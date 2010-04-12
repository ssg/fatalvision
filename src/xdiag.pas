{
Name            : XDiag 1.7a
Purpose         : Simple diagnostic functions for install programs etc
Date            : 27th Oct 93
Coder           : SSG

Update info:
------------
18th Jul 94 - 16:59 - Replaced old CPU detection routines...
18th Jul 94 - 18:04 - Added FPU detection routines...
19th Jul 94 - 02:06 - Added cache detection routines..
19th Jul 94 - 02:59 - Added video card detection routines...
21th Jul 94 - 13:44 - Added v86 mode detection... (but not working)
26th Jul 94 - 17:30 - Added GetTextLines... proc... not worked...removed...
28th Jul 94 - 12:39 - Added CMOS procs..
 8th Aug 94 - 22:36 - Fixed a bug in GetVideo proc...
18th Dec 94 - 12:22 - Fixed a bug in DESQview detection...
20th Dec 94 - 08:28 - Added GetOSName...
23rd Dec 94 - 12:05 - Added Ram disk detection routine...
 2nd Jan 95 - 22:17 - Compatibilized to DPMI
14th Jan 95 - 03:35 - Fixed a bug in GetHDDcxxx...
12th Apr 95 - 00:51 - Added ValidDrive...
18th Mar 96 - 23:45 - Removed numhandles proc... (it was unfinished)
24th Jun 96 - 01:37 - Removed many procs... they were unnecessary
24th Jun 96 - 22:36 - Simlified DESQview detection...
 2rd Jul 96 - 13:37 - Added isvga...
 8th Jul 96 - 15:41 - Perfected DESQview detection... (DE00 was wrong)
 3rd Jan 97 - 02:40 - Added isqemm..
 3rd Jan 97 - 05:13 - added some detection procs...
 5th Jan 97 - 03:20 - stabilized cache detection routines...
 3rd Mar 97 - 15:25 - added getcpu..
 3rd Mar 97 - 15:30 - added linux dosemu detection...
 3rd Mar 97 - 15:40 - added getuart...
 3rd Mar 97 - 15:46 - added getdrivetype...
}

unit XDiag;

interface

uses Disk,XTypes,XIO,Objects,Dos;

type

  TCPU = (cpu8088,cpu8086,cpuV20,cpuV30,cpu188,cpu186,cpu286,cpu386,
          cpu486,cpuPentium);

  TMultiTasker = (mtNone,mtOS2,mtDESQview,mtWindows,mtNetWare,mtLinux);

  TUART = (uaNone,ua8250,ua16450,ua16550A,ua16550N);

  TDriveType = (dtNone,dtFixed,dtRemovable,dtRemote,dtCDROM,dtDblSpace,
                dtSUBST,dtStacker3,dtStacker4,dtRAMDrive,dtDublDisk,
                dtBernoulli,dtDiskreet,dtSuperStor);

function  GetDiskDriveCount:Byte; {How many diskette drives?}
function  GetHardDiskCount:Byte; {How many hard disks?}
function  GetDDC:byte;           {Get DOS drive count}
function  GetHDDCount:byte;               {How many hard disks?}
function  IsDiskCache:boolean;
function  GetFILES:byte;            {learn maximum file handles}
function  GetMultitasker:TMultiTasker;
function  GetCPU:TCPU;
function  GetUART(baseaddr:word):TUART;
function  GetDriveType(drive:byte):TDriveType;
function  ValidDrive(drive:byte):boolean;
function  IsVGA:boolean;
function  IsQEMM:boolean;
function  IsEMM386:boolean;
function  IsMICEMM:boolean;
function  IsSHARE:boolean;
function  IsDOS5TASKER:boolean;
function  IsKSTACK:boolean;
function  GetQEMMVersion:word;
procedure FlushDiskCache;

implementation

function IsKSTACK;assembler;
asm
  mov  ax,0d44fh
  xor  bx,bx
  int  2fh
  xor  bx,bx
  cmp  ax,44ddh
  jne  @no
  inc  bl
@no:
  mov  ax,bx
end;

