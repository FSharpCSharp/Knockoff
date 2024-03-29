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

unit Knockoff.Binding.Components;

interface

uses
  Classes,
  Rtti,
  StdCtrls,
  ComCtrls,
  SysUtils,
  Knockoff.Observable;

type
  TBinding = class(TComponent)
  private
    fSource: IObservable;
    fTarget: TComponent;
  protected
    function InitGetValue(const observable: IObservable): TFunc<TValue>; virtual;
    procedure InitSource(const observable: IObservable); virtual;
    procedure InitTarget; virtual;

    property Source: IObservable read fSource;
    property Target: TComponent read fTarget;
  public
    constructor Create(const target: TComponent;
      const source: IObservable); reintroduce;
  end;

  TBindingClass = class of TBinding;

  TBinding<T: TComponent> = class(TBinding)
  private
    function GetTarget: T;
  protected
    property Target: T read GetTarget;
  public
    constructor Create(const target: T; const source: IObservable);
  end;

  TComponentBinding = class(TBinding<TComponent>)
  protected
    fProperty: TRttiProperty;
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
  public
    constructor Create(const target: TComponent; const source: IObservable;
      const propertyName: string); reintroduce;
  end;

  TButtonBinding = class(TBinding<TButton>)
  protected
    procedure HandleClick(Sender: TObject);
    procedure InitTarget; override;
    procedure InitSource(const observable: IObservable); override;
  end;

  TEditBinding = class(TBinding<TEdit>)
  protected
    procedure HandleChange(Sender: TObject);
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
    procedure InitTarget; override;
  end;

  TComboBoxBinding = class(TBinding<TComboBox>)
  protected
    procedure HandleChange(Sender: TObject);
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
    procedure InitTarget; override;
  end;

  TLabelBinding = class(TBinding<TLabel>)
  protected
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
  end;

  TCheckBoxBinding = class(TBinding<TCheckBox>)
  protected
    procedure HandleClick(Sender: TObject);
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
    procedure InitTarget; override;
  end;

  TTrackBarBinding = class(TBinding<TTrackBar>)
  protected
    procedure HandleChange(Sender: TObject);
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
    procedure InitTarget; override;
  end;

  TListBoxItemsBinding = class(TBinding<TListBox>)
  protected
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
  end;

  TListBoxBinding = class(TBinding<TListBox>)
  protected
    procedure HandleChange(Sender: TObject);
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
    procedure InitTarget; override;
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
  else if (target is TCheckBox) and SameText(expression, 'Checked') then
    Result := TCheckBoxBinding
  else if (target is TTrackBar) and SameText(expression, 'Position') then
    Result := TTrackBarBinding
  else if (target is TListBox) and SameText(expression, 'Options') then
    Result := TListBoxItemsBinding
  else if (target is TListBox) and SameText(expression, 'SelectedOption') then
    Result := TListBoxBinding
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

constructor TBinding.Create(const target: TComponent;
  const source: IObservable);
begin
  inherited Create(target);
  fTarget := target;
  InitSource(source);
  InitTarget;
end;

