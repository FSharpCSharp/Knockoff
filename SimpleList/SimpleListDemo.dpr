program SimpleListDemo;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {SimpleListMainForm},
  ViewModel in 'ViewModel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSimpleListMainForm, SimpleListMainForm);
  Application.Run;
end.
