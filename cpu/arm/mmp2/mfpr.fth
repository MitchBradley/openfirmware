purpose: Pin multiplexing for ARMADA 610 chip (no board details)

: aib-unlock  
   h# baba h# 68 apbc!  \ Unlock sequence
   h# eb10 h# 6c apbc!
;
: acgr-clocks-on  ( -- )
   h# 0818.F33C acgr-pa io!  \ Turn on all clocks
;

hex
create mfpr-offsets                                         \  GPIOs
   054 w, 058 w, 05C w, 060 w, 064 w, 068 w, 06C w, 070 w,  \   0->7
   074 w, 078 w, 07C w, 080 w, 084 w, 088 w, 08C w, 090 w,  \   8->15
   094 w, 098 w, 09C w, 0A0 w, 0A4 w, 0A8 w, 0AC w, 0B0 w,  \  16->23
   0B4 w, 0B8 w, 0BC w, 0C0 w, 0C4 w, 0C8 w, 0CC w, 0D0 w,  \  24->31
   0D4 w, 0D8 w, 0DC w, 0E0 w, 0E4 w, 0E8 w, 0EC w, 0F0 w,  \  32->39
   0F4 w, 0F8 w, 0FC w, 100 w, 104 w, 108 w, 10C w, 110 w,  \  40->47
   114 w, 118 w, 11C w, 120 w, 124 w, 128 w, 12C w, 130 w,  \  48->55
   134 w, 138 w, 13C w, 280 w, 284 w, 288 w, 28C w, 290 w,  \  56->63
   294 w, 298 w, 29C w, 2A0 w, 2A4 w, 2A8 w, 2AC w, 2B0 w,  \  64->71
   2B4 w, 2B8 w, 170 w, 174 w, 178 w, 17C w, 180 w, 184 w,  \  72->79
   188 w, 18C w, 190 w, 194 w, 198 w, 19C w, 1A0 w, 1A4 w,  \  80->87
   1A8 w, 1AC w, 1B0 w, 1B4 w, 1B8 w, 1BC w, 1C0 w, 1C4 w,  \  88->95
   1C8 w, 1CC w, 1D0 w, 1D4 w, 1D8 w, 1DC w, 000 w, 004 w,  \  96->103
   1FC w, 1F8 w, 1F4 w, 1F0 w, 21C w, 218 w, 214 w, 200 w,  \ 104->111
   244 w, 25C w, 164 w, 260 w, 264 w, 268 w, 26C w, 270 w,  \ 112->119
   274 w, 278 w, 27C w, 148 w, 00C w, 010 w, 014 w, 018 w,  \ 120->127
   01C w, 020 w, 024 w, 028 w, 02C w, 030 w, 034 w, 038 w,  \ 128->135
   03C w, 040 w, 044 w, 048 w, 04C w, 050 w, 008 w, 220 w,  \ 136->143
   224 w, 228 w, 22C w, 230 w, 234 w, 238 w, 23C w, 240 w,  \ 144->151
   248 w, 24C w, 254 w, 258 w, 14C w, 150 w, 154 w, 158 w,  \ 152->159
   250 w, 210 w, 20C w, 208 w, 204 w, 1EC w, 1E8 w, 1E4 w,  \ 160->167
   1E0 w,                                                   \ 168

: gpio>mfpr  ( gpio# -- mfpr-pa )
   mfpr-offsets swap wa+ w@
   h# 01.e000 +
;

: dump-mfprs  ( -- )
   base @
   d# 169 0 do  decimal i 3 u.r space  i gpio>mfpr io@ 4 hex u.r cr  loop
   base !
;

: no-update,  ( -- )  8 w,  ;  \ 8 is a reserved bit; the code skips these
: af@  ( gpio# -- function# )  gpio>mfpr io@  ;
: af!  ( function# gpio# -- )  gpio>mfpr io!  ;

: +edge-clr     ( n -- n' )  h#   40 or  ;
: +medium       ( n -- n' )  h# 1000 or  ;
: +fast         ( n -- n' )  h# 1800 or  ;
: +twsi         ( n -- n' )  h#  400 or  ;
: +pull-up      ( n -- n' )  h# c000 or  ;
: +pull-dn      ( n -- n' )  h# a000 or  ;
: +pull-up-alt  ( n -- n' )  h# 4000 or  ;
: +pull-dn-alt  ( n -- n' )  h# 2000 or  ;

\ We always start with edge detection off; it can be turned on later as needed
: af,   ( n -- )  +edge-clr w,  ;

: sleep-  ( n -- n' )  h# 0200 or  ;
: sleep0  ( n -- n' )  h# 0000 or  ;
: sleep1  ( n -- n' )  h# 0100 or  ;
: sleepi  ( n -- n' )  h# 0080 or  ;
