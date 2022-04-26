//
// ARM64 Application-level simulator.
//
//
// Copyright (c) 2011 Apple Inc. All rights reserved.
// See license at end.

#ifdef LINUX
#define _GNU_SOURCE
#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <signal.h>
#include <stdarg.h>
#include <ctype.h>
#include <assert.h>
#ifdef LINUX
typedef unsigned long  uintptr_t;
#endif

long s_bye(long code);

#define TP()    do { fprintf(stderr, "%s: %d\n", __FUNCTION__, __LINE__); } while (0)

/*
 * Include the Machine Specific Registers definition file
 */

#include "msr-def.h"

typedef          char       s8;
typedef          short      s16;
typedef          int        s32;
typedef          long long  s64;
typedef unsigned char       u8;
typedef unsigned short      u16;
typedef unsigned int        u32;
typedef unsigned long long  u64;
typedef __int128_t          s128;
typedef __uint128_t         u128;

typedef u64 CELL;
typedef u64 REG;

static int trace = 0;
static int ftrace = 0;
static int mem_wrap = 0;
static int err = 0;
static int quiet = 0;
static int step = 0;
static long int instruction_count = 0;
static long int primitive_instruction_count = 0;  // Instructions executed within primitives
static int no_svc_support = 0;
static int minimal_trace = 0;
static int done = 0;
static REG rp0, sp0, origin;

// u32 instruction;
// u64 last_pc;

#define DIS_NO_OPTIONS         0
#define DIS_YES_REGISTERS      1

// We model the processor as though it has 34 registers
// 0..30 are regular CPU registers.
// 31 is the 0xCAFE_BABE_DEAD_BEEF, it's programming error
// (of the simulator) if it ever crops up in a running program.
// 32 is the SP
// 33 is the PC
// 34 is zero.  We wack r[34] at the beginning of processing
// every instruction so that it will read as 0.  However,
// code must not write then read (in the same instruction processing)
// the zero register else the result may not be a valid 0.

#define LP          22
#define ORG         23
#define UP          24
#define TOS         25
#define RP          26
#define IP          27
#define DSP         28   /* Data Stack Pointer */
#define LR          30
#define SP          32
#define PC          33
#define ZERO        34
#define NUM_REGS    35

u64 r[NUM_REGS];
u64 msr_vbar_el3;
u64 msr_tpidr_el0;
u64 msr_tpidrro_el0;
u64 msr_tpidr_el1;
u64 mon_excl_addr;
u64 mon_excl_valid;

#define rLR r[LR]
#define rSP r[SP]   /* NOTE: NOT THE DATA STACK POINTER */
#define rRP r[RP]
#define rPC r[PC]
#define rUP r[UP]
#define rORG r[ORG]
#define rZERO r[ZERO]
#define rTOS  r[TOS]
#define rIP   r[IP]
#define rDSP  r[DSP]

#define UFIELD(lbit,nbits)  (     (instruction << (31 - (lbit))) >> (32 - (nbits)))
#define SFIELD(lbit,nbits)  ((s32)(instruction << (31 - (lbit))) >> (32 - (nbits)))

#define OP(low,high)    UFIELD(high, (high) - (low) + 1)
#define SXOP(low, high) SFIELD(high, (high) - (low) + 1)
#define OP_B(low)       ((instruction >> (low)) & 1)
#define OP_PAIR(low)    ((instruction >> (low)) & 3)
#define SX(n)           ((s64)((n) << 32) >> 32)

#define R(lbit)    UFIELD((lbit), 5)

#define RD         R(4)
#define RT         RD
#define RN         R(9)
#define RA         R(14)
#define RT2        R(14)
#define RM         R(20)
#define RX(r, x)   (((r) < 31) ? (r) : (x))

#define RDZ      r[RX(RD, ZERO)]
#define RDSP     r[RX(RD, SP)]
#define RDPC     r[RX(RD, PC)]

#define RNZ      r[RX(RN, ZERO)]
#define RNSP     r[RX(RN, SP)]
#define RNPC     r[RX(RN, PC)]

#define RMZ      r[RX(RM, ZERO)]
#define RMSP     r[RX(RM, SP)]
#define RMPC     r[RX(RM, PC)]

#define RAZ      r[RX(RA, ZERO)]

u64 image_start;

int sim_trace(u64 pc, u32 instr);
char *read_dict_name(u32 token, char *buffer);
int strmatch(char *w1, char *w2);
int is_in_dict(u64 ip);
void sim_ftrace(u32 instr);
void simhandler(int sig);
u64 find(u64 org, u32 *link, u64 len, char *adr);
void simulate_init(char *start, long imagesize, long memsize);
void simulate(char *membuf, char *start, char *header, long (*syscall_vec[])(),
     char *memtop, int argc, char **argv);
void sim_unimpl(u32 instruction);
void dump_histogram(void);


/*************************************************************
 *
 * Disassembler
 *
 * We support a disassembler, but all of that is at the end
 * of this file.  Declare functions.
 *
 *************************************************************/

void disassemble(u64 address, u32 instr, int options);
void disassemble_finish(void);
void dis_adr(u64 iaddr, u32 instr);
void dis_add_sub_imm(u64 iaddr, u32 instr);
void dis_logical_imm(u64 iaddr, u32 instr);
void dis_mov_nzk(u64 iaddr, u32 instr);
void dis_bitfield(u64 iaddr, u32 instr);
void dis_extract(u64 iaddr, u32 instr);
void dis_br_imm(u64 iaddr, u32 instr);
void dis_cmp_br_imm(u64 iaddr, u32 instr);
void dis_test_bit_imm(u64 iaddr, u32 instr);
void dis_br_cond_imm(u64 iaddr, u32 instr);
void dis_exception(u64 iaddr, u32 instr);
void dis_system(u64 iaddr, u32 instr);
void dis_br_reg(u64 iaddr, u32 instr);
void dis_load_reg_lit(u64 iaddr, u32 instr);
void dis_ldp(u64 iaddr, u32 instr);
void dis_ldr_post(u64 iaddr, u32 instr);
void dis_ldr_pre(u64 iaddr, u32 instr);
void dis_ldr_reg(u64 iaddr, u32 instr);
void dis_ldr_imm(u64 iaddr, u32 instr);
void dis_ldr_exc(u64 iaddr, u32 instr);
void dis_logical_reg(u64 iaddr, u32 instr);
void dis_add_sub_reg(u64 iaddr, u32 instr);
void dis_add_ext_reg(u64 iaddr, u32 instr);
void dis_adc_sbc(u64 iaddr, u32 instr);
void dis_cond_sel(u64 iaddr, u32 instr);
void dis_dp_3src(u64 iaddr, u32 instr);
void dis_dp_2src(u64 iaddr, u32 instr);
int dis_op_match(char **op_fmt, char *str);
const char *dis_reg_str(int reg_num);
void dis_reg_used(int n, int sz);
int dis_get_used(int idx);
void dis_reg_target(int n, int sz);
int dis_get_target(int idx);
void dis_print_reg_list(int (*reg_list_func)(int idx), const char *eq_str);
int dis_print_reg(u32 instr, char reg_type, int or_sp, int read, int target);
void dis_print(u64 iaddr, u32 instr, char *op_fmt, ...);
void dis_dp_1src(u64 iaddr, u32 instr);

void sim_handle_simulation_request(u32 instruction, u64 request);

struct { s64 imm24:24; } sext24;
struct { s64 imm21:21; } sext21;

union {
    u32 all;
    struct {
    u32 res :28;
    u32 Vbit:1;
    u32 Zbit:1;
    u32 Cbit:1;
    u32 Nbit:1;
    } bits;
} APSR;

#define N       (APSR.bits.Nbit)
#define Z       (APSR.bits.Zbit)
#define C       (APSR.bits.Cbit)
#define V       (APSR.bits.Vbit)

#define F(x)    ((x) & 1)
#define SETFLAGS(nzcv) do { \
    N = F((nzcv) >> 3); \
    Z = F((nzcv) >> 2); \
    C = F((nzcv) >> 1); \
    V = F((nzcv) >> 0); \
    } while (0)

// FIXME: We're skipping the V bit for now.

/* Leave C alone. */
#define UPCC(res) \
{ \
    N = (res) >> 31; \
    Z = ((res) == 0);                                               \
/* FIXME - possible problem with C bit - should be set to carry output from shifter */ \
}

void regdump(u64 pc, u32 instruction, int verbose);

static u8 *mem;
static size_t memsz;

// For disassembly, track the address and size of the last
// memory reference.
static void *mem_addr;
static int mem_addr_sz;
static int print_mem_addr;

static inline void *chk_mem(u64 addr, int size)
{
    if (mem_wrap)
        addr &= (memsz -1);

    return (void *)(uintptr_t)addr;
}

#define MEM(type, adr)      *(type *)(adr)

#define MEMDUMP_CHARS         0x01
#define MEMDUMP_U8S           0x00
#define MEMDUMP_U16S          0x10
#define MEMDUMP_U32S          0x20
#define MEMDUMP_U64S          0x30

void memdump(u64 addr, u32 size, int flags)
{
    while (size > 0) {
	printf("%llx [ %6.6x ]:  ", addr, (u32) (addr - r[ORG]));
	if (flags & MEMDUMP_U32S) {
	    for (int i = 0; i < 16; i+=4) {
		printf("%8.8x ", MEM(u32, addr + i));
	    }
	} else if (flags & MEMDUMP_U16S) {
	    for (int i = 0; i < 16; i+=2) {
		printf("%4.4x ", MEM(u16, addr + i));
	    }
	} else if (flags & MEMDUMP_U64S) {
	    for (int i = 0; i < 16; i+=8) {
		printf("%16.16llx ", MEM(u64, addr + i));
	    }
	} else {
	    for (int i = 0; i < 16; i++) {
		printf("%2.2x ", MEM(u8, addr + i));
	    }
	}
	if (flags & MEMDUMP_CHARS) {
	    printf("   ");
	    for (int i = 0; i < 17; i++) {
		u8 c = MEM(u8, addr + i);
		if (!isprint(c)) c = '.';
		printf("%c", c);
	    }
	}
	addr += 16;
	size -= 16;
	printf("\n");
    }
}

void regdump(u64 pc, u32 instruction, int verbose)
{
    int i, j;
    char *regname[] = {
        " r0", " r1", " r2", " r3", " r4", " r5", " r6", " r7",
        " r8", " r9", "r10", "r11", "r12", "r13", "r14", "r15",
        "r16", "r17", "r18", "r10", "r20", "r21", " lp", "org",
        " up", "tos", " rp", " ip", " sp", "r29", " lr", "r31"
    };

    printf("Instruction count: %ld\n", (primitive_instruction_count + instruction_count));

    if (instruction != -1) {
        disassemble(pc, instruction, DIS_NO_OPTIONS);
    }

    printf("\n");
    if (!verbose)
        return;

    for (i = 0; i < 8; i++) {
        for (j = 0; j < 4; j++) {
            int ri = i * 4 + j;
            printf(" %s  %016llx ", regname[ri], r[ri]);
        }
        printf("\n");
    }
    printf("N%d Z%d C%d V%d\n\n", N, Z, C, V);
    printf("TPIDR_EL0  (PHLEET_GLOBALS)  %016llx\n", msr_tpidr_el0);
    printf("TPIDRRO_EL0   (CPU_GLOBALS)  %016llx\n", msr_tpidrro_el0);
    printf("TPIDR_EL1         (RBM_VAR)  %016llx\n", msr_tpidr_el1);
    printf("VBAR_EL3                     %016llx\n", msr_vbar_el3);
}

// Return 1 if a disaasembly took place, else 0.
// The caller uses this information to determine if a
// call to disassemble_finish() should be issued.

int sim_trace(u64 pc, u32 instr)
{
    if ((pc >= (r[ORG] + 0x100)) && (pc <= (r[ORG] + 0x108))) {
        return 0;
    }

    if (instr == 0xd61f0300) {
        printf("%08llx [ %ld ]: (next)\n", pc, (primitive_instruction_count + instruction_count));
        return 0;
    }

    disassemble(pc, instr, DIS_YES_REGISTERS);

    return 1;
}

char *read_dict_name(u32 token, char *buffer)
{
    u64 cp;
    int len;
    char *p;
    u64 cfa;

    cfa = token + r[ORG];
    cp = (cfa - 5);
    len = MEM(u8, cp) & 31 ;
    p = buffer;
    cp -= len;
    while (len--) {
	*p++ = MEM(u8, cp++);
    }
    *p = '\0';

    return buffer;
}

int strmatch(char *w1, char *w2)
{
    int n1 = strlen(w1);
    int n2 = strlen(w2);
    if (n1 != n2) return 0;
    return strcmp(w1, w2) == 0;
}

int is_in_dict(u64 ip)
{
    if (ip < r[ORG]) return 0;
    if (ip >= r[DSP]) return 0;
    return 1;
}

void sim_ftrace(u32 instr)
{
    u32 token;
    char word[32];

    if (!rPC)
        return;

    if (rPC != r[UP])
        return;

    if (minimal_trace) {
	printf("%ld: ", (primitive_instruction_count + instruction_count));
    } else {
	printf(" i: %ld, .s %16llx %16llx %16llx\t|  ", (primitive_instruction_count + instruction_count), MEM(u64, r[DSP] + 8), MEM(u64, r[DSP]), r[TOS]);

	// Tabify based on stack pointer rdepth
	int depth = (sp0 - r[DSP]) / /* # bytes per cell */ 8;
	int rdepth = (rp0 - r[RP]) / /* # bytes per cell */ 8;

	printf(" <s: %d, r: %d> ", depth, rdepth);
	rdepth = rdepth % 25;
	while (rdepth-- > 0)
	    printf("  ");
    }

    token = MEM(u32, r[IP]);
    read_dict_name(token, word);

    if (minimal_trace) {
	printf("%s\n", word);
	return;
    }

    if (strmatch(word, "unnest")) {
	// Fetch the ip from the return stack and print out the word's
	// name that it points into.  Note that colon definitions
	// start with a branch and link.  That instruction's opcode is
	// 0x97F....  Whereas, all tokens are positive offsets from
	// origin.  So, we can use a signed test to determine if we've found
	// the acf.
	REG ip = MEM(u64, r[RP]);
	while (1) {
	    if (!is_in_dict(ip)) {
		printf("unnest to --unknown--\n");
		return;
	    }

	    if ((MEM(u32, ip) >> 24) == 0x97) {
		// Found what might be a code field
		int i;
		u64 t = ip - 4, cp;
		int ok;

		ok = 1;
		// Check the next 5 header links, do they link together?
		for (i = 0; i < 5; i++) {
		    cp = t - 1;
		    u8 flg = MEM(u8, cp);
		    // if not 0x80, not a flag byte
		    if (!(flg & 0x80)) {
			ok = 0;
			break;
		    }

		    if (!ok) break;

		    cp = t - 1;
		    u8 len = MEM(u8, cp);
		    cp -= len;
		    while (len--) {
			u8 c = MEM(u8, cp++);
			if (!isprint(c)) {
			    ok = 0;
			    break;
			}
		    }

		    if (!ok) break;

		    token = MEM(u32, t);
		    if (token == 0) {
			// Have to accept it ...
			break;
		    }
		    t = token + r[ORG] - 4;
		}

		// OK, I'm convinced this is a code field
		if (ok) break;
	    }

	    ip -= 4;
	}
	token = ip - r[ORG];
	read_dict_name(token, word);
	printf("unnest to %s\n", word);
    } else if (strmatch(word, "(lit)")) {
	u64 n = MEM(u32, r[IP] + 4) | (((u64)MEM(u32,r[IP] + 8)) << 32);
	printf("(lit) 0x%llx   (%lld)\n", n, n);
    } else if (strmatch(word, "(')")) {
	token = MEM(u32, r[IP] + 4);
	read_dict_name(token, word);
	printf("(')  %s\n", word);
    } else if (strmatch(word, "isdefer")) {
	token = MEM(u32, r[IP] + 4);
	read_dict_name(token, word);
	printf("is  %s\n", word);
    } else {
	printf("%s\n", word);
    }
}

#define TRUNK32(a)       ((a) & 0xFFFFFFFF)
#define SEXT32(a)       (((a) & 0x80000000) ? (a) | 0xFFFFFFFF00000000LL : (a))

#define SIGN32(n)    ((n) >> 31)
#define SIGN64(n)    ((n) >> 63)

#define ADC32(dest, ax, bx, cx)                  \
do {                                             \
    u32 _ua = (ax), _ub = (bx), _uc = (cx);      \
    u32 _ut = _ua + _ub + _uc;                   \
    if (setflags) {                              \
        N = SIGN32(_ut);                         \
        Z = _ut == 0;                            \
        C = (_ut < _ua) || (_uc && (_ut == _ua)); \
        V = (SIGN32(_ua) == SIGN32(_ub)) && (SIGN32(_ua) != SIGN32(_ut)); \
    }                                            \
    dest = _ut;                            \
} while (0)

