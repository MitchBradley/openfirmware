\ See license at end of file
purpose: Changing manufacturing data - adding and deleting tags

\ Set the write protect tag.  This is used to convert unlocked prototype
\ machined to locked machines for testing the firmware security.  This
\ should not be necessary once mass production systems start coming from
\ the factor with the "wp" tag set.

\ You can turn "ww" into "wp" just by clearing bits, which doesn't
\ require a full erase.  That is faster and safer than copying out the
\ data, erasing the block and rewriting it.

: wp-loc$  ( -- adr len )  mfg-data-top 2-  2  ;
: enable-security  ( "serialnumber" -- )
   board-revision  h# b48 <  abort" Only supported on B4 and later"
   wp-loc$  " wp"  $=  if  ." wp is already set" cr  exit  then
   " SN" find-tag 0=  abort" No serial number (SN tag); enabling security would brick me."  ( sn$ )
   -null            ( sn$' )
   safe-parse-word  ( sn$ confirmation$ )
   $= 0=  abort" Confirmation code mismatch"   

   " Enabling security is dangerous.  Are you sure you want to do it?" confirmedn?
   0= abort" Canceled"

   " U#" find-tag 0=  abort" No U# tag; enabling security would brick me." 2drop
   wp-loc$  " ww"  $=  0=  abort" No ww tag"
   spi-start  spi-identify
   " wp"  h# efffe  write-spi-flash
   wp-loc$ " wp"  $=  if  ." Succeeded" cr  then
   spi-reprogrammed
;

\ Set and clear the write-protect tag by copying, erasing, rewriting

: (put-mfg-data)
   hdd-led-on
   mfg-data-buf  mfg-data-end-offset mfg-data-offset  write-flash-range
   hdd-led-off
;

: ram-find-tag  ( name$ -- false | data$ true )
   mfg-data-buf /flash-block +  (find-tag)
;

[ifdef] /flash-page
: set-cp  ( adr -- )
   " CP" find-tag  if           ( adr len )
      2drop [char] C            ( expected )
   else                         ( )
      0                         ( expected )
   then                         ( expected )
   swap c!                      ( )
;

: set-ap  ( adr -- )
   " AP" find-tag  if           ( adr len )
      2drop [char] A            ( expected )
   else                         ( )
      0                         ( expected )
   then                         ( expected )
   swap 1+ c!                   ( )
;

/flash-page buffer: ec-flags-buf
: ?sync-ec  ( -- )
   ec-flags-buf /flash-page erase
   ec-flags-buf set-cp
   ec-flags-buf set-ap
   ec-flags-buf ?reflash-ec-flags
;
[else]
: ?sync-ec  ;
[then]

\ Write mfg data from RAM to FLASH
: put-mfg-data  ( -- )
   spi-start spi-identify
   (put-mfg-data)
   ?sync-ec
   spi-reprogrammed
;

\ Find RAM address of tag, given FLASH address
: tag>ram-adr  ( adr len -- ram-adr )
   drop                         ( adr' )   \ Address of  "ww" tag
   rom-pa mfg-data-offset +  -  ( offset )

   dup /flash-block u>= abort" Bad tag offset"        \ Sanity check

   mfg-data-buf +               ( ram-adr )
;

\ Get ready to modify the tag whose name is tag$
: mfg-data-setup  ( tag$ -- ram-adr )
   get-mfg-data
   2dup  find-tag  0=  if  ." No " type ."  tag" cr  abort  then  ( tag$ adr len )
   \ The 2+ below skips the length bytes to the tagname field
   tag>ram-adr  2+ >r                         ( tag$ r: ram-adr )
   r@ 2 $=  0= abort" Tag mismatch in RAM"    ( r: ram-adr )
   r>
;

[ifdef] notdef
\ Change the "ww" tag to "wp"
: hard-set-wp  ( -- )
   " ww" mfg-data-setup  ( ram-adr )
   [char] p  swap 1+ c!  ( )
   put-mfg-data
;
[then]

\ Change the "wp" tag to "ww"
: clear-wp  ( -- )
   " wp" mfg-data-setup  ( ram-adr )
   [char] w  swap 1+ c!  ( )
   put-mfg-data
;

alias disable-security clear-wp

: ?tagname-valid  ( tagname$ -- tagname$ )
   dup 2 <> abort" Tag name must be 2 characters long"
;
: ?wp-tag  ( tagname$ -- tagname$ )
   2dup " wp" $=  abort" Use enable-security for the wp tag"
;
: tag-setup  ( tagname$ -- ram-value$ )
   ?tagname-valid
   get-mfg-data
   2dup  find-tag  0=  if  ." No " type ."  tag" cr  abort  then  ( tagname$ value$ )
   2nip                    ( value$ )
   tuck tag>ram-adr swap   ( ram-value$ )
;

: value-mismatch?  ( new-value$ old-value$ -- flag )
   dup  if
      \ non-empty old value string
      2dup + 1- c@  0=  if         ( new-value$ old-value$ )
         \ Old value ends in null character; subtract that from the count
         1-                        ( new-value$ old-value$' )
      then                         ( new-value$ old-value$ )
      rot <>                       ( new-adr old-adr flag )
      nip nip                      ( old-len new-value$ )
   else                            ( new-value$ old-value$ )
      \ empty old value string; new one had better be empty too
      2drop  0<>  nip              ( flag )
   then
;

: $change-tag  ( value$ tagname$ -- )
   ?wp-tag
   tag-setup  ( new-value$ old-value$ )
   2over 2over  value-mismatch?  abort" New value and old value have different lengths"
   drop swap move   ( )
   put-mfg-data
;

: change-tag  ( "tagname" "new-value" -- )
   safe-parse-word  ( tagname$ )
   0 parse          ( tagname$ new-value$ )
   2swap $change-tag
;

: ram-last-mfg-data  ( -- adr )
   mfg-data-buf /flash-block +  last-mfg-data
;

: ($add-tag)  ( value$ name$ -- )
   ram-last-mfg-data  >r                          ( value$ name$ r: adr )

   \ Check for enough space for the new tag
   2 pick                                         ( value$ name$ datalen r: adr )
   dup d# 16383 >  abort" Tag data too long"
   dup d# 127 >  if  4  else  3  then  +          ( value$ name$ datalen' r: adr )
   over +                                         ( value$ name$ record-len r: adr )
   r@ over -  mfg-data-buf u<=  abort" Not enough space for new tag"

   \ Ensure that the space is not being used for something else
   r@ over -  swap  ?erased                       ( value$ name$ r: adr )

   \ Copy the tag name
   r@ 2- swap move                                ( value$ r: adr )

   \ Set the length field
   dup                                            ( value$ len r: adr )
   dup d# 127 >  if                               ( value$ len r: adr )
      \ 5-byte tag format - (top) check, lowlen, highlen (bottom)
      dup 7 rshift  swap h# 7f and                ( value$ len-high len-low r: adr )
      2dup xor  h# ff xor                         ( value$ len-high len-low check r: adr )
      r@ 3 - c!  r@ 4 - c!  r@ 5 - c!             ( value$ r: adr )
      r> 5 -                                      ( value$ end-adr )
   else                                           ( value$ len' r: adr )
      \ 4-byte tag format - (top) len, ~len (bottom)
      dup r@ 3 - c!  invert r@ 4 - c!             ( value$ r: adr )
      r> 4 -                                      ( value$ end-adr )
   then                                           ( value$ end-adr )

   \ Copy the value data
   over -  swap move                              ( )
;
: $add-tag  ( value$ name$ -- )
   ?wp-tag
   ?tagname-valid                                 ( value$ name$ )
   2dup find-tag  abort" Tagname already exists"  ( value$ name$ )

   get-mfg-data                                   ( value$ name$ )
   ($add-tag)                                     ( )
   put-mfg-data                                   ( )
;

: add-null  ( adr len -- adr' len' )  $cstr  cscount 1+   ;

: add-tag  ( "name$" "value$" -- )
   safe-parse-word  0 parse add-null  2swap $add-tag
;

\ Deletes a tag from a RAM image of the mfg data
: ($delete-tag)  ( adr len -- )
   2dup  ram-find-tag  0=  if  2drop exit  then  ( tagname$ ram-value$ )
   2nip                         ( ram-value$ )

   2dup + c@ h# 80 and          ( ram-value$ tag-style )
   if  4  else  5  then  +  >r  ( tag-adr tag-len )
   ram-last-mfg-data  >r        ( tag-adr r: len bot-adr ) 
   r@  2r@ +                    ( tag-adr src-adr dst-adr r: len bot-adr )    
   rot r@ -                     ( src-adr dst-adr copy-len r: len bot-adr ) 
   move                         ( r: len bot-adr )
   r> r> h# ff fill             ( )
;

: $delete-tag  ( name$ -- )
   tag-setup                    ( ram-value$ )
   2dup + c@ h# 80 and          ( ram-value$ tag-style )
   if  4  else  5  then  +  >r  ( tag-adr tag-len )
   ram-last-mfg-data  >r        ( tag-adr r: len bot-adr ) 
   r@  2r@ +                    ( tag-adr src-adr dst-adr r: len bot-adr )    
   rot r@ -                     ( src-adr dst-adr copy-len r: len bot-adr ) 
   move                         ( r: len bot-adr )
   r> r> h# ff fill             ( )
   put-mfg-data
;

: delete-tag  ( "name" -- )  safe-parse-word $delete-tag  ;

: add-tag-from-file  ( "name" "filename" -- )
   safe-parse-word 2>r  ( r: name$ )
   reading              ( r: name$ )
   ifd @ fsize >r       ( r: name$ len )
   r@ alloc-mem         ( adr r: name$ len )
   dup r@ ifd @ fgets   ( adr actual r: name$ len )
   ifd @ fclose         ( adr actual r: name$ len )
   r@ <> abort" File read error"  ( adr r: name$ len )
   r>  2dup  2r>        ( data$ data$ name$ )
   $add-tag             ( data$ )
   free-mem
;

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
