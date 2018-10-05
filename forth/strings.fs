: s" immediate ( -- addr len )
    state @ if ( are we compiling )
        lit litstring ,
        here ( save address for length on stack )
        0 , ( dummy length )
        begin
            key ( get char of string )
            dup '"' <>
        while
                c, ( copy it )
        repeat
        drop ( drop the " char at end )
        dup ( saved addr for length )
        here swap - ( calc length )
        8- ( remove length word )
        swap ! ( backfill length )
        align ( get us to multiple of 8 bytes )
    else ( immediate not compiling )
        here ( start of temp space )
        begin
            key
            dup '"' <>
        while
                over c! ( save )
                1+ ( increment addr )
        repeat
        drop
        here - ( length )
        here ( push start addr )
        swap ( addr len )
    then
;

: blank ( c-addr u - )
    32 fill ;

: /string ( caddr1 u1 n - caddr2 u2 )
    tuck - >r + r> ;

: -trailing ( caddr u1 - caddr u2 )
    begin 2dup 1- + c@ 32 = over 0<> and while 1- repeat ;

: pack ( addr1 u addr2 -- addr2 )
    2dup 2>r 1+ swap move 2r> tuck c! ;

: place ( addr1 u addr2 -- )
    pack drop ;

alias c>addr place
\ compat origianlly spelled pad c>addr pad
: c-addr ( addr u -- c-addr )
    pad pack ;

create nextname-buffer 32 allot

: nextname ( addr u --  )
    nextname-buffer pack
    1 compiling-nextname !
    count ;
