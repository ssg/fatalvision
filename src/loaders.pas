{
Name            : Loaders 1.01d
Purpose         : Generic file loaders for ARM
Coders          : SSG & FatalicA
}

unit loaders;

interface

uses xgfx,objects,xtypes,xbuf;

procedure SavePlanedBMP(OutFile:FNameStr;pb:PVifMap);
procedure LoadRaster(AFile:FNameStr;var pb:PVifMap);
procedure ShowBMP(AFile:FNameStr;var pb:PVIFMap);
procedure ShowBMP2(AFile:FNameStr;var pb:PVIFMap);
procedure LoadVIF(fname:FNameStr;var P:PVIFMap);
function LoadBMP256(afile:FnameStr):PVIFMap;
function LoadPAL(afile:FnameStr):PRGBPalette;
procedure ShowBMP1(BmpName:FNameStr; Var VifPTR:PVifMap);
function  LoadFont1(FName:FNameStr; Var FP:PFont):string;
function  LoadFont2(FName:FNameStr; Var FP:PFont):string;
procedure LoadFont(FName:FNameStr);
procedure LoadMouse(FName:FNameStr; var P:PMIF);
procedure LoadFNT(FName:FNameStr; var P:PFont);

implementation

type

  pbyte = ^byte;

function LoadPAL;
var
  P:PRGBPalette;
  T:TDosStream;
begin
  GetMem(P,768);
  T.Init(afile,stOpenRead);
  T.Read(P^,768);
  T.Done;
  LoadPAL := P;
end;

procedure LoadFNT;
type
  PXArray = ^TXArray;
  TXArray = array[0..65000] of byte;
var
  T           : TDosStream;
  csx,csy     : word;
  sc,ec       : byte;
  ChrXTable   : array[0..255] of byte;
  ChrOfsTable : array[0..255] of word;
  memsize     : word;
  datasize    : word;
  Px          : PXArray;
  w           : word;
  ax          : word;
  a           : word;
  Temp        : PXArray;
  procedure ConvertBitmap;
  var
    b,x,y:byte;
  begin
    FillChar(ChrOfsTable,SizeOf(ChrOfsTable),0);
    datasize := Pixel2Byte(csx)*csy*256;
    memsize  := datasize+3;
    GetMem(P,memsize);
    P^.FontType := ftBitmapped;
    P^.ChrX     := csx;
    P^.ChrY     := csy;
    Px          := @P^.Data1;
    w           := 0;
    FillChar(Px^,datasize,0);
    T.Seek($76);
    for b:=sc to ec do begin
      T.Read(csx,2);
      T.Read(ChrOFSTable[b],2);
    end;
    ax := Pixel2Byte(csx);
    a  := ax*csy;
    inc(word(Px),a*sc);
    GetMem(temp,a);
    for b:=sc to ec do begin
      T.Seek(ChrOfsTable[b]);
      T.Read(temp^,a);
      for y:=0 to csy-1 do
        for x:=0 to ax-1 do
          Px^[w+x+y*ax] := Temp^[y+x*csy];
      inc(w,a);
    end;
    FreeMem(temp,a);
  end;
  procedure ConvertProp;
  var
    n,i,i1,zz:word;
  begin
    FillChar(ChrXTable,SizeOf(ChrXTable),0);
    FillChar(ChrOfsTable,SizeOf(ChrOfsTable),0);
    T.Seek($76);
    i := 0;
    for N := sc to ec do begin
      T.Read(ax,2);
      T.Read(ChrOfsTable[n],2);
      ChrXTable[n] := ax; {word2byte (tm) conversion}
      inc(i,Pixel2Byte(ChrXTable[n])*csy);
    end;
    datasize := i+(256-(ec-sc))*csy;
    memsize  := datasize + 3;
    GetMem(P,memsize);
    P^.FontType := ftProportional;
    P^.ChrY1    := csy;
    Move(ChrXTable,P^.TblChrX,SizeOf(P^.TblChrX));
    P^.Size     := datasize;
    Px          := @P^.Data2;
    w           := 0;
    FillChar(Px^,datasize,0);
    for N:=sc to ec do begin
      T.Seek(ChrOfsTable[N]);
      CSX := ChrXTable[N];

      AX := Pixel2Byte(CSX);
      if ax > 0 then begin
        P^.TblChrOfs[N] := w;
        A  := AX * CSY;
        inc(w,A);
        GetMem(temp,A);
        T.Read(temp^,A);
        for I:=0 to CSY-1 do begin
          for i1 := 0 to AX-1 do
            Px^[I*AX+I1] := temp^[I1*CSY+I];
        end;
        inc(word(Px),A);
        FreeMem(temp,A);
      end;
    end;
  end;

