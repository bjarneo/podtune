# Analysis of the RØDE Central Mobile app (`com.rode.rodecentralmobile` v2.0.112)

APK pulled from a phone (`adb pull`, original signed). Split APK:
`base.apk` + `split_config.arm64_v8a.apk` (native libs) + resources.

## Architecture

- **Flutter app** — UI logic in `libapp.so` (Dart AOT), engine in `libflutter.so`.
- **`librode_bridge.so` (16.6 MB)** — a native C++ bridge (built on **JUCE**) with all
  device and protocol logic. Stripped, but exports **~25,000 symbols** (mangled C++
  names retained) → the protocol structure is readable directly.
- `assets/` contains **firmware blobs**: `Application-Podmic_v1.1.9.bin`,
  `NT-USBplus_v1.0.9.bin`, `AI_Micro_v1.2.2.bin`, WirelessGO, etc.

Tools used: `jadx` (of little use — Flutter), `llvm-objdump` (aarch64),
`readelf`, `c++filt`, capstone.

## Class map (DSP / protocol)

| Class | Role |
|---|---|
| `AphexFx` | APHEX DSP engine (Compressor, NoiseGate, AuralExciter, BigBottom) |
| `AphexFxParamsUtils` | **UI value ↔ HID parameter conversion** (below) |
| `DepthSparklePunch` | simplified control (PodMic USB UI): Depth/Sparkle/Punch → parameters |
| `PodMicUsb`, `AiMicro` | device models |
| `HighPassFiltrable` | high-pass filter (HPF) |
| `CommsUtils` | transport: `SendReportAndAwaitReply`, firmware gating |
| `HidDevices` | HID layer |

## Transport (confirmed from disassembly)

`AphexFx::SendCommandAndGetReply(uint8 in[28], uint8 out[28])` calls:

```
CommsUtils::SendReportAndAwaitReply(
    reportId   = 0x04,     # (0x06 on some firmware — branch in the code)
    cmdByte    = in[0],    # echoed in the reply (out[1])
    data       = in, len = 28,
    reply      = out, replyLen = 28,
    timeoutMs  = 500, ...)
```

- Checks VID == `0x19f7` and the firmware version (range).
- Reply: `out[1] == 0x41` → ACK (`0x4e` = NAK).

`in[28]` buffer layout (from `AphexFx::GetParams`):
- `in[0]` = selector / cmd (echoed)
- `in[1]` = **operation: `0x01` = GET, `0x02` = SET**
- parameters follow

→ **DSP state read-back is possible** (GET, op `0x01`) over the same 28-byte channel.
Granular parameters: `AphexFx::Get/SetGranularParam(effectIdx, paramIdx, in[28], out[28])`.

## Value encoding (formulas from disassembly)

Pattern: `norm` ∈ [0,1] → `idx = round(norm * 255)` → HID value = **LUT[idx]**
(256× int32, fixed-point Q≈31, sent to the DSP). Exception: Shape (no LUT).

| Parameter | UI range | `idx` formula | LUT @ vaddr |
|---|---|---|---|
| Compressor Gain | 0..9 dB | `(g/9)·255` | `0x4d0b94` |
| Compressor Threshold | −60..0 dB | `(−t/60)·255` | `0x4d0f94` |
| Compressor Attack | 0.1..10 ms | `log10(a/0.1)·0.5·255` | `0x4d1394` |
| Compressor Release | 5..200 ms | `(log10(r/5)/log10(40))·255` | `0x4d1794` |
| Compressor Shape (ratio) | 1.5..4.5 | `((s−1.5)/3)·255` | **no LUT** (idx = value) |
| Aural Exciter Tune | 600..5000 Hz | `((f−600)/4400)·255` | `0x4d1b94` + `0x4d1f94` (2 values) |
| Aural Exciter Mix | 0..100 % | `(m/100)·255` | `0x4d2394` |
| Big Bottom Drive | 0..100 % | `(d/100)·255` | `0x4d2394` (shared with AE Mix) |

The inverse functions (`From*HidParam`) recover the UI value from the LUT (binary search).
Extracted LUTs: bundled as `rode_podmic/dsp_luts.json`.

Constants verified from literals: 255, ±60, 0.1, 200, log10(40)=1.60206, 600, 5000, 4400, 100.

## Implemented and verified (live round-trip)

- **Compressor**: threshold, shape, attack, release, gain (parIdx 1–5)
- **Aural Exciter**: mix (par1, AEMix LUT), tune (par2, AETune_a LUT)
- **Big Bottom**: drive (par1) — `ToBBDrive` shares LUT @0x4d2394 with `ToAEMix`
  (fix: the earlier address 0x4d2794 was wrong)
- **Noise Gate** (Q31, computed inline; `AreGateParamsQ31`): threshold
  (par1, `10^(dB/20)·2³¹`), attack/release (par3/par4, `(1−e^(−1/(t·fs)))·2³¹`, fs=48000).
  par2/par5/par6 (likely range/hysteresis/ratio) — formula ambiguous, raw API only.
  par0 (enabled) is empty on GET — gate enable is coupled with "Punch".

## PodMic device parameters (outside AphexFx) — decoded

Channel `PodMicUsb::Set/GetParameter` → **report id 8 (out) / id 7 (in)**, 27 B:
`payload = [paramId, op, value]`, op `0x00`=SET / `0x01`=GET, timeout 2000 ms,
reply `07 <paramId> 0x41 <value>`. paramId (from `OnXChanged`):

| paramId | parameter | values |
|---|---|---|
| 1 | HPF | 0=off, 1=on (60 Hz) |
| 3 | direct monitoring | 0/1 |
| 4 | monitor mix | uint8 0..255 |
| 8 | input mute | 0/1 |

**Input gain** — not over HID: a standard UAC Feature Unit = the ALSA `Mic`
(capture) control, range 0..max (~63 dB). Driven via `amixer`.

## Open

- **NoiseGate** par2/par5/par6 (likely range/hysteresis/ratio) — formula still
  ambiguous; raw API only.
- Decode `DepthSparklePunch::ApplyDepth/Sparkle/Punch` (simplified UI:
  Depth=BB, Sparkle=AE, Punch=Compressor+gate).
