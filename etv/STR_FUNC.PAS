unit str_func;
interface
uses dos,crt;

const numbers_str:array[0..31] of string=
('Zero','One','Two','Three','Four','Five','Six','Seven','Eight','Nine','Ten',
'Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen',
'Eighteen','Ninteen','Twenty','Thurty','Fourty','Fifty','Sixty','Seventy',
'Eighty','Ninety','Fundreed','Thousand','Billion','Trilion');

TYPE 	PMEM=^TMEM;
		TMEM=ARRAY[0..65519] OF BYTE;

procedure hidecursor;
procedure showcursor;
procedure halfcursor;
procedure fullcursor;
function char_repl(num:byte;ch:char):string;
function ltrim(s:string):string;
function rtrim(s:string):string;
function alltrim(s:string):string;
function str_(n:longint):string;
function val_(s:string):integer;
function left_(s:string;n:byte):string;
function right_(s:string;n:byte):string;
FUNCTION UPPER(S:STRING):STRING;
function pos_(s,s1:string):byte;
function tobin(n:byte):string;
function tohex(n:byte):string;
function date_:string;
function time_:string;
FUNCTION PUTSPACES(SS:STRING):STRING;
FUNCTION DELEXTRASP(SS:STRING):STRING;
FUNCTION DOSTOWIN(S:STRING):STRING;
PROCEDURE DOSTOWINP(P:PMEM;SIZE:WORD);
PROCEDURE insnsp(VAR s,S1:string;n:INTEGER);
function _pos(s:string; N:byte):byte;
function _words(s:string):byte;
function _wlen(s:string; N:Byte):byte;
function _nwordslen(s:string;st,n:byte):byte;
procedure _change(var s:string;s1:string;n,l:byte);
function readnchars(nx{,n}:byte;s:string):string;
function readncharsx(nx{,n}:byte;s:string):string;
function codepass(s:string):word;
function hexbyte(n:byte):string;
function hexword(n:word):string;
procedure cleantab(var s:string);
implementation

Var r:registers;

function hexbyte(n:byte):string;
const let:array[0..15] of char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
begin
hexbyte:=let[n shr 4]+let[n and $F];
end;

function hexword(n:word):string;
begin
hexword:=hexbyte(hi(n))+hexbyte(lo(n));
end;

function codepass(s:string):word;
var i:byte;
	n:word;
begin
n:=0;
for i:=1 to length(s) do n:=n+(ord(s[i])*i);
n:=n*sqr(length(s));
end;

procedure hidecursor;
begin
with r do begin
ah:=1;
ch:=$20;
intr($10,r);
end;
end;

procedure showcursor;
begin
with r do begin
ah:=1;
cl:=$1f;
ch:=$1f;
intr($10,r);
end;
end;

procedure halfcursor;
begin
with r do begin
ah:=1;
cl:=$1f;
ch:=$10;
intr($10,r);
end;
end;

procedure fullcursor;
begin
with r do begin
ah:=1;
cl:=$1f;
ch:=$0;
intr($10,r);
end;
end;

function readnchars(nx{,n}:byte;s:string):string;
var c:char;
	ss:string;
	x,y,cx:byte;
	ShouldInsert:Boolean;

