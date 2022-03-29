\ Assembler Instruction Mnemonics for ARMv8.4
\ unfinished, 12 new instructions so far

: cfinv       0xD500.401F  %op  ;
: rmif        <asm  0x3A00.0400 xn,  #uimm6, 15 6 ^^op   #uimm4 or iop  asm>  ;
: setf8       0x3A00.080D m.x  %rn  ;
: setf16      0x3A00.480D m.x  %rn  ;

: sha512h     0xCE60.8000 m.q   %3sha84  ;
: sha512h2    0xCE60.8400 m.q   %3sha84  ;
: sha512su0   0xCEC0.8000 m.v.2d  %2sha  ;
: sha512su1   0xCE60.8800 m.v.2d  %3sha84  ;
: rax1        0xCE60.8C00 m.v.2d  %3sha84  ;
: xar         0xCE80.0000 m.v.2d  %3isha84  ;

: fmlal      ( -- )
   2 0 try: case
      0  of  0x0F80.0000 m.v#s  fvelem-long   endof
      1  of  0x0E20.EC00 m.v#s   fv3long  endof
   endcase
;
: fmlal2      ( -- )
   2 0 try: case
      0  of  0x2F80.8000 m.v#s  fvelem-long   endof
      1  of  0x0E20.CC00 m.v#s   fv3long  endof
   endcase
;

: fmlsl      ( -- )
   2 0 try: case
      0  of  0x0F80.4000 m.v#s  fvelem-long   endof
      1  of  0x0EA0.EC00 m.v#s   fv3long  endof
   endcase
;
: fmlsl2      ( -- )
   2 0 try: case
      0  of  0x2F80.C000 m.v#s  fvelem-long   endof
      1  of  0x0EA0.CC00 m.v#s   fv3long  endof
   endcase
;

\ sm3ss1 etc
\ sm4e etc

\ LDAPUR
\ LDAPUR
\ LDAPURB
\ LDAPURH
\ LDAPURSB
\ LDAPURSB
\ LDAPURSH
\ LDAPURSH
\ LDAPURSW
\ STLUR
\ STLUR
\ STLURB
\ STLURH

\ also extensions to TLBI
