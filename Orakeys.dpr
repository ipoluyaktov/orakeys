program Orakeys;

uses
  Vcl.Forms,
  Main in 'Main.pas' {fmMain},
  AppVersion in 'AppVersion.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
