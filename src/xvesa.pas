{
Name            : X/VESA 2.00b
Purpose         : VESA API services...
Coder           : SSG
Date            : 28th Nov 93

updates:
--------
27th Jun 96 - 23:57 - rewriting the code...
28th Jun 96 - 00:16 - finished...
 8th Sep 97 - 19:08 - retouched...
}

unit XVESA;

interface

const

  vmaModeSupported  = 1;
  vmaOptionalInfo   = 2;
  vmaBIOSOutput     = 4;
  vmaColor          = 8;
  vmaGraphics       = 16;
  vmaNonVGA         = 32;
  vmaBankSwitching  = 64;
  vmaLinearFrameBuf = 128;

  vwaExists         = 1;
  vwaReadable       = 2;
  vwaWriteable      = 4;

  vmmText           = 0;
  vmmCGA            = 1;
  vmmHercules       = 2;
  vmmEGA16          = 4;
  vmmPacked         = 8;
  vmmVGA256         = 16;
  vmmDirect         = 32;
  vmmYUV            = 64;

type

  TVESAInfo = record
    Header  : array[0..3] of char;
    Version : Word;
    OEMName : Pointer;
    Specs   : Longint;
    Modes   : Pointer;
    Reserved: array[1..238] of byte;
  end;

  TVESAModeInfo = record
    Attr         : Word;
    WAttrA       : Byte;
    WAttrB       : Byte;
    WGranularity : Word;
    WSize        : Word;
    WSegA        : word;
    WSegB        : Word;
    WinPos       : Pointer;
    ScanLineBytes: Word;
    XSize        : Word;
    YSize        : Word;
    CharXSize    : Byte;
    CharYSize    : Byte;
    Planes       : Byte;
    BitsPerPixel : Byte;
    Banks        : Byte;
    MemoryModel  : Byte;
    BankSize     : Byte;
    Reserved     : array[1..256-29] of byte;
  end;

function VESAInstalled:boolean;
function VESASetMode(mode:word):boolean;
function VESAGetMode:word;
function VESAGetModeInfo(mode:word; var modeinfo:TVESAModeInfo):boolean;
procedure VESASetBank(bank:byte);

implementation

procedure VESASetBank;assembler;
asm
  mov  ax,4f05h
  xor  bx,bx
  mov  dl,bank
  int  10h
end;

function VESAGetModeInfo;assembler;
asm
  mov  ax,4f01h
  mov  cx,mode
  les  di,modeinfo
  int  10h
  mov  al,ah
  xor  al,1
end;

function VESASetMode;assembler;
asm
  mov  ax,4f02h
  mov  bx,mode
  int  10h
  xor  ah,1
  mov  al,ah
end;

function VESAGetMode;assembler;
asm
  mov  ax,4f03h
  int  10h
  mov  ax,bx
end;

function VESAInstalled;assembler;
var
  VESAInfo:TVESAInfo;
asm
  mov  ax,4f00h
  push ss
  pop  es
  lea  di,VESAInfo
  int  10h
  xor  ah,ah
  cmp  al,4fh
  jne  @skip
  inc  ah
@skip:
  mov  al,ah
end;

end.