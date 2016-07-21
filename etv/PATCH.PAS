var f:file;
	s:string;
	fs:longint;
begin
assign(f,paramstr(1));
reset(f,1);
{$I-}
fs:=filesize(f);
seek(f,fs);
{$I+}
s[1]:=#255;
blockwrite(f,s[1],1);
seek(f,fs);
truncate(f);
close(f);
end.