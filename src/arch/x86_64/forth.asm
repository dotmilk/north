global start_forth
extern idt
bits 64
%define gdtCsSelector 0x08
%define r_stack_size 4096
%define stack_size 4096

%define F_IMMED 0x80         ; Immediate flag
%define F_HIDDEN 0x20        ; Hidden flag
%define F_LENMASK 0x1f       ; Length mask

%define link 0

; ---- header for forth definitions
; name - namelen - label - flags
%macro def 3-4 0
section .rodata
align 8
global name_%3
name_%3:
        dq link                 ; store previous head
%define link name_%3            ; this is new head
        db %4+%2                ; flags n length
        db %1                   ; the name
align 8
global %3
%endmacro

; ---- forth words in forth ----
; name - namelen - label - flags
%macro defword 3-4 0
        def %1,%2,%3,%4
%3:
        dq DOCOL                ; codeword - interpeter
%endmacro

; ---- forth words in assembly ----
; name - namelen - label - flags
%macro defcode 3-4 0
        def %1,%2,%3,%4
%3:
        dq code_%3              ; codeword - self label
section .text
global code_%3
code_%3:
%endmacro

%macro NEXT 0
        lodsq                ; RSI -> RAX : RSI +8
        jmp [rax]            ; go there
%endmacro

%macro PUSHRSP 1
        lea rbp, [rbp-8]     ; offset r_stack
        mov [rbp], %1        ; put val on r_stack
%endmacro

%macro POPRSP 1
        mov %1, [rbp]        ; get val from r_stack
        lea rbp, [rbp+8]     ; offset r_stack
%endmacro

                             ; AT&T Syntax
                             ; instr   source,dest
                             ; movl    (%ecx),%eax

                             ; Intel Syntax
                             ; instr   dest,source
                             ; mov     eax,[ecx]
section .text
align 8

DOCOL:
        PUSHRSP rsi          ; return ptr on r_stack
        add rax, 8           ; inc codeword ptr
        mov rsi, rax         ; to first instruction
        NEXT

section .text

start_forth:
        cld                  ; SI DI Inc on String
        mov rbp, r_stack_top ; point to return stack
        mov rsp, stack_top   ; point to the stack
        mov [var_SZ], rsp    ; save a pointer to stack top
        push rax
        push rcx
        push rdx
        call clear_screen    ;
        ; pop rdx
        ; pop rcx
        ; pop rax
        mov rsi, cold_start  ; init interpreter
        NEXT                 ; run

section .rodata
cold_start:
        dq DBG

        defcode "DROP",4,DROP
        pop rax
        NEXT

        defcode "SWAP",4,SWAP
        pop rax
        pop rbx
        push rax
        push rbx
        NEXT

        defcode "DUP",3,DUP
        mov rax, [rsp]
        push rax
        NEXT

        defcode "OVER",4,OVER
        mov rax, [rsp + 8]
        push rax
        NEXT

        defcode "ROT",3,ROT
        pop rax
        pop rbx
        pop rcx
        push rax
        push rcx
        push rbx
        NEXT

        defcode "-ROT",4,NROT
        pop rax
        pop rbx
        pop rcx
        push rbx
        push rax
        push rcx
        NEXT

        defcode "2DROP",5,TWODROP
        pop rax
        pop rax
        NEXT

        defcode "2DUP",4,TWODUP
        mov rax, [rsp]
        mov rbx, [rsp+8]
        push rbx
        push rax
        NEXT

        defcode "2SWAP",5,TWOSWAP
        pop rax
        pop rbx
        pop rcx
        pop rdx
        push rbx
        push rax
        push rdx
        push rcx
        NEXT

        defcode "?DUP",4,QDUP
        mov rax, [rsp]
        test rax, rax
        jz .l1
        push rax
.l1:
        NEXT

        defcode "1+",2,INCR
        inc qword [rsp]
        NEXT

        defcode "1-",2,DECR
        dec qword [rsp]
        NEXT

        defcode "4+",2,INCR4
        add qword [rsp], 4
        NEXT

        defcode "8+",2,INCR8
        add qword [rsp], 8
        NEXT

        defcode "4-",2,DECR4
        sub qword [rsp], 4
        NEXT

        defcode "8-",2,DECR8
        sub qword [rsp], 8
        NEXT

        defcode "+",1,ADD
        pop rax
        add [rsp], rax
        NEXT

        defcode "-",1,SUB
        pop rax
        sub [rsp], rax
        NEXT

        defcode "*",1,MUL
        pop rax
        pop rbx
        imul rbx,rax
        push rax
        NEXT

        defcode "/MOD",4,DIVMOD
        xor rdx, rdx
        pop rbx
        pop rax
        idiv rbx
        push rdx
        push rax
        NEXT

