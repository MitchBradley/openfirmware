purpose: Code words to support the file system interface
\ See license at end of file

decimal

\ &ptr is the address of a pointer.  fetch the pointed-to character and
\ post-increment the pointer.
code @c@++  ( &ptr -- char )
   mov     x0,tos     
   ldr     x1,[x0]    
   ldrb    wtos,[x1],#1
   str     x1,[x0]    
c;
 
\ &ptr is the address of a pointer.  store the character into
\ the pointed-to location and post-increment the pointer
code @c!++  ( char &ptr -- )
   pop     x0,sp
   ldr     x1,[tos]   
   strb    w0,[x1],#1
   str     x1,[tos]   
   pop     tos,sp
c;

[ifdef] notdef
\ "adr1 len2" is the longest initial substring of the string "adr1 len1"
\ that does not contain the character "char".  "adr2 len1-len2" is the
\ trailing substring of "adr1 len1" that is not included in "adr1 len2".
\ Accordingly, if there are no occurrences of that character in "adr1 len1",
\ "len2" equals "len1", so the return values are "adr1 len1  adr1+len1 0"

: split-string  ( adr1 len1 char -- adr1 len2  adr1+len2 len1-len2 )
   >r 2dup r> cindex if         ( adr1 len1 adr1+len2 )
      dup 3 pick -              ( adr1 len1 adr1+len2 len2 )
      rot over -                ( adr1 adr1+len2 len2 len1-len2 )
      >r swap r>
   else                         ( adr1 len1 )
      2dup + 0
   then
;

\ : xxsplit-string  ( adr1 len1 char -- adr1 len2  adr1+len2 len1-len2 )
\    over 0= if \ degenerate
\       drop 2dup exit
\    then
\    >r  2dup  over + swap      ( adr1 len1 adr1+len1 adr1 )
\    begin
\       2dup u> while           ( adr1 len1 adr1+len1 adr )
\       count r@ = if \ found it!       ( adr1 len1 adr1+len1 adr' )
\        1- nip 2 pick -        ( adr1 len1 len2 )
\        tuck - >r 2dup + r>    ( adr1 len2 adr1+len2 len1-len2 )
\        r> drop exit
\       then                    ( adr1 len1 adr1+len1 adr )
\    repeat                     ( adr1 len1 adr1+len1 adr )
\    2drop 2dup + 0
\ ;

   
\ Splits a buffer into two parts around the first line delimiter
\ sequence.  A line delimiter sequence is either CR, LF, CR followed by LF,
\ or LF followed by CR.
\ adr1 len2 is the initial substring before, but not including,
\ the first line delimiter sequence.
\ adr2 len3 is the trailing substring after, but not including,
\ the first line delimiter sequence.
decimal
: parse-line  ( adr1 len1 -- adr1 len2  adr2 len3 )
   2dup d# 10 cindex if  \ has lf               ( adr1 len1 adr-lf )
      >r 2dup d# 13 cindex if    \ has cr       ( adr1 len1 adr-cr )
         r> umin                                ( adr1 len1 adr-delim )
      else      \ lf only
         r>                                     ( adr1 len1 adr-delim )
      then                                      ( adr1 len1 adr-delim )
   else         \ no lf                         ( adr1 len1 )
      2dup d# 13 cindex if       \ has cr       ( adr1 len1 adr-cr )
      else      \ neither
         2dup + 0 exit
      then
   then                                         ( adr1 len1 adr-delim )
   dup 3 pick - -rot 1+ swap                    ( adr1 len2 adr2 len1 )
   2 pick - 1-
;
[else]
\ "adr1 len2" is the longest initial substring of the string "adr1 len1"
\ that does not contain the character "char".  "adr2 len1-len2" is the
\ trailing substring of "adr1 len1" that is not included in "adr1 len2".
\ Accordingly, if there are no occurrences of that character in "adr1 len1",
\ "len2" equals "len1", so the return values are "adr1 len1  adr1+len1 0"
code split-string       ( adr1 len1 char -- adr1 len2  adr1+len2 len1-len2 )
   ldp     x3,x4,[sp],#2cells  \ x3: len1   x4: adr1
   mov     x1,x4               \ x1: adr1
   add     x2,x3,x4            \ x2: lastchar of string 
   orn     x0,xzr,xzr          \ x0: -1
   begin
      cmp     x1,x2             
   < while
      ldrb    w0,[x1],#1   \ getchar - postincr
      cmp     w0,wtos      \ delimiter?
   0= until then
   cmp     w0,wtos         \ delimiter was found
   0 if  dec  x1,#1  then  \ last non-delimiter character adr
                           \ x1: adr1  x2: *lastchar+1
   sub     x2,x1,x4        \ x2: len2
   sub     tos,x3,x2       \ tos: len1-len2
   add     x1,x4,x2        \ x1: adr1+len2
   push    x4,sp
   push    x2,sp
   push    x1,sp
c;

\ Splits a buffer into two parts around the first line delimiter
\ sequence.  A line delimiter sequence is either CR, LF, CR followed by LF,
\ or LF followed by CR.
\ adr1 len2 is the initial substring before, but not including,
\ the first line delimiter sequence.
\ adr2 len3 is the trailing substring after, but not including,
\ the first line delimiter sequence.
code parse-line  ( adr1 len1 -- adr1 len2  adr2 len3 )
   ldr     x4,[sp],#1cell   \ x4 adr
   mov     x1,x4            \ x1 abs adr1
   add     x2,x1,tos        \ x2 abs lastchar
   orn     x0,xzr,xzr       \ x0: -1

   begin
      cmp     x1,x2
   < while
      ldrb    w0,[x1],#1
      cmp     w0,#10
      ne if  cmp  w0,#13  then
   0= until then
   sub     x3,x1,x4         \ x3 len2
   cmp     w0,#10
   ne if  cmp   w0,#13  then
   eq if  dec   x3,#1   then
   cmp     x1,x2            \ more chars in line?
   < if
      ldrb    wtos,[x1]
      cmp     wtos,#10
      ne if  cmp wtos,#13  then
      = if
         cmp     wtos,w0     \ not the same delimiter
         ne if  inc x1,#1  then
     then
   then
   sub     tos,x2,x1
   push    x4,sp
   push    x3,sp
   push    x1,sp
c;
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
