# Mercury One.1 (Ender 5 Plus frame) on Duet 2 Ethernet — project brief

RepRapFirmware config for a Zero G Mercury One.1 CoreXY conversion of an Ender 5 Plus,
driven by a Duet 2 Ethernet (RRF 3.6.0, DWC 3.6). This repo is the source of truth for
`sys/`; the SD card is the deploy target. `FIRST-RUN.md` is the commissioning checklist
and running status. `reference/` holds the 2020 Cartesian config this replaced.

## Hardware
- Toolhead: Rapido 2 hotend (Semitec 104NT-4 thermistor, B4267 C7.06e-8), Sherpa Mini
  clone extruder (1.0 A 1.8° pancake motor, 50:10), BLTouch on `exp.heater3` / `zprobe.in`.
- Fans: hotend fan on `fan0` (thermostatic 45 °C), part cooling on `fan2`, `fan1` unused.
- XY motors: Fabreeko Honey Badger `42HS48-25044A` (kit motors): NEMA 17, 48 mm, 1.8°, 2.5 A rated,
  ~1.25 Ω / 1.8 mH / 54 N·cm / 68 g·cm² (generic 42HS48-2504 family figures). 24 V PSU. Back-EMF
  math clears 300 mm/s with room to spare; acceleration is limited by current, not by the motors.
- Bed: stock Ender 5 Plus (B4092), two stock Creality `42-34` Z motors (0.8 A rated, 34 mm) wired in series on one driver,
  T8x4 leadscrews (800 steps/mm).
- Endstops: X max (right), Y max (rear). Bed clips: usable area 0–365 × 0–332, endstops sit
  10 mm / 13 mm beyond it (homing macros `G92` the true position with `M564 S0` around it).
- Network: `http://10.0.1.22`, hostname `MercuryOne`, no password (default `reprap`).

## Workflow
- The user (and other sessions) edit `sys/config.g` and this file directly. Run `git diff`
  before every commit and commit only what you changed; never `git add -A` blind
  (2026-09-10: motor-current and speed edits got swept into unrelated commits unread).
- Talk to the printer with `scripts/duet.sh` (pull / push / gcode / model). Read-only checks
  are fine to run unattended; anything that moves or heats is done with the user at the
  machine, one step at a time, and they confirm what they saw.
- After editing `sys/*`, `scripts/duet.sh push` then either `M999` or `M98 P"config.g"`.
- `M500` writes `sys/config-override.g` on the card (heater models). Pull before committing.

## Hard-won rules (2026-09-08)
- `G30 S-1` leaves the bed AT the trigger point. Always `G1 Z10` before the next probe,
  otherwise the pin deploys against the bed, the BLTouch faults, and the bed can crash.
- Re-sending `M558 ... P9` at runtime recreates the probe and wipes `G31`. Re-send `G31`.
- Never fire probes back-to-back from a script; wait for idle, then a couple of seconds.
- `deployprobe0.g` has `G4 P500`, `M558` has `R0.5`. Keep them.
- The Duet HTTP session times out in 8 s and rapid connects exhaust sockets: reconnect
  before each request, sleep between bulk transfers, use curl (urllib's encoding is rejected).
