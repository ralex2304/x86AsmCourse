CFLAGS_SANITIZER = -fsanitize=address,alignment,bool,bounds,enum,float-cast-overflow,$\
				   float-divide-by-zero,integer-divide-by-zero,leak,nonnull-attribute,null,$\
				   object-size,return,returns-nonnull-attribute,shift,signed-integer-overflow,$\
				   undefined,unreachable,vla-bound,vptr

all: asm link run

asm:
	@nasm -f elf64 -l ./prog.lst ./prog.nasm -o prog.o

link:
	@g++ $(CFLAGS_SANITIZER) -no-pie -o ./prog ./prog.o

run:
	@./prog
