{
Name            : AXE/Server 1.05b
Purpose         : Advanced & eXtEnded resource manager server routines
Coder           : SSG

Update info:
------------
19th Jul 94 - 01:20 - Integrity testing all routines...
23rd Jul 94 - 16:48 - Added CRC checking routines...
24th Jul 94 - 00:46 - Working on this compression things...
24th Jul 94 - 18:44 - Fixed a bug in sounds...
25th Jul 94 - 16:40 - Fixed a bug in compression system...
25th Jul 94 - 16:53 - Resource object management routines are perfect...
29th Jul 94 - 04:41 - Checking code...
 7th Oct 94 - 21:52 - Made RIFList var public...
 4th Nov 94 - 00:30 - made string comparison routines faster...
26th Dec 94 - 21:21 - Added check method to resource object...
18th Apr 95 - 02:16 - Added EXE embedding support...
26th Apr 95 - 17:48 - Fixed a fuckin bug in heap manager...
27th Apr 95 - 11:09 - Added dynamic file handling...
14th Jun 96 - 21:15 - Restructured unit...
29th Jun 96 - 00:07 - Removed compression... (to avoid trouble)
 1nd Jul 96 - 22:59 - Removed multi-resource support...
14th Oct 96 - 15:31 - Added some useful funcs...
14th Oct 96 - 17:03 - a bugfix...
}

unit AxeServ;

interface

uses

  XTypes,Objects;

const

  {Overlay id}
  idEXE       = $5A4D;
  idFB        = $4246;

  {Resource types}
  rtBinary    = 0;
  rtImage     = 1;
  rtSound     = 2;
  rtFont      = 3;
  rtMouse     = 4;
  rtPalette   = 5;

  {Resource flags}
  rfFixed      = 1;
  rfEncrypted  = 4;
  rfProtected  = 8;
  rfDeleted    = 16;

  {Search modes}
  rshId        = 0;
  rshName      = 1;

  ResourceID : TId = 'RIF'#$1a;
  ROBID      : TId = 'ROB:';

  RNLen      = 16;

  MaxRscTypes = 6;
  RscXLat : array[0..MaxRscTypes-1] of string[10] =
    ('Binary  ',
     'Image   ',
     'Sound   ',
     'Font    ',
     'Mouse   ',
     'Palette ');

  AXEOK : boolean = false;

type

  TRIFHeader = record {Resource Information File}
    Id       : TId;
    Version  : byte;
    Reserved : array[1..11] of byte;
  end;

  TROBHeader = record {ROB = Resource OBject} {36 bytes header}
    Sign     : TId;          {ROB sign}
    ROBType  : byte;         {ROB type}
    Flags    : byte;         {ROB flags}
    Version  : byte;         {ROB version}
    Id       : word;         {ROB id}
    Size     : longint;      {ROB size}
    Reserved : longint;
    CRC      : word;         {ROB CRC}
    Name     : string[RNLen];
  end;

  PROB = ^TROB;
  TROB = record
    ROBType : byte;
    Id      : word;
    Flags   : byte;
    Version : byte;
    Size    : longint;
    MWhere  : pointer;
    DWhere  : longint;
    Name    : string[RNLen];
  end;

  PROBCollection = ^TROBCollection;
  TROBCollection = object(TCollection)
    procedure FreeItem(Item:Pointer);virtual;
  end;

  PResource = ^TResource;
  TResource = object(TObject)
    Stream      : TDosStream;
    Filename    : PString;
    Index       : PROBCollection;
    OK          : boolean;
    Mode        : word;
    FOK         : boolean;
    chunkSize   : longint;
    constructor Init(AFName:FnameStr;AMode:word);
    destructor  Done;virtual;
    procedure   BuildIndex;
    procedure   CreateHeader;
    function    HeaderOK:boolean;
    function    GetROB(var T:TROB;SearchMode:byte):PROB;
    function    VerifyROB(var T:TROB):boolean;
    function    GetById(RType:byte;Id:Word):pointer;
    function    GetByName(RName:string):pointer;
    function    ReadROB(var T:TROB):pointer;
    procedure   WriteROB(var T:TROB;P:Pointer);
    procedure   DisposeROB(var T:TROB);
    procedure   DeleteROB(var T:TROB);
    procedure   ReplaceROB(var T:TROB);
    procedure   RequestMemory(Size:longint);
    function    FindGAP(ASize:longint):longint;
    function    ROBMemSize(var T:TROB):longint;
    function    Check:boolean;
    private
    procedure   SOpen;
    procedure   SClose;
    function    Retrieve(var T:TROB):pointer;
  end;

  function InitRif(AFName:FnameStr):boolean;
  procedure DoneRif(P:PResource);
  procedure InitAXE;
  procedure DoneAXE;
  function  GetRscById(RType:byte;Id:word):pointer;
  function  GetRscByName(AName:string):pointer;
  function  GetRscId(rtype:byte; name:string):word;
  function  GetRscName(rtype:byte; id:word):string;
  function  GetRTName(b:byte):string;

