{
Name    : X/Setup 1.00a
Purpose : Generic setup routines
Coder   : SSG
Date    : 7th Oct 96
Time    : 01:29

updates:
--------
 7th Oct 96 - 14:25 - perfect...
}

unit XSetup;

interface

uses Objects,XStr;

const

  rsiOK         = 0;
  rsiNotFound   = 1;
  rsiMismatch   = 2;

  gfNormal      = 0;
  gfNoRecover   = 1;

function  XSetupGetKey(key:string; var buf; size:word; var T:TStream; flags:word):byte;
procedure XSetupPutKey(key:string; var buf; size:word; var T:TStream);

implementation

uses xdebug;

function  XSetupGetKey;
var
  s:string;
  l:longint;
  oldpos:longint;
begin
  T.Reset;
  T.Seek(0);
  FastUpper(key);
  while T.GetPos < T.GetSize do begin
    T.Read(s[0],1);
    T.Read(s[1],length(s));
    T.Read(l,SizeOf(l));
    FastUpper(s);
    if s = key then begin
      oldpos := T.GetPos;
      if flags and gfNoRecover > 0 then if l <> size then begin
        XSetupGetKey := rsiMismatch;
        T.Seek(oldpos + l);
        exit;
      end;
      T.Read(buf,size);
      if l = size then XSetupGetKey := rsiOK else begin
        XSetupGetKey := rsiMismatch;
        T.Seek(oldpos + l);
      end;
      exit;
    end else T.Seek(T.GetPos + l);
  end;
  T.Done;
  XSetupGetKey := rsiNotFound;
end;

procedure XSetupPutKey;
var
  hebe:longint;
begin
  T.Write(key[0],length(key)+1);
  hebe := size;
  T.Write(hebe,sizeOf(hebe));
  T.Write(buf,size);
end;

end.