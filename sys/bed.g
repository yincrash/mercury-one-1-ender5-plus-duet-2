; bed.g
; called to level the bed (G32)
;
; Manual bed levelling assistant: probes at each of the 4 bed screws (positions
; measured 2026-09-09, same order as M671 in config.g) and reports how far to
; turn each one. Run G32 repeatedly until the corrections are small, then G29
; separately for mesh compensation. Best done with the bed at print temperature.

M561 ; clear any existing bed transform
if !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed
  G28 ; home if needed
G30 P0 X32.9 Y35.5 Z-99999 ; front-left screw
G30 P1 X332.9 Y37.5 Z-99999 ; front-right screw
G30 P2 X332.9 Y297.5 Z-99999 ; rear-right screw
G30 P3 X32.9 Y295.5 Z-99999 S4 ; rear-left screw, then report the 4 screw adjustments
