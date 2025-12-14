bits 16
section .STAGE2
extern _start
start:
    jmp _start
    cli
    hlt
global _print
_print:
    mov ah, 0x0E
    mov al, '5'
    int 0x10
    ret
