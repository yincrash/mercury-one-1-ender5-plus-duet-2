; resurrect-prologue.g
; called by resurrect.g (M916) after a power failure or an M911 pause, before the print resumes.
; resurrect.g has already set the heater temperatures and loaded the height map, and passes the
; position at the moment of failure as X, Y and Z parameters (RRF 3.5+). Z is not trusted: the
; M911 script lifts the bed 3 mm after that position is saved and may or may not finish before the
; PSU dies, and the motors can drift up to 4 full steps at power-off. So Z is re-probed instead.
; The front-left mesh point (probe X30 Y30, nozzle about X55 Y53) must be clear of the print.
; Do NOT call homeall.g / homez.g: they probe at the bed centre, where the print is.
; Afterwards resurrect.g lifts to Z+2, travels to the saved XY, descends to Z and resumes.
M116 ; wait for temperatures first: a hot nozzle releases from the print if it was left touching it
G91 ; relative positioning
G1 H2 Z5 F600 ; lower the bed 5 mm so the nozzle clears the print while homing (works unhomed)
G90 ; absolute positioning
M98 P"homex.g" ; home X (its own +5/-5 Z moves cancel out)
M98 P"homey.g" ; home Y
G1 X{move.compensation.probeGrid.mins[0] - sensors.probes[0].offsets[0]} Y{move.compensation.probeGrid.mins[1] - sensors.probes[0].offsets[1]} F6000 ; probe over the front-left mesh point
G30 ; probe: Z is now known
M83 ; relative extrusion
G1 E4 F1800 ; undo most of the 5 mm retraction the M911 script did
