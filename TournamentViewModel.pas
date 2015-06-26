unit TournamentViewModel;

interface

uses
  Classes,
  SimpleMVVM.Observable;

type
  TMatch = class
  private
    fHomeTeam: IObservable<string>;
    fAwayTeam: IObservable<string>;
    fHomeScore: IObservable<Integer>;
    fAwayScore: IObservable<Integer>;
    fWinner: IObservable<string>;
  public
    constructor Create(const matchName: string;
      const homeTeam: IObservable<string>;
      const awayTeam: IObservable<string>);

    procedure SaveScore;

    property HomeTeam: IObservable<string> read fHomeTeam;
    property AwayTeam: IObservable<string> read fAwayTeam;
    property HomeScore: IObservable<Integer> read fHomeScore;
    property AwayScore: IObservable<Integer> read fAwayScore;

    property Winner: IObservable<string> read fWinner;
  end;

  TTournamentViewModel = class(TComponent)
  private
    fSemiFinalOne: TMatch;
    fSemiFinalTwo: TMatch;
    fFinale: TMatch;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    // temporary until methods also work in chained expressions
    procedure SemiFinalOne_SaveScore;
    procedure SemiFinalTwo_SaveScore;
    procedure Finale_SaveScore;

    property SemiFinalOne: TMatch read fSemiFinalOne;
    property SemiFinalTwo: TMatch read fSemiFinalTwo;
    property Finale: TMatch read fFinale;
  end;

implementation

{ TTournamentViewModel }

constructor TTournamentViewModel.Create;
begin
  inherited Create(nil);

  fSemiFinalOne := TMatch.Create(
    'semifinal one',
    TObservable<string>.Create('Team 1'),
    TObservable<string>.Create('Team 2'));
  fSemiFinalTwo := TMatch.Create(
    'semifinal two',
    TObservable<string>.Create('Team 3'),
    TObservable<string>.Create('Team 4'));
  fFinale := TMatch.Create(
    'final',
    fSemiFinalOne.Winner,
    fSemiFinalTwo.Winner);
end;

destructor TTournamentViewModel.Destroy;
begin
  fFinale.Free;
  fSemiFinalTwo.Free;
  fSemiFinalOne.Free;
  inherited;
end;

procedure TTournamentViewModel.Finale_SaveScore;
begin
  fFinale.SaveScore;
end;

procedure TTournamentViewModel.SemiFinalOne_SaveScore;
begin
  fSemiFinalOne.SaveScore;
end;

procedure TTournamentViewModel.SemiFinalTwo_SaveScore;
begin
  fSemiFinalTwo.SaveScore;
end;

{ TMatch }

constructor TMatch.Create(const matchName: string;
  const homeTeam: IObservable<string>; const awayTeam: IObservable<string>);
begin
  fHomeTeam := homeTeam;
  fAwayTeam := awayTeam;
  fHomeScore := TObservable<Integer>.Create();
  fAwayScore := TObservable<Integer>.Create();
  fWinner := TObservable<string>.Create();
end;

procedure TMatch.SaveScore;
var
  homeScore, awayScore: Integer;
begin
  homeScore := fHomeScore;
  awayScore := fAwayScore;
  if homeScore > awayScore then
    fWinner(fHomeTeam)
  else if homeScore < awayScore then
    fWinner(fAwayTeam);
end;

end.
