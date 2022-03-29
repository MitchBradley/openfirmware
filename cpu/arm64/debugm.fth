purpose: Machine-dependent support routines for Forth debugger.
\ See license at end of file

hex

headerless
\ It doesn't matter what address this returns because it is only used
\ as an argument to slow-next and fast-next, which do nothing.
: low-dictionary-adr  ( -- adr )  origin  ( init-user-area + )  ;

nuser debug-next  \ Pointer to "next"
vocabulary bug   bug also definitions
nuser 'debug   \ code field for high level trace
nuser <ip      \ lower limit of ip
nuser ip>      \ upper limit of ip
nuser cntx     \ how many times thru debug next

\ Since we use a shared "next" routine, slow-next and fast-next are no-op's
alias slow-next 2drop  ( high low -- )
alias fast-next 2drop  ( high low -- )

label normal-next
       ldr     w0,[ip],#/token    \ Fetch next token and update IP
\+ itc add     lr,x0,org          \ token + origin = cfa
\+ itc ldr     w0,[lr],#/token    \ x0 = token of runtime word, lr = pfa
       add     x0,x0,org          \ token + origin = cfa
       br      x0                 \ cfa always contains executable code
end-code

label debnext
   ldr     x0,'user <ip
   cmp     ip,x0
   u>= if
      ldr     x0,'user ip>
      cmp     ip,x0
      u< if
         ldr     x0,'user cntx
         inc     x0,#1
         str     x0,'user cntx
         cmp     x0,#2
         = if
            movz    x0,#0
            str     x0,'user cntx
            ldr     w0,'body normal-next
            str     w0,[up]
            ic      ivau,up
            ldr     x0,'user 'debug
\+ itc      add     lr,x0,org          \ token + origin = cfa
\+ itc      ldr     w0,[lr],#/token    \ x0 = token of runtime word, lr = pfa
            add     x0,x0,org          \ token + origin = cfa
            br      x0
         then
      then
   then
   \ normal next
       ldr     w0,[ip],#/token    \ Fetch next token and update IP
\+ itc add     lr,x0,org          \ token + origin = cfa
\+ itc ldr     w0,[lr],#/token    \ x0 = token of runtime word, lr = pfa
       add     x0,x0,org          \ token + origin = cfa
       br      x0                 \ cfa always contains executable code
end-code

: test-debnext   ( -- )
   debnext 0x34 + l@ 0x18fffd20 <> abort" XXX debnext has incorrect instruction "
; \ test-debnext


\ Fix the next routine to use the debug version
: pnext   ( -- )
   [ also assembler ]
   debnext  up@  put-branch
   [ previous ]
;

\ Turn off debugging
: unbug   ( -- )  normal-next l@  up@ instruction!  ;

headers

forth definitions
\ unbug

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
