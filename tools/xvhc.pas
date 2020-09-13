{
Name            : XVHC 2.04a
Purpose         : Help compiler
Coder           : SSG

Updates:
--------
15th Aug 94 - 22:26 - Optimized code...
23rd Nov 94 - 00:01 - Added AXE support and fixed some bugs...
23rd Nov 94 - 00:06 - Fixed some bugs...
26th Nov 94 - 18:06 - Converted to new single file system...
26th Nov 94 - 18:28 - Added extended note support...
26th Nov 94 - 18:40 - Fixed a bug...
26th Nov 94 - 19:51 - Fixed bugs again...
 9th Mar 96 - 17:25 - Removed GUI support...
13th Mar 96 - 17:47 - removed percent olayi...
30th May 96 - 03:33 - Changed file format...
 5th Jan 97 - 14:57 - changed id assignment method...
}

{$I-}

uses

XTypes,AXEServ,XHelp,XStream,XStr,Objects,Dos,XBuf,XIO;

const

  Rsc         = 'Rid_';
  Hc          = 'hc';

  AppName      : string[19] = 'XGH / Help compiler';
  xvhc_Version : string[5] = '2.04a';

  errVarInBlock  : string[35] = 'Cannot define a variable in a block';
  errRecurBlocks : string[15] = '".END" expected';
  errUnknownCmd  : string[19] = 'Unknown dot command';
  errCannotid    : string[33] = 'Failed to identify the object';
  errMissingVar  : string[21] = 'Variable name missing';
  errTooManyObj  : string[16] = 'Too many objects';
  errIllegalCmd  : string[30] = 'Illegal use of dot command';

  PrefixArray : array[1..5] of string[4]
    = (hc,hc,Rsc,Rsc,Rsc);

  DestPath : PathStr = '';

  msgTestComplete : string[13] = 'Test complete';

  bnImage : string[5] = 'IMAGE';
  bnSound : string[5] = 'SOUND';
  bnTopic : string[5] = 'TOPIC';
  bnTitle : string[5] = 'TITLE';
  bnFont  : string[4] = 'FONT';
  bnNote  : string[4] = 'NOTE';

type

  PHelpObj = ^THelpObj;
  THelpObj = record
    ObjType : byte;
    Id      : word;
    ObjName : PString;
    SrcPos  : longint;
  end;

  PObjCollection = ^TObjCollection;
  TObjCollection = object(TCollection)
    procedure      FreeItem(Item:Pointer);virtual;
  end;

var

  f          : PathStr;
  d          : dirstr;
  trimeattre : dirstr;
  n          : namestr;
  e          : extstr;
  idx        : integer;
  Source     : TBufStream;
  Resource   : Pointer;
  Auto       : boolean;
  HIP        : TCodedStream;
  ObjList    : PObjCollection;
  index      : PCollection;

procedure Shutdown;
begin
  halt;
end;

procedure Wri(s:string);
begin
  writeln(s);
end;

