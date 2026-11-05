#!/usr/bin/env python3
"""Build game-ready photo materials from the selected Magnific / Nano Banana photos.

Inputs : contrib/incoming/magnific/selected/*.jpg, contrib/incoming/leather_set_2026-11-05/*.jpg
Outputs: art/textures/photo/<name>/  (tileable / strip / radial surfaces)
         art/textures/photo/objects/ (cut-out props with alpha)
         art/textures/photo/contact_previews.jpg, contact_objects.jpg

Pipeline for a tileable surface:
  1. flatten low-frequency lighting: divide RGB by blurred luminance (sigma ~ 1/7 image), colour kept
  2. seamless: per axis, pick the overlap that best matches the opposite edge, then join the
     overlap along a minimum-error boundary cut (image quilting) with a short feather; resize to 2048
  3. height = luminance high-pass (wrap-around filters), normal from height (OpenGL, +Y up),
     roughness = inverted local contrast (+ a little inverted luminance), mapped to a per-material range,
     metals clamped >= 0.16 (docs/styles/realizm.md)
  4. 1024 mobile copies (suffix _1k); height is stored only as 16-bit 1024 (saves repo space)
  5. 2x2 preview (albedo | shaded height) for seam checks

Usage: nice -n 10 python3 tools/make_photo_materials.py [names...]
Requires: numpy, Pillow, opencv-python-headless.
"""
import json
import os
import sys

import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_M = os.path.join(ROOT, "contrib/incoming/magnific/selected")
SRC_L = os.path.join(ROOT, "contrib/incoming/leather_set_2026-11-05")
OUT = os.path.join(ROOT, "art/textures/photo")
SIZE = 2048

# mode: tile (both axes), strip (horizontal only), radial (no tiling, centred)
# flat: lighting flatten ("full", "x" = only horizontal fall-off, "none")
# rough: (min, max); metal: clamp >= 0.16; hs: height high-pass sigma px; ns: normal strength
SURFACES = {
    "leather_brown_new":     dict(src=SRC_M, mode="tile", flat="full", rough=(0.48, 0.78), metal=False, hs=18, ns=4.0, keystone=True),
    "leather_brown_worn":    dict(src=SRC_M, mode="tile", flat="full", rough=(0.42, 0.82), metal=False, hs=22, ns=4.0),
    "leather_chocolate":     dict(src=SRC_L, mode="tile", flat="full", rough=(0.40, 0.76), metal=False, hs=18, ns=4.0),
    "leather_stitching_strip": dict(src=SRC_M, mode="strip", flat="x", rough=(0.45, 0.80), metal=False, hs=24, ns=5.0),
    "brass_turned":          dict(src=SRC_M, mode="radial", flat="none", rough=(0.18, 0.34), metal=True, hs=6, ns=2.0),
    "brass_face_milled":     dict(src=SRC_M, mode="tile", flat="full", rough=(0.22, 0.42), metal=True, hs=20, ns=3.0),
    "brass_patina_grease":   dict(src=SRC_M, mode="tile", flat="full", rough=(0.30, 0.82), metal=True, hs=16, ns=3.0),
    "steel_ground":          dict(src=SRC_M, mode="tile", flat="full", rough=(0.20, 0.38), metal=True, hs=6, ns=1.5),
    "steel_heat_tint":       dict(src=SRC_M, mode="strip", flat="x", rough=(0.18, 0.34), metal=True, hs=6, ns=1.2),
    "spring_steel_polished": dict(src=SRC_M, mode="tile", flat="full", rough=(0.16, 0.28), metal=True, hs=6, ns=1.2),
    "nickel_satin":          dict(src=SRC_M, mode="tile", flat="full", rough=(0.22, 0.40), metal=True, hs=8, ns=1.5),
    "iron_painted_rust":     dict(src=SRC_M, mode="tile", flat="full", rough=(0.35, 0.92), metal=True, hs=20, ns=4.0),
    "terrazzo_grey_red":     dict(src=SRC_M, mode="tile", flat="full", rough=(0.32, 0.62), metal=False, hs=12, ns=2.0),
    "cement_tiles":          dict(src=SRC_M, mode="tile", flat="full", rough=(0.40, 0.70), metal=False, hs=10, ns=2.0),
    "pine_floor_painted":    dict(src=SRC_M, mode="tile", flat="full", rough=(0.45, 0.82), metal=False, hs=24, ns=4.0, deskew=True),
    "workshop_concrete":     dict(src=SRC_M, mode="tile", flat="full", rough=(0.62, 0.95), metal=False, hs=24, ns=3.0),
}

