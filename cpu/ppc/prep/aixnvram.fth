purpose: Handle AIX-specific NVRAM variables
\ See license at end of file

\ AIX expects the NVRAM to contain a global environment variable named
\ "fw-boot-device".  Its value is an AIX-style (ersatz Open Firmware style)
\ pathname which reports the device from which AIX was booted.

\ AIX creates a global environment variable named "fw-boot-path".  Its value
\ is a semicolon-separated list of up to 4 AIX-style pathnames.  The value of
\ this variable is supposed to "override the default firmware boot device
\ list".

\ Here is the list of AIX-style pathname templates given in the AOS 1.2
\ boot requirements specification:
\
\ disk:            /pci@aaaaaaaa/pcivvv,ddd@dd,f [ /xxxxxx@gggg ] /harddisk@h
\ cdrom            /pci@aaaaaaaa/pcivvv,ddd@dd,f [ /xxxxxx@gggg ] /cdrom@h
\
\ For PR*P systems, aaaaaaaa is 80000000
\ vvv,ddd is the PCI vendor,device ID, and dd,f is the PCI device,function #
\ For SCSI disks, pcivvv,ddd@dd,f refers to the SCSI host adapter, and
\ for IDE disks, it refers to the IDE controller.  If the device is on the
\ ISA bus, pcivvv,ddd@dd,f refers to the ISA bridge, and xxxxxx@gggg refers
\ to the adapter on the ISA bus.


: get-int  ( name$ phandle -- int )
   get-package-property  abort" Missing property"  get-encoded-int
;