#define ADC64(dest, ax, bx, cx)                  \
do {                                             \
    u64 _ua = (ax), _ub = (bx), _uc = (cx);      \
    u64 _ut = _ua + _ub + _uc;                   \
    if (setflags) {                              \
        N = SIGN64(_ut);                         \
        Z = _ut == 0;                             \
        C = (_ut < _ua) || (_uc && (_ut == _ua)); \
        V = (SIGN64(_ua) == SIGN64(_ub)) && (SIGN64(_ua) != SIGN64(_ut)); \
    }                                            \
    dest = _ut;                                  \
} while (0)

#define UNIMP(s) \
{ \
    printf("UNIMPLEMENTED: %s\n", s); \
    if (!quiet) { \
        regdump(rPC, instruction, 1);       \
    } \
    err = 1; \
    s_bye(-1); \
}
#define UNIMPIF(cond, s) do { if (cond) UNIMP(s) } while (0)

#define EVAL_COND(cc) \
{ \
    switch (cc) { \
    case 0x0:       cond = (Z == 1); break; \
    case 0x1:       cond = (Z == 0); break; \
    case 0x2:       cond = (C == 1); break; \
    case 0x3:       cond = (C == 0); break; \
    case 0x4:       cond = (N == 1); break; \
    case 0x5:       cond = (N == 0); break; \
    case 0x6:       cond = (V == 1); break; \
    case 0x7:       cond = (V == 0); break; \
    case 0x8:       cond = (C == 1 && Z == 0); break; \
    case 0x9:       cond = (C == 0 || Z == 1); break; \
    case 0xa:       cond = (N == V); break; \
    case 0xb:       cond = (N != V); break; \
    case 0xc:       cond = (Z == 0 && N == V); break; \
    case 0xd:       cond = (Z == 1 || N != V); break; \
    case 0xe:       cond = (1); break; \
    case 0xf:       cond = (0xf); break; \
    } \
}

void simhandler(int sig)
{
    psignal(sig, "forth");
    regdump(rPC, MEM(u32, rPC), 1);
    s_bye(1);
}

/***************************************************************************
 *
 * Helper Words for locating the CFA of words in the dictionary
 *
 *
 *
 ***************************************************************************
 */

static void print_word_name(u64 xt)
{
    u8 len = MEM(u8, xt - 5) & 0x1F;
    printf("%*.*s", len, len, (char *) (xt - 5 - len));
}

static char *asprint_word_name(u64 xt)
{
    char *str;
    u8 len = MEM(u8, xt - 5) & 0x1F;
    asprintf(&str, "%*.*s", len, len, (char *) (xt - 5 - len));
    return str;
}

static int is_bl(u32 instr)
{
    if ((instr & 0xFC000000) == 0x94000000) {
	if (instr != 0x94000000) {
	    return 1;
	}
    }

    return 0;
}

static u64 bl_target(u64 pc, u32 instr)
{
    if (!is_bl(instr)) {
	return 0;
    }

    u64 offset = (((instr | 0xFC000000) ^ 0xFFFFFFFF) + 1) << 2;
    u64 target = pc - offset;

    return target;
}

/******************************************************
 *
 * Forth's Wrapper Find
 *
 ******************************************************
 */
// alf = find(adr, len, link, org);
u64
find(u64 org, u32 *link, u64 len, char *adr)
{
    char *np;
    u32 namelen;

    org >>= 2;                  // Scale for (u32 *) math.

    while ((link = (u32 *) (uintptr_t) *link)) {
        link += org;
        link -= 1;              // Move from code field to link field
        np = (char *)link - 1;
        namelen = *(unsigned char *)np & 0x1f;
        if (namelen == len) {
            np -= namelen;
            if (strncmp(np, adr, len) == 0) {
                return (u64)link;
	    }
        }
    }
    return 0LL;
}

u64 create_word(u64 org, u64 voc, u64 link)
{
        return 0;
}

u64 hide_word(u64 org, u64 voc, u64 link)
{
        return 0;
}

u64 reveal_word(u64 org, u64 voc, u64 link)
{
        return 0;
}

// Implement HighestSetBit:
//    If no bits are set, then return -1;
//    Else, return the bit number (starting from 0)
//          of the highest numbered bit in the sequence
static int HighestSetBit(u64 bits)
{
    int n, bitn;

    n = -1;
    bitn = 0;
    while (bits) {
        u64 bit = ((u64)1 << bitn);
        if (bits & bit) {
            bits ^= bit;  // Clear the bit
            n = bitn;
        }

        bitn ++;
    }

    return n;
}

// Create a MASK of one bits n bits long
#define MASK(n) ((n) == 64 ? 0xFFFFFFFFFFFFFFFFULL : ((u64)1 << (n)) - 1)

static u64 ROR(u64 bits, int numbits, int n)
{
    u64 mask = MASK(numbits);
    u64 nlo  = (bits & mask) >> n;
    u64 nhi  = (bits & mask) << (numbits - n);

    return (nlo | nhi) & mask;
}

static u64 ShiftReg(int sf, u64 reg, int type, int amount)
{
    if (sf == 0) {

        switch (type) {
        case 0: return (u32) (reg << amount);
        case 1: return ((u32)reg) >> amount;
        case 2: return ((s32)reg) >> amount;
        case 3: return ROR(reg, 32, amount);
        }

        return 0LL;
    }

    switch (type) {
    case 0: return reg << amount;
    case 1: return reg >> amount;
    case 2: return ((s64)reg) >> amount;
    case 3: return ROR(reg, 64, amount);
    }
    return 0LL;
}

static const char *ShiftStr(int type)
{
    const char *shift_strings[] = {
        "lsl", "lsr", "asr", "ror"
    };

    return shift_strings[type & 3];
}

static u64 Replicate(u64 bits, int numbits, int n)
{
    u64 result = 0;

    bits &= MASK(numbits);
    while (n--) {
        result |= bits << (numbits * n);
    }

    return result;
}

static u64 ExtendReg(u64 reg, int extend_type, int shift)
{
    int sxt = extend_type & 4;
    int len = 64 - (8 << (extend_type & 3));

    reg <<= shift;
    if (sxt)
        return ((s64)(reg << len) >> len);
    else
        return (     (reg << len) >> len);
}

#define MASK32(result, sf)   ((sf) ? (result) : (result) & MASK(32))

static void simone(u32 instr);



typedef void (*ifunc_t)(u32 instruction);

long (**gSyscall_vec)();
#define INITIAL_HEAP 0x80000LL

static void sim_refill(u32 instr);


void sim_next(u32 instruction)
{

    // ldr w0,[ip],#4
    r[0] = MEM(u32, r[IP]);
    r[IP] += 4;

    // add x0, x0, org
    r[0] += r[ORG];

    // br  x0
    r[PC] = r[0];
}



/**************************************
 **************************************/
void simulate_init(char *start, long imagesize, long memsize)
{
    u32 *instructions;

    instructions = (u32 *) start;
    image_start = (u64) start;

}


void
simulate(char *membuf,
     char *start,
     char *header,
     long (*syscall_vec[])(),
     char *memtop,
     int argc,
     char **argv)
{
    if ((sizeof(u64) != 8) ||
        (sizeof(u32) != 4) ||
        (sizeof(long int) != 8)) {
        printf("ERROR: Compiler assumptions about integer sizes are wrong.  Please check.\n");
        s_bye(-1);
    }

    /*
     * If we're running in the simulator on an x86 machine (likely), then
     * char *argv[] is (also likely) an array of 32-bit pointers.
     * The argv handling code in kernel.fth uses na+ to index,
     * which in our case is the native 64-bit cell size. Hence the
     * pointers in argv need to be converted to "long long" from our
     * point of view.
     */
    u64 *llargv = (u64 *)malloc(argc * sizeof(u64));
    int i;
    for (i = 0; i < argc; ++i)
        llargv[i] = (u64)(uintptr_t)(argv[i]);

    signal(SIGBUS, simhandler);
    signal(SIGSEGV, simhandler);

    no_svc_support = 0;  //  All service calls are supported here
    mem = (u8 *)membuf;
#if 0
    printf("membuf %p start %p header %p syscall_vec %p memtop %p argc %d argv %p\n",
       membuf, start, header, syscall_vec, memtop, argc, llargv);
#endif

    // Round down to 32 byte aligned address
    memtop = (void *)((uintptr_t)memtop & ~31);
    APSR.all = 0;
    rPC = (u64)(uintptr_t)start;
    r[0] = -1LL;       // SYS vs. STANDALONE
    r[1] = 0LL;        // No syscall vec; use simulator "svc #n" interface.
    r[2] = (u64)(uintptr_t)memtop;
    r[3] = (u64)argc;
    r[4] = (u64)(uintptr_t)llargv;
    r[5] = INITIAL_HEAP;
    rSP = (u64)(uintptr_t)memtop - 32;  // Make room for 4 more arguments
    gSyscall_vec = syscall_vec;

    while (1) {
        // NOTE: Simulated code terminates by calling
        // the wrapper provided function "exit".
        simone(MEM(u32, rPC));
    }
}

static void sim_adc_sbc(u32 instr);
static void sim_add_sub_imm(u32 instr);
static void sim_add_sub_reg(u32 instr);
static void sim_add_ext_reg(u32 instr);
static void sim_adr(u32 instr);
static void sim_bitfield(u32 instr);
static void sim_br_cond_imm(u32 instr);
static void sim_br_imm(u32 instr);
static void sim_br_reg(u32 instr);
static void sim_cmp_br_imm(u32 instr);
static void sim_cond_sel(u32 instr);
static void sim_dp_1src(u32 instr);
static void sim_dp_2src(u32 instr);
static void sim_dp_3src(u32 instr);
static void sim_exception(u32 instr);
static void sim_extract(u32 instr);
static void sim_ldp(u32 instr);
static void sim_ldr_imm(u32 instr);
static void sim_ldr_exc(u32 instr);
static void sim_ldr_post(u32 instr);
static void sim_ldr_pre(u32 instr);
static void sim_ldr_reg(u32 instr);
static void sim_load_reg_lit(u32 instr);
static void sim_logical_imm(u32 instr);
static void sim_logical_reg(u32 instr);
static void sim_mov_nzk(u32 instr);
static void sim_system(u32 instr);
static void sim_test_bit_imm(u32 instr);

/*
 * Further decoders:
 *
 * The basic idea is that after we've identified the 'class' of an instruction,
 * then further, manual decode determines an exact version of the instruction to
 * execute.  This is applied only to the CALL_EXECUTE version of the software
 * because in that case we decode an instruction once and execute it thousands
 * (millions!) of times without further decode.  Therefore, these decoders allow
 * the code to decode down to the point of no further branch instructions within
 * the execution code for a particular instruction.
 */

static ifunc_t decode_add_sub_imm(u32 instruction);
static ifunc_t decode_br_reg(u32 instruction);
static ifunc_t decode_br_imm(u32 instruction);
static ifunc_t decode_ldr_post(u32 instruction);
static ifunc_t decode_ldr_pre(u32 instruction);
static ifunc_t decode_ldr_imm(u32 instruction);
static ifunc_t decode_ldr_reg(u32 instruction);
static ifunc_t decode_br_cond_imm(u32 instruction);
static ifunc_t decode_add_sub_reg(u32 instruction);
static ifunc_t decode_logical_imm(u32 instruction);
static ifunc_t decode_logical_reg(u32 instruction);
static ifunc_t decode_instr(u32 instruction);
static void sim_cmp_x0_tos(u32 instruction);
static void sim_sub_tos_x0_tos(u32 instruction);
static void sim_add_ip_ip_x0(u32 instruction);
static void sim_add_tos_tos_x0(u32 instruction);
static void sim_br_ne_min_12(u32 instruction);
static void sim_pop_x0(u32 instruction);
static void sim_pop_tos(u32 instruction);
static void sim_push_tos(u32 instruction);
static void sim_push_ip(u32 instruction);
static void sim_ldrsw_x0_ip(u32 instruction);
static void sim_br_up(u32 instruction);

typedef struct decode_s {
    u32  mask;
    u32  match;
    void (*sim_func)(u32 instruction);
    void (*dis_func)(u64 iaddr, u32 instr);
    ifunc_t (*decode_func)(u32 instruction);
} decode_t;

void sim_unimpl(u32 instruction)
{
    UNIMP("Unimplemented instruction");
}

/*
 * If there are any bugs found in this decode table, then fixes need to be
 * propagated to disassem.fth, too.
 */

/*
 * This table has been resorted in an attempt to enhance decode performance
 * by placing instructions which are more frequently used near the top of
 * the list.  The histogram that generated this table was created while
 * building tools.dic.
 *
 * Also note that I modified the wrapper to call the histogram dump
 * routine.  Possibly that can be done inside this simulator itself.
 */

decode_t decode_table[] = {
    {0xFE000000, 0xD6000000, sim_br_reg,       dis_br_reg,        decode_br_reg},        // Unconditional branch (register)
    {0x3B200C00, 0x38000400, sim_ldr_post,     dis_ldr_post,      decode_ldr_post},      // Load/store register (immediate post-indexed)
    {0x1F200000, 0x0B000000, sim_add_sub_reg,  dis_add_sub_reg,   decode_add_sub_reg},   // Add/subtract (shifted register)
    {0x3B200C00, 0x38000C00, sim_ldr_pre,      dis_ldr_pre,       decode_ldr_pre},       // Load/store register (immediate pre-indexed)
    {0x3B000000, 0x39000000, sim_ldr_imm,      dis_ldr_imm,       decode_ldr_imm},       // Load/store register (unsigned immediate)
    {0x1F000000, 0x0A000000, sim_logical_reg,  dis_logical_reg,   decode_logical_reg},   // Logical (shifted register)
    {0x7C000000, 0x14000000, sim_br_imm,       dis_br_imm,        decode_br_imm},        // Unconditional branch (immediate)
    {0x1F000000, 0x11000000, sim_add_sub_imm,  dis_add_sub_imm,   decode_add_sub_imm},   // Add/Subtract (immediate)
    {0xFE000000, 0x54000000, sim_br_cond_imm,  dis_br_cond_imm,   decode_br_cond_imm},   // Conditional branch (immediate)
    {0x3A000000, 0x28000000, sim_ldp,          dis_ldp,           0},                    // Load/store pair
    {0x1FE00000, 0x1A800000, sim_cond_sel,     dis_cond_sel,      0},                    // Conditional select
    {0x3B200C00, 0x38200800, sim_ldr_reg,      dis_ldr_reg,       decode_ldr_reg},       // Load/store register (register offset)
    {0x1F800000, 0x12800000, sim_mov_nzk,      dis_mov_nzk,       0},                    // Move wide (immediate)
    {0x1F800000, 0x12000000, sim_logical_imm,  dis_logical_imm,   decode_logical_imm},   // Logical (immedaite)
    {0x1F800000, 0x13000000, sim_bitfield,     dis_bitfield,      0},                    // Bitfield
    {0x5FE00000, 0x5AC00000, sim_dp_1src,      dis_dp_1src,       0},                    // Data-processing (1 source)
    {0x5FE00000, 0x1AC00000, sim_dp_2src,      dis_dp_2src,       0},                    // Data-processing (2 source)
    {0x1F000000, 0x1B000000, sim_dp_3src,      dis_dp_3src,       0},                    // Data-processing (3 source)
    {0x1F800000, 0x13800000, sim_extract,      dis_extract,       0},                    // Extract
    {0xFF000000, 0xD4000000, sim_exception,    dis_exception,     0},                    // Exception generation (immediate)
    {0x1FE00000, 0x1A000000, sim_adc_sbc,      dis_adc_sbc,       0},                    // Add/subtract (with carry)
    {0x3B000000, 0x18000000, sim_load_reg_lit, dis_load_reg_lit,  0},                    // Load register (literal)
    {0x1F000000, 0x10000000, sim_adr,          dis_adr,           0},                    // PC-rel addressing
    {0xFFC00000, 0xD5000000, sim_system,       dis_system,        0},                    // System

    // Data Processing Immediate

    // Branches, Exception Generation and System
    {0x7E000000, 0x34000000, sim_cmp_br_imm,   dis_cmp_br_imm},   // Compare & branch (immediate)
    {0x7E000000, 0x36000000, sim_test_bit_imm, dis_test_bit_imm}, // Test & branch (immediate)

    // Data Processing Register
    {0x1F200000, 0x0B200000, sim_add_ext_reg,  dis_add_ext_reg},  // Add/subtract (extended register)

    // Exclusive Loads / Stores
    {0x3F000000, 0x08000000, sim_ldr_exc,      dis_ldr_exc},

    /* sim_unimpl is the default, no need to spend time testing unimplemented cases */

#ifdef NOTDEF
    // Loads and stores
    {0x3B200C00, 0x38000000, sim_ldr_um,       dis_ldr_um},       // Load/store register (unscaled immediate)
    {0x3B200C00, 0x38000800, sim_unimpl},       // Load/store regisetr (unprivileged)
    {0xBFBF0000, 0x0C000000, sim_unimpl},       // AdvSIMD load/store multiple elements
    {0xBFA00000, 0x0C800000, sim_unimpl},       // AdvSIMD load/store multiple elements
    {0xBF900000, 0x0D000000, sim_unimpl},       // AdvSIMD load/store single element
    {0xBF800000, 0x0D800000, sim_unimpl},       // AdvSIMD load/store single element

    // Data Processing Register
    {0x1FE00800, 0x1A400000, sim_unimpl},       // Conditional compare (register)
    {0x1FE00800, 0x1A400800, sim_unimpl},       // Conditional compare (immediate)

    // Neon Data Processing
    {0x9F200400, 0x0E200400, sim_unimpl},       // AdvSIMD three same
    {0x9F200400, 0x0E200000, sim_unimpl},       // AdvSIMD three different
    {0x9F3E0800, 0x0E200800, sim_unimpl},       // AdvSIMD two-reg misc
    {0x9F3E0800, 0x0E300800, sim_unimpl},       // AdvSIMD across lanes
    {0x9FE08400, 0x0E000400, sim_unimpl},       // AdvSIMD INS/DUP
    {0x9F000400, 0x0F000000, sim_unimpl},       // AdvSIMD vector x indexed element
    {0x9F800400, 0x0F000400, sim_unimpl},       // AdvSIMD shift by immediate
    {0x9FF80C00, 0x0F000400, sim_unimpl},       // AdvSIMD modified immediate
    {0xBF208C00, 0x0E000800, sim_unimpl},       // AdvSIMD ZIP/UZP/TRN
    {0xBFE08C00, 0x0E000000, sim_unimpl},       // AdvSIMD TBL/TBX
    {0xBFE08400, 0x2E000000, sim_unimpl},       // AdvSIMD EXT
    {0x5F200000, 0x1E000000, sim_unimpl},       // Floating-point<->integer conversions
    {0x5F200C00, 0x1E200400, sim_unimpl},       // Floating-point conditional compare
    {0x5F200C00, 0x1E200800, sim_unimpl},       // Floating-point data-processing (2 source)
    {0x5F200C00, 0x1E200C00, sim_unimpl},       // Floating-point conditional select
    {0x5F201C00, 0x1E201000, sim_unimpl},       // Floating-point immediate
    {0x5F203C00, 0x1E202000, sim_unimpl},       // Floating-point compare
    {0x5F207C00, 0x1E204000, sim_unimpl},       // Floating-point data-processing (1 source)
    {0x5F000000, 0x1F000000, sim_unimpl},       // Floating-point data-processing (3 source)
    {0xDF200400, 0x5E200400, sim_unimpl},       // AdvSIMD scalar three same
    {0xDF200C00, 0x5E200000, sim_unimpl},       // AdvSIMD scalar three different
    {0xDF3E0C00, 0x5E200800, sim_unimpl},       // AdvSIMD scalar two-reg misc
    {0xDF3E0C00, 0x5E300800, sim_unimpl},       // AdvSIMD scalar pairwise
    {0xDFE08400, 0x5E000400, sim_unimpl},       // AdvSIMD scalar CPY
    {0xDF000400, 0x5F000000, sim_unimpl},       // AdvSIMD scalar x indexed element
    {0xDF800400, 0x5F000400, sim_unimpl},       // AdvSIMD scalar shift by immediate
#endif
};
static int decode_sz = sizeof(decode_table) / sizeof(*decode_table);

