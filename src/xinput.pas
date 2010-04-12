{
Name    : X/Input 1.00a
Purpose : Old inputline routines are here.
Coder   : FatalicA
Moved by: SSG
Date    : 6th May 97
Time    : 04:36
}
{$N+,E+}

unit XInput;

interface

uses

  Debris,Graph,XStr,XTypes,XGfx,Drivers,GView,XOld,Objects;

type

  PInputStr = ^TInputStr;
  TInputStr = Object(TView)
    Prompt     : PString;
    Data       : PString;
    Source     : pointer;
    PaintFlags : Word;
    MaxLen     : Byte;
    Pos        : Byte;
    ScrX       : Byte;
    FirstPos   : Byte;
    PromptSize : Word;

    {init & done}
    Constructor Init(X,Y,Len:Integer;
		     APrompt:String; AMaxLen:Byte;
		     AConfig:Word);
    Destructor  Done; virtual;

    {event management methods}
    Procedure   HandleEvent(Var Event:TEvent); virtual;
    procedure   AddChar(C:Char); virtual;
    procedure   InsChar(C:Char); virtual;
    procedure   DelChar(P:Byte);
    procedure   ReplaceChar(C:Char);
    function    IncPos:Boolean;
    function    DecPos:Boolean;
    procedure   GoHome;
    procedure   GoEnd;
    procedure   BackDel; virtual;
    procedure   Del; virtual;
    procedure   DelEOL; virtual;
    procedure   DelLine; virtual;

    {set & gets}
    Procedure   GetData(Var Rec); virtual;
    Procedure   SetData(Var Rec); virtual;
    Function    DataSize:Word; virtual;
    procedure   SetState(AState:Word; Enable:Boolean); virtual;
    function    Modified:Boolean;
    function    Null:Boolean;
    function    GetPaintableData(Var S:String; APos:Byte):Byte; virtual;
    procedure   GetCursorXY(Var T:TPoint; APos:Byte);
    procedure   GetTxtFrame(Var R:TRect);
    procedure   GetTxtBounds(Var R:TRect);
    procedure   GetScrollBounds(Var LR,RR:TRect);

    {paint methods}
    procedure   PaintScroll(PLeft,PRight:Boolean);
    procedure   PaintPrompt(AFocused:Boolean);
    procedure   PaintTxt(S:String);
    procedure   Paint; virtual;

    private
    function    TurnUpper(c:char):char;
  end;  {inputline}

  PInputNum = ^TInputNum;
  TInputNum = Object(TInputStr)
    NumType : Byte;
    Dig,Dec : Byte;
    RelPos  : Byte;
    {init}
    constructor Init(X,Y,Len:Integer; APrompt:String; ANumType:Byte;
                     Digit1,Digit2:Byte; AConfig:Word);
    {set & gets}
    procedure   SetState(AState:Word; Enable:Boolean); virtual;
    procedure   GetData(var Rec); virtual;
    procedure   SetData(var Rec); virtual;
    function    DataSize:Word; virtual;
    function    GetPaintableData(var S:String; APos:Byte):Byte; virtual;

    {event management}
    procedure   BackDel; virtual;
    procedure   Del; Virtual;
    procedure   InsChar(C:Char); virtual;
    procedure   AddChar(C:Char); virtual;
  end;  {inputnum}

  PInputMask = ^TInputMask;
  TInputMask = Object(TInputStr)
    Mask : PString;
    Constructor Init(X,Y,Len:Integer;
		     APrompt:String; AMask:String;
		     AConfig:Word);
    Destructor  Done; virtual;
    procedure   AddChar(C:Char); virtual;
    procedure   SetState(AState:Word; Enable:Boolean); virtual;
    function    GetPaintableData(Var S:String; APos:Byte):Byte; virtual;
  end; {inputmask}

implementation

{ TInputStr }
constructor TInputStr.Init(X,Y,Len:Integer; APrompt:String; AMaxLen:Byte; AConfig:Word);
var
  R : TRect;
  A : Integer;
  S : String;
