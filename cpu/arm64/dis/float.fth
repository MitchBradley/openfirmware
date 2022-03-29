\ Floating point

: FP-cond-select  ( -- )
    ." fcsel"   op-col
   22 2bits
   case
      0 of .Sd, .Sn, .Sm,  endof
      1 of .Dd, .Dn, .Dm,  endof
      3 of .Hd, .Hn, .Hm,  endof
      unimpl ."  fcsel" drop exit
   endcase
   12 4bits .cond
;

: FP-cond-compare  ( -- )
   ." fccmp" 4 1bit if  ." e"  then
   op-col
   22 1bit if   .Dn, .Dm,  else  .Sn, .Sm,  then
   0 4bits .imm,  12 4bits .cond
;

: .f8imm  ( fimm8 -- )
   \ Print the 8 bit immediate value n as an immediate value after it's been converted
   \ to floating point
   dup 0x80 and  if  ." -"  then
   dup 0x70 and  4 >>  ( encoded-exponent )

   \ Possible exponential values are a encoded as a 3 digit binary number
   \ but They are expanded into an 8 bit (for 32 bit FP numbers) or an 11
   \ bit (for 64 bit DP numbers).  The expansion rules are:
   \   Take the highest bit and invert it.
   \   Take the highest bit and repeat it 8 (or 11) - 3 times (-1 for the
   \             inverted place, and 2 for the trailing bits).
   \   Take the low order two bits and append them.

   \ The resulting value is expressed as "Excess of 127" meaning that the
   \ value 127 == an exponent of 0.  However, the encoding represents 127
   \ as 7.  The following table shows the relationship between the encoding
   \ (left column) the 8 bit representation in the actual floating point
   \ register, and the semantic meaning in terms of the exponent of the
   \ number including a "hidden" bit in the mantissa:

   \   000 == 1_<0000>_00  = exponent of 1
   \   001 == 1_<0000>_01  = exponent of 2
   \   010 == 1_<0000>_10  = exponent of 3
   \   011 == 1_<0000>_11  = exponent of 4
   \   100 == 0_<1111>_00  = exponent of -3
   \   101 == 0_<1111>_01  = exponent of -2
   \   110 == 0_<1111>_10  = exponent of -1
   \   111 == 0_<1111>_11  = exponent of 0

   \ The mantissa (the low order 4 bits of the encoded imm8 value) is a 5
   \ bit number where the highest order bit value is implied, and is the
   \ sum of five of the following values starting with the number whose
   \ exponent matches the exponent represented by the encoded value (see
   \ above).  The first of the five values is always used because it
   \ matches the implied ("hidden") 1 bit not expressed in the mantissa.
   \ Then, the next four values are used depending on the presence of 1
   \ bits in the low 4 bits of the imm8 value.

   \  4 = 16.0_000_000
   \  3 =  8.0_000_000
   \  2 =  4.0_000_000
   \  1 =  2.0_000_000
   \  0 =  1.0_000_000
   \ -1 =   .5_000_000
   \ -2 =   .2_500_000
   \ -3 =   .1_250_000
   \ -4 =   .0_625_000
   \ -5 =   .0_312_500
   \ -6 =   .0_156_250
   \ -7 =   .0_078_125

   ( encoded-exponent ) case
      3 of  d# 160000000  endof
      2 of  d#  80000000  endof
      1 of  d#  40000000  endof
      0 of  d#  20000000  endof
      7 of  d#  10000000  endof
      6 of  d#  05000000  endof
      5 of  d#  02500000  endof
      4 of  d#  01250000  endof
   endcase
   dup >R   \ Keep the sum on the return stack, data stack has the shifting bit value
   ( imm8 N  R: sum )
   2/ over 8 and  if  dup R> + >R  then
   2/ over 4 and  if  dup R> + >R  then
   2/ over 2 and  if  dup R> + >R  then
   2/ over 1 and  if  dup R> + >R  then
   ( fimm8 N ) 2drop
   R> 0
   [char] # emit
   push-decimal
   <# # # #  # # #  # [char] . hold #s #>
   type space
   pop-base
