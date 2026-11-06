#!/usr/bin/env python3
# Lockwright — D-58 character compositing for the arrival hold frame (plain Python: Pillow + NumPy, no Blender).
#
#   python3 art/blender/arrival_composite.py --plate art/renders/arrival/wrong_floor_night_hold.png \
#       --figure kazimierz=contrib/.../D1_kazimierz_fullbody.png [--figure teresa=...] \
#       [--shadow art/renders/arrival/wrong_floor_night_shadow_kazimierz.png] --out composite.png
#   python3 art/blender/arrival_composite.py --placeholder kazimierz --out placeholder_kazimierz.png
#   python3 art/blender/arrival_composite.py --contact art/renders/arrival/wrong_floor_night_seq --out sheet.png
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
from scipy import ndimage
from PIL import Image, ImageDraw, ImageFilter, ImageFont

EXPOSURE = 1.0   # figure brightness relative to the plate's light around it (--exposure)
WRAP = 0.30      # light wrap strength at the silhouette edge (--wrap; 0.55 before G23 gave a glow on real photos)
WARM = 0.5      # share of the anchors' light colour in the tint vs the plate's own colour around the figure (--warm)
OCCLUDE_MM = 180.0  # scene depth this much nearer than the slot's feet hides the figure (--occlude-mm)
TINT_GAIN = 1.0  # >1 pushes the figure further into the scene's light colour (--tint-gain)
SAT = 1.0       # saturation of the figure after the tint (--sat)
ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))

def srgb_to_lin(c): return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
def lin_to_srgb(c):
    c = np.clip(c, 0, None); return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(c, 1 / 2.4) - 0.055)
def lum(c): return c[..., 0] * 0.2126 + c[..., 1] * 0.7152 + c[..., 2] * 0.0722
def _box(a, k, axis):
    if k < 1: return a
    pad = [(0, 0)] * a.ndim; pad[axis] = (k + 1, k)
    c = np.cumsum(np.pad(a, pad, mode='edge'), axis=axis, dtype=np.float64)
    n = a.shape[axis]
    hi = np.take(c, np.arange(2 * k + 1, 2 * k + 1 + n), axis=axis); lo = np.take(c, np.arange(0, n), axis=axis)
    return ((hi - lo) / (2 * k + 1)).astype(np.float32)
