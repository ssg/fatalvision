{
Name            : X/Types 1.15b
Purpose         : All constants and types of XVision.
Date            : 09th Sep 1993
Arrangement     : SSG & FatalicA
}

unit XTypes;

interface

uses

  Objects; {TEvent,TRect}

var

  XTimer : ^longint;
  XCurrentMode,XShiftState : ^word;

type

  {------------------------- Generic Types -------------------------}
  PSinCosTable = ^TSinCosTable;
  TSinCosTable = Array[0..359] of Real;

  TEXEHeader = Record
    Id           : Word;
    LastPageSize : Word;
    FileSize     : Word; { in 512 byte pages }
    RelCount     : word;
    HdrSize      : Word; { in 16 byte paragraphs}
    MinMem       : word; { in 16 byte paragraphs}
    MaxMem       : Word; { in 16 byte paragraphs}
    SSInit       : Word;
    SPInit       : Word;
    NegSum       : Word;
    IPInit       : Word;
    CSInit       : Word;
    RelOfs       : Word;
    OverlayCount : Word;
    Unused1      : word;
    Unused2      : word;
  end;

  TID = array[0..3] of char;
  TFileName = array[0..11] of char;

  TFName = string[12];

  TNullRecord = Record end;

  PXByteArray = ^TXByteArray;
  TXByteArray = array[0..65500] of byte;

  {----------------------- Extended Event Types ---------------------}

  PXEvent = ^Xevent;
  XEvent  = record
    What: Word;
    case Word of
      0: ();
      1: (
        Buttons: Byte;
        Double: Boolean;
        Where: TPoint);
      2: (
        case Integer of
          0: (KeyCode: Word);
          1: (CharCode: Char; ScanCode: Byte));
      3: (
        Command: Word;
        case Word of
          0: (InfoPtr: Pointer);
          1: (InfoLong: Longint);
          2: (InfoWord: Word);
          3: (InfoInt: Integer);
          4: (InfoByte: Byte);
          5: (InfoChar: Char);
          6: (
            Null: Pointer;
            Case Byte of
               0 : (Source:Pointer)));
  end;

  {------------------------ Types Used by Tools ---------------------}

  PDate = ^TDate;         {Appointment date format}
  TDate = record
    Year      : Word;
    Month     : Byte;
    Day       : Byte;
  end;

  PTime = ^TTime;
  TTime = record
    Minute    : Byte;
    Hour      : Byte;
  end;

  PFileStack = ^TFileStack; {MultiFileCopier Linked List}
  TFileStack = record
    Name     : String[13];
    Next     : PFileStack;
  end;

  PMText = ^TMText;                     {RadioButton Linked List}
  TMText = Record
   Text   : PString;
   Next   : PMText;
   State  : Byte;
  End;

  {--------------------------- Sound Types --------------------------}

  PSound = ^TSound;   {Sound format}
  TSound = record
    Size   : Word;
    KHz    : Word;
    Flags  : Word;
    Sample : record end;
  end;

  PSFXHeader = ^TSFXHeader;
  TSFXHeader = record
    Id       : TId;
    Version  : word;
    KHz      : word;
    Flags    : word;
    Size     : word;
  end;

  PVOCHeader = ^TVOCHeader;
  TVOCHeader = record
    Sign      : array[1..20] of char;
    DataOffs  : word;
    Version   : word;
    CRC       : word;
    BlockType : byte;
    BlockLen  : word;
    Temp      : byte;
    PackedKHZ : byte;
    Pack      : byte;
    Data      : record end;
  end;

  PWaveHeader = ^TWaveHeader;
  TWaveHeader = record
    RIFFid    : Tid;  {RIFF header}
    RIFFsize  : longint;              {RIFF block size}
    WAVEid    : Tid;  {WAVE header}
    FMTid     : array[1..3] of char;  {WAVE format block header}
    FMTsize   : longint;
    Unknown1  : word;
    Unknown2  : word;
    UnknownB  : byte;
    Freq1     : longint;              {Left frequency}
    Freq2     : longint;              {Right frequency}
    Unknown3  : word;
    Unknown4  : word;
    DATAid    : Tid;  {DATA block header}
    DATAsize  : longint;
  end;

  {--------------------------- Bitmap Types -----------------------}

  PVifMap = ^TVifMap;      {Enhanced VIF format}
  TVifMap = Record
    XSize   : Word;
    YSize   : Word;
    Version : Byte;
   case Byte of
      1 : (Data  : record end;);    {Version 1.0 Raster VIFs}
      2 : (Case Byte of       {Version 2.0 Planed VIFs}
            0 : (Plane0 : Pointer;
                 Plane1 : Pointer;
                 Plane2 : Pointer;
                 Plane3 : Pointer;);
            1 :  (Planes : Array[0..3] of Pointer;););
  end;

  PVIFHeader=^TVIFHeader;   {VIF File header}
  TVIFHeader=record
     ID            : array[0..2] of char;
     Version       : array[0..2] of char;
     EOFFlag       : byte;
     HardFlag      : word;
  end;

  TPCXHeader = record
    Sign         : byte;   {10}
    Version      : byte;   {5}
    Encoding     : byte;   {1 = PCX RLE}
    BitsPerPixel : byte;   {8 = 256 color}
    Xmin         : word;
    Ymin         : word;
    Xmax         : word;
    Ymax         : word;  {image dimensions}
    HDPI         : word;
    VDPI         : word; {horiz/vert dpi}
    Colormap     : array[1..48] of byte;
    Reserved     : byte; {0}
    NumPlanes    : byte;
    BytesPerLine : word; { 320 for 320x200 }
    PaletteInfo  : word; { 1 }
    HSize        : word;
    VSize        : word; {screen sizes}
    Filler       : array[1..54] of byte;
  end;

  PBmpCore = ^TBmpCore;
  TBmpCore = record
            BMId : Word;    {must be BM}
           FSize : Longint; {File size in bytes}
        Unknown1 : Longint; {Reserved}
       DataStart : Longint; {Start offset of data}
        HdrSize  : Longint; {Header size must be 12 for core, 36 for enh}
           SizeX : Longint; {sizes}
           SizeY : Longint;
          Planes : Word;    {number of planes for bitmap}
        BitCount : Word;    {bits per pixel - end of core header}
  end;

  PBMPSimple = ^TBMPSimple; {if hdrsize = 12 this record is used}
  TBMPSimple = record
    BMId      : word;
    FSize     : longint;
    Unknown1  : longint;
    DataStart : longint;
    HdrSize   : longint;
    SizeX     : word;
    SizeY     : word;
    Planes    : word;
    BitCount  : word;
  end;

  PBmpExtra = ^TBmpExtra;
  TBmpExtra = record
     Compression : Longint; {compression method, 0:Not compressed}
       ImageSize : Longint; {Size of Image}
   XPelsPerMeter : Longint; {X resolution}
   YPelsPerMeter : Longint; {Y resolution}
       ColorUsed : Longint; {Number of Color Table, 0:Max}
  ColorImportant : Longint; {Number of important colors,0:All}
  end;


  {--------------------------- Font Types -------------------------}
  TCIFHeader = record
    ID       : array[0..6] of char;
    Version  : word;
  end;

  PFont = ^TFont;
  TFont = Record
    FontType : Byte; {0=bitmap,1=prop}
    Case Byte of
  {BitMapped Fonts}
      00 : (ChrX : Byte;
            ChrY : Byte;
            Data1     : Byte;);
  {Proportional Fonts}
      01 : (ChrY1     : Byte;                   {Y-Size of a char}
            TblChrX   : Array[0..255] of Byte;  {X-Size table}
            TblChrOfs : Array[0..255] of Word;  {Character offset table}
            Size      : Word;
            Data2     : Byte;);
  end;

  {----------------------------- Palette Types ------------------------}

  TRGB = object           {RGB structure}
    R : byte;
    G : byte;
    B : byte;
  end;

  TRGBQuad = object(TRGB)       {Windows RGB Structure}
    X : Byte;
  end;

  PRGBArray = ^TRGBArray;
  TRGBArray = array[0..15] of TRGB;

  PRGBPalette = ^TRGBPalette;
  TRGBPalette = array[0..255] of TRGB;

  PQuadPalette = ^TQuadPalette;
  TQuadPalette = array[0..255] of TRGBQuad;

  {-------------------------- Mouse Types ---------------------------}
  PMouseBitMap = ^TMouseBitMap;
  TMouseBitMap =  Array[0..1,0..15] of Word;   {Mouse bitmap}

  PMIFHeader = ^TMIFHeader;
  TMIFHeader = record
    Id       : TID;
    Version  : word;
    case Word of
      1 : (HX       : byte;
           HY       : byte;);
  end;

  PMIF = ^TMIF;
  TMIF = record
    HX     : byte;
    HY     : byte;
    BitMap : TMouseBitMap;
  end;

