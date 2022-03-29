\ Define classes of instructions

: %op       ( op -- )        <asm  iop  asm>  ;
: %rd       ( op regs -- )   <asm  rd  rd??iop   asm>  ;
: %rn       ( op regs -- )   <asm  rn  rn??iop   asm>  ;
: %2same    ( op regs -- )   <asm  2same  asm>  ;

\ Data Processing (general purpose registers)

: %rev    ( op regs -- )   <asm  d=n  rd??iop  xd? if  0x8000.0400 iop  then  asm>  ;
: %dp1    ( op regs -- )   <asm  3crc   set-sf?  asm>  ;
: %dp2    ( op regs -- )   <asm  3same  set-sf?  asm>  ;

: %dp3a   ( op regs -- )   <asm  3long  set-sf?  asm>  ;
: %dp3b   ( op regs -- )   <asm  3same  set-sf?  asm>  ;
: %dp4a   ( op regs -- )   <asm  d=a>n=m  rd??iop  set-sf?  asm>  ;
: %dp4b   ( op regs -- )   <asm  4same  set-sf?  asm>  ;

\ Logic instructions

: logic-shift ( -- shift-type count )
   ","?  0=  if  0 0  exit  then
   <c $case
      " lsl"  $sub  c>  0 #uimm6  $endof
      " lsr"  $sub  c>  1 #uimm6  $endof
      " asr"  $sub  c>  2 #uimm6  $endof
      " ror"  $sub  c>  3 #uimm6  $endof
      " a shift type: lsl, lsr, asr, ror" expecting
   $endcase
;

: (log-shifted-reg)  ( opc N sh-type sh-cnt -- )
   0x0a000000 iop   set-sf?
   ?rd=rn=rm
   wd? if
      ( cnt ) dup 32 >=
      " shift count for 32 bit registers must be less than 32" ?expecting
   then
   ( cnt )  10 6 ^^op
   ( type ) 22 2 ^^op
   ( N  )   21 1 ^^op
   ( opc )  29 2 ^^op
;

: log-reg ( opc N )   wxm  logic-shift  (log-shifted-reg) ;

: (log-imm)  ( opc N immr imms -- )
   0x12000000 iop   set-sf?
   ?rd=rn   ^imms6 ^immr6   ( opc n )
   wd? if  dup " 32 bit immediate value" ?expecting  then
   ( N  )   22 1 ^^op
   ( opc )  29 2 ^^op
;

: log-imm ( opc N )   drop >c  xd?64|32 #uimm-nrs  (log-imm)  ;

: log-imm-modes  ( idx op n -- )
   rot case
     0  of  wxd|sp, wxn,   "#" log-imm  endof
     1  of  wxd,    wxn,       log-reg  endof
   endcase
;


\ Add & Sub

: ^aimm   ( op S imm12 shift invert-op? )
   0x11000000 iop  set-sf?
   >r
   ( shift ) 22     2 ^^op
   ( imm12 ) 10 12 ^^op
   (  S    ) 29     1 ^^op
   \ Invert op if the invert-op? flag is present
   r> if 1 xor then
   (  op   ) 30     1 ^^op
;

\ #aimm Fetches a number and then treats it in one of three ways:
\    1) If positive and less than 0x1000, checks for the presence of ", LSL #imm" where
\       imm has to be 0 or 12.
\    2) Else, if positive, checks to ensure that the low order 12 bits are
\       0 and that the number fits in 12 bits.  If that's the case,
\       the number is returned shifted down 12 bits with the shift flag set.
\    3) Else (the number is negative), checks to see if absolute value of the number applies
\       to cases 1 or 2 above and then sets the invert-op? flag so that the caller
\       can convert an add to a subtract (or vice-verse) or a cmp to a cmn (or vice-verse).
: #aimm-err ( -- )
   " A 12 bit number expressed as 'n, LSL #0|12', 'n' where the absolute value of n fits in 12 bits shifted 12 bits to the left or not" expecting
;
: #aimm  ( -- uimm12 shift invert-op? )
   \ Test for: a register move:  add x0, x1   <-- Move x1 to x0
   ","?  0=  if  0  0  0  exit  then    ( n shift invert-op? )
   #simm25  dup  12 mask andc 0= if
      \ Less than 0x1000, yet positive
      ","?  0=  if
         0 0
      else
         " lsl" $match?  0=  if  #aimm-err  then
         #uimm4 dup 0 = over 12 = or 0= if #aimm-err then
         12 = if 1 else 0 then 0        ( n shift invert-op? )
      then
   else
      dup  12 mask 12 lshift andc 0= if
         \ Less than 0x1,000,000, yet positive
         12 rshift 1 0               ( n shift invert-op? )
      else
         dup sext 0 < 0= if #aimm-err then
         \ Negative.  See if it's less than 0x1000 or 0x1,000,000
         -1 xor dup h# 1000 < if 0 1 else  ( n shift invert-op? )
            dup h# 1000000 < if
               12 rshift 1 1         ( n shift invert-op? )
            else
               #aimm-err
            then
         then
      then
   then
;

: ^ashift ( op S shift imm6 )
   ?rd=rn
   0x0b000000 iop   set-sf?
   ( imm6 )  ^imms6
   ( shift ) 22     2 ^^op
   (  S    ) 29     1 ^^op
   (  op   ) 30     1 ^^op
;

