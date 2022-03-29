\ See license at end of file
purpose: CRC-32 calculation

\ Load this before forth/lib/crc32.fth

code ($crc)  ( crc table-adr adr len -- crc' )
   \ tos = len
   mov     x3,tos              \ w3: len
   pop     x1,sp               \ w1: adr
   pop     x2,sp               \ w2: table-adr
   pop     tos,sp              \ tos: crc
   cmp     x3,#0
   0= if  next  then           \ Exit if no bytes to CRC

   begin
      ldrb     w4,[x1],#1         \ Get next byte
      eor      w4,w4,wtos         \ w4: crc^byte
      and      w4,w4,#0xff        \ w4: index
      ldr      w4,[x2,x4,lsl #2]  \ lookup in table
      decs     w3,#1              \ Decrement len
      eor      wtos,w4,wtos,lsr #8 \ crc' = table_data ^ (crc >> 8)
   0= until
c;

\ LICENSE_BEGIN
\ Copyright (c) 2010 FirmWorks
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
