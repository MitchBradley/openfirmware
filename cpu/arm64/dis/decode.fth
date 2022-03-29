\ split decode into sections

\ =======================================
\
\            DECODE LOGIC
\
\ =======================================

hex

: ,,,   ( mask match word )  rot l, swap l, token, ;
create dp-table
   \ Data Processing Immediate
   1F00.0000  1000.0000  ' adr               ,,, \ PC-rel addressing
   1F00.0000  1100.0000  ' add-imm           ,,, \ Add/Subtract (immediate)
   1F80.0000  1200.0000  ' log-imm           ,,, \ Logical (immediate)
   1F80.0000  1280.0000  ' movknz            ,,, \ Move wide (immediate)
   1F80.0000  1300.0000  ' bitfield          ,,, \ Bitfield
   1F80.0000  1380.0000  ' extract           ,,, \ Extract

   \ Data Processing Register
   1F00.0000  0A00.0000  ' log-reg           ,,, \ Logical (shifted register)
   1F20.0000  0B00.0000  ' add-reg           ,,, \ Add/subtract (shifted register)
   1F20.0000  0B20.0000  ' add-ext-reg       ,,, \ Add/subtract (extended register)
   1FE0.0000  1A00.0000  ' add-carry         ,,, \ Add/subtract (with carry)
   1FE0.0000  1A40.0000  ' cond-compare      ,,, \ Conditional compare
   1FE0.0000  1A80.0000  ' cond-select       ,,, \ Conditional select
   1F00.0000  1B00.0000  ' dataproc-3        ,,, \ Data-processing (3 source)
   FFE0.FC00  9AC0.3000  ' pacga             ,,,  
   5FE0.0000  1AC0.0000  ' dataproc-2        ,,, \ Data-processing (2 source)
   5FE0.0000  5AC0.0000  ' dataproc-1        ,,, \ Data-processing (1 source)
   0 ,
   

create ldst-table
   \ Loads and stores
   3FFF.FC00  38BF.C000  ' ldweak            ,,, \ v8.3 ldapr
   FF20.0400  F820.0400  ' ptr-auth-ld       ,,, \ v8.3 ldraa
   3F20.7C00  0820.7C00  ' cas               ,,, \ v8.1 atomic
   3F20.FC00  3820.8000  ' swp               ,,, \ v8.1 atomic
   3F20.8C00  3820.0C00  ' ldstop            ,,, \ v8.1 atomic
   
   3F00.0000  0800.0000  ' ldstx             ,,, \ Load/store exclusive
   3B00.0000  1800.0000  ' ldst[pc,#]        ,,, \ Load register (literal)
   3B80.0000  2800.0000  ' ldstnp[xn|sp,#]   ,,, \ Load/store no-allocate pair (offset)
   3B80.0000  2880.0000  ' ldstp[xn|sp],#    ,,, \ Load/store register pair (post-indexed)
   3B80.0000  2900.0000  ' ldstp[xn|sp,#]    ,,, \ Load/store register pair (offset)
   3B80.0000  2980.0000  ' ldstp[xn|sp,#]!   ,,, \ Load/store register pair (pre-indexed)
   3B20.0C00  3800.0000  ' ldstu[xn|sp{,#}]  ,,, \ Load/store register (unscaled immediate)
   3B20.0C00  3800.0400  ' ldst[xn|sp],#     ,,, \ Load/store register (immediate post-indexed)
   3B20.0C00  3800.0800  ' ldstt[xn|sp{,#}]  ,,, \ Load/store regisetr (unprivileged)
   3B20.0C00  3800.0C00  ' ldst[xn|sp,#]!    ,,, \ Load/store register (immediate pre-indexed)
   3B20.0C00  3820.0800  ' ldst[xn|sp,rm]    ,,, \ Load/store register (register offset)
   3B00.0000  3900.0000  ' ldst[xn|sp{,#}]   ,,, \ Load/store register (unsigned immediate)

    \ check for new atomics after the normal ones above
    \ this may be imperfect but seems to work 
   3F20.8C00  3820.0000  ' ldstop            ,,, \ v8.1 atomic
   0 ,

