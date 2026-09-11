#!/usr/bin/env python3
"""Log the accelerometer of a Betaflight flight controller over USB (MSP v1, MSP_RAW_IMU)
as fast as the FC will answer. Used as a poor man's input-shaping accelerometer: zip-tie
the FC to the toolhead with its arrow along printer +X, plug in USB, run this, then run
the excitation moves on the printer.

    scripts/msp_accel_log.py /dev/cu.usbmodemXXXX out.csv [--seconds 40]

CSV columns: t (s), ax, ay, az, gx, gy, gz (raw int16 from the FC; scale does not matter
for frequency analysis). Prints the achieved sample rate at the end.
"""
import argparse, serial, struct, sys, time

ap = argparse.ArgumentParser()
ap.add_argument('port'); ap.add_argument('out'); ap.add_argument('--seconds', type=float, default=40)
a = ap.parse_args()

MSP_RAW_IMU = 102
def msp_request(cmd):
    payload = b''
    size = len(payload)
    chk = size ^ cmd
    for b in payload: chk ^= b
    return b'$M<' + bytes([size, cmd]) + payload + bytes([chk])

def read_msp(ser):
    # find header
    while True:
        b = ser.read(1)
        if not b: return None
        if b == b'$':
            if ser.read(2) != b'M>': continue
            size = ser.read(1)[0]; cmd = ser.read(1)[0]
            payload = ser.read(size); chk = ser.read(1)[0]
            c = size ^ cmd
            for x in payload: c ^= x
            if c != chk: continue
            return cmd, payload

ser = serial.Serial(a.port, 1000000, timeout=0.05)
time.sleep(0.5); ser.reset_input_buffer()
# Pipelined: keep DEPTH requests in flight. Requires `set serial_update_rate_hz = 2000` on the
# FC (default 100 caps this at ~60 Hz) and `set acc_lpf_hz = 500` (default 25 Hz would smear
# the ringing band). Achieves ~300 Hz on an F411 over USB.
DEPTH = 16
req = msp_request(MSP_RAW_IMU)
rows = []; buf = b''; t0 = time.monotonic(); n = 0; last_print = 0
print(f'logging for {a.seconds:.0f} s ... (start the printer moves now)', flush=True)
ser.write(req * DEPTH)
while time.monotonic() - t0 < a.seconds:
    buf += ser.read(4096)
    while True:
        i = buf.find(b'$M>')
        if i < 0 or len(buf) < i + 5: break
        size = buf[i + 3]; cmd = buf[i + 4]
        if len(buf) < i + 6 + size: break
        payload = buf[i + 5:i + 5 + size]; buf = buf[i + 6 + size:]
        if cmd == MSP_RAW_IMU and size >= 12:
            ax, ay, az, gx, gy, gz = struct.unpack('<6h', payload[:12])
            rows.append((time.monotonic() - t0, ax, ay, az, gx, gy, gz)); n += 1
            ser.write(req)
    if n - last_print >= 1000:
        last_print = n; print(f'  {n} samples, {n/(time.monotonic()-t0):.0f} Hz', flush=True)
ser.close()
with open(a.out, 'w') as f:
    f.write('t,ax,ay,az,gx,gy,gz\n')
    for r in rows: f.write(','.join(f'{v:.5f}' if i == 0 else str(v) for i, v in enumerate(r)) + '\n')
dur = rows[-1][0] if rows else 0
print(f'{len(rows)} samples in {dur:.1f} s = {len(rows)/dur if dur else 0:.0f} Hz -> {a.out}')
