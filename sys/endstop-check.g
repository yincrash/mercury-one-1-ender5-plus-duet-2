; endstop-check.g: measure how far the firmware's idea of X and Y has drifted from reality.
; Creeps onto each endstop with H4 moves (stop on trigger, keep the current coordinates, do
; NOT reset them) and reports the position at the trigger. The homing macros set X375 Y345
; there, so the difference is the lost distance. Positive X or negative Y error here matches
; a print that shifted toward -X +Y (motor B, drive 1). Does not re-home; run G28 X Y after.
; Safe to run while paused or after a cancel: lifts nothing, so make sure the nozzle is clear
; of the print first (pause.g and stop.g both drop the bed).
M564 S0 ; the trigger points are past M208 max
G91
G1 H4 X400 F600
M400
echo "X endstop at X" ^ move.axes[0].machinePosition ^ ", homing sets 375.0, error " ^ move.axes[0].machinePosition - 375
G1 H4 Y400 F600
M400
echo "Y endstop at Y" ^ move.axes[1].machinePosition ^ ", homing sets 345.0, error " ^ move.axes[1].machinePosition - 345
G90
M564 S1
