program SimpleMVVMDemo;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  SimpleMVVM.Binding in 'SimpleMVVM.Binding.pas',
  SimpleMVVM.Binding.Components in 'SimpleMVVM.Binding.Components.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
  ReportMemoryLeaksOnShutdown := True;
end.
