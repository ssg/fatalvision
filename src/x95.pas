{
Name    : X/95 1.00c
Purpose : Windows 95 interface
Coder   : SSG
Date    : 13th Jun 96
Time    : 20:46

updates:
--------
13th Jun 96 - 21:19 - finished...
13th Jun 96 - 21:37 - made interface easier to use...
13th Jun 96 - 22:18 - fully tested... no bugs...
18th Jun 96 - 18:19 - added getvolinfo... (doesn't work)
23rd Aug 96 - 00:33 - added file functions...
26th Sep 97 - 15:38 - getdir doesn't work... trying to fix it...
28th Sep 97 - 12:20 - fixed getdir bug...
28th Sep 97 - 12:40 - bugfixes in dir routines...
29th Sep 97 - 21:19 - fixed a bug in getdir...
}

unit X95;

interface

const

  X95Support : boolean = false;

  faReadOnly      = $01;
  faHidden        = $02;
  faSysFile       = $04;
  faVolumeID      = $08;
  faDirectory     = $10;
  faArchive       = $20;
  faTemporary     = $80;
  faAnyFile       = faReadOnly or faHidden or faSysFile or faArchive or faTemporary;

  fsCaseSensitive  = 1;
  fsPreservesCase  = 2;
  fsSupUnicode     = 4;
  fsSupLongName    = $4000;
  fsCompressed     = $8000;

  ffAutoCommit     = $40;
  ffNoCrit         = $20;

  foRead           = 0;
  foWrite          = 1;
  foRW             = 2;
  foDenyAll        = $10;
  foDenyWrite      = $20;
  foDenyRead       = $30;
  foDenyNone       = $40;
  foNoInherit      = $80;

type

  T95Time = record
    Lo,Hi : longint;
  end;

  TFindRec = record
    Attr      : longint;
    cTime     : T95Time;
    aTime     : T95Time;
    mTime     : T95Time;
    Size      : longint;
    FullName  : string;
    ShortName : string[13];
    Handle    : word;
  end;

  TVolInfo = record
    FSName     : string[32];
    Flags      : word;
    MaxNameLen : word;
    MaxPathLen : word;
  end;

function  X95FindFirst(path:string; attr:word; var rec:TFindRec):boolean;
function  X95FindNext(var rec:TFindRec):boolean;
procedure X95FindClose(var rec:TFindRec);

function X95MkDir(const s:string):boolean;
function X95RmDir(const s:string):boolean;
function X95ChDir(const s:string):boolean;
function  X95GetDir(drive:byte; var s:string):boolean;

function  X95Delete(s:string):boolean;
function  X95GetAttr(s:string):word;
function  X95Rename(const src,dst:string):boolean;
function  X95Open(const filename:string;
                  openmode,attr:byte;
                  autocommit,nocrit,createifnotexist,createifexist:boolean;
                  var handle:word):boolean;
function X95SetAttr(s:string; attr:byte):boolean;

procedure X95GetVolInfo(const rootpath:string; var rec:TVolInfo);

function  X95FiletimeToDosTime(var T:T95Time):longint;
procedure X95DosTimetoFiletime(l:longint; var T:T95Time);

implementation

uses

  Strings;

procedure X95DosTimeToFiletime;assembler;
asm
  mov  ax,71a7h
  mov  bl,01
  mov  cx,word ptr l
  mov  dx,word ptr l+2
  xor  bh,bh
  les  di,T
  int  21h
end;

function X95FiletimeToDostime;assembler;
asm
  push ds
  mov  ax,71a7h
  xor  bl,bl
  lds  si,T
  int  21h
  mov  ax,cx
  pop  ds
end;

procedure toasciiz;assembler; {ds:dx ptr}
asm
  push  si
  push  bx
  mov   si,dx
  mov   bl,[si]
  xor   bh,bh
  inc   si
  mov   byte ptr [si+bx],0
  mov   dx,si
  pop   bx
  pop   si
end;

procedure StdInt21;assembler;
asm
  int  21h
  mov  al,0
  jb   @end
  inc  al
@end:
end;

function X95Open;assembler;
asm
  cld
  push  ds
  mov   bl,openmode
  mov   bh,autocommit
  shl   bh,1
  or    bh,nocrit
  shl   bh,5
  lds   dx,filename
  call  toasciiz
  mov   si,dx
  mov   ax,716ch
  xor   ch,ch
  mov   cl,attr
  xor   dh,dh
  mov   cl,createifnotexist
  shl   cl,4
  or    cl,createifexist
  int   21h
  mov   bl,0
  jb    @skip
  inc   bl
@skip:
  pop   ds
  les   di,handle
  stosw
  mov   al,bl
end;

function X95Rename;assembler;
asm
  cld
  push  ds
  lds   dx,dst
  mov   di,dx
  mov   ax,ds
  mov   es,ax
  call  toasciiz
  pop   ds
  push  ds
  lds   dx,src
  call  toasciiz
  mov   ax,7156h
  call  stdint21
  pop   ds
end;

function X95GetDir;assembler;
asm
  push ds
  mov  ax,7147h
  mov  dl,drive
  lds  si,s
  mov  byte ptr [si],0
  inc  si
  mov  di,si
  add  si,3
  int  21h
  mov  bl,0
  jc   @skik
  inc  bl
@skik:
  sub  si,3
  or   dl,dl
  jne  @skip
  mov  ah,19h
  int  21h
  inc  al
  mov  dl,al
@skip:
  add  dl,40h
  mov  [si],dl
  inc  si
  mov  word ptr [si],5c3ah {':\'}
  inc  si
  inc  si
  xor  al,al
  mov  cx,0ffh
  cld
  mov  dx,ds
  mov  es,dx
  repne scasb
  mov  al,0feh
  sub  al,cl
  sub  si,4
  mov  [si],al
  mov  al,bl
  pop  ds
end;

function X95GetAttr;assembler;
asm
  cld
  push ds
  push ss
  pop  ds
  lea  dx,s
  call toasciiz
  mov  ax,7143h
  xor  bl,bl
  int  21h
  mov  ax,cx
  pop  ds
end;

function X95SetAttr;assembler;
asm
  cld
  mov  cl,attr
  xor  ch,ch
  push ds
  push ss
  pop  ds
  lea  dx,s
  call toasciiz
  mov  ax,7143h
  mov  bl,1
  call stdint21
  pop  ds
end;

function X95Delete;assembler;
asm
  cld
  push ds
  push ss
  pop  ds
  lea  dx,s
  call toasciiz
  mov  ax,7141h
  call stdint21
  pop  ds
end;

function X95ChDir;assembler;
asm
  cld
  push ds
  lds  dx,s
  call toasciiz
  mov  ax,713bh
  call stdint21
  pop  ds
end;

function X95RmDir;assembler;
asm
  cld
  push ds
  lds  dx,s
  call toasciiz
  mov  ax,713ah
  call stdint21
  pop  ds
end;

function X95MkDir;assembler;
asm
  cld
  push ds
  lds  dx,s
  call toasciiz
  mov  ax,7139h
  call stdint21
  pop  ds
end;

procedure X95GetVolInfo(const rootpath:string; var rec:TVolInfo);assembler;
var
  hebe:array[1..255] of char;
asm
  cld
  push ds
  mov  ax,ss
  mov  es,ax
  lea  di,hebe
  lds  si,rootpath
  lodsb
  xor  ch,ch
  mov  cl,al
  rep  movsb
  xor  al,al
  stosb
  pop  ds
  push ds
  les  di,rec
  mov  ax,ss
  mov  ds,ax
  lea  si,hebe
  inc  di
  mov  cx,32
  mov  ax,71a0h
  int  21h
  pop  ds
  jc   @skip
  push cx
  mov  si,di
  dec  si
  mov  cx,32
  xor  al,al
  repne scasb
  sub  di,si
  xchg di,si
  mov  ax,si
  mov  es:[di],al
  pop  cx
  mov  es:[di].TVolInfo.Flags,bx
  mov  es:[di].TVolInfo.MaxNameLen,cx
  mov  es:[di].TVolInfo.MaxPathLen,dx
@skip:
end;

type

  TFindData = record
    Attr         : longint;
    cTime        : T95Time;
    aTime        : T95Time;
    mTime        : T95Time;
    HiSize       : longint;
    LoSize       : longint;
    Reserved     : array[1..8] of byte;
    FullName     : array[1..260] of char;
    ShortName    : array[1..14] of char;
  end;

var

  temp:array[1..256] of char;

procedure X95FindClose;assembler;
asm
  les  di,rec
  mov  bx,es:[di].TFindRec.Handle
  mov  ax,71a1h
  int  21h
end;

procedure Data2Rec(var src:TFindData; var dst:TFindRec);
begin
  with dst do begin
    Attr := src.Attr;
    cTime := src.cTime;
    aTime := src.aTime;
    mTime := src.mTime;
    Size  := src.loSize;
    FullName := StrPas(@src.FullName);
    ShortName := StrPas(@src.ShortName);
  end;
end;

function SubFindNext(var rec:TFindData; handle:word):boolean;assembler;
asm
  les  di,rec
  mov  bx,handle
  mov  ax,714fh
  xor  si,si
  int  21h
  mov  ax,0
  jb   @fail
  inc  ax
@fail:
end;

function SubFindFirst(const path:string; attr:word; var rec:TFindData; var handle:word):boolean;assembler;
asm
  push ds
  push ds
  pop  es
  mov  ax,ds
  mov  es,ax
  lea  di,temp
  lds  si,path
  xor  ch,ch
  mov  cl,[si]
  inc  si
  cld
  rep  movsb
  xor  al,al
  stosb
  mov  ax,es
  mov  dx,offset temp
  pop  ds
  les  di,rec
  mov  cx,attr
  push ds
  mov  ds,ax
  mov  ax,714eh
  xor  si,si
  int  21h
  pop  ds
  les  di,handle
  mov  bx,0
  jc   @fail
  inc  bx
  mov  es:[di],ax
@fail:
  mov  ax,bx
end;

function X95FindFirst(path:string; attr:word; var rec:TFindRec):boolean;
var
  data:TFindData;
  b:boolean;
  handle:word;
begin
  b := SubFindFirst(path,attr,data,handle);
  if b then begin
    Data2Rec(data,rec);
    rec.Handle := handle;
  end;
  X95FindFirst := b;
end;

function X95FindNext(var rec:TFindRec):boolean;
var
  data:TFindData;
  b:boolean;
begin
  b := SubFindNext(data,rec.Handle);
  if b then Data2Rec(data,rec);
  X95FindNext := b;
end;

function X95Supported:boolean;assembler;
asm
  jmp  @init
@hebe:
  db   'hebe',0
@init:
  push ds
  xor  bl,bl
  mov  ax,7143h
  push cs
  pop  ds
  lea  dx,@hebe
  int  21h
  cmp  ax,7100h
  jne  @skip
  xor  al,al
  jmp  @end
@skip:
  mov  al,1
@end:
  pop  ds
end;

begin
  X95Support := X95Supported;
end.