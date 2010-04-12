{
Name    : X/Dialogs 3.00b
Purpose : Dialog objects
Date    : 2nd Jan 95
Time    : 22:26
Coder   : SSG

to do's
~~~~~~~
- directory mode... (just lookin for directories)
- save mode... (this should be ok?)

Update Info:
------------
 2nd Jan 95 - 22:26 - Started...
10th Mar 96 - 16:32 - Updated to new gui scheme...
20th Aug 96 - 18:41 - rewritten the code... (with x95 support)
 5th Jan 97 - 01:57 - made it workin...
 5th Jan 97 - 02:49 - perfected...
 5th Jan 97 - 14:20 - multiple wildcard support added...
}

unit XDialogs;

interface

uses Drivers,Objects,Tools;

const

  odDirectoryMode = 1;

  fodPrompt        : FnameStr = 'Dosya adi';
  fodRefreshButton : FnameStr = '~Tazele';
  fodColumnFile    : FnameStr = 'Dosya';
  fodColumnSize    : FnameStr = 'Boyu';
  fodParentStr     : FnameStr = '(geri don)';
  fodDirStr        : FnameStr = '(dir)';

type

  PFileInfo = ^TFileInfo;
  TFileInfo = record
    Name     : string[12];
    Attr     : Byte;
    Size     : longint;
  end;

  PFileInfoColl = ^TFileInfoColl;
  TFileInfoColl = object(TSortedCollection)
    procedure FreeItem(item:pointer);virtual;
    function Compare(k1,k2:pointer):integer;virtual;
  end;

  PFileLister = ^TFileLister;
  TFileLister = object(TFormattedLister)
    function    GetText(item:longint):string;virtual;
    procedure   ItemDoubleClicked(item:longint);virtual;
    procedure   ItemFocused(item:longint);virtual;
  end;

  PFileInputLine = ^TFileInputLine;
  TFileInputLine = object(TInputLine)
    procedure HandleEvent(var Event:TEvent);virtual;
  end;

  PFileOpenDialog = ^TFileOpenDialog;
  TFileOpenDialog = object(TDialog)
    WildCard      : string;
    CurDir        : string;
    Lister        : PFileLister;
    Input         : PFileInputLine;
    constructor Init(awild,atitle:FnameStr; ahelpctx,afont,aflags:word);
    procedure   Activate(where:string);
    procedure   Refresh;
    procedure   HandleEvent(var Event:TEvent);virtual;
  end;

function ExecuteFileDialog(wildCard,atitle:FnameStr; helpctx,font:word;
                                     var fn:string):boolean;

implementation

uses XDev,XScroll,GView,XTypes,XIO,XGfx,Dos,XStr;

const

  defaultMask = ReadOnly or
                Hidden or
                Archive or
                SysFile;

{- TFileOpenDialog -}
constructor TFileOpenDialog.Init;
var
  R:TRect;
  Ps:PScrollBar;
  Pl:PLabel;
  scrbx:integer;
  s:string;
begin
  R.Assign(0,0,0,0);
  inherited Init(R,atitle);
  Config := aflags;
  Options := Options or Ocf_Centered;
  HelpContext := ahelpctx;
  New(Lister,Init(5,5,afont,10,NewColumn(fodColumnFile,130,cofNormal,
                                  NewColumn(fodColumnSize,100,cofRJust,
                                  NIL))));
  Lister^.GetBounds(R);
  Insert(Lister);
  r.a.x := r.b.x+5;
  r.b.x := r.a.x+sbButtonSize;
  scrbx := r.b.x-5;
  New(Ps,Init(R));
  Insert(Ps);
  Lister^.AssignScroller(Ps);
  r.a.y := r.b.y + 5;
  New(Pl,Init(5,r.a.y+2,fodPrompt,afont));
  Pl^.GetBounds(R);
  Insert(Pl);
  r.a.x := r.b.x + 5;
  New(Input,Init(r.a.x,r.a.y-2,scrbx-r.a.x,afont,255));
  Input^.GetBounds(R);
  Insert(Input);
  if ahelpctx <> hcNoContext then s := GetBlock(5,r.b.y+5,mnfHorizontal+mnfNoSelect,
    NewButton(Msg[Msg_OK],cmOK,
    NewButton(Msg[Msg_Cancel],cmCancel,
    NewButton(fodRefreshButton,cmRefresh,
    NewButton(Msg[Msg_Help],cmHelp,
    NIL))))) else s := GetBlock(5,r.b.y+5,mnfHorizontal+mnfNoSelect,
    NewButton(Msg[Msg_OK],cmOK,
    NewButton(Msg[Msg_Cancel],cmCancel,
    NewButton(fodRefreshButton,cmRefresh,
    NIL))));
  InsertBlock(s);
  Input^.Select;
  FitBounds;
  GetDir(0,CurDir);
  XMakeDirStr(CurDir,True);
  WildCard := awild;
  Refresh;
end;

