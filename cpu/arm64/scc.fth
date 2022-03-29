purpose: System Control Register access words
\ See license at end of file

\ generic access to special registers based on current exception level

hex
\ shift bits for easy convenience: EL3 returns 3, etc.
code current-el@   ( -- EL )   push tos,sp   mrs tos,CurrentEL  lsr  tos,tos,#2  c;

: sctlr@   ( -- n )
   current-el@ case
      1 of  sctlr_el1@   endof
      2 of  sctlr_el2@   endof
      3 of  sctlr_el3@   endof
      ( default )  0 swap
   endcase
;
: sctlr!   ( n -- )
   current-el@ case
      1 of  sctlr_el1!   endof
      2 of  sctlr_el2!   endof
      3 of  sctlr_el3!   endof
      nip
   endcase
;

: actlr@   ( -- n )
   current-el@ case
      1 of  actlr_el1@   endof
      2 of  actlr_el2@   endof
      3 of  actlr_el3@   endof
      ( default )  0 swap
   endcase
;
: actlr!   ( n -- )
   current-el@ case
      1 of  actlr_el1!   endof
      2 of  actlr_el2!   endof
      3 of  actlr_el3!   endof
      nip
   endcase
;

\ Cyclone User Manual, 5.3.12, p96
\ "The following code sequence ensures the visibility of an update to code and the execution of the branch to initiate the update to the code."
d# 64 constant /cacheline
\ ensure I-cache discards stale data
code iflush  ( adr len -- )
   pop   x0, sp        \ x0: adr
   set   x1,#`/cacheline`
   begin
      ic    ivau, x0
      add   x0,x0,x1
      subs   tos,tos,x1
   0<= until
   dsb   SY	\ ensure completion of the invalidation
   isb   SY	\ ensure instruction fetch path sees new I cache state
   pop   tos, sp
c;

code TLB_FLUSH_EL3  ( -- )
   dsb   ish
   tlbi  ALLE3
   dsb   SY
   isb   SY
c;

code TLB_FLUSH_EL2  ( -- )
   dsb   ish
   tlbi  ALLE2
   dsb   SY
   isb   SY
c;

code TLB_FLUSH_EL1  ( -- )
   dsb   ish
   tlbi  VMALLE1
   dsb   SY
   isb   SY
c;

code TLB_FLUSH_EL1_IS  ( -- )
   dsb   ish
   tlbi  VMALLE1IS
   dsb   SY
   isb   SY
c;

code TLB_FLUSH_EL1_OS  ( -- )
   dsb   ish
   tlbi  VMALLE1OS
   dsb   SY
   isb   SY
c;

alias tlb-flush    TLB_FLUSH_EL1

code rvaeis_tlb_flush_el1 ( reg-value -- )
   dsb      ish
   tlbi     RVAE1IS, tos
   dsb      SY
   isb      SY
   pop      tos, sp
c;

code rvaeis_tlb_flush_el2 ( reg-value -- )
   dsb      ish
   tlbi     RVAE2IS, tos
   dsb      SY
   isb      SY
   pop      tos, sp
c;

code rvaeis_tlb_flush_el3 ( reg-value -- )
   dsb      ish
   tlbi     RVAE3IS, tos
   dsb      SY
   isb      SY
   pop      tos, sp
c;

: rvaeis-tlb-flush ( reg-value -- )
   current-el@ case
      1 of  rvaeis_tlb_flush_el1   endof
      2 of  rvaeis_tlb_flush_el2   endof
      3 of  rvaeis_tlb_flush_el3   endof
      nip
   endcase
;

code RVAE_TLB_FLUSH_EL1 ( reg-value -- )
   dsb      ish
   tlbi     RVAE1, tos
   dsb      SY
   isb      SY
   pop      tos, sp
c;

code RVAE_TLB_FLUSH_EL2 ( reg-value -- )
   dsb      ish
   tlbi     RVAE2, tos
   dsb      SY
   isb      SY
   pop      tos, sp
c;

code RVAE_TLB_FLUSH_EL3 ( reg-value -- )
   dsb      ish
   tlbi     RVAE3, tos
   dsb      SY
   isb      SY
   pop      tos, sp
c;

