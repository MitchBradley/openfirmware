\ simd assembler

decimal

\ support adding SIMD instructions to the assembler.
\ this file defines words that are used to define instructions

\ Set the size fields Q and Z or SZ
\ behavior is different for scalar, vector, floating scalar, floating vector
\ XXX look for a way to merge these into fewer words

: set-q   ( -- )   \ set the q field
   \ used by BIT, BIF, EXT, TBL, TBX
   rd-adt case
      adt-dreg.8b  of              endof
      adt-qreg.16b of   1 30 ^op   endof
      " 8B or 16B " expecting
   endcase
;

: vreg>szq   ( adt -- sz q )
   case
      adt-dreg.8b  of   0 0   endof
      adt-qreg.16b of   0 1   endof
      adt-dreg.4h  of   1 0   endof
      adt-qreg.8h  of   1 1   endof
      adt-dreg.2s  of   2 0   endof
      adt-qreg.4s  of   2 1   endof
      adt-dreg.1d  of   3 0   endof
      adt-qreg.2d  of   3 1   endof
      " vector register " expecting
   endcase   ( sz q )
;
: set-szq   ( -- )   \ set the sz and q fields
   rn-adt vreg>szq  ( sz q )
   30    ^op
   22 2 ^^op
;
: setd-szq   ( -- )   \ set the sz and q fields
   rd-adt vreg>szq  ( sz q )
   30    ^op
   22 2 ^^op
;
: set-zq   ( -- )   \ set the z and q fields
   rn-adt vreg>szq  ( sz q )
   30    ^op
   1 and 22 ^op
;
: vset-zq?   ( -- size )   \ set the z and q fields
   rn-adt vreg>szq  ( sz q )
   30    ^op
   1 and dup 22 ^op
;

: sreg>sz   ( adt -- sz )
   case
      adt-breg of   0   endof
      adt-hreg of   1   endof
      adt-sreg of   2   endof
      adt-dreg of   3   endof
      " scalar register " expecting
   endcase
;
: set-sz   ( rx -- )   \ set the sz field based on selected registers
   sreg>sz  ( sz )
   22 2 ^^op
;
: set-z   ( rx -- )   \ set the sz field based on selected registers
   sreg>sz  ( sz )
   1 and 22 ^op
;
: set-z?   ( rx -- size? )   \ set the sz field based on selected registers
   sreg>sz  ( sz )
   1 and dup 22 ^op
;
: setd-sz   ( -- )  rd-adt set-sz  ;
: setd-z    ( -- )  rd-adt set-z   ;
: setn-sz   ( -- )  rn-adt set-sz  ;
: setn-z    ( -- )  rn-adt set-z   ;

: setd-szq   ( -- )   \ set the sz and q fields
   rd-adt vreg>szq  ( sz q )
   30    ^op
   22 2 ^^op
;
: setd-zq   ( -- )   \ set the z and q fields
   rd-adt vreg>szq  ( sz q )
   30    ^op
   1 and 22 ^op
;


\ define common behaviors
\ these may be used directly in instructions-try.fth
\ some cases are not currently used

: s2same   ( op regs -- )   2same  setd-sz  ;
: s3same   ( op regs -- )   3same  setd-sz  ;

: v2same   ( op regs -- )   2same  set-szq  ;
: v3same   ( op regs -- )   3same  set-szq  ;
: v2>3same   ( op regs -- )   2same <rn> ^rm  set-szq  ;

: fs2same   ( op regs -- )   2same  setd-z  ;
: fs3same   ( op regs -- )   3same  setd-z  ;
: fs4same   ( op regs -- )   4same  setd-z  ;

: fv2same   ( op regs -- )   2same  set-zq  ;
: fv3same   ( op regs -- )   3same  set-zq  ;

\ : s2long   ( op regs -- )   2long  setn-sz  ;
: s3long   ( op regs -- )   3long  setn-sz  ;

: v2long   ( op regs -- )   2long  set-szq  ;
: v3long   ( op regs -- )   3long  set-szq  ;

: pmull-args? ( op regs -- )
        rd, n=m  rd?? 
        rd-mask m.q  = rn-mask m.v.1d = and
        rd-mask m.v.8h = rn-mask m.v.8b = and
         or  0=
        " 8H,8B or 1q,1d " ?expecting 
        ;

