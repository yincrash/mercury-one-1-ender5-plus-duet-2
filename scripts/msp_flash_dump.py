#!/usr/bin/env python3
"""Download a Betaflight blackbox log from the FC's onboard flash over USB (MSP v1 with
jumbo frames), or erase the flash.

    scripts/msp_flash_dump.py PORT summary
    scripts/msp_flash_dump.py PORT erase
    scripts/msp_flash_dump.py PORT dump out.bfl

Decode afterwards with blackbox_decode (betaflight/blackbox-tools): blackbox_decode out.bfl
"""
import serial, struct, sys, time, glob

MSP_DATAFLASH_SUMMARY, MSP_DATAFLASH_READ, MSP_DATAFLASH_ERASE = 70, 71, 72

def send(ser, cmd, payload=b''):
    size = len(payload); chk = size ^ cmd
    for b in payload: chk ^= b
    ser.write(b'$M<' + bytes([size, cmd]) + payload + bytes([chk]))

def recv(ser, want):
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        b = ser.read(1)
        if b != b'$': continue
        if ser.read(2) != b'M>': continue
        size = ser.read(1)[0]
        if size == 255:  # jumbo frame
            size = struct.unpack('<H', ser.read(2))[0]
        cmd = ser.read(1)[0]
        payload = b''
        while len(payload) < size:
            chunk = ser.read(size - len(payload))
            if not chunk: break
            payload += chunk
        ser.read(1)  # checksum (not verified for jumbo)
        if cmd == want: return payload
    return None

def summary(ser):
    send(ser, MSP_DATAFLASH_SUMMARY); p = recv(ser, MSP_DATAFLASH_SUMMARY)
    flags, sectors, total, used = struct.unpack('<BIII', p[:13])
    return {'ready': bool(flags & 1), 'supported': bool(flags & 2), 'sectors': sectors, 'total': total, 'used': used}

port = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1].startswith('/dev') else glob.glob('/dev/cu.usbmodem*')[0]
args = sys.argv[2:] if sys.argv[1].startswith('/dev') else sys.argv[1:]
ser = serial.Serial(port, 1000000, timeout=0.5); time.sleep(0.3); ser.reset_input_buffer()
op = args[0]
if op == 'summary':
    print(summary(ser))
elif op == 'erase':
    send(ser, MSP_DATAFLASH_ERASE); recv(ser, MSP_DATAFLASH_ERASE)
    for i in range(60):
        time.sleep(1); s = summary(ser)
        if s['ready']: print('erased:', s); break
        print('  erasing...', flush=True)
elif op == 'dump':
    s = summary(ser); used = s['used']; print('flash:', s)
    out = bytearray(); addr = 0; chunk = 4096; t0 = time.monotonic()
    while addr < used:
        n = min(chunk, used - addr)
        send(ser, MSP_DATAFLASH_READ, struct.pack('<IHB', addr, n, 0))
        p = recv(ser, MSP_DATAFLASH_READ)
        if p is None: print('timeout at', addr); continue
        raddr, = struct.unpack('<I', p[:4])
        if len(p) >= 7:
            dsize, comp = struct.unpack('<HB', p[4:7]); data = p[7:7 + dsize]
        else:
            data = p[4:]
        if raddr != addr or not data: print('bad chunk at', addr, raddr, len(p)); continue
        out += data; addr += len(data)
        if (addr // chunk) % 25 == 0: print(f'  {addr}/{used} bytes, {addr/1024/(time.monotonic()-t0):.0f} KB/s', flush=True)
    open(args[1], 'wb').write(out); print(f'wrote {len(out)} bytes to {args[1]} in {time.monotonic()-t0:.0f} s')
ser.close()
