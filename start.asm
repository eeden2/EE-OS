mov bx, 4
cm bx, 5
jne label
jmp $
label:
   mov ah, 0x0e
   mov al, 'X'
   int 0x10
jmp $
times 510-($-$$) db 0
db 0x55, 0xaa