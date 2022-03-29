\ Assembler Instruction Mnemonics
\ ARMv8.0
\ this file defines the more complex instructions, about 135 of them

: adds        3 0 try: 0 1  add-sub ;

: cmeq       ( -- )
   4 0 try: case
      0  of  0x2E20.8C00 m.v#bhsd  v3same  endof
      1  of  0x7E20.8C00 m.d       s3same  endof
      2  of  0x0E20.8C00 m.v#bhsd  v2same  endof  \ XXX handle ,#0
      3  of  0x5E20.8C00 m.d       s2same  endof  \ XXX handle ,#0
   endcase
;
: cmge       ( -- )
   4 0 try: case
      0  of  0x0E20.3C00 m.v#bhsd  v3same  endof
      1  of  0x5E20.3C00 m.d       s3same  endof
      2  of  0x2E20.8800 m.v#bhsd  v2same  endof
      3  of  0x7E20.8800 m.d       s2same  endof
   endcase
;
: cmgt       ( -- )
   4 0 try: case
      0  of  0x0E20.3400 m.v#bhsd  v3same  endof
      1  of  0x5E20.3400 m.d       s3same  endof
      2  of  0x0E20.8800 m.v#bhsd  v2same  endof
      3  of  0x5E20.8800 m.d       s2same  endof
   endcase
;
: cmn         3 0 try: 0    1  parse-cmp ;
: cmp         3 0 try: 1    1  parse-cmp ;

\ dup is not a safe name for us to use here
: vdup   ( -- )   \ alias this to dup much later
   3 0 try: case
      0  of  0x0E00.0C00  m.v#bhsd  ^simd-dup-vg  endof
      1  of  0x0E00.0400  m.v#bhsd  ^simd-dup-ve  endof
      2  of  0x5E00.0400  m.bhsd    ^simd-dup-se  endof
   endcase
;

: fcmp    ( -- )
   2 0 try: case
      0  of  0x1E20.2000 m.sd  fcompare   endof
      1  of  0x1E20.2008 m.sd  fcompare0  endof
   endcase
;
: fcmpe    ( -- )
   2 0 try: case
      0  of  0x1E20.2010 m.sd  fcompare   endof
      1  of  0x1E20.2018 m.sd  fcompare0  endof
   endcase
;

: fcvtas     ( -- )
   3 0 try: case
      0  of  0x1e24.0000         ^simd-gn  endof
      1  of  0x0E21.C800 m.v#sd  fv2same   endof
      2  of  0x5E21.C800 m.sd    fs2same   endof
   endcase
;
: fcvtau     ( -- )
   3 0 try: case
      0  of  0x1e25.0000         ^simd-gn  endof
      1  of  0x2E21.C800 m.v#sd  fv2same   endof
      2  of  0x7E21.C800 m.sd    fs2same   endof
   endcase
;
: fcvtms     ( -- )
   3 0 try: case
      0  of  0x1e30.0000         ^simd-gn  endof
      1  of  0x0E21.B800 m.v#sd  fv2same   endof
      2  of  0x5E21.B800 m.sd    fs2same   endof
   endcase
;
: fcvtmu     ( -- )
   3 0 try: case
      0  of  0x1e31.0000         ^simd-gn  endof
      1  of  0x2E21.B800 m.v#sd  fv2same   endof
      2  of  0x7E21.B800 m.sd    fs2same   endof
   endcase
;
: fcvtns     ( -- )
   3 0 try: case
      0  of  0x1e20.0000         ^simd-gn  endof
      1  of  0x0E21.A800 m.v#sd  fv2same   endof
      2  of  0x5E21.A800 m.sd    fs2same   endof
   endcase
;
: fcvtnu     ( -- )
   3 0 try: case
      0  of  0x1e21.0000         ^simd-gn  endof
      1  of  0x2E21.A800 m.v#sd  fv2same   endof
      2  of  0x7E21.A800 m.sd    fs2same   endof
   endcase
