section .text

global main
extern printf

main:       enter 0, 0

            lea rdi, [rel Str]
            lea rsi, [rel Meow]
            mov rax, 0
            call printf wrt ..plt

            leave
            ret

section .data

Str:        db "Hello printf! %s", 0x0a, 0
Meow:       db "Meow", 0
