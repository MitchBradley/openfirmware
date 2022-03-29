purpose: Save the processor state after an exception - hardware version
\ See license at end of file

only forth also definitions  hidden also

defer log-irq  ' noop  is log-irq
defer log-fiq  ' noop  is log-fiq
defer log-done ' drop  is log-done

\ The exception handler hw-save-state has two functions.
\ When an exception such as a breakpoint occurs, it saves the registers and stacks
\ and reenters Forth.
\ In order to resume execution after a breakpoint, the state must be restored.
\ To do that the cpu must be put into exception state. hw-save-state must
\ distinguish between the two cases, and either save the state or restore it.
\ Related files in cpu/arm64/ are catchexc.fth and register.fth.

\ XXX Q: what does exception state mean for the architecture? Just a higher EL?

headerless

\ This is the first part of the exception handling sequence
\ and the last half of the exception restart sequence.
\ It is executed in exception state. SP is SPx, which is 16 aligned.
\ The previous LR is already on the stack, LR points to the exception entry point.

\ This will build a structure that looks like this:
\
\     |<-   16B   ->|

\     |-------------| <-- XSP on entry
\     |  LR  ,  ELR |
\     |  UP  ,  SAV |
\     |  X2  ,  X3  |
\     |  X0  ,  X1  |
\     |-------------|
\     | 'state      |
\     ~    struct   ~
\     | %X0  , %X1  |
\     |-------------|  <-- RP0, RP
\     |             |
\     |             |
\     |-------------|  <-- SP0, SP
\     |             |
\     |             |
\     |-------------|  <-- XSP on exit
\     |             |
\     |             |

0 value extend-hw-save-state-offset

