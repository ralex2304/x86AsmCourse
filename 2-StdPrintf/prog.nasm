section .text

global main
extern printf

main:       push rbp

            mov rdi, Str
            mov rsi, Meow
            mov rax, 0
            call printf

            pop rbp

            mov rax, 0
            ret

section .data

Str:        db "Hello printf! %s", 0x0a, 0
Meow:       db "Meow", 0
