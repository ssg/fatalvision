{
Name      : XCD 1.01b
Purpose   : MSCDEX implementation
Coder     : SSG
Date      : 1st May 95
Time      : 23:03

updates:
--------
 1st May 95 - 23:31 - finished...
 8th Aug 96 - 14:30 - perfected...
10th Aug 96 - 10:19 - still have bugs...
10th Aug 96 - 11:09 - perfect now...
10th Aug 96 - 12:03 - very perfect... ayrica acikogretimi kazanmi$im...
                      ehik...
29th Aug 96 - 17:58 - adapted to DPMI...
17th Sep 96 - 15:44 - perfected to DPMI...
20th Sep 96 - 01:56 - add ons...
}

unit XCD;

interface

const

  cdsError        = $8000;

  camHSG          = 0;
  camRedBook      = 1;

  cdsDoorOpen     = 1;
  cdsDoorLocked   = 2;
  cdsSupportsRAW  = 4;
  cdsReadWrite    = 8;
  cdsAudio        = 16;
  cdsInterleave   = 32;
  cdsPrefetch     = 64;
  cdsAudioManip   = 128;
  cdsRedBook      = 256;

  ioctlRead         = $03;
  ioctlWrite        = $0C;
  ioctlSeek         = $83;
  ioctlPlay         = $84;
  ioctlStop         = $85;
  ioctlResume       = $88;

type

  TDevReq = object
    Length   : byte;
    Subunit  : byte;
    Command  : byte;
    Status   : word;
    Reserved : array[1..8] of byte;
  end;

  TIOCTLI = object(TDevReq)
    Zero1 : byte;
    Addr  : pointer;
    Size  : word;
    Zero2 : array[1..6] of byte;
  end;

  TVTOC = array[1..2048] of byte;

  TIOCTLO = TIOCTLI;

  TIOCTLSeek = object(TDevReq)
    AddrMode : byte;
    Zero1    : longint;
    Zero2    : word;
    Start    : longint;
  end;

  TIOCTLPlay = object(TDevReq)
    AddrMode : byte;
    Start    : longint;
    Len      : longint;
  end;

  TCDTime = record
    frame : byte;
    sec   : byte;
    min   : byte;
    zero  : byte;
  end;

  TAudioInfo = record
    Lowest,Highest : byte;
    Start          : longint;
  end;

  TAudioStatus = record
    Paused     : boolean;
    LastStart  : longint;
    LastEnd    : longint;
  end;

  TQChannelInfo = record
    Track       : byte;
    TrackTime   : TCDTime;
    CDTime      : TCDTime;
  end;

  TUPCCode = array[1..7] of char;

const

  XCDCount       : word = 0;
  XCDVersion     : word = 0;
  XCDFirstDrive  : byte = 0;

var

  XCDDrives      : array[1..255] of byte;

function XCDInit:boolean;
function XCDReady(drive:word):boolean;
function XReadVTOC(drive,sector:word; var buf):byte;
function XSendReq(drive:word; var req:TDevReq; reqsize:word):boolean;
function XRed2HSG(var time:TCDTime):longint;
procedure XHSG2Red(l:longint; var time:TCDTime);

function  XIOCTLI(drive:word; var block;size:word):boolean;
function  XIOCTLO(drive:word; var block;size:word):boolean;
function  XCDSeek(drive:word; addrmode:byte; offs:longint):boolean;
function  XCDPlay(drive:word; addrmode:byte; start,len:longint):boolean;
function  XCDResume(drive:word):boolean;
function  XCDHeadLocation(drive:word):longint;
procedure XCDStop(drive:word);
function  XCDStatus(drive:word):longint;
function  XCDSectorSize(drive:word):word;
function  XCDCooked(drive:word):boolean;
function  XCDVolumeSize(drive:word):longint; {hsg}
function  XCDChanged(drive:word):boolean;
function  XCDAudioInfo(drive:word; var rec:TAudioInfo):boolean;
function  XCDTrackStart(drive:word; track:byte):longint;
procedure XCDQChannelInfo(drive:word; var rec:TQChannelInfo);
procedure XCDAudioStatus(drive:word; var rec:TAudioStatus);
procedure XCDGetUPCCode(drive:word; var upc:TUPCCode);
procedure XCDEject(drive:word);
procedure XCDLock(drive:word; lock:boolean);
procedure XCDReset(drive:word);
procedure XCDCloseTray(drive:word);
procedure XCDBuildDriveList;

