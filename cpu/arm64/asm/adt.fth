\ register abstract data types

\ there are getting to be a lot of these
\ now encoding register type and size in separate fields

hex

0 value rd-adt
0 value rn-adt
0 value rm-adt
0 value ra-adt

: adt>mask   ( adt -- bits )   00ff.ffff.ffff.ffff and  ;
: rd-mask   ( -- mask )   rd-adt adt>mask  ;
: rn-mask   ( -- mask )   rn-adt adt>mask  ;
: rm-mask   ( -- mask )   rm-adt adt>mask  ;
: ra-mask   ( -- mask )   ra-adt adt>mask  ;


\ Each instruction supports a different set of addressing modes
\ and allows a different subset of register types.
\ Encode the allowed registers for each mode as a bitmap.
\ We can OR several types together to represent the allowed types
\ for a particular instruction.

alias == constant

\ register or element size
\ 0001 == b
\ 0002 == h
\ 0004 == s
\ 0008 == d
\ 0010 == q
\ leave a few bits for later growth just in case...

\ 0001 == m..b
\ 0002 == m..h
\ 0004 == m..s
\ 0008 == m..d
\ 0010 == m..q

\ 0003 == m..bh
\ 0007 == m..bhs
\ 000c == m..sd
\ 000e == m..hsd
\ 000f == m..bhsd

\ vector length
\ 0000 == unspecified
\ 0100 == 1
\ 0200 == 2
\ 0400 == 4
\ 0800 == 8
\ 1000 == 16

\ so some allowed cases are
\ 1001 == 16b
\ 0404 == 4s

\ higher bits indicate register type

: adt>reg    ( adt -- sz )   0xffff andc  ;
: adt>len    ( adt -- sz )   0xff00 and  ;
: adt>size   ( adt -- sz )   0x003f and  ;
: adt>reg,len,size   ( adt -- reg len size )   dup adt>reg  swap dup adt>len  swap adt>size  ;
: adt?    ( adt mask -- match? )
   >r adt>reg,len,size r> adt>reg,len,size  ( ar al as mr ml ms )
   \ same reg type?
   2>r -rot 2>r and 0= if  2r> 2r> 4drop false exit  then
   \ same reg size?
   2r> 2r> rot 2dup or 0<> -rot and 0= and if   2drop false exit  then   ( al ml )
   \ same reg len?
   2dup or 0= if   2drop true  exit  then
   and 0<>
;

\ gpr
1.0004 == m.w
1.0008 == m.x

m.w m.x or == m.wx   \ this mask accepts either m.w or m.x

\ scalars
2.0001 == m.b
2.0002 == m.h
2.0004 == m.s
2.0008 == m.d
2.0010 == m.q
2.0020 == m.v

m.b m.h or == m.bh
m.h m.s or == m.hs
m.s m.d or == m.sd

m.bh m.s or == m.bhs
m.hs m.d or == m.hsd
m.d m.q or m.v or == m.dqv

m.bh m.sd or == m.bhsd
m.bhsd m.q or == m.bhsdq
m.bhs m.dqv or == m.bhsdqv
m.bhsdqv m.wx or == m.wxbhsd
m.bhsdqv m.wx or == m.wxbhsdqv

\ vector elements
\ 4.0000 == m.v       \ XXX   m.d m.q or == m.v ???
4.0001 == m.v.b
4.0002 == m.v.h
4.0004 == m.v.s
4.0008 == m.v.d
4.0010 == m.v.q

m.v.b m.v.h or == m.v.bh
m.v.b m.v.d or == m.v.bd
m.v.h m.v.s or == m.v.hs
m.v.s m.v.d or == m.v.sd
m.v.d m.v.q or == m.v.dq
m.v.bh m.v.s or == m.v.bhs
m.v.h m.v.sd or == m.v.hsd
m.v.bh m.v.sd or == m.v.bhsd
m.v.bhsd m.v.q or == m.v.bhsdq

\ vector element counts
4.1001 == m.v.16b
4.0801 == m.v.8b
4.0401 == m.v.4b
4.0802 == m.v.8h
4.0402 == m.v.4h
4.0202 == m.v.2h
4.0404 == m.v.4s
4.0204 == m.v.2s
4.0208 == m.v.2d
4.0108 == m.v.1d
4.0110 == m.v.1q

m.v.8b m.v.16b or == m.v#b
m.v.4h m.v.8h  or == m.v#h
m.v.2s m.v.4s  or == m.v#s
m.v.1d m.v.2d  or == m.v#d
m.v#b m.v#h or == m.v#bh
\ m.v#b m.v#s or == m.v#bs
m.v#b m.v#d or == m.v#bd
m.v#h m.v#s or == m.v#hs
\ m.v#h m.v#d or == m.v#hd
m.v#s m.v#d or == m.v#sd
m.v#bh m.v#s or == m.v#bhs
m.v#hs m.v#d or == m.v#hsd
m.v#bh m.v#sd or == m.v#bhsd
m.v#bhsd m.v.1q or == m.v#bhsdq

m.v.8h m.v.1q or == m.v.8h1q
m.v.4s m.v.2d or == m.v.4s2d
m.v.8h m.v.4s2d or == m.v.8h4s2d

