Procedure WriteTextPtr(P:PMem;Size:Word);
Var I:Word;
Begin
if p=nil then exit;
For I:=0 To Size-1 Do Write(chr(P^[i]));
End;

PROCEDURE FILLSEL(PR:RowPtr; VAR SEL:pSEL);
VAR COLS:ARRAY[5..11] OF BYTE;
	I,J:WORD;
BEGIN
 COLS[5]:=SELECT;
 COLS[6]:=COMMENT;
 COLS[7]:=SHADOW;
 COLS[8]:=SELECT;
 COLS[9]:=SELECT;
COLS[10]:=SELECT;
COLS[11]:=SELECT;
IF PR=NIL THEN EXIT;
WITH PR^ DO BEGIN
FOR J:=1 TO NWORDS(TextPtr,SizeOfText) DO SEL^[J]:=NORM+BACK SHL 4;
FOR I:=1 TO CommandsNumber DO WITH COMMANDS[I] DO
IF CommandType IN [5..11] THEN
IF CommandLength>0 THEN
FOR J:=CommandOffset TO CommandOffset+CommandLength-1 DO SEL^[J]:=COLS[CommandType]+BACK SHL 4 ELSE
FOR J:=1 TO NWORDS(TextPtr,SizeOfText) DO SEL^[J]:=COLS[CommandType]+BACK SHL 4;
END;
END;

FUNCTION _DM(PD:RowPtr):BOOLEAN;
VAR I:BYTE;
BEGIN
_DM:=FALSE;
IF PD=NIL THEN EXIT;
FOR I:=1 TO PD^.CommandsNumber DO IF PD^.COMMANDS[I].CommandType=16 THEN _DM:=TRUE;
END;

FUNCTION _CL(PD:RowPtr):BOOLEAN;
VAR I:BYTE;
BEGIN
_CL:=FALSE;
IF PD=NIL THEN EXIT;
FOR I:=1 TO PD^.CommandsNumber DO IF PD^.COMMANDS[I].CommandType=12 THEN _CL:=TRUE;
END;

FUNCTION _CC(PD:RowPtr):BOOLEAN;
VAR I:BYTE;
BEGIN
_CC:=FALSE;
IF PD=NIL THEN EXIT;
FOR I:=1 TO PD^.CommandsNumber DO IF PD^.COMMANDS[I].CommandType=13 THEN _CC:=TRUE;
END;

FUNCTION _CR(PD:RowPtr):BOOLEAN;
VAR I:BYTE;
BEGIN
_CR:=FALSE;
IF PD=NIL THEN EXIT;
FOR I:=1 TO PD^.CommandsNumber DO IF PD^.COMMANDS[I].CommandType=14 THEN _CR:=TRUE;
END;

FUNCTION FINDFILE(MASK:STRING):STRING;
var
  DirInfo: SearchRec;
begin
  FindFirst(MASK, Archive, DirInfo);
  IF DOSERROR= 0 THEN FINDFILE:=DirInfo.Name ELSE FINDFILE:='';
END;

Function NextPar(Var ParNum:Word):Boolean;
Var i,NewValue:Word;
begin
NextPar:=False;
NewValue:=10000;
With Header^ Do
For I:=0 to NumberOfParagraphs-1 Do With Offsets^[I] Do
If (NumberOfParagraph<NewValue) And (NumberOfParagraph>ParNum) then
NewValue:=NumberOfParagraph;
If NewValue<10000 Then Begin ParNum:=NewValue;NextPar:=True;End;
end;

Function PrevPar(Var ParNum:Word):Boolean;
Var i:Word;
	NewValue:Integer;
begin
PrevPar:=False;
NewValue:=-1;
With Header^ Do
For I:=0 to NumberOfParagraphs-1 Do With Offsets^[I] Do
If (NumberOfParagraph>NewValue) And (NumberOfParagraph<ParNum) then
NewValue:=NumberOfParagraph;
If NewValue>-1 Then Begin ParNum:=NewValue;PrevPar:=True;End;
end;

