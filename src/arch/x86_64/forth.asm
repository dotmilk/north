        ; r8 / r9 scratch registers - could be clobbered
        ;

global start_forth
global scratch
global debug_s
extern idt
bits 64
%define gdtCsSelector 0x08
%define r_stack_size 1000
%define stack_size 50
%define tmp_stack_size 1000

%define input_buffer_size 4096

%define F_IMMED 0x80         ; Immediate flag
%define F_HIDDEN 0x20        ; Hidden flag
%define F_LENMASK 0x1f       ; Length mask

%define link 0

; name size
%macro reserve_stack 2
section .data
align 8
%1_ptr: dq %1_top
section .bss
align 8
%1:
        resq %2
%1_top:
%endmacro

%macro make_stack 2
        reserve_stack %1,%2
%endmacro

%macro PUSHC 2
        mov r8, [%1_ptr]        ; get current ptr
        lea r8, [r8-8]          ; offset us
        mov [%1_ptr], r8        ; store new ptr
        mov r9, qword %2        ; get val
        mov [r8], r9            ; store val
%endmacro

%macro POPC 2
        mov r8, [%1_ptr]        ; get ptr
        mov r9, [r8]            ; deref for val
        mov %2, r9              ; deref to %1
        lea r8, [r8+8]          ; new ptr
        mov [%1_ptr], r8        ; store it
%endmacro

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

        make_stack TMP, tmp_stack_size
        make_stack sorder, 512

section .text
align 8

_NEXT:
        NEXT

DOCOL:
        PUSHRSP rsi          ; return ptr on r_stack
        lea rsi, [rax + 8]   ; inc codeword to first instruction
        NEXT

section .text

start_forth:
        cld                  ; SI DI Inc on String
        mov rbp, r_stack_top ; point to return stack
        mov rsp, stack_top   ; point to the stack
        mov [var_SZ], rsp    ; save a pointer to stack top

        ; need to set bufftop and buffpos to
        ; input_buffer_ptr
        mov r10, __DS
        mov [var_HERE], r10
        mov [var_UB], r10
        xor r8,r8
        xor r9,r9
        ; core wid
        mov r8, name_NOOP
        mov [builtin_wordlist], r8   ; basically latest
        mov [builtin_wordlist+8], r9 ; no custom fn
        mov [builtin_wordlist+16], r9 ; no name
        mov [builtin_wordlist+24], r9 ; no prev
        PUSHC sorder, builtin_wordlist
        mov qword [var_current], builtin_wordlist
        ; buffer stuff
        xor r9,r9
        xor r8,r8
        mov [buffpos], r9
        lea r8, [_binary_forth_core_fs_size] ; size
        mov r9, _binary_forth_core_fs_start
        mov [buffsize], r8
        mov [buffaddr], r9

        mov rsi, cold_start  ; init interpreter
        NEXT                 ; run

section .rodata
cold_start:
        dq QUIT

        defcode "eflags",6,EFLAGS
        pushf
        NEXT

        defcode "eflags!",7,EFLAGS_STORE
        popf
        NEXT

        defcode "drop",4,DROP
        pop rax
        NEXT

        defcode "swap",4,SWAP
        pop rax
        pop rbx
        push rax
        push rbx
        NEXT

        defcode "dup",3,DUP
        mov rax, [rsp]
        push rax
        NEXT

        defcode "over",4,OVER
        mov rax, [rsp + 8]
        push rax
        NEXT

        defcode "rot",3,ROT
        pop rax
        pop rbx
        pop rcx
        push rbx
        push rax
        push rcx
        NEXT

        defcode "-rot",4,NROT
        pop rax
        pop rbx
        pop rcx
        push rax
        push rcx
        push rbx
        NEXT

        defcode "2drop",5,TWODROP
        pop rax
        pop rax
        NEXT

        defcode "2dup",4,TWODUP
        mov rax, [rsp]
        mov rbx, [rsp+8]
        push rbx
        push rax
        NEXT

        defcode "2swap",5,TWOSWAP
        pop rax
        pop rbx
        pop rcx
        pop rdx
        push rbx
        push rax
        push rdx
        push rcx
        NEXT

        defcode "?dup",4,QDUP
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

        defcode "2+",2,INC2
        add qword [rsp], 2
        NEXT

        defcode "2-",2,DEC2
        sub qword [rsp], 2
        NEXT

        defcode "4+",2,INCR4
        add qword [rsp], 4
        NEXT

        defcode "4-",2,DECR4
        sub qword [rsp], 4
        NEXT

        defcode "8+",2,INCR8
        add qword [rsp], 8
        NEXT

        defcode "8-",2,DECR8
        sub qword [rsp], 8
        NEXT

        defcode "lshift",6,LSHIFT
        pop rcx
        shl qword [rsp], cl
        NEXT

        defcode "rshift",6,RSHIFT
        pop rcx
        shr qword [rsp], cl
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
        imul rax,rbx
        push rax
        NEXT

        defcode "/mod",4,DIVMOD
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
        cmp rbx, rax
