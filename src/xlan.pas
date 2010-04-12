{
Name    : X/Lan 1.00c
Purpose : Language file manip
Coder   : SSG
Date    : 27th Aug 95
Time    : 22:52

updates:
--------
23rd Aug 96 - 14:16 - moved to xvision...
23rd Aug 96 - 17:45 - bugfixes...
18th Jan 97 - 02:31 - a small bugfix...
}

unit XLan;

interface

uses

  XStream,Objects;

type

  PTIndex = ^TTIndex;
  TTIndex = record
    id    : longint;
    text  : PString;
  end;

  PRColl = ^TRColl;
  TRColl = object(TSortedCollection)
    procedure FreeItem(item:pointer);virtual;
    function Compare(k1,k2:pointer):integer;virtual;
  end;

function  InitXLan(afile:FnameStr):boolean;
function  gtid(id:longint):string;
procedure DoneXLan;

implementation

uses

  XBuf,XVFS,XSys,XStr;

const

  index:PrColl=NIL;

function InitXLan;
var
  P:PStream;
  Pt:PTIndex;
  s:string;
begin
  InitXLan := false;
  P := InitVFile(afile);
  if P = NIL then exit;
  New(index,Init(10,10));
  while P^.GetPos < P^.GetSize do begin
    New(Pt);
    P^.Read(Pt^.id,4);
    Decode(Pt^.id,4);
    P^.Read(s[0],1);
    Decode(s[0],1);
    if s <> '' then begin
      P^.Read(s[1],length(s));
      Decode(s[1],length(s));
    end;
    if P^.Status <> stOK then begin
      Dispose(Pt);
      Dispose(index,Done);
      exit;
    end;
    Pt^.text := NewStr(s);
    index^.Insert(Pt);
  end;
  InitXLan := true;
end;

procedure DoneXLan;
begin
  if index <> NIL then begin
    Dispose(index,Done);
    index := NIL;
  end;
end;

function TRColl.Compare;
begin
  with PTIndex(k1)^ do if PTIndex(k2)^.id = id then Compare := 0 else
  if PTIndex(k2)^.id > id then Compare := 1 else Compare := -1;
end;

procedure TRColl.FreeItem;
begin
  with PTIndex(item)^ do begin
    if text <> NIL then DisposeStr(text);
    Dispose(PTIndex(item));
  end;
end;

function gtid;
var
  n:integer;
  T:TTIndex;
  P:PTIndex;
begin
  gtid := '???';
  if Index = NIL then exit;
  T.id := id;
  if not Index^.Search(@T,n) then exit;{Error('XLan','missing id ('+l2s(id)+')');}
  P := Index^.At(n);
  gtid := P^.text^;
end;

end.