{
Name    : X/IEX v1.00a
Purpose : IBM/MS disk Extensions
Coder   : SSG
Date    : 27th Jun 96
Time    : 16:26
}

unit Xiex;

interface

const

  iexSupportDiskAccess = 1;
  iexSupportRemovable  = 2;
  iexValidXDPT         = 4;

  iexOK                = 0;

  iwfVerify            = 1;


type

  TDAP = record {disk address packet}
    Size     : byte; {10h}
    Reserved : byte;
    Blocks   : word;
    Buffer   : pointer;
    Start    : comp;
  end;

  TDPB = record {drive parameters buffer}
    Size    : word; {1ah}
    Flags   : word;
    Cyls    : longint;
    Heads   : longint;
    SPT     : longint;
    Total   : comp;
    BPS     : word;
  end;

function IEXInstalled:boolean;
function IEXVersion:byte;
function IEXSupport:word;
function IEXRead(drive:byte; var dap:TDAP):byte;
function IEXWrite(drive:byte; var dap:TDAP; verify:boolean):byte;
function IEXVerify(drive:byte; var dap:TDAP):byte;
function IEXLock(drive:byte):byte;
function IEXUnLock(drive:byte):byte;
function IEXIsLocked(drive:byte):boolean;
function IEXEject(drive:byte):byte;
function IEXSeek(drive:byte; var dap:TDAP):byte;
function IEXGetDPT(drive:byte; var dpb:TDPB):byte;
function IEXChange(drive:byte):boolean;

implementation

{--- IEX functions begin ---}
function IEXChange;assembler;
asm
  mov  ah,49h
  mov  dl,drive
  int  13h
  mov  al,ah
end;

function IEXGetDPT;assembler;
asm
  mov  ah,48h
  mov  dl,drive
  push ds
  lds  si,dpb
  mov  [si].TDPB.Size,001ah
  int  13h
  pop  ds
  mov  al,ah
end;

function IEXSeek;assembler;
asm
  mov  ah,47h
  mov  dl,drive
  push ds
  lds  si,dap
  int  13h
  mov  al,ah
  pop  ds
end;

function IEXEject;assembler;
asm
  mov  ah,46h
  xor  al,al
  mov  dl,drive
  int  13h
  mov  al,ah
end;

function IEXLock;assembler;
asm
  mov  ah,45h
  xor  al,al
  mov  dl,drive
  int  13h
  mov  al,ah
end;

function IEXIsLocked;assembler;
asm
  mov  ah,45h
  mov  al,2
  mov  dl,drive
  int  13h
end;

function IEXUnLock;assembler;
asm
  mov  ah,45h
  mov  al,1
  mov  dl,drive
  int  13h
  mov  al,ah
end;

function IEXVerify;assembler;
asm
  mov  ah,44h
  mov  dl,drive
  push ds
  lds  si,dap
  int  13h
  mov  al,ah
  pop  ds
end;

function IEXWrite;assembler;
asm
  mov  ah,43h
  mov  al,verify
  mov  dl,drive
  push ds
  lds  si,dap
  int  13h
  mov  al,ah
  pop  ds
end;

function IEXRead;assembler;
asm
  mov  ah,42h
  mov  dl,drive
  push ds
  lds  si,dap
  int  13h
  mov  al,ah
  pop  ds
end;

function IEXInstalled;assembler;
asm
  mov ah,41h
  mov bx,55aah
  int 13h
  mov ax,0
  jc  @skip
  inc ax
@skip:
end;

function IEXVersion;assembler;
asm
  mov ah,41h
  mov bx,55aah
  int 13h
  mov al,ah
end;

function IEXSupport;assembler;
asm
  mov ah,41h
  mov bx,55aah
  int 13h
  mov ax,cx
end;

end.