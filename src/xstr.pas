{
Name            : XStr 1.06c
Purpose         : Extended string handling functions
Date            : 12th Jan 94
Coder           : SSG

updates:
--------
24th Jan 95 - 02:53 - Fixed a serious bug in strip...
 3rd Apr 95 - 13:46 - Added RFix and FastRFix...
24th Nov 95 - 04:27 - Added l2s...
24th Nov 95 - 05:34 - Added s2l...
28th Nov 95 - 00:43 - Optimized Fix routines...
 3rd Dec 95 - 03:31 - Moved GetBool here...
14th Mar 96 - 11:42 - Fixed a bug...
28th Mar 96 - 01:21 - enhanced strip to strip nulls...
28th Mar 96 - 02:50 - fixed a bug in strip...
21nd May 96 - 05:35 - added getparse...
27th Jun 96 - 19:15 - added distill...
27th Jun 96 - 19:33 - added z2s...
 7th Aug 96 - 22:56 - added replace...
12th Aug 96 - 14:56 - added getparsecount...
21st Aug 96 - 13:18 - 386 removal...
14th Sep 96 - 02:50 - fixes in rfix...
27th Sep 96 - 15:46 - removed some unnecessary code...
 2nd Nov 96 - 15:33 - added x2s & s2x (experimental)
21st Jan 97 - 08:14 - fixes in z2s...
}

{$N+,E+}

unit XStr;

interface

procedure Translate(var sacrifice:string; source,destination:string);
procedure ConvertWinTurkish(var s:string);
procedure DisableTurkish(var s:string);
procedure Strip(var s:string);
procedure FastLower(var s:string);
procedure FastUpper(var s:string);
procedure FastFix(var s:string; len:byte);
procedure FastRFix(var s:string; len:byte);
procedure Distill(var s:string; c:char);
procedure Replace(var s:string; src,dst:string);
procedure FastReplace(var s:string; src,dst:string); {srclen = dstlen}

function  SSG:string;
function  FastCmpStr(var src,dst:string):boolean;
function  Lower(s:string):string;
function  Upper(s:String):string;
function  LoCase(c:char):char;
function  GetEndPrefix(l:longint):string;
function  Duplicate(c:char;count:byte):string;
function  Fix(s:string;len:byte):string;
function  RFix(s:string;len:byte):string;
function  l2s(l:longint):string;
function  x2s(x:extended; dig1,dig2:integer):string;
function  s2x(s:string):extended;
function  z2s(l:longint; maxlen:byte):string;
function  s2l(s:string):longint;
function  GetBool(b:boolean; t,f:string):string;
function  GetParse(esas:string; parsechar:char; part:byte):string;
function  GetParseCount(esas:string; parsechar:char):byte;

const

  WinTransSource : string[12] = 'ýÝÇþÞöÖÜðÐçü';
  WinTransDest   : string[12] = '˜€Ÿž”™š§¦‡';
  TrTransDest    : string[12] = 'iICsSoOUgGcu';

implementation

uses

  XBuf;

function s2x;
var
  code:integer;
  x:extended;
begin
  Val(s,x,code);
  s2x := x;
end;

function x2s;
var
  s:string;
begin
  Str(x:dig1:dig2,s);
  Strip(s);
  x2s := s;
end;

function GetParseCount(esas:string; parsechar:char):byte;
var
  w:word;
begin
  if esas = '' then w := 0
               else w := GetByteCount(esas[1],length(esas),byte(parsechar))+1;
  GetParseCount := w;
end;

procedure Replace;
var
  b:byte;
begin
  b := pos(src,s);
  if b > 0 then begin
    Delete(s,b,length(src));
    Insert(dst,s,b);
  end;
end;

procedure FastReplace;
var
  b:byte;
begin
  b := pos(src,s);
  if b > 0 then Move(dst[1],s[b],length(src));
end;

procedure Distill;
var
  b:byte;
begin
  repeat
    b := pos(c,s);
    if b > 0 then Delete(s,b,1);
  until (b = 0) or (s='');
