{
Name            : XCrt 1.0c
Purpose         : Simple CRT window to provide text mode emulation
Coder           : SSG
Date            : 24th Sep 93

Update Info:
------------
25th Sep 93 - 01:17 - I must sleep... it's working... in just three hours...
26th Sep 93 - 03:45 - It's multitasking...
14th Oct 93 - 21:50 - XWrite cursor adjustments...
03rd Dec 93 - 00:40 - Private variables added...
}

{$I-}

unit XCrt;

interface

uses

XTypes,
Objects,
GView,
Debris,
Drivers,
XGfx;

type

  PByte = ^byte;

  PCRTScreen = ^TCRTScreen;
  TCRTScreen = array[1..256] of string[80];

  PCRT = ^TCRT;
  TCRT = object(TView)
    XSize       : Byte;
    YSize       : Byte;
    WhereX      : Byte;
    WhereY      : Byte;
    Destination : PString;
    ReadStr     : PString;
    Screen      : PCRTScreen;

    constructor Init(x,y:integer;AXSize,AYSize,FC,BC:byte); {fc = fore , bc = back}
    destructor  Done;virtual;
    procedure   Paint;virtual;
    procedure   SetState(AState:Word; Enable:Boolean); virtual;

    procedure   ScrollUp(ADelta:Byte);

    procedure   AdvanceCursor;
    procedure   BackSpaceCursor;
    procedure   GotoXY(ax,ay:byte);
    procedure   Write(s:string);
    procedure   WriteLn(s:string);
    procedure   ClrScr;
    procedure   ClrEol;

    private

    ForeColor   : Byte;
    BackColor   : Byte;
    FontHeight  : Word;
    FontWidth   : Word;
    procedure   ClearLine(n:byte);
    procedure   RefreshRegion(StartX,StartY,EndX,EndY:byte);
    procedure   PaintCursor;
    procedure   XWrite(s:string;nl:boolean);
  end;

implementation

{*********************************** TCRT ********************************}
constructor TCRT.Init(x,y:integer;AXSize,AYSize,FC,BC:Byte);
var
  R:TRect;
  n:byte;
  P:PByte;
begin
  R.A.X := x;
  R.A.Y := y;
  R.B.X := R.A.X + (AXSize-1)*ViewFontWidth - 1;
  R.B.Y := R.A.Y + AYSize*ViewFontHeight - 1;
  TView.Init(R);
  EventMask := 0;
  Options   := Ocf_PaintFast;
  XSize     := AXSize;
  YSize     := AYSize;
  ForeColor := FC;
  BackColor := BC;
  WhereX    := 1;
  WhereY    := 1;
{  State     := State or Scf_CursorVis; }
  FontHeight:= ViewFontHeight;
  FontWidth := ViewFontWidth;
  GetMem(Screen,SizeOf(Screen^[1])*YSize);
  if Screen = NIL then Fail;
  for n := 1 to YSize do ClearLine(n);
end;

destructor TCRT.Done;
begin
  if ReadStr <> NIL then DisposeStr(ReadStr);
  if Screen <> NIL then FreeMem(Screen,SizeOf(Screen^[1])*YSize);
  TView.Done;
end;

procedure TCRT.Paint;
begin
  RefreshRegion(1,1,XSize,YSize);
end;

procedure TCRT.SetState(AState:Word; Enable:Boolean);
    begin
      inherited SetState(AState,Enable);
      if GetState(Scf_Exposed) and (AState and Scf_Focused > 0) then begin
	if Enable then State := State or Scf_CursorVis
		  else State := State and Not Scf_CursorVis;
      end;
    end;

procedure TCRT.RefreshRegion(StartX,StartY,EndX,EndY:byte);
var
  n:byte;
  s:string;
  x:integer;
  procedure SwapVars(var a1,a2:byte);
  var
    t:byte;
  begin
    t:=a1;
    a1:=a2;
    a2:=t;
  end;
