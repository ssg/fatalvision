{
Name    : X/VFS 1.00c
Purpose : Virtual file system
Coder   : SSG
Date    : 25th Dec 96
Time    : 02:58

updates:
--------
18th Jan 97 - 01:28 - restructured the code...
25th Jan 97 - 10:54 - some fixes...
}

unit XVFS;

interface

uses Dos,Objects;

const

  VFSId      = $1a534656;
  VFSVersion = 1;

type

  TForEachFileProc = procedure(filename:string);

  TVFSHeader = record
    Sign     : longint;
    Version  : byte;
    Flags    : byte; {none defined yet}
    Reserved : word;
  end;

  TVFSFileHeader = record
    Size     : longint;
    Time     : longint;
    CRC      : longint; {crc32 of the file}
    Flags    : byte; {reserved for future use}
    Namelen  : byte;
  end; {then follows the filename}

  PVFSindex = ^TVFSIndex;
  TVFSIndex = record
    Name    : PString;
    Size    : longint;
    Time    : longint;
    CRC     : longint;
    HdrOffs : longint;
    VFSOffs : longint;
  end;

  PVFSCollection = ^TVFSCollection;
  TVFSCollection = object(TSortedCollection)
    function     Compare(k1,k2:pointer):integer;virtual;
    procedure    FreeItem(item:pointer);virtual;
  end;

  PVFS = ^TVFS;
  TVFS = object(TObject)
    Stream   : PDosStream;
    Index    : PVFSCollection;
    BaseOffs : longint;
    Status   : integer;
    constructor Init(afilename:string; amode:word);
    destructor  Done;virtual;
    function    GetIndex(afilename:string):PVFSIndex;
    function    Read(offset:longint; var buf; size:word):boolean;
    function    Write(offset:longint; var buf; size:word):boolean;
    function    Create(afilename:string):PVFSIndex;
    private
    procedure   BuildIndex;
  end;

  PVFSStream = ^TVFSStream;
  TVFSStream = object(TStream)
    Index    : TVFSIndex;
    Position : longint;
    Mode     : word;
    constructor Init(afilename:string; amode:word);
    destructor  Done;virtual;
    function    GetPos:longint;virtual;
    function    GetSize:longint;virtual;
    procedure   Read(var buf; size:word);virtual;
    procedure   Write(var buf; size:word);virtual;
    procedure   Seek(aoffs:longint);virtual;
  end;

function InitVFile(afilename:string):PStream;
function InitVFS(afilename:string):boolean;
function WildMatch(wild,afilename:string):boolean;
procedure ForEachFile(awild:string; aproc:TForEachFileProc);
procedure DoneVFS;

const

  VFS : PVFS = NIL;

implementation

uses XBuf,Debris,XStr;

procedure ForEachFile;
var
  n:integer;
  P:PVFSIndex;
begin
  if VFS = NIL then exit;
  for n:=0 to VFS^.Index^.Count-1 do begin
    P := VFS^.Index^.At(n);
    if WildMatch(awild,P^.Name^) then aproc(P^.Name^);
  end;
end;

function WildMatch;
var
  parse:string;
  b:byte;
  lastpos:byte;
  temp:byte;
begin
  FastUpper(wild);
  FastUpper(afilename);
  WildMatch := true;
  if pos('*',wild) = 0 then WildMatch := afilename = wild else begin
    lastpos := 0;
    for b:=1 to GetParseCount(wild,'*') do begin
      parse := GetParse(wild,'*',b);
      if parse <> '' then begin
        temp := pos(parse,afilename);
        if temp > lastpos then lastpos := (temp+length(parse))-1 else begin
          WildMatch := false;
          exit;
        end;
      end;
    end;
  end;
end;

function InitVFS;
begin
  New(VFS,Init(afilename,stOpenRead));
  if VFS^.Status <> stOK then begin
    InitVFS := false;
    DoneVFS;
  end else InitVFS := true;
end;

procedure DoneVFS;
begin
  if VFS <> NIL then begin
    Dispose(VFS,Done);
    VFS := NIL;
  end;
end;

function InitVFile;
var
  P:PStream;
begin
  INitVFile := NIL;
  FastUpper(afilename);
  P := New(PDosStream,Init(afilename,stOpenRead));
  if P^.Status = stOK then InitVFile := P else if VFS <> NIL then begin
    Dispose(P,Done);
    if pos('VFS:',afilename) > 0 then begin
      Replace(afilename,'VFS:','');
      P := New(PVFSStream,Init(afilename,stOpenRead));
      if P^.Status = stOK then InitVFile := P else Dispose(P,Done);
    end;
  end;
end;

{- TVFSStream -}
constructor TVFSStream.Init;
var
  P:PVFSIndex;
begin
  inherited Init;
  Status := stInitError;
  Mode   := amode;
  if VFS <> NIL then begin
    case Mode of
      stCreate : P := VFS^.Create(afilename);
      stOpenWrite,stOpen : P := NIL;
      else P := VFS^.GetIndex(afilename);
    end;
    if P <> NIL then begin
      Move(P^,Index,SizeOf(Index));
      Status := stOK;
    end;
  end;
end;

destructor TVFSStream.Done;
var
  P:PVFSIndex;
begin
  if Mode = stCreate then begin
    P := VFS^.GetIndex(Index.Name^);
    if P <> NIL then begin
    {!!!!}
    end;
  end;
  inherited Done;
end;

function TVFSStream.GetPos;
begin
  if Status = stOK then GetPos := Position else GetPos := -1;
end;

function TVFSStream.GetSize;
begin
  if Status = stOK then GetSize := Index.Size else GetSize := -1;
end;

