---
name: Podtune
description: A restrained native Linux microphone test bench.
colors:
  dark-background: "#17191c"
  dark-surface: "#1d1f23"
  dark-foreground: "#f0f1f3"
  dark-secondary: "#b8b9bb"
  dark-border: "#3e4043"
  dark-accent: "#d0b675"
  light-background: "#f4f5f7"
  light-surface: "#fbfcfe"
  light-foreground: "#20242a"
  light-secondary: "#575a5f"
  light-border: "#cecfd2"
  light-accent: "#765b1f"
  omarchy-observed-background: "#0b170e"
  omarchy-observed-surface: "#0e1d11"
  omarchy-observed-foreground: "#dcd6bc"
  omarchy-observed-secondary: "#a6a48f"
  omarchy-observed-border: "#31392d"
  omarchy-observed-accent: "#64a472"
  accent-ink-dark: "#101214"
  accent-ink-light: "#ffffff"
  signal-high-dark: "#e5a083"
  signal-high-light: "#a33815"
  error-border-dark: "#cf987b"
  error-border-light: "#8d3c19"
  icon-background: "#24272c"
  transparent: "transparent"
typography:
  title-window:
    fontFamily: "sans-serif"
    fontSize: "28px"
    fontWeight: 600
  title-section:
    fontFamily: "sans-serif"
    fontSize: "17px"
    fontWeight: 600
  value-peak:
    fontFamily: "sans-serif"
    fontSize: "16px"
    fontWeight: 600
  body:
    fontFamily: "sans-serif"
    fontSize: "14px"
  label-strong:
    fontFamily: "sans-serif"
    fontSize: "14px"
    fontWeight: 600
  label-control:
    fontFamily: "sans-serif"
    fontSize: "13px"
  label-secondary:
    fontFamily: "sans-serif"
    fontSize: "12px"
  hint:
    fontFamily: "sans-serif"
    fontSize: "12px"
    lineHeight: 1.2
  label-scale:
    fontFamily: "sans-serif"
    fontSize: "11px"
rounded:
  control: "4px"
  meter: "2px"
spacing:
  flush: "0px"
  compact: "4px"
  annotation: "6px"
  preset-gap: "8px"
  group-gap: "10px"
  inset: "12px"
  waveform-inset: "16px"
  paired-controls: "18px"
  window-inset: "24px"
components:
  button-native:
    typography: "{typography.body}"
  button-record:
    backgroundColor: "{colors.dark-accent}"
    textColor: "{colors.accent-ink-dark}"
    typography: "{typography.label-strong}"
    rounded: "{rounded.control}"
  button-preset:
    backgroundColor: "{colors.transparent}"
    textColor: "{colors.dark-foreground}"
    typography: "{typography.label-strong}"
    rounded: "{rounded.control}"
    padding: "{spacing.inset}"
  button-preset-hover:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-foreground}"
    typography: "{typography.label-strong}"
    rounded: "{rounded.control}"
    padding: "{spacing.inset}"
  button-preset-selected:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-foreground}"
    typography: "{typography.label-strong}"
    rounded: "{rounded.control}"
    padding: "{spacing.inset}"
  value-slider:
    height: "32px"
  value-readout:
    textColor: "{colors.dark-secondary}"
    typography: "{typography.label-secondary}"
  toggle-control:
    typography: "{typography.label-control}"
  preset-name:
    typography: "{typography.body}"
  error-banner:
    backgroundColor: "{colors.dark-surface}"
    textColor: "{colors.dark-foreground}"
    typography: "{typography.label-control}"
    rounded: "{rounded.control}"
    padding: "{spacing.inset}"
  waveform-panel:
    backgroundColor: "{colors.dark-surface}"
    rounded: "{rounded.control}"
    padding: "{spacing.waveform-inset}"
    height: "128px"
  waveform-panel-compact:
    backgroundColor: "{colors.dark-surface}"
    rounded: "{rounded.control}"
    padding: "{spacing.waveform-inset}"
    height: "100px"
  level-meter:
    backgroundColor: "{colors.dark-border}"
    rounded: "{rounded.meter}"
    height: "12px"
---

# Design System: Podtune

## Overview

**Creative North Star: "Restrained instrument surface"**

Podtune uses a compact native Linux Qt Quick interface for microphone controls and local voice tests.
`src/main.cpp` selects Qt Quick Controls Material.
The approved surface brief establishes one theme accent and a measured waveform beside the hardware controls.
The built interface keeps clear labels, aligned values, and separate scroll areas.

