#!/usr/bin/env python3
"""Passive listen on /dev/hidraw4 — read-only, no writes.
Prints raw Input reports (first byte = Report ID) as hex."""
import os, select, sys, time

DEV = sys.argv[1] if len(sys.argv) > 1 else "/dev/hidraw4"
DURATION = float(sys.argv[2]) if len(sys.argv) > 2 else 4.0

fd = os.open(DEV, os.O_RDONLY | os.O_NONBLOCK)
print(f"# listening on {DEV} for {DURATION}s — move the level / talk into the mic")
t0 = time.time()
seen = {}
n = 0
try:
    while time.time() - t0 < DURATION:
        r, _, _ = select.select([fd], [], [], 0.5)
        if not r:
            continue
        data = os.read(fd, 64)
        if not data:
            continue
        n += 1
        rid = data[0]
        seen.setdefault(rid, 0)
        seen[rid] += 1
        if seen[rid] <= 3:  # show the first 3 of each Report ID
            ts = time.time() - t0
            print(f"[{ts:6.2f}s] id={rid:#04x} len={len(data):2d}  {data.hex(' ')}")
finally:
    os.close(fd)
print(f"\n# total reports: {n}")
print("# by Report ID:", {hex(k): v for k, v in sorted(seen.items())})
