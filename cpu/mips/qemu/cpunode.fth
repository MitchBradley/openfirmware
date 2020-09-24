purpose: CPU node for QEMU MIPS PC
\ See license at end of file

hex

root-device

new-device
   " cpu-clock" device-name
   " fixed-clock" +compatible
   0 " #clock-cells" integer-property
   d# 16.000.000 " clock-frequency" integer-property
finish-device

new-device
   " cpus" device-name
   1 " #address-cells" integer-property
   0 " #size-cells" integer-property

   new-device
      " cpu" device-name
      " cpu" device-type
      0 " reg" integer-property
      " /cpu-clock" encode-phandle " clocks" property \ Linux needs this
   finish-device
finish-device

device-end

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
