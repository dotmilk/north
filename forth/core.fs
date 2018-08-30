: / /mod swap drop ;
: mod /mod drop ;
: wordsize 8 ;
: '\n' 10 ; \ newline
: bl 32 ; \ blank / space
\ defer emitting words until proper kernel\emit support
\ : cr '\n\' emit ;
\ : space bl emit ;
: negate 0 swap - ; \ negative of n
: true 1 ;
: false 0 ;
: not 0= ;

: literal immediate ' lit , , ;
\ [ ... ] literal is compile time 'macro'
\ where char x become the int for x
\ at compile time and thus
\ : ':' [ char : ] literal ;
\ becomes 'interred' as
\ : ':' 58 literal ;
: ':' [ char : ] literal ;
: ';' [ char ; ] literal ;
: '(' [ char ( ] literal ;
: ')' [ char ) ] literal ;
: '"' [ char " ] literal ;
: 'A' [ char A ] literal ;
: '0' [ char 0 ] literal ;
: '-' [ char - ] literal ;
: '.' [ char . ] literal ;

\ force an otherwise immediate word to compile
: [compile] immediate
    word \ get/eat next word
    find \ find it
    >cfa \ get code word
    , \ append that
;

: recurse immediate
    latest @ \ get current word
    >cfa \ get codeword from it
    , \ append it in place
;

: if immediate
    ' 0branch , \ apppend 0branch
    here @ \ address of current offset on stack
    0 , \ insert dummy offset
;

: then immediate
    dup
    here @ swap - \ get difference of old here and here
    swap ! \ store offset in back-filled location
;

: else immediate
    ' branch , \ unconditional branch over false-part
    here @ \ our offfset
    0 , \ store dummy offset
    swap \ backfill the 'if' offset
    dup \ and so on for then
    here @ swap -
    swap !
;
\ begin loop-stuff condition until
: begin immediate
    here @ \ location to stack
;

: until immediate
    ' 0branch ,
    here @ - \ calculate offset from start of loop
    , \ store that
;

\ begin loop-stuff again
\ infinite loop, must call exit
: again immediate
    ' branch ,
    here @ -
    ,
;

\ begin condition while loop-stuff repeat
: while immediate
    ' 0branch , \ compile 0branch
    here !
    0 ,
;

: repeat immediate
    ' branch ,
    swap \ begin's offset
    here @ - , \ append calculation
    dup
    here @ swap - \ second offset
    swap ! \ backfill
;

\ if but reversed test
: unless immediate
    ' not , \ reverse test
    [compile] if \ literal immediate 'if'
;

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

: nip ( x y -- y ) swap drop ;
: tuck ( x y -- y x y ) swap over ;
: pick ( x_u ... x_1 x_0 u -- x_u ... x_1 x_0 x_u )
    1+ ( +1 for the u on the stack )
    wordsize * ( offset is count * wordsize )
    dsp@ + ( stack ptr + offset )
    @ ( fetch )
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

( depth = stack depth )
: depth ( -- n )
    s0 @ dsp@ -
    8- ( adjust for s0 on stack )
;

: aligned ( addr -- addr )
    7 + 7 invert and ( (addr+7) & ~7 )
;

: align here @ aligned here ! ;

: c,
    here @ c! ( store char in compiled image )
    1 here +! ( inc here by 1 byte )
;

: s" immediate ( -- addr len )
    state @ if ( are we compiling )
        ' litstring ,
        here @ ( save address for length on stack )
        0 , ( dummy length )
        begin
            key ( get char of string )
            dup '"' <>
        while
                ,c ( copy it )
        repeat
        drop ( drop the " char at end )
        dup ( saved addr for length )
        here 2 swap - ( calc length )
        8- ( remove length word )
        swap ! ( backfill length )
        align ( get us to multiple of 8 bytes )
    else ( immediate not copmiling )
        here @ ( start of temp space )
        begin
            key
            dup '"' <>
        while
                over c! ( save )
                1+ ( increment addr )
        repeat
        drop
        here @ - ( length )
        here @ ( push start addr )
        swap ( addr len )
    then
;

\ no ." for now

: chars ;
: char+ 1 chars + ;
: cell 8 ;
: cells ( n -- n ) 8 * ;

: allot ( n -- addr )
  here @ swap
  here +!
;

: variable
  1 cells allot
  word create
  docol ,
  ' lit ,
  ,
  ' exit ,
;

: constant
  word create
  docol ,
  ' lit ,
  ,
  ' exit ,
;

: value ( n -- )
    word create
    docol ,
    ' lit ,
    ,
    ' exit ,
;

: to immediate ( n -- )
    word
    find
    >dfa
    8+
    state @ if ( compiling? )
        ' lit ,
        ,
        ' ! ,
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
        ' lit ,
        ,
        ' +! ,
    else
        +!
    then
;

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

: case immediate
    0 ( mark the end of stack )
;
(
' word , is a common idiom for 'building' in essence saying
' get the address of the code of the next word
, store that 'here' since here is a ariable pointing to where we are in user memory right now
 this is like macros in lisp, dont run this code...return this code in place where it is called )
: of immediate
    ' over ,
    ' = ,
    [compile] if
    ' drop ,
;

: endof immediate
    [compile] else
;

: endcase immediate
    ' drop ,
    begin
        ?dup
    while
            [compile] then
    repeat
;

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

: noname
    0 0 create ( word with no name )
    here @ ( here is xt addr )
    docol , ( the xt )
    ] ( enter compile mode )
;

: ['] immediate
    ' lit ,
;

: exception-marker
    rdrop ( drop param stack ptr  )
    0 ( no exception, normal return path )
;

: catch ( xt -- exn? )
    dsp@ 8+ >r ( p-stack ptr save +8 for xt on rstack )
    ' exception-marker 8+ ( push rdrop address )
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
                ' exception-marker 8+ = if ( found the marker )
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
: rax IMMEDIATE 0 ;
: rcx IMMEDIATE 1 ;
: rdx IMMEDIATE 2 ;
: rbx IMMEDIATE 3 ;
: rsp IMMEDIATE 4 ;
: rbp IMMEDIATE 5 ;
: rsi IMMEDIATE 6 ;
: rdi IMMEDIATE 7 ;

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

: alias
    word create word find >cfa @
    dup docol = if abort then
    ,
; immediate

alias (here) here
alias (create) create
alias (find) find
alias (word) word
alias (key) key

            \ : does> r> latest @ >dfa ! ;

hide depth
hide here
hide allot
hide create
hide variable
hide true
hide find
hide while
    hide repeat
hide word
\ hide key
( apparently lit is the same as ' whatever )
hide '




1 constant 8bits
2 constant 16bits
4 constant 32bits
8 constant 64bits

\ : struct 0 ;
\ : field create swap dup , + does> @ + ;
\ : end-struct constant ;


: true 1 ;
: on true swap ! ;
: off false swap ! ;

: 2+ 2 + ;
: 2- 2 - ;
: negate 0 swap 1 ;
: not 0= ;
: 0! 0 swap ! ;
: 2+! 2 swap +! ;
: and! dup @ rot and swap ! ;
: or! dup @ rot or swap ! ;

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


dnoop
: literal immediate
          ' lit , \ compile lit
          , \ now the literal itself (stack)
;

: ':'
      [ \ immediate mode
      char : \ 58 / : on stack
      ] \ continue compile
             literal \ lit 58
      ;

:

: ';' [ char ; ] literal ;
: '(' [ char ( ] literal ;
: ')' [ char ) ] literal ;
: '"' [ char " ] literal ;
: 'A' [ char A ] literal ;
: '0' [ char 0 ] literal ;
: '-' [ char - ] literal ;
: '.' [ char . ] literal ;
