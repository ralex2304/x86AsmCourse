segment .text

;=================================================
; sys_write macro
;
; Args:     %1 - buffer
;           %2 - buffer size
;
; Destr:    rax, rcx, rdx, rdi, rsi, r11
;=================================================

%macro SYS_WRITE 2
            mov rax, 0x01   ; sys_wryte
            mov rdi, 0x01   ; stdout
            mov rsi, %1     ; buffer
            mov rdx, %2     ; buffer size
            syscall
%endmacro

;=================================================

;=================================================
; flushes Buffer to stdout
;
; Args:     r13 - buffer size
;
; Destr:    rax = 0x01
;           rdi = 0x01
;           rsi = offset Buffer
;           rcx
;           r11
;=================================================
%macro FLUSH_BUFFER 0
            push rdx

            SYS_WRITE Buffer, r13

            ; reset buffer size
            mov dword [BufferSize], 0
            xor r13, r13

            pop rdx
%endmacro
;=================================================

;=================================================
; Flushes buffer if buffer is not empty
;
; Assumes:  r13 - buffer size
;
; Destr:    rax, rdi, rsi, rcx, r11
;=================================================
%macro  FLUSH_IF_NEEDED 0

            test r13, r13 ; cmp r13, 0
            je %%isEmptyBuf

            FLUSH_BUFFER
%%isEmptyBuf:

%endmacro
;=================================================


;=================================================
; Writes one symbol to Buffer
;
; Args:     %1 - symbol to write
;
; Assumes:  r13 - buffer size
;
; Destr:    rax, rdi, rsi, rcx, r11
;=================================================
%macro WRITE_TO_BUF 1

            cmp r13, BufCapacity
            jb %%noFlush

            FLUSH_BUFFER
%%noFlush:

            mov byte [Buffer + r13], %1
            inc r8d
            inc r13
%endmacro
;=================================================

;=================================================
; Checks if current argument is on border between reg and stack arguments
;=================================================
%macro CHECK_REG_STACK_ARGS_BORDER 0

            test r15, r15
            jne %%Float
            ; no float

            cmp r10, rbp
            jne %%Exit
            add r10, 16 + 8 * SavedArgs ; ret + ret2 + SavedArgs

            jmp %%Exit
%%Float:
            lea rax, [rbp - 64]

            cmp r10, rax
            jne %%Exit

            cmp r14, rbp
            jb %%XmmArgsExist

            mov r10, r14
            jmp %%Exit

%%XmmArgsExist:
            lea r10, [rbp + 16 + 8 * SavedArgs] ; ret + ret2 + SavedArgs


%%Exit:
%endmacro
;=================================================

;=================================================
; Checks if current argument is on border between reg and stack arguments
;=================================================
%macro CHECK_REG_STACK_FLOAT_ARGS_BORDER 0

            neg r15
            lea rax, [rbp + 8 * r15] ; rbp - 8 * r15
            neg r15

            cmp r14, rax
            jae %%NotXmmArgsExist

            cmp r10, rbp
            jae %%NotRegsArgsExist

            lea r14, [rbp + 16 + 8 * SavedArgs] ; ret + ret2 + SavedArgs

            jmp %%NotXmmArgsExist
%%NotRegsArgsExist:
            mov r14, r10

%%NotXmmArgsExist:
%endmacro
;=================================================

;=================================================
; Increments args pointers
;=================================================
%macro INC_ARGS_PTRS 0

            cmp r10, rbp
            jb %%regsLeft
            cmp r14, rbp
            jb %%regsLeft

            add r14, 8
%%regsLeft:
            add r10, 8
%endmacro
;=================================================

;-------------------------------------------------
; int __stdcall myprintf(const char* format, ...);
;
;
; Destr: rax, rcx, rdx, rsi, rdi, r8d, r9, r10, r11
;
;-------------------------------------------------
global _Z8myprintfPKcz
_Z8myprintfPKcz:

SavedArgs   equ 5 ; !!! needed for stack args addr calc
            push rbx
            push r12
            push r13
            push r14
            push r15

            push rbp
            mov rbp, rsp

            ; push register arguments (only variadic)

            xor r15, r15
            xor r14, r14

            test al, al
            je .noFloats

            movq [rsp - 8],  xmm0
            movq [rsp - 16], xmm1
            movq [rsp - 24], xmm2
            movq [rsp - 32], xmm3
            movq [rsp - 40], xmm4
            movq [rsp - 48], xmm5
            movq [rsp - 56], xmm6
            movq [rsp - 64], xmm7

            lea r14, [rsp - 8]          ; r14 = rsp         - float args stack ptr
            mov r15b, al                ; r15 = al          - number of floats in xmm's

            sub rsp, 64