const

  Rif : PResource = NIL;

implementation

uses

  XIO,XBuf,XStr;

function GetRTName;
begin
  if b > MaxRscTypes then GetRTName := 'Unknown'
     else GetRTName := RscXLat[b];
end;

function CmpStr(s1,s2:string):boolean;
begin
  CmpStr := false;
  if s1[0] <> s2[0] then exit;
  FastUpper(s1);
  FastUpper(s2);
  CmpStr := s1 = s2;
end;

function GetRscByName;
begin
  GetRscByName := RIF^.GetByName(AName);
end;

function GetRscById(RType:byte;Id:word):pointer;
begin
  GetRscById := RIF^.GetById(RType,ID);
end;

function TResource.VerifyROB;
var
  H:TROBHeader;
  BufSize:word;
  Buf:pointer;
  current:longint;
  CRC:word;
begin
  VerifyROB := True;
  if T.Flags and rfProtected = 0 then exit;
  Stream.Seek(T.DWhere);
  Stream.Read(H,SizeOf(H));
  CRC := XGetStreamChecksum(Stream,H.Size);
  VerifyROB := CRC = H.CRC;
  if CRC <> H.CRC then VerifyROB := false;
end;

function TResource.Check;
var
  n:integer;
begin
  Check := OK;
  if not OK then exit;
  for n:=0 to Index^.Count-1 do if not VerifyROB(PROB(Index^.At(n))^) then begin
    Check := false;
    exit;
  end;
end;

function Pixel2Byte(N:Word):Byte; assembler;
asm
  mov     ax,N
  test    al,07
  jz      @1
  add     ax,+08
@1:
  shr     ax,3
end;

procedure TResource.DisposeROB;
  procedure DisposeAll;
  begin
    FreeMem(T.MWhere,T.Size);
  end;
  procedure DisposeImage;
  var
    P:PVIFMap;
    b:byte;
    bufsize:word;
  begin
    P := T.MWhere;
    if P <> NIL then
    case P^.Version of
      1 : FreeMem(P,5+(P^.XSize*P^.YSize));
      2 : begin
            bufsize := Pixel2Byte(P^.XSize)*P^.YSize;
            for b:=0 to 3 do FreeMem(P^.Planes[b],bufsize);
            Dispose(P);
          end;
      else DisposeAll;
    end;
  end;
begin
  if T.MWhere = NIL then exit;
  case T.ROBType of
    rtImage : DisposeImage;
    else DisposeAll;
  end; {case}
  T.MWhere := NIL;
end;

function TResource.GetROB(var T:TROB;SearchMode:byte):PROB;
var
  P:PROB;
  function SrcByName(Item:pointer):boolean;far;
  begin
    SrcByName := CmpStr(PROB(Item)^.Name,T.Name);
  end;
  function SrcById(Item:pointer):boolean;far;
  begin
    SrcById := (PROB(Item)^.Id = T.Id) and (PROB(Item)^.ROBType = T.ROBType);
  end;
begin
  FOK    := false;
  P      := NIL;
  case SearchMode of
    rshId   : P := Index^. FirstThat(@SrcById);
    rshName : P := Index^.FirstThat(@SrcByName);
  end; {case}
  FOK := P <> NIL;
  GetROB := P;
end;

procedure TResource.DeleteROB;
var
  H:TROBHeader;
begin
  if Mode = stOpenRead then exit;
  if not OK then exit;
  Stream.Seek(T.DWhere);
  Stream.Read(H,SizeOf(H));
  H.Flags := H.Flags or rfDeleted;
  Stream.Seek(T.DWhere);
  Stream.Write(H,SizeOf(H));
  Index^.Free(@T);
  FOK := Stream.Status = stOK;
end;