#define RD_INSTR        0

static void sim_illegal(u32 instruction)
{
    RD_INSTR;
    regdump(rPC, instruction, trace);
    sim_unimpl(instruction);
    s_bye(1);
}

static void sim_nop(u32 instruction)
{
    rPC += 4;
}

static void sim_common_br_next(u32 instruction)
{
    rPC = r[UP];
}

static void sim_early_br_next(u32 instruction)
{
    if (origin == 0) {
	rp0 = r[RP];
	sp0 = r[DSP];
	origin = r[ORG];
    }

    rPC = rUP;
}







static void simone(u32 instruction)
{
    int i;
    int dis;

    if (ftrace)
        sim_ftrace(instruction);

    if (instruction == /* br  up */ 0xd61f0300) {
	static int next_count;

	if (next_count++ == 0) {
	    rp0 = r[RP];
	    sp0 = r[DSP];
	    origin = r[ORG];
	}
    }


    for (i = 0; i < decode_sz; i++) {
	// Because trace is turned on/off during instruction execution,
	// we save the trace global variable state from the beginning
	// of the instruction and re-use it at the end of the instruction
	// so that we finish an instruction trace cleanly.
	int trace_this_instr;
        decode_t *p = &decode_table[i];

        if ((instruction & p->mask) == p->match) {

	    trace_this_instr = trace;
            if (trace_this_instr)
                dis = sim_trace(rPC, instruction);
            else
                dis = 0;

            if (step)
                getchar();

            p->sim_func(instruction);

            if (trace_this_instr && dis) disassemble_finish();
            return;
        }
    }

    regdump(rPC, instruction, trace);
    sim_unimpl(instruction);
    s_bye(1);
}

void dump_histogram(void)
{
}

/*
 * ADR  Xn, #<offset>
 * ADRP Xn, #<offset>
 */
static void sim_adr(u32 instruction)
{
    RD_INSTR;
    /* PC Relative addressing */
    s64 imm, base;
    int page;

    page = OP_B(31);

    sext21.imm21 = (OP(5,23) << 2) | OP(29,30);

    base = rPC;
    imm = sext21.imm21;
    if (page) {
    imm <<= 12;
    base &= ~0xFFF;
    }

    RDZ = base + imm;
    rZERO = 0;
    rPC += 4;
}

static void sim_mov_nzk(u32 instruction)
{
    RD_INSTR;
    /* Move Wide (immediate) */
    int sf = OP_B(31);
    int op = OP_PAIR(29);
    int hw = OP_PAIR(21);
    u64 imm = OP(5, 20);
    u64 mask, sign, res;

    UNIMPIF(op == 1, "MOV{NZK} Xn with unknown opcode");
    UNIMPIF(!sf && (hw > 1), "MOV{NZK} Wn, #<imm16>, LSL #<shift> where shift is too large for a 32 bit register");


    mask = MASK(16) << (hw * 16);
    imm  = imm      << (hw * 16);

    if (op == 3) res = RDZ;   // MOVK
    else         res = 0;

    res = (res & ~mask) | imm;
    if (op == 0) res = ~res;

    res = MASK32(res, sf);
    RDZ = res;
    rZERO = 0;
    rPC += 4;
}

/* =========== ADD & SUB ========== */

//    [0007] 0xaa1903e0, (executed 5324431)00000000 [ 1917302024 ]: aa1903e0:  orr        x0,zr,tos

static void sim_cmp_tos_0(u32 instruction)
{
    u64 res;
    int setflags = 1;

    ADC64(res, rTOS, ~0, 1);
    rPC += 4;
}

static void sim_subs_x0_x0_1(u32 instruction)
{
    int setflags = 1;

    ADC64(r[0], r[0], ~1, 1);
    rPC += 4;
}

static void sim_add_xsp_xsp_0(u32 instruction)
{
    rPC += 4;
}

static ifunc_t decode_instr(u32 instruction)
{

    // Handle two different (next): one to set the origin, rp0, and sp0.
    // And another to just branch to UP.
    if (instruction == /* br  up */ 0xd61f0300) {
        if (origin == 0) {
            return sim_early_br_next;
        } else {
            return sim_common_br_next;
        }
    }


    // (executed 4820688): f100033f:  subs       zr,tos, #0
    if (instruction == 0xf100033f) { return sim_cmp_tos_0; }

    // (executed 3775485): f1000400:  subs       x0,x0, #1
    if (instruction == 0xf1000400) { return sim_subs_x0_x0_1; }

    //    0x910003ff is the start of a code word opcode
    if (instruction == 0x910003ff) { return sim_add_xsp_xsp_0; }

    // (executed 4798557): eb19001f:  subs       zr,x0,tos
    if (instruction == 0xeb19001f) { return sim_cmp_x0_tos; }

    // (executed 4721946): cb190019:  sub        tos,x0,tos
    if (instruction == 0xcb190019) { return sim_sub_tos_x0_tos; }

    // (executed 4395807): 8b00037b:  add        ip,ip,x0
    if (instruction == 0x8b00037b) { return sim_add_ip_ip_x0; }

    // (executed 4232714): 8b000339:  add        tos,tos,x0
    if (instruction == 0x8b000339) { return sim_add_tos_tos_x0; }

    // (executed 5396130): 54ffffa1:  b.ne       $-12
    if (instruction == 0x54ffffa1) { return sim_br_ne_min_12; }

    //    br UP is the way to go to NEXT
    if (instruction == 0xd61f0300) { return sim_br_up ; }

    // (executed 22062426): f8408780:  ldr        x0,[sp], #8
    if (instruction == 0xf8408780) { return sim_pop_x0; }

    // (executed 11806786): f8408799:  ldr        tos,[sp], #8
    if (instruction == 0xf8408799) { return sim_pop_tos; }

    // (executed 12071876): f81f8f99:  str        tos,[sp, #-8]!
    if (instruction == 0xf81f8f99) { return sim_push_tos; }

    // (executed 12071876): f81f8f5b:  str        ip,[sp, #-8]!
    if (instruction == 0xf81f8f5b) { return sim_push_ip; }

    // (executed 4395807): b9800360:  ldrsw      x0,[ip]
    if (instruction == 0xb9800360) { return sim_ldrsw_x0_ip; }

    return NULL;
}

static ifunc_t decode_add_sub_imm(u32 instruction)
{
    return sim_add_sub_imm;
}

static void sim_add_sub_imm(u32 instruction)
{
    RD_INSTR;
    /* Add/Sub (immediate) */
    int sf = OP_B(31);
    int op = OP_B(30);
    int setflags = OP_B(29);
    u32 shift = OP_PAIR(22);
    u64 imm = OP(10,21);
    u64 res;

    UNIMPIF(shift > 1, "add/sub Rn, #<immed> with shift != 00 or 01");

    if (shift == 1) imm <<= 12;
    if (op)         imm = ~imm;
    C = op;
    if (sf)         ADC64(res, RNSP, imm, C);
    else            ADC32(res, RNSP, imm, C);
    if ((RD == 31) && (!setflags)) rSP = res;
    else                           RDZ = res;
    rZERO = 0;
    rPC += 4;
}

static void sim_cmp_x0_tos(u32 instruction)
{
    u64 res;
    int setflags = 1;

    ADC64(res, r[0], ~rTOS, 1);
    rPC += 4;
}

static void sim_sub_tos_x0_tos(u32 instruction)
{
    int setflags = 0;

    ADC64(rTOS, r[0], ~rTOS, 1);
    rPC += 4;
}

static void sim_add_ip_ip_x0(u32 instruction)
{
    int setflags = 0;

    ADC64(rIP, rIP, r[0], 0);
    rPC += 4;
}

static void sim_add_tos_tos_x0(u32 instruction)
{
    int setflags = 0;

    ADC64(rTOS, rTOS, r[0], 0);
    rPC += 4;
}

static ifunc_t decode_add_sub_reg(u32 instruction)
{
    return sim_add_sub_reg;
}

static void sim_add_sub_reg(u32 instruction)
{
    RD_INSTR;
    /* Add/Sub (immediate) */
    int sf = OP_B(31);
    int op = OP_B(30);
    int setflags = OP_B(29);
    u32 shift = OP_PAIR(22);
    u64 imm6 = OP(10,15);
    u64 res;
    u64 op1, op2, carry = 0;

    UNIMPIF(shift == 3, "add/sub Rn, Rm with shift == 11");
    UNIMPIF((sf == 0 && imm6 >= 32), "add Wm with  shift count > 32");

    op1 = RNZ;
    op2 = ShiftReg(sf, RMZ, shift, imm6);
    if (op == 1) {
      op2 = ~op2;
      carry = 1;
    }
    if (sf)         ADC64(res, op1, op2, carry);
    else            ADC32(res, op1, op2, carry);
    if ((RD == 31) && (!setflags)) rSP = res;
    else                           RDZ = res;
    rZERO = 0;
    rPC += 4;
}

static void sim_adc_sbc(u32 instruction)
{
    RD_INSTR;
    /* Add/Sub With Carry */
    int sf = OP_B(31);
    int op = OP_B(30);
    int setflags = OP_B(29);
    u64 res;
    u64 op1 = RNZ;
    u64 op2 = RMZ;

    if (op == 1)    op2 = ~op2;
    if (sf)         ADC64(res, op1, op2, C);
    else            ADC32(res, op1, op2, C);
    RDZ = res;
    rZERO = 0;
    rPC += 4;
}

static void sim_add_ext_reg(u32 instruction)
{
    RD_INSTR;
    int sf = OP_B(31);
    int sub = OP_B(30);
    int setflags = OP_B(29);
    int option = OP(13,15);
    int shift = OP(10,12);
    u64 opm = ExtendReg(RMZ, option, shift);
    u64 opn = RNSP;
    u64 res;
    u64 c = 0;

    UNIMPIF(shift > 4, "Shifts greater than 4 are not valid");

    if (sub)  {
	opm = ~opm;
	c = 1;
    }

    if (sf) ADC64(res, opn, opm, c);
    else    ADC32(res, opn, opm, c);
    RDSP = res;
    rPC += 4;
}

static ifunc_t decode_logical_imm(u32 instruction)
{
    return sim_logical_imm;
}

static void sim_logical_imm(u32 instruction)
{
    RD_INSTR;
    /* Logical (immediate) */
    int sf = OP_B(31);
    int op = OP_PAIR(29);
    int n = OP_B(22);
    int immr = OP(16, 21);
    int n_imms, imms = OP(10, 15);
    int setflags = op == 3;
    int rr, ss, len, size, datasize;
    u64 mask;
    u64 imm, pattern;
    u64 op1, op2, res;
    int nzcv;

    datasize = sf ? 64 : 32;

    UNIMPIF(!sf && n, "<logical-op> Wn, #<val> with the N bit set is an error");

    n_imms = MASK(6) ^ imms;
    len = HighestSetBit((n << 6) | n_imms);
    UNIMPIF(len < 1, "<logical-op> Wn, #<val> with a HighestSetBit() of < 1");
    size = 1 << len;
    mask = MASK(len);
    rr = immr & mask;
    ss = imms & mask;
    if (ss == (size -1)) {
	printf("ss == %d, size == %d, size-1 == %d, imms == %x, mask = %llx, imms & mask = %llx\n", ss, size, size-1, imms, mask, imms & mask);
    }
    UNIMPIF(ss == (size - 1), "<logical-op> Wn, #<val> with S == (size -1)");
    pattern = MASK(ss+1);
    pattern = ROR(pattern, size, rr);
    imm = Replicate(pattern, size, datasize >> len);
    if (0) {
	printf("(%d, %d, %d) --> %llx\n", len, size, datasize >> len, imm);
    }

    op1 = RNZ;
    op2 = imm;
    switch (op) {
    case 0: res = op1 & op2; break;
    case 1: res = op1 | op2; break;
    case 2: res = op1 ^ op2; break;
    case 3: res = op1 & op2; break;
    default:
    res = 0;
    UNIMP("<logical-op> Xn, #<val> with unknown operation code");
    break;
    }

    res = MASK32(res, sf);
    if ((RD == 31) && !setflags) rSP = res;
    else                         RDZ = res;
    rZERO = 0;
    if (setflags) {
        int n, z;
        if (sf) n = res >> 63;
        else    n = res >> 31;
        z = res == 0;
        nzcv = (n << 3) | (z << 2);
        SETFLAGS(nzcv);
    }
    rPC += 4;
}

static ifunc_t decode_logical_reg(u32 instruction)
{
    return sim_logical_reg;
}

static void sim_logical_reg(u32 instruction)
{
    RD_INSTR;
    /* Logical (shifted register) */
    int sf = OP_B(31);
    int opc = OP_PAIR(29);
    int shift = OP_PAIR(22);
    int n = OP_B(21);
    int imm6 = OP(10, 15);
    int datasize = sf ? 64 : 32;
    int setflags = (opc == 3);
    u64 op1, op2, res;

    UNIMPIF((datasize == 32 && imm6 >= 32), "<logical-op> Wn, shift count > 32");

    op1 = RNZ;
    op2 = ShiftReg(sf, RMZ, shift, imm6);
    if (n)
        op2 = ~op2;

    switch (opc) {
    case 0: res = op1 & op2; break;
    case 1: res = op1 | op2; break;
    case 2: res = op1 ^ op2; break;
    case 3: res = op1 & op2; break;
    default:
    res = 0;
    UNIMP("<logical-op> Xn, #<val> with unknown operation code");
    break;
    }

    res = MASK32(res, sf);
    if ((RD == 31) && !setflags) rSP = res;
    else                         RDZ = res;
    if (setflags) {
            SETFLAGS(0);
            UPCC(RDZ);
    }
    rZERO = 0;
    rPC += 4;
}

