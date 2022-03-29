\ Scaled Vector Extension

: sve_fp?
   <asm reg ( n adt ) swap drop m.zp.bhsd adt? if true exit then  \ if Rd is Z or P register
   ","? not if  false exit  then
   <@c> upc ascii P =                                             \ or 2nd parameter is P register
;

: == ( i0 f0 i1 f1 -- flag )  rot = -rot = and ;
: =0.0 ( i f -- flag )  0 0 == ;
: =0.5 ( i f -- flag )  0 5 == ;
: =1.0 ( i f -- flag )  1 0 == ;
: =2.0 ( i f -- flag )  2 0 == ;

: msz ( -- n ) opcode 23 >> 3 and ;

: reg-sz   ( mask -- sz )
   0x1f and
   case
      1 of   0   endof
      2 of   1   endof
      4 of   2   endof
      8 of   3   endof
      16 of   0   endof
      " adt size " expecting
   endcase
;

: zreg-sz   ( mask -- sz )
   case
      m.z.b of   0   endof
      m.z.h of   1   endof
      m.z.s of   2   endof
      m.z.d of   3   endof
      m.z.q of   0   endof
      " Z register " expecting
   endcase
;
: set-zreg-sz   ( -- )   rd-mask zreg-sz  22 2 ^^op  ;
: preg-sz   ( mask -- sz )
   case
      m.p.b of   0   endof
      m.p.h of   1   endof
      m.p.s of   2   endof
      m.p.d of   3   endof
      " P register " expecting
   endcase
;
: set-preg-sz   ( -- )   rd-mask preg-sz 22 2 ^^op  ;

\ Rd is a tile
: %zazz   ( op regs -- )
   <asm   rd, rn, rm  rd??iop  ?rn=rm
   rd-mask case
      \ m.za.b of   m.z.b   endof
      \ m.za.h of   m.z.h   endof
      m.za.s of   m.z.s   endof
      m.za.d of   m.z.d   endof
   endcase
   rn-mask <> " element sizes to match " ?expecting
   asm>
;

: %zz      <asm   rd, rd??iop rn ?rd=rn set-zreg-sz  asm>   ;

: %zzz     <asm   3same  set-zreg-sz  asm>   ;

: %zpz    <asm   rd, rd??iop  plm,  rn  ?rd=rn     set-zreg-sz  asm>   ;

\ Rn implicitly = Rd , and Ra goes to Rn field
\ eg MAD <Zdn>.<T>, <Pg>/M, <Zm>.<T>, <Za>.<T>
: %zpzz     <asm   rd, rd??iop  plm,  rm, rn  ?rd=rn=rm  set-zreg-sz  asm>   ;
: %zpmznzm  <asm   rd, rd??iop  plm,  rn, rm  ?rd=rn=rm  set-zreg-sz asm> ;
: %zpzz2     <asm   rd, rd??iop  pa,  rm, rn  ?rd=rn=rm  set-zreg-sz  asm>   ;


\ warning
\ sometimes Rn must be explicitly the same as Rd
\ and someties there is a P in between
\ better naming is needed for these cases
\ how about e for explicit
\ zez zpez


\ Rn explicitly = Rd , and both are encoded into the Rd field
\ eg BCAX <Zdn>.D, <Zdn>.D, <Zm>.D, <Zk>.D
: (rn=d)   ( n adt -- )   rd-adt <> swap <rd> <> or  " Rd = Rn " ?expecting  ;
: rn=d   ( -- )   reg (rn=d)  ;
: rn=d,  ( -- )   rn=d ","  ;
: rde     ( -- )   rd, rn=d  rd??iop  ;
: rde,    ( -- )   rde ","  ;
: %ze     <asm  rde  asm>  ;

\ if there is an Rm it is encoded in the Rn field
: zez     rde,  rn  ?rd=rn  ;
: %zez    <asm  zez  set-zreg-sz   asm>  ;
: %zezz   <asm  rde,  rm, rn  ?rd=rn=rm  asm>  ;

: %z>z    <asm  2long  set-zreg-sz  asm>  ;
: %z>zz   <asm  3long  set-zreg-sz  asm>  ;

\ some instructions also take a predicate between the identical Rd and Rn
: rdpe    ( -- )   rd, plm, rn=d  rd??iop  set-zreg-sz  ;
: rdpe,   ( -- )   rdpe  ","  ;
: %zpez    <asm   rdpe,  rn ?rd=rn   asm>   ;


: tsz-imm2   ( -- )
   rd-mask m.z.bhsd adt? 0= ?invalid-regs
   rd-mask m.z.b = if  6 #uimm  1 << 1 or  then
   rd-mask m.z.h = if  5 #uimm  2 << 2 or  then
   rd-mask m.z.s = if  4 #uimm  3 << 4 or  then
   rd-mask m.z.d = if  3 #uimm  4 << 8 or  then
   rd-mask m.z.q = if  2 #uimm  5 << 0x10 or  then
   ( imm )
   dup 0x1f and    swap 5 >> 3 and   ( tsz imm2 )
   22 2 ^^op  16 5 ^^op
;

: tsz-imm3   ( -- tszh tszl:imm3 )
   rd-mask m.z.bhsd adt? 0= ?invalid-regs
   rd-mask m.z.b = if   0 0x08  3 #uimm or  then
   rd-mask m.z.h = if   0 0x10  4 #uimm or  then
   rd-mask m.z.s = if   1       5 #uimm     then
   rd-mask m.z.d = if
      6 #uimm   dup 0x20 land if  0x1f land  3  else  2  then  swap 
   then
;
: tsz-imm3-hi   ( -- )   tsz-imm3  16 5 ^^op  22 2 ^^op  ;
: tsz-imm3-lo   ( -- )   tsz-imm3   5 5 ^^op  22 2 ^^op  ;

: %zpe#    <asm   rd, plm, rn=d,  rd??iop  tsz-imm3-lo  asm>   ;

\ similar story for predicates, but pz instead of plm
: %ppp    ( op regs -- )   <asm  3same  set-preg-sz  asm>   ;
: %ppe    ( op regs -- )   <asm  rd, rd??iop  pn, rn=d  asm>   ;
: %ppe1   ( op regs -- )   <asm  rd, rd??iop  pn, rn=d  set-preg-sz  asm>   ;
: %pppp   ( op regs -- )   <asm   rd, rd??iop  pza,  rn, rm  ?rd=rn=rm  set-preg-sz  asm>   ;
: %pppp2   ( op regs -- )   <asm   rd, rd??iop  pa,  rn, rm  ?rd=rn=rm  set-preg-sz  asm>   ;

: ?pd=zn
   rd-mask case
      m.p.b of   m.z.b   endof
      m.p.h of   m.z.h   endof
      m.p.s of   m.z.s   endof
      m.p.d of   m.z.d   endof
   endcase
   rn-mask <> " Rn size = Rd size " ?expecting
;
: ?pd=zn=zm   ( -- )   ?pd=zn  ?rn=rm  ;

: %ppzz   <asm   pd, rd??iop  plz, rn, set-preg-sz rm  ?pd=zn=zm  asm>  ;
: %ppzz-s <asm   pd, rd??iop  plz, rm, set-preg-sz rn  ?pd=zn=zm  asm>  ;
: %ppzu#  <asm   pd, rd??iop  plz, rn, set-preg-sz  ?pd=zn  7 #uimm  14 7 ^^op  asm>  ;
: %ppzs#  <asm   pd, rd??iop  plz, rn, set-preg-sz  ?pd=zn  5 #simm  16 5 ^^op  asm>  ;

: %zpzzn  <asm rd, rd??iop  plm, rn=d, rn ?rd=rn set-zreg-sz  asm>   ;

: %zpzzn-const
   <asm rd, rd??iop  plm, rn=d, rn, ?rd=rn set-zreg-sz sq-angle d# 16 ^op  asm>  ;

: %zpznzm-const
   <asm rd, rd??iop  plm, rn, rm, ?rd=rn=rm set-zreg-sz square-angle d# 13 2 ^^op  asm>  ;


: ?rd=zn
   rd-adt adt>size rn-adt adt>size <> " same register size" ?expecting
;
: ?rd=zm
   rd-adt adt>size rm-adt adt>size <> " same register size" ?expecting
;

: %vpvzn ( ops vmask -- )
   <asm  rd, rd??iop pl, rn=d, rn
      ?rd=zn rn-mask zreg-sz d# 22 2 ^^op
   asm>
;

: %vpzn ( ops vmask -- )
   <asm  rd, rd??iop pl, rn
      ?rd=zn rn-mask zreg-sz d# 22 2 ^^op
   asm>
;

