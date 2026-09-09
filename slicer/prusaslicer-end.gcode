; PrusaSlicer end G-code for MercuryOne (Duet 2 Ethernet, RRF 3.6)
M104 S0 ; hotend off
M140 S0 ; bed off
M83
G1 E-3 F1800 ; retract a little to limit ooze
G91 ; relative moves
G1 Z10 F300 ; drop the bed 10 mm (note: M208 Z max is unverified, keep prints under ~300 mm tall for now)
G90 ; absolute moves
G1 X5 Y325 F6000 ; park the head at the back-left, out of the way
M106 S0 ; part fan off
M84 ; motors off
