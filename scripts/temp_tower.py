#!/usr/bin/env python3
"""Turn a normally sliced PrusaSlicer G-code into a temperature tower.

Inserts `M104 S<temp>` at the first layer of each band and strips any other
M104/M109 that PrusaSlicer emitted after the start G-code (it usually re-sends
the profile temperature at layer 2). Band boundaries come from the `;Z:` markers
PrusaSlicer writes at every layer change.

    scripts/temp_tower.py in.gcode out.gcode --start 255 --step -5 --band 10 [--base 0]

--start  temperature of the bottom band
--step   change per band (negative to go cooler upwards, the usual direction)
--band   band height in mm (10 for the common "smart compact" towers)
--base   height of any base plate below band 1 (printed at --start)
"""
import argparse, re, sys

ap = argparse.ArgumentParser()
ap.add_argument('src'); ap.add_argument('dst')
ap.add_argument('--start', type=float, required=True)
ap.add_argument('--step', type=float, required=True)
ap.add_argument('--band', type=float, default=10.0)
ap.add_argument('--base', type=float, default=0.0)
a = ap.parse_args()

lines = open(a.src).read().splitlines()
out, band_seen, in_body, first_layer_done = [], -1, False, False
temps_used = []
for ln in lines:
    if ln.startswith(';LAYER_CHANGE'):
        in_body = True
    if in_body and re.match(r'^M10[49]\b', ln):
        out.append('; ' + ln + ' (removed by temp_tower.py)'); continue
    out.append(ln)
    m = re.match(r'^;Z:([\d.]+)', ln)
    if m and in_body:
        z = float(m.group(1))
        band = 0 if z <= a.base + 1e-6 else int((z - a.base - 1e-6) // a.band)
        if band != band_seen:
            band_seen = band
            t = a.start + a.step * band
            temps_used.append((z, t))
            out.append(f'M104 S{t:g} ; temp_tower.py band {band}')
open(a.dst, 'w').write('\n'.join(out) + '\n')
for z, t in temps_used:
    print(f'from Z {z:6.2f}: {t:g} C')
print(f'{len(temps_used)} bands written to {a.dst}')
