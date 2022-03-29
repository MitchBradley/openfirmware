\ support for SIMD elements

decimal

\ Element example:  v0.b[7]
\ some instructions can use just one element of a vector
\ eg   fcmla  v0.2d, v1.2d, v2.d[index], #rotate

\ convert an index register type to a one-bit mask
: vadt>mask   ( vmask -- mask )
   case
      adt-vreg.b   of   m.b    endof
      adt-vreg.h   of   m.h    endof
      adt-vreg.s   of   m.s    endof
      adt-vreg.d   of   m.d    endof
      " index register" expecting
   endcase
;

\ there are four cases for addressing by element: vector or scalar, same or long
: vrm==rn?   ( -- valid? )   rm-adt vadt>mask rn-adt adt>mask =  ;

\ the index is encoded into the H L M bits
: set-hlm   ( -- )
   3 get-index
   dup 1 and  ( M ) 20 ^op  2/
   dup 1 and  ( L ) 21 ^op  2/
   dup 1 and  ( H ) 11 ^op  drop
;
: set-hl   ( -- )
   2 get-index
   dup 1 and  ( L ) 21 ^op  2/
   dup 1 and  ( H ) 11 ^op  drop
;
: set-h   ( -- )   1 get-index   ( H ) 11 ^op  ;
: set-index   ( -- )
   opcode 22 >> 3 and  ( sz )
   case
      1 of   set-hlm   endof
      2 of   set-hl    endof
      ( default )   true " invalid index " ?error
   endcase
;

: velong?   ( -- ? )
   rm-mask rd-mask case
      m.v.8h of  m.v.b =  endof
      m.v.4s of  m.v.h =  endof
      m.v.2d of  m.v.s =  endof
      false swap
   endcase
;
: vesame?   ( re rv -- flag )   \ compares allowed vector rv to scalar re
   case
      m.v.16b of  m.v.b =  endof
      m.v.8b of  m.v.b =  endof
      m.v.8h of  m.v.h =  endof
      m.v.4h of  m.v.h =  endof
      m.v.4s of  m.v.s =  endof
      m.v.2s of  m.v.s =  endof
      m.v.2d of  m.v.d =  endof
      m.v.1d of  m.v.d =  endof
      false swap
   endcase
;
: (velem)   ( op regs -- ) 
   rd, rn, rm   rd??iop   set-szq  set-index
;
: velem-long   ( op regs -- )   \ vector indexed element
   (velem)  ?rd>rn   velong?  0= ?invalid-regs
;
: velem-same   ( op regs -- )   \ vector indexed element
   (velem)  ?rd=rn  rm-mask rn-mask vesame?  0= ?invalid-regs
;

: (fvelem)   ( op regs -- ) 
   rd, rn, rm   rd??iop   
;

: fvelem-long   ( op regs -- )   \ floating vector indexed element
   rd, rn, rm   rd??iop
   ?rd>rn   velong? 0= ?invalid-regs
   vset-zq? if  set-h  else  set-hl  then
;
: fvelem-same   ( op regs -- )   \ floating vector indexed element
   rd, rn, rm  rd??iop
   ?rd=rn   rm-mask rn-mask vesame? 0= ?invalid-regs
   vset-zq? if  set-h  else  set-hl  then
;

: selong?   ( -- ? )
   rm-mask rd-mask case
      m.h  of  m.v.b =  endof
      m.s  of  m.v.h =  endof
      m.d  of  m.v.s =  endof
      false swap
   endcase
;
: sesame?   ( -- ? )
   rm-mask rd-mask case
      m.b  of  m.v.b =  endof
      m.h  of  m.v.h =  endof
      m.s  of  m.v.s =  endof
      m.d  of  m.v.d =  endof
      false swap
   endcase
;
: (selem)   ( op regs -- ) 
   rd, rn, rm   rd??iop   rn-adt set-sz  set-index
;
: selem-long   ( op regs -- )
   (selem)  selong?  vrm==rn? and 0= ?invalid-regs
;

: (fselem)   ( op regs -- ) 
   rd, rn, rm   rd??iop
   rn-adt set-z? if  set-h  else  set-hl  then
;
: fselem-long   ( op regs -- )   \ scalar indexed element
   (fselem)  ?rd>rn   selong? 0= ?invalid-regs
;
: fselem-same   ( op regs -- )   \ scalar indexed element
   (fselem)   ?rd=rn   sesame? 0= ?invalid-regs
;
: celem-same   ( op regs -- )   \ complex vector indexed element
   rd, rn, rm   rd??iop
   ?rd=rn   rm-mask rn-mask vesame? 0= ?invalid-regs
   rn-adt  vreg>szq  ( sz q )
   30    ^op
   dup 22 2 ^^op  1 and
   if  set-h  else  set-hl  then
   ","  square-angle 13 2 ^^op
;


