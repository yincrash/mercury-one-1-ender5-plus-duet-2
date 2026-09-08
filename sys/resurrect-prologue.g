; resurrect-prologue.g
; called by resurrect.g (M916) after a power failure, before the print resumes.
; Must home X and Y without touching Z: the print is still on the bed, so
; do NOT call homeall.g / homez.g (they G30 at bed centre).
G91 ; relative positioning
G1 H2 Z5 F600 ; lift Z a little to clear the print
G90 ; absolute positioning
M98 P"homex.g" ; home X
M98 P"homey.g" ; home Y
M116 ; wait for temperatures
