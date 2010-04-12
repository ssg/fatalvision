{
Name            : XProtect 1.00c
Purpose         : EXE protector (from viruses, crackers, hackers, me)
Coder           : SSG

Update info:
------------
21st Nov 94 - 01:15 - Made code more stable...
21nd May 96 - 16:08 - Rewritten the code to handle non-overlaid protection
                      scheme...
}
{$R-,I-}
unit XProtect;

interface

uses XTypes,XBuf,Objects;

function EXEOK:boolean;

implementation

function EXEOK:boolean;
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
    if bufSize > MaxAvail then bufSize := MaxAvail;
    GetMem(buf,BufSize);
    T.Read(buf^,bufSize);
    inc(crc,GetChecksum(buf^,bufSize));
    FreeMem(buf,bufSize);
  end;
  T.Done;
  EXEOK := h.NegSum = crc;
end;

end.