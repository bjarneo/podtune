"""Transport + protocol layer for the RØDE PodMic USB.

Verified on firmware 1.19 (19f7:004a). Mechanism:
  - write: Output report ID 4 (28-byte payload) via /dev/hidraw
  - reply/ACK: Input report ID 3, byte 0x41 ('A')
See docs/protocol.md.
"""
from __future__ import annotations
import enum
import fcntl
import glob
import os
import select
import time

VID = 0x19F7
PID = 0x004A

# --- HID report IDs (from the vendor-page 0xFF00 descriptor) ---
REPORT_DSP_OUT = 0x04   # Output, 28-byte payload
REPORT_DSP_IN = 0x03    # Input,  28-byte payload (reply to DSP_OUT)

REPORT_METER_OUT = 0x06  # Output, 14 B — meter query
REPORT_METER_IN = 0x05   # Input,  14 B — level stream
METER_PAYLOAD_LEN = 14
METER_FULLSCALE = 2 ** 31  # confirmed: loud signal ~ -0.3 dBFS at 2^31

# PodMic device-parameter channel (PodMicUsb::Set/GetParameter), 27 B:
#   payload = [paramId, op, value]   op: 0x00=SET, 0x01=GET
#   reply on id7: [0x07, paramId, 0x41, value]
REPORT_PODMIC_OUT = 0x08
REPORT_PODMIC_IN = 0x07
PODMIC_PAYLOAD_LEN = 27
PODMIC_OP_SET = 0x00
PODMIC_OP_GET = 0x01


class PodMicParam(enum.IntEnum):
    """paramId for PodMicUsb::SetParameter (from the OnXChanged disassembly)."""
    HPF = 1               # 0 = off, 1 = on (60 Hz)
    DIRECT_MONITOR = 3    # 0/1
    MONITOR_MIX = 4       # uint8 0..255
    INPUT_MUTE = 8        # 0/1

# DSP command format (from librode_bridge.so, verified by reading back):
#   payload[0] = effIdx, payload[1] = op, payload[2] = parIdx, payload[3..] = value (LE)
# reply on REPORT_DSP_IN: [0x03, echo-effIdx, status, data...]
DSP_OP_GET_ALL = 0x01   # AphexFx::GetParams
DSP_OP_SET = 0x02       # AphexFx::SetParams / SetGranularParam
DSP_OP_GET = 0x03       # AphexFx::GetGranularParam (read a single parameter)
ACK = 0x41              # 'A' in the reply
NAK = 0x4E              # 'N' in the reply

PAYLOAD_LEN = 28
PARAM_ENABLED = 0x00    # parIdx 0 = enabled (1 B) for every effect


class Effect(enum.Enum):
    """DSP effects (effIdx in payload[0])."""
    COMPRESSOR = 0x00
    NOISE_GATE = 0x01
    AURAL_EXCITER = 0x02
    BIG_BOTTOM = 0x03


EFFECTS = {e.name.lower(): e for e in Effect}


# --- ioctl HIDIOCGINPUT (for diagnostics / potential read-back) ---
def _IOC(d, t, nr, size):
    return (d << 30) | (size << 16) | (ord(t) << 8) | nr


def _HIDIOCGINPUT(length):
    return _IOC(0x1 | 0x2, "H", 0x0A, length)


def find_device_path() -> str | None:
    """Find the /dev/hidrawN belonging to the PodMic USB (via sysfs uevent)."""
    for syspath in glob.glob("/sys/class/hidraw/hidraw*"):
        try:
            with open(os.path.join(syspath, "device/uevent")) as f:
                uevent = f.read()
        except OSError:
            continue
        if f"{VID:04X}" in uevent.upper() and f"{PID:04X}" in uevent.upper():
            return "/dev/" + os.path.basename(syspath)
    return None


class ProtocolError(RuntimeError):
    pass


