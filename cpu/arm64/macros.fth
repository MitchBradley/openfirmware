\ macro assembler support
\
\ just a start...
\ XXX $asm, only assembles one instrcution: fails to expand macros such as set


: $asm,   ( $ -- )      (asm$) abort" ERROR assembling string"  instruction,  ;

: (asm")   ( -- )    \ at runtime, assemble the string following the xt of (asm")
   skipstr
   push-decimal
   also assembler
   (entercode)   $asm,   (exitcode)
   previous
   pop-base
;

: asm"   ( -- )     \ text      compile (asm") followed by a string containing the text
   compile (asm") ,"      
; immediate

also hidden
' (asm")  ' .string  ' skip-string  install-decomp
previous


0 [if]
\ example
\ XXX fails for many values because ' asm" set ' generates only one instruction

: mfield   { offset size -- offset' }   \ name   
   code                \ define a new code word
      offset
      asm" set x0, #* "
      asm" add  tos, tos, x0 "
   c;                \ end new code word
   offset size +
;

\ OR

: mfield   { offset size -- offset' }   \ name   
   code                \ define a new code word
   offset 1000 <
   if
      offset
      asm" add  tos, tos, #* "
   else
      offset
      asm" set x0, #* "
      asm" add  tos, tos, x0 "
   then
   c;                \ end new code word
   offset size +
;

12345 23 mfield widget 

[then]