: ashift ( -- shift-type shift-amount )
   ","?  0=  if  0  0  exit then
   <c  $case
      " lsl"  $sub  c>  0  $endof
      " lsr"  $sub  c>  1  $endof
      " asr"  $sub  c>  2  $endof
      c>  " 'LSL', 'LSR', or 'ASR' followed by a shift amount" expecting
   $endcase
   xd?  if  #uimm6  else  #uimm5  then
;

: ^aext ( op S option imm3 )
   ?rd=rn
   0x0b200000 iop   set-sf?
   ( imm3 )   10  3  ^^op
   ( option ) 13  3  ^^op
   ( S )      29  1  ^^op
   ( op )     30  1  ^^op
;

: #aext-shift-err   " a shift of 0, 1, 2, or 3" expecting  ;
: uxtb?  ( -- index f | t )
   <c 4 < if
      drop 1
   else
      4 " uxtbuxthuxtwuxtxsxtbsxthsxtwsxtx" sindex
      dup 3 and dup  if  nip  then
      dup 0= if <c 4 /string c> then
   then
;
: #aext ( -- option imm3 )
   ?rd=rn
   ","?  0= if
      xd? if  3  else  2  then  0  exit
   then
   uxtb? if
      " lsl"  $match?  if
         xd? if  ( uxtx) 3  else  ( uxtw) 2  then
      else
         " an extending option (uxtb, uxth, uxtw, uxtx, sxtb, sxth, sxtw, sxtx) or lsl" expecting
      then
   else
      2 rshift  \ Convert index into option number
   then

   "#"?  0= if
      0
   else
      >c  #uimm3  dup 0=  if  exit  then
      dup 3 > if  #aext-shift-err  then
   then
;

: ?add-wxd,  ( s -- s )  dup if  wxd,  else  wxd|sp,  then  ;

: add-sub ( idx op s -- )
   rot case
      0  of  ?add-wxd, wxn|sp         #aimm   ^aimm    endof
      1  of  wxd,      wxn,     wxm   ashift  ^ashift  endof
      2  of  ?add-wxd, wxn|sp,  wxm   #aext   ^aext    endof
   endcase
;

: parse-cmp ( idx op s -- )
   rot case
      0  of  wxn|sp   [wxzd]       #aimm   ^aimm    endof
      1  of  wxn,     [wxzd]  wxm  ashift  ^ashift  endof
      2  of  wxn|sp,  [wxzd]  wxm  #aext   ^aext    endof
   endcase
;

: %adc2   ( op regs -- )   <asm  d=m    rd??iop  set-sf?  asm>  ;

: #lsl  ( -- )
   xd? if   0x8040.0000 iop  63 6  else  31 5  then  uimm    ( k-1 shift )
   >r  dup 1+ r@ - over and swap r> -
   ^imms6  ^immr6
;
: #lsr  ( -- )   xd? if  0x8040.8000 iop  6  else  5  then   uimm ^immr6  ;
: regshift   ( op regs -- )   rm  ?rd=rn=rm  rd??iop  set-sf?  ;

\ Extract

: ^extr   ( -- )
   #uimm6 ^imms6   xd? if
      0x93c0.0000 iop
   else
      0x1380.0000 iop
      <imms>  32  and
      " the extract bit # must be less than 32" ?expecting
   then
;

\ used only in ROR
: rn->rm   ( -- )   rn-adt is rm-adt <rn> ^rm ;


\ Bitfield

: #sf-immr,  ( -- n )
   xd? if   64 #uimm6, - 63 and
   else     32 #uimm5, - 31 and
   then
;

: imms<immr   ( -- )     <imms>  <immr>  <   not " imms < immr"  ?expecting  ;
: imms>=immr  ( -- )     <imms>  <immr>  >=  not " imms >= immr" ?expecting  ;

: #bfm    ( -- )   #uimm6,      ^immr6  #uimm6      ^imms6  ;
: #bfc    ( -- )   64 #uimm6, - ^immr6  #uimm6 1-   ^imms6  ;
: #bfi    ( -- )   #sf-immr,    ^immr6  #uimm6 1-   ^imms6  ;
: #bfx    ( -- )   #uimm6,  dup ^immr6  #uimm6 + 1- ^imms6  ;

: bitfield ( opc regs -- )
   rd??iop
   xd? if
      0x8040.0000 iop
   else
      <immr> <imms> or  32  and
      " IMMR and IMMS fields to have values less than 32" ?expecting
   then
;

: adr-imm  ( target op -- )
   dup iop  0x9000.0000 =
   if   \ adrp
      \ adrp says that imm has 12 low bits of zero affixed to it
      \ and it gets added to the current PC with the low order 12 bits
      \ cleared.
      12 mask andc               ( target-masked )
      here 12 mask andc          ( target-masked here-masked )
      - 12 >>a                   ( distance-in-pages )
64\   dup h# -10.0000 <  " a branch target less than 4GB away" ?expecting
      21 mask and
   else
      \ adr says that imm is added to the current PC to generate a
      \ pc relative address
      here -                      ( offset-relative )
      dup 
      abs  \ make absolute to detect large positive offsets
      h# 10.0000 >  " a branch target less than 1MB away" ?expecting

      21 mask and
   then
   dup 3 and   29 2 ^^op
   2 >>        5 19 ^^op
;
: %adr-imm  ( op regs -- )   <asm#  rd, rd??  >r  br-target  r> adr-imm  asm>  ;

