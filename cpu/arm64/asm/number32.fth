\ number parsing for 32-bit hosts
\ such as x86

: sext  ( n -- n ) ;   \ sign extension is only needed on 64-bit systems

\ dmask generate a double mask of <#bits> one bits starting from bit 0.
\ In C it's written:
\     (1LL << n) -1
: dmask  ( n -- du )
   dup 64 = if drop h# FFFF.FFFF dup exit then
   dup 32 and if
      31 and mask h# FFFF.FFFF swap
   else   ( n )
      mask 0
   then
;

: (get-based-number)  ( signed field$ -- true | d false )
   push-decimal                     \ Save the base and then switch to decimal, default
   set-base                         \ Did the user specify a base?
   $dnumber                         \ Fetch the number, converted to double
   pop-base                         \ Restore the base
;
: get-based-unumber  ( field$ -- ?? true | d false )
   $asm-execute  if   ( ?? )
      dup adt-immed = if  drop  then
      0 false exit
   then              ( field$ ) 

   0 -rot (get-based-number)
;
: get-based-number  ( field$ signed -- true | d false )
   \ signed indicates whether to sign-extend on single to double conversion.
   \ The user can override this with a - sign.
   \ Handle preceding signs; accepts -n +n and +-n.
   -rot  0 >r                  ( signed field$  ) ( r: negative )
   over c@ ascii +  = if  1 /string  then
   over c@ ascii -  = if
      1 /string
      r> drop  true >r 
   then                        ( signed field$  ) ( r: negative )

   $asm-execute  if
      dup adt-immed = if  drop  then
      swap n>d
      r> if  dnegate  then
      false exit
   then                       ( signed field$  ) ( r: negative )

   (get-based-number)         ( true | d false )
   r> over 0= and  if
      drop dnegate
      64 dmask 2and
      false
   then
;

: dnimm ( signed? -- d )
   "*"?  if   \ XXX make "**"?  ??
      drop  dval-valid 0= " a double immediate value on the data stack" ?expecting
      dval 2@  true is dval-consumed exit
   then
   "`"?  if  drop execute-inline  over n>d  exit then 
   "``"? if  drop execute-inline            exit then 
   <c  scantodelim  c>   rot    \ pull the signed flag up from the bottom
   get-based-number " a number" ?expecting
;