;
: fcvtps     ( -- )
   3 0 try: case
      0  of  0x1e28.0000         ^simd-gn  endof
      1  of  0x0EA1.A800 m.v#sd  fv2same   endof
      2  of  0x5EA1.A800 m.sd    fs2same   endof
   endcase
;
: fcvtpu     ( -- )
   3 0 try: case
      0  of  0x1e29.0000         ^simd-gn  endof
      1  of  0x2EA1.A800 m.v#sd  fv2same   endof
      2  of  0x7EA1.A800 m.sd    fs2same   endof
   endcase
;
: fcvtxn     ( -- )
   2 0 try: case
      0  of  0x2E61.6800 m.v#d   fv2narrow   endof
      1  of  0x7E61.6800 m.d     fs2narrow   endof
   endcase
;
: fcvtxn2   0x6E61.6800 m.v#d   %fs2narrow  ;


: ins   ( -- )
   2 0 try: case
      0  of  0x4E00.1C00  ^simd-ins-veg   endof
      1  of  0x6E00.0400  ^simd-ins-veve  endof
   endcase
;

: ld1   ( -- )
   2 0 try: case
      0  of  0x0C40.2000  ld1-m    endof
      1  of  0x0D40.0000  1 ld-s   endof
   endcase
;
: ld2   ( -- )
   2 0 try: case
      0  of  0x0C40.8000  2 ld-m   endof
      1  of  0x0D60.0000  2 ld-s   endof
   endcase
;
: ld3   ( -- )
   2 0 try: case
      0  of  0x0C40.4000  3 ld-m   endof
      1  of  0x0D40.2000  3 ld-s   endof
   endcase
;
: ld4   ( -- )
   2 0 try: case
      0  of  0x0C40.0000  4 ld-m   endof
      1  of  0x0D60.2000  4 ld-s   endof
   endcase
;

: ldnp        8 2 try:  1  rd, ra,  rd->V,opc,sz  5rot ldstp-adr-opc2  make-no-allocate  ;
: ldp         8 0 try:  1  rd, ra,  rd->V,opc,sz  5rot ldstp-adr-opc2  ;
: ldpsw       8 0 try:  1  xd, xa,      0  1  4   5rot ldstp-adr-opc2  ;
: ldrb        6 0 try:  0  0  wd,    1      adrmodes-1  ;
: ldrh        6 0 try:  1  0  wd,    1      adrmodes-1  ;
: ldrsb       6 0 try:  0  0  wxd,->3/2     adrmodes-1  ;
: ldrsh       6 0 try:  1  0  wxd,->3/2     adrmodes-1  ;
: ldrsw       7 0 try:  2  0  xd,    2      adrmodes-2  ;

: movi   ( -- )
   <asm 
   rd,  rd-adt 
   CASE
      adt-dreg.8b  OF  0x0F00.E400 movi8     ENDOF
      adt-qreg.16b OF  0x4F00.E400 movi8     ENDOF
      
      adt-dreg.4h  OF  0x0F00.8400 movi16    ENDOF
      adt-qreg.8h  OF  0x4F00.8400 movi16    ENDOF
      
      adt-dreg.2s  OF  0x0F00.0400 movi32    ENDOF
      adt-qreg.4s  OF  0x4F00.0400 movi32    ENDOF
      
      adt-dreg     OF  0x2F00.E400 movi-imm  ENDOF
      adt-qreg.2d  OF  0x6F00.E400 movi-imm  ENDOF
      
      true ?invalid-regs
   ENDCASE
   asm> 
;

: mvn   ( -- )
   2 0 try: case
      0  of  1 1  wxd, [wxzn] log-reg   endof
      1  of  0x2E20.5800 m.v#b  v2same   endof
   endcase
;
: mvni   ( -- )
   <asm 
   rd,  rd-adt 
   CASE
      adt-dreg.4h  OF  0x2F00.8400  movi16    ENDOF
      adt-qreg.8h  OF  0x6F00.8400  movi16    ENDOF
      adt-dreg.2s  OF  0x2F00.0400  movi32    ENDOF
      adt-qreg.4s  OF  0x6F00.0400  movi32    ENDOF
      true ?invalid-regs
   ENDCASE
   asm> 
