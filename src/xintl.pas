{
Name    : X/Intl 1.00b
Purpose : International functions
Coder   : SSG
Date    : 30th Dec 96
Time    : 04:59
}

unit XIntl;

interface

type

  TDateFormat     = (dfMDY, dfDMY, dfYMD);
  TCurrencyFormat = (cfPre, cfFol, cfPreSpace, cfFolSpace, cfDecimalSep);

  TCountryInfo = record
    CodePage       : word;
    CountryId      : byte;
    CurrencyFormat : TCurrencyFormat;
    DateFormat     : TDateFormat;
    CurrencyStr    : string[4];
    CurrencyDigits : byte;
    ThousandsSep   : char;
    DecimalSep     : char;
    DateSep        : char;
    TimeSep        : char;
    Hour24         : boolean;
  end;

const

  CountryInfo : TCountryInfo = (
    CodePage       : 0;
    CountryId      : 0;
    CurrencyFormat : cfPre;
    DateFormat     : dfDMY;
    CurrencyStr    : '$';
    CurrencyDigits : 0;
    ThousandsSep   : ',';
    DecimalSep     : '.';
    DateSep        : '/';
    TimeSep        : ':';
    Hour24         : true);

function  XIntlUpCase(c:char):char;
procedure XIntlFastUpper(var s:string);

implementation

uses

{$IFDEF DPMI}
  WinAPI, XDPMI, XBuf, Objects,
{$ENDIF}
  Strings;

type

  TDosCountryInfo = record
    SubFunc    : byte;
    BufferSize : word;
    CountryId  : byte;
    CodePage   : word;
    Date       : word;
    Currency   : array[0..4] of char;
    Thousands  : array[0..1] of char;
    Decimals   : array[0..1] of char;
    Dates      : array[0..1] of char;
    Times      : array[0..1] of char;
    CurSym     : byte;
    CurPlaces  : byte;
    Hour24     : boolean;
    MapAddr    : pointer;
    Lists      : array[0..1] of char;
    Reserved   : array[0..9] of char;
  end;

{$IFNDEF DPMI}
procedure XGetCountryInfo(var info:TDosCountryInfo);assembler;
asm
  xor  bx,bx
  not  bx
  mov  cx,type TDosCountryInfo
  mov  dx,bx
  les  di,info
  mov  ax,6501h
  mov  es:[di],al
  int  21h
  pop  ds
end;
{$ELSE}
procedure XGetCountryInfo(var info:TDosCountryInfo);
var
  handle:longint;
  regs:TRealModeRegs;
begin
  handle := GlobalDosAlloc(SizeOf(info));
  info.SubFunc := 1;
  asm
    push ds
    mov  cx,type TDosCountryInfo
    cld
    xor  di,di
    mov  ax,word ptr handle
    mov  es,ax
    lds  si,info
    rep  movsb
    pop  ds
  end;
  ClearBuf(regs,SizeOf(regs));
  with regs do begin
    eax := $6501;
    es  := longrec(handle).hi;
    ebx := -1;
    edx := -1;
    ecx := SizeOf(info);
  end;
  RealModeInt($21,regs);
  GlobalDosFree(handle);
end;
{$ENDIF}

procedure XIntlInit;
var
  dos:TDosCountryInfo;
begin
  XGetCountryInfo(dos);
  with CountryInfo do begin
    CodePage  := dos.CodePage;
    CountryId := dos.CountryId;
    CurrencyFormat := TCurrencyFormat(dos.CurSym);
    DateFormat     := TDateFormat(dos.Date);
    CurrencyStr    := StrPas(@dos.Currency);
    CurrencyDigits := dos.CurPlaces;
    ThousandsSep   := dos.Thousands[0];
    DecimalSep     := dos.Decimals[0];
    DateSep        := dos.Dates[0];
    TimeSep        := dos.Times[0];
    Hour24         := dos.Hour24;
  end;
end;

function XIntlUpCase;assembler;
asm
  mov  ax,6520h
  mov  dl,c
  int  21h
  mov  al,dl
end;

procedure XIntlFastUpper;assembler;
asm
  push ds
  lds  si,s
  mov  cl,[si]
  xor  ch,ch
  mov  dx,si
  inc  dx
  mov  ax,6521h
  int  21h
  pop  ds
end;

end.