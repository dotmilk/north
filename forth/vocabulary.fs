require @forth/structures.fs

variable last-wid

struct
    cell field wid-latest
    cell field wid-method
    cell field wid-name
    cell field wid-previous
end-struct wid%

: wid>latest wid-latest @ ;

: wid>name ( wid -- addr n )
    wid-name @ ?dup if count else 0 0 then ;

\ eulex spells it sorder_stack sorder_tos @ cells +
: context sorder-ptr @@ ;

\ store the wid at context @
context @ constant forth-impl-wordlist
: forth-impl
    forth-impl-wordlist context ! ;
forth-impl-wordlist last-wid !

: get-order ( -- widn .. wid1 n )
    sorder-stack @ \ top of stack wid1
    begin
        8- \ decrement from position / top of sorder-stack
        dup \ push position to stack
    dup sorder-ptr @@ = until \ are we at the ptr?
    drop \ drop extra copy
    sorder-stack @ 8-
    sorder-ptr @@ -
    8 /
    1 +
;

: set-order
    dup 0= if
        nop
    else
        nop
    then ;

context
nop
sorder-ptr
nop
sorder-ptr @
nop
sorder-ptr @@
nop

\ : set-order ( widn .. wid1 n -- )
\     dup 0= if
