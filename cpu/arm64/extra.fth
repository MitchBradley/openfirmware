purpose: Additional kernel code words
\ See license at end of file

hex


\ code perform  ( adr -- )
\      ldr x0,[tos]
\      pop tos,sp
\      br  x0
\ end-code 

#threads-t 1 = [if]
code hash  ( str-adr voc-ptr -- thread )
   pop     x0,sp              \ Drop the string, not hashed in this case
   ldr     tos,[tos,#1cell]   \ Get user#
   add     tos,tos,up         \ Get thread base address
c;
[else]
code hash  ( str-adr voc-ptr -- thread )
   pop     x0,sp              \ string
   ldrb    w0,[x0,#1] 
   #threads-t 1- 0
   and     x0,x0,#*
   ldr     tos,[tos,#1cell]   \ get user#
   add     tos,tos,up         \ Get thread base address
   add     tos,tos,x0,lsl #3
c;
[then]


\ Starting at "link", which is the address of a memory location
\ containing a link to the acf of a word in the dictionary, find the
\ word whose name matches the string "adr len", returning the link
\ field address of that word if found.

\ Assumes the following header structure - [N] is size in bytes:
\ pad[0-7]  name-characters[n]  name-len&flags[1]  link[4]  code-field[4]
\                               ^                  ^        ^
\                               anf                alf      acf
\ The link field points to the *code field* of the next word in the list.
\ Padding is added, if necessary, before the name characters so that
\ acf is aligned on the 4-byte boundary before an 8-byte boundary.
\ (See ACF-ALIGN.)

code code-$find-next  ( adr len link -- adr len alf true | adr len false )
   begin
      \ link@ == origin?
      ldr   wtos, [tos]
      add   tos, tos, org
      cmp   tos, org
   <> while
      sub   tos, tos, #/link  \ tos is new alf
      sub   x0, tos, #1       \ alf -> name$ in x0,x1
      ldrb  w1, [x0]
      and   w1, w1, #0x1f
      sub   x0, x0, x1
      ldp   x3, x2, [sp]      \ target$ in x2,x3
      \ At this point it's effectively  name$ target$ comp
      cmp   x1, x3
      = if
         \ Same length, so check bytes
         begin
            ldrb  w4, [x0], #1
            ldrb  w5, [x2], #1
            cmp   x4, x5
         = while
            decs  x1, #1
            0= if
               \ Exhausted: we have a match. Exit with success.
               push  tos, sp
               orn   tos, xzr, xzr
               next
            then
         repeat
      then
   repeat
   movz  tos, #0
c;

code s->l  ( n -- l )  c;
code l->n  ( l -- n )  sbfm  tos,tos,#0,#31  c;
code n->a  ( n -- a )  c;
code l->w  ( l -- w )  and tos,tos,#0xFFFF  c;
code n->w  ( n -- w )  and tos,tos,#0xFFFF  c;

code l>r  ( l -- )  push tos,rp  pop tos,sp  c;
code lr>  ( -- l )  push tos,sp  pop tos,rp  c;

#align-t     constant #align
#acf-align-t constant #acf-align
#talign-t    constant #talign

: align  ( -- )  #align (align)  ;
: taligned  ( adr -- adr' )  #talign round-up  ;
: talign  ( -- )  #talign (align)  ;
: asm-align  ( opcode n -- )
   1- begin dup here and while over instruction, repeat 2drop
;

: wconstant  ( "name" w -- )  header constant-cf ,  ;


\ These work with arm64sim, or fastsim under the wrapper,
\ or fastsim using our analyser.
code sim-trace-off    ( -- )   hint   0x42  c;
code sim-trace-on     ( -- )   hint   0x41  c;
code sim-ftrace-off   ( -- )   rbit   xzr,x2  c;
code sim-ftrace-on    ( -- )   rbit   xzr,x3  c;
code sim-instruction-count   ( -- n )
   set   x0,#0         \ On real hardware, x0 will be 0 when done
   rbit  xzr,x12       \ Get the processor instruction count
   push  tos,sp
   mov   tos,x0
c;

code 0exit   ( flag -- )
   cmp  tos,#0
   pop  tos,sp
   eq if
      ldr  ip,[rp],#1cell
   then
c;

code sign-extend32   ( l -- n )
   sbfx x0, tos, #31, #1
   bfi tos, x0, #32, #32
c;

code sign-extend16   ( w -- n )
   sbfx x0, tos, #15, #1
   bfi tos, x0, #16, #48
c;

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
