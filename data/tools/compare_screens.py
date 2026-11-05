#!/usr/bin/env python3
"""Visual regression for game-screens (task 14).

Compares freshly rendered PNGs (--new DIR) with the previous green run's artifact
(--old DIR). Reports screens whose changed-pixel fraction exceeds --threshold,
writes a Markdown report + thumbnails of the changed screens to --report DIR.
Exit code 0 always (report-only); CI turns it into an artifact.
"""
import argparse
import os
import sys


def load_png(path):
    from PIL import Image
    return Image.open(path).convert("RGB")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--old", required=True)
    ap.add_argument("--new", required=True)
    ap.add_argument("--report", required=True)
    ap.add_argument("--threshold", type=float, default=0.02, help="changed-pixel fraction threshold")
    args = ap.parse_args()

    os.makedirs(args.report, exist_ok=True)
    rows = []
    changed = []
    for name in sorted(os.listdir(args.new)):
        if not name.endswith(".png"):
            continue
        old_path = os.path.join(args.old, name)
        new_path = os.path.join(args.new, name)
        if not os.path.exists(old_path):
            rows.append((name, "new", 1.0))
            changed.append(name)
            continue
        a, b = load_png(old_path), load_png(new_path)
        if a.size != b.size:
            rows.append((name, "size %s -> %s" % (a.size, b.size), 1.0))
            changed.append(name)
            continue
        pa, pb = a.tobytes(), b.tobytes()
        if len(pa) != len(pb):
            rows.append((name, "bytes differ", 1.0))
            changed.append(name)
            continue
        diff = sum(1 for x, y in zip(pa, pb) if abs(x - y) > 8)
        frac = diff / len(pa)
        state = "changed" if frac > args.threshold else "ok"
        if frac > args.threshold:
            changed.append(name)
        rows.append((name, state, frac))
        if frac > args.threshold:
            thumb = os.path.join(args.report, "diff_" + name)
            from PIL import ImageChops
            d = ImageChops.difference(a, b)
            d.save(thumb)

    with open(os.path.join(args.report, "report.md"), "w", encoding="utf-8") as f:
        f.write("# Visual regression (threshold %.1f%%)\n\n| screen | state | changed pixels |\n|---|---|---|\n" % (args.threshold * 100))
        for name, state, frac in rows:
            f.write("| %s | %s | %.2f%% |\n" % (name, state, frac * 100))
        f.write("\nChanged screens: %d\n" % len(changed))
    print("changed screens (>%.1f%%): %s" % (args.threshold * 100, ", ".join(changed) if changed else "none"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