function IsDOS5TASKER;assembler;
asm
  mov  ax,4b02h
  xor  bx,bx
  mov  di,bx
  mov  es,bx
  int  2fh
  xor  al,al
  mov  bx,es
  or   bx,di
  je   @skip
  inc  al
@skip:
end;

procedure FlushDiskCache;assembler;
asm
  mov  ax,4a10h
  mov  bx,1
  int  2fh
end;

function IsSHARE;assembler;
asm
  mov  ax,1000h
  int  2fh
  xor  ah,ah
  cmp  al,$ff
  jne  @skip
  inc  ah
@skip:
  mov  al,ah
end;

function IsEMM386;assembler;
asm
  mov  ax,0ffa5h
  int  67h
  xor  al,al
  cmp  ah,84h
  jne  @skip
  inc  al
@skip:
end;

function IsMICEMM;assembler;
asm
  mov  ax,5bf0h
  int  67h
  xor  al,al
  or   ah,ah
  jne  @end
  inc  al
@end:
end;

const

  QEMMSignHi = $5145;
  QEMMSignLo = $4d4d;

function GetQEMMVersion:word;assembler;
asm
  mov  ah,3fh
  mov  cx,QEMMSignHi
  mov  dx,QEMMSignLo
  int  67h
  mov  ah,03h
  call dword ptr es:[di]
end;

function IsQEMM:boolean;assembler;
asm
  mov  ah,3fh
  mov  cx,QEMMSignHi
  mov  dx,QEMMSignLo
  int  67h
  xor  al,al
  or   ah,ah
  jne  @end
  inc  al
@end:
end;

function IsVGA;assembler;
asm
  mov ax,1a00h
  int 10h
  xor al,al
  cmp bl,7
  je  @ok
  cmp bl,8
  jne @end
@ok:
  inc al
@end:
end;

function GetMultitasker:TMultiTasker;assembler;
asm
  push ds
  {desqview detection}
  mov  ah,2bh
  mov  cx,4445h
  mov  dx,5351h
  mov  al,1
  int  21h
  cmp  al,0ffh
  je   @Next
  mov  al,mtDESQview
  jmp  @Exit
@Next:
  {windows detection}
  mov  ax,1600h
  int  2fh
  or   al,al
  je   @Next2
  cmp  al,80h
  je   @Next2
  mov  al,mtWindows
  jmp  @Exit
@Next2:
  {os/2 detection}
  mov  ax,4010h
  int  2fh
  cmp  ax,4010h
  je   @Next3
  mov  al,mtOS2
  jmp  @Exit
@Next3:
  {linux dosemu detection}
{ check for the BIOS date }
{$IFNDEF DPMI}
  mov  ax,$F000
  mov  ds,ax
  mov  bx,$FFF5
  mov  ax,'20'
  cmp  word ptr [bx],'20'
  jne  @else
  cmp  word ptr [bx+2],'2/'
  jne  @else
  cmp  word ptr [bx+4],'/5'
  jne  @else
  cmp  word ptr [bx+6],'39'
  jne  @else
  mov  al,mtLinux
  jmp  @exit
{$ENDIF}
  {novell netware detection}
@Next4:
  xor  ax,ax
  mov  di,ax
  mov  es,ax
  mov  ax,07a00h
  int  2fh
  cmp  al,$ff
  jne  @else
  mov  al,mtNetware
  jmp  @exit
@Else:
  mov  al,mtNone
@Exit:
  pop  ds
end;

type

  PSFTHeader = ^TSFTHeader;
  TSFTHeader = record
    Next     : PSFTHeader;
    Number   : word;
  end;

function GetFILES;
var
  sft:PSFTHeader;
  count:byte;
  xseg,offs:word;
begin
  count := 0;
  asm
    push  ds
    mov   ax,5200h
    int   21h
    pop   ds
    mov   ax,word ptr es:[bx+6]
    mov   xseg,ax
    mov   ax,word ptr es:[bx+4]
    mov   offs,ax
  end;
  sft := Ptr(xseg,offs);
  repeat
    inc(count,sft^.Number);
    sft := sft^.Next;
  until word(sft^.Next) = $FFFF;
  inc(count,sft^.Number);
  GetFILES := count;
