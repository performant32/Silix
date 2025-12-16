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
fat_heads: dw 2
fat_hidden_sectors: dd 0
fat_large_sector_count:dd 0

struc DirectoryEntry
    .fileName: resb 11
    .attributes: resb 1
    .reserved: resb 1
    .creationTime: resb 1
    .creationDate: resw 1
    .dateCreated: resw 1
    .lastAccessed: resw 1
    .unused: resw 1
    .lastModificationTime: resw 1
    .lastModificationDate: resw 1
    .lastSize: resw 2
endstruc

start:
    cli
    mov ax, 0x7BFF
    mov ss, ax
    mov ax, 0
    mov ds, ax
    mov es, ax

    cld
    jmp 0x0000:main
main:
    enter 8

    ; Printing current drive
    ; TODO:
    mov dl, 0xe0
    mov si, stage2_filename
    call load_stage2
    cli
.loop:
    hlt
    jmp .loop
;LBA to CHS scheme
; Parameters
;   ax - LBA Address
; return values
;   ch - clyinder
;   dh - head
;   cl - sector
lba_to_chs:
    test ax, 0xFFFF
    jnz .Calc
    mov al, 0
    mov dh, 0
    mov cl, 1
    mov si, msg_zero
    call print_string
    ret
.Calc:
    enter 0
    mov [bp - 4], ax
    div byte [fat_sectors_per_track]
    mov [bp - 6], al
    inc ah 
    mov cl, ah
    mov ah, 0
    div byte[fat_sectors_per_track]
    mov dh, ah
    mov ax, [bp - 6]
    mov ah, 0
    div byte [fat_heads]
    mov ch, al
    leave
    ret

    ;mov [bp - 2], ax
    ;div word fat_sectors_per_track
    ;mov [bp - 4], ax
    ;div word fat_sectors_per_track
    ;mov dh, ah
    ;mov al, [bp - 4]
    ;mov bl, fat_sectors_per_track
    ;div bl
    ;add ah, 1
    ;mov cl, ah
    ;mov al, [bp - 4]
    ;div word fat_heads_per_side 
    ;ret
; Reads Stage2 from the floppy into 0x7D00
; Parameters
;   si- fileName
load_stage2:
    enter DirectoryEntry_size
    ; Loading Directory Entries in to memory
    mov ax, 20
    call lba_to_chs
.ReadSectors:
    mov ah, 0x2
    mov al, 1
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
    mov si, msg_success
    call print_string
    mov si, 0x7E00
    call print_string
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
    push ax
    mov ah, 0x0e
.Loop:
    lodsb
    cmp al, 0
    je .Finish
    int 0x10
    jmp .Loop
.Finish:
    pop ax
    ret
times 446 - ($-$$) db 0
; Data
%define ENDL 13, 10
stage2_filename: db "STAGE2   BIN"
msg_read_sectors_failed: db "Read Sectors Failed", ENDL, 0x00
msg_success:db "si", ENDL, 0x00
msg_zero:db "div err", ENDL, 0x00
times 510 - ($-$$) db 0
;db 0x55, 0xAA
dw 0xAA55