static void sim_bitfield(u32 instruction)
{
    RD_INSTR;
    /* Bitfield -- Move a bitfield from register to register */
    int sf = OP_B(31);
    int datasize = sf ? 64 : 32;
    int inzero, extend, diff;
    u64 sign, mask;
    int opc = OP_PAIR(29);
    int n = OP_B(22);
    int immr = OP(16,21);
    int imms = OP(10,15);
    u64 dst, src, res;

    UNIMPIF(n != sf, "BFM with improper sf/N encodings");
    if (datasize == 32) {
    UNIMPIF(imms >= 32, "BFM with improper imms encodings");
    UNIMPIF(immr >= 32, "BFM with improper immr encodings");
    }

    UNIMPIF(opc > 2, "Illegal BFM instruction OP encoding");

    switch (opc) {
    case 0: inzero = 1; extend = 1; break;  // SBFM
    case 1: inzero = 0; extend = 0; break;  // BFM
    case 2: inzero = 1; extend = 0; break;  // UBFM
    }

    /* if s >= r then
       Wd<s-r:0> = Wn<s:r>,
       else if s > 0 then
       Wd<32+s-r:32-r> = Wn<s:0>
       else if s = 0 then
       Wd<32-r> = Wn<0>

       Leaves other bits in Wd unchanged.
    */
    diff = imms - immr;
    mask = 0;
    if (diff >= 0) {
    // S >= R: extract mask
    mask = MASK(diff+1);
    } else {
    // S < R: insert mask
    mask = MASK(imms+1);
    mask = ROR(mask, datasize, immr);
    diff += datasize; // Normalize to [0..datasize)
    }

    dst = inzero ? 0 : RDZ;
    dst &= ~mask;

    // rotate source bitfield into place
    // When S >= R, then we're shifting the SRC so that
    // bit R of SRC is bit 0.  However, when S < R, then
    // we're doing the opposite!  We shifting bit 0 of
    // SRC so that it's bit 32-R!
    if (sf) {
        src = RNZ;
    } else {
        src = (u32)RNZ;
    }
    res = ROR(src, datasize, immr);
    res &= mask;

    // determine sign extension of source
    sign = 0;
    if (extend && ((src >> imms) & 1)) {
    // compute bit mask above bitfield
    // (for sign extension)
    sign = ~MASK(diff+1);
    }

    // merge sign extension, dest/zero and bitfield
    res = sign | res | dst;
    res = MASK32(res, sf);
    RDZ = res;
    rZERO = 0;
    rPC += 4;
}

static void sim_load_reg_lit(u32 instruction)
{
    RD_INSTR;
    /* Load Register Literal */
    int sz, sx /* sign extend data */;
    u64 offset, res;

    UNIMPIF(OP_B(26), "Vector instructions are not supported");

    switch(OP(30,31)) {
    case 0: sz = 4; sx = 0; break;
    case 1: sz = 8; sx = 0; break;
    case 2: sz = 4; sx = 1; break;
    case 3: return;  // PRFM <prfop>, <label>, ignored!
    }
    offset = SXOP(5,23) << 2;
    if (sz == 4) res = MEM(u32, rPC + offset);
    else         res = MEM(u64, rPC + offset);
    if (sx) res = SX(res);
    RDZ = res;
    rZERO = 0;
    rPC += 4;
}

static void sim_ldp(u32 instruction)
{
    RD_INSTR;
    /* Load/Store Register Pair */
    int sz = 4 << OP_B(31);  // size of operands and scaling
    int sx = OP_B(30);       // sign extend data
    int wback = OP_B(23);    // update Rn
    int pre = OP_B(24);      // if writeback, pre- or post-index
    int load = OP_B(22);     // load or store
    s64 offset;
    u64 address;

    UNIMPIF(OP_B(26), "Vector instructions are not supported");

    offset = SXOP(15,21) * sz;
    if (wback) {
        if (pre) {
            RNSP += offset;
            address = RNSP;
        } else {
            address = RNSP;
            RNSP += offset;
        }
    } else {
        address = RNSP + offset;
    }
    if (load) {
        if (sz == 4) {
            if (sx) {
                r[RT]  = MEM(s32, address);
                r[RT2] = MEM(s32, address + sz);
            } else {
                r[RT]  = MEM(u32, address);
                r[RT2] = MEM(u32, address + sz);
            }
        } else {
            r[RT]  = MEM(u64, address);
            r[RT2] = MEM(u64, address + sz);
            rZERO = 0;
        }
    } else {
        if (sz == 4) {
            MEM(u32, address) = r[RT];
            MEM(u32, address + sz) = r[RT2];
        } else {
            MEM(u64, address) = r[RT];
            MEM(u64, address + sz) = r[RT2];
        }
    }
    rPC += 4;
}

static int is_cond_true(int cond)
{
    int r;

    cond &= 0xF;
    // UNIMPIF(cond == 0xF, "Unknown condition code");
    /* Actually, 0xF == 0xE.  I.e., !Always == always.  Damn ARM. */

    r = 0;
    switch (cond >> 1) {
    case 0: r = Z; break;
    case 1: r = C; break;
    case 2: r = N; break;
    case 3: r = V; break;
    case 4: r = C && !Z; break;
    case 5: r = N == V; break;
    case 6: r = (N == V) && !Z; break;
    case 7: r = 1; break;
    }

    if (cond & 1) r = !r;

    return r;
}

static void sim_br_ne_min_12(u32 instruction)
{
    if (!Z) {
	rPC -= 12;
    } else {
	rPC += 4;
    }
}

static ifunc_t decode_br_cond_imm(u32 instruction)
{
    return sim_br_cond_imm;
}

static void sim_br_cond_imm(u32 instruction)
{
    RD_INSTR;
    u64 imm19 = SXOP(5, 23) << 2;
    int cond = OP(0, 4);

    if (is_cond_true(cond)) {
        rPC += imm19;
    } else {
	rPC += 4;
    }
}

/* ============ br_imm ============= */

static void sim_bl_imm(u32 instruction)
{
    RD_INSTR;
    u64 imm26 = (0xFFFFFFFFFC000000 | (u64)instruction) << 2;

    r[30] = rPC + 4;
    rPC += imm26;
}

static ifunc_t decode_br_imm(u32 instruction)
{
    // Check for Branch & Link (0x8) and backwards (0x.2)
    if ((instruction & 0x82000000) == 0x82000000) {
	return sim_bl_imm;
    }

    return sim_br_imm;
}

static void sim_br_imm(u32 instruction)
{
    RD_INSTR;
    u64 imm26 = SXOP(0,25) << 2;
    if (instruction & 0x80000000) r[30] = rPC + 4;

    rPC += imm26;
}

static void sim_cmp_br_imm(u32 instruction)
{
    RD_INSTR;
    int sf = OP_B(31);
    int iszero = OP_B(24) == 0;
    u64 imm19 = SXOP(5, 23) << 2;
    int rt = OP(0, 4);

    if ((r[rt] == 0) == iszero) {
        rPC += imm19;
    } else {
	rPC += 4;
    }
}

static void sim_br_up(u32 instruction)
{
    rPC = rUP;

}

static ifunc_t decode_br_reg(u32 instruction)
{
    return sim_br_reg;
}

static void sim_br_reg(u32 instruction)
{
    RD_INSTR;
    if (instruction & 0x00200000) r[30] = rPC + 4;
    rPC = RNZ;
}

static void sim_cond_sel(u32 instruction)
{
    RD_INSTR;
    int cond = OP(12, 15);
    int else_inv = OP_B(30);
    int else_inc = OP_B(10);

    if (is_cond_true(cond)) {
        RDZ = RNZ;
        rZERO = 0;
    } else {
        RDZ = RMZ;
        if (else_inv) RDZ = ~RDZ;
        if (else_inc) RDZ += 1;
        rZERO = 0;
    }
    rPC += 4;
}

static void sim_extract(u32 instruction)
{
    RD_INSTR;
    int sf = OP_B(31);
    int n = OP_B(22);
    int lsb = OP(10, 15);

    UNIMPIF(!sf && (lsb >= 32), "Illegal EXTR encoding");
    UNIMPIF(sf != n, "Illegal EXTR encoding");

    if (sf) {
	u64 m = RMZ;
	u64 n = RNZ;
	u64 res  = (m >> lsb) | (n << (64 - lsb));
	RDZ = res;
    } else {
	u32 m = RMZ;
	u32 n = RNZ;
	u32 res = (m >> lsb) | (n << (32 - lsb));
	RDZ = res;
    }

    rZERO = 0;
    rPC += 4;
}

static void sim_test_bit_imm(u32 instruction)
{
    RD_INSTR;
    u64 operand = RDZ;
    int sf = OP_B(31);
    int bit_num = (OP_B(31) << 5) | OP(19, 23);
    s64 offset = SXOP(5, 18);
    int op = OP_B(24);

    if (((operand >> bit_num) & 1) == op) {
        rPC += offset << 2;
    } else {
	rPC += 4;
    }
}

static u64 sim_count_leading_bits(u64 val, int sf, int count_ones)
{
    int count;
    u32 sval;

    if (count_ones)  val = ~val;

    if (!val) {
	if (sf) return 64;
	else    return 32;
    }

    count = 0;
    if (sf) {
	if (val >> 32) {
	    sval = val >> 32;
	} else {
	    sval = val;
	    count += 32;
	}
    } else {
	sval = val;
    }

    if (sval & 0xFFFF0000) {
	sval >>= 16;
    } else {
	count += 16;
    }

    if (sval & 0xFF00) {
	sval >>= 8;
    } else {
	count += 8;
    }

    if (sval & 0xF0) {
	sval >>= 4;
    } else {
	count += 4;
    }

    if (sval & 0xC) {
	sval >>= 2;
    } else {
	count += 2;
    }

    if ((sval & 0x2) == 0) {
	count += 1;
    }

    return count;
}

static u64 sim_reverse_bits(u64 val, int sf, int vbits)
{
    u32 vbit;
    int datasize;

    if (sf) datasize = 64;
    else    datasize = 32;

    u64 result = val;

    for (vbit = 0; vbit < 6; vbit ++) {
	if ((1 << vbit) & vbits) {
	    u64 tmp = result;
	    int vsize = 1 << vbit;
	    int base = 0;
	    u64 mask = MASK(vsize);
	    u64 x;

	    while (base < datasize) {
		x = (tmp >> (base + vsize)) & mask;
		result &= ~(mask << base);
		result |= x << base;

		x = (tmp >> base) & mask;
		result &= ~(mask << (base + vsize));
		result |= x << (base + vsize);
		base += 2 * vsize;
	    }
	}
    }

    return result;
}

static void sim_dp_1src(u32 instruction)
{
    RD_INSTR;
    int opcode = OP(10, 15);
    int opcode2 = OP(16, 20);
    int sf = OP_B(31);
    int s = OP_B(29);

    UNIMPIF(opcode2, "Illegal Data-Processing (1 source) encoding: opcode2 must be 0");
    UNIMPIF(opcode >= 6,  "Illegal Data-Processing (1 source) encoding: opcode must be < 6");
    UNIMPIF(s, "Illegal Data-Processing (1 source) encoding: S must be 0");
    UNIMPIF((opcode == 3) && (!sf), "Illegal Data-Processing (1 source) encoding: REV32 must have sf = 1");

    u64 val = RNZ;
    u64 result;

    switch(opcode) {
    case 0:   // RevOp_RBIT
	// RBIT xzr, xn is the new way to communicate requests to the simulator
	if (RD == 31) {
	    sim_handle_simulation_request(instruction, RN);
	} else {
	    if (sf)   result = sim_reverse_bits(val, sf, 0x3F);
	    else      result = sim_reverse_bits(val, sf, 0x1F);
	}
	break;

    case 1:  // RevOp_REV16
	result = sim_reverse_bits(val, sf, 0x8);
	break;

    case 2:  // RevOp_REV32
	result = sim_reverse_bits(val, sf, 0x18);
	break;

    case 3:  // RevOp_REV64
	assert(sf);
	result = sim_reverse_bits(val, sf, 0x38);
	break;

    case 4:  // CLZ -- Count Leading Zero bits
	result = sim_count_leading_bits(val, sf, 0);
	break;

    case 5:  // CLS -- Count Leading Sign bits
	result = sim_count_leading_bits(val, sf, 1);
	break;
    default:
	UNIMP("Illegal Data-Processing (1 source) -- but this should have been caught in the code above");
	result = 0;
	break;
    }

    RDZ = result;
    rZERO = 0;
    rPC += 4;
}

static void sim_dp_2src(u32 instruction)
{
    RD_INSTR;
    int opcode = OP(10, 15);
    int sf = OP_B(31);
    u64 n = RNZ;
    u64 d;
    u32 m = RMZ;
    int nbits = (sf ? 64 : 32);

    m = m & (nbits -1);

    switch ((sf << 8) | opcode) {    // Combine width and operation
    case 0x00a:                       // asrv 32
    case 0x10a:                       // asrv 64
        d = (s64) n >> m;
        break;
    case 0x008:                       // lslv 32
    case 0x108:                       // lslv 64
        d = n << m;
        break;
    case 0x009:                       // lsrv 32
    case 0x109:                       // lsrv 64
        d = n >> m;
        break;
    case 0x00b:                       // rorv 32
    case 0x10b:                       // rorv 64
        d = (n >> m) | ((n & MASK(m)) << (nbits - m));
        break;
    case 0x003:                       // sdiv 32
        RDZ = (RMZ == 0) ? 0 : (s32) RNZ / (s32) RMZ;
        rZERO = 0;
	rPC += 4;
	return;
    case 0x103:                       // sdiv 64
        RDZ = (RMZ == 0) ? 0 : (s64) RNZ / (s64) RMZ;
        rZERO = 0;
	rPC += 4;
	return;
    case 0x002:                       // udiv 32
        RDZ = (RMZ == 0) ? 0 : (u32) RNZ / (u32) RMZ;
        rZERO = 0;
	rPC += 4;
	return;
    case 0x102:                       // udiv 64
        RDZ = (RMZ == 0) ? 0 :       RNZ /       RMZ;
        rZERO = 0;
	rPC += 4;
	return;
    default:
        UNIMP("Illegal opcode in data-processing 2 source instruction");
        return;
    }

    RDZ = MASK32(d, sf);
    rZERO = 0;
    rPC += 4;
}

static void sim_madd_msub(u32 instruction)
{
    /* Madd/Msub (DP3) */
    int sf = OP_B(31);
    int op = OP_B(15);
    u64 res, op1, op2, op3;

    op1 = RNZ;
    op2 = RMZ;
    op3 = RAZ;
    if (op) {
      res = op3 - (op1 * op2);
    } else {
      res = op3 + (op1 * op2);
    }
    res = MASK32(res, sf);
    RDZ = res;
    rZERO = 0;
}

static void sim_dp_3src(u32 instruction)
{
    RD_INSTR;
    int opcode = OP(21, 23);
    s128 prod;
    u128 uprod;

    rPC += 4;

    switch (opcode) {
    case 0:
        sim_madd_msub(instruction); return;
    case 1:
        if (OP_B(15))       // smsubl
            RDZ = (s64) RAZ - (s32) RMZ * (s32) RNZ;
        else                // smaddl
            RDZ = (s64) RAZ + (s32) RMZ * (s32) RNZ;
        rZERO = 0;
        return;
    case 2:                 // smulh
        prod = (s128) (s64) RNZ * (s64) RMZ;
        RDZ = (prod >> 64);
        rZERO = 0;
        return;
    case 5:
        if (OP_B(15))       // umsubl
            RDZ = RAZ - (u32) RMZ * (u32) RNZ;
        else                // umaddl
            RDZ = RAZ + (u32) RMZ * (u32) RNZ;
        rZERO = 0;
        return;
    case 6:                 // umulh
        uprod = (u128) RNZ * RMZ;
        RDZ = (uprod >> 64);
        rZERO = 0;
        return;
    default:
	rPC -= 4;
        UNIMP("Illegal opcode in data-processing 3 source instruction");
        return;
    }
}

