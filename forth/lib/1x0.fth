\ Imprecise
\ XXX note: move this code out of the disassembler, and add arm32 and x64 support

\ turn imprecise spec line into value and mask
\ char mask value
\ 1    1    1
\ 0    1    0
\ x    0    0
\ _    ignored

\ example
\ " 010xxx01" 1x0    gives ( 11100011 01000001 )
: 1x0   ( $ -- mask value )
   >r  0 0 rot    ( m v a )
   begin  r@  while
      dup c@ case        ( m v a )
	 ascii 1 of
	    rot 2* 1 or 
	    rot 2* 1 or
	    rot
	 endof
	 ascii 0 of
	    rot 2* 1 or 
	    rot 2*
	    rot	    
	 endof
	 ascii x of
	    rot 2* 
	    rot 2* 
	    rot
	 endof
	 ascii _ of	 endof
	 true abort" invalid 1x0 string"
      endcase
      1+
      r> 1- >r   \ count
   repeat    ( m v a )
   r> 2drop
;

\ [ifndef] (1x0)
\ \ push a pair of 32-bit in-line values 
\ code (1x0)   ( -- mask value )
\    push    tos,sp
\    ldr     w0,[ip],#4
\    push    x0,sp
\    ldr     wtos,[ip],#4
\ c;
\ [then]

\ convert string and compile a pair of 32-bit values
: 1x0"   ( -- )   ascii " parse 1x0 postpone (1x0)  swap l, l,  ; immediate

\ convert string and compile a pair of 64-bit values
\ : x1x0"   ( -- )   ascii " parse 1x0 postpone (x1x0)  swap , ,  ; immediate

\ [ifndef] (af)
\ \ "and of"
\ \ essentially   " selector mask and value = if drop  "
\ code (af)  ( selector mask val -- [ selector ] )
\    mov     x0,tos     \ val
\    pop     x1,sp      \ mask
\    pop     tos,sp     \ selector
\    and     x1,x1,tos
\    cmp     x1,x0
\    <> if
\       ldrsw x0,[ip]
\       add   ip,ip,x0
\       next
\    then
\    pop     tos,sp
\    inc     ip,#/token
\ c;
\ [then]

: af     ( -- >m )  ['] (af)  +>mark  ; immediate
alias endaf endof immediate


also hidden
\ Decompiler extensions for 1x0 and af support
\ note: 1x0 decompiles as a pair of literals
\ maybe later show the source string instead
: .1x0       ( ip -- ip' )  ta1+ dup l@ . la1+  dup l@ . la1+  ; 
: skip-1x0   ( ip -- ip' )  ta1+ la1+ la1+  ;
: .(1x0)     ( ip -- ip' )  .." af   " +branch  ;
' (1x0)  ' .1x0  ' skip-1x0  install-decomp
      
: .af        ( ip -- ip' )  .." af   " +branch  ;
' (af)  ' .af  ' scan-of  install-decomp
previous

