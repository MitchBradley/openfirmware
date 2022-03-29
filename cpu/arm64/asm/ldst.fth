\ Load and Store instructions

\ =======================================
\
\    Addressing Modes
\
\ =======================================

: ?|0|ds   ( ds x -- x s )
   "#"?          0= if  swap  drop 0 exit  then
   >c
   swap    ( x ds )
   #uimm5 swap over = if  drop 1 exit  then
   ( imm ) dup   0= if  drop 0 exit  then
   ( imm ) dup  if
      ." Expecting blank, 0 or " . " shift amount" ad-error
   else
      " blank or 0 shift amount" expecting
   then
;

: ?extending  ( datasize -- shift-type  S )
   ","?  0=  if
      drop
      rm-adt adt-xreg <> " X register when no shift/extension is specified" ?expecting
      3 0
   else
      <c $case
         " lsl"  $sub  c>  ?Rm=X  3  ?|0|ds  $endof
         " uxtw" $sub  c>  ?Rm=W  2  ?|0|ds  $endof
         " sxtw" $sub  c>  ?Rm=W  6  ?|0|ds  $endof
         " sxtx" $sub  c>  ?Rm=X  7  ?|0|ds  $endof
         " no extending rule or LSL, UXTW, SXTW, or SXTX" expecting
      $endcase
   then
;


