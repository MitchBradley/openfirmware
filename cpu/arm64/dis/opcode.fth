
variable instruction

: instruction@ instruction l@ ;
: instruction! instruction l! ;

\ : +offset  ( adr -- adr' )  display-offset @  -  ;
: bits  ( right-bit #bits -- field )
   instruction@ rot >>   ( #bits shifted-instruction )
   swap mask  and         ( field )
;
: sext  ( bits #bits -- n )   8 cells swap -  dup >r  <<  r> >>a  ;
: sxbits  ( right-bit #bits -- field )
   over + 8 cells swap - >r      \ #bits to shift left
   instruction@ r@ <<  \ Shift bit field up to the top
   swap r> + >>a
;

: 1bit     ( right-bit -- field )   1 bits  ;
: 2bits    ( right-bit -- field )   2 bits  ;
: 3bits    ( right-bit -- field )   3 bits  ;
: 4bits    ( right-bit -- field )   4 bits  ;
: 5bits    ( right-bit -- field )   5 bits  ;
: 6bits    ( right-bit -- field )   6 bits  ;
: 7bits    ( right-bit -- field )   7 bits  ;
: 8bits    ( right-bit -- field )   8 bits  ;
: 9bits    ( right-bit -- field )   9 bits  ;
: 12bits   ( right-bit -- field )  12 bits  ;
: 16bits   ( right-bit -- field )  16 bits  ;

: 14sbits  ( right-bit -- field )  14 sxbits  ;
: 19sbits  ( right-bit -- field )  19 sxbits  ;
: 26sbits  ( right-bit -- field )  26 sxbits  ;

: bit?  ( bit# -- f )  instruction@ swap rshift 1 and  0<>  ;


\ =======================================
\
\       CHARACTER PRINT ROUTINES
\
\ =======================================

: .,  ( -- )  ." , "  ;
: .[  ( -- )  ." ["  ;
: .]  ( -- )  ." ]"  ;
: .{  ( -- )  ." {"  ;
: .}  ( -- )  ." }"  ;
: .#  ( -- )  ."  #"  ;
: .!  ( -- )  ." !"  ;
: emit.  ( -- )  [char] . emit  ;
: emit,  ( -- )  [char] , emit  ;


: udis.32 ( n -- )
   push-hex
   <#
   u# u# u# u# u# u# u# u#
   u#>  type   pop-base
;
: udis.64 ( n -- )
   push-hex
   <#
   u# u# u# u# u# u# u# u# ( [char] _ hold )  u# u# u# u# u# u# u# u#
   u#>  type   pop-base
;
' udis.64  is showaddr

\ Extracts an index from the field "bit# #bits", indexes into the string
\ "adr len", which is assumed to contain substrings of length /entry,
\ and types the indexed substring.
: .txt  ( index adr len /entry --  )
   >r  drop  swap r@ * +  r>  type
;
: .fld  ( bit# #bits adr len /entry -- )
   >r drop  >r            ( bit# #bits r: /entry adr )
   bits                   ( index r: /entry adr )
   r> swap r@ * +  r>     ( adr' /entry )
   type
;

\ Display formatting
variable start-column
: op-col   ( -- )  start-column @  8 +  to-column  ;
: rem-col  ( -- )  start-column @  20 +  to-column  ." \ " ;

: unimpl   ( -- )   ." ,"  op-col  ." \ Instruction decode not implemented"  ;
: illegal  ( -- )   ." ,"  op-col  ." \ Illegal instruction"  ;

: invalid-op     ." invalid opcode "  ;
: invalid-regs   ." invalid registers "  ;
: ?invalid-op   ( error? -- )   if   invalid-op  then  ;
: ?invalid   ( error? -- )   if  ." invalid format "  then  ;


: immr   ( -- n )  16 6bits  ;
: imms   ( -- n )  10 6bits  ;
: imm12  ( -- n )  10 12bits ;
: simm7  ( -- n )  15 7 sxbits ;
: simm9  ( -- n )  12 9 sxbits ;
: op1    ( -- n )  16 3bits ;
: crn    ( -- n )  12 4bits ;
: crm    ( -- n )   8 4bits ;
: op2    ( -- n )   5 3bits ;
: sz     ( -- n )  22 2bits ;

defer .imm
: (.imm)  ( n -- )  ." #" push-decimal (.) type pop-base ;
' (.imm) is .imm
: .imm, ( n -- )  .imm ., ;

: .uimm  ( n -- )  ." #" push-decimal (u.) type pop-base ;

\ remove trailing zeros
: -trailing0 ( f -- f )
   dup 0<> if
      begin  dup dup 10 / 10 * =  while  10 /  repeat
   then
   ;

: .#i.f ( s i f -- )
   swap rot 0= if
      case
         0 of  ." #0."  endof
         1 of  ." #1."  endof
         2 of  ." #2."  endof
         3 of  ." #3."  endof
         4 of  ." #4."  endof
         5 of  ." #5."  endof
         6 of  ." #6."  endof
         7 of  ." #7."  endof
         8 of  ." #8."  endof
         9 of  ." #9."  endof
         10 of  ." #10."  endof
         11 of  ." #11."  endof
         12 of  ." #12."  endof
         13 of  ." #13."  endof
         14 of  ." #14."  endof
         15 of  ." #15."  endof
         16 of  ." #16."  endof
         17 of  ." #17."  endof
         18 of  ." #18."  endof
         19 of  ." #19."  endof
         20 of  ." #20."  endof
         21 of  ." #21."  endof
         22 of  ." #22."  endof
         23 of  ." #23."  endof
         24 of  ." #24."  endof
         25 of  ." #25."  endof
         26 of  ." #26."  endof
         27 of  ." #27."  endof
         28 of  ." #28."  endof
         29 of  ." #29."  endof
         30 of  ." #30."  endof
         31 of  ." #31."  endof
      endcase
   else
      case
         0 of  ." #-0."  endof
         1 of  ." #-1."  endof
         2 of  ." #-2."  endof
         3 of  ." #-3."  endof
         4 of  ." #-4."  endof
         5 of  ." #-5."  endof
         6 of  ." #-6."  endof
         7 of  ." #-7."  endof
         8 of  ." #-8."  endof
         9 of  ." #-9."  endof
         10 of  ." #-10."  endof
         11 of  ." #-11."  endof
         12 of  ." #-12."  endof
         13 of  ." #-13."  endof
         14 of  ." #-14."  endof
         15 of  ." #-15."  endof
         16 of  ." #-16."  endof
         17 of  ." #-17."  endof
         18 of  ." #-18."  endof
         19 of  ." #-19."  endof
         20 of  ." #-20."  endof
         21 of  ." #-21."  endof
         22 of  ." #-22."  endof
         23 of  ." #-23."  endof
         24 of  ." #-24."  endof
         25 of  ." #-25."  endof
         26 of  ." #-26."  endof
         27 of  ." #-27."  endof
         28 of  ." #-28."  endof
         29 of  ." #-29."  endof
         30 of  ." #-30."  endof
         31 of  ." #-31."  endof
      endcase
   then
   .
;
: r2exp ( r - exp )   4 - dup 0 < if 8 + then ;

: .fimm8 ( n -- )
   dup dup 0x71 = swap 0xf1 = or if
      0x71 = if  ." #1.0625" else ." #-1.0625" then         \ only i.fimm8 value of fraction with lead zeros
      exit
   then

   push-decimal
   dup 1 7 << and swap
   dup 0xf and 16 + 10000000 * 16 / swap 4 >> 7 and
   r2exp
   dup 3 >= if
      3 - 1 swap << *
   else
      3 swap - 1 swap << /
   then
   dup 10000000 / dup -rot
   dup 0<> if  10000000 *  then -
   -trailing0 ( s i f ) .#i.f
   pop-base
;

: .fimm8_all ( -- )
   ." Conforming floating point numbers (minus too) : " cr
   16 0 DO
      8 0 DO
         j i 4 << or .fimm8 9 emit
      LOOP
      cr
   LOOP
;
