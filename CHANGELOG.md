# Changelog and measurement log

Dated record of what was measured on this machine and why each number in `config.g` is what it is.
Newest at the bottom.

## 2026-09-08 — first boot and probe setup

- Config generated with the RRF Configuration Tool 3.6.15, firmware 3.6.0 installed, DWC 3.6.
- Motors, endstops and BLTouch verified. XY limits measured: usable area 0–365 x 0–332 with the
  endstops 10 mm (X) and 13 mm (Y) beyond it; homing macros set the true position with `G92`.
- Probe repeatability: five `G30 S-1` within 0.004 mm once `deployprobe0.g` got a 500 ms dwell
  and `M558` got `R0.5`. Before that, back-to-back probes with no dwell drove the pin into the bed
  and skipped the Z motors. `G30 S-1` leaves the bed at the trigger point; lift before the next probe.
- Bed PID tuned (`M303 H0 S100`): R0.168 K0.150 D5.67, predicted max rise 108 °C. Saved with `M500`.
- Hotend PID tuned bare (`M303 T0 S250`): R7.845 K0.743:0.444 D3.56. Nozzle fitted and hot-tightened at 250 °C.
- Hotend fan verified thermostatic at 45 °C. `G28` takes 26 s.

## 2026-09-09 — offsets, levelling, extruder

- Probe offset measured with a sharpie dot: `G31 X-25.1 Y-23.0`. Trigger height by the paper test: `Z1.485`.
- Bed screw positions measured with the probe pin: `M671 X32.9:332.9:332.9:32.9 Y35.5:37.5:297.5:295.5`,
  order front-left, front-right, rear-right, rear-left (same order in `bed.g`). Knob clockwise seen
  from below lowers the corner; effective travel 0.55 mm per turn at the probe point (`P0.55`).
- Levelled cold to within 0.055 mm in five passes. First mesh had a −0.32 mm mean because Z was not
  re-homed after levelling. Rule: `G28` between `G32` and `G29`. Second mesh: 0.006 to 0.122 mm,
  deviation 0.034 mm.
- Extruder: `M92 E585` (720 delivered 61.5 mm per 50 commanded; clone gearing is not 50:10). `M906 E800`
  after 600 mA skipped against the Rapido at 220 °C. Idler tension matters.
- Hot pass at bed 80 °C / hotend 150 °C: all four screws within 0.04 mm, hot mesh 0.028 to 0.127 mm,
  deviation 0.029 mm. Saved as the working `heightmap.csv`.
- Incident: the first hot `G28` pinched the toolhead umbilical against the X endstop. Cable re-routed,
  toolhead electronics checked OK.
- First print (Voron design cube, PETG 245/80) succeeded. Temperature tower 255 to 225 printed.

## 2026-09-10 — temperature, pressure advance, motion limits

- Overture PETG: 245 °C chosen from the tower.
- Pressure advance 0.12 from two towers (0.12 sharpest, rounding from 0.16 at 3000 mm/s², 8 mm/s jerk).
- Honey Badger XY motors raised to 1600 mA (64 % of the 2.5 A rating).
- Input shaping measured with a BetaFPV F411 flight controller zip-tied to the toolhead (MSP polling
  at about 290 Hz): at 250 mm/s and 6000 mm/s² only a weak 28 to 30 Hz peak (about 0.004 g); MZV at
  29 Hz made no measurable difference. Klipper ringing tower at 100 mm/s, 5000 mm/s², no shaper:
  no ringing on the Y faces, barely perceptible on X. Shaper left off, `M201` set to 5000.
- Start G-code changed to wait for the bed before `G28`; a cold home followed by a hot print failed
  its first layer.

## 2026-09-11 — Z travel, public clean-up

- Z max 400 verified by jogging; clear of the electronics enclosure. Slicer max height set to 400.
- Pressure advance moved out of `config.g` into the slicer filament preset (`M572 D0 S0.12` in the
  Overture PETG start G-code) and reset to 0 in the printer end G-code.
- Stale notes removed (mesh-grid TODO, unverified Z max in the end G-code, ringing macro restoring
  3000 instead of 5000). `configtool.json`, DWC settings and test G-code dropped from the repo.
