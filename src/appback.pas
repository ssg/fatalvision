{
Name          : AppBack 1.01a
Purpose       : Generic Application Backup Routines
Coder	      : SSG

Update Info:
------------
25th May 94 - 05:11 - Adapted to Turkish...
27th Aug 97 - 22:35 - formatted the source a bit.. made it working under
                      latest GUI...
}

unit AppBack;

interface

uses

  Dos,XColl,XTypes,Objects,Tools,Debris,Disk,XDiag,XBackup,Drivers,XGfx,
  XInput,GView;

const

  Ctx_AppBackup  : word = hcNoContext;
  Ctx_AppRestore : word = hcNoContext;

procedure BackupData(datawild:FnameStr);
procedure RestoreData;
procedure FormatDisk;

implementation

function GetDriveCollection:PTextCollection;
const
  Big525 : string[6] = '5.25" ';
  Big35  : string[6] = '3.5"  ';

  Cap360 : string[6] = '360K  ';
  Cap720 : string[6] = '720K  ';
  Cap12  : string[6] = '1.2M  ';
  Cap144 : string[6] = '1.44M ';
  Cap288 : string[6] = '2.88M ';

var
  PC:PTextCollection;
  drc,drt:byte;
  temp:byte;
  b:byte;
  s:string[20];
  cat:string[20];
begin
  New(PC,Init(5,5));
  temp := GetDiskDriveCount;
  GetDriveCollection := PC;
  if temp = 0 then exit;
  for b:=0 to temp-1 do begin
    s := char(b+65)+': ';
    case hi(GetDisketteParams(b)) of
      1 : cat := Big525 + Cap360;
      2 : cat := Big525 + Cap12;
      3 : cat := Big35  + Cap720;
      4 : cat := Big35  + Cap144;
      5 : cat := Big35  + Cap288;
      else cat := '????';
    end; {case}
    s := s + cat;
    PC^.Insert(NewStr(s));
  end;
end;

procedure FormatDisk;
var
  R:TRect;
  P:PDialog;
begin
end;

procedure RestoreData;
var
  P:PDialog;
  R:TRect;
  PL:PStringViewer;
  PR:PRestore;
  code:word;
  fc:integer;
begin
  R.Assign(0,0,0,0);
  New(P,Init(R,'Geri YÅkleme'));
  P^.Options := P^.Options or Ocf_Centered;
  P^.HelpContext := Ctx_AppRestore;
  R.Assign(0,0,30*8,4*10);
  R.Move(5,5);
  New(PL,Init(R,ViewFont));
  PL^.NewList(GetDriveCollection);
  PL^.GetBounds(R);
  P^.Insert(PL);
  P^.InsertBlock(GetBlock(5,r.b.y+5,mnfHorizontal,
    NewButton(Msg[Msg_OK],cmOK,
    NewButton(Msg[Msg_Cancel],cmClose,
    NIL))));
  P^.FitBounds;
  code := GSystem^.ExecView(P);
  fc := PL^.FocusedItem;
  if P <> NIL then Dispose(P,Done);
  if code <> cmOK then exit;
  PR := New(PRestore,Init('Geri YÅkleme',char(lo(fc)+65)+':\',FExpand('.')+'\'));
  GSystem^.Insert(PR);
end;

procedure BackupData(datawild:fnameStr);
var
  P:PDialog;
  PB:PBackup;
  PI:PInputStr;
  PL:PStringViewer;
  R:TRect;
  r2:trect;
  s:string[39];
  code:word;
  Event:TEvent;
  procedure dip;near;
  begin
    if P <> NIL then Dispose(P,Done);
  end;
begin
  R.Assign(0,0,0,0);
  New(P,Init(R,'Yedekleme'));
  P^.Options := P^.Options or Ocf_Centered;
  P^.HelpContext := Ctx_Appbackup;
  New(PI,Init(5,5,31,'Aáçklama ',39,Idc_StrDefault+Idc_PreDel));
  s := Date2Str(GetSysDate,False)+' tarihli veri dosyalarç';
  PI^.SetData(s);
  PI^.GetBounds(R);
  P^.Insert(PI);
  r2.Assign(0,0,31*8,4*10);
  r2.Move(90,r.b.y+5);
  New(PL,Init(r2,ViewFont));
  PL^.newList(GetDriveCollection);
  P^.Insert(PL);
  P^.InsertBlock(GetBlock(5,R.B.Y+5,mnfVertical,
    NewButton('~Tamam ',cmOk,
    NewButton(Msg[Msg_Cancel],cmCancel,
    NIL))));
  PI^.Select;
  P^.FitBounds;
  code := GSystem^.ExecView(P);
  if code <> cmOK then begin
    dip;
    exit;
  end;
  PI^.GetData(s);
  code := PL^.FocusedItem;
  dip;
  PB := New(PBackup,Init('Yedekleme',DataWild,FExpand('.')+'\',char(lo(code)+65)+':\',s));
  GSystem^.Insert(PB);
end;

end.