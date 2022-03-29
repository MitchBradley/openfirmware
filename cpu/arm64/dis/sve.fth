\ disassembler
\ SVE instructions

: sve-int-mathp   ( -- )
    instruction@ 0x001f.0000 and case
      0x0000.0000 of   ." add"    endof
      0x0001.0000 of   ." sub"    endof
      0x0003.0000 of   ." subr"   endof
      0x0008.0000 of   ." smax"   endof
      0x0009.0000 of   ." umax"   endof
      0x000a.0000 of   ." smin"   endof
      0x000b.0000 of   ." umin"   endof
      0x000c.0000 of   ." sabd"   endof
      0x000d.0000 of   ." uabd"   endof
      0x0010.0000 of   ." mul"    endof
      0x0012.0000 of   ." smulh"  endof
      0x0013.0000 of   ." umulh"  endof
      0x0014.0000 of   ." sdiv"   endof
      0x0015.0000 of   ." udiv"   endof
      0x0016.0000 of   ." sdivr"  endof
      0x0017.0000 of   ." udivr"  endof
      0x0018.0000 of   ." orr"    endof
      0x0019.0000 of   ." eor"    endof
      0x001a.0000 of   ." and"    endof
      0x001b.0000 of   ." bic"    endof
      illegal drop exit
   endcase
   op-col sz .zpez 
;
: sve-int-add-red   ( -- )
   16 3bits case
      0 of  ." saddv"   endof
      1 of  ." uaddv"   endof
      illegal drop exit
   endcase
   op-col .Dd, .p10, sz .zn.x
;
: sve-int-min-red   ( -- )
   16 3bits case
      0 of  ." smaxv"   endof
      1 of  ." umaxv"   endof
      2 of  ." sminv"   endof
      3 of  ." uminv"   endof
      illegal drop exit
   endcase
   op-col  sz .spz
;
: sve-int-log-red   ( -- )
   16 3bits case
      0 of  ." orv"    endof
      1 of  ." eorv"   endof
      2 of  ." andv"   endof
      illegal drop exit
   endcase
   op-col  sz .spz
;
: sve-int-reduce   ( -- )
   19 2bits case
      0 of  sve-int-add-red   endof
      1 of  sve-int-min-red   endof
      2 of
	 ." movprfx"  op-col  sz dup .zd.x,
	 16 1bit if   .p10m,  else  .p10z,  then  .zn.x
      endof
      3 of  sve-int-log-red   endof
   endcase
;

: sve-madp   ( -- )
   instruction@ 0x0000.a000 and case
      0x0000.0000 of   ." mla"  op-col sz .zdpnm  endof
      0x0000.2000 of   ." mls"  op-col sz .zdpnm  endof
      0x0000.8000 of   ." mad"  op-col sz .zdpmn  endof
      0x0000.a000 of   ." msb"  op-col sz .zdpmn  endof
   endcase
;
: sve-shift-widep   ( -- )
   instruction@ 0x0007.0000 and case
      0x0000.0000 of   ." asr"   endof
      0x0001.0000 of   ." lsr"   endof
      0x0003.0000 of   ." lsl"   endof
      illegal drop exit
   endcase
   op-col  sz  .zpew
;
: sve-shift-vecp   ( -- )
   19 1bit if   sve-shift-widep  exit  then
   instruction@ 0x0007.0000 and case
      0x0000.0000 of   ." asr"   endof
      0x0001.0000 of   ." lsr"   endof
      0x0003.0000 of   ." lsl"   endof
      0x0004.0000 of   ." asrr"  endof
      0x0005.0000 of   ." lsrr"  endof
      0x0007.0000 of   ." lslr"  endof
      illegal drop exit
   endcase
   op-col  sz  .zpez
;
: sve-shiftp   ( -- )
   20 1bit if   sve-shift-vecp  exit  then
    instruction@ 0x000f.0000 and case
      0x0000.0000 of   ." asr"    endof
      0x0001.0000 of   ." lsr"    endof
      0x0003.0000 of   ." lsl"    endof
      0x0004.0000 of   ." asrd"   endof
      0x0006.0000 of   ." sqshl"  endof
      0x0007.0000 of   ." uqshl"  endof
      0x000c.0000 of   ." srshr"  endof
      0x000d.0000 of   ." urshr"  endof
      0x000f.0000 of   ." sqshlu" endof
      illegal drop exit
   endcase
   op-col  tsz-imm3-lo .zpec
;
: sve-unaryp   ( -- )
    instruction@ 0x000f.0000 and case
      0x0000.0000 of   ." sxtb"   endof
      0x0001.0000 of   ." uxtb"   endof
      0x0002.0000 of   ." sxth"   endof
      0x0003.0000 of   ." uxth"   endof
      0x0004.0000 of   ." sxtw"   endof
      0x0005.0000 of   ." uxtw"   endof
      0x0006.0000 of   ." abs"    endof
      0x0007.0000 of   ." neg"    endof
      0x0008.0000 of   ." cls"    endof
      0x0009.0000 of   ." clz"    endof
      0x000a.0000 of   ." cnt"    endof
      0x000b.0000 of   ." cnot"   endof
      0x000c.0000 of   ." fabs"   endof
      0x000d.0000 of   ." fneg"   endof
      0x000e.0000 of   ." not"    endof
      illegal drop exit
   endcase
   op-col   22 2bits .zpz
;
: sve-vec-add   ( -- )
    instruction@ 0x0000.1c00 and case
      0x0000.0000 of   ." add"     endof
      0x0000.0400 of   ." sub"     endof
      0x0000.1000 of   ." sqadd"   endof
      0x0000.1400 of   ." uqadd"   endof
      0x0000.1800 of   ." sqsub"   endof
      0x0000.1c00 of   ." uqsub"   endof
      illegal drop exit
   endcase
   op-col   22 2bits .zzz
;

: sve-bit-logic   ( -- )
   sz 2 << 10 2bits or case
      1x0" 0000" af   ." and"   op-col   3 .zzz    endaf
      1x0" 0100" af   ." orr"   op-col   3 .zzz    endaf
      1x0" 1000" af   ." eor"   op-col   3 .zzz    endaf
      1x0" 1100" af   ." bic"   op-col   3 .zzz    endaf
      1x0" xx01" af   ." xar"   op-col   tsz-imm3-hi .zezc   endaf
      1x0" 0010" af   ." eor3"  op-col   3 .zdemn  endof
      1x0" 0011" af   ." bsl"   op-col   3 .zdemn  endof
      1x0" 0110" af   ." bcax"  op-col   3 .zdemn  endof
      1x0" 0111" af   ." bsl1n" op-col   3 .zdemn  endof
      1x0" 1011" af   ." bsl2n" op-col   3 .zdemn  endof
      1x0" 1111" af   ." nbsl"  op-col   3 .zdemn  endof
      illegal
   endcase
;

: sve-index-gen   ( -- )
   ." index" op-col  sz .zd.x,
   10 2bits case
      0 of   5 5 sxbits .imm ., 16 5 sxbits .imm  endof
      1 of   .szrn .,           16 5 sxbits .imm  endof
      2 of   5 5 sxbits .imm ., .szrm  endof
      3 of   .szrn ., .szrm  endof
   endcase
;
: sve-stack   ( -- )
   23 1bit if
      ." rdvl" op-col  .Xd, 5 6 sxbits .imm  exit
   then
   22 1bit if   ." addpl"   else  ." addvl"  then
   op-col  .xd|sp, .xm|sp,  5 6 sxbits .imm 
;
: sve2-int-mul   ( -- )
   instruction@ 0x0000.1c00 and case
      0x0000.0000 of   ." mul"       endof
      0x0000.0400 of   ." pmul"      endof
      0x0000.0800 of   ." smulh"     endof
      0x0000.0c00 of   ." umulh"     endof
      0x0000.1000 of   ." sqdmulh"   endof
      0x0000.1400 of   ." sqrdmulh"  endof
      illegal drop exit
   endcase
   op-col   22 2bits .zzz
;
: shiftimm-n,sz   ( n sz )
   22 2bits 2 << 19 2bits + case
      1x0" 0001" af  16 3bits  0  endaf
      1x0" 001x" af  16 4bits  1  endaf
      1x0" 01xx" af  16 5bits  2  endaf
      1x0" 1xxx" af  22 1bit 5 << 16 5bits + 3  endaf
      illegal drop 0 0 exit
   endcase
;

: sve-shift   ( -- )
   10 2bits case
      0 of   ." asr"   endof
      1 of   ." lsr"   endof
      3 of   ." lsl"   endof
      illegal drop exit
   endcase
   op-col  
   12 1bit if
      shiftimm-n,sz .zzc   \ shift-imm
   else
      22 2bits .zzw   \ shift-wide
   then
;
: sve-adr   ( -- )
   ." adr"  op-col
   23 1bit if  22 1bit .z[zz] exit  then
   .Zd.d, .[ .Zn.d, .Zm.d .,
   22 1bit if  ." uxtw "  else  ." sxtw "  then
   10 2bits .imm .] 
;
: sve-int-misc   ( -- )
   11 1bit 0= if  ." ftssel"  op-col  sz .zzz  exit  then
   10 1bit 0= if  ." fexpa"   op-col  sz .zz   exit  then
   ." movprfx"  op-col .zd, .zn
;
: sve2-cadd   ( -- )
   16 1bit if  ." sqcadd"  else  ." cadd"  then
   op-col  sz .zez ., 10 1bit 2* 1+ .square
;
: sve2-ssra   ( -- )
   10 2bits case
      0 of  ." ssra"   endof
      1 of  ." usra"   endof
      2 of  ." srsra"  endof
      3 of  ." ursra"  endof
   endcase
   op-col  tsz-imm3-hi  .zzc
;
: sve2-sri   ( -- )
   10 1bit if  ." sli"  else  ." sri"  then
   op-col  tsz-imm3-hi  .zzc
;
: sve2-saba   ( -- )
   10 1bit if  ." uaba"  else  ." saba"  then
   op-col  sz .zzz
