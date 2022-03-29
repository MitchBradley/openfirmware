\ disassembler
\ SVE register combinations

\ there are about 80 groups of SVE instructions, and most of them
\ use registers in their very own way

: .xd|sp    xreg instr-regtype !  .rd|sp  ;
: .xd|sp,   .xd|sp .,  ;
: .xn|sp    xreg instr-regtype !  .rd|sp  ;
: .xn|sp,   .xn|sp .,  ;
: .xm|sp    xreg instr-regtype !  .rm|sp  ;
: .xm|sp,   .xm|sp .,  ;

: sf>r   ( sf -- )   if xreg else wreg then instr-regtype !  ;
: s.rn      ( sf -- )   sf>r .rn  ;
: s.rn|sp   ( sf -- )   sf>r .rn|sp  ;
: s.rm      ( sf -- )   sf>r .rm  ;
: s.rn,     ( sf -- )   s.rn .,  ;

: sz>r   ( -- )   sz 3 = sf>r  ;
: .szrn   ( -- )   sz>r .rn|sp  ;
: .szrm   ( -- )   sz>r .rm  ;


\ XXX note need .wxn  ( size -- )

\ XXX tsz tsz2 possibly bogus
: tsz   ( -- sz )
   sz dup 2 and if  drop 3 exit  then   ( tszh )
   1 and if  2 exit  then   ( )
   8 2bits dup 2 and if  drop 1 exit  then   ( tszl )
   1 and if  0 exit  then
   ." invalid tsz " 0
;
: tsz2   ( -- sz )
   sz dup 2 and if  drop 3 exit  then   ( tszh )
   1 and if  2 exit  then   ( )
   19 2bits dup 2 and if  drop 1 exit  then   ( tszl )
   1 and if  0 exit  then
   ." invalid tsz " 0
;

: tsz-imm3   ( tszimm -- n sz )
   dup 0x40 and if   0x3f and  3  exit  then
   dup 0x20 and if   0x1f and  2  exit  then
   dup 0x10 and if   0x0f and  1  exit  then
   dup 0x08 and if   0x07 and  0  exit  then
   invalid-regs ( tszimm ) drop 0 0
;
: tsz-imm3-hi   ( -- n sz )   22 2bits 5 <<  16 5bits or  tsz-imm3  ;
: tsz-imm3-lo   ( -- n sz )   22 2bits 5 <<   5 5bits or  tsz-imm3  ;



: .dimm   ( d -- )
   2dup   .# push-decimal dis-ud. pop-base   rem-col push-hex ." h# " dis-ud. pop-base
;
: decode13   ( sz -- d )
   8 swap <<
   17 1bit 11 6bits 5 6bits {n,immr,imms}>immed
;
: decode-sz   ( -- sz )
   17 1bit    if  3 exit  then
   10 1bit 0= if  2 exit  then
   9 1bit 0=  if  1 exit  then
   0
;

: .x   ( sz -- )
   case
      0 of   ." .b"   endof
      1 of   ." .h"   endof
      2 of   ." .s"   endof
      3 of   ." .d"   endof
   endcase
;

: .pd.x   ( sz -- )
   case
      0 of   .Pd.b   endof
      1 of   .Pd.h   endof
      2 of   .Pd.s   endof
      3 of   .Pd.d   endof
   endcase
;
: .pd.x,   ( sz -- )  .pd.x  .,  ;
: .pn.x   ( sz -- )
   case
      0 of   .Pn.b   endof
      1 of   .Pn.h   endof
      2 of   .Pn.s   endof
      3 of   .Pn.d   endof
   endcase
;
: .pxx   ( sz -- )   .pd.x, .xn, .xm  ;
: .prr   ( sz sf -- )   swap .pd.x, dup s.rn, s.rm  ;


: .zd.x   ( sz -- )
   case
      0 of   .Zd.b   endof
      1 of   .Zd.h   endof
      2 of   .Zd.s   endof
      3 of   .Zd.d   endof
   endcase
;
: .zd.x,   ( sz -- )   .zd.x  .,  ;