This document records the built choices rather than the requested capability list.
`PRODUCT.md` supplies the product constraints.
`.impeccable/surfaces/main.md` supplies the approved visual direction.
The QML components and `src/theme.cpp` supply the visual authority.
`src/audio.cpp`, `src/backend.cpp`, and `src/protocol.cpp` establish the interaction states.

**Key Characteristics:**
- One live theme accent identifies the record action, selected presets, and measured signal.
- Thin rules and tonal fills separate compact control groups.
- Numeric controls pair clear labels with right-aligned values and units.
- Hardware failures remain visible beside independent audio test actions.
- Native controls retain Qt Material behavior unless QML defines a custom treatment.

## Colors

The fixed palettes pair neutral surfaces with a gold accent, while Omarchy supplies its current background, foreground, and accent.
The frontmatter records exact color values.
Component color references describe Dark mode, which is the initial default.
The sidecar records the runtime theme bindings for all modes.

### Primary

- `dark-accent` supplies the muted gold accent in Dark mode.
- `light-accent` supplies the darker gold accent in Light mode.
- `omarchy-observed-accent` records the green accent in the inspected Omarchy theme and review image.
- The accent fills the record button, waveform bars, and normal level meter.
- The accent also identifies preset selection and keyboard focus.

### Neutral

| Runtime role | Dark token | Light token | Observed Omarchy token |
| --- | --- | --- | --- |
| Window fill | `dark-background` | `light-background` | `omarchy-observed-background` |
| Raised tonal fill | `dark-surface` | `light-surface` | `omarchy-observed-surface` |
| Main text | `dark-foreground` | `light-foreground` | `omarchy-observed-foreground` |
| Hints and values | `dark-secondary` | `light-secondary` | `omarchy-observed-secondary` |
| Rules and panel borders | `dark-border` | `light-border` | `omarchy-observed-border` |

`surface()` uses `QColor(background()).lighter(124)` in dark themes and `lighter(103)` in light themes.
`secondary()` mixes foreground and background channels with weights `0.74` and `0.26`.
`border()` uses weights `0.18` and `0.82`.
Both mixtures use `QColor::fromRgbF(...).name()` to produce the final hex value.
These are Qt color operations, not CSS color functions.

### Signal and error states

- `signal-high-dark` and `signal-high-light` mark a live peak above `-3 dBFS`.
- `error-border-dark` and `error-border-light` outline the shared hardware and audio error banner.
- Both pairs follow `theme.dark`, including Omarchy mode.
- The icon uses `icon-background` and the fixed `dark-accent` color.

### Accent foreground

`accentForeground()` linearizes each normalized accent channel.
For a channel `c <= 0.04045`, it uses `c / 12.92`.
For other channels, it uses `pow((c + 0.055) / 1.055, 2.4)`.
It calculates luminance as `0.2126 * R + 0.7152 * G + 0.0722 * B`.

Luminance above `0.179` selects `accent-ink-dark`.
All other values select `accent-ink-light`.
Dark mode and the observed Omarchy theme select dark ink.
Light mode selects light ink.
This rule selects between two fixed inks and does not establish a whole-interface contrast guarantee.

### Live Omarchy behavior

The theme reads `~/.local/state/omarchy/current/theme/colors.toml`.
It accepts quoted six-digit hex values for `background`, `foreground`, and `accent`.
It ignores the file's `mode` field and other palette keys.
`QColor(background).lightnessF() < 0.5` determines dark styling.

The file watcher also watches available parent directories and the current theme path.
An `80 ms` debounce combines file and directory changes before reload.
`QSettings` stores the selected mode under `theme`.

The `omarchy-observed-*` tokens describe the inspected theme, not permanent Omarchy colors.
Initial imported colors match the fixed Dark palette.
Missing keys in a readable file use those same fallbacks.
An unreadable file retains the previous imported colors.

**The Live Theme Rule.** Bind custom controls to `theme` roles so Dark, Light, and Omarchy keep the same hierarchy.

## Typography

The window uses Qt's generic `sans-serif` family.
The app bundles no font and names no concrete fallback family.
Omarchy changes colors, not the font family.
The frontmatter records QML pixel sizes and explicit weights.
Qt supplies unspecified font metrics and native control typography.

