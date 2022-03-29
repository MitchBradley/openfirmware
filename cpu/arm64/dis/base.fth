purpose: ARM64 disassembler - prefix syntax
\ base instruction set
\ See license at end of file



\ =======================================
\
\          INSTRUCTION HANDLERS
\
\ =======================================

\ XXX line 533 of original

: ldst-unimpl unimpl ."  ld/st" ;

: .add  ( -- )  29 2bits " add addssub subs" 4 .txt  op-col  ;
: .adc  ( -- )  29 2bits " adc adcssbc sbcs" 4 .txt  op-col  ;

: .shifted-reg  ( -- )
   10 6bits 22 2bits    ( shift-count shift-type )
   2dup or if           \ Don't print "lsl #0"
      ., " lsllsrasrror" 3 .txt space .imm
   else
      2drop
   then
;
: log-reg  ( -- )
   sf!  29 2bits 1 <<  21 1bit  or
   " and bic orr orn eor eon andsbics" 4 .txt  op-col
   .rd, .rn, .rm   .shifted-reg
;
: add-reg  ( -- )  sf!  .add   .rd, .rn, .rm   .shifted-reg  ;

: .extended  ( -- )
   29 1bit if  0  else  rd XSP =  then
   rn XSP =  or 
   13 3bits sf@ if 3 else 2 then
   = and if
      \ The ARM documents want "LSL #" instead of UXTX in this case
      \ but on no account do we print "LSL #0". Sheesh.
      10 3bits ?dup  if  ., ." lsl" space .imm  then
   else
      \ In all other cases we print zero shift counts. Consistency!
      ., 13 3 " uxtbuxthuxtwuxtxsxtbsxthsxtwsxtx" 4 .fld
      10 3bits space .imm
   then
;
: add-ext-reg  ( -- )
   22 2bits 0<> if  unimpl  exit  then
   sf!  .add  29 1bit if .rd, else .rd|sp, then .rn|sp, .rm .extended
;

: add-carry  ( -- )
   10 6bits 0<> if unimpl exit then
   sf!  .adc    .rd, .rn, .rm
;

: add-imm  ( -- )
   23 1bit 0<> if unimpl exit then
   sf!  .add  29 1bit if .rd, else .rd|sp, then .rn|sp, 10 12 bits .imm ?.Start-Codetag
   22 1bit if ., ." lsl " 12 .imm  then
;

: log-imm  ( -- )
   sf! sf@ 1 xor 22 1bit land if unimpl exit then  \ If sf is 0, then N must be 0
   29 2bits " and orr eor ands" 4 .txt  op-col
   29 2bits 3 xor if .rd|sp, else .rd, then .rn, 
   sf@ if 64 else 32 then
   22 1bit  immr  imms
   {n,immr,imms}>immed 2dup
   .# push-decimal dis-ud. pop-base
   rem-col push-hex ." h# " dis-ud. pop-base
;

: .bfm-operands  ( -- )  op-col .rd, .rn, immr .imm, imms .imm ;
: .bfc-operands  ( -- )  op-col .rd,  d# 64 immr - .imm, imms 1+ .imm ;

\ Fix these words to interpret the various operands and emit
\ specialized instruction forms like LSL, ASR, etc.

: bfc  ( -- )  ." bfc"  .bfc-operands  ;
: bfm  ( -- )  ." bfm"  .bfm-operands  ;
: sbfm ( -- )  ." sbfm" .bfm-operands  ;
: ubfm ( -- )  ." ubfm" .bfm-operands  ;

: bitfield ( -- )
   sf!  sf@ 22 1bit <> if unimpl exit then
   sf@ 0= if 21 1bit 15 1bit or if unimpl exit then then
   29 2bits case
      0  of  sbfm  endof
      1  of
	 rn d# 31 = if  bfc  else  bfm  then
      endof
      2  of  ubfm  endof
      unimpl drop exit
   endcase
;

: extract ( -- )
   sf! sf@ 22 1bit <> if unimpl exit then
   21 1bit if unimpl exit then
   29 2bits if unimpl exit then
   rn rm = if
      ." ror" op-col .rd, .rn, imms .imm
   else
      ." extr" op-col .rd, .rn, .rm, imms .imm
   then
;

\ Bring in an auto-generated function

fload ${BP}/cpu/arm64/msr-decode.fth

: special-reg-decode ( -- $ )
   5 16bits  reg-encoding-to-$name
;
: cpsr-field-decode ( -- $ )
   op1 4 << op2 or  case
      h# 05 of  " SPSet"    endof
      h# 36 of  " DAIFSet"  endof
      h# 37 of  " DAIFClr"  endof
      " RESERVED" 
      ( inval str len )
      rot   \ endcase still needs to pop the original compare value.
            \ without a rot, endcase pops the strlen of "reserved".
            \ we end up calling type with bogus string len
   endcase
;


