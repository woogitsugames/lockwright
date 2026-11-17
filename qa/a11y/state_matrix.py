#!/usr/bin/env python3
"""D-139 lock state matrix: family x state pair, before / after, from the shots of
game/tests/a11y_state_shots.gd (docs/handoff/LOCK-STATES-2026-11-17.md).

Uses the same measure as state_report.py (share of the lock picture whose grayscale / deuteranopia /
protanopia value changes by more than DELTA levels; the smallest of the three counts), and adds what
that report does not know:
  - which states a family has at all (lockcore never reports the others, so their pairs are "-");
  - free is taken from the free_lifted pose (a free element at the height of the bound pose), so
    free / bound is not just "the element stands somewhere else";
  - compact contact sheets for the repo: per family one JPEG, rows colour / grayscale, columns states.

  python qa/a11y/state_matrix.py <after_dir> [--before DIR] [--sheets OUT_DIR] [--crop 0,0,1,0.75] [--tag portrait] [--tile 200]
"""
import argparse
import itertools
import os

import numpy as np
from PIL import Image, ImageDraw

from state_report import DELTA, MIN_SHARE, M, cvd, gray

ALL = ["free", "bound", "near", "set", "false_set", "overset", "stress", "open"]
PIN = ALL
NO_FALSE = [s for s in ALL if s != "false_set"]
# States lockcore reports per family (lockcore/src/families/*.cpp: ElementState and view.stress).
HAS = {
    "pin_tumbler": PIN, "dimple": PIN, "magnetic": PIN,
    "wafer": NO_FALSE, "time_lock": NO_FALSE,
    "egyptian": [s for s in NO_FALSE if s != "stress"],
    "lever": ALL, "lever_detector": ALL, "axial_slider": ALL,
    "warded": ["free", "bound", "near", "set", "stress", "open"],
    "combo": [s for s in ALL if s != "stress"], "disc_detainer": [s for s in ALL if s != "stress"],
    "dial_safe": ["free", "bound", "near", "set", "false_set", "open"],
}
ORDER = ["pin_tumbler", "dimple", "magnetic", "wafer", "time_lock", "egyptian", "lever", "lever_detector",
         "axial_slider", "warded", "combo", "disc_detainer", "dial_safe"]


def path(d, fam, st):
    name = "free_lifted" if st == "free" else st
    for n in (name, st):
        for ext in (".png", ".jpg"):
            p = os.path.join(d, f"{fam}__{n}{ext}")
            if os.path.exists(p):
                return p
    return None


def chans(p, crop):
    im = Image.open(p).convert("RGB")
    w, h = im.size
    rgb = np.asarray(im.crop((int(crop[0] * w), int(crop[1] * h), int(crop[2] * w), int(crop[3] * h))), dtype=np.float64) / 255.0
    return [gray(rgb), gray(cvd(rgb, M["deutan"])), gray(cvd(rgb, M["protan"]))]


def matrix(d, crop):
    out = {}
    for fam in ORDER:
        ch = {st: chans(path(d, fam, st), crop) for st in HAS[fam] if path(d, fam, st)}
        for a, b in itertools.combinations(ALL, 2):
            if a in ch and b in ch:
                out[(fam, a, b)] = min(float(np.mean(np.abs(x - y) > DELTA) * 100.0) for x, y in zip(ch[a], ch[b]))
    return out


def fmt(v):
    return "–" if v is None else (f"**{v:.2f}**" if v < MIN_SHARE else f"{v:.2f}")


def table(m):
    lines = ["| para | " + " | ".join(f.replace("_", " ") for f in ORDER) + " |", "|---|" + "---|" * len(ORDER)]
    for a, b in itertools.combinations(ALL, 2):
        lines.append(f"| {a} / {b} | " + " | ".join(fmt(m.get((f, a, b))) for f in ORDER) + " |")
    return lines


def sheet(d, fam, out, crop, tw=200):
    sts = [s for s in HAS[fam] if path(d, fam, s)]
    tiles = []
    for st in sts:
        im = Image.open(path(d, fam, st)).convert("RGB")
        w, h = im.size
        im = im.crop((int(crop[0] * w), int(crop[1] * h), int(crop[2] * w), int(crop[3] * h)))
        tiles.append(im.resize((tw, int(tw * im.size[1] / im.size[0])), Image.LANCZOS))
    th = tiles[0].size[1]
    sh = Image.new("RGB", (tw * len(sts), (th + 16) * 2), (255, 255, 255))
    dr = ImageDraw.Draw(sh)
    for i, (st, t) in enumerate(zip(sts, tiles)):
        g = np.asarray(t, dtype=np.float64) / 255.0
        gt = Image.fromarray(np.repeat(gray(g)[..., None], 3, -1).clip(0, 255).astype(np.uint8))
        for r, tile in enumerate((t, gt)):
            sh.paste(tile, (i * tw, r * (th + 16) + 16))
            dr.text((i * tw + 3, r * (th + 16) + 2), f"{'free (lifted)' if st == 'free' else st} / {['colour', 'gray'][r]}", fill=(0, 0, 0))
    sh.save(out, quality=82)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("after")
    ap.add_argument("--before", default=None)
    ap.add_argument("--sheets", default=None)
    ap.add_argument("--crop", default="0.0,0.0,1.0,0.75")
    ap.add_argument("--tag", default="portrait")
    ap.add_argument("--tile", type=int, default=200, help="sheet tile width in px (landscape shots: 366)")
    args = ap.parse_args()
    crop = [float(v) for v in args.crop.split(",")]
    after = matrix(args.after, crop)
    lines = []
    if args.before:
        before = matrix(args.before, crop)
        lines += [f"### Before ({args.tag})", ""] + table(before) + [""]
        lines += [f"### Changed pairs ({args.tag}): before -> after", "", "| rodzina | para | przed % | po % |", "|---|---|---|---|"]
        for k in sorted(after, key=lambda k: (ORDER.index(k[0]), ALL.index(k[1]), ALL.index(k[2]))):
            if k in before and abs(before[k] - after[k]) >= 0.02:
                lines.append(f"| {k[0]} | {k[1]} / {k[2]} | {fmt(before[k])} | {fmt(after[k])} |")
        lines.append("")
    lines += [f"### After ({args.tag})", ""] + table(after) + [""]
    low = sorted((v, k) for k, v in after.items() if v < 1.0)
    lines += ["### Below 1 % after", ""] + [f"- {k[0]}: {k[1]} / {k[2]} = {v:.2f}" for v, k in low]
    print("\n".join(lines))
    if args.sheets:
        os.makedirs(args.sheets, exist_ok=True)
        for fam in ORDER:
            if path(args.after, fam, "bound"):
                sheet(args.after, fam, os.path.join(args.sheets, f"{fam}_{args.tag}.jpg"), crop, args.tile)


if __name__ == "__main__":
    main()