procedure TFileOpenDialog.Refresh;
var
  P:PFileInfo;
  List:PFileInfoColl;
  s:string;
  dirinfo:SearchRec;
  b:byte;
  procedure Addit;
  begin
    New(P);
    with P^ do begin
      Name := dirinfo.Name;
      if dirinfo.Attr and Directory = 0 then FastLower(Name);
      Size := dirinfo.Size;
      Attr := dirinfo.Attr;
    end;
    List^.Insert(P);
  end;
begin
  EventWait;
  New(List,Init(20,20));
  FindFirst(CurDIr+'*.*', defaultMask+Directory,dirinfo);
  while DosError = 0 do begin
    if dirinfo.Attr and Directory > 0 then
      if dirinfo.name <> '.' then Addit;
    FindNext(dirinfo);
  end;
  for b:=1 to GetParseCount(Wildcard,';') do begin
    FindFirst(Curdir+GetParse(Wildcard,';',b), defaultMask+Directory, dirinfo);
    while DosError = 0 do begin
      if dirinfo.attr and Directory = 0 then Addit;
      FindNext(dirinfo);
    end;
  end;
  Lister^.NewList(List);
  s := Lower(Fexpand(curdir+wildcard));
  SetData(s);
  PaintView;
end;

procedure TFileOpenDialog.Activate;
var
  dirinfo:SearchRec;
  dir,name,ext:string;
  b:byte;
begin
  b := pos('.',wildcard);
  if b > 0 then ext := copy(wildcard,b,255)
           else ext := '';
  if XFileExists(xaddext(where,ext)) or XFileExists(xaddext(curdir+where,ext)) then begin
    EndModal(cmOK);
    exit;
  end;
  if pos(':',where) = 0 then
    if where[1] <> '\' then where := CurDir+where
                       else where := Fexpand(where);
  if pos('?',where)+pos('*',where) > 0 then begin
    FSplit(where,dir,name,ext);
    CurDir := dir;
    WildCard := name+ext;
  end else begin
    XMakeDirStr(where,true);
    CurDir := where;
  end;
  Refresh;
end;

procedure TFileOpenDialog.HandleEvent;
var
  s:string;
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then case Event.Command of
    cmInputNotify : begin
      s := Lower(FExpand(CurDir+PFileInfo(Event.InfoPtr)^.Name));
      SetData(s);
      Input^.PaintView;
    end;
    cmActivate : Activate(CurDir+PFileInfo(Event.InfoPtr)^.Name);
    cmRefresh : Refresh;
    cmActivateYourself : begin
      GetData(s);
      Activate(s);
    end;
    else exit;
  end else exit;
  ClearEvent(Event);
end;

{- TFileInfoColl -}
procedure TFileInfoColl.FreeItem(item:pointer);
begin
  Dispose(PFileInfo(item));
end;

function TFileInfoColl.Compare(k1,k2:pointer):integer;
var
  p1,p2:PFileInfo;
  function isdir(p:PFileInfo):boolean;
  begin
    isdir := P^.Attr and Directory > 0;
  end;
begin
  p1 := PFileInfo(k1);
  p2 := PFileInfo(k2);
  if isdir(p1) and not isdir(p2) then Compare := -1 else
    if isdir(p2) and not isdir(p1) then Compare := 1 else
      if p1^.Name > p2^.Name then Compare := 1 else
        if p1^.Name < p2^.Name then Compare := -1 else
          if p1^.Attr > p2^.Attr then Compare := 1 else
            if p1^.Attr < p2^.Attr then Compare := -1 else Compare := 0;
end;

{- TFileLister -}
procedure TFileLister.ItemDoubleClicked;
begin
  Message(Owner,evCommand,cmActivate,ItemList^.At(item));
end;

procedure TFileLister.ItemFocused;
begin
  Message(Owner,evCommand,cmInputNotify,ItemList^.At(item));
end;

function TFileLister.GetText;
var
  P:PFileInfo;
  fn:FnameStr;
  at:FnameStr;
begin
  P := ItemList^.At(item);
  if P^.name = '..' then at := fodParentStr else
    if P^.Attr and Directory > 0 then at := fodDirStr else at := l2s(P^.Size);
  GetText := P^.name+'|'+at;
end;

{- TFileInputLine -}
procedure TFileInputLine.HandleEvent;
begin
  inherited HandleEvent(Event);
  if Event.What = evKeydown then if Event.Keycode = kbEnter then begin
    Message(Owner,evCommand,cmActivateYourself,NIL);
    ClearEvent(Event);
  end;
end;

{************************ EXECUTEFILEDIALOG ************************}
function ExecuteFileDialog;
var
  P:PFileOpenDialog;
begin
  ExecuteFileDialog := false;
  New(P,Init(Wildcard,ATitle,helpctx,font,0));
  if GSystem^.ExecView(P) = cmOK then begin
     P^.GetData(fn);
     ExecuteFileDialog := XFileExists(fn);
  end;
  if P <> NIL then Dispose(P,Done);
end;

end.