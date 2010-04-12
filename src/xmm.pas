{
Name            : eXtended Memory Manager 1.00b
Coder           : SSG
Date            : 19th Nov 93

Update Info:
------------
20th Nov 93 - 21:12 - Perfected... with a little les di help from FatalicA
23rd Nov 93 - 21:12 - Perfected again... with additional EMS functions...
 9th Jul 94 - 16:46 - Removed init strings...
11th Aug 94 - 19:01 - Revised...
}

unit XMM;

{$F+,G+,O-}

interface

const

  xmsOk               = 0;    {General driver errors}
  xmsInvalidFunction  = $80;
  xmsVDiskDetected    = $81;
  xmsA20Error         = $82;
  xmsDriverError      = $8E;
  xmsFatalDriverError = $8F;

  xmsNoHMA            = $90;  {HMA Errors}
  xmsHMAInUse         = $91;
  xmsHMAMINoverflow   = $92;
  xmsHMAUnAllocated   = $93;
  xmsCannotDisableA20 = $94;

  xmsNoExtendedFree   = $A0;  {Allocation errors}
  xmsNoHandlesFree    = $A1;
  xmsInvalidHandle    = $A2;
  xmsInvalidSrcHandle = $A3;
  xmsInvalidSrcOffset = $A4;
  xmsInvalidDstHandle = $A5;
  xmsInvalidDstOffset = $A6;
  xmsInvalidLength    = $A7;
  xmsInvalidOverlap   = $A8;
  xmsParityError      = $A9;
  xmsBlockNotLocked   = $AA;
  xmsBlockIsLocked    = $AB;
  xmsLockCountOverflow= $AC;
  xmsLockFailed       = $AD;

  xmsUMBSizeTooLarge  = $B0;  {UMB Errors}
  xmsNoUMBAvailable   = $B1;
  xmsInvalidUMBSeg    = $B2;
  {}
  emsOk               = 0;   {General driver errors}
  emsDriverError      = $80;
  emsHardwareError    = $81;
  emsUnknownError     = $82;
  emsInvalidFunction  = $84;

  emsInvalidHandle    = $83; {Allocation errors}
  emsNoHandlesFree    = $85;
  emsMappingError     = $86;
  emsNoPagesAvailable = $87;
  emsNoPagesFree      = $88;
  emsNoPageRequestion = $89;
  emsInvalidPage      = $8A;
  emsInvalidPageNumber= $8B;
  emsNoMapMemoryFree  = $8C;
  emsMapAlreadySaved  = $8D;
  emsMapNotSaved      = $8E;

  XMSError      : Byte    = xmsOk;
  XMSInstalled  : Boolean = false;

  EMSError      : Byte    = emsOk;
  EMSInstalled  : Boolean = false;

type

  TXMS = record
    Length    : Longint;
    SrcHandle : Word;
    SrcOffset : Longint;
    DstHandle : Word;
    DstOffset : Longint;
  end;

{--------------------  XMS FUNCTIONS  ----------------}
procedure  GetXMSHandleInfo(Handle:Word;var Size:Word;var LockCount,FreeHandles:Byte);
procedure  GetXMSInfo(var Version,Revision:Word;var HMA:Boolean);
procedure  GetXMSMemory(var Total,Free:Word);
function   GetXMSErrorStr(Error:Byte):String;

function   RequestUMB(Size:Word;var UMBSeg:Word):Word;
function   RequestHMA:boolean;
function   XMSAllocate(Size:Word):Word;

procedure  ReallocateUMB(UMBSeg,NewSize:Word);
procedure  XMSReAllocate(Handle,NewSize:Word);
procedure  XMSMove(var MoveStruc:TXMS);

procedure  ReleaseUMB(UMBSeg:Word);
procedure  ReleaseHMA;
procedure  XMSFree(Handle:Word);

procedure  LockXMSBlock(Handle:Word;var Block:Longint);
procedure  UnLockXMSBlock(Handle:Word);

procedure  LocalDisableA20;
procedure  LocalEnableA20;
procedure  GlobalDisableA20;
procedure  GlobalEnableA20;
function   IsA20Enabled:boolean;

{--------------------  EMS FUNCTIONS  ----------------}
procedure  GetEMSInfo(var Version:Word);
procedure  GetEMSMemory(var Total,Free:Word);
function   GetEMSErrorStr(Error:Byte):String;
function   GetEMSFrameSeg:Word;

function   EMSAllocate(Pages:Word):Word;

procedure  EMSMap(Handle:Word;PPage:Byte;LPage:Word);
procedure  EMSSaveMap(Handle:Word);
procedure  EMSRestoreMap(Handle:Word);

procedure  EMSFree(Handle:Word);

implementation

const

  XMSAPI       : Pointer = NIL;
  EMSAPI       = $67;

  EMSDriverName : array[0..7] of char = 'EMMXXXX0';

{*********************   EMS FUNCTIONS   *********************}

