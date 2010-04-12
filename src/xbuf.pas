{
Name            : XBuf 1.03d
Purpose         : Basic buffer operations
Coder           : SSG
Date            : 29th Nov 93

Update info:
------------
23rd Jul 94 - 20:29 - Working with this compression thing...
24th Jul 94 - 14:12 - There's only one bug in compressor... Sometimes
                      compressed buffer extracted to 4 bytes more than
                      original buffer size. I will check it.
24th Jul 94 - 14:48 - Added compress optimization...
20th Aug 94 - 17:36 - Rewritten compressing routines in TP...
18th Nov 94 - 17:16 - Added RevBuf...
 4th Dec 94 - 00:21 - Added SearchBuf...
10th Dec 94 - 15:18 - Fixed a serious bug in FastMove...
24th Dec 94 - 14:43 - Rewritten Move32... benchmark results:
                        Borland Pascal's Move = 26 ticks
                        SSG's FastMove        = 13 ticks (2x faster!)
                        SSG's Move32!         = 6  ticks (4x faster!)
 2nd Jan 95 - 01:24 - Very optimized Move32... Thanx to FM de Monatserio
18th Jan 95 - 00:44 - Re-optimized clearbuf...
 6th Feb 95 - 01:29 - Fixed a bug in SearchBuf...
 3rd Aug 95 - 23:12 - Revised clearbuf.. testing something...
 3rd Aug 95 - 23:14 - Found a bug in clearbuf... fixing it NOW.
 3rd Aug 95 - 23:15 - So fixed...
14th Nov 95 - 14:22 - Added GetCRC32... (The Real Thing)
27th Nov 95 - 22:26 - Boosted SwapBuf... Stripped source from RLE thing..
28th Nov 95 - 00:24 - Added FillWord...
10st Jun 96 - 01:22 - Added TranslateBuf...
21st Aug 96 - 12:53 - Fixes in searchbuf...
 7th Nov 96 - 01:07 - 1 key-size bugfix in searchbuf...
 9th Nov 96 - 12:21 - rewrite of getbytecount...
21st Jul 97 - 10:45 - added xorbuf...
24th Aug 97 - 14:23 - bugfix in searchbuf...
}

unit XBuf;

interface

const

  FIRST_CRC : longint = -1;

procedure EnCode(var buf;count:word);                      {encrypt buffer}
procedure DeCode(var buf;count:word);                      {decrypt buffer}
procedure ClearBuf(var buf;count:word);                      {clear buffer}
procedure SwapBuf(var src,dst;count:word);                   {swap buffers}
procedure FastMove(var src,dst;count:word);          {fastmove src to dest}
procedure Move32(var src,dst;count:word);             {32-bit fastest move}
procedure RevBuf(var buf; count:word);                     {reverse buffer}
procedure FillBuf(var buf; count:word; what:byte);        {whattane byte}
procedure FillWord(var buf; count:word; what:word);       {whattane word}
procedure TranslateBuf(var buf; count:word; src,dst:byte); {src -> dst}
procedure XORBuf(var buf; count:word; xorval:byte);

function  GetByteCount(var buf;count:word;key:byte):word; {bytes in buffer}
function  BufCmp(var src,dst;count:word):boolean;         {compare buffers}
function  GetChecksum(var buf;size:word):word;              {find sum of buffer}
function  GetChecksum32(Var Buf; Size:Word):Longint; {find 32 bit sum of buffer}
function  IsEmpty(var buf;count:word;emptychar:byte):boolean; {empty buf?}
function  SearchBuf(var buf,key; bufsize,keysize:word; var foundoffs:word):boolean; {search buf}
function  GetCRC32(var buf; count:word; startcrc:longint):longint; {get 32 bit crc}

implementation

procedure XORBuf;assembler;
asm
  cld
  les  di,buf
  mov  ah,xorval
  mov  cx,count
@loop:
  mov  al,es:[di]
  xor  al,ah
  stosb
  loop @loop
end;

function SearchBuf(var buf,key; bufsize,keysize:word; var foundoffs:word):boolean;assembler;
asm
  cld
  push  ds
  mov   cx,bufsize
  mov   dx,keysize
  sub   cx,dx
  jbe   @NotFound
  les   di,buf
  lds   si,key
