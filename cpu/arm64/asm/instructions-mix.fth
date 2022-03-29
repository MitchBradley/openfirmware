\ instructions with a mix of formats
\ ~145 instructions
\ handled based on Rd type
\ where several formats have the same Rd type, use try

\ Many SVE instructions have the same name as an existing instruction from base, SIMD, or SME.
\ This code tries to fall thru to the old version when Rd is the wrong type for SVE.

\ note: each clause may (implicitly) use <asm to restart the scan

: abs
   <asm  rd 
   rd-mask m.z.bhsd adt? if  0x0416.a000 m.z.bhsd %zpz  exit  then
   0x0e20.b800 m.v#bhsd  0x5ee0.b800 m.d  %2same-nv
;
: add
   <asm  reg nip
   dup m.d      adt? if  drop 0x5E20.8400 m.d       %s3same  exit  then
   dup m.v#bhsd adt? if  drop 0x0E20.8400 m.v#bhsd  %v3same  exit  then
   dup m.z.bhsd adt? if  drop %sve-add  exit  then
   drop
   3 0 try: case
      0  of  0 0 0 add-sub      endof
      1  of  1 0 0 add-sub      endof
      2  of  2 0 0 add-sub      endof
   endcase
;
: sub
   <asm  reg nip
   dup m.d      adt? if  drop 0x7E20.8400 m.d       %s3same  exit  then
   dup m.v#bhsd adt? if  drop 0x2E20.8400 m.v#bhsd  %v3same  exit  then
   dup m.z.bhsd adt? if  drop %sve-sub  exit  then
   drop
   3 0 try: case
      0  of  0 1 0 add-sub      endof
      1  of  1 1 0 add-sub      endof
      2  of  2 1 0 add-sub      endof
   endcase
;
: addp
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4411.a000 m.z.bhsd %zpez  exit  then
   0x0e20.bc00 m.v#bhsd  0x5ef1.b800 m.d  %addp
;
: adr
   <asm  rd rd-mask m.z.sd adt? if  sve-adr  exit  then
   0x1000.0000 m.x  %adr-imm 
;
: aesd
   <asm  rd rd-mask m.z.b adt? if   0x4522.e400 m.z.b %zez  exit  then
   0x4E28.5800 m.v.16b  %aes
;
: aese
   <asm  rd rd-mask m.z.b adt? if   0x4522.e000 m.z.b %zez exit  then
   0x4E28.4800 m.v.16b  %aes
;
: aesimc
   <asm  rd rd-mask m.z.b adt? if   0x4520.e400 m.z.b %ze  exit  then
   0x4E28.7800 m.v.16b  %aes  
;
: aesmc
   <asm  rd rd-mask m.z.b adt? if   0x4520.e000 m.z.b %ze  exit  then
   0x4E28.6800 m.v.16b  %aes  
;
: and
   <asm  reg nip
   dup m.zp.bhsd  adt? if  drop %sve-and  exit  then
   dup m.v#b      adt? if  drop 0x0E20.1C00 m.v#b  %v3same  exit  then
   drop
   2 0 try: case
      0  of  0 0 0 log-imm-modes      endof
      1  of  1 0 0 log-imm-modes      endof
   endcase
;
: ands
   <asm  rd 
   rd-mask m.p.b adt? if  0x2540.4000 m.p.b  %pppp  exit  then
   m.wx rd??
   3 0  "," wxn, "#"? if  log-imm  else  log-reg  then  asm>
;
: asr
   <asm  rd rd-mask m.z.bhsd adt? if   %sve-asr  exit  then
   <asm  d=n, "#"? if  0x1300.7c00 m.wx  #lsr  bitfield  else  0x1ac0.2800 m.wx  regshift  then
   asm>
;

: bcax
   <asm  rd rd-mask m.z.d adt? if  0x0460.3800 m.z.d %zezz   exit  then
   0xCE20.0000 m.v.16b %4sha84
;
: bic
   <asm  rd, rd-mask
   dup m.wx   adt? if   drop wxn,  0 1 log-reg      asm>  exit  then
   dup m.v#b  adt? if   drop 0x0E60.1C00 m.v#b   %v3same  exit  then
   dup m.v#hs adt? if   drop 0x2F00.1400 m.v#hs  %modimm  exit  then
   dup m.z    adt? if   drop %sve-bic                      exit  then
   drop
