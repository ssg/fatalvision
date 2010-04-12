{
Name    : Tools 4.37d
Purpose : Basic objects
Date    : 27th Jun 93
Time    : 03:19
Coder   : SSG

Update Info:
------------
 6th Feb 95 - 01:56 - Removed TXLabel and added font support to TLabel...
20th Aug 95 - 00:06 - Revised TListViewer and TFormattedLister...
 6th Mar 96 - 18:56 - Removed many unnecessary things...
 7th Mar 96 - 00:47 - Retouched code a bit...
 8th Mar 96 - 01:47 - Made menu objects much more flexible...
 8th Mar 96 - 03:36 - Optimized listviewer...
 8th Mar 96 - 01:59 - Removed many unnecessary things...
 9th Mar 96 - 17:22 - Changed parameter decl of MessageBox...
10th Mar 96 - 02:09 - *** Fixed a bug in TGenericButton...
10th Mar 96 - 04:09 - Added TInputLine...
10th Mar 96 - 15:37 - Changed TInputBox...
10th Mar 96 - 18:41 - Revised...
10th Mar 96 - 18:57 - removed unnecessary things...
12th Mar 96 - 12:31 - Updated TSingleCheckBox....
16th Mar 96 - 16:48 - bi$iiler...
18th Mar 96 - 01:19 - removed xinits...
25th Mar 96 - 14:25 - *** fixed a bug in tlistviewer...
27th Mar 96 - 16:54 - *** fixed a bug in tinputline...
28th May 96 - 23:13 - *** fixed a bug in tlistviewer...
29th May 96 - 14:15 - added font support to procview...
31nd May 96 - 21:45 - Removed screensaver support...
 1nd Jun 96 - 03:15 - Removed ctx*.*...
25th Jun 96 - 01:49 - Got consoleview here...
26th Jun 96 - 01:24 - Changed definition of inputbox...
27th Jun 96 - 18:48 - Removed unnecessary code...
20th Aug 96 - 19:53 - *** fixed a bug in tlistviewer...
27th Sep 96 - 01:51 - Added TFormattedLister...
27th Sep 96 - 15:52 - *** fixed a bug in accelerator...
27th Sep 96 - 15:55 - *** some other fixes...
 9th Dec 96 - 01:42 - *** rewritten static text code...
16th Dec 96 - 06:09 - added simple perc...
 6th Jul 97 - 19:20 - added perc procs...
24th Jul 97 - 10:34 - *** a small bugfix in listviewer...
31st Jul 97 - 14:20 - added datetimeviewer...
}

{$N+,E+,O-}

unit Tools;

interface

uses

  XOld, XInput, XKey, XDev, Dos, Drivers, XSys, XGfx, Graph, GView,
  Objects, XBuf, XColl, XStr, XScroll, XIO, XDiag, XTypes;

const

  {inputline constants}
  ilPassword = 1;
  ilUpper    = 2;

  {datetimeviewer constants}
  dtcAlarm  = 1;

  { column flags }
  cofNormal  = 0;
  cofRJust   = 1; {right justified}

  { label config }
  lcRJust    = 1; {right justified}

  stxlineGAP = 3; {3 pixels gap between static text lines}

  flc_Focused = cDarkGray;

type

  PDesktop = ^TDesktop;
  TDesktop = object(TGroup)
    Background : PView;
    constructor Init(var R:TRect);
    procedure   InitBackground(var R:TRect);virtual;
  end;

  PStatusLine = ^TStatusLine;
  TStatusLine = object(TView)
    Text      : PString;
    constructor Init(var R:TRect);
    destructor  Done;virtual;
    procedure   Paint;virtual;
    procedure   Update(AText:String);
  end;

  PSystem = ^TSystem;                 {Base application}
  TSystem = object(TGroup)
    Background  : PBackground;
    MT          : TMultiTasker;
    {init & dones}
    constructor Init;
    destructor  Done; virtual;
    procedure   SetSysPalette;virtual;
    procedure   ShutdownEffect;virtual;
    procedure   InitPointingDevice;virtual;
    function    InitBackground:PBackGround; virtual;

    {execution methods}
    procedure   Run;virtual;

    {event management methods}
    procedure   PutEvent(Var Event:TEvent); virtual;
    procedure   GetEvent(Var Event:TEvent); virtual;
    procedure   HandleEvent(Var Event:TEvent); virtual;
    procedure   Idle; Virtual;
    procedure   PrimaryHandle(var Event:TEvent);virtual;
{    procedure   SaveScreen;virtual;}
  end;

  PListViewer = ^TListViewer;      {List Viewer}
  TListViewer = object(TView)
    ItemList    : PCollection;
    Rows        : Byte;
    ScrTop      : Integer;
    FocusedItem : Integer;
    Scroller    : PScrollBar;
    FontH       : word;
    Font        : word;

    {init & done}
    constructor Init(var abounds:TRect; afont:word);
    procedure   AssignScroller(AS:PScrollBar);
    destructor  Done;virtual;

    {paint methods}
    procedure   Paint;virtual;
    procedure   PaintItem(Item:longint);virtual;
    procedure   PaintItems;

    {event handling methods}
    procedure   HandleEvent(var Event:TEvent);virtual;

    {set & gets}
    procedure   SetState(AState:Word;Enable:Boolean);virtual;
    function    GetColor(item:longint):byte;virtual;
    function    GetText(Item:longint):String;virtual;
    function    GetFocusedItem:String;virtual;
    procedure   GetItemBounds(Item:longint;var R:TRect);virtual;

    {item management methods}
    procedure   FocusItem(Item:longint);virtual;
    procedure   ItemFocused(Item:longint); virtual;
    procedure   ItemTagged(item:longint);virtual;
    procedure   ItemDoubleClicked(Item:longint); virtual;
    procedure   DeleteItem(Item:longint);virtual;
    procedure   UpDate(AList:PCollection);virtual;
    procedure   NewList(AList:PCollection);virtual;

    { scrollbar methods }
    procedure   UpdateScroller;
  end; {listviewer}

  PColumn = ^TColumn;
  TColumn = object(TObject)
    Next  : pointer;
    Title : PString;
    Width : word;
    Flags : byte;
  end;

  PFormattedLister = ^TFormattedLister;
  TFormattedLister = object(TListViewer)
    ColumnList  : PColumn;
    ColumnCount : integer;
    constructor Init(x,y:integer; afont,arows:word; acolumns:PColumn);
    destructor  Done;virtual;
    procedure   GetItemBounds(item:longint; var abounds:TRect);virtual;
    procedure   PaintItem(item:longint);virtual;
    procedure   PaintHdr;
    procedure   PaintFrame;
    procedure   Paint;virtual;
  end;

  PStringViewer = ^TStringViewer;    {String List Viewer}
  TStringViewer = object(TListViewer)
    function    GetText(Item:longint):String;virtual;
  end;

  PImage = ^TImage;                 {BitMap Object}
  TImage = object(TView)
    BitMapId  : Word;
    constructor Init(x,y:integer; AVifId:Word);
    procedure   Paint;virtual;
  end;

  PStaticText = ^TStaticText;
  TStaticText = object(TView)
    Text      : PString;
    Font      : word;
    FontH     : word;
    fc,bc     : byte;
    constructor Init(var R:TRect; atext:string; afont:word; afc,abc:byte);
    destructor Done;virtual;
    procedure Paint;virtual;
  end;

  PGenericButton = ^TGenericButton;      {Generic Button}
  TGenericButton = object(TView)
    Pressed     : Boolean;
    Action      : Word;
    {init}
    constructor Init(var ABounds:TRect;AAction:Word);

    {set & gets}
    procedure   SetState(AState:Word;Enable:Boolean);virtual;

    {paint methods}
    procedure   Paint;virtual;
    procedure   PaintContents(var R:TRect);virtual;

    {event management methods}
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   PutAction(var Event:TEvent);virtual;

