# Product

<!-- impeccable:product-schema 1 -->

## Platform

Native Linux desktop.

## Stack

The user requests C++ and Qt 6.
Qt Quick supplies the interface.

## Users

The user tunes a connected RØDE PodMic USB on an Omarchy desktop.

## Product Purpose

Control the microphone hardware and test the result within one app.
Provide ready-to-use presets and useful visual feedback.

## Operating Context

The connected microphone identifies as USB device `19f7:004a`.
The desktop uses PipeWire.
The microphone provides mono capture at 48 kHz and stereo headphone playback.

## Capabilities and Constraints

- Provide sound controls, onboard settings, and headphone controls where the device supports them.
- Include presets and an in-app record and playback test.
- Show input levels, clipping, and signal quality guidance.
- Support dark mode, light mode, and the current Omarchy theme.
- Report unsupported controls and device access failures in the app.
- Keep hardware commands limited to documented or verified protocol operations.

## Product Principles

- Read the hardware state before changes.
- Make each control's effect clear.
- Base visual feedback on measured audio.
- Keep voice tests local.

## Open Decisions

The app reads and verifies all 20 supported controls on firmware `1.19`.
The live test restores every control to its original value.
Power-cycle persistence remains untested.
