"""Live level meter (VU/dBFS) for the RØDE PodMic USB — id6 channel.

The meter value is a linear amplitude 0..2^31 (full scale). We display dBFS
with peak-hold in the terminal. Read-only — it never changes device settings."""
from __future__ import annotations
import sys
import time

from .device import PodMicUSB

DB_FLOOR = -60.0   # bottom of the meter scale


def _bar(dbfs: float, width: int = 40) -> str:
    frac = (dbfs - DB_FLOOR) / (0.0 - DB_FLOOR)
    frac = max(0.0, min(1.0, frac))
    n = int(frac * width)
    return "█" * n + "·" * (width - n)


def run(refresh_hz: float = 30.0, peak_hold_s: float = 1.5):
    """Meter loop until Ctrl+C."""
    period = 1.0 / refresh_hz
    peak_db = DB_FLOOR
    peak_ts = 0.0
    try:
        with PodMicUSB() as mic:
            sys.stdout.write("\nRØDE PodMic USB — level (Ctrl+C to quit)\n")
            while True:
                mag = mic.read_meter()
                now = time.time()
                if mag is not None:
                    db = mic.meter_dbfs(mag)
                    if db >= peak_db or now - peak_ts > peak_hold_s:
                        peak_db, peak_ts = db, now
                    clip = " CLIP" if db > -0.5 else "     "
                    line = f"\r{_bar(db)} {db:6.1f} dBFS  peak {peak_db:6.1f}{clip}"
                    sys.stdout.write(line)
                    sys.stdout.flush()
                time.sleep(period)
    except KeyboardInterrupt:
        sys.stdout.write("\n")
