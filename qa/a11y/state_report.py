#!/usr/bin/env python3
"""D-90 colour / grayscale audit of the real lock screens (docs/ACCESSIBILITY.md section 3).

Input: the PNGs of game/tests/a11y_state_shots.gd (<family>__<state>.png, one state on every element).
Output (into the same directory unless --out):
  - sheet_<family>.png: rows = colour / grayscale / deuteranopia / protanopia, columns = states;
  - report.md: per family, for every pair of the five DESIGN.md states (+ near break, open) the share
    of section pixels whose grayscale (and CVD-simulated grayscale) value differs by more than
    DELTA levels; a pair below MIN_SHARE is "not told apart without colour".
CVD: Machado, Oliveira, Fernandes 2009, severity 1.0, applied in linear sRGB (same matrices as
mockups/tools/contrast.mjs). Grayscale = Rec. 709 luma of sRGB.

  python qa/a11y/state_report.py <shots_dir> [--out DIR] [--crop 0.0,0.0,1.0,0.75]
"""
import argparse
import itertools
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

STATES = ["free", "bound", "near", "set", "false_set", "overset", "stress", "open"]
CORE = ["bound", "set", "false_set", "overset", "stress"]  # CLAUDE.md: the five states
DELTA = 12        # grayscale levels (0-255) that count as a visible change
MIN_SHARE = 0.25  # % of section pixels that must change for two states to read apart
M = {
    "deutan": np.array([[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]]),
    "protan": np.array([[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]]),
}


def lin(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def unlin(c):
    return np.where(c <= 0.0031308, 12.92 * c, 1.055 * np.clip(c, 0, None) ** (1 / 2.4) - 0.055)


def gray(rgb):  # rgb float 0..1 -> 0..255 luma
    return (0.2126 * rgb[..., 0] + 0.7152 * rgb[..., 1] + 0.0722 * rgb[..., 2]) * 255.0


def cvd(rgb, m):
    out = unlin(np.clip(lin(rgb) @ m.T, 0, 1))
    return np.clip(out, 0, 1)


def load(path, crop):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    box = (int(crop[0] * w), int(crop[1] * h), int(crop[2] * w), int(crop[3] * h))
    return im, np.asarray(im.crop(box), dtype=np.float64) / 255.0


def share(a, b):
    return float(np.mean(np.abs(a - b) > DELTA) * 100.0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("shots")
    ap.add_argument("--out", default=None)
    ap.add_argument("--crop", default="0.0,0.0,1.0,0.75", help="box as fractions x0,y0,x1,y1 (portrait: section + plug face, not the tool roll)")
    args = ap.parse_args()
    out = args.out or args.shots
    os.makedirs(out, exist_ok=True)
    crop = [float(v) for v in args.crop.split(",")]
    fams = sorted({f.split("__")[0] for f in os.listdir(args.shots) if "__" in f and f.endswith((".png", ".jpg"))})
    lines = ["# Lock states without colour (D-90)", "",
             f"Share of section pixels (crop {args.crop}) whose value changes by > {DELTA}/255 between two states. "
             f"Below {MIN_SHARE}% = not told apart. Columns: grayscale / deuteranopia / protanopia (as grayscale).", ""]
    worst_all = []
    for fam in fams:
        imgs, chans = {}, {}
        for st in STATES:
            p = os.path.join(args.shots, f"{fam}__{st}.png")
            if not os.path.exists(p):
                p = p[:-4] + ".jpg"  # evidence in the repo is stored as JPEG
            if not os.path.exists(p):
                continue
            im, rgb = load(p, crop)
            imgs[st] = im
            chans[st] = {"gray": gray(rgb), "deutan": gray(cvd(rgb, M["deutan"])), "protan": gray(cvd(rgb, M["protan"]))}
        if not chans:
            continue
        # sheet
        sts = [s for s in STATES if s in imgs]
        tw = 206
        th = int(tw * imgs[sts[0]].size[1] / imgs[sts[0]].size[0])
        sheet = Image.new("RGB", (tw * len(sts), (th + 18) * 4), (255, 255, 255))
        d = ImageDraw.Draw(sheet)
        for i, st in enumerate(sts):
            full = np.asarray(imgs[st], dtype=np.float64) / 255.0
            rows = [full, np.repeat(gray(full)[..., None] / 255.0, 3, -1),
                    np.repeat(gray(cvd(full, M["deutan"]))[..., None] / 255.0, 3, -1),
                    np.repeat(gray(cvd(full, M["protan"]))[..., None] / 255.0, 3, -1)]
            for r, arr in enumerate(rows):
                tile = Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).resize((tw, th))
                sheet.paste(tile, (i * tw, r * (th + 18) + 18))
                d.text((i * tw + 4, r * (th + 18) + 3), f"{st} / {['colour', 'gray', 'deutan', 'protan'][r]}", fill=(0, 0, 0))
        sheet.save(os.path.join(out, f"sheet_{fam}.png"))
        # table
        lines += [f"## {fam}", "", "| pair | gray % | deutan % | protan % | verdict |", "|---|---|---|---|---|"]
        for a, b in itertools.combinations([s for s in STATES if s in chans], 2):
            v = [share(chans[a][k], chans[b][k]) for k in ("gray", "deutan", "protan")]
            ok = min(v) >= MIN_SHARE
            core = a in CORE and b in CORE
            verdict = "ok" if ok else ("**NOT APART**" if core else "not apart (not a core pair)")
            if not ok:
                worst_all.append((fam, a, b, min(v), core))
            lines.append(f"| {a} / {b} | {v[0]:.2f} | {v[1]:.2f} | {v[2]:.2f} | {verdict} |")
        lines.append("")
    lines += ["## Summary", ""]
    core_fail = [w for w in worst_all if w[4]]
    lines.append(f"Core pairs (bound, set, false_set, overset, near break) not told apart: {len(core_fail)}")
    for fam, a, b, v, _ in core_fail:
        lines.append(f"- {fam}: {a} / {b} ({v:.2f}%)")
    other = [w for w in worst_all if not w[4]]
    if other:
        lines.append("")
        lines.append(f"Other pairs below the threshold: {len(other)}")
        for fam, a, b, v, _ in other:
            lines.append(f"- {fam}: {a} / {b} ({v:.2f}%)")
    with open(os.path.join(out, "report.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print("\n".join(lines[-(len(core_fail) + len(other) + 6):]))
    return 1 if core_fail else 0


if __name__ == "__main__":
    sys.exit(main())