procedure GlobalError(s:string);
begin
  wri(#7+s);
  Shutdown;
end;

procedure WritePerc(cur,max:longint);
begin
{  XWritePerc(cur,max);}
end;

procedure StartJob(s:string);
begin
  write(s);
end;

procedure StripSpaces(var s:string);
begin
  while (s[1] = #32) and (length(s) > 0) do Delete(s,1,1);
  while (s[length(s)] = #32) and (length(s) > 0) do dec(byte(s[0]));
end;

procedure Done;
begin
  Wri('done.');
end;

procedure TObjCollection.FreeItem;
begin
  if Item <> NIL then Dispose(PHelpObj(Item));
end;

procedure Error(lineno:word;msg:string);
begin
  msg := l2s(lineno)+': '+msg;
  GlobalError(msg);
end;

function InList(id:word):boolean;
var
  n:integer;
  il:boolean;
begin
  il := false;
  for n:=0 to ObjList^.Count-1 do
    il := il or (PHelpObj(ObjList^.At(n))^.Id = id);
  InList := il;
end;

function GetId(P:PHelpObj; s:string):word;
var
  b:byte;
  id:word;
begin
  b := pos('=',s);
  if b = 0 then begin
    if P^.ObjType = hoTopic then begin
      id := 0;
      while InList(id) do inc(id);
    end else begin
      id := $FFFE;
      while InList(id) do dec(id);
    end;
    GetId := id;
  end else begin
    s := copy(s,b+1,255);
    StripSpaces(s);
    GetId := s2l(s);
  end;
end;

function GetName(s:string):PString;
var
  p:byte;
  p2:byte;
  PS:PString;
begin
  p := pos(' ',s);
  GetName := NIL;
  if p = 0 then exit;
  p2 := pos('=',s);
  if p2 = 0 then p2 := length(s)+1;
  if (p2 < p+2) then exit;
  s := copy(s,p+1,p2-p-1);
  StripSpaces(s);
  if s = '' then exit;
  PS := NewStr(s);
  FastUpper(PS^);
  GetName := PS;
end;

function Block(s:string):string;
var
  p:byte;
begin
  Block := '';
  if s[1] <> '.' then exit;
  FastUpper(s);
  p := Pos(' ',s);
  if p = 0 then Block := copy(s,2,255) else
  Block := copy(s,2,p-2);
end;

procedure CreateSymbols(fname:pathstr);
var
  T:TBufStream;
  n:integer;
  P:PHelpObj;
  s:string;
begin
  T.Init(ReplaceExt(fname,'.PAS'),stCreate,2048);
  SWriteln(T,'{ Help Contexts - (c) 1994 SSG }');
  SWriteln(T,'');
  SWriteln(T,'unit '+ReplaceExt(XGetFileName(fname),'')+';');
  SWriteln(T,'');
  SWriteln(T,'interface');
  SWriteln(T,'');
  SWriteln(T,'const');
  SWriteln(T,'');
  for n:=0 to ObjList^.Count-1 do begin
    WritePerc(n,ObjList^.Count-1);
    P := ObjList^.At(n);
    if P^.ObjType <> hoNote then begin
      s := '  '+PrefixArray[P^.ObjType];
      if s = '  hc' then if XIsParam('NH') > 0 then continue;
      if s = '  Rid_' then if XIsParam('NR') > 0 then continue;
      s := s + P^.ObjName^;
      Fix(s,30);
      s := s + '= '+l2s(P^.Id)+';';
      SWriteln(T,s);
    end;
  end;
  SWriteln(T,'');
  SWriteln(T,'implementation');
  SWriteln(T,'');
  SWriteln(T,'end.');
end;

function GetRscId(var f:FNameStr):word;
var
  P:PROB;
  T:TROB;
  ty,id:word;
begin
  GetRscId := $FFFF;
  if AXEOK then with AXEServ.PResource(Resource)^ do begin
    T.Name := f;
    P := GetROB(T,rshName);
    if P = NIL then exit;
    GetRscId := P^.Id;
  end;
end;

procedure ReadObjects;
var
  s:string;
  inblock:boolean;
  P:PHelpObj;
  lineno:word;
  bls:string;
  rt:(Unknown,Line,Blocked);
  err:FNameStr;
  obj:boolean;
  procedure LineErr(errmsg:string);
  begin
    Error(LineNo,errmsg);
  end;
begin
  Source.Seek(0);
  inblock := false;
  lineno  := 0;
  while source.Status = stOK do begin
    SReadln(Source,s);
    inc(lineno);
    if s[1] = '.' then begin
      WritePerc(Source.GetPos,Source.GetSize);
      bls := Block(s);
      if bls = 'END' then begin
        case inblock of
          True:  inblock :=false;
          false: LineErr('Unexpected ".END"');
        end; {casE}
        continue;
      end;
      New(P);
      FillChar(P^,SizeOf(THelpObj),0);
      rt  := Unknown;
      err := '';
      obj := true;
      if bls = bnImage then begin
        if InBlock then LineErr(errVarInBlock);
        P^.ObjType := hoImage;
        rt         := Line;
      end else
      if bls = bnSound then begin
        if InBlock then LineErr(errVarInBlock);
        P^.ObjType := hoSound;
        rt         := Line;
      end else
      if bls = bnFont then begin
        if InBlock then LineErr(errVarInBlock);
        P^.ObjType := hoFont;
        rt         := Line;
      end else
      if bls = bnNote then begin
        if InBlock then LineErr(errRecurBlocks);
        P^.ObjType := hoNote;
        inBlock    := True;
        rt         := blocked;
        obj        := false;
      end else
      if bls = bnTopic then begin
        if InBlock then LineErr(errRecurBlocks);
        P^.ObjType := hoTopic;
        inBlock    := True;
        rt         := blocked;
        obj        := false;
      end else
      if bls = bnTitle then begin
        if not InBlock then LineErr(errIllegalCmd);
        continue;
      end else LineErr(errUnknownCmd);
      if rt = blocked then P^.SrcPos  := Source.GetPos;
      P^.ObjName := GetName(s);
      if not obj then P^.Id := GetId(P,s)
                 else P^.Id := GetRscId(P^.ObjName^);
      if P^.Id = $FFFF then LineErr(errCannotId);
      if P^.ObjName = NIL then LineErr(errMissingVar);
      ObjList^.Insert(P);
      if ObjList^.Count = MaxObjects then LineErr(errToomanyobj);
    end;
  end;
  Source.Reset;
end;

procedure WriteIndex(id:word);
var
  Idx:longint;
begin
  Idx := HIP.GetPos;
  index^.Insert(Pointer(idx));
end;

procedure WriteNote(P:PHelpObj);
var
  s:string;
begin
  Source.Seek(P^.SrcPos);
  SReadLn(Source,s);
  if s[1] = '.' then
    if Block(s) = bnTitle then begin
      s := copy(s,pos(' ',s)+1,255);
      HIP.Write(s,length(s)+1);
      SReadln(Source,s);
    end else GlobalError('Invalid dot command in note '+P^.ObjName^)
  else HIP.Write(P^.ObjName^,Length(P^.ObjName^)+1);
  while Block(s) <> 'END' do begin
    StripSpaces(s);
    s := s + ' ';
    HIP.Write(s[1],length(s));
    SReadLn(Source,s);
  end;
end;

{function GetSubType(var s:string):byte;
begin
  GetSubType := sbWrapped;
  if s = '' then GetSubType := sbnewLine;
  if s[1] = #32 then GetSubType := sbText;
end;}

function GetVariable(name:string):PHelpObj;
var
  n:integer;
  P:PHelpObj;
begin
  FastUpper(name);
  for n:=0 to ObjList^.Count-1 do begin
    P := ObjList^.At(n);
    if P^.ObjName^ = name then begin
      GetVariable := P;
      exit;
    end;
  end;
  GetVariable := NIL;
end;

function GetHyperId(s:string):string;
var
  P:PHelpObj;
begin
  GetHyperId := '';
  FastUpper(s);
  P := GetVariable(s);
  if P = NIL then GlobalError('{'+s+'}:Hyperlink not found in topic');
  GetHyperId := char(P^.ObjType)+char(Lo(P^.Id))+char(Hi(P^.Id));
end;

function GetHyperLink(s:string):string;
var
  b         : byte;
  P         : PHelpObj;
  hyperlink : string;
begin
  GetHyperLink := '';
  if s[length(s)] = '}' then dec(byte(s[0]));
  if s[1] = '{' then Delete(s,1,1);
  if s='' then exit;
  b := Pos(':',s);
  if b = 0 then begin
    hyperlink := s;
    P         := GetVariable(hyperlink);
    if P = NIL then GlobalError('{'+hyperlink+'}:Single hyperlink not found');
    if (P^.ObjType = hoTopic) or (P^.ObjType = hoNote) then
    s         := hyperlink else s := '';
  end else begin
    hyperlink := copy(s,b+1,255);
    s         := copy(s,1,b-1);
  end;
  GetHyperLink := WildChar+GetHyperId(hyperlink)+char(length(s))+s;
end;

procedure WriteData(s:String);
var
  b:byte;
  b2:byte;
  parse:string;
  procedure WrIteC(c:char);
  begin
    HIP.Write(c,SizeOf(c));
  end;
begin
  if s = '' then begin
    WriteC(#10);
    exit;
  end;
  while (s[length(s)] = ' ') and (length(s) > 0) do dec(byte(s[0]));
  b := pos('{',s);
  while b > 0 do begin
    b2 := pos('}',copy(s,b+1,255));
    if b2 = 0 then GlobalError('} missing');
    parse := GetHyperLink(copy(s,b,b2));
    Delete(s,b,b2+1);
    Insert(parse,s,b);
    b := pos('{',s);
  end;
  if s[1] = #32 then begin
    Insert(#27,s,1);
    s := s + #13;
  end else s := s + #32;
  HIP.Write(s[1],length(s));
end;

procedure WriteTopic(P:PHelpObj);
var
  s:string;
begin
  Source.Seek(P^.SrcPos);
  SReadln(Source,s);
  while (Block(s) <> 'END') and (Source.GetPos < Source.GetSize) do begin
    WriteData(s);
    SReadln(Source,s);
  end;
  if Block(s) <> 'END' then GlobalError('END missing at EOF');
end;

function IsBlocked(ot:byte):boolean;
begin
  IsBlocked := (ot = hoTopic) or (ot = hoNote);
end;

procedure FlushIndex;
begin
  HIP.Seek(HIP.GetSize);
  HIP.Write(index^.Items^[0],index^.Count*sizeof(pointer));
end;

procedure Compile;
var
  HIPHdr:THIPHdr;
  n:integer;
  P:PHelpObj;
  T:TObjHdr;
  sizeoffset:longint;
  procedure WriteSize;
  begin
    T.Size := HIP.GetPos-(SizeOffset+SizeOf(TObjHdr));
    HIP.Seek(SizeOffset);
    HIP.Write(T,SizeOf(T));
    HIP.Seek(HIP.GetSize);
  end;
begin
  Source.Seek(0);
  HIP.Seek(SizeOf(THIPHdr));
  for n:=0 to ObjList^.Count-1 do begin
    WritePerc(n,ObjList^.Count-1); {writing perc}
    P := ObjList^.At(n);
    if IsBlocked(P^.ObjType) then begin
      WriteIndex(P^.Id);                       {writing index}
      sizeoffset := HIP.GetPos;
      T.ObjType  := P^.ObjType;
      T.Id       := P^.Id;
      T.Size     := 0;
      HIP.Write(T,SizeOf(T));                  {writing object header}
      case T.ObjType of
        hoTopic : begin
                    WriteTopic(P);
                    WriteSize;
                  end;
        hoNote  : begin
                    WriteNote(P);
                    WriteSize;
                  end;
        else GlobalError('Unknown object type : '+P^.ObjName^);
      end;
    end;
  end;
  HIPHdr.IndexOffs := HIP.GetPos;
  Move(HIPSign,HIPHdr.Sign,SizeOf(TId));
  HIP.Seek(0);
  HIP.Write(HIPHdr,SizeOf(HIPHdr));
  FlushIndex;
end;

procedure InitApp;
begin
  XAppInit(AppName,xvhc_Version,'SSG',0,'');
  if (ParamCount=0) or (XIsParam('?') > 0) then begin
    Wri('Usage : XVHC helptext[.TXT] [options]'#13#10);
    Wri(' /?         This help screen');
    Wri(' /t         Test. Do not compile. Only test help text');
    Wri(' /ns        Do not create symbol file');
    Wri(' /nr        Do not put resource id''s in symbol file');
    Wri(' /nh        Do not put help contexts in symbol file');
    Wri(' /o:path    Output path for help files');
    Wri(' /s:path    PathName for symbol file');
    Wri(' /a:rif     Automatically assign resource id''s');
    halt(1);
  end;
end;

procedure InitResource;
var
  T:TBufStream;
  id:longint;
  w:word;
begin
  idx := XIsParam('A');
  Auto := idx > 0;
  if Auto then begin
    f := XGetParamStr(idx);
    if not XFileExists(f) then GlobalError('RIF not found');
    T.Init(f,stOpenRead,2048);
    T.Read(id,4);
    T.Done;
    AXEOK := false;
    if BufCmp(id,AXEServ.ResourceID,4) then begin
      AXEOK := true;
      Resource := New(AXEServ.PResource,Init(f,stOpenRead));
    end else GlobalError('Invalid resource format');
  end;
end;

procedure OpenSource;
begin
  f := ParamStr(1);
  if pos('.',f) = 0 then f := f+'.TXT';
  Source.Init(f,stOpenRead,2048);
  if Source.Status <> stOK then GlobalError('Cannot open source file');
end;

procedure InitParams;
begin
  d := '';
  if XIsParam('O') > 0 then begin
    d := XGetParamStr(XIsParam('O'));
    if d[length(d)] <> '\' then begin
      Inc(byte(d[0]));
      d[length(d)] := '\';
    end;
  end;
end;

begin
  InitApp;
  InitResource;
  InitParams;
  OpenSource;
  StartJob('Reading objects...');
  New(ObjList,init(10,10));
  ReadObjects;
  done;
  FSplit(f,trimeattre,n,e);
  f := d+n+e;
  if XIsParam('T') > 0 then XAbort(msgTestComplete);
  if ObjList^.Count < 1 then GlobalError('No object(s) - compiling is meaningless');
  StartJob('Compiling...');
  New(index,Init(5,5));
  HIP.Init(ReplaceExt(f,hlpExt),stCreate);
  if HIP.Status <> stOK then GlobalError('Cannot create output');
  Compile;
  HIP.Done;
  done;
  if XIsParam('NC') = 0 then begin
    StartJob('Creating symbol file...');
    if XIsParam('S') > 0 then trimeattre := XGetParamStr(XIsParam('S'))
                         else trimeattre := ReplaceExt(f,'.PAS');
    CreateSymbols(trimeattre);
    done;
  end;
  Shutdown;
end.
