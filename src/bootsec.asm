;   This file is part of PHAT-OS.
;
;   PHAT-OS is free software: you can redistribute it and/or modify it under the terms of the 
;    GNU General Public License as published by the Free Software Foundation, either version 3 
;    of the License, or (at your option) any later version.
;
;    PHAT-OS is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
;    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
;    See the GNU General Public License for more details.

;    You should have received a copy of the GNU General Public License along with PHAT-OS. 
;    If not, see <https://www.gnu.org/licenses/>. 

[org 0x7c00]
[bits 16]

jmp short BOOT_START
nop

BS_OEMName                  db "MSWIN4.1"
BPB_BytesPerSec             dw 512
BPB_SecPerClus              db 1
BPB_RsvdSecCnt              dw 1
BPB_FatNum                  db 2
BPB_RootEntCnt              dw 0x0E0
BPB_TotalSecCnt             dw 2880
BPB_Media_Desc_Type         db 0x0F0
BPB_SecPerFat               dw 9
BPB_SecPerTrack             dw 18
BPB_Heads                   dw 2
BPB_HiddenSectors           dd 0
BPB_LargeSecCnt             dd 0

EBR_BootDrvNumber           db 0
                            db 0
EBR_Signature               db 0x29
EBR_VolumeId                db 0x88, 0xFF, 0x88, 0xFF
EBR_VolumeLbl               db "TINY "
EBR_SysId                   db "FAT 12"


[SECTION .text]
    BOOT_START:
        xor ax, ax
        mov es, ax
        mov ds, ax
        mov ss, ax

        mov byte[EBR_BootDrvNumber], dl
        
        mov al, 0x03
        int 0x10

        mov sp, 0x7c00
        mov bp, sp

        call INIT_BOOT_DISK

        call LOAD_ROOT_DIR
        call KERNEL_SEARCH
        call LOAD_FAT

        mov si, KERNEL_LOAD_MSG
        call PRINT

        jmp KERNEL_LOAD
        
    PRINT:
        pusha
        mov ah, 0x0e

        .loop:
        lodsb
        cmp al, 0
        je .done
        int 0x10
        jmp .loop

        .done:                ;Return cursor 
        mov al, RETC
        int 10h

        popa
        ret
    
    CRIT_ERROR:
        mov si, ERROR_MSG
        call PRINT
        mov si, REBOOT_MSG
        call PRINT
        xor ah, ah
        int 0x16
        db 0x0ea 
        dw 0x0000 
        dw 0xffff 

    INIT_BOOT_DISK:
        push es

        mov ah, 0x08
        int 0x13
        jc CRIT_ERROR
        pop es

        inc dh
        mov [BPB_Heads], dh
        and cl, 0x3f
        xor ch, ch
        mov [BPB_SecPerTrack], cx

        ret

    READ_LBA:
        push cx ;CX - amount of sectors to read
        push bx ;BX - buffer
        push ax ;AX - LBA 
        
        mov ax, word[BPB_Heads]
        mul word[BPB_SecPerTrack]
        mov bx, ax
        pop ax
        xor dx, dx
        div bx ;At this moment AX is Cylinder DX is temp

        push ax

        mov ax, dx
        xor dx, dx
        div word[BPB_SecPerTrack]
        inc dx ;At this moment AX is head DX is sector

        mov cx, dx ; CL - sector
        xor dx, dx
        mov dh, al ; DH - head

        pop bx  
        mov ch, bl ; CH - cylinder

        pop bx
        pop ax
        mov ah, 0x02
        mov dl, [EBR_BootDrvNumber]
        
        int 13h
        jc CRIT_ERROR

        ret

    LOAD_ROOT_DIR:
        mov al, [BPB_FatNum]
        xor ah, ah
        mov bx, [BPB_SecPerFat]
        mul bx
        add ax, [BPB_RsvdSecCnt]

        push ax ;Root dir start sector
        
        mov ax, [BPB_RootEntCnt],
        shl ax, 5
        xor dx, dx
        div word[BPB_BytesPerSec]

        test dx, dx
        jz .done 
        inc ax

        .done:
        mov cx, ax ;BX - root dir sector count 
        pop ax
        mov bx, BUFFER
        call READ_LBA

        ret

    KERNEL_SEARCH:
        xor bx, bx
        mov di, BUFFER
        .loop:
        mov si, KERNEL_FILE
        mov cx, 11
        push di
        repe cmpsb
        pop di

        je .found
        inc bx 
        add di, 32
        cmp bx, [BPB_RootEntCnt]
        jl .loop

        mov si, KERNEL_NOT_FOUND_MSG
        call PRINT
        call CRIT_ERROR

        .found: ;Kernel root directory entry is in DI register
        mov ax, [di + 26]
        mov [KERNEL_CLUS], ax
        mov ax, [di + 28]
        mov word[KERNEL_SIZE], ax

        ret 
    
    LOAD_FAT:
        mov ax, [BPB_SecPerFat]
        mov bx, [BPB_FatNum]
        mul bx

        mov cx, ax
        mov bx, BUFFER
        mov ax, [BPB_RsvdSecCnt]
        call READ_LBA

        ret

    KERNEL_LOAD:
        mov bx, KERNEL_OFF
        mov ax, KERNEL_SEG
        push ax
        mov es, ax

        .loop:
        mov ax, [KERNEL_CLUS]
        add ax, 31 ; will change later later
        mov cx, 1
        call READ_LBA
        add bx, [BPB_BytesPerSec]

        mov ax, [KERNEL_CLUS]
        mov cx, 3
        mul cx
        mov cx, 2
        ;xor dx, dx
        div cx
        
        mov si, BUFFER
        add si, ax
        mov ax, [ds:si]
        
        or dx, dx
        jz .even

        shr ax, 4               ; .odd
        jmp .after_next_clus

        .even:
        and ax, 0xFFF

        .after_next_clus:
        cmp ax, 0xFF8
        jae .done

        mov [KERNEL_CLUS], ax
        jmp .loop

        .done:                      ;checking kernel signature
        cmp word[es:KERNEL_OFF], KERNEL_SIGNATURE
        jne CRIT_ERROR

        mov dl, byte[EBR_BootDrvNumber]
        mov cx, [KERNEL_SIZE]
        pop ds
        jmp KERNEL_SEG:KERNEL_OFF + 2

KERNEL_LOAD_MSG             db "Loading kernel!", ENDL, 0
REBOOT_MSG                  db "Press any key to reboot", ENDL, 0
ERROR_MSG                   db "Unable To Boot!", ENDL, 0
KERNEL_NOT_FOUND_MSG        db "Kernel Not Found!", ENDL, 0
KERNEL_FILE                 db "KERNEL  BIN"
KERNEL_CLUS                 dw 0
KERNEL_SIZE                 dw 0

RETC                        equ 0x0D
ENDL                        equ 0x0A
KERNEL_SEG                  equ 0x0100
KERNEL_OFF                  equ 0
KERNEL_SIGNATURE            equ 0xBADF

times 510-($-$$) db 0
dw 0xaa55

BUFFER: