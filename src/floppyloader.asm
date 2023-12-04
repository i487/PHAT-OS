; A very old prototype from the begining of the development 
; Not used 

[bits 16]

[SECTION .text]
    load:
        pusha
        push dx

        mov ah, 0x02 ; BIOS read sector fuction
        mov al, dh ; passing the number of sectors to read
        mov ch, 0x00 ; selct cylinder 0
        mov dh, 0x00 ; select head 0

        int 0x13

        jc disk_error

        pop dx
        cmp dh, al
        jne disk_error

        popa
        ret

    disk_error:

        popa
        ret

; DL drive
; DH sectors to read
; CL start sector
