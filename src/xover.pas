{
Name            : X/Over 1.00a
Purpose         : Makes overlay inits easier...
Coder           : SSG
Date            : 3rd Dec 94
}

{$O-}

unit XOver;

interface

uses Objects,Overlay,OverXMS;

const

  xoNone = 0;
  xoDisk = 1;
  xoEMS  = 2;
  xoXMS  = 3;
  xoFail = -1;

function InitXOver(f:FNameStr):integer;

implementation

function InitXOver(f:FNameStr):integer;
begin
  InitXOver := xoFail;
  OvrInit(ParamStr(0));
  if OvrResult <> ovrOk then OvrInit(f);
  if OvrResult <> ovrOk then exit;
  OvrInitXMS;
  if OvrResult = ovrOk then InitXOver := xoXMS else begin
    OvrInitEMS;
    if OvrResult = ovrOk then InitXOver := xoEMS else InitXOver := xoDisk;
  end;
end;

end.