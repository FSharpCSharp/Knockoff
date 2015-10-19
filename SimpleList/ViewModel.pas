unit ViewModel;

interface

uses
  Classes,
  Knockoff.Observable;

type
  TViewModel = class(TComponent)
  private
    fItems: ObservableArray<string>;
    fItemToAdd: Observable<string>;
    fCanAdd: Observable<Boolean>;
    fSelectedItem: Observable<string>;
    fCanDelete: Observable<Boolean>;
  public
    constructor Create(AOwner: TComponent); override;

    procedure AddItem;
    procedure DeleteItem;
    procedure SortItems;

    property Items: ObservableArray<string> read fItems;
    property ItemToAdd: Observable<string> read fItemToAdd;
    property CanAdd: Observable<Boolean> read fCanAdd;
    property SelectedItem: Observable<string> read fSelectedItem;
    property CanDelete: Observable<Boolean> read fCanDelete;
  end;

implementation

{ TViewModel }

procedure TViewModel.AddItem;
begin
  if fItemToAdd <> '' then
  begin
    fItems.Add(fItemToAdd);
    fItemToAdd('');
  end;
end;

constructor TViewModel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  fItems := Observable.CreateArray<string>(['Fries', 'Eggs Benedict', 'Ham', 'Cheese']);
  fItemToAdd := Observable.Create<string>();
  fCanAdd := Observable.Computed<Boolean>(
    function: Boolean
    begin
      Result := Length(fItemToAdd) > 0;
    end);
  fSelectedItem := Observable.Create<string>('Ham');
  fCanDelete := Observable.Computed<Boolean>(
    function: Boolean
    begin
      Result := Length(fSelectedItem) > 0;
    end);
end;

procedure TViewModel.DeleteItem;
var
  i: Integer;
begin
  if fSelectedItem <> '' then
  begin
    for i := 0 to fItems.Length - 1 do
      if fItems[i] = fSelectedItem then
      begin
        fItems.Delete(i);
        Break;
      end;
  end;
end;

procedure TViewModel.SortItems;
begin
  fItems.Sort;
end;

end.
