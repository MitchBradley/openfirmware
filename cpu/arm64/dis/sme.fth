\ disassembler
\ SME instructions

\ Registers

: .Pd   ( -- )    0 4bits Preg .r#  ;
: .Pd,  ( -- )  .Pd .,  ;
: .Pn   ( -- )    5 4bits Preg .r#  ;
: .Pn,  ( -- )  .Pn .,  ;
: .Pm   ( -- )   16 4bits Preg .r#  ;
: .Pm,  ( -- )  .Pm .,  ;
: .Pa   ( -- )   10 4bits Preg .r#  ;
: .Pa,  ( -- )  .Pa .,  ;

: .Pd.b   ( -- )   .Pd ." .b" ;
: .Pd.h   ( -- )   .Pd ." .h" ;
: .Pd.s   ( -- )   .Pd ." .s" ;
: .Pd.d   ( -- )   .Pd ." .d" ;
\ : .Pd.q   ( -- )   .Pd ." .q" ;
: .Pn.b   ( -- )   .Pn ." .b" ;
: .Pn.h   ( -- )   .Pn ." .h" ;
: .Pn.s   ( -- )   .Pn ." .s" ;
: .Pn.d   ( -- )   .Pn ." .d" ;
\ : .Pn.q   ( -- )   .Pn ." .q" ;
: .Pm.b   ( -- )   .Pm ." .b" ;
: .Pm.h   ( -- )   .Pm ." .h" ;
: .Pm.s   ( -- )   .Pm ." .s" ;
: .Pm.d   ( -- )   .Pm ." .d" ;
\ : .Pm.q   ( -- )   .Pm ." .q" ;

: .Pd.b,   ( -- )   .Pd.b ., ;
: .Pd.h,   ( -- )   .Pd.h ., ;
: .Pd.s,   ( -- )   .Pd.s ., ;
: .Pd.d,   ( -- )   .Pd.d ., ;
\ : .Pd.q,   ( -- )   .Pd.q ., ;
: .Pn.b,   ( -- )   .Pn.b ., ;
: .Pn.h,   ( -- )   .Pn.h ., ;
: .Pn.s,   ( -- )   .Pn.s ., ;
: .Pn.d,   ( -- )   .Pn.d ., ;
\ : .Pn.q,   ( -- )   .Pn.q ., ;
: .Pm.b,   ( -- )   .Pm.b ., ;
: .Pm.h,   ( -- )   .Pm.h ., ;
: .Pm.s,   ( -- )   .Pm.s ., ;
: .Pm.d,   ( -- )   .Pm.d ., ;
\ : .Pm.q,   ( -- )   .Pm.q ., ;


: .P10    ( -- )   10 3bits Preg .r#  ;
: .P10g   ( -- )   10 4bits Preg .r#  ;
: .P10m   ( -- )   10 3bits Preg .r# ." /m" ;
: .P13m   ( -- )   13 3bits Preg .r# ." /m" ;
: .P16m   ( -- )   16 4bits Preg .r# ." /m" ;
: .P10z   ( -- )   10 3bits Preg .r# ." /z" ;
: .P13z   ( -- )   13 3bits Preg .r# ." /z" ;
: .P16z   ( -- )   16 4bits Preg .r# ." /z" ;

: .P10,    ( -- )   .P10  .,  ;
: .P10g,   ( -- )   .P10g .,  ;
: .P10m,   ( -- )   .P10m .,  ;
: .P13m,   ( -- )   .P13m .,  ;
: .P16m,   ( -- )   .P16m .,  ;
: .P10z,   ( -- )   .P10z .,  ;
: .P13z,   ( -- )   .P13z .,  ;
: .P16z,   ( -- )   .P16z .,  ;

: .Zd   ( -- )   rd Zreg .r#  ;
: .Zd,  ( -- )  .Zd .,  ;
: .Zn   ( -- )   rn Zreg .r#  ;
: .Zn,  ( -- )  .Zn .,  ;
: .Zm   ( -- )   rm Zreg .r#  ;
: .Zm,  ( -- )  .Zm .,  ;
: .Za   ( -- )   ra Zreg .r#  ;
: .Za,  ( -- )  .Za .,  ;

