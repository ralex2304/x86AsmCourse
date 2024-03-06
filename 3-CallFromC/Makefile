CFLAGS_SANITIZER = -fsanitize=address,alignment,bool,bounds,enum,float-cast-overflow,$\
				   float-divide-by-zero,integer-divide-by-zero,leak,nonnull-attribute,null,$\
				   object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,$\
				   undefined,unreachable,vla-bound,vptr

all: asm build link run

asm:
	@nasm -f elf64 -l ./prog.lst ./prog.nasm -o prog.o

build:
	@g++ $(CFLAGS_SANITIZER) -o main.o -c main.cpp

link:
	@g++ $(CFLAGS_SANITIZER) -no-pie -o ./prog ./prog.o ./main.o

run:
	@./prog
