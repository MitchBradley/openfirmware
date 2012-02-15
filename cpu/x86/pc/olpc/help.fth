purpose: Basic help for OLPC OFW

warning @ warning off
: help  ( -- )
   blue-letters  ." UPDATES:" cancel  mcr
   ."   flash u:\q2c18.rom              Rewrite the firmware from USB key" mcr
   ."   flash nand:\q2c18.rom           Rewrite the firmware from NAND file" mcr
   ."   copy-nand u:\boot\nand290.img   Rewrite the OS on NAND from USB key" mcr
   blue-letters  ." DIRECTORY LISTING:" cancel  mcr
   ."   dir u:\               List USB key root directory" mcr
   ."   dir u:\boot\          List USB key /boot directory" mcr
   ."   dir nand:\boot\*.rom  List .rom files in NAND FLASH /boot directory" mcr
   blue-letters  ." BOOTING:" cancel  mcr
   ."   boot                  Load the OS from list of default locations" mcr
   ."                         'printenv boot-device' shows the list" mcr
   ."   boot <cmdline>        Load the OS, passing <cmdline> to kernel" mcr
   ."   boot u:\boot\vmlinuz  Load the OS from a specific location" mcr
   blue-letters  ." CONFIGURATION VARIABLES FOR BOOTING:" cancel  mcr
   ."   boot-device  Kernel or boot script path.  Example: nand:\boot\olpc.fth" mcr
   ."   boot-file    Default cmdline.    Example: console=ttyS0,115200" mcr
   ."   ramdisk      initrd pathname.    Example: disk:\boot\initrd.imz" mcr
   blue-letters  ." MANAGING CONFIGURATION VARIABLES:" cancel  mcr
   ."   printenv [ <name> ]     Show configuration variables" mcr
   ."   setenv <name> <value>   Set configuration variable" mcr
   ."   editenv <name>          Edit configuration variable" mcr
   blue-letters  ." DIAGNOSTICS:" cancel  mcr
   ."   test <device-name>      Test device.  Example: test mouse" mcr
   ."   test-all                Test all devices that have test routines" mcr
   blue-letters  ." More information: "  cancel mcr
   green-letters  ." http://wiki.laptop.org/go/OFW_FAQ" cancel  cr
;
warning !