;
      

: FP-imm
   \ instruction@ h# e000.0000 and  23 1bit or  5 5bits or if  invalid-op exit  then
   ." fmov"  op-col
   22 1bit if   .Dd,  else  .Sd,  then
   13 8bits .f8imm
;


\ =======================================
\
\  Floating point Data processing
\
\ =======================================

\ 1e204000


: .fcvt-regs 
    op-col
     d# 22 2bits  ( type )
     2 <<
     d# 15 2bits  ( opc )
     or     \ combine
     ( TTOO )
     case
        b# 0001 of .Dd, .Sn endof \ Single-precision to double-precision (type = 00 && opc = 01) FCVT <Dd>, <Sn>
        b# 0011 of .Hd, .Sn endof \ Single-precision to half-precision   (type = 00 && opc = 11) FCVT <Hd>, <Sn>
        b# 0100 of .Sd, .Dn endof \ Double-precision to single-precision (type = 01 && opc = 00) FCVT <Sd>, <Dn>
        b# 0111 of .Hd, .Dn endof \ Double-precision to half-precision   (type = 01 && opc = 11) FCVT <Hd>, <Dn>
        b# 1100 of .Sd, .Hn endof \ Half-precision   to single-precision (type = 11 && opc = 00) FCVT <Sd>, <Hn>
        b# 1101 of .Dd, .Hn endof \ Half-precision   to double-precision (type = 11 && opc = 01) FCVT <Dd>, <Hn>
	    unimpl ." .FP-data-proc-1-regs  " drop exit
    endcase
    ;
             

: FP-data-proc-common
   22 2bits 3 =
   IF
      ." 16" op-col  .hd, .hn, .hm exit
   THEN
   op-col
   22 1bit
   IF
      .Dd, .Dn, .Dm
   ELSE
      .Sd, .Sn, .Sm
   THEN
    ;
        
: FP-data-proc-common-1
   22 2bits 3 =
   IF
      ." 16" op-col  .hd, .hn exit
   THEN
   op-col
   22 1bit
   IF
      .Dd, .Dn 
   ELSE
      .Sd, .Sn 
   THEN
    ;

: FP-data-proc-1
   31 1bit if  unimpl exit  then    ( M BIT 31 MUST BE 0 )
   29 1bit if  unimpl exit  then    ( S BIT 29 MUST BE 0 )
   15 6bits 
   case
      0  of  ." fmov"     endof
      1  of  ." fabs"     endof
      2  of  ." fneg"     endof
      3  of  ." fsqrt"    endof
      4  of  ." fcvt" .fcvt-regs exit endof
      5  of  ." fcvt" .fcvt-regs exit endof
      7  of  ." fcvt" .fcvt-regs exit endof
      8  of  ." frintn"   endof
      9  of  ." frintp"   endof
      10  of  ." frintm"  endof
      11  of  ." frintz"  endof
      12  of  ." frinta"  endof
      14  of  ." frintx"  endof
      15  of  ." frinti"  endof
	 unimpl ." FP-data-proc-1 " drop exit
   endcase
    FP-data-proc-common-1
    ;
 


: FP-data-proc-2
   31 1bit if  unimpl exit  then    ( M BIT 31 MUST BE 0 )
   29 1bit if  unimpl exit  then    ( S BIT 29 MUST BE 0 )
   
   instruction@ h# 9000 AND h# 9000 = if  unimpl exit  then
   instruction@ h# A000 AND h# A000 = if  unimpl exit  then
   instruction@ h# C000 AND h# C000 = if  unimpl exit  then
   
   12 4bits 
   case
      0  of  ." fmul"  endof
      1  of  ." fdiv"  endof
      2  of  ." fadd"  endof
      3  of  ." fsub"  endof
      4  of  ." fmax"  endof
      5  of  ." fmin"  endof
      6  of  ." fmaxnm"  endof
      7  of  ." fminnm"  endof
      8  of  ." fnmul"  endof
	 unimpl ." FP-data-proc-2 " drop exit
   endcase
    FP-data-proc-common
    ;


