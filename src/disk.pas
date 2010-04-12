{
Name            : Disk 1.01e
Purpose         : Low Level Disk Functions
Date            : 12th Aug 93
Coder           : SSG

Update Info:
------------
26th May 94 - 02:05 - SSG DID IT AGAIN!!!! THE ULTIMATE CHANGELINE
                      DETECTION ROUTINES!!!!...
11th Aug 94 - 16:40 - Added PartRecs...
30th Oct 94 - 20:19 - Corrected DosRead...
23rd Dec 94 - 11:54 - Re-corrected DosRead & added DosWrite...
26th Mar 95 - 00:06 - Made DiskExists work..
27th Jun 96 - 16:26 - Added IBM/MS Disk Extensions....
19th Jul 97 - 22:04 - revising code... gonna try to adapt the source to
                      DPMI shit...
}

unit Disk;

interface

const

  pcEmpty        = $00;  pcFAT12        = 1; {partition codes}
  pcXenixRoot    = $02;  pcXenixUsr     = 3;
  pcFAT16        = $04;  pcDOS3Extended = 5;
  pcDOS3Large    = $06;  pcHPFS         = 7;
  pcNTFS         = $07;  pcAIXBoot      = 8;
  pcCoherent     = $09;  pcBootManager  = $a;
  pcOPUS         = $10;  pcHiddenFAT12  = $11;
  pcCompaq       = $12;  pcHiddenFAT16  = $14;
  pcHiddenBIGDOS = $16;  pcHiddenHPFS   = $17;
  pcVENIX286     = $40;  pcSFS          = $42;
  pcDMRO         = $50;  pcDMRW         = $51;
  pcV386         = $52;  pcUnixSysV     = $63;
  pcNetware      = $64;  pcNetware311   = $65;
  pcPCIX         = $75;  pcMinix        = $80;
  pcLinux        = $81;  pcLinuxSwap    = $82;
  pcLinuxNative  = $83;  pcHiddenDOS    = $84;
  pcFreeBSD      = $a5;  pcFAT32        = $b;