: (.mrs#-op) 
    push-decimal
    instruction@ >r
    r@ d# 19 >> 1 and 2+ (.) type emit,                \ op0
    r@ d# 16 >> 7 and    (.) type emit,                \ op1
    [char] C emit r@ d# 12 >> 0xf and (.) type emit,   \ CRn
    [char] C emit r@ d# 8 >> 0xf  and (.) type emit,   \ CRm
    r> d# 5 >> 7 and (.) type                          \ op2
    pop-base
    ;


: .mrs#-op ." mrs# " instruction@ 0x1f and [char] x emit push-decimal (.) type ., (.mrs#-op) pop-base  ;
: .msr#-op ." msr# " (.mrs#-op) ., instruction@ 0x1f and [char] x emit push-decimal (.) type pop-base  ;


: mrs  ." mrs " op-col .xd, special-reg-decode type   rem-col .mrs#-op ;
: msr  ." msr " op-col special-reg-decode type ., .xd rem-col .msr#-op ;
: msr-cpsr  ." msr " op-col cpsr-field-decode type ., crm .imm ;

: sys-match ( op1 crn crm op2 -- t|f )
   op2 <>  if  3drop false exit  then
   crm <>  if  2drop false exit  then
   crn <>  if   drop false exit  then
   op1 <>  if        false exit  then
   true
;

: .sys ( op$ instr$ op1 crn crm op2 -- matched? )
   sys-match  if
      type op-col type ., .xt true
   else
      2drop 2drop false
   then
;

: sys ( -- )
   " IALLUIS"      " ic"   0 7  1 0  .sys ?exit
   " IALLU"        " ic"   0 7  5 0  .sys ?exit
   " IVAU"         " ic"   3 7  5 1  .sys ?exit

   " ZVA"          " dc"   3 7  4 1  .sys ?exit
   " IVAC"         " dc"   0 7  6 1  .sys ?exit
   " ISW"          " dc"   0 7  6 2  .sys ?exit
   " CVAC"         " dc"   3 7 10 1  .sys ?exit
   " CSW"          " dc"   0 7 10 2  .sys ?exit
   " CVAU"         " dc"   3 7 11 1  .sys ?exit
   " CIVAC"        " dc"   3 7 14 1  .sys ?exit
   " CISW"         " dc"   0 7 14 2  .sys ?exit

   " S1E1R"        " at"   0 7  8 0  .sys ?exit
   " S1E2R"        " at"   4 7  8 0  .sys ?exit
   " S1E3R"        " at"   6 7  8 0  .sys ?exit
   " S1E1W"        " at"   0 7  8 1  .sys ?exit
   " S1E2W"        " at"   4 7  8 1  .sys ?exit
   " S1E3W"        " at"   6 7  8 1  .sys ?exit
   " S1E0R"        " at"   0 7  8 2  .sys ?exit
   " S1E0W"        " at"   0 7  8 3  .sys ?exit
   " S12E1R"       " at"   4 7  8 4  .sys ?exit
   " S12E1W"       " at"   4 7  8 5  .sys ?exit
   " S12E0R"       " at"   4 7  8 6  .sys ?exit
   " S12E0W"       " at"   4 7  8 7  .sys ?exit

   " IPAS2E1IS"    " tlbi" 4 8  0 1  .sys ?exit
   " IPAS2LE1IS"   " tlbi" 4 8  0 5  .sys ?exit
   " VMALLE1IS"    " tlbi" 0 8  3 0  .sys ?exit
   " VMALLE1OS"    " tlbi" 0 8  1 0  .sys ?exit
   " ALLE2IS"      " tlbi" 4 8  3 0  .sys ?exit
   " ALLE3IS"      " tlbi" 6 8  3 0  .sys ?exit
   " VAE1IS"       " tlbi" 0 8  3 1  .sys ?exit
   " VAE1OS"       " tlbi" 0 8  1 1  .sys ?exit
   " VAE2IS"       " tlbi" 4 8  3 1  .sys ?exit
   " VAE3IS"       " tlbi" 6 8  3 1  .sys ?exit
   " ASIDE1IS"     " tlbi" 0 8  3 2  .sys ?exit
   " ASIDE1OS"     " tlbi" 0 8  1 2  .sys ?exit
   " VAAE1IS"      " tlbi" 0 8  3 3  .sys ?exit
   " VAAE1OS"      " tlbi" 0 8  1 7  .sys ?exit
   " ALLE1IS"      " tlbi" 4 8  3 4  .sys ?exit
   " ALLE1OS"      " tlbi" 4 8  1 4  .sys ?exit
   " VALE1IS"      " tlbi" 0 8  3 5  .sys ?exit
   " VALE1OS"      " tlbi" 0 8  1 5  .sys ?exit
   " VAALE1IS"     " tlbi" 0 8  3 7  .sys ?exit
   " VAALE1OS"     " tlbi" 0 8  1 7  .sys ?exit
   " VMALLE1"      " tlbi" 0 8  7 0  .sys ?exit
   " ALLE2"        " tlbi" 4 8  7 0  .sys ?exit
   " VALE2IS"      " tlbi" 4 8  3 5  .sys ?exit
   " VALE3IS"      " tlbi" 6 8  3 5  .sys ?exit
   " VMALLS12E1OS" " tlbi" 4 8  1 6  .sys ?exit
   " VMALLS12E1IS" " tlbi" 4 8  3 6  .sys ?exit
   " ALLE3"        " tlbi" 6 8  7 0  .sys ?exit
   " IPAS2E1"      " tlbi" 4 8  4 1  .sys ?exit
   " IPAS2LE1"     " tlbi" 4 8  4 5  .sys ?exit
   " VAE1"         " tlbi" 0 8  7 1  .sys ?exit
   " VAE2"         " tlbi" 4 8  7 1  .sys ?exit
   " VAE3"         " tlbi" 6 8  7 1  .sys ?exit
   " ASIDE1"       " tlbi" 0 8  7 2  .sys ?exit
   " VAAE1"        " tlbi" 0 8  7 3  .sys ?exit
   " ALLE1"        " tlbi" 4 8  7 4  .sys ?exit
   " VALE1"        " tlbi" 0 8  7 5  .sys ?exit
   " VALE2"        " tlbi" 4 8  7 5  .sys ?exit
   " VALE3"        " tlbi" 6 8  7 5  .sys ?exit
   " VMALLS12E1"   " tlbi" 4 8  7 6  .sys ?exit
   " VAALE1"       " tlbi" 0 8  7 7  .sys ?exit
   " RVAALE1IS"    " tlbi" 0 8  2 7  .sys ?exit
   " RVALE1IS"     " tlbi" 0 8  2 5  .sys ?exit
   " RVAAE1IS"     " tlbi" 0 8  2 3  .sys ?exit
   " RVAE1IS"      " tlbi" 0 8  2 1  .sys ?exit
   " RVAALE1"      " tlbi" 0 8  6 7  .sys ?exit
   " RVALE1"       " tlbi" 0 8  6 5  .sys ?exit
   " RVAAE1"       " tlbi" 0 8  6 3  .sys ?exit
   " RVAE1"        " tlbi" 0 8  6 1  .sys ?exit
   " RIPAS2LE1IS"  " tlbi" 4 8  0 6  .sys ?exit
   " RIPAS2E1IS"   " tlbi" 4 8  0 2  .sys ?exit
   " RVAALE1OS"    " tlbi" 0 8  5 7  .sys ?exit
   " RVALE1OS"     " tlbi" 0 8  5 5  .sys ?exit
   " RVAAE1OS"     " tlbi" 0 8  5 3  .sys ?exit
   " RVAE1OS"      " tlbi" 0 8  5 1  .sys ?exit
   " RIPAS2LE1OS"  " tlbi" 4 8  4 7  .sys ?exit
   " RIPAS2E1OS"   " tlbi" 4 8  4 3  .sys ?exit
   " RIPAS2LE1"    " tlbi" 4 8  4 6  .sys ?exit
   " RIPAS2E1"     " tlbi" 4 8  4 2  .sys ?exit
   " RVALE2IS"     " tlbi" 4 8  2 5  .sys ?exit
   " RVAE2IS"      " tlbi" 4 8  2 1  .sys ?exit
   " RVALE2"       " tlbi" 4 8  6 5  .sys ?exit
   " RVAE2"        " tlbi" 4 8  6 1  .sys ?exit
   " RVALE2OS"     " tlbi" 4 8  5 5  .sys ?exit
   " RVAE2OS"      " tlbi" 4 8  5 1  .sys ?exit
   " RVALE3IS"     " tlbi" 6 8  2 5  .sys ?exit
   " RVAE3IS"      " tlbi" 6 8  2 1  .sys ?exit
   " RVALE3"       " tlbi" 6 8  6 5  .sys ?exit
   " RVAE3"        " tlbi" 6 8  6 1  .sys ?exit
   " RVALE3OS"     " tlbi" 6 8  5 5  .sys ?exit
   " RVAE3OS"      " tlbi" 6 8  5 1  .sys ?exit


   unimpl exit
;

: ptr-auth0   ( -- )
   7 bit? if  ." auti"  else  ." paci"  then
   6 bit? if  ." b"     else  ." a"    then
   8 4 bits case
      1 of   ." 1716"  endof
      3 of
	 5 bit? if  ." sp"  else  ." z"  then
      endof
      ." hint" op-col 5 7bits .imm
   endcase
;    

: hint ( -- )
   8 4bits dup if drop  ptr-auth0 exit  then drop
   5 7bits case
      0 of  ." nop"   endof
      1 of  ." yield" endof
      2 of  ." wfe"   endof
      3 of  ." wfi"   endof
      4 of  ." sev"   endof
      5 of  ." sevl"  endof
      7 of  ." xpaclri"  endof
      ." hint" op-col dup .imm
   endcase
;


: .mb  ( $opcode -- )
   type op-col crm case
      1  of  ." OSHLD"  endof
      2  of  ." OSHST"  endof
      3  of  ." OSH"    endof
      5  of  ." NSHLD"  endof
      6  of  ." NSHST"  endof
      7  of  ." NSH"    endof
      9  of  ." ISHLD"  endof
      10 of  ." ISHST"  endof
      11 of  ." ISH"    endof
      13 of  ." LD"     endof
      14 of  ." ST"     endof
      15 of  ." SY"     endof
      ." #" dup .
   endcase
;

: dmb  ( -- )  " dmb" .mb  ;
: dsb  ( -- )  " dsb" .mb  ;
: isb  ( -- )  " isb" .mb  ;

: clrex ( -- )  ." clrex" op-col crm .imm  ;

\ Introduced in H9
: pan-imm ( -- T|F ) 
   ." msr" op-col ." pan,"  
   ." #" instruction@ 8 >> 1 and .
;
    
: system ( -- )
   instruction@                    0xd500.403f = if  ." xaflag" exit then
   instruction@                    0xd500.405f = if  ." axflag" exit then
   instruction@                    0xd503.229f = if  ." csdb" exit then
   instruction@                    0xd503.309f = if  ." ssbb" exit then
   instruction@                    0xd503.30ff = if  ." sb" exit then
   instruction@                    0xd503.349f = if  ." pssbb" exit then
   instruction@ h# 0000.0100 andc h# d500.409f = if pan-imm exit then
   instruction@ h# 003f.f01f land h# 0003.201f = if hint exit then
   instruction@ h# 0030.0000 land h# 0010.0000 = if msr exit then
   instruction@ h# 0030.0000 land h# 0030.0000 = if mrs exit then
   instruction@ h# 0038.0000 land h# 0008.0000 = if sys exit then
   instruction@ h# 00f8.f01f land h# 0000.401f = if msr-cpsr exit then
   instruction@ h# 003f.f0ff land h# 0003.305f = if clrex exit then
   instruction@ h# 003f.f0ff land h# 0003.309f = if dsb exit then
   instruction@ h# 003f.f0ff land h# 0003.30bf = if dmb exit then
   instruction@ h# 003f.f0ff land h# 0003.30df = if isb exit then
   unimpl exit
;

\
\ Decode the exception bit pattern with the new rule
\ that OPC 111 (7) -> WRC, the wrapper call for the simulator.
\
: exception ( -- )
   2  3bits  ( OP2 ) if unimpl exit then
   21 3bits  ( opc ) 2 <<
   0  2bits  ( LL  ) or     ( opcLL )
   case
     1  of  ." svc"   endof
     2  of  ." hvc"   endof
     3  of  ." smc"   endof
     4  of  ." brk"   endof
     8  of  ." hlt"   endof
    21  of  ." dcps1" endof
    22  of  ." dcps2" endof
    23  of  ." dcps3" endof
    31  of  ." wrc"   endof
    unimpl drop exit
   endcase
   op-col  5 16bits .imm
;

variable dis-cur-x
: movknz ( -- )
   sf! 29 2bits " movn??? movzmovk" 4 .txt op-col
   .rd, 5 16bits
   .imm  21 2bits ?dup if ." , lsl #" 16 * .d then
   rem-col
   \ Add logic to track the current X value via movz/movk/movn instructions
   \ Get the starting value
   dis-cur-x @  29 2bits 3 <>  if  ( movz | movn ) drop 0  then

   \ Create and apply the mask based on the lsl shift count
   h# ffff  21 2bits d# 16 * <<  andc

   \ Get the immediate value, again, and OR into the value
   5 16bits 21 2bits d# 16 * <<  or

   \ Invert if movn
   29 2bits 0=  if  NOT  then
   dup dis-cur-x !
   .rd ."  = " .h
;

: ra=31?  ( -- f )  ra 31 = ;

: dataproc-3 ( -- )
   sf! 29 2bits if unimpl exit then
   21 3bits 1 << 15 1bit or dup case
      0  of  ra=31?  if  ." mul"     else  ." madd"     then endof
      1  of  ra=31?  if  ." mneg"    else  ." msub"     then endof
      2  of  ra=31?  if  ." smull"   else  ." smaddl"   then endof
      3  of  ra=31?  if  ." smnegl"  else  ." smsubl"   then endof
      4  of  ra=31?  if  ." smulh"   else  unimpl drop exit  then endof
     10  of  ra=31?  if  ." umull"   else  ." umaddl"   then endof
     11  of  ra=31?  if  ." umnegl"  else  ." umsubl"   then endof
     12  of  ra=31?  if  ." umulh"   else  unimpl drop exit  then endof
   endcase

   op-col
   21 1bit if
      .xd, .wn, ra=31? if  .wm  else  .wm, .xa  then
   else
      .rd, .rn, ra=31? if  .rm  else  .rm, .ra  then
   then

   rem-col  21 1bit if .xd else .rd then ."  = "
   dup 4 =  swap 12 =  or  if
      \ smulh and umulh don't support mixed mode registers 
      ." bits<127:63> of (" .rn ."  * " .rm ." )"
   else
      ra=31? if
         15 1bit  if  ." - "  then
      else
         \ .ra works fine here; sf = 1 therefore .ra -> Xa
         .ra 15 1bit if ."  - " else ."  + " then
      then
      \ Handle mixed mode registers, i.e., Xd = [Xa +/-] (Wn * Wm)
      ." ("
      21 1bit if .xn else .rn then ."  *  "
      21 1bit if .xm else .rm then ." )"
   then
;

: dataproc-2-ops  ( -- )  op-col  .rd, .rn, .rm  ;
: dataproc-2 ( -- )
   sf! 29 1bit if  unimpl exit  then
   10 6bits case
      2  of  ." udiv"     dataproc-2-ops  endof
      3  of  ." sdiv"     dataproc-2-ops  endof
      8  of  ." lslv"     dataproc-2-ops  endof
      9  of  ." lsrv"     dataproc-2-ops  endof
     10  of  ." asrv"     dataproc-2-ops  endof
     11  of  ." rorv"     dataproc-2-ops  endof
     16  of  ." crc32b"   dataproc-2-ops  endof
     17  of  ." crc32h"   dataproc-2-ops  endof
     18  of  ." crc32w"   dataproc-2-ops  endof
     19  of  ." crc32x"   op-col .wd, .wn, .xm  endof
     20  of  ." crc32cb"  dataproc-2-ops  endof
     21  of  ." crc32ch"  dataproc-2-ops  endof
     22  of  ." crc32cw"  dataproc-2-ops  endof
     23  of  ." crc32cx"  op-col .wd, .wn, .xm  endof
   unimpl drop exit
   endcase
;

: ptr-auth1   ( -- )
   29 3bits 6 <> if unimpl exit then
   10 5bits dup 17 > if  drop unimpl exit then  ( opcode )
   8 < if
      12 bit? if  ." aut"  else  ." pac"  then
      11 bit? if  ." d"  else  ." i"  then
      10 bit? if  ." b"     else  ." a"    then
      op-col .xd, .xn
      exit
   then
   5 5bits 31 <> if  unimpl exit then
   11 4bits 8 = if
      ." xpac"
      10 bit? if  ." d"  else  ." i"  then
      exit
   then   
   12 bit? if  ." aut"  else  ." pac"  then
   11 bit? if  ." dz"  else  ." iz"  then
   10 bit? if  ." b"     else  ." a"    then
   op-col .xd
;

: dataproc-1 ( -- )
   sf! 29 1bit if unimpl exit then
   15 6bits ?dup if
      2 = if  ptr-auth1  else  unimpl  then
      exit
   then
   10 6bits dup 5 > if drop unimpl exit then
   dup 2 = if
      drop 31 1bit  if  ." rev32"  else  ." rev"  then
   else
      " rbit rev16rev  rev  clz  cls  " 5 .txt
   then
   op-col .rd, .rn
;

\ =======================================
\
\          LOAD STORE HANDLERS
\
\ =======================================

: ldst-szvop ( -- szvop )
   30 2bits 3 <<
   26 1bit  2 <<
   22 2bits or or
;

: .ldst+  ( c $suffix -- )  rot ?dup if  emit  then  ." r" type  op-col  ;
: .st     ( c $suffix -- )   ." st" .ldst+  ;
: .ld     ( c $suffix -- )   ." ld" .ldst+  ;
: .??     ( c $suffix -- )   ." ???"   op-col  ;

: .prfm   ( c -- )  ." prf"  ?dup if emit then  ." m" op-col  ;

binary

: ldst! ( -- )
   ldst-szvop
   case
      ( szVop  Type )
      00000  of  wreg  endof  \ STRB
      00001  of  wreg  endof  \ LDRB
      00010  of  xreg  endof  \ LDRSB  X
      00011  of  wreg  endof  \ LDRSB  W
      00100  of  breg  endof  \ STR B
      00101  of  breg  endof  \ LDR B
      00110  of  qreg  endof  \ STR Q
      00111  of  qreg  endof  \ LDR Q
      01000  of  wreg  endof  \ STRH
      01001  of  wreg  endof  \ LDRH
      01010  of  xreg  endof  \ LDRSH  X
      01011  of  wreg  endof  \ LDRSH  W
      01100  of  hreg  endof  \ STR H
      01101  of  hreg  endof  \ LDR H
      01110  of   -1   endof  \ undefined
      01111  of   -1   endof  \ undefined
      10000  of  wreg  endof  \ STR W
      10001  of  wreg  endof  \ LDR W
      10010  of  xreg  endof  \ LDRSW
      10011  of   -1   endof  \ undefined
      10100  of  sreg  endof  \ STR S
      10101  of  sreg  endof  \ LDR S
      10110  of   -1   endof  \ undefined
      10111  of   -1   endof  \ undefined
      11000  of  xreg  endof  \ STR X
      11001  of  xreg  endof  \ LDR X
      11010  of  xreg  endof  \ PRFM X
      11011  of   -1   endof  \ undefined
      11100  of  dreg  endof  \ STR D
      11101  of  dreg  endof  \ LDR D
      11110  of   -1   endof  \ undefined
      11111  of   -1   endof  \ undefined
   endcase
   instr-regtype !
;


: .ldst ( c -- special-prfm-case? )
   ldst-szvop
   case
      00000  of  " b" .st   endof  \ STRB
      00001  of  " b" .ld   endof  \ LDRB
      00010  of  " sb" .ld  endof  \ LDRSB  X
      00011  of  " sb" .ld  endof  \ LDRSB  W
      00100  of  " " .st    endof  \ STR B
      00101  of  " " .ld    endof  \ LDR B
      00110  of  " " .st    endof  \ STR Q
      00111  of  " " .ld    endof  \ LDR Q
      01000  of  " h" .st   endof  \ STRH
      01001  of  " h" .ld   endof  \ LDRH
      01010  of  " sh" .ld  endof  \ LDRSH  X
      01011  of  " sh" .ld  endof  \ LDRSH  W
      01100  of  " " .st    endof  \ STR H
      01101  of  " " .ld    endof  \ LDR H
      01110  of    .?? drop     endof  \ undefined
      01111  of    .?? drop     endof  \ undefined
      10000  of  " " .st    endof  \ STR W
      10001  of  " " .ld    endof  \ LDR W
      10010  of  " sw" .ld  endof  \ LDRSW
      10011  of    .?? drop     endof  \ undefined
      10100  of  " " .st    endof  \ STR S
      10101  of  " " .ld    endof  \ LDR S
      10110  of    .?? drop     endof  \ undefined
      10111  of    .?? drop  endof  \ undefined
      11000  of  " " .st    endof  \ STR X
      11001  of  " " .ld    endof  \ LDR X
      11010  of  .prfm true exit endof  \ PRFM returns TRUE -- special case
      11011  of    .?? drop      endof  \ undefined
      11100  of  " " .st    endof  \ STR D
      11101  of  " " .ld    endof  \ LDR D
      11110  of    .?? drop     endof  \ undefined
      11111  of    .?? drop     endof  \ undefined
   endcase
   false
;


\ The 7 bit register pair immediate values are scaled, as is the 12 bit
\ unsigned register  offset.  But the 9 bit register post/pre index values
\ are not scaled.  I don't know why.

binary
: ldst-scale ( -- scale )
   ldst-szvop
   case
      00001  of  d# 1  endof  \ LDRB W
      01001  of  d# 2  endof  \ LDRH W
      00011  of  d# 1  endof  \ LDRSB  W
      00010  of  d# 1  endof  \ LDRSB  X
      01011  of  d# 2  endof  \ LDRSH  W
      01010  of  d# 2  endof  \ LDRSH  X
      10010  of  d# 4  endof  \ LDRSW  X
      10001  of  d# 4  endof  \ LDR W
      11001  of  d# 8  endof  \ LDR X
      00101  of  d# 1  endof  \ LDR B
      11101  of  d# 8  endof  \ LDR D
      01101  of  d# 2  endof  \ LDR H
      00111  of  d# 16 endof  \ LDR Q
      10101  of  d# 4  endof  \ LDR S
      11010  of  d# 8  endof  \ PRFM X
      00000  of  d# 1  endof  \ STRB W
      01000  of  d# 2  endof  \ STRH W
      10000  of  d# 4  endof  \ STR W
      11000  of  d# 8  endof  \ STR X
      00100  of  d# 1  endof  \ STR B
      11100  of  d# 8  endof  \ STR D
      01100  of  d# 2  endof  \ STR H
      10100  of  d# 4  endof  \ STR S
      00110  of  d# 16 endof  \ STR Q
      0 swap
   endcase
;

: .prfm-rt  ( -- )
   rt case
     00000 of  ." PLDL1KEEP" endof
     00001 of  ." PLDL1STRM" endof
     00010 of  ." PLDL2KEEP" endof
     00011 of  ." PLDL2STRM" endof
     00100 of  ." PLDL3KEEP" endof
     00101 of  ." PLDL3STRM" endof
     01000 of  ." PLIL1KEEP" endof
     01001 of  ." PLIL1STRM" endof
     01010 of  ." PLIL2KEEP" endof
     01011 of  ." PLIL2STRM" endof
     01100 of  ." PLIL3KEEP" endof
     01101 of  ." PLIL3STRM" endof
     10000 of  ." PSTL1KEEP" endof
     10001 of  ." PSTL1STRM" endof
     10010 of  ." PSTL2KEEP" endof
     10011 of  ." PSTL2STRM" endof
     10100 of  ." PSTL3KEEP" endof
     10101 of  ." PSTL3STRM" endof
     dup .imm
   endcase
;
: .prfm-rt,  ( -- )  .prfm-rt .,  ;

decimal

: ldst-common  ( c -- )
   ldst! ( c ) .ldst
   ( prfm? ) if  .prfm-rt,  else  .rd,  then
   .[xn|sp
;
: .ldst-imm    ( n -- )  ?dup if  ., .imm then .]  ;

: ldst[xn|sp],#     ( -- )        0 ldst-common   .] ., simm9 .imm        ;
: ldst[xn|sp,#]!    ( -- )        0 ldst-common      ., simm9 .imm .] .!  ;

: ldst[xn|sp{,#}]   ( -- )        0 ldst-common imm12 ldst-scale * .ldst-imm  ;
: ldstt[xn|sp{,#}]  ( -- )  ascii t ldst-common simm9              .ldst-imm  ;
: ldstu[xn|sp{,#}]  ( -- )  ascii u ldst-common simm9              .ldst-imm  ;

: ldweak   ( -- )
   ." ldapr"
   30 2bits case
      0 of  ." b"  endof
      1 of  ." h"  endof
   endcase
   op-col
   30 2bits 3 = if  xreg  else wreg  then  instr-regtype !
   .rd, .[xn|sp  .] 
;

: ldst[xn|sp,rm]  ( -- )
   13 3bits case
      2  of  wreg  endof
      3  of  xreg  endof
      6  of  wreg  endof
      7  of  xreg  endof
      unimpl drop exit
   endcase

   0 ldst-common
   ., rm swap .lnamedreg
   12 4bits 6 <> if
      ., 15 1bit 1 <<  13 1bit or
      dup " uxtwlsl sxtwsxtx" 4 .txt
      1 <> if space then
       \ drm 1/12/13 add log2 because shift
       \ needs to be accurate and match the assembler
       \ for lsl #3, this was displaying lsl #8
      12 1bit ldst-scale * log2 .imm
   then
   .]
;

: ldst[pc,#]  ( -- )
   30 2bits 1 << 26 1bit or
   dup 6 = if
      drop 0 .prfm .prfm-rt
   else
      dup 4 = if
	 drop ." ldrsw" op-col rd xreg .lnamedreg
      else
	 ." ldr" op-col
	 dup 2 = if
	    drop rd xreg .lnamedreg
	 else
	    ( size ) " ws?d?q??" 1 .txt rd .d
	 then
      then
   then
   \ ." , $" 5 19 sxbits 2 << dup .d  rem-col instr-addr @ + dup .h .'
   \ always display the PC, on pc relative ops
   ." , [pc, #"   
   5 19 sxbits 2 << dup .d  
   ." ] "
   rem-col 
   dup .h 
   instr-addr @ + dup .h .'
;

\ =======================================
\
\     LOAD / STORE PAIRS OF REGISTERS
\
\ =======================================

: ldstp-opvl
  30 2bits 2 <<   \ OP
  26 1bit  1 <<   \ V
  22 1bit  or or  \ L
;

: .ldstp_rt,ru_[xn|sp  ( -- )
   ldstp-opvl
   dup 2 >> 3 = if drop unimpl exit then   \ OPC == 3 is not an instruction
   dup 4 = if drop unimpl exit then        \ STPSW is not an instruction
   dup 1 and if ." ld" else ." st" then
   23 3bits 0= if ." n" then         \ Handle the no-allocate variant
   ." p"
   ( opcVL ) 1 >> dup 2 = if ." sw" then
   op-col
   ( opcV ) case
      0  of  wreg  endof   \ LDP    Wt, Wu
      1  of  sreg  endof   \ LDP    St, Su
      2  of  xreg  endof   \ LDPSW  St, Su
      3  of  dreg  endof   \ LDP    Dt, Du
      4  of  xreg  endof   \ LDP    Xt, Xu
      5  of  qreg  endof   \ LDP    Qt, Qu
      drop unimpl  exit
   endcase
   instr-regtype !
   .rd, .ra, .[xn|sp
;

\
\ .ldstp_simm7 will print the scaled, signed immediate 7 bit offset for the
\ ldp/stp instruction family.  Note that the scale is generated by using
\ two simple rules: Vector register classes scale as the OPC bits + 2.
\ The Scalar register classes scale as OPC<1> + 2.
\
: .ldstp_simm7  ( -- )
   simm7 ?dup 0= if  exit  then
   ldstp-opvl  1 >>                       \ Drop Load/Store flag
   dup 1 and if 1 >> else 2 >> then 2 +   \ Calculate the scale
   << ., .imm
;   

: ldstnp[xn|sp,#]  ( -- )  .ldstp_rt,ru_[xn|sp    .ldstp_simm7 .]    ;
: ldstp[xn|sp,#]   ( -- )  .ldstp_rt,ru_[xn|sp    .ldstp_simm7 .]    ;
: ldstp[xn|sp],#   ( -- )  .ldstp_rt,ru_[xn|sp .] .ldstp_simm7       ;
: ldstp[xn|sp,#]!  ( -- )  .ldstp_rt,ru_[xn|sp    .ldstp_simm7 .] .! ;


\ XX line 1297 of original

\ removed simd ld/st

\ XX line 1848 of original

\ =======================================
\
\            LOAD / STORE EXCLUSIVE
\
\ =======================================

: ldstx  ( -- )
   30 2bits                                    ( size )
   dup 3 =  if xreg else wreg then             ( size wreg|xreg )
   instr-regtype !                             ( size )

   22 bit? dup  if ." ld" else ." st" then     ( size load? )
   
   \ drm 4/14/15
   \ qualify new Limited Ordering (LO) region class
   \ o2[23]=1 o1[21]=0 o0[15]=0
   23 bit?  
   21 bit? 0= and  
   15 bit? 0= and
   IF 
        ." lo" 
        ( size load? ) if ." a" else ." l" then 
        ( size ) " rbrhr r " 2 .txt
        op-col .rs,? .rt,
       .[ .xn .]
        exit
   THEN
   
   
   

   15 bit?  if
      ( load? ) if ." a" else ." l" then       ( size )
   else
      drop
   then

   23 bit? 0=  if ." x" then                   ( size )

   21 bit?  if                                 \ o1 = pair 
      drop ." p"
      op-col .rs,? .rt, .rt2,
   else
      ( size ) " rbrhr r " 2 .txt
      op-col .rs,? .rt,
   then



   .[ .xn .]
;

\ =======================================
\
\            v8.1 Atomic Instructions
\
\ =======================================

: sz->xwhb  ( -- )
   30 2bits                                    ( size ) 
   case
      3 of  xreg         endof
      2 of  wreg         endof
      1 of  wreg  ." h"  endof
      0 of  wreg  ." b"  endof
   endcase
   instr-regtype !
;
: sz->wx  ( -- )
   30 bit? if xreg else wreg then               ( size ) 
   instr-regtype !
;

\ ATOMIC ops
: cas  ( -- )
   ." cas"
   23 bit? if
      22 bit?  if ." a" then
      15 bit?  if ." l" then
      sz->xwhb
      op-col 
      .rs, .rt,
   else
      ." p"
      22 bit?  if ." a" then
      15 bit?  if ." l" then
      sz->wx
      op-col 
      \ .rs, rs 1+ instr-regtype @ .r# .,
      \ .rt, rt 1+ instr-regtype @ .r# .,
      .rs, .rt,
   then
   .[ .xn .]
;
: swp  ( -- )
   ." swp"
   23 bit?  if ." a" then
   22 bit?  if ." l" then
   sz->xwhb
   op-col 
   .rs, .rt,
   .[ .xn .]
;
: .lsop  ( op -- )
   case
      0 of   ." add"   endof
      1 of   ." bic"   endof
      2 of   ." eor"   endof
      3 of   ." set"   endof
      4 of   ." smax"  endof
      5 of   ." smin"  endof
      6 of   ." umax"  endof
      7 of   ." umin"  endof
   endcase
   23 bit?  if ." a" then
   22 bit?  if ." l" then
   sz->xwhb
;
: ldstop  ( -- )
   0 5bits 0x1f =
   if
      ." st"
      12 3bits .lsop
      op-col .rs,
   else
      ." ld"
      12 3bits .lsop
      op-col .rs, .rt,
   then
   .[ .xn .]
;

\ =======================================
\
\            BRANCH HANDLERS
\
\ =======================================

: ?calling-forth   ( target -- )
   \ test for a branch and link to _reenter-forth_
   dup d# 20 - d# 15  " _reenter-forth_"  $compare  if   ( target )
      ." 0x" dup .h .' exit
   then   ( target )
   drop ." call-forth " dis-cur-x @ origin + 5 - dup c@ h# 80 and  if
      dup c@ h# 7f and tuck - swap type
   else
      5 + .h
   then
;
: .br-target  ( offset -- )
   2 << dup ." $" dup 0> if ." +" then .d    ( offset )
   rem-col  instr-addr @ +                   ( target )
   dup in-dictionary? 0= testing-disassembler @ or if  ." 0x" .h  exit  then   ( target )
   ?calling-forth
;

: .op  ( index adr,len /entry -- )  .txt  op-col ;

: br-uncond-imm ( -- )   31 1bit " b bl " 2 .op      0 26sbits  .br-target  ;
: cmp-br-imm  ( -- )  sf!  24 1bit " cbz cbnz" 4 .op  .rd,  5 19sbits  .br-target  ;
: tst-br-imm  ( -- )
   24 1bit " tbz tbnz" 4 .op
   31 1bit 5 <<  19 5bits or
   sf!  .rd,  ." #" .d .,
   5 14sbits .br-target
;
\ debug .rd

: .cond ( cond -- )   " eqnecsccmiplvsvchilsgeltgtlealnv" 2 .txt  ;

: br-cond-imm  ( -- )
   24 1bit  4 1bit or  if  unimpl  exit  then
   ." b."  0 4bits .cond op-col 5 19sbits .br-target
;
: ptr-auth3   ( -- )
   22 2bits case
      1 of   ." reta"   endof
      2 of   ." ereta"  endof
      illegal drop exit
   endcase
   10 bit? if  ." b"     else  ." a"    then
;

: ptr-auth-br   ( -- )
   24 bit? if
      21 bit? if   ." blra"   else  ." bra"  then
      10 bit? if  ." b"     else  ." a"    then
      op-col  .xn, .xd     \ note: unusual order
      exit
   then
   22 2bits 0= if
      21 bit? if  ." blra"  else  ." bra"  then
      10 bit? if  ." bz"    else  ." az"   then
      op-col  .xn
      exit
   then
   0 5bits 31 <> if  unimpl  exit  then
   22 2bits case
      1 of   ." reta"   endof
      2 of   ." ereta"  endof
      illegal drop exit
   endcase
   10 bit? if  ." b"     else  ." a"    then
;

: br-uncond-reg  ( -- )
   11 5bits 1 = if  ptr-auth-br  exit  then
   imms rd or rm 5 mask xor or  if  unimpl  exit  then
   21 4bits case
      0  of  ." br"   op-col  .xn  endof
      1  of  ." blr"  op-col  .xn  endof
      2  of  ." ret"  op-col  .xn  endof
      4  of  rn=sp?  if  ." eret"  else  unimpl drop exit  then  endof
      5  of  rn=sp?  if  ." drps"  else  unimpl drop exit  then  endof
	 unimpl ." br-uncond-reg " drop exit
   endcase
   instruction@ h# d61f0300 = if
      rem-col ." next"
      1 end-found !
   then
   instruction@  h# ffff.fc1f and h# d65f.0000 = if
      rem-col ." ret"
      1 end-found !
   then
;

: adr  ( -- )
   ." adr"  31 1bit if ." p" then
   op-col  .xd,
   5 19 sxbits 2 << 29 2bits or    ( imm21 )
   31 1bit if
      12 << dup ." $" dup 0> if ." +" then .d
      rem-col instr-addr @ 12 mask andc + .h
   else
      dup ." $" dup 0> if ." +" then .d
      rem-col ." 0x" instr-addr @ + .h
   then
;


\ =======================================
\
\            CONDITIONAL LOGIC
\
\ =======================================

: cond-select  ( -- )
   sf!
   29 1bit if  unimpl exit  then
   11 1bit if  unimpl exit  then
   30 1bit 1 <<
   10 1bit or " csel csinccsinvcsneg" 5 .txt
   op-col  .rd, .rn, .rm, 12 4bits .cond
;

: cond-compare  ( -- )
   sf!
   30 1bit " ccmnccmp" 4 .txt
   op-col .rn,
   11 1bit if
      16 5bits .imm,
   else
      .rm,
   then
   0 4bits .imm,  12 4bits .cond
;
\ XXX line 2115 of original

\ removed simd

\ XXX line 4091 of original
: pacga   ( -- )
   ." pacga" op-col  .xd, .xn, .xm
;

: ptr-auth-ld   ( -- )
   ." ldra" 
   23 bit? if  ." b"     else  ." a"    then
   op-col  .[xn|sp
   11 bit? if
      ., simm9 .imm .] .!
   else
      simm9 .ldst-imm
   then
;

\ XXX line 4105 of original

