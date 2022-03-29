
\ used only for VADD etc ... should be aliases?
\ scalars

\ XXX this version failed
\ : ^simd-int-3same ( _U _size _opcode )
\    0x0e200400 iop
\    ( _opcode )  11 5 ^^op
\    ( _size )    22 2 ^^op
\    ( _U    )    29 1 ^^op
\    rd-adt case
\       adt-dreg.8b  of    endof
\       adt-qreg.16b of  0x8000.0000 iop  endof
\       adt-dreg.4h  of  0x0040.0000 iop  endof
\       adt-qreg.8h  of  0x8040.0000 iop  endof
\       adt-dreg.2s  of  0x0080.0000 iop  endof
\       adt-qreg.4s  of  0x8080.0000 iop  endof
\       adt-qreg.2d  of  0x80c0.0000 iop  endof
\       \ these are local additions, equal to d.8b and q.16b
\       adt-qreg     of  0x8000.0000 iop  exit  endof
\       adt-dreg     of    endof
\       " simd Q.T or D.T register" expecting
\    endcase
\ ;

: ^simd-int-3same ( _U _size _opcode )
   0x0e200400 iop
   ( _opcode )  11 5 ^^op
   ( _size )    22 2 ^^op
   ( _U    )    29 1 ^^op
   rd-adt case
      adt-dreg.8b of                \ q:0 size:00
      endof 
      adt-qreg.16b of                \ q:1 size:00
	 1 30 1 ^^op     \ q:1
      endof
      adt-dreg.4h of                \ q:0 size:01
	 1 22 2 ^^op     \ size:01   
      endof 
      adt-qreg.8h of                \ q:1 size:01
	 1 22 2 ^^op     \ size:01   
	 1 30 1 ^^op     \ q:1
      endof 
      adt-dreg.2s of                \ q:0 size:10
	 2 22 2 ^^op     \ size:10   
      endof 
      adt-qreg.4s of                \ q:1 size:10
	 2 22 2 ^^op     \ size:10   
	 1 30 1 ^^op     \ q:1
      endof 
      adt-qreg.2d of                \ q:1 size:11
	 3 22 2 ^^op     \ size:11   
	 1 30 1 ^^op     \ q:1
      endof 
      adt-qreg of  
	 1 30 1 ^^op     \ q:1
      endof 
      adt-vreg of  
	 1 30 1 ^^op     \ q:1
      endof 
      adt-dreg of 
      endof 
      " simd q.t or d.t register" expecting
   endcase
;

: ?hsd   ( adt-type -- n )
   case
      adt-hreg of  3  endof
      adt-sreg of  0  endof
      adt-dreg of  1  endof
      " an H, S, or D register" expecting
   endcase
;