: .zn.x   ( sz -- )
   case
      0 of   .Zn.b   endof
      1 of   .Zn.h   endof
      2 of   .Zn.s   endof
      3 of   .Zn.d   endof
   endcase
;
: .zn.x,   ( sz -- )   .zn.x  .,  ;

: .zm.x   ( sz -- )
   case
      0 of   .Zm.b   endof
      1 of   .Zm.h   endof
      2 of   .Zm.s   endof
      3 of   .Zm.d   endof
   endcase
;
: .zm.x,   ( sz -- )   .zm.x  .,  ;

: .zdimm   ( -- )   decode-sz dup .zd.x, decode13 .dimm  ;


: .pp   ( sp -- )
   case
      0 of   .Pd.b, .Pn.b   endof
      1 of   .Pd.h, .Pn.h   endof
      2 of   .Pd.s, .Pn.s   endof
      3 of   .Pd.d, .Pn.d   endof
   endcase
;
: .zz   ( sz -- )
   case
      0 of   .Zd.b, .Zn.b   endof
      1 of   .Zd.h, .Zn.h   endof
      2 of   .Zd.s, .Zn.s   endof
      3 of   .Zd.d, .Zn.d   endof
   endcase
;
: .zz,   ( sz -- )
   case
      0 of   .Zd.b, .Zn.b,   endof
      1 of   .Zd.h, .Zn.h,   endof
      2 of   .Zd.s, .Zn.s,   endof
      3 of   .Zd.d, .Zn.d,   endof
   endcase
;
: .z>z   ( sz -- )
   case
      1 of   .Zd.h, .Zn.b   endof
      2 of   .Zd.s, .Zn.h   endof
      3 of   .Zd.d, .Zn.s   endof
   endcase
;
: .z>zz   ( sz -- )
   case
      2 of   .Zd.s, .Zn.h, .Zm.h   endof
      3 of   .Zd.d, .Zn.s, .Zm.s   endof
   endcase
;
: .z>>zz   ( sz -- )
   case
      2 of   .Zd.s, .Zn.b, .Zm.b   endof
      3 of   .Zd.d, .Zn.h, .Zm.h   endof
   endcase
;
: .zzc   ( n sz-- )    .zz, .imm  ;
: .zzw   ( sz -- )     .zz, .Zm.d  ;

: .zrn   ( -- )   sz .zd.x,  .szrn  ;
: .zrm   ( -- )   sz .zd.x,  .szrm  ;
: .zs   ( -- )
   sz case
      0 of   .Zd.b, .Bn   endof
      1 of   .Zd.h, .Hn   endof
      2 of   .Zd.s, .Sn   endof
      3 of   .Zd.d, .Dn   endof
   endcase
;

: .zzz   ( sz -- )
   case
      0 of   .Zd.b, .Zn.b, .Zm.b   endof
      1 of   .Zd.h, .Zn.h, .Zm.h   endof
      2 of   .Zd.s, .Zn.s, .Zm.s   endof
      3 of   .Zd.d, .Zn.d, .Zm.d   endof
      4 of   .Zd.q, .Zn.q, .Zm.q   endof
   endcase
;
: .ppp   ( sp -- )
   case
      0 of   .Pd.b, .Pn.b, .Pm.b   endof
      1 of   .Pd.h, .Pn.h, .Pm.h   endof
      2 of   .Pd.s, .Pn.s, .Pm.s   endof
      3 of   .Pd.d, .Pn.d, .Pm.d   endof
   endcase
;
: .zpz   ( sz -- )
   case
      0 of   .Zd.b, .p10m, .Zn.b   endof
      1 of   .Zd.h, .p10m, .Zn.h   endof
      2 of   .Zd.s, .p10m, .Zn.s   endof
      3 of   .Zd.d, .p10m, .Zn.d   endof
      4 of   .Zd.q, .p10m, .Zn.q   endof
   endcase
;
: .zpzz   ( sz -- )
   case
      0 of   .Zd.b, .p10z, .Zn.b, .Zm.b   endof
      1 of   .Zd.h, .p10z, .Zn.h, .Zm.h   endof
      2 of   .Zd.s, .p10z, .Zn.s, .Zm.s   endof
      3 of   .Zd.d, .p10z, .Zn.d, .Zm.d   endof
   endcase
