#!/usr/bin/env python3
"""Turn a normally sliced PrusaSlicer G-code into a pressure advance tower for RRF.

Inserts `M572 D0 S<value>` at the first layer of each band, using the `;Z:` layer
markers. Slice a tower with equal-height bands (or any tall rectangular part with
sharp corners, e.g. a 30x30x60 mm hollow square with 1 perimeter) at the chosen
print temperature and normal speeds; sharp corners at 80+ mm/s show PA best.

    scripts/pa_tower.py in.gcode out.gcode --start 0 --step 0.01 --band 5 [--base 0] [--temp 240]

--start  PA of the bottom band (0 = off)
--step   PA increase per band
--band   band height in mm
--base   height of any base below band 1
--temp   optionally override the print temperature everywhere (M104/M109 S values)
"""
import argparse, re

ap = argparse.ArgumentParser()
ap.add_argument('src'); ap.add_argument('dst')
ap.add_argument('--start', type=float, default=0.0)
ap.add_argument('--step', type=float, required=True)
ap.add_argument('--band', type=float, required=True)
ap.add_argument('--base', type=float, default=0.0)
ap.add_argument('--temp', type=float)
a = ap.parse_args()

lines = open(a.src).read().splitlines()
if a.temp:
    lines = [re.sub(r'^(M10[49]) S(?!0\b)[\d.]+', rf'\1 S{a.temp:g}', ln) if re.match(r'^M10[49] S(?!150\b)', ln) else ln for ln in lines]
out, band_seen, in_body, used = [], -1, False, []
for ln in lines:
    if ln.startswith(';LAYER_CHANGE'):
        in_body = True
    out.append(ln)
    m = re.match(r'^;Z:([\d.]+)', ln)
    if m and in_body:
        z = float(m.group(1))
        band = 0 if z <= a.base + 1e-6 else int((z - a.base - 1e-6) // a.band)
        if band != band_seen:
            band_seen = band
            pa = a.start + a.step * band
            used.append((z, pa))
            out.append(f'M572 D0 S{pa:.3f} ; pa_tower.py band {band}')
out.append('M572 D0 S0 ; pa_tower.py: reset PA at end')
open(a.dst, 'w').write('\n'.join(out) + '\n')
for z, pa in used:
    print(f'from Z {z:6.2f}: PA {pa:.3f}')
print(f'{len(used)} bands written to {a.dst}')