.noFloats:
            push r9
            push r8
            push rcx
            push rdx
            push rsi
            mov r9, rdi

            mov r10, rsp                ; r10 = rsp         - args stack ptr

            xor rbx, rbx ; required for jump table lea [rbx + const]

            mov r13d, dword [BufferSize]; r13 = [BufSize]   - buffer size
            mov bl, [r9]                ; bl  = [r9]        - current fmt symbol
            xor r8, r8                  ; r8d = 0           - symbol counter
                                        ; r9                - format string ptr
            jmp .whileFmtEnter
.whileFmtBody:

            cmp bl, '%'
            jne .NotSpecialSymbol

            ; go to next format symbol
            inc r9
            mov bl, [r9]

            ; main switch
            ; options in ASCII order: %, <large gap>, b,  c,  d,  f,  o,  s,  x
            ;                         37              98  99 100 102 111 115 120
            cmp bl, '%'
            jne .is_not_percent
            WRITE_TO_BUF bl
            jmp .switch_end
.is_not_percent:

            cmp bl, 'b'
            jb .spec_error
            cmp bl, 'x'
            ja .spec_error

            mov rcx, printf_jmp_table[(rbx - 'b') * 8]
            jmp rcx

.spec_char: call printf_spec_char
            jmp .switch_end
.spec_bin:  call printf_spec_binary
            jmp .switch_end
.spec_oct:  call printf_spec_octal
            jmp .switch_end
.spec_dec:  call printf_spec_decimal
            jmp .switch_end
.spec_hex:  call printf_spec_hex
            jmp .switch_end
.spec_str:  call printf_spec_string
            jmp .switch_end
.spec_float:call printf_spec_float
            jmp .switch_end


.spec_error:
            SYS_WRITE UnknownSpecErrorMsg, UnknownSpecErrorMsgLen
            mov eax, -1
            jmp .return
.switch_end:


            jmp .whileFmtClause
.NotSpecialSymbol:
            WRITE_TO_BUF bl

.whileFmtClause:
            inc r9
            mov bl, [r9]
.whileFmtEnter:
            test bl, bl ; cmp bl, 0
            jne .whileFmtBody


            ; flush buffer
            FLUSH_IF_NEEDED

            mov dword [BufferSize], 0

            mov eax, r8d
.return:
            leave

            pop r15
            pop r14
            pop r13
            pop r12
            pop rbx
            ret
;-------------------------------------------------



;-------------------------------------------------
; prints char from argument
;
; Args:     r10 - args stack ptr
;           r13 - buffer size
;           r8d - symbol counter
;           r9  - format string ptr
;
; Destr:    bl, rax, rdi, rsi, rcx, r11
;-------------------------------------------------
printf_spec_char:

            CHECK_REG_STACK_ARGS_BORDER

            mov bl, [r10]
            WRITE_TO_BUF bl

            INC_ARGS_PTRS

            ret
;-------------------------------------------------

;-------------------------------------------------
; prints string from argument
;
; Args:     r10 - args stack ptr
;           r13 - buffer size
;           r8d - symbol counter
;           r9  - format string ptr
;
; Destr:    bl, rax, rdi, rsi, rcx, r11, r12
;-------------------------------------------------
printf_spec_string:

            CHECK_REG_STACK_ARGS_BORDER

            mov r12, [r10]
            mov bl, [r12]

            jmp .whileEnter
.whileBody:
            WRITE_TO_BUF bl


            inc r12
            mov bl, [r12]
.whileEnter:
            test bl, bl ; cmp bl, 0
            jne .whileBody

            INC_ARGS_PTRS

            ret
;-------------------------------------------------

;-------------------------------------------------
; prints decimal argument
;
; Args:     r10 - args stack ptr
;           r13 - buffer size
;           r8d - symbol counter
;
; Destr:    rax, rbx, rcx, rdx, rdi, rsi, r11, r12
;-------------------------------------------------
printf_spec_decimal:

            CHECK_REG_STACK_ARGS_BORDER

            mov eax, [r10]

            test eax, eax
            jge .isPositive

            ; is negative
            push rax
            WRITE_TO_BUF '-'
            pop rax

            neg eax