begin
  R.Assign(X,Y,X,Y);
  inc(R.B.Y,ViewFontHeight+1);
  if Len = 0 then Len := AMaxLen;
  A := Len;
  inc(A,Length(APrompt));
  if AConfig and Idc_NoScroll = 0 then begin
   if Len < AMaxLen then begin inc(A,2); AConfig := AConfig or Idc_ShowScroll; end
		    else AConfig := AConfig and Not Idc_ShowScroll;
  end else AConfig := AConfig and Not Idc_ShowScroll;
  inc(R.B.X, ViewFontWidth*A+3);
  inherited Init(R);
  Prompt    := NewStr(APrompt);
  MaxLen    := AMaxLen;
  ScrX      := Len;
  if Prompt <> NIL then PromptSize:= GetStringSize(ViewFont,Prompt^);
  GetMem(Data,MaxLen+1);
  Data^[0]  := #0;
  Options   := Options or Ocf_Selectable + Ocf_FirstClick + Ocf_PaintFast;
  EventMask := evMouseDown or evMessage or evKeyDown;
  Config    := AConfig;
  ViewType  := VtInputLine;
  HelpContext := Ctx_InputLine;
end;

function TInputStr.TurnUpper;
begin
  if GetConfig(Idc_English) then TurnUpper := upcase(c)
                            else TurnUpper := upcase(c);
end;

destructor TInputStr.Done;
begin
  if Prompt<> Nil then DisposeStr(Prompt);
  if Data  <> Nil then FreeMem(Data,MaxLen+1);
  inherited Done;
end;

{--------------------------- HANDLE EVENTS ------------------------}
Procedure TInputStr.HandleEvent(Var Event:TEvent);

    Procedure HandleCommands(Var E:TEvent);
      begin
      end;

    procedure HandleBroadCasts(Var E:TEvent);
      begin
	case E.Command of
	 Brc_IsModified : if Modified then E.InfoPtr := @Self
			  else exit;
	 Brc_IsValid    : if Not Valid(E.Command) then E.InfoPtr := @Self
			  else Exit;
	 Brc_IsNull     : if Null then E.InfoPtr := @Self
			  else exit;
	 Brc_ResetModified : begin SetConfig(Idc_Modified,False); exit; end;
	else
	  exit;
	end;
	ClearEvent(E);
      end;
    procedure HandleKeys(Var E:TEvent);
      var
	A : Byte;
	B : Byte;
	S : String;
	F : Boolean;
      Begin
       S := Data^;
       B := Pos;
{       A := System.Pos(E.CharCode,AKeyCodesMap);
       if A > 0 Then E.KeyCode := AKeyCodes[A];}
       case E.KeyCode of
	KbLeft     : if DecPos then exit;
	KbRight    : if incPos then exit;
	KbHome     : GoHome;
	KbEnd      : GoEnd;
	KbDel      : Del;
	KbBack     : BackDel;
	KbShiftDel : DelLine;
	KbCtrlDel  : DelEOL;
	KbIns      : SetState(scf_CursorIns,Not GetState(Scf_CursorIns));
       else
	 if E.CharCode > #31 then AddChar(E.CharCode)
			     else exit;
       end; {case}
       if GetConfig(Idc_ReadyToDel) then SetConfig(Idc_ReadyToDel,False);
       if (S <> Data^) then begin
	 SetConfig(Idc_Modified,True);
	 SetConfig(Idc_DataChanged,True);
         Message(Owner,evBroadcast,cmInputlineChanged,@Self);
       end else SetConfig(Idc_DataChanged,False);
       PaintView;
       ClearEvent(E);
      end;
    procedure HandleMouse(Var E : TEvent);
      Var
	R,R1  : TRect;
	LR,RR : TRect;
	X     : Integer;
	E1    : TEvent;
	A     : Byte;
      Begin
	   if Options and Ocf_Selectable = 0 then exit;
	   MakeLocal(E.Where,E.Where);
	   repeat
	    A := Pos;
	    if GetConfig(Idc_ShowScroll) then begin
	      GetScrollBounds(LR,RR);
	      if (PaintFlags and Idc_PaintLeft > 0) and
		 LR.Contains(E.Where) then DecPos;
	      if (PaintFlags and Idc_PaintRight > 0) and
		 RR.Contains(E.Where) then IncPos;
	    end; {scroll present check}
	    GetTxtBounds(R1);
	    if R1.Contains(E.Where) then begin
	      X   := (E.Where.X - R1.A.X) div ViewFontWidth;
	      Pos := FirstPos + X;
	      if Pos > length(data^) then Pos := length(data^);
	    end; {second contains}

	    if A <> Pos then begin
	      if GetConfig(Idc_ReadyToDel) then SetConfig(Idc_ReadyToDel,False);
	      PaintView;
	    end;
	    GetEvent(E1);
	    if E1.What <> EvNothing then begin
	      E := E1;
	      MakeLocal(E.Where, E.Where);
	    end;
	   until E.What = EvMouseUp;
      end;

