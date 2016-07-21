USES STR_FUNC,CRT,dos,_TOOLS,_FONT;

TYPE
	Command=RECORD
	CommandType:BYTE;
	CommandOffset,
	CommandLength,
	Paragraph,
	RowNumber:WORD;
	END;

	RowPtr=^TRow;
	TRow=RECORD
	CommandsNumber:BYTE;
	Commands:ARRAY[1..40] OF Command;
	SizeOfText:WORD;
	TextPtr:PMEM;
	END;

	PRowArr=^TRowArr;
	TRowArr=ARRAY[1..255] OF RowPtr;

	TParagraph=RECORD
	ParagraphNumber:WORD;
	NumberOfRows:BYTE;
	SizeOfText1:WORD;
	TextPtr1:PMEM;
	ParagraphData:TRowArr;
	END;

	TParagraphOffset=RECORD
	NumberOfParagraph:WORD;
	OffsetInFile:LONGINT;
	END;

	OffsetTablePtr=^TOffsetTable;
	TOffsetTable=Array[0..9999] Of TParagraphOffset;

	PWordArr=^TWordArr;
	TWordArr=ARRAY[1..255] OF WORD;

	HeaderPtr=^THeader;
	THeader=RECORD
    NumberOfIndexes:Word;
    Indexes:PWordArr;
	NumberOfParagraphs:WORD;
	Offsets:OffsetTablePtr;
	END;

	TRelData=Record
	SelectionOffset,
	SelectionLength:Byte;
	NumberOfRow,
	RelocateToParagraph,
	RelocateToRow:Word;
	End;

	RelArrPtr=^TRelArrPtr;
	TRelArrPtr=Record
	RelCount:Byte;
	Items:Array[1..255] Of TRelData;
	End;

var
    illegal:boolean;
	Header:HeaderPtr;
	FileHandle:file;
	CurrentParagraph:TParagraph;
	{ParagraphNumber,}K,I,J:word;
	Y1,WindowXSize:BYTE;
	SEL:PSEL;
	C:CHAR;
	MUSTHALT:BOOLEAN;
	PT:PARTXT;
	RN:pwordarr;	{RowNumber}
	NR:BYTE;
	A:BYTE;
	FILENAME:STRING;
	SCRY:BYTE;
	ScrYMax:WORD;
	nn:word;
	ActiveRow:word;
	Jumpers:RelArrPtr;
	RMarked:Boolean;
	RelOnLinePos:Byte;
	ParagraphNumber_:Word;
	searchstr:string[40];
	sapos,spar,srow,sofs:word;
	scr:pscr;
    oback:byte;
	legal:boolean;

{$i ETV_0001.PAS}

var quitit:boolean;
	makeselection:boolean;

Type
	pdarh=^tdarh;
    tdarh=record
    Sy:byte;
    Ay:Word;
    ReTurned:Boolean;
    ROLP:Byte;
	NextD:PDarh;
    PrevD:PDArh;
    start,offs:word;
    End;

Var DArh:PDArh;

procedure savedarh;
begin
New(DArh^.NextD);
DArh^.NextD^.PrevD:=DArh;
DArh:=DArh^.NextD;
end;

procedure restdarh;
begin
DArh:=DArh^.PrevD;
Dispose(DArh^.NextD);
end;

procedure help;
var scr:pscr;
	wmin,wmax:word;
	yy:byte;
	Max,Mix:Byte;
	s,s1:string;
	ob:byte;
