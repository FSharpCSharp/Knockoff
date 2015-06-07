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
//    procedure DependentObservableEvaluatesOnlyOnceAfterChange; // not yet implemented
    procedure DependentObservableUpdatesValueWhenDependencyChanges;
  end;

implementation

{ TObservableTests }

//procedure TObservableTests.DependentObservableEvaluatesOnlyOnceAfterChange;
//var
//  o: IObservable<string>;
//  count: Integer;
//begin
//  count := 0;
//  o := TDependentObservable<string>.Create(function: string begin Inc(count); Result := 'test' end);
//  CheckEquals('test', o.Value);
//  CheckEquals('test', o.Value);
//  CheckEquals(1, count);
//end;

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