: rvae-tlb-flush ( reg-value -- )
   current-el@ case
      1 of  RVAE_TLB_FLUSH_EL1   endof
      2 of  RVAE_TLB_FLUSH_EL2   endof
      3 of  RVAE_TLB_FLUSH_EL3   endof
      nip
   endcase
;

code tlb-flush-asid ( asid -- )
   lsl      tos, tos, #48
   dsb      ish
   tlbi     ASIDE1IS, tos
   dsb      SY
   isb      SY
   pop      tos, sp
c;

code TLB_FLUSH_ADR_EL3  ( adr -- )
\ This architecture is not terribly orthogonal
   dsb  ish
   tlbi ALLE3IS
   dsb  SY
   isb  SY
   pop  tos, sp
c;

code TLB_FLUSH_ADR_EL2  ( adr -- )
   dsb  ish
   tlbi ALLE2IS
   dsb  SY
   isb  SY
   pop  tos, sp
c;

code TLB_FLUSH_ADR_EL1  ( adr -- )
   lsr  tos, tos, #12 \ Put VA[55:12] into [43:0]
   bfi  tos, xzr, #44, #20 \ Zero out [63:44]
   dsb  ish
   tlbi VAAE1IS, tos
   dsb  SY
   isb  SY
   pop  tos, sp
c;

: tlb-flush-adr  ( adr -- )
   current-el@ case
      1 of  TLB_FLUSH_ADR_EL1   endof
      2 of  TLB_FLUSH_ADR_EL2   endof
      3 of  TLB_FLUSH_ADR_EL3   endof
      0 swap
   endcase
;


code TLB_FLUSH_ADR_LOCAL_EL3  ( adr -- )
\ This architecture is not terribly orthogonal
   dsb  ish
   tlbi ALLE3
   dsb  SY
   isb  SY
   pop  tos, sp
c;

code TLB_FLUSH_ADR_LOCAL_EL2  ( adr -- )
   dsb  ish
   tlbi ALLE2
   dsb  SY
   isb  SY
   pop  tos, sp
c;

code TLB_FLUSH_ADR_LOCAL_EL1  ( adr -- )
   lsr  tos, tos, #12 \ Put VA[55:12] into [43:0]
   bfi  tos, xzr, #44, #20 \ Zero out [63:44]
   dsb  ish
   tlbi VAAE1, tos
   dsb  SY
   isb  SY
   pop  tos, sp
c;

: tlb-flush-adr-local  ( adr -- )
   current-el@ case
      1 of  TLB_FLUSH_ADR_LOCAL_EL1   endof
      2 of  TLB_FLUSH_ADR_LOCAL_EL2   endof
      3 of  TLB_FLUSH_ADR_LOCAL_EL3   endof
      0 swap
   endcase
;

\ : .sctlr   ( -- )
\    sctlr@
\    dup 0200.0000 and if  ." EE " then
\    dup 0010.0000 and if  ." UWXN " then
\    dup 0008.0000 and if  ." WXN " then
\    dup 0000.1000 and if  ." I " then
\    dup 0000.0008 and if  ." SA " then
\    dup 0000.0004 and if  ." C " then
\    dup 0000.0002 and if  ." A " then
\    dup 0000.0001 and if  ." M " then
\    drop
\ ;

: vector-base@ ( -- adr )
   current-el@ case
      1 of  VBAR_EL1@   endof
      2 of  VBAR_EL2@   endof
      3 of  VBAR_EL3@   endof
      0 swap
   endcase
;
: vector-base! ( adr --- )
   current-el@ case
      1 of  VBAR_EL1!   endof
      2 of  VBAR_EL2!   endof
      3 of  VBAR_EL3!   endof
      nip
   endcase
;
: mair@ ( -- mair )
   current-el@ case
      1 of  MAIR_EL1@   endof
      2 of  MAIR_EL2@   endof
      3 of  MAIR_EL3@   endof
      0 swap
   endcase
;
: mair0@ ( -- mair-lo32 )  mair@  h# ffff.ffff and  ;
: mair1@ ( -- mair-hi32 )  mair@  d# 32 >> h# ffff.ffff and  ;
: mair! ( -- adr )
   current-el@ case
      1 of  MAIR_EL1!   endof
      2 of  MAIR_EL2!   endof
      3 of  MAIR_EL3!   endof
      nip
   endcase
