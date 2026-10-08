"""CLI: rode-podmic — control the RØDE PodMic USB DSP and device settings."""
from __future__ import annotations
import argparse
import sys

from .device import PodMicUSB, EFFECTS, find_device_path


def main(argv=None):
    p = argparse.ArgumentParser(prog="rode-podmic", description="Control the RØDE PodMic USB")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("info", help="show the detected device and its state")
    sub.add_parser("gui", help="configuration window (Tkinter)")

    sp = sub.add_parser("set", help="enable/disable a DSP effect")
    sp.add_argument("effect", choices=sorted(EFFECTS), help="effect to toggle")
    sp.add_argument("state", choices=["on", "off"], help="state")

    mp = sub.add_parser("meter", help="live level meter (dBFS)")
    mp.add_argument("--hz", type=float, default=30.0, help="refresh rate")

    pp = sub.add_parser("profile", help="configuration profiles: save/load/list/delete/show")
    pp.add_argument("action", choices=["save", "load", "list", "delete", "show"])
    pp.add_argument("name", nargs="?", help="profile name")

    lp = sub.add_parser("monitor", help="loopback the microphone to headphones (PipeWire)")
    lp.add_argument("state", choices=["on", "off"])
    lp.add_argument("--latency", type=int, default=60, help="buffer latency in ms")
    lp.add_argument("--sink", help="target sink (defaults to the system default)")

    dp = sub.add_parser("device", help="device parameters: HPF, gain, monitor, mute")
    dp.add_argument("--hpf", choices=["on", "off"], help="60 Hz high-pass filter")
    dp.add_argument("--mute", choices=["on", "off"], help="input mute")
    dp.add_argument("--monitor", choices=["on", "off"], help="direct monitoring")
    dp.add_argument("--monitor-mix", type=int, help="monitor mix 0..255")
    dp.add_argument("--gain", type=float, help="input gain in dB (PodMic USB: 22..63)")

    gp = sub.add_parser("get", help="read an effect's parameters (e.g. compressor)")
    gp.add_argument("effect", choices=sorted(EFFECTS))

    stp = sub.add_parser("tune", help="set an effect's parameters (UI values)")
    stp.add_argument("effect", choices=sorted(EFFECTS))
    stp.add_argument("--enabled", choices=["on", "off"])
    stp.add_argument("--threshold", type=float, help="compressor/noise_gate: dB")
    stp.add_argument("--shape", type=float, help="compressor: ratio (1.5..4.5)")
    stp.add_argument("--attack", type=float, help="compressor/noise_gate: ms")
    stp.add_argument("--release", type=float, help="compressor/noise_gate: ms")
    stp.add_argument("--gain", type=float, help="compressor: dB (0..9)")
    stp.add_argument("--mix", type=float, help="aural_exciter: %% (0..100)")
    stp.add_argument("--tune", type=float, help="aural_exciter: Hz (600..5000)")
    stp.add_argument("--drive", type=float, help="big_bottom: %% (0..100)")

    args = p.parse_args(argv)

    if args.cmd == "gui":
        from .modern_gui import ModernRodeGui
        gui = ModernRodeGui()
        gui.run()
        return 0

    if args.cmd == "profile":
        from . import profiles
        if args.action == "list":
            names = profiles.list_profiles()
            print("\n".join(names) if names else "(no profiles)")
            return 0
        if args.action in ("save", "load", "delete", "show") and not args.name:
            print(f"give a name: rode-podmic profile {args.action} <name>", file=sys.stderr)
            return 1
        if args.action == "delete":
            ok = profiles.delete(args.name)
            print(f"deleted: {args.name}" if ok else f"no such profile: {args.name}")
            return 0 if ok else 1
        if args.action == "show":
            import json
            try:
                print(json.dumps(profiles.load(args.name), indent=2, ensure_ascii=False))
            except FileNotFoundError:
                print(f"no such profile: {args.name}", file=sys.stderr); return 1
            return 0
        with PodMicUSB() as mic:
            if args.action == "save":
                path = profiles.save(mic, args.name)
                print(f"saved profile '{args.name}' -> {path}")
            else:  # load
                try:
                    prof = profiles.load(args.name)
                except FileNotFoundError:
                    print(f"no such profile: {args.name}", file=sys.stderr); return 1
                res = profiles.apply(mic, prof)
                for k, ok in res.items():
                    print(f"  {k}: {'OK' if ok else 'FAIL'}")
        return 0

    if args.cmd == "monitor":
        from . import alsa
        if args.state == "on":
            alsa.stop_monitor()  # avoid duplicates
            mod = alsa.start_monitor(latency_msec=args.latency, sink=args.sink)
            if mod:
                print(f"monitoring on (mic -> {args.sink or alsa.default_sink()}, module {mod})")
                print("turn off: rode-podmic monitor off")
                return 0
            print("failed — no PodMic source in PipeWire", file=sys.stderr)
            return 1
        n = alsa.stop_monitor()
        print(f"monitoring off ({n} modules)")
        return 0

    if args.cmd == "meter":
        from .meter import run
        run(refresh_hz=args.hz)
        return 0

    if args.cmd == "get":
        from . import params as P
        effect = EFFECTS[args.effect]
        with PodMicUSB() as mic:
            vals = P.get_params(mic, effect)
        for k, v in vals.items():
            print(f"  {k:10s} = {v}")
        return 0

    if args.cmd == "tune":
        from . import params as P
        effect = EFFECTS[args.effect]
        kw = {}
        if args.enabled is not None:
            kw["enabled"] = args.enabled == "on"
        for name in ("threshold", "shape", "attack", "release", "gain", "mix", "tune", "drive"):
            v = getattr(args, name)
            if v is not None:
                kw[name] = v
        if not kw:
            print("nothing to set — pass e.g. --gain 3", file=sys.stderr)
            return 1
        with PodMicUSB() as mic:
            res = P.set_params(mic, effect, **kw)
        for k, ok in res.items():
            print(f"  {k} -> {'OK' if ok else 'FAIL'}")
        return 0 if all(res.values()) else 2

    if args.cmd == "info":
        from . import alsa
        path = find_device_path()
        if not path:
            print("PodMic USB: not found", file=sys.stderr)
            return 1
        print(f"PodMic USB: {path}")
        with PodMicUSB() as mic:
            print(f"  HPF (60 Hz)      : {'on' if mic.get_hpf() else 'off'}")
            print(f"  input mute       : {'on' if mic.podmic_get(8) else 'off'}")
            print(f"  direct monitor   : {'on' if mic.podmic_get(3) else 'off'}")
            print(f"  monitor mix      : {mic.podmic_get(4)}")
        g = alsa.get_gain()
        if g:
            print(f"  input gain       : {g['db']:.0f} dB  "
                  f"(range {g['db_min']:.0f}..{g['db_max']:.0f} dB, ALSA step {g['value']}/{g['max']})")
        return 0

    if args.cmd == "device":
        from . import alsa
        with PodMicUSB() as mic:
            if args.hpf is not None:
                print(f"  HPF -> {args.hpf}  [{'OK' if mic.set_hpf(args.hpf=='on') else 'FAIL'}]")
            if args.mute is not None:
                print(f"  mute -> {args.mute}  [{'OK' if mic.set_input_mute(args.mute=='on') else 'FAIL'}]")
            if args.monitor is not None:
                print(f"  monitor -> {args.monitor}  [{'OK' if mic.set_direct_monitor(args.monitor=='on') else 'FAIL'}]")
            if args.monitor_mix is not None:
                print(f"  monitor-mix -> {args.monitor_mix}  [{'OK' if mic.set_monitor_mix(args.monitor_mix) else 'FAIL'}]")
        if args.gain is not None:
            print(f"  gain -> {args.gain:g} dB  [{'OK' if alsa.set_gain_db(args.gain) else 'FAIL'}]")
        return 0

    if args.cmd == "set":
        effect = EFFECTS[args.effect]
        enabled = args.state == "on"
        with PodMicUSB() as mic:
            ok = mic.set_effect(effect, enabled)
        status = "ACK" if ok else "NO ACK"
        print(f"{args.effect} -> {args.state}  [{status}]")
        return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
