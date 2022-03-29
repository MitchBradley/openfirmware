\ common number parsing for all hosts

: #simm-check ( n #bits -- n )
   over sext dup 0<  if  abs 1-  then   \ Negative numbers have more range, by 1
   over 1- mask andc  if     ( n #bits )
      abort-try  ." #simm-check Expecting a " .d " bit value" ad-error
   then                                   ( n #bits )
   mask and
;

\ =======================================
\
\         Immediate Value Parsing Words
\
\ =======================================

: uimm   ( #bits -- n )    unimm  swap #uimm-check  ;
: simm   ( #bits -- n )    snimm  swap #simm-check  ;

: #uimm   ( #bits -- n )   "##" uimm  ;
: #simm   ( #bits -- n )   "##" simm  ;

: #uimm0   ( -- n )   0 #uimm ;
: #uimm2   ( -- n )   2 #uimm ;
: #uimm3   ( -- n )   3 #uimm ;
: #uimm4   ( -- n )   4 #uimm ;
: #uimm5   ( -- n )   5 #uimm ;
: #uimm6   ( -- n )   6 #uimm ;
: #uimm7   ( -- n )   7 #uimm ;
: #uimm8   ( -- n )   8 #uimm ;
: #uimm13  ( -- n )  13 #uimm ;
: #uimm15  ( -- n )  15 #uimm ;
: #uimm16  ( -- n )  16 #uimm ;

: #uimm4,  ( -- n )  #uimm4  ","  ;
: #uimm5,  ( -- n )  #uimm5  ","  ;
: #uimm6,  ( -- n )  #uimm6  ","  ;

: #simm9   ( -- n )   9 #simm  ;
: #simm12  ( -- n )  12 #simm ;
: #simm25  ( -- n )  25 #simm  ;

\ Eval versions of some of these number words.
\ They're used in ld/st words with offsets inside
\ brackets.  E.g., ldr x0,[x1,#]
\ In that case, we want to parse up to the right
\ bracket, and evaluate the text.

: #eval]  ( -- n )
   "#"
   false  ( negate? )  "-"?  if  drop true  then
   push-decimal
   <c  " ]" lex  if           ( rem$ field$ delim )
      \ Delimiter was found; handle field and exit
      drop  2swap c>          ( field$ )
      evaluate
      swap if  negate  then
      pop-base
   else                       ( text$ )
      pop-base 3drop abort-try
   then
;

: #simm9]  ( -- n )  #eval]   9 #simm-check  ;
: #simm12] ( -- n )  #eval]  12 #simm-check  ;
: #uimm15] ( -- n )  #eval]  15 #uimm-check  ;

: xd?64|32    ( -- f )   rd-adt adt-xreg = if  64  else  32  then  ;

[ifdef] 32bit-host
: #uimm-nrs  ( sz -- n immr imms )
   >r r@ #duimm
   r> immed>{n,immr,imms}
   0= " an immediate value that conforms" ?expecting
;
[else]
: #uimm-nrs  ( sz -- n immr imms )
   >r r@  #uimm
   r> immed>{n,immr,imms}
   0= " an immediate value that conforms" ?expecting
; 
[then]