\ for indexed registers
: .Zd.b   ( -- )   .Zd ." .b" ;
: .Zd.h   ( -- )   .Zd ." .h" ;
: .Zd.s   ( -- )   .Zd ." .s" ;
: .Zd.d   ( -- )   .Zd ." .d" ;
: .Zd.q   ( -- )   .Zd ." .q" ;
: .Zn.b   ( -- )   .Zn ." .b" ;
: .Zn.h   ( -- )   .Zn ." .h" ;
: .Zn.s   ( -- )   .Zn ." .s" ;
: .Zn.d   ( -- )   .Zn ." .d" ;
: .Zn.q   ( -- )   .Zn ." .q" ;
: .Zm.b   ( -- )   .Zm ." .b" ;
: .Zm.h   ( -- )   .Zm ." .h" ;
: .Zm.s   ( -- )   .Zm ." .s" ;
: .Zm.d   ( -- )   .Zm ." .d" ;
: .Zm.q   ( -- )   .Zm ." .q" ;

: .Zd.b,   ( -- )   .Zd.b ., ;
: .Zd.h,   ( -- )   .Zd.h ., ;
: .Zd.s,   ( -- )   .Zd.s ., ;
: .Zd.d,   ( -- )   .Zd.d ., ;
: .Zd.q,   ( -- )   .Zd.q ., ;
: .Zn.b,   ( -- )   .Zn.b ., ;
: .Zn.h,   ( -- )   .Zn.h ., ;
: .Zn.s,   ( -- )   .Zn.s ., ;
: .Zn.d,   ( -- )   .Zn.d ., ;
: .Zn.q,   ( -- )   .Zn.q ., ;
: .Zm.b,   ( -- )   .Zm.b ., ;
: .Zm.h,   ( -- )   .Zm.h ., ;
: .Zm.s,   ( -- )   .Zm.s ., ;
: .Zm.d,   ( -- )   .Zm.d ., ;
: .Zm.q,   ( -- )   .Zm.q ., ;

: .ZA   ( n -- )  ." za" u.  ;
\ XXX the reality is more complicated
: .ZAd   ( -- )   0 4bits .ZA  ;
: .ZAd,  ( -- )  .Zd .,  ;

: .ZAd.b   ( -- )   .ZAd ." .b" ;
: .ZAd.h   ( -- )   .ZAd ." .h" ;
: .ZAd.s   ( -- )   .ZAd ." .s" ;
: .ZAd.d   ( -- )   .ZAd ." .d" ;
: .ZAd.q   ( -- )   .ZAd ." .q" ;

: .ZAd.b,   ( -- )   .ZAd.b ., ;
: .ZAd.h,   ( -- )   .ZAd.h ., ;
: .ZAd.s,   ( -- )   .ZAd.s ., ;
: .ZAd.d,   ( -- )   .ZAd.d ., ;
: .ZAd.q,   ( -- )   .ZAd.q ., ;

