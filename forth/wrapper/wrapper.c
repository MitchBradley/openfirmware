// See license at end of file

#ifdef PORTING_COMMENT
This is the C wrapper program for Forthmacs.  There are 3 problems to
solve in porting Forthmacs to a different machine.

1) What is the format of a binary file
2) How are I/O system calls invoked
3) At which address will the binary run (relocation)

This C program finesses problems 1 and 2 by assuming that the C
compiler/linker knows how to do those things.  The Forth 
interpreter itself is stored in a file whose format is system-independent.
The C program mallocs an array, reads the Forth image into that array,
and calls the array as a subroutine, passing it the address of another
array containing entry points for I/O subroutines.

The Forth interpreter relocates itself from a relocation bitmap
which is part of the Forth image file.
#endif

/*
 * Dynamic loader for Forth.  This program reads in a binary image of
 * a Forth system and executes it.  It connects standard input to the
 * Forth input stream (key and expect) and puts the Forth output stream
 * (emit and type) on standard output.
 *
 * An array of entry points for system calls is provided to the Forth
 * system, so that Forth doesn't have to know the details of how to
 * invoke system calls.
 *
 * Synopsis:
 *
 * forth [ dict-size ] [ <forth-binary>.exe ]
 *
 * dict-size is an optional decimal number specifying the number of
 * kilobytes of dictionary extension space to allocate.  The dictionary
 * extension space is the amount that the dictionary may grow as a result
 * of additional compilation, ALLOTing, etc.  If the dict-size argument
 * is omitted, a default value DEF_DICT is used.
 *
 * <forth-binary> is the name of the ".exe" file containing the forth binary
 * image.  The binary image is in a system-independent format, which contains
 * a header, the relocatable program image, and a relocation bitmap.
 *
 * If there is no such argument, the default binary file DEF_DIC is used.
 *
 * The Forth system may determine whether the input stream is coming from
 * a file or from standard input by calling the function "fileques()".
 * This is useful for deciding whether or not to prompt if it is possible
 * to redirect the input stream to a file.
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#ifndef WIN32
#include <sys/mman.h>
#endif

/* 
 * The following #includes and externs fix GCC warnings when compiled with
 * -Wimplicit-function-declarations, which I'm doing while trying to get
 * this working on Darwin hosts.
 */
#include <ctype.h>
/* zlib externs */
extern int inflate();
extern int compress();
extern long crc32();

#ifdef __linux__
char *host_os = "Linux";
#define SYS5 1
#endif

#ifdef __MACH__
#define __unix__ 1
#endif

#ifdef WIN32
#define ENV_DELIM  ';'
#define HOST_LITTLE_ENDIAN
char *host_os = "Win32";
#define PAGESIZE 4096
#endif

#ifndef ENV_DELIM
#define ENV_DELIM  ':'
#endif

#define DEF_FPATH ".:/usr/lib:/usr/local/lib/forth"
#define DEF_PATH  ".:/usr/bin:/usr/local/bin"
#define DEF_DIC   "builder.dic"		/* Default Forth image file */
#define DEF_DICT  (512*1024L)		/* Default dictionary growth space */

#ifdef M68K
char *host_cpu = "m68k";
#define CPU_MAGIC 0x601e0000
#define START_OFFSET 0x10
#endif

#if defined(__APPLE__)
char *host_os = "Darwin";
#define BSD 1
#include <libkern/OSCacheControl.h>
#endif

#ifdef MIPS
#define START_OFFSET 8
#define CPU_MAGIC 0x10000007
#ifdef MIPSSIM
char *target_cpu = "mips";
#else
char *host_cpu = "mips";
#include <asm/cachectl.h>
#ifdef __MIPSEL__
#define HOST_LITTLE_ENDIAN
#endif
#endif
#endif

#ifdef CKERNEL
char *target_cpu = "c";
char *host_cpu = "c";
#define CPU_MAGIC 0x464f4657
#define START_OFFSET 8
#endif

#ifdef sun
char *host_os = "solaris";
#ifndef CKERNEL
char *host_cpu = "sparc";
#endif
#endif

#ifdef DEMON
char *host_os = "demon";
char *host_cpu = "arm";
#endif

#ifdef AIX
char *host_os = "aix";
char *host_cpu = "powerpc";
#endif

#ifdef NetBSD
char *host_os = "netbsd";
#endif

#ifdef FreeBSD
char *host_os = "freebsd";
#endif

#ifdef __arm__
char *host_cpu = "arm";
#define HOST_LITTLE_ENDIAN
#endif

#ifdef __arm64__
char *host_cpu = "arm64";
#define HOST_LITTLE_ENDIAN
#endif

#ifdef HOSTPOWERPC
char *host_cpu = "powerpc";
# ifdef __linux__
#  define LinuxPOWERPC
# endif
#endif

#ifdef NT
char *host_os = "nt";
char *host_cpu = "x86";
#endif

#ifdef TARGET_POWERPC
char *target_cpu = "powerpc";
#define CPU_MAGIC 0x48000020
#define START_OFFSET 8
# ifdef LinuxPOWERPC
#  define NOGLUE
# else
   extern   void	glue();
# endif
#endif

#ifdef ARM
char *target_cpu = "arm";
#define CPU_MAGIC 0xe1a00000
#define START_OFFSET 8
#endif

#ifdef ARM64
char *target_cpu = "arm64";
#define CPU_MAGIC 0xd503201f
#define START_OFFSET 0
#define HOST_LITTLE_ENDIAN
#endif

#ifdef SPARC
char *target_cpu = "sparc";
#define CPU_MAGIC 0x30800008
#define START_OFFSET 0
#endif

#ifdef ALPHA
char *target_cpu = "alpha";
#define CPU_MAGIC 0xc3e00007
#define START_OFFSET 4
#endif

#ifdef __i386__
char *host_cpu = "x86";
# ifndef CKERNEL
#  define HOST_LITTLE_ENDIAN
# endif
#endif

#ifdef __x86_64__
char *host_cpu = "x86";
# ifndef CKERNEL
#  define HOST_LITTLE_ENDIAN
# endif
#endif

#ifdef TARGET_X86
char *target_cpu = "x86";
#define CPU_MAGIC 0x4d503400
#define START_OFFSET 0
#endif

#ifdef DOS
typedef long off_t;
char *host_os = "dos";
char *host_cpu = "x86";
#define HOST_LITTLE_ENDIAN
#endif

#define INTERNAL static

#include <errno.h>

#ifdef __unix__
# include <sys/mman.h>
# include <limits.h>	/* for PAGESIZE */
# ifndef PAGESIZE
#  define PAGESIZE 4096
# endif
# ifdef MAJC
#  include <sys/unistd.h>
# else
#  define HAVE_PSIGNAL
#  include <unistd.h>
# endif
# include <sys/param.h>
#endif


#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#ifdef ARM64
typedef int quadlet;
#else
typedef long quadlet;
#endif

#ifdef WIN32
# include <windows.h>
#endif

#ifdef BSD
# include <sys/time.h>
# include <sys/ioctl.h>	/* For FIONREAD */
#endif
#ifdef __linux__
# include <time.h>
# include <sys/ioctl.h>
#endif

#ifdef SYS5
# define USE_TERMIOS
#endif

#ifdef BSD
# define USE_TERMIOS
#endif

#ifdef DEMON
# define USE_STDIO
#endif

#ifdef USE_STDIO
# include <stdio.h>
#endif

/* fcntl.h will define this if the system needs it; otherwise we use 0 */
#ifndef _O_BINARY
# ifdef O_BINARY
#  define _O_BINARY O_BINARY
# else
#  define _O_BINARY 0
# endif
#endif

#ifndef MAXPATHLEN
# define MAXPATHLEN 256
#endif

#include <signal.h>

#ifdef AIX
  extern   void	_sync_cache_range(char *, long);
#endif

#ifdef __unix__
  void	exit_handler();
# ifdef BSD
  INTERNAL void	cont_handler();
  INTERNAL void	stop_handler();
# endif
#endif

#ifdef WIN32
# define isatty _isatty
# define kbhit  _kbhit
# define getch  _getch
# define open   _open
# define close  _close
# define read   _read
# define write  _write
# define lseek  _lseek
# define unlink _unlink
# define access _access
# define stat   _stat
# define getcwd _getcwd
# define chdir  _chdir

  INTERNAL int	getnum(char *);
  INTERNAL void	error(char *, char*);

#else
  INTERNAL int  getnum(char *);
  INTERNAL void	error();
#endif

/* externs from logger.c */
extern char *rootname(char *);
extern char *basename(char *);
extern void log_output(char *, long);
extern void log_input(char *, int);
extern void log_command_line(int, char **);
extern void log_env(char *, char *);

INTERNAL char *	substr();
INTERNAL long	path_open();
INTERNAL void	keymode();
#ifdef SYS5
INTERNAL void	keyqmode();
#endif

INTERNAL long 	f_open(), f_creat();
INTERNAL long	f_close(), f_read(), f_write();
INTERNAL long	f_ioctl();
INTERNAL long	f_lseek();
INTERNAL long	f_crstr();

#if defined(PPCSIM) || defined(ARMSIM) || defined(ARM64SIM) || defined(MIPSSIM)
  /* These are not INTERNAL because the simulators use then */
  long c_key();
  long s_bye();
  void restoremode();
#ifdef PPCSIM
  void simulate(char *, char *, char *, long (**)(), char *, int, char **, int);
#else
  void simulate(char *, char *, char *, long (**)(), char *, int, char **);
#endif
  long find(long, int, long, char *);
