# Commissioning a Mercury One.1 on a Duet 2 with this config

Bring the machine up one subsystem at a time. Each step ends with something you can see or measure.
The numbers you find replace the ones in `config.g`; the dated results for the original machine are
in `CHANGELOG.md`. Keep a hand near the power switch for every first move.

## 0. Before uploading

1. If the card has an old `sys/config-override.g` from a previous config, delete it before the
   first boot. `M501` would otherwise load stale heater models. A fresh one is written by `M500`
   after tuning (step 4).
2. Upload `sys/` through DWC (System page) or `scripts/duet.sh push`. If you are coming from an
   older firmware, DWC will offer to install 3.6; otherwise upload the firmware files to `/firmware`
   and run `M997 S0`. Hard-refresh DWC afterwards. `M115` must report 3.6.
3. Watch the console on boot. Any red `Error:` line from `config.g` must be fixed first. `M122`
   should show no driver errors.
4. If you have no filament sensor, remove or comment out the `M591` line now, or every print will
   pause immediately.

## 1. Motors and endstops (no homing yet, nozzle not fitted)

Allow unhomed moves for testing:

    M564 H0 S0

- `G91 G1 X10 F1500`: the toolhead moves +X (right) only. `G1 Y10`: +Y (back) only.
  CoreXY rules if it is wrong:
  - both axes reversed: flip `S` on both driver 0 and 1 (`M569 P0` / `P1`)
  - an X command moves Y (or vice versa): flip `S` on one motor only, retest
  - movement is diagonal: one motor is not moving; check wiring
- `G1 Z5`: the bed moves DOWN (away from the gantry). If not, flip `M569 P2`.
- `M119` while pressing each endstop by hand: `xstop` and `ystop` go from "not stopped" to "at max stop".
- BLTouch: `M401` deploys the pin, `M402` retracts. Push the pin up by hand while watching the Z-probe
  value in DWC: it should jump from 0 to 1000.
- If the BLTouch flashes red on boot, check the servo wire is on `exp.heater3` (pin 8 of the expansion
  header) and the black/white pair on `zprobe.in` / GND.

Put it back afterwards: `M564 H1 S1` (or reboot).

## 2. Home X and Y, then measure the real limits

1. `G28 X`, then `G28 Y`.
2. Jog to X0 Y0. Note where the nozzle position (empty heater block for now) sits relative to the
   bed's front-left corner. Jog until the block is over the corner you want as the origin (clear of
   the bed clips) and read the position. Do the same at the far corners for the maxima.
3. The endstops sit beyond the usable area, so the homing macros end with `G92 X<n> Y<n>` to set
   the true position. Set those values to where your endstops really are (here X375 Y345 for a
   365 x 332 usable area) and set `M208` to the usable area.
4. Homing Z probes at the centre of the `M557` grid, so set `M557` before the first `G28 Z`
   (step 6 refines it once the probe offset is known).

## 3. Home Z with the probe

1. `G28 Z`. The head goes to the grid centre and probes. With no nozzle this is safe.
2. Repeatability: `G30 S-1` five or six times, with at least 2 s between them and a `G1 Z10`
   before each one. Reported heights should agree within 0.02 mm. If not, check that the BLTouch
   mount is rigid and the pin is clean.
   - `G30 S-1` leaves the bed AT the trigger point (no lift). Always `G1 Z10` before the next
     probe, or the pin deploys against the bed and the BLTouch faults. Done back to back with no
     dwell, this crashed the bed into the toolhead on the original machine; `deployprobe0.g` has
     `G4 P500` and `M558` has `R0.5` for that reason. Keep them.
   - Re-sending `M558 ... P9` at runtime recreates the probe and wipes the `G31` offsets and
     trigger height. Re-send `G31` afterwards, or reboot.

## 4. Heaters, thermistors, fans (still no nozzle)

1. DWC should show room temperature on both sensors. A reading of −273 or 2000 is a wiring or
   thermistor-type problem (stock bed B4092; Semitec 104NT-4 is B4267 C7.06e-8).
