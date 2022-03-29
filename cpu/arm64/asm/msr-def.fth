
\ NOTE: The following text originally came from an automated script, see msr-gen.pl, msr.txt, and msr-def.fth
\ NOTE: The source text comes from Oban Exception documentation
\ It is unlikely to be regenerated automatically, and the original values are unlikely to change.

base @ hex
: $reg-name-to-instr-encoding  ( $ -- instr-encoding f | t )
   $case
   \ ARM v8.5
   " RNDR"              $of   ( 3,3,C2,C4,0 )  d920  false  $endof
   " RNDRRS"            $of   ( 3,3,C2,C4,1 )  d921  false  $endof
   " SBSS"              $of   ( 6,2,C4,C3,3 )  da16  false  $endof
   \ ARM v8.4
   " DIT"               $of   ( 3,3,C4,C2,5 )  da15  false  $endof
   \ ARM v8.3
   " APIAKEYLO_EL1"     $of   ( 3,0,C2,C1,0 )  c108  false  $endof
   " APIAKEYHI_EL1"     $of   ( 3,0,C2,C1,1 )  c109  false  $endof
   " APIBKEYLO_EL1"     $of   ( 3,0,C2,C1,2 )  c10a  false  $endof
   " APIBKEYHI_EL1"     $of   ( 3,0,C2,C1,3 )  c10b  false  $endof
   " APDAKEYLO_EL1"     $of   ( 3,0,C2,C2,0 )  c110  false  $endof
   " APDAKEYHI_EL1"     $of   ( 3,0,C2,C2,1 )  c111  false  $endof
   " APDBKEYLO_EL1"     $of   ( 3,0,C2,C2,2 )  c112  false  $endof
   " APDBKEYHI_EL1"     $of   ( 3,0,C2,C2,3 )  c113  false  $endof
   " APGAKEYLO_EL1"     $of   ( 3,0,C2,C3,0 )  c118  false  $endof
   " APGAKEYHI_EL1"     $of   ( 3,0,C2,C3,1 )  c119  false  $endof
   \ ARM v8.2
   " UAO"               $of   ( 3,0,C4,C2,4 )  c214  false  $endof
   \ ARM v8.1
   " PAN"               $of   ( 3,0,C4,C2,3 )  c213  false  $endof   \ EL1 or higher
   \ ARM v8.1 Virtualization Host Extensions
   " SCTLR_EL12"        $of   ( 3,5,C1,C0,0  ) e880  false  $endof
   " TTBR0_EL12"        $of   ( 3,5,C2,C0,0  ) e900  false  $endof
   " TTBR1_EL12"        $of   ( 3,5,C2,C0,1  ) e901  false  $endof
   " TCR_EL12"          $of   ( 3,5,C2,C0,2  ) e902  false  $endof
   " MAIR_EL12"         $of   ( 3,5,C10,C2,0 ) ed10  false  $endof
   " VBAR_EL12"         $of   ( 3,5,C11,C0,0 ) ee00  false  $endof
   " SPSR_EL12"         $of   ( 3,5,C4,C0,0  ) ea00  false  $endof
   " ESR_EL12"          $of   ( 3,5,C4,C0,1  ) ea01  false  $endof
   " ACTLR_EL12"        $of   ( 3,6,C15,C14,6) f7f6  false  $endof
   \ ARM v8.0
   " SPSR_SVC"          $of   ( 0,C0,0       ) c200  false  $endof   \ EL1 or higher 
   " SPSR_EL1"          $of   ( 0,C0,0       ) c200  false  $endof   \ EL1 or higher 
   " ELR_EL1"           $of   ( 0,C0,1       ) c201  false  $endof   \ EL1 or higher 
   " SP_EL0"            $of   ( 0,C1,0       ) c208  false  $endof   \ EL1 or higher; 
   " SPSEL"             $of   ( 0,C2,0       ) c210  false  $endof   \ EL1 or higher 
   " DAIF"              $of   ( 3,C2,1       ) da11  false  $endof   \ EL0 or higher (configurable for EL0); 
   " CURRENTEL"         $of   ( 0,C2,2       ) c212  false  $endof   \ EL1 or higher (Read Only); 
   " NZCV"              $of   ( 3,C2,0       ) da10  false  $endof   \ EL0 or higher 
   " FPCR"              $of   ( 3,C4,0       ) da20  false  $endof   \ EL0 or higher 
   " FPSR"              $of   ( 3,C4,1       ) da21  false  $endof   \ EL0 or higher 
   " DSPSR"             $of   ( 3,C5,0       ) da28  false  $endof   \ EL0 or higher debug state only; 
   " DLR"               $of   ( 3,C5,1       ) da29  false  $endof   \ EL0 or higher debug state only; 
   " SPSR_HYP"          $of   ( 4,C0,0       ) e200  false  $endof   \ EL2 or higher 
   " SPSR_EL2"          $of   ( 4,C0,0       ) e200  false  $endof   \ EL2 or higher 
   " ELR_EL2"           $of   ( 4,C0,1       ) e201  false  $endof   \ EL2 or higher 
   " SP_EL1"            $of   ( 4,C1,0       ) e208  false  $endof   \ EL2 or higher 
   " SPSR_IRQ"          $of   ( 4,C3,0       ) e218  false  $endof   \ EL2 or higher 
   " SPSR_ABT"          $of   ( 4,C3,1       ) e219  false  $endof   \ EL2 or higher 
   " SPSR_UND"          $of   ( 4,C3,2       ) e21a  false  $endof   \ EL2 or higher 
   " SPSR_FIQ"          $of   ( 4,C3,3       ) e21b  false  $endof   \ EL2 or higher 
   " SPSR_EL3"          $of   ( 6,C0,0       ) f200  false  $endof   \ EL3 or higher 
   " ELR_EL3"           $of   ( 6,C0,1       ) f201  false  $endof   \ EL3 or higher 
   " SP_EL2"            $of   ( 6,C1,0       ) f208  false  $endof   \ EL3 or higher 
   " MIDR_EL1"          $of   ( 3,0,C0,C0,0  ) c000  false  $endof   \ Read-only; 
   " CTR_EL0"           $of   ( 3,3,C0,C0,1  ) d801  false  $endof   \ Read-only – configurably EL0 accessible; 
   " MPIDR_EL1"         $of   ( 3,0,C0,C0,5  ) c005  false  $endof   \ Read-only; 
   " REVIDR_EL1"        $of   ( 3,0,C0,C0,6  ) c006  false  $endof   \ Read-only; 
   " DCZID_EL0"         $of   ( 3,3,C0,C0,7  ) d807  false  $endof   \ Read-only - See section 3.11.4.; 
   " ID_PFR0_EL1"       $of   ( 3,0,C0,C1,0  ) c008  false  $endof   \ Read-only   
   " ID_PFR1_EL1"       $of   ( 3,0,C0,C1,1  ) c009  false  $endof   \ Read-only   
   " ID_DFR0_EL1"       $of   ( 3,0,C0,C1,2  ) c00a  false  $endof   \ Read-only   
   " ID_AFR0_EL1"       $of   ( 3,0,C0,C1,3  ) c00b  false  $endof   \ Read-only   
   " ID_MMFR0_EL1"      $of   ( 3,0,C0,C1,4  ) c00c  false  $endof   \ Read-only   
   " ID_MMFR1_EL1"      $of   ( 3,0,C0,C1,5  ) c00d  false  $endof   \ Read-only   
   " ID_MMFR2_EL1"      $of   ( 3,0,C0,C1,6  ) c00e  false  $endof   \ Read-only   
   " ID_MMFR3_EL1"      $of   ( 3,0,C0,C1,7  ) c00f  false  $endof   \ Read-only   
   " ID_ISAR0_EL1"      $of   ( 3,0,C0,C2,0  ) c010  false  $endof   \ Read-only   
   " ID_ISAR1_EL1"      $of   ( 3,0,C0,C2,1  ) c011  false  $endof   \ Read-only   
   " ID_ISAR2_EL1"      $of   ( 3,0,C0,C2,2  ) c012  false  $endof   \ Read-only   
   " ID_ISAR3_EL1"      $of   ( 3,0,C0,C2,3  ) c013  false  $endof   \ Read-only   
   " ID_ISAR4_EL1"      $of   ( 3,0,C0,C2,4  ) c014  false  $endof   \ Read-only   
   " ID_ISAR5_EL1"      $of   ( 3,0,C0,C2,5  ) c015  false  $endof   \ Read-only   
   " MVFR0_EL1"         $of   ( 3,0,C0,C3,0  ) c018  false  $endof   \ Read-only
   " MVFR1_EL1"         $of   ( 3,0,C0,C3,1  ) c019  false  $endof   \ Read-only
   " MVFR2_EL1"         $of   ( 3,0,C0,C3,2  ) c01a  false  $endof   \ Read-only
   " ID_AA64PFR0_EL1"   $of   ( 3,0,C0,C4,0  ) c020  false  $endof   \ Read-only 
   " ID_AA64PFR1_EL1"   $of   ( 3,0,C0,C4,1  ) c021  false  $endof   \ Read-only 
   " ID_AA64DFR0_EL1"   $of   ( 3,0,C0,C5,0  ) c028  false  $endof   \ Read-only 
   " ID_AA64DFR1_EL1"   $of   ( 3,0,C0,C5,1  ) c029  false  $endof   \ Read-only 
   " ID_AA64AFR0_EL1"   $of   ( 3,0,C0,C5,4  ) c02c  false  $endof   \ Read-only 
   " ID_AA64AFR1_EL1"   $of   ( 3,0,C0,C5,5  ) c02d  false  $endof   \ Read-only 
   " ID_AA64ISAR0_EL1"  $of   ( 3,0,C0,C6,0  ) c030  false  $endof   \ Read-only 
   " ID_AA64ISAR1_EL1"  $of   ( 3,0,C0,C6,1  ) c031  false  $endof   \ Read-only 
   " ID_AA64MMFR0_EL1"  $of   ( 3,0,C0,C7,0  ) c038  false  $endof   \ Read-only 
   " ID_AA64MMFR1_EL1"  $of   ( 3,0,C0,C7,1  ) c039  false  $endof   \ Read-only 
   " ID_AA64MMFR2_EL1"  $of   ( 3,0,C0,C7,2  ) c03a  false  $endof   \ Read-only 
   " CCSIDR_EL1"        $of   ( 3,1,C0,C0,0  ) c800  false  $endof   \ Read-only 
   " CLIDR_EL1"         $of   ( 3,1,C0,C0,1  ) c801  false  $endof   \ Read-only 
   " AIDR_EL1"          $of   ( 3,1,C0,C0,7  ) c807  false  $endof   \ Read-only 
   " CSSELR_EL1"        $of   ( 3,2,C0,C0,0  ) d000  false  $endof   \ 
   " VPIDR_EL2"         $of   ( 3,4,C0,C0,0  ) e000  false  $endof   \ 
   " VMPIDR_EL2"        $of   ( 3,4,C0,C0,5  ) e005  false  $endof   \ 
   " SCTLR_EL1"         $of   ( 3,0,C1,C0,0  ) c080  false  $endof   \ 
   " SCTLR_EL2"         $of   ( 3,4,C1,C0,0  ) e080  false  $endof   \ 
   " SCTLR_EL3"         $of   ( 3,6,C1,C0,0  ) f080  false  $endof   \ 
   " ACTLR_EL1"         $of   ( 3,0,C1,C0,1  ) c081  false  $endof   \ 
   " ACTLR_EL2"         $of   ( 3,4,C1,C0,1  ) e081  false  $endof   \ 
   " ACTLR_EL3"         $of   ( 3,6,C1,C0,1  ) f081  false  $endof   \ 
   " CPACR_EL1"         $of   ( 3,0,C1,C0,2  ) c082  false  $endof   \ 
   " CPTR_EL2"          $of   ( 3,4,C1,C1,2  ) e08a  false  $endof   \ 
   " CPTR_EL3"          $of   ( 3,6,C1,C1,2  ) f08a  false  $endof   \ 
   " SCR_EL3"           $of   ( 3,6,C1,C1,0  ) f088  false  $endof   \ 
   " HCR_EL2"           $of   ( 3,4,C1,C1,0  ) e088  false  $endof   \ 
   " MDCR_EL2"          $of   ( 3,4,C1,C1,1  ) e089  false  $endof   \ 
   " MDCR_EL3"          $of   ( 3,6,C1,C3,1  ) f099  false  $endof   \ 
   " HSTR_EL2"          $of   ( 3,4,C1,C1,3  ) e08b  false  $endof   \ 
   " HACR_EL2"          $of   ( 3,4,C1,C1,7  ) e08f  false  $endof   \ 
   " TTBR0_EL1"         $of   ( 3,0,C2,C0,0  ) c100  false  $endof   \ 
   " TTBR0_EL2"         $of   ( 3,4,C2,C0,0  ) e100  false  $endof   \ 
   " TTBR0_EL3"         $of   ( 3,6,C2,C0,0  ) f100  false  $endof   \ 
   " TTBR1_EL1"         $of   ( 3,0,C2,C0,1  ) c101  false  $endof   \ 
   " TTBR1_EL2"         $of   ( 3,4,C2,C0,1  ) e101  false  $endof   \ 
   " VTTBR_EL2"         $of   ( 3,4,C2,C1,0  ) e108  false  $endof   \ 
   " VSTTBR_EL2"        $of   ( 3,4,C2,C6,0  ) e130  false  $endof   \ 
   " TCR_EL1"           $of   ( 3,0,C2,C0,2  ) c102  false  $endof   \ 
   " TCR_EL2"           $of   ( 3,4,C2,C0,2  ) e102  false  $endof   \ 
   " TCR_EL3"           $of   ( 3,6,C2,C0,2  ) f102  false  $endof   \ 
   " VTCR_EL2"          $of   ( 3,4,C2,C1,2  ) e10a  false  $endof   \ 
   " VSTCR_EL2"         $of   ( 3,4,C2,C6,2  ) e132  false  $endof   \ 
   " AFSR0_EL1"         $of   ( 3,0,C5,C1,0  ) c288  false  $endof   \ 
   " AFSR1_EL1"         $of   ( 3,0,C5,C1,1  ) c289  false  $endof   \ 
   " AFSR0_EL2"         $of   ( 3,4,C5,C1,0  ) e288  false  $endof   \ 
   " AFSR1_EL2"         $of   ( 3,4,C5,C1,1  ) e289  false  $endof   \ 
   " AFSR0_EL3"         $of   ( 3,6,C5,C1,0  ) f288  false  $endof   \ 
   " AFSR1_EL3"         $of   ( 3,6,C5,C1,1  ) f289  false  $endof   \ 
   " ESR_EL1"           $of   ( 3,0,C5,C2,0  ) c290  false  $endof   \ 
   " ESR_EL2"           $of   ( 3,4,C5,C2,0  ) e290  false  $endof   \ 
   " ESR_EL3"           $of   ( 3,6,C5,C2,0  ) f290  false  $endof   \ 
   " FAR_EL1"           $of   ( 3,0,C6,C0,0  ) c300  false  $endof   \ 
   " FAR_EL2"           $of   ( 3,4,C6,C0,0  ) e300  false  $endof   \ 
   " FAR_EL3"           $of   ( 3,6,C6,C0,0  ) f300  false  $endof   \ 
   " HPFAR_EL2"         $of   ( 3,4,C6,C0,4  ) e304  false  $endof   \ 
   " PAR_EL1"           $of   ( 3,0,C7,C4,0  ) c3a0  false  $endof   \ 
   " MAIR_EL1"          $of   ( 3,0,C10,C2,0 ) c510  false  $endof   \ 
   " MAIR_EL2"          $of   ( 3,4,C10,C2,0 ) e510  false  $endof   \ 
   " MAIR_EL3"          $of   ( 3,6,C10,C2,0 ) f510  false  $endof   \ 
   " AMAIR_EL1"         $of   ( 3,0,C10,C3,0 ) c518  false  $endof   \ 
   " AMAIR_EL2"         $of   ( 3,4,C10,C3,0 ) e518  false  $endof   \ 
   " AMAIR_EL3"         $of   ( 3,6,C10,C3,0 ) f518  false  $endof   \ 
   " VBAR_EL1"          $of   ( 3,0,C12,C0,0 ) c600  false  $endof   \ 
   " VBAR_EL2"          $of   ( 3,4,C12,C0,0 ) e600  false  $endof   \ 
   " VBAR_EL3"          $of   ( 3,6,C12,C0,0 ) f600  false  $endof   \ 
   " RVBAR_EL1"         $of   ( 3,0,C12,C0,1 ) c601  false  $endof   \ Read-only
   " RVBAR_EL2"         $of   ( 3,4,C12,C0,1 ) e601  false  $endof   \ Read-only
   " RVBAR_EL3"         $of   ( 3,6,C12,C0,1 ) f601  false  $endof   \ Read-only
   " ISR_EL1"           $of   ( 3,0,C12,C1,0 ) c608  false  $endof   \ Read-only
   " CONTEXTIDR_EL1"    $of   ( 3,0,C13,C0,1 ) c681  false  $endof   \ 
   " TPIDR_EL0"         $of   ( 3,3,C13,C0,2 ) de82  false  $endof   \ 
   " TPIDRRO_EL0"       $of   ( 3,3,C13,C0,3 ) de83  false  $endof   \ 
   " TPIDR_EL1"         $of   ( 3,0,C13,C0,4 ) c684  false  $endof   \ 
   " TPIDR_EL2"         $of   ( 3,4,C13,C0,2 ) e682  false  $endof   \ 
   " TPIDR_EL3"         $of   ( 3,6,C13,C0,2 ) f682  false  $endof   \ 
   " TEECR32_EL1"       $of   ( 2,2,C0,C0,0  ) 9000  false  $endof   \ See section 3.10.7.1
   " CNTFRQ_EL0"        $of   ( 3,3,C14,C0,0 ) df00  false  $endof   \ Read-only 
   " CNTPCT_EL0"        $of   ( 3,3,C14,C0,1 ) df01  false  $endof   \ Read-only 
   " CNTVCT_EL0"        $of   ( 3,3,C14,C0,2 ) df02  false  $endof   \ Read-only 
   " CNTVOFF_EL2"       $of   ( 3,4,C14,C0,3 ) e703  false  $endof   \ 
   " CNTKCTL_EL1"       $of   ( 3,0,C14,C1,0 ) c708  false  $endof   \ 
   " CNTHCTL_EL2"       $of   ( 3,4,C14,C1,0 ) e708  false  $endof   \ 
   " CNTP_TVAL_EL0"     $of   ( 3,3,C14,C2,0 ) df10  false  $endof   \  
   " CNTP_CTL_EL0"      $of   ( 3,3,C14,C2,1 ) df11  false  $endof   \  
   " CNTP_CTL_EL02"     $of   ( 3,5,C14,C2,1 ) ef11  false  $endof   \ 
   " CNTP_CVAL_EL0"     $of   ( 3,3,C14,C2,2 ) df12  false  $endof   \  
   " CNTV_TVAL_EL0"     $of   ( 3,3,C14,C3,0 ) df18  false  $endof   \  
   " CNTV_CTL_EL0"      $of   ( 3,3,C14,C3,1 ) df19  false  $endof   \  
   " CNTV_CVAL_EL0"     $of   ( 3,3,C14,C3,2 ) df1a  false  $endof   \  
   " CNTHP_TVAL_EL2"    $of   ( 3,4,C14,C2,0 ) e710  false  $endof   \ 
   " CNTHP_CTL_EL2"     $of   ( 3,4,C14,C2,1 ) e711  false  $endof   \ 
   " CNTHP_CVAL_EL2"    $of   ( 3,4,C14,C2,2 ) e712  false  $endof   \ 
   " CNTPS_TVAL_EL1"    $of   ( 3,7,C14,C2,0 ) ff10  false  $endof   \ 
   " CNTPS_CTL_EL1"     $of   ( 3,7,C14,C2,1 ) ff11  false  $endof   \ 
   " CNTPS_CVAL_EL1"    $of   ( 3,7,C14,C2,2 ) ff12  false  $endof   \ 
   \ The following registers are defined to allow access from AArch64 to registers which are only used in the AArch32 architecture
   " DACR32_EL2"        $of   ( 3,4,C3,C0,0  ) e180  false  $endof   \ 
   " IFSR32_EL2"        $of   ( 3,4,C5,C0,1  ) e281  false  $endof   \ 
   " TEEHBR32_EL1"      $of   ( 2,2,C1,C0,0  ) 9080  false  $endof   \ 
   " SDER32_EL3"        $of   ( 3,6,C1,C1,1  ) f089  false  $endof   \ 
   " FPEXC32_EL2"       $of   ( 3,4,C5,C3,0  ) e298  false  $endof   \ 
  true -rot    \ " A special register [NOTE: This code should attempt to encode op0,op1,Cn,Cm,op2 values but doesn't]"
  $endcase
;
base !
' $reg-name-to-instr-encoding is $special-reg-encoding
