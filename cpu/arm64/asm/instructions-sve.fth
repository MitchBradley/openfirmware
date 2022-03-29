\ Scaled Vecotr Extension instructions
\ ~237 instructions

\ we only implement some of SVE. Do we need all of these?

: adclb    0x4500.d000 m.z.sd %zzz  ;
: adclt    0x4500.d400 m.z.sd %zzz  ;
: addpl    0x0460.5000 %addxl  ;
: addvl    0x0420.5000 %addxl  ;
: andv     0x041a.2000 m.bhsd %spz3  ;
: asrd     0x0404.8000 m.z.bhsd %zpe#  ;
: asrr     0x0414.8000 m.z.bhsd %zpez  ;

: bdep     0x4500.b400 m.z.bhsd %zzz  ;
: bext     0x4500.b000 m.z.bhsd %zzz  ;

: bfcvt     0x658a.a000 m.z.h <asm  rd, rd??iop  plm, rn ?rd<rn  asm>  ;
: bfcvtnt   0x648a.a000 m.z.h <asm  rd, rd??iop  plm, rn ?rd<rn  asm>  ;

: bfmmla    0x6460.e400 m.z.s <asm   3long  asm>  ;

: bfdot   ( -- )
   <asm  d>n=m  m.z.s rd??
   [? if  0x6460.4000    2 get-index  19 2 ^^op
   else   0x6460.8000
   then  iop asm>
;

: bfmlalb
   <asm  d>n=m  m.z.s rd??
   [? if  0x64e0.4000  3 get-index dup 1 and 11 ^op 1 >> 19 2 ^^op
   else   0x64e0.8000
   then  iop asm>
;
: bfmlalt
   <asm  d>n=m  m.z.s rd??
   [? if  0x64e0.4400  3 get-index dup 1 and 11 ^op 1 >> 19 2 ^^op
   else   0x64e0.8400
   then  iop asm>
;

: bgrp     0x4500.b800 m.z.bhsd %zzz  ;

: brka    0x2510.4000 m.p.b %brka  ;
: brkb    0x2590.4000 m.p.b %brka  ;

: brkas   0x2550.4000 m.p.b %brkas  ;
: brkbs   0x25d0.4000 m.p.b %brkas  ;

: brkn    0x2518.4000 m.p.b %brkn  ;
: brkns   0x2558.4000 m.p.b %brkn  ;

: brkpa   0x2500.c000 m.p.b %brkpa  ;
: brkpas  0x2540.c000 m.p.b %brkpa  ;
: brkpb   0x2500.c020 m.p.b %brkpa  ;
: brkpbs  0x2540.c020 m.p.b %brkpa  ;

: bsl1n    0x0460.3c00 m.z.d  %zezz  ;
: bsl2n    0x04a0.3c00 m.z.d  %zezz  ;

: cadd     0x4500.d800 m.z.bhsd  <asm (cadd) asm>  ;
: sqcadd   0x4501.d800 m.z.bhsd  <asm (cadd) asm>  ;
: cdot     <asm (cdot) asm>  ;

: clasta   0x0520.8000  %clast  ;
: clastb   0x0521.8000  %clast  ;

: cmla     <asm (cmla) asm>  ;

: cmpeq    0x2400.8000 m.p.bhsd %cmps#  ;
: cmpgt    0x2400.0010 m.p.bhsd %cmps#  ;
: cmpge    0x2400.0000 m.p.bhsd %cmps#  ;
: cmpne    0x2400.8010 m.p.bhsd %cmps#  ;
: cmphi    0x2400.0010 m.p.bhsd %cmpu#  ;
: cmphs    0x2400.0000 m.p.bhsd %cmpu#  ;
: cmplt    0x2400.0000 m.p.bhsd %cmps#r  ;
: cmple    0x2400.0010 m.p.bhsd %cmps#r  ;
: cmplo    0x2400.0000 m.p.bhsd %cmpu#r  ;
: cmpls    0x2400.0010 m.p.bhsd %cmpu#r  ;

: cnot     0x041b.a000 m.z.bhsd %zpz  ;
: cntb   0x0420.e000 m.x  %sve-inc  ;
: cntd   0x04e0.e000 m.x  %sve-inc  ;
: cnth   0x0460.e000 m.x  %sve-inc  ;
: cntp   0x2520.8000 m.x  <asm  rd, rd??iop  px, p.n  rn-mask preg-sz 22 2 ^^op  asm>  ;
: cntw   0x04a0.e000 m.x  %sve-inc  ;

: compact   0x0521.8000 m.z.sd %zpz  ;
: cpy       0x0500.0000 m.z.bhsd %cpy  ;
: ctermeq   0x25a0.2000 m.wx %cterm  ;
: ctermne   0x25a0.2010 m.wx %cterm  ;

: decb   0x0430.e400 m.x  %sve-inc  ;
: decd
   <asm  rd
   rd-mask m.x adt? if  0x04f0.e400 m.x  else  0x04f0.c400 m.z.d  then  %sve-inc
;
: dech
   <asm  rd
   rd-mask m.x adt? if  0x0470.e400 m.x  else  0x0470.c400 m.z.h  then  %sve-inc
;
: decp
   <asm  rd,
   rd-mask m.x adt? if  0x252d.8800 m.x  else  0x252d.8000 m.z.bhsd  then
   rd??iop  p.n  rn-mask preg-sz 22 2 ^^op  asm>
;
: decw
   <asm  rd
   rd-mask m.x adt? if  0x04b0.e400 m.x  else  0x04b0.c400 m.z.s  then  %sve-inc
;

: dupm   <asm  (dupm)  asm>  ;

: eorbt   0x4500.9000 m.z.bhsd %zzz  ;
: eors    0x2540.4200 m.p.b    %pppp  ;
: eortb   0x4500.9400 m.z.bhsd %zzz  ;
: eorv    0x0419.2000 m.bhsd   %spz  ;

: fclamp  0x6420.2400 m.z.hsd  %zzz ;

: fdot   0x6420.0000 m.z.s
   <asm  3long [? if
      0x0000.4000 iop   2 get-index 19 2 ^^op
   else
      0x0000.8000 iop
   then
   asm>
;

: histcnt   0x4520.c000 m.z.sd  <asm  rd, rd??iop  plz,  rn, rm  ?rd=rn=rm  set-zreg-sz   asm>  ;
: histseg   0x4520.a000 m.z.b  %zzz  ;

: incb   0x0430.e000 m.x  %sve-inc  ;
: incd
   <asm  rd
   rd-mask m.x adt? if  0x04f0.e000 m.x  else  0x04f0.c000 m.z.d  then  %sve-inc
;
: inch
   <asm  rd
   rd-mask m.x adt? if  0x0470.e000 m.x  else  0x0470.c000 m.z.h  then  %sve-inc
;
: incp
   <asm  rd,
   rd-mask m.x adt? if  0x252c.8800 m.x  else  0x252c.8000 m.z.bhsd  then
   rd??iop  p.n rn-mask preg-sz 22 2 ^^op  asm>
;
: incw
   <asm  rd
   rd-mask m.x adt? if  0x04b0.e000 m.x  else  0x04b0.c000 m.z.s  then  %sve-inc
;
: index
   <asm  rd, m.z.bhsd rd??  set-zreg-sz
   "#"? if
      5 #simm  5 5 ^^op ","
      "#"? if  5 #simm  16 5 ^^op  0x0420.4000  else  rm  rm-mask ?zd=g  0x0420.4800  then
   else
      rn,
      "#"? if  5 #simm  16 5 ^^op  0x0420.4400  else  rm  rm-mask ?zd=g  ?rn=rm  0x0420.4c00  then
   then  iop
   asm>
;
: insr
   <asm  rd, m.z.bhsd rd??  set-zreg-sz  rn
   rn-mask m.wx adt? if
      0x0524.3800 iop  rn-mask ?zd=g
   else
      0x0534.3800 iop
      rn-mask m.bhsd adt? if
	 rd-mask adt>size rn-mask adt>size <>
      else
	 true
      then  ?invalid-regs
   then
   asm>
;

: lasta   0x0520.8000 m.wxbhsd %last  ;
: lastb   0x0521.8000 m.wxbhsd %last  ;

: ld2b    0x0020.0000 m.z.b 2  %ldn  ;
: ld2h    0x00a0.0000 m.z.h 2  %ldn  ;
: ld2w    0x0120.0000 m.z.s 2  %ldn  ;
: ld2d    0x01a0.0000 m.z.d 2  %ldn  ;

: ld3b    0x0040.0000 m.z.b 3  %ldn  ;
: ld3h    0x00c0.0000 m.z.h 3  %ldn  ;
: ld3w    0x0140.0000 m.z.s 3  %ldn  ;
: ld3d    0x01c0.0000 m.z.d 3  %ldn  ;

: ld4b    0x0060.0000 m.z.b 4  %ldn  ;
: ld4h    0x00e0.0000 m.z.h 4  %ldn  ;
: ld4w    0x0160.0000 m.z.s 4  %ldn  ;
: ld4d    0x01e0.0000 m.z.d 4  %ldn  ;

: ld1sb      0x8400.0000 m.z.hsd %ld1s ;
: ld1sh      0x8480.0000 m.z.sd  %ld1s ;
: ld1sw      0x8500.0000 m.z.d   %ld1s ;


: ld1rb   0x8440.8000 m.z.bhsd 0 %ld1r(s) ;
: ld1rh   0x84c0.8000 m.z.hsd  0 %ld1r(s) ;
: ld1rw   0x8540.8000 m.z.sd   0 %ld1r(s) ;
: ld1rd   0x85c0.8000 m.z.d    0 %ld1r(s) ;
: ld1rsb  0x85c0.8000 m.z.hsd  3 %ld1r(s) ;
: ld1rsh  0x8540.8000 m.z.sd   3 %ld1r(s) ;
: ld1rsw  0x84c0.8000 m.z.d    3 %ld1r(s) ;
: ld1rob  0xa420.0000 m.z.b   32 %ld1ro/q ;
: ld1roh  0xa4a0.0000 m.z.h   32 %ld1ro/q ;
: ld1row  0xa520.0000 m.z.s   32 %ld1ro/q ;
: ld1rod  0xa5a0.0000 m.z.d   32 %ld1ro/q ;
: ld1rqb  0xa400.0000 m.z.b   16 %ld1ro/q ;
: ld1rqh  0xa480.0000 m.z.h   16 %ld1ro/q ;
: ld1rqw  0xa500.0000 m.z.s   16 %ld1ro/q ;
: ld1rqd  0xa580.0000 m.z.d   16 %ld1ro/q ;

: ldnt1b  0x8400.8000 m.z.bhsd   %ldnt1 ;
: ldnt1h  0x8480.8000 m.z.hsd    %ldnt1 ;
: ldnt1w  0x8500.8000 m.z.sd     %ldnt1 ;
: ldnt1d  0x8580.c000 m.z.d      %ldnt1 ;
: ldnt1sb 0x8400.8000 m.z.sd     %ldnt1s ;
: ldnt1sh 0x8480.8000 m.z.sd     %ldnt1s ;
: ldnt1sw 0x8500.8000 m.z.d      %ldnt1s ;
: ldnf1b  0xa410.a000 m.z.bhsd 0 %ldnf1 ;
: ldnf1h  0xa490.a000 m.z.hsd  0 %ldnf1 ;
: ldnf1w  0xa510.a000 m.z.sd   0 %ldnf1 ;
: ldnf1d  0xa590.a000 m.z.d    0 %ldnf1 ;
: ldnf1sb 0xa590.a000 m.z.hsd  3 %ldnf1 ;
: ldnf1sh 0xa510.a000 m.z.sd   3 %ldnf1 ;
: ldnf1sw 0xa490.a000 m.z.d    3 %ldnf1 ;

: ldff1b  0x8400.6000 m.z.bhsd   0 %ldff1(s) ;
: ldff1h  0x8480.6000 m.z.hsd    0 %ldff1(s) ;
: ldff1w  0x8500.6000 m.z.sd     0 %ldff1(s) ;
: ldff1d  0x8580.6000 m.z.d      0 %ldff1(s) ;
: ldff1sb 0x8400.2000 m.z.bhsd   3 %ldff1(s) ;
: ldff1sh 0x8480.2000 m.z.hsd    3 %ldff1(s) ;
: ldff1sw 0x8500.2000 m.z.sd     3 %ldff1(s) ;

: lslr    0x0417.8000 m.z.bhsd %zpez  ;
: lsrr    0x0415.8000 m.z.bhsd %zpez  ;

: st2b       0x0020.0000 m.z.b 2  %stn  ;
: st2h       0x00a0.0000 m.z.h 2  %stn  ;
: st2w       0x0120.0000 m.z.s 2  %stn  ;
: st2d       0x01a0.0000 m.z.d 2  %stn  ;

: st3b       0x0040.0000 m.z.b 3  %stn  ;
: st3h       0x00c0.0000 m.z.h 3  %stn  ;
: st3w       0x0140.0000 m.z.s 3  %stn  ;
: st3d       0x01c0.0000 m.z.d 3  %stn  ;

: st4b       0x0060.0000 m.z.b 4  %stn  ;
: st4h       0x00e0.0000 m.z.h 4  %stn  ;
: st4w       0x0160.0000 m.z.s 4  %stn  ;
: st4d       0x01e0.0000 m.z.d 4  %stn  ;

: stnt1b  0xe400.2000 m.z.bhsd   %stnt1 ;
: stnt1h  0xe480.2000 m.z.hsd    %stnt1 ;
: stnt1w  0xe500.2000 m.z.sd     %stnt1 ;
: stnt1d  0xe580.2000 m.z.d      %stnt1 ;

: mad     0x0400.c000 m.z.bhsd %zpzz  ;
: match   0x4520.8000 m.p.bh   %ppzz  ;

: movprfx
   <asm  rd, reg  dup m.z adt? if   ( n adt )
      drop ^rn
      0x0420.bc00 m.z rd??iop
   else   ( n adt )
      dup m.px adt? 0= " a predicate " ?expecting
      m.p/m adt? if  0x0001.0000 iop  then  10 3 ^^op  ","  rn
      0x0410.2000 m.z.bhsd rd??iop  ?rd=rn  set-zreg-sz 
   then
   asm>
;
: movs
   <asm   rd,  m.p.b rd??   reg   ( rn rn-adt )
   ","? if
      m.p/z adt? 0= ?invalid-regs   10 4 ^^op
      rn  ?rd=rn  0x2540.4000 iop
   else
      is rn-adt ^rn  ?rd=rn  0x25c0.4000 iop
   then
   asm>
;

: msb      0x0400.e000 m.z.bhsd %zpzz  ;

: nand     0x2580.4210 m.p.b %pppp  ;
: nands    0x25c0.4210 m.p.b %pppp  ;
: nbsl     0x04e0.3c00 m.z.d %zezz  ;

: nmatch   0x4520.8010 m.p.bh   %ppzz  ;
: nor      0x2580.4200 m.p.b    %pppp  ;
: nors     0x25c0.4200 m.p.b    %pppp  ;

\ name conflict
: znot
   <asm  rd,  rd-adt m.z.bhsd adt? if
      plm, rn  ?rd=rn  set-zreg-sz  0x041e.a000 iop
   else
      0x2500.4200 m.p.b rd??iop  pza, rn  ?rd=rn
   then
   asm>
;
: nots   0x2540.4200  m.p.b
   <asm  rd, rd??iop  pza, rn  ?rd=rn
   <ra> 0x0f land ^rm  m.p.b is rm-adt
   asm>
;

: orns    0x25c0.4010 m.p.b    %pppp  ;
: orrs    0x25c0.4000 m.p.b    %pppp  ;
: orv     0x0418.2000 m.bhsd   %spz3  ;

: pext   ( -- )
   <asm
   {? if   \ multiple
      getlist  2 <> " a register pair " ?expecting
      ^rd  ","
      0x2520.7410 m.p.bhsd rd??iop
      5 (ph
      1 get-index  8 1 ^^op
   else   ( eq )   \ single
      0x2520.7010 iop
      rd,  m.p.bhsd rd??
      5 (ph
      2 get-index  8 2 ^^op
   then
   set-preg-sz
   asm>
;
: pfalse   0x2518.e400 m.p.b %rd  ;
: pfirst   0x2558.c000 m.p.b %ppe  ;
: pmullb   0x4500.6800 m.z.hdq %z>zz  ;
: pmullt   0x4500.6c00 m.z.hdq %z>zz  ;
: pnext    0x2519.c400 m.p.bhsd %ppe1  ;

: ptest   <asm  0x2550.c000 iop  pa, rn  rn-adt m.p.b adt? 0= ?invalid-regs  asm>   ;
: ptrue
   <asm  rd  m.p.bhsd rd??  set-preg-sz  ,? if
      "," sve-pattern  5 5 ^^op  0x2518.e000 iop
   else
      0x2520.7810 iop
   then
   asm>
;
: ptrues
   0x2519.e000  m.p.bhsd
   <asm  rd  rd??iop  set-preg-sz  ","? if  sve-pattern  else  31  then  5 5 ^^op
   asm>
;

: punpkhi   0x0531.4000 m.p.h  %p>p  ;
: punpklo   0x0530.4000 m.p.h  %p>p  ;
: sunpkhi   0x0531.3800 m.z.hsd  %z>z  ;
: sunpklo   0x0530.3800 m.z.hsd  %z>z  ;
: uunpkhi   0x0533.3800 m.z.hsd  %z>z  ;
: uunpklo   0x0532.3800 m.z.hsd  %z>z  ;

: rdffr
   0x2518.f000 m.p.b
   <asm  rd  rd??iop  ","? if  pzn  else  0x0001.0000 iop  then   asm>
;
: rdffrs   0x2558.f000 m.p.b   <asm  rd,  rd??iop  pzn   asm>  ;

: rdvl    0x04bf.5000 m.x  <asm  rd, rd??iop  6 #simm  5 6 ^^op  asm>  ;

: revb    0x0524.8000  m.z.hsd  %zpz  ;
: revh    0x0525.8000  m.z.sd   %zpz  ;
: revw    0x0526.8000  m.z.d    %zpz  ;
: revd    0x052e.8000  m.z.q  <asm  rd, rd??iop   plm, rn  ?rd=rn  asm>  ;

: saddv   0x0400.2000 m.d  <asm  rd, rd??iop  pl, rm  m.z.bhsd rn?? set-zreg-sz  asm>  ;
: uaddv   0x0401.2000 m.d  <asm  rd, rd??iop  pl, rm  m.z.bhsd rn?? set-zreg-sz  asm>  ;

: sclamp    0x4400.c000 m.z.bhsd %zzz  ;
: uclamp    0x4400.c400 m.z.bhsd %zzz  ;
: sdivr     0x0416.0000 m.z.sd %zpez  ;
: udivr     0x0417.0000 m.z.sd %zpez  ;

: sel
   <asm  rd,
   rd-mask m.z.bhsd adt? if
      0x0520.c000 m.z.bhsd %zpzz2
   else
      0x2500.4210 m.p.b %pppp2
   then
;

: setffr   0x252c.9000 %op  ;

: splice   0x052c.8000 m.z.bhsd %splice  ;

: srshlr   0x4406.8000 m.z.bhsd %zpez  ;
: urshlr   0x4407.8000 m.z.bhsd %zpez  ;

: ssra     0x4500.e000 m.z.bhsd  <asm  2same "," tsz-imm3-hi  asm>   ;
: usra     0x4500.e400 m.z.bhsd  <asm  2same "," tsz-imm3-hi  asm>   ;

: subr
   <asm  rd, reg
   dup m.p/m adt? if  drop 10 3 ^^op  0x0403.0000 m.z.bhsd %zpez  exit  then
   (rn=d) ","  8 #uimm 5 8 ^^op
   ","? if   lsl#8  0x2000 iop  then
   0x2523.c000  iop  asm>
;

: tbl   ( -- )
   <asm  reg is rd-adt  drop
   rd-adt m.z.bhsd adt? if  %tbl-z  exit  then  ( trn2 )
   0x0e00.0000  m.v#b  %tbl
;
: tbx   ( -- )
   <asm  reg is rd-adt  drop
   rd-adt m.z.bhsd adt? if  %tbx-z  exit  then  ( trn2 )
   0x0e00.1000  m.v#b  %tbl
;
: trn1  0 %trn  ;
: trn2  1 %trn  ;

: wrffr     0x2528.9000 m.p.b   <asm  rn  rn??iop  asm>  ;

: whilege   0 %sve-while  ;
: whilegt   1 %sve-while  ;
: whilehi   5 %sve-while  ;
: whilehs   4 %sve-while  ;
: whilele   3 %sve-while  ;
: whilelo   6 %sve-while  ;
: whilels   7 %sve-while  ;
: whilelt   2 %sve-while  ;

: whilerw   0x2520.3010 m.p.bhsd  <asm   rd, rd??iop  xn, xm  set-preg-sz  asm>  ;
: whilewr   0x2520.3000 m.p.bhsd  <asm   rd, rd??iop  xn, xm  set-preg-sz  asm>  ;

: fadda      0x6518.2000 m.hsd   %vpvzn ;
: faddv      0x6500.2000 m.hsd   %vpzn ;

: fsubr      0x6503.8000 m.z.hsd
   <asm rd, rd??iop plm, rn=d,
      #? if
         #fimm=05|10  0x18.0000 iop              \ imm predicate
      else
         rn  ?rd=rn                              \ vector predicate
      then
      set-zreg-sz
   asm>
;

: fdivr      0x650c.8000 m.z.hsd %zpzzn ;

: facgt      0x6500.e010 m.p.hsd %ppzz ;
: facge      0x6500.c010 m.p.hsd %ppzz ;
: facle      0x6500.c010 m.p.hsd %ppzz-s ;      \ alias to facgt with zn and zm swapped
: faclt      0x6500.e010 m.p.hsd %ppzz-s ;      \ alias to facge with zn and zm swapped

: fcmle  0x6500.0000 m.p.hsd
   <asm  pd, rd??iop plz, reg ","
   #? if
       swap ^rn is rn-adt ?pd=zn
       "##" " 0.0" $match? 0= " #0.0" ?expecting
       0x11.2010 iop
   else
      swap ^rm is rm-adt  rn ?pd=zn=zm
      0x4000 iop
   then
   set-preg-sz
   asm>
;
: fcmlt  0x6500.0000 m.p.hsd
   <asm  pd, rd??iop plz, reg ","
   #? if
       swap ^rn is rn-adt ?pd=zn
       "##" " 0.0" $match? 0= " #0.0" ?expecting
       0x11.2000 iop
   else
      swap ^rm is rm-adt  rn ?pd=zn=zm
      0x4010 iop
   then
   set-preg-sz
   asm>
;
: fcmne  0x6500.2000 m.p.hsd
   <asm  pd, rd??iop plz, rn,
   #? if
       ?pd=zn
       "##" " 0.0" $match? 0= " #0.0" ?expecting
       0x13.0000 iop
   else
      rm ?pd=zn=zm
      0x4010 iop
   then
   set-preg-sz
   asm>
;
: fcmuo      0x6500.c000 m.p.hsd %ppzz ;

: fcpy      0x0510.c000 m.z.hsd
   <asm  rd, rd??iop reg ( n adt )
      adt-p/m <> if " Pg/M" expecting then
      16 4 ^^op   set-zreg-sz
      "," #fimm8  5 8 ^^op
  asm>
;

: fcvtlt       0x6489.a000 m.z.sd
   <asm rd, rd??iop plm, rn
      rd-mask zreg-sz 1- rn-mask zreg-sz = not " correct size" ?expecting
      rn-mask m.z.s adt? if 0x42.0000 iop then
   asm>
;
: fcvtnt       0x6488.a000 m.z.hs
   <asm rd, rd??iop plm, rn
      rd-mask zreg-sz 1+ rn-mask zreg-sz = not " correct size" ?expecting
      rn-mask m.z.d adt? if 0x42.0000 iop then
   asm>
;

: fcvtx    0x650a.a000 m.z.s  %fcvtx/nt ;
: fcvtxnt  0x640a.a000 m.z.s  %fcvtx/nt ;

: fdup        0x2539.c000 m.z.hsd  <asm rd, rd??iop set-zreg-sz #fimm8  5 8 ^^op asm> ;
: fexpa       0x0420.b800 m.z.hsd  %zz ;
: flogb       0x6518.a000 m.z.hsd  <asm  rd, rd??iop  plm,  rn  rd-mask zreg-sz 17 2 ^^op asm> ;
: fmad        0x6520.8000 m.z.hsd  %zpmznzm ;

: fmlalb    0x64a0.0000 m.z.s     %fmla/slb/lt ;
: fmlslb    0x64a0.2000 m.z.s     %fmla/slb/lt ;
: fmlalt    0x64a0.0400 m.z.s     %fmla/slb/lt ;
: fmlslt    0x64a0.2400 m.z.s     %fmla/slb/lt ;

: fmmla         0x64a0.e400 m.z.sd
   <asm rd, rd??iop rn, rm ?rd=rn=rm
   rd-mask m.z.d adt? if  0x40.0000 iop then
   asm>
;

: fmov_sve
   <asm reg 2drop "," #? if
      #i.fimm =0.0 if
	 0x2538.c000 m.z.hsd                                         \ dup
	 <asm rd, rd??iop set-zreg-sz #i.fimm 2drop asm>
      else
	 fdup
      then
   else
      reg 2drop "," #i.fimm =0.0 if
	 0x0510.4000 m.z.hsd                                         \ cpy
	 <asm rd, rd??iop reg ( n adt ) adt-p/m <> ?invalid-regs
	 set-zreg-sz 16 4 ^^op "," #i.fimm 2drop asm>
      else
	 fcpy
      then
   then
;
   
: fmsb      0x6520.a000 m.z.hsd  %zpmznzm ;

: fnmad     0x6520.c000 m.z.hsd  %zpmznzm ;
: fnmla     0x6520.4000 m.z.hsd  %zpmznzm ;
: fnmls     0x6520.6000 m.z.hsd  %zpmznzm ;
: fnmsb     0x6520.e000 m.z.hsd  %zpmznzm ;

: fscale    0x6509.8000 m.z.hsd  %zpzzn ;
: ftmad     0x6510.8000 m.z.hsd
   <asm rd, rd??iop rn=d, rn, ?rd=rn set-zreg-sz #uimm3 16 3 ^^op asm> ;

: ftsmul    0x6500.0c00 m.z.hsd  %zzz ;
: ftssel    0x0420.b000 m.z.hsd  %zzz ;

: prfb   0  %prf  ;
: prfh   1  %prf  ;
: prfw   2  %prf  ;
: prfd   3  %prf  ;