implementation

uses

{$IFDEF DPMI}
XDPMI,WinAPI,
{$ENDIF}

XBuf,Objects;

{$IFDEF DPMI}
procedure cdint;
var
  regs:TRealModeRegs;
begin
  asm
    cld
    push es
    push ax
    push di
    push ss
    pop  es
    lea  di,regs
    pop  ax  {di popped}
    stosw
    xor  ax,ax
    stosw
    mov  ax,si
    stosw
    xor  ax,ax
    stosw
    stosw {bp as zero}
    stosw
    stosw {reserved zero}
    stosw
    mov  ax,bx
    stosw
    xor  ax,ax
    stosw
    mov  ax,dx
    stosw
    xor  ax,ax
    stosw
    mov  ax,cx
    stosw
    xor  ax,ax
    stosw
    pop  ax   {ax popped}
    stosw
    xor  ax,ax
    stosw
    stosw
    pop  ax {es popped}
    stosw
    mov  ax,ds
    stosw
    xor  ax,ax
    stosw  {fs & gs}
    stosw
    stosw  {ipcs}
    stosw
    stosw  {spss}
    stosw
  end;
  RealModeInt($2f,regs);
  asm
    cld
    push  ss
    pop   ds
    lea   si,regs
    lodsw
    mov   di,ax
    lodsw
    lodsw {si}
    push  ax {si pushed}
    lodsw
    lodsw {ebp skipped}
    lodsw
    lodsw {reserved skipped}
    lodsw
    lodsw {bx}
    mov   bx,ax
    lodsw
    lodsw {dx}
    mov   dx,ax
    lodsw
    lodsw {cx}
    mov   cx,ax
    lodsw
    lodsw {ax}
    push  ax {ax pushed}
    lodsw
    lodsw {flags}
    push  ax {flags pushed}
    lodsw
    mov   es,ax
    lodsw
    mov   ds,ax {ds}
    {remaining skipped}
    popf      {flagS}
    pop   ax  {ax}
    pop   si  {si}
  end;
end;

function PrepBuf(var buf; size:word):longint;
var
  handle:longint;
begin
  handle := GlobalDosAlloc(SizeOf(XCDDrives));
  asm
    push ds
    mov  cx,size
    cld
    xor  di,di
    mov  ax,word ptr handle
    mov  es,ax
    lds  si,buf
    rep  movsb
    pop  ds
  end;
  PrepBuf := handle;
end;

{$ELSE}
procedure CDInt;assembler;
asm
  int  2fh
end;
{$ENDIF}

{$IFDEF DPMI}
function XSendReq;
var
  regs:TRealModeRegs;
  handle:longint;
begin
  handle := PrepBuf(req,reqsize);
  ClearBuf(regs,SizeOf(regs));
  with regs do begin
    eax := $1510;
    ecx := drive+XCDFirstDrive;
    es  := LongRec(handle).Hi;
  end;
  RealModeInt($2f,regs);
  XSendReq := regs.Flags and 1 = 0;
  GlobalDosFree(handle);
end;
{$ELSE}
function XSendReq;assembler;
asm
  mov  ax,1510h
  mov  cx,drive
  xor  bh,bh
  mov  bl,XCDFirstDrive
  add  cx,bx
  les  bx,req
  call cdint
  mov  al,0
  jc   @skip
  inc  al
@skip:
end;
{$ENDIF}

function XCDReady;
var
  rec:TAudioInfo;
begin
  XCDReady := XCDAudioInfo(drive,rec);
end;

function XRed2HSG;
begin
  with time do XRed2HSG := ((longint(min) * longint(4500)) + (longint(sec) * longint(75)) + frame){ - 150};
end;

procedure XHSG2Red(l:longint; var time:TCDTime);
begin
{  inc(l,150);}
  time.frame := l mod 75;
  dec(l,time.frame);
  time.sec := (l div 75) mod 60;
  dec(l,time.sec);
  time.min := l div 4500;
end;

function XIOCTLI;
var
  T:TIOCTLI;
  handle:longint;
