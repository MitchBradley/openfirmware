purpose: Client interface handler code
\ See license at end of file

\ "Procedure Call Standard for the ARM 64-bit Architecture" (IHI 0055A)
\ specifies in section 5.1 that "A subroutine invocation must
\ preserve the contents of the registers r19-r29 and SP." There are
\ subtle rules governing r16-18 and r8. To be safe, we'll just
\ preserve everything above r7.

\ Build a new C stack, i.e., set the XSP to a reasonable place.
\ The rules are:
\  1) The last time RP was initialized, it was set to XSP
\     aligned down to the nearest 4K boundary (with a one
\     cell pointer linking RP/SP chunks together).
\
\  2) The Forth SP was then initialized to be 1K (-1 cell
\     for the link) below that.
\
\  3) At this point, the XSP must be 'allocated' from below
\     below the current Forth SP.
\
\  4) But, we have to be able to come back here;
\     i.e., we need to leave some bread crumbs behind
\
\  5) And, we need to make room for the arguments for the
\     routine that's about to be called.

struct \ saved registers and variables calling to CFE
   /x  field  >forth-state-xsp
   /x  field  >forth-state-num-args
   /x  field  >forth-state-rp0
   /x  field  >forth-state-sp0
   /x  field  >forth-state-sp
   /x  field  >forth-state-lr
constant /forth-state
   
\
\ Sometimes, a trace of calls into CFE is useful to have.
\ Here's some code to generate and dump call records.
\
\ NOTE:  Record 0 is a dummy; the cell at offset 0 of record
\        0 holds the count of records.
\
\ NOTE2: The count of records is a bit strange: it's 1 based
\        (because of record 0, as explained above), and it's
\        equal to the record number of the last valid entry.
\
\ my-ncnt{1,2} was x14 incremented in the heart of next:
\
\    ldr     w0,[ip],#/token    \ Fetch next token and update IP
\ *  add     x14,x14,#1         \ Increment total word count
\    add     x0,x0,org          \ token + origin = cfa
\    br      x0                 \ cfa always contains executable code
\
\ Word count might be useful in debugging; who knows.  But really,
\ it just shows that you can measure and record arbitrary things.
\
\ create save-call-c-records

[IFDEF] save-call-c-records
struct \ calling records
   /x  field  >call-c-func
   /x  field  >call-c-arg0
   /x  field  >call-c-arg1
   /x  field  >call-c-arg2
   /x  field  >call-c-arg3
   /x  field  >call-c-my-ip
   /x  field  >call-c-my-rp
   /x  field  >call-c-my-sp
   /x  field  >call-c-my-xsp
   /x  field  >call-c-my-ncnt1
   /x  field  >call-c-my-ncnt2
   /x  field  >call-c-call-ts
   /x  field  >call-c-ret-val
   /x  field  >call-c-ret-ts
constant /call-c_s

: dump-call-base  ( -- a )  0x8.2900.0000  ;
0x100.0000 constant /dump-calls
: #dump-calls  ( -- n )  dump-call-base @  ;

: dump-call ( n -- )
   ." =============================" cr
   ." No.: " dup .d cr
   /call-c_s * dump-call-base +
   dup >call-c-func    ." FUNC:   " @ .h cr
   dup >call-c-arg0    ." ARG0:   " @ .h cr
   dup >call-c-arg1    ." ARG1:   " @ .h cr
   dup >call-c-arg2    ." ARG2:   " @ .h cr
   dup >call-c-arg3    ." ARG3:   " @ .h cr
   dup >call-c-my-ip   ." IP:     " @ .h cr
   dup >call-c-my-rp   ." RP:     " @ .h cr
   dup >call-c-my-sp   ." SP:     " @ .h cr
   dup >call-c-my-xsp  ." XSP:    " @ .h cr
   dup >call-c-my-ncnt1 ." NEXT1 #:" @ .h cr
   dup >call-c-my-ncnt2 ." NEXT2 #:" @ .h cr
   dup >call-c-call-ts ." CALL-TS:" @ .h cr
   dup >call-c-ret-val ." RET-VAL:" @ .h cr
   dup >call-c-ret-ts  ." RET-TS: " @ .h cr
   drop
