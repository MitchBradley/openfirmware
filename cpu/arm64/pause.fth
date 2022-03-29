\ mutiltasker routines

\ Give other tasks a chance to run
code (pause)  ( -- )
   mrs   x0, DAIF
   tst   x0, #0x0C0
   0<> if
      \ Either Interrupts or Fast IRQs are masked,
      \ do not change to another task.
      br   up
   then

   str   ip,'user saved-ip    \ save my VM: six registers
   str   lp,'user saved-lp
   str   rp,'user saved-rp 
   str   sp,'user saved-sp 
   str   tos,'user saved-tos
   str   lp,'user saved-lp
   mov   x0, xsp
   str   x0,'user saved-ssp

   ldr   w0,'user link        \ get link token
   add   up,x0,org            \ point UP to next task
   adr   x1, 'body curr-task  \ save current task pointer
   str   up, [x1]
   ldr   w0,'user entry       \ get entry token
   add   x0,x0,org            \ enter next task
   br    x0
end-code

\ Entry for each task points to one of the two following routines.

\ a sleeping task does this
label skip-me  ( -- 'skip-me )
   ldr   w0,'user link        \ get link token
   add   up,x0,org            \ point UP to next task
   adr   x1, 'body curr-task  \ save current task pointer
   str   up, [x1]
   ldr   w0,'user entry       \ get entry token
   add   x0,x0,org            \ enter next task
   br    x0
end-code

\ a ready task does this
\ UP is already set to the next task
label wake-me  ( -- 'wake-me )     \ run active task
    ldr   ip,'user saved-ip    \ load my VM: six registers
    ldr   lp,'user saved-lp
    ldr   rp,'user saved-rp 
    ldr   sp,'user saved-sp 
    ldr   tos,'user saved-tos
    ldr   lp,'user saved-lp
    ldr   x0,'user saved-ssp
    mov   xsp, x0
c;   \  jump to next

code ami-main-task?
    push  tos,sp
    set   tos,#0
    adr   x0,'body main-task
    ldr   x0,[x0]
    cmp   up,x0
    0= if
       sub  tos,tos,#1
    then
c;
