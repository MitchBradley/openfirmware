purpose: Save the Forth dictionary image in a file in ARM64 image format
\ See license at end of file

\ save-forth  ( filename -- )
\       Saves the Forth dictionary to a file so it may be later used under Unix
\
\ save-image  ( header-adr header-len init-routine-name filename -- )
\       Primitive save routine.  Saves the dictionary image to a file.
\       The header is placed at the start of the file.  The latest definition
\       whose name is the same as the "init-routine-name" argument is
\       installed as the init-io routine.

hex

variable dictionary-size

\ only forth also hidden also
\ hidden definitions
\ headerless

: dict-size  ( -- size-of-dictionary )  here origin -  aligned  ;

\ headers

only forth also hidden also
forth definitions

h# 80 buffer: aif-header
   \ 00 NOP (BL decompress code)
   \ 04 NOP (BL self reloc code)
   \ 08 NOP (BL ZeroInit code)
   \ 0c BL entry (or offset to entry point for non-executable AIF header)
   \ 10 NOP (program exit instruction)
   \ 14 0   (Read-only section size)
   \ 18 Dictionary size, actual value will be set later
   \ 1c Reloc Size (ARM Debug size)
   \ 20 0 (ARM zero-init size)
   \ 24 0 (image debug type)
   \ 28 Reloc save base (image base)
   \ 2c Dictionary growth size (min workspace size)
   \ 30 d#32 (address mode)
   \ 34 0 (data base address)
   \ 38 reserved
   \ 3c reserved
   \ 40 NOP (debug init instruction)
   \ 44-7c unused (zero-init code)

decimal

: aif!  ( n offset -- )  aif-header + l!  ;
: nop!  ( offset -- )  h# d503201f swap aif!  ;

headerless
: $save-image  ( header header-len filename$ -- )
   $new-file                                  ( header header-len )

   \ There is no need to copy the user area to the initial user area
   \ image because the user area is currently accessed in-place.

   ( header header-len )    ofd @  fputs      \ Write header
   origin  dict-size        ofd @  fputs      \ Write dictionary
   ofd @ fclose
;
: make-arm64-header  ( -- )
   \ Build the header
   aif-header    h# 80 erase \ Wrapper field == ARM64 meaning
                 h# 00 nop!  \ MAGIC         == ARM64 nop
                 h# 04 nop!  \ res0[0]
                 h# 08 nop!  \ res0[1]
   h# 540003ae   h# 0c aif!  \ res0[2]       == branch past the header
\  h# 1400001d   h# 0c aif!  \ res0[2]       == branch past the header
   0             h# 10 aif!  \ res0[3]
   h# 80         h# 14 aif!  \ res0[4]       == header size
   dict-size     h# 18 aif!  \ tlen          == dictionary size
   0             h# 1c aif!  \ dlen
   0             h# 20 aif!  \ trlen
   0             h# 24 aif!  \ drlen
   h# 8000       h# 28 aif!  \ entry         == load base
 ( dictionary-size @  h# 10.0000 max )
   h# 100.0000 \ The dictionary, it needs room to GROW!
                 h# 2c aif!  \ blen          == dictionary growth size
   h# 40         h# 30 aif!  \ res1[0]       == 64-bit address mode
   dict-size     h# 10 origin+ !  \ Dictionary size
   origin        h# 18 origin+ !  \ Save base
;
headers

\ Save an image of the target system in a file.
: $save-forth64  ( str -- )
   2>r
   make-arm64-header
   " sys-init-io" $find-name is init-io
   " sys-init"    init-save

   aif-header  h# 80  2r>  $save-image
;

only forth also definitions
: $save-forth   ( name$ -- )
   $save-forth64
;

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