static void sim_system_msr(u32 instruction)
{
    RD_INSTR;
    u16 sr = OP(5,20);

    if (sr == VBAR_EL3) {
        msr_vbar_el3 = RDZ;
    } else if (sr == TPIDR_EL0) {
        msr_tpidr_el0 = RDZ;
    } else if (sr == TPIDRRO_EL0) {
        msr_tpidrro_el0 = RDZ;
    } else if (sr == TPIDR_EL1) {
        msr_tpidr_el1 = RDZ;
    } else if (sr == DAIF) {
        // Skip setting DAIF
    } else if (sr == 51072) {
        // HID 0  -- Skip
    } else if (sr == 51080) {
        // HID 1  -- Skip
    } else if (sr == 51088) {
        // HID 2  -- Skip
    } else if (sr == 51096) {
        // HID 3  -- Skip
    } else if (sr == 51104) {
        // HID 4  -- Skip
    } else if (sr == 51112) {
        // HID 5  -- Skip
    } else if (sr == 49682) {
        // Current EL -- Skip
    } else {
        printf("MSR sr == %d\n", sr);
        UNIMP("msr register");
    }
    rPC += 4;
}

static void sim_system_mrs(u32 instruction)
{
    RD_INSTR;
    u16 sr = OP(5,20);

    if (sr == VBAR_EL3) {
        RDZ = msr_vbar_el3;
    } else if (sr == MPIDR_EL1) {
        RDZ = 0;
    } else if (sr == TPIDR_EL0) {
        RDZ = msr_tpidr_el0;
    } else if (sr == TPIDRRO_EL0) {
        RDZ = msr_tpidrro_el0;
    } else if (sr == TPIDR_EL1) {
        RDZ = msr_tpidr_el1;
    } else if (sr == CNTPCT_EL0) {
        RDZ = primitive_instruction_count + instruction_count;
    } else if (sr == CNTVCT_EL0) {
        RDZ = primitive_instruction_count + instruction_count;
    } else if (sr == DAIF) {
        RDZ = 0x0; // All interrupts are enabled.
    } else if (sr == 51072) {
        RDZ = 0x0; // HID 0  -- Skip
    } else if (sr == 51080) {
        RDZ = 0x0; // HID 1  -- Skip
    } else if (sr == 51088) {
        RDZ = 0x0; // HID 2  -- Skip
    } else if (sr == 51096) {
        RDZ = 0x0; // HID 3  -- Skip
    } else if (sr == 51104) {
        RDZ = 0x0; // HID 4  -- Skip
    } else if (sr == 51112) {
        RDZ = 0x0; // HID 5  -- Skip
    } else if (sr == 49184) {
        RDZ = 0x0; // ID_AA64PFR0_EL1 - skip
    } else if (sr == 49682) {
        RDZ = 4; // Current EL, it's assumed 1: Kernel mode
    } else if (sr == MDRAR_EL1) {
        RDZ = 0;
    } else {
        printf("MSR sr == %d\n", sr);
        UNIMP("mrs register");
    }
    rZERO = 0;
    rPC += 4;
}

#define IS_SYS_MATCH(_op1,_crn,_crm,_op2)  (((_op1) == (op1)) && ((_crn) == (crn)) && ((_crm) == (crm)) && ((_op2) == (op2)))
#define SYS_MATCH(_op1,_crn,_crm,_op2)     if (IS_SYS_MATCH(_op1,_crn,_crm,_op2))  { ok = 1; } else

static void sim_system_sys(u32 instruction)
{
    RD_INSTR;
    u8 op1 = OP(16,18);
    u8 crn = OP(12,15);
    u8 crm = OP(8,11);
    u8 op2 = OP(5,7);
    int ok = 0;

    /* IC ops */
    if (IS_SYS_MATCH(0,7,1,0) ||  /* IALLUIS */
        IS_SYS_MATCH(0,7,5,0)) {  /* IALLU   */
        ok = 1;
    }
    if (IS_SYS_MATCH(3,7,5,1)) {  /* IVAU    */
        ok = 1;
    }

    /* DC ops */
    if (IS_SYS_MATCH(3,7,4,1)) {
	/* ZVA op: implement because it's great for zeroing regions quickly */
	u64 va = RDZ;
	u64 va_end;

	va = va & 0xFFFFFFFFFFFFFFC0;  // Cache line size
	va_end = va + 64;
	while (va != va_end) {
	    MEM(u64, va) = 0;
	    va += 8;
	}
	ok = 1;
    }

    SYS_MATCH(0,7,6,1);  /* IVAC    */
    SYS_MATCH(0,7,6,2);  /* ISW     */
    SYS_MATCH(3,7,10,1); /* CVAC    */
    SYS_MATCH(0,7,10,2); /* CSW     */
    SYS_MATCH(3,7,11,2); /* CVAU    */
    SYS_MATCH(3,7,14,1); /* CIVAC   */
    SYS_MATCH(0,7,14,2); /* CISW    */
    SYS_MATCH(0,8,3,2);  /* ISB  SY */
    SYS_MATCH(0,8,3,1);  /* TLBI ASIDE1IS */

    if (IS_SYS_MATCH(0,7,14,2)) {
        // We need cache way / number of set information.
        // Hardcode for now, just for grins.
        int ways_log2 = 3;  // 8 Ways
        int sets_log2 = 11; // 2048 Sets
        int clsz_log2  = 6; // 64 byte cache line size
        int level = ((RDZ >> 1) & 7) +1;
        int set = (RDZ >> clsz_log2) & ((1 << sets_log2) -1);
        int way = (RDZ >> (32 - ways_log2)) & ((1 << ways_log2) -1);

        printf("DC CISW of L%d: Set %d, Way %d\n", level, set, way);
        ok = 1;
    }

    if (!ok) {
        printf("SYS instruction with operands: SYS_MATCH(%d,%d,%d,%d)\n", op1, crn, crm, op2);
        UNIMP("SYS instruction");
    }

    rPC += 4;
}

static void sim_system(u32 instruction)
{
    RD_INSTR;
    if (instruction == 0xd503201f) {
	rPC += 4;
        // NOP
        return;
    }
    if ((instruction & 0x00300000) == 0x00100000) {
        sim_system_msr(instruction);
    } else if ((instruction & 0x00300000) == 0x00300000) {
        sim_system_mrs(instruction);
    } else if ((instruction & 0x00380000) == 0x00080000) {
	sim_system_sys(instruction);
    } else if ((instruction & 0xFFFFF01F) == 0xd503201F) {
	// NOP, Yield, WFE, WFI, SEV, SEVL, HINT
	if (OP(5,11) < 6) {
	    // NOP, Yield, WFE, WFI, SEV, SEVL ops.
	} else {
	    // Else, regular Hint to the simulator
	    sim_handle_simulation_request(instruction, OP(5,11));
	}
	rPC += 4;
    } else if ((instruction & 0xFFFFF0FF) == 0xd503302F) {
        // CLREX
        mon_excl_valid = 0;
        rPC += 4;
    } else if ((instruction & 0xFFFFF01F) == 0xd503301F) {
	// DSB, DMB, ISB
	// And some misc. invalid instructions.
	rPC += 4;
    } else {
	UNIMP("system class instruction");
    }
}

// Syscall logging. Keep a small circular buffer.
#define SYSCALL_BUFLEN 4
typedef struct {
  long func;
  long arg[6];
  long time;
} syscall_log_entry;
static syscall_log_entry syscall_buf[SYSCALL_BUFLEN];
static int syscall_idx = 0;

void sim_handle_simulation_request(u32 instruction, u64 request)
{
    int on_bit = request & 1;
    char *on_str = on_bit ? "on" : "off";

    // NOTE: the variable 'on' has been set to the low order bit of the request
    // to indicate if the feature is intended to be turned on (1) or off (0).

    switch (request) {
    case 0x41:                 // 41 and 42 are New values used by FastSIM
    case 0x42:
    case 0:
    case 1:
        trace = on_bit;
        // printf("Tracing %s\n", on_str);
        return;
    case 2:
    case 3:
        ftrace = on_bit;
        // printf("F-Tracing %s\n", on_str);
        return;
    case 4:
    case 5:
        step = on_bit;
        // printf("Stepping %s\n", on_str);
        break;
    case 6:
    case 7:
        quiet = on_bit;
        // printf("Quiet %s\n", on_str);
        break;
    case 8:
        // Abort debugging
        printf("Abort requested!\n");
        regdump(rPC, -1, 1);
        printf("\nLast %d syscalls\n", SYSCALL_BUFLEN);
        for (int i = 0; i < SYSCALL_BUFLEN; i++) {
          int j = (syscall_idx + i) % SYSCALL_BUFLEN;
          printf("time %lx func d#%3ld arg %09lx %09lx %09lx %09lx %09lx %09lx\n",
              syscall_buf[j].time, syscall_buf[j].func,
              syscall_buf[j].arg[0], syscall_buf[j].arg[1], syscall_buf[j].arg[2],
              syscall_buf[j].arg[3], syscall_buf[j].arg[4], syscall_buf[j].arg[5]);
        }
        break;
    case 30:
        // Return the instruction counter; it suffices early on as an
        // indication of the passage of time.
        r[0] = (primitive_instruction_count + instruction_count);
        break;
    default:
	UNIMP("Simulation request undefined");
	break;
    }
}

static void print_sim_ldst_records(void);
static void sim_exception(u32 instruction)
{
    RD_INSTR;
    u64 imm = OP(5, 20);
    long (*func)(long r0, long r1, long r2, long r3, long r4, long r5);

    if (no_svc_support) {
        printf("ERROR: A SVC instruction was issued: imm = %llx\n", imm);
        s_bye(-1);
    }

    if (imm < 128) {
	sim_handle_simulation_request(instruction, imm);
	rPC += 4;
	return;
    }

    switch (imm) {
    case 128:
        if (gSyscall_vec) {
            // Handle Forth wrapper calls - the call# is in tos.
            // Note the call# is not the index into the syscall
            // array, but is instead the offset from the base of the
            // array IF the array of function pointers was an array
            // of 4-byte quantities. (Why did we do it this way?) Our
            // array is of course either 4-byte or 8-byte depending
            // on whether the wrapper/simulator is compiled as i386
            // or x86_64. D'oh. Hence turn that offset back into a
            // simple index by dividing by 4.

	    if (r[TOS] == /* s_bye */ 36) {
                // print_sim_ldst_records();
	    }

            // Log syscall for debugging. See "svc #8" above.
            syscall_buf[syscall_idx].func = r[TOS] / 4;
            for (int i = 0; i < 6; i++) {
              syscall_buf[syscall_idx].arg[i] = r[i];
            }
            syscall_buf[syscall_idx].time = (primitive_instruction_count + instruction_count);
            syscall_idx = (syscall_idx + 1) % SYSCALL_BUFLEN;

            func = gSyscall_vec[r[TOS] / 4];
            r[0] = func(r[0], r[1], r[2], r[3], r[4], r[5]);
        } else {
            printf("ERROR: A SVC call to a syscall_vec[%d] issued\n", (int) (r[TOS] / 4));
            s_bye(-1);
        }
        break;
    default:
        UNIMP("exception class instruction");
    }

    rPC += 4;
}

/*
 * sim_ldr_sz() returns the size of the destination register into which
 * this operation gets written.
 */

#define XREG_SZ        8
#define WREG_SZ        4
#define LD_OP          1
#define ST_OP          0
#define SIGN_EXT       1
#define ZERO_EXT       0
#define BYTE_SZ        1
#define HALF_SZ        2
#define WMEM_SZ        4
#define XMEM_SZ        8

#define LDST(_ld, _rsz, _msz, _sx)   p->ldst = _ld;     \
                                     p->reg_sz = _rsz;  \
                                     p->mem_sz = _msz;  \
                                     p->sx = _sx; break

#define LDW(_msz, _sx)  LDST(LD_OP, WREG_SZ, _msz, _sx)
#define LDX(_msz, _sx)  LDST(LD_OP, XREG_SZ, _msz, _sx)
#define STW(_msz)       LDST(ST_OP, WREG_SZ, _msz, ZERO_EXT)
#define STX(_msz)       LDST(ST_OP, XREG_SZ, _msz, ZERO_EXT)

typedef struct ldr_attr_s {
    int ldst, mem_sz, reg_sz, sx;
} ldr_attr_t;

static void sim_ldr_attr(u32 instruction, ldr_attr_t *p)
{
    int idx = (OP(30,31) << 2) | (OP(22,23));

    UNIMPIF(idx > 16, "SIMULATOR ERROR");
    switch (idx) {
    case 0:  /* STRB  Wn */ STW(BYTE_SZ);
    case 1:  /* LDRB  Wn */ LDW(BYTE_SZ, ZERO_EXT);
    case 2:  /* LDRSB Xn */ LDX(BYTE_SZ, SIGN_EXT);
    case 3:  /* LDRSB Wn */ LDW(BYTE_SZ, SIGN_EXT);
    case 4:  /* STRH  Wn */ STW(HALF_SZ);
    case 5:  /* LDRH  Wn */ LDW(HALF_SZ, ZERO_EXT);
    case 6:  /* LDRSH Xn */ LDX(HALF_SZ, SIGN_EXT);
    case 7:  /* LDRSH Wn */ LDW(HALF_SZ, SIGN_EXT);
    case 8:  /* STR   Wn */ STW(WMEM_SZ);
    case 9:  /* LDR   Wn */ LDW(WMEM_SZ, ZERO_EXT);
    case 10: /* LDRSW Xn */ LDX(WMEM_SZ, SIGN_EXT);
    case 11: /* ILLEGAL  */ UNIMP("Unsupported Load/Store");
    case 12: /* STR   Xn */ STX(XMEM_SZ);
    case 13: /* LDR   xn */ LDX(XMEM_SZ, ZERO_EXT);
    case 14: /* PRFM */     UNIMP("Unsupported Prefetch");
    case 15: /* ILLEGAL  */ UNIMP("Unsupported Load/Store");
    }
}

static void sim_ld(u32 instruction, u64 addr, ldr_attr_t *p)
{
    u8 b;
    s8 sb;
    u16 h;
    s16 sh;
    u32 w;
    s32 sw;
    u64 x;
    s64 sx;

    if ((p->mem_sz == XMEM_SZ) && (p->reg_sz == XREG_SZ)) {
        RDZ = MEM(u64, addr);
        rZERO = 0;
	rPC += 4;
        return;
    }

    switch (p->mem_sz) {
    case XMEM_SZ:
        if (p->sx) sx = sw = MEM(s64, addr);
        else        x =  w = MEM(u64, addr);
        break;
    case WMEM_SZ:
        if (p->sx) sx = sw = MEM(s32, addr);
        else        x =  w = MEM(u32, addr);
        break;
    case HALF_SZ:
        if (p->sx) sx = sw = MEM(s16, addr);
        else        x =  w = MEM(u16, addr);
        break;
    case BYTE_SZ:
        if (p->sx) sx = sw = MEM(s8, addr);
        else        x =  w = MEM(u8, addr);
        break;
    }

    switch (p->reg_sz) {
    case XREG_SZ: RDZ = p->sx ? sx : x; break;
    case WREG_SZ: RDZ = p->sx ? sw : w; break;
    }
    rZERO = 0;
    rPC += 4;
}

static void sim_st(u32 instruction, u64 addr, ldr_attr_t *p)
{
    if ((addr == 0xC0) && (RDZ == 0x1234))
	done = 1;

    switch (p->mem_sz) {
    case XMEM_SZ: MEM(u64, addr) = RDZ; break;
    case WMEM_SZ: MEM(u32, addr) = RDZ; break;
    case HALF_SZ: MEM(u16, addr) = RDZ; break;
    case BYTE_SZ: MEM(u8, addr)  = RDZ; break;
    }
    rPC += 4;
}

#define MAX_LDST_RECORDS	50
typedef struct sim_ldst_record_s {
    u8 type, op;
    long count;
} sim_ldst_record_t;

sim_ldst_record_t sim_ldst_records[MAX_LDST_RECORDS];
int num_ldst_records = 0;

static void sim_ldst_record(u32 instruction, int type)
{
    sim_ldst_record_t  *r;
    u8 op = (OP(30,31) << 2) | (OP(22,23));

    for (int i = 0; i < num_ldst_records; i++) {
        r = &sim_ldst_records[i];
        if (r->type != type) continue;
        if (r->op != op) continue;
        r->count ++;

        while (i-- > 0) {
            if (r->count < sim_ldst_records[i].count) {
                break;
            }
            // printf("Swapping\n"); fflush(stdout);
            sim_ldst_record_t t = sim_ldst_records[i];
            sim_ldst_records[i] = *r;
            *r = t;
        }

        // printf("sim_ldst_record() done\n"); fflush(stdout);
        return;
    }

    // printf("Installing ldst_record()\n"); fflush(stdout);
    r = &sim_ldst_records[num_ldst_records++];
    r->type = type;
    r->op = op;
    r->count = 1;
    if (num_ldst_records == MAX_LDST_RECORDS) {
        num_ldst_records--;
    }
}