def blur(a, r):
    """Approximate Gaussian blur (sigma r px) of a float HxW or HxWxC array: three box passes per axis."""
    if r <= 0: return a
    k = max(1, int(round(math.sqrt(12 * r * r / 3 + 1) - 1) // 2)) if r >= 0.8 else 0
    a = a.astype(np.float32)
    if k == 0:   # sub-pixel softening: 3-tap
        w = min(0.25, r * 0.3)
        for ax in (0, 1): a = a * (1 - 2 * w) + (np.roll(a, 1, ax) + np.roll(a, -1, ax)) * w
        return a
    for ax in (0, 1):
        for _ in range(3): a = _box(a, k, ax)
    return a

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

def place_figure(plate_lin, slot, fig_path, meta, shadow_ratio=None, phase=0.0, breath=0.0, depth=None, layers=None):
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
    m = a > 0.9; mid = m & (lum(rgb) >= np.percentile(lum(rgb)[m], 20)) & (lum(rgb) <= np.percentile(lum(rgb)[m], 80))
    if mid.sum() < 50: mid = m                                          # flat cut-outs (placeholders)
    cast = np.maximum(rgb[mid].mean(0), 1e-4); rgb = rgb / (cast / cast.mean())               # neutralise the photo's own white balance
    # tint: the plate's own colour of light around the figure (it already went through the AgX look), mixed with the
    # light colours from the anchors (so a figure in a neutral spot still gets the bulb's warmth)
    rx0, rx1 = max(0, ox - nw), min(W, ox + 2 * nw); ry0, ry1 = max(0, oy), min(H, oy + nh)
    reg = plate_lin[ry0:ry1, rx0:rx1].reshape(-1, 3); rl_ = lum(reg); reg = reg[rl_ > np.percentile(rl_, 40)]
    pc = reg.mean(0); pc = pc / max(lum(pc[None])[0], 1e-6)
    lc = light_col / max(lum(light_col[None])[0], 1e-6)
    tint = np.clip((1 - WARM) * pc + WARM * lc, 0, None) ** TINT_GAIN; tint = tint / lum(tint[None])[0]
    rgb = rgb * tint
    if SAT != 1.0:
        L0 = lum(rgb)[..., None]; rgb = np.clip(L0 + (rgb - L0) * SAT, 0, None)
    # target exposure: the light level of the plate around the whole figure (wall behind + floor around the feet).
    # 65th percentile: a person facing the camera gets the bounce of the lit walls/floor, not the darkest corners.
    bx0, bx1 = max(0, ox - nw), min(W, ox + 2 * nw); by0, by1 = max(0, oy), min(H, oy + nh + nh // 8)
    region = lum(plate_lin[by0:by1, bx0:bx1]).ravel()
    target = float(np.percentile(region, 65)) * EXPOSURE
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
        # only near this figure (the ratio map is noisy elsewhere at low spp); feathered box 3 widths x 1.6 heights
        mk = np.zeros((H, W), np.float32)
        mk[max(0, int(oy - nh * 0.3)):min(H, int(fy + nh * 0.6)), max(0, int(fx - nw * 1.5)):min(W, int(fx + nw * 1.5))] = 1
        mk = blur(mk, nw * 0.25)
        out = out * (1 - mk * (1 - shadow_ratio))[..., None]
    # contact occlusion under the soles (always: too small for the ratio map at preview resolution); without a
    # ratio map also a soft cast blob pushed away from the key light. Footprint from the cut-out's own soles (the
    # lowest opaque pixel per column in the bottom band), so a foot set back or a raised heel gets its own contact
    # shadow instead of one ellipse at the bbox bottom (G25: weight on one leg, the other foot behind).
    fl = meta['feet_line']; fw = (fl[1][0] - fl[0][0]) * W
    foot = np.zeros((H, W), np.float32)
    band0 = int(nh * 0.88); solid = a > 0.5
    for x in range(nw):
        col = np.nonzero(solid[band0:, x])[0]
        if col.size == 0: continue
        yb = band0 + col.max(); X, Y = ox + x, oy + yb
        if 0 <= X < W:
            foot[max(0, min(H - 1, Y - 1)):max(0, min(H, Y + 4)), X] = 1.0
    def ablur(arr, rx, ry):   # anisotropic: wide along the floor, flat across it
        arr = arr.astype(np.float32)
        for ax, r in ((1, rx), (0, ry)):
            k = max(1, int(round(r)))
            for _ in range(3): arr = _box(arr, k, ax)
        return arr
    def norm(arr): return arr / max(float(arr.max()), 1e-6)
    tight = norm(ablur(foot, max(2, fw * 0.03), max(1.5, fw * 0.018))) * 0.9
    soft = norm(ablur(foot, max(4, fw * 0.10), max(2, fw * 0.04))) * 0.55
    cast = 0
    if shadow_ratio is None:
        k2 = -d2; sx, sy = int(round(k2[0] * fw * 0.5)), int(round(max(0.02, k2[1]) * fw * 0.15))
        cast = np.roll(np.roll(norm(ablur(foot, max(6, fw * 0.28), max(3, fw * 0.07))), sy, 0), sx, 1) * 0.4
    sh = tight + soft + cast
    if depth is not None:   # the 2D shadow lies on the floor around the feet, never on nearer things (jamb, leaf)
        sh = sh * (depth >= meta['depth_mm'] - 350)
    out = out * (1 - np.clip(sh, 0, 0.85))[..., None]

    # --- light wrap + paste
    X0, Y0, X1, Y1 = max(0, ox), max(0, oy), min(W, ox + nw), min(H, oy + nh)
    sx0, sy0 = X0 - ox, Y0 - oy; sx1, sy1 = sx0 + (X1 - X0), sy0 + (Y1 - Y0)
    fa = a[sy0:sy1, sx0:sx1]; frgb = rgb[sy0:sy1, sx0:sx1]
    if depth is not None:   # hide the figure behind anything nearer than its front (door leaf, jamb, newel)
        near = depth[Y0:Y1, X0:X1] < meta['depth_mm'] - OCCLUDE_MM
        # solid occluders only (door leaf, jamb, newel): thin specks in the depth pass (plant leaves, wreath
        # twigs, sampling noise at edges) would punch sparkling holes into the figure
        near = ndimage.binary_closing(ndimage.binary_opening(near, iterations=3), iterations=2).astype(np.float32)
        fa = fa * (1 - np.clip(blur(near, 0.6), 0, 1))
    bg = out[Y0:Y1, X0:X1]
    rad = max(2.0, nh * 0.012)
    bgb = blur(bg, rad * 2.5)
    inner = np.clip(fa - blur(fa, rad), 0, 1) * 0 + np.clip(1 - blur(fa, rad), 0, 1) * fa       # 1 at the edge, 0 inside
    wrap = WRAP * inner[..., None]
    frgb = frgb * (1 - wrap) + bgb * wrap * 1.1
    fa_soft = np.clip(blur(fa, 0.6), 0, 1)
    if layers is not None:   # --layers-out: plate with this figure's shadow (no figure) + the figure alone, full frame
        layers['plate'] = out.copy()
        fig = np.zeros((H, W, 4), np.float32); fig[Y0:Y1, X0:X1, :3] = frgb; fig[Y0:Y1, X0:X1, 3] = fa_soft
        layers['figure'] = fig
        layers['feet'] = [fx / W, fy / H]; layers['head'] = [fx / W, oy / H]
    out[Y0:Y1, X0:X1] = bg * (1 - fa_soft[..., None]) + frgb * fa_soft[..., None]
    return out

def add_grain(lin, amount, seed=7):
    rng = np.random.default_rng(seed); n = rng.normal(0, 1, lin.shape[:2]).astype(np.float32)
    n = blur(n, 0.5); return lin * (1 + amount * n[..., None])

def contact(seq_dir, out, cols=6, width=1080):
    """Contact sheet of an image sequence (frame numbers burned in, 12 fps timecode)."""
    fs = sorted(f for f in os.listdir(seq_dir) if f.endswith('.png'))
    ims = [Image.open(os.path.join(seq_dir, f)).convert('RGB') for f in fs]
    tw = width // cols; th = int(ims[0].height * tw / ims[0].width); rows = (len(ims) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * tw, rows * th), (20, 20, 20)); d = ImageDraw.Draw(sheet)
    for k, (f, im) in enumerate(zip(fs, ims)):
        x, y = (k % cols) * tw, (k // cols) * th; sheet.paste(im.resize((tw - 2, th - 2), Image.LANCZOS), (x + 1, y + 1))
        d.text((x + 6, y + 4), f.split('.')[0].replace('f_', '#'), fill=(235, 225, 200))
    sheet.save(out); print('WROTE', out, len(ims), 'frames')

def reproject(meta, slot, x, y, height_mm=None):
    """Move a figure slot to world floor point (x, y) mm with the plate's camera (arrival_scene.py: Blender camera,
    vertical sensor fit, X 90 deg + yaw, shift); rewrites feet_center, feet_line, head_top, height_px, px_per_mm,
    depth_mm in the slot (for a slot whose scene position is wrong, e.g. Teresa in front of the ajar leaf)."""
    c = meta['camera']; W, H = meta['width'], meta['height']; s = meta['figures'][slot]
    C = np.array(c['location_mm'], float); yaw = math.radians(c['rotation_euler_deg'][2]); f = c['lens_mm']; sh = c['shift'][1]
    sw = c.get('sensor_height_mm', 36.0)
    fwd = np.array([-math.sin(yaw), math.cos(yaw), 0.0]); right = np.array([math.cos(yaw), math.sin(yaw), 0.0])
    def proj(P):
        v = np.array(P, float) - C; z = v @ fwd
        return 0.5 + (v @ right) / z * f / (sw * W / H), 0.5 - ((v[2]) / z * f / sw - sh), z
    hm = height_mm or s['height_mm']
    u, v, z = proj((x, y, 0)); _, vt, _ = proj((x, y, hm))
    ul, _, _ = proj((x - 225, y, 0)); ur, _, _ = proj((x + 225, y, 0))
    s.update(feet_world_mm=[x, y, 0.0], height_mm=hm, feet_center=[u, v], feet_line=[[ul, v], [ur, v]], head_top=[u, vt],
             height_px=(v - vt) * H, px_per_mm=(v - vt) * H / hm, depth_mm=z)
    print('SLOT', slot, 'feet', [round(u, 4), round(v, 4)], 'height_px', round((v - vt) * H, 1), 'depth', round(z))


def main():
    global EXPOSURE, WRAP, WARM, SAT, OCCLUDE_MM, TINT_GAIN
    ap = argparse.ArgumentParser()
    ap.add_argument('--plate'); ap.add_argument('--anchors'); ap.add_argument('--figure', action='append', default=[])
    ap.add_argument('--shadow'); ap.add_argument('--out', required=True); ap.add_argument('--placeholder')
    ap.add_argument('--grain', type=float, default=0.025); ap.add_argument('--exposure', type=float, default=1.0); ap.add_argument('--no-depth', action='store_true'); ap.add_argument('--breath', type=int, default=0)
    ap.add_argument('--wrap', type=float, default=WRAP); ap.add_argument('--warm', type=float, default=WARM); ap.add_argument('--sat', type=float, default=SAT); ap.add_argument('--occlude-mm', type=float, default=OCCLUDE_MM); ap.add_argument('--tint-gain', type=float, default=TINT_GAIN)
    ap.add_argument('--feet-world', action='append', default=[],
                    help='SLOT=x,y[,height_mm]: move a slot on the floor (world mm) and re-project it with the plate camera')
    ap.add_argument('--contact', help='sequence dir: write a contact sheet to --out and exit')
    ap.add_argument('--layers-out', help='PREFIX: also write PREFIX_plate.png (plate + shadow, no figure) and '
                    'PREFIX_figure.png (the figure alone, full-frame RGBA) + PREFIX.json (feet/head, 0..1) for the game')
    o = ap.parse_args()
    if o.contact:
        contact(o.contact, o.out); return
    EXPOSURE, WRAP, WARM, SAT, OCCLUDE_MM, TINT_GAIN = o.exposure, o.wrap, o.warm, o.sat, o.occlude_mm, o.tint_gain
    if o.placeholder:
        print('WROTE', placeholder(o.placeholder, o.out)); return
    meta = json.load(open(o.anchors or os.path.splitext(o.plate)[0] + '.json'))
    plate = np.asarray(Image.open(o.plate).convert('RGB')).astype(np.float32) / 255.0
    plate_lin = srgb_to_lin(plate)
    H, W = plate.shape[:2]
    for fw in o.feet_world:
        slot, v = fw.split('=', 1); xyz = [float(t) for t in v.split(',')]
        reproject(meta, slot, xyz[0], xyz[1], xyz[2] if len(xyz) > 2 else None)
    for f in meta['figures'].values():   # anchors are normalised; the JSON's height_px is for its own width/height
        f['height_px'] = f['height_px'] * H / meta['height']
    shadow = None
    if o.shadow:
        s = Image.open(o.shadow); s = s.convert('RGBA') if s.mode != 'I;16' else s
        arr = np.asarray(s).astype(np.float32); arr = arr[..., :3].mean(-1) / 255.0 if arr.ndim == 3 else arr / 65535.0
        if arr.shape != (H, W): arr = np.asarray(Image.fromarray(arr, 'F').resize((W, H), Image.BILINEAR))
        shadow = np.clip(blur(arr, 1.0), 0, 1)
    depth = None
    dp = meta.get('depth_png')
    if dp and not o.no_depth:
        p = os.path.join(os.path.dirname(os.path.abspath(o.plate)), dp['file'])
        if os.path.exists(p):
            d = np.asarray(Image.open(p)).astype(np.float32)
            d = (d[..., 0] if d.ndim == 3 else d) / (65535.0 if d.max() > 255 else 255.0) * dp['depth_max_mm']
            if d.shape != (H, W): d = np.asarray(Image.fromarray(d, 'F').resize((W, H), Image.NEAREST))
            depth = d
    figs = [f.split('=', 1) for f in o.figure]
    frames = max(1, o.breath)
    for i in range(frames):
        out = plate_lin
        lay = {} if (o.layers_out and i == 0) else None
        for slot, path in figs:
            out = place_figure(out, slot, path, meta['figures'][slot], shadow, phase=i / frames, breath=1.0 if o.breath else 0.0, depth=depth, layers=lay)
        if lay:
            # same grain field as the composite, so plate + figure layer stack to the composite (up to edge blending)
            rng = np.random.default_rng(7 + i); n = blur(rng.normal(0, 1, (H, W)).astype(np.float32), 0.5)[..., None]
            pl = lay['plate'] * (1 + o.grain * n); fg = lay['figure'].copy(); fg[..., :3] = fg[..., :3] * (1 + o.grain * n)
            Image.fromarray((np.clip(lin_to_srgb(pl), 0, 1) * 255 + 0.5).astype(np.uint8)).save(o.layers_out + '_plate.png')
            rgba = np.dstack([np.clip(lin_to_srgb(fg[..., :3]), 0, 1), np.clip(fg[..., 3:], 0, 1)])
            Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), 'RGBA').save(o.layers_out + '_figure.png')
            json.dump({'feet': lay['feet'], 'head': lay['head'], 'width': W, 'height': H}, open(o.layers_out + '.json', 'w'))
            print('WROTE', o.layers_out + '_{plate,figure}.png')
        out = add_grain(out, o.grain, seed=7 + i)
        img = Image.fromarray((np.clip(lin_to_srgb(out), 0, 1) * 255 + 0.5).astype(np.uint8))
        p = o.out if frames == 1 else o.out.replace('.png', '_%02d.png' % i)
        img.save(p); print('WROTE', p)

if __name__ == '__main__':
    main()
