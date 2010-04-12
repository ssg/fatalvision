{
Name    : LZSS 1.00a
Purpose : Fine compression routines
Coder   : SSG
Date    : 22nd Nov 95

updates:
--------
22nd Nov 95 - 04:23 - SSG
 9th Nov 96 - 03:54 - hmm... adapted to dynamic thing? hmm...
}

unit LZSS;

interface

const

  LZSSBufSize = 8192;    { 8k File Buffers }

type

  TLZSSReadProc  = function:word;
  TLZSSWriteProc = procedure;

var

  LZSSReadProc  : TLZSSReadProc;
  LZSSWriteProc : TLZSSWriteProc;

procedure LZSSAssign(i:TLZSSReadProc; o:TLZSSWriteProc);
procedure LZSSCompress;
procedure LZSSUnCompress;

const

  N           = 4096; {4096}
  F           = 18;  {18}
  THRESHOLD   = 2;
  NUL         = N * 2;
  DBLARROW    = $AF;

type

  PLZSSInfo = ^TLZSSInfo;
  TLZSSInfo = record
    LZSSInBuf,LZSSOutBuf : Array[0..PRED(LZSSBufSize)] of BYTE;      { File buffers. }

    LZSSInBufPtr  : WORD;
    LZSSOutBufPtr : WORD;

    InLZSSBufSize : WORD;
    printcount, height, matchPos, matchLen, lastLen, printPeriod : WORD;
    opt : BYTE;

    TextBuf  : array[0.. N + F - 2] OF BYTE;
    Left,Mom : array [0..N] OF WORD;
    Right    : array [0..N + 256] OF WORD;
    codeBuf  : array [0..16] of BYTE;
  end;

const

  lzi : PLZSSInfo = NIL;

implementation

uses XBuf,Memory;

procedure LZSSAssign;
begin
  LZSSReadProc  := i;
  LZSSWriteProc := o;
end;

procedure Getc;assembler;
asm
  push    bx
  mov     bx, [TLZSSInfo.LZSSinBufPtr]
  cmp     bx, [TLZSSInfo.inLZSSBufSize]
  jb      @getc1
  push    ds
  push    cx
  push    dx
  push    di
  push    si
  mov     ax,seg @data
  mov     ds,ax
  call    LZSSReadProc
  pop     si
  pop     di
  pop     dx
  pop     cx
  pop     ds
  mov     [TLZSSInfo.inLZSSBufSize], ax
  or      ax, ax
  jz      @getc2
  xor     bx, bx
@getc1:     mov     al, [offset TLZSSInfo.LZSSInBuf + bx]
  inc     bx
  mov     [TLZSSInfo.LZSSinBufPtr], bx
  pop     bx
  clc
  jmp     @end
@getc2:     pop     bx
  stc
@end:
end;

procedure Putc;assembler;
asm
  push    bx
  mov     bx, [TLZSSInfo.LZSSOutBufPtr]
  mov     [OFFSet TLZSSInfo.LZSSOutBuf + bx], al
  inc     bx
  cmp     bx, LZSSBufSize
  jb      @putc1
  mov     [TLZSSInfo.LZSSOutBufPtr],LZSSBufSize   { Just so the flush will work. }
  push    ax
  push    ds
  push    cx
  push    dx
  push    di
  push    si
  mov     ax,seg @data
  mov     ds,ax
  call    LZSSWriteProc
  pop     si
  pop     di
  pop     dx
  pop     cx
  pop     ds
  pop     ax
  xor     bx, bx
@putc1:
  mov     [TLZSSInfo.LZSSoutBufPtr], bx
  pop     bx
end;

procedure InitTree;assembler;
asm
  cld
  push    ds
  pop     es
  mov     di, TLZSSInfo.right
  add     di, (N + 1) * 2
  mov     cx, 256
  mov     ax, NUL
  rep     stosw
  mov     di, TLZSSInfo.mom
  mov     cx, N
  rep     stosw
end;

