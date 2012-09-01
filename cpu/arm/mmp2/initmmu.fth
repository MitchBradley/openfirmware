\ See license at end of file
purpose: Setup the initial virtual address map

[ifdef] notdef
\ Synchronizes the instruction and data caches over the indicated
\ address range, thus allowing the execution of instructions that
\ have recently been written to memory.
label sync-cache-range  \ r0: adr, r1: len
   begin
      mcr  p15, 0, r0, cr7, cr10, 1    \ clean D$ line
      mcr  p15, 0, r0, cr7, cr5, 1     \ invalidate I$ line
      add  r0, r0, #32		       \ Advance to next line
      subs r1, r1, #32
   0<= until
   mov	pc, lr	
end-code

\ Forces data in the cache within the indicated address range
\ into memory.
label clean-dcache-range  \ r0: adr, r1: len
   begin
      mcr  p15, 0, r0, cr7, cr10, 1    \ clean D$ line
      add  r0, r0, #32		       \ Advance to next line
      subs r1, r1, #32
   0<= until
   mov	pc, lr	
end-code
[then]

\ Turn on the caches
label caches-on

   \ Invalidate the entire L1 data cache by looping over all sets and ways
   mov r0,#0                           \ Start with set/way 0 of L1 cache
   begin
      \ In this unrolled loop, the number of iterations (8) and the increment
      \ value (0x20000000) depend on fact that this cache has 8 ways.
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way - will wrap to 0

      inc  r0,#32                      \ Next set
      ands r1,r0,#0xfe0                \ Mask set bits - depends on #sets=128
   0= until

   \ Invalidate the entire L2 cache by looping over all sets and ways
   mov r0,#2                           \ Start with set/way 0 of L2 cache
   begin
      \ In this unrolled loop, the number of iterations (8) and the increment
      \ value (0x20000000) depend on fact that this cache has 8 ways.
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr6, 2     \ Invalidate D$ line by set/index
      inc  r0,#0x20000000              \ Next way - will wrap to 0

      inc  r0,#32                      \ Next set
      set  r2,`l2-#sets h# 20 - #`     \ Mask for set field for L2 cache
      ands r1,r0,r2                    \ Mask set bits
   0= until

   mcr  p15, 0, r0, cr7, cr5, 0        \ Invalidate entire I$

   mcr  p15, 0, r0, cr7, cr5, 6        \ Flush branch target cache

   mrc p15,0,r0,cr1,cr0,0              \ Read control register
   orr r0,r0,#0x1000                   \ ICache on
   orr r0,r0,#0x0800                   \ Branch prediction on
   orr r0,r0,#0x0004                   \ DCache on
   mcr p15,0,r0,cr1,cr0,0              \ Write control register with new bits

   mrc p15,0,r0,cr1,cr0,1              \ Read aux control register
   orr r0,r0,#0x0002                   \ L2 Cache on
   mcr p15,0,r0,cr1,cr0,1              \ Write control register with new bits

   mov	pc, lr	
end-code

\ Synchronizes the instruction and data caches, thus allowing the
\ execution of instructions that have recently been written to memory.
\ This version, which operates on the entire cache, is more efficient
\ than an address-range version when the range is larger than the
\ L1 cache size.
label sync-caches  \ No args or returns, kills r0 and r1

   \ Clean (push the data out to a higher level) the entire L1 data cache
   \ by looping over all sets and ways
   mov r0,#0                           \ Start with set/way 0 of L1 cache
   begin
      \ In this unrolled loop, the number of iterations (8) and the increment
      \ value (0x20000000) depend on fact that this cache has 8 ways.
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way
      mcr  p15, 0, r0, cr7, cr10, 2    \ clean D$ line by set/index
      inc  r0,#0x20000000              \ Next way - will wrap to 0

      inc  r0,#32                      \ Next set
      ands r1,r0,#0xfe0                \ Mask set bits - depends on #sets=128
   0= until

   mcr  p15, 0, r0, cr7, cr5, 0        \ Invalidate entire I$
   mov	pc, lr	
end-code
   
\ Insert zeros into the code stream until a cache line boundary is reached
\ This must be enclosed with "ahead .. then" to branch around the zeros.
: cache-align  ( -- )
   begin
      here [ also assembler ] asm-base [ previous ] -  h# 1f and
   while
      0 l,
   repeat
;   

\ Turn on the MMU
label enable-mmu  ( -- )
   mvn     r2, #0               \ Set domains for Manager access - all domains su
   mcr     p15,0,r2,3,0,0       \ Update register 3 in CP15 - domain access control

   \ Enable the MMU
   mrc     p15, 0, r2, 1, 0, 0  \ Read current settings in control reg
   mov     r2,  r2, LSL #18     \ Upper 18-bits must be written as zero,
   mov     r2,  r2, LSR #18     \ ... clear them now.

   orr     r2, r2, 0x200        \ Set the ROM Protection bit
   bic     r2, r2, 0x100        \ Clear the System Protection bit
   orr     r2, r2, 0x001        \ Set the MMU bit

   \ Align following code to a cache line boundary
   ahead
      cache-align
   then

   mcr    p15, 0, r2, cr1, cr0, 0       \ Go Virtual
   mrc    p15, 0, r2, cr2, cr0, 0       \ Ensure that the write completes
   mov    r2,  r2                       \ before continuing
   sub    pc,  pc,  #4

   mov    pc, lr
