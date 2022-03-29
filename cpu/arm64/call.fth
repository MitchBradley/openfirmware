purpose: Call the C subroutine whose address is on the stack
\ See license at end of file

\ General-purpose Register usage in C
\ X30           Link Register
\ X29           Frame Pointer
\ X19-X28       Callee-saved registers
\ X9-X18        Temporary registers
\ X8            Indirect result location 
\ X0-X7         Parameter/Result registers

\ Forth uses X23-X28 and should preserve them to be safe. But not yet...

code sp-call  ( [ arg7 .. arg0 ] adr sp -- [ arg7 .. arg0 ] result )
   pop    x8,sp                 \ Save the subroutine address
   \ SP now points to the first subroutine argument.
   mov    x9,sp                 \ Save pointer to arguments

   push2  lp,org,sp             \ Save Forth VM state on the stack
   push2  up,rp,sp
   push2  ip,sav,sp
	
   mov    x0,xsp
   push2  xzr,x0,sp

   movz   x29,#0                \ Set the frame pointer to null

   pop2   x0,x1,x9              \ Pass up to 8 arguments in registers
   pop2   x2,x3,x9
   pop2   x4,x5,x9
   pop2   x6,x7,x9

   mov    xsp,tos               \ Switch to the new stack
   blr    x8                    \ Call the subroutine

   pop2   xzr,x1,sp
   mov    xsp,x1

   pop2   ip,sav,sp             \ Restore Forth VM
   pop2   up,rp,sp
   pop2   lp,org,sp
   mov    tos,x0                \ Report C return value
c;

: call  ( [ arg19 .. arg0 ] adr -- [ arg19 .. arg0 ] result )  sp@ sp-call  ;

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