@loop:
  mov   si,word ptr key
  lodsb
  repne scasb
  jne   @notfound
  mov   ax,cx
  mov   bx,di
  mov   cx,dx
  dec   cx
  or    cx,cx
  repe  cmpsb
  mov   cx,ax
  mov   di,bx
  jne   @loop
@found:
  mov   ax,seg @data
  mov   ds,ax
  mov   ax,di
  les   di,buf
  sub   ax,di
  dec   ax
  les   di,foundoffs
  mov   es:[di],ax
  mov   al,1
  jmp   @end
@notfound:
  xor   al,al
@end:
  pop   ds
end;

procedure TranslateBuf(var buf; count:word; src,dst:byte);assembler;
asm
  les  di,buf
  mov  cx,count
  mov  bl,src
  mov  bh,dst
@loop:
  mov  al,es:[di]
  cmp  al,bl
  jne  @skip
  mov  es:[di],bh
@skip:
  inc  di
  loop @loop
end;

procedure FillBuf;assembler;
asm
  cld
  les  di,buf
  mov  al,what
  mov  ah,al
  mov  cx,count
  shr  cx,1
  rep  stosw
  adc  cx,cx
  rep  stosb
end;

procedure FillWord;assembler;
asm
  cld
  les  di,buf
  mov  ax,what
  mov  cx,count
  rep  stosw
end;

procedure RevBuf;assembler;
asm
  cld
  push ds
  les  di,buf
  add  di,count
  dec  di
  lds  si,buf
@Loop:
  cmp  di,si
  jbe  @Exit
  lodsb
  xchg al,es:[di]
  mov  ds:[si-1],al
  dec  di
  jmp  @Loop
@Exit:
  pop  ds
end;

function IsEmpty;assembler;
asm
  cld
  push ds
  lds  si,buf
  mov  cx,count
  mov  ah,emptychar
@loop:
  lodsb
  cmp  al,ah
  jne  @notempty
  loop @loop
  mov  al,true
  jmp  @quit
@notempty:
  xor  al,al
@quit:
  pop  ds
end;

procedure ClearBuf;assembler;
asm
  cld
  les  di,Buf
  xor  ax,ax
  mov  cx,Count
  shr  cx,1
  rep  stosw
  adc  cx,cx
  rep  stosb
end;

procedure FastMove(var src,dst;count:word);assembler;
asm
  cld
  les  di,dst
  push ds
  lds  si,src
  mov  cx,count
  xor  al,al
  shr  cx,1
  jnb  @Skip
  inc  al
  or   cx,cx
  je   @Movs
@Skip:
  rep  movsw
  or   al,al
  je   @Exit
@Movs:
  movsb
@Exit:
  pop  ds
end;

function GetByteCount;assembler;
asm
  mov   cx,count
  mov   bl,key
  les   di,buf
  xor   ax,ax
@loop:
  mov   bh,es:[di]
  cmp   bh,bl
  jne   @skip
  inc   ax
@skip:
  inc   di
  loop  @loop
end;

procedure SwapBuf(var src,dst;count:word);assembler;
asm
  push  ds
  mov   cx,count
  les   di,dst
  lds   si,src
@loop:
  mov   al,[si]
  xchg  al,es:[di]
  mov   [si],al
  inc   si
  inc   di
  loop  @loop
  pop   ds
end;

function  BufCmp(var src,dst;count:word):boolean;assembler;
asm
  cld
  push ds
  lds  si,src
  les  di,dst
  mov  cx,count
  repz cmpsb
  jnz  @No
  mov  al,true
  jmp  @Fuck
@No:
  mov  al,false
@Fuck:
  pop  ds
end;

const
  Cst_Xor  = $1104;
  Cst_XorB = 97;

procedure EnCode(var buf;count:word);assembler;
asm
    cld
    push  ax
    push  di
    les   di,buf
    mov   cx,count
    mov   bh,Cst_XorB
@Loop:
    mov   bl,byte ptr es:[di]
    rol   bl,3
    xor   bl,bh
    rol   bl,3
    mov   byte ptr es:[di],bl
    inc   di
    loop  @Loop
    pop   di
    pop   ax
end;

procedure DeCode(var buf;count:word);assembler;
asm
    cld
    push  ax
    push  di
    les   di,buf
    mov   cx,count
    mov   bh,Cst_XorB
