# Mercury One.1 (Ender 5 Plus + Duet 2 Ethernet) — first-run plan

Config generated 2026-09-08 by RRF Configuration Tool 3.6.15, hand-edited afterwards.
Old Ender 5 Plus Cartesian config is in `reference/ender5plus-cartesian-2020/`.

Placeholders still in config.g (grep for `TODO`):
- `M208` axis limits (350/350/400 nominal)
- `G31 X-25 Y-25 Z0.7` probe offsets
- `M557` mesh grid
- `M671` bed screw coordinates (old E5+ values)
- `M92 E720` extruder steps

## Status (end of 2026-09-08 session)

Done: firmware 3.6.0 + config uploaded (step 0), motors/endstops/BLTouch verified (1),
XY limits measured and homing macros fixed with G92 (2), Z homed and probe repeatable
to 0.004 mm (3), part fan verified, bed PID tuned (R0.168 K0.150 D5.67, predicted max
rise 108 C) and saved with `M500` to config-override.g.
2026-09-08 morning: `G28` clean (26 s). Hotend PID tuned bare (R7.845 K0.743:0.444 D3.56,
predicted rise 573 C), both models now also in config.g. Hotend fan verified at 45 C.
Nozzle fitted and hot-tightened at 250 C. G31 Z0.7 is now INVALID (nozzle is the reference).

2026-09-09: probe offsets measured: `G31 X-25.1 Y-23.0 Z1.485`. Mesh grid and screw points
unchanged (still within reach). Z homing verified against paper.

2026-09-09: bed screws measured with the probe pin, M671 set. Knob sense: CLOCKWISE seen from
BELOW lowers the corner; effective travel 0.55 mm/turn at the probe point (M671 P0.55).
Levelled cold to within 0.055 mm in 5 passes. First G29 mesh (cold): range 0.12 mm, deviation
0.033 mm, but mean -0.32 because Z was not re-homed after levelling. Map cleared (G29 S2).
Rule: always `G28` (or at least `G28 Z`) between G32 adjustments and G29.

Next, in order:
1. Extruder calibration (section 7).
2. Hot re-level (G32) and hot mesh (G29) before the first print.
Open config TODOs: `G31 X/Y/Z`, `M557`, `M671` + bed.g points, `M92 E`, Z max in `M208`.

## 0. Before uploading

1. The SD card still has the old `sys/config-override.g` (2020 heater models, old G10 offsets).
   Delete it from the card before the first boot. `M501` would otherwise load stale
   heater models. A fresh one gets written by `M500` after tuning.
2. Upload the whole zip through DWC (System page, upload). DWC on 3.3 will offer to
   install the 3.6.0 firmware from `firmware/`. Accept. If the prompt does not appear,
   upload `Duet2CombinedFirmware.bin` and `Duet2_SDiap32_WiFiEth.bin` to `/firmware`
   and run `M997 S0`.
3. Reload DWC (hard refresh, it is a new DWC too). `M115` must say 3.6.0.
4. Watch the console on boot. Any red `Error:` lines from config.g must be fixed first.
   `M122` should show no driver errors.

## 1. Motors and endstops (no homing yet, nozzle not fitted)

Allow unhomed moves for testing:

    M564 H0 S0

- `G91 G1 X10 F1500`: toolhead moves +X (right) only. `G1 Y10`: moves +Y (back) only.
  CoreXY rules if it is wrong:
  - both axes reversed: flip `S` on both driver 0 and 1 (`M569 P0`/`P1`)
  - X command moves in Y (or vice versa): flip `S` on ONE motor, retest
  - movement is diagonal: one motor is not moving; check wiring
- `G1 Z5`: bed moves DOWN (away from the gantry). If not, flip `M569 P2`.
- `M119` while pressing each endstop by hand: xstop and ystop go from "not stopped"
  to "at max stop".
- BLTouch: `M401` deploys the pin, `M402` retracts. Push the pin up by hand while
  watching the Z-probe value in DWC: should jump from 0 to 1000.
- If the BLTouch flashes red on boot, check the servo wire is on exp.heater3 (pin 8 of
  the expansion header) and the black/white pair on zprobe.in/GND.

Put it back to normal afterwards: `M564 H1 S1` (or just reboot).

## 2. Home X and Y, then measure the real limits

