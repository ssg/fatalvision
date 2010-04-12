{
Name    : X/IPX v1.00a
Purpose : Novell IPX implementation
Coder   : SSG
Date    : 3rd Jan 97
Time    : 03:37
}

unit XIPX;

interface

const

  islNormal    = 0;
  islKeepAlive = $ff;

  ipxDynamicSocket = 0;

  {ipx errors}
  ieOK                = 0;
  ieNoFreeSockets     = $fe;
  ieSocketAlreadyOpen = $ff;

  {ipx inuse flags}
  iufAvailable           = 0;
  iufAESTemp             = $e0;
  iufProcessing1         = $f6;
  iufProcessing2         = $f7;
  iufIPXCritical         = $f8;
  iufSPXListening        = $f9;
  iufProcessing          = $fa;
  iufHolding             = $fb;
  iufAESWaiting          = $fc;
  iufAESDelaying         = $fd;
  iufAwaitingPacket      = $fe;
  iufSendingPacket       = $ff;

  {ipx completion codes}
  iccSuccess             = 0;
  iccRemoteTerminate     = $ec;
  iccAbnormalTerminate   = $ed;
  iccInvalidConnectionID = $ee;
  iccSPXTableFull        = $ef;
  iccHell                = $f9;
  iccConnectionFail      = $fa;
  iccCancelled           = $fc;
  iccMalformedPacket     = $fd;
  iccUndelivarablePacket = $fe;
  iccPhysicalError       = $ff;

  {ipx packet types}
  iptUnknown             = 0;
  iptRIP                 = 1;
  iptEcho                = 2;
  iptError               = 3;
  iptPacketExchange      = 4;
  iptSPX                 = 5;
  iptNetwareCore         = $11;
  iptPropagated          = $14;


type

  TIPXECB = record
    Link                : longint;
    ESR                 : pointer; {event service routine}
    InUseFlag           : byte;
    CompletionCode      : byte;
    Socket              : word;
    IPXWorkspace        : array[0..3] of byte;
    DriverWorkspace     : array[0..11] of byte;
    LocalNodeAddr       : array[0..5] of byte;
    FragCount           : word;
  end;

  TIPXFragment = record
    Ptr    : pointer;
    Size   : word;
  end;

  TIPXHeader = record
    Checksum         : word;
    Length           : word;
    TransportControl : byte;
    PacketType       : byte;
  end;

  TIPXAddr = object
    Network : array[0..3] of byte;
    Node    : array[0..5] of byte;
  end;

  TIPXSocketAddr = object(TIPXAddr)
    Socket       : word;
  end;

function  XIPXInit:boolean;
function  XIPXOpenSocket(longevity:byte; var socket:word):byte;
procedure XIPXCloseSocket(socket:word);
procedure XIPXSendPacket(var ecb:TIPXECB);
procedure XIPXListenPacket(var ecb:TIPXECB);
procedure XIPXScheduleEvent(var ecb:TIPXECB; delay:word);
procedure XIPXScheduleSpecialEvent(var ecb:TIPXECB; delay:word);
procedure XIPXCancelEvent(var ecb:TIPXECB);
procedure XIPXRelinquish;
procedure XIPXGetAddr(var addr:TIPXAddr);
procedure XIPXDisconnect(var addr:TIPXSocketAddr);
function  XIPXGetIntervalMarker:word;

implementation

var

  IPXAddr : pointer;

procedure XIPXDisconnect;assembler;
asm
  mov  bx,0bh
  les  si,addr
  int  7ah
end;

procedure XIPXGetAddr;assembler;
asm
  mov  bx,9
  les  si,addr
  int  7ah
end;

procedure XIPXRelinquish;assembler;
asm
  mov  bx,0ah
  int  7ah
end;

function XIPXGetIntervalMarker;assembler;
asm
  mov  bx,8
  int  7ah
end;

procedure XIPXScheduleSpecialEvent;assembler;
asm
  mov  bx,7
  mov  ax,delay
  les  si,ecb
  int  7ah
end;

procedure XIPXCancelEvent;assembler;
asm
  mov  bx,6
  les  si,ecb
  int  7ah
end;

procedure XIPXScheduleEvent;assembler;
asm
  mov  bx,5
  mov  ax,delay
  les  si,ecb
  int  7ah
end;

procedure XIPXSendPacket;assembler;
asm
  mov  bx,3
  les  si,ecb
  int  7ah
end;

procedure XIPXListenPacket;assembler;
asm
  mov  bx,4
  les  si,ecb
  int  7ah
end;

procedure XIPXCloseSocket;assembler;
asm
  mov  bx,1
  mov  dx,socket
  int  7ah
end;

function XIPXOpenSocket;assembler;
asm
  xor  bx,bx
  mov  al,longevity
  les  di,socket
  mov  dx,es:[di]
  int  7ah
  xchg dh,dl
  mov  es:[di],dx
end;

function XIPXInit;assembler;
asm
  mov  ax,7a00h
  int  2fh
  mov  word ptr IPXAddr,di
  mov  word ptr IPXAddr+2,es
end;

end.