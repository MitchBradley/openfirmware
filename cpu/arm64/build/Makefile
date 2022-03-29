BASEDIR= $(realpath ../../..)

OS := $(shell uname)
export HOSTDIR= $(realpath ../${OS})
BUILDSH= ${BASEDIR}/forth/lib/build.sh

verbose ?= 0
ifneq ($(strip ${verbose}),0)
export _v =
export _dashv = -v
else
export _v = @
export _dashv =
endif

all: inflate64.bin basefw.dic

.PHONY: all clean

.PRECIOUS: builder.dic

forth arm64forth builder.dic inflate64.bin:
	$(_v)$(MAKE) -C ${HOSTDIR} $@
	$(_v)ln -sf ${HOSTDIR}/$@

build: forth arm64forth builder.dic
	$(_v)ln -sf ${BUILDSH} $@

%.dic: build
	$(_v)./build $(_dashv) $(notdir $@)

# builder.dic.uu:
# This is a free standing rule.  Meaning it exists to allow the easy
# creation of "builder.dic.uu" by the developer.
#
# It allows "make builder.dic.uu" to create a uu file for checking in.
#
# No dependency of builder.dic.uu on builder.dic because of existing
# rule for builder.dic that I do not wish to trigger.

builder.dic.bz2.uu:
	@echo "Creating $(@) from builder.dic"
	@if [ -s builder.dic ]; then\
	    cat builder.dic | bzip2 -9 | uuencode -m -o $@ builder.dic;\
	    test -s $(@) || rm -f $(@) || echo "making $(@) failed";\
	else echo "Missing input file builder.dic"; fi
	@chmod 644 $@
	@ls -l $(@)

# Rule to build fresh builder.dic. Usually we merely want to decode the
# existing builder.dic.uu. Disabled because it creates a circular
# dependency. Can a smarter engineer fix this some day?

#builder.dic: build tools.dic
#	-[ ! -f builder.sav ] && cp builder.dic builder.sav
#	./build builder.dic

clean:
	rm -rf *.dic *.log *~ *.tag *.out *.err *.dSYM \
	    build headers *forth inflate* sessions
	$(MAKE) -C ${HOSTDIR} clean