2. `M106 P1 S255`: the part cooling fan spins. `M106 P1 S0`.
3. Heat the hotend to 60 °C: the hotend fan (`fan0`) must come on by 45 °C.
4. Tune both heaters and save:

        M303 H0 S100
        M303 T0 S250
        M500

   `M303 T0` tunes with the tool's part fan, which matters for a Rapido.
5. Fit the nozzle. Heat to 250 °C and hot-tighten it.

## 5. Probe offsets (nozzle fitted)

1. X/Y offset: home, heat nothing, lower the nozzle until it just marks a piece of tape on the bed
   (or use a sharpie dot). Note the XY. Jog until the probe pin is over the mark, note the XY.
   `G31 X = probe X − nozzle X`, same for Y. Edit `config.g`.
2. Trigger height (Duet's standard method):

        G28
        G1 X175 Y175 Z10 F6000   ; centre of the bed (use your real centre)
        ; jog Z down in 0.1 then 0.05 steps until paper drags
        G92 Z0
        G1 Z5
        G30 S-1                  ; the console reports the trigger height

   Put the reported value in `G31 Z`. Repeat once to confirm.

## 6. Bed screws and mesh

1. Measure the XY of the four bed screws from the new origin with the probe pin over each screw
   (nozzle XY plus the `G31` offset). Update `M671` in `config.g` and the four `G30 P` lines in
   `bed.g`, keeping the same order in both: front-left, front-right, rear-right, rear-left.
   `M671 P` is the effective mm per knob turn; measure it by turning one knob a full turn and
   re-probing (0.55 here with M4 screws and the probe inboard of the screw).
2. Set `M557` so every grid point plus the `G31` offset lands on the bed and clear of the clips.
3. Bed at printing temperature, then `G32`. Adjust the screws by the reported turns. Repeat until
   the corrections are under about 0.05 mm.
4. `G28` again (levelling moved the bed under the Z reference), then `G29`. Look at the height map
   in DWC; a good result on this frame is under ±0.15 mm. The map is not loaded at boot; the slicer
   start G-code runs `G29 S1` after homing.

## 7. Extruder calibration

1. Heat to printing temperature. Mark the filament 120 mm above the extruder inlet.
2. `M83`, `G1 E100 F100`. Measure what is left above the inlet.
3. New steps = current `M92 E` × 100 / (120 − remaining). Edit `M92 E` in `config.g` (`M500` does
   not save `M92`). Repeat until 100 commanded gives 100 delivered.
4. If the extruder skips against the hotend, raise `M906 E` toward the motor's rating and check
   the idler tension before blaming steps.
5. Filament sensor: `M591 D0` shows the state. Pull the filament and check that it changes.

## 8. Before the first print

- Power-loss recovery: `M911` in `config.g` drops the XY current, lowers the bed 3 mm and retracts
  when VIN falls below 19.8 V. On power return, `M916` resumes the print (it must have been started
  from the SD card, which a DWC upload is). `resurrect-prologue.g` re-probes Z at the front-left
  mesh point, so that corner must be clear of the print. Test it once by switching the mains off a
  few layers into a small print; the 3 mm lift may not visibly finish before the PSU dies, which is
  why the prologue probes instead of trusting the saved Z.
- Pressure advance: set it in the slicer filament start G-code (`M572 D0 S<value>`), not in
  `config.g`. 0.12 was measured for Overture PETG with this Rapido 2 / Sherpa Mini; tune with
  `scripts/gen_pa_tower.py` or `scripts/pa_tower.py`.
- Speeds: `M203` / `M201` in `config.g` are what this machine verified. Start a print profile below
  them and raise the slicer accelerations together with `config.g`, not ahead of it.
- Input shaping (`M593`): measure before enabling. `scripts/gen_ringing_test.py` prints a ringing
  test; `scripts/msp_accel_log.py` and `scripts/ringing_fft.py` turn a Betaflight flight controller
  into an accelerometer. On this frame nothing was worth shaping at 250 mm/s and 5000 mm/s².
