# Wrapper makefile for arm64 on Darwin/iOS

BP = $(realpath ../../..)

CC := clang

# Flags for the OS and CPU
CFLAGS = -g -DARM64 -arch arm64 -Wall -Werror

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
INFLATEBIN = inflate64.bin
# Flags for standalone pure-text inflate.bin
NOMMU_INFFLAGS = -mno-unaligned-access -mno-implicit-float -mstrict-align \
                 -mno-global-merge -fno-merge-all-constants
INFFLAGS = -e _inflate -Wl,-preload -ffreestanding -nostartfiles -fno-builtin \
           -nodefaultlibs -fno-stack-protector ${NOMMU_INFFLAGS}
endif

verbose ?= 0
ifneq ($(strip ${verbose}),0)
export _v =
else
export _v = @
endif

all: forth arm64forth ${INFLATEBIN}

# Here uudecode builder.dic (encoded because problems checking in binary files)
#
# builder.dic would/should be checked in, so it only needs decoding once -
# when a new encoded version is delivered.
#
# While decoding it is a once off and is *not* platform specific, this rule
# is future parallel build safe.
#
# To make a new encoded file, run "make builder.dic.uu" in the ../x64/build directory to make a .uu file

builder.dic: ../build/builder.dic.bz2.uu
	$(_v)echo "--- Rebuilding $(@)"
	$(_v)if [  -s $(@) ]; then echo "--- $(@).uu is newer";fi
	$(_v)_TMP=$(@)_tmp.$$$$;	\
	uudecode -p $< | bzcat > $${_TMP}; \
	test -s $${_TMP} && mv $${_TMP}  $(@)

forth: arm64forth
	$(_v)ln -sf $< $@

# ARM64 simulator wrapper build rules

ARM64CFLAGS = -g -DARM64SIM -DARM64 -DSIMNEXT -O3
ARM64DIR = ${BP}/cpu/arm64
ARM64SRCS = ${ARM64DIR}/arm64sim.c ${WRSRCS} ${ZIPSRCS}

arm64forth: ${ARM64SRCS}
	$(_v)${CC} ${ARM64CFLAGS} -o $@ ${ARM64SRCS}

$(INFLATEBIN): inflate
	$(_v)segedit $< -extract __TEXT __text $@

inflate: ${ZIPDIR}/inflate.c Makefile
	$(_v)${CC} ${CFLAGS} ${INFFLAGS} -o $@ $<

clean:
	$(_v)rm -f *forth *.o *~
	$(_v)rm -rf inflate* *.dic *.dSYM
	$(_v)rm -f *.out *.err
	$(_v)rm -rf sessions