procedure TVFSStream.Read;
begin
  if Status = stOK then if not VFS^.Read(Index.VFSOffs+Position, buf, size) then Status := stReadError
                               else inc(Position,size);
end;

procedure TVFSStream.Write;
begin
  if Status = stOK then if not VFS^.Write(Index.VFSOffs+Position, buf, size) then Status := stWriteError else begin
    Position := VFS^.Stream^.GetPos-(VFS^.BaseOffs+Index.VFSOffs);
    if Position > Index.Size then Index.Size := Position;
  end;
end;

procedure TVFSStream.Seek;
begin
  if Status = stOK then Position := aoffs;
end;

{- TVFS -}
constructor TVFS.Init;
var
  h:TVFSHeader;
  w:word;
  l:longint;
  heberec:record
    lastPageSize:word;
    FileSize:word;
  end;
const
  EXESign = $5a4d;
begin
  inherited Init;
  Status := stInitError;
  New(Stream,Init(afilename,aMode));
  if Stream^.Status = stOK then begin
    Stream^.Read(w,SizeOf(w));
    if w = EXESign then begin
      Stream^.Read(heberec,SizeOf(heberec));
      BaseOffs := heberec.FileSize-1;
      BaseOffs := (BaseOffs*512)+heberec.lastPageSize;
      Stream^.Seek((longint(heberec.FileSize-1)*longint(512))+heberec.lastPageSize);
    end else Stream^.Seek(0);
    if aMode = stCreate then begin
      h.Sign     := VFSId;
      h.Version  := VFSVersion;
      h.Flags    := 0;
      h.Reserved := 0;
      Stream^.Write(h,SizeOf(h));
      Stream^.Truncate;
    end else begin
      Stream^.Read(h,SizeOf(h));
      if (h.Sign <> VFSId) or (h.Version <> VFSVersion) then exit;
    end;
    BaseOffs := Stream^.GetPos;
    BuildIndex;
    if Stream^.Status = stOK then Status := stOK;
  end;
end;

{
tommy is the work on docks
and union's being on a strike
he's down on his luck
its tough, so tough

Geena laskdjflk all day,
working for the man,
she brings plate for what??

she says we gotta hold on
to what we've got...

doesn't make a difference if
we make it or not...
if we got each other, that's
what life for...

tommie doin sacks change in what??
so tough...

geena bi$ii all way...
baby it's all game.. some day...

you've got each other, that's what
life for... we give it a shot...

we live the day, living on a prayer...

you gotta hold on, ready or not,


we live the day,
livin on a prayer..
take my hand, make it out sway???

we're livin on a prayer...
}

destructor TVFS.Done;
begin
  if Stream <> NIL then Dispose(Stream,Done);
  if Index <> NIL then Dispose(index,Done);
  inherited Done;
end;

function TVFS.Read;
begin
  Stream^.Seek(BaseOffs+offset);
  Stream^.Read(buf,size);
  Read := Stream^.Status = stOK;
  Stream^.Reset;
end;

procedure TVFS.BuildIndex;
var
  rec:TVFSFileHeader;
  s:string;
  P:PVFSIndex;
begin
  if Index <> NIL then Dispose(Index,Done);
  New(Index,Init(20,20));
  Stream^.Seek(BaseOffs);
  while Stream^.GetPos < Stream^.GetSize do begin
    New(P);
    P^.HdrOffs := Stream^.GetPos-BaseOffs;
    Stream^.Read(rec,SizeOf(rec));
    with P^ do begin
      byte(s[0]) := rec.Namelen;
      Stream^.Read(s[1],length(s));
      FastUpper(s);
      P^.Name := NewStr(s);
      P^.Size := rec.Size;
      P^.Time := rec.Time;
      P^.CRC  := rec.CRC;
      P^.VFSOffs := Stream^.GetPos-BaseOffs;
    end;
    Index^.Insert(P);
    Stream^.Seek(BaseOffs+P^.VFSOffs+rec.Size);
  end;
end;

function TVFS.GetIndex;
var
  T:TVFSIndex;
  i:integer;
begin
  T.Name := NewStr(afilename);
  if Index^.Search(@T,i) then GetIndex := Index^.At(i)
                         else GetIndex := NIL;
  DisposeStr(T.Name);
end;

function TVFS.Write;
begin
  Stream^.Seek(BaseOffs+offset);
  Stream^.Write(buf,size);
  Write := Stream^.Status = stOK;
  Stream^.Reset;
end;

function TVFS.Create;
var
  h:TVFSFileHeader;
  P:PVFSIndex;
  was:longint;
begin
  Create := NIL;
  FastUpper(afilename);
  if GetIndex(afilename) <> NIL then exit;
  ClearBuf(h,SizeOf(h));
  h.Time     := GetSysTime;
  h.Namelen  := length(afilename);
  Stream^.Seek(Stream^.GetSize);
  was := Stream^.GetPos;
  Stream^.Write(h,SizeOf(h));
  if Stream^.Status = stOK then begin
    New(P);
    P^.Name := newStr(afilename);
    P^.Time := h.Time;
    P^.Size := 0;
    P^.HdrOffs := was;
    P^.VFSOffs := Stream^.GetPos;
    P^.CRC     := 0;
    Index^.Insert(P);
    Create := P;
  end;
end;

{- TVFSCollection -}
function TVFSCollection.Compare;
var
  s1,s2:string;
begin
  s1 := PVFSindex(k1)^.Name^;
  s2 := PvfsIndex(k2)^.name^;
  if s1 < s2 then Compare := -1 else
    if s1 > s2 then Compare := 1 else
      Compare := 0;
end;

procedure TVFSCollection.FreeItem;
begin
  DisposeStr(PVFSindex(item)^.Name);
  Dispose(PVFSIndex(item));
end;

end.