purpose: Target-dependent definitions for metacompiling the kernel for ARM64
\ See license at end of file

hex

100.0000 constant max-kernel           \ Maximum size of the kernel

only forth also  meta also definitions

\ notation
\ We need to distinguish between host and target versions of things,
\ and we need operators that work from one space to the other.
\ -t modifies the preceeding character, so
\ l!-t  stores a host-long to a target address
\ l-t!  stores a target-long to a host address


variable protocol?   protocol? off        \ true -> information about compiled code
variable last-protocol

: .data  ( n adr -- )
   push-hex
   dup last-protocol @ xor  0ffffff0 and  0<>   \ different address?
   over d# 12 and  3 * d# 15 + dup >r           ( n adr new? col )  ( r: col )
   #out @ <  or                                 ( n adr show-adr? )
   if      0ffffff0 and  dup last-protocol !  cr 9 u.r
   else    drop
   then                                         ( n )  ( r: col )
   r> to-column  8 u.r       \ always show the data
   pop-base
;
: .protocol  ( c t-adr -- )  protocol? @  if  2dup .data  then  ;

         2 constant /w-t
         4 constant /l-t
         8 constant /x-t
         8 constant /n-t
         4 constant /a-t
      /a-t constant /thread-t
         4 constant /token-t
         4 constant /link-t
/token-t   constant /defer-t
/n-t th 2000 * constant user-size-t
/n-t th 1000 * constant ps-size-t
/n-t th 1000 * constant rs-size-t
/n-t constant /user#-t

\ arm64 target
: arm64-t?  ( -- flag )  true  ;
: arm-t?    ( -- flag )  false  ;
: x86-t?    ( -- flag )  false  ;

\ 32 bit host Forth compiling 64-bit target Forth
: l->n-t 0 ;
: n->l-t ;
: n->n-t s>d ;
: s->l-t ;

: c!-t  ( n t-adr -- )   >hostaddr c! ;
: c@-t  ( t-adr -- n )   >hostaddr c@ ;
\ : w!-t  ( n t-adr -- )   .protocol >hostaddr le-w! ;
\ : w@-t  ( t-adr -- n )   >hostaddr le-w@ ;

: l!-t  ( l t-adr -- )   .protocol >hostaddr  le-l! ;
: d!-t  ( d t-adr -- )   .protocol >hostaddr  dup >r 4 + le-l! r> le-l! ;
: n!-t  ( n t-adr -- )   .protocol >hostaddr  >r n->n-t r@ 4 + le-l! r> le-l! ;

: l@-t  ( t-adr -- l )   >hostaddr  le-l@ ;
: d@-t  ( t-adr -- d )   >hostaddr  dup le-l@ swap 4 + le-l@ ;

: !-t   ( d t-adr -- )   d!-t ;
: @-t   ( t-adr -- d )   d@-t ;

\ Store target data types into the host address space.
: c-t!  ( c h-adr -- )  c! ;
: l-t!  ( l h-adr -- )  le-l! ;
: n-t!  ( n h-adr -- )  dup >r 4 + n->n-t swap l-t!  r> l-t! ;
\ : w-t!  ( w h-adr -- )  le-w! ;

: c-t@  ( host-address -- c )  c@  ;
: l-t@  ( host-address -- l )  le-l@  ;

: c,-t  ( byte -- )  here-t     1 allot-t c!-t ;
: l,-t  ( long -- )  here-t  /l-t allot-t l!-t ;
: d,-t  ( d -- )   swap l,-t  l,-t ;
: n,-t  ( n -- )   s>d d,-t ;

: w,-t  true abort" Called w,-t"  ;
\ : w,-t ( word -- )  here-t  /w-t allot-t w!-t ;

: ,-t      ( adr -- )           d,-t ;
: ,user#-t ( user# -- )         d,-t ;    \ FIXME shouldnt this be l,-t ???

: a@-t     ( t-xt -- t-adr )    l@-t ;
: a!-t     ( token t-adr -- )   l!-t ;
: token@-t ( t-adr -- t-adr )   a@-t origin-t +  ;
: token!-t ( token t-adr -- )   swap origin-t - swap  a!-t  ;

\ FIXME  this looks wrong, unbalanced
: rlink@-t  ( occurrence -- next-occurrence )  a@-t  ;
: rlink!-t  ( next-occurrence occurrence -- )  token!-t  ;


\ Machine independent
: a,-t     ( adr -- )   here-t /a-t allot-t  a!-t  ;
: token,-t ( token -- ) here-t /token-t allot-t  token!-t  ;

