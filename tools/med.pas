{
Name            : MED 1.31a
Purpose         : Simple mouse editor
Date            : 06th Dec 93
Coder           : SSG

updates:
--------
27th Aug 97 - 23:22 - adapted to new GUI...
}

uses

  XDialogs,XStr,XTypes,XIO,Drivers,Dos,Loaders,Objects,Tools,XGfx,Graph,
  XDev,GView;

const

  medVersion = '1.31a';

  GridSize = 8;
  GrXSize  = 16;
  GrYSize  = 16;

  Col_Hi   = cWhite;
  Col_Lo   = cBlack;

  cmColorHi = 5400;
  cmColorHo = 5401;
  cmColorLo = 5402;

  cmNew     = 5403;
  cmAbout   = 5404;

  Brc_SaveIt  = 25000;
  Brc_SaveAs  = 25001;

type

  PGridRec = ^TGridRec;
  TGridRec = array[0..15,0..15] of byte;

  TGetDataData = record
    M          : TMouseBitMap;
    HX,HY      : string[2];
  end;

  PGrid = ^TGrid;
  TGrid = object(TView)
    Data        : TGridRec;
    Color       : Byte; {White,Black,LightGray}
    Modified    : boolean;
    constructor Init(x,y:integer);
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   GetData(var rec);virtual;
    procedure   SetData(var rec);virtual;
    procedure   Paint;virtual;
    function    DataSize:word;virtual;

    procedure   SetColor(AColor:Byte);
    procedure   PaintSquare(x,y:integer);
    procedure   GetSquareBounds(x,y:byte;var R:TRect);
    procedure   Clear;
  end;

  PColorButton = ^TColorButton;
  TColorButton = object(TGenericButton)
    color      : byte;
    constructor Init(var R:TRect;acolor:byte;command:word);
    procedure   PaintContents(var R:TRect); virtual;
  end;

  PMouseEditor = ^TMouseEditor;
  TMouseEditor = object(TWindow)
    Grid       : PGrid;
    FileName    : FNameStr;
    constructor Init(AFile:FNameStr);
    procedure   HandleEvent(var Event:TEvent);virtual;
    procedure   Save;
    procedure   Load;
    procedure   SetFileName(AFile:FNameStr);
    function    Valid(acmd:word):boolean;virtual;
  end;

  TMED = object(TSystem)
    constructor Init;
    procedure   HandleEvent(var Event:TEvent);virtual;
  end;

procedure TMED.HandleEvent;
  procedure Edit(fname:FNameStr);
  begin
    Insert(New(PMouseEditor,Init(fname)));
  end;
var
  s:FNameStr;
begin
  inherited HandleEvent(Event);
  if Event.What = evCommand then case Event.Command of
    cmNew : Edit('untitled');
    cmLoad : begin
               s := '';
               if ExecuteFileDialog('*.MIF','Open a File',0,ViewFont,s) then Edit(s);
             end;
    cmSave : Message(@Self,evBroadcast,Brc_SaveIt,NIL);
    cmSaveAs : begin
                 s := '';
                 if ExecuteFileDialog('*.MIF','Save File As',0,ViewFont,s) then begin
                   if XFileExists(s) then
                     if MessageBox(^C'File already exists? Overwrite?',0,
                       mfConfirm+mfYesNo) <> cmYes then exit;
                   Message(@Self,evBroadcast,brc_SaveAs,@s);
                 end;
               end;
    cmAbout : MessageBox(^C'MED Version '+medVersion+#13#32#13+
                         ^C'Programmed by'#13+
                         ^C'Sedat Kapanoglu',0,mfInfo);
  end; {case}
end;

constructor TMED.Init;
var
  R:TRect;
begin
  inherited Init;
  GetExtent(R);
  Insert(New(PMenuBar,Init(R,NewMenu(
    NewSubMenu('~File',
      NewMenu(
      NewItem('~New',cmNew,
      NewItem('~Open',cmLoad,
      NewItem('~Save',cmSave,
      NewItem('~Save as',cmSaveAs,
      NewLine(
      NewItem('E~xit',cmQuit,
      NIL))))))),
    NewSubMenu('~Edit',
      NewMenu(
      NewItem('~Clear',cmDel,
      NewItem('~Test',cmTest,
      NewLine(
      NewItem('~About',cmAbout,
      NIL))))),
    NIL))))));
  Insert(New(PAccelerator,Init(
    NewAcc(kbF3,cmLoad,
    NewAcc(kbF2,cmSave,
    NewAcc(kbDel,cmDel,
    NewAcc(kbF9,cmTest,
    NIL)))))));
