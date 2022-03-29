\ Scaled Matrix Extension instructions
\ 28 instructions

: addha     0xc090.0000 m.za.sd  %addhv  ;
: addva     0xc091.0000 m.za.sd  %addhv  ;

: fmopa     0x8080.0000 m.za.sd  %fmop  ;
: fmops     0x8080.0010 m.za.sd  %fmop  ;
: bfmopa    0x8180.0000 m.za.s  %bfmop  ;
: bfmops    0x8180.0010 m.za.s  %bfmop  ;

: smopa     0xa080.0000 m.za.sd  %mop  ;
: smops     0xa080.0010 m.za.sd  %mop  ;
: sumopa    0xa0a0.0000 m.za.sd  %mop  ;
: sumops    0xa0a0.0010 m.za.sd  %mop  ;
: usmopa    0xa180.0000 m.za.sd  %mop  ;
: usmops    0xa180.0010 m.za.sd  %mop  ;
: umopa     0xa1a0.0000 m.za.sd  %mop  ;
: umops     0xa1a0.0010 m.za.sd  %mop  ;

\ zero has zero docs for <mask> syntax
\ : zero   <asm  c008.0000 get-mask or  asm>  ;
\ so just take an immediate
: zero   <asm  0xc008.0000   8 #uimm or iop  asm>  ;    \ XXX hack

: ld1q   0xe1c0.0000 m.zahv.q  %ls1za  ;
: st1q   0xe1e0.0000 m.zahv.q  %ls1za  ;

: mova   0xc000.0000 %mova  ;

: smstop          0xd503.427f  %op   ;
: smstart         0xd503.437f  %op   ;
: za-enable       0xd503.447f  %op   ;
: za-disable      0xd503.537f  %op   ;