end;

function ValidDrive(drive:byte):boolean;assembler;
asm
  push  ds
  mov   bl,Drive
  cmp   bl,26
  ja    @Fuck
@Loop:
  mov   ax,4408h
  int   21h
  cmp   al,1
  ja    @Fuck
  mov   al,1
  jmp   @Exit
@Fuck:
  xor   al,al
@Exit:
  pop   ds
end;

function GetDDC:byte;
var
  b:byte;
begin
  for b:=26 downto 1 do if ValidDrive(b) then begin
    GetDDC := b;
    exit;
  end;
end;

function IsDiskCache:boolean;assembler;
asm
@IsSmartDrv:
  mov  ax,4a10h
  xor  bx,bx
  mov  cx,0ebabh
  int  2fh
  cmp  ax,$babe
  mov  al,0
  jne  @exit
  inc  al
@Exit:
end;

function GetHDDCount:byte;assembler;
asm
  mov   ah,08
  mov   dl,80h
  int   13h
  mov   al,dl
end;

function GetHardDiskCount:Byte;assembler;
asm
  mov   ah,8
  mov   dl,80h
  int   13h
  xor   ax,ax
  mov   al,dl
end;

function GetDiskDriveCount:Byte;assembler;
asm {192}
  mov  ax,Seg0040
  mov  es,ax
  mov  di,10h
  mov  ax,word ptr es:[di]
  and  ax,$00FF
  mov  cl,6
  shr  al,cl
  inc  ax
end;

function GetCPU;assembler;
asm
  pushf
  xor  bx,bx
  push bx
  popf
  pushf
  pop  bx
  and  bx,0F000h
  cmp  bx,0F000h
  je   @no286
  mov  bx,07000h
  push bx
  popf
  pushf
  pop  bx
  and  bx,07000h
  jne  @test486
  mov  dl,6
  jmp  @end
@test486:
  mov  dl,7
  xor  si,si
  mov  ax,cs
{$IFDEF DPMI}
  add  ax,SelectorInc
{$ENDIF}
  mov  es,ax
  mov  byte ptr es:[@queue486+11], 46h     { 46h == "INC SI" }
@queue486:
  nop; nop; nop; nop; nop; nop; nop; nop; nop; nop; nop; nop
  or   si,si
  jnz  @end
  inc  dl
  db   66h ; pushf      { pushfd }
  db   66h ; pushf      { pushfd }
  db   66h ; pop  ax    { pop eax }
  db   66h ; mov  cx,ax { mov ecx,eax }
  db   66h,35h
  db   00h,00h,20h,00h  { xor eax,(1 shl 21) (Pentium ID flag) }
  db   66h ; push ax    { push eax }
  db   66h ; popf       { popfd }
  db   66h ; pushf      { pushfd }
  db   66h ; pop  ax    { pop eax }
  db   66h,25h
  db   00h,00h,20h,00h  { and eax,(1 shl 21) }
  db   66h,81h,0E1h
  db   00h,00h,20h,00h  { and ecx,(1 shl 21) }
  db   66h ; cmp ax,cx  { cmp eax,ecx }
  je   @is486
  inc  dl
@is486:
  db   66h ; popf       { popfd }
  jmp  @end
@no286:
  mov  dl,5
  mov  al,0FFh
  mov  cl,21h
  shr  al,cl
  jnz  @testdatabus
  mov  dl,2
  sti
  xor  si,si
  mov  cx,0FFFFh
{$IFDEF DPMI}
  push es
  push ds
  pop  es
{$ENDIF}
  rep  seges lodsb      { == rep lods byte ptr es:[si] }
{$IFDEF DPMI}
  pop  es
{$ENDIF}
  or   cx,cx
  jz   @testdatabus
  mov  dl,1
@testdatabus:
  push cs
{$IFDEF DPMI}
  pop  ax
  add  ax,SelectorInc
  mov  es,ax
{$ELSE}
  pop  es
{$ENDIF}
  xor  bx,bx
  std
  mov  al,90h
  mov  cx,3
  call @ip2di
  cli
  rep  stosb
  cld
  nop; nop; nop
  inc  bx
  nop
  sti
  or   bx,bx
  jz   @end      { v20 or 8086 or 80186 }
  cmp  dl,1
  je   @its8088
  cmp  dl,2
  je   @itsV30
  cmp  dl,5
  jne  @end
  mov  dl,4
  jmp  @end