const

  AllFiles = $27;

  {---------------- Enhanced Keyboard Codes ----------------}
  kbAltEsc       = $0100;
  kbCtrlEsc      = $011B;
  kbF11          = $8500;
  kbF12          = $8600;
  kbAltTab       = $A500;
  kbSpace        = $3920;

  {--------------------- help constants ----------------------}
  hcNoContext  = 0;

  {------------------- DragMode constants --------------------}
  dmDragMove        = $01;
  dmDragGrow        = $02;
  dmLimitLoX        = $10;
  dmLimitLoY        = $20;
  dmLimitHiX        = $40;
  dmLimitHiY        = $80;
  dmLimitVertical   = dmLimitLoY+dmLimitHiY;
  dmLimitHorizontal = dmLimitLoX+dmLimitHiX;
  dmLimitAll        = dmLimitHorizontal+dmLimitVertical;

  {-------------------- GrowMode constants -------------------}
  gmFixedLoX        = 1;  {view fixed to owner's loy}
  gmFixedLoY        = 2;
  gmFixedHiX        = 4;
  gmFixedHiY        = 8;
  gmFixedAll        = 15; {view fixed to it's owner on all directions}

  {------------------- Listviewer Constants ------------------}
  lcShadows     = 1;
  lcGAP         = 4;

  {---------------------- Font Constants ---------------------}
  ViewFontHeight   : Word = 0;  {Default values}
  ViewFontWidth    : Word = 0;

  {--------------------- Standard File Id's ------------------}
  Id_MIF           : TID = 'MIF'#$1a;

  {----------------- Default Working Directory ---------------}
  Def_Dir = '\BP\ICONS\';

  {------------------------ System Flags ---------------------}
  Sys_SoundsActive = $0001; {sound effects}
  Sys_Busy         = $0002; {hour glass}
  Sys_BackProcess  = $0004; {multitasking}
  Sys_LowerMode    = $0008; {always lower}
  Sys_Relax        = $0010; {no multitasker support}
  Sys_ZoomEffect   = $0020;
  Sys_CycleEffect  = $0040; {process cycle effect active?}

  {----------------------- Field Flags --------------------------}
  ffRJust = 1;

  {----------------------- State Constants -----------------------}
  Scf_Visible        = $0001;  {View is visible on screen}
  Scf_CursorVis      = $0002;  {Cursor can be visible in view}
  Scf_CursorIns      = $0004;  {Cursor is in the insert state}
  Scf_Active         = $0008;  {View is active}
  Scf_Selected       = $0010;  {View is selected}
  Scf_Focused        = $0020;  {View is focused}
  Scf_Disabled       = $0040;  {View is disabled and can not be selected}
  Scf_Modal          = $0080;  {View is modal (executed)}
  Scf_Exposed        = $0100;  {View is inserted to GSystem}
  Scf_CursorOn       = $0200;  {What the hell?}
  Scf_CursorPainting = $0400;  {So?}
  Scf_Backprocess    = $0800;  {now it backs}

  sfModal            = Scf_Modal; {Compatibility assignment}

  {--------------------- Options Constants ----------------------}
  Ocf_Selectable    = $0001; {View can be selected}
  Ocf_TopSelect     = $0002; {When selected it becomes the top view}
  Ocf_FirstClick    = $0004; {Select does not clear event}
  Ocf_Framed        = $0008; {View is a frame}
  Ocf_PreProcess    = $0010; {Events first come to this view}
  Ocf_PostProcess   = $0020; {Events last come here}
  Ocf_CenterX       = $0040; {View is horizontal centered}
  Ocf_CenterY       = $0080; {View is vertical centered}
  Ocf_Centered      = $00C0; {View is horiz&vert centered}
  Ocf_AlwaysOnTop   = $0100; {View is always on top}
  Ocf_InSelectPaint = $0200; {I don't know what the hell is this}
  Ocf_Close         = $0400; {View can be closed}
  Ocf_Resize        = $0800; {View can be resized}
  Ocf_Move          = $1000; {View can be moved}
  Ocf_ZoomEffect    = $2000; {When inserting view it is being zoomed}
  Ocf_Paintfast     = $4000; {Paint view fast}
  Ocf_FullDrag      = $8000; {Paint view when dragging}

  {--------------------- Group Phase Constants --------------------}
  Phc_Focused     = 00; {Event is sending to focused view}
  Phc_PreProcess  = 01; {Event is sending to all PreProcess views}
  Phc_PostProcess = 02; {Event is sending to all PostProcess views}
  Phc_Positional  = 03; {Going to first available view}

  {-----------------------  Basic Commands  -----------------------}
  CmHalt         = $0F8;
  cmQuit         = $100;
  cmCancel       = $101;
  cmOk           = $102;

  cmYes               = $103;
  cmNo                = $104;
  cmAbort             = $105;
  cmRetry             = $106;
  cmIgnore            = $107;
  cmReboot            = $108;
  cmSaveAs            = $109;
  cmMessage           = $10A; {system message request - it may be unnecessary}
  cmFocusRecord       = $10B;
  cmSpecial           = $10C;
  cmItemSelected      = $10D; {Enter pressed on an item}
  cmCancelCopy        = $10E;    {This is for copier}
  cmCalcButton        = $10F;   {a button in calculator pressed}
  cmAdd               = $110;
  cmChange            = $111;
  cmClose             = $112;
  cmReceivedFocus     = $113;
  cmReleasedFocus     = $114;
  cmRecord            = $115; {SKart and DKart generic commands}
  cmNewRecord         = $116;
  cmDel               = $117;
  cmKeySelect         = $118;
  cmBackgroundClicked = $119;
  cmSwitch            = $11A;
  cmTest              = $11B;
  cmSave              = $11C;
  cmLoad              = $11D;
  cmHelp              = $11E;
  cmFileOpen          = cmLoad;
  cmFileReplace       = $11F;
  cmFileClear         = $120;
  cmFileInit          = $121;
  cmPrint             = $122;
  cmExamine           = cmSpecial;
  { Network commands }
  cmNetworkSetup      = $123;
  cmNetworkMessage    = $124;
  cmNetworkTxtMsg     = $125;
  cmSendNetMsg        = $126;
  cmSendNetBroadcast  = $127;
  cmForceUser         = $128;
  cmChatting          = $129;
  cmNetUserLogin      = $12A;
  cmNetUserLogout     = $12B;

  cmGoBack            = $12C;
  cmAbout             = $12d;
  cmActivate          = $12e;
  cmContents          = $12f;

  cmPlay              = $130;
  cmStop              = $131;
  cmPause             = $132;
  cmEject             = $133;
  cmNext              = $134;
  cmPrev              = $135;

  cmInputNotify       = $136;
  cmActivateYourself  = $137;
  cmRefresh           = $138;
  cmOpen              = $139;
  cmInputlineChanged  = $13a;

  ClearData = 8192;

  {---------------------- Basic Bradcasts ----------------------}
  Brc_ChangeDesktopColor = $201;  {Not used}
  Brc_IsModified         = $202;  {Hey guys! Are these views modified?}
  Brc_IsValid            = $203;  {Hey guys! Anyone refusing?}
  Brc_IsNull             = $204;  {Hey guys! What the fuck!}
  Brc_ChangeFrame        = $205;  {Change all frame styles immediately!}
  Brc_ProcessFinished    = $206;  {The infoptr can be disposed now}
  Brc_AppUpdate          = $207;  {This is a top secret data - SSG}
  Brc_FileFocused        = $208;  {A file is focused on listviewer}
  Brc_ZOrderChanged      = $209;  {an insert or delete processed}

  Brc_KeySelected        = $20A;  {?}
  Brc_KeyCanceled        = $20B;  {?}
  Brc_GetCurrentRecord   = $20C;  {?}
  Brc_KeyFocused         = $20D;  {?}
  Brc_ResetModified      = $20E;  {?}
  Brc_KeyGone            = $20F;  {A KeyLister is disposed from ZOrder}
  Brc_IsAnyOne           = $210;
  Brc_RefreshFiles       = $211; {Data file contents has been changed}
  Brc_DisposeGadgets     = $212; {Remove all gadgets from system (eyes etc)}
  Brc_ScrollBarChanged   = $213; {update yer vars according to scrollbar}
  Brc_TopicChanged       = $214; {topic is changed dude}
  Brc_ColorSelected      = $215; {color sel}

  {------------------ Frame Shadow Constants -----------------}
  Frm_ShadowCount         = 1;
  Frm_HeaderSize          = 20; {20}
  Frm_Size                = 2;

  Clb_Bar                 = 5;

  {------------------- Paint State Constants -----------------}
  Psc_Paintable    = $0001;
  Psc_PaintStarted = $0002;
  Psc_PaintEnded   = $0004;

  {------------------------ View Types -----------------------}
  VtView            = $0001;
  VtFrame           = $0002;
  VtBackground      = $0003;
  VtInputLine       = $0004;
  VtButton          = $0005;
  VtImage           = $0006;
  VtStaticText      = $0007;
  VtVifButton       = $0008;
  VtDubVifButton    = $0009;
  VtSingleChkBox    = $000A;
  VtCheckBox        = $000B;
  VtRadioButton     = $000C;
  VtCalcButton      = $000D;
  VtLabel           = $000E;
  VtListViewer      = $000F;

  VtGroup           = $4001;
  VtWindow          = $4002;
  VtSystem          = $4003;

  {-------------------- InputLine Constants ----------------------}
  Idc_Upper        = $0001;  {Make string upper}
  Idc_Password     = $0002;  {Do not show entered string}
  Idc_AdvancedDel  = $0004;  {When deleting back, if needed delete left}
  Idc_PreDel       = $0008;  {When deleting ahead, if needed delete right}
  Idc_NoScroll     = $0010;  {Do not scroll input line}
  Idc_ResetOnFocus = $0020;  {When focused set cursor to start of line}
  Idc_Business     = $0040;  {Insert commas into numbers}
  Idc_Formatted    = $0080;  {Format string}
  Idc_DataChanged  = $0100;  {last operation changed the data}
  Idc_FirstUpper   = $0200;  {make only first char upper}
  Idc_English      = $0400;  {english uppercase}
  Idc_StrDefault   = Idc_AdvancedDel + Idc_ResetOnFocus;
  Idc_UpperStr     = Idc_StrDefault + Idc_Upper;
  Idc_NumDefault   = Idc_StrDefault + Idc_Business;
  Idc_NumDefaultX  = Idc_StrDefault + Idc_Business + Idc_Formatted;
  { internal config flags }
  Idc_ShowScroll   = $8000;  {Show scroll arrows}
  Idc_Scroll       = $4000;  {By the time, scroll}
  Idc_Modified     = $2000;  {Am I modified?}
  Idc_ReadyToDel   = $1000;  {I am ready for you Karnagh! Yeeah}
  { PaintFlags Constants }
  Idc_PaintLeft    = $01;  {Put BitMap or what?}
  Idc_PaintRight   = $02;
  {Menu constants}
  Mnc_NoImmed      = $0001;{do not activate immediately - internal purposes}

  RStackSize = 512;  {Internal stack size}
  BMHeader = $4d42;

  {------------------------ ListViewer Config ------------------}
  Lvc_KeepList = 1;  {Do not dispose item collection in destructor}

  {----------------------- Color Constants ---------------------}
  Black         = 0;
  Blue          = 1;
  Green         = 2;
  Cyan          = 3;
  Red           = 4;
  Magenta       = 5;
  Brown         = 6;
  LightGray     = 7;
  DarkGray      = 8;
  LightBlue     = 9;
  LightGreen    = 10;
  LightCyan     = 11;
  LightRed      = 12;
  LightMagenta  = 13;
  Yellow        = 14;
  White         = 15;

  {----------------------- Palette Constants -----------------------}
  StartUpPalette : TRGBArray =
    ((R:00; G:00; B:00), {0}  {black}
     (R:32; G:00; B:00), {1}  {red}
     (R:00; G:32; B:00), {2}  {green}
     (R:40; G:40; B:00), {3}  {brown}
     (R:00; G:00; B:40), {4}  {blue}
     (R:48; G:00; B:48), {5}  {magenta}
     (R:00; G:32; B:32), {6}  {cyan}
     (R:46; G:46; B:54), {7}  {lightgray}
     (R:32; G:32; B:50), {8}  {darkgray}
     (R:63; G:00; B:00), {9}  {lightred}
     (R:00; G:59; B:00), {10} {lightgreen}
     (R:59; G:59; B:00), {11} {yellow}
     (R:00; G:00; B:63), {12} {lightblue}
     (R:63; G:00; B:63), {13} {lightmag}
     (R:40; G:53; B:53), {14} {lightcyan}
     (R:63; G:63; B:63));{15} {white}

  PalXLat : Array[0..15] of Byte = (00,01,02,03,04,05,20,07,56,57,58,59,60,61,62,63);

  { real colorz }
  cBlack             = Black;
  cBlue              = Red;
  cGreen             = Green;
  cCyan              = Brown;
  cRed               = Blue;
  cMagenta           = Magenta;
  cBrown             = Cyan;
  cLightGray         = LightGray;
  cDarkGray          = DarkGray;
  cLightBlue         = LightRed;
  cLightGreen        = LightGreen;
  cLightCyan         = Yellow;
  cLightRed          = LightBlue;
  cLightMagenta      = LightMagenta;
  cYellow            = LightCyan;
  cWhite             = White;

  { Shadow Color Constants }
  Shc_UpperLeft      : byte = cWhite;
  Shc_LowerRight     : byte = cDarkgray;  {Blue}

  { BackPlane Color (The old lightgray) }
  Col_Back               : byte = cLightGray;

  {-------------------- IndexViewer Colors --------------------}
  Col_Bar     : byte = CCyan;
  Col_Focused : byte = CBlack;
  Col_Normal  : byte = CBlack;
  Col_Passive : byte = CLightGray;
  Col_Sep     : byte = cCyan;

  {------------------ Other color constants --------------------}

  Col_LCDBack           : byte = cBlack;        { LCD Colors }
  Col_LCD               : byte = cLightGreen;

  Col_BarFull           : byte = cLightRed;    { BarGraph Color }

  Col_StaticText        : byte = cBlue;  { StaticText and FileText Color }

  Col_RButtonPassive    : byte = cBlack;        { RadioButton colors }
  Col_RButtonActive     : byte = cWhite;

  Col_FocusedButton     : byte = cBlack;        { Button colors }
  Col_ButtonTextNormal  : byte = cBlack;
  Col_ButtonTextHigh    : byte = cLightRed;

  Col_InputPromptActive : byte = cLightRed; { Inputline colors }
  Col_InputPromptPassive: byte = cRed;
  Col_InputScroll       : byte = cLightGreen;
  Col_InputLine         : byte = cBlack;     { cGreen }
  Col_Cursor            : byte = cLightGray;

  Col_BackGround        : byte = cDarkGray; { Desktop Color }

  Clb_YSize              = Frm_HeaderSize-Frm_Size-Frm_ShadowCount*2;
  Clb_XSize              = Clb_YSize;
  Clb_X                  = Frm_ShadowCount * 2 + Frm_Size + 1;
  Clb_Y                  = Clb_X;
  Frm_ReSizerRange       = Frm_HeaderSize+1;

  {------------------- Backprocess Constants --------------------}
  ElapsedIdleTicks       : longint = 0;
  Tickstart              : longint = 0;
  ScreenSaverDelay       : longint = 1200;{So be it}

  {---------------------- Mouse Constants -----------------------}
  mbLeft        = 1;
  mbRight       = 2;

  mmMove        = 1;
  mmLBPressed   = 2;
  mmLBReleased  = 4;
  mmRBPressed   = 8;
  mmRBReleased  = 16;
  mbMaskAll     = mmMove + mmLBPressed + mmLBReleased + mmRBPRessed +
                  mmRBReleased;

  {------------------------- Button constants ---------------------}
  btEnterDelay  = 2;  {delay when button is activated by key}
  btShadowCount = 2;{2}  {button shadow count}
  btLineCount   = 2;{2}  {outer border count}
  btXGAP        = 3;

  {----------------------- RadioButton constants -------------------}
  isFocused  = 1; {Item States}
  isDisabled = 2;

  rbcXGAP       = 10;
  rbcYGAP       = 3;

  {---------------- Minimum Window Size (standard) -----------}
  Wnd_MinSize : TPoint =
    (X:(Clb_XSize*2 + 5 + (Frm_Size+1+(Frm_ShadowCount*2)) * 2);
    Y:(Clb_YSize*2 + 5 + Frm_HeaderSize + (Frm_Size+1+(Frm_ShadowCount*2)) * 2));

  {---------------------- Font Constants ---------------------}
  FtBitMapped    = $00;   {Font versions}
  FtProportional = $01;

  FtMaxCharY     = 101; {Maximum Font Height (80x101)}

  {-------------------- MessageBox Constants ------------------}
  mfWarning      = $0000;       { Display a Warning box }
  mfError        = $0001;       { Display an Error box }
  mfInfo         = $0002;       { Display an Information Box }
  mfConfirm      = $0003;       { Display a Confirmation Box }

  mfYesButton    = $0100;       { Put a Yes button into the dialog }
  mfNoButton     = $0200;       { Put a No button into the dialog }
  mfOKButton     = $0400;       { Put an OK button into the dialog }
  mfCancelButton = $0800;       { Put a Cancel button into the dialog }
  mfAbortButton  = $1000;
  mfRetryButton  = $2000;
  mfIgnoreButton = $4000;
  mfRebootButton = $8000;

  mfYesNoCancel      = mfYesButton + mfNoButton + mfCancelButton;
  mfYesNo            = mfYesButton + mfNoButton;
  mfOKCancel         = mfOKButton + mfCancelButton;
  mfLineSpacing      = 8; {Default Line Spacing}
  mfAbortRetryIgnore = mfAbortButton + mfRetryButton + mfIgnoreButton;
  mfMaxButtons       = 7;

  Msg_Yes    = 0;
  Msg_No     = 1;
  Msg_OK     = 2;
  Msg_Cancel = 3;
  Msg_Abort  = 4;
  Msg_Retry  = 5;
  Msg_Ignore = 6;
  Msg_Help   = 7;

  Msg_Warning = 0;
  Msg_Info    = 2;
  Msg_Error   = 1;
  Msg_Confirm = 3;

  Commands: array[0..mfMaxButtons] of word =
    (cmYes, cmNo, cmOK, cmCancel, cmAbort, cmRetry, cmIgnore,cmHelp);

  {turkish messages}
  Msg: array[0..mfMaxButtons] of string[12] =
    ('~Evet', '~Hayçr', '~Tamam', '~Vazgeá','~òptal','Tekrar ~Dene','~Boüver','~Ne gibi?');
  Titles: array[0..3] of string[10] =
    ('DòKKAT','HATA','AÄIKLAMA','ONAY');
(*
  {english messages}
  MsgEnglish: array[0..mfMaxButtons] of string[7] =
    ('~Yes', '~No', '~OK', '~Cancel','~Abort','~Retry','~Ignore','Re~boot');
  TitlesEnglish: array[0..3] of string[7] =
    ('WARNING','ERROR','INFO','CONFIRM');*)

  DaysOfMonths    : Array[1..12] of Byte = (31,28,31,30,31,30,31,31,30,31,30,31);

  ESNamesOfMonths : Array[1..12] of String[3] =
  ('jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec');

  {---------------------- Multi-national support ------------------}
  Lan_English     = 0;
  Lan_Turkish     = 1;
  Language : byte = Lan_English;

  {-------------------- FileDialog Constants -----------------------}
  fdOkButton      = $0001;      { Put an OK button in the dialog }
  fdOpenButton    = $0002;      { Put an Open button in the dialog }
  fdReplaceButton = $0004;      { Put a Replace button in the dialog }
  fdClearButton   = $0008;      { Put a Clear button in the dialog }
  fdHelpButton    = $0010;      { Put a Help button in the dialog }
  fdNoLoadDir     = $0100;      { Do not load the current directory }

  {--------------------- Background styles ------------------------}
  bsSolid          = 1;
  bsBitMap         = 2;
  bsPattern        = 3;

  {----------------------- Resource Ids --------------------------}

  Rid_SystemFont                 = 'SystemFont';

  Rid_WindowsCloseBox            = 1;

  Rid_Arrow                      = 1;
  Rid_HourGlass                  = 2;

  Rid_StdMarkedCheckBox          = 3;
  Rid_StdUnMarkedCheckBox        = 2;
  Rid_RadioButtonActive          = 5;
  Rid_RadioButtonPassive         = 4;

  Rid_StartUpbackground          = 6;

  Rid_RandDecGun                 = 100;
  Rid_RandIncGun                 = 101;
  Rid_RandDecMon                 = 102;
  RId_RandIncMon                 = 103;

  Rid_CustKart                   = 130;
  Rid_CustList                   = 131;
  Rid_FirmaKart                  = 132;
  Rid_FirmaList                  = 133;
  Rid_Randevu                    = 134;
  Rid_Raporlar                   = 135;
  Rid_Istatistikler              = 136;
  Rid_HesapMakinesi              = 137;
  Rid_Setup                      = 138;
  Rid_MenuAbout                  = 139;
  Rid_Exit                       = 140;
  Rid_DosShell                   = 141;
  Rid_Help                       = 142;

  Rid_About                      = 200;

  Rid_Devil1                     = 300;
  Rid_Devil2                     = 301;
  Rid_EyeWhite                   = 302;
  Rid_EyeBlack                   = 303;

  Rid_SoundStartup               = 1;
  Rid_SoundShutDown              = 2;
  Rid_SndCheer                   = 3;
  Rid_SndLetsParty               = 4;
  Rid_SndMotorStart              = 5;
  Rid_SndOh                      = 6;
  Rid_SndAdios                   = 7;
  Rid_SndLaugh1                  = 8;
  Rid_SndLaugh2                  = 9;
  Rid_SndLaugh3                  = 10;
  Rid_SndTerminat                = 11;
  Rid_SndDentist                 = 12;
  Rid_SndUhOh                    = 13;
  Rid_SndShoot                   = 14;

  Rid_ScrollerPgUp  = 700;
  Rid_ScrollerPgDn  = 701;
  Rid_ScrollerEnd   = 702;
  Rid_ScrollerHome  = 703;
  Rid_ScrollerBack  = 704;

  {-------------------- Constants Used by Tools -----------------------}
  mnfHorizontal         = 1;
  mnfVertical           = 2;
  mnfNoSelect           = 4;

  blTextButton          = 1; {Text button}
  blVIFButton           = 2; {Bitmap button}
  blInputLine           = 3; {String input line}
  blNInputLine          = 4; {Numeric input line}
  blCheckBox            = 5; {Check box}
  blInputDate           = 6; {Input date}

  chcShadowSize         = 4;    {Chooser Constants}
  chcXGAP               = 4;
  chcYGAP               = 4;

  Ivc_YGap    = 3;
  Ivc_XGap    = 2;  {Min value is 4}
  Ivc_YFrmGap = 3;
  Ivc_XFrmGap = 3;
  Ivc_HdrSpc  = 5;

implementation

begin
  XTimer       := Ptr(Seg0040,$6C);
  XShiftState  := Ptr(Seg0040,$17);
  XCurrentMode := Ptr(Seg0040,$49);
end.
*** End of file ***
