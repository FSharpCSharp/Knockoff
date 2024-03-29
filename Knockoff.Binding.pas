{***************************************************************************}
{                                                                           }
{           Knockoff prototype                                              }
{                                                                           }
{           Copyright (c) 2015 Stefan Glienke - All rights reserved         }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

unit Knockoff.Binding;

interface

uses
  Classes;

type
  BindAttribute = class(TCustomAttribute)
  private
    fTargetName: string;
    fSourceName: string;
  public
    constructor Create(const targetName, sourceName: string);
    procedure ApplyBinding(const target: TComponent; const source: TObject); virtual;
  end;

  BindOptionsAttribute = class(BindAttribute)
  public
    constructor Create(const sourceName: string);
    procedure ApplyBinding(const target: TComponent; const source: TObject); override;
  end;

  BindOptionsCaptionAttribute = class(TCustomAttribute)
  private
    fOptionsCaption: string;
  public
    constructor Create(const optionsCaption: string);
    property OptionsCaption: string read fOptionsCaption;
  end;

  BindOptionsTextAttribute = class(TCustomAttribute)
  private
    fOptionsText: string;
  public
    constructor Create(const optionsText: string);
    property OptionsText: string read fOptionsText;
  end;

procedure ApplyBindings(const view: TComponent; const viewModel: TObject);
procedure ApplyBindingsByConventions(const view: TComponent; const viewModel: TObject);

procedure Bind(const target: TComponent; const targetExpression: string;
  const source: TObject; const sourceExpression: string);

implementation

uses
  Generics.Collections,
  Rtti,
  StdCtrls,
  StrUtils,
  SysUtils,
  Types,
  Knockoff.Binding.Components,
  Knockoff.Observable;

var
  ctx: TRttiContext;

procedure ApplyBindings(const view: TComponent; const viewModel: TObject);
var
  field: TRttiField;
  attr: TCustomAttribute;
begin
  if viewModel is TComponent then
    if TComponent(viewModel).Owner = nil then
      view.InsertComponent(TComponent(viewModel));

  for field in ctx.GetType(view.ClassInfo).GetFields do
    for attr in field.GetAttributes do
      if attr is BindAttribute then
        BindAttribute(attr).ApplyBinding(
          field.GetValue(view).AsType<TComponent>,
          viewModel);
end;

procedure ApplyBindingsByConventions(const view: TComponent; const viewModel: TObject);
var
  target: TComponent;
  typ: TRttiType;
  prop: TRttiProperty;
begin
  if viewModel is TComponent then
    if TComponent(viewModel).Owner = nil then
      view.InsertComponent(TComponent(viewModel));

  typ := ctx.GetType(viewModel.ClassInfo);
  for target in view do
  begin
    prop := typ.GetProperty(target.Name);
    if prop <> nil then
    begin
      // hardcoded for now
      if target is TEdit then
        Bind(target, 'Value', viewModel, target.Name)
      else if target is TLabel then
        Bind(target, 'Text', viewModel, target.Name);
    end;
  end;
end;

function CreateObservable(instance: TObject;
  const expression: string): IObservable;

  function CreateRootProp(const prop: TRttiProperty; const instance: TObject): IObservable;
  begin
    Result := TDependentObservable.Create(
      function: TValue
      begin
        Result := prop.GetValue(instance);
      end,
      procedure(const value: TValue)
      begin
        prop.SetValue(instance, value);
      end);
  end;

  function CreateSubProp(const prop: TRttiProperty; const observable: IObservable): IObservable;
  begin
    Result := TDependentObservable.Create(
      function: TValue
      var
        instance: TObject;
      begin
        instance := observable.Value.AsObject;
        if Assigned(instance) then
          Result := prop.GetValue(instance)
        else
          Result := nil;
      end,
      procedure(const value: TValue)
      var
        instance: TObject;
      begin
        instance := observable.Value.AsObject;
        if Assigned(instance) then
          prop.SetValue(instance, value);
      end);
  end;

var
  expressions: TStringDynArray;
  i: Integer;
  typ: TRttiType;
  prop: TRttiProperty;
