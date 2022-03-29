\ branching

\
\ br-target
\
\ This word will calculate one of two values:
\ 1) A destination address in absolute space
\ 2) A destination address relative to the current location
\ The user specifies which by either preceding the target address
\ with a $ (case 2) or not (case 1).
\

: br-target  ( -- n )
   "L#"? if
      \ Make a local string with the next word of input to contain:
      \ 'user <next-word>
      " L#                                   "  2dup 2 /string blank over 3 +
      <c  scantobl  c>
      rot swap cmove eval
      drop  \ Drop the adt-type
      exit
   then
   "*"?  if  ival@ exit  then
   "$"?  dup                ( flag flag )   \ Relative?
   if                       ( true )
      "+"?  if  false else  ( true false )  \ Relative branch, do not negate offset
      "-"?  if  true  else  ( true true )   \ Relative branch, negate offset
                false then  ( true false )  \ Relative branch, do not negate offset
      then
   else
      false                 ( false false ) \ Absolute address, do not negate
   then
   snimm                   ( flag flag N ) \ either target or offset
   swap if  negate  then    ( flag N )      \ negate?
   swap if  here +  then    ( N )           \ relative?
;


\ =======================================
\
\    Unconditional Branch Register Instructions
\
\ =======================================

: ret-try  ( idx -- )   \ RET {Xn}
   case 
      0 of     Xn endof
      1 of 30 ^Rn endof
   endcase
;


\ =======================================
\
\    Relative Branches & Relative Address Calculation
\
\ =======================================

\
\ NOTE: this architecture does not support 64 bit branch offsets
\

: ?aligned-branch  ( 32bit-target #bits -- n-bit-offset )
   over 3 and " a 4 byte aligned branch target" ?expecting
   swap here - 2 >>  \ Convert a target into an offset

   \ Test that the offset +/- fits within the supplied #bits
   ( #bits 32bit-offset ) 2dup sext swap 1- >>a
   dup -1 =  swap  0=  or  0=
   " WARNING: Branch target is too far away: " ?error
   \ dup -1 =  swap  0=  or  0=  if
   \    ." WARNING: Branch target is too far away: " .where  cr
   \ then

   \ It fits, continue.
   ( #bits 32bit-offset ) swap mask and
;

: %uncond-br-imm   ( op -- )
   >r  <asm  r> iop   \ pick up ival
   br-target  26 ?aligned-branch  0 26 ^^op   asm>
;

: %cmp-br-imm  ( op regs -- )
   <asm  rd, rd??  iop  set-sf?  br-target
   19 ?aligned-branch   5 19 ^^op
   asm>
;

: ^tst-br-imm  ( target bit# op -- )
   swap dup 5 >>  xd? 0=  if
      dup  " one of 32 bits to be tested with W register type" ?expecting
   then
   ( b5 )    31 1 ^^op
   0x36000000 iop
   swap      24 1 ^^op
   5 mask and  \ Mask off b5 which was placed up above
   ( b0-b4 ) 19 5 ^^op
   14 ?aligned-branch   ( simm14)
   5 14 ^^op
;


\ =======================================
\
\   Branch Logic
\
\ =======================================

: >br-offset  ( to from -- 19bit-offset ) 
   - 2 >>a dup 19 mask andc 19 >>a
   dup -1 = swap 0 = or 0= " a 19 bit relative branch" ?expecting
   19 mask and 5 <<
;

: >br-offset14  ( to from -- 14bit-offset ) 
   - 2 >>a dup 14 mask andc 14 >>a
   dup -1 = swap 0 = or 0= " a 14 bit relative branch" ?expecting
   14 mask and
;

: >br-offset21  ( to from -- 21bit-offset ) 
   - 2 >>a dup 21 mask andc 21 >>a
   dup -1 = swap 0 = or 0= " a 21 bit relative branch" ?expecting
   21 mask and
;

: >br-offset26  ( to from -- 26bit-offset ) 
   - 2 >>a dup 26 mask andc 26 >>a
   dup -1 = swap 0 = or 0= " a 26 bit relative branch" ?expecting
   26 mask and
;

: put-helper  ( target where op -- opcode )
   opcode >r
   is opcode   tuck   ( where target where )
   >br-offset26  0 26 ^^op    ( where )
   opcode swap asm!
   r> is opcode
;
\ moved into code.fth
\ : put-call    ( target where -- )  0x94000000 put-helper  ;
\ : put-branch  ( target where -- )  0x14000000 put-helper  ;


\ Create a building word to make creating the branches easy

: ^cond-br-imm  ( cond br-target  -- )
   19 ?aligned-branch
   0x54000000 iop
   ( simm19 ) 5 19 ^^op
   ( cond )   0 5     ^^op
;
: B.cond  ( cond -- )  >r  <asm  r>  br-target  ^cond-br-imm  asm>  ;
: B:  ( -- )  create , does> @ B.cond ;


