{
Name            : FatalVision 2.20a DPMI
Purpose         : The Ultimate User Interface ( Son of DreamView )
Date            : 24th May 93
Coders          : FatalicA & SSG

Update Info:
------------
18th Jan 95 - 16:59 - *** Fixed a bug in PaintPrompt...
18th Jan 95 - 16:59 - *** Fixed a bug in TInputStr's Init...
26th Apr 95 - 20:18 - Found a bug in GrpGetData...
19th Aug 95 - 18:26 - I was wrong...
 6th Mar 96 - 03:33 - *** Fixed a bug in Zoom...
 8th Mar 96 - 00:03 - *** Fixed a bug in ClearEvent...
 8th Mar 96 - 01:37 - *** Modified XTilda so it supports prop fonts now...
 9th Mar 96 - 16:42 - Changed zoomView...
10th Mar 96 - 18:54 - Removed Event passes through selects...
13th Mar 96 - 18:55 - Changed valid parameter declaration...
14th Mar 96 - 11:47 - Bug found in XLine... clip...
21nd Mar 96 - 02:06 - Fixed a major bug in Insert...
25th Mar 96 - 13:21 - Removed self-check in twindow's handleevent..
25th May 96 - 02:09 - *** fixed a bug...
25th May 96 - 02:14 - *** fixed a bug in xtilda...
 2rd Jun 96 - 17:53 - Word aligned TView...
27th Jun 96 - 19:17 - Removed tinputstrs...
29th Aug 96 - 16:24 - *** bugfixes in insert...
 4th Sep 96 - 16:26 - Added disposeblock...
23rd Dec 96 - 02:04 - *** major fixes & changes...
13th Jan 97 - 21:43 - *** bugfix in TView...
}

{$O-}
unit GView;

interface

uses

  objects,graph,drivers,dos,XBuf,XDev,XTypes,XMouse,XStr,XSys,XGfx;

const

  BulletinBoard    : string = ''; {top secret}
  NextEvent        : TEvent = (What:EvNothing);

  Grp_AllGroups = $FFFF;
  ZoomRectCount = 12;
  DragGranularity = 5;

  tildaGAP        : byte = 1;

  Ctx_InputLine   : word = hcNoContext;
  Col_Hdr         : byte = cLightCyan;

type

  PRStack = ^TRStack;
  TRStack = Array[0..RStackSize-1] of TRect;

  PGroup = ^TGroup;
  PView  = ^TView;

  TView = Object(TObject)
    Owner       : PGroup;
    Next        : PView;     {Nextview in circular ZOrder}
    Origin      : TPoint;
    Size        : TPoint;
    State       : Word;
    Options     : Word;
    CurPos      : TPoint;    {cursor position}
    EventMask   : Word;
    ExitCode    : Word;      {endmodal code}
    Config      : Word;
    ViewType    : Word;
    MinSize     : TPoint;
    MaxSize     : TPoint;
    HelpContext : Word;
    PaintState  : byte;
    ViewId      : Byte;
    GroupId     : Byte;
    GrowMode    : byte;      {relative grow flags}
    {inits & dones}
    constructor Init(var R:TRect);
    destructor  Done; virtual;

    {event management}
    procedure   PutEvent(var Event:TEvent); virtual;
    procedure   HandleEvent(Var Event:TEvent); virtual;
{    procedure   PostEvent(Var Event:TEvent); virtual;}
    procedure   ClearEvent(Var Event:TEvent);
    procedure   GetEvent(var Event:TEvent); virtual;
    function    ExitValid(Var Event:TEvent):Boolean; virtual;
    function    EntryValid(Var Event:TEvent):Boolean; virtual;
    function    Valid(acmd:word):Boolean; virtual;
{    procedure   GetMouseEvent(Var Event:TEvent);
    procedure   GetKeyEvent(var Event:TEvent);}
    procedure   BackProcess;virtual; {by SSG}

    {identification methods}
    function    GetHelpContext : word;virtual;

    {positional methods}
    function    MouseInView(M:TPoint):Boolean;virtual;
    procedure   MakeLocal(Src:Tpoint; var Des:TPoint);
    procedure   MakeLocalRect(Src:TRect; var Dest:TRect);
    procedure   MakeGlobal(Src:TPoint; var Des:TPoint);
    procedure   MakeGlobalRect(src:TRect; var dest:TRect);

    {set & gets}
    procedure   SetState(AState:Word; Enable:Boolean); virtual;
    function    GetState(AState:Word):Boolean;
    procedure   SetData(Var Rec); virtual;
    procedure   GetData(Var Rec); virtual;
    function    DataSize:Word; virtual;
    procedure   SetViewId(Id:Byte);
    procedure   SetGroupId(Id:Word);
{    procedure   AssignGroup(Id:Word);}
    function    GetViewId:Byte;
    function    GetGroupId:Word;
    procedure   SetConfig(AConfig:Word; Enable:Boolean); virtual;
    function    GetConfig(AConfig:Word):Boolean; virtual;

    {cursor handling functions}
    procedure   HideCursor;
    procedure   ShowCursor;
    procedure   SetCursor(CX,CY:Integer);

    {execution methods}
    function    Select:Boolean;
    function    IsSelectable:Boolean;
    procedure   EndModal(ACmd:Word); virtual;
    function    Execute:Word; virtual;
    function    Prev:PView;
    function    PrevView:PView;
    function    NextView:PView;

    {rectangle methods}
    procedure   GetBounds(Var R:TRect);
    procedure   GetExtent(Var R:TRect);
    procedure   ChangeBounds(Var R:TRect); virtual;
    procedure   CalcBounds(var Bounds:TRect);virtual;
    procedure   GetOwnerBounds(var R:TRect);virtual;
    procedure   Drag(var Event:TEvent;DragMode:byte);virtual;

    {Paint methods}
    procedure   PaintView;
    procedure   PaintBegin;
    procedure   FastPaintBegin;
    procedure   Paint; virtual;
    procedure   PaintEnd;
    procedure   Hide;
    procedure   Show;

    {Graphic commands}
    procedure   DrawGrid(var R:TRect);
    procedure   Triangle(x1,y1,x2,y2,x3,y3:integer);
    procedure   XBox(R:TRect;Filled:Boolean);
    procedure   XCircle(Bounds:TRect);
    procedure   XRectangle(x1, y1, x2, y2: Integer);
    procedure   XBar(x1, y1, x2, y2: Integer);
    procedure   XPutPixel(X, Y: Integer; Pixel: Word);
    procedure   XLine(x1, y1, x2, y2: Integer);
    procedure   XWriteStr(X,Y,SX:Integer; Str:String);
    procedure   XWritePStr(x,y,sx:integer; P:PFont; var str:string);
    procedure   XPrintStr(X,Y,SX:Integer; FontId:Word; Str:String);
    procedure   XPrintOredStr(X,Y,SX:Integer; FontId:Word; Str:String);
    procedure   XPutVIF(X,Y:Integer; Var BitMap);
    procedure   XPutImage(X,Y:Integer; ImageId:Word);
    procedure   XTilda(x,y:integer; s:string; fontid:word; fc,bc:byte);
    procedure   XPie(centerx,centery,stangle,endangle,radius:integer);
    procedure   XArc(centerx,centery,stangle,endangle,radius:integer);
    procedure   ShadowBox(Var R:TRect; Shadow:boolean);

    private
    RStack     : PRStack;
    StackTop   : Integer;

    procedure   GetPaintExtent(Var R:TRect);
    procedure   GetPaintBounds(Var R:TRect);
    procedure   SetPaintState(AStart:PView);
    procedure   _PaintBegin(AStart:PView);
    procedure   MakeCursorOn;
    procedure   MakeCursorOff;
    procedure   PaintCursor(T:TPoint; AState:Word);
    procedure   DeltaRect(Var BR,DR:TRect; SP:Integer);
    procedure   ClipScreenR(Src:TRect; Var Des:TRect; N:Integer);
    procedure   ClipScreenP(Src:TPoint; Var Des:TPoint; N:Integer);
    procedure   PaintShow;
    procedure   PaintUnderView;
    procedure   PaintHide;
  end;  {tView}

  PChildList = ^TChildList;
  TChildList = record
    Child    : PView;
    Next     : PChildList;
  end;

  TGroup = Object(TView)
    Current   : PView;
    Top       : PView;
    Phase     : Byte;
    Clip      : TRect;
    TrueClip  : TRect;
    LockCount : Integer;
    ActiveGroups : Word;

    {init & done}
    constructor Init(Var R:TRect);
    destructor  Done; virtual;

    {subView control methods}
    procedure   Insert(View:PView);
    procedure   InsertBlock(P:String);
    function    GetMostTop:PView;
    procedure   Delete(View:PView);
    procedure   MakeTop(P:PView);
    procedure   MakeGroupActive(Id:Word; Active:Boolean);
    procedure   ForEach(Action:Pointer);
    procedure   GrpForEach(GrpId:Word; Action:Pointer);
    function    FirstThat(Action:Pointer):PView;
    function    GrpFirstThat(GrpId:Word; Action:Pointer):PView;
    function    GetViewPtr(Id:Byte):PView;
    function    SetCurrent(P:PView):Boolean;
    procedure   SelectNext(ANext:Boolean);

    {set & gets}
    procedure   SetState(AState:Word; Enable:Boolean); virtual;
    procedure   SetData(Var Rec); virtual;
    procedure   GetData(Var Rec); virtual;
    function    DataSize:Word; virtual;
    procedure   GrpSetData(GrpId:Word; Var Rec); virtual;
    procedure   GrpGetData(GrpId:Word; Var Rec); virtual;
    function    GrpDataSize(GrpId:Word):Word; virtual;

    {event management methods}
    procedure   HandleEvent(Var Event:TEvent); virtual;
{    procedure   PostEvent(Var Event:TEvent); virtual;}
    procedure   BackProcess;virtual; {by SSG}

    {execution methods}
    function    Execute:Word; virtual;
    function    ExecView(P:PView):Word;
    function    Valid(acmd:word):boolean;virtual;

    {paint methods}
    procedure   Lock;
    procedure   UnLock;
    procedure   Paint; virtual;
    procedure   PaintUnderRect(SV:PView; Var R:TRect);
    procedure   PaintSubViews;

    {Rectangle methods}
    procedure   ChangeBounds(var R:TRect);virtual;
    procedure   ZoomView(P:PView);
    procedure   ZoomOut(P:PView);
    procedure   GetTrueClip(var R:TRect);
    procedure   GetVisibleBounds(var R:TRect);virtual;
    procedure   FitBounds;virtual;

    {help system management}
    function    GetHelpContext : word;virtual;
  end; {tgroup}

  PWindow = ^TWindow;
  TWindow = Object(TGroup)
     Frame    : PView;
     Header   : PString;
     ZoomRect : TRect;
     {inits & dones}
     constructor Init(R:TRect; AHdr:String);
     procedure   InitFrame(var R:TRect);virtual;
     destructor  Done;virtual;

     {paint methods}
     procedure   Paint;virtual;
     procedure   PaintFrame;virtual;

     {event management methods}
     procedure   HandleEvent(Var Event:TEvent); virtual;
{     procedure   PostEvent(Var Event:TEvent); virtual;}
     procedure   HandleGadgets(var Event:TEvent); virtual;
     procedure   HandleDrag(var Event:TEvent);virtual;

     {set & gets}
     procedure   SetState(AState:Word; Enable:Boolean); virtual;

     {positional methods}
     procedure   GetVisibleBounds(var R:TRect);virtual;
     procedure   Zoom;
  end; {twindow}

  TBackDC = record
    Style : Word;
    case word of
      bsSolid   : (SColor:Word);
      bsPattern : (PColor:Word;
		   Pattern:Word;);
      bsBitMap  : (Tiled:Boolean;
		   BitMapId:Word;);
  end;

  PBackGround = ^TBackGround;
  TBackGround = object(TView)
    DC          : TBackDC;
    constructor Init(Var R:TRect; var hDC:TBackDC);
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   AssignDC(var hDC:TBackDC);
    procedure   Paint; virtual;
  end;