create brsys-table
   \ Branches, Exception Generation and System
   7C00.0000  1400.0000  ' br-uncond-imm     ,,, \ Unconditional branch (immediate)
   7E00.0000  3400.0000  ' cmp-br-imm        ,,, \ Compare & branch (immediate)
   7E00.0000  3600.0000  ' tst-br-imm        ,,, \ Test & branch (immediate)
   FE00.0000  5400.0000  ' br-cond-imm       ,,, \ Conditional branch (immediate)
   FF00.0000  D400.0000  ' exception         ,,, \ Exception generation (immediate)
   FFC0.0000  D500.0000  ' system            ,,, \ System
   FE00.0000  D600.0000  ' br-uncond-reg     ,,, \ Unconditional branch (register)
   0 ,

create simd-table
   BF00.0000  0C00.0000  ' SIMD-LDST-Multiple  ,,, \ AdvSIMD load/store multiple elements
   BF00.0000  0D00.0000  ' SIMD-LDST-SINGLE    ,,, \ AdvSIMD load/store single element

   \ Neon Data Processing
   FFBE.7C00  1E28.4000  ' frintn#s                 ,,, \ scalar FRINT32Z etc
   9FBF.EC00  0E21.E800  ' frintn#v                 ,,, \ vector FRINT32Z etc

   FFFF.FC00  1E7E.0000  ' fjcvtzs                  ,,, \ JS floating to fixed
   FFA0.1FE0  1E20.1000  ' FP-imm                   ,,, \ Floating-point immediate
   FF20.FC07  1E20.2000  ' FP-compare               ,,, \ Floating-point compare
   FFA0.0C00  1E20.0400  ' FP-cond-compare          ,,, \ Floating-point conditional compare
   FF20.0C00  1E20.0C00  ' FP-cond-select           ,,, \ Floating-point conditional select

   \ BF16 decodes
   \ had to put this here cuz FP-data-proc-1 will decode bfcvt as valid op
   BFFF.fc00  1e63.4000  ' AdvSIMD-bfcvt    ,,,  \ scalar cvt f32 to bf16
   FFE0.fc00  6e40.ec00  ' AdvSIMD-bfmmla   ,,,     \ bf61 matrix mul 2x2
   BFE0.fc00  2ec0.fc00  ' AdvSIMD-bfmlalbt ,,,     \ bfmlal 'b' bottom 't' Top
   BFFF.fc00  0ea1.6800  ' AdvSIMD-bfcvtn   ,,,     \ bfcvtn & bfcvtn2
   BFE0.fc00  2e40.fc00  ' AdvSIMD-bfdot    ,,,

   BFC0.f400  0f40.f000  ' AdvSIMD-bfdot-ele  ,,,  \ need to mask out 21 20 and 11

   5F20.7C00  1E20.4000  ' FP-data-proc-1           ,,, \ Floating-point data-processing (1 source)
   5F20.0C00  1E20.0000  ' FP<>int-cvt              ,,, \ Floating-point<->integer conversions
   5F20.0000  1E00.0000  ' FP<>FixedPt-cvt          ,,, \ Floating-point<->fixed point conversions
   5F20.0C00  1E20.0800  ' FP-data-proc-2           ,,, \ Floating-point data-processing (2 source)
   5F00.0000  1F00.0000  ' FP-data-proc-3           ,,, \ Floating-point data-processing (3 source)

   BF20.C400  2E00.C400  ' AdvSIMD-3same-complex    ,,, \ AdvSIMD three same, complex
   9F20.C400  0E20.C400  ' AdvSIMD-3same-floats     ,,, \ AdvSIMD three same, floats
   9F60.C400  0E40.0400  ' AdvSIMD-3same-floats-hp  ,,, \ AdvSIMD three same, floats half-precision
   9F20.0400  0E20.0400  ' AdvSIMD-3same-ints       ,,, \ AdvSIMD three same, integers
   9F20.0C00  0E20.0000  ' AdvSIMD-3diff            ,,, \ AdvSIMD three different
   9F00.F400  0F00.E000  ' AdvSIMD-dotelem          ,,,
   9F20.FC00  0E00.9400  ' AdvSIMD-dot              ,,,
   9F3E.0C00  0E20.0800  ' AdvSIMD-2reg-misc        ,,, \ AdvSIMD two-reg misc
   9F3E.0C00  0E38.0800  ' AdvSIMD-2reg-misc        ,,, \ AdvSIMD two-reg misc half-precision
   9F3E.0C00  0E30.0800  ' AdvSIMD-across-lanes     ,,, \ AdvSIMD across lanes
   9FE0.8400  0E00.0400  ' AdvSIMD-copy             ,,, \ AdvSIMD copy
   9F00.0400  0F00.0000  ' AdvSIMD-X-index-element  ,,, \ AdvSIMD vector x indexed element
   9FF8.0400  0F00.0400  ' AdvSIMD-mod-imm          ,,, \ AdvSIMD modified immediate
   9F80.0400  0F00.0400  ' AdvSIMD-shift-imm        ,,, \ AdvSIMD shift by immediate
   BE40.9000  0E00.9000  ' AdvSIMD-usdot            ,,,

   BF20.8C00  0E00.0000  ' AdvSIMD-TBL/TBX          ,,, \ AdvSIMD TBL/TBX
   BF20.8C00  0E00.0800  ' AdvSIMD-ZIP/UZP/TRN      ,,, \ AdvSIMD ZIP/UZP/TRN
   BF20.8400  2E00.0000  ' AdvSIMD-EXT              ,,, \ AdvSIMD EXT

   DF20.0400  5E20.0400  ' AdvSIMD-Scalar-3same     ,,, \ AdvSIMD scalar three same
   DF20.0C00  5E20.0000  ' AdvSIMD-Scalar-3diff     ,,, \ AdvSIMD scalar three different
   DF3E.0C00  5E20.0800  ' AdvSIMD-Scalar-2reg-misc ,,, \ AdvSIMD scalar two-reg misc
   DF3E.0C00  5E30.0800  ' AdvSIMD-scalar-pairwise  ,,, \ AdvSIMD scalar pairwise

   DFE0.8400  5E00.0400  ' AdvSIMD-scalar-copy      ,,, \ AdvSIMD scalar copy
   DF00.0400  5F00.0000  ' AdvSIMD-scalar-index-elem ,,, \ AdvSIMD scalar x indexed element
   DF80.0400  5F00.0400  ' AdvSIMD-scalar-shift-imm ,,, \ AdvSIMD scalar shift by immediate

   FF20.8C00  5E00.0000  ' Crypto-3SHA              ,,, \ Crypto 3 register SHA
   FF3E.0C00  5E28.0800  ' Crypto-2SHA              ,,, \ Crypto 2 register SHA
   FF3E.0C00  4E28.0800  ' Crypto-AES               ,,, \ Crypto AES
   DFE0.F400  4E80.A400  ' AdvSIMD-mmla             ,,,
   FF80.8000  CE00.0000  ' Crypto-4reg              ,,, \ Crypto 4 register

   FFFF.FFFF  efedc0de   ' .End-Codetag             ,,, \ end of code marker
   0 ,

