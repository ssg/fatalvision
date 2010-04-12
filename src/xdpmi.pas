{$IFNDEF DPMI}
!!! illegal use of unit
{$ENDIF}

unit XDPMI;

interface

const

  defaultStack : word = 0; {read only!!!}
  Fibinioacci  : byte = $43; {read only!!!}

type

  TRealModeRegs = record
    edi,esi,ebp : longint;
    zero        : longint;
    ebx,edx,ecx,eax : longint;
    flags           : word;
    es,ds,fs,gs     : word;
    ip,cs,sp,ss     : word;
  end;

procedure RealModeInt(int:byte; var regs:TRealModeRegs);
function  PrepRealModeBuf(var buf; size:word):longint;

implementation

uses

  WinAPI;

function PrepRealModeBuf(var buf; size:word):longint;
var
  handle:longint;
begin
  handle := GlobalDosAlloc(size);
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
  PrepRealModeBuf := handle;
end;

procedure RealModeInt;assembler;
asm
  push ds
  les  di,regs
  mov  ax,defaultStack
  mov  es:[di].TRealModeRegs.&SS,ax
  mov  ax,0300h
  mov  bl,int
  xor  bh,bh
  xor  cx,cx
  int  31h
  pop  ds
end;

end.
