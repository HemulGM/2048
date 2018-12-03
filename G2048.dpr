program G2048;

uses
  Vcl.Forms,
  G2048.Main in 'G2048.Main.pas' {FormMain},
  Main.CommonFunc in '..\ToOffice\Main.CommonFunc.pas',
  Main.MD5 in '..\ToOffice\Main.MD5.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  FormMain.TimerRedraw.Enabled:=True;
  Application.Run;
end.
