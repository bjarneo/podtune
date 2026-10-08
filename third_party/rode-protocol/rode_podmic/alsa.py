"""PodMic USB input gain via ALSA (UAC Feature Unit = the 'Mic' capture control).

Gain does not go through HID — it is a standard USB Audio Class control exposed
as the ALSA card's capture volume. We drive it with `amixer`.
"""
from __future__ import annotations
import re
import subprocess

CARD_HINT = "PodMic"
CONTROL = "Mic"  # capture gain


def find_card() -> int | None:
    """Index of the PodMic USB ALSA card (from /proc/asound/cards)."""
    try:
        cards = open("/proc/asound/cards").read()
    except OSError:
        return None
    for line in cards.splitlines():
        m = re.match(r"\s*(\d+)\s", line)
        if m and CARD_HINT.lower() in line.lower():
            return int(m.group(1))
    # the name is sometimes on the second line of an entry — scan in pairs
    nums = re.findall(r"^\s*(\d+)\s+\[.*", cards, re.M)
    for blk in re.split(r"^\s*\d+\s+\[", cards, flags=re.M)[1:]:
        if CARD_HINT.lower() in blk.lower():
            idx = re.findall(r"(\d+)", cards.split(blk)[0].splitlines()[-1])
            if idx:
                return int(idx[-1])
    return None


def _amixer(card: int, *args) -> str:
    return subprocess.run(["amixer", "-c", str(card), *args],
                          capture_output=True, text=True).stdout


def _db_range(card: int, steps_min: int, steps_max: int) -> tuple[float, float] | None:
    """(dB_min, dB_max) of the capture control as reported by the device's UAC descriptor."""
    out = _amixer(card, "cget", f"name={CONTROL} Capture Volume")
    m = re.search(r"dBminmax-min=([-\d.]+)dB,max=([-\d.]+)dB", out)
    if m:
        return float(m.group(1)), float(m.group(2))
    m = re.search(r"dBscale-min=([-\d.]+)dB,step=([-\d.]+)dB", out)
    if m:
        lo, step = float(m.group(1)), float(m.group(2))
        return lo, lo + step * (steps_max - steps_min)
    return None


def get_gain(card: int | None = None) -> dict | None:
    """Current input gain, in ALSA steps and in dB.

    Returns {'value', 'min', 'max' (steps), 'db', 'db_min', 'db_max', 'percent'}.
    On the PodMic USB: steps 0..41 map linearly onto 22..63 dB (1 dB per step).
    """
    if card is None:
        card = find_card()
    if card is None:
        return None
    out = _amixer(card, "sget", CONTROL)
    lim = re.search(r"Limits: Capture (\d+) - (\d+)", out)
    cur = re.search(r"Capture (\d+) \[(\d+)%\] \[([-\d.]+)dB\]", out)
    if not (lim and cur):
        return None
    info = {"value": int(cur.group(1)), "min": int(lim.group(1)), "max": int(lim.group(2)),
            "percent": int(cur.group(2)), "db": float(cur.group(3))}
    rng = _db_range(card, info["min"], info["max"])
    if rng is None:  # fall back to 1 dB/step around the current reading
        rng = (info["db"] - (info["value"] - info["min"]),
               info["db"] + (info["max"] - info["value"]))
    info["db_min"], info["db_max"] = rng
    return info


def db_to_steps(db: float, info: dict) -> int:
    """Nearest ALSA step for a gain in dB (clamped to the control's range)."""
    span_db = info["db_max"] - info["db_min"]
    span_st = info["max"] - info["min"]
    if span_db <= 0 or span_st <= 0:
        return info["min"]
    st = info["min"] + round((db - info["db_min"]) * span_st / span_db)
    return max(info["min"], min(info["max"], int(st)))


def set_gain(value: int, card: int | None = None) -> bool:
    """Set the gain in ALSA steps (0..max). Returns True if amixer succeeded."""
    if card is None:
        card = find_card()
    if card is None:
        return False
    r = subprocess.run(["amixer", "-c", str(card), "sset", CONTROL, str(value)],
                       capture_output=True, text=True)
    return r.returncode == 0


def set_gain_db(db: float, card: int | None = None) -> bool:
    """Set the gain in dB (rounded to the nearest step, clamped to the device range)."""
    if card is None:
        card = find_card()
    info = get_gain(card)
    if info is None:
        return False
    return set_gain(db_to_steps(db, info), card)


# --- monitoring / loopback via PipeWire/PulseAudio (pactl) ---
SOURCE_HINT = "PodMic"


def _pactl(*args) -> str:
    return subprocess.run(["pactl", *args], capture_output=True, text=True).stdout


def find_source() -> str | None:
    """Name of the PipeWire source for the PodMic mic (an 'input', not '.monitor')."""
    for line in _pactl("list", "sources", "short").splitlines():
        parts = line.split("\t")
        if len(parts) >= 2 and SOURCE_HINT.lower() in parts[1].lower() \
                and not parts[1].endswith(".monitor"):
            return parts[1]
    return None


def default_sink() -> str | None:
    s = _pactl("get-default-sink").strip()
    return s or None


def loopback_modules() -> list[str]:
    """Indices of active loopback modules that use PodMic as the source."""
    out = []
    for line in _pactl("list", "modules", "short").splitlines():
        if "module-loopback" in line and SOURCE_HINT.lower() in line.lower():
            out.append(line.split("\t")[0])
    return out


def start_monitor(latency_msec: int = 60, sink: str | None = None) -> str | None:
    """Start a loopback PodMic mic -> sink (default sink if None). Returns module id."""
    src = find_source()
    if not src:
        return None
    sink = sink or default_sink()
    args = ["load-module", "module-loopback", f"source={src}", f"latency_msec={latency_msec}"]
    if sink:
        args.append(f"sink={sink}")
    mod = _pactl(*args).strip()
    return mod or None


def stop_monitor() -> int:
    """Tear down all PodMic loopbacks. Returns the number removed."""
    mods = loopback_modules()
    for m in mods:
        subprocess.run(["pactl", "unload-module", m], capture_output=True)
    return len(mods)
