"""Modern dark GUI for the RØDE PodMic USB — a polished RØDE Central alternative.

A flat, card-based dark interface built on ttkbootstrap (with a graceful
fall-back to a hand-themed ttk if ttkbootstrap is missing): device toggles,
input gain, monitoring, DSP effects (compressor / noise gate / aural exciter /
big bottom), a live level meter and profile management.

Usage:
    python -m rode_podmic.modern_gui      # or:  rode-podmic gui
"""
from __future__ import annotations
import tkinter as tk
import tkinter.font  # noqa: F401  (registers tk.font)

from .device import PodMicUSB, Effect, find_device_path
from . import params as P
from . import alsa
from . import profiles

# ttkbootstrap gives us flat, modern widgets + a real dark theme. Fall back to
# plain ttk (hand-themed) so the GUI still runs if it isn't installed.
try:
    import ttkbootstrap as tb
    ttk = tb  # ttkbootstrap exposes widgets (Button, Scale, Labelframe, …) directly
    from ttkbootstrap.constants import SUCCESS, DANGER, INFO, WARNING, SECONDARY
    HAVE_TB = True
except ImportError:  # pragma: no cover
    from tkinter import ttk
    tb = None
    SUCCESS = DANGER = INFO = WARNING = SECONDARY = ""
    HAVE_TB = False

METER_FLOOR = -60.0

# Palette (used by the canvas meter + accents; ttkbootstrap owns widget theming).
BG = "#0e1116"
CARD = "#171b22"
TEXT = "#e6edf3"
DIM = "#8b949e"
GREEN = "#3fb950"
YELLOW = "#e3b341"
RED = "#f85149"
TRACK = "#262c36"

# One accent bootstyle per effect for its toggle switch.
FX_STYLE = {
    Effect.COMPRESSOR: DANGER,
    Effect.NOISE_GATE: INFO,
    Effect.AURAL_EXCITER: WARNING,
    Effect.BIG_BOTTOM: SUCCESS,
}
FX_TITLES = {
    Effect.COMPRESSOR: "Compressor",
    Effect.NOISE_GATE: "Noise Gate",
    Effect.AURAL_EXCITER: "Aural Exciter",
    Effect.BIG_BOTTOM: "Big Bottom",
}


class MeterBar(tk.Canvas):
    """Segmented, colour-graded level meter (green → yellow → red)."""

    SEGMENTS = 24

    def __init__(self, parent, height=18):
        super().__init__(parent, height=height, bg=CARD, highlightthickness=0, bd=0)
        self.bind("<Configure>", lambda e: self._draw(self._frac))
        self._frac = 0.0

    def set_frac(self, frac: float):
        self._frac = max(0.0, min(1.0, frac))
        self._draw(self._frac)

    def _seg_color(self, i: int) -> str:
        t = i / (self.SEGMENTS - 1)
        if t > 0.9:
            return RED
        if t > 0.72:
            return YELLOW
        return GREEN

    def _draw(self, frac):
        self.delete("all")
        w = self.winfo_width() or 320
        h = self.winfo_height() or 26
        gap = 3
        seg_w = (w - gap * (self.SEGMENTS - 1)) / self.SEGMENTS
        lit = round(frac * self.SEGMENTS)
        for i in range(self.SEGMENTS):
            x0 = i * (seg_w + gap)
            color = self._seg_color(i) if i < lit else TRACK
            self.create_rectangle(x0, 2, x0 + seg_w, h - 2, fill=color, width=0)


