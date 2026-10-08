#!/usr/bin/env python3
"""Map the READ channel id6 (out 14B) -> id5 (in). READ-ONLY (query).
Sweep the payload[0] selector, full data, twice to confirm stability."""
import os, select, struct, time

DEV = "/dev/hidraw4"
RID_OUT, PLEN = 0x06, 14

fd = os.open(DEV, os.O_RDWR | os.O_NONBLOCK)

def read_one(t=0.3):
    end = time.time() + t
    while time.time() < end:
        r,_,_ = select.select([fd],[],[], max(0, end-time.time()))
        if not r: break
        try:
            return os.read(fd, 64)
        except BlockingIOError:
            break
    return None

def query(sel):
    payload = bytearray(PLEN); payload[0] = sel
    os.write(fd, bytes([RID_OUT]) + bytes(payload))
    return read_one()

def decode(d):
    # d: 05 <sel> <41/4e> <payload...>; payload is 14B
    body = d[3:3+14] if d else b""
    # interpret as 32-bit LE (3 words) + remainder
    words = []
    for i in range(0, min(12, len(body)), 4):
        words.append(struct.unpack_from("<i", body, i)[0])
    return body, words

print("== read-channel map id6->id5 (sel 0x00..0x1f) ==")
results = {}
for sel in range(0x00, 0x20):
    d1 = query(sel); time.sleep(0.05)
    d2 = query(sel); time.sleep(0.05)
    if not d1:
        continue
    status = d1[2]
    tag = "ACK" if status == 0x41 else ("NAK" if status == 0x4e else f"{status:#04x}")
    stable = (d1 == d2)
    body, words = decode(d1)
    if status == 0x41:
        print(f"  sel={sel:#04x} {tag} {'==' if stable else '!!varying'} "
              f"raw={body.hex(' ')}  i32LE={words}")
        results[sel] = body
    else:
        print(f"  sel={sel:#04x} {tag}")

os.close(fd)
