# PrusaSlicer profile for the MercuryOne

`prusaslicer-mercury-one.ini` is a PrusaSlicer config bundle: File > Import > Import Config Bundle.
It brings in three presets and needs no vendor bundle installed (everything is resolved, nothing
inherits). It contains no network details; add your Duet afterwards under Printer Settings >
Physical Printer (host type Duet, no API key on a password-less Duet).

| Preset | Name | Notes |
|---|---|---|
| Printer | `Mercury One.1 (Plus) - 0.4mm Nozzle (High Flow)` | RepRapFirmware flavor, bed 365 x 332 origin 0,0, max height 300, relative E, PNG thumbnails for DWC |
| Print | `0.20mm Standard @MercuryOne` | Voron V2 HF0.4 "Standard" profile resized to this machine's `config.g` limits |
| Filament | `Overture PETG @MercuryOne` | 245 C nozzle, 80 C bed, fan 30-50 %, no fan on layer 1, 12 mm3/s max volumetric (conservative) |

The print and filament presets are tied to the printer through the `PRINTER_MODEL_MERCURY_ONE`
keyword in Printer Settings > Notes. Keep it if you copy the printer preset.

## Where the numbers come from

- Printer: started from PrusaSlicer's `VORON V2 350mm - 0.4mm Nozzle (High Flow)` (closest CoreXY /
  direct-drive match), then flavor, bed, height, notes and machine limits changed. Retraction 0.8 mm
  at 35 mm/s (Sherpa Mini direct drive; 0.8-1.2 is the range to tune within).
- Machine limits mirror `sys/config.g` (M203 / M201 / M566) and are used for time estimates only.
  As of 2026-09-09: 250 mm/s, 3000 mm/s^2, 8 mm/s jerk in XY, untuned (no input shaping, motors at
  800 mA). Published Mercury One.1 builds on stock-class motors run 300 mm/s and 3000-5000 mm/s^2
  before shaping; 5000-6000 mm/s^2 after M593 is tuned; beyond that needs 2 A-class motors.
- Print speeds sit under those limits: perimeters 120 / external 80 / infill 200 / travel 250 mm/s,
  print acceleration 2500, travel 3000. Raise them together with `config.g`, not ahead of it.
- Start / end G-code: `prusaslicer-start.gcode` and `prusaslicer-end.gcode` are the readable source;
  the bundle embeds the same text. Start G-code homes, loads the saved mesh (`G29 S1`), waits for
  temperatures, and purges along the front edge.

## Regenerating the bundle

Edit in PrusaSlicer, then File > Export > Export Config Bundle and replace the file. Delete the
`[physical_printer:...]` section and any `print_host` / `printhost_*` values before committing.
