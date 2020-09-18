purpose: Unoptimized framebuffer support routines
\ See license at end of file

headerless
decimal

: fb8-invert ( adr width height pitch fg bg -- )
   5 roll 5 roll 5 roll			( pitch fg bg adr width height )

   \ Iterate lines
   0 do					( pitch fg bg adr width )
      over >r
      \ Iterate columns
      dup >r 0 do			( pitch fg bg adr )
         dup c@				( pitch fg bg adr c )
         dup 3 pick			( pitch fg bg adr c c bg )
         = if				( pitch fg bg adr c )
            \ bg matches, overwrite with fg
            drop 2 pick over c!
         else
            3 pick			( pitch fg bg adr c fg )
            = if
               \ fg matches, overwrite with bg
               2dup c!
            then			( pitch fg bg adr )
         then
         1+
      loop
      drop r> r>			( pitch fg bg width adr )
      4 pick +
      swap				( pitch fg bg adr width )
   loop
   5drop
;

: fb16-invert ( adr width height pitch fg bg -- )
   5 roll 5 roll 5 roll			( pitch fg bg adr width height )

   \ Iterate lines
   0 do					( pitch fg bg adr width )
      over >r
      \ Iterate columns
      dup >r 0 do			( pitch fg bg adr )
         dup w@				( pitch fg bg adr c )
         dup 3 pick			( pitch fg bg adr c c bg )
         = if				( pitch fg bg adr c )
            \ bg matches, overwrite with fg
            drop 2 pick over w!
         else
            3 pick			( pitch fg bg adr c fg )
            = if
               \ fg matches, overwrite with bg
               2dup w!
            then			( pitch fg bg adr )
         then
         2+
      loop
      drop r> r>			( pitch fg bg width adr )
      4 pick +
      swap				( pitch fg bg adr width )
   loop
   5drop
;

: fb32-invert ( adr width height pitch fg bg -- )
   5 roll 5 roll 5 roll			( pitch fg bg adr width height )

   \ Iterate lines
   0 do					( pitch fg bg adr width )
      over >r
      \ Iterate columns
      dup >r 0 do			( pitch fg bg adr )
         dup l@				( pitch fg bg adr c )
         dup 3 pick			( pitch fg bg adr c c bg )
         = if				( pitch fg bg adr c )
            \ bg matches, overwrite with fg
            drop 2 pick over l!
         else
            3 pick			( pitch fg bg adr c fg )
            = if
               \ fg matches, overwrite with bg
               2dup l!
            then			( pitch fg bg adr )
         then
         4 +
      loop
      drop r> r>			( pitch fg bg width adr )
      4 pick +
      swap				( pitch fg bg adr width )
   loop
   5drop
;

: fb8-paint ( fontadr fontbytes width height screenadr pitch fg bg -- )
   7 roll 7 roll 7 roll 7 roll		( screenadr pitch fg bg fontadr fontbytes width height )

   0 do \ Draw line
      2 pick be-l@			( screenadr pitch fg bg fontadr fontbytes width c )
      7 roll				( pitch fg bg fontadr fontbytes width c screenadr )
      dup >r
      2 pick 0 do \ Draw columns
         over h# 80000000 and  if  6  else  5  then  pick
         over c!			( pitch fg bg fontadr fontbytes width c screenadr )
         1+ swap
         1 << swap
      loop
      2drop
      5 roll				( fg bg fontadr fontbytes width pitch )
      dup r> +
      swap				( fg bg fontadr fontbytes width pitch screenadr+pitch )
      6 roll 6 roll 6 roll 6 roll	( width screenadr pitch fg bg fontadr fontbytes )
      tuck + swap			( width screenadr pitch fg bg fontadr+fontbytes fontbytes )
      6 roll				( screenadr pitch fg bg fontadr+fontbytes fontbytes width )
   loop

   5drop 2drop
;

: fb16-paint ( fontadr fontbytes width height screenadr pitch fg bg -- )
   7 roll 7 roll 7 roll 7 roll		( screenadr pitch fg bg fontadr fontbytes width height )

   \ Draw line
   0 do
      2 pick be-l@			( screenadr pitch fg bg fontadr fontbytes width c )
      7 roll				( pitch fg bg fontadr fontbytes width c screenadr )
      dup >r
      2 pick 0 do \ Draw columns
         over h# 80000000 and  if  6  else  5  then  pick
         over w!			( pitch fg bg fontadr fontbytes width c screenadr )
         2+ swap
         1 << swap
      loop
      2drop
      5 roll				( fg bg fontadr fontbytes width pitch )
      dup r> +
      swap				( fg bg fontadr fontbytes width pitch screenadr+pitch )
      6 roll 6 roll 6 roll 6 roll	( width screenadr pitch fg bg fontadr fontbytes )
      tuck + swap			( width screenadr pitch fg bg fontadr+fontbytes fontbytes )
      6 roll				( screenadr pitch fg bg fontadr+fontbytes fontbytes width )
   loop

   5drop 2drop
;

: fb32-paint ( fontadr fontbytes width height screenadr pitch fg bg -- )
   7 roll 7 roll 7 roll 7 roll		( screenadr pitch fg bg fontadr fontbytes width height )

   \ Draw line
   0 do
      2 pick be-l@			( screenadr pitch fg bg fontadr fontbytes width c )
      7 roll				( pitch fg bg fontadr fontbytes width c screenadr )
      dup >r
      2 pick 0 do \ Draw columns
         over h# 80000000 and  if  6  else  5  then  pick
         over l!			( pitch fg bg fontadr fontbytes width c screenadr )
         4 + swap
         1 << swap
      loop
      2drop
      5 roll				( fg bg fontadr fontbytes width pitch )
      dup r> +
      swap				( fg bg fontadr fontbytes width pitch screenadr+pitch )
      6 roll 6 roll 6 roll 6 roll	( width screenadr pitch fg bg fontadr fontbytes )
      tuck + swap			( width screenadr pitch fg bg fontadr+fontbytes fontbytes )
      6 roll				( screenadr pitch fg bg fontadr+fontbytes fontbytes width )
   loop

   5drop 2drop
;

: fb-window-move  ( src dst size pitch width -- )
   begin 2 pick 0> while
      4 roll 4 roll			( size pitch width src dst )
      2dup 4 pick move			( size pitch width src dst )
      3 pick + swap			( size pitch width dst+width src )
      3 pick + swap			( size pitch width dst+width src+width )
      4 roll 4 pick -			( pitch width dst+width src+width size-width )
      4 roll 4 roll			( dst+width src+width size-width pitch width )
   repeat
   5drop
;

headers
\ LICENSE_BEGIN
\ Copyright (c) 2020 Lubomir Rintel <lkundrak@v3.sk>
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
