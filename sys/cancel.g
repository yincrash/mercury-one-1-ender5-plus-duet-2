; cancel.g
; called when a print is cancelled after being paused (M0 while paused)
; pause.g has already parked the head at X0 Y0 with the bed 5 mm lower; here we just shut down.
M104 S0 ; hotend off
M140 S0 ; bed off
M106 S0 ; part fan off
if move.axes[2].homed
  G91 ; relative moves
  G1 Z10 F300 ; drop the bed 10 mm clear of the print
  G90 ; absolute moves
M84 ; motors off
