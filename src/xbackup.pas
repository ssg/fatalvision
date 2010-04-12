{
Name            : XBackup 3.03a
Purpose         : Extended Backup Routines
Coder           : SSG
Date            : 20th May 94

Update Info:
------------
25th May 94 - 05:08 - Adapted Turkish Texts...
26th May 94 - 02:00 - Added new changeline method...
26th May 94 - 02:03 - Fixed some bugs...
 8th Sep 94 - 21:16 - Added cancelability... (what?)
 3rd Dec 94 - 21:06 - Adapted to new gui...
26th Dec 94 - 22:59 - Removed diskfree check...
23rd Mar 95 - 01:33 - Grrr..
27th Apr 95 - 10:37 - hrrr...
27th Aug 97 - 22:36 - adaptation to latest GUI engine...
}

{$I-}

unit XBackup;

interface

uses

  XDev,XStr,XIO,XBuf,Drivers,GView,Disk,XGfx,Debris,XTypes,Dos,Objects,Tools;

const

  BackupId = 441664083;
  BlockId  = 1263488066;

  VolumeId : array[1..8] of char = 'GENBACK!';
  BackName : string[8] = 'GENBACK!';

  MinFree = 512;

  Id_Backup  = 1262698818;
  Id_Restore = 1381258066;

  Ctx_Backup  : word = hcNoContext;
  Ctx_Restore : word = hcNoContext;

type

  TBackupHeader = record
    Id          : longint;    {'SBSeof'}
    Flags       : longint;    {default 0}
    Desc        : string[39]; {description of backup}
    Reserved    : array[1..48] of byte; {reserved}
  end;

  TBlockHeader = record
    Id         : longint;    {'BLOK'}
    BlockType  : byte;       {0 = file start,1=file cont,FF=terminator}
    BlockSize  : longint;    {block length}
    CRC        : longint;    {block CRC, 0 skips checking}
    Reserved   : array[1..3] of byte; {reserved}
  end;

  TFileHeader = SearchRec; {same as it}

  PFileLink = ^TFileLink;
  TFileLink = record
    Header  : TFileHeader;
    Next    : PFileLink;
  end;

  PBackup = ^TBackup;
  TBackup = object(TDialog)
    Link          : PFileLink;
    CurrentF      : PFileLink;
    SrcDir,DstDir : FNameStr;
    Src,Dst       : PDosStream;
    BH            : TBackupHeader;
    TH            : TBlockHeader;
    PG            : PBarGraph;
    PS            : PDynamicLabel;
    TotalSize     : longint;
    CurSize       : longint;
    LastPos       : longint;
    Disk          : Word;
    Drive         : Byte;
    Finished      : boolean;
    constructor Init(AHdr,WildCard,ASrcDir,ADstDir,Descrp:FNameStr);
    destructor  Done;virtual;
    procedure   Backprocess;virtual;
    function    Valid(acmd:word):boolean;virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   InitNextFile;
    procedure   InitNextDisk(AvailFree:longint);
    procedure   ReadLinks(var s:string);
    procedure   FlushLastPos;
  end;

  PRestore = ^TRestore;
  TRestore = object(TDialog)
    Src,Dst       : PDosStream;
    SrcDir,DstDir : FNameStr;
    PG            : PBarGraph;
    PS            : PDynamicLabel;
    Disk          : word;
    Drive         : byte;
    TH            : TBlockHeader;
    BH            : TBackupHeader;
    Finished      : boolean;
    CurrentF      : SearchRec;
    constructor Init(AHdr,ASrcDir,ADstDir:FNameStr);
    destructor  Done;virtual;
    procedure   Backprocess;virtual;
    function    Valid(acmd:word):boolean;virtual;
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   InitNextDisk;
    procedure   InitNextFile;
  end;

implementation

procedure FuckIt(var P:PDosStream);
begin
  if P <> NIL then begin
    Dispose(P,Done);
    P := NIL;
  end;
end;

function WaitDisk(drive:byte;msg:string):boolean;
var
  code:word;