class PodMicUSB:
    """Connection to the microphone over hidraw."""

    def __init__(self, path: str | None = None):
        self.path = path or find_device_path()
        if not self.path:
            raise FileNotFoundError(
                f"PodMic USB not found ({VID:04x}:{PID:04x}). "
                "Is it plugged in and is the udev rule in place?"
            )
        self._fd: int | None = None

    def __enter__(self):
        self.open()
        return self

    def __exit__(self, *exc):
        self.close()

    def open(self):
        if self._fd is None:
            self._fd = os.open(self.path, os.O_RDWR | os.O_NONBLOCK)

    def close(self):
        if self._fd is not None:
            os.close(self._fd)
            self._fd = None

    # --- low-level ---
    def _write(self, report_id: int, payload: bytes) -> None:
        self._drain()  # drop stale replies so _read_input returns OURS
        frame = bytes([report_id]) + payload
        n = os.write(self._fd, frame)
        if n != len(frame):
            raise ProtocolError(f"wrote {n}/{len(frame)} B")

    def _drain(self) -> None:
        """Discard pending Input reports (request/response synchronisation)."""
        while True:
            r, _, _ = select.select([self._fd], [], [], 0)
            if not r:
                return
            try:
                if not os.read(self._fd, 64):
                    return
            except (BlockingIOError, OSError):
                return

    def _read_input(self, timeout: float = 0.5) -> bytes | None:
        end = time.time() + timeout
        while time.time() < end:
            r, _, _ = select.select([self._fd], [], [], max(0, end - time.time()))
            if not r:
                break
            try:
                return os.read(self._fd, 64)
            except BlockingIOError:
                continue
        return None

    # --- DSP protocol (granular get/set of parameters) ---
    def dsp_get_param(self, effect: Effect, par_idx: int) -> bytes | None:
        """Read a raw parameter value (GET op). Returns the value bytes
        (payload after the header) or None if no ACK."""
        payload = bytearray(PAYLOAD_LEN)
        payload[0] = effect.value
        payload[1] = DSP_OP_GET
        payload[2] = par_idx
        self._write(REPORT_DSP_OUT, bytes(payload))
        resp = self._read_input()
        if resp is None or len(resp) < 3 or resp[2] != ACK:
            return None
        return bytes(resp[3:])  # value starts at offset 3

    def dsp_set_param(self, effect: Effect, par_idx: int, value: bytes,
                      *, wait_ack: bool = True) -> bool:
        """Write a raw parameter value (SET op). value = little-endian bytes."""
        payload = bytearray(PAYLOAD_LEN)
        payload[0] = effect.value
        payload[1] = DSP_OP_SET
        payload[2] = par_idx
        payload[3:3 + len(value)] = value
        self._write(REPORT_DSP_OUT, bytes(payload))
        if not wait_ack:
            return True
        resp = self._read_input()
        return resp is not None and len(resp) >= 3 and resp[2] == ACK

    def set_effect(self, effect: Effect, enabled: bool, **kw) -> bool:
        """Enable/disable a DSP effect (parIdx 0 = enabled, 1 B)."""
        return self.dsp_set_param(effect, PARAM_ENABLED, bytes([1 if enabled else 0]), **kw)

    def get_effect_enabled(self, effect: Effect) -> bool | None:
        v = self.dsp_get_param(effect, PARAM_ENABLED)
        return None if v is None else bool(v[0])

    # --- meters (id6 -> id5 channel) ---
    def read_meter(self) -> int | None:
        """Read the instantaneous level amplitude (0..METER_FULLSCALE).
        Returns the magnitude (max of the 2 samples in the reply) or None."""
        payload = bytearray(METER_PAYLOAD_LEN)  # selector 0x00
        self._write(REPORT_METER_OUT, bytes(payload))
        resp = self._read_input(timeout=0.1)
        if resp is None or len(resp) < 11 or resp[2] != ACK:
            return None
        w0 = int.from_bytes(resp[3:7], "little")
        w1 = int.from_bytes(resp[7:11], "little")
        return max(w0, w1)

    @staticmethod
    def meter_dbfs(magnitude: int) -> float:
        """Convert a meter magnitude to dBFS (full scale = 2^31)."""
        import math
        return 20.0 * math.log10(max(magnitude, 1) / METER_FULLSCALE)

    # --- PodMic device parameters (id8 -> id7 channel) ---
    def podmic_get(self, param: int) -> int | None:
        """Read a PodMic parameter (HPF/monitor/mute). Returns a uint8 value or None."""
        payload = bytearray(PODMIC_PAYLOAD_LEN)
        payload[0] = int(param)
        payload[1] = PODMIC_OP_GET
        self._write(REPORT_PODMIC_OUT, bytes(payload))
        resp = self._read_input()
        if resp is None or len(resp) < 4 or resp[2] != ACK:
            return None
        return resp[3]

    def podmic_set(self, param: int, value: int, *, wait_ack: bool = True) -> bool:
        """Write a PodMic parameter."""
        payload = bytearray(PODMIC_PAYLOAD_LEN)
        payload[0] = int(param)
        payload[1] = PODMIC_OP_SET
        payload[2] = value & 0xFF
        self._write(REPORT_PODMIC_OUT, bytes(payload))
        if not wait_ack:
            return True
        resp = self._read_input()
        return resp is not None and len(resp) >= 3 and resp[2] == ACK

    # convenience aliases
    def set_hpf(self, on: bool) -> bool:
        return self.podmic_set(PodMicParam.HPF, 1 if on else 0)

    def get_hpf(self) -> bool | None:
        v = self.podmic_get(PodMicParam.HPF)
        return None if v is None else bool(v)

    def set_input_mute(self, mute: bool) -> bool:
        return self.podmic_set(PodMicParam.INPUT_MUTE, 1 if mute else 0)

    def set_direct_monitor(self, on: bool) -> bool:
        return self.podmic_set(PodMicParam.DIRECT_MONITOR, 1 if on else 0)

    def set_monitor_mix(self, value: int) -> bool:
        return self.podmic_set(PodMicParam.MONITOR_MIX, max(0, min(255, value)))
