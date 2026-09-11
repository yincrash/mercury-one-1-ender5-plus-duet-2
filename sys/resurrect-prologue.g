; resurrect-prologue.g
; called by resurrect.g (M916) after a power failure or an M911 pause, before the print resumes.
; resurrect.g has already set the heater temperatures and loaded the height map, and passes the
; position at the moment of failure as X, Y and Z parameters (RRF 3.5+). Z is not trusted: the
; M911 script lifts the bed 3 mm after that position is saved and may or may not finish before the
; PSU dies, and the motors can drift up to 4 full steps at power-off. So Z is re-probed instead.
; The front-left corner of the bed (about 70 x 70 mm) must be clear of the print: the probe lands
; on the front-left mesh point (probe X30 Y30, nozzle about X55 Y53) and a purge line goes at Y8.
; Do NOT call homeall.g / homez.g: they probe at the bed centre, where the print is.
; Order matters: heat the nozzle first (quick, and a hot nozzle releases from the print if it was
; left touching it), home and park, then wait for the bed away from the print (a nozzle waiting
; minutes for the bed while parked on the print oozes onto it, seen 2026-09-11), probe, purge.
; The bed is already heating: resurrect.g sends M140 before calling this file.
; Afterwards resurrect.g lifts to Z+2, travels to the saved XY, descends to Z and resumes.
M116 P0 ; wait for the tool heater only, not the bed
G91 ; relative positioning
G1 H2 Z5 F600 ; lower the bed 5 mm so the nozzle clears the print while homing (works unhomed)
G90 ; absolute positioning
M98 P"homex.g" ; home X (its own +5/-5 Z moves cancel out)
M98 P"homey.g" ; home Y
G1 X{move.compensation.probeGrid.mins[0] - sensors.probes[0].offsets[0]} Y{move.compensation.probeGrid.mins[1] - sensors.probes[0].offsets[1]} F6000 ; park with the probe over the front-left mesh point
M116 ; now wait for the bed too, here, away from the print
G30 ; probe: Z is now known
G1 Z2 F300 ; lift off the trigger point
G1 X5 Y8 F6000 ; purge line start (Y8 keeps clear of the start G-code purge at Y3)
G1 Z0.3 F300
M83 ; relative extrusion
G1 X60 Y8 E8 F900 ; short purge: undoes the M911 retraction and primes the nozzle
G1 X60 Y8.6 F3000 ; sideways step to break the string
G1 Z5 F300 ; lift before resurrect.g travels back over the print