1. `G28 X`, then `G28 Y`. Hand near the power switch the first time.
2. Jog to X0 Y0. Note where the nozzle position (empty heater block for now) sits relative
   to the bed's front-left corner. Jog until the block is over the bed's front-left corner
   and read the position: that gives the real minima. Same at the far corners for maxima.
3. Also find how far the probe reaches on each side: probe points must satisfy
   (nozzle position + G31 offset) inside the bed.
4. Update `M208`, then `M557` so every mesh point is within probe reach. Homing Z uses the
   centre of the M557 grid, so get this right before `G28 Z`.

## 3. Home Z with the probe

1. `G28 Z`. The head goes to the grid centre and probes. With no nozzle this is safe.
2. Repeatability: `G30 S-1` five or six times, **with at least 2 s between them**. Reported
   heights should agree within 0.02 mm. If not, check the BLTouch mount is rigid and the pin
   is clean.
   - 2026-09-08 lesson: back-to-back probes with no deploy dwell crashed the bed into the
     toolhead (pin not yet down, no trigger, Z motors skipped). deployprobe0.g now has
     `G4 P500` and M558 has `R0.5`. Keep them.
   - `G30 S-1` leaves the bed AT the trigger point (no lift). Always `G1 Z10` before the next
     probe, or the pin deploys against the bed and the BLTouch faults. This was the real cause
     of the crash. Result 2026-09-08: five probes within 0.004 mm.
   - Re-sending `M558 ... P9` at runtime recreates the probe and wipes the G31 offsets and
     trigger height. Re-send `G31` afterwards, or reboot.

## 4. Heaters, thermistors, fans (still no nozzle)

1. DWC should show room temperature on both sensors. A reading of -273 or 2000 is a
   wiring or thermistor-type problem (bed B4092, nozzle Semitec 104NT-4 B4267 C7.06e-8).
2. `M106 P1 S255`: part cooling fan spins. `M106 P1 S0`.
3. Heat the hotend to 60 C: the hotend fan (fan0) must come on by 45 C.
4. Tune both heaters and save:

        M303 H0 S100
        M303 T0 S250
        M500

   `M303 T0` tunes with the tool's part fan, which matters for a Rapido.
5. Fit the nozzle. Heat to 250 C and hot-tighten it.

## 5. Probe offsets (nozzle fitted)

1. X/Y offset: home, heat nothing, lower the nozzle until it just marks a piece of tape
   on the bed (or use a sharpie dot). Note the XY. Jog until the probe pin is over the
   mark, note the XY. `G31 X = probe X - nozzle X`, same for Y. Edit config.g.
2. Trigger height (Duet's standard method):

        G28
        G1 X175 Y175 Z10 F6000   ; centre of bed (adjust to your real centre)
        ; jog Z down in 0.1 then 0.05 steps until paper drags
        G92 Z0
        G1 Z5
        G30 S-1                  ; console reports the trigger height

   Put the reported value in `G31 Z`. Repeat once to confirm.

## 6. Bed screws and mesh

1. Measure the XY of the four bed screws from the new origin (nozzle over each screw).
   Update `M671` in config.g and the four `G30 P` lines in bed.g, keeping the order:
   rear-right, front-right, rear-left, front-left.
2. Bed at printing temperature, then `G32`. Adjust screws by the reported turns.
   Repeat until corrections are under ~0.05 mm.
3. `G29`, then look at the height map in DWC. Old E5+ map was +-0.8 mm; a good result
   on the new frame is under +-0.2 mm.

## 7. Extruder calibration

1. Heat to 220 C. Mark filament 120 mm above the extruder inlet.
2. `M83`, `G1 E100 F100`. Measure what is left above the inlet.
3. New steps = 720 * 100 / (120 - remaining). Edit `M92 E` in config.g (M500 does not
   save M92).
4. Filament sensor: `M591 D0` shows the state. Pull the filament, check it changes.

## 8. Before the first print

- `M913 X0 Y0` inside `M911` drops XY current on power loss; test by pulling the mains
  plug mid-move if you want to confirm it lifts Z. `M916` resumes after power returns
  (needs the print to have been from SD/DWC upload).
- Pressure advance: `M572 D0 S0.04` is a sane start for a Sherpa Mini + Rapido; tune later.
- Input shaping (`M593`) once the mechanics are settled; Duet 2 can use a LIS3DH/ADXL345
  on the SPI header, or do a ring tower.