| Token | Built use |
| --- | --- |
| `title-window` | The Podtune title |
| `title-section` | Column titles and hardware group headings |
| `value-peak` | The live peak value |
| `body` | The window default, native buttons, preset field, and help text |
| `label-strong` | Preset names and the record button |
| `label-control` | Identity, numeric control labels, switches, guidance, errors, and take names |
| `label-secondary` | Values, preset descriptions, peak labels, RMS text, and footer text |
| `hint` | Wrapped guidance with a proportional line height of `1.2` |
| `label-scale` | Level meter tick labels |

`Font.DemiBold` supplies the explicit weight `600`.
The source defines no display face, letter spacing, or global line-height scale.
Take names and footer notices use right elision.
Hints, descriptions, errors, and dialog text wrap by words.

## Layout

The window starts at `1280 × 860` and enforces a minimum size of `1040 × 720`.
These dimensions use QML coordinate units.
The window keeps three columns at the supported sizes.
The source defines no stacked layout or mobile breakpoint.

| Region | Built dimensions and behavior |
| --- | --- |
| Outer layout | `24` margin and `16` vertical spacing |
| Header | `4` title spacing and a `136` implicit-width theme selector |
| Main row | `24` spacing, with two `1`-wide vertical rules |
| Preset column | Preferred width `196`, maximum width `210`, and `12` group spacing |
| Controls column | Minimum width `300`, preferred width `410`, and horizontal fill |
| Controls scroll content | Width `availableWidth - 14` and `10` group spacing |
| Voice test column | Minimum width `290`, preferred width `350`, and `10` group spacing |
| Footer | Preferred height `28`, with `28`-high Undo and Redo buttons |
| Help dialog | Centered, modal, and `520` wide |
| Exit dialog | Centered, modal, and `400` wide |

Preferred column widths guide Qt's layout calculation and do not promise fixed rendered widths.
The preset list, controls, and takes list scroll independently and clip their content.
The Headphones button scrolls the controls to the headphone group.
Controls remain above headphone settings within the same scroll area.

The waveform panel uses the frontmatter's normal height at window heights of `820` or more.
It uses the compact height below `820`.
This height change is the only authored size breakpoint.

The spacing scale records reused steps from `0` through `24`.
Preset descriptions use `6` spacing, preset cards use `8` list spacing, and take rows use `4` spacing.
Paired attack and release controls use `18` spacing.
Numeric readouts reserve a minimum width of `85`.
Error banners use text height plus `24` for their total height.

## Elevation & Depth

Custom surfaces use tonal fills and thin borders rather than authored shadows.
The source adds no custom shadow effect or visual animation.
Qt Material supplies standard control effects and state behavior.
The source does not define their shadow metrics.
The busy indicator and footer notice expose hardware work without changing the column structure.

## Shapes

Custom preset buttons, the record button, the error banner, and the waveform panel use `rounded.control`.
The level meter uses `rounded.meter`.
Panel borders and divider rules use a width of `1`.
Focused preset buttons and the record button use a border width of `2`.
Native buttons, sliders, switches, fields, and dialogs retain Qt Material shapes unless QML overrides them.

`pkgbuild/podtune.svg` is the only authored icon.
It uses a `64 × 64` viewBox, a background radius of `12`, and a microphone capsule radius of `8`.
Its rounded strokes use a width of `3`.
`src/resources.qrc` packages the SVG and no raster image.
The PNG files under `.impeccable/review/` are review captures, not shipping assets.

## Components

### Native buttons and dialogs

Native text buttons provide Refresh, Help, Save preset, Check levels, Play, and dialog actions.
Flat buttons provide Headphones, Open folder, Trash, Undo, and Redo.
The source retains their Qt Material hover, focus, pressed, and disabled treatments.
The theme selector exposes the accessible name `Theme mode`.
The preset field exposes `New preset name` and limits input to `64` characters.

The help dialog describes the level check and voice test sequence.
The exit dialog appears when the user quits during a record or hardware command.
Accepted exit saves the current take and waits for the hardware thread through object cleanup.

### Preset buttons

Preset buttons combine a strong name, a wrapped description, and an outlined surface.
Their default fill is transparent.
Hover and selection use `theme.surface`.
Selection uses a `1`-wide accent border, while keyboard focus uses a `2`-wide accent border.
Accessible names and descriptions come from preset data.
The list starts without a selected preset.
The selected outline marks the clicked row and does not confirm successful hardware application.