; common ops for comparisons
%macro cmp2 0
        pop rax
        pop rbx
        cmp rax, rbx
%endmacro
; put result on stack
%macro pushCmp 0
        movzx rax, al
        push rax
%endmacro

        defcode "=",1,EQU
        cmp2
        sete al
        pushCmp
        NEXT

        defcode "<>",2,NEQU
        cmp2
        setne al
        pushCmp
        NEXT

        defcode "<",1,LT
        cmp2
        setl al
        pushCmp
        NEXT

        defcode ">",1,GT
        cmp2
        setg al
        pushCmp
        NEXT

        defcode "<=",2,LE
        cmp2
        setle al
        pushCmp
        NEXT

        defcode ">=",2,GE
        cmp2
        setge al
        pushCmp
        NEXT

; common ops for test
%macro tst 0
        pop rax
        test rax, rax
%endmacro

        defcode "0=",2,ZEQU
        tst
        setz al
        pushCmp
        NEXT

        defcode "0<>",3,ZNEQU
        tst
        setnz al
        pushCmp
        NEXT

        defcode "0<",2,ZLT
        tst
        setl al
        pushCmp
        NEXT

        defcode "0>",2,ZGT
        tst
        setg al
        pushCmp
        NEXT

        defcode "0<=",3,ZLE
        tst
        setle al
        pushCmp
        NEXT

        defcode "0>=",3,ZGE
        tst
        setge al
        pushCmp
        NEXT

        defcode "AND",3,AND
        pop rax
        and [rsp], rax
        NEXT

        defcode "OR",2,OR
        pop rax
        or [rsp], rax
        NEXT

        defcode "XOR",3,XOR
        pop rax
        xor [rsp], rax
        NEXT

        defcode "INVERT",6,INVERT
        not qword [rsp]
        NEXT

; returning from forth words
        defcode "EXIT",4,EXIT
        POPRSP rsi
        NEXT

; like next but push instead of jmp
        defcode "LIT",3,LIT
        lodsq
        push rax
        NEXT

; Direct Memory operations
        defcode "!",1,STORE
        pop rbx                 ; addr
        pop rax                 ; dat
        mov [rbx], rax
        NEXT

        defcode "@",1,FETCH
        pop rbx                 ; addr
        mov rax, [rbx]          ; get dat
        push rax                ; place on stack
        NEXT

        defcode "+!",2,ADDSTORE
        pop rbx                 ; addr
        pop rax                 ; operand 1
        add [rbx], rax
        NEXT

        defcode "-1",2,SUBSTORE
        pop rbx                 ; addr
        pop rax                 ; operand 1
        sub [rbx], rax
        NEXT

; byte level memory ops

        defcode "C!",2,STOREBYTE
        pop rbx                 ; addr
        pop rax                 ; dat
        mov [rbx], al
        NEXT

        defcode "C@",2,FETCHBYTE
        pop rbx                 ; addr
        xor rax, rax            ; clear rax
        mov al, [rbx]
        push rax
        NEXT

        defcode "C@C!",4,CCOPY
        mov rbx, [rsp+8]        ; source addr
        mov al, [rbx]           ; source char
        pop rdi                 ; destination addr
        stosb                   ; copy it
        push rdi
        inc qword [rsp+8]
        NEXT

        defcode "CMOVE",5,CMOVE
        mov rdx, rsi            ; keep rsi
        pop rcx                 ; length
        pop rdi                 ; destination
        pop rsi                 ; source
        rep movsb               ; sourc -> destination
        mov rsi, rdx            ; restore rsi

; Builtin variables
%macro defvar 3-5 0,0
        defcode %1, %2, %3, %4
        push qword var_%3
        NEXT
section .data
align 8
var_%3:
        dq %5
%endmacro

        defvar "STATE",5,STATE
        defvar "HERE",4,HERE
        defvar "LATEST",6,LATEST ; initial should be last builtin name_SYSCALL0
        defvar "S0",2,SZ
        defvar "BASE",4,BASE,10

%macro defconst 4-5 0
        defcode %1, %2, %3, %5
	push %4                 ; value
	NEXT
%endmacro

        defconst "R0",2,RZ,r_stack_top
        defconst "DOCOL",5,__DOCOL,DOCOL
        defconst "F_IMMED",7,__F_IMMED,F_IMMED
        defconst "F_HIDDEN",8,__F_HIDDDEN,F_HIDDEN
        defconst "F_LENMASK",9,__F_LENMASK,F_LENMASK

