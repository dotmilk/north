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
: context sorder-ptr @ ;

\ store ptr top for reset later
context constant sorder-ptr-reset
\ store the wid at context @
context @ constant forth-impl-wordlist
: forth-impl
    forth-impl-wordlist sorder-push ;
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
        sorder-reset
        forth-impl
        drop
    else
        sorder-reset
        dup ( n n - )
        sorder-ptr @ swap ( n ptr n - )
        cells - dup sorder-ptr! swap ( offset n - )
        0 ?do
            ( widn ... wid1 offset )
            dup -rot nop ! ( widn ... wid2 offset - )

            cell + (  - )
        loop
    then ;
context
666 2 1 forth-impl-wordlist 3 nop set-order
nop

\ : set-order ( widn .. wid1 n -- )
\     dup 0= if