begin
  code := XMessageBox(msg,0,mfWarning+mfOkCancel);
  WaitDisk := code = cmOk;
{  StartJob(msg);
  oldback := GetSystem(Sys_Backprocess);
  SetSystem(Sys_Backprocess,false);
  repeat until not DiskExists(Drive);
  repeat until DiskExists(Drive);
  EndJob;
  SetSystem(Sys_Backprocess,oldback);}
end;

function TRestore.Valid;
begin
  if not Finished then Finished := XMessageBox(^C'YÅkleme iülemini iptal etmek istiyor musunuz?',
                                   0,mfConfirm+mfYesNo) = cmYes;
  Valid := Finished;
end;

constructor TRestore.Init;
var
  R:TRect;
begin
  R.Assign(0,0,0,0);
  inherited Init(R,AHdr);
  Options := Options or Ocf_Centered;
  R.Assign(0,0,320,60);
  R.Move(5,5);
  New(PG,Init(R,0,0));
  Insert(PG);
  R.A.Y := R.B.Y + 5;
  R.B.Y := R.A.Y + 11;
  New(PS,Init(r.a.x,r.b.y+5,r.b.x-r.a.x,'',cBlack,Col_back,ViewFont));
  Insert(PS);
  FitBounds;

  SrcDir := ASrcDir;
  DstDir := ADstDir;
  Drive := Byte(Upcase(SrcDir[1]))-65;
  HelpContext := Ctx_Restore;
  InitNextFile;
  if Finished then Fail;
end;

procedure TRestore.Backprocess;
var
  Buf:Pointer;
  BufSize:word;
  code:word;
begin
  if Finished then begin
    SetState(Scf_Backprocess,False);
    Message(@Self,evCommand,cmClose,@Self);
    exit;
  end;
  BufSize := 36864;
  if BufSize > MaxAvail-1000 then BufSize := MaxAvail - 1000;
  if BufSize > Src^.GetSize-Src^.GetPos then BufSize := Src^.GetSize-Src^.GetPos;
  if BufSize > TH.BlockSize then BufSize := TH.BlockSize;
  GetMem(Buf,BufSize);
  repeat
    Src^.Read(Buf^,BufSize);
    if Src^.Status <> stOK then
      if not WaitDisk(drive,'LÅtfen disketi takçnçz') then begin
        FreeMem(Buf,BufSize);
        Finished := true;
        exit;
      end;
    Src^.Reset;
  until Src^.Status = stOK;
  Dst^.Write(Buf^,BufSize);
  FreeMem(Buf,BufSize);
  PG^.Update(Src^.GetSize,Src^.GetPos);
  Dec(TH.BlockSize,BufSize);
  dec(CurrentF.Size,BufSize);
  if CurrentF.Size = 0 then InitNextFile else if TH.BlockSize = 0 then begin
      InitNextDisk;
      if Finished then exit;
      Src^.Read(TH,SizeOf(TH));
      if TH.BlockType <> 1 then begin
        XMessageBox(^C'Backup verilerinde hata var!!',0,mfError);
        Finished := True;
        exit;
      end; {if non-valid block}
  end; {if currentf more than zero}
end;

procedure TRestore.HandleEvent;
begin
  inherited HandleEvent(Event);
  if Event.What = evBroadcast then
    if Event.Command = Brc_IsAnyone then if
      Event.InfoLong = Id_Restore then ClearEvent(Event);
end;

procedure TRestore.InitNextFile;
var
  ok:boolean;
  code:word;
  old:longint;
