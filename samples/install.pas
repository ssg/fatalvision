{
Name            : Install 2.08c
Purpose         : Fully flexible install program
Coder           : SSG
Date            : 04th Jan 94
Time            : 04:15 am

Update Info:
------------
30th May 94 - 15:50 - Added additional checks and config.sys recognitions...
30th May 94 - 16:58 - Complete...
19th Jul 94 - 07:20 - Revised..
10th Aug 94 - 11:23 - Revised..
23rd Aug 94 - 21:57 - Fixed some bugs...
24th Sep 94 - 21:42 - Added Huffman decompression routines...
24th Sep 94 - 22:20 - Fixed some bugs...
 3rd Dec 94 - 21:13 - Recompiled...
10th Dec 94 - 18:05 - Adding help support
 6th Mar 95 - 21:47 - Optimized code...
18th Apr 95 - 03:18 - Removed WinWarn & EmmWarn.. Put MinXMS & MinEMS...
20th Dec 95 - 03:57 - Changed compression method to LZSS..
27th Aug 97 - 23:02 - adapted source to the new GUI...
}

uses

  Debris,LZSS,Drivers,XDiag,Disk,Dos,Objects,GView,XGfx,Tools,XStr,XSys,
  XDev,XInput,XStream,XBuf,XTypes,XHelp,XGH,XIO;

{$I-,S-,R-}

const

  iVersion     = '2.08c';
  INI          = 'INSTALL.INI';
  DefaultBatch = 'RUN.BAT';
  cmInstall    = cmSpecial;

type

  PIniCollection = ^TIniCollection;
  TIniCollection = object(TCollection)
    procedure FreeItem(Item:Pointer);virtual;
  end;

procedure TIniCollection.FreeItem(Item:Pointer);
begin
  if Item <> NIL then DisposeStr(Item);
end;

var
  PIni:PIniCollection;

type

  TInstaller = object(TSystem)
    Application : String[80];
    Version     : String[10];
    Directory   : FNameStr;
    BatchName   : FNameStr;
    IniName     : FNameStr;
    Cur         : Integer;
    MinEMS      : word;
    MinXMS      : word;
    MinCPU      : byte;
    Protection  : boolean;
    MinFiles    : byte;
    MinBuffers  : byte;
    constructor Init;
    procedure   GoClass(Class:String);
    procedure   GetNextParam(var Cmd,Param:String);
    function    Upper(s:string):string;
    procedure   InitVariables;virtual;
    procedure   HandleClass(Class:String);virtual;
    procedure   HandleParams(var class,cmd,Param:String);virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   AddConfig(cnf:string;minval:byte);
    procedure   Install;
    procedure   PrimaryHandle(var Event:TEvent);virtual;
  end;

var
  lI,lO:TDosStream;
  lR:TRect;
  lP:PWindow;
  lGraph:PBarGraph;
  lText:PDynamicLabel;

function SRead:word;far;
var
  bufsize:word;
begin
  lGraph^.Update(lI.GetSize,lI.GetPos);
  bufsize := LZSSBufSize;
  if lI.GetSize-lI.GetPos < bufsize then bufsize := lI.GetSize-lI.GetPos;
  SRead := bufsize;
  lI.Read(lzi^.LZSSInbuf,bufsize);
  if lI.Status <> stOK then lText^.NewText('Read error!');
end;

procedure SWrite;far;
begin
  lO.Write(lzi^.LZSSoutbuf,lzi^.LZSSoutbufptr);
  if lO.Status <> stOK then lText^.NewText('Write error!');
end;

