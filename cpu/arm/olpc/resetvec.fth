\ See license at end of file
purpose: Low-level startup code

\ create debug-reset

\needs start-assembling  fload ${BP}/cpu/arm/asmtools.fth
\needs write-dropin      fload ${BP}/forth/lib/mkdropin.fth

hex

also forth definitions
: c$,  ( adr len -- )
   1+  here swap note-string dup allot move 4 (align)
;
previous definitions

also arm-assembler definitions
: $find-dropin,  ( adr len -- )
   2>r
   " mov     r0,pc"         evaluate	\ Get address of string
   " ahead"                 evaluate	\ Skip string
   2r> c$,				\ Place string
   " then"                  evaluate
   " bl      `find-dropin`" evaluate	\ and call find routine
;
previous definitions

\ /fw-mem  constant stack-offset                   \ Offset of top of inflater stack within destination RAM
stack-offset  h# 2.0000 -  constant workspace-offset  \ Offset of inflater workspace within destination RAM

start-assembling

label my-entry
\ **** This is the primary entry point; it will contain a branch instruction
\ that skips a few subroutines and lands at the startup sequence.  That
\ branch instruction is patched in below.
   0 ,				\ To be patched later
end-code

fload ${BP}/cpu/arm/olpc/numdot.fth

\ This subroutine is used by the startup code.
\ It compares two null-terminated strings, returning zero if they match.
\ Destroys: r2, r3
label strcmp  ( r0: str1 r1: str2 -- r0: 0 if match, nonzero if mismatch )
   begin
      ldrb    r2,[r0],#1
      ldrb    r3,[r1],#1
      cmp     r2,r3
      <> if
         sub     r0,r3,r2
         mov     pc,lr
      then

      cmp     r2,#0
   = until
   mov     r0,#0
   mov     pc,lr
end-code

\ This subroutine is used by the startup code.
\ It searches the ROM for a dropin module whose name field matches the
\ null-terminated string that is passed in r0.
\ Destroys: r1-6
label find-dropin    ( r0: module-name-ptr -- r0: address|-1 )
   mov     r6,lr		\ r6: return address
   mov     r5,r0		\ r5: module name

   \ Compute address of first dropin (the one containing this code)