begin
  ClearBuf(T,SizeOf(T));
  T.Length  := SizeOf(T);
  T.Command := ioctlRead;
  {$IFDEF DPMI}
  handle := PrepBuf(block,size);
  T.Addr := Ptr(LongRec(handle).Hi,0);
  {$ELSE}
  T.Addr    := @block;
  {$ENDIF}
  T.Size    := size;
  XIOCTLI := (XSendReq(drive,T,SizeOf(T))) and (T.Status and cdsError=0);
  {$IFDEF DPMI}
  Move(Ptr(LongRec(handle).Lo,0)^,Block,Size);
  GlobalDosFree(handle);
  {$ENDIF}
end;

function XIOCTLO;
var
  T:TIOCTLO;
  handle:longint;
begin
  ClearBuf(T,SizeOf(T));
  T.Length  := SizeOf(T);
  T.Command := ioctlWrite;
  {$IFDEF DPMI}
  handle := PrepBuf(block,size);
  T.Addr := Ptr(LongRec(handle).Hi,0);
  {$ELSE}
  T.Addr    := @block;
  {$ENDIF}
  T.Size    := size;
  XIOCTLO := XSendReq(drive,T,SizeOf(T));
  {$IFDEF DPMI}
  Move(Ptr(LongRec(handle).Lo,0)^,Block,Size);
  GlobalDosFree(handle);
  {$ENDIF}
end;

function XCDSeek;
var
  T:TIOCTLSeek;
begin
  ClearBuf(T,SizeOf(T));
  T.Length  := SizeOf(T);
  T.Command := ioctlSeek;
  T.AddrMode := addrmode;
  T.Start := offs;
  XCDSeek := XSendReq(drive,T,SizeOf(T));
end;

function XCDPlay;
var
  T:TIOCTLPlay;
begin
  ClearBuf(T,SizeOf(T));
  T.Length  := SizeOf(T);
  T.Command := ioctlPlay;
  T.AddrMode := addrmode;
  T.Start := start;
  T.Len   := len;
  XCDPlay := XSendReq(drive,T,SizeOf(T));
end;

function XCDResume;
var
  T:TDevReq;
begin
  ClearBuf(T,SizeOf(T));
  T.Length  := SizeOf(T);
  T.Command := ioctlResume;
  XCDResume := XSendReq(drive,T,Sizeof(T));
end;

function XCDHeadLocation;
var
  block:record
          control:byte;
          mode:byte;
          location:longint;
        end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 1;
  XIOCTLI(drive,block,SizeOf(block));
  if block.mode = camRedBook then XCDHeadLocation := XRed2HSG(TCDTime(block.location))
                             else XCDHeadLocation := block.location;
end;

procedure XCDStop(drive:word);
var
  req:TDevReq;
begin
  ClearBuf(req,SizeOf(req));
  req.Length := SizeOf(req);
  req.Command := ioctlStop;
  XSendReq(drive,req,SizeOf(req));
end;

function XCDStatus(drive:word):longint;
var
  block:record
    control:byte;
    flags:longint;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 6;
  block.flags   := 0;
  XIOCTLI(drive,block,SizeOf(block));
  XCDStatus := block.flags;
end;

function XCDSectorSize(drive:word):word;
var
  block:record
    control:byte;
    readmode:byte;
    secsize:word;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 7;
  XIOCTLI(drive,block,SizeOf(block));
  XCDSectorSize := block.secsize;
end;

function XCDCooked(drive:word):boolean;
var
  block:record
    control:byte;
    readmode:byte;
    secsize:word;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 7;
  XIOCTLI(drive,block,SizeOf(block));
  XCDCooked := block.readmode = 2048;
end;

function XCDVolumeSize(drive:word):longint;
var
  block:record
    control:byte;
    volsize:longint;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 8;
  XIOCTLI(drive,block,SizeOf(block));
  XCDVolumeSize := block.volsize;
end;

function XCDChanged(drive:word):boolean;
var
  block:record
    control:byte;
    change:byte;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 9;
  XIOCTLI(drive,block,SizeOf(block));
  XCDChanged := block.change <> 1;
end;

function XCDAudioInfo(drive:word; var rec:TAudioInfo):boolean;
var
  block:record
    control:byte;
    hebe:TAudioInfo;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 10;
  XCDAudioInfo := XIOCTLI(drive,block,SizeOf(block));
  Move(block.hebe,rec,SizeOf(TAudioInfo));
end;