static void print_sim_ldst_records(void)
{
    ldr_attr_t p;
    u32 instr;
    sim_ldst_record_t  *r;

    printf("Printing the SIMULATOR LDST records\n");
    fflush(stdout);

    for (int i = 0; i < 20; i++) {
        if (i >= num_ldst_records) break;
        r = &sim_ldst_records[i];
        instr = ((r->op & 12) << 28) | ((r->op & 3) << 22);
        sim_ldr_attr(instr, &p);

        printf("%ld: (0x%.4x)  %s - %s: reg_sz = %d, mem_sz = %d, sx = %d\n",
               r->count,
               r->op + ((r->type -1) << 4) + (p.ldst << 12),
               p.ldst == LD_OP ? "ld" : "st",
               r->type == 1 ? "post" :
               r->type == 2 ? "pre" :
               r->type == 3 ? "imm" :
               r->type == 4 ? "reg" :
               "unknown",
               p.reg_sz * 8,
               p.mem_sz * 8,
               p.sx);
    }
}

static void sim_ldst(u32 instruction, u64 addr, ldr_attr_t *p)
{
    UNIMPIF(p->reg_sz < p->mem_sz, "SIZE ERROR-- SIM BUG");

    if (p->ldst) sim_ld(instruction, addr, p);
    else         sim_st(instruction, addr, p);
}

static void sim_pop_x0(u32 instruction)
{
    r[0] = MEM(u64, rDSP);
    rDSP += 8;
    rPC += 4;
}

static void sim_pop_tos(u32 instruction)
{
    rTOS = MEM(u64, rDSP);
    rDSP += 8;
    rPC += 4;
}

static void sim_ldrb_Wn_post(u32 instruction)
{
    RD_INSTR;

    RDZ = MEM(u8, RNSP);
    RNSP += SXOP(12,20);
    rPC += 4;
}

static void sim_ldr_Wn_post(u32 instruction)
{
    RD_INSTR;

    RDZ = MEM(u32, RNSP);
    RNSP += SXOP(12,20);
    rPC += 4;
}

static void sim_ldr_Xn_post(u32 instruction)
{
    RD_INSTR;

    RDZ = MEM(u64, RNSP);
    RNSP += SXOP(12,20);
    rPC += 4;
}

static void sim_strb_Wn_post(u32 instruction)
{
    RD_INSTR;

    MEM(u8, RNSP) = RDZ;
    RNSP += SXOP(12,20);
    rPC += 4;
}

static void sim_str_Wn_post(u32 instruction)
{
    RD_INSTR;

    MEM(u32, RNSP) = RDZ;
    RNSP += SXOP(12,20);
    rPC += 4;
}

static void sim_str_Xn_post(u32 instruction)
{
    RD_INSTR;

    MEM(u64, RNSP) = RDZ;
    RNSP += SXOP(12,20);
    rPC += 4;
}

static ifunc_t decode_ldr_post(u32 instruction)
{
    int idx = (OP(30,31) << 2) | (OP(22,23));
    switch (idx) {
    case 0:  /* STRB  Wn */  return sim_strb_Wn_post;
    case 1:  /* LDRB  Wn */  return sim_ldrb_Wn_post;
    case 8:  /* STR   Wn */  return sim_str_Wn_post;
    case 9:  /* LDR   Wn */  return sim_ldr_Wn_post;
    case 12: /* STR   Xn */  return sim_str_Xn_post;
    case 13: /* LDR   Xn */  return sim_ldr_Xn_post;
    }
    return sim_ldr_post;
}

static void sim_ldr_post(u32 instruction)
{
    RD_INSTR;
    ldr_attr_t p;

    sim_ldr_attr(instruction, &p);
    sim_ldst(instruction, RNSP, &p);
    // sim_ldst_record(instruction, 1);
    RNSP += SXOP(12,20);
}

static void sim_push_tos(u32 instruction)
{
    rDSP -= 8;
    MEM(u64, rDSP) = rTOS;
    rPC += 4;
}

static void sim_push_ip(u32 instruction)
{
    rRP -= 8;
    MEM(u64, rRP) = rIP;
    rPC += 4;
}

static ifunc_t decode_ldr_pre(u32 instruction)
{
    return sim_ldr_pre;
}

static void sim_ldr_pre(u32 instruction)
{
    RD_INSTR;
    ldr_attr_t p;

    sim_ldr_attr(instruction, &p);
    RNSP += SXOP(12,20);
    sim_ldst(instruction, RNSP, &p);
    // sim_ldst_record(instruction, 2);
}

static void sim_ldrb_Wn_imm(u32 instruction)
{
    RD_INSTR;
    u64 addr = RNSP + (OP(10,21) * 1);
    RDZ = MEM(u8, addr);
    rPC += 4;
}

static void sim_ldr_Wn_imm(u32 instruction)
{
    RD_INSTR;
    u64 addr = RNSP + (OP(10,21) * 4);
    RDZ = MEM(u32, addr);
    rPC += 4;
}

static void sim_ldr_Xn_imm(u32 instruction)
{
    RD_INSTR;
    u64 addr = RNSP + (OP(10,21) * 8);
    RDZ = MEM(u64, addr);
    rPC += 4;
}

static void sim_strb_Wn_imm(u32 instruction)
{
    RD_INSTR;
    u64 addr = RNSP + (OP(10,21) * 1);
    MEM(u8, addr) = RDZ;
    rPC += 4;
}

static void sim_str_Wn_imm(u32 instruction)
{
    RD_INSTR;
    u64 addr = RNSP + (OP(10,21) * 4);
    MEM(u32, addr) = RDZ;
    rPC += 4;
}

static void sim_str_Xn_imm(u32 instruction)
{
    RD_INSTR;
    u64 addr = RNSP + (OP(10,21) * 8);
    MEM(u64, addr) = RDZ;
    rPC += 4;
}

static ifunc_t decode_ldr_imm(u32 instruction)
{
    int idx = (OP(30,31) << 2) | (OP(22,23));
    switch (idx) {
    case 0:  /* STRB  Wn */  return sim_strb_Wn_imm;
    case 1:  /* LDRB  Wn */  return sim_ldrb_Wn_imm;
    case 8:  /* STR   Wn */  return sim_str_Wn_imm;
    case 9:  /* LDR   Wn */  return sim_ldr_Wn_imm;
    case 12: /* STR   Xn */  return sim_str_Xn_imm;
    case 13: /* LDR   Xn */  return sim_ldr_Xn_imm;
    }
    return sim_ldr_imm;
}

static void sim_ldr_imm(u32 instruction)
{
    RD_INSTR;
    ldr_attr_t p;

    sim_ldr_attr(instruction, &p);
    sim_ldst(instruction, RNSP + (OP(10,21) * p.mem_sz), &p);
    // sim_ldst_record(instruction, 3);
}

static void sim_ldr_exc(u32 instruction)
{
    RD_INSTR;
    ldr_attr_t p;
    u32 op = (OP_B(23) << 2) | (OP_B(21) << 1) | (OP_B(15) << 0);
    u32 load = OP_B(22);
    u32 pair = OP_B(21);
    u32 size = OP_PAIR(30);

    rPC += 4;

    if (OP_PAIR(30) < 2) {
        // Byte / Half ops
        UNIMPIF(pair, "There are no exclusive PAIR OPS with Byte or Half-word ops");
        UNIMPIF(OP_B(23) && !OP_B(15), "Funny Exclusive Byte or Half-word op");
    } else {
        UNIMPIF(op == 4, "Funny Exclusive Word or X-sized op");
        UNIMPIF(op > 5,  "Funny Exclusive (more) Word or X-sized op");
    }

    if (load) {
        // Load ops
        // printf("Exclusive address latched: %llx\n", RNSP);
        mon_excl_addr = RNSP;
        mon_excl_valid = 1;
        UNIMPIF(RM != 0x1F, "LDR Exclusive must have RS (RM) == 31");
        UNIMPIF(!pair && (RT2 != 0x1F), "Exclusive OPS must have RT2 == 0x1F");
        switch (size) {
        case 0:  r[RT] = MEM(u8,  RNSP);  break;
        case 1:  r[RT] = MEM(u16, RNSP);  break;
        case 2:  r[RT] = MEM(u32, RNSP);  break;
        case 3:  r[RT] = MEM(u64, RNSP);  break;
        }
        if (pair) {
            switch (size) {
            case 2: r[RT2] = MEM(u32, RNSP + 4);  break;
            case 3: r[RT2] = MEM(u64, RNSP + 8);  break;
            default: UNIMP("Illegal exclusive op, but this is a simulator error");
            }
        }
    } else {
        if (!mon_excl_valid) {
            printf("Exclusive instruction failed: excl_valid == 0\n");
            RMZ = 1;
            return;
        }
        if (mon_excl_addr != RNSP) {
            printf("Exclusive instruction failed: excl_addr == %llx, RNSP == %llx\n", mon_excl_addr, RNSP);
            RMZ = 1;
            return;
        }
        RMZ = 0;
        switch (size) {
        case 0:  MEM(u8,  RNSP) = r[RT];  break;
        case 1:  MEM(u16, RNSP) = r[RT];  break;
        case 2:  MEM(u32, RNSP) = r[RT];  break;
        case 3:  MEM(u64, RNSP) = r[RT];  break;
        }
        if (pair) {
            switch (size) {
            case 2: MEM(u32, RNSP + 4) = r[RT2];  break;
            case 3: MEM(u64, RNSP + 8) = r[RT2];  break;
            default: UNIMP("Illegal exclusive op, but this is a simulator error");
            }
        }
    }
    // printf("X0 = %llx, X1 = %llx, X2 = %llx\n", r[0], r[1], r[2]);
}

static void sim_ldrsw_x0_ip(u32 instruction)
{
    r[0] = (s64) MEM(s32,r[IP]);
    rPC += 4;
}

static void sim_ldrb_Wn_reg(u32 instruction)
{
    RD_INSTR;
    int option = OP(13, 15);
    int shift = OP_B(12) ? OP_PAIR(30) : 0;
    u64 addr = RNSP + ExtendReg(RMZ, option, shift);
    RDZ = MEM(u8, addr);
    rPC += 4;
}

static void sim_ldr_Wn_reg(u32 instruction)
{
    RD_INSTR;
    int option = OP(13, 15);
    int shift = OP_B(12) ? OP_PAIR(30) : 0;
    u64 addr = RNSP + ExtendReg(RMZ, option, shift);
    RDZ = MEM(u32, addr);
    rPC += 4;
}

static void sim_ldr_Xn_reg(u32 instruction)
{
    RD_INSTR;
    int option = OP(13, 15);
    int shift = OP_B(12) ? OP_PAIR(30) : 0;
    u64 addr = RNSP + ExtendReg(RMZ, option, shift);
    RDZ = MEM(u64, addr);
    rPC += 4;
}

static void sim_strb_Wn_reg(u32 instruction)
{
    RD_INSTR;
    int option = OP(13, 15);
    int shift = OP_B(12) ? OP_PAIR(30) : 0;
    u64 addr = RNSP + ExtendReg(RMZ, option, shift);
    MEM(u8, addr) = RDZ;
    rPC += 4;
}

static void sim_str_Wn_reg(u32 instruction)
{
    RD_INSTR;
    int option = OP(13, 15);
    int shift = OP_B(12) ? OP_PAIR(30) : 0;
    u64 addr = RNSP + ExtendReg(RMZ, option, shift);
    MEM(u32, addr) = RDZ;
    rPC += 4;
}

static void sim_str_Xn_reg(u32 instruction)
{
    RD_INSTR;
    int option = OP(13, 15);
    int shift = OP_B(12) ? OP_PAIR(30) : 0;
    u64 addr = RNSP + ExtendReg(RMZ, option, shift);
    MEM(u64, addr) = RDZ;
    rPC += 4;
}

static ifunc_t decode_ldr_reg(u32 instruction)
{
    int idx = (OP(30,31) << 2) | (OP(22,23));
    switch (idx) {
    case 0:  /* STRB  Wn */  return sim_strb_Wn_reg;
    case 1:  /* LDRB  Wn */  return sim_ldrb_Wn_reg;
    case 8:  /* STR   Wn */  return sim_str_Wn_reg;
    case 9:  /* LDR   Wn */  return sim_ldr_Wn_reg;
    case 12: /* STR   Xn */  return sim_str_Xn_reg;
    case 13: /* LDR   Xn */  return sim_ldr_Xn_reg;
    }
    return sim_ldr_reg;
}

static void sim_ldr_reg(u32 instruction)
{
    RD_INSTR;
    ldr_attr_t p;
    int option = OP(13, 15);
    int shift = OP_B(12) ? OP_PAIR(30) : 0;

    // Check for PRFM <prfop>, [<Xn|SP>, <R><m>{, <extend> {<amount>}}]
    if ((instruction & 0xFFE00C00) == 0xF8A00800) return;

    UNIMPIF(OP_B(26), "Vector instructions are not supported");
    sim_ldr_attr(instruction, &p);
    sim_ldst(instruction, RNSP + ExtendReg(RMZ, option, shift), &p);
    // sim_ldst_record(instruction, 4);
}

/*************************************************************
 *
 * Disassembler
 *
 *************************************************************/

// Register fields
#define REG_D              0
#define REG_N              1
#define REG_M              2
#define REG_A              3
#define REG_FIELDS         4

// Register sizes: 0 = W, 1 = X
int dis_reg_sz[REG_FIELDS];

// Register bit field (lowest bit number)
const int dis_reg_lo[REG_FIELDS] = { 0, 5, 16, 10 };

static void dis_call_dis_func(void(*dis_func)(u64,u32),u64 iaddr, u32 instr)
{
    int i;

    for (i = 0; i < REG_FIELDS; i++) {
        dis_reg_sz[i] = -1;
    }

    dis_func(iaddr, instr);
}

static void dis_unimpl(u64 iaddr, u32 instr, const char *func)
{
    printf(" ++ (%s) DIS_UNIMP %x\n", func, instr);
    fflush(stdout);
}

static void inv_instr(u64 iaddr, u32 instr, const char *func)
{
    printf("%8.8x INVALID INSTRUCTION (%s)\n", instr, func);
    fflush(stdout);
}

void dis_reg_reset(void);

int dis_show_registers;

void disassemble(u64 iaddr, u32 instr, int options)
{
    int i;

    dis_reg_reset();

    dis_show_registers = (options & DIS_YES_REGISTERS) ? 1 : 0;

    for (i = 0; i < decode_sz; i++) {
        decode_t *p = &decode_table[i];

        if ((instr & p->mask) == p->match) {
            dis_call_dis_func(p->dis_func, iaddr, instr);
            return;
        }
    }

    printf("%08llx [ %8ld ]: %8.8x:  -- Unimplemented instruction\n", iaddr, (primitive_instruction_count + instruction_count), instr);
}

int dis_op_match(char **op_fmt, char *str)
{
    int len = strlen(str);
    if (strncmp(*op_fmt, str, len) == 0) {
            *op_fmt += len;
            return 1;
    }
    return 0;
}

const char *dis_reg_str(int reg_num)
{
    char *reg_name;

    switch (reg_num) {
    case LP:   reg_name = "lp";  break;
    case ORG:  reg_name = "org"; break;
    case UP:   reg_name = "up";  break;
    case TOS:  reg_name = "tos"; break;
    case RP:   reg_name = "rp";  break;
    case IP:   reg_name = "ip";  break;
    case LR:   reg_name = "lr";  break;
    case DSP:  reg_name = "sp";  break;
    case SP:   reg_name = "ssp"; break;
    case 31:   reg_name = "zr";  break;
    default:   reg_name = NULL;  break;
    }

    return reg_name;
}

static int dis_regs_used[4];
static int dis_num_regs_used;
static int dis_reg_targets[4];
static int dis_num_reg_targets;

#define XREG_BIT           64

void dis_reg_reset(void)
{
    dis_num_regs_used = 0;
    dis_num_reg_targets = 0;
}

void dis_reg_used(int n, int sz)
{
    if (sz == XREG_SZ) {
        n |= XREG_BIT;
    }

    dis_regs_used[dis_num_regs_used++] = n;
}

int dis_get_used(int idx)
{
    if (idx >= dis_num_regs_used) {
        return -1;
    }

    return dis_regs_used[idx];
}

void dis_reg_target(int n, int sz)
{
    if (sz == XREG_SZ) {
        n |= XREG_BIT;
    }

    dis_reg_targets[dis_num_reg_targets++] = n;
}

int dis_get_target(int idx)
{
    if (idx >= dis_num_reg_targets) {
        return -1;
    }

    return dis_reg_targets[idx];
}

void dis_print_reg_list(int (*reg_list_func)(int idx), const char *eq_str)
{
    int idx;
    int sf;

    idx = 0;
    do {
        int rn = reg_list_func(idx++);
        const char *reg_name;

        if (rn < 0) break;
        if (rn & XREG_BIT) {
            rn ^= XREG_BIT;
            sf = 1;
        } else {
            sf = 0;
        }

        reg_name = dis_reg_str(rn);
        if (!sf) printf("W");

        if (reg_name) {
            printf("%s", reg_name);
        } else {
            if (sf) printf("X");
            printf("%d", rn);
        }
        printf(" %s %#llx, ", eq_str, MASK32(r[rn], sf));
    } while (1);

}

