program ObservableDemo;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  MainUnit;

begin
  try
    Main;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Readln;
end.
