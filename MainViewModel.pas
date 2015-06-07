unit MainViewModel;

interface

uses
  Classes,
  Generics.Collections,
  SimpleMVVM.Observable;

type
  TTicket = class
  private
    fName: string;
    fPrice: Currency;
  public
    constructor Create(const name: string; price: Currency);
    property Name: string read FName write FName;
    property Price: Currency read FPrice write FPrice;
  end;

  TViewModel = class(TComponent)
  private
    fLastName: IObservable<string>;
    fFirstName: IObservable<string>;
    fFullName: IObservable<string>;
    fNumberOfClicks: IObservable<Integer>;
    fHasClickedTooManyTimes: IObservable<Boolean>;
    fChosenTicket: IObservable<TTicket>;
    fTickets: TList<TTicket>;
    fAvailableCountries: TArray<string>;
    fCountry: IObservable<string>;

    function GetLastName: string;
    procedure SetLastName(const value: string);
  public
    constructor Create(const firstName, lastName: string); reintroduce;
    destructor Destroy; override;

    procedure RegisterClick;
    procedure ResetClicks;

    procedure ResetTicket;

    property LastName: string read GetLastName write SetLastName;
    property FirstName: IObservable<string> read fFirstName;
    property FullName: IObservable<string> read fFullName;

    property NumberOfClicks: IObservable<Integer> read fNumberOfClicks;
    property HasClickedTooManyTimes: IObservable<Boolean> read fHasClickedTooManyTimes;

    property ChosenTicket: IObservable<TTicket> read fChosenTicket;
    property Tickets: TList<TTicket> read fTickets;

    property AvailableCountries: TArray<string> read fAvailableCountries;
    property Country: IObservable<string> read fCountry;
  end;

implementation

{ TTicket }

constructor TTicket.Create(const name: string; price: Currency);
begin
  fName := name;
  fPrice := price;
end;

{ TViewModel }

constructor TViewModel.Create(const firstName, lastName: string);
begin
  inherited Create(nil);

  // Example 1
  fLastName := TObservable<string>.Create(lastName);
  fFirstName := TObservable<string>.Create(firstName);
  fFullName := TDependentObservable<string>.Create(
    function: string
    begin
      Result := fFirstName.Value + ' ' + fLastName.Value;
    end);

  // Example 2
  fNumberOfClicks := TObservable<Integer>.Create;
  fHasClickedTooManyTimes := TDependentObservable<Boolean>.Create(
    function: Boolean
    begin
      Result := fNumberOfClicks.Value >= 3;
    end);

  // Example 3
  fChosenTicket := TObservable<TTicket>.Create;
  fTickets := TObjectList<TTicket>.Create;
  fTickets.AddRange([
    TTicket.Create('Economy', 199.95),
    TTicket.Create('Business', 449.22),
    TTicket.Create('First Class', 1199.99)]);

  // Example 4
  fAvailableCountries := TArray<string>.Create('AU', 'NZ', 'US');
  fCountry := TObservable<string>.Create;
end;

destructor TViewModel.Destroy;
begin
  fTickets.Free;
  inherited;
end;

function TViewModel.GetLastName: string;
begin
  Result := fLastName.Value;
end;

procedure TViewModel.RegisterClick;
begin
  fNumberOfClicks.Value := fNumberOfClicks.Value + 1;
end;

procedure TViewModel.ResetClicks;
begin
  fNumberOfClicks.Value := 0;
end;

procedure TViewModel.ResetTicket;
begin
  fChosenTicket.Value := nil;
end;

procedure TViewModel.SetLastName(const value: string);
begin
  fLastName.Value := value;
end;

end.
