: >instance-data-err  ( pfa -- )
   true abort" Tried to access instance-specific data with no current instance"
;

\ The following code tries to implement:
\
\         my-self  if  @ my-self + exit  then
\
\ Although the implementation is closer to:
\
\         @  myself 0=  IF  ERROR  THEN  myself +

code  >instance-data  ( pfa -- adr )
   ' my-self >body  l@
   set    x0,*
   ldr    x1,[up,x0]                 \ myself
   ldr    x2,[tos]                   \ @
   cbz    x1, '' >instance-data-err  \ ( myself )  0=  IF  ERROR  THEN
   add    tos,x1,x2                  \ myself ++
c;