: pmull2-args? ( op regs -- )
        rd, n=m  rd?? 
        rd-mask m.q  = rn-mask m.v.2d = and
        rd-mask m.v.8h = rn-mask m.v.16b = and
         or  0=
        " 8H,16B or 1q,2d " ?expecting 
        ;

: umull-args? ( op regs -- )
        rd, n=m  rd??
        rd-mask m.v.2d  = rn-mask m.v.2s = and
        rd-mask m.v.4s  = rn-mask m.v.4h = and or
        rd-mask m.v.8h  = rn-mask m.v.8b = and or
        0=
        " 8H,8B or 4s,4h or 2d,2s " ?expecting
        set-szq iop
        ;

: umull2-args? ( op regs -- )
        rd, n=m  rd??
        rd-mask m.v.2d  = rn-mask m.v.4s = and
        rd-mask m.v.4s  = rn-mask m.v.8h = and or
        rd-mask m.v.8h  = rn-mask m.v.16b = and or
        0=
        " 8H,16B or 4s,8h or 2d,4s " ?expecting
        set-szq iop
        ;

: umlal-args? ( op regs -- )
        rd, n=m  rd??
        rd-mask m.v.4s  = rn-mask m.v.4h = and
        rd-mask m.v.2d  = rn-mask m.v.2s = and
        or 0=
        " 4s,4h or 2d,2s " ?expecting
        set-szq iop
        ;

: umlal2-args? ( op regs -- )
        rd, n=m  rd??
        rd-mask m.v.4s  = rn-mask m.v.8h = and 
        rd-mask m.v.2d  = rn-mask m.v.4s = and 
        or 0=
        " 4s,4h or 2d,2s " ?expecting
        set-szq iop
        ;

: fs2long   ( op regs -- )   2long  setd-z  ;
\ : fs3long   ( op regs -- )   3long  setn-z  ;

\ : fv2long   ( op regs -- )   2long  set-zq  ;
: fv3long   ( op regs -- )   3long  set-zq  ;

: s2narrow   ( op regs -- )   2narrow  setd-sz  ;
\ : s3narrow   ( op regs -- )   3narrow  setd-sz  ;

: v2narrow   ( op regs -- )   2narrow  setd-szq  ;
: v3narrow   ( op regs -- )   3narrow  setd-szq  ;

: fs2narrow   ( op regs -- )   2narrow  setn-z  ;
\ : fs3narrow   ( op regs -- )   3narrow  setd-z  ;

: fv2narrow   ( op regs -- )   2narrow  setd-zq  ;
\ : fv3narrow   ( op regs -- )   3narrow  setd-zq  ;

: v3wide    ( op regs -- )   3wide  setd-szq  ;


\ these are used to define simple instructions

: %s2same   ( op regs -- )   <asm  s2same  asm>  ;
: %s3same   ( op regs -- )   <asm  s3same  asm>  ;

: %v2same   ( op regs -- )   <asm  v2same  asm>  ;
: %v3same   ( op regs -- )   <asm  v3same  asm>  ;

: %fs2same   ( op regs -- )   <asm  fs2same  asm>  ;
: %fs3same   ( op regs -- )   <asm  fs3same  asm>  ;
: %fs4same   ( op regs -- )   <asm  fs4same  asm>  ;

: %fv2same   ( op regs -- )   <asm  fv2same  asm>  ;
: %fv3same   ( op regs -- )   <asm  fv3same  asm>  ;

\ : %s2long   ( op regs -- )   <asm  s2long  asm>  ;
\ : %s3long   ( op regs -- )   <asm  s3long  asm>  ;

: %v2long   ( op regs -- )   <asm  v2long  asm>  ;
: %v3long   ( op regs -- )   <asm  v3long  asm>  ;

: %pmull    ( op regs -- ) <asm pmull-args? set-szq iop asm> ;
: %pmull2   ( op regs -- ) <asm pmull2-args? set-szq iop asm> ;

: %umull    ( op regs -- ) <asm umull-args? asm> ;
: %umull2   ( op regs -- ) <asm umull2-args? asm> ;

