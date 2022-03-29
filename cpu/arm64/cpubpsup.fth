purpose: Processor-dependent definitions for breakpoints on ARM64
\ See license at end of file

\ Machine-dependent definitions for breakpoints
\ h# d420.9a40 value breakpoint-opcode	\  BRK #1234  !! this gets intercepted by fastsim
h# 0123.4567 value breakpoint-opcode	\  a specific undefined instruction; 1 in 2^30 is fairly unique

headerless
\ processor independent code uses op@ twice, and op! twice
: op@  ( adr -- op )  l@  ;              \ all instructions are 32-bits
: op!  ( op adr -- )  instruction!  ;    \ store, and flush from caches
\ writes are special because they are modifying the instruction stream
\ by definition, this is self-modifying code.
\ a useful ally, very powerful, to be employed with restraint

\ simple validity test: instructions must be at 4-byte aligned addresses.
: bp-address-valid?  ( adr -- flag )  3 and  0=  ;

\ Is a copy of our breakpoint-opcode at address right now?
: at-breakpoint?  ( address -- flag )  op@ breakpoint-opcode =  ;
\ Put one there
: put-breakpoint  ( address -- )  breakpoint-opcode swap op!  ;

defer breakpoint-trap?
\ this version is valid only when bps are installed
: (breakpoint-trap?  ( -- flag )  %pc at-breakpoint?  ;
' (breakpoint-trap? is breakpoint-trap?     \ use it anyway

headers
\ show the instruction at %pc
: .instruction  ( -- )
   %pc   [ also disassembler ] dis-pc! dis1 [ previous ]
;

headerless
\ Find the places to set the next breakpoint for single stepping.

: bl?   ( pc -- flag )  l@  h# fc00.0000 and  h# 9400.0000 =  ;   \ branch and link (immediate)
: b?    ( pc -- flag )  l@  h# fc00.0000 and  h# 1400.0000 =  ;   \ Unconditional branch (immediate)
: bcc?  ( pc -- flag )  l@  h# fe00.0000 and  h# 5400.0000 =  ;   \ Conditional branch (immediate)
: br?   ( pc -- flag )  l@  h# fe00.0000 and  h# d600.0000 =  ;   \ Unconditional branch (register)
: >bcc  ( adr -- target )  dup l@  d# 40 <<  d# 43 >>a  3 andc  +  ;  \ imm19
: >br   ( adr -- target )  l@  5 >> h# 1f and  ( reg ) 3 <<  >state @  ;
: cb?   ( pc -- flag )  l@  h# 7e00.0000 and  h# 3400.0000 =  ;   \ conditional branch (register Z/NZ)
: tb?   ( pc -- flag )  l@  h# 7e00.0000 and  h# 3600.0000 =  ;   \ test bit and branch
: >btb  ( adr -- target )  dup l@  d# 45 <<  d# 48 >>a  3 andc  +  ;  \ imm14

\ breakpoints will be put at one or both of the returned addresses, later
: next-instruction  ( stepping? -- next-adr branch-target|0 )
   %pc la1+        \ always return the next address
   \ there are two single step words
   \ step traces the code in subroutines, and
   \ hop skips tracing them
   %pc bl?                \ is this a branch & link?
   if      swap      ( next-adr stepping? )
      if  >b-target       \ let's also put a bp at the start of the subroutine
      else
	 0                \ skip this subroutine
      then
      exit
   then              ( stepping? next-adr )
   nip               ( next-adr )
   %pc b?                \ is this an unconditional branch (immediate)?
   if
      >b-target          \ always put a bp at the target of the branch
      exit
   then              ( next-adr )
   %pc br?               \ is this an unconditional branch (register)?
   if
      %pc >br        ( next-adr branch-target )
      exit
   then
   %pc bcc?              \ is this a conditional branch (immediate)?
   if
      %pc >bcc           \ put a bp at the target of the branch
      exit
   then              ( next-adr )
   %pc cb?              \ is this a conditional branch register Z/NZ (immediate)?
   if
      %pc >bcc          \ put a bp at the target of the branch
      exit
   then              ( next-adr )
   %pc tb?              \ is this a test bit and branch (immediate)?
   if
      %pc >btb          \ put a bp at the target of the branch
      exit
   then              ( next-adr )
   0                     \ no branches here 
;

\ point %pc at following instruction
: bumppc  ( -- )  %pc la1+ to %pc   ;

: return-adr  ( -- adr )  %lr l@  ;

\ break at this address to skip to the end of this routine
: leaf-return-adr  ( -- adr )  %lr  ;

\ True if adr points to a backward branch
: backward-branch?  ( adr -- flag )
   dup b?            \ is this an unconditional branch?
   if  dup >b-target  u>   ( goingback? )
      exit
   then                    ( adr )
   dup br?           \ is this an unconditional branch (register)?
   if
      dup  >br  u>
      exit
   then
   dup bcc?          \ is this a conditional branch (immediate)?
   if
      dup >bcc  u> 
      exit
   then              ( next-adr )
   drop false        \ no
;
\ scan forward from %pc to find next backward branch
: loop-exit-adr  ( -- adr )
   %pc  begin  dup backward-branch? 0=  while  la1+  repeat  la1+
;

headers
: set-pc  ( adr -- )  to %pc  ;

alias rpc %pc      \ the cpu-independent code uses this name


\ LICENSE_BEGIN
\ Copyright (c) 1994 FirmWorks
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