\
\ Address syntaxes that allow a pre-index form ([xn|sp{,#}]! must be checked
\ before [xn|sp{,#}] because the latter won't match the write-back exclamation
\ point.  This word ensures that to be the case and flags an error if a "!"
\ is found.

: <>"!"
   "!"? if
      " INTERNAL ERROR: [xn|sp{,#}]! must be checked before [xn|sp{,#}]"
      ad-error
   then
;
: [xn|sp           ( -- )    "[" xn|xsp ;
: [xn|sp,          ( -- )    [xn|sp "," ;
: [xn|sp]          ( -- )    [xn|sp "]" ;
: [xn|sp],         ( -- )    [xn|sp] "," ;
: [xn|sp,#9]       ( -- n )  [xn|sp,          #simm9]    ;   \ <!>   Always used in wb forms
: [xn|sp{,#9}]     ( -- n )  [xn|sp ","?  if  #simm9]   else  0 "]"  then  <>"!" ;
: [xn|sp{,#p12}]   ( -- n )  [xn|sp ","?  if  #uimm15]  else  0 "]"  then  <>"!" ;
: [xn|sp],#9       ( -- n )  [xn|sp "]" ","   #simm9  ;
: [xn|sp,xm<ext>]  ( -- )    [xn|sp, wxm  ?extending  "]"  ;
: [xn|sp{,#0}]     ( -- )    [xn|sp ","?  if  #uimm0 0 <> " 0" ?expecting then  "]"  ;

\
\ PC Relative needs a different set of OPC V values than those
\ used by the LDR instruction.  So, when testing for PC Relative addressing
\ mode, we simply dump the sz-V-opc triplet and regenerate opc-V.
\

: pcrel-opc-v  ( -- opc V )
   rd-adt case
      adt-wreg  of  0 0  endof
      adt-xreg  of  1 0  endof
      adt-sreg  of  0 1  endof
      adt-dreg  of  1 1  endof
      adt-qreg  of  2 1  endof
      adt-vreg  of  2 1  endof
      adt-prfop of  3 0  endof
      " Invalid register type specified for PC Relative addressing mode" ad-error
   endcase
;

: ^pcrel  ( opc v target -- )
   here - dup 3 and " word aligned offset to pc relative data" ?expecting
   dup dup sext 0< if -1 xor then 1 20 << >= " pc relative data must be +/- 1MB" ?expecting
   2 >> dup h# 2000.0000 and if h# C000.0000 or then  \ Propagate the sign bit
   19 mask and 5 19 ^^op
   0x18000000 iop
   ( v )   26 1 ^^op
   ( opc ) 30 2 ^^op
;


: pcrel  ( sz opc V -- opc v target )
   \ Special case 2 0 2 which is an LDRSW instruction that needs to be remapped
   2 = swap 0= and swap 2 = and if  2 0  else  pcrel-opc-v  then
   br-target
;


\ =======================================
\
\    Load Store
\
\ =======================================

\ The 7 bit register pair immediate values are scaled, as is the 12 bit
\ unsigned register  offset.  But the 9 bit register post/pre index values
\ are not scaled.  I don't know why.

binary
: sz-v-op>scale ( sz v opc -- scale )
   rot 3 <<  rot 2 <<  or or  case
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
      11010  of  d# 8  endof  \ PREFETCH, multiple of 8 bytes
      00000  of  d# 1  endof  \ STRB W
      01000  of  d# 2  endof  \ STRH W
      10000  of  d# 4  endof  \ STR W
      11000  of  d# 8  endof  \ STR X
      00100  of  d# 1  endof  \ STR B
      11100  of  d# 8  endof  \ STR D
      01100  of  d# 2  endof  \ STR H
      00110  of  d# 16 endof  \ STR Q
      10100  of  d# 4  endof  \ STR S
   endcase
;
decimal

: lsm-sz30  ( -- )   xm? if  0x4000.0000 iop  then  ;
: ls-sz30   ( -- )   xd? if  0x4000.0000 iop  then  ;
: ls-sz22   ( -- )   xd? 0= if  0x0040.0000 iop  then  ;
: ls-szq  ( -- )
   rd-adt case
      adt-wreg  of  0x80000000  endof
      adt-xreg  of  0xc0000000  endof
      adt-breg  of  0x04000000  endof
      adt-hreg  of  0x44000000  endof
      adt-sreg  of  0x84000000  endof
      adt-dreg  of  0xc4000000  endof
      adt-qreg  of  0x04800000  endof
      adt-vreg  of  0x04800000  endof
   endcase   ( op )  iop
;

: lsi9     ( op regs -- )   rd, rd??iop  ls-sz30  [xn|sp{,#9}] 12 9 ^^op  ;
: lsi9a    ( op regs -- )   rd, rd??iop  ls-sz22  [xn|sp{,#9}] 12 9 ^^op  ;
: lsi9b    ( op regs -- )   rd, rd??iop  ls-szq  [xn|sp{,#9}] 12 9 ^^op  ;
: %lsi9    ( op regs -- )   <asm  lsi9  asm>  ;
: %lsi9a   ( op regs -- )   <asm  lsi9a  asm>  ;
: %lsi9b   ( op regs -- )   <asm  lsi9b  asm>  ;

: ^ls-imm9 ( sz v opc op imm9 -- )
   0x38000000 iop
   ( imm9 ) 12 9 ^^op
   ( op )   10 2 ^^op
   ( opc )  22 2 ^^op
   ( v )    26 1 ^^op
   ( sz )   30 2 ^^op
;

: imm-scale ( sz v opc imm -- sz v opc imm12 )
   >r 3dup sz-v-op>scale r@ over 1- and if 
      abort-try ." a " r@ . " byte alignment."  ad-error
   then
   r> swap /
;

: ^ls-imm12 ( sz v opc imm -- )
   0x39000000 iop
   imm-scale
   12 #uimm-check
   ( imm12 ) 10 12  ^^op
   ( opc )   22  2  ^^op
   ( v )     26  1  ^^op
   ( sz )    30  2  ^^op
;

\ special case to enable larger user area
: ^ls-imm12-up ( sz v opc imm -- )
   dup 32768 >= if             \ large offset from UP
      0x91402318 asm,          \ add  up,up,#`32kb`
      32768 -
      ^ls-imm12
      opcode asm,
      0xd1402318  is opcode   \ sub  up, up, #`32kb`
   else
      ^ls-imm12
   then
;
\ special case to enable larger user area
: x^ls-imm12-up ( sz v opc imm12 -- )
   0x39000000 iop
   imm-scale
   >r    ( sz v opc )
   ( opc )   22  2  ^^op
   ( v )     26  1  ^^op
   ( sz )    30  2  ^^op
   r>    ( imm )
   
   dup 4096 >=  ( <rn> 24 = and )  if    \ large offset from UP
      \ move UP while accessing the second 32KB in the user area
      0x91402318 asm,          \ add  up,up,#`32kb`
      4096 -
      12 #uimm-check
      ( imm12 ) 10 12  ^^op
      opcode asm,
      0xd1402318  is opcode   \ sub  up, up, #`32kb`
   else
      12 #uimm-check
      ( imm12 ) 10 12  ^^op
   then
;


: ^ls-reg  ( sz v opc shft s -- )
   0x38200800 iop
   ( s )     12 1 ^^op
   ( shft )  13 3 ^^op
   ( opc )   22 2 ^^op
   ( v )     26 1 ^^op
   ( sz )    30 2 ^^op
;

: rs>2/3  ( -- opc )   rm-adt adt-wreg = if  2  else  3  then ;
: wx>2/3  ( -- opc )   rd-adt adt-wreg = if  2  else  3  then ;
: wx>3/2  ( -- opc )   rd-adt adt-wreg = if  3  else  2  then ;

:  prfop,  ( -- )
   <c scantodelim c>  2dup upper $case
     " PLDL1KEEP"      $of   0  $endof
     " PLDL1STRM"      $of   1  $endof
     " PLDL2KEEP"      $of   2  $endof
     " PLDL2STRM"      $of   3  $endof
     " PLDL3KEEP"      $of   4  $endof
     " PLDL3STRM"      $of   5  $endof
     " PLIL1KEEP"      $of   8  $endof
     " PLIL1STRM"      $of   9  $endof
     " PLIL2KEEP"      $of  10  $endof
     " PLIL2STRM"      $of  11  $endof
     " PLIL3KEEP"      $of  12  $endof
     " PLIL3STRM"      $of  13  $endof
     " PSTL1KEEP"      $of  16  $endof
     " PSTL1STRM"      $of  17  $endof
     " PSTL2KEEP"      $of  18  $endof
     " PSTL2STRM"      $of  19  $endof
     " PSTL3KEEP"      $of  20  $endof
     " PSTL3STRM"      $of  21  $endof
   true " a PRFOP field name" ?expecting  
   $endcase    ( $ instr-encoding )
   0 5 ^^op
   adt-prfop is rd-adt
   "," 
;

\ ARM v8.3
: %ldraa   ( opcode -- )
   <asm
   xd, iop
   [xn|sp{,#9}]  12 9 ^^op
   "!"? if  0x800 iop  then
   asm>
;


\ =======================================
\
\    Load/Store Pairs
\
\ =======================================

: user-defined
   <c scantobl c>  $asm-execute 0= if " Free form text didn't find valid word" ad-error then
;

\ Install the User Pointer virtual machine register as Rn.
\ asmtest? [if]
: up^rn    ( -- )    " up"    $reg drop  ^rn  ;
: sav^rn   ( -- )    " sav"   $reg drop  ^rn  ;
\ [else]
\ : up^rn    ( -- )    " up"    eval drop  ^rn  ;
\ : sav^rn   ( -- )    " sav"   eval drop  ^rn  ;
\ [then]

: ?'user  ( "name" -- user# )
   " 'user " ?$match
   \ Make a local string with the next word of input to contain:
   \ 'user <next-word>
   " 'user                            "  2dup 5 /string blank over 6 +
   <c  scantobl  c>
   rot swap cmove eval
;

\ The next two are useful for PC-relative modes with ADR, B, or LDR
: ?'code  ( "name" -- acf )
   " 'code " ?$match
   \ Make a local string with the next word of input to contain:
   \ 'code <next-word>
   " 'code                            "  2dup 5 /string blank over 6 +
   <c  scantobl  c>
   rot swap cmove eval
;
: ?'body  ( "name" -- apf )
   " 'body " ?$match
   \ Make a local string with the next word of input to contain:
   \ 'body <next-word>
   " 'body                            "  2dup 5 /string blank over 6 +
   <c  scantobl  c>
   rot swap cmove eval
;

\ for referencing saved-state variables
\ implicitly uses sav register
: ?'state  ( "name" -- state-offset )
   " 'state " ?$match
   \ Make a local string with the next word of input to contain:
   \ 'code <next-word>
   " 'state                            "  2dup 6 /string blank over 7 +
   <c  scantobl  c>
   rot swap cmove eval
;

0 value imm-signed
0 value imm-multiplier
0 value imm-fieldwidth

: #uimm/sz-check  ( n -- )
   imm-multiplier /
   ( n/sz ) imm-fieldwidth mask
   andc  if
      abort-try  ." Immediate value exceeds field width for instruction"
   then
;
: #simm/sz-check  ( n -- )
   \ Negative numbers have more range, by 1
   ( n )  dup  0<  if  abs 1-  then
   imm-fieldwidth 1- is imm-fieldwidth
   ( +n )  #uimm/sz-check
   imm-fieldwidth 1+ is imm-fieldwidth
;
: #imm/sz-check  ( n -- opbits )
   ( n ) dup imm-multiplier 1- and  if
      abort-try  ." Expecting a number which is a multiple of " imm-multiplier . " " ad-error
   then
   imm-signed  if  dup #simm/sz-check  else  dup #uimm/sz-check  then
   \ N has passed all of its tests.
   \ Now divide it down and mask it.
   ( n )    Imm-multiplier /
   ( n/sz ) imm-fieldwidth mask and
   ( opbits )
;
: [xn|sp],#imm/sz    ( -- n )
   [xn|sp], "##" snimm
;
: [xn|sp{,#imm/sz}]!  ( -- n )
   [xn|sp,  #eval]  "!"
;
: [xn|sp{,#imm/sz}]  ( -- n )
   [xn|sp ","?  if  #eval]  else  "]"  0  then
;

: ^ldst-pair  ( L V opc adr-mode imm -- )
   true is imm-signed
   7    is imm-fieldwidth
   ( imm ) #imm/sz-check  \ -> imm7
   5 ( pair )   27 3 ^^op
   ( imm7 )     15 7 ^^op
   ( adr-mode ) 23 3 ^^op
   ( opc )      30 2 ^^op
   ( V )        26 1 ^^op
   ( L )        22 1 ^^op
;   

: rd->V,opc,sz  ( -- V opc sz )
   \ Ensure that Rd and Ra are not the same register.
   rd-adt ra-adt <> " Rt and Rt2 are the same data type" ?expecting
   rd-adt case   \  V opc sz
      adt-wreg  of  0  0  4  endof
      adt-xreg  of  0  2  8  endof
      adt-sreg  of  1  0  4  endof
      adt-dreg  of  1  1  8  endof
      adt-qreg  of  1  2  16 endof
      adt-vreg  of  1  2  16 endof
      " W, X, S, D, or Q register types" expecting
   endcase
;

: warn-ldstp-ill-wb  ( -- )
   \ Check the current instruction to see if it has an illegal writeback
   \ And warn if that's the case.
   \ NOTE: If the Rn field is the stack, then there's no chance of a writeback
   \       issue because the SP cannot be the source of a st nor the destination
   \       in a ld.
   rn#=sp?  if  exit  then
   rn#=XWt#? rn#=XWt2#? or  if
      " ldp/stp instruction with address write back where rt or rt2 is the same as the rn"
      warning$  $add
   then
;

: ldstp-adr-opc2  ( sz idx -- adr-mode simm )
   swap is imm-multiplier
   case
      0  of  1  [xn|sp],#imm/sz      ^ldst-pair  warn-ldstp-ill-wb  endof
      1  of  3  [xn|sp{,#imm/sz}]!   ^ldst-pair  warn-ldstp-ill-wb  endof
      2  of  2  [xn|sp{,#imm/sz}]    ^ldst-pair                     endof
      3  of  2  up^rn  ?'user        ^ldst-pair  endof
      4  of  2         ?'body        ^ldst-pair  endof
      5  of  2         ?'code        ^ldst-pair  endof
      6  of  2  sav^rn ?'state       ^ldst-pair  endof
      7  of  2  user-defined         ^ldst-pair  endof
   endcase
;

: make-no-allocate  ( -- )
   \ Convert an opcode to a no-allocate variety: No checking done!
   opcode 0x0180.0000 andc is opcode
;


\ =======================================
\
\    Load Register Byte
\
\ =======================================

: warn-ldst-ill-wb  ( -- )
   \ Check the current instruction to see if it has an illegal writeback
   \ And warn if that's the case.
   \ NOTE: If the Rn field is the stack, then there's no chance of a writeback
   \       issue because the SP cannot be the source of a st nor the destination
   \       in a ld.
   rn#=sp?  if  exit  then
   rn#=XWd#?  if
      " ldr/str instruction with address write back where rd is the same as the rn"
      warning$  $add
   then
;

\ general load and store addressing modes
: adrmodes-1   ( idx sz V opc -- )
   4rot  case   ( sz V opc -- )
      0  of   3       [xn|sp,#9]           ^ls-imm9  <!>  warn-ldst-ill-wb  endof
      1  of   1       [xn|sp],#9           ^ls-imm9       warn-ldst-ill-wb  endof
      2  of   2 pick  [xn|sp,xm<ext>]      ^ls-reg        endof
      3  of           [xn|sp{,#p12}]       ^ls-imm12      endof
      4  of   up^rn   ?'user               ^ls-imm12-up   endof
      5  of   sav^rn  ?'state              ^ls-imm12      endof
      " INTERNAL ERROR: Shouldn't get here" ad-error
   endcase
;
\ some loads can also use PC-relative addressing
: adrmodes-2   ( idx sz V opc -- )
   4rot  case   ( sz V opc -- )
      0  of   3       [xn|sp,#9]          ^ls-imm9  <!>  warn-ldst-ill-wb  endof
      1  of   1       [xn|sp],#9          ^ls-imm9       warn-ldst-ill-wb  endof
      2  of   2 pick  [xn|sp,xm<ext>]     ^ls-reg        endof
      3  of           [xn|sp{,#p12}]      ^ls-imm12      endof
      4  of   up^rn   ?'user              ^ls-imm12-up   endof
      5  of   sav^rn  ?'state             ^ls-imm12      endof
      6  of   pcrel                       ^pcrel         endof            
      " INTERNAL ERROR: Shouldn't get here" ad-error
   endcase
;
\ prfm addressing modes
: adrmodes-3   ( idx sz V opc -- )
   4rot  case   ( sz V opc )
      0  of   2 pick  [xn|sp,xm<ext>]      ^ls-reg        endof
      1  of           [xn|sp{,#p12}]       ^ls-imm12      endof
      2  of   up^rn   ?'user               ^ls-imm12-up   endof
      3  of   sav^rn  ?'state              ^ls-imm12      endof
      4  of   pcrel                        ^pcrel         endof            
      " INTERNAL ERROR: Shouldn't get here" ad-error
   endcase
;

: wxd,->3/2   ( -- 2|3 )  wxd, rd-adt adt-xreg = if 2 else 3 then  ;


\ =======================================
\
\    Standard Load/Store
\
\ =======================================

: rd->sz,v,opc  ( -- sz V opc )
   rd-adt case
      adt-wreg  of  2 0 1  endof
      adt-xreg  of  3 0 1  endof
      adt-breg  of  0 1 1  endof
      adt-hreg  of  1 1 1  endof
      adt-sreg  of  2 1 1  endof
      adt-dreg  of  3 1 1  endof
      adt-qreg  of  0 1 3  endof
      adt-vreg  of  0 1 3  endof
      " Invalid register type specified" ad-error
   endcase
;


\ =======================================
\
\    Exclusive Load/Store
\
\ =======================================

: lsx0    ( op regs -- )   rd, rd??iop  ls-sz30  [xn|sp{,#0}]  ;
: lsx1    ( op regs -- )   wm, lsx0  ;
: lsx2    ( op regs -- )   d=a, rd??iop  ls-sz30  [xn|sp{,#0}]  ;
: lsx3    ( op regs -- )   wm, lsx2  ;
: %lsx0   ( op regs -- )   <asm  lsx0  asm>  ;
: %lsx1   ( op regs -- )   <asm  lsx1  asm>  ;
: %lsx2   ( op regs -- )   <asm  lsx2  asm>  ;
: %lsx3   ( op regs -- )   <asm  lsx3  asm>  ;
: %cas    ( op regs -- )   <asm  m=d,  rd??iop  ls-sz30   [xn|sp{,#0}]  asm>  ;
: %stop   ( op regs -- )   <asm  rm,   rm?? iop  lsm-sz30  [xn|sp{,#0}]  asm>  ;