;
: tcr! ( tcr -- )
   current-el@ case
      1 of  TCR_EL1!   endof
      2 of  TCR_EL2!   endof
      3 of  TCR_EL3!   endof
      nip
   endcase
;
: tcr@ ( -- tcr )
   current-el@ case
      1 of  TCR_EL1@   endof
      2 of  TCR_EL2@   endof
      3 of  TCR_EL3@   endof
      nip
   endcase
;
: ttbr0@ ( -- adr )
   current-el@ case
      1 of  TTBR0_EL1@   endof
      2 of  TTBR0_EL2@   endof
      3 of  TTBR0_EL3@   endof
      0 swap
   endcase
;
: ttbr0! ( -- adr )
   current-el@ case
      1 of  TTBR0_EL1!  TLB_FLUSH_EL1   endof
      2 of  TTBR0_EL2!  TLB_FLUSH_EL2   endof
      3 of  TTBR0_EL3!  TLB_FLUSH_EL3   endof
      nip
   endcase
;
: ttbr1@ ( -- adr )
   current-el@ case
      1 of  TTBR1_EL1@   endof
      2 of  TTBR1_EL2@   endof
      0 swap
   endcase
;
: ttbr1! ( -- adr )
   current-el@ case
      1 of  TTBR1_EL1!  TLB_FLUSH_EL1   endof
      2 of  TTBR1_EL2!  TLB_FLUSH_EL2   endof
      nip
   endcase
;

alias ttbr@  ttbr0@
alias ttbr!  ttbr0!

code tpidr_el2@  ( -- n )
   push   tos,sp
   mrs    tos,TPIDR_EL2
c;

code tpidr_el1@  ( -- n )
   push   tos,sp
   mrs    tos,TPIDR_EL1
c;

code tpidr_el0@  ( -- n )
   push   tos,sp
   mrs    tos,TPIDR_EL0
c;

code tpidrro_el0@  ( -- n )
   push   tos,sp
   mrs    tos,TPIDRRO_EL0
c;

code tpidr_el2!  ( n -- )
   msr    TPIDR_EL2,tos
   pop    tos,sp
c;

code tpidr_el1!  ( n -- )
   msr    TPIDR_EL1,tos
   pop    tos,sp
c;

code tpidr_el0!  ( n -- )
   msr    TPIDR_EL0,tos
   pop    tos,sp
c;

code tpidrro_el0!  ( n -- )
   msr    TPIDRRO_EL0,tos
   pop    tos,sp
c;

