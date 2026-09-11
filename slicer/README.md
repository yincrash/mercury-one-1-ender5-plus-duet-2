# PrusaSlicer profile for the MercuryOne

`prusaslicer-mercury-one.ini` is a PrusaSlicer config bundle: File > Import > Import Config Bundle.
It brings in three presets and needs no vendor bundle installed (everything is resolved, nothing
inherits). It contains no network details; add your Duet afterwards under Printer Settings >
Physical Printer (host type Duet, no API key on a password-less Duet).

| Preset | Name | Notes |
|---|---|---|
| Printer | `Mercury One.1 (Plus) - 0.4mm Nozzle (High Flow)` | RepRapFirmware flavor, bed 365 x 332 origin 0,0, max height 400 (Z travel verified 2026-09-11), relative E, PNG thumbnails for DWC |
| Print | `0.20mm Standard @MercuryOne` | Voron V2 HF0.4 "Standard" profile resized to this machine's `config.g` limits |
| Filament | `Overture PETG @MercuryOne` | 245 C nozzle, 80 C bed, fan 30-50 %, no fan on layer 1, 12 mm3/s max volumetric (conservative) |

The print and filament presets are tied to the printer through the `PRINTER_MODEL_MERCURY_ONE`
keyword in Printer Settings > Notes. Keep it if you copy the printer preset.

## Where the numbers come from

- Printer: started from PrusaSlicer's `VORON V2 350mm - 0.4mm Nozzle (High Flow)` (closest CoreXY /
  direct-drive match), then flavor, bed, height, notes and machine limits changed. Retraction 0.8 mm
  at 35 mm/s (Sherpa Mini direct drive; 0.8-1.2 is the range to tune within).
- Machine limits mirror `sys/config.g` (M203 / M201 / M566) and are used for time estimates only.
  As of 2026-09-10: 250 mm/s, 5000 mm/s^2, 8 mm/s jerk in XY, Honey Badger motors at 1600 mA.
  Input shaping was measured (accelerometer + Klipper ringing tower at 5000 mm/s^2): no ringing
  worth shaping, `M593` stays off.
- Print speeds sit under those limits: perimeters 120 / external 80 / infill 200 / travel 250 mm/s.
  Accelerations (2026-09-10): outer walls 4000, perimeters/infill/default/travel 5000, first layer
  800. Raise them together with `config.g`, not ahead of it.
- Start / end G-code: `prusaslicer-start.gcode` and `prusaslicer-end.gcode` are the readable source;
  the bundle embeds the same text. Start G-code waits for the bed, THEN homes (Z0 must be set on a hot bed), loads the saved mesh
  (`G29 S1`), waits for the hotend, and purges along the front edge.

## Regenerating the bundle

Edit in PrusaSlicer, then File > Export > Export Config Bundle and replace the file. Delete the
`[physical_printer:...]` section and any `print_host` / `printhost_*` values before committing.

The live profiles are on the MacBook Pro (`~/Library/Application Support/PrusaSlicer/`, see
CLAUDE.md); edit them only with PrusaSlicer closed. The bundle's accelerations, start/end G-code, height and machine limits were synced from the live
profiles on 2026-09-11; re-export from PrusaSlicer after any other changes.
