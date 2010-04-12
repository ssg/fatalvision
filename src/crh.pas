{
Name            : CRH 1.3e
Purpose         : Critical Error Handler
Coder           : SSG
Date            : 18th Aug 93

Update Info:
------------
30th Oct 93 - 01:20 - *** Fixed some return_code bugs in handler...
18th Nov 93 - 01:20!- Converted messages to Turkish.......
04th Dec 93 - 15:20 - *** Fixed some return_code bugs in handler...
                      (sad but true : the same bug - the same solution)
27th Dec 93 - 01:10 - *** Fixed some coding bugs in handler...
                      (I need 4MB for Syndicate)
10th Jan 93 - 01:31 - Adding extended runtime handler...
21st Feb 94 - 11:00 - Declared new critical error handler method...
 9th Sep 94 - 19:36 - *** Fixed some bugs in handler...
16th Nov 94 - 00:46 - *** Fixed a recursion bug in mess'box...
27th Oct 94 - 02:29 - Made Baston compatible...
 5th Nov 94 - 00:08 - Converted messages to Turkish...
10th Nov 94 - 12:05 - Removed Dos unit linkage...
13th Nov 94 - 22:31 - Added RunErr 216...
18th Dec 94 - 11:57 - There's a bug I didn't understand after executing
                      a CRH messageBox... I will try to fix it...
27th Aug 97 - 22:44 - a little touch in the code... (nothing at all)
}

{$F+}

unit CRH;

interface

const

  CRHEnabled : boolean = true;

procedure InitCRH;
procedure DoneCRH;

implementation

uses

  XIO,XTypes,Objects,Drivers,Tools;

const

   Ret_Abort   = 2;
   Ret_Retry   = 1;
   Ret_Ignore  = 0;

const
  In24 : boolean = false;

procedure GetCriticalError(Err:Integer;Disk:byte;var s:string);far;
const
  cs : string[15] = '%c sÅrÅcÅsÅnde ';
var
  G:char;
begin
  G := char(Disk+65);
  case Err of
    0 : s := cs+'yazma koruma hatasç';
    1 : s := cs+'kritik hata';
    2 : s := cs+'disket yok';
    3 : s := cs+'kritik hata';
    4 : s := cs+'veri hatasi';
    5 : s := cs+'kritik hata';
    6 : s := cs+'arama hatasç';
    7 : s := '%c surucusu bilinmiyor';
    8 : s := cs+'sektîr bulunamadç';
    9 : s := 'Yazçcçda kaßçt yok';
   10 : s := '%c sÅrÅcÅsÅne yazçlamçyor';
   11 : s := cs+'okuma hatasç';
   12 : s := cs+'donançm hatasç';
   13 : s := 'FAT hatasç';
   14 : s := 'Donançm eriüim hatasç';
   15 : s := cs+'disket yok';
    else s := 'Bilinmeyen hata';
  end;
  FormatStr(S,S,G);
end;

function XSysError(ErrorCode:integer;Drive:Byte):integer;far;
var
  s:string[80];
const
  Exitc:word=0;
begin
  if In24 then exit;
  In24 := true;
  if not crhEnabled then begin
    XSysError := 1;
    exit;
  end;
  GetCriticalError(ErrorCode,Drive,s);
  if GSystem <> NIL then
    Exitc := XMessageBox(^c+s,0,mfWarning+mfRetryButton+mfAbortButton);
  if Exitc = cmRetry then XSysError := 0 {retry}
                     else XSysError := 1; {fail}
  In24 := false;
end;

procedure InitCRH;
begin
  InitSysError;
  SysErrorFunc := XSysError;
end;

procedure DoneCRH;
begin
  DoneSysError;
end;

end.