procedure showit;
begin
gotoxy(x,y);write(left_(ss+char_repl(nx,#32),nx));
if cx>nx then gotoxy(x+nx-1,y) else gotoxy(x+cx-1,y);{cx:=nx;}
end;

begin
ss:=s;
if length(ss)>nx then ss:=left_(ss,nx);
if ss='' then ss:=#32;
x:=wherex;y:=wherey;cx:=length(ss)+1;
if nx>nx then nx:=nx;
ShouldInsert:=true;
if Shouldinsert then showcursor else fullcursor;
repeat
showit;
c:=readkey;
case c of
#27:begin readnchars:=s;exit;end;
#13:begin readnchars:=ss;exit;end;
#0: BEGIN C:=READKEY;
CASE C OF
#75:If cx>1 then dec(cx);
#77:If cx<=nx then inc(cx);
{DEL}
#83:if cx-1<=length(ss) then begin delete(ss,cx,1);
if cx>length(ss)+1 then dec(cx);end;
{INS}
#82:begin
ShouldInsert:=Not ShouldInsert;
if Shouldinsert then showcursor else fullcursor;
End;
END;
END;
' '..'ÿ': if shouldinsert then begin
if length(ss)<nx then begin
if cx>length(ss) then ss:=ss+c else insert(c,ss,cx); inc(cx); end;
end else
begin
if cx<=nx then begin
if cx>length(ss) then ss:=ss+c else ss[cx]:=c; inc(cx); end;
end;
{BackSpace}
#8:if cx-1>0 then begin delete(ss,cx-1,1); dec(cx);end;
end;
until 1<>1;
end;

function readncharsx(nx{,n}:byte;s:string):string;
var c:char;
	ss:string;
	x,y,cx:byte;
	ShouldInsert:Boolean;

procedure showit;
begin
gotoxy(x,y);write(char_repl(length(rtrim(ss)),'*')+char_repl(nx-length(rtrim(ss))+1,#32));
if cx>nx then gotoxy(x+nx-1,y) else gotoxy(x+cx-1,y);{cx:=nx;}
end;

begin
ss:=s;
if length(ss)>nx then ss:=left_(ss,nx);
{if ss='' then ss:=#32;}
x:=wherex;y:=wherey;cx:=length(ss)+1;
if nx>nx then nx:=nx;
ShouldInsert:=true;
if Shouldinsert then showcursor else fullcursor;
repeat
showit;
c:=readkey;
case c of
#27:begin readncharsx:=s;exit;end;
#13:begin readncharsx:=ss;exit;end;
#0: BEGIN C:=READKEY;
CASE C OF
#75:If cx>1 then dec(cx);
#77:If cx<=nx then inc(cx);
{DEL}
#83:if cx-1<=length(ss) then begin delete(ss,cx,1);
if cx>length(ss)+1 then dec(cx);end;
{INS}
#82:begin
ShouldInsert:=Not ShouldInsert;
if Shouldinsert then showcursor else fullcursor;
End;
END;
END;
' '..'ÿ': if shouldinsert then begin
if length(ss)<nx then begin
if cx>length(ss) then ss:=ss+c else insert(c,ss,cx); inc(cx); end;
end else
begin
if cx<=nx then begin
if cx>length(ss) then ss:=ss+c else ss[cx]:=c; inc(cx); end;
end;
{BackSpace}
#8:if cx-1>0 then begin delete(ss,cx-1,1); dec(cx);end;
end;
until 1<>1;
end;

function _nwordslen(s:string;st,n:byte):byte;
begin
_NWordsLen:=0;
If st>_Words(s) Then exit;
If ST+N-1>_Words(s) Then N:=_Words(s)-st;
_NWordsLen:=(_Pos(s,st+n-1)+_WLen(s,st+n-1))-_Pos(s,st);
end;

procedure _change(var s:string;s1:string;n,l:byte);
var i:byte;
begin
if n>length(s) then exit;
if l+n>length(s) then l:=length(s)-n+1;
for i:=0 to l-1 do s[n+i]:=s1[i mod length(s1)+1];
end;

function _wlen(s:string; N:Byte):byte;
var i,j:byte;
begin
if n>_words(s) then exit;
j:=0;
for i:=_pos(s,n) to length(s) do
begin
if s[i]=#32 then begin _wlen:=j;exit;end;
inc(j);
end;
end;

function _words(s:string):byte;
Var i,n,l:byte;
Begin
_words:=0;
l:=32;n:=0;
for i:=1 to length(s) do
begin
if (l=32) and (s[i]<>#32) then
begin inc(n);l:=0;end;
if s[i]=#32 then l:=32;
end;
_words:=n;
End;

function _pos(s:string; N:byte):byte;
Var i,ps,L:byte;
Begin
_pos:=0;
l:=32;ps:=0;I:=1;
WHILE I<length(s) DO begin
if (l=32) and (s[i]<>#32) then
begin inc(ps);L:=0;if ps=n then BEGIN _pos:=i;EXIT;END;end;
if s[i]=#32 then l:=32;
INC(I);
end;
End;

PROCEDURE insnsp(VAR s,S1:string;n:INTEGER);
var
	j,nn:byte;
	K:INTEGER;
begin
k:=n;
j:=1;
IF _words(s)<2 THEN EXIT;
nn:=_words(s)-1;
while k>0 do begin
insert(' ',s1,_pos(s,j+1));
insert(' ',s,_pos(s,j+1));
if j+1>nn then begin j:=1;end else inc(j);
dec(k);
end;
end;

FUNCTION DOSTOWIN(S:STRING):STRING;
CONST DOSL='€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ ¡¢£¤¥¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï';
VAR	I:BYTE;
	SS:STRING;
BEGIN
SS:='';
FOR I:=1 TO LENGTH(S) DO
IF POS(S[I],DOSL)>0 THEN SS:=SS+CHR(191+POS(S[I],DOSL)) ELSE SS:=SS+S[I];
DOSTOWIN:=SS;
END;

PROCEDURE DOSTOWINP(P:PMEM; SIZE:WORD);
CONST DOSL='€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ ¡¢£¤¥¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï';
VAR	I:WORD;
BEGIN
IF P=NIL THEN EXIT;
FOR I:=1 TO SIZE DO
IF POS(CHR(P^[I]),DOSL)>0 THEN P^[I]:=191+ORD(POS(CHR(P^[I]),DOSL));
END;

FUNCTION PUTSPACES(SS:STRING):STRING;
VAR I:BYTE;
	S:STRING;
BEGIN
I:=1;
S:=SS;
REPEAT
IF S[I] IN [',', '.', '!', '?', ':', ';'] THEN
if not ((s[i-1] in ['0'..'9']) and
		(s[i+1] in ['0'..'9'])) then INSERT(' ',S,I+1);
INC(I);
UNTIL I>LENGTH(S);
PUTSPACES:=S;
END;

FUNCTION DELEXTRASP(SS:STRING):STRING;
VAR I:BYTE;
	C:CHAR;
	T:BOOLEAN;
	S:STRING;
BEGIN
S:=SS;
C:=#0;
I:=1;T:=TRUE;
REPEAT
IF (S[I]=#32) THEN IF (C=#32) THEN BEGIN DELETE(S,I,1);T:=FALSE;END ELSE C:=#32;
IF S[I]<>#32 THEN C:=S[I];
IF T THEN INC(I) ELSE T:=TRUE;
UNTIL I>LENGTH(S);
DELEXTRASP:=ALLTRIM(S);
END;

function date_:string;
const
  days : array [0..6] of String[9] =
    ('Sunday','Monday','Tuesday',
     'Wednesday','Thursday','Friday',
     'Saturday');
var
  y, m, d, dow : Word;
begin
  GetDate(y,m,d,dow);
  date_:=right_('00'+str_(d),2)+'/'+right_('00'+str_(m),2)+'/'+right_('0000'+str_(y),4);
end;

function time_:string;
var
  H,M,S,Hun : Word;
begin
  GetTime(h,m,s,hun);
  time_:=right_('00'+str_(h),2)+':'+right_('00'+str_(m),2)+':'+right_('00'+str_(s),2);
end;

function pos_(s,s1:string):byte;
var i:byte;
begin
if length(s1)>length(S) then begin pos_:=0;exit;end;
for i:=1 to length(s)-length(s1) do if copy(s,i,length(s1))=s1 then begin pos_:=i;exit;end;
pos_:=LENGTH(S);exit;
end;

FUNCTION UPPER(S:STRING):STRING;
Const
	bl:string[32]='€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ';
	SL:string[32]=' ¡¢£¤¥¦§¨©ª«¬­®¯àáâãäåæçèéêëìíîï';
VAR SS:STRING;I:BYTE;
BEGIN
SS:='';
FOR I:=1 TO LENGTH(S) DO
if pos(s[i],sl)>0 then ss:=ss+bl[pos(s[i],sl)] else SS:=SS+UPCASE(S[I]);
UPPER:=SS;
END;

function cut(s:string;start,amount:byte):string;
var i:byte;
begin
i:=amount;
if start>length(s) then begin cut:='';exit;end;
if start+i>length(s) then begin cut:=right_(s,length(s)-start);exit;end;
cut:=(left_(s,start)+right_(s,length(s)-(start+i)));
end;




function left_(s:string;n:byte):string;
var i:byte;
begin
i:=length(s);if n<i then i:=n;
if i=0 then begin left_:='';exit;end;
left_:=copy(s,1,i);
end;

function right_(s:string;n:byte):string;
var i:byte;
begin
i:=length(s);if n<i then i:=n;
if i=0 then begin right_:='';exit;end;
right_:=copy(s,length(s)-i+1,i);
end;

function str_(n:longint):string;
var s:string;
begin
str(n,s);
str_:=s;
end;

function val_(s:string):integer;
var I, Code: Integer;
begin
  Val(S, I, Code);
  if code <> 0 then
   val_:=0 else val_:=i
end;

function char_repl(num:byte;ch:char):string;
var i:byte;
s:string;
begin
s:='';for i:=1 to num do s:=s+ch;
char_repl:=s;
end;

function ltrim(s:string):string;
var s1:string;
begin
s1:=s;
while (left_(s1,1)=#32) do s1:=right_(s1,length(s1)-1);
ltrim:=s1;
end;

function rtrim(s:string):string;
var s1:string;
begin
s1:=s;
while (right_(s1,1)=#32) do s1:=left_(s1,length(s1)-1);
rtrim:=s1;
end;

function alltrim(s:string):string;
begin
alltrim:=rtrim(ltrim(s));
end;

procedure cleantab(var s:string);
var i:byte;
begin
i:=1;
repeat
if s[i]=#9 then begin delete(s,i,1);i:=1;end;
inc(i);
until i>length(s);
end;

function tobin(n:byte):string;
const powers:array[0..7] of byte=(1,2,4,8,16,32,64,128);
var i:byte;
s:string[8];
begin
s:='';
for i:=7 downto 0 do s:=s+chr(ord(n and powers[i]<>0)+ord('0'));
tobin:=s;
end;

function tohex(n:byte):string;
const dig:array[0..15] of char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
begin
tohex:=dig[n div 16]+dig[n mod 16];
end;

end.