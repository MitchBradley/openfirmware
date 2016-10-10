0 value #gpt-partitions
0 value /gpt-entry
32\ 0. 2value partition-lba0
32\ alias x>u drop
32\ alias u>x u>d
32\ alias x+ d+
32\ alias x- d-
32\ alias xswap 2swap
32\ : onex 1. ;
32\ : xu*d  ( x u -- d )  du*  ;

32\ alias x>d noop

64\ 0 value partition-lba0
64\ : onex 1 ;
64\ alias x>d 0
64\ alias x>u noop
64\ alias u>x noop
64\ alias x- -
64\ alias x+ +

64\ alias xu*d um*

: gpt-magic  ( -- adr len )  " EFI PART"  ;
: gpt-blk0   ( adr -- d.blk0 )  d# 32 + le-x@  ;
: gpt-#blks  ( adr -- d.blks )  dup d# 40 + le-x@  rot gpt-blk0 x-  onex x+  x>d  ;
