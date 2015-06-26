{******************************************************************************}
{                                                                              }
{           Knockoff prototype                                                 }
{                                                                              }
{           Copyright (c) 2015 Stefan Glienke - All rights reserved            }
{                                                                              }
{******************************************************************************}

unit Knockoff.Observable;

interface

uses
  Generics.Collections,
  Generics.Defaults,
  Rtti,
  SysUtils;

type
  TAction<T> = reference to procedure (const Arg1: T);

  TNotifyTrigger = (AfterChange, BeforeChange);

  ISubscribable = interface(IInvokable)
    ['{024CC9A2-1C89-4A80-A1F2-6EFF4EF91A07}']
    procedure Subscribe(const action: TAction<TValue>; trigger: TNotifyTrigger = AfterChange);
  end;

  IObservable = interface(ISubscribable)
    ['{3F78EF38-FA16-4E08-AD8D-3FD9A5E44BEF}']
  {$REGION 'Property Accessors'}
    function GetValue: TValue;
    procedure SetValue(const value: TValue);
  {$ENDREGION}
    property Value: TValue read GetValue write SetValue;
  end;

  {$M+}
  ReadOnlyObservable<T> = reference to function: T;
  Observable<T> = interface(ReadOnlyObservable<T>)
  {$REGION 'Property Accessors'}
    procedure Invoke(const value: T); overload;
  {$ENDREGION}
    procedure Subscribe(const action: TAction<T>; trigger: TNotifyTrigger = AfterChange);
  end;
  {$M-}

  TSubscribable = class(TInterfacedObject, ISubscribable)
  private type
    TSubscriptions = TArray<TAction<TValue>>;
    PSubscriptions = ^TSubscriptions;
  private
    fSubscriptions: array[TNotifyTrigger] of TSubscriptions;
  protected
    procedure Notify(const value: TValue; trigger: TNotifyTrigger); virtual;
    procedure Subscribe(const action: TAction<TValue>; trigger: TNotifyTrigger = AfterChange);
  end;

  TObservableBase = class(TSubscribable, IObservable)
  private
    fDependencies: TList<TObservableBase>;
    fSubscribers: TList<TObservableBase>;
  {$REGION 'Property Accessors'}
    function GetValue: TValue; virtual; abstract;
    procedure SetValue(const value: TValue); virtual; abstract;
  {$ENDREGION}
  protected
    class var ObservableStack: TStack<TObservableBase>;
    constructor Create;
    procedure ClearDependencies;
    procedure RegisterDependency;
    procedure Notify(const value: TValue; trigger: TNotifyTrigger); override;
  public
    class constructor Create;
    class destructor Destroy;
    destructor Destroy; override;
  end;

  TObservableStack = TStack<TObservableBase>;

  TObservable = class(TObservableBase)
  private
    fGetter: TFunc<TValue>;
    fSetter: TAction<TValue>;
  {$REGION 'Property Accessors'}
    function GetValue: TValue; override; final;
    procedure SetValue(const value: TValue); override; final;
  {$ENDREGION}
  public
    constructor Create(const getter: TFunc<TValue>); overload;
    constructor Create(const getter: TFunc<TValue>; const setter: TAction<TValue>); overload;
  end;

  TDependentObservable = class(TObservableBase)
  private
    fGetter: TFunc<TValue>;
    fSetter: TAction<TValue>;
    fValue: TValue;
    fIsNotifying: Boolean;
  {$REGION 'Property Accessors'}
    function GetValue: TValue; override; final;
    procedure SetValue(const value: TValue); override; final;
  {$ENDREGION}
    procedure Evaluate;
  protected
    procedure Notify(const value: TValue; trigger: TNotifyTrigger); override;
  public
    constructor Create(const getter: TFunc<TValue>); overload;
    constructor Create(const getter: TFunc<TValue>; const setter: TAction<TValue>); overload;
  end;

  TObservable<T> = class(TObservableBase, Observable<T>)
  private
    fValue: T;
    class var Comparer: IEqualityComparer<T>;
  {$REGION 'Property Accessors'}
    function GetValue: TValue; override; final;
    procedure SetValue(const value: TValue); override; final;
    function Invoke: T; overload;
    procedure Invoke(const value: T); overload;
  {$ENDREGION}
    procedure Subscribe(const action: TAction<T>; trigger: TNotifyTrigger = AfterChange);
  public
    class constructor Create;
    constructor Create; overload;
    constructor Create(const value: T); overload;
  end;

  TDependentObservable<T> = class(TObservableBase, Observable<T>)
  private
    fGetter: TFunc<T>;
    fSetter: TAction<T>;
    fValue: T;
    fIsNotifying: Boolean;
  {$REGION 'Property Accessors'}
    function GetValue: TValue; override; final;
    procedure SetValue(const value: TValue); override; final;
    function Invoke: T; overload;
    procedure Invoke(const value: T); overload;
  {$ENDREGION}
    procedure Evaluate;
    procedure Subscribe(const action: TAction<T>; trigger: TNotifyTrigger = AfterChange);
  protected
    procedure Notify(const value: TValue; trigger: TNotifyTrigger); override;
  public
    constructor Create(const getter: TFunc<T>); overload;
    constructor Create(const getter: TFunc<T>; const setter: TAction<T>); overload;
  end;

  TValueHelper = record helper for TValue
    function ToType<T>: T;
  end;

  Observable = record
    class function Create<T>: Observable<T>; overload; static; inline;
    class function Create<T>(const value: T): Observable<T>; overload; static; inline;

    class function Computed<T>(const getter: TFunc<T>): Observable<T>; overload; static; inline;
    class function Computed<T>(const getter: TFunc<T>; const setter: TAction<T>): Observable<T>; overload; static; inline;
  end;

implementation

uses
  TypInfo;
//  Spring;

function TValueHelper.ToType<T>: T;
begin
  Result := Default(T);
  if not TryAsType<T>(Result) then
    // hardcode some simple conversions for demo purpose - use Spring4D value converter later
    case Kind of
      tkUString:
        case PTypeInfo(System.TypeInfo(T)).Kind of
          tkInteger: PInteger(@Result)^ := StrToInt(AsString);
        end;
    end;
end;


{$REGION 'TObservableStackHelper'}

type
  TObservableStackHelper = class helper for TObservableStack
  public
    function Peek: TObservableBase;
  end;

function TObservableStackHelper.Peek: TObservableBase;
begin
  if Count = 0 then
    Result := nil
  else
    Result := inherited Peek;
end;

{$ENDREGION}


{$REGION 'TSubscribable'}

procedure TSubscribable.Notify(const value: TValue; trigger: TNotifyTrigger);
var
  subscriptions: PSubscriptions;
  i: Integer;
begin
  subscriptions := @fSubscriptions[trigger];
  for i := 0 to High(subscriptions^) do
    subscriptions^[i](value);
end;

procedure TSubscribable.Subscribe(const action: TAction<TValue>;
  trigger: TNotifyTrigger);
var
  subscriptions: PSubscriptions;
  count: Integer;
begin
  subscriptions := @fSubscriptions[trigger];
  count := Length(subscriptions^);
  SetLength(subscriptions^, count + 1);
  subscriptions^[count] := action;
end;

{$ENDREGION}


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
  fSubscribers := TList<TObservableBase>.Create;
end;

destructor TObservableBase.Destroy;
begin
  fDependencies.Free;
  fSubscribers.Free;
  inherited;
end;

procedure TObservableBase.ClearDependencies;
var
  i: Integer;
begin
  for i := fDependencies.Count - 1 downto 0 do
    fDependencies[i].fSubscribers.Remove(Self);
  fDependencies.Clear;
end;

procedure TObservableBase.Notify(const value: TValue; trigger: TNotifyTrigger);
var
  i: Integer;
begin
  for i := 0 to fSubscribers.Count - 1 do
    fSubscribers[i].Notify(value, trigger);
  inherited Notify(value, trigger);
end;

procedure TObservableBase.RegisterDependency;
var
  frame: TObservableBase;
begin
  frame := ObservableStack.Peek;
  if Assigned(frame) then
  begin
    if not fSubscribers.Contains(frame) then
      fSubscribers.Add(frame);
    if not frame.fDependencies.Contains(Self) then
      frame.fDependencies.Add(Self);
  end;
end;

{$ENDREGION}


{$REGION 'TObservable'}

constructor TObservable.Create(const getter: TFunc<TValue>);
begin
  Create(getter, nil);
end;

constructor TObservable.Create(const getter: TFunc<TValue>;
  const setter: TAction<TValue>);
begin
  inherited Create;
  fGetter := getter;
  fSetter := setter;
end;

function TObservable.GetValue: TValue;
begin
  RegisterDependency;
  Result := fGetter;
end;

procedure TObservable.SetValue(const value: TValue);
begin
  Notify(GetValue, BeforeChange);
  fSetter(value);
  Notify(value, AfterChange);