procedure Splay;assembler;
asm
@Splay1:
  mov     si, [Offset TLZSSInfo.Mom + di]
  cmp     si, NUL
  ja      @Splay4
  mov     bx, [Offset TLZSSInfo.Mom + si]
  cmp     bx, NUL
  jbe     @Splay5
  cmp     di, [Offset TLZSSInfo.Left + si]
  jne     @Splay2
  mov     dx, [Offset TLZSSInfo.Right + di]
  mov     [Offset TLZSSInfo.Left + si], dx
  mov     [Offset TLZSSInfo.Right + di], si
  jmp     @Splay3
@Splay2:
  mov     dx, [Offset TLZSSInfo.Left + di]
  mov     [Offset TLZSSInfo.Right + si], dx
  mov     [Offset TLZSSInfo.Left + di], si
@Splay3:
  mov     [Offset TLZSSInfo.Right + bx], di
  xchg    bx, dx
  mov     [Offset TLZSSInfo.Mom + bx], si
  mov     [Offset TLZSSInfo.Mom + si], di
  mov     [Offset TLZSSInfo.Mom + di], dx
@Splay4:
  jmp     @end
@Splay5:
  mov     cx, [Offset TLZSSInfo.Mom + bx]
  cmp     di, [Offset TLZSSInfo.Left + si]
  jne     @Splay7
  cmp     si, [Offset TLZSSInfo.Left + bx]
  jne     @Splay6
  mov     dx, [Offset TLZSSInfo.Right + si]
  mov     [Offset TLZSSInfo.Left + bx], dx
  xchg    bx, dx
  mov     [Offset TLZSSInfo.Mom + bx], dx
  mov     bx, [Offset TLZSSInfo.Right + di]
  mov     [Offset TLZSSInfo.Left +si], bx
  mov     [Offset TLZSSInfo.Mom + bx], si
  mov     bx, dx
  mov     [Offset TLZSSInfo.Right + si], bx
  mov     [Offset TLZSSInfo.Right + di], si
  mov     [Offset TLZSSInfo.Mom + bx], si
  mov     [Offset TLZSSInfo.Mom + si], di
  jmp     @Splay9
@Splay6:
  mov     dx, [Offset TLZSSInfo.Left + di]
  mov     [Offset TLZSSInfo.Right + bx], dx
  xchg    bx, dx
  mov     [Offset TLZSSInfo.Mom + bx], dx
  mov     bx, [Offset TLZSSInfo.Right + di]
  mov     [Offset TLZSSInfo.Left + si], bx
  mov     [Offset TLZSSInfo.Mom + bx], si
  mov     bx, dx
  mov     [Offset TLZSSInfo.Left + di], bx
  mov     [Offset TLZSSInfo.Right + di], si
  mov     [Offset TLZSSInfo.Mom + si], di
  mov     [Offset TLZSSInfo.Mom + bx], di
  jmp     @Splay9
@Splay7:
  cmp     si, [Offset TLZSSInfo.Right + bx]
  jne     @Splay8
  mov     dx, [Offset TLZSSInfo.Left + si]
  mov     [Offset TLZSSInfo.Right + bx], dx
  xchg    bx, dx
  mov     [Offset TLZSSInfo.Mom + bx], dx
  mov     bx, [Offset TLZSSInfo.Left + di]
  mov     [Offset TLZSSInfo.Right + si], bx
  mov     [Offset TLZSSInfo.Mom + bx], si
  mov     bx, dx
  mov     [Offset TLZSSInfo.Left + si], bx
  mov     [Offset TLZSSInfo.Left + di], si
  mov     [Offset TLZSSInfo.Mom + bx], si
  mov     [Offset TLZSSInfo.Mom + si], di
  jmp     @Splay9
@Splay8:
  mov     dx, [Offset TLZSSInfo.Right + di]
  mov     [Offset TLZSSInfo.Left + bx], dx
  xchg    bx, dx
  mov     [Offset TLZSSInfo.Mom + bx], dx
  mov     bx, [Offset TLZSSInfo.Left + di]
  mov     [Offset TLZSSInfo.Right + si], bx
  mov     [Offset TLZSSInfo.Mom + bx], si
  mov     bx, dx
  mov     [Offset TLZSSInfo.Right + di], bx
  mov     [Offset TLZSSInfo.Left + di], si
  mov     [Offset TLZSSInfo.Mom + si], di
  mov     [Offset TLZSSInfo.Mom + bx], di
