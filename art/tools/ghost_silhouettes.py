#!/usr/bin/env python3
# RETIRED (D-83, 2026-11-07): hints are chalk-only, the ghost hand and game/assets/ui/ghost/ are gone.
# Kept for history with its sources in contrib/gpt/G23/images/; do not regenerate into the game.
# Lockwright — ghost hand silhouettes (ONBOARDING §2.2) from the G23 hand photos (white background).
#
#   python3 art/tools/ghost_silhouettes.py [--src contrib/gpt/G23/images] [--out game/assets/ui/ghost] [--debug DIR]
#
# Per photo: alpha = distance from the (estimated) white background, holes filled, largest blob kept; the
# arm/wrist fades out towards the frame edge it enters from (a shadow "from the wrist", no hard cut);
# scaled to PX_PER_DP and blurred so the edge is ~12 dp soft (§2.2). Output: white RGB + alpha (the game
# tints it black at 35 %), padded so the blur is never clipped, plus ghost_silhouettes.json with each
# texture's hotspot (the point that sits on the gesture position: the thumb pad) and its dp scale.
import argparse, json, os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

PX_PER_DP = 2.0          # texture px per dp (GhostHand.texture_scale = 1 / PX_PER_DP)
SOFT_DP = 12.0           # 10-90 % edge width of the shadow (§2.2)
PAD_DP = 14.0

# name: (source, thumb width in dp, hotspot in source px (thumb pad / thumb on the tool), fade edge(s), source thumb width px)
SPEC = {
    'thumb_left_press':  ('thumb_left_press.png',  40.0, (515, 500), ('bottom', 'left'), 175),
    'thumb_right_press': ('thumb_right_press.png', 40.0, (468, 470), ('bottom', 'right'), 175),
    'thumb_right_slide': ('thumb_right_slide.png', 40.0, (452, 545), ('right',), 150),
    'hand_left_tool':    ('hand_left_tool.png',    32.0, (520, 320), ('bottom', 'left'), 115),
    'hand_right_tool':   ('hand_right_tool.png',   32.0, (360, 390), ('bottom', 'right'), 110),
    'hand_right_open':   ('hand_right_open.png',   32.0, (130, 630), ('bottom', 'right'), 110),
}


def mask_of(path):
    rgb = np.asarray(Image.open(path).convert('RGB')).astype(np.float32)
    border = np.concatenate([rgb[:8].reshape(-1, 3), rgb[:, :8].reshape(-1, 3)])
    bg = np.median(border, 0)
    d = np.max(bg[None, None] - rgb, -1)                    # darker than the paper in any channel
    a = np.clip((d - 10.0) / 22.0, 0, 1)
    core = ndimage.binary_fill_holes(a > 0.5)
    lab, n = ndimage.label(core)
    if n > 1:
        sizes = ndimage.sum(core, lab, range(1, n + 1)); keep = lab == (1 + int(np.argmax(sizes)))
        # keep pieces that are at least 2 % of the main blob (the thin tool can split off at its tip)
        for i, s in enumerate(sizes):
            if s >= 0.02 * sizes.max(): keep |= lab == i + 1
        core = keep
    grown = ndimage.binary_dilation(core, iterations=3)
    a = np.where(core, 1.0, np.where(grown, a, 0.0))
    return a.astype(np.float32)


def edge_fade(a, edges, frac=0.12):
    h, w = a.shape; yy, xx = np.mgrid[0:h, 0:w].astype(np.float32); f = np.ones_like(a)
    for e in edges:
        dist = {'bottom': h - 1 - yy, 'top': yy, 'left': xx, 'right': w - 1 - xx}[e] / (frac * (h if e in ('top', 'bottom') else w))
        f = np.minimum(f, np.clip(dist, 0, 1) ** 1.5)
    return a * f


def build(name, src_dir, out_dir, debug=None):
    src, thumb_dp, hot, edges, thumb_px = SPEC[name]
    a = edge_fade(mask_of(os.path.join(src_dir, src)), edges)
    s = thumb_dp * PX_PER_DP / thumb_px                     # source px -> texture px
    ys, xs = np.nonzero(a > 0.02); y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    crop = a[y0:y1, x0:x1]
    nw, nh = max(1, round(crop.shape[1] * s)), max(1, round(crop.shape[0] * s))
    small = np.asarray(Image.fromarray(crop, 'F').resize((nw, nh), Image.LANCZOS))
    pad = int(round(PAD_DP * PX_PER_DP))
    big = np.pad(np.clip(small, 0, 1), pad)
    sigma = SOFT_DP * PX_PER_DP / 2.56                      # 10-90 % of a Gaussian edge = 2.56 sigma
    soft = np.clip(ndimage.gaussian_filter(big, sigma), 0, 1)
    soft = np.clip(soft / max(soft.max(), 1e-6), 0, 1)      # thin parts (tool, fingertips) still reach full shadow at the core
    h, w = soft.shape
    img = np.zeros((h, w, 4), np.uint8); img[..., :3] = 255; img[..., 3] = np.round(soft * 255).astype(np.uint8)
    Image.fromarray(img, 'RGBA').save(os.path.join(out_dir, name + '.png'), optimize=True)
    hx, hy = (hot[0] - x0) * s + pad, (hot[1] - y0) * s + pad
    meta = {'size_px': [w, h], 'hotspot': [round(hx / w, 4), round(hy / h, 4)], 'px_per_dp': PX_PER_DP,
            'size_dp': [round(w / PX_PER_DP, 1), round(h / PX_PER_DP, 1)]}
    if debug:
        rgb = np.asarray(Image.open(os.path.join(src_dir, src)).convert('RGB')).copy()
        m = (a > 0.5)
        rgb[m] = (rgb[m] * 0.5 + np.array([255, 0, 0]) * 0.5).astype(np.uint8)
        dbg = Image.fromarray(rgb); from PIL import ImageDraw
        d = ImageDraw.Draw(dbg)
        for g in range(0, 1024, 128):
            d.line([(g, 0), (g, 1024)], fill=(0, 0, 255)); d.line([(0, g), (1024, g)], fill=(0, 0, 255))
        d.ellipse([hot[0] - 12, hot[1] - 12, hot[0] + 12, hot[1] + 12], outline=(0, 160, 0), width=5)
        dbg.save(os.path.join(debug, name + '_dbg.jpg'))
    return meta


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', default='contrib/gpt/G23/images'); ap.add_argument('--out', default='game/assets/ui/ghost')
    ap.add_argument('--debug'); ap.add_argument('--only', nargs='*')
    o = ap.parse_args(); os.makedirs(o.out, exist_ok=True)
    if o.debug: os.makedirs(o.debug, exist_ok=True)
    meta = {'schema': 'lockwright.ghost/1', 'soft_dp': SOFT_DP, 'source': 'contrib/gpt/G23 (ChatGPT image_gen)', 'textures': {}}
    for n in (o.only or SPEC):
        meta['textures'][n] = build(n, o.src, o.out, o.debug); print('WROTE', n, meta['textures'][n])
    with open(os.path.join(o.out, 'ghost_silhouettes.json'), 'w') as fh: json.dump(meta, fh, indent=1)


if __name__ == '__main__':
    main()
