{******************************************************************************}
{                                                                              }
{           Simple MVVM prototype                                              }
{                                                                              }
{           Copyright (c) 2015 Stefan Glienke - All rights reserved            }
{                                                                              }
{******************************************************************************}

{ TODOs:
  - make parts that are hard coded dynamic to extend support for other controls
  - support multiple bindings to text properties using format
}

unit SimpleMVVM;

interface

uses
  Classes,
  Controls,
  Generics.Collections,
  Rtti,
  SysUtils;

type
  TControlHelper = class helper for TControl
  private
    function GetDisabled: Boolean;
    procedure SetDisabled(const value: Boolean);
  public
    property Disabled: Boolean read GetDisabled write SetDisabled;
  end;

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

  TBinding = class;

  IObservable = interface
    ['{3F78EF38-FA16-4E08-AD8D-3FD9A5E44BEF}']
    procedure AddBinding(const binding: TBinding);
    procedure RemoveBinding(const binding: TBinding);

    procedure Changed;

    function GetValue: TValue;
    procedure SetValue(const value: TValue);

    property Value: TValue read GetValue write SetValue;
  end;

  IObservable<T> = interface(IInvokable)
    function GetValue: T;
    procedure SetValue(const value: T);
    property Value: T read GetValue write SetValue;
  end;

  Observable<T> = record
  private
    function GetValue: T;
    procedure SetValue(const Value: T);
  public
    Instance: IObservable<T>;
    class operator Implicit(const value: IObservable<T>): Observable<T>;
    class operator Implicit(const value: Observable<T>): T;
    class operator Implicit(const value: Observable<T>): IObservable;
    property Value: T read GetValue write SetValue;
  end;

  TBinding = class(TComponent)
  protected
    fIsNotifying: Boolean;
    fObservable: IObservable;
    procedure DoNotify; virtual;
  public
    destructor Destroy; override;
    procedure Notify;
  end;

  TObservableBase = class(TInterfacedObject, IObservable)
  private
    fDependencies: TList<TObservableBase>;
    fBindings: TList<TBinding>;
    class var ObservableStack: TStack<TObservableBase>;
    procedure Changed;

    procedure AddBinding(const binding: TBinding);
    procedure RemoveBinding(const binding: TBinding);

    function GetValueNonGeneric: TValue; virtual; abstract;
    procedure SetValueNonGeneric(const value: TValue); virtual; abstract;
    function IObservable.GetValue = GetValueNonGeneric;
    procedure IObservable.SetValue = SetValueNonGeneric;
  protected
    procedure UpdateDependencies;
  public
    class constructor Create;
    class destructor Destroy;

    constructor Create;
    destructor Destroy; override;
  end;

  TPropertyObservable = class(TObservableBase)
  private
    fProperty: TRttiProperty;
    fInstance: TObject;
  protected
    function GetValueNonGeneric: TValue; override;
    procedure SetValueNonGeneric(const value: TValue); override;
  public
    constructor Create(const prop: TRttiProperty; const instance: TObject);
  end;

  TDependentObservable = class(TObservableBase)
  private
    fProperty: TRttiProperty;
    fObservable: IObservable;
  protected
    function GetValueNonGeneric: TValue; override;
    procedure SetValueNonGeneric(const value: TValue); override;
  public
    constructor Create(const prop: TRttiProperty; const observable: IObservable);
  end;

  TObservable<T> = class(TObservableBase, IObservable<T>)
  private
    fValue: T;

    function GetValue: T;
    procedure SetValue(const value: T);
  protected
    function GetValueNonGeneric: TValue; override;
    procedure SetValueNonGeneric(const value: TValue); override;
  public
    constructor Create(const value: T);
    property Value: T read GetValue write SetValue;
  end;

  TDependentObservable<T> = class(TObservableBase, IObservable<T>)
  private
    fValue: TFunc<T>;
    function GetValue: T;
    procedure SetValue(const Value: T);
  protected
    function GetValueNonGeneric: TValue; override;
    procedure SetValueNonGeneric(const value: TValue); override;
  public
    constructor Create(const value: TFunc<T>);
  end;

procedure ApplyBindings(const view: TComponent; const viewModel: TObject);

implementation

uses
  StdCtrls,
  StrUtils,
  Types;

var
  ctx: TRttiContext;

