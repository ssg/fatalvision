{
Name    : X/Dev 1.00b
Purpose : FatalVision device layer
Coder   : SSG
Date    : 22nd Dec 96
Time    : 02:37
}

unit XDev;

interface

uses

  Drivers,XMouse,Objects;

const

  pdfSelfPainting = 1; {pointing device paints its shape on screen itself}

type

  PPointingDevice = ^TPointingDevice;
  TPointingDevice = object(TObject)
    Flags         : word;
    constructor Init;
    destructor Done;virtual;
    procedure Hide;virtual;
    procedure Show;virtual;
    function  GetButtonStatus:word;virtual;
    procedure SetPosition(x,y:integer);virtual;
    procedure GetPosition(var T:TPoint);virtual;
    procedure SetShape(whatlike,resourceid:word);virtual;
    procedure EnableEvents;virtual;
    procedure DisableEvents;virtual;
    procedure Paint;virtual;
    procedure GetEvent(var Event:TEvent);virtual;
  end;

  PDumbPointingDevice = ^TDumbPointingDevice;
  TDumbPointingDevice = object(TPointingDevice)
    XPos,YPos         : integer;
    procedure SetPosition(x,y:integer);virtual;
    procedure GetPosition(var T:TPoint);virtual;
  end;

  PMouse = ^TMouse;
  TMouse = object(TPointingDevice)
    constructor Init;
    procedure Hide;virtual;
    procedure Show;virtual;
    function  GetButtonStatus:word;virtual;
    procedure SetPosition(x,y:integer);virtual;
    procedure GetPosition(var T:TPoint);virtual;
    procedure SetShape(whatlike,resourceid:word);virtual;
    procedure EnableEvents;virtual;
    procedure DisableEvents;virtual;
    procedure GetEvent(var Event:TEvent);virtual;
  end;

const

  silArrow = 0; {standard arrow shape}
  silBusy  = 1; {a hour glass}
  silDrag  = 2; {a hand?}

  pdDumb       = 0;
  pdMouse      = 1;
  pdCrossHair  = 2;

  PointingDevice : PPointingDevice = NIL;

procedure EventWait;
procedure EventReady;

procedure Mouse_DefineCursor(hx,hy:word; var bitmap);

implementation

uses

{$ifdef dpmi}
WinAPI,XDPMI,
{$endif}

XBuf,XGfx,Graph,XSys,AXEServ,XTypes;

const

  LastMouse        : word = Rid_Arrow;
  CurrentMouse     : word = Rid_Arrow;

procedure EventWait;
begin
  if CurrentMouse <> Rid_HourGlass then LastMouse := CurrentMouse;
  PointingDevice^.Hide;
  PointingDevice^.SetShape(silBusy,rid_HourGlass);
  CurrentMouse := Rid_HourGlass;
  PointingDevice^.Show;
  SetSystem(Sys_Busy,True);
end;

procedure EventReady;
begin
  PointingDevice^.Hide;
  PointingDevice^.SetShape(silArrow,LastMouse);
  PointingDevice^.Show;
  SetSystem(Sys_Busy,False);
end;

{- TPointingDevice -}
constructor TPointingDevice.Init;
begin
  inherited Init;
  EnableEvents;
end;

destructor TPointingDevice.Done;
begin
  DisableEvents;
  inherited Done;
end;

procedure TPointingDevice.Hide;
begin
end;

procedure TPointingDevice.Show;
begin
end;

function  TPointingDevice.GetButtonStatus:word;
begin
  GetButtonStatus := 0;
end;

procedure TPointingDevice.SetPosition;
begin
end;

procedure TPointingDevice.GetPosition(var T:TPoint);
begin
end;

procedure TPointingDevice.SetShape(whatlike,resourceid:word);
begin
end;

procedure TPointingDevice.EnableEvents;
begin
end;

procedure TPointingDevice.DisableEvents;
begin
end;

procedure TPointingDevice.Paint;
begin
end;

procedure TPointingDevice.GetEvent(var Event:TEvent);
begin
  Event.What := evNothing;
end;

{=== MOUSE DERIVED POINTING DEVICES SECTION ===}

procedure Mouse_SetHandler(mask:word; handler:pointer);assembler;
asm
  mov  ax,0ch
  mov  cx,mask
  les  dx,handler
  int  33h
end;

{$ifdef dpmi}
procedure Mouse_DefineCursor(hx,hy:word; var bitmap);
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
procedure Mouse_DefineCursor(hx,hy:word; var bitmap);assembler;
asm
  mov  ax,9
  mov  bx,hx
  mov  cx,hy
  les  dx,bitmap
  int  33h
end;
{$endif}

function Mouse_Init:boolean;assembler;
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

type

  TMouseEvent = record
    Action    : word;
    Buttons   : word;
    X,Y       : word;
    Double    : boolean;
  end;

const

  MouseEventBufferSize = 100;

var

  MouseEventBuffer : array[0..MouseEventBufferSize-1] of TMouseEvent;

const

  LastReleasedTime : Word = 0;
  LastRelX         : integer = 0;
  LastRelY         : integer = 0;
  MouseBufStart    : Word    = Ofs(MouseEventBuffer);
  MouseBufEnd      : Word    = Ofs(MouseEventBuffer) + SizeOf(MouseEventBuffer);
  MouseBufHead     : Word    = Ofs(MouseEventBuffer);
  MouseBufTail     : Word    = Ofs(MouseEventBuffer);
  DoubleDelay      : word = 8;  {8 is the best, trust SSG}