;
: .zpzz2   ( sz -- )
   case
      0 of   .Zd.b, .p10, .Zn.b, .Zm.b   endof
      1 of   .Zd.h, .p10, .Zn.h, .Zm.h   endof
      2 of   .Zd.s, .p10, .Zn.s, .Zm.s   endof
      3 of   .Zd.d, .p10, .Zn.d, .Zm.d   endof
   endcase
;
: .zmzz   ( sz -- )
   case
      0 of   .Zd.b, .p10m, .Zn.b, .Zm.b   endof
      1 of   .Zd.h, .p10m, .Zn.h, .Zm.h   endof
      2 of   .Zd.s, .p10m, .Zn.s, .Zm.s   endof
      3 of   .Zd.d, .p10m, .Zn.d, .Zm.d   endof
   endcase
;
: .zps   ( sz -- )
   case
      0 of   .Zd.b, .p10m, .Bn   endof
      1 of   .Zd.h, .p10m, .Hn   endof
      2 of   .Zd.s, .p10m, .Sn   endof
      3 of   .Zd.d, .p10m, .Dn   endof
   endcase
;
: .zpr   ( sz -- )
   case
      0 of   .Zd.b, .p10m, .Wn   endof
      1 of   .Zd.h, .p10m, .Wn   endof
      2 of   .Zd.s, .p10m, .Wn   endof
      3 of   .Zd.d, .p10m, .Xn   endof
   endcase
;
\ scalar, predicate, z-vector
: .sgz   ( sz -- )
   case
      0 of   .Bd, .p10, .Zn.b   endof
      1 of   .Hd, .p10, .Zn.h   endof
      2 of   .Sd, .p10, .Zn.s   endof
      3 of   .Dd, .p10, .Zn.d   endof
   endcase
;
: .spz   ( sz -- )
   case
      0 of   .Bd, .p10, .Zn.b   endof
      1 of   .Hd, .p10, .Zn.h   endof
      2 of   .Sd, .p10, .Zn.s   endof
      3 of   .Dd, .p10, .Zn.d   endof
   endcase
;
: .rpz   ( sz -- )
   case
      0 of   .Wd, .p10, .Zn.b   endof
      1 of   .Wd, .p10, .Zn.h   endof
      2 of   .Wd, .p10, .Zn.s   endof
      3 of   .Xd, .p10, .Zn.d   endof
   endcase
;
: .spez   ( sz -- )
   case
      0 of   .Bd, .p10, .Bd, .Zn.b   endof
      1 of   .Hd, .p10, .Hd, .Zn.h   endof
      2 of   .Sd, .p10, .Sd, .Zn.s   endof
      3 of   .Dd, .p10, .Dd, .Zn.d   endof
   endcase
;
: .rpez   ( sz -- )
   case
      0 of   .Wd, .p10m, .Wd, .Zn.b   endof
      1 of   .Wd, .p10m, .Wd, .Zn.h   endof
      2 of   .Wd, .p10m, .Wd, .Zn.s   endof
      3 of   .Xd, .p10m, .Xd, .Zn.d   endof
   endcase
;

\ sometimes Zd is both a dest and a src, and ARM alls it Zdn
\ and sometimes you have to type it twice
\ e for explicit

\ Zdn, Zdn again
: .ze   ( sz -- )
   case
      0 of   .Zd.b, .Zd.b   endof
      1 of   .Zd.h, .Zd.h   endof
      2 of   .Zd.s, .Zd.s   endof
      3 of   .Zd.d, .Zd.d   endof
   endcase
;
: .ze,   ( sz -- )   .ze .,  ;
: .ze#    ( n sz -- )   .ze, .imm  ;
: .zeu#   ( n sz -- )   .ze, .uimm  ;

: .zez   ( sz -- )
   case
      0 of   .Zd.b, .Zd.b, .Zn.b   endof
      1 of   .Zd.h, .Zd.h, .Zn.h   endof
      2 of   .Zd.s, .Zd.s, .Zn.s   endof
      3 of   .Zd.d, .Zd.d, .Zn.d   endof
   endcase