#else
  INTERNAL long	c_key();
  INTERNAL long	s_bye();
  INTERNAL void	restoremode();
#endif
#if defined(ARM64SIM)
  void simulate_init(char *start, long imagesize, long memsize);
#endif

INTERNAL long	c_emit();
INTERNAL long	c_keyques();
INTERNAL long	c_cr();
INTERNAL long	fileques();
INTERNAL long	f_unlink();
INTERNAL long	c_expect();
INTERNAL long	c_type();
INTERNAL long	syserror();
INTERNAL long	emacs();
INTERNAL long	pr_error();
INTERNAL long	s_signal();
INTERNAL long	s_system();
INTERNAL long	s_chdir();
INTERNAL long	s_getwd();
INTERNAL long	s_getwd0();
INTERNAL void  *m_alloc_dictionary();
INTERNAL long	m_alloc();
INTERNAL long	m_realloc();
INTERNAL long	m_free();
INTERNAL long	c_getenv();
INTERNAL long	today();
INTERNAL long	timez();
INTERNAL long	timezstr();
INTERNAL long	s_flushcache();
#ifdef USE_TERMCAP
extern   long	t_init(), t_op(), t_move(), t_rows(), t_cols();
#endif
INTERNAL long	pathname();
INTERNAL long	m_sbrk();
INTERNAL long	f_modtime();
INTERNAL long   m_deflate();
INTERNAL long   m_inflate();
INTERNAL long   m_map();
INTERNAL long   m_unmap();
INTERNAL long   s_ioperm();
INTERNAL long   f_mkdir();
INTERNAL long   f_rmdir();
#ifdef DLOPEN
extern   long	dlopen(), dlsym(), dlerror(), dlclose();
#endif

#ifdef USE_XCB
extern   long   open_window(), close_window(), rgbcolor(), fill_rectangle();
#endif

#ifdef JTAG
#include "jtag.h"
#endif

#if defined (BSD) || defined (__linux__)
INTERNAL long s_timeofday();
#endif

#if defined(USE_TERMIOS)
INTERNAL long c_setraw(), c_setbaud(), c_setparity(), c_setattr();
INTERNAL long c_getattr(), c_drain();
#endif

/* Fend off unused argument warnings */
#define UNUSED_ARGUMENT(x) (void)x

long nop(void);
long
nop(void)
{
	return(0L);
}

long (*functions[])() = {
/*	0	4	*/
	c_key,	c_emit,

/*	8	12	16	20	24	28	32 */
	f_open,	f_creat,f_close,f_read,	f_write,f_ioctl,c_keyques,

/*	36	40	44		48		*/
	s_bye,	f_lseek,f_unlink,	fileques,

/*	52	56		60	*/
	c_type,	c_expect,	syserror,

/*	64	68	72	*/
	today,  timez,	timezstr,

/*	76	80	*/
/*	fork,	execve,	*/
	0L,	0L,

/*	84	*/
	c_getenv,

/*	88		92	*/
	s_system,	s_signal,

/*	96		100	*/
	s_chdir,	s_getwd,

/*	104		108		112	*/
	m_alloc,	c_cr,		f_crstr,

/*	116		120		124	*/
	s_flushcache,	pr_error,	emacs,

/*	128	*/
	m_free,

/*	132	136	140	144	148 */
#ifdef USE_TERMCAP
	t_init,	t_op,	t_move,	t_rows,	t_cols,
#else
	nop,	nop,	nop,	nop,	nop,
#endif

/*	152 */
	pathname,

/*	156 */
#ifdef __unix__
	m_sbrk,
#else
	nop,
#endif

#ifdef DLOPEN
/*	160	164	168	172	*/
	dlopen,	dlsym,	dlerror,dlclose
#else
	nop,	nop,	nop,	nop,
#endif

/*	176	*/
	f_modtime,

/*	180  */
#ifdef ARM64SIM
        find,
#else
	0,	/* find_next on SPARC systems */
#endif

/*	184  */
	m_realloc,

/*	188  */
	m_deflate,
/*	192  		196 */
	f_mkdir,	f_rmdir,
/*	200  */
	s_getwd0,

        //#ifdef WIN32
        //#include "win32fun.c"
        //#include "jtagfun.c"
        //#else
	/* Windows socket stuff 204 .. 264 */
	0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
        //#endif

#ifdef JTAG
#include "jtagfun.c"
#else
	/* 268 .. 344 */
	0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,
#endif

#if defined(BSD) || defined(__linux__)
	/* 348 */
	s_timeofday,
#else
	0,
#endif

#if defined(USE_TERMIOS)
	/* 352    356        360          364        368         372*/
	c_setraw, c_setbaud, c_setparity, c_getattr, c_setattr,  c_drain,
#else
	0,        0,         0,           0,         0,          0,
#endif

	/* 376       380      384	388 */
	m_inflate,   m_map,   m_unmap,	s_ioperm,

#ifdef USE_XCB
	/* 392       396           400       404 */
	open_window, close_window, rgbcolor, fill_rectangle,
#else
	0,           0,            0,        0,
#endif
};
/*
 * Function semantics:
 *
 * Functions which are the names of Unix system calls have the semantics
 * of those Unix system calls.
 *
 * char c_key();				Gets next input character
 *	no echo or editing, don't wait for a newline.
 * c_emit(char c);				Outputs the character.
 * long f_open(char *path, long mode);		Opens a file.
 *	Mode must agree with wrsys.fth
 * long f_creat(char *path, long mode); 	Creates a file.
 *	Mode must agree with wrsys.fth  
 * long f_read(long fd, char *buf, long cnt);	Reads from a file
 * long f_write(long fd, char *buf, long cnt);	Writes to a file
 * long f_ioctl(long fd, long code, char *buf);	Is not used right now.
 * long c_keyques();				True if a keystroke is pending.
 *	If you can't implement this, return false.
 * s_bye(long status);				Cleans up and exits.
 * long f_lseek(long fd, long offset, long whence);Changes file position.
 *	Whence:  0 - from start of file  1 - from current pos.  2 - from end
 * long f_unlink(char *path);			Deletes a file.
 * long fileques();				True if input stream has been
 *	redirected away from a keyboard.
 * long c_type(long len, char *addr);		Outputs len characters.
 * long c_expect(long max, char *buffer);	Reads an edited line of input.
 * long c_cr();					Advances to next line.
 * long f_crstr()				Returns file line terminator.
 * long syserror();				Error code from the last
 *	failed system call.
 */

#ifdef TARGET_X86
void
fsyscall(long callno, long *args)
{
	args[0] = functions[callno>>2](args[0], args[1], args[2],
		args[3], args[4], args[5], args[6], args[7]);
}
#endif

char *genvp;
char *progname;
char sccs_get_cmd[128]; /* sccs get command string */
int uflag = 0; /* controls auto execution of sccs get */
int vflag = 0; /* controls reporting of file names */

INTERNAL char *expand_name();

/*
 * Execute the MicroEmacs editor.
 */
extern char *emacs_main();
char *fake_argv[] = { "micro-emacs" , "dontexit" , 0 };
INTERNAL long
emacs(void)
{
#ifdef EMACS
	char *eret;
	eret = emacs_main(2, fake_argv, genvp);
	keymode();
	return((long)eret);
#else
	return(-1L);
#endif
}

#if defined(HOST_LITTLE_ENDIAN)
long lbflip(long n);
long
lbflip(long n)
{
	long o;
	o = (n>>24) &0xff;
	o |= ((n>>16) & 0xff) << 8;
	o |= ((n>>8) & 0xff) << 16;
	o |= (n & 0xff) << 24;
	return(o);
}
void lbflips(long *adr, int len);
void
lbflips(long *adr, int len)
{
	while ((len -= sizeof(long)) >= 0) {
		*adr = lbflip(*adr);
		adr++;
	}
}
void qlbflips(long *adr, char *bitmap, int len);
void
qlbflips(long *adr, char *bitmap, int len)
{
	int nbits = 0;
	unsigned char residbits = 0;

	while ((len -= sizeof(long)) >= 0) {
		if (nbits == 0) {
			nbits = 8;
			residbits = *bitmap++;
		}
		if ((residbits & 0x80) == 0)
			*adr = lbflip(*adr);
		residbits <<= 1;
		nbits -= 1;
		adr++;
	}
}
#endif

#ifdef TARGET_X86
int bittest(char *table, int index) 
{
	int quot, remain ;
	unsigned char pattern = 128 ;

	quot = index /8 ;
	remain = index %8 ;

	return( ( table[quot] & (pattern>>remain) ) !=0 ) ;
}

	/* Header for PharLap flat 32-bit executable file */
	struct exp_header {
			 char  signature[2];
		unsigned short size_fragment;
		unsigned short size_blocks;
		unsigned short nreloc;
		unsigned short header_paragraphs;
		unsigned short min_data_pages;
		unsigned short max_data_pages;
		unsigned short size_low, size_high;  /* Unaligned int */
		unsigned short checksum;
		unsigned int   init_eip;
		unsigned short first_reloc;
		unsigned short overlay;
		unsigned short must_be_1;
		unsigned char  padding[512-0x1e];
	} header;
#elif defined(ARM) || defined(ARM64)
	struct {
		quadlet h_magic;
		quadlet h_res0[5];
		quadlet h_tlen;   quadlet h_dlen;
		quadlet h_trlen;  quadlet h_drlen;
		quadlet h_entry;	/* load base - offset 0x28 */
		quadlet h_blen;	/* dictionary growth size - offset 0x2c */
		quadlet h_res1[20];
	} header;
