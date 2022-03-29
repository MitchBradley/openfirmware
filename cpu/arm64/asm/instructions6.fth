\ Assembler Instruction Mnemonics for ARMv8.6
\ 6 new instructions 

: dgh         0xd503.20df %op  ;  \ hint#6 ( NOP )

: ummla       0x6e80.a400  m.v.4s  %mmla  ;
: usmmla      0x4e80.ac00  m.v.4s  %mmla  ;

\ enhancedPAC2 + FPAC
\ Bfloat16


