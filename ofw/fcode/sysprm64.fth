\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: sysprm64.fth
\ 
\ Copyright (c) 2006 Sun Microsystems, Inc. All Rights Reserved.
\ 
\  - Do no alter or remove copyright notices
\ 
\  - Redistribution and use of this software in source and binary forms, with 
\    or without modification, are permitted provided that the following 
\    conditions are met: 
\ 
\  - Redistribution of source code must retain the above copyright notice, 
\    this list of conditions and the following disclaimer.
\ 
\  - Redistribution in binary form must reproduce the above copyright notice,
\    this list of conditions and the following disclaimer in the
\    documentation and/or other materials provided with the distribution. 
\ 
\    Neither the name of Sun Microsystems, Inc. or the names of contributors 
\ may be used to endorse or promote products derived from this software 
\ without specific prior written permission. 
\ 
\     This software is provided "AS IS," without a warranty of any kind. 
\ ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, 
\ INCLUDING ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A 
\ PARTICULAR PURPOSE OR NON-INFRINGEMENT, ARE HEREBY EXCLUDED. SUN 
\ MICROSYSTEMS, INC. ("SUN") AND ITS LICENSORS SHALL NOT BE LIABLE FOR 
\ ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
\ DISTRIBUTING THIS SOFTWARE OR ITS DERIVATIVES. IN NO EVENT WILL SUN 
\ OR ITS LICENSORS BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR 
\ FOR DIRECT, INDIRECT, SPECIAL, CONSEQUENTIAL, INCIDENTAL OR PUNITIVE 
\ DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE THEORY OF LIABILITY, 
\ ARISING OUT OF THE USE OF OR INABILITY TO USE THIS SOFTWARE, EVEN IF 
\ SUN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
\ 
\ You acknowledge that this software is not designed, licensed or
\ intended for use in the design, construction, operation or maintenance of
\ any nuclear facility. 
\ 
\ ========== Copyright Header End ============================================
id: @(#)sysprm64.fth 1.2 95/05/09
purpose: FCode token number definitions for system (2-byte) FCodes
copyright: Copyright 1995 Sun Microsystems, Inc.  All Rights Reserved

\ Defined in sysprims.fth
\ v3     02e 2 byte-code: rx@	   ( xaddr -- o )
\ v3     02f 2 byte-code: rx!        ( o xaddr -- )

v3     h# 041 2 byte-code: bxjoin     ( b.lo b.2 b.3 b.4 b.5 b.6 b.7 b.hi -- o )
v3     h# 042 2 byte-code: <l@        ( qaddr -- n )
v3     h# 043 2 byte-code: lxjoin     ( quad.lo quad.hi -- o )
v3     h# 044 2 byte-code: wxjoin     ( w.lo w.2 w.3 w.hi -- o )
v3     h# 045 2 byte-code: x,         ( o -- )
v3     h# 046 2 byte-code: x@         ( xaddr  -- o )
v3     h# 047 2 byte-code: x!         ( o xaddr -- )
v3     h# 048 2 byte-code: /x         ( -- n )
v3     h# 049 2 byte-code: /x*        ( nu1 -- nu2 )
v3     h# 04a 2 byte-code: xa+        ( addr1 index -- addr2 )
v3     h# 04b 2 byte-code: xa1+       ( addr1 -- addr2 )
v3     h# 04c 2 byte-code: xbflip     ( oct1 -- oct2 )
v3     h# 04d 2 byte-code: xbflips    ( xaddr len -- )
v3     h# 04e 2 byte-code: xbsplit    ( o -- b.lo b.2 b.3 b.4 b.5 b.6 b.7 b.hi )
v3     h# 04f 2 byte-code: xlflip     ( oct1 -- oct2 )
v3     h# 050 2 byte-code: xlflips    ( xaddr len -- )
v3     h# 051 2 byte-code: xlsplit    ( o -- quad.lo quad.hi )
v3     h# 052 2 byte-code: xwflip     ( oct1 -- oct2 )
v3     h# 053 2 byte-code: xwflips    ( xaddr len -- )
v3     h# 054 2 byte-code: xwsplit    ( o -- w.lo w.2 w.3 w.hi )
