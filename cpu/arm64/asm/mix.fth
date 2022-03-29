\ mix
\ some mnemonics have many meanings
\ instructions-mix.fth handles them based on the type of destination register
\ this file has internal elements used in instructions-mix.fth

: %vmov   ( -- )
   2 0 try: case
      0  of  0x4E00.1C00  ^simd-ins-veg      endof   \ MOV ve, gpr  ( INS )
      1  of  0x6E00.0400  ^simd-ins-veve     endof   \ MOV ve, ve   ( INS )
   endcase
;
: %gmov   ( -- )
   5 0 try: case
      0  of  0x0E00.3C00  ^simd-umov         endof   \ MOV gpr, ve  ( UMOV )
      1  of  1 0  wxd, [wxzn] wxm  0 0  (log-shifted-reg)  endof   \ MOV wx, wx    ( ORR Rd,RZR,Rn )
      2  of  0 0 0  add-sub                  endof   \ MOV wxp, wxp  ( ADD Rd,SP,#0 &c.)
      3  of  2  wxd,  mov-nzk-imm  ^mov-nzk  endof   \ MOV wx, #uimm16{, LSL #0|16|32|48}
      4  of  0  wxd,  mov-nzk-imm  ^mov-nzk  endof   \ FIXME mov x0,#-5  -->  movn x0,#5
   endcase
;

: fabd-leg    0x2EA0.D400 m.v#sd  0x7EA0.D400 m.sd  %f3same-nv  ;       \ fabd moved to -mix.fth
: fabs-leg    0x0EA0.F800 m.v#sd  0x1E20.C000 m.sd  %f2same-nv  ;       \ fabs moved to -mix.fth
: fadd-leg    0x0E20.D400 m.v#sd  0x1E20.2800 m.sd  %f3same-nv  ;       \ fadd moved to -mix.fth
: faddp-leg   0x2E20.D400 m.v#sd  0x7E30.D800 m.sd  %f3same-np  ;       \ faddp moved to -mix.fth
: fdiv-leg    0x2E20.FC00 m.v#sd  0x1E20.1800 m.sd  %f3same-nv  ;       \ fdiv moved to -mix.fth
: fmax-leg    0x2E20.F400 m.v#sd  0x1E20.4800 m.sd  %f3same-nv  ;
: fmaxnm-leg  0x0E20.F400 m.v#sd  0x1E20.6800 m.sd  %f3same-nv  ;
: fmaxnmp-leg 0x2E20.C400 m.v#sd  0x7E30.C800 m.sd  %f3same-np  ;
: fmaxnmv-leg 0x6E30.C800 m.sd  %across  ;
: fmaxv-leg   0x6E30.F800 m.sd  %across  ;
: fmaxp-leg   0x2E20.F400 m.v#sd  0x7E30.F800 m.sd  %f3same-np  ;
: fmin-leg    0x0EA0.F400 m.v#sd  0x1E20.5800 m.sd  %f3same-nv  ;
: fminnm-leg  0x0EA0.C400 m.v#sd  0x1E20.7800 m.sd  %f3same-nv  ;
: fminnmp-leg 0x2EA0.C400 m.v#sd  0x7EB0.C800 m.sd  %f3same-np  ;
: fminnmv-leg 0x6EB0.C800 m.sd  %across  ;
: fminv-leg   0x6EB0.F800 m.sd  %across  ;
: fminp-leg   0x2EA0.F400 m.v#sd  0x7EB0.F800 m.sd  %f3same-np  ;
: fneg-leg    0x2ea0.f800 m.v#sd  0x1e21.4000 m.sd  %f2same-nv  ;
: frecpe-leg  0x0ea1.d800 m.v#sd  0x5ea1.d800 m.sd  %f2same-nv  ;
: frecps-leg  0x0E20.FC00 m.v#sd  0x5E20.FC00 m.sd  %f3same-nv  ;
: frecpx-leg  0x5EA1.F800 m.sd  %fs2same  ;
: frinta-leg  0x2e21.8800 m.v#sd  0x1e26.4000 m.sd  %f2same-nv  ;
: frinti-leg  0x2ea1.9800 m.v#sd  0x1e27.c000 m.sd  %f2same-nv  ;
: frintm-leg  0x0e21.9800 m.v#sd  0x1e25.4000 m.sd  %f2same-nv  ;
: frintn-leg  0x0e21.8800 m.v#sd  0x1e24.4000 m.sd  %f2same-nv  ;
: frintp-leg  0x0ea1.8800 m.v#sd  0x1e24.c000 m.sd  %f2same-nv  ;
: frintx-leg  0x2e21.9800 m.v#sd  0x1e27.4000 m.sd  %f2same-nv  ;
: frintz-leg  0x0ea1.9800 m.v#sd  0x1e25.c000 m.sd  %f2same-nv  ;
: frsqrte-leg 0x2ea1.d800 m.v#sd  0x7ea1.d800 m.sd  %f2same-nv  ;
: frsqrts-leg 0x0EA0.FC00 m.v#sd  0x5EA0.FC00 m.sd  %f3same-nv  ;
: fsqrt-leg   0x2ea1.f800 m.v#sd  0x1e21.c000 m.sd  %f2same-nv  ;
: fsub-leg    0x0EA0.D400 m.v#sd  0x1E20.3800 m.sd  %f3same-nv  ;       \ fsub moved to -mix.fth

: fcmeq-try  ( -- )                                      \ fcmeq moved to -mix.fth
   4 0 try: case
      0  of  0x0E20.E400 m.v#sd  fv3same  endof
      1  of  0x5E20.E400 m.sd    fs3same  endof
      2  of  0x0EA0.D800 m.v#sd  fv2same  endof
      3  of  0x5EA0.D800 m.sd    fs2same  endof
   endcase
;
: fcmge-try  ( -- )                                      \ fcmge moved to -mix.fth
   4 0 try: case
      0  of  0x2E20.E400 m.v#sd  fv3same  endof
      1  of  0x7E20.E400 m.sd    fs3same  endof
      2  of  0x2EA0.C800 m.v#sd  fv2same  endof
      3  of  0x7EA0.C800 m.sd    fs2same  endof
   endcase
;
: fcmgt-try  ( -- )                                      \ fcmgt moved to -mix.fth
   4 0 try: case
      0  of  0x2EA0.E400 m.v#sd  fv3same  endof
      1  of  0x7EA0.E400 m.sd    fs3same  endof
      2  of  0x0EA0.C800 m.v#sd  fv2same  endof
      3  of  0x5EA0.C800 m.sd    fs2same  endof
   endcase
;
: fcvt-try   ( -- )
   <asm  0x1E22.4000 iop  rd, rn
   rd-adt ?hsd  ( opc  )  15 2 ^^op
   rn-adt ?hsd  ( type )  22 2 ^^op
   asm>
;
: fcvtzs-try     ( -- )
   5 0 try: case
      0  of  0x1e38.0000          ^simd-gn  endof
      1  of  0x0EA1.B800 m.v#sd   fv2same   endof
      2  of  0x5EA1.B800 m.sd     fs2same   endof
      3  of  0x0F00.FC00 m.v#sd   v2#same   endof
      4  of  0x5F00.FC00 m.sd     s2#same   endof
      \ 5  of  0x1e18.0000         ^simd-gni   endof
   endcase
;
: fcvtzu-try     ( -- )
   5 0 try: case
      0  of  0x1e39.0000          ^simd-gn  endof
      1  of  0x2EA1.B800 m.v#sd   fv2same   endof
      2  of  0x7EA1.B800 m.sd     fs2same   endof
      3  of  0x2F00.FC00 m.v#sd   v2#same   endof
      4  of  0x7F00.FC00 m.sd     s2#same   endof
      \ 5  of  0x1e19.0000         ^simd-gni   endof
   endcase
;

: fmla-try   ( -- )
   3 0 try: case
      0  of  0x0F80.1000 m.v#sd  fvelem-same   endof
      1  of  0x5F80.1000 m.sd    fselem-same   endof
      2  of  0x0E20.CC00 m.v#sd  fv3same  endof
   endcase
;
: fmls-try   ( -- )
   3 0 try: case
      0  of  0x0F80.5000 m.v#sd  fvelem-same   endof
      1  of  0x5F80.5000 m.sd    fselem-same   endof
      2  of  0x0EA0.CC00 m.v#sd  fv3same  endof
   endcase
;
: fmov-try   ( -- )
   4 0 try: case
      0  of  0x1E20.4000 m.sd   fs2same    endof
      1  of  0x1E20.1000 m.sd   simd-nimm  endof
      2  of  0x0F00.F400 m.v#sd  modimm     endof
      3  of  fpr-gpr-mov        endof
   endcase
;

: fmul-try   ( -- )                                      \ fmul moved to -mix.fth
   4 0 try: case
      0  of  0x0F80.9000 m.v#sd  fvelem-same   endof
      1  of  0x5F80.9000 m.sd    fselem-same   endof
      2  of  0x2E20.DC00 m.v#sd  fv3same  endof
      3  of  0x1E20.0800 m.sd   fs3same  endof
   endcase
;

: fmulx-try  ( -- )                                      \ fmulx moved to -mix.fth
   4 0 try: case
      0  of  0x2F80.9000 m.v#sd  fvelem-same   endof
      1  of  0x7F80.9000 m.sd    fselem-same   endof
      2  of  0x0E20.DC00 m.v#sd  fv3same  endof
      3  of  0x5E20.DC00 m.sd   fs3same  endof
   endcase
;

