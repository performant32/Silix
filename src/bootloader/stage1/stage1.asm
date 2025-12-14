bits 16
org 0x7C00  
jmp strict near start

; Fat12 Headers
fat_oem_name: db "MSWin4.1"
fat_bytes_per_cluster: dw 512
fat_sectors_per_cluster: db 1
fat_reserved_sector_count: dw 1
fat_table_count: db 2
fat_root_dir_entries:dw 224
fat_total_sectors: dw 2880
fat_media_descriptor_type: db 0xF0
fat_sectors_per_fat: dw 9
fat_sectors_per_track: dw 18
fat_heads_per_side: dw 2
fat_hidden_sectors: dd 0
fat_large_sector_count:dd 0
start:
    cli
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax

    cld
    jmp 0x0000:main
main:
    enter 8

    ; Printing current drive
    ; TODO:
    mov dl, 0xe0
    call get_drive_parameters
    cli
.loop:
    hlt
    jmp .loop
; Parameters
;   dl - drive number
; Registers Changed
;   ah
get_drive_parameters:
    enter 16
    mov [bp - 2], dl

    ; Get Drive Parameters
    mov ah, 0x8
    mov di, 0   ; Some buggy BIOS
    mov dl, 0x0
    int 0x13

    jnc .ReadSectors
    lea si, [ds:msg_parameter_error]
    call print_string
    jmp .Done
.ReadSectors:
    mov ax, 0
    mov es, ax
    mov ah, 0x2
    mov al, 1
    mov ch, 0
    mov cl, 16
    mov dh, 1
    mov dl, 0x0
    mov bx, 0x7E00
    int 0x13

    ; Checking Errors
    jnc .Success
    mov dl, ah
    mov ah, 0x0E
    mov al, dl
    and al, 0b11110000
    shr al, 4
    add al, '0'
    int 0x10
    mov al, dl
    and al, 0b1111
    add al, '0'
    int 0x10
    mov si, msg_read_sectors_failed
    call print_string
    jmp .Done
.Success: 
    push es
    push bx
    retf
.Done:
    leave
    ret
; Parameters used
;   SI - source
; Registers Changed
;   
print_string:
    mov ah, 0x0e
.Loop:
    lodsb
    cmp al, 0
    je .Finish
    int 0x10
    jmp .Loop
.Finish:
    ret
times 446 - ($-$$) db 0
; Data
%define ENDL 13, 10
msg_parameter_error: db "Error reading drive", ENDL, 0x00
msg_read_sectors_failed: db "Read Sectors Failed", ENDL, 0x00
msg_success: db "Success", ENDL, 0x00
times 510 - ($-$$) db 0
;db 0x55, 0xAA
dw 0xAA55
