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
  TAction<T> = reference to procedure (const Arg1: T);

  IObservable = interface(IInvokable)
    ['{3F78EF38-FA16-4E08-AD8D-3FD9A5E44BEF}']
  {$REGION 'Property Accessors'}
    function GetValue: TValue;
    procedure SetValue(const value: TValue);
  {$ENDREGION}
    property Value: TValue read GetValue write SetValue;
  end;

  {$M+}
  IReadOnlyObservable<T> = reference to function: T;
  IObservable<T> = interface(IReadOnlyObservable<T>)
  {$REGION 'Property Accessors'}
    procedure Invoke(const value: T); overload;
  {$ENDREGION}
  end;
  {$M-}

  TObservableBase = class(TInterfacedObject, IObservable)
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
    procedure Notify; virtual;
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
    fNeedsEvaluation: Boolean;
  {$REGION 'Property Accessors'}
    function GetValue: TValue; override; final;
    procedure SetValue(const value: TValue); override; final;
  {$ENDREGION}
    procedure Evaluate;
  protected
    procedure Notify; override;
  public
    constructor Create(const getter: TFunc<TValue>); overload;
    constructor Create(const getter: TFunc<TValue>; const setter: TAction<TValue>); overload;
  end;

  TObservable<T> = class(TObservableBase, IObservable<T>)
  private
    fValue: T;
    class var Comparer: IEqualityComparer<T>;
    class constructor Create;
  {$REGION 'Property Accessors'}
    function GetValue: TValue; override; final;
    procedure SetValue(const value: TValue); override; final;
    function Invoke: T; overload;
    procedure Invoke(const value: T); overload;
  {$ENDREGION}
  public
    constructor Create; overload;
    constructor Create(const value: T); overload;
  end;

  TDependentObservable<T> = class(TObservableBase, IObservable<T>)
  private
    fGetter: TFunc<T>;
    fSetter: TAction<T>;
    fValue: T;
    fIsNotifying: Boolean;
    fNeedsEvaluation: Boolean;
  {$REGION 'Property Accessors'}
    function GetValue: TValue; override; final;
    procedure SetValue(const value: TValue); override; final;
    function Invoke: T; overload;
    procedure Invoke(const value: T); overload;
  {$ENDREGION}
    procedure Evaluate;
  protected
    procedure Notify; override;
  public
    constructor Create(const getter: TFunc<T>); overload;
    constructor Create(const getter: TFunc<T>; const setter: TAction<T>); overload;
  end;

  TValueHelper = record helper for TValue
    function ToType<T>: T;
  end;

  Observable = record
    class function Create<T>: IObservable<T>; overload; static; inline;
    class function Create<T>(const value: T): IObservable<T>; overload; static; inline;

    class function Computed<T>(const getter: TFunc<T>): IObservable<T>; overload; static; inline;
    class function Computed<T>(const getter: TFunc<T>; const setter: TAction<T>): IObservable<T>; overload; static; inline;
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

procedure TObservableBase.Notify;
var
  i: Integer;
begin
  for i := 0 to fSubscribers.Count - 1 do
    fSubscribers[i].Notify;
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
  fSetter(value);
  Notify;
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
  fNeedsEvaluation := True;
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
    fNeedsEvaluation := False;
  end;
end;

function TDependentObservable.GetValue: TValue;
begin
  if fNeedsEvaluation or (ObservableStack.Count > 0) then
    Evaluate;
  Result := fValue;
end;

procedure TDependentObservable.Notify;
begin
  Evaluate;
  inherited;
end;

procedure TDependentObservable.SetValue(const value: TValue);
begin
  if fIsNotifying then Exit;
  if Assigned(fSetter) then
    fSetter(value);
  inherited Notify;
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
    fValue := value;
    Notify;
  end;
end;

procedure TObservable<T>.SetValue(const value: TValue);
begin
  Invoke(value.ToType<T>);
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
    fNeedsEvaluation := False;
  end;
end;

function TDependentObservable<T>.GetValue: TValue;
begin
  Result := TValue.From<T>(Invoke);
end;

function TDependentObservable<T>.Invoke: T;
begin
  if fNeedsEvaluation or (ObservableStack.Count > 0) then
    Evaluate;
  Result := fValue;
end;

procedure TDependentObservable<T>.Invoke(const value: T);
begin
  if fIsNotifying then Exit;
  if Assigned(fSetter) then
    fSetter(value);
  inherited Notify;
end;

procedure TDependentObservable<T>.Notify;
begin
  Evaluate;
  inherited;
end;

procedure TDependentObservable<T>.SetValue(const value: TValue);
begin
  Invoke(value.ToType<T>);
end;

{$ENDREGION}


{$REGION 'Observable'}

class function Observable.Create<T>: IObservable<T>;
begin
  Result := TObservable<T>.Create();
end;

class function Observable.Create<T>(const value: T): IObservable<T>;
begin
  Result := TObservable<T>.Create(value);
end;

class function Observable.Computed<T>(const getter: TFunc<T>): IObservable<T>;
begin
  Result := TDependentObservable<T>.Create(getter);
end;

class function Observable.Computed<T>(const getter: TFunc<T>;
  const setter: TAction<T>): IObservable<T>;
begin
  Result := TDependentObservable<T>.Create(getter, setter);
end;

{$ENDREGION}


end.