;

: prfm        5 0 try:  prfop,  3 0 2   adrmodes-3  ;
: ret         2 0 try: ret-try  0xd65f.0000 iop  ;

: shl        ( -- )
   2 0 try: case
      0  of  0x0F00.5400 m.v#bhsd  v2#same  endof
      1  of  0x5F00.5400 m.d      s2#same  endof
   endcase
;

: smlal      ( -- )
   2 0 try: case
      0  of  0x0F00.2000 m.v#sd  velem-long   endof
      1  of  0x0E20.8000 m.v#hsd  v3long    endof
   endcase
;
: smlal2     ( -- )
   2 0 try: case
      0  of  0x4F00.2000 m.v#sd  velem-long  endof
      1  of  0x4E20.8000 m.v#hsd  v3long        endof
   endcase
;
: smlsl      ( -- )
   2 0 try: case
      0  of  0x0F00.6000 m.v#sd  velem-long   endof
      1  of  0x0E20.A000 m.v#hsd  v3long    endof
   endcase
;
: smlsl2     ( -- )
   2 0 try: case
      0  of  0x4F00.6000 m.v#sd  velem-long  endof
      1  of  0x4E20.A000 m.v#hsd  v3long        endof
   endcase
;   
: smull      ( -- )
   3 0 try: case
      0  of  0x9b20.7c00 m.x     3long         endof
      1  of  0x0E20.C000 m.v#hsd  v3long        endof
      2  of  0x0F00.A000 m.v#sd  velem-long  endof
   endcase
;
: smull2     ( -- )
   2 0 try: case
      0  of  0x4E20.C000 m.v#hsd   v3long        endof
      1  of  0x4F00.A000 m.v#sd  velem-long  endof
   endcase
;

: sqdmlal    ( -- )
   4 0 try: case
      0  of  0x0E20.9000 m.v#sd    v3long         endof
      1  of  0x5E20.9000 m.sd     s3long         endof
      2  of  0x0F00.3000 m.v#sd  velem-long   endof
      3  of  0x5F00.3000 m.sd    selem-long  endof
   endcase
;
: sqdmlal2   ( -- )
   2 0 try: case
      0  of  0x4E20.9000 m.v#sd   v3long      endof
      1  of  0x4F00.3000 m.v#sd  velem-long    endof
   endcase
;
: sqdmlsl    ( -- )
   4 0 try: case
      0  of  0x0E20.B000 m.v#sd   v3long         endof
      1  of  0x5E20.B000 m.sd    s3long         endof
      2  of  0x0F00.7000 m.v#sd  velem-long   endof
      3  of  0x5F00.7000 m.sd  selem-long  endof
   endcase
;
: sqdmlsl2   ( -- )
   2 0 try: case
      0  of  0x4E20.B000 m.v#sd   v3long        endof
      1  of  0x4F00.7000 m.v#sd  velem-long  endof
   endcase
;
: sqdmulh    ( -- )
   4 0 try: case
      0  of  0x0E20.B400 m.v#hs    v3same         endof
      1  of  0x5E20.B400 m.hs     s3same         endof
      2  of  0x0F00.C000 m.v#sd  velem-long   endof
      3  of  0x5F00.C000 m.sd  selem-long  endof
   endcase
;
: sqdmull    ( -- )
   4 0 try: case
      0  of  0x0E20.D000 m.v#sd    v3long       endof
      1  of  0x5E20.D000 m.sd     s3long       endof
      2  of  0x0F00.B000 m.v#sd  velem-long    endof
      3  of  0x5F00.B000 m.sd  selem-long   endof
   endcase
;
: sqdmull2   ( -- )
   2 0 try: case
      0  of  0x4E20.D000 m.v#sd   v3long        endof
      1  of  0x4F00.B000 m.v#sd  velem-long  endof
   endcase
;

: sqneg      ( -- )
   2 0 try: case
      0  of  0x0e20.3c00 m.v#bhsd  v2same   endof
      1  of  0x5e20.3c00 m.bhsd   s2same   endof
   endcase