begin
  if (Screen = NIL) or (Owner = NIL) then exit;
  PaintBegin;
  if EndX < StartX then SwapVars(StartX,EndX);
  if EndY < StartY then SwapVars(StartY,EndY);
  SetTextColor(ForeColor,BackColor);
  x := (StartX-1)*FontWidth;
  for n:=StartY to EndY do begin
    s := copy(Screen^[n],StartX,EndX-StartX);
    XWriteStr(x,(n-1)*FontHeight,(EndX-StartX)*FontWidth,s);
  end;
  PaintCursor;
  PaintEnd;
end;

procedure TCRT.PaintCursor;
begin
  SetCursor((WhereX-1)*FontWidth,(WhereY-1)*FontHeight);
end;

procedure TCRT.GotoXY(ax,ay:byte);
begin
  WhereX := ax;
  WhereY := ay;
  PaintCursor;
end;

procedure TCRT.ClearLine(n:byte);
var
  P : PBytearray;
begin
  P := @Screen^[n];
  P^[0] := XSize;
  FillChar(P^[1],XSize,#32);
end;

procedure TCRT.ClrScr;
var
  n:byte;
begin
  if Screen = NIL then exit;
  for n:=1 to YSize do ClearLine(n);
  Paint;
  Self.GotoXY(1,1);
end;

procedure TCRT.ClrEol;
var
  s:string;
  ls:byte;
begin
  if Screen = NIL then exit;
  ls := XSize-WhereX;
  FillChar(s,ls,0);
  Byte(s[0]) := ls;
  Move(s[1],Screen^[WhereY][WhereX],ls);
  RefreshRegion(WhereX,WhereY,XSize,WhereY);
end;

procedure TCRT.XWrite(s:string;nl:boolean);
var
  n:byte;
  reg:string;
  buf:string;
  sy:byte;
  eol:byte;
  procedure PutBuffer(x,y:byte;s:string);
  begin
    move(s[1],Screen^[y][x],length(s));
  end;
  procedure ScrollMemoryUp;
  begin
    Move(Screen^[2],Screen^[1],(YSize-1)*SizeOf(Screen^[1]));
    ClearLine(YSize);
  end;
begin
  if Length(s) = 1 then begin
     PutBuffer(WhereX,WhereY,s);
     RefreshRegion(WhereX,WhereY,WhereX+1,WhereY);
     AdvanceCursor;
  end else begin
     reg := s;
     sy := WhereY;
     while reg<>'' do begin
       eol := XSize - WhereX;
       buf := Copy(reg,1,eol);
       PutBuffer(WhereX,WhereY,buf);
       inc(WhereX,length(buf));
       if wherex>=XSize then begin
	 WhereX := 1;
	 inc(WhereY);
	 if WhereY > YSize then begin
	    ScrollMemoryUp;
	    WhereY := YSize;
	 end;
       end;
       System.Delete(reg,1,length(buf));
     end; {while} {what a logic? I don't know really how did I find it..}
     RefreshRegion(1,sy,XSize,WhereY);
  end; {big if}
  PaintCursor;
  if nl then begin
     inc(WhereY);
     WhereX := 1;
     if WhereY > YSize then ScrollUp(1);
  end;
end;

procedure TCRT.Write(s:string);
begin
  XWrite(s,false);
end;

procedure TCRT.WriteLn(s:string);
begin
  XWrite(s,true);
end;

procedure TCRT.ScrollUp(ADelta:Byte);
var
  n:byte;
begin
  Move(Screen^[ADelta+1],Screen^[1],(YSize-ADelta)*SizeOf(Screen^[1]));
  for n:=YSize-ADelta+1 to YSize do ClearLine(n);
  Dec(WhereY,ADelta);
  Paint;
end;

procedure TCRT.AdvanceCursor;
begin
  inc(WhereX);
  if WhereX > XSize then begin
     WhereX := 1;
     inc(WhereY);
     if WhereY > YSize then begin
	ScrollUp(1);
	WhereY := YSize;
     end;
  end;
  PaintCursor;
end;

procedure TCRT.BackSpaceCursor;
begin
  dec(WhereX);
  if WhereX < 1 then begin
     if WhereY > 1 then begin
	WhereX := XSize;
	dec(WhereY);
      end else WhereX := 1;
  end;
  PaintCursor;
end;

end.
