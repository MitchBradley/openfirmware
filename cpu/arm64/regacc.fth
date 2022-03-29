purpose: Register access words for ARM64
\ See license at end of file

hex

\ We assume that all devices of interest are mapped with write-buffering disabled,
\ and that all device accesses must be 32-bit.

: rx@   ( addr -- x )   dup l@ swap la1+ l@ lxjoin   ;
: rx!   ( x addr -- )   >r xlsplit r@ la1+ l! r> l!  ;
alias rl@  l@  ( addr -- l )
alias rl!  l!  ( l addr -- )

code rw@   ( a -- w )
   movz   x3,#3
   ands   x0,tos,#2
   bic    tos,tos,x3
   ldr    w1,[tos]
   0= if
      ubfm   tos,x1,#0,#15
   else
      ubfm   tos,x1,#16,#31
   then
c;
code rw!   ( w a -- )
   pop    x1,sp       \ w
   movz   x3,#3
   ands   x0,tos,#2
   bic    tos,tos,x3
   ldr    w2,[tos]    \ old
   0= if
      bfm   w2,w1,#0,#15
   else
      bfm   w2,w1,#16,#15
   then
   str    w2,[tos]
   pop    tos,sp
c;
code rb@   ( a -- b )
   mov    x0,tos
   movz   x1,#3
   bic    tos,tos,x1
   ldr    wtos,[tos]
   and    x0,x0,x1
   lsl    x0,x0,x1
   lsr    tos,tos,x0
   and    tos,tos,#0xff
c;
code rb!   ( b a -- )
   mov    x0,tos
   movz   x3,#3
   bic    tos,tos,x3
   ldr    w2,[tos]    \ old
   and    x0,x0,x3
   lsl    x0,x0,x3    \ bit shift
   movz   x1,#0xff
   lsl    x1,x1,x0
   bic    x2,x2,x1
   pop    x1,sp
   lsl    x1,x1,x0
   orr    x2,x2,x1    \ new
   str    w2,[tos]
   pop    tos,sp
c;


\ register bit arrays also use 32-bit accesses
\ bit 0 of the array is bit 0 of byte 0
code rbitset  ( bit# array -- )
   mov     x0,tos                  \ x0 array
   ldp     x1,tos,[sp],#2cells     \ x1 bit#
   movz    w3,#1
   movz    w2,#32
   sub     w2,w2,w1                \ only the bottom 5 bits will be used
   ror     w3,w3,w2                \ why is there no ROL instruction ?
   lsr     x1,x1,#5                \ 32 bits
   lsl     x1,x1,#2                \ 4 bytes
   ldr     w4,[x0,x1]
   orr     w4,w4,w3
   str     w4,[x0,x1]
c;

code rbitw1c  ( bit# array -- )
   mov     x0,tos                  \ x0 array
   ldp     x1,tos,[sp],#2cells     \ x1 bit#
   movz    w3,#1
   movz    w2,#32
   sub     w2,w2,w1                \ only the bottom 5 bits will be used
   ror     w3,w3,w2                \ why is there no ROL instruction ?
   lsr     x1,x1,#5                \ 32 bits
   lsl     x1,x1,#2                \ 4 bytes
   str     w3,[x0,x1]
c;

code rbitclear  ( bit# array -- )
   mov     x0,tos                  \ x0 array
   ldp     x1,tos,[sp],#2cells     \ x1 bit#
   movz    w3,#1
   movz    w2,#32
   sub     w2,w2,w1                \ only the bottom 5 bits will be used
   ror     w3,w3,w2                \ why is there no ROL instruction ?
   lsr     x1,x1,#5                \ 32 bits
   lsl     x1,x1,#2                \ 4 bytes
   ldr     w4,[x0,x1]
   bic     w4,w4,w3
   str     w4,[x0,x1]
c;

code rbitflip  ( bit# array -- )
   mov     x0,tos                  \ x0 array
   ldp     x1,tos,[sp],#2cells     \ x1 bit#
   movz    w3,#1
   movz    w2,#32
   sub     w2,w2,w1                \ only the bottom 5 bits will be used
   ror     w3,w3,w2                \ why is there no ROL instruction ?
   lsr     x1,x1,#5                \ 32 bits
   lsl     x1,x1,#2                \ 4 bytes
   ldr     w4,[x0,x1]
   eor     w4,w4,w3
   str     w4,[x0,x1]
c;

code rbittest  ( bit# array -- flag )
   mov     x0,tos                  \ x0 array
   pop     x1,sp                   \ x1 bit#
   movz    w3,#1
   movz    w2,#32
   sub     w2,w2,w1                \ only the bottom 5 bits will be used
   ror     w3,w3,w2                \ why is there no ROL instruction ?
   lsr     x1,x1,#5                \ 32 bits
   lsl     x1,x1,#2                \ 4 bytes
   ldr     w4,[x0,x1]
   ands    w4,w4,w3
   cstf    tos,ne                   \ TRUE if bit is set
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