{  HANDLEEVENT MAIN BEGIN }

    Begin
       TView.HandleEvent(Event);
       case Event.What of
	 EvKeyDown   : HandleKeys(Event);
	 EvBroadCast : HandleBroadCasts(Event);
	 EvCommand   : HandleCommands(Event);
       else
	 if (Event.What and EvMouse) > 0 then HandleMouse(Event);
       end;
    End;

procedure TInputStr.InsChar(C:Char);
    begin
     if length(data^) >= MaxLen then dec(byte(data^[0]));
     Insert(C,Data^,Pos+1);
     IncPos;
    end;

procedure TInputStr.DelChar(P:Byte);
    begin
      if P > 0 then begin
	Delete(Data^,P,1);
	DecPos;
      end;
    end;

procedure TInputStr.ReplaceChar(C:Char);
    begin
     if Pos < MaxLen then begin
       if Pos=length(data^) then InsChar(C)
			   else Data^[Pos+1] := C;
       IncPos;
     end;
    end;

function TInputStr.IncPos:Boolean;
    begin
      IncPos := True;
      if MaxLen > 1 then
       if Pos < length(data^) then Inc(Pos)
			     else Exit
      else Exit;
      IncPos := False;
    end;

function TInputStr.DecPos:Boolean;
    begin
      if Pos > 0 then begin
	Dec(Pos);
	DecPos := False;
      end else DecPos := True;
    end;

procedure TInputStr.GoHome;
    begin
      Pos := 0;
    end;

procedure TInputStr.GoEnd;
    begin
       Pos := length(data^);
    end;

