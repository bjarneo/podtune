# RØDE PodMic USB — control protocol (Linux)

Reverse-engineering findings from a real device (firmware 1.19, `19f7:004a`).

## Device

- **VID:PID**: `19f7:004a` (RODE Microphones — RØDE PodMic USB)
- **Firmware** (bcdDevice): `1.19`, serial in iSerial (e.g. `C1AE0AA1`)
- Composite USB Audio Class 1.0 + HID + Vendor-specific
- Interfaces:
  | Iface | Class | Role |
  |---|---|---|
  | 0,1,2 | Audio (UAC1) | mic in 24/16-bit @48 kHz, headphone out, mixer — `snd-usb-audio` |
  | **3** | HID (vendor page 0xFF00) | **DSP control** |
  | 5 | Vendor-specific (0xFF) | likely service/firmware |

## Control channel

- hidraw node: `/dev/hidrawN` (driver `hid-generic`), interface 3
- Interrupt IN endpoint `0x81`, max 29 B (= 1 B report ID + 28 B payload)
- Non-root access: udev rule (see `udev/70-rode-podmic-usb.rules`)

### Decoded HID report descriptor (vendor page 0xFF00)

| Report ID | Dir | Payload | Use |
|---|---|---|---|
| 1 / 2 | In / Out | 9 B | short commands (b0 0x00–0x0b → NAK; opcodes unknown) |
| **3 / 4** | In / Out | **28 B** | **DSP** (confirmed) |
| 5 / 6 | In / Out | 14 B | live level meter |
| 7 / 8 | In / Out | 27 B | PodMic device parameters |

No Feature reports (GET_FEATURE → timeout). Input reports carry no state when
polled (`HIDIOCGINPUT` returns zeros) — the model is **request/response**.

## Communication model (confirmed)

1. **Command write**: Output report ID 4, 28-byte payload.
   - via hidraw: `write(fd, bytes([0x04]) + payload28)`
   - via libusb/SET_REPORT: `ctrl_transfer(0x21, 0x09, 0x0204, 3, payload28)`
     (`bmRequestType=0x21` H→D|Class|Iface, `bRequest=0x09` SET_REPORT,
      `wValue=0x0204` = Output<<8 | report ID 4, `wIndex=3`)
2. **Reply / ACK**: interrupt IN, Input report ID 3:
   `03 <echo-opcode> 41 ...` where **`0x41` = ACK** (common across the RØDE family).

### Channel map (probing)

Reply status byte: **`0x41` = `'A'` = ACK**, **`0x4e` = `'N'` = NAK** (unknown command).
Every reply has the form `<in_id> <echo b0> <ACK/NAK> <data...>`.

| Out→In | Payload | Role (established) |
|---|---|---|
| id4 → id3 | 28 B | **DSP read/write**. See the DSP payload below |
| id6 → id5 | 14 B | **live level meter**. Selectors b0 `0x00`–`0x03` = ACK+data, `0x04+` = NAK. Reply `05 <sel> 41 <w0:u32LE> <w1:u32LE> ...` = 2 amplitude samples. **Full scale = 2^31** (verified: loud signal ≈ −0.3 dBFS). dBFS = 20·log₁₀(v/2³¹). Selectors return a shared stream, not separate meters |
| id2 → id1 | 9 B | command channel; b0 `0x00`–`0x0b` → NAK (correct opcodes unknown) |
| id8 → id7 | 27 B | **PodMic device parameters** (`PodMicUsb::Set/GetParameter`): payload `[paramId, op, value]`, op `0x00`=SET / `0x01`=GET, reply `07 <paramId> 41 <value>`. paramId: 1=HPF(0/1), 3=directMonitor, 4=monitorMix(u8), 8=inputMute |

### DSP payload (28 B) — verified format (binary + live read-back)

```
offset  0       1     2        3..
       effIdx   op    parIdx   value (LE, 1 or 4 B)
```
- `op`: `0x01` = GET-all, `0x02` = SET, `0x03` = GET a single parameter
- reply on report id 3: `03 <echo-effIdx> <0x41=ACK / 0x4e=NAK> <data...>`

