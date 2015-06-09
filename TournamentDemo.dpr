program TournamentDemo;

uses
  Forms,
  TournamentView in 'TournamentView.pas' {TournamentViewForm},
  TournamentViewModel in 'TournamentViewModel.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TTournamentViewForm, TournamentViewForm);
  Application.Run;
end.