;
: sve-acc   ( -- )
   17 4bits 3 << 11 3bits or  case
      1x0" 0000_011" af  sve2-cadd   endaf
      1x0" xxxx_10x" af  sve2-ssra   endaf
      1x0" xxxx_110" af  sve2-sri    endaf
      1x0" xxxx_111" af  sve2-saba   endaf
      illegal
   endcase
;

: sve-sat-inc-vec-elem   ( -- )
   sz 2 << 10 2bits or case
      4 of   ." sqinch"   endof
      5 of   ." uqinch"   endof
      6 of   ." sqdech"   endof
      7 of   ." uqdech"   endof
      8 of   ." sqincw"   endof
      9 of   ." uqincw"   endof
      10 of  ." sqdecw"   endof
      11 of  ." uqdecw"   endof
      12 of  ." sqincd"   endof
      13 of  ." uqincd"   endof
      14 of  ." sqdecd"   endof
      15 of  ." uqdecd"   endof
      illegal drop exit
   endcase
   .Xd, .zpat#
;
: sve-sat-inc-reg-elem   ( -- )
   sz 2 << 10 2bits or case
      0 of   ." sqincb"   endof
      1 of   ." uqincb"   endof
      2 of   ." sqdecb"   endof
      3 of   ." uqdecb"   endof
      4 of   ." sqinch"   endof
      5 of   ." uqinch"   endof
      6 of   ." sqdech"   endof
      7 of   ." uqdech"   endof
      8 of   ." sqincw"   endof
      9 of   ." uqincw"   endof
      10 of  ." sqdecw"   endof
      11 of  ." uqdecw"   endof
      12 of  ." sqincd"   endof
      13 of  ." uqincd"   endof
      14 of  ." sqdecd"   endof
      15 of  ." uqdecd"   endof
   endcase
   op-col  .Xd,
   20 1bit 0= if  .Wn,  then
   .zpat#
;
: sve-cnt   ( -- )
   sz case
      0 of   ." cntb"   endof
      1 of   ." cnth"   endof
      2 of   ." cntw"   endof
      3 of   ." cntd"   endof
   endcase
   op-col  .Xd, .zpat#
;
: sve-inc-vec-elem    ( -- )
   sz 1 << 10 1bit or case
      2 of   ." inch"  1   endof
      3 of   ." dech"  1   endof
      4 of   ." incw"  2   endof
      5 of   ." decw"  2   endof
      6 of   ." incd"  3   endof
      7 of   ." decd"  3   endof
      illegal drop exit
   endcase
   op-col  .Zd.x,  .zpat#
;
: sve-inc-reg-elem    ( -- )
   sz 1 << 10 1bit or case
      0 of   ." incb"    endof
      1 of   ." decb"    endof
      2 of   ." inch"    endof
      3 of   ." dech"    endof
      4 of   ." incw"    endof
      5 of   ." decw"    endof
      6 of   ." incd"    endof
      7 of   ." decd"    endof
   endcase
   op-col  .Xd,  .zpat#
;
: sve-elem-cnt   ( -- )
   20 1bit 3 << 11 3bits or  case
      0 of   sve-sat-inc-vec-elem   endof
      1 of   sve-sat-inc-vec-elem   endof
      4 of   sve-cnt                endof
      6 of   sve-sat-inc-reg-elem   endof
      7 of   sve-sat-inc-reg-elem   endof
      8 of   sve-inc-vec-elem       endof
      12 of  sve-inc-reg-elem       endof
      14 of  sve-sat-inc-reg-elem   endof
      15 of  sve-sat-inc-reg-elem   endof
      illegal drop exit
   endcase
;
: sve-bit-imm   ( -- )
   sz case
      0 of   ." orr"   endof
      1 of   ." eor"   endof
      2 of   ." and"   endof
      3 of   ." dupm" op-col  .zdimm  exit  endof
   endcase
   op-col decode-sz dup .ze, decode13 .dimm
;
: sve-int-wide-immp   ( -- )
   13 3bits 6 = if
      ." fcpy"   op-col  22 2bits .Zd.x,  .p16m, 5 8bits .fimm8 exit
   then
   15 1bit 0= if
      ." cpy"
   else
      illegal drop exit
   then
   op-col  22 2bits .Zd.x,
   14 1bit if  .p16m,  else  .p16z,  then
   5 8 sxbits .imm
   13 1bit if  ." , lsl #8"  then
;
: sve-perm-ext   ( -- )
   ." ext"  op-col  22 1bit if  \ constructive
      .Zd.b, .{ .Zn, .Zn2 .} ., .zuimm8
   else  \ destructive
      .Zd.b, .Zd.b, .Zn.b, .zuimm8
   then
;
: sve-dup-ind   ( -- )   ." dup"  op-col  tsz.z[]  ;
: sve-tbl3   unimpl  ;
: sve-tbl    unimpl  ;

: tsz-sz  ( tszhl -- sz )
   dup 0= if  ." invalid tsz " exit  then  \ don't spin forever
   0 swap begin dup 1 and 1 <> while swap 1+ swap 1 >> repeat drop
;
: sve-dup-pred  ( -- )
   ." dup"  op-col 18 3bits 22 1bit 3 << or tsz-sz
   dup dup .Pd.x, .P10g ." /z," .pn.x ." [w"  16 2bits 12 + u.
   case
       0 of 22 2bits 2 << 19 2bits or  endof
       1 of 22 2bits 1 << 20 1bit  or  endof
       2 of 22 2bits                   endof
       3 of 23 1bit                    endof
   endcase
   ?dup if ., .uimm  then
   ." ]"
;

: sve-perm-scalar   ( -- )
   16 5bits case
      0 of   ." dup"  op-col .zrn   endof
      4 of   ." insr"  op-col .zrn   endof
      20 of  ." insr"  op-col .zs    endof
      illegal drop exit
   endcase
;
: sve-perm-vec   ( -- )
   16 5bits case
      0 of    sve-perm-scalar  exit  endof
      4 of    sve-perm-scalar  exit  endof
      16 of   ." sunpklo"  endof
      17 of   ." sunpkhi"  endof
      18 of   ." uunpklo"  endof
      19 of   ." uunpkhi"  endof
      20 of   sve-perm-scalar  exit  endof
      24 of   ." rev"  endof
      illegal drop exit
   endcase
   op-col  sz .z>z
;
: sve-perm-pred-elem   ( -- )
   10 3bits case
      0 of   ." zip1"   endof
      1 of   ." zip2"   endof
      2 of   ." uzp1"   endof
      3 of   ." uzp2"   endof
      4 of   ." trn1"   endof
      5 of   ." trn2"   endof
      illegal drop exit
   endcase
   op-col  sz .ppp
;
: sve-perm-pred   ( -- )
   20 1bit 0= if  sve-perm-pred-elem  exit  then
   sz 8 << 16 5bits 3 << or 10 3bits or  case
      1x0" 00_10000_000"  af  ." punpklo"  op-col  .Pd.h, .Pn.b  endaf
      1x0" 00_10001_000"  af  ." punpkhi"  op-col  .Pd.h, .Pn.b  endaf
      1x0" xx_10100_000"  af  ." rev"      op-col  sz .pp        endaf
      illegal drop exit
   endcase
;
: sve-perm-vec-elem   ( -- )
   10 3bits case
      0 of   ." zip1"   endof
      1 of   ." zip2"   endof
      2 of   ." uzp1"   endof
      3 of   ." uzp2"   endof
      4 of   ." trn1"   endof
      5 of   ." trn2"   endof
      illegal drop exit
   endcase
   op-col  sz .zzz
;

: sve-perm-vec-pred   ( -- )
   16 5bits 2* 13 1bit or  case
      1x0" 00000_0" af  ." cpy"     op-col sz .zps   endaf
      1x0" 00001_0" af  ." compact" op-col sz .zpz   endaf
      1x0" 00000_1" af  ." lasta"   op-col sz .rpz   endaf
      1x0" 00001_1" af  ." lastb"   op-col sz .rpz   endaf
      1x0" 00010_0" af  ." lasta"   op-col sz .spz   endaf
      1x0" 00011_0" af  ." lastb"   op-col sz .spz   endaf
      1x0" 00100_0" af  ." revb"    op-col sz .zpz   endaf
      1x0" 00101_0" af  ." revh"    op-col sz .zpz   endaf
      1x0" 00110_0" af  ." revw"    op-col        3 .zpz   endaf
      1x0" 00111_0" af  ." rbit"    op-col sz .zpz   endaf
      1x0" 01000_1" af  ." cpy"     op-col sz .zpr   endaf
      1x0" 01000_0" af  ." clasta"  op-col sz .zpez  endaf
      1x0" 01001_0" af  ." clastb"  op-col sz .zpez  endaf
      1x0" 01010_0" af  ." clasta"  op-col sz .spez  endaf
      1x0" 01011_0" af  ." clastb"  op-col sz .spez  endaf
      1x0" 01100_0" af  ." splice"  op-col sz .zpez  endaf
      1x0" 01101_0" af  ." splice"  op-col sz .zp{zz}   endaf
      1x0" 01110_0" af  ." revd"    op-col  4 .zpz   endaf
      1x0" 10000_1" af  ." clasta"  op-col sz .rpez  endaf
      1x0" 10001_1" af  ." clastb"  op-col sz .rpez  endaf
      illegal drop exit
   endcase
;
: sve-sel   ( -- )   ." sel" op-col  sz .zpzz2  ;

: sve-perm-vec-seg   ( -- )
   22 1bit 3 << 10 3bits or case
      0 of   ." zip1"   endof
      1 of   ." zip2"   endof
      2 of   ." uzp1"   endof
      3 of   ." uzp2"   endof
      6 of   ." trn1"   endof
      7 of   ." trn2"   endof
      illegal drop exit
   endcase
   op-col   4 .zzz
;

: sve-int-cmp   ( -- )
   13 3bits 1 << 4 1bit or  case
      0 of   ." cmphs"  0   endof
      1 of   ." cmphi"  0   endof
      2 of   ." cmpeq"  1   endof
      3 of   ." cmpne"  1   endof
      4 of   ." cmpge"  1   endof
      5 of   ." cmpgt"  1   endof
      6 of   ." cmplt"  1   endof
      7 of   ." cmple"  1   endof
      8 of   ." cmpge"  0   endof
      9 of   ." cmpgt"  0   endof
      10 of  ." cmpeq"  0   endof
      11 of  ." cmpne"  0   endof
      12 of  ." cmphs"  1   endof
      13 of  ." cmphi"  1   endof
      14 of  ." cmplo"  1   endof
      15 of  ." cmpls"  1   endof
   endcase
   op-col  sz swap if  .ppzw  else  .ppzz  then
