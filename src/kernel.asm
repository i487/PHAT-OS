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

KERNEL_SIGN                     dw 0xBADF ;Kernel signature

[bits 16]
[SECTION .data]
    ; Constants
    KERNEL_SEG                  equ 0x100
    KENEL_OFF                   equ 0
    ENDL                        equ 0x0A
    RETC                        equ 0x0D

    ; Strings
    HEX_OUT                     db "0x0000", ENDL, RETC, 0
    KERNEL_START_MSG            db "Starting kernel!", ENDL, RETC, 0
    DISK_READ_ERR_MSG           db "Unable to read disk", ENDL, RETC, 0
    FS_ERROR_MSG                db "Filesystem does not appear to be valid", ENDL, RETC, 0
    ABORT_RETRY_MSG             db "Abort? Retry? A/R", ENDL, RETC, 0
    KERNEL_LOOP_MSG             db "No program is loaded, enter program name or press Ctr Alt Del to reboot", ENDL, RETC, '://', 0

    ; WARNING! None of the DISK or FS values are ment to be set directly use DISK_INIT and FS_INIT instead
    ; setting those values directly will almost certantly result in a crash

    ; Disk values 
    DISK_STATE                  db 0    ;Current disk state 0 - non initialized 1 - initialized         
    DISK_HEADS                  db 0    ;Current disk heads amount  
    DISK_SEC_PER_TRACK          dw 0    ;Current disk sectors per track                        
    DISK_NUM                    db 0    ;Current disk number                                          

    ; Filesystem values
    FS_STATE                    db 0    ; State of the file system 0 - non initialized 1 - initialized
    FS_TYPE                     db 0    ; FAT Type 0 - FAT12 1 - FAT16 
    FS_FAT_SECTORS              db 0    ; Number of sectors occupied by FAT
    FS_FAT_START_SEC            dw 0    ; Start sector of FAT
    FS_ROOT_DIR_START_SEC       db 0    ; Start sector of root directory
    FS_ROOT_DIR_SECTORS         db 0    ; Number of sectors ocupied by root directory
    FS_DATA_START_SEC           db 0    ; Start sector of data region 
    FS_DATA_SECTORS             dw 0    ; Number of sectors ocupied by data region
    FS_TOTAL_CLUSTERS           dw 0    ; Total amount of clusters in the filesystem

    ; Filesystem bootsector
    FS_BOOTSECTOR:
    BS_JmpBoot      times 3     db 0

    BS_OEMName      times 8     db 0
    BPB_BytesPerSec             dw 0
    BPB_SecPerClus              db 0
    BPB_RsvdSecCnt              dw 0
    BPB_FatNum                  db 0
    BPB_RootEntCnt              dw 0
    BPB_TotalSecCnt             dw 0
    BPB_Media_Desc_Type         db 0
    BPB_SecPerFat               dw 0
    BPB_SecPerTrack             dw 0
    BPB_Heads                   dw 0
    BPB_HiddenSectors           dd 0
    BPB_LargeSecCnt             dd 0
    EBR_BootDrvNumber           db 0
                                db 0
    EBR_Signature               db 0
    EBR_VolumeId    times 4     db 0
    EBR_VolumeLbl               db 0
    EBR_SysId                   db 0               

    ; Buffers
    FS_DIR_ENTRY    times 32    db 0    ; Current Directory Entry
    FS_FAT          times 9300  db 0    ; FAT
    
    KBD_BUFFER      times 64    db 0    ; Keyboard buffer