function TResource.ROBMemSize(var T:TROB):longint;
begin
  ROBMemSize := 0;
  if T.MWhere = NIL then exit;
  case T.ROBType of
    rtImage : case T.Version of
                1 : with PVIFMap(T.MWhere)^ do ROBMemSize := XSize*YSize+5;
                2 : with PVIFMap(T.MWhere)^ do ROBMemSize := Pixel2Byte(XSize)*YSize*4+Sizeof(TVIFMap);
              end;
    else ROBMemSize := T.Size;
  end; {case}
end;

procedure TResource.RequestMemory;
var
  n:integer;
  P:PROB;
begin
  if not OK then exit;
  n := 0;
  while (MaxAvail < Size) and (n < Index^.Count) do begin
    P := Index^.At(n);
    if P^.MWhere <> NIL then DisposeROB(P^);
    inc(n);
  end;
end;

function TResource.FindGAP(ASize:longint):longint;
var
  T:TROBHeader;
  l:longint;
begin
  FindGAP := Stream.GetSize;
  exit;
  Stream.Seek(SizeOf(TRIFHeader));
  repeat
    l := Stream.GetPos;
    Stream.Read(T,SizeOf(T));
    if T.Flags and rfDeleted > 0 then
      if T.Size = ASize then begin
        FindGAP := l;
        exit;
      end;
    Stream.Seek(l+SizeOf(T)+T.Size);
  until Stream.Status <> stOK;
  Stream.Reset;
end;

procedure TResource.ReplaceROB;
var
  P:PROB;
begin
  P := GetROB(T,rshId);
  DeleteROB(P^);
  WriteROB(T,T.MWhere);
end;

procedure TResource.WriteROB;
var
  PR         : PROB;
  PM         : PROB;
  dw         : longint;
  PV         : PVIFMap;
  PF         : PFont;
  Buf        : pointer;
  BufSize    : word;
  CRC        : word;
  current    : longint;
  H          : TROBHeader;
  code       : boolean;
  replace    : boolean;
  function GuessSize:longint;
  var
    plane : word;
  begin
    GuessSize := 0;
    case T.ROBType of
      rtSound : GuessSize := SizeOf(TSound)+PSound(T.MWhere)^.Size;
      rtMouse : GuessSize := SizeOf(TMIF);
      rtPalette : GuessSize := 256*3;
      rtImage : begin
                  PV := T.MWhere;
                  case PV^.Version of
                    1 : GuessSize := PV^.XSize*PV^.YSize+5;
                    2 : begin
                          plane     := Pixel2Byte(PV^.XSize)*PV^.YSize;
                          GuessSize := longint(plane)*longint(4)+5;
                        end;
                  end; {case}
                end;
      rtFont : begin
                 PF := T.MWhere;
                 case PF^.FontType of
                   ftBitMapped    : GuessSize := Pixel2Byte(PF^.ChrX)*PF^.ChrY*256+3;
                   ftProportional : GuessSize := 256+512+4+PF^.Size;
                 end; {case}
               end;
    end; {case}
  end;
  procedure SWrite(var buf;count:word);
  begin
    if code then EnCode(buf,count);
    Stream.Write(buf,count);
    if code then DeCode(buf,count);
  end;
  procedure WriteAll;
  var
    w  : word;
    P2 : Pointer;
  begin
    SWrite(T.MWhere^,T.Size);
  end;
  procedure WriteImage;
  var
    b       : byte;
    bufsize : word;
    w       : word;
    P2      : Pointer;
    w2      : word;
  begin
    SWrite(T.MWhere^,5);
    with PVIFMap(T.MWhere)^ do begin
      case T.Version of
        1 : SWrite(Data,XSize*YSize);
        2 : begin
              bufsize := Pixel2Byte(XSize)*YSize;
              T.Size := 5;
              for b:=0 to 3 do begin
                SWrite(Planes[b]^,bufsize);
                inc(T.Size,bufsize);
              end;
            end;
        else exit;
      end; {case}
    end; {with}
  end;
  function Duplicates:boolean;
  var
    n:integer;
  begin
    Duplicates := false;
    for n:=0 to Index^.Count-1 do begin
      PM := Index^.At(n);
      if ((PM^.ROBType = T.ROBType) and (PM^.Id = T.Id)) or CmpStr(PM^.Name,T.Name)
        then begin
          Duplicates := true;
          exit;
        end;
    end;
  end;
begin
  FOK := false;
  SOpen;
  if not OK then exit;
  if Mode = stOpenRead then exit;
  with H do begin
    Move(ROBId,Sign,SizeOf(Sign));
    ROBType  := T.ROBType;
    Id       := T.Id;
    Flags    := T.Flags;
    Version  := T.Version;
    if T.Size = 0 then T.Size := GuessSize;
    Size     := T.Size;
    CRC      := 0;
    Name     := T.Name;
  end;
  code := T.Flags and rfEncrypted > 0;
  if Duplicates then exit;
  dw := Stream.GetSize;
  Stream.Seek(dw);
  Stream.Write(H,SizeOf(H));
  case T.ROBType of
    rtImage : WriteImage;
    else WriteAll;
  end; {case}
  if T.Flags and rfProtected > 0 then begin
    Stream.Seek(dw+SizeOf(TROBHeader));
    H.CRC := XGetStreamChecksum(Stream,T.Size);
  end;
  H.Flags := T.Flags;
  H.Size  := T.Size;
  Stream.Seek(dw);
  Stream.Write(H,SizeOf(H));
  T.DWhere := dw;
  T.MWhere := NIL;
  New(PR);
  Move(T,PR^,sizeof(T));
  Index^.Insert(PR);
  SClose;
  FOK := true;
end;

{
SSG says:

Don't forget; in images there is no size information. Put this into
your brain.
}

function TResource.ReadROB(var T:TROB):pointer;
var
  P:Pointer;
  wash:word;
  P2:Pointer;
  w2:word;
  procedure SRead(var buf;count:word);
  begin
    Stream.Read(buf,count);
    if T.Flags and rfEncrypted > 0 then DeCode(buf,count);
  end;
  procedure ReadImage;
  var
    bufsize : word;
    xs,ys,w : word;
    b       : byte;
  begin
    SRead(xs,2);
    SRead(ys,2);
    SRead(b,1);
    case T.Version of
      1 : begin
            BufSize := xs*ys;
            GetMem(P,5+bufsize);
            with PVIFMap(P)^ do begin
              XSize   := xs;
              YSize   := ys;
              Version := b;
            end;
            SRead(PVIFMap(P)^.Data,bufsize);
          end;
      2 : begin
            bufsize := Pixel2Byte(xs)*ys;
            New(PVIFMap(P));
            with PVIFMap(P)^ do begin
              XSize   := xs;
              YSize   := ys;
              Version := b;
              for w:=0 to 3 do begin
                GetMem(Planes[w],bufsize);
                SRead(Planes[w]^,bufsize);
              end; {for}
            end; {with}
          end;
    end; {case}
  end;
  procedure ReadAll;
  begin
    GetMem(P,T.Size);
    if P = NIL then exit;
    SRead(P^,T.Size);
  end;
begin
  FOK     := false;
  ReadROB := NIL;
  P       := NIL;
  SOpen;
  Stream.Seek(T.DWhere+SizeOf(TROBHeader));
  case T.ROBType of
    rtImage : ReadImage;
    else ReadAll;
  end; {case}
  SClose;
  FOK     := P <> NIL;
  ReadROB := P;
end;

procedure TResource.SOpen;
begin
  Stream.Init(Filename^,Mode);
  OK := Stream.Status = stOK;
end;

procedure TResource.SClose;
begin
  Stream.Done;
end;

function TResource.GetByName;
var
  T:TROB;
  P:PROB;
begin
  GetByName := NIL;
  if not OK then exit;
  T.Name := RName;
  P := GetROB(T,rshName);
  if not FOK then exit;
  GetByName := Retrieve(P^);
end;

function TResource.Retrieve;
begin
  if T.MWhere = NIL then T.MWhere := ReadROB(T);
  Retrieve := T.MWhere;
  FOK      := T.MWhere <> NIL;
end;

function TResource.GetById;
var
  T:TROB;
  P:PROB;
begin
  GetById := NIL;
  if not OK then exit;
  T.ROBType := RType;
  T.Id      := Id;
  P := GetROB(T,rshId);
  if not FOK then exit;
  GetById := Retrieve(P^);
end;

constructor TResource.Init;
begin
  inherited Init;
  Filename := NewStr(AFName);
  Mode := AMode;
  SOpen;
  New(Index,Init(5,5));
  if Mode = stCreate then CreateHeader else begin
    OK := HeaderOK;
    BuildIndex;
  end;
  FOK := OK;
end;

procedure TResource.CreateHeader;
var
  T:TRIFHeader;
begin
  FillChar(T,SizeOf(T),0);
  Move(ResourceId,T.Id,SizeOf(TId));
  T.Version := 2;
  Stream.Seek(0);
  Stream.Write(T,SizeOf(T));
  OK  := Stream.Status = stOK;
  FOK := OK;