;
: sve-cmp-uimm  ( -- )
   13 1bit 2* 4 1bit or  case
      0 of   ." cmphs"   endof
      1 of   ." cmphi"   endof
      2 of   ." cmplo"   endof
      3 of   ." cmpls"   endof
   endcase
   op-col  sz .ppz,  14 7bits  ." #" u.
;
: sve-cmp-simm  ( -- )
   15 1bit 2 << 13 1bit 2* or 4 1bit or  case
      0 of   ." cmpge"   endof
      1 of   ." cmpgt"   endof
      2 of   ." cmplt"   endof
      3 of   ." cmple"   endof
      4 of   ." cmpeq"   endof
      5 of   ." cmpne"   endof
      illegal drop exit
   endcase
   op-col  sz .ppz,  16 5 sxbits  ." #" s.
;
: sve-pred-logic   ( -- )
   sz 2*  9 1bit or 2*  4 1bit or  case
      0 of   ." and"    endof
      1 of   ." bic"    endof
      2 of   ." eor"    endof
      3 of   ." sel"    op-col  .pd.b, .p10, .pn.b, .pm.b  exit  endof
      4 of   ." ands"   endof
      5 of   ." bics"   endof
      6 of   ." eors"   endof
      8 of   ." orr"    endof
      9 of   ." orn"    endof
      10 of  ." nor"    endof
      11 of  ." nand"   endof
      12 of  ." orrs"   endof
      13 of  ." orns"   endof
      14 of  ." nors"   endof
      15 of  ." nands"  endof
      illegal drop exit
   endcase
   op-col  .pd.b, .p10z, .pn.b, .pm.b
;
: sve-prop-break   ( -- )
   22 1bit 2* 4 1bit or  case
      0 of   ." brkpa"    endof
      1 of   ." brkpb"    endof
      2 of   ." brkpas"   endof
      3 of   ." brkpbs"   endof
   endcase
   op-col  .pgpp
;
: sve-part-break   ( -- )
   sz 2 << 19 1bit 2* or 4 1bit or  case
      1x0" 0010"  af   ." brkn"   op-col  .pgpe        endaf
      1x0" 0110"  af   ." brkns"  op-col  .pgpe        endaf
      1x0" 000x"  af   ." brka"   op-col  4 1bit .pgp  endaf
      1x0" 010x"  af   ." brkas"  op-col  0      .pgp  endaf
      1x0" 100x"  af   ." brkb"   op-col  4 1bit .pgp  endaf
      1x0" 110x"  af   ." brkbs"  op-col  0      .pgp  endaf
      illegal
   endcase
;

: sve-ptest   ( -- )
   22 2bits 4 << 0 4bits or  case
      1x0" 010000"  af	." ptest"  op-col  .p10g ., .Pn.b   endaf
      illegal
   endcase
;
: sve-pfirst   ( -- )
   22 2bits  case
      1x0" 01"  af  ." pfirst"  op-col  .Pd.b, .Pn, .Pd.b   endaf
      illegal
   endcase
;
: sve-pfalse   ( -- )
   22 2bits  case
      1x0" 00"  af  ." pfalse"  op-col  .Pd.b  endaf
      illegal
   endcase
;
: sve-pinit   ( -- )
   16 1bit if   ." ptrues"  else  ." ptrue"  then
   op-col  sz .Pd.x, .zpat
;
: sve-pred-misc   ( -- )
   16 4bits 3 <<  11 3bits or 2 <<  9 2bits or  5 << 4 5bits or
   case
      1x0" 0000_xxx_x0_xxxx0"  af   sve-ptest    endaf
      1x0" 1000_000_00_xxxx0"  af   sve-pfirst   endaf
      1x0" 1000_100_10_00000"  af   sve-pfalse   endaf
      1x0" 1001_000_10_xxxx0"  af  ." pnext"  op-col  sz dup .Pd.x, .Pn, .Pd.x  endaf
      1x0" 100x_100_0x_xxxx0"  af   sve-pinit    endaf
      illegal
   endcase
;

: sve-int-ctr-to-mask
   ." pext"   op-col
   9 2bits  case
      1x0" 0x"  af  sz .Pd.x, .Pn 8 2bits .index   endaf
      1x0" 10"  af  sz 0 4bits 2 .{preglist} .Pn 8 1bit .index   endaf
      illegal
   endcase
;

: whilexx   ( cond -- )
   case
      0 of   ." whilege"  endof
      1 of   ." whilegt"  endof
      2 of   ." whilelt"  endof
      3 of   ." whilele"  endof
      4 of   ." whilehs"  endof
      5 of   ." whilehi"  endof
      6 of   ." whilelo"  endof
      7 of   ." whilels"  endof
   endcase
   op-col
;
: sve-while-rr-pair
   10 2bits 2* 0 1bit or  whilexx  sz  1 3bits 2 .{preglist} .Xn, .Xm
;
: sve-while-rr-pn
   10 2bits 2* 3 1bit or  whilexx   sz .pxx ., 13 1bit if  ." VLx4 "  else  ." VLx2"  then
;

: sve-cmp-pred-ctr
   16 5bits 3 <<  11 3bits or 6 <<  5 6bits or 1 <<  3 1bit or
   case
      1x0" 00000_110_xxxxxx_x"  af   sve-int-ctr-to-mask  endaf
      1x0" 00000_111_000000_0"  af   ." ptrue"  op-col  sz .Pd.x   endaf
      1x0" xxxxx_01x_xxxxxx_x"  af   sve-while-rr-pair    endaf
      1x0" xxxxx_x0x_xxxxxx_x"  af   sve-while-rr-pn      endaf
      illegal
   endcase
;

: sve-while-cnt   ( -- )
   10 2bits 2* 4 1bit or  whilexx  sz  12 1bit .prr
;

: sve-cterm   ( -- )
   22 1bit 0= if
      illegal drop exit
   then
   4 1bit if  ." ctermne"  else  ." ctermeq"  then
   op-col  22 1bit dup s.rn, s.rm
;
: sve-while-ptr   ( -- )
   4 1bit if  ." whilerw"  else  ." whilewr"  then
   op-col  sz .pxx
;
: sve-cmp-scalar   ( -- )
   10 4bits 4 << 0 4bits or case
      1x0" 0xxxxxxx"  af  sve-while-cnt  endaf
      1x0" 10000000"  af  sve-cterm      endaf
      1x0" 1100xxxx"  af  sve-while-ptr  endaf
      illegal drop exit
   endcase
;
: sve-cntp   ( -- )
   ." cntp"  op-col  .Xd, .P10g, sz .Pn.x
;
: sve-dup-imm   ( -- )
   16 1bit if
      ." fdup"  op-col  22 2bits .Zd.x, 5 8bits .fimm8 exit
   else
     ." dup"
  then
   op-col  sz .zd.x,   5 8 sxbits .imm
   13 1bit if  ." , lsl #8"  then
;
: sve-int-add-imm   ( -- )
   16 3bits case
      0 of   ." add"    endof
      1 of   ." sub"    endof
      3 of   ." subr"   endof
      4 of   ." sqadd"  endof
      5 of   ." uqadd"  endof
      6 of   ." sqsub"  endof
      7 of   ." uqsub"  endof
      illegal drop exit
   endcase
   op-col  sz .ze,   5 8bits .uimm
   13 1bit if  ." , lsl #8"  then
;
: sve-int-max-imm   ( -- )
   16 3bits case
      0 of  ." smax"   op-col  sz .ze,   5 8 sxbits .imm  endof
      1 of  ." umax"   op-col  sz .ze,   5 8bits .uimm    endof
      2 of  ." smin"   op-col  sz .ze,   5 8 sxbits .imm  endof
      3 of  ." umin"   op-col  sz .ze,   5 8bits .uimm    endof
      illegal drop exit
   endcase
;
: sve-int-imm   ( -- )
   19 2bits case
      0 of   sve-int-add-imm  endof
      1 of   sve-int-max-imm  endof
      2 of   ." mul" op-col  sz .ze, 5 8 sxbits .imm  endof
      3 of   sve-dup-imm  endof
   endcase
;
   
: sve-sat-inc-vec-pred   ( -- )
   9 2bits 2 <<  16 2bits or case
      0 of   ." sqincp"   endof
      1 of   ." uqincp"   endof
      2 of   ." sqdecp"   endof
      3 of   ." uqdecp"   endof
   endcase
   op-col  sz .zp
;
: sve-sat-inc-reg-pred   ( -- )
   16 2bits case
      0 of   ." sqincp"   endof
      1 of   ." uqincp"   endof
      2 of   ." sqdecp"   endof
      3 of   ." uqdecp"   endof
   endcase
   .Xd,  .Pn.x
   10 1bit 0= if  ., .Wn  then
;
: sve-inc-vec-pred    ( -- )
   9 2bits 1 << 16 1bit or case
      0 of   ." incp"    endof
      1 of   ." decp"    endof
      illegal drop exit
   endcase
   op-col  sz .zp
;
: sve-inc-reg-pred    ( -- )
   9 2bits 1 << 16 1bit or case
      0 of   ." incp"    endof
      1 of   ." decp"    endof
      illegal drop exit
   endcase
   op-col  .Xd,  sz .Pn.x
;
: sve-pred-cnt   ( -- )
   18 1bit 2*  11 1bit or  case
      0 of   sve-sat-inc-vec-pred   endof
      1 of   sve-sat-inc-reg-pred   endof
      2 of   sve-inc-vec-pred       endof
      3 of   sve-inc-reg-pred       endof
      illegal drop exit
   endcase
;
: sve-cdot   ( -- )
   ." cdot"   op-col  22 1bit .zzz-flong ., 10 2bits .square
