purpose: Secure NAND updater
\ See license at end of file

\ Depends on words from security.fth and copynand.fth

: get-hex#  ( -- n )
   safe-parse-word
   push-hex $number pop-base  " Bad number" ?nand-abort
;

0 value min-eblock#
0 value max-eblock#

: written ( eblock# -- )
   dup
   max-eblock# max to max-eblock# ( eblock# )
   min-eblock# min to min-eblock#
;

: ?all-written  ( -- )
   max-eblock# 1+ #image-eblocks <>  if
      cr
      red-letters
      ." WARNING: The file said highest block " #image-eblocks .d
      ." but wrote only as high as block " max-eblock# .d cr
      cancel
   then
   min-eblock# 0 <>  if
      cr
      red-letters
      ." WARNING: The file did not write a zero block, "
      ." but wrote only as low as block " min-eblock# .d cr
      cancel
   then
;

0 value secure-fsupdate?
d# 128 constant /spec-maxline

\ We simultaneously DMA one data buffer onto NAND while unpacking the
\ next block of data into another. The buffers exchange roles after
\ each block.

0 value dma-buffer
0 value data-buffer

: swap-buffers  ( -- )  data-buffer dma-buffer  to data-buffer to dma-buffer  ;

: force-line-delimiter  ( delimiter fd -- )
   file @                      ( delim fd fd' )
   swap file !                 ( delim fd' )
   swap line-delimiter c!      ( fd' )
   file !                      ( )
;

: ?compare-spec-line  ( -- )
   secure-fsupdate?  if
      data-buffer /spec-maxline  filefd read-line         ( len end? error? )
      " Spec line read error" ?nand-abort                 ( len end? )
      0= " Spec line too long" ?nand-abort                ( len )
      data-buffer swap                                    ( adr len )
      source $= 0=  " Spec line mismatch" ?nand-abort     ( )
   then
;

vocabulary nand-commands
also nand-commands definitions

: zblocks:  ( "eblock-size" "#eblocks" ... -- )
   ?compare-spec-line
   get-hex# to /nand-block
   get-hex# to #image-eblocks
   #image-eblocks to min-eblock#
   0 to max-eblock#
   " size" $call-nand  #image-eblocks /nand-block um*  d<
   " Image size is larger than output device" ?nand-abort
   #image-eblocks  show-init
   get-inflater
   \ Separate the two buffers by enough space for both the compressed
   \ and uncompressed copies of the data.  4x is overkill, but there
   \ is plenty of space at load-base
   load-base to dma-buffer
   load-base /nand-block 4 * + to data-buffer
   /nand-block /nand-page / to nand-pages/block
   t-update  \ Handle possible timer rollover
;

: zblocks-end:  ( -- )
\ Asynchronous writes
   " write-blocks-end" $call-nand   ( error? )
   " Write error" ?nand-abort
   release-inflater
   fexit
;

h# 1be. 2value pt  \ device byte offset to start of partition table
h# 10 value /pe    \ size of a partition entry
/pe buffer: pe     \ partition entry buffer

: pe-seek   ( partition# -- )
   1- /pe * 0 pt d+                  ( d.pos )
   " seek" nandih $call-method drop  ( )
;

: pe-read   ( partition# -- )  pe-seek  pe /pe " read"  nandih $call-method drop  ;
: pe-write  ( partition# -- )  pe-seek  pe /pe " write" nandih $call-method drop  ;

: pe-start@   ( pe -- start )   pe h# 08 + le-l@  ;
: pe-length@  ( pe -- length )  pe h# 0c + le-l@  ;
: pe-length!  ( length pe -- )  pe h# 0c + le-l!  ;

: pe-is-set?  ( partition# -- flag )   pe-read  pe-start@ pe-length@ or  ;

: (resize:)  ( -- )
   4 pe-is-set?  abort" partition 4 is non-zero"
   3 pe-is-set?  abort" partition 3 is non-zero"
   " size" nandih $call-method d# 512 um/mod swap drop
                              ( d-end )
   2 pe-read                  ( d-end )
   pe-start@  dup >r          ( d-end p-start )  ( r: p-start )
   pe-length@ + swap          ( p-end d-end )    ( r: p-start )
   2dup > abort" partition ends beyond device size"
   2dup < if                  ( p-end d-end )    ( r: p-start )
      nip r> - pe-length!     ( )                ( r: )
      2 pe-write              ( )                ( r: )
   else                       ( p-end d-end )    ( r: p-start )
      r> 3drop                ( )                ( r: )
   then                       ( )                ( r: )
;

: data:  ( "filename" -- )
   safe-parse-word            ( filename$ )
   nb-zd-#sectors  -1 <>  if  ( filename$ )
      2drop  " /nb-updater"   ( filename$' )
   else                       ( filename$ )
      fn-buf place            ( )
      " ${DN}${PN}\${CN}${FN}" expand$  image-name-buf place
      image-name$             ( filename$' )
   then                       ( filename$ )
   r/o open-file  if          ( fd )
      drop ." Can't open " image-name$ type cr
      true " " ?nand-abort
   then  to filefd            ( )
   linefeed filefd force-line-delimiter
   true to secure-fsupdate?
;

: erase-all  ( -- )
   #image-eblocks show-writing
;

: eat-newline  ( ih -- )
   fgetc newline <>                                    ( error? )
   " Missing newline after zdata" ?nand-abort             ( )
;
: skip-zdata  ( comprlen -- )
   ?compare-spec-line                                     ( comprlen )

   secure-fsupdate?  if  filefd  else  source-id  then    ( comprlen ih )

   >r  u>d  r@ dftell                                     ( d.comprlen d.pos r: ih )
   d+  r@ dfseek                                          ( r: ih )

   r> eat-newline
;

: get-zdata  ( comprlen -- )
   ?compare-spec-line                                     ( comprlen )

   secure-fsupdate?  if  filefd  else  source-id  then    ( comprlen ih )

   >r  data-buffer /nand-block +  over  r@  fgets         ( comprlen #read r: ih )
   <>  " Short read of zdata file" ?nand-abort            ( r: ih )

   r> eat-newline

   \ The "2+" skips the Zlib header
   data-buffer /nand-block + 2+  data-buffer true  (inflate)  ( len )
   /nand-block <>  " Wrong expanded data length" ?nand-abort  ( )
;

true value check-hash?

: check-hash  ( -- )
   2>r                                ( eblock# hashname$ r: hash$ )
   data-buffer /nand-block 2swap      ( eblock# data$ hashname$ r: hash$ )
   fast-hash                          ( eblock# r: hash$ )
   2r>  $=  0=  if                    ( eblock# )
      ." Bad hash for eblock# " .x cr cr
      ." Your USB key may be bad.  Please try a different one." cr
      ." See http://wiki.laptop.org/go/Bad_hash" cr cr
      abort
   then                               ( eblock# )
;

0 value have-crc?
0 value my-crc

: ?get-crc  ( -- )
   parse-word  dup  if                   ( eblock# hashname$ crc$ r: comprlen )
      push-hex $number pop-base  if      ( eblock# hashname$ crc$ r: comprlen )
         false to have-crc?              ( eblock# hashname$ r: comprlen )
      else                               ( eblock# hashname$ crc r: comprlen )
         to my-crc                       ( eblock# hashname$ r: comprlen )
         true to have-crc?               ( eblock# hashname$ r: comprlen )
      then                               ( eblock# hashname$ r: comprlen )
   else                                  ( eblock# hashname$ empty$ r: comprlen )
      2drop                              ( eblock# hashname$ r: comprlen )
      false to have-crc?                 ( eblock# hashname$ r: comprlen )
   then                                  ( eblock# hashname$ r: comprlen )
;
: ?check-crc  ( -- )
   have-crc?  if
   then
;

: zblock: ( "eblock#" "comprlen" "hashname" "hash-of-128KiB" -- )
   get-hex#                              ( eblock# )
   get-hex# >r                           ( eblock# r: comprlen )
   safe-parse-word                       ( eblock# hashname$ r: comprlen )
   safe-parse-word hex-decode            ( eblock# hashname$ [ hash$ ] err? r: comprlen )
   " Malformed hash string" ?nand-abort  ( eblock# hashname$ hash$ r: comprlen )

   ?get-crc                              ( eblock# hashname$ hash$ r: comprlen )

\  2dup  " fa43239bcee7b97ca62f007cc68487560a39e19f74f3dde7486db3f98df8e471" $=  if  ( eblock# hashname$ hash$ r: comprlen)
\     r> skip-zdata                         ( eblock# hashname$ hash$ )
\     2drop 2drop                           ( eblock# )
\  else                                     ( eblock# hashname$ hash$ )
      r> get-zdata                          ( eblock# hashname$ hash$ )
      ?check-crc                            ( eblock# hashname$ hash$ )

      check-hash?  if                       ( eblock# hashname$ hash$ )
         check-hash                         ( eblock# )
      else                                  ( eblock# hashname$ hash$ )
         2drop 2drop                        ( eblock# )
      then                                  ( eblock# )

\ Asynchronous writes
      data-buffer over nand-pages/block *  nand-pages/block  " write-blocks-start" $call-nand  ( eblock# error? )
      " Write error" ?nand-abort   ( eblock# )
\   data-buffer over nand-pages/block *  nand-pages/block  " write-blocks" $call-nand  ( eblock# #written )
\   nand-pages/block  <>  " Write error" ?nand-abort   ( eblock# )
      swap-buffers                          ( eblock# )
\  then

   dup written                              ( eblock# )
   show-written                             ( )
   show-temperature
;

previous definitions

: $fs-update  ( file$ -- )
   load-crypto  abort" Can't load hash routines"

   open-nand                           ( file$ )

   false to secure-fsupdate?           ( file$ )
   r/o open-file                       ( fd error? )
   " Can't open file" ?nand-abort      ( fd )

   linefeed over force-line-delimiter  ( fd )

   t-hms(                              ( fd )
   also nand-commands                  ( fd )
   ['] include-file catch              ( 0 | x error# )
   previous

   show-done
   ?all-written
   close-nand-ihs
   )t-hms
   throw                               ( )
;

: fs-update  ( "devspec" -- )
   safe-parse-word $fs-update
;

: fs-resize  ( -- )
   open-nand
   [ also nand-commands ] (resize:) [ previous ]
   close-nand
;

: do-fs-update  ( img$ -- )
   tuck  load-base h# c00000 +  swap move  ( len )
   load-base h# c00000 + swap              ( adr len )

   ['] noop to show-progress               ( adr len )

   open-nand                               ( adr len )

\  clear-context  nand-commands
   t-hms(
   also nand-commands                      ( adr len )

   true to secure-fsupdate?                ( adr len )
   ['] include-buffer  catch  ?dup  if  nip nip  .error  security-failure  then

   previous
\  only forth also definitions

   show-done
   ?all-written
   close-nand-ihs
   )t-hms cr
;

: fs-update-from-list  ( devlist$ -- )
   load-crypto  if  visible  ." Crytpo load failed" cr  show-sad  security-failure   then

   visible                            ( devlist$ )
   begin  dup  while                  ( rem$ )
      bl left-parse-string            ( rem$ dev$ )
      dn-buf place                    ( rem$ )

      null$ pn-buf place              ( rem$ )
      null$ cn-buf place              ( rem$ )
      " fs" bundle-present?  if       ( rem$ )
         " Filesystem image found - " ?lease-debug
         fskey$ to pubkey$            ( rem$ )
         img$  sig$  sha-valid?  if   ( rem$ )
            2drop                     ( )
            show-unlock               ( )
            img$ do-fs-update         ( )
            ." Rebooting in 10 seconds ..." cr
            d# 10,000 ms  bye
            exit
         then                         ( rem$ )
         show-lock                    ( rem$ )
      then                            ( rem$ )
   repeat                             ( rem$ )
   2drop
;
: update-devices  " disk: ext: http:\\172.18.0.1"  ;
: try-fs-update  ( -- )
   ." Searching for a NAND file system update image." cr
   " disk: ext:" fs-update-from-list
   ." Trying NANDblaster" cr
   ['] nandblaster catch  0=  if  exit  then
   " http:\\172.18.0.1" fs-update-from-list
;

: $update-nand  ( devspec$ -- )
   load-crypto abort" Can't load the crypto functions"
   null$ cn-buf place                           ( devspec$ )
   2dup                                         ( devspec$ devspec$ )
   [char] : right-split-string dn-buf place     ( devspec$ path+file$ )
   [char] \ right-split-string                  ( devspec$ file$ path$ )
   dup  if  1-  then  pn-buf place              ( devspec$ file$ )
   2drop                                        ( devspec$ )
   boot-read loaded do-fs-update                ( )
;
: update-nand  ( "devspec" -- )  safe-parse-word  $update-nand  ;

0 0  " "  " /" begin-package
   " nb-updater" device-name
   0. 2value offset
   : size  ( -- d.#bytes )  nb-zd-#sectors h# 200 um*  ;
   : open  ( -- flag )
      nb-zd-#sectors -1 =  if
         ." nb-updater: nb-zd-#sectors is not set" cr
         false exit
      then
      nandih  0=  if
         ." nb-updater: fsdisk device is not open" cr
         false exit
      then
      " size" $call-nand  ( d.size )
      size d- to offset
      true
   ;
   : close  ;
   : seek  ( d.pos -- )  offset d+  " seek" $call-nand  ;
   : read  ( adr len -- actual )  " read" $call-nand  ;
   \ No write method for this
end-package

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
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
