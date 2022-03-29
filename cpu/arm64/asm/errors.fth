\ Error handling

\ Try block hooks, see try.fth
defer abort-try  ' noop is abort-try
defer next-try   ' noop is next-try


\ Use abort" for internal errors.  Else, use the following routines
\ which know how to handle retry logic properly.

\ NOTE: All of the error routines that begin with a question mark
\ terminate if true.

: ws? ( c -- f )  dup bl =  swap  9 =  or  ;

: .where
   where #out @ >r
   0    \ Count the number of spaces to prepend to the ^^s below the error/warning
   source >in @ /string       ( n a n )  \ First n is number of spaces, then a n are the string

   \ Backup to the next non-space character
   begin                      ( n a n )
      over source drop <> if  ( n a n )
         over 1- c@  ws?  if  ( n a n )
            -1 /string        ( n a n )
	    rot 1+ -rot       ( n a n )
            false  \ Continue at the until statement
         else  true  then
      else  true  then
   ( flag ) until
                              ( n a n )
   \ Backup to the next space character or beginning of the line
   begin                      ( n a n )
      over source drop <> if  ( n a n )
         over 1- c@  ws? 0=  if
            -1 /string        ( n a n )
	    rot 1+ -rot       ( n a n )
            false  \ Continue at the until statement
         else  true  then
      else  true  then
   ( flag ) until

   type cr                             ( n )
   spaces                              ( - )
   cin mark-start dup r> + spaces      ( cin ms )
   2dup < if  2drop 1 0  then          ( end start )  \ Handle negative end start ranges
   ?do  ." ^"  loop  cr
;

: ad-error  ( msg$ -- )
   abort-try   \ If we're in a try block then abort now
   \ Type the message passed in and the contents of source
   type cr  .where   abort
;

: unimpl   ( -- )  abort-try  ." UNIMPLEMENTED" cr  abort  ;
: ?invalid-regs   ( error? -- )   if  " invalid register type " ad-error  then  ;

: expecting    ( $ -- )  abort-try ." Expecting "   ( $ ) ad-error  ;
: error        ( $ -- )  abort-try ." Error: "      ( $ ) ad-error  ;
: not-allowed  ( $ -- )  abort-try ." Not allowed " ( $ ) ad-error ;
: undefined    ( $ -- )  abort-try ." Undefined: "  ( $ ) ad-error  ;
: same-reg-type ( $ -- ) abort-try ." Registers " type "  have to be the same register type" ad-error ;

: ?expecting   ( flag msg$ -- )  rot  if  ( $ ) expecting     else  2drop  then  ;
: ?error       ( flag msg$ -- )  rot  if  ( $ ) error         else  2drop  then  ;
: ?not-allowed ( flag msg$ -- )  rot  if  ( $ ) not-allowed   else  2drop  then  ;
: ?undefined   ( flag msg$ -- )  rot  if  ( $ ) undefined     else  2drop  then  ;
: ?same-reg-type ( flag msg$ -- ) rot if  ( $ ) same-reg-type else  2drop  then  ;


