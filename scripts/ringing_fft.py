#!/usr/bin/env python3
"""Find the dominant vibration frequencies in an accelerometer CSV from msp_accel_log.py.

    scripts/ringing_fft.py log.csv [--min 15] [--max 150] [--from T0] [--to T1]

Resamples to a uniform rate, removes the mean, windows, runs an FFT (pure Python, no
numpy) and prints the top peaks per axis. Use --from/--to to analyse only the X-move
part or the Y-move part of the recording.
"""
import argparse, cmath, math

ap = argparse.ArgumentParser()
ap.add_argument('csv'); ap.add_argument('--min', type=float, default=15); ap.add_argument('--max', type=float, default=150)
ap.add_argument('--from', dest='t0', type=float, default=None); ap.add_argument('--to', dest='t1', type=float, default=None)
a = ap.parse_args()

rows = [list(map(float, l.split(','))) for l in open(a.csv).read().splitlines()[1:] if l.strip()]
if a.t0 is not None: rows = [r for r in rows if r[0] >= a.t0]
if a.t1 is not None: rows = [r for r in rows if r[0] <= a.t1]
t = [r[0] for r in rows]
dur = t[-1] - t[0]; fs = (len(t) - 1) / dur
print(f'{len(rows)} samples over {dur:.1f} s, mean rate {fs:.0f} Hz, usable to {fs/2:.0f} Hz')

def fft(x):
    n = len(x)
    if n == 1: return x
    even = fft(x[0::2]); odd = fft(x[1::2])
    out = [0] * n
    for k in range(n // 2):
        tw = cmath.exp(-2j * math.pi * k / n) * odd[k]
        out[k] = even[k] + tw; out[k + n // 2] = even[k] - tw
    return out

def resample(col):
    # uniform grid at fs by linear interpolation
    n = 1 << int(math.log2(len(t)))
    grid = [t[0] + i * dur / n for i in range(n)]
    out, j = [], 0
    for g in grid:
        while j + 1 < len(t) and t[j + 1] < g: j += 1
        if j + 1 >= len(t): out.append(col[-1]); continue
        f = (g - t[j]) / (t[j + 1] - t[j]) if t[j + 1] > t[j] else 0
        out.append(col[j] + f * (col[j + 1] - col[j]))
    return out, n / dur

for name, idx in (('accel X', 1), ('accel Y', 2), ('accel Z', 3)):
    col = [r[idx] for r in rows]
    x, rate = resample(col)
    m = sum(x) / len(x); x = [v - m for v in x]
    n = len(x); x = [v * (0.5 - 0.5 * math.cos(2 * math.pi * i / n)) for i, v in enumerate(x)]  # Hann
    spec = fft([complex(v) for v in x])
    mags = [(k * rate / n, abs(spec[k])) for k in range(n // 2)]
    band = [(f, mg) for f, mg in mags if a.min <= f <= a.max]
    peaks = []
    for i in range(1, len(band) - 1):
        if band[i][1] > band[i - 1][1] and band[i][1] >= band[i + 1][1]: peaks.append(band[i])
    peaks.sort(key=lambda p: -p[1])
    top = peaks[:4]; ref = top[0][1] if top else 1
    print(f'{name}: ' + ', '.join(f'{f:5.1f} Hz ({mg/ref*100:3.0f}%)' for f, mg in top))
