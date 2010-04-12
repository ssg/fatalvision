{
Name            : X/Gfx 1.00d
Purpose         : gfx subsystem
Date            : 24th May 1993
Coder           : most of the code by FatalicA others are SSG's...


Update Info:
------------
22nd Dec 96 - 02:54 - revising the code and structure...
29th Jun 97 - 12:49 - a small bugfix in donegfx code..
}

{$O-,R-}

unit XGfx;

interface

uses

  Dos,Drivers,Objects,XTypes;

const

  ViewFont         : word = 1;

  ScreenX          : integer = 0;     {Screen X Size}     {********** MISC **}
  ScreenY          : integer = 0;     {  "    Y   " }
  MaxColor         : word    = 0;     {Maximum available colors}

  BiosFontPtr      : PFont = Nil;
  TxtForeground    : word = 0;         {Text colors}
  TxtBackGround    : word = 0;

  EventsFocused    : word = evCommand + evKeydown;
  EventsPositional : word = evMouse;

  SmoothPalSet     : boolean = False;

{---------------- INIT & DONES ---------------------}
procedure InitFonts;
procedure InitGfx;          {Initialize graphics screen}
procedure DoneGfx;          {Return to shitty text mode}

{---------------- BITMAP MANAGEMENT ---------------------}
procedure PutOredVIF(ix,iy:integer; var BitMap);
procedure PutVIF(X,Y:Integer; Var BitMap);             {Put image}
procedure DisposeVIF(var P:PVIFMap);                   {Dispose image}
function  GetImagePtr(ImageId:Word):PVifMap;           {Get image pointer}
function  GetVIFSize(P:PVIFMap):word;                  {Get image size}
function  Pixel2Byte(N:Word):Byte;

{---------------- FONT MANAGEMENT ---------------------------}
procedure WriteStr(X,Y,XSize:Integer; S:String; P:PFont);    {Write text}
procedure WriteOredStr(X,Y,XSize:Integer; S:String; P:PFont);{ored}
procedure SetTextColor(ForeGround,BackGround:Word);   {Set text colors}
procedure LoadBIOSFont;                               {Load font from ROM}
function  GetFontPtr(FontId:Word):PFont;              {Get fonts pointer}
function  GetStringSize(FontId:Word; S:String):word;   {Get string size}
function  GetFontHeight(FontId:Word):word;            {Get font's height}
function  GetFontX(FontPtr:PFont; var S:String):word; {Get strings X-size}
function  GetFontY(FontPtr:PFont):word;               {Get strings Y-size}

{---------------- PALETTE MANAGEMENT ---------------------}
procedure SetRGB(Color,Red,Green,Blue:Byte);          {Sets RGB of a color}
procedure GetRGB(Color:Byte;var T:TRGB); {Gets "    " "  "}
procedure GetQuadPalette(var P:TQuadPalette);              {gets quad palette}
procedure GetPalette(Var P:TRGBPalette);                  {gets full palette}
procedure GetTruePalette(Var P:TRGBPalette);              {gets true palette?}
procedure SetTrueRGB(Color,Red,Green,Blue:Byte);      {Sets True RGB}
procedure SetPalette(Var Pal:TRGBPalette);                {Sets full palette}
procedure SetTruePalette(var P:TRGBPalette);              {Sets true palette}
procedure SetStartupPalette;                          {Sets startup values}
procedure NullPalette;                                {Blanks screen}
procedure RGB2Quad(var src,dst; numcolors:byte);      {Pal to Pal convs}
procedure Quad2RGB(var src,dst; numcolors:word);      {Same as prev}
procedure Cycle;
procedure Sync;

implementation

uses

XDiag,
Graph,
XBuf,
XStr,
XSys,
AXEServ;

var

  VideoSeg         : Word absolute SegA000;

type

  PFontLineBuf = ^TFontLineBuf;
  TFontLineBuf = array[0..ftMaxCharY-1,0..79] of byte;

const

  NumPlanes = 4;

  FontLineBuf : PFontLineBuf = NIL;

  VideoDriver      : integer = 0;

  BytesPerLine = 640 div 8;

  TurkishChars : Array[0..11] of Array[0..8] of byte =
 ((128,   060,102,192,192,192,102,060,024),
  (166,   024,062,096,096,110,102,062,000),
  (152,   024,060,024,024,024,024,060,000),
  (153,   108,124,198,198,198,198,124,000),
  (158,   060,102,048,024,012,102,060,024),
  (154,   102,000,102,102,102,102,060,000),
  (135,   000,000,124,198,192,198,126,056),
  (167,   056,000,124,204,204,124,012,248),
  (141,   000,000,056,024,024,024,060,000),
  (148,   000,108,000,124,198,198,124,000),
  (159,   000,000,124,192,124,006,252,048),
  (129,   000,102,000,102,102,102,062,000));

procedure EGAVGADriverProc;external;
{$L EGAVGA}

(*procedure VESADriverProc;external;
$L VESA}*)

procedure InitGfx;
var
  GM : Integer;
begin
  if not IsVGA then Error('InitGfx','VGA not detected');
  if VideoDriver = 0 then begin
    VideoDriver := VGA;
    if RegisterBGIDriver(@EGAVGADriverProc) < 0 then Error('InitGfx','register error');
  end;
  gm := VGAHi;
  InitGraph(VideoDriver,gm,'');
  if GraphResult = GrOK then begin
         ScreenX  := GetMaxX;
         ScreenY  := GetMaxY;
         MaxColor := GetMaxColor;
    TxtForeGround := MaxColor;
    TxtBackGround := 0;
  end else Error('InitGfx',graphErrorMsg(GraphResult));
end;

procedure DoneGfx;
begin
  CloseGraph;
  asm
    mov ax,3
    int 10h
  end;
end;

{---------------------------------------------------------------------------}
{->                 B I T M A P   R O U T I N E S                         <-}
{---------------------------------------------------------------------------}

function GetImagePtr(ImageId:Word):PVifMap;
var
  P : PVifMap;
begin
  if not AXEOK then Error('GetImagePtr','No system resource') else begin
    P := GetRscById(rtImage,ImageId);
    if P = Nil then Error('GetImagePtr','Couldn''t get image '+l2s(ImageId));
    GetImagePtr := P;
  end;
end;

procedure _PixelToByte; near; assembler;
    asm
               test    al,07
               jz      @1
               add     ax,+08
@1:            shr     ax,1
               shr     ax,1
               shr     ax,1
    end;