#else
	struct {
		quadlet h_magic;  quadlet h_tlen;
		quadlet h_dlen;   quadlet h_blen;
		quadlet h_slen;   quadlet h_entry;
		quadlet h_trlen;  quadlet h_drlen;
	} header;
#endif

char bpval[MAXPATHLEN];
char hostdirval[MAXPATHLEN];

/*
 * Set psuedo-environment-variable values for
 *   ${BP}        - The top of the OFW build tree
 *   ${HOSTDIR}   - The directory containing the host wrapper program
 * Internal management of these values (see fetchenv()) eliminates the
 * need for an external shell script to set them, thus making the build
 * system more portable to platforms without Unix-style shells.
 */
void set_bp(void);
void
set_bp(void)
{
	char *pret;
	int ret;
	char here[MAXPATHLEN];
	pret = getcwd(here, MAXPATHLEN);
	pret = getcwd(bpval, MAXPATHLEN);
	while (1) {
                // If HOSTDIR is set in environment, prefer it.
                if ((pret = getenv("HOSTDIR")) != NULL) {
                  strcpy(hostdirval, pret);
                } else {
			pret = getcwd(hostdirval, MAXPATHLEN);
			strcat(hostdirval, "/");
			strcat(hostdirval, host_cpu);
			strcat(hostdirval, "/");
			strcat(hostdirval, host_os);
                }
		if (access("ofw", F_OK) == 0)
			break;
		ret = chdir("..");
		pret = getcwd(bpval, MAXPATHLEN);
		if (strcmp(bpval, "/") == 0) {
			bpval[0] = '\0';
			break;
		}
	}
	ret = chdir(here);
}

struct woptions {  char *dashopt; char *forthopt; } woptions[] =
{
	{ "-c",  "clean " },
	{ "-d",  "prolix " },
	{ "-q",  "quiet " },
	{ "-v",  "verbose " },
	{ "",    "" },
};

int modify_command_line(int argc, char *argv[], char *targv[]);
int
modify_command_line(int argc, char *argv[], char *targv[])
{
	int argn = 1;
	static char dictname[MAXPATHLEN];
	static char command[100];
	struct woptions *o;

	*command = '\0';

	for (o = woptions; *o->dashopt != '\0'; o++)
		if (argn < argc && strcmp(argv[argn], o->dashopt) == 0) {
			strcat(command, o->forthopt);
			++argn;
		}

	strcpy(dictname, "${HOSTDIR}/../build/builder.dic");

	if (argn < argc && strcmp(argv[argn], "-t") == 0) {
		++argn;
		strcat(command, "tag ");
	} else {
		strcat(command, "build ");
	}

	if (argn < argc) {
		strcat(command, argv[argn]);
	} else {
		printf("No target name specified; executing builder in interactive mode\n");
		strcpy(command, "interact");
	}

	targv[0] = argv[0];
	targv[1] = dictname;
	targv[2] = "-s";
	targv[3] = command;
	targv[4] = 0;
	return(4);
}

char *strlower(char *str);
char *
strlower(char *str)
{
	char c, *s;
	for (s = str; (c = *s) != '\0'; s++)
		if (isupper(c))
			*s = tolower(c);
	
	return(str);
}

