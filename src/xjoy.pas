{
Name    : X/Joy 1.00b
Purpose : Joystick handling routines
Coder   : SSG
Date    : 8th Aug 96
Time    : 11:50
}

unit XJoy;

interface

uses Objects;

const

  JoyButton1 = $10;
  JoyButton2 = $20;
  JoyButton3 = $40;
  JoyButton4 = $80;

function  JoyInit:boolean;
procedure JoyGetPos(var T:TPoint);
procedure Align(var upperleft,lowerright,acenter:TPoint);
function  JoyHoriz:integer;
function  JoyVert:integer;
function  JoyX:integer;
function  JoyY:integer;
function  JoyButtons:integer;

implementation

const

  Center : TPoint = (X:80;Y:40);
  JoyMin : TPoint = (X:0;Y:0);
  JoyMax : TPoint = (X:0;Y:0);

procedure JoyGetPos;
begin
  T.X := JoyX;
  T.Y := JoyY;
end;

function JoyX;assembler;
asm
  xor  bx,bx
  mov  dx,$201
  mov  al,$ff
  out  dx,al
  mov  cx,32000
@loop:
  in   al,dx
  test al,1
  jz   @break
  inc  bx
  loop @loop
@break:
  mov  ax,bx
end;

function JoyY;assembler;
asm
  xor  bx,bx
  mov  dx,$201
  xor  al,al
  out  dx,al
  mov  cx,32000
@loop:
  in   al,dx
  test al,2
  jz   @break
  inc  bx
  loop @loop
@break:
  mov  ax,bx
end;

function JoyInit;
begin
  if (JoyButtons = 0) and (JoyX = 32000) and (JoyY = 32000) then JoyInit := false else begin
    Center.X := JoyX;
    Center.Y := JoyY;
    JoyInit := true;
  end;
end;

function JoyButtons;assembler;
asm
  mov  dx,$201
  in   al,dx
  not  al
  xor  ah,ah
end;

procedure Align;
begin
  Center := ACenter;
  JoyMin.X := UpperLeft.X;
  JoyMax.X := LowerRight.X;
  JoyMin.Y := UpperLeft.Y;
  JoyMax.Y := LowerRight.Y;
end;

function JoyHoriz;
begin
  JoyHoriz := JoyX-Center.X;
end;

function JoyVert;
begin
  JoyVert := JoyY-Center.Y;
end;

end.