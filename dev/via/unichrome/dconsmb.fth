: smb-dly  4 us  ;
: crtsp-set  ( mask -- )  h# 26 seq@  or  h# 26 seq!  smb-dly  ;
: crtsp-clr  ( mask -- )  invert  h# 26 seq@  and  h# 26 seq!  smb-dly  ;
: crtsp@  ( mask -- flag )  h# 26 seq@ and  0<>  ;

: smb-data-hi  ( -- )  h# 10 crtsp-set  ;
: smb-data-lo  ( -- )  h# 10 crtsp-clr  ;
: smb-clk-hi  ( -- )  h# 20 crtsp-set  ;
: smb-clk-lo  ( -- )  h# 20 crtsp-clr  ;
: smb-data@  ( -- flag )  4 crtsp@  ;
: smb-clk@  ( -- )  8 crtsp@  ;
\ : smb-on  ( -- )  1 crtsp-set  h# 30 crtsp-set  d# 10 ms  ;
: smb-off  ( -- )  1 crtsp-clr  ;
: smb-on  ( -- )  h# 31 crtsp-set  ;
: smb-bit@  ( -- )  smb-clk-hi  h# 26 seq@ 4 and 0<>  smb-clk-lo  ;

h# 3500 constant smb-clk-timeout-us
\ Slave can flow control by holding CLK low temporarily
: smb-wait-clk-hi  ( -- )
   smb-clk-timeout-us 0  do
      smb-clk@  if  smb-dly  unloop exit  then  1 us
   loop
   true abort" I2C clock stuck low"
;
: smb-data-hi-w  ( -- )  smb-data-hi  smb-wait-clk-hi  ;

h# 3500 constant smb-data-timeout-us
: smb-wait-data-hi  ( -- )
   smb-data-timeout-us 0  do
      smb-data@  if  unloop exit  then  1 us
   loop
   true abort" I2C data stuck low"
;

: smb-restart  ( -- )
   smb-clk-hi  smb-data-lo  smb-clk-lo
;

: smb-start ( -- )  smb-clk-hi  smb-data-hi  smb-data-lo smb-clk-lo  ;
: smb-stop  ( -- )  smb-clk-lo  smb-data-lo  smb-clk-hi  smb-data-hi  ;

: smb-get-ack  ( -- )
   smb-data-hi
   smb-clk-hi smb-wait-clk-hi  
   smb-data@  if  smb-stop  true abort" I2c NAK" then
   smb-clk-lo
\   smb-wait-data-hi
;
: smb-bit  ( flag -- )
   if  smb-data-hi  else  smb-data-lo  then
   smb-clk-hi smb-wait-clk-hi  smb-clk-lo
;

: smb-byte  ( b -- )
   8 0  do                     ( b )
      dup h# 80 and  smb-bit   ( b )
      2*                       ( b' )
   loop                        ( b )
   drop                        ( )
   smb-get-ack
;
: smb-byte-in  ( ack=0/nak=1 -- b )
   0
   8 0  do             ( n )
      smb-clk-hi       ( n )
      2*  smb-data@  if  1 or  then  ( n' )
      smb-clk-lo
   loop
   swap smb-bit  smb-data-hi  \ Send ACK or NAK
;

0 value smb-slave
: smb-addr  ( lowbit -- )  smb-slave 2* or  smb-byte  ;
: smb-word!  ( word reg# -- )
   smb-start
   0 smb-addr          ( word reg# )
   smb-byte            ( word )
   wbsplit swap smb-byte smb-byte  ( )
   smb-stop
;

: smb-word@  ( reg# -- word )
   smb-start
   0 smb-addr          ( reg# )
   smb-byte            ( )
   smb-restart
   1 smb-addr          ( )
   0 smb-byte-in   1 smb-byte-in  bwjoin  ( word )
   smb-stop
;

\ This can useful for clearing out DCON SMB internal state
: smb-pulses  ( -- )
   d# 32 0  do  smb-clk-lo smb-clk-hi  loop
;
: smb-init  ( -- )  smb-on  smb-pulses ;

: dcon@  ( reg# -- word )  h# 0d to smb-slave  smb-word@  ;
: dcon!  ( word reg# -- )  h# 0d to smb-slave  smb-word!  ;