: (spz)
   rn-mask zreg-sz  22 2 ^^op
   rd-mask case
      m.b of   m.z.b   endof
      m.h of   m.z.h   endof
      m.s of   m.z.s   endof
      m.d of   m.z.d   endof
   endcase
   rn-mask <> " Rn size = Rd size " ?expecting
;

: ?z,s   ( -- )
   rn-mask case
      m.b of   m.z.b   endof
      m.h of   m.z.h   endof
      m.s of   m.z.s   endof
      m.d of   m.z.d   endof
   endcase
   rd-mask <> " Rn size = Rd size " ?expecting
;
: (z,s)   ( -- )   set-zreg-sz ?z,s  ;
: tsz-mov   ( -- )   \ yet another special case
   ?z,s
   rd-mask m.z.b = if  1     then
   rd-mask m.z.h = if  2     then
   rd-mask m.z.s = if  4     then
   rd-mask m.z.d = if  8     then
   rd-mask m.z.q = if  0x10  then
   16 5 ^^op
;

: %spz    <asm  rd, rd??iop  px, rn  (spz)  asm>  ;
: %spz3   <asm  rd, rd??iop  pl, rn  (spz)  asm>  ;
: (gpz)
   rn-mask zreg-sz  22 2 ^^op
   rn-mask case
      m.z.b of   m.w   endof
      m.z.h of   m.w   endof
      m.z.s of   m.w   endof
      m.z.d of   m.x   endof
   endcase
   rd-mask <> " Rn size = Rd size " ?expecting
;
: ?gd=zm
   rm-mask case
      m.z.b of   m.w   endof
      m.z.h of   m.w   endof
      m.z.s of   m.w   endof
      m.z.d of   m.x   endof
   endcase
   rd-mask <> " Rm size = Rd size " ?expecting
;
: (z,g)
   set-zreg-sz
   rd-mask case
      m.z.b of   m.w   endof
      m.z.h of   m.w   endof
      m.z.s of   m.w   endof
      m.z.d of   m.x   endof
   endcase
   rn-mask <> " Rn size = Rd size " ?expecting
;
: %gpz   <asm  rd, rd??iop  pl, rn  (gpz)  asm>  ;

