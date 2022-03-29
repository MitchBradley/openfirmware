\ Scaled Matrix Extension

\ Matrix Outer Products

: %bfmop   ( op regs -- )
   <asm   rd, rd??iop   plm, plmu,   n=m
   rn-mask m.z.h <> ?invalid-regs
   asm>
;

: %fmop   ( op regs -- )
   <asm   rd, rd??iop   plm, plmu,   n=m
   rd-mask m.za.s = if
      rn-mask m.z.hs and 0= ?invalid-regs
      rn-mask m.z.h = if  0x0120.0000 iop  then   
   else
      rn-mask m.z.d <> ?invalid-regs
      0x0040.0000 iop
   then
   asm>
;

: %mop   ( op regs -- )
   <asm   rd, rd??iop   plm, plmu,   n=m
   rd-mask m.za.s = if
      rn-mask m.z.b <> ?invalid-regs
   else
      rn-mask m.z.h <> ?invalid-regs
      0x0040.0000 iop
   then
   asm>
;

\ Add vector to tile
: %addhv   ( op regs -- )
   <asm   rd, rd??iop   plm, plmu, rn
   rd-mask m.za.s = if
      rn-mask m.z.s <> ?invalid-regs
   else
      rn-mask m.z.d <> ?invalid-regs
      0x0040.0000 iop
   then
   asm>
;

: Wv   ( -- )
   reg adt-wreg <> ?invalid-regs
   dup 12 15 between 0= " W12 to W15 " ?expecting
   12 -
   13 2 ^^op
;

: ?expectza   ( okay? -- )   0= " ZAH or ZAV with .B .H .S .D or .Q " ?expecting  ;
: ?expect-tile   ( n sz -- )   mask andc " smaller tile number " ?expecting  ;
: ?expect-equal-imms  ( err? -- )   " immediates to be equal " ?expecting  ;
: ?set-vertical   ( mask -- )    m.zav.bhsdq and if  0x0000.8000 iop  then  ;

: %ls1za   ( op regs -- )
   <asm   swap dup iop   ( regs op )
   22 >> dup 4 and if  drop 4  else  3 and  then  >r   ( regs )
   "{"  reg dup is rd-adt   ( regs n adt )
   rot and 0= " ZAH or ZAV with .B .H .S .D or .Q " ?expecting
   ( n )  dup r@ ?expect-tile   \ tile# fits in sz bits
   ( n )  4 r@ - << iop         \ shift tile# into place
   rd-mask m.zav.bhsdq and if  0x0000.8000 iop  then
   "[" Wv ","? if  4 r@ - #uimm iop  then "]" "}" ","
   plz,
   [xn|sp  ","? if
      xm
      r@ if
	 ","  "lsl"
	 #uimm3 r@ <> " shift to match data size " ?expecting
      then
   then  "]"
   r> drop
   asm>
;

: lsza   ( op regs -- )
   rd  rd??iop
   "[" Wv ","? if  #uimm4 iop  then "]" ","
   [xn|sp  ","? if
      #uimm4  opcode 4 mask and <> ?expect-equal-imms
      "," " mul vl" $match?  0= " mul vl" ?expecting
   then  "]"
;
: %lsza   ( op regs -- )   <asm   lsza   asm>  ;
\ ldrza and strza need to merge with base ldr and str
: ldrza   0xe100.0000 m.za %lsza  ;
: strza   0xe120.0000 m.za %lsza  ;


: mask>sz   ( mask -- sz )
   case
      m.z.b of      0   endof
      m.z.h of      1   endof
      m.z.s of      2   endof
      m.z.d of      3   endof
      m.z.q of      4   endof
      m.zah.b of   0   endof
      m.zah.h of   1   endof
      m.zah.s of   2   endof
      m.zah.d of   3   endof
      m.zah.q of   4   endof
      m.zav.b of   0   endof
      m.zav.h of   1   endof
      m.zav.s of   2   endof
      m.zav.d of   3   endof
      m.zav.q of   4   endof
   endcase
;
: setsz   ( sz -- )
   dup 4 and if  0x1.0000 or  then
   3 and 22 2 ^^op
;

: mov-a>v   ( n -- )
   ^rd  0x0002.0000 iop  "," plm,
   rd-mask mask>sz  >r
   r@ setsz
   reg is rn-adt
   rn-mask m.zahv.bhsdq and ?expectza
   ( n )  dup r@ ?expect-tile
   r@ 5 + << iop
   rn-mask ?set-vertical
   "[" Wv ","? if  4 r@ - #uimm 5 << iop  then "]" 
   r> drop
;
: mov-v>a   ( n -- )
   rd-mask mask>sz  >r         ( n )
   dup r@ ?expect-tile         ( n )
   r@ setsz
   r@ << iop
   rd-mask ?set-vertical
   "[" Wv ","? if  4 r@ - #uimm iop  then "]" ","
   plm, rn
   rn-mask m.z.bhsdq and ?expectza
   r> drop
;
: %mova   ( op -- )
   <asm  iop reg is rd-adt    ( n )
   rd-mask m.z.bhsdq and if
      mov-a>v
   else
      rd-mask m.zahv.bhsdq and 0= " z, zah, or zav with .b thrugh .q " ?expecting
      mov-v>a
   then
   asm>
;

: Wm   ( -- )
   reg adt-wreg <> ?invalid-regs
   dup 12 15 between 0= " W12 to W15 " ?expecting
   12 -
   16 2 ^^op
;

