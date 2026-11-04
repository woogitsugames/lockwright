#!/usr/bin/env python3
"""Composes audio/demo/all_events.wav — one pass through every event (brass, variant 1)
with a short label gap, for quick listening checks.

Usage: python3 audio/tools/preview.py [--sfx game/assets/audio/sfx] [--out audio/demo/all_events.wav]
"""

import argparse
import os

import numpy as np
import soundfile as sf

SR = 48000
EVENTS = [
    "contact", "bind", "near_shear", "set", "false_set", "counter_rotate",
    "overset", "drop", "stress", "break", "wear", "gate_align",
    "detector_trip", "open", "tension_resistance", "pick_drag",
]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sfx", default=os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "audio", "sfx"))
    ap.add_argument("--out", default=os.path.join(os.path.dirname(__file__), "..", "demo", "all_events.wav"))
    args = ap.parse_args()
    sfx_root = os.path.abspath(args.sfx)
    gap = np.zeros(int(0.35 * SR))
    chunks = []
    for ev in EVENTS:
        path = os.path.join(sfx_root, ev, "brass_1.wav")
        x, sr = sf.read(path, dtype="float32")
        assert sr == SR
        chunks.append(x)
        chunks.append(gap)
    out = np.concatenate(chunks)
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    sf.write(os.path.abspath(args.out), out, SR, subtype="PCM_16")
    print(f"demo written: {args.out} ({len(out) / SR:.1f}s, events in order: {', '.join(EVENTS)})")


if __name__ == "__main__":
    main()