begin
ob:=back;
back:=8;
s1:='           ';
new(scr);
savescr(scr);
wmin:=windmin;
wmax:=windmax;
Max:=MaxX;
Mix:=MinX;
hidecursor;
window_(5,1,70,23);
textattr:=select+back shl 4;clrscr;
writeln;
s:='*>- ETView - Окно помощи -<*';writec(@s[1],length(s),67);
s:='>───────────────────────────────────────────────────<';writec(@s[1],length(s),67);
{s:='Кнопки:';writec(@s[1],length(s),67);
s:='Up/Dn, PgUp/PgDn, Home/End, Ctrl+PgUp/Ctrl+PgDn ';writec(s1+s[1],length(s),67);
s:='Alt+S : Глобальный поиск по базе';writec(@s[1],length(s),67);
s:='Alt+L : Поиск начиная с текущей позиции';writec(@s[1],length(s),67);
s:='Alt+G : Продолжить поиск';writec(@s[1],length(s),67);
s:='Alt+P : Режим подготовки и печати документа';writec(@s[1],length(s),67);
s:='S : Обозначить начало выделенного фрагмента';writec(@s[1],length(s),67);
s:='E : Обозначить конец выделенного фрагмента';writec(@s[1],length(s),67);
s:='Пробел : Отменить выделение';writec(@s[1],length(s),67);
s:='P : Распечатать выделенный фрагмент на принтер';writec(@s[1],length(s),67);
s:='F : Записать выделенный фрагмент в файл';writec(@s[1],length(s),67);
s:='Alt+X/F10 : Выход до уровня оглавления';writec(@s[1],length(s),67);
s:='Esc : Шаг азад/выход в ОС (только с уровня оглавления)';writec(@s[1],length(s),67);}

writeln(s1+'Кнопки:');
textattr:=cheader+back shl 4;
writeln(s1+'Up/Dn, PgUp/PgDn, Home/End, Ctrl+PgUp/Ctrl+PgDn ');
write(s1+'Alt+S     : ');
textattr:=select+back shl 4;
writeln('Глобальный поиск по базе');
textattr:=cheader+back shl 4;
write(s1+'Alt+L     : ');
textattr:=select+back shl 4;
writeln('Поиск с текущей позиции');
textattr:=cheader+back shl 4;
write(s1+'Alt+G     : ');
textattr:=select+back shl 4;
writeln('Продолжить поиск');
s:='───────────────────────────────────────────────────';writec(@s[1],length(s),67);
textattr:=cheader+back shl 4;
write(s1+'Alt+P     : ');
textattr:=select+back shl 4;
writeln('Режим подготовки к распечатке');
textattr:=cheader+back shl 4;
write(s1+'S         : ');
textattr:=select+back shl 4;
writeln('Начать выделение');
textattr:=cheader+back shl 4;
write(s1+'E         : ');
textattr:=select+back shl 4;
writeln('Завершить выделение');
textattr:=cheader+back shl 4;
write(s1+'Пробел    : ');
textattr:=select+back shl 4;
writeln('Отменить выделение');
textattr:=cheader+back shl 4;
write(s1+'P         : ');
textattr:=select+back shl 4;
writeln('Распечатать выделенный фрагмент на принтер');
textattr:=cheader+back shl 4;
write(s1+'F         : ');
textattr:=select+back shl 4;
writeln('Сохранить выделенный фрагмент в файл');
s:='───────────────────────────────────────────────────';writec(@s[1],length(s),67);
textattr:=cheader+back shl 4;
write(s1+'Alt+X/F10 : ');
textattr:=select+back shl 4;
writeln('Вернуться к оглавлению');
textattr:=cheader+back shl 4;
write(s1+'Esc       : ');
textattr:=select+back shl 4;
writeln('Назад/выйти в ОС (только из оглавления)');

While 1=1 do
begin
gotoxy(6,20);
textattr:=select+back shl 4;
write('       Время : ');
textattr:=cheader+back shl 4;
write(time_);
textattr:=select+back shl 4;
write('             Дата : ');
textattr:=cheader+back shl 4;
write(date_);
if keypressed then if readkey=#27 then break;
end;
windmax:=wmax;windmin:=wmin;
MAXX:=Max;
MINX:=Mix;
restscr(scr);
dispose(scr);
back:=ob;
end;

