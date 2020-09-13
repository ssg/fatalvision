{
Name            : AXE 1.07f
Purpose         : Extended resource management system
Coder           : SSG

Update info:
------------
19th Jul 94 - 01:21 - Enhancing...
19th Jul 94 - 03:42 - Fixed some bugs... no no... re-thinking about them...
19th Jul 94 - 05:16 - Rewritten the rebuild logic...
19th Jul 94 - 05:42 - Fixing bugs...
22nd Jul 94 - 14:38 - Testing file rebuild function...
22nd Jul 94 - 19:02 - Bug #1: Extraction gives "read failed"...
22nd Jul 94 - 19:05 - Bug #1: fixed...
22nd Jul 94 - 21:53 - Added specific listing option...
22nd Jul 94 - 21:57 - Removed default listing support for parametric
                      listing feature...
23rd Jul 94 - 17:08 - Added resource testing feature...
24th Jul 94 - 03:07 - Working on compression...
24th Jul 94 - 04:50 - At last finished this compression feature...
                      (I'm not sure but it's working)
26th Jul 94 - 14:53 - Fixed a bug in VIF extraction...
26th Jul 94 - 17:08 - Added resource repair facility...
28th Jul 94 - 17:39 - Fixed BMP extraction bug...
 4th Nov 94 - 00:22 - Recompiled for last changes...
 5th Nov 94 - 03:06 - Added rename function...
15th Nov 94 - 00:56 - Fixed some bugs...
22nd Nov 94 - 23:25 - Added VOC support...
18th Apr 95 - 02:39 - Retouched to support EXEs...
29th Jun 96 - 00:08 - Removed compression support...
29th Jun 96 - 00:14 - Removed conversion support...
 2rd Jul 96 - 01:34 - Added palette type...
}

uses

XGfx,XStream,Loaders,Dos,XStr,Objects,XIO,XTypes,XBuf,AXEServ;

const

  xVersion = '1.07f';

function ValidRH(var H:TRIFHeader):boolean;
begin
  ValidRH := BufCmp(H.Id,ResourceId,SizeOf(Tid));
end;

procedure failed;
begin
  XAbort('failed');
end;

procedure ok;
begin
  writeln('ok  ');
end;

procedure incorrectParams;
begin
  XAbort('incorrect number of parameters');
end;

procedure Usage;
const
  right:boolean=false;
  procedure puthelp(c:char; msg:string);
  begin
    write(Fix(c+'  '+msg,36));
    if right then writeln;
    right := not right;
  end;
