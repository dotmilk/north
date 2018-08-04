global start_forth
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
        mov rbp, r_stack_top ; point us at the return stack
        mov rsp, stack_top   ; point us at the stack
                             ; mov var_S0, rsp
                             ; save a pointer to stack top
        mov rsi, cold_start  ; init interpreter
        NEXT                 ; run

section .rodata
cold_start:
        dq DBG

        defcode ""

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

        defcode "DBG",4,DBG
        call debug_y

debug_y:
        mov rax, 0x2F732F652F79
        mov qword [0xB8000], rax
        hlt

debug_n:
        mov rax, 0x2F4A2F4F2F4b2F4F
        mov qword [0xB8000], rax
        hlt


section .bss
align 4096
stack_bottom:
        stack resb 1000000
stack_top:
r_stack_bottom:
        r_stack resb 1000000
r_stack_top:
