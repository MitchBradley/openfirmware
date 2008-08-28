/*
 * The routines in this file
 * handle the reading and writing of
 * disk files. All of details about the
 * reading and writing of the disk are
 * in "fileio.c".
 */
#include	"estruct.h"
#include        "edef.h"

/*
 * Read a file into the current
 * buffer. This is really easy; all you do it
 * find the name of the file, and call the standard
 * "read a file into the current buffer" code.
 * Bound to "C-X C-R".
 */
fileread(f, n)
{
        register int    s;
        char fname[NFILEN];

        if ((s=mlreply("Read file: ", fname, NFILEN)) != TRUE)
                return(s);
        return(readin(fname, TRUE));
}

/*
 * Insert a file into the current
 * buffer. This is really easy; all you do it
 * find the name of the file, and call the standard
 * "insert a file into the current buffer" code.
 * Bound to "C-X C-I".
 */
insfile(f, n)
{
        register int    s;
        char fname[NFILEN];

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        if ((s=mlreply("Insert file: ", fname, NFILEN)) != TRUE)
                return(s);
        return(ifile(fname));
}

/*
 * Select a file for editing.
 * Look around to see if you can find the
 * fine in another buffer; if you can find it
 * just switch to the buffer. If you cannot find
 * the file, create a new buffer, read in the
 * text, and switch to the new buffer.
 * Bound to C-X C-F.
 */
filefind(f, n)
{
        char fname[NFILEN];	/* file user wishes to find */
        register int s;		/* status return */

        if ((s=mlreply("Find file: ", fname, NFILEN)) != TRUE)
                return(s);
	return(getfile(fname, TRUE));
}

viewfile(f, n)	/* visit a file in VIEW mode */
{
        char fname[NFILEN];	/* file user wishes to find */
        register int s;		/* status return */
	register WINDOW *wp;	/* scan for windows that need updating */

        if ((s=mlreply("View file: ", fname, NFILEN)) != TRUE)
                return (s);
	s = getfile(fname, FALSE);
	if (s) {	/* if we succeed, put it in view mode */
		curwp->w_bufp->b_mode |= MDVIEW;

		/* scan through and update mode lines of all windows */
		wp = wheadp;
		while (wp != NULL) {
			wp->w_flag |= WFMODE;
			wp = wp->w_wndp;
		}
	}
	return(s);
}

getfile(fname, lockfl)

char fname[];		/* file name to find */
int lockfl;		/* check the file for locks? */

{
        register BUFFER *bp;
        register LINE   *lp;
        register int    i;
        register int    s;
        char bname[NBUFN];	/* buffer name to put file */

        for (bp=bheadp; bp!=NULL; bp=bp->b_bufp) {
                if ((bp->b_flag&BFINVS)==0 && strcmp(bp->b_fname, fname)==0) {
			swbuffer(bp);
                        lp = curwp->w_dotp;
                        i = curwp->w_ntrows/2;
                        while (i-- && lback(lp)!=curbp->b_linep)
                                lp = lback(lp);
                        curwp->w_linep = lp;
                        curwp->w_flag |= WFMODE|WFHARD;
                        mlwrite("[Old buffer]");
                        return (TRUE);
                }
        }
        makename(bname, fname);                 /* New buffer name.     */
        while ((bp=bfind(bname, FALSE, 0)) != NULL) {
                s = mlreply("Buffer name: ", bname, NBUFN);
                if (s == ABORT)                 /* ^G to just quit      */
                        return (s);
                if (s == FALSE) {               /* CR to clobber it     */
                        makename(bname, fname);
                        break;
                }
        }
        if (bp==NULL && (bp=bfind(bname, TRUE, 0))==NULL) {
                mlwrite("Cannot create buffer");
                return (FALSE);
        }
        if (--curbp->b_nwnd == 0) {             /* Undisplay.           */
                curbp->b_dotp = curwp->w_dotp;
                curbp->b_doto = curwp->w_doto;
                curbp->b_markp = curwp->w_markp;
                curbp->b_marko = curwp->w_marko;
        }
        curbp = bp;                             /* Switch to it.        */
        curwp->w_bufp = bp;
        curbp->b_nwnd++;
        return(readin(fname, lockfl));          /* Read it in.          */
}

