bits 16
section .STAGE2
extern _start
extern _PrintString
start:
    call _start
    push 0
    push test
    call _PrintString
    cli
    hlt
section .data 
times 12 db 0
test: db "Fully Loaded", 0x00
