unit MainView;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Knockoff.Binding, Vcl.Samples.Spin;

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
    SpinEdit1: TSpinEdit;

    procedure FormCreate(Sender: TObject);
  end;

var
  MainViewForm: TMainViewForm;

implementation

{$R *.dfm}

uses
  Rtti,
  Knockoff.Observable,
  Knockoff.Binding.Components,
  MainViewModel;

var
  vm: TViewModel;

type
  TSpinEditBinding = class(TBinding<TSpinEdit>)
  protected
    procedure HandleChange(Sender: TObject);
    function InitGetValue(const observable: IObservable): TFunc<TValue>; override;
    procedure InitTarget; override;
  end;

{ TMainForm }

procedure TMainViewForm.FormCreate(Sender: TObject);
begin
  vm := TViewModel.Create('John', 'Doe');
  ApplyBindings(Self, vm);
  TSpinEditBinding.Create(SpinEdit1, vm.Number as IObservable);
end;

{ TSpinEditBinding }

procedure TSpinEditBinding.HandleChange(Sender: TObject);
begin
  Source.Value := Target.Value;
end;

function TSpinEditBinding.InitGetValue(
  const observable: IObservable): TFunc<TValue>;
begin
  Result :=
    function: TValue
    begin
      Target.Value := observable.Value.AsInteger;
    end;
end;

procedure TSpinEditBinding.InitTarget;
begin
  Target.OnChange := HandleChange;
end;

end.
