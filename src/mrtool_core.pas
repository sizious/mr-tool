{
  MRTool Core - v0.5 - krypt@mountaincable.net
  This source is licensed under the GNU GPL

  [big_fury]SiZiOUS was here, since v0.6 (http://sbibuilder.shorturl.com/)
  kRYPT_ where are you, man...?

  Changes :
    - Fixed a bitmap size bug in the method Compress.
    - Fixed invalid bitmap & mr files detection
    - Fixed BMP write.
    - Fixed many mini-bugs...
    - Code cleaned
}

unit
  mrtool_core;

interface

uses
  SysUtils, Graphics;

const
  CoreVersion = '0.6';

type
    TMRHeader = packed record
        ID              : array[0..1] of Char;
        Size            : Word;
        Crap1           : array[0..5] of Char;
        Offset, Crap2,
        Width, Crap3,
        Height          : Word;
        Crap4           : array[0..5] of Char;
        Colors, crap    : Word;
     end;

     TMRPal = packed record
        b, g, r, crap   : byte;
     end;

     TMRPallete = packed record
        Colors          : array[0..126] of TMRPal;
        count           : integer;
     end;

     TBMPHeader = packed record
        ID              : array[0..1] of Char;
        size, crap,
        offset          : LongWord;
     end;

     TBMPInfo = packed record
        Size, width,
        height          : LongWord;
        planes,
        bitcount        : Word;
        compression,
        imagesize,
        XpixelsPerM,
        YpixelsPerM,
        ColorsUsed,
        ColorsImportant : LongWord;
     end;

     TBuffer  =  array[0..0] of Char; //?
     PBuffer  =  ^TBuffer;

     TMRFile = class
        private
          Data, ComprData         : PBuffer;
          DataSize, ComprDataSize : LongInt;
          PAL                     : TMRPallete;

          function DeCompress(var Src, Dest : PBuffer; InSize, X, Y : LongInt) : LongInt;
          function Compress(var Src, Dest : PBuffer; X, Y : LongInt) : LongInt;
          procedure CorrectBmp(Bitmap : string);
        public
          Header  : TMRHeader;
          Loaded  : Boolean;
          Verbose : Boolean;

          constructor Create;
          destructor Destroy; override;

          procedure Log(Msg : string) ; virtual;

          function LoadFromMR(FileName : string ; Offset : Integer) : Boolean;
          function LoadFromBMP(FileName : string) : Boolean;
          function LoadFromIPBIN(FileName : string) : Boolean;
          procedure SaveToMR(FileName : string ; Offset : Integer);
          procedure SaveToBmp(Filename : string ; Flip : Boolean);
          procedure SaveToIPBIN(FileName : string);

          procedure CleanIPBin(FileName : string);

          procedure ShowInfo;
     end;


implementation

//------------------------------------------------------------------------------

constructor TMRFile.Create;
begin
  Loaded    := False;
  Verbose   := True;
  Data      := nil;
  ComprData := nil;
end;

//------------------------------------------------------------------------------

destructor TMRFile.Destroy;
begin
  //Si chargé on detruit
  if Loaded then
  begin
    if Data <> nil then FreeMem(Data); //Si le PBuffer Data est chargé par qqch (nil = rien) on le détruit
    if ComprData <> nil then FreeMem(ComprData); //pareil pour ComprData
  end;
end;
//------------------------------------------------------------------------------

function TMRFile.Decompress(var Src, Dest : PBuffer ; InSize, X, Y : LongInt) : LongInt;
var 
  Tmp    : PBuffer; // PBuffer = ^array of Char 
  i, j, 
  K, Run  : Integer; 
  
begin 
  i := 0; 
  j := 0; 

  GetMem(Tmp, x*y*2); // le bitmap doit être codé sur 2 octets par point ??? 
  Src^[Insize] := Chr(0);      
  Src^[Insize + 1] := Chr(0);  

  repeat 

    if Ord(Src^[I]) < $80 then 
      begin 
        tmp^[j] := Src^[i]; // les octets inférieurs à 128 sont recopiés tels quels dans le bitmap 
        Inc(j); 
      end 

    else 

      if (Ord(Src^[I]) = $82) and (Ord(Src^[I+1]) >= $80) then 
        begin 
          // le tag $82 est suivi du nb de points décodé dans Run
          Run := Ord(Src^[i + 1]) - $80 + $100; 

          for K := 1 to Run do 
          begin 
            tmp^[j] := Src^[I + 2]; // en ne retenant que le 1° octet pour chaque point 
            inc(j); 
          end; 

          Inc(I, 2); 

        end 

      else 

        if Ord(Src^[I]) = $81 then 
          // le tag $81 est suivi d'un octet donnant directement le nb de points
          begin 
            Run := Ord(Src^[I + 1]); 

            for K := 1 to Run do 
            begin 
              tmp^[J] := Src^[I + 2]; // idem : 1° octet sur 2 
              inc(j); 
            end; 

            Inc(I, 2); 
          end 

      else 

        begin 
          // si > $82 => code pour un nb de points décodé dans run 
          Run := Ord(Src^[I]) - $80; 

          for K := 1 to run do 
          begin 
            tmp^[j] := Src^[I + 1]; // codés sur un seul octet 
            inc(j); 
          end; 

          Inc(i); 
        end; 

    Inc(i); 
  until i > InSize - 1; 

  Dec(j); 
  GetMem(dest,J); 
  Move(tmp^, dest^, j); 
  Result := j; //Decompress := j; 
  FreeMem(tmp); 
end;

//------------------------------------------------------------------------------

function TMRFile.Compress(var Src, Dest : PBuffer ; X, Y : LongInt):LongInt;
var
  tmp : PBuffer;
  i, j, run : Integer;

begin
  I:=0;
  J:=0;

  GetMem(tmp,x*y);

  repeat
     run := 1;

     while (Src^[I+run] = Src^[I])and(run < $17f)and((I+run)<=(X*Y)) do
      Inc(run);

     if (run > $ff) then
      begin
        tmp^[J]:=chr($82);
        tmp^[J+1]:=chr($80 or (run - $100));
        tmp^[J+2]:=Src^[I];
        inc(J,3);
      end
     else if (run > $7f) then
      begin
              tmp^[J]:=chr($81);
        tmp^[J+1]:= chr(run);
        tmp^[J+2]:= Src^[I];
              inc(J,3);
      end
     else if (run > 1) then
      begin
              tmp^[J]:=chr($80 or run);
        tmp^[J+1]:= Src^[I];
              inc(J,2);
      end
     else
      begin
              tmp^[J]:=Src^[I];
              inc(J);
      end;

      inc(I,run);

  until I > (X*Y);

  GetMem(dest,J);
  Move(tmp^,dest^,J);
  compress := J;
  FreeMem(tmp);
end;

//------------------------------------------------------------------------------

function TMRFile.LoadFromMR(FileName : string ; Offset:Integer):boolean;
var F:File;
    I:Integer;

begin
if verbose then Log('Reading MR: '+filename);
LoadFromMr:=False;

if Loaded then
begin
        Loaded:=False;
        if Data<>nil then freemem(Data);
        if ComprData<>nil then freemem(ComprData);
end;

{$I-}
AssignFile(F,FileName);
Reset(F,1);
{$I+}
If (IoResult <>0) then
begin
        if verbose then Log('Cannot open '+filename); LoadFromMr:=False;
end
else
begin
        if (FileSize(F) = 0) then
        begin
          Log('File empty...');
          Exit;
        end;

        seek(F,Offset);
        BlockRead(F,Header,Sizeof(Header));

        if (Header.ID[0] <> 'M')or(Header.ID[1] <> 'R') then
        begin
                Log('Not a valid MR (or MR not found in IP.BIN) !');
        end
        else
        begin
                LoadFromMr:=True;

                ComprDataSize:=Header.Size-Header.Offset;
                //comprdatasize:=header.size;
                if verbose then Log('Reading Pallete');
                Pal.count:=Header.Colors;
                for I:=0 to pal.count-1 do BlockRead(F,Pal.Colors[i],4);
                if verbose then Log('Reading '+IntToStr(comprdatasize)+' bytes of compressed data.');

                getmem(ComprData,ComprDataSize*2);
                Blockread(F,ComprData^,ComprDataSize);

                DataSize:=Decompress(ComprData,Data,ComprDataSize, Header.Width, Header.Height);
                if verbose then Log('Decompressed to ' + IntToStr(datasize) + ' bytes');
                Loaded:=True;
        end;

        CloseFile(F);
end;
end;

//------------------------------------------------------------------------------

function TMRFile.LoadFromIPBIN(FileName:String):Boolean;
begin
        LoadFromIPBIN:=LoadFromMR(FileName,$3820);
end;

//------------------------------------------------------------------------------

function TMRFile.LoadFromBMP(Filename:String):Boolean;
var F:File;
    HdrBMP:TBmpHeader;
    InfoBMP:TBmpInfo;
    I,J,K:integer;
    error:boolean;
    Tmp:PBuffer;
    Color:TMRPal;

begin
if verbose then Log('Reading BMP: '+filename);
LoadFromBMP:=False;
Error:=False;

if Loaded then
begin
        Loaded:=False;
        if Data<>nil then freemem(Data);
        if ComprData<>nil then freemem(ComprData);
end;

{$I-}
AssignFile(F,FileName);
Reset(F,1);
{$I+}
If (IoResult <>0) then
begin
        Log('Cannot open '+filename);
end
else
begin
        if (FileSize(F) = 0) then
        begin
          Log('File empty...');
          error := true;
        end;

        BlockRead(F,Hdrbmp,sizeof(Hdrbmp));
        BlockRead(F,InfoBmp,sizeof(InfoBmp));

        if (HdrBmp.ID[0] <> 'B')or(HdrBmp.ID[1]<>'M') then
         begin Log('not a valid .bmp');
              CloseFile(F);
              end
        else
        begin
                if InfoBmp.bitcount <> 24 then begin Log('image must be 24-bit'); error:=true; end;
                if InfoBmp.compression <> 0 then begin Log('image must be uncompressed'); error:=true; end;
                if Infobmp.width > 320 then begin Log('width must be < 320'); error:=true; end;
                if Infobmp.height > 90 then begin Log('height must be < 90'); error:=true; end;

                if (not error) then
                begin
                        Log('Bitmap is valid!');
                        getmem(Tmp,Infobmp.Width * InfoBmp.Height*3+1);
                        getmem(Data,Infobmp.Width * InfoBmp.Height+1);

                        Log('Reading '+IntToStr(Infobmp.Width * InfoBmp.Height*3)+' bytes');
                        Blockread(f,Tmp^,Infobmp.Width * InfoBmp.Height*3);

                        Log('Building palette and loading...');
                        For I:=0 to (Infobmp.Width * InfoBmp.Height)-1 do
                        begin
                            Move(Tmp^[I*3],color,3);
                            color.crap:=0;
                            K:=-1;

                            for J:=0 to Pal.count do
                             if (Pal.Colors[J].r = Color.r)and(Pal.Colors[J].b = Color.b)and(Pal.Colors[J].g = Color.g) then K:=J;

                            if (K = -1) then
                             begin
                               if verbose then Log('New color found: '+inttostr(color.r)+' '+inttostr(color.g)+' '+inttostr(color.b));
                               K:=pal.count;
                               if pal.count < 127 then pal.colors[pal.count]:=color;
                               inc(pal.count);
                             end;

                            if (pal.count=128) then
                             begin
                                     Log('Error : Too many colors in bitmap, max is 127.');
                                     error:=true;
                             end;

                            Data^[I]:=Chr(K);
                        end;

                        freemem(tmp);
                        if (not Error) then begin
                        LoadFromBMP:=True;
                        Loaded:=True;

                        // Flip it!
                        getmem(tmp, Infobmp.Width * InfoBmp.Height+1);

                        K:=0;
                        for I:=InfoBmp.Height-1 downto 0 do
                          for J:=0 to Infobmp.Width-1 do
                            begin
                                   move(data^[I*Infobmp.Width+J],tmp^[K],1);
                                   inc(K);
                            end;

                        move(tmp^,Data^,K);
                        freemem(tmp);

                        Log('Pallete built : '+inttostr(pal.count)+' colors');
                        ComprDataSize := Compress(Data, ComprData, infobmp.width, infobmp.height);
                        Log('Compressed size : '+inttostr(comprdatasize) + ' bytes');

                        if (ComprDataSize <= 8192) then
	                        Log('This will fit in a normal ip.bin.')
                        else
                        begin
	                        Log('This will NOT fit in a normal ip.bin - it is '
                            + IntToStr(ComprDataSize - 8192) + ' bytes too big!');
                          Result := False;
                        end;

                        Header.ID[0]:='M';
                        Header.ID[1]:='R';
                        Header.Width:=Infobmp.Width;
                        Header.Height:=InfoBmp.Height;
                        Header.Colors:=pal.count;
                        Header.Size:=2 + 7*4 + pal.count*4 + comprdatasize;
                        Header.Offset:=2 + 7*4 + pal.count*4;

                        Log(filename+' loaded in memory.');
                        end;                        
                end
                  else CloseFile(F); //ET ALORS !!
        end;
end;
end;

//------------------------------------------------------------------------------

procedure TMRFile.ShowInfo;
begin
if Loaded then
  begin
    Log('Size : ' + IntToStr(Header.Size) + ' bytes');
    Log('Width : ' + IntToStr(Header.Width));
    Log('Height : ' + IntToStr(Header.Height));
    Log('Colors : ' + IntToStr(Header.Colors));
    Log('Offset : ' + IntToStr(Header.Offset));
  end;
end;

//------------------------------------------------------------------------------

procedure TMRFile.SaveToBmp(Filename:String; Flip:Boolean);
var F:File;
    HdrBMP : TBmpHeader;
    InfoBMP : TBmpInfo;
    I,J:integer;

begin

//------------------------------------------------------------------------------

if Loaded then
begin
        {$I-}
        assignfile(F,FileName);
        rewrite(f,1);
        {$I+}

        If (IoResult <>0) then
        begin
                If verbose then Log('cannot write to '+filename);
        end
        else
        begin

        // Create a 24-bit no-palette BMP header
        fillchar(hdrbmp,sizeof(hdrbmp),0);
        HdrBmp.ID[0]:='B';
        HdrBmp.ID[1]:='M';
        HdrBmp.size:=Header.Width*Header.Height+sizeof(HdrBmp)+sizeof(infobmp);
        HdrBmp.offset:=54;
        blockwrite(f,Hdrbmp,sizeof(hdrbmp));

        // create our info block
        fillchar(infobmp,40,0);
        infobmp.size:=40;
        InfoBmp.width:=Header.Width;
        InfoBmp.height:=Header.Height;
        InfoBmp.planes:=1;
        InfoBmp.bitcount:=24;
        infobmp.compression:=0;
        blockwrite(f,infobmp,sizeof(infobmp));

        if verbose then Log('Writing out .bmp data');

        // Image comes out with scanlines reversed
        if (Flip) then
        begin
                if Verbose then Log('Flipping image.');
                for I:=Header.Height-1 downto 0 do
                 for J:=0 to Header.Width-1 do
                    blockwrite(f,Pal.colors[ord(Data^[I*Header.Width+J])],3);
        end
        else
        begin
                if verbose then Log('Not Flipping image.');
                for I:=0 to datasize-1 do blockwrite(f,Pal.colors[ord(Data^[I])],3);
        end;

        closefile(f);
        CorrectBmp(FileName);
        Log(filename+' written.');
        end;
end;

end;

//------------------------------------------------------------------------------

procedure TMRFile.SaveToMR(Filename:String; Offset:Integer);
var F:File;
    I:Integer;
    
begin
if Loaded then
begin
        {$I-}
        AssignFile(F,FileName);
        if FileExists(FileName) then Reset(F,1) else Rewrite(f,1);
        {$I+}

        If (IoResult <>0) then
        begin
                If verbose then Log('cannot write to '+filename);
        end
        else
        begin
                Seek(F, offset);
                BlockWrite(F,Header,sizeof(Header));
                For I:=0 to pal.count-1 do
                  blockwrite(F,pal.colors[i],4);
                blockwrite(F,comprdata^,comprdatasize);
                closefile(F);

                Log(filename+' written.');
        end;
end;
end;

//------------------------------------------------------------------------------

procedure TMRFile.CleanIPBin(FileName:String);
var F:File;
    buff:array[1..8176] of byte;
begin
        {$I-}
        AssignFile(F,FileName);
        Reset(F,1);
        {$I+}

        If (IoResult <>0) then
        begin
                If verbose then Log('Cannot write to '+filename);
        end
        else
        begin
                Log('Cleaning ' + Filename + '.');
                Seek(F, $3820);
                FillChar(buff,8176,0);
                BlockWrite(F,buff,8176);
                closefile(F);
                if verbose then Log(Filename + ' cleaned.');
        end;
end;

//------------------------------------------------------------------------------

procedure TMRFile.SaveToIPBIN(FileName:String);
begin
if Loaded then
begin
        CleanIPBin(FileName);
        SaveToMR(FileName, $3820);
end;
end;

//------------------------------------------------------------------------------

procedure TMRFile.Log(Msg:String);
//var I:Integer;
begin
//        I:=0;
end;

//------------------------------------------------------------------------------

procedure TMRFile.CorrectBmp(Bitmap: string);
var
  B : TBitmap;

begin
  if not FileExists(Bitmap) then Exit;
  B := TBitmap.Create;
  try
    B.LoadFromFile(Bitmap);
    B.SaveToFile(Bitmap);
  finally
    B.Free;
  end;
end;

end.
