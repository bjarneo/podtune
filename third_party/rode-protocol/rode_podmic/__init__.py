"""Control the RØDE PodMic USB on Linux (DSP + device parameters)."""
from .device import PodMicUSB, Effect, EFFECTS, PodMicParam, find_device_path
from . import params, alsa, profiles

__all__ = ["PodMicUSB", "Effect", "EFFECTS", "PodMicParam",
           "find_device_path", "params", "alsa", "profiles"]
__version__ = "0.7.0"
