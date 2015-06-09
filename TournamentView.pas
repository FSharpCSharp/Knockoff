unit TournamentView;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, SimpleMVVM.Binding;

type
  TTournamentViewForm = class(TForm)

    [Bind('Value', 'SemiFinalOne.HomeScore')]
    Edit1: TEdit;
    [Bind('Value', 'SemiFinalOne.AwayScore')]
    Edit2: TEdit;
    [Bind('Value', 'SemiFinalTwo.HomeScore')]
    Edit3: TEdit;
    [Bind('Value', 'SemiFinalTwo.AwayScore')]
    Edit4: TEdit;
    [Bind('Enabled', 'Finale.CanPlay')]
    [Bind('Value', 'Finale.HomeScore')]
    Edit5: TEdit;
    [Bind('Enabled', 'Finale.CanPlay')]
    [Bind('Value', 'Finale.AwayScore')]
    Edit6: TEdit;

    [Bind('Text', 'SemiFinalOne.HomeTeam')]
    Label1: TLabel;
    [Bind('Text', 'SemiFinalOne.AwayTeam')]
    Label2: TLabel;
    [Bind('Text', 'SemiFinalTwo.HomeTeam')]
    Label3: TLabel;
    [Bind('Text', 'SemiFinalTwo.AwayTeam')]
    Label4: TLabel;
    [Bind('Text', 'Finale.HomeTeam')]
    Label5: TLabel;
    [Bind('Text', 'Finale.AwayTeam')]
    Label6: TLabel;
    [Bind('Text', 'Finale.Winner')]
    Label7: TLabel;

    [Bind('Click', 'SemiFinalOne_SaveScore')]
    Button1: TButton;
    [Bind('Click', 'SemiFinalTwo_SaveScore')]
    Button2: TButton;
    [Bind('Click', 'Finale_SaveScore')]
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  TournamentViewForm: TTournamentViewForm;

implementation

{$R *.dfm}

uses
  TournamentViewModel;

procedure TTournamentViewForm.FormCreate(Sender: TObject);
begin
  ApplyBindings(Self, TTournamentViewModel.Create);
end;

end.
