{
Name            : XIO 2.1b
Purpose         : eXtended Input/Output services
Date            : 05th Dec 93
Coder           : SSG

updates:
--------
18th Jan 97 - 01:17 - revised all the code...
}

{$N+}

unit XIO;

interface

uses

  XStr,XBuf,Objects,Dos;

type

  TFCB = record
    Drive : byte;
    Name : array[1..11] of char;
    CurrentBlock : word;
    RecSize      : word;
    Filesize     : longint;
    Date         : word;
    Time         : word;
    Reserved     : array[1..8] of byte;
    CurrentRec   : byte;
    RecNo        : longint;
  end;

  PXFCB = ^TXFCB;
  TXFCB = record
    Id   : byte;
    Zero : array[1..5] of byte;
    Attr : byte;
    Drive : byte;
    Name : array[1..11] of char;
    CurrentBlock : word;
    RecSize      : word;
    Filesize     : longint;
    Date         : word;
    Time         : word;
    Reserved     : array[1..8] of byte;
    CurrentRec   : byte;
    RecNo        : longint;
  end;

const

  xprOK             = 0;  {patch constants}
  xprAlreadyPatched = 1;
  xprPatchError     = 2;
  xprParamError     = 3;
  xprInvalidFile    = 4;

{The following 7 functions are cut copy paste from Borland (Heh heh)}
function  IsDir(var S: String): Boolean;
function  IsWild(var S: String): Boolean;
function  GetCurDir: DirStr;
function  ValidFileName(var FileName: FNameStr): Boolean;
function  PathValid(var Path: FNameStr): Boolean;
function  DriveValid(Drive: Char): Boolean;
function  ReplaceExt(FileName: FNameStr; NExt: ExtStr):FNameStr;
function  XDeleteAnyWay(AFile:FnameStr):boolean;              {Erases all attribs}
function  XDeleteFile(AFile:FNameStr):boolean;                {Erases file}

procedure XDeleteWild(AFileSpec:FNameStr);            {Erases multi-files}
procedure XRenameAnyway(OldName,NewName:FNameStr);    {Erases NewName if x}
procedure XSetFileAttr(AFile:FNameStr;Attr:Word);    {Sets file attr}
procedure XSetFileDate(afile:FnameStr;date:longint);
procedure XSetDrive(drive:byte);                      {sets drive}
procedure XAbort(Msg:FNameStr);   {halts program with given message}
procedure XAppInit(Name,Version,c:string;MinParamCount:integer;Usage:string);
procedure XWritePerc(current,max:longint);
procedure XWriteGraph(current,max:longint);
procedure XMakeDirStr(var dir:string;slash:boolean);
procedure XSetRedirection(afile:FnameStr);

function  XPatch(var s:TStream; offset:longint; aorg,apatch:string):word;
function  XGetFileDate(f:FNameStr):longint;
function  XGetFileAttr(f:FNameStr):word;
function  XSetVolume(drive:byte; newvolume:FNameStr):boolean;
function  XRenameFile(OldName,NewName:FNameStr):boolean; {Renames file}
function  XAddExt(s:FNameStr;ext:ExtStr):FNameStr;
function  XGetWorkDir:FNameStr;
function  XGetDirName(AFile:FNameStr):DirStr;         {Gets dir parse}
function  XGetFileName(AFile:FNameStr):FnameStr;      {Gets name parse}
function  XGetFileExt(Afile:FnameStr):FnameStr;       {gets ext parse}
function  XFileExists(s:FNameStr):boolean;     {This is a must!}
function  XFilesExist(s:FnameStr):boolean;     {multiple files search}
function  XGetFileChecksum(AFile:FNameStr):longint;
function  XGetStreamChecksum(var S:TStream;size:longint):longint;
function  XGetStreamCRC32(var S:TStream;size:longint):longint;
function  XIsParam(AParam:string):integer;    {Returns param no of param}
function  XGetParamInt(ParamNo:integer):longint;
function  XGetParamStr(ParamNo:integer):string;
function  XGetDrive:byte;
function  XGetFileSize(s:FNameStr):longint;
function  XGetUniqueName(adir:FnameStr; ext:ExtStr):FNameStr;
function  XGetTempDir:FnameStr;
function  XTestEXECRC:boolean;

