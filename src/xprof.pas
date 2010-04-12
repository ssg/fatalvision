{
Name    : XProf 1.00b
Purpose : Profile handler
Coder   : SSG
Date    : 15th Dec 94

update info:
------------
15th Dec 94 - 19:10 - Rejuvenated the code in trash...
28th Apr 95 - 14:16 - Retouched the code...
}

unit XProf;

interface

uses XStream,XStr,Objects;

const

  ClassLeft  = '[';
  ClassRight = ']';
  ParamSep   = '=';
  Remark     = ';';
  MaxLineLen = 79;

type

  prstr = string[MaxLineLen];

  PProfile = ^TProfile;
  TProfile = object(TDosStream)
    LastClass   : prstr;
    LastWhere   : longint;
    function    ok:boolean;
    function    GoClass(class:prstr):boolean;
    function    GetStr(class,param:prstr):string;
    function    GetLInt(class,param:prstr):longint;
    function    GetBool(class,param:prstr):boolean;
  end;

implementation

function TProfile.ok;
begin
  ok := Status = stOK;
end;

function TProfile.GoClass(class:prstr):boolean;
var
  line:prstr;
begin
  GoClass := true;
  Reset;
  Seek(0);
  FastUpper(class);
  if class = LastClass then begin
    Seek(lastWhere);
    exit;
  end;
  while Status = stOK do begin
    SReadln(Self,line);
    if Status = stOK then begin
      Strip(line);
      if line[1] = '[' then begin
        dec(byte(line[0]));
        Delete(line,1,1);
        FastUpper(line);
        if line = class then begin
          LastClass := class;
          LastWhere := GetPos;
          exit;
        end;
      end;
    end;
  end;
  GoClass := false;
end;

function TProfile.GetBool;
var
  s:string;
begin
  s := GetStr(class,param);
  FastUpper(s);
  GetBool := (s='TABII KI') or
             (s='TRUE') or
             (s='YES') or
             (s='ON') or
             (s='EVET');
end;

function TProfile.GetLInt;
var
  l:longint;
  code:integer;
begin
  Val(GetStr(class,param),l,code);
  GetLInt := l;
end;

function TProfile.GetStr;
var
  s : prstr;
  procedure GetParam;
  var
    b:byte;
    sl:prstr;
  begin
    while Status = stOK do begin
      SReadln(Self,s);
      if Status = stOK then begin
        b := pos(remark,s);
        if b > 0 then Delete(s,b,255);
        Strip(s);
        b := pos(ParamSep,s);
        if b > 0 then begin
          sl := copy(s,1,b-1);
          Strip(sl);
          if Upper(sl) = param then begin
            s := copy(s,b+1,255);
            Strip(s);
            exit;
          end;
        end else if s[1] = classLeft then exit;
      end else s := '';
    end;
  end;
begin
  GetStr := '';
  s := '';
  if Status <> stOK then Reset;
  FastUpper(Param);
  if not GoClass(class) then exit;
  GetParam;
  GetStr := s;
end;

end.