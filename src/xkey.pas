{
Name    : X/Key 1.00c
Purpose : Keyboard low level procs
Coder   : SSG
Date    : 22nd Dec 96
Time    : 03:53

updates:
--------
25th Dec 96 - 02:25 - a perfect key event grabber added...
 3rd Mar 97 - 15:51 - added game mode...
}

unit XKey;

interface

uses

  Drivers;

procedure MaxTypematicRate;
procedure ClearKeyBuffer;
procedure GetExtendedKeyEvent(var Event); {supports extended keyboard}

procedure InitGameMode;
procedure DoneGameMode;

var

  Pressed : array[0..255] of boolean;

implementation

uses Dos;

const

  SaveInt09 : Pointer = NIL;

procedure KeybHandler; interrupt;
begin
  asm
    xor ax, ax
    in al, 60h

    mov di, ax
    and di, 0FF7Fh
    mov bx, 7
  end;

  inline(
    $0F/$A3/$D8/                 (* cf=bit 7 *)
    $D6                          (* if cf=0, al=0. if cf=1, al=0FFh *)
  );

  asm
    not al
    lea bx, Pressed
    mov [bx+di], al

    mov al, 020h
    out 020h, al
  end;
end;

procedure InitGameMode;
begin
  asm
    cld
    mov ax,ds
    mov es,ax
    mov cx,128
    lea di,Pressed
    xor ax,ax
    rep stosw
  end;
  GetIntVec($9,SaveInt09);
  SetIntVec($9,@KeybHandler);
end;

procedure DoneGameMode;
begin
  if SaveInt09 <> NIL then SetIntVec($9, SaveInt09);
end;

procedure GetExtendedKeyEvent;assembler;
asm
  les  di,Event
  mov  ah,11h
  int  16h
  jnz  @keywar
  mov  bx,evNothing
  jmp  @end
@keywar:
  mov  ah,10h
  int  16h
  mov  bx,evKeyDown
  cmp  ah,$e0
  jne  @check
  cmp  al,$0d
  jne  @check2
  mov  ah,$1c
  jmp  @end
@check2:
  cmp  al,$2f
  jne  @end
  mov  ah,$35
  jmp  @end
@check:
  cmp  al,$e0
  jne  @end
  xor  al,al
@end:
  mov  es:[di].TEvent.What,bx
  mov  es:[di].TEvent.KeyCode,ax
end;

procedure ClearKeyBuffer;assembler;
asm
@Loop:
  mov ah,1
  int 16h
  jz  @Exit
  xor ax,ax
  int 16h
  jmp @Loop
@Exit:
end;

procedure MaxTypematicRate;assembler;
asm
  mov ax,305h
  xor bx,bx
  int 16h
end;

end.