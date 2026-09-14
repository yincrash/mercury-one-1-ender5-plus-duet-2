; PrusaSlicer start G-code for MercuryOne (Duet 2 Ethernet, RRF 3.6)
; Printer Settings > Custom G-code > Start G-code. G-code flavor: RepRapFirmware.
; Bed shape 365 x 332, origin 0,0. Use relative E distances.
M140 S[first_layer_bed_temperature] ; start heating the bed
M104 S150 ; warm the hotend without oozing while we home and probe
M190 S[first_layer_bed_temperature] ; wait for the bed BEFORE homing: Z0 must be set on a hot bed (2026-09-10: cold home + hot print = failed first layer)
G28 ; home all (XY to endstops, Z with the BLTouch at the mesh centre)
G29 S1 ; load the saved height map (heightmap.csv) and enable mesh compensation
G1 X5 Y3 Z10 F6000 ; move to the purge line start (front-left, inside the usable area)
M109 S[first_layer_temperature] ; wait for hotend
M83 ; relative extrusion
G92 E0
G1 Z0.3 F300
G1 X120 Y3 E12 F900 ; purge line along the front edge
G1 X120 Y3.6 F3000 ; small sideways step to break the string
G1 X30 Y3.6 E4 F900 ; second, thinner pass back
G1 X20 Y8 F3000 ; sideways at bed height to break the string against the glass (2026-09-11: lifting straight up dragged a string onto the skirt); no manual retract here, PrusaSlicer would not know and would under-prime the first line
G92 E0
G1 Z2 F300 ; lift before the travel to the first object
