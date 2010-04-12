{
Name    : X/VCPI 1.00a
Purpose : VCPI functions implementation
Coder   : SSG
Date    : 3rd Jan 97
Time    : 02:57

notes:
------
 3rd Jan 97 - 03:03 - Not to code much here... *grin*
}

unit XVCPI;

interface

type

  PWORD = record
    Offs : longint;
    Seg  : word;
  end;

  TVCPIDebugRegs = record
    DR0,DR1,DR2,DR3,DR4,DR5,DR6,DR7 : longint;
  end;

  TVCPIParams = record
    CR3       : longint;
    GDTRPtr   : longint;
    IDTRPtr   : longint;
    LDTR      : word;
    TR        : word;
    Entry     : PWORD;
  end;

function  XVCPIOK:boolean;
procedure XVCPIGetPMI(var pagetable,gdt; var unusedentry:word; var entrypoint:longint);
function  XVCPIGetMaxPage:longint;
function  XVCPIGetFreePages:longint;
function  XVCPIAllocatePage:longint;
function  XVCPIGetPageAddr(page:word):longint;
function  XVCPIGetCR0:longint;
function  XVCPIVersion:word;
procedure XVCPIGet8259Vectors(var master,slave:word);
procedure XVCPISet8259Vectors(master,slave:word);
procedure XVCPIGetDebugRegs(var regs:TVCPIDebugRegs);
procedure XVCPISetDebugRegs(var regs:TVCPIDebugRegs);
procedure XVCPIFreePage(page:longint);
procedure XVCPISwitchProtectedMode(var params:TVCPIParams);

implementation

procedure XVCPISwitchProtectedMode;assembler;
asm
  mov  ax,0de0ch
  db   66h
  xor  di,di
  les  di,params
  db   66h
  xor  ax,ax
  mov  ax,es
  db   66h
  shl  ax,4
  or   ax,di
  db   66h
  mov  si,ax
  int  67h
end;

procedure XVCPISet8259Vectors;assembler;
asm
  mov  ax,0de0bh
  mov  bx,master
  mov  cx,slave
  int  67h
end;

procedure XVCPIGet8259Vectors;assembler;
asm
  mov  ax,0de0ah
  int  67h
  les  di,master
  mov  es:[di],bx
  les  di,slave
  mov  es:[di],cx
end;

procedure XVCPISetDebugRegs;assembler;
asm
  mov  ax,0de09h
  les  di,regs
  int  67h
end;

procedure XVCPIGetDebugRegs;assembler;
asm
  mov  ax,0de08h
  les  di,regs
  int  67h
end;

function XVCPIGetCR0;assembler;
asm
  mov  ax,0de07h
  int  67h
  mov  ax,bx
  db   66h
  shr  bx,16
  mov  dx,bx
end;

function XVCPIPageAddr;assembler;
asm
  mov  ax,0de06h
  mov  cx,page
  int  67h
  mov  ax,dx
  db   66h
  shr  dx,16
end;

procedure XVCPIFreePage;assembler;
asm
  mov  ax,0de05h
  mov  dx,word ptr page
  db   66h
  shl  dx,16
  mov  dx,word ptr page+2
  int  67h
end;

function XVCPIAllocatePage;assembler;
asm
  mov  ax,0de04h
  int  67h
  mov  ax,dx
  db   66h
  shr  dx,16
end;

function XVCPIGetFreePages;assembler;
asm
  mov  ax,0de03h
  int  67h
  mov  ax,dx
  db   66h
  shr  dx,16
end;

function XVCPIGetMaxPage;assembler;
asm
  mov  ax,0de02h
  int  67h
  mov  ax,dx
  db   66h
  shr  dx,16
end;

procedure XVCPIGetPMI(var pagetable,gdt; var unusedentry:word; var entrypoint:longint);assembler;
asm
  cld
  push ds
  mov  ax,0de01h
  les  di,pagetable
  lds  si,gdt
  int  67h
  pop  ds
  mov  ax,di
  les  di,unusedentry
  stosw
  les  di,entrypoint
  mov  ax,bx
  stosw
  db 66h
  shr  bx,16
  stosw
end;

function XVCPIVersion;assembler;
asm
  mov  ax,0de00h
  int  67h
  mov  ax,bx
end;

function XVCPIOK;assembler;
asm
  mov  ax,0de00h
  int  67h
  xor  al,al
  or   ah,ah
  jne  @end
  inc  al
@end:
end;

end.