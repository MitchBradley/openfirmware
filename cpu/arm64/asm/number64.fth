\ number parsing for 64-bit hosts
\ such as arm64

: sext  ( n -- n )  32 <<  32 >>a  ;

: (get-based-number)  ( field$ -- true | n false )
   push-decimal                     \ Save the base and then switch to decimal, default
   set-base                         \ Did the user specify a base?
   $number                          \ Fetch the number
   pop-base                         \ Restore the base
;
: get-based-unumber  ( field$ -- ?? true | n false )
   $asm-execute  if   ( ?? )
      false exit
   then              ( field$ ) 

   (get-based-number)
;
: get-based-number  ( field$ signed -- true | n false )
   \ signed indicates whether to sign-extend on single to double conversion.
   drop    \ Only used for 32bit hosts

   \ The user can override this with a - sign.
   \ Handle preceding signs; accepts -n +n and +-n.
   0 >r                        ( field$  ) ( r: negative )
   over c@ ascii +  = if  1 /string  then
   over c@ ascii -  = if
      1 /string
      r> drop  true >r 
   then                        ( field$  ) ( r: negative )

   $asm-execute  if
      ??adt-immed
      r> if  negate  then
      false exit
   then                       ( field$  ) ( r: negative )

   (get-based-number)         ( true | n false )
   r> over 0= and  if        \ If number is OK and negation flag is true ...
      drop negate
      false
   then
;

: unimm  ( -- n )
   \ pick up a value from the stack?
   "*"?  if  ival@ exit  then

   \ evaluate an expression in single quotes?
   "`"?  if  execute-inline exit  then
   
   <c  scantodelim  c>   get-based-unumber " a number" ?expecting       ( n )
;

: snimm ( -- n )
   "*"?  if  ival@ exit  then
   "`"?  if  execute-inline  exit  then

   <c  scantodelim  c> 
   true get-based-number " a number" ?expecting       ( n )
;

