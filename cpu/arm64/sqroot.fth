purpose: Integer square-root for ARM processors
\ See license at end of file

\ 64bit -> 32bit fixed point square root
\ see http://www.finesse.demon.co.uk/steven/sqrt.html
code sqrt  ( n -- root )
   mov   x0, tos                   \ n
   movz  tos,#0x4000,lsl #48       \ root
   movz  x1, #0xC000,lsl #48       \ offset
   movz  x2,#0                     \ loop count
   begin
      ror   x3, tos, x2
      cmp   x0, x3
      hs if
         sub   x0, x0, x3
      then
      lsl   x3, tos, #1
      adc   tos, x1, x3
      inc   x2, #2
      cmp   x2, #64
   = until
   and      tos, tos,#-0xC000000000000001  \ Mask off the top two bits
c;

\ LICENSE_BEGIN
\ Copyright (c) 2008 FirmWorks
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