@Splay9:
  mov     si, cx
  cmp     si, NUL
  ja      @Splay10
  cmp     bx, [Offset TLZSSInfo.Left + si]
  jne     @Splay10
  mov     [Offset TLZSSInfo.Left + si], di
  jmp     @Splay11
@Splay10:   mov     [Offset TLZSSInfo.Right + si], di
@Splay11:   mov     [Offset TLZSSInfo.Mom + di], si
  jmp     @Splay1
@end:
end;

procedure InsertNode;assembler;
asm
  push    si
  push    dx
  push    cx
  push    bx
  mov     dx, 1
  xor     ax, ax
  mov     [TLZSSInfo.matchLen], ax
  mov     [TLZSSInfo.height], ax
  mov     al, byte ptr [Offset TLZSSInfo.TextBuf + di]
  shl     di, 1
  add     ax, N + 1
  shl     ax, 1
  mov     si, ax
  mov     ax, NUL
  mov     word ptr [Offset TLZSSInfo.Right + di], ax
  mov     word ptr [Offset TLZSSInfo.Left + di], ax
@Ins1:
  inc     [TLZSSInfo.height]
  cmp     dx, 0
  jl      @Ins3
  mov     ax, word ptr [Offset TLZSSInfo.Right + si]
  cmp     ax, NUL
  je      @Ins2
  mov     si, ax
  jmp     @Ins5
@Ins2:
  mov     word ptr [Offset TLZSSInfo.Right + si], di
  mov     word ptr [Offset TLZSSInfo.Mom + di], si
  jmp     @Ins11
@Ins3:
  mov     ax, word ptr [Offset TLZSSInfo.Left + si]
  cmp     ax, NUL
  je      @Ins4
  mov     si, ax
  jmp     @Ins5
@Ins4:
  mov     word ptr [Offset TLZSSInfo.Left + si], di
  mov     word ptr [Offset TLZSSInfo.Mom + di], si
  jmp     @Ins11
@Ins5:
  mov     bx, 1
  shr     si, 1
  shr     di, 1
  xor     ch, ch
  xor     dh, dh
@Ins6:
  mov     dl, byte ptr [Offset TLZSSInfo.Textbuf + di + bx]
  mov     cl, byte ptr [Offset TLZSSInfo.TextBuf + si + bx]
  sub     dx, cx
  jnz     @Ins7
  inc     bx
  cmp     bx, F
  jb      @Ins6
@Ins7:
  shl     si, 1
  shl     di, 1
  cmp     bx, [TLZSSInfo.matchLen]
  jbe     @Ins1
  mov     ax, si
  shr     ax, 1
  mov     [TLZSSInfo.matchPos], ax
  mov     [TLZSSInfo.matchLen], bx
  cmp     bx, F
  jb      @Ins1
@Ins8:
  mov     ax, word ptr [Offset TLZSSInfo.Mom + si]
  mov     word ptr [Offset TLZSSInfo.Mom + di], ax
  mov     bx, word ptr [Offset TLZSSInfo.Left + si]
  mov     word ptr [Offset TLZSSInfo.Left + di], bx
  mov     word ptr [Offset TLZSSInfo.Mom + bx], di
  mov     bx, word ptr [Offset TLZSSInfo.Right + si]
  mov     word ptr [Offset TLZSSInfo.Right + di], bx
  mov     word ptr [Offset TLZSSInfo.Mom + bx], di
  mov     bx, word ptr [Offset TLZSSInfo.Mom + si]
  cmp     si, word ptr [Offset TLZSSInfo.Right + bx]
  jne     @Ins9
  mov     word ptr [Offset TLZSSInfo.Right + bx], di
  jmp     @Ins10
@Ins9:
  mov     word ptr [Offset TLZSSInfo.Left + bx], di
@Ins10:
  mov     word ptr [Offset TLZSSInfo.Mom + si], NUL
@Ins11:
  cmp     [TLZSSInfo.height], 30
  jb      @Ins12
  call    Splay
@Ins12:     pop     bx
  pop     cx
  pop     dx
  pop     si
  shr     di, 1
end;