;

: sqrdmulh    ( -- )
   4 0 try: case
      0  of  0x2E20.B400 m.v#hs    v3same     endof
      1  of  0x7E20.B400 m.hs     s3same     endof
      2  of  0x0F00.D000 m.v#sd  velem-long    endof
      3  of  0x5F00.D000 m.sd  selem-long   endof
   endcase
;

: sqrshrn    ( -- )
   2 0 try: case
      0  of  0x0F00.9C00 m.v#bhs  v2#narrow     endof
      1  of  0x5F00.9C00 m.bhs   s2#narrow     endof
   endcase
;
: sqrshrn2    0x4F00.9C0  m.v#bhs  %v2#narrow  ;

: sqrshrun    ( -- )
   2 0 try: case
      0  of  0x2F00.8C00 m.v#bhs  v2#narrow     endof
      1  of  0x7F00.8C00 m.bhs   s2#narrow     endof
   endcase
;
: sqrshrun2    0x6F00.8C00 m.v#bhs  %v2#narrow  ;

: sqshl      ( -- )
   4 0 try: case
      0  of  0x0E20.4C00 m.v#bhsd   v3same   endof
      1  of  0x5E20.4C00 m.bhsd    s3same   endof
      2  of  0x0F00.7400 m.v#bhsd    v2#same      endof
      3  of  0x5F00.7400 m.bhsd     s2#same      endof
   endcase
;
: sqshlu     ( -- )
   2 0 try: case
      0  of  0x2F00.6400 m.v#bhsd  v2#same   endof
      1  of  0x7F00.6400 m.bhsd   s2#same   endof
   endcase
;

: sqshrn    ( -- )
   2 0 try: case
      0  of  0x0F00.9400 m.v#bhs  v2#narrow   endof
      1  of  0x5F00.9400 m.bhs   s2#narrow   endof
   endcase
;
: sqshrn2    0x4F00.9400 m.v#bhs  %v2#narrow  ;

: sqshrun    ( -- )
   2 0 try: case
      0  of  0x2F00.8400 m.v#bhs  v2#narrow   endof
      1  of  0x7F00.8400 m.bhs   s2#narrow   endof
   endcase
;
: sqshrun2    0x6F00.8400 m.v#bhs  %v2#narrow  ;

: sqxtn      ( -- )
   2 0 try: case
      0  of  0x5E20.A800 m.bhs   s2narrow   endof
      1  of  0x0E20.A800 m.v#bhs  v2narrow   endof
   endcase
;
: sqxtn2   0x4E20.A800 m.v#bhs  %v2narrow  ;

: sqxtun      ( -- )
   2 0 try: case
      0  of  0x7E21.2800 m.bhs   s2narrow  endof
      1  of  0x2E21.2800 m.v#bhs  v2narrow  endof
   endcase
;
: sqxtun2   0x6E21.2800 m.v#bhs  %v2narrow  ;

: sshl       ( -- )
   2 0 try: case
      0  of  0x0E20.4400 m.v#bhsd  v3same       endof
      1  of  0x5E20.4400 m.d      s3same       endof
   endcase
;

: sshr       ( -- )
   2 0 try: case
      0  of  0x0F00.0400 m.v#bhsd  v2#same   endof
      1  of  0x5F00.0400 m.d      s2#same   endof
   endcase
;

: st1   ( -- )
   2 0 try: case
      0  of  0x0C00.2000  ld1-m    endof
      1  of  0x0D00.0000  1 ld-s   endof
   endcase
;
: st2   ( -- )
   2 0 try: case
      0  of  0x0C00.8000  2 ld-m   endof
      1  of  0x0D20.0000  2 ld-s   endof
   endcase
;
: st3   ( -- )
   2 0 try: case
      0  of  0x0C00.4000  3 ld-m   endof
      1  of  0x0D00.2000  3 ld-s   endof
   endcase
;
: st4   ( -- )
   2 0 try: case
      0  of  0x0C00.0000  4 ld-m   endof
      1  of  0x0D20.2000  4 ld-s   endof
   endcase
