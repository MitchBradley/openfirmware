\ See license at end of file
purpose: ARM Linux zImage program loading

defer linux-hook      ' noop to linux-hook
defer linux-pre-hook  ' noop to linux-pre-hook

0 value ramdisk-adr
0 value /ramdisk

0 value linux-memtop

defer memory-limit
\ Find the end of the largest piece of memory
: (memory-limit)  ( -- limit )
   \ If we have already loaded a RAMdisk in high memory, its base is the memory limit
   ramdisk-adr  ?dup  if  exit  then

   0 0                                                 ( size base )
   " /memory" find-package 0= abort" No /memory node"  ( size base phandle )
   " available" rot get-package-property abort" No memory node available property"  ( limit size $ )
   \ Find the largest memory piece
   begin  dup  8 >=  while           ( size base $ )
      2 decode-ints                  ( size base $ size1 base1 )
      5 pick 2 pick <=  if           ( size base $ size1 base1 )
         2>r 2nip 2r>                ( $ size1 base1 )
         2swap                       ( size' base' $ )
      else                           ( size base $ size1 base1 )
	 2drop                       ( size base $ )
      then                           ( size base $ )
   repeat                            ( size base $ )
   2drop                             ( size base )
   +                                 ( limit )
;
' (memory-limit) to memory-limit  \ Override by platform code if necessary

\ see http://www.simtec.co.uk/products/SWLINUX/files/booting_article.html

0 value arm-linux-machine-type  \ Set this after loading this file
h# 100 value linux-params       \ The location recommended by the above article
h# 10.0000 value linux-base
0 value rootdev#                \ Set externally

0 value tag-adr
: tag-w,  ( w -- )  tag-adr w!  tag-adr wa1+ to tag-adr  ;
: tag-b,  ( b -- )  tag-adr c!  tag-adr ca1+ to tag-adr  ;
: tag-l,  ( n -- )  tag-adr l!  tag-adr la1+ to tag-adr  ;

defer fb-tag,  ' noop to fb-tag,   \ Define externally if appropriate
defer ofw-tag, ' noop to ofw-tag,  \ Define externally if appropriate

: set-parameters  ( cmdline$ -- )
   linux-params to tag-adr

   5           tag-l,    \ size   
   h# 54410001 tag-l,    \ ATAG_CORE
   0           tag-l,    \ Flags (1 for read-only)
   pagesize    tag-l,
   rootdev#    tag-l,

   4            tag-l,
   h# 54410002  tag-l,    \ ATAG_MEM
   linux-memtop tag-l,    \ size
   0            tag-l,    \ start_address

   /ramdisk  if
      4              tag-l,
      h# 54420005    tag-l,          \ ATAG_INITRD2
      ramdisk-adr >physical tag-l,   \ physical starting address
      /ramdisk       tag-l,          \ size of compressed ramdisk in bytes
   then

   \ Command line
   ( cmdline$ )                  ( adr len )
   dup  if                       ( adr len )
      1+ 4 round-up              ( adr len+null_rounded )
      dup  2 rshift  2 +  tag-l, ( adr len+null_rounded )  \ tag size
      h# 54410009         tag-l, ( adr len+null_rounded )  \ ATAG_CMDLINE
      tuck  tag-adr swap move    ( len+null_rounded )      \ copy in cmdline
      tag-adr +  to tag-adr      ( )
   else                          ( adr len )
      2drop                      ( )
   then

   fb-tag,

   ofw-tag,

   0 tag-l,    \ size of ATAG_NONE is really 2 but must be written as 0
   0 tag-l,    \ ATAG_NONE
;

0 value use-fdt?
: use-fdt  ( -- )  true to use-fdt?  ;

: linux-fixup  ( -- )
[ifdef] linux-logo  linux-logo  [then]
   use-fdt? 0=  if
      args-buf cscount set-parameters          ( )
   then
   disable-interrupts

   linux-base linux-base  (init-program)    \ Starting address, SP
   0 to r0
   arm-linux-machine-type to r1
[ifdef] flatten-device-tree
   use-fdt?  if
      flatten-device-tree to r2
   else
      linux-params to r2
   then
[else]
   linux-params to r2
[then]
   linux-hook
;

d# 256 buffer: ramdisk-buf
' ramdisk-buf  " ramdisk" chosen-string

defer load-ramdisk
defer place-ramdisk
: linux-place-ramdisk  ( adr len -- )
   to /ramdisk                                    ( adr )

   dup memory-limit  umin  /ramdisk -             ( adr new-ramdisk-adr )
   tuck /ramdisk move                             ( new-ramdisk-adr )
\  dup to linux-memtop
   to ramdisk-adr

   ramdisk-adr " linux,initd-start"  chosen-int-property
   ramdisk-adr /ramdisk +  " linux,initd-end"  chosen-int-property
;
: $load-ramdisk  ( name$ -- )
   0 to /ramdisk                                  ( name$ )

   ['] load-path behavior >r                      ( name$ r: xt )
   ['] ramdisk-buf to load-path                   ( name$ r: xt )

   ." Loading ramdisk image from " 2dup type  ."  ..."  ( name$ r: xt )
   ['] boot-read catch                            ( throw-code r: xt )
   cr                                             ( throw-code r: xt )
   r> to load-path                                ( throw-code )
   throw

   loaded place-ramdisk
;
: cv-load-ramdisk  ( -- )
   " ramdisk" eval  dup 0=  if  2drop exit  then  ( name$ )
   $load-ramdisk
;
' cv-load-ramdisk to load-ramdisk

0 value linux-loaded?

: init-zimage?   ( -- flag )
   loaded                               ( adr len )
   h# 30 <  if  drop false exit  then   ( adr )
   dup h# 24 + l@  h# 016f2818  <>  if  drop false exit  then   ( adr )
   >r
   r@ h# 28 + l@  r@ +                  ( start r: adr )
   r@ h# 2c + l@  r@ +                  ( start end r: adr )
   r> drop                              ( start end )
   over -                               ( start len )
   
   linux-base swap move                 ( )

   true to linux-loaded?                ( )

   true                                 ( flag )
;

warning @ warning off
: init-program  ( -- )
   init-zimage?  if  exit  then
   init-program
;
warning !

warning @ warning off
: init-program  ( -- )
   false to linux-loaded?
   init-program
   linux-loaded?  if
      ['] linux-place-ramdisk to place-ramdisk
      linux-pre-hook
      memory-limit 1meg round-down  to linux-memtop  \ load-ramdisk may change this
      ['] load-ramdisk guarded
      linux-fixup
   then
;
warning !

: mcr  ( -- )  cr exit? throw  ;

\ Hack to force the vaddr to a paddr, because the Linux kernel expects to be
\ started at physical addresses.
: (linux-elf-map-in)  ( va size -- )
   drop                 ( va )
   h# c000.0000 u>  if  ( )
      p32_vaddr h# c000.0000 -  dup elf32-pheader >p32_vaddr l!  ( pa )
      to linux-base
      true to linux-loaded?
   then
;
' (linux-elf-map-in) to elf-map-in

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
