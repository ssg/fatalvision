uses Objects,Debris,XStr,XIO,XVFS;

var
  dirinfo:TVFSSearchRec;
  header:string;
begin
  XAppInit('VFS Dump','1.00a','SSG',1,'filename[.VFS]');
  if not InitVFS(XAddExt(ParamStr(1),'.VFS')) then XAbort('vfs init error');
  if not VFS^.FindFirst('*.*',dirinfo) then XAbort('no files in vfs');
  header := Fix('File',32)+
            Fix('Size',10)+
            Fix('Date/Time',14)+
            Fix('CRC32',8);
  writeln(header+#13#10+Duplicate('-',length(header)));
  repeat
    with dirinfo do writeln(Fix(Name,30)+
                            RFix(l2s(Size),8)+'  '+
                            Date2Str(LongRec(time).Hi,false)+' '+Time2Str(longrec(time).Lo,false,true)+'  '+
                            HexL(CRC));
  until not VFS^.FindNext(dirinfo);
end.