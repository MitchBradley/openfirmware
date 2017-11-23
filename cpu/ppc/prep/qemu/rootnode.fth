purpose: Methods for root node
\ See license at end of file

dev /
" device-tree" device-name
" QEMU PReP/40p" model

80 " aix-bus-id" integer-property
: pnp-decode-reg  ( adr len -- adr' len' d.size d.base info type false true )
   decode-int >r  decode-int 0  r> 0  d# 32  3  false true
;
: init  ( -- )

   d# 400,000,000 " clock-frequency" integer-property  \ For root bus
   calibrate-ticker
;

device-end

\ LICENSE_BEGIN
\ Copyright (c) 1997 FirmWorks
\ Copyright (c) 2014 Artyom Tarasenko
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

