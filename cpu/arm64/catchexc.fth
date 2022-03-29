purpose: Common code to manage saved program state
\ See license at end of file
\ See AArch_v8A_ExceptionModel_PRD03-GENC-009432-21-0.pdf

hex

defer vector-base
' 0 to vector-base

code undefined  0 asm,  c;

true value abort-spew    \ let me turn it off
: exquiet   false to abort-spew  ;

headerless
only forth also hidden also  forth definitions

defer handle-exception  ' 0 is handle-exception
defer ignore-exception  ' 0 is ignore-exception
\ This code runs with interrupts disabled
: tramp-to-exception  ( -- )		\ state has just been saved
   state-valid on
   my-self to %saved-my-self
   ignore-exception  ?exit
   handle-exception  ?exit
   handle-breakpoint  \ see forth/lib/breakpt.fth
   \ handle-breakpoint selects a handler:
   \ if not a breakpoint, .exception
   \ if single-stepping,  .step
   \ if a breakpoint,     .breakpoint
;

\ We get here from hw-save-state, still in exception mode
\ Registers X0..X30 have been saved. SP is SPx, UP and SAV are set.
\ Save the exception state and switch to normal mode.
\ New: x0 has exception#
label save-common
   \ save exception registers
   \ default values:
   movz   x3,#0           \ ELR
   movz   x4,#0           \ ESR
   movz   x5,#0           \ FAR
   movz   x6,#0           \ SPSR

   \ select registers based on Exception Level
   \ We do not have EL2, and exceptions will not go to EL0
   mrs    x2,CurrentEL
   and    x2,x2,#0xC
   cmp    x2,#0x4
   0= if
      mrs     x3,ELR_EL1
      mrs     x4,ESR_EL1
      mrs     x5,FAR_EL1
      mrs     x6,SPSR_EL1
      mrs     x7,SCTLR_EL1
      mrs     x8,MAIR_EL1
      mrs     x9,TTBR0_EL1
      mrs     x10,TTBR1_EL1
      mrs     x11,TCR_EL1
   then
   cmp    x2,#0x8
   0= if
      mrs     x3,ELR_EL2
      mrs     x4,ESR_EL2
      mrs     x5,FAR_EL2
      mrs     x6,SPSR_EL2
      mrs     x7,SCTLR_EL2
      mrs     x8,MAIR_EL2
      mrs     x9,TTBR0_EL2
      mrs     x10,TTBR1_EL2
      mrs     x11,TCR_EL2
   then
   cmp    x2,#0xC
   0= if
      mrs     x3,ELR_EL3
      mrs     x4,ESR_EL3
      mrs     x5,FAR_EL3
      mrs     x6,SPSR_EL3
      mrs     x7,SCTLR_EL3
      mrs     x8,MAIR_EL3
      mrs     x9,TTBR0_EL3
      movz    x10,#0     \ There is no TTBR1_EL3
      mrs     x11,TCR_EL3
   then
   str     x3,'state %pc
   str     x4,'state %esr
   str     x5,'state %far
   str     x6,'state %spsr
   str     x7,'state %sctlr
   str     x8,'state %mair
   str     x9,'state %ttbr0
   str     x10,'state %ttbr1
   str     x11,'state %tcr

   ret     lr
end-code

