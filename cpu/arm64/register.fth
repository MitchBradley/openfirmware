purpose: Common code to manage saved program state
\ See license at end of file

\ Requires:
\
\ >state  ( offset -- addr )
\	Returns an address within the processor state array given the
\	offset into that array
\
\ Defines:
\
\ register names
\ .registers

\ needs action: objects.fth

decimal

only forth hidden also forth also definitions
headerless
create save-fp-regs

variable next-reg
0 next-reg !

: alloc-reg  ( size -- offset )   next-reg @  swap next-reg +!  ;

3 actions
action:  l@ >state @  ;
action:  l@ >state !  ; ( is )
action:  l@ >state    ; ( addr )
: reg  \ name  ( -- )
   create /x alloc-reg l,
   use-actions
;
: regs  \ name name ...  ( #regs -- )
   0  ?do  reg  loop
;

headers
8 regs  %x0   %x1   %x2   %x3   %x4   %x5   %x6   %x7
8 regs  %x8   %x9   %x10  %x11  %x12  %x13  %x14  %x15
8 regs  %x16  %x17  %x18  %x19  %x20  %x21  %x22  %x23
8 regs  %x24  %x25  %x26  %x27  %x28  %x29  %x30  %ssp
5 regs  %spsr %pc   %esr  %far  %exc
7 regs  %vbar %mair %tcr  %ttbr0 %ttbr1 %sctlr %cpacr
3 regs  %saved-my-self  %state-valid  %restartable?
3 regs  %saved-cpu-state   %saved-rp0    %saved-sp0
1 regs  %exc-type           \ Exception types:  0 == unknown, 1 == IRQ, 2 = FIQ
1 regs  %#emit              \ # of characters emitted during an exception


\ alternate names
alias %lp  %x22
alias %org %x23
alias %up  %x24
alias %tos %x25
alias %rp  %x26
alias %ip  %x27
alias %sp  %x28
alias %sav %x29
alias %lr  %x30

[IFDEF] save-fp-regs
\ Floating point
3 actions
action:  l@ >state >r  r@  @  r>  /x + @  swap  ;
action:  l@ >state >r  r@  !  r>  /x + !        ; ( is )
action:  l@ >state                              ; ( addr )
: freg  \ name  ( -- )
   create d# 16 alloc-reg l,
   use-actions
;
: fregs \ name name ...  ( #fregs -- )
   0  ?do  freg  loop
;

next-reg @ d# 16 round-up  next-reg !
8 fregs %q0   %q1   %q2   %q3   %q4   %q5   %q6   %q7
8 fregs %q8   %q9   %q10  %q11  %q12  %q13  %q14  %q15
8 fregs %q16  %q17  %q18  %q19  %q20  %q21  %q22  %q23
8 fregs %q24  %q25  %q26  %q27  %q28  %q29  %q30  %q31
2 regs  %fpsr %fpcr
[THEN] \ save-fp-regs

next-reg @ d# 16 round-up value /save-area

\ Following words defined here to satisfy the
\ references to these "variables" anywhere else
: saved-my-self ( -- addr )  addr %saved-my-self  ;
: state-valid   ( -- addr )  addr %state-valid    ;
: restartable?  ( -- addr )  addr %restartable?   ;

\ : offset-of  \ reg-name  ( -- offset )
\    ' >body @
\ ;

also arm64-assembler definitions
: 'state  ( "name" -- n )  'user#  ;
previous definitions

: clear-save-area  ( -- )  cpu-state /save-area erase  ;
: ?saved-state  ( -- )
   state-valid @  0=  abort" No program state has been saved in this session."
;
: init-save-area  ( -- )
   /save-area alloc-mem is cpu-state
   ps-size    alloc-mem is pssave
   rs-size    alloc-mem is rssave
   clear-save-area
;
init-save-area


headerless
: .xx    ( x -- )    base @ >r hex  17 u.r  3 spaces  r> base !  ;
: (.qx)  ( x -- )    (.) d# 16 over - 0 max 0 ?do  ascii 0 emit  loop  type  ;
: .qx    ( x x -- )  base @ >r hex   (.qx) (.qx) 3 spaces   r> base !  ;

: .mode  ( n -- )
   dup h# 10.0000 and if  ." Illegal "  then
   dup h# 10 and if  32  else  64  then .d ." bits, "
   dup 2 >> 3 and ." EL" .
   ." SP" 1 and if  ." x "  else  0 .  then
;

headers
: .psr  ( -- )
   ." %spsr  "
   %spsr " nzcv~~~~~~sl~~~~~~~~~~daif~~~~~~" show-bits space
   %spsr .mode
;
[IFDEF] save-fp-regs
: .qregisters ( -- )
   ." %fpsr  " %fpsr .xx ." %fpcr  " %fpcr .xx  cr
   ." %q0    " %q0   .qx ." %q1    " %q1   .qx cr
;
[ELSE]
: .qregisters ( -- )  ;
[THEN]

defer .registers-hook  ' noop is .registers-hook
: .registers ( -- )
   ?saved-state
   ??cr
   ." %x0   " %x0 .xx   ." %x1   " %x1 .xx   ." %x2   " %x2 .xx   ." %x3   " %x3 .xx cr
   ." %x4   " %x4 .xx   ." %x5   " %x5 .xx   ." %x6   " %x6 .xx   ." %x7   " %x7 .xx cr
   ." %x8   " %x8 .xx   ." %x9   " %x9 .xx   ." %x10  " %x10 .xx  ." %x11  " %x11 .xx cr
   ." %x12  " %x12 .xx  ." %x13  " %x13 .xx  ." %x14  " %x14 .xx  ." %x15  " %x15 .xx cr
   ." %x16  " %x16 .xx  ." %x17  " %x17 .xx  ." %x18  " %x18 .xx  ." %x19  " %x19 .xx cr
   ." %x20  " %x20 .xx  ." %x21  " %x21 .xx  ." %lp   " %x22 .xx  ." %org  " %x23 .xx cr
   ." %up   " %x24 .xx  ." %tos  " %x25 .xx  ." %rp   " %x26 .xx  ." %ip   " %x27 .xx cr
   ." %sp   " %x28 .xx  ." %fp   " %x29 .xx  ." %lr   " %x30 .xx  ." %ssp  " %ssp .xx cr
   ." %esr  " %esr .xx  ." %far  " %far .xx  ." %exc  " %exc .xx cr
   ." %pc   " %pc .xx .psr  cr
   ." %sctlr " %sctlr " i~~~~~~~~~cam" show-bits cr
   .qregisters
   .registers-hook
;

: .ps  ( -- )
   \ Don't display the parameter stack unless the stack pointer appears to be valid.
   %sp in-data-stack? 0= ?exit
   ." Stack:"   d# 70 rmargin !  %tos .xx  cr
   pssave-end  %sp >saved
   ?do  i x@ .xx  ?cr  exit? ?leave  /x +loop  cr
;
: .rs  ( -- )
   \ Don't display the return stack unless the return stack pointer
   \ appears to be valid.  For instance, if the exception occurred
   \ while executing C code, rp will actually be the C frame pointer,
   \ which has nothing to do with the Forth return stack.
   %rp  in-return-stack?
   if
      ." Return Stack:" cr    d# 70 rmargin !
      rssave-end  %rp >saved
      ?do  i x@ .xx  ?cr  exit? ?leave  /x +loop  cr
   then
;

only forth also definitions

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
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