end;

constructor TColorButton.Init;
begin
  inherited Init(R,command);
  color := acolor;
end;

procedure TColorButton.PaintContents;
begin
  SetFillStyle(SolidFill,color);
  XBox(R,True);
end;

{------------------------------ TMOUSEEDITOR -------------------------}
constructor TMouseEditor.Init;
var
  R:TRect;
begin
  R.Assign(0,0,0,0);
  inherited Init(R,AFile);
  Options := (Options or Ocf_Centered) and not Ocf_ReSize;
  New(Grid,Init(5,5));
  Grid^.GetBounds(R);
  Insert(Grid);
  FileName := Upper(AFile);
  InsertBlock(GetBlock(5,R.B.Y+10,mnfVertical,
    NewInputItem('HotSpot-X     ',2,Idc_NumDefault,
    NewInputItem('HotSpot-Y     ',2,Idc_NumDefault,NIL))));
  R.Assign(r.b.x+5,r.a.y+1,180,R.a.Y+51);
  Insert(New(PColorButton,Init(R,Col_Hi,cmColorHi)));
  R.Move(0,55);
  Insert(New(PColorButton,Init(R,Col_Back,cmColorHo)));
  R.Move(0,55);
  Insert(New(PColorButton,Init(R,Col_Lo,cmColorLo)));
  FitBounds;
  Load;
end;

function TMouseEditor.Valid;
begin
  Valid := true;
  if Grid^.modified then case MessageBox(^C+FileName+' has been modified. Save?',0,
                              mfConfirm+mfYesNoCancel) of
    cmYes : Save;
    cmCancel : Valid := false;
  end; {case}
end;

procedure TMouseEditor.Load;
var
  P:PMIF;
  GD:TGetDataData;
  s:string[2];
begin
  if FileName = 'UNTITLED' then exit;
  EventWait;
  LoadMouse(FileName,P);
  if P = NIL then MessageBox(^C'Error loading file',0,mfError) else begin
    Str(P^.HX:2,s);
    GD.HX := s;
    Str(P^.HY:2,s);
    GD.HY := s;
    GD.M  := P^.BitMap;
    SetData(GD);
  end;
end;

procedure TMouseEditor.SetFileName(AFile:FNameStr);
begin
  FileName := AFile;
  if Header <> NIL then DisposeStr(Header);
  Header := NewStr(FileName);
  PaintView;
end;

procedure TMouseEditor.Save;
var
  H:TMIFHeader;
  M:TMouseBitMap;
  GD:TGetDataData;
  T:TDosStream;
  f:FNameStr;
  code:integer;
  b:byte;
begin
  if FileName = 'untitled' then begin
    f := '';
    if ExecuteFileDialog('*.MIF','Save File',0,ViewFont,f) then SetFileName(f) else exit;
  end;
  EventWait;
  Move(Id_MIF,H.Id,SizeOf(TID));
  H.Version := 1;
  GetData(GD);
  Val(GD.HX,b,code);
  H.HX := b;
  Val(GD.HY,b,code);
  H.HY := b;
  T.Init(FileName,stCreate);
  T.Write(H,SizeOf(H));
  T.Write(GD.M,SizeOf(TMouseBitMap));
  if T.Status <> stOK then MessageBox(^C+'Error saving '+filename,0,mfError);
  T.Done;
  Grid^.modified := false;
end;

procedure TMouseEditor.HandleEvent(var Event:TEvent);
var
  T:TMouseBitMap;
  GD:TGetDataData;
  O:TPoint;
begin
  inherited HandleEvent(Event);
  if GetState(Scf_Focused) then
  case Event.What of
    evCommand : case Event.Command of
       cmDel : begin
                 FillChar(GD.M[0,0],32,$FF);
                 FillChar(GD.M[1,0],32,0);
                 GD.HX := '00';
                 GD.HY := '00';
                 SetData(GD);
               end;
       cmTest : begin
                  Grid^.GetData(T);
                  EventWait;
                  Mouse_DefineCursor(1,1,T);
                  repeat
                  until PointingDevice^.GetButtonStatus > 0;
                  PointingDevice^.GetPosition(O);
                  asm
                    xor ah,ah
                    int 33h
                  end;
                  PointingDevice^.SetPosition(O.x,O.y);
                end;
       cmColorHi : Grid^.SetColor(Col_Hi);
       cmColorHo : Grid^.SetColor(Col_Back);
       cmColorLo : Grid^.SetColor(Col_Lo);
       else exit;
     end; {case little}
     evBroadcast : case Event.Command of
       Brc_SaveIt : Save;
       Brc_SaveAs : begin
                      SetFileName(PString(Event.InfoPtr)^);
                      Save;
                    end;
       else exit;
     end; {case}
  end else exit; {if}
  ClearEvent(Event);