%endmacro
; put result on stack
%macro pushCmp 0
        movzx rax, al
        neg rax                 ; forth true = -1
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

        defcode "u<",2,ULT
        cmp2
        setb al
        pushCmp
        NEXT

        defcode "u>",2,UGT
        cmp2
        seta al
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

        defcode "and",3,AND
        pop rax
        and [rsp], rax
        NEXT

        defcode "or",2,OR
        pop rax
        or [rsp], rax
        NEXT

        defcode "xor",3,XOR
        pop rax
        xor [rsp], rax
        NEXT

        defcode "invert",6,INVERT
        not qword [rsp]
        NEXT

; returning from forth words
        defcode "exit",4,EXIT
        POPRSP rsi
        NEXT

; like next but push instead of jmp
        defcode "lit",3,LIT
        lodsq
        push rax
        NEXT

        defcode "roll",4,ROLL
        pop rcx                 ; n items
        jecxz code_ROLL.roll_next
        lea rdi,[rsp + rcx * 8]
        lea rbx,[rdi - 8]
        mov rax,[rdi]
        std
        xchg rsi, rbx
        rep movsq
        xchg rsi, rbx
        cld
        mov [rsp],rax
.roll_next:
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

        defcode "@@",2,DBLFETCH
        pop rbx
        mov rax, [rbx]
        mov rax, [rax]
        push rax
        NEXT

        defcode "+!",2,ADDSTORE
        pop rbx                 ; addr
        pop rax                 ; operand 1
        add [rbx], rax
        NEXT

        defcode "1+!",3,ADDONESTORE
        pop rbx                 ; addr
        mov rax, 1
        add [rbx], rax
        NEXT

; byte level memory ops

        defcode "c!",2,STOREBYTE
        pop rbx                 ; addr
        pop rax                 ; dat
        mov [rbx], al
        NEXT

        defcode "c@",2,FETCHBYTE
        pop rbx                 ; addr
        xor rax, rax            ; clear rax
        mov al, [rbx]
        push rax
        NEXT

        defcode "c@c!",4,CCOPY
        mov rbx, [rsp+8]        ; source addr
        mov al, [rbx]           ; source char
        pop rdi                 ; destination addr
        stosb                   ; copy it
        push rdi
        inc qword [rsp+8]
        NEXT

        defcode "cmove",5,CMOVE
        mov rdx, rsi            ; keep rsi
        pop rcx                 ; length \ u
        pop rdi                 ; destination \ to
        pop rsi                 ; source \ from
        rep movsb               ; source -> destination
        mov rsi, rdx            ; restore rsi
        NEXT

        defcode "cmove>",6,CMOVETO
        mov rdx, rsi            ; keep rsi
        pop rcx                 ; length \ u
        pop rdi                 ; destination \ to
        pop rsi                 ; source \ from
        add rsi,rcx
        add rdi,rcx
        add rcx,1
        std
        rep movsb               ; sourc -> destination
        cld
        mov rsi, rdx            ; restore rsi
        NEXT

        defcode "fill",4,fill
        pop rax                 ; char
        pop rcx                 ; count
        pop rdi                 ; addr
        cmp rcx,0
        jle _fillDone
        rep stosb
