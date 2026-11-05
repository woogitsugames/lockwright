#!/usr/bin/env python3
# Lockwright — D-58 character compositing for the arrival hold frame (plain Python: Pillow + NumPy, no Blender).
#
#   python3 art/blender/arrival_composite.py --plate art/renders/arrival/wrong_floor_night_hold.png \
#       --figure kazimierz=contrib/.../D1_kazimierz_fullbody.png [--figure teresa=...] \
#       [--shadow art/renders/arrival/wrong_floor_night_shadow_kazimierz.png] --out composite.png
#   python3 art/blender/arrival_composite.py --placeholder kazimierz --out placeholder_kazimierz.png
#
# The plate's <plate>.json (written by arrival_scene.py) gives per slot: feet line, height in px, and the lights
# seen from the figure (colour, relative strength, image-space direction). Per figure:
#   1. scale so the alpha bbox height == height_px, feet (bbox bottom centre) on feet_center;
#   2. colour match: neutralise the cut-out's own cast (grey-world on mid tones), multiply by the weighted light
#      colour, match mean luminance to the plate's lit wall around the head, compress contrast towards the scene;
#   3. directional relight: a soft ramp across the figure, brighter on the key-light side, darker away;
#   4. shadows: Blender shadow-ratio map if given (--shadow, physically right: falls on floor, wall and door),
#      else a 2D contact shadow (tight occlusion under the feet + soft cast blob away from the key light);
#   5. light wrap: blurred plate light bleeding over the silhouette edge; slight edge softening; matched grain;
#   6. optional --breath N: writes N frames of idle motion (1.2 % vertical breathing scale from the feet, small
#      weight shift) for the game's in-place loop.
import argparse, json, math, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))

def srgb_to_lin(c): return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
def lin_to_srgb(c):
    c = np.clip(c, 0, None); return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)
def lum(c): return c[..., 0] * 0.2126 + c[..., 1] * 0.7152 + c[..., 2] * 0.0722
def blur(a, r):
    """Gaussian blur of a float HxW or HxWxC array via Pillow (per channel, 32-bit float mode)."""
    if r <= 0: return a
    if a.ndim == 2: return np.asarray(Image.fromarray(a.astype(np.float32), 'F').filter(ImageFilter.GaussianBlur(r)))
    return np.stack([blur(a[..., i], r) for i in range(a.shape[2])], -1)

