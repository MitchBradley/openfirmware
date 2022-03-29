\ Contents: Boot-code for ARM64 Risc_OS Code
\ See license at end of file

hex
nuser memtop            \ The top of the memory used by Forth
0 value #args           \ The process's argument count
0 value  args           \ The process's argument list

0 value origin
0 constant main-task    \ This pointer will be changed at boot
0 constant curr-task    \ This pointer is changed as we switch tasks

\ Header code -- cld -- branches to here. Arguments are in registers:
\    x0: was STANDALONE = 0, SYS = -1; obsolete
\    x1: syscall vector, or zero if standalone or under the simulator
\    x2: memtop
\    x3: argc
\    x4: argv
\    x5: initial heap size
\    x6: header (i.e. image) base address
\   org: origin (x23)

code start-forth
   here-t  h# 0c  put-branch        \ Immediate code; runs at compile time!!

   set     x7, #`userarea-t`
   add     up,org,x7            \ set user-pointer
   str     up,'user up0
   adr     x7, 'body main-task
   str     up, [x7]
   adr     x7, 'body curr-task
   str     up, [x7]
   str     org, 'user origin    \ Set origin

   \ At this point, the user pointer has been set to the bottom of the
   \ initial user area image. Record incoming arguments, etc.

   ldr     x7, [x6, #0x90]      \ Fetch dictionary size @(header + 0x10)
   add     x7, x7, org          \ Calc here = (origin + dictsize)
   str     x7, 'user dp         \ Set here
   movz    x9,#0x0f
   bic     x2,x2,x9             \ memtop must be 16 aligned for xsp
   str     x1,'user syscall-vec
   str     x2,'user memtop
   str     x3,'user #args
   str     x4,'user args
   \ Now we can set up the stacks, just below the top of our memory.
   sub     rp,x2,#0             \ RP at the top of memory
   str     rp,'user rp0         \
   sub     sp,rp,#`rs-size-t`   \ SP below the RP
   str     sp,'user sp0
   sub     x8,sp,#`ps-size-t`   \ x8 is below the SP
   mov     xsp,x8               \ System stack below data stack
   sub     x8,x8,#`ps-size-t`   \ Same size as the parameter stack
   sub     x8,x8,x5             \ Heap size
   str     x8,'user limit       \ Initial heap will be from limit to bottom of stack
   inc     sp,#1cell            \ Account for the top of stack register
   adr     ip,'body cold
   set     x0,#0                \ clear next counter
   str     x0,[org,#0x80]
c;

: init-user  ;

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
