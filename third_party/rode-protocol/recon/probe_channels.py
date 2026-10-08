#!/usr/bin/env python3
"""Probe the remaining report channels looking for a state READ.
Output id2 (9B), id6 (14B), id8 (27B) -> replies on Input id1/id5/id7.
Sweep the first byte with a zero payload. Looking for replies WITH DATA."""
import os, select, time

DEV = "/dev/hidraw4"
# (output_report_id, payload_len)
CHANNELS = [(0x02, 9), (0x06, 14), (0x08, 27)]

fd = os.open(DEV, os.O_RDWR | os.O_NONBLOCK)

def read_resp(t=0.4):
    end = time.time() + t
    out = []
    while time.time() < end:
        r,_,_ = select.select([fd],[],[], max(0, end-time.time()))
        if not r: break
        try:
            d = os.read(fd, 64)
            if d: out.append(d)
        except BlockingIOError:
            break
    return out

def classify(resps):
    if not resps:
        return "NONE"
    tags = []
    for d in resps:
        data = any(b != 0 for b in d[3:])
        tags.append((f"DATA! {d.hex(' ')}") if data else f"ack/echo {d[:4].hex(' ')}")
    return " | ".join(tags)

for rid, plen in CHANNELS:
    print(f"\n== Output channel id={rid:#04x} (payload {plen}B) ==")
    for op in range(0x00, 0x0c):
        payload = bytearray(plen)
        payload[0] = op
        os.write(fd, bytes([rid]) + bytes(payload))
        print(f"  b0={op:#04x}: {classify(read_resp())}")
        time.sleep(0.1)

os.close(fd)
