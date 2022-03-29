\ various performance tweaks

: field   \ name  ( offset size -- offset' )
   header  code-cf
   [ also arm64-assembler also helpers ]
   over ( offset ) 0 set-reg-value    \  set    x0,#offset
   0x8b000339 instruction,            \  add    tos, tos, x0
   next                               \  br     up
   [ previous previous ]
   ( offset size )  +  ( offset' )
;

: lfield   \ name  ( offset size -- offset' )
   \ In this implementation, there's no advantage to lfield over field
   field
;

