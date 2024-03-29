purpose: Machine/implementation-dependent decompiler support
\ See license at end of file

headerless

only forth also hidden also  definitions
: dictionary-base  ( -- adr )  up@ user-size +  ;

\ True if adr is a reasonable value for the interpreter pointer
: reasonable-ip?  ( adr -- flag )
   dup  in-dictionary?  if  ( ip )
      #talign 1- and 0=  \ must be token-aligned
   else
      drop false
   then
;

\ XXX already in forth/lib/decomp.fth
\ \ Decompiler extension for 32-bit literals
\ : .llit      ( ip -- ip' )  ta1+ dup l@ 1- n.  la1+  ;  
\ : skip-llit  ( ip -- ip' )  ta1+ la1+  ;  
\ ' (llit)  ' .llit  ' skip-llit  install-decomp

\ Decompiler class extension for labels
label alabel   ret end-code
: .label   ( -- )   .definer >body disassemble  ; 
' alabel word-type ' label ' .label install-decomp-class

only forth also definitions
headers

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