end-code

\ Map sections within the given address range, using
\ the given protection/cacheability mode.  pt-adr is the page table base address.
label map-sections  ( r0: pt-adr, r1: padr, r2: len, r3: mode r4: vadr -- )
    add  r1, r1, r3               \ PA+mode
    begin
       str  r1, [r0, r4, lsr #18]
       
       inc  r1, #0x100000
       inc  r4, #0x100000
       decs r2, #0x100000
    0<= until

    mov   pc, lr
end-code

\ Map sections virtual=physical within the given address range, using
\ the given protection/cacheability mode.  pt-adr is the page table base address.
label map-sections-v=p  ( r0: pt-adr, r1: adr, r2: len, r3: mode -- )
    begin
       add  r4, r1, r3            \ PA+mode
       str  r4, [r0, r1, lsr #18]
       
       inc  r1, #0x100000
       decs r2, #0x100000
    0<= until

    mov   pc, lr
end-code

\ Map sections within the given address range, using
\ the given protection/cacheability mode.  pt-adr is the page table base address.
label allocate-and-map-sections  ( r0: pt-adr, r1: padr-top, r2: len, r3: mode r4: vadr -- r1: padr-bot )
    inc  r4, r2                   \ vadr-top
    add  r1, r1, r3               \ PA+mode
    begin
       dec  r1, #0x100000
       dec  r4, #0x100000

       str  r1, [r0, r4, lsr #18]
       
       decs r2, #0x100000
    0<= until

    mov   r1,r1,lsr #20  \ Clear out mode bits in padr
    mov   r1,r1,lsl #20

    mov   pc, lr
end-code

\ This assumes that there are no holes and that unused MMAP registers have CS_VALID=0
label dramsize  ( -- r0: size-in-bytes )
   mov    r0,0
   mov    r1,0xd0000000    \ Memory controller base address

\  ldr    r2,[r1,#0x00]    \ MMAP0 register
\  and    r2,r2,#0xff      \ Revision
\  cmps   r2,#0xNN         \ MMP3?
\  >=     if

[ifdef] mmp3
   \ MMP3 memory controller - 2 banks, MMAP registers at 0x10 and 0x14

   \ Don't access a memory controller whose clock is in reset; it will hang
   set    r2, #0xd428286c  \ PMUA_BUS_CLK_RES_CTRL
   ldr    r2,[r2]          \ Register value
   tst    r2,#0x1          \ MC_RST bit
   0<> if

      ldr    r2,[r1,#0x10]    \ MMAP0 register
      ands   r3,r2,#1         \ Test CS_VALID
      movne  r3,#0x10000      \ Scale factor for memory size
      movne  r2,r2,lsl #11    \ Clear high bits above AREA_LENGTH field
      movne  r2,r2,lsr #27    \ Move AREA_LENGTH to LSB
      addne  r0,r0,r3,lsl r2  \ Compute bank size and add to accumulator

      ldr    r2,[r1,#0x14]    \ MMAP1 register
      ands   r3,r2,#1         \ Test CS_VALID
      movne  r3,#0x10000      \ Scale factor for memory size
      movne  r2,r2,lsl #11    \ Clear high bits above AREA_LENGTH field
      movne  r2,r2,lsr #27    \ Move AREA_LENGTH to LSB
      addne  r0,r0,r3,lsl r2  \ Compute bank size and add to accumulator
   then

   \ Don't access a memory controller whose clock is in reset; it will hang
   set    r2, #0xd428286c  \ PMUA_BUS_CLK_RES_CTRL
   ldr    r2,[r2]          \ Register value
   tst    r2,#0x2          \ MC2_RST bit
   0<> if
      add    r1,r1,#0x10000   \ Memory controller base address d0010000

      ldr    r2,[r1,#0x10]    \ MMAP0 register
      ands   r3,r2,#1         \ Test CS_VALID
      movne  r3,#0x10000      \ Scale factor for memory size
      movne  r2,r2,lsl #11    \ Clear high bits above AREA_LENGTH field
      movne  r2,r2,lsr #27    \ Move AREA_LENGTH to LSB
      addne  r0,r0,r3,lsl r2  \ Compute bank size and add to accumulator

      ldr    r2,[r1,#0x14]    \ MMAP1 register
      ands   r3,r2,#1         \ Test CS_VALID
      movne  r3,#0x10000      \ Scale factor for memory size
      movne  r2,r2,lsl #11    \ Clear high bits above AREA_LENGTH field
      movne  r2,r2,lsr #27    \ Move AREA_LENGTH to LSB
      addne  r0,r0,r3,lsl r2  \ Compute bank size and add to accumulator
   then
[else]
   \ MMP2 memory controller - 1 bank, MMAP registers at 0x100 and 0x110
   ldr    r2,[r1,#0x100]   \ MMAP0 register
   ands   r3,r2,#1         \ Test CS_VALID
   movne  r3,#0x10000      \ Scale factor for memory size
   movne  r2,r2,lsl #12    \ Clear high bits above AREA_LENGTH field
   movne  r2,r2,lsr #28    \ Move AREA_LENGTH to LSB
   addne  r0,r0,r3,lsl r2  \ Compute bank size and add to accumulator

   ldr    r2,[r1,#0x110]   \ MMAP1 register
   ands   r3,r2,#1         \ Test CS_VALID
   movne  r3,#0x10000      \ Scale factor for memory size
   movne  r2,r2,lsl #12    \ Clear high bits above AREA_LENGTH field
   movne  r2,r2,lsr #28    \ Move AREA_LENGTH to LSB
   addne  r0,r0,r3,lsl r2  \ Compute bank size and add to accumulator
[then]

   mov    pc,lr
end-code

\ Initial the section table, setting up mappings for the platform-specific
\ address ranges that the firmware uses.
\ Destroys: r0-r4
label init-map  ( -- )
   mov r10,lr

   bl  `dramsize`                       \ r0: total-memory-size
   mov r1,r0                            \ r1: allocation pointer starts at top of DRAM

   \ Locate the page table at the top of the firmware memory, just below the frame buffer
   dec r0,`/fb-mem #`                   \ Size of frame buffer
   dec r0,`/page-table #`               \ r0: page-table-pa

   mcr p15,0,r0,cr2,cr0,0               \ Set table base address

   \ Clear the entire section table for starters
   mov     r2, #0x1000			\ Section#
   mov     r3, #0			\ Invalid section entry
   begin
      subs    r2, r2, #1		\ Decrement section number
      str     r3, [r0, r2, lsl #2]	\ Invalidate section entry
   0= until
                                        \ r1: top of DRAM
   set r2,`/fb-mem #`                   \ Size of frame buffer
   set r3,#0xc06                        \ Write bufferable
   set r4,`fb-mem-va #`                 \ Virtual address
   bl  `allocate-and-map-sections       \ r1: bottom PA of frame buffer

   set r2,`/fw-mem #`                   \ Size of firmware region
   set r3,#0xc0e                        \ Write bufferable
   set r4,`fw-mem-va #`                 \ Virtual address
   bl  `allocate-and-map-sections`      \ r1: bottom PA of firmware memory

   set r2,`/extra-mem #`                \ Size of additional allocatable memory
   set r3,#0xc0e                        \ Write bufferable
   set r4,`extra-mem-va #'              \ Virtual address
   bl  `allocate-and-map-sections`      \ r1: bottom PA of extra memory

   set r2,`/dma-mem #`                  \ Size of DMA area
   set r3,#0xc02                        \ No caching or write buffering
   set r4,`dma-mem-va #`                \ Virtual address
   bl  `allocate-and-map-sections`      \ r1: bottom PA of DMA memory

   mov r2,r1                            \ Size of low memory
   set r3,#0xc0e                        \ Cache and write bufferable
   mov r4,#0                            \ Virtual address
   bl  `allocate-and-map-sections`      \ r1: 0

   \ Now we have mapped all of DRAM
   set r1,`sram-pa #`                   \ Address of SRAM
   set r2,`/sram #`                     \ Size of SRAM
   set r3,#0xc02                        \ No caching or write buffering
   bl  `map-sections-v=p`

   set r1,`io-pa #`                     \ Address of I/O
   set r2,`/io #`                       \ Size of I/O region
   set r3,#0xc02                        \ No caching or write buffering
   bl  `map-sections-v=p`

   set r1,`memctrl-pa #`                \ Address of memory controller
   set r2,`/io #`                       \ Size of I/O region
   set r3,#0xc02                        \ No caching or write buffering
   bl  `map-sections-v=p`

[ifdef] /audio-sram-map
   set r1,`audio-sram-pa #`             \ Address of Audio SRAM
   set r2,`/audio-sram-map #`           \ Map size of audio SRAM
   set r3,#0xc02                        \ No caching or write buffering
   bl  `map-sections-v=p`
[then]

   set r1,`io-pa #`                     \ Address of I/O
   set r2,`/io #`                       \ Size of I/O region
   set r3,#0xc02                        \ No caching or write buffering
   set r4,`io-va #`                     \ Virtual address
   bl  `map-sections`

   set r1,`io2-pa #`                    \ Address of I/O
   set r2,`/io2 #`                      \ Size of I/O region
   set r3,#0xc02                        \ No caching or write buffering
   set r4,`io2-va #`                    \ Virtual address
   bl  `map-sections`

[ifdef] mmp3-audio-pa
   set r1,`mmp3-audio-pa #`             \ Address of I/O
   set r2,`/mmp3-audio #`               \ Size of I/O region
   set r3,#0xc02                        \ No caching or write buffering
   set r4,`mmp3-audio-va #`             \ Virtual address
   bl  `map-sections`
[then]

   mov     pc, r10
end-code

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
