// See license at end of file

/* For gcc, compile with -fno-builtin to suppress warnings */

#include "1275.h"
#include "stdio.h"
#include "string.h"

FILE _stdin  = { -1, 0, 0};
FILE _stdout = { -1, 0, 0};
FILE *stdin  = &_stdin;
FILE *stdout = &_stdout;

void
abort()
{
  fflush(stdout);
  OFExit();
}

void
exit(int code)
{
  fflush(stdout);
  OFExit();
}

void
sleep(ULONG delay)
{
    ULONG now = OFMilliseconds();
    delay *= 1000;
    while ((OFMilliseconds() - now) < delay)
	;
}

/* files */

char _homedir[128];

char *
gethomedir()
{
  return(_homedir);
}

void
parse_homedir(char *progname)
{
  char *p, *q, c;

  p = progname + strlen(progname);
  while (p > progname) {
    c = *--p;
    if (c == ',' || c == ':' || c == '\\') {
      ++p;
      break;
    }
  }
  for (q = _homedir; progname < p; )
    *q++ = *progname++;

  *q = '\0';
}

int
ofw_setup()
{
  static char *argv[10];
  phandle ph;
  char *argstr;
  int i = 0;
  extern int main(int, char**);

  if ((ph = OFFinddevice("/chosen")) == -1)
    abort() ;
  stdin->id  = get_cell_prop(ph, "stdin");
  stdout->id = get_cell_prop(ph, "stdout");

  argv[0] = get_str_prop(ph, "bootpath", ALLOC);
  if (argv[0] != NULL)
    parse_homedir(argv[0]);
  argstr  = get_str_prop(ph, "bootargs", ALLOC);
  if (argstr != NULL) {
    for (i = 1; i < 10;) {
      if (*argstr == '\0')
        break;
      argv[i++] = argstr;
      while (*argstr != ' ' && *argstr != '\0')
        ++argstr;
      if (*argstr == '\0')
        break;
      *argstr++ = '\0';
    }
  }
  return main(i, argv);
}

FILE *
fopen (char *name, char *mode)
{
  FILE *fp;

  fp = (FILE *)malloc(sizeof(struct _file));
  if (fp == (FILE *)NULL)
      return ((FILE *)NULL);

  if (mode[0] == 'w') {
      if ((fp->id = OFCreate(name)) == 0)
          return ((FILE *)NULL);
      goto good;
  }

  if ((fp->id = OFOpen(name)) == 0) {
      return ((FILE *)NULL);
  }
  
 good:
  fp->dirty = 0;
  fp->readonly = (strcmp(mode, "r") == 0) || (strcmp(mode, "rb") == 0);
  fp->bufc = 0;
  return(fp);
}

int
ferror(FILE *fp)
{
  return(0);	/* Implement me */
}

int
fputc(char c, FILE *fp)
{
  if (fp->readonly)
    return -1;  // EOF

  if (fp == stdout && c == '\n')
    (void) fputc('\r', fp);

  fp->buf[fp->bufc++] = c;
  fp->dirty = 1;

  if ((fp->bufc == 127) || (fp == stdout && c == '\n')) {
    OFWrite(fp->id, fp->buf, fp->bufc);
    fp->bufc = 0;
    fp->dirty = 0;
  }
  return (int)c;
}

void
fflush (FILE *fp)
{
  if (fp->dirty && fp->bufc != 0) {
    OFWrite(fp->id, fp->buf, fp->bufc);
    fp->bufc = 0;
    fp->dirty = 0;
  }
}

int
kbhit()
{
  int  count;

  if (stdin->bufc != 0)
      return 1;
  count = OFRead(stdin->id, stdin->buf, 1);
  if (count > 0) {
      stdin->bufc = count;
      stdin->inbufp = stdin->buf;
      return 1;
  }
  return 0;
}

int
fgetc(FILE *fp)
{
  int  count;

  /* try to read from the buffer */
  if (fp->bufc != 0) {
    fp->bufc--;
    return(*fp->inbufp++);
  }

  /* read from the file */
  do {
      count = OFRead(fp->id, fp->buf, 128);
  } while (count == -2);	/* Wait until input available */

  if (count > 0)
    {
      fp->bufc = count-1;
      fp->inbufp = fp->buf;
      return((*fp->inbufp++) & 0xff);
    }

  /* otherwise return EOF */
  return (-1);
}

int
fclose(FILE *fp)
{
  fflush(fp);
  OFClose(fp->id);
  free((UCHAR *)fp);
  return(0);
}

int
getchar()
{
  return(fgetc(stdin));
}

void
putchar(UCHAR c)
{
  fputc(c, stdout);
}

int
fputs(char *s, FILE *f)
{
  char c;
  while ((c = *s++) != 0)
    fputc(c, f);
  return(0);
}

int
puts(char *s)
{
  fputs(s, stdout);
  putchar('\n');
  return(0);
}

void
gets(char *buf)
{
  while ((*buf = getchar()) != '\r')
    buf++;
  *buf = '\0';
}

char *
fgets(char *buf, int n, FILE *f)
{
  char *p = buf;

  while ((n > 1) && ((*p = fgetc(f)) != '\n')) {
    p++;
    n--;
  }
  *p = '\0';
  return(buf);
}

int
unlink(char *filename)
{
  return(-1);
/* XXX Implement me */
}

int
system(const char *str)
{
  return (int)OFInterpret0(str);
}

#define MAXENV 256
char *
getenv(const char *str)
{
  phandle ph;

  if ((ph = OFFinddevice("/options")) == -1)
      return(NULL);

  return (get_str_prop(ph, str, 0));
}

int
stdout_rows()
{
  phandle ph;
  int res;

  if ((ph = OFFinddevice("/chosen")) == -1)
    return(24);
  res = get_int_prop_def(ph, "stdout-#lines", 24);
  if (res < 0)
    return(24);		/* XXX should look in device node too */
  return (res);
}

int
stdout_columns()
{
  phandle ph;
  int res;

  if ((ph = OFFinddevice("/chosen")) == -1)
      return(80);
  res = get_int_prop_def(ph, "stdout-#columns", 80);
  if (res < 0)
    return(80);		/* XXX should look in device node too */
  return (res);
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