procedure ok;
procedure failed;

implementation

uses

  XStream;

type

  TEXEHeader = record
    Id           : Word;
    LastPageSize : Word;
    FileSize     : Word; { in 512 byte pages }
    RelCount     : word;
    HdrSize      : Word; { in 16 byte paragraphs}
    MinMem       : word; { in 16 byte paragraphs}
    MaxMem       : Word; { in 16 byte paragraphs}
    SSInit       : Word;
    SPInit       : Word;
    NegSum       : Word;
    IPInit       : Word;
    CSInit       : Word;
    RelOfs       : Word;
    OverlayCount : Word;
    Unused1      : word;
    Unused2      : word;
  end;

function XTestEXECRC:boolean;
var
  h:TEXEHeader;
  T:TDosStream;
  crc:word;
  buf:pointer;
  bufsize:word;
begin
  T.Init(ParamStr(0),stOpenRead);
  T.Read(h,SizeOf(h));
  crc := 0;
  while T.GetPos < T.GetSize do begin
    bufSize := 65000;
    if bufSize > T.GetSize-T.GetPos then bufSize := T.GetSize-T.GetPos;
    GetMem(buf,BufSize);
    T.Read(buf^,bufSize);
    inc(crc,GetChecksum(buf^,bufSize));
    FreeMem(buf,bufSize);
  end;
  T.Done;
  XTestEXECRC := h.NegSum = crc;
end;

procedure XSetFileDate;
var
  f:File;
begin
  Assign(f,afile);
  Reset(f);
  SetFTime(f,date);
  Close(f);
end;

function XGetFileAttr;
var
  x:File;
  attr:word;
begin
  Assign(x,F);
  GetFAttr(x,attr);
  XGetFileAttr := attr;
end;

function XGetFileDate;
var
  x:File;
  l:longint;
begin
  Assign(x,F);
  Reset(x);
  GetFTime(x,l);
  Close(x);
  XGetFileDate := l;
end;

function XGetUniqueName;
var
  f:FnameStr;
  counter:longint;
begin
  for counter := 0 to MaxLongint do begin
    Str(counter,f);
    f := f + ext;
    if not XFileExists(adir+f) then begin
      XGetUniqueName := f;
      exit;
    end;
  end;
  XGetUniqueName := '';
end;

function  XSetVolume(drive:byte; newvolume:FNameStr):boolean;
var
  b:byte;
  fcb:TXFCB;
  P:PXFCB;
  dir:FNameStr;
  dirinfo:SearchRec;
  l,r:string[8];
  function FCBCall(func:byte):byte;assembler;
  asm
    push ds
    mov  ah,func
    xor  al,al
    lds  dx,P
    int  21h
    pop  ds
  end;