begin
  P := NIL;
  T.Init(FName,stOpenRead);
  if T.Status = stOK then begin
    T.Seek($56);
    T.Read(csx,2);
    T.Read(csy,2);
    if csy = 0 then exit;
    T.Seek($5f);
    T.Read(sc,1);
    T.Read(ec,1);
    if (csx = 0) then ConvertProp else ConvertBitmap;
  end;
  T.Done;
end;

procedure LoadMouse(FName:FNameStr; var P:PMIF);
var
  T:TDosStream;
  H:TMIFHeader;
  M:TMouseBitMap;
begin
  P := NIL;
  T.Init(FName,stOpenRead);
  if T.Status <> stOk then begin
     T.Done;
     exit;
  end;
  T.Read(H,SizeOf(H));
  T.Read(M,SizeOf(M));
  T.Done;
  New(P);
  if P = NIL then exit;
  P^.HX     := H.HX;
  P^.HY     := H.HY;
  P^.BitMap := M;
end;

procedure SavePlanedBMP(OutFile:FNameStr;pb:PVifMap);
var
  T:TDosStream;
  sx,sy:word;
  PlaneSize:Word;
begin
  T.Init(OutFile,stCreate);
  sx := PB^.XSize;
  sy := PB^.YSize;
  PlaneSize := ((SX div 8) + Byte((SX mod 8)>0))*SY ;
  T.Write(PB^,4);
  T.Write(PB^.Plane0^,PlaneSize);
  T.Write(PB^.Plane1^,PlaneSize);
  T.Write(PB^.Plane2^,PlaneSize);
  T.Write(PB^.Plane3^,PlaneSize);
  T.Done;
end;

procedure LoadRaster(AFile:FNameStr;var pb:PVifMap);
var
  T:TDosStream;
  sx,sy:word;
  PlaneSize:Word;
begin
  pb := nil;
  T.Init(AFile,stOpenRead);
  if T.Status <> stOk then exit;
  New(pb);
  T.Read(pb^,4);
  sx := pb^.XSize;
  sy := pb^.YSize;
  pb^.Version := 2;
  PlaneSize := ((SX div 8) + Byte((SX mod 8)>0))*SY ;
  GetMem(PB^.Plane0,PlaneSize);
  GetMem(PB^.Plane1,PlaneSize);
  GetMem(PB^.Plane2,PlaneSize);
  GetMem(PB^.Plane3,PlaneSize);
  T.Read(PB^.Plane0^,PlaneSize);
  T.Read(PB^.Plane1^,PlaneSize);
  T.Read(PB^.Plane2^,PlaneSize);
  T.Read(PB^.Plane3^,PlaneSize);
  T.Done;
end;

procedure ShowBMP(AFile:FNameStr;var pb:PVIFMap);
begin
  ShowBMP2(AFile,pb);
end;

procedure ShowBMP2(AFile:FNameStr;var pb:PVIFMap);
    Var
      S     : TDosStream;
      T     : TBmpCore;
      TX    : TBmpExtra;
      SX,SY : Word;
      BX    : Word;
      A,B   : Word;
      C,D   : Byte;
      X1    : Word;
      Pal   : TRGBQuad;
      I     : Word;
      p1,p2,p3,p4 : pByte;
      PlaneSize  : Word;
      CurrentBit : Byte;
      Bicik : Boolean;
      BSX   : Byte;
      n:byte;

    procedure SharePixel(Pixel:Byte);
    begin
      if Pixel and 1 > 0 then P1^ := P1^ or $80 shr CurrentBit;
      if Pixel and 2 > 0 then P2^ := P2^ or $80 shr CurrentBit;
      if Pixel and 4 > 0 then P3^ := P3^ or $80 shr CurrentBit;
      if Pixel and 8 > 0 then P4^ := P4^ or $80 shr CurrentBit;
      inc(CurrentBit);
      if CurrentBit > 7 then begin
         Bicik := true;
         CurrentBit := 0;
         inc(Word(P1));
         inc(Word(P2));
         inc(Word(P3));
         inc(Word(P4));
      end else Bicik := False;
    end;

    begin
      S.Init(AFile,StOpen);
      if S.Status <> stOk then exit;
      S.Read(T,SizeOf(T)); {read first header}
      if T.HdrSize > 14 then S.Read(TX,SizeOf(TX)); {read extra header}
      SX := T.SizeX;
      SY := T.SizeY;
      GetMem(pb,1+4+16); {!}
      PB^.XSize  := SX;
      PB^.YSize  := SY;
      BSX := ((SX div 8) + Byte((SX mod 8)>0));
      PlaneSize := BSX*SY ;
      if PlaneSize = 0 then exit;
      GetMem(PB^.Plane0,PlaneSize);
      GetMem(PB^.Plane1,PlaneSize);
      GetMem(PB^.Plane2,PlaneSize);
      GetMem(PB^.Plane3,PlaneSize);
      p1 := PB^.Plane0;
      p2 := PB^.Plane1;
      p3 := PB^.Plane2;
      p4 := PB^.Plane3;
      FillChar(p1^,PlaneSize,0);
      FillChar(p2^,PlaneSize,0);
      FillChar(p3^,PlaneSize,0);
      FillChar(p4^,PlaneSize,0);
      inc(Word(P1),BSX*(SY-1));
      inc(Word(P2),BSX*(SY-1));
      inc(Word(P3),BSX*(SY-1));
      inc(Word(P4),BSX*(SY-1));
      S.Seek(T.DataStart);
      BX := (S.GetSize - T.DataStart) div SY;
      writeln('sy=',sy);
      writeln('bx=',bx);
      writeln('xsize=',pb^.xsize);
      writeln('ysize=',pb^.ysize);
      For A := SY-1 downto 0 do begin
        X1 := 0;
        CurrentBit := 0;
        For B:=0 to BX-1 do begin
          S.Read(D,1);
          case T.BitCount of
            1 : begin

                end;
            4 : begin
                 C := (D and $F0) shr 4;
                 if X1 < SX then SharePixel(C);
                 inc(X1);
                 C := D and $0F;
                 if X1 < SX then SharePixel(C);
                 inc(X1);
                end;
            8 : begin
                 {if B < SX then begin PByte(P)^ := C; inc(word(P)); end;}
                end;
          end;
        end;
        if (CurrentBit <= 7) and (Not Bicik) then begin
         inc(Word(P1));
         inc(Word(P2));
         inc(Word(P3));
         inc(Word(P4));
        end;
        dec(word(P1),BSX*2);
        dec(word(P2),BSX*2);
        dec(word(P3),BSX*2);
        dec(word(P4),BSX*2);
      end;
      S.Done;
      pb^.Version := 2;
    end;

