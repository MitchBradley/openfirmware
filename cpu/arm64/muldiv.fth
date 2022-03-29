purpose: Multiply and divide
\ See license at end of file


code  *   ( n1 n2 -- n3 )  pop x0,sp  mul  tos,x0,tos  c;
code u*   ( u1 u2 -- u3 )  pop x0,sp  mul  tos,x0,tos  c;
code  /   (  N  D --  Q )  pop x0,sp  sdiv tos,x0,tos  c;
code u/   ( uN uD -- uQ )  pop x0,sp  udiv tos,x0,tos  c;

code /mod (  N  D -- R Q )
   pop     x0, sp           \ N
   mov     x1, tos          \ D
   sdiv    tos, x0, x1      \ TOS = quotient
   msub    x0, tos, x1, x0  \ X0 = remainder
   push    x0, sp
c;

: mod    (  N  D -- modulus )  /mod drop  ;

code um*  ( u1 u2 -- ud )
   pop     x4,sp
   mul     x0,tos,x4    \ Compute the low 64 bits
   umulh   x1,tos,x4    \ Compute the high 64 bits of TOS * X4
   psh     x0,sp
   mov     tos,x1
c;

code m*  ( n1 n2 -- d )
   pop     x4,sp
   mul     x0,tos,x4    \ Compute the low 64 bits
   smulh   x1,tos,x4    \ Compute the high 64 bits of TOS * X4
   psh     x0,sp
   mov     tos,x1
c;

code u/mod  ( u.dividend u.divisor -- u.rem u.quot )
   pop     x0, sp
   mov     x1, tos
   udiv    tos, x0, x1      \ TOS = quotient
   msub    x0, tos, x1, x0  \ X0 = remainder
   push    x0, sp
c;