Preset buttons disable while the backend is busy.
Factory presets preserve gain, computer playback volume, and monitor settings.
Save preset requires a nonempty name, available values, and an idle backend.
The backend rejects duplicate names and pending changes at save time.

### Numeric controls and switches

`ValueControl.qml` pairs a label with a right-aligned readout and a native slider.
The slider uses the configured range, step, decimal count, and unit.
Its accessible name matches the label, and its description identifies the hardware unit.
Its preview includes pending and in-flight values until the hardware read-back replaces them.
The backend combines slider requests with a `160 ms` debounce.
Supported sliders remain enabled during hardware work so later requests can enter the queue.

`ToggleControl.qml` uses a native Switch with its label as the accessible name.
Its checked state follows the verified backend value.
Switches disable when unsupported or busy.

| Numeric control | Range | Step | Decimals | Unit |
| --- | --- | --- | --- | --- |
| Input gain | `22` to `63` | `1` | `0` | `dB` |
| Compressor threshold | `-60` to `0` | `0.5` | `1` | `dB` |
| Compressor ratio | `1.5` to `4.5` | `0.1` | `1` | `:1` |
| Compressor attack | `0.1` to `10` | `0.1` | `1` | `ms` |
| Compressor release | `5` to `200` | `1` | `0` | `ms` |
| Makeup gain | `0` to `9` | `0.1` | `1` | `dB` |
| Low-frequency drive | `0` to `100` | `1` | `0` | `%` |
| Presence mix | `0` to `100` | `1` | `0` | `%` |
| Presence frequency | `600` to `5000` | `25` | `0` | `Hz` |
| Gate threshold | `-100` to `0` | `1` | `0` | `dB` |
| Gate attack | `1` to `2000` | `1` | `0` | `ms` |
| Gate release | `1` to `4000` | `1` | `0` | `ms` |
| Computer playback volume | `-60` to `0` | `1` | `0` | `dB` |
| Monitor mix | `0` to `255` | `1` | `0` | `/ 255` |

### Genuine unavailable hardware states

Each hardware read sets `backend.supported` for that control.
Unsupported numeric controls show `Unavailable`, use secondary label color, and disable their sliders.
Unsupported switches disable without claiming an available off state.
The shared error banner displays actual backend and audio errors as separate lines.
An error banner does not disable independent audio actions.

The HID protocol accepts the PodMic USB device `19f7:004a` with firmware `1.19`.
Other firmware lacks a verified DSP map.
HID permission failures leave ALSA gain and computer playback controls available when their reads succeed.
Audio tests can operate without HID access when Qt exposes the PodMic audio input.

Missing audio input or headphone output produces a genuine error rather than a fallback device.
The noise gate has parameter controls but no verified independent enable switch.
The physical microphone dial controls headphone output level.
Monitor mix displays the raw device value because its direction remains unresolved.

**The Verified Availability Rule.** Expose hardware controls only through read-confirmed support and preserve genuine unavailable states.

### Measured waveform and level meter

The waveform shows measured interval peaks, not a decorative trace or a saved-take waveform.
The audio meter updates every `50 ms` and retains at most `100` peaks.
This produces a rolling history of approximately `5` seconds.
The canvas reserves `100` horizontal positions and aligns partial history to the right.
Each bar uses `sqrt(peak) * (canvasHeight - 8)` with a minimum height of `1`.
The waveform uses symmetric bars around a `1`-wide center rule.

Before a level check, the panel shows its center rule and an explanatory prompt.
While capture is active, the prompt disappears and peak and RMS values show one decimal in `dBFS`.
Silence produces minimum-height measured bars and the numeric floor `-90 dBFS`.

Stop levels resets the meter values and restores the inactive prompt.
It retains the last waveform samples behind that prompt.
A new level check clears the history.
Playback does not drive this waveform or the input meter.

The meter fills according to `clamp((peakDb + 60) / 60, 0, 1)`.
Its ticks mark `-60`, `-18`, `-6`, and `0`.
A peak above `-3 dBFS` uses the high-signal color.
That color warns about headroom and does not itself assert clipped samples.

| Peak condition | Guidance state |
| --- | --- |
| Capture inactive | Start a level check |
| Above `-3 dBFS` | Too high |
| Below `-45 dBFS` | No speech or low signal |
| From `-45` to below `-18 dBFS` | Low signal |
| From `-18` through `-6 dBFS` | Target range |
| Above `-6` through `-3 dBFS` | High signal |

