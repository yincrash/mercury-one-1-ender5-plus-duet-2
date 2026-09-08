; bed.g
; called to level the bed (G32)
;
; Manual bed levelling assistant: probes next to each of the 4 bed screws
; (positions from M671 in config.g) and reports how far to turn each one.
; Run G32 repeatedly until the reported corrections are small, then run G29
; separately for mesh compensation.
;
; TODO: probe points must be within probe reach and match M671 order:
;   P0 rear-right, P1 front-right, P2 rear-left, P3 front-left

M561 ; clear any existing bed transform
if !move.axes[0].homed || !move.axes[1].homed || !move.axes[2].homed
  G28 ; home if needed
G30 P0 X316 Y295 Z-99999 ; rear-right screw
G30 P1 X316 Y35 Z-99999 ; front-right screw
G30 P2 X46 Y295 Z-99999 ; rear-left screw
G30 P3 X46 Y35 Z-99999 S4 ; front-left screw, then report screw adjustments
