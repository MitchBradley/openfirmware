#!/bin/sh
if [ -f .machname ]; then
    MACHNAME=`cat .machname`
else
    MACHNAME=`uname -m`
fi

case ${MACHNAME} in
    sun4*) CPUNAME=sparc ;;
    ppc)   CPUNAME=powerpc ;;
    i*86)  CPUNAME=x86 ;;
    x86*)  CPUNAME=x86 ;;
    mips)  CPUNAME=mips ;;
    arm64*)CPUNAME=arm64 ;;
    arm*)  CPUNAME=arm ;;
    sun3)  CPUNAME=m68k ;;
    *)     CPUNAME=${MACHNAME} ;;
esac

echo ${CPUNAME}