;
: bics
   <asm  rd 
   rd-mask m.p.b adt? if  0x2540.4010 m.p.b  %pppp  exit  then
   m.wx rd??
   3 1  "," wxn,  log-reg  asm>
;
: bsl
   <asm  rd rd-mask m.z.d adt? if  0x0420.3c00 m.z.d  %zezz   exit  then
   0x2E60.1C00 m.v#b  %bv3same
;

: cls
   <asm  rd rd-mask m.z.bhsd adt? if   0x0418.a000 m.z.bhsd %zpz  exit  then
   0x0E20.4800 m.v#bhs   0x5ac0.1400 m.wx  %2same-gv
;
: clz
   <asm  rd rd-mask m.z.bhsd adt? if   0x0419.a000 m.z.bhsd %zpz  exit  then
   0x2E20.4800 m.v#bhs   0x5ac0.1000 m.wx  %2same-gv
;
: cnt
   <asm  rd rd-mask m.z.bhsd adt? if    0x041a.a000 m.z.bhsd %zpz  exit  then
   0x0E20.5800 m.v#b  %v2same
;

: eon
   <asm  rd  rd-mask m.z.bhsd adt? if   0x0540.0000 m.z.bhsd %sve-eon  exit  then
   <asm  2  1  wxd, wxn, log-reg asm>
;
: eor
   <asm  reg nip
   dup m.zp.bhsd adt? if  drop %sve-eor  exit  then
   dup m.v#b     adt? if  drop 0x2E20.1C00 m.v#b  %v3same  exit  then
   drop
   2 0 try: case
      0  of  0 2 0 log-imm-modes      endof
      1  of  1 2 0 log-imm-modes      endof
   endcase
;
: eor3
   <asm  reg nip
   dup  m.z.bhsd adt? if  drop 0x0420.3800 m.z.d %zezz  exit  then
   drop
   0xCE00.0000 m.v.16b %4sha84 
;
: ext
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x0520.0000 m.z.b %sve-ext  exit  then
   <asm  d=n=m,  m.v#b rd??  set-q  #uimm4 11 4 ^^op  0x2E00.0000 iop  asm>
;

: ld1b
   <asm  "{"  rd
   rd-mask m.z.bhsd adt? if  0x0000.0000 m.z.bhsd %ld1  exit  then
   0xe000.0000 m.zahv.b  %ls1za
;
: ld1h
   <asm  "{"  rd
   rd-mask m.z.bhsd adt? if  0x0080.0000 m.z.hsd  %ld1  exit  then
   0xe040.0000 m.zahv.h  %ls1za
;
: ld1w
   <asm  "{"  rd
   rd-mask m.z.bhsd adt? if  0x0100.0000 m.z.sd   %ld1  exit  then
   0xe080.0000 m.zahv.s  %ls1za
;
: ld1d
   <asm  "{"  rd
   rd-mask m.z.bhsd adt? if  0x0180.0000 m.z.d    %ld1  exit  then
   0xe0c0.0000 m.zahv.d  %ls1za
;

: st1b
   <asm  "{"  rd
   rd-mask m.z.bhsd adt? if  0x0000.0000 m.z.bhsd %st1  exit  then
   0xe020.0000 m.zahv.b  %ls1za
;
: st1h
   <asm  "{"  rd
   rd-mask m.z.bhsd adt? if  0x0080.0000 m.z.hsd  %st1  exit  then
   0xe060.0000 m.zahv.h  %ls1za
;
: st1w
   <asm  "{"  rd
   rd-mask m.z.bhsd adt? if  0x0100.0000 m.z.sd   %st1  exit  then
   0xe0a0.0000 m.zahv.s  %ls1za
;
: st1d
   <asm  "{"  rd
   rd-mask m.z.bhsd adt? if  0x0180.0000 m.z.d    %st1  exit  then
   0xe0e0.0000 m.zahv.d  %ls1za
;

: ldr
   <asm  rd
   rd-mask m.zp adt? if  0x8580.0000 m.zp %lspz  exit  then
   rd-mask m.za adt? if  0xe100.0000 m.za %lsza  exit  then 
   7 0 try:  rd,  rd->sz,v,opc  adrmodes-2
