program SimpleMVVMDemo;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  SimpleMVVM in 'SimpleMVVM.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
  ReportMemoryLeaksOnShutdown := True;
end.