procedure printit(numberofrows:word);
LABEL QEWE;
var c:char;
	st,nd,scry,k,a,j:word;
    isn:byte;
	scr,scr1:pscr;
	fname:string[12];
    f:text;
	selected:Boolean;
begin
selected:=false;
isn:=0;
new(scr);
savescr(scr);
k:=1;scry:=1;
st:=0;nd:=0;
displayp(PT,K,SCRY,k+scry-1,pt.nr,scry+k-1,st,nd);
repeat
c:=chr(ord(readkey)+ord(illegal));
case c of
'S','s','ы','Ы': begin selected:=true;st:=scry+k-1;if nd<st then nd:=st;end;
'E','e','у','У': begin selected:=true;Nd:=scry+k-1;if st>nd then st:=nd;end;
'P','p','з','З': begin
if not selected then begin st:=0;nd:=pt.nr;end;
new(scr1);
savescr(scr1);
drawtable(1,11,78,3);
 for j:=st to nd do begin
outstringxy(3,12,select+back shl 4,PROGRESS(nd-st+1,j-st+1,74,'■','∙'));
if not pstring(pt.text^[j]) then GOTO QEWE;
end;
pstring(chr(12));
QEWE:
restscr(scr1);
dispose(scr1);
end;
'F','f','а','А': begin
if not selected then begin st:=0;nd:=pt.nr;end;
new(scr1);
savescr(scr1);
drawtable(12,11,56,3);
gotoxy(15,12-sy);
textattr:=back shl 4+select;
write(' Введите имя файла: ');
textattr:=select;
fname:=upper(alltrim(readnchars(12,str_(paragraphnumber_)+'.txt')));
hidecursor;
restscr(scr1);
dispose(scr1);
assign(f,fname);
{$I-}
append(f);
if ioresult<>0 then rewrite(f);
{$I+}
if ioresult<>0 then begin
fname:=str_(paragraphnumber_)+'.txt';
rewrite(f);
end;
for j:=st to nd do writeln(f,pt.text^[j]);
close(f);
saymess('Выделенный фрагмент сохранён в файл '+fname+'...');
end;
#32: begin st:=0;nd:=0;selected:=false;end;
#0: begin
c:=chr(ord(readkey)+ord(illegal));
case c of
#59:help;
#72: if scry>1 then dec(scry) else if k>1 then dec(k);
#80: if scry<ScrYMax then inc(scry) else if k+scrymax<=pt.nr then inc(k);
#73: for a:=1 to ScrYMax Do if scry>1 then dec(scry) else if k>1 then dec(k);
#81: for a:=1 to ScrYMax Do if scry<ScrYMax then inc(scry) else if k+scrymax<=pt.nr then inc(k);
#073: IF K>1 THEN FOR A:=1 TO MY DO IF K>1 THEN DEC(K) ELSE ELSE C:=#0;
#081: IF NOT (K+1>(INTEGER(PT.NR)-MY+1)) THEN FOR A:=1 TO MY DO
		IF NOT (K+1>(INTEGER(PT.NR)-MY+1)) THEN INC(K) ELSE ELSE C:=#0;
#071: scry:=1;
#079: scry:=ScrYMax;
#0132: begin scry:=1; K:=1; end;
#0118: begin scry:=ScrYMax; if PT.NR>SCRYMax then K:=pt.nr-scrymax+1 else k:=1; end;
end;
end;
end;
if st>nd then begin a:=st;st:=nd;nd:=a;end;
displayp(PT,K,SCRY,k+scry-1,pt.nr,scry+k-1,st,nd);
until c=#27;
restscr(scr);
dispose(scr);
end;

procedure show_par(start,offs:word);
Label StartShow,checkc,start1;
{Var
	Sy:Byte;
	Ay:Word;
	ReTurned:Boolean;
	ROLP:Byte;}