end;

{$ENDREGION}


{$REGION 'TDependentObservable'}

constructor TDependentObservable.Create(const getter: TFunc<TValue>);
begin
  Create(getter, nil);
end;

constructor TDependentObservable.Create(const getter: TFunc<TValue>;
  const setter: TAction<TValue>);
begin
  inherited Create;
  fGetter := getter;
  fSetter := setter;
  Evaluate;
end;

procedure TDependentObservable.Evaluate;
begin
  if fIsNotifying then Exit;
  fIsNotifying := True;
  RegisterDependency;

  ObservableStack.Push(Self);
  try
//    ClearDependencies;
    fValue := fGetter;
  finally
    ObservableStack.Pop;
    fIsNotifying := False;
  end;
end;

function TDependentObservable.GetValue: TValue;
begin
  if ObservableStack.Count > 0 then
    Evaluate;
  Result := fValue;
end;

procedure TDependentObservable.Notify(const value: TValue;
  trigger: TNotifyTrigger);
begin
  if trigger = AfterChange then
    Evaluate;
  inherited;
end;

procedure TDependentObservable.SetValue(const value: TValue);
begin
  if fIsNotifying then Exit;
  inherited Notify(fValue, BeforeChange);
  if Assigned(fSetter) then
    fSetter(value);
  inherited Notify(value, AfterChange);
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

function TObservable<T>.GetValue: TValue;
begin
  Result := TValue.From<T>(Invoke);
end;

function TObservable<T>.Invoke: T;
begin
  RegisterDependency;
  Result := fValue;
end;

procedure TObservable<T>.Invoke(const value: T);
begin
  if not Comparer.Equals(fValue, value) then
  begin
    // TODO: refactor to eliminate unnecessary TValue wrapping
    Notify(TValue.From<T>(fValue), BeforeChange);
    fValue := value;
    Notify(TValue.From<T>(value), AfterChange);
  end;
end;

procedure TObservable<T>.SetValue(const value: TValue);
begin
  Invoke(value.ToType<T>);
end;

procedure TObservable<T>.Subscribe(const action: TAction<T>;
  trigger: TNotifyTrigger);
begin
  inherited Subscribe(
    procedure(const value: TValue)
    begin
      action(value.AsType<T>)
    end, trigger);
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
  Evaluate;
end;

procedure TDependentObservable<T>.Evaluate;
begin
  if fIsNotifying then Exit;
  fIsNotifying := True;
  RegisterDependency;

  ObservableStack.Push(Self);
  try
    ClearDependencies;
    fValue := fGetter;
  finally
    ObservableStack.Pop;
    fIsNotifying := False;
  end;
end;

function TDependentObservable<T>.GetValue: TValue;
begin
  Result := TValue.From<T>(Invoke);
end;

function TDependentObservable<T>.Invoke: T;
begin
  if ObservableStack.Count > 0 then
    Evaluate;
  Result := fValue;
end;

procedure TDependentObservable<T>.Invoke(const value: T);
begin
  if fIsNotifying then Exit;
  if Assigned(fSetter) then
  begin
    inherited Notify(TValue.From<T>(fValue), BeforeChange);
    fSetter(value);
    inherited Notify(TValue.From<T>(value), AfterChange);
  end;
end;

procedure TDependentObservable<T>.Notify(const value: TValue;
  trigger: TNotifyTrigger);
begin
  if trigger = AfterChange then
    Evaluate;
  inherited;
end;

procedure TDependentObservable<T>.SetValue(const value: TValue);
begin
  Invoke(value.ToType<T>);
end;

procedure TDependentObservable<T>.Subscribe(const action: TAction<T>;
  trigger: TNotifyTrigger);
begin
  inherited Subscribe(
    procedure(const value: TValue)
    begin
      action(value.AsType<T>)
    end, trigger);
end;

{$ENDREGION}


{$REGION 'Observable'}

class function Observable.Create<T>: Observable<T>;
begin
  Result := TObservable<T>.Create();
end;

class function Observable.Create<T>(const value: T): Observable<T>;
begin
  Result := TObservable<T>.Create(value);
end;

class function Observable.Computed<T>(const getter: TFunc<T>): Observable<T>;
begin
  Result := TDependentObservable<T>.Create(getter);
end;

class function Observable.Computed<T>(const getter: TFunc<T>;
  const setter: TAction<T>): Observable<T>;
begin
  Result := TDependentObservable<T>.Create(getter, setter);
end;

{$ENDREGION}


end.
