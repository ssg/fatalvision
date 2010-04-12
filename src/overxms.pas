{
Name            : OverXMS 1.00a
Purpose         : Load overlays in XMS
Coder           : Wilbert van Leijen
}

unit OverXMS;

{$O- }

interface

uses Overlay;

const
  ovrNoXMSDriver = -7;                 { No XMS driver installed }
  ovrNoXMSMemory = -8;                 { Insufficient XMS memory available }

procedure OvrInitXMS;

implementation

procedure OvrInitXMS; External;
{$L OVERXMS.OBJ }

end.  { OverXMS }