# ---------------------------------------------------------------- placeholder (until Magnific section D arrives)
def placeholder(slot, out, h=1600):
    """Neutral grey full-body silhouette with alpha, clearly labelled. Proportions of an adult (8 heads)."""
    w = int(h * 0.42); im = Image.new('RGBA', (w, h), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    g = (128, 128, 128, 255); hd = h / 8.0; cx = w / 2
    d.ellipse([cx - hd * 0.42, 6, cx + hd * 0.42, hd + 6], fill=g)                                 # head
    d.rectangle([cx - hd * 0.18, hd, cx + hd * 0.18, hd * 1.35], fill=g)                           # neck
    d.rounded_rectangle([cx - hd * 1.0, hd * 1.25, cx + hd * 1.0, hd * 4.3], radius=hd * 0.45, fill=g)   # torso + coat
    d.rounded_rectangle([cx - hd * 1.18, hd * 1.4, cx - hd * 0.78, hd * 4.15], radius=hd * 0.2, fill=g)  # arms
    d.rounded_rectangle([cx + hd * 0.78, hd * 1.4, cx + hd * 1.18, hd * 4.15], radius=hd * 0.2, fill=g)
    d.rounded_rectangle([cx - hd * 0.82, hd * 4.0, cx - hd * 0.06, h - hd * 0.12], radius=hd * 0.15, fill=g)  # legs
    d.rounded_rectangle([cx + hd * 0.06, hd * 4.0, cx + hd * 0.82, h - hd * 0.12], radius=hd * 0.15, fill=g)
    d.rounded_rectangle([cx - hd * 0.95, h - hd * 0.28, cx - hd * 0.02, h - 1], radius=hd * 0.1, fill=g)     # shoes
    d.rounded_rectangle([cx + hd * 0.02, h - hd * 0.28, cx + hd * 0.95, h - 1], radius=hd * 0.1, fill=g)
    try: font = ImageFont.truetype(os.path.join(ROOT, 'mockups', 'fonts', 'AtkinsonHyperlegibleNext-wght.ttf'), int(hd * 0.34))
    except OSError: font = ImageFont.load_default()
    for i, t in enumerate(('PLACEHOLDER', slot.upper(), 'not final art')):
        d.text((cx, hd * (2.2 + 0.5 * i)), t, fill=(60, 60, 60, 255), font=font, anchor='mm')
    im.save(out); return out

# ---------------------------------------------------------------- compositing
def load_rgba(p):
    im = Image.open(p).convert('RGBA'); a = np.asarray(im).astype(np.float32) / 255.0
    return srgb_to_lin(a[..., :3]), a[..., 3]

def place_figure(plate_lin, slot, fig_path, meta, shadow_ratio=None, phase=0.0, breath=0.0):
    H, W = plate_lin.shape[:2]
    rgb, a = load_rgba(fig_path)
    ys, xs = np.nonzero(a > 0.5); y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
    rgb, a = rgb[y0:y1 + 1, x0:x1 + 1], a[y0:y1 + 1, x0:x1 + 1]
    hpx = meta['height_px'] * (1 + breath * 0.012 * math.sin(2 * math.pi * phase))
    sc = hpx / rgb.shape[0]; nw, nh = max(1, int(round(rgb.shape[1] * sc))), max(1, int(round(rgb.shape[0] * sc)))
    def rs(x, mode=Image.LANCZOS):
        return np.stack([np.asarray(Image.fromarray(x[..., i].astype(np.float32), 'F').resize((nw, nh), mode)) for i in range(x.shape[2])], -1) \
            if x.ndim == 3 else np.asarray(Image.fromarray(x.astype(np.float32), 'F').resize((nw, nh), mode))
    rgb = np.clip(rs(rgb), 0, None); a = np.clip(rs(a), 0, 1)
    fx = meta['feet_center'][0] * W + breath * 1.5 * math.sin(2 * math.pi * phase * 0.5) * sc * 10
    fy = meta['feet_center'][1] * H
    ox, oy = int(round(fx - nw / 2)), int(round(fy - nh))

    # --- colour match
    lights = meta['lights']; key = lights[0]
    w = np.array([l['strength_rel'] for l in lights]); cols = np.array([l['color_linear'] for l in lights])
    light_col = (cols * w[:, None]).sum(0) / w.sum(); light_col = light_col / light_col.max()
    m = a > 0.9; mid = m & (lum(rgb) > np.percentile(lum(rgb)[m], 20)) & (lum(rgb) < np.percentile(lum(rgb)[m], 80))
    cast = rgb[mid].mean(0); rgb = rgb / (cast / cast.mean())               # neutralise the photo's own white balance
    rgb = rgb * light_col
    # target exposure: the plate's wall around the upper body (excluding the darkest/brightest 10 %)
    bx0, bx1 = max(0, ox - nw // 2), min(W, ox + nw + nw // 2); by0, by1 = max(0, oy), min(H, oy + nh // 2)
    region = lum(plate_lin[by0:by1, bx0:bx1]).ravel(); region = region[(region > np.percentile(region, 10)) & (region < np.percentile(region, 90))]
    target = float(np.median(region)) * 0.85                                # clothes/skin sit a little under a lit lime wall
    cur = float(np.median(lum(rgb)[m])); rgb = rgb * (target / max(cur, 1e-5))
    # contrast towards the scene: compress highlights a bit (photo flash/studio look -> stairwell)
    L = lum(rgb)[..., None]; rgb = rgb * (1.0 / (1.0 + 0.35 * np.clip(L / max(target, 1e-5) - 1, 0, None)))

    # --- directional relight: key light side brighter, far side darker; head more lit than feet under a top light
    d2 = np.array(key['dir2d_to_light'], dtype=np.float32); d2 = d2 / (np.linalg.norm(d2) + 1e-6)
    yy, xx = np.mgrid[0:nh, 0:nw].astype(np.float32)
    u = ((xx - nw / 2) / nw) * d2[0] + ((yy - nh / 2) / nh) * d2[1] * 0.6
    ramp = 1.0 + 0.55 * np.clip(u * 2, -1, 1)
    ramp *= 1.0 + 0.25 * max(0.0, key['elevation_deg'] / 90.0) * (0.5 - yy / nh)
    rgb = rgb * ramp[..., None]

    # --- shadows on the plate
    out = plate_lin.copy()
    if shadow_ratio is not None:
        out = out * shadow_ratio[..., None]
    else:
        # contact occlusion: tight dark ellipse under the feet, plus a soft cast blob pushed away from the key light
        sh = np.zeros((H, W), np.float32); im = Image.fromarray(sh, 'F'); d = ImageDraw.Draw(im)
        fl = meta['feet_line']; fw = (fl[1][0] - fl[0][0]) * W
        d.ellipse([fx - fw * 0.42, fy - fw * 0.06, fx + fw * 0.42, fy + fw * 0.05], fill=0.75)
        k2 = -d2; cx, cy = fx + k2[0] * fw * 0.9, fy + max(0.05, k2[1]) * fw * 0.25
        d.ellipse([cx - fw * 0.7, cy - fw * 0.14, cx + fw * 0.7, cy + fw * 0.14], fill=0.45)
        sh = blur(np.asarray(im), max(1.5, fw * 0.05)) + blur(np.asarray(im), max(3, fw * 0.18)) * 0.6
        out = out * (1 - np.clip(sh, 0, 0.85))[..., None]

    # --- light wrap + paste
    X0, Y0, X1, Y1 = max(0, ox), max(0, oy), min(W, ox + nw), min(H, oy + nh)
    sx0, sy0 = X0 - ox, Y0 - oy; sx1, sy1 = sx0 + (X1 - X0), sy0 + (Y1 - Y0)
    fa = a[sy0:sy1, sx0:sx1]; frgb = rgb[sy0:sy1, sx0:sx1]
    bg = out[Y0:Y1, X0:X1]
    rad = max(2.0, nh * 0.012)
    bgb = blur(bg, rad * 2.5)
    inner = np.clip(fa - blur(fa, rad), 0, 1) * 0 + np.clip(1 - blur(fa, rad), 0, 1) * fa       # 1 at the edge, 0 inside
    wrap = 0.55 * inner[..., None]
    frgb = frgb * (1 - wrap) + bgb * wrap * 1.1
    fa_soft = np.clip(blur(fa, 0.6), 0, 1)
    out[Y0:Y1, X0:X1] = bg * (1 - fa_soft[..., None]) + frgb * fa_soft[..., None]
    return out

def add_grain(lin, amount, seed=7):
    rng = np.random.default_rng(seed); n = rng.normal(0, 1, lin.shape[:2]).astype(np.float32)
    n = blur(n, 0.5); return lin * (1 + amount * n[..., None])

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--plate'); ap.add_argument('--anchors'); ap.add_argument('--figure', action='append', default=[])
    ap.add_argument('--shadow'); ap.add_argument('--out', required=True); ap.add_argument('--placeholder')
    ap.add_argument('--grain', type=float, default=0.025); ap.add_argument('--breath', type=int, default=0)
    o = ap.parse_args()
    if o.placeholder:
        print('WROTE', placeholder(o.placeholder, o.out)); return
    meta = json.load(open(o.anchors or os.path.splitext(o.plate)[0] + '.json'))
    plate = np.asarray(Image.open(o.plate).convert('RGB')).astype(np.float32) / 255.0
    plate_lin = srgb_to_lin(plate)
    H, W = plate.shape[:2]
    for f in meta['figures'].values():   # anchors are normalised; the JSON's height_px is for its own width/height
        f['height_px'] = f['height_px'] * H / meta['height']
    shadow = None
    if o.shadow:
        s = Image.open(o.shadow); s = s.convert('RGBA') if s.mode != 'I;16' else s
        arr = np.asarray(s).astype(np.float32); arr = arr[..., :3].mean(-1) / 255.0 if arr.ndim == 3 else arr / 65535.0
        if arr.shape != (H, W): arr = np.asarray(Image.fromarray(arr, 'F').resize((W, H), Image.BILINEAR))
        shadow = np.clip(blur(arr, 1.0), 0, 1)
    figs = [f.split('=', 1) for f in o.figure]
    frames = max(1, o.breath)
    for i in range(frames):
        out = plate_lin
        for slot, path in figs:
            out = place_figure(out, slot, path, meta['figures'][slot], shadow, phase=i / frames, breath=1.0 if o.breath else 0.0)
        out = add_grain(out, o.grain, seed=7 + i)
        img = Image.fromarray((np.clip(lin_to_srgb(out), 0, 1) * 255 + 0.5).astype(np.uint8))
        p = o.out if frames == 1 else o.out.replace('.png', '_%02d.png' % i)
        img.save(p); print('WROTE', p)

if __name__ == '__main__':
    main()