type

  PDPT = ^TDPT;
  TDPT = record
    HeadMoveTime    : Byte; {bit 7-4:step rate; bit 3-0:head unload time}
    DMAMode         : Byte; {bit 7-1:head load time; bit 0:non-DMA mode}
    IdleTime        : Byte; {motor off delay in clock ticks}
    BytesPerSector  : Byte; {0 = 128, 1 = 256, 2 = 512, 3 = 1024}
    SectorsPerTrack : Byte; {sectors per track}
    InterleaveTime  : Byte; {gap between sectors; 2Ah 5.25", 1Bh 3.5"}
    DataLength      : Byte; {ignored if bytespersector <> 0}
    InterleaveGAP   : Byte; {format gap length (50h 5.25", 6Ch 3.5"}
    FormatCode      : Byte; {format filler byte (F6h)}
    TrackMoveTime   : Byte; {head settle time in miliseconds}
    SpinupTime      : Byte; {motor start time in 1/8 seconds}
    Pad             : array[1..5] of byte;
  end;

  PFormatInfo = ^TFormatInfo;
  TFormatInfo = record
    Cyl       : byte;
    Head      : byte;
    Sector    : byte;
    BytesPerSector : byte;
  end;

  PBootRecord = ^TBootRecord;
  TBootRecord = record
    case Boolean of
      True : (Data:array [1..512] of byte;);
      False: (
    Jump                  : array[1..3] of byte;
    OEMID                 : array[1..8] of byte;
    BytesPerSector        : Word;
    SectorsPerCluster     : Byte;
    ReservedSectors       : Word;
    FATCopies             : Byte;
    RootDirEntries        : Word;
    TotalSectors          : Word;
    MediaDescriptor       : Byte;
    SectorsPerFAT         : Word;
    SectorsPerTrack       : Word;
    Sides                 : Word;
    HiddenSectors         : Word;
    Reserved              : Word;
    BigTotalSectors       : Longint;
    PhysicalDriveNumber   : Word;
    ExtendedBootSignature : Byte;
    SerialNumber          : Longint;
    VolumeLabel           : array[1..8] of byte;
    FileSysID             : array[1..8] of byte;);
  end;

  PPart = ^TPart;
  TPart = record
    Boot   : boolean;
    SHead  : byte;
    SSec   : byte;
    SCyl   : byte;
    OS     : byte;
    EHead  : byte;
    ESec   : byte;
    ECyl   : byte;
    RelSec : longint;
    TotSec : longint;
  end;

  PPartTable = ^TPartTable;
  TPartTable = record
    Code     : array[1..$1BE] of byte;
    Recs     : array[1..4] of TPart;
    Sign     : word;
  end;

function  ResetDisk(Drive:Byte):Byte;
function  GetDiskStatus(Drive:Byte):Byte;
function  ReadDisk(var Buf;Drive,Head,SecStart,SecCount:Byte;Cyl:Word):byte;
function  WriteDisk(var Buf;Drive,Head,SecStart,SecCount:Byte;Cyl:Word):byte;
function  SafeRead(var Buf;Drive,Head,SecStart,SecCount:Byte;Cyl:Word):byte;
function  SafeWrite(var Buf;Drive,Head,SecStart,SecCount:Byte;Cyl:Word):byte;
function  VerifyDisk(Drive,Head,SecStart,SecCount:Byte;Cyl:Word):Byte;
function  FormatCylinder(Drive,Head,SecCount,BytesPerSect,Interleave:Byte;Cyl:Word):Byte;
function  ChangeLine(Drive:Byte):Byte;
function  GetDisketteParams(Drive:Byte):word; {hi=type; lo=count}

function  DosRead(var Buf;Drive:Byte;SecStart,SecCount:Word):word;
function  DosWrite(var Buf;Drive:Byte;SecStart,SecCount:Word):word;

procedure MotorOn(Drive:byte);
procedure MotorOff(drive:byte);

implementation

{$IFDEF DPMI}
uses

  WinAPI,XDPMI;
{$ENDIF}

procedure MotorOn(drive:byte);assembler;
asm
  cli
  mov  dl,Drive
  mov  al,1
  mov  cl,dl
  add  cl,4
  shl  al,cl
  or   al,Drive
  or   al,$c
  mov  dx,3f2h
  out  dx,al
  sti
end;

procedure MotorOff(drive:byte);assembler;
asm
  cli
  mov  dl,Drive
  mov  al,1
  mov  cl,dl
  add  cl,4
  shl  al,cl
  not  drive
  and  al,drive
  or   al,$c
  mov  dx,3f2h
  out  dx,al
  sti
end;

function BIOSChangeLine(drive:byte):byte;assembler;
asm
  mov  ah,16h
  mov  dl,drive
  int  13h
  mov  al,ah
end;

function DiskChange(drive:byte):boolean;assembler;
asm
  xor  ah,ah
  mov  al,drive
  push ax
  call Motoron
  mov  dx,3f7h
  in   al,dx
  xor  ah,ah
  and  al,$80
  rol  al,1
  not  al
  and  al,1
end;

function  SafeRead(var Buf;Drive,Head,SecStart,SecCount:Byte;Cyl:Word):Byte;
var
  tries:byte;
  w:word;
begin
  for tries := 0 to 2 do begin
    w := ReadDisk(Buf,Drive,Head,SecStart,SecCount,Cyl);
    if lo(w) = 0 then break;
  end;
  SafeRead := lo(w);
end;

function  SafeWrite(var Buf;Drive,Head,SecStart,SecCount:Byte;Cyl:Word):Byte;
var
  tries:byte;
  w:word;
begin
  for tries := 0 to 2 do begin
    w := WriteDisk(Buf,Drive,Head,SecStart,SecCount,Cyl);
    if lo(w) = 0 then break;
  end;
  SafeWrite := lo(w);
end;

function ResetDisk(Drive:Byte):Byte;assembler;
asm
  xor ah,ah
  mov dl,Drive
  int $13
  jc  @Exit
  xor ax,ax
@Exit:
  xchg ah,al
end;

function GetDiskStatus(Drive:Byte):Byte;assembler;
asm
  mov ah,1
  mov dl,Drive
  int $13
  jc  @Exit
  xor ax,ax
@Exit:
  xchg ah,al
end;

function  DosRead(var Buf;Drive:Byte;SecStart,SecCount:Word):word;assembler;
asm
  push ds
  xor  ah,ah
  mov  al,drive
  mov  cx,SecCount
  mov  dx,SecStart
  lds  bx,Buf
  int  25h
  jc   @Exit
  xor  ax,ax
@Exit:
  pop  bx
  pop  ds
end;

function  DosWrite(var Buf;Drive:Byte;SecStart,SecCount:Word):word;assembler;
asm
  push ds
  xor  ah,ah
  mov  al,drive
  mov  cx,SecCount
  mov  dx,SecStart
  lds  bx,Buf
  int  26h
  jc   @Exit
  xor  ax,ax
@Exit:
  pop  bx
  pop  ds
end;

function ReadDisk;assembler;
asm
  les  bx, Buf
  mov  ah,2
  mov  al,SecCount
  mov  dx,Cyl
  mov  cl,6
  shl  dh,cl
  xchg dh,dl
  mov  cx,dx
  xor  dh,dh
  mov  dl,SecStart
  and  dl,3fh
  or   cx,dx
  mov  dh,Head
  mov  dl,Drive
  int  13h
  mov  al,ah
  xor  ah,ah
end;

function WriteDisk;assembler;
asm
  les  bx, Buf
  mov  ah,3
  mov  al,SecCount
  mov  dx,Cyl
  mov  cl,6
  shl  dh,cl
  xchg dh,dl
  mov  cx,dx
  xor  dh,dh
  mov  dl,SecStart
  and  dl,3fh
  or   cx,dx
  mov  dh,Head
  mov  dl,Drive
  int  13h
  mov  al,ah
  xor  ah,ah
end;

function VerifyDisk(Drive,Head,SecStart,SecCount:Byte;Cyl:Word):Byte;assembler;
asm
  mov  ah,4
  mov  al,SecCount
  mov  dx,Cyl
  mov  cl,6
  shl  dh,cl
  xchg dh,dl
  mov  cx,dx
  xor  dh,dh
  mov  dl,SecStart
  and  dl,$3F
  or   cx,dx
  mov  dh,Head
  mov  dl,Drive
  int  $13
  mov  al,ah
  xor  ah,ah
end;

function SetMediaType(Var TargetDPT:PDPT; Drive,Head,SecCount:Byte; Tracks:Word):Byte; assembler;
asm
  mov     ah,$18
  mov     dx,Tracks
  mov     cl,6
  shl     dh,cl
  xchg    dh,dl
  mov     cx,dx
  mov     dl,SecCount
  and     dl,$3F
  or      cx,dx
  xor     dh,dh
  mov     dl,Drive
  int     $13
  jb      @Error
  push    ds
  lds     si,TargetDPT
  mov     [si],di
  mov     [si+02],es
  pop     ds
@Error:        xchg    ah,al
end;

function FormatCylinder(Drive,Head,SecCount,BytesPerSect,Interleave:Byte;Cyl:Word):Byte;
var
  FormatTable : Array[0..127] of TFormatInfo;
  P           : PFormatInfo;
  TP          : PDPT;
  I           : Byte;
  X,A,B       : Byte;
begin
   FillChar(FormatTable,SizeOf(FormatTable),0);
   X := 1;
   if Interleave > 1 then begin
     A := (SecCount+1) div Interleave;
   end else A := 1;
   For I:=1 to SecCount do begin
     P := @FormatTable[I-1];
     P^.Cyl            := Cyl;
     P^.Head           := Head;
     P^.Sector         := X;
     inc(X,A);
     if X > SecCount then X := X mod A + 1;
     P^.BytesPerSector := BytesPerSect; {512 bytes/sector}
   end;
   SetMediaType(TP,Drive,2,18,79);
   asm
     mov  ax,ss
     mov  es,ax
     lea  bx,FormatTable
     mov  ah,$05
     mov  al,SecCount
     mov  dx,Cyl
     mov  cl,6
     shl  dh,cl
     xchg dh,dl
     mov  cx,dx
     mov  dh,Head
     mov  dl,Drive
     int  $13
     jb   @Exit
     xor  ax,ax
   @Exit:
     mov @Result,ah
   end;
end;

function GetDisketteParams;assembler;
asm
  mov  ah,8
  mov  dl,Drive
  int  $13
  mov  ah,bl
  mov  al,dl
end;

function  ChangeLine(Drive:Byte):Byte;assembler;
asm
  mov ah,$16
  mov dl,Drive
  int $13
  xchg ah,al
end;

end.
