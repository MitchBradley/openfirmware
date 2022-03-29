\ SVE predicate registers

\ four forms: Pn Pn.t Pn/M Pn/Z    n is 0 to 15   t is in bhsd
\ many instructions accept only P0 to P7, or P8 to P15

\ as source and destination registers they take Pn ;
\ as predicates they control which vector elements are affected,
\ and take /M if results are merged, /Z if zeroed

\ 4 bits to encode full set
\ sometimes called Pg in the instruction docs
: px   ( bit# -- adt )
   reg -rot     ( adt bit# n )
   dup 0 15 between 0= " P0 to P15" ?expecting
   swap 4 ^^op
;
\ 3 bits to encode lo or high set
: (plx)   ( bit# n adt -- adt )
   -rot     ( adt bit# n )
   dup 0 7 between 0= " P0 to P7" ?expecting
   swap ( adt n bit# ) 3 ^^op
;
: plx   ( bit# -- adt )   reg (plx)  ;
: phx   ( bit# -- adt )
   reg -rot     ( adt bit# n )
   dup 8 15 between 0= " P8 to P15" ?expecting
   8 -  swap 3 ^^op
;

: (px    ( bit# -- )   px   adt-preg <> ?invalid-regs  ;

: (pl    ( bit# -- )   plx  adt-preg <> ?invalid-regs  ;
: (ph    ( bit# -- )   phx  adt-preg <> ?invalid-regs  ;

\ lo or hi with /M
: (plm   ( bit# -- )   plx  adt-p/m <> ?invalid-regs  ;
: (phm   ( bit# -- )   phx  adt-p/m <> ?invalid-regs  ;

\ lo hi or full with /Z
: (pz    ( bit# -- )   px   adt-p/z <> ?invalid-regs  ;
: (plz   ( bit# -- )   plx  adt-p/z <> ?invalid-regs  ;
: (phz   ( bit# -- )   phx  adt-p/z <> ?invalid-regs  ;

\ these put 3 or 4 bits into the Ra bitfield
: px,    ( -- )    10 (px    ","  ;
: pl,    ( -- )    10 (pl    ","  ;
: plm,   ( -- )    10 (plm   ","  ;
: plz,   ( -- )    10 (plz   ","  ;
: plmu,  ( -- )    13 (plm   ","  ;   \ this is higher
\ these go to the same bitfields as Rn Ra Rm
: pzn    ( -- )     5 (pz    ;
: pzn,   ( -- )     5 (pz    ","  ;
: pza,   ( -- )    10 (pz    ","  ;
: pzm,   ( -- )    16 (pz    ","  ;

: pn   ( -- )    rn  rn-adt m.p adt? 0= ?invalid-regs  ;
: pa   ( -- )    ra  ra-adt m.p adt? 0= ?invalid-regs  ;
: pm   ( -- )    rm  rm-adt m.p adt? 0= ?invalid-regs  ;
: pn,  ( -- )    pn  ","  ;
: pa,  ( -- )    pa  ","  ;
: pm,  ( -- )    pm  ","  ;

: p.n   ( -- )    rn  rn-adt m.p.bhsd adt? 0= ?invalid-regs  ;
: p.a   ( -- )    ra  ra-adt m.p.bhsd adt? 0= ?invalid-regs  ;
: p.m   ( -- )    rm  rm-adt m.p.bhsd adt? 0= ?invalid-regs  ;
: p.n,  ( -- )    p.n  ","  ;
: p.a,  ( -- )    p.a  ","  ;
: p.m,  ( -- )    p.m  ","  ;


