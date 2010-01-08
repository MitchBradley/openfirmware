purpose: EHCI USB Controller probe
\ See license at end of file

hex
headers

: make-root-hub-node  ( port -- )
   ok-to-add-device? 0=  if  drop exit  then		\ Can't add another device

   0 set-target				( port )	\ Address it as device 0

   speed-high 0 di-speed!     \ Use high speed for getting the device descriptor
   \ Some devices (e.g. Lexar USB-to-SD) don't work unless you do this first
   dev-desc-buf h# 40 get-cfg-desc drop

   new-address				( port dev )
   speed-high over di-speed!		( port dev )

   0 set-target				( port dev )	\ Address it as device 0

   dup set-address  if			( port dev )	\ Assign it usb addr dev
      ." Retrying with a delay" cr
      over reset-port  d# 5000 ms
      dup set-address  if		( port dev )	\ Assign it usb addr dev
         2drop exit
      then
   then ( port dev )

   dup set-target			( port dev )	\ Address it as device dev
   make-device-node			( )
;

0 instance value probe-error?  \ Back channel to selftest

: probe-root-hub-port  ( port -- )
   false to probe-error?
   dup portsc@ 1 and 0=  if  drop exit  then	\ No device detected
   dup portsc@ h# c00 and h# 400 =  if		\ A low speed device detected
      dup disown-port				\ Disown the port
   else						\ Don't know what it is
      dup reset-port				\ Reset to find out
      dup portsc@ 4 and  0=  if			\ A full speed device detected
	 dup disown-port			\ Disown the port
      else					\ A high speed device detected
         dup ['] make-root-hub-node catch  if	\ Process high speed device
            drop ." Failed to probe root port " dup .d cr
            true to probe-error?
         then
      then
   then                           ( port# )
   dup portsc@ swap portsc!       ( )		\ Clear connection change bit
;

: grab-controller  ( -- error? )
   hccparams@ 8 rshift h# ff and  dup  if    ( config-adr )
      dup my-l@  h# 10001 =  if              ( config-adr )
         h# 100.0000 over my-l!              ( config-adr )  \ Ask for it
         true                                ( config-adr error? )
         d# 100 0  do                        ( config-adr error? )
            over my-l@ h# 101.0000 and  h# 100.0000 =  if
               \ Turn off SMIs in Legacy Support Extended CSR
               h# e000.0000 h# 6c my-l!      ( config-adr error? )
               0 my-l@ h# 27cc8086 =  if
                  h# ffff.0000  h# 70  my-l!  \ Clear EHCI Intel special SMIs
               then
               0= leave                      ( config-adr error?' )
            then                             ( config-adr error? )
            d# 10 ms                         ( config-adr error? )
         loop                                ( config-adr error? )
         nip exit
      then                                   ( config-adr )
   then                                      ( config-adr )
   drop                                      ( )
   false
;

: probe-setup  ( -- )
   \ Set active-package so device nodes can be added and removed
   my-self ihandle>phandle push-package

   alloc-pkt-buf
;
: probe-teardown  ( -- )
   free-pkt-buf
   pop-package
;

: #testable-ports  ( -- n )
   #ports                                            ( #hardware-ports )
   " usb-test-ports" get-inherited-property  0=  if  ( #hardware-ports adr len )
      decode-int  nip nip  min                       ( #testable-ports )
   then                                              ( #testable-ports )
;

: wait-connect  ( port# -- error? )
   begin                            ( port# )
      dup portsc@ h# 2001 and  0=   ( port# unconnected? )
   while                            ( port# )
      key?  if                      ( port# )
         key h# 1b =  if            ( port# )   \ ESC aborts
            drop true exit          ( -- true )
         then                       ( port# )
      then                          ( port# )
   repeat                           ( port# )
   ." Device connected - probing ... "
   probe-setup                      ( port# )
   dup probe-root-hub-port          ( port# )
   probe-teardown                   ( port# )
   probe-error?                     ( error? )
   dup  if  ." Failed" else  ." Done"  then  cr  ( error? )
;

external

: power-usb-ports  ( -- )  ;

: ports-changed?  ( -- flag )
   #ports 0  ?do
      i portsc@ 2 and  if  true unloop exit  then
   loop
   false
;

: probe-root-hub  ( -- )
   probe-setup

   #ports 0  ?do			        \ For each port
      i portsc@ 2 and  if			\ Connection changed
         i rm-obsolete-children			\ Remove obsolete device nodes
         i probe-root-hub-port			\ Probe it
      then
   loop

   probe-teardown
;

: do-resume  ( -- )
   init-ehci-regs
   start-usb
   claim-ownership
   init-struct
   init-extra
;

\ This is a sneaky way to determine if the hardware has been turned off without the software's knowledge
: suspended?  ( -- flag )  asynclist@ 0=  qh-ptr 0<>  and  ;

: open  ( -- flag )
   parse-my-args
   open-count 0=  if
      map-regs
      alloc-dma-buf
      first-open?  if
         false to first-open?
         grab-controller  if
            ." Can't take control of EHCI from underlying BIOS" cr
            free-dma-buf unmap-regs
            false exit
         then
         0 ehci-reg@  h# ff and to op-reg-offset
         reset-usb
         do-resume
      then
      suspended?  if  do-resume  then
      probe-root-hub
   then
   open-count 1+ to open-count
   true
;

: close  ( -- )
   open-count 1- to open-count
   end-extra
   open-count 0=  if  free-dma-buf unmap-regs  then
;

: selftest  ( -- error? )
   ehci-reg dup 0=  if  map-regs  then

   #testable-ports  0  ?do
      i portsc@ h# 2001 and  if		\ Port owned by usb 1.1 controller (2000) or device is present (1)
         ." USB 2.0 port " i u. ."  in use" cr
      else
         diagnostic-mode?  if
            ." Please connect a device to USB port " i u. " !" cr
            i wait-connect  if  true unloop exit  then
         else
            ." Fisheye pattern out to USB 2.0 port " i u. cr
            i test-port-begin
            d# 2,000 ms
            i test-port-end
            0 i portsc!  i reset-port  i power-port
         then
      then
   loop
   0=  if  unmap-regs  then
   false
;

headers

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
