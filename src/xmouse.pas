{
Name    : X/Mouse 1.00a
Purpose : Rewritten mouse interface routines
Coder   : SSG
Date    : 27th Jun 96
Time    : 17:40

updates:
--------
27th Jun 96 - 17:40 - started...
27th Jun 96 - 18:38 - finished...
 2nd Jul 96 - 20:12 - fixed a bug...
}

unit XMouse;

interface

uses

  XTypes,Objects;

function Mouse_Init:boolean;
function Mouse_GetX:integer;
function Mouse_GetY:integer;
function Mouse_GetButtons:integer;
procedure Mouse_SetPos(x,y:integer);
procedure Mouse_GetPos(var T:TPoint);
procedure Mouse_GetState(var x,y,buttons:integer);
procedure Mouse_Hide;
procedure Mouse_Show;
procedure Mouse_DefineCursor(hx,hy:integer; var bitmap);
procedure Mouse_SetHandler(mask:word; handler:pointer);

implementation

{$ifdef dpmi}
uses WinAPI,XDPMI,XBuf;
{$endif}


procedure Mouse_GetPos;
var
  temp:integer;
begin
  Mouse_GetState(T.X,T.Y,temp);
end;

procedure Mouse_SetHandler;assembler;
asm
  mov  ax,0ch
  mov  cx,mask
  les  dx,handler
  int  33h
end;

{$ifdef dpmi}
procedure Mouse_DefineCursor;
var
  regs:TRealModeRegs;
  handle:longint;
begin
  handle := GlobalDosAlloc(SizeOf(bitmap));
  asm
    push ds
    mov  cx,type TMouseBitmap
    cld
    xor  di,di
    mov  ax,word ptr handle
    mov  es,ax
    lds  si,bitmap
    rep  movsb
    pop  ds
  end;
  ClearBuf(regs,SizeOf(regs));
  with regs do begin
    ebx := hx;
    ecx := hy;
    eax := 9;
    es  := Longrec(handle).hi;
  end;
  asm cli end;
  RealModeInt($33,regs);
  asm sti end;
  GlobalDosFree(handle);
end;
{$else}
procedure Mouse_DefineCursor;assembler;
asm
  mov  ax,9
  mov  bx,hx
  mov  cx,hy
  les  dx,bitmap
  int  33h
end;
{$endif}

procedure Mouse_SetPos;assembler;
asm
  mov  ax,4
  mov  cx,x
  mov  dx,y
  int  33h
end;



function Mouse_GetButtons;assembler;
asm
  mov  ax,3
  int  33h
  mov  ax,bx
end;

function Mouse_GetX;assembler;
asm
  mov  ax,3
  int  33h
  mov  ax,cx
end;

function Mouse_GetY;assembler;
asm
  mov  ax,3
  int  33h
  mov  ax,dx
end;

procedure Mouse_GetState;assembler;
asm
  mov  ax,3
  int  33h
  les  di,buttons
  mov  es:[di],bx
  les  di,x
  mov  es:[di],cx
  les  di,y
  mov  es:[di],dx
end;

procedure Mouse_Show;assembler;
asm
  mov  ax,1
  int  33h
end;

procedure Mouse_Hide;assembler;
asm
  mov  ax,2
  int  33h
end;

function Mouse_Init;assembler;
asm
  mov  ax,3533h
  int  21h
  mov  ax,es
  or   ax,bx
  jz   @exit
  xor  ax,ax
  int  33h
@exit:
end;

end.