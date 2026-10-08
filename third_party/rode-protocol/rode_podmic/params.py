"""DSP parameter encoding (UI value <-> HID bytes).

Formulas recovered from librode_bridge.so (AphexFxParamsUtils::To/From*HidParam).
Pattern: norm in [0,1] -> idx = round(norm*255) -> coeff = LUT256[idx] (int32 LE).
Verified on a live device. See docs/apk_analysis.md.
"""
from __future__ import annotations
import json
import math
import os
from dataclasses import dataclass
from typing import Callable

from .device import Effect

_LUTS = json.load(open(os.path.join(os.path.dirname(__file__), "dsp_luts.json")))


def _nearest_idx(lut: list[int], coeff: int) -> int:
    return min(range(256), key=lambda i: abs(lut[i] - coeff))


def _clamp01(x: float) -> float:
    return max(0.0, min(1.0, x))


@dataclass
class Param:
    """Parameter definition: where it lives in the protocol + how to encode it."""
    name: str
    par_idx: int
    nbytes: int                     # 1 (u8) or 4 (int32)
    unit: str
    encode: Callable[[float], int]  # UI value -> int sent (coeff or byte)
    decode: Callable[[int], float]  # int from device -> UI value

    def to_bytes(self, ui_value: float) -> bytes:
        return int(self.encode(ui_value)).to_bytes(self.nbytes, "little", signed=True)

    def from_bytes(self, raw: bytes) -> float:
        v = int.from_bytes(raw[: self.nbytes], "little", signed=(self.nbytes == 4))
        return self.decode(v)


# --- encoders following the disassembled formulas ---
def _lut_enc(lut_name: str, norm: Callable[[float], float]):
    lut = _LUTS[lut_name]
    return lambda ui: lut[round(_clamp01(norm(ui)) * 255)]


def _lut_dec(lut_name: str, denorm: Callable[[float], float]):
    lut = _LUTS[lut_name]
    return lambda coeff: denorm(_nearest_idx(lut, coeff) / 255.0)


# Compressor (effIdx 0) — fully verified
COMPRESSOR_PARAMS = {
    "threshold": Param("threshold", 1, 4, "dB",
                       _lut_enc("CompThreshold", lambda t: -t / 60.0),
                       _lut_dec("CompThreshold", lambda n: -n * 60.0)),
    "shape":     Param("shape", 2, 4, "ratio",
                       lambda s: round((_clamp01((s - 1.5) / 3.0)) * 255),
                       lambda b: b / 255.0 * 3.0 + 1.5),
    "attack":    Param("attack", 3, 4, "ms",
                       _lut_enc("CompAttack", lambda a: math.log10(max(a, 0.1) / 0.1) * 0.5),
                       _lut_dec("CompAttack", lambda n: 0.1 * 10 ** (2 * n))),
    "release":   Param("release", 4, 4, "ms",
                       _lut_enc("CompRelease", lambda r: math.log10(max(r, 5.0) / 5.0) / math.log10(40)),
                       _lut_dec("CompRelease", lambda n: 5.0 * 10 ** (n * math.log10(40)))),
    "gain":      Param("gain", 5, 4, "dB",
                       _lut_enc("CompGain", lambda g: g / 9.0),
                       _lut_dec("CompGain", lambda n: n * 9.0)),
}

# Ranges (for validation / CLI)
COMPRESSOR_RANGES = {
    "threshold": (-60.0, 0.0), "shape": (1.5, 4.5),
    "attack": (0.1, 10.0), "release": (5.0, 200.0), "gain": (0.0, 9.0),
}

# Aural Exciter (effIdx 2): par1=Mix (AEMix LUT), par2=Tune (AETune_a LUT).
# par0=enabled. par3 (=a constant, e.g. 31) is not exposed. Verified live.
AURAL_EXCITER_PARAMS = {
    "mix":  Param("mix", 1, 4, "%",
                  _lut_enc("AEMix", lambda m: m / 100.0),
                  _lut_dec("AEMix", lambda n: n * 100.0)),
    "tune": Param("tune", 2, 4, "Hz",
                  _lut_enc("AETune_a", lambda f: (f - 600.0) / 4400.0),
                  _lut_dec("AETune_a", lambda n: 600.0 + n * 4400.0)),
}
AURAL_EXCITER_RANGES = {"mix": (0.0, 100.0), "tune": (600.0, 5000.0)}

