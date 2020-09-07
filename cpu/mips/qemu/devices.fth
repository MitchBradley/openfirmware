purpose: Device drivers for QEMU MIPS PC
\ See license at end of file

hex

fload ${BP}/dev/isa/irq.fth
fload ${BP}/cpu/x86/pc/isatick.fth

support-package: 16550
fload ${BP}/dev/16550pkg/16550.fth
end-support-package

fload ${BP}/cpu/mips/qemu/cpunode.fth

0 0  " 10000000"  " /"  begin-package
   fload ${BP}/cpu/mips/qemu/isabus.fth

   also forth definitions
   stand-init: ISA
      " /isa" " init"  execute-device-method drop
   ;
   previous definitions
end-package

0 0  " i20"  " /isa" begin-package
   0 0 encode-bytes  " interrupt-controller" property

   2 " #interrupt-cells" integer-property

   " interrupt-controller" device-name
   " interrupt-controller" device-type

   20 1 2 encode-reg
   a0 1 2 encode-reg encode+
   4d0 1 2 encode-reg encode+
   " reg" property

   fload ${BP}/dev/i8259.fth
   " pnpPNP,0" +compatible
   " pnpPNP,000" +compatible
   " intel,i8259" +compatible

   also forth definitions
   stand-init: Interrupt Controller
      " /isa/interrupt-controller"  " init"  execute-device-method drop
   ;
   previous definitions
end-package

0 0  " i40" " /isa" begin-package
   " timer" device-name
   " timer" device-type

   40 1 4 encode-reg
   61 1 1 encode-reg encode+
   " reg" property

   0 encode-int  3 encode-int encode+  " interrupts"  property

   fload ${BP}/dev/i8254.fth
   " pnpPNP,100" +compatible
   " intel,i8253" +compatible

   also forth definitions
   stand-init: Timer
      " /isa/timer" " init"  execute-device-method drop
   ;
   previous definitions
end-package

fload ${BP}/dev/pci/isakbd.fth

0 0  " i70"  " /isa" begin-package
   2 " device#" integer-property
   8 encode-int  0 encode-int encode+    " interrupts" property

   fload ${BP}/dev/ds1385r.fth
   " motorola,mc146818" +compatible

   also forth definitions
   stand-init: RTC
      " /rtc" open-dev  clock-node !
   ;
   previous definitions
end-package

0 0 " i1f0" " /isa" begin-package
   0 0 encode-bytes
      15 encode-int encode+ 3 encode-int encode+
      14 encode-int encode+ 3 encode-int encode+
    " interrupts" property
   " ata-generic" +compatible
   create include-secondary-ide
   fload ${BP}/dev/ide/isaintf.fth
   fload ${BP}/dev/ide/generic.fth
   2 to max#drives
   fload ${BP}/dev/ide/onelevel.fth
end-package

0 0  " i300" " /isa" begin-package
   9 encode-int  3 encode-int encode+    " interrupts" property
   start-module
      fload ${BP}/dev/ne2000/ne2000.fth
   end-module
end-package

0 0  " i3b0" " /isa" begin-package
   " vga" device-name

   0 0 encode-bytes
      1 encode-int encode+
      h# 3c0 encode-int encode+
      h# 20 encode-int encode+
      0 encode-int encode+
      h# a.0000 encode-int encode+
      h# 2.0000 encode-int encode+
      1 encode-int encode+
      h# 3b0 encode-int encode+
      h# 10 encode-int encode+
      " reg" property

   " vga" device-name
   fload ${BP}/dev/video/common/defer.fth
   fload ${BP}/dev/video/controlr/vga.fth
   fload ${BP}/dev/video/common/graphics.fth
   fload ${BP}/dev/video/common/init.fth
   fload ${BP}/dev/video/common/textmode.fth

   : (map-io-regs) isa-io-base kseg1 + to io-base  ;
   ' (map-io-regs) to map-io-regs

   ' noop to unmap-io-regs

   true to safe?
   use-vga
   basic-vga

   : init
      init
      text-mode3
      h# 20 h# a crt!	\ Turn off hw cursor
   ;

   also forth definitions
   stand-init: VGA Text Output
      " /isa/vga" " init"  execute-device-method drop
   ;
   previous definitions
end-package

0 0 " " " /" begin-package
   fload ${BP}/dev/egatext.fth
end-package

0 0  " i3f8"  " /isa"  begin-package
   4 encode-int  3 encode-int encode+    " interrupts" property

   d# 1843200 encode-int " clock-frequency" property

   fload ${BP}/dev/16550pkg/ns16550p.fth
   fload ${BP}/dev/16550pkg/isa-int.fth
   " ns16550" +compatible
end-package

0 0 rom-pa <# u#s u#> " /" begin-package
   " flash" device-name

   /rom constant /device
   my-address my-space /device reg
   fload ${BP}/dev/flashpkg.fth
end-package

0 0 /resetjmp <# u#s u#> " /flash" begin-package
   " dropins" device-name

   /rom constant /device
   fload ${BP}/dev/subrange.fth
end-package

\ LICENSE_BEGIN
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
