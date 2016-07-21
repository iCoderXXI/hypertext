UNIT _TOOLS;

INTERFACE

uses _font,crt,dos,str_func,printer;

type
	PMEM=^TMEM;
	TMEM=ARRAY[0..65519] OF BYTE;

	_window=record
	x1,y1,xs,ys:byte;
	end;

	_table=record
	table:_window;
	area:_window;
	cx,cy:byte;
	end;

	PSel=^TSel;
	TSEL=ARRAY[1..999] OF BYTE;

	TSTR=STRING[78];

CONST TSTRASIZE=(65520 DIV SIZEOF(TSTR));

TYPE

	PSTRA=^TSTRA;
	TSTRA=ARRAY[1..TSTRASIZE] OF TSTR;

	PARTXT=RECORD
	NR:WORD;
	TEXT,ATTR:PSTRA;
	END;

	pscr=^tscr;
	tscr=array[0..3999] of byte;

procedure outcharxy(x,y,attr:byte;c:char);
procedure outstringxy(x,y,attr:byte;s:string);
procedure box(x,y,xs,ys,attr:byte);
procedure FillArea(x1,y1,xs,ys,attr:byte;c:char);
Procedure DrawTable(X1,Y1,XS,YS:BYTE);
function nwords(p:pmem; SIZE:word):Word;
function wpos(p:pmem; N,SIZE:word):Word;
FUNCTION WLEN(P:PMEM; N,SIZE:WORD):WORD;
FUNCTION NWORD(P:PMEM; N,SIZE:WORD):STRING;
PROCEDURE WRITEX_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
PROCEDURE WRITEC(P:PMEM; SIZE:WORD; XLEN:BYTE);
PROCEDURE WRITEL_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
PROCEDURE WRITEC_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
PROCEDURE WRITER_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
PROCEDURE WRITED_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
PROCEDURE WINDOW_(X1,Y1,XS,YS:BYTE);
FUNCTION SAYHEADER(P:PMEM; SIZE:WORD):BYTE;
PROCEDURE DISPLAY(PT:PARTXT; N:WORD; SCRY:BYTE; pnum:word; Max,cp:longint);
PROCEDURE DISPLAYp(PT:PARTXT; N:WORD; SCRY:BYTE; pnum:word; Max,cp:longint; st,nd:word);
FUNCTION SY:BYTE;
FUNCTION MY:BYTE;
FUNCTION PROGRESS(MAX,N:longint;XLEN:BYTE;C,C1:CHAR):STRING;
function percent(Max,N:LongInt):String;
procedure settime(x,y,attr:byte);
procedure killtime;
procedure saymess(s:string);
function alert(s,s1,s2:string):byte;
procedure savescr(scr:pscr);
procedure restscr(scr:pscr);
function isalt:boolean;
function isshift:boolean;
function pstring(s:string):boolean;

VAR MAXX,MINX:BYTE;

IMPLEMENTATION

Var	R:registers;
	tx,ty,ta:byte;
	timer:boolean;
	TimerVec : Procedure;
	tc:byte;
	h,m,s:word;
	st:string[8];

function isalt:boolean;
begin
isalt:=mem[seg0040:$17] and 8<>0;
end;

function isshift:boolean;
begin
isshift:=mem[seg0040:$17] and 3<>0;
end;

procedure savescr(scr:pscr);
begin
if scr=nil then exit;
move(ptr(segb800,0)^,scr^,4000);
end;

procedure restscr(scr:pscr);
begin
if scr=nil then exit;
move(scr^,ptr(segb800,0)^,4000);
end;

procedure saymess(s:string);
var wmin,wmax:word;
	scr:pscr;
	yy:byte;
	Max,Mix:Byte;
begin
wmin:=windmin;
wmax:=windmax;
Max:=MaxX;
Mix:=MinX;
new(scr);
savescr(scr);
hidecursor;
yy:=length(s) div 60+3+ord(length(s) mod 60>0);
window_(9,12-yy div 2-1,62,yy+2);
writeln;
writec(@s[1],length(s),60);
windmax:=wmax;windmin:=wmin;
{window(lo(wmin),hi(wmin),lo(wmax),hi(wmax));}
MAXX:=Max;
MINX:=Mix;
readkey;
restscr(scr);
dispose(scr);
end;