# Big Bottom (effIdx 3): par1=Drive. ToBBDrive shares the LUT with AEMix (0..100%).
BIG_BOTTOM_PARAMS = {
    "drive": Param("drive", 1, 4, "%",
                   _lut_enc("AEMix", lambda d: d / 100.0),
                   _lut_dec("AEMix", lambda n: n * 100.0)),
}
BIG_BOTTOM_RANGES = {"drive": (0.0, 100.0)}

# Noise Gate (effIdx 1) — Q31 params, computed inline in firmware (no LUT).
# Decoded from disassembly + round-trip verified on the device:
#   threshold (par1): dB, coeff = 10^(dB/20) * 2^31
#   times (par3, par4): ms, coeff = (1 - exp(-1/(t_s * 48000))) * 2^31
# par2/par5/par6: formula ambiguous — only available as raw.
_Q31 = 2 ** 31
_FS = 48000.0


def _db_q31_enc(db):
    return max(0, min(_Q31 - 1, round(10 ** (db / 20.0) * _Q31)))


def _db_q31_dec(c):
    return 20.0 * math.log10(max(c, 1) / _Q31)


def _time_q31_enc(ms):
    x = 1.0 - math.exp(-1.0 / ((max(ms, 0.01) / 1000.0) * _FS))
    return max(0, min(_Q31 - 1, round(x * _Q31)))


def _time_q31_dec(c):
    x = c / _Q31
    return (-1.0 / (_FS * math.log(1 - x))) * 1000.0 if 0 < x < 1 else 0.0


NOISE_GATE_PARAMS = {
    "threshold": Param("threshold", 1, 4, "dB", _db_q31_enc, _db_q31_dec),
    "attack":    Param("attack", 3, 4, "ms", _time_q31_enc, _time_q31_dec),
    "release":   Param("release", 4, 4, "ms", _time_q31_enc, _time_q31_dec),
}
NOISE_GATE_RANGES = {"threshold": (-100.0, 0.0), "attack": (1.0, 2000.0), "release": (1.0, 4000.0)}

PARAMS_BY_EFFECT = {
    Effect.COMPRESSOR: COMPRESSOR_PARAMS,
    Effect.NOISE_GATE: NOISE_GATE_PARAMS,
    Effect.AURAL_EXCITER: AURAL_EXCITER_PARAMS,
    Effect.BIG_BOTTOM: BIG_BOTTOM_PARAMS,
}
RANGES_BY_EFFECT = {
    Effect.COMPRESSOR: COMPRESSOR_RANGES,
    Effect.NOISE_GATE: NOISE_GATE_RANGES,
    Effect.AURAL_EXCITER: AURAL_EXCITER_RANGES,
    Effect.BIG_BOTTOM: BIG_BOTTOM_RANGES,
}


def get_params(mic, effect: Effect) -> dict:
    """Read all supported parameters of an effect as UI values."""
    out = {"enabled": mic.get_effect_enabled(effect)}
    for name, p in PARAMS_BY_EFFECT.get(effect, {}).items():
        raw = mic.dsp_get_param(effect, p.par_idx)
        out[name] = None if raw is None else round(p.from_bytes(raw), 3)
    return out


def set_params(mic, effect: Effect, **values) -> dict:
    """Set parameters by name (UI values). Returns {name: ok}.
    The special name 'enabled' -> bool. Values are clamped to their range."""
    params = PARAMS_BY_EFFECT.get(effect, {})
    ranges = RANGES_BY_EFFECT.get(effect, {})
    result = {}
    for name, val in values.items():
        if name == "enabled":
            result[name] = mic.set_effect(effect, bool(val))
            continue
        p = params.get(name)
        if p is None:
            result[name] = False
            continue
        lo, hi = ranges.get(name, (val, val))
        val = max(lo, min(hi, float(val)))
        result[name] = mic.dsp_set_param(effect, p.par_idx, p.to_bytes(val))
    return result
