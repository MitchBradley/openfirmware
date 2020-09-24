//
// MIPS Simulator
//
// Copyright (C) 2020 Lubomir Rintel
// See license at end of file
//
// Usage:
//
//   Load a MIPS Forth dictionary:
//   $ mipsfth kernel.dic
//
//   Enable syscall trace:
//   $ MIPSSIM_TRACE=1 mipsfth kernel.dic
//
//   Enable syscall + instruction trace:
//   $ MIPSSIM_TRACE=2 mipsfth kernel.dic
//
//   Enable syscall + instruction + register trace:
//   $ MIPSSIM_TRACE=3 mipsfth kernel.dic

#include <stdint.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <signal.h>

extern void restoremode();

uint32_t trace;
static uint32_t R[32];
static uint32_t oPC, PC, nPC;
static uint32_t Hi, Lo;
#define INSN (*(uint32_t *)oPC)

#define	rs		((0x03e00000 & INSN) >> 21)
#define	rt		((0x001f0000 & INSN) >> 16)
#define	rd		((0x0000f800 & INSN) >> 11)

#define	shamt		((0x000007c0 & INSN) >> 6)
#define	syscall_nr	((0x03ffffc0 & INSN) >> 6)
#define	address		((0x03ffffff & INSN) << 2)

#define	BranchAddr	(((0x0000ffff & INSN) << 2) | \
			 (0x00008000 & INSN ? 0xfffc0000 : 0))

#define	SignExtImm	((0x0000ffff & INSN) | \
			 (0x00008000 & INSN ? 0xffff0000 : 0))
#define	ZeroExtImm	 (0x0000ffff & INSN)

const char * const rn[] = {
	"zero", "at", "v0", "v1", "a0", "a1", "a2", "a3",
	"t0", "t1", "t2", "t3", "t4", "t5", "t6", "t7",
	"s0", "a1", "s2", "s3", "s4", "s5", "s6", "s7",
	"t8", "t9", "k0", "k1", "gp", "sp", "rp", "ra",
};

static void
dumpregs(void)
{
	int i;
	char str[18];

	for (i = 0; i < 32; i++) {
		snprintf(str, sizeof(str), "$%d(%s)=%08x", i, rn[i], R[i]);
		fprintf(stderr, "%18s", str);
		if (i % 4 == 3)
			fprintf(stderr, "\n");
	}
	fprintf(stderr, "       PC=%08x", oPC);
	fprintf(stderr, "  Hi=%08x", Hi);
	fprintf(stderr, "  Lo=%08x\n", Lo);
}

static void
trace_insn(const char *fmt, ...)
{
	va_list ap;

	if (trace < 2)
		return;

	va_start(ap, fmt);
	fprintf(stderr, "0x%08x:   (0x%08x)  ", oPC, INSN);
	vfprintf(stderr, fmt, ap);
	va_end(ap);
	fprintf(stderr, "\n");

	if (trace < 3)
		return;

	dumpregs();
	fprintf(stderr, "\n");
}

static void
quit_handler(int signum)
{
	trace = 3;
	trace_insn("(fatal signal received)\n");
	restoremode();
	exit(1);
}

