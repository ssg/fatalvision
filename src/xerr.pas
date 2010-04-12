{
Name    : X/Err 1.00b
Purpose : Runtime Error Handler
Coder   : SSG
Date    : 22nd Jan 95
}

unit XErr;

interface

procedure InitXErr;

implementation

uses

  Debris,Objects,XStr;

var
  ErrorStr    : PChar;
  OldExit:Pointer;

type

  hmhm = string[9];
  s2   = string[2];
  s4   = string[4];

const

  Erol : array[0..16] of PChar = (
       'Division by zero',
       'Range check error',
       'Stack overflow',
       'Heap overflow',
       'Invalid pointer operation',
       'FPU overflow',
       'FPU underflow',
       'Invalid FPU operation',
       'Illegal overlay call',
       'Overlay read error',
       'Object init fail',
       'Abstract call',
       'Registering error',
       'Coll index out of range',
       'Coll overflow',
       'Math overflow',
       'Protection fault');


procedure ExtendedErrorHandler;far;

  function Hexen:hmhm;
  begin
    Hexen := HexW(LongRec(ErrorAddr).Hi)+':'+HexW(word(ErrorAddr));
  end;

begin
  if (ExitCode > 1) and (ExitCode <> $AD) then begin
    case ExitCode of
       200..216 : ErrorStr := Erol[ExitCode-200];
      else ErrorStr := 'Alakasiz error';
    end; {case}
    asm
      mov ax,3
      int 10h
    end;
    writeln('Uh-oh'#13#10,ErrorStr,' at '+Hexen);
    ExitCode := 0;
    ErrorAddr := NIL;
  end;
  ExitProc := OldExit;
end;

procedure InitXErr;
begin
  OldExit     := ExitProc;
  ExitProc    := @ExtendedErrorHandler;
end;

end.