function   EMSAllocate(Pages:Word):Word;assembler;
asm
  mov  ah,43h
  mov  bx,Pages
  int  EMSAPI
  mov  EMSError,ah
  mov  ax,dx
end;

procedure  EMSMap(Handle:Word;PPage:Byte;LPage:Word);assembler;
asm
  mov  ah,44h
  mov  al,PPage
  mov  bx,LPage
  mov  dx,Handle
  int  EMSAPI
  mov  EMSError,ah
end;

procedure  EMSSaveMap(Handle:Word);assembler;
asm
  mov  ah,47h
  mov  dx,Handle
  int  EMSAPI
  mov  EMSError,ah
end;

procedure  EMSRestoreMap(Handle:Word);assembler;
asm
  mov  ah,48h
  mov  dx,Handle
  int  EMSAPI
  mov  EMSError,ah
end;

procedure  EMSFree(Handle:Word);assembler;
asm
  mov ah,45h
  mov dx,Handle
  int EMSAPI
  mov EMSError,ah
end;

procedure  GetEMSInfo(var Version:Word);assembler;
asm
  mov  ah,46h
  int  EMSAPI
  mov  EMSError,ah
  les  di,Version
  xor  bx,bx
  mov  bl,al
  and  bl,15
  shr  al,4
  mov  cx,10
  mul  cx
  add  ax,bx
  aam
end;

procedure  GetEMSMemory(var Total,Free:Word);assembler;
asm
  mov  ah,42h
  int  EMSAPI
  mov  EMSError,ah
  shl  dx,4
  shl  bx,4
  les  di,Total
  mov  word ptr es:[di],dx
  les  di,Free
  mov  word ptr es:[di],bx
end;

function   GetEMSErrorStr(Error:Byte):String;
var
  s:string;
begin
  s := '';
  case Error of
    emsOk               : S:='No error';
    emsDriverError      : S:='EMS driver failure';
    emsHardwareError    : S:='Hardware failure';
    emsUnknownError     : S:='Unknown error';
    emsInvalidFunction  : S:='Invalid function call';

    emsInvalidHandle    : S:='Invalid handle';
    emsNoHandlesFree    : S:='No free handles';
    emsMappingError     : S:='Map save/restore error';
    emsNoPagesAvailable : S:='No more available pages';
    emsNoPagesFree      : S:='No more free pages';
    emsNoPageRequestion : S:='No page requested';
    emsInvalidPage      : S:='Invalid page context with handle';
    emsInvalidPageNumber: S:='Invalid page number';
    emsNoMapMemoryFree  : S:='No map memory free';
    emsMapAlreadySaved  : S:='Map is already saved';
    emsMapNotSaved      : S:='Map not saved before';
    else s := 'Unknown error';
  end; {case}
  GetEMSErrorStr := s;
end;

function   GetEMSFrameSeg:Word;assembler;
asm
  mov  ah,41h
  int  EMSAPI
  mov  EMSError,ah
  mov  ax,bx
end;

{**********************  XMS FUNCTIONS   **************************}

function   GetXMSErrorStr(Error:Byte):String;
var
  S:String;
begin
  case Error of
     xmsOk               :S:='OK';
     xmsInvalidFunction  :S:='Function is not implemented';
     xmsVDiskDetected    :S:='VDisk device driver detected';
     xmsA20Error         :S:='Unable to control A20 line';
     xmsDriverError      :S:='General driver failure';
     xmsFatalDriverError :S:='Fatal driver failure';

     xmsNoHMA            :S:='HMA not available';
     xmsHMAInUse         :S:='HMA is already in use';
     xmsHMAMINoverflow   :S:='Size exceeds minimum HMA size';
     xmsHMAUnAllocated   :S:='Cannot allocate HMA';
     xmsCannotDisableA20 :S:='Cannot disable A20 line';

     xmsNoExtendedFree   :S:='No free extended memory remaining';
     xmsNoHandlesFree    :S:='No free handles';
     xmsInvalidHandle    :S:='Invalid handle';
     xmsInvalidSrcHandle :S:='Invalid source handle';
     xmsInvalidSrcOffset :S:='Invalid source offset';
     xmsInvalidDstHandle :S:='Invalid destination handle';
     xmsInvalidDstOffset :S:='Invalid destination offset';
     xmsInvalidLength    :S:='Invalid length';
     xmsInvalidOverlap   :S:='Invalid block overlap';
     xmsParityError      :S:='Memory parity error';
     xmsBlockNotLocked   :S:='Block is not locked';
     xmsBlockIsLocked    :S:='Block is locked';
     xmsLockCountOverflow:S:='LockCount overflow';
     xmsLockFailed       :S:='Lock failed';

     xmsUMBSizeTooLarge  :S:='Requested UMB size is too large';
     xmsNoUMBAvailable   :S:='No UMBs available';
     xmsInvalidUMBSeg    :S:='Invalid UMB segment';
    else
      S := 'Unknown Error';
  end; {case}
  GetXMSErrorStr := S;
end;