.isPositive:

            push rax
            FLUSH_IF_NEEDED
            pop rax

            lea r13, [Buffer + BufCapacity - 1] ; r13 - output str pointer

            mov r12d, 10 ; base
.whileBody:
            xor rdx, rdx
            div r12d
            ; eax = div
            ; edx = mod

            mov dl, HexTable[rdx]
            mov byte [r13], dl
            dec r13

.whileClause:
            test eax, eax
            jne .whileBody

            mov r11, Buffer + BufCapacity - 1
            sub r11, r13

            push r11

            inc r13
            SYS_WRITE r13, r11

            pop r11
            add r8, r11

            xor r13, r13 ; buffer is flushed

            INC_ARGS_PTRS

            ret
;-------------------------------------------------

;=================================================
; printf spec functions template
;
; Args:     %1 - max number of digits
;           %2 - bits in one digit
;           %3 - bit mask for one digit
;
; Assumes:  rax (higher half) - number
;           r10 - args stack ptr
;           r13 - buffer size
;           r8d - symbol counter
;
; Destr:    rax, rbx, rcx, rdx, rdi, rsi, r11, r12
;=================================================
%macro PRINTF_SPEC_TEMPLATE 3

            test rax, rax
            jne %%notNull

            WRITE_TO_BUF '0'

            jmp %%whileBreak

%%notNull:
            xor r12, r12 ; counter
            xor bl, bl

%%whileBody:
            cmp r12, %1 ; sizeof
            jae %%whileBreak

            rol rax, %2
            mov ecx, eax
            and ecx, %3
            inc r12

            test bl, bl
            jne %%printSymbol

            test ecx, ecx
            je %%whileBody

            inc bl ; bl = 1
%%printSymbol:

            mov cl, HexTable[ecx]
            WRITE_TO_BUF cl

            jmp %%whileBody
%%whileBreak:

            INC_ARGS_PTRS

            ret
%endmacro
;=================================================

;-------------------------------------------------
; printf binary
;
; Assumes:  rax (higher half) - number
;           r10 - args stack ptr
;           r13 - buffer size
;           r8d - symbol counter
;
; Destr:    rax, rbx, rcx, rdx, rdi, rsi, r11, r12
;-------------------------------------------------
printf_spec_binary:
            WRITE_TO_BUF '0'
            WRITE_TO_BUF 'b'

            CHECK_REG_STACK_ARGS_BORDER
            mov eax, [r10]
            shl rax, 32
            PRINTF_SPEC_TEMPLATE 32, 1, 0b1

;-------------------------------------------------
; printf octal
;
; Assumes:  rax (higher half) - number
;           r10 - args stack ptr
;           r13 - buffer size
;           r8d - symbol counter
;
; Destr:    rax, rbx, rcx, rdx, rdi, rsi, r11, r12
;-------------------------------------------------
printf_spec_octal:
            WRITE_TO_BUF '0'

            CHECK_REG_STACK_ARGS_BORDER
            mov eax, [r10]
            shl rax, 31
            PRINTF_SPEC_TEMPLATE 11, 3, 0b111

;-------------------------------------------------
; printf hex
;
; Assumes:  rax (higher half) - number
;           r10 - args stack ptr
;           r13 - buffer size
;           r8d - symbol counter
;
; Destr:    rax, rbx, rcx, rdx, rdi, rsi, r11, r12
;-------------------------------------------------
printf_spec_hex:
            WRITE_TO_BUF '0'
            WRITE_TO_BUF 'x'

            CHECK_REG_STACK_ARGS_BORDER
            mov eax, [r10]
            shl rax, 32
            PRINTF_SPEC_TEMPLATE 8, 4, 0b1111

;-------------------------------------------------
; printf float
;
; Assumes:  rax (higher half) - number
;           r10 - args stack ptr
;           r13 - buffer size
;           r8d - symbol counter
;
; Destr:    rax, rbx, rcx, rdx, rdi, rsi, r11, r12, xmm0, xmm1
;-------------------------------------------------
printf_spec_float:

            CHECK_REG_STACK_FLOAT_ARGS_BORDER

            movq xmm0, [r14]                            ; xmm0 - double

            FLUSH_IF_NEEDED

            lea r13, [Buffer + BufCapacity - 1]         ; r13 - output str pointer

            movq rbx, xmm0                              ; rbx - raw xmm0
            test rbx, rbx
            jns .isPositive ; xmm0 >= 0

            movq xmm1, xmm0
            pxor xmm0, xmm0
            subsd xmm0, xmm1