# Objects: GrabCut initialised with a rect (fractions x0, y0, x1, y1 of the photo).
# kind: grabcut | ink (alpha from ink darkness) | decal (soft radial alpha, centred circle cx, cy, r)
OBJECTS = {
    "coconut_doormat":   dict(src=SRC_M, kind="grabcut", rect=(0.08, 0.18, 0.93, 0.84)),
    "envelope_back":     dict(src=SRC_M, kind="grabcut", rect=(0.06, 0.16, 0.94, 0.84)),
    "envelope_front":    dict(src=SRC_M, kind="grabcut", rect=(0.10, 0.18, 0.92, 0.82)),
    "icon_doorbell":     dict(src=SRC_M, kind="grabcut", rect=(0.10, 0.10, 0.88, 0.94)),
    "icon_enamel_L":     dict(src=SRC_M, kind="grabcut", rect=(0.13, 0.10, 0.87, 0.87)),
    "icon_number_plate_7": dict(src=SRC_M, kind="grabcut", rect=(0.20, 0.16, 0.80, 0.87)),
    "leather_brass_snap": dict(src=SRC_M, kind="circle", rect=(0.18, 0.16, 0.82, 0.82)),
    "paper_card_stock":  dict(src=SRC_M, kind="grabcut", rect=(0.20, 0.06, 0.80, 0.96)),
    "paper_note_torn":   dict(src=SRC_M, kind="grabcut", rect=(0.18, 0.06, 0.82, 0.94)),
    "paper_office_folded": dict(src=SRC_M, kind="grabcut", rect=(0.04, 0.06, 0.96, 0.96)),
    "paper_receipt_pad": dict(src=SRC_M, kind="grabcut", rect=(0.16, 0.06, 0.84, 0.96)),
    "tool_roll_open_empty": dict(src=SRC_M, kind="grabcut", rect=(0.04, 0.20, 0.96, 0.84)),
    "tool_roll_pocket_empty_closeup": dict(src=SRC_M, kind="grabcut", rect=(0.24, 0.03, 0.84, 0.99)),
    "ink_oval_blank":    dict(src=SRC_M, kind="ink", rect=(0.12, 0.25, 0.92, 0.85)),
    "thumb_dent":        dict(src=SRC_L, kind="decal", circle=(0.50, 0.47, 0.34)),
}


# ---------------------------------------------------------------- helpers
def load(path):
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.float32) / 255.0


def to_srgb8(a):
    return (np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)


def lum(a):
    return a[..., 0] * 0.2126 + a[..., 1] * 0.7152 + a[..., 2] * 0.0722


def blur_wrap(a, sigma):
    """Gaussian blur with wrap-around borders (keeps tileable maps tileable)."""
    p = int(min(3 * sigma + 1, min(a.shape[:2]) - 1))
    pad = ((p, p), (p, p)) + ((0, 0),) * (a.ndim - 2)
    b = cv2.GaussianBlur(np.pad(a, pad, mode="wrap"), (0, 0), sigma)
    return b[p:-p, p:-p]


def blur_reflect(a, sigma):
    return cv2.GaussianBlur(a, (0, 0), sigma, borderType=cv2.BORDER_REFLECT)


def flatten(img, how):
    """Remove the lighting gradient.

    a) per channel, fit a 2nd-order polynomial to log(colour) and divide it out: removes broad
       brightness *and* tint fall-off (the AI photos often get warmer/darker towards one edge)
       without eating content blotches;
    b) then divide by a large-radius blurred luminance (sigma = 1/6 image) for the residual
       non-polynomial vignetting, gain clipped to +-33 %.
    """
    if how == "none":
        return img
    H, W = img.shape[:2]
    n = 64
    small = cv2.resize(img, (n, n), interpolation=cv2.INTER_AREA)
    yy, xx = np.mgrid[0:n, 0:n] / (n - 1.0) - 0.5
    if how == "x":  # only left-right fall-off (keeps vertical content such as heat tint bands)
        basis = [np.ones_like(xx), xx, xx * xx]
    else:
        basis = [np.ones_like(xx), xx, yy, xx * xx, yy * yy, xx * yy]
    A = np.stack([b.ravel() for b in basis], axis=1)
    Y, X = np.mgrid[0:H, 0:W]
    Xf, Yf = X / (W - 1.0) - 0.5, Y / (H - 1.0) - 0.5
    full = [np.ones_like(Xf), Xf, Xf * Xf] if how == "x" else \
        [np.ones_like(Xf), Xf, Yf, Xf * Xf, Yf * Yf, Xf * Yf]
    out = np.empty_like(img)
    for c in range(3):
        lg = np.log(np.maximum(small[..., c], 1e-3)).ravel()
        coef, *_ = np.linalg.lstsq(A, lg, rcond=None)
        trend = sum(k * b for k, b in zip(coef[1:], full[1:]))  # drop the constant: keep mean colour
        out[..., c] = img[..., c] * np.exp(-trend)
    img = np.clip(out, 0, 1)
    L = lum(img)
    s = 256
    t = blur_reflect(cv2.resize(L, (s, s), interpolation=cv2.INTER_AREA), s / 6.0)
    if how == "x":
        t = np.repeat(t.mean(axis=0, keepdims=True), s, axis=0)
    t = cv2.resize(t, (W, H), interpolation=cv2.INTER_CUBIC)
    gain = np.clip(L.mean() / np.maximum(t, 1e-3), 0.75, 1.33)
    return np.clip(img * gain[..., None], 0, 1)


