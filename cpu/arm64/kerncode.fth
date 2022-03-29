purpose: Kernel Primitives for ARM64 Processors
\ See license at end of file

\ Allocate and clear the initial user area image
mlabel init-user-area   setup-user-area

\ We create the shared code for the "next" routine so that:
\ a) It will be in RAM for speed (ROM is often slow)
\ b) We can use the user pointer as its base address, for quick jumping

also forth
compilation-base  here-t                        \ Save meta dictionary pointer
\ Use the first version if the user area is separate from the dictionary
\ 0 dp-t !  userarea-t is compilation-base      \ Point it to user area
userarea-t dp-t !                               \ Point it to user area
previous

code-field: (next)   \ Shared code for next; will be copied into user area
[ifdef] trace-next
       mov     x1,up
       ldr	   x0,[x1,#-8]!
       cmp	   x0,up
       b.ne	   $20  \ L# do-next

       psh     lr,sp
       ldr	   x0,[x1,#-8]!
       blr	   x0
       pop     lr,sp
[then]
[ifdef] count-nexts
       ldr     x0,[org,#0x80]
       inc     x0,#1
       str     x0,[org,#0x80]
[then]
[ifdef] check-stack-ordering
       \ Test for checking the relative ordering of rp, sp and the xsp
       mov     x0, rp
       mov     x1, sp
       mov     x2, xsp
       cmp     x0, x1
       0< if
          begin again
       then
       cmp     x1, x2
       0< if
          begin again
       then
       cmp     x0, x2
       0< if
          begin again
       then
[then]  \ check-stack-ordering

       ldr     w0,[ip],#/token    \ Fetch next token and update IP
\+ itc add     lr,x0,org          \ token + origin = cfa
\+ itc ldr     w0,[lr],#/token    \ x0 = token of runtime word, lr = pfa
       add     x0,x0,org          \ token + origin = cfa
       br      x0                 \ executable code
end-code


also forth
dp-t !  is compilation-base  previous    \ Restore meta dict. pointer

d# 64 equ #user-init      \ Leaves space for the shared "next"

hex meta assembler definitions
\ New: the following 3 definitions aren't in this file

:-h next  " br up" evaluate  ;-h
:-h c;     next  end-code ;-h
caps on

\ Run-time actions for defining words:

\ In the ARM64 implementation all words but code definitions are
\ called by a branch+link instruction. It branches to a relative-inline-
\ address and leaves the pfa in the link register, X30.
\ The pfa of the word is just after the branch+link instruction.
\ NOTE: Cell size and token size need not be the same (e.g., a 64 bit
\ cell size and a 32 bit token size).  And therefore, colon definitions
\ don't necessary need to align the pointer to the token stream before
\ using them.  However, variables and other data stores must be cell size
\ aligned.  This is true for two reasons:  1) locks require exclusive
\ operations and those instructions cannot work on unaligned data;
\ 2) support for unaligned accesses may be disabled when Forth is
\ running and would therefore cause exceptions.

meta definitions
code-field: douser
       push    tos,sp
       ldr     w0,[lr]
       add     tos,x0,up
c;
code-field: dodoes
       push    tos,sp
       mov     tos,x0       \ x0 has pfa of child
       push    ip,rp
       mov     ip,lr        \ ip has pfa of parent
c;
code-field: dovalue
       push    tos,sp
       ldr     w0,[lr]
       ldr     tos,[up,x0]
c;
code-field: docolon
       push    ip,rp
       mov     ip,lr
c;
code-field: doconstant
       push    tos,sp
       ldr     tos,[lr]
c;
code-field: dodefer
       ldr     w0,[lr]          \ Get user#
       ldr     w0,[x0,up]       \ Fetch target token
\+ itc add     lr,x0,org        \ CFA of target
\+ itc ldr     w0,[lr],#/token  \ Fetch do-word token; LR = PFA
       add     x0,x0,org
       br      x0
end-code
code-field: do2constant
       ldp     x1,x2,[lr]
       push2   x1,tos,sp
       mov     tos, x2
c;
code-field: dolabel            \ tag for subroutines
       push    tos,sp
       mov     tos,lr
c;
code-field: docreate
       push    tos,sp
       mov     tos,lr
c;
code-field: dovariable
       push    tos,sp
       mov     tos,lr
c;

\ New: dopointer  (identical to doconstant)
\ New: dobuffer  (identical to doconstant)

:-h push-pfa       ( -- ) also assembler " mov x0,lr" evaluate previous ;-h

[ifdef] itc

:-h compvoc     compile-t <vocabulary> ;-h
\ for itc move lr to x0 for use by dodoes
code-field: dovocabulary
   mov     x0,lr
   ldr     w1,$+12      \ Snag compvoc after the end of this word
   add     x1,x1,org        \ CFA of target
   br      x1
end-code
compvoc  \ later we search for a word named <vocabulary> and compile its token here
\ compvoc points to
\   mov   x0,lr
\   bl    dodoes
\ which will call dodoes with lr: pfa of compvoc, and x0: pfa of wordlist

\ Meta compiler words to compile code fields for child words
:-h place-cf-t      \ ( adr -- ) really token!
   origin - l,-t
;-h

\ XXX This will need to change when code words are placed in a code segment.
:-h code-cf        ( -- )  here-t /token 2* +  place-cf-t
                           also assembler " add xsp,xsp,#0" evaluate previous  ;-h
:-h start;code     ( -- )                              ;-h  \ ???
:-h colon-cf       ( -- )  docolon          place-cf-t ;-h
:-h constant-cf    ( -- )  doconstant       place-cf-t ;-h
:-h label-cf       ( -- )  dolabel          place-cf-t ;-h
:-h create-cf      ( -- )  docreate         place-cf-t ;-h
:-h variable-cf    ( -- )  dovariable       place-cf-t ;-h
:-h user-cf        ( -- )  douser           place-cf-t ;-h
:-h value-cf       ( -- )  dovalue          place-cf-t ;-h
:-h defer-cf       ( -- )  dodefer          place-cf-t ;-h
:-h 2constant-cf   ( -- )  do2constant      place-cf-t ;-h
:-h vocabulary-cf  ( -- )  dovocabulary     place-cf-t ;-h

:-h place-does-t      \ ( adr -- ) compile a branch+link to adr
   here-t -  2/ 2/  h# 03ff.ffff and  h# 9400.0000 or  l,-t
;-h
:-h startdoes      ( -- )  push-pfa  dodoes place-does-t ;-h

[else] \ not itc

:-h compvoc     compile-t <vocabulary> ;-h
code-field: dovocabulary
       ldr     w0,$+12      \ Snag compvoc after the end of this word
       add     x0,x0,org
       br      x0
end-code
compvoc  \ later we search for a word named <vocabulary> and compile its token here

\ Meta compiler words to compile code fields for child words
:-h place-cf-t      \ ( adr -- ) compile a branch+link to adr
   here-t -  2/ 2/  h# 03ff.ffff and  h# 9400.0000 or  l,-t
;-h

:-h code-cf        ( -- )  also assembler " add xsp,xsp,#0" evaluate previous  ;-h
:-h startdoes      ( -- )  push-pfa
                           dodoes       place-cf-t ;-h
:-h start;code     ( -- )                          ;-h  \ ???
:-h colon-cf       ( -- )  docolon      place-cf-t ;-h
:-h constant-cf    ( -- )  doconstant   place-cf-t ;-h
\ New: :-h buffer-cf   ( -- )  dobuffer   place-cf-t ;-h
\ New: :-h pointer-cf  ( -- )  dopointer  place-cf-t ;-h
:-h label-cf       ( -- )  dolabel      place-cf-t ;-h
:-h create-cf      ( -- )  docreate     place-cf-t ;-h
:-h variable-cf    ( -- )  dovariable   place-cf-t ;-h
:-h user-cf        ( -- )  douser       place-cf-t ;-h
:-h value-cf       ( -- )  dovalue      place-cf-t ;-h
:-h defer-cf       ( -- )  dodefer      place-cf-t ;-h
:-h 2constant-cf   ( -- )  do2constant  place-cf-t ;-h
:-h vocabulary-cf  ( -- )  dovocabulary place-cf-t ;-h

[then] \ itc

\ Start adding named words to the target dictionary.

\ =======================================
\
\          IS___ Assignment Words
\  'is' will compile one of these run-time words
\  XXX the metacompiler verson of 'is' compiles the wrong thing.
\      It reolves at run time, too slow!
\
\ =======================================

code isdefer  ( xt -- )
   ldr w0,[ip],#/token \ Get token of target word
   add x0,x0,org
   ldr w0,[x0,#/token] \ Get user number
   sub x1,tos,org      \ make it a token
   str w1,[x0,up]      \ Store 32-bit value
   pop tos,sp          \ Fix stack
c;
code isvalue  ( n -- )
   ldr w0,[ip],#/token \ Get token of target word
   add x0,x0,org
   ldr w0,[x0,#/token] \ Get user number
   str tos,[x0,up]     \ Store value
   pop tos,sp          \ Fix stack
c;
code isuser  ( n -- )
   ldr w0,[ip],#/token \ Get token of target word
   add x0,x0,org
   ldr w0,[x0,#/token] \ Get user number
   str tos,[x0,up]     \ Store value
   pop tos,sp          \ Fix stack
c;
code isconstant  ( n -- )
   ldr w0,[ip],#/token \ Get token of target word
   add x0,x0,org
   inc x0,#4           \ Advance to pfa
   str tos,[x0]        \ Store value
   pop tos,sp          \ Fix stack
c;
code isvariable  ( n -- )
   ldr w0,[ip],#/token \ Get token of target word
   add x0,x0,org
   inc x0,#4           \ Advance to pfa
   str tos,[x0]        \ Store value
   pop tos,sp          \ Fix stack
c;

\ =======================================
\
\          IMMEDIATE VALUES
\
\ =======================================

\ 32-bit literal
\ value was incremented when stored;
\ decrement to provide a range of small positive integers, 0, and -1
code  (llit)  ( -- lit )
   psh     tos,sp
   ldr     wtos,[ip],#4
   dec     tos,#1
c;

\ a cell-sized literal in a stream of tokens may not be aligned
\ so fetch it as two longs
code (lit)  ( -- lit )
   push    tos,sp
   ldr     w0,[ip],#4
   ldr     w1,[ip],#4
   orr     tos,x0,x1,lsl #32
c;
\ and a double takes four longs
code (dlit)  ( -- d )
   push    tos,sp

   ldr     w0,[ip],#4
   ldr     w1,[ip],#4
   orr     tos,x0,x1,lsl #32
   push    tos,sp

   ldr     w0,[ip],#4
   ldr     w1,[ip],#4
   orr     tos,x0,x1,lsl #32
c;
\ push a pair of 32-bit in-line values
code (1x0)   ( -- mask value )
   push    tos,sp
   ldr     w0,[ip],#4
   push    x0,sp
   ldr     wtos,[ip],#4
c;

\ =======================================
\
\          EXECUTE
\
\ =======================================

\ branch to a code field
code execute   ( cfa -- )
\- itc mov     x0,tos
\+ itc mov     lr,tos
       pop     tos,sp
\+ itc ldr     w0,[lr],#/token
\+ itc add     x0,x0,org
       br      x0
end-code
\ execute unless 0
code ?execute  ( cfa|0 -- )
\- itc ands    x0,tos,tos                \ tos: len
\+ itc ands    lr,tos,tos
       pop     tos,sp
       0<> if
\+ itc    ldr  w0,[lr],#/token
\+ itc    add  x0,x0,org
          br   x0
       then
c;
\ fetch-execute
code @execute  ( adr -- )
\- itc ldr     x0,[tos]
\+ itc ldr     lr,[tos]
       pop     tos,sp
\+ itc ldr     w0,[lr],#/token
\+ itc add     x0,x0,org
       br      x0
end-code

\ execute-ip  This word will call a block of Forth words given the address
\ of the first word.  It's used, for example, in try blocks where the
\ a word calls 'try' and then the words that follow it are called repeatedly.
\ This word, execute-ip, is used to transfer control back to the caller of
\ try and execute the words that follow the call to try.

\ see forth/lib/try.fth for more details.

code execute-ip  ( word-list-ip -- )
   push     ip,rp     \ nest
   mov      ip,tos    \ interpret list of tokens, until unnest or throw
   pop      tos,sp
c;

\ =======================================
\
\          BRANCHES
\
\ =======================================

\ Run-time actions for structured-conditionals

\ always branch:  else
code branch  ( -- )
   ldrsw    x0,[ip]
   add      ip,ip,x0
c;

\ branch if false:  if
code ?branch  ( flag -- )
   cmp      tos,#0
   pop      tos,sp
   0<> if
      inc   ip,#/token
   else
      ldrsw x0,[ip]
      add   ip,ip,x0
   then
c;

\ branch if true:  0= if
code ?0=branch  ( flag -- )
   cmp      tos,#0
   pop      tos,sp
   0= if
      inc   ip,#/token
   else
      ldrsw x0,[ip]
      add   ip,ip,x0
   then
c;

\ =======================================
\
\          DO LOOP etc.
\
\ =======================================

code (next)  ( -- )
   ldr        x0,[rp]
   subs       x0,x0,#1
   0>= if
       str    x0,[rp]
       ldrsw  x0,[ip]
       add    ip,ip,x0
       ldr    w0,[ip],#/token
\+ itc add    lr,x0,org
\+ itc ldr    w0,[lr],#/token
       add    x0,x0,org
       br     x0
   then
   inc        rp,#3cells
   inc        ip,#/token
c;

code (for)  ( n -- )
   push    ip,rp          \ save the do offset address
   inc     ip,#/token
   push2   tos,xzr,rp
   pop     tos,sp
c;

code (loop)  ( -- )
   ldr        x0,[rp]
   incs       x0,#1
   vc if
       str    x0,[rp]
       ldrsw  x0,[ip]
       add    ip,ip,x0
       ldr    w0,[ip],#/token
\+ itc add    lr,x0,org
\+ itc ldr    w0,[lr],#/token
       add    x0,x0,org
       br     x0
   then
   inc        rp,#3cells
   inc        ip,#/token
c;

code (+loop)  ( n -- )
   ldr        x0,[rp]
   adds       x0,x0,tos
   vc if
      str     x0,[rp]
   then
   pop        tos,sp
   vc if
       ldrsw  x0,[ip]
       add    ip,ip,x0
       ldr    w0,[ip],#/token
\+ itc add    lr,x0,org
\+ itc ldr    w0,[lr],#/token
       add    x0,x0,org
       br     x0
   then
   inc        rp,#3cells
   inc        ip,#/token
c;

code (do)  ( l i -- )
   mov     x0,tos
   pop2    x1,tos,sp
   push    ip,rp          \ save the do offset address
   inc     ip,#/token
   eor     x1,x1,#0x8000.0000.0000.0000   \ bit63 ^ l
   sub     x0,x0,x1                       \ bit63 ^ (i-l)
   push2   x0,x1,rp
c;

code (?do)  ( l i -- )
   mov       x0,tos
   pop2      x1,tos,sp
   cmp       x1,x0
   = if
       ldrsw x0,[ip]
       add   ip,ip,x0
       ldr   w0,[ip],#/token
\+ itc add   lr,x0,org
\+ itc ldr   w0,[lr],#/token
       add   x0,x0,org
       br    x0
                ( r: loop-end-offset l+0x8000 i-l-0x8000 )
   then
   push      ip,rp          \ save the do offset address
   inc       ip,#/token
   eor       x1,x1,#0x8000.0000.0000.0000
   sub       x0,x0,x1
   push2     x0,x1,rp
c;

code i  ( -- n )
   push     tos,sp
   ldp      x0,x1,[rp]
   add      tos,x1,x0
c;
code ilimit  ( -- n )
   push     tos,sp
   ldr      tos,[rp,#1cell]
   eor      tos,tos,#0x8000.0000.0000.0000
c;
code j  ( -- n )
   push     tos,sp
   add      x2,rp,#3cells
   ldp      x0,x1,[x2]
   add      tos,x1,x0
c;
code jlimit  ( -- n )
   push     tos,sp
   ldr      tos,[rp,#4cells]
   eor      tos,tos,#0x8000.0000.0000.0000
c;
code k  ( -- n )
   push     tos,sp
   add      x2,rp,#6cells
   ldp      x0,x1,[x2]
   add      tos,x1,x0
c;
code klimit  ( -- n )
   push     tos,sp
   ldr      tos,[rp,#7cells]
   eor      tos,tos,#0x8000.0000.0000.0000
c;

code (leave)  ( -- )
   inc     rp,#2cells        \ get rid of the loop indices
   ldr     ip,[rp],#1cell
   ldrsw   x0,[ip]          \ branch
   add     ip,ip,x0
c;

code (?leave)  ( f -- )
   cmp       tos,#0
   pop       tos,sp
   = if
       ldr   w0,[ip],#/token
\+ itc add   lr,x0,org
\+ itc ldr   w0,[lr],#/token
       add   x0,x0,org
       br    x0
   then
   inc       rp,#2cells     \ get rid of the loop indices
   ldr       ip,[rp],#1cell
   ldrsw     x0,[ip]       \ branch
   add       ip,ip,x0
c;

code unloop  ( -- )  inc rp,#3cells  c;  \ Discard the loop indices

\ =======================================
\
\       MISC WORDS
\
\ =======================================

\ returns the following token as a code field address
code (')  ( -- acf )
   push    tos,sp
   ldr     wtos,[ip],#/token
   add     tos,tos,org
c;

\ Modifies caller's ip to skip over an in-line string
code skipstr  ( -- adr len)
   push    tos,sp
   ldr     x0,[rp]
   ldrb    wtos,[x0],#1
   push    x0,sp
   add     x0,x0,tos
   inc     x0,#/token
   and     x0,x0,#-/token
   str     x0,[rp]
c;
\ runtime code for an inline string with leading 8-bit count
code (")  ( -- adr len)
   push    tos,sp
   ldrb    wtos,[ip],#1
   push    ip,sp
   add     ip,ip,tos
   inc     ip,#/token
   and     ip,ip,#-/token
c;
\ runtime code for an inline string with leading 32-bit count
code (l")  ( -- adr len)
   push    tos,sp
   ldr     wtos,[ip],#4
   push    ip,sp
   add     ip,ip,tos
   inc     ip,#/token
   and     ip,ip,#-/token
c;
\ runtime code for an inline string with leading cell-sized count
code (n")  ( -- adr len)
   push    tos,sp
   ldr     tos,[ip],#8
   push    ip,sp
   add     ip,ip,tos
   inc     ip,#/token
   and     ip,ip,#-/token
c;

\ =======================================
\
\       CASE / OF / ENDOF / ENDCASE
\
\ =======================================

\ Run time code for the case statement
code (of)  ( selector test -- [ selector ] )
   mov     x0,tos
   pop     tos,sp
   cmp     tos,x0
   <> if
      ldrsw x0,[ip]
      add   ip,ip,x0
      next
   then
   pop     tos,sp
   inc     ip,#/token
c;

\ (endof) is the same as branch, and (endcase) is the same as drop,
\ but redefining them this way makes the decompiler much easier.
code (endof)   ( -- )  \ branch
   ldrsw  x0,[ip]
   add    ip,ip,x0
c;

code (endcase)  ( n -- )  pop tos,sp  c;  \ drop

\ "and of"
\ essentially   " selector mask and value = if drop  "
code (af)  ( selector mask val -- [ selector ] )
   mov     x0,tos     \ val
   pop     x1,sp      \ mask
   pop     tos,sp     \ selector
   and     x1,x1,tos
   cmp     x1,x0
   <> if
      ldrsw x0,[ip]
      add   ip,ip,x0
      next
   then
   pop     tos,sp
   inc     ip,#/token
c;


\ =======================================
\
\          $CASE
\
\ =======================================

\ ($endof) is the same as branch, and ($endcase) is a 2drop,
\ but redefining them this way makes the decompiler much easier.
\ $of is written completely in Forth.
\ code ($case)  ( $ -- $ )  c;

code ($endof)   ( -- )  \ branch
   ldrsw  x0,[ip]
   add    ip,ip,x0
c;

code ($endcase)  ( -- )   inc sp,#1cell   pop tos,sp  c;  \ 2drop
\ code ($endcase)  ( -- )  c;

\ =======================================
\
\          DIGIT
\  convert a character to a digit in the given base
\
\ =======================================

code digit  ( char base -- digit true | char false )
   mov     x0,tos          \ x0 base
   ldr     x1,[sp]         \ x1 char
   and     x1,x1,#0xff
   cmp     x1,#0x41        \ ascii A
   >= if
      cmp     x1,#0x5b     \ ascii [
      < if
         inc     x1,#0x20
      then
   then
   movz    tos,#0          \ tos false
   subs    x1,x1,#0x30
   < if
      next
   then
   cmp     x1,#10
   >= if
      cmp     x1,#0x31
      < if
         next
      then
      dec     x1,#0x27
   then
   cmp     x1,x0
   >= if
      next
   then
   str     x1,[sp]
   movn    tos,#0       \ tos true
c;


\ =======================================
\
\          MOVE and FILL
\
\ =======================================

code cmove  ( from to cnt -- )   \ move cnt bytes using incrementing source address
   adds    x0,tos,#0       \ x0 cnt
   ldr     x1,[sp],#1cell
   pop2    x2,tos,sp
   0= if           \ optimize zero-length move
      next
   then
   cmp     x1,x2   \ optimize zero-distance move
   = if
      next
   then
   begin
      ldrb    w3,[x2],#1
      strb    w3,[x1],#1
      decs    x0,#1
   0= until
c;

code cmove>  ( from to cnt -- )   \ move cnt bytes using decrementing source address
   adds    x0,tos,#0       \ x0 cnt
   pop2    x1,x2,sp
   ldr     tos,[sp],#1cell
   0= if           \ optimize zero-length move
      next
   then
   cmp     x1,x2   \ optimize zero-distance move
   = if
      next
   then
   begin
      decs    x0,#1
      ldrb    w3,[x2,x0]
      strb    w3,[x1,x0]
   0= until
c;

\ sometimes byte writes are not allowed
code lmove  ( from to cnt -- )   \ move cnt bytes using incrementing source address
   adds    x0,tos,#0       \ x0 cnt
   set     x3,#3
   bic     x0,x0,x3        \ drop the last few bytes if not a multiple of 4
   ldr     x1,[sp],#1cell
   pop2    x2,tos,sp
   0= if           \ optimize zero-length move
      next
   then
   cmp     x1,x2   \ optimize zero-distance move
   = if
      next
   then
   begin
      ldr     w3,[x2],#4
      str     w3,[x1],#4
      decs    x0,#4
   0= until
c;

\
\ move  This could use some significant performance enhancments.  :-)
\
code move ( src dst len -- )
   adds    x0,tos,#0       \ x0 cnt
   pop2    x1,x2,sp        \ x1 = dst, x2 = src
   ldr     tos,[sp],#1cell
   0= if           \ optimize zero-length move
      next
   then
   cmp     x1,x2   \ optimize zero-distance move
   = if
      next
   then
   u< if
      \ cmove
      orr	x3,x0,x1
      orr	x3,x3,x2
      ands      xzr,x3,#31
      0= if
         \ qmove
         begin
            ldp    x4,x5,[x2],#16
            ldp    x6,x7,[x2],#16
            stp    x4,x5,[x1],#16
            stp    x6,x7,[x1],#16
            subs   x0,x0,#32
         0= until
         next
      then

      ands	xzr,x3,#3
      0= if
        begin
           ldr     w3,[x2],#4
           str     w3,[x1],#4
           decs    x0,#4
        0= until
        next
      then

      \ Move by byte
      begin
         ldrb    w3,[x2],#1
         strb    w3,[x1],#1
         decs    x0,#1
      0= until
   else
      orr	x3,x0,x1
      orr	x3,x3,x2
      ands      xzr,x3,#31
      0= if
         \ qmove>
         add x2, x2, x0
         add x1, x1, x0
         begin
            subs   x0,x0,#32
            ldp    x4,x5,[x2, #-16]!
            ldp    x6,x7,[x2, #-16]!
            stp    x4,x5,[x1, #-16]!
            stp    x6,x7,[x1, #-16]!
         0= until
         next
      then

      \ cmove>
      orr	x3,x0,x1
      orr	x3,x3,x2
      ands	xzr,x3,#3
      0= if
        begin
           decs    x0,#4
           ldr     w3,[x2,x0]
           str     w3,[x1,x0]
        0= until
        next
      then
      begin
         decs    x0,#1
         ldrb    w3,[x2,x0]
         strb    w3,[x1,x0]
      0= until
   then
c;

\ fill slowly.  I'm sure you can figure out six different optimizations for this one.
\ fill a range with a 8-bit value
code fill       ( adr cnt char -- )
   pop2      x0,x1,sp             \ x0 = cnt, x1 = adr, tos = char
   ands	     xzr,x1,#7
   0= if     \ Quad aligned?
      and         tos,tos,#255
      orr         x7,tos,tos, lsl #8
      orr         x7,x7,x7, lsl #16
      orr         x7,x7,x7, lsl #32
      begin
         cmp	     x0,#128
      >= while
         stp      x7,x7,[x1],#16
         stp      x7,x7,[x1],#16

         stp      x7,x7,[x1],#16
         stp      x7,x7,[x1],#16

         stp      x7,x7,[x1],#16
         stp      x7,x7,[x1],#16

         stp      x7,x7,[x1],#16
         stp      x7,x7,[x1],#16

	 sub	  x0,x0,#128
      repeat
   then
   begin
      decs      x0,#1
      >= if
         strb   wtos,[x1],#1
      then
   < until
   pop       tos,sp
c;
\ fill a range with a 16-bit value
code wfill       ( adr cnt w -- )
   pop2      x0,x1,sp             \ x0 = cnt, x1 = adr, tos = w
   begin
      decs      x0,#1
      >= if
         strh   wtos,[x1],#2
      then
   < until
   pop       tos,sp
c;
\ fill a range with a 24-bit value
code tfill       ( adr cnt t -- )
   pop2      x0,x1,sp             \ x0 = cnt, x1 = adr, tos = t
   begin
      decs      x0,#1
      >= if
	 strh   wtos,[x1],#2
	 lsr    tos,tos,#16
         strb   wtos,[x1],#1
      then
   < until
   pop       tos,sp
c;
\ fill a range with a 32-bit value
code lfill       ( adr cnt l -- )
   pop2      x0,x1,sp             \ x0 = cnt, x1 = adr, tos = char
   begin
      decs      x0,#4
      >= if
         str    wtos,[x1],#4
      then
   < until
   pop       tos,sp
c;
\ fill a range with a 64-bit value
code qfill       ( adr cnt l -- )
   pop2      x0,x1,sp             \ x0 = cnt, x1 = adr, tos = char
   begin
      decs      x0,#8
      >= if
         str    tos,[x1],#8
      then
   < until
   pop       tos,sp
c;

\ =======================================
\
\          STRING PRIMITIVES
\
\ =======================================

\ remove cnt chars from start of string
code /string  ( adr len cnt -- adr' len' )
   \ tuck - -rot + swap
   pop2   x0,x1,sp     \ x0 len, x1 adr, tos cnt
   add    x1,x1,tos
   push   x1,sp
   sub    tos,x0,tos
c;

\ Skip initial occurrences of bvalue, returning the residual length
code bskip  ( adr len bvalue -- residue )
   pop2   x0,x1,sp     \ r0-len r1-adr tos-bvalue
   mov    x2,tos       \ r2-bvalue
   mov    tos,x0                 \ tos: len
   ands   xzr,tos,tos
   = if next then      \ Bail out if len=0

   begin
      ldrb   w0,[x1],#1
      cmp    x0,x2
      <> if next then
      decs   tos,#1
   = until
c;

\ Skip initial occurrences of lvalue, returning the residual length
code lskip  ( adr len lvalue -- residue )
   pop2   x0,x1,sp     \ x0-len x1-adr tos-bvalue
   mov    x2,tos       \ r2-lvalue
   mov    tos,x0                 \ tos: len
   ands   xzr,tos,tos
   = if next then      \ Bail out if len=0

   begin
      ldr    w0,[x1],#4
      cmp    x0,x2
      <> if next then
      decs   tos,#4
   = until
c;

\ Find the first occurence of bvalue, returning the residual string
code bscan  ( adr len bvalue -- adr' len' )
   pop2   x0,x1,sp                \ r0-len r1-adr tos-bvalue
   mov    x2,tos                  \ r2-bvalue
   mov    tos,x0                  \ tos: len
   ands   xzr,tos,tos
   0= if  push x1,sp  next  then  \ Bail out if len=0

   begin
      ldrb   w0,[x1],#1
      cmp    x0,x2
      = if
         dec    x1,#1
         push   x1,sp
         next
      then
      decs   tos,#1
   = until
   push x1,sp
c;

\ Find the first occurrence of wvalue, returning the residual string
code wscan  ( adr len wvalue -- adr' len' )
   pop2   x0,x1,sp                \ r0-len r1-adr tos-wvalue
   mov    x2,tos                  \ r2-lvalue
   mov    tos,x0                  \ tos: len
   ands   xzr,tos,tos
   0= if  push x1,sp  next  then  \ Bail out if len=0

   begin
      ldrh   w0,[x1],#2
      cmp    x0,x2
      = if
         dec    x1,#2
         push   x1,sp
         next
      then
      decs   tos,#2
   <= until
   push   x1,sp
   movz   tos,#0
c;

\ Find the first occurrence of lvalue, returning the residual string
code lscan  ( adr len lvalue -- adr' len' )
   pop2   x0,x1,sp               \ x0: len x1: adr tos-lvalue
   mov    x2,tos                 \ x2: lvalue
   mov    tos,x0                 \ tos: len
   ands   xzr,tos,tos
   0= if  push x1,sp  next  then  \ Bail out if len=0

   begin
      ldr    w0,[x1],#4
      cmp    x0,x2
      = if
         dec    x1,#4
         push   x1,sp
         next
      then
      decs   tos,#4
   <= until
   push   x1,sp
   movz   tos,#0
c;

\ Find the first occurrence of xvalue, returning the residual string
code xscan  ( adr len value -- adr' len' )
   pop2   x0,x1,sp               \ x0: len x1: adr tos-xvalue
   mov    x2,tos                 \ x2: value
   mov    tos,x0                 \ tos: len
   ands   xzr,tos,tos
   0= if  push x1,sp  next  then  \ Bail out if len=0

   begin
      ldr    x0,[x1],#8
      cmp    x0,x2
      = if
         dec    x1,#8
         push   x1,sp
         next
      then
      decs   tos,#8
   <= until
   push   x1,sp
   movz   tos,#0
c;

: scan  ( adr len value -- adr' len' )  xscan  ;

code upc  ( char -- upper-case-char )
   and       tos,tos,#0xff
   cmp       tos,#0x61      \ ascii a
   < if next then
   cmp       tos,#0x7b      \ ascii {
   < if dec  tos,#0x20  then
c;

code upper  (s adr len -- )
   pop       x0,sp
   begin
      cmp    tos,#0
      sub    tos,tos,#1
   0<> while
      ldrb   w3,[x0]
      cmp       w3,#0x61      \ ascii a
      >= if
	 cmp       w3,#0x7b      \ ascii {
	 < if  sub  w3,w3,#0x20  then
      then
      strb   w3,[x0],#1
   repeat
   pop       tos,sp
c;

code lcc  ( char -- lower-case-char )
   and       tos,tos,#0xff
   cmp       tos,#0x41      \ ascii A
   < if next then
   cmp       tos,#0x5b      \ ascii [
   < if inc  tos,#0x20  then
c;

code lower  (s adr len -- )
   pop       x0,sp
   begin
      cmp    tos,#0
      sub    tos,tos,#1
   0<> while
      ldrb   w3,[x0]
      cmp       w3,#0x41      \ ascii A
      >= if
	 cmp       w3,#0x5b      \ ascii [
	 < if  add  w3,w3,#0x20  then
      then
      strb   w3,[x0],#1
   repeat
   pop       tos,sp
c;

code qcomp  ( up save size -- -1 == not-equal | 0 == equal )
   ldp    x6,x7,[sp],#16

   begin
      ldp   x2,x3,[x6],#16
      ldp   x4,x5,[x7],#16
      cmp   x2,x4
      0<>  if
         sub   x6,x6,#16
         sub   x7,x7,#16
         movn  tos,#0
         next
      then
      cmp  x3,x5
      0<>  if
         sub   x6,x6,#16
         sub   x7,x7,#16
         movn  tos,#0
         next
      then

      subs  tos,tos,#16
   0=  until

   movz  tos,#0
c;

code comp  ( adr1 adr2 len -- -1 | 0 | 1 )
   inc       tos,#1                \ tos length
   pop2      x0,x1,sp
   begin
      decs      tos,#1
   0<> while
      ldrb      w2,[x0],#1
      ldrb      w3,[x1],#1
      cmp       x2,x3
      0<> if
         > if movz  tos,#1 then
         < if cstf  tos,<  then   \ tos = -1
         next
      then
   repeat
   movz    tos,#0
c;


code caps-comp  ( adr1 adr2 len -- -1 | 0 | 1 )
   add     tos,tos,#1          \ tos length
   pop2    x0,x1,sp
   begin
      decs     tos,#1
   0<> while
      movz    x2,#0
      ldrb    w2,[x0],#1
      cmp     x2,#0x41     \ ascii A
      >= if
         cmp     x2,#0x5b  \ ascii [
         < if inc  x2,#0x20 then
      then
      movz    x3,#0
      ldrb    w3,[x1],#1
      cmp     x3,#0x41     \ ascii A
      >= if
         cmp     x3,#0x5b  \ ascii [
         < if inc  x3,#0x20 then
      then
      cmp     x2,x3    \ Compare the case-normalized chars
      0<> if
         > if movz   tos,#1 then
         < if cstf   tos,< then   \ tos = -1
         next
      then
   repeat
   movz    tos,#0
c;


code pack  ( str-adr len to -- to )
   mov     x0,tos        \ to
   pop2    x1,x2,sp
   ands    x1,x1,#0xff   \ set length flag
   strb    w1,[x0],#1
   0<> if
      begin
         ldrb    w3,[x2],#1
         strb    w3,[x0],#1
         decs    x1,#1
      0= until
   then
   movz    x1,#0
   strb    w1,[x0],#1
c;


\
\ Walk along in memory starting at adr and progressing by direction
\ (presumably -1 or 1, but other values might be useful, too) searching
\ for a byte with its high bit set.
\

code traverse   ( adr direction -- adr' )
   mov     x0,tos         \ direction r0
   pop     tos,sp         \ adr -> tos
   add     tos,tos,x0
   begin
      ldrb    w1,[tos]
      ands    w1,w1,#0x80
   0= while
      add     tos,tos,x0
   repeat
c;

code count      ( adr -- adr+1 cnt )
   mov     x0,tos
   ldrb    wtos,[x0],#1
   push    x0,sp
c;
code lcount      ( adr -- adr+4 cnt )
   mov     x0,tos
   ldr     wtos,[x0],#/token
   push    x0,sp
c;
code ncount      ( adr -- adr+8 cnt )
   mov     x0,tos
   ldr     w1,[x0],#4
   ldr     w2,[x0],#4
   orr     tos, x1,x2,lsl#32
   push    x0,sp
c;

code cindex  ( adr len char -- [ index true ]  | false )
   pop2    x1,x2,sp      \ x1 = len, x2 = adr, tos = char
   begin
      cmp     x1,#0
      sub     x1,x1,#1
   0<> while
      ldrb   w3,[x2],#1
      cmp    w3,tos
      0= if
	 sub     x2,x2,#1
	 push    x2,sp
	 movn    tos,#0       \ tos true
	 next
      then
   repeat
   orr     tos,xzr,xzr
c;

\ Adr2 points to the delimiter or to the end of the buffer
\ Adr3 points to the character after the delimiter or to the end of the buffer
code scantochar  ( adr1 len1 char -- adr1 adr2 adr3 )
   mov     x4,tos        \ x4 = char
   pop2    x1,tos,sp     \ x1 = len, tos = adr, x4 = char
   push    tos,sp        \ push adr1, first result
   begin
      cmp     x1,#0
      sub     x1,x1,#1
   0> while
      ldrb   w3,[tos],#1
      cmp    w3,x4
      0= if
	 sub     x2,tos,#1   \ tos = adr3
	 push    x2,sp       \ x2 = adr2
	 next
      then
   repeat
   push    tos,sp       \ tos = end of the buffer
c;

code scantowhite  ( adr1 len1 -- adr1 adr2 adr3 )
   mov     x1,tos        \ x1 = len
   ldr     tos,[sp]      \ tos = adr
   begin
      cmp     x1,#0
      sub     x1,x1,#1
   0> while
      ldrb   w3,[tos],#1
      cmp    w3,#0x20
      0<= if
	 sub     x2,tos,#1   \ tos = adr3
	 push    x2,sp       \ x2 = adr2
	 next
      then
   repeat
   push    tos,sp       \ tos = end of the buffer
c;

code skipwhite  ( adr1 len1 -- adr2 len2  )
   pop     x1,sp        \ x1 = adr
   begin
      cmp    tos,#0
   0> while
      ldrb   w3,[x1]
      cmp    w3,#0x20
      0> if
	 push    x1,sp
	 next
      then
      sub    tos,tos,#1
      add     x1,x1,#1
   repeat
   push    x1,sp
c;

\ =======================================
\
\          BASIC KERNEL WORDS
\
\ =======================================

code noop  ( -- )   c;
code uspin  ( -- )  begin again  c;  \ a machine language spinner (debugging word)

code and     ( n1 n2 -- n3 )  pop x0,sp  and tos,tos,x0  c;
code or      ( n1 n2 -- n3 )  pop x0,sp  orr tos,tos,x0  c;
code xor     ( n1 n2 -- n3 )  pop x0,sp  eor tos,tos,x0  c;
code andc    ( n1 n2 -- n3 )  pop x0,sp  bic tos,x0,tos  c;

code not     ( n1 -- n2 )  orn tos,xzr,tos  c;
code invert  ( n1 -- n2 )  orn tos,xzr,tos  c;

code lshift  ( n1 cnt -- n2 )  pop x0,sp  lslv tos,x0,tos  c;
code rshift  ( n1 cnt -- n2 )  pop x0,sp  lsrv tos,x0,tos  c;
code <<      ( n1 cnt -- n2 )  pop x0,sp  lslv tos,x0,tos  c;
code >>      ( n1 cnt -- n2 )  pop x0,sp  lsrv tos,x0,tos  c;
code >>a     ( n1 cnt -- n2 )  pop x0,sp  asrv tos,x0,tos  c;
code +    ( n1 n2 -- n3 )  pop x0,sp  add tos,tos,x0  c;
code -    ( n1 n2 -- n3 )  pop x0,sp  sub tos,x0,tos  c;

code negate   ( n -- -n )  sub tos,xzr,tos  c;

code ?negate  ( n f -- n | -n )  cmp tos,#0  pop tos,sp  < if  sub tos,xzr,tos  then  c;

code abs   ( n -- [n] )  cmp tos,#0  0< if  sub tos,xzr,tos  then  c;

code min   ( n1 n2 -- n1|n2 )  pop x0,sp  cmp x0,tos  csel tos,tos,x0,gt  c;
code umin  ( u1 u2 -- u1|u2 )  pop x0,sp  cmp x0,tos  csel tos,tos,x0,cs  c;
code max   ( n1 n2 -- n1|n2 )  pop x0,sp  cmp tos,x0  csel tos,tos,x0,gt  c;
code umax  ( u1 u2 -- u1|u2 )  pop x0,sp  cmp tos,x0  csel tos,tos,x0,cs  c;

code up@  ( -- adr )  push tos,sp  mov tos,up  c;
code sp@  ( -- adr )  push tos,sp  mov tos,sp  c;
code rp@  ( -- adr )  push tos,sp  mov tos,rp  c;
code up!  ( adr -- )  mov up,tos  pop tos,sp  c;
code sp!  ( adr -- )  mov sp,tos  pop tos,sp  c;
code rp!  ( adr -- )  mov rp,tos  pop tos,sp  c;

code >r   ( n -- )  push tos,rp  pop tos,sp  c;
code r>   ( -- n )  push tos,sp  pop tos,rp  c;
code r@   ( -- n )  push tos,sp  ldr tos,[rp]  c;

code 2>r  ( n1 n2 -- )  mov x0,tos  pop2 x1,tos,sp  push2 x0,x1,rp  c;
code 2r>  ( -- n1 n2 )              pop2 x0,x1,rp   push2 x1,tos,sp   mov tos,x0  c;
code 2r@  ( -- n1 n2 )              ldp x0,x1,[rp]  push2 x1,tos,sp   mov tos,x0  c;

code >ip  ( n -- )  push tos,rp  pop tos,sp  c;
code ip>  ( -- n )  push tos,sp  pop tos,rp  c;
code ip@  ( -- n )  push tos,sp  ldr tos,[rp]  c;



\ =======================================
\
\          STACK MANIPULATORS
\
\ =======================================


code drop  ( n1 n2 -- n1 )  pop tos,sp  c;
code dup   ( n1 -- n1 n1 )  push tos,sp  c;
code ?dup  ( n1 -- 0 | n1 n1 )  cmp tos,#0  ne if push tos,sp then  c;
code over  ( n1 n2 -- n1 n2 n1 )  push tos,sp  ldr tos,[sp,#1cell]  c;
code swap  ( n1 n2 -- n2 n1 )  ldr x0,[sp]  str tos,[sp]  mov tos,x0  c;
code rot   ( n1 n2 n3 -- n2 n3 n1 )
   mov       x0,tos
   ldp       x1,tos,[sp]
   stp       x0,x1,[sp]
c;
code -rot  ( n1 n2 n3 -- n3 n1 n2 )
   ldp       x1,x2,[sp]
   stp       x2,tos,[sp]
   mov       tos,x1
c;
\ swap over
code tuck  ( n1 n2 -- n2 n1 n2 )  pop x0,sp  push2 x0,tos,sp  c;
\ swap drop
code nip   ( n1 n2 -- n2 )  inc sp,#1cell  c;

code 2drop  ( n1 n2 -- )           inc sp,#1cell   pop tos,sp  c;
code 3drop  ( n1 n2 n3 -- )        inc sp,#2cells  pop tos,sp  c;
code 4drop  ( n1 n2 n3 n4 -- )     inc sp,#3cells  pop tos,sp  c;
code 5drop  ( n1 n2 n3 n4 n5 -- )  inc sp,#4cells  pop tos,sp  c;

code ndrop  ( n1 .. nN #N -- )
   set       x0,#1cell
   madd      sp,tos,x0,sp
   pop       tos,sp
c;

code 2dup   ( n1 n2 -- n1 n2 n1 n2 )  ldr x0,[sp]  push2 x0,tos,sp  c;
code 2over  ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 )
   ldr       x0,[sp,#2cells]
   push2     x0,tos,sp
   ldr       tos,[sp,#3cells]
c;
code 2swap  ( n1 n2 n3 n4 -- n3 n4 n1 n2 )
   mov       x0,tos
   pop2      x1,x2,sp
   pop       x3,sp
   push2     x0,x1,sp
   push      x3,sp
   mov       tos,x2
c;
code 3dup   ( n1 n2 n3 -- n1 n2 n3 n1 n2 n3 )
   ldp       x0,x1,[sp]          \ x0: n2 x1: n1
   push      tos,sp              \ tos: n3
   push2     x0,x1,sp
c;
code 4dup  ( n1 n2 n3 n4 -- n1 n2 n3 n4 n1 n2 n3 n4 )
   ldp       x0,x1,[sp,#1cell]   \ x0: n2 x1: n1
   ldr       x2,[sp]             \ x2: n3 tos: n4
   push2     x1,tos,sp
   push2     x2,x0,sp
c;
code 5dup  ( n1 n2 n3 n4 n5 -- n1 n2 n3 n4 n5 n1 n2 n3 n4 n5 )
   pop2      x2,x3,sp
   pop2      x0,x1,sp
   push2     x0,x1,sp
   push2     x2,x3,sp
   push      tos,sp
   push2     x0,x1,sp
   push2     x2,x3,sp
c;

code over+  ( n1 n2 -- n1 n2+n1 )
   ldr       x0,[sp]
   add       tos,tos,x0
c;

code pick   ( nm ... n1 n0 k -- nm ... n1 n0 nk )  ldr tos,[sp,tos,lsl #3]  c;

\ \ 0 roll is nop, 1 roll is swap, 2 roll is rot, etc
\ \ roll mth item to top of stack
\ code x-roll  ( ... m -- ... )  \ test me!
\   add       x1,sp,tos,lsl #3
\   ldr       tos,[x1]
\   begin
\      ldr    x0,[x1,#-1cell]
\      str    x0,[x1],#-1cell
\      cmp    x1,sp
\   < until
\   inc       sp,#1cell
\ c;

\ code between  ( n min max -- flag )
\   mov       r1,tos
\   ldmia     sp!,{r0,r2}
\   mov       tos,#0
\   cmp       r2,r0
\   ldrlt     pc,[ip],1cell
\   cmp       r2,r1
\   mvnle     tos,#0
\ c;

\ =======================================
\
\       CPU ARCHITECTURE WORDS
\
\ =======================================

code arm64?  ( -- true  )  push  tos,sp  movn  tos,#0  c;
code arm?    ( -- false )  push  tos,sp  movz  tos,#0  c;
code x86?    ( -- false )  push  tos,sp  movz  tos,#0  c;

\ =======================================
\
\       WORD LEVEL CONTROL FLOW
\
\ =======================================

code unnest  ( -- )  ldr  ip,[rp],#1cell  c;
code exit    ( -- )  ldr  ip,[rp],#1cell  c;
code ?exit   ( flag -- )
   cmp  tos,#0
   pop  tos,sp
   ne if
      ldr  ip,[rp],#1cell
   then
c;


\ =======================================
\
\        WORD ADDRESS CONVERTERS
\
\ =======================================

[ifdef] itc

code >body  ( cfa -- pfa )
   inc     tos,#/token
c;
code body>  ( pfa -- cfa )
   dec     tos,#/token
c;

\ The "word type" is a number which distinguishes one type of word
\ from another.  This is highly implementation-dependent.
\ For this implementation, return the token of the "do-word" at cfa.

code word-type  ( cfa -- word-type )
   ldr     wtos,[tos]
   add     tos, tos, org
c;

[else] \ not itc

\ Q: Why not just 4+ and 4-  ??

\ A: Per the ARM32 version, we're looking for a branch and link to indicate
\ that the PFA is different from the CFA.  The x86 implementation doesn't
\ have any of this non-sense.

code >body  ( cfa -- pfa )
   ldr     w0,[tos]
   and     w0,w0,#0x7C00.0000
   lsr     w0,w0,#24
   cmp     x0,#0x14
   = if inc tos,#/token then
c;
code body>  ( pfa -- cfa )
   sub     x0,tos,#/token
   ldr     w0,[x0]
   and     w0,w0,#0x7C00.0000
   lsr     w0,w0,#24
   cmp     x0,#0x14
   = if dec tos,#/token then
c;

\ The "word type" is a number which distinguishes one type of word
\ from another.  This is highly implementation-dependent.
\ For this implementation, it always returns the address of the
\ code sequence for that word.

\ If the code field contains a branch and link, return the target address.
\ Otherwise return the address of the code field.
code word-type  ( cfa -- word-type )
   ldr     w0,[tos]
   and     w1,w0,#0x7C00.0000
   lsr     w1,w1,#24
   cmp     w1,#0x14
   = if
      lsl   w0,w0,#6
      sbfm  x0,x0,#4,#31  \ asr w0,w0,#4; sxtw x0,w0
      add   tos,tos,x0
   then
c;

[then] \ itc

\ =======================================
\
\          MISCELLANEOUS
\
\ =======================================

\ Working with a 32 bit word
code lwsplit  ( l -- w.low w.high )
   and     x0,tos,#0xFFFF
   lsr     tos,tos,#16
   push    x0,sp
   and     tos,tos,#0xFFFF
c;
code wljoin  ( w.low w.high -- l )
   and     tos,tos,#0xFFFF      \ Keep only the low order 16 bits
   lsl     tos,tos,#0x10
   pop     x0,sp
   and     x0,x0,#0xFFFF        \ Keep only the low order 16 bits
   orr     tos,tos,x0
c;
code lbsplit  ( l -- b0 b1 b2 b3 )
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     tos,tos,#0xFF
c;
code bljoin  ( b0 b1 b2 b3 -- l )
   and     tos,tos,#0xFF      \ Keep only the low order 8 bits
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF        \ Keep only the low order 8 bits
   orr     tos,tos,x0
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF        \ Keep only the low order 8 bits
   orr     tos,tos,x0
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF        \ Keep only the low order 8 bits
   orr     tos,tos,x0
c;
code xbsplit  ( l -- b0 b1 b2 b3 )
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     x0,tos,#0xFF
   push    x0,sp
   lsr     tos,tos,#8
   and     tos,tos,#0xFF
c;
code bxjoin  ( b0 b1 b2 b3 -- l )
   and     tos,tos,#0xFF      \ Keep only the low order 8 bits
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF
   orr     tos,tos,x0
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF
   orr     tos,tos,x0
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF
   orr     tos,tos,x0
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF
   orr     tos,tos,x0
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF
   orr     tos,tos,x0
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF
   orr     tos,tos,x0
   lsl     tos,tos,#08
   pop     x0,sp
   and     x0,x0,#0xFF
   orr     tos,tos,x0
c;
code lxjoin  ( l.low l.high -- x )
   pop     x0,sp
   orr     tos,x0,tos,lsl #32
c;

\ Swap lo/high of a 32 bit value
code wflip  ( n1 -- n2 )  ror wtos,wtos,#31   c;

\ Swap lo/high of a 16 bit value
code flip   ( w1 -- w2 )
   lsr     x0,tos,#8
   lsl     x1,tos,#8
   orr     tos,x0,x1
   and     tos,tos,#0xFFFF
c;

\ =======================================
\
\          COMPARATORS
\
\ =======================================

code 0=   ( n -- f )  cmp tos,#0  cstf tos,eq  c;
code 0<>  ( n -- f )  cmp tos,#0  cstf tos,ne  c;
code 0<   ( n -- f )  cmp tos,#0  cstf tos,mi  c;
code 0>=  ( n -- f )  cmp tos,#0  cstf tos,pl  c;
code 0>   ( n -- f )  cmp tos,#0  cstf tos,gt  c;
code 0<=  ( n -- f )  cmp tos,#0  cstf tos,le  c;

\ tos = n2
\ x0  = n1
code >    ( n1 n2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, gt  c;
code <    ( n1 n2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, lt  c;
code =    ( n1 n2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, eq  c;
code <>   ( n1 n2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, ne  c;
code u>   ( u1 u2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, hi  c;
code u<=  ( u1 u2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, ls  c;
code u<   ( u1 u2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, cc  c;
code u>=  ( u1 u2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, cs  c;
code >=   ( n1 n2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, ge  c;
code <=   ( n1 n2 -- f )  pop x0,sp  cmp x0,tos  cstf tos, le  c;


\ =======================================
\
\          SINGLE OP MATH
\
\ =======================================

code 1+   ( n -- n+1 )   inc tos,#1      c;
code 2+   ( n -- n+2 )   inc tos,#2      c;
code 1-   ( n -- n-1 )   dec tos,#1      c;
code 2-   ( n -- n-2 )   dec tos,#2      c;
code 2/   ( n -- n/2 )   asr tos,tos,#1  c;
code u2/  ( u -- u/2 )   lsr tos,tos,#1  c;
code 8/   ( n -- n/8 )   asr tos,tos,#3  c;
code 2*   ( n -- 2n )    lsl tos,tos,#1  c;
code 3*   ( n -- 3n )    add tos,tos,tos,lsl #1  c;
code 4*   ( n -- 4n )    lsl tos,tos,#2  c;
code 8*   ( n -- 8n )    lsl tos,tos,#3  c;


\ =======================================
\
\          FETCH/STORE
\
\ =======================================

code !    ( n adr -- )  pop x0,sp  str x0,[tos]  pop tos,sp  c;
code @    ( adr -- n )  ldr tos,[tos]  c;

\ XXX these should also handle misalignment
code on   ( adr -- )  orn x0,xzr,xzr  str x0,[tos]  pop tos,sp  c;
code off  ( adr -- )  str xzr,[tos]  pop tos,sp  c;
code +!   ( n adr -- )
   mov       x0,tos
   pop2      x1,tos,sp
   ldr       x2,[x0]
   add       x2,x2,x1
   str       x2,[x0]
c;

code l+!   ( n adr -- )
   mov       x0,tos
   pop2      x1,tos,sp
   ldr       w2,[x0]
   add       w2,w2,w1
   str       w2,[x0]
c;

code or!  ( n adr -- )
   mov       x0,tos
   pop2      x1,tos,sp
   ldr       x2,[x0]
   orr       x2,x2,x1
   str       x2,[x0]
c;

code lor!  ( n adr -- )
   mov       x0,tos
   pop2      x1,tos,sp
   ldr       w2,[x0]
   orr       w2,w2,w1
   str       w2,[x0]
c;

code and!  ( n adr -- )
   mov       x0,tos
   pop2      x1,tos,sp
   ldr       x2,[x0]
   and       x2,x2,x1
   str       x2,[x0]
c;

code land!  ( n adr -- )
   mov       x0,tos
   pop2      x1,tos,sp
   ldr       w2,[x0]
   and       w2,w2,w1
   str       w2,[x0]
c;

code andc!  ( n adr -- )
   mov       x0,tos
   pop2      x1,tos,sp
   ldr       x2,[x0]
   bic       x2,x2,x1
   str       x2,[x0]
c;

code landc!  ( n adr -- )
   mov       x0,tos
   pop2      x1,tos,sp
   ldr       w2,[x0]
   bic       w2,w2,w1
   str       w2,[x0]
c;

code x!   ( n adr -- )  pop x0,sp  str  x0,[tos]  pop tos,sp  c;
code x@   ( adr -- n )  ldr  tos,[tos]  c;

code stxr!   ( n adr -- result )  pop x0,sp  stxr  wtos,x0,[tos]  pop tos,sp  c;
code ldxr@   ( adr -- n )  ldxr  tos,[tos]  c;

code stlr!   ( n adr -- )  pop x0,sp  stlr  x0,[tos]  pop tos,sp  c;
code ldar@   ( adr -- n )  ldar  tos,[tos]  c;

code l!   ( n adr -- )  pop x0,sp  str  w0,[tos]  pop tos,sp  c;
code l@   ( adr -- n )  ldr  wtos,[tos]  c;
code <l@  ( adr -- n )  ldrsw  tos,[tos]  c;   \ load 32, sign-extend to 64

\ 24-bit store
code t!       ( t adr -- )
   pop    x0,sp
   strh   w0,[tos],#2
   lsr    x0,x0,#16
   strb   w0,[tos],#1
   pop    tos,sp
c;

\ 16-bit ops
code w!   ( n adr -- )  pop x0,sp  strh w0,[tos]  pop tos,sp  c;
code w@   ( adr -- n )  ldrh wtos,[tos]  c;
code <w@  ( adr -- n )  ldrsh  tos,[tos]  c;   \ load 16, sign-extend to 64

\ 8-bit ops
code c!  ( char adr -- )  pop x0,sp  strb w0,[tos]  pop tos,sp  c;
code c@  ( adr -- char )  ldrb wtos,[tos]  c;
code <c@ ( adr -- char )  ldrsb  tos,[tos]  c;  \ load 8, sign-extended to 64


code unaligned-!  ( n adr -- )
   mov       x5,tos                \ x5: adr
   pop2      x4,tos,sp             \ x4: n
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
   c;
code unaligned-@  ( adr -- n )
   and       x0,tos,#-8         \ aligned address
   ands      x1,tos,#7          \ bytes of offset
   0= if
      ldr       tos,[tos]
      next
   then
   lsl       x1,x1,#3           \ bits to shift
   ldp       x2,x3,[x0]         \ get 128 bits
   orr       x0,xzr,#0x40
   lsr       x2,x2,x1
   sub       x1,x0,x1
   lsl       x3,x3,x1
   orr       tos,x2,x3
c;

code unaligned-l!  ( l adr -- )
   mov       x5,tos                \ x5: adr
   pop2      x4,tos,sp             \ x4: n
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
c;
code unaligned-l@  ( adr -- l )
   ldrb       w0,[tos,#3]
   lsl        x0,x0,#8
   ldrb       w1,[tos,#2]
   orr        x0,x0,x1
   lsl        x0,x0,#8
   ldrb       w1,[tos,#1]
   orr        x0,x0,x1
   lsl        x0,x0,#8
   ldrb       w1,[tos]
   orr        tos,x0,x1
c;

code unaligned-w!  ( w adr -- )
   mov       x5,tos                \ x5: adr
   pop2      x4,tos,sp             \ x4: n
   strb      w4,[x5],#1
   ror       x4,x4,#8
   strb      w4,[x5],#1
c;
code unaligned-w@  ( adr -- w )
   ldrb       w1,[tos],#1
   lsl        x1,x1,#8
   ldrb       w0,[tos]
   orr       tos,x1,x0
c;

\ =======================================
\
\          DOUBLE OPERATIONS
\
\ =======================================

code 2@  ( adr -- n-high n-low )    \ low,high refer to addresses
   ldr       x0,[tos,#1cell]
   push      x0,sp
   ldr       tos,[tos]
c;
code 2!  ( n-high n-low adr -- )    \ low,high refer to addresses
   pop2      x0,x1,sp
   stp       x0,x1,[tos]
   pop       tos,sp
c;

code ntp@ ( adr -- n-high n-low )
   ldnp      x0,x1,[tos]
   push      x0,sp
   mov       tos,x1
c;

code ntp!  ( n-high n-low adr -- )
   pop2     x0,x1,sp
   stnp     x0,x1,[tos]
   pop      tos,sp
c;

: d@            ( adr -- d )  dup @  swap na1+ @  ;  \  2@ swap
: d!            ( d adr -- )  tuck na1+ ! ! ;        \ -rot swap rot 2!

code d+  ( d1 d2 -- d1+d2 )
   pop       x0,sp                \  tos(d2hi) x0(d2lo)
   pop2      x1,x2,sp             \   x1(d1hi) x2(d1lo)
   adds      x0,x0,x2
   adc       tos,tos,x1
   push      x0,sp
c;

code d-  ( d1 d2 -- d1-d2 )
   pop       x0,sp                \  tos(d2hi) x0(d2lo)
   pop2      x1,x2,sp             \   x1(d1hi) x2(d1lo)
   subs      x0,x2,x0
   sbc       tos,x1,tos
   push      x0,sp
c;

code d>  ( d1 d2 -- f )
   pop       x0,sp                \  tos(d2hi) x0(d2lo)
   pop2      x1,x2,sp             \   x1(d1hi) x2(d1lo)
   cmp       x1,tos
   = if
       cmp   x2,x0
       cstf  tos,hi
   else
       cstf  tos,gt
   then
c;

\ Use d> but reverse d1,d2: we can only use "hi" for unsigned comparison.
code d<  ( d1 d2 -- f )
   pop       x0,sp                \  tos(d2hi) x0(d2lo)
   pop2      x1,x2,sp             \   x1(d1hi) x2(d1lo)
   cmp       tos,x1
   = if
       cmp   x0,x2
       cstf  tos,hi
   else
       cstf  tos,gt
   then
c;

code d=  ( d1 d2 -- f )
   pop       x0,sp                \  tos(d2hi) x0(d2lo)
   pop2      x1,x2,sp             \   x1(d1hi) x2(d1lo)
   cmp       x1,tos
   = if
       cmp   x2,x0
   then
   cstf      tos,eq
c;
: d<>   d= 0= ;

code du>  ( d1 d2 -- f )
   pop       x0,sp                \  tos(d2hi) x0(d2lo)
   pop2      x1,x2,sp             \   x1(d1hi) x2(d1lo)
   cmp       x1,tos
   = if
       cmp   x2,x0
   then
   cstf      tos,hi
c;

code du>=  ( d1 d2 -- f )
   pop       x0,sp                \  tos(d2hi) x0(d2lo)
   pop2      x1,x2,sp             \   x1(d1hi) x2(d1lo)
   cmp       x1,tos
   = if
       cmp   x2,x0
   then
   cstf      tos,hs
c;

\ Use du> but reverse d1,d2: we can only use "hi" for unsigned comparison.
code du<  ( d1 d2 -- f )
   pop       x0,sp                \  tos(d2hi) x0(d2lo)
   pop2      x1,x2,sp             \   x1(d1hi) x2(d1lo)
   cmp       tos,x1
   = if
       cmp   x0,x2
   then
   cstf      tos,hi
c;

code du<=  ( d1 d2 -- f )
   pop       x0,sp                \  tos(d2hi) x0(d2lo)
   pop2      x1,x2,sp             \   x1(d1hi) x2(d1lo)
   cmp       tos,x1
   = if
       cmp   x0,x2
   then
   cstf      tos,hs
c;

code s>d  ( n -- d )
   push      tos,sp
   cmp       tos,#0
   cstf      tos,lt
c;

code dnegate  ( d -- -d )
   pop       x0,sp                \  tos(hi) x0(lo)
   subs      x0,xzr,x0
   sbc       tos,xzr,tos
   push      x0,sp
c;

code ?dnegate  ( d flag -- d )
   cmp       tos,#0
   pop       tos,sp
   <> if
      pop       x0,sp                \  tos(hi) x0(lo)
      subs      x0,xzr,x0
      sbc       tos,xzr,tos
      push      x0,sp
   then
c;

code dabs  ( d -- d )
   cmp       tos,#0
   < if
      pop       x0,sp                \  tos(hi) x0(lo)
      subs      x0,xzr,x0
      sbc       tos,xzr,tos
      push      x0,sp
   then
c;

code d0=  ( d -- f )
   pop       x0,sp
   orr       tos,tos,x0
   cmp       tos,#0
   cstf      tos,eq
c;

code d0<  ( d -- f )
   inc       sp,#1cell
   cmp       tos,#0
   cstf      tos,lt
c;

code d2*  ( d1 -- d2 )
   pop       x0,sp
   lsl       tos,tos,#1
   orr       tos,tos,x0,lsr #63
   lsl       x0,x0,#1
   push      x0,sp
c;
code d2/  ( d1 -- d2 )
   pop       x0,sp
   lsr       x0,x0,#1
   orr       x0,x0,tos,lsl #63
   lsr       tos,tos,#1
   push      x0,sp
c;

purpose: More math
\ think big, let's do doubles right

\ double (128-bit) shifts
code d<<  ( d0 n -- d1 )   \ double shift left
   cmp   tos,#0
   0= if  \ no shift
      pop   tos,sp
      next
   then
   pop   x1,sp       \ x1: hi0
   pop   x0,sp       \ x0: lo0
   cmp   tos,#127
   u> if   \ shifting too far, return 0 0
      push   xzr,sp
      mov    tos,xzr
      next
   then
   cmp   tos,#64
   u>= if   \ large moves are simpler
      push   xzr,sp
      lsl    tos,x0,tos
      next
   then
   lsl   x5,x1,tos  \ x5: hi1  = x..x0..0
   lsl   x4,x0,tos  \ x4: lo1  = x..x0..0
   neg   tos,tos
   lsr   x6,x0,tos  \ overflow bits from lo0 = 0..0x..x
   orr   tos,x5,x6  \ go into hi1
   push  x4,sp      \ lo1
c;

code d>>  ( d0 n -- d1 )   \ double shift right
   cmp   tos,#0
   0= if  \ no shift
      pop   tos,sp
      next
   then
   pop   x1,sp       \ x1: hi0
   pop   x0,sp       \ x0: lo0
   cmp   tos,#127
   u> if   \ shifting too far, return 0 0
      push   xzr,sp
      mov    tos,xzr
      next
   then
   cmp   tos,#64
   u>= if   \ large moves are simpler
      lsr    x0,x1,tos
      push   x0,sp
      mov    tos,xzr
      next
   then
   lsr   x5,x1,tos  \ x5: hi1 = 0..0x..x
   lsr   x4,x0,tos  \ x4: lo1 = 0..0x..x
   neg   tos,tos
   lsl   x6,x1,tos  \ overflow bits from hi0  = x..x0..0
   orr   x4,x4,x6   \ go into lo1
   push  x4,sp      \ lo1
   mov   tos,x5
c;

code d>>a  ( d0 n -- d1 )   \ double shift right arithmetic
   cmp   tos,#0
   0= if  \ no shift
      pop   tos,sp
      next
   then
   pop   x1,sp       \ x1: hi0
   pop   x0,sp       \ x0: lo0
   cmp   tos,#127
   u> if   \ shifting too far, shift 127 to return 0 0 or -1 -1
      movz   tos,#127
   then
   cmp   tos,#64
   u>= if   \ large moves are simpler
      asr    x0,x1,tos
      push   x0,sp
      cmp    x1,#0
      csinv  tos,xzr,xzr,ge
      next
   then
   asr   x5,x1,tos  \ x5: hi1 = s..sx..x
   lsr   x4,x0,tos  \ x4: lo1 = 0..0x..x
   neg   tos,tos
   lsl   x6,x1,tos  \ overflow bits from hi0  = x..x0..0
   orr   x4,x4,x6   \ go into lo1
   push  x4,sp      \ lo1
   mov   tos,x5
c;

\ =======================================
\
\        CPU/FORTH BUILD PROPERTIES
\
\ =======================================

code /char  ( -- 1 )  push tos,sp  movz tos,#1  c;
code /cell  ( -- 4 )  push tos,sp  movz tos,#1cell  c;

code chars  ( n1 -- n1 )  c;
code cells  ( n -- 8n )   lsl  tos,tos,#3  c;
code char+  ( adr -- adr1 )  inc tos,#1     c;
code cell+  ( adr -- adr1 )  inc tos,#1cell  c;
code chars+  ( adr index -- adr1 )  pop x0,sp  add tos,x0,tos  c;
code cells+  ( adr index -- adr1 )  pop x0,sp  add tos,x0,tos,lsl #3  c;

\ code n->l  ( n.unsigned -- l )
\    set  x0,#0x1.0000.0000
\    sub  x0,x0,#1
\    and  tos,tos,x0
\ c;
code n->l  ( n.unsigned -- l )   mov x0,tos   mov wtos,w0  c;
code ca+  ( adr index -- adr1 )  pop x0,sp  add tos,x0,tos  c;
code wa+  ( adr index -- adr1 )  pop x0,sp  add tos,x0,tos,lsl #1  c;
code la+  ( adr index -- adr1 )  pop x0,sp  add tos,x0,tos,lsl #2  c;
code xa+  ( adr index -- adr1 )  pop x0,sp  add tos,x0,tos,lsl #3  c;
code na+  ( adr index -- adr1 )  pop x0,sp  add tos,x0,tos,lsl #3  c;
code ta+  ( adr index -- adr1 )  pop x0,sp  add tos,x0,tos,lsl #2  c;
\ FIXME  't' is sometimes token, sometimes triple.

code ca1+  ( adr -- adr1 )  inc tos,#1  c;
code wa1+  ( adr -- adr1 )  inc tos,#2  c;
code la1+  ( adr -- adr1 )  inc tos,#4  c;
code xa1+  ( adr -- adr1 )  inc tos,#8  c;
code na1+  ( adr -- adr1 )  inc tos,#1cell  c;
code ta1+  ( adr -- adr1 )  inc tos,#/token  c;

code /c  ( -- 1 )  push tos,sp  movz tos,#1  c;
code /w  ( -- 2 )  push tos,sp  movz tos,#2  c;
code /l  ( -- 4 )  push tos,sp  movz tos,#4  c;
code /x  ( -- 8 )  push tos,sp  movz tos,#8  c;
code /n  ( -- 8 )  push tos,sp  movz tos,#1cell  c;

code /c*  ( n1 -- n1 )  c;
code /w*  ( n1 -- n2 )  lsl tos,tos,#1  c;
code /t*  ( n1 -- n2 )  add tos,tos,tos,lsl #1  c;
code /l*  ( n1 -- n2 )  lsl tos,tos,#2  c;
code /n*  ( n1 -- n2 )  lsl tos,tos,#3  c;
code /x*  ( n1 -- n2 )  lsl tos,tos,#3  c;

\ =======================================
\
\        USER AREA SUPPORT
\
\ =======================================

4 constant /user#
init-user-area constant init-user-address


\ =======================================
\
\        FIRST COLON DEFINITIONS
\
\ =======================================

\ This implementation uses 4-byte tokens, 4-byte links, and a single 4-byte instruction at acf.
: aligned      ( adr -- adr' )     #align round-up  ;
: acf-aligned  ( adr -- adr' ) #acf-align round-up  ;
: acf-align    ( -- )
   here acf-aligned here  ?do  0 c,  loop
   here 'lastacf token!
;

code dmb  ( -- )   dmb SY   c;
code dsb  ( -- )   dsb SY   c;
code isb  ( -- )   isb SY   c;
code barrier   ( -- )
   dsb SY
   isb SY
c;

\ : instruction!  ( n adr -- )  tuck l!  /l  sync-cache  ;
code instruction!  ( n adr -- )
   pop   x1,sp
   str   w1,[tos]
   ic    ivau, tos  \ flush
   dsb   SY         \ ensure completion of the invalidation
   isb   SY         \ ensure instruction fetch path sees new I cache state
   pop   tos,sp
c;
: instruction,  ( n -- )  here /l allot  instruction!  ;


code build-bl-opcode ( delta -- opcode )
   lsr   tos, tos, #2
   and   tos, tos, #0x03ff.ffff
   movz  x0, #0x9400, LSL #16
   orr   tos, tos, x0
c;

: origin-  ( adr -- offset )  origin -  ;
: origin+  ( offset -- adr )  origin +  ;

[ifdef] itc

: >code  ( acf-of-code-word -- address-of-start-of-machine-code )
   token@  \ Skip the token at CFA
;

: code?  ( acf -- f )  \ True if the acf is for a code word
   >code /token -  ( address of NOP header? )
   l@ h# 9100.03ff n->l =
;
\ place token of target at adr
: put-cf   ( target adr -- )
   >r origin- r> instruction!
;

: place-cf      ( xt -- )
   acf-align instruction,
;

: docolon       ( -- adr ) docolon                 ;
: colon-cf      ( -- )     docolon       place-cf  ;
: code-cf       ( -- )     here /token 2* + origin- place-cf  \ could also be DOCODE
                           h# 910003ff ( add xsp,xsp,#0 ) instruction,  ;
: create-cf     ( -- )     docreate      place-cf  ;
: label-cf      ( -- )     dolabel       place-cf  ;
: variable-cf   ( -- )     dovariable    place-cf  ;
: user-cf       ( -- )     douser        place-cf  ;
: value-cf      ( -- )     dovalue       place-cf  ;
: constant-cf   ( -- )     doconstant    place-cf  ;
: defer-cf      ( -- )     dodefer       place-cf  ;
: 2constant-cf  ( -- )     do2constant   place-cf  ;

: colon-cf?     ( adr -- flag )  word-type docolon origin+ =  ;
: create-cf?    ( adr -- flag )  word-type docreate origin+ =  ;

\ place a branch+link to target at adr
: put-does-cf   ( target -- )
   \ also assembler " mov x0,lr" evaluate previous
   0xaa1e03e0 instruction,    \  mov x0,lr
   here - build-bl-opcode  instruction,
;
: place-does    ( -- )     dodoesaddr l@ origin + put-does-cf ;

[else] \ not itc

: >code  ( acf-of-code-word -- address-of-start-of-machine-code )  4 +  ;

: code?  ( acf -- f )  \ True if the acf is for a code word
   \   dup word-type =
   l@ h# 9100.03ff n->l =
;

\ place a branch+link to target at adr
: put-cf   ( target adr -- )
   dup >r - build-bl-opcode
   r> instruction!
;

\ a colon-magic doesn't exist in this ARM64 version
: place-cf      ( adr -- )
   acf-align
   here - build-bl-opcode
   instruction,
;

: push-pfa  ( -- adr )
   align
   aa1e03c0  instruction,   \ mov x0,lr  (orr x0, lr, lr)
;

: code-cf  ( -- )   acf-align  h# 910003ff ( add xsp,xsp,#0 ) instruction,  ;

: docolon       ( -- adr ) docolon      origin+ ;
: colon-cf      ( -- )     docolon      place-cf  ;
: colon-cf?     ( adr -- flag )  word-type docolon =  ;

: create-cf     ( -- )     docreate     origin+  place-cf  ;
: create-cf?    ( adr -- flag )  word-type  docreate origin +  =  ;

: label-cf      ( -- )     dolabel      origin+  place-cf  ;
: variable-cf   ( -- )     dovariable   origin+  place-cf  ;
: user-cf       ( -- )     douser       origin+  place-cf  ;
: value-cf      ( -- )     dovalue      origin+  place-cf  ;
: constant-cf   ( -- )     doconstant   origin+  place-cf  ;
: defer-cf      ( -- )     dodefer      origin+  place-cf  ;
: 2constant-cf  ( -- )     do2constant  origin+  place-cf  ;
: place-does    ( -- )     push-pfa     dodoesaddr token@ place-cf ;

[then] \ itc

\ Ip is assumed to point to (;code .  flag is true if
\ the code at ip is a does> clause as opposed to a ;code clause.

\ decide between does> and ;code
: does-ip?  ( ip -- ip' flag )
   dup token@ ['] (does>) =  if  ta1+ aligned na1+ true  else  ta1+ false  then
;

: place-;code  ( -- )  ;

\ XXX this needs to be in the assembler
\ Version for next in user area
: next  ( -- )  h# d61f0300 instruction,  ;  ( br up )

\ New: : pointer-cf  ( -- )  dopointer  literal origin+  place-cf  ;
\ New: : buffer-cf   ( -- )  dobuffer   literal origin+  place-cf  ;

\ uses  sets the code field of the indicated word so that
\ it will execute the code at action-clause-adr
: uses  ( action-clause-adr xt -- )  put-cf  ;

\ used  sets the code field of the most-recently-defined word so that
\ it executes the code at action-clause-adr
: used  ( action-clause-adr -- )  lastacf  uses  ;

/token constant /token

\ tokens are 32-bit offsets from origin
code token@  ( adr -- cfa )
   ldr   wtos, [tos]
   add   tos, tos, org
c;

code token!  ( cfa adr -- )
   pop   x0, sp
   sub   x0, x0, org
   str   w0, [tos]
   pop   tos, sp
c;

: token,  ( cfa -- )      here  /token allot  token!  ;

\ operators using addresses, links and tokens
\ Wrong: common code uses a@ for dictionary links
\ and it appears not be to used elsewhere
\ so we can use a@ for 32-bit offsets from origin
\ ... but I don't have to like it.
/l constant /a
: a@  ( adr -- adr )  token@  ;
: a!  ( adr adr -- )  token!  ;
: a,  ( adr -- )      here  /a allot    a!  ;

/l constant /branch

\ forth branches use 32-bit signed offsets
: branch,  ( offset -- )         l,  ;
: branch!  ( offset where -- )   l!  ;
: branch@  ( where -- offset )   <l@  ;
: >target  ( ip -- target )  ta1+ dup branch@ +  ;

: null  ( -- token )  origin  ;
: !null-link   ( adr -- )  null swap link!  ;
: !null-token  ( adr -- )  null swap token!  ;
1 [IF]
: non-null?  ( link -- false | link true )
   dup null =  if  drop false  else  true  then
;
[else]
   \ Sheesh.  The following code apparently doesn't do what the code above does.
code non-null?  ( link -- false | link true )
   mov    x1,tos         \ Cache link
   cmp    tos,org
   mov    tos,xzr        \ Assume tos = FALSE
   0<> if
      push  x1,sp
      sub   tos,tos,#1   \ Make tos = TRUE
   then
c;
[THEN]
: get-token?     ( adr -- false | acf  true )  token@ non-null?  ;
: another-link?  ( adr -- false | link true )  link@  non-null?  ;

: ip>token  ( ip -- token-adr )  /token -  ;

only forth also labels also meta
also assembler helpers also assembler definitions
:-h 'body#   ( "name" -- variable-apf )
   [ also meta ]-h  '  ( acf-of-user-variable )  >body-t
   [ previous  ]-h
;-h
:-h 'code   ( "name" -- code-word-acf )
   [ also meta ]-h  '  ( acf-of-user-variable )
   [ previous  ]-h
;-h
:-h 'user#  ( "name" -- user# )
\  [ also meta ]-h  '  ( acf-of-user-variable )  >body-t @-t ( d ) drop ( n )
   [ also meta ]-h  '  ( acf-of-user-variable )  >body-t l@-t ( n )
   [ previous  ]-h
;-h
\ 'user is intended to be used with ldr/str instruction.
\ However, for completeness, this code should verify that the instruction it's
\ modifying really is the ldr or str instruction; else the result could take a
\ while to identify and fix.
:-h 'user  ( "name" -- )
   'user#  ( value )
;
:-h 'body  ( "name" -- )
   'body#  ( value )
;
only forth also labels also meta also definitions

\ =======================================
\
\        SOME HELPER FUNCTIONS
\
\ =======================================

8 equ nvocs     \ Number of slots in the search order


0 [if]    \ Break in case of emergency.
code check-xsp	( -- )
   set     x0, 0x00000008017fe000
   mov     x1, xsp
   cmp     x0, x1
   0< if
      begin again
   then
c;
[then]

[ifdef] check-stack-ordering
code check-all-stacks ( -- )
   mov     x0 , rp
   mov     x1 , sp
   mov     x2 , xsp
   cmp     x0 , x1
   0< if
      begin again
   then
   cmp     x1 , x2
   0< if
      begin again
   then
   cmp     x0 , x2
   0< if
      begin again
   then
c;
[then]  \ check-stack-ordering

\
\ Help for the assembler
\

\ hibit computes the bit # of the highest set bit in a number.
\ The possible output values are 0..63 or -1 if no bits were set.
code hibit  ( n -- n )
   clz     tos,tos
   set     x0,#63
   sub     tos,x0,tos
c;

\ count leading zeroes
code clz  ( n -- n )   clz tos,tos   c;
\ count trailing ones
code cto   ( n -- n' )
   rbit   tos,tos
   set    x0,#-1
   eor    tos,tos,x0
   clz    tos,tos
c;

\ code lshift  ( n1 cnt -- n2 )  pop x0,sp  lslv tos,x0,tos  c;
code mask  ( width -- mask )
   cmp   tos,#64
   = if
      set tos,#-1
      next
   then
   set   x0,#1
   lslv  tos,x0,tos
   sub   tos,tos,#1
c;
