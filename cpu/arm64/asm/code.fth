purpose: Defining words for code definitions
\ See license at end of file

decimal

only forth also definitions

\ make forth versions of these available in the assembler
alias *if      if
alias *else    else
alias *then    then
alias *=       =
alias *0=      0= 
alias *<>      <> 
alias *>=      >= 
alias *and     and
alias *or      or 

\ These words are specific to the virtual machine implementation
\ Later, we'll qualify this word with arm64\ or something so that
\ one can have the arm64-assembler on other ISAs without name
\ collision here
: assembler  ( -- )  arm64-assembler  ;

assembler helpers vocab-assembler
\ only forth also arm64-assembler also helpers also arm64-assembler also definitions


\ Forth Virtual Machine registers
\ Convenient register names for portable programming

regalias lp     x22
regalias org    x23
regalias up     x24
regalias tos    x25
regalias wtos   w25
regalias rp     x26
regalias ip     x27
regalias sp     x28
regalias sav    x29
regalias fp     x29


: asm-con:  ( n "name" -- )  create ,  does> @  ;

\ still in decimal
32\  4
64\  8
             asm-con:  1cell        \ Offsets into the stack
1cell   -1 * asm-con: -1cell
1cell   -1 * asm-con: ~1cell
1cell    2 * asm-con:  2cells
1cell    3 * asm-con:  3cells
1cell    4 * asm-con:  4cells
1cell    5 * asm-con:  5cells
1cell    6 * asm-con:  6cells
1cell    7 * asm-con:  7cells
1cell    8 * asm-con:  8cells
1cell    9 * asm-con:  9cells
1cell   10 * asm-con:  10cells
1cell   11 * asm-con:  11cells
1cell   12 * asm-con:  12cells
1cell   13 * asm-con:  13cells
1cell   14 * asm-con:  14cells
1cell   15 * asm-con:  15cells
1cell   16 * asm-con:  16cells
1cell   17 * asm-con:  17cells
1cell   18 * asm-con:  18cells
1cell   19 * asm-con:  19cells
1cell   20 * asm-con:  20cells
1cell   21 * asm-con:  21cells
1cell   22 * asm-con:  22cells
1cell   23 * asm-con:  23cells
1cell   24 * asm-con:  24cells
1cell   25 * asm-con:  25cells
1cell   26 * asm-con:  26cells
1cell   27 * asm-con:  27cells
1cell   28 * asm-con:  28cells
1cell   29 * asm-con:  29cells
1cell   30 * asm-con:  30cells
1cell   31 * asm-con:  31cells
1cell   32 * asm-con:  32cells

( Size of an ARM64 branch instruction )
4            asm-con:  /cf          \ Size of a code field
/cf     -1 * asm-con: -/cf

4            asm-con:  /token       \ Size of a compiled word reference
/token  -1 * asm-con: -/token

4            asm-con:  /branch      \ Size of a branch offset
4            asm-con:  /link        \ Ditto

/token    2* asm-con:  /ccf         \ Size of a "create" code field

\ The next few words are already in the forth vocabulary;
\ we want them in the assembler vocabulary too

: 'body   ( "name" -- variable-apf )  ' >body  ;
\ : 'offset ( "name" -- pg-offset-apf )
\    ' >body ( target ) origin- ( offset ) 12 mask land  ;
: 'code   ( "name" -- code-word-acf )
   '
[ifdef] itc
   token@   \ always skip token and point to code
[then]
   dup  asm@  0x910003ff *=  *if   \ Skip NOP at CFA of code word
      4 +
   *then
;
alias ''  'code
: 'user   ( "name" -- user# )  ' >body l@  ;
: 'user#  ( "name" -- user# )  'user  ;

\ 'user is intended to be used with ldr/str instruction.
\ However, for completeness, this code should verify that the instruction it's
\ modifying really is the ldr or str instruction; else the result could take a
\ while to identify and fix.

: (incdec)  ( idx op s -- )
   rot case
      0  of  wd|wsp  <rd> ^rn     #aimm   ^aimm    endof
      1  of  xd|xsp  <rd> ^rn     #aimm   ^aimm    endof
   endcase