\ These versions of linkx-t are for offsets from origin: smaller and relocatable
: link@-t  ( t-adr -- t-off' )   a@-t  ;
: link!-t  ( t-off t-adr -- )    a!-t  ;
: link,-t  ( t-off -- )          a,-t  ;

\ XXX why are these complex?
: a-t@   ( host-address -- target-address )
[ also forth ]
   dup  origin here within  over up@  dup user-size +  within  or  if
[ previous ]
      l@
   else
      hostaddr> a@-t
   then
;
: a-t!  ( target-address host-address -- )
[ also forth ]
   dup  origin here within  over up@  dup user-size +  within  or  if
[ previous ]
      l!
   else   
      hostaddr> a!-t
   then
;
: rlink-t@  ( host-adr -- target-adr )  a-t@  ;
: rlink-t!  ( target-adr host-adr -- )  a-t!  ;

: token-t@  ( host-adr -- t-adr )  a-t@  ;
: token-t!  ( t-adr host-adr -- )  a-t!  ;
: link-t@   ( host-adr -- t-adr )  a-t@  ;
: link-t!   ( t-adr host-adr -- )  a-t!  ;

: a-t,      ( t-adr -- )         here /a-t allot  a-t!  ;
: token-t,  ( t-adr -- )         here /token-t allot token-t! ;
[ifdef] itc
: >body-t   ( cfa-t -- pfa-t )   /a-t +  ;
[else]
: >body-t   ( cfa-t -- pfa-t )
   dup l@-t  7C000000 and 14000000 =
   if  /a-t +  then
;
[then]
: >body  >body-t  ;

\ XXX try more threads for speed ... Fails!
1 constant #threads-t       \ Must be a power of 2
create threads-t   #threads-t 1+ /link-t * allot

: $hash-t   ( adr len voc-ptr -- thread )
   -rot nip #threads-t 1- and  /thread-t * +
;

\ Should allocate these dynamically.
\ The dictionary space should be dynamically allocated too.

\ The user area image lives in the host address space.
\ We wish to store into the user area with -t commands so as not
\ to need separate words to store target items into host addresses.
\ That is why user+ returns a target address.

\ Machine Independent

0 constant userarea-t
: setup-user-area       ( -- )
   here-t  is userarea-t
   user-size-t allot-t
   userarea-t >hostaddr user-size-t  erase
;

: >user-t   ( cfa-t -- user-adr-t )
   >body-t @-t  abort" user-address must not actually have the high 32 bits set" 
   userarea-t + >hostaddr
;
: n>link-t  ( anf-t -- alf-t )  /link-t - ;
: l>name-t  ( alf-t -- anf-t )  /link-t + ;

\ This implementation uses 4-byte tokens, 4-byte links, and a single
\ 4-byte instruction at acf.
decimal
4 constant #align-t
4 constant #talign-t
4 constant #acf-align-t

: (aligned-t)  ( n alignment -- n' )
   tuck  1- +  swap  negate and
;
: aligned-t      ( n1 -- n2 )      #align-t (aligned-t)  ;
: acf-aligned-t  ( n1 -- n2 )  #acf-align-t (aligned-t)  ;

: (align-t) ( n -- )
   1- begin  dup here-t and   while   0 c,-t   repeat drop
;
: align-t      ( -- )      #align-t (align-t)  ;
: talign-t     ( -- )     #talign-t (align-t)  ;
: acf-align-t  ( -- )  #acf-align-t (align-t)  ;

: entercode     ( -- )
   only forth also labels also meta also assembler
   [ also assembler also helpers ]
   [ previous previous ]
\   acf-align-t
;

\ Next 5 are Machine Independent
: cmove-t   ( from to-t n -- )
   2dup 2>r                      ( r: to-t n )
   0 ?do      ( from to-t )
      over c@ over c!-t  ca1+ swap ca1+ swap
   loop
   2drop 2r>         ( to-t n )
   protocol? @
   if
      base @ >r  hex
      last-protocol off
      cr ." String at" over 6 u.r space ascii " emit bounds
      do      i c@-t dup bl <
	 if drop else emit then
      loop    ascii " emit
      r> base !
   else
      2drop
   then
;
: place-cstr-t  ( adr len cstr-adr-t -- cstr-adr-t )
   >r  tuck r@ swap cmove-t  ( len ) r@ +  0 swap c!-t  r>
;
: "copy-t   ( from to-t -- )   over c@ 2+  cmove-t  ;
: toggle-t  ( addr-t n -- )
   protocol? @ if
      base @ >r hex
      cr ." Toggle at"   2dup swap  6 u.r  3 u.r
      last-protocol off
      r> base !
   then                   ( addr-t n )
   swap >r r@ c@-t xor r> c!-t
;

: clear-threads-t  ( hostaddr -- )
   #threads-t /link-t * bounds  do
      origin-t i link-t!
   /link +loop
;
: initmeta      ( -- )
   threads-t   #threads-t /link-t * bounds do
      origin-t i link-t!
      threads-t current-t !
   /link +loop
   last-protocol on
;

\ For compiling branch offsets/addresses used by control constructs.
/l-t constant /branch

: branch!      ( from to -- )  over -  swap  l!-t  ;
: branch,      ( to -- )   here-t -  l,-t  ;

\ Store actions for some data structures.
\ In this version, the user area is in the dictionary.
: isuser      ( n acf -- )        >user-t n-t!  ;
: istuser     ( acf1 acf -- )     >user-t token-t!  ;
: isvalue     ( n acf -- )        >user-t n-t!  ;
: isdefer     ( acf acf -- )      >user-t token-t!  ;

: thread-t!   ( thread adr -- )   link!-t  ;


only forth also meta also definitions
: install-target-assembler
   [ also assembler also helpers ]
   ['] allot-t is asm-allot
   ['] here-t  is here
   \ ['] c!-t    is byte!
   ['] l!-t    is asm!
   ['] l@-t    is asm@
   [ previous previous ]
;
: install-host-assembler  ( -- )
   [ assembler ] resident [ meta ]
;

decimal

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
