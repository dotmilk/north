inoop
1 constant 8bits
2 constant 16bits
4 constant 32bits
8 constant 64bits

: struct 0 ;
: field create swap dup , + does> @ + ;
: end-struct constant ;