;
: lsl
   <asm  rd rd-mask m.z.bhsd adt? if   %sve-lsl  exit  then
   <asm  d=n, "#"? if  0x5300.0000 m.wx  #lsl  bitfield  else  0x1ac0.2000 m.wx  regshift  then
   asm>
;
: lsr
   <asm  rd rd-mask m.z.bhsd adt? if   %sve-lsr  exit  then
   <asm  d=n, "#"? if  0x5300.7c00 m.wx  #lsr  bitfield  else  0x1ac0.2400 m.wx  regshift  then
   asm>
;

: mla
   <asm  rd rd-mask m.z.bhsd adt? if   %sve-mla  exit  then
   2 0 try: case
      0  of  0x0E20.9400 m.v#bhs  v3same       endof
      1  of  0x2F00.0000 m.v#hs   velem-same   endof
   endcase
;
: mls
   <asm  rd rd-mask m.z.bhsd adt? if   %sve-mls  exit  then
   2 0 try: case
      0  of  0x2E20.9400 m.v#bhs  v3same       endof
      1  of  0x2F00.4000 m.v#hs   velem-same   endof
   endcase
;

: mov
   <asm  reg is rd-adt  drop
   rd-adt m.z.bhsd adt? if  %zmov  exit  then
   rd-adt m.p.bhsd adt? if  %pmov  exit  then
   rd-adt m.v.bhsd adt? if  %vmov  exit  then
   rd-adt m.v#bhsd adt? if  <asm  0x0EA0.1C00 m.v#b  v2>3same  asm>  exit  then
   rd-adt m.bhsd   adt? if  <asm  0x5E00.0400 m.bhsd  ^simd-dup-se  asm>  exit  then
   %gmov
;

: mul
   <asm  rd
   rd-mask m.z.bhsd adt? if   %sve-mul  exit  then
   rd-mask m.wx adt? if   <asm  0x1b00.7c00 m.wx 3same  set-sf?  asm>  exit  then
    2 0 try: case
      0  of  0x0E20.9C00 m.v#bhs  v3same      endof
      1  of  0x0F00.8000 m.v#hs   velem-same  endof
   endcase
;

: neg
   <asm  rd,
   rd-mask m.zp.bhsd adt? if  0x0417.a000 m.z.bhsd %zpz      exit  then
   rd-mask m.d       adt? if  0x7E20.B800 m.d      %s2same   exit  then
   rd-mask m.v#bhsd  adt? if  0x2E20.B800 m.v#bhsd %v2same   exit  then
   1 0 rd-adt ?wx [wxzn] wxm ashift ^ashift  asm>
;

: orr
   <asm  reg nip
   dup m.zp.bhsd adt? if  drop %sve-orr  exit  then
   dup m.v#b     adt? if  drop 0x0EA0.1C00 m.v#b  %v3same  exit  then
   dup m.v#hs    adt? if  drop 0x0F00.1400 m.v#hs %modimm  exit  then
   drop
   2 0 try: case
      0  of  0 1 0 log-imm-modes      endof
      1  of  1 1 0 log-imm-modes      endof
   endcase
;

: orn
   <asm  rd,
   rd-mask m.z.bhsd adt? if
      rn=d  ","   false encode-imm13  5 6 ^^op  11 6 ^^op  17 1 ^^op
      0x0500.0000 iop  asm>  exit
   then
   rd-mask m.p.bhsd adt? if
      0x2580.4010 m.p.b rd??iop  pza, rn, rm  ?rd=rn=rm  asm>  exit
   then
   rd-mask m.v#b adt? if   0x0EE0.1C00  m.v#b  %v3same  exit  then
   <asm  wxd, wxn,  1 1 log-reg  asm>
;

: pmul
   <asm  rd,
   rd-mask m.zp.bhsd  adt? if  0x0420.6400 m.z.b %zzz  exit  then
   0x2E20.9C00 m.v#b   %v3same
;

: rax1
   <asm  rd,
   rd-mask m.z.bhsd adt? if  0x4520.f400  m.z.d  <asm   d=n=m  rd??iop  asm>   exit  then
   0xCE60.8C00 m.v.2d  %3sha84
;

: rbit
   <asm  rd,
   rd-mask m.z.bhsd adt? if  0x0527.8000  m.z.bhsd  %zpz   exit  then
    0x2E60.5800 m.v#b  0x5ac0.0000 m.wx  %2same-gv