begin
  writeln('Usage : AXE <command> <rscname[.RIF]> [object] [options]');
  writeln;
  writeln('Commands:');
  writeln;
  puthelp('a','Add object to resource');
  puthelp('b','Add items from list file');
  puthelp('d','Delete object from resource');
  puthelp('e','Extract object to disk');
  puthelp('h','Help on a specific command');
  puthelp('i','Display object info');
  puthelp('l','List resource contents');
  puthelp('n','Rename resource object');
  puthelp('p','Repair broken resource');
  puthelp('r','Rebuild resource');
  puthelp('t','Test resource integrity');
  puthelp('u','Undelete resource object');
  puthelp('x','Replace resource item (n/a)');
  if right then writeln;
  writeln(#13#10'Options:'#13#10);
  writeln('/?  Display this help screen        /p  Pause at each screenful');
  writeln('/n  Specify resource name           /i  Specify resource id');
  writeln('/f  Specify resource flags          /d  Decrypt while dumping');
  halt(1);
end;

var
  command  : FNameStr;
  f        : FNameStr;
  PR       : PResource;
  obj      : FNameStr;
  param    : FNameStr;
  paginate : boolean;

function GetStrFlags(s:string):word;
  function IsF(c:char):byte;
  begin
    IsF := byte(pos(c,s) > 0);
  end;
begin
  FastUpper(s);
  GetStrFlags := IsF('F')*rfFixed+
                 IsF('P')*rfProtected+
                 IsF('E')*rfEncrypted;
end;

procedure HelpCommand;
var
  c:char;
  s:string;
begin
  if ParamCount <> 2 then XAbort('insufficient parameters');
  c := f[1];
  s := 'filename[.RIF]';
  case c of
    'A','R','L','T','P'     : ;
    'N'                     : s := s+' old_name new_name';
    'C'                     : s := 'source[.RIF] target[.RIF]';
    'E','M','I','D','S','U' : s := s+' resource_name';
    'B'                     : s := s+' listfile';
    'H'                     : s := 'command';
    'X'                     : s := 'filename[.RIF] filename resource_name';
    else                      s := 'unimplemented command';
  end; {case}
  if c = 'C' then begin
    writeln('This command converts ARM 1.00 RIF files as well as EXE files to');
    writeln('new AXE format. Some resource types not implemented but they''re');
    writeln('not used in ARM either. So there are no bugs. Using same source');
    writeln('and target name may cause erratic results.');
  end else
  if c = 'N' then begin
    writeln('Renames resource object given by old_name to new_name. I think');
    writeln('you won''t need any further information. That''s enough.');
  end else
  if c = 'E' then begin
    writeln('This command provides extraction of a resource object to a file.');
    writeln('Multiple extraction formats only supported by sound objects.');
    writeln('Others are extracted to unique GENSYS format (VIF,MIF,KIL,TUY).');
    writeln('No guarantee for any successful extraction.');
  end else
  if c = 'B' then begin
    writeln('Adding items from a list file is a useful procedure. Because of');
    writeln('the GENDIS experience, we learned that, adding 32 resource items');
    writeln('to a resource file is somewhat killing. So use this command'#13#10);
    writeln('text format: filename,resource_name,resource_id,flags');
  end else
  if c = 'M' then begin
    writeln('Dumping is cool, huh? This command recently used for debugging');
    writeln('purposes by SSG. In most cases you wouldn''t need to bear');
    writeln('with this command.');
  end else
  if c = 'P' then begin
    writeln('You got it! The ultimate resource repairing system by SSG! This');
    writeln('command searches for any object in resource file and extracts');
    writeln('if it founds. The fixed filename is always: AXEFIX.RIF.');
  end else
  if c = 'U' then begin
    writeln('Undeletes resource objects. No need any more info. Uses low');
    writeln('level routines to process resource files. And incompatible');
    writeln('resource versions may behave strange. Be careful when using');
    writeln('this powerful tool.');
  end else
  if c = 'T' then begin
    writeln('The test command performs two tests on resource file: structure');
    writeln('test and object integrity test. Object tests are performed only');
    writeln('on protected objects.');
  end else
  if c = 'I' then begin
    writeln('Like dump command, this command is used for debugging job, too.');
    writeln('There is no different or additional info except disk offset');
    writeln('via this little command. You may use it.');
  end else
  if c = 'X' then begin
    writeln('Replacement is a good function that allows both deleting and');
    writeln('resource item at the same time. Fast and powerful.');
    writeln;
    writeln('note: You can redefine flags of resource item via param /f');
  end else
  if c = 'R' then begin
    writeln('This command rebuilds entire resource, and disposes of deleted');
    writeln('objects. If any deleted objects in resource, they''re lost');
    writeln('forever. (In other words; forget''em)');
  end else
  if c = 'L' then begin
    writeln('As you see, this command lists contents of RIF file. This command');
    writeln('can be used in conjuction with /P parameter for formatted listings.');
    writeln('Also you can list specific resource objects via putting first letter');
    writeln('of object type at the end of command letter (''L''). For example:');
    writeln;
    writeln('axe lsb deneme /p');
    writeln;
    writeln('This command lists only sound and binary objects in DENEME.RIF');
    writeln('file and pauses at each screenful.');
  end else
  if c = 'D' then begin
    writeln('This fast delete command exactly does not remove resource item');
    writeln('from the resource file. They can be undeleted (nice feature) by');
    writeln('this program. If you want to get rid of them forever, use rebuild');
    writeln('function also provided by this program too.');
  end; {that's all folks}
  writeln;
  writeln('parameters: '+s);
end;

type

  IdGetProc = procedure(var T:TROB);

const

  TmpName = '$$G.TMP';

  VIFH   : string[3] = 'VIF'; {file headers}
  CIFH   : string[3] = 'CIF';
  MIFH   : string[3] = 'MIF';
  SFXH   : string[3] = 'SFX';
  BMPH   : string[2] = 'BM';
  VOCH   : string = 'Creative Voice File';
  WAVH   : string[4] = 'RIFF';

  ExtTable = 'PAL-BIN-VIF-BMP-CEL-CIF-FNT-SFX-VOC-WAV-MIF';

  rsVIF  = 0;
  rsBMP  = 1;
  rsCEL  = 2;

  rsCIF  = 3;
  rsFNT  = 4;

  rsSFX  = 5;
  rsVOC  = 6;
  rsWAV  = 7;

  rsMIF  = 8;
  rsBIN  = 9;

  rsPAL  = 10;

  MaxTypes = 10;
  TypeXlat : array[0..MaxTypes] of string[30] =
    ('FatalVision Bitmap',
    'Windows Bitmap',
    'Animator CEL',
    'FatalVision Font',
    'Windows Font',
    'FatalVision Sound',
    'Creative Labs Sound',
    'Waveform Sound',
    'FatalVision MouseImage',
    'Generic Binary',
    'Raw Palette');

  rscinit : string[19] = 'init resource...';

procedure InitRif(w:word);
begin
  write(rscinit);
  New(PR,Init(f,w));
  if PR^.OK then ok else Failed;
end;

function GetFileType(AFile:FNameStr):integer;
var
  T       : TDosStream;
  Buf     : Pointer;
  BufSize : Word;
  ftp     : integer;
begin
  ftp := -1;
  if pos('.PAL',afile) > 0 then ftp := rsPAL else
  if Pos('.WAV',AFile) > 0 then ftp := rsWAV else
  if Pos('.FNT',AFile) > 0 then ftp := rsFNT else
  if Pos('.BIN',AFile) > 0 then ftp := rsBIN;
  if ftp = -1 then begin
    T.Init(AFile,stOpenRead);
    if T.Status = stOK then begin
      if T.GetSize > 256 then BufSize := 256
                         else BufSize := T.GetSize;
      GetMem(Buf,BufSize);
      T.Read(Buf^,BufSize);
      if BufCmp(Buf^,VIFH[1],3) then ftp := rsVIF
         else if BufCmp(Buf^,CIFH[1],3) then ftp := rsCIF
         else if BufCmp(Buf^,BMPH[1],2) then ftp := rsBMP
         else if BufCmp(Buf^,MIFH[1],3) then ftp := rsMIF
         else if BufCmp(Buf^,WAVH[1],4) then ftp := rsWAV
         else if Word(Buf^) = $9119 then ftp := rsCEL
         else if BufCmp(Buf^,SFXH[1],3) then ftp := rsSFX
         else if BufCmp(Buf^,VOCH[1],Byte(VOCH[0])) then ftp := rsVOC;
      FreeMem(Buf,BufSize);
    end;
    T.Done;
  end;
  GetFileType := ftp;
end;

function ValidFile(AFile:FNameStr):Boolean;
var
  a:DirStr;
  b:NameStr;
  c:ExtStr;
begin
  FSplit(AFile,a,b,c);
  C := Copy(c,2,3);
  ValidFile := Pos(c,ExtTable)>0;
end;

function ReadFile(var T:TROB):boolean;
var
  ft : integer;
  S  : TDosStream;
begin
  ReadFile :=false;
  if not ValidFile(param) then XAbort('unknown object');
  ft := GetFileType(param);
  if (ft = -1) or (ft > MaxTypes) then XAbort('unknown object type');
  write(TypeXLat[ft]+'...');
  T.Size := 0;
  case ft of
    rsVIF : begin
              T.ROBType := rtImage;
              LoadVIF(param,PVIFMap(T.MWhere));
              T.Version := PVIFMap(T.MWhere)^.Version;
            end;
    rsPAL : begin
              T.ROBType := rtPalette;
              T.MWhere := LoadPAL(param);
              T.Version := 1;
            end;
    rsBMP : begin
              T.ROBType := rtImage;
              T.Version := 2;
              ShowBMP2(param,PVIFMap(T.MWhere));
            end;
    rsWAV : begin
              T.ROBType := rtSound;
              T.Version := 1;
              LoadWave(param,PSound(T.MWhere));
            end;
    rsSFX : begin
              T.ROBType := rtSound;
              T.Version := 1;
              LoadSound(param,PSound(T.MWhere));
            end;
    rsVOC : begin
              T.ROBType := rtSound;
              T.Version := 1;
              LoadVOC(param,PSound(T.MWhere));
            end;
    rsMIF : begin
              T.ROBType := rtMouse;
              T.Version := 1;
              LoadMouse(param,PMIF(T.MWhere));
            end;
    rsFNT : begin
              T.ROBType := rtFont;
              LoadFNT(param,PFont(T.MWhere));
              T.Version := PFont(T.MWhere)^.FontType+1;
            end;
    rsBIN : begin
              S.Init(param,stOpenRead);
              T.ROBType := rtBinary;
              T.Size    := S.GetSize;
              if S.Status = stOK then
              if (T.Size < MaxAvail) then if (T.Size < 65000) then begin
                GetMem(T.MWhere,T.Size);
                S.Read(T.MWhere^,T.Size);
              end;
              S.Done;
            end;
    else XAbort('Object type not implemented');
  end; {case}
  ReadFile := T.MWhere <> NIL;
end;

function ReadKey:char;assembler;
asm
  xor ax,ax
  int 16h
end;

function ScrPause:char;
begin
  write('- more -');
  ScrPause := readkey;
  write(#13);
end;

function GetKey(s:string):char;
var
  c:char;
begin
  repeat
    c := upcase(ReadKey);
  until Pos(c,s) > 0;
  GetKey := c;
end;

function GetOK(prompt:string):byte;
var
  c:char;
begin
  write(prompt);
  c := GetKey('YN');
  writeln(c);
  GetOK := byte(c = 'Y');
end;

procedure GetData(var T:TROB);
var
  s:string;
begin
  if XIsParam('N') = 0 then begin
    write('Name           : ');
    readln(T.Name);
  end else T.Name := XGetParamStr(XIsParam('N'));
  if T.Name = '' then XAbort('Cancelled');
  if XIsParam('I') = 0 then begin
    write('Resource Id    : ');
    readln(s);
  end else s := XGetParamStr(XIsParam('I'));
  T.Id    := s2l(s);
  if XIsParam('F') = 0 then begin
    write('Flags (Fixed/Encrypted) : ');
    readln(s);
  end else s := XGetParamStr(XIsParam('F'));
  T.Flags := GetStrFlags(s);
end;

function FlagToStr(w:word):string;
const
  Flags : string = 'FCEP*???';
var
  s:string;
  b:byte;
begin
  s := '        ';
  for b:=1 to length(s) do if w and (1 shl (b-1)) > 0 then s[b] := Flags[b];
  FlagToStr := s;
end;

procedure ListResource;
var
  s:string;
  s1:string;
  P:PROB;
  R:TROBHeader;
  st:TDosStream;
  c:byte;
  rumpelstilskin:char;
  totalsize :longint;
  n:integer;
  pagesize:byte;
  procedure WriteLine;
  begin
    writeln('==================== ========== ======== ==== ========== ======== =====');
  end;
  function Avail(what:byte):boolean;
  const
    types : array[0..MaxRscTypes] of char = 'BISFM';
  begin
    Avail := true;
    if what > MaxRscTypes then exit;
    if length(command) > 1 then
      avail := pos(types[what],copy(command,2,255)) > 0;
  end;
begin
  if not XFileExists(f) then XAbort('resource not found');
  InitRif(stOpenRead);
  st.Init(f,stOpenRead);
  if not Pr^.FOK then XAbort('Invalid resource');
  writeln('Listing ',FExpand(f));
  writeln;
  writeln('OBJECT NAME          TYPE       FLAGS    ID   SIZE       DATE     TIME');
  WriteLine;
  c          := 0;
  totalsize  := 0;
  pagesize   := 25;
  for n:=0 to Pr^.Index^.Count-1 do begin
    P := Pr^.Index^.At(n);
    st.Seek(P^.DWhere);
    st.Read(R,SizeOf(R));
    if st.Status <> stOK then XAbort('stream access error');
    if Avail(R.ROBType) then begin
      s := Fix(R.Name,20);
      s := s + ' '+GetRTName(R.ROBType)+'.v'+l2s(R.Version)+' '+FlagToStr(R.Flags)+' '+
           RFix(l2s(R.Id),4)+' ';
      s1 := l2s(R.Size);
      FastRFix(s1,10);
      s := s + s1 ;{+ ' ' + Date2Str(R.Date,false) + ' ' + Time2Str(R.Time,false,true);}
      writeln(s);
      inc(totalsize,R.Size);
      if Paginate then begin
        inc(c);
        if c > pagesize-5 then begin
          c := 0;
          if ScrPause = #27 then halt;
        end;
      end; {if paginate}
    end; {if deleted}
  end; {for}
  WriteLine;
  writeln('Total objects        = ',Pr^.Index^.Count);
  writeln('Total size           = ',totalsize);
  st.Done;
  Dispose(Pr,Done);
end;

procedure AddInit;
begin
  if PR = NIL then begin
    write(rscinit);
    New(PR,Init(f,stOpen));
    if not PR^.OK then begin
      if XFileExists(F) then
        if GetOK('Invalid resource. Re-create it? ')=0 then exit;
      Dispose(PR,done);
      New(PR,Init(f,stCreate));
      if not PR^.OK then Failed;
    end;
    ok;
  end; {if}
end;

procedure AddResource(IdGet:IdGetProc);
var
  T:TROB;
begin
  AddInit;
  IdGet(T);
  write('reading object...');
  if not ReadFile(T) then Failed else ok;
  write('writing...');
  PR^.WriteROB(T,T.MWhere);
  if not PR^.FOK then Failed else ok;
end;

procedure DeleteResource;
var
  T:TROB;
  P:PROB;
begin
  InitRif(stOpen);
  write('searching object...');
  T.Name := param;
  P := PR^.GetROB(T,rshName);
  if (P = NIL) or not PR^.FOK then Failed else ok;
  write('deleting...');
  PR^.DeleteROB(P^);
  if PR^.FOK then ok else failed;
end;

procedure RebuildResource;
const
  deleted : longint = 0;
  rebuilt : longint = 0;
  gain    : longint = 0;
var
  I,O:TDosStream;
  H:TROBHeader;
  RH:TRIFHeader;
  totsize,cursize:longint;
  bufsize:word;
  buf:pointer;
  procedure sc;
  begin
    totsize := H.Size;
    cursize := 0;
    while cursize < totsize do begin
      bufsize := 65000;
      if bufsize > MaxAvail then bufsize := MaxAvail;
      if bufsize > totsize-cursize then bufsize := totsize-cursize;
      GetMem(buf,bufsize);
      I.Read(buf^,bufsize);
      O.Write(buf^,bufsize);
      FreeMem(buf,bufsize);
      inc(cursize,bufsize);
    end;
  end;
  procedure err(s:string);
  begin
    XDeleteFile(TmpName);
    XAbort(s);
  end;
var
  s:string;
begin
  I.Init(f,stOpenRead);
  if I.Status <> stOK then err('resource not found');
  write('reading header...');
  I.Read(RH,SizeOf(RH));
  if I.Status <> stOK then failed;
  if not BufCmp(RH.Id,ResourceID,SizeOf(TId)) then err('invalid header');
  if I.Status = stOK then ok else failed;
  write('rebuilding...');
  O.Init(tmpname,stCreate);
  O.Write(RH,SizeOf(RH));
  repeat
    I.Read(H,SizeOf(H));
    if I.Status = stOK then begin
      if not BufCmp(H.Sign,ROBID,SizeOf(TId)) then err('bad structure');
      if H.Flags and rfDeleted = 0 then begin
        s := H.Name;
        while length(s) < 18 do s := s+#32;
        write(s,duplicate(#8,18));
        O.Write(H,SizeOf(H));
        sc;
        inc(rebuilt);
      end else begin
        inc(deleted);
        I.Seek(I.GetPos+H.Size);
      end;
    end; {if}
  until (I.GetPos >= I.GetSize) or (I.Status <> stOK);
  writeln('done'+duplicate(#32,14));
  write('renaming files...');
  gain := I.GetSize-O.GetSize;
  I.Done;
  O.Done;
  XRenameAnyway(f,ReplaceExt(f,'.BAK'));
  XRenameAnyway(TmpName,f);
  ok;
  writeln;
  writeln('Total objects    = ',rebuilt+deleted);
  writeln('Deleted objects  = ',deleted);
  writeln('Rebuilt objects  = ',rebuilt);
  writeln;
  writeln('Size gained      = ',gain);
  writeln;
end;

procedure Info;
const
  flags:array[0..7] of string[10] = ('Fixed','???','Encrypted','Protected','','','','');
var
  T:TROB;
  P:PROB;
  H:TROBHeader;
  s:string;
  procedure GetFlagStr;
  var
    b:byte;
  begin
    s := '';
    for b:=0 to 7 do if P^.Flags and (1 shl b) > 0 then s:=s+flags[b]+'+';
    if length(s) > 0 then dec(byte(s[0]));
  end;
const
  ftts : array[0..1] of string[12] = ('Fixed','Proportional');
begin
  InitRif(stOpenRead);
  write('searching...');
  T.Name := param;
  P := PR^.GetROB(T,rshName);
  if P = NIL then Failed else ok;
  writeln;
  PR^.Stream.Seek(P^.DWhere);
  PR^.Stream.Read(h,sizeof(h));
  GetFlagStr;
  writeln('Name         = ',T.Name);
  writeln('Type         = ',GetRTName(P^.ROBType),' version ',P^.Version);
  P^.MWhere := PR^.ReadROB(P^);
  if P^.MWhere <> NIL then
  case P^.ROBType of
    rtBinary:;
    rtImage : with PVIFMap(P^.MWhere)^ do begin
                writeln('  XSize      = ',XSize);
                writeln('  YSize      = ',YSize);
              end;
    rtSound : with PSound(P^.MWhere)^ do begin
                writeln('  Size       = ',Size);
                writeln('  Flags      = '+l2s(Flags));
                writeln('  Frequency  = ',KHz,' KHz');
              end;
    rtMouse : with PMIF(P^.MWhere)^ do begin
                writeln('  HotSpot-X  = ',HX);
                writeln('  HotSpot-Y  = ',HY);
              end;
    rtFont  : with PFont(P^.MWhere)^ do begin

                write('  Type       = ');
                if FontType > 1 then writeln('Unknown') else writeln(ftts[FontType]);
                case FontType of
                  0 : begin
                        writeln('  XSize      = ',ChrX);
                        writeln('  YSize      = ',ChrY);
                      end;
                  1 : begin
                        writeln('  YSize      = ',ChrY1);
                        writeln('  Total Size = ',Size);
                      end;
                end; {case}
              end;
  end; {CASE}
  writeln('Flags        = ',s);
  s := l2s(P^.Size);
  writeln('Size         = ',s);
  writeln('CRC          = ',l2s(H.CRC));
  writeln('File Offset  = ',P^.DWhere);
end;

procedure WriteSound(F:FNameStr;format:char;P:PSound); {Sfx,Voc,Wav}
var
  T    : TDosStream;
  Shdr : TSFXHeader;
  Whdr : TWaveHeader;
  Vhdr : TVOCHeader;
  w    : word;
const
  riff : tid = 'RIFF';
  wave : tid = 'WAVE';
  fmt  : array[1..3] of char = 'fmt';
  data : tid = 'data';
  voc  : array[1..20] of char = 'Creative Voice File'#$1a;
begin
  if P^.KHz = 0 then XAbort('invalid freq info');
  T.Init(F,stCreate);
  case Format of
    'S' : with Shdr do begin
            Id      := SFXid;
            Version := $100; {1.00}
            KHz     := P^.KHz;
            Flags   := P^.Flags;
            Size    := P^.Size;
            T.Write(Shdr,SizeOf(Shdr));
          end;
    'W' : with Whdr do begin
            RIFFid   := riff;
            RIFFsize := P^.Size + SizeOf(Whdr) - 8;
            WAVEid   := wave;
            Move(fmt,FMTid,sizeof(fmt));
            FMTsize  := 17;
            DATAid   := data;
            DATAsize := P^.Size;
            Freq1    := P^.KHz;
            Freq2    := P^.KHz;
            T.Write(Whdr,SizeOf(Whdr));
          end;
    'V' : with Vhdr do begin
            Move(voc,Sign,sizeof(voc));
            DataOffs   := $1a;
            Version    := $100;
            CRC        := $1233-$100;
            BlockType  := 1;
            BlockLen   := P^.Size;
            Temp       := 0;
            PackedKHZ  := 256-(1000000 div P^.KHz);
            Pack       := 0;
            T.Write(VHdr,SizeOf(VHdr));
          end;
  end; {case}
  T.Write(P^.Sample,P^.Size);
  if Format = 'V' then begin
    w := 0;
    T.Write(w,2);
  end;
end;

procedure ExtractItem;
var
  T:TROB;
  P:PROB;
  s:FNameStr;
  O:TDosStream;
  procedure WriteVIF;
  var
    H     : TVIFHeader;
    VIFId : PChar;
    pln   : byte;
    plnsz : word;
    c     : char;
    x,y   : integer;
    BC    : TBMPCore;
    Px    : PChar;
    OldPal : TRGBPalette;
    NewPal : TQuadPalette;
    function GetPix:byte;
    var
      bit:byte;
      count:byte;
      pixel:byte;
      offs:word;
      Pc:^byte;
    begin
      with PVIFMap(P^.MWhere)^ do begin
        offs := Pixel2Byte(xsize)*ysize+Pixel2Byte(x);
        bit  := x mod 8;
        pixel := 0;
        for count := 0 to 3 do begin
          Pc := Planes[count];
          inc(word(Pc),offs);
          if Pc^ and (1 shl bit) > 0 then pixel := pixel or (1 shl bit);
        end;
        GetPix := pixel;
      end;
    end;
  begin
    write('Output format (Bitmap/Vif) : ');
    c := GetKey('BV'#27);
    if c = #27 then XAbort('* break *') else writeln;
    write('writing ');
    case c of
      'B' : with PVIFMap(P^.MWhere)^ do begin
              write('bitmap...');
              O.Init(XAddExt(s,'.BMP'),stCreate);
              ClearBuf(BC,SizeOf(BC));
              with BC do begin
                BMId      := BMHeader;
                DataStart := SizeOf(BC)+SizeOf(TBMPExtra);
                FSize     := DataStart+XSize*YSize;
                Unknown1  := 0;
                HdrSize   := 40;
                SizeX     := XSize;
                SizeY     := YSize;
                Planes    := 1;
                BitCount  := 8;
              end;
              O.Write(BC,SizeOf(BC));
              GetMem(Px,SizeOf(TBMPExtra));
              FillChar(Px^,SizeOf(TBMPExtra),0);
              O.Write(Px^,SizeOf(TBMPExtra));
              FreeMem(Px,SizeOf(TBMPExtra));
              GetPalette(OldPal);
              SetStartupPalette;
              GetQuadPalette(NewPal);
              SetPalette(OldPal);
              O.Write(NewPal,SizeOf(NewPal));
              GetMem(Px,XSize);
              for y := YSize-1 downto 0 do begin
                XWritePerc(YSize-y,ysize);
                for x := XSize-1 downto 0 do begin
                  Px[XSize-x] := char(GetPix);
                  O.Write(c,1);
                end;
                O.Write(Px^,XSize);
              end;
              FreeMem(Px,XSize);
              BC.FSize := O.GetSize;
              O.Seek(0);
              O.Write(BC,SizeOf(BC));
              O.Done;
            end;
      'V' : begin
              write('vif...');
              O.Init(XAddExt(s,'.VIF'),stCreate);
              with PVIFMap(P^.MWhere)^ do begin
                VIFId := 'VIF1.0';
                Move(VIFId^,H.Id,SizeOf(VIFId));
                if Version = 2 then inc(H.Version[0]);
                H.EOFFlag  := $1a;
                H.HardFlag := 0;
                O.Write(H,Sizeof(H));
                O.Write(P^.MWhere^,5);
                plnsz := Pixel2Byte(XSize)*YSize;
                case Version of
                  1 : O.Write(Data,XSize*YSize);
                  2 : for pln:=0 to 3 do O.Write(Planes[pln]^,plnsz);
                  else XAbort('unknown version');
                end; {case}
              end;
              O.Done;
            end;
      end; {case}
      ok;
  end;

  procedure WriteSFX;
  var
    c:char;
  begin
    write('Output format (Sfx/Voice/Wave) : ');
    c := GetKey('SVW'#27);
    if c = #27 then XAbort('* break *') else writeln;
    write('writing ');
    case c of
      'S' : begin
              write('sfx...');
              s := XAddExt(s,'.SFX');
            end;
      'W' : begin
              write('wave...');
              s := XAddExt(s,'.WAV');
            end;
      'V' : begin
              write('voice...');
              s := XAddExt(s,'.VOC');
            end;
    end;
    WriteSound(s,c,P^.MWhere);
    ok;
  end;

  procedure WriteMIF;
  const
    MIFId : Tid = 'MIF'#$1a;
  var
    H:TMIFHeader;
  begin
    write('writing mouse...');
    O.Init(XAddExt(s,'.MIF'),stCreate);
    with H do begin
      Id      := MIFid;
      Version := $100;
      HX      := PMIF(P^.MWhere)^.HX;
      HY      := PMIF(P^.MWhere)^.HY;
    end; {with}
    O.Write(H,SizeOf(H));
    O.Write(PMIF(P^.MWhere)^.Bitmap,P^.Size);
    O.Done;
    ok;
  end;

  procedure WriteGeneric;
  begin
    write('writing generic...');
    O.Init(s,stCreate);
    O.Write(P^.MWhere^,P^.Size);
    O.Done;
    ok;
  end;

begin
  InitRif(stOpenRead);
  write('reading...');
  T.Name := param;
  P := PR^.GetROB(T,rshName);
  if P = NIL then Failed;
  P^.MWhere := PR^.ReadROB(P^);
  if P^.MWhere = NIL then Failed else ok;
  write('Enter filename : ');
  readln(s);
  case P^.ROBType of
    rtImage  : WriteVIF;
    rtSound  : WriteSFX;
    rtMouse  : WriteMIF;
    rtFont   : XAbort('Font support not implemented');
    else WriteGeneric;
  end; {case}
end;

var
  currentline:string;

procedure TextFilter(var T:TROB);
var
  n:integer;
  count:integer;
  s:string;
begin
  count := GetByteCount(currentline[1],length(currentline),byte(','));
  if count <> 3 then begin
    writeln('invalid arguments in listfile');
    exit;
  end;
  T.Name  := GetParse(currentline,',',2);
  T.Id    := s2l(GetParse(currentline,',',3));
  s := GetParse(currentline,',',4);
  T.Flags := GetStrFlags(s);
end;

procedure AddList;
var
  T:TDosStream;
  R:TROB;
  b:byte;
begin
  if ParamCount <> 3 then incorrectParams;
  if not XFileExists(param) then XAbort(param+' not found');
  AddInit;
  T.Init(param,stOpenRead);
  while T.Status = stOK do begin
    SReadln(T,currentline);
    if T.Status = stOK then begin
      b := pos(',',currentline);
      if b > 0 then begin
        param := copy(currentline,1,b-1);
        FastUpper(param);
        AddResource(TextFilter);
      end else writeln('invalid line in listfile');
    end; {if}
  end;
  T.Done;
  Dispose(PR,Done);
end;

procedure TestResource;
var
  T:TDosStream;
  RH:TRIFHeader;
  H:TROBHeader;
begin
  write('init resource...');
  T.Init(f,stOpenRead);
  if T.Status <> stOK then failed else ok;
  write('checking header...');
  T.Read(RH,SizeOf(RH));
  if BufCmp(RH.Id,ResourceId,SizeOf(TId)) then ok else failed;
  write('testing resource structure...');
  while T.GetPos < T.GetSize do begin
    XWritePerc(T.GetPos,T.GetSize);
    T.Read(H,SizeOf(H));
    if not BufCmp(H.Sign,ROBid,SizeOf(TId)) then failed;
    T.Seek(T.GetPos+H.Size);
  end;
  ok;
  writeln;
  T.Seek(SizeOf(RH));
  while T.GetPos < T.GetSize do begin
    T.Read(H,SizeOf(H));
    if (H.Flags and rfDeleted = 0) and (H.Flags and rfProtected > 0) then begin
      FastFix(H.Name,RNLen);
      write('Testing : '+H.Name+'  ');
      if H.CRC = XGetStreamChecksum(T,H.Size) then ok else writeln('CRC error!');
    end else T.Seek(T.GetPos+H.Size);
  end;
  T.Done;
end;

procedure RepairResource;
var
  RH:TRIFHeader;
  H:TROBHeader;
  I,O:TDosStream;
  l:Tid;
  current:longint;
  Buf:pointer;
  BufSize:word;
  CRC:word;
const
  total:longint = 0;
  faileds:longint = 0;
  procedure CreateHdr;
  begin
    write('creating header...');
    ClearBuf(RH,SizeOf(RH));
    Move(ResourceId,RH.Id,SizeOf(Tid));
    O.Write(RH,SizeOf(RH));
    ok;
  end;
  function ValidId:boolean;
  begin
    ValidId := BufCmp(l,ROBId,SizeOf(tid));
  end;
  procedure ReadROBHdr;
  begin
    I.Seek(I.GetPos-4);
    I.Read(H,SizeOf(H));
  end;
  procedure wp;
  begin
    XWritePerc(I.GetPos,I.GetSize);
  end;
begin
  if ParamCount < 2 then incorrectParams;
  write('init resource...');
  I.Init(XAddExt(f,'.RIF'),stOpenRead);
  O.Init('AXEFIX.RIF',stCreate);
  if I.Status <> stOK then failed;
  ok;
  write('reading header...');
  I.Read(RH,SizeOf(RH));
  if not BufCmp(RH.Id,ResourceId,SizeOf(Tid)) then begin
    writeln('invalid');
    CreateHdr;
  end else begin
    O.Write(RH,SizeOf(RH));
    ok;
  end;
  writeln;
  write('searching...');
  while I.Status = stOK do begin
    wp;
    I.Read(l,SizeOf(l));
    if I.Status = stOK then
    if ValidId then begin
      write('writing...');
      ReadROBHdr;
      O.Write(H,SizeOf(H));
      current := 0;
      CRC     := 0;
      while current < H.Size do begin
        wp;
        BufSize := 65000;
        if BufSize > MaxAvail then BufSize := MaxAvail;
        if BufSize > H.Size-current then BufSize := H.Size-current;
        GetMem(Buf,BufSize);
        I.Read(Buf^,BufSize);
        O.Write(Buf^,BufSize);
        inc(CRC,GetChecksum(Buf^,BufSize));
        FreeMem(Buf,BufSize);
        inc(current,BufSize);
      end;
      if H.Flags and rfProtected > 0 then case H.CRC = CRC of
        True  : writeln('CRC test ok');
        False : begin
                  writeln('CRC test failed');
                  inc(faileds);
                end;
      end else ok;
      inc(total);
      write('searching...');
    end;
  end;
  writeln;
  writeln;
  writeln('Total objects recovered = ',total);
  writeln('Objects failed CRC test = ',faileds);
  writeln;
end;

procedure UndeleteResource;
var
  T:TDosStream;
  RH:TRIFHeader;
  H:TROBHeader;
begin
  if ParamCount <> 3 then incorrectParams;
  write('init resource...');
  T.Init(XAddExt(f,'.RIF'),stOpen);
  T.Read(RH,SizeOf(RH));
  if not ValidRH(RH) then failed else ok;
  write('processing...');
  while T.GetPos < T.GetSize do begin
    XWritePerc(T.GetPos,T.GetSize);
    T.Read(H,SizeOf(H));
    if H.Name = param then begin
      if H.Flags and rfDeleted = 0 then XAbort('item is not deleted');
      H.Flags := H.Flags and not rfDeleted;
      T.Seek(T.GetPos-SizeOf(H));
      T.Write(H,SizeOf(H));
      ok;
      exit;
    end else T.Seek(T.GetPos+H.Size);
  end;
  failed;
end;

procedure RenameResource;
var
  T:TROB;
  P:PROB;
  H:TROBHeader;
  ofs:longint;
begin
  if ParamCount <> 4 then incorrectParams;
  AddInit;
  T.Name := param;
  P := PR^.GetROB(T,rshName);
  if P = NIL then failed else begin
    write('renaming...');
    with PR^.Stream do begin
      Seek(P^.DWhere);
      Read(H,SizeOf(H));
      H.Name := ParamStr(4);
      Seek(P^.DWhere);
      Write(H,SizeOf(H));
      ok;
    end;
  end;
end;

begin
  XAppInit('AXE Resource Manager',xVersion,'SSG',0,'');
  if (XIsParam('?') > 0) or (ParamCount = 0) then Usage;
  command := ParamStr(1);
  FastUpper(command);
  if (length(command) > 1) and (command[1] <> 'L') then XAbort('invalid command');
  param := ParamStr(3);
  f := ParamStr(2);
  FastUpper(param);
  FastUpper(f);
  f := XAddExt(f,'.RIF');
  Paginate := XIsParam('P') > 0;
  InitAXE;
  case upcase(command[1]) of
    'A' : AddResource(GetData);
    'B' : AddList;
    'D' : DeleteResource;
    'E' : ExtractItem;
    'H' : HelpCommand;
    'I' : Info;
    'L' : ListResource;
    'R' : RebuildResource;
    'T' : TestResource;
    'P' : RepairResource;
    'U' : UndeleteResource;
    'N' : RenameResource;
    else XAbort('Unknown command');
  end; {case}
  DoneAXE;
end.