;

: dump-calls
   ." Dumping the last few entries" cr
   #dump-calls 1+ dup 20 - ?do
      i dump-call
      key?  if  unloop  key drop  exit  then
   loop
;
[THEN] \ save-call-c-records

nuser c-save-xsp
nuser c-save-forth-state

code _call-c_  ( x0:  number of arguments
                 tos: func to call
                 sp:  func args
                 -- xsp is set, args are copied, regs x0..x7 are set )
   sub	 x7, sp, #`/forth-state`
   sub   x7, x7, #16    \ Make room for two elements on the SP (only one used)

   \ Note that in the code below we save SP twice!
   \ When restoring, we'll restore all the registers
   \ and then manually pick up the SP separately.
   \ The reason we do this is because the code below
   \ modifies the SP after we save it here and we want
   \ to preserve the modified SP a second time so we
   \ have special slot for it into which we can preserve
   \ the SP without haveing to know its REG #.

   mov   x2, xsp                \ Can't store xsp directly
   mov   x3, x0                 \ # of args
   ldr	 x4, 'user rp0          \ Should be the same as XSP
   ldr	 x5, 'user sp0
   mov   x6, x7

   \ Now, save the Forth VM
   str   x2,  [x6, #0 >forth-state-xsp]
   str   x3,  [x6, #0 >forth-state-num-args]
   str   x4,  [x6, #0 >forth-state-rp0]
   str   x5,  [x6, #0 >forth-state-sp0]
   str   sp,  [x6, #0 >forth-state-sp]
   str   lr,  [x6, #0 >forth-state-lr]

   stp   x8,  x9,  [xsp, #-16]!
   stp   x10, x11, [xsp, #-16]!
   stp   x12, x13, [xsp, #-16]!
   stp   x14, x15, [xsp, #-16]!
   stp   x16, x17, [xsp, #-16]!
   stp   x18, x19, [xsp, #-16]!
   stp   x20, x21, [xsp, #-16]!
   stp   x22, x23, [xsp, #-16]!
   stp   x24, x25, [xsp, #-16]!
   stp   x26, x27, [xsp, #-16]!
   stp   x28, x29, [xsp, #-16]!
   stp   x30, xzr, [xsp, #-16]!    \ xZR to keep xSP aligned

   mrs   x8, fpcr
   mrs   x9, fpsr

   stp   x8,  x9,  [xsp, #-16]!   \ Save the FPCR and FPSR

   stp   q0,  q1,  [xsp, #-32]!
   stp   q2,  q3,  [xsp, #-32]!
   stp   q4,  q5,  [xsp, #-32]!
   stp   q6,  q7,  [xsp, #-32]!
   stp   q8,  q9,  [xsp, #-32]!
   stp   q10, q11, [xsp, #-32]!
   stp   q12, q13, [xsp, #-32]!
   stp   q14, q15, [xsp, #-32]!
   stp   q16, q17, [xsp, #-32]!
   stp   q18, q19, [xsp, #-32]!
   stp   q20, q21, [xsp, #-32]!
   stp   q22, q23, [xsp, #-32]!
   stp   q24, q25, [xsp, #-32]!
   stp   q26, q27, [xsp, #-32]!
   stp   q28, q29, [xsp, #-32]!
   stp   q30, q31, [xsp, #-32]!

   \ NOTE: We briefly use the x19 register before we CALL
   \       and right after we return.  This is because the
   \       the LR is a callee saved and we can use it to get
   \       back to our xSP to unwind our saved state.
   mov   x19, xsp
   str   x19, 'user c-save-xsp
   and   x0, x0, #0xFF   \ x0 also has the return param in bits 8..15

   \ Copying parameters to C stack frame
   \ Because the XSP has to be aligned, if N args is odd, we need to push
   \ a dummy arg between the linkage just pushed and the N arguments

   tst  x0, #1
   0<> if
      push xzr, sp     \ Temporary push of a dummy argument, 0
      add  x0, x0, #1  \ Pretend the argument count is an even #
   then

   mov   x8, x0        \ Use x8 for the load-registers code, below
   begin
      cmp   x0, #0
   <> while
      pop2  x3, x2, sp     \ This may pop the temporary push of 0, above
      push2 x2, x3, xsp
      sub   x0, x0, #2
   repeat

   \ Update the SP in the save structure
   str   sp, [x6, #0 >forth-state-sp]

   \ NOTE: We briefly use the fp register before we CALL
   \       and right after we return.  This is because the
   \       the fp is callee saved and we can use it to get
   \       back to our saved on-stack structure.
   mov   x29, x6
   str   x6, 'user c-save-forth-state
   \ Now we load the arg parameters
   \ If #args == 0, don't load any args
   \ If #args == 1, then we already bumped it to 2 and aligned the stack.
   \ Therefore, we can test by even numbers and load increasing arg
   \ registers along the way
   \
   \ This basically works out to be
   \ for (i = 0; i < MIN(argcount, 8); i++)
   \    x[i] = pop(xsp);
   \
   cmp   x8, #2
   >= if
      pop2  x0, x1, xsp
      cmp   x8, #4
      >= if
         pop2  x2, x3, xsp
         cmp   x8, #6
         >= if
            pop2  x4, x5, xsp
            cmp   x8, #8
            >= if
               pop2  x6, x7, xsp
            then
         then
      then
   then

[IFDEF] save-call-c-records
   \ Log our calling ...
   set     x8, #`dump-call-base`
   set     x10, #`/dump-calls /call-c_s /`
   ldr	   x9, [x8]
   add	   x9, x9, #1
   cmp     x9,x10
   0= if
      set     x9, #1
   then
   str     x9, [x8]
   set     x10, #`/call-c_s`
   mul     x9, x9, x10
   add	   x8, x8, x9
   str	   tos,[x8, #0 >call-c-func]
   str	   x0,[x8, #0 >call-c-arg0]
   str	   x1,[x8, #0 >call-c-arg1]
   str	   x2,[x8, #0 >call-c-arg2]
   str	   x3,[x8, #0 >call-c-arg3]
   str	   ip,[x8, #0 >call-c-my-ip]
   str	   rp,[x8, #0 >call-c-my-rp]
   str	   sp,[x8, #0 >call-c-my-sp]
   mov     x9,xsp
   str	   x9,[x8, #0 >call-c-my-xsp]
   str     x14,[x8, #0 >call-c-my-ncnt1]
   mrs	   x10,CNTPCT_EL0
   str	   x10,[x8, #0 >call-c-call-ts]
   str     xzr,[x8, #0 >call-c-ret-ts]   
[THEN] \ save-call-c-records

   \ Call the C function!

   blr	 tos

[IFDEF] save-call-c-records
   set     x8, #`dump-call-base`
   ldr	   x9, [x8]
   set     x10, #`/call-c_s`
   mul     x9, x9, x10
   add	   x8, x8, x9
   str     x14,[x8, #0 >call-c-my-ncnt2]
   str     x0, [x8, #0 >call-c-ret-val]
   mrs	   x10,CNTPCT_EL0
   str	   x10,[x8, #0 >call-c-ret-ts]
[THEN] \ save-call-c-records

   \ x0 may be a returned argument, see below where we keep or drop it
   mov   x6, x29       \ mov x6, fp  ; but we don't name the fp
   mov   xsp, x19      \ Recover xSP from our saved register

   \ Restore "all" the registers
   ldp   q30, q31, [xsp], #32
   ldp   q28, q29, [xsp], #32
   ldp   q26, q27, [xsp], #32
   ldp   q24, q25, [xsp], #32
   ldp   q22, q23, [xsp], #32
   ldp   q20, q21, [xsp], #32
   ldp   q18, q19, [xsp], #32
   ldp   q16, q17, [xsp], #32
   ldp   q14, q15, [xsp], #32
   ldp   q12, q13, [xsp], #32
   ldp   q10, q11, [xsp], #32
   ldp   q8,  q9,  [xsp], #32
   ldp   q6,  q7,  [xsp], #32
   ldp   q4,  q5,  [xsp], #32
   ldp   q2,  q3,  [xsp], #32
   ldp   q0,  q1,  [xsp], #32

   ldp   x8,  x9,  [xsp], #16
   msr   fpcr, x8
   msr   fpsr, x9

   ldp   x30, x29, [xsp], #16    \ This will zero x29, but it will restore shortly
   ldp   x28, x29, [xsp], #16
   ldp   x26, x27, [xsp], #16
   ldp   x24, x25, [xsp], #16
   ldp   x22, x23, [xsp], #16
   ldp   x20, x21, [xsp], #16
   ldp   x18, x19, [xsp], #16
   ldp   x16, x17, [xsp], #16
   ldp   x14, x15, [xsp], #16
   ldp   x12, x13, [xsp], #16
   ldp   x10, x11, [xsp], #16
   ldp   x8,  x9,  [xsp], #16

   \ Now, the Forth VM is restored, including up
   ldr   x2,  [x6, #0 >forth-state-xsp]
   ldr   x3,  [x6, #0 >forth-state-num-args]
   ldr   x4,  [x6, #0 >forth-state-rp0]
   ldr   x5,  [x6, #0 >forth-state-sp0]
   ldr   sp,  [x6, #0 >forth-state-sp]
   ldr   lr,  [x6, #0 >forth-state-lr]

   mov   xsp, x2
   str   x4, 'user rp0
   str   x5, 'user sp0

   lsr   x3, x3, #8
   and   x3, x3, #0xFF
   cmp   x3, #1
   = if
      mov  tos, x0    \ Keep C's return argument
   else
      pop  tos, sp    \ Drop C's return argument
   then
   ret   lr
end-code

code call-c ( <params> func ret? #args -- ret | empty )
   mov   x0, tos     \ # arguments
   pop   x1, sp      \ ret?
   orr   x0, x0, x1, lsl #8
   pop   tos, sp     \ func
   bl    '' _call-c_
c;

code svc-c-return ( -- )
   ldr   x6, 'user c-save-forth-state
   ldr   x1, 'user c-save-xsp
   mov   xsp, x1

   adr     up,'body main-task           \ Get user pointer address
   ldr     up,[up]                      \ Get user pointer
   ldr     sav,'user cpu-state          \ address of saved state area

   \ In traps.fth we built a new collection of RP, SP, and XSP stacks.
   \ Here, we need to undo that work.
   ldr     x0, 'state %saved-cpu-state
   str     x0, 'user cpu-state

   ldr   x3,  [x6, #0 >forth-state-lr]

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

   \ Restore "all" the registers
   ldp   q30, q31, [xsp], #32
   ldp   q28, q29, [xsp], #32
   ldp   q26, q27, [xsp], #32
   ldp   q24, q25, [xsp], #32
   ldp   q22, q23, [xsp], #32
   ldp   q20, q21, [xsp], #32
   ldp   q18, q19, [xsp], #32
   ldp   q16, q17, [xsp], #32
   ldp   q14, q15, [xsp], #32
   ldp   q12, q13, [xsp], #32
   ldp   q10, q11, [xsp], #32
   ldp   q8,  q9,  [xsp], #32
   ldp   q6,  q7,  [xsp], #32
   ldp   q4,  q5,  [xsp], #32
   ldp   q2,  q3,  [xsp], #32
   ldp   q0,  q1,  [xsp], #32

   ldp   x8,  x9,  [xsp], #16
   msr   fpcr, x8
   msr   fpsr, x9

   ldp   x30, x29, [xsp], #16    \ This will zero x29, but it will restore shortly
   ldp   x28, x29, [xsp], #16
   ldp   x26, x27, [xsp], #16
   ldp   x24, x25, [xsp], #16
   ldp   x22, x23, [xsp], #16
   ldp   x20, x21, [xsp], #16
   ldp   x18, x19, [xsp], #16
   ldp   x16, x17, [xsp], #16
   ldp   x14, x15, [xsp], #16
   ldp   x12, x13, [xsp], #16
   ldp   x10, x11, [xsp], #16
   ldp   x8,  x9,  [xsp], #16

   ldr   x6, 'user c-save-forth-state

   \ Now, the Forth VM is restored, including up
   ldr   x2,  [x6, #0 >forth-state-xsp]
   ldr   x3,  [x6, #0 >forth-state-num-args]
   ldr   x4,  [x6, #0 >forth-state-rp0]
   ldr   x5,  [x6, #0 >forth-state-sp0]
   ldr   sp,  [x6, #0 >forth-state-sp]
   ldr   lr,  [x6, #0 >forth-state-lr]

   mov   xsp, x2
   str   x4, 'user rp0
   str   x5, 'user sp0

   lsr   x3, x3, #8
   and   x3, x3, #0xFF
   cmp   x3, #1
   = if
      mov  tos, x0    \ Keep C's return argument
   else
      pop  tos, sp    \ Drop C's return argument
   then 

   eret

end-code

headerless
code cif-return  ( error? -- x0: error? )
   mov     x0, tos
   ldr     x1, 'user rp0
   
   mov     xsp, x1
   pop2    rp, sp, xsp
   str     rp, 'user rp0
   str     sp, 'user sp0

   pop2    d14, d15, xsp
   pop2    d12, d13, xsp
   pop2    d10, d11, xsp
   pop2    d8 , d9 , xsp
   pop2    x30, x1 , xsp           \ x1 was to round the stack out; ignore
   pop2    x28, x29, xsp
   pop2    x26, x27, xsp
   pop2    x24, x25, xsp
   pop2    x22, x23, xsp
   pop2    x20, x21, xsp
   pop2    x18, x19, xsp
   pop2    x16, x17, xsp
   pop2    x14, x15, xsp
   pop2    x12, x13, xsp
   pop2    x10, x11, xsp
   pop2    x8 , x9 , xsp

   ret     lr
end-code

: cif-exec  ( args ... -- )  do-cif cif-return  ;

variable halt-on-pause   0 halt-on-pause !
headerless
label cif-handler  ( x0: argument array pointer, lr: return pc -- args-ptr )
   push2   x8 , x9 , xsp
   push2   x10, x11, xsp
   push2   x12, x13, xsp
   push2   x14, x15, xsp
   push2   x16, x17, xsp
   push2   x18, x19, xsp
   push2   x20, x21, xsp
   push2   x22, x23, xsp
   push2   x24, x25, xsp
   push2   x26, x27, xsp
   push2   x28, x29, xsp
   push2   x30, x1 , xsp                \ x1 is just to round the stack out
   push2   d8 , d9 , xsp
   push2   d10, d11, xsp
   push2   d12, d13, xsp
   push2   d14, d15, xsp

   adr     up, 'body curr-task          \ Get user pointer address
   ldr     up, [up]                     \ Get user pointer
   ldr     org, 'user origin
   ldr     rp, 'user rp0
   ldr     sp, 'user sp0
   push2   rp, sp, xsp

   mov     rp, xsp
   sub     sp, xsp, #0x1000
   sub     xsp, sp, #0x1000
   str     rp, 'user rp0
   str     sp, 'user sp0
   inc     sp, #1cell                   \ Account for the top of stack register

   mov     tos, x0                      \ Set top of stack register to arg
   adr     ip, 'body cif-exec           \ Set interpreter pointer
c;

headers
code callback-call  ( argarray vector -- )
   set     x0, #0x001    \ No return value, takes 1 arguments
   bl      '' _call-c_
c;

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