/*
 * Read file "fname" into the current
 * buffer, blowing away any text found there. Called
 * by both the read and find commands. Return the final
 * status of the read. Also called by the mainline,
 * to read in a file specified on the command line as
 * an argument. If the filename ends in a ".c", CMODE is
 * set for the current buffer.
 */
readin(fname, lockfl)

char    fname[];	/* name of file to read */
int	lockfl;		/* check for file locks? */

{
        register LINE   *lp1;
        register LINE   *lp2;
        register int    i;
        register WINDOW *wp;
        register BUFFER *bp;
        register int    s;
        register int    nbytes;
        register int    nline;
	register char	*sptr;		/* pointer into filename string */
	int		lflag;		/* any lines longer than allowed? */
        char            line[NLINE];

#if	FILOCK
	if (lockfl && lockchk(fname) == ABORT)
		return(ABORT);
#endif
        bp = curbp;                             /* Cheap.               */
        if ((s=bclear(bp)) != TRUE)             /* Might be old.        */
                return (s);
        bp->b_flag &= ~(BFINVS|BFCHG);
#if	ACMODE
	if (strlen(fname) > 1) {		/* check if a 'C' file	*/
		sptr = fname + strlen(fname) - 2;
		if (*sptr == '.' &&
		   (*(sptr + 1) == 'c' || *(sptr + 1) == 'h'))
			bp->b_mode |= MDCMOD;
	}
#endif
        strcpy(bp->b_fname, fname);
        if ((s=ffropen(fname)) == FIOERR)       /* Hard file open.      */
                goto out;
        if (s == FIOFNF) {                      /* File not found.      */
                mlwrite("[New file]");
                goto out;
        }
        mlwrite("[Reading file]");
        nline = 0;
	lflag = FALSE;
        while ((s=ffgetline(line, NLINE)) == FIOSUC || s == FIOLNG) {
		if (s == FIOLNG)
			lflag = TRUE;
                nbytes = strlen(line);
                if ((lp1=lalloc(nbytes)) == NULL) {
                        s = FIOERR;             /* Keep message on the  */
                        break;                  /* display.             */
                }
                lp2 = lback(curbp->b_linep);
                lp2->l_fp = lp1;
                lp1->l_fp = curbp->b_linep;
                lp1->l_bp = lp2;
                curbp->b_linep->l_bp = lp1;
                for (i=0; i<nbytes; ++i)
                        lputc(lp1, i, line[i]);
                ++nline;
        }
        ffclose();                              /* Ignore errors.       */
        if (s == FIOEOF) {                      /* Don't zap message!   */
                if (nline == 1)
                        mlwrite("[Read 1 line]");
                else
                        mlwrite("[Read %d lines]", nline);
        }
	if (lflag)
		mlwrite("[Read %d line(s), Long lines wrapped]",nline);
out:
        for (wp=wheadp; wp!=NULL; wp=wp->w_wndp) {
                if (wp->w_bufp == curbp) {
                        wp->w_linep = lforw(curbp->b_linep);
                        wp->w_dotp  = lforw(curbp->b_linep);
                        wp->w_doto  = 0;
                        wp->w_markp = NULL;
                        wp->w_marko = 0;
                        wp->w_flag |= WFMODE|WFHARD;
                }
        }
        if (s == FIOERR || s == FIOFNF)		/* False if error.      */
                return(FALSE);
        return (TRUE);
}

/*
 * Take a file name, and from it
 * fabricate a buffer name. This routine knows
 * about the syntax of file names on the target system.
 * I suppose that this information could be put in
 * a better place than a line of code.
 */