procedure LoadVIF(fname:FNameStr;var P:PVIFMap);
var
  T:TDosStream;
  H:TVIFHeader;
  S:String[3];
  xs,ys:word;
  p1,p2,p3,p4:pointer;
  bsx : word;
  ver : byte;
  n:byte;
  PlaneSize : word;
begin
  P:=NIL;
  T.Init(fname,stOpenRead);
  T.Read(H,SizeOf(H));
  S[0]:=#3;
  Move(H.Id,S[1],3);
  if S<>'VIF' then exit;
  Move(H.Version,S[1],3);
  ver := Byte(s[1])-48;
  case ver of
    1:begin
       T.Read(xs,sizeof(word));
       T.Read(ys,sizeof(word));
       T.Read(ver,1);
       GetMem(P,xs*ys+5);
       P^.XSize  := xs;
       P^.YSize  := ys;
       PlaneSize := xs*ys;
       T.Seek(T.GetSize - PlaneSize);
       T.Read(P^.Data,PlaneSize);
    end;  {1}
    2:begin
       New(P);
       P^.Version := ver;
       T.Read(P^.XSize,2);
       T.Read(P^.YSize,2);
       T.Read(P^.Version,1);
       PlaneSize := Pixel2Byte(P^.XSize)*P^.YSize;
       for n := 0 to 3 do begin
         GetMem(P^.Planes[n],PlaneSize);
         T.Read(P^.Planes[n]^,PlaneSize);
       end; {for}
    end; {2}
  end; {case}
  T.Done;
end;

function LoadBMP256(afile:FnameStr):PVIFMap;
var
  P:PVIFMap;
  T:TDosStream;
  h:TBmpCore;
  hx:TBmpExtra;
  line:pointer;
  dest:pointer;
  y:integer;
begin
  LoadBMP256 := NIL;
  T.Init(afile,stOpenRead);
  T.Read(h,SizeOf(h));
  if T.Status <> stok Then exit;
  if h.SizeX*h.SizeY > 65530 then exit;
  GetMem(P,h.SizeX*h.SizeY+5);
  P^.XSize := h.Sizex;
  P^.YSize := h.Sizey;
  P^.Version := 1;
  GetMem(line,P^.XSize);
{  if T.HdrSize > 12 then T.Read(hx,SizeOf(hx));}
  T.Seek(h.Datastart);
  dest := @P^.Data;
  inc(word(dest),P^.XSize*(P^.YSize-1));
  for y:=1 to P^.YSize do begin
    T.Read(line^,P^.XSize);
    Move(line^,dest^,P^.XSize);
    dec(word(dest),P^.XSize);
  end;
  FreeMem(line,P^.Xsize);
  T.Done;
  LoadBMP256 := P;
end;