begin
  if Finished then exit;
  FuckIt(Dst);
  if Src <> NIL then InitNextDisk;
  if Finished then exit;
  ok := false;
  repeat
    repeat
      old := Src^.GetPos;
      repeat
        Src^.Read(TH,SizeOf(TH));
        if Src^.Status <> stOK then if MessageBox(^C'Disket okunamadi'#13+
                                                  ^C'Tekrar deneyeyim mi?',0,mfYesNo) = cmNo then begin
          Finished := true;
          exit;
        end;
      until Src^.Status = stOK;
      case TH.BlockType of
        1 : begin
              Src^.Seek(Src^.GetPos+TH.BlockSize);
              if Src^.GetPos = Src^.GetSize then InitNextDisk;
            end;
        $FF : begin
                Finished := True;
                exit;
              end;
      end; {case}
      if Finished then exit;
    until TH.BlockType = 0;
    Src^.Read(CurrentF,SizeOf(CurrentF));
    PS^.NewText(CurrentF.Name);
    if CurrentF.Size > DiskFree(byte(upcase(DstDir[1]))-64) then begin
      code := XMessageBox(^C+CurrentF.Name+' dosyasç iáin hedef diskte yer yok'#13+
                  ^C'Yedekleme iülemine devam etmek ister misiniz?',0,mfWarning+mfYesNo);
      Finished := code <> cmYes;
      if Finished then exit;
    end else ok := true;
  until ok;
  New(Dst,Init(DstDir+CurrentF.Name,stCreate));
end;

destructor TRestore.Done;
begin
  FuckIt(Src);
  FuckIt(Dst);
  inherited Done;
end;

procedure TRestore.InitNextDisk;
var
  code:word;
  bol:boolean;
  TempBH : TBackupHeader;
  function Understand:boolean;near;
  var
    T:TBootRecord;
    b:byte;
  begin
    Understand := false;
    FillChar(T,SizeOf(T),0);
    b := SafeRead(T,Drive,0,1,1,0);
    case b of
      0:;
      $80:exit;
      else begin
        code := XMessageBox('Disk error. Code $'+HexB(b),0,mfError+mfOkCancel);
        Finished := code <> cmOK;
        exit;
      end;
    end; {case}
    if (T.SerialNumber = Disk) and
       BufCmp(T.VolumeLabel,VolumeId,8) and
       XFileExists(SrcDir+BackName) then begin
                                             if T.SerialNumber <> Disk then exit;
                                             Understand := True
                                           end;
  end;
begin
  repeat
    inc(Disk);
    FuckIt(Src);
    if Finished then exit;
    repeat
      if not WaitDisk(drive,'LÅtfen '+l2s(disk)+' no''lu disketi takçnçz') then begin
        Finished := true;
        exit;
      end;
      bol := Understand;
      if Finished then exit;
    until bol;
    if Finished then exit;
    New(Src,Init(SrcDir+BackName,stOpenRead));
    FillChar(TempBH,SizeOf(TempBH),0);
    if BufCmp(TempBH,BH,SizeOf(BH)) then begin
      Src^.Read(TempBH,SizeOf(TempBH));
      Move(TempBH,BH,SizeOf(BH));
      if disk=1 then begin
        code := MessageBox(^C'Taktçßçnçz disket'#13+
                           ^C'"'+Bh.Desc+'"'#13+
                           ^C'isimli yedek bilgilere aittir.',0,
                           mfWarning+mfOkCancel);
        if code <> cmOK then begin
          Finished := True;
          exit;
        end;
      end;
    end else Src^.Read(TempBH,SizeOf(TempBH));
  until BufCmp(BH,TempBH,SizeOf(BH));
end;

constructor TBackup.Init;
var
  R:TRect;
begin
  R.Assign(0,0,0,0);
  inherited Init(R,AHdr);
  Options := Options or Ocf_Centered;
  R.Assign(0,0,320,60);
  R.Move(5,5);
  PG := New(PBarGraph,Init(R,TotalSize,0));
  Insert(PG);
  R.A.Y := R.B.Y + 5;
  R.B.Y := R.A.Y + 11;
  PS := New(PDynamicLabel,Init(r.a.x,r.a.y,r.b.x-r.a.x,'',cBlack,Col_back,ViewFont));
  Insert(PS);

  SrcDir := ASrcDir;
  DstDir := ADstDir;
  Drive  := Byte(Upcase(DstDir[1])) - 65;
  ReadLinks(WildCard);
  FillChar(BH,SizeOf(BH),0);
  with BH do begin
    Id    := BackupId;
    Flags := 0;
    Desc  := Descrp;
  end;
  FitBounds;
  Finished := Link = NIL;
  HelpContext := Ctx_Backup;
  InitNextFile;
  if Finished then Fail;
