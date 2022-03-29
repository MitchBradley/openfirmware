purpose: Bit operations
\ See license at end of file

hex

0 [if]
code bit   ( bit# -- mask )
   set    x1,#1
   lsl    tos,x1,tos
c;
code bit?   ( n bit# -- bit )
   pop    x0,sp
   lsr    tos,x0,tos
   and    tos,tos,#1
c;
code bif   ( bit# width -- mask )
   pop    x0,sp
   set    x1,#1
   lsl    x2,x1,tos
   sub    x2,x2,#1
   lsl    tos,x2,x0
c;
code bif?   ( n bit# width -- bits )
   pop    x0,sp        \ bit#
   pop    x3,sp        \ n
   set    x1,#1
   lsl    x2,x1,tos
   sub    x2,x2,#1     \ mask
   lsr    tos,x3,x0    \ n >> bit#
   and    tos,tos,x2
c;
[then]

\ large bit arrays
\ bit 0 of the array is bit 7 of byte 0

code bitset  ( bit# array -- )
   mov     x0,tos                  \ x0 array
   ldp     x1,tos,[sp],#2cells     \ x1 bit#
   and     w2,w1,#7
   movz    w3,#0x80
   ror     w3,w3,w2
   lsr     x1,x1,#3
   ldrb    w4,[x0,x1]
   orr     w4,w4,w3
   strb    w4,[x0,x1]
c;

code bitclear  ( bit# array -- )
   mov     x0,tos                  \ x0 array
   ldp     x1,tos,[sp],#2cells     \ x1 bit#
   and     w2,w1,#7
   movz    w3,#0x80
   ror     w3,w3,w2
   \ eor     w3,w3,#0xFF
   lsr     x1,x1,#3
   ldrb    w4,[x0,x1]
   bic     w4,w4,w3
   strb    w4,[x0,x1]
c;

code bitflip  ( bit# array -- )
   mov     x0,tos                  \ x0 array
   ldp     x1,tos,[sp],#2cells     \ x1 bit#
   and     w2,w1,#7
   movz    w3,#0x80
   ror     w3,w3,w2
   lsr     x1,x1,#3
   ldrb    w4,[x0,x1]
   eor     w4,w4,w3
   strb    w4,[x0,x1]
c;

code bittest  ( bit# array -- flag )
   mov     x0,tos                  \ x0 array
   pop     x1,sp                   \ x1 bit#
   and     w2,w1,#7
   movz    w3,#0x80
   ror     w3,w3,w2
   asr     x1,x1,#3
   ldrb    w4,[x0,x1]
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
