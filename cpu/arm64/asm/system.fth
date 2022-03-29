\    System Instructions

\  The code below builds a system class instruction by putting
\  together the L, op0, op1, CRn, CRm, op2, and Rt bits.  These
\  bits are described in the ARMv8 instruction documentation in
\  a couple of different places.  The instruction encoding for
\  the arrangement of these bits are covered in the instruction
\  set encoding document.  The bindings for the text to bit
\  values are documented in ARMv8 Instruction Set Architecture
\  manual.


: system   ( op1 CRn CRm op2 rt -- )
   0xd508.0000 iop
   ( Rt )   0 5  ^^op
   ( op2 )  5 3  ^^op
   ( CRm )  8 4  ^^op
   ( CRn ) 12 4  ^^op
   ( op1 ) 16 3  ^^op
;
: ^sys   ( op CRm -- )   8 4 ^^op  iop  ;

: dbarrier-option ( -- CRm )
   <c 2dup upper $case
   " OSHLD"  $sub  c>  1      $endof
   " OSHST"  $sub  c>  2      $endof
   " OSH"    $sub  c>  3      $endof
   " NSHLD"  $sub  c>  5      $endof
   " NSHST"  $sub  c>  6      $endof
   " NSH"    $sub  c>  7      $endof
   " ISHLD"  $sub  c>  9      $endof
   " ISHST"  $sub  c>  10     $endof
   " ISH"    $sub  c>  11     $endof
   " LD"     $sub  c>  13     $endof
   " ST"     $sub  c>  14     $endof
   " SY"     $sub  c>  15     $endof
   c> " a data barrier option, e.g., OSHLD, ISHST, or SY" expecting
   $endcase
;

: dbarrier ( -- CRm )
   "#"?  if   >c  #uimm4
        else  dbarrier-option
        then
;

: ibarrier ( -- CRm )
   "#"?  if
      >c  #uimm4    \ User specified an immediate number
   else
      " SY" $match?  0=  if  2drop  then
      15               \ sy == default == 15
   then
;

: #clrex ( -- CRm )
   "#"?  if   >c  #uimm4  else  15  then
;

: ,xreg  ( -- xreg-number )
   "," reg  adt-xreg <> " an X register" ?expecting
;

: ,xreg?  ( -- xreg-number|xzr )
   ","? if  >c ,xreg  else  31  then
;

: ic-parse  ( --  op1 CRn CRm op2 )
   <c 2dup upper $case    \
   " IALLUIS" $sub  c>  0   7   1   0  $endof
   " IALLU"   $sub  c>  0   7   5   0  $endof
   " IVAU"    $sub  c>  3   7   5   1  $endof
   c> " a instruction cache opcode: IALLUIS, IALLU, or IVAU" expecting
   $endcase
;

: dc-parse  ( --    op1 CRn CRm op2 )
   <c 2dup upper $case
   " ZVA"       $sub  c>  3   7   4   1  $endof
   " IVAC"      $sub  c>  0   7   6   1  $endof
   " ISW"       $sub  c>  0   7   6   2  $endof
   " CVAC"      $sub  c>  3   7  10   1  $endof
   " CSW"       $sub  c>  0   7  10   2  $endof
   " CVAU"      $sub  c>  3   7  11   1  $endof
   " CIVAC"     $sub  c>  3   7  14   1  $endof
   " CISW"      $sub  c>  0   7  14   2  $endof
   " CVAP"      $sub  c>  3   7  12   1  $endof
   " CVADP"     $sub  c>  3   7  13   1  $endof
   c> " a data cache opcode" expecting
   $endcase
;

: at-parse  ( --    op1 CRn CRm op2 )
   <c 2dup upper $case
   " S1E1R"     $sub  c>  0   7   8   0  $endof
   " S1E2R"     $sub  c>  4   7   8   0  $endof
   " S1E3R"     $sub  c>  6   7   8   0  $endof
   " S1E1W"     $sub  c>  0   7   8   1  $endof
   " S1E2W"     $sub  c>  4   7   8   1  $endof
   " S1E3W"     $sub  c>  6   7   8   1  $endof
   " S1E0R"     $sub  c>  0   7   8   2  $endof
   " S1E0W"     $sub  c>  0   7   8   3  $endof
   " S12E1R"    $sub  c>  4   7   8   4  $endof
   " S12E1W"    $sub  c>  4   7   8   5  $endof
   " S12E0R"    $sub  c>  4   7   8   6  $endof
   " S12E0W"    $sub  c>  4   7   8   7  $endof
   " S1E1RP"    $sub  c>  0   7   9   0  $endof
   " S1E1WP"    $sub  c>  0   7   9   1  $endof
   c> " an address translation opcode" expecting
   $endcase
;