type
  TBinding<T: TComponent> = class(TBinding)
  protected
    fComponent: T;
    procedure Initialize; virtual;
  public
    constructor Create(const component: T; const observable: IObservable); reintroduce;
  end;

  TComponentBinding = class(TBinding<TComponent>)
  protected
    fProperty: TRttiProperty;
    procedure DoNotify; override;
  public
    constructor Create(const component: TComponent; const observable: IObservable;
      const propertyName: string); reintroduce;
  end;

  TEditBinding = class(TBinding<TEdit>)
  protected
    procedure DoNotify; override;
    procedure HandleChange(Sender: TObject);
    procedure Initialize; override;
  end;

  TLabelBinding = class(TBinding<TLabel>)
  protected
    procedure DoNotify; override;
  end;

  TComboBoxBinding = class(TBinding<TComboBox>)
  protected
    procedure DoNotify; override;
    procedure HandleChange(Sender: TObject);
    procedure Initialize; override;
  end;

  ICommand = interface
    procedure Execute;
  end;

  TCommand = class(TInterfacedObject, ICommand)
  private
    fMethod: TRttiMethod;
    fInstance: TObject;
    procedure Execute;
  public
    constructor Create(const method: TRttiMethod; const instance: TObject);
  end;

  TButtonBinding = class(TComponent)
  private
    fAction: ICommand;
  protected
    fComponent: TButton;
    procedure Initialize; //override;
    procedure HandleClick(Sender: TObject);
  public
    constructor Create(const component: TButton; const action: ICommand); reintroduce;
  end;

procedure ApplyBindings(const view: TComponent; const viewModel: TObject);
var
  f: TRttiField;
  a: TCustomAttribute;
begin
  if (viewModel is TComponent) then
    if TComponent(viewModel).Owner = nil then
      view.InsertComponent(TComponent(viewModel));

  for f in ctx.GetType(view.ClassInfo).GetFields do
    for a in f.GetAttributes do
      if a is BindAttribute then
        BindAttribute(a).ApplyBinding(
          f.GetValue(view).AsType<TComponent>,
          viewModel);
end;

{ BindAttribute }

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

{ BindOptionsAttribute }

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
//      observable := p.GetValue(source).AsInterface as IObservable
//    else
//      observable := TPropertyObservable.Create(p, source);
end;

{ BindOptionsCaptionAttribute }

constructor BindOptionsCaptionAttribute.Create(const optionsCaption: string);
begin
  inherited Create;
  fOptionsCaption := optionsCaption;
end;

{ BindOptionsTextAttribute }

constructor BindOptionsTextAttribute.Create(const optionsText: string);
begin
  inherited Create;
  fOptionsText := optionsText;
end;

{ TObservable }

class constructor TObservableBase.Create;
begin
  ObservableStack := TStack<TObservableBase>.Create;
end;

class destructor TObservableBase.Destroy;
begin
  ObservableStack.Free;
end;

constructor TObservableBase.Create;
begin
  inherited Create;
  fDependencies := TList<TObservableBase>.Create;
  fBindings := TList<TBinding>.Create;
end;

destructor TObservableBase.Destroy;
begin
  fBindings.Free;
  fDependencies.Free;
  inherited;
end;

procedure TObservableBase.AddBinding(const binding: TBinding);
begin
  fBindings.Add(binding);
end;

procedure TObservableBase.RemoveBinding(const binding: TBinding);
begin
  fBindings.Remove(binding);
end;

procedure TObservableBase.UpdateDependencies;
var
  observable: TObservableBase;
begin
  for observable in ObservableStack do
    if not fDependencies.Contains(observable) then
      fDependencies.Add(observable);
end;

procedure TObservableBase.Changed;
var
  binding: TBinding;
  observable: TObservableBase;
begin
  for binding in fBindings do
    binding.Notify;
  for observable in fDependencies do
    observable.Changed;
end;

{ TObservable }

constructor TPropertyObservable.Create(const prop: TRttiProperty;
  const instance: TObject);
begin
  inherited Create;
  fProperty := prop;
  fInstance := instance;
end;

function TPropertyObservable.GetValueNonGeneric: TValue;
begin
  UpdateDependencies;

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
  UpdateDependencies;

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

{ TObservable<T> }

constructor TObservable<T>.Create(const value: T);
begin
  inherited Create;
  fValue := value;
end;

function TObservable<T>.GetValue: T;
begin
  UpdateDependencies;

  ObservableStack.Push(Self);
  try
    Result := fValue;
  finally
    ObservableStack.Pop;
  end;
end;

function TObservable<T>.GetValueNonGeneric: TValue;
begin
  Result := TValue.From<T>(GetValue);
end;

procedure TObservable<T>.SetValue(const value: T);
begin
  fValue := value;
  Changed;
end;

procedure TObservable<T>.SetValueNonGeneric(const value: TValue);
begin
  SetValue(value.AsType<T>);
end;

{ TDependentObservable<T> }

constructor TDependentObservable<T>.Create(const value: TFunc<T>);
begin
  inherited Create;
  fValue := value;
end;

function TDependentObservable<T>.GetValue: T;
begin
  UpdateDependencies;

  ObservableStack.Push(Self);
  try
    Result := fValue;
  finally
    ObservableStack.Pop;
  end;
