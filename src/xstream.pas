{
Name              : XStream 1.4d
Purpose           : Simple streams
Coder             : SSG
Date              : 10th Sep 93

Update Info:
------------
21st Sep 93 - 15:40 - *** Recovered the "Read" bug in "Write!"...
                      and added some pops for pushes...
21st Sep 93 - 16:10 - *** Recovered a "double" bug...
                      When i'm looping byte by byte.. di increments
                      double.. so it's named "double" bug...
22nd Sep 93 - 22:34 - Optimized the assembler source...
26th Oct 93 - 23:46 - Added CacheStream... but the performance does not
                      differ from TBufStream... (even slower a bit)
                      (but 3 times faster than TBufStream...)
26th Oct 93 - 00:00 - *** Recovered a bug...
05th Dec 93 - 11:58 - Enhanced the coding technology in TCodedStream...
                      (A classic technique 3 rols then xor then 3 rols)...
05th Dec 93 - 12:10 - *** Recovered a bug in Coding tech...
24th Nov 93 - 02:45 - Added TRecordStream... (I hope it will work)...
                      If it works, it will be the fastest code ever I have
                      written... (fastest code but not most reliable code)
29th Nov 93 - 02:50 - Moved something to somewhere... goodnight...
02nd Dec 93 - 15:50 - *** Fixed a bug in CodedStream...
14th Jan 94 - 16:14 - Rewrote TCacheStream...
30th May 94 - 15:39 - Moved TTextStream here...
 6th Nov 94 - 01:10 - Optimized TTextStream's Readln...
11th Nov 94 - 22:12 - *** Fixed a bug in Readln...
13th Nov 94 - 20:58 - *** Fixed another bug in Readln...
15th Dec 94 - 19:24 - Made Text stream faster...
25th Dec 95 - 22:49 - Removed TRecordStream...
 9th Mar 96 - 17:32 - made textstream buffered...
 4th Jan 97 - 03:54 - converted text stream to procs... (much flexible)
26th Jan 97 - 04:37 - rewritten readln...
}

unit XStream;

interface

uses

  XBuf,XStr,Objects;

const

  StDenyNone         = $0040;
  StNetOpenRead      = StOpenRead or StDenyNone;
  StNetOpenWrite     = StOpenWrite or StDenyNone;
  stNetOpen          = StOpen or StDenyNone;

type

  PCodedStream = ^TCodedStream;
  TCodedStream = object(TDosStream)
    procedure Read(var buf;count:word);virtual;
    procedure Write(var buf;count:word);virtual;
  end;

function  IniReadln(var T:TStream; var s:string):boolean;
procedure SReadln(var T:TStream; var s:string);
procedure SWriteln(var T:TStream; s:String);

implementation

function IniReadln(var T:TStream; var s:string):boolean;
begin
  while (T.GetPos < T.GetSize) and (T.Status = stOK) do begin
    SReadln(T,s);
    Strip(s);
    if s <> '' then if s[1] <> ';' then begin
      IniReadln := true;
      exit;
    end;
  end;
  iniReadLn := false;
end;

procedure SWriteLn;
begin
  s := s+#13#10;
  T.Write(s[1],length(s));
  T.Flush;
end;

procedure SReadLn;
var
  temp:string;
  apos:longint;
  asize:longint;
  b:byte;
  size:byte;
begin
  size := 255;
  apos := T.GetPos;
  asize := T.GetSize;
  if size > asize-apos then size := asize-apos;
  temp[0] := char(size);
  T.Read(temp[1],size);
  b := pos(#13,temp);
  if b > 0 then begin
    inc(apos,b);
    if b < length(temp) then if temp[b+1] = #10 then inc(apos);
    byte(temp[0]) := b-1;
    T.Seek(apos);
  end else begin
    b := pos(#10,temp);
    if b > 0 then begin
      inc(apos,b);
      if b < length(temp) then if temp[b+1] = #13 then inc(apos);
      byte(temp[0]) := b-1;
      T.Seek(apos);
    end;
  end;
  s := temp;
end;

{********************************* TCODEDSTREAM **************************}
procedure TCodedStream.Read(var buf;count:word);
begin
  inherited Read(buf,count);
  DeCode(buf,count);
end;

procedure TCodedStream.Write(var buf;count:word);
begin
  EnCode(buf,count);
  inherited Write(buf,count);
  DeCode(buf,count);
end;

end.
