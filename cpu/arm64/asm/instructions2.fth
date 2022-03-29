\ Assembler Instruction Mnemonics for ARMv8.2
\ 2 new instructions
\ also adds FP16 support to existing FP instructions

: bfc         <asm  0x3300.03E0 m.wx  rd,  #bfc  bitfield  asm>  ;

: rev64       0x0E20.0800 m.v#bhs  %v2same  ;

\ FP16 someday ?

0 [if]
\ XXX f3same-np sets size incorrectly for fp16; modify it!

: fabd16        0x2EC0.1400 m.v.h  0x7EC0.1400 m.h  %f3same-nv  ;
: fabs16        0x0EF8.F800 m.v.h  0x1EE0.C000 m.h  %f2same-nv  ;
\ : facge       0x2E20.EC00 m.v.h  0x7E20.EC00 m.h  %f3same-nv  ;
\ : facgt       0x2EA0.EC00 m.v.h  0x7EA0.EC00 m.h  %f3same-nv  ;
\ : fadd        0x0E20.D400 m.v.h  0x1E20.2800 m.h  %f3same-nv  ;
: faddp16       0x2E40.1400 m.v.h  0x5E30.D800 m.h  %f3same-np  ;
: fccmp16       0x1EE0.0400 m.h  %fcond-cmp  ;
: fccmpe16      0x1EE0.0410 m.h  %fcond-cmp  ;
: fcmle16       0x2ef8.d800 m.v.sd  0x7ef8.d800 m.sd  %f2same-nvz  ;
: fcmlt16       0x0ef8.e800 m.v.sd  0x5ef8.e800 m.sd  %f2same-nvz  ;
: fcsel16       0x1EE0.0C00 m.h   %fcond-sel  ;
\ : fcvtl2      0x4E21.7800 m.v.h  %fs2long  ;
\ : fcvtn       0x0E21.6800 m.v.hs  %fs2narrow  ;
\ : fcvtn2      0x4E21.6800 m.v.hs  %fs2narrow  ;
\ : fdiv        0x2E20.FC00 m.v.h  0x1E20.1800 m.h  %f3same-nv  ;
\ : fmadd       0x1f00.0000 m.h  %fs4same  ;
\ : fmax        0x2E20.F400 m.v.h  0x1E20.4800 m.h  %f3same-nv  ;
\ : fmaxnm      0x0E20.F400 m.v.h  0x1E20.6800 m.h  %f3same-nv  ;
: fmaxnmp16     0x2E20.C400 m.v.h  0x5E30.C800 m.h  %f3same-np  ;
\ : fmaxnmv     0x6E30.C800 m.4s  %across  ;
\ : fmaxv       0x6E30.F800 m.4s  %across  ;
: fmaxp16       0x2E40.3400 m.v.h  0x5E30.F800 m.h  %f3same-np  ;
\ : fmin        0x0EA0.F400 m.v.h  0x1E20.5800 m.h  %f3same-nv  ;
\ : fminnm      0x0EA0.C400 m.v.h  0x1E20.7800 m.h  %f3same-nv  ;
: fminnmp16     0x2EC0.0400 m.v.h  0x5EB0.C800 m.h  %f3same-np  ;
\ : fminnmv     0x6EB0.C800 m.4s  %across  ;
\ : fminv       0x6EB0.F800 m.4s  %across  ;
: fminp16       0x2EC0.3400 m.v.h  0x5EB0.F800 m.h  %f3same-np  ;
\ : fmsub       0x1f00.8000 m.h  %fs4same  ;
\ : fneg        0x2ea0.f800 m.v.h  0x1e21.4000 m.h  %f2same-nv  ;
\ : fnmadd      0x1f20.0000 m.h  %fs4same  ;
\ : fnmsub      0x1f20.8000 m.h  %fs4same  ;
\ : fnmul       0x1e20.8800 m.h  %fs3same ;
\ : frecpe      0x0ea1.d800 m.v.h  0x5ea1.d800 m.h  %f2same-nv  ;
\ : frecps      0x0E20.FC00 m.v.h  0x5E20.FC00 m.h  %f3same-nv  ;
\ : frecpx      0x5EA1.F800 m.h  %fs2same  ;
\ : frinta      0x2e21.8800 m.v.h  0x1e26.4000 m.h  %f2same-nv  ;
\ : frinti      0x2ea1.9800 m.v.h  0x1e27.c000 m.h  %f2same-nv  ;
\ : frintm      0x0e21.9800 m.v.h  0x1e25.4000 m.h  %f2same-nv  ;
\ : frintn      0x0e21.8800 m.v.h  0x1e24.4000 m.h  %f2same-nv  ;
\ : frintp      0x0ea1.8800 m.v.h  0x1e24.c000 m.h  %f2same-nv  ;
\ : frintx      0x2e21.9800 m.v.h  0x1e27.4000 m.h  %f2same-nv  ;
\ : frintz      0x0ea1.9800 m.v.h  0x1e25.c000 m.h  %f2same-nv  ;
\ : frsqrte     0x2ea1.d800 m.v.h  0x7ea1.d800 m.h  %f2same-nv  ;
\ : frsqrts     0x0EA0.FC00 m.v.h  0x5EA0.FC00 m.h  %f3same-nv  ;
\ : fsqrt       0x2ea1.f800 m.v.h  0x1e21.c000 m.h  %f2same-nv  ;
\ : fsub        0x0EA0.D400 m.v.h  0x1E20.3800 m.h  %f3same-nv  ;
[then]
