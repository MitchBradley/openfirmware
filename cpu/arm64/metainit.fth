purpose: Metacompiler initialization for kernel compilation
\ See license at end of file

\ Handle command line
\ Make interpreter re-entrant - multiple tibs? (pokearound)
\ Handle end-of-file on input stream
\ Fix "" to be state smart
\ Meta compiler source for the Forth 83 kernel.
\ Debugging aids

hex
    0 #words !
  800 threshold !
  800 granularity !
warning off

forth definitions
: `  ( -- pstr-adr )  parse-word pad pack  ;

variable >cld  >cld off                 \ helps forward referencing cold

metaon  meta definitions
max-kernel 40 + alloc-mem  target-image      \ Allocate space for the target image

\ org sets the lowest address that is used by Forth kernel.
\ This is sort of a funny number, being a target token rather
\ than a real absolute address.
0.0000 org  0.0000  voc-link-t token-t!

initmeta
ps-size-t equ ps-size
rs-size-t equ rs-size

assembler
\ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
\ !!  The header has called here from somewhere
\ !!      But a header precedes this image.
\ !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
mlabel cld
   adr     org,$0          \ calculate this instruction's address.
                           \ apparently, this is the origin.
   sub     x6,org,#0x80    \ x6 = address of header, x6 = org - sizeof(header)
   str     lr,[org,#0x40]
   nop                     \ space for a branch and link, to be patched in later
meta
\ 0 a,-t
h# 10   allot-t        \ register saving area, reserved for internals
\ CFE boot scribbles some runtime variables at offset h# 100, the start
\ of the user area. Add ad hoc padding here to move the user area to h# 180.
h# e0   allot-t
\ h# 4000 allot-t   \ room for the page tables. 

\ LICENSE_BEGIN
\ Copyright (c) 1986 FirmWorks
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
