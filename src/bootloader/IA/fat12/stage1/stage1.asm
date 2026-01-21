bits 16
org 0x7C00  
jmp strict near start

; Fat12 Headers
fat_oem_name: db "MSWin4.1"
fat_bytes_per_sector: dw 512
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
    .firstLogicalCluster: resw 1
    .lastSize: resw 2
endstruc

start:
    cli
    mov ax, 0x8000
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
    mov si, msg_div_error
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
; Prints the error of bios function 13h, ah=02h
; Parameters
;   ah = error code
handle_read_error:
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
.Loop:
    hlt
    jmp .Loop
; Reads Stage2 from the floppy into 0x7D00
; Parameters
;   si- fileName
load_stage2:
    enter 40

    ; Loading addresses for LBA FAT, ROOT, ROOT sector count and LBA Data respectively
    mov bx, [fat_reserved_sector_count]
    mov [bp - 2], bx
    mov al, byte [fat_table_count]
    mov ah, 0
    mul byte [fat_sectors_per_fat] 
    add ax, bx
    mov [bp - 4], ax
    mov ax, [fat_root_dir_entries]
    mov bx, 32
    mul bx
    mov dx, 0
    dec ax
    add ax, [fat_bytes_per_sector]
    mov dx, 0
    div word [fat_bytes_per_sector]
    mov [bp - 6], ax
    add ax, [bp - 4]
    mov [bp - 8], ax
    mov ax, [bp - 4]
    ; Finding stage2
    call lba_to_chs

.ReadDirectories:
    mov ah, 0x2
    mov al, [bp - 4]
    mov dl, 0x0
    mov bx, 0x500
    int 0x13

    ; Checking Errors
    jc handle_read_error

    ; Read fat table
    mov dx, [fat_root_dir_entries]
    ; Root Entry Index
    mov word [bp - 10], 0xFFFF
    cld
.CompareFileName:
    mov cx, [bp - 10]
    inc cx
    cmp cx, dx
    je stage2_not_found
    mov ax, cx
    mov bx, 32
    push dx
    mul bx
    pop dx
    add ax, 0x500
    mov si, ax
    mov di, stage2_filename
    mov [bp - 10], cx
    mov cx, 0
    cld
.Loop:
    cmpsb
    jne .CompareFileName
    inc cx
    cmp cx, 11
    je .LoadFile
    jmp .Loop
.LoadFile:
    ; Getting sector
    mov ax, [bp - 10]
    sub ax, 2
    mul byte [fat_sectors_per_cluster]
    add ax, [bp - 8]
    mov ax, 30
    call lba_to_chs
    ; Loading
    mov ah, 0x2
    mov dl, 0
    mov bx, 0x7E00
    int 0x13

    ; Starting Stage2
    jmp 0x7E00:0000
stage2_not_found:
    mov si, msg_stage2_not_found
    call print_string
    cli
.Loop:
    hlt
    jmp .Loop
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
; Parameters used
;   SI - Source
;   DX - Count
write:
    push ax
    push cx
    mov ah, 0x0E
    mov cx, 0
.Loop:
    lodsb
    cmp cx, dx
    je .Done
    inc cx
    int 0x10
    jmp .Loop
.Done:
    pop cx
    pop ax
    ret
; Data
%define ENDL 13, 10
stage2_filename: db "STAGE2  BIN" 
msg_stage2_not_found: db "Stage2 Not Found", ENDL, 0x00
msg_read_sectors_failed: db "Read Sectors Failed", ENDL, 0x00
msg_div_error: db "Div error", ENDL, 0x00
times 446 - ($-$$) db 0
times 510 - ($-$$) db 0
;db 0x55, 0xAA
dw 0xAA55
