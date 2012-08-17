\ See license at end of file
purpose: Graphical display of boot sequence

d# 0  d# 0  2value first-icon-xy
0 0 2value icon-xy
0 0 2value last-xy
0 value text-y

: ?next-row  ( -- )
   icon-xy drop  image-width +                       ( right )
   screen-ih  package( screen-width )package  >  if  ( )
      first-icon-xy  drop   ( x )
      icon-xy nip d# 40 +   ( y )
      to icon-xy
   then
;

: prep-565  ( image-adr,len -- bits-adr x y w h )
   drop
   dup  " C565" comp  abort" Not in C565 format"
   dup 4 + le-w@  to image-width
   dup 6 + le-w@  to image-height
   8 +
   ?next-row
   icon-xy to last-xy
   icon-xy  image-width  image-height
;

: image-base  ( -- adr )  " graphmem" $call-screen  ;
: $image-name  ( basename$ -- fullname$ )  " rom:%s.565" sprintf  ;

: $get-image  ( filename$ -- true | adr,len false )
   $image-name                           ( fullname$ )
   r/o open-file  if  drop true  exit  then   >r    ( r: fd )
   
   image-base  r@ fsize                  ( bmp-adr,len  r: fd )
   2dup  r@ fgets  over <>               ( bmp-adr,len error?  r: fd )
   r> fclose                             ( bmp-adr,len )
   if  2drop true  else  false  then     ( true | bmp-adr,len false )
;
: $prep&draw  ( image-adr,len -- )
   prep-565  " draw-transparent-rectangle" $call-screen
;
: $show  ( filename$ -- )
   screen-ih 0=  if  2drop exit  then
   0 to image-width   \ In case $show fails
   $get-image  if  exit  then
   $prep&draw
;
: $show-centered  ( filename$ -- )
   screen-ih 0=  if  2drop exit  then
   0 to image-width   \ In case $show fails
   $get-image  if  exit  then
   prep-565                      ( bits-adr x y w h )
   2nip                          ( bits-adr w h )
   screen-wh 2over xy-           ( bits-adr w h excess-x,y )
   swap 2/ swap 2/  2swap        ( bits-adr x y w h )
   " draw-transparent-rectangle" $call-screen
;
: $show-opaque  ( filename$ -- )
   screen-ih 0=  if  2drop exit  then
   $get-image  if  exit  then
   prep-565  " draw-rectangle" $call-screen
;
: advance  ( -- )
   icon-xy  image-width 0  d+  to icon-xy
