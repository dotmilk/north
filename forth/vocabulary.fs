inoop
require @forth/structures.fs
inoop
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
: context sorder_ptr ;

context @ constant forth-impl-wordlist
: forth-impl
    forth-impl-wordlist context ! ;

inoop
nop
