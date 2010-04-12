{
Name      : X/Fossil 1.00d
Purpose   : Low level fossil interface
Coder     : SSG
Date      : 24th May 95
Time      : 01:18

updates:
--------
24th May 95 - 02:01 - finished... perfectly... 312 bytes code, no data...
27th Jun 95 - 11:01 - added superset 1ch...
15th Nov 95 - 14:12 - added char support...
}

unit XFossil;

interface

const

  baud300     = 2 shl 5;
  baud600     = 3 shl 5;
  baud1200    = 4 shl 5;
  baud2400    = 5 shl 5;
  baud4800    = 6 shl 5;
  baud9600    = 7 shl 5;
  baud19200   = 0 shl 5;
  baud38400   = 1 shl 5;

  parityNo    = 0 shl 4;
  parityOdd   = 1 shl 4;
  parityEven  = 3 shl 4;

  stop1       = 0 shl 2;
  stop152     = 1 shl 2;

  bits5       = 0;
  bits6       = 1;
  bits7       = 2;
  bits8       = 3;

  lineRDA     = 1;
  lineOVRN    = 2;
  lineTHRE    = 32;
  lineTSRE    = 64;
  lineTimeout = 128;

  modemDCTS   = 1;
  modemDDSR   = 2;
  modemDDCD   = 4;
  modemDummy  = 8;
  modemCTS    = 16;
  modemDSR    = 32;
  modemRI     = 64;
  modemDCD    = 128;

  flowXonXoff = 9;
  flowRTSCTS  = 2;

  bootCold    = 0;
  bootWarm    = 1;

type

  TFossilRec = record
    StructSize    : word;
    FossilRev     : byte;
    DriverRev     : byte;
    Description   : PChar;
    InBufferSize  : word;
    iFree         : word;
    OutBufferSize : word;
    oFree         : word;
    ScrXSize      : byte;
    ScrYSize      : byte;
    Baud          : byte;
  end;

procedure XSetCommParams(port:word; params:byte);
procedure XSendChar(port:word; chr:char);
procedure XSendNoWait(port:word; chr:char);
procedure XDeactivatePort(port:word);
procedure XSetDTR(port:word; raise:boolean);
procedure XFlushOutBuffer(port:word);
procedure XPurgeOutBuffer(port:word);
procedure XPurgeInBuffer(port:word);
procedure XSetFlowControl(port:word; flow:byte);
procedure XReboot(boottype:byte);
procedure XStartBreak(port:word);
procedure XStopBreak(port:word);
procedure XGetFossilInfo(port:word; var rec:TFossilRec);

function  XReceiveBlock(port:word; var buf; size:word):word;
function  XSendBlock(port:word; var buf; size:word):word;
function  XOldActivatePort(port:word):boolean;
function  XActivatePort(port:word):boolean;
function  XReceiveChar(port:word):char;
function  XGetPortStatus(port:word):word;
function  XPeek(port:word):word;

implementation

procedure XGetFossilInfo;assembler;
asm
  mov  ah,1bh
  mov  cx,type TFossilRec
  mov  dx,port
  les  di,rec
  int  14h
end;

procedure XStartBreak;assembler;
asm
  mov  ax,1a01h
  mov  dx,port
  int  14h
end;

procedure XStopBreak;assembler;
asm
  mov  ax,1a00h
  mov  dx,port
  int  14h
end;

function XReceiveBlock;assembler;
asm
  mov  ah,18h
  mov  dx,port
  mov  cx,size
  les  di,buf
  int  14h
end;

function XSendBlock;assembler;
asm
  mov  ah,19h
  mov  dx,port
  mov  cx,size
  les  di,buf
  int  14h
end;

procedure XReboot;assembler;
asm
  mov  ah,17h
  mov  al,boottype
  int  14h
end;

procedure XSetFlowControl;assembler;
asm
  mov  ah,0fh
  mov  al,flow
  mov  dx,port
  int  14h
end;

function XPeek;assembler;
asm
  mov  ah,0ch
  mov  dx,port
  int  14h
end;

procedure XSendNowait;assembler;
asm
  mov ah,0bh
  mov al,chr
  mov dx,port
  int 14h
end;

procedure XPurgeInBuffer;assembler;
asm
  mov  ah,0ah
  mov  dx,port
  int  14h
end;

procedure XPurgeOutBuffer;assembler;
asm
  mov  ah,9
  mov  dx,port
  int  14h
end;

procedure XFlushOutBuffer;assembler;
asm
  mov  ah,8
  mov  dx,port
  int  14h
end;

procedure XSetDTR;assembler;
asm
  mov  ah,6
  mov  al,raise
  mov  dx,port
  int  14h
end;

procedure XDeactivatePort;assembler;
asm
  mov  ah,5
  mov  dx,port
  int  14h
end;

function XOldActivatePort;assembler;
asm
  mov  ah,4
  mov  dx,port
  int  14h
  cmp  ax,1954h
  jne  @Shit
  mov  al,1
  jmp  @Exit
@Shit:
  xor  al,al
@Exit:
end;

function XActivatePort;assembler;
asm
  mov  ah,1ch
  mov  dx,port
  int  14h
  cmp  ax,1954h
  jne  @Shit
  mov  al,1
  jmp  @Exit
@Shit:
  xor  al,al
@Exit:
end;

function XGetPortStatus;assembler;
asm
  mov  ah,3
  mov  dx,port
  int  14h

end;

function XReceiveChar;assembler;
asm
  mov  ah,2
  mov  dx,port
  int  14h
end;

procedure XSendChar;assembler;
asm
  mov ah,1
  mov al,chr
  mov dx,port
  int 14h
end;

procedure XSetCommParams;assembler;
asm
  xor  ah,ah
  mov  al,params
  mov  dx,port
  int  14h
end;

end.