unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TSimpleListMainForm = class(TForm)
    Edit1: TEdit;
    Button1: TButton;
    ListBox1: TListBox;
    Button2: TButton;
    Label1: TLabel;
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SimpleListMainForm: TSimpleListMainForm;

implementation

{$R *.dfm}

uses
  ViewModel,
  Knockoff.Binding;

procedure TSimpleListMainForm.FormCreate(Sender: TObject);
var
  viewModel: TViewModel;
begin
  ReportMemoryLeaksOnShutdown := True;

  viewModel := TViewModel.Create(Self);

  Bind(Edit1, 'Value', viewModel, 'ItemToAdd');
  Bind(Button1, 'Click', viewModel, 'AddItem');
  Bind(Button1, 'Enabled', viewModel, 'CanAdd');
  Bind(ListBox1, 'Options', viewModel, 'Items');
  Bind(ListBox1, 'SelectedOption', viewModel, 'SelectedItem');
  Bind(Label1, 'Text', viewModel, 'SelectedItem');

  Bind(Button2, 'Click', viewModel, 'DeleteItem');
  Bind(Button2, 'Enabled', viewModel, 'CanDelete');

  Bind(Button3, 'Click', viewModel, 'SortItems');
end;

end.
