purpose: fb8 package support routines
\ See license at end of file

\ Rectangular regions are defined by "adr width height bytes/line".
\ "adr" is the address of the upper left-hand corner of the region.
\ "width" is the width of the region in pixels (= bytes, since
\ this is the 8-bit-per-pixel package).  "height" is the height of the
\ region in scan lines.  "bytes/line" is the distance in bytes from
\ the beginning of one scan line to the beginning of the next one.

\ Within the rectangular region, replace bytes whose current value is
\ the same as fg-color with bg-color, and vice versa, leaving bytes that
\ match neither value unchanged.
code fb8-invert  ( adr width height bytes/line fg-color bg-color -- )
   mov     x0,tos
   ldp     x1,x2,[sp],#2cells
   ldp     x3,x4,[sp],#2cells
   ldp     x5,tos,[sp],#2cells
   \ x0:bg-colour  x1:fg-colour x2:bytes/line  x3:height  x4:width  x5:adr

   begin
      cmp     x3,#0
      > while
      movz     x6,#0
      begin
	 cmp     x4,x6		\ more pixels/line?
	 > while
	 add     x10,x5,x6
	 ldrb    w7,[x10]	\ get pixel colour at adr+offset
	 cmp     x7,x0
	 = if
	    strb  w1,[x10]
	 then
	 cmp     x7,x1
	 = if
	    strb  w0,[x10]
	 then
	 inc     x6,#1
      repeat
      add     x5,x5,x2
      dec     x3,#1
   repeat
c;

\ Within the rectangular region, replace halfwords whose current value is
\ the same as fg-color with bg-color, and vice versa, leaving bytes that
\ match neither value unchanged.
code fb16-invert  ( adr width height bytes/line fg-color bg-color -- )
   mov     x0,tos
   ldp     x1,x2,[sp],#2cells
   ldp     x3,x4,[sp],#2cells
   ldp     x5,tos,[sp],#2cells
   \ x0:bg-colour  x1:fg-colour x2:bytes/line  x3:height  x4:width  x5:adr

   add      x4,x4,x4     \ Byte count instead of pixel count
   begin
      cmp     x3,#0
      > while
      movz     x6,#0
      begin
	 cmp     x4,x6		\ more bytes/line?
	 > while
	 add     x10,x5,x6
         ldrh    w7,[x10]	\ get pixel colour at adr+offset
	 cmp     x7,x0
	 = if
	    strh  w1,[x10]
	 then
	 cmp     x7,x1
	 = if
	    strh  w0,[x10]
	 then
         inc     x6,#2
      repeat
      add     x5,x5,x2
      dec     x3,#1
   repeat
c;

