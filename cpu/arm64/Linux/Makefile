# Wrapper makefile for arm64 on Linux

BP = $(realpath ../../..)

# Flags for the OS and CPU
CC := clang
CFLAGS = -static -O3 -g -target aarch64-linux-gnu -DARM64 \
	 -fno-stack-protector -fno-builtin \
	 -Wall -Wmissing-prototypes

WRTAIL = forth/wrapper
WRDIR = ${BP}/${WRTAIL}
WRFILES = wrapper logger
WRSRCS = $(addsuffix .c,$(addprefix ${WRDIR}/,${WRFILES}))

ifdef OMIT_ZIP
ZIPDIR = ${WRDIR}
ZIPSRCS = ${ZIPDIR}/nullzip.c
INFLATEBIN =
else
ZIPDIR = ${WRDIR}/zip
ZIPFILES = adler32 compress crc32 deflate inflate trees zutil
ZIPSRCS = $(addsuffix .c,$(addprefix ${ZIPDIR}/,${ZIPFILES}))
INFLATEBIN = inflate.bin
# Flags for standalone pure-text inflate.bin
NOMMU_INFFLAGS = -mno-unaligned-access -mstrict-align -fno-merge-all-constants
INFFLAGS = -Wl,-e,inflate -ffreestanding -nostartfiles -nodefaultlibs \
           ${NOMMU_INFFLAGS}
endif

all: forth arm64forth ${INFLATEBIN}

verbose ?= 0
ifneq ($(strip ${verbose}),0)
export _v =
else
export _v = @
endif

# Here uudecode builder.dic (encoded because problems checking in binary files)
#
# builder.dic would/should be checked in, so it inly needs decoding once -
# when a new encoded version is delivered.
#
# While decoding it is a once off and is *not* platform specific, this rule
# is future parallel build safe.
#
# To make a new encoded file, run "make builder.dic.uu" in the ../arm64/build directory to make a .uu file

builder.dic: ../build/builder.dic.bz2.uu
	@echo "--- Rebuilding $@"
	@if [ $@ -nt $< ]; then echo "--- $@ newer than $<"; fi
	$(_v)_TMP=$(@)_tmp.$$$$; \
	uudecode -o - $< | bzcat > $${_TMP}; \
	test -s $${_TMP} && mv $${_TMP}  $(@)

# Use forth when you just need to run Forth but don't care what
# native instruction set it is on.
# Use arm64forth when you need to compile new dictionaries that will
# run on arm64 systems.
forth: ${WRSRCS} ${ZIPSRCS}
	$(_v)${CC} ${CFLAGS} -o $@ ${WRSRCS} ${ZIPSRCS}
	$(_v)ln -sf forth arm64forth

arm64forth: forth

$(INFLATEBIN): inflate
	$(_v)aarch64-linux-gnu-objcopy -O binary -j .text $< $@

inflate: ${ZIPDIR}/inflate.c Makefile
	${CC} ${CFLAGS} ${INFFLAGS} -o $@ $<

clean:
	rm -f *forth *.o *~
	rm -rf inflate* *.dic
	rm -f *.out *.err
	rm -rf sessions
