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
