\ Parsing

\ The rules on parsing are as follows:
\  1) We copy the systems input buffer to a local buffer
\     so that we can step through assembler words without
\     the input buffer becoming corrupt because of our
\     typing at the console during the debug session.
\  2) Further, we copy the input buffer's >in value at the
\     beginning of parsing a line to two locations:
\     +  An index used for parsing the line
\     +  A copy at the start used for rewinding within
\        try blocks.
\  3) One last note about the >in value: the algorithm
\     goes backward to find either the start of the line
\     or the most recent blank in an attempt to include
\     the name of the arm64 assembly language instruction
\     into the character buffer so that during error messages
\     the full text should make it easier for users of
\     the assembler to know exactly which instruction generates
\     an error.
\  4) Forth parsing of the input buffer.  There are two cases
\     where the assembler calls back to Forth and arbitrary
\     code may parse the input stream.  In one case is the
\     register lookup code, see reg.  And the other is in
\     immediate value handling.  However, these cases may
\     extend to user variables, too.  Right now user variables
\     are a bit clunky:   ldr  X0, [UP, 'user some-var].
\     OK, but the preferred syntax is:  ldr X0, 'user some-var.
\     In order for that to work we need to allow arbitrary
\     execution of code after "X0,".  And, for that to work,
\     the word 'user must be able to parse (and execute!) the
\     the next word some-var.  In order for it to parse that
\     word using the standard Forth parsing techniques, the
\     Forth code " source >in @ /string " needs to point
\     to the character just beyond 'user.  Well, that's what
\     I've done here is to allow just that.
\
\     The way that >in is updated is rather tricky but basically
\     we increment >in by the number of characters we've parsed
\     since we took the input stream from the Forth parser.  Then,
\     upon return from the executed word, we then update our internal
\     parse pointer by the number of characters that the arbitrary
\     code parsed.

\ point to start of cbuf
: rewind ( -- )   
   0 is cin
   0 is mark-start
;

\ copy a line of input text to cbuf
: copyln ( -- )
   source >in @ /string       ( a n )
   /tib min dup is clen      \ Can't copy more than buf sz
   cbuf swap cmove            ( )
   rewind
;

\ Signal to the input source that so many characters have been parsed.
: readln ( -- )   cin >in +!  ;

\
\ Character scanning words
\

\ <c  begin a character scan process.  It skips white space then
\ pushes the string to the rest of the input line.
: <c  ( -- $ )
   cbuf clen  cin /string
   skipwhite
   over cbuf - is mark-start
;

\ c>  terminate a char scan process.  Pop the string
\     of the rest of the input line.
: c>  ( $ -- )
   over +  cbuf clen +  <> " input string became corrupted" ?error
   ( cadr ) cbuf - is cin
;

\ <c>   Fetch one char out of the input stream after scanning past white space.
: <c>   ( -- c )   <c 2dup if c@ else drop 0 then  -rot 1 /string c> ;

\ <@c>  Skip white space and then push a copy of the next char of the input.
: <@c>  ( -- c )  <c if c@ else drop 0 then ;

\ >c    Return a char back into the input stream.
\       This gets used, for example, when optionally parsing a # symbol
\       (which yanks the # symbol out of the input stream) and then calling
\       imm which requires the # symbol be in the input stream.
: >c    ( -- )  cbuf clen  cin 1- /string  c>  ;


\
\ scanto  These words will scan the input stream for one or more characters.
\

: scanto$  ( input$  lex$ -- scan$ rem$ )
   lex  if   ( rem$  field$  delim )      \ Add the delim back into the rem$
      drop 2swap -1 /string   ( field$ rem$ )
   else      ( field$ )
      2dup + 0                ( field$ rem$ )
   then
;
\ "t is a tab
: scantodelim ( $ -- scan$ rem$ )  " "t!#,[]{}()` " scanto$  ;
\ : scantobl    ( $ -- scan$ rem$ )  "  "           scanto$  ;
: scantobl    ( $ -- scan$ rem$ )   bl split-string  ;
: execute-inline  ( -- ?? )
   <c  " `" lex  if           ( rem$ field$ delim )      \ Delimiter was found; handle field and exit
      drop  2swap c>          ( field$ )
      depth >r                                   ( r: x+2 )
      evaluate                ( immediate )
      r> depth                ( immediate x+2 x+2 )
      - dup                   ( immediate depthchange depthchange )
      0> " stack underflow " ?error
      0< " stack overflow " ?error
      ( immediate )
   else                       ( text$ )
      \ XXX should this print an error msg?
      2drop
   then
;

\ test for char without picking it up
: #?        ( c -- flag )   ascii # <@c> =  ;
: ,?        ( c -- flag )   ascii , <@c> =  ;
: [?        ( c -- flag )   ascii [ <@c> =  ;
: ]?        ( c -- flag )   ascii ] <@c> =  ;
: {?        ( c -- flag )   ascii { <@c> =  ;
: '?        ( c -- flag )   ascii ' <@c> =  ;

\ convert char to upper case
: opt-ascii  ( c -- flag )   <@c> upc = dup if  <c> drop  then ;
: ","?      ascii ,  opt-ascii ;
: "["?      ascii [  opt-ascii ;
: "]"?      ascii ]  opt-ascii ;
: "#"?      ascii #  opt-ascii ;
: "!"?      ascii !  opt-ascii ;
: "*"?      ascii *  opt-ascii ;
: "$"?      ascii $  opt-ascii ;
: "+"?      ascii +  opt-ascii ;
: "-"?      ascii -  opt-ascii ;
: "`"?      ascii `  opt-ascii ;
: "0"?      ascii 0  opt-ascii ;
: "``"?     "`"?  dup if  drop "`"?  dup 0= if  >c  then then  ;
: "L"?      ascii L  opt-ascii  ;
: "L#"?     "L"?  dup if  drop "#"?  dup 0= if  >c  then then  ;
: "X"?      ascii X  opt-ascii  ;
: "0x"?     "0"?  dup if  drop "x"?  dup 0= if  >c  then then  ;

: "##"  ( -- )  ascii # <@c> = if  <c> drop  then ;

: req-ascii   ( ascii-char$ -- )   over c@ <c> <> -rot ?expecting  ;
: ","   " ," req-ascii ;
: "["   " [" req-ascii ;
: "]"   " ]" req-ascii ;
: "{"   " {" req-ascii ;
: "}"   " }" req-ascii ;
: "#"   " #" req-ascii ;
: "!"   " !" req-ascii ;
: "0"   " 0" req-ascii ;
: "'"   " '" req-ascii ;

\
\ <!>  will look for an exclamation point in the input stream.  If it finds one it will
\ push true on the stack.  Else, it will call next-try which will abort the current
\ try attempt without saving the error condition.  However, if we're not in a try mode,
\ then a flag as to whether or not an ! was in the input stream will be pushed on the
\ stack.
\
\ This word will be used in parsing pre-indexed addressing modes to avoid the error
\ that an exclamation point was missing when another error is the cause of an abort.
\

: <!>   "!"?  0= if next-try then ;


\
\ Parsing instruction fields
\

\ NOTE: usubstring? is defined in forth/lib/strcase.fth

\ check whether the input begins with a specified string
\ and advance past it
: $match? ( $string -- true | $string false )
   2dup <c usubstring? 0= if  false exit  then
   <c  rot /string  c>
   drop true
;
\ require the input to begin with a specified string
: ?$match ( $string -- )
   $match?  0= if abort-try ." Expecting " ( $ ) ad-error then
;

\ check whether the input begins with a specified string
: $find? ( $string -- true | false )
   2dup <c usubstring? 0<> -rot 2drop
;

: $asm-find  ( word$ -- word$ false | xt true )  ['] arm64-assembler $vfind  ;

: $asm-execute  ( name$ -- ?? t | name$ f )
   $asm-find 0= if  false exit  then   ( xt )
   
   >in @ >r                      \ Save the current Forth parse index
   cin >in +!                    \ Increment by the number of chars asm64 parsed
   execute
   >in @  cin r@ + -             \ Calculate the number of chars parsed by 
                                 \ the word we just executed.
   cin + is cin                  \ Absorb into asm64's parser
   r> >in !                      \ Restore the Forth parse index
   true
;