;

\ Zdn, Zdn again, Zm, #const
: .zezc   ( n sz -- )   dup .ze, .Zn.x, .imm ;

\ pointless register swapping
: .zdemn   ( sz -- )
   case
      0 of   .Zd.b, .Zd.b, .Zm.b, .Zn.b  endof
      1 of   .Zd.h, .Zd.h, .Zm.h, .Zn.h  endof
      2 of   .Zd.s, .Zd.s, .Zm.s, .Zn.s  endof
      3 of   .Zd.d, .Zd.d, .Zm.d, .Zn.d  endof
   endcase
;

\ Zdn, predicate, Zdn again, 
: .zpe,   ( n sz -- )
   case
      0 of   .Zd.b, .p10m, .Zd.b,    endof
      1 of   .Zd.h, .p10m, .Zd.h,    endof
      2 of   .Zd.s, .p10m, .Zd.s,    endof
      3 of   .Zd.d, .p10m, .Zd.d,    endof
   endcase
;
\ Zdn, predicate, Zdn again, constant
: .zpec   ( n sz -- )   .zpe,  .imm  ;
: .fimm1/0     ( n -- )   if   ." #1.0"  else  ." #0.0"  then  ;
: .fimm1/0.5   ( n -- )   if   ." #1.0"  else  ." #0.5"  then  ;
: .fimm2/0.5   ( n -- )   if   ." #2.0"  else  ." #0.5"  then  ;

\ Zdn, predicate, Zdn again, wide Zm
: .zpew   ( sz -- )
   case
      0 of   .Zd.b, .p10m, .Zd.b, .Zn.d   endof
      1 of   .Zd.h, .p10m, .Zd.h, .Zn.d   endof
      2 of   .Zd.s, .p10m, .Zd.s, .Zn.d   endof
      3 of   .Zd.d, .p10m, .Zd.d, .Zn.d   endof
   endcase
;

: .zpez   ( sz -- )
   case
      0 of   .Zd.b, .p10m, .Zd.b, .Zn.b   endof
      1 of   .Zd.h, .p10m, .Zd.h, .Zn.h   endof
      2 of   .Zd.s, .p10m, .Zd.s, .Zn.s   endof
      3 of   .Zd.d, .p10m, .Zd.d, .Zn.d   endof
   endcase
;

: .pgpe   ( -- )   .Pd.b, .P10g ." /z, " .Pn.b, .Pd.b  ;
: .pgpp   ( -- )   .Pd.b, .P10g ." /z, " .Pn.b, .Pm.b  ;
: .pgp    ( m? -- )
   .Pd.b, .P10g  if  ." /m, "  else  ." /z, " then  .Pn.b
;

: .zdpnm   ( sz -- )
   case
      0 of   .Zd.b, .p10m, .Zn.b, .Zm.b   endof
      1 of   .Zd.h, .p10m, .Zn.h, .Zm.h   endof
      2 of   .Zd.s, .p10m, .Zn.s, .Zm.s   endof
      3 of   .Zd.d, .p10m, .Zn.d, .Zm.d   endof
   endcase
;
\ more pointless register swapping
: .zdpmn   ( sz -- )
   case
      0 of   .Zd.b, .p10m, .Zm.b, .Zn.b   endof
      1 of   .Zd.h, .p10m, .Zm.h, .Zn.h   endof
      2 of   .Zd.s, .p10m, .Zm.s, .Zn.s   endof
      3 of   .Zd.d, .p10m, .Zm.d, .Zn.d   endof
   endcase
;

: .Zn2  ( -- )   rn 1+ 0x1f and  Zreg .r#  ;
: .zp{zz}   ( sz -- )
   case
      0 of   .Zd.b, .p10, .{ .Zn.b, .Zn2 0 .x .}  endof
      1 of   .Zd.h, .p10, .{ .Zn.h, .Zn2 1 .x .}  endof
      2 of   .Zd.s, .p10, .{ .Zn.s, .Zn2 2 .x .}  endof
      3 of   .Zd.d, .p10, .{ .Zn.d, .Zn2 3 .x .}  endof
   endcase
