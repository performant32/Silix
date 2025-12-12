bits 16
org 0x7C00
start:
    cli
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov ax, 0xFFFF
    mov es, ax
    jmp 0x0000:main
main:
    lea si, [ds:msg_booting]
    call print_string
    
    call get_drive_parameters
    cli
.loop:
    hlt
    jmp .loop
; Registers Changed
;   ah, dl
get_drive_parameters:
    enter 16

    ; Get Drive Parameters
    mov ah, 0x8
    mov dl, 0x0
    mov di, 0   ; Some buggy BIOS
    int 0x13
    
    jc .PrintError
.ReadSectors:
    lea si, msg_reading_sectors
    call print_string
    ; Settings up DAP
    mov ax, 0
    mov es, ax
    mov [word bp - 16], 0x0010
    mov [word bp - 14], 1
    mov [word bp - 12], 0
    mov [word bp - 10], es
    mov [word bp - 8], 0
    mov [word bp - 4], 0
    ; Calling Read Sectors
    mov ah, 0x42
    mov dl, 0x0
    mov si, [bp-8]
    int 0x13

    ; Checking Errors
    jnc .Done
    sub sp, 8
.PrintError:
    lea si, [ds:msg_parameter_error]
    call print_string
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
; Parameters sued
;   SI - source
;   dx - n
; Registers Changed
print_string_n:
    push cx
    mov ah, 0x0e
.Loop:
    lodsb
    cmp cx, dx
    je .Finish
    int 0x10
    inc cx
    jmp .Loop
.Finish:
    pop cx
    ret
times 446 - ($-$$) db 0
; Data
%define ENDL 13, 10
msg_booting: db "Booting", ENDL, 0x00
msg_parameter_error: db "Error reading drive", ENDL, 0x00
msg_reading_sectors: db "Reading Sectors", ENDL, 0x00
msg_success: db "Success", ENDL, 0x00
times 510 - ($-$$) db 0
;db 0x55, 0xAA
dw 0xAA55
