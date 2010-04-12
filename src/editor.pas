{
Name  : Editor 1.0
Date  : 15th May 94
Time  : 12:30
Coder : WiseMan

Update Info:
------------
15th May 94 - 01:25 - Added ScrollBar and a new logic TEditView object.
}
Unit Editor;
Interface
 Uses Crt,Objects,GRaph,Tools,GView,Debris,XTypes,GDrivers,Drivers,XBuf;
Const
 MaxBuffer = MaxInt-1;

Type
 PByteArray = ^TByteArray;
 TByteArray = Array[0..MaxBuffer] of Byte;

 PScrollBar = ^TScrollBar;
 TScrollBar = Object(TView)
  LinkView       : PView;
  MaxCount,Count : Word;
  OneR,TriR,
  UseRect        : TRect;
  VH             : Word;
  MiddleT        : TPoint;
  MidX,MidY      : Integer;
  Constructor Init(X,Y,MaxLen : Integer;AVertHorz:Word);
  Procedure   HandleEvent(Var Event : TEvent); Virtual;
  Procedure   SetState(AState:Word; Enable:Boolean); Virtual;
  Procedure   Paint; Virtual;
  Procedure   SetCount(ACount : Word);
  Function    GetCount : Word;
  Procedure   SetMaxCount(ACount : Word);
  Procedure   SetLinkView(P : PView);
 End;
(**************************** Editor Base Object ***************************)
 PEditView = ^TEditView;
 TEditView = Object(TView)
  Buffer      : Pointer;
  BufSize     : Word;
  Col,Row     : Word;
  CurX,CurY   : Word;
  MainR       : Trect;
  InsertMode  : Boolean;    { Editing Mode Insert=True else Overwrite }
  DelOk       : Boolean;
  CRLine      : Boolean;
  Constructor Init(Var Bounds:TRect;ABufSize:Word);
  Destructor  Done; Virtual;
  Procedure   HandleEvent(Var Event : TEVent); Virtual;
  Procedure   SetState(AState:Word; Enable:Boolean); Virtual;
  Procedure   SetData(Var Rec); Virtual;
  Procedure   GetData(Var Rec); Virtual;
  Function    DataSize: Word; Virtual;
  Procedure   Paint; Virtual;
  Function    Modified : Boolean;
  Procedure   VFastPaint;
  Procedure   SetCurXY;
  Function    AllSpace(Var Buf;Len : Word) : Boolean;
  Procedure   IncCurX;
  Procedure   IncCurY;
  Procedure   DecCurX;
  Procedure   DecCurY;
  Procedure   ICurX;
  Procedure   ICurY;
  Procedure   DCurX;
  Procedure   DCurY;
  Procedure   EnterProc;
  Procedure   WordWrap;
  Procedure   InsertChar(Ch : Char);
  Procedure   DelLine;
  Procedure   BackDel;
  Procedure   DelWord;
  Procedure   DelChar;
  Procedure   DelEOL;
  Procedure   DelRight;
  Procedure   LeftRightWrap(FF : Boolean);
  Procedure   EndWrap;
  Procedure   AddStr(Var S : String);
 End;

 PEditorData = ^TEditorData;
 TEditorData = Record
  Len  : Word;
  Data : TByteArray;
 End;

Const
  Bar_ScrollUp      = 18000;
  Bar_ScrollDown    = 18001;
  Bar_ScrollLeft    = 18002;
  Bar_ScrollRight   = 18003;
  Bar_ScrollRandom  = 18004;

(***************************************************************************)
Implementation

Const
  cmBarUp   = 19000;
  cmBarDown = 19001;
  cmMiddle  = 19002;

  UpButton      = Rid_ScrollerPgUp;
  DownButton    = Rid_ScrollerPgDn;
  MiddleButton  = Rid_ScrollerHome;

  AKeyCodesMap   : String[8] = ^S+^D+^G+^H+^Y+^E+^V+^Q;
  AKeyCodes      : Array[1..8] of word = (KbLeft,KbRight,KbDel,KbBack,KbShiftDel,KbCtrlDel,KbIns,KbCtrlBack);

