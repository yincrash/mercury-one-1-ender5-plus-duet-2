# PrusaSlicer profile for the MercuryOne

`prusaslicer-mercury-one.ini` is a PrusaSlicer config bundle: File > Import > Import Config Bundle.
It brings in three presets and needs no vendor bundle installed (everything is resolved, nothing
inherits). It contains no network details; add your Duet afterwards under Printer Settings >
Physical Printer (host type Duet, no API key on a password-less Duet).

| Preset | Name | Notes |
|---|---|---|
| Printer | `Mercury One.1 (Plus) - 0.4mm Nozzle (High Flow)` | RepRapFirmware flavor, bed 365 x 332 origin 0,0, max height 400 (Z travel verified 2026-09-11), relative E, PNG thumbnails for DWC |
| Print | `0.20mm Standard @MercuryOne` | Voron V2 HF0.4 "Standard" profile resized to this machine's `config.g` limits |
| Filament | `Overture PETG @MercuryOne` | 245 C nozzle, 80 C bed, fan 30-50 %, no fan on layer 1, 14 mm3/s max volumetric (free-air flow test 2026-09-11: clean to 15, 94 % at 20, 84 % at 25, skips at 30), pressure advance `M572 D0 S0.12` in the filament start G-code |

The print and filament presets are tied to the printer through the `PRINTER_MODEL_MERCURY_ONE`
keyword in Printer Settings > Notes. Keep it if you copy the printer preset.

## Where the numbers come from

- Printer: started from PrusaSlicer's `VORON V2 350mm - 0.4mm Nozzle (High Flow)` (closest CoreXY /
  direct-drive match), then flavor, bed, height, notes and machine limits changed. Retraction 0.8 mm
  at 45 mm/s with wipe on and a 0.5 mm Z-hop from layer 1 (2026-09-11: first-layer blobs and ooze on
  PETG; was 35 mm/s, no wipe, no hop below Z0.25). The Rapido HF holds more melt than a standard
  hotend; do not go past about 1.5 mm.
- Avoid crossing perimeters is off. It was tried on 2026-09-11 so PETG ooze would land on plastic
  rather than bare glass, but its travels ride along fresh perimeters and a 0.2 mm hop let the nozzle
  catch curled corners and skip belt teeth on the first layer; the 0.5 mm hop stays.
- Machine limits mirror `sys/config.g` (M203 / M201 / M566) and are used for time estimates only.
  As of 2026-09-10: 250 mm/s, 5000 mm/s^2, 8 mm/s jerk in XY, Honey Badger motors at 1600 mA.
  Input shaping was measured (accelerometer + Klipper ringing tower at 5000 mm/s^2): no ringing
  worth shaping, `M593` stays off.
- Print speeds sit under those limits: perimeters 120 / external 80 / infill 200 / travel 200 mm/s.
  Travel was 250 until 2026-09-11: a long 45-degree travel puts one CoreXY motor at 1.41x the axis
  speed (354 mm/s at 250) and that skipped on the first layer of the IEC skirt; 200 keeps the worst
  case at 283 mm/s. `M203` stays at 250 as the ceiling.
  Accelerations: outer walls 4000, perimeters/infill/default 5000, travel 3000, first layer 800.
  Travel came down from 5000 on 2026-09-11 after hot XY motors stalled on 200 mm/s travels (a
  travel is the one move that puts a single CoreXY motor at 1.41x the speed and acceleration,
  from a dead stop). Raise them together with `config.g`, not ahead of it.
- Infill is cubic. Honeycomb at 40 % produced about a thousand sub-millimetre segments per layer,
  which keeps both motors in full-acceleration reversals for the whole infill and leaves blobs at
  the hex corners for travels to clip; use it only for parts that truly need its Z compression.
- Start / end G-code: `prusaslicer-start.gcode` and `prusaslicer-end.gcode` are the readable source;
  the bundle embeds the same text. Start G-code waits for the bed, THEN homes (Z0 must be set on a
  hot bed), loads the saved mesh (`G29 S1`), waits for the hotend, and purges along the front edge.
  End G-code resets pressure advance (`M572 D0 S0`) because RRF keeps the last value across prints.
- Pressure advance lives in each filament preset's start G-code, not in `config.g`, so a filament
  without a measured value prints with PA 0 rather than inheriting another filament's number.

## Regenerating the bundle

Edit in PrusaSlicer, then File > Export > Export Config Bundle and replace the file. Delete the
`[physical_printer:...]` section and any `print_host` / `printhost_*` values before committing.

The bundle matches the live PrusaSlicer profiles as of 2026-09-11 (accelerations, start/end G-code,
height, machine limits, pressure advance, retraction/wipe, first-layer infill speed and temperature).
Re-export after any other change.