\ increase len if it is non-zero,  or increase size
: raise-reg   ( reg-mask -- reg-mask' )
   \ adt>reg,len,size  -rot over m.v#bhsdq adt? 0= if  rot  then  2* or or
   adt>reg,len,size  over if  swap  then  2* or or
;


\ SVE vector elements
8.0000 == m.z
8.0001 == m.z.b
8.0002 == m.z.h
8.0004 == m.z.s
8.0008 == m.z.d
8.0010 == m.z.q

m.z.b m.z.h or == m.z.bh
m.z.h m.z.s or == m.z.hs
m.z.s m.z.d or == m.z.sd
m.z.bh m.z.s or == m.z.bhs
m.z.h m.z.sd or == m.z.hsd
m.z.bh m.z.sd or == m.z.bhsd
m.z.bhsd m.z.q or == m.z.bhsdq
m.z.h m.z.d or m.z.q or == m.z.hdq

\ predicate vector elements
10.0000 == m.p
10.0001 == m.p.b
10.0002 == m.p.h
10.0004 == m.p.s
10.0008 == m.p.d
10.0010 == m.p.q
\ use these bits for flags
10.4000 == m.p/m
10.8000 == m.p/z

m.p.b m.p.h or == m.p.bh
m.p.h m.p.s or == m.p.hs
m.p.s m.p.d or == m.p.sd
m.p.hs m.p.d or == m.p.hsd
m.p.bh m.p.sd or == m.p.bhsd
m.p.bhsd m.p.q or == m.p.bhsdq

m.p m.p/m or m.p/z or == m.px
m.p m.z or == m.zp
m.p.bhsdq m.z.bhsdq or == m.zp.bhsd

\ SME array elements aka tiles
20.0000 == m.za
20.0001 == m.za.b
20.0002 == m.za.h
20.0004 == m.za.s
20.0008 == m.za.d
20.0010 == m.za.q

m.za.b m.za.h or == m.za.bh
m.za.s m.za.d or == m.za.sd

40.0000 == m.zah
40.0001 == m.zah.b
40.0002 == m.zah.h
40.0004 == m.zah.s
40.0008 == m.zah.d
40.0010 == m.zah.q

m.zah.b m.zah.h or == m.zah.bh
m.zah.s m.zah.d or == m.zah.sd
m.zah.bh m.zah.sd or == m.zah.bhsd
m.zah.bhsd m.zah.q or == m.zah.bhsdq

80.0000 == m.zav
80.0001 == m.zav.b
80.0002 == m.zav.h
80.0004 == m.zav.s
80.0008 == m.zav.d
80.0010 == m.zav.q

m.zav.b m.zav.h or == m.zav.bh
m.zav.s m.zav.d or == m.zav.sd
m.zav.bh m.zav.sd or == m.zav.bhsd
m.zav.bhsd m.zav.q or == m.zav.bhsdq

m.zah.b m.zav.b or == m.zahv.b
m.zah.h m.zav.h or == m.zahv.h
m.zah.s m.zav.s or == m.zahv.s
m.zah.d m.zav.d or == m.zahv.d
m.zah.q m.zav.q or == m.zahv.q

m.zahv.b m.zahv.h or == m.zahv.bh
m.zahv.s m.zahv.d or == m.zahv.sd
m.zahv.bh m.zahv.sd or == m.zahv.bhsd
m.zahv.bhsd m.zahv.q or == m.zahv.bhsdq

100.0000 == m.imm
200.0000 == m.prf


5a00.0000.0000.0000 == adt-empty

: mask>adt   ( m - adt )   adt-empty or  ;
: adt:   ( n -- )   mask>adt constant  ;

m.w    adt: adt-wreg           \ w0, w1, ...,
m.x    adt: adt-xreg           \ x0, x1, ...,
m.b    adt: adt-breg           \ b0, b1, ...,
m.h    adt: adt-hreg           \ h0, h1, ...,
m.s    adt: adt-sreg           \ s0, s1, ...,
m.d    adt: adt-dreg           \ d0, d1, ...,
m.q    adt: adt-qreg           \ q0, q1, ...,
m.v    adt: adt-vreg           \ v0, v1, ...,
m.z    adt: adt-zreg           \ z0, z1, ...,
m.p    adt: adt-preg           \ p0, p1, ...,

m.v.4b   adt: adt-dreg.4b
m.v.2h   adt: adt-dreg.2h

m.v.8b   adt: adt-dreg.8b
m.v.4h   adt: adt-dreg.4h
m.v.2s   adt: adt-dreg.2s
m.v.1d   adt: adt-dreg.1d

m.v.16b  adt: adt-qreg.16b
m.v.8h   adt: adt-qreg.8h
m.v.4s   adt: adt-qreg.4s
m.v.2d   adt: adt-qreg.2d

m.v.b  adt: adt-Vreg.B     \ for elements eg v0.b[2]
m.v.h  adt: adt-Vreg.H
m.v.s  adt: adt-Vreg.S
m.v.d  adt: adt-Vreg.D

m.imm  adt: adt-immed          \ #immediate_value.
m.prf  adt: adt-prfop          \ Prefetch operation code in Rt

m.p/m  adt: adt-p/m
m.p/z  adt: adt-p/z


: is-adt?    ( n -- adt? )     ff00.0000.0000.0000 and adt-empty =  ;
: reg-adt?   ( 'adt' -- adt? )   dup adt>mask 0<> swap is-adt? and  ;

\ this is only used for X or W
: =?reg  ( adt-code adt-code -- adt-code )
   over <> if   ( adt-code )
      case
	 adt-wreg  of  " a 32 bit (Wn) register" expecting  endof
	 adt-xreg  of  " a 64 bit (Xn) register" expecting  endof
      endcase
   then   ( adt-code )
;

: ??adt-immed   ( imm {adt-imm} -- imm )   dup adt-immed = if  drop  then  ;

