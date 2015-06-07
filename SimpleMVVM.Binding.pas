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
  f: TRttiField;
  a: TCustomAttribute;
begin
  if viewModel is TComponent then
    if TComponent(viewModel).Owner = nil then
      view.InsertComponent(TComponent(viewModel));

  for f in ctx.GetType(view.ClassInfo).GetFields do
    for a in f.GetAttributes do
      if a is BindAttribute then
        BindAttribute(a).ApplyBinding(
          f.GetValue(view).AsType<TComponent>,
          viewModel);
end;

{$REGION 'BindAttribute'}

type
  TPropertyObservable = class(TObservableBase)
  private
    fProperty: TRttiProperty;
    fInstance: TObject;
    function GetValueNonGeneric: TValue; override;
    procedure SetValueNonGeneric(const value: TValue); override;
  public
    constructor Create(const prop: TRttiProperty; const instance: TObject);
  end;

  TDependentObservable = class(TObservableBase)
  private
    fProperty: TRttiProperty;
    fObservable: IObservable;
    function GetValueNonGeneric: TValue; override;
    procedure SetValueNonGeneric(const value: TValue); override;
  public
    constructor Create(const prop: TRttiProperty; const observable: IObservable);
  end;

{ TPropertyObservable }

constructor TPropertyObservable.Create(const prop: TRttiProperty;
  const instance: TObject);
begin
  inherited Create;
  fProperty := prop;
  fInstance := instance;
end;

function TPropertyObservable.GetValueNonGeneric: TValue;
begin
  RegisterDependency;

  ObservableStack.Push(Self);
  try
    Result := fProperty.GetValue(fInstance);
  finally
    ObservableStack.Pop;
  end;
end;

procedure TPropertyObservable.SetValueNonGeneric(const value: TValue);
begin
  fProperty.SetValue(fInstance, value);
end;

{ TDependentObservable }

constructor TDependentObservable.Create(const prop: TRttiProperty;
  const observable: IObservable);
begin
  inherited Create;
  fProperty := prop;
  fObservable := observable;
end;

function TDependentObservable.GetValueNonGeneric: TValue;
var
  v: TValue;
  obj: TObject;
begin
  RegisterDependency;

  ObservableStack.Push(Self);
  try
    v := fObservable.Value;
    obj := v.AsObject;
    if Assigned(obj) then
      Result := fProperty.GetValue(obj)
    else
      Result := nil;
  finally
    ObservableStack.Pop;
  end;
end;

procedure TDependentObservable.SetValueNonGeneric(const value: TValue);
var
  v: TValue;
  obj: TObject;
begin
  v := fObservable.Value;
  obj := v.AsObject;
  if Assigned(obj) then
    fProperty.SetValue(obj, value);
end;

constructor BindAttribute.Create(const targetName, sourceName: string);
begin
  inherited Create;
  fTargetName := targetName;
  fSourceName := sourceName;
end;

procedure BindAttribute.ApplyBinding(const target: TComponent;
  const source: TObject);
var
  t: TRttiType;
  p: TRttiProperty;
  m: TRttiMethod;
  observable: IObservable;
  action: ICommand;
  sourceName: TStringDynArray;
  i: Integer;
begin
  t := ctx.GetType(source.ClassInfo);
  // TODO: extract to extra method to generate chained expressions
  sourceName := SplitString(fSourceName, '.');

  for i := 0 to High(sourceName) do
  begin
    p := t.GetProperty(sourceName[i]);
    if Assigned(p) then
    begin
      if StartsText('IObservable<', p.PropertyType.Name) then
      begin
        observable := p.GetValue(source).AsInterface as IObservable;
        t := p.PropertyType.GetMethod('GetValue').ReturnType;
      end
      else
      begin
        if i = 0 then
          observable := TPropertyObservable.Create(p, source)
        else
          observable := TDependentObservable.Create(p, observable);
        t := p.PropertyType;
      end;
    end;
  end;

  m := t.GetMethod(sourceName[0]);
  if Assigned(m) then
    action := TCommand.Create(m, source);

  // hardcode for now, build better rules later
  if (target is TEdit) and SameText(fTargetName, 'Value') then
    TEditBinding.Create(TEdit(target), observable)
  else if (target is TComboBox) and SameText(fTargetName, 'Value') then
    TComboBoxBinding.Create(TComboBox(target), observable)
  else if (target is TLabel) and SameText(fTargetName, 'Text') then
    TLabelBinding.Create(TLabel(target), observable)
  else if (target is TButton) and SameText(fTargetName, 'Click') then
    TButtonBinding.Create(TButton(target), action)
  else
    TComponentBinding.Create(target, observable, fTargetName);
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
  s: TStrings;
  l: TList<TObject>;
  o: TObject;
  i: Integer;
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
    if StartsText('TList<', p.PropertyType.Name) then
    begin
      // just hardcode this for the Items property for now, make it dynamic later
      if target is TComboBox then
      begin
        s := TComboBox(target).Items;
        s.Clear;
        if optionsCaption <> '' then
        begin
          s.Add(optionsCaption);
          TComboBox(target).ItemIndex := 0;
        end;
        // assume that it is a list of objects for now
        l := TList<TObject>(p.GetValue(source).AsObject);
        for i := 0 to l.Count - 1 do
        begin
          o := l[i];
          if optionsText <> '' then
            p := ctx.GetType(o.ClassInfo).GetProperty(optionsText);
          if Assigned(p) then
            s.AddObject(p.GetValue(o).ToString, o)
          else
            s.AddObject(o.ToString, o);
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
