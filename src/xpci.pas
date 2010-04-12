{
Name    : X/PCI 1.00a
Purpose : PCI BIOS Extensions
Coder   : SSG
Date    : 3rd Jan 97
Time    : 04:32

updates:
--------
29th Jun 97 - 00:48 - Made it to compile...
}

unit XPCI;

interface

const

  XPCIVersion : word = 0;
  XPCILastBus : byte = 0;
  XPCIEntry   : pointer = NIL;

  ESCDSign    = $47464341;

type

  TESCD = record
    TableLength : word;
    Sign        : word;
    Version     : word;
    Boards      : byte;
    Reserved    : array[0..2] of byte;
  end;

  TESCDBoardHeader = record
    HdrLen         : word;
    Slot           : byte;
    Reserved       : byte;
  end;

  TESCDFreeformBoardHeader = record
    Sign                   : word;
    Version                : word;
    BoardType              : byte;
    Reserved               : byte;
    DisabledFuncs          : word;
    CEF                    : word;
    ReconfigFuncs          : word;
  end;

  TESCDFreeformPCIDeviceData = record
    BusNumber                : byte;
    DevicFun                 : byte;
    DeviceId                 : word;
    VendorId                 : word;
    Reserved                 : word;
  end;

  TESCDPnPISABoardId = record
    VendorId         : longint;
    Serial           : longint;
  end;

  TPCICard    = record
    DevicFun  : byte;
    Bus       : byte;
  end;

function XPCIInit:boolean;
function XPCIFindDevice(deviceid,vendorid,deviceindex:word; var card:word):boolean;
function XPCIFindClassCode(classcode:longint; deviceindex:word; var card:word):boolean;
function XPCIGetConfigByte(card,reg:word):byte;
function XPCIGetConfigWord(card,reg:word):word;
function XPCIGetConfigDWord(card,reg:word):longint;
procedure XPCISetConfigByte(card,reg:word; config:byte);
procedure XPCISetConfigWord(card,reg:word; config:word);
procedure XPCISetConfigDWord(card,reg:word; config:longint);

implementation

procedure XPCISetConfigDWord;assembler;
asm
  mov  ax,0b10dh
  mov  bx,card
  mov  di,reg
  mov  cx,word ptr config+2
  db   66h
  shl  cx,16
  mov  cx,word ptr config
  int  1ah
end;

procedure XPCISetConfigWord;assembler;
asm
  mov  ax,0b10ch
  mov  bx,card
  mov  di,reg
  mov  cx,config
  int  1ah
end;

procedure XPCISetConfigByte;assembler;
asm
  mov  ax,0b10bh
  mov  bx,card
  mov  di,reg
  mov  cl,config
  int  1ah
end;

function XPCIGetConfigDWord;assembler;
asm
  mov  ax,0b10ah
  mov  bx,card
  mov  di,reg
  int  1ah
  mov  ax,cx
  db   66h
  shr  cx,16
  mov  dx,cx
end;

function XPCIGetConfigWord;assembler;
asm
  mov  ax,0b109h
  mov  bx,card
  mov  di,reg
  int  1ah
  mov  ax,cx
end;

function XPCIGetConfigByte;assembler;
asm
  mov  ax,0b108h
  mov  bx,card
  mov  di,reg
  int  1ah
  mov  al,cl
end;

function XPCIFindClassCode;assembler;
asm
  cld
  mov  ax,0b103h
  mov  cx,word ptr classcode+2
  db   66h
  shl  cx,16
  mov  cx,word ptr classcode
  mov  si,deviceindex
  int  1ah
  xor  al,al
  or   ah,ah
  jne  @skip
  les  di,card
  mov  ax,bx
  stosw
@skip:
end;

function XPCIFindDevice;assembler;
asm
  cld
  mov  ax,0b102h
  mov  cx,deviceid
  mov  dx,vendorid
  mov  si,deviceindex
  int  1ah
  xor  al,al
  or   ah,ah
  jne  @skip
  les  di,card
  mov  ax,bx
  stosw
@skip:
end;

function XPCIInit;assembler;
asm
  mov  ax,0b101h
  int  1ah
  xor  al,al
  or   ah,ah
  jne  @skip
  mov  word ptr XPCIEntry,di
  db   66h
  shr  di,16
  mov  word ptr XPCIEntry+2,di
  mov  XPCIVersion,bx
  mov  XPCILastBus,cl
@skip:
end;

end.