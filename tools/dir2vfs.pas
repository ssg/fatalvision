uses Dos,XStr,XIO,Objects,XVFS;

var

  filename:FnameStr;

procedure AddFile(whatfile:string);
var
  I:TDosStream;
  O:TVFSStream;
  buf:pointer;
  bufsize:word;
begin
  FastLower(whatfile);
  write('adding '+whatfile+'...');
  I.Init(whatfile,stOpenRead);
  O.Init(whatfile,stCreate);
  if I.Status <> stOK then XAbort('input open error');
  if O.Status <> stOK then XAbort('output create error');
  while I.GetPos < I.GetSize do begin
    XWritePerc(I.GetPos,I.GetSize);
    bufsize := 65000;
    if bufsize > I.GetSize-I.GetPos then bufsize := I.GetSize-I.GetPos;
    if bufsize > MaxAvail then bufsize := MaxAvail;
    GetMem(buf,bufsize);
    I.Read(buf^,bufSize);
    O.Write(buf^,bufSize);
    FreeMem(buf,bufSize);
  end;
  I.Done;
  O.Done;
  ok;
end;

procedure AddDir(whatdir:string);
var
  dirinfo:SearchRec;
begin
  FindFirst(whatdir+'*.*',Directory+ReadOnly+Archive+Hidden+SysFile,dirinfo);
  while DosError = 0 do begin
    if dirinfo.Attr = Directory then begin
      if dirinfo.name[1] <> '.' then AddDir(whatdir+dirinfo.name+'\')
    end else if Upper(FExpand(whatdir+dirinfo.name)) <> Upper(filename) then AddFile(whatdir+dirinfo.name);
    FindNext(dirinfo);
  end;
end;

begin
  XAppInit('Recursive VFS Creator','1.00a','SSG',1,'Usage: filename[.VFS]');
  write('init vfs...');
  filename := XAddExt(FExpand(ParamStr(1)),'.VFS');
  if not XFileExists(filename) then if not CreateVFS(filename) then XAbort('couldn''t create '+filename);
  if not InitVFS(filename) then XAbort('file not found: '+filename);
  ok;
  AddDir('');
  DoneVFS;
  writeln(#13#10'SSG Operation complete');
end.