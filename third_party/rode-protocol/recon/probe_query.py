#!/usr/bin/env python3
"""Search for the DSP state READ opcode.
DSP channel (Output id4 -> Input id3). We vary ONLY payload[0] (opcode),
the rest = 0 (effect 0 / value 0 -> harmless). Looking for a reply WITH DATA
(more than just '03 xx 41 00...')."""
import os, select, sys, time

DEV = "/dev/hidraw4"
REPORT_OUT = 0x04
PAYLOAD = 28

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

def send(opcode, p1=0, p2=0, p3=0, p4=0):
    payload = bytearray(PAYLOAD)
    payload[0], payload[1], payload[2], payload[3], payload[4] = opcode, p1, p2, p3, p4
    os.write(fd, bytes([REPORT_OUT]) + bytes(payload))

def classify(resps):
    if not resps:
        return "NO reply"
    tags = []
    for d in resps:
        ack = len(d) >= 3 and d[2] == 0x41
        data = any(b != 0 for b in d[3:])
        if data:
            tags.append(f"DATA! {d.hex(' ')}")
        elif ack:
            tags.append(f"ack ({d[:3].hex(' ')})")
        else:
            tags.append(f"other {d.hex(' ')}")
    return " | ".join(tags)

print("== sweep opcode (payload[0]), rest=0 ==")
for op in range(0x00, 0x10):
    send(op)
    print(f"  op={op:#04x}: {classify(read_resp())}")
    time.sleep(0.1)

# Hypothesis: opcode 0x04 is SET; maybe payload[2] (parameter selector) with a
# different opcode reads. Try opcode 0x04 with payload[2] varied and value=0,
# watching whether the current value comes back.
print("\n== opcode 0x04, sweep payload[2] (selector), value=0 ==")
for sel in range(0x00, 0x06):
    send(0x04, p1=0x00, p2=sel, p4=0x00)
    print(f"  p2={sel:#04x}: {classify(read_resp())}")
    time.sleep(0.1)

os.close(fd)
