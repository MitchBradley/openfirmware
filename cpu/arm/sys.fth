purpose: Low-level I/O interface for use with a C "wrapper" program.
\ See license at end of file

\ The C program provides the Forth kernel with an array of entry-points
\ into C subroutines for performing the actual system calls.
\ This scheme should be reasonably compatible with nearly any Unix
\ implementation.  The only difference would be in the implementation of
\ "syscall", which has to look up the address of the actual system call
\ C routine in the system call table provided to it by the C program loader.
\ It then has to convert the stack arguments into the same form as is
\ expected by the C system call routines.  This obviously depends on the
\ details of the C calling sequence, but should not be too hard because
\ C compilers usually pass arguments on the stack.
\    Syscall is defined in the kernel, because it is needed for basics like
\ key and emit.

decimal

/l ualloc-t  dup equ syscall-user#
user syscall-vec   \ long address of system call vector
nuser sysretval

\ I/O for running under an OS with a C program providing actual I/O routines

meta
code syscall  ( call# -- )
   ldmia   sp,{r0,r1,r2,r3,r4,r5}	\ Get some arguments

   psh     ip,rp			\ This register may be clobbered
   ldr     r6,'user syscall-vec		\ Get address of system call table
   add     r6,r6,tos			\ Call through vector
   ldr     r6,[r6]                

   mov     lk,pc                  	\ Return address
   mov     pc,r6                  
\   ldr     pc,[r6,tos]			\ Call through vector

   str     r0,'user sysretval		\ Save the result

   pop     ip,rp                  	\ Restore IP
   pop     tos,sp                  	\ Fix stack
c;
: retval   ( -- return_value )     sysretval l@  ;
: lretval  ( -- l.return_value )   sysretval l@  ;

nuser errno	\ The last system error code
: error?  ( return-value -- return-value error? )
   dup 0< dup  if  60 syscall retval errno !  then   ( return-value flag )
;

\ Rounds down to a block boundary.  This causes all file accesses to the
\ underlying operating system to occur on disk block boundaries.  Some
\ systems (e.g. CP/M) require this; others which don't require it
\ usually run faster with alignment than without.

\ Aligns to a 512-byte boundary
hex
: _falign  ( l.byte# fd -- l.aligned )  drop  1ff invert and  ;
: _dfalign  ( d.byte# fd -- d.aligned )  drop  swap 1ff invert and swap  ;

: sys-init-io  ( -- )
   install-wrapper-alloc
   init-relocation
   install-wrapper-key

   install-disk-io
   \ Don't poll the keyboard under Unix; block waiting for a key
   ['] (key              ['] key            (is
\ sp@ hex . cr
\ rp@ hex . cr
\ origin hex . cr
\ here hex . cr
;
' sys-init-io is init-io

: sys-init ;  \ Environment initialization chain
' sys-init is init-environment
decimal

\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
