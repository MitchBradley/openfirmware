Purpose: Prefix assembler for ARM64 Instruction Set
\ We define most addressing modes and nearly all instructions.

\ 1 value asmtest?

only forth also definitions
decimal

fload ${BP}/forth/lib/strcase.fth
fload ${BP}/cpu/arm64/utils.fth
fload ${BP}/cpu/arm64/asm/setup.fth

vocab-helpers
\ most of this code will NOT be visible in the assembler vocabulary

fload ${BP}/cpu/arm64/asm/errors.fth
fload ${BP}/cpu/arm64/asm/adt.fth
fload ${BP}/cpu/arm64/asm/parse.fth
fload ${BP}/cpu/arm64/asm/opcode.fth

[ifndef] clz
fload ${BP}/cpu/arm64/asm/util.fth
[then]

[ifdef] 32bit-host
   fload ${BP}/cpu/arm64/asm/number32.fth
[else]
   fload ${BP}/cpu/arm64/asm/number64.fth
[then]
fload ${BP}/cpu/arm64/asm/number.fth

fload ${BP}/cpu/arm64/asm/regparse.fth
fload ${BP}/cpu/arm64/asm/regs.fth

fload ${BP}/cpu/arm64/asm/branch.fth
fload ${BP}/cpu/arm64/asm/alu.fth
fload ${BP}/cpu/arm64/asm/ldst.fth
fload ${BP}/cpu/arm64/asm/system.fth
fload ${BP}/cpu/arm64/asm/extra.fth
fload ${BP}/cpu/arm64/asm/conditional.fth

fload ${BP}/cpu/arm64/asm/try.fth
fload ${BP}/cpu/arm64/asm/simd.fth
fload ${BP}/cpu/arm64/asm/predicate.fth
fload ${BP}/cpu/arm64/asm/sme.fth
fload ${BP}/cpu/arm64/asm/mov.fth
fload ${BP}/cpu/arm64/asm/ldn.fth
fload ${BP}/cpu/arm64/asm/elements.fth
fload ${BP}/cpu/arm64/asm/sve.fth
fload ${BP}/cpu/arm64/asm/mix.fth


vocab-assembler
\ this code WILL be visible in the assembler vocabulary

fload ${BP}/cpu/arm64/asm/instructions.fth
fload ${BP}/cpu/arm64/asm/instructions-try.fth
fload ${BP}/cpu/arm64/asm/instructions1.fth
fload ${BP}/cpu/arm64/asm/instructions2.fth
fload ${BP}/cpu/arm64/asm/instructions3.fth
fload ${BP}/cpu/arm64/asm/instructions4.fth
fload ${BP}/cpu/arm64/asm/instructions5.fth
fload ${BP}/cpu/arm64/asm/instructions6.fth
fload ${BP}/cpu/arm64/asm/instructions-sme.fth
fload ${BP}/cpu/arm64/asm/instructions-sve.fth
fload ${BP}/cpu/arm64/asm/pseudo.fth
fload ${BP}/cpu/arm64/asm/instructions-mix.fth

\ load structured conditionals late
\ there are name conflicts with Forth words
fload ${BP}/cpu/arm64/asm/strcond.fth
fload ${BP}/cpu/arm64/asm/alias.fth

only forth also definitions

fload ${BP}/cpu/arm64/asm/macro.fth
fload ${BP}/cpu/arm64/asm/code.fth

: xxx  " code foo hex also helpers " eval  ;