class ModernRodeGui:
    def __init__(self, root=None):
        if root is None:
            if HAVE_TB:
                self.root = tb.Window(themename="darkly")
            else:
                self.root = tk.Tk()
                try:
                    ttk.Style().theme_use("clam")
                except tk.TclError:
                    pass
            self._is_standalone = True
        else:
            self.root = root
            self._is_standalone = False

        self.root.title("RØDE PodMic USB — Control Center")
        self.root.configure(bg=BG)
        self.root.minsize(440, 560)

        try:
            self._ws = self.root.tk.call("tk", "windowingsystem")  # x11/win32/aqua
        except tk.TclError:
            self._ws = "x11"

        # Counter X11's often-inflated auto-scaling (~1.4) that balloons every
        # control. Leave macOS/Windows alone — their scaling is DPI-correct.
        if self._ws == "x11":
            try:
                if float(self.root.tk.call("tk", "scaling")) > 1.1:
                    self.root.tk.call("tk", "scaling", 1.0)
            except tk.TclError:
                pass

        self._font = self._pick_font()
        for named in ("TkDefaultFont", "TkTextFont", "TkHeadingFont",
                      "TkMenuFont", "TkFixedFont"):
            try:
                fnt = tk.font.nametofont(named)
                fnt.configure(size=10)
                if self._font:
                    fnt.configure(family=self._font)
            except tk.TclError:
                pass

        self.mic = None
        self.gain_card = None
        self._loading = True
        self.s_gain = None

        self._tune_theme()

        if not find_device_path():
            self._build_missing()
            return

        self.mic = PodMicUSB()
        self.mic.open()
        self.gain_card = alsa.find_card()

        self._build()
        self._load_values()
        self._loading = False
        self._tick_meter()

    # ---------- fonts ----------
    def _pick_font(self):
        """Best UI font family for this platform. Resolves each candidate via
        .actual() (fontconfig on x11) so absent families are skipped; always
        returns a concrete family (the platform's native default as last
        resort). Warns only when the interpreter's Tk is genuinely Xft-less
        (conda/anaconda), where every TrueType renders as blocky bitmaps."""
        cands = {
            "aqua":  ["SF Pro Text", "Helvetica Neue", "Lucida Grande"],
            "win32": ["Segoe UI", "Tahoma", "Verdana"],
            "x11":   ["Lato", "Noto Sans", "Cantarell", "DejaVu Sans",
                      "Liberation Sans"],
        }.get(self._ws, ["DejaVu Sans"])

        def resolves(name):
            try:
                got = tk.font.Font(family=name, size=10).actual("family")
                return got.lower() == name.lower()
            except tk.TclError:
                return False

        for c in cands:
            if resolves(c):
                return c

        default = tk.font.nametofont("TkDefaultFont").actual("family")
        if self._ws == "x11":  # only the Xft-less x11 build is actually broken
            try:
                nfam = len(tk.font.families(self.root))
            except tk.TclError:
                nfam = 0
            if nfam < 100:
                import sys
                print(
                    f"[rode-podmic] WARNING: this Python's Tk ({sys.executable}) "
                    f"was built without Xft/fontconfig (only {nfam} bitmap fonts "
                    "visible), so the UI renders blocky. This is typical of "
                    "conda/anaconda Python — run with a system interpreter, e.g.:\n"
                    "    /usr/bin/python3 -m rode_podmic.modern_gui",
                    file=sys.stderr,
                )
        return default

    # ---------- theming ----------
    def _tune_theme(self):
        if not HAVE_TB:
            return
        style = ttk.Style()
        # Catch-all: force our font on every ttk widget class (ttkbootstrap sets
        # fonts per-style, so reconfiguring named fonts alone isn't enough).
        style.configure(".", font=(self._font, 10))
        style.configure("Card.TLabelframe", background=CARD, borderwidth=0)
        style.configure("Card.TLabelframe.Label", background=BG,
                        foreground=DIM, font=(self._font, 8, "bold"))
        style.configure("Card.TFrame", background=CARD)
        style.configure("Card.TLabel", background=CARD, foreground=TEXT)
        style.configure("Dim.TLabel", background=CARD, foreground=DIM)
        style.configure("Val.TLabel", background=CARD, foreground=TEXT,
                        font=(self._font, 9, "bold"))

    # ---------- construction helpers ----------
    def _card(self, parent, title):
        if HAVE_TB:
            f = ttk.Labelframe(parent, text=title, padding=10, style="Card.TLabelframe")
        else:
            f = ttk.LabelFrame(parent, text=title, padding=8)
        f.pack(fill="x", padx=14, pady=5)
        return f

    def _toggle(self, parent, text, var, cmd, bootstyle=SUCCESS):
        kw = {}
        if HAVE_TB:
            kw["bootstyle"] = f"{bootstyle}-round-toggle"
        cb = ttk.Checkbutton(parent, text=text, variable=var, command=cmd, **kw)
        cb.pack(anchor="w", pady=2)
        return cb

    def _slider(self, parent, label, lo, hi, unit, on_release, bootstyle=INFO, digits=1):
        # Single dense row: label | scale (fills) | value.
        row = ttk.Frame(parent, style="Card.TFrame" if HAVE_TB else "")
        row.pack(fill="x", pady=2)
        lab = ttk.Label(row, text=label, style="Card.TLabel" if HAVE_TB else "", width=12)
        lab.pack(side="left")
        val = ttk.Label(row, text="", style="Val.TLabel" if HAVE_TB else "",
                        anchor="e", width=9)
        val.pack(side="right")

        kw = {"bootstyle": bootstyle} if HAVE_TB else {}
        s = ttk.Scale(row, from_=lo, to=hi, orient="horizontal", **kw)
        s.pack(side="left", fill="x", expand=True, padx=8)

        def show(_=None):
            val.config(text=f"{s.get():.{digits}f} {unit}".strip())
        s.configure(command=lambda _: show())
        s.bind("<ButtonRelease-1>", lambda e: (show(), on_release(s.get())))
        return s

    # ---------- screens ----------
    def _build_missing(self):
        wrap = ttk.Frame(self.root)
        wrap.pack(expand=True, fill="both", padx=40, pady=60)
        ttk.Label(wrap, text="🎙️", font=("", 48)).pack(pady=(0, 12))
        ttk.Label(wrap, text="PodMic USB not found",
                  font=("", 15, "bold")).pack()
        ttk.Label(wrap, foreground=DIM, justify="center",
                  text="Plug in the microphone and check the udev rule,\n"
                       "then reopen this window.").pack(pady=10)

    def _build(self):
        # Scrollable body so everything fits on small screens.
        outer = ttk.Frame(self.root)
        outer.pack(fill="both", expand=True)
        canvas = tk.Canvas(outer, bg=BG, highlightthickness=0)
        vsb = ttk.Scrollbar(outer, orient="vertical", command=canvas.yview)
        canvas.configure(yscrollcommand=vsb.set)
        vsb.pack(side="right", fill="y")
        canvas.pack(side="left", fill="both", expand=True)
        body = ttk.Frame(canvas)
        win = canvas.create_window((0, 0), window=body, anchor="nw")
        body.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.bind("<Configure>", lambda e: canvas.itemconfig(win, width=e.width))
        canvas.bind_all("<MouseWheel>", lambda e: canvas.yview_scroll(int(-e.delta / 120), "units"))
        canvas.bind_all("<Button-4>", lambda e: canvas.yview_scroll(-1, "units"))
        canvas.bind_all("<Button-5>", lambda e: canvas.yview_scroll(1, "units"))

        # --- header ---
        header = ttk.Frame(body)
        header.pack(fill="x", padx=14, pady=(12, 2))
        ttk.Label(header, text="RØDE PodMic USB",
                  font=(self._font, 14, "bold")).pack(side="left")
        pill = ttk.Label(header, text="● Connected", foreground=GREEN,
                         font=(self._font, 9, "bold"))
        pill.pack(side="right")

        # --- meter ---
        mf = self._card(body, "INPUT LEVEL")
        self.meter = MeterBar(mf)
        self.meter.pack(fill="x")
        self.meter_lbl = ttk.Label(mf, text="—", style="Val.TLabel" if HAVE_TB else "",
                                   anchor="e")
        self.meter_lbl.pack(fill="x", pady=(6, 0))

        # --- device ---
        df = self._card(body, "DEVICE")
        self.v_hpf = tk.BooleanVar()
        self.v_mute = tk.BooleanVar()
        self.v_mon = tk.BooleanVar()
        self.v_loop = tk.BooleanVar()
        self._toggle(df, "High-pass filter (60 Hz)", self.v_hpf,
                     lambda: self._guard(self.mic.set_hpf, self.v_hpf.get()), INFO)
        self._toggle(df, "Mute input", self.v_mute,
                     lambda: self._guard(self.mic.set_input_mute, self.v_mute.get()), DANGER)
        self._toggle(df, "Direct monitoring (mic jack)", self.v_mon,
                     lambda: self._guard(self.mic.set_direct_monitor, self.v_mon.get()), INFO)
        self._toggle(df, "Monitor → headphones (loopback)", self.v_loop,
                     self._toggle_loopback, INFO)
        self.s_mix = self._slider(df, "Monitor mix", 0, 255, "",
                                  lambda v: self._guard(self.mic.set_monitor_mix, int(v)))
        if self.gain_card is not None:
            # The mic's own preamp (UAC Feature Unit), shown in dB like RØDE Central.
            g = alsa.get_gain(self.gain_card) or {"db_min": 22, "db_max": 63}
            self.s_gain = self._slider(df, "Input gain", g["db_min"], g["db_max"], "dB",
                                       self._set_gain_db, bootstyle=SUCCESS, digits=0)

        # --- DSP effects ---
        self.fx_enable = {}
        self.fx_sliders = {}
        for eff in (Effect.COMPRESSOR, Effect.NOISE_GATE,
                    Effect.AURAL_EXCITER, Effect.BIG_BOTTOM):
            f = self._card(body, FX_TITLES[eff].upper())
            var = tk.BooleanVar()
            self.fx_enable[eff] = var
            self._toggle(f, "Enabled", var,
                         lambda e=eff, v=var: self._guard(self.mic.set_effect, e, v.get()),
                         FX_STYLE[eff])
            self.fx_sliders[eff] = {}
            for name, p in P.PARAMS_BY_EFFECT[eff].items():
                lo, hi = P.RANGES_BY_EFFECT[eff][name]
                self.fx_sliders[eff][name] = self._slider(
                    f, name.replace("_", " ").title(), lo, hi, p.unit,
                    lambda v, e=eff, n=name: self._guard(
                        lambda: P.set_params(self.mic, e, **{n: v})),
                    bootstyle=FX_STYLE[eff])

        # --- profiles ---
        pf = self._card(body, "PROFILES")
        row = ttk.Frame(pf, style="Card.TFrame" if HAVE_TB else "")
        row.pack(fill="x")
        self.cmb_profile = ttk.Combobox(row, values=profiles.list_profiles(), state="readonly")
        self.cmb_profile.pack(side="left", fill="x", expand=True)
        ttk.Button(row, text="Load", width=8, command=self._profile_load,
                   **({"bootstyle": INFO} if HAVE_TB else {})).pack(side="left", padx=(8, 0))
        row2 = ttk.Frame(pf, style="Card.TFrame" if HAVE_TB else "")
        row2.pack(fill="x", pady=(8, 0))
        ttk.Button(row2, text="Save as…", command=self._profile_save,
                   **({"bootstyle": SUCCESS} if HAVE_TB else {})).pack(side="left")
        ttk.Button(row2, text="Delete", command=self._profile_delete,
                   **({"bootstyle": f"{DANGER}-outline"} if HAVE_TB else {})).pack(side="left", padx=8)

        ttk.Button(body, text="Reload from device", command=self._load_values,
                   **({"bootstyle": SECONDARY} if HAVE_TB else {})).pack(
            fill="x", padx=16, pady=(4, 16))

    # ---------- profile actions ----------
    def _refresh_profiles(self):
        self.cmb_profile["values"] = profiles.list_profiles()

    def _profile_save(self):
        from tkinter import simpledialog
        name = simpledialog.askstring("Save profile", "Profile name:", parent=self.root)
        if name:
            profiles.save(self.mic, name)
            self._refresh_profiles()
            self.cmb_profile.set(name)

    def _profile_load(self):
        name = self.cmb_profile.get()
        if not name:
            return
        try:
            profiles.apply(self.mic, profiles.load(name))
        except FileNotFoundError:
            return
        self._load_values()

    def _profile_delete(self):
        name = self.cmb_profile.get()
        if name and profiles.delete(name):
            self._refresh_profiles()
            self.cmb_profile.set("")

    # ---------- logic ----------
    def _toggle_loopback(self):
        if self._loading:
            return
        if self.v_loop.get():
            alsa.stop_monitor()
            if not alsa.start_monitor():
                self.v_loop.set(False)
                self.meter_lbl.config(text="no PodMic source in PipeWire")
        else:
            alsa.stop_monitor()

    def _guard(self, fn, *a):
        if self._loading:
            return
        try:
            fn(*a)
        except Exception as e:  # noqa
            self.meter_lbl.config(text=f"error: {e}")

    def _set_gain_db(self, db):
        db = round(db)
        self.s_gain.set(db)  # snap to whole dB (the control has 1 dB steps)
        return alsa.set_gain_db(db, self.gain_card)

    def _load_values(self):
        self._loading = True
        try:
            self.v_hpf.set(bool(self.mic.get_hpf()))
            self.v_mute.set(bool(self.mic.podmic_get(8)))
            self.v_mon.set(bool(self.mic.podmic_get(3)))
            self.v_loop.set(bool(alsa.loopback_modules()))
            mix = self.mic.podmic_get(4)
            if mix is not None:
                self.s_mix.set(mix)
            if self.s_gain is not None:
                g = alsa.get_gain(self.gain_card)
                if g:
                    self.s_gain.set(g["db"])
            for eff, sliders in self.fx_sliders.items():
                vals = P.get_params(self.mic, eff)
                self.fx_enable[eff].set(bool(vals.get("enabled")))
                for name, s in sliders.items():
                    if vals.get(name) is not None:
                        s.set(vals[name])
        finally:
            self._loading = False

    def _tick_meter(self):
        try:
            mag = self.mic.read_meter()
        except Exception:
            mag = None
        if mag is not None:
            db = self.mic.meter_dbfs(mag)
            frac = max(0.0, min(1.0, (db - METER_FLOOR) / (0 - METER_FLOOR)))
            self.meter.set_frac(frac)
            self.meter_lbl.config(text=f"{db:5.1f} dBFS")
        self.root.after(60, self._tick_meter)

    def run(self):
        if self._is_standalone:
            self.root.mainloop()


def run():
    ModernRodeGui().run()


if __name__ == "__main__":
    run()