;
: sve-int-dot   ( -- )
   10 2bits case
      0 of   ." sdot"       op-col  22 1bit  .zzz-flong  endof
      1 of   ." udot"       op-col  22 1bit  .zzz-flong  endof
      2 of   ." sqdmlalbt"  op-col  sz  .zzz-long  endof
      3 of   ." sqdmlslbt"  op-col  sz  .zzz-long  endof
   endcase   
;
: sve-int-cmad
   12 1bit if  ." sqrdcmlah"  else  ." cmla"  then  op-col  sz .zzz  ., 10 2bits .square
;
: sve-mixed-dot   ( -- )
   ." usdot"  op-col  0 .zzz-flong
;
: sve-int-mad   ( -- )
   10 5bits case
      1x0" 0000x" af   sve-int-dot      endaf
      \ 1x0" 0001x" af   sve-sat-mad-il   endaf
      1x0" 001xx" af   sve-cdot         endaf
      1x0" 01xxx" af   sve-int-cmad     endaf
      \ 1x0" 10xxx" af   sve-int-madl     endaf
      \ 1x0" 110xx" af   sve-sat-madl     endaf
      \ 1x0" 1110x" af   sve-sat-madh     endaf
      1x0" 11110" af   sve-mixed-dot    endaf
      illegal
   endcase
;
: sve-int-unaryp
   18 1bit 2 << sz or  case
      0 of   ." urecpe"   op-col   2 .zpz  endof
      1 of   ." ursqrte"  op-col   2 .zpz  endof
      4 of   ." sqabs"    op-col  sz .zpz  endof
      5 of   ." sqsub"    op-col  sz .zpz  endof
      illegal
   endcase
;
: sve-srshl
   16 4bits case
       0 of    ." srashl"   endof
       2 of    ." srshl"    endof
       3 of    ." urshl"    endof
       6 of    ." srshlr"   endof
       7 of    ." urshlr"   endof
       8 of    ." sqshl"    endof
       9 of    ." uqshl"    endof
       10 of   ." sqrshl"   endof
       11 of   ." uqrshl"   endof
       12 of   ." sqshlr"   endof
       13 of   ." uqshlr"   endof
       14 of   ." sqrshlr"  endof
       15 of   ." uqrshlr"  endof
      illegal drop exit
    endcase
    op-col  sz .zpez
;
: sve-int-pair
   16 3bits  case
      1 of   ." addp"  endof
      4 of   ." smaxp"  endof
      5 of   ." umaxp"  endof
      6 of   ." sminp"  endof
      7 of   ." uminp"  endof
      illegal drop exit
   endcase
   op-col  sz .zpez
;
: sve-sqadd
   16 3bits  case
      0 of   ." sqadd"   endof
      1 of   ." uqadd"   endof
      2 of   ." sqsub"   endof
      3 of   ." uqsub"   endof
      4 of   ." suqadd"  endof
      5 of   ." usqadd"  endof
      6 of   ." sqsubr"  endof
      7 of   ." uqsubr"  endof
   endcase
   op-col  sz .zpez
;
: sve2-intp   ( -- )
   17 4bits 1 << 13 1bit or case
      1x0" 0x0x_1" af   sve-int-unaryp   endaf
      1x0" 0xxx_0" af   sve-srshl        endaf
      1x0" 10xx_1" af   sve-int-pair     endaf
      1x0" 11xx_0" af   sve-sqadd        endaf
      illegal drop exit
   endcase
;

: sve-clamp   ( -- )
   10 1bit if  ." uclamp"   else  ." sclamp"  then
   op-col  sz .zzze
;
: sve-int-dot-ind    ( -- )
   10 1bit if  ." udot"  else  ." sdot"  then
   op-col sz .z>>zz[]
;
: sve-int-mad-ind    ( -- )
  10 1bit if  ." mls"  else  ." mla"  then
  op-col sz .zzz[]
;
: sve-sat-madh-ind   ( -- )
  10 1bit if  ." sqrdmlsh"  else  ." sqrdmlah"  then
  op-col sz .zzz[]
;
: sve-mix-dot-ind    ( -- )
   10 1bit if  ." sudot"  else  ." usdot"  then
   op-col 2 .z>>zz[]
;
: sve-sat-mad-ind    ( -- )
   12 1bit 2* 10 1bit or case
     0 of  ." sqdmlalb"  endof
     1 of  ." sqdmlalt"  endof
     2 of  ." sqdmlslb"  endof
     3 of  ." sqdmlslt"  endof
  endcase
  op-col sz .z>zz[]
;
: sve-int-cdot-ind   ( -- )
   ." cdot" op-col  sz .z>>zz[] ., 10 2bits .square
;
: sve-int-cmad-ind   ( -- )
   ." cmla" op-col  sz 1- .zzz-c[] ., 10 2bits .square   
;
: sve-sat-cmad-ind   ( -- )
   ." sqrdcmlah" op-col  sz 1- .zzz-c[] ., 10 2bits .square   
;
: sve-int-madl-ind   ( -- )
   12 2bits 2* 10 1bit or  case
     0 of  ." smlalb"  endof
     1 of  ." smlalt"  endof
     2 of  ." umlalb"  endof
     3 of  ." umlalt"  endof
     4 of  ." smlslb"  endof
     5 of  ." smlslt"  endof
     6 of  ." umlslb"  endof
     7 of  ." umlslt"  endof
  endcase
  op-col  sz .z>zz[]
;
: sve-int-mull-ind   ( -- )
   12 1bit  2* 10 1bit or  case
     0 of  ." smullb"  endof
     1 of  ." smullt"  endof
     2 of  ." umullb"  endof
     3 of  ." umullt"  endof
  endcase
  op-col  sz .z>zz[]
;
: sve-sat-mul-ind    ( -- )
   10 1bit if   ." sqdmullt"  else  ." sqdmullb"  then
   op-col  sz .z>zz[]
;

: sve-sat-mulh-ind   ( -- )
   10 1bit if   ." sqrdmulh"  else  ." sqdmulh"  then
   op-col  sz .zzz[]
;
: sve-int-mul-ind    ( -- )
   ." mul" op-col  sz .zzz[]
;
: sve-mul-ind   ( -- )
   10 6bits case
      1x0" 00000x"  af    sve-int-dot-ind    endaf
      1x0" 00001x"  af    sve-int-mad-ind    endaf
      1x0" 00010x"  af    sve-sat-madh-ind   endaf
      1x0" 00011x"  af    sve-mix-dot-ind    endaf
      1x0" 001xxx"  af    sve-sat-mad-ind    endaf
      1x0" 0100xx"  af    sve-int-cdot-ind   endaf
      1x0" 0110xx"  af    sve-int-cmad-ind   endaf
      1x0" 0111xx"  af    sve-sat-cmad-ind   endaf
      1x0" 10xxxx"  af    sve-int-madl-ind   endaf
      1x0" 110xxx"  af    sve-int-mull-ind   endaf
      1x0" 1110xx"  af    sve-sat-mul-ind    endaf
      1x0" 11110x"  af    sve-sat-mulh-ind   endaf
      1x0" 11111x"  af    sve-int-mul-ind    endaf
   endcase
;

: sve-eorbt   ( -- )
   10 1bit if   ." eortb"  else  ." eorbt"  then
   op-col  sz .zzz
;
: sve-mmla   ( -- )
   sz case
      0 of   ." smmla"   endof
      2 of   ." usmmla"  endof
      3 of   ." ummla"   endof
      illegal drop exit
   endcase
   op-col  2 .z>>zz   \ XXX check regs!  s b b ?   
;
: sve-bitpermute   ( -- )
   10 2bits case
      0 of   ." bext"   endof
      1 of   ." bdep"  endof
      2 of   ." bgrp"   endof
      illegal drop exit
   endcase
   op-col  sz .zzz
;
: sve-misc   ( -- )   \ skip SVE2 for now
   23 1bit 4 <<  10 4bits or  case
      \ 1x0" 010xx"  af   sve-shll   endaf
      \ 1x0" x00xx"  af   sve-addl   endaf
      1x0" x010x"  af   sve-eorbt  endaf
      1x0" x0110"  af   sve-mmla   endaf
      1x0" x11xx"  af   sve-bitpermute  endaf
      illegal
   endcase
;
: sve-match   ( -- )
   4 1bit if  ." nmatch"  else  ." match"   then
   op-col   sz .ppzz
;
: sve-histseg   ( -- )
   sz if
      illegal drop exit
   then
   ." histseg"  op-col  0 .zzz
;
: sve-histcnt   ( -- )   ." histcnt"  op-col  sz .zpzz  ;

: sve-crypto-unary   ( -- )
   22 2bits 2 << 10 1bit or case
      0 of   ." aesmc"   endof
      1 of   ." aesimc"   endof
      illegal drop exit
   endcase
   op-col  0 .ze
;
: sve-crypto-destruct   ( -- )
   22 2bits 2 << 16 1bit or 2* 10 1bit or case
      0 of   ." aese"   endof
      1 of   ." aesd"   endof
      illegal drop exit
   endcase
   op-col  0 .zez
;
: sve-crypto-construct   ( -- )
   22 2bits 2 << 10 1bit or case
      1 of   ." rax1"   endof
      illegal drop exit
   endcase
   op-col  3 .zzz
;
: sve-crypto   ( -- )
   16 5bits 2 << 11 2bits or 5 << 5 5bits or case
      1x0" 000_00_00_00000"  af    sve-crypto-unary      endaf
      1x0" 000_1x_00_xxxxx"  af    sve-crypto-destruct   endaf
      1x0" xxx_xx_10_xxxxx"  af    sve-crypto-construct  endaf
      illegal
   endcase
;
: sve-fcmla     ( -- )   ." fcmla"    op-col  sz .zmzz ., 13 2bits .square  ;
: sve-fcadd     ( -- )   ." fcadd"    op-col  sz .zpez ., 16 1bit 2* 1+ .square  ;
: sve-faddp     ( -- )   ." faddp"    op-col  sz .zpez  ;
: sve-fp-cvt    ( -- )
   sz 2 << 16 2bits or  case
      2 of   ." fcvtxnt"  op-col  3 .zp<z   endof
      8 of   ." fcvtnt"   op-col  2 .zp<z   endof
      9 of   ." fcvtlt"   op-col  2 .zp>z   endof
      10 of  ." bfcvtnt"  op-col  2 .zp<z   endof
      14 of  ." fcvtnt"   op-col  3 .zp<z   endof
      15 of  ." fcvtlt"   op-col  3 .zp>z   endof
      illegal drop exit
   endcase