function Message(Receiver:PView;What,Command:Word;InfoPtr:Pointer):Pointer;
function XMessage(Receiver:PView;What,Command:Word; Sender:PView; InfoPtr:Pointer):Pointer;
function PtrStr(var P):string;
function StrPtr(var S:String;Index:Integer):Pointer;
procedure DisposeBlock(var s:string);
procedure GetBlockBounds(var S:String;var R:TRect);
procedure MoveBlock(var block:string; deltax,deltay:integer);

IMPLEMENTATION

TYPE
   PSortedByX = ^TSortedByX;
   TSortedByX = Object(TSortedCollection)
     function Compare(Key1,Key2:Pointer):Integer; virtual;
   end;

   PSortedByY = ^TSortedByY;
   TSortedByY = Object(TSortedCollection)
     function Compare(Key1,Key2:Pointer):Integer; virtual;
   end;

CONST
  RStackCache    : PRStack = NIL;
  RStackCacheCount : Integer = 0;
  AKeyCodesMap   : String[7] = ^S+^D+^G+^H+^Y+^E+^V;
  AKeyCodes      : Array[1..7] of word = (KbLeft,KbRight,KbDel,KbBack,KbShiftDel,KbCtrlDel,KbIns);
  EditMaskChars  : String[2] = 'X9';
  MaskCharSets   : Array[1..2] of TCharSet =
		  ([#32..#255],['0'..'9']);
  Psw_Char     : Char = '*';

{Cursor Constants }
  CursorOwner  : PView = Nil;

function PtrStr(var P):string;
var
  S:String;
  PP:Pointer;
begin
  S[0] := #4;
  PP:=Pointer(P);
  Move(PP,S[1],4);
  PtrStr := S;
end;

procedure MoveBlock(var block:string; deltax,deltay:integer);
var
  b:byte;
  P:PView;
  R:TRect;
begin
  b := 1;
  while b < length(block) do begin
    P := PView(StrPtr(block,b));
    P^.GetBounds(R);
    R.Move(deltax,deltay);
    P^.ChangeBounds(R);
    inc(b,4);
  end;
end;

procedure GetBlockBounds(var S:String;var R:TRect);
var
  b:byte;
  PR:TRect;
begin
  PView(StrPtr(S,1))^.GetBounds(R);
  b := 5;
  while (b < length(s)) do begin
    PView(StrPtr(S,b))^.GetBounds(PR);
    if pr.a.x < r.a.x then r.a.x := pr.a.x;
    if pr.a.y < r.a.y then r.a.y := pr.a.y;
    if pr.b.x > r.b.x then r.b.x := pr.b.x;
    if pr.b.y > r.b.y then r.b.y := pr.b.y;
    inc(b,4);
  end; {while}
end;

procedure DisposeBlock;
var
  index:integer;
begin
  index := 1;
  while index < length(s) do begin
    Dispose(PView(StrPtr(s,index)),Done);
    inc(index,4);
  end;
end;

function StrPtr(var S:String;Index:Integer):Pointer;
var
  P:Pointer;
begin
  Move(S[Index],P,4);
  StrPtr := P;
end;

function Message(Receiver:PView;What,Command:Word;InfoPtr:Pointer):Pointer;
var
  Event:TEvent;
begin
  Message:=NIL;
  if Receiver = NIL then exit;
  Event.What   :=What;
  Event.Command:=Command;
  Event.InfoPtr:=InfoPtr;
  Receiver^.HandleEvent(Event);
  if Event.What=evNothing then Message:=Event.InfoPtr;
end;

function XMessage(Receiver:PView;What,Command:Word; Sender:PView; InfoPtr:Pointer):Pointer;
var
  Event:XEvent;
  P    :^TEvent;
begin
  XMessage:=NIL;
  if Receiver = NIL then exit;
  Event.What:=What;
  Event.Command:=Command;
  Event.Source := Sender;
  Event.InfoPtr:=InfoPtr;
  P := @Event;
  Receiver^.HandleEvent(P^);
  if Event.What=evNothing then XMessage:=Event.InfoPtr;
end;
{---------------------------------------------------------------------------}
{->                     TSORTEDBYX AND Y                                  <-}
{---------------------------------------------------------------------------}
function TSortedByX.Compare(Key1,Key2:Pointer):Integer;
    begin
      if PView(Key1)^.Origin.X < PView(Key2)^.Origin.X then Compare := -1
      else if PView(Key1)^.Origin.X > PView(Key2)^.Origin.X then Compare := 1
      else Compare := 0;
    end;

function TSortedByY.Compare(Key1,Key2:Pointer):Integer;
    begin
      if PView(Key1)^.Origin.Y < PView(Key2)^.Origin.Y then Compare := -1
      else if PView(Key1)^.Origin.Y > PView(Key2)^.Origin.Y then Compare := 1
      else Compare := 0;
    end;
{---------------------------------------------------------------------------}
{->                           View                                        <-}
{---------------------------------------------------------------------------}
constructor TView.Init(Var R:Trect);
begin
  inherited Init;
  Origin    := R.A;
  Size.X    := R.B.X - R.A.X;
  Size.Y    := R.B.Y - R.A.Y;
  State     := Scf_Visible;
  ViewType  := VtView;
  EventMask := EvMouse + EvCommand;
  MinSize   := Size;
  MaxSize   := Size;
  SetState(Scf_Backprocess,True);
end;

procedure TView.DrawGrid(var R:TRect);
var
  R1:TRect;
begin
  if Options and Ocf_FullDrag <> 0 then ChangeBounds(R) else begin
    SetWriteMode(XorPut);
    with R do begin
      Line(a.x,a.y,b.x,a.y);
      Line(b.x,a.y+1,b.x,b.y);
      Line(a.x,b.y,b.x-1,b.y);
      Line(a.x,a.y+1,a.x,b.y-1);
    end;
    SetWriteMode(NormalPut);
  end;
end;

function TView.GetHelpContext : word;
begin
  GetHelpContext := HelpContext;
end;

destructor TView.Done;
begin
  if Owner<>Nil then Owner^.Delete(@Self);
  if RStack <> NIL then
    if RStack <> RStackCache then begin
      Dispose(RStack);
      RStack := NIL;
    end;
  inherited Done;
end;

procedure TView.BackProcess;
begin
end;

procedure TView.PutEvent(var Event:TEvent);
begin
  if Owner<>NIL then Owner^.PutEvent(Event);
end;

procedure TView.HandleEvent(Var Event:TEvent);
begin
  if (Options and Ocf_Selectable > 0) then begin
    if (Event.What = EvMouseDown) and (Event.Buttons = mbLeft) then begin
     if Not GetState(Scf_Focused) then begin
        Select;
        if Options and Ocf_FirstClick = 0 then ClearEvent(Event);
      end;
    end;
  end;
  if (Options and Ocf_Move > 0) and
     (ViewType < $4000) and
     (Event.What = evMouseDown) and
     (Event.Buttons = mbRight) then begin
    Drag(Event,dmDragMove+dmLimitAll);
    ClearEvent(Event);
  end;
end;

{procedure TView.PostEvent(Var Event:TEvent);
begin
end;}

procedure TView.ClearEvent(Var Event:TEvent);
begin
  Event.What := EvNothing;
  Event.InfoPtr := @Self;
end;

procedure TView.GetEvent(var Event:TEvent);
begin
  if Owner<>Nil then Owner^.GetEvent(Event);
end;

function TView.MouseInView(M:TPoint):Boolean;
var
  T : TPoint;
  R : TRect;
begin
  GetExtent(R);
  MakeLocal(M,T);
  MouseInView := R.Contains(T);
end;

procedure TView.MakeLocal(Src:TPoint; var Des:TPoint);
var
  P : PGroup;
begin
 Des := Src;
 P   := @Self;
 repeat
   Dec(Des.X,P^.Origin.X);
   Dec(Des.Y,P^.Origin.Y);
   P := P^.Owner;
 until P=Nil;
end;

procedure TView.MakeGlobal(Src:TPoint; var Des:TPoint);
var
  P : PGroup;
begin
  Des := Src;
  P   := @Self;
  repeat
    Inc(Des.X, P^.Origin.X);
    Inc(Des.Y, P^.Origin.Y);
    P := P^.Owner;
  until P=Nil;
end;

procedure TView.MakeGlobalRect;
begin
  MakeGlobal(Src.A,Dest.A);
  MakeGlobal(Src.B,Dest.B);
end;

procedure TView.MakeLocalRect;
begin
  MakeLocal(Src.A,Dest.A);
  MakeLocal(Src.B,Dest.B);
end;

procedure TView.SetState(AState:Word; Enable:Boolean);
var
  A : Word;
  B : Word;
begin
  B := State;
  if Enable Then State := State or AState
	    else State := State and Not AState;
  A := AState;
  if A and Scf_Visible > 0 then
    if Enable then PaintShow
	      else PaintHide;
  if A and Scf_CursorVis > 0 then
    if Enable then MakeCursorOn
	      else MakeCursorOff;
  if A and Scf_CursorIns > 0 then
   if State and Scf_CursorVis > 0 then begin
     PaintCursor(Curpos,B);
     PaintCursor(CurPos,State);
  end;
end;

function TView.GetState(AState:Word):Boolean;
begin
  GetState := State and AState = AState; {The most optimized getstate}
end;

procedure TView.SetData(Var Rec);
begin
end;

procedure TView.GetData(Var Rec);
begin
end;

function TView.DataSize:Word;
begin
  DataSize := 0;
end;

procedure TView.Hide;
begin
  SetState(Scf_Visible,False);
end;

procedure TView.Show;
begin
  SetState(Scf_Visible,True);
end;

procedure TView.HideCursor;
begin
  SetState(Scf_CursorVis,False);
end;

procedure TView.ShowCursor;
begin
  SetState(Scf_CursorVis,True);
end;

procedure TView.SetCursor(CX,CY:Integer);
var
  T : TPoint;
begin
  if Not GetState(Scf_CursorVis) then exit;
  if CursorOwner <> @Self then begin
    if CursorOwner <> NIL then CursorOwner^.MakeCursorOff;
    CursorOwner := @Self;
  end;
  T.X := CX;
  T.Y := CY;
  if (T.X = CurPos.X) and
     (T.Y = CurPos.Y) and
     (State and Scf_CursorOn > 0) then exit;
  if State and Scf_CursorOn > 0 then PaintCursor(CurPos,State);
  if RStack = Nil then begin
     PaintCursor(T,State);
  end;
  CurPos := T;
end;

function TView.Select:Boolean;
begin
  if Owner <> Nil then Select := Owner^.SetCurrent(@Self)
                  else Select := False;
end;

function TView.IsSelectable:Boolean;
begin
  IsSelectable := (State and Scf_Disabled = 0) and
		  (State and Scf_Visible > 0) and
		  (Options and Ocf_Selectable > 0);
end;

function TView.ExitValid(Var Event:TEvent):Boolean;
begin
  if Owner = Nil then ExitValid := True
		 else ExitValid := Owner^.ExitValid(Event);
end;

function TView.EntryValid(Var Event:TEvent):Boolean;
begin
  if Owner = Nil then EntryValid := True
		 else EntryValid := Owner^.EntryValid(Event);
end;

function TView.Valid;
begin
  Valid := True; {ssg was here}
end;

procedure TView.EndModal(ACmd:Word);
begin
  ExitCode := ACmd;
  SetState(Scf_Modal,False);
end;

function TView.Execute:Word;
begin
  Execute := cmCancel;
end;

function TView.Prev:PView;
var
  P : PView;
begin
  P := @Self;
  while (P^.Next <> @Self) and (P <> NIL) do P:=P^.Next;
  if P=Nil then Prev := @Self
	   else Prev := P;
end;

function TView.PrevView:PView;
var
  P : PView;
begin
  PrevView := Nil;
  if Owner=Nil then exit;
  P := Prev;
  if Owner^.Top <> P then PrevView := P;
end;

function TView.NextView:PView;
begin
  NextView := Nil;
  if Owner = Nil then exit;
  if @Self <> Owner^.Top then NextView := Next;
end;

procedure TView.GetBounds(Var R:TRect);
begin
  R.A   := Origin;
  R.B.X := R.A.X + Size.X;
  R.B.Y := R.A.Y + Size.Y;
end;

procedure TView.GetExtent(Var R:TRect);
begin
  R.Assign(0,0,Size.X,Size.Y);
end;

procedure TView.GetPaintExtent(Var R:TRect);
var
  R1 : TRect;
begin
   R.Assign(0,0,Size.X+1,Size.Y+1);
   if Owner <> NIL then begin
     R1 := Owner^.Clip;
     R1.Move(-Origin.X, -Origin.Y);
     R.Intersect(R1);
   end;
end;

procedure TView.GetPaintBounds(Var R:TRect);
begin
  R.A := Origin;
  R.B.X := R.A.X + Size.X + 1;
  R.B.Y := R.A.Y + Size.Y + 1;
end;

procedure TView.ChangeBounds(var R:TRect);
var
  OldR : TRect;
begin
  CalcBounds(R);
  GetBounds(OldR);
  Origin := R.A;
  Size.X := R.B.X - R.A.X;
  Size.Y := R.B.Y - R.A.Y;
  if Owner <> NIL then if (Owner^.LockCount = 0) then begin
     PaintView;
     Owner^.PaintUnderRect(@Self,OldR);
  end;
end;

procedure TView.CalcBounds(var Bounds:TRect);
begin
end;

procedure TView.GetOwnerBounds(var R:TRect);
begin
  if Owner <> NIL then begin
    Owner^.GetVisibleBounds(R);
    Owner^.MakeGlobalRect(R,R);
  end else begin
    GetBounds(R);
    MakeGlobalRect(R,R);
  end;
end;
procedure TView.Drag(var Event:TEvent;DragMode:Byte);
var
  R,R1:TRect;
  Temp:TRect;
  OWR:TRect;
  Old:TPoint;
  dx,dy:integer;
  ok:boolean;
  EventMouse:boolean;{if true mouse else keyboard}
  subok:boolean;
  fast:boolean;
  oldstate:boolean;
  procedure InitLineSettings;near;
  begin
    SetViewPort(0,0,ScreenX,ScreenY,False);
    SetColor(Col_Back);
    SetLineStyle(SolidLn,0,1);
  end;
  procedure DoneLineSettings;near;
  begin
    SetLineStyle(SolidLn,0,1);
  end;
  procedure PaintBar(var xR:TRect);near;
  begin
    Mouse_Hide;
    DrawGrid(xR);
    Mouse_Show;
  end;
  procedure MoveRect;near;
  begin
    if (Old.X <> Event.Where.X) or (Old.Y <> Event.Where.Y) then begin
       if DragMode and dmDragMove > 0 then begin
         R.Move(Event.Where.X-Old.X,Event.Where.Y-Old.Y);
	 if DragMode and dmLimitLoX > 0 then if R.A.X < OWR.A.X then R.Move(OWR.A.X-R.A.X,0);
	 if DragMode and dmLimitLoY > 0 then if R.A.Y < OWR.A.Y then R.Move(0,OWR.A.Y-R.A.Y);
	 if DragMode and dmLimitHiX > 0 then if R.B.X > OWR.B.X then R.Move(OWR.B.X-R.B.X,0);
	 if DragMode and dmLimitHiY > 0 then if R.B.Y > OWR.B.Y then R.Move(0,OWR.B.Y-R.B.Y);
       end
       else begin
	  R.B.X := Event.Where.X + dx;
	  R.B.Y := Event.Where.Y + dy;
	  if DragMode and dmLimitHiX > 0 then if R.B.X > OWR.B.X then R.B.X := OWR.B.X;
	  if DragMode and dmLimitHiY > 0 then if R.B.Y > OWR.B.Y then R.B.Y := OWR.B.Y;
	  if r.b.x-r.a.x < MinSize.X then R.B.X := R.A.X + MinSize.X;
	  if r.b.y-r.a.y < MinSize.Y then R.B.Y := R.A.Y + MinSize.Y;
	  if r.b.x-r.a.x > MaxSize.X then R.B.X := R.A.X + MaxSize.X;
	  if r.b.y-r.a.y > MaxSize.Y then R.B.Y := R.A.Y + MaxSize.Y;
       end;
       Old := Event.Where;
    end;
  end;
  procedure Relative(x,y:integer);near;
  begin
    Event.Where.X := Old.X + x;
    Event.Where.Y := Old.Y + y;
    MoveRect;
  end;
  procedure Untitled(x,y:integer);near;
  begin
    Event.Where.X := x;
    Event.Where.Y := y;
    MoveRect;
  end;
begin
  if Owner = NIL then exit;
  if DragMode and (dmDragMove+dmDragGrow) = 0 then exit;
  if (DragMode and dmDragMove > 0) and (Options and Ocf_Move=0) then exit;
  if (DragMode and dmDragGrow > 0) and (Options and Ocf_Resize=0) then exit;
  GetExtent(R);
  MakeGlobalRect(R,R);
  R1 := R;
  GetOwnerBounds(OWR);
  EventMouse := Event.What and evMouse > 0;
  if EventMouse then Old := Event.Where else Old := R.B;
  dx := R.B.X - Old.X;
  dy := R.B.Y - Old.Y;
  oldstate := GetSystem(Sys_Backprocess);
  SetSystem(Sys_BackProcess,False);
  ok := false;
  fast := false;
  InitLineSettings;
  repeat
    if Options and Ocf_FullDrag = 0 then PaintBar(R);
    subok := false;
    repeat
      GetEvent(Event);
      if EventMouse then begin
        subok := Event.What and evMouse > 0;
      end else subok := Event.What = evKeyDown;
    until subok;
    Temp := R;
    if EventMouse then ok := Event.Buttons = 0;
    if EventMouse then MoveRect else
      case Event.KeyCode of
	 kbLeft  : Relative(-DragGranularity,0);
	 kbRight : Relative(DragGranularity,0);
	 kbUp    : Relative(0,-DragGranularity);
	 kbDown  : Relative(0,DragGranularity);
	 kbEnter,kbEsc : ok := true;
      end; {case}
    Sync;
    PaintBar(Temp);
  until ok;
  DoneLineSettings;
  SetSystem(Sys_Backprocess,oldstate);
  if Event.What = evKeyDown then
    if Event.KeyCode = kbEsc then begin
    ClearEvent(Event);
    exit;
  end;
  ClearEvent(Event);
  if not R.Equals(R1) then begin
    Owner^.MakeLocalRect(R,R);
    ChangeBounds(R);
  end;
end;
procedure TView.SetViewId(Id:Byte);
    begin
      ViewId := Id;
    end;
procedure TView.SetGroupId(Id:Word);
    begin
      GroupId := Id;
    end;
{procedure TView.AssignGroup(Id:Word);
    begin
      GroupId := GroupId or Id;
    end;}
function TView.GetViewId:Byte;
    begin
      GetViewId := ViewId;
    end;
function TView.GetGroupId:Word;
    begin
      GetGroupId := GroupId;
    end;
procedure TView.SetConfig(AConfig:Word; Enable:Boolean);
    begin
      if Enable then Config := Config or AConfig
		else Config := Config and Not AConfig;
    end;
function TView.GetConfig(AConfig:Word):Boolean;
    begin
      GetConfig := Config and AConfig = AConfig;
    end;
{procedure TView.GetMouseEvent(Var Event:TEvent);
    begin
      repeat PointingDevice^.GetEvent(Event); until Event.What and EvMouse > 0;
    end;
procedure TView.GetKeyEvent(var EVent:TEvent);
    begin
      repeat GetKeyEvent(Event); until Event.What <> evNothing;
    end;}

{----------------------- CHECK RECTANGLES ---------------------}
procedure TView.ShadowBox(Var R:TRect; Shadow:boolean);
var
  c1,c2 : integer;
begin
  if shadow then begin
     c1:=Shc_UpperLeft;c2:=Shc_LowerRight;
  end else Begin
     c1:=Shc_LowerRight;c2:=Shc_UpperLeft;
  end; { else }
  with R do begin
    SetColor(C1);
    XLine(A.X, A.Y, A.X, B.Y-1);     {left}
    XLine(A.X+1, A.Y, B.X-1, A.Y);   {upper}
    SetColor(C2);
    XLine(B.X, A.Y, B.X, B.Y);   {right}
    XLine(A.X, B.Y, B.X-1, B.Y); {lower}
  end;
end;

procedure TView.PaintView;
begin
  if GetState(Scf_Exposed+Scf_Visible) then Paint;
end;

procedure TView.PaintBegin;
var
  ok:boolean;
begin
  if (Options and Ocf_Paintfast > 0) then begin
    ok := false;
    if (Owner <> NIL) then
      if Owner^.Owner = NIL then ok := true;
    if ok then _PaintBegin(@Self) else _PaintBegin(Owner);
  end else _PaintBegin(@Self);
end;

procedure TView.FastPaintBegin;
begin
  _PaintBegin(Owner); {Owner}
end;

procedure TView._PaintBegin(AStart:PView);
var
  T  : TPoint;
  R  : TRect;
  R1 : TRect;
begin
  if Owner = NIL then exit;
  Owner^.GetExtent(R1);
  GetBounds(R);
  R.Intersect(R1);
  Owner^.MakeGlobalRect(R,R);
  Mouse_Hide;
  if (State and Scf_CursorPainting = 0) then
   if (State and Scf_CursorVis > 0) and
      (State and Scf_CursorOn > 0) then PaintCursor(Curpos,State);
  PaintState := Psc_PaintStarted;
  if AStart = NIL then SetPaintState(@Self)
		  else SetPaintState(AStart);
end;

procedure TView.Paint;
    begin
      PaintBegin;
      SetFillStyle(SolidFill,Col_Back);
      XBar(0,0,Size.X,Size.Y);
      PaintEnd;
    end;
procedure TView.PaintEnd;
    begin
      if State and (Scf_CursorPainting +
		    Scf_CursorVis) = Scf_CursorVis then
	 if CursorOwner = @Self then begin
	   State := State and Not Scf_CursorOn;
	   PaintCursor(CurPos,State);
      end;
      Mouse_Show;
      if RStack <> NIL then begin
	StackTop   := 0;
	if RStackCacheCount > 0 then begin
	  if RStack <> RStackCache then begin
	    Dispose(RStack);
	    RStack := NIL;
	  end;
	  Dec(RStackCacheCount);
	end;
	RStack     := NIL;
	PaintState := Psc_PaintEnded;
      end;
    end;

procedure TView.DeltaRect(Var BR,DR:TRect; SP:Integer);
var
  C1,C2,C3,C4 : TRect;
  SR          : TRect;
  F           : Boolean;
  procedure PushRect(Var Bound:TRect);
  begin
    if StackTop < RStackSize then begin
      F := False;
      if SP = -1 then begin
	RStack^[StackTop] := Bound;
	inc(StackTop);
      end else begin
	RStack^[SP] := Bound;
	SP := -1;
      end;
    end else Error('PushRect','Internal stack overflow');
  end;
begin
  SR := BR;
  SR.Intersect(DR);
  if SR.Empty then exit;
  F := True;
  C1.Assign(BR.A.X, BR.A.Y, BR.B.X, SR.A.Y);
  C2.assign(BR.A.X, SR.B.Y, BR.B.X, BR.B.Y);
  C3.assign(BR.A.X, SR.A.Y, SR.A.X, SR.B.Y);
  C4.assign(SR.B.X, SR.A.Y, BR.B.X, SR.B.Y);
  if Not C3.Empty then PushRect(C3);
  if Not C4.Empty then PushRect(C4);
  if Not C1.Empty then PushRect(C1);
  if Not C2.Empty then PushRect(C2);
  if F then begin
    if SP<>-1 then begin
      if StackTop > 0 then begin
	RStack^[SP] := RStack^[StackTop-1];
	dec(StackTop);
      end;
    end;
  end;
end;

procedure TView.SetPaintState(AStart:PView);
var
  R1,R2 : TRect;
  P     : PGroup;
  V     : PView;
  I,M   : Integer;
begin
  if (AStart^.Owner = Nil) or (not GetState(Scf_Visible)) then exit;
  P := Owner;
  GetPaintBounds(R1);
  repeat
    if P^.LockCount > 0 then exit;
    if Options and Ocf_Framed > 0 then R2 := P^.TrueClip
				  else R2 := P^.Clip;
    R1.InterSect(R2);
    if R1.Empty then exit;
    R1.Move(P^.Origin.X,P^.Origin.Y);
    P := P^.Owner;
  until P=Nil;
  R2.Assign(0,0,ScreenX+1,ScreenY+1);
  R1.InterSect(R2);
  P          := AStart^.Owner;
  if RStackCache <> NIL then begin
    if RStackCacheCount > 0 then New(RStack)
                            else RStack := RStackCache;
    inc(RStackCacheCount);
  end;
  if RStack = NIL then Error('SetPaintState','Internal stack overflow');
  StackTop   := 1;
  RStack^[0] := R1;
  V          := AStart;
  repeat
    while V <> P^.Top do begin
      V := V^.Next;
      if V^.State and Scf_Visible = Scf_Visible then begin
        V^.GetPaintExtent(R2);
        V^.makeGlobalRect(R2,R2);
        R2.Intersect(R1);
        if not R2.Empty then begin
          if StackTop = 0 then exit;
          I := 0;
          M := StackTop;
          while I < M do begin
            DeltaRect(RStack^[I],R2,I);
            if M > StackTop then M := StackTop
		            else inc(I);
          end; {while}
        end; {if not empty}
      end; {if visible}
    end; {while}
    V := PView(P);
    P := P^.Owner;
  until P = Nil;
  PaintState := PaintState or Psc_Paintable;
end;

procedure TView.ClipScreenR(Src:TRect; Var Des:TRect; N:Integer);
var
  R : TRect;
begin
  Des := Src;
  R   := RStack^[N];
  SetViewPort(R.A.X, R.A.Y, R.B.X-1, R.B.Y-1, ClipOn);
  Des.Move(-R.A.X,-R.A.Y);
end;

procedure TView.ClipScreenP(Src:TPoint; Var Des:TPoint; N:Integer);
var
  R : TRect;
begin
  Des := Src;
  R := RStack^[N];
  SetViewPort(R.A.X, R.A.Y, R.B.X-1, R.B.Y-1, ClipOn);
  dec(Des.X, R.A.X);
  dec(Des.Y, R.A.Y);
end;

{----------------------- PAINT ROUTINES ---------------------}
procedure TView.XCircle(Bounds:TRect);
var
  I  : Integer;
  R  : TRect;
  R1 : TRect;
  XR,YR : Word;
  swp : integer;
begin
  if PaintState and Psc_Paintable > 0 then begin
    if Bounds.B.X < Bounds.A.X then SwapBuf(Bounds.B.X,Bounds.A.X,SizeOf(Bounds.B.X));
    if Bounds.B.Y < Bounds.A.Y then SwapBuf(Bounds.B.Y,Bounds.A.Y,SizeOf(Bounds.A.Y));
    XR := (Bounds.B.X-Bounds.A.X) div 2;
    YR := (Bounds.B.Y-Bounds.A.Y) div 2;
    R1 := Bounds;
    MakeGlobalRect(R1,R1);
    for I:=0 to StackTop - 1 do begin
      ClipScreenR(R1,R,I);
      Ellipse(R.A.X+XR,R.A.Y+YR,0,360,XR,YR);
    end;
  end;
end;

procedure TView.XArc(centerx,centery,stangle,endangle,radius:integer);
var
  i:integer;
  R:TRect;
  ClipR:TRect;
  GlobalCenter:TPoint;
begin
  GlobalCenter.X := centerx;
  GlobalCenter.Y := centery;
  with GlobalCenter do begin
    R.A.X := X-radius;
    R.A.Y := Y-radius;
    R.B.X := X+radius;
    R.B.Y := Y+radius;
  end;
  MakeGlobalRect(R,R);
  for i := 0 to StackTop-1 do begin
    ClipScreenR(R,ClipR,i);
    with GlobalCenter do Arc(X,Y,stangle,endangle,radius);
  end;
end;

procedure TView.XPie(centerx,centery,stangle,endangle,radius:integer);
var
  i:integer;
  R:TRect;
  ClipR:TRect;
  GlobalCenter:TPoint;
begin
  GlobalCenter.X := centerx;
  GlobalCenter.Y := centery;
  with GlobalCenter do begin
    R.A.X := X-radius;
    R.A.Y := Y-radius;
    R.B.X := X+radius;
    R.B.Y := Y+radius;
  end;
  MakeGlobal(r.a,r.a);
  MakeGlobal(r.b,r.b);
  for i := 0 to StackTop-1 do begin
    ClipScreenR(R,ClipR,i);
    with GlobalCenter do PieSlice(X,Y,stangle,endangle,radius);
  end;
end;

procedure TView.XRectangle(x1, y1, x2, y2: Integer);
    Var
      I  : Integer;
      R  : TRect;
      R1 : Trect;
    begin
     if PaintState and Psc_Paintable > 0 then begin
	R1.Assign(x1,y1,x2,y2);
        MakeGlobalRect(R1,R1);
	For I:=0 to StackTop - 1 do begin
	  ClipScreenR(R1,R,I);
	  Rectangle(R.A.X, R.A.Y, R.B.X, R.B.Y);
	end;
     end;
    end;

procedure TView.Triangle(x1,y1,x2,y2,x3,y3:integer);
begin
  XLine(x1,y1,x2,y2);
  XLine(x2,y2,x3,y3);
  XLine(x3,y3,x1,y1);
end;

procedure TView.XLine(x1, y1, x2, y2: Integer);
    Var
      I  : Integer;
      R  : TRect;
      R1 : Trect;
    begin
     if PaintState and Psc_Paintable > 0 then begin
        R1.Assign(x1,y1,x2,y2);
        MakeGlobalRect(R1,R1);
        For I:=0 to StackTop - 1 do begin
          ClipScreenR(R1,R,I);
          Line(R.A.X, R.A.Y, R.B.X, R.B.Y);
        end;
     end;
    end;
procedure TView.XBar(x1, y1, x2, y2: Integer);
    Var
      I  : Integer;
      R  : TRect;
      R1 : TRect;
      F  : Boolean;
      V  : ViewPortType;
    begin
     if PaintState and Psc_Paintable > 0 then begin
	R1.Assign(x1,y1,x2,y2);
        MakeGlobalRect(R1,R1);
	SetViewPort(0,0,ScreenX,ScreenY,ClipOn);
	For I:=0 to StackTop - 1 do begin
	  R := RStack^[I];
	  Dec(R.B.X);
	  Dec(R.B.Y);
	  R.InterSect(R1);
	  asm
	    mov   F,True
	    lea   di,R
	    mov   ax,ss:[di].TRect.A.X
	    or    ax,ss:[di].TRect.A.Y
	    or    ax,ss:[di].TRect.B.X
	    or    ax,ss:[di].TRect.B.Y
	    jnz   @1
	    mov   F,False
@1:
	  end;
	  if F then Bar(R.A.X, R.A.Y, R.B.X, R.B.Y);
	end;
     end;
    end;
procedure TView.XBox(R:TRect;Filled:Boolean);
begin
  if PaintState and Psc_Paintable > 0 then with R do case Filled of
    True : XBar(a.x,a.y,b.x,b.y);
    False: XRectangle(a.x,a.y,b.x,b.y);
  end; {case & with}
end;
procedure TView.XPutPixel(X, Y: Integer; Pixel: Word);
    Var
      I  : Integer;
      T  : TPoint;
      T1 : TPoint;
    begin
     if PaintState and Psc_Paintable > 0 then begin
	T1.X := X;
	T1.Y := Y;
	MakeGlobal(T1,T1);
	For I:=0 to StackTop - 1 do begin
	  ClipScreenP(T1,T,I);
	  PutPixel(T.X, T.Y, Pixel);
	end;
     end;
    end;
procedure TView.XWriteStr(X,Y,SX:Integer; Str:String);
    begin
      XWritePStr(x,y,sx,GetFontPtr(ViewFont),str);
    end;
procedure TView.XWritePStr(x,y,sx:integer; P:PFont; var str:string);
    Var
      I  : Integer;
      T  : TPoint;
      T1 : TPoint;
    begin
     if PaintState and Psc_Paintable > 0 then begin
	T1.X := X;
	T1.Y := Y;
	MakeGlobal(T1,T1);
	For I:=0 to StackTop - 1 do begin
	  ClipScreenP(T1,T,I);
	  WriteStr(T.X, T.Y, SX, Str, P);
	end;
     end;
    end;
procedure TView.XPrintStr(X,Y,SX:Integer; FontId:Word; Str:String);
    Var
      I  : Integer;
      T  : TPoint;
      T1 : TPoint;
      P  : PFont;
    begin
     if PaintState and Psc_Paintable > 0 then begin
	T1.X := X;
	T1.Y := Y;
	MakeGlobal(T1,T1);
	P := GetFontPtr(FontId);
	For I:=0 to StackTop - 1 do begin
	  ClipScreenP(T1,T,I);
	  WriteStr(T.X, T.Y, SX, Str, P);
	end;
     end;
    end;

procedure TView.XPrintOredStr(X,Y,SX:Integer; FontId:Word; Str:String);
    Var
      I  : Integer;
      T  : TPoint;
      T1 : TPoint;
      P  : PFont;
    begin
     if PaintState and Psc_Paintable > 0 then begin
	T1.X := X;
	T1.Y := Y;
	MakeGlobal(T1,T1);
	P := GetFontPtr(FontId);
	For I:=0 to StackTop - 1 do begin
	  ClipScreenP(T1,T,I);
	  WriteOredStr(T.X, T.Y, SX, Str, P);
	end;
     end;
    end;

procedure TView.XTilda;
var
  ix       : integer;
  tildapos : byte;
  fonth    : integer;
begin
  tildapos := pos('~',s);

  SetTextColor(fc,bc);
  if (tildapos > 0) and (tildapos < length(s)) then begin
    fonth := GetFontHeight(fontid);
    Delete(s,tildapos,1);
    SetColor(fc);
    ix := x+GetStringSize(fontid,copy(s,1,tildapos-1));
    inc(y,fonth+tildaGAP);
    XLine(ix,y,ix+GetStringSize(fontid,s[tildapos])-1,y);
    dec(y,fonth+1);
  end;
  XPrintStr(x,y,GetStringSize(fontid,s),fontid,s);
end;

procedure TView.XPutVIF(X,Y:Integer; Var BitMap);
    Var
      I  : Integer;
      T  : TPoint;
      T1 : TPoint;
    begin
     if PaintState and Psc_Paintable > 0 then begin
	T1.X := X;
	T1.Y := Y;
	MakeGlobal(T1,T1);
	For I:=0 to StackTop - 1 do begin
	  ClipScreenP(T1,T,I);
	  PutVIF(T.X, T.Y, BitMap);
	end;
     end;
    end;

procedure TView.XPutImage(X,Y:Integer; ImageId:Word);
    Var
      I  : Integer;
      R  : TPoint;
      R1 : TPoint;
      P  : PVifMap;
    begin
      if PaintState and Psc_Paintable > 0 then begin
        P := GetImagePtr(ImageId);
        XPutVIF(X,Y,P^);
      end;
    end;

{----------------------- PRIVATE TView PROCS ---------------------}
procedure TView.PaintUnderView;
var
  R : TRect;
begin
  if Owner <> NIL then begin
    GetBounds(R);
    Owner^.PaintUnderRect(@Self,R);
  end;
end;

procedure TView.PaintShow;
begin
  PaintView;
end;

procedure TView.PaintHide;
begin
  PaintUnderView;
  if Owner <> Nil then begin
   if Owner^.Current = @Self then begin
     Owner^.SelectNext(False);
     if Owner^.Current = @Self then Owner^.Current := Nil;
   end;
  end;
end;

procedure TView.PaintCursor(T:TPoint; AState:Word);
var
  F : Boolean;
begin
  F := RStack = Nil;
  State := State or Scf_CursorPainting;
  if F then PaintBegin;
  if PaintState and Psc_Paintable > 0 then begin
    SetWriteMode(XorPut);
    SetColor(Col_Cursor);
    if AState and Scf_CursorIns = 0 then begin
      inc(T.Y,ViewFontHeight);
      XLine(T.X, T.Y, T.X + ViewFontWidth, T.Y);
      dec(T.Y);
      XLine(T.X, T.Y, T.X + ViewFontWidth, T.Y);
    end else begin
      XLine(T.X, T.Y, T.X, T.Y + ViewFontHeight);
      inc(T.X);
      XLine(T.X, T.Y, T.X, T.Y + ViewFontHeight);
    end;
    SetWriteMode(NormalPut);
    State := State xor Scf_CursorOn;
  end;
  if F then PaintEnd;
  State := State and not Scf_CursorPainting;
end;

procedure TView.MakeCursorOn;
    begin
      if State and (Scf_CursorVis + Scf_CursorOn) = Scf_CursorVis then
	PaintCursor(CurPos,State);
    end;
procedure TView.MakeCursorOff;
    begin
      if State and (Scf_CursorVis + Scf_CursorOn) = (Scf_CursorVis + Scf_CursorOn) then
	PaintCursor(CurPos,State);
    end;
{---------------------------------------------------------------------------}
{->                     TGRAPHICAL GROUP                                  <-}
{---------------------------------------------------------------------------}
constructor TGroup.Init(Var R:Trect);
begin
  inherited Init(R);
  GetVisibleBounds(Clip);
  inc(Clip.B.X);
  inc(Clip.B.Y);
  GetTrueClip(TrueClip);
  Options      := Ocf_Selectable;
  EventMask    := $FFFF;
  ActiveGroups := Grp_AllGroups;
  ViewType     := vtGroup;
end;

destructor TGroup.Done;
begin
  Lock;
  while Top <> NIL do Dispose(Top,Done);
  inherited Done;
end;

function TGroup.GetHelpContext : word;
var
  hc:word;
begin
  GetHelpContext := hcNoContext;
  if HelpContext <> hcNoContext then GetHelpContext := HelpContext
    else if Current <> NIL then begin
      hc := Current^.GetHelpContext;
      if hc <> hcNoContext then GetHelpContext := hc;
    end; {if}
end;

procedure TGroup.BackProcess;
  procedure MultiTasker(P:PView);far;
  begin
    if P^.State and Scf_Backprocess > 0 then P^.BackProcess;
  end;
begin
  if (Top=NIL) then exit;
  ForEach(@MultiTasker);
end;

procedure TGroup.FitBounds;
var
  maxx,maxy:integer;
  R:TRect;
  VB:TRect;
  procedure FindMax(P:PView);far;
  begin
    P^.GetBounds(R);
    if R.B.X > maxx then maxx := R.B.X;
    if R.B.Y > maxy then maxy := R.B.Y;
  end;
begin
  maxx := 0;
  maxy := 0;
  ForEach(@FindMax);
  GetBounds(R);
  GetVisibleBounds(VB);
  R.B.X := R.A.X + maxx + 5 + (R.B.X-VB.B.X);
  R.B.Y := R.A.Y + maxy + 5 + (R.B.Y-VB.B.Y);
  ChangeBounds(R);
end;

procedure TGroup.GetTrueClip(var R:TRect);
begin
  R.Assign(0,0,Size.X + 1,Size.Y + 1);
end;

procedure TGroup.GetVisibleBounds;
begin
  GetExtent(R);
end;

procedure TGroup.ChangeBounds(var R:TRect);
var
  T:TPoint;
  OldR:TRect;
  procedure Bounder(P:PView);far;
  var
    b:byte;
    R1:TRect;
  begin
    P^.GetBounds(R1);
    b := P^.GrowMode;
    if b > 0 then begin
      if b and gmFixedHiX > 0 then R1.B.X := (R.B.X-R.A.X)-(Size.X-P^.Origin.X-P^.Size.X);
      if b and gmFixedHiY > 0 then R1.B.Y := (R.B.Y-R.A.Y)-(Size.Y-P^.Origin.Y-P^.Size.Y);
      if b and gmFixedLoX > 0 then R1.A.X := P^.Origin.X else R1.A.X := R1.B.X-P^.Size.X;
      if b and gmFixedLoY > 0 then R1.A.Y := P^.Origin.Y else R1.A.Y := R1.B.Y-P^.Size.Y;
    end;
    P^.ChangeBounds(R1);
  end;

begin
  Lock;
  ForEach(@Bounder);
  GetBounds(OldR);
  Origin := R.A;
  Size.X := R.B.X - R.A.X;
  Size.Y := R.B.Y - R.A.Y;
  CalcBounds(R);
  GetVisibleBounds(Clip);
  GetTrueClip(TrueClip);
  UnLock;
  if Owner <> NIL then Owner^.PaintUnderRect(@Self,OldR);
end;

procedure TGroup.HandleEvent(Var Event:TEvent);
    Var
      P : PView;
    procedure SendEvent(V:PView);
       begin
	 if V^.EventMask and Event.What > 0 then
           if not V^.GetState(Scf_Disabled) then V^.HandleEvent(Event);
       end;
    function ScanPreProcess(P:PView):Boolean; far;
       begin
	 ScanPreProcess := False;
	 if P^.Options and Ocf_PreProcess > 0 then begin
	   SendEvent(P);
	   ScanPreProcess := Event.What = EvNothing;
	 end;
       end;

    function ScanPostProcess(P:PView):Boolean; far;
       begin
	 ScanPostProcess := False;
	 if P^.Options and Ocf_PostProcess > 0 then begin
	   SendEvent(P);
	   ScanPostProcess := Event.What = EvNothing;
	 end;
       end;
    function IsMouseInThisView(P:PView):Boolean; far;
    begin
      IsMouseInThisView := P^.MouseInView(Event.Where) and (P^.State and Scf_Visible > 0);
    end;
    procedure SendAll(P:PView); far;
    begin
      SendEvent(P);
    end;
    begin
      inherited HandleEvent(Event);
      if Event.What and EventsPositional > 0 then begin
	Phase := Phc_Positional;
	P := FirstThat(@IsMouseInThisView);
	if (P<>Nil) then if P^.GetState(Scf_Visible) then SendEvent(P);
      end else if Event.What and EventsFocused > 0 then begin
	Phase := Phc_PreProcess;
	P := FirstThat(@ScanPreProcess);
	if P<>Nil then exit;
	Phase := Phc_Focused;
	if Current <> Nil then SendEvent(Current);
	if Event.What = EvNothing then exit;
	Phase := Phc_PostProcess;
	P := FirstThat(@ScanPostProcess);
	if P<>Nil then exit;
      end else ForEach(@SendAll);
    end;

{procedure TGroup.PostEvent(Var Event:TEvent);
begin
  inherited PostEvent(Event);
  if Current<>NIL then
    if Current^.EventMask and Event.What > 0 then Current^.PostEvent(Event);
end;}

procedure TGroup.SetData(Var Rec);
    Var
      PR : Pointer;
    procedure SubSetData(P:PView); far;
      var
        size:word;
      begin
        size := P^.DataSize;
	if size > 0 then begin
          P^.SetData(PR^);
          inc(Word(PR),size);
        end;
      end;
    begin
      PR := @Rec;
      ForEach(@SubSetData);
    end;
procedure TGroup.GetData(Var Rec);
var
  PR : Pointer;
  procedure SubGetData(P:PView); far;
  var
    size:word;
  begin
    size := P^.DataSize;
    if size > 0 then begin
      P^.GetData(PR^);
      inc(Word(PR),size);
    end;
  end;
begin
  PR := @Rec;
  ForEach(@SubGetData);
end;

function TGroup.DataSize:Word;
    Var
      W : Word;
    procedure SubDataSize(P:PView); far;
      begin
	inc(W,P^.DataSize);
      end;
    begin
      W := 0;
      ForEach(@SubDataSize);
      DataSize := w;
    end;

procedure TGroup.GrpSetData(GrpId:Word; Var Rec);
    Var
      PR : Pointer;
    procedure SubSetData(P:PView); far;
      begin
	P^.SetData(PR^);
	inc(Word(PR),P^.DataSize);
      end;
    begin
      PR := @Rec;
      GrpForEach(GrpId,@SubSetData);
    end;
procedure TGroup.GrpGetData(GrpId:Word; Var Rec);
    Var
      PR : Pointer;
    procedure SubGetData(P:PView); far;
      begin
	P^.GetData(PR^);
	inc(Word(PR),P^.DataSize);
      end;
    begin
      PR := @Rec;
      GrpForEach(GrpId,@SubGetData);
    end;
function TGroup.GrpDataSize(GrpId:Word):Word;
    Var
      W : Word;
    procedure SubDataSize(P:PView); far;
      begin
	inc(W,P^.DataSize);
      end;
    begin
      W := 0;
      GrpForEach(GrpId,@SubDataSize);
      GrpDataSize := w;
    end;

function TGroup.Execute:Word;
var
  E : TEvent;
begin
  repeat
    SetState(Scf_Modal,True);
    repeat
      GetEvent(E);
      if E.What <> EvNothing then HandleEvent(E);
    until State and Scf_Modal = 0;
  until Valid(ExitCode);
  Execute := ExitCode;
end;

function TGroup.Valid(acmd:word):boolean;
  function IsAngry(P:PView):boolean;far;
  begin
    IsAngry := not P^.Valid(acmd);
  end;
begin
  Valid := FirstThat(@IsAngry) = NIL;  {optimized by ssg}
end;

function TGroup.ExecView(P:PView):Word;
var
  Inserted : Boolean;
begin
  if P<>Nil then begin
    Inserted := P^.Owner <> NIL;
    if Inserted and Not P^.GetState(Scf_Focused) then P^.Select
                                                 else Insert(P);
    ExecView := P^.Execute;
    if Not Inserted then Delete(P); {ssg was here}
  end;
  {and also Bill}
end;

procedure TGroup.SetState(AState:Word; Enable:Boolean);
  procedure SubSetState(P:PView); far;
  begin
    P^.SetState(Scf_Exposed,Enable);
  end;
begin
  TView.SetState(AState,Enable);
  if AState and Scf_Exposed = Scf_Exposed then ForEach(@SubSetState);
  if AState and Scf_Focused = Scf_Focused then
    if Current <> NIL then Current^.SetState(Scf_Focused,Enable);
end;
procedure TGroup.Lock;
begin
  inc(LockCount);
end;

procedure TGroup.UnLock;
begin
  if LockCount > 0 then begin
    dec(LockCount);
    if LockCount = 0 then PaintView;
  end;
end;

procedure TGroup.ZoomOut(P:PView);
var
  R:TRect;
  x1,y1,x2,y2:integer;
  ix1,iy1,ix2,iy2:integer;
  ox1,oy1,ox2,oy2:integer;
  x,y:integer;
  temp:longint;
  n:byte;
begin
  if not GetSystem(sys_ZoomEffect) then exit;
  P^.GetExtent(R);
  P^.MakeGlobalRect(R,R);
  SetViewPort(0,0,ScreenX,ScreenY,False);
  x := Mouse_GetX;
  y := Mouse_GetY;
  x1 := r.a.x;
  y1 := r.a.y;
  x2 := r.b.x;
  y2 := r.b.y;
  ix1 := (R.A.X - x) div ZoomRectCount;
  ix2 := (R.B.X - x) div ZoomRectCount;
  iy1 := (R.A.Y - y) div ZoomRectCount;
  iy2 := (R.B.Y - y) div ZoomRectCount;
  Mouse_Hide;
  SetColor(cLightGray);
  SetWriteMode(XorPut);
  ox1 := x1;
  ox2 := x2;
  oy1 := y1;
  oy2 := y2;
  for n := 1 to ZoomRectCount do begin
    Rectangle(x1,y1,x2,y2);
    Sync;
    Rectangle(x1,y1,x2,y2);
    dec(x1,ix1);
    dec(y1,iy1);
    dec(x2,ix2);
    dec(y2,iy2);
  end;
  Mouse_Show;
  SetWriteMode(NormalPut);
end;

procedure TGroup.ZoomView(P:PView);
var
  R:TRect;
  x1,y1,x2,y2:integer;
  ix1,iy1,ix2,iy2:integer;
  ox1,oy1,ox2,oy2:integer;
  x,y:integer;
  temp:longint;
  n:byte;
begin
  if not GetSystem(Sys_ZoomEffect) then exit;
  P^.GetExtent(R);
  P^.makeGlobalRect(R,R);
  SetViewPort(0,0,ScreenX,ScreenY,False);
  x := Mouse_GetX;
  y := Mouse_GetY;
  x1 := x;
  y1 := y;
  x2 := x1;
  y2 := y1;
  ix1 := (R.A.X - x1) div ZoomRectCount;
  ix2 := (R.B.X - x1) div ZoomRectCount;
  iy1 := (R.A.Y - y1) div ZoomRectCount;
  iy2 := (R.B.Y - y1) div ZoomRectCount;
  Mouse_Hide;
  SetColor(cLightGray);
  SetWriteMode(XorPut);
  ox1 := x1;
  ox2 := x2;
  oy1 := y1;
  oy2 := y2;
  for n := 1 to ZoomRectCount do begin
    Rectangle(x1,y1,x2,y2);
    Sync;
    Rectangle(x1,y1,x2,y2);
    inc(x1,ix1);
    inc(y1,iy1);
    inc(x2,ix2);
    inc(y2,iy2);
  end;
  Mouse_Show;
  SetWriteMode(NormalPut);
end;

procedure TGroup.Insert(View:PView);
var
  R  : TRect;
  xs,ys:integer;
  P : PView;
begin
   if (View<>Nil) then begin
     if View^.Owner <> NIL then exit;
     GetVisibleBounds(R);
     xs := R.B.X - R.A.X;
     ys := R.B.Y - R.A.Y;
     if View^.Options and Ocf_CenterX > 0 then View^.Origin.X := (xs - View^.Size.X) div 2;
     if View^.Options and Ocf_CenterY > 0 then View^.Origin.Y := (ys - View^.Size.Y) div 2;
     inc(View^.Origin.X,R.A.X);
     inc(View^.Origin.Y,R.A.Y);
     if Top = Nil then begin
       Top        := View;
       View^.Next := View;
     end else begin
       if (View^.Options and Ocf_AlwaysOnTop = 0) and (Top^.Options and Ocf_AlwaysOnTop > 0) then begin
         P := GetMostTop;
         View^.Next := P^.Next;
         P^.Next := View;
       end else begin
         View^.Next := Top^.Next;
         Top^.Next  := View;
         Top        := View;
       end;
     end;
     View^.Owner := @Self;

     if (View^.Options and Ocf_ZoomEffect > 0) then ZoomView(View);

     View^.SetState(Scf_Exposed,GetState(Scf_Exposed));
     if View^.GetState(Scf_Visible) then begin
       View^.PaintState := 0;
       if View^.IsSelectable then View^.Select;
       if View^.PaintState = 0 then View^.PaintView;
     end;
   end;
end;
procedure TGroup.InsertBlock(P:String);
var
  Index:integer;
begin
  Index := 1;
  repeat
    Self.Insert(PView(StrPtr(P,Index)));
    inc(Index,4);
  until Index >= Length(P);
end;
procedure TGroup.Delete(View:PView);
var
  P : PView;
begin
  if View = NIL then exit;
  if View^.Owner <> @Self then exit;
  View^.SetState(Scf_Exposed,False);
  if LockCount = 0 then View^.Hide;
  View^.State := 0;
  if View^.Next = View then begin
    Top     := Nil;
    Current := Nil;
  end else begin
    P := View^.Prev;
    if View = Top then Top := P;
    P^.Next := View^.Next;
    View^.Next  := Nil;
    View^.Owner := Nil;
  end;
  View^.Show;
  if View^.Options and Ocf_ZoomEffect > 0 then ZoomOut(view);
end;

function TGroup.GetMostTop;
var
  P:PView;
begin
  P := Top^.Prev;
  while (P <> Top) and (P^.Options and Ocf_AlwaysOnTop > 0) do P := P^.Prev;
  if P = Top then P := Top^.Prev;
  GetMostTop := P;
end;

procedure TGroup.MakeTop(P:PView);
var
  MostTop : PView;
begin
  if P=Nil then Exit;
  if Top = P then exit;
  P^.Prev^.Next := P^.Next; {removing old link}
  if (P^.Options and Ocf_AlwaysOnTop = 0) and (Top^.Options and Ocf_AlwaysOnTop > 0) then begin
    MostTop := GetMostTop;
    P^.Next := MostTop^.Next;
    MostTop^.Next := P;
  end else begin
    P^.Next  := Top^.Next;
    Top^.Next := P;
    Top := P;
  end;
end;

procedure TGroup.MakeGroupActive(Id:Word; Active:Boolean);
    begin
      if Active then ActiveGroups := ActiveGroups or Id
		else ActiveGroups := ActiveGroups and Not Id;
    end;

procedure TGroup.ForEach(Action:Pointer);
    var
      P : PView;
    begin
      if Top = Nil then exit;
      P := Top;
      repeat
	P := P^.Next;
	if P = NIL then exit;
	asm
	  les   di,P
	  push  es
	  push  di
	  mov   ax,[bp]
	  push  ax
	  call  dword ptr Action
	end;
      until P=Top;
    end;
procedure TGroup.GrpForEach(GrpId:Word; Action:Pointer);
    var
      P : PView;
    begin
      if Top = Nil then exit;
      P := Top;
      repeat
	P := P^.Next;
	if P = NIL then exit;
        if P^.GetGroupId and GrpId <> 0 then asm
	  les   di,P
	  push  es
	  push  di
	  mov   ax,[bp]
	  push  ax
	  call  dword ptr Action
	end;
      until P=Top;
    end;
function TGroup.FirstThat(Action:Pointer):PView;
    Var
      P : PView;
      F : Boolean;
    begin
      FirstThat := Nil;
      if Top = Nil then exit;
      P := Top;
      repeat
	asm
	  les   di,P
	  push  es
	  push  di
	  mov   ax,[bp]
	  push  ax
	  call  dword ptr Action
	  mov   F,al
	end;
	if F then begin
	  FirstThat := P;
	  exit;
	end;
	P := P^.Prev;
      until P=Top;
    end;
function TGroup.GrpFirstThat(grpId:Word; Action:Pointer):PView;
    Var
      P : PView;
      F : Boolean;
    begin
      GrpFirstThat := Nil;
      if Top = Nil then exit;
      P := Top;
      repeat
	P := P^.Prev;
	if P^.GetGroupId and GrpId > 0 then begin
	  asm
	    les   di,P
	    push  es
	    push  di
	    mov   ax,[bp]
	    push  ax
	    call  dword ptr Action
	    mov    F,al
	  end;
	  if F then begin
	    GrpFirstThat := P;
	    exit;
	  end;
	end;
      until P=Top;
    end;
function TGroup.GetViewPtr(Id:Byte):PView;
    function ScanForViewId(P:PView):Boolean;
      begin
	ScanforViewId := P^.GetViewId = Id;
      end;
    begin
      GetViewPtr := FirstThat(@ScanForViewId);
    end;
function TGroup.SetCurrent(P:PView):Boolean;
    Var
      FIN,FOUT : Boolean;
    begin
     SetCurrent := False;
     if P=Nil then exit;
     if P=Current then exit;
     if P^.IsSelectable then begin
      FOUT := True;
      FIN  := True;
      FOUT := Message(@Self,evBroadcast,cmReleasedFocus,Current)=NIL;
      if FOUT then FIN := Message(@Self,evBroadcast,cmReceivedFocus,P)=NIL;
      if FOUT and FIN and (Current <> NIL) then
        Current^.SetState(Scf_Focused,False);

      if FOUT and FIN then begin
	 if (P^.Options and Ocf_TopSelect = Ocf_TopSelect)
	    then MakeTop(P);
	 P^.PaintState := 0;
	 P^.SetState(Scf_Focused,True);
	 Current := P;
	 SetCurrent := True;
	 if P^.Options and Ocf_TopSelect = Ocf_TopSelect then begin
	   P^.Options := P^.Options or Ocf_InSelectPaint;
	   P^.PaintView;
	   P^.Options := P^.Options and Not Ocf_InSelectPaint;
	 end;
      end;
     end;
    end;

procedure TGroup.SelectNext(ANext:Boolean);
var
  P : PView;
begin
  if Current = Nil then exit;
  if ANext then begin
    P := Current^.Next;
    while P<>Current do begin
     if P^.IsSelectable then begin
      P^.Select;
      exit;
     end; {if}
     P := P^.Next;
    end; {while}
  end else begin
    P := Current^.Prev;
    while P<>Current do begin
     if P^.IsSelectable then begin
      P^.Select;
      exit;
     end; {if}
     P := P^.Prev;
    end; {while}
  end;
end;

procedure TGroup.Paint;
begin
  PaintState := Psc_PaintStarted;
  PaintSubViews;
  PaintState := Psc_PaintEnded;
end;

{this procedure draws part of subViews that in clip and does not match SV}
procedure TGroup.PaintUnderRect(SV:PView; Var R:Trect);
var
  P:PView;
begin
  Clip := R;
  inc(Clip.B.X);
  inc(Clip.B.Y);
  TrueClip := Clip;
  P := Top^.Next;
  while P <> SV do begin
    P^.Paint;
    P := P^.Next;
  end;
  GetVisibleBounds(Clip);
  inc(Clip.b.x);
  inc(Clip.b.y);
  GetTrueClip(TrueClip);
end;

procedure TGroup.PaintSubViews;
var
  P:PView;
begin
  P := Top;
  repeat
    if Options and Ocf_InSelectPaint = 0 then P^.PaintView
      else if P^.PaintState = 0 then P^.PaintView;
    P := P^.Prev;
  until P = Top;
end;

{---------------------------------------------------------------------------}
{->                          W I N D O W                                  <-}
{---------------------------------------------------------------------------}
constructor TWindow.Init;
begin
  inherited Init(R);
  Options := Options or
	     Ocf_FirstClick or
	     Ocf_TopSelect  or
	     Ocf_Selectable or
	     Ocf_Close      or
	     Ocf_Move       or
	     Ocf_ZoomEffect or
	     Ocf_Resize;
  MinSize     := Wnd_MinSize;
  Header      := NewStr(AHdr);
  MaxSize.X   := ScreenX;
  MaxSize.Y   := ScreenY;
  ViewType    := VtWindow;

  {Frame initialization}
  GetVisibleBounds(R);
  R.Move(-r.a.x,-r.a.y);
  InitFrame(R);
  with Frame^ do begin
    GrowMode  := gmFixedAll;
    MaxSize   := MaxSize;
    MinSize   := MinSize;
  end;
  Insert(Frame);
  {clip assign}
  GetVisibleBounds(Clip);
end;

procedure TWindow.Zoom;
var
  R:TRect;
begin
  if ((Size.X = MaxSize.X) and (Size.Y = MaxSize.Y)) and not ZoomRect.Empty then ChangeBounds(ZoomRect) else begin
    GetBounds(ZoomRect);
    R.Assign(0,0,MaxSize.X,MaxSize.Y);
    ChangeBounds(R);
  end;
end;

destructor TWindow.Done;
begin
  if Header <> NIL then begin
    DisposeStr(Header);
    Header := NIL;
  end;
  inherited Done;
end;

procedure TWindow.Paint;
begin
  inherited Paint;
  PaintFrame;
end;

procedure TWindow.PaintFrame;
const
  barnormal = Frm_Size;
  barheader = Frm_HeaderSize+Frm_ShadowCount;
  realbar   = Frm_Size+Frm_ShadowCount*2+1;
  procedure PaintV(x,y:integer);near;
  begin
    SetColor(cDarkGray);
    XLine(x,y,x,y+barnormal);
    SetColor(cWhite);
    XLine(x+1,y,x+1,y+barnormal);
  end;
  procedure PaintH(x,y:integer);near;
  begin
    SetColor(cDarkGray);
    XLine(x,y,x+barnormal,y);
    SetColor(cWhite);
    XLine(x,y+1,x+barnormal,y+1);
  end;
var
  R:TRect;
  hdrstart,hdrend:integer;
  hdrcap:integer;
  hdrsize:integer;
  hdrcolor:integer;
  isfocused:boolean;
  n:integer;
begin
  PaintBegin;
  GetExtent(R);
  hdrstart := realbar;
  hdrend   := Size.X-realbar;

  {colors adjusting now}
  SetColor(cBlack);
  isfocused := GetState(Scf_Focused);
  if isFocused then hdrcolor := Col_Hdr
               else hdrcolor := cLightGray;
  SetTextColor(cBlack,hdrcolor);
  SetFillStyle(SolidFill,hdrColor);
  {outer rects of frame}
  XBox(R,False);
  R.Grow(-1,-1);
  ShadowBox(R,True);
  R.Grow(-1,-1);

  {inner bars}
  SetColor(hdrcolor);
  for n:=1 to barnormal do begin
    XBox(R,False);
    R.Grow(-1,-1);
  end;

  {resize stick visualisation}
  ShadowBox(R,False);

  {gadgets are now painting}
  if Options and Ocf_ReSize > 0 then begin
    PaintV(Frm_ReSizerRange,1);
    PaintV(Frm_ReSizerRange,Size.Y-realbar+1);
    PaintV(Size.X-Frm_ReSizerRange-1,1);
    PaintV(Size.X-Frm_ReSizerRange-1,Size.Y-realbar+1);
    PaintH(1,Frm_ReSizerRange);
    PaintH(1,Size.Y-Frm_ReSizerRange);
    PaintH(Size.X-realbar+1,Frm_ReSizerRange);
    PaintH(Size.X-realbar+1,Size.Y-Frm_ReSizerRange);
    R.Assign(Size.X-realbar-Clb_XSize,realbar,Size.X-realbar,realbar+Clb_YSize);
    ShadowBox(R,True);
    R.Grow(-1,-1);
    XBox(R,True);
    R.Grow(-2,-2);
    ShadowBox(R,True);
    dec(hdrend,Clb_XSize+1);
  end;
  if Options and Ocf_Close > 0 then begin
    inc(hdrstart,Clb_XSize+1);
    R.Assign(realbar,realbar,realbar+Clb_Xsize,realbar+Clb_YSize);
    ShadowBox(R,True);
    R.Grow(-1,-1);
    XBox(R,True);
    R.Grow(-1,-Clb_Bar);
    ShadowBox(R,True);
  end;

  {header is painting}
  R.Assign(hdrstart,realbar,hdrend,Frm_HeaderSize+1);
  ShadowBox(R,True);
  R.Grow(-1,-1);
  XBox(R,True);
  if Header <> NIL then begin
    hdrsize := GetStringSize(ViewFont,Header^);
    hdrcap  := (hdrend-hdrstart)-2;
    inc(hdrstart);
    if hdrsize > hdrcap then hdrsize := hdrcap;
    hdrcap := hdrstart + ((hdrcap-hdrsize) div 2);
    if hdrcap > hdrstart then hdrstart := hdrcap;
    XPrintStr(hdrstart,realbar+4,hdrsize,ViewFont,header^);
  end;
  PaintEnd;
end;

procedure TWindow.InitFrame;
begin
  Frame := New(PView,Init(R));
end;

procedure TWindow.GetVisibleBounds(var R:TRect);
const
  temp = Frm_ShadowCount*2 + Frm_Size;
begin
  r.a.y := Frm_HeaderSize+2;
  r.a.x := temp+1;
  r.b.x := Size.X-temp;
  r.b.y := Size.Y-temp;
end;

procedure TWindow.HandleGadgets(var Event:TEvent);
const
  realbar = Frm_Size+Frm_ShadowCount*2+1;
var
  T:TEvent;
  R:TRect;
  Pressed:boolean;
  function HandleThisShit:boolean;
  begin
    HandleThisShit := False;
    if not R.Contains(T.Where) then exit;
    ClearEvent(Event);
    Pressed := true;
    PaintBegin;
    ShadowBox(R,not Pressed);
    Mouse_Show;
    repeat
      GetEvent(T);
      if T.What = evMouseMove then begin
	MakeLocal(T.Where,T.Where);
	if R.Contains(T.Where) and not Pressed then begin
	   Pressed := True;
	   Mouse_Hide;
	   ShadowBox(R,not Pressed);
	   Mouse_Show;
	end;
	if not R.Contains(T.Where) and Pressed then begin
	   Pressed := false;
	   Mouse_Hide;
	   ShadowBox(R,not Pressed);
	   Mouse_Show;
	end;
      end; {big if}
    until T.Buttons = 0;
    Mouse_Hide;
    ShadowBox(R,True);
    PaintEnd;
    HandleThisShit := Pressed;
  end;

begin
  MakeLocal(Event.Where,T.Where);
  if Options and Ocf_Close > 0 then begin
    R.Assign(realbar,realbar,realbar+Clb_XSize,realbar+Clb_YSize);
    if HandleThisShit then begin
      ClearEvent(Event);
      Message(@Self,evCommand,cmClose,@Self);
      exit;
    end;
  end;
  if Options and Ocf_ReSize > 0 then begin
    R.Assign(Size.X-realbar-Clb_XSize,realbar,Size.X-realbar,realbar+Clb_YSize);
    if HandleThisShit then begin
      ClearEvent(Event);
      Zoom;
      exit;
    end;
  end;
end;

procedure TWindow.HandleDrag(var Event:TEvent);
const
  realbar = Frm_Size+Frm_ShadowCount*2+1;
var
  T:TEvent;
  R:TRect;
  hdrstart,hdrend:integer;
  oldpos:TPoint;
begin
  MakeLocal(Event.Where,T.Where);
  hdrstart := realbar+(Clb_XSize+1)*byte((Options and Ocf_Close > 0));
  hdrend   := Size.X-realbar-Clb_YSize*byte((Options and Ocf_Resize > 0));
  if Options and Ocf_Move > 0 then begin
    R.Assign(hdrstart,realbar,hdrend,Frm_HeaderSize+1);
    if R.Contains(T.Where) then begin
      oldpos := Event.Where;
      repeat
        repeat
          PointingDevice^.GetEvent(Event);
        until Event.What <> evNothing;
        if Event.Buttons = 0 then begin
          ClearEvent(Event);
          exit;
        end;
      until (Event.What = evMouseMove) and (Event.Buttons > 0);
      Event.Where := oldpos;
      Drag(Event,dmDragMove+dmLimitLoY);
      ClearEvent(Event);
      exit;
    end;
  end;
  if Options and Ocf_ReSize > 0 then begin
    R.Assign(Size.X-Frm_ReSizerRange,Size.Y-Frm_ReSizerRange,Size.X,Size.Y);
    if R.Contains(T.Where) then begin
      Drag(Event,dmDragGrow);
      ClearEvent(Event);
      exit;
    end;
  end;
end;

procedure TWindow.HandleEvent(Var Event:TEvent);

  function SelectViewThruCursor(SV:PView):Boolean;
    Var
      PX : PSortedByX;
      PY : PSortedByY;
      NV : PView;

    function InitSorteds:Boolean;
       begin
	 New(PX,Init(20,20));
	 New(PY,Init(20,20));
         PX^.Duplicates := True;
	 PY^.Duplicates := True;
	 InitSorteds    := True;
       end;
     procedure DoneSorteds;
       begin
	 PX^.DeleteAll;
	 PY^.DeleteAll;
	 Dispose(PX,Done);
	 Dispose(PY,Done);
       end; {proc}

     procedure SortViews(P:PView); far;
       begin
	 if P^.IsSelectable then begin
	   PX^.Insert(P);
	   PY^.Insert(P);
	 end; {if}
       end; {proc}

     Function GetUpView(V:PView):PView;
	Var
	  IY    : Integer;
	  V1    : PView;
	  I     : Integer;
	  R,R1  : TRect;
	begin
	  GetUpView := NIL;
	  IY := PY^.IndexOf(V);
	  if (IY = -1) or (IY = 0) then exit;
	  V^.GetBounds(R);
	  For I:=IY-1 downto 0 do begin
	    V1 := PY^.At(I);
	    V1^.GetBounds(R1);
	    R1.A.Y := R.A.Y;
	    R1.B.Y := R.B.Y;
	    R1.Intersect(R);
	    if Not R1.Empty then begin
	      GetUpView := V1;
	      exit;
	    end; {if}
	  end; {for}
	end; {proc}

     Function GetDownView(V:PView):PView;
	Var
	  IY    : Integer;
	  V1    : PView;
	  I     : Integer;
	  R,R1  : TRect;
	begin
	  GetDownView := NIL;
	  IY := PY^.IndexOf(V);
	  if (IY = -1) or (IY = PY^.Count-1) then exit;
	  V^.GetBounds(R);
	  For I:=IY+1 to PY^.Count - 1 do begin
	    V1 := PY^.At(I);
	    V1^.GetBounds(R1);
	    R1.A.Y := R.A.Y;
	    R1.B.Y := R.B.Y;
	    R1.Intersect(R);
	    if Not R1.Empty then begin
	      GetDownView := V1;
	      exit;
	    end; {if}
	  end; {for}
	end; {proc}

     Function GetLeftView(V:PView):PView;
	Var
	  IX    : Integer;
	  V1    : PView;
	  I     : Integer;
	  R,R1  : TRect;
	begin
	  GetLeftView := NIL;
	  IX := PX^.IndexOf(V);
	  if (IX = -1) or (IX = 0) then exit;
	  V^.GetBounds(R);
	  For I:=IX-1 Downto 0 do begin
	    V1 := PX^.At(I);
	    V1^.GetBounds(R1);
	    R1.A.X := R.A.X;
	    R1.B.X := R.B.X;
	    R1.Intersect(R);
	    if Not R1.Empty then begin
	      GetLeftView := V1;
	      exit;
	    end; {if}
	  end; {for}
	end; {proc}

     Function GetRightView(V:PView):PView;
	Var
	  IX    : Integer;
	  V1    : PView;
	  I     : Integer;
	  R,R1  : TRect;
	begin
	  GetRightView := NIL;
	  IX := PX^.IndexOf(V);
	  if (IX = -1) or (IX = PX^.Count-1) then exit;
	  V^.GetBounds(R);
	  For I:=IX+1 to PX^.Count - 1 do begin
	    V1 := PX^.At(I);
	    V1^.GetBounds(R1);
	    R1.A.X := R.A.X;
	    R1.B.X := R.B.X;
	    R1.Intersect(R);
	    if Not R1.Empty then begin
	      GetRightView := V1;
	      exit;
	    end; {if}
	  end; {for}
	end; {proc}

       begin {Proc begin}
	 SelectViewThruCursor := False;
	 if SV = NIL then exit;
	 if Not InitSorteds then exit;
	 ForEach(@SortViews);
	 Case Event.Keycode of
	   KbUp        : NV := GetUpView(SV);
	   KbDown      : NV := GetDownView(SV);
	   KbLeft,
	   KbCtrlLeft  : NV := GetLeftView(SV);
	   KbRight,
	   KbCtrlRight : NV := GetRightView(SV);
	 end;
	 DoneSorteds;
	 if NV <> NIL then NV^.Select;
	 SelectViewThruCursor := NV <> NIL;
       end;

var
  b:byte;
  S:String;
begin
  inherited HandleEvent(Event);
  if Event.What = evMouseDown then HandleGadgets(Event);
  if Event.What = evMouseDown then HandleDrag(Event);
  case Event.What of
    evKeyDown : case Event.KeyCode of
      KbAltF4    : Message(@Self,evCommand,cmClose,@Self);
      KbTab,kbEnter : SelectNext(True);
      KbShiftTab : SelectNext(False);
      kbF5       : if Options and Ocf_ReSize > 0 then Zoom;
      kbCtrlF5   : Drag(Event,dmDragMove+dmLimitLoY);
      kbCtrlF6   : Drag(Event,dmDragGrow+dmLimitHiX+dmLimitHiY);
      KbUp,
      KbDown,
      KbLeft,
      KbCtrlLeft,
      KbRight,
      KbCtrlRight : if Not SelectViewThruCursor(Current) then exit;
      else exit;
    end;
    evCommand:
      case Event.Command of
	cmClose:if Options and Ocf_Close = Ocf_Close then
		     if GetState(Scf_Modal) then EndModal(cmClose)
		     else if Valid(cmClose) then begin
		       EventWait;
		       ClearEvent(Event);
		       Dispose(PWindow(@Self),Done);
		       Exit;
		     end; {small if}
      else exit;
      end; {evCommand case}
  else
    exit;
  end;
  ClearEvent(Event);
end;

{procedure TWindow.PostEvent(Var Event:TEvent);
    begin
      inherited PostEvent(Event);
    end;}
procedure TWindow.SetState(AState:Word; Enable:Boolean);
  procedure SubSet(P:PView);far;
  begin
    P^.PaintState := 0;
    P^.SetState(Scf_Active,Enable);
  end;
begin
  TGroup.SetState(AState,Enable);
  if AState and Scf_Focused > 0 then begin
    if not Enable then PaintFrame;
    ForEach(@SubSet);
  end;
end;
{---------------------------------------------------------------------------}
{->                        B A C K G R O U N D                            <-}
{---------------------------------------------------------------------------}
constructor TBackground.Init(Var R:TRect;var hDC : TBackDC);
    begin
      TView.Init(R);
      AssignDC(hDC);
      EventMask := evMouseUp or evMouseDown;
      Options   := Ocf_PostProcess;
      ViewType  := VtBackground;
{      Center    := GetCrtc(4);
      StartCenter := Center;}
    end;

procedure TBackground.HandleEvent(var Event:TEvent);
var
  E:TEvent;
{  Start:TPoint;
const
  HDelta = 2;}
begin
  case Event.What of
    evMouseUp : if Event.Double then begin
	E.What    := evCommand;
	E.Command := cmBackgroundClicked;
	E.InfoPtr := @Self;
	PutEvent(E);
	ClearEvent(Event);
     end else exit;
{    evMouseMove : if Event.Buttons > 0 then begin
                    Start := Event.Where;
                    OutCrtc($11,GetCrtc($11) and not $80);
                    repeat
                      GetMouseEvent(Event);
                      if Center < StartCenter+HDelta then
                      if Event.Where.X < Start.X then inc(Center);
                      if Center > StartCenter-HDelta then
                      if Event.Where.X > Start.X then dec(Center);
                      Start := Event.Where;
                      OutCrtc(4,Center);
                      Sync;
                    until Event.Buttons = 0;
                    OutCrtc($11,GetCrtc($11) or $80);
                  end else exit;}
    else exit;
  end; {case}
  {ClearEvent(Event);}
end;

procedure TBackGround.AssignDC(var hDC:TBackDC);
begin
  DC := hDC;
  PaintView;
end;

procedure TBackGround.Paint;
   var
     R:TRect;
     x,y:integer;
     P : PVifMap;
    begin
      PaintBegin;
	GetExtent(R);
	case DC.Style of
	  bsSolid  : begin
		      SetFillStyle(SolidFill,DC.SColor);
		      XBox(R,True);
		     end;
	  bsPattern: begin
		       SetFillStyle(DC.Pattern,DC.PColor);
		       XBox(R,True);
		     end;
	  bsBitMap: begin
		      if DC.BitMapId <> 0 then P := GetImagePtr(DC.BitMapId)
					  else P := Nil;
		      if P <> NIL then if DC.Tiled then begin
			 x := 0;
			 y := 0;
			 while y<=ScreenY do begin
			   while x<=ScreenX do begin
			     XPutVIF(x,y,P^);
			     inc(x,P^.XSize);
			   end;  {small while}
			   inc(y,P^.YSize);
			   x := 0;
			 end; {big while}
		      end else begin
			XPutVIF(0,0,P^);
			SetFillStyle(SolidFill,cBlack);
			if P^.YSize < ScreenY then XBar(0,P^.YSize,ScreenX,ScreenY);
			if P^.XSize < ScreenX then XBar(P^.XSize,0,ScreenX,P^.YSize);
		      end;
		    end;
	  end; {case}
      PaintEnd;
    end;

begin
  asm       {Correction of TRect.Intersect}
    mov     ax,Seg Objects.TRect.Assign
  {$IFDEF DPMI}
    add     ax,SelectorInc
  {$ENDIF}
    mov     es,ax
    mov     di, offset Objects.TRect.Assign
    mov     byte ptr es:[di-20],$7F
    mov     byte ptr es:[di-10],$7E
  end;
  New(RStackCache);
end.
