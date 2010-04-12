{
Name    : X/CDPlayer 1.00c
Purpose : CD player object
Coder   : SSG
Date    : 10th Aug 96
Time    : 12:38
}

unit XCDPlay;

interface

uses XCD,Drivers,Objects,GView,Tools;

type

  TCDPlayerButton = record
    id,cmd : word;
  end;

  TCDPlayerAction = (cdaRewind,
                     cdaStop,
                     cdaPlay,
                     cdaPause,
                     cdaForward,
                     cdaEject);

  TCDPlayerButtonSet = array[cdaRewind..cdaEject] of TCDPlayerButton;

type

  PCDPlayer = ^TCDPlayer;
  TCDPlayer = object(TObject)
    Drive   : word;
    constructor Init(adrive:word);
    procedure   SeekTrack(atrack:byte);
    procedure   SeekNext;
    procedure   SeekPrev;
    procedure   Stop;
    procedure   Resume;
    procedure   Play;
    procedure   Pause;
    procedure   Eject;
    function    DriveReady:boolean;
    function    GetTrack:byte;
    function    GetPos:longint;
    function    GetAudioInfo(var info:TAudioInfo):boolean;
    function    GetPlaylen(apos:longint):longint;
    function    IsPaused:boolean;
  end;

  PSimpleCDPlayer = ^TSimpleCDPlayer;
  TSimpleCDPlayer = object(TView)
    butXSize    : integer;
    pressed     : integer;
    CDPlayer    : PCDPlayer;
    constructor Init(x,y:integer; adrive:word);
    destructor  Done;virtual;
    procedure   PaintButton(index:integer);
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   GetButtonBounds(index:integer; var Bounds:TRect);
    procedure   Paint;virtual;
  end;

const

  CDButtons : TCDPlayerButtonSet = (
   (id:00; cmd:00), {rewind}
   (id:01; cmd:01), {stop}
   (id:02; cmd:02), {play}
   (id:03; cmd:03), {pause}
   (id:04; cmd:04),  {forward}
   (id:05; cmd:05)); {eject}

implementation

uses

  XDev,XStr,XDebug,Graph,XGfx,XTypes;

function t2s(l:longint):string;
var
  time:TCDTime;
begin
  XHSG2Red(l,time);
  with time do t2s := z2s(min,2)+':'+z2s(sec,2)+'.'+z2s(frame,2);
end;

constructor TCDPlayer.Init(adrive:word);
begin
  inherited Init;
  Drive := adrive;
end;

function TCDPlayer.DriveReady;
var
  info:TAudioInfo;
begin
  DriveReady := GetAudioInfo(info);
end;

function TCDPlayer.GetTrack:byte;
var
  q:TQChannelInfo;
begin
  XCDQChannelInfo(Drive,q);
  GetTrack := q.Track;
end;

function TCDPlayer.GetPos:longint;
begin
  GetPos := XCDHeadLocation(Drive);
end;

function TCDPlayer.GetAudioInfo(var info:TAudioInfo):boolean;
begin
  GetAudioInfo := XCDAudioInfo(Drive,info);
end;

procedure TCDPlayer.SeekTrack;
begin
  XCDSeek(Drive,camHSG,XCDTrackStart(Drive,atrack));
end;

function TCDPlayer.GetPlayLen(apos:longint):longint;
begin
  getplaylen := (XCDVolumeSize(Drive)-apos)-150;
end;

function TCDPlayer.IsPaused:boolean;
var
  status:TAudioStatus;
begin
  XCDAudioStatus(Drive,status);
  IsPaused := status.Paused;
end;

procedure TCDPlayer.Stop;
begin
  XCDStop(Drive);
end;

procedure TCDPlayer.Resume;
begin
  XCDResume(Drive);
end;

procedure TCDPlayer.Play;
var
  tracklen:longint;
begin
  if DriveReady then begin
    if GetTrack = 0 then SeekTrack(1);
    tracklen := GetPlaylen(GetPos);
    Debug('CD: playing track '+l2s(GetTrack)+' from '+t2s(GetPos)+' - len: '+t2s(tracklen));
    XCD.XCDPlay(Drive,camHSG,GetPos,tracklen);
  end;
end;

procedure TCDPlayer.SeekPrev;
var
  paused:boolean;
  info:TAudioInfo;
  seekto:byte;
begin
  if GetAudioInfo(info) then begin
    if GetTrack > info.Lowest then seekto := GetTrack-1
                              else seekto := info.Highest;
    paused := IsPaused;
    SeekTrack(seekto);
    if not paused then Play;
  end;
end;

