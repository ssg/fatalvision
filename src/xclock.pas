{
Name            : XClock 1.2b
Purpose         : Simple analog clock
Date            : - not specific -
Coder           : SSG & Wiseman

Update info:
------------
 6th Sep 94 - 02:24 - Enhanced and cleaned from bugs...
 6th Sep 94 - 05:14 - Re-enhanced and re-debugged...
}

unit XClock;

interface

uses

XBuf,Dos,Graph,Drivers,GView,GDrivers,Objects,Debris,XTypes,Tools;

const

  piboluiki = Pi/2;
  ikipi     = 2*Pi;

  Col_ClockBack   : byte = cBlue;
  Col_ClockCircle : byte = cWhite;
  Col_ClockStick  : byte = cWhite;
  Col_ClockText   : byte = cLightGreen;

  Ctx_Clock       : word = hcNoContext;

type

 PClock = ^TClock;
 TClock = object(TView)
  Cl          : array[1..4] of Word;
  constructor Init(var ABounds : TRect);
  procedure   HandleEvent(var Event:TEvent);virtual;
  procedure   Paint;virtual;
  procedure   BackProcess;Virtual;
  procedure   UpdateTime;
  procedure   PaintSecond(newsec:word);
 end;

 PClockDialog = ^TClockDialog;
 TClockDialog = object(TWindow)
   procedure  InitFrame(var R:TRect);virtual;
 end;

implementation

constructor TClock.Init;
begin
  inherited Init(ABounds);
  UpdateTime;
  HelpContext := Ctx_Clock;
  Options := Options or Ocf_PreProcess or Ocf_FullDrag or Ocf_Move;
  EventMask := evMouseDown;
end;

procedure TClock.HandleEvent(var Event:TEvent);
var
  R,R1:TRect;
begin
  Owner^.GetVisibleBounds(R);
  GetBounds(R1);
  if R1.Equals(R) then exit;
  Drag(Event,dmDragMove);
end;

procedure TClock.UpdateTime;
begin
  GetTime(cl[1],cl[2],cl[3],cl[4]);
end;

procedure TClock.Paint;
var
  R         : TRect;
  Xr,Yr     : Integer;
  s         : string;
  x,y       : integer;
  fw        : word;

  procedure GetTimeCoords(Time:Word;Units:Byte;var x,y:integer);
  var
    division:longint;
    n : byte;
  begin
     case Units of
       1:division := 12;
       2:division := 60;
       3:division := 60;
     end;
     Time := Time mod division;
     X:=Round(-Cos(piboluiki+Time*(ikipi/division))*Xr*Units/2)+Xr;
     Y:=Round(-Sin(piboluiki+Time*(ikipi/division))*Yr*Units/2)+Yr;
  end;

  procedure PaintAnalog;
  var
    n:byte;
    x,y:integer;
  begin
    SetLineStyle(SolidLn,0,ThickWidth);
    SetColor(Col_ClockStick);
    for n := 1 to 2 do begin
      GetTimeCoords(cl[n],n,x,y);
      XLine(x,y,xr,yr);
    end;
    SetLineStyle(SolidLn,0,NormWidth);
  end;

begin
  PaintBegin;
  GetExtent(R);
  SetFillStyle(SolidFill,Col_ClockBack);
  SetColor(Col_ClockCircle);
  Yr:=Size.Y div 2;
  Xr:=Size.X div 2;
  XBox(R,True);
  XCircle(R);
  PaintAnalog;
  s := Word2Str(cl[1],2)+':'+Word2Str(cl[2],2);
  fw := GetStringSize(3,s);
  SetTextColor(Col_ClockText,Col_ClockBack);
  XPrintOredStr(Xr-(fw div 2),Yr-(GetFontHeight(3) div 2),fw,3,S);
{  SetColor(cBlack);
  PaintSecond(CL[3]);}
  PaintEnd;
end;

procedure TClock.PaintSecond(newsec:word);
var
  x,y,xr,yr:integer;
  time:word;
begin
  SetLineStyle(SolidLn,0,NormWidth);
  xr   := Size.X div 2;
  yr   := Size.Y div 2;
  time := newsec mod 60;
  X:=Round(-Cos(piboluiki+Time*(ikipi/60))*Xr)+Xr;
  Y:=Round(-Sin(piboluiki+Time*(ikipi/60))*Yr)+Yr;
  XLine(xr,yr,x,y);
end;

procedure TClock.BackProcess;
var
  Car:Array[1..4] of word;
begin
  GetTime(Car[1],Car[2],Car[3],Car[4]);
  if not BufCmp(Car,CL,2*2) then begin
    UpdateTime;
    PaintView;
  end;{ else if Car[3] <> CL[3] then begin
    PaintBegin;
    SetColor(Col_ClockBack);
    SetWriteMode(XorPut);
    PaintSecond(CL[3]);
    UpdateTime;
    PaintSecond(CL[3]);
    SetWriteMode(NormalPut);
    PaintEnd;
  end; }
end;

(************************ TClockWindow Procs *****************************)

procedure TClockDialog.InitFrame;
begin
  Frame := New(PClock,Init(R));
end;

end.
