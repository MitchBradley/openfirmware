purpose: ARM64 disassembler - prefix syntax
\ See license at end of file


\ =======================================
\
\     DISPLAYING REGISTER NAMES
\
\ =======================================

\
\ Register names can be printed in two different formats:
\
\  1) For Forth programmers.  In this case the register names are
\     symbolic when accessed as 64 bit registers and TOS is printed
\     symbolically as wtos when accessed as a 32 bit entity.
\     Additionally, the Forth SP is printed as SP.  However,
\     the CPU's SP is printed as XSP or WSP, depending on the
\     size (but WSP is most likely an indicator of a lurking bug).
\     
\  2) For System programmers.  In this case the register names are
\     "by the book."  The CPU's stack pointer is printed as SP (or
\     wSP if accessed as a 32bit item).  And, none of the Forth
\     virtual machine registers are printed symbolically in this
\     mode.
\
\ NOTE: The assembler is currently built to handle symbolic registers.
\

\ Register types
0 constant wreg
1 constant xreg
2 constant breg
3 constant hreg
4 constant sreg
5 constant dreg
6 constant qreg
7 constant vreg
8 constant preg
9 constant zreg
10 constant zareg

\ Forth register numbers:
22 constant lp
23 constant org
24 constant up
25 constant tos
26 constant rp
27 constant ip
28 constant sp

\ ARM register numbers
30 constant xlr
31 constant wzr
31 constant xzr
31 constant xsp
31 constant wsp

: u.  ( n -- )  push-decimal  (u.) type  pop-base ;
: s.  ( n -- )  push-decimal   (.) type  pop-base ;

: .wxdq ( type -- )  " wxbhsdqvpz" drop + 1 type ;
: .wx   ( type -- )  .wxdq ;
: .x?   ( type -- )  xreg = if ." x" then ;
: .w?   ( type -- )  wreg = if ." w" then ;

1 value use-symbolic-reg-names