procedure TCDPlayer.SeekNext;
var
  paused:boolean;
  info:TAudioInfo;
  seekto:byte;
begin
  if GetAudioInfo(info) then begin
    seekto := gettrack + 1;
    if seekto > info.Highest then seekto := 1;
    paused := IsPaused;
    SeekTrack(seekto);
    if not paused then Play;
  end;
end;

procedure TCDPlayer.Pause;
begin
  if IsPaused then Resume else begin
    Stop;
    Debug('CD: paused audio at '+t2s(GetPos));
  end;
end;

procedure TCDPlayer.Eject;
begin
  if XCDStatus(Drive) and cdsDoorOpen > 0 then begin
    Debug('CD: close tray');
    XCDCloseTray(Drive);
  end else begin
    Debug('CD: eject');
    XCDEject(Drive);
  end;
end;

{- TSimpleCDPlayer -}
constructor TSimpleCDPlayer.Init(x,y:integer; adrive:word);
var
  R:TRect;
  P:PVIFMap;
  bxsize:integer;
begin
  P := GetImagePtr(CDButtons[cdaRewind].id);
  bxsize := P^.XSize+2;
  R.Assign(0,0,(bxsize*6)-1,P^.YSize+2);
  R.Move(x,y);
  inherited Init(R);
  pressed := -1;
  Options := (Options or Ocf_Move or Ocf_FullDrag or Ocf_PreProcess or Ocf_AlwaysOnTop) and not Ocf_Selectable;
  EventMask := evMouseDown or evKeyDown;
  butXSize := bxsize;
  New(CDPlayer,Init(adrive));
end;

destructor TSimpleCDPlayer.Done;
begin
  if CDPlayer <> NIL then Dispose(CDPlayer,Done);
  inherited Done;
end;

procedure TSimpleCDPlayer.HandleEvent(var Event:TEvent);

  function GetButtonIndex(where:TPoint):integer;
  var
    n:integer;
    R:TRect;
  begin
    GetButtonIndex := -1;
    if not MouseInView(where) then exit;
    MakeLocal(where,where);
    for n:=0 to 5 do begin
      GetButtonBounds(n,R);
      if R.Contains(where) then begin
        GetButtonIndex := n;
        exit;
      end;
    end;
  end;

  procedure HandleMouseEvents;
  var
    index:integer;
    cmd:word;
  begin
    repeat
      PointingDevice^.GetEvent(Event);
      index := GetButtonIndex(Event.Where);
      if pressed <> index then begin
        pressed := index;
        Paint;
      end;
    until Event.Buttons = 0;
    if pressed <> -1 then begin
      cmd := CDButtons[TCDPlayerAction(pressed)].Cmd;
      pressed := -1;
      Paint;
      Message(@Self,evCommand,Cmd,NIL);
    end;
  end;

  function AdoptCommand:boolean;
  var
    n:TCDPlayerAction;
  begin
    AdoptCommand := false;
    for n:=cdaRewind to cdaEject do if CDButtons[n].Cmd = Event.Command then begin
      AdoptCommand := true;
      with CDPlayer^ do case n of
        cdaRewind  : SeekPrev;
        cdaStop    : Stop;
        cdaPlay    : Play;
        cdaPause   : Pause;
        cdaForward : SeekNext;
        cdaEject   : Eject;
      end;
      exit;
    end;
  end;

begin
  case Event.What of
    evMouseDown : if Event.Buttons = mbLeft then HandleMouseEvents
                                            else Drag(Event,dmDragMove+dmLimitAll);
    evCommand : if not AdoptCommand then exit;
    else exit;
  end; {Case}
  ClearEvent(Event);
end;

procedure TSimpleCDPlayer.GetButtonBounds(index:integer; var Bounds:TRect);
begin
  Bounds.Assign(0,0,butXSize,Size.Y);
  Bounds.Move(index*butXSize,0);
end;

procedure TSimpleCDPlayer.PaintButton(index:integer);
var
  R:TRect;
begin
  with CDButtons[TCDPlayerAction(index)] do begin
    GetButtonBounds(index,R);
    XPutImage(r.a.x+1,r.a.y+1,id);
    dec(r.b.x);
    SetColor(cLightGray);
    XLine(r.a.x,size.y-1,r.b.x-1,size.y-1);
    ShadowBox(R,pressed <> index);
  end;
end;

procedure TSimpleCDPlayer.Paint;
var
  n:integer;
begin
  PaintBegin;
    for n:=0 to 5 do PaintButton(n);
  PaintEnd;
end;

{procedure TSimpleCDPlayer.Backprocess;
begin
  if XCDChanged(cdDrive) then RefreshCDInfo;
end;}

end.