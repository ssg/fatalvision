{
Name    : X/Prn 1.04f
Purpose : Extended Printer Functions
Coders  : SSG, FatalicA & Wiseman

Update Info:
------------
21st Mar 94 - 10:45 - Added EndPrint & Prn_SetupRec to AutoFeed varaible ...
21st Mar 94 - 11:50 - AutoFeed and some proc controls by WiseMan
21st Mar 94 - 23:05 - Ulan SSG GetPageStop <>1 ha oldun oglum.. Artik Okey..
                      (WM) O-(:)
06th May 94 - 00:35 - Fixed a bug in DonePrinter.... (SSG)
11th Jul 94 - 16:17 - Changed setup screen layout... (SSG)
27th Jul 94 - 16:27 - Fixed a bug in setups... (SSG)
11th Nov 94 - 11:31 - Updated to new proc names...
22rd Mar 96 - 02:12 - Removed loadPrnSetup...
22rd Mar 96 - 02:17 - Adam edildi..
22rd Mar 96 - 02:44 - Rewritten setup...
 1st Oct 96 - 14:20 - Removed all the junk...
24th Jul 97 - 10:42 - Fixed a small bug
31st Jul 97 - 12:43 - Made code more stable...
}

{$C MOVEABLE DEMANDLOAD DISCARDABLE}
{$O+}

unit XPrn;

interface

const

  TransSource = 'òçûü¶ßöÅôîÄá';
  TransDest   = 'IiSsGgUuOoCc';

  PrnAbort  : boolean = false;

  prnFile : string[12] = 'PRN';

procedure BeginPrint;
procedure EndPrint;
procedure WritePrn(s:string);
procedure PrintBitmap(var bitmap; width,height:word);

implementation

uses

  Objects,XSys,XBuf,XTypes,Tools,XStream;

const

  Printer    : PDosStream = NIL;
  PrnOK      : boolean = false;
  prnGfxMode : char = 'L'; {L/Z}

procedure PrintBitmap;
const
  prnc772LineSpacing : array[1..2] of char = #27+'1';
begin
  if not PrnOK then exit;
  Printer^.Write(prnc772LineSpacing,SizeOf(prnc772LineSpacing));

end;

procedure BeginPrint;
begin
  PrnAbort  := false;
  PrnOK     := true;
  if Printer <> NIL then Dispose(Printer,Done);
  New(Printer,Init(prnFile,stCreate));
  if Printer^.Status <> stOK then begin
    PrnAbort  := true;
    Dispose(Printer,Done);
    Printer := NIL;
    PrnOK     := false;
  end;
end;

procedure EndPrint;
begin
  PrnAbort := False;
  if Printer <> NIL then begin
    Dispose(Printer,Done);
    Printer := NIL;
  end;
end;

procedure WritePrn(s:string);
var
  code:word;
begin
  if Printer = NIL then Error('WritePrn','Call before BeginPrint');
  if s = '' then s := ' ';
  while not PrnAbort do begin
    TranslateBuf(s[1],length(s),0,32);
    SWriteln(Printer^,s);
    if Printer^.Status <> stOk then begin
      code := MessageBox('Printer''da hata var. Tekrar deneyeyim mi?',0,
        mfWarning+mfYesNo);
      PrnAbort := not (code = cmYes);
      if code = cmYes then Printer^.Reset;
    end else begin
      PrnOK := true;
      break;
    end;
  end;
end;

end.
