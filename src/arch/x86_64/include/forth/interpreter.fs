defer [if] immediate
defer [else] immediate
defer [then] immediate
defer [endif] immediate

\ : read-word
\     word find dup 0= if drop then drop ;
: read-word
    word find drop ;

: %lookup-else-or-then
    0 >tmp
    begin
        read-word
        case
            ['] [compile] [if] of tmp> 1+ >tmp endof
            ['] [compile] [else] of
                tmp>
                ?dup 0= if
                    exit
                else
                    >tmp
                then
            endof
            ['] [compile] [then] of
                tmp>
                ?dup 0= if
                    exit
                else
                    1- >tmp
                then
            endof
            ['] [compile] [endif] of
                tmp>
                ?dup 0= if
                    exit
                else
                    1- >tmp
                then
            endof
        endcase

    again ;

: lookup-else-or-then
    not if %lookup-else-or-then then ;

hide %lookup-else-or-then

' lookup-else-or-then is [if]

: lookup-then
    0 >tmp
    begin
        read-word
        case
            ['] [compile] [if] of tmp> 1+ >tmp endof
            ['] [compile] [then] of
                tmp> ?dup 0= if
                    exit
                else
                    1- >tmp
                then
            endof
            ['] [compile] [endif] of
                tmp> ?dup 0= if
                    exit
                else
                    1- >tmp
                then
            endof
        endcase
    again ;

' lookup-then is [else]
' noop is [then]
' noop is [endif]

: [defined] immediate word find nip 0<> ;
: [ifdef] immediate
    postpone [defined]
    postpone [if] ;

: [ifundef] immediate
    postpone [defined]
    not
    postpone [if] ;

[ifdef] snarf
    : snafu 1 2 + ;
[endif]

: blammo 2 3 + ;

[ifdef] blammo
    : kammo 4 5 ;
[endif]