@its8088:
  xor  dl,dl
  jmp  @end
@itsV30:
  mov  dl,3
  jmp  @end
@ip2di:
  pop  di
  push di
  add  di,9
  retn
@end:
  popf
  mov  al,dl
end;

function GetUART;assembler;
const
  IIR=2;
  SCR=5; {IIR+5 = 7 o da SCR}
asm
  mov  dx,baseaddr
  add  dx,IIR
  in   al,dx
  test al,30h
  mov  al,0
  jne  @exit
  inc  al
  out  dx,al
  in   al,dx
  test al,$c0
  mov  al,ua16550a
  jne  @exit
  in   al,dx
  test al,$80
  mov  al,ua16550n
  jne  @exit
  add  dx,SCR
  mov  al,$aa
  out  dx,al
  in   al,dx
  cmp  al,$aa
  mov  al,ua8250
  jne  @exit
  mov  al,ua16450
@exit:
end;

{getdrivetype begins}
type
	ControlBlk25 = record	{ control block for INT 25 extended call }
			StartSector : LongInt; { start sector to read }
			Count	    : Word;    { number of sectors to read }
			BufferOffs  : Word;    { data buffer offset }
			BufferSeg   : Word;    { data buffer segment }
		       end;

function checkStacker4( Drive : Byte ) : Boolean; near; assembler;
{ returns True if Drive is Stacker 4 compressed volume, False otherwise.
  This also may return True with previous versions of Stacker - I didn't
  check it. /Bobby Z. 29/11/94 }

var CB   : ControlBlk25;
    Boot : array[1..512] of Byte;
asm
	push	ds
	mov	al,Drive
	cmp	al,1
	ja	@@1
	sub	al,al
	jmp	@@Q
@@1:
	push	ss
	pop	ds
	lea	bx,CB
	sub	ax,ax
	mov	word ptr ds:ControlBlk25[bx].StartSector,ax
	mov	word ptr ds:ControlBlk25[bx].StartSector[2],ax
	mov	word ptr ds:ControlBlk25[bx].Count,1
	lea	dx,Boot
	mov	word ptr ds:ControlBlk25[bx].BufferOffs,dx
	mov	word ptr ds:ControlBlk25[bx].BufferSeg,ds
	mov	al,Drive
	sub	cx,cx
	dec	cx
	mov	si,sp
	int	25h
	cli
	mov	sp,si
	sti
	pushf
	lea	si,Boot
	add	si,1F0h		{ Stacker signature CD13CD14CD01CD03 should }
	sub	al,al		{ appear at offset 1F0 of boot sector.      }
	popf
	jc	@@Q		{ was error reading boot sector - assume    }
				{ not Stacker drive                         }
	cmp	word ptr ds:[si],13CDh
	jnz	@@Q
	cmp	word ptr ds:[si][2],14CDh
	jnz	@@Q
	cmp	word ptr ds:[si][4],01CDh
	jnz	@@Q
	cmp	word ptr ds:[si][6],03CDh
	jnz	@@Q
	mov	al,1
@@Q:
	pop	ds
end; { checkStacker4 }

function checkDiskreet(Drive : byte) : boolean; near; assembler;
{ Returns True if Drive is Norton Diskreet drive, otherwise it returns False }
type
  TDiskreetPacket = record
    Header : array [1..6] of byte;
    Drive  : char;
    Size   : longint
  end;
const DrvName : PChar = '@DSKREET'; {-Diskreet driver name}
var Packet : TDiskreetPacket;
asm
        push    ds
        mov     ax,0FE00h
        mov     di,'NU'   { 4E55h='NU' }
        mov     si,'DC'   { 4443h='DC' }
        int     2Fh
        or      al,al     { check for zero }
        je      @@2
        cmp     al,1      { check for 1 }
        je      @@2
@@1:
        sub     al,al      { return False }
        jmp     @@4
