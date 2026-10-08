# rode-podmic-usb

An open-source Linux configuration tool for the **RØDE PodMic USB** microphone —
a drop-in replacement for RØDE Central, which has no Linux version.

It talks to the microphone directly over USB HID (`/dev/hidraw`); the protocol was
reverse-engineered from the device and from the official RØDE Central Android app.
No drivers or vendor software required. Protocol notes: [`docs/protocol.md`](docs/protocol.md),
reverse-engineering details: [`docs/apk_analysis.md`](docs/apk_analysis.md).

Verified on firmware 1.19 (`19f7:004a`).

## Features

- **APHEX DSP effects** with real UI units, read and write:
  - **Compressor** — threshold, ratio (shape), attack, release, gain
  - **Noise Gate** — threshold, attack, release
  - **Aural Exciter** — mix, tune
  - **Big Bottom** — drive
- **Device controls** — high-pass filter (60 Hz), input mute, direct monitoring + mix
- **Input gain** in dB via ALSA (the mic's own UAC preamp, 22..63 dB)
- **Live input level meter** (dBFS)
- **Headphone monitoring** — hardware direct monitor + software loopback (PipeWire)
- **Profiles** — save/load the full configuration as presets
- A **CLI** and a **Tkinter GUI**; no runtime dependencies beyond the standard library

## Requirements

- Linux with `hidraw` (standard kernel)
- Python 3.9+
- `amixer` (alsa-utils) for input gain; `pactl` (PipeWire/PulseAudio) for loopback monitoring

## Install

```bash
# one-time: non-root access to the device
sudo cp udev/70-rode-podmic-usb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=hidraw
# (your user must be in the 'plugdev' group)

pip install .
```

## Usage

```bash
rode-podmic info                       # detected device + current state
rode-podmic gui                        # configuration window (Tkinter)
rode-podmic meter                      # live level meter (dBFS, Ctrl+C to quit)

# DSP effects
rode-podmic get compressor             # read parameters (UI values)
rode-podmic set compressor on          # enable/disable an effect
rode-podmic tune compressor --gain 4 --threshold -20 --attack 1 --release 50
rode-podmic tune noise_gate --threshold -45 --attack 20 --release 500
rode-podmic tune aural_exciter --mix 30 --tune 4000
rode-podmic tune big_bottom --drive 60

# device settings
rode-podmic device --hpf on --gain 45 --mute off   # gain in dB

# hear the mic in your headphones (PipeWire loopback)
rode-podmic monitor on
rode-podmic monitor off

# presets (stored in ~/.config/rode-podmic/profiles/)
rode-podmic profile save vocal
rode-podmic profile load vocal
rode-podmic profile list
```

### Running the GUI

The GUI uses Tkinter (standard library; on Debian/Ubuntu install it with
`sudo apt install python3-tk`). For the modern flat dark theme, install the
optional extra:

```bash
pip install ".[gui]"     # adds ttkbootstrap; without it the GUI still runs (plain ttk)
rode-podmic gui
```

> **conda / anaconda users:** their bundled Tcl/Tk is built **without Xft**, so
> the GUI renders with blocky bitmap fonts no matter what. Run the GUI with a
> system Python that has Xft-enabled Tk instead (Linux: `sudo apt install
> python3-tk`; macOS/Windows: the python.org build). A venv that inherits the
> system Tk works well:
>
> ```bash
> python3 -m venv --system-site-packages .venv   # system python3, NOT conda
> .venv/bin/pip install ".[gui]"
> .venv/bin/rode-podmic gui
> ```
>
> The GUI prints a warning to stderr if it detects an Xft-less Tk.

Effects: `compressor`, `noise_gate`, `aural_exciter`, `big_bottom`.
- **compressor**: `--threshold` (−60..0 dB), `--shape` (1.5..4.5), `--attack` (0.1..10 ms), `--release` (5..200 ms), `--gain` (0..9 dB)
- **noise_gate**: `--threshold` (dB), `--attack` (ms), `--release` (ms)
- **aural_exciter**: `--mix` (0..100 %), `--tune` (600..5000 Hz)
- **big_bottom**: `--drive` (0..100 %)
- all: `--enabled on/off`

## As a library

```python
from rode_podmic import PodMicUSB, Effect, params

with PodMicUSB() as mic:
    print(params.get_params(mic, Effect.COMPRESSOR))     # {'gain': 2.4, 'threshold': -26.6, ...}
    params.set_params(mic, Effect.COMPRESSOR, gain=3.0)  # UI values, clamped to range
    mic.set_hpf(True)
```

## Status

Done:

- [x] Device discovery + udev access
- [x] DSP read-back (granular GET) and write for all four effects, verified by round-trip
- [x] Live dBFS level meter
- [x] HPF, input mute, direct monitoring + mix (PodMic parameter channel)
- [x] Input gain via ALSA
- [x] Monitoring: hardware direct + PipeWire loopback to any output
- [x] Tkinter GUI
- [x] Configuration profiles (CLI + GUI)

Open:

- [ ] Noise gate par2/5/6 (range/hysteresis?) — formula still ambiguous; available via the raw API

## Disclaimer

Unofficial and not affiliated with or endorsed by RØDE / Freedman Electronics.
"RØDE" and "PodMic" are trademarks of their respective owner. Use at your own risk;
the protocol was reverse-engineered for interoperability with hardware you own.

## License

MIT.