void
simulate(uint8_t *mem,
         uint32_t start,
         uint32_t header,
         uint32_t syscall_vec,
         uint32_t memtop,
         uint32_t argc,
         uint32_t argv)
{
	trace = atoi(getenv("MIPSSIM_TRACE") ?: "");
	if (trace) {
		fprintf(stderr, "mem=0x%08x start=0x%08x header=0x%08x "
			"syscall_vec=0x%08x memtop=0x%08x "
			"argc=0x%08x argv=0x%08x\n",
			mem, start, header, syscall_vec, memtop, argc, argv);
	}

	signal(SIGQUIT, quit_handler);

	R[4] = header;
	R[5] = 0;
	R[6] = memtop;
	R[7] = argc;
	R[29] = (uint32_t)&header;

	PC = start;
	nPC = PC + 4;
next:
	oPC = PC;
	PC = nPC;
	nPC += 4;
	R[0] = 0;

	switch (INSN) {
	case 0x00000000:
		/* Just a sll zero, zero, 0,
		 * but this way we get nicer traces */
		trace_insn("nop");
		goto next;
	}

	switch (INSN & 0xffff07ff) {
	case 0x00000010:
		trace_insn("mfhi %s", rn[rd]);
		R[rd] = Hi;
		goto next;

	case 0x00000012:
		trace_insn("mflo %s", rn[rd]);
		R[rd] = Lo;
		goto next;
	}

	switch (INSN & 0xfc00003f) {
	case 0x0000000c:
		trace_insn("syscall %d", syscall_nr);

		if (syscall_nr == 0) {
			R[2] = (*(long (*) ())(*(long *)(syscall_vec + R[20]))) (R[4], R[5], R[6], R[7]);
			if (trace) {
				fprintf (stderr, "syscall=%d (a0=%d, a1=%d, a2=%d, a3=%d) = 0x%08x\n",
					 R[20], R[4], R[5], R[6], R[7], R[2]);
			}
			goto next;
		}

		trace = 2;
		trace_insn("Unhandled syscall: %d\n", syscall_nr);
		return;

	case 0x00000004:
		trace_insn("sllv %s, %s, %s", rn[rd], rn[rt], rn[rs]);
		R[rd] = R[rt] << R[rs];
		goto next;

	case 0x00000026:
		trace_insn("xor %s, %s, %s", rn[rd], rn[rs], rn[rt]);
		R[rd] = R[rs] ^ R[rt];
		goto next;

	case 0x00000000:
		trace_insn("sll %s, %s, %d", rn[rd], rn[rt], shamt);
		R[rd] = R[rt] << shamt;
		goto next;

	case 0x00000002:
		trace_insn("srl %s, %s, %d", rn[rd], rn[rt], shamt);
		R[rd] = R[rt] >> shamt;
		goto next;

	case 0x00000003:
		trace_insn("sra %s, %s, %d", rn[rd], rn[rt], shamt);
		R[rd] = (int32_t)R[rt] >> shamt;
		goto next;

	case 0x00000007:
		trace_insn("srav %s, %s, %s", rn[rd], rn[rt], rn[rs]);
		R[rd] = (int32_t)R[rt] >> R[rs];
		goto next;
	}

	switch (INSN & 0xfc1fffff) {
	case 0x00000008:
		trace_insn("jr %s", rn[rs]);
		nPC = R[rs];
		goto next;
	}

	switch (INSN & 0xfc00ffff) {
	case 0x00000018:
		trace_insn("mult %s, %s", rn[rs], rn[rt]);
		{
			uint64_t prod = R[rs] * R[rt];
			Lo = prod & 0xffffffff;
			Hi = prod >> 32;
		}
		goto next;

	case 0x00000019:
		trace_insn("multu %s, %s", rn[rs], rn[rt]);
		{
			uint64_t prod = R[rs] * R[rt];
			Lo = prod & 0xffffffff;
			Hi = prod >> 32;
		}
		goto next;

	case 0x0000001a:
		trace_insn("div %s, %s", rn[rs], rn[rt]);
		Lo = (int32_t)R[rs] / (int32_t)R[rt];
		Hi = (int32_t)R[rs] % (int32_t)R[rt];
		goto next;

	case 0x0000001b:
		trace_insn("divu %s, %s", rn[rs], rn[rt]);
		Lo = R[rs] / R[rt];
		Hi = R[rs] % R[rt];
		goto next;
	}

	switch (INSN & 0xfc0007ff) {
	case 0x00000006:
		trace_insn("srlv %s, %s, %s", rn[rd], rn[rt], rn[rs]);
		R[rd] = R[rt] >> R[rs];
		goto next;

	case 0x00000020:
		trace_insn("add %s, %s, %s", rn[rd], rn[rs], rn[rt]);
		R[rd] = (int32_t)R[rs] + (int32_t)R[rt];
		goto next;

	case 0x00000021:
		trace_insn("addu %s, %s, %s", rn[rd], rn[rs], rn[rt]);
		R[rd] = R[rs] + R[rt];
		goto next;

	case 0x00000022:
		trace_insn("sub %s, %s, %s", rn[rd], rn[rs], rn[rt]);
		R[rd] = (int32_t)R[rs] - (int32_t)R[rt];
		goto next;

	case 0x00000023:
		trace_insn("subu %s, %s, %s", rn[rd], rn[rs], rn[rt]);
		R[rd] = R[rs] - R[rt];
		goto next;

	case 0x00000024:
		trace_insn("and %s, %s, %s", rn[rd], rn[rs], rn[rt]);
		R[rd] = R[rs] & R[rt];
		goto next;

	case 0x00000025:
		trace_insn("or %s, %s, %s", rn[rd], rn[rs], rn[rt]);
		R[rd] = R[rs] | R[rt];
		goto next;

	case 0x0000002a:
		trace_insn("slt %s, %s, %s", rn[rd], rn[rs], rn[rt]);
		if ((int32_t)R[rs] < (int32_t)R[rt])
			R[rd] = 1;
		else
			R[rd] = 0;
		goto next;

	case 0x0000002b:
		trace_insn("sltu %s, %s, %s", rn[rd], rn[rs], rn[rt]);
		if (R[rs] < R[rt])
			R[rd] = 1;
		else
			R[rd] = 0;
		goto next;
	}

	switch (INSN & 0xfc1f0000) {
	case 0x04000000:
		trace_insn("bltz %s, 0x%x", rn[rs], BranchAddr);
		if ((int32_t)R[rs] < 0)
			nPC = PC + BranchAddr;
		goto next;

	case 0x04010000:
		trace_insn("bgez %s, 0x%x", rn[rs], BranchAddr);
		if ((int32_t)R[rs] >= 0)
			nPC = PC + BranchAddr;
		goto next;

	case 0x04100000:
		trace_insn("bltzal %s, 0x%x", rn[rs], BranchAddr);
		if ((int32_t)R[rs] < 0) {
			R[31] = PC + 8;
			nPC = PC + BranchAddr;
		}
		goto next;

	case 0x04110000:
		trace_insn("bgezal %s, 0x%x", rn[rs], BranchAddr);
		if ((int32_t)R[rs] >= 0) {
			R[31] = PC + 8;
			nPC = PC + BranchAddr;
		}
		goto next;

	case 0x18000000:
		trace_insn("blez %s, 0x%x", rn[rs], BranchAddr);
		if ((int32_t)R[rs] <= 0)
			nPC = PC + BranchAddr;
		goto next;

	case 0x1c000000:
		trace_insn("bgtz %s, 0x%x", rn[rs], BranchAddr);
		if ((int32_t)R[rs] > 0)
			nPC = PC + BranchAddr;
		goto next;
	}

	switch (INSN & 0xfc000000) {
	case 0x08000000:
		trace_insn("j 0x%x", (PC & 0xf0000000) | address);
		nPC = (PC & 0xf0000000) | address;
		goto next;

	case 0x0c000000:
		trace_insn("jal 0x%x", (PC & 0xf0000000) | address);
		R[31] = PC + 8;
		nPC = (PC & 0xf0000000) | address;
		goto next;

	case 0x10000000:
		trace_insn("beq %s, %s, 0x%x", rn[rs], rn[rt], BranchAddr);
		if (R[rs] == R[rt])
			nPC = PC + BranchAddr;
		goto next;

	case 0x14000000:
		trace_insn("bne %s, %s, 0x%x", rn[rs], rn[rt], BranchAddr);
		if (R[rs] != R[rt])
			nPC = PC + BranchAddr;
		goto next;

	case 0x20000000:
		trace_insn("addi %s, %s, 0x%x", rn[rt], rn[rs], SignExtImm);
		R[rt] = R[rs] + SignExtImm;
		goto next;

	case 0x24000000:
		trace_insn("addiu %s, %s, 0x%x", rn[rt], rn[rs], SignExtImm);
		R[rt] = R[rs] + SignExtImm;
		goto next;

	case 0x28000000:
		trace_insn("slti %s, %s, 0x%x", rn[rt], rn[rs], SignExtImm);
		if ((int32_t)R[rs] < (int32_t)SignExtImm)
			R[rt] = 1;
		else
			R[rt] = 0;
		goto next;

	case 0x2c000000:
		trace_insn("sltiu %s, %s, 0x%x", rn[rt], rn[rs], SignExtImm);
		if (R[rs] < SignExtImm)
			R[rt] = 1;
		else
			R[rt] = 0;
		goto next;

	case 0x30000000:
		trace_insn("andi %s, %s, 0x%x", rn[rt], rn[rs], ZeroExtImm);
		R[rt] = R[rs] & ZeroExtImm;
		goto next;

	case 0x34000000:
		trace_insn("ori %s, %s, 0x%x", rn[rt], rn[rs], ZeroExtImm);
		R[rt] = R[rs] | ZeroExtImm;
		goto next;

	case 0x38000000:
		trace_insn("xori %s, %s, 0x%x", rn[rt], rn[rs], ZeroExtImm);
		R[rt] = R[rs] ^ ZeroExtImm;
		goto next;

	case 0x3c000000:
		trace_insn("lui %s, 0x%x", rn[rt], ZeroExtImm << 16);
		R[rt] = (ZeroExtImm << 16);
		goto next;

	case 0x80000000:
		trace_insn("lb %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		R[rt] = *(int8_t *)(R[rs] + SignExtImm);
		goto next;

	case 0x8c000000:
		trace_insn("lw %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		R[rt] = *(int32_t *)(R[rs] + SignExtImm);
		goto next;

	case 0xa0000000:
		trace_insn("sb %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		{
			uint32_t addr = (R[rs] + SignExtImm) & 0xfffffffc;
			int off = 8 * ((R[rs] + SignExtImm) % 4);

			*(uint32_t *)addr &= ~(0xff << off);
			*(uint32_t *)addr |= ((0xff & R[rt]) << off);
		}
		goto next;

	case 0xa4000000:
		trace_insn("sh %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		{
			uint32_t addr = (R[rs] + SignExtImm) & 0xfffffffc;
			int off = 8 * ((R[rs] + SignExtImm) % 4);

			*(uint32_t *)addr &= ~(0xffff << off);
			*(uint32_t *)addr |= ((0xffff & R[rt]) << off);
		}
		goto next;

	case 0xac000000:
		trace_insn("sw %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		*(int32_t *)(R[rs] + SignExtImm) = R[rt];
		goto next;

	case 0x90000000:
		trace_insn("lbu %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		R[rt] = *(uint8_t *)(R[rs] + SignExtImm);
		goto next;

	case 0xa8000000:
		trace_insn("swl %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		{
			uint32_t addr = (R[rs] + SignExtImm) & 0xfffffffc;
			int off = 8 * (3 - (R[rs] + SignExtImm) % 4);

			*(uint32_t *)addr &= ~(0xffffffff >> off);
			*(uint32_t *)addr |= (R[rt] >> off);
		}
		goto next;

	case 0xb8000000:
		trace_insn("swr %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		{
			uint32_t addr = (R[rs] + SignExtImm) & 0xfffffffc;
			int off = 8 * ((R[rs] + SignExtImm) % 4);

			*(uint32_t *)addr &= ~(0xffffffff << off);
			*(uint32_t *)addr |= (R[rt] << off);
		}
		goto next;

	case 0x88000000:
		trace_insn("lwl %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		{
			uint32_t addr = (R[rs] + SignExtImm) & 0xfffffffc;
			int off = 8 * (3 - (R[rs] + SignExtImm) % 4);

			R[rt] &= ~(0xffffffff << off);
			R[rt] |= (*(uint32_t *)addr << off);
		}
		goto next;

	case 0x98000000:
		trace_insn("lwr %s, %d(%s)", rn[rt], SignExtImm, rn[rs]);
		{
			uint32_t addr = (R[rs] + SignExtImm) & 0xfffffffc;
			int off = 8 * ((R[rs] + SignExtImm) % 4);

			R[rt] &= ~(0xffffffff >> off);
			R[rt] |= (*(uint32_t *)addr >> off);
		}
		goto next;
	}

	trace = 3;
	trace_insn("(invalid instruction)\n");
	restoremode();
	exit(1);
}

// LICENSE_BEGIN
// Copyright (C) 2020 Lubomir Rintel
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
