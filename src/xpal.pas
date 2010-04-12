{
Name            : XPal 1.00d
Purpose         : Extended Palette Setter
Coder           : SSG
Date            : 8th Dec 94
Time            : 00:52

updates:
--------
11th Mar 96 - 04:17 - fixed some bugs...
 9th Oct 96 - 02:38 - Some bugfixes...
}

unit XPal;

interface

uses XGfx,XScroll,Graph,XTypes,GView,Objects,Drivers,Tools;

const

  csXCols = 1;
  csYCols = 16 div csXCols;

type

  PColorSelector = ^TColorSelector;
  TColorSelector = object(TView)
    Focused      : byte;
    constructor Init(var R:TRect);
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   Paint;virtual;
  end;

  PPaletteWindow = ^TPaletteWindow;
  TPaletteWindow = object(TDialog)
    Selector    : PColorSelector;
    R,G,B       : PScrollBar;
    constructor Init(ahdr:FNameStr);
    procedure   HandleEvent(var Event:TEvent);virtual;
  end;

implementation

{ TPaletteWindow - changes palettes of windows :)) har har har }

constructor TPaletteWindow.Init;
var
  R1:TRect;
  procedure Put(P:PScrollbar);
  begin
    P^.Update(63,63,1,1,true);
    Insert(P);
  end;
begin
  R1.Assign(0,0,0,0);
  inherited Init(R1,ahdr);
  Options := Options or Ocf_Centered;
  R1.Assign(0,0,60,160);
  R1.Move(5,5);
  New(Selector,Init(R1));
  Insert(Selector);
  R1.Move((R1.B.X-R1.A.X)+5,0);
  R1.B.X := R1.A.X + sbButtonSize;
  New(R,Init(R1));
  R1.Move(sbButtonSize+5,0);
  New(G,Init(R1));
  R1.Move(sbButtonSize+5,0);
  New(B,Init(R1));
  Put(R);
  Put(G);
  Put(B);
  FitBounds;
end;

procedure TPaletteWindow.handleEvent;
  procedure UpdatePalette;
  var
    colR,colG,colB:byte;
  begin
    colR := 63-R^.Value;
    colG := 63-G^.Value;
    colB := 63-B^.Value;
    SetTrueRGB(Selector^.Focused,colR,colG,colB);
  end;

  procedure UpdateScroller;
  var
    rgb:TRGB;
    procedure doit(ha:PScrollBar; wha:byte);
    begin
      ha^.Update(63-wha,63,1,1,false);
    end;
  begin
    GetRGB(palXLat[Selector^.Focused],rgb);
    doit(R,rgb.R);
    doit(G,rgb.G);
    doit(B,rgb.B);
  end;
  procedure SavePal;
  var
    T:TDosStream;
    pal:TRGBPalette;
  begin
    T.Init('CURRENT.PAL',stCreate);
    XGfx.GetPalette(pal);
    T.Write(pal,SizeOf(pal));
    T.Done;
  end;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evBroadcast : case Event.Command of
                    Brc_ScrollBarChanged : with Event do
                      if (InfoPtr <> R) and (InfoPtr <> G) and (InfoPtr <> B) then exit else
                      UpdatePalette;
                    Brc_ColorSelected: if Event.InfoPtr = Selector then UpdateScroller else exit;
                    else exit;
                  end; {Case}
    evKeyDown : if upcase(Event.CharCode) = 'S' then SavePal;
    else exit;
  end;
  ClearEvent(Event);
end;

{ TColorSelector - selects color to be changed }

constructor TColorSelector.Init;
begin
  inherited Init(R);
  Options   := Options or Ocf_PreProcess;
  EventMask := evMouseDown;
end;

procedure TColorSelector.Paint;
var
  R:TRect;
  color:byte;
  xs,ys:integer;
begin
  PaintBegin;
    GetExtent(R);
    xs := (Size.X) div csXCols;
    ys := (Size.Y) div csYCols;
    for color := 0 to 15 do begin
      SetFillStyle(SolidFill,color);
      R.Assign(0,0,xs-1,ys-1);
      R.Move(xs*(color div csYCols),ys*(color mod csYCols));
      ShadowBox(R,focused <> color);
      R.Grow(-1,-1);
      XBox(R,True);
    end;
    SetFillStyle(SolidFill,Col_Back);
    R.Assign(0,csYCols*ys,Size.X,Size.Y);
    XBox(R,True);
    R.Assign(csXCols*xs,0,Size.X,Size.Y);
    XBox(R,True);
  PaintEnd;
end;

procedure TColorSelector.HandleEvent;
var
  xs,ys:integer;
  newf:integer;
begin
  if Event.What = evMouseDown then begin
    xs := (Size.X) div csXCols;
    ys := (Size.Y) div csYCols;
    MakeLocal(Event.Where,Event.Where);
    newf := ((Event.Where.X div xs)*csYCols)+(Event.Where.Y div ys);
    if newf <> focused then begin
      focused := newf;
      PaintView;
      Message(Owner,evBroadcast,Brc_ColorSelected,@Self);
    end;
    ClearEvent(Event);
  end;
end;

end.