( )

: alias
    word create word find >cfa @
    \ skip check for now dup docol = if abort then
    ,
; immediate

hide '
: ' ( "<spaces>name" -- xt ) word find >cfa ;

: wordsize 8 ;
: char+ 1 + ;
: cell 8 ;
: cells  8 * ;
: cell+ 1 cells + ;
\ here in asm, moar ans
alias (here) here
: here ( -- addr ) here @ ;
\ old-here is addr that stores here
: allot ( n -- ) here + (here) ! ;

\ , asm
: c, here 1 allot c! ;

: false 0 ;
: true  -1 ; \ traditionally jones has 1 as true
: on true swap ! ;
: off false swap ! ;

\ 0<
\ ... asm
\ 2-
: negate 0 swap - ; \ negative of n
: not 0= ;
: u>= u< not ;
: u<= u> not ;
: 0! 0 swap ! ;
: 1-! -1 swap +! ;
: and! dup @ rot and swap ! ;
: or!  dup @ rot or swap ! ;

\ a b c -- a<=b<=c
: between over u>= >r u<= r> and ;

\ x n -- flag
: bit? 1 swap lshift and 0<> ;
: CF? eflags 0 bit? ;
: SF? eflags 7 bit? ;
: OF? eflags 11 bit? ;

\ -rot asm
: tuck ( x y -- y x y ) swap over ;
\ 2dup ... 2swap asm
: nip ( x y -- y ) swap drop ;
: 2nip ( w1 w2 w3 w4 -- w3 w4 ) 2swap 2drop ;
\ /mod asm
: / /mod swap drop ;
: mod /mod drop ;

\ ( addr+7 ) & ~7
: aligned ( addr -- addr )
    7 + 7 invert and ;
: align here aligned (here) ! ;
\ 2align is 8byte qword-which we are already using
: clearstack sp-limit dsp! ;
\ jones depth ( depth = stack depth ) no / 8
: depth ( -- +n ) s0 @ 8- dsp@ - 8 / ;
\ le dictionary link entry + 8 is len/flags + 1 = name
: >name ( LE -- addr u )
    8+ dup
    c@ F_LENMASK and swap ( len nt -- )
    1+ swap ;
\ latest @ nt>name noop
: previous-word ( LE -- LE2 )
    @ ;
: >xt
    >cfa @ ;

: parse-nt
    word find ;