void disassemble_finish(void)
{
    dis_print_reg_list(dis_get_target, "<-");
    printf("\n");
}

int dis_print_reg(u32 instruction, char reg_type, int or_sp, int read, int target)
{
    int r, n, sz;
    const char *reg_name;

    switch (reg_type) {
    case 'd': r = REG_D; break;
    case 'n': r = REG_N; break;
    case 'm': r = REG_M; break;
    case 'a': r = REG_A; break;
    default:
        printf("\nERROR: Unknown named register field: %c\n", reg_type);
        return 0;
    }

    sz = dis_reg_sz[r];

    n = OP(dis_reg_lo[r], dis_reg_lo[r]+4);
    if (or_sp && (n == 31)) {
        if (target) { dis_reg_target(SP, sz); }
        if (read)   { dis_reg_used(SP, sz); }
        if (sz == WREG_SZ) return printf("INVALID REGISTER (WSP)");
        else               return printf("XSP");
    }

    if (target) { dis_reg_target(n, sz); }
    if (read)   { dis_reg_used(n, sz); }

    reg_name = dis_reg_str(n);

    if (reg_name) {
            int len = 0;
            if (sz == 'w') len = printf("w");
            len += printf("%s", reg_name);
            return len;
    }

    if (sz == WREG_SZ) return printf("w%d", n);
    else               return printf("x%d", n);
}

void dis_print(u64 iaddr, u32 instruction, char *op_fmt, ...)
{
    va_list var_args;
    char *op_str;
    u64 v;
    s32 imm;
    int mode;  // 0 = instr, 1 == operands, 2 == comments
    int col;

    mode = 0;
    col = 1;

    printf("%08llx [ %8ld ]: %8.8x:  ", iaddr, (primitive_instruction_count + instruction_count), instruction);


    va_start(var_args, op_fmt);
    op_str = op_fmt;
    while (*op_fmt) {
    char fmt = *op_fmt++;
    if (fmt == '%') {
        fmt = *op_fmt++;  // We've consumed the % character
        switch(fmt) {
        default:
            printf("\nUNKNWON FORMAT specifier: %c\nformat string: %s\n", fmt, op_str);
            break;
        case '%':
            putchar(fmt);
            col ++;
            break;
        case 's':
            col += printf("%s", va_arg(var_args, char *));
            break;
        case 'd':
            v = va_arg(var_args, u64);
            col += printf("%lld", v);
            break;
        case 'x':
            v = va_arg(var_args, u64);
            col += printf("%llx", v);
            break;
        case 'r':   // Register is read
            if (dis_op_match(&op_fmt, "n|sp")) {
                dis_reg_sz[REG_N] = XREG_SZ;
                col += dis_print_reg(instruction, 'n', 1, 1, 0);
            } else if (dis_op_match(&op_fmt, "d|sp")) {
                dis_reg_sz[REG_D] = XREG_SZ;
                col += dis_print_reg(instruction, 'd', 1, 1, 0);
            } else {
                col += dis_print_reg(instruction, *op_fmt++, 0, 1, 0);
            }
            break;
        case 'R':  // Register is updated
            if (dis_op_match(&op_fmt, "n|sp")) {
                dis_reg_sz[REG_N] = XREG_SZ;
                col += dis_print_reg(instruction, 'n', 1, 0, 1);
            } else if (dis_op_match(&op_fmt, "d|sp")) {
                dis_reg_sz[REG_D] = XREG_SZ;
                col += dis_print_reg(instruction, 'd', 1, 0, 1);
            } else {
                col += dis_print_reg(instruction, *op_fmt++, 0, 0, 1);
            }
            break;
        case 'U':  // Register is read/write, i.e., Updated
            if (dis_op_match(&op_fmt, "n|sp")) {
                dis_reg_sz[REG_N] = XREG_SZ;
                col += dis_print_reg(instruction, 'n', 1, 1, 1);
            } else if (dis_op_match(&op_fmt, "d|sp")) {
                dis_reg_sz[REG_D] = XREG_SZ;
                col += dis_print_reg(instruction, 'd', 1, 1, 1);
            } else {
                col += dis_print_reg(instruction, *op_fmt++, 0, 1, 1);
            }
            break;
        }
    } else if (fmt == '$') {
        imm = va_arg(var_args, s32);
        if (imm >=0 ) col += printf("$+%d", imm);
        else          col += printf("$%d", imm);
    } else if (fmt == ' ') {
        int tab_stop;
        switch (mode) {
        case 0: tab_stop = 12; break;
        case 1: tab_stop = 30; break;
        default: printf("\ERROR too many spaces in the format string: %s\n", op_str);
            break;
        }

        do {
            col += printf(" ");
        } while (col < tab_stop);
        mode++;
        if (mode == 2) col += printf("; ");
    } else if (fmt == '#') {
        imm = -1;
        if (dis_op_match(&op_fmt, "<pimm12>")) {
            imm = SXOP(10,21);
        }
        if (dis_op_match(&op_fmt, "<simm9>")) {
            imm = SXOP(12,20);
        }
        if (dis_op_match(&op_fmt, "%d")) {
            imm = va_arg(var_args, s32);
        }

        col += printf(" #%d", imm);
    } else if (fmt == '{') {
        if (dis_op_match(&op_fmt, ",#%d}")) {
            int offset = va_arg(var_args, s32);
            if (offset) {
                col += printf(", #%d", offset);
            }
        }
    } else {
        putchar(fmt);
        col ++;
    }

    }
    va_end(var_args);

    if (!dis_show_registers) {
        printf("\n");
        return;
    }

    // Else, print out the instruction's registers

    if (mode < 2) {
        while (col < 30) {
            col += printf(" ");
        }
        printf("; ");
    } else {
        // There's already something in the comment block, set it off
        printf(", ");
    }

    dis_print_reg_list(dis_get_used, "=");
    fflush(stdout);
}

void dis_adr(u64 iaddr, u32 instruction)
{
    /* PC Relative addressing */
    s64 imm, base;
    int page;
    char *instr_str = "adr";

    page = OP_B(31);
    sext21.imm21 = (OP(5,23) << 2) | OP(29,30);
    base = iaddr;
    imm = sext21.imm21;
    if (page) {
        imm <<= 12;
        base &= ~0xFFF;
        instr_str = "adrp";
    }
    dis_print(iaddr, instruction, "%s %Rd,$ addr=0x%x", instr_str, imm, base + imm);
}

#define INV_INSTR()     inv_instr(iaddr, instruction, __FUNCTION__)
#define INV_INSTRIF(x,str)  do { if (x) { printf(str); INV_INSTR(); } } while (0)
#define DIS_UNIMPL()    dis_unimpl(iaddr, instruction, __FUNCTION__)

void dis_add_sub_imm(u64 iaddr, u32 instruction)
{
    int sf = OP_B(31);
    int sub = OP_B(30);
    int s = OP_B(29);
    int shift = OP(22,23);
    int imm = OP(10,21);
    char *op, *ss;

    op = sub ? "sub" : "add";
    ss = s ? "s" : "";

    dis_reg_sz[REG_D] = dis_reg_sz[REG_N] = sf ? XREG_SZ : WREG_SZ;

    if (shift == 0) {
        if (s) {
            dis_print(iaddr, instruction, "%s%s %Rd,%rn,#<pimm12>", op, ss);
        } else {
            dis_print(iaddr, instruction, "%s%s %Rd|sp,%rn,#<pimm12>", op, ss);
        }
    } else if (shift == 1) {
        if (s) {
            dis_print(iaddr, instruction, "%s%s %Rd,%rn,#<pimm12>,lsl#%d %x", op, ss, 12, imm << 12);
        } else {
            dis_print(iaddr, instruction, "%s%s %Rd|sp,%rn,#<pimm12>,lsl#%d %x", op, ss, 12, imm << 12);
        }
    } else {
        INV_INSTR();
    }
}

void dis_logical_imm(u64 iaddr, u32 instruction)
{
    /* Logical (immediate) */
    int sf = OP_B(31);
    int op = OP_PAIR(29);
    int n = OP_B(22);
    int immr = OP(16, 21);
    int n_imms, imms = OP(10, 15);
    int rr, ss, len, size, datasize;
    u64 mask;
    u64 imm, pattern;

    datasize = sf ? 64 : 32;

    INV_INSTRIF(!sf && n, "<logical-op> Wn, #<val> with the N bit set is an error");

    n_imms = MASK(6) ^ imms;
    len = HighestSetBit((n << 6) | n_imms);
    INV_INSTRIF(len < 1, "<logical-op> Wn, #<val> with a HighestSetBit() of < 1");
    size = 1 << len;
    mask = MASK(len);
    rr = immr & mask;
    ss = imms & mask;
    if (ss == (size -1)) {
	printf("ss == %d, size == %d, size-1 == %d, imms == %x, mask = %llx, imms & mask = %llx\n", ss, size, size-1, imms, mask, imms & mask);
    }
    INV_INSTRIF(ss == (size - 1), "<logical-op> Wn, #<val> with S == (size -1)");
    pattern = MASK(ss+1);
    pattern = ROR(pattern, size, rr);
    imm = Replicate(pattern, size, datasize >> len);
    if (0) {
	printf("(%d, %d, %d) --> %llx\n", len, size, datasize >> len, imm);
    }

    dis_reg_sz[REG_D] = dis_reg_sz[REG_N] = sf ? XREG_SZ : WREG_SZ;

    const char *dis_op_str[] = {"and", "orr", "eor", "ands" };
    const char *op_str = dis_op_str[op];

    dis_print(iaddr, instruction, "%s %Rd,%rn{,#%d}", op_str, imm);
}

void dis_mov_nzk(u64 iaddr, u32 instruction)
{
    int sf = OP_B(31);
    int opc = OP(29,30);
    int hw = OP(21,22);
    int imm = OP(5,20);
    char *op_str;

    dis_reg_sz[REG_D] = sf ? XREG_SZ : WREG_SZ;
    if (OP_B(22) & !sf) {
        INV_INSTR();
        return;
    }

    switch (opc) {
    case 0: op_str = "movn"; break;
    case 2: op_str = "movz"; break;
    case 3: op_str = "movk"; break;
    default: INV_INSTR(); return;
    }

    if (!hw) {
        dis_print(iaddr, instruction, "%s %Rd,#%d 0x%x", op_str, imm);
    } else {
        dis_print(iaddr, instruction, "%s %Rd,#%d,lsl#%d", op_str, imm, hw * 16);
    }
}

void dis_bitfield(u64 iaddr, u32 instruction)
{
    /* Bitfield -- Move a bitfield from register to register */
    int sf = OP_B(31);
    int datasize = sf ? 64 : 32;
    int inzero, extend, diff;
    u64 sign, mask;
    int opc = OP_PAIR(29);
    int n = OP_B(22);
    int immr = OP(16,21);
    int imms = OP(10,15);
    u64 dst, src, res;

    UNIMPIF(n != sf, "BFM with improper sf/N encodings");
    if (datasize == 32) {
    UNIMPIF(imms >= 32, "BFM with improper imms encodings");
    UNIMPIF(immr >= 32, "BFM with improper immr encodings");
    }

    UNIMPIF(opc > 2, "Illegal BFM instruction OP encoding");

    char *istr = NULL;

    switch (opc) {
    case 0: istr = "sbfm"; break;  // SBFM
    case 1: istr = "bfm";  break;  // BFM
    case 2: istr = "ubfm"; break;  // UBFM
    }

    if (!istr) { INV_INSTR(); }
    else {
        dis_reg_sz[REG_D] = sf ? XREG_SZ : WREG_SZ;
        dis_print(iaddr, instruction, "%s %Rd,%rn,#%d,#%d", istr, immr, imms);
    }
}

void dis_extract(u64 iaddr, u32 instruction)
{
    int sf = OP_B(31);
    int n = OP_B(22);
    int lsb = OP(10, 15);

    UNIMPIF(!sf && (lsb >= 32), "Illegal EXTR encoding");
    UNIMPIF(sf != n, "Illegal EXTR encoding");

    dis_reg_sz[REG_D] = dis_reg_sz[REG_N] = dis_reg_sz[REG_M] = sf ? XREG_SZ : WREG_SZ;
    dis_print(iaddr, instruction, "EXTR %Rd,%rn,%rm,#%d", lsb);
}

void dis_br_imm(u64 iaddr, u32 instruction)
{
    s64 imm26 = SXOP(0,25) << 2;
    int link = OP_B(31);
    char *istr;

    if (link) istr = "bl";
    else      istr = "b";

    dis_print(iaddr, instruction, "%s $ 0x%x", istr, imm26, iaddr + imm26);
}

void dis_cmp_br_imm(u64 iaddr, u32 instruction)
{
    int sf = OP_B(31);
    int iszero = OP_B(24) == 0;
    u64 imm19 = SXOP(5, 23) << 2;
    int rt = OP(0, 4);
    char *istr;

    if (iszero) istr = "cbz";
    else        istr = "cbnz";

    dis_reg_sz[REG_D] = sf ? XREG_SZ : WREG_SZ;

    dis_print(iaddr, instruction, "%s %rd,$ 0x%x", istr, imm19, iaddr + imm19);
}

void dis_test_bit_imm(u64 iaddr, u32 instruction)
{
    u64 operand = RDZ;
    int sf = OP_B(31);
    int bit_num = (OP_B(31) << 5) | OP(19, 23);
    s64 offset = SXOP(5, 18);
    int op = OP_B(24);

    dis_reg_sz[REG_D] = sf ? XREG_SZ : WREG_SZ;

    char *istr = NULL;

    if (op) istr = "TBNZ";
    else    istr = "TBZ";

    dis_print(iaddr, instruction, "%s %rd,#%d,$ 0x%x", istr, bit_num, offset, iaddr + offset);
}

const char *dis_cond_str[] = {
    "eq", "ne",
    "cs", "cc",
    "mi", "pl",
    "vs", "vc",
    "hi", "ls",
    "ge", "lt",
    "gt", "le",
    "al", "al-alt-"
};

void dis_br_cond_imm(u64 iaddr, u32 instruction)
{
    int o1 = OP_B(24);
    int o0 = OP_B(4);
    int cond = OP(0,3);
    int imm19 = SXOP(5,23);

    dis_print(iaddr, instruction, "b.%s $", dis_cond_str[cond], imm19 * 4);
}

void dis_exception(u64 iaddr, u32 instruction)
{
    int opc = OP(21,23);
    int imm = OP(5,20);
    int op2 = OP(2,4);
    int ll = OP(0,1);
    char *on_str = (imm & 1) ? "on" : "off";

    if (op2) {
        INV_INSTR();
        return;
    }

    if ((opc == 1) && (ll == 0)) {
        dis_print(iaddr, instruction, "brk %d", imm);
        return;
    }

    if ((opc == 0) && (ll == 1)) {
        switch (imm) {
        case 0:
        case 1:
            dis_print(iaddr, instruction, "trace-%s", on_str);
            break;
        case 2:
        case 3:
            dis_print(iaddr, instruction, "ftrace-%s", on_str);
            break;
        case 4:
        case 5:
            dis_print(iaddr, instruction, "stepping-%s", on_str);
            break;
        case 6:
        case 7:
            dis_print(iaddr, instruction, "quiet-%s", on_str);
            break;
        case 126: dis_print(iaddr, instruction, "instruction-count"); break;
        case 127: dis_print(iaddr, instruction, "find-next"); break;
        case 128: dis_print(iaddr, instruction, "wrapper-call"); break;
        default: dis_print(iaddr, instruction, "svc %d", imm); break;
        }
        return;
    }
    DIS_UNIMPL();
}

