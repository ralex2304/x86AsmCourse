

all: asm link run

asm:
	@nasm -f elf64 -l ./prog.lst ./prog.nasm

link:
	@ld -s -o ./prog ./prog.o

run:
	@./prog