: lsl#8   ( -- )   "lsl"  #uimm4 8 <> " #8 " ?expecting  ;
: zimm   ( #bits -- )
   #uimm 5 << iop ","? if   lsl#8  0x2000 iop  then
;

: ?zd=g   ( mask -- )   rd-mask m.z.d = if  m.x   else  m.w  then  <> ?invalid-regs  ;

: %sve-add   ( -- )
   <asm   rd, reg dup m.p/m adt? if      ( n adt )  \ must be ADD (vectors, predicated)
      2drop
      0x0400.0000 m.z.bhsd %zpez  exit
   then   ( n adt )
   rd-adt <> " Rd and Rn " ?same-reg-type   ( n )
   <rd> <> if  ( )  \ must be ADD (vectors, unpredicated)
      0x0420.0000 m.z.bhsd %zzz  exit
   then   ( ) 
   \ must be ADD (immediate)
   0x2520.c000 iop   set-zreg-sz "," 8 zimm  asm>
;
: %sve-sub   ( -- )
   <asm   rd, reg dup m.p/m adt? if      ( n adt )  \ must be SUB (vectors, predicated)
      2drop
      0x0401.0000 m.z.bhsd %zpez  exit
   then   ( n adt )
   rd-adt <> " Rd and Rn " ?same-reg-type   ( n )
   <rd> <> if  ( )  \ must be SUB (vectors, unpredicated)
      0x0420.0400 m.z.bhsd %zzz  exit
   then   ( ) 
   \ must be SUB (immediate)
   0x2521.c000 iop   set-zreg-sz "," 8 zimm  asm>
;
: %sve-sqadd   ( -- )
   <asm   rd, reg dup m.p/m adt? if      ( n adt )  \ must be SQADD (vectors, predicated)
      2drop
      0x4418.8000 m.z.bhsd %zpez  exit
   then   ( n adt )
   rd-adt <> " Rd and Rn " ?same-reg-type   ( n )
   <rd> <> if  ( )  \ must be SQADD (vectors, unpredicated)
      0x0420.1000 m.z.bhsd %zzz  exit
   then   ( ) 
   \ must be SQADD (immediate)
   0x2524.c000 iop   set-zreg-sz "," 8 zimm  asm>
;
: %sve-sqsub   ( -- )
   <asm   rd, reg dup m.p/m adt? if      ( n adt )  \ must be SQSUB (vectors, predicated)
      2drop
      0x441a.8000 m.z.bhsd %zpez  exit
   then   ( n adt )
   rd-adt <> " Rd and Rn " ?same-reg-type   ( n )
   <rd> <> if  ( )  \ must be SQSUB (vectors, unpredicated)
      0x0420.1800 m.z.bhsd %zzz  exit
   then   ( ) 
   \ must be SQSUB (immediate)
   0x2526.c000 iop   set-zreg-sz "," 8 zimm  asm>
;

: %addxl   <asm  iop  xd|xsp, rm|rsp ","  6 #simm  5 6 ^^op  asm>  ;

: sve-adr   ( -- )
   0x0420.a000 m.z.sd <asm
   rd, rd??iop "[" rn, rm   ","? if
      <c $case
      " lsl"  $sub  c>  #? if  #uimm2 10 2 ^^op  then
      rd-mask m.z.d adt? if  0x00c0.0000  else  0x0080.0000  then  iop
      $endof
      rd-mask m.z.s adt? ?invalid-regs
      " sxtw" $sub  c>      #uimm2 10 2 ^^op      $endof
      " uxtw" $sub  c>      #uimm2 10 2 ^^op   0x0040.0000 iop  $endof
      $endcase
   else
      rd-mask m.z.d = if  0x00c0.0000  else  0x0080.0000  then  iop      
   then
   "]"
   asm>
;
: %brka
   <asm  rd, rd??iop  10 px  ( adt )  ","
   dup adt-p/m = if  drop  0x0000.0010 iop  else  adt-p/z <> ?invalid-regs  then
   rn  ?rd=rn
   asm>
;
: %brkas   <asm  rd, rd??iop  pza,  rn  ?rd=rn   asm>  ;
: %brkn
   <asm  rd, rd??iop  pza, rn, ?rd=rn
   reg rd-adt <> swap <rd> <> or  " Rd = Rm " ?expecting
   asm>
;
: %brkpa   <asm  rd, rd??iop  pza, rn, rm  ?rd=rn=rm  asm>  ;


: #zsimm9   ( -- n )   #simm9  dup 3 >> 16 6 ^^op  7 and  10 3 ^^op  ;

: lspz   ( op regs -- )
   rd,  rd??iop
   rd-mask m.z adt? if  0x0000.4000 iop  then
   [xn|sp  ","? if
      #zsimm9  
      "," " mul vl" $match?  0= " mul vl" ?expecting
   then  "]"
;
: %lspz   ( op regs -- )   <asm  lspz  asm>  ;
: ldr-pz   0x8580.0000 m.zp  %lspz  ;
: str-pz   0xe580.0000 m.zp  %lspz  ;

: #uimm-nrs?  ( neg? sz -- n immr imms )
   >r r@ #uimm  swap if  negate 1- then   ( imm )
   r> immed>{n,immr,imms}
   0= " an immediate value that conforms" ?expecting
; 

: encode-imm13   ( neg? -- n immr imms )
   rd-mask adt>size   ( neg? sz )
   dup >r
   3 << #uimm-nrs?  ( n immr imms )
   3dup r> case
      1 of  0 0x30  endof
      2 of  0 0x20  endof
      4 of  0 0x00  endof
      8 of  1 0x00  endof
   endcase    ( n immr imms n immr imms x y )
   rot over land = >r      ( n immr imms n immr x )
   nip tuck land = r> land 0= if ."  encode-imm13 size error " cr  then
;

\ the assembler is defined before locals are supported
\ so this will have to do
variable sve-op0
variable sve-op1
variable sve-op2
variable sve-op3
variable sve-op4
variable sve-neg?

: sve-log   ( op-pred op-vecp op-vecu op-imm neg? -- )
   sve-neg? !  sve-op3 !  sve-op2 !  sve-op1 !  sve-op0 ! 
   rd,  rd-adt m.p.bhsd adt? if   \ (predicates)
      sve-op0 @ m.p.b rd??iop  pza, rn, rm   ?rd=rn=rm   exit
   then
   m.z.bhsd rd??
   reg dup m.p/m adt? if      ( n rn-adt )  \ (vectors, predicated)
      sve-op1 @ iop
      d# 10 -rot (plx) drop ","  rn=d,  rn ?rd=rn set-zreg-sz  exit
   then   ( n adt )
   rd-adt <> " Rd and Rn " ?same-reg-type   ( n )
   dup <rd> <> if   ( n )  \ (vectors, unpredicated)
      ^rn   sve-op2 @ m.z.d rd??iop  "," rm ?rd=rm  exit
   then   ( n )  \ (immediate)
   drop   sve-op3 @  iop   ","
   sve-neg? @ encode-imm13  5 6 ^^op  11 6 ^^op  17 1 ^^op
;

: sve-and   0x2500.4000  0x041a.0000  0x0420.3000  0x0580.0000  0  sve-log  ;
: sve-bic   0x2500.4010  0x041b.0000  0x04e0.3000  0x0580.0000  1  sve-log  ;
: sve-eor   0x2500.4200  0x0419.0000  0x04a0.3000  0x0540.0000  0  sve-log  ;
: sve-orr   0x2580.4000  0x0418.0000  0x0460.3000  0x0500.0000  0  sve-log  ;

: %sve-and   ( -- )   <asm  sve-and  asm>  ;
: %sve-bic   ( -- )   <asm  sve-bic  asm>  ;
: %sve-eor   ( -- )   <asm  sve-eor  asm>  ;
: %sve-orr   ( -- )   <asm  sve-orr  asm>  ;

: sve-shift   ( op-immp op-immu op-vec op-widep op-wideu -- )
   sve-op4 !  sve-op3 !  sve-op2 !  sve-op1 !  sve-op0 ! 
   rd,
   reg "," dup m.z.bhsd adt? if   ( rn rn-adt )
      is rn-adt  5 ^r
      #? if   \ must be (immediate, unpredicated)
	 sve-op1 @ m.z.bhsd rd??iop  ?rd=rn  tsz-imm3-hi
      else   \ must be (wide elements, unpredicated)
	 set-zreg-sz
	 sve-op4 @ m.z.bhs rd??iop  rm  m.z.d rm??  
      then
      exit
   then   ( rn rn-adt )
   dup m.p/m adt? 0= ?invalid-regs    ( rn rn-adt )
   10 -rot (plx) drop rn=d,  
   #? if   \ must be (immediate, predicated)
      sve-op0 @ m.z.bhsd rd??iop  tsz-imm3-lo
      exit
   then
   set-zreg-sz 
   rn  rn-mask m.z.d = rd-mask m.z.d <> land if   \ must be (wide elements, predicated)
      sve-op3 @ m.z.bhs rd??iop  exit
   then   \ must be (vectors)
   sve-op2 @ iop
;

: sve-asr   0x0400.8000  0x0420.9000  0x0410.8000  0x0418.8000  0x0420.8000  sve-shift  ;
: sve-lsl   0x0403.8000  0x0420.9c00  0x0413.8000  0x041b.8000  0x0420.8c00  sve-shift  ;
: sve-lsr   0x0401.8000  0x0420.9400  0x0411.8000  0x0419.8000  0x0420.8400  sve-shift  ;

: %sve-asr   ( -- )   <asm  sve-asr  asm>  ;
: %sve-lsl   ( -- )   <asm  sve-lsl  asm>  ;
: %sve-lsr   ( -- )   <asm  sve-lsr  asm>  ;

: (cadd)   ( -- )   rde,  rn, sq-angle 10 ^op  ;
: (cdot)   ( -- )
   rd, rn, rm  ?rn=rm
   rd-adt m.z.d adt? dup if   ( sz )
      1 22 ^op   m.z.h rn??
   else   ( sz )
      m.z.s rd??   m.z.b rn??
   then   ( sz )
   [? if  ( sz )   \ must be CDOT (indexed)
      0x44a0.4000 iop   ( sz )
      if    1 get-index  20 1 ^^op
      else  2 get-index  19 2 ^^op
      then
   else   ( sz )    \ must be CDOT (vectors)
      drop  0x4400.1000 iop
   then
    "," square-angle  10 2 ^^op
;
: (cmla)   ( -- )
   rd, rn, rm  ?rd=rn=rm
   [? if   \ must be CMLA (indexed)
      0x44a0.6000 m.z.hs rd??iop
      rd-adt m.z.s = 
      if    1 get-index  20 1 ^^op   1 22 ^op
      else  2 get-index  19 2 ^^op
      then
   else   \ must be CMLA (vectors)
      0x4400.2000  m.z.bhsd rd??iop  set-zreg-sz  ?rd=rn=rm
   then
    "," square-angle  10 2 ^^op
;

: (clast)   ( op -- )
   iop  rd, pl, rn=d, rn
   rd-adt m.wx   adt? if   0x0010.2000  iop  (gpz)   exit  then
   rd-adt m.bhsd adt? if   0x000a.0000  iop  ?rd=zn  exit  then
   m.z.bhsd rd??           0x0008.0000  iop  ?rd=rn
;
: %clast   ( op -- )   <asm  (clast)  asm>  ;

: %cmps#   ( op regs -- )
   swap dup  >r
   0xffff.7fff land swap
   <asm   rd, rd??iop  plz, rn, set-preg-sz
   #? if
      ?pd=zn  5 #simm  16 5 ^^op
      r@ 0x0100.0000 or iop
   else
      rm   rn<rm? if   \ wide
	 r@ 0x0000.8000 land if  0x0000.2000  else  0x0000.4000   then  iop
      else        \ vector
	 ?pd=zn=zm
	 r@ 0x0000.8000 land if  0x0000.a000  else  0x0000.8000  then  iop
      then
   then
   asm>
   r> drop
;
: %cmpu#   ( op regs -- )
   <asm   rd, rd??iop  plz, rn, set-preg-sz
   #? if
      ?pd=zn  7 #uimm  14 7 ^^op
      0x0020.0000 iop
   else
      rm  rn<rm? if   \ wide
	 0x0000.c000 iop
      else        \ vector
	 ?pd=zn=zm
      then
   then
   asm>
;

: %cmps#r   ( op regs -- )   \ vector case gets rm before rn, how convenient...
   <asm   rd, rd??iop  plz,  set-preg-sz
   reg  ","  ( rn rn-adt )
   #? if    ( rn rn-adt )
      is rn-adt   ^rn
      ?pd=zn  5 #simm  16 5 ^^op
      0x0100.2000 iop
   else   ( rn rn-adt )
      reg rot   ( rn rm rn-adt rm-adt )
      over adt>size over adt>size > if   \ wide
	 is rm-adt  is rn-adt  ^rm ^rn
	 0x0000.6000  iop
      else   ( rn rm rn-adt rm-adt )   \ vector
	 is rn-adt  is rm-adt  ^rn  ^rm   \ swap rn with rm
	 ?pd=zn=zm
	 0x0000.8000  iop
      then
   then
   asm>
;
: %cmpu#r   ( op regs -- )   \ vector case gets rm before rn, how convenient...
   <asm   rd, rd??iop  plz, set-preg-sz
   reg  ","  ( rn rn-adt )
   #? if
      is rn-adt   ^rn
      ?pd=zn  7 #uimm  14 7 ^^op
      0x0020.2000 iop
   else   ( rn rn-adt )
      reg rot   ( rn rm rn-adt rm-adt )
      over adt>size over adt>size > if   \ wide
	 is rm-adt  is rn-adt  ^rm  ^rn
	 0x0000.e000  iop
      else        \ vector
	 is rn-adt  is rm-adt  ^rn  ^rm   \ swap rn with rm
	 ?pd=zn=zm
	 0x0000.0010 opcode xor is opcode
      then
   then
   asm>
;

: %cpy   ( op regs -- )
   <asm   rd, rd??iop   set-zreg-sz
   reg ","  dup m.px adt? 0= " P/M or P/Z " ?expecting   ( p p-adt )
   #? if   ( p p-adt )
      swap 16 4 ^^op   m.p/m adt? if  0x0010.4000  else  0x0010.0000  then  iop
      8 #simm 5 8 ^^op  ","? if  lsl#8  1 13 1 ^^op  then
   else   ( p p-adt )
      swap 10 3 ^^op    m.p/m adt? 0= " P/M " ?expecting
      rn|rsp  rn-adt m.wx adt? if
	 0x0028.a000 iop   (z,g)
      else
	 0x0020.8000 iop   (z,s)
      then
   then
   asm>
;

: %cterm   ( op regs -- )
   <asm   rn, rn??iop  rm
   rn-adt m.x adt? if  1 22 1 ^^op  then
   asm>
;

: %sve-eon    ( op regs -- )
   <asm   rd, rd??iop  rn=d,  
   true encode-imm13  5 6 ^^op  11 6 ^^op  17 1 ^^op
   asm>
;
: %sve-ext   ( op regs -- )
   <asm  rd, rd??iop
   {? if
      0x0040.0000 iop
      (getlist) is rn-adt  ?rd=rn  ( n count )
      2 <> " a register pair " ?expecting   ^rn ","
   else
      rn=d, rn,  ?rd=rn
   then
   #uimm8  dup 7 and 10 3 ^^op  3 >> 16 5 ^^op
   asm>
;

: sve-pattern    ( -- n )
   <c  dup 0= if   c>  31  exit  then 
   2dup upper $case
      " VL128" $sub c>  12  endof
      " VL16"  $sub c>   9  endof
      " VL256" $sub c>  13  endof
      " VL32"  $sub c>  10  endof
      " VL64"  $sub c>  11  endof
      " POW2"  $sub c>   0  endof
      " VL1"   $sub c>   1  endof
      " VL2"   $sub c>   2  endof
      " VL3"   $sub c>   3  endof
      " VL4"   $sub c>   4  endof
      " VL5"   $sub c>   5  endof
      " VL6"   $sub c>   6  endof
      " VL7"   $sub c>   7  endof
      " VL8"   $sub c>   8  endof
      " MUL4"  $sub c>  29  endof
      " MUL3"  $sub c>  30  endof
      " ALL"   $sub c>  31  endof
      c> #uimm5  " uimm5"
   $endcase
;
: %sve-inc   ( -- )
   <asm   rd rd??iop   ","? if
      sve-pattern  5 5 ^^op
      ","? if  " MUL" ?$match  #uimm5 dup 16 > " 1 to 16" ?expecting 1-  16 4 ^^op  then
   else
      31 5 5 ^^op   \ set pattern to default ALL
   then
   asm>
;

: %last   ( op regs -- )
   <asm  rd, rd??iop  pl, rn
   \ rn-mask zreg-sz  22 2 ^^op
   rd-adt m.wx adt? if  0x0000.2000 iop  (gpz)  else  0x0002.0000 iop  (spz)  then
   asm>
;


: adt-set-index   ( -- )
   rd-mask case
      m.z.h of   3 get-index dup 2 >> 1 and 22 1 ^^op  3 and 19 2 ^^op   endof
      m.z.s of   2 get-index 19 2 ^^op   endof
      m.z.d of   1 get-index 19 1 ^^op   endof
      true ?invalid-regs
   endcase
;
: %sve-sudot   ( op regs -- )
   <asm  rd, rd??iop  rn, rm   m.z.b rn??  ?rn=rm   adt-set-index  asm>
;
: %sve-usdot   ( op regs -- )
   <asm  rd, rd??iop  rn, rm   m.z.b rn??  ?rn=rm
   [? if   adt-set-index  0x44a0.1800  else  0x4480.7800  then  iop
   asm>
;

: %sve-mla
   <asm  rd,  reg "," dup m.p/m adt? if   ( rn rn-adt )   \ must be MLA (vectors)
      10 -rot (plx) drop
      0x0400.4000 iop  rn, rm  ?rd=rn=rm set-zreg-sz
   else   ( rn rn-adt )   \ must be MLA (indexed)
      is rn-adt  ^rn
      0x4420.0800 iop  rm  ?rd=rn=rm  set-zreg-sz
     adt-set-index
   then
   asm>
;
: %sve-mls
   <asm  rd,  reg "," dup m.p/m adt? if   ( rn rn-adt )   \ must be MLA (vectors)
      10 -rot (plx) drop
      0x0400.6000 iop  rn, rm  ?rd=rn=rm set-zreg-sz
   else   ( rn rn-adt )   \ must be MLA (indexed)
      is rn-adt  ^rn
      0x4420.0c00 iop  rm  ?rd=rn=rm  set-zreg-sz
      adt-set-index
   then
   asm>
;
: %sve-mul
   <asm  rd,  reg "," dup m.p/m adt? if   ( rn rn-adt )   \ must be MUL (vectors, pred)
      10 -rot (plx) drop
      0x0410.0000 iop  rn=d, rn  ?rd=rn set-zreg-sz
   else   ( rn rn-adt )   \ must be MUL (indexed)
      2dup rd-adt = swap <rd> = land if   ( rn rn-adt )   \ must be MUL (imm)
	 2drop
	 0x2530.c000 iop  #uimm8  5 8 ^^op
      else
	 is rn-adt  ^rn  rm  ?rd=rn=rm 
	 [? if   \ must be MUL (indexed)
	    0x4420.f800 iop   adt-set-index
	 else   \ must be MUL (vectors, unpred)
	    0x0420.6000 iop  set-zreg-sz
	 then
      then
   then
   asm>
;

: %sve-while   ( cond -- )
   <asm  dup 2/ 10 2 ^^op  1 land   ( eq )
   {? if   ( eq )   \ mask, multiple
      0 ^op
      getlist  2 <> " a register pair " ?expecting
      7 and 2* ^rd  ","
      0x2520.5010 m.p.bhsd rd??iop
      xn, xm
   else   ( eq )
      rd,
      rn, rm ?rn=rm  set-preg-sz
      ","? if   ( eq )   \ counter
	 3 ^op
	 0x2520.4010 m.p.bhsd rd??iop  m.x rn??
	 <c case
	    " VLx2" $sub  c>  0  endof
	    " VLx4" $sub  c>  1  endof
	    true ?invalid-regs
         endcase
         13 1 ^^op
      else   ( eq )   \ mask, single
	 4 ^op
	 0x2520.0000 m.p.bhsd rd??iop
	 m.wx rn?? Xn?  if  1 12 ^op  then
      then
   then
   asm>
;


: <mod>   ( -- n )
   " uxtw" $match? if  0 exit  then  2drop
   " sxtw" $match? if  1 exit  then  2drop
   " lsl"  $match? if  2 exit  then  2drop
   " uxtw, sxtw, or lsl " expecting
;
: ldsz   ( -- )
   rd-mask case
      m.z.b of   0x0000.0000   endof
      m.z.h of   0x0020.0000   endof
      m.z.s of   0x0040.0000   endof
      m.z.d of   0x0060.0000   endof
   endcase   iop
;

: (ld1-scalar-imm)   ( comma? -- op )
   if   4 #simm  16 4 ^^op ","   " mul vl" $match?  0= " mul vl" ?expecting  then
   "]"  ldsz  0xa400.a000
;
: (ld1-scalar-scalar)   ( -- op )
   opcode 23 >> 3 and ?dup if
      ","  "lsl"  #uimm2 <> " correct size" ?expecting
   then
   "]"  ldsz   0xa400.4000
;
: (ld1-scalar-vector)   ( -- op )
   ?rd=rm  ","? if
      <mod> dup 2 = if   \ LSL
	 opcode 0x0180.0000 land 0= if  undefined  then
	  #uimm2 2drop  m.z.d rd??  0x4060.c000 iop   \ 64s
      else
	 22 1 ^^op   m.z.sd rd??
	 rd-mask  m.z.d adt? if   0x4000.0000  iop  then   \ 32uu 32u
	 #? if   #uimm2 drop  0x0020.0000 iop  then	   \ 32us 32s
      then
   else
      m.z.d rd??   0x4040.8000  iop   \ 64u
   then
   "]"  0x8400.4000
;

: ?vi-#uimm ( sz -- n )
	"##" unimm dup rot
	case
		0 of  d#  31 > " 0-31"  ?expecting      endof
		1 of  d#  62 > " 0-62"	?expecting 1 >> endof
		2 of  d# 124 > " 0-124" ?expecting 2 >> endof
		3 of  d# 248 > " 0-248" ?expecting 3 >> endof
	endcase
	;

: (ld1-vector-imm)   ( -- op )
   ","? if  msz ?vi-#uimm  16 5 ^^op  then
   ?rd=rn   m.z.sd rd??
   rd-mask  m.z.d adt? if   0x4000.0000  iop  then
   "]"  0x8420.c000
;

: %ld1   ( op regs -- )
   <asm  
   getlist  ( n count ) 1 <> " list of one register " ?expecting  ^rd  ","    ( op regs )
   rd??iop   plz,  "[" reg is rn-adt rn-adt m.x adt? if         \ rn|rsp   rn-adt m.x adt? if
   	  dup d# 32 = if 1- then ^rn
      ]? if
	 false (ld1-scalar-imm)
      else
	 "," #? if
	    true (ld1-scalar-imm)
	 else
	    rm  rm-adt m.x adt? if
	       (ld1-scalar-scalar)
	    else
	       (ld1-scalar-vector)
	    then
	 then
      then
   else
      5 5 ^^op  (ld1-vector-imm)
   then
   iop   asm>
;

\ these are merged with the SME versions in instructions-mix.fth
: %ld1b   0x0000.0000 m.z.bhsd %ld1  ;
: %ld1h   0x0080.0000 m.z.hsd  %ld1  ;
: %ld1w   0x0100.0000 m.z.sd   %ld1  ;
: %ld1d   0x0180.0000 m.z.d    %ld1  ;

: %ldn   ( op regs n -- )
   <asm   >r
   getlist  ( n count ) r@  <> " list of registers " ?expecting  ^rd  ","   ( op regs )
   rd??iop  plz,  [xn|sp  "]"? if
      0xa400.e000
   else
      "," "#"? if
	 snimm  r@ /   4 #simm-check
	 16 4 ^^op ","   " mul vl" $match?  0= " mul vl" ?expecting  "]"
	 0xa400.e000
      else
	 xm
	 rd-mask adt>size reg-sz ?dup if
	    "," "lsl"  #uimm4 <> " correct shift" ?expecting
	 then
	 "]"   0xa400.c000
      then
   then
   r> drop
   iop   asm>
;

: lsl#n ( n -- )
   dup if
      "lsl" #uimm2 <> " correct size" ?expecting
   else
      drop " no lsl #" expecting
   then
   ;
: ?"mul_vl" ( -- )
   " mul vl" $match? 0= if -rot ?expecting then
   ;

: %ld1r(s) ( op mask xor -- )              \ xor - 3 for signed load, else 0
   <asm   >r
      getlist  ( n count ) 1 <> " list of one register " ?expecting
      ^rd  "," rd??iop  rd-mask zreg-sz r@ xor 13 2 ^^op  plz,  [xn|sp
      ","? if
         "##" unimm 1 msz r@ xor <<  2dup 2dup / * <> " a multiply of 2, 4, 8" ?expecting
         / 16 6 ^^op
      then
      "]"
   r> drop  asm>
   ;
: %ld1ro/q ( op mask mul -- )
  <asm  >r
      getlist  ( n count ) 1 <> " list of one register " ?expecting
      ^rd  "," rd??iop  plz,  [xn|sp
      ","? if
         #? if
            1 13 ^op
            "##" snimm r@ 2dup 2dup / * <> " a multiply of 16 or 32" ?expecting
            / 4 #simm-check 16 4 ^^op
         else
            xm ]? not if "," rd-mask zreg-sz lsl#n then               \ ss
         then
     else
         1 13 ^op
     then
     "]"
   r> drop  asm>
   ;
: %ldnt1 ( op mask -- )
   <asm
      getlist  ( n count ) 1 <> " list of one register " ?expecting
      ^rd  "," rd??iop  plz,  "[" reg ( n adt )
      dup m.x adt? if
         rd-mask zreg-sz  msz <> " correct size" ?expecting
         drop  dup 32 = if 1- then  ^rn  1 29 ^op
         ","? if
            #? if
               "##" snimm 4 #simm-check  16 4 ^^op
               "," ?"mul_vl"  0x6000                           \ si
            else
               xm rd-mask zreg-sz ?dup if "," lsl#n then       \ ss
               0x4000
            then
         else
            0x6000                                  \ si
         then
      else
         is rn-adt ?rd=rn ^rn                       \ vi
         msz 3 = if
            rd-mask m.z.bhs adt? " .d" ?expecting
         else
            rd-mask m.z.bh  adt? " .s or .d" ?expecting
         then
          rd-mask zreg-sz case
            2 of   0x2000        endof
            3 of   0x4000.4000   endof
         endcase
          ","? if xm  else  31 ^rm  then
      then
      "]" iop
   asm>
   ;
: %ldnt1s ( op mask -- )
   <asm
      getlist  ( n count ) 1 <> " list of one register " ?expecting
      ^rd  "," rd??iop  plz,  "[" rn ?rd=rn
      ","? if xm else 31 ^rm then
      rd-mask zreg-sz 3 = if  1 30 ^op  then
      "]"
   asm>
   ;
: %ldnf1 ( op mask xor -- )                                       \ xor - 3 for signed load, else 0
   <asm  >r
      getlist  ( n count ) 1 <> " list of one register " ?expecting
      ^rd  "," rd??iop  plz,  [xn|sp
       ","? if 4 #simm  16 4 ^^op "," ?"mul_vl" then
      rd-mask zreg-sz r@ xor 21 2 ^^op
      "]"
   r> drop asm>
   ;
: %ldff1(s) ( op mask xor -- )                                       \ xor - 3 for signed load, else 0
   <asm  >r
      getlist  ( n count ) 1 <> " list of one register " ?expecting
      ^rd  "," rd??iop  plz,  "[" reg is rn-adt
      rn-mask m.x adt? if
         dup d# 32 = if 1- then ^rn
         ","? if
            rm rm-mask m.x adt? if
               rd-mask zreg-sz r@ xor  21 2 ^^op                  \ ss
               ","? if  msz lsl#n  then
               r@ 23 << opcode xor is opcode
               0x2000.4000 iop
            else
               ?rd=rm rd-mask zreg-sz 30 2 ^^op                   \ sv
               ","? if
                  <mod> dup 2 = if
                     drop #? if
                        #uimm2 msz <> " correct lsl #" ?expecting
                     then
                     0x60.8000 iop                                \ lsl #
                  else
                     22 ^op                                       \ uxtw or sxtw - xs
                     #? if
                        #uimm2  msz <> " correct uxtw or sxtw #" ?expecting
                        0x20.0000 iop
                     then
                  then
               else
                  0x40.8000 iop                                     \ 64 us
               then
            then
         else
            rd-mask zreg-sz r@ xor  21 2 ^^op                       \ ss
            31 16 5 ^^op                                           \ xzr
            r@ 23 << opcode xor is opcode
            0x2000.4000 iop
         then
      else
         5 5 ^^op
         ?rd=rn ","? if                                             \ vi
            "##" unimm 1 msz << 2dup 2dup / * <> " a multiply of 2,4,8" ?expecting
            / 16 5 ^^op
         then
         rd-mask zreg-sz 30 2 ^^op
         0x20.8000 iop
      then
      "]"
    r> drop asm>
   ;


: ldssz   ( -- )
   rd-mask case
      m.z.h of   0x0040.0000   endof
      m.z.s of   0x0020.0000   endof
      m.z.d of   0x0000.0000   endof
      " .hsd" expecting
   endcase   iop
;
: msz?? ( n - )
   opcode 23 >> 3 and <>  " matching #" ?expecting
   ;

: (ld1s-scalar-imm)   ( comma? -- op )
   if   4 #simm  16 4 ^^op ","   " mul vl" $match?  0= " mul vl" ?expecting  then
   "]"  ldssz  0x2000.a000
;
: (ld1s-scalar-scalar)   ( -- op )
   opcode 23 >> 3 and 3 xor ?dup if
      ","  "lsl"  #uimm2 <> " correct size" ?expecting
   then
   "]"  ldssz   0x2000.4000
;

: (ld1s-scalar-vector)   ( -- op )
   ?rd=rm  ","? if
      <mod> dup 2 = if   \ LSL
         opcode 0x0180.0000 land 0= if  undefined  then
         drop m.z.d rd??
         #uimm2 msz??  0x4060.8000 iop   \ 64s
      else
         22 1 ^^op   m.z.sd rd??
         rd-mask  m.z.d adt? if  0x4000.0000 iop  then   \ 32uu 32u
         #? if   #uimm2 msz??    0x0020.0000 iop  then   \ 32us 32s
      then
   else
      m.z.d rd??   0x4040.8000  iop   \ 64u
   then
   "]" 0x0000.0000
;
: (ld1s-vector-imm)   ( -- op )
   ","? if  msz ?vi-#uimm  16 5 ^^op  then
   ?rd=rn   m.z.sd rd??
   rd-mask  m.z.d adt? if   0x4000.0000  iop  then
   "]"  0x0020.8000
;

: %ld1s ( op regs -- )
   <asm
   getlist  ( n count ) 1 <> " list of one register " ?expecting  ^rd  ","    ( op regs )
   rd??iop   plz,  "[" reg is rn-adt  rn-adt m.x adt? if
      dup 32 = if 1- then ^rn
      ]? if
         opcode 3 23 << xor is opcode
         false (ld1s-scalar-imm)
      else
         "," #? if
            opcode 3 23 << xor is opcode
            true (ld1s-scalar-imm)
         else
            rm  rm-adt m.x adt? if
               opcode 3 23 << xor is opcode
               (ld1s-scalar-scalar)
            else
               (ld1s-scalar-vector)
            then
         then
      then
   else
      5 5 ^^op  (ld1s-vector-imm)
   then
   iop   asm>
;

: (st1-scalar-imm)   ( comma? -- op )
   if   4 #simm  16 4 ^^op ","   " mul vl" $match?  0= " mul vl" ?expecting  then
   "]"  ldsz  0xe400.e000
;
: (st1-scalar-scalar)   ( -- op )
   opcode 23 >> 3 and ?dup if
      ","  "lsl"  #uimm2 <> " correct size" ?expecting
   then
   "]"  ldsz   0xe400.4000
;
: (st1-scalar-vector)   ( -- op )
   ?rd=rm  ","? if
      <mod> dup 2 = if   \ LSL
         opcode 0x0180.0000 land 0= if  undefined  then
         drop m.z.d rd??
         #uimm2 msz??  0xe420.a000 iop   \ 64s
      else
         14 ^op   m.z.sd rd??
         rd-mask  m.z.s adt? if 0x40.0000 iop  then    \ 32uu 32u
         #? if   #uimm2 msz??   0x20.0000 iop  then    \ 32us 32s
         0xe400.8000 iop
      then
   else
      m.z.d rd??   0xe400.a000  iop   \ 64u
   then
   "]" 0x0000.0000
;

: (st1-vector-imm)   ( -- op )
   ","? if  msz ?vi-#uimm  16 5 ^^op  then
  ?rd=rn   m.z.sd rd??
   rd-mask  m.z.d adt? if 2 else 3 then d# 21 2 ^^op
   "]"  0xe440.a000
;

: %st1   ( op regs -- )
   <asm
   getlist  ( n count ) 1 <> " list of one register " ?expecting  ^rd  ","    ( op regs )
   rd??iop   pl,  "[" reg is rn-adt  rn-adt m.x adt? if
      dup 32 = if 1- then ^rn
      ]? if
         false (st1-scalar-imm)
      else
         "," #? if
            true (st1-scalar-imm)
         else
            rm  rm-adt m.x adt? if
               (st1-scalar-scalar)
            else
               (st1-scalar-vector)
            then
         then
      then
   else
      5 5 ^^op  (st1-vector-imm)
   then
   iop   asm>
;

: %stn   ( op regs n -- )
   <asm   >r
   getlist  ( n count ) r@  <> " list of registers " ?expecting  ^rd  ","   ( op regs )
   rd??iop  pl,  [xn|sp  "]"? if
      0xe410.e000
   else
      "," "#"? if
    snimm  r@ /   4 #simm-check
    16 4 ^^op ","   " mul vl" $match?  0= " mul vl" ?expecting  "]"
    0xe410.e000
      else
    xm
    rd-mask adt>size reg-sz ?dup if
       "," " lsl"  ?$match #uimm4 <> " correct shift" ?expecting
    then
    "]"   0xe400.6000
      then
   then
   r> drop
   iop   asm>
;
: %stnt1 ( op mask -- )
   <asm
      getlist  ( n count ) 1 <> " list of one register " ?expecting
      ^rd  "," rd??iop pl,  "[" reg is rn-adt  rn-adt m.x adt? if
         dup 32 = if 1- then ^rn
         ","? if
            #? if
               4 #simm 16 4 ^^op "," ?"mul_vl"
               0x10.c000                       \ si
            else
               xm ","?
               if  rd-mask zreg-sz lsl#n  then
               0x4000                          \ ss
            then
         else
            0x10.c000                          \ si
         then
      else
         5 5 ^^op
         ?rd=rn  ","? if  xm  else  0x1f 16 5 ^^op  then     \ vs
         rd-mask m.z.s adt? if  0x40.0000 else 0 then
      then
      "]" iop
   asm>
;

: %p>p      <asm  2long  asm>   ;
: (pmov)   ( -- )
   rd,  reg   ( n adt )
   dup m.p/m adt? if      \ MOV (predicate, predicated, merging)
      drop 10 3 ^^op "," rn   ?rd=rn  0x2500.4210 iop   exit
   then   ( rn rn-adt )
   dup m.p/z adt? if      \ MOV (predicate, predicated, zeroing)
      drop 10 3 ^^op "," rn   ?rd=rn  0x2500.4000 iop   exit
   then   ( rn rn-adt )   \ MOV (predicate, unpredicated)
   is rn-adt  ^rn   ?rd=rn  0x2580.4000 iop
;
: %pmov   <asm  (pmov)  asm>  ;

: zmovp   ( -- )
   <asm  rd,  reg ","   ( n adt )
   #? if  ( n adt )
      m.p/z adt? if
	 0x0510.0000   \ MOV (immediate, predicated, zeroing)
      else
	 0x0510.4000   \ MOV (immediate, predicated, merging)
      then  iop  16 4 ^^op   8 #simm 5 8 ^^op
      ","? if   lsl#8   1 13 1 ^^op  then   exit
   then   ( n adt )
   reg is rn-adt   dup 32 = if  ( SP ) drop 31   then  ^rn
   
   rn-adt m.z.bhsd adt? if   ( n adt )   \ MOV (vector, predicated)
      drop  10 4 ^^op   0x0520.c000 iop   set-zreg-sz  exit
   then    ( n adt )
   drop 10 3 ^^op
   rn-adt m.bhsd adt? if      \ MOV (SIMD&FP scalar, predicated)
      (z,s)   0x0520.8000 iop
      exit
   then
   \ MOV (scalar, predicated)
   (z,g)   0x0528.a000 iop
;
: zmovu   ( -- )
   <asm  rd,
   reg is rn-adt   dup 32 = if  ( SP ) drop 31   then  ^rn
   
   rn-adt m.z.bhsd adt? if   \ MOV (vector, unpredicated)
      ?rd=rn
      "["? if
	 ?rd=rn  tsz-imm2  "]"  0x0520.2000 iop
      else
	 <rn> ^rm 0x0460.3000 iop
      then
      exit
   then
   rn-adt m.bhsd adt? if     \ MOV (SIMD&FP scalar, unpredicated)
      tsz-mov  0x0520.2000 iop
      exit
   then
   \ MOV (scalar, unpredicated)
   (z,g)  0x0520.3800 iop
;

\ MOV (immediate, unpredicated)
\ MOV <Zd>.<T>, #<imm>{, <shift>}   ===  DUP <Zd>.<T>, #<imm>{, <shift>}
: mov#u
   0x2538.c000 m.z.bhsd  <asm  rd, rd??iop   8 #simm  5 8 ^^op
   ","? if  lsl#8  1 13 1 ^^op  then
;
: (dupm)
   0x05c0.0000  m.z.bhsd  <asm  rd, rd??iop  set-zreg-sz
   false encode-imm13  5 6 ^^op  11 6 ^^op  17 1 ^^op
;

\ zmov# can be either mov#u or %dupm; they are hard to distinguish
: zmov#   ( -- )
   2 0 try: case
      0 of  mov#u  endof
      1 of  (dupm)  endof
   endcase
;

: %zmov   ( -- )
   <asm  rd,  #? if  zmov#  else  reg nip m.px adt? if  zmovp  else  zmovu  then  asm>  then
;

: sve-cvtf.h
   rn-adt m.z.hsd adt? 0= ?invalid-regs
   rn-adt m.z.h adt? if  0x0042.0000  then
   rn-adt m.z.s adt? if  0x0044.0000  then
   rn-adt m.z.d adt? if  0x0046.0000  then
;
: sve-cvtf.s
   rn-adt m.z.sd adt? 0= ?invalid-regs
   rn-adt m.z.s adt? if  0x0084.0000  then
   rn-adt m.z.d adt? if  0x00c4.0000  then
;
: sve-cvtf.d
   rn-adt m.z.sd adt? 0= ?invalid-regs
   rn-adt m.z.s adt? if  0x00c0.0000  then
   rn-adt m.z.d adt? if  0x00c6.0000  then
;
: %cvtf
   <asm  rd, plm, rn  rd??iop
   rd-adt m.z.hsd adt? 0= ?invalid-regs
   rd-adt m.z.h adt? if  sve-cvtf.h  then
   rd-adt m.z.s adt? if  sve-cvtf.s  then
   rd-adt m.z.d adt? if  sve-cvtf.d  then
   iop asm>
;

:  sve-prfop,  ( -- )
   <c scantodelim c>  2dup upper $case
     " PLDL1KEEP"      $of   0  $endof
     " PLDL1STRM"      $of   1  $endof
     " PLDL2KEEP"      $of   2  $endof
     " PLDL2STRM"      $of   3  $endof
     " PLDL3KEEP"      $of   4  $endof
     " PLDL3STRM"      $of   5  $endof
     " PSTL1KEEP"      $of   8  $endof
     " PSTL1STRM"      $of   9  $endof
     " PSTL2KEEP"      $of  10  $endof
     " PSTL2STRM"      $of  11  $endof
     " PSTL3KEEP"      $of  12  $endof
     " PSTL3STRM"      $of  13  $endof
   true " a PRFOP field name" ?expecting  
   $endcase    ( $ instr-encoding )
   0 5 ^^op
   adt-prfop is rd-adt
   "," 
;

: %sdot  ( op regs -- )
   <asm  rd, rn, rm   rd??iop  ?rn=rm
   rd-mask m.z.s adt? if
      m.z.b rn??
      [? if   2 get-index  19 2 ^^op  0x00a0.0000  iop  then
   else   m.z.h rn??
      [? if   1 get-index  20 1 ^^op  0x00e0.0000  else  0x0040.0000  then  iop
   then
   asm>
;

: %sli  ( op regs -- )   <asm  d=n  rd??iop "," tsz-imm3-hi  asm>  ;

: %smax
   <asm  rd, reg
   dup m.p/m adt? if  2drop  0x0408.0000 m.z.bhsd %zpez  exit  then
   (rn=d)  ","  8 #simm 5 8 ^^op  0x2528.c000  iop  asm>
;
: %umax
   <asm  rd, reg
   dup m.p/m adt? if  2drop  0x0409.0000 m.z.bhsd %zpez  exit  then
   (rn=d)  ","  8 #uimm 5 8 ^^op  0x2529.c000  iop  asm>
;
: %smin
   <asm  rd, reg
   dup m.p/m adt? if  2drop  0x040a.0000 m.z.bhsd %zpez  exit  then
   (rn=d) ","  8 #simm 5 8 ^^op  0x252a.c000  iop  asm>
;
: %umin
   <asm  rd, reg
   dup m.p/m adt? if  2drop  0x040b.0000 m.z.bhsd %zpez  exit  then
   (rn=d) ","  8 #uimm 5 8 ^^op  0x252b.c000  iop  asm>
;

: %smmla   <asm  rd, rn, rm   0x4500.9800 m.z.s rd??iop  ?rn=rm  m.z.b rn??   asm>  ;
: %splice   ( op regs -- )
   <asm  rd, rd??iop  pl,
   {? if
      (getlist) is rn-adt  ?rd=rn  ( n count )
      2 <> " a register pair " ?expecting   ^rn
      0x0001.0000 iop
   else
      rn=d, rn  ?rd=rn
   then
   asm>
;

: %zip-p   ( op regs -- )   <asm  d=n=m  rd??iop  set-preg-sz   asm>  ;
: %zip-z   ( op regs -- )
   <asm  d=n=m  rd??iop   rd-mask m.z.q = if
      0x0080.0000 iop
   else
      0x0000.6000 iop   set-zreg-sz   
   then
   asm>
;



: fabd_sve   0x6508.8000 m.z.hsd %zpzzn ;
: fabs_sve   0x041c.a000 m.z.hsd %zpz ;
: #fimm=05|10
   #i.fimm 2dup
   2dup =1.0 -rot =0.5 or not if 1 " #0.5 or #1.0" ?expecting then
   =1.0 if 1 5 1 ^^op then
;
: fadd_sve   0x6500.0000 m.z.hsd
   <asm rd, rd??iop reg "," ( n adt )
      dup m.p/m adt? if
         drop  10 3 ^^op  rn=d,
         #? if
            #fimm=05|10  0x18.8000 iop             \ imm predicate
         else
            rn ?rd=rn    0x00.8000 iop             \ vector predicate
         then
      else
         is rn-adt ?rd=rn 5 5 ^^op rm ?rd=rm       \ vectore unpredicate
      then
      set-zreg-sz
   asm>
;

: faddp_sve  0x6410.8000 m.z.hsd %zpzzn ;
: fcadd_sve  0x6400.8000 m.z.hsd %zpzzn-const ;

: fsub_sve   0x6500.0000 m.z.hsd
   <asm rd, rd??iop reg "," ( n adt )
      dup m.p/m adt? if
         drop  10 3 ^^op  rn=d,
         #? if
            #fimm=05|10  0x19.8000              \ imm predicate
         else
            rn ?rd=rn    0x01.8000              \ vector predicate
         then
      else
         is rn-adt ?rd=rn 5 5 ^^op rm ?rd=rm        \ vectore unpredicate
         0x400
      then
      set-zreg-sz
      iop
   asm>
;
: #fimm=05|20
   #i.fimm 2dup
   2dup =2.0 -rot =0.5 or not if 1 " #0.5 or #2.0" ?expecting then
   =2.0 if 1 5 1 ^^op then
;
\ expecting Z0-Z7 for .hs and Z0-Z15 for .d
: ?zm-sz ( n -- n )
   dup rd-mask zreg-sz case
      1 of   7 > " Z0-Z7"  ?expecting  endof
      2 of   7 > " Z0-Z7"  ?expecting  endof
      3 of  15 > " Z0-Z15" ?expecting  endof
   endcase
;
: zmx[imm] ( n - )
   ?zm-sz
   "["  unimm dup rd-mask zreg-sz case ( n imm imm )
      1 of 7 > " 0-7" ?expecting  dup 3 and 19 2 ^^op 2 >> 22 ^op   16 3 ^^op  endof     \ imm ^rm )
      2 of 3 > " 0-3" ?expecting            19 2 ^^op  2 22 2 ^^op  16 3 ^^op  endof     \ imm [23:22]=zsize ^rm
      3 of 1 > " 0-1" ?expecting            20 ^op     3 22 2 ^^op  16 4 ^^op  endof     \ imm [23:22]=zsize ^rm
   endcase
   "]"
;
: fmul_sve   0x6400.0000 m.z.hsd
   <asm rd, rd??iop reg "," ( n adt )
      dup m.p/m adt? if
         drop  10 3 ^^op rn=d,
         #? if
            #fimm=05|20  0x11a.8000           \ imm predicate
         else
            rn  ?rd=rn   0x102.8000           \ vector predicate
         then
         set-zreg-sz
      else
         is rn-adt 5 5 ^^op ?rd=rn
         reg ( n adt ) is rm-adt ?rd=rn=rm
         [? if
            zmx[imm] 0x20.2000       \ index
         else
            16 5 ^^op                        \ ^rm
            set-zreg-sz
            0x100.0800                       \ vectore unpredicate
         then
      then
   iop
   asm>
;

: fmulx_sve  0x650a.8000 m.z.hsd %zpzzn ;
: fdiv_sve   0x650d.8000 m.z.hsd %zpzzn ;
: fcmgt_sve  0x6500.0000 m.p.hsd
   <asm  pd, rd??iop plz, rn,
   #? if
       ?pd=zn
       "##" " 0.0" $match? 0= " #0.0" ?expecting
       0x10.2010 iop
   else
      rm ?pd=zn=zm
      0x4010 iop
   then
   set-preg-sz
   asm>
;
: fcmeq_sve  0x6500.2000 m.p.hsd
   <asm  pd, rd??iop plz, rn,
   #? if
       ?pd=zn
       "##" " 0.0" $match? 0= " #0.0" ?expecting
       0x12.0000 iop
   else
      rm ?pd=zn=zm
      0x4000 iop
   then
   set-preg-sz
   asm>
;
: fcmge_sve  0x6500.0000 m.p.hsd
   <asm  pd, rd??iop plz, rn,
   #? if
       ?pd=zn
       "##" " 0.0" $match? 0= " #0.0" ?expecting
       0x10.2000 iop
   else
      rm ?pd=zn=zm
      0x4000 iop
   then
   set-preg-sz
   asm>
;
: fcmla_sve  0x6400.0000 m.z.hsd
    <asm rd, rd??iop reg "," ( n adt )
    dup adt-p/m = if
       10 -rot (plx) drop rn, rm,                                  \ vectors hsd
       ?rd=rn=rm set-zreg-sz square-angle d# 13 2 ^^op
    else
      m.z.hs rd??                                                  \ indexed hs
      0x20.1000 iop
      swap ^rn is rn-adt rm ?rd=rn=rm
      "[" unimm dup
       rd-mask zreg-sz case
         1 of  3 > if drop " 0-3" expecting then  2 d# 22 2 ^^op  d# 19 2 ^^op  endof        \ .h size i2
         2 of  1 > if drop " 0-3" expecting then  3 d# 22 2 ^^op  d# 20 ^op     endof        \ .s size i1
         2drop " .h .s " expecting
      endcase
      "]" "," square-angle d# 10 2 ^^op                                                      \ rot
   then
   asm>
;
: fcvt_sve  0x6588.a000 m.z.hsd
   <asm rd, rd??iop plm, rn
      rd-mask zreg-sz 2 << rn-mask zreg-sz or
      case
         b# 1001 of  0x0001.0000  endof          \ h->s
         b# 1101 of  0x0041.0000  endof          \ h->d
         b# 0110 of  0x0000.0000  endof          \ s->h
         b# 1110 of  0x0043.0000  endof          \ s->d
         b# 0111 of  0x0040.0000  endof          \ d->h
         b# 1011 of  0x0042.2000  endof          \ d->s
         " correct coversion sizes" expecting
      endcase
      iop
   asm>
;

: %fcvtx/nt   <asm rd, rd??iop plm, rn rn-mask m.z.d adt? 0= " .d" ?expecting asm> ;  \ Zd.s, Pg/m, Zn.d

: %fcvtzs/u
   <asm rd, rd??iop plm, rn
      rd-mask zreg-sz 2 << rn-mask zreg-sz or
      case
         b# 0101 of  0x0042.0000  endof          \ h->h
         b# 1001 of  0x0044.0000  endof          \ h->s
         b# 1101 of  0x0046.0000  endof          \ h->d
         b# 1010 of  0x0084.0000  endof          \ s->s
         b# 1110 of  0x00c4.0000  endof          \ s->d
         b# 1011 of  0x00c0.0000  endof          \ d->s
         b# 1111 of  0x00c6.2000  endof          \ d->d
         " correct coversion sizes" expecting
      endcase
      iop
   asm>
;
: fcvtzs_sve  0x6518.A000 m.z.hsd  %fcvtzs/u ;
: fcvtzu_sve  0x6519.A000 m.z.hsd  %fcvtzs/u ;

: %fminmax/nm
   <asm  rd, rd??iop plm, rn=d, set-zreg-sz
      #? if
         #i.fimm  2dup =0.0  -rot =1.0  dup if 1 5 ^op then
         or not " 0.0 or 1.0" ?expecting                               \ imm
         0x18.0000 iop
      else
         rn ?rd=rn                                                     \ vec
      then
   asm>
;
: fmax_sve      0x6506.8000 m.z.hsd  %fminmax/nm ;
: fmaxnm_sve    0x6504.8000 m.z.hsd  %fminmax/nm ;
: fmaxnmp_sve   0x6414.8000 m.z.hsd  %zpzzn ;
: fmaxnmv_sve   0x6504.2000 m.hsd    %vpzn ;
: fmaxp_sve     0x6416.8000 m.z.hsd  %zpzzn ;
: fmaxv_sve     0x6506.2000 m.hsd    %vpzn ;

: fmin_sve      0x6507.8000 m.z.hsd  %fminmax/nm ;
: fminnm_sve    0x6505.8000 m.z.hsd  %fminmax/nm ;
: fminnmp_sve   0x6415.8000 m.z.hsd  %zpzzn ;
: fminnmv_sve   0x6505.2000 m.hsd    %vpzn ;
: fminp_sve     0x6417.8000 m.z.hsd  %zpzzn ;
: fminv_sve     0x6507.2000 m.hsd    %vpzn ;
: %fmla
   <asm  rd, rd??iop reg "," dup m.p/m adt? if ( n adt )
         10 -rot (plx) drop rn, rm ?rd=rn=rm  set-zreg-sz      \ vec
         0x0100.0000 iop
      else
         is rn-adt 5 5 ^^op                                    \ idx
         reg ( n adt ) is rm-adt ?rd=rn=rm
         zmx[imm]
      then
   asm>
;
: fmla_sve      0x6420.0000 m.z.hsd   %fmla ;

: %fmls
   <asm  rd, rd??iop reg "," dup m.p/m adt? if ( n adt )
         10 -rot (plx) drop rn, rm ?rd=rn=rm  set-zreg-sz      \ vec
         0x0100.2000 iop
      else
         is rn-adt 5 5 ^^op  1 10 ^op                          \ idx
         reg ( n adt ) is rm-adt ?rd=rn=rm
         zmx[imm]
      then
   asm>
;
: fmls_sve      0x6420.0000 m.z.hsd   %fmls ;

: %fmla/slb/lt
   <asm rd, rd??iop rn, rn-mask m.z.h adt? not " .h" ?expecting
      reg ( n adt ) is rm-adt ?rn=rm ( n )
      "["? if
         dup 7 > " Z0-Z7" ?expecting 16 3 ^^op        \ Zm 3 bits
         unimm dup 7 > " 0-7" ?expecting  dup 1 and 11 ^op  1 >> 19 2 ^^op
         0x0000.4000
         "]"
      else
         16 5 ^^op
         0x0000.8000
      then
   iop asm>
;

: fneg_sve  0x041d.a000 m.z.hsd  %zpz ;
: frecpe_sve    0x650e.3000 m.z.hsd  %zz ;
: frecps_sve    0x6500.1800 m.z.hsd  %zzz ;
: frecpx_sve    0x650c.a000 m.z.hsd  %zpz ;

: frinti_sve   0x6507.a000 m.z.hsd %zpz ;
: frintx_sve   0x6506.a000 m.z.hsd %zpz ;
: frinta_sve   0x6504.a000 m.z.hsd %zpz ;
: frintn_sve   0x6500.a000 m.z.hsd %zpz ;
: frintz_sve   0x6503.a000 m.z.hsd %zpz ;
: frintm_sve   0x6502.a000 m.z.hsd %zpz ;
: frintp_sve   0x6501.a000 m.z.hsd %zpz ;

: frsqrte_sve   0x650f.3000 m.z.hsd  %zz ;
: frsqrts_sve   0x6500.1c00 m.z.hsd  %zzz ;
: fsqrt_sve 0x650d.a000 m.z.hsd  %zpz ;

: (prf-scalar-imm)   ( sz comma? -- op )
   if   6 #simm  16 6 ^^op ","   " mul vl" $match?  0= " mul vl" ?expecting  then  ( sz )
   13 2 ^^op   "]"    0x85c0.0000
;
: (prf-scalar-scalar)   ( sz -- op )
    dup 23 2 ^^op  ?dup if
      ","  "lsl"  #uimm2 <> " correct size" ?expecting
   then
   "]"   0x8400.c000
;
: (prf-scalar-vector)   ( sz -- op )
   13 2 ^^op  ","? if
      <mod> dup 2 = if   \ LSL
	 opcode 0x0000.6000 land 0= if  undefined  then
	  #uimm2 2drop  0x4040.8000 iop   \ 64s
      else  ( mod )
	 22 1 ^^op
	 rm-adt m.z.d adt? if  0x4000.0000 iop  then
	 #? if   #uimm2 drop  then	   \ 32us 32s
      then
   else
      m.z.d rm??    0x4040.8000  iop   \ 64s
   then
   "]"  0x8420.0000
;

: (prf-vector-imm)   ( sz -- op )
   23 2 ^^op  ","? if  #uimm5  16 5 ^^op  then
   rn-adt m.z.d adt? if  0x4000.0000 iop  then
   "]"  0x8400.e000
;

: %prf   ( sz -- )
   <asm  sve-prfop,   pl,  "[" rn|rsp   rn-adt m.x adt? if
      ]? if
	 false (prf-scalar-imm)
      else
	 "," #? if
	    true (prf-scalar-imm)
	 else
	    rm  rm-adt m.x adt? if
	       (prf-scalar-scalar)
	    else
	       (prf-scalar-vector)
	    then
	 then
      then
   else
      (prf-vector-imm)
   then
   iop   asm>
;

: %tbl-z   m.z.bhsd <asm  rd, rd??
   "{" rn ","? if
      reg rn-adt " registers to be the same type " ?expecting   ( r )
      <rn> 1+ <> " registers to be sequential " ?expecting
      0x0520.2800
   else
      0x0520.3000
   then
   iop   "}" ","  rm  ?rd=rn=rm  set-zreg-sz   asm>
;
: %tbx-z   0x0520.2c00  m.z.bhsd %zzz  ;

: %tbl
   <asm  rd, rd??iop
   (getlist)  "," ( n count adt )  is rn-adt
   13 2 ^^op  ^rn  ","  rm
   ?rd=rm
   m.v.16b rn-mask and 0= ?invalid-regs
   rd-adt vreg>szq 30 ^op drop
   asm>
;

: %trn-p   ( trn2 -- )   0x0520.5000 swap if  0x0000.0400 or  then   m.p.bhsd %ppp  ;
: %trn-z   ( trn2 -- )
   m.z.bhsdq  <asm  d=n=m  rd??
   rd-adt m.z.q adt? if  ( trn2 )
      if  0x05a0.1c00  else  0x05a0.1800  then
   else  ( trn2 )
      if  0x0520.7400  else  0x0520.7000  then   set-zreg-sz
   then
   iop  asm>
;

: %trn   ( trn2 -- )
   <asm  reg is rd-adt  drop
   rd-adt m.z.bhsdq adt? if  %trn-z  exit  then  ( trn2 )
   rd-adt m.p.bhsd  adt? if  %trn-p  exit  then  ( trn2 )
   if  0x0E00.6800  else  0x0E00.2800  then   m.v#bhsd %v3same
;

: %mulh   ( u? regs -- )
   <asm  rd, rd??  reg ","  dup m.p/m adt? if   ( u? p p-adt )
      drop   10 3 ^^op  rn=d,  rn  ( u? )
      0x0412.0000  swap if  0x0001.0000 or  then  iop
   else   ( u? p p-adt )
      is rn-adt ^rn  rm
      0x0420.6800  swap if  0x0000.0400 or  then  iop
   then
   asm>
;
