program MRTool;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, MRImage, CustApp
  { you can add units after this };

type
  { TMRToolApplication }
  TMRToolApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TMRToolApplication }

procedure TMRToolApplication.DoRun;
var
  ErrorMsg: String;
  MRFile: TMRFile;

begin
  // quick check parameters
  ErrorMsg := CheckOptions('h', 'help');
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  { add your program here }
  MRFile := TMRFile.Create;
  try
    MRFile.LoadFromFile('iplogo.mr');
    MRFile.SaveToFile('iplogo.png');
    MRFile.SaveToFile('iplogo.gif');
    MRFile.SaveToFile('iplogo.jpg');
    MRFile.SaveToFile('iplogo.dib');
  finally
    MRFile.Free;
  end;

  // stop program loop
  Terminate;
end;

constructor TMRToolApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

destructor TMRToolApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TMRToolApplication.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' -h');
end;

var
  Application: TMRToolApplication;

begin
  Application := TMRToolApplication.Create(nil);
  Application.Title:='MR-Tool';
  Application.Run;
  Application.Free;
end.

