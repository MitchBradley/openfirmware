\ See license at end of file
purpose: Omnivision OV7670 image sensor driver

\ ============================= camera operations =============================

: set-hw  ( vstop vstart hstop hstart -- )
   dup  3 >> 17 ov!			\ Horiz start high bits
   over 3 >> 18 ov!			\ Horiz stop high bits
   32 ov@ swap 7 and or swap 7 and 3 << or 10 ms 32 ov!	\ Horiz bottom bits

   dup  2 >> 19 ov!			\ Vert start high bits
   over 2 >> 1a ov!			\ Vert start high bits
   03 ov@ swap 3 and or swap 3 and 2 << or 10 ms 03 ov!	\ Vert bottom bits
;

\ VGA RGB565
: ov7670-rgb565  ( -- )
   04 12 ov!			\ VGA, RGB565
   00 8c ov!			\ No RGB444
   00 04 ov!			\ Control 1: CCIR601 (H/VSYNC framing)
   10 40 ov!			\ RGB565 output
   38 14 ov!			\ 16x gain ceiling
   b3 4f ov!			\ v-red
   b3 50 ov!			\ v-green
   00 51 ov!			\ v-blue
   3d 52 ov!			\ u-red
   a7 53 ov!			\ u-green
   e4 54 ov!			\ u-blue
   c0 3d ov!			\ Gamma enable, UV saturation auto adjust

   \ OVT says that rewrite this works around a bug in 565 mode.
   \ The symptom of the bug is red and green speckles in the image.
   01 11 ov!			\ 30 fps def 80  !! Linux doesn't do this
;

: ov7670-config  ( ycrcb? -- )
   >r                           ( r: ycrcb? )

   80 12 ov!  2 ms		\ reset (reads back different)
   01 11 ov!			\ 30 fps
   04 3a ov!			\ UYVY or VYUY
   00 12 ov!			\ VGA

   \ Hardware window
   13 17 ov!			\ Horiz start high bits
   01 18 ov!			\ Horiz stop high bits
   b6 32 ov!			\ HREF pieces
   02 19 ov!			\ Vert start high bits
   7a 1a ov!			\ Vert stop high bits
   0a 03 ov!			\ GAIN, VSTART, VSTOP pieces

   \ Mystery scaling numbers
   00 0c ov!			\ Control 3
   00 3e ov!			\ Control 14
   3a 70 ov!  35 71 ov!  11 72 ov!  f0 73 ov!
   02 a2 ov!
   00 15 ov!			\ Control 10

   \ Gamma curve values
   20 7a ov!  10 7b ov!  1e 7c ov!  35 7d ov!
   5a 7e ov!  69 7f ov!  76 80 ov!  80 81 ov!
   88 82 ov!  8f 83 ov!  96 84 ov!  a3 85 ov!
   af 86 ov!  c4 87 ov!  d7 88 ov!  e8 89 ov!

   \ AGC and AEC parameters
   e0 13 ov!			\ Control 8
   00 00 ov!			\ Gain lower 8 bits  !! Linux then sets REG_AECH to 0
   00 10 ov!
   40 0d ov!			\ Control 4 magic reserved bit
   18 14 ov!			\ Control 9: 4x gain + magic reserved bit
   05 a5 ov!			\ 50hz banding step limit
   07 ab ov!			\ 60hz banding step limit
   95 24 ov!			\ AGC upper limit
   33 25 ov!			\ AGC lower limit
   e3 24 ov!			\ AGC/AEC fast mode op region
   78 9f ov!			\ Hist AEC/AGC control 1
   68 a0 ov!			\ Hist AEC/AGC control 2
   03 a1 ov!			\ Magic
   d8 a6 ov!			\ Hist AEC/AGC control 3
   d8 a7 ov!			\ Hist AEC/AGC control 4
   f0 a8 ov!			\ Hist AEC/AGC control 5
   90 a9 ov!			\ Hist AEC/AGC control 6
   94 aa ov!			\ Hist AEC/AGC control 7
   e5 13 ov!			\ Control 8

   \ Mostly magic
   61 0e ov!  4b 0f ov!  02 16 ov!  07 1e ov!
   02 21 ov!  91 22 ov!  07 29 ov!  0b 33 ov!
   0b 35 ov!  1d 37 ov!  71 38 ov!  2a 39 ov!
   78 3c ov!  40 4d ov!  20 4e ov!  00 69 ov! 
   4a 6b ov!  10 74 ov!  4f 8d ov!  00 8e ov!
   00 8f ov!  00 90 ov!  00 91 ov!  00 96 ov!
   00 9a ov!  84 b0 ov!  0c b1 ov!  0e b2 ov!
   82 b3 ov!  0a b8 ov!

   \ More magic, some of which tweaks white balance
   0a 43 ov!  f0 44 ov!  34 45 ov!  58 46 ov!
   28 47 ov!  3a 48 ov!  88 59 ov!  88 5a ov!
   44 5b ov!  67 5c ov!  49 5d ov!  0e 5e ov!
   0a 6c ov!  55 6d ov!  11 6e ov!
   9f 6f ov!			\ 9e for advance AWB
   40 6a ov!
   40 01 ov!			\ Blue gain
   60 02 ov!			\ Red gain
   e7 13 ov!			\ Control 8

   \ Matrix coefficients
   80 4f ov!  80 50 ov!  00 51 ov!  22 52 ov!
   5e 53 ov!  80 54 ov!  9e 58 ov!

   08 41 ov!			\ AWB gain enable
   00 3f ov!			\ Edge enhancement factor
   05 75 ov!  e1 76 ov!  00 4c ov!  01 77 ov!
   c3 3d ov!			\ Control 13
   09 4b ov!  60 c9 ov!         \ Reads back differently
   38 41 ov!			\ Control 16
   40 56 ov!

   11 34 ov!
   12 3b ov!			\ Control 11
   88 a4 ov!  00 96 ov!  30 97 ov!  20 98 ov!
   30 99 ov!  84 9a ov!  29 9b ov!  03 9c ov!
   4c 9d ov!  3f 9e ov!  04 78 ov!

   \ Extra-weird stuff.  Some sort of multiplexor register
   01 79 ov!  f0 c8 ov!
   0f 79 ov!  00 c8 ov!
   10 79 ov!  7e c8 ov!
   0a 79 ov!  80 c8 ov!
   0b 79 ov!  01 c8 ov!
   0c 79 ov!  0f c8 ov!
   0d 79 ov!  20 c8 ov!
   09 79 ov!  80 c8 ov!
   02 79 ov!  c0 c8 ov!
   03 79 ov!  40 c8 ov!
   05 79 ov!  30 c8 ov!
   26 79 ov!

   ( r: ycrcb? )  r>  0=  if  ov7670-rgb565  then   ( )  \ Possibly switch to RGB mode

   d# 490 d# 10 d# 14 d# 158 set-hw	\ VGA window info
