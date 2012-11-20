purpose: Manufacturing testing
\ See license at end of file

: alloc-buffer  ( -- )
   record-len la1+  " dma-alloc" $call-parent to record-base
;
: dealloc-buffer  ( -- )
   record-base record-len la1+  " dma-free" $call-parent
;

: ?key-abort  ( -- )
   key?  if
      key h# 1b =  if  ." Aborting" abort  then
   then
;
: connect-headphones  ( -- )
   headphone-jack pin-sense? 0= if
      " connect-headphones" $instructions
      begin  ?key-abort  instructions-idle  pin-sense?  until
      instructions-done
   then
;
: disconnect-headphones  ( -- )
   headphone-jack pin-sense?  if
      " disconnect-headphones" $instructions
      begin  ?key-abort  instructions-idle  pin-sense?  0= until
      instructions-done
   then
;
: speaker-test  ( -- )
   disconnect-headphones
   2 to #channels
   ." Playing left to right sweep "
   make-sweep  0 set-volume  play  cr
;

: headphones-test  ( -- )
   2 to #channels
   connect-headphones
   speakers-off  \ turn off speaker
   make-sweep  -9 set-volume  play
   speakers-on   \ turn speaker back on
;

: louder-mic-test  ( -- )
   ." Recording ..." cr
   record
   ." Playing ..." cr
   d# 0 set-volume  play
;

: connect-mic
   external-mic pin-sense? 0= if
      " connect-microphone" $instructions
      begin  ?key-abort  instructions-idle  pin-sense?  until
      instructions-done
   then
;
: disconnect-mic  ( -- )
   external-mic pin-sense?  if
      " disconnect-microphone" $instructions
      begin  ?key-abort  instructions-idle  pin-sense? 0=  until
      instructions-done
   then
;

: builtin-mic-test  ( -- )
   disconnect-mic
   ." Press a key to test recording / playback on the built-in microphone.. "
   key drop cr
   louder-mic-test
;

: external-mic-test  ( -- )
   connect-mic
   ." Press a key to test recording / playback on the external microphone.. "
   key drop cr
   mic-test
;

0 value analyzer-ih
: $call-analyzer  ( ? name$ -- ? )  analyzer-ih $call-method  ;
: open-analyzer  ( -- )
   analyzer-ih  0=  if
      " "  " audio-test" $open-package  to analyzer-ih
   then
;
: close-analyzer  ( -- )
   analyzer-ih  if
      analyzer-ih close-package
      0 to analyzer-ih
   then
;
: test-common  ( setup$ -- error? )
   $call-analyzer                    ( )
   " prepare-signal" $call-analyzer  ( pb /pb rb /rb )
   \ First shorter run lets the input channel settle
\   2over 4 /  2over 4 /  out-in      ( pb /pb rb /rb )
   out-in                            ( )
   " analyze-signal" $call-analyzer  ( error? )
;
: .test-error  ( error? -- error? )
    dup 1 and  if   ." Left channel failure" cr  then
    dup 2 and  if   ." Right channel failure" cr  then
;

false value plot?  \ Set to true to plot the impulse response, for debugging
: plot-impulse  ( adr -- )
   d# 600              ( adr #samples )
   " 0 set-fg  h# ffffffff set-bg single-drawing ( clear-drawing ) wave" evaluate
\   key ascii d = if debug-me then
;
[ifndef] $call-screen  : $call-screen  " $call-screen" evaluate  ;  [then]
: plot-impulse0  ( adr -- )   0 " set-wave#" $call-screen plot-impulse  ;
: plot-impulse1  ( adr -- )   1 " set-wave#" $call-screen plot-impulse  ;

: test-with-case  ( -- error? )
\   " setup-case" $call-analyzer
\   xxx - this needs to use the internal speakers and mic even though the loopback cable is attached
   true to force-speakers?  true to force-internal-mic?
   mic-bias-on
   input-test-settings  mono
   output-test-settings  case-test-volume set-volume
   ." Testing internal speakers and microphone" cr
   " setup-case" test-common  .test-error
   false to force-speakers?  false to force-internal-mic?
   plot?  if
      0 " calc-sm-impulse" $call-analyzer  plot-impulse0
      2 " calc-sm-impulse" $call-analyzer  plot-impulse1
   then
