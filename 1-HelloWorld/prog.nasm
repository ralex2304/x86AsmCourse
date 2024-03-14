section .text

global _start ; entry point

_start:     mov rax, 0x01       ; sys_write
            mov rdi, 1          ; file descr - stdout
            lea rsi, [rel Msg]  ; buffer
            mov rdx, MsgLen     ; buffer len
            syscall

            mov rax, 0x3c       ; sys_exit
            xor rdi, rdi        ; error_code = 0
            syscall

section .data

Msg:        db "Hello asm", 0x0a
MsgLen:     equ $ - Msg