;

\ inc      rN,<immed>
\ is equivalent to
\ add      rN,rN,<immed>
: inc  ( -- )  2 0 try: 0  0  (incdec)  ;
: incs ( -- )  2 0 try: 0  1  (incdec)  ;

\ dec      rN,<immed>
\ is equivalent to
\ sub      rN,rN,<immed>
: dec  ( -- )  2 0 try:  1  0  (incdec)  ;
: decs ( -- )  2 0 try:  1  1  (incdec)  ;

: ?push2-pop2-reg-chk  ( -- )
   ?rt=rt2
   <rn> d# 31 *<>  *if  exit  *then
   rd-adt adt-dreg *=  *if  exit  *then
   rd-adt adt-xreg *=  *if  exit  *then
   " Only x or d register type supported with push2/pop2 to/from the xsp" expecting
;

: ?push-pop-reg-chk  ( -- )
   <rn> d# 31 *<>  *if  exit  *then
   rn-adt  adt-qreg  *=  *if  exit  *then  \ push/pop q is OK
   " push/pop of a single register to/from the XSP register misaligns it" expecting
;
   
: (push-parse)  <asm  rd, xn|xsp
                ?push-pop-reg-chk
                rd->sz,v,opc 1 xor
                3dup sz-v-op>scale 1cell  min negate 9 mask land
                3  \ Addressing mode [x|sp,#]!
                swap ^ls-imm9
                asm>  ;
: (pop-parse)  <asm  rd, xn|xsp
                ?push-pop-reg-chk
                rd->sz,v,opc
                3dup sz-v-op>scale 1cell  min
                1  \ Addressing mode [x|sp],#
                swap ^ls-imm9
                asm>  ;
\ psh      rN,rM
\ is equivalent to
\ str      rN,[rM,-1cell]!
: psh  ( -- )   (push-parse)  ;
: push  ( -- )  (push-parse)  ;

\ pop      rN,rM
\ is equivalent to
\ ldr      rN,[rM],1cell
: pop  ( -- )  (pop-parse)  ;

: (push2-parse)  <asm  rd, ra, xn|xsp
                ?push2-pop2-reg-chk
                0 rd->v,opc,sz  is imm-multiplier
                3     \ Addressing mode [x|sp,{,#7x}]!
                d# -16
                ^ldst-pair
                asm>  ;
: (pop2-parse)  <asm  rd, ra, xn|xsp
                ?push2-pop2-reg-chk
                1 rd->v,opc,sz  is imm-multiplier
                1     \ Addressing mode [x|sp],#7x
                d# 16
                ^ldst-pair
                asm>  ;
\ psh2     rJ, rK, rM
\ is equivalent to
\ stp      rJ, rK, [rM,-2cells]!
: psh2  ( -- )   (push2-parse)  ;
: push2  ( -- )  (push2-parse)  ;

\ pop2      rJ, rK, rM
\ is equivalent to
\ ldp      rJ, rK, [rM], 2cells
: pop2  ( -- )  (pop2-parse)  ;

\ : next  " br up" evaluate  ;
: next  ( -- )  h# d61f0300 l,  ;  ( br up )
\ : next  ( -- )  h# d61f0300 instruction,  ;  ( br up )   \ x86 lacks instruction,
\ : c;     next  end-code ;

\ NOTE: CSINV translates to: Rd = if cond then Rn else NOT (RM)
\ Or, in Forth:  cond if Rn else Rm NOT then Rd!
\
\ CSTF is Condtionally Select TRUE, else FALSE
\ It's based on CSINV  <rd>, XZR, XZR, <cond> XOR 1
\ The inversion is applied because the CSINV will set
\ <rd> to 0 if <cond>; but we want <rd> to be -1 if <cond>,
\ therefore, CSTF inverts the condition and sets <rd> to -1 if <cond>.

\ XXX identical to csetm ???
alias cstf csetm
\ : cstf   <asm  1 0  wxd,  0x1f03e0 iop  4 uimm  1 xor  ^cond-select  asm>  ;

\ set <rd>,#<value>
\ Set allows an arbitrary value in a register to be set.
\ Use movz to set the low 16 bits and clear the others,
\ then use movk 0 to 3 times for the rest.

\ still in decimal

: set-movz    ( 16b reg# shift  -- )
   dup 2 *>=  sf *0=  *and  *if  ??cr .s 1 abort" Can't set the high 32 bits of a W reg (set-movz)"  *then
   rot
   start-instr
   ( 16b )   5  16  ^^op
   ( shift ) 21  2  ^^op
   ( reg# )          ^rd
   2         29 2   ^^op
   sf                ^sf
   0x25      23 6   ^^op
   end-instr
;
: set-mov(z)    ( 16b reg# shift -- )
   dup 2 *>=  sf *0=  *and  *if  3drop exit  *then
   rot
   dup l0=  *if  3drop exit  *then
   start-instr
   ( 16b )   5  16  ^^op
   ( shift ) 21  2  ^^op
   ( reg# )          ^rd
   3         29  2  ^^op
   sf                ^sf
   0x25      23  6 ^^op
   end-instr
;

: set0-based  ( d reg# -- )
   >R
   \ Ensure hi is 0 if SF is false
   dup 0 *<>  sf *0=  *and  *if ??cr .s cr 1 abort" Can't set the hi 32 bit of a W register"  *then
   lwsplit swap rot lwsplit swap  ( hi_hi_16 hi_lo_16 lo_hi_16 lo_lo_16  R: reg# )
   dup      0 *<>  *if  R@ 0 set-movz  R@ 1 set-mov(z)   R@ 2 set-mov(z)   R> 3 set-mov(z)  exit  *then
   drop dup 0 *<>  *if                 R@ 1 set-movz     R@ 2 set-mov(z)   R> 3 set-mov(z)  exit  *then
   drop dup 0 *<>  *if                                   R@ 2 set-movz     R> 3 set-mov(z)  exit  *then
   drop                                                                    R> 3 set-movz
;

: set-movn    ( 16b reg# shift  -- )
   dup 2 *>=  sf *0=  *and  *if  3drop exit  *then
   rot
   start-instr
   0xffff xor
   ( 16b )   5  16  ^^op
   ( shift ) 21  2  ^^op
   ( reg# )          ^rd
   \ 0         29  2  ^^op
   sf                ^sf
   0x25      23  6  ^^op
   end-instr
;
: set-mov(n)    ( 16b reg# shift -- )
   dup 2 *>=  sf *0=  *and  *if  3drop exit  *then
   rot
   dup 0xFFFF *=  *if  3drop exit  *then
   start-instr
   ( 16b )   5  16  ^^op
   ( shift ) 21  2  ^^op
   ( reg# )          ^rd
   3         29  2  ^^op
   sf                ^sf
   0x25      23  6  ^^op
   end-instr
;

hex
: setF-based  ( d reg# -- )
   >R
   \ Ensure hi is 0 or -1 if SF is false
   sf *0=  *if  dup *0=  over 0xFFFFFFFF *=  *or  *0=  *if  ??cr .s cr 1 abort" Can't set the hi 32 bits of a W register (Negative-based)"  *then  *then
   lwsplit swap rot lwsplit swap  ( hi_hi_16 hi_lo_16 lo_hi_16 lo_lo_16  R: reg# )
   dup      ffff *<>  *if  R@ 0 set-movn  R@ 1 set-mov(n)   R@ 2 set-mov(n)   R> 3 set-mov(n)   exit  *then
   drop dup ffff *<>  *if                 R@ 1 set-movn     R@ 2 set-mov(n)   R> 3 set-mov(n)   exit  *then
   drop dup ffff *<>  *if                                   R@ 2 set-movn     R> 3 set-mov(n)   exit  *then
   drop                                                                       R> 3 set-movn
;

: set-count-half   ( n -- #0s #Fs )
   ( n ) dup lwsplit swap   \ n hi lo
   rot lwsplit swap   0 0   ( hi lo hi lo  0-0s  0-Fs )
   rot ( lo )  *0=      *if  swap 1+ swap  *then
   rot ( hi )  ffff *=  *if       1+       *then
   rot ( lo )  ffff *=  *if       1+       *then
   rot ( hi )  *0=      *if  swap 1+ swap  *then
;

: set-count-0s-Fs  ( d -- #0s #Fs )
   set-count-half
   rot set-count-half
   rot + -rot + swap
;

\ More efficient set:
\ 
\ 1) Count the number of F's and 0's
\ 2) If number of 0's is greater than or equal to F's,
\ 3) Then call set0-based
\ 4) Else call setF-based

: set-reg-dvalue  ( d reg# -- )
   >R                           ( d      R: reg# )
   \ Handle #0 and #-1 because those values undermine set0 and setF, respectively
   2dup  *or           *0=   *if  2drop 0    R> 0 set-movz  exit  *then
   2dup *and ffffffff   *=   *if  2drop FFFF R> 0 set-movn  exit  *then
   \ Count the 0s and FFFFs and then call the appropriate set routine
   2dup set-count-0s-Fs
   *>=  *if  R> set0-based  *else  R> setF-based  *then
;

: set-reg-value ( n reg# -- )
   0 swap set-reg-dvalue
;

[ifdef] 32bit-host

: set   \ usage:  set  Rn,#value
   <asm  reg >sf >r  ","  d# 64 #dsimm  >r >r  asm]
   r> r> r>  set-reg-dvalue
;

[else]

: set   \ usage:  set  Rn,#value
   <asm  reg >sf >r  ","  d# 64 #simm  xlsplit  >r >r  asm]
   r> r> r>  set-reg-dvalue
;

: ll16( [char] ) parse eval           h# ffff land ;
: lh16( [char] ) parse eval  d# 16 >> h# ffff land ;
: hl16( [char] ) parse eval  d# 32 >> h# ffff land ;
: hh16( [char] ) parse eval  d# 48 >> h# ffff land ;

[then]

alias ldk set


also forth definitions
headerless
variable pre-asm-base
: stash-base    base @ pre-asm-base ! ;
: restore-base  pre-asm-base @ base ! ;

variable assembling?   assembling? off
\ variable assembling?   0 assembling? !

: (entercode)  ( -- )
   assembling? on
   \ true assembling? !
   also arm64-assembler
;
: entercode  ( -- )   stash-base  decimal (entercode)  ;
' entercode is do-entercode

: (exitcode)  ( -- )
   assembling? off
   \ false assembling? !
   previous
   show-aborts on
;
: exitcode  ( -- )
   (exitcode)
   h# efedc0de l,
   restore-base
;
' exitcode is do-exitcode

headers
\ "code" is defined in the kernel

[ifdef] label-cf
: label  \ name  ( -- )
   header label-cf  !csp  entercode
;
[else]
: label  \ name  ( -- )
   header create-cf  !csp  entercode
;
[then]

: put-call    ( target where -- )  0x94000000 put-helper  ;
: put-branch  ( target where -- )  0x14000000 put-helper  ;

\ assemble one line of text
: (asm$),  ( $ -- t | f )
   dp @ >r               \ Save the current dictionary pointer
   also arm64-assembler ['] eval  catch  ( error? )
   previous
   if
      r@ dp !            \ Restore the dictionary pointer
      true               \ Assembler ERR
   else
      false              \ Assembled OK
   then
   r> drop
;
: (asm$)   ( $ -- instr f | t )
   dp @ >r               \ Save the current dictionary pointer
   also arm64-assembler ['] eval  catch  ( error? )
   previous
   r> dp !               \ Restore the dictionary pointer
   if  true exit  then   \ Assembler ERR
   here l@  false        \ Assembled OK
;
\ eg   asm   and x0,x0,#1
: asm    ( "assembly code" -- instr )
   -1 parse (asm$)  abort" ERROR assembling string"
;
alias asm$ asm   \ historical


only forth also definitions


\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END