defer cpu#
code (cpu#)  ( -- n )
   push  tos, sp
   mrs   x0, MPIDR_EL1
   and   tos, x0, #255    \ bits 0:7 are the "lowest level affinity field" bits
c;
' (cpu#) is cpu#

\ This routine needs the cache-type as an argument.
\ 0: L1 D-$   1: L1 I-$   2: L2 D-$   3: L3 D-$
\ Bits [2:0] represent (Log2(Number of bytes in cache line)) - 4
\ ex: For a line length of 16 bytes: Log2(32) = 5, Bits [2:0] = 1.
: /cache-line@ ( cache-type -- n )
   csselr_el1! 1 ccsidr_el1@ 0x7 and 4 + <<
;

: #cache-ways@ ( cache-type -- n )
   csselr_el1! ccsidr_el1@ 0x3 >> 0x3ff and 1+
;

: #cache-sets@ ( cache-type -- n )
   csselr_el1! ccsidr_el1@ 0xd >> 0x7fff and 1+
;

: /cache-size ( cache-type -- n )
   >r r@ /cache-line@ r@ #cache-ways@ r> #cache-sets@ * *
;

\ CSSELR_EL1[3-1]: cache level -1     [0]: I not D
: .cache-size   ( level ctype -- )
   swap  ." L" dup 1 .r   1- 2*  swap
   case
      0 of  ." D: "     endof
      1 of  ." I: " 1+  endof
      ." :  "
   endcase
   CSSELR_EL1!   CCSIDR_EL1@
   dup d# 13 >> d# 15 mask and 1+ dup >r .d ." sets "
   dup d# 3 >> d# 10 mask and 1+ dup >r .d ." ways "
   dup 7 and 1 swap 4 + lshift dup >r .d ." bytes/line "
   dup h# 8000.0000 and if ." WT " then
   dup h# 4000.0000 and if ." WB " then
   dup h# 2000.0000 and if ." RA " then
       h# 1000.0000 and if ." WA " then
   r> r> r> * * d# 1024 / ." (" .d ." KB) "
   cr
;
: (.cache-config)   ( level ctype -- )
   case
      0 of  drop  endof                               \ no cache
      1 of  1 .cache-size  endof                      \ I
      2 of  0 .cache-size  endof                      \ D
      3 of  dup 1 .cache-size  0 .cache-size  endof   \ I and D
      4 of  2 .cache-size  endof                      \ U
      abort" invalid cache type "
   endcase
;
\ CLIDR 3 bits per cache level (0..7) giving type (ignoring upeer bits)
: .cache-config   ( -- )
   ." CTR " CTR_EL0@ .h
   ." CLIDR " CLIDR_EL1@ dup .h  cr   ( clidr )
   8 1 do   i over 7 and (.cache-config)  3 >>  loop  drop
;
: .cache-config-all   ( -- )    \ print all in case CLIDR is wrong
   8 1 do   i 3 (.cache-config)  loop
;

\ fs:
\ CLIDR a200023 CTR 8444c004 CSSELR 1
\ L1: 512 sets 16 ways 64 bytes/line WB RA WA (512 KB)
\ L2: 256 sets 2 ways 64 bytes/line WB RA WA (32 KB)
\ fpga:
\ CLIDR 9200023 CTR 8444c004 CSSELR 0
\ L1: 512 sets 2 ways 64 bytes/line WB RA (64 KB)
\ L2: 512 sets 2 ways 64 bytes/line WB RA (64 KB)

\ note: cyclone manual says
\ L1: 64KB 2 way 64B/L
\ L2: 1MB  8 way 64B/L

code DC_CIVAC ( adr -- )
   dc   civac, tos
   pop  tos,sp
c;

: clean-invalidate-dcache
   DC_CIVAC
   barrier
;

code _ic-iallu_
   dmb  sy
   ic   iallu,x0
   dsb  sy
   isb  sy
   ret  lr
end-code

code ic-iallu
   bl   '' _ic-iallu_
c;

1 [IF]
\
\ In this clean and invalidate algorithm, note that
\ the clear x0 which holds the address; we don't want the
\ CPU to get any funny ideas about using the address in that
\ register for anything.
\
code _clean-invalidate-range_ ( x0: addr  x1: len -- )
   \ Get size of smallest cacheline
   mrs    x2, CTR_EL0
   lsr    x2, x2, #16
   and    x2, x2, #0xf \ x2 = Log2 of the number of words in the smallest cache line in data caches
   add    x2, x2, #2 \ adjust because 1 word = 4 bytes
   mov    x3, #1
   lsl    x2, x3, x2 \ /cacheline
   sub    x3, x2, #1 \ /cacheline - 1

   \ Bump len if the given len will cross another cacheline
   \ if ((/cacheline - (addr % /cacheline)) < (len % /cacheline)) len += /cacheline
   and    x4, x0, x3
   sub    x4, x2, x4
   and    x5, x1, x3
   cmp    x4, x5
   < if
      add     x1, x1, x2
   then

   begin
      dc     civac, x0
      add    x0, x0, x2
      subs   x1, x1, x2
   0<= until
   movz   x0, #0    \ Nuke the address
   dsb    SY
   isb    SY
   ret    lr
end-code

code _clean-invalidate-range  ( addr len -- )
   mov     x1, tos
   pop     x0, sp
   bl      '' _clean-invalidate-range_
   pop     tos, sp
c;

: clean-invalidate-range  ( addr len -- )
   dup 0 <= abort" clean-invalidate-range: Range must be greater than 0"
   _clean-invalidate-range
;
[ELSE]
: clean-invalidate-range  ( addr len -- )
   dup 0 <= if  2drop  then
   3F + -40 and bounds ?do
     i DC_CIVAC
   40 +loop
   barrier
;
[THEN]
