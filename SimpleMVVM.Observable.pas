{******************************************************************************}
{                                                                              }
{           Simple MVVM prototype                                              }
{                                                                              }
{           Copyright (c) 2015 Stefan Glienke - All rights reserved            }
{                                                                              }
{******************************************************************************}

unit SimpleMVVM.Observable;

interface

uses
  Generics.Collections,
  Generics.Defaults,
  Rtti,
  SysUtils;

type
  IObservable = interface
    ['{3F78EF38-FA16-4E08-AD8D-3FD9A5E44BEF}']
    function GetValue: TValue;
    procedure SetValue(const value: TValue);
    property Value: TValue read GetValue write SetValue;
  end;

  IObservable<T> = interface(IInvokable)
    function GetValue: T;
    procedure SetValue(const value: T);
    property Value: T read GetValue write SetValue;
  end;

  TObservableBase = class(TInterfacedObject, IObservable)
  private
    fDependencies: TList<TObservableBase>;
  protected
    class var ObservableStack: TStack<TObservableBase>;
    constructor Create;
    procedure Changed; virtual;
    function GetValueNonGeneric: TValue; virtual; abstract;
    procedure SetValueNonGeneric(const value: TValue); virtual; abstract;
    function IObservable.GetValue = GetValueNonGeneric;
    procedure IObservable.SetValue = SetValueNonGeneric;
    procedure RegisterDependency;
  public
    class constructor Create;
    class destructor Destroy;

    destructor Destroy; override;
  end;

  TObservable<T> = class(TObservableBase, IObservable<T>)
  private
    fValue: T;
    class var Comparer: IEqualityComparer<T>;
    class constructor Create;
    function GetValue: T;
    procedure SetValue(const value: T);
  protected
    function GetValueNonGeneric: TValue; override; final;
    procedure SetValueNonGeneric(const value: TValue); override; final;
  public
    constructor Create; overload;
    constructor Create(const value: T); overload;
    property Value: T read GetValue write SetValue;
  end;

  TAction<T> = reference to procedure (const Arg1: T);

  TDependentObservable<T> = class(TObservableBase, IObservable<T>)
  private
    fValue: T;
    fGetter: TFunc<T>;
    fSetter: TAction<T>;
    fIsNotifying: Boolean;
    fNeedsEvaluation: Boolean;
    procedure Evaluate;
    function GetValue: T;
    procedure SetValue(const value: T);
  protected
    procedure Changed; override;
    function GetValueNonGeneric: TValue; override; final;
    procedure SetValueNonGeneric(const value: TValue); override; final;
  public
    constructor Create(const getter: TFunc<T>); overload;
    constructor Create(const getter: TFunc<T>; const setter: TAction<T>); overload;
  end;

implementation


{$REGION 'TObservableBase'}

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
end;

destructor TObservableBase.Destroy;
begin
  fDependencies.Free;
  inherited;
end;

procedure TObservableBase.Changed;
var
  observable: TObservableBase;
begin
  for observable in fDependencies do
    observable.Changed;
end;

procedure TObservableBase.RegisterDependency;
var
  observable: TObservableBase;
begin
  if ObservableStack.Count > 0 then
  begin
    observable := ObservableStack.Peek;
    if not fDependencies.Contains(observable) then
      fDependencies.Add(observable);
  end;
end;

{$ENDREGION}


{$REGION 'TObservable<T>'}

class constructor TObservable<T>.Create;
begin
  Comparer := TEqualityComparer<T>.Default;
end;

constructor TObservable<T>.Create;
begin
  inherited Create;
end;

constructor TObservable<T>.Create(const value: T);
begin
  inherited Create;
  fValue := value;
end;

function TObservable<T>.GetValue: T;
begin
  RegisterDependency;
  Result := fValue;
end;

function TObservable<T>.GetValueNonGeneric: TValue;
begin
  Result := TValue.From<T>(GetValue);
end;

procedure TObservable<T>.SetValue(const value: T);
begin
  if not Comparer.Equals(fValue, value) then
  begin
    fValue := value;
    Changed;
  end;
end;

procedure TObservable<T>.SetValueNonGeneric(const value: TValue);
begin
  SetValue(value.AsType<T>);
end;

{$ENDREGION}


{$REGION 'TDependentObservable<T>'}

constructor TDependentObservable<T>.Create(const getter: TFunc<T>);
begin
  Create(getter, nil);
end;

constructor TDependentObservable<T>.Create(const getter: TFunc<T>;
  const setter: TAction<T>);
begin
  inherited Create;
  fGetter := getter;
  fSetter := setter;
  fNeedsEvaluation := True;
  Evaluate;
end;

procedure TDependentObservable<T>.Changed;
begin
  Evaluate;
  inherited;
end;

procedure TDependentObservable<T>.Evaluate;
begin
  if fIsNotifying then Exit;
  fIsNotifying := True;
  RegisterDependency;

  ObservableStack.Push(Self);
  try
    fValue := fGetter;
  finally
    ObservableStack.Pop;
    fIsNotifying := False;
    fNeedsEvaluation := False;
  end;
end;

function TDependentObservable<T>.GetValue: T;
begin
  if fNeedsEvaluation or (ObservableStack.Count > 0) then
    Evaluate;
  Result := fValue;
end;

function TDependentObservable<T>.GetValueNonGeneric: TValue;
type
  PValue = ^TValue;
var
  v: T;
begin
  if TypeInfo(T) = TypeInfo(TValue) then
  begin
    v := GetValue;
    Result := PValue(@v)^;
  end
  else
    Result := TValue.From<T>(GetValue);
end;

procedure TDependentObservable<T>.SetValue(const value: T);
begin
  fSetter(value);
  inherited Changed;
end;

procedure TDependentObservable<T>.SetValueNonGeneric(const value: TValue);
type
  PValue = ^TValue;
var
  v: T;
begin
  if TypeInfo(T) = TypeInfo(TValue) then
  begin
    PValue(@v)^ := value;
    SetValue(v);
  end
  else
    SetValue(value.AsType<T>);
end;

{$ENDREGION}


end.