procedure ShowBMP1(BmpName:FNameStr; Var VifPTR:PVifMap);
    Var
      S     : TDosStream;
      T     : TBmpCore;
      TX    : TBmpExtra;
      SX,SY : Word;
      BX    : Word;
      A,B   : Word;
      C,D   : Byte;
      X1    : Word;
      Pal   : TRGBQuad;
      I     : Word;
      P     : PVifMap;
      L     : Word;
    begin
      VIFPTR := NIL;
      S.Init(BmpName,StOpen);
      S.Read(T,SizeOf(T));
      if S.Status <> stok then exit;
      if T.HdrSize > 12 then S.Read(TX,SizeOf(TX));
      SX := T.SizeX;
      SY := T.SizeY;
      if longint(SX)*longint(SY) > longint(65530) then begin
        exit;
      end;
      L := SX*SY+5; {!}
      GetMem(VifPtr,L);
      P := VifPtr;
      P^.XSize  := SX;
      P^.YSize  := SY;
      inc(word(P),5);
      inc(Word(P),SX*(SY-1));
      S.Seek(T.DataStart);
      BX := (S.GetSize - T.DataStart) div SY;
      For A := SY-1 downto 0 do begin
        X1 := 0;
        For B:=0 to BX-1 do begin
          S.Read(D,1);
          case T.BitCount of
            1 : begin

                end;
            4 : begin
                 C := (D and $F0) shr 4;
                 if X1 < SX then begin PByte(P)^ := C; inc(word(P)); end;
                 inc(X1);
                 C := D and $0F;
                 if X1 < SX then begin PByte(P)^ := C; inc(word(P)); end;
                 inc(X1);
                end;
            8 : begin
                 if B < SX then begin PByte(P)^ := C; inc(word(P)); end;
                end;
          end;
        end;
        dec(word(P),SX*2);
      end;
      S.Done;
      VifPtr^.Version := 1;
    end;

function LoadFont1(FName:FNameStr; Var FP:PFont):string;
    Var
      P  : Pointer;
      I  : Byte;
      S  : TDosStream;
      N  : String;
      CSX,CSY,A : Word;
    begin
        S.Init(FName,StOpenRead);
        if S.Status <> StOK then exit;
        S.Seek(SizeOf(TCIFHeader));
        S.Read(N[0],1);
        S.Read(N[1],length(N));
        LoadFont1 := N;
        S.Read(CSX,SizeOf(Word));
        S.Read(CSY,SizeOf(Word));
        S.Read(A,SizeOf(Word));
        GetMem(FP,A*256+3);
        S.Read(FP^.Data1,A*256);
        S.Done;
        FP^.FontType  := FtBitMapped;
        FP^.ChrX      := CSX;
        FP^.ChrY      := CSY;
    end;

function LoadFont2(FName:FNameStr; Var FP:PFont):string;
    Var
      P  : Pointer;
      I  : Byte;
      S  : TDosStream;
      N  : String;
      CSX,CSY,A : Word;
      L  : Word;
      ChrX   : Array[0..255] of byte;
      ChrOfs : Array[0..255] of Word;
    begin
        CSY := 0;
        S.Init(FName,StOpenRead);
        if S.Status <> StOK then exit;
        S.Seek(SizeOf(TCIFHeader));
        S.Read(N[0],1);
        S.Read(N[1],length(N));
        LoadFont2 := N;
        S.Read(CSY,SizeOf(Byte));
        S.Read(ChrX,SizeOf(ChrX));
        fillchar(ChrOfs,SizeOf(ChrOfs),0);
        L := 0;
        for I:=0 to 255 do begin
          if ChrX[I] > 0 then begin
             ChrOfs[I] := L;
             A := Pixel2Byte(ChrX[I]);
             A := A*CSY;
             inc(L,A);
          end;
        end;
        GetMem(FP,L+SizeOf(ChrX)+SizeOf(ChrOfs)+2);
        FP^.FontType := FtProportional;
        FP^.ChrY1    := CSY;
        FP^.Size     := L + SizeOf(ChrX)+SizeOf(ChrOfs)+2;
        move(ChrX,FP^.TblChrX,SizeOf(ChrX));
        move(ChrOfs,FP^.TblChrOfs,SizeOf(ChrOfs));
        S.Read(FP^.Data2,L);
        S.Done;
    end;

procedure LoadFont(FName:FNameStr);
    Var
      FP : PFont;
      S  : TDosStream;
      N  : String;
      Header : TCIFHeader;
    begin
      S.Init(FName,stOpenRead);
      if S.Status <> stOk then exit;
      S.Read(Header,SizeOf(Header));
      S.Done;
      case Header.Version of
        1 : N:=LoadFont1(FName,FP);
        2 : N:=LoadFont2(FName,FP);
      end; {case}
    end;

end.
*** End Of File ***