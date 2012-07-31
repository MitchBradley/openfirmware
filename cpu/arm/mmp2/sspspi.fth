\ See license at end of file
\ Access primitives for SPI FLASH using Marvell MMP2 SSP

\ Some chips (e.g. Spansion) don't work in hardware mode, so we do
\ everything in "firmware mode", where we have control over the SPI bus.
\ Every spicmd! clocks out 8 bits.  To read, you have to do a dummy
\ write of the value 0, then you can read the data from the spidata register.

h# 035000 value ssp-base  \ SSP1
: ssp-sscr0  ( -- adr )  ssp-base  ;
: ssp-sscr1  ( -- adr )  ssp-base  4 +  ;
: ssp-sssr   ( -- adr )  ssp-base  8 +  ;
: ssp-ssdr   ( -- adr )  ssp-base  h# 10 +  ;
: ssp-sspsp  ( -- adr )  ssp-base  h# 2c +  ;

: ssp-spi-start  ( -- )
   \ Avoid reinitializing the device after the first time, as that
   \ seems to cause glitches that confuse the SPI FLASH chip
   ssp-sscr1 io@ 0=  if  exit  then

   h# 01 ssp-sspsp io!
   h# 07 ssp-sscr0 io!
   0 ssp-sscr1 io!
   h# 87 ssp-sscr0 io!   
   spi-flash-cs-gpio# gpio-set
   spi-flash-cs-gpio# gpio-dir-out
   h# c0 spi-flash-cs-gpio# af!
;
: ssp-spi-cs-on   ( -- )  spi-flash-cs-gpio# gpio-clr  ;
: ssp-spi-cs-off  ( -- )  spi-flash-cs-gpio# gpio-set  ;

code ssp-spi-out-in  ( bo -- bi )
   set r0,`ssp-base +io #`
   begin
      ldr r1,[r0,#8]
      ands r1,r1,#4
   0<> until
   str tos,[r0,#0x10]
   begin
      ldr r1,[r0,#8]
      ands r1,r1,#8
   0<> until
   ldr tos,[r0,#0x10]
c;
0 [if]
: ssp-spi-out-in  ( bo -- bi )
   begin  ssp-sssr io@ 4 and  until  \ Tx not full
   ssp-ssdr io!
   begin  ssp-sssr io@ 8 and  until  \ Rx not empty
   ssp-ssdr io@
;
[then]
code ssp-spi-in16  ( adr -- adr' )
   set r0,`ssp-base +io #`
   set r2,#0xf04
   set r3,#0xf008
   mov r4,#0
   begin
      ldr r1,[r0,#8]
      and r1,r1,r2
      cmp r1,#4
   0= until
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   str r4,[r0,#0x10]
   begin
      ldr r1,[r0,#8]
      and r1,r1,r3
      cmp r1,r3
   0= until
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
   ldr r4,[r0,#0x10]
   strb r4,[tos],#1
c;
: fast-spi-flash-read  ( adr len offset -- )
   3 spi-cmd  spi-adr   ( adr len )
   d# 16 /mod           ( adr len%16 len/16 )
   swap >r              ( adr len/16  r: len%16 )
   0  ?do               ( adr  r: len%16 )
      ssp-spi-in16      ( adr' r: len%16 )
   loop                 ( adr' r: len%16 )
   r>  0  ?do           ( adr )
      spi-in over c!    ( adr )
      1+                ( adr' )
   loop                 ( adr )
   drop                 ( )
   spi-cs-off           ( )
;

: ssp-spi-out  ( b -- )  ssp-spi-out-in drop  ;
: ssp-spi-in  ( -- b )  0 ssp-spi-out-in  ;

: use-ssp-spi  ( -- )
   ['] ssp-spi-start  to spi-start
   ['] ssp-spi-in     to spi-in
   ['] ssp-spi-out    to spi-out
   ['] ssp-spi-cs-on  to spi-cs-on
   ['] ssp-spi-cs-off to spi-cs-off
   ['] reset-all      to spi-reprogrammed
   ['] noop to spi-reprogrammed-no-reboot
\  use-spi-flash-read
   ['] fast-spi-flash-read to flash-read
;
use-ssp-spi

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
