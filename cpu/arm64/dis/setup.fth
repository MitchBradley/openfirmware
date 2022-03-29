\ set in dminit.fth
defer .'
' drop is .'

vocabulary disassembler
only forth also disassembler also definitions
decimal

headerless


\ =======================================
\
\          Utilities
\
\ =======================================


\ Print a double in hex.  Note that we can't simply use d. (in base hex)
\ because the low order value will be printed as a 64 bit number, not
\ a 32 bit # as the disassembler uses doubles.

: dis-ud. ( d -- )
   dup 0= if  drop u. exit  then
   64bit? if
      32 << swap 32 mask and or u.
   else
      ud.
   then
;

\ =======================================
\
\          VARIABLES
\
\ =======================================

variable testing-disassembler  testing-disassembler off
variable instruction

: instruction@ instruction l@ ;
: instruction! instruction l! ;

variable instr-addr
variable end-found
variable display-offset  0 display-offset !

variable dis-pc
: (pc@ ( -- adr ) dis-pc @ ;
defer dis-pc@ ' (pc@ is dis-pc@
: (pc! ( adr -- ) dis-pc ! ;
defer dis-pc!  ' (pc! is dis-pc!
: pc@l@ ( -- opcode ) dis-pc @ l@ ;

: ?.Start-Codetag 
    instruction@ 
    h# 910003ff =   \ add     SSP, SSP, #0
    IF ."  \ ***CODE Start*** " dis-pc @ .' THEN 
    ;
: .End-Codetag    ."  \ ***CODE End*** " cr ;

: +offset  ( adr -- adr' )  display-offset @  -  ;



0 [if]  \ enable this for assembler testing
\
\ Determine if an {n,immr,imms} triplet is valid
\
: {n,immr,imms}? ( datasize n immr imms -- t | f )
   >r >r 2dup if 32 = if 2drop r> r> 2drop false exit then else drop then
   r> r>  dup  6 mask xor  4rot 6 lshift or  highestsetbit  ( len )
   ( len ) dup 1 < if  2drop 2drop false exit  then
   ( len ) >r
   r@ mask land ( S )
   swap r@ mask land ( R )
   swap dup ( R S S )
   1 r@ lshift ( size ) dup >r
   ( S size ) 1- = if r> r> 2drop 2drop drop false exit then
   r> r> 2drop 2drop drop true
;

0 value datasize
0 value N
0 value immr
0 value imms

: test-{n,immr,imms}?
  2 0 do 32 i << is datasize
  2 0 do i is N
  64 0 do i is IMMR
  64 0 do i is IMMS
     datasize dup . N dup . immr dup . imms dup .
     {n,immr,imms}?  drop depth 0 <> if ." BAD: " .s else ." OK" then cr
  loop
  loop
  loop
  loop
;
[then]