;
: sve-fp-mad-ind   ( -- )
   10 1bit if  ." fmls"  else  ." fmla"  then  op-col  sz .zzz[] 
;
: sve-fp-cmad-ind   ( -- )
   ." fcmla"  op-col   sz 1- .zzz-c[] ., 10 2bits .square
;
: sve-fp-mul-ind   ( -- )   ." fmul"    op-col  sz .zzz[]  ;
: sve-fp-clamp   ( -- )     ." fclamp"  op-col  sz .zzz  ;
: sve-fp-wmad-ind   ( -- )
   sz 4 << 10 4bits or case
      1x0" 00_0000"  af  ." fdot"      endaf
      1x0" 01_0000"  af  ." bfdot"     endaf
      1x0" 10_00x0"  af  ." fmlalb"    endaf
      1x0" 10_00x1"  af  ." fmlalt"    endaf
      1x0" 10_10x0"  af  ." fmlslb"    endaf
      1x0" 10_10x1"  af  ." fmlslt"    endaf
      1x0" 11_00x0"  af  ." bfmlalb"   endaf
      1x0" 11_00x1"  af  ." bfmlalt"   endaf
      1x0" 10_10x0"  af  ." bfmlslb"   endaf
      1x0" 10_10x1"  af  ." bfmlslt"   endaf
      illegal drop exit
   endcase
   op-col  2 sz 2 < if .z>zz[]2 else  .z>zz[]  then
;

: sve-fp-wmad   ( -- )
   sz 4 << 10 4bits or case
      1x0" 00_0000"  af  ." fdot"      endaf
      1x0" 01_0000"  af  ." bfdot"     endaf
      1x0" 10_0000"  af  ." fmlalb"    endaf
      1x0" 10_0001"  af  ." fmlalt"    endaf
      1x0" 10_1000"  af  ." fmlslb"    endaf
      1x0" 10_1001"  af  ." fmlslt"    endaf
      1x0" 11_0000"  af  ." bfmlalb"   endaf
      1x0" 11_0001"  af  ." bfmlalt"   endaf
      1x0" 11_1000"  af  ." bfmlslb"   endaf
      1x0" 11_1001"  af  ." bfmlslt"   endaf
      illegal drop exit
   endcase
   op-col  2 .z>zz
;
: sve-fp-mma   ( -- )
   sz  case
      1x0" 01"  af  ." bfmmla"  op-col  2        .z>zz  endaf
      1x0" 1x"  af  ." fmmla"   op-col  sz .zzz   endaf
      illegal drop exit
   endcase
;
: sve-fp-math    ( -- )
   10 3bits  case
      0 of  ." fadd"      endof
      1 of  ." fsub"      endof
      2 of  ." fmul"      endof
      3 of  ." ftsmul"    endof
      6 of  ." frecps"    endof
      7 of  ." frsqrts"   endof
      illegal drop exit
   endcase
   op-col  sz .zzz
;
: sve-fp-rec-red    ( -- )
   16 3bits  case
      0 of  ." faddv"    endof
      4 of  ." fmaxnmv"  endof
      5 of  ." fminnmv"  endof
      6 of  ." fmaxv"    endof
      7 of  ." fminv"    endof
      illegal drop exit
   endcase
   op-col  sz .sgz
;
: sve-fp-cmp-vec    ( -- )
   13 3bits 2* 4 1bit or  case
      4 of   ." fcmge"   endof
      5 of   ." fcmgt"   endof
      6 of   ." fcmeq"   endof
      7 of   ." fcmne"   endof
      12 of  ." fcmuo"   endof
      13 of  ." facge"   endof
      15 of  ." facgt"   endof
      illegal drop exit
   endcase
   op-col  sz  .ppzz
;
: sve-fp-mathp-vec   ( -- )
   16 4bits  case
      0 of   ." fadd"    endof
      1 of   ." fsub"    endof
      2 of   ." fmul"    endof
      3 of   ." fsubr"   endof
      4 of   ." fmaxnm"  endof
      5 of   ." fminnm"  endof
      6 of   ." fmax"    endof
      7 of   ." fmin"    endof
      8 of   ." fabd"    endof
      9 of   ." fscale"  endof
      10 of  ." fmulx"   endof
      12 of  ." fdivr"   endof
      13 of  ." fdiv"    endof
      illegal drop exit
   endcase
   op-col  sz .zpez
;
: sve-fp-mathp-imm   ( -- )
   16 3bits  case
      0 of   ." fadd"    op-col  sz .zpe, 5 1bit .fimm1/0.5  endof
      1 of   ." fsub"    op-col  sz .zpe, 5 1bit .fimm1/0.5  endof
      2 of   ." fmul"    op-col  sz .zpe, 5 1bit .fimm2/0.5  endof
      3 of   ." fsubr"   op-col  sz .zpe, 5 1bit .fimm1/0.5  endof
      4 of   ." fmaxnm"  op-col  sz .zpe, 5 1bit .fimm1/0  endof
      5 of   ." fminnm"  op-col  sz .zpe, 5 1bit .fimm1/0  endof
      6 of   ." fmax"    op-col  sz .zpe, 5 1bit .fimm1/0  endof
      7 of   ." fmin"    op-col  sz .zpe, 5 1bit .fimm1/0  endof
      illegal drop exit
   endcase
;
: sve-fp-mathp   ( -- )
   19 2bits 7 << 6 7bits or  case
      1x0" 0x_xxxxxxx"  af  sve-fp-mathp-vec  endaf
      1x0" 11_xxx0000"  af  sve-fp-mathp-imm  endaf
      1x0" 10_000xxxx"  af  ." ftmad"  op-col  16 3bits  sz .zezc  endaf
      illegal drop exit
   endcase
;
: sve-fp-mathp-pair   ( -- )
   16 3bits  case
      0 of   ." faddp"    endof
      4 of   ." fmaxnmp"  endof
      5 of   ." fminnmp"  endof
      6 of   ." fmaxp"    endof
      7 of   ." fminp"    endof
      illegal drop exit
   endcase
   op-col  sz .zpez
;
: sve-fp-unaryp   ( -- )
   sz 5 << 16 5bits or  case
      1x0" xx_00000"  af   ." frintn"    op-col  sz .zpz   endof
      1x0" xx_00001"  af   ." frintp"    op-col  sz .zpz   endof
      1x0" xx_00010"  af   ." frintm"    op-col  sz .zpz   endof
      1x0" xx_00011"  af   ." frintz"    op-col  sz .zpz   endof
      1x0" xx_00100"  af   ." frinta"    op-col  sz .zpz   endof
      1x0" xx_00110"  af   ." frintx"    op-col  sz .zpz   endof
      1x0" xx_00111"  af   ." frinti"    op-col  sz .zpz   endof
      1x0" 00_01010"  af   ." fcvtx"     op-col  3 .zp<z   endof
      1x0" 10_01010"  af   ." bfcvt"     op-col  2 .zp<z   endof
      1x0" 10_01000"  af   ." fcvt"      op-col  2 .zp<z   endof
      1x0" 10_01001"  af   ." fcvt"      op-col  2 .zp>z   endof
      1x0" 11_01000"  af   ." fcvt"      op-col  3 .zp<<z  endof
      1x0" 11_01001"  af   ." fcvt"      op-col  3 .zp>>z  endof
      1x0" 11_01010"  af   ." fcvt"      op-col  3 .zp<z   endof
      1x0" 11_01011"  af   ." fcvt"      op-col  3 .zp>z   endof
      1x0" xx_01100"  af   ." frecpx"    op-col  sz .zpz   endof
      1x0" xx_01101"  af   ." fsqrt"     op-col  sz .zpz   endof
      1x0" 11_10000"  af   ." scvtf"     op-col  3 .zp>z   endof
      1x0" 11_10001"  af   ." ucvtf"     op-col  3 .zp<z   endof
      1x0" 01_10010"  af   ." scvtf"     op-col  1 .zpz    endof
      1x0" 01_10011"  af   ." ucvtf"     op-col  1 .zpz    endof
      1x0" 01_10100"  af   ." scvtf"     op-col  2 .zp<z   endof
      1x0" 01_10101"  af   ." ucvtf"     op-col  2 .zp<z   endof
      1x0" 01_10110"  af   ." scvtf"     op-col  3 .zp<<z  endof
      1x0" 01_10111"  af   ." ucvtf"     op-col  3 .zp<<z  endof
      1x0" 10_10100"  af   ." scvtf"     op-col  2 .zpz    endof
      1x0" 10_10101"  af   ." ucvtf"     op-col  2 .zpz    endof
      1x0" 11_10000"  af   ." scvtf"     op-col  3 .zp>z   endof
      1x0" 11_10001"  af   ." ucvtf"     op-col  3 .zp>z   endof
      1x0" 11_10100"  af   ." scvtf"     op-col  3 .zp<z   endof
      1x0" 11_10101"  af   ." ucvtf"     op-col  3 .zp<z   endof
      1x0" 11_10110"  af   ." scvtf"     op-col  3 .zpz    endof
      1x0" 11_10111"  af   ." ucvtf"     op-col  3 .zpz    endof
      1x0" 00_11xx0"  af   ." flogb"     op-col  17 2bits .zpz   endof
      1x0" 01_11010"  af   ." fcvtzs"    op-col  1 .zpz    endof
      1x0" 01_11011"  af   ." fcvtzu"    op-col  1 .zpz    endof
      1x0" 01_11100"  af   ." fcvtzs"    op-col  2 .zp>z   endof
      1x0" 01_11101"  af   ." fcvtzu"    op-col  2 .zp>z   endof
      1x0" 01_11110"  af   ." fcvtzs"    op-col  3 .zp>>z  endof
      1x0" 01_11111"  af   ." fcvtzu"    op-col  3 .zp>>z  endof
      1x0" 10_11100"  af   ." fcvtzs"    op-col  2 .zpz    endof
      1x0" 10_11101"  af   ." fcvtzu"    op-col  2 .zpz    endof
      1x0" 11_11000"  af   ." fcvtzs"    op-col  3 .zp<z   endof
      1x0" 11_11001"  af   ." fcvtzu"    op-col  3 .zp<z   endof
      1x0" 11_11100"  af   ." fcvtzs"    op-col  3 .zp>z   endof
      1x0" 11_11101"  af   ." fcvtzu"    op-col  3 .zp>z   endof
      1x0" 11_11110"  af   ." fcvtzs"    op-col  3 .zpz    endof
      1x0" 11_11111"  af   ." fcvtzu"    op-col  3 .zpz    endof
      illegal drop exit
   endcase