procedure DeleteNode;assembler;
asm
  push    di
  push    bx
  shl     si, 1
  cmp     word ptr [Offset TLZSSInfo.Mom + si], NUL
  je      @del7
  cmp     word ptr [Offset TLZSSInfo.Right + si], NUL
  je      @del8
  mov     di, word ptr [Offset TLZSSInfo.Left + si]
  cmp     di, NUL
  je      @del9
  mov     ax, word ptr [Offset TLZSSInfo.Right + di]
  cmp     ax, NUL
  je      @del2
@del1:
  mov     di, ax
  mov     ax, word ptr [Offset TLZSSInfo.Right + di]
  cmp     ax, NUL
  jne     @del1
  mov     bx, word ptr [Offset TLZSSInfo.Mom + di]
  mov     ax, word ptr [Offset TLZSSInfo.Left + di]
  mov     word ptr [Offset TLZSSInfo.Right + bx], ax
  xchg    ax, bx
  mov     word ptr [Offset TLZSSInfo.Mom + bx], ax
  mov     bx, word ptr [Offset TLZSSInfo.Left + si]
  mov     word ptr [Offset TLZSSInfo.Left + di], bx
  mov     word ptr [Offset TLZSSInfo.Mom + bx], di
@del2:
  mov     bx, word ptr [Offset TLZSSInfo.Right + si]
  mov     word ptr [Offset TLZSSInfo.Right + di], bx
  mov     word ptr [Offset TLZSSInfo.Mom + bx], di
@del3:
  mov     bx, word ptr [Offset TLZSSInfo.Mom + si]
  mov     word ptr [Offset TLZSSInfo.Mom + di], bx
  cmp     si, word ptr [Offset TLZSSInfo.Right + bx]
  jne     @del4
  mov     word ptr [Offset TLZSSInfo.Right + bx], di
  jmp     @del5
@del4:
  mov     word ptr [Offset TLZSSInfo.Left + bx], di
@del5:
  mov     word ptr [Offset TLZSSInfo.Mom + si], NUL
@del7:
  pop     bx
  pop     di
  shr     si, 1
  jmp     @end;
@del8:
  mov     di, word ptr [Offset TLZSSInfo.Left + si]
  jmp     @del3
@del9:
  mov     di, word ptr [Offset TLZSSInfo.Right + si]
  jmp     @del3
@end:
end;


procedure Encode;assembler;
asm
  push    ds
  lds     ax,lzi
  call    initTree
  xor     bx, bx
  mov     [Offset TLZSSInfo.CodeBuf + bx], bl
  mov     dx, 1
  mov     ch, dl
  xor     si, si
  mov     di, N - F
@Encode2:
  call    getc
  jc      @Encode3
  mov     byte ptr [Offset TLZSSInfo.TextBuf +di + bx], al
  inc     bx
  cmp     bx, F
  jb      @Encode2
@Encode3:
  or      bx, bx
  jne     @Encode4
  jmp     @Encode19
@Encode4:
  mov     cl, bl
  mov     bx, 1
  push    di
  sub     di, 1
@Encode5:
  call    InsertNode
  inc     bx
  dec     di
  cmp     bx, F
  jbe     @Encode5
  pop     di
  call    insertNode
@Encode6:
  mov     ax, [TLZSSInfo.matchLen]
  cmp     al, cl
  jbe     @Encode7
  mov     al, cl
  mov     [TLZSSInfo.matchLen], ax
@Encode7:
  cmp     al, THRESHOLD
  ja      @Encode8
  mov     [TLZSSInfo.matchLen], 1
  or      byte ptr [TLZSSInfo.codeBuf], ch
  mov     bx, dx
  mov     al, byte ptr [Offset TLZSSInfo.TextBuf + di]
  mov     byte ptr [Offset TLZSSInfo.CodeBuf + bx], al
  inc     dx
  jmp     @Encode9
@Encode8:
  mov     bx, dx
  mov     al, byte ptr [TLZSSInfo.matchPos]
  mov     byte ptr [Offset TLZSSInfo.Codebuf + bx], al
  inc     bx
  mov     al, byte ptr ([TLZSSInfo.matchPos] + 1)
  push    cx
  mov     cl, 4
  shl     al, cl
  pop     cx
  mov     ah, byte ptr TLZSSInfo.matchLen
  sub     ah, THRESHOLD + 1
  add     al, ah
  mov     byte ptr [Offset TLZSSInfo.Codebuf + bx], al
  inc     bx
  mov     dx, bx
