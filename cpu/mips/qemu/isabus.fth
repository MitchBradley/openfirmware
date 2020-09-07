purpose: ISA bus device for QEMU MIPS PC
\ See license at end of file

hex

" isa" device-name
" isa" device-type

" pnpPNP,a00" +compatible
" isa" +compatible

2 " #address-cells" integer-property
1 " #size-cells" integer-property

0 0 encode-bytes
   isa-mem-base encode-int encode+             \ ISA memory MMIO address
   h# 0100.0000 encode-int encode+             \ 16M
   isa-io-base encode-int encode+              \ ISA I/O MMIO address
   h# 0001.0000 encode-int encode+             \ 64K
   " reg" property

0 0 encode-bytes
   0 encode-int encode+  0 encode-int encode+  \ ISA memory
   isa-mem-base encode-int encode+             \ MMIO address
   h# 0100.0000 encode-int encode+             \ 16M
   1 encode-int encode+  0 encode-int encode+  \ ISA I/O
   isa-io-base encode-int encode+              \ MMIO address
   h# 0001.0000 encode-int encode+             \ 64K
   " ranges" property

2 " #interrupt-cells" integer-property \ ???

headers
\ Static methods
\ Text representation:  nnn (I/O space)  innn (I/O space)  mnnn (memory space)
\ Numeric representation:  hi cell: 0-memory 1-I/O  lo cell: offset

: decode-unit  ( adr len -- phys.lo phys.hi )
   base @ >r hex
   dup  if
      over c@  upc  case
         ascii I  of  1 /string   1    endof
         ascii M  of  1 /string   0    endof
         ( default )  1 swap			\ Default to "IO"
      endcase                               ( adr len phys.hi )
      -rot  $number  if  0  then   swap     ( phys.lo phys.lo )
   else
      2drop 0 0
   then
   r> base !
;
: encode-unit  ( phys.lo phys.hi -- adr len )
   base @ >r hex
   >r  <# u# u#s
   r>  1 and  if  ascii i  else  ascii m  then  hold
   u#>
   r> base !
;

\ Not-necessarily-static methods
: open  ( -- true )  true  ;
: close  ( -- )  ;

: map-in   ( phys.lo phys.hi size -- virt )
   drop  if  isa-io-base  else  isa-mem-base  then  kseg1 + +
;
: map-out  ( virt size -- )
   2drop
;

: dma-map-in  ( vaddr len cacheable -- devaddr )  " dma-map-in" $call-parent  ;
: dma-map-out  ( vaddr devaddr len -- )  " dma-map-out" $call-parent  ;
: dma-alloc  ( size -- vadr )  " dma-alloc" $call-parent  ;
: dma-free ( vaddr len -- )  " dma-free" $call-parent  ;

\ XXX Should we define methods for allocating ISA DMA channels?

: probe-self  ( arg$ reg$ fcode$ -- )
   true abort" probe-self for ISA is not yet implemented"  ( XXX )
;

headers
: init  ( -- )
   " /isa/interrupt-controller" find-package  if
      " interrupt-parent" integer-property
   then
;

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
\ Copyright (c) 2020 Lubomir Rintel <lkundrak@v3.sk>
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