\ The is the first half of the state restoration procedure.  It executes
\ in normal state (e.g user state when running under an OS)
code (restart  ( -- )
   \ The following code communicates with the first part of "save-state".
   \ See the description there.

   \ Remember offset
   here  'code (restart  - >r

   \ Take another trap, so we can fix up the PC's in the signal handler
   0 asm,	\ Should we be using an Undefined instruction?  Yes!
end-code

r> constant restart-offset

0 value extend-restart-common-offset

\ Second part of restart
\ the trap handler sends us here in exception mode.
label restart-common
   \ set     x1,#0
   \ Entry: x1: 0 unless user abort  others: scratch
   adr     up,'body main-task           \ Get user pointer address
   ldr     up,[up]                      \ Get user pointer
   ldr     sav,'user cpu-state          \ address of saved state area

   \ In traps.fth we built a new collection of RP, SP, and XSP stacks.
   \ Here, we need to undo that work.
   ldr     x30, 'state %ssp
   ldr     rp, 'state %saved-rp0
   ldr     sp, 'state %saved-sp0
   ldr     x0, 'state %saved-cpu-state
   str     rp, 'user rp0
   str     sp, 'user sp0
   str     x0, 'user cpu-state

   \ What?  What the hell is this?
   \ This little tricky piece of code is moving the last
   \ registers to be restored from the 'state structure
   \ from the struct to the stack.

   \ Why?  Why the hell do this?
   \ The deal is that the XSP wants to be set above the
   \ the top of 'state structure.  However, setting XSP
   \ above the 'state struct before the 'state structure
   \ has been completely emptied will -allow- another
   \ exception/interrupt to arrive and overwrite the
   \ the very 'state structure we're reading from.

   \ So, what the hell are you going to do?
   \ By copying the last registers from the 'state struct
   \ up into the high block of the current "stack frame",
   \ the code will load -most- of its registers from the
   \ 'state struct and then use pop2 "instructions" to
   \ get the last registers off the stack.

   \ x30 is holding the XSP that ... after we pop x29 and x30,
   \ will be the XSP that we will want.  But, I can't set XSP
   \ with the value of x30 until after we've emptied the
   \ 'state struct.   But, I think I've already explained that.

   ldr     x2, 'state %x29
   ldr     x3, 'state %x30
   push2   x2,x3, x30

   \ In the early part of this code, we don't have to be too careful
   \ about register usage, because we will eventually restore all the
   \ registers to saved values.

   \ Restore the exception state: spsr, etc
   \ We only call restart-common in three cases:
   \ 1) after a hardware irq
   \ 2) as part of debugger, eg the step command
   \ 3) after enter-forth exits ( ie .exception with no abort )
   \ XXX in case 3, can we go back to a bad state???
   ldr     x3,'state %pc
   \ cmp    x1,#0
   \ 0<> if                         \ user abort
   \    add     x3,x3,#4            \ skip over the trap
   \ then
   ldr     x4,'state %esr
   ldr     x5,'state %far
   ldr     x6,'state %spsr
   
   \ select registers based on Exception Level
   mrs    x1,CurrentEL
   and    x1,x1,#0xC

   \ We do not have EL2, and exceptions will not go to EL0
   cmp	  x1,#0x4
   0= if
      msr     ELR_EL1,x3
      msr     ESR_EL1,x4
      msr     FAR_EL1,x5
      msr     SPSR_EL1,x6
   then
   cmp	  x1,#0x8
   0= if
      msr     ELR_EL2,x3
      msr     ESR_EL2,x4
      msr     FAR_EL2,x5
      msr     SPSR_EL2,x6
   then
   cmp	  x1,#0xC
   0= if
      msr     ELR_EL3,x3
      msr     ESR_EL3,x4
      msr     FAR_EL3,x5
      msr     SPSR_EL3,x6
   then

[IFDEF] save-fp-regs
   \ Runtime check of ID_AA64PFR0_EL1 to see if NEON/FP is present, and if yes, then save its state
   mrs    x0, ID_AA64PFR0_EL1
   and    x0, x0, #0xf00000
   cmp    x0, #0xf00000
   0<> if
      ldr     x7,'state %fpsr
      ldr     x8,'state %fpcr
      msr     FPSR,x7
      msr     FPCR,x8
      ldp     q0,q1,'state %q0
      ldp     q2,q3,'state %q2
      ldp     q4,q5,'state %q4
      ldp     q6,q7,'state %q6
      ldp     q8,q9,'state %q8
      ldp     q10,q11,'state %q10
      ldp     q12,q13,'state %q12
      ldp     q14,q15,'state %q14
      ldp     q16,q17,'state %q16
      ldp     q18,q19,'state %q18
      ldp     q20,q21,'state %q20
      ldp     q22,q23,'state %q22
      ldp     q24,q25,'state %q24
      ldp     q26,q27,'state %q26
      ldp     q28,q29,'state %q28
      ldp     q30,q31,'state %q30
   then
