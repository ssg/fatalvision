{ id to longint converter }
var
  s:string[4];
  c:array[1..4] of char;
  l:longint absolute c;
begin
  write('Enter id (4 chars): ');
  readln(s);
  move(s[1],c,4);
  writeln('id = ',l);
end.