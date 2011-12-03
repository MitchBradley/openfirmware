purpose: Common code for fetching and building the NANDblaster support code

\ The macro MCNAND_VERSION must be set externally

" ${MCNAND_VERSION}" expand$ " test" $=  [if]
   " multicast-nand/Makefile" $file-exists?  0=  [if]
      " git clone -q git+ssh://dev.laptop.org/git/users/wmb/multicast-nand" expand$ $sh
   [then]
[else]   
   " rm -rf multicast-nand" $sh
   " wget -q -O - http://dev.laptop.org/git/users/wmb/multicast-nand/snapshot/multicast-nand-${MCNAND_VERSION}.tar.gz | tar xfz -" expand$ $sh
   " mv multicast-nand-${MCNAND_VERSION} multicast-nand" expand$ $sh
[then]

" (cd multicast-nand; make BPDIR=../../../../../.. OFW_CPU=arm nandblaster15_rx.bin nandblaster_tx.bin; cp nandblaster15_rx.bin nandblaster_tx.bin ..)" expand$ $sh

\ This forces the creation of a .log file, so we don't re-fetch
writing mcastnand.version
" ${MCNAND_VERSION}"n" expand$  ofd @ fputs
ofd @ fclose
