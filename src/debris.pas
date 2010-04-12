{
Name               : Debris 1.3e
Purpose            : All small jobs is done here...
Date               : 09th Sep 1993
Coder              : SSG

updates:
-------
21st Jan 97 - 01:02 - Rewritten almost all the code...
}

unit Debris;

interface

procedure ConvertNumToBusiness(Var S : String);
function  cn2b(s:String):string;

function  Date2Str(time:longint; full:boolean):String;
function  Time2Str(time:longint):String;

function  HexB(H:Byte):string;
function  HexW(H:Word):string;
function  HexD(H:Pointer):string;
function  HexL(L:longint):string;
function  BinB(B:Byte):string;
function  BinW(B:word):string;

function  GetSysMoment:longint;
function  CompareMoment(m1,m2:longint):integer;
function  GetSysDate:Word;
function  GetSysTime:Word;

implementation

uses XIntl,Objects,XStr,Dos;

function cn2b;
begin
  ConvertNumToBusiness(s);
  cn2b := s;
end;

function Time2Str;
var
  d:DateTime;
begin
  UnpackTime(time,d);
  with d do Time2Str := z2s(Hour,2)+CountryInfo.TimeSep+z2s(Min,2);
end;

function Date2Str;
var
  d:DateTime;
  realyear:word;
  realyeardigits:byte;
  c:char;
begin
  UnpackTime(time,d);
  if full then begin
    realyear := d.Year;
    realyeardigits := 4;
  end else begin
    realyear := d.Year-1900;
    realyeardigits := 2;
  end;
  c := CountryInfo.DateSep;
  with d do case CountryInfo.DateFormat of
    dfMDY : Date2Str := z2s(Month,2)+c+z2s(Day,2)+c+z2s(realyear,realyeardigits);
    dfYMD : Date2Str := z2s(realyear,realyeardigits)+c+z2s(Month,2)+c+z2s(Day,2);
    else Date2Str := z2s(Day,2)+c+z2s(Month,2)+c+z2s(realyear,realyeardigits);
  end;
end;

Procedure ConvertNumToBusiness(Var S : String); assembler;
    var
      S1 : String;
    Asm
         push    ds
         pushf
         mov     al,CountryInfo.DecimalSep
         mov     ah,CountryInfo.ThousandsSep
         lds     si,S
         mov     cl,[si]
         or      cl,cl
         jz      @@Exit
         xor     ch,ch
         add     si,cx
         les     di,S
         inc     di
         cld
         push    cx
         repnz   scasb
         mov     dx,ss
         mov     es,dx
         mov     dx,di
         lea     di,S1[255]
         jnz     @1
         mov     cx,si
         sub     cx,dx
         inc     cx
         inc     cx
         pop     dx
         sub     dx,cx
         push    dx
         std
         repz    movsb
@1:      pop     cx
         jcxz    @@Exit
         mov     dl,04
         std
@@Loop1: lodsb
         cmp     al,'0'
         jb      @2
         cmp     al,'9'
         ja      @2
         dec     dl
         jnz     @2
         mov     dl,03
         xchg    ah,al
         stosb
         xchg    ah,al
@2:      stosb
         Loop    @@Loop1
         mov     si,di
         mov     ax,es
         mov     ds,ax
         les     di,S
         lea     cx,S1[255]
         sub     cx,si
         cld
         mov    al,cl
         stosb
         inc    si
         repz   movsb
@@Exit:  popf
         pop     ds
    End;

{-----------------------------------------------------------------------}
Function HexB(H:Byte):string;
    begin
     asm
       les    di,@Result
       mov    byte ptr es:[di],02
       inc    di
       mov    al,H
       mov    ah,al
       and    ax,$0FF0;
       mov    cl,4
       shr    al,cl
       add    ax,$3030
       cmp    al,$39
       jbe    @1
       add    al,07
@1:    cmp    ah,$39
       jbe    @2
       add    ah,07
@2:    mov    es:[di],ax
     end;
    end;
 
Function HexW(H:Word):string;
    begin
     HexW := HexB(Hi(H))+HexB(Lo(H));
    end;
 
function HexL;
begin
  HexL := HexW(LongRec(L).Hi)+HexW(LongRec(L).Lo);
end;

Function HexD(H:Pointer):string;
    begin
     HexD := HexW(LongRec(H).Hi)+':'+HexW(LongRec(H).Lo);
    end;
 
Function BinB(B:Byte):string;
   begin
    asm
    les   di,@Result
    cld
    mov   al,8
    mov   cl,al
    xor   ch,ch
    stosb
    mov   bl,B
    mov   bh,'0'
@L1:mov   al,bh
    shl   bl,1
    jnb   @1
    inc   al
@1: stosb
    Loop @L1
    end;
   end;

Function BinW(B:word):string;
   begin
    BinW := BinB(hi(B))+':'+BinB(lo(B));
   end;

function GetSysMoment;
var
  d:DateTime;
  hb:word;
  l:longint;
begin
  asm
    cld
    mov  ax,ss
    mov  es,ax
    lea  di,d
    mov  ah,2ah
    int  21h
    mov  ax,cx
    stosw
    mov  al,dh
    xor  ah,ah
    stosw
    mov  al,dl
    stosw
    mov  ah,2ch
    int  21h
    mov  al,ch
    xor  ah,ah
    stosw
    mov  al,cl
    stosw
    mov  al,dh
    stosw
  end;
  PackTime(d,l);
  GetSysMoment := l;
end;
{asm
  mov  ah,2ah
  int  21h
  xor  bh,bh
  mov  bl,dh
  xor  dh,dh
  shl  bx,5
  or   dx,bx
  shl  cx,9
  or   dx,cx
  mov  bx,dx
  mov  ah,2ch
  int  21h
  xor  ax,ax
  shr  dh,1
  or   al,dh
  mov  dh,ch
  xor  ch,ch
  shl  cx,5
  or   ax,cx
  xor  cx,cx
  mov  cl,dh
  shl  cx,11
  or   ax,cx
  mov  dx,bx
end;}

function GetSysdate:word;assembler;
asm
  call GetSysMoment
  mov ax,dx
end;

function GetSysTime:word;assembler;
asm
  call GetSysMoment
end;

function CompareMoment;
var
  d1,d2:datetime;
begin
  UnPackTime(m1,d1);
  UnPackTime(m2,d2);
  if d1.Year > d2.year then CompareMoment := 1 else
  if d1.Year < d2.year then CompareMoment := -1 else
  if d1.Month > d2.Month then CompareMoment := 1 else
  if d1.Month < d2.Month then CompareMoment := -1 else
  if d1.Day > d2.Day then CompareMoment := 1 else
  if d1.Day < d2.Day then CompareMoment := -1 else
  if d1.Hour > d2.Hour then CompareMoment := 1 else
  if d1.Hour < d2.Hour then CompareMoment := -1 else
  if d1.Min > d2.Min then CompareMoment := 1 else
  if d1.Min < d2.Min then CompareMoment := -1 else
  if d1.Sec > d2.Sec then CompareMoment := 1 else
  if d1.Sec < d2.Sec then CompareMoment := -1 else
  CompareMoment := 0;
end;

end.
