program Tests;

uses
  TestInsight.DUnit,
  ObservableTests in 'ObservableTests.pas',
  SimpleMVVM.Observable in 'SimpleMVVM.Observable.pas';

begin
  RunRegisteredTests;
end.