: .[Wv     ( -- )   ." [W"  13 2bits 12 + u.  ;
: .Wimm4   ( n -- )    4bits ?dup if  .,  ." #" u.  then    ;
: .Wimm3   ( n -- )    3bits ?dup if  .,  ." #" u.  then    ;
: .Wimm2   ( n -- )    2bits ?dup if  .,  ." #" u.  then    ;
: .Wimm1   ( n -- )     1bit ?dup if  .,  ." #" u.  then   ;
: .ZA[W],   ( -- )   ." za" 0 .[Wv .Wimm4 .] .,  ;

: .HV      ( -- )   1bit if  ." v" else ." h"  then  ;
: .ZAHV    ( -- )   .ZA 15 .HV  ;
: .ZAdHV.b[W]   ( -- )   0       .ZAHV ." .b" .[Wv  0 .Wimm4 .]  ;
: .ZAdHV.h[W]   ( -- )   3 1bit  .ZAHV ." .h" .[Wv  0 .Wimm3 .]  ;
: .ZAdHV.s[W]   ( -- )   2 2bits .ZAHV ." .s" .[Wv  0 .Wimm2 .]  ;
: .ZAdHV.d[W]   ( -- )   1 3bits .ZAHV ." .d" .[Wv  0 .Wimm1 .]  ;
: .ZAdHV.q[W]   ( -- )   0 4bits .ZAHV ." .q" .[Wv           .]  ;

: .ZAnHV.b[W]   ( -- )   0       .ZAHV ." .b" .[Wv  5 .Wimm4 .]  ;
: .ZAnHV.h[W]   ( -- )   8 1bit  .ZAHV ." .h" .[Wv  5 .Wimm3 .]  ;
: .ZAnHV.s[W]   ( -- )   7 2bits .ZAHV ." .s" .[Wv  5 .Wimm2 .]  ;
: .ZAnHV.d[W]   ( -- )   6 3bits .ZAHV ." .d" .[Wv  5 .Wimm1 .]  ;
: .ZAnHV.q[W]   ( -- )   5 4bits .ZAHV ." .q" .[Wv           .]  ;

: sme-bfmop
   4 1bit if  ." bfmops"   else  ." bfmopa"  then
   op-col  .ZAd.s, .p10m, .p13m, .Zn.h, .Zm.h
;
: sme-fmop
   4 1bit if   ." fmops"  else  ." fmopa"   then
   op-col  21 2bits case
      0 of   .ZAd.s, .p10m, .p13m, .Zn.s, .Zm.s   endof
      1 of   .ZAd.s, .p10m, .p13m, .Zn.h, .Zm.h   endof
      2 of   .ZAd.d, .p10m, .p13m, .Zn.d, .Zm.d   endof
      invalid-regs
   endcase
;
: sme-mop
   instruction@ 0x0120.0010 and case
      0x0000.0000 of   ." smopa"    endof
      0x0000.0010 of   ." smops"    endof
      0x0020.0000 of   ." sumopa"   endof
      0x0020.0010 of   ." sumops"   endof
      0x0100.0000 of   ." usmopa"   endof
      0x0100.0010 of   ." usmops"   endof
      0x0120.0000 of   ." umopa"    endof
      0x0120.0010 of   ." umops"    endof
   endcase
   op-col 22 1bit if
      .ZAd.d, .p10m, .p13m, .Zn.h, .Zm.h
   else
      .ZAd.s, .p10m, .p13m, .Zn.b, .Zm.b
   then
;

: sme-mov-z>a
   instruction@ 0xffff.0000 and 0xc008.0000 = if
      ." zero" op-col ." #0x" 0 8bits .h  exit
   then
   ." mova" op-col
   16 1bit 2 << 22 2 bits or case
      0 of   .ZAdHV.b[W] ., .p10m, .Zn.b   endof
      1 of   .ZAdHV.h[W] ., .p10m, .Zn.h   endof
      2 of   .ZAdHV.s[W] ., .p10m, .Zn.s   endof
      3 of   .ZAdHV.d[W] ., .p10m, .Zn.d   endof
      7 of   .ZAdHV.q[W] ., .p10m, .Zn.q   endof
   endcase
;
: sme-mov-a>z
   ." mova" op-col
   16 1bit 2 << 22 2 bits or case
      0 of   .Zd.b, .p10m, .ZAnHV.b[W]    endof
      1 of   .Zd.h, .p10m, .ZAnHV.h[W]    endof
      2 of   .Zd.s, .p10m, .ZAnHV.s[W]    endof
      3 of   .Zd.d, .p10m, .ZAnHV.d[W]    endof
      7 of   .Zd.q, .p10m, .ZAnHV.q[W]    endof
   endcase
;
: sme-addhv
   16 1bit if   ." addva"  else  ." addha"  then   op-col
   22 1bit if
      .ZAd.d, .p10m, .p13m, .Zn.d
   else
      .ZAd.s, .p10m, .p13m, .Zn.s
   then
;
: sme-mov   ( -- )
   instruction@ 0xc090.0000 and 0xc090.0000 = if  sme-addhv  exit  then
   17 1bit if   sme-mov-a>z  else  sme-mov-z>a  then
;

: .[xnxm]   ( sz -- )
   >r  .[xn|sp rm if
      ., .Xm  r@ if   ." , lsl #" r@ u.  then
   then  .]
   r> drop
;

: sme-ldst
   21 1bit if  ." st"  else  ." ld"  then
   22 3bits 4 = if
      ." r"  op-col  .ZA[w],  .[xn|sp 0 4bits ?dup if
	 ." , #" u. ." , mul vl "
      then  .]
   else
      ." 1" 22 3bits case
      0 of   ." b "  op-col  ." { " .ZAdHV.b[W] ."  }, "  .p10z,  0 .[xnxm]  endof
      1 of   ." h "  op-col  ." { " .ZAdHV.h[W] ."  }, "  .p10z,  1 .[xnxm]  endof
      2 of   ." s "  op-col  ." { " .ZAdHV.s[W] ."  }, "  .p10z,  2 .[xnxm]  endof
      3 of   ." d "  op-col  ." { " .ZAdHV.d[W] ."  }, "  .p10z,  3 .[xnxm]  endof
      7 of   ." q "  op-col  ." { " .ZAdHV.q[W] ."  }, "  .p10z,  4 .[xnxm]  endof
      invalid-regs
      endcase
   then
;

