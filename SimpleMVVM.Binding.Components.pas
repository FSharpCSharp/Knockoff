{******************************************************************************}
{                                                                              }
{           Simple MVVM prototype                                              }
{                                                                              }
{           Copyright (c) 2015 Stefan Glienke - All rights reserved            }
{                                                                              }
{******************************************************************************}

unit SimpleMVVM.Binding.Components;

interface

uses
  Classes,
  Rtti,
  StdCtrls,
  SysUtils,
  SimpleMVVM.Observable;

type
  TBinding = class(TComponent)
  private
    fObservable: IObservable;
  protected
    procedure InitComponent; virtual;
    procedure InitObservable(const observable: IObservable); virtual;
    function InitGetValue(const observable: IObservable): TFunc<TValue>; virtual;
    procedure SetComponent(const component: TComponent); virtual; abstract;
  public
    constructor Create(const component: TComponent;
      const observable: IObservable); reintroduce;
  end;

  TBindingClass = class of TBinding;

  TBinding<T: TComponent> = class(TBinding)
  protected
    fComponent: T;
    procedure SetComponent(const component: TComponent); override;
  public
    constructor Create(const component: T; const observable: IObservable);
  end;

  TComponentBinding = class(TBinding<TComponent>)
  protected
    fProperty: TRttiProperty;
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
  public
    constructor Create(const component: TComponent; const observable: IObservable;
      const propertyName: string); reintroduce;
  end;

  TButtonBinding = class(TBinding<TButton>)
  protected
    procedure HandleClick(Sender: TObject);
    procedure InitComponent; override;
    procedure InitObservable(const observable: IObservable); override;
  end;

  TEditBinding = class(TBinding<TEdit>)
  protected
    procedure HandleChange(Sender: TObject);
    procedure InitComponent; override;
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
  end;

  TComboBoxBinding = class(TBinding<TComboBox>)
  protected
    procedure HandleChange(Sender: TObject);
    procedure InitComponent; override;
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
  end;

  TLabelBinding = class(TBinding<TLabel>)
  protected
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
  end;

function GetBindingClass(const target: TObject; const expression: string): TBindingClass;

implementation

uses
  Controls;

function GetBindingClass(const target: TObject; const expression: string): TBindingClass;
begin
  // hardcode for now, build better rules later
  if (target is TEdit) and SameText(expression, 'Value') then
    Result := TEditBinding
  else if (target is TComboBox) and SameText(expression, 'Value') then
    Result := TComboBoxBinding
  else if (target is TLabel) and SameText(expression, 'Text') then
    Result := TLabelBinding
  else if (target is TButton) and SameText(expression, 'Click') then
    Result := TButtonBinding
  else
    Result := nil;
end;

var
  ctx: TRttiContext;

type
  TControlHelper = class helper for TControl
  private
    function GetDisabled: Boolean;
    procedure SetDisabled(const value: Boolean);
  public
    property Disabled: Boolean read GetDisabled write SetDisabled;
  end;


{$REGION 'TControlHelper'}

function TControlHelper.GetDisabled: Boolean;
begin
  Result := not Enabled;
end;

procedure TControlHelper.SetDisabled(const value: Boolean);
begin
  Enabled := not Value;
end;

{$ENDREGION}


{$REGION 'TBinding'}

constructor TBinding.Create(const component: TComponent;
  const observable: IObservable);
begin
  inherited Create(component);
  SetComponent(component);
  InitObservable(observable);
  InitComponent;
end;

procedure TBinding.InitComponent;
begin
end;

function TBinding.InitGetValue(const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    begin
      Result := observable.Value;
    end;
end;

procedure TBinding.InitObservable(const observable: IObservable);
begin
  fObservable := TDependentObservable.Create(
    InitGetValue(observable),
    procedure(const value: TValue)
    begin
      observable.Value := value;
    end);
end;

{$ENDREGION}


{$REGION 'TBinding<T>'}

constructor TBinding<T>.Create(const component: T; const observable: IObservable);
begin
  inherited Create(component, observable);
end;

procedure TBinding<T>.SetComponent(const component: TComponent);
begin
  fComponent := T(component);
end;

{$ENDREGION}


{$REGION 'TComponentBinding'}

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

function TComponentBinding.InitGetValue(
  const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    var
      v: TValue;
    begin
      v := observable.Value;
      // some hardcoded custom value conversion for now
      if (fProperty.PropertyType.Handle = TypeInfo(Boolean)) and v.IsObject then
        fProperty.SetValue(fComponent, v.AsObject <> nil)
      else
        fProperty.SetValue(fComponent, v);
    end;
end;

{$ENDREGION}


{$REGION 'TButtonBinding'}

procedure TButtonBinding.HandleClick(Sender: TObject);
begin
  fObservable.Value;
end;

procedure TButtonBinding.InitComponent;
begin
  fComponent.OnClick := HandleClick;
end;

procedure TButtonBinding.InitObservable(const observable: IObservable);
begin
  fObservable := observable;
end;

{$ENDREGION}


{$REGION 'TEditBinding'}

procedure TEditBinding.HandleChange(Sender: TObject);
begin
  fObservable.Value := fComponent.Text;
end;

procedure TEditBinding.InitComponent;
begin
  fComponent.OnChange := HandleChange;
end;

function TEditBinding.InitGetValue(const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    begin
      fComponent.Text := observable.Value.ToString;
    end;
end;

{$ENDREGION}


{$REGION 'TComboBoxBinding'}

procedure TComboBoxBinding.HandleChange(Sender: TObject);
var
  o: TObject;
begin
  if fComponent.ItemIndex = -1 then
    fObservable.Value := nil
  else
  begin
    o := fComponent.Items.Objects[fComponent.ItemIndex];
    if o = nil then
      fObservable.Value := fComponent.Items[fComponent.ItemIndex]
    else
      fObservable.Value := o;
  end;
end;

procedure TComboBoxBinding.InitComponent;
begin
  fComponent.OnChange := HandleChange;
end;

function TComboBoxBinding.InitGetValue(const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    var
      value: TValue;
    begin
      value := observable.Value;
      if value.IsObject then
        fComponent.ItemIndex := fComponent.Items.IndexOfObject(value.AsObject)
      else
        fComponent.ItemIndex := fComponent.Items.IndexOf(value.ToString);
    end;
end;

{$ENDREGION}


{$REGION 'TLabelBinding'}

function TLabelBinding.InitGetValue(const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    var
      v: TValue;
    begin
      if observable = nil then
        Exit;
      v := observable.Value;
      if v.IsEmpty then
        fComponent.Caption := ''
      else
        fComponent.Caption := v.ToString;
    end;
end;

{$ENDREGION}


end.
