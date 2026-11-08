#!/usr/bin/env python3
"""Lockwright: grayscale contrast of every moving element of a plan-B family plate vs its background.

Layer plates (layers.json: plate.png + one RGBA layer per moving part + front.png):
  element  = the layer's visible pixels (alpha > 0.5, not covered by front.png)
  ring     = the composite (plate + front, no other moving part) in a band 3..9 px round the element
  behind   = the plate under the element's footprint (what shows when the part moves away)
Photo plates (lever/wafer: parts.png + plate.png, same camera):
  element  = pixels where parts differs from plate (the moving parts), ring/behind from plate.png
Luminance is WCAG relative luminance (linear sRGB, Rec.709 weights), i.e. the grayscale picture;
each region is summarised by its median, contrast = (Lhi + 0.05) / (Llo + 0.05).
Usage: plate_contrast.py DIR [DIR...] [--json out.json]   (DIR = .../<family>/photo)
"""
import json, os, sys
import numpy as np
from PIL import Image, ImageFilter


def lum(rgb):
    c = rgb.astype(np.float32) / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def ratio(a, b):
    hi, lo = max(a, b), min(a, b)
    return (hi + 0.05) / (lo + 0.05)


def dilate(mask, r):
    im = Image.fromarray((mask * 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.MaxFilter(2 * r + 1))) > 127


def measure_layers(d):
    meta = json.load(open(os.path.join(d, 'layers.json')))
    L = meta['layers']
    plate = np.asarray(Image.open(os.path.join(d, 'plate.png')).convert('RGB'))
    H, W = plate.shape[:2]
    bg = Image.fromarray(plate).convert('RGBA')
    front_a = np.zeros((H, W), np.float32)
    if 'front' in L and os.path.exists(os.path.join(d, 'front.png')):
        fr = Image.open(os.path.join(d, 'front.png')).convert('RGBA')
        bg.alpha_composite(fr, tuple(L['front']['offset']))
        x, y = L['front']['offset']; fa = np.asarray(fr)[..., 3] / 255.0
        front_a[y:y + fa.shape[0], x:x + fa.shape[1]] = fa[:H - y, :W - x]
    bgl = lum(np.asarray(bg.convert('RGB')))
    plate_l = lum(plate)
    out = {}
    for n, info in L.items():
        if n in ('plate', 'front'):
            continue
        p = os.path.join(d, n + '.png')
        if not os.path.exists(p):
            continue
        im = np.asarray(Image.open(p).convert('RGBA'))
        x, y = info['offset']; h, w = im.shape[:2]
        h, w = min(h, H - y), min(w, W - x)
        a = np.zeros((H, W), np.float32); a[y:y + h, x:x + w] = im[:h, :w, 3] / 255.0
        rgb = np.zeros((H, W, 3), np.uint8); rgb[y:y + h, x:x + w] = im[:h, :w, :3]
        el = (a > 0.5) & (front_a < 0.5)
        if el.sum() < 20:
            continue
        foot = a > 0.02
        ring = dilate(foot, 9) & ~dilate(foot, 3) & (front_a < 0.5)
        le = float(np.median(lum(rgb)[el]))
        lr = float(np.median(bgl[ring])) if ring.any() else le
        lb = float(np.median(plate_l[el]))
        out[n] = {'element': le, 'ring': lr, 'behind': lb, 'c_ring': ratio(le, lr), 'c_behind': ratio(le, lb)}
    return out


def measure_photo(d):
    parts = np.asarray(Image.open(os.path.join(d, 'parts.png')).convert('RGB')).astype(np.int16)
    plate = np.asarray(Image.open(os.path.join(d, 'plate.png')).convert('RGB')).astype(np.int16)
    diff = np.abs(parts - plate).max(axis=2)
    el = diff > 24
    el = ~dilate(~el, 2)  # erode: keep the parts' interior
    el = dilate(el, 2) & el
    ring = dilate(el, 12) & ~dilate(el, 4)
    pl, pal = lum(plate.astype(np.uint8)), lum(parts.astype(np.uint8))
    le = float(np.median(pal[el])); lr = float(np.median(pal[ring])); lb = float(np.median(pl[el]))
    return {'moving_parts': {'element': le, 'ring': lr, 'behind': lb, 'c_ring': ratio(le, lr), 'c_behind': ratio(le, lb)}}


def main():
    args = sys.argv[1:]
    jout = None
    if '--json' in args:
        i = args.index('--json'); jout = args[i + 1]; del args[i:i + 2]
    res = {}
    for d in args:
        fam = os.path.basename(os.path.dirname(os.path.abspath(d))) + ('' if os.path.basename(d) == 'photo' else '/' + os.path.basename(d))
        r = measure_layers(d) if os.path.exists(os.path.join(d, 'layers.json')) else measure_photo(d)
        res[fam] = r
        print('== %s' % fam)
        for n, v in r.items():
            flag = 'OK ' if min(v['c_ring'], v['c_behind']) >= 3.0 else 'LOW'
            print('  %s %-12s el %.3f ring %.3f behind %.3f  ring %.2f:1  behind %.2f:1' % (flag, n, v['element'], v['ring'], v['behind'], v['c_ring'], v['c_behind']))
        mins = [min(v['c_ring'], v['c_behind']) for v in r.values()]
        print('  min %.2f:1  median %.2f:1' % (min(mins), float(np.median(mins))))
    if jout:
        json.dump(res, open(jout, 'w'), indent=1)


if __name__ == '__main__':
    main()
