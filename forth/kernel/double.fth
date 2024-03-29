\ See license at end of file
purpose: Double number primitives

headers
: 2literal   ( d -- )  swap  [compile] literal  [compile] literal  ; immediate

: d0=   ( d -- flag )  or  0=  ;
: d0<>  ( d -- flag )  or  0<>  ;
: d0<   ( d -- flag )  nip 0<  ;
: d=    ( d1 d2 -- flag )  d- d0=  ;
: d<>   ( d1 d2 -- flag )  d=  0=  ;
: du<   ( ud1 ud2 -- flag )  rot  swap  2dup <>  if  2swap  then  2drop u<  ;
: d<    ( d1 d2 -- flag )  2 pick over = if drop nip u< else nip < nip then  ;
: d>=   ( d1 d2 -- flag )  d< 0=  ;
: d>    ( d1 d2 -- flag )  2swap d<  ;
: d<=   ( d1 d2 -- flag )  2swap d< 0=  ;
: dnegate  ( d -- -d )  0 0  2swap  d-  ;
: dabs     ( d -- +d )  2dup  d0<  if  dnegate  then  ;

: s>d   ( n -- d )  dup 0<  ;
: u>d   ( u -- d )  0  ;
: d>s   ( d -- n )  drop  ;

: (d.)  (  d -- adr len )  tuck dabs <# #s rot sign #>  ;
: (ud.) ( ud -- adr len )  <# #s #>  ;

: d.    (  d -- )     (d.) type space  ;
: ud.   ( ud -- )    (ud.) type space  ;
: ud.r  ( ud n -- )  >r (ud.) r> over - spaces type  ;

: d2*   ( xd1 -- xd2 )  2*  over 0<  if  1+  then  swap  2*  swap  ;
: d2/   ( xd1 -- xd2 )
   dup 2/  swap 1 and  rot 1 rshift  swap
64\ d# 63
32\ d# 31
16\ d# 15
   lshift  or  swap
;

: dmax  ( xd1 xd2 -- )  2over 2over d<  if  2swap  then  2drop  ;
: dmin  ( xd1 xd2 -- )  2over 2over d<  0=  if  2swap  then  2drop  ;

: m+    ( d1|ud1 n -- )  s>d  d+  ;
: 2rot  ( d1 d2 d3 -- d2 d3 d1 )  2>r 2swap 2r> 2swap  ;
: 2nip  ( $1 $2 -- $2 )  2swap 2drop  ;

: drot  ( d1 d2 d3 -- d2 d3 d1 )  2>r 2swap 2r> 2swap  ;
: -drot ( d1 d2 d3 -- d3 d1 d2 )  drot drot  ;
: dinvert  ( d1 -- d2 )  swap invert  swap invert  ;

: dlshift  ( d1 n -- d2 )
   tuck lshift >r                           ( low n  r: high2 )
   2dup bits/cell  swap - rshift  r> or >r  ( low n  r: high2' )
   lshift r>                                ( d2 )
;
: drshift  ( d1 n -- d2 )
   2dup rshift >r                           ( low high n  r: high2 )
   tuck  bits/cell swap - lshift            ( low n low2  r: high2 )
   -rot  rshift  or                         ( low2  r: high2 )
   r>                                       ( d2 )
;
: d>>a  ( d1 n -- d2 )
   2dup rshift >r                           ( low high n  r: high2 )
   tuck  bits/cell swap - lshift            ( low n low2  r: high2 )
   -rot  >>a  or                            ( low2  r: high2 )
   r>                                       ( d2 )
;
: du*  ( d1 u -- d2 )  \ Double result
   tuck u* >r     ( d1.lo u r: d2.hi )
   um*  r> +      ( d2 )
;
: du*t  ( ud.lo ud.hi u -- res.lo res.mid res.hi )  \ Triple result
   tuck um*  2>r  ( ud.lo u          r: res.mid0 res.hi0 )
   um*            ( res.lo res.mid1  r: res.mid0 res.hi0 )
   0  2r> d+      ( res.lo res.mid res.hi )
;

: mask ( #bits -- )
32\        dup h# 20 = if drop 0 1- exit then
64\        dup h# 40 = if drop 0 1- exit then
           1 swap lshift 1-
;

: dmask  ( n -- du )  \ Double-number mask with n low-order bits set
   dup d# 64 = if drop h# ffff.ffff dup exit then
   dup d# 32 and if
      d# 31 and mask h# ffff.ffff swap
   else   ( n )
      mask 0
   then
;


\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
