\ miscellaneous utility words
\ Some of these are generally useful, and they are collected here
\ to make them easier to find. Some may end up in the kernel.

: 't   ( -- token )  ' origin -  ;

\ branch&link target... redundant; too lazy to sort it out now
: dest   ( a1 -- a2 )
    dup l@ dup d# 24 >> h# fc and h# 94 <> if  ." not a branch "  2drop exit  then  ( a1 opcode )
    dup h# 0200.0000 and if  h# fC00.0000 or l->n  else  h# 03ff.ffff and  then  2 << + 
;
: dest-  ( a1 -- t2 )   dest origin -  ;

: dw  ( -- )  ' h# 10 - h# 40 ldump ;




\needs 2and  : 2and  ( d d -- d )  rot and -rot and swap ;
\needs 2or   : 2or   ( d d -- d )  rot  or -rot  or swap ;
\needs 2xor  : 2xor  ( d d -- d )  rot xor -rot xor swap ;

\needs 2nip  : 2nip  ( n1 n2 n3 n4 -- n3 n4 )  2swap 2drop  ;
\needs 2not  : 2not  ( d -- d )  not swap not swap ;
\needs 2andc : 2andc ( d d -- d )  2not 2and ;

: 4rot  ( a b c d   -- b c d a   )   >r    rot r>    swap  ;
: -4rot ( b c d a   -- a b c d   )   swap  >r  -rot  r>    ;
: 5rot  ( a b c d e -- b c d e a )   2>r rot 2r> rot   ;
: -5rot ( b c d e a -- a b c d e )   -rot 2>r -rot 2r> ;