\ !!!WARNING!!!
\
\ The ordering of the following strings MATTERS (A LOT). The $sub only checks to
\ see if the latter $ is a substring of the former (input) $.
\
\ For Example:
\   If "VMALLE1" were to be listed before " VMALLE1OS" in the following
\   definition, and one were to assemble
\       TLBI VMALLE1OS, rx
\   it would be assembled as TLBI VMALLE1 -- *NOT* VMALLE1OS. This is because
\   VMALLE1 would be seen as a substring of the input VMALLE1OS. It would be
\   assembled as such and then this definition would exit.
: tlbi-parse  ( --    op1 CRn CRm op2 )
   <c 2dup upper $case
   " VMALLS12E1OS"  $sub  c>  4  8  1  6  $endof
   " VMALLS12E1IS"  $sub  c>  4  8  3  6  $endof
   " VMALLS12E1"    $sub  c>  4  8  7  6  $endof
   " VMALLE1OS"     $sub  c>  0  8  1  0  $endof
   " VMALLE1IS"     $sub  c>  0  8  3  0  $endof
   " VMALLE1"       $sub  c>  0  8  7  0  $endof
   " VALE3OS"       $sub  c>  6  8  1  5  $endof
   " VALE3IS"       $sub  c>  6  8  3  5  $endof
   " VALE3"         $sub  c>  6  8  7  5  $endof
   " VALE2OS"       $sub  c>  4  8  1  5  $endof
   " VALE2IS"       $sub  c>  4  8  3  5  $endof
   " VALE2"         $sub  c>  4  8  7  5  $endof
   " VALE1OS"       $sub  c>  0  8  1  5  $endof
   " VALE1IS"       $sub  c>  0  8  3  5  $endof
   " VALE1"         $sub  c>  0  8  7  5  $endof
   " VAE3OS"        $sub  c>  6  8  1  1  $endof
   " VAE3IS"        $sub  c>  6  8  3  1  $endof
   " VAE3"          $sub  c>  6  8  7  1  $endof
   " VAE2OS"        $sub  c>  4  8  1  1  $endof
   " VAE2IS"        $sub  c>  4  8  3  1  $endof
   " VAE2"          $sub  c>  4  8  7  1  $endof
   " VAE1OS"        $sub  c>  0  8  1  1  $endof
   " VAE1IS"        $sub  c>  0  8  3  1  $endof
   " VAE1"          $sub  c>  0  8  7  1  $endof
   " VAALE1OS"      $sub  c>  0  8  1  7  $endof
   " VAALE1IS"      $sub  c>  0  8  3  7  $endof
   " VAALE1"        $sub  c>  0  8  7  7  $endof
   " VAAE1OS"       $sub  c>  0  8  1  3  $endof
   " VAAE1IS"       $sub  c>  0  8  3  3  $endof
   " VAAE1"         $sub  c>  0  8  7  3  $endof
   " IPAS2LE1OS"    $sub  c>  4  8  4  4  $endof
   " IPAS2LE1IS"    $sub  c>  4  8  0  5  $endof
   " IPAS2LE1"      $sub  c>  4  8  4  5  $endof
   " IPAS2E1OS"     $sub  c>  4  8  4  0  $endof
   " IPAS2E1IS"     $sub  c>  4  8  0  1  $endof
   " IPAS2E1"       $sub  c>  4  8  4  1  $endof
   " ASIDE1OS"      $sub  c>  0  8  1  2  $endof
   " ASIDE1IS"      $sub  c>  0  8  3  2  $endof
   " ASIDE1"        $sub  c>  0  8  7  2  $endof
   " ALLE3OS"       $sub  c>  6  8  1  0  $endof
   " ALLE3IS"       $sub  c>  6  8  3  0  $endof
   " ALLE3"         $sub  c>  6  8  7  0  $endof
   " ALLE2OS"       $sub  c>  4  8  1  0  $endof
   " ALLE2IS"       $sub  c>  4  8  3  0  $endof
   " ALLE2"         $sub  c>  4  8  7  0  $endof
   " ALLE1OS"       $sub  c>  4  8  1  4  $endof
   " ALLE1IS"       $sub  c>  4  8  3  4  $endof
   " ALLE1"         $sub  c>  4  8  7  4  $endof
   " RVAALE1OS"     $sub  c>  0  8  5  7  $endof
   " RVAALE1IS"     $sub  c>  0  8  2  7  $endof
   " RVAALE1"       $sub  c>  0  8  6  7  $endof
   " RVALE1OS"      $sub  c>  0  8  5  5  $endof
   " RVALE1IS"      $sub  c>  0  8  2  5  $endof
   " RVALE1"        $sub  c>  0  8  6  5  $endof
   " RVAAE1OS"      $sub  c>  0  8  5  3  $endof
   " RVAAE1IS"      $sub  c>  0  8  2  3  $endof
   " RVAAE1"        $sub  c>  0  8  6  3  $endof
   " RVAE1OS"       $sub  c>  0  8  5  1  $endof
   " RVAE1IS"       $sub  c>  0  8  2  1  $endof
   " RVAE1"         $sub  c>  0  8  6  1  $endof
   " RIPAS2LE1OS"   $sub  c>  4  8  4  7  $endof
   " RIPAS2LE1IS"   $sub  c>  4  8  0  6  $endof
   " RIPAS2LE1"     $sub  c>  4  8  4  6  $endof
   " RIPAS2E1OS"    $sub  c>  4  8  4  3  $endof
   " RIPAS2E1IS"    $sub  c>  4  8  0  2  $endof
   " RIPAS2E1"      $sub  c>  4  8  4  2  $endof
   " RVALE2OS"      $sub  c>  4  8  5  5  $endof
   " RVALE2IS"      $sub  c>  4  8  2  5  $endof
   " RVALE2"        $sub  c>  4  8  6  5  $endof
   " RVAE2OS"       $sub  c>  4  8  5  1  $endof
   " RVAE2IS"       $sub  c>  4  8  2  1  $endof
   " RVAE2"         $sub  c>  4  8  6  1  $endof
   " RVALE3OS"      $sub  c>  6  8  5  5  $endof
   " RVALE3IS"      $sub  c>  6  8  2  5  $endof
   " RVALE3"        $sub  c>  6  8  6  5  $endof
   " RVAE3OS"       $sub  c>  6  8  5  1  $endof
   " RVAE3IS"       $sub  c>  6  8  2  1  $endof
   " RVAE3"         $sub  c>  6  8  6  1  $endof

   c> " a TLB invalidation opcode" expecting
   $endcase
