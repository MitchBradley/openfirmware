purpose: Low-level I/O interface for use with a C "wrapper" program.
\ See license at end of file

\ The wrapper program provides the Forth kernel with an array of entry-points
\ into C subroutines for performing the actual system calls.
\ This is passed in as argv[2] ("functions") when invoking the interpreter
\ from the wrapper; if this argument is zero then there are no wrapper
\ routines and the OFW image is reponsible for its own I/O, memory
\ allocation, and so on.
\
\ Forth invokes a "system call" with the call number on the data stack
\ and some variable number of arguments (0..6) pushed below the
\ syscall number. The syscall numbers originally were the actual offset
\ in the functions[] vector of the service routine, and thus for
\ historical reasons are 32-bit quantities in multiples of 4.
\ This is not true for 64-bit implementations where the syscall
\ handlers are 64-bit (octlet) function pointers but the syscall
\ numbers are wired into the machine-independent kernel so we simply
\ calculate the actual offset of the handler by multiplying the call
\ number by 2, i.e. "lsl #1".

decimal

/n ualloc-t  dup equ syscall-user#
                 user syscall-vec     \ long address of system call vector
nuser sysretval

\ I/O for running under an OS with a C program providing actual I/O routines

meta

code syscall  ( ... call# -- )
   ldp     x0, x1, [sp]                \ Fetch up to six arguments
   ldp     x2, x3, [sp, #16]           \ from the stack. Caller must
   ldp     x4, x5, [sp, #32]           \ clean up.

   ldr     x6, 'user syscall-vec
   cmp     x6, #0                      \ Running under simulator?
   = if
      svc  #0x80                       \ Simulator wrapper call
   else
      add  x6, x6, tos, lsl #1         \ See note above.
      ldr  x6, [x6]
      blr  x6
   then
   str     x0, 'user sysretval         \ Save the result
   pop     tos, sp                     \ Fix stack
c;


\ : ..  ( n -- )   \ . does not work yet
\    100 u/mod >digit emit
\     10 u/mod >digit emit
\              >digit emit
\ ;

: retval   ( -- return_value )     sysretval @  ;

nuser errno     \ The last system error code
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
   install-wrapper-io
   install-disk-io
   ['] sys-$getenv is $getenv
   \ Don't poll the keyboard under an OS; block waiting for a key
   ['] (key is key
;

: wrapper-$find-next  ( adr len link -- adr len alf true | adr len false )
   origin d# 180 syscall     ( adr len link org )
   2drop retval ?dup
;         

\ Running native on a host OS, or under arm64sim, we can use wrapper-$find-next.
: sys-init  ( -- ) 
   0 isvalue my-self
   ['] wrapper-$find-next  is $find-next    \ special case
;

: stand-init \ Install code-$find-next
   0 isvalue my-self
   ['] code-$find-next    is $find-next    \ default case
;

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