end;

{
notes:
------
init:backup (writes header)
init:source (write block header)
read:source
write:backup
if write fails
  done:backup
  init:backup
  write:source (write sub-block header)
done:source
done:backup
}

procedure TBackup.HandleEvent;
begin
  inherited HandleEvent(Event);
  if Finished then exit;
  if Event.What = evBroadcast then
    if Event.Command = Brc_IsAnyone then if
      Event.InfoLong = Id_Backup then ClearEvent(Event);
end;

procedure TBackup.Backprocess;
var
  BufSize:word;
  Buf:Pointer;
  code:word;
  procedure DiskUp;near;
  begin
    FlushLastPos;
    InitNextDisk(BufSize);
    FillChar(TH,SizeOf(TH),0);
    LastPos := Dst^.GetPos;
    TH.ID        := BlockId; {sub-block}
    TH.BlockType := 1;
    Dst^.Write(TH,SizeOf(TH));
    Dst^.Write(Buf^,BufSize);
  end;
begin
  if Finished then begin
    SetState(Scf_Backprocess,False);
    Message(@Self,evCommand,cmClose,@Self);
    exit;
  end;
  BufSize := 36864;
  if BufSize > MaxAvail-1000 then BufSize := MaxAvail-1000;
  if BufSize > Src^.GetSize-Src^.GetPos then BufSize := Src^.GetSize-Src^.GetPos;
  if BufSize > DiskFree(Drive+1) then BufSize := DiskFree(Drive+1);
  if BufSize > 0 then begin
    GetMem(Buf,BufSize);
    Src^.Read(Buf^,BufSize);
    Dst^.Write(Buf^,BufSize);
    FreeMem(Buf,BufSize);
    inc(CurSize,BufSize);
    PG^.Update(TotalSize,CurSize);
  end else DiskUp;
  if Dst^.Status <> stOK then begin
    Dst^.Reset;
    WaitDisk(drive,'LÅtfen disketi takçnçz');
    DiskUp;
  end;
  if Src^.GetPos = Src^.GetSize then begin
    CurrentF := CurrentF^.Next;
    Finished := CurrentF = NIL;
    if not Finished then InitNextFile else begin
      FlushLastPos;
      FillChar(TH,SizeOf(TH),0);
      TH.Id        := BlockId; {terminator II}
      TH.BlockType := $FF;
      Dst^.Write(TH,SizeOf(TH));
    end;
  end;
end;

function TBackup.Valid;
begin
  if not Finished then
    Finished := XMessageBox(^C'Yedekleme iülemini iptal etmek istiyor musunuz?',
                           0,mfWarning+mfYesNo) = cmYes;
  Valid := Finished;
end;

procedure TBackup.InitNextFile;
begin
  if Finished then exit;
  repeat
    Finished := CurrentF = NIL;
    if Finished then exit;
    FuckIt(Src);
    FlushLastPos;
    if Dst = NIL then InitNextDisk(MinFree);
    if Finished then exit;
    FillChar(TH,SizeOf(TH),0);
    TH.Id        := BlockId;
    LastPos      := Dst^.GetPos;
    Dst^.Write(TH,SizeOf(TH));
    Dst^.Write(CurrentF^.Header,SizeOf(CurrentF^.Header));
    PS^.NewText(CurrentF^.Header.Name);
    if CurrentF^.Header.Size > 0 then begin
      New(Src,Init(SrcDir+CurrentF^.Header.Name,stOpenRead));
      exit;
    end else CurrentF := CurrentF^.Next;
  until false;
end;

