{
Name    : BMP2VIF 1.0
Purpose : BMP to VIF converter
Coder   : SSG

Update Info:
------------
05th Jul 93 - 22:30 - Trying to recover a bug...
05th Jul 93 - 22:35 - Cancelled... This source works perfectly...
}

uses Loaders,XGfx,Dos,Objects,XTypes;

const
  AllFiles=ReadOnly+Archive+SysFile;
  Version : Byte = 1;

var
  fname   : String;
  dirinfo : SearchRec;
  OutFile : TDosStream;
  dir:DirStr;
  nam:NameStr;
  ext:ExtStr;
  InDir:DirStr;
  P:PVIFMap;
  T:TVIFHeader;
  vstr : string;
  sx,sy : Word;
  PlaneSize : Word;

begin
  writeln('BMP to VIF Converter Version 2.0 - (c) 1993 SSG');
  writeln;
  if paramcount<>2 then begin
     writeln('Usage: BMP2VIF filespec version');
     writeln('BMP2VIF can convert BMPs to following VIF Versions:');
     writeln('  1.0 - Raster');
     writeln('  2.0 - Bitplaned');
     halt(1);
  end;
  fname := paramstr(2);
  Version := Byte(fname[1])-48;
  vstr := fname[1]+'.0';
  writeln('VIF v',vstr);
  fname:=paramstr(1);
  if pos('.',fname)<1 then fname:=fname+'.BMP';
  FSplit(fname,dir,nam,ext);
  InDir:=dir;
  FindFirst(fname,AllFiles,dirinfo);
  if DosError<>0 then begin
     writeln('No BMP files found');
     halt(1);
  end;
  with T do begin
    ID       := 'VIF';
    move (vstr[1],Version,3);
    EOFFlag  := $1a;
    HardFlag := 0;
  end;
  repeat
    FSplit(dirinfo.name,dir,nam,ext);
    write('Converting : ',dirinfo.name,' ... ');
    OutFile.Init(nam+'.VIF',stCreate);
    OutFile.Write(T,sizeof(T));
    Case Version of
      1 : begin
             P := LoadBMP256(InDir+dirinfo.name);
             if P=NIL then begin
                writeln('Unable to open file');
                halt(1);
             end;
            OutFile.Write(P^,P^.XSize*P^.YSize+SizeOf(TVIFHeader));
          end;
      2 : begin
             ShowBMP2(InDir+dirinfo.name,P);
             if P=NIL then begin
                writeln('Unable to open file');
                halt(1);
             end;
             sx := P^.XSize;
             sy := P^.YSize;
             PlaneSize := ((SX div 8) + Byte((SX mod 8)>0))*SY ;
             OutFile.Write(P^,SizeOf(TVIFHeader));
             OutFile.Write(P^.Plane0^,PlaneSize);
             OutFile.Write(P^.Plane1^,PlaneSize);
             OutFile.Write(P^.Plane2^,PlaneSize);
             OutFile.Write(P^.Plane3^,PlaneSize);
          end;
    end;
    OutFile.Done;
    writeln('Done.');
    FindNext(dirinfo);
  until doserror<>0;
  writeln('SSG Operation complete...');
end.