[THEN] \ save-fp-regs

   \ restore GPRs
   ldp     x0,x1,'state %x0
   ldp     x2,x3,'state %x2
   ldp     x4,x5,'state %x4
   ldp     x6,x7,'state %x6
   ldp     x8,x9,'state %x8
   ldp     x10,x11,'state %x10
   ldp     x12,x13,'state %x12
   ldp     x14,x15,'state %x14
   ldp     x16,x17,'state %x16
   ldp     x18,x19,'state %x18
   ldp     x20,x21,'state %x20
   ldp     x22,x23,'state %x22
   ldp     x24,x25,'state %x24
   ldp     x26,x27,'state %x26
   ldr     x28,'state %x28

   \ The "nop" can be patched later. Its a placeholder in case we need to extend
   \ restart-common to restore  more register than listed here. There is a
   \ corresponding "nop" in hw-save-state that can be patched to save those
   \ additional registers. Note: Always the xsp and not the sp to save and restore
   \ the lr. I learnt the hard way that you can't trust the sp (x28) to be valid.
   \ And keep accesses 16 byte aligned to account for the SCTLR.S bit.
   str     lr, [xsp, #-16]!
   here origin - to extend-restart-common-offset
   nop
   ldr     lr, [xsp], #16

   \ The last piece.  These two registers were copied
   \ from the 'state struct above.
   mov     xsp,x30
   pop2    x29,x30,xsp    \ Presto!  xsp is the XSP before the exception

   eret
end-code

code unnest-stacks   
   ldr     sav,'user cpu-state          \ address of saved state area
   ldr     rp, 'state %saved-rp0
   ldr     sp, 'state %saved-sp0
   ldr     x0, 'state %saved-cpu-state

   \ Copy the context from the soon to be deleted frame
   \ to the frame pointed to in saved-cpu-state
   \ (Copy pairs of X chunks, 16 bytes at a time)
   ldr     x2, 'user /save-area
   mov     x4, x0
   mov     x3, sav
   begin
      subs   x2, x2, #16                \ This will always go one step too far
   0>= while
      ldp    x5,x6,[x3],#16             \ Read from current cpu-state
      stp    x5,x6,[x4],#16             \ Write to the saved-cpu-state
   repeat

   add     x2, x2, #16                  \ Recoup the 16 "lost" above

   \ Continue the copy a byte at a time, if there are any bytes left.
   begin
      cmp    x2, #0
   0> while
      ldrb   w5,[x3],#1
      strb   w5,[x4],#1
      sub    x2, x2, #1
   repeat
   
   str     rp, 'user rp0
   str     sp, 'user sp0
   str     x0, 'user cpu-state
   inc     sp,#1cell                    \ Account for the top of stack register
   push    ip, rp
c;

\ +0: Synchronous Exceptions, +80: IRQ, +100: FIQ, +180: SError
\ +0: current EL w SP0, +200: current EL w. SPx, +400: lower EL w. ARM64, +600: lower EL w ARM32

string-array exception-type
( 00 )  ," same EL, using SP0 "
( 01 )  ," same EL, using SPx "
( 02 )  ," lower EL running ARM64 "
( 03 )  ," lower EL running ARM32 "
end-string-array
string-array exception-name
( 00 )  ," Synchronous "
( 01 )  ," IRQ "
( 02 )  ," FIQ "
( 03 )  ," SError "
end-string-array

hex

: exception#  ( -- n )   %exc vector-base - 7 >>  ;
: exception-addr    ( -- n )   %far ;

\ Here's a handy word for dumping a number of registers
\ (and memory) that might have been involved in the
\ generation of the current exception

: .reg ( n -- )
   push-hex
   0 swap <#
      u# u# u# u# ascii . hold
      u# u# u# u# ascii . hold
      u# u# u# u# ascii . hold
      u# u# u# u#
   #> type
   pop-base
;
: .cell ( n -- )  .reg  ;
: exception-dump-stack ( start-adr end-adr -- )
   2dup <> if
      swap
      7 andc  \ Align start-adr
      \ dump no more than 16 cells
      dup " sdram /sdram + > over sdram < or" evaluate if exit then
      2dup - d# 16 /n * u>  if  nip dup 3 /n * + then
      cr
      ?do
         \ NOTE: This assumes the address is valid.
         \ We won't know until later how to unravel the MMU and look at the PTE.
         \ So, we may want to make this a defered word so we can factor in the
         \ validity of the PTE before issuing the next operation.
         \ Alternatively; we could have a deferred word v->p-valid? which could
         \ get populated by the currently active MMU table handler.
         2 spaces i @ .cell
      /n +loop
      cr
   else
      2drop
      cr ."  - Empty -" cr
   then
;
: exception-ldump ( adr -- )
   3 andc  \ Align adr
   h# 20 -  h# 40  ldump
;
: exception-dis ( adr -- )
   3 andc  \ Align adr
   h# 10 -  d# 10 dis-n  \ Show 4 instructions before, 1 at and 5 after.
;
: .ex-xreg  ( reg# -- )
   ." x" dup .d  dup d# 10 <  if  space  then space
   ( reg# ) /x * >state @ .reg 2 spaces
;


: .verbose-exception ( -- )
   %pc exception-ldump
   %pc exception-dis
   
   ." lr:    " %lr   .reg cr
   %lr exception-ldump
   %lr exception-dis
   
   ." %ip:   " %ip   .reg cr
   %ip exception-ldump
   
   ." %tos:  " %tos  .reg cr
   ." %sp:   " %sp   .reg \ %sp %saved-sp0 exception-dump-stack
   ." %rp:   " %rp   .reg \ %rp %saved-rp0 exception-dump-stack
   
   ." %org:  " %org  .reg 6 spaces
   ." %up:   " %up   .reg cr
   
   ." %sav:  " %sav  .reg 6 spaces
   ." %lp:   " %lp   .reg cr
   
   ." %x0:   " %x0   .reg 6 spaces
   ." %x1:   " %x1   .reg cr
   ." %x2:   " %x2   .reg 6 spaces
   ." %x3:   " %x3   .reg cr
;
: .exception-registers ( -- )
   d# 32 0 do
      i .ex-xreg  i 1+ .ex-xreg  i 2+ .ex-xreg  i 3 + .ex-xreg  cr
   4 +loop

   ." %esr:  " %esr  .reg 6 spaces
   ." %far:  " %far  .reg cr
   ." %spsr: " %spsr .reg 6 spaces
   ." %ssp:  " %ssp  .reg cr
   ." pc:    " %pc   .reg cr
   abort-spew if  .verbose-exception   then
;

\
\ Exception classes
\
\ see ExceptionModel p.102
: exception-class   ( -- n )   %esr d# 26 >>  ;
\ h# 24 constant data-abort-lower-exception-level
\ h# 25 constant data-abort-same-exception-level
defer handle-irq   ( -- )
' noop to handle-irq
defer handle-fiq   ( -- )
' noop to handle-fiq
defer handle-svc   ( -- F )
: (handle-svc)  ( -- F )  ." SVC d# " %esr 0 d# 24 bits .d cr false ;
' (handle-svc) is handle-svc
defer handle-hvc   ( -- F )
: (handle-hvc)  ( -- F )  ." HVC d# " %esr 0 d# 24 bits .d cr false ;
' (handle-hvc) is handle-hvc
defer handle-mmu-fault   ( -- F )
' false is handle-mmu-fault

variable #irqs
variable #fiqs

defer handle-data-abort-same   ( -- )
defer handle-data-abort-lower  ( -- )
defer .soc-registers
: no-soc-registers  ." ******* NO-SOC-Registers defined for this platform" cr ;
' no-soc-registers  is .soc-registers

defer soc-serror-handler  ( -- handled? )
: default-serror-handler  ( -- handled? )
   ." ******* SError *******" cr
   .soc-registers cr
   false   \ not handled
;
' default-serror-handler  is soc-serror-handler

defer impl-defined-handler ( -- handled? )
: default-impl-defined-handler  ( -- handled? )
   ." ******* EXC Class 3F: Implementation defined Error *******" cr
   false   \ not handled
;
' default-impl-defined-handler  is impl-defined-handler

: .exception-class   ( class -- )
   case
      00 of   ." Unknown Reason "               cr endof
      01 of   ." WFI exception "                cr endof
      07 of   ." FP exception "                 cr endof
      0E of   ." Illegal Execution State "      cr endof
      15 of   ." SVC "                          cr endof
      17 of   ." SMC "                          cr endof
      18 of   ." MSR exception "                cr endof
      20 of   ." Instruction abort "            cr endof
      21 of   ." Instruction abort "            cr endof
      22 of   ." PC alignment "                 cr endof
      24 of   handle-data-abort-lower              endof
      25 of   handle-data-abort-same               endof
      26 of   ." SP alignment "                 cr endof
      2C of   ." FP exception "                 cr endof
      2F of   ." SERROR"                        cr endof
      3F of   ." Implementation Defined Error"  cr endof
      ( default )
         ." class " dup .h  cr
   endcase
   .exception-registers
   abort
;
: (handle-exception  ( -- handled? )
   \ begin again
   exception#  h# 10 <  if
      exception-class  case
         15 of  handle-svc                endof
         16 of  handle-hvc                endof
         2F of  soc-serror-handler        endof
         20 of  handle-mmu-fault          endof
         21 of  handle-mmu-fault          endof
         24 of  handle-mmu-fault          endof
         25 of  handle-mmu-fault          endof
         2F of  soc-serror-handler        endof
         3F of  impl-defined-handler      endof
         ( default ) false  swap  \ Exception not handled
      endcase
      ( -- handled? )
   else  false  \ Exception not handled
   then
;
' (handle-exception  is handle-exception

: .handlers   ( -- )
   ." catchers: " cr
   handler @ 
\   begin  dup sp0 @ rp0 @ between while
   begin  dup origin dup h# 100.0000 + between while
      dup .h cr
      @
   repeat
   drop
;

   \ Fault  |
   \ Status |
   \ [5:0]  |  Meaning
   \ -----------------
   \ 0000LL   Address Size Fault – level determined by LL bits
   \ 0001LL   Translation Fault – level determined by LL bits
   \ 0010LL   Access Flag fault – level determined by LL bits
   \ 0011LL   Permission fault – level determined by LL bits
   \ 010000   Synchronous External Abort
   \ 011000   Memory access Synchronous Parity error
   \ 0101LL   Synchronous External Abort on Translation Table walk – level determined by LL bits
   \ 0111LL   Memory access Synchronous Parity error on Translation Table walk – level determined by LL bits
   \ 100001   Alignment Fault
   \ 110000   TLB Conflict
   \ 110100   IMPLEMENTATION DEFINED FAULT (Lockdown Abort)
   \ 110101   IMPLEMENTATION DEFINED FAULT (unsupported exclusive – see [1])
   \ 111010   IMPLEMENTATION DEFINED FAULT (Coprocessor Abort)
   \ 111101   Section Domain Fault (used for PAR only – see section 3.11.29)
   \ 111110  ￼Page Domain Fault (used for PAR only - see section 3.11.29 )

: .da-level  ( -- )  %esr 3 and  ."  at MMU level " .d cr  ;

: .parity-error   ( -- )
   ." Memory access Synchronous Parity error " cr
   .soc-registers
;
defer parity-error  ' .parity-error is parity-error

code data-abort-trigger c;    \ gives a unique breakpoint address
: .data-abort   ( -- )
   data-abort-trigger
   false >R  \ Do we print soc-registers?
   \ Look at bits 2:5 of the ESR, which are a subset of the fault status codes.
   ." Unhandled Data Abort ("  %esr h# 3F and .h  ." ): "
   %esr 2 >>  h# 0F and  case
      0  of  ." Address Size Fault" .da-level  endof
      1  of  ." Translation Fault" .da-level   endof
      2  of  ." Access Flag Fault" .da-level   endof
      3  of  ." Permission Fault" .da-level    endof
      5  of  ." Synchronous External Abort on Translatioin Table walk" .da-level  endof
      7  of  ." Memory access Synchronous Parity error on Translation Table walk" .da-level  endof
      %esr h# 3F and  case
         10  of  ." Synchronous External Abort"  R> drop true >R  endof
         18  of  parity-error  endof
         20  of  ." Alignment Fault"  endof   \ Was this dropped from the architecture?
         21  of  ." Alignment Fault"  endof
         30  of  ." TLB Conflict"     endof
         34  of  ." IMPLEMENTATION DEFINED FAULT: (Lockdown Abort)"  endof
         35  of  ." IMPLEMENTATION DEFINED FAULT: (unsupported exclusive)"  endof
         3A  of  ." IMPLEMENTATION DEFINED FAULT: (Coprocessor Abort)"  endof
         3D  of  ." Section Domain Fault (used for PAR only)"        endof
         3E  of  ." Page Domain Fault (used for PAR only)"           endof
         ( default )
         ." Undefined Data Abort: 0x" %esr .h
      endcase
   endcase

   ." : address = 0x" %far .h  cr
   .exception-registers
   R>  if  .soc-registers  then
   abort-spew if
      ftrace
      unnest-stacks
      rstrace   \ rp@ rp0 @ over - ldump cr
   then
   \ XXX this quit should cleanly restart the interpreter, but does not
   \ XXX after a data abort, all input will often cause the same data abort to recur
   quit
   \ abort   \ XXX this does not get caught; quit instead
;
' .data-abort is handle-data-abort-same

: .data-abort-lower-el  ( -- )
   ." Data Abort: Lower EL" cr
   \ For now call the same data abort handler, we can change this later
   .data-abort
;

' .data-abort-lower-el is handle-data-abort-lower

: (.exception) ( -- )
   exception#  h# 10 >= if  ." Bogus exception # " exception# .h cr  exit  then
   
   \   ." CPU# " cpu# .
   \ exception# 3 and exception-name count type
   \ ." exception from " exception# 2 >> exception-type count type
   exception-class .exception-class
;
' (.exception) is .exception

[ifdef] notdef
\ Very simple handler, useful before the full breakpoint mechanism is installed
: print-breakpoint
   .exception  \ norm
   interactive? 0=  if bye then  \ Restart unless a human is at the controls
   ??cr quit
;
' print-breakpoint is handle-breakpoint
[then]

defer install-handler  ( handler exception# -- )
defer catch-exception  ( exception# -- )

headers
: catch-exceptions  ( -- )
   init-save-area
   16 0 do   i catch-exception   loop
;

\ [IFDEF] CFG-DEBUG-USERAREA
create main-user-save-area   user-size allot

: (save-user-area)  ( -- )
   up@  main-user-save-area  user-size  move
;

: (comp-user-area)  ( -- fail? )
   up@  main-user-save-area  user-size  qcomp
;
\ [THEN]

headers

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