create sme-table
   ffe0.0000  8180.0000  ' SME-bfmop           ,,,
   f080.0000  8080.0000  ' SME-fmop            ,,,
   f080.0000  a080.0000  ' SME-mop             ,,,
   e000.0000  c000.0000  ' SME-mov             ,,,
   fe00.0000  e000.0000  ' SME-ldst            ,,,
   0 ,

create sve-table
   ff20.e000  0400.0000  ' sve-int-mathp      ,,,
   ff20.e000  0400.2000  ' sve-int-reduce     ,,,
   ff20.4000  0400.4000  ' sve-madp           ,,,
   ff20.e000  0400.8000  ' sve-shiftp         ,,,
   ff20.e000  0400.a000  ' sve-unaryp         ,,,
   ff20.e000  0420.0000  ' sve-vec-add        ,,,
   ff20.e000  0420.2000  ' sve-bit-logic      ,,,
   ff20.f000  0420.4000  ' sve-index-gen      ,,,
   ff20.f000  0420.5000  ' sve-stack          ,,,
   ff20.e000  0420.6000  ' sve2-int-mul       ,,,
   ff20.e000  0420.8000  ' sve-shift          ,,,
   ff20.f000  0420.a000  ' sve-adr            ,,,
   ff20.f000  0420.b000  ' sve-int-misc       ,,,
   ff20.c000  0420.c000  ' sve-elem-cnt       ,,,
   ff30.0000  0500.0000  ' sve-bit-imm        ,,,
   ff30.0000  0510.0000  ' sve-int-wide-immp  ,,,
   ffa0.e000  0520.0000  ' sve-perm-ext       ,,,
   ff20.fc00  0520.2000  ' sve-dup-ind        ,,,
   ff20.f800  0520.2800  ' sve-tbl3           ,,,
   ff20.fc00  0520.3000  ' sve-tbl            ,,,
   ff20.fc00  0520.3800  ' sve-perm-vec       ,,,
   ff20.e000  0520.4000  ' sve-perm-pred      ,,,
   ff20.e000  0520.6000  ' sve-perm-vec-elem  ,,,
   ff20.c000  0520.8000  ' sve-perm-vec-pred  ,,,
   ff20.c000  0520.c000  ' sve-sel             ,,,
   ffa0.e000  05a0.0000  ' sve-perm-vec-seg   ,,,
   ff20.0000  2400.0000  ' sve-int-cmp        ,,,
   ff20.0000  2420.0000  ' sve-cmp-uimm       ,,,
   ff20.4000  2500.0000  ' sve-cmp-simm       ,,,
   ff30.c000  2500.4000  ' sve-pred-logic     ,,,
   ff30.c000  2500.c000  ' sve-prop-break     ,,,
   ff30.c000  2510.4000  ' sve-part-break     ,,,
   ff30.c000  2510.c000  ' sve-pred-misc      ,,,
   ff20.c000  2520.0000  ' sve-cmp-scalar     ,,,
   ff20.c210  2520.4000  ' sve-dup-pred       ,,,
   ff20.c010  2520.4010  ' sve-cmp-pred-ctr   ,,,
   ff38.c000  2520.8000  ' sve-cntp           ,,,
   ff20.c000  2520.c000  ' sve-int-imm        ,,,
   ff38.f000  2528.8000  ' sve-pred-cnt       ,,,