@@2:
        lds     dx,DrvName
        mov     ax,3D02h
        int     21h
        jc      @@1
        mov     bx,ax
        mov     ax,seg [Packet]
        mov     ds,ax
        mov     dx,offset [Packet]
        mov     es,ax
        mov     di,dx
        mov     cx,type TDiskreetPacket
        sub     al,al
        cld
        rep     stosb     { initialize Packet fields }
        mov     di,offset [Packet.Header]
        mov     ax,12FFh  { store first two bytes in Packet header }
        stosw
        mov     di,offset [Packet.Drive]
        mov     al,Drive
        add     al,64     { convert drive number to drive letter }
        stosb             { store drive letter }
        mov     ax,4403h  { ready to send Diskreet Packet }
        mov     cx,7
        mov     si,'dc'   { 6463h = 'dc' }
        mov     di,'NU'   { 4E55h = 'NU' }
        int     21h       { assuming ds=seg [Packet], dx=offset [Packet],
                            bx=Handle }
        mov     ah,3Eh
        int     21h       { close device }
        mov     si,offset [Packet.Size]
        lodsw
        or      ax,ax
        jnz     @@3
        lodsw
        or      ax,ax
        jz      @@1
@@3:
        mov     al,True   { return True }
@@4:
        pop     ds
end; { checkDiskreet }

function checkSuperStor(Drive : byte) : boolean; near; assembler;
type
  TSSPacket = record
    Sign  : word;
    Sign1 : word;
    P     : pointer;
    Res   : array [1..4] of byte
  end;
var
  Packet : TSSPacket;
asm
        push    ds
        mov     ax,seg [Packet]
        mov     es,ax
        mov     di,offset [Packet]
        mov     cx,type TSSPacket
        cld
        rep     stosb   { initialize SStor Packet structure }
        mov     di,offset [Packet.Sign]
        mov     ax,0AA55h
        stosw             { init Packet.Sign }
        mov     ax,0201h
        stosw             { init Packet.Sign1 }
        mov     ax,4404h
        mov     dx,seg [Packet]
        mov     ds,dx
        mov     dx,offset [Packet]
        mov     cx,12
        mov     bl,Drive
        int     21h
        jc      @@2          { if error then quit }
        mov     si,offset [Packet.Sign]
        lodsw
        or      ax,ax        { if Packet.Sign<>0 then quit }
        jnz     @@2
        lodsw
        cmp     ax,0201h     { if Packet.Sign1<>0201h then quit }
        jne     @@2
        les     di,[Packet.P]
        mov     ax,[es:di+5Dh]
        test    ax,40h       { host drive? }
        jz      @@2
        mov     cl,byte ptr es:[di+24h]
        add     cl,'A'
        mov     ah,30h
        int     21h
        cmp     ah,4
        jb      @@1
        inc     di
@@1:
        les     di,dword ptr es:[di+5Fh]
        mov     bl,[es:di]
        add     bl,'A'
        cmp     cl,Drive   { ????? I don't know whether bl or cl is a host
                             SStor drive... }
        jne     @@2
        mov     al,True   { return True }
        jmp     @@3
@@2:
        sub     al,al     { return False }
@@3:
        pop     ds
end; { checkSuperStor }

function GetDriveType; assembler;
{ Detects the type for a specified drive. Drive is a drive number to detect the
  type for (0=detect current (default) drive, 1=A, 2=B, 3=C...)

  Returns: One of the dtXXX-constants.

  Note: Function will work under DOS version 3.30 or later
        Also should work under DPMI and Windows.
}

asm
	cmp	Drive,0
	jne	@@1
	mov	ah,19h    { get active drive number in al }
	int	21h
	mov	Drive,al
	inc	Drive
@@1:
        push    word ptr [Drive]
        call    checkDiskreet
        or	al,al
	jz	@CDROMcheck
	mov	bl,dtDiskreet
        jmp     @@7
