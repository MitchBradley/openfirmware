\ Conditionals

\ =======================================
\
\    Conditional Select
\
\ =======================================

: cond  ( -- cond )  4 uimm  ;

\ Flipping the low order bit of the condition code inverts its sense.
\ In A64, unlike A32, always (e) and never (f) are synonymous(!) so
\ inverting the sense of AL is a noop since AL == NV.
: -cond  ( cond -- !cond )  1 xor  ;

: %cond-select0   ( op regs -- )
   <asm  d=n=m,  rd??iop  set-sf?  cond 12 4 ^^op  asm>
;
: %cond-select1   ( op regs -- )
   <asm  d=n,  <rn> ^rm  rd??iop  set-sf?  cond -cond 12 4 ^^op  asm>
;
: %cond-select2   ( op regs -- )
   <asm  rd,  rd??iop  set-sf?  cond -cond 12 4 ^^op  asm>
;

\ =======================================
\
\    Conditional Comparison
\
\ =======================================


: %cond-compare  ( op -- )
   <asm  iop
   wxn, #? if
      #uimm5, ^rm  0x0800 iop
   else
      wxm,
   then
   #uimm4, ^rd
   cond  12 4 ^^op
   xn? if  set-sf  then
   asm>
;


\ =======================================
\
\    Forth-like flow-control for the assembler
\
\ =======================================

: brif  ( target cond -- )  swap  here >br-offset or h# 5400.0000 or  asm,  ;

\
\ In the words below, we keep the >mark on the stack to be used by the error handler.
\ As of now, it hasn't been applied.  But that can be done without restructuring the code that
\ computes the offset
\

: -1or0  ( n -- f )   -1 0 between invert  ;

