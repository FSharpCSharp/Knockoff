unit ObservableTests;

interface

uses
  TestFramework,
  SimpleMVVM.Observable;

type
  TObservableTests = class(TTestCase)
  published
    procedure ObservableReturnsValue;
    procedure ObservableSetValueChangesValue;

    procedure DependentObservableReturnsValue;
    procedure DependentObservableEvaluatesOnlyOnceAfterChange;
    procedure DependentObservableUpdatesValueWhenDependencyChanges;

    procedure DependentObservableClearsOldDependencies;
  end;

implementation

type
  KO = Observable;

{ TObservableTests }

procedure TObservableTests.DependentObservableClearsOldDependencies;
var
  a: IObservable<Boolean>;
  b, c: IObservable<string>;
  o: IObservable<string>;
  count: Integer;
begin
  a := KO.Create(False);
  b := KO.Create('true');
  c := KO.Create('false');
  o := KO.Computed<string>(
    function: string
    begin
      Inc(count);
      if a.Value then
        Result := b.Value
      else
        Result := c.Value
    end);
  count := 0;
  CheckEquals('false', o.Value);
  CheckEquals(0, count);
  b.Value := 'TRUE';
  CheckEquals(0, count);
  c.Value := 'FALSE';
  CheckEquals('FALSE', o.Value);
  CheckEquals(1, count);
  a.Value := True;
  CheckEquals('TRUE', o.Value);
  CheckEquals(2, count);
  c.Value := 'false';
  CheckEquals(2, count);
end;

procedure TObservableTests.DependentObservableEvaluatesOnlyOnceAfterChange;
var
  o: IObservable<string>;
  count: Integer;
begin
  count := 0;
  o := TDependentObservable<string>.Create(function: string begin Inc(count); Result := 'test' end);
  CheckEquals('test', o.Value);
  CheckEquals('test', o.Value);
  CheckEquals(1, count);
end;

procedure TObservableTests.DependentObservableReturnsValue;
var
  o: IObservable<string>;
begin
  o := TDependentObservable<string>.Create(function: string begin Result := 'test' end);
  CheckEquals('test', o.Value);
end;

procedure TObservableTests.DependentObservableUpdatesValueWhenDependencyChanges;
var
  o1, o2: IObservable<string>;
  called: Boolean;
begin
  o1 := TObservable<string>.Create;
  o2 := TDependentObservable<string>.Create(function: string begin Result := o1.Value; called := True; end);
  CheckEquals('', o2.Value);
  called := False;
  o1.Value := 'test';
  Check(called);
  CheckEquals('test', o2.Value);
end;

procedure TObservableTests.ObservableReturnsValue;
var
  o: IObservable<string>;
begin
  o := TObservable<string>.Create('test');
  CheckEquals('test', o.Value);
end;

procedure TObservableTests.ObservableSetValueChangesValue;
var
  o: IObservable<string>;
begin
  o := TObservable<string>.Create;
  CheckEquals('', o.Value);
  o.Value := 'test';
  CheckEquals('test', o.Value);
end;

initialization
  RegisterTest(TObservableTests.Suite);

end.
