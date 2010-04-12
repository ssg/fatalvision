{
Name        : EyeBalls 1.0d
Purpose     : Special effects for TXSys
Date        : 31st Jun 1993
Coder       : SSG

Update Info:
------------
31st Jun 93 - 22:25 - Added TDevil and recovered a bug in TEye..
05th Jul 93 - 22:45 - Mission : Local Mouse Hide while UpDating...
05th Jul 93 - 22:50 - Mission aborted... Because there is no difference
                      while hiding in paintbegin and showing it before
                      xputvifs with
                      hiding it and showing it in paintend there is
                      no necessary to do it...
23rd Oct 93 - 16:50 - Re-arranged the source...
02nd May 94 - 17:50 - *** Fixed some bugs...
}

unit EyeBalls;

interface

uses
XTypes,
GDrivers,
Objects,
GView;

type

  PEye = ^TEye;
  TEye = object(TView)
    Eye         : TPoint;
    VIFXSize    : integer;
    VIFYSize    : integer;
    constructor Init(APoint:TPoint);
    procedure   Paint;virtual;
    procedure   BackProcess;virtual;
  end;

implementation

const

  Black = Rid_EyeBlack;
  White = Rid_EyeWhite;

{********************************** EYE ****************************}
constructor TEye.Init(APoint:TPoint);
var
  R:TRect;
  P:PVIFMap;
begin
  P:= GetImagePtr(White);
  R.A:=APoint;
  R.B.X:=R.A.X+P^.XSize-1;
  R.B.Y:=R.A.Y+P^.YSize-1;
  TView.Init(R);
  P:= GetImagePtr(Black);
  VIFXSize  := P^.XSize;
  VIFYSize  := P^.YSize;
  Eye.X     := Size.X div 2;
  Eye.Y     := Size.Y div 2;
  Options   := 0;
  EventMask := 0;
end;

procedure TEye.Paint;
begin
  PaintBegin;
    XPutImage(0,0,White);
    XPutImage(Eye.X,Eye.Y,Black);
  PaintEnd;
end;

procedure TEye.BackProcess;
var
  sx:word;
  Old:TPoint;
begin
  Old:=Eye;
  Eye.X:=Mouse_GetX;
  Eye.Y:=Mouse_GetY;
  sx:=VIFXSize;
  MakeLocal(Eye,Eye);
  if Eye.X>Size.X-sx then Eye.X:=Size.X-sx;
  if Eye.Y>Size.Y-sx then Eye.Y:=Size.Y-sx;
  if Eye.X<0 then Eye.X:=0;
  if Eye.Y<0 then Eye.Y:=0;
  if (Old.X<>Eye.X) or (Old.Y<>Eye.Y) then Paint;
end;

end.
