; ringing-excite.g: sharp moves to excite toolhead vibration for accelerometer measurement.
; Run with the FC accelerometer logging. X moves first (8 stops), 4 s gap, then Y moves.
; Needs XY homed. Bed must be at least 30 mm below the nozzle.
M400
M204 P6000 T6000 ; hard accel for the test
G90
G1 X100 Y166 F6000 ; start position
M400
G4 S2
; --- X excitation, 8 sharp stops ---
G1 X250 F15000
G4 S1.5
G1 X100 F15000
G4 S1.5
G1 X250 F15000
G4 S1.5
G1 X100 F15000
G4 S1.5
G1 X250 F15000
G4 S1.5
G1 X100 F15000
G4 S1.5
G1 X250 F15000
G4 S1.5
G1 X100 F15000
G4 S4
; --- Y excitation, 8 sharp stops ---
G1 X182 Y90 F6000
M400
G4 S2
G1 Y240 F15000
G4 S1.5
G1 Y90 F15000
G4 S1.5
G1 Y240 F15000
G4 S1.5
G1 Y90 F15000
G4 S1.5
G1 Y240 F15000
G4 S1.5
G1 Y90 F15000
G4 S1.5
G1 Y240 F15000
G4 S1.5
G1 Y90 F15000
G4 S2
M204 P5000 T5000 ; restore the M201 values from config.g
M400
