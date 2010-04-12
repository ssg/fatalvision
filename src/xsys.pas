{
Name    : X/Sys 1.00a
Purpose : base system procs
Coder   : SSG
Date    : 22nd Dec 96
Time    : 04:04
}

unit XSys;

interface

procedure Error(Source,ErrStr:string);      {Error abort}
procedure SetSystem(AConfig:Longint;Enable:Boolean);  {Set system config}
function  GetSystem(AConfig:Longint):boolean;         {Get system config}

implementation

uses XTypes;

const

  SystemFlag : Longint = Sys_SoundsActive or
                         Sys_BackProcess or
                         Sys_CycleEffect or
                         Sys_ZoomEffect;

procedure SetSystem(AConfig:Longint;Enable:Boolean);
begin
  if Enable then SystemFlag := SystemFlag or AConfig
            else SystemFlag := SystemFlag and not AConfig;
end;

function GetSystem(AConfig:Longint):boolean;
begin
  GetSystem := SystemFlag and AConfig > 0;
end;

procedure Error;
  procedure outstrfalan(const s:string);assembler;
  asm
    push ds
    lds  si,s
    mov  cl,[si]
    xor  ch,ch
    inc  si
    cld
    mov  ah,0eh
    xor  bx,bx
  @loop:
    lodsb
    int  10h
    loop @loop
    pop  ds
  end;
begin
  asm
    mov ax,3
    int 10h
  end;
  if (source <> '') then outstrfalan(Source+': '+ErrStr+#13#10);
  Halt(1);
end;

end.