Constructor TScrollBar.Init(X,Y,MaxLen : Integer;AVertHorz:Word);
 Var R         : TRect;
     LenX,LenY : Integer;
    Begin
     if MaxLen<50 then MaxLen:=50;
     R.Assign(0,0,0,0);
     Inherited Init(R);
     Options:=Options or ocf_FirstClick;
     Options:=Options and Not Ocf_Selectable;
     MaxCount:=1;
     Count   :=0;
     VH      :=AVertHorz;
     GetExtent(R);
     Case VH of
      mnfHorizontal:Begin
                     R.Assign(X,Y,X+MaxLen,Y+15);
                     ChangeBounds(R);LenX:=R.B.X-R.A.X;LenY:=R.B.Y-R.A.Y;
                     OneR.Assign(1,1,15,LenY-1);
                     UseRect.Assign(16,1,LenX-16,LenY-2);
                     TriR.Assign(LenX-15,1,LenX,LenY-1);
                     MiddleT.X:=16;MiddleT.Y:=1;
                     MidX:=15;MidY:=LenY-2;
                    End;
        mnfVertical:Begin
                     R.Assign(X,Y,X+15,Y+MaxLen);
                     ChangeBounds(R);LenX:=R.B.X-R.A.X;LenY:=R.B.Y-R.A.Y;
                     OneR.Assign(1,1,LenX-1,15);
                     UseRect.Assign(1,16,LenX-2,LenY-16);
                     TriR.Assign(1,LenX-15,LenX,LenY-1);
                     MiddleT.X:=1;MiddleT.Y:=16;
                     MidY:=15;MidX:=LenX-2;
                    End;
     End; {Case}
    End;
Procedure TScrollBar.SetLinkView(P : PView);
    Begin
     if XInit(P) then LinkView:=P;
    End;
Procedure TScrollBar.SetCount(ACount : Word);
    Begin
     if MaxCount<ACount then MaxCount:=ACount;
     Count:=ACount;Paint;
    End;
Procedure TScrollBar.SetState(AState:Word; Enable:Boolean);
    Begin
     Inherited SetState(AState,Enable);
     if AState and Scf_Focused > 0 then
        if State and Scf_Exposed > 0 then
           if XInit(LinkView) then LinkView^.Select(NullEvent);
    End;

Procedure TScrollBar.Paint;
 Var Len  : Integer;
     T    : TPoint;
     R    : TRect;

 Procedure PaintUpButton;
    Begin
     SetFillStyle(SolidFill,cBlue);
     XBar(OneR.A.X,OneR.A.Y,OneR.B.X,OneR.B.Y);
    End;
 Procedure PaintDownButton;
    Begin
     SetFillStyle(SolidFill,cBlue);
     XBar(TriR.A.X,TriR.A.Y,TriR.B.X,TriR.B.Y);
    End;
 Procedure PaintMiddleButton;
    Begin
     SetFillStyle(SolidFill,cBlue);
     XBar(MiddleT.X,MiddleT.Y,MiddleT.X+MidX,MiddleT.Y+MidY);
    End;

    Begin
     Inherited Paint;
     PaintBegin;
     T:=MiddleT;
      Case VH of
         mnfVertical:T.Y:=UseRect.A.Y+Round(((UseRect.B.Y-UseRect.A.Y-MidY)/MaxCount)*Count);
       mnfHorizontal:T.X:=UseRect.A.X+Round(((UseRect.B.X-UseRect.A.X-MidX)/MaxCount)*Count);
      End; {Case}
     MiddleT:=T;
     PaintUpButton;PaintDownButton;
     GetExtent(R);ShadowBox(R,False);
     SetFillStyle(SolidFill,col_Back);
     With UseRect do XBar(A.X,A.Y,B.X,B.Y);
     PaintMiddleButton;PaintEnd;
    End;
Procedure TScrollBar.SetMaxCount(ACount : Word);
    Begin
     if ACount<=0 then Exit;MaxCount:=ACount;PaintView;
    End;
Function TScrollBar.GetCount : Word;
    Begin
     GetCount:=Count;
    End;