begin
musthalt:=false;
darh^.prevd:=darh;
start1:
{saymess(str_(offs));}
SCRY:=1;
DArh^.ReTurned:=False;
StartShow:
if musthalt and (darh^.prevd=darh) then
begin
oback:=back;
back:=4;
if (alert('Выйти в ОС ?',' Д А ','Н Е Т')=1) then exit else back:=oback;musthalt:=false;end;
ParagraphNumber_:=start;
MUSTHALT:=FALSE;
REPEAT
with CurrentParagraph do begin
WINDOW_(1,0,WindowXSize,25);
seek(FileHandle,Header^.Offsets^[AbsolutePosition(ParagraphNumber_)].OffsetInFile);
blockread(FileHandle,ParagraphNumber,5);
getmem(TextPtr1,SizeOfText1);
blockread(FileHandle,TextPtr1^,SizeOfText1);
Y1:=SAYHEADER(TextPtr1,SizeOfText1);
WINDOW(WINDMIN MOD 256+1,WINDMIN DIV 256+Y1,WINDMAX MOD 256+1,WINDMAX DIV 256);
Freemem(TextPtr1,SizeOfText1);
dec(NumberOfRows);
FOR K:=1 TO NumberOfRows DO
BEGIN
	NEW(ParagraphData[K]);
	WITH ParagraphData[K]^ DO
	BEGIN
		BLOCKREAD(FileHandle,CommandsNumber,1);
		FOR I:=1 TO CommandsNumber DO BLOCKREAD(FileHandle,COMMANDS[I],9);
		BLOCKREAD(FileHandle,SizeOfText,2);
		GETMEM(TextPtr,SizeOfText);
		BLOCKREAD(FileHandle,TextPtr^,SizeOfText);
    	FOR I:=1 TO COMMANDSNUMBER DO BEGIN
        IF COMMANDS[I].COMMANDTYPE IN [8..11] THEN
        IF COMMANDS[I].COMMANDLENGTH=0 THEN
        BEGIN
        COMMANDS[I].COMMANDLENGTH:=NWORDS(TEXTPTR,SIZEOFTEXT);
        COMMANDS[I].COMMANDOFFSET:=1;
        END;
        END;
	END;
END;
    if makeselection then
	with ParagraphData[Srow]^ do begin
    inc(CommandsNumber);
	commands[commandsnumber].commandtype:=6;
	commands[commandsnumber].CommandOffset:=nwords(TextPtr,sofs);
	commands[commandsnumber].CommandLength:=_words(searchstr);
    makeselection:=false;
    end;
C:=#0;
PT.NR:=0;
	GOTOXY(1,2);WRITE(CHAR_REPL(MAXX+2,'─'));
NR:=0;
FOR J:=1 TO NumberOfRows DO
BEGIN
	FILLSEL(ParagraphData[J],SEL);
	IF J=1 THEN RN^[J]:=1 ELSE RN^[J]:=PT.NR+1;
	IF _DM(ParagraphData[J]) THEN WRITED_(ParagraphData[J]^.TextPtr,ParagraphData[J]^.SizeOfText,MAXX,SEL,PT) ELSE
	IF _CL(ParagraphData[J]) THEN WRITEL_(ParagraphData[J]^.TextPtr,ParagraphData[J]^.SizeOfText,MAXX,SEL,PT) ELSE
	IF _CC(ParagraphData[J]) THEN WRITEC_(ParagraphData[J]^.TextPtr,ParagraphData[J]^.SizeOfText,MAXX,SEL,PT) ELSE
	IF _CR(ParagraphData[J]) THEN WRITER_(ParagraphData[J]^.TextPtr,ParagraphData[J]^.SizeOfText,MAXX,SEL,PT) ELSE
	WRITEX_(ParagraphData[J]^.TextPtr,ParagraphData[J]^.SizeOfText,MAXX,SEL,PT);
	GOTOXY(2,1);WRITE(PROGRESS(NumberOfRows,J,MAXX,'■','∙'));
	WITH ParagraphData[J]^ DO FREEMEM(TextPtr,SizeOfText);