\   ff38.f000  2528.9000  ' sve-wr-ffr          ,,,
   ff20.8000  4400.0000  ' sve-int-mad        ,,,
   ff20.c000  4400.8000  ' sve2-intp          ,,,
   ff20.c000  4400.c000  ' sve-clamp          ,,,
   ff20.0000  4420.0000  ' sve-mul-ind        ,,,
\   ff20.8000  4500.0000  ' sve-wide-int        ,,,
   ff20.c000  4500.8000  ' sve-misc           ,,,
   ff20.c000  4500.c000  ' sve-acc            ,,,
\   ff20.8000  4520.0000  ' sve-narrow          ,,,
   ff20.e000  4520.8000  ' sve-match          ,,,
   ff20.e000  4520.a000  ' sve-histseg        ,,,
   ff20.e000  4520.c000  ' sve-histcnt        ,,,
   ff20.e000  4520.e000  ' sve-crypto         ,,,
   ff20.8000  6400.0000  ' sve-fcmla          ,,,
   ff3e.e000  6400.8000  ' sve-fcadd          ,,,
   ff3c.e000  6408.a000  ' sve-fp-cvt         ,,,
   ff38.e000  6410.8000  ' sve-fp-mathp-pair  ,,,
   ff20.f800  6420.0000  ' sve-fp-mad-ind     ,,,
   ff20.f000  6420.1000  ' sve-fp-cmad-ind    ,,,
   ff20.fc00  6420.2000  ' sve-fp-mul-ind     ,,,
   ff20.fc00  6420.2400  ' sve-fp-clamp       ,,,
   ff20.d000  6420.4000  ' sve-fp-wmad-ind    ,,,
   ff20.d800  6420.8000  ' sve-fp-wmad        ,,,
   ff20.fc00  6420.e400  ' sve-fp-mma         ,,,
   ff20.e000  6500.0000  ' sve-fp-math        ,,,
   ff38.e000  6500.2000  ' sve-fp-rec-red     ,,,
   ff20.4000  6500.4000  ' sve-fp-cmp-vec     ,,,
   ff20.e000  6500.8000  ' sve-fp-mathp       ,,,
   ff20.e000  6500.a000  ' sve-fp-unaryp      ,,,           \ fcvt/zs/zu, frecpx, frintx
   ff38.fc00  6508.3000  ' sve-fp-rec-est     ,,,
   ff3c.e000  6510.2000  ' sve-fp-cmp0        ,,,
   ff3f.e000  6518.2000  ' sve-fadda          ,,,
   ff20.0000  6520.0000  ' sve-fp-mad         ,,,
   fe00.0000  8400.0000  ' sve-gather32       ,,,
   fe00.0000  a400.0000  ' sve-contig-ld      ,,,
   fe00.0000  c400.0000  ' sve-gather64       ,,,

   fe00.a000  e400.0000  ' sve-contig-st-uc   ,,,
   fe00.a000  e400.2000  ' sve-nt-mr-st       ,,,
   fe00.e000  e400.6000  ' sve-contig-st-imm  ,,,
   fe00.a000  e400.8000  ' sve-scatter-se     ,,,
