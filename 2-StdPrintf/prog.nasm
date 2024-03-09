section .text

global main
extern printf

main:       enter 0, 0

            mov rdi, Str
            mov rsi, Meow
            mov rax, 0
            call printf

            pop rbp

            leave
            ret

section .data

Str:        db "Hello printf! %s", 0x0a, 0
Meow:       db "Meow", 0