int
main(int argc, char **argv
#ifdef EMACS
     , char **envp
#endif
	)
{
	char * loadaddr;
	long f;
	long dictsize, extrasize, imagesize, memsize, relsize;
	int extrak;
	char * dictfile;
	char *targv[10];
#ifdef TARGET_X86
	char *reloc_table ;
	int delta_org, old_org, code_size ;
	int code_wsize, i ;
#endif

	/*
	 * This is a special accomodation for running the wrapper under an emulator
	 * like QEMU.  You can make a shell script containing a line like:
	 *   qemu-arm wrapper_name -0 script_name ...
	 * The logger will then log the name of script instead of the actual wrapper.
	 * An alternate would be to use Linux's binfmt_misc facility to bind the
	 * emulator to the wrapper binary, but the problem with that is that it
	 * requires root to register the binding every time you start the computer.
	 */
	if (argc > 1 && (0 == strcmp(argv[1], "-0"))) {
		argv += 2;
		argc -= 2;
	}

	progname = argv[0];
	log_command_line(argc, argv);

	set_bp();
	if (strcmp(strlower(rootname(basename(progname))), "build") == 0) {
		argc = modify_command_line(argc, argv, targv);
		argv = &targv[0];
	}

	++argv;
	--argc;

#ifdef EMACS
	/*
	 * We only look at the last 5 characters of the name in case
	 * the path name was explicitly specified, e.g. /usr/bin/emacs
	 */
	if( strlen(progname) >= 5
	&&  strcmp(substr(progname,-5,5), "emacs") == 0 ) {
		emacs_main(argc, argv, envp);
		exit(0);
	}
#endif

	extrak = -1;
	if ( (argc >= 1) && ((extrak = getnum(*argv)) >= 0)) {
		++argv;
		--argc;
	}

	/* If there is no command line argument, use the default .exe file */
	if( argc >= 1  &&
	    (  (strcmp(substr(*argv,-4,4),".exe") == 0)
	       || (strcmp(substr(*argv,-4,4),".dic") == 0)
	       || (strcmp(substr(*argv,-4,4),".EXE") == 0)
	       || (strcmp(substr(*argv,-4,4),".DIC") == 0) ) ) {
		dictfile = *argv++;
		argc--;
	} else {
		dictfile = DEF_DIC;
	}

	argv--; argc++;

	/* Open file for reading */
	if( (f = path_open(expand_name(dictfile)) ) < 0L ) {
		error("forth: Can't open dictionary file ",dictfile);
		exit(1);
	}
	log_input(dictfile, f);

#ifdef SCCS
	strcpy(sccs_get_cmd,"sccs ");
	if ( getenv("SCCSFLAGS") != NULL )
		strcat(sccs_get_cmd,getenv("SCCSFLAGS"));
	strcat(sccs_get_cmd," get ");
	if (getenv("SCCSGETFLAGS") == NULL)
		strcat(sccs_get_cmd," -s");
	else
		strcat(sccs_get_cmd,getenv("SCCSGETFLAGS"));
	strcat(sccs_get_cmd," ");
#endif

	/*
	 * Read just the header into a separate buffer,
	 * use it to find the size of text+data+bss, allocate that
	 * much memory plus sizeof(header), copy header to the
	 * new place, then read the rest of the file.
	 */
	if( f_read(f, (char *)&header, (long)sizeof(header)) != (long)sizeof(header) ) {
		error("forth: Can't read dictionary file header","");
		exit(1);
	}

#ifdef TARGET_X86	
	/*
	 * XXX we should do an additional test to verify that it's
	 * really a Forthmacs dictionary file and not just some other
	 * random .EXP file.
	 */
	if (header.signature[0] != 'M' && header.signature[1] != 'P') {
		error("forth: Incorrect dictionary file header in ", dictfile);
		exit(1);
	}

	/* imagesize is the number of bytes to read from the file */
	imagesize = *(int *)&header.size_low;

	/*
	 * Determine the dictionary growth size.
	 * First priority:  command line specification
	 * Second priority: h_blen header field
	 * Default:	    DEF_DICT
	 */
	if (extrak == -1)
		extrasize = DEF_DICT;
	else
		extrasize = (long)extrak * 1024L;

	/* dictsize is the total amount of dictionary memory to allocate */

	dictsize = imagesize +  extrasize; 
	relsize  = (dictsize + 15) /16;    /* Space for relocation map */

	memsize = dictsize + relsize + PAGESIZE - 1;

	loadaddr = (char *)m_alloc(memsize);
	if ((loadaddr == (char *) -1) || (loadaddr == (char *) 0)) {
		error("forth: Can't get memory","");
		exit(1);
	}
	loadaddr = (char *)(((long)loadaddr + (PAGESIZE-1)) & ~(PAGESIZE-1));

#ifndef WIN32
	// Make the dictionary memory executable
	if (mprotect(loadaddr, dictsize + relsize, PROT_READ | PROT_WRITE | PROT_EXEC) != 0) {
		perror("forth: mprotect");
		exit(1);
	}
#endif

	if( f_read(f, loadaddr, dictsize) <= 0) {
		error("forth: Error reading dictionary file","");
		exit(1);
	}
	f_close(f);
	
	old_org = *(int*)(&loadaddr[0x1c]);
	if (old_org != -1) {
		/* Otherwise relocate lots of things via the bitmap */
		code_size = ( (int)header.size_blocks -2)*0x200
			+ (int)header.size_fragment ;
		code_wsize = (code_size+1) /2 ;
		delta_org = (int)loadaddr - old_org ;
		reloc_table = &loadaddr[code_size] ;
		for(i=0 ; i<code_wsize ; i++) {
			if(bittest(reloc_table, i)) {
				*(int*)(&loadaddr[2*i]) += delta_org ;
			}
		}
		memcpy(&loadaddr[dictsize], reloc_table, (code_size+15)/16);
	}

#else  // TARGET_X86	

# if defined(TARGET_POWERPC) && defined(HOST_LITTLE_ENDIAN)
	lbflips((long *)&header, sizeof(header));
# endif

	if ((unsigned int) header.h_magic != CPU_MAGIC) {
		error("forth: Incorrect dictionary file header in ", dictfile);
		exit(1);
	}

	/* imagesize is the number of bytes to read from the file */
	imagesize = header.h_tlen  + header.h_dlen
		+ header.h_trlen + header.h_drlen;

	/*
	 * Determine the dictionary growth size.
	 * First priority:  command line specification
	 * Second priority: h_blen header field
	 * Default:	    DEF_DICT
	 */
	if (extrak == -1)
		extrasize = header.h_blen ? header.h_blen : DEF_DICT;
	else
		extrasize = (long)extrak * 1024L;

	/* dictsize is the total amount of dictionary memory to allocate */

	dictsize = sizeof(header) + imagesize +  extrasize ; 
	dictsize += 16;		/* Allow for alignment */
#ifndef roundup
#define    roundup(x, y)   ((((x)+((y)-1))/(y))*(y))  /* to any y */
#endif
	memsize = roundup(dictsize, PAGESIZE);

# ifdef VERBOSE
#  ifdef PPCSIM
	printf("PowerPC Instruction Set Simulator\n");
	printf("Copyright 1994 FirmWorks   All rights reserved\n");
#  elif ARMSIM
	printf("ARM Instruction Set Simulator\n");
	printf("Copyright 1994 FirmWorks   All rights reserved\n");
	printf("Copyright 2010 Apple, Inc. All rights reserved\n");
#  elif ARM64SIM
	printf("ARM64 Instruction Set Simulator\n");
	printf("Copyright 1994 FirmWorks        All rights reserved\n");
	printf("Copyright 2010-2021 Apple, Inc. All rights reserved\n");
#  endif
# endif

#if defined(__linux__) && defined(ARM)
	/* This is a hack to make sure loadaddr is page-aligned for mprotect() in s_flushcache() */
	loadaddr = (char *)sbrk(memsize);
#elif defined(ARM64SIM)
	loadaddr = m_alloc_dictionary(memsize);
#else
	loadaddr = (char *)m_alloc(memsize);
#endif
	if ((loadaddr == (char *) -1) || (loadaddr == (char *) 0)) {
		error("forth: Can't get memory","");
		exit(1);
	}

	/* Align loadaddr to 16-byte boundary; some mallocs align less stringently */
	loadaddr = (char *)(((long)loadaddr + 15) & ~15);

	memsize -= 16;  // Leave room for initial stack pointer
	(void)memcpy(loadaddr, (char *)&header, sizeof(header));

#if !defined(ARMSIM) && !defined(ARM64SIM)
        if (mprotect(loadaddr, memsize, PROT_READ | PROT_WRITE | PROT_EXEC) != 0) {
                perror("forth: mprotect");
                exit(1);
        }
#endif

#if defined(ARM64SIM)
	// Don't preserve the header for ARM64SIM.
	char *adjusted_loadaddr = loadaddr;
#else
	// Leave the header intact and load the rest of the image above it.
	char *adjusted_loadaddr = loadaddr + sizeof(header);
#endif
	if( f_read(f, adjusted_loadaddr, imagesize) != imagesize ) {
		error("forth: The dictionary file is too short","");
		exit(1);
	}

	f_close(f);

# if defined(TARGET_POWERPC) && defined(HOST_LITTLE_ENDIAN)
	lbflips((long *)(loadaddr + sizeof(header) + header.h_tlen),
		header.h_dlen);
	qlbflips((long *)(loadaddr + sizeof(header)),
		 loadaddr + sizeof(header) + header.h_tlen + header.h_dlen,
		 header.h_tlen);
# endif
#endif  // TARGET_X86	

	keymode();

#ifdef __unix__
	signal(SIGHUP,exit_handler);
	signal(SIGINT,exit_handler);
	signal(SIGILL,exit_handler);
	signal(SIGIOT,exit_handler);
	signal(SIGTRAP,exit_handler);
	signal(SIGFPE,exit_handler);
	signal(SIGBUS,exit_handler);
	signal(SIGSEGV,exit_handler);
# ifndef __linux__
	signal(SIGEMT,exit_handler);
	signal(SIGSYS,exit_handler);
# endif
# ifdef BSD
	signal(SIGCONT,cont_handler);
	signal(SIGTSTP,stop_handler);
# endif
#endif

	/*
	 * Call the Forth interpreter as a subroutine.  If it returns,
	 * exit with its return value as the status code.
	 *
	 * Each of the blocks below selects one form of target execution,
	 * and each terminates the entire wrapper run upon completion.
	 * Hence there should be no "else" or "elif" clauses after
	 * this point.
	 */

#if defined(PPCSIM)
	simulate(0L, loadaddr+sizeof(header)+START_OFFSET,
		 loadaddr, functions, (char *)loadaddr + memsize,
		 argc, argv, 1 /* 0=POWER, 1=PowerPC */);
	s_bye(0L);
#endif

#if defined(ARM64SIM)
	simulate_init(loadaddr, imagesize, memsize);
#endif

#if defined(ARMSIM) || defined(ARM64SIM)
	simulate(0L, loadaddr, loadaddr, functions,
		 (char *)loadaddr + memsize, argc, argv);
	s_bye(0L);
#endif

#if defined(MIPSSIM)
	simulate(0L, loadaddr+sizeof(header)+START_OFFSET,
		 loadaddr, functions, (char *)loadaddr + memsize,
		 argc, argv);
	s_bye(0L);
#endif

	/*
	 * Not a simulator.
	 */
	s_flushcache(loadaddr, dictsize);  /* We're about to execute data! */

#ifdef TARGET_X86
	{
	int (*codep)();
	/* There is a pointer to the startup code at offset 0x18 */
	codep = (int (*)()) *(int *)(&loadaddr[0x18]);
	if (old_org == -1)
		codep = (int (*)())((int)codep + (int)loadaddr);
	*(void **)(loadaddr+0x6) = fsyscall;
	*(short *)(&loadaddr[0x0a]) = 0;
	*(long *)(&loadaddr[0x10]) = argc;
	*(char ***)(&loadaddr[0x14]) = (char **)((char *)&argv[0]); 
	/* Far call to Forth */
	(void)codep(0, &(loadaddr[dictsize]));
	codep = (int (*)())(loadaddr + *(int *)(&loadaddr[0x0]));
	s_bye(codep(0, 1, 2));
	}
#endif

#ifdef TARGET_POWERPC
#ifndef PPCSIM
# ifdef NOGLUE
	{ long toc_entry[2]; int c;
		toc_entry[1] = 0;
		toc_entry[0] = ((long)loadaddr)+sizeof(header)+START_OFFSET;

		(*(void (*) ())toc_entry) (loadaddr, functions,
					   (long)loadaddr+memsize, argc, argv, 0, 0);
		s_bye(0L);
	}
# else
	glue(loadaddr, functions, (long)loadaddr+memsize, argc, argv,
		loadaddr+sizeof(header)+START_OFFSET);
	s_bye(0L);
# endif
#endif
#endif

#ifdef __APPLE_CC__
	{
	/*
	 * XCode specific behavior: if your function has a prototype, the compiler
	 * passes arguments in registers. Otherwise it pushes them on the stack.
	 */
	long (*func)(char *, long (*[])(), long, int, char **);
	func = (*(long (*) ())(loadaddr+sizeof(header)+START_OFFSET));
	printf("func %p (%p %p %lx %d %p)\n", func,
	       (char *)-1, functions, (long)loadaddr + memsize, argc, argv);
	fflush(stdout);
	s_bye(func((char *)-1, functions, (long)loadaddr + memsize, argc, argv));
	}
#endif

	s_bye((*(long (*) ())(loadaddr+sizeof(header)+START_OFFSET))
		(loadaddr, functions, ((long)loadaddr+dictsize - 16) & ~15,
		 argc, argv));

	restoremode();
	return 0;
}

/*
 * If the input string contains only decimal digits, returns the base 10
 * number represented by that digit string.  Otherwise returns -1.
 */
int
getnum(char *s)
{
	register int digit, n;

	for (n = 0; *s; s++) {
		digit = *s - '0';
		if (digit < 0  ||  digit > 9)
			return(-1);
		n = n * 10  +  digit;
	}
	return (n);
}

#ifdef BSD
INTERNAL void
stop_handler(void)
{
	restoremode();
	kill(0,SIGSTOP);
}
INTERNAL void
cont_handler(void)
{
	keymode();
}
#endif

#ifdef AIX
void
exit_handler(int sig, int code, struct sigcontext *SCP)
{
	struct mstsave *state = &SCP->sc_jmpbuf.jmp_context;
	int i, j;

	psignal(sig, "forth");

	if (sig == SIGINT) {
		s_bye(0L);
	} else if (sig == SIGILL) {
		/*
		 * Dump state for debugging
		 */
		printf("iar %08x instruction %08x\n", state->iar,
		       *((int *)state->iar));
		printf("msr %08x\t", state->msr);
		printf("cr  %08x\t", state->cr);
		printf("lr  %08x\t", state->lr);
		printf("ctr %08x\n", state->ctr);
		for (i = 0; i < NGPRS; ++i) {
			printf("r%02d %08x\t", i, state->gpr[i]);
			if ((i + 1) % 4 == 0)
				putchar('\n');
		}
	}
	restoremode();
	kill(0,SIGQUIT);
}
#else
void exit_handler(int sig);
void
exit_handler(int sig)
{
#ifdef HAVE_PSIGNAL
	psignal(sig, "forth");
#else
	printf("forth received signal number %d\n", sig);
#endif

	if (sig == SIGINT) {
		s_bye(0L);
	} else {
		restoremode();
#ifdef __unix__
		kill(0,SIGQUIT);
#endif
	}
}
#endif

#ifdef __linux__
static void			/* set file associated with fd to */
waitchar (int fd)		/* "wait for character" */
{
  int flags;

  flags = fcntl (fd, F_GETFL, 0);
  fcntl (fd, F_SETFL, flags & ~O_NONBLOCK);
}

