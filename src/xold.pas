{
Name    : X/Old 1.00a
Purpose : Older constants
Moved   : SSG
Date    : 6th May 97
Time    : 04:37
}

unit XOld;

interface

const

  Psw_Char         : char = '*';

  Stf_TypeMask     = $1F;
  Stf_DigitMask    = $1F;
  Stf_DecMask      = $E0;
  Stf_RecSize      = $8000;

  Stf_Byte         = $0001;
  Stf_ShortInt     = $0002;
  Stf_Word         = $0003;
  Stf_Integer      = $0004;
  Stf_LongInt      = $0005;
  Stf_Single       = $0006;
  Stf_Real         = $0007;
  Stf_Double       = $0008;
  Stf_Extended     = $0009;
  Stf_Comp         = $000A;
  Stf_Char         = $000B;
  Stf_HDate        = $000C;
  Stf_FDate        = $000D;
  Stf_HTime        = $000E;
  Stf_FTime        = $000F;
  Stf_HTime24      = $0010;
  Stf_FTime24      = $0011;
  Stf_Pointer      = $0012;
  Stf_String       = $0013;
  Stf_CString      = $0014;
  Stf_LString      = $0015;
  Stf_Record       = $0016;
  Stf_Bit          = $0017;
  Stf_UprString    = $0018; {UPPER}
  Stf_FString      = $0019; {First Upper}

  Stf_DByte        = [Stf_Word,Stf_Integer,Stf_HDate,Stf_FDate,Stf_HTime,Stf_FTime,Stf_HTime24,Stf_FTime24];
  Stf_QByte        = [Stf_LongInt];
  Stf_Swapable     = [Stf_Word,Stf_Integer,Stf_HDate,Stf_FDate,Stf_HTime,
                      Stf_FTime,Stf_HTime24,Stf_FTime24,Stf_LongInt,
                      Stf_String,Stf_CString,Stf_LString];

  Stf_IndexKey     = $0020;
  Stf_Duplicate    = $0040;
  Stf_PrimeKey     = Stf_IndexKey;
  Stf_DuplicateKey = Stf_IndexKey + Stf_Duplicate;
  Stf_DupKey       = Stf_DuplicateKey;
  Stf_Business     = $0080;
  Stf_FillZero     = $0100;
  Stf_OvrStr       = $0200;

  Stf_ShowCnvErr   = $08;

  Stf_Upper        = $01;
  Stf_Short        = $02;

  Stf_DefSize : Array[1..$12] of Byte = (SizeOf(Byte),
                                         SizeOf(ShortInt),
                                         SizeOf(Word),
                                         SizeOf(Integer),
                                         SizeOf(LongInt),
                                         SizeOf(Single),
                                         SizeOf(Real),
                                         SizeOf(Double),
                                         SizeOf(Extended),
                                         SizeOf(Comp),
                                         SizeOf(Char),
                                         SizeOf(Word),
                                         SizeOf(Word),
                                         SizeOf(Word),
                                         SizeOf(Word),
                                         SizeOf(Word),
                                         SizeOf(Word),
                                         SizeOf(Pointer));

  TurkishFormat : Array[0..3] of char = (',' , '.' , '/' , ':');
  ForeignFormat : Array[0..3] of char = ('.' , ',' , '/' , ':');

  TLNamesOfMonths : Array[1..12] of string[7] =
  ('ocak','üubat','mart','nisan','mayçs','haziran','temmuz','aßustos','eylÅl','ekim','kasçm','aralçk');
  TSNamesOfMonths : Array[1..12] of string[3] =
  ('ock','übt','mrt','nis','may','haz','tem','aßu','eyl','ekm','kas','ara');
  ELNamesOfMonths : Array[1..12] of String[9] =
  ('january','february','march','april','may','june','july','august','september','october','november','december');
  TLNamesOfDays   : Array[0..6] of string[9] =
  ('pazar','pazartesi','salç','áarüamba','perüembe','cuma','cumartesi');
  TSNamesOfDays   : Array[0..6] of string[3] =
  ('paz','pts','sal','áar','per','cum','cts');

implementation

end.