\ Within the rectangular region, replace 3-byte pixels whose current value
\ is the same as fg-color with bg-color, and vice versa, leaving bytes that
\ match neither value unchanged.
code fb24-invert  ( adr width height bytes/line fg-color bg-color -- )
   ldp     x1,x2,[sp],#2cells
   ldp     x3,x4,[sp],#2cells
   ldr     x5,[sp],#1cell
   \ x0:scratch  x1:fg-colour x2:bytes/line  x3:height  x4:width  x5:adr
   \ x6 bytes/line, x7 scratch, x8 scratch, tos bg-color

   add        x4,x4,x4, lsl #1  \ Multiply width by 3 to get bytes
   begin
      cmp     x3,#0
      > while
      movz     x6,#0
      begin
	 cmp     x4,x6		\ more bytes on this line?
	 > while
         add     x0,x5,x6       \ x0 points to the pixel
         ldrb    w7,[x0]        \ Start reading a 3-byte pixel
         ldrb    w8,[x0,#1]
	 orr     x7, x7, x8, lsl #8
	 ldrb    w8,[x0,#2]
	 orr     x7, x7, x8, lsl #16

	 cmp     x7,tos   \ Is it the background color?
	 0=  if
            \ If so, replace with the foreground color
	    strb  w1,[x0]
	    lsr   x8,x1,#8
	    strb  w8,[x0,#1]
	    lsr   x8,x1,#16
	    strb  w8,[x0,#2]
	 then

         cmp     x7,x1   \ Is it the foreground color?
         0=  if
            \ If so, replace with the background color
            strb  wtos,[x0]
            lsr   x8,tos,#8
            strb  w8,[x0,#1]
            lsr   x8,tos,#16
            strb  w8,[x0,#2]
         then
         inc   x6,#3     \ Advance offset to the next pixel
      repeat
      add     x5,x5,x2   \ Advance to next scan line
      dec     x3,#1      \ Decrease the remaining line count
   repeat
   pop   tos,sp
c;

\ Within the rectangular region, replace halfwords whose current value is
\ the same as fg-color with bg-color, and vice versa, leaving bytes that
\ match neither value unchanged.
code fb32-invert  ( adr width height bytes/line fg-color bg-color -- )
   mov     x0,tos
   ldp     x1,x2,[sp],#2cells
   ldp     x3,x4,[sp],#2cells
   ldp     x5,tos,[sp],#2cells
   \ x0:bg-colour  x1:fg-colour x2:bytes/line  x3:height  x4:width  x5:adr

   begin
      cmp     x3,#0
      > while
      movz     x6,#0
      begin
         cmp     x4,x6		\ more bytes on this line?
	 > while
	 add     x10,x5,x6, lsl #2
	 ldr     x7,[x10]	\ get pixel colour at adr+offset
	 cmp     x7,x0
	 = if
	    str   x1,[x10]
	 then
	 cmp     x7,x1
	 = if
	    str   x0,[x10]
	 then
         inc     x6,#1
      repeat
      add     x5,x5,x2
      dec     x3,#1
   repeat
c;


\ Draws a character from a 1-bit-deep font into an 8-bit-deep frame buffer
\ Font bits are stored 1-bit-per-pixel, with the most-significant-bit of
\ the font byte corresponding to the leftmost pixel in the group for that
\ byte.  "font-width" is the distance in bytes from the first font byte for
\ a scan line of the character to the first font byte for its next scan line.
code fb8-paint
  ( fontadr font-width width height screenadr bytes/line fg-color bg-color -- )
   ldp     x1,x2,[sp],#2cells
   ldp     x3,x4,[sp],#2cells
   ldp     x5,x6,[sp],#2cells
   pop     x7,sp
\ tos:bg-col  x1:fg-col  x2:bytes/line  x3: screeadr  x4:height  x5:width
\ x6:font-width  x7:fontadr
   begin
      cmp     x4,#0
      > while                           \ draw another row
      movz    x8,#0			\ x8: pixel-offset
      mov     x11,x3                    \ x11: screen-adr
      begin
         cmp     x5,x8			\ room for one more pixel?
	 > while
	 add     x10,x7,x8,lsr #3       \ x10: font-adr + pixel#/8
         ldrb    w9,[x10]	        \ x9: fontdatabyte
         and     x0,x8,#7               \ x0: pixel-bit# (0..7)
	 lsl     x0,x9,x0               \ shift this pixel to bit 7
	 ands    x0,x0,#0x80            \ test it
	 csel    x0,tos,x1,eq           \ and select fg or bg color
	 strb    w0,[x11],#1            \ write the pixel
         inc     x8,#1                  \ next pixel
      repeat
      add     x7,x7,x6			\ new font-line
      add     x3,x3,x2			\ new screen-line
      dec     x4,#1
   repeat
   pop    tos,sp
c;

\ Draws a character from a 1-bit-deep font into a 16bpp frame buffer
\ Font bits are stored 1-bit-per-pixel, with the most-significant-bit of
\ the font byte corresponding to the leftmost pixel in the group for that
\ byte.  "font-width" is the distance in bytes from the first font byte for
\ a scan line of the character to the first font byte for its next scan line.
code fb16-paint
  ( fontadr fontbytes width height screenadr bytes/line fg-color bg-color -- )
   ldp     x1,x2,[sp],#2cells
   ldp     x3,x4,[sp],#2cells
   ldp     x5,x6,[sp],#2cells
   pop     x7,sp
\ tos:bg-col  x1:fg-col  x2:bytes/line  x3: screeadr  x4:height  x5:width
\ x6:font-width  x7:fontadr
   begin
      cmp     x4,#0
      > while
      movz    x8,#0			\ x8: pixel-offset
      mov     x11,x3                    \ x11: screen-adr
      begin
         cmp     x5,x8			\ one more pixel?
	 > while
	 add     x10,x7,x8,lsr #3       \ x10: font-adr + pixel#/8
	 ldrb    w9,[x10]	        \ x9: fontdatabyte
         and     x0,x8,#7               \ x0: pixel-bit# (0..7)
	 lsl     x0,x9,x0               \ shift this pixel to bit 7
	 ands    x0,x0,#0x80            \ test it
	 csel    x0,tos,x1,eq           \ and select fg or bg color
	 strh    w0,[x11],#2            \ write the pixel
	 inc     x8,#1
      repeat
      add     x7,x7,x6			\ new font-line
      add     x3,x3,x2			\ new screen-line
      dec     x4,#1
   repeat
   pop   tos,sp
c;

\ Draws a character from a 1-bit-deep font into a 24bpp frame buffer
\ Font bits are stored 1-bit-per-pixel, with the most-significant-bit of
\ the font byte corresponding to the leftmost pixel in the group for that
\ byte.  "font-width" is the distance in bytes from the first font byte for
\ a scan line of the character to the first font byte for its next scan line.
code fb24-paint
  ( fontadr fontbytes width height screenadr bytes/line fg-color bg-color -- )
   ldp     x1,x2,[sp],#2cells
   ldp     x3,x4,[sp],#2cells
   ldp     x5,x6,[sp],#2cells
   pop     x7,sp
\ tos:bg-col  x1:fg-col  x2:bytes/line  x3: screenadr  x4:height  x5:width
\ x6:font-width  x7:fontadr
\ free: x8 x9 x0
   begin
      cmp     x4,#0
      > while
      movz    x8,#0			\ x8: pixel-offset
      mov     x11,x3                    \ x11: screen-adr
      begin
	 cmp     x5,x8			\ one more pixel?
	 > while
	 add     x10,x7,x8,lsr #3       \ x10: font-adr + pixel#/8
	 ldrb    w9,[x10]	        \ x9: fontdatabyte
         and     x0,x8,#7               \ x0: pixel-bit# (0..7)
	 lsl     x0,x9,x0               \ shift this pixel to bit 7
	 ands    x0,x0,#0x80            \ test it
	 csel    x0,tos,x1,eq           \ and select fg or bg color
	 strb    w0,[x11],#1            \ write the pixel
	 lsr     x0,x0,#8
	 strb    w0,[x11],#1            \ write the pixel
	 lsr     x0,x0,#8
	 strb    w0,[x11],#1            \ write the pixel
         inc     x8,#1
      repeat
      add     x7,x7,x6			\ new font-line
      add     x3,x3,x2			\ new screen-line
      dec     x4,#1
   repeat
   pop   tos,sp
c;

\ Draws a character from a 1-bit-deep font into an 8-bit-deep frame buffer
\ Font bits are stored 1-bit-per-pixel, with the most-significant-bit of
\ the font byte corresponding to the leftmost pixel in the group for that
\ byte.  "font-width" is the distance in bytes from the first font byte for
\ a scan line of the character to the first font byte for its next scan line.
code fb32-paint
  ( fontadr fontbytes width height screenadr bytes/line fg-color bg-color -- )
   ldp     x1,x2,[sp],#2cells
   ldp     x3,x4,[sp],#2cells
   ldp     x5,x6,[sp],#2cells
   pop     x7,sp
\ tos:bg-col  x1:fg-col  x2:bytes/line  x3: screeadr  x4:height  x5:width
\ x6:font-width  x7:fontadr
\ free: x8 x9 x0
   begin
      cmp     x4,#0
      > while
      movz    x8,#0			\ x8: pixel-offset
      begin
	 cmp     x5,x8			\ one more pixel?
	 > while
	 add     x10,x7,x8,lsr #3       \ x10: font-adr + pixel#/8
	 ldrb    w9,[x10]	        \ x9: fontdatabyte
         and     x0,x8,#7               \ x0: pixel-bit# (0..7)
	 lsl     x0,x9,x0               \ shift this pixel to bit 7
	 ands    x0,x0,#0x80            \ test it
	 csel    x0,tos,x1,eq           \ and select fg or bg color
	 str     x0,[x11],#4            \ write the pixel
         inc     x8,#1
      repeat
      add     x7,x7,x6			\ new font-line
      add     x3,x3,x2			\ new screen-line
      dec     x4,#1
   repeat
   pop   tos,sp
c;

\ Similar to 'move', but only moves width out of every 'bytes/line' bytes
\ "size" is "height" times "bytes/line", i.e. the total length of the
\ region to move.

\ bytes/line is a multiple of 8, src-start and dst-start are separated by
\ a multiple of bytes/line (i.e. src and dst are simililarly-aligned), and
\ src > dst (so move from the start towards the end).  This makes it
\ possible to optimize an assembly language version to use longword or
\ doubleword operations.

\ this assumes width to be also a multiple of 8
code fb-window-move  ( src-start dst-start size bytes/line width -- )
   mov     x0,tos
   ldp     x1,x2,[sp],#2cells
   ldp     x3,x4,[sp],#2cells
   pop   tos,sp
   \ x0:width  x1: bytes/line  x2:size  x3:dst-start  x4:src-start
   sub     x1,x1,x0	\ x1:bytes/line - width
   add     x2,x2,x4	\ x2:end-of-src-copy-region
   begin
      cmp     x4,x2
      < while
      mov     x7,x0	\ x7:loop-width
      begin
	 decs    x7,#8
	 >= if
	    ldp  x5,x6,[x4],#2cells
	    stp  x5,x6,[x3],#2cells
	 then
      < until
      add     x4,x4,x1
      add     x3,x3,x1
   repeat
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