;
  
: rev
   <asm rd,
   rd-mask m.p.bhsd  adt? if  0x0534.4000 iop  set-preg-sz  rn  ?rd=rn  asm>  exit  then
   rd-mask m.z.bhsd  adt? if  0x0538.3800 iop  set-zreg-sz  rn  ?rd=rn  asm>  exit  then
   0x5ac0.0800 m.wx  %rev 
;

: saba
   <asm rd,
   rd-mask m.z.bhsd  adt? if  0x4500.f800 m.z.bhsd %zzz  exit  then
   0x0E20.7C00 m.v#bhs  %v3same
;
: uaba
   <asm rd,
   rd-mask m.z.bhsd  adt? if  0x4500.fc00 m.z.bhsd %zzz  exit  then
   0x2E20.7C00 m.v#bhs  %v3same
;
: sabd
   <asm rd,
   rd-mask m.z.bhsd  adt? if  0x040c.0000 m.z.bhsd %zpez  exit  then
   0x0E20.7400 m.v#bhs  %v3same
;
: uabd
   <asm rd,
   rd-mask m.z.bhsd  adt? if  0x040d.0000 m.z.bhsd %zpez  exit  then
   0x2E20.7400 m.v#bhs  %v3same
;

: scvtf
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x6510.a000 m.z.hsd %cvtf  exit  then
   rd-mask m.bhsd adt? if
      4 0 try: case
	 0  of  0x1e22.0000            ^simd-ng   endof
	 1  of  0x1e02.0000            ^simd-ngi  endof
	 2  of  0x5F00.E400 m.sd       s2#same    endof
	 3  of  0x5E21.D800 m.sd       fs2same    endof
      endcase
      exit
   then
   rd-mask m.v#bhsd adt? if
      2 0 try: case
	 0  of  0x0F00.E400 m.v#hsd    v2#same    endof
	 1  of  0x0E21.D800 m.v#hsd    fv2same    endof
      endcase
   then
;
: ucvtf
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x6511.a000 m.z.hsd %cvtf  exit  then
   rd-mask m.bhsd adt? if
      4 0 try: case
	 0  of  0x1e23.0000            ^simd-ng   endof
	 1  of  0x1e03.0000            ^simd-ngi  endof
	 2  of  0x7F00.E400 m.hsd      s2#same    endof
	 3  of  0x7E21.D800 m.hsd      fs2same    endof
      endcase
      exit
   then
   rd-mask m.v#bhsd adt? if
      2 0 try: case
	 0  of  0x2F00.E400 m.v#hsd    v2#same    endof
	 1  of  0x2E21.D800 m.v#hsd    fv2same    endof
      endcase
   then
;

: sdiv
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x0414.0000 m.z.sd %zpez  exit  then
   0x1ac0.0c00 m.wx  %dp2
;
: udiv
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x0415.0000 m.z.sd %zpez  exit  then
   0x1ac0.0800 m.wx  %dp2
;

: sdot
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4400.0000 m.z.sd %sdot  exit  then
   2 0 try: case
      0 of  0x0E80.9400 m.v#b  simd-dot      endof
      1 of  0x0F80.E000 m.v#b  simd-dotelem  endof
   endcase
;
: udot
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4400.0400 m.z.sd %sdot  exit  then
   2 0 try: case
      0 of  0x2E80.9400 m.v#b  simd-dot      endof
      1 of  0x2F80.E000 m.v#b  simd-dotelem  endof
   endcase
;
: sli
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4500.f400 m.z.bhsd %sli  exit  then
   rd-mask m.v#bhsd adt? if  0x2F00.5400 m.v#bhsd %v2#same  exit  then
   0x7F00.5400 m.d  %s2#same
;
: smax
   <asm  rd
   rd-mask m.z.bhsd adt? if  %smax  exit  then
   0x0E20.6400 m.v#bhs  %v3same
;
: umax
   <asm  rd
   rd-mask m.z.bhsd adt? if  %umax  exit  then
   0x2E20.6400 m.v#bhs  %v3same
;
: smaxp
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4414.a000 m.z.bhsd %zpez  exit  then
   0x0E20.a400 m.v#bhs  %v3same
