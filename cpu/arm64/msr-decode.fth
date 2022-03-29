
\ NOTE: DO NOT EDIT THE FOLLOWING TEXT
\ NOTE: The following text comes from an automated script, see msr-gen.pl, msr.txt, and msr-def.fth
\ NOTE: The source text comes from Oban Exception documentation

base @ hex
: reg-encoding-to-$name  ( instr-encoding -- $ )
  case
   c200  of  ( 0,C0,0       )  " SPSR_SVC"          endof  \ EL1 or higher access;  
   c200  of  ( 0,C0,0       )  " SPSR_EL1"          endof  \ EL1 or higher access;  
   c201  of  ( 0,C0,1       )  " ELR_EL1"           endof  \ EL1 or higher access;  
   c208  of  ( 0,C1,0       )  " SP_EL0"            endof  \ EL1 or higher access*;  
   c210  of  ( 0,C2,0       )  " SPSEL"             endof  \ EL1 or higher access;  
   da11  of  ( 3,C2,1       )  " DAIF"              endof  \ EL0 or higher access (configurable for EL0);  
   c212  of  ( 0,C2,2       )  " CURRENTEL"         endof  \ EL1 or higher access (Read Only);  
   da10  of  ( 3,C2,0       )  " NZCV"              endof  \ EL0 or higher access;  
   da20  of  ( 3,C4,0       )  " FPCR"              endof  \ EL0 or higher access;  
   da21  of  ( 3,C4,1       )  " FPSR"              endof  \ EL0 or higher access;  
   da28  of  ( 3,C5,0       )  " DSPSR"             endof  \ EL0 or higher access; debug state only;  
   da29  of  ( 3,C5,1       )  " DLR"               endof  \ EL0 or higher access; debug state only;  
   e200  of  ( 4,C0,0       )  " SPSR_HYP"          endof  \ EL2 or higher access;  
   e200  of  ( 4,C0,0       )  " SPSR_EL2"          endof  \ EL2 or higher access;  
   e201  of  ( 4,C0,1       )  " ELR_EL2"           endof  \ EL2 or higher access;  
   e208  of  ( 4,C1,0       )  " SP_EL1"            endof  \ EL2 or higher access;  
   e218  of  ( 4,C3,0       )  " SPSR_IRQ"          endof  \ EL2 or higher access;  
   e219  of  ( 4,C3,1       )  " SPSR_ABT"          endof  \ EL2 or higher access;  
   e21a  of  ( 4,C3,2       )  " SPSR_UND"          endof  \ EL2 or higher access;  
   e21b  of  ( 4,C3,3       )  " SPSR_FIQ"          endof  \ EL2 or higher access;  
   f200  of  ( 6,C0,0       )  " SPSR_EL3"          endof  \ EL3 or higher access;  
   f201  of  ( 6,C0,1       )  " ELR_EL3"           endof  \ EL3 or higher access;  
   f208  of  ( 6,C1,0       )  " SP_EL2"            endof  \ EL3 or higher access;  
   ea00  of  ( 3,5,c4,c0,0  )  " SPSR_EL12"         endof
   ea01  of  ( 3,5,c4,c0,1  )  " ELR_EL12"          endof
   c000  of  ( 3,0,C0,C0,0  )  " MIDR_EL1"          endof  \ Read-only;  
   d801  of  ( 3,3,C0,C0,1  )  " CTR_EL0"           endof  \ Read-only – configurably EL0 accessible;  
   c005  of  ( 3,0,C0,C0,5  )  " MPIDR_EL1"         endof  \ Read-only;  
   c006  of  ( 3,0,C0,C0,6  )  " REVIDR_EL1"        endof  \ Read-only;  
   d807  of  ( 3,3,C0,C0,7  )  " DCZID_EL0"         endof  \ Read-only - See section 3.11.4.;  
   c008  of  ( 3,0,C0,C1,0  )  " ID_PFR0_EL1"       endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c009  of  ( 3,0,C0,C1,1  )  " ID_PFR1_EL1"       endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c00a  of  ( 3,0,C0,C1,2  )  " ID_DFR0_EL1"       endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c00b  of  ( 3,0,C0,C1,3  )  " ID_AFR0_EL1"       endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c00c  of  ( 3,0,C0,C1,4  )  " ID_MMFR0_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c00d  of  ( 3,0,C0,C1,5  )  " ID_MMFR1_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c00e  of  ( 3,0,C0,C1,6  )  " ID_MMFR2_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c00f  of  ( 3,0,C0,C1,7  )  " ID_MMFR3_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c010  of  ( 3,0,C0,C2,0  )  " ID_ISAR0_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c011  of  ( 3,0,C0,C2,1  )  " ID_ISAR1_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c012  of  ( 3,0,C0,C2,2  )  " ID_ISAR2_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c013  of  ( 3,0,C0,C2,3  )  " ID_ISAR3_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c014  of  ( 3,0,C0,C2,4  )  " ID_ISAR4_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c015  of  ( 3,0,C0,C2,5  )  " ID_ISAR5_EL1"      endof  \ Read-only – is RAZ if AArch32 is not implemented;  
   c018  of  ( 3,0,C0,C3,0  )  " MVFR0_EL1"         endof  \ Read-only - moved for ARMv8;  
   c019  of  ( 3,0,C0,C3,1  )  " MVFR1_EL1"         endof  \ Read-only - moved for ARMv8;  
   c01a  of  ( 3,0,C0,C3,2  )  " MVFR2_EL1"         endof  \ Read-only - moved for ARMv8;  
   c020  of  ( 3,0,C0,C4,0  )  " ID_AA64PFR0_EL1"   endof  \ Read-only;  
   c021  of  ( 3,0,C0,C4,1  )  " ID_AA64PFR1_EL1"   endof  \ Read-only;  
   c028  of  ( 3,0,C0,C5,0  )  " ID_AA64DFR0_EL1"   endof  \ Read-only;  
   c029  of  ( 3,0,C0,C5,1  )  " ID_AA64DFR1_EL1"   endof  \ Read-only;  
   c02c  of  ( 3,0,C0,C5,4  )  " ID_AA64AFR0_EL1"   endof  \ Read-only;  
   c02d  of  ( 3,0,C0,C5,5  )  " ID_AA64AFR1_EL1"   endof  \ Read-only; 
   c030  of  ( 3,0,C0,C6,0  )  " ID_AA64ISAR0_EL1"  endof  \ Read-only;  
   c031  of  ( 3,0,C0,C6,1  )  " ID_AA64ISAR1_EL1"  endof  \ Read-only;  
   c038  of  ( 3,0,C0,C7,0  )  " ID_AA64MMFR0_EL1"  endof  \ Read-only;  
   c039  of  ( 3,0,C0,C7,1  )  " ID_AA64MMFR1_EL1"  endof  \ Read-only;  
   c03a  of  ( 3,0,C0,C7,2  )  " ID_AA64MMFR2_EL1"  endof  \ Read-only;  
   c800  of  ( 3,1,C0,C0,0  )  " CCSIDR_EL1"        endof  \ Read-only;  
   c801  of  ( 3,1,C0,C0,1  )  " CLIDR_EL1"         endof  \ Read-only;  
   c807  of  ( 3,1,C0,C0,7  )  " AIDR_EL1"          endof  \ Read-only;  
   d000  of  ( 3,2,C0,C0,0  )  " CSSELR_EL1"        endof  \  
   e000  of  ( 3,4,C0,C0,0  )  " VPIDR_EL2"         endof  \  
   e005  of  ( 3,4,C0,C0,5  )  " VMPIDR_EL2"        endof  \  
   c080  of  ( 3,0,C1,C0,0  )  " SCTLR_EL1"         endof  \  
   e080  of  ( 3,4,C1,C0,0  )  " SCTLR_EL2"         endof  \  
   f080  of  ( 3,6,C1,C0,0  )  " SCTLR_EL3"         endof  \  
   e880  of  ( 3,5,C1,C0,0  )  " SCTLR_EL12"        endof  \
   c081  of  ( 3,0,C1,C0,1  )  " ACTLR_EL1"         endof  \ IMP DEF registers;  
   e081  of  ( 3,4,C1,C0,1  )  " ACTLR_EL2"         endof  \ IMP DEF registers;  
   f081  of  ( 3,6,C1,C0,1  )  " ACTLR_EL3"         endof  \ IMP DEF registers;  
   c082  of  ( 3,0,C1,C0,2  )  " CPACR_EL1"         endof  \ Only applies to Floating-point and Advanced SIMD;  
   e08a  of  ( 3,4,C1,C1,2  )  " CPTR_EL2"          endof  \ Only applies to Floating-point and Advanced SIMD;  
   f08a  of  ( 3,6,C1,C1,2  )  " CPTR_EL3"          endof  \ Only applies to Floating-point and Advanced SIMD;  
   f088  of  ( 3,6,C1,C1,0  )  " SCR_EL3"           endof  \  
   e088  of  ( 3,4,C1,C1,0  )  " HCR_EL2"           endof  \  
   e089  of  ( 3,4,C1,C1,1  )  " MDCR_EL2"          endof  \  
   f099  of  ( 3,6,C1,C3,1  )  " MDCR_EL3"          endof  \ Note: this has moved from a previous release of this document;  
   e08b  of  ( 3,4,C1,C1,3  )  " HSTR_EL2"          endof  \  
   e08f  of  ( 3,4,C1,C1,7  )  " HACR_EL2"          endof  \ IMP DEF registers;  
   c100  of  ( 3,0,C2,C0,0  )  " TTBR0_EL1"         endof  \  
   c101  of  ( 3,0,C2,C0,1  )  " TTBR1_EL1"         endof  \  
   e100  of  ( 3,4,C2,C0,0  )  " TTBR0_EL2"         endof  \  
   f100  of  ( 3,6,C2,C0,0  )  " TTBR0_EL3"         endof  \  
   e900  of  ( 3,5,C2,C0,0  )  " TTBR0_EL12"        endof  \
   e901  of  ( 3,5,C2,C0,1  )  " TTBR1_EL12"        endof  \
   e108  of  ( 3,4,C2,C1,0  )  " VTTBR_EL2"         endof  \  
   c102  of  ( 3,0,C2,C0,2  )  " TCR_EL1"           endof  \  
   e102  of  ( 3,4,C2,C0,2  )  " TCR_EL2"           endof  \  
   f102  of  ( 3,6,C2,C0,2  )  " TCR_EL3"           endof  \  
   e902  of  ( 3,5,C2,C0,2  )  " TCR_EL12"          endof  \
   e10a  of  ( 3,4,C2,C1,2  )  " VTCR_EL2"          endof  \  
   c288  of  ( 3,0,C5,C1,0  )  " AFSR0_EL1"         endof  \ IMP DEF registers;  
   c289  of  ( 3,0,C5,C1,1  )  " AFSR1_EL1"         endof  \ IMP DEF registers;  
   e288  of  ( 3,4,C5,C1,0  )  " AFSR0_EL2"         endof  \ IMP DEF registers;  
   e289  of  ( 3,4,C5,C1,1  )  " AFSR1_EL2"         endof  \ IMP DEF registers;  
   f288  of  ( 3,6,C5,C1,0  )  " AFSR0_EL3"         endof  \ IMP DEF registers;  
   f289  of  ( 3,6,C5,C1,1  )  " AFSR1_EL3"         endof  \ IMP DEF registers;  
   c290  of  ( 3,0,C5,C2,0  )  " ESR_EL1"           endof  \  
   e290  of  ( 3,4,C5,C2,0  )  " ESR_EL2"           endof  \  
   f290  of  ( 3,6,C5,C2,0  )  " ESR_EL3"           endof  \  
   c300  of  ( 3,0,C6,C0,0  )  " FAR_EL1"           endof  \  
   e300  of  ( 3,4,C6,C0,0  )  " FAR_EL2"           endof  \  
   f300  of  ( 3,6,C6,C0,0  )  " FAR_EL3"           endof  \  
   e304  of  ( 3,4,C6,C0,4  )  " HPFAR_EL2"         endof  \  
   c3a0  of  ( 3,0,C7,C4,0  )  " PAR_EL1"           endof  \  
   c510  of  ( 3,0,C10,C2,0 )  " MAIR_EL1"          endof  \  
   e510  of  ( 3,4,C10,C2,0 )  " MAIR_EL2"          endof  \  
   f510  of  ( 3,6,C10,C2,0 )  " MAIR_EL3"          endof  \  
   ed10  of  ( 3,5,C10,C2,0 )  " MAIR_EL12"         endof  \
   c518  of  ( 3,0,C10,C3,0 )  " AMAIR_EL1"         endof  \  
   e518  of  ( 3,4,C10,C3,0 )  " AMAIR_EL2"         endof  \  
   f518  of  ( 3,6,C10,C3,0 )  " AMAIR_EL3"         endof  \  
   c600  of  ( 3,0,C12,C0,0 )  " VBAR_EL1"          endof  \  
   e600  of  ( 3,4,C12,C0,0 )  " VBAR_EL2"          endof  \  
   f600  of  ( 3,6,C12,C0,0 )  " VBAR_EL3"          endof  \  
   ee00  of  ( 3,5,C12,C0,0 )  " VBAR_EL12"         endof  \
   c601  of  ( 3,0,C12,C0,1 )  " RVBAR_EL1"         endof  \ Read-only – only implemented if EL2 and EL3 are not implemented - see section 5.3;  
   e601  of  ( 3,4,C12,C0,1 )  " RVBAR_EL2"         endof  \ Read-only - only implemented if EL3 is not implemented- see section 5.3;  
   f601  of  ( 3,6,C12,C0,1 )  " RVBAR_EL3"         endof  \ Read-only;  
   c608  of  ( 3,0,C12,C1,0 )  " ISR_EL1"           endof  \ Read-only;  
   c681  of  ( 3,0,C13,C0,1 )  " CONTEXTIDR_EL1"    endof  \  
   de82  of  ( 3,3,C13,C0,2 )  " CPU_GLOBALS"       endof  \ An alias of TPIDR_EL0 to make the code clearer;  
   de83  of  ( 3,3,C13,C0,3 )  " PHLEET_GLOBALS"    endof  \ An alias of TPIDRRO_EL0 to make the code clearer;  
   de82  of  ( 3,3,C13,C0,2 )  " TPIDR_EL0"         endof  \  
   de83  of  ( 3,3,C13,C0,3 )  " TPIDRRO_EL0"       endof  \  
   c684  of  ( 3,0,C13,C0,4 )  " TPIDR_EL1"         endof  \  
   e682  of  ( 3,4,C13,C0,2 )  " TPIDR_EL2"         endof  \  
   f682  of  ( 3,6,C13,C0,2 )  " TPIDR_EL3"         endof  \  
   9000  of  ( 2,2,C0,C0,0  )  " TEECR32_EL1"       endof  \ See section 3.10.7.1; Timer registers;  
   df00  of  ( 3,3,C14,C0,0 )  " CNTFRQ_EL0"        endof  \ Read-only at EL1 – can be written at the highest exception level implemented – configurably EL0 accessible;  
   df01  of  ( 3,3,C14,C0,1 )  " CNTPCT_EL0"        endof  \ Read-only – configurably EL0 accessible;  
   df02  of  ( 3,3,C14,C0,2 )  " CNTVCT_EL0"        endof  \ Read-only – configurably EL0 accessible;  
   e703  of  ( 3,4,C14,C0,3 )  " CNTVOFF_EL2"       endof  \  
   c708  of  ( 3,0,C14,C1,0 )  " CNTKCTL_EL1"       endof  \  
   e708  of  ( 3,4,C14,C1,0 )  " CNTHCTL_EL2"       endof  \  
   df10  of  ( 3,3,C14,C2,0 )  " CNTP_TVAL_EL0"     endof  \ Configurably EL0 accessible;  
   df11  of  ( 3,3,C14,C2,1 )  " CNTP_CTL_EL0"      endof  \ Configurably EL0 accessible;  
   df12  of  ( 3,3,C14,C2,2 )  " CNTP_CVAL_EL0"     endof  \ Configurably EL0 accessible;  
   df18  of  ( 3,3,C14,C3,0 )  " CNTV_TVAL_EL0"     endof  \ Configurably EL0 accessible;  
   df19  of  ( 3,3,C14,C3,1 )  " CNTV_CTL_EL0"      endof  \ Configurably EL0 accessible;  
   df1a  of  ( 3,3,C14,C3,2 )  " CNTV_CVAL_EL0"     endof  \ Configurably EL0 accessible;  
   e710  of  ( 3,4,C14,C2,0 )  " CNTHP_TVAL_EL2"    endof  \  
   e711  of  ( 3,4,C14,C2,1 )  " CNTHP_CTL_EL2"     endof  \  
   e712  of  ( 3,4,C14,C2,2 )  " CNTHP_CVAL_EL2"    endof  \  
   ff10  of  ( 3,7,C14,C2,0 )  " CNTPS_TVAL_EL1"    endof  \ Configurably secure EL1 accessible, otherwise just EL3 accessible;  
   ff11  of  ( 3,7,C14,C2,1 )  " CNTPS_CTL_EL1"     endof  \ Configurably secure EL1 accessible, otherwise just EL3 accessible;  
   ff12  of  ( 3,7,C14,C2,2 )  " CNTPS_CVAL_EL1"    endof  \ Configurably secure EL1 accessible, otherwise just EL3 accessible; The following registers are defined to allow access from AArch64 to registers which are only used in the AArch32 architecture;  
   e180  of  ( 3,4,C3,C0,0  )  " DACR32_EL2"        endof  \ If execution in 64-bit state occurs at EL1 or EL0, this register retains its state, but the value in this register has no effect on execution; If EL1 cannot use AArch32, this register is UNDEFINED;  
   e281  of  ( 3,4,C5,C0,1  )  " IFSR32_EL2"        endof  \ If execution in 64-bit state occurs at EL1 or EL0, this register retains its state, but the value in this register has no effect on;  
   0000  of  (              )  " EXECUTION"         endof  \ If EL1 cannot use AArch32, this register is UNDEFINED;  
   9080  of  ( 2,2,C1,C0,0  )  " TEEHBR32_EL1"      endof  \ If execution in 64-bit state occurs at EL1 or EL0, this register retains its state, but the value in this register has no effect on execution; If EL0 cannot use AArch32, this register is UNDEFINED;  
   f089  of  ( 3,6,C1,C1,1  )  " SDER32_EL3"        endof  \ If execution in 64-bit state occurs at EL1 or EL0, this register retains its state, but the value in this register has no effect on execution; If EL1 cannot use AArch32, this register is UNDEFINED;  
   e298  of  ( 3,4,C5,C3,0  )  " FPEXC32_EL2"       endof  \ If execution in 64-bit state occurs this register retains its state (unless explicitly written in EL2 or EL3), but the value in this register has no effect on execution (other than for explicit reads in EL2 or EL3).; If all exceptions levels cannot use AArch32, this register is UNDEFINED;  
   \ Arm documentation states that implementation specific registers should
   \ be specfied by the syntax: S<op0>_<op1>_<Cn>_<Cm>_<op2>
   \ Note that op2 is a 3 bit field, Cm is a 4 bit field, Cn is a 4 bit field,
   \ op1 is a 3 bit field, and op0 is a 2 bit field.
   push-decimal
   ( reg# ) 0 <#
   ( op2 )  8 base !  # [char] _ hold  d# 10 base !
   ( Cm  )  over h# F land 0 #s  2drop swap 4 >> swap  [char] C hold  [char] _ hold
   ( Cn  )  over h# F land 0 #s  2drop swap 4 >> swap  [char] C hold  [char] _ hold
   ( op1 )  8 base !  # [char] _ hold  d# 10 base !
   ( op0 )  # #>
   ( put a bogus value on the stack to be consumed by endcase) 0
   pop-base
   endcase
;
base !
