\ Structured Conditionals

\
\ This section is left to last because it defines some assembler words
\ which conflict with normal Forth words, such as  =  <>  0=  
\ These assembler versions enable us to use structured conditionals
\ such as  if ... then  within assembly code.

binary
0000 cond4:  =     <>       EQ  NE
0000 cond4: 0=    0<>       Z   NZ
0010 cond4: u>=   u<        CS  CC
0010 cond2:                 HS  LO   \ Same as CS CC, respectively
0100 cond4: 0<    0>=       MI  PL
0110 cond4: vs    vc        VS  VC
1000 cond4: u>    u<=       HI  LS
1010 cond4:  >=    <        GE  LT
1100 cond4:  >     <=       GT  LE
1100 cond4: 0>    0<=       GT  LE
1110 cond4: always never    AL  NV  \ Note, never and NV mean always.  Really.  Sigh.
\ same effect but physically different opcodes
\ 1110 cond2: always  AL 
\ 1111 cond2: never  NV 
decimal

\    Forth      Traditional ASM        Extra        Cond #
  =  B: B.=        =  B: B.eq        = B: B.z    \  0000
 <>  B: B.<>      <>  B: B.ne       <> B: B.nz   \  0001
u>=  B: B.u>=    u>=  B: B.cs      u>= B: B.hs   \  0010
u<   B: B.u<      u<  B: B.cc       u< B: B.lo   \  0011
0<   B: B.0<      0<  B: B.mi                    \  0100
0>=  B: B.0>=    0>=  B: B.pl                    \  0101
vs   B: B.vs      vc  B: B.vc                    \  011x
u>   B: B.u>      u>  B: B.hi                    \  1000
u<=  B: B.u<=    u<=  B: B.ls                    \  1001
 >=  B: B.>=      >=  B: B.ge                    \  1010
  <  B: B.<        <  B: B.lt                    \  1011
  >  B: B.>        >  B: B.gt                    \  1100
 <=  B: B.<=      <=  B: B.le                    \  1101
\ always B: B.al   always B: B.nv                  \  111x, Yes: nv means Always.
always B: B.al   never B: B.nv                   \ same effect but physically different opcodes 


\ =======================================
\
\    Standard Forth assembly level conditional words
\
\ =======================================


: but     ( mark1 mark2 -- mark2 mark1 )  swap  ;
: yet     ( mark -- mark mark )  dup  ;

: ahead   ( -- >mark )          >mark  here always brif  ;
: if      ( cond -- >mark )     >mark  here rot -cond  brif  ;
: then    ( >mark -- )          >resolve  ;
: else    ( >mark -- >mark1 )   ahead  but then  ;
: begin   ( -- <mark )          <mark  ;
: until   ( <mark cond -- )      -cond brif ;
: again   ( <mark -- )          always brif  ;
: repeat  ( >mark <mark -- )    again  then  ;
: while   ( <mark cond -- >mark <mark )  if  but  ;

\ =======================================
\
\    support for using CBZ CBNZ in structured conditionals
\
\ =======================================

: 0=if     ( reg# reg-adt -- >mark )   0x3500.0000 (=if)  ;
: 0<>if    ( reg# reg-adt -- >mark )   0x3400.0000 (=if)  ;

: 0=while   ( <mark reg# reg-adt -- >mark <mark )  0=if   but  ;
: 0<>while  ( <mark reg# reg-adt -- >mark <mark )  0<>if  but  ;

: 0=until   ( <mark reg# reg-adt -- )   0x3500.0000 (=until)  ;
: 0<>until  ( <mark reg# reg-adt -- )   0x3400.0000 (=until)  ;