procedure XCDAudioStatus(drive:word; var rec:TAudioStatus);
var
  block:record
    control:byte;
    status:word;
    lstart:longint;
    lend:longint;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 15;
  XIOCTLI(drive,block,SizeOf(block));
  rec.Paused := block.status and 1 > 0;
  rec.LastStart := block.lstart;
  rec.LastEnd   := block.lend;
end;

function XCDTrackStart(drive:word; track:byte):longint;
var
  block:record
    control:byte;
    track:byte;
    start:longint;
    info:byte;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 11;
  block.track := track;
  XIOCTLI(drive,block,SizeOf(block));
  XCDTrackStart := (XRed2HSG(TCDTime(block.start)))-150;
end;

procedure XCDQChannelInfo;
var
  block:record
    control:byte;
    adr:byte;
    track:byte;
    hebe:byte;
    tmin,tsec,tframe:byte;
    zero:byte;
    amin,asec,aframe:byte;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 12;
  XIOCTLI(drive,block,SizeOf(block));
  with block do begin
    rec.Track := block.track;
    rec.trackTime.Min := tmin;
    rec.trackTime.Sec := tsec;
    rec.trackTime.Frame := tframe;
    rec.cdtime.Min := amin;
    rec.cdtime.Sec := asec;
    rec.cdtime.Frame := aframe;
  end;
end;

procedure XCDGetUPCCode(drive:word; var upc:TUPCCode);
var
  block:record
    control:byte;
    adr:byte;
    upc:TUPCCode;
    zero:byte;
    aframe:byte;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 14;
  XIOCTLI(drive,block,SizeOf(block));
  move(block.upc,upc,SizeOf(upc));
end;

procedure XCDEject(drive:word);
var
  b:byte;
begin
  b := 0;
  XIOCTLO(drive,b,1);
end;

procedure XCDLock(drive:word; lock:boolean);
var
  block:record
    control:byte;
    lock:byte;
  end;
begin
  ClearBuf(block,SizeOf(block));
  block.control := 1;
  block.lock    := byte(lock);
  XIOCTLO(drive,block,SizeOf(block));
end;

procedure XCDReset(drive:word);
var
  b:byte;
begin
  b := 2;
  XIOCTLO(drive,b,1);
end;

procedure XCDCloseTray(drive:word);
var
  b:byte;
begin
  b := 5;
  XIOCTLO(drive,b,1);
end;

{$IFDEF DPMI}
function XReadVTOC;
var
  regs:TRealModeRegs;
  handle:longint;
begin
  handle := PrepBuf(buf,SizeOf(TVTOC));
  ClearBuf(regs,SizeOf(regs));
  with regs do begin
    eax := $1505;
    ecx := drive;
    edx := sector;
    es  := longrec(handle).hi;
  end;
  RealModeInt($2f,regs);
  XReadVTOC := byte(regs.eax);
  GlobalDosFree(handle);
end;
{$ELSE}
function XReadVTOC;assembler;
asm
  mov  ax,1505h
  mov  cx,drive
  mov  dx,sector
  les  bx,buf
  call cdint
end;
{$ENDIF}

function XCDInit;assembler;
asm
  mov  ax,1500h
  xor  bx,bx
  xor  cx,cx
  call cdint
  xor  ax,ax
  or   bx,bx
  je   @Exit
  mov  XCDCount,bx
  mov  XCDFirstDrive,cl
  mov  ax,150ch
  call cdint
  mov  XCDVersion,bx
  call XCDBuildDriveList
  mov  ax,1
@Exit:
end;

procedure subprocess;assembler;
asm
  mov  bl,XCDFirstDrive
  mov  cx,XCDCount
  lea  si,XCDDrives
@loop:
  add  [si],bl
  inc  si
  loop @loop
end;

{$IFDEF DPMI}
procedure XCDBuildDriveList;
var
  regs:TRealModeRegs;
  handle:longint;
begin
  handle := PrepBuf(XCDDrives,SizeOf(XCDDrives));
  ClearBuf(regs,SizeOf(regs));
  with regs do begin
    eax := $150d;
    es  := Longrec(handle).hi;
  end;
  RealModeInt($2f,regs);
  GlobalDosFree(handle);
  subprocess;
end;
{$ELSE}
procedure XCDBuildDriveList;assembler;
asm
  mov  ax,150dh
  push ds
  pop  es
  lea  bx,XCDDrives
  call cdint
  call subprocess
end;
{$ENDIF}

end.