procedure UnCompress(inf,outf:FNameStr);
begin
  lR.Assign(0,0,0,0);
  New(lP,Init(lR,'Decompression'));
  lR.Assign(0,0,300,13);
  lR.Move(5,5);
  New(lText,Init(lR.a.x,lR.a.y,lR.b.x-lR.a.x,XGetFileName(inf)+' -> '+XGetFileName(outf),cBlack,Col_back,ViewFont));
  lP^.Insert(lText);
  lR.A.Y := lR.B.Y+5;
  lR.B.Y := lR.A.Y+48;
  New(lGraph,Init(lR,0,0));
  lP^.Insert(lGraph);
  lP^.Options := lP^.Options or Ocf_Centered;
  lP^.FitBounds;
  GSystem^.Insert(lP);
  lI.Init(inf,stOpenRead);
  lO.Init(outf,stCreate);
  if (lI.Status <> stOK) or (lO.Status <> stOK) then MessageBox(^C'Uncompress: open error',0,mfError)
                                                else begin
    LZSSReadProc  := SRead;
    LZSSWriteProc := SWrite;
    LZSSUnCompress;
  end;
  if lP <> NIL then Dispose(lP,Done);
  lI.Done;
  lO.Done;
end;

procedure TInstaller.PrimaryHandle;

  procedure Help;
  var
    P:PHelpWindow;
  begin
    ClearEvent(Event);
    New(P,Init(GetHelpContext));
    ExecView(P);
    Dispose(P,Done);
  end;
begin
  inherited PrimaryHandle(Event);
  case Event.What of
    evKeyDown : if Event.KeyCode = kbF1 then Help;
    evCommand : if Event.Command = cmHelp then Help;
  end; {case}
end;

constructor TInstaller.Init;
var
  R:TRect;
  P:PMenuWindow;
  T:TBackDC;
begin
  inherited Init;
  T.Style := bsSolid;
  T.SColor := cBlack;
  Background^.AssignDC(T);
  R.Assign(0,0,ScreenX,16);
  Insert(New(PStaticText,Init(R,'Install v'+iVersion,ViewFont,cBlack,Col_back)));
  MinCPU := 0;
  InitVariables;
  R.Assign(0,0,300,90);
  New(P,Init(0,0,'Se‡enekler',GetBlock(5,5,mnfVertical,
    NewButton('~Install iŸlemini baŸlat',cmInstall,
    NewButton('     ~Programdan ‡k    ',cmQuit,
    NIL)))));
  P^.Options := (P^.Options or Ocf_Centered) and not (Ocf_ReSize+Ocf_Close);
  Insert(P);
end;

procedure TInstaller.AddConfig(cnf:string;minval:byte);
var
  I,O:TDosStream;
  s:string[80];
  changed:boolean;
  function GetParam:byte;near;
  var
    i:byte;
    code:integer;
  begin
    GetParam := 0;
    i := Pos('=',s);
    if i > 0 then GetParam := s2l(copy(s,i+1,255));
  end;
begin
  changed := false;
  I.Init('C:\CONFIG.SYS',stOpenRead);
  O.Init('C:\INSTALL.TMP',stCreate);
  while I.GetPos < I.GetSize do begin
    SReadLn(I,s);
    if I.Status = stOK then begin
      FastUpper(s);
      if (Pos('REM',s) = 0) and (Pos(cnf,s) > 0) and (GetParam < minval) then begin
        s := cnf + ' = ' + l2s(minval);
        changed := true;
      end;
      O.Write(s[1],length(s));
    end;
  end;
  I.Done;
  O.Done;
  if changed then XRenameAnyway('C:\INSTALL.TMP','C:\CONFIG.SYS')
             else XDeleteFile('C:\INSTALL.TMP');
end;