\   fe40.a000  e400.a000  ' sve-scatter-se     ,,, \ XXX bogus?
   fe00.a000  e400.a000  ' sve-scatter        ,,,
   fe00.e000  e400.e000  ' sve-contig-st-imm  ,,,
   0 ,

: (decode)    ( table -- )
   begin
      dup l@ instruction@ and over 1 la+ l@ = if
	 2 la+ token@ execute exit
	 \ 2 la+ token@ dup .name execute exit
      then
      3 la+ dup l@ 0=
   until  drop
   illegal
   end-found on
;
: br-sys  ( -- )   brsys-table (decode)  ;
: dp      ( -- )   dp-table    (decode)  ;
: ldst    ( -- )   ldst-table  (decode)  ;
: SIMD    ( -- )   simd-table  (decode)  ;
: SME     ( -- )   sme-table   (decode)  ;
: SVE     ( -- )   sve-table   (decode)  ;


\ main categories
create decode-table
   9E00.0000  8000.0000  ' sme               ,,, \ mop add
   1E00.0000  0400.0000  ' sve               ,,, \ 
   1C00.0000  1000.0000  ' dp                ,,, \ 
   1C00.0000  1400.0000  ' br-sys            ,,, \ br exc sys
   0E00.0000  0A00.0000  ' dp                ,,, \ 
   0E00.0000  0E00.0000  ' simd              ,,, \ 
   0A00.0000  0800.0000  ' ldst              ,,, \ 
   FFFF.FFFF  efedc0de   ' .End-Codetag      ,,, \ end of code marker
   0 ,

decimal

defer decode-extension
' false is decode-extension

0 [if] \ debug
0 value ddepth
: decode ( addr opcode -- )
   instruction !  instr-addr  !
   depth to ddepth
   #out @ start-column !
   decode-table
   begin
      dup l@ instruction@ and over 1 la+ l@ = if
	 2 la+ token@ execute
	 depth ddepth <> abort" stack changed "
	 exit
      then
      3 la+ dup l@ 0=
   until  drop
   decode-extension ?exit
   illegal
   end-found on
;
[else]
: decode ( addr opcode -- )
   instruction !  instr-addr  !
   #out @ start-column !
   decode-table
   begin
      dup l@ instruction@ and over 1 la+ l@ = if
	 2 la+ token@ execute exit
      then
      3 la+ dup l@ 0=
   until  drop
   decode-extension ?exit
   illegal
   end-found on
;
[then]



\ create use-redirect-output       \ uncoment this for assembler testing
[ifdef] use-redirect-output

\ =======================================
\
\          OUTPUT REDIRECTION
\
\ =======================================

\
\ Redirect output to a private buffer.  We use this at least initially
\ to test the assembler/disassembler.  In theory, any instruction assembled
\ when disassembled and then assembled will generate the same binary code as
\ the original assembly.  If not, then there's bug (or a corner case).
\

256 constant dis64-bfr#
create dis64-out-buffer  dis64-bfr# allot

