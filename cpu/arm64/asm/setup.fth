

: bit?   ( n bit# -- bit )   rshift 1 and  ;
: bits?  ( n lobit# width -- bits )   mask -rot >> and  ;

\ support for the metacompiler
\needs 64bit?  : 64bit?   ( -- large? )   bits/cell 64 =  ;
\needs  andc   : andc  ( n n -- n )  not and  ;


\ Define the vocabularies

vocabulary arm64-assembler
only forth also arm64-assembler definitions

vocabulary helpers
only forth also arm64-assembler also helpers definitions

headerless

\ To move from helpers to arm64-assembler
: vocab-assembler ( -- )   only forth also helpers also arm64-assembler definitions  headers  ;
vocab-assembler

\ To move from arm64-assembler to helpers
: vocab-helpers   ( -- )   only forth also arm64-assembler also helpers definitions  headerless  ;
vocab-helpers


\ =======================================
\
\         ASSEMBLER BASICS
\
\ =======================================

defer here      \ ( -- adr )   actual dictionary pointer, metacomp. calculates host/target adresses
defer asm-allot \ ( n -- )     allocate memory in the code address space
defer asm!     \ ( n adr -- ) write n to adr           "
defer asm@     \ ( adr -- n ) read n at adr            "

: resident  ( -- )
\   little-endian
\   aligning? on
   [ also forth ] ['] here          [ previous ] is here
   [ also forth ] ['] allot         [ previous ] is asm-allot
   [ also forth ] ['] le-l@         [ previous ] is asm@
   [ also forth ] ['] instruction!  [ previous ] is asm!
;
resident


vocab-assembler

0 value dis-asm-en
defer .dis-asm
' noop is .dis-asm
: dis-asm  ( n a -- n a )
   dis-asm-en if  2dup swap .dis-asm cr  then
;

: asm,  ( n -- )  here  dis-asm  /l asm-allot  asm! ;


vocab-helpers

0 constant pc->here    \ used by labels, non-zero for ARM32


\ A char buffer of the input source to process
create cbuf   /tib allot
0 value clen         \ number of chars in cbuf
0 value cin          \ current offset into cbuf
0 value mark-start   \ cin at the start of parsing an item