_fillDone:
        NEXT

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
        defvar "sorder-stack",12,sorder_t,0,sorder_top
        ; defvar "sorder-ptr",10,sorder_p,0,sorder_ptr
        defvar "current",7,current
        defvar "compiling-nextname",18,compiling_nextname,0,0
        defvar "sp-limit",8,sp_limit,0,stack+(stack_size*8)
        defvar "user-base",9,UB
        defvar "state",5,STATE
        defvar "tmpbase",7,TMPBASE
        defvar "here",4,HERE
        defvar "latest",6,LATEST,0,name_NOOP ; initial should be last builtin name_SYSCALL0
        defvar "s0",2,SZ
        defvar "base",4,BASE,0,10
        defvar "INPUT_BUFFER_SOURCE",19,IBS,0,-1
        defvar "INPUT_BUFFER",12,IB
        defvar "INPUT_BUFFER_LENGTH",19,IBL
        defvar "$dodoes",7,DDADDR,0,code__dodoes._dodo

%macro defconst 4-5 0
        defcode %1, %2, %3, %5
	push %4                 ; value
	NEXT
%endmacro

        defconst "sorder-ptr",10,sorder_p,sorder_ptr
        defconst "r0",2,RZ,r_stack_top
        defconst "docol",5,__DOCOL,DOCOL
        defconst "F_IMMED",7,__F_IMMED,F_IMMED
        defconst "F_HIDDEN",8,__F_HIDDDEN,F_HIDDEN
        defconst "F_LENMASK",9,__F_LENMASK,F_LENMASK

; tmp stack

        defcode ">tmp",4,TOTMP
        pop rax
        PUSHC TMP, rax
        NEXT

        defcode "tmp>",4,FROMTMP
        POPC TMP ,rax
        push rax
        NEXT
; return stack
        defcode ">r",2,TOR
        pop rax                 ; from param stack
        PUSHRSP rax             ; to return stack
        NEXT

        defword "2>r",3,TTOR
        dq TOR
        dq TOR
        dq EXIT

        defcode "r>",2,FROMR
        POPRSP rax              ; from return stack
        push rax                ; to parameter stack
        NEXT

        defword "2r>",3,TFROMR
        dq FROMR
        dq FROMR
        dq EXIT

        defcode "r@",2,RFETCH
        mov rax, [rbp]
        push rax
        NEXT

        defcode "rsp@",4,RSPFETCH
        push rbp
        NEXT

        defcode "rsp!",4,RSPSTORE
        pop rbp
        NEXT

        defcode "rdrop",5,RDROP
        add rbp, 8
        NEXT

; Parameter stack

        defcode "dsp@",4,DSPFETCH
        mov rax, rsp
        push rax
        NEXT

        defcode "dsp!",4,DSPSTORE
        pop rsp
        NEXT

        ; ---- Input ----

        defcode "h#",2,TMPHEX,F_IMMED
        mov qword [var_TMPBASE], 0x10
        NEXT

        defcode "d#",2,TMPDEC,F_IMMED
        mov qword [var_TMPBASE], 0xA
        NEXT

        defcode "o#",2,TMPOCT,F_IMMED
        mov qword [var_TMPBASE], 0x8
        NEXT

        defcode "b#",2,TMPBIN,F_IMMED
        mov qword [var_TMPBASE], 0x2
        NEXT

        defcode "ctb",3,CTB,F_IMMED
        mov qword [var_TMPBASE], 0
        NEXT

        defcode "key",3,KEY
        call _KEY
        push rax
        NEXT
_KEY:
        call _PEEK
        inc qword [buffpos]     ; update buffpos
        ret

        defcode "peek",4,PEEK
        call _PEEK
        push rax
        NEXT
_PEEK:
        mov rbx, [buffpos]      ; is buffpos
        cmp rbx, [buffsize]      ; the top of buffer?
        jge _PEEK.exhausted      ; get more then
        xor rax, rax
        mov rbx, [buffaddr]     ; buffer start +
        add rbx, [buffpos]      ; our position =
        mov al, [rbx]           ; next byte / key
        ; inc qword [buffpos]     ; update buffpos
        ret