{    private
    procedure   BeFocused;}
  end;

  PColorButton = ^TColorButton;
  TColorButton = object(TGenericButton)
    Color      : byte;
    constructor Init(var abounds:TRect; acolor:byte; aaction:word);
    procedure PaintContents(var R:TRect);virtual;
  end;

  PButton = ^TButton;                    {Text Button from Generic Button}
  TButton = object(TGenericButton)
    Text        : PString;
    Motivator   : Char;
    iPos        : byte;
    Font        : word;
    {inits & done}
    constructor Init(x,y:integer;AText:FNameStr;AAction:Word);
    constructor SizedInit(var ABounds:TRect;AText:FNameStr;AAction:Word);
    destructor  Done;virtual;

    {others}
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   PaintContents(var R:TRect);virtual;
  end;

  PVIFButton = ^TVIFButton;              {BitMapButton from genericbutton}
  TVIFButton = object(TGenericButton)
    VIF         : Word;
    constructor Init(x,y:integer;AVIF:Word;AAction:Word);
    procedure   PaintContents(var R:TRect);virtual;
  end;

  PDoubleVIFButton = ^TDoubleVIFButton;  {Animated VIF Button}
  TDoubleVIFButton = object(TGenericButton)
    VIFA,VIFP      : Word;
    {init}
    constructor    Init(x,y:integer;VA,VP:Word;AAction:Word);

    {paint methods}
    procedure      Paint;virtual;
    procedure      PaintContents(var R:TRect);virtual;
  end;

  PSingleCheckBox = ^TSingleCheckBox;   {Single check box}
  TSingleCheckBox = object(TView)
    Checked       : boolean;
    Motivator     : char;
    Text          : PString;
    Font          : word;
    {init & done}
    constructor Init(x,y:integer;afont:word; AText:FNameStr);
    destructor  Done;virtual;

    {set & gets}
    procedure   SetState(AState:Word;Enable:Boolean);virtual;
    function    DataSize:Word;virtual;
    procedure   SetData(var rec);virtual;
    procedure   GetData(var rec);virtual;
    procedure   Mark(Enable:boolean);virtual;

    {event management methods}
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   HandleMouseEvents(var Event:TEvent);

    {paint methods}
    procedure   Paint;virtual;

    private
    function    CheckView:PVIFMap;
  end;

  PDialog = ^TDialog;                 {Simple Dialog Box}
  TDialog = object(TWindow)
    constructor Init(var ABounds:TRect;AHdr:FnameStr);
    procedure HandleEvent(var Event:TEvent);virtual;
  end;

  PAccLink = ^TAccLink;
  TAccLink = record
    Motivator : word;
    Action    : word;
    Next      : PAccLink;
  end;

  PAccelerator = ^TAccelerator;          {Keyboard Handler Object}
  TAccelerator = object(TView)
    Link       : PAccLink;
    constructor Init(ALink:PAccLink);
    destructor  Done;virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
  end;

  PBarGraph = ^TBarGraph;                {Bar Graphic}
  TBarGraph = object(TView)
    Max         : LongInt;
    Current     : LongInt;
    constructor Init(ABounds:TRect;AMax,ACurrent:LongInt);
    procedure   Paint;virtual;
    procedure   UpDate(AMax,ACurrent:Longint);
  end;

  PMemoryReporter = ^TMemoryReporter;
  TMemoryReporter = object(TView)
    OMemAvail,OMaxAvail : longint;
    constructor Init;
    procedure   Paint;virtual;
    procedure   Backprocess;virtual;
  end;

  PDynamicBar = ^TDynamicBar;         {Dynamic bar graph}
  TDynamicBar = object(TBarGraph)
    constructor Init(var R:TRect);
    procedure   NewData(var NewMax,NewCurrent:Longint);virtual;
    procedure   Backprocess;virtual;
  end;

  PMemoryView = ^TMemoryView;         {Dynamic memory bar graph}
  TMemoryView = object(TDynamicBar)
    procedure   NewData(var NewMax,NewCurrent:Longint);virtual;
    procedure   ChangeBounds(var R:TRect);virtual;
  end;

  PLabel = ^TLabel;                  {Simple label}
  TLabel = object(TView)
    Text   : PString;
    FontId : word;
    FColor : Byte;
    BColor : Byte;
    constructor Init(x,y:integer;atext:string; afont:word);
    constructor FullInit(x,y:integer;AText:string;cf,cb:byte; afontid:word);
    destructor  Done;virtual;
    procedure   Paint;virtual;
  end;

  PDynamicLabel = ^TDynamicLabel;
  TDynamicLabel = object(TView)
    Text        : PString;
    Font        : word;
    FC,BC       : byte;
    constructor Init(x,y,xsize:integer; atext:string; afc,abc:byte; afont:word);
    destructor  Done;virtual;
    procedure   Paint;virtual;
    procedure   NewText(atext:string);
  end;

  PLinkItem = ^TLinkItem;     {XMENU TYPES BEGIN HERE}
  TLinkItem = object
    Next    : PLinkItem;
    Class   : Byte;
    Delta   : Byte;
  end;

  PCheckBoxItem = ^TCheckBoxItem;
  TCheckBoxItem = object(TLinkItem)
    Text        : PString;
  end;

  PButtonItem = ^TButtonItem;
  TButtonItem = object(TLinkItem)
    Text    : PString;
    Command : Word;
  end;

  PVIFItem = ^TVIFItem;
  TVIFItem = object(TLinkItem)
    VIF     : Word;
    Command : Word;
  end;

  PInputItem = ^TInputItem;
  TInputItem = object(TLinkItem)
    Prompt   : PString;
    Len      : Byte;
    Config   : Word;
    IdNumber : Byte;
    GrupNum  : Word;
  end;

  PNInputItem = ^TNInputItem;
  TNInputItem = object(TInputItem)
    NumType   : Byte;
    Digit1    : Byte;
    Digit2    : Byte;
  end;

  PChooserItem = ^TChooserItem;
  TChooserItem = record
    Next       : PChooserItem;
    Text       : PString;
  end;

  PMenuWindow = ^TMenuWindow;
  TMenuWindow = object(TWindow)
    constructor Init(x,y:integer;AHdr:String;Items:string);
  end;

  PChooser = ^TChooser;
  TChooser = object(TView)
    List        : PChooserItem;
    MaxItems    : Word;
    MaxLength   : Word;
    FocusedItem : Word;
    constructor Init(x,y:integer;AList:PChooserItem);
    destructor  Done;virtual;
    procedure   Paint;virtual;
    function    DataSize : word;virtual;
    procedure   SetData(var rec);virtual;
    procedure   GetData(var rec);virtual;
    function    Execute:word;virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   SetState(AState:Word; Enable:Boolean); virtual;

    procedure   FocusItem(Index:Word);virtual;
    procedure   SelectItem(Index:word);virtual;
    procedure   HandleKeyEvents(var Event:TEvent);virtual;
    procedure   HandleMouseEvents(var Event:TEvent);virtual;
    function    GetItem(Index:Word):PChooserItem;virtual;
    function    GetItemIndex(Item:PChooserItem):Word;virtual;
    procedure   GetItemBounds(Item:PChooserItem;var Bounds:TRect);virtual;
    procedure   PaintItem(P:PChooserItem);virtual;
    procedure   PaintItems;virtual;
  end;

  PRadioButton = ^TRadioButton;
  TRadioButton = object(TChooser)
    YINC       : byte;
    ActiveItem : word;
    Font       : word;
    FontH      : word;
    constructor  Init(var Bounds:TRect;afont:word; AList:PChooserItem);
    procedure    Paint;virtual;
    procedure    PaintItem(P:PChooserItem);virtual;
    procedure    GetItemBounds(Item:PChooserItem;var Bounds:TRect);virtual;
    procedure    GetData(var rec);virtual;
    procedure    SetData(var rec);virtual;
    procedure    SelectItem(Index:word);virtual;
  end;

  PMessageView = ^TMessageView;
  TMessageView = object(TView)
    Msg        : PString;
    constructor Init(amsg:string);
    destructor  Done;virtual;
    procedure   Paint;virtual;
  end;

  TMenuStr = string[31];   {PULL-DOWN MENU TYPES BEGIN HERE}

  PMenu = ^TMenu;

  PMenuItem = ^TMenuItem;
  TMenuItem = record
    Name     : PString;
    Command  : word;
    Disabled : boolean;
    SubMenu  : PMenu;
    Next     : PMenuItem;
  end;

  TMenu = record
    Items   : PMenuItem;
    Default : PMenuItem;
  end;

  PMenuView = ^TMenuView;
  TMenuView = object(TView)
    Menu     : PMenu;
    Focused  : PMenuItem;
    endit    : boolean;
    Modalize : boolean;
    Parent   : PMenuView;
    Font     : word;
    FontH    : word;
    constructor Init(var R:TRect);
    procedure HandleEvent(var Event:TEvent);virtual;
    procedure Paint;virtual;
    procedure GetItemBounds(P:PMenuItem;var R:TRect);virtual;
    function  GetItemIndex(P:PMenuItem):integer;
    function  Execute:word;virtual;
    function  GetLastItem:PMenuItem;
    function  GetPointedItem(var Event:TEvent):PMenuItem;
    procedure PaintItem(P:PMenuItem);virtual;
    procedure PaintItems;virtual;
    procedure FocusPrev;
    procedure FocusNext;
    procedure FocusItem(item:PMenuItem);virtual;
    procedure Activate(P:PMenuItem);virtual;

    function GetTilda(P:PMenuItem):char;
    function GetStrSize(s:string):word;
    function GetMaxSize(aMenu:PMenu):byte;
  end;

  PMenuBar = ^TMenuBar;
  TMenuBar = object(TMenuView)
    constructor Init(var R:TRect; AMenu: PMenu);
    destructor  Done;virtual;
    procedure   GetItemBounds(P:PMenuItem;var R:TRect);virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
  end;

  PMenuBox = ^TMenuBox;
  TMenuBox = object(TMenuView)
    constructor Init(x,y:integer;AMenu:PMenu);
    procedure   GetItemBounds(P:PMenuItem;var R:TRect);virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
  end;

  PSimplePerc = ^TSimplePerc;
  TSimplePerc = object(TView)
    FC,BC     : byte;
    Value,Max : longint;
    constructor Init(abounds:TRect; afc,abc:byte);
    procedure   Paint;virtual;
    procedure   NewPerc(aval,amax:longint);
  end;

  PProcView = ^TProcView;
  TProcView = object(TView)
    Text        : PString;
    Value,Max   : longint;
    FontID      : word;
    constructor Init(var R:TRect; afont:word);
    destructor  Done;virtual;
    procedure   NewText(s:FnameStr);
    procedure   NewPerc(avalue,amax:longint);
    procedure   Paint;virtual;
    procedure   PaintText;
    procedure   PaintPerc;
  end;

  PInputLine = ^TInputLine;
  TInputLine = object(TView)
    ValidChars : set of char;
    Data       : PString;
    Font       : word;
    FontH      : word;
    MaxLen     : byte;
    Cursor     : byte;
    StartPos   : byte;
    Moved      : boolean;
    constructor Init(x,y,xsize:integer; afont:word; amaxlen:byte);
    destructor  Done;virtual;
    function    GetVisibleData:string;virtual;
    procedure   Paint;virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
    function    DataSize:word;virtual;
    procedure   SetData(var rec);virtual;
    procedure   GetData(var rec);virtual;
    procedure   SetState(astate:word;enable:boolean);virtual;
  end;

  PConsoleView = ^TConsoleView;
  TConsoleView = object(TView)
    Lines      : PTextCollection;
    Font       : word;
    FontH      : word;
    MaxLines   : byte;
    FC,BC      : byte;
    constructor Init(var abounds:TRect; afont:word; linecount:byte; afc,abc:byte);
    destructor Done;virtual;
    procedure Paint;virtual;
    procedure Out(s:string);virtual;
    procedure Clear;virtual;
  end;

  TMoment = record
    Year  : word;
    Month : byte;
    Day   : byte;
    Hour  : byte;
    Min   : byte;
  end;

  PDateTimeViewer = ^TDateTimeViewer;
  TDateTimeViewer = object(TView)
    Moment        : TMoment;
    Alarm         : TMoment;
    Font          : word;
    constructor Init(x,y:integer; afont:word);
    procedure   OnAlarm;virtual; {abstract}
    procedure   OnTick;virtual; {abstract}
    procedure   Paint;virtual;
    procedure   Backprocess;virtual;
    procedure   GetMoment(var amoment:TMoment);
  end;

  {- Column functions -}
  function  NewColumn(atitle:string; awidth:integer; aflags:byte; anext:PColumn):PColumn;
  procedure DisposeColumn(P:PColumn);

  {- listviewer help tools -}
  procedure PutListerScroller(alist:PListViewer; owner:PGroup);

  {---------------------  Pull-down Menu Functions ----------------------}

  function NewMenu(Items:PMenuItem):PMenu;
  function NewItem(Name:TMenuStr; Command:word; Next:PMenuItem):PMenuItem;
  function NewSubMenu(Name:TMenuStr; SubMenu:PMenu; Next:PMenuItem):PMenuItem;
  function NewLine(Next:PMenuItem):PMenuItem;

  procedure DisposeMenu(Menu:PMenu);
  procedure DisposeMenuItem(Item:PMenuItem);

  {----------------------- Blocked Menu Functions -----------------------}

  function  NewButton(AText:FNameStr; ACommand:Word; Next:PLinkItem):PButtonItem;
  function  NewVIFItem(AVIF,ACommand:Word; Next:PLinkItem):PVIFItem;
  function  NewInputItem(APrompt:FNameStr; ALen:Byte; AConfig:Word; Next:PLinkItem):PInputItem;
  function  NewInputIdItem(APrompt:FNameStr;ALen:Byte;AConfig:Word;AIdNumber:Byte;AGrpNum:Word;Next:PLinkItem):PInputItem;
  function  NewNInputItem(APrompt:FNameStr;ALen,NumType,D1,D2:Byte;AConfig:Word;Next:PLinkItem):PNInputItem;
  function  NewNInputIdItem(APrompt:FNameStr;ALen,NumType,D1,D2:Byte;AConfig:Word;
			    AId:Byte; AGrp:Word; Next:PLinkItem):PNInputItem;
  function  NewCheckBox(AText:FnameStr;Next:PLinkItem):PCheckBoxItem;

  { they will be integrated - 30th Oct 93 - SSG }
  { they have been integrtd - 25th Nov 93 - SSG }
  function  GetBlock(x,y:integer;Options:Word;List:PLinkItem):String;
  procedure DisposeLink(List:PLinkItem);

  {-----------------------  Chooser Functions  --------------------------}

  function  NewChooser(S:FNameStr;ANext:PChooserItem):PChooserItem;
  procedure DisposeChooserItem(CList:PChooserItem);
  function  ExecuteChooser(x,y:integer;CList:PChooserItem):word;
  function  MaxChoiceLength(CList:PChooserItem):byte;
  function  GetChoiceCount(CList:PChooserItem):word;

  {-------------------- Standard Dialog Functions ---------------------}

  function ExecBox(amsg,atitle:string; actx:word; buttons:string):word;
  {normal message box}
  function MessageBox(tell:string; helpctx:word; AOptions:word):word;
  {modal message box}
  function XMessageBox(tell:string; helpctx:word; AOptions:word):word;
  function InputBox(Header,Prompt:FnameStr; actx,afont:word; var s:string; maxlen:byte):boolean;

  procedure StartJob(s:FnameStr);
  procedure EndJob;

  procedure StartPerc(s:string);
  procedure UpdatePerc(value,max:longint);
  procedure UpdatePercText(s:string);
  procedure DonePerc;

  function NewAcc(KeyCode,Action:Word;Next:PAccLink):PAccLink;

const

  GSystem         : PSystem = NIL;      {Dynamic GSystem}
  JobView         : PMessageView = NIL; {Messages around}
  ButtonFocusMode : byte = 0;   {0=standard, 1=komisyon}
  ButtonFont      : word = 0;
  MenuFont        : word = 0;
  MsgBoxFont      : word = 0;

{  Ctx_Chooser       : word = hcNoContext;
  Ctx_Button        : word = hcNoContext;
  Ctx_ListViewer    : word = hcNoContext;
  Ctx_CheckBox      : word = hcNoContext;
  Ctx_RadioButton   : word = hcNoContext;
  Ctx_WindowLister  : word = hcNoContext;
  Ctx_Copier        : word = hcNoContext;
  Ctx_WindowManager : word = hcNoContext;
  Ctx_MessageBox    : word = hcNoContext;
  Ctx_InputBox      : word = hcNoContext;}

implementation

const

  Rbc_Modified = $0001;

  PercView     : PProcView = NIL;

procedure PutListerScroller(alist:PListViewer; owner:PGroup);
var
  R:TRect;
  Ps:PScrollBar;
begin
  alist^.GetBounds(R);
  r.a.x := r.b.x+2;
  r.b.x := r.a.x+sbButtonSize;
  New(Ps,Init(R));
  Owner^.Insert(Ps);
  alist^.AssignScroller(Ps);
end;

procedure StartPerc(s:string);
var
  R:TRect;
begin
  if PercView = NIL then begin
    R.Assign(0,0,320,40);
    New(PercView,Init(R,ViewFont));
    GSystem^.Insert(PercView);
  end else begin
    UpdatePercText(s);
    UpdatePerc(0,0);
  end;
end;

procedure UpdatePerc(value,max:longint);
begin
  if PercView <> NIL then percView^.NewPerc(value,max);
end;

procedure UpdatePercText(s:string);
begin
  if PercView <> NIL then percView^.newText(s);
end;

procedure DonePerc;
begin
  if percView <> NIL then begin
    Dispose(percView,Done);
    percView := NIL;
  end;
end;

{************************** TCONSOLEVIEW *****************************}
constructor TConsoleView.Init;
begin
  inherited Init(abounds);
  Options := Options and not Ocf_Selectable;
  EventMask := 0;
  Font := afont;
  FontH := GetFontHeight(afont);
  MaxLines := linecount;
  FC       := afc;
  BC       := abc;
  new(Lines,Init(maxlines,1));
end;

procedure TConsoleView.Paint;
var
  n:integer;
  y:integer;
begin
  PaintBegin;
  SetTextColor(fc,bc);
  SetFillStyle(SolidFill,bc);
  y := 0;
  for n:=0 to Lines^.Count-1 do begin
    XPrintStr(0,y,Size.X+1,Font,PString(Lines^.At(n))^);
    inc(y,FontH);
  end;
  if y < Size.Y then XBar(0,y,Size.X,Size.Y);
  PaintEnd;
end;

procedure TConsoleView.Out;
begin
  if s = '' then s := #32;
  if Lines^.Count = maxlines then Lines^.AtFree(0);
  Lines^.Insert(NewStr(s));
  PaintView;
end;

procedure TConsoleView.Clear;
begin
  Lines^.FreeAll;
  PaintView;
end;

destructor TConsoleView.Done;
begin
  Dispose(Lines,Done);
  inherited DOne;
end;

{************************** TINPUTLINE *************************}
constructor TInputLine.Init;
var
  R:TRect;