procedure TInstaller.Install;
  function Ask(s:string):boolean;
  begin
    Ask := MessageBox(s,0,mfYesNo+mfWarning) = cmYes;
  end;
  procedure CheckConfig;
  begin
  end;
  function AskDirectory:boolean;
  var
    P:PDialog;
    code:word;
    R:TRect;
    procedure AdjustDir;
    begin
      Directory := FExpand(Directory);
      if Directory[Length(Directory)] = '\' then
        Dec(Byte(Directory[0]));
      FastUpper(Directory);
    end;
  begin
    AskDirectory := false;
    R.Assign(0,0,0,0);
    New(P,Init(R,'Install '+iVersion));
    P^.Options := P^.Options or Ocf_Centered;
    R.Assign(0,0,310,90);
    R.Move(5,5);
    P^.Insert(New(PStaticText,Init(R,
      Application+' '+Version+' Programn hard diskte hangi dizine kurulaca§n yaznz. '+
      'E§er normal de§erleri kabul etmek istiyorsanz direk ENTER tuŸuna basnz.',ViewFont,cBlack,Col_back)));
    P^.Insert(New(PInputStr,Init(5,r.b.y+5,25,'Dizin ad : ',25,Idc_UpperStr+Idc_PreDel)));
    P^.InsertBlock(GetBlock(5,r.b.y+18,mnfHorizontal,
      NewButton(Msg[Msg_OK],cmOK,
      NewButton(Msg[Msg_Cancel],cmClose,
      NIL))));
    P^.FitBounds;
    P^.SelectNext(True);
    AdjustDir;
    P^.SetData(Directory);
    code := GSystem^.ExecView(P);
    P^.GetData(Directory);
    Dispose(P,Done);
    if code <> cmOK then exit;
    AdjustDir;
    AskDirectory := true;
  end;
  function Avail:boolean;
  var
    cmd,param:string[40];
    size:longint;
  begin
    EventWait;
    StartJob('Dosyalar inceleniyor...');
    Avail := false;
    GoClass('files');
    size := 0;
    if cur < PIni^.Count-1 then
    while cur <> -1 do begin
      GetNextParam(cmd,param);
      inc(size,XGetFileSize(param));
    end;
    EndJob;
    if DiskFree(byte(Directory[0])-64) < size then
      if MessageBox(^C'Programi yuklemek istediginiz diskte yeterli bos yer yok'#13+
                      ^C'Bu diske yukleme yapmak istediginizden emin misiniz?',
                      0,mfWarning+mfYesNo) <> cmYes then exit;
    Avail := true;
  end;
  procedure InitialWork;
  var
    f:text;
    T:TCodedStream;
    w:word;
    b:byte;
    BIOS : byte absolute $F000:0;
  begin
    MkDir(Directory);
    if ININame <> '' then begin
      Assign(f,Directory+'\'+IniName);
      ReWrite(f);
      if IOResult = 0 then begin
        writeln(f,Directory);
        writeln(f,';Created by Install v'+iVersion);
      end;
      Close(f);
    end;
  end;
  procedure CreateBatch(dir:FNameStr);
  var
    T:TDosStream;
    cmd,param:string;
  begin
    T.Init(dir+BatchName,stCreate);
    if T.Status = stOK then begin
      SWriteln(T,'@echo off');
      SWriteln(T,'rem Created by Install v'+iVersion);
      SWriteln(T,'cd '+Directory);
      GoClass('startup');
      if cur < PIni^.Count-1 then
         while cur <> -1 do begin
           cmd := '';param := '';
           GetNextParam(cmd,Param);
           if cmd = 'COMMAND' then SWriteln(T,param);
         end; {while}
    end;
    T.Done;
  end;

  procedure CopyFile(src,dst:string);
  var
    I,O:TDosStream;
    buf:pointer;
    bufsize:word;
  begin
    StartPerc(src+' kopyalaniyor...');
    I.Init(src,stOpenRead);
    O.Init(dst,stCreate);
    while I.GetPos < I.GetSize do begin
      UpdatePerc(I.GetPos,I.getSize);
      bufsize := 65000;
      if bufsize > I.GetSize-I.GetPos then bufsize := I.GetSize-I.GetPos;
      if bufsize > maxavail then bufsize := maxavail;
      GetMem(buf,bufsize);
      I.Read(buf,bufsize);
      O.Write(buf,bufsize);
      FreeMem(buf,bufSize);
    end;
    I.Done;
    O.Done;
  end;

var
  cmd,param:string;
  b:byte;
  P:PView;
  R:TRect;
begin
  if not AskDirectory then exit;
  InitialWork;
  CreateBatch(Directory+'\');
  CreateBatch(Copy(Directory,1,2)+'\');
  GoClass('files');
  if cur < PIni^.Count-1 then
    while cur <> -1 do begin
      cmd := '';param := '';
      GetNextParam(cmd,param);
      if cur <> -1 then
      if cmd='COPY' then begin
        CopyFile(param,Directory+'\');
      end else if cmd='UNCOMPRESS' then begin
        b := Pos(',',param);
        UnCompress(copy(param,1,b-1),Directory+'\'+copy(param,b+1,255));
      end;
    end;
  DonePerc;
  MessageBox(^C'Install:˜Ÿlem sona ermiŸtir',0,mfInfo);
  Done;
  halt(1);
end;

procedure TInstaller.HandleEvent(var Event:TEvent);
begin
  TSystem.HandleEvent(Event);
  if Event.What = evCommand then
    if Event.Command = cmInstall then Install;
end;

procedure TInstaller.HandleParams(var class,cmd,Param:String);
begin
  if class = 'APPLICATION' then begin
     if cmd = 'APPLICATION' then Application := Param else
     if cmd = 'VERSION' then Version := Param else
     if cmd = 'INSTALLDIRECTORY' then Directory := Param;
  end else
  if class = 'REQS' then begin
     if cmd = 'MINCPU' then MinCPU := s2l(Param) else
     if cmd = 'MINFILES' then MinFiles := s2l(Param) else
     if cmd = 'MINXMS' then MinXMS := s2l(Param) else
     if cmd = 'MINEMS' then MinEMS := s2l(Param) else
     if cmd = 'MINBUFFERS' then MinBuffers := s2l(Param);
  end else
  if class = 'WARNINGS' then begin
     if cmd = 'PROTECTION' then Protection := (Param='YEAH');
  end else
  if class = 'STARTUP' then begin
    if cmd = 'NAME' then begin
       BatchName := param;
       if pos('.',BatchName) < 1 then BatchName := BatchName + '.BAT';
    end;
    if cmd = 'ININAME' then IniName := param;
  end;
end;

procedure TInstaller.HandleClass(Class:String);
var
  cmd,param:string;
begin
  FastUpper(Class);
  GoClass(Class);
  if Cur < (PIni^.Count-1) then
    while Cur <> -1 do begin
      GetNextParam(cmd,Param);
      if (cmd <> '') then HandleParams(class,cmd,Param);
    end;
end;

procedure TInstaller.InitVariables;
begin
  BatchName := DefaultBatch;
  HandleClass('application');
  HandleClass('reqs');
  HandleClass('warnings');
  HandleClass('startup');
end;

function TInstaller.Upper(s:string):string;
var
  b:byte;
begin
  for b:=1 to Length(s) do s[b] := upcase(s[b]);
  Upper := s;
end;

procedure TInstaller.GetNextParam(var Cmd,Param:String);
var
  s:string;
  p:byte;
begin
  cmd := '';
  Param := '';
  repeat
    s := PString(PIni^.At(Cur))^;
    FastUpper(s);
    if s[1] = '[' then begin
      Cur := -1;
      exit;
    end;
    p := Pos(';',s);
    if p > 0 then s := copy(s,1,p-1);
    inc(Cur);
  until (s<>'') or (Cur = PIni^.Count);
  if Cur = PIni^.Count then begin
     Cur := -1;
     exit;
  end;
  p := pos('=',s);
  cmd := copy(s,1,p-1);
  param := copy(s,p+1,255);
  Strip(cmd);
  Strip(Param);
end;

procedure TInstaller.GoClass(Class:String);
var
  s:string;
begin
  Cur := 0;
  while Cur < PIni^.Count do begin
    s := Upper(PString(PIni^.At(Cur))^);
    if (s[1]='[') and (s[length(s)]=']') then
    if Upper(Class) = copy(s,2,length(s)-2) then begin
      inc(Cur);
      exit;
    end;
    inc(Cur);
  end;
end;

procedure ReadIni;
var
  f:text;
  s:string;
begin
  New(PIni,Init(10,10));
  Assign(f,INI);
  Reset(f);
  if IOResult <> 0 then exit;
  while not eof(f) do begin
    Readln(f,s);
    PIni^.Insert(NewStr(s));
  end;
  Close(f);
end;

var
  T:TInstaller;
begin
  ReadIni;
  if PIni^.Count < 1 then XAbort('INI file not found');
  T.Init;
  T.Run;
  T.Done;
end.
*** End Of File ***
