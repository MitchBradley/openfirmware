\ try blocks

\ This code implements a try/fail/try-next model.
\ Many instructions use try blocks to support multiple argument formats.
\ ie we try each possibility until one doesn't fail

\ Basically, the model is set up so that at the highest level
\ a call is made to start the try-block (see try).
\ Then, the code immediately following the call to 'try' will be
\ called repeatedly with different indexes.  With each different index
\ the code is free implement a try.  If that try fails, then it should
\ call abort-try without printing anything.  If the try succeeds it
\ simply returns to the caller (without any stack affects).

0 value try-active
0 value try-max-index

\ abort-try  This word should be called from within the try block
\ if the try failed.  Else, the try block should simply return (e.g., with
\ 'exit' or ';') like any other word.  Or, it can call accept-try, see next.

: (abort-try)   ( -- )  try-active if   1 throw   then  ;
' (abort-try)  is abort-try

\ next-try  This word should be called from within a try block if the
\ try failed but if the reason for the try failure should not be recorded.
\ Specifically, this word is used when looking for an ! in the input stream
\ to indicate a pre-indexed addressing mode.

: (next-try)    ( -- )  try-active if   2 throw   then  ;
' (next-try)   is next-try

\ try-one  This word will call back to the (and clean up from) caller
\ of the try block.  Note that the return code from the try attempt
\ is returned to the try loop.  But, one should simply use TRUE (to
\ indicate failure).  FALSE, which indicates success, is automatically
\ returned to the try loop if the try attempt did not abort.

: try-one  ( adr idx -- n )
   start-instr
   swap ['] execute-ip catch ( err# ) dup if nip nip then
;

\ setup-try-block  This word is called before any any of the try-one calls
\ are issued.  This is a good place to initialize the system or any global
\ variables for successive tries.

: setup-try-block ( -- )
   1 is try-active
   0 is try-max-index
   <asm
;

\ failed-try-block  This word is called if none of the tries were successful.
\ One should clean up any state that was altered during setup-try-block here.

: failed-try-block ( word-list-ip -- )
   0 is try-active
   start-instr
   ( word-list-ip ) try-max-index swap execute-ip
   \ asmtry? @ if  abort  then   \ let tryall catch it
;

\ accepted-try  This word is called from within the try-block if a try returned
\ without calling abort-try.  This word will also need to clean up any system
\ state modified by setup-try-block because upon returning from here the try-block
\ will simply exit.

: accepted-try  ( word-list-ip i -- )
   2drop
   0 is try-active
   asm>           \ finish the instruction
;

\ failed-try  This word is called from within the try-block after a try called
\ abort-try.  This word does not need to do any state clean up but may want to
\ record some information about this try.  For one thing, if none of the tries
\ are successful then there might be some indication in one of the failures
\ that stands out to be passed back up to the user.

: failed-try  ( word-list-ip i -- )
   ( i ) is try-max-index
   ( word-list-ip ) drop
;

\ try:  This is the main entry point to the try-block.  This word will call several
\ handlers: setup-try-block, try-one {multiple times}, accepted-try, failed-try,
\ and/or failed-try-block.  Note that accepted-try may never be called if all tries
\ call abort-try.  Also, failed-try may never be called if the first try succeeded.
\ And, failed-try-block may never be called if any try succeeds.

0 value try-ip-adr
: try:  ( [dval|ival] terminal-idx  start-idx -- )
   r> is try-ip-adr
   2>r  setup-try-block  2r>  ( terminal-idx  start-idx )  do
       try-ip-adr i try-one case
         0  of  try-ip-adr i unloop accepted-try exit endof
        -1  of  try-ip-adr i unloop accepted-try exit endof
         1  of  try-ip-adr i        failed-try        endof
         2  of  ( Do nothing, just try the next idx ) endof
      endcase
   loop
   try-ip-adr failed-try-block
;