makename(bname, fname)
char    bname[];
char    fname[];
{
        register char   *cp1;
        register char   *cp2;

        cp1 = &fname[0];
        while (*cp1 != 0)
                ++cp1;

#if     AMIGA
        while (cp1!=&fname[0] && cp1[-1]!=':' && cp1[-1]!='/')
                --cp1;
#endif
#if     VMS
        while (cp1!=&fname[0] && cp1[-1]!=':' && cp1[-1]!=']')
                --cp1;
#endif
#if     CPM
        while (cp1!=&fname[0] && cp1[-1]!=':')
                --cp1;
#endif
#if     MSDOS
        while (cp1!=&fname[0] && cp1[-1]!=':' && cp1[-1]!='\\'&&cp1[-1]!='/')
                --cp1;
#endif
#if     V7 | USG | BSD
        while (cp1!=&fname[0] && cp1[-1]!='/')
                --cp1;
#endif
#if     OFW
        while (cp1!=&fname[0] && cp1[-1]!=':' && cp1[-1]!='\\' && cp1[-1]!='/'
	       && cp1[-1]!=',')
                --cp1;
#endif
        cp2 = &bname[0];
        while (cp2!=&bname[NBUFN-1] && *cp1!=0 && *cp1!=';')
                *cp2++ = *cp1++;
        *cp2 = 0;
}

/*
 * Ask for a file name, and write the
 * contents of the current buffer to that file.
 * Update the remembered file name and clear the
 * buffer changed flag. This handling of file names
 * is different from the earlier versions, and
 * is more compatable with Gosling EMACS than
 * with ITS EMACS. Bound to "C-X C-W".
 */
filewrite(f, n)
{
        register WINDOW *wp;
        register int    s;
        char            fname[NFILEN];

        if ((s=mlreply("Write file: ", fname, NFILEN)) != TRUE)
                return (s);
        if ((s=writeout(fname)) == TRUE) {
                strcpy(curbp->b_fname, fname);
                curbp->b_flag &= ~BFCHG;
                wp = wheadp;                    /* Update mode lines.   */
                while (wp != NULL) {
                        if (wp->w_bufp == curbp)
                                wp->w_flag |= WFMODE;
                        wp = wp->w_wndp;
                }
        }
        return (s);
}

/*
 * Save the contents of the current
 * buffer in its associatd file. No nothing
 * if nothing has changed (this may be a bug, not a
 * feature). Error if there is no remembered file
 * name for the buffer. Bound to "C-X C-S". May
 * get called by "C-Z".
 */
filesave(f, n)
{
        register WINDOW *wp;
        register int    s;

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        if ((curbp->b_flag&BFCHG) == 0)         /* Return, no changes.  */
                return (TRUE);
        if (curbp->b_fname[0] == 0) {           /* Must have a name.    */
                mlwrite("No file name");
                return (FALSE);
        }
        if ((s=writeout(curbp->b_fname)) == TRUE) {
                curbp->b_flag &= ~BFCHG;
                wp = wheadp;                    /* Update mode lines.   */
                while (wp != NULL) {
                        if (wp->w_bufp == curbp)
                                wp->w_flag |= WFMODE;
                        wp = wp->w_wndp;
                }
        }
        return (s);
}

/*
 * This function performs the details of file
 * writing. Uses the file management routines in the
 * "fileio.c" package. The number of lines written is
 * displayed. Sadly, it looks inside a LINE; provide
 * a macro for this. Most of the grief is error
 * checking of some sort.
 */
writeout(fn)
char    *fn;
{
        register int    s;
        register LINE   *lp;
        register int    nline;

        if ((s=ffwopen(fn)) != FIOSUC)          /* Open writes message. */
                return (FALSE);
	mlwrite("[Writing..]");			/* tell us were writing */
        lp = lforw(curbp->b_linep);             /* First line.          */
        nline = 0;                              /* Number of lines.     */
        while (lp != curbp->b_linep) {
                if ((s=ffputline(&lp->l_text[0], llength(lp))) != FIOSUC)
                        break;
                ++nline;
                lp = lforw(lp);
        }
        if (s == FIOSUC) {                      /* No write error.      */
                s = ffclose();
                if (s == FIOSUC) {              /* No close error.      */
                        if (nline == 1)
                                mlwrite("[Wrote 1 line]");
                        else
                                mlwrite("[Wrote %d lines]", nline);
                }
        } else                                  /* Ignore close error   */
                ffclose();                      /* if a write error.    */
        if (s != FIOSUC)                        /* Some sort of error.  */
                return (FALSE);
        return (TRUE);
}