\ highestsetbit will compute the bit # of the highest set bit in a
\ single.  The possible output values are 0..31 or -1.  The latter
\ indicates that no input bits were set.
\ used only by the disassembler
: highestsetbit  ( n -- bit# )
   dup 0= if  drop -1 exit  then
   0 31 do
      dup i >> 1 and if  drop i unloop exit  then
   -1 +loop
;


\ On 32 bit machines (i.e., cell size of 4 bytes) the following algorithm
\ is a NOP; but it consumes time.
\ On 64 bit machines (i.e., cell size of 8 bytes) it adjusts the hi/lo
\ cells so that neither is larger than 32 bits.  This algorithm is used
\ to allow a bunch of logic which was designed to work on 32 bit machines
\ with doubles to continue to work on 64 bit machines.  The ideal thing
\ to do would be to change a bunch of the logic to correctly use a single
\ cell on 64 bit machines; but I haven't got time for that today.
\ The challenge is fun and so I'll keep it open as something to do.

: d32mask ( n1 n2 -- n1 n2 )
   n->l  swap
   n->l  swap
;


\ XXX should these words be replaced by the code dl words?
\   No. Only the disassembler still uses these. Modify it, then
\   replace these with 64-bit single number versions.

\ dl->> will shift a double right some number of bits.
\ This algorithm works with 32 bit values in the hi/lo cells even on 64 bit machines.

\ The basic algorithm is to:
\ 1. Special case 64 or more: return 0
\ 2. Special case 32 or more: return the high half shifted
\ 3. Shift the low half
\ 4. Mask the portion of the high half that needs to go to the low half
\ 5. Left shift the portion from (4)
\ 6. OR pieces (4) and (5)
\ 7. Shift the high half
\ 8. Mask both halves for 32 bit values

\ TEST CODE:
\   44 0 do   76543210 FEDCBA98  i dl->> 8x_ 8x cr  4 +loop

: dl->>  ( d n -- d )
   ( 1.) dup 64 >= if  drop 2drop 0 0  exit  then
   ( 2.) dup 32 >= if  31 and rot drop rshift n->l 0  exit  then
   ( 3.) >r  swap  r@  rshift
   ( 4.) swap  dup  r@  mask  and
   ( 5.) 32  r@  -  lshift
   ( 6.) rot or
   ( 7.) swap r> rshift
   ( 8.) d32mask
;

\ dl-<< will shift a double left some number of bits.

\ The algorithm here is a little different than above.
\ 1. Special case 64 or more: return 0
\ 2. Special case 32 or more: return the low half shifted
\ 3. Shift the high half
\ 4. Create a mask for the low half
\ 5. Apply the mask
\ 6. Shift the masked portion down to the lowest bit positions and OR into the high half
\ 7. Shift the low half
\ 8. Mask both halves for 32 bit values

\ TEST CODE:
\   44 0 do  FEDCBA98 1234  i dl-<< 8x_ 8x cr  4 +loop

: dl-<<  ( d n -- d )
   ( 1.) dup 64 >= if  drop 2drop 0 0  exit  then
   ( 2.) dup 32 >= if  swap drop 31 and lshift n->l 0 swap  exit  then
   ( 3.) >r  r@  lshift
   ( 4.) swap  dup  r@  mask
   ( 5.) 32  r@  -  lshift  and
   ( 6.) 32  r@  -  rshift  rot  or
   ( 7.) swap  r>  lshift  swap
   ( 8.) d32mask
;


\ d-Rotate <size> bits within a double <shft-cnt> bits TO THE RIGHT
\ The basic algorithm is:
\ 1. Rotate the <d-patt> right
\ 2. Rotate the <d-patt> left
\ 3. OR the two rotations
\ 4. MASK the low order <size> bits.

\ TEST CODE:
\   FEDCBA98 1234 2dup 16x_ cr
\   10 0 do  30 4 drotate  2dup 16x_ cr  loop

: d-rotate ( d-patt size shft-cnt -- d-patt )
   swap >r >r
   ( 1.) 2dup r@ dl->>
   ( 2.) 2swap r> r@ swap - dl-<<
   ( 3.) 2or
   ( 4.) r> dmask 2and
   ( 5.) d32mask
;

: n-rotate ( n size shft-cnt -- n )
  swap >r >r
   ( 1.) dup r@ >>
   ( 2.) swap r> r@ swap - <<
   ( 3.) or
   ( 4.) r> mask and
;

\ dreplicate is a highly specialized algorithm used in the creation
\ of immediate values from {n, immr, imms} triplets.  Basically it
\ takes the low order #bits from d-patt and then replicates it N
\ times #bits apart in the output pattern.

: d-replicate ( d-patt #bits n -- d )
   >r dup >r dmask 2and           ( d-patt-masked                         R: n #bits )
   0 0                            ( d-patt-masked d-result                R: n #bits )
   r> r> 0 do                     ( d-patt-masked d-result #bits          R: loop 0..n-1 )
      >r 2over 2or                ( d-patt-masked d-result                R: loop 0..n-1 #bits )
      2swap r@ dl-<<               ( d-result d-patt-masked-shifted        R: loop 0..n-1 #bits )
      2swap r>                    ( d-patt-masked-shifted d-result #bits  R: loop 0..n-1 )
   loop                           ( d-patt-masked-shifted d-result #bits )
   drop 2swap 2drop               ( d-result )
   d32mask
;

: n-replicate  ( n-patt #bits n -- n )
   >r dup >r mask and             ( n-patt-masked                         R: n #bits )
   0                              ( n-patt-masked n-result                R: n #bits )
   r> r> 0 do                     ( n-patt-masked n-result #bits          R: loop 0..n-1 )
      >r over or                  ( n-patt-masked n-result                R: loop 0..n-1 #bits )
      swap r@ <<                  ( n-result n-patt-masked-shifted        R: loop 0..n-1 #bits )
      swap r>                     ( n-patt-masked-shifted n-result #bits  R: loop 0..n-1 )
   loop                           ( n-patt-masked-shifted n-result #bits )
   drop nip                       ( n-result )
;

\ goto-n  A caller has a list of N words that follow this word's
\         xt.  Use the index on the stack to execute one of those
\         words.  One way to use this is:
\ : a ." Hello" ;
\ : b ." world" ;
\ : foo ( idx -- ) goto-n: a  b  cr  ;
\   3 0 do i foo loop
\ : goto-n:  ( idx -- )   cells  r>  +  token@  ( xt )  ?execute  ;


( Here's some code from the PowerPC assembler that will handle
    *
  | <based-number>
where <based-number> is
    <decimal-digits>
  | d#<decimal-digits>
  | h#<hex-digits>
  | 0x<hex-digits>
  | o#<octal-digits>
  | b#<binary-digits>
   )

\ If adr2,len2 is an initial substring of adr1,len1, return the remainder
\ of the adr1,len1 string following that initial substring.
\ Otherwise, return adr1,len1
: ?remove ( adr1 len1 adr2 len2 -- adr1 len1 false | adr1+len2 len1-len2 true )
   2 pick  over  u<  if  2drop false exit  then      \ len2 too long?
   3 pick  rot  2 pick   ( adr len1 len2  adr1 adr2 len2 )
   caps-comp 0=  if  /string true  else  drop false  then
;
: set-base  ( adr len -- adr' len' )
   " h#" ?remove  if  hex     exit  then
   " 0x" ?remove  if  hex     exit  then
   " d#" ?remove  if  decimal exit  then
   " o#" ?remove  if  octal   exit  then
   " 0o" ?remove  if  octal   exit  then
   " b#" ?remove  if  binary  exit  then
   " 0b" ?remove  if  binary  exit  then
;



