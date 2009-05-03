\ See license at end of file
purpose: Defines Open Firmware virtual address space

\ Low RAM
h#     580 constant gdt-pa   \ Above the BDA, below the MBR area at 600
h#      80 constant gdt-size

h#    1000 constant mem-info-pa
h#  9.fc00 constant 'ebda    \ Extended BIOS Data Area, which we co-opt for our real-mode workspace

[ifdef] virtual-mode
h#    2000 constant pdir-pa
h#    3000 constant pt-pa
h# ff80.0000 value fw-virt-base
h# 0040.0000 value fw-virt-size
[else]
fw-pa value fw-virt-base
0 value fw-virt-size
[then]
\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
