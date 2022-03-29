\ Disassembler
\ SIMD instructions

: regz    ( -- sz )   op-col  d# 22 1bit  ;
: regsz   ( -- sz )   op-col  d# 22 2bits  ;
: regszq  ( -- szq )  op-col  d# 22 2bits 2* d# 30 1bit or  ;
: regq    ( -- q )    op-col  d# 30 1bit ;

\ =======================================
\ SIMD-LDST-Multiple
\ =======================================

\ simple byte indexed structure for LDST multiple size suffix
\ LD(1|2|3|4)
\ 255 = error
create ldstnum[]
4   c,  \ 0
255 c,
1   c,  \ 2
255 c,

3   c,  \ 4
255 c,
1   c,  \ 6
1   c,  \ 7
2   c,  \ 8

255 c,
1   c,  \ 0xa
255 c,
255 c,

255 c,
255 c,
255 c,
255 c,

: .SIMD-LDST-Mult-Mnemonic
    22 1bit IF ." ld" ELSE ." st" THEN
    12 4bits ldstnum[] + c@ .d 
    ;
 
: .reg-szq-suffix   ( szq -- )
    case
        b# 000 of  ." 8b"  endof
        b# 001 of  ." 16b" endof
        b# 010 of  ." 4h"  endof
        b# 011 of  ." 8h"  endof
        b# 100 of  ." 2s"  endof
        b# 101 of  ." 4s"  endof
        b# 111 of  ." 2d"  endof
        ." ??"
        \ invalid-op ." .reg-szq-suffix"
    endcase
    ;
    
\ returns szq bits for decode of reg type/size    
: LDSTMult-szq ( -- size[12:11]:Q[30] ) 30 1 bits 10 2 bits 1 << or ;

\ ***this is only valid for ld2,3,4
: LDST-Mult-#Regs
    instruction@ d# 12 >> 0xf and
    case
        0 of 4 endof
        2 of 1 endof
        4 of 3 endof
        6 of 1 endof
        7 of 1 endof
        8 of 2 endof
        10 of 1 endof 
        0 invalid-op ." LDST-Mult-#Regs"
    endcase
    ;

