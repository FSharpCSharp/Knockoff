{******************************************************************************}
{                                                                              }
{           Simple MVVM prototype                                              }
{                                                                              }
{           Copyright (c) 2015 Stefan Glienke - All rights reserved            }
{                                                                              }
{******************************************************************************}

unit SimpleMVVM.Binding;

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
  SimpleMVVM.Binding.Components,
  SimpleMVVM.Observable;

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

function CreateObservable(const instance: TObject;
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
      if StartsText('IObservable<', prop.PropertyType.Name) then
      begin
        Result := prop.GetValue(instance).AsInterface as IObservable;
        typ := prop.PropertyType.GetMethod('GetValue').ReturnType;
      end
      else
      begin
        if i = 0 then
          Result := CreateRootProp(prop, instance)
        else
          Result := CreateSubProp(prop, Result);
        typ := prop.PropertyType;
      end;
  end;
end;

procedure Bind(const target: TComponent; const targetExpression: string;
  const source: TObject; const sourceExpression: string);
var
  observable: IObservable;
  typ: TRttiType;
  method: TRttiMethod;
  command: ICommand;
  bindingClass: TBindingClass;
begin
  observable := CreateObservable(source, sourceExpression);

  if not Assigned(observable) then
  begin
    typ := ctx.GetType(source.ClassInfo);
    method := typ.GetMethod(sourceExpression);
    if Assigned(method) then
      command := TCommand.Create(method, source);
  end;

  Assert(Assigned(observable) or Assigned(command), 'expression not found: ' + sourceExpression);

  bindingClass := GetBindingClass(target, targetExpression);
  if Assigned(bindingClass) then
    bindingClass.Create(target, observable)
  else if (target is TButton) and SameText(targetExpression, 'Click') then
    TButtonBinding.Create(TButton(target), command)
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