static void			/* set file associated with fd to */
no_waitchar (int fd)		/* "don't wait for character" */
{
  int flags;

  flags = fcntl (fd, F_GETFL, 0);
  fcntl (fd, F_SETFL, flags | O_NONBLOCK);
}
#endif

#if defined(__linux__) && defined(__i386__)
#include <sys/io.h>
#endif
INTERNAL long
s_ioperm(unsigned long  from,  unsigned long num, unsigned long on)
{
#if defined(__linux__) && defined(__i386__)
  return (long)ioperm(from, num, (int)on);
#else
  UNUSED_ARGUMENT(from);
  UNUSED_ARGUMENT(num);
  UNUSED_ARGUMENT(on);

  return -1L;
#endif
}

/*
 * Returns true if a key has been typed on the keyboard since the last
 * call to c_key().
 */
INTERNAL long
c_keyques(void)
{
#if defined(__unix__) && defined(SYS5) && (defined(__linux__) || !defined(IRIS))
	unsigned char c[1];		/* place to read the character */
#endif /* c is used in a couple of configurations */
	int nchars = 0;

	fflush(stdout);
# ifdef __unix__
#  ifdef SYS5
#   ifdef __linux__
	no_waitchar (0);
	nchars = read(0, &c[0], 1) > 0;
	waitchar (0);
	if (nchars)  ungetc(c[0], stdin);
#   else
#    ifndef IRIS
	if ( (nchars = stdin->_cnt) == 0 ) {
		keyqmode();
		nchars = read(0, &c, 1) > 0;
		if (nchars)
			ungetc(c[0], stdin);
	}
#    endif
#   endif
#  else
#   ifdef BSD
	if ( (nchars = stdin->_r) == 0 )
		ioctl(0, FIONREAD, &nchars);
#   endif
#  endif
# else  // Windows?
	nchars = (long) (kbhit() ? 1 : 0);
# endif
	return ((long)nchars);
}

/*
 * Get the next character from the input stream.
 */
/*
 * There is a minor problem under Regulus relating to interrupted system
 * calls.  If the user types the INTERRUPT character (e.g. DEL) while
 * Forth is waiting for input, the read system call will be interrupted.
 * Forth will field the signal thus generated, save the state, and return
 * to the Forth interpreter.  If the user then tries to restart from the
 * saved state, the restarted system call will return 0, which is the same
 * code that is returned for end-of-file.  This is especially nasty when
 * using the Regulus standard-I/O package, because when it see the 0-length
 * read, it set a flag in the stdio file descriptor and returns EOF
 * forevermore.  What we really want to happen is for the read system call
 * to restart cleanly and continue waiting for input, rather than returning
 * 0.
 */

#if defined(WIN32) || defined(DOS)
struct keymap { char scancode; char esc_char; } keymap[] = {
	{ 'H', 'A'},  /* Up */
	{ 'P', 'B'},  /* Down */
	{ 'G', 'H'},  /* Home */
	{ 'O', 'K'},  /* End */
	{ 'K', 'D'},  /* Left */
	{ 'M', 'C'},  /* Right */
	{ 'S', 'P'},  /* Delete */
	{ 0, 0},
};

INTERNAL unsigned char
mapkeys(int c)
{
	register struct keymap *p;

	for (p = keymap; p->scancode != 0; p++) {
		if (p->scancode == c)
			return (p->esc_char);
	}
	return (0);
}
#endif

/* Not INTERNAL because the PowerPC simulator uses it */
long c_key(void);
long
c_key(void)
{
	register int c;

#if defined(WIN32) || defined(DOS)
	static int escaping = 0;
	if (escaping) {
		c = escaping;
		escaping = 0;
		return((long)c);
	}
	if ((c = getch()) == 0 || c == 0xe0) {
		escaping = (int)mapkeys(getch());
		return(escaping ? 0x9bL : 0x07L);  /* Bell if unmappable */
	}
	return((long)c);
#else
	keymode();

	fflush(stdout);
	if ((c = getchar()) != EOF)
		return(c);
	
	s_bye(0L);
	return(0);  /* To avoid compiler warnings */
#endif
}

/*
 * Send the character c to the output stream.
 */
INTERNAL long
c_emit(long c)
{
	putchar((int)c);
	return (long) fflush(stdout);
}

/*
 * This routine is called by the Forth system to determine whether
 * its input stream is connected to a file or to a terminal.
 * It uses this information to decide whether or not to
 * prompt at the beginning of a line.  If you are running in an environment
 * where input cannot be redirected away from the terminal, just return 0L.
 */
INTERNAL long
fileques(void)
{
#ifdef USE_STDIO
# ifdef DEMON
	return(!fisatty(stdin));
# else
	return((long)0);
# endif
#endif
	return(!isatty(fileno(stdin)));
}

#ifdef USE_TERMIOS
#include <termios.h>
struct termios ostate;
struct termios lstate;
struct termios kstate;
struct termios kqstate;
#endif

#ifdef USE_STTY
#include <sgtty.h>
struct sgttyb ostate;
struct sgttyb lstate;
struct sgttyb kstate;
#define TCSETA TIOCSETN
#endif

#define M_ORIG 0
#define M_KEY  1
#define M_LINE 2
#define M_KEYQ 3
static int lmode = M_ORIG;

INTERNAL void
initline(void) {
	if (lmode != M_ORIG)
		return;
#ifdef USE_TERMIOS
	tcgetattr(0, &ostate);                  /* save old state        */

	tcgetattr(0, &lstate);                  /* base of line state    */
	lstate.c_iflag |= IXON|IXANY|IXOFF;     /* XON/XOFF              */
	lstate.c_iflag |= ICRNL;                /* CR/NL munging         */

# ifdef IUCLC
	lstate.c_iflag &= ~(IUCLC);             /* no case folding       */
# endif

# ifndef AIX
	lstate.c_oflag |=  OPOST|ONLCR;         /* Map NL to CR-LF       */
#  ifdef ILCUC
	lstate.c_oflag &= ~(OLCUC);             /* No case folding       */
#  endif
	lstate.c_oflag &= ~(OCRNL|ONLRET);      /* Don't swap cr and lf  */
# endif

	lstate.c_lflag |= ICANON|ECHO;          /* Line editing on       */
	lstate.c_cc[VMIN] = 1;			/* Don't hold up input   */
	lstate.c_cc[VTIME] = 0;                 /* No input delay        */

	tcgetattr(0, &kstate);	                /* base of key state     */
	kstate.c_iflag &= ~(IXON|IXANY|IXOFF);  /* no XON/XOFF           */

# ifdef IUCLC
	kstate.c_iflag &= ~(IUCLC);             /* no case folding       */
# endif

# ifndef AIX
	kstate.c_iflag &= ~(INLCR|ICRNL);       /* no CR/NL munging      */
	kstate.c_oflag |=  OPOST|ONLCR;         /* Map NL to CR-LF       */
#  ifdef OLCUC
	kstate.c_oflag &= ~(OLCUC);             /* No case folding       */
#  endif
	kstate.c_oflag &= ~(OCRNL|ONLRET);      /* Don't swap cr and lf  */
# endif

	kstate.c_lflag &= ~(ICANON|ECHO);       /* No editing characters */
	kstate.c_cc[VMIN] = 1;			/* Don't hold up input   */
	kstate.c_cc[VTIME] = 0;                 /* No input delay        */

	kqstate = kstate;
	kqstate.c_cc[VMIN] = 0;			/* Poll for character	 */
#endif

#ifdef USE_STTY
	ioctl(0, TIOCGETP, &ostate);            /* save old state        */

	ioctl(0, TIOCGETP, &lstate);            /* base of line state    */
	lstate.sg_flags &= ~(CBREAK|RAW);       /* Line editing on       */
	lstate.sg_flags |= ECHO;		/* Echo                  */

	ioctl(0, TIOCGETP, &kstate);            /* base of key state     */
	kstate.sg_flags |= CBREAK;		/* Wake up on each char  */
	kstate.sg_flags &= ~ECHO;		/* Don't echo            */
#endif
}

INTERNAL void linemode(void)
{
	initline();
	if (lmode != M_LINE) {
#ifdef USE_STTY
		ioctl(0, TCSETA, &lstate);
#endif
#ifdef USE_TERMIOS
		tcsetattr(0, TCSANOW, &lstate);
#endif
		lmode = M_LINE;
	}
}

#ifdef SYS5
INTERNAL void
keyqmode(void)
{
	initline();
	if (lmode != M_KEYQ) {
		tcsetattr(0, TCSANOW, &kqstate);
		lmode = M_KEYQ;
	}
}
#endif

INTERNAL void
keymode(void)
{
	initline();
	if (lmode != M_KEY) {
#ifdef USE_STTY
		ioctl(0, TCSETA, &kstate);
#endif
#ifdef USE_TERMIOS
		tcsetattr(0, TCSANOW, &kstate);
#endif
		lmode = M_KEY;
	}
}

void restoremode(void);
void
restoremode(void)
{
	initline();
	if (lmode != M_ORIG) {
#ifdef USE_STTY
		ioctl(0, TCSETA, &ostate);
#endif
#ifdef USE_TERMIOS
#ifdef AIX
		/*
		 * AIX is soooooo special.
		 *
		 * If you interrupt "make" when it is in the midst of
		 * running Forth, the "make" process dies, reparenting
		 * the Forth process to be a child of the "init" process
		 * (PID 1).  Then the signal is sent to the Forth process,
		 * which tries to clean up after itself and restore the
		 * tty to its previous mode, but it can't do so, because
		 * the following tcsetattr() call just hangs and neither
		 * resets the tty mode nor returns.  The process sits around
		 * consuming system resources.
		 *
		 * The following "getppid()" test keeps the process from
		 * hanging, but it doesn't help the problem that the tty
		 * remains in the wrong mode.  ksh and bash users won't
		 * notice the tty problem, because those shells restore
		 * the tty mode to a reasonable state after running each
		 * command, but csh users will have to deal with the
		 * possibility of echoing being left turned off.  The
		 * getppid() test doesn't cause the tty problem - that
		 * problem happens with or without the test.
		 */

		if (getppid() == 1)
			return;
#endif
		tcsetattr(0, TCSANOW, &ostate);
#endif
		lmode = M_ORIG;
	}
}

