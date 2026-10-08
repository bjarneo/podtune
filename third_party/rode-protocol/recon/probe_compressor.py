#!/usr/bin/env python3
"""Controlled, REVERSIBLE experiment: compressor toggle + read-back.
Sends the known rode-dsp-tool packets (Output report ID 4) and checks whether
Input report ID 3 reflects the state. Leaves the compressor OFF at the end."""
import fcntl, os, select, sys, time

DEV = "/dev/hidraw4"
_W, _R = 1, 2
def _IOC(d,t,nr,sz): return (d<<30)|(sz<<16)|(ord(t)<<8)|nr
def HIDIOCGINPUT(n): return _IOC(_W|_R,'H',0x0A,n)

# 28-byte payload per rode-dsp-tool — WITHOUT the report-ID byte (added on write)
COMP_ON  = bytes.fromhex('0400020001' + '00'*23)
COMP_OFF = bytes.fromhex('0400020000' + '00'*23)
assert len(COMP_ON) == 28 and len(COMP_OFF) == 28

fd = os.open(DEV, os.O_RDWR)

def get_input(rid, size):
    buf = bytearray([rid] + [0]*size)
    try:
        fcntl.ioctl(fd, HIDIOCGINPUT(len(buf)), buf, True)
        return bytes(buf)
    except OSError as e:
        return f"ERR {e}"

def drain_interrupt(label, t=0.4):
    """Read Input reports arriving on the interrupt IN after a command."""
    end = time.time() + t
    got = []
    while time.time() < end:
        r,_,_ = select.select([fd],[],[], max(0, end-time.time()))
        if not r: break
        try:
            d = os.read(fd, 64)
            if d: got.append(d)
        except BlockingIOError:
            break
    if got:
        for d in got:
            print(f"    [int-IN {label}] id={d[0]:#04x} {d.hex(' ')}")
    else:
        print(f"    [int-IN {label}] (no data)")

def send_output(rid, payload, label):
    frame = bytes([rid]) + payload
    n = os.write(fd, frame)
    print(f"  -> WRITE id={rid:#04x} ({n}B): {frame.hex(' ')}  # {label}")

try:
    print("== BASELINE ==")
    print("  GET_INPUT id=0x03:", get_input(3, 28).hex(' ') if isinstance(get_input(3,28),bytes) else get_input(3,28))

    print("\n== COMPRESSOR ON ==")
    send_output(0x04, COMP_ON, "compressor ON")
    drain_interrupt("after ON")
    r3 = get_input(3, 28)
    print("  GET_INPUT id=0x03:", r3.hex(' ') if isinstance(r3,bytes) else r3)

    time.sleep(0.3)

    print("\n== COMPRESSOR OFF (restore) ==")
    send_output(0x04, COMP_OFF, "compressor OFF")
    drain_interrupt("after OFF")
    r3 = get_input(3, 28)
    print("  GET_INPUT id=0x03:", r3.hex(' ') if isinstance(r3,bytes) else r3)
finally:
    os.close(fd)
print("\n# done — compressor left OFF")
