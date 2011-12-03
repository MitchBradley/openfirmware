purpose: Common code for building the "prefw.dic" intermediate dictionary

hex
\ ' $report-name is include-hook
' noop is include-hook

: headerless ;  : headers  ;  : headerless0 ;

' (quit) to quit

: \Tags [compile] \  ; immediate
: \NotTags [compile] \  ; immediate

def-load-base ' load-base set-config-int-default

true ' fcode-debug? set-config-int-default

[ifdef] serial-console
" com1" ' output-device set-config-string-default
" com1" ' input-device set-config-string-default
[then]

fload ${BP}/ofw/core/memlist.fth	\ Resource list common routines
fload ${BP}/ofw/core/showlist.fth	\ Linked list display tool

\ Memory management services
[ifdef] virtual-mode
fload ${BP}/ofw/core/clntmem1.fth	\ client services for memory
[else]
fload ${BP}/ofw/core/clntphy1.fth	\ client services for memory
defer page-table-va
: >physical  ( va -- pa )
   dup  d# 20 rshift             ( va section-index )
   page-table-va swap la+  l@    ( va pte )
   h# fffff invert and           ( va pa-base )
   swap h# fffff and  or         ( pa )
;
[then]

fload ${BP}/cpu/arm/mmp2/rootnode.fth	\ Root node mapping - physical mode

fload ${BP}/ofw/core/allocph1.fth	\ S Physical memory allocator
fload ${BP}/ofw/core/availpm.fth	\ Available memory list

dev /
   " olpc,XO-1.75" model
   " OLPC" encode-string  " architecture" property
\ The clock frequency of the root bus may be irrelevant, since the bus is internal to the SOC
\    d# 1,000,000,000 " clock-frequency" integer-property
device-end

