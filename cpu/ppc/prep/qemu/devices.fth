purpose: Load file for devices of QEMU -M prep
copyright: Copyright 1999 FirmWorks Inc.  All Rights Reserved.

fload ${BP}/cpu/ppc/prep/qemu/pcinode.fth

: unswizzle-move  ( arc dest len -- )  move  ;

0 0  " fff00000"  " /" begin-package
   " flash" device-name
   h# 10.0000 dup constant /device constant /device-phys
   my-address my-space /device reg
   fload ${BP}/dev/flashpkg.fth

end-package

\ This must precede isamisc.fth in the load file, to execute it first
fload ${BP}/cpu/x86/pc/moveisa.fth

\ Create the /ISA node in the device tree, and load the ISA bridge code.
\ Usually this includes the dma controller, interrupt controller, and timer.
0 0  " b"  " /pci" begin-package
fload ${BP}/dev/via/vt82c586.fth			\ ISA node
   1 " aix-bus-id" integer-property  \ Add properties and interface procedures
   1 " aix-serial#" integer-property \ used by make-residual-data
   2800 aix-flags
   06.01.00  41.d0.0a.00 aix-id
   : pnp-decode-reg  ( adr len -- adr' len' d.size d.base info type )
      decode-int >r  decode-int >r  decode-int  ( adr,len sz ) ( r: physhi,lo )
      r>                                ( adr,len size base ) ( r: physhi )
      r>  dup 1 and  if    \ I/O        ( adr,len size base physhi )
         2 and  if  0  else  1  then    ( adr' len' d.s d.b 16bit )
         true              \ short tag  ( adr' len' d.s d.b 16bit isa-io )
      else                 \ memory     ( adr,len size base physhi )
         drop                           ( adr,len size base )
         \ Convert the address and size to 64-bit numbers
         0 tuck                         ( adr,len d.size d.base )
         d# 32  2                       ( adr,len d.size d.base #bits type )
         false             \ long tag   ( adr,len d.size d.base #bits type tag)
      then
      true
   ;
   : pnp-decode-interrupt  ( adr len -- adr' len' irq-mask flags )
      0 >r
      begin  dup  while  decode-int  1 swap lshift r> or >r ( adr'' len'' )
       " #interrupt-cells" get-property 0= if decode-int -rot 2drop ( adr'' len'' #interrupt-cells )
        \ ISA has #interrupt-cells =2, the second cell is interrupt type
        2 = if decode-int drop then                         ( adr' len' )
        then
      repeat
      r> 0
   ;
   : make-pnp-data  ( -- adr len )
      start-encode
      " "(75 01 24 4d 00 81)" +bytes    \ IBM8100 (82378)

      \ ISA 398,399 and 800-807 ports with 32-bit decoding
       61  1 +isa-reg
      398  2 +isa-reg  \ Index/data registers for SuperI/O
      800  8 +isa-reg  \ "orphan" ISA addresses, whatever that means

      d# 8,250,000  3  +bus-attributes

      \ Mapping from ISA interrupts to system interrupts, indexed by IRQ#
      \ Type = 0A, IntCtlrType (1 byte), IntCtlr# (1 bytes), IntMap(16*2 bytes)
      " "(84 23 00 0A 01 00)" +bytes  10 0  do  i +le16  loop

      chrp?  if
         0 1 cf00.0000 0000.0000 0100.0000 +bus-range   \ ISA memory space
         0 2 fa00.0000 0000.0000 0001.0000 +bus-range   \ ISA I/O space
      else
         0 1 C000.0000 0000.0000 0100.0000 +bus-range   \ ISA memory space
         0 2 8000.0000 0000.0000 0001.0000 +bus-range   \ ISA I/O space
      then
   ;
end-package

fload ${BP}/dev/isa/irq.fth

dev /interrupt-controller
   08.00.01 41.d0.00.00 aix-id
   2 encode-int  d encode-int encode+  " interrupts" property
device-end
dev /isa/dma-controller
   08.01.01 41.d0.02.00 aix-id
   2800 aix-flags
   4 encode-int " dma" property
device-end

dev /timer
   08.02.01 41.d0.01.00 aix-id
   24.4d.10.8f chip-id     \ value for 8254
device-end

support-package: 16550
fload ${BP}/dev/16550pkg/16550.fth  \ Serial port support package
end-support-package

\ Super I/O support.
\ Usually includes serial, parallel, floppy, and keyboard.
\ The 87308 also has gpio and power control functions.
fload ${BP}/dev/isa/pc87307.fth			\ SuperI/O

dev /serial@i3f8
   07.00.04 41.D0.05.01 aix-id
   21c3 aix-flags
   1 " slave" integer-property
   start-encode  3f8 8 +reg11  " aix-reg" property
dev /pci/isa@b/serial@2f8
   07.00.04 41.D0.05.01 aix-id
   21c3 aix-flags
   2 " slave" integer-property
   start-encode  2f8 8 +reg11  " aix-reg" property
device-end

dev /8042
   \ Make the child devices appear connected to the ISA bus
   \ in the residual data
   1 " aix-bus-id" integer-property
   : pnp-decode-interrupt   " pnp-decode-interrupt" $pcall-parent  ;
   : pnp-decode-reg         " pnp-decode-reg"       $pcall-parent  ;
device-end

dev /keyboard
   09.00.00 41.d0.03.03 aix-id
   289a aix-flags
   start-encode  60 1 +reg16  64 1 +reg16  " aix-reg" property
device-end

dev /mouse
   09.02.00 41.d0.0f.03 aix-id
   2892 aix-flags
   start-encode  60 1 +reg16  64 1 +reg16  " aix-reg" property
device-end

\ QEMU doesn't have rtc/nvram on port 70
" /rtc"  find-package  if  delete-package  then

0 0 " i74" " /isa" begin-package	 \ RTC node
   fload ${BP}/dev/m48t559.fth
   08.03.01 41.d0.0b.00 aix-id
   24.4d.00.8f chip-id
   start-encode  70 2 +fixed-isa-reg  10 1 +fixed-isa-reg 12 1 +fixed-isa-reg " aix-reg" property
   " "(76 00 01 f8 1f 00 00)" encode-bytes " other-pnp-data" property
end-package

fload ${BP}/cpu/ppc/prep/qemu/fixednv.fth  \ Offsets of fixed regions of NVRAM 


fload ${BP}/cpu/ppc/prep/qemu/macaddr.fth

0 0  " i74"  " /pci/isa" begin-package	  \ NVRAM node
   fload ${BP}/dev/ds1385n.fth

   " mk48t18-nvram" encode-string
   " ds1385-nvram"  encode-string encode+
   " pnpPNP,8"      encode-string encode+
   " compatible" property
   08.05.00 24.4d.00.08 aix-id
   24.4d.00.8f chip-id
   env-end-offset to /nvram
end-package

stand-init: NVRAM
   " /nvram" open-dev  to nvram-node
    init-config-vars
;

0 0 " b,1" " /pci" begin-package
   fload ${BP}/dev/ide/pcilintf.fth
   fload ${BP}/dev/ide/generic.fth
   fload ${BP}/dev/ide/onelevel.fth
end-package
\ One-level IDE

\ Mark all ISA devices as built-in.
" /isa" find-device  mark-builtin-all  device-end