\ zeros after decimal point
: <.@c>='.0' ( -- #zeros )
   <@c> ascii . = if  <c> drop  then
   0  begin  <@c> ascii 0 =  while  1+  <c> drop  repeat
   ;

\ remove trailing zeros
: -trailing0 ( f -- f )
   dup 0<> if
      begin  dup dup 10 / 10 * =  while  10 /  repeat
   then
   ;

\ get integer and fraction of dot fp number from input stream
\ #z is count of leading zeros of the fraction
: i.zfimm ( -- i #z f )
   \ pick up a value from the stack?
   "*"?  if  ival@ exit  then
   \ evaluate an expression in single quotes?
   "`"?  if  execute-inline exit  then
   <c  " . " scanto$  c>   get-based-unumber " a floating point number" ?expecting
   <.@c>='.0'
   <@c> dup ascii 1 < swap ascii 9 > or if 0 else unimm then
   dup 0= if  swap drop 0 then
;

: #i.zfimm ( -- i z f )  "##" i.zfimm ;

: r2exp ( r - exp )   4 - dup 0 < if 8 + then ;
: n2i.zf ( n -- s i z f )
   dup 0x71 = if 1 1 625 exit             \ #1.0625
      exit
   then

   push-decimal
    dup 1 7 << and swap
   dup 0xf and 16 + 10000000 * 16 / swap 4 >> 7 and ( 10000000n r )
   r2exp
   dup 3 >= if
      3 - 1 swap << *
   else
      3 swap - 1 swap << /
   then
   dup 10000000 / dup -rot
   dup 0<> if  10000000 *  then -
   -trailing0 ( s i f ) 0 swap
   pop-base
;

\ also read 0ximm8 and translate to floating point number
: #i.fimm ( -- i f )
   "##"
   " 0x" $find? if
      unimm n2i.zf ( s i z f ) swap " use #1.0625 instead of 0x71 " ?expecting rot drop exit                    \ 0x# format drop sign
   then
   " 0X" $find? if
      unimm n2i.zf ( s i z f ) swap " use #1.0625 instead of 0x71 " ?expecting rot drop exit                    \ 0x# format
   then
   i.zfimm swap " fraction with no leading 0" ?expecting
   ;

: frac#z ( 2f t -- #z newf )
   0 -rot tuck 2dup <> swap dup 0<> rot and if
      2swap swap 2swap ( t z 2f t )
      100 0 DO
         10 / dup 2 < if drop ( i t z nf ) swap dup 0> if swap rot drop else swap rot - then nip unloop exit then
         2dup / 10  i 0 ?do 10 * loop = if ( t z 2f t )
            rot 1+ -rot
         else
            drop rot - unloop exit
         then
      LOOP
   then
   - nip
   ;

: i.f*2 ( i #z f -- i #z f )
   rot 2* -rot dup 2* dup rot ( 2i #z 2f 2f f )
   0 -rot ( i #z 2f cnt 2f f )
   begin
      10 / swap 10 / swap
      dup 0<>
   while
      rot 1+ -rot
   repeat
   ( i #z 2f cnt 2f/10 f/10 )
   drop ( 2i #z 2f cnt t[1 or 0] )
   swap ( 2i #z 2f t cnt ) 1+ 0 ?DO 10 * LOOP ( i2 #z 2f 2f/10*10 )
   ( 2i #z 2f t )
   dup 0<> if ( 2i z 2f t )
      2swap dup 0<> if
         1- 2swap drop
      else
         drop 1+ -rot ( 2i+1 2f t )
         frac#z
      then
   else
      drop
   then
   ( 2i z nf )
   -trailing0
;
: ?fconst ( i z# f -- n r )
   0 -rot ( i cnt z# f )
   begin
      2swap swap dup dup 32 < swap 15 > and not ( z f c i flag )
   while
      dup 31 > if 2drop 2drop " a floating point value that conforms" expecting then
      swap 1+ swap
      ( z# f cnt i ) 2swap ( cnt i z# f ) i.f*2
      2swap swap 2swap
   repeat
   2swap  0<> " a floating point value that conforms" ?expecting            \ f = 0
   drop ( c i )
   2dup dup 31 > swap 16 < or swap 7 > or " a floating point value that conforms" ?expecting
   16 - swap
   3 - dup 0> if 8 swap - else  negate  then
;
\ get integer and fraction of signed dot fp number from input stream
: i.zfsimm ( -- sign i #z f )    "-"? i.zfimm ;                    \ sign neg=-1 pos=0
: #i.zfsimm ( -- sign i #z f )   "##" i.zfsimm ;                   \ sign neg=-1 pos=0

\ process both #0x and #si.f floating point format
: #fimm8 ( - imm8 )
   "##"
   " 0x" $find? if
      unimm exit                             \ 0x# format
   then
   " 0X" $find? if
      unimm exit                             \ 0x# format
   then
   i.zfsimm ( s i z# f ) ?fconst ( s n r )
   4 <<  or  swap 1 and 7 <<  or
;

\ immed-elemsz is a helper function for immed>{n,immr,imms}.  This
\ function will find the smallest element which exists one or more
\ times within the supplied immediate number (given a datasize)

: immed-elemsz ( n-imm regsize -- element elemsz )
   dup 2 do                  ( n-imm regsize                    R: loop )
      >r  dup                ( n-imm n-imm                      R: loop regsize )
      r@ swap                ( n-imm regsize n-imm              R: loop regsize )
      r> i swap i /          ( n-imm regsize n-imm i regsize/i  R: loop )
      n-replicate            ( n-imm regsize n-rotated          R: loop )
      swap >r over           ( n-imm n-rotated n-imm            R: loop regsize )
      - 0= if                ( n-imm                            R: loop regsize )
         r> drop             ( n-imm                            R: loop )
         i mask and          ( n-imm-masked                     R: loop )
         i unloop exit       ( n-imm-masked elemsz )
      then r>                ( n-imm regsize                    R: loop )
   i +loop                   ( n-imm regsize )
;

   
\ immed-rotate is a helper function for immed>{n,immr,imms}.  This
\ function will determine the rotation of imm in order to make the
\ element be: 0{M} 1{N}  (M and N are used in the stack notation
\ below to help identify which values are the count of leading 0's
\ and which is the count of trailing 1's.)
\ However, M is not just the count of leading zeros, it's the count
\ of leading zeros within the specified size, which is why
\    M := CLZ - (64 - size)

\ The loop terminates when M + N = size.

\ n refers to a single bit value in the {n, immr, imms} triplet being
\ constructed by the last bit of the algorithm.  (A piece which ought
\ to be moved to another word entirely.)
\   if size = 64, n := 1
\   else          n := 0

\ imms,p1 is an intermediate value of computing the imms and it's:
\   imms,p1 := ((size - 1) ^ 0x3F) << 1
\ imms is the full imms value and is:
\   imms := ((N - 1) | imms,p1) & 0x3F

\ immr is computed as:
\   immr := size - (i + 1)

\ Note the input number must have at least one 0b and one 1b.
\ (Else the clz below would return -1 and throw the logic off.)

: immed-rotate  ( n-elem size -- n immr imms t | f )
   dup 0 do                       ( n-elem size        R: loop )
      >r                          ( n-elem             R: loop size )
      r@ 1 n-rotate               ( n-elem-rotated     R: loop size )
      dup clz                     ( n-elem clz         R: loop size )
      64 r@ - -                   ( n-elem M           R: loop size )
      over                        ( n-elem M 0 n-elem  R: loop size )
      cto                         ( n-elem M N         R: loop size )
      + r@                        ( n-elem M+N size    R: loop size )
      =  if                       ( n-elem             R: loop size )
         cto                      ( N                  R: loop size )
         r@ 6 rshift 1 and        ( N n                R: loop size )
         r@ 1- -1 xor 2*          ( N n imms,p1        R: loop size )
         rot 1- or 63 and         ( n imms             R: loop size )
         r> i 1+ - swap true      ( n immr imms t      R: loop )
         unloop exit              ( n immr imms t )
      then                        ( n-elem             R: loop size )
      r>                          ( n-elem size        R: loop )
   loop                           ( n-elem size )
   2drop false                    ( f )
;

\ immed>{n,immr,imms} - Determine if an immediate value can be encoded
\ as the immediate operand of a logical instruction for the given register
\ size.  If so, return true with "encoding" set to the encoded value in
\ the form {N, immr, imms}.

: immed>{n,immr,imms}  ( n-imm regsize -- n immr imms t | f)
   \ 0 cannot be represented with n immr imms,
   \ cast that out early
   over 0=  if  2drop false  exit then
   immed-elemsz    ( elem size )
   immed-rotate    ( n immr imms t | f )
;