: (cpu-arch  ( -- adr len )
   " architecture" ['] root-node  get-package-property  drop
   get-encoded-string
;
' (cpu-arch to cpu-arch

[ifndef] virtual-mode
fload ${BP}/cpu/arm/mmp2/mmuon.fth
[then]
fload ${BP}/cpu/arm/olpc/probemem.fth	\ Memory probing

stand-init: Probing memory
   " probe" memory-node @ $call-method
;

[ifdef] virtual-mode
fload ${BP}/cpu/arm/loadvmem.fth	\ /mmu node
stand-init: MMU
   " /mmu" open-dev mmu-node !
;
fload ${BP}/ofw/core/initdict.fth	\ Dynamic dictionary allocation
fload ${BP}/arch/arm/loadarea.fth	\ Allocate and map program load area
[then]

\ XXX should be elsewhere
dev /client-services
: chain  ( len args entry size virt -- )
   release                                       ( len args entry )
   h# 8000 alloc-mem h# 8000 +  (init-program)   ( len args )
   to r1  to r2
   go
;
device-end

fload ${BP}/cpu/arm/crc32.fth		\ Assembly language Zip CRC calculation
fload ${BP}/forth/lib/crc32.fth		\ High-level portion of CRC calculation

[ifdef] resident-packages

\needs unix-seconds>  fload ${BP}/ofw/fs/unixtime.fth	\ Unix time calculation
support-package: ext2-file-system
   fload ${BP}/ofw/fs/ext2fs/ext2fs.fth	\ Linux file system
end-support-package

[ifdef] jffs2-support
\needs unix-seconds>  fload ${BP}/ofw/fs/unixtime.fth	\ Unix time calculation
support-package: jffs2-file-system
   fload ${BP}/ofw/fs/jffs2/jffs2.fth	\ Journaling flash file system 2
end-support-package
[then]

support-package: zip-file-system
   fload ${BP}/ofw/fs/zipfs.fth		\ Zip file system
end-support-package
[then]

fload ${BP}/ofw/core/osfile.fth		\ For testing

\ Load file format handlers

: call32 ;

fload ${BP}/ofw/core/allocsym.fth    \ Allocate memory for symbol table
fload ${BP}/ofw/core/symcif.fth
fload ${BP}/ofw/core/symdebug.fth
: release-load-area  ( boundary-adr -- )  drop  ;

[ifdef] use-elf
fload ${BP}/ofw/elf/elf.fth
fload ${BP}/ofw/elf/elfdebug.fth
[ifdef] virtual-mode
\ Depends on the assumption that physical memory is mapped 1:1 already
: (elf-map-in) ( va size -- )  0 mem-claim  drop  ;
[else]
: (elf-map-in)  ( va size -- )  2drop  ;
[then]
' (elf-map-in) is elf-map-in
[then]

\ Reboot and re-entry code
fload ${BP}/ofw/core/reboot.fth		\ Restart the client program
fload ${BP}/ofw/core/reenter.fth	\ Various entries into Forth

headerless
[ifdef] virtual-mode
: (initial-heap)  ( -- adr len )  sp0 @ ps-size -  dict-limit  tuck -  ;
[else]
   \ : (initial-heap)  ( -- adr len )  RAMtop heap-size  ;
: (initial-heap)  ( -- adr len )  limit heap-size  ;
[then]
' (initial-heap) is initial-heap
headers

" /openprom" find-device
   " FirmWorks,3.0" encode-string " model" property
device-end

[ifdef] virtual-mode
fload ${BP}/cpu/arm/mmusetup.fth	\ Initial values for MMU lists
[then]

: background-rgb  ( -- r g b )  h# ff h# ff h# ff  ;

fload ${BP}/forth/lib/selstr.fth

fload ${BP}/cpu/arm/mmp2/socregs.fth   \ MMP2 registers used by many functional units

fload ${BP}/cpu/arm/mmp2/hash.fth      \ Hashes - SHA1, SHA-256, MD5
fload ${BP}/cpu/x86/pc/olpc/crypto.fth \ Cryptographic image validation
fload ${BP}/cpu/x86/pc/olpc/lzip.fth   \ Access zip images from memory

fload ${BP}/ofw/inet/loadtcp.fth

support-package: http
   fload ${BP}/ofw/inet/http.fth	\ HTTP client
end-support-package

support-package: cifs
   fload ${BP}/ofw/fs/cifs/loadpkg.fth
end-support-package
devalias smb tcp//cifs
devalias cifs tcp//cifs
: op  " select smb:\\test:testxxx@10.20.0.14\XTest\hello.txt" eval ;
: dsmb  " dir smb:\\test:testxxx@10.20.0.14\XTest\" eval ;

fload ${BP}/ofw/wifi/wifi-cfg.fth
support-package: supplicant
fload ${BP}/ofw/wifi/loadpkg.fth
end-support-package

: olpc-ssids  ( -- $ )  " OLPCOFW"  ;
' olpc-ssids to default-ssids

fload ${BP}/ofw/inet/sntp.fth
: olpc-ntp-servers  ( -- )
   " DHCP time 172.18.0.1 0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org"
;
' olpc-ntp-servers to ntp-servers
: ntp-time&date  ( -- s m h d m y )
   ntp-timestamp  abort" Can't contact NTP server"
   ntp>time&date
;
: .clock  ( -- )
   time&date .date space .time  ."  UTC" cr
;
: ntp-set-clock  ( -- )
   ntp-time&date  " set-time"  clock-node @ $call-method
   .clock
;

[ifdef] use-ppp
fload ${BP}/ofw/ppp/loadppp.fth
[then]

" dhcp" ' ip-address  set-config-string-default

fload ${BP}/ofw/gui/bmptools.fth
fload ${BP}/dev/null.fth
fload ${BP}/ofw/core/bailout.fth

true ' local-mac-address? set-config-int-default
[ifdef] resident-packages
support-package: nfs
   fload ${BP}/ofw/fs/nfs/loadpkg.fth
end-support-package
[then]
devalias nfs net//obp-tftp:last//nfs

\ This helps with TeraTerm, which sends ESC-O as the arrow key prefix
also hidden also keys-forth definitions
warning @  warning off
: esc-o  key lastchar !  [""] esc-[ do-command  ;
warning !
previous previous definitions

\ GUI
false value gui-safeboot?

: 2tuck  ( d1 d2 -- d2 d1 d2 )  2swap 2over  ;
false value fru-test?
: user-ok  "ok"  ;  \ This is supposed to check for authorization
true value user-mode?

fload ${BP}/ofw/gui/loadmenu.fth
\ fload ${BP}/ofw/gui/insticon.fth

\ Uninstall the diag menu from the general user interface vector
\ so exiting from emacs doesn't invoke the diag menu.
' quit to user-interface

tag-file @ fclose  tag-file off

.( --- Saving prefw.dic ...)
" prefw.dic" $save-forth cr
