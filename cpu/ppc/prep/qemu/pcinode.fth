purpose: System-specific portions of PCI bus package
\ See license at end of file

dev /pci

d# 33,333,333 " clock-frequency"  integer-property

create slot-map

\   Dev#    Pin A  Pin B  Pin C  Pin D
    b c,   -1 c,  -1 c,  -1 c,  -1 c,   \ ISA
    1 c,    d c,  -1 c,  -1 c,  -1 c,   \ SCSI
    2 c,    f c,  -1 c,  -1 c,  -1 c,   \ VGA
    3 c,    f c,  -1 c,  -1 c,  -1 c,   \ Ethernet
    4 c,    f c,   f c,   f c,   f c,   \ Slot 4
    5 c,    f c,   f c,   f c,   f c,   \ Slot 5
    ff c,                               \ End of list

fload ${BP}/dev/pci/intmap.fth      \ Generic interrupt mapping code

0 value slot-map-#

: make-residual-slot-map                      ( adr len -- adr' len' )
   slot-map                                   ( ... adr )
   begin  dup c@  h# ff <>  while             ( ... adr )
      \ Each table entry contains dev#,pin1,pin2,pin3,pin4
      \ We loop over the pin numbers and create map entries for each
      \ valid pin entry.
      \ assume isa being the first entry
      dup c@ slot-map-# 0 =                   ( ... adr slot flag )
       if ( adr slot ) 3 lshift 0 swap rot -1 ( ... slot fn adr irqtype )
       else dup 3 lshift rot 1                ( ... slot fn adr irqtype )
      then swap                               ( ... slot fn irqtype adr )
      5 1  do
         dup i + c@ dup ff =  if drop -1 then swap ( ... irq adr )
      loop                                    ( ... slot fn irqtype irq1 .. irq4 adr )
      >r +slot r>                             ( adr )
      5 +                                     ( adr' )
      slot-map-# 1 + to slot-map-#            ( adr )
   repeat                                     ( adr )
   drop
;
   4 " aix-bus-id" integer-property
   06.04.01 41.d0.0a.03 aix-id
   start-encode
   cf8 8 +reg32                    \ Index/data registers for config cycles
   " "(75 01 4d 24 01 00)" +bytes \ SID1

   6 ( #devices )  start-pci-descriptor
   80000cf8 +le64  80000cfc +le64  0 +byte  " "(00 00 00)" +bytes
   make-residual-slot-map
   d# 33,333,333  6  +bus-attributes \ 6 Slots

   1 1 c000.0000 0000.0000 3f00.0000 +bus-range   \ PCI memory space
   1 2 8000.0000 0000.0000 0080.0000 +bus-range   \ I/O space before config
   1 2 8100.0000 0100.0000 3e80.0000 +bus-range   \ I/O space after config
   1 3 0000.0000 8000.0000 8000.0000 +bus-range   \ DMA up to system

   " pnp-data" property
external

h#    1.c000  " bus-master-capable"          integer-property

h# 60 encode-int				\ Mask of implemented slots
" PCI Slot 4" encode-string encode+
" PCI Slot 5" encode-string encode+ " slot-names" property

: config-setup  ( config-adr -- vaddr )
   \ Bit 31 ("enable") must be 1, bits 30:24 ("reserved") must be 0,
   \ bits 1:0 must be 0.
   dup h# ff.fffc and  h# 8000.0000 or  h# cf8 pl!  ( config-adr )
   3 and  h# cfc +  \ Merge in the byte selector bits
;

: config-b@  ( config-adr -- b )  config-setup pc@ ;
: config-w@  ( config-adr -- w )  config-setup pw@  ;
: config-l@  ( config-adr -- l )  config-setup pl@ ;
: config-b!  ( b config-adr -- )  config-setup pc! ;
: config-w!  ( w config-adr -- )  config-setup pw! ;
: config-l!  ( l config-adr -- )  config-setup pl! ;

\  ------PCI Address-------    ---Host Address--     -- size --
\ phys.hi    .mid      .low    phys.hi       .lo       .hi .lo  \ 40p

0 0 encode-bytes
0100.0000 +i  0+i         0+i  8000.0000 +i     0+i    1.0000 +i  \ ISA I/O
0100.0000 +i  0+i 100.0000 +i  8100.0000 +i     0+i 3e80.0000 +i  \ PCI I/O
0200.0000 +i  0+i         0+i  c000.0000 +i     0+i 3f00.0000 +i  \ PCI Mem
   " ranges" property

: pnp-decode-reg  ( adr len -- adr' len'  [ d.size d.base info type ] flag )
      decode-int drop  decode-int drop  decode-int drop
      decode-int drop  decode-int drop
      0
;
device-end

" b,5,4,3,2,1"  dup config-string pci-probe-list

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

