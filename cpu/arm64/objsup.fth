purpose: Machine dependent support routines used for the objects package.
\ See license at end of file

\ These words know intimate details about the Forth virtual machine
\ implementation.

\ Assembles the common code executed by actions.  That code
\ extracts the next token (which is the acf of the object) from the
\ code stream and leaves the corresponding apf on the stack.

headerless

: start-code  ( -- )  code-cf  !csp  ;

\ Assembles code to begin a ;code clause
: start-;code  ( -- )  start-code  ;

\ Code field for an object action.
: doaction  ( -- )  acf-align colon-cf  ;

[ifdef] itc
code >action-adr        ( object-acf action# -- ... )
( ... -- object-acf action# #actions true | object-apf action-adr false )
   ldr     x1,[sp]              \ x1: object-acf    top: action#

   ldr     w0,[x1]              \ w0: object-code-field
   add     x0,x0,org            \ x0: adr of object ;code cause
   sub     x0,x0,#1cell         \ x0: object-#actions-adr x1: obj-acf

   ldr     x2,[x0]              \ x2: #actions
   cmp     tos,x2               \ action# greater #actions
   > if
      stp     tos,x2,[sp,#-2cells]!     \ push action# and #actions
      movn    tos,#0            \ return true
      next
   then

   \ x0: object-#actions-adr  x1: object-acf  x2: #actions  tos: action#
   lsl     tos,tos,#2           \ tos /token *
   sub     x0,x0,tos            \ x0: adr of action cell
   ldr     w0,[x0]
   add     x0,x0,org            \ x0: action-adr

   \ x0: object-action-adr  x1: object-acf  tos: action#
   inc     x1,#4                \ x1: object-apf
   str     x1,[sp]              \ put object-apf on stack
   push    x0,sp                \ push action-adr
   movz    tos,#0               \ return false
c;

headers
: action-name   \ name  ( action# -- )
        create ,
   ;code
\   0xd503283f instruction,      \ sim-trace-on
   ldr     x0,[lr]              \ x0: action#

   ldr     w2,[ip],#4           \ x2: object token
   add     x2,x2,org            \ x2: object-acf
   psh     tos,sp               \ make room on stack
   add     tos,x2,#4            \ tos: object-apf

   ldr     w3,[x2]              \ r3: object-code-field
   add     x3,x3,org            \ x3: adr of object ;code cause

   inc     x0,#2                \ x0: index to action-cell
   sub     x3,x3,x0,lsl #2      \ x3: adr of action cell
   ldr     w2,[x3]              \ get token
   add     lr,x2,org            \ x2: object-acf
   ldr     w1,[lr],#4           \ get cfa token
   add     x1,x1,org            \ x1: code
   br      x1                   \ execute action
c;
[else]
code >action-adr        ( object-acf action# -- ... )
( ... -- object-acf action# #actions true | object-apf action-adr false )
   ldr     x1,[sp]              \ x1: object-acf    top: action#

   ldr     w0,[x1]              \ w0: object-code-field
   lsl     x0,x0,#38            \ remove opcode bits, and shift into sign bit
   asr     x0,x0,#36            \ Shift back, preserving sign bit
   add     x0,x1,x0             \ x0: adr of object ;code cause
   sub     x0,x0,#1cell         \ x0: object-#actions-adr x1: obj-acf

   ldr     x2,[x0]              \ x2: #actions
   cmp     tos,x2               \ action# greater #actions
   > if
      stp     tos,x2,[sp,#-2cells]!     \ push action# and #actions
      movn    tos,#0            \ return true
      next
   then

   \ x0: object-#actions-adr  x1: object-acf  x2: #actions  tos: action#
   lsl     tos,tos,#2           \ tos /token *
   sub     x0,x0,tos            \ x0: adr of action cell
   ldr     w0,[x0]
   add     x0,x0,org            \ x0: action-adr

   \ x0: object-action-adr  x1: object-acf  tos: action#
   inc     x1,#4                \ x1: object-apf
   str     x1,[sp]              \ put object-apf on stack
   push    x0,sp                \ push action-adr
   movz    tos,#0               \ return false
c;

headers
: action-name   \ name  ( action# -- )
        create ,
        ;code
   ldr     x0,[lr]              \ x0: action#

   ldr     w2,[ip],#4           \ x2: object token
   add     x2,x2,org            \ x2: object-acf
   psh     tos,sp               \ make room on stack
   add     tos,x2,#4            \ tos: object-apf

   ldr     w3,[x2]              \ r3: object-code-field
   lsl     x3,x3,#38            \ remove opcode bits, and shift into sign bit
   asr     x3,x3,#36            \ Shift back, preserving sign bit
   add     x3,x2,x3             \ x3: adr of object ;code cause

   inc     x0,#2                \ x0: index to action-cell
   sub     x3,x3,x0,lsl #2      \ x3: adr of action cell
   ldr     w2,[x3]              \ get token
   add     x2,x2,org            \ x2: object-acf
   br      x2                   \ execute action
c;
[then]

: >action#  ( apf -- action# )  @  ;
headers

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
