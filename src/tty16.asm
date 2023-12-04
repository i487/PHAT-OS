;  Old prototype from the begining of the development 
;  Not used

[bits 16]

handle_input16:
  
    xor cl, cl
    mov di, buffer

    .loop:
    xor ah, ah
    int 0x16
    cmp ah, 0x0e
    je backspace
    cmp ah, 0x1c
    je enter
    cmp cl, 63
    je .loop
    mov ah, 0x0e
    int 0x10
    stosb 
    inc cl
    jmp .loop  
    ret

    backspace:
    xor bx, bx
    mov ah, 0x03
    int 0x10
    cmp dl, 0
    dec dl
    dec cl
    mov ah, 0x02
    int 0x10 
    mov ah, 0x0a
    mov al, 0x20
    int 0x10
    ret


    enter:
    push cx
   
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10	
    mov si, buffer
    call println16

    xor cx, cx
    mov bx, buffer
    .loop:
    mov byte[bx], 0x00
    cmp cx, 63
    je .skip
    inc cx
    inc bx
    jmp .loop 
    .skip:
    pop cx
    ret


buffer times 64 db 0