;
: test-with-fixture  ( -- error? )
   true to force-speakers?  true to force-internal-mic?
   mic-bias-on
   input-test-settings  mono
   output-test-settings  fixture-test-volume set-volume  \ -23 prevents obvious visible clipping
   ." Testing internal speakers and microphone with fixture" cr
   " setup-fixture" test-common  .test-error
   false to force-speakers?  false to force-internal-mic?
   plot?  if
      0 " calc-sm-impulse" $call-analyzer  plot-impulse0
      2 " calc-sm-impulse" $call-analyzer  plot-impulse1
   then
;
true value allow-swapping?
: ?try-swapped   ( error? -- error?' )
   allow-swapping?  0=  if  exit  then   ( error? )
   dup  if                               ( error? )
       " swap-lr-pb" $call-analyzer      ( error? )
       " analyze-signal" $call-analyzer  ( error? swapped-error? )
       " unswap-lr-pb" $call-analyzer    ( error? swapped-error? )
       0=  if                            ( error? )
          \ If swapping left and right "fixes" the problem, we
          \ don't report an error.  This works around a hard-to-fix
          \ random channel-swapping problem with Marvell MMP3.
          ." Channel swap!" cr           ( error? )
          drop false                     ( 0 )
       then                              ( error? )
   then                                  ( error? )
;
: test-with-loopback  ( -- error? )
   mic-bias-off
   input-test-settings   stereo
   output-test-settings  loopback-test-volume set-volume
   ." Testing headphone and microphone jacks with loopback cable" cr
   " setup-loopback" test-common         ( error? )
   ?try-swapped
   .test-error

   plot?  if
      0 " calc-stereo-impulse" $call-analyzer  plot-impulse0
      2 " calc-stereo-impulse" $call-analyzer  plot-impulse1
   then
;

0 value saved-volume
: (interactive-test)  ( -- error? )
   alloc-buffer
   headphones-test
   external-mic-test
   speaker-test
   builtin-mic-test
   dealloc-buffer
   " confirm-selftest?" eval
;
: interactive-test  ( -- )
   " playback-volume" evaluate to saved-volume
   0 " to playback-volume" evaluate
   ['] (interactive-test) catch  if  true  then
   saved-volume " to playback-volume" evaluate
;
: loopback-connected?  ( -- flag )
   headphone-jack pin-sense? external-mic pin-sense?  and
;
: loopback-disconnected?  ( -- flag )
   headphone-jack pin-sense? 0=  external-mic pin-sense? 0=  and
;
: connect-loopback  ( -- )
   loopback-connected?  0=  if  
      " connect-loopback" $instructions
      begin  ?key-abort  instructions-idle  loopback-connected?  until
      instructions-done
   then
   d# 500 ms  \ Delay to make sure the plug is all the way in
;
: disconnect-loopback  ( -- )
   loopback-disconnected?  0=  if  
      " disconnect-loopback" $instructions
      begin  ?key-abort  instructions-idle  loopback-disconnected?  until
      instructions-done
   then
;
: acoustic-test  ( -- )
   disconnect-loopback  \ Not for 1.5; it can test internal while loopback is connected
   " smt-test?" evaluate  if
      test-with-fixture throw
   else
      test-with-case throw
   then
;
: loopback-test  ( -- )
   connect-loopback
   test-with-loopback throw
   disconnect-loopback
;
\ Returns failure by throwing
: automatic-test  ( -- )
   analysis-parameters " set-analysis-parameters" $call-analyzer
   acoustic-test
   loopback-test
;
: selftest  ( -- error? )
   diagnostic-mode?  if
      open 0=  if  ." Failed to open /audio" cr true exit  then
      open-analyzer
      ['] automatic-test catch  ( error? )
      close-analyzer   ( error? )
      close            ( error? )
   else
      selftest         ( error? )
   then
;

\ LICENSE_BEGIN
\ Copyright (c) 2009 Luke Gorrie
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
