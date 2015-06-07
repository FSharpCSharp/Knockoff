program SimpleMVVMDemo;

uses
  Forms,
  MainView in 'MainView.pas' {MainViewForm},
  MainViewModel in 'MainViewModel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainViewForm, MainViewForm);
  Application.Run;
  ReportMemoryLeaksOnShutdown := True;
end.