@Loop:
    mov   bl,byte ptr es:[di]
    ror   bl,3
    xor   bl,bh
    ror   bl,3
    mov   byte ptr es:[di],bl
    inc   di
    loop  @Loop
    pop   di
    pop   ax
end;

function GetCheckSum(var buf;size:word):word;assembler;
asm
  xor  ax,ax
  les  di,buf
  xor  bh,bh
  mov  cx,size
@loop:
  mov  bl,byte ptr es:[di]
  add  ax,bx
  inc  di
  loop @loop
end;

function GetChecksum32(Var Buf; Size:Word):Longint;
var
  P:^byte;
  sum:longint;
begin
  sum := 0;
  P := @buf;
  while size > 0 do begin
    sum := P^+(sum xor $475353);
    inc(word(P));
    dec(size);
  end;
  GetCheckSum32 := sum;
end;

procedure Move32(var src,dst;count:word);assembler;
asm
  push ds
  cld
  les  di,dst
  lds  si,src
  mov  cx,count
  shr  cx,1
  jnc  @NextOne
  movsb
@NextOne:
  shr  cx,1
  db   66h
  rep  movsw
  adc  cx,cx
  rep  movsw
  pop  ds
end;

function crc_32_tab(b:byte):longint;
const
  c32t: ARRAY[0..255] OF LONGINT = (
$00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $706af48f, $e963a535, $9e6495a3,
$0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07, $90bf1d91,
$1db71064, $6ab020f2, $f3b97148, $84be41de, $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7,
$136c9856, $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9, $fa0f3d63, $8d080df5,
$3b6e20c8, $4c69105e, $d56041e4, $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b,
$35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3, $45df5c75, $dcd60dcf, $abd13d59,
$26d930ac, $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599, $b8bda50f,
$2802b89e, $5f058808, $c60cd9b2, $b10be924, $2f6f7c87, $58684c11, $c1611dab, $b6662d3d,
$76dc4190, $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f, $9fbfe4a5, $e8b8d433,
$7807c9a2, $0f00f934, $9609a88e, $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
$6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457,
$65b0d9c6, $12b7e950, $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65,
$4db26158, $3ab551ce, $a3bc0074, $d4bb30e2, $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb,
$4369e96a, $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9,
$5005713c, $270241aa, $be0b1010, $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
$5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17, $2eb40d81, $b7bd5c3b, $c0ba6cad,
$edb88320, $9abfb3b6, $03b6e20c, $74b1d29a, $ead54739, $9dd277af, $04db2615, $73dc1683,
$e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8, $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1,
$f00f9344, $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb, $196c3671, $6e6b06e7,
$fed41b76, $89d32be0, $10da7a5a, $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5,
$d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b,
$d80d2bda, $af0a1b4c, $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef, $4669be79,
$cb61b38c, $bc66831a, $256fd2a0, $5268e236, $cc0c7795, $bb0b4703, $220216b9, $5505262f,
$c5ba3bbe, $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31, $2cd99e8b, $5bdeae1d,
$9b64c2b0, $ec63f226, $756aa39c, $026d930a, $9c0906a9, $eb0e363f, $72076785, $05005713,
$95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21,
$86d3d2d4, $f1d4e242, $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1, $18b74777,
$88085ae6, $ff0f6a70, $66063bca, $11010b5c, $8f659eff, $f862ae69, $616bffd3, $166ccf45,
$a00ae278, $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7, $4969474d, $3e6e77db,
$aed16a4a, $d9d65adc, $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
$bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605, $cdd70693, $54de5729, $23d967bf,
$b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d
);
begin
  crc_32_tab := c32t[b];
end;

function GetCRC32(var buf; count:word; startcrc:longint):longint;
  function upd(b:byte; crc:longint):longint;
  begin
    upd := crc_32_tab(BYTE(crc XOR LONGINT(b))) XOR ((crc SHR 8) AND $00FFFFFF);
  end;
var
  P:^byte;
  acrc:longint;
begin
  P := @buf;
  acrc := startcrc;
  while count > 0 do begin
    acrc := upd(P^,acrc);
    dec(count);
    inc(word(P));
  end;
  GetCRC32 := acrc;
end;

end.