;

: ov7670-set-mirrored  ( mirrored? -- )
   h# 1e ov@  h# 20                     ( mirrored? reg-value bit )
   rot  if  or  else  invert and  then  ( reg-value' )
   h# 1e ov!
;

: probe-ov7670  ( -- found? )
   h# 42 to camera-smb-slave    ( )   \ Omnivision SMB ID
   camera-smb-on

   \ Try to read a byte of the manufacturing ID.  If the read fails,
   \ the device is not present or not responding.
   h# 1d ['] ov@ catch  if      ( x )
      drop                      ( )
      false exit                ( -- false )
   then                         ( id-low )

   \ Otherwise there is something at that SMB address; verify that
   \ it has the correct ID.

   h# 1c ov@  h# 0b ov@  h# 0a ov@  bljoin h# 7673.7fa2 <>   if     \ ProdID.MfgID
      false exit                ( -- false )
   then                         ( )

   " OV7670" " sensor" string-property

   ['] ov7670-set-mirrored to set-mirrored
   ['] ov7670-config       to camera-config
   true
;

\ Chain of sensor recognizers
: sensor-found?  ( -- flag )
   probe-ov7670  if  true exit  then
   sensor-found?
;

\ The rest is for debugging and testing
[ifdef] notdef

\ Check for the expected value
: ovc  ( val adr -- )
   2dup ov@      ( val reg# val actual )
   tuck <>  if   ( val reg# actual )
      ." Bad camera I2C value at " swap 2 u.r  ( val actual )
      ."  expected " swap 2 u.r  ."  got " 2 u.r  cr    ( )
   else          ( val reg# actual )
      3drop      ( )
   then          ( )
;

: config-check  ( -- )
   01 11 ovc			\ 30 fps
   04 3a ovc			\ UYVY or VYUY
   ( 00 12 ovc )		\ VGA

   \ Hardware window
   13 17 ovc			\ Horiz start high bits
   01 18 ovc			\ Horiz stop high bits
   b6 32 ovc			\ HREF pieces
   02 19 ovc			\ Vert start high bits
   7a 1a ovc			\ Vert stop high bits
   0a 03 ovc			\ GAIN, VSTART, VSTOP pieces

   \ Mystery scaling numbers
   00 0c ovc			\ Control 3
   00 3e ovc			\ Control 14
   3a 70 ovc  35 71 ovc  11 72 ovc  f0 73 ovc
   02 a2 ovc
   00 15 ovc			\ Control 10

   \ Gamma curve values
   20 7a ovc  10 7b ovc  1e 7c ovc  35 7d ovc
   5a 7e ovc  69 7f ovc  76 80 ovc  80 81 ovc
   88 82 ovc  8f 83 ovc  96 84 ovc  a3 85 ovc
   af 86 ovc  c4 87 ovc  d7 88 ovc  e8 89 ovc

   \ AGC and AEC parameters
   ( e0 13 ovc )		\ Control 8
   ( 00 00 ovc )		\ Gain lower 8 bits
   ( 00 10 ovc )                \ Automatic exposure control 9:2
   40 0d ovc			\ Control 4 magic reserved bit
   ( 18 14 ovc )		\ Control 9: 4x gain + magic reserved bit
   05 a5 ovc			\ 50hz banding step limit
   07 ab ovc			\ 60hz banding step limit
   ( 95 24 ovc )		\ AGC upper limit
   33 25 ovc			\ AGC lower limit
   e3 24 ovc			\ AGC/AEC fast mode op region
   78 9f ovc			\ Hist AEC/AGC control 1
   68 a0 ovc			\ Hist AEC/AGC control 2
   03 a1 ovc			\ Magic
   d8 a6 ovc			\ Hist AEC/AGC control 3
   d8 a7 ovc			\ Hist AEC/AGC control 4
   f0 a8 ovc			\ Hist AEC/AGC control 5
   90 a9 ovc			\ Hist AEC/AGC control 6
   94 aa ovc			\ Hist AEC/AGC control 7
   ( e5 13 ovc	)		\ Control 8

   \ Mostly magic
   61 0e ovc  4b 0f ovc  02 16 ovc  07 1e ovc
   02 21 ovc  91 22 ovc  07 29 ovc  0b 33 ovc
   0b 35 ovc  1d 37 ovc  71 38 ovc  2a 39 ovc
   78 3c ovc  40 4d ovc  20 4e ovc  00 69 ovc 
   4a 6b ovc  10 74 ovc  4f 8d ovc  00 8e ovc
   00 8f ovc  00 90 ovc  00 91 ovc  00 96 ovc
   ( 00 9a ovc )  84 b0 ovc  0c b1 ovc  0e b2 ovc
   82 b3 ovc  0a b8 ovc

   \ More magic, some of which tweaks white balance
   0a 43 ovc  f0 44 ovc  34 45 ovc  58 46 ovc
   28 47 ovc  3a 48 ovc  88 59 ovc  88 5a ovc
   44 5b ovc  67 5c ovc  49 5d ovc  0e 5e ovc
   0a 6c ovc  55 6d ovc  11 6e ovc
   9f 6f ovc			\ 9e for advance AWB
   ( 40 6a ovc )
   ( 40 01 ovc )		\ Blue gain
   ( 60 02 ovc )		\ Red gain
   e7 13 ovc			\ Control 8

   \ Matrix coefficients
   b3 4f ovc  b3 50 ovc  00 51 ovc  3d 52 ovc
   a7 53 ovc  e4 54 ovc  9e 58 ovc

   \ 08 41 ovc			\ AWB gain enable
   ( 00 3f ovc )		\ Edge enhancement factor
   05 75 ovc  e1 76 ovc  ( 00 4c ovc )  01 77 ovc
   c0 3d ovc			\ Control 13
   09 4b ovc  ( 60 c9 ovc )
   38 41 ovc			\ Control 16
   40 56 ovc

   11 34 ovc
   12 3b ovc			\ Control 11
   88 a4 ovc  00 96 ovc  30 97 ovc  20 98 ovc
   30 99 ovc  84 9a ovc  29 9b ovc  03 9c ovc
   5c 9d ovc  3f 9e ovc  04 78 ovc
;

: read-agc  ( -- n )
   3 ov@  h# c0 and  2 lshift  0 ov@ or
;

: read-aec  ( -- n )
   7 ov@  h# 3f and  d# 10 lshift
   h# 10 ov@  2 lshift  or
   4 ov@  3 and  or
;

: dump-regs  ( run# -- )
   0 d# 16 " at-xy" eval
   ." Pass " .d
   key upc  h# 47 =  if ." Good" else  ." Bad" then cr  \ 47 is G

   ."        0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f" cr
   ."       -----------------------------------------------" cr
   h# ca 0  do
      i 2 u.r ." :  "
      i h# 10 bounds  do
         i h# ca <  if  i ov@ 3 u.r   then
      loop
      cr
   h# 10 +loop
;
[then]


\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