function alert(s,s1,s2:string):byte;
label finish;
var wmin,wmax:word;
	scr:pscr;
	yy:byte;
	Max,Mix:Byte;
	c:char;
    n:byte;
begin
wmin:=windmin;
wmax:=windmax;
Max:=MaxX;
Mix:=MinX;
new(scr);
savescr(scr);
hidecursor;
yy:=length(s) div 60+3+ord(length(s) mod 60>0);
window_(9,12-yy div 2-1,62,yy+4);
writeln;
writec(@s[1],length(s),60);
windmax:=wmax;windmin:=wmin;
{window(lo(wmin),hi(wmin),lo(wmax),hi(wmax));}
MAXX:=Max;
MINX:=Mix;
n:=1;
if length(s1)>10 then s1:=left_(s1,10);
if length(s2)>10 then s2:=left_(s2,10);
if n=1 then textattr:=mselect+mback shl 4 else textattr:=select+back shl 4;
outstringxy(30,12+yy div 2-1,textattr,s1);
if n=2 then textattr:=mselect+mback shl 4 else textattr:=select+back shl 4;
outstringxy(45,12+yy div 2-1,textattr,s2);
repeat
c:=readkey;
case c of
#9,#15,#075,#077: n:=3-n;
#27:begin n:=2;goto finish;end;
#13:goto finish;
end;
if n=1 then textattr:=mselect+mback shl 4 else textattr:=select+back shl 4;
outstringxy(30,12+yy div 2-1,textattr,s1);
if n=2 then textattr:=mselect+mback shl 4 else textattr:=select+back shl 4;
outstringxy(45,12+yy div 2-1,textattr,s2);
until 1<>1;
finish:
restscr(scr);
dispose(scr);
alert:=n;
end;

procedure updatetime;
begin
  st:=right_('00'+alltrim(str_(h)),2)+':'+
	  right_('00'+alltrim(str_(m)),2)+':'+
	  right_('00'+alltrim(str_(s)),2);
  outstringxy(tx,ty,ta,st);
end;

FUNCTION SY:BYTE;
BEGIN
SY:=WINDMIN SHR 8-1;
END;

FUNCTION MY:BYTE;
BEGIN
MY:=WINDMAX SHR 8-SY+1;
END;

procedure outstringxy(x,y,attr:byte;s:string);
var i:byte;
begin
for i:=1 to length(s)do
begin
if x+i>79 then exit;
outcharxy(x+i-1,y,attr,s[i]);
end;
end;

PROCEDURE WINDOW_(X1,Y1,XS,YS:BYTE);
BEGIN
DrawTable(X1,Y1,XS,YS);
WINDOW(X1+2,Y1+2,X1+XS-1,Y1+YS-1);
TEXTBACKGROUND(BACK);
TEXTCOLOR(CFRAME);
{CLRSCR;}
MAXX:=XS-2-2;
MINX:=X1+1+1;
END;

procedure outcharxy(x,y,attr:byte;c:char);
begin
if not ((x<=79) and (y<=24)) then exit;
mem[SEGb800:x*2+y*160]:=ord(c);
mem[SEGb800:x*2+y*160+1]:=attr;
end;

