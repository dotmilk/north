global start_forth
global scratch
global debug_s
extern idt
bits 64
%define gdtCsSelector 0x08
%define r_stack_size 4096
%define stack_size 4096
%define input_buffer_size 4096

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
        ; push rax
        ; push rcx
        ; push rdx
        ; call clear_screen
        ; pop rdx
        ; pop rcx
        ; pop rax
        ; need to set bufftop and currkey to
        ; input_buffer_ptr
        mov rsi, cold_start  ; init interpreter
        push 2
        push foo
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
        defvar "INPUT_BUFFER_SOURCE",19,IBS,0,-1
        defvar "INPUT_BUFFER",12,IB
        defvar "INPUT_BUFFER_LENGTH",19,IBL

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
        mov rbx, [currkey]      ; is currkey
        cmp rbx, [bufftop]      ; the top of buffer?
        jge _KEY.exhausted      ; get more then
        xor rax, rax
        mov al, [rbx]           ; next byte / key
        inc rbx
        mov [currkey], rbx      ; update currkey
        ret
.exhausted:                     ; out of input get more bytes
        ; the place to swap between memory / key input
        mov rdx, input_source_id
        cmp rdx, -1             ;
        je _KEY.eof             ; we are out of in memory 'file'
        hlt                     ; halt for now
        push rsi                ; refill from keyboard
        mov rsi, buffer   ; since buffer is exhausted
        mov [currkey], rsi           ; reset currkey to buff start
        mov rdx, input_buffer_size ; max bytes we can get
        call refill_buffer
        pop rsi
.eof:
        mov rsi, buffer         ; reset our pointers to
        mov [currkey], rsi     ;  buffer start and currkey
        ; set bufftop to buffer later?
        xor rax, rax            ; return 0
        ret
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
        jbe _WORD.start         ; start over

        ; search for end of word
        mov rdi, word_buffer
.slurp:
        stosb                   ; add char to return buffer
        call _KEY               ; get next byte
        test al, al
        je _WORD.return
        cmp al, ' '             ; is it space?
        ja _WORD.slurp          ; if not get more

        ; return the contents of buffer
.return:
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

; ---- Number ----
        defcode "NUMBER",6,NUMBER
        pop rcx                 ; str length
        pop rdi                 ; addr of string
        call _NUMBER
        push rax                ; the number
        push rcx                ; # unparsed chars
        NEXT
_NUMBER:
        xor rax, rax
        xor rbx, rbx

        test rcx, rcx           ; is there something
        jnz _NUMBER.continue    ; to parse?
        ret                     ; nope? bail
.continue:
        mov rdx, [var_BASE]       ; dl holds base
        mov bl, [rdi]           ; bl is fst char
        inc rdi                 ; point to next char
        push rax                ; 0 onto stack
        cmp bl, '-'
        jnz _NUMBER.parse       ; if not neg parse it
        pop rax                 ; it was negative
        push rbx                ; indicate it is so
        dec rcx                 ; one less char to parse
        jnz _NUMBER.loop        ; if we are out of chars
        pop rbx                 ; string was only '-'
        mov rcx, 1              ; err: 1 / unparsed char
        ret	                ; 0 in rax
.loop:
        imul rax, rdx           ; rax *= base
        mov bl, [rdi]           ; get next char
        inc rdi                 ; update char ptr
.parse:
        sub bl,'0'              ; < '0'?
        jb _NUMBER.maybeNegate
        cmp bl, 10              ; <= '9'
        jb _NUMBER.maybeDone
        sub bl, 17              ; < 'A'? (17 is 'A'-'0')
        jb _NUMBER.maybeNegate
        add bl, 10
.maybeDone:
        cmp bl, dl              ; >= BASE?
        jge _NUMBER.maybeNegate

        add rax, rbx            ; total +
        dec rcx                 ; we ate another char
        jnz _NUMBER.loop        ; if there are more loop