begin
  Result := nil;
  expressions := SplitString(expression, '.');
  typ := ctx.GetType(instance.ClassInfo);
  for i := 0 to High(expressions) do
  begin
    prop := typ.GetProperty(expressions[i]);
    if Assigned(prop) then
    begin
      if StartsText('Observable<', prop.PropertyType.Name)
        or StartsText('ObservableArray<', prop.PropertyType.Name) then
      begin
        Result := prop.GetValue(instance).AsInterface as IObservable;
        typ := prop.PropertyType.BaseType.GetMethod('Invoke').ReturnType;
      end
      else
      begin
        if i = 0 then
          Result := CreateRootProp(prop, instance)
        else
          Result := CreateSubProp(prop, Result);
        typ := prop.PropertyType;
      end;
      if i < High(expressions) then
        instance := Result.Value.AsObject;
    end;
  end;
end;

procedure Bind(const target: TComponent; const targetExpression: string;
  const source: TObject; const sourceExpression: string);
var
  observable: IObservable;
  typ: TRttiType;
  method: TRttiMethod;
  bindingClass: TBindingClass;
begin
  observable := CreateObservable(source, sourceExpression);

  if not Assigned(observable) then
  begin
    typ := ctx.GetType(source.ClassInfo);
    method := typ.GetMethod(sourceExpression);
    if Assigned(method) then
      observable := TObservable.Create(
        function: TValue
        begin
          Result := method.Invoke(source, []);
        end);
  end;

  Assert(Assigned(observable), 'expression not found: ' + sourceExpression);

  bindingClass := GetBindingClass(target, targetExpression);
  if Assigned(bindingClass) then
    bindingClass.Create(target, observable)
  else
    TComponentBinding.Create(target, observable, targetExpression);
end;


{$REGION 'BindAttribute'}

constructor BindAttribute.Create(const targetName, sourceName: string);
begin
  inherited Create;
  fTargetName := targetName;
  fSourceName := sourceName;
end;

procedure BindAttribute.ApplyBinding(const target: TComponent;
  const source: TObject);
begin
  Bind(target, fTargetName, source, fSourceName);
end;

{$ENDREGION}


{$REGION 'BindOptionsAttribute'}

constructor BindOptionsAttribute.Create(const sourceName: string);
begin
  inherited Create('options', sourceName);
end;

procedure BindOptionsAttribute.ApplyBinding(const target: TComponent;
  const source: TObject);
var
  a: TCustomAttribute;
  t: TRttiType;
  p: TRttiProperty;
  items: TStrings;
  l: TList<TObject>;
  o: TObject;
  i: Integer;
  s: string;
  optionsCaption: string;
  optionsText: string;
begin
  for a in ctx.GetType(target.Owner.ClassInfo).GetField(target.Name).GetAttributes do
  begin
    if a is BindOptionsCaptionAttribute then
      optionsCaption := BindOptionsCaptionAttribute(a).OptionsCaption
    else if a is BindOptionsTextAttribute then
      optionsText := BindOptionsTextAttribute(a).OptionsText;
  end;

  t := ctx.GetType(source.ClassInfo);
  p := t.GetProperty(fSourceName);
  if Assigned(p) then
    // just hardcode this for the Items property for now, make it dynamic later
    if target is TComboBox then
    begin
      items := TComboBox(target).Items;
      items.Clear;
      if optionsCaption <> '' then
      begin
        items.Add(optionsCaption);
        TComboBox(target).ItemIndex := 0;
      end;

      if p.PropertyType.Handle = TypeInfo(TArray<string>) then
      begin
        for s in p.GetValue(source).AsType<TArray<string>> do
          items.Add(s);
      end else
      if StartsText('TList<', p.PropertyType.Name) then
      begin
        // assume that it is a list of objects for now
        l := TList<TObject>(p.GetValue(source).AsObject);
        for i := 0 to l.Count - 1 do
        begin
          o := l[i];
          if optionsText <> '' then
            p := ctx.GetType(o.ClassInfo).GetProperty(optionsText);
          if Assigned(p) then
            items.AddObject(p.GetValue(o).ToString, o)
          else
            items.AddObject(o.ToString, o);
        end;
      end;
    end;
end;

{$ENDREGION}


{$REGION 'BindOptionsCaptionAttribute'}

constructor BindOptionsCaptionAttribute.Create(const optionsCaption: string);
begin
  inherited Create;
  fOptionsCaption := optionsCaption;
end;

{$ENDREGION}


{$REGION 'BindOptionsTextAttribute'}

constructor BindOptionsTextAttribute.Create(const optionsText: string);
begin
  inherited Create;
  fOptionsText := optionsText;
end;

{$ENDREGION}


end.