function GetLastMouseEvent(var Event:TMouseEvent):Boolean; assembler;
asm
  cld
  xor     ax,ax
  les     di,Event
  mov     cx,Type TMouseEvent
@Retry:
  mov     si,MouseBufTail
  cmp     si,MouseBufHead
  jz      @Esc
  add     si,cx
  cmp     si,MouseBufEnd
  jb      @1                {bufend: set ptr to start}
  mov     si,MouseBufStart
@1:            mov     MouseBufTail,si   {normal}
  cmp     si,MouseBufHead   {is there any next event?}
  je      @Ok
  mov     dx,ds:[si].TMouseEvent.Action
  cmp     dx,mmMove
  jne     @Ok
  cmp     dx,ds:[si+Type TMouseEvent].TMouseEvent.Action
  jne     @Ok
  mov     dx,ds:[si].TMouseEvent.Buttons
  cmp     dx,ds:[si+Type TMouseEvent].TMouseEvent.Buttons
  je      @Retry
@Ok:
  repz    movsb
  inc     ax
@Esc:
end;

procedure Mouse_UserHandler; far; assembler;
asm
  push    ds
  push    es
  push    ax

  mov     si,seg @DATA
  mov     ds,si
  mov     es,si
  cld
  mov     di,MouseBufHead
  add     di,Type TMouseEvent
  cmp     di,MouseBufEnd
  jb      @1
  mov     di,MouseBufStart
@1:            cmp     di,MouseBufTail
  jnz     @2
  pop     ax
  jmp     @Esc
@2:            mov     MouseBufHead,di
  stosw
  mov     ax,bx {buttons}
  stosw
  mov     ax,cx {x}
  stosw
  mov     ax,dx {y}
  stosw

  pop     cx
  xor     al,al
  test    cx,mmLBReleased + mmRBReleased
  jz      @4
  or      bx,bx
  jnz     @4
  push    es
  xor     al,al
  mov     cx,$40
  mov     es,cx
  mov     si,$6C
  mov     cx,es:[si]
  mov     dx,cx
  xchg    dx,LastReleasedTime
  sub     cx,dx
  cmp     cx,DoubleDelay
  ja      @3
  inc     al
@3:
  pop     es
@4:
  stosb
@Esc:
  pop     es
  pop     ds
@Exit:
end;

{- TMouse -}
constructor Tmouse.Init;
begin
  inherited Init;
  LastReleasedTime := XTimer^;
end;

procedure TMouse.GetEvent;
var
  T : TMouseEvent;
begin
  Event.What := evNothing;
  if GetLastMouseEvent(T) then begin
    if T.Action and (mmLBPressed or mmRBPressed) > 0 then Event.What := evMouseDown
    else if T.Action and (mmLBReleased or mmRBReleased) > 0 then Event.What := evMouseUp
    else if (T.Action and mmMove > 0) then
      Event.What := evMouseMove else exit;
    Event.Buttons := T.Buttons;
    Event.Where.X := T.X;
    Event.Where.Y := T.Y;
    Event.Double  := T.Double;
    if Event.What = evMouseUp then begin
      if (abs(LastRelX-T.X) > 4) or (abs(LastRelY-T.Y) > 4) then
        Event.Double := false;
      LastRelX := T.X;
      LastRelY := T.Y;
    end;
    if Event.Double then LastReleasedTime := 0;
  end;
end;

procedure TMouse.EnableEvents;
begin
  Mouse_SetHandler(mbMaskAll,@Mouse_UserHandler);
end;

procedure Tmouse.DisableEvents;
const
  NullPtr : pointer = NIL;
begin
  Mouse_SetHandler(0,NullPtr);
end;

procedure TMouse.Hide;assembler;
asm
  mov  ax,2
  int  33h
end;

procedure TMouse.Show;assembler;
asm
  mov  ax,1
  int  33h
end;

function TMouse.GetButtonStatus;assembler;
asm
  mov  ax,3
  int  33h
  mov  ax,bx
end;

procedure TMouse.SetPosition;assembler;
asm
  mov  ax,4
  mov  cx,x
  mov  dx,y
  int  33h
end;

procedure TMouse.GetPosition;assembler;
asm
  mov  ax,3
  int  33h
  les  di,T
  mov  es:[di].TPoint.X,cx
  mov  es:[di].TPoint.Y,dx
end;

procedure TMouse.SetShape;
var
  P:PMIF;
begin
  if AXEOK then begin
    P := GetRscById(rtMouse,resourceid);
    if P <> NIL then begin
      Mouse_DefineCursor(P^.HX,P^.HY,P^.Bitmap);
      CurrentMouse := resourceid;
    end;
  end;
end;

{- TDumbPointingDevice -}
procedure TDumbPointingDevice.SetPosition(x,y:integer);
begin
  XPos := x;
  YPos := y;
end;

procedure TDumbPointingDevice.GetPosition(var T:TPoint);
begin
  T.X := XPos;
  T.Y := YPos;
end;

const

  OldExitProc : pointer = NIL;

procedure DoneXDev;
begin
  if PointingDevice <> NIL then begin
    Dispose(PointingDevice,Done);
    PointingDevice := NIL;
  end;
  ExitProc := OldExitProc;
end;

begin
  OldExitProc := ExitProc;
  ExitProc := @DoneXDev;
end.