#ifdef USE_TERMIOS
INTERNAL long
c_setraw(long fd) {
  struct termios sstate;
  tcgetattr((int)fd, &sstate);	        /* base of key state     */
  cfmakeraw(&sstate);
  sstate.c_cflag |= PARENB | PARODD;	/* Odd parity */
  sstate.c_cc[VMIN] = 0;		/* Poll for character	 */
  sstate.c_cc[VTIME] = 0;               /* No input delay        */

  return (long) tcsetattr((int)fd, TCSANOW, &sstate);
}

struct { int baud; int code; } baudcodes[] =
{ {      0,        B0}, {       50,       B50}, {       75,       B75},
  {    110,      B110}, {      134,      B134}, {      150,      B150},
  {    200,      B200}, {      300,      B300}, {      600,      B600},
  {   1200,     B1200}, {     1800,     B1800}, {     2400,     B2400},
  {   4800,     B4800}, {     9600,     B9600}, {    19200,    B19200},
  {  38400,    B38400}, {    57600,    B57600}, {   115200,   B115200},
#ifdef B230400
  { 230400,   B230400},

#ifdef B4000000
  { 460800,   B460800}, {   500000,   B500000},
  { 576000,   B576000}, {   921600,   B921600}, {  1000000,  B1000000},
  {1152000,  B1152000}, {  1500000,  B1500000}, {  2000000,  B2000000},
  {2500000,  B2500000}, {  3000000,  B3000000}, {  3500000,  B3500000},
  {4000000,  B4000000},
#endif
#endif
  {     -1,        -1}, 
};

INTERNAL long
c_setbaud(long fd, long baud)
{
	struct termios sstate;
	int i;
	int baudcode;

	baudcode = -1;
	for (i = 0; baudcodes[i].baud != -1; i++) {
		if (baudcodes[i].baud == baud) {
			baudcode = baudcodes[i].code;
			break;
		}
	}
	if (baudcode == -1)
		return -1L;

	tcgetattr((int)fd, &sstate);	        /* base of key state     */
	cfsetospeed(&sstate, baudcode);
	cfsetispeed(&sstate, baudcode);

	return (long)tcsetattr((int)fd, TCSADRAIN, &sstate);
}

INTERNAL long
c_setparity(long fd, long odd)
{
	struct termios sstate;

	tcgetattr((int)fd, &sstate);	        /* base of key state     */

	if (odd)
		sstate.c_cflag |= PARODD;
	else
		sstate.c_cflag &= ~PARODD;

	return (long)tcsetattr((int)fd, TCSADRAIN, &sstate);
}
INTERNAL long
c_getattr(long fd)
{
	static struct termios sstate;

	if (tcgetattr((int)fd, &sstate) < 0)
		return (-1L);

	return((long)&sstate);
}

INTERNAL long
c_setattr(long fd, long sstate)
{
	return (long)tcsetattr((int)fd, TCSADRAIN, (struct termios *)sstate);
}

INTERNAL long
c_drain(long fd)
{
	tcdrain((int)fd);
	return 0L;
}
#endif

/*
 * Get an edited line of input from the keyboard, placing it at buffer.
 * At most "max" characters will be placed in the buffer.
 * The line terminator character is not stored in the buffer.
 */
INTERNAL long
c_expect(long max, char *buffer)
{
	int c = 0, ret;
	register char *p = buffer;

	linemode();

	fflush(stdout);
	ret = read(0, &c, 1);
	while (max--  &&  c != '\n'  &&  c != EOF ) {
		*p++ = c;
		ret = read(0, &c, 1);
	}
	keymode();
	return ( (long)(p - buffer) );
}

/*
 * Send len characters from the buffer at addr to the output stream.
 */
INTERNAL long
c_type(long len, char *addr)
{
	while(len--)
		putchar(*addr++);
	return 0L;
}

/*
 * Sends an end-of-line sequence to the output stream.
 */
INTERNAL long
c_cr(void)
{
	return (long) putchar('\n');
}

/*
 * Returns the end-of-line sequence that is used within files as
 * a packed (leading count byte) string.
 */
INTERNAL long
f_crstr(void)
{
	return((long)"\1\n");
}

/* Not INTERNAL because the PowerPC simulator uses it */
long s_bye(long code);
long
s_bye(long code)
{
	restoremode();
	fflush(stdout);
	exit((int)code);
}

/*
 * Display the two strings, followed by an newline, on the error output
 * stream.
 */
void
error(char *str1, char *str2)
{
	int ret;
	ret = write(2,str1,strlen(str1));
	ret = write(2,str2,strlen(str2));
	ret = write(2,"\n",1);
}


/* Find the error code returned by the last failing system call. */
INTERNAL long
syserror(void)
{
#ifndef __unix__
	extern int errno;
#endif

	return((long)errno);
}

/* Display an error message */

INTERNAL long
pr_error(long errnum)
{
#ifndef __unix__
	extern int errno;
#endif
	
	errno = errnum;
	perror("");
	return 0L;
}

INTERNAL char *expand_name();

char output_filename[MAXPATHLEN];
#ifdef USE_STDIO
  #define NONE (FILE *)0
  FILE *output_fd = NONE;
#else
  #define NONE -1
  int output_fd = NONE;
#endif

#ifdef USE_STDIO
char *open_modes[] = {
#ifdef NO_BINARY_OPEN
    "r",  "a", "r+",  "",   "",   "",   "",   "",  "w+",  "w+",  "w+",   "",
#else
    "rb", "ab","r+b", "",   "",   "",   "",   "",  "w+b", "w+b", "w+b",  "",
#endif
};
#endif

INTERNAL long
f_open(char *name, long flag, long mode)
{
	char *expand_name();
	char *sccs_get();
	char *newname;
	int result;

	newname = expand_name(name);
#ifdef SCCS

	if (uflag)
		if( isobsolete(newname) == 1 )
			s_system(sccs_get(newname));
#endif
	if (vflag)
		printf("File: %s\n",name);

#ifdef USE_STDIO
	result = (int) fopen(newname, open_modes[flag]);
#else
	result = open(newname, _O_BINARY|(int)flag, (int)mode);
#endif
	if (((flag & 3) == O_RDONLY) && result != -1)
		log_input(name, result);
	return((long)result);
}

#ifdef BSD
#include <sys/file.h>
#endif
INTERNAL long
f_creat(char *name, long mode)
{
	int result;

#ifdef USE_STDIO
	result = (int) fopen(expand_name(name), open_modes[8]);
	if (result != -1) {
		strcpy(output_filename, name);
		output_fd = result;
	}
#else
#ifdef __unix__
	result = open(expand_name(name), O_RDWR|O_CREAT|O_TRUNC, (int)mode);
#else
	result = open(expand_name(name), _O_BINARY|O_RDWR|O_CREAT|O_TRUNC, (int)mode);
#endif
	if (result != -1) {
		strcpy(output_filename, name);
		output_fd = result;
	}
#endif
	return((long)result);
}

INTERNAL long
f_mkdir(char *name)
{
#ifdef DEMON
	return(-1);	/* XXX fixme */
#else
	return((long)mkdir(expand_name(name)
#if !(defined(WIN32) || defined(DOS))
		, (mode_t) 0777
#endif
		));
#endif
}

INTERNAL long
f_rmdir(char *name)
{
#ifdef DEMON
	return(-1);	/* XXX fixme */
#else
	return((long)rmdir(expand_name(name)));
#endif
}

INTERNAL long
f_read(long fd, char *buf, long cnt)
{
#ifdef USE_STDIO
	return((long)fread(buf, 1, cnt, (FILE *)fd));
#else
	return((long)read((int)fd, buf, cnt));
#endif
}

INTERNAL long
f_write(long fd, char *buf, long cnt)
{
#ifdef USE_STDIO
	return((long)fwrite(buf, 1, cnt, (FILE *)fd));
#else
	return((long)write((int)fd, buf, cnt));
#endif
}

INTERNAL long
f_close(long fd)
{
	long size;

#ifdef USE_STDIO
	if (fd == (long)output_fd) {
		size = fseek((FILE *)fd, 0, 2);
		log_output(output_filename, size);
		output_fd = NONE;
	}
	return((long)fclose((FILE *)fd));
#else
	if (fd == (long)output_fd) {
		size = lseek((int)fd, (off_t)0, SEEK_END);
		log_output(output_filename, size);
		output_fd = NONE;
	}
	return((long)close((int)fd));
#endif
}

INTERNAL long
f_unlink(char *name)
{
#ifdef DEMON
	return((long)remove(expand_name(name)));
#else
	return((long)unlink(expand_name(name)));
#endif
}

INTERNAL long
f_lseek(long fd, long offset, long flag)
{
#ifdef USE_STDIO
	return(fseek((FILE *)fd, offset, (int)flag));
#else
	return(lseek((int)fd, (off_t)offset, (int)flag));
#endif
}

