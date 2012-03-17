\ See license at end of file
purpose: Hashes (MD5, SHA1, SHA-256) using Marvell hardware acceleration

h# 8101 constant dval
: dma>hash  ( adr len -- )
   4 round-up  2 rshift  h# 29080c io!    ( adr )
   >physical h# 290808 io!                ( )
   dval h# 290800 io!                     ( )
\  begin  h# 290814 io@  1 and  until
;
: dma-stop  h# 290800 io@ 1 invert and h# 290800 io!   ;
: swap-axi-bytes  ( -- )  h# 5 h# 290838 io!  ;  \ Byte swap input and output
: in-fifo-remain  ( -- n )  h# 29083c io@  ;
\ : in-fifo@  ( -- n )  h# 290880 io@  ;
\ : in-fifo!  ( n -- )  h# 290880 io!  ;
\ : out-fifo@  ( -- n )  h# 290900 io@  ;
\ : out-fifo!  ( n -- )  h# 290900 io!  ;

h# 40 value /hash-block
d# 20 value /hash-digest
0 value (hash-buf)
: hash-buf  ( -- adr )  (hash-buf) /hash-block round-up  ;  \ Aligned
0 value #hash-buf
0 value #hashed

: use-sha1    ( -- )  0 h# 291800 io!  d# 20 to /hash-digest  ;
: use-sha256  ( -- )  1 h# 291800 io!  d# 32 to /hash-digest  ;
: use-sha224  ( -- )  2 h# 291800 io!  d# 28 to /hash-digest  ;
: use-md5     ( -- )  3 h# 291800 io!  d# 16 to /hash-digest  ;

: hash-control!  ( n -- )  h# 291804 io!  ;
: hash-go  ( -- )
   1 h# 291808 io!
   begin  h# 29180c io@  1 and  until
   1 h# 29180c io!
;
: set-msg-size  ( n -- )
   0 h# 29181c io! \ High word of total size
   h# 291818 io!   \ Low word of total size
;
: hash-init  ( -- )
   (hash-buf) 0=  if
      /hash-block 2* " /" " dma-alloc" execute-device-method drop
      to (hash-buf)
   then
   1 h# 290c00 io!  \ Select hash (0) for Accelerator A, crossing to direct DMA to it
   dma-stop
   8 hash-control!  \ Reset
   0 hash-control!  \ Unreset
   1 hash-control!  \ Init digest
   hash-go
   0 to #hash-buf
   0 to #hashed
;

: hash-update-step  ( -- )
   hash-buf  /hash-block dma>hash   ( )
   /hash-block h# 291810 io!       ( )
   2 hash-control!  \ Update digest ( )
   hash-go                          ( )
   dma-stop
;
: copy-to-hashbuf  ( adr thislen -- )
   tuck                             ( adr thislen )
   hash-buf #hash-buf +  swap move  ( thislen )
   #hash-buf + to #hash-buf         ( )
   #hash-buf /hash-block =  if      ( )
      hash-update-step              ( )
      0 to #hash-buf
   then
;
: hash-update  ( adr len -- )
   dup #hashed + to #hashed                ( adr len )
   begin  dup   while                      ( adr len )
      2dup  /hash-block #hash-buf -  min   ( adr len adr this )
      tuck copy-to-hashbuf                 ( adr len this )
      /string                              ( adr' len' )
   repeat                                  ( adr len )
   2drop
;
: hash-final  ( -- adr len )
   #hashed set-msg-size       ( )
   #hash-buf h# 291810 io!   ( )
   #hash-buf  if
      hash-buf #hash-buf  dma>hash         ( )
   then
   7 hash-control!  \ Final, with hardware padding
   hash-go
   dma-stop
   h# 291820 +io /hash-digest
;
: hash1  ( adr len -- )
   hash-init           ( adr len )
   hash-update         ( adr' len' )
   hash-final
;
0 [if]
: hash2  ( adr1 len1 adr2 len2 -- digest$ )
   third over +  >r   ( adr1 len1 adr2 len2 r: total-len )
   hash-init          ( adr1 len1 adr2 len2 r: total-len )
   2swap hash-update  ( adr2 len2  r: total-len )
   hash-update        ( r: total-len )
   r> hash-done       ( digest$ )
;
[then]

: md5  ( adr len -- digest$ )  use-md5  hash1  ;
\ alias $md5digest1 md5

\ : $md5digest2  ( adr1 len1 adr2 len2 -- digest$ )  use-md5 hash2  ;

: sha-256  ( adr len -- digest$ )   use-sha256 hash1  ;

: sha1  ( adr len -- digest$ )  use-sha1 hash1  ;

\ The following interface is for the benefit of ofw/wifi/hmacsha1.fth
d# 20 constant /sha1-digest
0 value sha1-digest
: sha1-init   use-sha1 hash-init  ;
: sha1-update hash-update  ;
: sha1-final hash-final drop to sha1-digest  ;

: ebg-set  ( n -- )  h# 292c00 io@  or  h# 292c00 io!  ;
: ebg-clr  ( n -- )  invert  h# 292c00 io@  and  h# 292c00 io!  ;

0 [if]
\ This is the procedure recommended by the datasheet, but it doesn't work
: init-entropy-digital  ( -- )
\   h# ffffffff ebg-clr   \ All off
   h# 00008000 ebg-set   \ Digital entropy mode
   h# 00000400 ebg-clr   \ RNG reset
   h# 00000200 ebg-set   \ Bias power up
   d# 400 us
   h# 00000100 ebg-set   \ Fast OSC enable
   h# 00000080 ebg-set   \ Slow OSC enable
   h# 02000000 ebg-set   \ Downsampling ratio
   h# 00110000 ebg-set   \ Slow OSC divider
   h# 00000400 ebg-set   \ RNG unreset
   h# 00000040 ebg-set   \ Post processor enable
   h# 00001000 ebg-set
;
[else]
\ This procedure works
: init-entropy  ( -- )  \ Using digital method
   h# 21117c0 h# 292c00 io!
;
[then]

: random-short  ( -- w )
   begin  h# 292c04 io@  dup 0>=  while  drop  repeat
   h# ffff and
;
: random-byte  ( -- b )  random-short 2/ h# ff and  ;
: random-long  ( -- l )
   random-short random-short wljoin
;
alias random random-long

stand-init: Random number generator
   init-entropy
;

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
