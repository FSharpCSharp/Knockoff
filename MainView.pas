unit MainView;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Knockoff.Binding;

type
  TMainViewForm = class(TForm)

    GroupBox1: TGroupBox;
    [Bind('Value', 'FirstName')]
    edtFirstName: TEdit;
    [Bind('Value', 'LastName')]
    edtLastName: TEdit;
    [Bind('Text', 'FullName')]
    lblFullName: TLabel;

    GroupBox2: TGroupBox;
    [Bind('Click', 'RegisterClick')]
    [Bind('Disabled', 'HasClickedTooManyTimes')]
    btnRegisterClick: TButton;
    [Bind('Text', 'NumberOfClicks')]
    lblClickCount: TLabel;
    [Bind('Click', 'ResetClicks')]
    [Bind('Visible', 'HasClickedTooManyTimes')]
    btnResetClicks: TButton;
    [Bind('Visible', 'HasClickedTooManyTimes')]
    lblClickedTooManyTimes: TLabel;

    GroupBox3: TGroupBox;
    [Bind('Value', 'ChosenTicket')]
    [BindOptions('Tickets')]
    [BindOptionsCaption('Choose...')]
    [BindOptionsText('Name')]
    cbTickets: TComboBox;
    [Bind('Text', 'ChosenTicket.Price')]
    lblPrice: TLabel;
    [Bind('Click', 'ResetTicket')]
    [Bind('Enabled', 'ChosenTicket')]
    btnClear: TButton;

    GroupBox4: TGroupBox;
    [Bind('Value', 'Country')]
    [BindOptions('AvailableCountries')]
    [BindOptionsCaption('Choose...')]
    cbAvailableCountries: TComboBox;

    procedure FormCreate(Sender: TObject);
  end;

var
  MainViewForm: TMainViewForm;

implementation

{$R *.dfm}

uses
  MainViewModel;

{ TMainForm }

procedure TMainViewForm.FormCreate(Sender: TObject);
begin
  ApplyBindings(Self, TViewModel.Create('John', 'Doe'));
end;

end.