: .FP-data-proc-3
   22 2bits 3 =
   IF
      ." 16" op-col  .hd, .hn, .hm, .ha exit
   THEN
   op-col
   22 1bit
   IF
      .Dd, .Dn, .Dm, .Da
   ELSE
      .Sd, .Sn, .Sm, .Sa
   THEN
;
: FP-data-proc-3
   31 1bit if  unimpl exit  then    ( M BIT 31 MUST BE 0 )
   29 1bit if  unimpl exit  then    ( S BIT 29 MUST BE 0 )
   
   \ merge o1[21]:o0[15]
   instruction@
   dup 
   d# 15 >> 1 and   ( op o0 )
   swap
   ( op o0 op )
   d# 20 >> 2 and ( op o0 o1 ) or
   ( op o1:o0 )
   case
      0  of  ." fmadd"  endof
      1  of  ." fmsub"  endof
      2  of  ." fnmadd"  endof
      3  of  ." fnmsub"  endof
	 unimpl ." FP-data-proc-3 " drop exit
   endcase
    .FP-data-proc-3
    ;


\ =======================================
\
\  Floating-point<->fixed-point conversions
\
\ =======================================

: FP<>FixedPt-cvt 
   29 1bit if  unimpl exit  then    ( S BIT 29 MUST BE 0 )
   23 1bit if  unimpl exit  then    ( type[23:22] must be 'b0x )
   18 1bit if  unimpl exit  then    ( opcode[18] must be 0 )
   
   instruction@ h# 000e0000 AND 0=            if  unimpl exit  then
   instruction@ h# 000e0000 AND h# 000A0000 = if  unimpl exit  then
   instruction@ h# 00160000 AND 0=            if  unimpl exit  then
   instruction@ h# 00160000 AND h# 00120000 = if  unimpl exit  then
   
   \ this must be a documentation issue!!!
   \ all ops of scale field=zer0
   \ so this condition always indicate unallocated
   
   \ instruction@ h# 80008000 AND 0=            if  unimpl exit  then
   
   \ combine type:0:mode:opcode
   instruction@ d# 16 >> h# ff and
   dup h# 1f and
   ( all mode:opcode )
   swap
   1 >> h# 60 and or
   ( type:mode:opcode )
   
   instruction@ h# 80000000 and 0=
   IF                          \ 32bit       
      ( type:mode:opcode )
      case
	 b# 0000010  of  ." scvtf"   op-col .Sd, .Wn endof  \ 32-bit to single-precision
	 b# 0000011  of  ." ucvtf"   op-col .Sd, .Wn endof  \ 32-bit to single-precision
	 b# 0011000  of  ." fcvtzs"  op-col .Wd, .Sn endof  \ single-precision to 32-bit
	 b# 0011001  of  ." fcvtzu"  op-col .Wd, .Sn endof  \ single-precision to 32-bit
	 b# 0100010  of  ." scvtf"   op-col .Dd, .wn endof  \ 32-bit to double-precision
	 b# 0100011  of  ." ucvtf"   op-col .Dd, .wn endof  \ 32-bit to double-precision
	 b# 0111000  of  ." fcvtzs"  op-col .Wd, .Dn endof  \ double-precision to 32-bit
	 b# 0111001  of  ." fcvtzu"  op-col .Wd, .Dn endof  \ double-precision to 32-bit
	 unimpl ." FP<>FixedPt-cvt " drop exit
      endcase
   ELSE                        \ 64bit
      ( type:mode:opcode )
      case
	 b# 0000010  of  ." scvtf"   op-col .Sd, .Xn endof  \ 64-bit to single-precision
	 b# 0000011  of  ." ucvtf"   op-col .Sd, .Xn endof  \ 64-bit to single-precision 
	 b# 0011000  of  ." fcvtzs"  op-col .Xd, .Sn endof  \ single-precision to 64-bit
	 b# 0011001  of  ." fcvtzu"  op-col .Xd, .Sn endof  \ single-precision to 64-bit 
	 b# 0100010  of  ." scvtf"   op-col .Dd, .Xn endof  \ 64-bit to double-precision
	 b# 0100011  of  ." ucvtf"   op-col .Dd, .Xn endof  \ 64-bit to double-precision 
	 b# 0111000  of  ." fcvtzs"  op-col .Xd, .Dn endof  \ double-precision to 64-bit 
	 b# 0111001  of  ." fcvtzu"  op-col .Xd, .Dn endof  \ double-precision to 64-bit 
	 unimpl ." FP<>FixedPt-cvt " drop exit
      endcase
   THEN
   
;

: FP<>int-cvt 
\     29 1bit if  unimpl exit  then    ( S BIT 29 MUST BE 0 )
\     23 1bit if  unimpl exit  then    ( type[23:22] must be 'b0x )
\     18 1bit if  unimpl exit  then    ( opcode[18] must be 0 )
\     
\     instruction@ h# 000e0000 AND 0=            if  unimpl exit  then
\     instruction@ h# 000e0000 AND h# 000A0000 = if  unimpl exit  then
\     instruction@ h# 00160000 AND 0=            if  unimpl exit  then
\     instruction@ h# 00160000 AND h# 00120000 = if  unimpl exit  then
\     
\     \ this must be a documentation issue!!!
\     \ all ops of scale field=zer0
\     \ so this condition always indicate unallocated
\     
\     \ instruction@ h# 80008000 AND 0=            if  unimpl exit  then
\     
\     \ combine type:0:mode:opcode
    instruction@ d# 16 >> h# ff and
    dup h# 1f and
    ( all mode:opcode )
    swap h# c0 and 1 >> or
    ( type:mode:opcode )
    
    instruction@ h# 80000000 and 0=
    IF                          \ 32bit       
        ( type:mode:opcode )
        case
            b# 0000000  of  ." fcvtns"   op-col .Wd, .Sn endof  \ single-precision to 32-bit
            b# 0000001  of  ." fcvtnu"   op-col .Wd, .Sn endof  \ single-precision to 32-bit
            b# 0000010  of  ." scvtf"    op-col .Sd, .Wn endof  \ 32-bit to single-precision
            b# 0000011  of  ." ucvtf"    op-col .Sd, .Wn endof  \ 32-bit to single-precision
            b# 0000100  of  ." fcvtas"   op-col .Sd, .Wn endof 
            b# 0000101  of  ." fcvtau"   op-col .Sd, .Wn endof 
            b# 0000111  of  ." fmov"     op-col .Sd, .Wn endof
            b# 0000110  of  ." fmov"     op-col .Wd, .Sn endof 

            b# 0001000  of  ." fcvtps"   op-col .Sd, .Wn endof 
            b# 0001001  of  ." fcvtpu"   op-col .Sd, .Wn endof 

            b# 0010000  of  ." fcvtms"   op-col .Sd, .Wn endof 
            b# 0010001  of  ." fcvtmu"   op-col .Sd, .Wn endof 

            b# 0011000  of  ." fcvtzs"   op-col .Sd, .Wn endof 
            b# 0011001  of  ." fcvtzu"   op-col .Sd, .Wn endof 

            b# 0100000  of  ." fcvtns"   op-col .Wd, .Dn endof  \ double-precision to 32-bit
            b# 0100001  of  ." fcvtnu"   op-col .Wd, .Dn endof  \ double-precision to 32-bit
            b# 0100010  of  ." scvtf"    op-col .Dd, .Wn endof  \ 32-bit to double-precision
            b# 0100011  of  ." ucvtf"    op-col .Dd, .Wn endof  \ 32-bit to double-precision
            
            b# 1100110  of  ." fmov"     op-col .Wd, .Hn endof  \ Half-precision to 32-bit (sf = 0 && type = 11 && rmode = 00 && opcode = 110)
            b# 1100111  of  ." fmov"     op-col .Hd, .Wn endof  \ 32-bit to half-precision (sf = 0 && type = 11 && rmode = 00 && opcode = 111)
            
            unimpl ."  FP<>int-cvt" drop exit
        endcase
        exit
    ELSE                        \ 64bit
        ( type:mode:opcode )
        case
            b# 0000000  of  ." fcvtns"   op-col .Xd, .Sn endof  \ single-precision to 64-bit
            b# 0000001  of  ." fcvtnu"   op-col .Xd, .Sn endof  \ single-precision to 64-bit
            b# 0000010  of  ." scvtf"    op-col .Sd, .Xn endof  \ 64-bit to single-precision
            b# 0000011  of  ." ucvtf"    op-col .Sd, .Xn endof  \ 64-bit to single-precision
            b# 0100000  of  ." fcvtns"   op-col .Xd, .Dn endof  \ double-precision to 64-bit
            b# 0100001  of  ." fcvtnu"   op-col .Xd, .Dn endof  \ double-precision to 64-bit
            b# 0100010  of  ." scvtf"    op-col .Dd, .Xn endof  \ 64-bit to double-precision
            b# 0100011  of  ." ucvtf"    op-col .Dd, .Xn endof  \ 64-bit to double-precision

            b# 0100110  of  ." fmov"    op-col .Xd, .Dn endof   \ double-precision to 64-bit
            b# 0100111  of  ." fmov"    op-col .Dd, .Xn endof 

            b# 1001110  of  ." fmov"    op-col .Xd, .Vn ." .d[1]" endof   \ double-precision to 64-bit
            b# 1001111  of  ." fmov"    op-col .Vd ." .d[1], " .Xn endof


            b# 1100110  of  ." fmov"     op-col .Xd, .Hn endof  \ Half-precision to 64-bit (sf = 1 && type = 11 && rmode = 00 && opcode = 110)
            b# 1100111  of  ." fmov"     op-col .Hd, .Xn endof  \ 64-bit to half-precision (sf = 1 && type = 11 && rmode = 00 && opcode = 111)

            unimpl ."  FP<>int-cvt" drop exit
        endcase
        exit
    THEN
    unimpl exit
;

\ 1e202000
: FP-compare
   ." fcmp"  4 bit? if  ." e"  then
   op-col
   22 2bits
   case
      b# 00 of  .Sn, 3 1bit IF ." #0.0" ELSE .Sm THEN  endof
      b# 01 of  .Dn, 3 1bit IF ." #0.0" ELSE .Dm THEN  endof
      b# 11 of  .Hn, 3 1bit IF ." #0.0" ELSE .Hm THEN  endof
      unimpl ."  fcmp" drop exit
   endcase
;

: fjcvtzs   ( -- )
   ." fjcvtzs" op-col  .wd, .dn
;
: frintn#s   ( -- )
   ." frint"
   16 1bit if  ." 64" else  ." 32"  then
   15 1bit if  ." x" else  ." z"  then
   op-col
   22 1bit if
      .Dd, .Dn
   else
      .Sd, .Sn
   then
;
: frintn#v   ( -- )
   ." frint"
   12 1bit if  ." 64" else  ." 32"  then
   29 1bit if  ." x" else  ." z"  then
   op-col
   12 1bit if
      30 1bit if  .Vd.2d, .Vn.2d  else  .Vd.d ." ," .Vn.d  then
   else
      30 1bit if  .Vd.4s, .Vn.4s  else  .Vd.2s, .Vn.2s  then
   then
;

