\ parse reg names
\ modified to work with adt2.fth

\ NOTE this replaces regnames.fth
\ which defines words for each possible register and vector type

\ if parse fails, search dict of aliases  created by regalias
\ including XZR SSP LR WZR WLR WSP 
\ so parse is reduced to (where vt is vector type)
\ Xn
\ Wn
\ Bn
\ Sn
\ Hn
\ Dn Dn.vt 
\ Qn Qn.vt
\ Vn.vt
\ Zn.vt
\ Pn
\ Pn.vt
\ Pn/M
\ Pn/Z

\ so 10 valid letters, always a number,
\ sometimes .vt or /c
\ returns t | n, adt, 0

vocabulary regnames
: regalias   \ newname oldname
   get-current >r  also regnames definitions
   create  ( -- )   safe-parse-word ",
   previous  r> set-current
   does>  count  ( -- $ )
;

also regnames definitions
regalias lr     x30
regalias xzr    x31
regalias xsp    x32
regalias ssp    x32
regalias xpc    x33

regalias wlr    w30
regalias wzr    w31
regalias wsp    w32
regalias wssp   w32
previous definitions

: firstchar   ( $ -- $' c )
   dup 0= if  0 exit  then
   over c@ >r  1 /string  r>
;
: char>mask   ( c -- 0 true | adt false )
   upc false swap
   case
      ascii # of   m.imm  endof
      ascii X of   m.x    endof
      ascii W of   m.w    endof
      ascii B of   m.b    endof
      ascii H of   m.h    endof
      ascii S of   m.s    endof
      ascii D of   m.d    endof
      ascii Q of   m.q    endof
      ascii V of   m.v    endof
      ascii Z of   m.z    endof
      ascii P of   m.p    endof
      ascii R of   m.x    endof
      ( default )   true swap
   endcase
   swap
;

: $reg#   ( $ -- true | $' n false )
   \ is next char a digit?
   firstchar d# 10 digit 0= if  3drop true exit  then   ( $ d1 )
   \ end of string?
   over 0= if  false exit   then   ( $ n )
   \ is there another digit?
   >r over c@ d# 10 digit 0= if   drop r> false exit  then  ( $ d2 )
   >r 1 /string r>
   r> d# 10 * + false
;
: v/z   ( m.a m.vx m.zx -- m.x m.a )   2 pick dup >r  m.z = if   swap  then  drop  r>  ;
\ m.regs shows allowed reg type for each vector type

: $vt.#c   ( adt $ -- adt true | adt' false )
   false >r
   2dup upper $case
   " .B"   $of  m.v.b    $endof
   " .H"   $of  m.v.h    $endof
   " .S"   $of  m.v.s    $endof
   " .D"   $of  m.v.d    $endof
   " .Q"   $of  m.v.q    $endof
   " .16B" $of  m.v.16b  $endof
   " .8B"  $of  m.v.8b   $endof
   " .4B"  $of  m.v.4b   $endof
   " .8H"  $of  m.v.8h   $endof
   " .4H"  $of  m.v.4h   $endof
   " .2H"  $of  m.v.2h   $endof
   " .4S"  $of  m.v.4s   $endof
   " .2S"  $of  m.v.2s   $endof
   " .2D"  $of  m.v.2d   $endof
   " .1D"  $of  m.v.1d   $endof
   " .1Q"  $of  m.v.1q   $endof
   ( default )  r> drop true >r
   $endcase
   r> if   true  else  nip false  then
;
: $vt.c   ( adt $ -- adt true | adt' false )
   false >r
   2dup upper
   $case
   " .B"   $of   1 or       $endof
   " .H"   $of   2 or       $endof
   " .S"   $of   4 or       $endof
   " .D"   $of   8 or       $endof
   " .Q"   $of  16 or       $endof
   " /M"   $of  0x4000 or   $endof
   " /Z"   $of  0x8000 or   $endof
   ( default )  r> drop true >r
   $endcase
   r> 
;
: $vt   ( adt $ -- true | adt' false )   \ vector type eg m.16b
   dup 0= if  3drop true exit  then
   2 pick case
      m.d of   $vt.#c   endof
      m.q of   $vt.#c   endof
      m.v of   $vt.#c   endof
      m.p of   $vt.c    endof
      m.z of   $vt.c    endof
      ( default )   dup true 
   endcase
   if  drop true  else  mask>adt false  then
;

: za-vt   ( $ -- true | m.zah m.zav m.za false )   \ vector type eg m.zavq
   dup 0= if  2drop true exit  then
   false >r
   2dup upper
   $case
   " .B"   $of  m.zav.b  m.zah.b  m.za.b   $endof
   " .H"   $of  m.zav.h  m.zah.h  m.za.h   $endof
   " .S"   $of  m.zav.s  m.zah.s  m.za.s   $endof
   " .D"   $of  m.zav.d  m.zah.d  m.za.d   $endof
   " .Q"   $of  m.zav.q  m.zah.q  m.za.q   $endof
   ( default )  r> drop true >r
   $endcase
   r> 
;
: h/v?   ( c -- n )
   upc dup
   ascii H = if  drop  1 exit  then
   ascii V = if        2 exit  then
   0
;
: ZA-parse   ( $ -- true | n adt false )
   1 /string  dup 0= if  2drop 0 m.za false exit  then  ( n $ )
   $reg# if  true exit   then  ( $ n )
   \ end of string?
   -rot dup 0= if  2drop m.za false exit  then  ( n $ )
   \ look for H or V
   over c@ h/v? dup if  >r  1 /string  r>   then   ( n $ hv )
   >r  za-vt if   r> 4drop true exit  then   ( hv m.zav m.zah m.za )
   r> dup if
      1 = if  rot  then
   else  drop -rot
   then   2drop mask>adt false
;

: (reg)   ( $ -- true | n adt false )
   \ first character gives adt
   firstchar char>mask if   3drop true exit   then  ( $ adt )
   >r
   r@ m.z = if   over c@ upc ascii A = if
	 r> drop ZA-parse exit  then
   then                                             ( $ )
   \ get 1 or 2 digit reg number
   $reg# if   r> drop true exit   then  ( $ n )
   r>  2swap  ( n adt $ )
   dup 0= if   2drop mask>adt false exit  then   ( n adt $ )
   \ $ has vector type
   $vt dup if   3drop true   then
;

: $reg   ( $ -- n adt )
   2>r 2r@ (reg) 0= if  2r> 2drop exit  then
   \ parsing failed, look it up
   2r> ['] regnames $vfind   ( $ false | xt +-1 )   
   0= if  " Unknown symbol: "  ad-error  then   ( xt )
   execute (reg) if  " Unknown register: "  ad-error  then
;

: reg   ( -- n adt )   <c  scantodelim  c>   ( $ )   $reg  ;
