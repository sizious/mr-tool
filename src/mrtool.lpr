program MRTool;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp,
  MRImage;

type
  { TMRToolApplication }
  TMRToolApplication = class(TCustomApplication)
  private
    procedure WriteBanner;
    function GetOperationMode: TMRMode;
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TMRToolApplication }

procedure TMRToolApplication.WriteBanner;
begin
  WriteLn(Title, CoreVersion);
end;

function TMRToolApplication.GetOperationMode: TMRMode;
begin
  Result := mmConvert;
  if HasOption('c', 'convert') then
    Result := mmConvert;
  if HasOption('e', 'extract') then
    Result := mmConvert;
  if HasOption('s', 'strip') then
    Result := mmStrip;
end;

procedure TMRToolApplication.DoRun;
var
  ErrorMsg: string;
  InputFileName, OutputFileName: TFileName;
  MRFile: TMRFile;
  Mode: TMRMode;

begin
  WriteBanner;

  // Quick check parameters
  ErrorMsg := CheckOptions('h c e s i: o:', 'help convert extract strip input: output:');
  if ErrorMsg <> '' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then
  begin
    WriteHelp;
    Terminate;
    Exit;
  end;



  InputFileName := GetOptionValue('i', 'input');
  OutputFileName := GetOptionValue('o', 'output');

  { add your program here }
  MRFile := TMRFile.Create;
  try
    MRFile.LoadFromFile(InputFileName);
    MRFile.Mode := GetOperationMode;
    MRFile.SaveToFile(OutputFileName);
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
  WriteLn('Usage: ', ExeName, ' <command> <infile> [outfile]');
  WriteLn;
  WriteLn('Commands:');
  WriteLn('  -c, --convert    converts <infile> to <outfile>');
  WriteLn('  -e, --extract    extracts <infile> to an ip.bin');
  WriteLn('  -s, --strip      removes logo from an ip.bin');
  WriteLn;
  WriteLn('  -h, --help    show this help');
end;

var
  Application: TMRToolApplication;

{$R *.res}

begin
  Application := TMRToolApplication.Create(nil);
  Application.Title:='MR-Tool';
  Application.Run;
  Application.Free;
end.

