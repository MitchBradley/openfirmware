purpose: USB UART driver
\ See license at end of file

hex
headers

" serial" device-name
" serial" device-type
0 " #size-cells" integer-property
1 " #address-cells" integer-property

variable refcount  0 refcount !

\ Don't do this until someone calls read.  That makes the device
\ work as a console, with separate input and output instances
0 value read-started?
: ?start-reading  ( -- )
   read-started?  if  exit  then
   read-q init-q
   inbuf /bulk-in-pipe bulk-in-pipe begin-bulk-in
   true to read-started?
;

external

: install-abort  ( -- )  ['] poll-tty d# 100 alarm  ;   \ Check for break
: remove-abort   ( -- )  ['] poll-tty 0 alarm  ;

\ Read at most "len" characters into the buffer at adr, stopping when
\ no more characters are immediately available.
: read  ( adr len -- #read )   \ -2 for none available right now
   ?start-reading
   read-bytes
;

: write  ( adr len -- actual )  dup  if  write-bytes  else  nip  then  ;

: open  ( -- flag )
   set-device?  if  false exit  then
   device set-target
   refcount @ 0=  if

      reset?  if
         configuration set-config  if
            ." Failed set serial port configuration" cr
            false exit
         then
         bulk-in-pipe bulk-out-pipe reset-bulk-toggles
      then

      init-buf
      inituart rts-dtr-on
   then
   refcount @ 1+  refcount !
   true
;
: close  ( -- )
   refcount @ 1-  0 max  refcount !
   refcount @ 0=  if
      rts-dtr-off
      end-bulk-in
      free-buf
      false to read-started?
   then
;

variable test-char
: selftest  ( -- 0 )		\ Test device by sending a bunch of characters
   refcount @  if  ." Device in use" cr 0 exit  then
   open 0=  if  ." Device won't open" cr true exit  then
   h# 7f bl  do  i test-char !  test-char 1 write drop  loop
   close  0
;

: init  ( -- )
   init
   init-buf
   init-hook
   free-buf
;

headers

init


\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
