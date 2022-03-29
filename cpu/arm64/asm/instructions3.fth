\ Assembler Instruction Mnemonics for ARMv8.3
\ 52 new instructions

: fcadd-3     <asm  0x2e00.e400 m.v.sd  c3same  asm>  ;     \ fcadd moved to -mix.fth
: fcmla-3     ( -- )                                        \ fcmla moved to -mix.fth
   2 0 try: case
      0  of  0x2f00.1000 m.v#hs  celem-same     endof
      1  of  0x2e00.c400 m.v#hsd  cv3same   endof
   endcase
;

: pacia1716   0xd503.211f %op  ;
: pacib1716   0xd503.215f %op  ;
: autia1716   0xd503.219f %op  ;
: autib1716   0xd503.21df %op  ;
: paciaz      0xd503.231f %op  ;
: paciasp     0xd503.233f %op  ;
: pacibz      0xd503.235f %op  ;
: pacibsp     0xd503.237f %op  ;
: autiaz      0xd503.239f %op  ;
: autiasp     0xd503.23bf %op  ;
: autibz      0xd503.23df %op  ;
: autibsp     0xd503.23ff %op  ;
: xpaclri     0xd503.20ff %op  ;

: pacia       0xdac1.0000 m.x  %2same  ;
: pacib       0xdac1.0400 m.x  %2same  ;
: pacda       0xdac1.0800 m.x  %2same  ;
: pacdb       0xdac1.0c00 m.x  %2same  ;
: autia       0xdac1.1000 m.x  %2same  ;
: autib       0xdac1.1400 m.x  %2same  ;
: autda       0xdac1.1800 m.x  %2same  ;
: autdb       0xdac1.1c00 m.x  %2same  ;

: paciza      0xdac1.23e0 m.x  %rd  ;
: pacizb      0xdac1.27e0 m.x  %rd  ;
: pacdza      0xdac1.2be0 m.x  %rd  ;
: pacdzb      0xdac1.2fe0 m.x  %rd  ;
: autiza      0xdac1.33e0 m.x  %rd  ;
: autizb      0xdac1.37e0 m.x  %rd  ;
: autdza      0xdac1.3be0 m.x  %rd  ;
: autdzb      0xdac1.3fe0 m.x  %rd  ;
: xpaci       0xdac1.43e0 m.x  %rd  ;
: xpacd       0xdac1.47e0 m.x  %rd  ;

: pacga       <asm  0x9ac0.3000  d=n=m  m.x rd??iop  asm>  ;

: braa        <asm  0xd71f.0800 m.x  rn, rd  rd??iop  asm>  ;
: brab        <asm  0xd71f.0c00 m.x  rn, rd  rd??iop  asm>  ;
: blraa       <asm  0xd73f.0800 m.x  rn, rd  rd??iop  asm>  ;
: blrab       <asm  0xd73f.0c00 m.x  rn, rd  rd??iop  asm>  ;

: braaz       0xd61f.081f m.x  %rn  ;
: brabz       0xd61f.0c1f m.x  %rn  ;
: blraaz      0xd63f.081f m.x  %rn  ;
: blrabz      0xd63f.0c1f m.x  %rn  ;

: retaa       0xd65f.0bff %op  ;
: retab       0xd65f.0fff %op  ;
: eretaa      0xd6df.0bff %op  ;
: eretab      0xd6df.0fff %op  ;

: ldraa       0xf820.0400 %ldraa  ;
: ldrab       0xf8A0.0400 %ldraa  ;

: fjcvtzs     <asm  wd, dn  0x1e7e.0000 iop  asm>  ;

: ldapr       0x88bf.c000 m.wx  %lsx0  ;
: ldaprb      0x08bf.c000 m.w   %lsx0  ;
: ldaprh      0x48bf.c000 m.w   %lsx0  ;