end;

function TDependentObservable<T>.GetValueNonGeneric: TValue;
begin
  Result := TValue.From<T>(GetValue);
end;

procedure TDependentObservable<T>.SetValue(const Value: T);
begin
end;

procedure TDependentObservable<T>.SetValueNonGeneric(const value: TValue);
begin
  SetValue(value.AsType<T>);
end;

{ Observable<T> }

class operator Observable<T>.Implicit(
  const value: IObservable<T>): Observable<T>;
begin
  Result.Instance := value;
end;

class operator Observable<T>.Implicit(const value: Observable<T>): T;
begin
  Result := value.Instance.Value;
end;

class operator Observable<T>.Implicit(const value: Observable<T>): IObservable;
begin
  Result := value.Instance as IObservable;
end;

function Observable<T>.GetValue: T;
begin
  Result := Instance.Value;
end;

procedure Observable<T>.SetValue(const Value: T);
begin
  Instance.Value := value;
end;

{ TBinding }

destructor TBinding.Destroy;
begin
  fObservable.RemoveBinding(Self);
  inherited;
end;

procedure TBinding.DoNotify;
begin  // nothing
end;

procedure TBinding.Notify;
begin
  if fIsNotifying then
    Exit;
  fIsNotifying := True;
  try
    DoNotify;
  finally
    fIsNotifying := False;
  end;
end;

{ TBinding<T> }

constructor TBinding<T>.Create(const component: T; const observable: IObservable);
begin
  inherited Create(component);
  fComponent := component;
  fObservable := observable;
  fObservable.AddBinding(Self);
  Initialize;
  Notify;
end;

procedure TBinding<T>.Initialize;
begin // nothing
end;

{ TEditBinding }

procedure TEditBinding.DoNotify;
begin
  fComponent.Text := fObservable.Value.AsString;
end;

procedure TEditBinding.HandleChange(Sender: TObject);
begin
  fObservable.Value := fComponent.Text;
end;

procedure TEditBinding.Initialize;
begin
  fComponent.OnChange := HandleChange;
end;

{ TComboBoxBinding }

procedure TComboBoxBinding.DoNotify;
begin
  fComponent.ItemIndex := fComponent.Items.IndexOfObject(fObservable.Value.AsObject);
end;

procedure TComboBoxBinding.HandleChange(Sender: TObject);
begin
  if fComponent.ItemIndex = -1 then
    fObservable.Value := nil
  else
    fObservable.Value := fComponent.Items.Objects[fComponent.ItemIndex];
end;

procedure TComboBoxBinding.Initialize;
begin
  fComponent.OnChange := HandleChange;
end;

{ TLabelBinding }

procedure TLabelBinding.DoNotify;
var
  v: TValue;
begin
  v := fObservable.Value;
  if v.IsEmpty then
    fComponent.Caption := ''
  else
    fComponent.Caption := v.ToString;
end;

{ TButtonBinding }

constructor TButtonBinding.Create(const component: TButton;
  const action: ICommand);
begin
  inherited Create(component);
  fComponent := component;
  fAction := action;
  Initialize;
end;

procedure TButtonBinding.HandleClick(Sender: TObject);
begin
  fAction.Execute;
end;

procedure TButtonBinding.Initialize;
begin
  fComponent.OnClick := HandleClick;
end;

{ TAction }

constructor TCommand.Create(const method: TRttiMethod; const instance: TObject);
begin
  inherited Create;
  fMethod := method;
  fInstance := instance;
end;

procedure TCommand.Execute;
begin
  fMethod.Invoke(fInstance, []);
end;

{ TComponentBinding }

constructor TComponentBinding.Create(const component: TComponent;
  const observable: IObservable; const propertyName: string);
begin
  // hardcode property extension for now, build dynamic system later
  if (component is TControl) and SameText(propertyName, 'Disabled') then
    fProperty := ctx.GetType(TypeInfo(TControlHelper)).GetProperty(propertyName)
  else
    fProperty := ctx.GetType(component.ClassInfo).GetProperty(propertyName);
  Assert(Assigned(fProperty));
  inherited Create(component, observable);
end;

procedure TComponentBinding.DoNotify;
var
  v: TValue;
begin
  v := fObservable.Value;
  // some hardcoded custom value conversion for now
  if (fProperty.PropertyType.Handle = TypeInfo(Boolean)) and v.IsObject then
    fProperty.SetValue(fComponent, v.AsObject <> nil)
  else
    fProperty.SetValue(fComponent, v);
end;

{ TControlHelper }

function TControlHelper.GetDisabled: Boolean;
begin
  Result := not Enabled;
end;

procedure TControlHelper.SetDisabled(const value: Boolean);
begin
  Enabled := not Value;
end;

end.