void dis_system(u64 iaddr, u32 instruction)
{
    int L = OP_B(21);
    int op0 = OP(19,20);
    int op1 = OP(16,18);
    int crn = OP(12,15);
    int crm = OP(8,11);
    int op2 = OP(5,7);
    int rt = OP(0,4);
    char *istr;

    if ((L == 0) && (op0 == 0) && (op1 == 3) && (rt == 31)) {
        int sys_hint = (crm << 3) | op2;
        if ((op2 == 2) && (crn == 3)) {
            istr = "clrex";
        } else {
            istr = NULL;
            switch (sys_hint) {
            case 0: istr = "nop"; break;
            case 1: istr = "yield"; break;
            case 2: istr = "wfe"; break;
            case 3: istr = "wfi"; break;
            case 4: istr = "sev"; break;
            case 5: istr = "sevl"; break;
            case 124: istr = "dsb sy"; break;
            }
        }
        if (istr) {
            dis_print(iaddr, instruction, "%s", istr);
        } else {
	    char *comment = "unknown";
	    switch (sys_hint) {
	    case 0x41: comment = "sim-trace-on"; break;
	    case 0x42: comment = "sim-trace-off"; break;
	    }
	    // Not perfect: the #%d syntax causes an extra space to be printed
	    // And, the sim-trace-{on,off} is followed by Tracing {on,off}
	    dis_print(iaddr, instruction, "hint #%d %s", sys_hint, comment);
        }
    } else if ((L == 0) && (op0 == 1)) {
	istr = NULL;

	dis_reg_sz[REG_D] = XREG_SZ;
	/* IC ops */
	if (IS_SYS_MATCH(0,7,1,0)) istr = "ic IALLUIS";
	if (IS_SYS_MATCH(0,7,5,0)) istr = "ic IALLU";
	if (IS_SYS_MATCH(3,7,5,1)) istr = "ic IVAU,%rd";

	/* DC ops */
	if (IS_SYS_MATCH(3,7,4,1))  istr = "dc ZVA,%rd";
	if (IS_SYS_MATCH(0,7,6,1))  istr = "dc IVAC,%rd";
	if (IS_SYS_MATCH(0,7,6,2))  istr = "dc ISW,%rd";
	if (IS_SYS_MATCH(3,7,10,1))  istr = "dc CVAC,%rd";
	if (IS_SYS_MATCH(0,7,10,2))  istr = "dc CSW,%rd";
	if (IS_SYS_MATCH(3,7,11,2))  istr = "dc CVAU,%rd";
	if (IS_SYS_MATCH(3,7,14,1))  istr = "dc CIVAC,%rd";
	if (IS_SYS_MATCH(0,7,14,2))  istr = "dc CISW,%rd";
	if (IS_SYS_MATCH(0,8,3,2))   istr = "isb sy";
	if (IS_SYS_MATCH(0,8,3,1))   istr = "tlbi aside1is";

	if (istr) {
	    dis_print(iaddr, instruction, istr);
	} else {
	    printf("Can't print instr with SYS_MATCH(%d,%d,%d,%d)\n", op1, crn, crm, op2);
	    INV_INSTR();
	}
    } else {
        char *istr;

        if (L)  istr = "mrs %Rd,3,#%d,CR%d,C%d,#%d";
        else    istr = "msr %Rd,3,#%d,CR%d,C%d,#%d";

        dis_reg_sz[REG_D] = XREG_SZ;
        dis_print(iaddr, instruction, istr, op1, crn, crm, op2);
    }
}

void dis_br_reg(u64 iaddr, u32 instruction)
{
    int opc = OP(21,24);
    int op2 = OP(16,20);
    int op3 = OP(10,15);
    int op4 = OP(0,4);
    int rn = OP(5,9);

    if ((op2 == 31) && (op3 == 0) && (op4 == 0)) {
        dis_reg_sz[REG_N] = XREG_SZ;

        switch (opc) {
        case 0: dis_print(iaddr, instruction, "br %rn"); return;
        case 1: dis_print(iaddr, instruction, "blr %rn"); dis_reg_target(LR, XREG_SZ); return;
        case 2: dis_print(iaddr, instruction, "ret %rn"); return;
        case 4:
        case 5:
            if (rn != 31) break;
            dis_print(iaddr, instruction, "%s", opc == 4 ? "eret" : "dret");
            return;
        }
    }

    INV_INSTR();
}

void dis_load_reg_lit(u64 iaddr, u32 instruction)
{
    DIS_UNIMPL();
}

static const char *ldst_str[] = {
    "st", "ld"
};
static const char *ldst_sz_str[8] = {
    "b", "sb", "h", "sh", "", "sw", "", ""
};

void dis_ldp(u64 iaddr, u32 instruction)
{
    /* Load/Store Register Pair */
    int sf = OP_B(31);
    int sz = 4 << sf;        // size of operands and scaling
    int load = OP_B(22);     // load or store
    int offset;
    int cmd = OP(23,24);

    UNIMPIF(OP_B(26), "Vector instructions are not supported");

    offset = SXOP(15,21) * sz;
    dis_reg_sz[REG_D] = dis_reg_sz[REG_A] = dis_reg_sz[REG_N] = sf ? XREG_SZ : WREG_SZ;

    switch (cmd) {
    case 0:
        if (load) dis_print(iaddr, instruction, "ldrnp %Rd,%Ra,[%rn|sp{,#%d}]", offset);
        else      dis_print(iaddr, instruction, "strnp %rd,%ra,[%rn|sp{,#%d}]", offset);
        break;
    case 1:
        if (load) dis_print(iaddr, instruction, "ldrp %Rd,%Ra,[%Un|sp],#%d", offset);
        else      dis_print(iaddr, instruction, "strp %rd,%ra,[%Un|sp],#%d", offset);
        break;
    case 2:
        if (load) dis_print(iaddr, instruction, "ldrp %Rd,%Ra,[%rn|sp{,#%d}]", offset);
        else      dis_print(iaddr, instruction, "strp %rd,%ra,[%rn|sp{,#%d}]", offset);
        break;
    case 3:
        if (load) dis_print(iaddr, instruction, "ldrp %Rd,%Ra,[%Un|sp,#%d]!", offset);
        else      dis_print(iaddr, instruction, "strp %rd,%ra,[%Un|sp,#%d]!", offset);
        break;
    }
}

void dis_ldr_post(u64 iaddr, u32 instruction)
{
    ldr_attr_t p;
    int idx;

    sim_ldr_attr(instruction, &p);
    dis_reg_sz[REG_D] = p.reg_sz;
    idx = (OP(30,31) << 1) | (OP_B(23));
    if (p.ldst) dis_print(iaddr, instruction, "ldr%s %Rd,[%rn|sp],#<simm9>", ldst_sz_str[idx]);
    else        dis_print(iaddr, instruction, "str%s %rd,[%rn|sp],#<simm9>", ldst_sz_str[idx]);
}

void dis_ldr_pre(u64 iaddr, u32 instruction)
{
    ldr_attr_t p;
    int idx;

    sim_ldr_attr(instruction, &p);
    dis_reg_sz[REG_D] = p.reg_sz;
    idx = (OP(30,31) << 1) | (OP_B(23));
    if (p.ldst) dis_print(iaddr, instruction, "ldr%s %Rd,[%Un|sp,#<simm9>]!", ldst_sz_str[idx]);
    else        dis_print(iaddr, instruction, "str%s %rd,[%Un|sp,#<simm9>]!", ldst_sz_str[idx]);
}

void dis_ldr_reg(u64 iaddr, u32 instruction)
{
    ldr_attr_t p;
    int shift = OP_B(12) ? OP_PAIR(30) : 0;
    int ext_type = OP(13, 15);
    char *ext_str;
    int idx;

    UNIMPIF(OP_B(26), "Vector instructions are not supported");
    if (OP_B(12) && (OP_PAIR(30) == 0)) {
        INV_INSTR();
        return;
    }

    sim_ldr_attr(instruction, &p);
    dis_reg_sz[REG_D] = p.reg_sz;
    idx = (OP(30,31) << 1) | (OP_B(23));
    switch (ext_type) {
    case 2:  dis_reg_sz[REG_M] = WREG_SZ; ext_str = "uxtw"; break;
    case 3:  dis_reg_sz[REG_M] = XREG_SZ; ext_str = "lsl"; break;
    case 6:  dis_reg_sz[REG_M] = WREG_SZ; ext_str = "sxtw"; break;
    default: INV_INSTR(); return;
    }

    if ((ext_type == 3) && shift == 0) {
        if (p.ldst) dis_print(iaddr, instruction, "ldr%s %Rd,[%rn|sp,%rm]", ldst_sz_str[idx]);
        else        dis_print(iaddr, instruction, "str%s %Rd,[%rn|sp,%rm]", ldst_sz_str[idx]);
    } else {
        if (p.ldst) dis_print(iaddr, instruction, "ldr%s %Rd,[%rn|sp,%rm,%s#%d]", ldst_sz_str[idx], ext_str, shift);
        else        dis_print(iaddr, instruction, "str%s %Rd,[%rn|sp,%rm,%s#%d]", ldst_sz_str[idx], ext_str, shift);
    }
}

void dis_ldr_imm(u64 iaddr, u32 instruction)
{
    ldr_attr_t p;
    int idx;
    int imm12 = OP(10,21) << OP(30,31);

    UNIMPIF(OP_B(26), "Vector instructions are not supported");

    sim_ldr_attr(instruction, &p);
    dis_reg_sz[REG_D] = p.reg_sz;
    idx = (OP(30,31) << 1) | (OP_B(23));
    if (p.ldst) dis_print(iaddr, instruction, "ldr%s %Rd,[%rn|sp{,#%d}]", ldst_sz_str[idx], imm12);
    else        dis_print(iaddr, instruction, "str%s %rd,[%rn|sp{,#%d}]", ldst_sz_str[idx], imm12);
}

void dis_ldr_exc(u64 iaddr, u32 instruction)
{

}

void dis_logical_reg(u64 iaddr, u32 instruction)
{
    /* Logical (shifted register) */
    int sf = OP_B(31);
    int opc = (OP_PAIR(29) << 1) | OP_B(21);
    int shift = OP_PAIR(22);
    int imm6 = OP(10, 15);
    const char *logical_op_str[] = {
        "and", "bic", "orr", "orn", "eor", "eon", "ands", "bics"
    };

    UNIMPIF((!sf && imm6 >= 32), "<logical-op> Wn, shift count > 32");

    dis_reg_sz[REG_D] = dis_reg_sz[REG_N] = dis_reg_sz[REG_M] = sf ? XREG_SZ : WREG_SZ;

    if ((shift == 0) && (imm6 > 0)) {
        dis_print(iaddr, instruction, "%s %Rd,%rn,%rm,%s#%d",
                  logical_op_str[opc],
                  ShiftStr(shift), imm6);
    } else {
        if ((opc == 2) && (RN == RM)) {
            dis_print(iaddr, instruction, "mov %Rd,%rn");
        } else {
            dis_print(iaddr, instruction, "%s %Rd,%rn,%rm",
                      logical_op_str[opc]);
        }
    }
}

void dis_add_sub_reg(u64 iaddr, u32 instruction)
{
    int sf = OP_B(31);
    int sub = OP_B(30);
    int setflags = OP_B(29);
    int shift_type = OP(22,23);
    int imm6 = OP(10,15);

    char *op_str = OP_B(30) ? "sub" : "add";
    char *shift_str;

    switch (shift_type) {
    case 0: shift_str = "lsl"; break;
    case 1: shift_str = "lsr"; break;
    case 2: shift_str = "asr"; break;
    case 3: shift_str = "UNKNOWN"; break;
    }

    dis_reg_sz[REG_D] = dis_reg_sz[REG_N] = dis_reg_sz[REG_M] = sf ? XREG_SZ : WREG_SZ;

    if ((shift_type == 0) && (imm6 == 0)) {
        dis_print(iaddr, instruction, "%s%s %Rd,%rn,%rm", op_str, setflags ? "s" : "");
    } else {
        dis_print(iaddr, instruction, "%s%s %Rd,%rn,%rm,%s#%d", op_str, setflags ? "s" : "", shift_str, imm6);
    }
}

void dis_add_ext_reg(u64 iaddr, u32 instruction)
{
    char *dis_ext_str[] = { "UXTB", "UXTH", "UXTW", "UXTX",
			    "SXTB", "SXTH", "SXTW", "SXTX" };
    char *dis_cmd_str[] = { "add", "adds", "sub", "subs" };
    int sf = OP_B(31);
    int sub = OP_B(30);
    int setflags = OP_B(29);
    int option = OP(13,15);
    int shift = OP(10,12);
    char *ext_str = dis_ext_str[option];
    char *cmd_str = dis_cmd_str[(sub << 1) | setflags];

    if ((RD == 31) || (RN == 31)) {
	if (sf && (option == 3)) {
	    ext_str = "LSL";
	}
	if (!sf && (option == 2)) {
	    ext_str = "LSL";
	}
    }

    dis_reg_sz[REG_D] = dis_reg_sz[REG_N] = dis_reg_sz[REG_M] = sf ? XREG_SZ : WREG_SZ;
    if (sf) {
	if ((option & 3) != 3) {
	    dis_reg_sz[REG_M] = WREG_SZ;
	}
    }

    dis_print(iaddr, instruction, "%s %Rd|sp,%rn|sp,%rm,%s#%d", cmd_str, ext_str, shift);
}

void dis_adc_sbc(u64 iaddr, u32 instruction)
{
    DIS_UNIMPL();
}

void dis_cond_sel(u64 iaddr, u32 instruction)
{
    int sf = OP_B(31);
    int op = OP_B(30);
    int s = OP_B(29);
    int op2 = OP(10,11);
    int cond = OP(12, 15);
    int iop = (op << 1) | (op2 & 1);
    const char *dis_cond_sel_str[] = { "csel", "csinc", "csinv", "csneg" };
    if ((op2 > 1) || (s == 1)) {
        INV_INSTR();
        return;
    }

    dis_reg_sz[REG_D] = dis_reg_sz[REG_N] = dis_reg_sz[REG_M] = sf ? XREG_SZ : WREG_SZ;
    dis_print(iaddr, instruction, "%s %Rd,%rn,%rm,%s", dis_cond_sel_str[iop], dis_cond_str[cond]);
}

void dis_dp_3src(u64 iaddr, u32 instruction)
{
    int sf = OP_B(31);
    int op54 = OP_PAIR(29);
    int op31 = OP(21,23);
    int o0 = OP_B(15);
    int opc = (op31 << 1) | (o0);
    int type;
    char *op_str;

    if (op54) {
        INV_INSTR();
        return;
    }

    if (!sf && op31) {
        INV_INSTR();
        return;
    }

    dis_reg_sz[REG_D] =
        dis_reg_sz[REG_N] =
        dis_reg_sz[REG_M] =
        dis_reg_sz[REG_A] = sf ? XREG_SZ : WREG_SZ;

    switch (opc) {
    case 0: op_str = "madd"; type = 4; break;
    case 1: op_str = "msub"; type = 4; break;
    case 2: op_str = "smaddl"; type = -4; break;
    case 3: op_str = "smsubl"; type = -4; break;
    case 4: op_str = "smulh"; type = 3; break;
    case 10: op_str = "umaddl"; type = -4; break;
    case 11: op_str = "umsubl"; type = -4; break;
    case 12: op_str = "umulh"; type = 3; break;
    default: INV_INSTR(); return;
    }

    switch(type) {
    case 4:
        dis_print(iaddr, instruction, "%s %Rd,%ra,%rn,%rm", op_str);
        return;
    case -4:
        dis_reg_sz[REG_N] = dis_reg_sz[REG_M] = WREG_SZ;
        dis_print(iaddr, instruction, "%s %Rd,%ra,%rn,%rm", op_str);
        return;
    case 3:
        dis_print(iaddr, instruction, "%s %Rd,%rn,%rm", op_str);
        return;
    default:
        INV_INSTR();
        return;
    }
}

void dis_dp_2src(u64 iaddr, u32 instruction)
{
    int sf = OP_B(31);
    int s = OP_B(29);
    int opc = OP(10,15);
    char *op_str;

    if (s) {
        INV_INSTR();
        return;
    }

    switch (opc) {
    case 10: op_str = "asrv"; break;
    case 8:  op_str = "lslv"; break;
    case 9:  op_str = "lsrv"; break;
    case 11: op_str = "rorv"; break;
    case 3:  op_str = "sdiv"; break;
    case 2:  op_str = "udiv"; break;
    default: op_str = "dp2src"; break;
    }

    dis_reg_sz[REG_D] = dis_reg_sz[REG_N] = dis_reg_sz[REG_M] = sf ? XREG_SZ : WREG_SZ;

    dis_print(iaddr, instruction, "%s %Rd,%rn,%rm", op_str);
}

void dis_dp_1src(u64 iaddr, u32 instruction)
{
    int opcode = OP(10, 15);
    int opcode2 = OP(16, 20);
    int sf = OP_B(31);
    int s = OP_B(29);
    char *op_str;

    if (opcode2 || s || (opcode >= 6) || ((opcode == 3) && !sf)) {
        INV_INSTR();
        return;
    }

    switch (opcode) {
    case 0: op_str = "rbit"; break;
    case 1: op_str = "rev16"; break;
    case 2: if (sf) op_str = "rev32"; else op_str = "rev"; break;
    case 3: op_str = "rev"; break;
    case 4: op_str = "clz"; break;
    case 5: op_str = "cls"; break;
    default: op_str = "dp2src"; break;
    }

    dis_reg_sz[REG_D] = dis_reg_sz[REG_N] = sf ? XREG_SZ : WREG_SZ;

    dis_print(iaddr, instruction, "%s %Rd,%rn", op_str);
}

// LICENSE_BEGIN
// Copyright (c) 2007 FirmWorks
// Copyright 2010 Apple, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// LICENSE_END