;
: umaxp
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4415.a000 m.z.bhsd %zpez  exit  then
   0x2E20.a400 m.v#bhs  %v3same
;
: smaxv
   <asm  rd, reg nip m.p adt? if
      0x0408.2000 m.bhsd %spz3
   else
       0x0E30.A800 m.bhs  %across
   then
;
: umaxv
   <asm  rd, reg nip m.p adt? if
      0x0409.2000 m.bhsd %spz3
   else
       0x2E30.A800 m.bhs  %across
   then
;
: smin
   <asm  rd
   rd-mask m.z.bhsd adt? if  %smin  exit  then
   0x0E20.6c00 m.v#bhs  %v3same
;
: umin
   <asm  rd
   rd-mask m.z.bhsd adt? if  %umin  exit  then
   0x2E20.6c00 m.v#bhs  %v3same
;
: sminp
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4416.a000 m.z.bhsd %zpez  exit  then
   0x2E20.AC00 m.v#bhs  %v3same
;
: uminp
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4417.a000 m.z.bhsd %zpez  exit  then
   0x2E20.AC00 m.v#bhs  %v3same
;
: sminv
   <asm  rd, reg nip m.p adt? if
      0x040a.2000 m.bhsd %spz3
   else
       0x0E31.A800 m.bhs  %across
   then
;
: uminv
   <asm  rd, reg nip m.p adt? if
      0x040b.2000 m.bhsd %spz3
   else
       0x2E31.A800 m.bhs  %across
   then
;
: smmla
   <asm  rd
   rd-mask m.z.bhsd adt? if  %smmla  exit  then
   0x4e80.a400  m.v.4s  %mmla
;

: smulh   
   <asm  rd
   rd-mask m.zp.bhsd adt? if   0 m.z.bhsd %mulh  exit  then
   0x9b40.7c00 m.x   %dp3b
;
: umulh   
   <asm  rd
   rd-mask m.zp.bhsd adt? if   1 m.z.bhsd %mulh  exit  then
   0x9bc0.7c00 m.x   %dp3b
;

: sqabs
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4408.a000 m.z.bhsd %zpz   exit  then
   rd-mask m.bhsd   adt? if  0x5E20.7800 m.bhsd %s2same  exit  then
   0x0E20.7800 m.v#bhsd  %v2same
;
: sqadd
   <asm  rd
   rd-mask m.z.bhsd adt? if  %sve-sqadd   exit  then
   0x0E20.0C00 m.v#bhsd  0x5E20.0C00 m.bhsd  %3same-nv
;
: sqsub
   <asm  rd
   rd-mask m.z.bhsd adt? if  %sve-sqsub   exit  then
   0x0E20.2C00 m.v#bhsd  0x5E20.2C00 m.bhsd  %3same-nv
;

: srhadd
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4414.8000 m.z.bhsd  %zpez   exit  then
   0x0E20.1400 m.v#bhs  %v3same
;
: urhadd
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4415.8000 m.z.bhsd  %zpez   exit  then
   0x2E20.1400 m.v#bhs  %v3same
;

: sri
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x4500.f000 m.z.bhsd %sli     exit  then
   rd-mask m.v#bhsd adt? if  0x2F00.4400 m.v#bhsd %v2#same  exit  then
   0x7F00.4400 m.d  %s2#same
;

: srshl
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x4402.8000 m.z.bhsd %zpez  exit  then
   0x0E20.5400 m.v#bhsd  0x5E20.5400 m.d  %3same-nv
;
: urshl
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x4403.8000 m.z.bhsd %zpez  exit  then
   0x2E20.5400 m.v#bhsd  0x7E20.5400 m.d  %3same-nv
;

: srshr
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x040c.8000 m.z.bhsd %zpe#    exit  then
   rd-mask m.bhsd   adt? if  0x5F00.2400 m.bhsd   %s2#same  exit  then
   0x0F00.2400 m.v#bhsd  %v2#same
;
: urshr
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x040d.8000 m.z.bhsd %zpe#    exit  then
   rd-mask m.bhsd   adt? if  0x7F00.2400 m.bhsd   %s2#same  exit  then
   0x2F00.2400 m.v#bhsd  %v2#same
;

: srsra
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x4500.e800 m.z.bhsd %sli     exit  then
   rd-mask m.bhsd   adt? if  0x5F00.3400 m.bhsd   %s2#same  exit  then
   0x0F00.3400 m.v#bhsd  %v2#same
