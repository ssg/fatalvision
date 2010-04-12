{
Name            : X/Diff 1.00a
Purpose         : DIFF implementation
Coder           : SSG
Date            : 7th Jan 95
Time            : 23:58

Updates:
--------
 8th Jan 95 - 00:18 - Success... just in 20 mins... untested..
}

unit XDiff;

interface

uses XBuf,XStr,Objects;

type

  TSig = string[8];

  TDiffHeader = record
    Id        : array[1..8] of char;
    Blocksize : longint;
  end;

  PDiffStream = ^TDiffStream;
  TDiffStream = object(TStream)
    base        : longint;
    size        : longint;
    head        : longint;
    server      : PStream;
    name        : TSig;
    constructor Init(asig:TSig; bsize:word; var aserver:TStream);
    function    GetPos:longint;virtual;
    function    GetSize:longint;virtual;
    procedure   Seek(apos:longint);virtual;
    procedure   Write(var buf;count:word);virtual;
    procedure   Read(var buf;count:word);virtual;
    procedure   Locate;
  end;

implementation

constructor TDiffStream.Init;
begin
  inherited Init;
  Name   := asig;
  Server := @AServer;
  Size   := bsize;
  Locate;
end;

procedure TDiffStream.Locate;
var
  H:TDiffHeader;
  key:TSig;
  finish:longint;
  curpos:longint;
  s:TSig;
begin
  Status := server^.Status;
  if Status <> stOK then exit;
  key := Name;
  FastUpper(key);
  server^.Seek(0);
  finish := server^.GetSize;
  byte(s[0]) := 8;
  if finish > 0 then
  repeat
    server^.Read(H,SizeOf(H));
    curpos := server^.GetPos;
    Move32(H.Id,s[1],8);
    FastUpper(s);
    if s = key then begin
      base := curpos;
      if size = 0 then size := H.Blocksize;
      break;
    end else server^.Seek(curpos+H.BlockSize);
  until (server^.GetPos = finish) or (server^.Status <> stOK);
  if Server^.Status = stOK then begin
    curpos := server^.GetPos;
    if curpos = finish then begin {autocreate (tm)}
      base := curpos+SizeOf(H);
      Move32(Name[1],H.Id,8);
      H.Blocksize := size;
      server^.Write(H,SizeOf(H));
      server^.Seek(server^.GetPos+H.Blocksize);
    end;
    Head   := base;
  end;
  Status := server^.Status;
  server^.Reset;
end;

procedure TDiffStream.Seek;
begin
  Head := apos;
end;

function TDiffStream.GetPos;
begin
  GetPos := Head;
end;

function TDiffStream.GetSize;
begin
  GetSize := size;
end;

procedure TDiffStream.Write;
begin
  if Head+count > size then Error('XDiff.Write','Overbound fault');
  server^.Seek(Head);
  server^.Write(Buf,count);
  Status := server^.Status;
  server^.Reset;
end;

procedure TDiffStream.Read;
begin
  server^.Seek(Head);
  server^.Read(Buf,count);
  Status := server^.Status;
  server^.Reset;
end;

end.