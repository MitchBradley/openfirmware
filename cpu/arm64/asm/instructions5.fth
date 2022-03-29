\ Assembler Instruction Mnemonics for ARMv8.5
\ 13 new instructions

: xaflag        0xd500.403f  %op  ;
: axflag        0xd500.405f  %op  ;
: sb            0xd503.30ff  %op  ;
: csdb          0xd503.229f  %op  ;
: ssbb          0xd503.309f  %op  ;
: pssbb         0xd503.349f  %op  ;

: frint32z      0x0e21.e800 m.v#sd  0x1e28.4000 m.sd  %f2same-nv  ;
: frint32x      0x2e21.e800 m.v#sd  0x1e28.c000 m.sd  %f2same-nv  ;
: frint64z      0x0e21.f800 m.v#sd  0x1e29.4000 m.sd  %f2same-nv  ;
: frint64x      0x2e21.f800 m.v#sd  0x1e29.c000 m.sd  %f2same-nv  ;

: cfp          <asm  rctx-parse  3 7 3 4 ,xreg  system  asm>  ;
: dvp          <asm  rctx-parse  3 7 3 5 ,xreg  system  asm>  ;
: cpp          <asm  rctx-parse  3 7 3 7 ,xreg  system  asm>  ;


\ MSR SSBS, #Imm1      okay? check this