def grain_frequency_profile(img, bands=8):
    """Mean spatial frequency of fine detail in horizontal bands (perspective / scale drift probe)."""
    a = lum(img)
    H, W = a.shape
    ys, fs = [], []
    for y in range(0, H - 255, H // bands):
        b = a[y:y + 256, W // 2 - 512:W // 2 + 512]
        b = b - cv2.GaussianBlur(b, (0, 0), 20)
        F = np.abs(np.fft.rfft2(b)) ** 2
        r = np.sqrt(np.fft.fftfreq(256)[:, None] ** 2 + np.fft.rfftfreq(1024)[None, :] ** 2)
        m = r > 0.004
        ys.append(y + 128)
        fs.append(float((F * r)[m].sum() / F[m].sum()))
    return np.array(ys), np.array(fs)


def keystone_fix(img):
    """Undo a vertical grain-scale drift (camera tilt): the finer end is magnified so the grain has
    one size everywhere; otherwise the top/bottom seam joins two grain sizes."""
    H, W = img.shape[:2]
    ys, fs = grain_frequency_profile(img)
    k, c = np.polyfit(ys, fs, 1)
    y = np.arange(H, dtype=np.float64)
    f = np.maximum(k * y + c, 1e-4)
    fref = f.min()
    dv = f / fref  # output rows per source row
    v = np.concatenate([[0], np.cumsum(dv)[:-1]])
    Hout = int(v[-1])
    vo = np.arange(Hout, dtype=np.float64)
    ysrc = np.interp(vo, v, y)
    sx = fref / np.interp(ysrc, y, f)  # source px per output px horizontally
    cx = (W - 1) / 2.0
    u = np.arange(W, dtype=np.float64)
    mapx = (cx + (u[None, :] - cx) * sx[:, None]).astype(np.float32)
    mapy = np.repeat(ysrc[:, None], W, axis=1).astype(np.float32)
    out = cv2.remap(img, mapx, mapy, cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_REFLECT)
    y0 = (Hout - W) // 2 if Hout > W else 0
    return out[y0:y0 + W], dict(keystone_freq_ratio=round(float(f.max() / f.min()), 3))


def deskew_vertical(img, max_deg=3.0):
    """Rotate so that long vertical structures (plank gaps) are exactly vertical; then the top/bottom
    seam joins gaps that line up. Angle = argmax of the variance of the column-mean profile."""
    H, W = img.shape[:2]
    g = cv2.resize(lum(img), (W // 2, H // 2), interpolation=cv2.INTER_AREA)
    h, w = g.shape
    best, ba = -1, 0.0
    for a in np.arange(-max_deg, max_deg + 1e-6, 0.1):
        M = cv2.getRotationMatrix2D((w / 2, h / 2), a, 1.0)
        r = cv2.warpAffine(g, M, (w, h), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT)
        c = r[h // 8:-h // 8, w // 8:-w // 8].mean(axis=0)
        v = float(np.var(c - cv2.GaussianBlur(c[None, :], (0, 0), 20)[0]))
        if v > best:
            best, ba = v, float(a)
    t = np.radians(abs(ba))
    s = 1.0 / (np.cos(t) + np.sin(t))  # largest centred square fully inside the rotated image
    M = cv2.getRotationMatrix2D((W / 2, H / 2), ba, 1.0 / s)
    out = cv2.warpAffine(img, M, (W, H), flags=cv2.INTER_LANCZOS4, borderMode=cv2.BORDER_REFLECT)
    return np.clip(out, 0, 1), dict(deskew_deg=round(ba, 2))


def equalize_detail(img, fine=6.0, wide=96.0):
    """Even out fine-detail contrast across the photo (AI photos are often sharper/coarser on one
    side); otherwise the seam joins two visibly different grain contrasts."""
    base = blur_reflect(img, fine)
    det = img - base
    dl = lum(det)
    amp = np.sqrt(blur_reflect(dl * dl, wide)) + 1e-4
    f = np.clip(np.median(amp) / amp, 0.6, 1.7)
    return np.clip(base + det * f[..., None], 0, 1)


def min_cut_path(err):
    """Vertical path of minimum cumulative error through err (H x W)."""
    H, W = err.shape
    E = err.copy()
    back = np.zeros((H, W), np.int8)
    for y in range(1, H):
        prev = E[y - 1]
        left = np.r_[np.inf, prev[:-1]]
        right = np.r_[prev[1:], np.inf]
        stack = np.stack([left, prev, right])
        idx = stack.argmin(axis=0)
        E[y] += stack[idx, np.arange(W)]
        back[y] = idx - 1
    path = np.zeros(H, np.int32)
    path[-1] = int(E[-1].argmin())
    for y in range(H - 1, 0, -1):
        path[y - 1] = np.clip(path[y] + back[y, path[y]], 0, W - 1)
    return path


def seam_x(img, omin, omax, feather=3):
    """Make img horizontally tileable. Returns (H, W - o) image."""
    H, W, _ = img.shape
    best, best_o = None, omin
    g = cv2.resize(img, (W // 4, H // 4), interpolation=cv2.INTER_AREA)
    for o in range(omin, omax + 1, 4):
        q = o // 4
        e = float(((g[:, :q] - g[:, W // 4 - q:]) ** 2).mean())
        if best is None or e < best:
            best, best_o = e, o
    o = best_o
    L = img[:, :o]
    R = img[:, W - o:]
    err = ((L - R) ** 2).sum(axis=2)
    err = cv2.GaussianBlur(err, (0, 0), 1.5)
    m = 2 * feather + 2  # keep the cut away from the overlap borders
    err[:, :m] = 1e3
    err[:, o - m:] = 1e3
    path = min_cut_path(err)
    xs = np.arange(o)[None, :]
    mask = (xs >= path[:, None]).astype(np.float32)  # 1 -> left (L), 0 -> right (R)
    if feather > 0:
        mask = cv2.GaussianBlur(mask, (0, 0), feather)
        mask[:, :2] = 0
        mask[:, -2:] = 1
    comp = R * (1 - mask[..., None]) + L * mask[..., None]
    out = img[:, :W - o].copy()
    out[:, :o] = comp
    return out, o


def make_tileable(img, axes="xy"):
    W = img.shape[1]
    omin, omax = int(W * 0.07), int(W * 0.17)
    info = {}
    if "x" in axes:
        img, info["overlap_x"] = seam_x(img, omin, omax)
    if "y" in axes:
        t, info["overlap_y"] = seam_x(np.ascontiguousarray(img.transpose(1, 0, 2)), omin, omax)
        img = np.ascontiguousarray(t.transpose(1, 0, 2))
    return img, info


def resize(a, size, interp=cv2.INTER_LANCZOS4):
    return cv2.resize(a, (size, size), interpolation=interp)


def resize_wrap(a, size):
    """Resize a tileable map without introducing edge artefacts (pad wrap, resize, crop)."""
    h = a.shape[0]
    p = 16
    pad = ((p, p), (p, p)) + ((0, 0),) * (a.ndim - 2)
    big = np.pad(a, pad, mode="wrap")
    s = size / h
    n = int(round((h + 2 * p) * s))
    r = cv2.resize(big, (n, n), interpolation=cv2.INTER_LANCZOS4)
    q = int(round(p * s))
    return r[q:q + size, q:q + size]


def height_map(albedo, sigma, wrap):
    L = lum(albedo)
    bl = blur_wrap if wrap else blur_reflect
    hp = L - bl(L, sigma)
    hp = bl(hp, 1.0)
    lo, hi = np.percentile(hp, [1, 99])
    s = max(abs(lo), abs(hi), 1e-4)
    return np.clip(0.5 + 0.5 * hp / s, 0, 1)


def normal_map(h, strength, wrap):
    if wrap:
        hp = np.pad(h, 1, mode="wrap")
    else:
        hp = np.pad(h, 1, mode="reflect")
    dx = (hp[1:-1, 2:] - hp[1:-1, :-2]) * 0.5
    dy = (hp[2:, 1:-1] - hp[:-2, 1:-1]) * 0.5
    k = strength * h.shape[0] / 512.0
    nx, ny, nz = -dx * k, dy * k, np.ones_like(h)  # OpenGL: +Y (green) points up the image
    n = np.stack([nx, ny, nz], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def rough_map(albedo, rng, metal, wrap):
    L = lum(albedo)
    bl = blur_wrap if wrap else blur_reflect
    m = bl(L, 6)
    lc = np.sqrt(np.maximum(bl(L * L, 6) - m * m, 0))
    lc = bl(lc, 2)

    def norm(x):
        lo, hi = np.percentile(x, [2, 98])
        return np.clip((x - lo) / max(hi - lo, 1e-5), 0, 1)

    t = 0.7 * (1 - norm(lc)) + 0.3 * (1 - norm(bl(L, 3)))
    r = rng[0] + (rng[1] - rng[0]) * t
    if metal:
        r = np.maximum(r, 0.16)
    return np.clip(r, 0, 1)


def shade(h, n):
    light = np.array([-0.45, 0.55, 0.70])
    light /= np.linalg.norm(light)
    v = (n * 2 - 1) @ light
    return np.clip(0.15 + 0.85 * v, 0, 1)


def save_jpg(path, a, q=92):
    Image.fromarray(to_srgb8(a)).save(path, quality=q, subsampling=0, optimize=True)


def save_png8(path, a):
    Image.fromarray(to_srgb8(a)).save(path, optimize=True)


def save_normal(path, n, cap=9.8e6):
    """8-bit PNG normal; if it would exceed the 10 MB repo cap, soften it slightly until it fits."""
    sig = 0.0
    while True:
        m = cv2.GaussianBlur(n, (0, 0), sig) if sig else n
        m = m * 2 - 1
        m /= np.linalg.norm(m, axis=-1, keepdims=True)
        rgb = to_srgb8(m * 0.5 + 0.5)
        ok, buf = cv2.imencode(".png", rgb[..., ::-1], [cv2.IMWRITE_PNG_COMPRESSION, 9])
        if len(buf) <= cap or sig >= 2.0:
            with open(path, "wb") as f:
                f.write(buf.tobytes())
            return sig
        sig += 0.3


def save_png16(path, h):
    cv2.imwrite(path, (np.clip(h, 0, 1) * 65535 + 0.5).astype(np.uint16))


def preview(name, albedo, nrm, mode):
    t = 512
    a = resize(albedo, t, cv2.INTER_AREA)
    s = resize(shade(None, nrm), t, cv2.INTER_AREA)
    s = np.repeat(s[..., None], 3, axis=2)
    if mode == "radial":
        tile_a, tile_s = a, s
    elif mode == "strip":
        tile_a, tile_s = np.tile(a, (1, 2, 1)), np.tile(s, (1, 2, 1))
    else:
        tile_a, tile_s = np.tile(a, (2, 2, 1)), np.tile(s, (2, 2, 1))
    pv = np.concatenate([tile_a, np.ones((tile_a.shape[0], 8, 3)), tile_s], axis=1)
    p = os.path.join(OUT, name, f"{name}_preview_2x2.jpg")
    save_jpg(p, pv, 85)
    return p


# ---------------------------------------------------------------- surfaces
def build_surface(name, cfg):
    src = os.path.join(cfg["src"], name + ".jpg")
    img = load(src)
    d = os.path.join(OUT, name)
    os.makedirs(d, exist_ok=True)
    img = flatten(img, cfg["flat"])
    mode = cfg["mode"]
    info = {}
    if cfg.get("deskew"):
        img, di = deskew_vertical(img)
        info.update(di)
    if cfg.get("keystone"):
        img, ki = keystone_fix(img)
        info.update(ki)
    if mode in ("tile", "strip") and cfg.get("eq", True):
        img = equalize_detail(img)
    if mode == "tile":
        img, ti = make_tileable(img, "xy")
        info.update(ti)
        albedo = resize_wrap(img, SIZE) if img.shape[0] == img.shape[1] else None
        if albedo is None:
            albedo = cv2.resize(img, (SIZE, SIZE), interpolation=cv2.INTER_LANCZOS4)
            # one more light cut-free wrap smoothing is not needed: both edges already continue
    elif mode == "strip":
        img, ti = make_tileable(img, "x")
        info.update(ti)
        h, w = img.shape[:2]
        y0 = (h - w) // 2
        img = img[y0:y0 + w]
        albedo = cv2.resize(img, (SIZE, SIZE), interpolation=cv2.INTER_LANCZOS4)
    else:  # radial: centre on the brightest radial symmetry point (image centre for this photo)
        h, w = img.shape[:2]
        s = min(h, w)
        albedo = cv2.resize(img[(h - s) // 2:(h + s) // 2, (w - s) // 2:(w + s) // 2], (SIZE, SIZE),
                            interpolation=cv2.INTER_LANCZOS4)
    albedo = np.clip(albedo, 0, 1)
    wrap = mode == "tile"
    # strips wrap horizontally only; vertical edges are free, so reflect is the safer choice there
    if mode == "strip":
        hgt = height_map_strip(albedo, cfg["hs"])
        nrm = normal_strip(hgt, cfg["ns"])
        rgh = rough_strip(albedo, cfg["rough"], cfg["metal"])
    else:
        hgt = height_map(albedo, cfg["hs"], wrap)
        nrm = normal_map(hgt, cfg["ns"], wrap)
        rgh = rough_map(albedo, cfg["rough"], cfg["metal"], wrap)

    save_jpg(os.path.join(d, f"{name}_albedo.jpg"), albedo)
    info["normal_2k_soften_sigma"] = save_normal(os.path.join(d, f"{name}_normal.png"), nrm)
    save_png8(os.path.join(d, f"{name}_rough.png"), rgh)
    save_png16(os.path.join(d, f"{name}_height_1k.png"),
               (resize_wrap(hgt, 1024) if wrap else resize(hgt, 1024, cv2.INTER_AREA)))
    rs = (lambda a: resize_wrap(a, 1024)) if wrap else (lambda a: resize(a, 1024, cv2.INTER_AREA))
    save_jpg(os.path.join(d, f"{name}_albedo_1k.jpg"), rs(albedo))
    n1 = rs(nrm) * 2 - 1
    n1 /= np.linalg.norm(n1, axis=-1, keepdims=True)
    save_normal(os.path.join(d, f"{name}_normal_1k.png"), n1 * 0.5 + 0.5)
    save_png8(os.path.join(d, f"{name}_rough_1k.png"), rs(rgh))
    meta = dict(name=name, source=os.path.relpath(src, ROOT), mode=mode,
                tiling={"tile": "u+v", "strip": "u only", "radial": "none (centred)"}[mode],
                metallic=1.0 if cfg["metal"] and name != "iron_painted_rust" else 0.0,
                roughness_range=list(cfg["rough"]), normal="OpenGL (+Y up)",
                normal_strength=cfg["ns"], height_highpass_sigma_px=cfg["hs"],
                lighting_flatten=cfg["flat"], **info,
                rough_mean=round(float(rgh.mean()), 3))
    if name == "iron_painted_rust":
        meta["metallic_note"] = "painted iron: treat as dielectric; rust/bare spots could use a mask later"
    with open(os.path.join(d, "material.json"), "w") as f:
        json.dump(meta, f, indent=2)
    return preview(name, albedo, nrm, mode)


def _blur_xwrap(a, sigma):
    p = int(3 * sigma + 1)
    b = np.pad(a, ((p, p), (p, p)), mode="wrap")  # wrap in x; y edges are rarely sampled across
    b[:p] = b[p:2 * p][::-1]
    b[-p:] = b[-2 * p:-p][::-1]
    return cv2.GaussianBlur(b, (0, 0), sigma)[p:-p, p:-p]


def height_map_strip(albedo, sigma):
    L = lum(albedo)
    hp = L - _blur_xwrap(L, sigma)
    hp = _blur_xwrap(hp, 1.0)
    lo, hi = np.percentile(hp, [1, 99])
    s = max(abs(lo), abs(hi), 1e-4)
    return np.clip(0.5 + 0.5 * hp / s, 0, 1)


def normal_strip(h, strength):
    hp = np.pad(h, ((0, 0), (1, 1)), mode="wrap")
    hp = np.pad(hp, ((1, 1), (0, 0)), mode="reflect")
    dx = (hp[1:-1, 2:] - hp[1:-1, :-2]) * 0.5
    dy = (hp[2:, 1:-1] - hp[:-2, 1:-1]) * 0.5
    k = strength * h.shape[0] / 512.0
    n = np.stack([-dx * k, dy * k, np.ones_like(h)], axis=-1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def rough_strip(albedo, rng, metal):
    L = lum(albedo)
    m = _blur_xwrap(L, 6)
    lc = np.sqrt(np.maximum(_blur_xwrap(L * L, 6) - m * m, 0))

    def norm(x):
        lo, hi = np.percentile(x, [2, 98])
        return np.clip((x - lo) / max(hi - lo, 1e-5), 0, 1)

    t = 0.7 * (1 - norm(lc)) + 0.3 * (1 - norm(_blur_xwrap(L, 3)))
    r = rng[0] + (rng[1] - rng[0]) * t
    return np.clip(np.maximum(r, 0.16) if metal else r, 0, 1)


# ---------------------------------------------------------------- objects
def grabcut_mask(rgb8, rect_frac, work=768):
    H, W = rgb8.shape[:2]
    s = work / max(H, W)
    small = cv2.resize(rgb8, (int(W * s), int(H * s)), interpolation=cv2.INTER_AREA)
    h, w = small.shape[:2]
    x0, y0, x1, y1 = rect_frac
    rect = (int(x0 * w), int(y0 * h), int((x1 - x0) * w), int((y1 - y0) * h))
    mask = np.zeros((h, w), np.uint8)
    bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
    cv2.grabCut(cv2.cvtColor(small, cv2.COLOR_RGB2BGR), mask, rect, bgd, fgd, 6, cv2.GC_INIT_WITH_RECT)
    fg = np.where((mask == 1) | (mask == 3), 1.0, 0.0).astype(np.float32)
    # keep the largest component, fill holes
    n, lab, stats, _ = cv2.connectedComponentsWithStats((fg > 0.5).astype(np.uint8))
    if n > 1:
        k = 1 + int(stats[1:, cv2.CC_STAT_AREA].argmax())
        fg = (lab == k).astype(np.float32)
    inv = (fg < 0.5).astype(np.uint8)
    n, lab, stats, _ = cv2.connectedComponentsWithStats(inv)
    for i in range(1, n):
        x, y, ww, hh, a = stats[i]
        if x > 0 and y > 0 and x + ww < w and y + hh < h:
            fg[lab == i] = 1.0
    fg = cv2.morphologyEx(fg, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    big = cv2.resize(fg, (W, H), interpolation=cv2.INTER_LINEAR)
    big = cv2.GaussianBlur(big, (0, 0), 1.2 / s * 0.6)
    a = np.clip((big - 0.5) * 2.2 + 0.5, 0, 1)
    return a


def circle_mask(rgb8, rect_frac):
    H, W = rgb8.shape[:2]
    g = cv2.cvtColor(rgb8, cv2.COLOR_RGB2GRAY)
    g = cv2.medianBlur(cv2.resize(g, (W // 4, H // 4), interpolation=cv2.INTER_AREA), 5)
    cs = cv2.HoughCircles(g, cv2.HOUGH_GRADIENT, dp=1.2, minDist=200, param1=120, param2=40,
                          minRadius=int(W / 4 * 0.18), maxRadius=int(W / 4 * 0.40))
    if cs is None:
        return grabcut_mask(rgb8, rect_frac)
    cx, cy, r = (cs[0][0] * 4).tolist()
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    return np.clip((r + 2 - d) / 4.0, 0, 1).astype(np.float32)


def ink_alpha(rgb, rect):
    H, W = rgb.shape[:2]
    paper = np.percentile(rgb.reshape(-1, 3), 70, axis=0)
    dark = np.clip((paper - rgb).max(axis=2) / 0.45, 0, 1)
    blue = np.clip((rgb[..., 2] - rgb[..., 0]) / 0.25, 0, 1)  # blue ink, not paper shadow / wood
    a = np.clip((dark - 0.06) / 0.6, 0, 1) ** 0.9 * np.clip(blue * 1.5, 0, 1)
    x0, y0, x1, y1 = rect
    box = np.zeros((H, W), np.float32)
    box[int(y0 * H):int(y1 * H), int(x0 * W):int(x1 * W)] = 1
    a = a * cv2.GaussianBlur(box, (0, 0), 20)
    ink = np.array([0.08, 0.12, 0.42])
    col = np.broadcast_to(ink, rgb.shape).copy()
    # keep the photographed ink colour where it is solid, flat ink colour where faint
    col = col * (1 - a[..., None]) + rgb * a[..., None]
    return col, a


def decal(rgb, circle):
    H, W = rgb.shape[:2]
    cx, cy, r = circle[0] * W, circle[1] * H, circle[2] * W
    x0, y0 = int(max(cx - r, 0)), int(max(cy - r, 0))
    x1, y1 = int(min(cx + r, W)), int(min(cy + r, H))
    crop = rgb[y0:y1, x0:x1]
    h, w = crop.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt((xx - (cx - x0)) ** 2 + (yy - (cy - y0)) ** 2) / r
    a = np.clip((1.0 - d) / 0.35, 0, 1) ** 1.5
    return crop, a.astype(np.float32)


def build_object(name, cfg):
    src = os.path.join(cfg["src"], name + ".jpg")
    rgb8 = np.asarray(Image.open(src).convert("RGB"))
    rgb = rgb8.astype(np.float32) / 255.0
    d = os.path.join(OUT, "objects")
    os.makedirs(d, exist_ok=True)
    extra = {}
    if cfg["kind"] == "grabcut":
        a = grabcut_mask(rgb8, cfg["rect"])
        col = rgb
    elif cfg["kind"] == "circle":
        a = circle_mask(rgb8, cfg["rect"])
        col = rgb
    elif cfg["kind"] == "ink":
        col, a = ink_alpha(rgb, cfg["rect"])
    else:
        col, a = decal(rgb, cfg["circle"])
        hgt = height_map(col, 40, False)
        nrm = normal_map(hgt, 3.0, False)
        n = nrm.copy()
        n[..., :2] = 0.5 + (n[..., :2] - 0.5) * a[..., None]
        extra["normal"] = n
    ys, xs = np.where(a > 0.02)
    pad = 12
    y0, y1 = max(ys.min() - pad, 0), min(ys.max() + pad + 1, a.shape[0])
    x0, x1 = max(xs.min() - pad, 0), min(xs.max() + pad + 1, a.shape[1])
    col, a = col[y0:y1, x0:x1], a[y0:y1, x0:x1]
    rgba = np.dstack([col, a])
    p = os.path.join(d, f"{name}.png")
    Image.fromarray(to_srgb8(rgba), "RGBA").save(p, optimize=True)
    if "normal" in extra:
        save_png8(os.path.join(d, f"{name}_normal.png"), extra["normal"][y0:y1, x0:x1])
    # 1k copy (longest side 1024)
    s = 1024 / max(rgba.shape[:2])
    if s < 1:
        sm = cv2.resize(rgba, (int(rgba.shape[1] * s), int(rgba.shape[0] * s)), interpolation=cv2.INTER_AREA)
        Image.fromarray(to_srgb8(sm), "RGBA").save(os.path.join(d, f"{name}_1k.png"), optimize=True)
    return p


# ---------------------------------------------------------------- contact sheets
def contact(paths, out, tile_h=300, cols=4, checker=False):
    ims = []
    for p in paths:
        im = Image.open(p)
        s = tile_h / im.height
        im = im.resize((max(1, int(im.width * s)), tile_h), Image.LANCZOS)
        if checker:
            bg = Image.new("RGB", im.size, (200, 200, 200))
            dr = ImageDraw.Draw(bg)
            for y in range(0, im.height, 16):
                for x in range(0, im.width, 16):
                    if (x // 16 + y // 16) % 2:
                        dr.rectangle([x, y, x + 15, y + 15], fill=(150, 150, 150))
            bg.paste(im, (0, 0), im)
            im = bg
        ims.append((os.path.basename(p), im.convert("RGB")))
    cw = max(i.width for _, i in ims)
    rows = (len(ims) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (cw + 8), rows * (tile_h + 22)), (245, 243, 238))
    dr = ImageDraw.Draw(sheet)
    for k, (n, im) in enumerate(ims):
        x, y = (k % cols) * (cw + 8), (k // cols) * (tile_h + 22)
        sheet.paste(im, (x, y))
        dr.text((x + 2, y + tile_h + 4), n, fill=(20, 20, 20))
    sheet.save(out, quality=85)


def main(argv):
    names = argv[1:]
    pv, obj = [], []
    for n, c in SURFACES.items():
        if names and n not in names:
            if os.path.exists(os.path.join(OUT, n, f"{n}_preview_2x2.jpg")):
                pv.append(os.path.join(OUT, n, f"{n}_preview_2x2.jpg"))
            continue
        print("surface", n, flush=True)
        pv.append(build_surface(n, c))
    for n, c in OBJECTS.items():
        if names and n not in names:
            if os.path.exists(os.path.join(OUT, "objects", n + ".png")):
                obj.append(os.path.join(OUT, "objects", n + ".png"))
            continue
        print("object", n, flush=True)
        obj.append(build_object(n, c))
    if pv:
        contact(pv, os.path.join(OUT, "contact_previews.jpg"), tile_h=300, cols=3)
    if obj:
        contact(obj, os.path.join(OUT, "contact_objects.jpg"), tile_h=280, cols=5, checker=True)


if __name__ == "__main__":
    main(sys.argv)
