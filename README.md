# Zero G Mercury One.1 on a Duet 2 — RepRapFirmware 3.6 configuration

A complete, running RepRapFirmware 3.6 configuration for a [Zero G Mercury One.1](https://zerog.one)
CoreXY conversion of a Creality Ender 5 Plus, driven by a Duet 2 Ethernet (a Duet 2 WiFi is the
same board with a different network module; only the `M552` line differs).

It is meant for someone building the same conversion who wants a known-good starting point and
a clear list of what to copy and what to measure on their own machine.

## The machine this config was built on

| Part | What is fitted here |
|---|---|
| Frame / motion | Mercury One.1 kit on an Ender 5 Plus (usable bed 365 x 332 mm, Z 400 mm), 20T GT2 pulleys, 1.8° XY motors |
| XY motors | Fabreeko Honey Badger 42HS48-25044A (kit motors, 2.5 A rated) at 1600 mA |
| Z | Two stock Ender 5 Plus 42-34 motors wired in series on one driver, T8x4 leadscrews (800 steps/mm) |
| Toolhead | Rapido 2 hotend (Semitec 104NT-4 thermistor), Sherpa Mini clone extruder (1.0 A pancake motor), BLTouch |
| Bed | Stock Ender 5 Plus heated bed and thermistor, four M4 levelling screws, glass clipped at the rear corners |
| Endstops | Microswitches at X max (right) and Y max (rear); the BLTouch is the Z endstop |
| Fans | Hotend fan on `fan0` (thermostatic, 45 °C), part cooling on `fan2` |
| Filament sensor | Simple switch on `e0stop` |
| Board / firmware | Duet 2 Ethernet, RepRapFirmware 3.6.0, Duet Web Control 3.6, 24 V PSU |

## Layout

- `sys/` is the printer's `/sys` folder: `config.g`, homing and probe macros, `bed.g` (four-screw
  levelling assistant), `pause.g` / `resume.g`, power-loss `resurrect-prologue.g`, and
  `config-override.g` (the tuned heater models written by `M500`).
- `FIRST-RUN.md` is the commissioning checklist: how to bring the machine up one subsystem at a time.
- `CHANGELOG.md` is the dated log of what was measured and why each number is what it is.
- `slicer/` has a PrusaSlicer config bundle (printer, print and filament presets) and the start/end G-code.
- `scripts/` has `duet.sh` (push/pull/G-code over the Duet HTTP API) and small tools for temperature
  towers, pressure-advance towers, a ringing test print and accelerometer analysis.
- `measurements/` holds the accelerometer captures behind the input-shaping decision.
- `reference/ender5plus-cartesian-2020/` is the Cartesian Ender 5 Plus config this replaced, for comparison.

## What you can copy as-is

If your hardware matches the table above these need no changes:

- Kinematics, driver mapping, microstepping and XY / Z steps per mm (`M669`, `M584`, `M350`, `M92 X Y Z`).
- The homing macros. The endstops sit beyond the usable bed area, so the macros home at full travel plus
  a margin and then `G92` the true position, with `M564 S0` around it so RRF accepts a position past `M208`.
- The BLTouch setup: `M558 ... R0.5`, `deployprobe0.g` with its 500 ms dwell, `retractprobe0.g`.
  These dwells are what stops the pin being driven into the bed. Keep them.
- The thermistor definitions and the heater fault monitors (`M308`, `M143`).
- Fan wiring and the thermostatic hotend fan.
- Motor idle current reduction, the CoreXY jerk policy (`M566 ... P1`) and the extruder limits.
- `bed.g` structure (probe each screw, `S4` on the last point, so `G32` reports how far to turn each knob).
- Power-loss recovery (`M911`) and `resurrect-prologue.g`. Tested by cutting the mains mid-print: the
  prologue homes X and Y cold with the bed dropped clear of the print, parks at the front-left
  corner, heats there so nothing oozes onto the print, re-probes Z with the BLTouch at the
  front-left mesh point, and lays a short purge line before resuming. It does not depend on the
  3 mm emergency lift having finished before the PSU died. Keep the front-left corner of the bed
  (about 70 x 70 mm) clear of prints you want to be able to resume.
- The slicer bundle, apart from the print temperatures and pressure advance, which are per filament.

## What you must measure or tune on your own machine

Work through `FIRST-RUN.md`; it covers each of these in order. In `config.g`:

| Setting | Why it is machine-specific |
|---|---|
| `M569 S` for every driver | Motor wiring. Verify direction before homing. |
| `M208` limits and the `G92 X375 Y345` values in `homeall.g` / `homex.g` / `homey.g` | Where your endstops actually sit relative to the bed. |
| `G31 X Y Z` | Probe offset and trigger height depend on your BLTouch mount and nozzle. |
| `M671` and the four `G30 P` points in `bed.g` | Bed screw positions, measured with the probe over each screw. Keep the order the same in both places. |
| `M557` | Mesh grid; every point plus the `G31` offset must land on the bed. |
| `M92 E` | Extruder steps. Clone gearing varies; this one measured 585, not the nominal 720. |
| `M906` | Motor currents. These are for the motors listed above; use 60 to 85 % of your motor's rating. |
| `M307` (via `M303` then `M500`) | Heater models. Re-tune with your own hotend, bed and fans. |
| `M203`, `M201` | Speeds and accelerations. 250 mm/s and 5000 mm/s² were verified here with a ringing tower and an accelerometer. Start lower if your motors or currents differ. |
| `M591` | Filament sensor. This config enables a switch on `e0stop`. If you have no sensor, remove or comment out the `M591` line, or every print will pause immediately. |
| `M593` | Input shaping is off because measurements showed no ringing worth shaping at these settings. Measure your own frame before enabling it. |

Pressure advance is not in `config.g`. It is set per filament in the slicer's filament start G-code
(`M572 D0 S0.12` for the Overture PETG preset) and reset to 0 in the printer end G-code.

## Deploying

Upload `sys/` through Duet Web Control, or use the helper:

```bash
scripts/duet.sh push          # upload all of sys/ with CRC and read-back check
scripts/duet.sh pull          # download the printer's /sys into sys/
scripts/duet.sh gcode 'M115'  # send a command and print the reply
```

The script reads the Duet address from `DUET_HOST` or a one-line `.duet-host` file in the repo root.
After changing `config.g` send `M999` (reboot) or `M98 P"config.g"`. Delete any old `config-override.g`
on the card before the first boot, otherwise `M501` loads stale heater models.

## Things that will bite you

- `G30 S-1` leaves the bed at the trigger point. Move up (`G1 Z10`) before probing again, or the pin
  deploys against the bed, the BLTouch faults, and the bed can crash into the toolhead.
- Re-sending `M558 ... P9` at runtime recreates the probe and wipes the `G31` values. Send `G31` again.
- Never fire probes back to back from a script. Wait for idle, then a couple of seconds.
- Home Z on a hot bed. A cold home followed by a hot print gave a failed first layer here; the start
  G-code waits for the bed before `G28`.
- Always `G28` between `G32` screw adjustments and `G29`, otherwise the mesh carries a Z offset.
- The mesh is not loaded at boot. The start G-code runs `G29 S1` after homing.
- Route the toolhead umbilical clear of the right-hand end of the gantry; it can get pinched at the X endstop.