procedure box(x,y,xs,ys,attr:byte);
var i:byte;
begin
for i:=1 to xs-2 do outcharxy(x+i,y,attr,#1);
for i:=1 to ys-2 do outcharxy(x+xs-1,y+i,attr,#3);
for i:=1 to xs-2 do outcharxy(x+i,y+ys-1,attr,#5);
for i:=1 to ys-2 do outcharxy(x,y+i,attr,#7);
outcharxy(x,y,attr,#0);
outcharxy(x+xs-1,y,attr,#2);
outcharxy(x+xs-1,y+ys-1,attr,#4);
outcharxy(x,y+ys-1,attr,#6);
end;

procedure FillArea(x1,y1,xs,ys,attr:byte;c:char);
var i,j:byte;
	S:STRING;
begin
S:=CHAR_REPL(XS*2,C);
for i:=1 to xs do S[I*2]:=CHR(ATTR);
for j:=y1 to y1+ys-1 do MOVE(S[1],PTR(SEGB800,J*160+X1*2)^,XS*2);
end;

Procedure DrawTable(X1,Y1,XS,YS:BYTE);
Begin
FillArea(x1+1,y1+1,xs-2,ys-2,CFRAME+BACK*16,#32);
Box(x1,y1,xs,ys,CFRAME+BACK*16);
TEXTBACKGROUND(BACK);
End;

function nwords(p:pmem; SIZE:word):Word;
Var i,n:Word;
	L:byte;
Begin
nwords:=0;
if p=nil then exit;
l:=32;n:=0;
for i:=0 to SIZE-1 do
begin
if (l=32) and (p^[i]<>32) then
begin inc(n);l:=0;end;
if p^[i]=32 then l:=32;
end;
nwords:=n;
End;

function wpos(p:pmem; N,SIZE:word):Word;
Var i,ps:Word;
	L:byte;
Begin
wpos:=0;
if p=nil then BEGIN {WRITE(#7);}exit;END;
l:=32;ps:=0;I:=0;
WHILE I<SIZE DO begin
if (l=32) and (p^[i]<>32) then
begin inc(ps);L:=0;if ps=n then BEGIN wpos:=i;EXIT;END;end;
if p^[i]=32 then l:=32;
INC(I);
end;
End;

FUNCTION WLEN(P:PMEM; N,SIZE:WORD):WORD;
VAR I,J:WORD;
BEGIN
WLEN:=0;
IF P=NIL THEN BEGIN {WRITE(#7);}EXIT;END;
I:=WPOS(P,N,SIZE);J:=I;
IF N>I+1 THEN BEGIN {write(#7);}EXIT;END;
WHILE I<SIZE DO BEGIN
IF (P^[I]=32) OR (I=SIZE) THEN BEGIN WLEN:=I-J;EXIT;END;
INC(I);
END;
WLEN:=I-J;
END;

FUNCTION NWORD(P:PMEM; N,SIZE:WORD):STRING;
VAR I,J,K:WORD;
	S:STRING;
BEGIN
NWORD:='';
IF P=NIL THEN EXIT;
J:=WLEN(P,N,SIZE);IF J>255 THEN J:=255;
K:=WPOS(P,N,SIZE);
S:='';
FOR I:=1 TO J DO S:=S+CHR(P^[I+K-1]);
NWORD:=S;
END;

PROCEDURE WRITEX_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
VAR J:WORD;
	s:string;
	L,K,TI:BYTE;

PROCEDURE INSSP;
VAR K:BYTE;
BEGIN
  WITH PT DO BEGIN
  L:=ORD(TEXT^[PT.NR,1]);
  IF L=32 THEN BEGIN
  ATTR^[NR]:=RIGHT_(ATTR^[NR],LENGTH(ATTR^[NR])-4);
  END;
  TEXT^[NR]:=ALLTRIM(TEXT^[NR]);
  IF LENGTH(TEXT^[NR])<LENGTH(ATTR^[NR]) THEN ATTR^[NR]:=LEFT_(ATTR^[NR],LENGTH(TEXT^[NR]));
  TI:=XLEN-LENGTH(TEXT^[NR])-(ORD(L=32)*4);
  insnsp(TEXT^[NR],ATTR^[NR],TI);
  IF L=32 THEN BEGIN
  TEXT^[NR]:='    '+TEXT^[NR];
  ATTR^[NR]:=CHAR_REPL(4,CHR(NORM+BACK SHL 4))+ATTR^[NR];
  END;
  FOR K:=1 TO LENGTH(PT.ATTR^[PT.NR]) DO
  IF PT.ATTR^[PT.NR,K]=#32 THEN PT.ATTR^[PT.NR,K]:=CHR(NORM+BACK SHL 4);
  END;
END;

BEGIN
INC(PT.NR);
IF (P=NIL)or (XLEN<4)OR (PT.TEXT=NIL)OR (PT.ATTR=NIL) THEN BEGIN WRITE(#7);EXIT;END;
PT.TEXT^[PT.NR]:='    ';
PT.attr^[PT.NR]:=CHAR_REPL(4,CHR(NORM+BACK SHL 4));
L:=4;K:=0;
FOR J:=1 TO NWORDS(P,SIZE) DO
BEGIN
L:=LENGTH(PT.TEXT^[PT.NR]);
IF INTEGER(XLEN)-L<WLEN(P,J,SIZE) THEN
BEGIN

IF SIZE>XLEN THEN INSSP;

K:=0;
L:=1;
IF PT.NR=TSTRASIZE THEN BEGIN WRITE(#7);EXIT;END;
INC(PT.NR);
PT.TEXT^[PT.NR]:='';
PT.attr^[PT.NR]:='';
END;
PT.TEXT^[PT.NR]:=PT.TEXT^[PT.NR]+NWORD(P,J,SIZE)+' ';
PT.ATTR^[PT.NR]:=PT.ATTR^[PT.NR]+CHAR_REPL(WLEN(P,J,SIZE)+1,CHR(SEL^[J]));
L:=L+LENGTH(NWORD(P,J,SIZE)+' ');
INC(K);
END;
END;


PROCEDURE WRITEC_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
VAR J:WORD;
	s:string;
	L,K,TI:BYTE;
BEGIN
INC(PT.NR);
IF (P=NIL)or (XLEN<4)OR (PT.TEXT=NIL)OR (PT.ATTR=NIL) THEN BEGIN WRITE(#7);EXIT;END;
PT.TEXT^[PT.NR]:='';
PT.attr^[PT.NR]:='';
L:=0;K:=0;
FOR J:=1 TO NWORDS(P,SIZE) DO
BEGIN
L:=LENGTH(PT.TEXT^[PT.NR]);
IF INTEGER(XLEN)-L<WLEN(P,J,SIZE) THEN
BEGIN

PT.TEXT^[PT.NR]:=LEFT_(PT.TEXT^[PT.NR],LENGTH(PT.TEXT^[PT.NR])-1);
PT.ATTR^[PT.NR]:=LEFT_(PT.ATTR^[PT.NR],LENGTH(PT.ATTR^[PT.NR])-1);
PT.TEXT^[PT.NR]:=CHAR_REPL(XLEN DIV 2-LENGTH(PT.TEXT^[PT.NR]) DIV 2,#32)+PT.TEXT^[PT.NR];
PT.ATTR^[PT.NR]:=CHAR_REPL(XLEN DIV 2-LENGTH(PT.ATTR^[PT.NR]) DIV 2,CHR(NORM+BACK SHL 4))+PT.ATTR^[PT.NR];

K:=0;
L:=1;
IF PT.NR=TSTRASIZE THEN BEGIN WRITE(#7);EXIT;END;
INC(PT.NR);
PT.TEXT^[PT.NR]:='';
PT.attr^[PT.NR]:='';
END;
PT.TEXT^[PT.NR]:=PT.TEXT^[PT.NR]+NWORD(P,J,SIZE)+' ';
PT.ATTR^[PT.NR]:=PT.ATTR^[PT.NR]+CHAR_REPL(WLEN(P,J,SIZE)+1,CHR(SEL^[J]));
L:=L+LENGTH(NWORD(P,J,SIZE)+' ');
INC(K);
END;
PT.TEXT^[PT.NR]:=LEFT_(PT.TEXT^[PT.NR],LENGTH(PT.TEXT^[PT.NR])-1);
PT.ATTR^[PT.NR]:=LEFT_(PT.ATTR^[PT.NR],LENGTH(PT.ATTR^[PT.NR])-1);
PT.TEXT^[PT.NR]:=CHAR_REPL(XLEN DIV 2-LENGTH(PT.TEXT^[PT.NR]) DIV 2,#32)+PT.TEXT^[PT.NR];
PT.ATTR^[PT.NR]:=CHAR_REPL(XLEN DIV 2-LENGTH(PT.ATTR^[PT.NR]) DIV 2,CHR(NORM+BACK SHL 4))+PT.ATTR^[PT.NR];
END;

PROCEDURE WRITER_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
VAR J:WORD;
	s:string;
	L,K,TI:BYTE;

BEGIN
INC(PT.NR);
IF (P=NIL)or (XLEN<4)OR (PT.TEXT=NIL)OR (PT.ATTR=NIL) THEN BEGIN WRITE(#7);EXIT;END;
PT.TEXT^[PT.NR]:='';
PT.attr^[PT.NR]:='';
L:=0;K:=0;
FOR J:=1 TO NWORDS(P,SIZE) DO
BEGIN
L:=LENGTH(PT.TEXT^[PT.NR]);
IF INTEGER(XLEN)-L<WLEN(P,J,SIZE) THEN
BEGIN

PT.TEXT^[PT.NR]:=LEFT_(PT.TEXT^[PT.NR],LENGTH(PT.TEXT^[PT.NR])-1);
PT.ATTR^[PT.NR]:=LEFT_(PT.ATTR^[PT.NR],LENGTH(PT.ATTR^[PT.NR])-1);
PT.TEXT^[PT.NR]:=CHAR_REPL(XLEN-LENGTH(PT.TEXT^[PT.NR]),#32)+PT.TEXT^[PT.NR];
PT.ATTR^[PT.NR]:=CHAR_REPL(XLEN-LENGTH(PT.ATTR^[PT.NR]),CHR(NORM+BACK SHL 4))+PT.ATTR^[PT.NR];

K:=0;
L:=1;
IF PT.NR=TSTRASIZE THEN BEGIN WRITE(#7);EXIT;END;
INC(PT.NR);
PT.TEXT^[PT.NR]:='';
PT.attr^[PT.NR]:='';
END;
PT.TEXT^[PT.NR]:=PT.TEXT^[PT.NR]+NWORD(P,J,SIZE)+' ';
PT.ATTR^[PT.NR]:=PT.ATTR^[PT.NR]+CHAR_REPL(WLEN(P,J,SIZE)+1,CHR(SEL^[J]));
L:=L+LENGTH(NWORD(P,J,SIZE)+' ');
INC(K);
END;
PT.TEXT^[PT.NR]:=LEFT_(PT.TEXT^[PT.NR],LENGTH(PT.TEXT^[PT.NR])-1);
PT.ATTR^[PT.NR]:=LEFT_(PT.ATTR^[PT.NR],LENGTH(PT.ATTR^[PT.NR])-1);
PT.TEXT^[PT.NR]:=CHAR_REPL(XLEN-LENGTH(PT.TEXT^[PT.NR]),#32)+PT.TEXT^[PT.NR];
PT.ATTR^[PT.NR]:=CHAR_REPL(XLEN-LENGTH(PT.ATTR^[PT.NR]),CHR(NORM+BACK SHL 4))+PT.ATTR^[PT.NR];
END;

PROCEDURE WRITEL_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
VAR J:WORD;
	s:string;
	L,K,TI:BYTE;

BEGIN
INC(PT.NR);
IF (P=NIL)or (XLEN<4)OR (PT.TEXT=NIL)OR (PT.ATTR=NIL) THEN BEGIN WRITE(#7);EXIT;END;
PT.TEXT^[PT.NR]:='';
PT.attr^[PT.NR]:='';
L:=0;K:=0;
FOR J:=1 TO NWORDS(P,SIZE) DO
BEGIN
L:=LENGTH(PT.TEXT^[PT.NR]);
IF INTEGER(XLEN)-L<WLEN(P,J,SIZE) THEN
BEGIN

PT.TEXT^[PT.NR]:=LEFT_(PT.TEXT^[PT.NR],LENGTH(PT.TEXT^[PT.NR])-1);
PT.ATTR^[PT.NR]:=LEFT_(PT.ATTR^[PT.NR],LENGTH(PT.ATTR^[PT.NR])-1);
PT.TEXT^[PT.NR]:=PT.TEXT^[PT.NR]+CHAR_REPL(XLEN-LENGTH(PT.TEXT^[PT.NR]),#32);
PT.ATTR^[PT.NR]:=PT.ATTR^[PT.NR]+CHAR_REPL(XLEN-LENGTH(PT.ATTR^[PT.NR]),CHR(NORM+BACK SHL 4));

K:=0;
L:=1;
IF PT.NR=TSTRASIZE THEN BEGIN WRITE(#7);EXIT;END;
INC(PT.NR);
PT.TEXT^[PT.NR]:='';
PT.attr^[PT.NR]:='';
END;
PT.TEXT^[PT.NR]:=PT.TEXT^[PT.NR]+NWORD(P,J,SIZE)+' ';
PT.ATTR^[PT.NR]:=PT.ATTR^[PT.NR]+CHAR_REPL(WLEN(P,J,SIZE)+1,CHR(SEL^[J]));
L:=L+LENGTH(NWORD(P,J,SIZE)+' ');
INC(K);
END;
PT.TEXT^[PT.NR]:=LEFT_(PT.TEXT^[PT.NR],LENGTH(PT.TEXT^[PT.NR])-1);
PT.ATTR^[PT.NR]:=LEFT_(PT.ATTR^[PT.NR],LENGTH(PT.ATTR^[PT.NR])-1);
PT.TEXT^[PT.NR]:=PT.TEXT^[PT.NR]+CHAR_REPL(XLEN-LENGTH(PT.TEXT^[PT.NR]),#32);
PT.ATTR^[PT.NR]:=PT.ATTR^[PT.NR]+CHAR_REPL(XLEN-LENGTH(PT.ATTR^[PT.NR]),CHR(NORM+BACK SHL 4));
END;

PROCEDURE WRITED_(P:PMEM; SIZE:WORD; XLEN:BYTE; SEL:psel;VAR PT:PARTXT);
VAR J,K:WORD;
BEGIN
INC(PT.NR);
IF (P=NIL)or (XLEN<4)OR (PT.TEXT=NIL)OR (PT.ATTR=NIL) THEN BEGIN WRITE(#7);EXIT;END;
PT.TEXT^[PT.NR,0]:=CHR(XLEN);
PT.ATTR^[PT.NR,0]:=CHR(XLEN);
K:=XLEN;
IF K>SIZE THEN K:=SIZE;
MOVE(P^[0],PT.TEXT^[PT.NR,1],K);
FOR J:=K+1 TO XLEN DO PT.TEXT^[PT.NR,J]:=#32;
FOR J:=1 TO XLEN DO PT.attr^[PT.NR,J]:=CHR(NORM+BACK SHL 4);
for j:=1 to _words(PT.TEXT^[PT.NR]) do
_Change(PT.Attr^[pt.nr],Chr(sel^[j]),_Pos(PT.Text^[pt.nr],j),_wlen(PT.Text^[pt.nr],j));

END;

PROCEDURE WRITEC(P:PMEM; SIZE:WORD; XLEN:BYTE);
VAR I,J,L,K:WORD;
	s:string;
BEGIN
IF (P=NIL) or (xlen<4) THEN EXIT;
L:=1;J:=1;
WHILE (L<=XLEN) and (J<=NWORDS(p,size))DO BEGIN
L:=L+WLEN(P,J,SIZE)+1;INC(J);
END;
DEC(L);
if l>xlen then begin dec(j);l:=l-WLEN(P,J,SIZE)-1;end;
dec(j);
s:='';
FOR I:=1 TO J DO s:=s+NWORD(P,I,SIZE)+' ';
s:=ALLTRIM(s);
GOTOXY(XLEN DIV 2-LENGTH(S) DIV 2+1+(xlen+1+length(s)) mod 2,WHEREY);
WRITE(S);
IF LENGTH(S)<XLEN THEN WRITELN;
INC(J);
WHILE NOT (J>NWORDS(p,size)) DO BEGIN
L:=0;
K:=J;
WHILE (L<=XLEN) and NOT (J>NWORDS(p,size))DO BEGIN
L:=L+WLEN(P,J,SIZE)+1;INC(J);
END;
DEC(L);
if l>xlen then begin dec(j);l:=l-WLEN(P,J,SIZE)-1;end;
dec(j);
s:='';
FOR I:=K TO J DO s:=s+NWORD(P,I,SIZE)+' ';
s:=ALLTRIM(s);
GOTOXY(XLEN DIV 2-LENGTH(S) DIV 2+2,WHEREY);
WRITE(S);
IF LENGTH(S)<=XLEN THEN WRITELN;
INC(J);
END;
END;

FUNCTION SAYHEADER(P:PMEM; SIZE:WORD):BYTE;
BEGIN
TEXTBACKGROUND(BACK);
TEXTCOLOR(CHEADER);
CLRSCR;
WriteC(P,SIZE,MAXX);
TEXTCOLOR(CFRAME);
WRITE(CHAR_REPL(MAXX+2,'─'));
SAYHEADER:=WHEREY;
END;

PROCEDURE DISPLAY(PT:PARTXT; N:WORD; SCRY:BYTE; pnum:word; Max,cp:longint);
VAR I,J,L,A:BYTE;
	S:STRING;
BEGIN
IF (PT.TEXT=NIL) OR (PT.ATTR=NIL) THEN EXIT;
A:=MY;
IF A>PT.NR THEN A:=PT.NR;
FOR J:=1 TO A DO BEGIN
L:=LENGTH(PT.TEXT^[N+J-1]);
IF L>MAXX THEN L:=MAXX;
IF N+J<=PT.NR+1 THEN
BEGIN
IF L<MAXX THEN FILLAREA(MINX+L,SY+J,MAXX-L,1,NORM+BACK SHL 4,#32);
{S:='';}
FOR I:=1 TO L DO
begin
outcharxy(MINX-1,SY+J,SELECT+BACK SHL 4,' ');
outcharxy(MINX+MAXX,SY+J,SELECT+BACK SHL 4,' ');
outcharxy(I-1+MINX,SY+J,ORD(PT.attr^[N+J-1,I]),PT.TEXT^[N+J-1,I]);
end;
IF J=SCRY THEN BEGIN
outcharxy(MINX-1,SY+J,SELECT+BACK SHL 4,'>');
outcharxy(MINX+MAXX,SY+J,SELECT+BACK SHL 4,'<');
END;
END;
END;
outstringxy(minx,sy+my+1,cframe+back shl 4,#4#32+alltrim(str_(pnum))+
' ('+alltrim(percent(MAX,cp))+')'+#32#6#5#5#5#5);
outstringxy(minx+maxx-14,sy+my+1,cframe+back shl 4,#4#32+'F1 - Помощ'+#32#6);
{outstringxy(tx-2,ty,SELECT+BACK SHL 4,#2#32);
outstringxy(tx+8,ty,SELECT+BACK SHL 4,#32#0);
updatetime;}
END;

PROCEDURE DISPLAYP(PT:PARTXT; N:WORD; SCRY:BYTE; pnum:word; Max,cp:longint; st,nd:word);
VAR I,J,L,A,c:BYTE;
	S:STRING;
BEGIN
IF (PT.TEXT=NIL) OR (PT.ATTR=NIL) THEN EXIT;
A:=MY;
IF A>PT.NR THEN A:=PT.NR;
FOR J:=1 TO A DO BEGIN
L:=LENGTH(PT.TEXT^[N+J-1]);
IF L>MAXX THEN L:=MAXX;
IF N+J<=PT.NR+1 THEN
BEGIN
{S:='';}
if (N+J-1>=st) and (n+j-1<=nd) then c:=mselect+mback shl 4 else c:=select+back shl 4;
IF L<MAXX THEN FILLAREA(MINX+L,SY+J,MAXX-L,1,c,#32);
FOR I:=1 TO L DO
begin
outcharxy(MINX-1,SY+J,SELECT+BACK SHL 4,' ');
outcharxy(MINX+MAXX,SY+J,SELECT+BACK SHL 4,' ');
outcharxy(I-1+MINX,SY+J,c,PT.TEXT^[N+J-1,I]);
end;
IF J=SCRY THEN BEGIN
outcharxy(MINX-1,SY+J,SELECT+BACK SHL 4,'>');
outcharxy(MINX+MAXX,SY+J,SELECT+BACK SHL 4,'<');
END;
END;
END;
outstringxy(minx,sy+my+1,cframe+back shl 4,#4#32+alltrim(str_(pnum))+
' ('+alltrim(percent(MAX,cp))+')'+#32#6#5#5#5#5);
outstringxy(minx+maxx-14,sy+my+1,cframe+back shl 4,#4#32+'F1 - Помощ'+#32#6);
{outstringxy(tx-2,ty,SELECT+BACK SHL 4,#2#32);
outstringxy(tx+8,ty,SELECT+BACK SHL 4,#32#0);
updatetime;}
END;

function percent(Max,N:LongInt):String;
begin
if max=0 then max:=1;
percent:=' '+ALLTRIM(STR_(ROUND(N/MAX*100)))+' % ';
end;

FUNCTION PROGRESS(MAX,N:longint;XLEN:BYTE;C,C1:CHAR):STRING;
VAR S,SS:STRING;
	PC:REAL;
	I,P:BYTE;
BEGIN
IF MAX=0 THEN EXIT;
IF MAX=0 THEN MAX:=1;
PC:=XLEN/MAX;
S:=CHAR_REPL(ROUND(PC*N),C);
S:=S+CHAR_REPL(XLEN-LENGTH(S),C1);
SS:=percent(max,n);
P:=LENGTH(S) DIV 2-LENGTH(SS) DIV 2;
FOR I:=1 TO LENGTH(SS) DO S[P+I]:=SS[I];
PROGRESS:=S;
END;

{$F+}
procedure ShowTime; interrupt;
begin
  inc(tc);
  if tc=18 then begin
  tc:=0;
  if s+1>59 then
  begin
  s:=0;
  if m+1>59 then
  begin
  h:=(h+1) mod 24;
  m:=0;
  end else inc(m);end else inc(s);
  st:=right_('00'+alltrim(str_(h)),2)+':'+
	  right_('00'+alltrim(str_(m)),2)+':'+
	  right_('00'+alltrim(str_(s)),2);
  outstringxy(tx,ty,ta,st);
  end;
  inline ($9C);
  TimerVec;
end;
{$F-}

procedure settime(x,y,attr:byte);
var t:word;
begin
if timer then exit;
tx:=x;ty:=y;ta:=attr;
  tc:=0;
  gettime(h,m,s,t);
  timer:=true;
  GetIntVec($1C,@TimerVec);
  SetIntVec($1C,Addr(ShowTime));
end;

procedure killtime;
begin
if not timer then exit;
  SetIntVec($1C,@TimerVec);
end;

function pstring(s:string):boolean;
label aaa;
var i:byte;
begin
OUTSTRINGXY(60,13,SELECT+BACK SHL 4,' ESC-Бекор килиш ');
pstring:=false;
s:=s+#13#10;
for i:=1 to length(s) do
begin
aaa:
{$I-}
write(lst,s[i]);
{$I+}
if keypressed then if readkey=#27 then begin if ioresult<>0 then;exit;end;
if ioresult<>0 then begin
OUTSTRINGXY(4,11,12+BACK SHL 4,'Принтер тайёр эмас... ESC-Бекор килиш, бошка исталган тугма-давом эттириш');
IF READKEY=#27 THEN EXIT ELSE
BEGIN
OUTSTRINGXY(11,11,CFRAME+BACK SHL 4,CHAR_REPL(60,#1));
goto aaa;END;end;
end;
pstring:=true;
end;

begin
timer:=false;
MAXX:=80;
end.