;
: sve-fp-rec-est   ( -- )
   16 3bits  case
      6 of   ." frecpe"    endof
      7 of   ." frsqrte"   endof
      illegal drop exit
   endcase
   op-col  sz .zz 
;
: sve-fp-cmp0   ( -- )
   16 2bits 2* 4 1bit or  case
      0 of   ." fcmge"    endof
      1 of   ." fcmgt"    endof
      2 of   ." fcmlt"    endof
      3 of   ." fcmle"    endof
      4 of   ." fcmeq"    endof
      6 of   ." fcmne"    endof
      illegal drop exit
   endcase
   op-col  sz .ppz, ." #0.0"
;
: sve-fp-mad   ( -- )
   13 3bits  case
      0 of   ." fmla"    op-col  sz .zmzz   endof
      1 of   ." fmls"    op-col  sz .zmzz   endof
      2 of   ." fnmla"   op-col  sz .zmzz   endof
      3 of   ." fnmls"   op-col  sz .zmzz   endof
      4 of   ." fmad"    op-col  sz .zdpnm  endof
      5 of   ." fmsb"    op-col  sz .zdpnm  endof
      6 of   ." fnmad"   op-col  sz .zdpnm  endof
      7 of   ." fnmsb"   op-col  sz .zdpnm  endof
      illegal drop exit
   endcase
;

: sve-fadda     ( -- )   ." fadda"    op-col  sz .spez  ;

: ldst-imm   ( -- n )   16 6bits 3 << 10 3bits or  23 << 23 >>a  ;

: sve-ldst     ( -- )
   29 2bits case
      0 of   ." ldr"  endof
      3 of   ." str"  endof
      illegal drop exit
   endcase
   op-col   14 1bit if  .Zd,  else  .Pd,  then
   .[xn|sp ldst-imm ?dup if  ., .imm ., ." mul vl"  then .]
;

: (sve-ldm)   ( -- sz n )
   21 4bits dup case
      b# 0001 of   ." ld2b"   endof
      b# 0010 of   ." ld3b"   endof
      b# 0011 of   ." ld4b"   endof
      b# 0101 of   ." ld2h"   endof
      b# 0110 of   ." ld3h"   endof
      b# 0111 of   ." ld4h"   endof
      b# 1001 of   ." ld2w"   endof
      b# 1010 of   ." ld3w"   endof
      b# 1011 of   ." ld4w"   endof
      b# 1101 of   ." ld2d"   endof
      b# 1110 of   ." ld3d"   endof
      b# 1111 of   ." ld4d"   endof
      unimpl drop exit
   endcase
   op-col
   dup 2 >> swap 3 and 1+
;

: sve-ldm-si
   (sve-ldm) dup >r
   rd swap .{zreglist} .p10z, .[xn|sp
   16 4 sxbits ?dup if
      ., r@ * .imm, ." mul vl"
   then
   .]
   r> drop
;
: sve-ldm-ss
   (sve-ldm) over >r
   rd swap .{zreglist} .p10z, .[xn|sp ., .xm
   r> ?dup if
      ., ." lsl " .imm
   then
   .]
;

\ load contiguous
: (sve-ldc)   ( -- sz )
   21 4bits case
      b# 0000 of   ." ld1b"  0 endof
      b# 0001 of   ." ld1b"  1 endof
      b# 0010 of   ." ld1b"  2 endof
      b# 0011 of   ." ld1b"  3 endof
      b# 0100 of   ." ld1sw" 3 endof
      b# 0101 of   ." ld1h"  1 endof
      b# 0110 of   ." ld1h"  2 endof
      b# 0111 of   ." ld1h"  3 endof
      b# 1000 of   ." ld1sh" 3 endof
      b# 1001 of   ." ld1sh" 2 endof
      b# 1010 of   ." ld1w"  2 endof
      b# 1011 of   ." ld1w"  3 endof
      b# 1100 of   ." ld1sb" 3 endof
      b# 1101 of   ." ld1sb" 2 endof
      b# 1110 of   ." ld1sb" 1 endof
      b# 1111 of   ." ld1d"  3 endof
      unimpl exit
   endcase
   op-col
;

\ scalar plus immediate
: sve-ldc-si
   (sve-ldc)  .{ .zd.x .} ., .p10z, .[xn|sp
   16 4 sxbits ?dup if
      ., .imm, ." mul vl"
   then
   .]
;
\ scalar plus scalar
:  lsl#imm ( -- n )     \ 0,1,2,3 = b,h,s,d
   21 4bits case
      b# 0000 of  0 endof
      b# 0001 of  0 endof
      b# 0010 of  0 endof
      b# 0011 of  0 endof
      b# 0100 of  2 endof
      b# 0101 of  1 endof 
      b# 0110 of  1 endof
      b# 0111 of  1 endof
      b# 1000 of  1 endof
      b# 1001 of  1 endof
      b# 1010 of  2 endof
      b# 1011 of  2 endof
      b# 1100 of  0 endof
      b# 1101 of  0 endof
      b# 1110 of  0 endof
      b# 1111 of  3 endof
   endcase
;

: sve-ldc-ss
   (sve-ldc)  .{ .zd.x .} ., .p10z, .[xn|sp ., .xm
   lsl#imm dup if  ., ." lsl #" . else drop then
   .]
;

: (sve-ld1ro)
   23 2bits case
      0 of  ." ld1rob"    endof
      1 of  ." ld1roh"    endof
      2 of  ." ld1row"    endof
      3 of  ." ld1rod"    endof
   endcase
   op-col
   ;
: (sve-ld1rq)
   23 2bits case
      0 of  ." ld1rqb"    endof
      1 of  ." ld1rqh"    endof
      2 of  ." ld1rqw"    endof
      3 of  ." ld1rqd"    endof
   endcase
   op-col
   ;
: sve-ld1-ss
   .{ 23 2bits .zd.x .} ., .p10z, .[xn|sp ., .xm .]
   ;
: sve-ld1ro/q-ss
   .{ 23 2bits .zd.x .} ., .p10z, .[xn|sp ., .xm
   23 2bits ?dup if  ., ." lsl #" . then  .]
   ;

: sve-ld1-si ( mul -- )
   .{ 23 2bits .zd.x .} ., .p10z, .[xn|sp
   16 4 sxbits ?dup if  ., * .imm  else  drop  then  .]
   ;

: (sve-ldnt) ( -- )
   23 2bits case
      0 of  ." ldnt1b"    endof
      1 of  ." ldnt1h"    endof
      2 of  ." ldnt1w"    endof
      3 of  ." ldnt1d"    endof
   endcase
   op-col
   ;
: (sve-ldnf) ( -- )
   23 2bits case
      0 of  ." ldnf1b"    endof
      1 of  ." ldnf1h"    endof
      2 of  ." ldnf1w"    endof
      3 of  ." ldnf1d"    endof
   endcase
   op-col
   ;
: (sve-ldnfs) ( -- )
   23 2bits case
      1 of  ." ldnf1sw"    endof
      2 of  ." ldnf1sh"    endof
      3 of  ." ldnf1sb"    endof
      unimpl
   endcase
   op-col
   ;
: sve-ldnt-si ( -- )
   .{ 23 2bits .zd.x .} ., .p10z, .[xn|sp
   16 4 sxbits ?dup if  ., .imm  ." , mul vl" then  .]
   ;

: sve-ldnf(s) ( xor -- )
   dup if  (sve-ldnfs)  else  (sve-ldnf)  then
   .{ 21 2bits swap xor .zd.x .} ., .p10z, .[xn|sp
   16 4 sxbits ?dup if  ., .imm ." , mul vl" then  .]
   ;

: sve-ldnf(s)-si
   21 4bits case
      1x0" 0100" af  3 sve-ldnf(s)  endaf
      1x0" 0xxx" af  0 sve-ldnf(s)  endaf
      1x0" 1111" af  0 sve-ldnf(s)  endaf
      1x0" 101x" af  0 sve-ldnf(s)  endaf
      1x0" 1xxx" af  3 sve-ldnf(s)  endaf
   endcase
   ;

: (sve-ldff) ( -- )
   23 2bits case
      0 of  ." ldff1b"    endof
      1 of  ." ldff1h"    endof
      2 of  ." ldff1w"    endof
      3 of  ." ldff1d"    endof
   endcase
   op-col
   ;
: (sve-ldffs-ss) ( -- )
   23 2bits case
      1 of  ." ldff1sw"    endof
      2 of  ." ldff1sh"    endof
      3 of  ." ldff1sb"    endof
      unimpl
   endcase
   op-col
   ;
: (sve-ldffs) ( -- )
   23 2bits case
      0 of  ." ldff1sb"    endof
      1 of  ." ldff1sh"    endof
      2 of  ." ldff1sw"    endof
      unimpl
   endcase
   op-col
   ;
: sve-ldff-ss ( xor -- )
   dup >r if (sve-ldffs-ss) else (sve-ldff) then
   .{ 21 2bits r@ xor .zd.x .} ., .p10z, .[xn|sp
   16 5bits 31 <>  if
      ., .xm 23 2bits r@ xor ?dup  if  ., ." lsl #" .   then
  then
  .] r> drop
  ;

: sve-ldff(s)-ss
   21 4bits case
      1x0" 0100" af  3 sve-ldff-ss  endaf
      1x0" 0xxx" af  0 sve-ldff-ss  endaf
      1x0" 1111" af  0 sve-ldff-ss  endaf
      1x0" 101x" af  0 sve-ldff-ss  endaf
      1x0" 1xxx" af  3 sve-ldff-ss  endaf
      unimpl
   endcase
   ;

