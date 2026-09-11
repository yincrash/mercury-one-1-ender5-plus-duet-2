; stop.g
; called when M0 (Stop) is run, e.g. when a print is cancelled from DWC without pausing first
; The head is wherever the print stopped; the bed drops clear before the motors idle.
M104 S0 ; hotend off
M140 S0 ; bed off
M106 S0 ; part fan off
if move.axes[2].homed
  G91 ; relative moves
  G1 Z10 F300 ; drop the bed 10 mm clear of the print
  G90 ; absolute moves
M84 ; motors off
