"""PodMic USB configuration profiles — save/load the full state (DSP + device + gain).

A profile is JSON:
  {"version":1,
   "effects": {"compressor": {"enabled":true,"threshold":-26.6,...}, ...},
   "device":  {"hpf":false,"input_mute":false,"direct_monitor":false,"monitor_mix":91},
   "gain": 41}

Named profiles live in ~/.config/rode-podmic/profiles/<name>.json.
"""
from __future__ import annotations
import json
import os

from .device import Effect, PodMicParam
from . import params as P
from . import alsa

VERSION = 1

# device paramId -> profile key
_DEVICE = {
    "hpf": PodMicParam.HPF,
    "input_mute": PodMicParam.INPUT_MUTE,
    "direct_monitor": PodMicParam.DIRECT_MONITOR,
    "monitor_mix": PodMicParam.MONITOR_MIX,
}
_BOOL_DEV = {"hpf", "input_mute", "direct_monitor"}


def profiles_dir() -> str:
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    d = os.path.join(base, "rode-podmic", "profiles")
    os.makedirs(d, exist_ok=True)
    return d


def _path(name: str) -> str:
    safe = "".join(c for c in name if c.isalnum() or c in "-_ ").strip() or "profile"
    return os.path.join(profiles_dir(), f"{safe}.json")


def list_profiles() -> list[str]:
    d = profiles_dir()
    return sorted(f[:-5] for f in os.listdir(d) if f.endswith(".json"))


def capture(mic) -> dict:
    """Read the full current device state into a dict."""
    effects = {}
    for eff in Effect:
        vals = P.get_params(mic, eff)
        effects[eff.name.lower()] = {k: v for k, v in vals.items() if v is not None}
    device = {}
    for key, pid in _DEVICE.items():
        v = mic.podmic_get(pid)
        if v is not None:
            device[key] = bool(v) if key in _BOOL_DEV else v
    prof = {"version": VERSION, "effects": effects, "device": device}
    g = alsa.get_gain()
    if g:
        prof["gain"] = g["value"]
    return prof


def apply(mic, prof: dict) -> dict:
    """Apply a profile. Returns a summary {section: status}."""
    result = {}
    for eff_name, vals in prof.get("effects", {}).items():
        try:
            eff = Effect[eff_name.upper()]
        except KeyError:
            continue
        res = P.set_params(mic, eff, **vals)
        result[eff_name] = all(res.values()) if res else True
    for key, val in prof.get("device", {}).items():
        pid = _DEVICE.get(key)
        if pid is None:
            continue
        result[f"device.{key}"] = mic.podmic_set(pid, 1 if (key in _BOOL_DEV and val) else
                                                  (0 if key in _BOOL_DEV else int(val)))
    if "gain" in prof:
        result["gain"] = alsa.set_gain(int(prof["gain"]))
    return result


def save(mic, name: str) -> str:
    """Save the current state as a named profile. Returns the file path."""
    path = _path(name)
    with open(path, "w") as f:
        json.dump(capture(mic), f, indent=2, ensure_ascii=False)
    return path


def load(name: str) -> dict:
    with open(_path(name)) as f:
        return json.load(f)


def delete(name: str) -> bool:
    path = _path(name)
    if os.path.exists(path):
        os.remove(path)
        return True
    return False
