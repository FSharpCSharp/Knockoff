unit MainUnit;

interface

procedure Main;

implementation

uses
  Knockoff.Observable;

type
  TViewModel = class
  strict private
    fPersonName: Observable<string>;
  public
    constructor Create(const personName: string);
    property PersonName: Observable<string> read fPersonName;
  end;

constructor TViewModel.Create(const personName: string);
begin
  fPersonName := Observable.Create(personName);
end;

procedure Main;
var
  myViewModel: TViewModel;
  sub: ISubscribable<string>;
begin
  myViewModel := TViewModel.Create('John');
  try
    Writeln(myViewModel.PersonName());
    sub := myViewModel.PersonName as ISubscribable<string>;
    sub.Subscribe(
//    myViewModel.PersonName.Subscribe(
      procedure (const newValue: string)
      begin
        Writeln('old value: ' + newValue)
      end, BeforeChange);
    sub := myViewModel.PersonName as ISubscribable<string>;
    sub.Subscribe(
//    myViewModel.PersonName.Subscribe(
      procedure (const newValue: string)
      begin
        Writeln('value changed to: ' + newValue)
      end);
    myViewModel.PersonName('Bob');
    Writeln(myViewModel.PersonName());
  finally
    myViewModel.Free;
  end;
  ReportMemoryLeaksOnShutdown := True;
end;

end.
