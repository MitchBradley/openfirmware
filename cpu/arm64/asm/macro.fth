\ minimal macro support
\ see forth/lib/macro.fth

\ XX same as dl@ ??
: 2L@   ( a -- l0 l1 )   dup l@ swap 4 + l@ ;

\ ==========================================
\ macro support
\ ugly but it works.
\ feel free to optimize it
\ Example:
\ .macro mJunk
\     mov x1, x0
\     mov x2, x3
\     mov x3, x4
\     .endm
\     
\ code foo
\     mJunk
\     mJunk
\     mJunk
\    c;
\ 
\ 
\ 0: code foo 
\  aa0003e1  orr     x1, xzr, x0
\  aa0303e2  orr     x2, xzr, x3
\  aa0403e3  orr     x3, xzr, x4
\  aa0003e1  orr     x1, xzr, x0
\  aa0303e2  orr     x2, xzr, x3
\  aa0403e3  orr     x3, xzr, x4
\  aa0003e1  orr     x1, xzr, x0
\  aa0303e2  orr     x2, xzr, x3
\  aa0403e3  orr     x3, xzr, x4
\  d61f0300  br      up          \ next
\ ==========================================


: Copy-Code ( src dst len ) 0 DO 2dup swap l@ swap instruction! 4 4 d+  4 +loop 2drop ;
0 value macro-here

: .macro
	create
	Here 8 + origin- l,     \ where code is going
	0 l,                    \ will hold code len
	Here is macro-here      \ where we start compiling code
    do-entercode
	does>
 	2L@ ?dup                \ 1/13/13 added for code len's of xer0
 	IF
        swap
        origin+ 
        over ( len adr )
        Here ( len adr len )
        swap ( len adr len Here )
        Copy-Code 
        ( len ) allot				\ AND ALLOC THE DICT
    ELSE
        drop
    THEN

 	;

: .endm Here macro-here - macro-here 4 - l! do-exitcode ;



\ ==========================================
\ .rept pseudo op
\ Example:
\ code foo
\     .rept 3
\     add     x0, x0, #1
\     add     x1, x1, #2
\     .endr
\     c;
\     
\     
\ 0: 0 -> <- Empty ok see foo
\ 0: code foo 
\ 0:  91000400  add     x0, x0, #1
\ 0:  91000821  add     x1, x1, #2
\ 0:  91000400  add     x0, x0, #1
\ 0:  91000821  add     x1, x1, #2
\ 0:  91000400  add     x0, x0, #1
\ 0:  91000821  add     x1, x1, #2
\ 0:  91000400  add     x0, x0, #1
\ 0:  91000821  add     x1, x1, #2
\ 0:  d61f0300  br      up          \ next
\ ==========================================
    

0 value rept-hereSv
0 value rept-end
0 value rept-Len
0 value #rept 

: .rept ( <n> )
    bl parse          \ grab  #rept  
                                \ note number is total-1
                                \ we assemble the 1st iteration
                                \ and copy that 1st one <#rept > times
    dup
    0= IF cr ." .rept: Error no repeat value" 2drop quit then
    push-decimal eval pop-base is #rept  
	Here is rept-hereSv         \ save current here to calc len
    ;


: .endr
    here is rept-end
    rept-end rept-hereSv - is rept-Len 
    rept-Len #rept * 0
    DO
        rept-hereSv rept-end i + rept-Len Copy-Code
        rept-Len allot
    rept-Len +LOOP
 ;

 