The take statistics count clipped finite samples when `abs(sample) >= 0.999`.
Level guidance does not score tone, room noise, distortion, or comfort.

**The Measured Signal Rule.** Derive waveform, levels, guidance, and clipped-sample counts from captured audio rather than invented activity.

### Local voice test and takes

Check levels starts or stops live input capture.
Record test stops playback and starts capture when needed.
The record button uses `theme.accentForeground` and a `2`-wide foreground border on keyboard focus.
Press uses `Qt.darker(theme.accent, 1.15)`.

During a record, the label shows Stop and the elapsed whole-second value.
The meter timer stops each take when elapsed time reaches `60` seconds.
Stop saves the take and leaves the live level check active.

Each take stores mono `16`-bit PCM WAV audio and JSON measurements in the local recordings directory.
Capture requests `48 kHz` mono float audio and uses the device's preferred format if that request lacks support.
The saved WAV uses the actual capture sample rate.
The default directory is `QStandardPaths::GenericDataLocation + "/podtune/recordings"`.

Take rows show a time-based name, duration, peak, and clipped-sample count when metadata exists.
WAV files without metadata show `WAV voice test`.
The list places the newest timestamp filenames first.

Play routes the take to the PodMic headphone output.
The active take's Play button becomes Stop.
Play and Trash disable during a record.
Trash moves the WAV and available measurement file to the desktop trash.
Open folder opens the local recordings directory.
The empty list prompts a reference take and a second take for comparison.
The source implements manual comparison through playback and defines no A/B comparison control.

### Focus and shortcuts

Qt controls retain their native keyboard focus and activation behavior.
The QML defines no custom tab order.
Custom preset and record buttons add visible focus borders.
Sliders, switches, preset buttons, the theme selector, and the preset field expose explicit accessible names.
Take buttons identify their action and the take name in their accessible names.

| Shortcut | Action |
| --- | --- |
| `?` | Open help |
| `Q` | Quit or open the active-task exit dialog |
| `Space` | Start or stop a record |
| `Ctrl+Z` | Undo a verified hardware change |
| `Ctrl+Shift+Z` | Redo a hardware change |
| `Ctrl+R` | Refresh hardware state |

All shortcuts use `Qt.ApplicationShortcut` and suspend while either app dialog is open.
TextInput or TextEdit focus blocks all six shortcuts so text input keeps its own keys.
Any Control focus also blocks Space so a focused control keeps its native activation key.
Backend guards prevent Undo, Redo, and Refresh from interrupting busy hardware work.

### Evidence and open facts

The three review images confirm the fixed palettes and the observed Omarchy palette at `1280 × 860`.
They show a real HID permission failure, available input gain, disabled DSP controls, and an inactive voice test.
The packaged resources include no shipping raster assets.
QML is native Linux source, so the HTML and CSS detector does not apply.
The inspected test source covers signal statistics, WAV headers, protocol values, and optional real-device record and playback.
This documentation pass does not establish a fresh hardware or runtime accessibility test result.

The sidecar records native component metadata and QML source references because browser snippets cannot represent this native implementation.
The context loader misclassifies `Native Linux desktop.` as web.
This document follows the QML implementation's native Linux platform.

Power-cycle persistence and monitor mix direction remain open hardware facts.
The generic font's resolved family and inherited Qt control metrics depend on the runtime environment.
The custom waveform and meter define no explicit accessible role or value.
The source defines no explicit live announcement for errors or level changes.
These accessibility gaps remain implementation facts, not reusable design rules.
Minimum-size behavior, focus traversal, and screen-reader output require runtime verification beyond the inspected review images.

## Do's and Don'ts

### Do:

- Do bind custom fills, text, and borders to the live theme roles.
- Do retain native Qt control behavior and explicit accessible names.
- Do show real support, read-back values, units, and hardware errors.
- Do keep numeric readouts aligned and reserve their minimum width.
- Do derive audio feedback from measured samples and keep voice tests local.
- Do distinguish high signal level from clipped-sample counts and subjective voice quality.

### Don't:

- Don't freeze the observed Omarchy palette into the live theme implementation.
- Don't replace measured audio feedback with invented waveform activity.
- Don't present unavailable controls as verified hardware settings.
- Don't add a noise gate enable switch without a verified protocol operation.
- Don't label monitor mix endpoints as microphone or computer without hardware evidence.
- Don't claim power-cycle persistence, whole-app accessibility, or additional platform support from these source records.
