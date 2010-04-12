{
Name    : XNibbles 1.00a
Purpose : Nibbles game for x...
Date    : 10st Apr 96
Time    : 11:30
}

unit XNib;

interface

const

  maxTailLength = 1000;

  nsPlaying     = 1;

  playFieldWidth  = 40;
  playFieldHeight = 12;

  Player1Name     = 'Kusmuk';
  Player2Name     = 'Dubara';

type

  TLoc = record
    x,y:byte;
  end;

  TPlayerStat = record
    Name      : string[9];
    Score     : longint;
    Length    : word;
    Tail      : array[1..maxTailLength] of TLoc;
  end;

  PNibView = ^TNibView;
  TNibView = object(TView)
    P1,P2  : TPlayerStat;
    constructor Init(x,y:integer);
  end;

implementation

constructor TNibView.Init;
var
  R:TRect;
begin
  R.Assign(0,0,playFieldWidth*ViewFontWidth,playFieldHeight*ViewFontHeight);
  R.Move(x,y);
  inherited Init(R);
  EventMask := evKeyboard or evCommand;
  ClearBuf(P1,SizeOf(P1));
  ClearBuf(P2,SizeOf(P2));
  P1.Name := Player1Name;
  P2.Name := Player2Name;
end;

end.