;
: ursra
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x4500.ec00 m.z.bhsd %sli     exit  then
   rd-mask m.bhsd   adt? if  0x7F00.3400 m.bhsd   %s2#same  exit  then
   0x2F00.3400 m.v#bhsd  %v2#same
;

: ssra
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x4500.e000 m.z.bhsd %sli     exit  then
   rd-mask m.bhsd   adt? if  0x5F00.1400 m.b      %s2#same  exit  then
   0x0F00.1400 m.v#bhsd  %v2#same
;
: usra
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x4500.e400 m.z.bhsd %sli     exit  then
   rd-mask m.bhsd   adt? if  0x7F00.1400 m.b      %s2#same  exit  then
   0x2F00.1400 m.v#bhsd  %v2#same
;

: str
   <asm  rd
   rd-mask m.zp adt? if  0xe580.0000 m.zp %lspz  exit  then
   rd-mask m.za adt? if  0xe120.0000 m.za %lsza  exit  then 
   7 0 try:  rd,  rd->sz,v,opc 1 xor  adrmodes-1
;

: sudot
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x44a0.1c00 m.z.s %sve-sudot   exit  then
   0x0000.0000  m.v#s  %usdot
;
: usdot
  <asm  rd
   rd-mask m.z.bhsd adt? if  0x4480.1800 m.z.s %sve-usdot   exit  then
   0x0080.0000  m.v#s  %usdot
;
: suqadd
   <asm  rd
   rd-mask m.z.bhsd adt? if  0x441c.8000 m.z.bhsd %zpez   exit  then
   rd-mask m.bhsd   adt? if  0x5E20.3800 m.bhsd   s2same  exit  then
   0x0E20.3800 m.v#bhsd  v2same
;
: sxtb
   <asm  rd,
   rd-mask m.z.bhsd adt? if  0x0410.a000 m.z.hsd %zpz   exit  then
   0x1300.0000 m.wx  wxn    7 ^imms6  bitfield  asm>
;
: sxth
   <asm  rd,
   rd-mask m.z.bhsd adt? if  0x0412.a000 m.z.sd %zpz   exit  then
   0x1300.0000 m.wx  wxn   15 ^imms6  bitfield  asm>
;
: sxtw
   <asm  rd,
   rd-mask m.z.bhsd adt? if  0x0414.a000 m.z.d %zpz   exit  then
   0x9300.0000 m.wx  wxn   31 ^imms6  bitfield  asm>
;
: uxtb
   <asm  rd,
   rd-mask m.z.bhsd adt? if  0x0411.a000 m.z.hsd %zpz   exit  then
   0x5300.0000 m.wx  wxn    7 ^imms6  bitfield  asm>
;
: uxth
   <asm  rd,
   rd-mask m.z.bhsd adt? if  0x0413.a000 m.z.sd %zpz   exit  then
   0x5300.0000 m.wx  wxn   15 ^imms6  bitfield  asm>
;
: uxtw   0x0415.a000 m.z.d %zpz  ;

: uzp1
   <asm  rd,
   rd-mask m.p.bhsd  adt? if  0x0520.4800 m.p.bhsd  %zip-p   exit  then
   rd-mask m.z.bhsdq adt? if  0x0520.0800 m.z.bhsdq %zip-z   exit  then
   0x0E00.1800 m.v#bhsd  %v3same
;
: uzp2
   <asm  rd,
   rd-mask m.p.bhsd  adt? if  0x0520.4c00 m.p.bhsd  %zip-p   exit  then
   rd-mask m.z.bhsdq adt? if  0x0520.0c00 m.z.bhsdq %zip-z   exit  then
   0x0E00.5800 m.v#bhsd  %v3same
;
: zip1
   <asm  rd,
   rd-mask m.p.bhsd  adt? if  0x0520.4000 m.p.bhsd  %zip-p   exit  then
   rd-mask m.z.bhsdq adt? if  0x0520.0000 m.z.bhsdq %zip-z   exit  then
   0x0E00.3800 m.v#bhsd  %v3same