INTERNAL long
f_ioctl(long fd, long code, char *buf)
{
#ifdef __unix__
	return((long)ioctl((int)fd, (int)code, buf));
#else
	UNUSED_ARGUMENT(fd);
	UNUSED_ARGUMENT(code);
	UNUSED_ARGUMENT(buf);

	return((long)-1);
#endif
}

INTERNAL long
s_signal(long signo, void (*adr)())
{
#ifndef WIN32
	return((long)signal((int)signo, adr));
#else
	UNUSED_ARGUMENT(signo);
	UNUSED_ARGUMENT(adr);

	return(0L);
#endif
}

/* Within the first blank-delimited field, translate / to \ */
#if defined(WIN32) || defined(DOS)
INTERNAL char *
backslash(char *cmd)
{
	static char cmdbuf[256];
	char c, *newp;
	int field2;

	field2 = 0;
	newp = cmdbuf;
	do {
		c = *cmd++;
		switch (c) {
		case ' ':  field2 = 1;  break;
		case '/':  if (field2 == 0) c = '\\';    break;
		}
		*newp++ = c;
	} while(c != '\0');
	return(cmdbuf);
}
#endif /* WIN32 || DOS */

INTERNAL long
s_system(char *str)
{
	int i;
	char *cmd;

	fflush(stdout);
	linemode();
#if defined(WIN32) || defined(DOS)
	/*
	 * Environment variables must be expanded by the wrapper
	 * under DOS.  On Unix, system() calls the shell which does it.
	 */
	cmd = backslash(expand_name(str));
#else
	cmd = expand_name(str);
#endif
	i = system(cmd);
	keymode();

	return ((long)i);
}

/*
 * DOS doesn't allow trailing backslashes in directory name
 * arguments to system calls.  This function removes them.
 * It modifies the argument string, so it's only safe to use
 * this on strings that are known to be in temporary storage.
 * For now, this is only used on the result from backslash().
 */
#if defined(WIN32) || defined(DOS)
INTERNAL char *
clean_dir(char *name)
{
	int namelen;

	namelen = strlen(name);
	if (namelen && name[namelen - 1] == '\\')
		name[namelen - 1] = '\0';
	return(name);
}
#endif /* WIN32 || DOS */


INTERNAL long
s_chdir(char *str)
{
	char *name;
#if defined(WIN32) || defined(DOS)
	name = clean_dir(backslash(expand_name(str)));
#else
	name = expand_name(str);
#endif
	return((long)chdir(name));
}

INTERNAL long
s_getwd(char *buf)
{
	return ((long)getcwd(buf, MAXPATHLEN));
}

INTERNAL long
s_getwd0(void)
{
	static char tmpbuf[MAXPATHLEN];

	return ((long)getcwd(tmpbuf, MAXPATHLEN));
}

#ifdef ARM64SIM

#define MB(x)           ((x) << 20)
#define BASE_ALIGN      MB(4)
#define BASE_MASK       (BASE_ALIGN -1)
#define HEAP_SIZE       MB(2000)
#define BASE_OFFSET(x)  ((BASE_ALIGN - (x)) & BASE_MASK)
void *heap_base;
long heap_size;
void *heap_ptr;

INTERNAL void *
m_alloc_dictionary(long size)
{
    long asize = roundup(size + HEAP_SIZE, BASE_ALIGN);
    void *abase = MAP_FAILED;
    int mprot = PROT_READ|PROT_WRITE;
    int mflags = MAP_ANON|MAP_PRIVATE;

    abase = malloc(asize);
    if (abase == NULL) {
        perror("malloc");
        exit(1);
    }

    long heap_offset = BASE_OFFSET(size);
    heap_base = abase + size + heap_offset;
    heap_size = ((asize - (size + heap_offset)) + BASE_MASK) & ~BASE_MASK;
    heap_ptr = heap_base;

    // printf("size = 0x%lx, asize = 0x%lx, heap_size = 0x%lx\n", size, asize, heap_size);
    // printf("abase = %p, heap_base = %p, heap_offset = 0x%lx\n", abase, heap_base, heap_offset);

    return abase;
}

INTERNAL long
m_alloc(long size)
{
    void *addr;

    // printf("alloc: size = %lx -> ", size);

    if (size >= 0x1000) {
        size = roundup(size, 0x1000);
        heap_ptr = (void *)roundup((uintptr_t)heap_ptr, 0x1000);
    } else {
        size = roundup(size, 0x100);
    }

    addr = heap_ptr;
    heap_ptr += size;

    if (heap_ptr >= (heap_base + heap_size)) {
        fflush(stdout);
        fprintf(stderr, "ERROR: Forth Wrapper (simulator) Heap exhausted!\n");
        s_bye(-1);
    }

    // printf("%p\n", addr);

    return (long)addr;
}

INTERNAL long
m_free(long size, char *adr)
{
    // free((void *)adr);
    return 0L;
}

#else // ARM64SIM
INTERNAL long
m_alloc(long size)
{
	char *mem;

	size = (size+7) & ~7;
	mem = (char *)malloc((size_t)size);
	if (mem != NULL)
		memset(mem, '\0', size);

	return((long)mem);
}

/* ARGSUSED */
INTERNAL long
m_free(long size, char *adr)
{
	UNUSED_ARGUMENT(size);
	free(adr);
	return 0L;
}
#endif // ARM64SIM

INTERNAL long
m_realloc(long size, char *adr)
{
	char *mem;

	size = (size+7) & ~7;
	mem = (char *)realloc(adr, (size_t)size);
	return((long)mem);
}

#ifdef __unix__
INTERNAL long
m_sbrk(long size)
{
#ifdef __APPLE__
	perror("forth: sbrk is no longer supported on Mac OS X 10.9\n");
	exit(1);
#else  // Other UNIXs still support sbrk()
	return((long)sbrk(size));
#endif
}
#endif

INTERNAL long
c_getenv(char *str)
{
	return((long)getenv(str));
}

#ifdef SYS5
#include <sys/time.h>
#ifndef IRIS
#include <sys/timeb.h>
#endif
#endif
INTERNAL long
today(void)
{
	long tadd;
	time(&tadd);
	return((long)localtime(&tadd));
}

INTERNAL long
timez(void)
{
#if defined(BSD)
	static struct timeval t;
	static struct timezone tz;
	extern int gettimeofday();

	gettimeofday(&t, &tz);
	return((long)tz.tz_minuteswest);
#else
# ifdef SYS5
#  ifdef IRIS
	return((long)480);	/* Assume PST */
#  else
  	static struct timeb tbuf;
#   ifndef AIX
	extern int ftime();

	ftime(&tbuf);
#   endif
	return((long)tbuf.timezone);
#  endif
# endif
#endif
#ifdef MINIWRAPPER
	return((long)480);	/* Assume PST */
#endif
}

#if defined(BSD) || defined(__linux__)
INTERNAL long
s_timeofday(struct timeval *tvp)
{
	static struct timeval t;
	static struct timezone tz;
	extern int gettimeofday();

	if (tvp == 0)
		tvp = &t;
	gettimeofday(tvp, &tz);
	return((long)tvp);
}
#endif

/* Return a string representing the name of the time zone */
INTERNAL long
timezstr(void)
{
	return((long)"");	/* Regulus doesn't seem to have this */
}

/*
 * Flush the data cache if necessary and possible.  Used after writing
 * instructions into the dictionary.
 */
#if defined(NetBSD) && defined(M68K)
#include </usr/include/m68k/sync_icache.h>
#endif

INTERNAL long
s_flushcache(char *adr, long len)
{
	UNUSED_ARGUMENT(adr);
	UNUSED_ARGUMENT(len);

#ifdef __APPLE__
	sys_icache_invalidate((void *)adr, (size_t)len);
	return 0L;
#endif
#if defined(__linux__) && defined(ARM) 
	/* There is another way to achieve the goal of making the */
	/* dictionary executable.  You can add "-Wl,-z,execstack" */
	/* to the cc command line or add "-z execstack" to the ld */
	/* command line.  mprotect() is perhaps more precise, making */
	/* only the dictionary executable while leaving the stack */
	/* protected, although that is probably pointless since */
	/* the whole point of this program is code injection. */
	mprotect(adr, len, PROT_READ | PROT_WRITE | PROT_EXEC);
	__clear_cache(adr, adr+len);
	return 0L;
#endif
#if defined(__linux__) && defined(MIPS) && !defined(MIPSSIM)
	extern int cacheflush(char *addr, int nbytes, int cache);
	(void) cacheflush(adr, len, BCACHE);
	return 0L;
#endif
#if defined(NetBSD) && defined(ARM)
	struct arm32_sync_icache_args { void *addr; long len; } sysarch_args;

	sysarch_args.addr = (void *)adr;
	sysarch_args.len = len;
	sysarch(0, &sysarch_args);
	return 0L;
#endif
#if defined(NetBSD) && defined(M68K)
	m68k_sync_icache(adr, len);
	return 0L;
#endif
#ifdef NeXT
	asm("trap #2");
	return 0L;
#endif
#ifdef WINNT
	FlushInstructionCache(GetCurrentProcess(), adr, len);
	return 0L;
#endif
#ifdef AIX
	_sync_cache_range(adr, len);
	return 0L;
#endif
#ifdef LinuxPOWERPC
/*
 * In principle, this code should work on any operating system;
 * the cache management instructions that it uses are nonpriviliged.
 * The cache block size is consistent across most PPC chips.
 */
#define CACHEBLOCKSIZE 0x20
#define CACHEALIGN(adr)  (void *)((long)(adr) & ~(CACHEBLOCKSIZE-1))
	register void *block, *end;
	block = CACHEALIGN(adr);
	end = CACHEALIGN(adr + len + (CACHEBLOCKSIZE-1));
	while (block < end) {
		asm("dcbst 0,%0; sync" : : "r" (block));
		asm("icbi  0,%0; sync" : : "r" (block));
		block += CACHEBLOCKSIZE;
	}
#endif
	return 0L;
}