procedure TInputStr.AddChar(C:Char);
    begin
      if GetConfig(Idc_ReadyToDel) then Data^ := '';
      if GetConfig(Idc_Upper) then C := TurnUpper(C) else
      if GetConfig(Idc_FirstUpper) then begin
	if (Pos > 0) and not (Data^[Pos] =#32) then
	  c := LoCase(C) else c:= TurnUpper(C);
      end;
      if GetState(Scf_CursorIns) then InsChar(C)
				 else ReplaceChar(C);
    end;

procedure TInputStr.BackDel;
    begin
      if length(data^) = 0 then exit;
      if Pos > 0 then begin
       DelChar(Pos);
       SetConfig(Idc_Scroll,True);
      end else if GetConfig(Idc_AdvancedDel) then Del;
    end;

procedure TInputStr.Del;
    Var
      A : Byte;
    begin
     if GetConfig(Idc_ReadyToDel) then begin Data^ := ''; exit; end;
     A := length(data^);
     if A = 0 then exit;
     if Pos < A then begin
       A := Pos+1;
       Delete(Data^,A,1);
     end else if GetConfig(Idc_AdvancedDel) then BackDel;
    end;

procedure TInputStr.DelEOL;
    var
     A,B : Byte;
    begin
      B := Pos + 1;
      A := length(data^);
      if A > B then Delete(Data^,B,255);
    end;

procedure TInputStr.DelLine;
    begin
      Data^ := '';
      Pos   := 0;
    end;

Procedure TInputStr.GetData(Var Rec);
    begin
      String(Rec) := Data^;
    end;

Procedure TInputStr.SetData(Var Rec);
var
  b:byte;
  newword : boolean;
    begin
      if String(Rec) = Data^ then exit; {!!!!!!!!!!!!!!!!!!!!!!!!!!}
      {if Byte(Rec) > MaxLen then Data^ := Copy(String(Rec),1,MaxLen)
			    else }Data^ := String(Rec);
      if GetConfig(Idc_FirstUpper) then begin
	newword := true;
	for b:=1 to Length(Data^) do begin
	  if NewWord then begin
	    Data^[b] := TurnUpper(Data^[b]);
	    NewWord := False;
	  end else begin
	    Data^[b] := Locase(Data^[b]);
	    if (Data^[b] =#32) then NewWord := True;
	  end;
	end;
      end;
      SetConfig(Idc_Modified,False);
      GoHome;
      PaintView;
    end;

Function TInputStr.DataSize:Word;
    begin
      DataSize := MaxLen + 1;
    end;

procedure TInputStr.SetState(AState:Word; Enable:Boolean);
    begin
      TView.SetState(AState,Enable);
      if GetState(Scf_Exposed) and (AState and Scf_Focused > 0) then begin
	if Enable then State := State or Scf_CursorVis
		  else State := State and Not Scf_CursorVis;
	if GetConfig(Idc_ResetOnFocus) then begin
	  State := State and Not Scf_CursorIns;
	  GoHome;
	end;
	SetConfig(Idc_ReadyToDel,GetConfig(Idc_PreDel) and Enable);
	PaintView;
      end;
    end;

function TInputStr.Modified:Boolean;
    begin
      Modified := GetConfig(Idc_Modified);
    end;

function TInputStr.Null:Boolean;
    begin
      Null := data^ = '';
    end;

function TInputStr.GetPaintableData(Var S:String; APos:Byte):Byte;
    Var
      A : Byte;
    begin
      A := APos;
      if A = MaxLen then Dec(A);
      if GetConfig(Idc_Scroll) then begin
	SetConfig(Idc_Scroll,False);
	if FirstPos > 0 then dec(FirstPos);
      end;
      if A < FirstPos then FirstPos := A
      else if A >= (FirstPos + ScrX) then FirstPos := A - ScrX + 1;
      if FirstPos > 0 then PaintFlags := PaintFlags or Idc_PaintLeft
                      else PaintFlags := PaintFlags and not Idc_PaintLeft;
      if FirstPos+ScrX < length(s) then PaintFlags := paintFlags or Idc_PaintRight
                                   else PaintFlags := PaintFlags and not Idc_PaintRight;
      S := Copy(S, FirstPos + 1, 255);
      if Length(S) < ScrX then S := S+Duplicate(#32,ScrX - Length(S));
      GetPaintableData := A;
    end;

procedure TInputStr.GetCursorXY(Var T:TPoint; APos:Byte);
    begin
      APos := APos - FirstPos;
      if APos = ScrX then dec(APos);
      if Prompt <> Nil then Inc(APos,length(prompt^));
      T.X := APos*ViewFontWidth+2;
      T.Y := 0;
      if GetConfig(Idc_ShowScroll) then inc(T.X,ViewFontWidth);
    end;

procedure TInputStr.GetTxtFrame(Var R:TRect);
    begin
      R.Assign(0,0,Size.X,Size.Y);
      if Prompt <> Nil then inc(R.A.X, PromptSize+2);
    end;

procedure TInputStr.GetTxtBounds(Var R:TRect);
    begin
      GetTxtFrame(R);
      if GetConfig(Idc_ShowScroll) then begin
	Inc(R.A.X,ViewFontWidth);
	Dec(R.B.X,ViewFontWidth);
      end;
      R.Grow(-1,-1); {ssg was here}
      inc(r.b.x);
    end;
procedure TInputStr.GetScrollBounds(Var LR,RR:TRect);
    begin
      GetTxtFrame(LR);
      RR := LR;
      inc(LR.A.X); Inc(RR.A.X);
      inc(LR.A.Y); inc(RR.A.Y);
      LR.B.X := LR.A.X + ViewFontWidth;
      RR.A.X := RR.B.X - ViewFontWidth;
    end;
procedure TInputStr.PaintScroll(PLeft,PRight:Boolean);
    Var
      LR,RR : TRect;
      S     : String[1];
    begin
      GetScrollBounds(LR,RR);
      if GetConfig(Idc_ShowScroll) then begin
	SetTextColor(Col_InputScroll,Col_Back);
	if PLeft then S := '<'
		 else S := ' ';
	XWriteStr(LR.A.X, LR.A.Y, LR.B.X - LR.A.X, S);
	if PRight then S := '>'
		  else S := ' ';
	XWriteStr(RR.A.X, RR.A.Y, RR.B.X - RR.A.X, S);
      end;
    end;
procedure TInputStr.PaintPrompt(AFocused:Boolean);
    Var
      R : TRect;
    begin
      GetTxtFrame(R);
      ShadowBox(R,AFocused);
      if Prompt = Nil then exit;
      R.Assign(0,0,Size.X,Size.Y);
      R.B.X := R.A.X + PromptSize + 1;
      if AFocused then SetTextColor(Col_InputPromptActive,Col_Back)
		  else SetTextColor(Col_InputPromptPassive,Col_Back);
      SetColor(Col_Back);
      XRectangle(R.A.X, R.A.Y, R.B.X, R.B.Y);
      inc(R.A.X);
      inc(R.A.Y);
      XWriteStr(R.A.X, R.A.Y, R.B.X - R.A.X, Prompt^);
    end;
procedure TInputStr.PaintTxt(S:String);
    Var
      R : TRect;
      strsize : integer;
    begin
      if GetConfig(Idc_Password) then FillChar(S[1], Length(Data^), Psw_Char);
      GetTxtBounds(R);
      if GetConfig(Idc_ReadyToDel) then begin
        SetTextColor(Col_InputLine,cLightGreen);
        SetFillStyle(SolidFill,Col_Back);
        Strip(S);
        strsize := GetStringSize(ViewFont,S);
        XWriteStr(R.A.X, R.A.Y, strsize, S);
        inc(r.a.x,strsize);
        dec(r.b.x);
        XBox(R,True);
      end else begin
        SetTextColor(Col_InputLine,Col_Back);
        XWriteStr(R.A.X,R.A.Y,R.B.X-R.A.X,S);
      end;
    end;

procedure TInputStr.Paint;
    Var
      S : String;
      T : TPoint;
      A : Byte;
    begin
      PaintBegin;
      S := Data^;
      A := GetPaintableData(S,Pos);
      GetCursorXY(T,A);
      PaintPrompt(State and Scf_Focused > 0);
      PaintScroll(PaintFlags and Idc_PaintLeft > 0,
		  PaintFlags and Idc_PaintRight > 0);
      PaintTxt(S);
      SetCursor(T.X, T.Y);
      PaintEnd;
    end;

{---------------------------------------------------------------------------}
{->                          TINPUTNUMBER                                 <-}
{---------------------------------------------------------------------------}
Constructor TInputNum.Init(X,Y,Len:Integer; APrompt:String; ANumType:Byte; Digit1,Digit2:Byte; AConfig:Word);
    Var
      ML : Byte;
    begin
      ML := Digit1;  {+1 for minus sign (-)}
      if Digit2 > 0 then inc(ML,Digit2+1);
      if Len = 0 then begin
	Len := ML;
	if AConfig and Idc_Business > 0 then inc(Len,(Digit1-1) div 3)
      end;
      TInputStr.Init(X,Y,Len,APrompt,ML,AConfig);
      NumType := ANumType;
      Dig     := Digit1;
      Dec     := Digit2;
    end;
procedure TInputNum.SetState(AState:Word; Enable:Boolean);
    begin
      if AState and Scf_CursorIns > 0 then
       if Enable then exit;
      TInputStr.SetState(AState,Enable);
    end;
Procedure TInputNum.GetData(Var Rec);
var
  s:string;
    begin
      s := Data^;
      if GetConfig(Idc_Business) then Distill(s,',');
      Case NumType of
        Stf_ShortInt  : ShortInt(Rec) := s2l(s);
        Stf_Byte      : Byte(Rec)     := s2l(s);
        Stf_Integer   : Integer(Rec)  := s2l(s);
        Stf_Word      : Word(Rec)     := s2l(s);
        Stf_LongInt   : LongInt(Rec)  := s2l(s);
        Stf_Single    : Single(Rec)   := s2x(s);
        Stf_Real      : Real(Rec)     := s2x(s);
        Stf_Double    : Double(Rec)   := s2x(s);
        Stf_Extended  : Extended(Rec) := s2x(s);
        Stf_Comp      : Comp(Rec)     := s2x(s);
      else
	exit;
      end;
    end;
Procedure TInputNum.SetData(Var Rec);
 Var
  S  : String;
    begin
    S:='';
      Case NumType of
	Stf_ShortInt  : S:=l2s(ShortInt(Rec));
	Stf_Byte      : S:=l2s(Byte(Rec));
	Stf_Integer   : S:=l2s(Integer(Rec));
	Stf_Word      : S:=l2s(Word(Rec));
	Stf_LongInt   : S:=l2s(LongInt(Rec));
	Stf_Single    : S:=x2s(Single(Rec),Dig,Dec);
	Stf_Real      : S:=x2s(Real(Rec),Dig,Dec);
	Stf_Double    : S:=x2s(Double(Rec),Dig,Dec);
	Stf_Extended  : S:=x2s(Extended(Rec),Dig,Dec);
	Stf_Comp      : S:=x2s(Comp(Rec),Dig,Dec);
      else
	exit;
      end;
      if Length(S) > MaxLen then S := Copy(S,1,MaxLen);
      if S = Data^ then exit;
      Data^:=S;
      GoHome;
      PaintView;
    end;
Function TInputNum.DataSize:Word;
    begin
      Case NumType Of
	Stf_ShortInt,
	Stf_Byte      : DataSize := SizeOf(Byte);
	Stf_Integer,
	Stf_Word      : DataSize := SizeOf(Word);
	Stf_LongInt   : DataSize := SizeOf(Longint);
	Stf_Single    : DataSize := SizeOf(Single);
	Stf_Real      : DataSize := SizeOf(Real);
	Stf_Double    : DataSize := SizeOf(Double);
	Stf_Extended  : DataSize := SizeOf(Extended);
	Stf_Comp      : DataSize := SizeOf(Comp);
      else
	DataSize := 0;
      end;
    end;
procedure TInputNum.BackDel;
    begin
      if length(data^) > 0 then
	if (Data^[Pos] = '.') and (Pos < length(data^)) then begin DecPos; exit; end;
      TInputStr.BackDel;
    end;
procedure TInputNum.Del;
    Var
      A : Byte;
    begin
      if length(data^) > 0 then begin
       A := Pos+1;
       if (Data^[A] = '.') and (A < length(data^)) then exit;
      end;
      TInputStr.Del;
    end;
procedure TInputNum.InsChar(C:Char);
    Var
      CDig,CDec : Byte;
      A         : Byte;
    begin
      if (C < '0') or (C > '9') then begin
	TInputStr.InsChar(C);
	exit;
      end;
      asm
	       push    ds
	       cld
	       les     di,Self
	       lds     si,es:[di].TInputNum.Data
	       xor     ah,ah
	       mov     CDig,ah
	       mov     CDec,ah
	       mov     A,ah
	       lodsb
	       mov     cx,ax
	       jcxz    @Esc
	       lea     bx,CDig
@Loop:         lodsb
	       cmp     al,'0'
	       jb      @1
	       cmp     al,'9'
	       ja      @1
	       inc     byte ptr ss:[bx]
	       jmp     @L
@1:            cmp     al,'.'
	       jnz     @L
	       lea     bx,CDec
	       mov     dx,si
	       sub     dx,word ptr es:[di].TInputNum.Data
	       dec     dl
	       mov     A,dl
@L:            Loop    @Loop
@Esc:          pop     ds
      end;
      if (A=0) or ((A > 0) and (Pos < A)) then
	if CDig < Dig then TInputStr.InsChar(C)
	else
      else if CDec < Dec then TInputStr.InsChar(C);
    end;
procedure TInputNum.AddChar(C:Char);
    Var
      A : Byte;
    begin
{      if C=DecPoint then C := '.';}
      if C in ['-', '.', '0'..'9'] then
	if GetConfig(Idc_ReadytoDel) then Data^ := '';
      Case C Of
	'-' : begin
		A := system.pos(C,Data^);
		if A = 0 then begin
		 if length(data^) < MaxLen then begin
		   Insert(C,Data^,1);
		   IncPos;
		 end;
		end else begin
		 Delete(Data^,A,1);
		 DecPos;
		end;
	      end;
	'.' : if Dec > 0 then begin
		 A := system.Pos('.',Data^);
		 if A > 0 then Pos := A
		 else if Pos >= length(data^) then InsChar('.');
	      end;
   '0'..'9' : if Data^[Pos+1] = '.' then InsChar(C)
				    else ReplaceChar(C);
      end;
    end;

function TInputNum.GetPaintableData(Var S:String; APos:Byte):Byte;
    begin
      if GetConfig(Idc_Business) then ConvertNumToBusiness(S);
      asm
	  push    ds
	  les     di,Self
	  lds     si,es:[di].TInputNum.Data
	  les     di,S
	  inc     di
	  cld
	  lodsb
	  or      al,al
	  jz      @Esc
	  xor     ch,ch
	  mov     ah,APos
	  mov     cl,ah
	  inc     cl
	  cmp     cl,al
	  jbe     @Loop2
	  mov     cl,al
@Loop2:   lodsb
@Loop1:   scasb
	  jz      @1
	  inc     ah
	  jmp     @Loop1
@1:       loop    @Loop2
	  mov     APos,ah
@Esc:     pop     ds
      end;
      if (APos = Length(S)) and (length(data^) < MaxLen) then S := S + ' ';
      if Length(S) < ScrX then begin
	Inc(APos,ScrX - Length(S));
	S := Duplicate(#32,ScrX - Length(S)) + S;
      end;
      if GetConfig(Idc_Scroll) then begin
	SetConfig(Idc_Scroll,False);
	if APos > RelPos then FirstPos := APos - RelPos
			 else FirstPos := 0;
      end else begin
	if APos < FirstPos then FirstPos := APos
	else if APos >= FirstPos + ScrX then FirstPos := APos - ScrX + 1;
	if Length(S) < FirstPos + ScrX then FirstPos := Length(S) - ScrX;
	RelPos := APos - FirstPos;
      end;
      PaintFlags := PaintFlags and not (idc_PaintLeft+idc_PaintRight);
      if FirstPos > 0 then paintFlags := PaintFlags or idc_PaintLeft else
      if FirstPos+ScrX < length(s) then paintFlags := paintFlags or idc_PaintRight;
      S := Copy(S,FirstPos + 1, 255);
      GetPaintableData := APos;
    end;

{---------------------------------------------------------------------------}
{->                          TINPUTMASK                                   <-}
{---------------------------------------------------------------------------}
Constructor TInputMask.Init(X,Y,Len:Integer;
			    APrompt, AMask:String;
			    AConfig:Word);
    Var
      ML : Byte;
      I  : Byte;
      A  : Byte;
    begin
      if AMask = '' then fail;
      ML := 0;
{      for I:=1 to Length(AMask) do begin
       A := system.pos(UpCase(AMask[I]), EditMaskChars);
       if A > 0 then begin
	 AMask[I] := Char(A);
	 inc(ML);
       end;
      end;}
      if Len = 0 then Len := Length(AMask);
      TInputStr.Init(X,Y,Len,APrompt,ML,AConfig);
      Mask := NewStr(AMask);
    end;
Destructor TInputMask.Done;
    begin
      if Mask <> Nil then DisposeStr(Mask);
      TInputStr.Done;
    end;
procedure TInputMask.SetState(AState:Word; Enable:Boolean);
    begin
      if AState and Scf_CursorIns > 0 then
       if Enable then exit;
      TInputStr.SetState(AState,Enable);
    end;
procedure TInputMask.AddChar(C:Char);
    Var
      A,N,I : Byte;
    begin
      A := Pos+1;
      I := 0;
      N := 0;
      while (I < Length(Mask^)) and (N<A) do begin
	inc(I);
	if Mask^[I] < #32 then inc(N);
      end;
      N := Byte(Mask^[I]);
{      if C in MaskCharSets[N] then ReplaceChar(C);}
    end;
function TInputMask.GetPaintableData(Var S:String; APos:Byte):Byte;
    Var
      I,N : Byte;
      C   : Char;
    begin
      if length(data^) < MaxLen then Data^ := Data^ + Duplicate(#32,MaxLen - length(data^));
      S := '';
      N := 1;
      For I:=1 to Length(Mask^) do begin
	if N > length(data^) then C := ' '
			    else C := Data^[N];
	if Mask^[I] > #31 then S := S+Mask^[I]
			  else begin S := S+C; inc(N); end;
      end;
      asm
	  push    ds
	  cld
	  les     di,Self
	  lds     si,es:[di].TInputNum.Data
	  les     di,S
	  inc     di
	  lodsb
	  or      al,al
	  jz      @Esc
	  xor     ch,ch
	  mov     ah,APos
	  mov     cl,ah
	  inc     cl
	  cmp     cl,al
	  jbe     @Loop2
	  mov     cl,al
@Loop2:   lodsb
@Loop1:   scasb
	  jz      @1
	  inc     ah
	  jmp     @Loop1
@1:       loop    @Loop2
	  mov     APos,ah
@Esc:     pop     ds
      end;
      N := MaxLen;
      MaxLen := Length(Mask^);
      GetPaintableData := TInputStr.GetPaintableData(S,APos);
      MaxLen := N;
    end;

end.