{or here! here! yeah! yeah! the bug is here! here! fuck'em all}
procedure _AdjustViewPort(X,Y,XSize,YSize,BufXSize:Integer); near; assembler;
{IN : None
 OUT: SI-> View ported offset
      CL-> Mem Start Bit
      BX-> X count in pixels
      DX-> Y count in pixels
      AX-> Coordinate X
      DI-> Coordinate Y
}
    var
      V : ViewPortType;
      C : Byte;
    asm
               lea     di,V
               push    ss
               push    di
               call    Graph.GetViewSettings
               xor     si,si
               mov     byte ptr C,0

               mov     ax,X
               mov     bx,Y
               add     ax,V.X1
               add     bx,V.Y1
               mov     cx,ax
               mov     dx,bx
               add     cx,XSize
               add     dx,YSize

               cmp     ax,V.X1
               jge     @1
               sub     ax,V.X1
               neg     ax
               push    cx
               mov     cx,ax
               shr     ax,1
               shr     ax,1
               shr     ax,1
               add     si,ax
               and     cl,$07
               mov     C,cl
               pop     cx
               mov     ax,V.X1

@1:
               cmp     bx,V.Y1
               jge     @2
               sub     bx,V.Y1
               neg     bx
               push    ax
               push    dx
               mov     ax,BufXSize
               call    _PixelToByte
               mul     bx
               add     si,ax
               pop     dx
               pop     ax
               mov     bx,V.Y1
@2:
               cmp     cx,V.X2
               jle     @3
               mov     cx,V.X2
               inc     cx
@3:
               cmp     dx,V.Y2
               jle     @4
               mov     dx,V.Y2
               inc     dx
@4:
               sub      cx,ax
               jle      @Exit
               sub      dx,bx
               jle      @Exit
               mov      di,bx
               mov      bx,cx
               mov      cl,C
               clc
               jmp      @Esc
@Exit:         stc
@Esc:
    end;
procedure _CalcScrAdr;near;assembler;
asm
               push    bx
               push    cx

               shl     di,1                 {DI Y coordinate}
               mov     bx,di                {SI X Coordinate}
               mov     cl,2
               shl     di,cl
               add     di,bx
               inc     cl
               shl     di,cl

               mov     ax,si
               shr     si,cl
               add     di,si
               and     ax,$07               {AL Start Scr Bit}
               pop     cx
               pop     bx
               retn
end;

procedure PutOredVIF(ix,iy:integer; var BitMap);
var
  x,y:integer;
  function getPix:byte;
  var
    pixel : byte;
    P     : ^byte;
    offs  : word;
    bit   : byte;
    n     : byte;
  begin
    with TVIFMap(BitMap) do begin
      pixel := 0;
      offs  := (y-iy)*Pixel2Byte(XSize)+Pixel2Byte(x-ix);
      bit   := x mod 8;
      for n := 0 to 3 do begin
        P := Planes[n];
        inc(word(P),offs);
        if (1 shl bit) and P^ <> 0 then pixel := pixel or (1 shl n);
      end;
      GetPix := pixel;
    end;
  end;
begin
  with TVIFMap(BitMap) do begin
    for y:=ix to ix+YSize-1 do
      for x:=ix to ix+XSize-1 do PutPixel(x,y,GetPix);
  end;
end;

procedure PutVIF256(x,y:integer; var T:TVIFMap);
var
  movesize:word;
  srcaddsize:word;
  dstaddsize:word;
  loopsize:word;
  srcoffs,dstoffs:word;
  viewport:ViewPortType;
  rView,rBitmap:TRect;
begin
  GetViewSettings(Viewport);
  with viewport do rView.Assign(x1,y1,x2,y2);
  with T do rBitmap.Assign(x,y,x+XSize,y+YSize);
  rBitmap.Intersect(rView);
  if rBitmap.Empty then exit;
  movesize := (rBitmap.b.x - rBitmap.a.x)+1;
  loopsize := (rBitmap.b.y - rBitmap.a.y);
  srcaddsize := T.XSize-movesize;
  dstaddsize := ScreenX-movesize;
  srcoffs    := (rBitmap.a.x-x)+((rBitmap.a.y-y)*T.XSize);
  asm
    mov  ax,[rBitmap].TRect.A.Y
    mul  ScreenX
    add  ax,[rBitmap].TRect.A.X
    adc  dx,0
    mov  dstoffs,ax
    mov  ax,4f05h
    xor  bx,bx
    int  10h
    {---}
    cld
    jmp @start
  @moveit:
    shr  cx,1
    rep  movsw
    adc  cx,cx
    rep  movsb
    retn
  @incbank:
    push bx {setting bank}
    mov  ax,4f05h
    xor  bx,bx
    inc  dx
    int  10h
    pop  bx
    retn
  @start:
    mov  ax,SegA000
    mov  es,ax
    mov  di,dstoffs

    push ds
    lds  si,T
    add  si,2+2+1
    add  si,srcoffs

    mov  bx,loopsize
  @loop:
    mov  cx,movesize
    mov  ax,di
    add  ax,cx
    jnc  @doit
    sub  cx,ax
    call @moveit
    mov  cx,ax
    call @incbank
    call @moveit
    add  si,srcaddsize
    add  di,dstaddsize
    jmp  @skip
  @doit:
    shr  cx,1
    rep  movsw
    adc  cx,cx
    rep  movsb
    add  si,srcaddsize
    add  di,dstaddsize
    jnc  @skip
    call @incbank
  @skip:
    dec  bx
    jnz  @loop
    pop  ds
  end;
end;

{$IFDEF DPMI}
procedure PutVIF1(X,Y:integer;var BitMap); assembler;
    Var
      V : ViewPortType;
    asm
               cld
               mov     ax,cs
               add     ax,SelectorInc
               db      66h;rol ax,16
               push    ds
               push    bp
               push    ss
               lea     ax,V
               push    ax
               call    Graph.GetViewSettings
               mov     ax,X
               mov     bx,Y
               add     ax,V.X1
               add     bx,V.Y1
               mov     cx,ax
               mov     dx,bx
               les     si,BitMap
               mov     di,es:[si]
               push    es
               db 66h;rol ax,16
               mov es,ax
               db 66h;rol ax,16
               mov     word ptr es:@AddBufY,di
               pop es
               add     cx,di
               add     dx,es:[si+02]
               xor     di,di
               cmp     bx,V.Y1
               jge     @MX1
               push    dx
               push    ax
               mov     ax,V.Y1
               sub     ax,bx
               mul     word ptr es:[si]
               mov     di,ax
               pop     ax
               pop     dx
               mov     bx,V.Y1
@MX1:          cmp     ax,V.X1
               jge     @MX2
               add     di,V.X1
               sub     di,ax
               mov     ax,V.X1
@MX2:          inc     di {!}
               add     si,di
               cmp     dx,V.Y2
               jle     @MX3
               mov     dx,V.Y2
               inc     dx
@MX3:          cmp     cx,V.X2
               jle     @MX4
               mov     cx,V.X2
               inc     cx
@MX4:          add     si,+04
               sub     cx,ax
               jle     @Exit
               sub     dx,bx
               jle     @Exit
               push    es
               push    si
               mov     si,ax
               mov     di,bx
               push    cx
               call    @CalcDI
               pop     cx
               pop     si
               mov     bp,dx
               mov     dx,ScreenX
               inc     dx
               shr     dx,1
               shr     dx,1
               shr     dx,1
               push    es
               db 66h;rol ax,16
               mov es,ax
               db 66h;rol ax,16
               mov     word ptr es:@AddScrY,dx
               pop es
               pop     ds
               push    ax
               call    @InitPort
               pop     ax
               call    @DumpRect
               call    @DonePort
@Exit:         pop     bp
               pop     ds
               jmp     @Esc

@CalcDI:
               call    _CalcScrAdr
               mov     ah,$80
               mov     cl,al
               shr     ah,cl
               mov     es,VideoSeg
               retn

@DumpRect:
               mov     bl,cl
               and     bl,$07
               jz      @X1
               add     cx,$08
@X1:           shr     cx,1
               shr     cx,1
               shr     cx,1
               mov     al,ah
               mov     bh,$08
               cmp     cx,1
               jnz     @Loop3
               or      bl,bl
               jz      @Loop3
               mov     bh,bl
@Loop3:        out     dx,al
               push    di
               push    si
               push    bp
@Loop2:        push    di
               push    si
               push    cx
@Loop1:        mov     ah,es:[di]
               movsb
               add     si,+07
               Loop    @Loop1
               pop     cx
               pop     si
               pop     di
               add     si,word ptr cs:@AddBufY
               add     di,word ptr cs:@AddScrY
               dec     bp
               jnz     @Loop2
               pop     bp
               pop     si
               inc     si
               pop     di
               ror     al,1
               jnb     @X2
               inc     di
@X2:           dec     bl
               jnz     @X3
               dec     cx
@X3:           dec     bh
               jnz     @Loop3
               retn
@AddBufY:      dw      0
@AddScrY:      dw      0

@InitPort:     mov     dx,$3CE
               mov     ax,$0205
               out     dx,ax
               mov     al,$08
               out     dx,al
               inc     dx
               retn

@DonePort:     mov   dx,$3CE
               mov   ax,$0005
               out   dx,ax
               mov   ax,$0003
               out   dx,ax
               mov   ax,$FF08
               out   dx,ax
               mov   dx,$3C4
               mov   ax,$0F02
               out   dx,ax
               retn
@Esc:
    end;
{$ELSE}
procedure PutVIF1(X,Y:integer;var BitMap); assembler;
    Var
      V : ViewPortType;
    asm
               cld
               push    ds
               push    bp
               push    ss
               lea     ax,V
               push    ax
               call    Graph.GetViewSettings
               mov     ax,X
               mov     bx,Y
               add     ax,V.X1
               add     bx,V.Y1
               mov     cx,ax
               mov     dx,bx
               les     si,BitMap
               mov     di,es:[si]
               mov     word ptr cs:@AddBufY,di
               add     cx,di
               add     dx,es:[si+02]
               xor     di,di
               cmp     bx,V.Y1
               jge     @MX1
               push    dx
               push    ax
               mov     ax,V.Y1
               sub     ax,bx
               mul     word ptr es:[si]
               mov     di,ax
               pop     ax
               pop     dx
               mov     bx,V.Y1
@MX1:          cmp     ax,V.X1
               jge     @MX2
               add     di,V.X1
               sub     di,ax
               mov     ax,V.X1
@MX2:          inc     di {!}
               add     si,di
               cmp     dx,V.Y2
               jle     @MX3
               mov     dx,V.Y2
               inc     dx
@MX3:          cmp     cx,V.X2
               jle     @MX4
               mov     cx,V.X2
               inc     cx
@MX4:          add     si,+04
               sub     cx,ax
               jle     @Exit
               sub     dx,bx
               jle     @Exit
               push    es
               push    si
               mov     si,ax
               mov     di,bx
               push    cx
               call    @CalcDI
               pop     cx
               pop     si
               mov     bp,dx
               mov     dx,ScreenX
               inc     dx
               shr     dx,1
               shr     dx,1
               shr     dx,1
               mov     word ptr cs:@AddScrY,dx
               pop     ds
               push    ax
               call    @InitPort
               pop     ax
               call    @DumpRect
               call    @DonePort
@Exit:         pop     bp
               pop     ds
               jmp     @Esc

@CalcDI:
               call    _CalcScrAdr
               mov     ah,$80
               mov     cl,al
               shr     ah,cl
               mov     es,VideoSeg
               retn

@DumpRect:
               mov     bl,cl
               and     bl,$07
               jz      @X1
               add     cx,$08
@X1:           shr     cx,1
               shr     cx,1
               shr     cx,1
               mov     al,ah
               mov     bh,$08
               cmp     cx,1
               jnz     @Loop3
               or      bl,bl
               jz      @Loop3
               mov     bh,bl
@Loop3:        out     dx,al
               push    di
               push    si
               push    bp
@Loop2:        push    di
               push    si
               push    cx
@Loop1:        mov     ah,es:[di]
               movsb
               add     si,+07
               Loop    @Loop1
               pop     cx
               pop     si
               pop     di
               add     si,word ptr cs:@AddBufY
               add     di,word ptr cs:@AddScrY
               dec     bp
               jnz     @Loop2
               pop     bp
               pop     si
               inc     si
               pop     di
               ror     al,1
               jnb     @X2
               inc     di
@X2:           dec     bl
               jnz     @X3
               dec     cx
@X3:           dec     bh
               jnz     @Loop3
               retn
@AddBufY:      dw      0
@AddScrY:      dw      0

@InitPort:     mov     dx,$3CE
               mov     ax,$0205
               out     dx,ax
               mov     al,$08
               out     dx,al
               inc     dx
               retn

@DonePort:     mov   dx,$3CE
               mov   ax,$0005
               out   dx,ax
               mov   ax,$0003
               out   dx,ax
               mov   ax,$FF08
               out   dx,ax
               mov   dx,$3C4
               mov   ax,$0F02
               out   dx,ax
               retn
@Esc:
    end;
{$ENDIF}

{$IFDEF DPMI}
{here! here! the bug is here! please someone help me! A.S.A.P}
procedure PutVIF2(X,Y:Integer; Var BitMap);assembler;
    Var
      FAddSI   : Word;
      FAddDI   : Word;
      BAddSI   : Word;
      BAddDI   : Word;
      YSize    : Word;
      MemXSize : Word;
      ScrXSize : Word;
    asm
               push    bp
               mov     ax,cs
               add     ax,SelectorInc
               mov     es,ax
               db 66h;rol ax,16
               call    @Init
               pop     bp
               jmp     @Esc
{--------------------------------------}
@DumpIt:       mov     ax,$0308              {Initial future out Values}
               jmp     @Dmp1
@LMainLoop:
               push    dx                    {select next Plane}
               push    ax
               mov     dx,$3C5
               out     dx,al
               mov     dx,$3CF
               mov     al,ah
               out     dx,al
               pop     ax
               pop     dx
@Dmp1:
               push    ax                    {save registers}
               push    bx
               push    bp
               push    si
               push    di
               add     si,cs:[bx]
               inc     bx
               inc     bx
               mov     ds,cs:[bx]           {Select next Segment,each seg contains 1 plane}
@BXVal:        mov     bx,0000              {offset + 1}   {scr bit mask value}

@LYLoop:       mov     ch,00                {offset @LYLoop+1 byte} {X size value}
@LCont0:       jmp     @RStart
@LCont1:       jmp     @RMiddle
@LCont2:       jmp     @REnd
@LCont3:
@AddDIVal:     add     di,$FFFF             {offset + 2} {next line}
@AddSIVal:     add     si,$FFFF             {offset + 2} {next data line}
               dec     bp                   {dec Y counter}
               jnz     @LYLoop
               pop     di
               pop     si
               pop     bp
               pop     bx
               pop     ax
               dec     bx                   {inc Data Seg Index}
               dec     bx
               dec     bx
               dec     bx
               shr     al,1                 {next write enable plane}
               or      ah,ah                {check for all planes dumped}
               jz      @LEndLoop
               dec     ah                   {next read enable plane}
               jmp     @LMainLoop
@LEndLoop:     retn
{Never write any code from here to @REnd}
{because of short jumps!}
@LStart:       lodsb                        {get mem data}
               mov     ah,al
               mov     al,[si]
               shl     ax,cl                {shift it to adjust scr bit position}
               and     ah,dh                {mask for used bits}
               mov     al,es:[di]           {get video byte}
               and     al,bh                {mask for used bits}
               or      al,ah                {make or with Mem and Video}
               stosb                        {store to video mem}
               jmp     @LCont1

@LMiddle:      lodsb                        {get bitmap data}
               mov     ah,al
               mov     al,[si]
               shl     ax,cl                {shift it to adjust scr bit pos..}
               mov     al,ah                {store to AL}
               stosb                        {store to video mem}
               dec     ch
               jnz     @LMiddle
               jmp     @LCont2
@LEnd:
               lodsb
               shl     al,cl
               and     al,dl
               mov     ah,es:[di]
               and     ah,bl
               or      al,ah
               stosb
               jmp     @LCont3
@LEnd1:
               lodsb
               mov     ah,al
               mov     al,[si]
               shl     ax,cl
               and     ah,dl
               mov     al,es:[di]
               and     al,bl
               or      al,ah
               stosb
               inc     si
               jmp     @LCont3

@FastStart:
               lodsb
               and     al,dh
               mov     ah,es:[di]
               and     ah,bh
               or      al,ah
               stosb
               jmp     @LCont1
@FastMiddle:
               movsb
               dec     ch
               jnz     @FastMiddle
               jmp     @LCont2

@FastEnd:
               lodsb
               and     al,dl
               mov     ah,es:[di]
               and     ah,bl
               or      al,ah
               stosb
               jmp     @LCont3

@RStart0:      xor     al,al
               mov     ah,[si]
               shr     ax,cl
               and     al,dl
               mov     ah,es:[di]
               and     ah,bl
               or      al,ah
               stosb
               jmp     @LCont1

@RStart:       lodsb
               mov     ah,[si]
               shr     ax,cl
               and     al,dl
               mov     ah,es:[di]
               and     ah,bl
               or      al,ah
               stosb
               jmp     @LCont1

@RMiddle:      lodsb
               mov     ah,[si]
               shr     ax,cl
               stosb
               dec     ch
               jnz     @RMiddle
               jmp     @LCont2

@REnd:         lodsb
               shr     al,cl
               and     al,dh
               mov     ah,es:[di]
               and     ah,bh
               or      al,ah
               stosb
               jmp     @LCont3
{--------------------------------------------------------------------------}
{      Mem: 00001111 ... 11111000
               dh          dl
       Scr: 00111111 ... 11100000
            11000000 ... 00011111
               bh          bl
       Out:  AH : Read Plane #
             AL : Write Plane Bit
}
@InitPorts:    push    dx
               push    ax
               mov     dx,$3C4               {Initial Port Value}
               mov     ax,$0802              {Enable Write Plane 4}
               out     dx,ax                 {Enable Read Plane 4}
               mov     dx,$3CE
               mov     ax,$FF08              {Set all Bitmask}
               out     dx,ax
               mov     ax,$0304
               out     dx,ax
               pop     ax
               pop     dx
               retn

@DonePorts:    mov     dx,$3C4
               mov     ax,$FF02
               out     dx,ax
               mov     dx,$3CE
               mov     ax,$0004
               out     dx,ax
               retn

@SetForwardAdds:
               push    ax
               mov     ax,FAddSI
               mov     word ptr es:@AddSIVal[2],ax
               mov     ax,FAddDI
               mov     word ptr es:@AddDIVal[2],ax
               pop     ax
               retn
@SetBackwardAdds:
               push    ax
               mov     ax,BAddSI
               mov     word ptr es:@AddSIVal[2],ax
               mov     ax,BAddDI
               mov     word ptr es:@AddDIVal[2],ax
               add     si,MemXSize
               add     di,ScrXSize
               dec     di
               dec     si
               pop     ax
               retn

@SegTable:     DD 00,00,00,00
@BSizeX:       DB 00
@Init:         les     di,bitmap
               lea     di,[di].TVifMap.Planes
               mov     cx,NumPlanes
               mov     bx,offset @SegTable
               push ds
               db 66h;rol ax,16
               mov ds,ax
               db 66h;rol ax,16
@InLoop:       mov     ax,es:[di]
               mov     ds:[bx],ax
               mov     ax,es:[di+2]
               mov     ds:[bx+2],ax
               add     di,Type Pointer
               add     bx,Type Pointer
               loop    @InLoop
               pop     ds
               push    X
               push    Y
               les     di,BitMap
               push    es:[di].TVifMap.XSize
               push    es:[di].TVifMap.YSize {After call AX:X, DI:Y, SI:Offset}
               push    es:[di].TVifMap.XSize
               call    _AdjustViewPort       {after call,bx:XSize, DX:YSize}
               jnb     @X0
               jmp     @Exit
@X0:
               push    si
               mov     si,ax
               call    _CalcScrAdr
               pop     si
               push    di
               push    ax
               mov     YSize,dx
               mov     ch,cl             {save mem start bit in CH}
               xor     ah,ah
               mov     al,cl
               add     ax,bx
               push    ax
               Call    _PixelToByte
               mov     MemXSize,ax
               mov     dh,al
@CalcBothAdds:
               pop     di                {get scr Start bit}
               pop     ax
               push    ax
               push    di
               xor     ah,ah
               add     ax,bx
               call    _PixelToByte
               mov     ScrXSize,ax
               mov     bx,BytesPerLine {ssg was here}
               add     bx,ax
               mov     BAddDI,bx
               mov     bx,BytesPerLine
               sub     bx,ax
               mov     FAddDI,bx
               mov     ax,MemXSize
               les     di,BitMap
               mov     bx,es:[di].TVifMap.XSize
               xchg    ax,bx
               call    _PixelToByte
               mov     BAddSI,ax
               add     BAddSI,bx
               sub     ax,bx
               mov     FAddSI,ax               {end of calcing Add DI&SI}
               pop     ax
               mov     bx,$FFFF
               and     al,$07
               mov     cl,al
               shr     bl,cl
               not     bl
               mov     cl,ch
               shr     bh,cl
               cmp     dh,1
               jnz     @X1
               or      bl,bl
               jz      @X1
               and     bh,bl
               xor     bl,bl
@X1:
               pop     ax                    {restore scr bit start}
               pop     di                    {restore Scr offset}
               xor     ah,ah
               db 66h;rol ax,16
               mov es,ax
               db 66h;rol ax,16
               mov     byte ptr es:@LCont0[1],ah
               mov     byte ptr es:@LCont1[1],ah
               mov     byte ptr es:@LCont2[1],ah
               sub     cl,al
               jz      @SetFast
               ja      @SetLeft
               jmp     @SetRight

@SetFast:      cld
               cmp     bh,$FF
               jz      @SF1
               mov     ax,Offset @FastStart
               sub     ax,Offset @LCont1
               mov     byte ptr es:@LCont0[1],al
               or      dh,dh
               jz      @SF1
               dec     dh
@SF1:
               or      bl,bl
               jz      @SF2
               mov     ax,Offset @FastEnd
               sub     ax,Offset @LCont3
               mov     byte ptr es:@LCont2[1],al
               or      dh,dh
               jz      @SF2
               dec     dh
@SF2:
               or      dh,dh
               jz      @SF3
               mov     ax,Offset @FastMiddle
               sub     ax,Offset @LCont2
               mov     byte ptr es:@LCont1[1],al
@SF3:
               mov     byte ptr es:@LYLoop[1],dh
               call    @SetForwardAdds
               jmp     @SetOK

@SetLeft:      cld              {Trouble is in here ... 100% perc.. }
               mov     dl,bl    {25th Aug 93 - 00:50 - FatalicA said...}
                                {Bug found, 00:52..}
                                {Bug corrected 26th Aug 93 - 02:14}
               cmp     dh,2
               jae     @SL1
               shl     bx,cl
               cmp     dh,1
               jz      @SLSetStart
               mov     al,bh
               jmp     @SL2
@SL1:
               mov     al,$FF
               push    cx
@SLLoop1:      shl     bl,1
               rcl     al,1
               rcl     bh,1
               dec     cl
               jnz     @SLLoop1
               pop     cx
@SL2:          or      dl,dl
               jz      @SLSetLEnd1
               or      bl,bl
               jz      @SLSetLEnd1X
@SLSetLEnd:
               mov     ax,Offset @LEnd
               sub     ax,Offset @LCont3
               mov     byte ptr es:@LCont2[1],al
               or      dh,dh
               jz      @SLSetStart
               dec     dh
               jmp     @SLSetStart
@SLSetLEnd1:
               or      bl,bl
               mov     bl,al
               jz      @SLSetLEnd
@SLSetLEnd1X:  mov     bl,al
               mov     ax,Offset @LEnd1
               sub     ax,Offset @LCont3
               mov     byte ptr es:@LCont2[1],al
               or      dh,dh
               jz      @SLSetStart
               dec     dh
               or      dh,dh
               jz      @SLSetStart
               dec     dh
@SLSetStart:
               cmp     bh,$FF
               jz      @SLSetMiddle
               or      dh,dh
               jz      @SLEnd
               mov     ax,Offset @LStart
               sub     ax,Offset @LCont1
               mov     byte ptr es:@LCont0[1],al
               or      dh,dh
               jz      @SLSetMiddle
               dec     dh
@SLSetMiddle:
               or      dh,dh
               jz      @SLEnd
               mov     ax,Offset @LMiddle
               sub     ax,Offset @LCont2
               mov     byte ptr es:@LCont1[1],al
@SLENd:
               mov     byte ptr es:@LYLoop[1],dh
               call    @SetForwardAdds
               jmp     @SetOK
                                           {    BL<>0 and DL<>0 LEnd       }
                                           {    BL=0 and DL<>0 LEnd1 BL=AL }
@SetRight:     std
               neg     cl
               mov     dl,bl
               xor     ch,ch
               push    cx
@SRL1:         shr     bx,1
               rcr     ch,1
               dec     cl
               jnz     @SRL1
               or      ch,ch
               jz      @SRX0
               mov     bl,ch
@SRX0:         pop     cx
               jnz     @SRX1
               or      bl,bl
               jz      @SR1
               or      dl,dl
               jz      @SRX1
               mov     ax,Offset @RStart
               sub     ax,Offset @LCont1
               mov     byte ptr es:@LCont0[1],al
               or      dh,dh
               jz      @SR1
               dec     dh
               jmp     @SR1
@SRX1:
               mov     ax,Offset @RStart0
               sub     ax,Offset @LCont1
               mov     byte ptr es:@LCont0[1],al
{               or      dh,dh
               jz      @SR1
               dec     dh    }
@SR1:
               cmp     bh,$FF
               jz      @SR2
               mov     ax,Offset @REnd
               sub     ax,Offset @LCont3
               mov     byte ptr es:@LCont2[1],al
               or      dh,dh
               jz      @SR2
               dec     dh
@SR2:
               or      dh,dh
               jz      @SR3
               mov     ax,Offset @RMiddle
               sub     ax,Offset @LCont2
               mov     byte ptr es:@LCont1[1],al
@SR3:
               mov     byte ptr es:@LYLoop[1],dh
               call    @SetbackwardAdds
@SetOK:
               mov     dx,bx
               not     bx
               mov     bp,YSize
               mov     word ptr es:@BXVal[1],bx
               mov     bx,offset @SegTable + 12
               mov     es,VideoSeg
               call    @InitPorts
               push    ds
               call    @DumpIt
               pop     ds
               call    @DonePorts
@Exit:
               retn
@Esc:
    end;
{$ELSE}
procedure PutVIF2(X,Y:Integer; Var BitMap);assembler;
    Var
      FAddSI   : Word;
      FAddDI   : Word;
      BAddSI   : Word;
      BAddDI   : Word;
      YSize    : Word;
      MemXSize : Word;
      ScrXSize : Word;
    asm
               push    bp
               call    @Init
               pop     bp
               jmp     @Esc
{--------------------------------------}
@DumpIt:       mov     ax,$0308              {Initial future out Values}
               jmp     @Dmp1
@LMainLoop:
               push    dx                    {select next Plane}
               push    ax
               mov     dx,$3C5
               out     dx,al
               mov     dx,$3CF
               mov     al,ah
               out     dx,al
               pop     ax
               pop     dx
@Dmp1:
               push    ax                    {save registers}
               push    bx
               push    bp
               push    si
               push    di
               add     si,cs:[bx]
               inc     bx
               inc     bx
               mov     ds,cs:[bx]           {Select next Segment,each seg contains 1 plane}
@BXVal:        mov     bx,0000              {offset + 1}   {scr bit mask value}

@LYLoop:       mov     ch,00                {offset @LYLoop+1 byte} {X size value}
@LCont0:       jmp     @RStart
@LCont1:       jmp     @RMiddle
@LCont2:       jmp     @REnd
@LCont3:
@AddDIVal:     add     di,$FFFF             {offset + 2} {next line}
@AddSIVal:     add     si,$FFFF             {offset + 2} {next data line}
               dec     bp                   {dec Y counter}
               jnz     @LYLoop
               pop     di
               pop     si
               pop     bp
               pop     bx
               pop     ax
               dec     bx                   {inc Data Seg Index}
               dec     bx
               dec     bx
               dec     bx
               shr     al,1                 {next write enable plane}
               or      ah,ah                {check for all planes dumped}
               jz      @LEndLoop
               dec     ah                   {next read enable plane}
               jmp     @LMainLoop
@LEndLoop:     retn
{Never write any code from here to @REnd}
{because of short jumps!}
@LStart:       lodsb                        {get mem data}
               mov     ah,al
               mov     al,[si]
               shl     ax,cl                {shift it to adjust scr bit position}
               and     ah,dh                {mask for used bits}
               mov     al,es:[di]           {get video byte}
               and     al,bh                {mask for used bits}
               or      al,ah                {make or with Mem and Video}
               stosb                        {store to video mem}
               jmp     @LCont1

@LMiddle:      lodsb                        {get bitmap data}
               mov     ah,al
               mov     al,[si]
               shl     ax,cl                {shift it to adjust scr bit pos..}
               mov     al,ah                {store to AL}
               stosb                        {store to video mem}
               dec     ch
               jnz     @LMiddle
               jmp     @LCont2
@LEnd:
               lodsb
               shl     al,cl
               and     al,dl
               mov     ah,es:[di]
               and     ah,bl
               or      al,ah
               stosb
               jmp     @LCont3
@LEnd1:
               lodsb
               mov     ah,al
               mov     al,[si]
               shl     ax,cl
               and     ah,dl
               mov     al,es:[di]
               and     al,bl
               or      al,ah
               stosb
               inc     si
               jmp     @LCont3

@FastStart:
               lodsb
               and     al,dh
               mov     ah,es:[di]
               and     ah,bh
               or      al,ah
               stosb
               jmp     @LCont1
@FastMiddle:
               movsb
               dec     ch
               jnz     @FastMiddle
               jmp     @LCont2

@FastEnd:
               lodsb
               and     al,dl
               mov     ah,es:[di]
               and     ah,bl
               or      al,ah
               stosb
               jmp     @LCont3

@RStart0:      xor     al,al
               mov     ah,[si]
               shr     ax,cl
               and     al,dl
               mov     ah,es:[di]
               and     ah,bl
               or      al,ah
               stosb
               jmp     @LCont1

@RStart:       lodsb
               mov     ah,[si]
               shr     ax,cl
               and     al,dl
               mov     ah,es:[di]
               and     ah,bl
               or      al,ah
               stosb
               jmp     @LCont1

@RMiddle:      lodsb
               mov     ah,[si]
               shr     ax,cl
               stosb
               dec     ch
               jnz     @RMiddle
               jmp     @LCont2

@REnd:         lodsb
               shr     al,cl
               and     al,dh
               mov     ah,es:[di]
               and     ah,bh
               or      al,ah
               stosb
               jmp     @LCont3
{--------------------------------------------------------------------------}
{      Mem: 00001111 ... 11111000
               dh          dl
       Scr: 00111111 ... 11100000
            11000000 ... 00011111
               bh          bl
       Out:  AH : Read Plane #
             AL : Write Plane Bit
}
@InitPorts:    push    dx
               push    ax
               mov     dx,$3C4               {Initial Port Value}
               mov     ax,$0802              {Enable Write Plane 4}
               out     dx,ax                 {Enable Read Plane 4}
               mov     dx,$3CE
               mov     ax,$FF08              {Set all Bitmask}
               out     dx,ax
               mov     ax,$0304
               out     dx,ax
               pop     ax
               pop     dx
               retn

@DonePorts:    mov     dx,$3C4
               mov     ax,$FF02
               out     dx,ax
               mov     dx,$3CE
               mov     ax,$0004
               out     dx,ax
               retn

@SetForwardAdds:
               push    ax
               mov     ax,FAddSI
               mov     word ptr cs:@AddSIVal[2],ax
               mov     ax,FAddDI
               mov     word ptr cs:@AddDIVal[2],ax
               pop     ax
               retn
@SetBackwardAdds:
               push    ax
               mov     ax,BAddSI
               mov     word ptr cs:@AddSIVal[2],ax
               mov     ax,BAddDI
               mov     word ptr cs:@AddDIVal[2],ax
               add     si,MemXSize
               add     di,ScrXSize
               dec     di
               dec     si
               pop     ax
               retn

@SegTable:     DD 00,00,00,00
@BSizeX:       DB 00
@Init:         les     di,bitmap
               lea     di,[di].TVifMap.Planes
               mov     cx,NumPlanes
               mov     bx,offset @SegTable
@InLoop:       mov     ax,es:[di]
               mov     cs:[bx],ax
               mov     ax,es:[di+2]
               mov     cs:[bx+2],ax
               add     di,Type Pointer
               add     bx,Type Pointer
               loop    @InLoop
               push    X
               push    Y
               les     di,BitMap
               push    es:[di].TVifMap.XSize
               push    es:[di].TVifMap.YSize {After call AX:X, DI:Y, SI:Offset}
               push    es:[di].TVifMap.XSize
               call    _AdjustViewPort       {after call,bx:XSize, DX:YSize}
               jnb     @X0
               jmp     @Exit
@X0:
               push    si
               mov     si,ax
               call    _CalcScrAdr
               pop     si
               push    di
               push    ax
               mov     YSize,dx
               mov     ch,cl             {save mem start bit in CH}
               xor     ah,ah
               mov     al,cl
               add     ax,bx
               push    ax
               Call    _PixelToByte
               mov     MemXSize,ax
               mov     dh,al
@CalcBothAdds:
               pop     di                {get scr Start bit}
               pop     ax
               push    ax
               push    di
               xor     ah,ah
               add     ax,bx
               call    _PixelToByte
               mov     ScrXSize,ax
               mov     bx,BytesPerLine {ssg was here}
               add     bx,ax
               mov     BAddDI,bx
               mov     bx,BytesPerLine
               sub     bx,ax
               mov     FAddDI,bx
               mov     ax,MemXSize
               les     di,BitMap
               mov     bx,es:[di].TVifMap.XSize
               xchg    ax,bx
               call    _PixelToByte
               mov     BAddSI,ax
               add     BAddSI,bx
               sub     ax,bx
               mov     FAddSI,ax               {end of calcing Add DI&SI}
               pop     ax
               mov     bx,$FFFF
               and     al,$07
               mov     cl,al
               shr     bl,cl
               not     bl
               mov     cl,ch
               shr     bh,cl
               cmp     dh,1
               jnz     @X1
               or      bl,bl
               jz      @X1
               and     bh,bl
               xor     bl,bl
@X1:
               pop     ax                    {restore scr bit start}
               pop     di                    {restore Scr offset}
               xor     ah,ah
               mov     byte ptr cs:@LCont0[1],ah
               mov     byte ptr cs:@LCont1[1],ah
               mov     byte ptr cs:@LCont2[1],ah
               sub     cl,al
               jz      @SetFast
               ja      @SetLeft
               jmp     @SetRight

@SetFast:      cld
               cmp     bh,$FF
               jz      @SF1
               mov     ax,Offset @FastStart
               sub     ax,Offset @LCont1
               mov     byte ptr cs:@LCont0[1],al
               or      dh,dh
               jz      @SF1
               dec     dh
@SF1:
               or      bl,bl
               jz      @SF2
               mov     ax,Offset @FastEnd
               sub     ax,Offset @LCont3
               mov     byte ptr cs:@LCont2[1],al
               or      dh,dh
               jz      @SF2
               dec     dh
@SF2:
               or      dh,dh
               jz      @SF3
               mov     ax,Offset @FastMiddle
               sub     ax,Offset @LCont2
               mov     byte ptr cs:@LCont1[1],al
@SF3:
               mov     byte ptr cs:@LYLoop[1],dh
               call    @SetForwardAdds
               jmp     @SetOK

@SetLeft:      cld              {Trouble is in here ... 100% perc.. }
               mov     dl,bl    {25th Aug 93 - 00:50 - FatalicA said...}
                                {Bug found, 00:52..}
                                {Bug corrected 26th Aug 93 - 02:14}
               cmp     dh,2
               jae     @SL1
               shl     bx,cl
               cmp     dh,1
               jz      @SLSetStart
               mov     al,bh
               jmp     @SL2
@SL1:
               mov     al,$FF
               push    cx
@SLLoop1:      shl     bl,1
               rcl     al,1
               rcl     bh,1
               dec     cl
               jnz     @SLLoop1
               pop     cx
@SL2:          or      dl,dl
               jz      @SLSetLEnd1
               or      bl,bl
               jz      @SLSetLEnd1X
@SLSetLEnd:
               mov     ax,Offset @LEnd
               sub     ax,Offset @LCont3
               mov     byte ptr cs:@LCont2[1],al
               or      dh,dh
               jz      @SLSetStart
               dec     dh
               jmp     @SLSetStart
@SLSetLEnd1:
               or      bl,bl
               mov     bl,al
               jz      @SLSetLEnd
@SLSetLEnd1X:  mov     bl,al
               mov     ax,Offset @LEnd1
               sub     ax,Offset @LCont3
               mov     byte ptr cs:@LCont2[1],al
               or      dh,dh
               jz      @SLSetStart
               dec     dh
               or      dh,dh
               jz      @SLSetStart
               dec     dh
@SLSetStart:
               cmp     bh,$FF
               jz      @SLSetMiddle
               or      dh,dh
               jz      @SLEnd
               mov     ax,Offset @LStart
               sub     ax,Offset @LCont1
               mov     byte ptr cs:@LCont0[1],al
               or      dh,dh
               jz      @SLSetMiddle
               dec     dh
@SLSetMiddle:
               or      dh,dh
               jz      @SLEnd
               mov     ax,Offset @LMiddle
               sub     ax,Offset @LCont2
               mov     byte ptr cs:@LCont1[1],al
@SLENd:
               mov     byte ptr cs:@LYLoop[1],dh
               call    @SetForwardAdds
               jmp     @SetOK
                                           {    BL<>0 and DL<>0 LEnd       }
                                           {    BL=0 and DL<>0 LEnd1 BL=AL }
@SetRight:     std
               neg     cl
               mov     dl,bl
               xor     ch,ch
               push    cx
@SRL1:         shr     bx,1
               rcr     ch,1
               dec     cl
               jnz     @SRL1
               or      ch,ch
               jz      @SRX0
               mov     bl,ch
@SRX0:         pop     cx
               jnz     @SRX1
               or      bl,bl
               jz      @SR1
               or      dl,dl
               jz      @SRX1
               mov     ax,Offset @RStart
               sub     ax,Offset @LCont1
               mov     byte ptr cs:@LCont0[1],al
               or      dh,dh
               jz      @SR1
               dec     dh
               jmp     @SR1
@SRX1:
               mov     ax,Offset @RStart0
               sub     ax,Offset @LCont1
               mov     byte ptr cs:@LCont0[1],al
{               or      dh,dh
               jz      @SR1
               dec     dh    }
@SR1:
               cmp     bh,$FF
               jz      @SR2
               mov     ax,Offset @REnd
               sub     ax,Offset @LCont3
               mov     byte ptr cs:@LCont2[1],al
               or      dh,dh
               jz      @SR2
               dec     dh
@SR2:
               or      dh,dh
               jz      @SR3
               mov     ax,Offset @RMiddle
               sub     ax,Offset @LCont2
               mov     byte ptr cs:@LCont1[1],al
@SR3:
               mov     byte ptr cs:@LYLoop[1],dh
               call    @SetbackwardAdds
@SetOK:
               mov     dx,bx
               not     bx
               mov     bp,YSize
               mov     word ptr cs:@BXVal[1],bx
               mov     bx,offset @SegTable + 12
               mov     es,VideoSeg
               call    @InitPorts
               push    ds
               call    @DumpIt
               pop     ds
               call    @DonePorts
@Exit:
               retn
@Esc:
    end;
{$ENDIF}

{
 Return registers:
 ES:SI -> CharData
 BL    -> CharSizeX
 BH    -> CharSizeY
}
procedure GetBitMappedCharData(Chr:Byte; FontPtr:PFont); far; assembler;
    asm
               les     si,FontPtr
               mov     bl,Chr
               xor     ah,ah
               mov     al,es:[si].TFont.ChrX
               call    _PixelToByte
               mul     bl
               mov     bl,es:[si].TFont.ChrX
               mov     bh,es:[si].TFont.ChrY
               mul     bh
               lea     si,[si].TFont.Data1
               add     si,ax
    end;

procedure GetPropCharData(Chr:Byte; FontPtr:PFont); far; assembler;
    asm
               les     si,FontPtr
               xor     bh,bh
               mov     bl,Chr
               shl     bx,1
               mov     ax,word ptr es:[bx+si].TFont.TblChrOfs
               shr     bx,1
               mov     bl,byte ptr es:[si+bx].TFont.TblChrX
               mov     bh,es:[si].TFont.ChrY1
               lea     si,[si].TFont.Data2
               add     si,ax
    end;

procedure SetCharDataProc(FontPtr:PFont; Var Proc:Pointer);
    begin
      Proc := Nil;
      if FontPtr <> Nil then
        Case FontPtr^.FontType of
           FtBitmapped    : Proc := @GetBitMappedCharData;
           FtProportional : Proc := @GetPropCharData;
        end;
    end;

const

  xseg = $65;

{$IFDEF DPMI}
procedure MakeFontImage(Var S:String; FontPtr:PFont); assembler;
    asm
               mov     ax,cs
               add     ax,SelectorInc
               db 66h;rol ax,16

{               push    word ptr S[2]
               push    word ptr S
               call    GetStringId
               or      ax,ax
               jz      @Exit}

               db 66h;rol ax,16
               mov     es,ax
               db 66h;rol ax,16
               {mov     word ptr es:@CurrentStrId,ax {!!}

               push    word ptr FontPtr[2]
               push    word ptr FontPtr
               push    es                       {!!}
               mov     ax,offset @GetCharData
               push    ax
               call    SetCharDataProc

               mov     ax,word ptr cs:@GetCharData
               or      ax,word ptr cs:@GetCharData[2]
               jz      @Exit

               xor     ax,ax

               db 66h;rol ax,16
               mov     es,ax
               db 66h;rol ax,16
               mov     word ptr es:@TotStrX,ax  {!!}
               cld
               les     di,FontLineBuf
               mov     dx,di
               mov     cx,Type TFontLineBuf / 2
               xor     ax,ax
               repz    stosw
               push    ds
               lds     bx,S
               mov     ch,[bx]
               inc     bx
               pop     ds
@NextChar:
               push    ds
               mov     ds,word ptr S[2]
               mov     al,[bx]
               pop     ds
               inc     bx
               push    bx
               push    cx
               push    dx

               push    cx     {saving for proc destroying}
               push    dx

               push    ax
               push    word ptr FontPtr[2]
               push    word ptr FontPtr
               call    dword ptr cs:@GetCharData
               pop     dx
               pop     cx
               or      bl,bl
               jz      @GoNextChar
               rol     ax,16

               push    es
               db 66h;rol ax,16
               mov     es,ax
               db 66h;rol ax,16
               add     byte ptr es:@TotStrX,bl      {!!}
               adc     byte ptr es:@TotStrX[1],0    {!!}
               pop     es
               cmp     word ptr cs:@TotStrX,640
               jbe     @3
               pop     dx
               pop     cx
               pop     bx
               jmp     @Exit
@3:
               push    bx
               mov     ch,cl
               mov     cl,bl
               and     cl,$07
               mov     ax,$FF00
               shr     ax,cl
               or      cl,cl
               jnz     @2
               mov     al,ah
@2:            mov     cl,ch
               shr     al,cl
               push    es
               db 66h;rol ax,16
               mov     es,ax
               db 66h;rol ax,16
               mov     byte ptr es:@SkipFlg,$F9  {stc}
               jnb     @1
               mov     byte ptr es:@SkipFlg,$F8  {clc}
@1:
               pop     es
               xor     ah,ah
               mov     al,bl
               call    _PixelToByte
               mov     ch,al
               mov     ax,es
               mov     es,word ptr FontLineBuf[2]
               push    ds
               mov     ds,ax
@YLoop:
               mov     bl,ch
               mov     di,dx
               xor     ah,ah
@XLoop:
               mov     al,[si]
               shr     ax,cl
               mov     ah,[si]
               or      es:[di],al
               inc     di
               inc     si
               dec     bl
               jnz     @XLoop
@SkipFlg:      stc
               jb      @Skip1
               xor     al,al
               shr     ax,cl
               or      es:[di],al
@Skip1:
               add     dx,BytesPerLine {ssg was here}
               dec     bh
               jnz     @YLoop
               pop     ds
               pop     bx            {restore chrSizeX & Y}
@GoNextChar:
               pop     dx            {restore BufStart}
               pop     cx            {restore Chr Count}
               add     cl,bl
               mov     bl,cl
               and     cl,$07
               xor     bh,bh
               shr     bl,1
               shr     bl,1
               shr     bl,1
               add     dx,bx
               pop     bx            {restore String Data offset}
               dec     ch
               jnz     @NextChar
               jmp     @Exit
@GetCharData:  dd 0
@CurrentStrId: dw 0
@TotStrX:      dw 0
@Exit:
    end;
{$ELSE}
procedure MakeFontImage(Var S:String; FontPtr:PFont); assembler;
    asm
{               push    word ptr S[2]
               push    word ptr S
               call    GetStringId
               or      ax,ax
               jz      @Exit
               mov     word ptr cs:@CurrentStrId,ax}
               push    word ptr FontPtr[2]
               push    word ptr FontPtr
               push    cs
               mov     ax,offset @GetCharData
               push    ax
               call    SetCharDataProc
               mov     ax,word ptr cs:@GetCharData
               or      ax,word ptr cs:@GetCharData[2]
               jz      @Exit

               xor     ax,ax
               mov     word ptr cs:@TotStrX,ax
               cld
               les     di,FontLineBuf
               mov     dx,di
               mov     cx,Type TFontLineBuf / 2
               xor     ax,ax
               repz    stosw
               push    ds
               lds     bx,S
               mov     ch,[bx]
               inc     bx
               pop     ds
@NextChar:
               push    ds
               mov     ds,word ptr S[2]
               mov     al,[bx]
               pop     ds
               inc     bx
               push    bx
               push    cx
               push    dx

               push    cx     {saving for proc destroying}
               push    dx

               push    ax
               push    word ptr FontPtr[2]
               push    word ptr FontPtr
               call    dword ptr cs:@GetCharData
               pop     dx
               pop     cx
               or      bl,bl
               jz      @GoNextChar
               add     byte ptr cs:@TotStrX,bl
               adc     byte ptr cs:@TotStrX[1],0
               cmp     word ptr cs:@TotStrX,640
               jbe     @3
               pop     dx
               pop     cx
               pop     bx
               jmp     @Exit
@3:
               push    bx
               mov     ch,cl
               mov     cl,bl
               and     cl,$07
               mov     ax,$FF00
               shr     ax,cl
               or      cl,cl
               jnz     @2
               mov     al,ah
@2:            mov     cl,ch
               shr     al,cl
               mov     byte ptr cs:@SkipFlg,$F9  {stc}
               jnb     @1
               mov     byte ptr cs:@SkipFlg,$F8  {clc}
@1:
               xor     ah,ah
               mov     al,bl
               call    _PixelToByte
               mov     ch,al
               mov     ax,es
               mov     es,word ptr FontLineBuf[2]
               push    ds
               mov     ds,ax
@YLoop:
               mov     bl,ch
               mov     di,dx
               xor     ah,ah
@XLoop:
               mov     al,[si]
               shr     ax,cl
               mov     ah,[si]
               or      es:[di],al
               inc     di
               inc     si
               dec     bl
               jnz     @XLoop
@SkipFlg:      stc
               jb      @Skip1
               xor     al,al
               shr     ax,cl
               or      es:[di],al
@Skip1:
               add     dx,BytesPerLine {ssg was here}
               dec     bh
               jnz     @YLoop
               pop     ds
               pop     bx            {restore chrSizeX & Y}
@GoNextChar:
               pop     dx            {restore BufStart}
               pop     cx            {restore Chr Count}
               add     cl,bl
               mov     bl,cl
               and     cl,$07
               xor     bh,bh
               shr     bl,1
               shr     bl,1
               shr     bl,1
               add     dx,bx
               pop     bx            {restore String Data offset}
               dec     ch
               jnz     @NextChar
               jmp     @Exit
@GetCharData:  dd 0
@CurrentStrId: dw 0
@TotStrX:      dw 0
@Exit:
    end;

{$ENDIF}

{$IFDEF DPMI}
procedure PutFnt(X,Y,XSize,YSize:Integer; FC,BC:Byte; Var ImageBuffer; OrPut:Boolean);assembler;
    Var
      FAddSI   : Word;
      FAddDI   : Word;
      BAddSI   : Word;
      BAddDI   : Word;
      MemXSize : Word;
      ScrXSize : Word;
    asm
               push    bp
               mov     ax,cs
               add     ax,SelectorInc
               mov     es,ax
               db 66h;rol ax,16
               call    @Init
               pop     bp
               jmp     @Esc
{--------------------------------------}
@DumpIt:
               mov     ah,cs:[bx]
               inc     bx
               or      ah,ah
               jz      @LEndLoop
               mov     al,cs:[bx]
               inc     bx
               push    ax
               mov     dx,$3C4
               mov     al,$02
               out     dx,ax
               mov     dx,$3CE
               mov     al,$08
               out     dx,al
               inc     dx
               pop     ax
               mov     ah,al
               mov     al,cs:[bx]
               inc     bx
               push    es
               db 66h;rol ax,16
               mov  es,ax
               db 66h;rol ax,16
               mov     byte ptr es:@XorByte,ah
               pop     es
               push    bx
               push    bp
               push    si
               push    di
@BitMask:      mov     bx,0000              {BitMask}
               cmp     al,$01
               jz      @SYLoop
               cmp     al,$02
               jnz     @LYLoop
               push    dx
               push    ax
               mov     dx,$3CE
               or      ah,ah
               mov     ax,$1003            {set data rotate reg for OR }
               jz      @MakeOr
               mov     ah,$08              {set data rotate reg for AND }
@MakeOr:       out     dx,ax
               mov     al,$08
               out     dx,al
               pop     ax
               pop     dx

@LYLoop:       mov     ch,00                {offset @LYLoop+1 byte} {X size value}
@LCont0:       jmp     @Exit
@LCont1:       jmp     @Exit
@LCont2:       jmp     @Exit
@LCont3:
@AddDIVal:     add     di,$FFFF             {offset + 2} {next line}
@AddSIVal:     add     si,$FFFF             {offset + 2} {next data line}
               dec     bp                   {dec Y counter}
               jnz     @LYLoop
               jmp     @LoopEsc

@SYLoop:       mov     ch,00
@SCont0:       jmp     @Exit
@SCont1:       jmp     @Exit
@SCont2:       jmp     @Exit
@SCont3:
@SAddDIVal:    add     di,$FFFF             {offset + 2} {next line}
@SAddSIVal:    add     si,$FFFF             {offset + 2} {next data line}
               dec     bp                   {dec Y counter}
               jnz     @SYLoop
@LoopEsc:
               pop     di
               pop     si
               pop     bp
               pop     bx
               jmp     @DumpIt
@LEndLoop:     retn
{Never write any code from here to @REnd}
{because of short jumps!}

@LStart:
               mov     al,bh               {set bit mask index}
               out     dx,al
               lodsb                        {get mem data}
               mov     ah,al
               mov     al,[si]
               shl     ax,cl                {shift it to adjust scr bit position}
               xor     ah,byte ptr cs:@XorByte
               xchg    es:[di],ah
               inc     di
               jmp     @LCont1

@LMiddle:
               mov     al,$FF
               out     dx,al
               push    es
               db 66h;rol ax,16
               mov  es,ax
               db 66h;rol ax,16
               xchg    dl,byte ptr es:@XorByte
               pop es
@LM_Loop:
               lodsb                        {get bitmap data}
               mov     ah,al
               mov     al,[si]
               shl     ax,cl                {shift it to adjust scr bit pos..}
               mov     al,ah                {store to AL}
               xor     al,dl
               xchg    es:[di],al
               inc     di
            {   stosb  }                      {store to video mem}
               dec     ch
               jnz     @LM_Loop
               push    es
               db 66h;rol ax,16
               mov  es,ax
               db 66h;rol ax,16
               xchg    dl,byte ptr es:@XorByte
               pop es
               jmp     @LCont2
@LEnd:
               mov     al,bl
               out     dx,al
               lodsb
               shl     al,cl
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               inc     di
               jmp     @LCont3
@LEnd1:
               mov     al,bl
               out     dx,al
               lodsb
               mov     ah,al
               mov     al,[si]
               shl     ax,cl
               xor     ah,byte ptr cs:@XorByte
               xchg    es:[di],ah
               inc     di
               inc     si
               jmp     @LCont3

@FastStart:
               mov     al,bh
               out     dx,al
               lodsb
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               inc     di
               jmp     @LCont1
@FastMiddle:
               mov     al,$FF
               out     dx,al
               push    es
               db 66h;rol ax,16
               mov es,ax
               db 66h;rol ax,16
               xchg    dl,byte ptr es:@XorByte
               pop es
@FM_Loop:
               lodsb
               xor     al,dl
               xchg    es:[di],al
               inc     di
             {  stosb }
               dec     ch
               jnz     @FM_Loop
               push    es
               db 66h;rol ax,16
               mov es,ax
               db 66h;rol ax,16
               xchg    dl,byte ptr es:@XorByte
               pop es
               jmp     @LCont2

@FastEnd:
               mov     al,bl
               out     dx,al
               lodsb
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               inc     di
               jmp     @LCont3

@RStart0:
               mov     al,bl
               out     dx,al
               xor     al,al
               mov     ah,[si]
               shr     ax,cl
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               dec     di
               jmp     @LCont1

@RStart:       mov     al,bl
               out     dx,al
               lodsb
               mov     ah,[si]
               shr     ax,cl
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               dec     di
               jmp     @LCont1

@RMiddle:
               mov     al,$FF
               out     dx,al
               push    es
               db 66h;rol ax,16
               mov es,ax
               db 66h;rol ax,16
               xchg    dl,byte ptr es:@XorByte
               pop es
@RM_Loop:
               lodsb
               mov     ah,[si]
               shr     ax,cl
               xor     al,dl
               xchg    es:[di],al
               dec     di
            {   stosb }
               dec     ch
               jnz     @RM_Loop
               push    es
               db 66h;rol ax,16
               mov es,ax
               db 66h;rol ax,16
               xchg    dl,byte ptr es:@XorByte
               pop es
               jmp     @LCont2

@REnd:         mov     al,bh
               out     dx,al
               lodsb
               shr     al,cl
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               dec     di
               jmp     @LCont3
{--------------------------------------------------------------------------}
@SetStart:     mov     al,bh
               out     dx,al
               mov     al,es:[di]
               mov     es:[di],ah
               inc     di
               jmp     @SCont1
@SetMiddle:    mov     al,$FF
               out     dx,al
               mov     al,ah
@SM_Loop:      stosb
               dec     ch
               jnz     @SM_Loop
               jmp     @SCont2
@SetEnd:       mov     al,bl
               out     dx,al
               mov     al,es:[di]
               mov     es:[di],ah
               inc     di
               jmp     @SCont3
@BSetStart:    mov     al,bl
               out     dx,al
               mov     al,es:[di]
               mov     es:[di],ah
               dec     di
               jmp     @SCont1
@BSetMiddle:   mov     al,$FF
               out     dx,al
               mov     al,ah
@BSM_Loop:     stosb
               dec     ch
               jnz     @BSM_Loop
               jmp     @SCont2
@BSetEnd:      mov     al,bh
               out     dx,al
               mov     al,es:[di]
               mov     es:[di],ah
               dec     di
               jmp     @SCont3
{--------------------------------------------------------------------------}
{      Mem: 00001111 ... 11111000
               dh          dl
       Scr: 00111111 ... 11100000
            11000000 ... 00011111
               bh          bl
       Out:  AH : Read Plane #
             AL : Write Plane Bit
}
@InitPorts:    push    dx
               push    ax
               mov     dx,$3CE
               mov     ax,$0005              {Set all Bitmask}
               out     dx,ax
               pop     ax
               pop     dx
               retn

@DonePorts:    mov     dx,$3C4
               mov     ax,$FF02
               out     dx,ax
               mov     dx,$3CE
               mov     ax,$0004
               out     dx,ax
               mov     ax,$FF08
               out     dx,ax
               mov     ax,$0003
               out     dx,ax
               retn

@SetForwardAdds:
               push    ax
               mov     ax,FAddSI
               mov     word ptr es:@AddSIVal[2],ax
               mov     word ptr es:@SAddSIVal[2],ax
               mov     ax,FAddDI
               mov     word ptr es:@AddDIVal[2],ax
               mov     word ptr es:@SAddDIVal[2],ax
               pop     ax
               retn
@SetBackwardAdds:
               push    ax
               mov     ax,BAddSI
               mov     word ptr es:@AddSIVal[2],ax
               mov     word ptr es:@SAddSIVal[2],ax
               mov     ax,BAddDI
               mov     word ptr es:@AddDIVal[2],ax
               mov     word ptr es:@SAddDIVal[2],ax
               add     si,MemXSize
               add     di,ScrXSize
               dec     di
               dec     si
               pop     ax
               retn

@SegTable:     DD 00,00,00,00
@BSizeX:       DB 00
@XorByte:      DB 00
@ForeColor:    DB 00
@BackColor:    DB 00
@Table:        DB 00,00,00, 00,00,00, 00,00,00, 00,00,00, $FF
               {  BitPlane,$00 or $FF,$00 for FC or BC; $01 for Set; $02 for OR put}
@Init:
               mov     si,Offset @Table
               mov     bl,FC
               mov     bh,BC
               cmp     OrPut,True
               jnz     @LookFF
               mov     al,bl
               or      al,al
               jz      @SetNotFC
               mov     es:[si],al
               mov     byte ptr es:[si+01],$00
               mov     byte ptr es:[si+02],$02
               add     si,+03
@SetNotFC:
               mov     al,bl
               not     al
               and     al,$0F
               mov     es:[si],al
               mov     byte ptr es:[si+01],$FF
               mov     byte ptr es:[si+02],$02
               add     si,+03
               jmp     @Continue
@LookFF:
               mov     ax,bx
               and     al,ah                         {find Set $FF Planes}
               and     al,$0F
               jz      @Look00
               mov     es:[si],al
               xor     al,al
               dec     al
               mov     es:[si+01],al
               mov     byte ptr es:[si+02],$01
               add     si,03

@Look00:
               mov     ax,bx
               or      al,ah
               not     al                            {find Set $00 Planes}
               and     al,$0F
               jz      @LookFC
               mov     es:[si],al
               xor     al,al
               mov     es:[si+01],al
               inc     al
               mov     es:[si+02],al
               add     si,03

@LookFC:       mov     ax,bx
               xor     al,ah
               and     al,bl                        {fing FC planes}
               and     al,$0F
               jz      @LookBC
               mov     es:[si],al
               xor     al,al
               mov     es:[si+01],al
               mov     es:[si+02],al
               add     si,03

@LookBC:       mov     ax,bx
               xor     al,ah
               and     al,bh                        {find BC planes}
               and     al,$0F
               jz      @Continue
               mov     es:[si],al
               xor     al,al
               dec     al
               mov     es:[si+01],al
               inc     al
               mov     es:[si+02],al
               add     si,03
@Continue:
               mov     byte ptr es:[si],$00
               cmp     si,offset @Table
               jz      @Exit
               push    es
               push    X
               push    Y
               push    XSize
               push    YSize             {After call AX:X, DI:Y, SI:Offset}
               mov     ax,ScreenX
               inc     ax
               push    ax
               call    _AdjustViewPort   {after call,bx:XSize, DX:YSize}
               pop     es
               jnb     @X0
               jmp     @Exit
@X0:
               push    si
               mov     si,ax
               call    _CalcScrAdr
               pop     si
               push    di
               push    ax
               mov     YSize,dx
               mov     ch,cl             {save mem start bit in CH}
               xor     ah,ah
               mov     al,cl
               add     ax,bx
               push    ax
               Call    _PixelToByte
               mov     MemXSize,ax
               mov     dh,al
@CalcBothAdds:
               pop     di                {get scr Start bit}
               pop     ax
               push    ax
               push    di
               xor     ah,ah
               add     ax,bx
               call    _PixelToByte
               mov     ScrXSize,ax
               mov     bx,BytesPerLine  {ssg was here}
               add     bx,ax
               mov     BAddDI,bx
               mov     bx,BytesPerLine
               sub     bx,ax
               mov     FAddDI,bx
               mov     ax,MemXSize
               mov     bx,BytesPerLine
               mov     BAddSI,bx
               add     BAddSI,ax
               sub     bx,ax
               mov     FAddSI,bx               {end of calcing Add DI&SI}
               pop     ax
               mov     bx,$FFFF
               and     al,$07
               mov     cl,al
               shr     bl,cl
               not     bl
               mov     cl,ch
               shr     bh,cl
               cmp     dh,1
               jnz     @X1
               or      bl,bl
               jz      @X1
               and     bh,bl
               xor     bl,bl
@X1:
               db 66h;rol ax,16
               mov es,ax
               db 66h;rol ax,16
               xor     ax,ax
               mov     word ptr es:@LCont0[1],ax
               mov     word ptr es:@LCont1[1],ax
               mov     word ptr es:@LCont2[1],ax
               mov     word ptr es:@SCont0[1],ax
               mov     word ptr es:@SCont1[1],ax
               mov     word ptr es:@SCont2[1],ax
               pop     ax                    {restore scr bit start}
               pop     di                    {restore Scr offset}
               sub     cl,al
               jz      @SetFast
               ja      @SetLeft
               jmp     @SetRight

@SetFast:
               cld
               cmp     bh,$FF
               jz      @SF1
               mov     ax,Offset @FastStart
               sub     ax,Offset @LCont1
               mov     word ptr es:@LCont0[1],ax {!!}
               call    @Set_SetStart
               or      dh,dh
               jz      @SF1
               dec     dh
@SF1:
               or      bl,bl
               jz      @SF2
               mov     ax,Offset @FastEnd
               sub     ax,Offset @LCont3
               mov     word ptr es:@LCont2[1],ax
               call    @Set_SetEnd
               or      dh,dh
               jz      @SF2
               dec     dh
@SF2:
               or      dh,dh
               jz      @SF3
               mov     ax,Offset @FastMiddle
               sub     ax,Offset @LCont2
               mov     word ptr es:@LCont1[1],ax
               call    @Set_SetMiddle
@SF3:
               mov     byte ptr es:@LYLoop[1],dh
               mov     byte ptr es:@SYLoop[1],dh
               call    @SetForwardAdds
               jmp     @SetOK

@SetLeft:      cld
               mov     dl,bl
               cmp     dh,2
               jae     @SL1
               shl     bx,cl
               cmp     dh,1
               jz      @SLSetStart
               mov     al,bh
               jmp     @SL2
@SL1:
               mov     al,$FF
               push    cx
@SLLoop1:      shl     bl,1
               rcl     al,1
               rcl     bh,1
               dec     cl
               jnz     @SLLoop1
               pop     cx
@SL2:          or      dl,dl
               jz      @SLSetLEnd1
               or      bl,bl
               jz      @SLSetLEnd1X
@SLSetLEnd:
               mov     ax,Offset @LEnd
               sub     ax,Offset @LCont3
               mov     word ptr es:@LCont2[1],ax
               call    @Set_SetEnd
               or      dh,dh
               jz      @SLSetStart
               dec     dh
               jmp     @SLSetStart
@SLSetLEnd1:
               or      bl,bl
               mov     bl,al
               jz      @SLSetLEnd
@SLSetLEnd1X:  mov     bl,al
               mov     ax,Offset @LEnd1
               sub     ax,Offset @LCont3
               mov     word ptr es:@LCont2[1],ax
               call    @Set_SetEnd
               or      dh,dh
               jz      @SLSetStart
               dec     dh
               or      dh,dh
               jz      @SLSetStart
               dec     dh
@SLSetStart:
               cmp     bh,$FF
               jz      @SLSetMiddle
               or      dh,dh
               jz      @SLEnd
               mov     ax,Offset @LStart
               sub     ax,Offset @LCont1
               mov     word ptr es:@LCont0[1],ax
               call    @Set_SetStart
               or      dh,dh
               jz      @SLSetMiddle
               dec     dh
@SLSetMiddle:
               or      dh,dh
               jz      @SLEnd
               mov     ax,Offset @LMiddle
               sub     ax,Offset @LCont2
               mov     word ptr es:@LCont1[1],ax
               call    @Set_SetMiddle
@SLENd:
               mov     byte ptr es:@LYLoop[1],dh
               mov     byte ptr es:@SYLoop[1],dh
               call    @SetForwardAdds
               jmp     @SetOK
                                           {    BL<>0 and DL<>0 LEnd       }
                                           {    BL=0 and DL<>0 LEnd1 BL=AL }
@SetRight:     std
               neg     cl
               mov     dl,bl
               xor     ch,ch
               push    cx
@SRL1:         shr     bx,1
               rcr     ch,1
               dec     cl
               jnz     @SRL1
               or      ch,ch
               jz      @SRX0
               mov     bl,ch
@SRX0:         pop     cx
               jnz     @SRX1
               or      bl,bl
               jz      @SR1
               or      dl,dl
               jz      @SRX1
               mov     ax,Offset @RStart
               sub     ax,Offset @LCont1
               mov     word ptr es:@LCont0[1],ax
               call    @Set_BSetStart
               or      dh,dh
               jz      @SR1
               dec     dh
               jmp     @SR1
@SRX1:
               mov     ax,Offset @RStart0
               sub     ax,Offset @LCont1
               mov     word ptr es:@LCont0[1],ax
               call    @Set_BSetStart
@SR1:
               cmp     bh,$FF
               jz      @SR2
               mov     ax,Offset @REnd
               sub     ax,Offset @LCont3
               mov     word ptr es:@LCont2[1],ax
               call    @Set_BSetEnd
               or      dh,dh
               jz      @SR2
               dec     dh
@SR2:
               or      dh,dh
               jz      @SR3
               mov     ax,Offset @RMiddle
               sub     ax,Offset @LCont2
               mov     word ptr es:@LCont1[1],ax
               call    @Set_BSetMiddle
@SR3:
               mov     byte ptr es:@LYLoop[1],dh
               mov     byte ptr es:@SYLoop[1],dh
               call    @SetbackwardAdds
{               jmp     @SetOK }
@SetOK:
               mov     word ptr es:@BitMask[1],bx
               mov     es,VideoSeg
               mov     bx,offset @Table
               push    ds
               add     si,word ptr ImageBuffer
               mov     ds,word ptr ImageBuffer[2]
               mov     bp,YSize
               call    @InitPorts
               call    @DumpIt
               pop     ds
               call    @DonePorts
@Exit:
               retn
@Set_SetStart: mov     ax,offset @SetStart
               sub     ax,offset @SCont1
               mov     word ptr es:@SCont0[1],ax
               retn
@Set_SetMiddle:mov     ax,offset @SetMiddle
               sub     ax,offset @SCont2
               mov     word ptr es:@SCont1[1],ax
               retn
@Set_SetEnd:   mov     ax,offset @SetEnd
               sub     ax,offset @SCont3
               mov     word ptr es:@SCont2[1],ax
               retn
@Set_BSetStart:mov     ax,offset @BSetStart
               sub     ax,offset @SCont1
               mov     word ptr es:@SCont0[1],ax
               retn
@Set_BSetMiddle:mov     ax,offset @BSetMiddle
               sub     ax,offset @SCont2
               mov     word ptr es:@SCont1[1],ax
               retn
@Set_BSetEnd:  mov     ax,offset @BSetEnd
               sub     ax,offset @SCont3
               mov     word ptr es:@SCont2[1],ax
               retn
@Esc:
    end;
{$ELSE}
procedure PutFnt(X,Y,XSize,YSize:Integer; FC,BC:Byte; Var ImageBuffer; OrPut:Boolean);assembler;
    Var
      FAddSI   : Word;
      FAddDI   : Word;
      BAddSI   : Word;
      BAddDI   : Word;
      MemXSize : Word;
      ScrXSize : Word;
    asm
               push    bp
               call    @Init
               pop     bp
               jmp     @Esc
{--------------------------------------}
@DumpIt:
               mov     ah,cs:[bx]
               inc     bx
               or      ah,ah
               jz      @LEndLoop
               mov     al,cs:[bx]
               inc     bx
               push    ax
               mov     dx,$3C4
               mov     al,$02
               out     dx,ax
               mov     dx,$3CE
               mov     al,$08
               out     dx,al
               inc     dx
               pop     ax
               mov     ah,al
               mov     al,cs:[bx]
               inc     bx
               mov     byte ptr cs:@XorByte,ah
               push    bx
               push    bp
               push    si
               push    di
@BitMask:      mov     bx,0000              {BitMask}
               cmp     al,$01
               jz      @SYLoop
               cmp     al,$02
               jnz     @LYLoop
               push    dx
               push    ax
               mov     dx,$3CE
               or      ah,ah
               mov     ax,$1003            {set data rotate reg for OR }
               jz      @MakeOr
               mov     ah,$08              {set data rotate reg for AND }
@MakeOr:       out     dx,ax
               mov     al,$08
               out     dx,al
               pop     ax
               pop     dx

@LYLoop:       mov     ch,00                {offset @LYLoop+1 byte} {X size value}
@LCont0:       jmp     @Exit
@LCont1:       jmp     @Exit
@LCont2:       jmp     @Exit
@LCont3:
@AddDIVal:     add     di,$FFFF             {offset + 2} {next line}
@AddSIVal:     add     si,$FFFF             {offset + 2} {next data line}
               dec     bp                   {dec Y counter}
               jnz     @LYLoop
               jmp     @LoopEsc

@SYLoop:       mov     ch,00
@SCont0:       jmp     @Exit
@SCont1:       jmp     @Exit
@SCont2:       jmp     @Exit
@SCont3:
@SAddDIVal:    add     di,$FFFF             {offset + 2} {next line}
@SAddSIVal:    add     si,$FFFF             {offset + 2} {next data line}
               dec     bp                   {dec Y counter}
               jnz     @SYLoop
@LoopEsc:
               pop     di
               pop     si
               pop     bp
               pop     bx
               jmp     @DumpIt
@LEndLoop:     retn
{Never write any code from here to @REnd}
{because of short jumps!}

@LStart:
               mov     al,bh               {set bit mask index}
               out     dx,al
               lodsb                        {get mem data}
               mov     ah,al
               mov     al,[si]
               shl     ax,cl                {shift it to adjust scr bit position}
               xor     ah,byte ptr cs:@XorByte
               xchg    es:[di],ah
               inc     di
               jmp     @LCont1

@LMiddle:
               mov     al,$FF
               out     dx,al
               xchg    dl,byte ptr cs:@XorByte
@LM_Loop:
               lodsb                        {get bitmap data}
               mov     ah,al
               mov     al,[si]
               shl     ax,cl                {shift it to adjust scr bit pos..}
               mov     al,ah                {store to AL}
               xor     al,dl
               xchg    es:[di],al
               inc     di
            {   stosb  }                      {store to video mem}
               dec     ch
               jnz     @LM_Loop
               xchg    dl,byte ptr cs:@XorByte
               jmp     @LCont2
@LEnd:
               mov     al,bl
               out     dx,al
               lodsb
               shl     al,cl
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               inc     di
               jmp     @LCont3
@LEnd1:
               mov     al,bl
               out     dx,al
               lodsb
               mov     ah,al
               mov     al,[si]
               shl     ax,cl
               xor     ah,byte ptr cs:@XorByte
               xchg    es:[di],ah
               inc     di
               inc     si
               jmp     @LCont3

@FastStart:
               mov     al,bh
               out     dx,al
               lodsb
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               inc     di
               jmp     @LCont1
@FastMiddle:
               mov     al,$FF
               out     dx,al
               xchg    dl,byte ptr cs:@XorByte
@FM_Loop:
               lodsb
               xor     al,dl
               xchg    es:[di],al
               inc     di
             {  stosb }
               dec     ch
               jnz     @FM_Loop
               xchg    dl,byte ptr cs:@XorByte
               jmp     @LCont2

@FastEnd:
               mov     al,bl
               out     dx,al
               lodsb
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               inc     di
               jmp     @LCont3

@RStart0:
               mov     al,bl
               out     dx,al
               xor     al,al
               mov     ah,[si]
               shr     ax,cl
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               dec     di
               jmp     @LCont1

@RStart:       mov     al,bl
               out     dx,al
               lodsb
               mov     ah,[si]
               shr     ax,cl
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               dec     di
               jmp     @LCont1

@RMiddle:
               mov     al,$FF
               out     dx,al
               xchg    dl,byte ptr cs:@XorByte
@RM_Loop:
               lodsb
               mov     ah,[si]
               shr     ax,cl
               xor     al,dl
               xchg    es:[di],al
               dec     di
            {   stosb }
               dec     ch
               jnz     @RM_Loop
               xchg    dl,byte ptr cs:@XorByte
               jmp     @LCont2

@REnd:         mov     al,bh
               out     dx,al
               lodsb
               shr     al,cl
               xor     al,byte ptr cs:@XorByte
               xchg    es:[di],al
               dec     di
               jmp     @LCont3
{--------------------------------------------------------------------------}
@SetStart:     mov     al,bh
               out     dx,al
               mov     al,es:[di]
               mov     es:[di],ah
               inc     di
               jmp     @SCont1
@SetMiddle:    mov     al,$FF
               out     dx,al
               mov     al,ah
@SM_Loop:      stosb
               dec     ch
               jnz     @SM_Loop
               jmp     @SCont2
@SetEnd:       mov     al,bl
               out     dx,al
               mov     al,es:[di]
               mov     es:[di],ah
               inc     di
               jmp     @SCont3
@BSetStart:    mov     al,bl
               out     dx,al
               mov     al,es:[di]
               mov     es:[di],ah
               dec     di
               jmp     @SCont1
@BSetMiddle:   mov     al,$FF
               out     dx,al
               mov     al,ah
@BSM_Loop:     stosb
               dec     ch
               jnz     @BSM_Loop
               jmp     @SCont2
@BSetEnd:      mov     al,bh
               out     dx,al
               mov     al,es:[di]
               mov     es:[di],ah
               dec     di
               jmp     @SCont3
{--------------------------------------------------------------------------}
{      Mem: 00001111 ... 11111000
               dh          dl
       Scr: 00111111 ... 11100000
            11000000 ... 00011111
               bh          bl
       Out:  AH : Read Plane #
             AL : Write Plane Bit
}
@InitPorts:    push    dx
               push    ax
               mov     dx,$3CE
               mov     ax,$0005              {Set all Bitmask}
               out     dx,ax
               pop     ax
               pop     dx
               retn

@DonePorts:    mov     dx,$3C4
               mov     ax,$FF02
               out     dx,ax
               mov     dx,$3CE
               mov     ax,$0004
               out     dx,ax
               mov     ax,$FF08
               out     dx,ax
               mov     ax,$0003
               out     dx,ax
               retn

@SetForwardAdds:
               push    ax
               mov     ax,FAddSI
               mov     word ptr cs:@AddSIVal[2],ax
               mov     word ptr cs:@SAddSIVal[2],ax
               mov     ax,FAddDI
               mov     word ptr cs:@AddDIVal[2],ax
               mov     word ptr cs:@SAddDIVal[2],ax
               pop     ax
               retn
@SetBackwardAdds:
               push    ax
               mov     ax,BAddSI
               mov     word ptr cs:@AddSIVal[2],ax
               mov     word ptr cs:@SAddSIVal[2],ax
               mov     ax,BAddDI
               mov     word ptr cs:@AddDIVal[2],ax
               mov     word ptr cs:@SAddDIVal[2],ax
               add     si,MemXSize
               add     di,ScrXSize
               dec     di
               dec     si
               pop     ax
               retn

@SegTable:     DD 00,00,00,00
@BSizeX:       DB 00
@XorByte:      DB 00
@ForeColor:    DB 00
@BackColor:    DB 00
@Table:        DB 00,00,00, 00,00,00, 00,00,00, 00,00,00, $FF
               {  BitPlane,$00 or $FF,$00 for FC or BC; $01 for Set; $02 for OR put}
@Init:
               mov     si,Offset @Table
               mov     bl,FC
               mov     bh,BC
               cmp     OrPut,True
               jnz     @LookFF
               mov     al,bl
               or      al,al
               jz      @SetNotFC
               mov     cs:[si],al
               mov     byte ptr cs:[si+01],$00
               mov     byte ptr cs:[si+02],$02
               add     si,+03
@SetNotFC:
               mov     al,bl
               not     al
               and     al,$0F
               mov     cs:[si],al
               mov     byte ptr cs:[si+01],$FF
               mov     byte ptr cs:[si+02],$02
               add     si,+03
               jmp     @Continue
@LookFF:
               mov     ax,bx
               and     al,ah                         {find Set $FF Planes}
               and     al,$0F
               jz      @Look00
               mov     cs:[si],al
               xor     al,al
               dec     al
               mov     cs:[si+01],al
               mov     byte ptr cs:[si+02],$01
               add     si,03

@Look00:       mov     ax,bx
               or      al,ah
               not     al                            {find Set $00 Planes}
               and     al,$0F
               jz      @LookFC
               mov     cs:[si],al
               xor     al,al
               mov     cs:[si+01],al
               inc     al
               mov     cs:[si+02],al
               add     si,03

@LookFC:       mov     ax,bx
               xor     al,ah
               and     al,bl                        {fing FC planes}
               and     al,$0F
               jz      @LookBC
               mov     cs:[si],al
               xor     al,al
               mov     cs:[si+01],al
               mov     cs:[si+02],al
               add     si,03

@LookBC:       mov     ax,bx
               xor     al,ah
               and     al,bh                        {find BC planes}
               and     al,$0F
               jz      @Continue
               mov     cs:[si],al
               xor     al,al
               dec     al
               mov     cs:[si+01],al
               inc     al
               mov     cs:[si+02],al
               add     si,03
@Continue:
               mov     byte ptr cs:[si],$00
               cmp     si,offset @Table
               jz      @Exit
               push    X
               push    Y
               push    XSize
               push    YSize             {After call AX:X, DI:Y, SI:Offset}
               mov     ax,ScreenX
               inc     ax
               push    ax
               call    _AdjustViewPort   {after call,bx:XSize, DX:YSize}
               jnb     @X0
               jmp     @Exit
@X0:
               push    si
               mov     si,ax
               call    _CalcScrAdr
               pop     si
               push    di
               push    ax
               mov     YSize,dx
               mov     ch,cl             {save mem start bit in CH}
               xor     ah,ah
               mov     al,cl
               add     ax,bx
               push    ax
               Call    _PixelToByte
               mov     MemXSize,ax
               mov     dh,al
@CalcBothAdds:
               pop     di                {get scr Start bit}
               pop     ax
               push    ax
               push    di
               xor     ah,ah
               add     ax,bx
               call    _PixelToByte
               mov     ScrXSize,ax
               mov     bx,BytesPerLine  {ssg was here}
               add     bx,ax
               mov     BAddDI,bx
               mov     bx,BytesPerLine
               sub     bx,ax
               mov     FAddDI,bx
               mov     ax,MemXSize
               mov     bx,BytesPerLine
               mov     BAddSI,bx
               add     BAddSI,ax
               sub     bx,ax
               mov     FAddSI,bx               {end of calcing Add DI&SI}
               pop     ax
               mov     bx,$FFFF
               and     al,$07
               mov     cl,al
               shr     bl,cl
               not     bl
               mov     cl,ch
               shr     bh,cl
               cmp     dh,1
               jnz     @X1
               or      bl,bl
               jz      @X1
               and     bh,bl
               xor     bl,bl
@X1:
               xor     ax,ax
               mov     word ptr cs:@LCont0[1],ax
               mov     word ptr cs:@LCont1[1],ax
               mov     word ptr cs:@LCont2[1],ax
               mov     word ptr cs:@SCont0[1],ax
               mov     word ptr cs:@SCont1[1],ax
               mov     word ptr cs:@SCont2[1],ax
               pop     ax                    {restore scr bit start}
               pop     di                    {restore Scr offset}
               sub     cl,al
               jz      @SetFast
               ja      @SetLeft
               jmp     @SetRight

@SetFast:      cld
               cmp     bh,$FF
               jz      @SF1
               mov     ax,Offset @FastStart
               sub     ax,Offset @LCont1
               mov     word ptr cs:@LCont0[1],ax
               call    @Set_SetStart
               or      dh,dh
               jz      @SF1
               dec     dh
@SF1:
               or      bl,bl
               jz      @SF2
               mov     ax,Offset @FastEnd
               sub     ax,Offset @LCont3
               mov     word ptr cs:@LCont2[1],ax
               call    @Set_SetEnd
               or      dh,dh
               jz      @SF2
               dec     dh
@SF2:
               or      dh,dh
               jz      @SF3
               mov     ax,Offset @FastMiddle
               sub     ax,Offset @LCont2
               mov     word ptr cs:@LCont1[1],ax
               call    @Set_SetMiddle
@SF3:
               mov     byte ptr cs:@LYLoop[1],dh
               mov     byte ptr cs:@SYLoop[1],dh
               call    @SetForwardAdds
               jmp     @SetOK

@SetLeft:      cld
               mov     dl,bl
               cmp     dh,2
               jae     @SL1
               shl     bx,cl
               cmp     dh,1
               jz      @SLSetStart
               mov     al,bh
               jmp     @SL2
@SL1:
               mov     al,$FF
               push    cx
@SLLoop1:      shl     bl,1
               rcl     al,1
               rcl     bh,1
               dec     cl
               jnz     @SLLoop1
               pop     cx
@SL2:          or      dl,dl
               jz      @SLSetLEnd1
               or      bl,bl
               jz      @SLSetLEnd1X
@SLSetLEnd:
               mov     ax,Offset @LEnd
               sub     ax,Offset @LCont3
               mov     word ptr cs:@LCont2[1],ax
               call    @Set_SetEnd
               or      dh,dh
               jz      @SLSetStart
               dec     dh
               jmp     @SLSetStart
@SLSetLEnd1:
               or      bl,bl
               mov     bl,al
               jz      @SLSetLEnd
@SLSetLEnd1X:  mov     bl,al
               mov     ax,Offset @LEnd1
               sub     ax,Offset @LCont3
               mov     word ptr cs:@LCont2[1],ax
               call    @Set_SetEnd
               or      dh,dh
               jz      @SLSetStart
               dec     dh
               or      dh,dh
               jz      @SLSetStart
               dec     dh
@SLSetStart:
               cmp     bh,$FF
               jz      @SLSetMiddle
               or      dh,dh
               jz      @SLEnd
               mov     ax,Offset @LStart
               sub     ax,Offset @LCont1
               mov     word ptr cs:@LCont0[1],ax
               call    @Set_SetStart
               or      dh,dh
               jz      @SLSetMiddle
               dec     dh
@SLSetMiddle:
               or      dh,dh
               jz      @SLEnd
               mov     ax,Offset @LMiddle
               sub     ax,Offset @LCont2
               mov     word ptr cs:@LCont1[1],ax
               call    @Set_SetMiddle
@SLENd:
               mov     byte ptr cs:@LYLoop[1],dh
               mov     byte ptr cs:@SYLoop[1],dh
               call    @SetForwardAdds
               jmp     @SetOK
                                           {    BL<>0 and DL<>0 LEnd       }
                                           {    BL=0 and DL<>0 LEnd1 BL=AL }
@SetRight:     std
               neg     cl
               mov     dl,bl
               xor     ch,ch
               push    cx
@SRL1:         shr     bx,1
               rcr     ch,1
               dec     cl
               jnz     @SRL1
               or      ch,ch
               jz      @SRX0
               mov     bl,ch
@SRX0:         pop     cx
               jnz     @SRX1
               or      bl,bl
               jz      @SR1
               or      dl,dl
               jz      @SRX1
               mov     ax,Offset @RStart
               sub     ax,Offset @LCont1
               mov     word ptr cs:@LCont0[1],ax
               call    @Set_BSetStart
               or      dh,dh
               jz      @SR1
               dec     dh
               jmp     @SR1
@SRX1:
               mov     ax,Offset @RStart0
               sub     ax,Offset @LCont1
               mov     word ptr cs:@LCont0[1],ax
               call    @Set_BSetStart
@SR1:
               cmp     bh,$FF
               jz      @SR2
               mov     ax,Offset @REnd
               sub     ax,Offset @LCont3
               mov     word ptr cs:@LCont2[1],ax
               call    @Set_BSetEnd
               or      dh,dh
               jz      @SR2
               dec     dh
@SR2:
               or      dh,dh
               jz      @SR3
               mov     ax,Offset @RMiddle
               sub     ax,Offset @LCont2
               mov     word ptr cs:@LCont1[1],ax
               call    @Set_BSetMiddle
@SR3:
               mov     byte ptr cs:@LYLoop[1],dh
               mov     byte ptr cs:@SYLoop[1],dh
               call    @SetbackwardAdds
{               jmp     @SetOK }
@SetOK:
               mov     es,VideoSeg
               mov     word ptr cs:@BitMask[1],bx
               mov     bx,offset @Table
               push    ds
               add     si,word ptr ImageBuffer
               mov     ds,word ptr ImageBuffer[2]
               mov     bp,YSize
               call    @InitPorts
               call    @DumpIt
               pop     ds
               call    @DonePorts
@Exit:
               retn
@Set_SetStart: mov     ax,offset @SetStart
               sub     ax,offset @SCont1
               mov     word ptr cs:@SCont0[1],ax
               retn
@Set_SetMiddle:mov     ax,offset @SetMiddle
               sub     ax,offset @SCont2
               mov     word ptr cs:@SCont1[1],ax
               retn
@Set_SetEnd:   mov     ax,offset @SetEnd
               sub     ax,offset @SCont3
               mov     word ptr cs:@SCont2[1],ax
               retn
@Set_BSetStart:mov     ax,offset @BSetStart
               sub     ax,offset @SCont1
               mov     word ptr cs:@SCont0[1],ax
               retn
@Set_BSetMiddle:mov     ax,offset @BSetMiddle
               sub     ax,offset @SCont2
               mov     word ptr cs:@SCont1[1],ax
               retn
@Set_BSetEnd:  mov     ax,offset @BSetEnd
               sub     ax,offset @SCont3
               mov     word ptr cs:@SCont2[1],ax
               retn
@Esc:
    end;

{$ENDIF}

procedure PutVIF(x,y:integer; var BitMap);
begin
  case TVifMap(BitMap).Version of
    1 : PutVIF1(x,y,TVIFMap(BitMap));
    2 : PutVIF2(x,y,BitMap);
  end; {case}
end;

function GetVIFSize(P:PVIFMap):word;
Var
  N : Word;
begin
  GetVIFSize := 0;
  if P = NIL then exit;
  Case P^.Version of
    01 : GetVifSize := P^.XSize * P^.YSize + 5;
    02 : begin
           N := Pixel2Byte(P^.XSize)*P^.YSize;
           N := 4*(N+SizeOf(Pointer));
           GetVifSize := N + 5;
         end;
  end;
end;

procedure DisposeVIF(var P:PVIFMap);
var
  planesize:word;
  n:byte;
begin
  if P = NIL then exit;
  case P^.Version of
   2: begin
        planesize := ((P^.XSize div 8)+Byte((P^.XSize mod 8)>0)) * P^.YSize;
        for n := 0 to 3 do FreeMem(P^.Planes[n],PlaneSize);
        dispose(P);
      end;
   1: FreeMem(P,P^.xsize*P^.ysize+5);
   else Dispose(P);
  end; {case}
end;
{---------------------------------------------------------------------------}
{->                    W R I T E  R O U T I N E S                         <-}
{---------------------------------------------------------------------------}
function Pixel2Byte(N:Word):Byte; assembler;
asm
  mov     ax,N
  test    al,07
  jz      @1
  add     ax,+08
@1:
  shr     ax,1
  shr     ax,1
  shr     ax,1
end;

function PrepWrite(var s:string; P:PFont):integer;
var
  SY : Integer;
begin
  case P^.FontType of
    ftBitMapped : SY := P^.ChrY;
    ftProportional : SY := P^.ChrY1;
    else SY := 0;
  end;
  MakeFontImage(S,P);
  PrepWrite := SY;
end;

procedure WriteStr(X,Y,XSize:Integer; S:String; P:PFont);
begin
  PutFnt(X,Y,XSize,PrepWrite(S,P),TxtForeGround,TxtBackGround,FontLineBuf^,False);
end;

procedure WriteOredStr(X,Y,XSize:Integer; S:String; P:PFont);
begin
  PutFnt(X,Y,XSize,PrepWrite(S,P),TxtForeGround,TxtBackGround,FontLineBuf^,True);
end;

procedure SetTextColor(ForeGround,BackGround:Word);
    begin
      TxtForeGround := ForeGround;
      TxtBackGround := BackGround;
    end;

{---------------------------------------------------------------------------}
{->                      F O N T  R O U T I N E S                         <-}
{---------------------------------------------------------------------------}

const

  FontCache : PFont = NIL;
  FontCacheId : word = 0;

function GetFontPtr(FontId:Word):PFont;
var
  P:PFont;
begin
  P := NIL;
  if fontcache <> NIL then if fontid = fontcacheid then begin
    GetFontPtr := FontCache;
    exit;
  end;
  if AXEOK then P := GetRscById(rtFont,FontID);
  if P = NIL then begin
    if BiosFontPtr = NIL then LoadBIOSFont;
    P := BiosFontPtr;
    FontId := 0;
  end;
  if P = NIL then Error('GetFontPtr','Couldn''t get font '+l2s(FontId));
  if FontId > 0 then begin
    FontCache := P;
    FontCacheId := FontId;
  end;
  GetFontPtr := P;
end;

function GetStringSize(FontId:Word; S:String):word;
var
  P:PFont;
begin
  P := GetFontPtr(FontId);
  if (P <> NIL) and (s <> '') then GetStringSize := GetFontX(P,S)
                              else GetStringSize := 0;
end;

procedure BIOSFntProc;external;
{$L BIOSFNT.OBJ}

procedure LoadBIOSFont;
var
  P  : Pointer;
  FP : PFont;
  I  : byte;
  AddSize : Word;
begin
  P := @BIOSFntProc;
  GetMem(FP,256*8+6);
  FP^.FontType  := FtBitMapped;
  FP^.ChrX      := 08;
  FP^.ChrY      := 08;
  Move(P^,FP^.Data1,256*8);
  AddSize := Pixel2Byte(FP^.ChrX)*FP^.ChrY;

  For I:=0 to 11 do begin
    P := @FP^.Data1;
    inc(word(P),TurkishChars[I][0]*AddSize);
    Move(TurkishChars[I][1],P^,AddSize);
  end;

  BiosFontPtr   := FP;
end;

function GetFontHeight(FontId:Word):word;
    Var
      P : PFont;
    begin
     P := GetFontPtr(FontId);
     if P <> NIL then GetFontHeight := GetFontY(P)
                 else GetFontHeight := 0;
    end;

function GetFontX; assembler;
    asm
               push    ds
               les     di,FontPtr
               mov     ax,es
               or      ax,di
               jz      @Esc
               cld
               lds     si,S
               lodsb
               xor     ah,ah
               or      al,al
               jz      @Esc
               mov     cx,ax
               mov     dl,es:[di].TFont.FontType
               cmp     dl,FtBitMapped
               jnz     @IsProp
               mov     al,es:[di].TFont.ChrX
               mul     cl
               jmp     @Esc
@IsProp:
               cmp     dl,FtProportional
               jnz     @Other
               lea     di,[di].TFont.TblChrX
               xor     ax,ax
               mov     bx,ax
@PropLoop:     mov     bl,[si]
               inc     si
               add     al,es:[di+bx]
               adc     ah,0
               loop    @PropLoop
               jmp     @Esc

@Other:        xor     ax,ax
@Esc:          pop     ds
    end;

function GetFontY(FontPtr:PFont):word;
    begin
      if FontPtr<>Nil then
          case FontPtr^.FontType of
             FtBitMapped    : GetFontY := FOntPtr^.ChrY;
             FtProportional : GetFontY := FontPtr^.ChrY1;
          else
             GetFontY := 1;
          end
      else GetFontY := 1;
    end;
{---------------------------------------------------------------------------}
{->                     PALETTE REGISTER ROUTINES                         <-}
{---------------------------------------------------------------------------}
procedure SetRGB(Color,Red,Green,Blue:Byte); assembler;
    asm
               mov     dx,$3C8
               mov     al,Color
               out     dx,al
               inc     dx
               mov     al,Red
               out     dx,al
               mov     al,Green
               out     dx,al
               mov     al,Blue
               out     dx,al
    end;

procedure SetTrueRGB(Color,Red,Green,Blue:Byte);
begin
  SetRGB(PalXlat[Color],Red,Green,Blue);
end;

procedure _SetPalette(var Pal:TRGBPalette); assembler;
    asm
               cld
               mov     dx,$3C8
               mov     cx,256*3
               push    ds
               lds     si,Pal
               xor     al,al
               out     dx,al
               inc     dx
               repz    outsb
               pop     ds
    end;

procedure GetQuadPalette(var P:TQuadPalette);
var
  b:byte;
  temp:byte;
begin
  asm
    cld
    mov dx,3c7h
    mov cx,100h
    les di,P
    xor al,al
    out dx,al
    inc dx
    inc dx
  @Loop:
    insb
    insb
    insb
    stosb
    loop @Loop
  end;
  for b:=0 to 255 do with P[b] do begin
    temp := R shl 2;
    R := B shl 2;
    G := G shl 2;
    B := temp;
  end;
end;

procedure GetPalette(Var P:TRGBPalette); assembler;
asm
               cld
               mov     dx,$3C7
               mov     cx,256*3
               les     di,P
               xor     al,al
               out     dx,al
               inc     dl
               inc     dl
               repz    insb
end;

procedure SetPalette(Var Pal:TRGBPalette);
    var
      CP    : TRGBPalette;
      b     : boolean;
    begin
      if SmoothPalSet then begin
         GetPalette(CP);
         b := false;
         repeat
           if b then asm
             mov  dx,3dah
           @1:
             in   al,dx
             test al,8
             jne   @1
           @2:
             in   al,dx
             test al,8
             je  @2

             xor al,al
             mov b,al
           end else b := true;
           asm
             les  di,Pal
             push ds
             mov  ax,ss
             mov  ds,ax
             lea  si,cp
             mov  cx,768
           @loop:
             mov  al,byte ptr [si]
             cmp  al,es:[di]
             je   @continue
             ja   @dec
             inc  byte ptr [si]
             jmp  @continue
           @dec:
             dec  byte ptr [si]
           @continue:
             inc  di
             inc  si
             loop @loop
             pop  ds
           end;
           _SetPalette(CP);

         until BufCmp(CP,Pal,768);
      end else _SetPalette(Pal);
    end;
procedure GetRGB(Color:Byte;var T:TRGB);assembler;
asm
  cld
  mov  al,Color
  mov  dx,$3c7
  out  dx,al
  inc  dx
  inc  dx
  mov  cx,3
  les  di,T
  rep  insb
end;

procedure _SetTruePalette(var P:TRGBPalette);assembler;
asm
  cld
  mov  ax,ds
  mov  es,ax
  push ds
  lds  si,P
  xor  bx,bx
  mov  dx,$3c8
@Loop:
  mov  al,byte ptr es:PalXLat[bx]
  out  dx,al
  inc  dl
  outsb
  outsb
  outsb
  inc  bl
  dec  dl
  cmp  bl,16
  jne  @Loop
  pop  ds
end;

procedure GetTruePalette(Var P:TRGBPalette); assembler;
asm
  cld
  les     di,P
  mov     dx,$3C8
  xor     bx,bx
  mov     cx,16
@Loop:
  mov     al,byte ptr PalXLat[bx]
  out     dx,al
  inc     dx
  insb
  insb
  insb
  dec     dx
  inc     bx
  loop    @Loop
end;

procedure SetTruePalette(Var P:TRGBPalette);
var
 CP : TRGBPalette;
  I,N   : Word;
  P1,P2 : ^Byte;
  F     : Boolean;
begin
  if SmoothPalSet then begin
     GetTruePalette(CP);
     repeat
       N := 0;
       P1 := @CP[0].R;  P2 := @P[0].R;
       For I:=0 to 256*3-1 do begin
           if  P1^ > P2^ then dec(P1^)
           else if P1^ < P2^ then inc(P1^)
           else inc(N);
           inc(Word(P1));
           inc(Word(P2));
       end;
       _SetTruePalette(CP);
     until N > I;
  end else _SetTruePalette(P);
end;

procedure RGB2Quad(var src,dst; numcolors:byte);assembler;
asm
  cld
  push  ds
  xor   ch,ch
  mov   cl,numcolors
  les   di,dst
  lds   si,src
@Loop:
  lodsw
  stosw
  lodsb
  xor   ah,ah
  stosw
  loop  @Loop
  pop   ds
end;

procedure Quad2RGB;assembler;
asm
  cld
  push  ds
  mov   cx,numcolors
  les   di,dst
  lds   si,src
@Loop:
  lodsw
  stosw
  lodsb
  stosb
  inc   si
  loop  @Loop
  pop   ds
end;

procedure NullPalette;
var
  P:TRGBPalette;
begin
  ClearBuf(P,SizeOf(P));
  SetPalette(P);
end;

procedure SetStartupPalette;
begin
  SetTruePalette(PRGBPalette(@StartupPalette)^);
end;

procedure InitFonts;
begin
  New(FontLineBuf);
  ViewFontHeight := GetFontHeight(ViewFont);
  ViewFontWidth  := GetStringSize(ViewFont,'A');
end;

procedure Sync;assembler;
asm
  mov  dx,3dah
@1:
  in    al,dx
  test  al,8
  jne   @1
@2:
  in    al,dx
  test  al,8
  je    @2
end;

procedure Cycle;
  procedure setrgb(c,r,g,b:byte);assembler;
  asm
    mov  dx,3c8h
    mov  al,c
    out  dx,al
    inc  dx
    mov  al,r
    out  dx,al
    mov  al,g
    out  dx,al
    mov  al,b
    out  dx,al
  end;
begin
  if GetSystem(Sys_CycleEffect) then begin
    setrgb(0,0,63,0);
    setrgb(0,0,0,0);
  end;
end;

end.
*** End Of File ***