INTERNAL long
m_deflate(long outlen, long outadr, long inlen, long inadr)
{
	/*
	 * Zlib compress() returns a buffer in zlib format (see RFC1950).
	 * The buffer is formatted as
	 *   Header[2]  Compressed_data[outlen-6] Adler32[4]
	 * Our inflate() routine expects gzip format (RFC1952):
	 *   Header[10] Compressed_data[outlen-6] CRC32[4] inlen[4]
	 * The conversion is simple so let's just do it here.
	 * Note the CRC32 and inlen fields are little-endian by spec.
	 * Note the overlapping copy requires memmove() or equivalent.
	 * Is the outbuf big enough to handle pathological cases?
	 */
	unsigned char *outbuf = (unsigned char *)outadr;  /* type convenience */
	unsigned long datalen;
	unsigned char gzip_hdr[] = {
		0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03
	};
	unsigned long crc = crc32(0, inadr, inlen);
	int err = compress(outbuf, &outlen, (void *)inadr, inlen);
	if (err) return 0;

	datalen = outlen - 6;
	memmove(&outbuf[10], &outbuf[2], datalen);
	memmove(&outbuf[0], gzip_hdr, 10);
#ifndef HOST_LITTLE_ENDIAN
	crc = lbflip(crc);
	inlen = lbflip(inlen);
#endif
	/* The CRC and input length are little-endian, not necessarily aligned */
	outbuf[10 + datalen] = crc & 0xff;
	outbuf[11 + datalen] = (crc>>8) & 0xff;
	outbuf[12 + datalen] = (crc>>16) & 0xff;
	outbuf[13 + datalen] = (crc>>24) & 0xff;
	outbuf[14 + datalen] = inlen & 0xff;
	outbuf[15 + datalen] = (inlen>>8) & 0xff;
	outbuf[16 + datalen] = (inlen>>16) & 0xff;
	outbuf[17 + datalen] = (inlen>>24) & 0xff;
	return (18 + datalen);
}

INTERNAL long
m_inflate(long nohdr, long outadr, long inadr)
{
	static char workspace[0x10000];
	return((long)inflate(workspace, nohdr, (void *)outadr, (void *)inadr));
}

INTERNAL long
m_map(long fd, long len, long off)
{
#ifdef WIN32
	return -1;
#else
	return (long)mmap((void *)0, (size_t)len, PROT_READ|PROT_WRITE, MAP_SHARED, (int)fd, (off_t)off);
#endif
}

INTERNAL long
m_unmap(long len, long addr)
{
#ifdef WIN32
	return -1;
#else
	return (long)munmap((void *)addr, (size_t)len);
#endif
}

/*
 * Tries to open the named file looking in each directory of the
 * search path specified by the environment variable FTHPATH.
 * Returns file descriptor or -1 if not found
 */
char fnb[MAXPATHLEN];
INTERNAL long
path_open(char *fn)
{
	static char *path;
	register char *dp;
	int fd;
	register char  *lpath;

	if (fn == (char *)0)
		return -1;
	if (path == (char *)0) {
		if (((path = getenv ("FTHPATH")) == (char *)0)
		    &&  ((path = getenv ("FPATH")) == (char *)0))	/* ksh uses FPATH ! */
			path = DEF_FPATH;
	}

	lpath = path;

	/*
	 * Don't apply search path to filenames beginning
	 * with either a drive specification or a slash.
	 */
	if ((strlen(fn) >= 2) && (fn[1] == ':'))
		lpath = "";
	if (*fn == '/' || *fn == '\\')
		lpath = "";
	do {
		dp = fnb;
		while (*lpath && *lpath != ENV_DELIM)
			*dp++ = *lpath++;
		if (dp != fnb)
			*dp++ = '/';
		strcpy (dp, fn);
		if ((fd = open (fnb, _O_BINARY, 0)) >= 0)
			return(fd);
	} while (*lpath++);
	if ((fd = open (fn, _O_BINARY, 0)) >= 0)
		return(fd);
	return -1;
}

INTERNAL int
executable(char *filename)	/* True if file is executable */
{
#ifdef WIN32
	return(1);
#else
	struct stat stbuf;

	return(   stat(expand_name(filename),&stbuf) == 0
		  && (stbuf.st_mode&S_IFMT) == S_IFREG
		  &&  access(filename,1) == 0
		);
#endif
}

INTERNAL long
f_modtime(long filename)	/* True if file is executable */
{
	struct stat stbuf;

	if (stat(expand_name((char *)filename),&stbuf) != 0)
		return (0L);
	return ((long)stbuf.st_mtime);
}

/* Find fname for symbol table  */
INTERNAL long
pathname(void)
{   
	static char buf[256];
	register char *cp, *cp2;
	char *getenv();

	cp = getenv("PATH");
	if(cp == NULL) cp=DEF_PATH;
	if(*cp == ':' || *progname == '/') {
		cp++;
		if(executable(progname)) {
			strcpy(buf, progname);
			return((long)buf);
		}
	}
	for(;*cp;) {
		/* copy over current directory and then append progname */
		for(cp2 = buf; (*cp) != '\0' && (*cp) != ':';)
			*cp2++ = *cp++;
		*cp2++ = '/';
		strcpy(cp2, progname);
		if(*cp) cp++;
		if(!executable(buf)) continue;
		return((long)buf);
	}
	strcpy(buf, progname);
	return((long)buf);
}

INTERNAL char *
substr(char *str, int pos, int n)
{
	register int len = strlen(str);
	static char outstr[128];

	if( pos < 0 )
		pos += len+1;
	if( pos <= 0 )
		pos = 1;
	if (n < 0)
		n += len;
	if (pos + n - 1 > len) {
		n = len + 1  - pos;
		if (n < 0)
			n = 0;
	}
	strncpy(outstr, str + pos - 1, n);
	outstr[n] = '\0';

	return(outstr);
}
#ifdef SCCS

INTERNAL char *
sccs_name(char *name)
{
	static char sccsname[512];
	char *p;
	int dirlen;

	/* Find the beginning of the last filename component */

	if ((p = strrchr(name, '/')) == NULL)
		p = name;
	else
		p++;

	dirlen = p - name;

	strcpy(sccsname, name);			/* Copy whole path */
	strcpy(sccsname+dirlen, "SCCS/s.");	/* Merge in "SCCS/s." */
	strcat(sccsname, p);			/* Put filename back */

	return(sccsname);

}


/*   file | SCCS | obsolete (return value)
 *   -----+------+------------------------
 *    Y   |  Y   |    ?     (SCCS > file)
 *    N   |  Y   |    Y          (1)
 *    Y   |  N   |    N          (0)
 *    N   |  N   |    Error      (-1)
 */
INTERNAL int
isobsolete(char *name)
{
	struct stat status, sccsstatus;
	int file, sccsfile;

	file = stat(name, &status);
	sccsfile = stat(sccs_name(name), &sccsstatus);

	/* If the file is missing, it is deemed "obsolete" */
	if( file == -1 )
		if( sccsfile == -1 )
			return(-1);      /* Both file and SCCS file missing */
		else
			return(1);       /* file missing,  but SCCS file is there */
	else
		if ( sccsfile == -1 )
			return(0);       /* file is there and there is no SCCS file */
	else                             /* Both exist, compare times */
		return((sccsstatus.st_mtime > status.st_mtime) ? 1 : 0);
}

INTERNAL char *
sccs_get(char *name)
{
	static char str[512];

	strcpy(str,sccs_get_cmd);
	strcat(str,name);
	strcat(str," -G");
	strcat(str,name);
	return (str);
}

#endif

char *fetchenv(char *name);
char *
fetchenv(char *name)
{
	if (*bpval != '\0' && strcmp(name, "BP") == 0)
		return (bpval);
	if (*hostdirval != '\0' && strcmp(name, "HOSTDIR") == 0)
		return (hostdirval);
	return (getenv(name));
}

INTERNAL char *
expand_name(char *name)
{
	char envvar[64], *fnamep, *envp, paren, *fullp;
	static char fullname[MAXPATHLEN];
	int ndx = 0;

	fullp = fullname;
	fullname[0] = '\0';

	fnamep = name;

	while (*fnamep) {
		if (*fnamep == '$') {
			fnamep++;
			if (*fnamep == '{' || *fnamep == '(') {	// multi char env var
				if (*fnamep == '{')
					paren = '}';
				else
					paren = ')';
				fnamep++;

				envvar[ndx++] = *(fnamep++);

				while (*fnamep != paren && ndx < MAXPATHLEN && *fnamep != '\0') {
					envvar[ndx++] = *(fnamep++);
				}
				if (*fnamep == paren) {
					fnamep++;
				} else {
					ndx = 0;
					fnamep = name;
				}
			} else		/* single char env. var. */
				envvar[ndx++] = *(fnamep++);
			envvar[ndx] = '\0';

			if (ndx > 0 && (envp = fetchenv(envvar)) != NULL) {
				log_env(envvar, envp);
				strcpy(fullp, envp);
				fullp += strlen(envp);
			} else {
				printf("Can't find environment variable %s in %s\n", envvar,name);
			}
			ndx = 0;
		} else {
			*fullp++ = *fnamep++;
		}
	}
	*fullp = '\0';
	return (fullname);
}


// LICENSE_BEGIN
// Copyright (c) 2006 FirmWorks
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
