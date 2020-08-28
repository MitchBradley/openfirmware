# Wrapper makefile for Unix: FreeBSD, Linux, etc.
# Copyright 1997 FirmWorks. All rights reserved.

BP=../../..

CROSS	= mips64-linux-gnu-
CC	= $(CROSS)gcc
LD	= $(CROSS)ld
OBJCOPY	= $(CROSS)objcopy

CFLAGS	= -O -g -D__linux__ -DMIPS -DHOSTMIPS
LFLAGS	=

WRDIR = ${BP}/forth/wrapper
ZIPDIR = ${WRDIR}/zip

ZIPOBJS = adler32.o compress.o crc32.o deflate.o inflate.o trees.o zutil.o

OBJS = wrapper.o logger.o ${ZIPOBJS}

all: forth

wrapper.o: ${BP}/forth/wrapper/wrapper.c
	${CC} ${CFLAGS} -c ${BP}/forth/wrapper/wrapper.c

xinflate.lo: ${ZIPDIR}/inflate.c
	${CC} -c ${CFLAGS} -mabi=32 -mfp32 -mips1 -EL -O $< -o $@

xinflate.o: xinflate.lo
	${LD} -T inflate.ld -EL -G0 -N $< -o $@

../build/inflate.bin: xinflate.o
	${OBJCOPY} -O binary $< $@

%.o: ${WRDIR}/%.c
	${CC} -c ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

forth: mipsfth
	@ln -sf mipsfth forth

mipsfth: ${OBJS}
	${CC} $(LFLAGS) -o $@ ${OBJS}

clean:
	@rm -f forth *.o *.lo

install: forth
	cp forth ${BP}/bin/mips/`uname|tr A-Z a-z`/forth
	cp forth ${BP}/bin/mips/`uname|tr A-Z a-z`/mipsfth

dist:
	(cd ${BP}; zip /tmp/wrapper.zip os/unix/mips/makefile ${SRCS})