@Encode9:
  shl     ch, 1
  jnz     @Encode11
  xor     bx, bx
@Encode10:
  mov     al, byte ptr [Offset TLZSSInfo.CodeBuf + bx]
  call    putc
  inc     bx
  cmp     bx, dx
  jb      @Encode10
  mov     dx, 1
  mov     ch, dl
  mov     byte ptr TLZSSInfo.codeBuf, dh
@Encode11:
  mov     bx, TLZSSInfo.matchLen
  mov     word ptr TLZSSInfo.lastLen, bx
  xor     bx, bx
@Encode12:
  call    getc
  jc      @Encode14
  push    ax
  call    deleteNode
  pop     ax
  mov     byte ptr [Offset TLZSSInfo.TextBuf + si], al
  cmp     si, F - 1
  jae     @Encode13
  mov     byte ptr [Offset TLZSSInfo.TextBuf + si + N], al
@Encode13:
  inc     si
  and     si, N - 1
  inc     di
  and     di, N - 1
  call    insertNode
  inc     bx
  cmp     bx, TLZSSInfo.lastLen
  jb      @Encode12
@Encode14:
  sub     word ptr TLZSSInfo.printCount, bx
  jnc     @Encode15
  mov     ax, TLZSSInfo.printPeriod
  mov     word ptr TLZSSInfo.printCount, ax
@Encode15:
  cmp     bx, TLZSSInfo.lastLen
  jae     @Encode16
  inc     bx
  call    deleteNode
  inc     si
  and     si, N - 1
  inc     di
  and     di, N - 1
  dec     cl
  jz      @Encode15
  call    insertNode
  jmp     @Encode15
@Encode16:
  cmp     cl, 0
  jbe     @Encode17
  jmp     @Encode6
@Encode17:
  cmp     dx, 1
  jb      @Encode19
  xor     bx, bx
@Encode18:
  mov     al, byte ptr [Offset TLZSSInfo.Codebuf + bx]
  call    putc
  inc     bx
  cmp     bx, dx
  jb      @Encode18
@Encode19:
  pop     ds
end;

procedure Decode;assembler;
asm
  push    ds
  lds     ax,lzi
  xor     dx, dx
  mov     di, N - F
@Decode2:
  shr     dx, 1
  or      dh, dh
  jnz     @Decode3
  call    getc
  jc      @Decode9
  mov     dh, 0ffh
  mov     dl, al
@Decode3:
  test    dx, 1
  jz      @Decode4
  call    getc
  jc      @Decode9
  mov     byte ptr [Offset TLZSSInfo.TextBuf + di], al
  inc     di
  and     di, N - 1
  call    putc
  jmp     @Decode2
@Decode4:
  call    getc
  jc      @Decode9
  mov     ch, al
  call    getc
  jc      @Decode9
  mov     bh, al
  mov     cl, 4
  shr     bh, cl
  mov     bl, ch
  mov     cl, al
  and     cl, 0fh
  add     cl, THRESHOLD
  inc     cl
@Decode5:
  and     bx, N - 1
  mov     al, byte ptr [Offset TLZSSInfo.TextBuf + bx]
  mov     byte ptr [Offset TLZSSInfo.TextBuf + di], al
  inc     di
  and     di, N - 1
  call    putc
  inc     bx
  dec     cl
  jnz     @Decode5
  jmp     @Decode2
@Decode9:
  pop     ds
end;

procedure LZSSInit;
begin
  lzi := MemAllocSeg(SizeOf(TLZSSInfo));
  ClearBuf(lzi^,SizeOf(lzi^));
  lzi^.InLZSSBufSize := LZSSBufSize;
  lzi^.LZSSInBufPtr  := LZSSBufSize;
end;

procedure LZSSDone;
begin
  FreeMem(lzi,SizeOf(TLZSSInfo));
  lzi := NIL;
end;

procedure LZSSCompress;
begin
  LZSSInit;
  encode;
  LZSSWriteProc;
  LZSSDone;
end;

procedure LZSSUnCompress;
begin
  LZSSInit;
  decode;
  LZSSWriteProc;
  LZSSDone;
end;

end.