\  sub     r4,pc,`here asm-base - h# 20 + 8 + #`	\ r4: module pointer
   set     r4,`'dropins #`

   begin
      ldr     r1,[r4]
      set     r2,#0x444d424f   \ 'OBMD' in little-endian
      cmp     r1,r2
   = while
      mov     r0,r5
      add     r1,r4,#16
      bl      `strcmp`
      cmp     r0,#0
      = if			\ It the strings match, we found the dropin
         mov    r0,r4
         mov    pc,r6
      then
      ldr     r0,[r4,#4]	\ Length of dropin image
      eor     r1,r0,r0, ror #16 \ Byte reverse r0
      bic     r1,r1,#0xff0000   \ using the tricky sequence
      mov     r0,r0,ror #8      \ shown in the ARM Programming Techniques
      eor     r0,r0,r1,lsr #8   \ manual

      add     r0,r0,r4		\ Added to base address of previous dropin
      add     r0,r0,#35		\ Plus length of header (32) + roundup (3)
      bic     r4,r0,#3		\ Aligned to 4-byte boundary = new dropin addr
   repeat

   mvn     r0,#0	\ No more dropins; return -1 to indicate failure
   mov     pc,r6
end-code

\ This subroutine is used by the startup code.
\ It copies n (r2) bytes of memory from src (r1) to dst (r0)
\ Destroys: r0-r3
label memcpy  ( r0: dst r1: src r2: n -- r0: dst )
   ahead begin
      ldr     r3,[r1],#4
      str     r3,[r0],#4
   but then
      subs    r2,r2,#4
   0< until

   mov     pc,lr
end-code

\ Load some additional subroutines that are used by the startup code
fload ${BP}/cpu/arm/mmp2/initmmu.fth	\ Setup the initial virtual address map

\ **** This is the main-line code for the initial startup sequence.
\ It is reached from a branch instruction (which will be patched in later)
\ at the beginning of this module.

label startup

\ Place a branch instruction to this location at the entry address
\ (i.e. the beginning) of this module
here my-entry  put-branch

[ifdef] notdef
   \ Locate and execute the dropin module named "start".
   \ That module's job is to initialize the core logic and memory controller
   \ at least to the point that memory works, and to size the memory.
   \ It returns in r0 the physical address just past the end of the last
   \ bank of memory.  Near the beginning of the last megabyte of memory,
   \ it stores bitmasks describing which memory banks are populated.

   " start" $find-dropin,   \ Assemble call to find-dropin with literal arg

   add     r0,r0,#32	\ Skip dropin header
   mov     lr,pc	\ Set return address
   mov     pc,r0	\ Execute the dropin
[then]

   mov     r0,#0x10
   bl      `puthex`

   \ Setup the page (section) table and turn on the MMU and caches
\    set     r0,`page-table-pa #`
   bl      `init-map`			\ Setup the initial virtual address map
   bl	   `enable-mmu`			\ Turn on the MMU
   bl	   `caches-on`			\ Turn on the caches

   mov     r0,#0x11
   bl      `puthex`

   \ Now we are running with the MMU and caches on, thus going faster

   \ Locate the dropin module named "firmware".

   " firmware" $find-dropin,  \ Assemble call to find-dropin with literal arg

   ldr     r1,[r0,#12]		\ Get the module's "expanded size" field,
   cmp     r1,#0		\ which will be non0 if the module's compressed
   <> if
      \ The firmware dropin is compressed, so we find the inflater
      \ and use it to inflate the firmware into RAM
      mov     r11,r0		\ Save address of firmware dropin

      mov     r0,#0x12
      bl      `puthex`

      \ Locate the "inflate" module.
      " inflate" $find-dropin,  \ Assemble call to find-dropin with literal arg

      add     r4,r0,#32		\ r1: Base address of inflater code
      
      mov     r0,#0x13
      bl      `puthex`

      \ Execute the inflater, giving it the address of the compressed firmware
      \ module, the address where the inflated firmware should be placed, and
      \ the address of some RAM the inflater can use for scratch variables.

      set     r0,`fw-virt-base workspace-offset + #`   \ Scratch RAM for inflater
      mov     r1,#0                                    \ No-header flag (false)
      set     r2,`fw-virt-base #`                      \ Firmware RAM address
      add     r3,r11,#32	\ Address of compressed bits of firmware dropin

      set     sp,`fw-virt-base stack-offset + #`       \ Stack for inflater

[ifdef] notdef
   \ Simple recipe for debug output to serial port
   set   r11, #0xd4018000
   begin
      ldr  r10,[r11,0x14]
      ands r10,r10,#0x20
   0<> until
   set   r10, #0x43  \ C
   str   r10, [r11]
[then]

      mov     lr,pc
      mov     pc,r4			\ Inflate the firmware

   else
      \ The firmware dropin isn't compressed, so we just copy it to RAM

      mov     r11,r0

      mov     r0,#0x14
      bl      `puthex`

      ldr     r2,[r11,#4]		\ Length of image

      eor     r1,r2,r2, ror #16 	\ Byte reverse r2 using the
      bic     r1,r1,#0xff0000   	\ tricky sequence shown in the
      mov     r2,r2,ror #8      	\ ARM Programming Techniques
      eor     r2,r2,r1,lsr #8   	\ manual

      add     r1,r0,#32			\ src: Skip dropin header

      set     r0,`fw-virt-base #`	\ dst: Firmware RAM address
      bl      `memcpy`			\ Copy the firmware
   then

   mov     r0,#0x15
   bl      `puthex`

   \ Synchronize the instruction and data caches so the firmware code can
   \ be executed.
   bl      `sync-caches`			\ Push Forth dictionary to memory

   mov     r0,#0x16
   bl      `puthex`

[ifdef] notdef
   " nanoforth" $find-dropin,   \ Assemble call to find-dropin with literal arg

   add     r0,r0,#32	\ Skip dropin header
   mov     lr,pc	\ Set return address
   mov     pc,r0	\ Execute the dropin
[then]

   \ Jump to the RAM firmware image
   set     r4, `fw-virt-base #`	\ RAM start address
   mov     pc, r4

   \ Notreached, in theory
   begin again
end-code

end-assembling

writing resetvec.img
asm-base  here over -  ofd @ fputs
ofd @ fclose

\ LICENSE_BEGIN
\ Copyright (c) 2011 FirmWorks
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
