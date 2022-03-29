\ Pseudo Instructions

\ For use with FastSIM, but otherwise innocuous when running on real hardware
: sim-trace-on   ( -- )   0xd503.283f %op  ;
: sim-trace-off  ( -- )   0xd503.285f %op  ;

\ Wrapper Call - FirmWorks pseudo-op for armsim wrapper calls
\ Syntax is:       WRC #imm16
\ The mapping for #imm16 to function is defined in the wrapper.
: wrc   ( -- )  0xd4e00000 m.x  %rd  ;


1 [if]
\ aliases
\ only "AdvSIMD three same" are implemented
\ XXX these can probably be eliminated now that all modes are handled by the actual opcodes.

\ prefixing with a 'v' so to not conflict with integer mnemonic
\ need to work these in ( more cussing )
: vadd      <asm rd, rn, rm              0     b# 00     b# 10000      ^simd-int-3same  asm> ;
: vsub      <asm rd, rn, rm              1     b# 00     b# 10000      ^simd-int-3same  asm> ;
: vmla      <asm rd, rn, rm              0     b# 00     b# 10010      ^simd-int-3same  asm> ;
: vmls      <asm rd, rn, rm              1     b# 00     b# 10010      ^simd-int-3same  asm> ;

\ syntax MUST BE d0.8b or q0.16b
: vbic      <asm rd, rn, rm              0     b# 01     b# 00011      ^simd-int-3same  asm> ;
: vand      <asm rd, rn, rm              0     b# 00     b# 00011      ^simd-int-3same  asm> ;
: vorr      <asm rd, rn, rm              0     b# 10     b# 00011      ^simd-int-3same  asm> ;
: vorn      <asm rd, rn, rm              0     b# 11     b# 00011      ^simd-int-3same  asm> ;

: veor      <asm rd, rn, rm              1     b# 00     b# 00011      ^simd-int-3same  asm> ;
[then]