function TBinding.InitGetValue(const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    begin
      Result := observable.Value;
    end;
end;

procedure TBinding.InitSource(const observable: IObservable);
begin
  fSource := TDependentObservable.Create(
    InitGetValue(observable),
    procedure(const value: TValue)
    begin
      observable.Value := value;
    end);
end;

procedure TBinding.InitTarget;
begin
end;

{$ENDREGION}


{$REGION 'TBinding<T>'}

constructor TBinding<T>.Create(const target: T; const source: IObservable);
begin
  inherited Create(target, source);
end;

function TBinding<T>.GetTarget: T;
begin
  Result := T(inherited Target);
end;

{$ENDREGION}


{$REGION 'TComponentBinding'}

constructor TComponentBinding.Create(const target: TComponent;
  const source: IObservable; const propertyName: string);
begin
  // hardcode property extension for now, build dynamic system later
  if (target is TControl) and SameText(propertyName, 'Disabled') then
    fProperty := ctx.GetType(TypeInfo(TControlHelper)).GetProperty(propertyName)
  else
    fProperty := ctx.GetType(target.ClassInfo).GetProperty(propertyName);
  Assert(Assigned(fProperty));
  inherited Create(target, source);
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
        fProperty.SetValue(Target, v.AsObject <> nil)
      else
        fProperty.SetValue(Target, v);
    end;
end;

{$ENDREGION}


{$REGION 'TButtonBinding'}

procedure TButtonBinding.HandleClick(Sender: TObject);
begin
  Source.Value;
end;

procedure TButtonBinding.InitTarget;
begin
  Target.OnClick := HandleClick;
end;

procedure TButtonBinding.InitSource(const observable: IObservable);
begin
  fSource := observable;
end;

{$ENDREGION}


{$REGION 'TEditBinding'}

procedure TEditBinding.HandleChange(Sender: TObject);
begin
  Source.Value := Target.Text;
end;

procedure TEditBinding.InitTarget;
begin
  Target.OnChange := HandleChange;
end;

function TEditBinding.InitGetValue(const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    begin
      Target.Text := observable.Value.ToString;
    end;
end;

{$ENDREGION}


{$REGION 'TComboBoxBinding'}

procedure TComboBoxBinding.HandleChange(Sender: TObject);
var
  o: TObject;
begin
  if Target.ItemIndex = -1 then
    Source.Value := nil
  else
  begin
    o := Target.Items.Objects[Target.ItemIndex];
    if o = nil then
      Source.Value := Target.Items[Target.ItemIndex]
    else
      Source.Value := o;
  end;
end;

procedure TComboBoxBinding.InitTarget;
begin
  Target.OnChange := HandleChange;
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
        Target.ItemIndex := Target.Items.IndexOfObject(value.AsObject)
      else
        Target.ItemIndex := Target.Items.IndexOf(value.ToString);
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
        Target.Caption := ''
      else
        Target.Caption := v.ToString;
    end;
end;

{$ENDREGION}


{$REGION 'TCheckBoxBinding'}

procedure TCheckBoxBinding.HandleClick(Sender: TObject);
begin
  Source.Value := Target.Checked;
end;

procedure TCheckBoxBinding.InitTarget;
begin
  Target.OnClick := HandleClick;
end;

function TCheckBoxBinding.InitGetValue(
  const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    begin
      Target.Checked := observable.Value.AsBoolean;
    end;
end;

{$ENDREGION}


{$REGION 'TTrackBarBinding'}

procedure TTrackBarBinding.HandleChange(Sender: TObject);
begin
  Source.Value := Target.Position;
end;

procedure TTrackBarBinding.InitTarget;
begin
  Target.OnChange := HandleChange;
end;

function TTrackBarBinding.InitGetValue(const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    begin
      Target.Position := observable.Value.ToType<Integer>;
    end;
end;

{$ENDREGION}


{$REGION 'TListBoxItemsBinding'}

type
  TControlAccess = class(TControl);

function TListBoxItemsBinding.InitGetValue(
  const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    var
      i: Integer;
      values: TArray<string>;
      item: string; // only single select for now
    begin
      if Target.ItemIndex > - 1 then
        item := Target.Items[Target.ItemIndex];
      Target.Items.BeginUpdate;
      try
        Target.Items.Clear;
        values := observable.Value.AsType<TArray<string>>;
        for i := Low(values) to High(values) do
          Target.Items.Add(values[i]);
      finally
        Target.Items.EndUpdate;
        Target.ItemIndex := Target.Items.IndexOf(item);
        TControlAccess(Target).Click;
      end;
    end;
end;

{$ENDREGION}


{$REGION 'TListBoxBinding'}

procedure TListBoxBinding.HandleChange(Sender: TObject);
var
  o: TObject;
begin
  if Target.ItemIndex = -1 then
    Source.Value := nil
  else
  begin
    o := Target.Items.Objects[Target.ItemIndex];
    if o = nil then
      Source.Value := Target.Items[Target.ItemIndex]
    else
      Source.Value := o;
  end;
end;

function TListBoxBinding.InitGetValue(
  const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    var
      value: TValue;
    begin
      value := observable.Value;
      if value.IsObject then
        Target.ItemIndex := Target.Items.IndexOfObject(value.AsObject)
      else
        Target.ItemIndex := Target.Items.IndexOf(value.ToString);
    end;
end;

procedure TListBoxBinding.InitTarget;
begin
  Target.OnClick := HandleChange;
end;

{$ENDREGION}


end.
