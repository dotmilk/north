: does> r> latest @ >dfa ! ;
: chars ;
: char+ 1 chars + ;
: cell 8 ;
: cells 8 * ;
: allot
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

: / /mod swap drop ;
: '\n' 10 ; \ newline
: bl 32 ; \ blank / space
: false 0 ;
: true 1 ;
: on true swap ! ;
: off false swap ! ;

: 2+ 2 + ;
: 2- 2 - ;
: negate 0 swap 1 ;
: not 0= ;
: 0! 0 swap ! ;
\ : 1+! 1 swap +! ;
\ : 1-! -1 swap +! ;
: and! dup @ rot and swap ! ;
: or! dup @ rot or swap ! ;

: decimal 10 base ! ;
: hex 16 base ! ;

variable vga_cursor
0 vga_cursor !
\ 753664 vga address
\ what is already on the stack
\ where
: display
  3840 or \ add color byte
  \ vga_cursor @ 2 *
  753664 vga_cursor @ + \ add offset to vga_cursor
  ! \ print it
  vga_cursor 1+! \ increment vga cursor
  vga_cursor 1+!
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

\ compile if would be immediate
: [compile] immediate
            word
            find
            >cfa
            ,
:
