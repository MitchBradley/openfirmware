\
\ return-asm
\ reenter-forth
\
\ Here are two assembly language sequences for getting back into Forth
\ and returning from Forth.
\
\ The basic idea is some assembly language code will preserve whaterver
\ state it wants to preserve, say, on the data stack.  It will then
\ push whatever parameters it wants to pass to a Forth word onto the
\ data stack, leaving the top element in TOS.
\
\ Then, the assembly langauge code puts the token for the word it wants to
\ call into w0.  It then calls reenter-forth.

\ reenter-forth will use a trampoline to get to Forth.  In reenter-tramp
\ there is a token which will be overwritten and immediately used by the
\ inner interpreter to get to Forth.  After that is the token of a word
\ which returns to assembly language.

code return-asm
   pop    x0,rp   \ Pop the tramp word from the stack
   pop    lr,rp
   pop    ip,rp
   br     lr
end-code


code _reenter-forth_
   psh    ip,rp
   psh    lr,rp

   \ Build the re-enter tramp on the return stack (!)
   \ This way we have our very own copy and don't have to
   \ to worry about anybody else modifying it behind our
   \ back.
   'body return-asm  origin- lwsplit swap
   movz   x1,#*
?dup  [IF]
   movk   x1,#*,lsl #16
[THEN]
   psh    w1,rp
   psh    w0,rp

   \ Set the IP to the dummy word we just built on the stack
   mov    ip,rp
   br     up
end-code


\  Adding an assembler word for calling Forth code from assembler.
\
\  Now you can call Forth code from the ARM64 assembler using the syntax
\     call-forth word
\
\  The word will be looked up and, if found it will be called.
\  If the word is not found, the user can continue to enter assembler
\  into the currently defined word.

also arm64-assembler definitions

: call-forth ( "forth-word" -- )
   safe-parse-word  $find  *if
      origin-  " set x0,#*  bl 'code _reenter-forth_" eval
   *else  ." ERROR: call-forth can't call " type ."  - word not found" cr abort
   *then
;

previous definitions
