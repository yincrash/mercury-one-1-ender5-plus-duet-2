# PrusaSlicer printer profile notes (MercuryOne)

- G-code flavor: RepRapFirmware
- Bed shape: 365 x 332 mm, origin 0,0 (front-left of the usable area, clear of the bed clips)
- Max print height: 300 mm for now (M208 Z max of 400 is not yet verified against the frame)
- Use relative E distances: yes
- Start / end G-code: see the two .gcode files here
- Extruder: 0.4 mm nozzle (Rapido 2), direct drive Sherpa Mini clone. Retraction 0.8-1.2 mm, 35 mm/s to start.
- Overture PETG: 240-250 C first layer 245 C, bed 80 C, part fan 30-50 %, no fan on layer 1.
