#!/usr/bin/env python3
"""Read the current Input reports via HIDIOCGINPUT (GET_REPORT, Device->Host).
This request only READS state — it sends no commands that change settings."""
import fcntl, sys, ctypes

DEV = sys.argv[1] if len(sys.argv) > 1 else "/dev/hidraw4"

_IOC_WRITE, _IOC_READ = 1, 2
def _IOC(d, t, nr, size): return (d << 30) | (size << 16) | (ord(t) << 8) | nr
def HIDIOCGINPUT(length):   return _IOC(_IOC_WRITE | _IOC_READ, 'H', 0x0A, length)
def HIDIOCGFEATURE(length): return _IOC(_IOC_WRITE | _IOC_READ, 'H', 0x07, length)

# Report ID -> payload size (from the HID descriptor)
REPORTS = {1: 9, 3: 28, 5: 14, 7: 27}

import os
fd = os.open(DEV, os.O_RDWR)  # GET needs no write, but ioctl sometimes requires RDWR
def query(kind, ioctl_fn):
    print(f"\n=== {kind} ===")
    for rid, size in REPORTS.items():
        buf = bytearray([rid] + [0] * size)
        try:
            fcntl.ioctl(fd, ioctl_fn(len(buf)), buf, True)
            print(f"  id={rid:#04x} len={len(buf):2d}  {bytes(buf).hex(' ')}")
        except OSError as e:
            print(f"  id={rid:#04x} -> error: {e}")

try:
    query("GET_INPUT (HIDIOCGINPUT)", HIDIOCGINPUT)
    query("GET_FEATURE (HIDIOCGFEATURE)", HIDIOCGFEATURE)
finally:
    os.close(fd)
