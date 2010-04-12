{
Name            : XDos 1.2f
Purpose         : Simple dosshell..
Coder           : SSG
Date            : 26th Sep 93

updates:
--------
29th Jun 97 - 00:44 - revised source. and this thing is useless man.
                      copy doesn't work.
}

{$I-}

unit XDos;

interface

uses

Dos,
Tools,
XCrt,
XTypes,
Objects,
Drivers,
XStr,
GView;

type

  TDosPhase = (Off,Input,Output);

  TCmdTable = record
    Cmd     : String[8];
    Task    : Word;
  end;

  PDosShell = ^TDosShell;
  TDosShell = object(TCRT)
    DosPhase    : TDosPhase;
    Task        : Word;
    CmdLine     : String[80];
    Counter     : Longint;
    Workfile    : Text;
    Workspace   : Pointer;
    DirInfo     : SearchRec;
    LastCode    : integer;
    SelfDir     : DirStr;
    SelfDrive   : Byte;
    OrigDir     : DirStr;
    OrigDrive   : Byte;

    constructor Init(x,y:integer;AYSize,FC,BC:Byte);
    procedure   ExecuteDosShell;
    procedure   CloseDosShell;
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   BackProcess;virtual;
    function    Valid(acmd:word):boolean;virtual;

    function    SearchPath:string;
    function    GetCommand(st:string):string;
    procedure   UnderstandCommandLine;
    procedure   NewPrompt;
    function    GetParams(s:string):string;
    function    IsParam(s:string):boolean;

    procedure   AssignTask;
    procedure   Cls;
    procedure   Dir;
    procedure   ChangeDir;
    procedure   MakeDir;
    procedure   RemoveDir;
    procedure   Info;
    procedure   Copy;
    procedure   Help;
    procedure   FileType;
    procedure   Ver;
  end;

  PDosShellWindow = ^TDosShellWindow;
  TDosShellWindow = object(TWindow)
    DosShell      : PDosShell;
    constructor Init(x,y:integer);
  end;

const
  Version        = '1.2c';

  tkIdle         = 0;
  tkClearScreen  = 1;
  tkDirectory    = 2;
  tkChangeDir    = 3;
  tkMakeDir      = 4;
  tkRemoveDir    = 5;
  tkInfo         = 6;
  tkCopy         = 7;
  tkHelp         = 8;
  tkType         = 9;
  tkRestart      = 10;
  tkVer          = 11;

  WorkSpaceLimit = 64000;

  MaxDOSCommands = 11;
  DOSCommandTable : array[1..MaxDOSCommands] of TCmdTable =
    ((Cmd:'CLS';Task:tkClearScreen),
     (Cmd:'DIR';Task:tkDirectory),
     (Cmd:'CD';Task:tkChangeDir),
     (Cmd:'MD';Task:tkMakeDir),
     (Cmd:'RD';Task:tkRemoveDir),
     (Cmd:'INFO';Task:tkInfo),
     (Cmd:'COPY';Task:tkCopy),
     (Cmd:'HELP';Task:tkHelp),
     (Cmd:'TYPE';Task:tkType),
     (Cmd:'VER';Task:tkVer),
     (Cmd:'RESTART';Task:tkRestart));

implementation

{************************* SETDEFAULTDRIVE ****************************}
procedure SetDefaultDrive(Drive:Byte);assembler;
asm
  mov  ah,$0E
  mov  al,Drive
  mov  dl,al
  int  21h
end;

{************************ GETDEFAULTDRIVE ***************************}
function GetDefaultDrive:byte;assembler;
asm
  mov ax,1900h
  int 21h
end;

{****************************  TDOSSHELLWINDOW ************************}
constructor TDosShellWindow.Init(x,y:integer);
var
  R:TRect;
begin
  R.A.X := x;
  R.A.Y := y;
  R.B.X := x+640;
  R.B.Y := y + 227;
  TWindow.Init(R,'DOS Prompt');
  New(DosShell,Init(0,0,25,cWhite,cBlue));
  DosShell^.ExecuteDosShell;
  Insert(DosShell);
end;

{******************************** TDOSSHELL *****************************}
constructor TDosShell.Init(x,y:integer;AYSize,FC,BC:Byte);
begin
  TCRT.Init(x,y,80,AYSize,fc,bc);
  CmdLine   := '';
  EventMask := evKeyDown;
  Options   := Ocf_PostProcess;
  DosPhase  := Off;
  Task      := tkIdle;
  Counter   := 0;
  GetDir(0,OrigDir);
  OrigDrive := GetDefaultDrive;
  SelfDrive := OrigDrive;
  SelfDir   := OrigDir;
