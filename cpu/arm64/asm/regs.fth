\ Assembler register scanning

decimal

\ These words define how an instruction scans text input for registers.

\ pick up values for the registers used by an instance of an instruction
\ check for valid types eg v7.16b
\ check for valid relationships, eg 3 of the same type

\ =======================================
\
\         Register Parsing Words
\
\    reg is defined in parseregs.fth
\
\ =======================================

: rx?sp ( reg# -- 0...31 )
   dup 31 < if  exit  then    \ ?exit is not defined yet
   32 = if  31 exit  then
   " r0..r30,SP" expecting
;

: rx    ( bit# -- adt-code )  reg -rot       swap ^r  ;
: rx|sp ( bit# -- adt-code )  reg -rot rx?sp swap ^r  ;

: r!     ( adt-code  bit# --  adt-code )   rx    =?reg  ;
: r|sp!  ( adt-code  bit# --  adt-code )   rx|sp =?reg  ;

: set-sf    ( -- )     0x8000.0000 iop  ;       \ set the SixtyFour bit
: ^sf  ( n -- )   if  set-sf  then  ;

\ XXX eliminate this
0 value sf      \ bit 31 (S)ixty (F)our  Brilliant!
: >sf  ( adt-type -- )  adt-xreg = 1 and  is sf ;

: rd   ( -- )             0 rx  dup is rd-adt >sf ;
: xd   ( -- )   adt-xreg  0 r!  dup is rd-adt >sf ;
: wd   ( -- )   adt-wreg  0 r!  dup is rd-adt >sf ;

: rd,  rd  "," ;
: xd,  xd  "," ;
: wd,  wd  "," ;

: pd   reg swap 0 4 ^^op dup is rd-adt >sf ;         \ 4bits opcode field for Preg
: pd,  pd  "," ;

: rn   ( -- )             5 rx  is rn-adt ;
: xn   ( -- )   adt-xreg  5 r!  is rn-adt ;
: wn   ( -- )   adt-wreg  5 r!  is rn-adt ;

: dn   ( -- )   adt-dreg  5 r!  is rn-adt  ;

: rn,  rn  "," ;
: xn,  xn  "," ;
: wn,  wn  "," ;

: rm   ( -- )             16 rx  is rm-adt ;
: xm   ( -- )   adt-xreg  16 r!  is rm-adt ;
: wm   ( -- )   adt-wreg  16 r!  is rm-adt ;

alias  rs  rm
alias  ws  wm

: rm,  rm  ","  ;
: wm,  wm  ","  ;

alias  rs,  rm,
alias  ws,  wm,

: ra   ( -- )             10 rx  is ra-adt ;
: xa   ( -- )   adt-xreg  10 r!  is ra-adt ;
: wa   ( -- )   adt-wreg  10 r!  is ra-adt ;

: ra,  ra  ","  ;
: xa,  xa  ","  ;

: rd|rsp ( -- )             0 rx|sp dup is rd-adt >sf  ;
: xd|xsp ( -- )   adt-xreg  0 r|sp! dup is rd-adt >sf  ;
: wd|wsp ( -- )   adt-wreg  0 r|sp! dup is rd-adt >sf  ;
: rn|rsp ( -- )             5 rx|sp     is rn-adt      ;
: xn|xsp ( -- )   adt-xreg  5 r|sp!     is rn-adt      ;
: rm|rsp ( -- )            16 rx|sp     is rm-adt      ;

: xd|xsp,  xd|xsp  ","  ;

: ?wx  ( adt-type -- )
   ( adt-type )  case
      adt-wreg  of  0 is sf  endof
      adt-xreg  of  1 is sf  endof
      " a W or X register" expecting
   endcase
;

: wxd ( -- )   rd rd-adt  ?wx  ;
: wxn ( -- )   rn              ;
: wxm ( -- )   rm              ;

: wxd,  wxd  ","  ;
: wxn,  wxn  ","  ;
: wxm,  wxm  ","  ;

: wxd|sp ( -- )   rd|rsp rd-adt ?wx ;
: wxn|sp ( -- )   rn|rsp            ;

: wxd|sp,  wxd|sp  ","  ;
: wxn|sp,  wxn|sp  ","  ;

: ?Rm=X  ( -- )   rm-adt  adt-xreg  <>  " register Rm is an Xn" ?expecting  ;
: ?Rm=W  ( -- )   rm-adt  adt-wreg  <>  " register Rm is an Wn" ?expecting  ;

: Xd?    ( -- f )   rd-adt  adt-xreg  =  ;
: Wd?    ( -- f )   rd-adt  adt-wreg  =  ;
: XWd?   ( -- f )   Xd?  Wd?  or  ;
: Xn?    ( -- f )   rn-adt  adt-xreg  =  ;
: Wn?    ( -- f )   rn-adt  adt-wreg  =  ;
: XWn?   ( -- f )   Xn?  Wn?  or  ;
: Xa?    ( -- f )   ra-adt  adt-xreg  =  ;
: Wa?    ( -- f )   ra-adt  adt-wreg  =  ;
: XWa?   ( -- f )   Xa?  Wd?  or  ;
: Xm?    ( -- f )   rm-adt  adt-xreg  =  ;

alias XWt?   XWd?
alias XWt2?  XWa?

: Dd?    ( -- f )   rd-adt  adt-dreg  =  ;
: Sd?    ( -- f )   rd-adt  adt-sreg  =  ;
: DSd?   ( -- f )   Dd?  Sd?  or  ;
: Dn?    ( -- f )   rn-adt  adt-dreg  =  ;
: Sn?    ( -- f )   rn-adt  adt-sreg  =  ;
: DSn?   ( -- f )   Dn?  Sn?  or  ;

: set-sf?   ( -- )     xd? if  set-sf  then  ;


\ many instructions have different sizes for each register
\ regs will be all scalar or all vector (elements are handled elsewhere) 
\ instructions that take three arguments are usually one of these types:
\ same       8b = 8b + 8b   ( three the same ) d=n=m
\ narrow     8b = 8h + 8h   ( smaller result ) d<n=m
\ long       8h = 8b + 8b   ( larger result )  d>n=m
\ wide       8h = 8h + 8b   ( mixed inputs )   d=n>m

\ register matches
\ tests
: rd=rn?   ( -- ? )         rd-adt rn-adt =  ;
: rd=rm?   ( -- ? )         rd-adt rm-adt =  ;
: rd=ra?   ( -- ? )         rd-adt ra-adt =  ;
: rn=rm?   ( -- ? )         rn-adt rm-adt =  ;

\ asserts
: ?rd=rn  ( -- )   rd-adt rn-adt <> " Rd and Rn " ?same-reg-type  ;
: ?rd=rm  ( -- )   rd-adt rm-adt <> " Rd and Rm " ?same-reg-type  ;
: ?rd=ra  ( -- )   rd-adt ra-adt <> " Rd and Ra " ?same-reg-type  ;
: ?rn=rm  ( -- )   rn-adt rm-adt <> " Rn and Rm " ?same-reg-type  ;
: ?rd=rn=rm  ( -- )
   rd-adt  rn-adt  <>
   rd-adt  rm-adt  <>  or
   " Rd, Rn, and Rm" ?same-reg-type
;
: ?rd=rn=rm=ra  ( -- )
   rd-adt  rn-adt  <>
   rd-adt  rm-adt  <>  or
   rd-adt  ra-adt  <>  or
   " Rd, Rn, Rm, and Ra" ?same-reg-type
;
: ?rt=rt2  ( -- )   rd=ra? 0= " Rt and Rt2" ?same-reg-type  ;

\ some instructions have some registers one size larger than the rest
\ vector types each have two sizes, eg .2s .4s so the mask shifts two bits
\ : raise-reg   ( reg-mask -- reg-mask' )   dup m.v.bhsd and if  4*  else  2*  then  ;

\ tests
: rd<rn?   ( -- narrow? )   rd-mask raise-reg rn-mask =  ;
: rd>rn?   ( -- long? )     rn-mask raise-reg rd-mask =  ;
: rn<rm?   ( -- ? )         rn-mask raise-reg rm-mask =  ;
: rn>rm?   ( -- wide? )     rm-mask raise-reg rn-mask =  ;
: rm>ra?   ( -- ? )         ra-mask raise-reg rm-mask =  ;

\ asserts
: ?rd<rn  ( -- )   rd<rn? 0= " Rd<Rn " ?expecting  ;
: ?rd>rn  ( -- )   rd>rn? 0= " Rd>Rn " ?expecting  ;
: ?rd<rn=rm   ( -- )   rd<rn? rn=rm? and 0= " Rd<Rn=Rm " ?expecting  ;
: ?rd>rn=rm   ( -- )   rd>rn? rn=rm? and 0= " Rd>Rn=Rm " ?expecting  ;
: ?rd=rn>rm   ( -- )   rd=rn? rn>rm? and 0= " Rd=Rn>Rm " ?expecting  ;
: ?rd=rn<rm   ( -- )   rd=rn? rn<rm? and 0= " Rd=Rn<Rm " ?expecting  ;
\ and just for madd etc
: ?rd=ra>rn=rm  ( -- )   rd>rn? rn=rm? and rd=ra? and 0= " Rd>Rn=Rm<Ra " ?expecting  ;


\ The following words parse a set of registers from the input stream
\ and enforce a specific register mix.
\ Each instruction takes a fixed pattern of registers.
\ For example they may all have to be of the same type.

\ each of these words parses the input stream for registers,
\ then asserts a relationship between them
: d=n     ( -- )   rd, rn           ?rd=rn  ;
: d=m     ( -- )   rd, rm           ?rd=rm  ;
: d=a     ( -- )   rd, ra           ?rd=ra  ;
: d<n     ( -- )   rd, rn           ?rd<rn  ;
: d>n     ( -- )   rd, rn           ?rd>rn  ;
: d=n=m   ( -- )   rd, rn, rm       ?rd=rn=rm  ;   \ same
: d<n=m   ( -- )   rd, rn, rm       ?rd<rn=rm  ;   \ narrow
: d>n=m   ( -- )   rd, rn, rm       ?rd>rn=rm  ;   \ long
: d=n>m   ( -- )   rd, rn, rm       ?rd=rn>rm  ;   \ wide
: d=n<m   ( -- )   rd, rn, rm       ?rd=rn<rm  ;   \ (some crcs)
: d=n=m=a ( -- )   rd, rn, rm, ra   ?rd=rn=rm=ra  ;
: d=a>n=m ( -- )   rd, rn, rm, ra   ?rd=ra>rn=rm  ;

: m=d     ( -- )   rm, rd           ?rd=rm  ;
: n=m     ( -- )   rn, rm           ?rn=rm  ;

: d=n,    ( -- )   d=n    ","  ;
: d=a,    ( -- )   d=a    ","  ;
: d=n=m,  ( -- )   d=n=m  ","  ;
: m=d,    ( -- )   m=d    ","  ;
: n=m,    ( -- )   n=m    ","  ;

\ FIXME find a way to fit immediates into this scheme !
\ #? is a start...


\ each of these words tests a particular register against a bitmap of allowed types
\ most instructions test rd, the others are rarely needed.
: rd?   ( allowed -- match? )   rd-mask adt?  ;
: rn?   ( allowed -- match? )   rn-mask adt?  ;
: rm?   ( allowed -- match? )   rm-mask adt?  ;



\ XXX  relics. deprecate
: rn#=sp?   ( -- f )  <rn>  31  =   ;
: rn#=XWd#?   ( -- f )  XWd?   <rn>  <rd>  =   and  ;
: rn#=XWt#?   ( -- f )  XWt?   <rn>  <rt>  =   and  ;
: rn#=XWt2#?  ( -- f )  XWt2?  <rn>  <rt2> =   and  ;
: [wxzd]  ( -- )  31 ^rd  rn-adt  dup is rd-adt  >sf  ;
: [wxzn]  ( -- )  31 ^rn  rd-adt      is rn-adt       ;





\
\ Show allowed register names on error
\
string: err$
: #ones   ( n -- #ones )
   0  d# 28 0 do   ( n #ones )
      over 1 i << and if  1+  then
   loop   nip
;
: addreg,   ( ones $ -- ones' )
   rot
   dup 2 > if
      -rot
      err$ $add  " , " err$ $add
      1-  exit
   then   ( $ ones )
   dup 2 = if
      drop
      err$ $add  "  or " err$ $add  
      1  exit
   then   ( $ ones )
   dup 1 = if
      drop
      err$ $add
      0  exit
   then   ( $ ones )
   3drop 0
;
: mask>str   ( mask reg$-- $ )
   err$ place
   >r
   r@ #ones   
   r@ m.x     adt? if   " X"       addreg,  then
   r@ m.w     adt? if   " W"       addreg,  then
   r@ m.b     adt? if   " B"       addreg,  then
   r@ m.h     adt? if   " H"       addreg,  then
   r@ m.s     adt? if   " S"       addreg,  then
   r@ m.d     adt? if   " D"       addreg,  then
   r@ m.q     adt? if   " Q"       addreg,  then
   r@ m.v.8b  adt? if   " V.8b"    addreg,  then
   r@ m.v.16b adt? if   " V.16b"   addreg,  then
   r@ m.v.4h  adt? if   " V.4h"    addreg,  then
   r@ m.v.8h  adt? if   " V.8h"    addreg,  then
   r@ m.v.2s  adt? if   " V.2s"    addreg,  then
   r@ m.v.4s  adt? if   " V.4s"    addreg,  then
   r@ m.v.1d  adt? if   " V.1d"    addreg,  then
   r@ m.v.2d  adt? if   " V.2d"    addreg,  then
   r@ m.v.bhs adt? if   " V[elem]" addreg,  then
   r@ m.z.b   adt? if   " Z.b"     addreg,  then
   r@ m.z.h   adt? if   " Z.h"     addreg,  then
   r@ m.z.s   adt? if   " Z.s"     addreg,  then
   r@ m.z.d   adt? if   " Z.d"     addreg,  then
   r@ m.z.b   adt? if   " P.b"     addreg,  then
   r@ m.z.h   adt? if   " P.h"     addreg,  then
   r@ m.z.s   adt? if   " P.s"     addreg,  then
   r@ m.z.d   adt? if   " P.d"     addreg,  then
   r> 2drop
   err$ count
;
\ check that Rd is a valid type
\ if not, list the allowed types
: rd??   ( mask -- )   dup rd? 0= if
      " Rd is " mask>str expecting
   else  drop  then
;
: rn??   ( mask -- )   dup rn? 0= if
      " Rn is " mask>str expecting
   else  drop  then
;
: rm??   ( mask -- )   dup rm? 0= if
      " Rm is " mask>str expecting
   else  drop  then
;

: rd??iop   ( op regs -- )   rd??   iop  ;
: rn??iop   ( op regs -- )   rn??   iop  ;


\ common behaviors: pick up some registers, confirm their relative types, and
\ check that the type of Rd is in the regs mask, then OR the op into opcode.

: 2same   ( op regs -- )   d=n      rd??iop  ,? ?invalid-regs  ;
: 3same   ( op regs -- )   d=n=m    rd??iop  ;
: 4same   ( op regs -- )   d=n=m=a  rd??iop  ;

: 2long   ( op regs -- )   d>n      rd??iop  ;
: 3long   ( op regs -- )   d>n=m    rd??iop  ;

: 2narrow ( op regs -- )   d<n      rd??iop  ;
: 3narrow ( op regs -- )   d<n=m    rd??iop  ;

: 3wide   ( op regs -- )   d=n>m    rd??iop  ;
: 3crc    ( op regs -- )   d=n<m    rd??iop  ;