end;

function GetParse(esas:string; parsechar:char; part:byte):string;
var
  count:byte;
  b :byte;
begin
  count := 0;
  GetParse := '';
  while count < part do begin
    inc(count);
    b := pos(parsechar,esas);
    if count = part then begin
      if b > 0 then esas := copy(esas,1,b-1);
      Strip(esas);
      GetParse := esas;
      exit;
    end;
    if b = 0 then exit;
    esas := copy(esas,b+1,255);
  end;
end;

function GetBool;
begin
  if b then GetBool := t else GetBool := f;
end;

function s2l(s:string):longint;
var
  code:integer;
  l:longint;
begin
  Strip(s);
  Val(s,l,code);
  s2l := l;
end;

function l2s(l:longint):string;
var
  s:string;
begin
  Str(l,s);
  l2s := s;
end;

function z2s;
var
  z:string;
begin
  Str(l,z);
  if maxlen > length(z) then z2s := Duplicate('0',maxlen-length(z))+z
                        else z2s := z;
end;

procedure FastRFix;
begin
  if length(s) < len then s := Duplicate(#32,len-length(s)) + s;
end;

function RFix;
begin
  FastRFix(s,len);
  RFix := s;
end;

procedure FastFix;
begin
  if length(s) > len then byte(s[0]) := len else begin
    FillBuf(s[length(s)+1],len-length(s),32);
    byte(s[0]) := len;
  end;
end;

function FastCmpStr;assembler;
asm
  cld
  push  ds
  les   di,dst
  lds   si,src
  cmpsb
  jne   @No
  inc   di
  xor   ch,ch
  mov   cl,al
  shr   cx,1
  jnc   @Go
  cmpsb
  jne   @No
  inc   di
  inc   si
@Go:
  repe  cmpsw
  jne   @No
@Yes:
  mov   al,1
  jmp   @Exit
@No:
  xor   al,al
@Exit:
  pop   ds
end;

function Lower;
begin
  FastLower(s);
  Lower := s;
end;

procedure FastLower;
var
  b:byte;
begin
  for b:=1 to length(s) do s[b] := LoCase(s[b]);
end;

function Upper;
begin
  FastUpper(s);
  Upper := s;
end;

procedure FastUpper;
var
  b:byte;
begin
  for b:=1 to length(s) do s[b] := UpCase(s[b]);
end;

function LoCase;assembler;
asm
  mov  al,c
  cmp  al,'A'
  jb   @Skip
  cmp  al,'Z'
  ja   @Skip
  add  al,32
@Skip:
end;

procedure Strip(var s:string);
begin
  while (length(s) > 0) and (s[length(s)] in [' ',#0]) do dec(byte(s[0]));
  while (length(s) > 0) and (s[1] in [' ',#0]) do delete(s,1,1);
end;

function Fix;
begin
  FastFix(s,len);
  Fix := s;
end;

function GetEndPrefix;
const
  EndPrefix : array[0..9] of string[4] =
           ('nc','inci','nci','nc','nc','inci','nc','nci','inci','uncu');

var
  s:string[20];
  code:integer;
begin
  Str(l,s);
  GetEndPrefix := EndPrefix[byte(s[length(s)])-48];
end;

procedure ConvertWinTurkish(var s:string);
begin
  Translate(s,WinTransSource,WinTransDest);
end;

procedure DisableTurkish;
begin
  Translate(s,WinTransDest,TrTransDest);
end;

function Duplicate;
var
  s:string;
begin
  byte(s[0]) := count;
  FillBuf(s[1],count,byte(c));
  Duplicate := s;
end;

procedure Translate(var sacrifice:string; source,destination:string);
var
  n:byte;
  b:byte;
begin
  for n:=1 to length(sacrifice) do begin
    b := Pos(sacrifice[n],source);
    if b > 0 then sacrifice[n] := destination[b];
  end;
end;

function SSG;
const
  g : char = 'g';
  s : char = 'S';
begin
  SSG := s + s + upcase(g);
end;

end.