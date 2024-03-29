purpose: Configure metacompiler to build a 64, t32, dtc kernel
\ See license at end of file

only forth also definitions

warning @  warning off
: 16\ [compile] \ ; immediate
: 32\ [compile] \ ; immediate
: 64\ ; immediate
warning !

: \itc-t ( -- ) [compile] \  ; immediate
: \dtc-t ( -- )              ; immediate
: \ttc-t ( -- ) [compile] \  ; immediate

: \t8-t  ( -- ) [compile] \  ; immediate
: \t16-t ( -- ) [compile] \  ; immediate
: \t32-t ( -- )              ; immediate
: \t64-t ( -- ) [compile] \  ; immediate

: \tagvoc-t ( -- )                 ; immediate
: \nottagvoc-t ( -- ) [compile] \  ; immediate

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
