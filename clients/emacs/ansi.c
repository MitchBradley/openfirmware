/*
 * The routines in this file provide support for ANSI style terminals
 * over a serial line. The serial I/O services are provided by routines in
 * "termio.c". It compiles into nothing if not an ANSI device.
 */

#define	termdef	1			/* don't define "term" external */

#include	"estruct.h"
#include        "edef.h"

#if     ANSI

#if	AMIGA
#define NROW    23                      /* Screen size.                 */
#define NCOL    77                      /* Edit if you want to.         */
#else
/*
 * PCs really have 25 lines, but the VT100 terminal emulator in the
 * MS Windows "Terminal" accessory does really bad things if you tell
 * it to go to line 25
 */
#define NROW    24                      /* Screen size.                 */
#define NCOL    80                      /* Edit if you want to.         */
#endif
#define	NPAUSE	100			/* # times thru update to pause */
#define	MARGIN	8			/* size of minimim margin and	*/
#define	SCRSIZ	64			/* scroll size for extended lines */
#define BEL     0x07                    /* BEL character.               */
#define ESC     0x1B                    /* ESC character.               */

extern  int     ttopen();               /* Forward references.          */
extern  int     ttgetc();
extern  int     ttputc();
extern  int     ttflush();
extern  int     ttclose();
extern  int     ansimove();
extern  int     ansieeol();
extern  int     ansieeop();
extern  int     ansibeep();
extern  int     ansiopen();
extern	int	ansirev();
extern	int	ansiclose();

#if	COLOR
extern	int	ansifcol();
extern	int	ansibcol();

int	cfcolor = -1;		/* current forground color */
int	cbcolor = -1;		/* current background color */
#endif

/*
 * Standard terminal interface dispatch table. Most of the fields point into
 * "termio" code.
 */
TERM    term    = {
        NROW-1,
        NCOL,
	MARGIN,
	SCRSIZ,
	NPAUSE,
        ansiopen,
        ansiclose,
        ttgetc,
        ttputc,
        ttflush,
        ansimove,
        ansieeol,
        ansieeop,
        ansibeep,
	ansirev
#if	COLOR
	, ansifcol,
	ansibcol
#endif
};

#if	COLOR
ansifcol(color)		/* set the current output color */

int color;	/* color to set */

{
	if (color == cfcolor)
		return;
	ttputc(ESC);
	ttputc('[');
	ansiparm(color+30);
	ttputc('m');
	cfcolor = color;
}

ansibold()
{
	ttputc(ESC);
	ttputc('[');
	ttputc('1');
	ttputc('m');
}

ansibcol(color)		/* set the current background color */

int color;	/* color to set */

{
	if (color == cbcolor)
		return;
	ttputc(ESC);
	ttputc('[');
	ansiparm(color+40);
	ttputc('m');
        cbcolor = color;
}
#endif

ansimove(row, col)
{
        ttputc(ESC);
        ttputc('[');
        ansiparm(row+1);
        ttputc(';');
        ansiparm(col+1);
        ttputc('H');
}

ansieeol()
{
        ttputc(ESC);
        ttputc('[');
        ttputc('K');
}

ansieeop()
{
#if	COLOR
	ansifcol(gfcolor);
	ansibcol(gbcolor);
#endif
        ttputc(ESC);
        ttputc('[');
        ttputc('J');
}

ansirev(state)		/* change reverse video state */

int state;	/* TRUE = reverse, FALSE = normal */

{
#if	COLOR
	int ftmp, btmp;		/* temporaries for colors */

	if (state == FALSE) {
		ftmp = cfcolor;
		btmp = cbcolor;
		cfcolor = -1;
		cbcolor = -1;
		ansifcol(ftmp);
		ansibcol(btmp);
	}
#else
	ttputc(ESC);
	ttputc('[');
	ttputc(state ? '7': '0');
	ttputc('m');
#endif
}

ansibeep()
{
        ttputc(BEL);
        ttflush();
}

ansiparm(n)
register int    n;
{
        register int q,r;

        q = n/10;
        if (q != 0) {
		r = q/10;
		if (r != 0) {
			ttputc((r%10)+'0');
		}
		ttputc((q%10) + '0');
        }
        ttputc((n%10) + '0');
}

ansiopen()
{
#if     V7 | USG | BSD
        register char *cp;
        char *getenv();

        if ((cp = getenv("TERM")) == NULL) {
                puts("Shell variable TERM not defined!");
                exit(1);
        }
        if (strcmp(cp, "vt100") != 0) {
                puts("Terminal type not 'vt100'!");
                exit(1);
        }
#endif
#if	OFW
	term.t_nrow = stdout_rows() - 1;
	term.t_ncol = stdout_columns();
#endif
	revexist = TRUE;
        ttopen();
}

ansiclose()

{
#if	COLOR
	ansifcol(7);
	ansibcol(0);
#endif
	ttclose();
}
#else
ansihello()
{
}
#endif
