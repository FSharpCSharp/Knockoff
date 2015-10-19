unit ObservableTests;

interface

uses
  TestFramework,
  Knockoff.Observable;

type
  TObservableTests = class(TTestCase)
  published
    procedure ObservableReturnsValue;
    procedure ObservableSetValueChangesValue;

    procedure DependentObservableReturnsValue;
    procedure DependentObservableEvaluatesOnlyOnceAfterChange;
    procedure DependentObservableUpdatesValueWhenDependencyChanges;

    procedure DependentObservableClearsOldDependencies;
    procedure DependentObservableNotifiesMultipleDependenciesProperly;

    procedure ObservableArrayNotifyAdded;
    procedure ObservableArrayNotifyChanged;
    procedure ObservableArrayNotifyDelete;
    procedure ObservableArrayIndexAccessIsTracked;
  end;

  KO = Observable;

implementation

{ TObservableTests }

procedure TObservableTests.DependentObservableClearsOldDependencies;
var
  a: Observable<Boolean>;
  b, c: Observable<string>;
  o: Observable<string>;
  count: Integer;
begin
  a := KO.Create(False);
  b := KO.Create('true');
  c := KO.Create('false');
  o := KO.Computed<string>(
    function: string
    begin
      Inc(count);
      if a then
        Result := b
      else
        Result := c
    end);
  count := 0;
  CheckEquals('false', o);
  CheckEquals(0, count);
  b('TRUE');
  CheckEquals(0, count);
  c('FALSE');
  CheckEquals('FALSE', o);
  CheckEquals(1, count);
  a(True);
  CheckEquals('TRUE', o);
  CheckEquals(2, count);
  c('false');
  CheckEquals(2, count);
end;

procedure TObservableTests.DependentObservableEvaluatesOnlyOnceAfterChange;
var
  o: Observable<string>;
  count: Integer;
begin
  count := 0;
  o := KO.Computed<string>(function: string begin Inc(count); Result := 'test' end);
  CheckEquals('test', o);
  CheckEquals('test', o);
  CheckEquals(1, count);
end;

procedure TObservableTests.DependentObservableNotifiesMultipleDependenciesProperly;
var
  o: Observable<Integer>;
  dependency1, dependency2: Observable<Boolean>;
  callCount1, callCount2: Integer;
begin
  o := KO.Create<Integer>(0);
  dependency1 := KO.Computed<Boolean>(
    function: Boolean
    begin
      Result := o < 10;
      Inc(callCount1);
    end);
  dependency2 := KO.Computed<Boolean>(
    function: Boolean
    begin
      Result := o < 10;
      Inc(callCount2);
    end);
  CheckEquals(1, callCount1);
  CheckEquals(1, callCount2);
  Check(o < 10);
  CheckEquals(1, callCount1);
  CheckEquals(1, callCount2);
  o(o+1);
  CheckEquals(2, callCount1);
  CheckEquals(2, callCount2);
end;

procedure TObservableTests.DependentObservableReturnsValue;
var
  o: Observable<string>;
begin
  o := KO.Computed<string>(function: string begin Result := 'test' end);
  CheckEquals('test', o);
end;

procedure TObservableTests.DependentObservableUpdatesValueWhenDependencyChanges;
var
  o1, o2: Observable<string>;
  called: Boolean;
begin
  o1 := KO.Create<string>();
  o2 := KO.Computed<string>(function: string begin Result := o1; called := True; end);
  CheckEquals('', o2);
  called := False;
  o1('test');
  Check(called);
  CheckEquals('test', o2);
end;

procedure TObservableTests.ObservableArrayIndexAccessIsTracked;
var
  o: ObservableArray<string>;
  o2: Observable<Boolean>;
  called: Boolean;
begin
  o := KO.CreateArray<string>(['a', 'b']);
  with o do // avoid dependency on o itself inside the DependentObservable
    o2 := KO.Computed<Boolean>(
      function: Boolean
      begin
        Result := Items[1] = 'c'; // access Items property to check if it is properly tracked
        called := True;
      end);
  CheckFalse(o2);
  called := False;
  o[1] := 'c';
  CheckTrue(called);
  CheckTrue(o2);
end;

procedure TObservableTests.ObservableArrayNotifyAdded;
var
  o: ObservableArray<string>;
  o2: Observable<Integer>;
  count: Integer;
  values: TArray<string>;
begin
  o := KO.CreateArray<string>();
  o2 := KO.Computed<Integer>(
    function: Integer
    begin
      Inc(count);
      Result := o.Length;
    end);
  count := 0;
  o(['a', 'b']);
  values := o;
  CheckEquals(1, count);
  o.Add('c');
  values := o;
  CheckEquals(2, count);

  with o do
  begin
    Add('d');
    Add('e');
  end;
  values := o;
  CheckEquals(4, count);
end;

procedure TObservableTests.ObservableArrayNotifyChanged;
var
  o: ObservableArray<string>;
  o2: Observable<Integer>;
  count: Integer;
begin
  o := KO.CreateArray<string>(['a', 'b']);
  o2 := KO.Computed<Integer>(
    function: Integer
    begin
      Inc(count);
      Result := o.Length;
    end);
  count := 0;
  o[1] := 'c';
  CheckEquals(1, count);
end;

procedure TObservableTests.ObservableArrayNotifyDelete;
var
  o: ObservableArray<string>;
  o2: Observable<Integer>;
  count: Integer;
  values: TArray<string>;
begin
  o := KO.CreateArray<string>(['a', 'b']);
  o2 := KO.Computed<Integer>(
    function: Integer
    begin
      Inc(count);
      Result := o.Length;
    end);
  count := 0;
  o.Delete(0);
  CheckEquals(1, count);
  values := o;
  CheckEquals(1, Length(values));
  CheckEquals('b', values[0]);
end;

procedure TObservableTests.ObservableReturnsValue;
var
  o: Observable<string>;
begin
  o := KO.Create('test');
  CheckEquals('test', o);
end;

procedure TObservableTests.ObservableSetValueChangesValue;
var
  o: Observable<string>;
begin
  o := KO.Create<string>();
  CheckEquals('', o);
  o('test');
  CheckEquals('test', o);
end;

initialization
  RegisterTest(TObservableTests.Suite);

end.
