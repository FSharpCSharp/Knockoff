unit MainViewModel;

interface

uses
  Classes,
  Generics.Collections,
  Knockoff.Observable;

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
    fLastName: Observable<string>;
    fFirstName: Observable<string>;
    fFullName: Observable<string>;
    fNumberOfClicks: Observable<Integer>;
    fHasClickedTooManyTimes: Observable<Boolean>;
    fChosenTicket: Observable<TTicket>;
    fTickets: TList<TTicket>;
    fAvailableCountries: TArray<string>;
    fCountry: Observable<string>;
    fActive: Observable<Boolean>;

    fNumber: Observable<Integer>;

    function GetLastName: string;
    procedure SetLastName(const value: string);
    function GetActive: Boolean;
    procedure SetActive(const value: Boolean);
  public
    constructor Create(const firstName, lastName: string); reintroduce;
    destructor Destroy; override;

    procedure RegisterClick;
    procedure ResetClicks;

    procedure ResetTicket;

    property LastName: string read GetLastName write SetLastName;
    property FirstName: Observable<string> read fFirstName;
    property FullName: Observable<string> read fFullName;

    property NumberOfClicks: Observable<Integer> read fNumberOfClicks;
    property HasClickedTooManyTimes: Observable<Boolean> read fHasClickedTooManyTimes;

    property ChosenTicket: Observable<TTicket> read fChosenTicket;
    property Tickets: TList<TTicket> read fTickets;

    property AvailableCountries: TArray<string> read fAvailableCountries;
    property Country: Observable<string> read fCountry;

    property Active: Boolean read GetActive write SetActive;

    property Number: Observable<Integer> read fNumber;
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
var
  field: Integer;
begin
  inherited Create(nil);

  // Example 1
  fLastName := TObservable<string>.Create(lastName);
  fFirstName := TObservable<string>.Create(firstName);
  fFullName := TDependentObservable<string>.Create(
    function: string
    begin
      Result := fFirstName + ' ' + fLastName;
    end);

  // Example 2
  fNumberOfClicks := TObservable<Integer>.Create();
  fHasClickedTooManyTimes := TDependentObservable<Boolean>.Create(
    function: Boolean
    begin
      Result := fNumberOfClicks >= 3;
    end);

  // Example 3
  fChosenTicket := TObservable<TTicket>.Create();
  fTickets := TObjectList<TTicket>.Create;
  fTickets.AddRange([
    TTicket.Create('Economy', 199.95),
    TTicket.Create('Business', 449.22),
    TTicket.Create('First Class', 1199.99)]);

  // Example 4
  fAvailableCountries := TArray<string>.Create('AU', 'NZ', 'US');
  fCountry := TObservable<string>.Create();

  // Example 5;
  fActive := TObservable<Boolean>.Create(True);

  fNumber := TDependentObservable<Integer>.Create(
    function: Integer
    begin
      Result := field;
    end,
    procedure (const value: Integer)
    begin
      if value > 10 then
        field := 10
      else if value < -10 then
        field := -10
      else
        field := value;
    end);
end;

destructor TViewModel.Destroy;
begin
  fTickets.Free;
  inherited;
end;

function TViewModel.GetActive: Boolean;
begin
  Result := fActive;
end;

function TViewModel.GetLastName: string;
begin
  Result := fLastName;
end;

procedure TViewModel.RegisterClick;
begin
  fNumberOfClicks(fNumberOfClicks + 1);
end;

procedure TViewModel.ResetClicks;
begin
  fNumberOfClicks(0);
end;

procedure TViewModel.ResetTicket;
begin
  fChosenTicket(nil);
end;

procedure TViewModel.SetActive(const value: Boolean);
begin
  fActive(value);
end;

procedure TViewModel.SetLastName(const value: string);
begin
  fLastName(value);
end;

end.