\ NOTE: the CPU SP has been handled by this point.  See, for example, .[xn|sp or .rd|sp
: .system-regs ( type n -- )
   case
      xzr        of  .wx  ." zr"    endof
      swap .wxdq u.
      ( pacify endcase ) 0
   endcase
;

: .named-regs ( type n -- )
   over ( reg-type ) case
      wreg  of
         ." w" nip  case
            xzr  of  ." zr"   endof
            xlr  of  ." lr"   endof
            tos  of  ." tos"  endof
            u.
            ( pacify endcase ) 0
         endcase
      endof
      xreg  of
         nip  case
            xzr   of   ." xzr"    endof
            xlr   of   ." lr"    endof
            org   of   ." org"   endof
            up    of   ." up"    endof
            tos   of   ." tos"   endof
            rp    of   ." rp"    endof
            ip    of   ." ip"    endof
            sp    of   ." sp"    endof
            lp    of   ." lp"    endof
            ." x" u.
            ( pacify endcase ) 0
         endcase
      endof
      ( pacify endcase ) 0
   endcase
;

: .sp  ( reg-type -- )
   .w?
   use-symbolic-reg-names  if
       ." SSP"
   else
       ." SP"
   then
;   

: .lnamedreg ( n type -- )
   case
      wreg  of  wreg  endof
      xreg  of  xreg  endof
      ." ILLEGAL USE .lnamedreg" cr abort
   endcase

   swap
   use-symbolic-reg-names  if
      .named-regs
   else
      .system-regs
   then
;

: .lreg#   ( n type -- )
   ( type ) case 
      wreg  of  wreg .lnamedreg  endof
      xreg  of  xreg .lnamedreg  endof
      ( reg# type ) .wxdq u.
      ( pacify endcase ) 0
   endcase
;

\ -----------------------------------------------------------------
variable sf                 \ (S)IXTY (F)OUR BIT
variable instr-regtype

: sf@  ( -- n )  sf @ ;
: sf!
   instruction@ 31 rshift dup  sf !
   if xreg else wreg then instr-regtype !
;

: .r#  ( reg type -- )
   .lreg#
;

: rd  ( -- r )  0 5bits  ;
: rn  ( -- r )  5 5bits  ;
: ra  ( -- r )  10 5bits ;
: rm  ( -- r )  16 5bits ;
: rt  ( -- r )  rd  ;
: rt2 ( -- r )  ra  ;
: rs  ( -- r )  rm  ;

: .rd  ( -- )   rd instr-regtype @ .r#  ;
: .rn  ( -- )   rn instr-regtype @ .r#  ;
: .ra  ( -- )   ra instr-regtype @ .r#  ;
: .rm  ( -- )   rm instr-regtype @ .r#  ;
: .rt  ( -- )   .rd  ;
: .rt2 ( -- )   .ra  ;
: .rs  ( -- )   .rm  ;

: .wd  ( -- )   rd wreg .r#  ;
: .wn  ( -- )   rn wreg .r#  ;
: .wa  ( -- )   ra wreg .r#  ;
: .wm  ( -- )   rm wreg .r#  ;
: .wt  ( -- )   .wd  ;
: .wt2 ( -- )   .wa  ;
: .ws  ( -- )   .wm  ;

: .xd  ( -- )   rd xreg .r#  ;
: .xn  ( -- )   rn xreg .r#  ;
: .xa  ( -- )   ra xreg .r#  ;
: .xm  ( -- )   rm xreg .r#  ;
: .xt  ( -- )   .xd  ;
: .xt2 ( -- )   .xa  ;
: .xs  ( -- )   .xm  ;

: .xt?    rt 31 <>  if  ., .xt   then  ;

: .rd,  ( -- )   .rd .,  ;
: .rn,  ( -- )   .rn .,  ;
: .ra,  ( -- )   .ra .,  ;
: .rm,  ( -- )   .rm .,  ;
: .rt,  ( -- )   .rd,    ;
: .rt2, ( -- )   .ra,    ;
: .rs,  ( -- )   .rm,    ;

: .rs,?   rs 31 <>  if  .ws .,  then  ;

: .wd,  ( -- )   .wd .,  ;
: .wn,  ( -- )   .wn .,  ;
: .wa,  ( -- )   .wa .,  ;
: .wm,  ( -- )   .wm .,  ;
: .wt,  ( -- )   .wd,    ;
: .wt2, ( -- )   .wa,    ;
: .ws,  ( -- )   .wm,    ;

: .xd,  ( -- )   .xd .,  ;
: .xn,  ( -- )   .xn .,  ;
: .xa,  ( -- )   .xa .,  ;
: .xm,  ( -- )   .xm .,  ;
: .xt,  ( -- )   .xd,    ;
: .xt2, ( -- )   .xa,    ;
: .xs,  ( -- )   .xm,    ;


: .Bd   ( -- )   rd breg .r#  ;
: .Bd,  ( -- )  .Bd .,  ;
: .Bn   ( -- )   rn breg .r#  ;
: .Bn,  ( -- )  .Bn .,  ;
: .Bm   ( -- )   rm breg .r#  ;
: .Bm,  ( -- )  .Bm .,  ;
: .Ba   ( -- )   ra breg .r#  ;
: .Ba,  ( -- )  .Ba .,  ;

: .Hd   ( -- )   rd hreg .r#  ;
: .Hd,  ( -- )  .Hd .,  ;
: .Hn   ( -- )   rn hreg .r#  ;
: .Hn,  ( -- )  .Hn .,  ;
: .Hm   ( -- )   rm hreg .r#  ;
: .Hm,  ( -- )  .Hm .,  ;
: .Ha   ( -- )   ra hreg .r#  ;
: .Ha,  ( -- )  .Ha .,  ;

: .Sd   ( -- )   rd sreg .r#  ;
: .Sd,  ( -- )  .Sd .,  ;
: .Sn   ( -- )   rn sreg .r#  ;
: .Sn,  ( -- )  .Sn .,  ;
: .Sm   ( -- )   rm sreg .r#  ;
: .Sm,  ( -- )  .Sm .,  ;
: .Sa   ( -- )   ra sreg .r#  ;
: .Sa,  ( -- )  .Sa .,  ;

: .Dd   ( -- )   rd dreg .r#  ;
: .Dd,  ( -- )  .Dd .,  ;
: .Dn   ( -- )   rn dreg .r#  ;
: .Dn,  ( -- )  .Dn .,  ;
: .Dm   ( -- )   rm dreg .r#  ;
: .Dm,  ( -- )  .Dm .,  ;
: .Da   ( -- )   ra dreg .r#  ;
: .Da,  ( -- )  .Da .,  ;

: .Qd   ( -- )   rd Qreg .r#  ;
: .Qd,  ( -- )  .Qd .,  ;
: .Qn   ( -- )   rn Qreg .r#  ;
: .Qn,  ( -- )  .Qn .,  ;
: .Qm   ( -- )   rm Qreg .r#  ;
: .Qm,  ( -- )  .Qm .,  ;
: .Qa   ( -- )   ra Qreg .r#  ;
: .Qa,  ( -- )  .Qa .,  ;

: .Vd   ( -- )   rd Vreg .r#  ;
: .Vd,  ( -- )  .Vd .,  ;
: .Vn   ( -- )   rn Vreg .r#  ;
: .Vn,  ( -- )  .Vn .,  ;
: .Vm   ( -- )   rm Vreg .r#  ;
: .Vm,  ( -- )  .Vm .,  ;
: .Va   ( -- )   ra Vreg .r#  ;
: .Va,  ( -- )  .Va .,  ;

: rd=sp?  ( -- f )  rd XSP =  ;
: rn=sp?  ( -- f )  rn XSP =  ;
: rm=sp?  ( -- f )  rm XSP =  ;

: .[xn|sp  ( -- )  .[ rn=sp?  if  xreg .sp  else  rn xreg .r#  then  ;

: .size-sp ( -- )  instr-regtype @ .sp  ;
: .rd|sp ( -- )  rd=sp?  if  .size-sp  else  .rd  then  ;
: .rn|sp ( -- )  rn=sp?  if  .size-sp  else  .rn  then  ;
: .rm|sp ( -- )  rm=sp?  if  .size-sp  else  .rm  then  ;

: .rd|sp, ( -- )  .rd|sp .,  ;
: .rn|sp, ( -- )  .rn|sp .,  ;
: .rm|sp, ( -- )  .rm|sp .,  ;



\ =======================================
\
\       {N,immr,imms} -> IMMEDIATE
\
\ =======================================

\ {n,immr,imms}>immed

\ Ugh.  This word takes a triple {n, immr, imms} and creates an immediate
\ value from it.  The logic for this is non-trivial.  It can be found in
\ any Oban (ARM64) instruction manual under, for example, the ORR immediate
\ instruction.

\ The basic algorithm below is:
\ 1. Ensure that if N is set that datasize is 64.
\ 2. Get the "length" of {N:~immr}.
\ 3. Ensure length is >= 1.
\ 4. Extract S from imms<len-1:0>
\ 5. Extract R from immr<len-1:0>
\ 6. Determine size = 1 << len
\ 7. Ensure S <> size -1
\ 8. Create a double pattern of 0 and 1 bits by using dmask.
\ 9. 

: {n,immr,imms}>immed   ( datasize n immr imms -- d )
   >r >r 2dup if
      32 = if  ." INVALID datasize = 32 and N = 1" r> r> 4drop 0 0 exit then 
   else
      drop
   then   r> r>                                           ( datasize n immr imms )
   dup 6 mask xor 4rot 6 lshift or highestsetbit          ( datasize immr imms len )
   dup 1 < if  ." INVALID len < 1" 4drop 0 0 exit  then   ( datasize immr imms len )
   >r   r@ mask land    ( datasize immr S )
   swap r@ mask land    ( datasize S R )
   swap dup             ( datasize R S S )
   1 r@ lshift          ( datasize R S S size )
   dup >r               ( r: len size )
   1- = if              ( datasize R S )
      ." INVALID S == size - 1"   2r> 2drop  3drop 0 0 exit 
   then                 ( datasize R S )  ( r: len size )
   1+ dmask rot         ( datasize dmask R )
   r@ swap d-rotate rot ( dpatt datasize )
   r> swap              ( dpatt size datasize)
   r> rshift            ( dpatt size datasize>>len )
   d-replicate
;



0 [if]
\
\ Determine if an {n,immr,imms} triplet is valid
\
: {n,immr,imms}? ( datasize n immr imms -- t | f )
   >r >r 2dup if 32 = if 2drop r> r> 2drop false exit then else drop then
   r> r>  dup  6 mask xor  4rot 6 lshift or  highestsetbit  ( len )
   ( len ) dup 1 < if  2drop 2drop false exit  then
   ( len ) >r
   r@ mask land ( S )
   swap r@ mask land ( R )
   swap dup ( R S S )
   1 r@ lshift ( size ) dup >r
   ( S size ) 1- = if r> r> 2drop 2drop drop false exit then
   r> r> 2drop 2drop drop true
;

0 value datasize
0 value N
0 value immr
0 value imms

: test-{n,immr,imms}?
  2 0 do 32 i << is datasize
  2 0 do i is N
  64 0 do i is IMMR
  64 0 do i is IMMS
     datasize dup . N dup . immr dup . imms dup .
     {n,immr,imms}?  drop depth 0 <> if ." BAD: " .s else ." OK" then cr
  loop
  loop
  loop
  loop
;
[then]

\ SIMD Registers

: .".2s" ." .2s" ;
: .Dd.2s   ( -- )   .Dd .".2s" ;
: .Dd.2s,  ( -- )   .Dd.2s .,  ;
: .Dn.2s   ( -- )   .Dn .".2s" ;
: .Dn.2s,  ( -- )   .Dn.2s .,  ;
: .Dm.2s   ( -- )   .Dm .".2s" ;
: .Dm.2s,  ( -- )   .Dm.2s .,  ;


: .".8b" ." .8b" ;
: .Dd.8b   ( -- )   .Dd .".8b" ;
: .Dd.8b,  ( -- )   .Dd.8b .,  ;
: .Dn.8b   ( -- )   .Dn .".8b" ;
: .Dn.8b,  ( -- )   .Dn.8b .,  ;
: .Dm.8b   ( -- )   .Dm .".8b" ;
: .Dm.8b,  ( -- )   .Dm.8b .,  ;

: .".2h" ." .2h" ;
: .".4h" ." .4h" ;
: .Dd.4h   ( -- )   .Dd .".4h" ;
: .Dd.4h,  ( -- )   .Dd.4h .,  ;
: .Dn.4h   ( -- )   .Dn .".4h" ;
: .Dn.4h,  ( -- )   .Dn.4h .,  ;
: .Dm.4h   ( -- )   .Dm .".4h" ;
: .Dm.4h,  ( -- )   .Dm.4h .,  ;

: .".2d" ." .2d" ;
: .Qd.2d   ( -- )   .Qd .".2d" ;
: .Qd.2d,  ( -- )   .Qd.2d .,  ;
: .Qn.2d   ( -- )   .Qn .".2d" ;
: .Qn.2d,  ( -- )   .Qn.2d .,  ;
: .Qm.2d   ( -- )   .Qm .".2d" ;
: .Qm.2d,  ( -- )   .Qm.2d .,  ;


: .".4s" ." .4s" ;
: .Qd.4s   ( -- )   .Qd .".4s" ;
: .Qd.4s,  ( -- )   .Qd.4s .,  ;
: .Qn.4s   ( -- )   .Qn .".4s" ;
: .Qn.4s,  ( -- )   .Qn.4s .,  ;
: .Qm.4s   ( -- )   .Qm .".4s" ;
: .Qm.4s,  ( -- )   .Qm.4s .,  ;
 

: .".16b" ." .16b" ;
: .Qd.16b   ( -- )   .Qd .".16b" ;
: .Qd.16b,  ( -- )   .Qd.16b .,  ;
: .Qn.16b   ( -- )   .Qn .".16b" ;
: .Qn.16b,  ( -- )   .Qn.16b .,  ;
: .Qm.16b   ( -- )   .Qm .".16b" ;
: .Qm.16b,  ( -- )   .Qm.16b .,  ;


: .".8h" ." .8h" ;
: .Qd.8h   ( -- )   .Qd .".8h" ;
: .Qd.8h,  ( -- )   .Qd.8h .,  ;
: .Qn.8h   ( -- )   .Qn .".8h" ;
: .Qn.8h,  ( -- )   .Qn.8h .,  ;
: .Qm.8h   ( -- )   .Qm .".8h" ;
: .Qm.8h,  ( -- )   .Qm.8h .,  ;


: .Vd.2s   ( -- )   .Vd .".2s" ;
: .Vd.2s,  ( -- )   .Vd.2s .,  ;
: .Vn.2s   ( -- )   .Vn .".2s" ;
: .Vn.2s,  ( -- )   .Vn.2s .,  ;
: .Vm.2s   ( -- )   .Vm .".2s" ;
: .Vm.2s,  ( -- )   .Vm.2s .,  ;

: .Vd.8b   ( -- )   .Vd .".8b" ;
: .Vd.8b,  ( -- )   .Vd.8b .,  ;
: .Vn.8b   ( -- )   .Vn .".8b" ;
: .Vn.8b,  ( -- )   .Vn.8b .,  ;
: .Vm.8b   ( -- )   .Vm .".8b" ;
: .Vm.8b,  ( -- )   .Vm.8b .,  ;

: .Vd.4h   ( -- )   .Vd .".4h" ;
: .Vd.4h,  ( -- )   .Vd.4h .,  ;
: .Vn.4h   ( -- )   .Vn .".4h" ;
: .Vn.4h,  ( -- )   .Vn.4h .,  ;
: .Vm.4h   ( -- )   .Vm .".4h" ;
: .Vm.4h,  ( -- )   .Vm.4h .,  ;

: .Vm.2h   ( -- )   .Vm .".2h" ;
: .Vm.2h,  ( -- )   .Vm.2h .,  ;



: .Vd.2d   ( -- )   .Vd .".2d" ;
: .Vd.2d,  ( -- )   .Vd.2d .,  ;
: .Vn.2d   ( -- )   .Vn .".2d" ;
: .Vn.2d,  ( -- )   .Vn.2d .,  ;
: .Vm.2d   ( -- )   .Vm .".2d" ;
: .Vm.2d,  ( -- )   .Vm.2d .,  ;

: .Vd.4s   ( -- )   .Vd .".4s" ;
: .Vd.4s,  ( -- )   .Vd.4s .,  ;
: .Vn.4s   ( -- )   .Vn .".4s" ;
: .Vn.4s,  ( -- )   .Vn.4s .,  ;
: .Vm.4s   ( -- )   .Vm .".4s" ;
: .Vm.4s,  ( -- )   .Vm.4s .,  ;

: .Vd.16b   ( -- )   .Vd .".16b" ;
: .Vd.16b,  ( -- )   .Vd.16b .,  ;
: .Vn.16b   ( -- )   .Vn .".16b" ;
: .Vn.16b,  ( -- )   .Vn.16b .,  ;
: .Vm.16b   ( -- )   .Vm .".16b" ;
: .Vm.16b,  ( -- )   .Vm.16b .,  ;
: .Va.16b   ( -- )   .Va .".16b" ;
: .Va.16b,  ( -- )   .Va.16b .,  ;

: .Vd.8h   ( -- )   .Vd .".8h" ;
: .Vd.8h,  ( -- )   .Vd.8h .,  ;
: .Vn.8h   ( -- )   .Vn .".8h" ;
: .Vn.8h,  ( -- )   .Vn.8h .,  ;
: .Vm.8h   ( -- )   .Vm .".8h" ;
: .Vm.8h,  ( -- )   .Vm.8h .,  ;

: .".1d" ." .1d" ;
: .Vn.1d   ( -- )   .Vn .".1d" ;
: .Vn.1d,  ( -- )   .Vn.1d .,  ;
: .Vm.1d   ( -- )   .Vm .".1d" ;
: .Vm.1d,  ( -- )   .Vm.1d .,  ;

: .".1q" ." .1q" ;
: .Vd.1q   ( -- )   .Vd .".1q" ;
: .Vd.1q,  ( -- )   .Vd.1q .,  ;

\ for indexed registers
: .Vd.b   ( -- )   .Vd ." .b" ;
: .Vd.h   ( -- )   .Vd ." .h" ;
: .Vd.s   ( -- )   .Vd ." .s" ;
: .Vd.d   ( -- )   .Vd ." .d" ;
: .Vn.b   ( -- )   .Vn ." .b" ;
: .Vn.h   ( -- )   .Vn ." .h" ;
: .Vn.s   ( -- )   .Vn ." .s" ;
: .Vn.d   ( -- )   .Vn ." .d" ;
: .Vm.b   ( -- )   .Vm ." .b" ;
: .Vm.h   ( -- )   .Vm ." .h" ;
: .Vm.s   ( -- )   .Vm ." .s" ;
: .Vm.d   ( -- )   .Vm ." .d" ;
: .Vm4.h  ( -- )   16 4bits  Vreg .r#  ." .h" ;


