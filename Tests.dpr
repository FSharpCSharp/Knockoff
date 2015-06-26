program Tests;

uses
  TestInsight.DUnit,
  ObservableTests in 'ObservableTests.pas',
  Knockoff.Observable in 'Knockoff.Observable.pas';

begin
  RunRegisteredTests;
end.