.isPositive:

            cvttsd2si r11, xmm0 ; convert float to int  ; r11 - int part
            cvtsi2sd xmm1, r11
            subsd xmm0, xmm1
            mulsd xmm0, [double_1e6]
            cvttsd2si rax, xmm0                         ; rax - non-int part

            ; convert non-int part
            mov r12d, 10    ; base
            mov rcx, 6      ; width
.flWhileBody:
            xor rdx, rdx
            div r12d
            ; eax = div
            ; edx = mod

            mov dl, HexTable[rdx]
            mov byte [r13], dl
            dec r13
            dec rcx

            test rcx,rcx
            jne .flWhileBody

            mov byte [r13], '.'
            dec r13

            mov rax, r11                                ; rax - int part

            ; convert int part
.intWhileBody:
            xor rdx, rdx
            div r12d
            ; eax = div
            ; edx = mod

            mov dl, HexTable[rdx]
            mov byte [r13], dl
            dec r13

            test eax, eax
            jne .intWhileBody

            test rbx, rbx
            jns .isPositive2 ; xmm0 >= 0

            mov byte [r13], '-'
            dec r13
.isPositive2:

            mov r11, Buffer + BufCapacity - 1
            sub r11, r13

            push r11
            inc r13

            SYS_WRITE r13, r11

            pop r11
            add r8, r11
            xor r13, r13 ; buffer is flushed

            ; stack pointers increment
            cmp r14, rbp
            jb .xmmArgs

            add r14, 8

            cmp r10, rbp
            jb .regsLeft

            add r10, 8

.xmmArgs:   sub r14, 8

.regsLeft:
            ret
;-------------------------------------------------

;-------------------------------------------------
; Writes to buffer unsigned double from long with precision 10^6
;
; Args:     rax - number
;
; Assumes:  r13 - dest pointer
;           r8d - symbol counter
;
; Destr:    rax, rbx, rcx, rdx, rdi, rsi, r11
;-------------------------------------------------
ConvertDecDouble:
            mov r12d, 10 ; base

            mov rbx, 6

.whileBody:
            xor rdx, rdx
            div r12d
            ; eax = div
            ; edx = mod

            mov dl, HexTable[rdx]
            mov byte [r13], dl
            dec r13

            dec rbx

            test rbx, rbx
            jne .noDot

            mov byte [r13], '.'
            dec r13
.noDot:

.whileClause:
            test eax, eax
            jne .whileBody

            jmp .zeroWhileClause
.zeroWhileBody:

            mov byte [r13], '0'
            dec r13

            dec rbx

.zeroWhileClause:
            cmp rbx, 0
            jg .zeroWhileBody

            test rbx, rbx
            jne .noZero

            mov byte [r13], '.'
            dec r13
            mov byte [r13], '0'
            dec r13
.noZero:

            mov r11, Buffer + BufCapacity - 1
            sub r11, r13
            push r11

            inc r13
            SYS_WRITE r13, r11

            pop r11
            add r8, r11

            ret
;-------------------------------------------------

;+++++++++++++++++++++++++++++++++++++++++++++++++
segment .data


HexTable:   db "0123456789abcdef"

BufCapacity equ 64

Buffer:     times BufCapacity db 0
BufferSize: dd 0

;+++++++++++++++++++++++++++++++++++++++++++++++++
segment .rodata

UnknownSpecErrorMsg:    db "Printf error. Unknown format specified", 0x0a
UnknownSpecErrorMsgLen  equ $ - UnknownSpecErrorMsg

double_1e6:  dq 0x412e848000000000
double_1     equ 0x3ff0000000000000

; options in ASCII order: %, <large gap>, b,  c,  d,  f,  o,  s,  x
;                         37              98  99 100 102 111 115 120
printf_jmp_table:
            dq _Z8myprintfPKcz.spec_bin
            dq _Z8myprintfPKcz.spec_char
            dq _Z8myprintfPKcz.spec_dec
            times ('f' - 'd' - 1) dq _Z8myprintfPKcz.spec_error
            dq _Z8myprintfPKcz.spec_float
            times ('o' - 'f' - 1) dq _Z8myprintfPKcz.spec_error
            dq _Z8myprintfPKcz.spec_oct
            times ('s' - 'o' - 1) dq _Z8myprintfPKcz.spec_error
            dq _Z8myprintfPKcz.spec_str
            times ('x' - 's' - 1) dq _Z8myprintfPKcz.spec_error
            dq _Z8myprintfPKcz.spec_hex