: sve-contig-ld   ( -- )
   20 3bits 3 << 13 3bits or case
      1x0" 00x000" af   (sve-ld1rq) sve-ld1ro/q-ss  endaf
      1x0" 000001" af   (sve-ld1rq) 16 sve-ld1-si   endaf
      1x0" 01x000" af   (sve-ld1ro) sve-ld1ro/q-ss  endaf
      1x0" 010001" af   (sve-ld1ro) 32 sve-ld1-si   endaf
      1x0" 00x110" af   (sve-ldnt)  sve-ld1ro/q-ss  endaf
      1x0" 000111" af   (sve-ldnt)  sve-ldnt-si     endaf
      1x0" xx1101" af   sve-ldnf(s)-si              endaf
      1x0" xxx011" af   sve-ldff(s)-ss              endaf
      1x0" xx0111" af   sve-ldm-si                  endaf
      1x0" xxx110" af   sve-ldm-ss                  endaf
      \ 1x0" xx0001" af   sve-ldbq-si               endaf
      1x0" xx0101" af   sve-ldc-si                  endaf
      \ 1x0" xxx000" af   sve-ldbq-ss               endaf
      1x0" xxx010" af   sve-ldc-ss                  endaf
      unimpl
   endcase
;
: sve-str-p
   ." str"  op-col  .Pd, .[xn|sp
   zimm9 ?dup if  .,  9 sext .imm ." , mul vl"
   then  .]
;
: sve-str-z
   ." str"  op-col  .Zd, .[xn|sp
   zimm9 ?dup if  .,  9 sext .imm ." , mul vl"
   then  .]
;
: sve-contig-ss
   21 4bits case
      1x0" 00xx" af  ." st1b"  endaf
      1x0" 01xx" af  ." st1h"  endaf
      1x0" 10xx" af  ." st1w"  endaf
      1x0" 1111" af  ." st1d"  endaf
      illegal
   endcase
   op-col  .{ 21 2bits .Zd.x .} ., .p10, .[xn|sp ., .xm
   23 2bits ?dup if   ." , lsl #" .  then  .]
;
: sve-contig-st-uc   ( -- )
   22 3bits 1 << 14 1bit or 1 << 4 1bit or  case
      1x0" 11000" af   sve-str-p       endaf
      1x0" 1101x" af   sve-str-z       endaf
      1x0" xxx1x" af   sve-contig-ss   endaf
      unimpl
   endcase
;

: (sve-scatter)
   23 2bits case
      0 of  ." st1b"  endof
      1 of  ." st1h"  endof
      2 of  ." st1w"  endof
      3 of  ." st1d"  endof
    endcase
    op-col
;
: (sve-stnt)
   23 2bits case
      0 of  ." stnt1b"  endof
      1 of  ." stnt1h"  endof
      2 of  ." stnt1w"  endof
      3 of  ." stnt1d"  endof
    endcase
    op-col
;

: sve-nt-mr-st
   (sve-stnt)
    22 1bit if  2  else  3  then  dup
    .{ .Zd.x .} ., .p10, ." [" .Zn.x
    16 5bits 31 <> if
    	., .Xm
    then
    ." ]"
;

: sve-scatter-se
   (sve-scatter)
    22 1bit if  2  else  3  then  dup
    .{ .Zd.x .} ., .p10, .[xn|sp ., .Zm.x
    21 1bit if
    	\ scaled
    	13 1bit 0= if
    		14 1bit if ." , sxtw " else ." , uxtw " then
    		23 2bits ?dup if  ." #" .d then
    	else
    		23 2bits ?dup if ., ." lsl #" .d then
    	then
    else
    	\ unscaled
    	13 1bit 0= if
    		14 1bit if ."  , sxtw" else ." , uxtw" then
    	then
    then
    .]
;

: sve-scatter
   (sve-scatter)
    21 1bit if  2  else  3  then  dup
    .{ .Zd.x .} ., .p10, .[ .Zn.x
    16 5bits ?dup if  .,  1 23 2bits <<  * .imm  then
    .]
;

: (sve-stm)   ( -- sz n )
   21 4bits dup case
      b# 0001 of   ." st2b"   endof
      b# 0010 of   ." st3b"   endof
      b# 0011 of   ." st4b"   endof
      b# 0101 of   ." st2h"   endof
      b# 0110 of   ." st3h"   endof
      b# 0111 of   ." st4h"   endof
      b# 1001 of   ." st2w"   endof
      b# 1010 of   ." st3w"   endof
      b# 1011 of   ." st4w"   endof
      b# 1101 of   ." st2d"   endof
      b# 1110 of   ." st3d"   endof
      b# 1111 of   ." st4d"   endof
      unimpl drop exit
   endcase
   op-col
   dup 2 >> swap 3 and 1+
;

: sve-stm-si
   (sve-stm) dup >r
   rd swap .{zreglist} .p10, .[xn|sp
   16 4 sxbits ?dup if
      ., r@ * .imm, ." mul vl"
   then
   .]
   r> drop
;
: sve-stm-ss
   (sve-stm) over >r
   rd swap .{zreglist} .p10, .[xn|sp ., .xm
   r> ?dup if
      ., ." lsl " .imm
   then
   .]
;

\ store contiguous
: (sve-stc)   ( -- sz )
   21 4bits case
      b# 0000 of   ." st1b"  0 endof
      b# 0001 of   ." st1b"  1 endof
      b# 0010 of   ." st1b"  2 endof
      b# 0011 of   ." st1b"  3 endof
      b# 0101 of   ." st1h"  1 endof
      b# 0110 of   ." st1h"  2 endof
      b# 0111 of   ." st1h"  3 endof
      b# 1010 of   ." st1w"  2 endof
      b# 1011 of   ." st1w"  3 endof
      b# 1111 of   ." st1d"  3 endof
      unimpl exit
   endcase
   op-col
;

\ scalar plus immediate
: sve-stc-si
   (sve-stc)  .{ .zd.x .} ., .p10, .[xn|sp
   16 4 sxbits ?dup if
      ., .imm, ." mul vl"
   then
   .]
;
\ scalar plus scalar
: sve-stc-ss
   (sve-stc)  .{ .zd.x .} ., .p10, .[xn|sp ., .xm
   23 2bits ?dup if
      ., ." lsl " .imm
   then
   .]
;
: (sve-st)
   23 2bits case
      0 of  ." st1b"    endof
      1 of  ." st1h"    endof
      2 of  ." st1w"    endof
      3 of  ." st1d"    endof
   endcase
   op-col
   ;
