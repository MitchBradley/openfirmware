\ support for LDn, STn, and TBL

\ support the horrible syntax
\ LD1 { v0.2d, v1.2d, v2.2d, v3.2d }, [x4], x5

\ the list of registers must be sequential (mod 32)
\ eg  0,1,2,3 or 30,31,0,1

: (getlist)   ( -- n count adt )
   "{"  reg >r  1   ( n count )
   begin
      ","?
   while
      2dup + 32 mod        ( n count next )
      reg r@ <> " registers to be the same type " ?expecting   ( n count next n' )
      <> " registers to be sequential " ?expecting                 ( n count )
      1+
   repeat
   "}"
   r>
;
: getlist   ( -- n count )   (getlist) is rd-adt  ;
: %tbl   ( op regs -- )   \ for TBL
   <asm  rd,  rd??iop
   rd-adt >r  getlist rd-adt is rn-adt  r> is rd-adt  ( n count )
   13 2 ^^op  ^rn  ","  rm
   ?rd=rm
   m.v.16b rn-mask and 0= ?invalid-regs
   rd-adt vreg>szq 30 ^op drop
   asm>
;

0 [if]
TBL needs to decode a list argument
TBL <Vd>.<Ta>, {<Vn>.16B, <Vn+1>.16B, <Vn+2>.16B, <Vn+3>.16B}, <Vm>.<Ta>

\ for sanity's sake define macros:
TBL1  Vd.8b, Vn.16b, Vm.8b   \ or TBL1  Vd.16b, Vn.16b, Vm.16b
TBL2  Vd.8b, Vn.16b, Vm.8b   \ TBL2 implies TBL  Vd.8b, { Vn.16B, Vn+1.16b }, Vm.16b
TBL3  Vd.8b, Vn.16b, Vm.8b   \ etc
TBL4  Vd.8b, Vn.16b, Vm.8b
[then]

: %tbln   ( op regs -- )   \ for the macros: tbl1 tbl2 tbl3 tbl4
   <asm  rd, rn, rm  ?rd=rm  rd??iop
   m.v.16b rn-mask and 0= ?invalid-regs
   rd-adt vreg>szq 30 ^op drop
   asm>
;

\ LDn multiple
: get-xm   ( -- )
   xm  <rm> 31 = if  " Xm cannot be 31 " ad-error   then
;
: (ldn-m)   ( n -- )
   rd-adt vreg>szq             ( n sz q )
   swap 10 2 ^^op  dup 30 ^op  ( n q )
   "," [xn|sp] ","? if
      0x0080.0000 iop
      "#"? if                   ( n q )
	 31 ^rm
	 2dup 8 swap << *       ( n q offset )
	 7 #uimm <> if  " offset does not match size " ad-error   then
      else
	 get-xm
      then
   then                          ( n q )
   2drop
;
: ld-m   ( op n -- )      \ multiple
   >r
   iop  getlist          ( n count )
   r@ <> ?invalid-regs   ( n )
   ^rd
   r> (ldn-m)
;
: %ld-m   ( op n -- )   <asm  ld-m  asm>  ;

\ only LD1 multiple can take a variable length list
: ld1-m   ( op -- )
   iop   getlist   ( n count )
   >r ^rd    r@ case
      1 of   0x7000   endof
      2 of   0xa000   endof
      3 of   0x6000  endof
      4 of   0x2000   endof
      true ?invalid-regs
   endcase   iop
   r> (ldn-m) 
;

\ LDn single

: ldn-encode-index   ( index #bits -- )
   2dup mask andc " index too large " ?error                    ( index #bits )
   dup 4 = if   3 - swap  dup 3 >> swap 7 and 10 3 ^^op  swap  then    ( index #bits )
   dup 3 = if   2- swap   dup 2 >> swap 3 and 11 2 ^^op  swap  then    ( index #bits )
       2 = if             dup 1 >> swap 1 and 12 1 ^^op        then    ( index )
   30 ^op
;
: (ldn-s)   ( offset -- )
   "," [xn|sp] ","? if
      0x0080.0000 iop
      "#"? if
	 31 ^rm
	 dup 6 #uimm <> if  " offset does not match size " ad-error   then
      else
	 get-xm
      then
   then
   drop  \ offset
;

: get-index   ( #bits -- index )   "[" uimm "]"  ;

: ld-s   ( op n -- )      \ single
   >r
   iop  getlist          ( n count )
   r@ <> ?invalid-regs   ( n )
   ^rd  4 get-index      ( index )
   rd-adt    case
      adt-vreg.b   of    1 4 0x0000    endof
      adt-vreg.h   of    2 3 0x4000    endof
      adt-vreg.s   of    4 2 0x8000    endof
      adt-vreg.d   of    8 1 0x8400    endof
      " .b .h .s or .d " expecting
   endcase               ( index offset #bits size-op )
   iop  rot swap         ( offset index #bits )
   ldn-encode-index      ( offset )
   r> * (ldn-s) 
;

: ld-r   ( op n -- )      \ single
   >r
   iop  getlist          ( n count )
   r@ <> ?invalid-regs   ( n )
   ^rd  
   rd-adt vreg>szq           ( sz q )
   30 ^op  dup 10 2 ^^op     ( sz )
   1 swap <<                 ( offset )
   r> * (ldn-s) 
;
: %ld-r   ( op n -- )   <asm  ld-r  asm>  ;
