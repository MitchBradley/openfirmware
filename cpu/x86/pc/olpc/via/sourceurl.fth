\ Make a file containing the URL of the source code

show-rebuilds?  false to show-rebuilds?   \ We don't need to see these commands

" git remote --verbose show | head -1 | cut -f2 | cut -f1 -d' ' | tr  \\n ' ' > sourceurl ; git branch -v | cut -f2,3 -d' ' | tr  \\n ' ' >>sourceurl ; git status --porcelain | wc --lines >>sourceurl" $sh

to show-rebuilds?