@CDROMcheck:
	mov	ax,1500h  { check for CD-ROM v2.00+ }
	sub	bx,bx
	int	2Fh
	or	bx,bx
	jz	@@2
	mov	ax,150Bh
	sub	ch,ch
	mov	cl,Drive
        dec     cl      { bug fixed with CD-ROM drives, thanx to Ralf Quint }
	int	2Fh     { drives for this function start with 0 for A: }
	cmp	bx,0ADADh
	jne	@@2
	or	ax,ax
	jz	@@2
	mov	bl,dtCDROM
	jmp	@@7
@@2:
	mov	ax,4409h { check for SUBST'ed drive }
	mov	bl,Drive
	int	21h
	jc	@DblSpaceChk
	test	dh,80h
	jz	@DblSpaceChk
	mov	bl,dtSUBST
	jmp	@@7
@DblSpaceChk:
	mov	ax,4A11h  { check for DoubleSpace drive }
	mov	bx,1
	mov	dl,Drive
	dec	dl
	int	2Fh
	or	ax,ax     { is DoubleSpace loaded? }
	jnz	@@3
	cmp	dl,bl     { if a host drive equal to compressed, then get out... }
	je	@@3
	test	bl,80h    { bit 7=1: DL=compressed,BL=host
                                 =0: DL=host,BL=compressed }
	jz	@SStorChk   { so avoid host drives, assume host=fixed :) }
	inc	dl
	cmp	Drive,dl
	jne	@SStorChk
	mov	bl,dtDblSpace
	jmp	@@7
@SStorChk:
        push    word ptr [Drive]
        call    checkSuperStor
        or	al,al
	jz	@@3
	mov	bl,dtSuperStor
        jmp     @@7
@@3:
	mov	ax,4409h     { check for remote drive }
	mov	bl,Drive
	int	21h
	jc	@@5
	and	dh,10h
	jz	@@4
	mov	bl,dtRemote
	jmp	@@7
@@4:
	mov	al,Drive     { check for Stacker 4 volume }
	or	al,al
	jz	@@getDrv
	dec	al
@@goStac:
	push	ax
	call	checkStacker4
	or	al,al
	jz	@@8
	mov	bl,dtStacker4
	jmp	@@7
@@8:
        mov     ax,4408h     { check for fixed (hard) drive }
        mov     bl,Drive
        int     21h
        jc      @@5
        or      al,al
        jz      @@6
        push    ds           { check for RAM drive }
        mov     ax,ss
        mov     ds,ax
        mov     si,sp
        sub     sp,28h	     { allocate 28h bytes on stack }
        mov     dx,sp
        mov     ax,440Dh     { generic IOCTL }
        mov     cx,860h      { get device parameters }
        int     21h          { RAMDrive and VDISK don't support this command }
	jc	@@cleanup
	pushf
	mov	di,dx
	cmp	byte ptr ds:[di+6],0F8h	{ DoubleDisk returns 0F8h in media type}
	jz	@@dubldsk		{ field of BPB if drive in question is }
					{ compressed }
	popf
	jmp	@@cleanup
@@dubldsk:
	popf
	mov	bl,dtDublDisk
	mov	sp,si
	pop	ds
	jmp	@@7
@@cleanup:
        mov     sp,si
        pop     ds
        mov     bl,dtRAMDrive
        jc      @@7
	push	ds
	mov	ah,1Ch			{ this function works _really_ slowly }
	mov	dl,Drive		{ get media descriptor pointer }
	int	21h
	cmp	byte ptr ds:[bx],0FDh
	pop	ds
	jnz	@@fixed
	push	ds
	mov	ah,32h			{ get BPB pointer }
	mov	dl,Drive
	int	21h
	cmp	byte ptr ds:[bx+0Bh],2	{ Sectors per FAT is more than 2 for }
	pop	ds			{ Bernoully drives }
	jz	@@fixed
	mov	bl,dtBernoulli
	jmp	@@7
@@fixed:
        mov     bl,dtFixed
        jmp     @@7
@@5:
	sub	bl,bl        { mov bl,dtError cuz dtError=0 }
	jmp	@@7
@@getDrv:
	mov	ah,19h
	int	21h
	jmp	@@goStac		
@@6:
	mov	bl,dtRemovable   { else - removeable media }
@@7:
	mov	al,bl
end; { GetDriveType }

end.