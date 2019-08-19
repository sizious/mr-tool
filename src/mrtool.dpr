{
  MR-TOOL Created by kRYPT_
  Updated by [big_fury]SiZiOUS.
  http://sbibuilder.shorturl.com/

  Changes :
  
  1)  Rename '-scan' command to '-sega'. I would have guessed that '-scan' scans
      a BMP image to check if it'll convert to a MR image OK meaning, being
      able to "fit in a normal IP.BIN" and it being within the size, resolution,
      and depth (24-bit BMP) limit, as well as check how many colors there are
      in the image.

  2)  Which brings me to my second idea; use '-scan' to check BMP image to check
      if it'll convert to a MR image OK.

  (Thx LyingWake)
}

program mrtool;

{$APPTYPE CONSOLE}
{$R mrtool.res}

uses
  SysUtils,
  mrtool_core in 'mrtool_core.pas';

const
  Version = '0.6';
  WrapStr = #13 + #10;
  
type
  TCommandType = (ctNoSwitch, ctInvalid, ctHelp, ctVersion, ctInfo, ctBmp, ctMr,
                  ctInj, ctExt, ctStrip, ctScan, ctSega);

  TConsoleMR = class(TMRFile)
    public
      procedure Log(Msg:String); override;
      function GetCommandType : TCommandType;
    end;

var
  MR : TConsoleMR;
  CmdType : TCommandType;
  InFile,
  OutFile : string;

//------------------------------------------------------------------------------

procedure ShowHelp;
begin
  WriteLn('usage: mrtool <command> <infile> [outfile]');
  WriteLn;
  WriteLn('commands: -info    dumps the .mr header');
  WriteLn('          -scan    load image to check if it''ll convert to a .mr image OK');
  WriteLn('          -bmp     converts a .mr to a .bmp');
  WriteLn('          -mr      converts a .bmp to a .mr');
  WriteLn('          -inj     injects a .mr into an ip.bin');
  WriteLn('          -ext     extracts a .mr from an ip.bin');
  WriteLn('          -strip   removes logo from an ip.bin');
  WriteLn('          -sega    extracts tm and sega .mr files from an ip.bin');
  WriteLn;
  WriteLn('          -help    show this help');
  WriteLn('          -ver     show some informations...');
end;

//------------------------------------------------------------------------------

procedure ShowVersion;
begin
  WriteLn('This source code was found in the net... I used it for my IP.BIN'
    + ' Creator.' + WrapStr);
  WriteLn('[big_fury]SiZiOUS was here since core v0.6...' + WrapStr);
  WriteLn('This''s a cool MR pictures tool, it rocks but it was some "buggy" :)');
  WriteLn('kRYPT_, your are awesome, keep up the great work !' + WrapStr);
  WriteLn('- SiZ! ;)' + WrapStr);
  WriteLn('But... the question''s... kRYPT_ where are you ? :/');
end;

//------------------------------------------------------------------------------

function TConsoleMR.GetCommandType : TCommandType;
var
  pcstr : string;
  
begin
  Result := ctInvalid;
  pcstr := LowerCase(ParamStr(1));

  if (pcstr = '') then Result := ctNoSwitch;
  if (pcstr = '?') or (pcstr = '/?') or (pcstr = '-help') then Result := ctHelp;
  if (pcstr = '-info') then Result := ctInfo;
  if (pcstr = '-bmp') then Result := ctBmp;
  if (pcstr = '-inj') then Result := ctInj;
  if (pcstr = '-ext') then Result := ctExt;
  if (pcstr = '-mr') then Result := ctMr;
  if (pcstr = '-scan') then Result := ctScan;
  if (pcstr = '-strip') then Result := ctStrip;
  if (pcstr = '-ver') then Result := ctVersion;
  if (pcstr = '-sega') then Result := ctSega;
end;

//------------------------------------------------------------------------------

procedure TConsoleMR.Log(Msg : string);
begin
  WriteLn(Msg);
end;

//------------------------------------------------------------------------------

begin
  WriteLn('MR-TOOL Console v'+Version+' (Core v' + CoreVersion+') by kRYPT_ (krypt@mountaincable.net)');
  WriteLn('Updated by [big_fury]SiZiOUS - http://sbibuilder.shorturl.com/' + WrapStr);

  MR := TConsoleMR.Create;
  try

    with MR do
    begin
      Verbose := False;
      CmdType := GetCommandType;

      //Vérification si on a tous les paramètres qu'il faut.
      if (CmdType = ctInfo) or (CmdType = ctBmp) or (CmdType = ctMr)
        or (CmdType = ctInj) or (CmdType = ctExt) or (CmdType = ctScan)
        or (CmdType = ctStrip) or (CmdType = ctSega) then
          if (ParamCount < 2) then
          begin
            WriteLn('Missing parameters...' + WrapStr);
            ShowHelp;
            Exit;
          end else begin
            //Nous avons tous les paramètres. On va vérifier si le fichier
            //d'entrée existe
            InFile := ExpandFileName(ParamStr(2));
            OutFile := ExpandFileName(ParamStr(3));
            if not FileExists(InFile) then
            begin
              Log('Source file not found : ' + InFile);
              Exit;
            end;
          end;

      case CmdType of
        ctInvalid : Log('Invalid switch : ' + ParamStr(1));
        ctNoSwitch: ShowHelp;
        ctHelp    : ShowHelp;
        ctVersion : ShowVersion;                               
        ctInfo    : if LoadFromMR(InFile, 0) then ShowInfo;
        ctBmp     : if LoadFromMR(InFile, 0) then
                    begin
                      if OutFile = '' then
                        OutFile := ChangeFileExt(InFile, '.bmp');
                      SaveToBMP(OutFile, True);
                    end;
        ctMr      : if MR.LoadFromBMP(InFile) then
                    begin
                      if OutFile = '' then
                        OutFile := ChangeFileExt(InFile, '.mr');
                      MR.SaveToMR(OutFile,0);
                    end;
        ctInj     : if LoadFromMR(InFile, 0) then
                    begin
                      if OutFile = '' then OutFile := 'IP.BIN';
                      if not FileExists(OutFile) then
                      begin
                        Log('Error : ' + OutFile + ' not found.');
                        Exit;
                      end;
                      SaveToIPBIN(OutFile);
                    end;
        ctExt     : if MR.LoadFromIPBIN(InFile) then
                    begin
                      if OutFile = '' then
                        OutFile := ChangeFileExt(InFile, '.mr');
                      MR.SaveToMR(OutFile, 0);
                    end;
        ctStrip   : MR.CleanIPBin(InFile);
        ctScan    : if LoadFromBMP(InFile) then
                      Log('This bitmap''ll generate a valid .mr file.')
                    else Log('Sorry but this bitmap isn''t valid for .mr creation.');
        ctSega    : begin
                      if MR.LoadFromMR(InFile, 8812) then
                      begin
                        MR.ShowInfo;
                        MR.SaveToMR('tm.mr', 0);
                        MR.SaveToBMP('tm.bmp', False);
                      end;

                      if MR.LoadFromMR(InFile, 9111) then
                      begin
                        MR.ShowInfo;
                        MR.SaveToMR('sega.mr', 0);
                        MR.SaveToBMP('sega.bmp', False);
                      end;
                    end;
      end;

    end;

  finally
    MR.Free;
  end;

end.