\ helps the arm64 assembler compile on x64

[ifndef] clz
: clz   ( n -- count )   \ count leading zeroes
   0 swap    ( count n )
   d# 64 0 do   dup 1 63 i - << and ?leave  swap 1+ swap  loop
   drop
;
: cto   ( n -- count )   \ count trailing ones
   0 swap    ( count n )
   d# 64 0 do   dup 1 i << and 0= ?leave  swap 1+ swap    loop
   drop
;
[then]
