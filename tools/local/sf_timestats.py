#!/usr/bin/env python3
"""Frame-time stats of the game's surface from Android SurfaceFlinger TimeStats.

The Godot Vulkan SurfaceView is not covered by `dumpsys gfxinfo` (HWUI only) and
`dumpsys SurfaceFlinger --latency` is empty on Android 16, but TimeStats keeps a
per-layer present-to-present histogram. Usage (Git Bash):

  python tools/local/sf_timestats.py start            # clear + enable TimeStats
  ... interact with the game ...
  python tools/local/sf_timestats.py dump LABEL [--out file.txt] [--json file.json]
  python tools/local/sf_timestats.py stop             # disable + clear (restore the device)

`dump` prints one line: frames, average FPS, p50/p95/p99/max present-to-present (ms),
frames > 25/33/50 ms and "1% low" FPS (1000 / p99). Histogram buckets are 1 ms wide up to
34 ms, then 2-4 ms, then 50 ms, so values above 150 ms are bucket lower bounds.
"""
import json
import os
import re
import subprocess
import sys

ADB = os.environ.get("ADB_W", "C:/tools/android/platform-tools/adb.exe")
PKG = os.environ.get("LW_PKG", "com.woogitsugames.lockwright")


def adb(*args: str) -> str:
    return subprocess.run([ADB, "shell", *args], capture_output=True, text=True, check=False).stdout


def parse_hist(line: str) -> list[tuple[int, int]]:
    out = []
    for tok in line.split():
        m = re.match(r"(\d+)ms=(\d+)$", tok)
        if m:
            out.append((int(m.group(1)), int(m.group(2))))
    return out


def layer_hist(dump: str) -> tuple[list[tuple[int, int]], float]:
    """present2present histogram of the biggest game layer (SurfaceView ... BLAST)."""
    best: list[tuple[int, int]] = []
    best_fps = 0.0
    lines = dump.splitlines()
    i = 0
    while i < len(lines):
        if lines[i].startswith("layerName = ") and PKG in lines[i] and "SurfaceView" in lines[i]:
            fps = 0.0
            j = i + 1
            while j < len(lines) and not lines[j].startswith("layerName = "):
                if lines[j].startswith("averageFPS = "):
                    fps = float(lines[j].split("=")[1])
                if lines[j].startswith("present2present histogram"):
                    h = parse_hist(lines[j + 1]) if j + 1 < len(lines) else []
                    if sum(c for _, c in h) > sum(c for _, c in best):
                        best, best_fps = h, fps
                    break
                j += 1
            i = j
        else:
            i += 1
    return best, best_fps


def pct(h: list[tuple[int, int]], p: float) -> int:
    total = sum(c for _, c in h)
    if total == 0:
        return 0
    acc = 0
    for ms, c in h:
        acc += c
        if acc >= total * p:
            return ms
    return h[-1][0]


def summarize(label: str, h: list[tuple[int, int]], fps: float) -> dict:
    n = sum(c for _, c in h)
    total_ms = sum((ms + 0.5) * c for ms, c in h) or 1
    mx = max((ms for ms, c in h if c), default=0)
    p99 = pct(h, 0.99)
    return {
        "label": label,
        "frames": n,
        "avg_fps": round(n * 1000.0 / total_ms, 1) if n else 0.0,
        "sf_average_fps": fps,
        "p50_ms": pct(h, 0.5),
        "p95_ms": pct(h, 0.95),
        "p99_ms": p99,
        "max_ms": mx,
        "over25": sum(c for ms, c in h if ms > 25),
        "over33": sum(c for ms, c in h if ms > 33),
        "over50": sum(c for ms, c in h if ms > 50),
        "low1_fps": round(1000.0 / p99, 1) if p99 else 0.0,
        "hist_nonzero": {str(ms): c for ms, c in h if c},
    }


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    cmd = sys.argv[1]
    if cmd == "start":
        adb("dumpsys", "SurfaceFlinger", "--timestats", "-clear", "-enable")
        return 0
    if cmd == "stop":
        adb("dumpsys", "SurfaceFlinger", "--timestats", "-disable", "-clear")
        return 0
    if cmd == "dump":
        label = sys.argv[2] if len(sys.argv) > 2 else "sample"
        dump = adb("dumpsys", "SurfaceFlinger", "--timestats", "-dump", "-maxlayers", "8")
        args = sys.argv[3:]
        if "--out" in args:
            with open(args[args.index("--out") + 1], "a", encoding="utf-8") as f:
                f.write("### %s\n%s\n" % (label, dump))
        h, fps = layer_hist(dump)
        s = summarize(label, h, fps)
        print("%-28s frames=%5d fps=%5.1f p50=%2d p95=%3d p99=%3d max=%4d >25=%3d >33=%3d >50=%3d 1%%low=%5.1f" % (
            label, s["frames"], s["avg_fps"], s["p50_ms"], s["p95_ms"], s["p99_ms"], s["max_ms"],
            s["over25"], s["over33"], s["over50"], s["low1_fps"]))
        if "--json" in args:
            path = args[args.index("--json") + 1]
            data = []
            if os.path.exists(path):
                with open(path, encoding="utf-8") as f:
                    data = json.load(f)
            data.append(s)
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=1)
        # restart the window for the next sample
        adb("dumpsys", "SurfaceFlinger", "--timestats", "-clear")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