: >resolve-delta  ( >mark #bits -- n-bit-offset )
   over here swap -         ( >mark  #bits  delta )  \ Convert a target into an offset
   2dup swap >>a 
   -1or0 if ." ERROR: relative address out of range" abort then
   2 >>a swap mask and    ( >mark  n-bit-offset )
   nip                      \ Remove the >mark
;

: >resolve-adr-delta  ( >mark -- n-bit-offset )
   here over -              ( >mark  delta )  \ Convert a target into an offset
   dup 21 >>a 
   -1or0 if ." ERROR: relative address for adr out of range" abort then
   nip                      \ Remove the >mark
;

: >resolve-adrp-delta  ( >mark -- n-bit-offset )
   here 12 mask andc   \ Convert the current address to a page #
   over 12 mask andc   \ Convert the target address to a page #
   -                        ( >mark  delta-in-pages )
   12 >>a                \ Throw away the 12 zeros created above
   dup 21 >>a            \ The page # is 21 bits
   -1or0 if ." ERROR: relative address for adrp out of range" abort then
   nip                      \ Remove the >mark
;

: rotate-adr-delta    ( delta -- rotated )
   21 mask and         \ Only 21 bits represented in adr/adrp
   dup 3 and 29 <<     \ Move the lo order two bits into bits 29,30
   swap 2 >>                \ Finished with the lo order, work on the hi order
   19 mask and 5 <<    \ Move the hi order 19 bits into bits 5-23
   or
;

: >resolve-asm!    ( >mark instr delta -- )  or swap asm!  ;
: >resolve-5<<     ( >mark instr delta -- )  5 <<  >resolve-asm!  ;

: >resolve-ldr     ( >mark instr delta -- )  >resolve-5<<  ;
: >resolve-ldrsw   ( >mark instr delta -- )  >resolve-5<<  ;
: >resolve-b.cond  ( >mark instr delta -- )  >resolve-5<<  ;
: >resolve-cbz     ( >mark instr delta -- )  >resolve-5<<  ;
: >resolve-tbz     ( >mark instr delta -- )  >resolve-5<<  ;

: >resolve-b       ( >mark instr delta -- )  >resolve-asm!  ;

: >resolve-adr     ( >mark instr >mark -- )  >resolve-adr-delta  rotate-adr-delta  >resolve-asm!  ;
: >resolve-adrp    ( >mark instr >mark -- )  >resolve-adrp-delta rotate-adr-delta  >resolve-asm!  ;


: ,,,,   ( mask match #bits word )
   >r  rot ( mask ) l,
   swap ( match ) l,
   ( #bits ) l,
   r> token,
;

hex
create >resolve-table
   FF00.0010  5400.0000   d# 19  ' >resolve-b.cond  ,,,,
   3B00.0000  1800.0000   d# 19  ' >resolve-ldr     ,,,,
   FF00.0000  9800.0000   d# 19  ' >resolve-ldrsw   ,,,,
   7C00.0000  1400.0000   d# 26  ' >resolve-b       ,,,,  \ Including bl
   9F00.0000  1000.0000   d#  0  ' >resolve-adr     ,,,,  \ NOTE: instr-addr is passed, not delta
   9F00.0000  9000.0000   d#  0  ' >resolve-adrp    ,,,,  \ NOTE: instr-addr is passed, not delta
   7E00.0000  3400.0000   d# 19  ' >resolve-cbz     ,,,,  \ Including cbnz
   7E00.0000  3600.0000   d# 14  ' >resolve-tbz     ,,,,  \ Including tbnz
   0 ,
decimal

vocab-assembler

\ These implementation factors are used by the local labels package
\ in forth/lib/loclabel.fth
: <mark  ( -- <mark )  here  ;
: >mark  ( -- >mark )  here  ;
: <resolve  ( <mark -- <mark )  ;
: >resolve  ( >mark -- )
   dup asm@                              \ Fetch the instruction to be fixed up
   >resolve-table                        \ Table address
   begin
      over over l@  and over 1 la+ l@ =
      if
         2 pick over 2 la+ l@             ( >mark  instr  >resolve-table  >mark  #bits )
         ?dup if >resolve-delta then      ( >mark  instr  >resolve-table  [ delta | >mark ] )
         swap 3 la+ token@ execute exit
      then
   4 la+ dup @ 0=
   until  drop                             ( >mark  instr )
   ." ERROR: >resolve called for an incorrect instruction:"
   swap ." addr = " .h  ." , instr = " .h
   ." line# " source-id file-line .d cr abort
;

vocab-helpers

\ // ConditionPassed()
\ // =================
\ boolean ConditionPassed()
\         cond = CurrentCond();
\         // Evaluate base condition.
\         case cond<3:0> of
\         when ‘000x’ result = (APSR.Z == ‘1’);                        // EQ or NE
\         when ‘001x’ result = (APSR.C == ‘1’);                        // CS or CC
\         when ‘010x’ result = (APSR.N == ‘1’);                        // MI or PL
\         when ‘011x’ result = (APSR.V == ‘1’);                        // VS or VC
\         when ‘100x’ result = (APSR.C == ‘1’) && (APSR.Z == ‘0’);     // HI or LS
\         when ‘101x’ result = (APSR.N == APSR.V);                     // GE or LT
\         when ‘110x’ result = (APSR.N == APSR.V) && (APSR.Z == ‘0’);  // GT or LE
\         when ‘111x’ result = TRUE;                                   // AL
\ 
\         // Condition bits ‘111x’ indicate the instruction is
\         // always executed. Otherwise, invert condition if necessary.
\         if cond<0> == ‘1’ && cond != ‘1111’ then
\            result = !result;
\ 
\         return result;

: cond2:  ( n1 "name" "name" -- )  dup constant  1 xor constant ;
: cond4:  ( n1 "name" "name" "name" "name" -- )   dup cond2: cond2:  ;

: (=if)   ( reg# reg-adt opcode -- >mark )
   is opcode
   drop set-sf?  ^rd
   >mark
   opcode asm,
; 
: (=until)   ( <mark reg# reg-adt opcode -- )
   is opcode
   drop set-sf?   ^rd   ( <mark )
   19 ?aligned-branch   ( simm19 )
   5 19 ^^op
   opcode asm,
; 