END;
	FillRelo;
	RMarked:=False;
	GOTOXY(2,1);WRITE(CHAR_REPL(MAXX,' '));
	GOTOXY(1,2);WRITE(CHAR_REPL(MAXX+2,' '));
ScrYMax:=MY;
IF ScrYMax>PT.NR THEN ScrYMax:=PT.NR;
if offs>NumberOfRows Then Offs:=1;
if offs=0 then offs:=1;
K:=rn^[offs];
if pt.nr<=ScrYMax then begin k:=1;ScrY:=rn^[offs]-k+1; end else
if pt.nr-K<ScrYMax then
begin K:=pt.nr-ScrYMax+1;ScrY:=rn^[offs]-k+1; end;
if k<1 then k:=1;
if scry<1 then if k>1 then dec(k);
if ScrY<1 then ScrY:=1;
{saymess(' offs='+str_(offs)+
		'       rn^[offs]='+str_(rn^[offs])+
		'       numofrows='+str_(numberofrows)+
		'       K='+str_(k)+
		'       Pt.Nr='+str_(pt.nr)+
		'       ScrY='+str_(scry));}
ActiveRow:=1;
RelOnLinePos:=1;
If DArh^.ReTurned Then Begin
DArh^.ReTurned:=False;
K:=DArh^.Ay; ScrY:=DArh^.Sy;
RelOnLinePos:=DArh^.ROLP;
End;
MarkIt(K+ScrY-1,RelOnLinePos);
{for j:=1 to NumberOfRows do
 if ((j<NumberOfRows) and ((k+scry-1>=rn^[j]) and (k+scry-2<rn^[j+1])))
  Or ((j=numberofrows) and (k+scry-1>=rn^[j])) then ActiveRow:=j;}
if k+scry-2=0 then ActiveRow:=1;
DISPLAY(PT,K,SCRY,{ActiveRow}scry+k-1,pt.nr,scry+k-1);
REPEAT
{if isalt then help;}
IF KEYPRESSED THEN BEGIN
C:=chr(ord(READKEY)+ord(illegal));
checkc:
CASE C OF
#045,#068:begin
FOR K:=1 TO NumberOfRows DO
BEGIN
	DISPOSE(ParagraphData[K]);
END;
while not (darh^.prevD=darh) do darh:=darh^.prevd;
start:=darh^.start;
offs:=darh^.offs;
 goto startshow;
end;
#059:help;
#025: printit(NumberOfRows);
#031:begin
sapos:=0;
{spar:=Header^.offsets^[header^.indexes^[sapos]].NumberOfParagraph;}
srow:=1;
sofs:=0;
new(scr);
savescr(scr);
oback:=back;
back:=8;
drawtable(2,11,76,3);
gotoxy(2,12-sy);
textattr:=back shl 4+select;
write('  Введите строку поиска : ');
textattr:=select;
searchstr:=upper(rtrim(readnchars(40,searchstr)));
hidecursor;
restscr(scr);
dispose(scr);
back:=oback;
if (searchstr<>'') then if searchit then if
(maxavail>sizeof(pdarh)) then Begin
FOR i:=1 TO NumberOfRows DO BEGIN DISPOSE(ParagraphData[i]);END;
DArh^.Sy:=ScrY; DArh^.Ay:=K;
DArh^.ROLP:=RelOnLinePos;
darh^.start:=start;darh^.offs:=offs;
savedarh;
start:=spar;
offs:=srow;
makeselection:=true;
goto start1;

