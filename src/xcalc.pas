{
Name            : XCalc 1.1d
Purpose         : Replacement to old calculator
Coder           : SSG

Update Info:
------------
21st Nov 93 - 01:00 - Perfected... Thanks to Borland..
24th Mar 94 - 01:20 - *** Adapted and fixed a bug...
 6th Jul 94 - 05:20 - *** Fixed some shitty bugs...
                      (some were really strange)
10th Nov 94 - 22:36 - *** Fixed a bug again...
29th Oct 94 - 19:21 - Adapted to new button inits...
                      Don't miss "Ordinary World" from Duran Duran...
                      (by the way my backspace has been fucked up)
}

unit XCalc;

{$O+}

interface

uses

XTypes,
GDrivers,   {font ops}
Drivers,    {tevent}
Debris,     {adjuststrsize}
Graph,      {paints}
Objects,    {trect}
GView,      {other things}
Tools;      {very other things}

type

  TCalcState = (csFirst, csValid, csError);

  PCalcDisplay = ^TCalcDisplay;
  TCalcDisplay = object(TView)
    Status: TCalcState;
    Number: string[15];
    Sign: Char;
    Operator: Char;
    Operand: Real;
    Width  : Byte;
    constructor Init(x,y:integer;AWidth:byte);
    procedure   CalcKey(var Event:TEvent);
    procedure   Clear;
    procedure   Paint; virtual;
    procedure   HandleEvent(var Event: TEvent); virtual;
  end;

  PCalculator = ^TCalculator;
  TCalculator = object(TDialog)
    constructor Init;
  end;

const

  Ctx_Calculator : word = hcNoContext;

implementation

const
  Rid_FontLCD  = 3;
  Rid_PowerOn  = 901;
  Rid_PowerOff = 900;
  clShadowCount = 2;
  clGAP         = 2;

  cmCalcBase    = 65500;
  KeyChar: array[0..19] of Char =
    '789/C456*'#27'123-%0.=+'#241;

constructor TCalcDisplay.Init(x,y:integer;AWidth:byte);
var
  R:TRect;
begin
  R.Assign(0,0,GetStringSize(Rid_FontLCD,'0')*AWidth+(clShadowCount shl 1),
               GetFontHeight(Rid_FontLCD)+((clShadowcount+clGAP) shl 1));
  R.Move(x,y);
  TView.Init(R);
  Options := Options or Ocf_PreProcess;
  EventMask := evKeyDown + evCommand;
  Width     := AWidth;
  Clear;
end;

procedure TCalcDisplay.CalcKey(var Event:TEvent);
var
  R: Real;
  Key:Char;

procedure Error;
begin
  Status := csError;
  Number := 'Error';
  Sign := ' ';
end;

procedure SetDisplay(R: Real);
var
  S: string[63];
begin
  Str(R: 0: 10, S);
  if S[1] <> '-' then Sign := ' ' else
  begin
    Delete(S, 1, 1);
    Sign := '-';
  end;
  if Length(S) > 15 + 1 + 10 then Error
  else
  begin
    while S[Length(S)] = '0' do Dec(S[0]);
    if S[Length(S)] = '.' then Dec(S[0]);
    Number := S;
  end;
end;

procedure GetDisplay(var R: Real);
var
  E: Integer;
begin
  Val(Sign + Number, R, E);
end;

procedure CheckFirst;
begin
  if Status = csFirst then
  begin
    Status := csValid;
    Number := '0';
    Sign := ' ';
  end;
end;

begin
  Key := UpCase(Event.Charcode);
  if (Status = csError) and (Key <> 'C') then Key := ' ';
  case Key of
    '0'..'9':
      begin
        CheckFirst;
        if Number = '0' then Number := '';
        Number := Number + Key;
      end;
    '.':
      begin
        CheckFirst;
        if Pos('.', Number) = 0 then Number := Number + '.';
      end;
    #8, #27:
      begin
        CheckFirst;
        if Length(Number) = 1 then Number := '0' else Dec(Number[0]);
      end;
    '_', #241:
      if Sign = ' ' then Sign := '-' else Sign := ' ';
    '+', '-', '*', '/', '=', '%', #13:
      begin
        if Status = csValid then
        begin
          Status := csFirst;
          GetDisplay(R);
          if Key = '%' then
            case Operator of
              '+', '-': R := Operand * R / 100;
              '*', '/': R := R / 100;
            end;
          case Operator of
            '+': SetDisplay(Operand + R);
            '-': SetDisplay(Operand - R);
            '*': SetDisplay(Operand * R);
            '/': if R = 0 then Error else SetDisplay(Operand / R);
          end;
        end;
        Operator := Key;
        GetDisplay(Operand);
      end;
    'C': Clear;
   else exit;
  end;
  Paint;
  ClearEvent(Event);
end;

procedure TCalcDisplay.Clear;
begin
  Status := csFirst;
  Number := '0';
  Sign := ' ';
  Operator := '=';
end;

procedure TCalcDisplay.Paint;
var
  R:TRect;
  OldR:TRect;
  n:byte;
  s:string;
begin
  if not GetState(Scf_Exposed) then exit;
  PaintBegin;
    GetExtent(R);
    for n:=1 to clShadowCount do begin
      ShadowBox(R,False);
      R.Grow(-1,-1);
    end;
    SetFillStyle(SolidFill,cBlack);
    SetTextColor(cLightGreen,cBlack);
    OldR  := R;
    R.B.Y := R.A.Y + clGAP;
    XBox(R,True);
    R := OldR;
    R.A.Y := R.B.Y - clGAP;
    XBox(R,True);
    r := Oldr;
    inc(R.A.Y,clGAP);
    s := Sign+Number;
    AdjustStrSize(s,width,Stf_RJust,0);
    XPrintStr(r.a.x,r.a.y,r.b.x-r.a.x+1,Rid_FontLCD,s);
  PaintEnd;
end;

procedure TCalcDisplay.HandleEvent(var Event: TEvent);
var
  P:PView;
begin
  TView.HandleEvent(Event);
  case Event.What of
    evKeyDown:CalcKey(Event);
    evCommand:
      if Event.Command >= cmCalcBase then
      begin
        Event.Charcode := KeyChar[Byte(Event.Command - cmCalcBase)];
        CalcKey(Event);
        ClearEvent(Event);
      end;
  end;
end;

{ TCalculator }

constructor TCalculator.Init;
var
  I: Integer;
  P: PView;
  R: TRect;
  Display: PCalcDisplay;
begin
  R.Assign(0,0,0,0);
  TDialog.Init(R, 'Hesap Makinesi');
  Options := Options or Ocf_FirstClick or Ocf_Centered;
  for I := 0 to 19 do begin
    R.A.X := (I mod 5) * 34 + 5;
    R.A.Y := (I div 5) * 24 + 50;
    P := New(PButton, Init(R.A.x,r.a.y, KeyChar[I], cmCalcBase+I));
    P^.Options := P^.Options and not Ocf_Selectable;
    Insert(P);
  end;
  New(Display, Init(5,5,18));
  Display^.GetBounds(R);
  R.A.Y := R.B.Y + 2;
  P := New(PDoubleVIFButton,Init(R.A.x,r.a.y,Rid_PowerOn,Rid_PowerOff,cmClose));
  P^.Options := P^.Options and not Ocf_Selectable;
  Insert(P);
  Insert(Display);
  FitBounds;
  HelpContext := Ctx_Calculator;
end;

end.