\ support for mov and movi

\ support for encoding 64bit immediate into abcdefgh byte mask construct
\ Example:
\ movi    v0.8b, #0xff00
\ movi    v1.8b, #0xff00ff00.ffffffff
\ movi    v2.16b, #0xffff00
\ movi    v3.16b, #0xff00ff00.00ffffff
\
\ But Will currently disassemble like this:
\ ( function over form at this time )
\ movi    d0, #0x02,    \ #0x000000000000ff00
\ movi    d1, #0xaf,    \ #0xff00ff00ffffffff
\ movi    v2.2d, #0x06, \ #0x0000000000ffff00
\ movi    v3.2d, #0xa7, \ #0xff00ff0000ffffff

: movi-abcdefgh? ( val -- 0 | imm true )
    0 ( val imm )
    8 0                             \ whip thru 8 bytes
    do      
        over i 8 * >> 0xff and
        dup
        ( val imm byte byte )
        dup 0 = swap 0xff = or
        ( val imm byte 00|ff )
        IF                         \ 00 or FF is only valid values
            1 and i << or         \ merge bit into mask
            ( val imm )
        ELSE
            ( val imm byte )
            3drop false unloop exit
        THEN
    loop
    ( val imm )
    nip true
    ( imm true )
    ;
               
: ^^movi-imm ( imm )
    dup                         \ encode imm into opcode
    0x1f and 5 <<              \ defgh 
    swap
    5 >> 7 and d# 16 << or     \ abc
    iop                         \ insert
    ;

: (lsl)   ( maxshift -- )
   #uimm6   ( maxshift imm )
   tuck <  " smaller shift " ?expecting   ( imm )
   case
      0  of  0  endof
      8  of  1  endof
      16 of  2  endof
      24 of  3  endof
      " multiple of 8 " expecting
   endcase
   13 << iop
;
: (msl)   ( -- )
   #uimm6   ( maxshift imm )
   dup case
      8  of  0  endof
      16 of  1  endof
      " 8 or 16 " expecting
   endcase
   13 << iop
;
: ?lsl   ( n -- )
   ","?  if                   \ we have a comma
      " lsl" $match? if  dup (lsl)  else  2drop  then
   then  drop
;
: ?lsl/msl   ( -- )
   ","?  if                   \ we have a comma
      " lsl" $match? if  24 (lsl)  else  2drop  then
      " msl" $match? if     (msl)  else  2drop  then
   then
;
: movi8    ( op -- )   iop  #modimm8   0 ?lsl  ;
: movi16   ( op -- )   iop  #modimm8   8 ?lsl  ;
\ : (movi32)   ( op -- )   iop  #modimm8   ?lsl/msl  ;

\ -----------------------------------------------------
\ hack to implement/disambiguate fimm construct.
\ if immediate is prefixed with f# instead of just #
\ assume a fimm (FMOV Imm) construct
\ the imm8 is a raw hex value that will be encoded
\ into a range for 64 or 32bit floats
\ according to the AdvSIMDExpandImm() FMOV nitemare
\ -----------------------------------------------------

: (movi-imm)   ( -- )
   "##" unimm dup h# ff u> if    \ treat as a 64-bit value
      movi-abcdefgh? 0= " invalid 64-bit immediate " ?error
   THEN    ( imm )
   ^^movi-imm                 \ insert
;
: "f#"?   ( -- match? ) " f#" $match? ;
: f#movi-imm   ( -- )
   "f#"? 0= if  2drop (movi-imm) exit  then
   rd-adt
   case
      adt-dreg.2s  OF  0x0000.f000 iop  ENDOF 
      adt-qreg.4s  OF  0x4000.f000 iop  ENDOF 
      adt-qreg.2d  OF  0x6000.f000 iop  ENDOF
      cr ." f#movi-imm: error Unsupported adt " dup . 
   endcase 
   8 #uimm ^^movi-imm
;
: movi-imm   ( op -- )   iop  f#movi-imm  ;
: movi32   ( op -- )
   "f#"? if   \ hack hack hack   turn it into an fmov
      drop  
      rd-adt
      case
	 adt-dreg.2s  OF  0x0F00.F400 iop  ENDOF 
	 adt-qreg.4s  OF  0x4F00.F400 iop  ENDOF 
	 cr ." movi32: error unsupported adt " dup . 
      endcase
      #modimm8
   else
      2drop
      iop  #modimm8   ?lsl/msl
   then
;


\ =======================================
\
\    MOVK  MOVN  MOVZ
\
\ =======================================

: mov-nzk-err  ( $ -- ) ." MOVK MOVN MOVZ shifts must be " ( $ ) ad-error ;

: ^mov-nzk  ( opc  imm  shift -- )
   0x12800000 iop   set-sf?
   ( shift ) dup 15 and if " multiples of 16" mov-nzk-err then
   ( shift ) 4 rshift dup
   xd? if
      3 andc if " 0, 16, 32, or 48" mov-nzk-err then
   else
      1 andc if " 0 or 16" mov-nzk-err then
   then
   ( shift ) 21 2 ^^op
   ( imm )   5 16 ^^op
   ( opc ) dup 3 andc
   over 1 =  or  " a shift type of 0, 2, or 3 only" ?expecting
   ( opc )   29 2 ^^op
;

: mov-nzk-imm  ( -- imm16  shift )
   #uimm16  ","?  0=  if  0  exit  then
   " lsl" $match?  0=  if  " #N, LSL" expecting  then
   #uimm6
;



\ =======================================
\
\    MOVE ALIASES
\
\ =======================================

\
\ ARM64 does not supply a MOV instruction, per se.  However,
\ the user is allowed to use MOV and it will transparently
\ map to one of a collection of instructions:
\    MOV:  alias to MOVN
\    MOV:  alias to MOVZ
\    MOV:  alias to ADD (immediate)
\    MOV:  alias to ORR (immediate)
\    MOV:  alias to ORR (shifted reg)
\    MVN:  alias to ORN (shifted reg)

\ : movs-reg  wxd, [wxzn] wxm  1 h# 3f h# 3e  (log-imm)  ;