;

: %hint   ( op -- )   <asm   iop  #uimm7  5 7 ^^op  asm>  ;

\ ARMv8.5
: rctx-parse   ( -- )
   <c 2dup upper c>  " RCTX" $= 0= " RCTX" expecting
;

\ =======================================
\
\    MSR/MRS Instructions
\
\ =======================================

\ Bring in an auto-generated function
defer $special-reg-encoding   ( $ -- instr-encoding f | t )
' drop is $special-reg-encoding

fload ${BP}/cpu/arm64/asm/msr-def.fth   \ generated

\ encode special registers as a 16-bit field
: ^special-reg-encoding  ( -- )
   <c scantodelim c> 2dup upper $special-reg-encoding  ( instr-encoding f | t )
   " a special register name" ?expecting   ( instr-encoding )
   5 16 ^^op
;

: $cpsrfield   ( $ -- op1 f | t)
   $case
   " PAN"            $of  0x0000.0080 false  $endof
   " SPSEL"          $of  0x0000.00a0 false  $endof
   " DAIFSET"        $of  0x0003.00c0 false  $endof
   " DAIFCLR"        $of  0x0003.00e0 false  $endof
   true
   $endcase   ( instr-encoding f | t )
;
: ^cpsrfield   ( $ -- )
   <c scantodelim c> 2dup upper $cpsrfield
   " a CPSR field name" ?expecting  ( op1 op2 )
   5 3 ^^op
   16 3 ^^op
;
: %mrs  ( op -- )
   <asm  iop   xd,  ^special-reg-encoding     asm>
;
: %msr  ( op -- )
   <asm  iop
   <c scantodelim c> 2dup upper
   2dup $special-reg-encoding if    ( $ )
      $cpsrfield  " a special register name" ?expecting   ( op1 )
      0x0000.401f or  iop  ","  #uimm4 8 4 ^^op
   else    ( $ instr-encoding )
      -rot 2drop
      0x0010.0000 iop  5 16 ^^op  ","  xd
   then  asm>
;

: C#,   ( -- n )   ascii C <c> upc <> " C" ?expecting   4 #uimm ","  ;
: %mrs#   ( op -- )
   <asm  iop
   xd,
   2 #uimm ","   19  2 ^^op
   3 #uimm ","   16  3 ^^op
   C#,           12  4 ^^op
   C#,            8  4 ^^op
   3 #uimm        5  3 ^^op
   asm>
;
: %msr#   ( -- )
   <asm  iop
   2 #uimm ","   19  2 ^^op
   3 #uimm ","   16  3 ^^op
   C#,           12  4 ^^op
   C#,            8  4 ^^op
   3 #uimm ","    5  3 ^^op
   xd
   asm>
;


\ =======================================
\
\    Exception Instructions
\
\ =======================================

: %exception   ( opc -- )   <asm         #uimm16  5 16 ^^op        iop asm>  ;
: %exception?  ( opc -- )   <asm  #? if  #uimm16  5 16 ^^op  then  iop asm>  ;