end;

function  TDosShell.Valid(acmd:word):boolean;
begin
  SetDefaultDrive(OrigDrive);
  ChDir(OrigDir);
  Valid := True;
end;

procedure TDosShell.NewPrompt;
begin
  WriteLn('');
  Write(SelfDir+'>');
  CmdLine := '';
  DosPhase := Input;
end;

procedure TDosShell.CloseDosShell;
begin
  DosPhase := Off;
  writeln('End of DOS Session');
  Message(Owner,evCommand,cmClose,Owner);
end;

procedure TDosShell.Cls;
begin
  ClrScr;
  NewPrompt;
end;

function TDosShell.GetCommand(st:string):string;
var
  i:byte;
  S:string;
begin
  i := Pos(' ',st);
  if i>0 then s := System.Copy(st,1,i-1)
     else s := st;
  GetCommand := Upper(s);
end;

function TDosShell.SearchPath:string;
var
  s:string;
begin
  S := FSearch(GetCommand(CmdLine)+'.COM',GetEnv('PATH'));
  if S = '' then S := FSearch(GetCommand(CmdLine)+'.EXE',GetEnv('PATH'));
  SearchPath := S;
end;

procedure TDosShell.AssignTask;
var
  s:string;
  n:integer;
begin
  Task := tkIdle;
  s := Upper(GetCommand(CmdLine));
  for n:=1 to MaxDOSCommands do if s=DOSCommandTable[n].Cmd then
      Task := DOSCommandTable[n].Task;
  Counter := 0;
end;

procedure TDosShell.UnderstandCommandLine;
var
  s:string;