procedure TBackup.InitNextDisk;
var
  code:word;
  bol:boolean;
  function Understand:boolean;near;
  var
    T:TBootRecord;
    b:byte;
    Deneme:SearchRec;
    firsttest : boolean;
  begin
    EventWait;
    Understand := false;
    FillChar(T,SizeOf(T),0);
    SafeRead(T,Drive,0,1,1,0);
    firsttest := false;
    if BufCmp(T.VolumeLabel,VolumeId,8) then begin
      code := XMessageBox(^C'Takmçü oldußunuz disket yedek bilgiler iáermektedir'#13+
                         ^C'Eski bilgiler silinecektir'#13+
                         ^C'Bu disketi kullanmak istiyor musunuz?',0,mfWarning+mfYesNoCancel);
      case code of
        cmCancel : begin
                     Finished := True;
                     exit;
                   end;
        cmNo     : exit;
      end; {case}
      firsttest := true;
    end;
    Move(VolumeId,T.VolumeLabel,8);
    T.SerialNumber := Disk;
    b := SafeWrite(T,Drive,0,1,1,0);
    case b of
      $80 : exit;
      0   : ;
      else begin
        code := XMessageBox('Disk error. Code $'+HexB(b),0,mfWarning+mfOkCancel);
        Finished := code <> cmOK;
        exit;
      end;
    end; {case}
    Understand := b = 0;
    if b <> 0 then exit;
    if not firsttest then begin
      Understand := false;
      FindFirst(DstDir+'*.*',Archive+ReadOnly+Hidden+SysFile,Deneme);
      if DosError = 0 then begin
        code := XMessageBox(^C'Taktçßçnçz disket boü deßil'#13+
                   ^C'Diskette bulunan dosyalar silinecektir'#13+
                   ^C'Bu disketi kullanmak istiyor musunuz?',0,mfWarning+mfYesNoCancel);
        case code of
          cmCancel : begin
                       Finished := True;
                       exit;
                     end;
          cmNo     : exit;
        end;
      end;
    end; {if firsttest}
    if DiskFree(Drive+1) < AvailFree then begin
      XMessageBox(^C'Taktçßçnçz diskette yeterli boü yer yok',0,mfError);
      exit;
    end;
    Understand := true; {OK.. diskette analyzed}
  end;
begin
  lastpos := 0;
  FuckIt(Dst);
  if Finished then exit;
  inc(Disk);
  repeat
    if not WaitDisk(drive,'LÅtfen '+l2s(disk)+' no''lu disketi takçnçz') then begin
      Finished := true;
      exit;
    end;
    bol := Understand;
    if Finished then exit; {do not optimize these lines (I know them)}
  until bol;
  StartJob('Disketteki dosyalar siliniyor');
  XDeleteWild(DstDir+'*.*');
  EndJob;
  New(Dst,Init(DstDir+BackName,stCreate));
  Dst^.Write(BH,SizeOf(BH));
end;

procedure TBackup.FlushLastPos;
begin
  if lastpos > 0 then begin
    Dst^.Seek(lastpos);
    TH.BlockSize := Dst^.GetSize-LastPos;
    dec(TH.BlockSize,SizeOf(TH));
    if TH.BlockType = 0 then dec(TH.BlockSize,SizeOf(SearchRec));
    Dst^.Write(TH,SizeOf(TH));
    Dst^.Seek(Dst^.GetSize);
  end;
end;

destructor TBackup.Done;
  procedure DisposeFileLinks(var P:PFileLink);near;
  begin
    if P^.Next <> NIL then DisposeFileLinks(P^.Next);
    Dispose(P);
    P := NIL;
  end;
begin
  FuckIt(Src);
  FuckIt(Dst);
  if Link <> NIL then DisposeFileLinks(Link);
  inherited Done;
end;

procedure TBackup.ReadLinks(var s:string);
var
  P:PFileLink;
  PrevP:PFileLink;
  Info:SearchRec;
begin
  PrevP := NIL;
  FindFirst(SrcDir+s,ReadOnly+Archive,Info);
  while DosError = 0 do begin
    New(P);
    if PrevP = NIL then Link := P else PrevP^.Next := P;
    P^.Header := Info;
    inc(TotalSize,Info.Size);
    P^.Next   := NIL;
    PrevP := P;
    FindNext(Info);
  end; {while}
  CurrentF := Link;
end;

end.