Function AbsolutePosition(n:Word):Word;
Var I:Word;
Begin
With Header^ Do
For I:=0 to numberOfParagraphs-1 Do With Offsets^[I] Do
If NumberOfParagraph=N Then Begin AbsolutePosition:=I;Exit;End;
AbsolutePosition:=0;
End;

Function IAbsolutePosition(n:Word):Word;
Var I:Word;
Begin
With Header^ Do
For I:=0 to numberOfindexes-1 Do
If indexes^[I]=N Then Begin IAbsolutePosition:=I;Exit;End;
IAbsolutePosition:=0;
End;

Procedure SearchForRelo(RNum:Word;Var N:Byte; Var _Par,_Row,_Start,_Len:Word);
Var I:Byte;
Begin
_Par:=10000;
If n=0 then N:=1;
With CurrentParagraph.ParagraphData[RNum]^ Do
For I:=n to CommandsNumber Do With Commands[I] Do
If CommandType In [8..11] Then Begin
N:=I;
_Par:=Paragraph;
_Row:=RowNumber;
_Start:=CommandOffset;
_Len:=CommandLength;
Exit;
end;
End;

Procedure FillRelo;
Var CR:Word;
	IR:Byte;
	_Par,_Row,_Start,_Len:Word;
	WhichRow:Word;
	SizeUpToRow:Word;
