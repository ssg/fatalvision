{ Text resource compiler - (c) SSG again }

{$IFDEF DPMI} ALOOO!!! {$ENDIF}

uses Dos,XStr,XIO,XStream,Objects;

const

  ctrlchar = '^';

var
  I:Text;
  O:TCodedStream;
  Pas:TTextStream;
  s:string;
  pasname:FnameStr;
  idname:FnameStr;
  globalid:longint;
  id:longint;
  lc:longint;
  b:byte;
  c:char;

  procedure comerr(msg:fnameStr);
  begin
    XAbort(' ERROR: '+msg+' on line '+l2s(lc));
  end;

  procedure WritePasHeader;
  var
    dir:dirstr;
    name:namestr;
    ext:extstr;
  begin
    Pas.Writeln('{ Language File Compiled by TRC - (c) 1996 SSG }'#13#10);
    FSplit(pasname,dir,name,ext);
    Pas.Writeln('unit '+name+';'#13#10);
    Pas.Writeln('interface'#13#10);
    Pas.Writeln('const'#13#10);
  end;

  procedure WritePasFooter;
  begin
    Pas.Writeln(#13#10'implementation');
    Pas.Writeln(#13#10'end.');
  end;

begin
  writeln('Text resource compiler Version *.2 - (c) 1996 SSG'#13#10);
  if ParamCount <> 3 then XAbort('Usage: TRC infile outfile pasfile');
  Assign(I,ParamStr(1));
  Reset(I);
  if IOResult <> 0 then XAbort('input file not found');
  O.Init(XAddExt(ParamStr(2),'.LAN'),stCreate);
  if O.Status <> stOK then XAbort('cannot create output file');
  pasname := XAddExt(ParamStr(3),'.PAS');
  Pas.Init(pasname,stCreate);
  if Pas.Status <> stOK then XAbort('cannot create '+pasname);
  WritePasHeader;
  write('compiling...');
  lc := 0;
  globalid := 0;
  while not eof(I) do begin
    ReadLn(I,s);
    inc(lc);
    Strip(s);
    if (s='') or (s[1] = ';') then Continue;
    b := pos(',',s);
    if b = 0 then comerr('"," missing');
    idname := copy(s,1,b-1);
    id := s2l(idname);
    if id = 0 then begin
      id := globalid;
      inc(globalid);
      Pas.Writeln('  '+Fix('ms'+idname,50)+'= '+l2s(id)+';');
    end;
    s := copy(s,b+1,255);
    Strip(s);
    O.Write(id,SizeOf(id));
    if s <> '' then begin
      if s[1] = '''' then begin
        Delete(s,1,1);
        if s[length(s)] <> '''' then comerr('open marks');
        dec(byte(s[0]));
      end;
      while pos(ctrlchar,s) > 0 do begin
        b := pos(ctrlchar,s);
        s[b+1] := char(byte(s[b+1])-64);
        Delete(s,b,1);
      end;
    end;
    O.Write(s[0],1);
    if s <> '' then O.Write(s[1],length(s));
  end;
  Close(I);
  O.Done;
  WritePasFooter;
  Pas.Done;
  writeln('done'#13#10#13#10'La operacion y escobar SSG compinenta');
end.