.maybeNegate:
        pop rbx                 ; check stack for
        test rbx, rbx           ; negation flag on stack
        jz _NUMBER.done
        neg rax
.done:
        ret

        defcode "FIND",4,FIND
        pop rcx                 ; length
        pop rdi                 ; addr
        call _FIND
        push rax                ; addr of entry or null
        NEXT

; ---- Find ----
_FIND:
        push rsi                ; save for string comp

        mov rdx, var_LATEST     ; name header of latest word
.start:
        test rdx, rdx           ; end of linked list?
        je _FIND.notFound
        xor rax, rax            ; compare lengths first
        mov al, [rdx+8]         ; al = flags + length field
        and al, (F_HIDDEN | F_LENMASK) ; al = name length
        cmp al, cl                     ; correct length ?
        jne _FIND.next

        push rcx                ; save length
        push rdi                ; save the addess repe will change this
        lea rsi, [rdx+9]        ; dict string
        repe cmpsb              ; compare while ==
        pop rdi                 ; restore
        pop rcx                 ; these
        jne _FIND.next

        pop rsi                 ; they were the same
        mov rax, rdx            ; return header pointer
        ret
.next:
        mov rdx, [rdx]
        jmp _FIND.start
.notFound:
        pop rsi                 ; restore rsi
        xor rax, rax            ; return 0 / not found
        ret


        defcode ">CFA",4,TCFA
        pop rdi
        call _TCFA
        push rdi
        NEXT
_TCFA:
        xor rax,rax
        add rdi, 8              ; skip link pointer
        mov al, [rdi]           ; load the flags+len into al
        inc rdi                 ; skip flags+len byte
        and al, F_LENMASK       ; now we have just the length
        add rdi, rax            ; use it to skip the name
        add rdi, 7              ; 8-byte aligned
        and rdi, ~7
        ret

        defword ">DFA",4,TDFA
        dq TCFA                 ;  >CFA (get code field)
        dq INCR4                ; skip 2 words
        dq INCR4
        dq EXIT

        defcode "CREATE",6,CREATE
        pop rcx                 ; length of name
        pop rbx                 ; addr name

        mov rdi, [var_HERE]       ; addr of header
        mov rax, [var_LATEST]     ; link ptr
        stosq                   ; store it
        push rsi
        mov rsi, rbx            ; word
        rep movsb               ; copy word
        pop rsi
        add rdi, 7              ; align next 4 byte
        and rdi, ~7

        mov rax, [var_HERE]
        mov [var_LATEST], rax
        mov [var_HERE], rdi
        NEXT

        defcode ",",1,COMMA
        pop rax
        call _COMMA
        NEXT
_COMMA:
        mov rdi, [var_HERE]       ; we are here
        stosq                   ; store ptr
        mov [var_HERE], rdi       ; update here
        ret


; in immediate mode
        defcode "[",1,LBRAC,F_IMMED
        xor rax, rax
        mov [var_STATE], rax
        NEXT