begin
  if CmdLine = '' then begin
     NewPrompt;
     exit;
  end;
  s := Upper(System.Copy(CmdLine,1,3));
  if (s = 'CD.') or (s = 'CD\') then System.Insert(' ',CmdLine,3);
  if Length(CmdLine) = 2 then
     if CmdLine[Length(CmdLine)] = ':' then begin
        SelfDrive := Byte(upcase(CmdLine[1]))-65;
        SetDefaultDrive(SelfDrive);
        GetDir(0,SelfDir);
        NewPrompt;
        exit;
     end;
  ChDir(SelfDir);
  SetDefaultDrive(SelfDrive);
  if GetCommand(CmdLine)= 'EXIT' then if Valid(0) then begin
     CloseDosShell;
     exit;
  end;
  AssignTask;
  if (Task = tkIdle) then begin
     if SearchPath = '' then
        WriteLn('Bad command or file name') else
        WriteLn('Not enough memory');
     NewPrompt;
     exit;
  end;
  DosPhase := Output;
end;

procedure TDosShell.ExecuteDosShell;
begin
  ClrScr;
  WriteLn('MS-DOS Virtual Shell Version 1.0');
  writeln('Type EXIT to return main program');
  NewPrompt;
end;

procedure TDosShell.HandleEvent(var Event:TEvent);
begin
  if (Event.What <> evKeyDown) then exit;
  if Event.CharCode = ^C then begin
     writeln('^C');
     NewPrompt;
  end;
  if DosPhase <> Input then exit;
  if Event.KeyCode = kbLeft then Event.CharCode := #8;
  case Event.CharCode of
     #13: begin
            WriteLn('');
            UnderstandCommandLine;
          end;
     #8: if Length(CmdLine) > 0 then begin
            Dec(Byte(CmdLine[0]));
            BackSpaceCursor;
            Write(' ');
            BackSpaceCursor;
         end;
     #27: begin
           WriteLn('\');
           CmdLine := '';
          end;
     #20..#255: if Length(CmdLine) < 167 then begin
                  Write(Event.CharCode);
                  CmdLine := CmdLine + Event.CharCode;
                end;
    else exit;
  end;
  ClearEvent(Event);
end;

function TDosShell.GetParams(s:string):string;
var
  i:byte;
begin
  GetParams := '';
  i := Pos(' ',s);
  if i = 0 then exit;
  GetParams := System.Copy(s,i+1,Length(CmdLine));
end;

function TDosShell.IsParam(s:string):boolean;
var
  p:string;
begin
  p := Upper(GetParams(CmdLine));
  FastUpper(s);
  IsParam := Pos(s,p) > 0;
end;

procedure TDosShell.Dir;
var
  s,s1:string;
begin
  GetDir(0,s);
  if Counter < 5 then case Counter of
     1,4 : WriteLn('');
     2 : WriteLn(' Volume on drive '+s[1]+' is SSG');
     3 : begin
           Writeln(' Directory of '+s);
           s := GetParams(CmdLine);
           if s = '' then s:='*.*' else if Pos(' ',s)>0 then s := GetParams(s);
           FindFirst(s,ReadOnly+Hidden+Archive+SysFile+Directory,DirInfo);
           LastCode := DosError;
        end;
  end {case}
     else begin
       if LastCode <> 0 then begin
         writeln('');
         writeln(l2s(DiskFree(0))+' bytes free');
         NewPrompt;
       end else begin
         s := Fix(DirInfo.Name,13);
         if DirInfo.Attr and Directory > 0 then
            s1 := '<DIR>' else s1 := l2s(DirInfo.Size);
         s := s + RFix(s1,10);
         writeln(s);
         FindNext(DirInfo);
         LastCode := DosError;
       end;
  end;
end;

procedure TDosShell.ChangeDir;
begin
  ChDir(GetParams(CmdLine));
  if IOResult <> 0 then writeln('Cannot change directory');
  GetDir(0,SelfDir);
  NewPrompt;
end;

procedure TDosShell.MakeDir;
begin
  MkDir(GetParams(CmdLine));
  if IOResult <> 0 then writeln('Cannot make directory');
  NewPrompt;
end;

procedure TDosShell.RemoveDir;
begin
  RmDir(GetParams(CmdLine));
  if IOResult <> 0 then writeln('Cannot remove directory');
  NewPrompt;
end;

procedure TDosShell.Info;
begin
  if counter < 5 then
     case counter of
       1 : Writeln('Programmed by SSG - 26th Sep 93 - 03:45');
       2 : writeln('We did the Windows can''t in 400K free memory');
       3 : writeln('By the way, this is the first version!');
       4 : writeln('Anything can be expected from GENSYS');
     end {case}
  else NewPrompt;
end;

procedure TDosShell.FileType;
var
  s:string;
begin
  if counter = 1 then begin
    Assign(Workfile,GetParams(CmdLine));
    Reset(Workfile);
    if IOResult <> 0 then begin
      writeln('Cannot open file');
      NewPrompt;
    end;
  end;
  readln(WorkFile,s);
  writeln(s);
  if Eof(WorkFile) then begin
    Close(WorkFile);
    NewPrompt;
  end;
end;

procedure TDosShell.Copy;
{var
  P:PCopier;}
begin
{  New(P,Init(0,0,'Copy Process',GetCommand(GetParams(CmdLine)),GetParams(GetParams(CmdLine))));
  if P = NIL then begin
     writeln('Invalid parameters');
     NewPrompt;
     exit;
  end;
  if GSystem = NIL then begin
     writeln('System request failure');
     Dispose(P,Done);
     NewPrompt;
     exit;
  end;
  GSystem^.Insert(P);
  NewPrompt;}
end;

procedure TDosShell.Ver;
begin
  case counter of
    1 : writeln('');
    2 : writeln('MS-DOS Virtual Shell Version '+Version);
    else NewPrompt;
  end; {case}
end;

procedure TDosShell.Help;
begin
  case counter of
    1 : writeln('Available commands:');
    2 : writeln('-------------------');
  end;
  if counter>2 then writeln(DOSCommandTable[Counter-2].Cmd);
  if MaxDosCommands = counter-2 then NewPrompt;
end;

procedure TDosShell.BackProcess;
begin
  if (Task = tkIdle) or (DosPhase <> Output) then exit;
  inc(Counter);
  ChDir(SelfDir);
  SetDefaultDrive(SelfDrive);
  case Task of
    tkClearScreen : Cls;
    tkDirectory   : Dir;
    tkChangeDir   : ChangeDir;
    tkMakeDir     : MakeDir;
    tkRemoveDir   : RemoveDir;
    tkInfo        : Info;
    tkCopy        : Copy;
    tkHelp        : Help;
    tkType        : FileType;
    tkRestart     : ExecuteDOSShell;
    tkVer         : Ver;
  end;
  ChDir(OrigDir);
  SetDefaultDrive(OrigDrive);
end;

end.
