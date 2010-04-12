{
Name    : X/APM 1.00a
Purpose : Advanced Power Management support
Coder   : SSG
Date    : 27th Jun 96
Time    : 16:31

updates:
--------
27th Jun 96 - 16:32 - started...
27th Jun 96 - 17:10 - success...
}

unit XAPM;

interface

const

  apm16bitAPI      = 1;
  apm32bitAPI      = 2;
  apmSlowIdle      = 4;
  apmDisabled      = 8;
  apmDisengaged    = 16;

  adiBIOS          = 0;
  adiAllDevices    = 1;
  adiDisplay       = $0100;
  adi2ndStorage    = $0200;
  adiParallel      = $0300;
  adiSerial        = $0400;
  adiNetwork       = $0500;
  adiPCMCIA        = $0600;

  asiReady         = 0;
  asiStandBy       = 1;
  asiSuspend       = 2;
  asiOFF           = 3;

  apsOffLine       = 0;
  apsOnLine        = 1;
  apsBackup        = 2;
  apsUnknown       = $ff;

  absHigh          = 0;
  absLow           = 1;
  absCritical      = 2;
  absCharging      = 3;
  absUnknown       = $ff;

function APMInstalled:boolean;
function APMVersion:word;
function APMFlags:word;
function APMPowerStatus:byte;
function APMBatteryStatus:byte;
function APMBatteryLife:byte;
function APMGetState(adi:word):word;

procedure APMIdle;
procedure APMBusy;
procedure APMSetState(adi,asi:word);
procedure APMStandBy;
procedure APMSuspend;
procedure APMEnable(enable:boolean);

implementation

function APMGetState;assembler;
asm
  mov  ax,530ch
  mov  bx,adi
  int  15h
  mov  ax,bx
end;

procedure SubStatus;assembler;
asm
  mov  ax,530ah
  mov  bx,1
  int  15h
end;

function APMPowerStatus;assembler;
asm
  call SubStatus
  mov  al,bh
end;

function APMBatteryStatus;assembler;
asm
  call SubStatus
  mov  al,bl
end;

function APMBatteryLife;assembler;
asm
  call SubStatus
  mov  al,cl
end;

procedure APMEnable;assembler;
asm
  mov  ax,5308h
  mov  bx,1
  mov  cl,enable
  xor  ch,ch
  int  15h
end;

procedure APMSetState;assembler;
asm
  mov  ax,5307h
  mov  bx,adi
  mov  cx,asi
  int  15h
end;

procedure APMStandBy;
begin
  APMSetState(adiAllDevices,asiStandBy);
end;

procedure APMSuspend;
begin
  APMSetState(adiAllDevices,asiSuspend);
end;

procedure APMIdle;assembler;
asm
  mov  ax,5305h
  int  15h
end;

procedure APMBusy;assembler;
asm
  mov  ax,5306h
  int  15h
end;

function APMFlags;assembler;
asm
  mov  ax,5300h
  xor  bx,bx
  int  15h
  mov  ax,cx
end;

function APMInstalled;assembler;
asm
  mov  ax,5300h
  xor  bx,bx
  int  15h
  mov  ax,0
  cmp  bx,504dh
  jne  @skip
  inc  ax
@skip:
end;

function APMVersion;assembler;
asm
  mov  ax,5300h
  xor  bx,bx
  int  15h
end;

end.