; in compile mode
        defcode "]",1,RBRAC
        mov rax, 1
        mov [var_STATE], rax
        NEXT

        defword ":",1,COLON
        dq $WORD                 ; name of new word
        dq CREATE               ; make dictionary entry
        dq LIT, DOCOL, COMMA    ; append DOCOL (codeword)
        dq LATEST, FETCH, HIDDEN ; Make word hidden
        dq RBRAC                 ; compile mode
        dq EXIT

        defword ";",1,SEMICOLON,F_IMMED
        dq LIT, EXIT, COMMA     ; append exit so word returns
        dq LATEST, FETCH, HIDDEN ; show the word now
        dq LBRAC                 ; immediate mode
        dq EXIT

        defcode "IMMEDIATE",9,IMMEDIATE,F_IMMED
        mov rdi, [var_LATEST]   ; latest word
        add rdi, 8              ; name / flags byte
        xor byte [rdi], F_IMMED
        NEXT

        defcode "HIDDEN",6,HIDDEN
        pop rdi
        add rdi, 8
        xor byte [rdi], F_HIDDEN
        NEXT

        defword "HIDE",4,HIDE
        dq $WORD                 ; get word (after HIDE)
        dq FIND                 ; look it up
        dq HIDDEN               ; hide / unhide it
        dq EXIT                 ; return

        defcode "'",1,TICK
        lodsq                   ; get addr of next word + skip it
        push rax                ; put it on stack
        NEXT

        defcode "BRANCH",6,BRANCH
        add rsi,[rsi]           ; add offset
        NEXT

        defcode "0BRANCH",7,ZBRANCH
        pop rax
        test rax, rax           ; is top of stack 0?
        jz code_BRANCH          ; jump to branch
        lodsq                   ; otherwise skip
        NEXT

        defcode "LITSTRING",9,LITSTRING
        lodsq                   ; length of string
        push rsi                ; push address of string
        push rax                ; push length
        add rsi, rax            ; skip the string
        add rsi, 7              ; round up to 4 byte
        and rsi, ~7
        NEXT

        ; TELL... needs EMIT too

        defword "QUIT",4,QUIT
        dq RZ, RSPSTORE         ; R0 RSP!
        dq INTERPRET            ; interpret next word
        dq BRANCH, -16          ; looooop


; ---- Xtra-Beefy Code ----
        defcode "INTERPRET",9,INTERPRET
        call _WORD              ; rcx length, rdi ptr to word

        xor rax, rax
        mov [interpret_is_lit], rax ; set lit flag to not lit
        call _FIND                  ; rax is ptr to header or 0
        test rax, rax
        jz code_INTERPRET.notFound

        ; it was found
        mov rdi, rax            ; rdi is dict entry
        mov al, [rdi+8]         ; name + flags
        push ax                 ; save it for now
        call _TCFA              ; convert EDI to codeword
        pop ax
        and al, F_IMMED
        mov rax, rdi
        jnz code_INTERPRET.execute ; if IMMED exec

        jmp code_INTERPRET.whichAction ; otherwise decide
.notFound:
        inc qword [interpret_is_lit]
        call _NUMBER            ; number in eax
        test rcx, rcx           ; rcx > 0 then no error
        jnz code_INTERPRET.err  ; err is blank stub for now
        mov rbx, rax            ; back up value
        mov rax, LIT            ; make it LIT
.whichAction:
        mov rdx, var_STATE
        test rdx, rdx
        jz code_INTERPRET.execute

        ; to compile just append word to dictionary def
        call _COMMA
        mov rcx, [interpret_is_lit]
        test rcx, rcx           ; was it literal?
        jz code_INTERPRET.next
        mov rax, rbx            ; Yes / Lit is followed by #
        call _COMMA
.next:
        NEXT
.execute:
        mov rcx, [interpret_is_lit]
        test rcx, rcx
        jnz code_INTERPRET.execLit
        jmp [rax]
.execLit:                       ; if exec lit, push on stack only
        push rbx
        NEXT
.err:
        hlt
section .data
align 8
interpret_is_lit:
        dq 0


        defcode "CHAR",4,CHAR
        call _WORD              ; rcx len / rdi ptr
        xor rax, rax
        mov al, [rdi]           ; first char in al
        push rax                ; push it onto stack
        NEXT

        defcode "EXECUTE",7,EXECUTE
        pop rax                 ; get xt into rax
        jmp [rax]               ; jump there




















        defcode "DBG",4,DBG
        call debug_s

        mystring db "hey yr this is a thing woo"
        db 0x00
debug_s:
        push 12
        pop r8
        pop r8
        pop r9
        mov [scratch], r8
        mov [scratch+1],r9
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



key_handler:
        iret

refill_buffer:
        hlt
section .data
        foo db '12'
section .bss
alignb 4096
stack:
        resw 1000
stack_top:
alignb 4096
r_stack_bottom:
         resw 1000
r_stack_top:
alignb 4096
buffer:
        resb input_buffer_size
input_source_id:
        resb 1
scratch:
        resb 20