; return stack
        defcode ">R",2,TOR
        pop rax                 ; from param stack
        PUSHRSP rax             ; to return stack
        NEXT

        defcode "R>",2,FROMR
        POPRSP rax              ; from return stack
        push rax                ; to parameter stack
        NEXT

        defcode "RSP@",4,RSPFETCH
        push rbp
        NEXT

        defcode "RSP!",4,RSPSTORE
        pop rbp
        NEXT

        defcode "RDROP",5,RDROP
        add rbp, 8
        NEXT

; Parameter stack

        defcode "DSP@",4,DSPFETCH
        mov rax, rsp
        push rax
        NEXT

        defcode "DSP!",4,DSPSTORE
        pop rsp
        NEXT

; ---- Input ----
        defcode "KEY",3,KEY
        call _KEY
        push rax
        NEXT
_KEY:
        mov rbx, [currkey]
        cmp rbx, [bufftop]
        jge _KEY.exhausted
        xor rax, rax
        mov al, [rbx]           ; next byte / key
        inc rbx
        mov [currkey], rbx
        ret
.exhausted:                     ; out of input get more bytes
        ; the place to swap between memory / key input
        hlt
.err:
        hlt
currkey:
        dq buffer
bufftop:
        dq buffer

; ---- Emit ----
        defcode "EMIT",4,EMIT
        pop rax                 ; byte to emit
        call _EMIT
        NEXT
_EMIT:
        or ax, [color_b]        ; color the char
        mov bx, [vga_position]
        mov [0xB8000+rbx*2], ax
        add word [vga_position], 1
        ret
section .data
vga_position:
        dw 0x0
color_b:
        dw 0x0F00



; ---- Word ----
        defcode "WORD",4,$WORD
        call _WORD
        push rdi                ; base addr of word
        push rcx                ; length
        NEXT
_WORD:
; first non blank non \ comment
.start:
        call _KEY               ; get byte of input
        cmp al, `\\`            ; \ start of comment
        je _WORD.skip           ; skip it if so
        cmp al, ' '             ; is it space?
        jbe _WORD.start

        ; search for end of word
        mov rdi, word_buffer
.slurp:
        stosb                   ; add char to return buffer
        call _KEY               ; get next byte
        cmp al, ' '             ; is it space?
        ja _WORD.slurp          ; if not get more

        ; return the contents of buffer
        sub rdi, word_buffer
        mov rcx, rdi            ; length into rcx
        mov rdi, word_buffer    ; give addr of buffer
        ret

        ; skip comments
.skip:
        call _KEY
        cmp al, `\n`            ; new line?
        jne _WORD.skip
        jmp _WORD.start

section .bss                   ; quick buffer
word_buffer:
        resb 32










        defcode "DBG",4,DBG
        call debug_y

debug_s:
        mystring db "hey yr this is a thing woo"
        db 0x00
        mov rsi, mystring
        mov rcx, 0
.loop:
        mov ax, (0x0f << 8)
        or al, byte [mystring + rcx]
        test al,al
        je .done
        mov [0xB8000+rcx*2], ax
        inc rcx
        jmp .loop
        ; mov rax, 0x2F732F652F79
        ; mov qword [0xB8000], rax
        ; mov qword [0xB800C], rax
.done:
        hlt


        ; interrupt #
        ; handler
%macro inthandler 2

        mov rax, %2 ; int_handler
        mov [idt+%1*16], ax
        mov word [idt+%1*16+2], 0x08 ; 0x08 is code select
        mov word [idt+%1*16+4], 0x8e00
        shr rax, 16
        mov [idt+%1*16+6], ax
        shr rax, 16
        mov [idt+%1*16+8], rax

%endmacro



debug_y:
        ; inthandler 22, key_handler
        ; call os_wait_for_key

        mov rax, 'f'
        call _EMIT

        hlt

clear_screen:
        push rbp
        mov ax, (0x00 << 8)
        mov rcx, 0
.loop:
        mov [0xB8000+rcx*2], ax
        inc rcx
        mov rbx, rcx
        cmp rbx, 2000
        jle .loop
.done:
        pop rbp
        ret



os_wait_for_key:

        mov ax, 0
        mov ah, 10h        ; BIOS call to wait for key
        int 22

        mov [.tmp_buf], ax ; Store resulting keypress


        mov ax, [.tmp_buf]
        ret

.tmp_buf        dw 0

key_handler:
        iret



section .bss
alignb 4096
stack_bottom:
        stack resb 1000000
stack_top:
alignb 4096
r_stack_bottom:
        r_stack resb 1000000
r_stack_top:
alignb 4096
buffer:
        resb 4096