{(sptr>=10000) then Begin
FOR i:=1 TO NumberOfRows DO BEGIN DISPOSE(ParagraphData[i]); END;
DArh^.Sy:=ScrY; DArh^.Ay:=K;
DArh^.ROLP:=0;
makeselection:=true;
show_par(spar,srow);
DArh^.ReTurned:=True;
Goto StartShow;}
End else saymess('Не хватает оперативной памяти...')
else saymess('Строка не найденна...');
end;
#038:begin
{spar:=START;}
sapos:=Iabsoluteposition(start);
{saymess(str_(start)+' '+str_(sapos)+' '+str_(header^.indexes^[sapos]));}
srow:=1;
sofs:=0;
new(scr);
savescr(scr);
oback:=back;
back:=8;
drawtable(2,11,76,3);
gotoxy(2,12-sy);
textattr:=back shl 4+select;
write('  Введите строку поиска : ');
textattr:=select;
searchstr:=upper(rtrim(readnchars(40,searchstr)));
hidecursor;
restscr(scr);
dispose(scr);
back:=oback;
if (searchstr<>'') then if searchit then if
(maxavail>sizeof(pdarh)) then Begin
FOR i:=1 TO NumberOfRows DO BEGIN DISPOSE(ParagraphData[i]);END;
DArh^.Sy:=ScrY; DArh^.Ay:=K;
DArh^.ROLP:=RelOnLinePos;
darh^.start:=start;darh^.offs:=offs;
savedarh;
start:=spar;
offs:=srow;
makeselection:=true;
goto start1;

{(sptr>=10000) then Begin
FOR i:=1 TO NumberOfRows DO BEGIN DISPOSE(ParagraphData[i]); END;
DArh^.Sy:=ScrY; DArh^.Ay:=K;
DArh^.ROLP:=0;
makeselection:=true;
show_par(spar,srow);
DArh^.ReTurned:=True;
Goto StartShow;}
End else saymess('Не хватает оперативной памяти...')
else saymess('Строка не найденна...');
end;
#34: if searchstr='' then saymess('Ну хотя бы одну буковку...') else
        begin
		If searchit Then If
{(sptr>=10000) then Begin
FOR i:=1 TO NumberOfRows DO BEGIN DISPOSE(ParagraphData[i]); END;
DArh^.Sy:=ScrY; DArh^.Ay:=K;
DArh^.ROLP:=0;
makeselection:=true;
show_par(spar,srow);
DArh^.ReTurned:=True;
Goto StartShow;}
(maxavail>sizeof(pdarh)) then Begin
FOR i:=1 TO NumberOfRows DO BEGIN DISPOSE(ParagraphData[i]);END;
DArh^.Sy:=ScrY; DArh^.Ay:=K;
DArh^.ROLP:=RelOnLinePos;
darh^.start:=start;darh^.offs:=offs;
savedarh;
start:=spar;
offs:=srow;
makeselection:=true;
goto start1;
End else saymess('Не хватает оперативной памяти...')
else saymess('Строка не найденна...');
end;

#073:
Begin
If RMarked Then UnMarkIt(K+ScrY-1,RelOnLinePos);
 IF K>1 THEN FOR A:=1 TO MY DO IF K>1 THEN DEC(K) ELSE ELSE C:=#0;
RelOnLinePos:=1;
MarkIt(K+ScrY-1,RelOnLinePos);
End;
#081:
Begin
If RMarked Then UnMarkIt(K+ScrY-1,RelOnLinePos);
 IF NOT (K+1>(INTEGER(PT.NR)-MY+1)) THEN FOR A:=1 TO MY DO
		IF NOT (K+1>(INTEGER(PT.NR)-MY+1)) THEN INC(K) ELSE ELSE C:=#0;
RelOnLinePos:=1;
MarkIt(K+ScrY-1,RelOnLinePos);
End;

#071:
Begin
If RMarked Then UnMarkIt(K+ScrY-1,RelOnLinePos);
scry:=1;
RelOnLinePos:=1;
MarkIt(K+ScrY-1,RelOnLinePos);
End;
#079:
Begin
If RMarked Then UnMarkIt(K+ScrY-1,RelOnLinePos);
scry:=ScrYMax;
RelOnLinePos:=1;
MarkIt(K+ScrY-1,RelOnLinePos);
End;

