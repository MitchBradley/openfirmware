\ opcode construction

decimal

\ opcode is set to 0 when starting to build an instruction.
\ operations set bits, but never clear them. (any exceptions? why?)

0 value opcode

: iop  ( on-bits -- )      opcode or  is opcode  ;
: ^op  ( n bit# -- )       lshift iop ;


: #uimm-check ( n #bits -- n )
   2dup mask andc  if   ( n #bits )
      abort-try  ." #uimm expected a " .d " bit value" ad-error
   then  drop
;
\ this versions checks to see if value fits field
: ^^op ( n bit# #bits -- ) rot swap #uimm-check swap ^op ;
\ replace with a check for trying to change fixed bits


\ shift bits for each register into place
: ^r   ( n bit# -- )      5 ^^op ;   \ all are 5-bit numbers
: ^rd  ( n -- )             0 ^r ;
: ^rn  ( n -- )             5 ^r ;
: ^ra  ( n -- )            10 ^r ;
: ^rm  ( n -- )            16 ^r ;

\ ARM uses aliases for some registers in a few instructions for no apparent reason.
\ There is no reason for the assembler internals to use these aliases.
\ alias ^rt   ^rd

\ shift bits for common immediate fields into place
: ^immr5   ( n -- )   16  5  ^^op ;
: ^imms5   ( n -- )   10  5  ^^op ;
: ^immr6   ( n -- )   16  6  ^^op ;
: ^imms6   ( n -- )   10  6  ^^op ;


\ get the current value of a field
: <r>   ( bit# -- r )  opcode swap rshift 31 and ;
: <rd>   ( -- n )    0 <r> ;
: <rn>   ( -- n )    5 <r> ;
: <ra>   ( -- n )   10 <r> ;
: <rm>   ( -- n )   16 <r> ;
: <immr>  ( -- n )  opcode 16 rshift 63 and ;
: <imms>  ( -- n )  opcode 10 rshift 63 and ;

alias <rt>   <rd>
alias <rt2>  <ra>


\ =======================================
\
\    support for passing literal immediates
\    e.g.   12345    set x0,*
\
\    this makes the code more complicated, but is sometimes useful
\
\ =======================================

0 value ival
0 value ival-valid
0 value ival-consumed

2variable dval
0 value dval-valid
0 value dval-consumed

: ival@   ( -- n )
   ival-valid 0= " an immediate value on the data stack" ?expecting
   ival-consumed abort" ival already consumed "
   true is ival-consumed
   ival
;


: start-instr   ( -- )
   0 is opcode
   adt-empty is rd-adt
   adt-empty is rn-adt
   adt-empty is rm-adt
   adt-empty is ra-adt
   rewind
;
: end-instr   ( -- )   opcode asm,  ;

string: warning$

\ begin assembling an instruction
: <asm   ( -- )    \ or ( ival -- ival )  or ( dval -- dval )
   copyln  start-instr
   depth 1 >=  dup is ival-valid  if  dup  is ival  then  
   depth 2 >=  dup is dval-valid  if  2dup dval 2!  then
   false is ival-consumed
   false is dval-consumed
   " " warning$ $place
;
\ <asm treats the top two items on the stack as ival and dval
\ so to pass opcode and regmask to a word that contains <asm
\ we need to move them aside while <asm picks up ival and dval
\ note: only needed with instructions that can take an immediate argument
: <asm#   ( op regs -- op regs )   2>r  <asm  2r>  ;

:  asm]   ( -- )
   ival-consumed if  drop then
   dval-consumed if 2drop then
   warning$  string$  ?dup  if  ." WARNING: " type cr  .where  else  drop  then
   readln
;
\ finish assembling an instruction, and append the result to the dictionary
:  asm>   ( -- )   asm]  end-instr  ;