.exhausted:                     ; out of input get more bytes
        ; the place to swap between memory / key input
        mov rdx, [buffsid]
        cmp rdx, -1             ;
        je _PEEK.eof             ; we are out of in memory 'file'
        hlt                     ; halt for now
        push rsi                ; refill from keyboard
        mov rsi, buffer   ; since buffer is exhausted
        mov [buffpos], rsi           ; reset buffpos to buff start
        mov rdx, input_buffer_size ; max bytes we can get
        call refill_buffer
        pop rsi
.eof:
        call _restore_memory
        jmp _PEEK
        ; mov rsi, buffer         ; reset our pointers to
        ; mov [buffpos], rsi     ;  buffer start and buffpos
        ; ; set bufftop to buffer later?
        ; xor rax, rax            ; return 0
        ; ret
.err:
        hlt
buffsize:
        dq 0
buffaddr:
        dq buffer
buffpos:
        dq buffer
savcurrkey:
        dq 0
savbufftop:
        dq 0
savbuffaddr:
        dq 0
; ---- Emit ----
        defcode "emit",4,EMIT
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
        defcode "word",4,$WORD
        mov rdx, [var_compiling_nextname]
        test rdx, rdx
        jz .regular
        mov qword [var_compiling_nextname], 0
        NEXT
.regular:
        call _WORD
        push rdi                ; base addr of word
        push rcx                ; length
        NEXT
_WORD:

; first non blank non \ comment
.start:
        call _KEY               ; get byte of input
        ; cmp al,0
        ; jnz _WORD.notEof
        ; xor rax,rax
        ; ret
.notEof:
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
        defcode "number",6,NUMBER
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
        mov r8, [var_TMPBASE]     ; r8 tmp base?
        test r8,r8
        jz _NUMBER.noTmpBase
        mov rdx, r8
.noTmpBase:
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
        mov qword [var_TMPBASE], 0
        ret

        defcode "find",4,FIND
        pop rcx                 ; length
        pop rdi                 ; addr
        call _FIND
        push rax                ; addr of entry or null
        NEXT



; ---- Find ---- dont touch rax / rcx / rdi / rdx
_FIND:
        push rsi                ; save for string comp
.load_sorder:
        mov rbx, [sorder_ptr]   ; first wid to search
.loop:
        mov rdx, [rbx]          ; deref the wid
        mov rdx, [rdx]           ; wid latest
        ; mov rdx, [var_LATEST]     ; name header of latest word
        jmp _Search
.reenter:
        test rax, rax
        jnz _FIND.done
        add rbx, 8
        cmp rbx, sorder_top     ; have we reached the end of wordlists?
        jne _FIND.loop
.done:
        ret

_Search:
        test rdx, rdx           ; end of linked list?
        je _Search.notFound
        xor rax, rax            ; compare lengths first
        mov al, [rdx+8]         ; al = flags + length field
        and al, (F_HIDDEN | F_LENMASK) ; al = name length
        cmp al, cl                     ; correct length ?
        jne _Search.next

        push rcx                ; save length
        push rdi                ; save the addess repe will change this
        lea rsi, [rdx+9]        ; dict string
        repe cmpsb              ; compare while ==
        pop rdi                 ; restore
        pop rcx                 ; these
        jne _Search.next
        pop rsi                 ; they were the same
        mov rax, rdx            ; return header pointer
        jmp _FIND.reenter
.next:
        mov rdx, [rdx]
        jmp _Search
