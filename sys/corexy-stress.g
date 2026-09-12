; corexy-stress.g: find the speed at which an A/B motor loses steps on 45-degree moves.
; On CoreXY a pure X+Y diagonal is driven by motor A alone (drive 0) and an X-Y diagonal by
; motor B alone (drive 1), each at 1.41x the commanded speed. This homes XY, runs N diagonal
; passes for each motor at speed S (mm/s) and acceleration A (mm/s^2), then re-finds each
; endstop with an H4 move and reports the position it was found at. The homing macros set
; X375 Y345 at the endstops, so any difference from those numbers is lost steps.
;   M98 P"corexy-stress.g" S250 A5000 N10
; Bed must be at least 20 mm below the nozzle and empty. Restores M204 5000/5000 and re-homes.
var speed = exists(param.S) ? param.S : 250
var accel = exists(param.A) ? param.A : 5000
var n = exists(param.N) ? param.N : 10
var feed = var.speed * 60
if !move.axes[0].homed || !move.axes[1].homed
  G28 X Y
M400
M204 P{var.accel} T{var.accel}
G90
echo "CoreXY stress: " ^ var.speed ^ " mm/s vector (motor " ^ var.speed * 1.414 ^ " mm/s), " ^ var.accel ^ " mm/s2, " ^ var.n ^ " passes per motor"
; motor A: X+Y diagonal, X40 Y40 <-> X300 Y300
G1 X40 Y40 F9000
M400
while iterations < var.n
  G1 X300 Y300 F{var.feed}
  G1 X40 Y40 F{var.feed}
M400
; motor B: X-Y diagonal, X40 Y300 <-> X300 Y40
G1 X40 Y300 F9000
M400
while iterations < var.n
  G1 X300 Y40 F{var.feed}
  G1 X40 Y300 F{var.feed}
M400
; re-find the endstops without resetting position. The head ends up past M208 max at each
; endstop, so suspend the soft limits like the homing macros do.
M564 S0
G1 X340 Y40 F9000
M400
G1 H4 X400 F600
M400
echo "X endstop found at X" ^ move.axes[0].machinePosition ^ " (expected 375.0)"
G1 X340 Y320 F9000
M400
G1 H4 Y400 F600
M400
echo "Y endstop found at Y" ^ move.axes[1].machinePosition ^ " (expected 345.0)"
M564 S1
M204 P5000 T5000
G28 X Y