: #2imm-check ( allow-signed? d #bits -- d )
   >r rot if              ( d )  ( r:  #bits )
      2dup dup sext 0<  if  ( d32mask )   64 dmask 2xor then
      r@  1-
   else
      2dup r@
   then                   ( abs-d  #bits )
   dmask  2andc or if
      abort-try  ." (#2imm-check) Expecting a " r> .d " bit value" ad-error
   then
   r> dmask  2and
;

:  dimm   ( #bits signed? -- d )   swap >r  dup dnimm  r>  #2imm-check  ;
: #duimm  ( #bits -- d )   "##" 0 dimm  ;   \ XXX used once
: #dsimm  ( #bits -- d )   "##" 1 dimm  ;   \ XXX used once

: unimm  ( -- n )
   \ pick up a value from the stack?
   "*"?  if  ival@ exit  then

   \ evaluate an expression in single quotes?
   "`"?  if  execute-inline exit  then
   
   <c  scantodelim  c>   get-based-unumber " a number" ?expecting       ( d )

   \ A single cell value?  If so, exit
   dup 0= if  drop exit  then

   \ No, a signed number where the low order cell doesn't have the sign bit set.
   " at most a single cell number" expecting
;

: snimm ( -- n )
   "*"?  if  ival@ exit  then
   "`"?  if  execute-inline  exit  then
   
   <c  scantodelim  c> 
   true get-based-number " a number" ?expecting       ( d )
   
   \ A single cell value?  If so, exit
   dup 0= if drop exit then
   
   \ A signed number?  If so, is the sign bit of the low cell set?
   \ sext -1 =   if sext dup 0 < if exit then then
   -1 = if  dup 0< if exit then  then
   
   \ No, a signed number where the low order cell doesn't have the sign bit set.
   " at most a single cell number" expecting
;

: i.fimm ( -- i f )
   \ pick up a value from the stack?
   "*"?  if  ival@ exit  then
   \ evaluate an expression in single quotes?
   "`"?  if  execute-inline exit  then
   <c  " . " scanto$  c>   get-based-unumber " a number" ?expecting       ( i )
   unimm ( i f )
;
: #i.fimm ( -- i f )   "##" i.fimm ;

\ count trailing ones
\ eg 5 cto --> 1 , 7 cto -> 3
: cto  ( n -- n )
   bits/cell 0 do
      dup 1 and 0= if  drop i unloop exit  then
      1 rshift
   loop   drop bits/cell
;
: d-cto  ( d -- n )
  swap dup h# ffff.ffff = if drop 32 else swap drop 0 then
  swap cto +
;

\ dhighestsetbit will compute the bit # of the highest set bit in a
\ double.  The possible output values are 0..63 or -1.  The latter
\ indicates that no input bits were set.

\ The basic algorithm is to examine each half of the double and
\ compute the highestsetbit of either the high half (if it's non-zero) or
\ the low order word.  NOTE that there is special logic to handle
\ the -1 case at the top.  That simplifies the end of the routine.

: d-highestsetbit ( d -- n )
   2dup or 0=  if  2drop -1  exit  then
   dup  if  swap drop 32
   else     drop 0
   then     swap  highestsetbit
   ( 32|0  bit# ) + ( NOTE: -1 isn't possible, see test at top )
;

: 2clz  ( d -- n )
   d-highestsetbit 63 swap -
;

\ immed-elemsz is a helper function for immed>{n,immr,imms}.  This
\ function will find the smallest element which exists one or more
\ times within the supplied immediate number (given a datasize)

: immed-elemsz ( d-imm regsize -- element elemsz )
   dup 2 do                  ( d-imm regsize                    R: loop )
      >r 2dup                ( d-imm d-imm                      R: loop regsize )
      r@ -rot                ( d-imm regsize d-imm              R: loop regsize )
      r> i swap i /          ( d-imm regsize d-imm i regsize/i  R: loop )
      d-replicate            ( d-imm regsize d-rotated          R: loop )
      rot >r 2over           ( d-imm d-rotated d-imm            R: loop regsize )
      d- or 0= if            ( d-imm                            R: loop regsize )
         r> drop             ( d-imm                            R: loop )
         i dmask 2and        ( d-imm-masked                     R: loop )
         i unloop exit       ( d-imm-masked elemsz )
      then r>                ( d-imm regsize                    R: loop )
   i +loop                   ( d-imm regsize )
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

: immed-rotate  ( d-elem size -- n immr imms t | f )
   dup 0 do                       ( d-elem size        R: loop )
      >r                          ( d-elem             R: loop size )
      r@ 1 d-rotate               ( d-elem-rotated     R: loop size )
      2dup 2clz                   ( d-elem clz         R: loop size )
      64 r@ - -                   ( d-elem M           R: loop size )
      0 2over                     ( d-elem M 0 d-elem  R: loop size )
      d-cto nip                   ( d-elem M N         R: loop size )
      + r@                        ( d-elem M+N size    R: loop size )
      =  if                       ( d-elem             R: loop size )
         d-cto                    ( N                  R: loop size )
         r@ 6 rshift 1 and       ( N n                R: loop size )
         r@ 1- -1 xor 2*          ( N n imms,p1        R: loop size )
         rot 1- or 63 and        ( n imms             R: loop size )
         r> i 1+ - swap true      ( n immr imms t      R: loop )
         unloop exit              ( n immr imms t )
      then                        ( d-elem             R: loop size )
      r>                          ( d-elem size        R: loop )
   loop                           ( d-elem size )
   3drop false                    ( f )
;

\ immed>{n,immr,imms} - Determine if an immediate value can be encoded
\ as the immediate operand of a logical instruction for the given register
\ size.  If so, return true with "encoding" set to the encoded value in
\ the form {N, immr, imms}.

: immed>{n,immr,imms}  ( dimm regsize -- n immr imms t | f)
   \ 0 cannot be represented with n immr imms,
   \ cast that out early
   -rot 2dup or 0=  if  2drop drop  false  exit  then
   rot
   immed-elemsz    ( elem size )
   immed-rotate    ( n immr imms t | f )
;