: .{Vreglist} ( szq  startreg# #regs  )
    .{ 
    bounds 
    ?do
        ( szq )   
        i 0x1f and              \ reg wraps
        Vreg .r#                \ always vector format Vn
        emit.                   \ Vn.
        dup .reg-szq-suffix     \ Vn.Sz
        .,                      \ Vn.Sz,
    loop
    drop
    bs emit \ remove the last ,
    bs emit 
    ." }, "
    ;


 
 
 
: SIMD-LDST1-Multiple   
    LDSTMult-szq rT
    12 4 bits \ opcode
    case
        b# 0111 of 1 endof
        b# 1010 of 2 endof
        b# 0110 of 3 endof
        b# 0010 of 4 endof
        invalid-op ." SIMD-LDST1-Multiple " 0
    endcase
    .{Vreglist}
    d# 23 1bit 0=                   \ no offset
    IF
        .[xn|sp .] 
    ELSE
        \ if   Rm  = 'b11111 [<Xn|SP>], <imm> 
        \ else Rm != 'b11111 [<Xn|SP>], <Xm>

        Rm b# 11111 <>
        IF                          \ reg offset
            .[xn|sp .] ., .xm       \ display reg# 
        ELSE                        \ imm offset
            .[xn|sp ." ], #"
                                    \ decode implicit immediate offset
            12 4 bits               \ opcode
            case
                b# 0111 of 30 1bit if 16 else 8  then endof
                b# 1010 of 30 1bit if 32 else 16 then endof
                b# 0110 of 30 1bit if 48 else 24 then endof
                b# 0010 of 30 1bit if 64 else 32 then endof
                invalid-op ." SIMD-LDST1-Multiple " 0
           endcase
           .d
        THEN
    THEN
    ;

: SIMD-LDST234-Multiple   
    LDSTMult-szq rt LDST-Mult-#Regs 
    ( szq  startreg# #regs  ) 
    .{Vreglist}
    \ if   Rm  = 'b11111 [<Xn|SP>], <imm> <imm>=Q=0=32 or Q=1=64
    \ else Rm != 'b11111 [<Xn|SP>], <Xm>
    Rm 0=
    IF                          
        23 1bit 0=
        IF                      \ no offset
            .[xn|sp .] exit
        THEN
    THEN

    Rm b# 11111 <>
    IF                          \ reg offset
        .[xn|sp .] ., .xm  
    ELSE                        \ imm offset
        .[xn|sp ." ], #"
        12 4bits
        case
            0 of 30 1bit IF 64 ELSE 32 THEN .d endof \ ld4
            4 of 30 1bit IF 48 ELSE 24 THEN .d endof \ ld3
            8 of 30 1bit IF 32 ELSE 16 THEN .d endof \ ld2
            invalid-op ." SIMD-LDST234-Multiple " 
        endcase
    THEN
    ;
 

: SIMD-LDST-Multiple-UnAllocated?   ( -- T|F )
    instruction@ d# 12 >> 0xf and
    dup 0xc and 0xc = if drop true exit then

    case
        b# 0001 of true  endof
        b# 0011 of true  endof
        b# 0101 of true  endof
        b# 1001 of true  endof
        b# 1011 of true  endof
        false swap
    endcase
    ;


: SIMD-LDST-Multiple  
    SIMD-LDST-Multiple-UnAllocated? if invalid-op exit then 
    .SIMD-LDST-Mult-Mnemonic op-col \ mnemonic
    13 1bit                     \ opcode bit13 set?
    IF  
        SIMD-LDST1-Multiple     \ Ld1 list is qualified different
    ELSE
        SIMD-LDST234-Multiple
    THEN   
    ;



\ ---------------------------------------------------
\ END SIMD-LDST-Multiple 
\ ---------------------------------------------------

    
: .LDST-Sgl-[Rn] .[ Rn xreg .r# .] ;   
: (.LDST-Offset) ( Imm -- )
    Rm 31 =
    IF      \ imm
        ." #" .d
    ELSE    \ Rm
        drop Rm xreg .r#      
    THEN
    ;

\ R[21]:OP[15:13]    

: .ldstNSgl ( R:Opcode )
    case
        b# 0000 of 1 endof
        b# 0001 of 3 endof
        b# 0010 of 1 endof
        b# 0011 of 3 endof
        b# 0100 of 1 endof
        b# 0101 of 3 endof
        b# 1000 of 2 endof
        b# 1001 of 4 endof
        b# 1010 of 2 endof
        b# 1011 of 4 endof
        b# 1100 of 2 endof
        b# 1101 of 4 endof
        0
    endcase
    .d
    ;
    

\ Structure Siz    
\ Byte Half Single Double
0 value LDST-Siz



: Get-LDST1-Siz   ( -- sz )
    13 3 bits ?dup 0= 
    IF 
        1 
    ELSE
        ( construct a 4 bit decode [15:13]:10 )
        ( 15:13 )       \ opcode 3:1
        1 <<
        10 1 bits or    \ size<0>
        case
            b# 010.0 of 2 endof
            b# 100.0 of 4 endof
            b# 100.1 of 8 endof
            invalid-op ."  Get-LDST1-Siz " 0
        endcase
    THEN
    dup to LDST-Siz \ save it
    ;

: .LDST-BHSD   ( width -- )
    case
        1 of ." B" endof
        2 of ." H" endof
        4 of ." S" endof
        8 of ." D" endof
        invalid-op dup . ." .LDST1-BHSD" 
    endcase
    ;

: .LDST1-BHSD  .LDST-BHSD ;



\ common for Single permutations
: .{VregListBHSD} ( width startreg# #regs  )
    .{ 
    bounds 
    ?do
        ( width )   
        i 0x1f and      \ reg wraps
        Vreg .r#        \ always vector format Vn
        emit.           \ Vn.
        dup 
        .LDST1-BHSD \ Vn.Sz
        .,              \ Vn.Sz,
    loop
    drop
    bs emit             \ remove the last ,
    bs emit 
    .}
    ;


\ form: ld1	{V0.B}[0], [x0], #1




: .LDST1-Sgl-{Vx.Siz} .{ Rt Vreg .r# emit. Get-LDST1-Siz .LDST1-BHSD ." }" ;

\ ============== LDST1 =====================
  

\ index = UInt(Q:S:size); B[0-15]
: .LDST1-Sgl-B[ndx]
    .[      
    10 2 bits       \ Sz
    12 1bit 2 << or \ S
    30 1bit 3 << or \ Q
    u. 
    .] 
    ;
         
\ index = UInt(Q:S:size<1>); // H[0-7]
: .LDST1-Sgl-H[ndx]
    .[      
    11 1bit         \ size<1>
    12 1bit 1 << or \ S
    30 1bit 2 << or \ Q 
    u. 
    .] 
    ;

\ index = UInt(Q:S); // S[0-3]
: .LDST1-Sgl-S[ndx]
    .[      
    12 1bit         \ S
    30 1bit 1 << or \ Q 
    u. 
    .] 
    ;


\ index = UInt(Q); // Q[0-1]
: .LDST1-Sgl-D[ndx] .[ 30 1bit u. .] ; \ Q 

: .LDST-Siz->BHSD ( -- imm )
    LDST-Siz
    case
        1 of .LDST1-Sgl-B[ndx] 1 endof
        2 of .LDST1-Sgl-H[ndx] 2 endof
        4 of .LDST1-Sgl-S[ndx] 4 endof
        8 of .LDST1-Sgl-D[ndx] 8 endof
        \ ." .LDST-Siz->BHSD error force to 1" 1 swap
        0 swap
    endcase
    ;
    

: LDSTn-Sgl-Cmn ( #regs )
   .LDST-Siz->BHSD ?dup 0= if invalid-op exit then
   ( #regs imm )
   .,
   .LDST-Sgl-[Rn]
   23 1bit if   ( #regs imm ) 
      ., * (.LDST-Offset)
   else
      2drop
   then
;


: LDST1-Sgl 
    .LDST1-Sgl-{Vx.Siz}
    .LDST-Siz->BHSD ?dup 0= if invalid-op exit then
    ( imm )
    .,
    .LDST-Sgl-[Rn] 
    23 1bit 0= IF DROP EXIT THEN \ NO OFFSET
    
    .,    
    ( imm ) (.LDST-Offset)
    ;
    

\ ============== LDST2 =====================



: Get-LDST2-Siz   ( -- sz )
    13 3 bits ?dup 0= 
    IF 
        1 
    ELSE
        ( construct a 4 bit decode [15:13]:10 )
        ( 15:13 )       \ opcode 3:1
        2 <<
        10 2 bits or    \ size<0>
        case
            b# 010.00 of 2 endof
            b# 100.00 of 4 endof
            b# 100.01 of 8 endof
            invalid-op ."  Get-LDST2-Siz " 0 swap
        endcase
    THEN
    dup to LDST-Siz \ save it
    ;





: LDST2-Sgl
    Get-LDST2-Siz ?dup 0= if invalid-op exit then
    Rt 2 .{VregListBHSD} 
    2 LDSTn-Sgl-Cmn
    ;

\ ============== LDST3 =====================

: Get-LDST3-Siz   ( -- sz )
    13 3 bits dup b# 001 = 
    IF 
        drop 1 
    ELSE
        ( construct a 4 bit decode [15:13]:10 )
        ( 15:13 )       \ opcode 3:1
        3 <<
        10 3 bits or    \ opcode[3:1]:Scale[12]:size[1:0]
        case
            \ Qualify H
            b# 011.0.00 of 2 endof  \ S and SIZE<1> =Don't care
            b# 011.0.10 of 2 endof
            b# 011.1.00 of 2 endof
            b# 011.1.10 of 2 endof

            \ Qualify S
            b# 101.0.00 of 4 endof  \ S =Don't care
            b# 101.1.00 of 4 endof
            
            \ Qualify D
            b# 101.0.01 of 8 endof
            \ invalid-op ."  Get-LDST3-Siz " 
            0 swap
        endcase
    THEN
    dup to LDST-Siz \ save it
    ;


: LDST3-Sgl
    Get-LDST3-Siz ?dup 0= if invalid-op exit then
    Rt 3 .{VregListBHSD} 
    3 LDSTn-Sgl-Cmn
    ;

\ ============== LDST4 =====================

: Get-LDST4-Siz  Get-LDST3-Siz ;
: LDST4-Sgl 
    Get-LDST4-Siz ?dup 0= if invalid-op exit then 
    Rt 4 .{VregListBHSD} 
    4 LDSTn-Sgl-Cmn
    ;




\ ============== LD/STnR sgl elem replicate =====================

: SIMD-LDnRSTnR 
    22 1bit IF ." ld" ELSE ." st" THEN
    21 1bit 3 <<
    13 3 bits or
    ( R:Opcode )
    case
        b# 0.110 of ." 1r" 1 endof
        b# 1.110 of ." 2r" 2 endof
        b# 0.111 of ." 3r" 3 endof
        b# 1.111 of ." 4r" 4 endof
        invalid-op ." SIMD-LDnRSTnR" 
    endcase
    ( #regs ) >r
    op-col
    .{ 
    \ ----- reg  list ---------
    
    rT r@ 
    ( startreg #regs )
    bounds
    DO
    
        i 0x1f and Vreg .r# emit.  
        LDSTMult-szq   ( szq )
        case
            b# 000 of ." 8B"  endof
            b# 001 of ." 16B" endof
            b# 010 of ." 4H"  endof
            b# 011 of ." 8H"  endof
            b# 100 of ." 2S"  endof
            b# 101 of ." 4S"  endof
            b# 110 of ." 1D"  endof
            b# 111 of ." 2D"  endof
            invalid-op dup . ." SIMD-LDnRSTnR  LDSTMult-szq "
        endcase
        .,
    LOOP
    bs emit bs emit   
    .} .,   

    .LDST-Sgl-[Rn] .,
    LDSTMult-szq  ( szq -- )
    case
        b# 000 of 1 endof \ 8b
        b# 001 of 1 endof \ 16b
        b# 010 of 2 endof \ 4h    
        b# 011 of 2 endof \ 8h
        b# 100 of 4 endof \ 2s
        b# 101 of 4 endof \ 4s
        b# 110 of 8 endof \ 1d
        b# 111 of 8 endof \ 2d
        invalid-op dup . ." SIMD-LDnRSTnR" 0
    endcase
    ( size ) r> ( size #regs ) *
    (.LDST-Offset)
    ;
    


: SIMD-LDST-SINGLE 
    14 2bits b# 11 = IF SIMD-LDnRSTnR exit then
   
    22 1bit IF ." ld" ELSE ." st" THEN

    13 3bits
    21 1bit 3 << or
    ( R:Opcode )
    DUP
    .ldstNSgl  op-col \ "ldX" | "stX"
    ( R:Opcode )
    
     case
        b# 0000 of LDST1-Sgl endof
        b# 0001 of LDST3-Sgl endof
        b# 0010 of LDST1-Sgl endof
        b# 0011 of LDST3-Sgl endof
        b# 0100 of LDST1-Sgl endof
        b# 0101 of LDST3-Sgl endof
        b# 1000 of LDST2-Sgl endof
        b# 1001 of LDST4-Sgl endof
        b# 1010 of LDST2-Sgl endof
        b# 1011 of LDST4-Sgl endof
        b# 1100 of LDST2-Sgl endof
        b# 1101 of LDST4-Sgl endof
        invalid-op ." SIMD-LDST-Sgl" 
    endcase
   
    ;
 

\ =======================================
\
\            AdvSIMD-3same
\
\ =======================================


\ need to separate this into fpu and ints
: .AdvSIMD-3same-regs
   op-col  
   instruction@ d# 22 >> 1 and ( size<0> )
   instruction@ d# 29 >> 2 and ( size<0> Q )
   or
   CASE
      b# 00 of .Vd.2s, .Vn.2s, .Vm.2s endof
      b# 10 of .Vd.4s, .Vn.4s, .Vm.4s endof
      b# 11 of .Vd.2d, .Vn.2d, .Vm.2d endof
      ." .AdvSIMD-3same-regs ???" \ exit
   ENDCASE
;

: .AdvSIMD-3same-regs-hp
   op-col
   instruction@ d# 30 >> 1 and ( Q )
   CASE
      0 of .Vd.4h, .Vn.4h, .Vm.4h endof
      1 of .Vd.8h, .Vn.8h, .Vm.8h endof
   ENDCASE
;

\ int regs
: .AdvSIMD-int-3same-regs
   op-col
   instruction@ d# 22 >> 3 and 1 << ( size<0:1> )
   instruction@ d# 30 >> 1 and ( size<0> Q )
   or
   ( sz:10:Q )
   CASE
      b# 000 of .Vd.8b,  .Vn.8b,  .Vm.8b endof
      b# 001 of .Vd.16b, .Vn.16b, .Vm.16b endof
      b# 010 of .Vd.4h,  .Vn.4h,  .Vm.4h endof
      b# 011 of .Vd.8h,  .Vn.8h,  .Vm.8h endof
      b# 100 of .Vd.2s,  .Vn.2s,  .Vm.2s endof
      b# 101 of .Vd.4s,  .Vn.4s,  .Vm.4s endof
      b# 111 of .Vd.2d,  .Vn.2d,  .Vm.2d endof
      ." .AdvSIMD-int-3same-regs ???" \ exit
   ENDCASE
;

\ separate integer from fpu vectors
\ because reg mnemonic/types are different
:  AdvSIMD-3same-ints   ( -- )
   instruction@ h# 0000f800 and h# 00001800 = if   \ 8b or 16b only
      instruction@ d# 20 >> 0x20e and
      case
	 0x002 of ." and"   endof
	 0x006 of ." bic"   endof
	 0x00a of ." orr"   endof
	 0x00e of ." orn"   endof
	 0x202 of ." eor"   endof
	 0x206 of ." bsl"   endof
	 0x20a of ." bit"   endof
	 0x20e of ." bif"   endof
      endcase
      op-col
      30 bit? if
	 .Vd.16b, .Vn.16b, .Vm.16b
      else
	 .Vd.8b,  .Vn.8b,  .Vm.8b
      then
      exit
   then
   
   instruction@ h# 20000000 and 0= \ u=0
   IF
      instruction@ 11 >> h# 1f and
      case
            b# 00000 of ." shadd"   endof
            b# 00001 of ." sqadd"   endof
            b# 00010 of ." srhadd"  endof
            b# 00100 of ." shsub"   endof
            b# 00101 of ." sqsub"   endof
            b# 00110 of ." cmgt"    endof
            b# 00111 of ." cmge"    endof
            b# 01000 of ." sshl"    endof
            b# 01001 of ." sqshl"   endof
            b# 01010 of ." srshl"   endof
            b# 01011 of ." sqrshl"  endof
            b# 01100 of ." smax"    endof
            b# 01101 of ." smin"    endof
            b# 01110 of ." sabd"    endof
            b# 01111 of ." saba"    endof
            b# 10000 of ." add"     endof
            b# 10001 of ." cmtst"   endof
            b# 10010 of ." mla"     endof
            b# 10011 of ." mul"     endof
            b# 10100 of ." smaxp"   endof
            b# 10101 of ." sminp"   endof
            b# 10110 of ." sqdmulh" endof
            b# 10111 of ." addp"    endof
        endcase
        .AdvSIMD-int-3same-regs
        exit
    THEN

    instruction@ h# 20000000 and h# 20000000 = \ u=1 
    IF
        instruction@ h# 2080f800 and 11 >> h# 1f and
        case
            b# 00000 of ." uhadd"       endof
            b# 00001 of ." uqadd"       endof
            b# 00010 of ." urhadd"      endof
            b# 00100 of ." uhsub"       endof
            b# 00101 of ." uqsub"       endof
            b# 00110 of ." cmhi"        endof
            b# 00111 of ." cmhs"        endof
            b# 01000 of ." ushl"        endof
            b# 01001 of ." uqshl"       endof
            b# 01010 of ." urshl"       endof
            b# 01011 of ." uqrshl"      endof
            b# 01100 of ." umax"        endof
            b# 01101 of ." umin"        endof
            b# 01110 of ." uabd"        endof
            b# 01111 of ." uaba"        endof
            b# 10000 of ." sub"         endof
            b# 10001 of ." cmeq"        endof
            b# 10010 of ." mls"         endof
            b# 10011 of ." pmul"        endof
            b# 10100 of ." umaxp"       endof
            b# 10101 of ." uminp"       endof
            b# 10110 of ." sqrdmulh"    endof
            b# 10111 of ." UNALLOCATED" endof
            unimpl ." AdvSIMD-int-3same " drop exit
        endcase
        .AdvSIMD-int-3same-regs
        exit
    THEN
    unimpl
;


: AdvSIMD-bfdot   ( -- )
    ." bfdot"  op-col
    30 bit? \ Q=1  4s 8h
    IF
        .Vd.4s, .Vn.8h, .Vm.8h  
    ELSE \ Q=0 2s 4h 
        .Vd.2s, .Vn.4h, .Vm.4h 
    then
 ;

\ BFDOT <Vd>.<Ta>, <Vn>.<Tb>, <Vm>.2H[<index>]
: AdvSIMD-bfdot-ele   ( -- )
    ." bfdot"  op-col
    30 bit? \ Q=1  4s 8h
    IF   \ 4s 8h
         .Vd.4s, .Vn.8h, .Vm.2h 
    ELSE  \ 2s 4h
         .Vd.2s, .Vn.4h, .Vm.2h 
    THEN
     .[
     instruction@ d# 21 >> 1 and \ L
     instruction@ d# 10 >> 2 and \ H
     OR 
     ( index )
     u. .]          
    ;
    











: AdvSIMD-bfmmla   ( -- ) ." bfmmla"  op-col .Vd.4s, .Vn.8h, .Vm.8h ;


\ there are several permutes to this op
: AdvSIMD-bfmlalbt   ( -- ) d# 30 bit? IF ." bfmlalt" ELSE ." bfmlalb" THEN op-col .Vd.4s, .Vn.8h, .Vm.8h ;
: AdvSIMD-bfmlalt   ( -- ) ." bfmlalt" op-col .Vd.4s, .Vn.8h, .Vm.8h ;
 
 
 
 
: AdvSIMD-bfcvtn   ( -- ) 
    d# 30 bit? \ Q=1
    IF
        ." bfcvtn2"  op-col .Vd.8h, .Vn.4s 
    ELSE
        ." bfcvtn"  op-col .Vd.4h, .Vn.4s 
    THEN
    ;
 
: AdvSIMD-bfcvt   ( -- ) ." bfcvt"  op-col .Vd.h ., .Vn.s  ;


: AdvSIMD-3same-complex   ( -- )
   13 bit? if
      ." fcadd" .AdvSIMD-3same-regs ." , #" 12 1bit if  270  else  90  then  .d
   else
      ." fcmla" .AdvSIMD-3same-regs ." , #" 11 2bits 90 * .d
   then
;

: AdvSIMD-3same-floats   ( -- )
   \ floats are U:size<1>:opcode
     instruction@ 11 >> h# 1f and
     ( opcode )
     instruction@ 18 >> h# 20 and or
     ( sz[1]:opcode )
     instruction@ 23 >> h# 40 and or
     
     ( U:sz[1]:opcode )
    CASE
        b# 0.0.11000 of ." fmaxnm"      endof
        b# 0.0.11001 of ." fmla"        endof
        b# 0.0.11010 of ." fadd"        endof
        b# 0.0.11011 of ." fmulx"       endof
        b# 0.0.11100 of ." fcmeq"       endof
        b# 0.0.11101 of ." UNALLOCATED" endof
        b# 0.0.11110 of ." fmax"        endof
        b# 0.0.11111 of ." recp"        endof

        b# 0.1.11000 of ." fminnm"      endof
        b# 0.1.11001 of ." fmls"        endof
        b# 0.1.11010 of ." fsub"        endof
        b# 0.1.11011 of ." UNALLOCATED" endof
        b# 0.1.11100 of ." UNALLOCATED" endof
        b# 0.1.11101 of ." UNALLOCATED" endof
        b# 0.1.11110 of ." fmin"        endof
        b# 0.1.11111 of ." frsqrts"     endof

        b# 1.0.11000 of ." fmaxnmp"     endof
        b# 1.0.11001 of ." UNALLOCATED" endof
        b# 1.0.11010 of ." faddp"       endof
        b# 1.0.11011 of ." fmul"        endof
        b# 1.0.11100 of ." fcmge"       endof
        b# 1.0.11101 of ." facge"       endof
        b# 1.0.11110 of ." fmaxp"       endof
        b# 1.0.11111 of ." fdiv"        endof

        b# 1.1.11000 of ." fminnmp"     endof
        b# 1.1.11001 of ." UNALLOCATED" endof
        b# 1.1.11010 of ." fabd"        endof
        b# 1.1.11011 of ." UNALLOCATED" endof
        b# 1.1.11100 of ." fcmgt"       endof
        b# 1.1.11101 of ." facgt"       endof
        b# 1.1.11110 of ." fminp"       endof
        b# 1.1.11111 of ." UNALLOCATED" endof
        unimpl drop exit
    ENDCASE
    .AdvSIMD-3same-regs
;

: AdvSIMD-3same-floats-hp   ( -- )          \ vector half-precision
   \ floats are U:size<1>:opcode
     instruction@ 11 >> h# 1f and
     ( opcode )
     instruction@ 18 >> h# 20 and or
     ( sz[1]:opcode )
     instruction@ 23 >> h# 40 and or

     ( U:sz[1]:opcode )
    CASE
        b# 0.0.00000 of ." fmaxnm"      endof
        b# 0.0.00001 of ." fmla"        endof
        b# 0.0.00010 of ." fadd"        endof
        b# 0.0.00011 of ." fmulx"       endof
        b# 0.0.00100 of ." fcmeq"       endof
        b# 0.0.00101 of ." UNALLOCATED" endof
        b# 0.0.00110 of ." fmax"        endof
        b# 0.0.00111 of ." recp"        endof

        b# 0.1.00000 of ." fminnm"      endof
        b# 0.1.00001 of ." fmls"        endof
        b# 0.1.00010 of ." fsub"        endof
        b# 0.1.00011 of ." UNALLOCATED" endof
        b# 0.1.00100 of ." UNALLOCATED" endof
        b# 0.1.00101 of ." UNALLOCATED" endof
        b# 0.1.00110 of ." fmin"        endof
        b# 0.1.00111 of ." frsqrts"     endof

        b# 1.0.00000 of ." fmaxnmp"     endof
        b# 1.0.00001 of ." UNALLOCATED" endof
        b# 1.0.00010 of ." faddp"       endof
        b# 1.0.00011 of ." fmul"        endof
        b# 1.0.00100 of ." fcmge"       endof
        b# 1.0.00101 of ." facge"       endof
        b# 1.0.00110 of ." fmaxp"       endof
        b# 1.0.00111 of ." fdiv"        endof

        b# 1.1.00000 of ." fminnmp"     endof
        b# 1.1.00001 of ." UNALLOCATED" endof
        b# 1.1.00010 of ." fabd"        endof
        b# 1.1.00011 of ." UNALLOCATED" endof
        b# 1.1.00100 of ." fcmgt"       endof
        b# 1.1.00101 of ." facgt"       endof
        b# 1.1.00110 of ." fminp"       endof
        b# 1.1.00111 of ." UNALLOCATED" endof
        unimpl drop exit
    ENDCASE
    .AdvSIMD-3same-regs-hp
;

: .AdvSIMD-perbyte-imm
   instruction@ 5 >> 0x1f and
   instruction@ 16 >> 7 and 5 << or
   ." #0x" push-hex u. pop-base
;


\ ---------------------------------------------------------------------------
\ movi
\ ---------------------------------------------------------------------------
\ WIP
\ All the negatives:
\ Does not include the BIC and ORR permutations in this class of opcodes.
\ and, at this time, does not represent the immediate value the way the spec says it should.
\ The assembler is supposed to automajikally evaluate the immediate value,
\ and figure out the/a way to acheive that value via the permutation options.
\ Expanded imm8 value is reconstructed and output as a comment.
\ Need to come up with some way to disambiguate the syntax/permutations.
\ May need super computer to do that.
\ I have verified that the reconstructed value matches the hardware results.
\ But this output is NOT and will not be suitable syntacically for the assembly side.
\ Which at this time, does not exit.
\ Below is examples of some of the output permutations.
\ Can remove these when the support is completed
\
\  0f00c420    movi    v0.2s, #0x01, msl #8     \ #0x000001ff000001ff
\  4f00c421    movi    v1.4s, #0x01, msl #8     \ #0x000001ff000001ff
\  2f00c422    mvni    v2.2s, #0x01, msl #8     \ #0xfffffe00fffffe00
\  6f00c423    mvni    v3.4s, #0x01, msl #8     \ #0xfffffe00fffffe00
\  0f00d424    movi    v4.2s, #0x01, msl #16    \ #0x0001ffff0001ffff
\  4f00d425    movi    v5.4s, #0x01, msl #16    \ #0x0001ffff0001ffff
\  2f00d426    mvni    v6.2s, #0x01, msl #16    \ #0xfffe0000fffe0000
\  6f00d427    mvni    v7.4s, #0x01, msl #16    \ #0xfffe0000fffe0000
\  0f00e628    movi    v8.8b, #0x11,            \ #0x1111111111111111
\  4f00e629    movi    v9.16b, #0x11,           \ #0x1111111111111111
\  2f04e42a    movi    d10, #0x81,              \ #0xff000000000000ff (abcdefgh)
\  6f02e44b    movi    v11.2d, #0x42,           \ #0x00ff00000000ff00 (abcdefgh)
\  4f04f432    movi    v18.4s, #0x81            \ #0xbfa0000000000000 ( #fimm )
\  6f02f453    movi    v19.2d, #0x42            \ #0xc00c000000000000 ( #fimm )
\  0f000420    movi    v0.2s, #0x01, lsl #0     \ #0x0000000100000001
\  4f000421    movi    v1.4s, #0x01, lsl #0     \ #0x0000000100000001
\  2f000442    mvni    v2.2s, #0x02, lsl #0     \ #0xfffffffdfffffffd
\  6f000463    mvni    v3.4s, #0x03, lsl #0     \ #0xfffffffcfffffffc
\  0f004508    movi    v8.2s, #0x08, lsl #16    \ #0x0008000000080000
\  4f004529    movi    v9.4s, #0x09, lsl #16    \ #0x0009000000090000
\  2f00454a    mvni    v10.2s, #0x0a, lsl #16   \ #0xfff5fffffff5ffff
\  6f00456b    mvni    v11.4s, #0x0b, lsl #16   \ #0xfff4fffffff4ffff
\  0f00658c    movi    v12.2s, #0x0c, lsl #24   \ #0x0c0000000c000000
\  4f0065ad    movi    v13.4s, #0x0d, lsl #24   \ #0x0d0000000d000000
\  2f0065ce    mvni    v14.2s, #0x0e, lsl #24   \ #0xf1fffffff1ffffff
\  6f0065ef    mvni    v15.4s, #0x0f, lsl #24   \ #0xf0fffffff0ffffff
\  0f008430    movi    v16.4h, #0x01, lsl #0    \ #0x0001000100010001
\  4f008431    movi    v17.8h, #0x01, lsl #0    \ #0x0001000100010001
\  0f00a432    movi    v18.4h, #0x01, lsl #8    \ #0x0100010001000100
\  4f00a433    movi    v19.8h, #0x01, lsl #8    \ #0x0100010001000100
\  2f008434    mvni    v20.4h, #0x01, lsl #0    \ #0xfffefffefffefffe
\  6f008435    mvni    v21.8h, #0x01, lsl #0    \ #0xfffefffefffefffe
\  2f00a436    mvni    v22.4h, #0x01, lsl #8    \ #0xfefffefffefffeff
\  6f00a437    mvni    v23.8h, #0x01, lsl #8    \ #0xfefffefffefffeff
\ ---------------------------------------------------------------------------



\ these are duplicates because they don't exist yet.
: lxjoin n->l 0x20 lshift swap n->l or ;
: zeros   ( n -- ) 0 max 0 ?do [char] 0 emit loop ;
: uz.r   (s u len -- ) 
    >r (u.) dup r@ >
    IF dup r@ - /string THEN
    r@ min r> over - zeros type 
    ;

: .#0xImm64     op-col ."  \ #0x"     d# 16 uz.r space ;
: .#0xImm32     op-col ."  \ #0x"     d# 8 uz.r space ;
: .#0xImm64Not not .#0xImm64 ;
: (.Imm8) push-hex 2 uz.r pop-base ;
: .#0xImm8  ." #0x"  (.Imm8) ;
: .f#0xImm8 ." f#0x" (.Imm8) ;

\ Extract imm8


: ((AvSMD-Ext-ModImm)) ( op -- imm8 ) dup 5 >> 0x1f and swap d# 11 >> 0xe0 and or ;
: (AvSMD-Ext-ModImm)   ( -- imm8 ) instruction@ ((AvSMD-Ext-ModImm)) ;

: AvSMD-Ext-ModImm ( -- imm8 ) (AvSMD-Ext-ModImm) dup .#0xImm8  ;

: .,LSL# ( n ) ." , lsl #" .d ;   \ shift 0's into low order bits
: .,MSL# ( n ) ." , msl #" .d ;   \ shift 1's into low order bits


\ op[29]=1=invert
: ?#0xImm64|NOT 29 bit? IF .#0xImm64Not ELSE .#0xImm64 THEN ;

: (.AvSMD-im8<<n)   >r  AvSMD-Ext-ModImm r@ .,LSL# r> << dup lxjoin ?#0xImm64|NOT ;

\ ----------------
\ cmode<3:1> 000.op:0
\ cmode<3:0> 000.op:1 mvni
\ ----------------
: .AvSMD-im8<<0     0 (.AvSMD-im8<<n) ;

\ ----------------
\ cmode<3:1> 001
\ ----------------
: .AvSMD-im8<<8     8 (.AvSMD-im8<<n) ;

\ ----------------
\ cmode<3:1> 010
\ ----------------
: .AvSMD-im8<<16     16 (.AvSMD-im8<<n) ;

\ ----------------
\ cmode<3:1> 011
\ ----------------
: .AvSMD-im8<<24     24 (.AvSMD-im8<<n) ;

: (AvSMD-im8h<<N)    >r AvSMD-Ext-ModImm r@ .,LSL# r> << dup wljoin dup lxjoin ?#0xImm64|NOT ;
\ ----------------
\ cmode<3:1> 100
\ ----------------
: .AvSMD-im8-h<<0      0 (AvSMD-im8h<<N) ;

\ ----------------
\ cmode<3:1> 101
\ ----------------
: .AvSMD-im8-h<<8   8 (AvSMD-im8h<<N) ;

\ ----------------
\ cmode<3:0> 1100
\ ----------------

\ only MSL# 8 and MSL #16
\ No MSL #24
: (AvSMD-im8-MSL-N)    >r AvSMD-Ext-ModImm r@ .,MSL# r@ << r> mask or dup lxjoin ?#0xImm64|NOT ;
: .AvSMD-im8-MSL8     8 (AvSMD-im8-MSL-N) ;
: .AvSMD-im8-MSL16    16 (AvSMD-im8-MSL-N) ;


\ ----------------
\ cmode<op.3:0> 0.1110
\ ----------------
: .AvSMD-imm8,8               AvSMD-Ext-ModImm dup bwjoin dup wljoin dup lxjoin .#0xImm64 ;

\ ----------------
\ cmode<op.3:0> 1.1110
\ ----------------
: .AvSMD-imm8:abcdefgh      
    AvSMD-Ext-ModImm 0 
    ( imm imm64 ) 
    0 7                 \ construct imm64. start with MSB
    DO
        ( imm8 imm64 )
        over 
        ( imm8 imm64 imm8 )
        1 i << and
        ( imm8 imm64 bit? )
        If 0xFF i 8 * << or then
    -1 +LOOP
    nip
    .#0xImm64 
    ;



\ ----------------
\ cmode<op.3:0> 1.1111
\ ----------------
\ imm8<7>:NOT(imm8<6>):Replicate(imm8<6>,8):imm8<5:0>:Zeros(48);
defer .#fimm64
defer .#fimm32
' . is .#fimm64 \ these get re-assigned in dminit to construct and display a decimal float
' . is .#fimm32

: .AvSMD-fimm64
    (AvSMD-Ext-ModImm) dup .f#0xImm8
    0
    ( imm imm64 )
    over 0x80 and d# 56 << or               \ imm8<7>
    over 0x40 xor 0x40 and d# 56 << or      \ :NOT(imm8<6>)  
    over 0x40 and IF 0xFF d# 54 << or THEN  \ Replicate(imm8<6>,8)
    over 0x3f and d# 48 << or               \ :imm8<5:0>
    nip
    dup
    .#0xImm64 
    .#fimm64
    ;
   



\ imm8<7>: NOT(imm8<6>): Replicate(imm8<6>,5): imm8<5:0>: Zeros(19)
: .AvSMD-fimm32
    (AvSMD-Ext-ModImm) dup .f#0xImm8
    0
    ( imm imm32 )
    over 0x80 and          d# 24 << or      \ imm8<7>
    over 0x40 xor 0x40 and d# 24 << or      \ :NOT(imm8<6>)  
    over 0x40 and IF 0x1F  d# 25 << or THEN \ Replicate(imm8<6>,5)
    over 0x3f and          d# 19 << or      \ :imm8<5:0>
    nip
    dup
    .#0xImm32
    .#fimm32
    ;

: ."movi" ." movi" ;
: ."mvni" ." mvni" ;

: ?.Vd.8b16b op-col 30 bit? IF .Vd.16b, ELSE .Vd.8b, THEN ;
: .movi-nB, ."movi" ?.Vd.8b16b ;
: .mvni-nB, ."mvni" ?.Vd.8b16b ;

: ?.Vd.2S4S op-col 30 bit? IF .Vd.4s, ELSE .Vd.2s, THEN ;
: .movi-nS, ."movi" ?.Vd.2s4S ;
: .mvni-nS, ."mvni" ?.Vd.2s4S ; 

: ?.Vd.4H8H op-col 30 bit? IF .Vd.8h, ELSE .Vd.4h, THEN ;
: .movi-nH, ."movi" ?.Vd.4H8H ;
: .mvni-nH, ."mvni" ?.Vd.4H8H ;

: ?.Vd.2d-vd.4s op-col 30 bit? IF .Vd.2d, ELSE .Vd.4s, THEN ;


: AdvSIMD-mod-imm
   instruction@ 11 >> 0x1e and     \ cmode[15:12]
   instruction@ 29 >> 0x1 and or   \ op[29]
   ( cmode:op )
   case
      \ cmode.op 
      b# 0000.0 of .movi-nS, .AvSMD-im8<<0  endof   \ lsl #0
      b# 0000.1 of .mvni-nS, .AvSMD-im8<<0  endof   \ lsl #0 NOT

      b# 0010.0 of .movi-nS, .AvSMD-im8<<8  endof   \ lsl #8
      b# 0010.1 of .mvni-nS, .AvSMD-im8<<8  endof   \ lsl #8 NOT

      b# 0100.0 of .movi-nS, .AvSMD-im8<<16 endof   \ lsl #16
      b# 0100.1 of .mvni-nS, .AvSMD-im8<<16 endof   \ lsl #16

      b# 0110.0 of .movi-nS, .AvSMD-im8<<24 endof   \ lsl #24
      b# 0110.1 of .mvni-nS, .AvSMD-im8<<24 endof   \ lsl #24

      b# 1000.0 of .movi-nH, .AvSMD-im8-h<<0 endof
      b# 1000.1 of .mvni-nH, .AvSMD-im8-h<<0 endof
      b# 1010.0 of .movi-nH, .AvSMD-im8-h<<8 endof
      b# 1010.1 of .mvni-nH, .AvSMD-im8-h<<8 endof


      b# 1100.0 of .movi-nS, .AvSMD-im8-MSL8  endof  \ MSL
      b# 1100.1 of .mvni-nS, .AvSMD-im8-MSL8  endof
      b# 1101.0 of .movi-nS, .AvSMD-im8-MSL16 endof  \ MSL
      b# 1101.1 of .mvni-nS, .AvSMD-im8-MSL16 endof

    \ 8b or 16B
      b# 1110.0 of .movi-nB, .AvSMD-imm8,8           endof
      
    \ this is Dn or Vd.2d
      b# 1110.1                         \ MOVI Dn, #uimm64 byte mask” immediate 
      of 
        ."movi" op-col 30 bit? 
        IF .Vd.2d, ELSE .Dd, THEN
        .AvSMD-imm8:abcdefgh    
      endof   

    \ these construct #fimm
      b# 1111.0 of
	 ." fmov" op-col
	 30 bit? if  .Vd.4S,  else  .Vd.2S,  then
	 .AvSMD-fimm32
      endof
      
      b# 1111.1 
      of 
          30 bit? 0=
          IF
            ." <unknown> "
          ELSE
            ." fmov" op-col .Vd.2d, .AvSMD-fimm64    
          THEN 
      endof \ Vd.2D


    \ Hack place holders

      b# 0001.1 of ." vbic" op-col .Vd.4S, .AvSMD-im8<<0  endof 
      b# 0011.1 of ." vbic" op-col .Vd.4S, .AvSMD-im8<<8  endof 
      b# 0101.1 of ." vbic" op-col .Vd.4S, .AvSMD-im8<<16 endof 
      b# 0111.1 of ." vbic" op-col .Vd.4S, .AvSMD-im8<<24 endof 
      b# 1001.1 of ." vbic" op-col .Vd.4h, .AvSMD-im8<<0  endof 
      b# 1011.1 of ." vbic" op-col .Vd.4h, .AvSMD-im8<<8  endof 
      
      b# 0001.0 of ." vorr" op-col .Vd.4S, .AvSMD-im8<<0  endof 
      b# 0011.0 of ." vorr" op-col .Vd.4S, .AvSMD-im8<<8  endof 
      b# 0101.0 of ." vorr" op-col .Vd.4S, .AvSMD-im8<<16 endof 
      b# 0111.0 of ." vorr" op-col .Vd.4S, .AvSMD-im8<<24 endof 
      b# 1001.0 of ." vorr" op-col .Vd.4h, .AvSMD-im8<<0  endof 
      b# 1011.0 of ." vorr" op-col .Vd.4h, .AvSMD-im8<<8  endof 

      cr ." AdvSIMD-mod-imm " unimpl  
    endcase
    ;

\ ---------------------------------------------------------------------------


: .same-v2regs   ( szq -- )
   case
      b# 000 of .Vd.8b,  .Vn.8b  endof
      b# 001 of .Vd.16b, .Vn.16b endof
      b# 010 of .Vd.4h,  .Vn.4h  endof
      b# 011 of .Vd.8h,  .Vn.8h  endof
      b# 100 of .Vd.2s,  .Vn.2s  endof
      b# 101 of .Vd.4s,  .Vn.4s  endof
      b# 111 of .Vd.2d,  .Vn.2d  endof
      invalid-regs
   endcase
;
: .shift-v2regs   ( imm szq -- )
   case
      b# 000 of .Vd.8h,  .Vn.8b,  endof
      b# 001 of .Vd.8h,  .Vn.16b, endof
      b# 010 of .Vd.4s,  .Vn.4h,  endof
      b# 011 of .Vd.4s,  .Vn.8h,  endof
      b# 100 of .Vd.2d,  .Vn.2s,  endof
      b# 101 of .Vd.2d,  .Vn.4s,  endof
      invalid-regs
   endcase
   .imm
;
: .same-x2regs   ( szq -- )
   case
      b# 000 of .Bd, .Vn.8b  endof
      b# 001 of .Bd, .Vn.16b endof
      b# 010 of .Hd, .Vn.4h  endof
      b# 011 of .Hd, .Vn.8h  endof
      b# 100 of .Sd, .Vn.2s  endof
      b# 101 of .Sd, .Vn.4s  endof
      invalid-regs
   endcase
;
: .sha-2regs   ( op -- )
   case
      0 of .Sd,    .Sn     endof
      1 of .Vd.4s, .Vn.4s  endof
      2 of .Vd.4s, .Vn.4s  endof
      invalid-regs
   endcase
;
: .sha-3regs   ( op -- )
   case
      0 of .Qd,     .Sn,     .Vm.4s  endof
      1 of .Qd,     .Sn,     .Vm.4s  endof
      2 of .Qd,     .Sn,     .Vm.4s  endof
      3 of .Vd.4s,  .Vn.4s,  .Vm.4s  endof
      4 of .Qd,     .Qn,     .Vm.4s  endof
      5 of .Qd,     .Qn,     .Vm.4s  endof
      6 of .Vd.4s,  .Vn.4s,  .Vm.4s  endof
      invalid-regs
   endcase
;
: .long-x2regs   ( szq -- )
   case
      b# 000 of .Hd, .Vn.8b  endof
      b# 001 of .Hd, .Vn.16b endof
      b# 010 of .Sd, .Vn.4h  endof
      b# 011 of .Sd, .Vn.8h  endof
      b# 100 of .Dd, .Vn.2s  endof
      b# 101 of .Dd, .Vn.4s  endof
      invalid-regs
   endcase
;
: .same-v3regs   ( szq -- )
   case
      b# 000 of .Vd.8b,  .Vn.8b,  .Vm.8b  endof
      b# 001 of .Vd.16b, .Vn.16b, .Vm.16b endof
      b# 010 of .Vd.4h,  .Vn.4h,  .Vm.4h  endof
      b# 011 of .Vd.8h,  .Vn.8h,  .Vm.8h  endof
      b# 100 of .Vd.2s,  .Vn.2s,  .Vm.2s  endof
      b# 101 of .Vd.4s,  .Vn.4s,  .Vm.4s  endof
      b# 111 of .Vd.2d,  .Vn.2d,  .Vm.2d  endof
      invalid-regs
   endcase
;
: .long-v3regs   ( szq -- )
   case
      b# 000 of .Vd.8h,  .Vn.8b,  .Vm.8b  endof
      b# 001 of .Vd.8h,  .Vn.16b, .Vm.16b endof
      b# 010 of .Vd.4s,  .Vn.4h,  .Vm.4h  endof
      b# 011 of .Vd.4s,  .Vn.8h,  .Vm.8h  endof
      b# 100 of .Vd.2d,  .Vn.2s,  .Vm.2s  endof
      b# 101 of .Vd.2d,  .Vn.4s,  .Vm.4s  endof
      invalid-regs
   endcase
;
: .long-v3regs-pmull  ( szq -- )
   case
      b# 000 of .Vd.8h,  .Vn.8b,  .Vm.8b  endof
      b# 001 of .Vd.8h,  .Vn.16b, .Vm.16b endof
      b# 110 of .Vd.1q,  .Vn.1d,  .Vm.1d  endof
      b# 111 of .Vd.1q,  .Vn.2d,  .Vm.2d  endof
      invalid-regs
   endcase
;
: .wide-v3regs   ( szq -- )
   case
      b# 000 of .Vd.8h,  .Vn.8h,  .Vm.8b  endof
      b# 001 of .Vd.8h,  .Vn.8h,  .Vm.16b endof
      b# 010 of .Vd.4s,  .Vn.4s,  .Vm.4h  endof
      b# 011 of .Vd.4s,  .Vn.4s,  .Vm.8h  endof
      b# 100 of .Vd.2d,  .Vn.2d,  .Vm.2s  endof
      b# 101 of .Vd.2d,  .Vn.2d,  .Vm.4s  endof
      invalid-regs
   endcase
;
: .narrow-v3regs   ( szq -- )
   case
      b# 000 of .Vd.8b,  .Vn.8h,  .Vm.8h  endof
      b# 001 of .Vd.16b, .Vn.8h,  .Vm.8h  endof
      b# 010 of .Vd.4h,  .Vn.4s,  .Vm.4s  endof
      b# 011 of .Vd.8h,  .Vn.4s,  .Vm.4s  endof
      b# 100 of .Vd.2s,  .Vn.2d,  .Vm.2d  endof
      b# 101 of .Vd.4s,  .Vn.2d,  .Vm.2d  endof
      invalid-regs
   endcase
;

: .same-float-s3regs   ( sz -- )
   case
      b# 00 of .Sd, .Sn, .Sm endof
      b# 01 of .Dd, .Dn, .Dm endof
      b# 11 of .Dd, .Dn, .Dm endof \ So scalar version (Dregs) of ushl displays properly 
      invalid-regs
   endcase
;
: .same-s3regs   ( sz -- )
   case
      b# 00 of .Bd, .Bn, .Bm endof
      b# 01 of .Hd, .Hn, .Hm endof
      b# 10 of .Sd, .Sn, .Sm endof
      b# 11 of .Dd, .Dn, .Dm endof
   endcase
;
: .long-s3regs   ( sz -- )
   case
      b# 01 of .Sd, .Hn, .Hm endof
      b# 10 of .Dd, .Sn, .Sm endof
   endcase
;
: .wide-s3regs   ( sz -- )
   case
      b# 01 of .Sd, .Sn, .Hm endof
      b# 10 of .Dd, .Dn, .Sm endof
   endcase
;
: .narrow-3regs   ( sz -- )
   case
      b# 01 of .Bd, .Hn, .Hm endof
      b# 10 of .Hd, .Sn, .Sm endof
      b# 11 of .Sd, .Dn, .Dm endof
   endcase
;

: .same-s2regs   ( sz -- )
   case
      b# 00 of .Bd, .Bn endof
      b# 01 of .Hd, .Hn endof
      b# 10 of .Sd, .Sn endof
      b# 11 of .Dd, .Dn endof
   endcase
;
: .narrow-s2regs   ( sz -- )
   case
      b# 01 of  .Bd, .Hn  endof
      b# 10 of  .Hd, .Sn  endof
      b# 11 of  .Sd, .Dn  endof
   endcase
;

: AdvSIMD-Scalar-3same-floats   ( -- )
   29 1bit 7 <<  22 2bits 5 << or  11 5bits or  ( usz.op )
   case
      b# 000.11011 of  ." fmulx"     endof
      b# 000.11100 of  ." fcmeq"     endof
      b# 000.11111 of  ." frecps"    endof
      b# 001.11011 of  ." fmulx"     endof
      b# 001.11100 of  ." fcmeq"     endof
      b# 001.11111 of  ." frecps"    endof
      b# 010.11111 of  ." frsqrts"   endof
      b# 011.11111 of  ." frsqrts"   endof
      b# 011.00110 of  ." cmgt"      endof
      b# 011.00111 of  ." cmge"      endof
      b# 011.01000 of  ." sshl"      endof
      b# 011.01010 of  ." srshl"     endof
      b# 011.10000 of  ." add"       endof
      b# 011.10001 of  ." cmtst"     endof
      b# 100.11100 of  ." fcmge"     endof
      b# 100.11101 of  ." facge"     endof
      b# 101.11100 of  ." fcmge"     endof
      b# 101.11101 of  ." facge"     endof
      b# 110.11010 of  ." fabd"      endof
      b# 110.11100 of  ." fcmgt"     endof
      b# 110.11101 of  ." facgt"     endof
      b# 111.11010 of  ." fabd"      endof
      b# 111.11100 of  ." fcmgt"     endof
      b# 111.11101 of  ." facgt"     endof
      b# 111.00110 of  ." cmhi"      endof
      b# 111.00111 of  ." cmhs"      endof
      b# 111.01000 of  ." ushl"      endof
      b# 111.01010 of  ." urshl"     endof
      b# 111.10000 of  ." sub"       endof
      b# 111.10001 of  ." cmeq"      endof
      invalid-op drop exit
   endcase
   regsz .same-float-s3regs
;       
: AdvSIMD-Scalar-3same   ( -- )
   true >r
   29 1bit 5 <<  11 5bits or  ( u.op )
   case
      b# 0.00001 of  ." sqadd"     endof
      b# 0.00101 of  ." sqsub"     endof
      b# 0.01001 of  ." sqshl"     endof
      b# 0.01011 of  ." sqrshl"    endof
      b# 0.10110 of  ." sqdmulh"   endof
      b# 1.00001 of  ." uqadd"     endof
      b# 1.00101 of  ." uqsub"     endof
      b# 1.01001 of  ." uqshl"     endof
      b# 1.01011 of  ." uqrshl"    endof
      b# 1.10110 of  ." sqrdmulh"  endof
      r> drop false >r
   endcase
   r> if
      regsz .same-s3regs
   else
      AdvSIMD-Scalar-3same-floats
   then
;

: AdvSIMD-3diff-narrow   ( u.op -- found? )
   case
      b# 00100 of   ." addhn"       endof
      b# 00110 of   ." subhn"       endof
      b# 10100 of   ." raddhn"      endof
      b# 10110 of   ." rsubhn"      endof
      drop false exit
   endcase
   regszq  .narrow-v3regs
   true
;   
: AdvSIMD-3diff-wide   ( u.op -- found? )
   case
      b# 00001 of   ." saddw"       endof
      b# 00011 of   ." ssubw"       endof
      b# 10001 of   ." uaddw"       endof
      b# 10011 of   ." usubw"       endof
      drop false exit
   endcase
   regszq .wide-v3regs
   true
;
: AdvSIMD-3diff-long   ( u.op -- found? )
   case
      b# 00000 of   ." saddl"       endof
      b# 00010 of   ." ssubl"       endof
      b# 00101 of   ." sabal"       endof
      b# 00111 of   ." sabdl"       endof
      b# 01000 of   ." smlal"       endof
      b# 01001 of   ." sqdmlal"     endof
      b# 01010 of   ." smlsl"       endof
      b# 01011 of   ." sqdmlsl"     endof
      b# 01100 of   ." smull"       endof
      b# 01101 of   ." sqdmull"     endof
      b# 10000 of   ." uaddl"       endof
      b# 10010 of   ." usubl"       endof
      b# 10101 of   ." uabal"       endof
      b# 10111 of   ." uabdl"       endof
      b# 11000 of   ." umlal"       endof
      b# 11010 of   ." umlsl"       endof
      b# 11100 of   ." umull"       endof
      drop false exit
   endcase
   30 1bit if  ." 2"  then
   regszq .long-v3regs
   true
;
: AdvSIMD-3diff-long-pmull   ( u.op -- found? )
   case
      b# 01110 of   ." pmull"       endof
      drop false exit
   endcase
   30 1bit if  ." 2"  then
   regszq .long-v3regs-pmull
   true
;
: AdvSIMD-3diff   ( -- )
   29 1bit 4 <<  12 4bits or  ( u.op )
   dup AdvSIMD-3diff-long        if  drop exit  then
   dup AdvSIMD-3diff-long-pmull  if  drop exit  then
   dup AdvSIMD-3diff-wide        if  drop exit  then
   dup AdvSIMD-3diff-narrow      if  drop exit  then
   drop invalid-op
;

: AdvSIMD-Scalar-3diff   ( -- )
   12 4bits case
      b# 1001 of  ." sqdmlal"  endof
      b# 1011 of  ." sqdmlsl"  endof
      b# 1101 of  ." sqdmull"  endof
      invalid-op drop exit
   endcase
   regsz .long-s3regs
;

: AdvSIMD-2reg-misc-floats   ( -- )
   29 1bit 6 <<  23 1bit 5 << or  12 5bits or  ( u.op )
   case
      b# 00.10110 of   ." fcvtn"    endof
      b# 00.10111 of   ." fcvtl"    endof
      b# 00.11000 of   ." frintn"   endof
      b# 00.11001 of   ." frintm"   endof
      b# 00.11010 of   ." fcvtns"   endof
      b# 00.11011 of   ." fcvtms"   endof
      b# 00.11100 of   ." fcvtas"   endof
      b# 00.11101 of   ." scvtf"    endof
      b# 01.01100 of   ." fcmgt"    endof
      b# 01.01101 of   ." fcmeq"    endof
      b# 01.01110 of   ." fcmlt"    endof
      b# 01.01111 of   ." fabs"     endof
      b# 01.11000 of   ." frintp"   endof
      b# 01.11001 of   ." frintz"   endof
      b# 01.11010 of   ." fcvtps"   endof
      b# 01.11011 of   ." fcvtpz"   endof
      b# 01.11100 of   ." urecpe"   endof
      b# 01.11101 of   ." frecpe"   endof
      b# 10.10110 of   ." fcvtxn"   endof
      b# 10.11000 of   ." frinta"   endof
      b# 10.11001 of   ." frintx"   endof
      b# 10.11010 of   ." fcvtnu"   endof
      b# 10.11011 of   ." fcvtmu"   endof
      b# 10.11100 of   ." fcvtau"   endof
      b# 10.11101 of   ." ucvtf"    endof
      b# 11.01100 of   ." fcmge"    endof
      b# 11.01101 of   ." fcmle"    endof
      b# 11.01111 of   ." fneg"     endof
      b# 11.11001 of   ." frinti"   endof
      b# 11.11010 of   ." fcvtpu"   endof
      b# 11.11011 of   ." fcvtzu"   endof
      b# 11.11100 of   ." ursqrte"  endof
      b# 11.11101 of   ." frsqrte"  endof
      b# 11.11111 of   ." fsqrt"    endof
      drop false exit
   endcase
   17 4bits 0= IF
      regszq .same-v2regs        \ XXX floats?
   ELSE
      regq 2 or .same-v2regs     \ XXX floats?
   THEN
   true
;
: AdvSIMD-2reg-misc-ints   ( -- )
   29 1bit 5 <<  12 5bits or  ( u.op )
   case
      b# 000000 of   ." rev64"    endof
      b# 000001 of   ." rev16"    endof
      b# 000010 of   ." saddlp"   endof
      b# 000011 of   ." suqadd"   endof
      b# 000100 of   ." cls"      endof
      b# 000101 of   ." cnt"      endof
      b# 000110 of   ." sadalp"   endof
      b# 000111 of   ." sqabs"    endof
      b# 001000 of   ." cmgt"     endof
      b# 001001 of   ." cmeq"     endof
      b# 001010 of   ." cmlt"     endof
      b# 001011 of   ." abs"      endof
      b# 010010 of   ." xtn"      endof
      b# 010100 of   ." sqxtn"    endof
      b# 100000 of   ." rev32"    endof
      b# 100010 of   ." uaddlp"   endof
      b# 100011 of   ." usqadd"   endof
      b# 100100 of   ." clz"      endof
      b# 100110 of   ." uadalp"   endof
      b# 100111 of   ." sqneg"    endof
      b# 101000 of   ." cmge"     endof
      b# 101001 of   ." cmle"     endof
      b# 101011 of   ." neg"      endof
      b# 110010 of   ." sqxtun"   endof
      b# 110011 of   ." shll"     endof
      b# 110100 of   ." uqxtn"    endof
      drop false exit
   endcase
   regszq .same-v2regs
   true
;
: AdvSIMD-2reg-misc-bytes   ( -- )
   29 1bit 5 <<  12 5bits or  ( u.op )
   b# 100101 <> 
   if  
        \ drop 
        false exit  
   then
   22 1bit if  ." rbit"  else  ." not"  then  op-col
   30 1bit if
      .Vd.16b, .Vn.16b
   else
      .Vd.8b, .Vn.8b
   then
   true
;
: AdvSIMD-2reg-misc   ( -- )
   AdvSIMD-2reg-misc-bytes  if  exit  then
   AdvSIMD-2reg-misc-ints   if  exit  then
   AdvSIMD-2reg-misc-floats if  exit  then
   invalid-op
;
: AdvSIMD-Scalar-2reg-misc-floats   ( -- found? )
   29 1bit 6 <<  23 1bit 5 << or  12 5bits or  ( usz.op )
   case
      b# 00.11010 of   ." fcvtns"   endof
      b# 00.11011 of   ." fcvtms"   endof
      b# 00.11100 of   ." fcvtas"   endof
      b# 00.11101 of   ." scvtf"    endof
      b# 01.01100 of   ." fcmgt"    endof
      b# 01.01101 of   ." fcmeq"    endof
      b# 01.01110 of   ." fcmlt"    endof
      b# 01.11010 of   ." fcvtps"   endof
      b# 01.11011 of   ." fcvtpz"   endof
      b# 01.11101 of   ." frecpe"   endof
      b# 01.11111 of   ." frecpx"   endof
      b# 10.10110 of   ." fcvtxn"   endof
      b# 10.11010 of   ." fcvtnu"   endof
      b# 10.11011 of   ." fcvtmu"   endof
      b# 10.11100 of   ." fcvtau"   endof
      b# 10.11101 of   ." ucvtf"    endof
      b# 11.01100 of   ." fcmge"    endof
      b# 11.01101 of   ." fcmle"    endof
      b# 11.11010 of   ." fcvtpu"   endof
      b# 11.11011 of   ." fcvtzu"   endof
      b# 11.11101 of   ." frsqrte"  endof
      drop false exit
   endcase
   regsz .same-s2regs
   true
;
: AdvSIMD-Scalar-2reg-misc-ints   ( -- found? )
   29 1bit 5 <<  12 5bits or  ( u.op )
   case
      b# 000011 of   ." suqadd"   endof
      b# 000111 of   ." sqabs"    endof
      b# 001000 of   ." cmgt"     endof
      b# 001001 of   ." cmeq"     endof
      b# 001010 of   ." cmlt"     endof
      b# 001011 of   ." abs"      endof
      b# 010100 of   ." sqxtn"    endof
      b# 100011 of   ." usqadd"   endof
      b# 100111 of   ." sqneg"    endof
      b# 101000 of   ." cmge"     endof
      b# 101001 of   ." cmle"     endof
      b# 101011 of   ." neg"      endof
      b# 110010 of   ." sqxtun"   endof
      b# 110100 of   ." uqxtn"    endof
      drop false exit
   endcase
   regsz .same-s2regs
   true
;
: AdvSIMD-Scalar-2reg-misc   ( -- )
   AdvSIMD-Scalar-2reg-misc-ints    if  exit  then
   AdvSIMD-Scalar-2reg-misc-floats  if  exit  then
   invalid-op
;

: AdvSIMD-across-lanes-same   ( -- found? )
   29 1bit 5 <<  12 5bits or  ( u.op )
   case
      b# 001010 of   ." smaxv"     endof
      b# 011010 of   ." sminv"     endof
      b# 011011 of   ." addv"      endof
      b# 101010 of   ." umaxv"     endof
      b# 111010 of   ." uminv"     endof
      drop false exit
   endcase
   regszq .same-x2regs
   true
;
: AdvSIMD-across-lanes-float   ( -- found? )
   29 1bit 5 <<  12 5bits or  ( u.op )
   case
      b# 101100 of   23 1bit if  ." fminnmv"  else  ." fmaxnmv" then  endof
      b# 101111 of   23 1bit if  ." fmin"     else  ." fmax"    then  endof
      drop false exit
   endcase
   op-col .Sd, .Vn.4s 
   true
;
: AdvSIMD-across-lanes-long   ( -- found? )
   29 1bit 5 <<  12 5bits or  ( u.op )
   case
      b# 000011 of   ." saddlv"    endof
      b# 100011 of   ." uaddlv"    endof
      drop false exit
   endcase
   regszq .long-x2regs
   true
;
: AdvSIMD-across-lanes   ( -- )
   AdvSIMD-across-lanes-long if exit then
   AdvSIMD-across-lanes-float if exit then
   AdvSIMD-across-lanes-same if exit then
   invalid-op
;
: AdvSIMD-ZIP/UZP/TRN   ( -- )
   12 3bits
   case
      1 of   ." uzp1"   endof
      2 of   ." trn1"   endof
      3 of   ." zip1"   endof
      5 of   ." uzp2"   endof
      6 of   ." trn2"   endof
      7 of   ." zip2"   endof
      invalid-op
   endcase
   regszq .same-v3regs
;

: shift>imm   ( bits -- n )
   dup h# 40 and if  0x40 swap h# 3f and -  exit  then
   dup h# 20 and if  0x20 swap h# 1f and -  exit  then
   dup h# 10 and if  0x10 swap h# 0f and -  exit  then
   dup h# 08 and if  0x08 swap h# 07 and -  exit  then
   ." invalid shift "
;
: AdvSIMD-shift-imm   ( -- )
   29 1bit 5 <<  11 5bits or  ( u.op )
   case
      b# 000000 of  ." sshr"     endof
      b# 000010 of  ." ssra"     endof
      b# 000100 of  ." srshr"    endof
      b# 000110 of  ." srsra"    endof
      b# 001010 of  ." sshl"     endof
      b# 001110 of  ." sqshl"    endof
      b# 010000 of  ." shrn"     endof
      b# 010001 of  ." rshrn"    endof
      b# 010010 of  ." sqshrn"   endof
      b# 010011 of  ." sqrshrn"  endof
      b# 010100 of  ." sshll"    endof
      b# 011100 of  ." scvtf"    endof
      b# 011111 of  ." fcvtzs"   endof
      b# 100000 of  ." ushr"     endof
      b# 100010 of  ." usra"     endof
      b# 100100 of  ." urshr"    endof
      b# 100110 of  ." ursra"    endof
      b# 101000 of  ." sri"      endof
      b# 101010 of  ." sli"      endof
      b# 101100 of  ." sqshlu"   endof
      b# 101110 of  ." uqshl"    endof
      b# 110000 of  ." sqshrun"  endof
      b# 110001 of  ." sqrshrun" endof
      b# 110010 of  ." uqshrn"   endof
      b# 110011 of  ." uqrshrn"  endof
      b# 110100 of  ." ushll"    endof
      b# 111100 of  ." ucvtf"    endof
      b# 111111 of  ." fcvtzu"   endof
      invalid-op
   endcase
   regszq .same-v2regs .,
   d# 16 7bits shift>imm .imm
;
: AdvSIMD-scalar-shift-imm   ( -- )
   29 1bit 5 <<  11 5bits or  ( u.op )
   case
      b# 000000 of  ." sshr"     endof
      b# 000010 of  ." ssra"     endof
      b# 000100 of  ." srshr"    endof
      b# 000110 of  ." srsra"    endof
      b# 001010 of  ." sshl"     endof
      b# 001110 of  ." sqshl"    endof
      b# 010010 of  ." sqshrn"   endof
      b# 010011 of  ." sqrshrn"  endof
      b# 011100 of  ." scvtf"    endof
      b# 011111 of  ." fcvtzs"   endof
      b# 100000 of  ." ushr"     endof
      b# 100010 of  ." usra"     endof
      b# 100100 of  ." urshr"    endof
      b# 100110 of  ." ursra"    endof
      b# 101000 of  ." sri"      endof
      b# 101010 of  ." sli"      endof
      b# 101100 of  ." sqshlu"   endof
      b# 101110 of  ." uqshl"    endof
      b# 110000 of  ." sqshrun"  endof
      b# 110001 of  ." sqrshrun" endof
      b# 110010 of  ." uqshrn"   endof
      b# 110011 of  ." uqrshrn"  endof
      b# 110100 of  ." ushll"    endof
      b# 111100 of  ." ucvtf"    endof
      b# 111111 of  ." fcvtzu"   endof
      invalid-op
   endcase
   regszq .same-s2regs .,
   d# 16 7bits shift>imm .imm
;

: AdvSIMD-scalar-pairwise   ( -- )
   29 1bit 6 <<  12 5bits or  ( u.op )
   dup b# 00.11011 = if   ." addp"  drop 
   else
      23 1bit 5 << or  ( usz.op )
      case
	 b# 10.01100 of   ." fmaxnmp"  endof
	 b# 10.01101 of   ." faddp"    endof
	 b# 10.01111 of   ." fmaxp"    endof
	 b# 11.01100 of   ." fminnmp"  endof
	 b# 11.01111 of   ." fminp"    endof
	 invalid-op
      endcase
   then
   op-col
   22 1bit if
      .Dd, .Vn.2d
   else
      .Sd, .Vn.2s
   then
;

: AdvSIMD-EXT   ( -- )
   22 2bits if  invalid-op  exit  then
   ." ext"  op-col 
   30 1bit if
      .Vd.16b, .Vn.16b, .Vm.16b,  11 4bits .imm
   else
      .Vd.8b, .Vn.8b, .Vm.8b,  11 3bits .imm
   then
;

: .Vn+.8b    ( n -- )   rn + Vreg .r# .".8b"  ;
: .Vn+.16b   ( n -- )   rn + Vreg .r# .".16b"  ;
: AdvSIMD-TBL/TBX   ( -- )
   22 2bits if  invalid-op  exit  then
   12 1bit " tbltbx" 3 .txt   op-col
   30 1bit if
      .Vd.16b, .{ .Vn.16b
      13 2bits
      case
	 1 of  ., 1 .Vn+.16b                              endof
	 2 of  ., 1 .Vn+.16b ., 2 .Vn+.16b                endof
	 3 of  ., 1 .Vn+.16b ., 2 .Vn+.16b ., 3 .Vn+.16b  endof
      endcase
      .} ., .Vm.16b  
   else
      .Vd.8b, .{ .Vn.8b
      13 2bits
      case
	 1 of  ., 1 .Vn+.8b                            endof
	 2 of  ., 1 .Vn+.8b ., 2 .Vn+.8b               endof
	 3 of  ., 1 .Vn+.8b ., 2 .Vn+.8b ., 3 .Vn+.8b  endof
      endcase
      .} ., .Vm.8b  
   then
;
: .index   ( n -- ) base @ >r decimal  ." [" 1 .r ." ]"  r> base ! ;
: .copy-1index-regs   ( -- )
   op-col  16 5bits
   dup 1 and if   .Vd.b  1 >> .index ., .Wn  exit  then
   dup 2 and if   .Vd.h  2 >> .index ., .Wn  exit  then
   dup 4 and if   .Vd.s  3 >> .index ., .Wn  exit  then
   dup 8 and if   .Vd.d  4 >> .index ., .Xn  exit  then
   drop invalid-regs
;
: .copy-2index-regs   ( -- )
   op-col  16 5bits
   dup 1 and if   .Vd.b  1 >> .index ., .Vn.b  11 4bits .index  exit  then
   dup 2 and if   .Vd.h  2 >> .index ., .Vn.h  12 3bits .index  exit  then
   dup 4 and if   .Vd.s  3 >> .index ., .Vn.s  13 2bits .index  exit  then
   dup 8 and if   .Vd.d  4 >> .index ., .Vn.d  14 1bit  .index  exit  then
   drop invalid-regs
;
: .dup-1index-regs   ( -- )
   op-col  16 5bits
   dup 1 and if   30 1bit if  .Vd.16b,  else  .Vd.8b,  then  .Vn.b  1 >> .index  exit  then
   dup 2 and if   30 1bit if  .Vd.8h,   else  .Vd.4h,  then  .Vn.h  2 >> .index  exit  then
   dup 4 and if   30 1bit if  .Vd.4s,   else  .Vd.2s,  then  .Vn.s  3 >> .index  exit  then
   dup 8 and if   30 1bit if  .Vd.2d,                        .Vn.d  4 >> .index  exit  then then
   drop invalid-regs
;
: .dup-regs   ( -- )
   op-col  16 5bits
   dup 1 and if   30 1bit if  .Vd.16b,  else  .Vd.8b,  then  .Wn  drop exit  then
   dup 2 and if   30 1bit if  .Vd.8h,   else  .Vd.4h,  then  .Wn  drop exit  then
   dup 4 and if   30 1bit if  .Vd.4s,   else  .Vd.2s,  then  .Wn  drop exit  then
   dup 8 and if   30 1bit if  .Vd.2d,                        .Xn  drop exit  then then
   drop invalid-regs
;

: .umov   ( -- )
   op-col  16 5bits
   dup 1 and if 30 1bit if invalid-regs else .wd, then .Vn.b 1 >> .index exit then
   dup 2 and if 30 1bit if invalid-regs else .wd, then .Vn.h 2 >> .index exit then
   dup 4 and if 30 1bit if invalid-regs else .wd, then .Vn.s 3 >> .index exit then
   dup 8 and if 30 1bit if .xd, .Vn.d  4 >> .index exit else invalid-regs then then
   drop invalid-regs
;
: .smov   ( -- )
   op-col  16 5bits
   dup 1 and if 30 1bit if .xd, else .wd, then .Vn.b 1 >> .index exit then
   dup 2 and if 30 1bit if .xd, else .wd, then .Vn.h 2 >> .index exit then
   dup 4 and if 30 1bit if .xd, else .wd, then .Vn.s 3 >> .index exit then
   dup 8 and if 30 1bit if .xd, .Vn.d  4 >> .index exit else invalid-regs then then
   drop invalid-regs
;

: AdvSIMD-dot   ( -- )
   29 1bit if  ." udot"  else  ." sdot"  then
   regszq case
      4 of  .dd.2s, .dn.8b,  .dm.8b    endof
      5 of  .qd.4s, .qn.16b, .qm.16b   endof
      invalid-regs drop exit
   endcase
   
;
: AdvSIMD-dotelem   ( -- )
   29 1bit if  ." udot"  else  ." sdot"  then
   regszq case
      4 of  .dd.2s, .dn.8b,  .vm.b   endof
      5 of  .qd.4s, .qn.16b, .vm.b   endof
      invalid-regs drop exit
   endcase
   11 1bit 2* 21 1bit or  .index   
;

: AdvSIMD-copy   ( -- )
   29 1bit if  ." ins "  .copy-2index-regs exit  then
   11 4bits ( imm4 )
   case
      b# 0000 of  ." dup"   .dup-1index-regs    endof
      b# 0001 of  ." dup"   .dup-regs           endof
      b# 0011 of  ." ins"   .copy-1index-regs   endof
      b# 0101 of  ." smov"  .smov    endof
      b# 0111 of  ." umov"  .umov    endof
      invalid-op
   endcase
;


: .dup-scalar-index-regs   ( -- )
   op-col  16 5bits
   dup 1 and if   .Bd,  .Vn.b  1 >> .index  exit  then
   dup 2 and if   .Hd,  .Vn.h  2 >> .index  exit  then
   dup 4 and if   .Sd,  .Vn.s  3 >> .index  exit  then
   dup 8 and if   .Dd,  .Vn.d  4 >> .index  exit  then
   drop invalid-regs
;
: AdvSIMD-scalar-copy   ( -- )
   29 1bit  11 4bits or  if  invalid-op  exit  then
   ." dup"   .dup-scalar-index-regs
;

: h-bit     ( -- n )   11 1bit  ;
: hl-bits   ( -- n )   11 1bit 2*  21 1bit  or  ;
: hlm-bits  ( -- n )   11 1bit 2 <<  20 2bits  or  ;
: .long-xi3regs   ( szq -- )
   case
      b# 010 of  .Vd.4s, .Vn.4h, .Vm4.h hlm-bits .index  endof
      b# 011 of  .Vd.4s, .Vn.8h, .Vm4.h hlm-bits .index  endof
      b# 100 of  .Vd.2d, .Vn.2s, .Vm.s  hl-bits  .index  endof
      b# 101 of  .Vd.2d, .Vn.4s, .Vm.s  hl-bits  .index  endof
      invalid-regs
   endcase
;
: .same-xi3regs   ( szq -- )
   case
      b# 010 of  .Vd.4h, .Vn.4h, .Vm4.h hlm-bits .index  endof
      b# 011 of  .Vd.8h, .Vn.8h, .Vm4.h hlm-bits .index  endof
      b# 100 of  .Vd.2s, .Vn.2s, .Vm.s  hl-bits  .index  endof
      b# 101 of  .Vd.4s, .Vn.4s, .Vm.s  hl-bits  .index  endof
      invalid-regs
   endcase
;
: .fp-xi3regs   ( szq -- )
   case
      b# 100 of  .Vd.2s, .Vn.2s, .Vm.s hl-bits .index  endof
      b# 101 of  .Vd.4s, .Vn.4s, .Vm.s hl-bits .index  endof
      b# 111 of  .Vd.2d, .Vn.2d, .Vm.d h-bit   .index  endof
      invalid-regs
   endcase
;
0 [if]
: .complex-xi3regs   ( qszhl -- )
   case
      b# 00100 of  .Vd.4h, .Vn.4h, .Vm4.h  0 .index  endof
      b# 00101 of  .Vd.4h, .Vn.4h, .Vm4.h  1 .index  endof
      b# 00110 of  .Vd.4h, .Vn.4h, .Vm4.h  2 .index  endof
      b# 00111 of  .Vd.4h, .Vn.4h, .Vm4.h  3 .index  endof

      b# 01000 of  .Vd.2s, .Vn.2s, .Vm.s   0 .index  endof
      b# 01001 of  .Vd.2s, .Vn.2s, .Vm.s   1 .index  endof

      b# 10100 of  .Vd.8h, .Vn.8h, .Vm4.h  0 .index  endof
      b# 10101 of  .Vd.8h, .Vn.8h, .Vm4.h  1 .index  endof
      b# 10110 of  .Vd.8h, .Vn.8h, .Vm4.h  2 .index  endof
      b# 10111 of  .Vd.8h, .Vn.8h, .Vm4.h  3 .index  endof

      b# 101 of  .Vd.4s, .Vn.4s, .Vm.s  h-bit   .index  endof
      invalid-regs
   endcase
;
[then]

: AdvSIMD-X-index-long   ( -- found? )
   29 1bit 4 <<  12 4bits or  ( u.op )
   case
      b# 00010 of   ." smlal"     endof
      b# 00011 of   ." sqdmlal"   endof
      b# 00110 of   ." smlsl"     endof
      b# 00111 of   ." sqdmlsl"   endof
      b# 01010 of   ." smull"     endof
      b# 01011 of   ." sqdmull"   endof
      b# 11010 of   ." umull"     endof
      b# 10010 of   ." umlal"     endof
      b# 10110 of   ." umlsl"     endof
      drop false exit
   endcase
   30 1bit if  ." 2"  then
   regszq .long-xi3regs
   true
;

\ : regqszhl  ( -- qszhl )   op-col  30 1bit 4 << 22 2 bits 2 << or 11 1bit 2* or 21 1 bit or  ;
: AdvSIMD-complex-index-same   ( -- found? )
   ." fcmla"
   \   regqszhl .complexe-xi3regs
   regszq .same-xi3regs
   ." , #" 13 2bits 90 * .d
   true
;
: AdvSIMD-X-index-same   ( -- found? )
   29 1bit 4 <<  12 4bits or  ( u.op )
   dup 0x19 and 0x11 = if
      drop AdvSIMD-complex-index-same exit
   then   ( u.op )
   case
      b# 01000 of   ." mul"       endof
      b# 01100 of   ." sdqmulh"   endof
      b# 01101 of   ." sqrdmulh"  endof
      b# 10000 of   ." mla"       endof
      b# 10100 of   ." mls"       endof
      drop false exit
   endcase
   regszq .same-xi3regs
   true
;
: AdvSIMD-X-index-float   ( -- found? )
   23 1bit 0= if  false  exit  then
   29 1bit 4 <<  12 4bits or  ( u.op )
   case
      b# 00001 of   ." fmla"       endof
      b# 00101 of   ." fmls"       endof
      b# 01001 of   ." fmul"       endof
      b# 11001 of   ." fmulx"      endof
      drop false exit
   endcase
   regszq .fp-xi3regs
   true
;
: AdvSIMD-X-index-element
   AdvSIMD-X-index-long   if  exit  then
   AdvSIMD-X-index-same   if  exit  then
   AdvSIMD-X-index-float  if  exit  then
   invalid-op
;
: .s-long-xi3regs   ( sz -- )
   case
      b# 01 of  .Sd, .Hn, .Vm4.h hlm-bits .index  endof
      b# 10 of  .Dd, .Sn, .Vm.s  hl-bits  .index  endof
      invalid-regs
   endcase
;
: .s-same-xi3regs   ( sz -- )
   case
      b# 01 of  .Hd, .Hn, .Vm4.h hlm-bits .index  endof
      b# 10 of  .Sd, .Sn, .Vm.s  hl-bits  .index  endof
      invalid-regs
   endcase
;
: .s-fp-xi3regs   ( szs -- )
   case
      0 of  .Sd, .Sn, .Vm.s  hl-bits .index  endof
      1 of  .Dd, .Dn, .Vm.d  h-bit   .index  endof
      invalid-regs
   endcase
;
: AdvSIMD-scalar-x-index-long   ( -- found? )
   29 1bit 4 <<  12 4bits or  ( u.op )
   case
      b# 00011 of   ." sqdmlal"   endof
      b# 00111 of   ." sqdmlsl"   endof
      b# 01011 of   ." sqdmull"   endof
      drop false exit
   endcase
   regsz .s-long-xi3regs
   true
;
: AdvSIMD-scalar-x-index-same   ( -- found? )
   29 1bit 4 <<  12 4bits or  ( u.op )
   case
      b# 01100 of   ." sdqmulh"   endof
      b# 01101 of   ." sqrdmulh"  endof
      drop false exit
   endcase
   regszq .s-same-xi3regs
   true
;
: AdvSIMD-scalar-X-index-float   ( -- found? )
   23 1bit 0= if  false exit  then
   29 1bit 4 <<  12 4bits or  ( u.op )
   case
      b# 00001 of   ." fmla"       endof
      b# 00101 of   ." fmls"       endof
      b# 01001 of   ." fmul"       endof
      b# 11001 of   ." fmulx"      endof
      drop false exit
   endcase
   regz .s-fp-xi3regs
   true
;
: AdvSIMD-scalar-index-elem
   AdvSIMD-scalar-x-index-long   if  exit  then
   AdvSIMD-scalar-x-index-same   if  exit  then
   AdvSIMD-scalar-x-index-float  if  exit  then
   invalid-op
;

: Crypto-3SHA   ( -- )
   22 2bits if  invalid-op exit  then   \ sz must be 00
   12 3bits
   case
      0 of   ." sha1c"       endof
      1 of   ." sha1p"       endof
      2 of   ." sha1m"       endof
      3 of   ." sha1su0"     endof
      4 of   ." sha256h"     endof
      5 of   ." sha256h2"    endof
      6 of   ." sha256su1"   endof
      invalid-op
   endcase
   op-col  12 3bits .sha-3regs
;

: Crypto-2SHA   ( -- )
   22 2bits if  invalid-op exit  then   \ sz must be 00
   12 5bits
   case
      0 of   ." sha1h"       endof
      1 of   ." sha1su1"     endof
      2 of   ." sha256su0"   endof
      invalid-op
   endcase
   op-col  12 5bits .sha-2regs
;

: Crypto-AES   ( -- )
   22 2bits if  invalid-op exit  then   \ sz must be 00
   12 5bits
   case
      4 of   ." aese"    endof
      5 of   ." aesd"    endof
      6 of   ." aesmc"   endof
      7 of   ." aesimc"  endof
      invalid-op
   endcase
   op-col  1 .same-v2regs
;
: Crypto-4reg   ( -- )
   21 2bits
   case
      0 of   ." eor3"    endof
      1 of   ." bcax"    endof
      invalid-op
   endcase
   op-col  .Vd.16b, .Vn.16b, .Vm.16b, .Va.16b
;


: AdvSIMD-mmla   ( -- )
   11 1bit if  ." usmmla"  else  29 1bit if  ." ummla"  else  ." smmla"  then then
   op-col  .Vd.4s, .Vn.16b, .Vm.16b
;
: AdvSIMD-usdot   ( -- )
   instruction@ 0xBFE0.FC00 and 0x0E80.9C00 = if
      ." usdot" op-col  .Vd.4s, .Vn.16b, .Vm.16b
      exit
   then
   instruction@ 0xBF40.F400 and 0x0F00.F000 <> if  invalid-op  exit  then

   23 1bit if  ." usdot"  else  ." sudot"  then
   op-col
   30 1bit if
      .Vd.4s, .Vn.16b,
   else
      .Vd.2s, .Vn.8b,
   then
   .Vm ." .4b "
   11 1bit 2* 21 1bit or .index
;