: sve-sc32
   (sve-st)
   22 1bit if
      .{ .Zd.s .} ., .p10g ., .[xn|sp ., .Zm.s .,
   else
      .{ .Zd.d .} ., .p10g ., .[xn|sp ., .Zm.d .,
   then
   14 1bit if ." sxtw"  else  ." uxtw"  then
   21 1bit if  space 23 2bits .imm  then
   .]
   ;
: sve-sc64
   (sve-st)
   .{ .Zd.d .} ., .p10g ., .[xn|sp ., .Zm.d
   21 1bit if
      23 2bits ?dup if  ." , lsl " .imm  then
   then
   .]
   ;

: sve-stnt-vs
   (sve-stnt) .{ 3 22 1bit - dup .zd.x  .} ., .p10, .[ .zn.x 16 5bits if  ., .xm  then  .]
;
: sve-stnt-ss
   (sve-stnt) .{ 23 2bits .zd.x .} ., .p10, .[xn|sp  ., .xm  23 2bits ?dup if  ., ." lsl " .imm  then .]
;
: sve-stnt-si
   (sve-stnt) .{ 23 2bits .zd.x .} ., .p10, .[xn|sp 16 4 sxbits ?dup if
      ., .imm, ." mul vl"
   then
   .]
;

: sve-contig-st-imm   ( -- )
   20 3bits 3 << 13 3bits or case
      1x0" x00001" af   sve-stnt-vs   endaf
      1x0" 00x011" af   sve-stnt-ss   endaf
      1x0" 001111" af   sve-stnt-si   endaf
      1x0" xx1111" af   sve-stm-si    endaf
      1x0" xxx011" af   sve-stm-ss    endaf
      1x0" xx0111" af   sve-stc-si    endaf
      1x0" xxx010" af   sve-stc-ss    endaf
      1x0" xxx1x0" af   sve-sc32      endaf
      1x0" xxx101" af   sve-sc64      endaf
      unimpl drop
   endcase
;

\ LD1x scalar plus vector comes in 6 flavors:
\ 32bit scaled, 32bit unpacked scaled, 32bit unpaced unscaled, 32bit unscaled
\ 64bit scaled, 64bit unscaled
: (sve-ga32)
   23 2bits 2 << 13 2bits or  case
      b# 0000 of   ." ld1sb"  endof
      b# 0010 of   ." ld1b"   endof
      b# 0100 of   ." ld1sh"  endof
      b# 0110 of   ." ld1h"   endof
      b# 1000 of   ." ld1sw"  endof
      b# 1010 of   ." ld1w"   endof
      unimpl
   endcase
   op-col .{ 30 1bit if .zd.d  else .zd.s then .} ., .p10z, 
;
\ prefetch
: sve-prfop,
   0 4bits case
      0 of   ." PLDL1KEEP"  endof
      1 of   ." PLDL1STRM"  endof
      2 of   ." PLDL2KEEP"  endof
      3 of   ." PLDL2STRM"  endof
      4 of   ." PLDL3KEEP"  endof
      5 of   ." PLDL3STRM"  endof
      8 of   ." PSTL1KEEP"  endof
      9 of   ." PSTL1STRM"  endof
      10 of  ." PSTL2KEEP"  endof
      11 of  ." PSTL2STRM"  endof
      12 of  ." PSTL3KEEP"  endof
      13 of  ." PSTL3STRM"  endof
      ." 0x" dup .h
   endcase
   .,
;
: (sve-prf)   ( sz -- )
   case
      0 of  ." prfb"  endof
      1 of  ." prfh"  endof
      2 of  ." prfw"  endof
      3 of  ." prfd"  endof
   endcase
   op-col    sve-prfop, .p10,
;
: sve-ga32-prf
   13 2bits (sve-prf)  .[xn|sp ., .zm.s, 
   22 1bit if  ." sxtw"  else  ." uxtw"  then
   13 2bits ?dup if  ."  #" .d  then   .]
;
\ prefetch imm
: sve-prfc-si
   13 2bits (sve-prf)  .[xn|sp
   16 6 sxbits ?dup if  ., .imm, ." mul vl"  then  .]
;
: sve-prfc-ss
   23 2bits (sve-prf)  .[xn|sp ., .Xm
   23 2bits ?dup if  ., ." lsl #" .d  then  .]
;
: sve-ga32-prf-vi
   23 2bits (sve-prf)  .[ .Zn.s
   16 5bits ?dup if   ., .imm  then  .]
;
: sve-ga64-prf-sv
   13 2bits (sve-prf)  .[xn|sp ., .Zm.d
   13 2bits ?dup if  ., ." lsl #" .d  then  .]
;
: sve-ga64-prf-32u
   13 2bits (sve-prf)  .[xn|sp ., .Zm.d,
   22 1bit if  ." sxtw"  else  ." uxtw"  then
   13 2bits ?dup if  ."  #" .d  then   .]
;
: sve-ga64-prf-vi
   23 2bits (sve-prf)  .[ .Zn.d
   16 5bits ?dup if   ., .imm  then  .]
;


\ halfword scaled plus 32bit scaled
: sve-ga32-ldh-s32s
   unimpl
;
\ scalar plus 32bit scaled
: sve-ga32-ld-s32s
   (sve-ga32)  .[xn|sp ., 30 1bit if .zm.d, else .zm.s, then
   22 1bit if  ." sxtw"  else  ." uxtw"  then
   23 2bits ?dup if  ." #" .d  then  .]
;

\ scalar plus 32bit unscaled
: sve-ga32-ld-su32
   (sve-ga32)  .[xn|sp ., .zm.s,
   22 1bit if  ." sxtw"  else  ." uxtw"  then
   21 1bit if  space 23 2bits .imm  then  .]
;
\ scalar plus vector imm
: sve-ga32-ld-vi
   (sve-ga32)  .[ .zn.s   16 5bits ?dup if ., 1 23 2bits << *  .imm   then  .]
;

: (sve-ld1r)
   23 2bits case
      0 of  ." ld1rb"  endof
      1 of  ." ld1rh"  endof
      2 of  ." ld1rw"  endof
      3 of  ." ld1rd"  endof
   endcase
   op-col
;
: sve-ld1r
   (sve-ld1r) .{ 13 2bits .Zd.x .} ., .p10z, .[xn|sp
   16 6bits ?dup if ., 1 23 2bits << * .imm then .]
   ;

: (sve-ld1rs)
   23 2bits case
      1 of  ." ld1rsw"  endof
      2 of  ." ld1rsh"  endof
      3 of  ." ld1rsb"  endof
      unimpl
   endcase
   op-col ;
: sve-ld1rs
   (sve-ld1rs) .{ 3 13 2bits - .Zd.x .} ., .p10z, .[xn|sp
   16 6bits ?dup if ., 1 23 2bits 3 xor << * .imm then .]
   ;

: sve-ld1r(s)
   23 2bits 3 << 13 3bits or case
      1x0" 1_1111" af   sve-ld1r           endaf
      1x0" 0_1100" af   sve-ld1rs          endaf
      1x0" 1_011x" af   sve-ld1r           endaf
      1x0" 1_010x" af   sve-ld1rs          endaf
      1x0" 1_1xxx" af   sve-ld1rs          endaf
      1x0" 0_x1xx" af   sve-ld1r           endaf
   endcase
;

: (sve-ldnts) ( -- )
   23 2bits case
      0 of  ." ldnt1sb"    endof
      1 of  ." ldnt1sh"    endof
      2 of  ." ldnt1sw"    endof
      unimpl
   endcase
   op-col
   ;
: sve-ldnt(s)-vs
   13 3bits 4 <> if  (sve-ldnt)  else  (sve-ldnts)  then
   .{ 30 2bits dup .zd.x .} ., .p10z, .[ .zn.x 16 5bits 31 <> if ., .xm  then  .]
   ;

: sve-ldff(s)-vi ( -- )
   14 1bit if  (sve-ldff)  else  (sve-ldffs)  then
   .{ 30 2bits dup .zd.x .} ., .p10z, .[ .zn.x 16 5bits ?dup if
      ., 1 23 2bits << * .imm       \  14 1bit 0= if 3 xor then << * .imm
   then  .]
   ;

: sve-ldff(s)-mod ( -- )
   14 1bit if  (sve-ldff)  else  (sve-ldffs)  then
   .{ 30 2bits dup .zd.x  .} ., .p10z, .[xn|sp ., .zm.x,
   22 1bit if  ." sxtw"  else  ." uxtw"  then
   21 1bit if  23 2bits .imm  then .]  	\ 14 1bit 0= if 3 xor then space .imm then  .]
   ;

: sve-ldff(s)-lsl ( -- )
   14 1bit if  (sve-ldff)  else  (sve-ldffs)  then
   .{ .zd.d  .} ., .p10z, .[xn|sp ., .zm.d
   21 1bit if  ., ." lsl " 23 2bits .imm then  .]
   ;

: sve-gather32
   21 4bits 3 << 13 3bits or 2* 4 1bit or case
      1x0" 00x1_0xx0" af   sve-ga32-prf            endaf
      1x0" 00x0_0x1x" af   sve-ldff(s)-mod         endaf
      1x0" 01xx_0x1x" af   sve-ldff(s)-mod         endaf
      1x0" 10xx_011x" af   sve-ldff(s)-mod         endaf
      1x0" 10x0_001x" af   sve-ldff(s)-mod         endaf
      1x0" 10x1_001x" af   sve-ldff(s)-mod         endaf
      1x0" 01x1_0xxx" af   sve-ga32-ld-s32s        endaf 		\ ldh
      1x0" 10x1_0xxx" af   sve-ga32-ld-s32s        endaf
      1x0" 110x_0000" af   sve-ldst                endaf
      1x0" 110x_010x" af   sve-ldst                endaf
      1x0" 111x_0xx0" af   sve-prfc-si             endaf
      1x0" xx00_10xx" af   sve-ldnt(s)-vs          endaf
      1x0" xx00_1100" af   sve-prfc-ss             endaf
      1x0" xx00_1110" af   sve-ga32-prf-vi         endaf
      1x0" xx01_1x1x" af   sve-ldff(s)-vi          endaf
      1x0" xx01_1x0x" af   sve-ga32-ld-vi          endaf
      1x0" xx1x_1xxx" af   sve-ld1r(s)             endaf
      1x0" xxx0_0xxx" af   sve-ga32-ld-su32        endaf
      unimpl
   endcase
;

\ gather64
: (sve-ga64)
  23 2bits 2 << 13 2bits or  case
      b# 0000 of   ." ld1sb"  endof
      b# 0010 of   ." ld1b"   endof
      b# 0100 of   ." ld1sh"  endof
      b# 0110 of   ." ld1h"   endof
      b# 1000 of   ." ld1sw"  endof
      b# 1010 of   ." ld1w"   endof
      b# 1110 of   ." ld1d"   endof
      unimpl
   endcase
   op-col  .{ .zd.d .} ., .p10z,
;
\ scalar plus 64bit scaled
: sve-ga64-ld-s64s
   (sve-ga64)  .[xn|sp ., .zm.d,  
   23 2bits ?dup if  ." lsl " .imm  then    .]
;
\ scalar plus 32bit unscaled
: sve-ga64-ld-s32us
   (sve-ga64)  .[xn|sp ., .zm.d,
   22 1bit if  ." sxtw"  else  ." uxtw"  then
   21 1bit if  space 23 2bits .imm  then  .]
;
\ scalar plus vector imm
: sve-ga64-ld-vi
   (sve-ga64)  .[ .zn.d   16 5bits ?dup if  ., 1 23 2bits << * .imm  then  .]
;
\ scalar plus 64bit unscaled
: sve-ga64-ld-s64u
   (sve-ga64)  .[xn|sp ., .zm.d .]  
;
\ scalar plus unpacked 32bit unscaled
: sve-ga64-ld-su32u
   (sve-ga64)   .[xn|sp ., .zm.d,
   22 1bit if  ." sxtw"  else  ." uxtw"  then  .]
;

: sve-gather64
   21 4bits 3 << 13 3bits or 2* 4 1bit or case
      1x0" 0011_1xx0" af   sve-ga64-prf-sv    endaf
      1x0" 00x1_0xx0" af   sve-ga64-prf-32u   endaf

      1x0" 0xx0_0x1x" af   sve-ldff(s)-mod    endaf
      1x0" 01xx_0x1x" af   sve-ldff(s)-mod    endaf
      1x0" 10xx_0x1x" af   sve-ldff(s)-mod    endaf
      1x0" 11xx_011x" af   sve-ldff(s)-mod    endaf
      1x0" 0010_1x1x" af   sve-ldff(s)-lsl    endaf
      1x0" 011x_1x1x" af   sve-ldff(s)-lsl    endaf
      1x0" 101x_1x1x" af   sve-ldff(s)-lsl    endaf
      1x0" 111x_111x" af   sve-ldff(s)-lsl    endaf
      1x0" xx01_101x" af   sve-ldff(s)-vi     endaf
      1x0" xx01_111x" af   sve-ldff(s)-vi     endaf
      1x0" xx00_1xxx" af   sve-ldnt(s)-vs     endaf

      1x0" xx11_1xxx" af   sve-ga64-ld-s64s   endaf
      1x0" xxx1_0xxx" af   sve-ga64-ld-s32us  endaf
      1x0" xx00_1110" af   sve-ga64-prf-vi    endaf

      1x0" xx01_1xxx" af   sve-ga64-ld-vi     endaf
      1x0" xx10_1xxx" af   sve-ga64-ld-s64u   endaf
      1x0" xxx0_0xxx" af   sve-ga64-ld-su32u  endaf
      unimpl drop
   endcase
;