: %umlal    ( op regs -- ) <asm umlal-args? asm> ;
: %umlal2   ( op regs -- ) <asm umlal2-args? asm> ;

: %fs2long   ( op regs -- )   <asm  fs2long  asm>  ;
\ : %fs3long   ( op regs -- )   <asm  fs3long  asm>  ;

\ : %fv2long   ( op regs -- )   <asm  fv2long  asm>  ;
\ : %fv3long   ( op regs -- )   <asm  fv3long  asm>  ;

\ : %s2narrow   ( op regs -- )   <asm  s2narrow  asm>  ;
\ : %s3narrow   ( op regs -- )   <asm  s3narrow  asm>  ;

: %v2narrow   ( op regs -- )   <asm  v2narrow  asm>  ;
: %v3narrow   ( op regs -- )   <asm  v3narrow  asm>  ;

: %fs2narrow   ( op regs -- )   <asm  fs2narrow  asm>  ;
\ : %fs3narrow   ( op regs -- )   <asm  fs3narrow  asm>  ;

\ : %fv2narrow   ( op regs -- )   <asm  fv2narrow  asm>  ;
\ : %fv3narrow   ( op regs -- )   <asm  fv3narrow  asm>  ;

: %v3wide   ( op regs -- )   <asm  v3wide  asm>  ;



\ some immediates

: vsz?   ( -- sz )   rn-adt vreg>szq   ( sz q )  30 ^op  ;
: ssz?   ( -- sz )   rn-adt sreg>sz  ;
: set-shift   ( sz -- )   3 + 1 swap << dup dup #uimm - or  16 7 ^^op  ;

