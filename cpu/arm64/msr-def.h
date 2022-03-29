#define SPSR_SVC          0xc200    /* 0,C0,0       EL1 or higher access;  */
#define SPSR_EL1          0xc200    /* 0,C0,0       EL1 or higher access;  */
#define ELR_EL1           0xc201    /* 0,C0,1       EL1 or higher access;  */
#define SP_EL0            0xc208    /* 0,C1,0       EL1 or higher access*;  */
#define SPSEL             0xc210    /* 0,C2,0       EL1 or higher access;  */
#define DAIF              0xda11    /* 3,C2,1       EL0 or higher access (configurable for EL0);  */
#define CURRENTEL         0xc212    /* 0,C2,2       EL1 or higher access (Read Only);  */
#define NZCV              0xda10    /* 3,C2,0       EL0 or higher access;  */
#define FPCR              0xda20    /* 3,C4,0       EL0 or higher access;  */
#define FPSR              0xda21    /* 3,C4,1       EL0 or higher access;  */
#define DSPSR             0xda28    /* 3,C5,0       EL0 or higher access; debug state only;  */
#define DLR               0xda29    /* 3,C5,1       EL0 or higher access; debug state only;  */
#define SPSR_HYP          0xe200    /* 4,C0,0       EL2 or higher access;  */
#define SPSR_EL2          0xe200    /* 4,C0,0       EL2 or higher access;  */
#define ELR_EL2           0xe201    /* 4,C0,1       EL2 or higher access;  */
#define SP_EL1            0xe208    /* 4,C1,0       EL2 or higher access;  */
#define SPSR_IRQ          0xe218    /* 4,C3,0       EL2 or higher access;  */
#define SPSR_ABT          0xe219    /* 4,C3,1       EL2 or higher access;  */
#define SPSR_UND          0xe21a    /* 4,C3,2       EL2 or higher access;  */
#define SPSR_FIQ          0xe21b    /* 4,C3,3       EL2 or higher access;  */
#define SPSR_EL3          0xf200    /* 6,C0,0       EL3 or higher access;  */
#define ELR_EL3           0xf201    /* 6,C0,1       EL3 or higher access;  */
#define SP_EL2            0xf208    /* 6,C1,0       EL3 or higher access;  */
#define MIDR_EL1          0xc000    /* 3,0,C0,C0,0  Read-only;  */
#define CTR_EL0           0xd801    /* 3,3,C0,C0,1  Read-only – configurably EL0 accessible;  */
#define MPIDR_EL1         0xc005    /* 3,0,C0,C0,5  Read-only;  */
#define MDRAR_EL1         0x8080    /* 2,0,C1,C0,0  Only support read */
#define REVIDR_EL1        0xc006    /* 3,0,C0,C0,6  Read-only;  */
#define DCZID_EL0         0xd807    /* 3,3,C0,C0,7  Read-only - See section 3.11.4.;  */
#define ID_PFR0_EL1       0xc008    /* 3,0,C0,C1,0  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_PFR1_EL1       0xc009    /* 3,0,C0,C1,1  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_DFR0_EL1       0xc00a    /* 3,0,C0,C1,2  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_AFR0_EL1       0xc00b    /* 3,0,C0,C1,3  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_MMFR0_EL1      0xc00c    /* 3,0,C0,C1,4  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_MMFR1_EL1      0xc00d    /* 3,0,C0,C1,5  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_MMFR2_EL1      0xc00e    /* 3,0,C0,C1,6  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_MMFR3_EL1      0xc00f    /* 3,0,C0,C1,7  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_ISAR0_EL1      0xc010    /* 3,0,C0,C2,0  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_ISAR1_EL1      0xc011    /* 3,0,C0,C2,1  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_ISAR2_EL1      0xc012    /* 3,0,C0,C2,2  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_ISAR3_EL1      0xc013    /* 3,0,C0,C2,3  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_ISAR4_EL1      0xc014    /* 3,0,C0,C2,4  Read-only – is RAZ if AArch32 is not implemented;  */
#define ID_ISAR5_EL1      0xc015    /* 3,0,C0,C2,5  Read-only – is RAZ if AArch32 is not implemented;  */
#define MVFR0_EL1         0xc018    /* 3,0,C0,C3,0  Read-only - moved for ARMv8;  */
#define MVFR1_EL1         0xc019    /* 3,0,C0,C3,1  Read-only - moved for ARMv8;  */
#define MVFR2_EL1         0xc01a    /* 3,0,C0,C3,2  Read-only - moved for ARMv8;  */
#define ID_AA64PFRN_EL1   0xc020    /* 3,0,C0,C4,n  Read-only, n in range 0-1;  */
#define ID_AA64DFRN_EL1   0xc028    /* 3,0,C0,C5,n  Read-only, n in range 0-1;  */
#define ID_AA64AFRM_EL1   0xc028    /* 3,0,C0,C5,n  Read-only, n in range 4-5, m=n-4;  */
#define ID_AA64ISARN_EL1  0xc030    /* 3,0,C0,C6,n  Read-only, n in range 0-1;  */
#define ID_AA64MMFRN_EL1  0xc038    /* 3,0,C0,C7,n  Read-only, n in range 0-1;  */
#define CCSIDR_EL1        0xc800    /* 3,1,C0,C0,0  Read-only;  */
#define CLIDR_EL1         0xc801    /* 3,1,C0,C0,1  Read-only;  */
#define AIDR_EL1          0xc807    /* 3,1,C0,C0,7  Read-only;  */
#define CSSELR_EL1        0xd000    /* 3,2,C0,C0,0   */
#define VPIDR_EL2         0xe000    /* 3,4,C0,C0,0   */
#define VMPIDR_EL2        0xe005    /* 3,4,C0,C0,5   */
#define SCTLR_EL1         0xc080    /* 3,0,C1,C0,0   */
#define SCTLR_EL2         0xe080    /* 3,4,C1,C0,0   */
#define SCTLR_EL3         0xf080    /* 3,6,C1,C0,0   */
#define ACTLR_EL1         0xc081    /* 3,0,C1,C0,1  IMP DEF registers;  */
#define ACTLR_EL2         0xe081    /* 3,4,C1,C0,1  IMP DEF registers;  */
#define ACTLR_EL3         0xf081    /* 3,6,C1,C0,1  IMP DEF registers;  */
#define CPACR_EL1         0xc082    /* 3,0,C1,C0,2  Only applies to Floating-point and Advanced SIMD;  */
#define CPTR_EL2          0xe08a    /* 3,4,C1,C1,2  Only applies to Floating-point and Advanced SIMD;  */
#define CPTR_EL3          0xf08a    /* 3,6,C1,C1,2  Only applies to Floating-point and Advanced SIMD;  */
#define SCR_EL3           0xf088    /* 3,6,C1,C1,0   */
#define HCR_EL2           0xe088    /* 3,4,C1,C1,0   */
#define MDCR_EL2          0xe089    /* 3,4,C1,C1,1   */
#define MDCR_EL3          0xf099    /* 3,6,C1,C3,1  Note: this has moved from a previous release of this document;  */
#define HSTR_EL2          0xe08b    /* 3,4,C1,C1,3   */
#define HACR_EL2          0xe08f    /* 3,4,C1,C1,7  IMP DEF registers;  */
#define TTBR0_EL1         0xc100    /* 3,0,C2,C0,0   */
#define TTBR1_EL1         0xc101    /* 3,0,C2,C0,1   */
#define TTBR0_EL2         0xe100    /* 3,4,C2,C0,0   */
#define TTBR0_EL3         0xf100    /* 3,6,C2,C0,0   */
#define VTTBR_EL2         0xe108    /* 3,4,C2,C1,0   */
#define TCR_EL1           0xc102    /* 3,0,C2,C0,2   */
#define TCR_EL2           0xe102    /* 3,4,C2,C0,2   */
#define TCR_EL3           0xf102    /* 3,6,C2,C0,2   */
#define VTCR_EL2          0xe10a    /* 3,4,C2,C1,2   */
#define AFSR0_EL1         0xc288    /* 3,0,C5,C1,0  IMP DEF registers;  */
#define AFSR1_EL1         0xc289    /* 3,0,C5,C1,1  IMP DEF registers;  */
#define AFSR0_EL2         0xe288    /* 3,4,C5,C1,0  IMP DEF registers;  */
#define AFSR1_EL2         0xe289    /* 3,4,C5,C1,1  IMP DEF registers;  */
#define AFSR0_EL3         0xf288    /* 3,6,C5,C1,0  IMP DEF registers;  */
#define AFSR1_EL3         0xf289    /* 3,6,C5,C1,1  IMP DEF registers;  */
#define ESR_EL1           0xc290    /* 3,0,C5,C2,0   */
#define ESR_EL2           0xe290    /* 3,4,C5,C2,0   */
#define ESR_EL3           0xf290    /* 3,6,C5,C2,0   */
#define FAR_EL1           0xc300    /* 3,0,C6,C0,0   */
#define FAR_EL2           0xe300    /* 3,4,C6,C0,0   */
#define FAR_EL3           0xf300    /* 3,6,C6,C0,0   */
#define HPFAR_EL2         0xe304    /* 3,4,C6,C0,4   */
#define PAR_EL1           0xc3a0    /* 3,0,C7,C4,0   */
#define MAIR_EL1          0xc510    /* 3,0,C10,C2,0  */
#define MAIR_EL2          0xe510    /* 3,4,C10,C2,0  */
#define MAIR_EL3          0xf510    /* 3,6,C10,C2,0  */
#define AMAIR_EL1         0xc518    /* 3,0,C10,C3,0  */
#define AMAIR_EL2         0xe518    /* 3,4,C10,C3,0  */
#define AMAIR_EL3         0xf518    /* 3,6,C10,C3,0  */
#define VBAR_EL1          0xc600    /* 3,0,C12,C0,0  */
#define VBAR_EL2          0xe600    /* 3,4,C12,C0,0  */
#define VBAR_EL3          0xf600    /* 3,6,C12,C0,0  */
#define RVBAR_EL1         0xc601    /* 3,0,C12,C0,1 Read-only – only implemented if EL2 and EL3 are not implemented - see section 5.3;  */
#define RVBAR_EL2         0xe601    /* 3,4,C12,C0,1 Read-only - only implemented if EL3 is not implemented- see section 5.3;  */
#define RVBAR_EL3         0xf601    /* 3,6,C12,C0,1 Read-only;  */
#define ISR_EL1           0xc608    /* 3,0,C12,C1,0 Read-only;  */
#define CONTEXTIDR_EL1    0xc681    /* 3,0,C13,C0,1  */
#define CPU_GLOBALS       0xde82    /* 3,3,C13,C0,2 An alias of TPIDR_EL0 to make the code clearer;  */
#define PHLEET_GLOBALS    0xde83    /* 3,3,C13,C0,3 An alias of TPIDRRO_EL0 to make the code clearer;  */
#define TPIDR_EL0         0xde82    /* 3,3,C13,C0,2  */
#define TPIDRRO_EL0       0xde83    /* 3,3,C13,C0,3  */
#define TPIDR_EL1         0xc684    /* 3,0,C13,C0,4  */
#define TPIDR_EL2         0xe682    /* 3,4,C13,C0,2  */
#define TPIDR_EL3         0xf682    /* 3,6,C13,C0,2  */
#define TEECR32_EL1       0x9000    /* 2,2,C0,C0,0  See section 3.10.7.1; Timer registers;  */
#define CNTFRQ_EL0        0xdf00    /* 3,3,C14,C0,0 Read-only at EL1 – can be written at the highest exception level implemented – configurably EL0 accessible;  */
#define CNTPCT_EL0        0xdf01    /* 3,3,C14,C0,1 Read-only – configurably EL0 accessible;  */
#define CNTVCT_EL0        0xdf02    /* 3,3,C14,C0,2 Read-only – configurably EL0 accessible;  */
#define CNTVOFF_EL2       0xe703    /* 3,4,C14,C0,3  */
#define CNTKCTL_EL1       0xc708    /* 3,0,C14,C1,0  */
#define CNTHCTL_EL2       0xe708    /* 3,4,C14,C1,0  */
#define CNTP_TVAL_EL0     0xdf10    /* 3,3,C14,C2,0 Configurably EL0 accessible;  */
#define CNTP_CTL_EL0      0xdf11    /* 3,3,C14,C2,1 Configurably EL0 accessible;  */
#define CNTP_CVAL_EL0     0xdf12    /* 3,3,C14,C2,2 Configurably EL0 accessible;  */
#define CNTV_TVAL_EL0     0xdf18    /* 3,3,C14,C3,0 Configurably EL0 accessible;  */
#define CNTV_CTL_EL0      0xdf19    /* 3,3,C14,C3,1 Configurably EL0 accessible;  */
#define CNTV_CVAL_EL0     0xdf1a    /* 3,3,C14,C3,2 Configurably EL0 accessible;  */
#define CNTHP_TVAL_EL2    0xe710    /* 3,4,C14,C2,0  */
#define CNTHP_CTL_EL2     0xe711    /* 3,4,C14,C2,1  */
#define CNTHP_CVAL_EL2    0xe712    /* 3,4,C14,C2,2  */
#define CNTPS_TVAL_EL1    0xff10    /* 3,7,C14,C2,0 Configurably secure EL1 accessible, otherwise just EL3 accessible;  */
#define CNTPS_CTL_EL1     0xff11    /* 3,7,C14,C2,1 Configurably secure EL1 accessible, otherwise just EL3 accessible;  */
#define CNTPS_CVAL_EL1    0xff12    /* 3,7,C14,C2,2 Configurably secure EL1 accessible, otherwise just EL3 accessible; The following registers are defined to allow access from AArch64 to registers which are only used in the AArch32 architecture;  */
#define DACR32_EL2        0xe180    /* 3,4,C3,C0,0  If execution in 64-bit state occurs at EL1 or EL0, this register retains its state, but the value in this register has no effect on execution; If EL1 cannot use AArch32, this register is UNDEFINED;  */
#define IFSR32_EL2        0xe281    /* 3,4,C5,C0,1  If execution in 64-bit state occurs at EL1 or EL0, this register retains its state, but the value in this register has no effect on;  */
#define EXECUTION         0x0000    /*              If EL1 cannot use AArch32, this register is UNDEFINED;  */
#define TEEHBR32_EL1      0x9080    /* 2,2,C1,C0,0  If execution in 64-bit state occurs at EL1 or EL0, this register retains its state, but the value in this register has no effect on execution; If EL0 cannot use AArch32, this register is UNDEFINED;  */
#define SDER32_EL3        0xf089    /* 3,6,C1,C1,1  If execution in 64-bit state occurs at EL1 or EL0, this register retains its state, but the value in this register has no effect on execution; If EL1 cannot use AArch32, this register is UNDEFINED;  */
#define FPEXC32_EL2       0xe298    /* 3,4,C5,C3,0  If execution in 64-bit state occurs this register retains its state (unless explicitly written in EL2 or EL3), but the value in this register has no effect on execution (other than for explicit reads in EL2 or EL3).; If all exceptions levels cannot use AArch32, this register is UNDEFINED;  */