#0132: begin
If RMarked Then UnMarkIt(K+ScrY-1,RelOnLinePos);
scry:=1; K:=1;
RelOnLinePos:=1;
MarkIt(K+ScrY-1,RelOnLinePos);
end;
#0118: begin
If RMarked Then UnMarkIt(K+ScrY-1,RelOnLinePos);
scry:=ScrYMax;
if PT.NR>SCRYMax then K:=pt.nr-scrymax+1 else k:=1;
RelOnLinePos:=1;
MarkIt(K+ScrY-1,RelOnLinePos);
end;

#072:
begin
If RMarked Then UnMarkIt(K+ScrY-1,RelOnLinePos);
IF SCRY=1 THEN IF K>1 THEN DEC(K) ELSE C:=#0 ELSE DEC(SCRY);
RelOnLinePos:=1;
MarkIt(K+ScrY-1,RelOnLinePos);
end;
#075: If (RMarked) And (RelOnLinePos>1) then
Begin
UnMarkIt(K+ScrY-1,RelOnLinePos);
Dec(RelOnLinePos);
MarkIt(K+ScrY-1,RelOnLinePos);
DISPLAY(PT,K,SCRY,{ActiveRow}scry+k-1,pt.nr,scry+k-1);
End;
#077: If (RMarked) And (RelOnLinePos<RelNumOnLine(K+ScrY-1)) then
Begin
UnMarkIt(K+ScrY-1,RelOnLinePos);
Inc(RelOnLinePos);
MarkIt(K+ScrY-1,RelOnLinePos);
DISPLAY(PT,K,SCRY,{ActiveRow}scry+k-1,pt.nr,scry+k-1);
End;
#13: If RMarked And (maxavail>sizeof(pdarh)) then Begin
FOR i:=1 TO NumberOfRows DO BEGIN DISPOSE(ParagraphData[i]);END;
DArh^.Sy:=ScrY; DArh^.Ay:=K;
DArh^.ROLP:=RelOnLinePos;
darh^.start:=start;darh^.offs:=offs;
savedarh;
start:=Jumpers^.Items[RelNum(K+ScrY-1,RelOnLinePos)].RelocateToParagraph;
offs:=Jumpers^.Items[RelNum(K+ScrY-1,RelOnLinePos)].RelocateToRow;
goto start1;
{show_par(Jumpers^.Items[RelNum(K+ScrY-1,RelOnLinePos)].RelocateToParagraph,
	Jumpers^.Items[RelNum(K+ScrY-1,RelOnLinePos)].RelocateToRow);}