;
: fix-cursor  ( -- )  cursor-on  ['] user-ok to (ok)  user-ok  ;

: .mem  ( -- )  memory-size .d ." MB SDRAM"   ; 

: .pciid   ( vendor-id product-id -- )
   <# u#s drop  [char] , hold u#s u#>		( adr len )
   d# 10					( adr len 10 )
   over						( adr len 10 len ) 
   -						( adr len pad)
   spaces                                       ( adr len )
   type						( )
;

: get-slot-name  ( # -- adr len )
   " /pci" find-package drop			( # phandle )
   " slot-names" rot get-package-property drop	( # adr len )
   decode-int  drop				( # adr len' ) \ Loose mask

   rot 1- 0 ?do
      decode-string 2drop
   loop

   decode-string 2>r 2drop 2r>
;

0 value slot#
false value looking-for-nic?
0 value slot-mask
0 value slot-displayed

: display-this-node  ( phandle -- )

   base @ swap
   hex

   looking-for-nic?  if
      " name" 2 pick get-package-property drop
      decode-string  " ethernet" $= nip nip 0=  if  drop  base !  exit  then
   then

   " reg" 2 pick get-package-property drop decode-int nip nip
   h# 800 / 1 swap lshift
   slot-displayed =  if  drop  base !  exit  then

   >r					( ) ( r: phandle )

   looking-for-nic?  if
      ." NIC: "
   else
      slot# get-slot-name type
   then

\   ."    ID: "

   " vendor-id" r@ get-package-property drop
   decode-int nip nip				( vendor )

   " device-id" r@ get-package-property drop
   decode-int nip nip				( vendor device )

   .pciid					( )

   ."  "
   " name" r@ get-package-property drop
   decode-string type 2drop

   looking-for-nic?  if  ."  in " slot# get-slot-name type  then

   r>  looking-for-nic? 0=  if 
      drop
   else
      " reg" rot get-package-property drop
      decode-int nip nip
      h# 800 / 1 swap lshift to slot-displayed
   then

   cr

   base !
;

: in-mask?  ( base -- flag )
   h# 800 / >r r@			( slot# ) ( r: slot# )
   1 swap lshift slot-mask and		( flag )

   r> over 0=  if  drop exit  then	( flag )

   0 to slot#

   1 swap
   1+ 0 do
      dup slot-mask and  if  slot# 1+ to slot#  then
      1 lshift
   loop
   drop 
;

: display-if-slot  ( phandle -- )
   ?dup 0=  if  exit  then		\ Just in case...

   " reg" 2 pick get-package-property  if  drop exit  then

   decode-int				( phandle prop$ base )
   nip nip				( phandle base )
   in-mask?  if				( phandle )
      display-this-node			( )
   else					( phandle )
      drop				( )
   then					( )
;

: .pci-slots  ( -- )
   " /pci" find-package drop		( phandle.p )	\ It better be there!

   " slot-names" 2 pick			( phandle.p $ phandle.p )
   get-package-property drop		( phandle.p prop$ )
   decode-int nip nip			( phandle.p slot-mask )
   to slot-mask				( phandle.p )

   child				( phandle )	\ First child

   begin				( phandle )
      dup display-if-slot		( phandle )
      peer ?dup	0=			( phandle false | 0 true )
   until
;

: .cpu-data  ( -- )  cpu-mhz ." CPU Speed:  "  .d ."  MHz" cr  ;

: .usb  ( -- )
   " /usb" find-package 0=  if  exit  then

   ( phandle )

   child			( phandle.c )

   dup if			( phandle.c )
      ." USB Devices:" cr	( phandle.c )
   else				( 0 )
      drop  exit		( )
   then				( phandle.c )

   begin			( phandle.c )
      dup  " name" rot get-package-property  0=  if
         ."   "  type cr
      then			( phandle.c )
      peer			( phandle.next )
      dup 0=
   until
   drop
;

: .sd  ( -- )
   " /pci/sdhci/disk"  open-dev  ?dup  0=  if
      ." Non-Volatile Memory Module Not Installed" cr  exit
   then

   ( ihandle )
   " size" 2 pick $call-method		( ihandle lo hi )
   rot close-dev			( lo hi )

   drop  d# 100000 /			( 100Ks )
   d# 5 +				( 100Ks' )
   d# 10 /				( MBs )
   .d  ." MB SD memory card" cr
;

false value info-shown?
false value show-sysinfo?

also chords definitions
: f7  ( -- )  true to show-sysinfo?  ;
alias w f7
: f8  ( -- )  true to fru-test?  ;
previous definitions

warning @ warning off
: .chords
   .chords
   " F7   Show System Information" .chord
   " F8   Execute FRU Tests" .chord
;
warning !

: .build-date  ( -- )
   " build-date" $find  if  ." , Built " execute type  else  2drop  then
;
: .sysinfo  ( -- )
   info-shown?  if  exit  then   true to info-shown?
   ." MAC Address: " .enet-addr cr
   .rom .build-date cr
   true to looking-for-nic?  .pci-slots
   .mem cr
   .sd
   false to looking-for-nic?  .pci-slots
   .usb
   .cpu-data cr
;

\ Make the terminal emulator use a region that avoids the logo area
: avoid-logo  ( -- )
   screen-ih package( foreground-color background-color )package ( fg-color bg-color )
   screen-wh drop  char-wh drop  d# 80 *  -  2/  ( fg-color bg-color x )
   text-y                                        ( fg-color bg-color x y )
   char-wh drop d# 80  *                         ( fg-color bg-color x y w )
   screen-wh nip text-y -                        ( fg-color bg-color x y w h )
   set-text-region
;

: debug-net?  ( -- flag )  bootnet-debug  ;

: text-area?  ( -- flag )
   show-sysinfo?  debug-net?  or  user-mode? 0<> or  diagnostic-mode? or
   gui-safeboot?  or  show-chords? or
;

false value error-shown?

: error-banner  ( -- )
   error-shown?  if  exit  then   true to error-shown?

   .sysinfo
;
: visual-error  ( error# -- )
   ['] (.error) is .error
   screen-ih 0=  if  (.error) exit  then   
   restore-output
   error-banner
   0 'source-id !  0 error-source-id !  \ Suppress <buffer@NNNN>: prefix
   user-mode?  if                       ( error# )
      (.error)                          ( )
   else                                 ( error# )
      begin                             ( error# | 0 )
         key?  if                       ( error# | 0 )
            key drop                    ( error# | 0 )
            ?dup  if  (.error) 0  then  ( 0 )
         then                           ( error# | 0 )
      user-mode? until                  ( error# | 0 )
      drop
   then
;

: logo-banner  ( -- error? )
   screen-ih  0=  if  true exit  then

\ Do this later...
\   diagnostic-mode?  0=  if  ['] visual-error to .error  then

   text-area?  if
      d# 146 to text-y
      0 0 to icon-xy
   else
      null-output
   then

   cursor-off  ['] fix-cursor to (ok)	\ hide text cursor

   0 to image-width  0 to image-height   \ In case $show-bmp fails
   
   icon-xy to first-icon-xy

   show-sysinfo?  if  .sysinfo  then
   show-chords?  if  " .chords" evaluate  then

   false
;
' logo-banner is gui-banner

[ifdef] resident-packages
dev /obp-tftp
: (configured)  ( -- )  " netconfigured" $show  ;
: show-timeout  ( adr len -- )
   2dup (.dhcp-msg)                 ( adr len )
   " Timeout" $=  screen-ih 0<>  and  if
      " nettimeout" $show
      .sysinfo
   then
;
\ ' show-timeout to .dhcp-msg
\ ' (configured) to configured
device-end
[then]

h# 32 buffer: icon-name

: show-icon  ( basename$ -- )
   [char] : left-parse-string  2nip     ( basename$' )
   $show                                ( )
;

: frozen?  ( -- flag )  " vga?" $call-dcon 0=  ;
: dcon-freeze    ( -- )  0 " set-source" $call-dcon d# 30 ms  ;
: dcon-unfreeze  ( -- )  1 " set-source" $call-dcon d# 30 ms  ;

\ === Stuff moved from security.fth ===

: visible  dcon-unfreeze text-on   ;
: invisible  text-off dcon-freeze  ;

0 0 2value next-icon-xy
0 0 2value next-dot-xy
d# 463 d# 540 2constant progress-xy

: ?adjust  ( x y -- x' y' )
\ 88 is 1200 1024 - 2/ , 66 is 900 768 - 2/
\+ olpc-cl3  swap d# 88 -  swap d# 66 -   ( x' y' )  \ Recenter for XO-3
;
: ?adjust-y  ( y -- y' )
\ 132 is 900 768 -
\+ olpc-cl3  d# 132 -   ( x' y' )  \ Adjustment in Y only for bottom-relative
;
: set-icon-xy  ( x y -- )  ?adjust  to icon-xy  ;
: show-going  ( -- )
   background-rgb  rgb>565  progress-xy ?adjust d# 500 d# 100  " fill-rectangle" $call-screen
   d# 588 d# 638 set-icon-xy  " bigdot" show-icon
   frozen?  if  dcon-unfreeze dcon-freeze  then
;

: show-no-power  ( -- )  \ chip, battery, overlaid sad face
   \ Apply full Y adjustment for stuff at the bottom of the screen
   d#  25 d# 772 ?adjust-y to icon-xy " spi"     show-icon
   d# 175 d# 772 ?adjust-y to icon-xy " battery" show-icon
   d# 175 d# 790 ?adjust-y to icon-xy " sad"     show-icon
;

d# 834 value bar-y
d# 150 value bar-x
0 value dot-adr

: read-dot  ( -- )  \ rom: is unavailable during reflash
   0 to dot-adr  0 0 to icon-xy         ( )
   " darkdot" $get-image if exit then   ( )
   prep-565  4drop  to dot-adr          ( )
;

: show-reflash  ( -- )  \ bottom left corner, chip and progress dots
   d# 25 d# 772 set-icon-xy " spi" show-icon
   d# 992 bar-x + bar-y set-icon-xy " yellowdot" show-icon
   read-dot
;

: show-reflash-dot  ( n -- )  \ n to vary h# 0 to h# 8000
   dup h# 400 mod 0=  if                   ( n )
      dot-adr 0=  if  drop exit  then      ( n )
      dot-adr swap h# 20 /  bar-x + bar-y  ( adr x y )
      image-width image-height             ( adr x y w h )
      " draw-transparent-rectangle" $call-screen
   else
      drop
   then
;

0 [if]
: test-reflash-dot
   page show-reflash  t( h# 8000 0 do  i show-reflash-dot  h# 80 +loop )t
;
[then]

: show-x  ( -- )  " x" show-icon  ;
: show-sad  ( -- )
   icon-xy
   d# 552 d# 283 set-icon-xy  " sad" show-icon
   to icon-xy
;
: show-lock    ( -- )  " lock" show-icon  ;
: show-unlock  ( -- )  " unlock" show-icon  ;
: show-plus    ( -- )  " plus" show-icon  ;
: show-minus   ( -- )  " minus" show-icon  ;
: show-child  ( -- )
   " erase-screen" $call-screen
   d# 552 d# 384 set-icon-xy  " xogray" $show-opaque
   progress-xy ?adjust to next-icon-xy  \ For boot progress reports
;

0 [if]
: show-warnings  ( -- )
   " erase-screen" $call-screen
   d# 48 d# 32 to icon-xy  " warnings" $show-opaque
   dcon-freeze
;
[then]

0 value alternate?
: show-dot  ( -- )
   next-dot-xy to icon-xy  next-dot-xy  d# 16 0 d+  to next-dot-xy    ( )
   alternate?  if  " yellowdot"  else  " lightdot"  then  show-icon
;

: show-dev-icon  ( devname$ -- )
   next-icon-xy                               ( devname$ x y )
   2dup to icon-xy                            ( devname$ x y )
   d# 5 d# 77 d+  to next-dot-xy              ( devname$ )
   show-icon                                  ( )
   next-icon-xy image-width 0 d+  to next-icon-xy  ( devname$ x y )
;

: show-pass  ( -- )
   background  0 0 screen-wh fill-rectangle
   " bigcheck" $show-centered
;
\needs color-reg h# f800 constant color-red
: show-fail  ( -- )
   color-red  0 0 screen-wh fill-rectangle
   " bigx" $show-centered
;

: linux-hook-unfreeze
   [ ' linux-hook behavior compile, ]
;
: linux-hook-freeze
   [ ' linux-hook behavior compile, ]
   show-going
;
: freeze    ( -- )  ['] linux-hook-freeze   to linux-hook  ;
: unfreeze  ( -- )  ['] linux-hook-unfreeze to linux-hook  ;


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