/*
 * The command allows the user
 * to modify the file name associated with
 * the current buffer. It is like the "f" command
 * in UNIX "ed". The operation is simple; just zap
 * the name in the BUFFER structure, and mark the windows
 * as needing an update. You can type a blank line at the
 * prompt if you wish.
 */
filename(f, n)
{
        register WINDOW *wp;
        register int    s;
        char            fname[NFILEN];

        if ((s=mlreply("Name: ", fname, NFILEN)) == ABORT)
                return (s);
        if (s == FALSE)
                strcpy(curbp->b_fname, "");
        else
                strcpy(curbp->b_fname, fname);
        wp = wheadp;                            /* Update mode lines.   */
        while (wp != NULL) {
                if (wp->w_bufp == curbp)
                        wp->w_flag |= WFMODE;
                wp = wp->w_wndp;
        }
	curbp->b_mode &= ~MDVIEW;	/* no longer read only mode */
        return (TRUE);
}

/*
 * Insert file "fname" into the current
 * buffer, Called by insert file command. Return the final
 * status of the read.
 */
ifile(fname)
char    fname[];
{
        register LINE   *lp0;
        register LINE   *lp1;
        register LINE   *lp2;
        register int    i;
        register BUFFER *bp;
        register int    s;
        register int    nbytes;
        register int    nline;
	int		lflag;		/* any lines longer than allowed? */
        char            line[NLINE];

        bp = curbp;                             /* Cheap.               */
        bp->b_flag |= BFCHG;			/* we have changed	*/
	bp->b_flag &= ~BFINVS;			/* and are not temporary*/
        if ((s=ffropen(fname)) == FIOERR)       /* Hard file open.      */
                goto out;
        if (s == FIOFNF) {                      /* File not found.      */
                mlwrite("[No such file]");
		return(FALSE);
        }
        mlwrite("[Inserting file]");

	/* back up a line and save the mark here */
	curwp->w_dotp = lback(curwp->w_dotp);
	curwp->w_doto = 0;
	curwp->w_markp = curwp->w_dotp;
	curwp->w_marko = 0;

        nline = 0;
	lflag = FALSE;
        while ((s=ffgetline(line, NLINE)) == FIOSUC || s == FIOLNG) {
		if (s == FIOLNG)
			lflag = TRUE;
                nbytes = strlen(line);
                if ((lp1=lalloc(nbytes)) == NULL) {
                        s = FIOERR;             /* Keep message on the  */
                        break;                  /* display.             */
                }
		lp0 = curwp->w_dotp;	/* line previous to insert */
		lp2 = lp0->l_fp;	/* line after insert */

		/* re-link new line between lp0 and lp2 */
		lp2->l_bp = lp1;
		lp0->l_fp = lp1;
		lp1->l_bp = lp0;
		lp1->l_fp = lp2;

		/* and advance and write out the current line */
		curwp->w_dotp = lp1;
                for (i=0; i<nbytes; ++i)
                        lputc(lp1, i, line[i]);
                ++nline;
        }
        ffclose();                              /* Ignore errors.       */
	curwp->w_markp = lforw(curwp->w_markp);
        if (s == FIOEOF) {                      /* Don't zap message!   */
                if (nline == 1)
                        mlwrite("[Inserted 1 line]");
                else
                        mlwrite("[Inserted %d lines]", nline);
        }
	if (lflag)
		mlwrite("[Inserted %d line(s), Long lines wrapped]",nline);
out:
	/* advance to the next line and mark the window for changes */
	curwp->w_dotp = lforw(curwp->w_dotp);
	curwp->w_flag |= WFHARD | WFMODE;

	/* copy window parameters back to the buffer structure */
	curbp->b_dotp = curwp->w_dotp;
	curbp->b_doto = curwp->w_doto;
	curbp->b_markp = curwp->w_markp;
	curbp->b_marko = curwp->w_marko;

        if (s == FIOERR)                        /* False if error.      */
                return (FALSE);
        return (TRUE);
}