.notFound:
        pop rsi                 ; restore rsi
        xor rax, rax            ; return 0 / not found
        jmp _FIND.reenter

        defcode "source",6,SOURCE
        push qword [buffaddr]
        push qword [buffsize]
        NEXT

        defcode ">in",3,INPTR
        push buffpos
        NEXT

        defcode ">cfa",4,TCFA
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

        defword ">dfa",4,TDFA
        dq TCFA                 ;  >CFA (get code field)
        dq INCR4                ; skip 2 words
        dq INCR4                ; 8 bytes total = 1 qword
        dq EXIT

        defcode "create",6,CREATE
        pop rcx                 ; length of name
        pop rbx                 ; addr name

        mov rdi, [var_HERE]       ; addr of header
        mov rax, [var_current]
        mov rax, [rax]
        ; mov rax, [var_LATEST]     ; link ptr
        stosq                   ; store it

        mov al,cl               ; length
        stosb                   ; store it
        push rsi
        mov rsi, rbx            ; word
        rep movsb               ; copy word
        pop rsi
        add rdi, 7              ; align next 4 byte
        and rdi, ~7
        nop
        mov r9, var_current
        mov r9, [r9]
        mov r11, [r9]
        mov rax, [var_HERE]
        mov [r9], rax
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
        mov rax, -1
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

        defcode "immediate",9,IMMEDIATE,F_IMMED
        mov rdi, [var_LATEST]   ; latest word
        add rdi, 8              ; name / flags byte
        xor byte [rdi], F_IMMED
        NEXT

        defcode "immediate?",10,IMMEDIATEQ
        pop rbx
        call _ISIMM
        push rax
        NEXT

_ISIMM:
        mov byte al,[rbx+8]
        and al, F_IMMED
        jnz _ISIMM.true
        mov rax, 0
        ret
.true:
        mov rax, -1
        ret

        defcode "hidden",6,HIDDEN
        pop rdi
        add rdi, 8
        xor byte [rdi], F_HIDDEN
        NEXT

        defword "hide",4,HIDE
        dq $WORD                 ; get word (after HIDE)
        dq FIND                 ; look it up
        dq HIDDEN               ; hide / unhide it
        dq EXIT                 ; return

        defcode "'",1,TICK
        lodsq                   ; get addr of next word + skip it
        push rax                ; put it on stack
        NEXT

        defcode "branch",6,BRANCH
        add rsi,[rsi]           ; add offset
        NEXT

        defcode "0branch",7,ZBRANCH
        pop rax
        test rax, rax           ; is top of stack 0?
        jz code_BRANCH          ; jump to branch
        lodsq                   ; otherwise skip
        NEXT

        defcode "?branch",7,NZBRANCH
        pop rax
        test rax, rax           ; is top of stack not 0
        jnz code_BRANCH         ; jump to branch
        lodsq                   ; otherwise skip
        NEXT

        defcode "litstring",9,LITSTRING
        lodsq                   ; length of string
        push rsi                ; push address of string
        push rax                ; push length
        add rsi, rax            ; skip the string
        add rsi, 7              ; round up to 4 byte
        and rsi, ~7
        NEXT

        ; TELL... needs EMIT too

        defcode "change-memory-buffer",20,EISC
        pop rax                 ; size
        pop rbx                 ; addr

        PUSHC TMP, [buffaddr]
        PUSHC TMP, [buffsize]
        PUSHC TMP, [buffpos]
        PUSHC TMP, [buffsid]

        mov [buffsize], rax
        mov [buffaddr], rbx
        mov qword [buffpos], 0
        mov qword [buffsid], -1
        NEXT

        defcode "restore-memory-buffer",21,EISR
        call _restore_memory
        NEXT
_restore_memory:
        nop
        POPC TMP,[buffsid]
        nop
        POPC TMP,[buffpos]
        nop
        POPC TMP,[buffsize]
        nop
        POPC TMP, [buffaddr]
        ret

; section .data
; tmpptr: dq tmp_top

        defword "quit",4,QUIT
        dq RZ, RSPSTORE         ; R0 RSP!
        dq INTERPRET            ; interpret next word
        dq BRANCH, -16          ; looooop



; ---- Xtra-Beefy Code ----
        defcode "interpret",9,INTERPRET
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
        test rcx, rcx           ; rcx > 0 then error
        jnz code_INTERPRET.err  ; err is blank stub for now
        mov rbx, rax            ; back up value
        mov rax, LIT            ; make it LIT