: ['] immediate
    lit lit , ;

: literal immediate
    lit lit , , ;

\ force an otherwise immediate word to compile
: [compile] immediate
   word find >cfa ,
;

: '\n' 10 ; \ newline
: bl 32 ; \ blank / space
: ':' [ char : ] literal ;
: ';' [ char ; ] literal ;
: '(' [ char ( ] literal ;
: ')' [ char ) ] literal ;
: '"' [ char " ] literal ;
: 'A' [ char A ] literal ;
: '0' [ char 0 ] literal ;
: '-' [ char - ] literal ;
: '.' [ char . ] literal ;


: recurse immediate
    latest @ \ get current word
    >cfa \ get codeword from it
    , \ append it in place
;

: if immediate
    lit 0branch , \ apppend 0branch
    here \ address of current offset on stack
    0 , \ insert dummy offset
;

: then immediate
    dup
    here swap - \ get difference of old here and here
    swap ! \ store offset in back-filled location
;

alias endif then

: else immediate
    lit branch , \ unconditional branch over false-part
    here \ our offfset
    0 , \ store dummy offset
    swap \ backfill the 'if' offset
    dup \ and so on for then
    here swap -
    swap !
;

\ begin loop-stuff condition until
: begin immediate
    here \ location to stack
;

: until immediate
    lit 0branch ,
    here - \ calculate offset from start of loop
    , \ store that
;

\ begin loop-stuff again
\ infinite loop, must call exit
: again immediate
    lit branch ,
    here -
    , ;

\ begin condition while loop-stuff repeat
: while immediate
    lit 0branch , \ compile 0branch
    here
    0 , ;

: repeat immediate
    lit branch ,
    swap \ begin's offset
    here - , \ append calculation
    dup
    here swap - \ second offset
    swap ! \ backfill
;

\ if but reversed test
: unless immediate
    lit not , \ reverse test
    [compile] if \ literal immediate 'if'
;

: case immediate
    0 ( mark the end of stack )
;

\ CASE's implementation imported from Gforth.
\
\ Usage
\ ( n )
\ CASE
\    1 OF .... ENDOF
\    2 OF .... ENDOF
\    OTHERWISE
\ END-CASE
\
\ Remember not to consume the element in the OTHERWISE case.
: of immediate
    lit over ,
    lit = ,
    [compile] if
    lit drop ,
;

: endof immediate
    [compile] else
;

: endcase immediate
    lit drop ,
    begin
        ?dup
    while
            [compile] then
    repeat
;

: count ( caddr1 -- caddr2 u ) dup c@ swap 1+ swap ;

: move ( c-from c-to u )
    >r 2dup < if r> cmove> else r> cmove then ;

alias (find) find
hide find
: find ( c-addr -- c-addr 0 | xt 1 | xt -1 )
  dup count (find) dup 0= if exit then
  nip dup 8+ @ F_IMMED and 0= if >cfa -1 exit then
  >cfa 1
;

: drop-nop 0 ;

: store-char
    swap 1+ 2dup c! swap drop \ store char
;

: input-empty?
    source nip
    >in @ <= ;

: slurp-while-ws
    begin
        input-empty? if 0 exit then
        key case
            09 of endof
            10 of endof
            13 of endof
            32 of endof
            exit
        endcase
    again ;

: slurp-until-ws
    begin
        store-char
        input-empty? if 0 exit then
        key case
            09 of exit endof
            10 of exit endof
            13 of exit endof
            32 of exit endof
            drop-nop
        endcase

    again ;

alias (word) word
hide word
\ needs compiling_nextname support
: word ( "<ws+>ccc<ws>" -- c-addr )
    slurp-while-ws dup 0= if \ nothing was in buffer
        here c! here exit
    then
    here swap \ setup for first slurp loop
    slurp-until-ws dup 0= if
        here - here c! here exit
    then
    here - here c! here
;

hide store-char
hide drop-nop
hide slurp-while-ws
hide slurp-until-ws
\ needs compiling_nextname support
: delimited-word ( char "<chars>ccc<char>" -- c-addr )
  0 begin drop
  source nip >in @ <= if drop 0 here c! here exit then \ nothing in buffer
  key 2dup <> until \ skip leading delimiters
  here -rot begin rot 1+ 2dup c! -rot drop \ store char
  source nip >in @ <= if drop here - here c! here exit then \ exhausted
  key 2dup = \ char key result --
  swap \ char result key
  dup \ char result key key
  -rot \ char key result key
  '\n' \ char key result key nl
  = \ char key result result2
  or \ char key
  until 2drop here - here c! here
;

: :noname
    0 0 create ( word with no name )
    here ( here is xt addr )
    docol , ( the xt )
    ] ( enter compile mode )
;

: exception-marker
    rdrop ( drop param stack ptr  )
    0 ( no exception, normal return path )
;

: catch ( xt -- exn? )
    dsp@ 8+ >r ( p-stack ptr save +8 for xt on rstack )
    lit exception-marker 8+ ( push rdrop address )
    >r ( onto return stack to fake return addr )
    execute ( execute nested fn )
;

: throw ( n -- )
    ?dup if ( only if exception code <> 0 )
        rsp@ ( return stack ptr )
        begin
            dup r0 8- < ( rsp < r0 )
        while
                dup @ ( get return stack entry )
                lit exception-marker 8+ = if ( found the marker )
                    8+ ( skip marker )
                    rsp! ( restore return stack ptr )
                    ( restore param stack )
                    dup dup dup ( working space / prevent overlap )
                    r> ( saved pstack ptr | n dsp )
                    8- ( reserve space to store n )
                    swap over ( dsp n dsp )
                    ! ( write n to the stack )
                    dsp! exit ( restore p stack ptr then bail )
                then
                8+
        repeat
        ( no frame found restart interpreter )
        drop
        ( case print later )
        quit
    then
;

: abort ( -- )
   0 1- throw
;

: postpone ( "<spaces>name" -- )
  word find dup 0= if abort then
  -1 = if
    ['] lit , , ['] , ,
  else
    ,
  then
; immediate

alias (create) create
hide create
: create ( "<spaces>name" -- ) (word) (create) dodoes , 0 , ;
: <builds word create dodoes , 0 , ;
: does> r> latest @ >dfa ! ;
: >body ( xt -- a-addr ) 2 cells + ;

: defer create ['] abort , does> @ execute ;

: defer@ ( xt1 -- xt2 )
  >body @ ;

: defer! ( xt2 xt1 -- )
  >body ! ;

: <is> ( xt "name" -- )
    ' defer! ;

: [is] ( compilation: "name" -- ; run-time: xt -- )
    postpone ['] postpone defer! ; immediate

: is
    state @ if
      postpone [is]
    else
      <is>
    then
; immediate

: action-of
 state @ if
     postpone ['] postpone defer@
 else
     ' defer@
 then
; immediate

: value ( n -- )
    word create
    docol ,
    lit lit ,
    ,
    lit exit ,
;

: to immediate ( n -- )
    word
    find
    >dfa
    8+
    state @ if ( compiling? )
        lit lit ,
        ,
        lit ! ,
    else
        !
    then
;

: +to immediate ( n -- )
    word
    find
    >dfa
    8+
    state @ if ( compiling? )
        lit lit ,
        ,
        lit +! ,
    else
        +!
    then
;

0 value anon

: variable create 1 cells allot ;

: constant
  create
  docol ,
  lit lit ,
  ,
  lit exit , ;

: ]l ] postpone literal ;

: abs dup 0< if negate then ;

: max 2dup < if nip else drop then ;

: min 2dup > if nip else drop then ;

: pick ( x_u ... x_1 x_0 u -- x_u ... x_1 x_0 x_u )
    1+ ( +1 for the u on the stack )
    wordsize * ( offset is count * wordsize )
    dsp@ + ( stack ptr + offset )
    @ ( fetch )
;

\ roll asm

: ndrop ( xn .. x1 x0 n --- )
    1+
    wordsize *
    dsp@ +
    dsp!
;

: 2over 3 pick 3 pick ;
: 2tuck 2swap 2over ;
: 2rot 5 roll 5 roll ;

\ Like ALLOT but initialize memory to 0.
: zallot ( n -- )
    dup 0 < if
        allot
    else
        here swap
        dup allot
        0 fill
    then ;



create pad 1024 allot

: low-byte 255 and ;
: high-byte 8 rshift low-byte ;
\ a b c -- a<=b<=c
: printable-char? ( ch -- flag )
    dup  h# 20 >=
    swap h# 7E <= and ;



: get-char
    begin
        key case
            09 of endof
            10 of endof
            13 of endof
            32 of endof
            exit
        endcase
    again ;

: [get-char] immediate
    get-char [compile] literal ;

\ user-base noop
\ here noop
\ : unused user-base here - ;

: buffer>start ( addr -- start )
    @ ;

: buffer>size ( addr -- size )
    cell + @ ;

: buffer>loaded ( addr -- isloaded? )
    2 cells + ;

: buffer>nt ( addr -- addr u )
    3 cells + @ ;

: buffer>string ( addr -- addr u )
    dup buffer>start swap buffer>size ;

: buffer-loaded? ( addr -- flag )
    buffer>loaded @ ;

: mark-buffer-as-loaded ( addr -- )
    buffer>loaded true swap ! ;

@forth/core.fs mark-buffer-as-loaded

defer load-buffer-print-hook
' drop is load-buffer-print-hook

variable load-buffer-print
load-buffer-print on

: load-buffer ( addr -- )
    dup mark-buffer-as-loaded
    load-buffer-print @ if
        dup load-buffer-print-hook
    then
    buffer>string change-memory-buffer ;

: require-buffer ( addr -- )
    dup buffer-loaded? if drop else load-buffer then ;

: enum dup constant 1+ ;
: end-enum drop ;

: require immediate
    '
    state @ if
        postpone literal
        postpone execute
        postpone require-buffer
    else
        execute
        require-buffer
    then ;

: include immediate
    '
    state @ if
        postpone literal
        postpone execute
        postpone load-buffer
    else
        execute
        require-buffer
    then ;

require @forth/structures.fs
require @forth/interpreter.fs
require @forth/strings.fs

: feature ( flag -- )
    word swap if
        nextname count alias
    else
        2drop
    then ;




\ defer emitting words until proper kernel\emit support
\ : cr '\n\' emit ;
\ : space bl emit ;



\ [ ... ] literal is compile time 'macro'
\ where char x become the int for x
\ at compile time and thus
\ : ':' [ char : ] literal ;
\ becomes 'interred' as
\ : ':' 58 literal ;


: ( immediate
    1 \ keep track of nested paren depths
    begin
        key \ next char
        dup '(' = if \ is open paren?
            drop \ drop it
            1+
        else
            ')' = if
                1-
            then
        then
    dup 0= until \ continue until depth 0
    drop \ drop counter
;





: decimal ( -- ) 10 base ! ;
: hex ( -- ) 16 base ! ;

\ missing . and various integer printing ops


( c a b within true if a <= c and c < b  )
( without ifs over - >r - r> u< )
: within
    -rot ( b c a)
    over ( b c a c )
    <= if
        > if ( b c -- )
            true
        else
            false
        then
    else
        2drop ( b c -- )
        false
    then
;




\ : c,
\     here @ c! ( store char in compiled image )
\     1 here +! ( inc here by 1 byte )
\ ;

\ : s" immediate ( -- addr len )
\     state @ if ( are we compiling )
\         ' litstring ,
\         here @ ( save address for length on stack )
\         0 , ( dummy length )
\         begin
\             key ( get char of string )
\             dup '"' <>
\         while
\                 c, ( copy it )
\         repeat
\         drop ( drop the " char at end )
\         dup ( saved addr for length )
\         here @ swap - ( calc length )
\         8- ( remove length word )
\         swap ! ( backfill length )
\         align ( get us to multiple of 8 bytes )
\     else ( immediate not copmiling )
\         here @ ( start of temp space )
\         begin
\             key
\             dup '"' <>
\         while
\                 over c! ( save )
\                 1+ ( increment addr )
\         repeat
\         drop
\         here @ - ( length )
\         here @ ( push start addr )
\         swap ( addr len )
\     then
\ ;

\ no ." for now








\ id. missing

: ?hidden
    8+
    c@
    F_HIDDEN and
;

: ?immediate
    8+
    c@
    F_IMMED and
;

\ words missing

: forget
    word find
    dup @ latest !
    here !
;

\ dump missing



: cfa>
    latest @
    begin
        ?dup
    while
            2dup swap ( cfa curr curr cfa )
            < if ( curr < cfa? )
                nip ( leave curr on stack )
                exit
            then
            @ ( follow back )
    repeat
    drop
    0
;

\ see missing



\ c strings missing
\ env missing
\ system calls missing

hex

( next macro )
: next immediate 48 c, AD c, FF c, 20 c, ;

: ;code immediate
    [compile] next
    align
    latest @ dup
    hidden
    dup >dfa swap >cfa ! ( change codeword to point to data )
    [compile] [
;

( 16bit prefix )
: w 66 ;

( i386 registers )
: rax immediate 0 ;
: rcx immediate 1 ;
: rdx immediate 2 ;
: rbx immediate 3 ;
: rsp immediate 4 ;
: rbp immediate 5 ;
: rsi immediate 6 ;
: rdi immediate 7 ;

( stack instructions )
: push immediate 50 + c, ;
: pop immediate 58 + c, ;

( rdtsc )
: rdtsc immediate 0F c, 32 c, ;

decimal

(
RDTSC timestamp counter
)
: rdtsc ( -- lsb msb )
    rdtsc
    rax push ( lsb )
    rdx push ( msb )
;code
\ 48 c, AD c, FF c, 20 c,
\ AD C, FF C, 20 C,
hex
: =next ( addr -- next? )
       dup c@ 48 <> if drop false exit then
    1+ dup c@ AD <> if drop false exit then
    1+ dup c@ FF <> if drop false exit then
    1+     c@ 20 <> if      false exit then
;
decimal

: (inline) ( cfa -- )
    @ ( cw points to code )
    begin ( copy until hit NEXT )
        dup =next not
    while
            dup c@ c,
            1+
    repeat
    drop
;

: inline immediate
    word find ( find it )
    >cfa ( get codeword of it )
    dup @ docol = if ( cw != docol? not a forth word )
        abort
    then

    (inline)
;

hide =next

\ end regular jonesforth phew.....





\ alias (here) here
\ alias (create) create
\ alias (find) find
\ alias (word) word
\ alias (key) key

\ hide non-standard jonesforth words:

\ hide depth
\ \ hide .s
\ hide here
\ hide allot
\ hide create
\ \ hide variable
\ hide find
\ hide while
\ hide repeat
\ hide word
\ \ hide key
\ hide ' \ ( lit is identical )

\ replace non-standard forth words:




\ \ : variable ( "<spaces>name" -- ) create 1 cells allot ;
\
\ \ : key ( -- char ) get ;
\ : ' ( "<spaces>name" -- xt ) word find >cfa ;




\ : while ( c: dest -- orig dest )
\ 	['] 0branch ,	\ compile 0branch
\ 	here 		\ save location of the offset2 on the stack
\ 	swap		\ get the original offset (from begin)
\ 	0 ,		\ compile a dummy offset2
\ ; immediate

\ : repeat ( c: orig dest -- )
\ 	['] branch ,	\ compile branch
\ 	here - ,	\ and compile it after branch
\ 	dup
\ 	here swap -	\ calculate the offset2
\ 	swap !		\ and back-fill it in the original location
\ ; immediate

\ need to rewrite for newlines...
\ : word ( char "<chars>ccc<char>" -- c-addr )
\   0 begin drop
\   source nip >in @ noop <= if drop 0 here c! here exit then \ nothing in buffer
\   (key) 2dup <> until \ skip leading delimiters
\   here -rot begin rot 1+ 2dup c! -rot drop \ store char
\   source nip >in @ <= if drop here - here c! here exit then \ exhausted
\   (key) 2dup = until 2drop here - here c! here
\ ;

: add5 5 5 + ;
\ later nop




\ : does> r> latest @ >dfa ! ;
\ : >body ( xt -- a-addr ) 2 cells + ;


: does1 does> @ 1 + ;
: does2 does> @ 2 + ;

\ create cr1

\ cr1
\ ' cr1 >body
\ 1 ,
\ cr1 @
\ does1 noop
\ cr1 noop














defer num
noop
: ab num ;

: n1 12 ;
: n2 13 ;
noop
' n2 is num
noop
: bard num num + ;

\ 1 constant 8bits
\ 2 constant 16bits
\ 4 constant 32bits
\ 8 constant 64bits

\ : struct 0 ;
\ : field create swap dup , + does> @ + ;
\ : end-struct constant ;


\ : true 1 ;


\ : 2+ 2 + ;
\ : 2- 2 - ;
\ : negate 0 swap 1 ;
\ : not 0= ;
\ : 0! 0 swap ! ;
: 2+! 2 swap +! ;
\ : and! dup @ rot and swap ! ;
\ : or! dup @ rot or swap ! ;

: octal 8 base ! ;
: decimal 10 base ! ;
: hex 16 base ! ;

variable vga_cursor
0 vga_cursor !
\ 753664 vga address

variable bg_color
3840 bg_color !
: display
  bg_color @ or \ add color byte
  753664 vga_cursor @ + \ add offset to vga_cursor
  ! \ print it
  vga_cursor 2+! \ increment vga cursor
;

char w display
char o display
char o display
char t display

: test-do
    4 0 do
        i
        65 i + display
    loop
;

test-do
\ : nt' (word) (find) ;
\ : comp' nt' >cfa
noop