begin
  XSetVolume := true;
  GetDir(0,dir);
  ChDir(copy(dir,1,2)+'\');
  ClearBuf(fcb,SizeOf(fcb));
  P := @fcb;
  fcb.Id    := $FF;
  fcb.Attr  := VolumeID;
  fcb.Drive := drive;
  FindFirst('*.*',VolumeID,dirinfo);
  if DosError = 0 then begin
    b := Pos('.',dirinfo.Name);
    if b > 0 then begin
      l := copy(dirinfo.Name,1,b-1);
      r := copy(dirinfo.Name,b+1,255);
    end else begin
      l := dirinfo.Name;
      r := '';
    end;
    Move(l[1],fcb.Name,length(l));
    if r <> '' then Move(r[1],fcb.Name[9],length(r));
    FCBCall($13); {delete}
  end;
  ClearBuf(fcb.Name,11);
  Move(newvolume[1],fcb.Name,length(newvolume));
  if FCBCall($16) <> 0 then XSetVolume := false;
  if FCBCall($10) <> 0 then XSetVolume := false;
  ChDir(dir);
end;

function XGetDrive;
var
  s:string[1];
begin
  GetDir(0,s);
  XGetDrive := byte(upcase(s[1]))-64;
end;

procedure XSetDrive;assembler;
asm
  mov  ax,440fh
  mov  bl,drive
  int  21h
end;

function XGetStreamCRC32(var S:TStream;size:longint):longint;
var
  Buf     : pointer;
  BufSize : word;
  current : longint;
  CRC     : longint;
begin
  current := 0;
  CRC     := FIRST_CRC;
  while current < Size do begin
    BufSize := 65000;
    if BufSize > MaxAvail then BufSize := MaxAvail;
    if BufSize > Size-current then BufSize := Size-current;
    GetMem(Buf,BufSize);
    S.Read(Buf^,BufSize);
    CRC := GetCRC32(Buf^,BufSize,CRC);
    FreeMem(Buf,BufSize);
    inc(current,BufSize);
  end;
  XGetStreamCRC32 := CRC;
end;

function XGetStreamChecksum(var S:TStream;size:longint):longint;
var
  Buf     : pointer;
  BufSize : word;
  current : longint;
  CRC     : longint;
begin
  current := 0;
  CRC     := 0;
  while current < Size do begin
    BufSize := 65000;
    if BufSize > MaxAvail then BufSize := MaxAvail;
    if BufSize > Size-current then BufSize := Size-current;
    GetMem(Buf,BufSize);
    S.Read(Buf^,BufSize);
    inc(CRC,GetChecksum32(Buf^,BufSize));
    FreeMem(Buf,BufSize);
    inc(current,BufSize);
  end;
  XGetStreamChecksum := CRC;
end;

procedure XMakeDirStr;
begin
  if slash then begin
    if dir[length(dir)] <> '\' then begin
      inc(byte(dir[0]));
      dir[length(dir)] := '\';
    end;
  end else if dir[length(dir)] = '\' then dec(byte(dir[0]));
end;

procedure ok;
begin
  writeln('ok  ');
end;

procedure failed;
begin
  writeln('failed');
end;

function XGetFileSize;
var
  dirinfo:SearchRec;
begin
  FindFirst(s,readonly+archive+hidden+sysfile,dirinfo);
  if DosError = 0 then XGetFileSize := dirinfo.Size else XGetFileSize := 0;
end;

procedure XRenameAnyway;
begin
  if XFileExists(NewName) then XDeleteFile(NewName);
  XRenameFile(OldName,NewName);
end;

function XGetWorkDir;
var
  s:FNameStr;
  dir:dirstr;
  name:namestr;
  ext:extstr;
begin
  FSplit(FExpand(ParamStr(0)),dir,name,ext);
  XGetWorkDir := dir;
end;

procedure XWritePerc(current,max:longint);
var
  s:string;
  b:byte;
  tcur,tmax:comp;
  result:longint;
begin
  inc(max,byte(max = 0));
  tcur := current;
  tmax := max;
  result := trunc((tcur/max)*100);
  Str(result,s);
  s := s + '%  ';
  write(s+Duplicate(#8,length(s)));
end;

procedure XWriteGraph(current,max:longint);
const
  barw = 20; {bar width}
var
  s:string;
  n:byte;
begin
  inc(max,byte(max = 0));
  n := (barw*current) div max;
  s := Duplicate(#219,n) + Duplicate(#177,barw-n);
  write(s+Duplicate(#8,length(s)));
end;

function  XIsParam;
var
  n:integer;
  s:string;
  i:byte;
begin
  XIsParam := 0;
  FastUpper(AParam);
  for n:=1 to ParamCount do begin
    s := ParamStr(n);
    if (s[1] = '/') or (s[1] = '-') then begin
      Delete(s,1,1);
      i := Pos(':',s);
      if i > 0 then Delete(s,i,255);
      FastUpper(s);
      if s = AParam then XIsParam := n;
    end;
  end;
end;

function XGetParamInt;
var
  s:string;
  b:byte;
  l:longint;
  code:integer;
begin
  XGetParamInt := -1;
  if ParamNo  = 0 then exit;
  s := ParamStr(ParamNo);
  b := Pos(':',s);
  if b > 0 then Delete(s,1,b);
  Val(s,l,code);
  XGetParamInt := l;
end;

function XGetParamStr;
var
  s:string;
  b:byte;
begin
  XGetParamStr :='';
  if ParamNo  = 0 then exit;
  s := ParamStr(ParamNo);
  b := Pos(':',s);
  if b > 0 then Delete(s,1,b);
  XGetParamStr := s;
end;

function XGetFileChecksum(AFile:FNameStr):longint;
var
  T:TDosStream;
begin
  T.Init(AFile,stOpenRead);
  XGetFileChecksum := XGetStreamChecksum(T,T.GetSize);
  T.Done;
end;

procedure XAppInit;
var
  d:DirStr;
  n:NameStr;
  e:ExtStr;
begin
  writeln(Name+' Version '+version+' - (c) 1997 '+c);
  writeln;
  FSplit(FExpand(ParamStr(0)),D,N,E);
  if ParamCount < MinParamCount then begin
    writeln('Usage : '+N+' '+Usage);
    halt(1);
  end;
end;

function XAddExt;
begin
  if pos('.',s) = 0 then s := s + ext;
  XAddExt := s;
end;

procedure XAbort;   {halts program with given message}
begin
  writeln(Msg);
  halt(1);
end;

function ReplaceExt;
var
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;
begin
  FSplit(FileName, Dir, Name, Ext);
  ReplaceExt := Dir + Name + NExt;
end;

procedure XDeleteWild(AFileSpec:FNameStr);
var
  DirInfo:SearchRec;
  f:file;
  Dir:DirStr;
  Name:NameStr;
  Ext:ExtStr;
begin
  FSplit(AFileSpec,Dir,Name,Ext);
  FindFirst(AFileSpec,Archive,DirInfo);
  if DosError <> 0 then exit;
  repeat
    Assign(f,Dir+DirInfo.Name);
    Erase(f);
    FindNext(DirInfo);
  until DosError <> 0;
end;

function DriveValid(Drive: Char): Boolean; assembler;
asm
	MOV	DL,Drive
        MOV	AH,36H
        SUB	DL,'A'-1
        INT	21H
        INC	AX
        JE	@@2
@@1:	MOV	AL,1
@@2:
end;

function PathValid(var Path: FNameStr): Boolean;
var
  ExpPath: FNameStr;
  F: File;
  SR: SearchRec;
begin
  ExpPath := FExpand(Path);
  if Length(ExpPath) <= 3 then PathValid := DriveValid(ExpPath[1])
  else
  begin
    if ExpPath[Length(ExpPath)] = '\' then Dec(ExpPath[0]);
    FindFirst(ExpPath, Directory, SR);
    PathValid := (DosError = 0) and (SR.Attr and Directory <> 0);
  end;
end;

function ValidFileName(var FileName: FNameStr): Boolean;
const
  IllegalChars = ';,=+<>|"[] \';
var
  Dir: DirStr;
  Name: NameStr;
  Ext: ExtStr;

{ Contains returns true if S1 contains any characters in S2 }
function Contains(S1, S2: String): Boolean; assembler;
asm
	PUSH	DS
        CLD
        LDS	SI,S1
        LES	DI,S2
        MOV	DX,DI
        XOR	AH,AH
        LODSB
        MOV	BX,AX
        OR      BX,BX
        JZ      @@2
        MOV	AL,ES:[DI]
        XCHG	AX,CX
@@1:	PUSH	CX
	MOV	DI,DX
	LODSB
        REPNE	SCASB
        POP	CX
        JE	@@3
	DEC	BX
        JNZ	@@1
@@2:	XOR	AL,AL
	JMP	@@4
@@3:	MOV	AL,1
@@4:	POP	DS
end;

begin
  ValidFileName := True;
  FSplit(FileName, Dir, Name, Ext);
  if not ((Dir = '') or PathValid(Dir)) or Contains(Name, IllegalChars) or
    Contains(Dir, IllegalChars) then ValidFileName := False;
end;

function GetCurDir: DirStr;
var
  CurDir: DirStr;
begin
  GetDir(0, CurDir);
  if Length(CurDir) > 3 then begin
    Inc(CurDir[0]);
    CurDir[Length(CurDir)] := '\';
  end;
  GetCurDir := CurDir;
end;
 
function IsWild(var S: String): Boolean;
begin
  IsWild := (Pos('?',S) > 0) or (Pos('*',S) > 0);
end;

function IsDir(var S: String): Boolean;
var
  SR: SearchRec;
begin
  FindFirst(S, Directory, SR);
  if DosError = 0 then
    IsDir := SR.Attr and Directory <> 0
  else IsDir := False;
end;

function XFilesExist(s:FnameStr):boolean;     {multiple files search}
var
  dirinfo:SearchRec;
begin
  FindFirst(s,ReadOnly+Archive+Hidden+SysFile,dirinfo);
  XFilesExist := DosError = 0;
end;

function XFileExists(s:FNameStr):boolean;
var
  F:File;
  Attr:word;
begin
  Assign(F,s);
  GetFAttr(F,attr);
  XFileExists := (DosError = 0) and (Attr and (Directory+VolumeId) = 0);
end;

function  XGetDirName(AFile:FNameStr):DirStr;
var
  d:dirstr;
  n:namestr;
  e:extstr;
begin
  FSplit(FExpand(AFile),d,n,e);
  XGetDirName := d;
end;

function  XGetFileName(AFile:FNameStr):FnameStr;
var
  d:dirstr;
  n:namestr;
  e:extstr;
begin
  FSplit(FExpand(AFile),d,n,e);
  XGetFileName := n+e;
end;

function XDeleteAnyWay(AFile:FnameStr):boolean;
var
  f:File;
begin
  Assign(F,AFile);
  SetFAttr(F,0);
  Erase(F);
  XDeleteAnyway := IOResult = 0;
end;

function XDeleteFile(AFile:FNameStr):boolean;
var
  f:file;
begin
  Assign(f,AFile);
  Erase(f);
  XDeleteFile := IOResult = 0;
end;

function XRenameFile;assembler;
asm
  push  ds
  lds   si,oldname
  les   di,newname
  xor   ah,ah
  mov   al,es:[di]
  add   di,ax
  inc   di
  mov   bl,es:[di]
  mov   byte ptr es:[di],0
  sub   di,ax
  mov   al,ds:[si]
  add   si,ax
  inc   si
  mov   bh,ds:[si]
  mov   byte ptr ds:[si],0
  sub   si,ax
  mov   ax,5600h
  mov   dx,si
  int   21h
  jc    @Error
  mov   al,1
  jmp   @Exit
@Error:
  xor   al,al
@Exit:
  push  ax
  dec   si
  dec   di
  mov   al,ds:[si]
  xor   ah,ah
  add   si,ax
  inc   si
  mov   byte ptr ds:[si],bh
  mov   al,es:[di]
  add   di,ax
  inc   di
  mov   byte ptr es:[di],bl
  pop   ax
  pop   ds
end;

procedure XSetFileAttr(AFile:FNameStr;Attr:Word);
var
  f:file;
begin
  Assign(f,AFile);
  SetFAttr(f,Attr);
end;

function XPatch(var s:TStream; offset:longint; aorg,apatch:string):word;
var
  buf:string;
begin
  if length(aorg) <> length(apatch) then begin
    XPatch := xprParamError;
    exit;
  end;
  s.Seek(offset);
  buf[0] := aorg[0];
  s.Read(buf[1],length(buf));
  s.Seek(offset);
  if s.Status <> stoK then begin
    XPatch := xprPatchError;
    exit;
  end;
  if buf = apatch then begin
    XPatch := xprAlreadyPatched;
    exit;
  end;
  if buf <> aorg then begin
    XPatch := xprInvalidFile;
    exit;
  end;
  s.Write(apatch[1],length(apatch));
  if s.Status <> stoK then begin
    XPatch := xprPatchError;
    exit;
  end;
  XPatch := xprOK;
end;

function XGetFileExt;
var
  dir:dirstr;
  name:namestr;
  ext:extstr;
begin
  FSplit(Afile,dir,name,ext);
  XGetFileExt := ext;
end;

procedure XSetRedirection(afile:FnameStr);
begin
  afile := afile + #0;
  asm
    push  ds
    mov   ax, ss
    mov   ds, ax
    lea   dx, afile[1]
    mov   ah, 3Ch
    int   21h
    pop   ds
    jnc   @@1
    ret
@@1:
    push  ax
    mov   bx, ax
    mov   cx, Output.FileRec.Handle
    mov   ah, 46h
    int   21h
    mov   ah, 3Eh
    pop   bx
    jnc   @@2
    ret
@@2:
    int   21h
  end;
end;

function XGetTempDir:FnameStr;
var
  f:FnameStr;
begin
  f := GetEnv('TEMP');
  if f <> '' then XMakeDirStr(f,true);
  XGetTempDir := f;
end;

end.