\ Helper: count leading zeros
code clz   ( n -- # )    clz   tos, tos  c;

\ div128: on this arch, double / double division, double remainder, quotient
\ Algorithm by Tracy Allen, http://www.emesystems.com/division.htm
\
\ On entry, we know that
\   Nhi != 0
\     D != 0
\   N,D  > 0
\     N  > D
: div128  ( dN dD -- dR dQ )
    2over nip clz            ( dN dD leadingzeros )
    >r 2swap r@ dlshift      ( dD dN' R: lz )
    0 0 0 0 d# 128 r> -      ( dD dN dR dQ #sigbits-in-N )
    ( #sigbits-in-N ) 0 do   ( dD dN dR dQ )
        2>r                  ( dD dN dR R: dQ )
        1 dlshift            ( dD dN dR' R: dQ )
        2over nip 0<  if     \ copy N:MSbit into R
            1 0 d+           ( dD dN dR' R: dQ )
        then
        2r> 1 dlshift 2>r    ( dD dN dR' R: dQ' )
        2>r 1 dlshift        ( dD dN' R: dQ' dR' )
        2over 2dup 2r@       ( dD dN' dD dD dR' R: dQ' dR' )
        d> if                ( dD dN' dD R: dQ' dR' )
            \ D > R: 
            2drop 2r> 2r>
        else                 ( dD dN' dD R: dQ' dR' )
            \ D <= R: increment Q and replace R with R - D
            2r> 2r>          ( dD dN' dD dR' dQ' )
            1 0 d+ 2>r       ( dD dN' dD dR' R: dQ" )
            2swap d- 2r>     ( dD dN' dR" dQ" )
        then
    loop                     ( dD dN' dR" dQ" )
    2rot 2drop 2rot 2drop
;
 \ signed double by double division
: d/mod  ( d.N d.D -- d.rem d.quot )
   \ D = 0?
   2dup d0=  if  4drop -1 -1 2dup exit  then
   \ N < D?
   2over 2over du<  if  2drop 0 0 exit  then
   \ Nhi = 0?
   2 pick 0=  if           \ Dhi must be zero from previous step
      drop nip u/mod 0 tuck exit
   then                      ( ud.N ud.D )
   \ N < 0?
   1 >r dup 0< >r -rot r>  if
     2swap dnegate 2swap r> negate >r
   then                      ( Nlo Nhi Dlo Dhi R: sign )
   \ D < 0?
   dup 0<  if  dnegate r> negate >r  then
   div128
   r> 0<  if  dnegate  then
;

\ unsigned double by double division primitive
code udiv128  ( dN dD -- dR dQ )
   mov     x3,tos               \ divisor
   pop     x2,sp                \ x3: Dhi  x2: Dlo  
   pop     x1,sp                \ dividend, also inital remainder
   pop     x0,sp                \ x1: Rhi  x0: Rlo
   movz    x4,#0                \ quotient
   movz    x5,#0                \ x5: Qhi  x4: Qlo
   push2   x8,x9,sp
   push2   x10,x11,sp
   
   \ determine initial shift
   cmp    x1,#0
   0= if  \ Nhi is 0
      clz    x10,x0
      add    x8,x10,#64
   else
      clz    x8,x1
   then                         \ x8: lzN
   cmp    x3,#0
   0= if  \ Dhi is 0
      clz    x10,x2
      add    x9,x10,#64
   else
      clz    x9,x3
   then                         \ x9: lzD
   subs    x8,x9,x8             \ x8: ishift
   u< if   \ N u< D
      pop2   x10,x11,sp
      pop2   x8,x9,sp
      push   x0,sp              \ R = N
      push   x1,sp
      push   x4,sp              \ Q = 0
      mov    tos,x5
      next
   then
   \ D u<= N
   movz   x6,#0     \ increment
   movz   x7,#0     \ x7: Ihi  x6: Ilo

   cmp    x8,#64
   u>= if                       \ large shift
      lsl    x3,x2,x8           \ shift Dhi by low 6 bits of x8
      mov    x2,xzr             \ Dlo = 0
      movz   x7,#1
      lsl    x7,x7,x8           \ shift Ihi
   else
      cmp    x8,#0
      0<> if
	 neg    x9,x8
	 lsr    x10,x2,x9          \ overflow bits
	 lsl    x3,x3,x8           \ shift D left
	 lsl    x2,x2,x8
	 orr    x3,x3,x10
      then
      movz   x6,#1
      lsl    x6,x6,x8           \ shift Ilo 
   then                         \ D and I are shifted left so first set bit matches N
   \ ready to iterate
   begin
      \ subtract D from R
      subs    x0,x0,x2
      sbcs    x1,x1,x3
      0< if     \ add D to R
	 adds    x0,x0,x2
	 adc     x1,x1,x3
      else      \ add I to Q
	 adds    x4,x4,x6
	 adc     x5,x5,x7
      then
      lsr     x2,x2,#1       \ shift D right 1
      orr     x2,x2,x3,lsl #63
      lsr     x3,x3,#1
      lsr     x6,x6,#1       \ shift I right 1
      orr     x6,x6,x7,lsl #63
      lsr     x7,x7,#1
      subs    x8,x8,#1
   0< until
   pop2   x10,x11,sp
   pop2   x8,x9,sp
   push   x0,sp       \ R
   push   x1,sp
   push   x4,sp       \ Q
   mov    tos,x5
c;

0 [if] \ udiv128
: udiv128  ( udN udD -- udR udQ )
   2 pick clz           ( udN udD leadingzeros )
   >r 2swap r@ dlshift      ( udD udN' R: lz )
   0 0 0 0 d# 128 r> -      ( udD udN udR udQ #sigbits-in-N )
   ( #sigbits-in-N ) 0 ?do  ( udD udN udR udQ )
      1 dlshift 2>r        ( udD udN udR R: udQ )
      1 dlshift            ( udD udN udR' R: udQ )
      2 pick 0<  if     \ copy N:MSbit into R
	 1 0 d+           ( udD udN udR' R: udQ )
      then
      2>r 1 dlshift        ( udD udN' R: udQ' udR' )
      2over 2r@            ( udD udN' udD udR' R: udQ' udR' )
      du> if               ( udD udN' R: udQ' udR' )
	 \ D > R: 
	 2r> 2r>
      else
	 2over             ( udD udN' udD R: udQ' udR' )
	 \ D <= R: increment Q and replace R with R - D
	 2r>  2swap d-     ( udD udN' udR'' R: udQ' )
	 2r>  1 0 d+       ( udD udN' udR'' udQ" )
      then
   loop                     ( udD udN' udR" udQ" )
   2>r 2>r 4drop 2r> 2r>
;
[then]
\ unsigned double by double division  
: du/mod  ( ud.N ud.D -- ud.rem ud.quot )
   \ D = 0?
   2dup d0=  if  4drop -1 -1 2dup exit  then
   \ N < D?
   2over 2over du<  if  2drop 0 0 exit  then
   \ Nhi = 0?
   2 pick 0=  if           \ Dhi must be zero from previous step
      drop nip u/mod 0 tuck exit
   then                      ( ud.N ud.D )
   udiv128
;
\ unsigned double by single division
: um/mod  ( ud u -- u.rem u.quot )
   0 udiv128 drop nip
;
\ symmetrical double by single division (rounds towards zero)
: sm/rem  ( d n -- rem quot )
   0                           ( d n sign )
   2 pick 0<  if               ( d n sign )
      1+  2swap dnegate 2swap  ( +d n sign )
   then                        ( +d n sign )
   over 0<  if                 ( +d n sign )
      2+  swap negate swap     ( +d +n sign )
   then                        ( +d +n sign )
   >r um/mod r>                ( u.rem u.quot sign )
   case
      1 of  swap negate swap negate  endof  \ -dividend, +divisor
      2 of  negate                   endof  \ +dividend, -divisor
      3 of  swap negate swap         endof  \ -dividend, -divisor
   endcase
;
\ floored double by single division (rounds towards minus infinity)
: fm/mod  ( d.dividend n.divisor -- n.rem n.quot )
   2dup xor 0<  if        \ Fixup only if operands have opposite signs
      dup >r  sm/rem                                ( rem' quot' r: divisor )
      over  if  1- swap r> + swap  else  r> drop  then
      exit
   then
   \ In the usual case of similar signs (i.e. positive quotient),
   \ sm/rem gives the correct answer
   sm/rem   ( n.rem' n.quot' )
;

\ scaling: multiply then divide, with double precision intermediate
: */mod  ( n1 n2 n3 -- n.mod n.quot )  >r m* r> fm/mod  ;
: */     ( n1 n2 n3 -- n.quot )  */mod nip  ;

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
\
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