0 value dis64-save-(type
0 value dis64-save-(emit
0 value dis64-save-#out
0 value dis64-emit-i

: dis-emit ( c -- )
   dis64-emit-i dis64-bfr# < if
      dis64-emit-i dis64-out-buffer + c!
      dis64-emit-i 1+ is dis64-emit-i
   else
      drop
   then
;

: dis-type ( adr len -- )
   bounds ?do  i c@ dis-emit   loop
;

\ begin redirecting output
: <bfr  ( -- )
   dis64-out-buffer dis64-bfr# [char] * fill  \ make errors apparent
   #out @ is dis64-save-#out
   0 is dis64-emit-i
   ['] (type behavior is dis64-save-(type
   ['] (emit behavior is dis64-save-(emit
   ['] dis-type is (type
   ['] dis-emit is (emit
;

\ stop redirecting output, and return the resulting string
: bfr> ( -- adr,len )
   dis64-save-(type  is (type
   dis64-save-(emit  is (emit
   dis64-save-#out   #out !
   dis64-out-buffer dis64-emit-i  ( adr len )
;
[else]  \ do nothing (at compile time)
: <bfr  ( -- )  ; immediate
: bfr>  ( -- )  ; immediate
[then]
      
: emit-address  ( address opcode -- address opcode )
   over showaddr ." : "  dup udis.32  ."   "
;

: (disasm)  ( addr opcode -- )
   push-hex  decode  pop-base
;


: disasm  ( addr opcode -- $ )
   <bfr
   ['] (disasm) catch if   2drop  ."       \ Error decoding this instruction"  then
   bfr>
;


\ =======================================
\
\               USER VISIBLE INTERFACE
\
\ =======================================

also forth definitions previous

[ifdef] use-redirect-output    \ Debug WIP
\ disassemble an opcode into a string, then assemble it and compare to original
: asmtest?  ( opcode -- err? )
   here off    here over disasm    ( opcode $ )
   over c@ ascii , = if   1 /string   then   ( opcode $ )
   (asm$) if  drop 1 exit  then
   here l@ 0= if   2drop 1 exit  then
   <>
;
: asmtest0 ( opcode -- )
   asmtest? dup 1 = if  drop ." illegal "  exit  then  ( err? )
   if  ." mismatch "  then
;
: asmtest1  ( opcode -- err? )
   hex
   here off    here over disasm    ( opcode $ )
   over c@ ascii , = if   1 /string   then   ( opcode $ )
   (asm$) if  8 0.r ."  illegal " cr  exit  then   ( opcode instr )
   \ here l@ 0= if   drop  8 0.r ."  illegal " cr  exit  then  ( opcode instr )
   dup 0= if   drop  8 0.r ."  illegal " cr  exit  then  ( opcode instr )
   2dup <>  if  9 0.r 9 0.r   ."  mismatch "  else  2drop  then
;
: atest1   ( a -- )   0x40 bounds do  i l@ asmtest1  4 +loop  ;
: 0.r_   ( n -- )   8 0.r  4 spaces  ;
: asmtest2  ( opcode -- )
   hex
   here over disasm    ( opcode $ )
   over c@ ascii , = if
      2drop  0.r_ ." no dis " cr  exit  
   then   ( opcode $ )
   (asm$) over 0= or if   2drop  0.r_ ." no asm " cr  exit  then   ( opcode instr )
   2dup <>  if   swap  0.r_ 0.r_  ." mismatch "  else  2drop  then
;
: atest2   ( a -- )   0x40 bounds do  i l@ asmtest2  4 +loop  ;
[then]

: (dis-opcode)  ( address opcode -- )
   emit-address  (disasm)
;

: dis-opcode  ( address opcode -- $ )
   <bfr
   ['] (dis-opcode) catch if   2drop  ."       \ Error decoding this instruction"  then
   bfr>
;

: dis1  ( -- )
   dis-pc@ +offset pc@l@
   ??cr (dis-opcode) cr
   /l dis-pc@ + dis-pc!
;
: +dis  ( -- )
   end-found off
   begin   dis1  end-found @  exit? or  until
;
: dis  ( adr -- )  dis-pc! +dis  ;
: dis-n ( adr n -- ) swap dis-pc! 0 do dis1 loop ;

: xdis  ( adr -- )  
   dis-pc!  begin  dis1  exit? until
;


also assembler
   ' (dis-opcode) is .dis-asm
previous

only forth also definitions