.whichAction:
        mov rdx, [var_STATE]
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


        defcode "char",4,CHAR
        call _WORD              ; rcx len / rdi ptr
        xor rax, rax
        mov al, [rdi]           ; first char in al
        push rax                ; push it onto stack
        NEXT

        defcode "execute",7,EXECUTE
        pop rax                 ; get xt into rax
        jmp [rax]               ; jump there

        defconst "dodoes",6,_dodoes,._dodo
._dodo:
        cmp qword [rax+8],0     ; has does been executed ?
        jz .noDoes
        lea rbp,[rbp-8]
        mov [rbp], rsi
        mov rsi, [rax+8]         ; ptr stored by does>
.noDoes:
        lea rax,[rax+16]
        push rax                ; user data area address
        NEXT

        defcode "leave",5,LVE
        lea rbp,[rbp + 24]      ; pop return stack
        jmp code_QDO.leave

        defcode "?do",3,QDO
        pop rcx                 ; initial index
        pop rdx                 ; limit
        cmp rcx,rdx
        jne code_DO.dogo
.leave:
        mov rcx, 1
        xor rbx, rbx
.qdoloop:
        lodsq
        cmp rax, code_DO            ; nested loop?
        setz bl
        add rcx, rbx
        cmp rax, code_QDO
        setz bl
        add rcx, rbx
        cmp rax, code_Lloop
        setz bl
        sub rcx, rbx
        cmp eax, code_Ploop
        setz bl
        sub rcx, rbx
        or rcx, rcx
        jnz code_QDO.qdoloop
        NEXT

        defcode "do",2,DO
        pop rcx                 ; initial index
        pop rdx                 ; limit
.dogo:
        lea rbp,[rbp - 24]      ; return stack room
        mov [rbp + 16], rsi
        mov [rbp + 8], rdx
        mov [rbp], rcx
        NEXT

        defcode "+loop",5,Ploop
        pop rax
        jmp code_Lloop.loop_step

        defcode "loop",4,Lloop
        mov rax, 1              ; default step
.loop_step:
        mov rbx, [rbp]          ; index
        sub rbx, [rbp + 8]      ; limit
        btc rbx, 63             ; invert MSB
        add rbx, rax            ; step
        jo code_Unloop          ; loop end on overflow
        btc rbx, 63             ; revert MSB
        add rbx, [rbp + 8]      ; add limit back
        mov [rbp], rbx          ; updated index
        mov rsi, [rbp + 16]
        NEXT

        defcode "unloop",6,Unloop
        lea rbp,[rbp + 24]      ; pop return stack
        NEXT

        defcode "i",1,i
        push qword [rbp]
        NEXT

        defcode "j",1,j
        push qword [rbp + 24]
        NEXT

        defcode "k",1,k
        push qword [ rbp + 40]  ; untested
        NEXT


%include "include/builtin-files.asm"

        defcode "(",1,OPEN_COMMENT,F_IMMED
        mov rcx, 1              ; nested parent count
.start:
        call _KEY               ; byte in al
        cmp rax, '('            ; another open paren?
        jne code_OPEN_COMMENT.closeParen
        inc rcx                 ; it was, inc counter
        jmp code_OPEN_COMMENT.start  ; go again
.closeParen:
        cmp rax, ')'            ; closing parens?
        jne code_OPEN_COMMENT.start
        dec rcx                 ; it was, dec counter
        cmp rcx, 0              ; are we done?
        jne code_OPEN_COMMENT.start
        NEXT

        defcode "hlt",3,HALT
halt_here:
        hlt
        jmp halt_here
        NEXT

        defcode "inoop",5,inoop,F_IMMED
        nop
        NEXT

        defcode "nop",3,NOPP
        nop
        NEXT

        defcode "noop",4,NOOP
        nop
        NEXT











        ; defcode "DBG",4,DBG
        ; call debug_s

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
        buffsid dq -1
section .bss
alignb 4096
stack:
        resq stack_size
stack_top:
alignb 4096
r_stack:
         resq r_stack_size
r_stack_top:
buffer:
        resb input_buffer_size
scratch:
        resq 1
builtin_wordlist: resq 4
__DS:
        resq 262144
