{
Name            : X/Help 2.01f
Purpose         : Help Server Functions
Coder           : SSG

Update info:
------------
02nd Apr 94 - 21:12 - Completed with no bugs...
05th Apr 94 - 21:12 - Optimized the code...
30th May 94 - 15:39 - Moved TTextStream to XStream...
 6th Aug 94 - 20:34 - Fixed a little bug...
29th Oct 94 - 19:32 - Removed unnecessary utilization of dos unit...
27th Nov 94 - 00:02 - Changed indexing tech...
 8th Dec 94 - 23:04 - Updated wordseps...
10th Dec 94 - 02:11 - Fixed a bug in NoteLineCount... not seriously...
25th Dec 94 - 23:18 - Adjusted wordseps...
10th Mar 96 - 01:29 - Removed notelinecount...
29th May 96 - 18:01 - removed sub-block types...
}

{$C MOVEABLE DEMANDLOAD DISCARDABLE}
{$O+}

unit XHelp;

interface

uses

XBuf,    {bufcmp}
XStream, {coded streams}
XIO,     {xaddext's}
Objects, {tcollection}
XTypes;  {everything else}

const

  hlpExt   : string[4] = '.HLP';

{  wordseps:set of char=[#32];}

  WildChar    = #0;

  hoTopic     = 1; {Help object types}
  hoNote      = 2;
  hoImage     = 3;
  hoSound     = 4;
  hoFont      = 5;

(*  MaxSBs      = 2;
  sbNewLine   = 0; {Topic sub-block types}
  sbWrapped   = 1;
  sbText      = 2;*)

  MaxObjects  = 32000;

  HIPSign     : TId = 'aa1'#$1a;
  HelpOK      : boolean = false;

type

  PXArray = ^TXArray;
  TXArray = array[0..65500] of char;

  TObjHdr = record
    ObjType : byte;
    Id      : word;
    Size    : word;
  end;

  THIPHdr = record
    Sign      : TId;
    IndexOffs : longint;
  end;

  PTable = ^TTable;
  TTable = record
    Id    : word;
    Where : longint;
    Next  : PTable;
  end;

const

  HIP:PCodedStream=NIL; {Help Information Please}

procedure InitHelpSystem(fn:FNameStr);
procedure DoneHelpSystem;

procedure GetObjectHdr(id:word;var T:TObjHdr);
function  SearchId(id:word):longint;
function  ReadNote(id:word;var P:PChar;var s:string):word;

implementation

const

  Index : PTable = NIL;

procedure DisposeIndex;
  procedure SubDispose(p:PTable);
  begin
    if P^.Next <> NIL then SubDispose(P^.Next);
    Dispose(P);
  end;
begin
  SubDispose(Index);
  Index := NIL;
end;

function NewEntry(aid:word; awhere:longint):PTable;
var
  P:PTable;
begin
  New(P);
  NewEntry := P;
  P^.Id    := aid;
  P^.Where := awhere;
  P^.Next  := NIL;
end;

procedure InitHelpSystem;
var
  T:THIPHdr;
  procedure BuildIndex;
  var
    l:longint;
    old:longint;
    id:word;
    P:PTable;
  begin
    HIP^.Seek(T.IndexOffs);
    while HIP^.GetPos < HIP^.GetSize do begin
      HIP^.Read(l,sizeof(longint));
      if HIP^.Status = stOK then begin
        old := HIP^.GetPos;
        HIP^.Seek(l+1);
        HIP^.Read(id,sizeof(id));
        HIP^.Seek(old);
        if index = NIL then index := NewEntry(id,l) else begin
          P := index;
          while P^.Next <> NIL do P := P^.Next;
          P^.Next := NewEntry(id,l);
        end;
      end;
    end;
  end;

(*  procedure BuildWordSeps;
  var
    b:char;
  begin
    WordSeps := [' '];
{    for b:=' ' to '@' do Include(WordSeps,b);
    for b:=#91 to #96 do Include(WordSeps,b);
    WordSeps := wordseps - ['0'..'9','?','!',':','.',',','(',')','"','''','/','-'];}
  end;*)

begin
  if HelpOK then DoneHelpSystem;
  New(HIP,Init(XAddExt(fn,hlpExt),stOpenRead));
  HIP^.Read(T,SizeOf(T));
  if (HIP^.Status <> stOK) or not BufCmp(T.Sign,HIPSign,SizeOf(HIPSign)) then begin
    Dispose(HIP,Done);
    HIP := NIL;
    exit;
  end;
{  BuildWordSeps;}
  BuildIndex;
  HelpOK := True;
end;

procedure DoneHelpSystem;
begin
  if HIP <> NIL then Dispose(HIP,Done);
  if index <> NIL then DisposeIndex;
  HelpOK := false;
end;

function SearchId;
var
  n:integer;
  l:longint;
  T:TObjHdr;
  P:PTable;
begin
  SearchId := -1;
  HIP^.Reset;
  P := index;
  while P <> NIL do begin
    if P^.Id = id then begin
      SearchId := P^.Where;
      exit;
    end;
    P := P^.Next;
  end;
end;

procedure GetObjectHdr;
var
  l:longint;
begin
  FillChar(T,SizeOf(T),255);
  l := SearchId(id);
  if l = -1 then exit;
  HIP^.Reset;
  HIP^.Seek(l);
  HIP^.Read(T,SizeOf(T));
end;

function ReadNote;
var
  T:TObjHdr;
begin
  P := NIL;
  GetObjectHdr(id,T);
  if T.Id = $FF then exit;
  HIP^.Read(s[0],1);
  HIP^.Read(s[1],length(s));
  dec(T.Size,length(s)+1);
  GetMem(P,T.Size);
  HIP^.Read(P^,T.Size);
  ReadNote := T.Size;
end;

end.
*** End of File ***