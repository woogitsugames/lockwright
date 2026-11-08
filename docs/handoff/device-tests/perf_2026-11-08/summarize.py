#!/usr/bin/env python3
"""Markdown table from <run>_frames.json + <run>_mem.txt (perf pass 2026-11-08).
usage: python summarize.py RUN [RUN2]  -> per label: fps, p95, max, >33 ms, 1% low, PSS, Graphics."""
import json, re, sys, os
D = os.path.dirname(os.path.abspath(__file__))

def load(run):
    frames = {s["label"]: s for s in json.load(open(os.path.join(D, run + "_frames.json"), encoding="utf-8"))}
    mem = {}
    for line in open(os.path.join(D, run + "_mem.txt"), encoding="utf-8"):
        m = re.match(r"(\S+)\s+PSS=\s*(\d+) MB\s+Graphics=\s*(\d+)", line)
        if m:
            mem[m.group(1)] = (int(m.group(2)), int(m.group(3)))
    return frames, mem

runs = [load(r) for r in sys.argv[1:]]
labels = [l for l in runs[0][0] if l != "x"]
hdr = "| Ekran / akcja | " + " | ".join(f"{r}: FPS · p95 · max [ms] · >33 ms · PSS/Graphics [MB]" for r in sys.argv[1:]) + " |"
print(hdr)
print("|---" * (1 + len(runs)) + "|")
for l in labels:
    cells = []
    for frames, mem in runs:
        s = frames.get(l)
        if not s:
            cells.append("—")
            continue
        pss, gfx = mem.get(l, (0, 0))
        cells.append(f"{s['avg_fps']:.0f} · {s['p95_ms']} · {s['max_ms']} · {s['over33']} · {pss}/{gfx}")
    print(f"| {l} | " + " | ".join(cells) + " |")
