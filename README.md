# Podtune

Podtune controls the RØDE PodMic USB from a native C++ and Qt 6 app.
It includes onboard sound controls, voice presets, and local record and playback tests.

## Start the app

To build the app, run this command from the project directory:

```sh
bin/build
```

To start the app, run:

```sh
build/podtune
```

The layout adapts to the window size.
Below 960 pixels wide, the app shows one scrolling column.

The build uses `qmake6`, `make`, Qt 6, and `alsa-lib`.
The binary embeds the QML files, presets, and DSP coefficient tables.
Python is not a runtime dependency.

## Enable device access

If the app cannot open the HID device, install its device-specific access rule:

```sh
bin/enable-device-access
```

The command requests your sudo password.
After the command completes, press `Ctrl+R` to read the hardware state again.
If access still fails, unplug the microphone and reconnect it.

## Install the app

To install the Arch package and app launcher entry, run:

```sh
bin/install
```

The command requests your sudo password.
The package includes a udev rule for USB device `19f7:004a`.
Open **Podtune** from the app launcher after the install.

## Tune your voice

1. Connect headphones to the PodMic USB.
2. Select **Check levels**.
3. Speak at your normal volume and distance.
4. Adjust **Input gain** for speech peaks near −18 to −6 dBFS.
5. Select **Record test** to make a reference take.
6. Select **Stop** to save the take.
7. Choose a preset, or adjust **Warmth**, **Presence**, or **Leveling**.
8. Record another take with the same phrase.
9. Select the play button of each take to compare the takes through the microphone headphones.

Each take stops at 60 seconds.
The app saves mono 16-bit PCM WAV files.
The live waveform shows peak amplitude over the last five seconds.
The app reports peak level, RMS level, and clipped sample counts.
These measurements describe signal level. They do not judge tone, room noise, or voice quality.

The playback path uses the PodMic USB output.
The app reports an error if this output is unavailable.

## Controls

The main view groups the tone controls into three scales from 0 to 100.

- **Warmth** sets the APHEX Big Bottom drive.
- **Presence** sets the APHEX Aural Exciter mix and tune.
- **Leveling** sets the compressor threshold, ratio, and makeup gain.

A scale at 0 turns its effect off.
Select **Advanced** to adjust each hardware control directly.

| Control | Hardware range |
| --- | --- |
| Input gain | 22 to 63 dB |
| High-pass filter | Off or 60 Hz |
| Input mute | Off or on |
| Compressor | Enable, threshold, ratio, attack, release, and makeup gain |
| APHEX Big Bottom | Enable and drive |
| APHEX Aural Exciter | Enable, mix, and tune |
| Noise gate | Threshold, attack, and release |
| Direct monitor | Off or on |
| Computer playback volume | −60 to 0 dB |
| Monitor mix | Raw device value from 0 to 255 |

The physical dial controls the headphone output level.
The computer playback control adjusts the USB playback stream.
The app does not claim a verified monitor-mix direction.

The noise gate has no verified independent enable command.
The app does not expose the gate's unknown parameters.
The APHEX tone controls provide presence and bass effects. They are not a parametric EQ.

The app changes onboard DSP settings through HID reports.
Each write requires an ACK and a matching read-back.
The standard gain and playback controls use ALSA.
The app requires firmware `1.19` for the current DSP map.
Other firmware versions retain the standard ALSA controls.

The current USB session retains onboard settings after the app closes.
Power-cycle persistence needs a separate hardware check.
The app has no firmware update or factory reset command.

## Presets and themes

- **Natural** disables the compressor and APHEX tone effects.
- **Warm podcast** adds bass and gentle compression.
- **Clear calls** adds presence and stronger compression.
- **Voice-over** uses moderate compression and restrained tone effects.

Factory presets retain the input gain, headphone volume, monitor settings, and existing gate parameters.
To save the current readable hardware state, select **Save current…**.
Enter a name, then select **Save**.
The app saves presets atomically.

The theme switch includes **Dark**, **Light**, and **Omarchy**.
Omarchy mode follows `~/.local/state/omarchy/current/theme/colors.toml` live.

## Local files

Qt uses the standard XDG directories.

- Settings and saved presets: `~/.config/podtune/`.
- Voice tests and measurements: `~/.local/share/podtune/recordings/`.

Use **Open folder** to inspect the voice tests.
Use **Trash** to move a take to the system trash.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| `Space` | Start or stop a voice test |
| `Ctrl+Z` | Undo a verified hardware change |
| `Ctrl+Shift+Z` | Redo a hardware change |
| `Ctrl+R` | Read the hardware state again |
| `?` | Show help |
| `Esc` | Close the help or the **Advanced** panel |
| `Q` | Quit |

## Verify the app

The connected PodMic USB uses firmware `1.19`.
All 20 supported controls pass a reversible write and read-back test.
The final readable hardware state matches the original state.
The full test run passes 13 checks, including real microphone record and playback.

To run the codec, preset, signal, and WAV tests, run:

```sh
bin/test
```

To test record and playback on the connected microphone, run:

```sh
PODTUNE_HARDWARE_TEST=1 bin/test
```

This test captures 1.2 seconds into a temporary directory.
It plays the test through the PodMic USB and removes the temporary files afterward.

To report the readable hardware controls, run:

```sh
build/podtune --diagnose
```

To check the microphone audio stream without a saved take, run:

```sh
build/podtune --audio-check
```

To verify an input gain change and restore the previous value, run:

```sh
build/podtune --verify-control gain
```

The same command accepts control keys from `src/protocol.cpp`.

## Protocol reference

The control map and coefficient tables come from the MIT-licensed
[RodePodMicUSB-linux project](https://github.com/borsuk85/RodePodMicUSB-linux).
See `third_party/README.md` for the reference revision.
The upstream license remains in `third_party/rode-protocol/LICENSE`.

Podtune implements the transport and user interface in C++ and Qt 6.
The transport checks the report ID, selector, ACK, and minimum reply length.
It runs hardware commands on a worker thread to keep the interface responsive.
