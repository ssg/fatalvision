uses XBuf,XTypes,Objects,XIO;

var
  h:TEXEHeader;
  T:TDosStream;
  crc:word;
  buf:pointer;
  bufsize:word;
begin
  XAppInit('MakeEXECRC','2.00a','SSG',1,'exename');
  T.Init(ParamStr(1),stOpen);
  if T.Status <> stok then XAbort('hell');
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
  h.negSum := crc;
  T.Seek(0);
  T.Write(h,SizeOf(h));
  T.Done;
  writeln('SSG operation complete');
end.
