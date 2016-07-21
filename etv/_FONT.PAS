Unit _font;

interface

Uses dos,CRT;

VAR BACK,NORM,SELECT,COMMENT,SHADOW,MSELECT,MBACK,CHEADER,CFRAME:BYTE;

PROCEDURE LOADATTR;
PROCEDURE SAVEATTR;
PROCEDURE SETBLINK(BLINK:BOOLEAN);

implementation

{$I TWIN.PAS}

var r:registers;

procedure setfont;
begin
with r do begin
es:=seg(font);
bp:=ofs(font);
cx:=256;
dx:=0;
bl:=0;
bh:=16;
ah:=$11;
al:=$10;
intr($10,r);
end;
end;

procedure set8x16;assembler;
asm
  cli
  mov dx,3C4h
  mov ax,0100h

  out dx,al
  out dx,ax
  mov al,1

  out dx,al
  inc dx
  in al,dx
  dec dx
  or al,1
  mov ah,al
  mov al,1
  out dx,ax
  mov ax,0300h

  out dx,ax
  sti
end;

PROCEDURE LOADATTR;
VAR F:FILE;
BEGIN
ASSIGN(F,'ETVIEW.INI');
{$i-}
RESET(F,1);
IF IORESULT<>0 THEN EXIT;
BLOCKREAD(F,BACK,9);
IF IORESULT<>0 THEN BEGIN CLOSE(F);EXIT;END;
{$i+}
CLOSE(F);
END;

PROCEDURE SAVEATTR;
VAR F:FILE;
BEGIN
ASSIGN(F,'ETVIEW.INI');
{$i-}
REWRITE(F,1);
BLOCKWRITE(F,BACK,9);
{$i+}
CLOSE(F);
END;

PROCEDURE SETBLINK(BLINK:BOOLEAN);
BEGIN
WITH R DO BEGIN
AH:=$10;
AL:=3;
BL:=ORD(BLINK);
INTR($10,R);
END;
END;

begin
BACK:=1;
NORM:=7;
SELECT:=15;
COMMENT:=14;
SHADOW:=8;
MSELECT:=14;
MBACK:=3;
CHEADER:=10;
CFRAME:=15;
r.ax:=3;
intr($10,r);
set8x16;
setfont;
DIRECTVIDEO:=TRUE;
SETBLINK(FALSE);
NORMVIDEO;
LOADATTR;
end.
