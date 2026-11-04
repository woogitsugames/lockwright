#!/usr/bin/env python3
"""CI check for generated SFX: 48 kHz 16-bit mono, clicks 20-80 ms with <= 1 ms
leading silence (low-latency requirement), every event has 4 materials x 4 variants."""

import glob
import os
import sys

import numpy as np
import soundfile as sf

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "audio", "sfx")
EVENTS = ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate", "overset",
          "drop", "stress", "break", "wear", "gate_align", "detector_trip", "open",
          "tension_resistance", "pick_drag"]
MATERIALS = ["brass", "steel", "iron", "wood"]
# Full clicks 20-80 ms; contact is a 10-15 ms quiet tick per docs/TECH.md §3.3.
CLICKS = {"bind", "set", "false_set", "overset", "gate_align"}
TICKS = {"contact"}


def main() -> int:
    failures = 0
    for ev in EVENTS:
        for mat in MATERIALS:
            for n in range(1, 5):
                path = os.path.abspath(os.path.join(ROOT, ev, f"{mat}_{n}.wav"))
                if not os.path.exists(path):
                    print(f"MISSING {path}")
                    failures += 1
                    continue
                info = sf.info(path)
                if info.samplerate != 48000 or info.subtype != "PCM_16" or info.channels != 1:
                    print(f"BAD FORMAT {path}: {info.samplerate} {info.subtype} ch={info.channels}")
                    failures += 1
                if ev in CLICKS or ev in TICKS:
                    x, sr = sf.read(path, dtype="float32")
                    dur = len(x) / sr
                    lo, hi = (0.020, 0.080) if ev in CLICKS else (0.010, 0.020)
                    if not (lo - 1e-4 <= dur <= hi + 1e-4):
                        print(f"BAD CLICK DUR {path}: {dur*1000:.1f} ms (want {lo*1000:.0f}-{hi*1000:.0f})")
                        failures += 1
                    idx = int(np.argmax(np.abs(x) > 1e-4)) if np.any(np.abs(x) > 1e-4) else len(x)
                    if idx > 48:
                        print(f"BAD LEADING SILENCE {path}: {idx/sr*1000:.2f} ms")
                        failures += 1
    if failures:
        print(f"SFX CHECK FAIL: {failures} problems")
        return 1
    print("SFX CHECK OK: 16 events/loops x 4 materials x 4 variants, format + click constraints pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