;

: stnp        8 2 try:  0  rd, ra,  rd->V,opc,sz  5rot ldstp-adr-opc2  make-no-allocate  ;
: stp         8 0 try:  0  rd, ra,  rd->V,opc,sz  5rot ldstp-adr-opc2  ;
: strb        7 0 try:  0  0  wd,    0      adrmodes-1  ;
: strh        7 0 try:  1  0  wd,    0      adrmodes-1  ;

: sub   ( -- )
   5 0 try: case
      0  of  0 1 0 add-sub                          endof
      1  of  1 1 0 add-sub                          endof
      2  of  2 1 0 add-sub                          endof
      3  of  0x7E20.8400 m.d      s3same      endof
      4  of  0x2E20.8400 m.v#bhsd  v3same      endof
   endcase
;
: subs        3 0 try: 1    1  add-sub ;

: suqadd     ( -- )
   2 0 try: case
      0  of  0x0E20.3800 m.v#bhsd  v2same    endof
      1  of  0x5E20.3800 m.bhsd   s2same    endof
   endcase
;

: umlal      ( -- )
   2 0 try: case
      0  of  0x2F00.2000 m.v#sd  velem-long        endof
      1  of  0x2E20.8000 m.v.4s2d  umlal-args?  endof
   endcase
;
: umlal2     ( -- )
   2 0 try: case
      0  of  0x6F00.2000 m.v#sd  velem-long          endof
      1  of  0x6E20.8000 m.v.4s2d  umlal2-args?   endof
   endcase
;
: umlsl      ( -- )
   2 0 try: case
      0  of  0x2F00.6000 m.v#sd  velem-long          endof
      1  of  0x2E20.A000 m.v.4s2d  umlal-args?    endof
   endcase
;
: umlsl2     ( -- )
   2 0 try: case
      0  of  0x6F00.6000 m.v#sd  velem-long          endof
      1  of  0x6E20.A000 m.v.4s2d  umlal2-args?   endof
   endcase
;
: umull      ( -- )
   3 0 try: case
      0  of  0x9ba0.7c00 m.x        3long           endof
      1  of  0x2E20.C000 m.v.8h4s2d  umull-args?     endof
      2  of  0x2F00.A000 m.v#sd  velem-long           endof
   endcase
;
: umull2     ( -- )
   2 0 try: case
      0  of  0x6E20.C000 m.v.8h4s2d   umull2-args?    endof
      1  of  0x6F00.A000 m.v#sd  velem-long           endof
   endcase
;

: uqrshrn    ( -- )
   2 0 try: case
      0  of  0x2F00.9C00 m.v#bhs  v2#narrow   endof
      1  of  0x7F00.9C00 m.d     s2#narrow   endof
   endcase
;
: uqrshrn2      0x6F00.9C00 m.v#bhs  %v2#narrow  ;

: uqshl      ( -- )
   4 0 try: case
      0  of  0x2E20.4C00 m.v#bhsd   v3same    endof
      1  of  0x7E20.4C00 m.bhsd    s3same    endof
      2  of  0x2F00.7400 m.v#bhsd   v2#same    endof
      3  of  0x7F00.7400 m.bhsd    s2#same    endof
   endcase
;
: uqshrn    ( -- )
   2 0 try: case
      0  of  0x2F00.9400 m.v#bhs  v2#narrow   endof
      1  of  0x7F00.9400 m.d     s2#narrow   endof
   endcase
;
: uqshrn2    0x6F00.9400 m.v#bhs  %v2#narrow  ;

: uqxtn      ( -- )
   2 0 try: case
      0  of  0x2E20.A800 m.v#bhs  v2narrow   endof
      1  of  0x7E20.A800 m.bhs   s2narrow   endof
   endcase
;
: uqxtn2   <asm  0x6E20.A800  m.v#bhs  v2narrow  asm>  ;

: ushr       ( -- )
   2 0 try: case
      0  of  0x2F00.0400 m.v#bhsd  v2#same   endof
      1  of  0x7F00.0400 m.d      s2#same   endof
   endcase
;