Begin
Jumpers^.RelCount:=0;
With CurrentParagraph Do
For CR:=1 To NumberOfRows Do
Begin
IR:=0;
While IR<=CurrentParagraph.ParagraphData[CR]^.CommandsNumber Do
Begin
Inc(IR);
SearchForRelo(CR,IR,_Par,_Row,_Start,_Len);
If _Par<>10000 Then 		{Relo Item Found ...}
With Jumpers^ Do Begin
If RelCount=255 Then Exit;
Inc(RelCount);
SizeUpToRow:=0;
WhichRow:=0;
While _Start-SizeUpToRow>_Words(PT.Text^[WhichRow+RN^[CR]]) Do
Begin
SizeUpToRow:=SizeUpToRow+_Words(PT.Text^[WhichRow+RN^[CR]]);
Inc(WhichRow);
End;
Dec(WhichRow);
With Items[RelCount] Do Begin
NumberOfRow:=WhichRow+RN^[CR]+1;
SelectionOffset:=_Start-SizeUpToRow;
{SelectionOffset:=_Pos(PT.Text^[NumberOfRow],SelectionOffset);}
RelocateToParagraph:=_Par;
If _Row=0 then _Row:=1;
RelocateToRow:=_Row;
SelectionLength:=_Len;
{If SelectionLength=0 Then SelectionLength:=_Words(PT.Text^[NumberOfRow])-SelectionOffset+1;}
SelectionLength:=_NWordsLen(PT.Text^[NumberOfRow],SelectionOffset,SelectionLength);
{if PT.Text^[NumberOfRow,SelectionOffset+SelectionLength]<>#32 then inc(SelectionLength);}
if selectionlength>MaxX Then selectionLength:=MaxX;
{if NumberOfRow=18 Then saymess(str_(selectionlength)+' '+str_(_len));}
End;
End;
End;
End;
End;

Function RelNumOnLine(NRow:Word):Byte;
Var I,J:Byte;
Begin
J:=0;
With Jumpers^ Do
For I:=1 To RelCount Do j:=j+Ord(Items[I].NumberOfRow=NRow);
RelNumOnLine:=j;
End;

Function RelNum(NRow:Word;N:Byte):Byte;
Var I,K:Byte;
Begin
RelNum:=0;
If N>RelNumOnLine(NRow) Then Exit;
K:=1;
With Jumpers^ Do Begin
For I:=1 To RelCount Do With Items[I] Do
If NumberOfRow=NRow Then If K<N Then Inc(K) Else
Begin
RelNum:=I;
Exit;
End;
End;
End;

Procedure MarkIt(NRow:Word;N:byte);
Var I:Byte;
Begin
{OUTSTRINGXY(0,0,14,STR_(JUMPERS^.ITEMS[RELNUM(NROW,N)].SELECTIONLENGTH));}
If (RMarked) or (RelNumOnLine(NRow)=0) or (RelNum(NRow,N)=0) Then Exit;
With Jumpers^ Do
With Items[RelNum(NRow,N)] Do Begin
RMarked:=True;
_Change(PT.Attr^[NRow],Chr(MSelect+MBack Shl 4),_Pos(PT.Text^[NRow],SelectionOffset),SelectionLength);
{saymess(str_(SelectionLength));}
End;
End;

Procedure UnMarkIt(NRow:Word;N:byte);
Begin
If (Not RMarked) or (RelNumOnLine(NRow)=0) or (RelNum(NRow,N)=0) Then Exit;
With Jumpers^ Do
With Items[RelNum(NRow,N)] Do Begin
RMarked:=False;
_Change(PT.Attr^[NRow],Chr(Select+Back Shl 4),_Pos(PT.Text^[NRow],SelectionOffset),SelectionLength);
End;
End;

function searchit:Boolean;
var pt:pmem;
	scr:pscr;
	s:string[74];
	NORows:Byte;
	TSize,kkl:Word;
	NC:Byte;
	cs:string[40];
begin
cs[0]:=chr(length(searchstr));
SearchIt:=False;
new(scr);
savescr(scr);
oback:=back;
back:=8;
drawtable(1,11,78,4);
s:=#2+' ¨ιγ <'+searchstr+'>... '+#0;
outstringxy(39-length(s) div 2,11,comment+back shl 4,s);
while sapos<Header^.NumberOfIndexes{Paragraphs} Do Begin
spar:=Header^.offsets^[absoluteposition(Header^.indexes^[sapos])].NumberOfParagraph;
s:=PROGRESS(Header^.NumberOfIndexes-1,sapos,74,'ώ','ω');
outstringxy(3,12,select+back shl 4,s);
seek(FileHandle,Header^.Offsets^[absoluteposition(spar)].OffsetInFile+2);
BlockRead(FileHandle,NORows,1);
dec(NORows);
BlockRead(FileHandle,TSize,2);
seek(FileHandle,FilePos(FileHandle)+tsize);
if srow>1 then
begin
for kkl:=1 to srow-1 do begin
blockread(FileHandle,nc,1);
seek(FileHandle,FilePos(FileHandle)+NC*9);
blockread(filehandle,TSize,2);
getmem(pt,tsize);
blockread(filehandle,pt^,tsize);
freemem(pt,tsize);
end;
end;
if keypressed then begin
    back:=oback;
	restscr(scr);
	dispose(scr);
	exit;
	end;
while srow<=NORows Do Begin
s:=PROGRESS(NORows,srow,74,'ώ','ω');
outstringxy(3,13,select+back shl 4,s);
blockread(FileHandle,nc,1);
seek(FileHandle,FilePos(FileHandle)+NC*9);
blockread(filehandle,TSize,2);
getmem(pt,tsize);
{if spar=139 then saymess(str_(srow)+' '+str_(sofs)+' '+str_(tsize));}
{$I-}
blockread(filehandle,pt^,tsize);
{$I+}
	While sofs+length(searchstr)<=tsize do begin
	if upper(chr(pt^[sofs]))=searchstr[1] then begin
	move(pt^[sofs],cs[1],length(searchstr));
	if upper(cs)=searchstr then begin
	searchit:=true;
	freemem(pt,tsize);
	restscr(scr);
	dispose(scr);
	back:=oback;
    if searchstr[1]=#32 then inc(sofs);
	inc(sofs);
	exit;
	end;
	end;
	inc(sofs);
	end;
freemem(pt,tsize);
sofs:=0;
Inc(SRow);
End;
SRow:=1;
inc(sapos);
End;
restscr(scr);
dispose(scr);
	back:=oback;
end;