Effects (effIdx): compressor `0`, noiseGate `1`, auralExciter `2`, bigBottom `3`.

> Note: the `rode-dsp-tool` packet (`04 00 02 00 01`) had a wrong leading byte
> `0x04` (effIdx=4). The device ACKs anyway (it echoes every command), so it
> looked like it worked. The format above is authoritative — taken from the
> binary and confirmed by reading back live values.

#### Parameter map (parIdx) — from granular GET on the device

| effIdx | par0 | par1 | par2 | par3 | par4 | par5 | par6 |
|---|---|---|---|---|---|---|---|
| 0 compressor | enabled(1B) | threshold(i32) | shape(i32) | attack(i32) | release(i32) | gain(i32) | — |
| 1 noiseGate | — | threshold(i32,dB) | ?(i32) | attack(i32,ms) | release(i32,ms) | ?(i32) | ?(i32) |
| 2 auralExciter | enabled(1B) | mix(i32, AEMix LUT) | tune(i32, AETune_a LUT) | const(1B) | — | | |
| 3 bigBottom | enabled(1B) | drive(i32, AEMix LUT) | const(1B) | const(1B) | — | | |

Round-trip verified on a live device: compressor (threshold/shape/attack/release/gain),
auralExciter (mix 0–100%, tune 600–5000 Hz), bigBottom (drive 0–100%),
noiseGate (threshold dB, attack/release ms).
`ToBBDrive` and `ToAEMix` share the same LUT @0x4d2394 (the 0–100% curve).

NoiseGate is computed inline in firmware (Q31, no LUT). Formulas decoded from disasm:
- threshold (par1): `coeff = 10^(dB/20) · 2³¹`  →  dB = `20·log10(coeff/2³¹)`
- attack/release (par3/par4): `coeff = (1 − e^(−1/(t_s·48000))) · 2³¹`
par2/par5/par6 — formula ambiguous (raw); par0 (enabled) is empty on GET
(gate enable is coupled with "Punch").

Examples (hidraw frame = `04 | payload`):
- GET compressor gain: `04 | 00 03 05` → reply `03 00 41 a1 2c 7c 15` (int32 LE coeff)
- SET compressor enabled ON: `04 | 00 02 00 01` → reply `03 00 41` (ACK)

## Value encoding — recovered from the app

Formulas and ranges for the DSP parameters (gain, threshold, attack, release, shape,
AE tune/mix, BB drive) were recovered from `librode_bridge.so` — see
**[`apk_analysis.md`](apk_analysis.md)**. This also confirmed the **GET opcode = `0x01`**
(state read) and SET = `0x02` on the 28-byte channel, ACK `0x41`/NAK `0x4e`,
timeout 500 ms (`CommsUtils::SendReportAndAwaitReply`).

## Resolved

- ✅ DSP command format (effIdx/op/parIdx/value), GET + SET, ACK/NAK (`0x41`/`0x4e`)
- ✅ read + write of all four effects in UI units (dB/ms/ratio/%/Hz), round-trip verified
- ✅ level meter read channel (id6→id5), full scale 2^31
- ✅ PodMic device parameters (id8→id7): HPF, mute, direct monitor, monitor mix
- ✅ input gain via ALSA (UAC capture control)

## Open

- NoiseGate par2/par5/par6 (range/hysteresis/ratio?) — formula still ambiguous; raw API only
- `DepthSparklePunch::Apply*` (simplified PodMic USB UI: Depth=BB, Sparkle=AE, Punch=Compressor+gate)
- 9-byte command channel (id2/id1) — correct opcodes unknown
- Vendor-specific interface 5 (likely service/firmware)

## Sources / related projects

- AyQWERTY/rode-dsp-tool — DSP packets (XDM-100), payload identical to the PodMic USB
- Jordan-Milner/rodecaster-control — `0x41` ACK, report structure
- freedmanelectronics/hidapi — the HID library used by RØDE
