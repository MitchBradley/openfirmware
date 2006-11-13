\ ========== Copyright Header Begin ==========================================
\ 
\ Hypervisor Software File: probescsi.fth
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
purpose: Implements probe-scsi and probe-scsi-all commands
copyright: Copyright 1990-2000, 2003 Sun Microsystems, Inc.  All Rights Reserved
copyright: Use is subject to license terms.

headers

: probe-scsi  ( -- )
   " scsi"  " show-children"  execute-device-method drop
;

headerless

: scsi-children  ( -- )
   \ Ignore nodes that do not have device_type = scsi or scsi-2
   " device_type" get-property  if  exit  then        ( adr len )
   get-encoded-string  2dup " scsi" $=                ( adr,len flag )
   >r " scsi-2" $= r>  or  if                         (  )
      " show-children" method-name 2!  do-method?     (  )
   then
;

: reset-scsi-children  ( -- )
   \ Ignore nodes that do not have device_type = scsi or scsi-2
   " device_type" get-property  if  exit  then        ( adr len )
   get-encoded-string  2dup " scsi" $=                ( adr,len flag )
   >r " scsi-2" $= r>  or  if                         (  )
      " reset" method-name 2!  do-method?     (  )
   then
;

headers

: probe-scsi-all ( -- )
   optional-arg-or-/$  ['] scsi-children  scan-subtree
;

: reset-scsi-all ( -- )
   " /pci" ['] reset-scsi-children  scan-subtree
;