: (s2#)     ( op regs -- )   rd??  iop  "," ssz? set-shift  ;
: (v2#)     ( op regs -- )   rd??  iop  "," vsz? set-shift  ;
: s2#same   ( op regs -- )   d=n  (s2#)  ;
: v2#same   ( op regs -- )   d=n  (v2#)  ;

: s2#long    ( op regs -- )   d>n  (s2#)  ;
: v2#long    ( op regs -- )   d>n  (v2#)  ;

: s2#narrow   ( op regs -- )   d<n  (s2#)  ;
: v2#narrow   ( op regs -- )   d<n  (v2#)  ;

\ these are used to define simple immediate instructions

: %s2#same   ( op regs -- )   <asm  s2#same  asm>  ;
: %v2#same   ( op regs -- )   <asm  v2#same  asm>  ;

: %s2#long   ( op regs -- )   <asm  s2#long  asm>  ;
: %v2#long   ( op regs -- )   <asm  v2#long  asm>  ;

: %s2#narrow  ( op regs -- )   <asm  s2#narrow  asm>  ;
: %v2#narrow  ( op regs -- )   <asm  v2#narrow  asm>  ;


\ handle cases where a mnemonic has different behavior depending on the register types

\ gv : general purpose or vector
: %2same-gv    ( v-op v-mask g-op g-mask -- )   \ gv2same
   <asm  d=n   rd? if            ( v-op v-mask g-op )
      nip nip
      set-sf?   \ setting size is special for every type... need to fix
   else              ( v-op v-mask g-op )
      drop  rd? 0=  " Rd is Xn or vector " ?expecting   ( v-op )
      set-szq
   then   iop   asm>
;
\ nv : scalar or vector
: (2same-nv)    ( v2-op v2-mask n2-op n2-mask -- )
   d=n rd? if                ( v-op v-mask n-op )
      nip nip  rn-adt set-sz
   else                  ( v-op v-mask n-op )
      drop  rd? 0=  " Rd is scalar or vector " ?expecting
      set-szq
   then
   iop
;
: ",#0"   ( -- )    "," "#" "0" ;
: %2same-nv    ( v-op v-mask n-op n-mask -- )    <asm  (2same-nv)        asm>  ;
: %2same-nvz   ( v-op v-mask n-op n-mask -- )    <asm  (2same-nv) ",#0"  asm>  ;
: %3same-nv    ( v-op v-mask n-op n-mask -- )
   <asm  d=n=m
   rd? if                ( v-op v-mask n-op )
      nip nip  rn-adt set-sz
   else                  ( v-op v-mask n-op )
      drop  rd? 0=  " Rd is scalar or vector " ?expecting
      set-szq
   then   iop  asm>
;
\ fnv : scalar or vector fp
: (f2same-nv)   ( v-op v-mask n-op n-mask -- )
   d=n  rd? if                ( v-op v-mask n-op )
      nip nip  rn-adt set-z
   else                  ( v-op v-mask n-op )
      drop  rd? 0=  " Rd is float scalar or vector " ?expecting
      set-zq
   then   iop
;
: %f2same-nv   ( v-op d-op -- )    <asm   (f2same-nv)        asm>  ;
: %f2same-nvz  ( v-op d-op -- )    <asm   (f2same-nv) ",#0"  asm>  ;

: %f3same-nv   ( v-op v-mask n-op n-mask -- )   \ fsv3same
   <asm  d=n=m
   rd? if                ( v-op v-mask n-op )
      nip nip  rn-adt set-z
   else                  ( v-op v-mask n-op )
      drop  rd? 0=  " Rd is float scalar or vector " ?expecting
      set-zq
   then   iop  asm>
;
\ fnp : scalar or pair fp
: %f3same-np   ( v-op v-mask n-op n-mask -- )
   <asm  rd,   rd? if                ( v-op v-mask n-op )
      nip nip   rn ?rd=rn
      rd-adt set-sz
   else                  ( v-op v-mask n-op )
      drop  rd? 0=  " Rd is float scalar or vector " ?expecting
      rn, rm ?rd=rn=rm
      set-zq
   then   iop  asm>
;

: %addp         ( v-op v-mask n-op n-mask -- )
   <asm  rd, rd? if                ( v-op v-mask n-op )
      nip nip rn rd-mask m.d = rn-mask m.v.2d = and 0=
        " d,2d" ?expecting

      rd-adt set-sz
   else                  ( v-op v-mask n-op )
      drop  rd? 0=  " Rd is float scalar or vector " ?expecting
      rn, rm ?rd=rn=rm
      set-zq
   then   iop  asm>
;

\ some instructions act "across lanes"
\ eg  saddlv can give  h = sum (8b)
: xsame?   ( -- ? )   \ compares allowed vector rv to scalar rs
   rd-mask rn-mask 
   dup m.v#b adt? if  drop m.b = exit   then
   dup m.v#h adt? if  drop m.h = exit   then
   dup m.v#s adt? if  drop m.s = exit   then
   dup m.v#d adt? if  drop m.d = exit   then
   2drop false
;
: xlong?   ( -- ? )    \ compares allowed value of rx to rd
   rd-mask rn-mask 
   dup m.v#b adt? if  drop m.h = exit   then
   dup m.v#h adt? if  drop m.s = exit   then
   dup m.v#s adt? if  drop m.d = exit   then
   2drop false
;
: %across  ( op regs -- )
   <asm  rd, rn  rd??iop   set-szq
   xsame? 0= ?invalid-regs   ( op )
   asm>
;
: %long-across  ( op regs -- )
   <asm  rd, rn  rd??iop   set-szq
   xlong? 0= ?invalid-regs
   asm>
;

: simd-nimm   ( op regs -- )   \ immediate
   rd,  swap iop   ( regs )
   rd-mask adt? 0= ?invalid-regs   ( rdmask )
   8 #uimm  13 8 ^^op
   rd-adt set-z
;

: #modimm8   ( -- )
   8 #uimm           ( imm8 )   \ get an 8-bit immediate value
   dup 5 >> 7 and               \ take the top 3 bits
   16 3 ^^op                    \ shift them up 16 into the opcode
   5 mask and 5 5 ^^op          \ shift the bottom 5 up 5 ditto
;
: "lsl"   ( -- )   " lsl" ?$match  ;
: modimm   ( op regs -- )   \ modified immediate
   rd,  swap iop
   rd-mask adt? 0= ?invalid-regs
   rd-adt vreg>szq 30 ^op drop
   rd-adt adt-qreg.2d = if  1 29 ^op  then
   #modimm8
   ","? if
      "lsl" 5 #uimm   ( imm )
      8 /mod swap ?invalid-regs    ( imm/8 )
      13 2 ^^op
   then
;
: %modimm    ( op regs -- )   <asm  modimm  asm>  ; 
: %bv3same   ( op regs -- )   <asm  3same set-q  asm>  ;

\ XXX used in apple/lib/asm.fth
: ^simd-v2same    ( op regs -- )   2same  ;

\ XXX used in soctools/asm_macros.fth
: simd-v3same    ( op regs -- )   3same  set-szq  ;


\ arm v8.3 complex numbers
: square-angle   ( -- n )
   "#" unimm case
      0   of   0  endof
      90  of   1  endof
      180 of   2  endof
      270 of   3  endof
      true " a multiple of 90" ?expecting
   endcase
;
: sq-angle   ( -- n )
   "#" unimm case
      90  of   0  endof
      270 of   1  endof
      true " 90 or 270" ?expecting
   endcase
;
: cv3same   ( op regs -- )
   3same  set-szq ","  square-angle 11 2 ^^op
;
: c3same   ( op regs -- )
   3same  set-szq ","  sq-angle 12 ^op
;

: gnregs?   xwd? dsn? and  ;    
: ^simd-gn   ( op -- )
   rd, rn   gnregs? 0= ?invalid-regs
   xd? if  set-sf  then   \ X -> sf
   dn? if  0x00400000 or  then  iop  \ D -> bit 22
;
: ngregs?   xwn? dsd? and  ;    
: ^simd-ng   ( op -- )
   rd, rn   ngregs? 0= ?invalid-regs
   xn? if  set-sf  then   \ X -> sf
   dd? if  0x00400000 or  then  iop  \ D -> bit 22
;
: ^simd-ngi   ( op -- )
   rd, rn, #uimm6  ngregs? 0= ?invalid-regs
   wn? if  ( imm ) 32 > " no more than 32 " ?expecting then
   64 swap - 10 6 ^^op
   xn? if  set-sf  then   \ X -> sf
   dd? if  0x00400000 or  then  iop  \ D -> bit 22
;

: %aes   ( op regs -- )   <asm  d=n rd?? iop  asm>  ;
: %2sha  ( op regs -- )   <asm  d=n rd?? iop  asm>  ;
: %3sha  ( op regs -- )
   <asm
   rd, rn, rm
   ( regs )  rn-mask adt? 0= ?invalid-regs
   ( op )  iop
   rm-adt adt-qreg.4s <> " Rm to be 4S " ?expecting
   rn-adt adt-qreg.4s = if  \ rd must also be 4s
      ?rd=rn
   else                     \ rd must be q
      rd-adt adt-qreg <> ?invalid-regs
   then
   asm>
;

\ ARMv8.4
: %3sha84  ( op regs -- )
   <asm
   rd, rn, rm
   ( regs )  rn-mask adt? 0= ?invalid-regs
   ?rd=rn
   ( op )  iop
   rm-adt adt-qreg.2d <> " Rm to be 2D " ?expecting
   asm>
;
: %3isha84  ( op regs -- )   <asm# 3same  ","  #uimm6 ^imms6  asm>  ;
: %4sha84   ( op regs -- )   <asm  4same  asm>  ;

: simd-dot  ( op regs -- )
   rd, rn, rm
   ( regs )  rn-mask adt? 0= ?invalid-regs
   ?rn=rm
   ( op )  iop
   rn-adt adt-dreg.8b = if
      adt-dreg.2s
   else
      adt-qreg.4s    1 30 ^op
   then    rd-adt <> ?invalid-regs
;

: %fcond-sel   ( op regs -- )
   <asm  d=n=m,  rd??iop   rn-adt set-z
   cond 12 4 ^^op   asm>
;
: fcompare   ( op regs -- )   n=m  rn??iop   rn-adt set-z  ;
: %fcond-cmp   ( op regs -- )
   <asm#   fcompare ","  #uimm4, iop  cond 12 4 ^^op   asm>
;
: fcompare0   ( op regs -- )   rn, " #0.0" ?$match  rn??iop   rn-adt set-z  ;

: %mmla    ( op regs -- )   <asm  rd, n=m  rd??iop   m.v.16b rn??  asm>  ;

