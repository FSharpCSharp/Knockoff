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