procedure GetXMSInfo(var Version,Revision:Word;var HMA:Boolean);assembler;
asm
  xor  ah,ah
  call XMSAPI
  les  di,Version
  mov  word ptr es:[di],ax
  les  di,Revision
  mov  word ptr es:[di],bx
  les  di,HMA
  mov  byte ptr es:[di],DL
  mov  XMSError,BL
end;

function RequestHMA:boolean;assembler;
asm
  mov  ah,1
  mov  dx,$FFFF
  call XMSAPI
  mov  XMSError,BL
end;

procedure ReleaseHMA;assembler;
asm
  mov  ah,2
  call XMSAPI
  mov  XMSError,BL
end;

procedure GlobalEnableA20;assembler;
asm
  mov  ah,3
  call XMSAPI
  mov  XMSError,BL
end;

procedure GlobalDisableA20;assembler;
asm
  mov  ah,4
  call XMSAPI
  mov  XMSError,BL
end;

procedure LocalEnableA20;assembler;
asm
  mov  ah,5
  call XMSAPI
  mov  XMSError,BL
end;

procedure LocalDisableA20;assembler;
asm
  mov  ah,6
  call XMSAPI
  mov  XMSError,BL
end;

function IsA20Enabled:boolean;assembler;
asm
  mov  ah,7
  call XMSAPI
  mov  XMSError,BL
end;

procedure GetXMSMemory(var Total,Free:Word);assembler;
asm
  mov  ah,8
  call XMSAPI
  les  di,Total
  mov  word ptr es:[di],DX
  les  di,Free
  mov  word ptr es:[di],AX
  mov  XMSError,BL
end;

function XMSAllocate(Size:Word):Word;assembler;
asm
  mov  ah,9
  mov  dx,Size
  call XMSAPI
  mov  ax,dx
  mov  XMSError,BL
end;

procedure XMSFree(Handle:Word);assembler;
asm
  mov  ah,0ah
  mov  dx,Handle
  call XMSAPI
  mov  XMSError,BL
end;

procedure XMSMove(var MoveStruc:TXMS);assembler;
asm
  push ds
  lds  si,MoveStruc
  mov  ah,0bh
  call XMSAPI
  pop  ds
  mov  XMSError,BL
end;

procedure LockXMSBlock(Handle:Word;var Block:Longint);assembler;
asm
  mov  ah,0ch
  mov  dx,Handle
  call XMSAPI
  les  di,Block
  mov  word ptr es:[di],bx
  mov  word ptr es:[di+2],dx
  mov  XMSError,BL
end;

procedure UnLockXMSBlock(Handle:Word);assembler;
asm
  mov  ah,0dh
  mov  dx,Handle
  call XMSAPI
  mov  XMSError,BL
end;

procedure GetXMSHandleInfo(Handle:Word;var Size:Word;var LockCount,FreeHandles:Byte);assembler;
asm
  mov  ah,0eh
  mov  dx,Handle
  call XMSAPI
  les  di,Size
  mov  word ptr es:[di],DX
  les  di,LockCount
  mov  byte ptr es:[di],BH
  les  di,FreeHandles
  mov  byte ptr es:[di],BL
  mov  XMSError,BL
end;

procedure XMSReAllocate(Handle,NewSize:Word);assembler;
asm
  mov  ah,0fh
  mov  bx,NewSize
  mov  dx,Handle
  call XMSAPI
  mov  XMSError,BL
end;

function RequestUMB(Size:Word;var UMBSeg:Word):Word;assembler;
asm
  mov  ah,10h
  mov  dx,Size
  call XMSAPI
  or   ax,ax
  jz   @Ok
  xor  bx,bx
  xor  dx,dx
@Ok:
  les  di,UMBSeg
  mov  word ptr es:[di],BX
  mov  ax,dx
  mov  XMSError,BL
end;

procedure ReleaseUMB(UMBSeg:Word);assembler;
asm
  mov  ah,11h
  mov  dx,UMBSeg
  call XMSAPI
  mov  XMSError,BL
end;

procedure ReallocateUMB(UMBSeg,NewSize:Word);assembler;
asm
  mov  ah,12h
  mov  dx,UMBSeg
  mov  bx,NewSize
  call XMSAPI
  mov  XMSError,BL
end;

begin
  asm
    mov XMSInstalled,False
    mov ax,4300h
    int 2fh
    cmp al,80h
    jne @Fuck
    mov XMSInstalled,True
    mov ax,4310h
    int 2fh
    mov word ptr [XMSAPI],bx
    mov word ptr [XMSAPI+2],es
  @Fuck:
    mov  EMSInstalled,False
    mov  ax,$3567
    int  21h
    mov  di,10
    push ds
    mov  ax,seg EMSDriverName
    mov  ds,ax
    mov  si,offset EMSDriverName
    mov  cx,8
    repz cmpsb
    pop  ds
    jne  @FuckAgain
    mov  EMSInstalled,True
  @FuckAgain:
  end;
end.
