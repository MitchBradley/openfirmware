purpose: Access functions for processor status register
\ See license at end of file

hex

\ interrupt flags: Debug Abort IRQ FIRQ are bits 3c0
3c0 constant DAIF-mask
0c0 constant interrupt-mask
: interrupts-enabled?  ( -- enabled? )   daif@ interrupt-mask and 0=  ;
: interrupt-enable@    ( -- f )   daif@ DAIF-mask and  ;
: interrupt-enable!    ( f -- )   daif@ DAIF-mask andc or  daif!  ;

headerless
: (disable-interrupts)  ( -- )  daif@  interrupt-mask or          daif!  ;
: (enable-interrupts)   ( -- )  daif@  interrupt-mask invert and  daif!  ;

\ daif@ >r (disable-interrupts)
code (lock)  ( -- )  ( R: -- oldDAIF )
   mrs     x0,daif
   psh     x0,rp
   orr     x0,x0,#0xc0
   msr     daif,x0
c;
\ r> daif!
code (unlock)  ( -- )  ( R: oldDAIF -- )
   pop     x0,rp
   msr     daif,x0
c;

' (enable-interrupts) to enable-interrupts
' (disable-interrupts) to disable-interrupts
' (lock) to lock[
' (unlock) to ]unlock

headers

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