\ If path$ begins with test$, shorten path$ to exclude that beginning portion
\ and return false.  Otherwise return true.
: peel?  ( path$ test$ -- path$' error? )
   dup >r  2over substring?  if  r> /string false  else  r> drop true  then
;

d# 128 buffer: aix-boot$
: +bs  ( adr len -- )  aix-boot$ $cat  ;
: +nx  ( n -- adr len )  push-hex  <# u#s u#>  pop-base  +bs  ;

: bootpath$  ( -- adr len )
   " /chosen" find-package  drop
   " bootpath" rot get-package-property  if   ( )
      0 0
   else                                       ( prop-adr,len )
      get-encoded-string                      ( path$ )
   then
;

: cdrom?  ( -- flag )
   bootpath$  open-dev  dup 0= abort" Can't open boot device"  >r
   " block-size" r@ ['] $call-method  catch  if   ( x x x )
      3drop false                                 ( flag )
   else                                           ( size )
      d# 2048 =                                   ( flag )
   then                                           ( flag )
   r> close-dev      
;

\ Invents the "fw-boot-device" configuration variable from the "bootpath"
\ property in "/chosen"
\ Example "bootpath"      : /pci/scsi@c/disk@0,0:1
\ Example "fw-boot-device": /pci@80000000/pci1000,1@c,0/harddisk@0,0

: convert-floppy?  ( rem$ -- true | rem$ false )
   " fdc" peel?  if  false exit  then                 ( e.g."@i3f0" )
   " /PNP0700@" +bs                                  
   \ Remove the "@i" from "@i3f0" and append the rest
   2 /string +bs
   " /floppy@0" +bs
   true
;

: convert-disk?  ( rem$ -- true | rem$ false )
   " disk" peel?  if  false exit  then                   ( disk-unit$ )
   cdrom?  if                                            ( disk-unit$ )
      " /cdrom" +bs                                      ( disk-unit$ )
   else                                                  ( disk-unit$ )
      " /harddisk" +bs			                 ( disk-unit$ )
   then                                                  ( disk-unit$ )
   \ e.g. @0,0:1
   [char] : left-parse-string +bs                        ( args$ )
   2drop  true
;

: convert-tape?  ( rem$ -- true | rem$ false )
   " tape" peel?  if  false exit  then                   ( tape-unit$ )
   " /tape" +bs                                          ( tape-unit$ )
   \ e.g. @0,0:1
   [char] : left-parse-string +bs                        ( args$ )
   2drop  true
;

: aix-net-prop ( prop$ env$ -- )
   2>r  " /chosen" find-package drop			( prop$ phandle )
   get-package-property  if  2r> 2drop exit  then	( prop-val,len )
   bounds  do  i c@  loop				( ip0 ip1 ip2 ip3 )
   push-decimal <#  3 0  do
      u#s  [char] . hold  drop
   loop  u#s u#> pop-base				( addr len )
   2r> $setenv
;

: convert-net?  ( rem$ -- true | rem$ false )
   " device_type" bootpath$ find-package drop		( rem$ prop$ ph )
   get-package-property  if  false exit  then		( rem$ prop$ )
   drop cscount " network" $= 0=  if  false exit  then  ( rem$ )
   2drop " :0,0" +bs
   " server-ip"   " ServerIPAddr"   aix-net-prop
   " client-ip"   " ClientIPAddr"   aix-net-prop
   " gateway-ip"  " GatewayIPAddr"  aix-net-prop
   " netmask-ip"  " NetMask"        aix-net-prop
   true
;

: convert-name-tail  ( rem$ -- )
   convert-disk?   if  exit  then
   convert-floppy? if  exit  then
   convert-tape?   if  exit  then
   convert-net?    if  exit  then
   \ convert-ide?  if  exit  then
   ." This firmware release does not know how to convert the name" cr
   ." of a '" type ." ' device to the AIX name."  cr
   abort
;

\ If the input string contains a device node whose name is "pci", split
\ the string into a head component including the pci node and tail
\ component following the pci node.  For example, for the path:
\ 	/dpci@ff000000/pci@b/foo/bar
\ the head string would be "/dpci@ff000000/pci@b" and the tail
\ string would be "foo/bar".

: parse-pci  ( $ -- true | tail$ head$ false )
  2dup                              ( $ tail$ )
  begin  dup  while                 ( $ tail$ )
     [char] /  split-string         ( $ name@adr$ tail$' )
     dup  if  1 /string  then       ( $ name@adr$ tail$'' )
     2swap  [char] @  split-string  ( $ tail$ name$ @adr$ )
     2drop  " pci" $=  if           ( $ tail$ )
        2swap 2 pick - 1-           ( head$ tail$ )
        false exit
     then                           ( $ tail$ )
  repeat
  2drop true
;

0 value pci-phandle

\ Find the PCI bus node within the path string.  Set pci-phandle to the
\ phandle of that node.  Set the aix-boot$ variable to "/pci@nnnnnnnn",
\ where nnnnnnnn is the system bus address of the beginning of PCI I/O space.
\ Return as "tail$" the portion of the path string after the PCI bus node part.

: convert-pci-node  ( path$ -- tail$ )
   parse-pci  if  2drop exit  then                    ( tail$ head$ )
   " /pci@" +bs                                       ( tail$ head$ )
   locate-device  if  2drop exit  then                ( tail$ phandle )
   to pci-phandle                                     ( tail$ )
   " ranges" pci-phandle                              ( tail$ name$ ph )
   get-package-property  if  2drop exit  then         ( tail$ value$ )

   \ Discard the PCI address portion of the first ranges entry
   3 0  do  decode-int drop  loop                     ( tail$ value$' )
   get-encoded-int                                    ( tail$ sysadr )
   push-hex  (u.)  pop-base  +bs                      ( tail$ )
;

: convert-pci-child  ( tail$ -- tail$' )
   begin
      \ Replace the name of the PCI child device with its vendor and device IDs
      [char] / left-parse-string                   ( rem$ dev$ )
      [char] @ split-string                        ( rem$ name$ unit$ )

      pci-phandle  push-package                    ( rem$ name$ unit$ )
      2dup locate-device pop-package  if  2drop exit  then
						   ( rem$ name$ unit$ phandle )

      " /pci" +bs
      " vendor-id" 2 pick get-int  +nx             ( rem$ name$ unit$ phandle )
      " ," +bs                                     ( rem$ name$ unit$ phandle )
      " device-id"  rot   get-int  +nx             ( rem$ name$ unit$ )
      " @" +bs                                     ( rem$ name$ unit$ )

      \ Remove the "@" and any ":" arguments from unit string
      1 /string  [char] : left-parse-string  2nip  ( rem$ name$ unit$' )

      " decode-unit" pci-phandle $call-static-method  nip nip
                                                   ( rem$ name$ phys.hi )

      dup  d# 11 5 bits +nx                        ( rem$ name$ phys.hi )
      " ," +bs                                     ( rem$ name$ phys.hi )
      d# 8 3 bits +nx                              ( rem$ name$ )
      \ Continue through all levels of PCI-PCI bridges, stopping after
      \ converting the first component that is not a PCI-PCI bridge.
   " pci" $= 0=  until                             ( rem$ )
;

: make-boot-name  ( -- )
   bootpath$  dup  if                                    ( str-adr,len )
      0 aix-boot$ c!

      convert-pci-node
      convert-pci-child
      convert-name-tail                                  ( )

      aix-boot$ count  " fw-boot-device" $setenv
   else                                                  ( str-adr,len )
      2drop                                              ( )
   then
;

dev /
new-device

" os" device-name
: open  ( -- okay? )  true  ;
: close  ( -- )  ;

new-device
" aix" device-name

: set-boot$  ( -- pstr )  pwd$ aix-boot$ pack  ;
\ This vocabulary contains words whose names match the name portions of
\ "special" aix pathname components.  To handle an aix pathname component,
\ we first try to match the name portion of the pathname component with a
\ word in this vocabulary.  If that succeeds, we execute that word, which
\ does whatever is necessary to handle that pathname component.  If there
\ is no matching word in this vocabulary, we try to do a "noalias-find-device"
\ with an argument of the form "@uuu", in an attempt to find a node by
\ address alone.  We do it this way because, in general, AIX uses different
\ node names than Open Firmware uses.

vocabulary aix-node-names
also aix-node-names definitions

: PNP0700  ( rem$ address$ -- null-rem$ )
   \ address is e.g. "3f0", rem is e.g. "floppy@0"
   2drop                             ( rem$ )
   " floppy" noalias-find-device     ( rem$ )
   set-boot$ drop                    ( rem$ )

   \ Discard the rest of the path string to avoid processing the
   \ "floppy" component that follows

   drop 0                            ( null-rem$ )
;
: pci  ( address$ -- )  2drop  " pci" noalias-find-device  ;
: harddisk  ( address$ -- )
   " disk" noalias-find-device  set-boot$   ( address$ pstr )
   " @" 2 pick $cat  $cat
;
: cdrom  ( address$ -- )  harddisk  ;
: tape  ( address$ -- )
   " tape" noalias-find-device  set-boot$   ( address$ pstr )
   " @" 2 pick $cat  $cat
;
previous definitions

: aix-heuristic  ( address$ name$ -- )
   2drop  " @" string2 pack  $cat  string2 count  noalias-find-device

   \ If it's a network device, there won't be any more components,
   \ so we copy the path to the string buffer now, and append ":bootp"
   " device_type" get-property  if  exit  then   ( prop$ )
   get-encoded-string  " network" $=  if         ( )
      set-boot$  " :bootp" rot  $cat             ( )
   then
;

: find-aix-node  ( rem$ name$ -- rem$' )
   [char] : left-parse-string 2nip      ( rem$ name@address$ )
   [char] @ left-parse-string           ( rem$ address$ name$ )
   ['] aix-node-names $find-word  if    ( rem$ address$ xt )
      execute                           ( rem$ )
   else                                 ( rem$ address$ name$ )
      aix-heuristic                     ( rem$ )
   then
;

: from-aix-path  ( aix$ -- ofw$ )
   ['] root-node push-package
   " /"  peel?  abort" Unrecognized path"   ( rem$ )
   begin  dup  while                        ( rem$ )
      [char] /  left-parse-string           ( rem$ node$ )
      find-aix-node
   repeat                                   ( rem$ )
   2drop
   aix-boot$ count
   pop-package
;

0 instance value winner

: open  ( -- okay? )
   " fw-boot-path" $getenv  0=  if                    ( pathlist$ )
      begin  dup  while                               ( pathlist$ )
         [char] ; left-parse-string                   ( rem$ aix-path$ )
         from-aix-path                                ( rem$ ofw-path$ )
         open-dev ?dup  if                            ( rem$ ihandle )
            to winner  2drop true exit                ( true )
         then                                         ( rem$ )
      repeat                                          ( null$ )
      2drop                                           ( )
   then                                               ( )
   false
;

: close  ( -- )  winner close-dev  ;

: load  ( adr -- )
   winner ihandle>devname  path-buf place-cstr drop  \ Fix the bootpath value
   " load" winner  $call-method
;

finish-device

finish-device

device-end

devalias aix /os/aix

\ LICENSE_BEGIN
\ Copyright (c) 1996 FirmWorks
\
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END