end;

destructor TResource.Done;
begin
  if Index <> NIL then Dispose(Index,Done);
  if FileName <> NIL then DisposeStr(Filename);
  inherited Done;
end;

procedure TResource.BuildIndex;
var
  T:TROBHeader;
  P:PROB;
  lp:longint;
begin
  if not OK then exit;
  Index^.FreeAll;
  Stream.Seek(chunkSize+SizeOf(TRIFHeader));
  repeat
    lp := Stream.GetPos;
    Stream.Read(T,SizeOf(T));
    if Stream.Status = stOK then
        if BufCmp(T.Sign,ROBId,SizeOf(TId)) then begin
          if T.Flags and rfDeleted = 0 then begin
            New(P);
            P^.ROBType := T.ROBType;
            P^.Flags   := T.Flags;
            P^.Version := T.Version;
            P^.Id      := T.Id;
            P^.Size    := T.Size;
            P^.MWhere  := NIL;
            P^.DWhere  := lp;
            P^.Name    := T.Name;
            Index^.Insert(P);
          end;
          Stream.Seek(Stream.GetPos+T.Size);
        end; {if bufcmp}
  until Stream.Status <> stOK;
  Stream.Reset;
end;

function TResource.HeaderOK:boolean;
var
  T:TRIFHeader;
  w:word;
  offs:longint;
  H:TExeHeader;
begin
  Fillchar(T,SizeOf(T),0);
  Stream.Seek(0);
  if chunkSize > 0 then Stream.Seek(chunkSize) else begin
    Stream.Read(w,2);
    if w = idEXE then begin
      Stream.Seek(0);
      Stream.Read(H,SizeOf(H));
      if H.LastPageSize <> 0 then dec(H.FileSize);
      offs := H.FileSize;
      chunkSize := (offs*512)+H.LastPageSize;
      Stream.Seek(chunkSize);
      repeat
        chunkSize := Stream.GetPos;
        Stream.Read(w,2);
        if w = idFB then begin
          Stream.Read(w,2);
          Stream.Read(offs,sizeof(offs));
          Stream.Seek(Stream.GetPos+offs);
        end else begin
          stream.Seek(stream.GetPos-2);
          break;
        end;
        chunkSize := Stream.GetPos;
      until (Stream.Status <> stOK);

      {if Stream.Status <> stOK then begin
        HeaderOK := false;
        exit;
      end;}
    end;
    Stream.Seek(chunkSize);
  end;
  Stream.Read(T,SizeOf(T));
  HeaderOK := BufCmp(T.Id,ResourceId,SizeOf(TId));
end;

procedure TROBCollection.FreeItem;
begin
  Dispose(PROB(Item));
end;

const

  inaxemm:boolean=false;

function AXEMM(Size:Word):integer;far;
begin
  AXEMM := 0;
  if inaxemm then exit;
  if Size = 0 then exit;
  inaxemm := true;
  RIF^.RequestMemory(Size);
  if MaxAvail > Size then AXEMM := 2;
  inaxemm := false;
end;

function InitRif(AFName:FnameStr):boolean;
begin
  New(RIF,Init(AFName,stOpen or $40));
  if not RIF^.FOK then begin
    Dispose(RIF,Done);
    New(RIF,Init(ParamStr(0),stOpen or $40));
  end;
  InitRif := RIF^.FOk;
end;

procedure DoneRif(P:PResource);
begin
  Dispose(RIF,Done);
  RIF := NIL;
end;

procedure InitAXE;
begin
  HeapError := @AXEMM;
  AXEOK     := True;
end;

procedure DoneAXE;
begin
  if not AXEOK then exit;
  if RIF <> NIL then begin
    Dispose(RIF,Done);
    RIF := NIL;
  end;
  AXEOK := false;
end;

function GetRscId;
var
  T:TROB;
  P:PROB;
begin
  GetRscId := $ffff;
  if not AXEOK then exit;
  T.ROBType := RType;
  T.name    := Name;
  P := RIF^.GetROB(T,rshName);
  if P <> NIL then GetRscId := P^.Id;
end;

function GetRscName;
var
  T:TROB;
  P:PROB;
begin
  GetRscName := '';
  if not AXEOK then exit;
  T.ROBType := RType;
  T.ID      := id;
  P := RIF^.GetROB(T,rshId);
  if P <> NIL then GetRscName := P^.Name;
end;

end.