End;
#080:
begin
If RMarked Then UnMarkIt(K+ScrY-1,RelOnLinePos);
IF SCRY=ScrYMax THEN IF NOT (K+1>(INTEGER(PT.NR)-MY+1)) THEN INC(K) ELSE C:=#0 ELSE INC(SCRY);
RelOnLinePos:=1;
MarkIt(K+ScrY-1,RelOnLinePos);
end;
#27:
begin
if (darh^.PrevD=darh) then musthalt:=true else begin
FOR i:=1 TO NumberOfRows DO BEGIN DISPOSE(ParagraphData[i]);END;
restdarh;
start:=darh^.start;
offs:=darh^.offs;
DArh^.ReTurned:=True;
goto startshow;
end;
end;
END;
IF (C IN [#072,#080,#073,#081,#071,#079,#0132,#0118]) THEN BEGIN
for j:=1 to NumberOfRows do
 if ((j<NumberOfRows) and ((k+scry-1>=rn^[j]) and (k+scry-2<rn^[j+1])))
  Or ((j=numberofrows) and (k+scry-1>=rn^[j]))
 then ActiveRow:=j;
if k+scry-2=0 then ActiveRow:=1;
DISPLAY(PT,K,SCRY,{ActiveRow}scry+k-1,pt.nr,scry+k-1);
END;
END;
UNTIL MUSTHALT{ OR (C IN ['-','+'])};
oback:=back;
back:=4;
if not (alert('Выйти в ОС ?',' Д А ','Н Е Т')=1) then begin musthalt:=false;back:=oback;goto startshow;end;
FOR K:=1 TO NumberOfRows DO
BEGIN
	DISPOSE(ParagraphData[K]);
END;
END;
offs:=1;
UNTIL MUSTHALT;
end;

function ffile(mask:string):string;
var
  DirInfo: SearchRec;
begin
  FindFirst(mask, Archive, DirInfo);
  if doserror=0 then ffile:=dirinfo.name else
  begin
  back:=4;
  saymess('ФАЙЛ НЕ НАЙДЕН '+mask);
  Illegal:=true;
  textmode(3);
  halt;
  end;
end;


var pstate:pointer;
	pp:pointer;
	ii:byte;
	fs:longint;
	s:string;
	f:file;
	filename_:String;
begin
checkbreak:=false;
illegal:=true;
filename_:='';
for ii:=1 to paramcount do
begin
assign(f,paramstr(ii));
{$i-}
reset(f,1);
{$i+}
if ioresult=0 then begin filename_:=paramstr(ii);close(f);break;end;
end;
if filename='' then filename_:=ffile('*.etf');
assign(f,filename_);
{$i-}
reset(f,1);
{$i+}
if ioresult<>0 then begin
back:=4;
saymess('ФАЙЛ НЕ НАЙДЕН '+filename_);
Illegal:=true;
textmode(3);
halt;
end;
ii:=$0;
fs:=filesize(f);
seek(f,fs+10);
blockwrite(f,ii,1);
seek(f,fs);
blockread(f,ii,1);
seek(f,fs);
truncate(f);
close(f);
illegal:=FALSE; {(ii<>$ff);}
if illegal then if alert('Программа думает, что это пиратская копия...','Выйти в ОС','Повиснуть')=1 then
begin textmode(3);halt;end;
quitit:=false;
makeselection:=false;
LOADATTR;
CHECKBREAK:=FALSE;
WindowXSize:=78;
HIDECURSOR;
TEXTATTR:=7;
IF PARAMCOUNT<1 THEN FILENAME:=FINDFILE('*.ETF') ELSE FILENAME:=PARAMSTR(1);
IF FILENAME='' THEN BEGIN
WRITELN(#7'ФАЙЛ НЕ НАЙДЕН *.ETF ...');
READKEY;
TEXTMODE(3);
HALT;
END;
assign(FileHandle,FILENAME);
{$I-}
reset(FileHandle,1);
IF IORESULT<>0 THEN BEGIN
WRITELN(#7'ФАЙЛ НЕ НАЙДЕН ',FILENAME,' ...');
READKEY;
TEXTMODE(3);
HALT;
END;
{$I+}
mark(pstate);
new(darh);
darh^.prevd:=darh;
new(Header);
NEW(PT.TEXT);
NEW(PT.ATTR);
new(RN);
new(sel);
new(jumpers);

	blockread(FileHandle,Header^.NumberOfIndexes,2);
	getmem(Header^.Indexes,Header^.NumberOfIndexes*2);
	blockread(FileHandle,Header^.Indexes^,Header^.NumberOfIndexes*2);
blockread(FileHandle,Header^.NumberOfParagraphs,2);
getmem(Header^.Offsets,sizeof(TParagraphOffset)*Header^.NumberOfParagraphs);
blockread(FileHandle,Header^.Offsets^[0],Header^.NumberOfParagraphs*sizeof(TParagraphOffset));
Writeln;
searchstr:='';
spar:=Header^.offsets^[0].NumberOfParagraph;
srow:=1;
sofs:=0;
if paramcount<2 then show_par(spar,1) else show_par(spar,val_(paramstr(2)));
close(FileHandle);
Freemem(Header^.Offsets,sizeof(TParagraphOffset)*Header^.NumberOfParagraphs);
release(pstate);
TEXTMODE(3);
end.