end;

{--------------------------------- TGRID -----------------------------}
constructor TGrid.Init(x,y:integer);
var
  R:TRect;
begin
  R.Assign(0,0,GrXSize*GridSize+1,GrYSize*GridSize+1);
  R.Move(x,y);
  inherited Init(R);
  Clear;
  Options   := Ocf_PreProcess or Ocf_PaintFast;
  EventMask := evMouseDown;
  Color     := Col_Hi;
end;

function TGrid.DataSize:word;
begin
  DataSize := SizeOf(TMouseBitMap);
end;

procedure TGrid.GetData(var rec);
var
  w:word;
  y:byte;
  x:byte;
begin
  for y := 0 to 15 do begin
    w := 0;
    for x := 0 to 15 do if Data[x,y] = Col_Back then w := w or (1 shl (15-x));
    TMouseBitMap(rec)[0,y] := w;
  end; {fory}
  for y := 0 to 15 do begin
    w := 0;
    for x := 0 to 15 do if Data[x,y] = Col_Hi then w := w or (1 shl (15-x));
    TMouseBitMap(rec)[1,y] := w;
  end; {fory}
end;

procedure TGrid.Clear;
begin
  FillChar(Data,SizeOf(Data),Col_Back);
  if GetState(Scf_Exposed) then Paint;
end;

procedure TGrid.SetData(var rec);
var
  y:byte;
  x:byte;
  w,w1:word;
  f:boolean;
begin
  for y := 0 to 15 do begin
    w  := TMouseBitMap(rec)[0,y];
    w1 := TMouseBitMap(rec)[1,y];
    for x := 0 to 15 do begin
        f := w1 and (1 shl (15-x)) > 0;
        if w and (1 shl (15-x)) > 0 then Data[x,y] := Col_Back
        else case f of
           True  : Data[x,y] := Col_Hi;
           False : Data[x,y] := Col_Lo;
        end;
    end; {forx}
  end; {fory}
  if GetState(Scf_Exposed) then Paint;
end;

procedure TGrid.HandleEvent(var Event:TEvent);
var
  x,y:integer;
  R:TRect;
  T:TPoint;
  ox,oy:byte;
begin
  if Event.What <> evMouseDown then exit;
  PaintBegin;
  PointingDevice^.Show;
  ox := 255;
  while (Event.What <> evMouseUp) do begin
    MakeLocal(Event.Where,T);
    x := T.X div GridSize;
    y := T.Y div GridSize;
    if x > GrXSize-1 then x := GrXSize - 1;
    if Y > GrYSize -1 then y := GrYSize - 1;
    if x < 0 then x := 0;
    if y < 0 then y := 0;
    case Event.Buttons of
      MbLeftButton  : begin
                        Data[x,y] := Color;
                        modified := true;
                      end;
      MbRightButton : begin
                        Data[x,y] := Col_Back;
                        modified := true;
                      end;
    end;
    if ((ox<>x) or (oy<>y)) then begin
       PointingDevice^.Hide;
       PaintSquare(x,y);
       PointingDevice^.Show;
       ox := x;
       oy := y;
    end;
    PointingDevice^.GetEvent(Event);
  end;
  PaintEnd;
  ClearEvent(Event);
end;

procedure TGrid.GetSquareBounds(x,y:byte;var R:TRect);
begin
  R.A.X := x*GridSize;
  R.A.Y := y*GridSize;
  R.B.X := R.A.X + GridSize;
  R.B.Y := R.A.Y + GridSize;
  R.Move(1,1);
  dec(R.B.X);
  dec(R.B.Y);
end;

procedure TGrid.SetColor(AColor:Byte);
begin
  Color := AColor;
end;

procedure TGrid.Paint;
var
  x,y:integer;
  R:TRect;
begin
  if not GetState(Scf_Exposed) then exit;
  PaintBegin;
    GetExtent(R);
    ShadowBox(R,False);
    R.Grow(-1,-1);
    for y := 0 to 15 do
      for x := 0 to 15 do PaintSquare(x,y);
  PaintEnd;
end;

procedure TGrid.PaintSquare(x,y:integer);
var
  R:TRect;
begin
  GetSquareBounds(x,y,R);
  SetFillStyle(SolidFill,Data[x,y]);
  XBox(R,True);
end;

var
  Main:TMED;
begin
  Main.Init;
  Main.Run;
  Main.Done;
end.