[SECTION .text]
    KERNEL_START:
        mov ax, 0x1000 ;initialize new stack
        mov sp, ax
        mov bp, sp

        mov si, KERNEL_START_MSG
        call PRINT

        call FREE_BOOTSECTOR

        call DISK_INIT

        call FS_INIT

        jmp KERNEL_LOOP

    KERNEL_LOOP:
        mov si, KERNEL_LOOP_MSG
        call PRINT

        mov dh, 0
        mov di, KBD_BUFFER
        call KBD_READ
        mov ah, 0x0e
        mov al, RETC
        int 10h
        mov al, ENDL
        int 10h

        jmp KERNEL_LOOP

    PRINT:
        pusha
        mov ah, 0x0e

        .loop:
        lodsb
        cmp al, 0
        je .done
        int 0x10
        jmp .loop

        .done:                 
        popa
        ret

    PRINT_HEX:      ;Value to print - DX
        pusha
        mov ah, 0x0e
        mov cx, 4

        .loop:
        dec cx
        mov ax, dx
        shr dx, 4
        and ax, 0xF
        mov bx, HEX_OUT
        add bx, 2
        add bx, cx
        cmp ax, 0xA
        jl .set_letter
        add byte [bx], 7

        .set_letter:
        add byte [bx], al
        cmp cx, 0
        je .done
        jmp .loop

        .done:
        mov si, HEX_OUT
        call PRINT
        mov bx, HEX_OUT
        add bx, 2

        .reset_leter:
        mov byte[bx], 0x30
        inc bx
        cmp byte[bx], 0
        jne .reset_leter

        popa
        ret

    KBD_READ:   ; Reads keyboard input into buffer 
        push ax
        push bx
        push cx

        mov cx, di

        .loop:
        xor ax, ax
        int 16h
        cmp ah, 0x1c
        je .done
        cmp ah, 0x0e
        je .backspace
        mov byte[es:di], al
        cmp dh, 0
        jne .skip
        mov ah, 0x0e
        int 10h

        .skip:
        inc di
        jmp .loop

        .backspace:
        cmp di, cx
        je .loop
        dec di
        mov byte[es:di], 0
        cmp dh, 0
        jne .loop
        mov ah, 0x0e
        int 10h
        jmp .loop

        .done
        pop cx
        pop bx
        pop ax
        ret

    DISK_INIT:  ; Initialize disk parameters DL - drive number
        pusha 
        push es

        mov [DISK_NUM], dl  ; Initializing boot sector
        xor ax, ax
        mov es, ax
        mov di, ax
        mov ah, 0x08
        int 13h
        jc .err

        mov byte[DISK_HEADS], dh
        and cl, 0x3f
        xor ch, ch
        mov word[DISK_SEC_PER_TRACK], cx

        mov byte[DISK_STATE], 1
        jmp .done

        .err:
        mov byte[DISK_STATE], 0
        call DISK_READ_ERROR
        jc .done
        mov byte[DISK_STATE], 1

        .done:
        pop es
        popa 
        ret 

    FS_INIT: ; Initialize file system on the current disk.
        pusha
        
        .loop:
        mov ax, 0
        mov bx, FS_BOOTSECTOR
        mov cx, 1
        call READ_LBA

        mov bx, FS_BOOTSECTOR
        add bx, 510
        cmp word[ds:bx], 0xaa55
        jne .err

        mov ax, word[BPB_HiddenSectors]    ; Calculating FAT values
        mov word[FS_FAT_START_SEC], ax
        mov ax, [BPB_FatNum]
        mov bx, [BPB_SecPerFat]
        mul bx
        mov byte[FS_FAT_SECTORS], al

       ;mov ax, [FS_FAT_SECTORS]           ; Calculating root dir values
        add ax, [FS_FAT_START_SEC]
        mov [FS_DATA_START_SEC], al

        mov ax, [BPB_RootEntCnt]
        shl ax, 5
        xor dx, dx
        div word[BPB_BytesPerSec]

        test dx, dx
        jz .skip
        inc ax
        .skip:

        mov [FS_ROOT_DIR_SECTORS], al

        ;mov ax, [FS_ROOT_DIR_SECTORS]      ; Calculating data region values
        add ax, [FS_ROOT_DIR_START_SEC]
        mov [FS_DATA_START_SEC], al
        mov ax, [FS_BOOTSECTOR + 19]
        sub ax, [FS_DATA_START_SEC]
        mov [FS_DATA_SECTORS], ax

        mov bx, [BPB_SecPerClus]           ; Calcultaing total amount of clusters
        xor dx, dx 
        div bx
        mov [FS_TOTAL_CLUSTERS], ax

        mov ax, [FS_FAT_START_SEC]          ; Reading FAT to memory
        mov cx, [FS_FAT_SECTORS]
        mov bx, FS_FAT
        call READ_LBA
        jc .err

        mov ax, [FS_TOTAL_CLUSTERS]
        cmp ax, 4085                        ; Determination of FAT subtype
        jle .FAT12
        mov byte[FS_TYPE], 1
        cmp ax, 65526
        jge .err

        .FAT12:
        mov byte[FS_TYPE], 0

        mov byte[FS_STATE], 1
        jmp .done

        .err:
        mov byte[FS_STATE], 0
        call FS_ERROR
        jc .done
        jmp .loop

        .done:
        popa
        ret


    READ_LBA:   ; Reads sector by it's LBA
        push cx ;CX - amount of sectors to read
        push bx ;BX - buffer
        push ax ;AX - LBA NO 
        
        mov ax, word[DISK_HEADS]
        mul word[DISK_SEC_PER_TRACK]
        mov bx, ax
        pop ax
        xor dx, dx
        div bx ;At this moment AX is Cylinder DX is temp

        push ax

        mov ax, dx
        xor dx, dx
        div word[DISK_SEC_PER_TRACK]
        inc dx ;At this moment AX is head DX is sector

        mov cx, dx ; CL - sector
        xor dx, dx
        mov dh, al ; DH - head

        pop bx  
        mov ch, bl ; CH - cylinder

        pop bx
        pop ax
        mov ah, 0x02
        mov dl, [DISK_NUM]

        int 13h
        jc .err

        ret
    
        .err:
        call DISK_READ_ERROR
        ret

    DISK_READ_ERROR:    ; Called when a disk error happends 
        pusha
        push ds
        mov ax, KERNEL_SEG
        mov ds, ax

        mov si, DISK_READ_ERR_MSG
        call PRINT

        call ABORT_RETRY
        jnc .retry

        .abort:
        pop ds
        popa 
        ret

        .retry:
        pop ds
        popa
        int 13h
        jc DISK_READ_ERROR
        ret

    FS_ERROR:   ; Called when a filesystem error happends 
        pusha
        push ds 
        mov ax, KERNEL_SEG
        mov ds, ax

        mov si, FS_ERROR_MSG
        call PRINT
        call ABORT_RETRY

        pop ds
        popa
        ret

    FREE_BOOTSECTOR:    ; Free memory ocupied by bootsector
        pusha
        push es

        xor ax, ax
        mov es, ax
        mov bx, 0x7b00

        .loop:
        mov word[es:bx], 0x0000
        cmp bx, 0x8000
        je .done
        add bx, 2
        jmp .loop

        .done:
        pop es
        popa
        ret

    ABORT_RETRY:    ; Carry flag set if retry not set if abort
        pusha
        push ds
        mov ax, KERNEL_SEG
        mov ds, ax

        mov si, ABORT_RETRY_MSG
        call PRINT

        .loop:          ; This piece of code here is garbage! Never use something like that
        xor ax, ax
        int 16h
        cmp al, 'A'
        je .setc
        cmp al, 'a'
        je .setc
        cmp al, 'R'
        je .done
        cmp al, 'r'
        je .done
        jmp .loop

        .done:
        pop ds
        popa
        ret

        .setc:
        stc
        pop ds
        popa
        ret