Procedure TScrollBar.HandleEvent(Var Event : TEvent);
Var  Ok   : Boolean;
     E    : TEvent;
     T    : TPoint;
     R    : Trect;
 Procedure DecCount;
    Begin
     if Count>0 then Begin Dec(Count);SetCount(Count);End;
     if XInit(LinkView) then
     if VH=mnfHorizontal then XMessage(LinkView,evBroadCast,Bar_ScrollLeft,@Self,Nil)
                         else XMessage(LinkView,evBroadCast,Bar_ScrollUp,@Self,Nil);
    End;
 Procedure IncCount;
    Begin
     if Count<MaxCount then Begin Inc(Count);SetCount(Count);End;
     if XInit(LinkView) then
     if VH=mnfHorizontal then XMessage(LinkView,evBroadCast,Bar_ScrollRight,@Self,Nil)
                         else XMessage(LinkView,evBroadCast,Bar_ScrollDown,@Self,Nil);
    End;
 Function CalcT(TT : TPoint) : Integer;
    Begin
    if VH=mnfHorizontal then CalcT:=Round((TT.X-UseRect.A.X)/((UseRect.B.X-UseRect.A.X)/MaxCount))
                        else CalcT:=Round((TT.Y-UseRect.A.Y)/((UseRect.B.Y-UseRect.A.Y)/MaxCount));
    End;

    Begin
     Inherited HandleEvent(Event);
     Case Event.What of
        evCommand:Case Event.Command of
                      cmBarUp:DecCount;
                    cmBarDown:IncCount;
                   else Exit;
                  End;
      evMouseDown:Case Event.Command of
                    evMouseDown:Begin
                                 MakeLocal(Event.Where,T);
                                 SetCount(CalcT(T));
                                 Repeat
                                  GetMouseEvent(E);
                                  Ok := (E.What = evMouseup);
                                  if (E.What=evMouseMove) and (MouseInView(E.Where)) then
                                  Begin
                                   MakeLocal(E.Where,T);
                                   R.A:=T;R.B:=T;R.Grow(1,1);
                                   R.Intersect(UseRect);
                                   if Not R.Empty then SetCount(CalcT(T));
                                  End; {if}
                                  XMessage(LinkView,evBroadCast,Bar_ScrollRandom,@Self,Nil);
                                 Until OK;
                                End; {evMouseDown}
                   else Exit;
                  End;
       Else Exit;
     End; {Case}
     ClearEvent(Event);
    End;

(****************************** Editor View ********************************)
Constructor TEditView.Init(Var Bounds:TRect;ABufSize:Word);
 Var R  : TRect;
    Begin
     Inherited Init(Bounds);
     SetState(Scf_CursorVis,True);
     Options:=Options or Ocf_Selectable or Ocf_PaintFast or ocf_FirstClick;
     EventMask := evMouseDown or evBroadcast or Evc_MaskMessage or evKeyDown;
     BufSize:=ABufSize;
     Col:=(Bounds.B.X-Bounds.A.X) div ViewFontWidth;
     Row:=(Bounds.B.Y-Bounds.A.Y) div ViewFontHeight;
     R:=Bounds;
     R.Assign(R.A.X,R.A.Y,R.A.X+Col*ViewFontWidth+1,R.A.Y+Row*ViewFontHeight+1);
     ChangeBounds(R);
     if BufSize > MaxBuffer then BufSize:=MaxBuffer;
     if BufSize = 0 then BufSize:=Row*Col;
     Buffer:=Nil;
     GetMem(Buffer,BufSize+1);
     FillChar(PByteArray(Buffer)^[0],BufSize+1,#32);
     CurX:=0;CurY:=0;
     GetExtent(MainR);
     DelOk:=False;
     InsertMode:=False;
     CRLine:=False;
    End;

Procedure TEditView.SetState(AState:Word; Enable:Boolean);
    Begin
     Inherited SetState(AState,Enable);
     if AState and Scf_Focused > 0 then
        if State and Scf_Exposed > 0 then Begin
          if Enable then State := State or Scf_CursorVis
		    else State := State and Not Scf_CursorVis;
      PaintView;
     End; {if}
    End;

Procedure TEditView.SetCurXY;
    Begin
     if GetState(Scf_Focused) then
      if Not CRLine then SetCursor(CurX*ViewFontWidth+1,CurY*ViewFontHeight+1)
                    else Begin
                          SetCursor((Col-1)*ViewFontWidth+1,(CurY-1)*ViewFontHeight+1);
                          CRLine:=False;
                         End;
    End;

Procedure TEditView.Paint;
 Var S    : String;
     VP   : Word;
     n    : Byte;
     R    : Trect;
    Begin
     PaintBegin;SetCurXY;
     if GetState(Scf_Focused) then SetTextColor(cWhite,cBlue)
                              else SetTextColor(cBlack,col_Back);
     ShadowBox(MainR,False);
     VP:=0;FillChar(S,SizeOf(S),#32);
     For n:=0 to Row-1 do Begin
      Move(PByteArray(Buffer)^[VP],S[1],Col);S[0]:=Char(Col);VP:=VP+Col;
      XWriteStr(1,n*ViewFontHeight+1,Col*ViewFontWidth,S);
     End;
     PaintEnd;
    End;
Procedure TEditView.VFastPaint;
 Var S    : String;
     R    : Trect;
    Begin
     PaintBegin;S:='';SetCurXY;
     Move(PByteArray(Buffer)^[CurY*Col],S[1],Col);S[0]:=Char(Col);
     SetTextColor(cWhite,cBlue);
     XWriteStr(1,CurY*ViewFontHeight+1,Col*ViewFontWidth,S);
     PaintEnd;
    End;
Function TEditView.AllSpace(Var Buf;Len : Word) : Boolean; assembler;
    asm
      les      di,Buf
      cld
      mov      cx,Len
      mov      al,$20
      repz     scasb
      mov      al,0
      jnz      @Ext
      inc      al
@Ext:
    End;
Procedure TEditView.IncCurX;
    Begin
     if CurX<Col then Inc(CurX) else Exit;
     if CurX>=Col then Dec(CurX);
     VFastPaint;
    End;
Procedure TEditView.IncCurY;
    Begin
     if CurY<Row-1 then Inc(CurY) else Exit;
     Paint;
    End;
Procedure TEditView.DecCurX;
    Begin
     if CurX>0 then Dec(CurX) else Exit;
     VFastPaint;
    End;
Procedure TEditView.DecCurY;
    Begin
     if CurY>0 then Dec(CurY) else Exit;
     Paint;
    End;
Procedure TEditView.ICurX;
    Begin
     if CurX<Col then Inc(CurX) else Exit;
     if CurX>=Col then Dec(CurX);
     SetCurXY;
    End;
Procedure TEditView.ICurY;
    Begin
     if CurY<Row-1 then Inc(CurY) else Exit;
     SetCurXY;
    End;
Procedure TEditView.DCurX;
    Begin
     if CurX>0 then Dec(CurX) else Exit;
     SetCurXY;
    End;
Procedure TEditView.DCurY;
    Begin
     if CurY>0 then Dec(CurY) else Exit;
     SetCurXY;
    End;
Procedure TEditView.EnterProc;
  Var PosX,PosY,PosY1,PosY2 : Word;
      S                     : String;
    Begin
     if CurX=Col-1 then Begin CurX:=0;IncCurY;Exit;End;
     if CurY=Row-1 then Exit;
     SetConfig(Idc_Modified,True);
     SetConfig(Idc_DataChanged,True);
     PosX:=CurY*Col+CurX;PosY:=CurY*Col;
     if AllSpace(PByteArray(Buffer)^[PosX],BufSize-PosX) or Not InsertMode then Begin CurX:=0;ICurY;Exit;End;
     PosY1:=(CurY+1)*Col;PosY2:=(CurY+2)*Col;
     FillChar(S,SizeOf(S),#32);
     Move(PByteArray(Buffer)^[PosX],S[1],Col-CurX);S[0]:=Char(Col);
     Move(PByteArray(Buffer)^[PosY1],PByteArray(Buffer)^[PosY2],BufSize-PosY2);
     Move(S[1],PByteArray(Buffer)^[PosY1],Length(S));
     FillChar(PByteArray(Buffer)^[PosX],Col-CurX,#32);
     CurX:=0;IncCurY;
    End;
Procedure TEditView.WordWrap;
  Var Bo   : Boolean;
      Cx   : Word;
      PX   : Word;
      S    : String;
    Begin
     if CurY=Row-1 then Exit;
     Cx:=CurX;PX:=CurX;
     Repeat
      Bo:=(PByteArray(Buffer)^[(CurY*Col)+Cx]<>32);
      if Bo then Dec(Cx);
     Until Not Bo or (CX=0);
     if CX=0 then Begin Inc(CurY);CurX:=0;Exit;End;
     Cx:=CurY*Col+Cx;PX:=(Col*CurY)+CurX;
     Move(PByteArray(Buffer)^[Cx+1],S[1],PX-Cx);Byte(S[0]):=PX-Cx;
     Move(PByteArray(Buffer)^[Cx+1],PByteArray(Buffer)^[PX+1],BufSize-PX);
     FillChar(PByteArray(Buffer)^[Cx],PX-Cx+1,32);
     CurX:=PX-CX;if CurX>Col-1 then CurX:=Col-1;
     Inc(CurY);if CurY>Row-1 then CurY:=Row-1;
    End;
Procedure TEditView.InsertChar(Ch : Char);
  Var PosX   : Word;
      CX     : Word;
      Ok     : Boolean;
      BB     : Boolean;
    Begin
     SetConfig(Idc_Modified,True);
     SetConfig(Idc_DataChanged,True);
     PosX:=CurY*Col+CurX;
     if PosX=BufSize then Exit;
     if InsertMode then Begin
                         if PByteArray(Buffer)^[PosX-CurX+Col-1]=32 then Begin
                            CX:=Col-CurX;Ok:=False;
                         End else Ok:=True;
                         if Not Ok then Move(PByteArray(Buffer)^[PosX],PByteArray(Buffer)^[PosX+1],CX);
                        End else Ok:=False;
     if Not Ok then PByteArray(Buffer)^[PosX]:=Byte(Ch);
     if Ok and InsertMode then Begin
        if CurY<Row-1 then Begin CurX:=Col-1;WordWrap;InsertChar(Ch);End
                      else Begin Move(PByteArray(Buffer)^[PosX],PByteArray(Buffer)^[PosX+1],Col-CurX-1);
                                 PByteArray(Buffer)^[PosX]:=Byte(Ch);
                           End;
      Paint;Exit;
     End;
     Inc(CurX);
     if InsertMode then Begin BB:=CurX>Col;CRLine:=CurX>Col;End
                   else Begin BB:=CurX>Col-1;CRLine:=CurX=Col;End;
     if BB then Begin
                 CurX:=0;Inc(CurY);
                 if CurY>Row-1 then Begin Dec(CurY);CRLine:=False;CurX:=Col-1;End;
                End;
     if (CRLine) or (InsertMode and Ok) then Paint
                                        else VFastPaint;
    End;
Procedure TEditView.DelLine;
  Var PX,PX1  : Word;
    Begin
     SetConfig(Idc_Modified,True);
     SetConfig(Idc_DataChanged,True);
     PX:=CurY*Col;PX1:=(CurY+1)*Col;
     if CurY<>Row-1 then Begin
      Move(PByteArray(Buffer)^[PX1],PByteArray(Buffer)^[PX],BufSize-PX1);
      FillChar(PByteArray(Buffer)^[BufSize-Col],Col,#32);
      Paint;Exit;
     End;
     FillChar(PByteArray(Buffer)^[BufSize-Col],Col,#32);VFastPaint;
    End;
Procedure TEditView.BackDel;
  Var PosX   : Word;
      PX,PX1 : Word;
      S      : String;

    Begin
     if CurX<=0 then Begin
      if CurY>0 then Dec(CurY) else Exit;
      CurX:=Col;
     End;
     SetConfig(Idc_Modified,True);
     SetConfig(Idc_DataChanged,True);
     PosX:=CurY*Col+CurX-1;S:='';
     if CurY<Row-1 then Begin
      if CurX=Col then S:=' '
                  else Move(PByteArray(Buffer)^[PosX],S[1],Col-CurX+1);S[0]:=Char(Col-CurX+1);
      Delete(S,1,1);S:=S+' ';
      Move(S[1],PByteArray(Buffer)^[PosX],Length(S));Dec(CurX);
      if Not InsertMode then VFastPaint
         else Begin
               if AllSpace(PByteArray(Buffer)^[PosX],BufSize-PosX) and (CurX<Col) then
                Begin VFastPaint;Exit;End;
               Inc(PosX,Col-CurX);
               Move(PByteArray(Buffer)^[PosX],S[1],Col);S[0]:=Char(Col);
               TruncateStrSize(S,Stf_RJust);
               if S='' then Begin
                Inc(CurY);
                PX:=CurY*Col;PX1:=(CurY+1)*Col;
                if CurY<>Row-1 then Begin
                 Move(PByteArray(Buffer)^[PX1],PByteArray(Buffer)^[PX],BufSize-PX1);
                 FillChar(PByteArray(Buffer)^[BufSize-Col],Col,#32);
                End else FillChar(PByteArray(Buffer)^[BufSize-Col],Col,#32);
                Dec(CurY);Paint;Exit;
               End;
               VFastPaint;Exit;
              End;
      VFastPaint;Exit;
     End;
     Move(PByteArray(Buffer)^[PosX+1],PByteArray(Buffer)^[PosX],BufSize-PosX);
     PByteArray(Buffer)^[BufSize]:=32;Dec(CurX);Paint;
    End;
Procedure TEditView.DelWord;
  Var  WB,WK    : Word;
       PosX,CX  : Word;
       Ok       : Boolean;
       S        : String;

    Begin
     SetConfig(Idc_Modified,True);
     SetConfig(Idc_DataChanged,True);
     Cx:=Cury*Col+CurX;PosX:=Cx;
     if AllSpace(PByteArray(Buffer)^[Cx],BufSize-Cx) then Exit;
     WB:=CX;
     WK:=Cx+Col+(Col-CurX);
     Ok:=PByteArray(Buffer)^[PosX]<>32;
     if Ok then While (PByteArray(Buffer)^[WB]<>32) and (WB<WK) do Inc(WB);
     While (PByteArray(Buffer)^[WB]=32) and (WB<WK) do Inc(WB);
     Move(PByteArray(Buffer)^[WB],PByteArray(Buffer)^[PosX],WK-WB);
     FillChar(PByteArray(Buffer)^[PosX+WK-WB],WB-PosX,32);
     Move(PByteArray(Buffer)^[PosX+Col-CurX],S[1],Col);S[0]:=Char(Col);
     TruncateStrSize(S,Stf_RJust);
     if S='' then Begin
                   WB:=(CurY+1)*Col;WK:=(CurY+2)*Col;
                   if CurY<>Row-1 then Begin
                    Move(PByteArray(Buffer)^[WK],PByteArray(Buffer)^[WB],BufSize-WK);
                    FillChar(PByteArray(Buffer)^[BufSize-Col],Col,#32);
                   End else FillChar(PByteArray(Buffer)^[BufSize-Col],Col,#32);
                  End;
     Paint;
    End;
Procedure TEditView.DelChar;
  Var PosX     : Word;
      Ilk,Ilk1,
      Son      : Boolean;
      S        : String;

    Begin
     SetConfig(Idc_Modified,True);
     SetConfig(Idc_DataChanged,True);
     if AllSpace(PByteArray(Buffer)^[CurY*Col+CurX],BufSize-(CurY*Col+CurX)) then Exit;
     PosX:=CurY*Col;
     Move(PByteArray(Buffer)^[PosX],S[1],Col);Byte(S[0]):=Col;
     TruncateStrSize(S,Stf_RJust);
     Ilk1:=False;if S='' then Ilk1:=True;
     Move(PByteArray(Buffer)^[PosX],S[1],Col);Byte(S[0]):=Col;
     S:=Copy(S,CurX+1,Col-CurX);
     TruncateStrSize(S,Stf_RJust);
     Ilk:=False;if S='' then Ilk:=True;
     Move(PByteArray(Buffer)^[PosX],S[1],Col);Byte(S[0]):=Col;Son:=False;
     if (CurY+1<Row-1) and Ilk then Begin
      PosX:=(CurY+1)*Col;
      Move(PByteArray(Buffer)^[PosX],S[1],Col);Byte(S[0]):=Col;
      TruncateStrSize(S,Stf_RJust);
      if S='' then Son:=True;
     End;
     if Ilk1 and Ilk and Son then Begin DelLine;Exit;End;
     if Ilk then Begin
                  if Son then Begin
                               Move(PByteArray(Buffer)^[PosX+Col],PByteArray(Buffer)^[PosX],BufSize-PosX-Col);
                               FillChar(PByteArray(Buffer)^[BufSize-Col],Col,32);
                              End else Begin DelWord;Exit;End;
                 End else Begin
                  Delete(S,CurX+1,1);S:=S+' ';
                  Move(S[1],PByteArray(Buffer)^[PosX],Byte(S[0]));
                  VFastPaint;Exit;
                 End;
     Paint;
    End;
Procedure TEditView.DelEOL;
    Begin
     FillChar(PByteArray(Buffer)^[CurY*Col],Col,#32);VFastPaint;
     SetConfig(Idc_Modified,True);
     SetConfig(Idc_DataChanged,True);
    End;
Procedure TEditView.DelRight;
    Begin
     FillChar(PByteArray(Buffer)^[Col*CurY+CurX],Col-CurX,#32);VFastPaint;
     SetConfig(Idc_Modified,True);
     SetConfig(Idc_DataChanged,True);
    End;
Procedure TEditView.LeftRightWrap(FF : Boolean);
  Var PX  : Word;
    Begin
     PX:=CurY*Col+CurX;
     if FF then Begin
      While (PByteArray(Buffer)^[PX]<>32) and (Px<BufSize) do Inc(Px);
      While (PByteArray(Buffer)^[PX]=32) and (Px<BufSize) do Inc(Px);
     End else Begin
      if Px>0 then Dec(Px);
      While (PByteArray(Buffer)^[PX]=32) and (Px>0) do Dec(Px);
      While (PByteArray(Buffer)^[PX]<>32) and (Px>0) do Dec(Px);
      if PX<BufSize then Inc(Px);
      if (PX=1) and (PByteArray(Buffer)^[0]<>32) then Dec(Px);
      if (PX=1) and (PByteArray(Buffer)^[1]=32) then Dec(Px);
     End;
     if PX<>CurY*Col+CurX then Begin
      CurX:=PX mod Col;CurY:=PX div Col;
      if CurX>Col-1 then CurX:=Col-1;
      if CurY>Row-1 then CurY:=Row-1;
      if CurX<0 then CurX:=0;
      if CurY<0 then CurY:=0;
      SetCurXY;
     End; {if}
    End;
Procedure TEditView.EndWrap;
  Var PX : Word;
    Begin
     PX:=Col-1;
     While (PByteArray(Buffer)^[Col*CurY+Px]=32) and (Px>0) do Dec(Px);
     if PByteArray(Buffer)^[Col*CurY+Px]<>32 then Inc(Px);
     if PX<>CurX then Begin
      CurX:=PX mod Col;if CurX>Col-1 then CurX:=Col-1;SetCurXY;
     End; {if}
    End;
Function TEditView.Modified : Boolean;
    Begin
      Modified := GetConfig(Idc_Modified);
    End;
Procedure TEditView.HandleEvent(Var Event : TEvent);
 Var A    : Byte;
     T    : TPoint;

 Procedure LookSpecialChars(CH : Char);
    Begin
     Case Upcase(CH) of
      'Y':if DelOk then DelRight
                   else Begin DelOK:=False;Exit;End;
       ^T:DelWord;
      else Begin DelOK:=False;Exit;End;
     End; {Case}
     DelOk:=False;
     Event.CharCode:=#0;
    End;

    Begin
     Inherited HandleEvent(Event);
     With Event do
      Case What of
     evBroadCast:Case Command of
	 Brc_IsModified :if Modified then InfoPtr := @Self else Exit;
	 Brc_IsValid    :if Not Valid(Event) then InfoPtr := @Self else Exit;
	 Brc_IsNull     :if AllSpace(PByteArray(Buffer)^[0],BufSize) then InfoPtr := @Self else Exit;
      Brc_ResetModified :begin SetConfig(Idc_Modified,False);Exit; end;
	else exit;
	end; {Case}
     evMouseDown:Begin
                  MakeLocal(Event.Where,T);
                  CurX:=T.X div ViewFontWidth;
                  CurY:=T.Y div ViewFontHeight;
                  if CurX>Col-1 then CurX:=Col-1;
                  if CurY>Row-1 then CurY:=Row-1;
                  SetCurXY;
                 End;
       evKeyDown:Begin
                 CRLine:=False;SetCurXY;
                 A := System.Pos(Event.CharCode,AKeyCodesMap);
                 if A > 0 Then Event.KeyCode := AKeyCodes[A];
                 Case KeyCode of
                        kbTab:Exit;
                   kbCtrlLeft:LeftRightWrap(False);
                  kbCtrlRight:LeftRightWrap(True);
                   kbCtrlBack:DelOk:=1=1;
	           kbShiftDel:if Not DelOK then DelLine else DelRight;
                    kbCtrlDel:DelEOL;
                        kbDel:DelChar;
                       kbBack:BackDel;
                        kbIns:Begin
                               InsertMode:=Not InsertMode;
                               if InsertMode then SetState(Scf_CursorIns,True)
                                             else SetState(Scf_CursorIns,False);
                              End;
                      kbEnter:EnterProc;
                       kbLeft:Begin DCurX;SetCurXY;End;
                      kbRight:ICurX;
                       kbDown:ICurY;
                         kbUp:DCurY;
                       kbPgUp:Begin CurY:=0;VFastPaint;End;
                       kbPgDn:Begin CurY:=Row-1;VFastPaint;End;
                       kbHome:Begin CurX:=0;VFastPaint;End;
                        kbEnd:EndWrap;
                   kbCtrlHome:Begin CurY:=0;VFastPaint;End;
                    kbCtrlEnd:Begin CurY:=Row-1;VFastPaint;End;
                   kbCtrlPgUp:Begin CurX:=0;CurY:=0;VFastPaint;End;
                   kbCtrlPgDn:Begin CurX:=Col-1;CurY:=Row-1;VFastPainT;End;
                  else Begin
                        LookSpecialChars(CharCode);
                        if CharCode in [#32..#255] then InsertChar(CharCode)
                                                   else Exit;
                       End;
                  end; {case}
                 End; {evKeyDown}
       else Exit;
      End; {Case}
     ClearEvent(Event);
    End;
Function TEditView.DataSize: Word;
    Begin
     DataSize:=BufSize+SizeOf(Word)+1;
    End;
Procedure TEditView.GetData(Var Rec);
    Begin
     TEditorData(Rec).Len:=BufSize;
     Move(PByteArray(Buffer)^[0],TEditorData(Rec).Data[0],BufSize);
    End;
Procedure TEditView.SetData(Var Rec);
    Begin
     SetConfig(Idc_Modified,False);
     if Buffer=Nil then Exit;
     if TEditorData(Rec).Len>Bufsize then TEditorData(Rec).Len:=BufSize;
     Move(TEditorData(Rec).Data[0],PByteArray(Buffer)^[0],TEditorData(Rec).Len);
     if GetState(Scf_Exposed) then Paint;
    End;
Destructor TEditView.Done;
    Begin
     if Buffer<>Nil then FreeMem(Buffer,BufSize+1);
     Inherited Done;
    End;
Procedure TEditView.AddStr(Var S : String);
 Var Len  : Word;
     PosX : Word;
    Begin
     TruncateStrSize(S,Stf_LJust);
     Len:=Byte(S[0]);PosX:=CurY*Col+CurX;
     if Len>(BufSize-PosX) then Len:=BufSize-PosX;
     Move(S[1],PByteArray(Buffer)^[PosX],Len);
     Paint;
    End;
(***************************************************************************)
End.
