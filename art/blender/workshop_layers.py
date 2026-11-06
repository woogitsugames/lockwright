#!/usr/bin/env python3
"""Workshop furnishing overlays (D-71): raw variant renders -> transparent layers aligned to the base render.

    blender -b -P art/blender/workshop.py -- --layers art/renders/workshop_layers/raw --res 810x1440 --samples 32
    python3 art/blender/workshop_layers.py                       # raw/ -> masters + game WebPs + compare sheet

Every variant is rendered with the same camera, settings and seed as raw/base.png, with exactly one furnishing
shown. The overlay keeps the variant's pixels where it differs from the base (the object, its shadow and the
light it adds), with a soft alpha edge; elsewhere it is transparent. The game stacks the base and the owned
overlays in `z` order (game/data/furnishings.json), all full-frame, so alignment is exact by construction.

Outputs:
  art/renders/workshop_layers/base.png, furn_<id>.png       masters (RGBA PNG)
  art/renders/workshop_layers/compare.jpg                   base | all furnishings | masks
  game/assets/ui/workshop/workshop_base.webp, furn_<id>.webp game layers (lossy WebP, alpha kept)
"""
import argparse
import json
import os

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def overlay(base, var, thr, grow, soft):
    """RGBA overlay: variant pixels where |variant - base| > thr (speckle removed, grown, feathered)."""
    b = np.asarray(base, dtype=np.float32) / 255.0
    v = np.asarray(var, dtype=np.float32) / 255.0
    diff = np.abs(v - b).max(axis=2)
    m = Image.fromarray(((diff > thr) * 255).astype(np.uint8))
    m = m.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.MaxFilter(3))  # drop isolated noise pixels
    m = m.filter(ImageFilter.MaxFilter(grow))                               # cover the anti-aliased rim
    m = m.filter(ImageFilter.GaussianBlur(soft))
    out = var.convert("RGBA")
    out.putalpha(m)
    return out, (np.asarray(m) > 8).mean()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--raw", default=os.path.join(ROOT, "art", "renders", "workshop_layers", "raw"))
    ap.add_argument("--out", default=os.path.join(ROOT, "art", "renders", "workshop_layers"))
    ap.add_argument("--game", default=os.path.join(ROOT, "game", "assets", "ui", "workshop"))
    ap.add_argument("--thr", type=float, default=0.03, help="per-channel difference that counts as changed (0..1)")
    ap.add_argument("--grow", type=int, default=5, help="mask dilation, px (odd)")
    ap.add_argument("--soft", type=float, default=1.5, help="mask feather, px")
    ap.add_argument("--quality", type=int, default=82, help="WebP quality of the game layers")
    a = ap.parse_args()
    data = json.load(open(os.path.join(ROOT, "game", "data", "furnishings.json"), encoding="utf-8"))
    os.makedirs(a.out, exist_ok=True)
    os.makedirs(a.game, exist_ok=True)
    base = Image.open(os.path.join(a.raw, "base.png")).convert("RGB")
    base.save(os.path.join(a.out, "base.png"))
    base.save(os.path.join(a.game, data["base"]), "WEBP", quality=a.quality, method=6)
    layers = []
    for f in data["furnishings"]:
        var = Image.open(os.path.join(a.raw, f["id"] + ".png")).convert("RGB")
        ov, cover = overlay(base, var, a.thr, a.grow, a.soft)
        ov.save(os.path.join(a.out, "furn_%s.png" % f["id"]))
        ov.save(os.path.join(a.game, f["layer"]), "WEBP", quality=a.quality, alpha_quality=90, method=6)
        layers.append((f.get("z", 20), f["id"], ov))
        print("%-14s mask %5.1f %%  webp %6.1f KB" % (f["id"], cover * 100, os.path.getsize(os.path.join(a.game, f["layer"])) / 1024))
    # compare sheet: base | everything stacked like the game does | alpha masks
    full = base.convert("RGBA")
    masks = Image.new("L", base.size, 0)
    for _, _, ov in sorted(layers, key=lambda t: (t[0], t[1])):
        full = Image.alpha_composite(full, ov)
        masks = Image.fromarray(np.maximum(np.asarray(masks), np.asarray(ov.getchannel("A"))))
    w, h = base.size
    sheet = Image.new("RGB", (w * 3, h))
    sheet.paste(base, (0, 0))
    sheet.paste(full.convert("RGB"), (w, 0))
    sheet.paste(masks.convert("RGB"), (2 * w, 0))
    sheet.thumbnail((1800, 1800))
    sheet.save(os.path.join(a.out, "compare.jpg"), quality=85)
    print("base webp %.1f KB, compare.jpg written" % (os.path.getsize(os.path.join(a.game, data["base"])) / 1024))


if __name__ == "__main__":
    main()
