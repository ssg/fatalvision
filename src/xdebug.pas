{
Name    : X/Debug 1.00b
Purpose : Extended debug output console
Coder   : SSG
Date    : 2rd Jun 96
Time    : 17:42

updates:
--------
 2rd Jun 96 - 18:06 - finished....
 3th Jun 96 - 00:57 - updated...
25th Jun 96 - 01:48 - moved consoleview to tools...
13th Aug 96 - 00:16 - added setconsole...
}

unit XDebug;

interface

uses Tools,XColl,GView,XTypes,Objects;

const

  DebugActive : boolean = false;
  Col_Debugforeground = cWhite;
  Col_Debugbackground = cBlack;

type

  PDebugWindow = ^TDebugWindow;
  TDebugWindow = object(TWindow)
    Console    : PConsoleView;
    constructor Init(aheader:fnameStr; afont:word);
  end;

procedure InitDebug(aheader:FnameStr; afont:word; redirecttofile:boolean);
procedure DoneDebug;
procedure SetConsole(enable:boolean);
procedure ToggleConsole;
procedure Debug(msg:FnameStr);
procedure DebugFile(msg:FnameStr);

implementation

uses XIO,XStream,Graph,XGfx;

const

  DebugWindow : PDebugWindow = NIL;
  tofile      : boolean = false;
  outFile     : string[12] = 'debug';

procedure SetConsole;
begin
  DebugWindow^.SetState(Scf_Visible,enable);
end;

procedure ToggleConsole;
begin
  SetConsole(not DebugWindow^.GetState(Scf_Visible));
end;

procedure InitDebug;
begin
  New(DebugWindow,Init(aheader,afont));
  tofile := redirecttofile;
  if tofile then XDeleteFile(outFile);
  GSystem^.Insert(DebugWindow);
  DebugActive := true;
end;

procedure DebugFile;
var
  T:TDosStream;
begin
  if not tofile then exit;
  T.Init(outFile,stOpen);
  if T.Status <> stOK then begin
    T.Done;
    T.Init(outFile,stCreate);
  end;
  T.Seek(T.GetSize);
  SWriteln(T,msg);
  T.Done;
end;

procedure Debug;
begin
  if debugActive then begin
    if DebugWindow^.GetState(Scf_Visible) then DebugWindow^.Console^.Out(msg);
    if tofile then DebugFile(msg);
  end;
end;

procedure DoneDebug;
begin
  if DebugActive then begin
    Dispose(DebugWindow,Done);
    DebugWindow := NIL;
    DebugActive := false;
  end;
end;

constructor TDebugWindow.Init;
var
  R:TRect;
begin
  R.Assign(0,ScreenY-200,320,ScreenY-20);
  inherited Init(R,aheader);
  Options := (Options and not (Ocf_Selectable+Ocf_ReSize+Ocf_Close)) or Ocf_AlwaysOnTop;
  GetVisibleBounds(R);
  R.Move(-r.a.x,-r.a.y);
  New(Console,Init(R,afont,(r.b.y-r.a.y) div GetFontHeight(afont),Col_DebugForeground,Col_DebugBackground));
  Insert(Console);
end;

end.