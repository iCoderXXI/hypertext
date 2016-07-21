uses Crt,str_func;

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


var
  FromF, ToF: file;
  NumRead, NumWritten: Word;
  Buf:pointer;
  tread:longint;
begin
  Assign(FromF, ParamStr(1));
  Assign(ToF, ParamStr(2));
{$I-}
  Reset(FromF, 1);
	if ioresult<>0 then
	begin
	gotoxy(1,25);
	write(#7'Error opening file ',paramstr(1),'...');
	readkey;
	halt;
	end;
  Rewrite(ToF, 1);
	if ioresult<>0 then
	begin
	gotoxy(1,25);
	write(#7'Error creating file ',paramstr(2),'...');
	readkey;
	halt;
	end;
{$I-}
  gotoxy(1,23);
  insline;insline;insline;
  tread:=0;
  getmem(buf,65520);
  repeat
	{$I-}
	gotoxy(1,23);
	writeln(paramstr(1),' (',filesize(fromf),') ==> ',paramstr(2),' (',tread,')');
	BlockRead(FromF, Buf^, 65520, NumRead);
	if ioresult<>0 then
	begin
	gotoxy(1,25);
	write(#7'Error reading file ',paramstr(1),'...');
	readkey;
	halt;
	end;
	tread:=tread+numread;
	BlockWrite(ToF, Buf^, NumRead, NumWritten);
	if ioresult<>0 then
	begin
	gotoxy(1,25);
	write(#7'Error writing file ',paramstr(2),'...');
	readkey;
	halt;
	end;
	{$I-}
  gotoxy(5,24);write(progress(filesize(fromf),tread,70,'þ','ù'));
  until (NumRead = 0) or (NumWritten <> NumRead);
  freemem(buf,65520);
  gotoxy(1,23);
  insline;insline;insline;
  Close(FromF);
  Close(ToF);
end.
