# x86-64 linux asm course programs

All assembly programs are written for `x86-64` `linux`, assembled with `nasm` and linked with `gcc`

## 1 - HelloWorld

Prints `Hello asm` to `stdout`

## 2 - StdPrintf

`stdlib`'s `printf` call from assembly code.

Especially, `printf("Hello printf! %s\n", "Meow")`

## 3 - CallFromC

Assembly function call from C++ code.

Function proto: `long substract(long a, long b)`

Mangled name: `_Z9substractll`

Programs prints result of `a - b`

## 4 - AsmPrintf

Assembly implementation of `printf`

```
int myprintf(const char* format, ...)
```

### Available specifiers

| # | Spec | Description |
|---|------|-------------|
| 1 | `%c` | single ASCII character
| 2 | `%d` | signed decimal integer
| 3 | `%b` | unsigned binary integer
| 4 | `%o` | unsigned octal integer
| 5 | `%x` | unsigned hexadecimal integer
| 6 | `%f` | signed double precision floating point number (with fixed precision `1e-6`)
| 7 | `%s` | null-terminated string
| 8 | `%%` | `%` symbol
| 9 | `%n` | writes number of characters written so far to `int*`

### Examples

```
int ret = myprintf("%d %s %x %d%%%c%b\n", -1, "love", 3802, 100, 33, 127);
----------
ret = 29
----------
-1 love 0xeda 100%!0b1111111

```
```
int ret = myprintf("%f\n", -1.25);
----------
ret = 10
----------
-1.250000

```
```
int res = 0;
int ret = 0;
ret = myprintf("abc%ndef\n", &res);
----------
abcdef

----------
# res = 3
# ret = 7
```

# Usage

Each program has it's own Makefile. Simply use `make` to build and run

# Literature and tools

1. **Computer Systems: A Programmer's Perspective** 3rd Edition by **Randal Bryant**, **David O'Hallaron**
2. **Compiler explorer** - [godbolt.com](https://godbolt.com)
3. **Glibc and System Call** docs - [readthedocs.io](https://sys.readthedocs.io/en/latest/index.html)

# Credits
- [Ilya Dedinsky](https://github.com/ded32) aka Ded as prepod
- [Aleksei Durnov](https://github.com/Panterrich) as mentor