begin
  R.Assign(0,0,xsize+4,GetFontHeight(afont)+3);
  R.Move(x,y);
  inherited Init(R);
  Options := Options or Ocf_Selectable or Ocf_FirstClick;
  EventMask := evMouseDown or evKeyDown;
  MaxLen    := amaxlen;
  Font      := AFont;
  FontH     := GetFontHeight(Font);
  GetMem(data,maxlen+1);
  ValidChars := [#32..#255];
  data^[0] := #0;
end;

procedure TInputLine.SetState;
begin
  inherited SetState(astate,enable);
  if astate and scf_Focused > 0 then begin
    if StartPos > 1 then begin
      Cursor := 0;
      StartPos  := 0;
    end;
    PaintView;
  end;
end;

function TInputLine.GetVisibleData:string;
var
  s:String;
begin
  s := Data^;
  if GetConfig(ilPassword) then FillChar(s[1],length(s),'*');
  GetVisibleData := s;
end;

procedure TInputLine.HandleEvent;
  function getcursor(x:integer):byte;
  var
    b:byte;
    size:integer;
  begin
    getcursor := 0;
    size      := 0;
    for b:=1 to length(Data^) do begin
      inc(size,GetStringSize(font,data^[b]));
      if x < size then begin
        getcursor := b;
        exit;
      end;
    end;
    getcursor := b;
  end;

  procedure GoLeft;
  var
    i:integer;
  begin
    if cursor < 1 then exit;
    dec(cursor);
    if cursor < startpos then begin
      i := startpos-5;
      if i < 0 then i := 0;
      startpos := i;
    end;
    moved := true;
    PaintView;
  end;

  procedure AdjustStartPos;
  var
    v:string;
  begin
    v := GetVisibleData;
    while GetStringSize(Font,copy(v,startpos,(cursor-startpos)+1)) > Size.X-4 do inc(startpos);
  end;

  procedure GoRight;
  begin
    if cursor < length(data^) then begin
      inc(cursor);
      AdjustStartPos;
      moved := true;
      PaintView;
    end;
  end;

  procedure ClearData;
  begin
    StartPos := 0;
    Cursor   := 0;
    Data^ := '';
  end;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evKeyDown : case Event.CharCode of
                  #32..#255 : begin
                                if GetConfig(ilUpper) then Event.Charcode := upcase(Event.CharCode);
                                if Event.Charcode in Validchars then begin
                                  if not moved then ClearData;
                                  if length(Data^) < MaxLen then begin
                                    System.Insert(Event.CharCode,Data^,cursor+1);
                                    GoRight;
                                  end;
                                end;
                              end;
                  ^Y : begin
                         ClearData;
                         PaintView;
                       end;
                  #8 : if length(Data^) > 0 then begin
                         System.Delete(Data^,cursor,1);
                         GoLeft;
                       end;
                  else case Event.KeyCode of
                         kbDel : if moved then begin
                                   if cursor < length(data^) then begin
                                     Delete(Data^,cursor+1,1);
                                     PaintView;
                                   end;
                                 end else begin
                                   ClearData;
                                   paintView;
                                 end;
                         kbLeft : GoLeft;
                         kbRight : GoRight;
                         kbEnd : begin
                                   cursor := length(data^);
                                   AdjustStartPos;
                                   moved := true;
                                   PaintView;
                                 end;
                         kbHome : begin
                                    cursor := 0;
                                    startpos := 0;
                                    moved := true;
                                    PaintView;
                                  end;
                         else exit;
                       end; {case}
                end; {Case}
    evMouseDown : begin
                    MakeLocal(Event.Where,Event.Where);
                    if Event.Where.X > 2 then begin
                      dec(Event.Where.X,2);
                      cursor := GetCursor(event.where.x);
                      if cursor > length(Data^) then cursor := length(data^);
                      PaintView;
                    end;
                  end;
    else exit;
  end; {case}
  ClearEvent(Event);
end;

destructor TInputLine.Done;
begin
  if data <> nil then FreeMem(data,maxlen+1);
  inherited Done;
end;

function TInputLine.DataSize;
begin
  DataSize := MaxLen+1;
end;

procedure TInputLine.SetData;
var
  s:string;
begin
  s := string(rec);
  if GetConfig(ilUpper) then FastUpper(s);
  Move(s[0],data^[0],length(s)+1);
end;

procedure TInputLine.GetData;
begin
  Move(data^[0],rec,maxlen+1);
end;

procedure TInputLine.Paint;
var
  s:string;
  R:TRect;
  bc:byte;
  fc:byte;
begin
  PaintBegin;
    GetExtent(R);
    ShadowBox(R,False);
    r.grow(-1,-1);
    fc := cBlack;
    if GetState(scf_Disabled) then bc := cLightGray else
      if GetState(scf_Focused) then begin
        fc := cYellow;
        bc := cBlue;
      end else bc := cWhite;
    SetColor(bc);
    XBox(R,false);
    r.grow(-1,-1);
    s := copy(GetVisibleData,startpos,255);
    if s ='' then s := #32;
    SetTextColor(fc,bc);
    XPrintStr(r.a.x,r.a.y,(r.b.x-r.a.x)+1,Font,s);
    if GetState(Scf_Focused) then begin
      SetWriteMode(XORPut);
      if startpos = 0 then startpos := 1;
      if cursor > 0 then inc(r.a.x,GetStringSize(Font,copy(s,1,(cursor-startpos)+1)));
      SetColor(cLightGreen);
      XLine(r.a.x,1,r.a.x,Size.Y-1);
      SetWriteMode(NORMALPut);
    end;
  PaintEnd;
end;

{************************** STARTJOB ***************************}
procedure StartJob;
begin
  EndJob;
  if GSystem = NIL then exit;
  New(JobView,Init(s));
  JobView^.Options := JobView^.Options or Ocf_AlwaysOnTop;
  GSystem^.Insert(JobView);
end;

procedure EndJob;
begin
  if JobView <> NIL then begin
    Dispose(JobView,Done);
    JobView := NIL;
  end;
end;

{*************************** TLABEL ***********************}
constructor TLabel.Init;
begin
  FullInit(x,y,atext,cBlack,Col_Back,afont);
end;

constructor TLabel.FullInit;
var
  R:TRect;
begin
  if AText = '' then Fail;
  R.Assign(0,0,GetStringSize(AFontId,AText)-1,GetFontHeight(AFontId)-1);
  R.Move(x,y);
  inherited Init(R);
  Options   := Ocf_PaintFast;
  EventMask := 0;
  ViewType  := vtLabel;
  FColor    := cf;
  BColor    := cb;
  Text      := NewStr(AText);
  FontId    := AFontId;
end;

destructor TLabel.Done;
begin
  if Text <> NIL then DisposeStr(Text);
  inherited Done;
end;

procedure TLabel.Paint;
begin
  PaintBegin;
    SetTextColor(FColor,BColor);
    XPrintStr(0,0,Size.X+1,FontId,Text^);
  PaintEnd;
end;

{***************************** TStringViewer **************************}
function TStringViewer.GetText;
begin
  GetText := PString(ItemList^.At(Item))^;
end;

{***************************** TLISTVIEWER **************************}
constructor TListViewer.Init;
begin
  inherited Init(abounds);
  Options     := Ocf_Selectable or Ocf_PaintFast or Ocf_FirstClick;
  EventMask   := evMessage or evKeyboard or evMouse;
  ViewType    := vtListViewer;
  Font        := afont;
  FontH       := GetFontHeight(Font);
  Rows        := (((Size.Y-4) div (FontH+2)));
end;

function TListViewer.GetColor;
begin
  GetColor := cBlack;
end;

procedure TListViewer.AssignScroller;
begin
  Scroller := AS;
  UpdateScroller;
end;

destructor TListViewer.Done;
begin
  if ItemList <> NIL then if not GetConfig(Lvc_KeepList) then begin
    Dispose(ItemList,Done);
    ItemList := NIL;
  end;
  inherited Done;
end;

procedure TListViewer.NewList;
begin
  if not GetConfig(Lvc_KeepList) then if ItemList <> NIL then Dispose(ItemList,Done);
  ItemList    := AList;
  FocusedItem := 0;
  ScrTop      := 0;
  UpdateScroller;
  if ItemList <> NIL then if ItemList^.Count > 0 then ItemFocused(0);
end;

procedure TListViewer.UpDate;
begin
  NewList(AList);
  PaintView;
end;

procedure TListViewer.DeleteItem;
begin
  if (Item < 0) or (Item > ItemList^.Count-1) then exit;
  ItemList^.AtFree(Item);
  if ItemList^.Count > 0 then if Item > ItemList^.Count-1 then begin
    FocusItem(ItemList^.Count-1);
    exit;
  end;
  if ItemList^.Count > 0 then ItemFocused(item);
  PaintView;
  UpdateScroller;
end;

procedure TListViewer.UpdateScroller;
begin
  if (Scroller <> NIL) and (ItemList <> NIL) then
    Scroller^.Update(ScrTop,ItemList^.Count,1,Rows,False);
end;

procedure TListViewer.FocusItem;
var
  olds:integer;
  oldf:integer;
  eol:integer;
begin
  if ItemList = NIL then exit;
  if Item > ItemList^.Count-1 then Item := ItemList^.Count-1;
  if Item < 0 then Item := 0;
  if Item = FocusedItem then exit;
  olds := ScrTop;
  oldf := FocusedItem;
  if oldf < olds then olds := oldf;
  eol  := ScrTop + Rows -1;
  if Item > eol then inc(ScrTop,Item-Eol);
  if Item < ScrTop then ScrTop := Item;
  if ItemList^.Count < Rows then ScrTop := 0;
  FocusedItem := Item;
  if (olds <> ScrTop) then PaintView else begin
    PaintBegin;
    PaintItem(oldf);
    PaintItem(FocusedItem);
    PaintEnd;
  end;
  ItemFocused(Item);
  UpdateScroller;
end;

procedure TListViewer.ItemFocused;
begin
end;

procedure TListViewer.ItemTagged;
begin
end;

procedure TListViewer.ItemDoubleClicked;
begin
end;

procedure TListViewer.SetState;
begin
  inherited SetState(AState,Enable);
  if AState and Scf_Focused > 0 then PaintView;
end;

procedure TListViewer.Paint;
var
  R:TRect;
  n:byte;
begin
  PaintBegin;
    GetExtent(R);
    ShadowBox(R,True);
    SetColor(Col_Back);
    R.Grow(-1,-1);
    XBox(R,False);
    PaintItems;
    GetItemBounds(0,R);
    SetFillStyle(solidFill,Col_Back);
    r.a.y := (rows*(FontH+2))+2;
    r.b.y := Size.Y-2;
    XBox(R,True);
  PaintEnd;
end;

procedure TListViewer.HandleEvent;
var
  T:TPoint;
  R:TRect;
  endof:integer;

  function GetPointedItem:integer;
  var
    n:integer;
  begin
    GetPointedItem := -1;
    MakeLocal(Event.Where,T);
    endof := ScrTop + Rows - 1;
    if endof > ItemList^.Count-1 then endof := ItemList^.Count-1;
    for n:=ScrTop to endof do begin
       GetItemBounds(n,R);
       if R.Contains(T) then begin
         GetPointedItem := n;
         exit;
       end;
    end; {for}
  end;

  procedure Double;
  begin
    endof := GetPointedItem;
    if (endof <> -1) then ItemDoubleClicked(endof)
  end;

  procedure HandleMouseEvents;
  begin
    if ItemList = NIL then exit;
    if Event.Double then Double else begin
      while Event.Buttons > 0 do begin
        endof := GetPointedItem;
        if endof <> -1 then FocusItem(endof) else begin
          GetItemBounds(ScrTop,R);
          if (T.Y < R.A.Y) then FocusItem(ScrTop-1);
          GetItemBounds(ScrTop+Rows-1,R);
          if (T.Y > R.B.Y) then FocusItem(ScrTop+rows);
          PointingDevice^.GetEvent(Event);
        end;
        PointingDevice^.GetEvent(Event);
      end;
    end;
    if Event.Double then Double;
  end;

begin
  inherited HandleEvent(Event);
  case Event.What of
    evKeyDown :     case Event.KeyCode of
                      kbUp         : FocusItem(FocusedItem-1);
                      kbDown       : FocusItem(FocusedItem+1);
                      kbPgUp       : FocusItem(FocusedItem - Rows);
                      kbPgDn       : FocusItem(FocusedItem + Rows);
                      kbCtrlPgUp   : FocusItem(0);
                      kbCtrlPgDn   : FocusItem(ItemList^.Count - 1);
                      kbHome       : FocusItem(ScrTop);
                      kbEnd        : FocusItem(ScrTop+Rows-1);
                      kbEnter      : if ItemList^.Count > 0 then ItemDoubleClicked(FocusedItem);
                      kbSpace      : if ItemList^.Count > 0 then ItemTagged(FocusedItem);
                      else exit;
                    end;
    evBroadcast : if Event.Command = Brc_ScrollbarChanged then
                    if Event.InfoPtr = Scroller then begin
                      ScrTop := Scroller^.Value;
                      PaintView;
                    end else exit else exit;
    evMouseDown,evMouseMove : HandleMouseEvents;
    evMouseUp : if Event.Double then Double else exit;
    else exit;
  end; {case}
  ClearEvent(Event);
end;

procedure TListViewer.GetItemBounds;
begin
  R.Assign(0,0,Size.X-1,FontH+1);
  R.Move(0,(item-scrtop)*(FontH+2)+2);
  R.Grow(-2,0);
  inc(r.b.x);
end;

procedure TListViewer.PaintItem;
var
  R:TRect;
  s:string;
  emptyline:boolean;
  isfocused:boolean;
  amifocused:boolean;
  shadow:boolean;
  fc,bc:byte;
begin
  GetItemBounds(Item,R);
  emptyline := false;
  if (ItemList = NIL) then emptyline := true else
    if (item > ItemList^.Count-1) then emptyline := true;
  if not emptyline then s := GetText(item);
  isfocused := item = FocusedItem;
  amifocused := GetState(scf_Focused);
  shadow     := isfocused and amifocused;
  fc := GetColor(item);
  bc := Col_Back;
  if shadow then bc := fc else if isfocused then bc := cDarkGray else bc := Col_back;
  SetColor(bc);
  XBox(R,False);
  R.Grow(-1,-1);
  if emptyline then begin
    SetFillStyle(SolidFill,Col_Back);
    XBox(R,True);
  end else begin
    if not shadow then SetTextColor(fc,Col_Back) else SetTextColor(Col_Back,fc);
    XPrintStr(r.a.x,r.a.y,(r.b.x-r.a.x)+1,Font,s);
  end;
end;

procedure TListViewer.PaintItems;
var
  n:integer;
  Finish:integer;
begin
  for n := ScrTop to ScrTop+Rows-1 do PaintItem(n);
end;

function TListViewer.GetText;
begin
  GetText := ''; {abstract method}
end;

function TListViewer.GetFocusedItem:String;
begin
  GetFocusedItem := '';
  if (FocusedItem < 0) or (FocusedItem > ItemList^.Count-1) then exit;
  GetFocusedItem := GetText(FocusedItem);
end;

{**************************** INPUTBOX ********************************}
function InputBox;
var
  Pd:PDialog;
  Pl:PLabel;
  Pb:PButton;
  R:TRect;
  code:word;
  block:string;
begin
  InputBox := false;
  R.Assign(0,0,0,0);
  New(Pd,Init(R,Header));
  Pd^.HelpContext := actx;
  Pd^.Options := Pd^.Options or Ocf_Centered;
  New(Pl,Init(5,6,Prompt,afont));
  Pl^.GetBounds(R);
  Pd^.Insert(Pl);
  Pd^.Insert(New(PInputLine,Init(r.b.x+5,5,100,afont,maxlen)));
  Pd^.SetData(s);
  block := GetBlock(5,r.b.y+6,mnfHorizontal+mnfNoSelect,
    NewButton(Msg[Msg_OK],cmOk,
    NewButton(Msg[Msg_Cancel],cmCancel,
    NIL)));
  GetBlockBounds(block,R);
  Pd^.InsertBlock(block);
  if actx <> 0 then begin
    Pb := New(PButton,Init(r.b.x+3,r.a.y,Msg[Msg_Help],cmHelp));
    Pb^.Options := Pb^.Options and not Ocf_Selectable;
    Pd^.Insert(Pb);
  end;
  Pd^.Insert(New(PAccelerator,Init(NewAcc(kbEnter,cmOK,NIL))));
  Pd^.FitBounds;
  code := GSystem^.ExecView(Pd);
  Pd^.GetData(S);
  InputBox := code = cmOK;
  Dispose(Pd,Done);
end;

{****************************  T S Y S T E M ******************}
constructor TSystem.Init;
var
  R : TRect;
begin
  MaxTypematicRate;
  InitFonts;
  InitGfx;
  InitPointingDevice;
  R.Assign(0,0,ScreenX,ScreenY);
  inherited Init(R);
  with PointingDevice^ do begin
    SetPosition(screenx div 2,screeny div 2);
    Show;
  end;
  SetSysPalette;
  State       := Scf_Backprocess + Scf_Visible + Scf_Exposed + Scf_Active + Scf_Selected + Scf_Focused;
  Options     := Ocf_Selectable;
  EventMask   := $FFFF;
  Background  := InitBackGround;
  GSystem     := @Self;
  ViewType    := VtSystem;
  MT          := GetMultiTasker;
  Insert(BackGround);
end;

procedure TSystem.InitPointingDevice;
begin
  PointingDevice := New(PMouse,Init);
  if PointingDevice = NIL then PointingDevice := New(PDumbPointingDevice,Init);
end;

procedure TSystem.SetSysPalette;
begin
  SetStartupPalette;
end;

procedure TSystem.ShutDownEffect;
var
  y1,y2:integer;
  b:byte;
const
  sheysize = 16;
begin
  SetViewPort(0,0,ScreenX,ScreenY,False);
  y1 := 0;
  y2 := ScreenY;
  SetFillStyle(SolidFill,cBlack);
  for b:=1 to 15 do begin
    Bar(0,y1,ScreenX,y1+sheysize);
    Bar(0,y2,ScreenX,y2-sheysize);
    inc(y1,sheysize);
    dec(y2,sheysize);
    sync;
  end;
end;

destructor TSystem.Done;
begin
  ShutdownEffect;
  DoneGfx;
  GSystem := NIL;
  TObject.Done;
end;

procedure TSystem.Run;
begin
  Execute;
end;

procedure TSystem.PutEvent;
begin
  NextEvent := Event;
end;

procedure TSystem.GetEvent;
begin
  if NextEvent.What <> EvNothing then begin
    Event := NextEvent;
    NextEvent.What := EvNothing;
  end else begin
    PointingDevice^.GetEvent(Event);
    if Event.What = evNothing then GetExtendedKeyEvent(Event);
    if Event.What <> evNothing then begin
      TickStart := 0;
{      PointingDevice^.Paint;}
    end else begin
      Idle;
      exit;
    end;
  end; {all ifs}
  PrimaryHandle(Event);
end;

procedure TSystem.Idle;
var
  s       : string;
begin
  if not GetSystem(Sys_Relax) then begin
    case MT of
      mtWindows,mtOS2 : asm
                          mov ax,1680h
                          int 2fh
                        end;
      mtDESQview : asm
                     mov ax,1000h
                     int 15h
                   end;
    end; {case}
  end;
  if not GetSystem(Sys_BackProcess) then exit;
  if GetSystem(Sys_Busy) then EventReady;
  if BulletinBoard <> '' then begin
     s := BulletinBoard;
     BulletinBoard := '';
     MessageBox(s,0,mfInfo);
  end;
  if XTimer^ < TickStart then TickStart := XTimer^;
  if TickStart = 0 then TickStart := XTimer^;
  ElapsedIdleTicks := XTimer^ - TickStart;
  if ElapsedIdleTicks < 0 then begin
    TickStart := XTimer^;
    ElapsedIdleTicks := 0;
  end;
  BackProcess;
end;

function TSystem.InitBackGround:PBackGround;
    Var
      R   : TRect;
      hDC : TBackDC;
    begin
      GetExtent(R);
      hDC.Style      := bsSolid;
      hDC.SColor     := Col_BackGround;
      InitBackGround := New(PBackground,Init(R, hDC)); {SSG was here}
    end;

procedure TSystem.PrimaryHandle;
var
  E : TEvent;
  n:byte;
  P:string[1];
begin
  case Event.What of
    evKeyDown : case Event.KeyCode of
		  kbCtrlPrtSc : Message(@Self,evCommand,cmBackgroundClicked,NIL);
		  kbAltX : begin
                             E.What := evCommand;
                             E.Command := cmQuit;
                             PutEvent(E);
                             ClearEvent(Event);
                           end;
		  else exit;
		end; {case keycode}
    evCommand : case Event.Command of
		   cmHelp : begin
			      HandleEvent(Event);
			      ClearEvent(Event);
			    end;
		   cmHalt : Done;
		   else exit;
		 end; {case}
    else exit;
  end; {case what}
end;

procedure TSystem.HandleEvent;
begin
  case Event.What of
    evKeyDown:
      case Event.KeyCode of
	kbGrayMinus: begin
                       SelectNext(False);
                       exit;
                     end;
        kbGrayPlus:begin
                     SelectNext(True);
                     exit;
                   end;
      end; {little case}
    evCommand:
      case Event.Command of
	cmQuit     : begin
			EndModal(cmQuit);
			exit;
		     end;
      end; {little case}
    evBroadCast:
      case Event.Command of
	Brc_ProcessFinished:if Event.InfoPtr <>NIL then begin
			       Dispose(PView(Event.InfoPtr),Done);
			       exit;
			    end;
      end; {smallest case}
  end; {big case}
  if Event.What <> evNothing then inherited HandleEvent(Event);
end;

{****************************** MESSAGE BOX ****************************}
function XMessageBox;
var
  lastback:boolean;
begin
  lastback := GetSystem(Sys_Backprocess);
  SetSystem(Sys_Backprocess,False);
  XMessageBox := MessageBox(tell,0,AOptions);
  SetSystem(Sys_Backprocess,lastback);
end;

function ExecBox(amsg,atitle:string; actx:word; buttons:string):word;
const
  minxsize = 200;
var
  Dialog:PDialog;
  Text:PStaticText;
  R:TRect;
  blockwidth : integer;
  height : integer;
  width  : integer;
begin
  if Buttons = '' then exit;
  GetBlockBounds(Buttons,R);
  blockwidth := r.b.x-r.a.x;
  if blockwidth > minxsize then width := blockwidth
                           else width := minxsize;
  height := ((GetStringSize(MsgBoxFont,amsg) div width)+2)*(GetFontHeight(MsgBoxFont)+stxlineGAP);
  R.Assign(0,0,0,0);
  New(Dialog,Init(R,atitle));
  Dialog^.Options := (Dialog^.Options and not Ocf_ZoomEffect) or Ocf_Centered;
  Dialog^.HelpContext := actx;
  R.Assign(0,0,width,height);
  R.Move(5,5);
  New(Text,Init(R,amsg,MsgBoxFont,cBlue,Col_Back));
  Text^.GetBounds(R);
  Dialog^.Insert(Text);
  r.a.y := r.b.y+5;
  r.a.x := ((width-blockwidth) div 2)+5;
  MoveBlock(Buttons,r.a.x,r.a.y);
  Dialog^.InsertBlock(Buttons);
  Dialog^.FitBounds;
  Dialog^.SelectNext(True);
  ExecBox := GSystem^.ExecView(Dialog);
  Dispose(Dialog,Done);
end;

{function ExecBox(amsg:string; atitle:FNameStr; actx:word; buttons:string):word;
var
  Dialog:PDialog;
  R,R1:TRect;
  Text:PStaticText;
  lines,lastx,b:byte;
  maxwidth,width:word;
  butx:integer;
  delta1,delta2:integer;
const
  dls = 4;
  function GetWidth(towhere:byte):word;
  begin
    GetWidth := GetStringSize(ViewFont,copy(amsg,lastx+1,towhere-lastx));
  end;
begin
  if GSystem = NIL then exit;
  if Buttons = '' then exit;
  R.Assign(0,0,0,0);
  New(Dialog,Init(R,atitle));
  Dialog^.Options := (Dialog^.Options and not Ocf_ZoomEffect);
  lines    := 1;
  maxwidth := 0;
  lastx    := 0;
  for b:=1 to length(amsg) do begin
    if amsg[b] = #13 then begin
      inc(lines);
      width := GetWidth(b);
      if width > maxwidth then maxwidth := width;
      lastx := b;
    end;
  end;
  width := GetWidth(length(amsg));
  if width > MaxWidth then MaxWidth := width;
  R.Assign(0,0,maxwidth+10,(lines*(ViewFontHeight+4))+5);
  GetBlockBounds(Buttons,R1);
  delta1 := r1.b.x-r1.a.x;
  delta2 := r.b.x-r.a.x;
  if delta1 > delta2 then begin
    R.B.X := delta1;
    butx  := 0;
  end else butx := (delta2-delta1) div 2;
  R.Move(5,5);
  New(Text,Init(R,amsg,4));
  Text^.fc := cLightGreen;
  Text^.bc := cBlack;
  delta1 := -R1.A.X+5+butx;
  delta2 := -R1.A.Y+R.B.Y+5;
  MoveBlock(Buttons,delta1,delta2);
  with Dialog^ do begin
    Insert(Text);
    InsertBlock(Buttons);
    FitBounds;
    HelpContext := actx;
    Options := Options or Ocf_Centered;
    SelectNext(True);
  end;
  ExecBox := GSystem^.ExecView(Dialog);
  if Dialog <> NIL then Dispose(Dialog,Done);
end;}

function MessageBox;
const
  MaxButtonsInDialog = 20;
  BlockSize          = MaxButtonsInDialog*SizeOf(Pointer);
var
  Buttons:string[BlockSize];
  n:word;
  b:byte;
  x:integer;
  procedure AddButton(var buttext:string; cmd:word);
  var
    R:TRect;
    P:PButton;
  begin
    if b > BlockSize-SizeOf(Pointer) then exit;
    New(P,Init(x,0,buttext,cmd));
    P^.GetBounds(R);
    x := R.B.X + 5;
    Move(P,Buttons[b],sizeof(Pointer));
    inc(b,4);
    inc(byte(Buttons[0]),4);
  end;
begin
  if Hi(AOptions) = 0 then AOptions := AOptions or mfOkButton;
  Buttons := '';
  b := 1;
  x := 0;
  for n:=0 to mfMaxButtons do if AOptions and ($100 shl n) > 0 then
    AddButton(Msg[n],Commands[n]);
  MessageBox := ExecBox(tell,Titles[lo(AOptions)],helpctx,Buttons);
end;

{************************** DELAY *********************************}
procedure Delay(ticks:longint);
var
  t1:longint;
begin
  t1 := XTimer^;
  while XTimer^-t1 < ticks do ;
end;

{************************* TBARGRAPH **************************}
constructor TBarGraph.Init;
begin
  inherited Init(ABounds);
  EventMask := 0;
  Options   := 0;
  Max       := AMax;
  Current   := ACurrent;
end;

procedure TBarGraph.Paint;
var
  R:TRect;
  R1:TRect;
begin
  PaintBegin;
    GetExtent(R);
    ShadowBox(R,False);
    R.Grow(-1,-1);
    ShadowBox(R,False);
    R.Grow(-1,-1);
    if Current > Max then Current := Max;
    if Max = 0 then begin
       SetFillStyle(SolidFill,cBlack);
       XBox(R,True);
    end else begin
       R1 := R;
       Dec(R.B.X,(Size.X-4)-((Size.X-4)*Current) div Max);
       SetFillStyle(SolidFill,cLightRed);
       XBox(R,True);
       R1.A.X := R.B.X+1;
       SetFillStyle(SolidFill,cBlack);
       XBox(R1,True);
    end;
  PaintEnd;
end;

procedure TBarGraph.Update;
begin
  Max     := AMax;
  Current := ACurrent;
  PaintView;
end;

{*********************** TACCELERATOR *************************}
constructor TAccelerator.Init;
var
  R:TRect;
begin
  R.Assign(0,0,0,0);
  inherited Init(R);
  Options   := Ocf_PostProcess; {Do not interrupt important events}
  EventMask := evKeyDown;
  State     := 0; {Non-visible}
  Link      := ALink;
end;

destructor TAccelerator.Done;
  procedure FuckLink(P:PAccLink);
  begin
    if P^.Next <> NIL then FuckLink(P^.Next);
    P^.Next := NIL;
    Dispose(P);
    P := NIL;
  end;
begin
  if Link <> NIL then FuckLink(Link);
  TView.Done;
end;

procedure TAccelerator.HandleEvent;
var
  P:PAccLink;
begin
  TView.HandleEvent(Event);
  if Event.What = evKeyDown then begin
    P := Link;
    while P <> NIL do begin
      if Event.KeyCode = P^.Motivator then begin
	ClearEvent(Event);
	Message(Owner,evCommand,P^.Action,Owner);
	exit;
      end;
      P := P^.Next;
    end;
  end;
end;

{*************************** TMEMORYREPORTER ************************}
constructor TMemoryReporter.Init;
var
  R:TRect;
begin
  R.Assign(1,ScreenY-ViewFontHeight+1,ScreenX,ScreenY);
  inherited Init(R);
  Options   := Ocf_AlwaysOnTop;
  EventMask := 0;
end;

procedure TMemoryReporter.Paint;
begin
  PaintBegin;
  SetTextColor(cWhite,cBlack);
  XWriteStr(0,0,ScreenX,'MaxAvail : '+l2s(MaxAvail)+' - MemAvail : '+l2s(MemAvail));
  PaintEnd;
end;

procedure TMemoryReporter.Backprocess;
begin
  if (OMaxAvail <> MaxAvail) or (OMemAvail <> MemAvail) then begin
    OMaxAvail := MaxAvail;
    OMemAvail := MemAvail;
    PaintView;
  end;
end;

{*************************** TDIALOG ****************************}
constructor TDialog.Init;
begin
  inherited Init(ABounds,AHdr);
  Options := Options and not (Ocf_ReSize{+Ocf_ZoomEffect});
end;

procedure TDialog.HandleEvent;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evKeyDown:
      if Event.KeyCode=kbEsc then case GetState(Scf_Modal) of
         True : begin
           ClearEvent(Event);
           Message(@Self,evCommand,cmCancel,@Self);
           exit;
         end;
         False : begin
           ClearEvent(Event);
           Message(@Self,evCommand,cmClose,@Self);
           exit;
         end;
      end;
    evCommand:
      case Event.Command of
	cmYes    ,
	cmOk     ,
	cmNo     ,
	cmCancel ,
	cmAbort  ,
	cmRetry  ,
	cmIgnore : if GetState(sfModal) then begin
                     ClearEvent(Event);
                     EndModal(Event.Command);
                     exit;
                   end;
      end; {case}
  end; {big case}
end;

{************************** TVIFIMAGE ****************************}
constructor TImage.Init;
var
  R:TRect;
  P:PVifMap;
begin
  P := GetImagePtr(AVifId);
  R.Assign(0,0,0,0);
  R.B.X := P^.XSize-1;
  R.B.Y := P^.YSize-1;
  R.Move(x,y);
  inherited Init(R);
  BitMapId  := AVifId;
  EventMask := 0;
  Options   := 0;
  ViewType  := VtImage;
end;

procedure TImage.Paint;
var
  R:TRect;
begin
  PaintBegin;
    GetExtent(R);
    XPutImage(0,0,BitmapId);
  PaintEnd;
end;

{************************** TDOUBLEVIFBUTTON ************************}
constructor TDoubleVIFButton.Init;
var
  R : TRect;
  P : PVifMap;
begin
  P := GetImagePtr(va);
  if P = NIL then exit;
  R.Assign(0,0,P^.XSize-1,P^.YSize-1);
  R.Move(x,y);
  TView.Init(R); {<=== this is a must}
  Action    := AAction;
  Options   := Ocf_PostProcess+Ocf_Selectable+Ocf_FirstClick;
  EventMask := evKeyDown or evMouseDown;
  VIFA      := va;
  VIFP      := vp;
  ViewType  := VtDubVifButton;
end;

procedure TDoubleVIFButton.PaintContents;
begin
  case Pressed of
     True:XPutImage(0,0,VIFP);
    False:XPutImage(0,0,VIFA);
  end; {case}
end;

procedure TDoubleVIFButton.Paint;
var
  R:TRect;
begin
  GetExtent(R);
  PaintBegin;
  PaintContents(R);
  PaintEnd;
end;

{************************ TSINGLECHECKBOX ***********************}
constructor TSingleCheckBox.Init;
var
  R:TRect;
  P:PVIFMap;
  Txt:string;
  b:byte;
  fh:integer;
begin
  R.A.X := x;
  R.A.Y := y;
  fh := GetFontHeight(afont);
  AText := #32+AText;
  Txt := AText;
  b   := pos('~',Txt);
  if b > 0 then begin
    System.Delete(Txt,b,1);
    Motivator := upcase(Txt[b]);
  end else Motivator := #255;
  P := GetImagePtr(Rid_StdMarkedCheckBox);
  if P^.YSize > fh then R.B.Y := R.A.Y + P^.YSize -1
                   else R.B.Y := R.A.Y + fh;
  R.B.X := R.A.X + P^.XSize + GetStringSize(afont,Txt);
  inherited Init(R);
  Font        := afont;
  Text        := NewStr(AText);
  Options     := Options or Ocf_Selectable or Ocf_FirstClick or Ocf_PreProcess;
  EventMask   := EventMask or evMouse or evKeyboard;
  ViewType    := VtSingleChkBox;
end;

destructor TSingleCheckBox.Done;
begin
  if Text <> NIL then DisposeStr(Text);
  inherited Done;
end;

procedure TSingleCheckBox.SetState;
begin
  inherited SetState(AState,Enable);
  if (AState and Scf_Focused > 0) then PaintView;
end;

function TSingleCheckBox.CheckView:PVIFMap;
var
  id:word;
begin
  if Checked then id := Rid_StdMarkedCheckBox
             else id := Rid_StdUnMarkedCheckBox;
  CheckView := GetImagePtr(id);
end;

procedure TSingleCheckBox.HandleMouseEvents;
var
  T:TPoint;
  R:TRect;
  sR:TRect;
  P : PVIFMap;
  Pressed : Boolean;
  procedure MakeBox;
  begin
    PointingDevice^.Hide;
    ShadowBox(sR,not Pressed);
    PointingDevice^.Show;
  end;
begin
  if Event.Buttons <> mbLeft then exit;
  T := Event.Where;
  GetExtent(R);
  MakeLocal(T,T);
  if not R.Contains(T) then exit;
  P := GetImagePtr(Rid_StdMarkedCheckBox);
  sR.Assign(0,0,P^.XSize-1,P^.YSize-1);
  Pressed := True;
  PaintBegin;
    PointingDevice^.Show;
    MakeBox;
    repeat
      GetEvent(Event);
      MakeLocal(Event.Where,Event.Where);
      if (Event.What = evMouseMove) then
      if R.Contains(Event.Where) and not Pressed then begin
	 Pressed := True;
	 MakeBox;
      end else if not R.Contains(Event.Where) and Pressed then begin
	 Pressed := False;
	 MakeBox;
      end;
    until Event.What = evMouseUp;
  PointingDevice^.Hide;
  PaintEnd;
  if Pressed then Mark(not Checked);
  ClearEvent(Event);
end;

procedure TSingleCheckBox.HandleEvent;
  procedure Update;
  begin
    Mark(not checked);
  end;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evKeyDown : if GetState(Scf_Focused) and (Event.CharCode = #32) and GetState(Scf_Focused) then begin
                   Update;
		end else if Event.KeyCode = GetAltCode(Motivator) then begin
                  Select;
                  Update;
                end else exit;
    evMouseDown : if GetState(Scf_Focused) then HandleMouseEvents(Event);
    else exit;
  end;
  ClearEvent(Event);
end;

procedure TSingleCheckBox.Mark;
begin
  Checked := Enable;
  PaintView;
end;

procedure TSingleCheckBox.Paint;
var
  P:PVIFMap;
  fc:byte;
begin
  PaintBegin;
    P := CheckView;
    XPutVIF(0,0,P^);
    if GetState(Scf_Focused) then fc := cWhite else
    if GetState(Scf_Disabled) then fc := cDarkGray else fc := cBlack;
    SetTextColor(fc,Col_Back);
    SetFillStyle(SolidFill,Col_Back);
    XBar(P^.XSize,0,Size.X,Size.Y);
    if Text <> NIL then
      XTilda(P^.XSize,(Size.Y-ViewFontHeight) div 2,Text^,Font,TxtForeground,TxtBackground);
  PaintEnd;
end;

function TSingleCheckBox.DataSize:Word;
begin
  DataSize := SizeOf(Boolean);
end;

procedure TSingleCheckBox.SetData;
begin
  Checked := Boolean(rec);
  PaintView;
end;

procedure TSingleCheckBox.GetData;
begin
  Boolean(Rec) := Checked;
end;

{- TStatusLine -}
constructor TStatusLine.Init(var R:TRect);
begin
  inherited Init(R);
  EventMask := 0;
  Options   := 0;
end;

destructor TStatusLine.Done;
begin
  if Text <> NIL then DisposeStr(Text);
  inherited Done;
end;

procedure TStatusLine.Paint;
var
  R:TRect;
  textsize:integer;
  gap:integer;
  linesize:integer;
begin
  PaintBegin;
    GetExtent(R);
    SetColor(Col_Back);
    SetFillStyle(SolidFill,cBlue);
    SetTextColor(cYellow,cBlue);
    ShadowBox(R,True);
    R.Grow(-1,-1);
    XBox(R,False);
    R.Grow(-1,-1);
    ShadowBox(R,False);
    R.Grow(-1,-1);
    linesize := R.B.X-R.A.X;
    XBox(R,True);
    if Text <> NIL then begin
      textsize := GetStringSize(ViewFont,Text^);
      if textsize > linesize then textsize := linesize else begin
        gap := (linesize-textsize) div 2;
        inc(r.a.x,gap);
      end;
      XWriteStr(r.a.x+3,(((r.b.y-r.a.y)-(ViewFontHeight-1)) div 2)+3,textsize,Text^);
    end;
  PaintEnd;
end;

procedure TStatusLine.Update(AText:String);
begin
  if Text <> NIL then DisposeStr(Text);
  Text := NewStr(AText);
  PaintView;
end;

{This GenericButton technique has come from the old 'DreamView'
 user interface. It worked there and here - Viva nostalgia}

{************************ TGENERICBUTTON *************************}
constructor TGenericButton.Init;
begin
  inherited Init(ABounds);
  Action:=AAction;
  Options:=Options or Ocf_PostProcess+Ocf_FirstClick+Ocf_Selectable;
  EventMask:=evMouseDown + evKeyDown;
{  HelpContext := Ctx_Button;}
end;

procedure TGenericButton.PaintContents;
begin
  SetFillStyle(SolidFill,Col_Back);
  XBox(R,True);
end;

procedure TGenericButton.Paint;
var
  R:TRect;
  n:integer;
  Thick:integer;
begin
  PaintBegin;
  GetExtent(R);
  if GetState(Scf_Focused) then ShadowBox(R,False) else begin
    SetColor(COl_Back);
    XBox(R,false);
  end;
  R.Grow(-1,-1);
  SetColor(cBlack);
  XBox(R,False);
  R.Grow(-1,-1);
  case Pressed of
    False : begin
	     for n:=1 to btShadowCount do begin {2 pixels from here}
	       ShadowBox(R,True);
	       R.Grow(-1,-1);
	     end;
	     PaintContents(R);
	   end; {true}
    True : begin
	     Thick := btShadowCount+1;
	     SetFillStyle(SolidFill,Shc_LowerRight);
	     XBar(R.A.X,R.A.Y,R.A.X+Thick-1,R.B.Y);
	     XBar(R.A.X+Thick,R.A.Y,R.B.X,R.A.Y+Thick-1);
	     SetFillStyle(SolidFill,Col_Back);
	     XBar(R.A.X+Thick,R.B.Y-Thick,R.B.X,R.B.Y);
	     XBar(R.B.X-Thick,R.A.Y+Thick,R.B.X,R.B.Y-Thick);
             inc(r.a.x,thick);
             inc(r.a.y,thick);
             dec(r.b.x,thick);
             dec(r.b.y,thick);
	     PaintContents(R);
	   end; {false}
  end; {case}
  {BeFocused;}
  PaintEnd;
end;

{procedure TGenericButton.BeFocused;
var
  R:TRect;
  b:byte;
begin
  GetExtent(R);
  R.Grow(-1,-1);
  if GetState(Scf_Focused) then ShadowBox(R,False) else begin
    SetColor(Col_Back);
    XBox(R,False);
  end;
end;}

procedure TGenericButton.SetState;
var
  R        : TRect;
  OldState : Word;
begin
  OldState:=State;
  TView.SetState(AState,Enable);
  if Owner = NIL then exit;
  if not Owner^.GetState(Scf_Exposed) then exit;
  if AState and (Scf_Focused+Scf_Disabled)>0 then PaintView;
end;

procedure TGenericButton.PutAction;
begin
  if (not GetState(Scf_Focused)) and (Options and Ocf_Selectable > 0) then
    Select;
  if Event.What = evKeyDown then begin
     Pressed       := True;
     Paint;
     Delay(btEnterDelay);
     Pressed       := False;
     Paint;
  end;
  Event.What    := evCommand;
  Event.Command := Action;
  Event.InfoPtr := Owner;
  PutEvent(Event);
  ClearEvent(Event);
end;

procedure TGenericButton.HandleEvent;
var
  R:TRect;
begin
  inherited HandleEvent(Event);
  if (Event.What=evMouseDown) and MouseInView(Event.Where) and (Event.Buttons = mbLeft) then begin
     Pressed:=True;
     Paint;
     repeat
       GetEvent(Event);
       if Event.What=evMouseMove then
	  if (MouseInView(Event.Where) and not Pressed) then begin
	     Pressed:=true;
	     Paint;
	  end else
	  if (not MouseInView(Event.Where) and Pressed) then begin
	     Pressed:=false;
	     Paint;
	  end;
     until Event.What=evMouseUp;
     Pressed := False;
     Paint;
     if MouseInView(Event.Where) then PutAction(Event);
  end else if (Event.What=evKeyDown)
	      and ((Event.KeyCode=kbEnter) or (Event.CharCode = #32))
	      and GetState(Scf_Focused) then begin
		Pressed := True;
		Paint;
		Delay(btEnterDelay);
		Pressed := False;
		Paint;
		PutAction(Event);
	      end;
end;

{******************************* TBUTTON **********************}
constructor TButton.Init;
var
  R:TRect;
  afont:word;
begin
  R.A.X := x;
  R.A.Y := y;
  if buttonfont <> 0 then afont := buttonfont else afont := viewfont;
  R.B.X := R.A.X + GetStringSize(afont,AText) +
                   (btShadowCount+btLineCount+btXGAP)*2;
  R.B.Y := R.A.Y + 3 + GetFontHeight(afont) + (btShadowCount+btLineCount) * 2;
  SizedInit(R,AText,AAction);
end;

constructor TButton.SizedInit;
var
  i:byte;
begin
  i := pos('~',AText);
  if i > 0 then Delete(AText,i,1);
  inherited Init(ABounds,AAction);
  if i>0 then Motivator := Upcase(AText[i]);
  Text      := NewStr(AText);
  ViewType  := VtButton;
  iPos      := i;
  if ButtonFont <> 0 then Font := ButtonFont else Font := ViewFont;
end;

destructor TButton.Done;
begin
  if Text<>NIL then DisposeStr(Text);
  inherited Done;
end;

procedure TButton.HandleEvent;
var
  c:char;
begin
  inherited HandleEvent(Event);
  if Event.What <> evKeyDown then exit;
  if Motivator = #0 then exit;
  if Event.CharCode <> #0 then c := UpCase(Event.CharCode) else
     c := UpCase(GetAltChar(Event.KeyCode));
  if (Motivator = c) then begin
    PutAction(Event);
    ClearEvent(Event);
  end;
end;

procedure TButton.PaintContents;
var
  s:string;
  ib:byte;
  c:byte;
begin
  inherited PaintContents(R);
  if Text=NIL then exit;
  s := Text^;
  if ipos > 0 then Insert('~',s,ipos);
  ib := 2*Byte(Pressed);
  r.a.x := (Size.X-GetStringSize(Font,Text^)) div 2;
  r.a.y := ((Size.Y-(GetFontHeight(Font)-(tildaGAP+1))) div 2);
  R.Move(ib,ib);
  if GetState(Scf_Disabled) then c := cDarkGray else c := Col_ButtonTextNormal;
  XTilda(r.a.x,r.a.y,s,Font,c,Col_Back);
end;

{**************************** TVIFBUTTON ***************************}
constructor TVIFButton.Init;
var
  R:TRect;
  P : PVifMap;
begin
  P := GetImagePtr(AVif);
  r.assign(0,0,(P^.XSize-1)+((btShadowCount+btLineCount)*2),
               (P^.YSize-1)+((btShadowCount+btLineCount)*2));
  R.Move(x,y);
  inherited Init(R,AAction);
  VIF:=AVIF;
  ViewType  := VtVifButton;
end;

procedure TVIFButton.PaintContents;
begin
  XPutImage(r.a.x,r.a.y,VIF);
end;

{***************************** TMEMORYVIEW ***************************}
procedure TMemoryView.NewData;
begin
  NewMax     := Max;
  NewCurrent := MemAvail;
end;

procedure TMemoryView.ChangeBounds;
var
  R1:TRect;
begin
  Owner^.GetVisibleBounds(R1);
  TView.ChangeBounds(R1);
end;

{***************************** TDYNAMICBAR ****************************}
constructor TDynamicBar.Init;
begin
  TBarGraph.Init(R,0,0);
  SetState(Scf_Backprocess,True);
end;

procedure TDynamicBar.NewData;
begin
  NewMax := 0;  {Must be overridden by other objects}
  NewCurrent := 0;
end;

procedure TDynamicBar.Backprocess;
var
  NewMax,NewCurrent : longint;
begin
  NewData(NewMax,NewCurrent);
  if (NewMax <> Max) or (NewCurrent <> Current) then Update(NewMax,NewCurrent);
end;

{********************** NEWACC ******************************}
function NewAcc;
var
  P:PAccLink;
begin
  P := NIL;
  New(P);
  if P <> NIL then begin
    P^.Motivator := KeyCode;
    P^.Action    := Action;
    P^.Next      := Next;
  end;
  NewAcc := P;
end;

{*************************** DISPOSEBLOCK ***********************}
procedure DisposeLink;
begin
  if List^.Next <> NIL then DisposeLink(List^.Next);
  case List^.Class of
    blInputLine,blInputDate : begin
		    DisposeStr(PInputItem(List)^.Prompt);
		    Dispose(PInputItem(List));
		  end;
    blNInputLine : begin
		     DisposeStr(PNInputItem(List)^.Prompt);
		     Dispose(PNInputItem(List));
		   end;
    blVIFButton : Dispose(PVIFItem(List));
    blTextButton: begin
		    DisposeStr(PButtonItem(List)^.Text);
		    Dispose(PButtonItem(List));
		  end;
    blCheckBox : begin
		   DisposeStr(PCheckBoxItem(List)^.Text);
		   Dispose(PCheckBoxItem(List));
		 end;
    else Dispose(List);
  end;
end;

{***************************** GETBLOCK *************************}
function GetBlock;
var
  S:String;
  P:PLinkItem;
  B:PView;
  T:TPoint;
  BlockType : Byte;
  Delta:Byte;
  temp:string[80];
begin
  GetBlock := '';
  S        := '';
  P := List;
  while P <> NIL do begin
    BlockType := P^.Class;
    T.X := x;
    T.Y := y;
    if PInputItem(P)^.Prompt = NIL then temp := '' else temp := PInputItem(P)^.Prompt^;
    case BlockType of
      blCheckBox   :
	 B := New(PSingleCheckBox,Init(x,y,ViewFont,PCheckBoxItem(P)^.Text^));
      blInputLine  :
	 B := New(PInputStr,
	   Init(x,y,0,temp,
		      PInputItem(P)^.Len,
		      PInputItem(P)^.Config));
      blNInputLine  :
	 B := New(PInputNum,
	   Init(x,y,PNInputItem(P)^.Len,temp,
		      PNInputItem(P)^.NumType,
		      PNInputItem(P)^.Digit1,
		      PNInputItem(P)^.Digit2,
		      PNInputItem(P)^.Config));
      blVIFButton  : B := New(PVIFButton,Init(t.x,t.y,PVIFItem(P)^.VIF,
						PVIFItem(P)^.Command));
      blTextButton : B := New(PButton,Init(t.x,t.y,PButtonItem(P)^.Text^,
					     PButtonItem(P)^.Command));
    end; {case}
    case BlockType of
      blInputLine,
      BlNInputLine : begin
		      B^.SetViewID(PInputItem(P)^.IdNumber);
		      B^.SetGroupID(PInputItem(P)^.GrupNum);
		    end;
    end; {case}
    if Options and mnfNoSelect > 0 then B^.Options := B^.Options and not Ocf_Selectable;
    if Options and mnfHorizontal > 0 then inc(x,B^.Size.X+P^.Delta);
    if Options and mnfVertical > 0 then inc(y,B^.Size.Y+P^.Delta);
    S := S + PtrStr(B);
    P := P^.Next;
  end;
  GetBlock := S;
  DisposeLink(List);
end;

{************************** NEWCHECKBOXITEM **************************}
function  NewCheckBox;
var
  P:PCheckBoxItem;
begin
  New(P);
  if P = NIL then Error('NewCheckBoxItem','Insufficient memory');
  P^.Text  := NewStr(AText);
  P^.Next  := Next;
  P^.Class := blCheckBox;
  P^.Delta := 3;
  NewCheckBox := P;
end;

{**************************** NEWINPUTITEM *****************************}
function NewInputItem;
begin
  NewInputItem := NewInputIdItem(APrompt,ALen,AConfig,0,0,Next);
end;

function NewInputIdItem;
var
  P:PInputItem;
begin
  New(P);
  P^.Class   := blInputLine;
  P^.Delta   := 6;
  P^.Prompt  := NewStr(APrompt);
  P^.Len     := ALen;
  P^.Next    := Next;
  P^.Config  := AConfig;
  P^.IdNumber:= AIdNumber;
  P^.GrupNum := AGrpNum;
  NewInputIdItem := P;
end;

function NewNInputItem;
begin
  NewNInputItem := NewNInputIdItem(APrompt,ALen,Numtype,D1,D2,AConfig,0,0,Next);
end;

function NewNInputIdItem;
var
  P:PNInputItem;
begin
  New(P);
  if P = NIL then Error('NewInputIdItem','Insufficient memory');
  P^.Class   := blNInputLine;
  P^.Delta   := 6;
  P^.Prompt  := NewStr(APrompt);
  P^.Next    := Next;
  P^.Len     := ALen;
  P^.Config  := AConfig;
  P^.NumType := NumType;
  P^.Digit1  := D1;
  P^.Digit2  := D2;
  P^.IdNumber := AId;
  P^.GrupNum  := AGrp;
  NewNInputIdItem := P;
end;
{****************************** NEWVIFITEM ******************************}
function NewVIFItem;
var
  P:PVIFItem;
begin
  New(P);
  if P = NIL then Error('NewVIFItem','Insufficient memory');
  P^.VIF     := AVIF;
  P^.Class   := blVIFButton;
  P^.Delta   := 3;
  P^.Command := ACommand;
  P^.Next := Next;
  NewVIFItem := P;
end;

{**************************** TMENUWINDOW *********************************}
constructor TMenuWindow.Init;
var
  R:TRect;
begin
  R.Assign(0,0,0,0);
  inherited Init(R,AHdr);
  InsertBlock(Items);
  SelectNext(True);
  FitBounds;
  Origin.X := x;
  Origin.Y := y;
end;

{**************************** NewButton ********************************}
function NewButton;
var
  P:PButtonItem;
begin
  New(P);
  P^.Text := NewStr(AText);
  P^.Command := ACommand;
  P^.Delta   := 3;
  P^.Class   := blTextButton;
  P^.Next    := Next;
  NewButton  := P;
end;

{**************************** MAXCHOICELENGTH **********************}
function MaxChoiceLength(CList:PChooserItem):byte;
var
  P:PChooserItem;
  Max : Byte;
  b   : byte;
begin
  MaxChoiceLength := 0;
  if CList = NIL then exit;
  Max := 0;
  P := CList;
  while P <> NIL do begin
    b := Length(P^.Text^);
    if b > Max then Max := b;
    P := P^.Next;
  end;
  MaxChoiceLength := Max;
end;

{************************** GETCHOICECOUNT *****************************}
function GetChoiceCount(CList:PChooserItem):word;
var
  P:PChooserItem;
  c:word;
begin
  GetChoiceCount := 0;
  if CList = NIL then exit;
  c := 0;
  P := CList;
  while P <> NIL do begin
    inc(c);
    P := P^.Next;
  end;
  GetChoiceCount := c;
end;

{****************************** TCHOOSER *****************************}
constructor TChooser.Init;
var
  R:TRect;
  Count:Word;
  l : word;
begin
  Count := GetChoiceCount(AList);
  if Count < 2 then Fail;
  R.Assign(0,0,0,0);
  l := MaxChoiceLength(AList)*ViewFontWidth;
  R.B.X := ((chcShadowSize+chcXGAP) * 2) + l;
  R.B.Y := (chcShadowSize * 2) + Count*(GetFontHeight(ViewFont)+chcYGAP) + chcYGAP;
  R.Move(x,y);
  TView.Init(R);
  List     := AList;
  MaxItems := Count;
  MaxLength:= l;
  FocusedItem := 1;
  Options  := Ocf_Selectable or Ocf_FirstClick;
  EventMask:= EventMask or evKeyDown or evMouseDown;
{  HelpContext := Ctx_Chooser;}
end;

function TChooser.Execute:word;
var
  Event:TEvent;
begin
  SetState(Scf_Modal,True);
  repeat
   GetEvent(Event);
   if Event.What <> EvNothing then HandleEvent(Event);
  until State and Scf_Modal = 0;
  Execute := ExitCode;
end;

function TChooser.DataSize : word;
begin
  DataSize := 2;
end;

procedure TChooser.SetData;
begin
  FocusItem(word(rec));
end;

procedure TChooser.GetData;
begin
  word(rec) := FocusedItem;
end;

destructor TChooser.Done;
begin
  if List <> NIL then DisposeChooserItem(List);
  List := NIL;
  inherited Done;
end;

procedure TChooser.SetState;
    begin
       TView.SetState(AState,Enable);
       if AState and Scf_Focused > 0 then begin
	   PaintBegin;
	   PaintItem(GetItem(FocusedItem));
	   PaintEnd;
	 end;
    end;

procedure TChooser.FocusItem;
var
  f:PChooserItem;
begin
  if Index = FocusedItem then exit;
  if Index < 1 then Index := 1;
  F := GetItem(FocusedItem);
  FocusedItem := Index;
  PaintBegin; {GRRR!}
  PaintItem(F);
  PaintItem(GetItem(FocusedItem));
  PaintEnd;
end;

procedure TChooser.HandleKeyEvents;
begin
  if Event.CharCode = #32 then SelectItem(FocusedItem) else
  case Event.KeyCode of
    kbUp    : if FocusedItem > 1 then FocusItem(FocusedItem - 1) else exit;
    kbDown  : if FocusedItem < MaxItems then FocusItem(FocusedItem + 1) else exit;
    kbEnter : if GetState(Scf_Modal) then EndModal(FocusedItem) else
		 Owner^.SelectNext(True);
    kbEsc   : if GetState(Scf_Modal) then EndModal(cmCancel) else exit;
  else
    exit;
  end;
  ClearEvent(Event);
end;

procedure TChooser.SelectItem;
begin
  FocusItem(Index);
end;

procedure TChooser.HandleMouseEvents;
var
  P    : PChooserItem;
  T    : TPoint;
  Yeah : boolean;
  R    : TRect;
  c    : word;
begin
  if Event.What and evMouse = 0 then exit;
  if Event.What = EvMouseMove then
    if (Event.Buttons and mbLeft = 0) then exit;
  if not GetState(Scf_Focused) then exit;
  T := Event.Where;
  MakeLocal(T,T);
  GetExtent(R);
  if not R.Contains(T) then exit;
  ClearEvent(Event);
  P := List;
  yeah := False;
  c := 0;
  repeat
    GetItemBounds(P,R);
    yeah := R.Contains(T);
    P := P^.Next;
    inc(c);
  until Yeah or (P = NIL);
  if not Yeah then exit;
  FocusItem(c);
  SelectItem(c);
  if GetState(Scf_Modal) then EndModal(FocusedItem);
end;

procedure TChooser.HandleEvent;
begin
  TView.HandleEvent(Event);
  case Event.What of
    evKeyDown :
      HandleKeyEvents(Event);
    evMouseDown,evMouseMove :
      HandleMouseEvents(Event);
    else exit;
  end;
end;

function TChooser.GetItem;
var
  c:word;
  P:PChooserItem;
begin
  if index < 1 then index := 1 else if index > maxitems then index := maxitems;
  P := List;
  GetItem := NIL;
  c := 1;
  while (P <> NIL) and (c <> Index) do begin
    inc(c);
    P := P^.Next;
  end;
  if c = Index then GetItem := P;
end;

function TChooser.GetItemIndex;
var
  P:PChooserItem;
  c:word;
begin
  GetItemIndex := 0;
  if Item = NIL then exit;
  c := 1;
  P := List;
  while (P <> NIL) and (Item <> P) do begin
    inc(c);
    P := P^.Next;
  end;
  if Item <> P then exit;
  GetItemIndex := c;
end;

procedure TChooser.GetItemBounds;
var
  Index:Word;
begin
  Bounds.Assign(0,0,0,0);
  if Item = NIL then exit;
  Index := GetItemIndex(Item);
  Bounds.A.X := chcShadowSize+chcXGAP;
  Bounds.B.X := Bounds.A.X + MaxLength;
  Bounds.A.Y := chcYGAP+chcShadowSize+(Index-1)*(chcYGAP+ViewFontHeight);
  Bounds.B.Y := Bounds.A.Y + ViewFontHeight;
end;

procedure TChooser.PaintItem;
var
  Index:Word;
  R:TRect;
begin
  if not GetState(Scf_Exposed) then exit;
  Index := GetItemIndex(P);
  if Index = 0 then exit;
  GetItemBounds(P,R);
  SetColor(Col_Back);
  R.Grow(2,2);
  dec(R.B.Y);
  if (Index = FocusedItem) then begin
     SetTextColor(cWhite,Col_Back);
     if GetState(Scf_Focused) then ShadowBox(R,True)
			      else XBox(R,False);
  end else begin
      SetTextColor(cBlack,Col_Back);
      XBox(R,False);
  end;
  inc(R.B.Y);
  R.Grow(-2,-2);
  XWriteStr(R.A.X,R.A.Y,R.B.X-R.A.X,P^.Text^);
end;

procedure TChooser.PaintItems;
var
  P:PChooserItem;
begin
  P := List;
  while P <> NIL do begin
    PaintItem(P);
    P := P^.Next;
  end;
end;

procedure TChooser.Paint;
var
  R:TRect;
begin
  PaintBegin;
    GetExtent(R);
    ShadowBox(R,True);
    R.Grow(-1,-1);
    SetFillStyle(SolidFill,Col_Back);
    XBox(R,True);
    R.Grow(-(chcShadowSize-3),-(chcShadowSize-3));
    ShadowBox(R,False);
    PaintItems;
  PaintEnd;
end;

{***************************** NEWCHOOSER ****************************}
function NewChooser;
var
  P:PChooserItem;
begin
  NewChooser := NIL;
  New(P);
  P^.Text    := NewStr(S);
  P^.Next    := ANext;
  NewChooser := P;
end;

{**************************** DISPOSECHOOSERITEM **********************}
procedure DisposeChooserItem(CList:PChooserItem);
begin
  if CList^.Next <> NIL then DisposeChooserItem(CList^.Next);
  if CList^.Text <> NIL then DisposeStr(CList^.Text);
  Dispose(CList);
end;

{*************************** EXECUTECHOOSER ***************************}
function ExecuteChooser;
var
  P:PChooser;
begin
  if GSystem = NIL then exit;
  P := New(PChooser,Init(x,y,CList));
  ExecuteChooser := GSystem^.ExecView(P);
  if P <> NIL then Dispose(P,Done);
  if CList <> NIL then DisposeChooserItem(CList);
  Clist := NIL;
end;

{*************************** TRADIOBUTTON ***************************}
constructor TRadioButton.Init;
var
  P:PVIFMap;
begin
  TView.Init(Bounds); {tview is a must}
  Font := AFont;
  FontH := GetFontHeight(Font);
  MaxItems    := GetChoiceCount(AList);
  List        := AList;
  FocusedItem := 1;
  ActiveItem  := 1;
  Options     := Ocf_Selectable or Ocf_Firstclick;
  EventMask   := EventMask or evKeyDown or evMouseDown;
{  HelpContext := Ctx_RadioButton;}
  P := GetImagePtr(Rid_RadioButtonActive);
  YINC := (P^.YSize - FontH) div 2;
end;

procedure TRadioButton.SelectItem;
var
  oa:word;
begin
  if Index < 1 then Index := 1;
  oa := ActiveItem;
  ActiveItem := Index;
  PaintBegin;
    PaintItem(GetItem(oa));
    PaintItem(GetItem(ActiveItem));
  PaintEnd;
end;

procedure TRadioButton.SetData;
begin
  SelectItem(word(rec));
end;

procedure TRadioButton.GetData;
begin
  word(rec) := ActiveItem;
end;

procedure TRadioButton.Paint;
var
  R:TRect;
begin
  PaintBegin;
    GetExtent(R);
    SetFillStyle(SolidFill,Col_Back);
    ShadowBox(R,False);
    R.Grow(-1,-1);
    XBox(R,True);
    PaintItems;
  PaintEnd;
end;

procedure TRadioButton.PaintItem;
var
  Index:Word;
  R:TRect;
  VIF:PVIFMap;
  xgap:integer;
begin
  if P = NIL then exit;
  if not GetState(Scf_Exposed) then exit;
  Index := GetItemIndex(P);
  if Index = 0 then exit;
  GetItemBounds(P,R);
  SetTextColor(Col_RButtonPassive,Col_Back);
  if ActiveItem = Index then
    VIF := GetImagePtr(Rid_RadioButtonActive)
  else
    VIF := GetImagePtr(Rid_RadioButtonPassive);
  if FocusedItem = Index then
    if GetState(Scf_Focused) then
       SetTextColor(Col_RButtonActive,Col_Back);
  XPutVIF(r.a.x,r.a.y,VIF^);
  xgap := VIF^.XSize+3;
  XPrintStr(r.a.x+xgap,r.a.y+YINC,r.b.x-r.a.x-xgap,Font,P^.Text^);
end;

procedure TRadioButton.GetItemBounds;
var
  Index:word;
  P:PVIFMap;
begin
  Index := GetItemIndex(Item);
  GetExtent(Bounds);
  inc(Bounds.A.X,rbcXGAP);
  dec(Bounds.B.X);
  P := GetImagePtr(Rid_RadioButtonActive);
  inc(Bounds.A.Y,(Index-1)*(P^.YSize+rbcYGAP)+rbcYGAP);
  Bounds.B.Y := Bounds.A.Y+P^.YSize;
end;

{****************************** TMESSAGEVIEW **************************}
constructor TMessageView.Init;
var
  R:TRect;
begin
  R.Assign(0,0,length(amsg)*ViewFontWidth+20,ViewFontHeight*3);
  inherited Init(R);
  Options   := Ocf_Centered;
  EventMask := 0;
  Msg       := NewStr(amsg);
end;

destructor TMessageView.Done;
begin
  if Msg <> NIL then DisposeStr(Msg);
  inherited Done;
end;

procedure TMessageView.Paint;
var
  R:TRect;
begin
  PaintBegin;
    GetExtent(R);
    SetFillStyle(SolidFill,Col_BAck);
    SetTextColor(Col_StaticText,Col_Back);
    ShadowBox(R,True);
    R.Grow(-1,-1);
    XBox(R,True);
    R.Grow(-4,-4);
    ShadowBox(R,False);
    if Msg <> NIL then XWriteStr(10,8,size.x-20,Msg^);
  PaintEnd;
end;

{- TMenuBox -}
constructor TMenuBox.Init;
var
  R:TRect;
  xsize:word;
  ysize:word;
  P:PMenuItem;
begin
  xsize := GetMaxSize(AMenu)+20;
  P := AMenu^.Items;
  ysize := 8;
  while P <> NIL do begin
    if P^.Name = NIL then inc(ysize,6) {newline size}
                     else inc(ysize,ViewFontHeight+8);
    P := P^.Next;
  end;
  R.Assign(0,0,xsize,ysize);
  R.Move(x,y);
  inherited Init(R);
  Options   := Options or Ocf_TopSelect;
  Menu      := AMenu;
  Focused   := Menu^.Default;
  endit     := true;
end;

procedure TMenuBox.GetItemBounds;
var
  Search:PMenuItem;
begin
  R.A.X := 4;
  R.B.X := Size.X-4;
  R.A.Y := 4;
  Search := Menu^.Items;
  while Search <> P do begin
    if Search^.Name = NIL then inc(r.a.y,6) {newline size}
                          else inc(r.a.y,ViewFontHeight+8);
    Search := Search^.Next;
  end;
  if P^.Name = NIL then R.B.Y := R.A.Y + 6
                   else R.B.Y := R.A.Y + ViewFontHeight+7;
end;

procedure TMenuBox.HandleEvent;
var
  PI:PMenuItem;
  ismodal:boolean;
  function SearchOwner : PMenuItem;
  var
    Search:PMenuView;
    P:PMenuItem;
  begin
    SearchOwner := NIL;
    Search := Parent; {looking if other menus selected}
    while Search <> NIL do begin
      if not MouseInView(Event.Where) then P := Search^.GetPointedItem(Event)
                                      else P := NIL;
      if (P <> NIL) and (P <> Search^.Focused) then begin
        SearchOwner := P;
        exit;
      end;
      Search := Search^.Parent;
    end; {while}
  end;
begin
  inherited HandleEvent(Event);
  if Event.What = evNothing then exit;
  ismodal := GetState(Scf_Modal);
  case Event.What of
    evKeyDown :  if ismodal then case Event.KeyCode of
                     kbUp    : FocusPrev;
                     kbDown  : FocusNext;
                     kbLeft : begin
                                if Parent <> NIL then
                                  if Parent^.Focused = Parent^.Menu^.Items then exit;
                                PutEvent(Event);
                                EndModal(0);
                              end;
                     kbRight : begin
                                if Parent <> NIL then
                                  if Parent^.Focused^.Next = NIL then exit;
                                PutEvent(Event);
                                EndModal(0);
                              end;
                     else if Event.CharCode > #0 then begin
                       PI := Menu^.Items;
                       Event.Charcode := Upcase(Event.Charcode);
                       while (PI <> NIL) and (GetTilda(PI) <> Event.Charcode) do
                         PI := PI^.Next;
                       if PI = NIL then exit;
                       Activate(PI);
                     end else begin
                       if Parent <> NIL then
                         if GetTilda(Parent^.Focused) = GetAltChar(Event.KeyCode)
                           then exit;
                       PutEvent(Event);
                       EndModal(0);
                     end;
                   end else exit; {case}
      evMouseDown,evMouseMove : if Event.Buttons > 0 then begin
                      if Parent <> NIL then begin
                        PI := SearchOwner;
                        if PI <> NIL then begin
                          Event.What := evMouseDown;
                          PutEvent(Event);
                          EndModal(0);
                          ClearEvent(Event);
                          exit; {<<---  !!! this is a must}
                        end;
                      end;
                      PI := GetPointedItem(Event);
                      if (PI <> NIL) then if PI <> Focused then FocusItem(PI);
                    end else exit;
      evMouseUp : begin
                    Event.What    := evMouseDown;
                    Event.Buttons := mbLeft;
                    PI            := GetPointedItem(Event);
                    if PI <> NIL then begin
                      if Parent <> NIL then if Parent^.Parent = NIL then
                        PutEvent(Event);
                      Activate(PI);
                      exit;
                    end else begin
                      if Parent <> NIL then
                        if Parent^.GetPointedItem(Event) = Parent^.Focused then
                          exit;
                      if not GetConfig(Mnc_NoImmed) then PutEvent(Event);
                      EndModal(0);
                    end;
                  end;
      else exit;
  end; {case big}
  ClearEvent(Event);
end;

{-----------------------------  TMenuBar  ----------------------------}

constructor TMenuBar.Init;
begin
  r.b.y := r.a.y + 15 + ViewFontHeight;
  inherited Init(R);
  Menu      := AMenu;
  Focused   := Menu^.Default;
end;

procedure TMenuBar.HandleEvent;
var
  P:PMenuItem;
  ok:boolean;
  c:char;
  procedure xPrev;
  begin
    FocusPrev;
    Activate(Focused);
  end;
  procedure xNext;
  begin
    FocusNext;
    Activate(Focused);
  end;
begin
  inherited HandleEvent(Event);
  if Event.What = evNothing then exit;
  ok := GetState(Scf_Modal);
  c  := Event.Charcode;
  case Event.What of
    evKeyDown : case Event.KeyCode of
                  kbLeft  : if ok then xPrev else exit;
                  kbRight : if ok then xNext else exit;
                  kbDown  : if ok and (Focused^.SubMenu <> NIL) then Activate(Focused) else exit;
                  else if c = #0 then begin
                    c := Upcase(GetAltChar(Event.KeyCode));
                    P := Menu^.Items;
                    while (P <> NIL) and (GetTilda(P) <> c) do
                      P := P^.Next;
                    if P = NIL then exit;
                    if not ok then PutEvent(Event);
                    Activate(P);
                  end else exit;
                end; {case keycode}
    evMouseDown : begin
                    P := GetPointedItem(Event);
                    if P <> NIL then begin
                      if not ok then PutEvent(Event);
                      Activate(P);
                    end else if ok and not MouseInView(Event.Where) then
                        EndModal(0) else exit; {if}
                  end; {begin}
    else exit;
  end; {case what}
  ClearEvent(Event);
end;

procedure TMenuBar.GetItemBounds;
var
  Search:PMenuItem;
begin
  Search:=Menu^.Items;
  R.A.X := 10;
  R.A.Y := 3;
  R.B.Y := R.A.Y + FontH + 7;
  while Search <> P do begin
    inc(R.A.X,GetStrSize(Search^.Name^)+16);
    Search := Search^.Next;
  end;
  R.B.X := R.A.X + GetStrSize(P^.Name^) + 8;
end;

destructor TMenuBar.Done;
begin
  if Menu <> NIL then begin
    DisposeMenu(Menu);
    Menu := NIL;
  end;
  inherited Done;
end;

{----------------------------  TMenuView  ----------------------------}

procedure TMenuView.Paint;
var
  R:TRect;
begin
  PaintBegin;
    GetExtent(R);
    SetFillStyle(SolidFill,Col_Back);
    ShadowBox(R,True);
    R.Grow(-1,-1);
    XBox(R,True);
    PaintItems;
  PaintEnd;
end;

constructor TMenuView.Init;
begin
  inherited Init(R);
  EventMask := evMouse or evKeyDown or evBroadcast;
  Options   := (Options or Ocf_PreProcess+Ocf_FirstClick) and not Ocf_Selectable;
  if MenuFont <> 0 then Font := MenuFont else Font := ViewFont;
  FontH := GetFontHeight(Font);
end;

function TMenuView.GetStrSize(s:string):word;
var
  b:byte;
begin
  b := pos('~',s);
  if b > 0 then delete(s,b,1);
  GetStrSize := GetStringSize(Font,s);
end;

function TMenuView.GetMaxSize;
var
  P:PMenuItem;
  len:word;
  maxlen:word;
begin
  P := aMenu^.Items;
  maxlen := 0;
  while P <> NIL do begin
    len := 0;
    if P^.Name <> NIL then len := GetStrSize(P^.Name^);
    if len > maxlen then maxlen := len;
    P := P^.Next;
  end;
  GetMaxSize := maxlen;
end;

function TMenuView.GetTilda;
var
  b:byte;
begin
  GetTilda := #0;
  if P^.Name <> NIL then begin
    b := pos('~',P^.Name^);
    if b <> 0 then GetTilda := Upcase(P^.Name^[b+1]);
  end;
end;

procedure TMenuView.Activate;
var
  Event:TEvent;
  R:TRect;
  PM:PMenuBox;
  w:word;
begin
  if P^.Name = NIL then exit;
  if not GetState(Scf_Modal) then begin
    Menu^.Default := P;
    Modalize := true;
    exit;
  end;
  FocusItem(P);
  if P^.SubMenu <> NIL then begin
    GetItemBounds(P,R);
    MakeGlobal(r.a,r.a);
    MakeGlobal(r.b,r.b);
    if endit then begin
      dec(r.a.y,4);
      r.a.x := r.b.x+5
    end else r.a.y := r.b.y+5;
    New(PM,Init(r.a.x,r.a.y,P^.SubMenu));
    PM^.Parent := @Self;
    PM^.GetBounds(r);
    if r.b.x > GSystem^.Size.X then R.Move(GSystem^.Size.X-r.b.x,0);
    if r.b.y > GSystem^.Size.y then R.Move(0,GSystem^.Size.y-r.b.y);
    PM^.ChangeBounds(R);
    w := GSystem^.ExecView(PM);
    if PM <> NIL then Dispose(PM,Done);
    if (w <> 0) then EndModal(w);
  end else EndModal(P^.Command);
end;

procedure TMenuView.FocusPrev;
var
  P:PMenuItem;
  function GetPrev(This:PMenuItem):PMenuItem;
  var
    search:PMenuItem;
  begin
    GetPrev := NIL;
    search := Menu^.Items;
    if (This = NIL) or (This = search) then exit;
    while (search^.Next <> This) do search := search^.Next;
    if search^.Name = NIL then GetPrev := GetPrev(search)
                          else GetPrev := search;
  end;
begin
  if Focused = NIL then Error('TMenuView.FocusPrev','Focused nil');
  P := GetPrev(Focused);
  if P <> NIL then FocusItem(P);
end;

procedure TMenuView.FocusNext;
var
  P:PMenuItem;
begin
  if Focused = NIL then Error('TMenuView.FocusNext','Focused nil');
  P := Focused;
  while (P^.Next <> NIL) and (P^.Next^.Name = NIL) do
    P := P^.Next;
  if P^.Next <> NIL then FocusItem(P^.Next);
end;

function TMenuView.GetPointedItem(var Event:TEvent):PMenuItem;
var
  Item:PMenuItem;
  T:TPoint;
  R:TRect;
begin
  GetPointedItem := NIL;
  if (Event.Buttons = 0) or (Menu = NIL) then exit;
  Item := Menu^.Items;
  MakeLocal(Event.Where,T);
  while Item <> NIL do begin
    GetItemBounds(Item,R);
    if R.Contains(T) then begin
      GetPointedItem := Item;
      exit;
    end;
    Item := Item^.Next;
  end;
end;

procedure TMenuView.HandleEvent;
var
  w:word;
  Ev:TEvent;
begin
  if Modalize then begin
    Modalize := false;
    w := Execute;
    if w > 0 then Message(Owner,evCommand,w,NIL);
    ClearEvent(Event);
    exit;
  end;
  case Event.What of
    evKeyDown : if GetState(Scf_Modal) then case Event.KeyCode of
                  kbEnter : Activate(Focused);
                  kbEsc : begin
                            if Parent <> NIL then if Parent^.Parent = NIL then PutEvent(Event);
                            EndModal(0);
                          end;
                  else exit;
                end else exit; {case keycode}
    else exit;
  end; {case what}
  ClearEvent(Event);
end;

procedure TMenuView.FocusItem(Item:PMenuItem);
var
  OldFocused:PMenuItem;
begin
  if Item = NIL then exit;
  if Item^.Name = NIL then exit;
  if Focused = Item then begin
    PaintBegin;
    PaintItem(Focused);
    PaintEnd;
    exit;
  end;
  OldFocused := Focused;
  Focused    := Item;
  Menu^.Default    := Item;
  PaintBegin;
  PaintItem(OldFocused);
  PaintItem(Focused);
  PaintEnd;
end;

function TMenuView.GetLastItem;
var
  P:PMenuItem;
begin
  GetLastItem := NIL;
  P := Menu^.Items;
  if P = NIL then Error('TMenuView.GetLastItem','No items');
  while P^.Next <> NIL do P := P^.Next;
  GetLastItem := P;
end;

procedure TMenuView.PaintItems;
var
  P:PMenuItem;
begin
  P := Menu^.Items;
  while P <> NIL do begin
    PaintItem(P);
    P := P^.Next;
  end;
end;

procedure TMenuView.PaintItem;
var
  R:TRect;
  y:integer;
begin
  GetItemBounds(P,R);
  if P^.Name <> NIL then begin
    if (Focused = P) and GetState(Scf_Modal) then ShadowBox(R,True) else begin
      SetColor(Col_Back);
      XBox(R,False);
    end;
    R.Grow(-(((R.B.Y-R.A.Y)-FontH) div 2),-4);
    XTilda(r.a.x,r.a.y,P^.Name^,Font,Col_ButtonTextNormal,Col_Back);
  end else begin {we have a newline right here}
    y := r.a.y + 2;
    GetExtent(R);
    SetColor(cDarkGray);
    XLine(r.a.x,y,r.b.x,y);
    SetColor(cWhite);inc(y);
    XLine(r.a.x,y,r.b.x,y);
  end;
end;

function TMenuView.Execute;
var
  Event:TEvent;
begin
  SetState(Scf_Modal,True);
  if (Parent <> NIL) or GetConfig(Mnc_NoImmed) then FocusItem(Menu^.Default)
                                               else Activate(Menu^.Default);
  repeat
    GetEvent(Event);
    if Event.What <> evNothing then HandleEvent(Event);
  until not GetState(Scf_Modal);
  Execute := ExitCode;
  FocusItem(Focused);
end;

procedure TMenuView.GetItemBounds;
begin
  R.Assign(0,0,0,0);
end;

function TMenuView.GetItemIndex;
var
  index:integer;
  Search:PMenuItem;
begin
  Search := Menu^.Items;
  index := 0;
  while (Search <> NIL) and (Search <> P) do begin
    inc(index);
    Search := Search^.Next;
  end;
  if Search = NIL then GetItemIndex := 0
                  else GetItemIndex := index;
end;

{----------------------  Memory Allocation Commands ------------------}

function NewLine;
var
  P:PMenuItem;
begin
  New(P);
  FillChar(P^,SizeOf(P^),0);
  P^.Next := Next;
  NewLine := P;
end;

function NewSubMenu;
var
  P:PMenuItem;
begin
  New(P);
  FillChar(P^,SizeOf(P^),0);
  P^.Name    := NewStr(Name);
  P^.SubMenu := SubMenu;
  P^.Next    := Next;
  NewSubMenu := P;
end;

function NewItem;
var
  P:PMenuItem;
begin
  New(P);
  P^.Name     := NewStr(Name);
  P^.Command  := Command;
  P^.Next     := Next;
  P^.SubMenu  := NIL;
  P^.Disabled := false;
  NewItem := P;
end;

function NewMenu;
var
  P:PMenu;
begin
  NewMenu := NIL;
  if Items = NIL then exit;
  New(P);
  P^.Items   := Items;
  P^.Default := Items;
  NewMenu := P;
end;

procedure DisposeMenu;
begin
  if Menu^.Items <> NIL then DisposeMenuItem(Menu^.Items);
  Dispose(Menu);
end;

procedure DisposeMenuItem;
begin
  if Item^.Next <> NIL then DisposeMenuItem(Item^.Next);
  if Item^.Name <> NIL then DisposeStr(Item^.Name);
  if Item^.SubMenu <> NIL then DisposeMenu(Item^.SubMenu);
  Dispose(Item);
end;

{*************************  TPROCVIEW  ************************************}
constructor TProcView.Init;
begin
  inherited Init(R);
  Options   := Ocf_Selectable or Ocf_TopSelect or Ocf_Centered;
  EventMask := 0;
  FontID    := afont;
end;

destructor TProcView.Done;
begin
  if Text <> NIL then DisposeStr(Text);
  inherited Done;
end;

procedure TProcView.NewText;
begin
  if Text <> NIL then DisposeStr(Text);
  Text := NewStr(s);
  PaintBegin;
  PaintText;
  PaintEnd;
end;

procedure TProcView.NewPerc(avalue,amax:longint);
begin
  Value := avalue;
  Max   := amax;
  PaintBegin;
  PaintPerc;
  PaintEnd;
end;

procedure TProcView.PaintText;
var
  R:TRect;
begin
  if Text <> NIL then begin
    GetExtent(R);
    R.Grow(-6,-6);
    SetTextColor(cBlack,Col_Back);
    XPrintStr(r.a.x,r.a.y,r.b.x-r.a.x,FontID,Text^);
  end;
end;

procedure TProcView.PaintPerc;
var
  ThoseWereTheDays : comp;
  hebe:longint;
  tcur,tmax:comp;
  R,R2 : TRect;
begin
  GetExtent(R);
  R.Grow(-4,-4);
  inc(R.A.Y,GetFontHeight(FontID)+5);
  ShadowBox(R,False);
  R.Grow(-1,-1);
  ShadowBox(R,False);
  R.Grow(-1,-1);
  if Max = 0 then begin
    SetFillStyle(SolidFill,cBlack);
    XBox(R,True);
  end else begin
    SetFillStyle(SolidFill,cLightRed);
    tcur := value;
    tmax := max;
    thosewerethedays := (tcur/tmax)*(r.b.x-r.a.x);
    hebe := trunc(thosewerethedays);
    XBar(r.a.x,r.a.y,r.a.x+hebe,r.b.y);
    SetFillStyle(SolidFill,cBlack);
    XBar(r.a.x+hebe,r.a.y,r.b.x,r.b.y);
  end;
end;

procedure TProcView.Paint;
var
  R:TRect;
begin
  PaintBegin;
  SetFillStyle(SolidFill,Col_Back);
  GetExtent(R);
  ShadowBox(R,True);
  R.Grow(-1,-1);
  ShadowBox(R,True);
  R.Grow(-1,-1);
  XBox(R,True);
  PaintText;
  PaintPerc;
  PaintEnd;
end;

{ TDesktop - desktop object (isn't it clear enough?) }

constructor TDesktop.Init;
begin
  inherited Init(R);
  Options := Ocf_Selectable or Ocf_PreProcess or Ocf_FirstClick;
  InitBackground(R);
  Insert(Background);
end;

procedure TDesktop.InitBackground(var R:TRect);
begin
  New(Background,Init(R));
end;

{ Column procs }
function NewColumn(atitle:string; awidth:integer; aflags:byte; anext:PColumn):PColumn;
var
  P:PColumn;
begin
  New(P,Init);
  P^.Title := NewStr(atitle);
  P^.Width := awidth;
  P^.Flags := aflags;
  P^.Next := anext;
  NewColumn := P;
end;

procedure DisposeColumn(P:PColumn);
begin
  if P^.Next <> NIL then DisposeColumn(P^.Next);
  if P^.Title <> NIL then DisposeStr(P^.Title);
  Dispose(p,Done);
end;

{ TFormattedLister }
constructor TFormattedLister.Init;
var
  R:TRect;
  afonth:integer;
  P:PColumn;
  totxsize:integer;
  totysize:integer;
  acolc:integer;
begin
  afonth := GetFontHeight(afont);
  totxsize := 0;
  P := acolumns;
  acolc := 0;
  while P <> NIL do begin
    inc(totxsize,P^.Width);
    inc(acolc);
    P := P^.Next;
  end;
  totysize := ((afonth+2)*arows)+4+afonth+1;
  R.Assign(0,0,totxsize-1,totysize-1);
  R.Move(x,y);
  inherited Init(R,afont);
  Rows       := arows;
  ColumnList := acolumns;
  ColumnCount := acolc;
end;

destructor TFormattedLister.Done;
begin
  if ColumnList <> NIL then DisposeColumn(ColumnList);
  inherited Done;
end;

procedure TFormattedLister.GetItemBounds;
begin
  abounds.Assign(0,0,Size.X-1,FontH+1);
  abounds.Move(0,((item-scrtop)*(FontH+2))+FontH+3);
end;

procedure TFormattedLister.PaintItem;
var
  R:TRect;
  s:string;
  sub:string;
  P:PColumn;
  y:integer;
  x:integer;
  counter:integer;
  printwidth:integer;
  textwidth : integer;
  emptyline:boolean;
  isfocused:boolean;
  amifocused:boolean;
  shadow:boolean;
  fc:byte;
begin
  P := ColumnList;
  emptyline := false;
  if (itemList = NIL) then emptyline := true else
    if (item > itemlist^.count-1) then emptyline := true;
  if not emptyline then s := GetText(item);
  isfocused := FocusedItem = item;
  amifocused := GetState(Scf_Focused);
  shadow     := isfocused and amifocused;
  GetItemBounds(item,R);
  if not emptyline then begin
    fc := GetColor(item);
    {if isfocused and not amifocused then bc := flc_Focused;}
  end else fc := cBlack;
  if shadow then begin
    SetTextColor(Col_Back,fc);
    SetColor(fc);
  end else begin
    SetTextColor(fc,Col_Back);
    if isfocused then SetColor(cDarkGray) else SetColor(Col_Back);
  end;
  if emptyline then sub := #32;
  counter := 1;
  r.a.x := 2;
  while P <> NIL do begin
    r.b.x := r.a.x+(P^.Width-5);
{    if shadow then ShadowBox(R,True)
              else }XBox(R,False);
    if not emptyline then begin
      sub := GetParse(s,'|',counter);
      if sub = '' then sub := #32;
    end;
    inc(counter);
    printwidth := (r.b.x-r.a.x)-1;
    if (P^.Flags and cofRJust = 0) or emptyline then XPrintStr(r.a.x+1,r.a.y+1,printwidth,Font,sub) else begin
      textwidth := GetStringSize(Font,sub);
      if textwidth > printwidth then textwidth := printwidth else XPrintStr(r.a.x+1,r.a.y+1,(printwidth-textwidth),Font,#32);
      XPrintStr(r.a.x+1+(Printwidth-textwidth),r.a.y+1,textwidth,Font,sub);
    end;
    r.a.x := r.b.x+5;
    P := P^.Next;
  end;
end;

procedure TFormattedLister.PaintFrame;
var
  R:TRect;
  P:PColumn;
begin
  P := ColumnList;
  r.a.x := 0;
  r.a.y := FontH+1;
  r.b.y := Size.Y;
  while P <> NIL do begin
    r.b.x := r.a.x+P^.Width-1;
    ShadowBox(R,True);
    SetColor(col_back);
    XRectangle(r.a.x+1,r.a.y+1,r.b.x-1,r.b.y-1);
    r.a.x := r.b.x+1;
    P := P^.Next;
  end;
end;

procedure TFormattedLister.PaintHdr;
var
  P:PColumn;
  x:integer;
  awidth:integer;
begin
  P := ColumnList;
  x := 0;
  SetTextColor(cBlack,Col_Back);
  awidth := P^.Width+2;
  while P <> NIL do begin
    XPrintStr(x,0,awidth,Font,P^.Title^);
    inc(x,awidth);
    P := P^.Next;
    if P <> NIL then awidth := P^.Width;
  end;
  SetColor(col_back);
  XLine(0,FontH,Size.X,FontH);
end;

procedure TFormattedLister.Paint;
begin
  FastPaintBegin;
  PaintHdr;
  PaintFrame;
  PaintItems;
  PaintEnd;
end;

{- TColorButton -}
constructor TColorButton.Init;
begin
  inherited Init(abounds,aaction);
  Color := acolor;
end;

procedure TColorButton.PaintContents;
begin
  SetFillStyle(SolidFill,Color);
  XBox(R,True);
end;

{- TStaticText -}
constructor TStaticText.Init;
begin
  inherited Init(R);
  EventMask := 0;
  FC        := afc;
  BC        := abc;
  Font      := afont;
  FontH     := GetFontHeight(Font);
  Text      := NewStr(atext);
end;

destructor TStaticText.Done;
begin
  if Text <> NIL then DisposeStr(Text);
  inherited Done;
end;

procedure TStaticText.Paint;
var
  s:string;
  lastword:string;
  R:TRect;
  y:integer;
  b:byte;
  c:char;
  procedure outline(hebe:string);
  begin
    XPrintStr(0,y,Size.X+1,Font,hebe);
    XBar(0,y+FontH,Size.X+1,y+FontH+stxlineGAP);
    inc(y,FontH+stxlineGAP);
  end;
  function wrapit:boolean;
  begin
    wrapit := GetStringSize(Font,s+lastword) > Size.X;
  end;
begin
  GetExtent(R);
  PaintBegin;
    SetFillStyle(SolidFill,bc);
    if Text = NIL then XBox(R,True) else begin
      s := '';
      lastword := '';
      y := 0;
      SetTextColor(fc,bc);
      for b := 1 to length(Text^) do begin
        c := Text^[b];
        if c = #32 then if wrapit then begin
          OutLine(s);
          s := lastword+#32;
          lastword := '';
        end else begin
          s := s + lastword + #32;
          lastword := '';
        end else lastword := lastword + c;
      end;
      if wrapit then begin
        OutLine(s);
        OutLine(lastword);
      end else OutLine(s + lastword);
      if y <= Size.Y then begin
        r.a.y := y;
        XBox(R,true);
      end;
    end;
  PaintEnd;
end;

{- TSimplePerc -}
constructor TSimplePerc.Init(abounds:TRect; afc,abc:byte);
begin
  inherited Init(abounds);
  EventMask := evMouseDown;
  Options   := (Options or Ocf_FullDrag or Ocf_Move) and not Ocf_Selectable;
  Max       := 1;
  FC        := afc;
  BC        := abc;
end;

procedure TSimplePerc.Paint;
var
  R:TRect;
  gox:integer;
begin
  PaintBegin;
    GetExtent(R);
    SetColor(FC);
    ShadowBox(R,true);
    R.Grow(-1,-1);
    gox := (value*(Size.X-1)) div max;
    SetFilLStyle(SolidFill,FC);
    XBar(r.a.x,r.a.y,(r.a.x+gox)-1,r.b.y);
    SetFillStyle(SolidFill,BC);
    XBar(r.a.x+gox,r.a.y,r.b.x,r.b.y);
  PaintEnd;
end;

procedure TSimplePerc.NewPerc;
begin
  if amax = 0 then amax := 1;
  if aval > amax then aval := amax;
  Value := aval;
  Max   := amax;
  paint;
end;

{- TDynamicLabel -}
constructor TDynamicLabel.Init(x,y,xsize:integer; atext:string; afc,abc:byte; afont:word);
var
  R:TRect;
begin
  R.Assign(x,y,x+xsize,y+GetFontHeight(afont)-1);
  inherited Init(R);
  EventMask := 0;
  Text      := NewStr(atext);
  Font      := afont;
  FC        := afc;
  BC        := abc;
end;

destructor TDynamicLabel.Done;
begin
  if Text <> NIL then DisposeStr(Text);
  inherited Done;
end;

procedure TDynamicLabel.Paint;
var
  textwidth:word;
begin
  PaintBegin;
    SetTextColor(fc,bc);
    if GetConfig(lcRJust) then begin
      SetFillStyle(SolidFill,bc);
      textwidth := GetStringSize(Font,Text^);
      XBar(0,0,size.x-textwidth-1,size.y);
      XPrintStr(size.x-textwidth,0,textwidth,Font,Text^);
    end else XPrintStr(0,0,size.x+1,Font,text^);
  PaintEnd;
end;

procedure TDynamicLabel.NewText(atext:string);
begin
  if Text <> NIL then DisposeStr(Text);
  Text := NEwStr(atext);
  PaintView;
end;

{- TDateTimeViewer -}
constructor TDateTimeViewer.Init;
var
  R:TRect;
begin
  R.Assign(0,0,16*GetStringSize(afont,'A')+1,GetFontHeight(afont)+1);
  R.Move(x,y);
  inherited Init(R);
  Options   := Options or
               (Ocf_TopSelect or
               Ocf_AlwaysOnTop or
               Ocf_PostProcess or
               Ocf_FullDrag or
               Ocf_Move);
  EventMask := evMouse or evBroadcast;
  Font      := afont;
  GetMoment(Moment);
end;

procedure TDateTimeViewer.GetMoment(var amoment:TMoment);
var
  temp:word;
  xhour,xmin:word;
  xmonth,xday:word;
begin
  with amoment do begin
    GetTime(xhour,xmin,temp,temp);
    GetDate(year,xmonth,xday,temp);
    Hour := xhour;
    Min  := xmin;
    Month := xmonth;
    Day   := xday;
  end;
end;

procedure TDateTimeViewer.Paint;
var
  R:TRect;
  function tostr(hebe:byte):string;
  begin
    tostr := z2s(hebe,2);
  end;
begin
  PaintBegin;
    GetExtent(R);
    ShadowBox(R,True);
    if GetConfig(dtcAlarm) then SetTextColor(cRed,Col_Back)
                           else SetTextColor(cBlue,Col_Back);
    with Moment do XPrintStr(1,1,Size.X-1,Font,
       tostr(Day)+'/'+tostr(Month)+'/'+l2s(Year)+' '+tostr(Hour)+':'+tostr(Min));
  PaintEnd;
end;

procedure TDateTimeViewer.OnAlarm;
begin
end;

procedure TDateTimeViewer.OnTick;
begin
end;

procedure TDateTimeViewer.Backprocess;
var
  temp:TMoment;
begin
  GetMoment(temp);
  if not BufCmp(temp,Moment,SizeOf(Moment)) then begin
    GetMoment(Moment);
    PaintView;
    if GetConfig(dtcAlarm) then if BufCmp(Moment,Alarm,SizeOf(Moment)) then OnAlarm;
    OnTick;
  end;
end;

end.
*** End Of File ***
