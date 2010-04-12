{
Name    : X/Scroll 1.03d
Purpose : Scroll bars
Date    : 20th Oct 94
Coder   : SSG of course

Update info:
------------
24th Oct 94 - 00:58 - my eyes are burnin'... and with this stiuation
                      i am workin' with these nonsense scrollbars... argh..
29th Oct 94 - 22:54 - workin' on draggings...
30th Oct 94 - 01:43 - finished... (damn! i have a few days to finish
                      this program and my coding is like a turtle's walking)
                      i must finish this before the contest has finished...
 2nd Nov 94 - 17:46 - fixed a minor bug...
 2nd Nov 94 - 17:58 - fixed another minor bug...
19th Nov 94 - 23:41 - moved source to xvision directory...
21st Nov 94 - 01:11 - touched...
26th Nov 94 - 13:34 - fixed some bugs and reduced the code size...
 8th Dec 94 - 01:23 - enhanced and fixed some bugs...
10th Dec 94 - 03:28 - fixed a serious assignment bug...
10th Dec 94 - 17:38 - perfected mouse handles...
13th Dec 94 - 01:04 - changed things...
21st Dec 94 - 22:16 - fixed a little bug...
25th Dec 94 - 23:33 - due to qube's requests, added page scroll...
25th Dec 94 - 23:38 - minor fixes...
26th Dec 94 - 00:22 - touched... (cs=2626)
31st Dec 94 - 00:21 - i think i fixed a bug... (cs=2605)
 6th Mar 96 - 18:06 - fixed a bug in update...
 7th Mar 96 - 12:23 - fixed flickering bug occurs when moving tab...
 7th Mar 96 - 12:24 - added mintabsize...
13th Mar 96 - 17:59 - changed default scrollbar sizes...
21nd Mar 96 - 00:25 - optimized...
}

unit XScroll;

interface

uses

  XDev,Graph,XTypes,GView,XGfx,Objects,Drivers;

const

  Scroll_Dec     = 0;           {scroll bar button types}
  Scroll_Inc     = 1;

  sbButtonSize   = 13;          {scroll bar button size}
  minTabSize     = sbButtonSize div 2; {minimum tab size}

type

  PScrollBar = ^TScrollBar;
  TScrollBar = object(TView)
    Value    : integer;
    Max      : integer;
    Step     : integer;
    PageSize : integer;
    Dragging : boolean;
    constructor Init(var ABounds:TRect);
    procedure   Update(AValue,AMax,AStep,APageSize:integer; Notify:boolean);
    procedure   SetValue(aval:integer; Notify:boolean);
    procedure   Paint;virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   GetButtonBounds(buttype:byte; var R:TRect);virtual;
    procedure   GetDataBounds(var R:TRect);virtual;
    procedure   PaintButtons;virtual;
    procedure   PaintData;virtual;
    procedure   NotifyOwner;virtual;
    function    IsVert:boolean;
  end;

implementation

constructor TScrollBar.Init;
begin
  inherited Init(ABounds);
  Options   := (Options or Ocf_PreProcess or Ocf_PaintFast) and not Ocf_Selectable;
  EventMask := EventMask or evKeyDown or evMouseDown;
  Update(1,1,1,1,False);
end;

procedure TScrollBar.SetValue;
begin
  Update(Aval,Max,Step,PageSize,Notify);
end;

function TScrollBar.IsVert;
begin
  IsVert := Size.Y > Size.X;
end;

procedure TScrollBar.PaintButtons;
var
  R:TRect;
  procedure LeChuck;
  begin
    ShadowBox(R,True);
    R.Grow(-1,-1);
    XBox(R,True);
    R.Grow(-2,-2);
    SetColor(cBlack);
  end;
begin
  SetFillStyle(SolidFill,Col_Back);
  GetButtonBounds(Scroll_Dec,R);
  LeChuck;
  if isVert then Triangle(r.a.x,r.b.y,
                          r.b.x,r.b.y,
                          r.a.x+(r.b.x-r.a.x) div 2,r.a.y)
            else Triangle(r.b.x,r.b.y,
                          r.b.x,r.a.y,
                          r.a.x,r.a.y+(r.b.y-r.a.y) div 2);
  GetButtonBounds(Scroll_Inc,R);
  LeChuck;
  if isVert then Triangle(r.a.x,r.a.y,
                          r.b.x,r.a.y,
                          r.a.x+(r.b.x-r.a.x) div 2,r.b.y)
            else Triangle(r.a.x,r.a.y,
                          r.a.x,r.b.y,
                          r.b.x,r.a.y+(r.b.y-r.a.y) div 2);
end;

procedure TScrollBar.GetDataBounds(var R:TRect);
var
  asize:word;
begin
  GetExtent(R);
  if max = 0 then exit;
  if isVert then begin
    inc(r.a.y,sbButtonSize+2);
    dec(r.b.y,sbButtonSize+1);
    asize := (r.b.y-r.a.y);
    inc(r.a.y,asize*Value div Max);
    r.b.y := r.a.y + (asize*PageSize div Max);
    if (r.b.y-r.a.y) < minTabSize then r.b.y := r.a.y+minTabSize;
    if r.b.y > Size.Y-sbButtonSize-2 then begin
      R.Move(0,Size.Y-sbButtonSize-2-r.b.y);
      {value := max;}
    end;
  end else begin
    inc(r.a.x,sbButtonSize+1);
    dec(r.b.x,sbButtonSize+1);
    asize := (r.b.x-r.a.x);
    inc(r.a.x,asize*Value div Max);
    r.b.x := r.a.x + (asize*PageSize div Max);
    if (r.b.x-r.a.x) < minTabSize then r.b.x := r.a.x+minTabSize;
  end;
  R.Grow(-1,-1);
end;

procedure TScrollBar.PaintData;
var
  R:TRect;
  R2:TRect;
  OldR:TRect;
begin
  SetFillStyle(SolidFill,Col_Back);
  GetExtent(R);
  if not isVert then begin
    inc(r.a.x,sbButtonSize+1);
    dec(r.b.x,sbButtonSize+1);
  end else begin
    inc(r.a.y,sbButtonSize+1);
    dec(r.b.y,sbButtonSize+1);
  end;
  GetDataBounds(R2);
  ShadowBox(R,False);
  R.Grow(-1,-1);
  OldR := R;
  R.B.Y := R2.A.Y-1;
  XBox(R,True);
  R.A.Y := R2.B.Y+1;
  R.B.Y := OldR.B.Y;
  XBox(R,True);
  ShadowBox(R2,true);
  R2.Grow(-1,-1);
  if Dragging then SetFillStyle(solidFill,cWhite);
  XBox(R2,True);
end;

procedure TScrollBar.GetButtonBounds;
begin
  if Size.Y > Size.X then begin
    R.Assign(0,0,Size.X,sbButtonSize);
    if buttype = Scroll_Inc then R.Move(0,Size.Y-sbButtonSize);
  end else begin
    R.Assign(0,0,sbButtonSize,Size.Y);
    if buttype = Scroll_Inc then R.Move(Size.X-sbButtonSize,0);
  end;
end;

procedure TScrollbar.Update;
var
  oldb:TRect;
  R:TRect;
begin
  GetDataBounds(OldB);
  Value    := AValue;
  Max      := AMax;
  Step     := AStep;
  PageSize := APageSize;
  if Value < 0 then Value := 0;
  if Max = 0 then Max := 1;
  if PageSize > Max then PageSize := Max;
  if Value > Max-PageSize then Value := Max-PageSize;
  GetDataBounds(R);
  if not R.Equals(OldB) then begin
    if Notify then NotifyOwner;
    if GetState(Scf_Exposed) then begin
      PaintBegin;
      PaintData;
      PaintEnd;
    end;
  end;
end;

procedure TScrollBar.Paint;
begin
  PaintBegin;
  PaintData;
  PaintButtons;
  PaintEnd;
end;

procedure TScrollBar.NotifyOwner;
begin
  Message(Owner,evBroadcast,Brc_ScrollBarChanged,@Self);
end;

procedure TScrollbar.HandleEvent(var Event:TEvent);
var
  R:TRect;
  Old:TRect;
  Curr:TRect;
  T:TPoint;
  dx,dy:integer;
  mi,ma:integer;
  newvalue:integer;
  l1,l2:longint;
  exito:boolean;
  immed:boolean;
  procedure SubScroll(astep:longint);
  begin
    PointingDevice^.GetEvent(Event);
    MakeLocal(Event.Where,T);
    if Event.Buttons > 0 then SetValue(Value+astep,True);
  end;
  procedure Calc(anotify:boolean);
  begin
    l1 := (curr.a.y-mi);
    l2 := max;
    l1 := l1*l2;
    l2 := ma-mi;
    l1 := l1 div l2;
    newvalue := l1;
    SetValue(newvalue,anotify);
  end;
begin
  if (Event.What = evMouseDown) then begin
    GetButtonBounds(Scroll_Dec,R);
    MakeLocal(Event.Where,T);
    while (Event.Buttons > 0) and
           R.Contains(T) do SubScroll(-Step);
    GetButtonBounds(Scroll_Inc,R);
    while (Event.Buttons > 0) and
          R.Contains(T) do SubScroll(Step);
    GetDataBounds(R);
    if (Event.Buttons > 0) and (T.Y < R.A.Y) then SubScroll(-PageSize);
    if (Event.Buttons > 0) and (T.Y > R.B.Y) then SubScroll(PageSize);
    if R.Contains(T) and (PageSize < Max) then begin
      Dragging := true;
      PaintView;
      immed := true;
      Curr := R;
      dx := T.X-R.A.X;
      dy := T.Y-R.A.Y;
      mi := sbButtonSize+2;
      if isVert then ma := Size.Y-mi else ma := Size.X-mi;
      while (Event.Buttons > 0) do begin
        repeat
          GetEvent(Event);
        until (Event.What and evMouse > 0);
        MakeLocal(Event.Where,T);
        if (Event.What = evMouseMove) {and MouseInView(Event.Where)} then begin
          Old := Curr;
          if IsVert then begin
            Curr.Move(0,T.Y-dy-Curr.A.Y);
            if Curr.B.Y > ma then Curr.Move(0,ma-Curr.B.Y);
            if Curr.A.Y < mi then Curr.Move(0,mi-Curr.A.Y);
          end else begin
            Curr.Move(T.X-dx-Curr.A.X,0);
            if Curr.B.X > ma then Curr.Move(ma-Curr.B.X,0);
            if Curr.A.X < mi then Curr.Move(mi-Curr.A.X,0);
          end;
          Calc(immed);
        end;
      end; {while}
      Dragging := false;
      Calc(true);
      PaintView;
    end; {if}
    ClearEvent(Event);
  end;
end;

end.