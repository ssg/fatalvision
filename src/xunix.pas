{
Name    : X/Unix 1.00a
Purpose : Unix date/time conversion implementation
Coder   : SSG
Date    : 12th Mar 96
Time    : 17:13
}

unit XUnix;

interface

uses Dos;

function DOS2Unix(var T:DateTime):longint;
procedure Unix2DOS(adate:longint; var T:DateTime);
function GregorianToJuliandN(Year, Month, Day:integer):longint;

implementation

const

   C1970 = 2440588;
   D0    =    1461;
   D1    =  146097;
   D2    = 1721119;

function GregorianToJuliandN(Year, Month, Day:integer):longint;
var
  Century,
  XYear    : LongInt;
begin {GregorianToJuliandN}
  If Month <= 2 then begin
    Year := pred(Year);
    Month := Month + 12;
    end;
  Month := Month - 3;
  Century := Year div 100;
  XYear := Year mod 100;
  Century := (Century * D1) shr 2;
  XYear := (XYear * D0) shr 2;
  GregorianToJuliandN := ((((Month * 153) + 2) div 5) + Day) + D2
                                    + XYear + Century;
end; {GregorianToJuliandN}

procedure JuliandNToGregorian(JuliandN : LongInt;var Year, Month, Day : Integer);
var
  Temp,
  XYear   : LongInt;
  YYear,
  YMonth,
  YDay    : Integer;
begin {JuliandNToGregorian}
  Temp := (((JuliandN - D2) shl 2) - 1);
  XYear := (Temp mod D1) or 3;
  JuliandN := Temp div D1;
  YYear := (XYear div D0);
  Temp := ((((XYear mod D0) + 4) shr 2) * 5) - 3;
  YMonth := Temp div 153;
  If YMonth >= 10 then begin
    YYear := YYear + 1;
    YMonth := YMonth - 12;
    end;
  YMonth := YMonth + 3;
  YDay := Temp mod 153;
  YDay := (YDay + 5) div 5;
  Year := YYear + (JuliandN * 100);
  Month := YMonth;
  Day := YDay;
end; {JuliandNToGregorian}

function DOS2Unix;
var
   secspast, datenum, dayspast: LONGINT;
   s: STRING;
begin
  datenum := GregorianToJuliandN(T.year,T.month,T.day);
  dayspast := datenum - c1970;
  secspast := dayspast * 86400;
  secspast := secspast + T.hour * 3600 + T.min * 60 + T.sec;
  DOS2Unix := secspast;
end;

procedure Unix2DOS;
var
   secspast, datenum: longint;
   n: word;
begin
   secspast := adate;
   datenum := (secspast DIV 86400) + c1970;
   JulianDNToGregorian(datenum,integer(T.year),integer(T.month),integer(T.day));
   secspast := secspast MOD 86400;
   T.hour := secspast DIV 3600;
   secspast := secspast MOD 3600;
   T.min := secspast DIV 60;
   T.sec := secspast MOD 60;
end;

end.