;
: .z[zz]   ( sz -- )
   if    .Zd.d, .[ .Zn.d, .Zm.d
   else  .Zd.s, .[ .Zn.s, .Zm.s
   then
   10 2bits dup if  ." , lsl " .imm  else  drop  then  .] 
;

: dup-index   ( #bits -- n )
   22 2bits 5 <<  16 5bits or
   7 rot - >>
;

: tsz.z[]   ( -- )
   16 5bits case
      1x0" xxxx1" af   .Zd.b, .Zn.b  6 dup-index .index   endaf
      1x0" xxx10" af   .Zd.h, .Zn.h  5 dup-index .index   endaf
      1x0" xx100" af   .Zd.s, .Zn.s  4 dup-index .index   endaf
      1x0" x1000" af   .Zd.d, .Zn.d  3 dup-index .index   endaf
      1x0" 10000" af   .Zd.q, .Zn.q  2 dup-index .index   endaf
   endcase
;

: .zpat   ( -- )
   5 5bits case
      0 of   ." pow2"  endof
      1 of   ." VL1"   endof
      2 of   ." VL2"   endof
      3 of   ." VL3"   endof
      4 of   ." VL4"   endof
      5 of   ." VL5"   endof
      6 of   ." VL6"   endof
      7 of   ." VL7"   endof
      8 of   ." VL8"   endof
      9 of   ." VL16"  endof
      10 of  ." VL32"  endof
      11 of  ." VL64"  endof
      12 of  ." VL128" endof
      13 of  ." VL256" endof
      29 of  ." MUL4"  endof
      30 of  ." MUL3"  endof
      31 of  ." ALL"   endof
      .uimm dup
   endcase
;
: .zpat#   ( -- )   .zpat  16 4bits ?dup if  ." , MUL " 1+ .imm  then  ;


: zimm9   ( -- n )   16 6bits 3 << 10 3bits or  ;
: zimm8   ( -- n )   16 5bits 3 << 10 3bits or  ;
: .zuimm8   ( -- )   16 5bits 3 << 10 3bits or .imm  ;

: .ppzz   ( sz -- )
   case
      0 of   .Pd.b, .p10z, .Zn.b, .Zm.b   endof
      1 of   .Pd.h, .p10z, .Zn.h, .Zm.h   endof
      2 of   .Pd.s, .p10z, .Zn.s, .Zm.s   endof
      3 of   .Pd.d, .p10z, .Zn.d, .Zm.d   endof
   endcase
;
: .ppzw   ( sz -- )
   case
      0 of   .Pd.b, .p10z, .Zn.b, .Zm.d   endof
      1 of   .Pd.h, .p10z, .Zn.h, .Zm.d   endof
      2 of   .Pd.s, .p10z, .Zn.s, .Zm.d   endof
      3 of   .Pd.d, .p10z, .Zn.d, .Zm.d   endof
   endcase
;
: .ppz,   ( sz -- )
   case
      0 of   .Pd.b, .p10z, .Zn.b,   endof
      1 of   .Pd.h, .p10z, .Zn.h,   endof
      2 of   .Pd.s, .p10z, .Zn.s,   endof
      3 of   .Pd.d, .p10z, .Zn.d,   endof
   endcase
;

: .zp   ( sz -- )
   case
      1 of   .Zd.h, .Pn.h   endof
      2 of   .Zd.s, .Pn.s   endof
      3 of   .Zd.d, .Pn.d   endof
      invalid-regs
   endcase
;

: .zzz-flong   ( sz -- )
   if    .Zd.d, .Zn.h, .Zm.h
   else  .Zd.s, .Zn.b, .Zm.b
   then
;
: .square   ( n )   90 * .uimm  ;
: sve-cdot   ( -- )
   ." cdot"   op-col  22 1bit .zzz-flong ., 10 2bits .square
;
: .zzz-long   ( sz -- )
   case
      1 of   .Zd.h, .Zn.b, .Zm.b  endof
      2 of   .Zd.s, .Zn.h, .Zm.h  endof
      3 of   .Zd.d, .Zn.s, .Zm.s  endof
      invalid-regs
   endcase
;
: .zzze   ( sz -- )
   case
      0 of   .Zd.b, .Zn.b, .Zm.b, .Zd.b  endof
      1 of   .Zd.h, .Zn.h, .Zm.h, .Zd.h  endof
      2 of   .Zd.s, .Zn.s, .Zm.s, .Zd.s  endof
      3 of   .Zd.d, .Zn.d, .Zm.d, .Zd.d  endof
   endcase
;

: .z>zz[]   ( sz -- )
   case
      2 of   .Zd.s, .Zn.h, 16 3bits Zreg .r# ." .h" 19 2bits 2* 11 1bit or .index  endof
      3 of   .Zd.d, .Zn.s, 16 5bits Zreg .r# ." .s" 20 1bit  2* 11 1bit or .index  endof
      invalid-regs
   endcase
;
: .z>zz[]2   ( sz -- )
   case
      2 of   .Zd.s, .Zn.h, 16 3bits Zreg .r# ." .h" 19 2bits .index  endof
      3 of   .Zd.d, .Zn.s, 16 5bits Zreg .r# ." .s" 20 1bit  .index  endof
      invalid-regs
   endcase
;
: .z>>zz[]   ( sz -- )
   case
      2 of   .Zd.s, .Zn.b, 16 3bits Zreg .r# ." .b" 19 2bits .index  endof
      3 of   .Zd.d, .Zn.h, 16 4bits Zreg .r# ." .h" 20 1bit  .index  endof
      invalid-regs
   endcase
;
: .zzz[]   ( sz -- )
   case
      1x0" 0x" af   .Zd.h, .Zn.h, 16 3bits Zreg .r# ." .h" 22 1bit 2 << 19 2bits or .index  endaf
      2 of   .Zd.s, .Zn.s, 16 3bits Zreg .r# ." .s" 19 2bits .index  endof
      3 of   .Zd.d, .Zn.d, 16 4bits Zreg .r# ." .d" 20 1bit  .index  endof
   endcase
;
: .zzz-c[]   ( sz -- )
   case
      1 of   .Zd.h, .Zn.h, 16 3bits Zreg .r# ." .h" 19 2bits .index  endof
      2 of   .Zd.s, .Zn.s, 16 4bits Zreg .r# ." .s" 20 1bit  .index  endof
      invalid-regs
   endcase
;
: .zp<z   ( sz -- )
   case
      1 of   .Zd.b, .p10m, .Zn.h  endof
      2 of   .Zd.h, .p10m, .Zn.s  endof
      3 of   .Zd.s, .p10m, .Zn.d  endof
      invalid-regs
   endcase
;
: .zp>z   ( sz -- )
   case
      1 of   .Zd.h, .p10m, .Zn.b  endof
      2 of   .Zd.s, .p10m, .Zn.h  endof
      3 of   .Zd.d, .p10m, .Zn.s  endof
      invalid-regs
   endcase
;
: .zp<<z   ( sz -- )
   case
      2 of   .Zd.b, .p10m, .Zn.s  endof
      3 of   .Zd.h, .p10m, .Zn.d  endof
      invalid-regs
   endcase
;
: .zp>>z   ( sz -- )
   case
      2 of   .Zd.s, .p10m, .Zn.b  endof
      3 of   .Zd.d, .p10m, .Zn.h  endof
      invalid-regs
   endcase
;

: .{zreglist}   ( sz startreg# #regs -- )
   .{  2dup 2>r  1- bounds ?do  ( sz )   
      i 0x1f and  Zreg .r#      ( sz )   
      dup .x .,
   loop                         ( sz )
   2r> + 1- 0x1f and  Zreg .r# .x
    ." }, "
;
: .{preglist}   ( sp startreg# #regs -- )
   .{  2dup 2>r  1- bounds ?do  ( sp )   
      i 0x1f and  Preg .r#      ( sp )   
      dup .x .,
   loop                         ( sp )
   2r> + 1- 0x1f and  Preg .r# .x
    ." }, "
;