\ some instructions encode the index this way
: (pack-index)   ( mask -- shift #bits )
   case  \   sh   #bits
      m.v.b  of   0  4   endof
      m.v.h  of   1  3   endof
      m.v.s  of   2  2   endof
      m.v.d  of   3  1   endof
      true " bad mode " ?error
   endcase
;

: (pack-size)   ( mask -- shift #bits )
   case  \   sh   #bits
      m.v.16b of  0  4   endof
      m.v.8b  of  0  4   endof
      m.v.8h  of  1  3   endof
      m.v.4h  of  1  3   endof
      m.v.4s  of  2  2   endof
      m.v.2s  of  2  2   endof
      m.v.2d  of  3  1   endof
      true " bad mode " ?error
   endcase
; 

: pack-index   ( mask -- bits )   (pack-index)  get-index 2* 1+ swap <<  ;
: pack-size    ( mask -- bits )   (pack-size)  drop         1  swap <<  ;
: ^simd-umov   ( op -- )
   rd, rn  iop
   rn-mask                                        ( rnmask )
   dup m.v.bhs adt? if                            ( rnmask )
      rd-adt adt-wreg <> ?invalid-regs
   else                                           ( rnmask )
      dup m.v.d adt? 0= ?invalid-regs
      rd-adt adt-xreg <> ?invalid-regs
      1 30 ^op
   then                                         ( rnmask )
   pack-index  16 5 ^^op
;
: ^simd-dup-vg   ( op regs -- )    \ vector from gpr
   rd, rn  rd??iop
   rn-adt adt-wreg = if
      rd-mask m.v#bhs adt? 0= ?invalid-regs
      rd-mask pack-size  16 5 ^^op
   else
      rn-adt adt-xreg <> ?invalid-regs
      rd-mask m.v.2d adt? 0= ?invalid-regs
      0x80000 iop
   then
   rd-adt vreg>szq nip 30 ^op
;

: ^simd-dup-ve   ( op regs -- )    \ vector from element
   d=n  rd??iop
   rn-mask rd-mask vesame? 0= ?invalid-regs
   rd-mask pack-index  16 5 ^^op
   rd-adt vreg>szq nip 30 ^op
;
: ^simd-dup-se   ( op regs -- )    \ scalar from element
   d=n  rd??iop
   rd-mask pack-index  16 5 ^^op
;

\ INS  v0.b[7], w1
: rd[],   ( -- )   rd   rd-mask pack-index  16 5 ^^op   ","   ;
: ^simd-ins-veg   ( op -- )    \ vector element from gpr
   iop  rd[], rn

   rd-mask                                      ( rdmask )
   rn-adt adt-wreg = if                         ( rdmask )
      m.v.bhs adt? 0= ?invalid-regs
   else                                         ( rdmask )
      rn-adt adt-xreg <> ?invalid-regs
      m.v.d adt? 0= ?invalid-regs
   then
;

\ INS  v0.b[7], v1.b[5]
: rn[]    ( -- )
   rn   rn-mask (pack-index) get-index  swap <<
   11 4 ^^op
;
: ^simd-ins-veve   ( op -- )    \ vector element from vector element
   iop  rd[], rn[]
   rd-mask rn-mask <> ?invalid-regs
;

: simd-dotelem   ( op regs -- )   \ vector indexed element
   rd, rn, rm
   rn-mask and 0= ?invalid-regs
   rm-mask m.v.b adt? 0= ?invalid-regs
   iop
   setd-szq
   set-index
;

: fpr-gpr-mov   ( --  )
   rd 
   rd-adt adt-vreg.d = if
      2 get-index 1 = if  "," rn  0x9EAF.0000 iop  exit  then  \ X to vector element
   then
   "," rn

\ Wreg destination
\ src: Sreg Hreg
\ FMOV <Wd>, <Sn>

\ ---Begin rd=wreg
   rd-adt adt-wreg =                                           \ if rD = wreg = fp->32
   IF                                               
\ FMOV <Wd>, <Sn>
        rn-adt adt-sreg = IF  0x1E26.0000 iop exit THEN            \ sgl to 32bit

\ FMOV <Wd>, <Hn>
        rn-adt adt-hreg =   \ H to 32bit
        IF  
            0x1ee60000 iop
            exit
        THEN       
        " Sreg/Hreg register" expecting
   THEN 
\ ---------end rd=wreg
 

\ ---Begin rd=sreg
   rd-adt adt-sreg =                                           \ if rD = wreg = fp->32
   IF
\ FMOV <Sd>, <Wn>
      rn-adt adt-wreg = IF  0x1E27.0000 iop  exit THEN        \ 32bit to sgl
      " Wreg register" expecting
   THEN
\ ---------end rd=Sreg

\ ---Begin rd=Dreg
   rd-adt adt-dreg =                                           \ if rD = wreg = fp->32
   IF
\ FMOV <Dd>, <Xn>
      rn-adt adt-xreg = IF  0x9E67.0000 iop  exit THEN        \ 64bit to dbl
      " Dreg register" expecting
   THEN


\ ---Begin rd=Xreg
   rd-adt adt-xreg =                                           \ if rD = wreg = fp->32
   IF
      rn-adt adt-dreg = IF  0x9E66.0000 iop  exit THEN        \ dbl to 64bit
      rn-adt adt-vreg.d = 
      if
	     2 get-index 1 = if  0x9EAE.0000 iop  exit  then       \ vector element to X
      then

\ FMOV <Xd>, <Hn>
        rn-adt adt-hreg =   \ H to 32bit
        IF  
            0x9ee60000 iop    exit
        THEN       
	" Dreg or V.d[1] register" expecting
   THEN


\ FMOV <Hd>, <Xn>
   rd-adt adt-hreg =                                           \ if rD = wreg = fp->32
   IF
        rn-adt adt-xreg =   \ 64 to h
        IF  
            0x9ee70000 iop    exit
        THEN

\ FMOV <Hd>, <Wn>
        rn-adt adt-wreg =   \ 64 to h
        IF  
            0x1ee70000 iop   exit
        THEN
        " XREG or WREG" expecting
    THEN
    true ?invalid-regs
;

: %usdot   ( op regs -- )
   <asm  over >r   ( sudot has op = 0 )
   rd, rd??iop  rn,
   rd-mask m.v.4s = if
      0x4000.0000 iop  \ set Q
      m.v.16b
   else
      m.v.8b
   then  rn??
   rm  rm-mask m.v.4b <> if
      r@ 0= " index with SUDOT" ?expecting
      ?rn=rm  0x0e80.9c00 iop
   else   \ indexed
      set-hl  0x0f00.f000 iop
   then
   r> drop
   asm>
;