;
: zip2
   <asm  rd,
   rd-mask m.p.bhsd  adt? if  0x0520.4400 m.p.bhsd  %zip-p   exit  then
   rd-mask m.z.bhsdq adt? if  0x0520.0400 m.z.bhsdq %zip-z   exit  then
   0x0E00.7800 m.v#bhsd  %v3same
;

: xar
   <asm  rd
   rd-mask m.zp.bhsd adt? if  0x0420.3400 m.z.bhsd  <asm  zez "," tsz-imm3-hi  asm>  exit  then
   0xCE80.0000 m.v.2d  %3isha84
;

: fabd        sve_fp? if  fabd_sve exit then fabd-leg  ;
: fabs        sve_fp? if  fabs_sve exit then fabs-leg  ;
: fadd        sve_fp? if  fadd_sve exit then fadd-leg  ;
: faddp       sve_fp? if  faddp_sve exit then faddp-leg  ;
: fcadd       sve_fp? if  fcadd_sve exit then fcadd-3  ;
: fsub        sve_fp? if  fsub_sve exit then fsub-leg  ;
: fmul        sve_fp? if  fmul_sve exit then fmul-try  ;
: fmulx       sve_fp? if  fmulx_sve exit then fmulx-try  ;
: fdiv        sve_fp? if  fdiv_sve exit then fdiv-leg  ;
: fcmeq       sve_fp? if  fcmeq_sve exit then fcmeq-try  ;
: fcmge       sve_fp? if  fcmge_sve exit then fcmge-try  ;
: fcmgt       sve_fp? if  fcmgt_sve exit then fcmgt-try  ;
: fcmla       sve_fp? if  fcmla_sve exit then fcmla-3  ;

: fcvt        sve_fp? if  fcvt_sve exit then fcvt-try  ;
: fcvtzs      sve_fp? if  fcvtzs_sve exit then fcvtzs-try  ;
: fcvtzu      sve_fp? if  fcvtzu_sve exit then fcvtzu-try  ;

: fmax        sve_fp? if  fmax_sve exit then fmax-leg ;
: fmaxnm      sve_fp? if  fmaxnm_sve exit then fmaxnm-leg ;
: fmaxnmp     sve_fp? if  fmaxnmp_sve exit then fmaxnmp-leg ;
: fmaxnmv     sve_fp? if  fmaxnmv_sve exit then fmaxnmv-leg ;
: fmaxp       sve_fp? if  fmaxp_sve exit then fmaxp-leg ;
: fmaxv       sve_fp? if  fmaxv_sve exit then fmaxv-leg ;

: fmin        sve_fp? if  fmin_sve exit then fmin-leg ;
: fminnm      sve_fp? if  fminnm_sve exit then fminnm-leg ;
: fminnmp     sve_fp? if  fminnmp_sve exit then fminnmp-leg ;
: fminnmv     sve_fp? if  fminnmv_sve exit then fminnmv-leg ;
: fminp       sve_fp? if  fminp_sve exit then fminp-leg ;
: fminv       sve_fp? if  fminv_sve exit then fminv-leg ;

: fmla        sve_fp? if  fmla_sve exit then fmla-try ;
: fmls        sve_fp? if  fmls_sve exit then fmls-try ;

: fmov        sve_fp? if  fmov_sve exit then fmov-try ;
: fneg        sve_fp? if  fneg_sve exit then fneg-leg ;

: frecpe      sve_fp? if  frecpe_sve exit then frecpe-leg ;
: frecps      sve_fp? if  frecps_sve exit then frecps-leg ;
: frecpx      sve_fp? if  frecpx_sve exit then frecpx-leg ;

: frinti      sve_fp? if  frinti_sve exit then frinti-leg ;
: frintx      sve_fp? if  frintx_sve exit then frintx-leg ;
: frinta      sve_fp? if  frinta_sve exit then frinta-leg ;
: frintn      sve_fp? if  frintn_sve exit then frintn-leg ;
: frintz      sve_fp? if  frintz_sve exit then frintz-leg ;
: frintm      sve_fp? if  frintm_sve exit then frintm-leg ;
: frintp      sve_fp? if  frintp_sve exit then frintp-leg ;

: frsqrte     sve_fp? if  frsqrte_sve exit then frsqrte-leg ;
: frsqrts     sve_fp? if  frsqrts_sve exit then frsqrts-leg ;

: fsqrt       sve_fp? if  fsqrt_sve exit then fsqrt-leg ;