{
Name     : XGH 2.05a
Purpose  : XHS Graphical Implementation
Coder    : SSG
Date     : 31st Mar 94

Update Info:
------------
31st Mar 94 - 21:12 - Starting at start...
02nd Apr 94 - 21:12 - Evraka everything about HELP! in last six hours.
                      After six hours we got our OWN HELP SYSTEM..
                      (Just for View and it's INCREDIBLY FLEXIBLE!!!)
03rd Apr 94 - 21:12 - Complete with no bugs...
05th Apr 94 - 21:12 - Last optimizations...
28th Apr 94 - 21:12 - BUG: NewLine doubles... (but not here)
29th Apr 94 - 21:12 - Fixed the BUG...
29th Apr 94 - 21:13 - Fixed a bug in NoteView...
29th Oct 94 - 19:34 - Added some explanatory rems to source...
19th Nov 94 - 23:40 - Starting to rejuvenate the code...
21st Nov 94 - 00:14 - Added scrollbar support and optimized the code...
21st Nov 94 - 00:50 - Perfected FlashBack routines...
21st Nov 94 - 01:01 - Perfected everything... Now listening the CD called
                      "Endless Love"... this is a good one...
22nd Nov 94 - 08:35 - Fixed some bugs... Now it's, really perfect!
26th Nov 94 - 13:36 - Reduced the code size...
26th Nov 94 - 18:14 - Optimized... integrated to single file...
27th Nov 94 - 17:19 - Fixed some serious bugs...
 4th Dec 94 - 12:59 - Added forget method to thelpwin..
 8th Dec 94 - 23:34 - Fixed some bugs...
10th Dec 94 - 02:16 - Added any font support... "Falling In Love" , nice
                      tune from "Twin Peaks". ..
10th Dec 94 - 18:18 - Closely-rewritten the paint routines to handle multi
                      font ops...
15th Dec 94 - 19:57 - Fixed a minor bug...
24th Dec 94 - 14:41 - Fixed a bug in flashback....
25th Dec 94 - 23:02 - Fixed some bugs in Topic's paint... (cs=5580)
25th Dec 94 - 23:39 - Last corrections... (cs=5510)
 2nd Jan 95 - 01:17 - Fixed a bug in NewContext... (cs=5503)
 8th Mar 96 - 02:19 - Added hwxxx constants...
10th Mar 96 - 01:23 - Fixed a bug in noteview...
10th Mar 96 - 01:47 - Rewritten noteview's paint and calc routines...
10th Mar 96 - 01:56 - Perfected noteview...
21nd Mar 96 - 00:15 - Fixed a little bug...
30st May 96 - 16:16 - Rewritten topic handlers... image support not
                      implemented yet... added keyboard support...
31nd May 96 - 03:55 - Fixed bugs...
 7th Aug 96 - 14:33 - Fixed a small bug...
}

{$C MOVEABLE DEMANDLOAD DISCARDABLE}
{$O+}

unit XGH;

interface

uses

  XDev,XStr,Graph,Drivers,XGfx,Objects,XScroll,XColl,XHelp,XTypes,Tools,
  GView;

const

  noteGAP  = 7;
  topicGAP = 4;
  lineGAP  = 2;

  topicOffset : integer = 16;

  Col_NoteHeader = cRed;
  Col_NoteText   = cBlack;

  Col_TopicNormal = cBlack;

  Col_HyperTopic  = cBlue;
  Col_HyperNote   = cRed;
  Col_HyperSound  = cRed;
  Col_HyperOther  = cBlack;

  Col_HelpBack    = cLightGray;

  HelpFont        : word = 0;

  DontWrapChar    = #27;

  hwHeader        : string[20] = 'Yardçm';
  hwBack          : string[20] = '~Geri';
  hwClose         : string[20] = '~Kapa';
  hwHelpOnHelp    : string[20] = '~Ne ki?';
  hwContents      : string[20] = '~Ba$liklar';

type

  PContext = ^TContext;     {context link}
  TContext = record
    Ctx    : word;
    Stay   : integer;
  end;

  PHyperLink = ^THyperLink; {hyperlinks}
  THyperLink = record
    ObjType  : byte;
    Id       : word;
    Bounds   : TRect;
  end;

  PNoteView = ^TNoteView;
  TNoteView = object(TView)
    Context : word;
    Width   : word;
    constructor Init(awidth:word;AContext:word);
    function    Execute:word;virtual;
    procedure   Paint;virtual;
  end;

  PTopic = ^TTopic;
  TTopic = object(TView)
    Header   : PString;
    Context  : word;
    TextBuf  : PChar;
    TextSize : word;
    List     : PSizedCollection; {holds context history - linklist's better}
    Hypers   : PSizedCollection; {holds hyperlink locations}
    Stay     : integer;
    Finish   : integer;
    Foc      : word;
    constructor Init(var R:TRect;AContext:word);
    destructor  Done;virtual;
    procedure   Paint;virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   ChangeBounds(var R:TRect);virtual;

    procedure   NewContext(c:word);
    procedure   FlashBack;
    procedure   Update;
    procedure   Note(c:word);
    procedure   UpdateHyperList(ot:byte;id:word;var R:TRect);
    function    FindHyper(T:TPoint):PHyperLink;
    procedure   ActivateHyperLink(P:PHyperLink);
    procedure   Go(where:integer);
    procedure   NotifyOwner;
  end;

  PHelpWindow = ^THelpWindow;
  THelpWindow = object(TDialog)
    Topic     : PTopic;
    Scroller  : PScrollBar;
    constructor Init(ACtx:word);
    function    Valid(acmd:word):boolean;virtual;
    procedure   Update(ACtx:word);
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   UpdateScroller;
    procedure   Forget;
  end;

function NewWord(w:word;s:integer):PContext;

implementation

const

  DefaultLineHeight = 3;

{ THelpWindow - main help window is this }
{ Coding is to love what you do }

constructor THelpWindow.Init;
var
  R:TRect;
  P:PButton;
  s:string;
begin
  R.Assign(0,0,400,250);
  inherited Init(R,hwHeader);
  Options := Options or Ocf_Centered or Ocf_ReSize;
  s := GetBlock(1,1,mnfHorizontal+mnfNoSelect,
    NewButton(hwBack,cmGoBack,
    NewButton(hwClose,cmClose,
    NewButton(hwHelpOnHelp,cmHelp,
    NewButton(hwContents,cmContents,
    NIL)))));
  GetBlockBounds(s,R);
  InsertBlock(s);
  topicOffset := R.B.Y+5;
  GetVisibleBounds(R);
  R.Move(-r.a.x,-r.a.y);
  dec(R.B.X,sbButtonSize+1);
  R.A.Y := topicOffset;
  inc(r.a.x,5);
  New(Topic,Init(R,ACtx));
  Topic^.GrowMode := gmFixedAll;
  Insert(Topic);
  GetVisibleBounds(R);
  R.Move(-r.a.x,-r.a.y);
  R.A.X := R.B.X-sbButtonSize;
  R.A.Y := topicOffset;
  New(Scroller,Init(R));
  Scroller^.GrowMode := gmFixedAll and not gmFixedLoX;
  Insert(Scroller);
  SelectNext(True);
  MinSize.Y := topicOffset + (sbButtonSize*3)+20+Frm_HeaderSize;
  Update(ACtx);
end;

function THelpWindow.Valid;
begin
  Forget;
  Valid := True;
end;

procedure THelpWindow.Forget;
begin
  Topic^.List^.FreeAll;
end;

procedure THelpWindow.HandleEvent;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evBroadcast : case Event.Command of
                    Brc_ScrollBarChanged : if Event.InfoPtr = Scroller then Topic^.Go(Scroller^.Value);
                    Brc_TopicChanged     : if Event.InfoPtr = Topic then UpdateScroller;
                    else exit;
                  end;{case}
    evCommand : case Event.Command of
                  cmContents : Update(1);
                  else exit;
                end; {case}
    else exit;
  end; {Case}
  ClearEvent(Event);
end;

procedure THelpWindow.UpdateScroller;
begin
  with Topic^ do
    Scroller^.Update(Stay,Finish,GetFontHeight(HelpFont),Topic^.Size.Y,False);
end;

procedure THelpWindow.Update;
begin
  Topic^.NewContext(ACtx);
end;

{ TTopic - TopicView }

constructor TTopic.Init;
begin
  inherited Init(R);
  Options    := (Options and not Ocf_Selectable)
                        or Ocf_PreProcess
                        or Ocf_FirstClick;
  Eventmask  := evMouseDown+evCommand+evKeyDown;
  Context    := $FFFF;
  New(List,Init(5,5,SizeOf(TContext)));
{  New(SB,Init(5,5));}
  New(Hypers,Init(5,5,SizeOf(THyperLink)));
  NewContext(AContext);
  GetExtent(R);
  R.Grow(-topicGAP,-topicGAP);
end;

procedure TTopic.ChangeBounds;
begin
  inherited ChangeBounds(R);
  NotifyOwner;
end;

procedure TTopic.NotifyOwner;
begin
  Message(Owner,evBroadcast,Brc_TopicChanged,@Self);
end;

function TTopic.FindHyper;
var
  n:integer;
  P:PHyperLink;
begin
  FindHyper := NIL;
  for n:=0 to Hypers^.Count-1 do begin
    P := Hypers^.At(n);
    if P^.Bounds.Contains(T) then begin
      FindHyper := P;
      exit;
    end;
  end;
end;

procedure TTopic.Go;
var
  totsize: integer;
begin
  if Finish < Size.Y then totsize := 0 else totsize := Finish-Size.Y;
  if where > totsize then where := totsize;
  if where < 0 then where := 0;
  if where = Stay then exit;
  Stay := where;
  PaintView;
end;

procedure TTopic.ActivateHyperLink;
begin
  case P^.ObjType of
    hoNote  : Note(P^.Id);
    hoTopic : NewContext(P^.Id);
{    hoSound : Play(P^.Id);}
  end;
end;

procedure TTopic.HandleEvent;
var
  P:PHyperLink;
  procedure ScrollUp(units:integer);
  begin
    Go(Stay-units);
  end;
  procedure ScrollDown(units:integer);
  begin
    Go(Stay+Units);
  end;
  procedure focushyper(next:boolean);
  begin
    if next then begin
      if Foc < Hypers^.Count-1 then inc(Foc) else exit;
    end else if Foc > 0 then dec(foc) else exit;
    PaintView;
  end;
begin
  inherited HandleEvent(Event);
  case Event.What of
    evMouseDown : begin
                    MakeLocal(Event.Where,Event.Where);
                    P := FindHyper(Event.Where);
                    if P = NIL then exit;
                    ActivateHyperLink(P);
                  end;
    evKeyDown : case Event.KeyCode of
                    kbUp   : ScrollUp(GetFontHeight(HelpFont));
                    kbDown : ScrollDown(GetFontHeight(HelpFont));
                    kbPgUp : ScrollUp(Size.Y);
                    kbPgDn : ScrollDown(Size.Y);
                    kbHome : Go(0);
                    kbEnd  : Go(Finish);
                    kbTab  : FocusHyper(true);
                    kbShiftTab : FocusHyper(false);
                    kbAltF1: FlashBack;
                    kbEnter : if Hypers^.Count > 0 then ActivateHyperLink(Hypers^.at(Foc))
                                 else exit;
                    else exit;
                  end; {case}
    evCommand : case Event.Command of
                  cmGoBack : FlashBack;
                  else exit;
                end; {Case}
    else exit;
  end; {case}
  if Event.What = evKeyDown then NotifyOwner;
  ClearEvent(Event);
end;

destructor TTopic.Done;
  procedure SubKill(P:PCollection);
  begin
    if P <> NIL then Dispose(P,Done);
  end;
begin
  SubKill(List);
  SubKill(Hypers);
  FreeMem(TextBuf,TextSize);
  inherited Done;
end;

procedure TTopic.UpdateHyperList;
var
  P:PHyperLink;
begin
  New(P);
  if P = NIL then exit;
  P^.ObjType := ot;
  P^.Id      := id;
  P^.Bounds  := R;
  Hypers^.Insert(P);
end;

procedure TTopic.Paint;
type
  PWord = ^word;
var
  font        : PFont;
  y,x,incv    : integer;
  curhyp      : word;
  fontHeight  : byte;
  oldFinish   : integer;
  procedure PutIt;
  var
    w:word;
    strsize:word;
    line:string;
    lastword:string;
    temp:string;
    ot:byte;
    id:word;
    R:TRect;
    color:byte;
    wrapit:boolean;
    procedure OutLine(aline:string; nl,draw3d:boolean);
    var
      asize:word;
      subR:TRect;
    begin
      if (aline = '') and nl then begin
        XBar(x,y,Size.X,y+fontHeight+2);
        inc(y,fontHeight+2);
        XBar(0,y,Size.X,y+2);
        inc(y,3);
        x := 0;
        WrapIt := true;
        exit;
      end;
      if nl then asize := (Size.X-x)+1 else asize := GetStringSize(HelpFont,aline);
      if (y+fontHeight >= 0) and (y <= Size.Y) then begin
        subR.Assign(x,y,x+asize+1,y+fontHeight+1);
        XPrintStr(x+1,y+1,asize,HelpFont,aline);
        if Draw3d then ShadowBox(subR,True) else begin
          SetColor(Col_Helpback);
          XBox(subR,false);
        end;
      end;
      if nl then begin
        inc(y,fontHeight+2);
        XBar(0,y,Size.X,y);
        inc(y,1);
        x := 0;
        WrapIt := true;
      end else inc(x,GetStringSize(HelpFont,aline)+2);
    end;
    procedure Flush;
    begin
      OutLine(line+lastword,false,false);
      line := '';
      lastword := '';
    end;
  begin
    SetTextColor(Col_TopicNormal,Col_HelpBack);
    SetColor(Col_HelpBack);
    line := '';
    lastword := '';
    wrapit := true;
    for w:=0 to TextSize-1 do begin
      case TextBuf[w] of
        WildChar : begin
                     inc(w);
                     ot := byte(TextBuf[w]);
                     inc(w);
                     id := word(TextBuf[w]) or (word(TextBuf[w+1]) shl 8);
                     inc(w,2);
                     Move(TextBuf[w],temp[0],byte(TextBuf[w])+1);
                     line := line + lastword;
                     lastword := '';
                     if x+GetStringSize(HelpFont,line+temp) > Size.X-1 then begin
                       OutLine(line,true,false);
                       line := '';
                     end else Flush;
                     r.a.x := x;
                     r.a.y := y;
                     r.b.y := y + fontHeight;
                     case ot of
                       hoTopic,hoNote,hoSound : begin
                         if ot = hoTopic then color := Col_HyperTopic else
                         if ot = hoNote then color := Col_HyperNote else
                         if ot = hoSound then color := Col_HyperSound;
                         if curhyp = Foc then SetTextColor(color+8,Col_HelpBack)
                                         else SetTextColor(color,Col_HelpBack);
                         inc(curhyp);
                         OutLine(temp,false,true);
                         r.b.x := x;
                       end;
                       hoImage : begin
                       end;
                     end; {case}
                     UpdateHyperList(ot,id,R);
                     inc(w,byte(TextBuf[w])); {for increases one too}
                     SetTextColor(Col_TopicNormal,Col_HelpBack);
                   end;
        #32 : begin
                strsize := GetStringSize(HelpFont,line+lastword);
                if (strsize+x > Size.X-1) and WrapIt then begin
                  OutLine(line,true,false);
                  line := lastword+#32;
                  lastword := '';
                end else begin
                  line := line + lastword + #32;
                  lastword := '';
                end;
              end;
        #13,#10 : begin {#32 & #13 needs to be joined togedda}
                    if (TextBuf[w] <> #10) or ((line <> '') or (lastword <> '')) then begin
                      strsize := GetStringSize(HelpFont,line+lastword);
                      if (strsize+x > Size.X-1) and WrapIt then begin
                        OutLine(line,true,false);
                        OutLine(lastword,true,false);
                      end else begin
                        OutLine(line+lastword,true,false);
                      end;
                      line := '';
                      lastword := '';
                    end;
                    if TextBuf[w] = #10 then OutLine('',true,false);
                  end;
        #27 : begin
                if (line<>'') or (lastword<>'') then begin
                  OutLine(line+lastword,true,false);
                  Line := '';
                  LastWord := '';
                end;
                WrapIt := false;
              end;
        else lastword := lastword + TextBuf[w];
      end; {case}
    end;
    OutLine(line+lastword,true,false);
  end;
begin
  PaintBegin;
  fontHeight := GetFontHeight(HelpFont);
  x := 0;
  y := 0;
  curhyp    := 0;
  oldFinish := finish;
  dec(y,Stay);
  Hypers^.FreeAll;
  incv := fontHeight + DefaultLineHeight;
  SetFillStyle(SolidFill,Col_HelpBack);
{  Sync;}
  PutIt;
  XBar(0,y,Size.X,Size.Y);
  Finish  := y+Stay;
  if oldFinish <> Finish then NotifyOwner;
  PaintEnd;
end;

procedure TTopic.Update;
var
  T:TObjHdr;
begin
  EventWait;
  FreeMem(TextBuf,TextSize);
  GetObjectHdr(Context,T);
  if T.ObjType <> $FF then begin
    TextSize := T.Size;
    GetMem(TextBuf,TextSize);
    HIP^.Read(TextBuf^,TextSize);
  end;
  PaintView;
  NotifyOwner;
end;

procedure TTopic.Note;
var
  P:PNoteView;
begin
  New(P,Init(300,c));
  GSystem^.ExecView(P);
  if P <> NIL then Dispose(P,Done);
end;

procedure TTopic.NewContext;
begin
  if c=Context then exit;
  List^.Insert(NewWord(Context,Stay));
  Context := c;
  Stay    := 0;
  Foc     := 0;
  Update;
end;

procedure TTopic.FlashBack;
var
  P:PContext;
  P2:PContext;
begin
  if List^.Count < 2 then exit;
  New(P);
  P2 := List^.At(List^.Count-1);
  Move(P2^,P^,SizeOf(TContext));
  List^.Free(P2);
  Context := P^.Ctx;
  Stay    := P^.Stay;
  Update;
end;

{***************************** TNOTEVIEW ********************************}
constructor TNoteView.Init;
var
  R:TRect;
  buf:pchar;
  bufsize:word;
  s:string;
  lw:FnameStr;
  lines:byte;
  w:word;
begin
  bufsize := ReadNote(AContext,buf,s);
  if bufsize = 0 then fail;
  s := '';
  lw := '';
  lines := 1;
  for w:=0 to bufsize-1 do begin
    case buf[w] of
      #32 : begin
              if GetStringSize(HelpFont,s+lw) > awidth then begin
                s := lw;
                lw := '';
                inc(lines);
              end else begin
                s := s + lw + #32;
                lw := '';
              end;
            end;
      else lw := lw + buf[w];
    end; {Case}
  end;
  if s <> '' then inc(lines);
  inc(lines,2);
  R.Assign(0,0,
    awidth+noteGAP*2,
    (lines*GetFontHeight(HelpFont))+noteGAP*2);
  inherited Init(R);
  Options   := Ocf_Centered or Ocf_ZoomEffect;
  EventMask := 0;
  Context   := AContext;
  Width     := AWidth;
end;

function TNoteView.Execute:word;
var
  Event:TEvent;
begin
  repeat
    GetEvent(Event);
  until (Event.What = evMouseDown) or (Event.What = evKeyDown);
  Execute := cmOk;
end;

procedure TNoteView.Paint;
var
  s      : string;
  lastword : FnameStr;
  R      : TRect;
  Buf    : PChar;
  n,lastpos,bufsize,ls : word;
  x,y    : integer;
  c      : char;
  lw     : byte;
  inword : boolean;
  fontHeight:integer;
  procedure PutIt;
  begin
    XPrintStr(x,y,r.b.y,HelpFont,s); {optimized}
    inc(y,fontHeight);
  end;
begin
  PaintBegin;
    fontHeight := GetFontHeight(HelpFont);
    GetExtent(R);
    SetColor(cBlack);
    SetFillStyle(SolidFill,Col_Back);
    ShadowBox(R,True);
    R.Grow(-1,-1);
    XBox(R,True);
    R.Grow(-noteGAP+4,-noteGAP+4);
    ShadowBox(R,False);
    R.Grow(-2,-2);
    x := r.a.x;
    y := r.a.y;
    r.b.y := r.b.x-r.a.x;
    bufsize := ReadNote(Context,Buf,s);
    SetTextColor(Col_NoteHeader,Col_Back);
    if s <> '' then PutIt else inc(y,fontHeight);
    SetTextColor(Col_NoteText,Col_Back);
    inc(y,fontHeight);
    if (Buf <> NIL) and (bufsize > 0) then begin
      {variable initialization}
      s       := '';
      lastword := '';
      lastpos := 0;
      ls      := 0;
      lw      := 0;
      {main loop}
      for n:=0 to bufsize-1 do begin
        c := Buf[n];
        case c of
          #32 : begin
                  if GetStringSize(HelpFont,s+lastword) > width then begin
                    putit;
                    s := lastword+#32;
                    lastword := '';
                  end else begin
                    s := s + lastword + #32;
                    lastword := '';
                  end;
                end;
          else lastword := lastword + c;
        end; {case}
      end; {for}
      s := s + lastword;
      if s <> '' then putit;
      FreeMem(Buf,BufSize);
    end;
  PaintEnd;
end;

{***************************** NEWWORD ********************************}
function NewWord(w:word;s:integer):PContext;
var
  P:PContext;
begin
  GetMem(P,sizeof(TContext));
  NewWord := P;
  if P = NIL then exit;
  P^.Ctx := w;
  P^.Stay:= s;
end;

end.