label hw-save-state
\   sim-trace-on
   \ save some registers on the exception stack
   \ Note, these will be left on the exception stack,
   \ -here-, until we return to the code executing when
   \ the exception occurred.
   \ XXX WCGW?
   push2   up,sav,xsp
   push2   x2,x3,xsp
   push2   x0,x1,xsp

   \ select ELR based on Exception Level
   mrs    sav,CurrentEL
   and    sav,sav,#0xC
   cmp    sav,#0x4
   0= if
      mrs     up,ELR_EL1 
   then
   cmp    sav,#0x8
   0= if
      mrs     up,ELR_EL2 
   then
   cmp    sav,#0xC
   0= if
      mrs     up,ELR_EL3
   then

   str    up,[ssp,#56]

   \ Did we get here from (restart ?
   'code (restart   restart-offset +   ( offset )
   adr     sav,*                        \ Address of trap in (restart
   cmp     sav,up
   0= if
      \ restarting, discard saved registers
      add   xsp,xsp,#4cells   \ x0, x1, x2, x3; keep it 16 aligned
      add   xsp,xsp,#4cells   \ sav, up, lr; keep it 16 aligned

      \ continue restart (in exception state), restore all registers
      \ from the save area and return from the original exception.
      b     'body restart-common
   then

   \ We got here because of some other exception, so save everything.
   \ save certain Forth registers
   adr     up,'body main-task           \ Get user pointer address
   ldr     up,[up]                      \ Get user pointer
   ldr     x0,'user cpu-state           \ address of saved state area
   ldr     x1,'user rp0
   ldr     x2,'user sp0
   ldr     x3,'user /save-area

   str     x1,'user rssave              \ Save the address of the old RS

   \ Allocate the /save-area from the XSP first
   sub     xsp, xsp, x3

   \ Is the SP < here ?
   \ Note: Try to keep this check as close to the point where
   \ we allocate stack space as possible. The farther apart they
   \ are, the greater the chances of nested aborts stomping memory.
   ldr     x3,'user dp
   cmp     xsp,x3
   u< if
      \ And, we're not compiling code (like on the command line)?
      ldr    x3,'user level
      cbz    x3,$0
   then

   \ Then set it as the save area
   mov     sav,xsp
   str     sav,'user cpu-state

   str     x0,'state %saved-cpu-state
   str     x1,'state %saved-rp0
   str     x2,'state %saved-sp0

   \ Clear the # characters emitted during an ISR
   str     xzr,'state %#emit
   str     xzr,'state %exc-type

   \ NOTE: We're not popping the x0,x1,x2,x3 registers
   \       We're just restoring them.

   ldr     x3,'user /save-area
   add     x3, xsp, x3           \ x3 = xsp + /save-area
   ldr     x0, [x3, #0x00]
   ldr     x1, [x3, #0x08]
   ldr     x2, [x3, #0x10]
   ldr     x3, [x3, #0x18]

   \ save GPRs
   stp     x0,x1,'state %x0
   stp     x2,x3,'state %x2
   stp     x4,x5,'state %x4
   stp     x6,x7,'state %x6
   stp     x8,x9,'state %x8
   stp     x10,x11,'state %x10
   stp     x12,x13,'state %x12
   stp     x14,x15,'state %x14
   stp     x16,x17,'state %x16
   stp     x18,x19,'state %x18
   stp     x20,x21,'state %x20
   stp     x22,x23,'state %x22
   stp     x24,x25,'state %x24
   stp     x26,x27,'state %x26
   stp     x28,x29,'state %x28
   str     lr,'state %exc

[IFDEF] save-fp-regs
   \ Runtime check vs ID_AA64PFR0_EL1 to see if NEON/FP is present, and if yes - then save its state
   mrs    x0, ID_AA64PFR0_EL1
   and    x0, x0, #0xf00000
   cmp    x0, #0xf00000
   0<> if
      stp     q0,q1,'state %q0
      stp     q2,q3,'state %q2
      stp     q4,q5,'state %q4
      stp     q6,q7,'state %q6
      stp     q8,q9,'state %q8
      stp     q10,q11,'state %q10
      stp     q12,q13,'state %q12
      stp     q14,q15,'state %q14
      stp     q16,q17,'state %q16
      stp     q18,q19,'state %q18
      stp     q20,q21,'state %q20
      stp     q22,q23,'state %q22
      stp     q24,q25,'state %q24
      stp     q26,q27,'state %q26
      stp     q28,q29,'state %q28
      stp     q30,q31,'state %q30
      mrs     x0,FPSR
      mrs     x1,FPCR
      str     x0,'state %fpsr
      str     x1,'state %fpcr
   then
[THEN]  \ save-fp-regs

   \ The "nop" can be patched later. Its a placeholder in case we need to extend
   \ hw-save-state to save more register than listed here. There is a corresponding
   \ "nop" in restart-common that can be patched to re-load those additional saved
   \ registers. Note: Always use the xsp and not the sp to save and restore the
   \ lr. I learnt the hard way that you can't always trust the sp (x28) to be valid.
   \ And keep accesses 16 byte aligned to account for the SCTLR.S bit.
   str     lr, [xsp, #-16]!
   here origin - to extend-hw-save-state-offset
   nop
   ldr     lr, [xsp], #16

   \ NOTE: We're not popping the up and sav registers from
   \       the stack; they'll be left there until later.

   ldr     x3,'user /save-area
   add     x3, xsp, x3                  \ x3 = xsp + /save-area
   ldr     x0, [x3, #0x20]
   ldr     x1, [x3, #0x28]
   str     x1,'state %sav
   str     x0,'state %up

   \ Save the LR from the running code (this LR register was
   \ pushed in the -actual- interrupt vector code, before
   \ ever calling here)

   ldr     x0, [x3, #0x30]
   str     x0,'state %lr

   \ Save the running code's XSP

   add     x0, x3, #0x40                \ x0 = xsp + /save-area + 0x40
   str     x0,'state %ssp

   \ all registers have now been saved
   \ and the exception stack is empty

   adr     up,'body main-task           \ Get user pointer address
   ldr     up,[up]                      \ Get user pointer
   ldr     org, 'user origin            \ Get origin

   \ Build a new set of stack frames: RP, SP, and XSP

   mov     rp,xsp
   sub     sp,xsp, #0x1000      \ XXX sizes should not be hard coded
   sub     xsp,sp, #0x1000
   str     rp,'user rp0
   str     sp,'user sp0
   inc     sp,#1cell                    \ Account for the top of stack register

   \ lr still has the exception address
   mrs     x0,VBAR_EL1
   sub     x0,lr,x0
   lsr     x0,x0,#7             \ x0: exception vector #

   \ Save the ELR, ESR, FAR, and SPSR
   bl      'body save-common

   \ ARMv8 Exception Vector Table Offsets
   \ Exception From                 Synchronous    IRQ    FIQ    SError
   \ CurrentEL with SP_EL0          0x000          0x080  0x100  0x180
   \ CurrrntEL with SP_ELx (x>0)    0x200          0x280  0x300  0x380
   \ LowerEL = AArch64              0x400          0x480  0x500  0x580
   \ LowerEL = AArch32              0x600          0x680  0x700  0x780

   cmp     x0, #9        \ Interrupt?  (Offset = 0x480, LowerEL)
   b.eq    `0 F:`        \ L_HANDLE_IRQ
   cmp     x0, #5        \ Interrupt?  (Offset = 0x280, CurrentEL)
   b.eq    `0 F:`        \ L_HANDLE_IRQ
   b       `1 F:`        \ L_SKIP_IRQ

0 L:  \ L_HANDLE_IRQ
   movz    x0,#1      \ IRQ
   str     x0,'state %exc-type
   \ call-forth  log-irq
   ldr     x0,'user #irqs
   add     x0,x0,#1
   str     x0,'user #irqs
   call-forth  handle-irq
   \ call-forth  log-done
   mrs     x0,DAIF
   cmp     x0,#0x3C0
   0<>  if
      orr    x0,x0,#0x3C0
      msr    DAIF,x0
      begin  again
   then
   b    'body  restart-common

1 L:  \ L_SKIP_IRQ

   \ Check for FIQ from currentEL or from lowerEL
   cmp     x0, #10       \ FIQ (Offset = 0x500, LowerEL)
   b.eq    `2 F:`        \ L_HANDLE_FIQ
   cmp     x0, #6        \ FIQ (Offset = 0x300, CurrentEL)
   b.eq    `2 F:`        \ L_HANDLE_FIQ
   b       `3 F:`        \ L_SKIP_FIQ

2 L: \ L_HANDLE_FIQ
   movz    x0,#2      \ FIQ
   str     x0,'state %exc-type
   \ call-forth  log-fiq
   ldr     x0,'user #fiqs
   add     x0,x0,#1
   str     x0,'user #fiqs
   call-forth  handle-fiq
   \ call-forth  log-done
   mrs     x0,DAIF
   cmp     x0,#0x3C0
   0<>  if
      orr    x0,x0,#0x3C0
      msr    DAIF,x0
      begin  again
   then
   b    'body  restart-common

3 L: \ L_SKIP_FIQ
   \ The tramp-to-execution hardly ever returns
   call-forth  tramp-to-exception
   \ But if it does ...
   b    'body  restart-common
end-code

label debug-spin-loop
   begin again
end-code

defer init-vector-base
' noop to init-vector-base

\ Put handler address into table at vector-base + 80*exception#
: hw-install-handler  ( handler exception# -- )
   h# 80 * vector-base +               ( handler address )
   ( adr ) dup h# 80 0xfeedface.cafebabe qfill   \ Fill the handler with garbage
   \   insert "b .", which is branch to self
   \   h# 5400000e over instruction! /l +
   \ insert "str lr, [SSP, #-16]!", which is "push lr, ssp" 16-byte aligned
   h# f81f0ffe over instruction! /l +            ( handler address' )

   \ insert "bl handler"
   tuck  - 2 >>a ( offset ) d# 26 lowmask and ( imm26 ) h# 94000000 or
   ( address' instr ) swap instruction!
;


\ so we can grab current one
\ to switch handlers in and out as needed
: hw-get-handler  ( exception# -- addr-of-handler ) 
   h# 80 * vector-base + 4 + dup l@  h# 03ffffff and d# 40 << d# 38 >>a + 
;


: hw-catch-exception     ( exception# -- )    hw-save-state swap install-handler  ;

: debug-catch-exception  ( exception# -- )  debug-spin-loop swap install-handler  ;

: debug-catch-exceptions  ( -- )  16 0 do i debug-catch-exception loop ;

0 value reset-vector-base

: (vector-base)  ( -- n ) vector-base@ ;

: move-vector-base  ( -- )
   \ Allocate 3x 2KB for vector table address + reset vector address both of which must be 2KB aligned
   h# 1800 alloc-mem h# 800 round-up
   dup current-el@ case
      1 of  vbar_el1!  endof
      2 of  vbar_el2!  endof
      3 of  dup  vbar_el1!  vbar_el3!  endof
      nip
   endcase

   ( vbar-adr ) h# 800 + to reset-vector-base
;
: use-movable-vector-base  ( -- )
   ['] (vector-base) to vector-base
   ['] move-vector-base to init-vector-base
;

: enable-exceptions   ( -- )
   ['] (restart           is restart
   ['] hw-install-handler is install-handler
   ['] hw-catch-exception is catch-exception
   use-movable-vector-base
   init-vector-base
   catch-exceptions
   \ hw-handle-irq 1 install-handler
;
warning off    \ stand-init-io occurs
: stand-init-io   ( -- )   stand-init-io
   enable-exceptions        \ Exception handlers
;
warning on

headers
only forth also definitions

\ LICENSE_BEGIN
\ Copyright (c) 2009 FirmWorks
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
