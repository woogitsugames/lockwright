#!/usr/bin/env python3
"""Lockwright: before/after contact sheet for re-rendered plan-B family plates (colour + grayscale,
with the grayscale contrast of the weakest moving element from plate_contrast.py).
Usage: family_sheet.py OUT.jpg LABEL=BEFORE_DIR:AFTER_DIR [...]   (dirs: .../<family>/photo)"""
import json, os, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plate_contrast as pc

TW, TH = 330, 440


def compose(d):
    if not os.path.exists(os.path.join(d, 'layers.json')):
        return Image.open(os.path.join(d, 'parts.png')).convert('RGB')
    L = json.load(open(os.path.join(d, 'layers.json')))['layers']
    base = Image.open(os.path.join(d, 'plate.png')).convert('RGBA')
    for n in L:
        if n in ('plate', 'front') or not os.path.exists(os.path.join(d, n + '.png')):
            continue
        base.alpha_composite(Image.open(os.path.join(d, n + '.png')).convert('RGBA'), tuple(L[n]['offset']))
    if 'front' in L:
        base.alpha_composite(Image.open(os.path.join(d, 'front.png')).convert('RGBA'), tuple(L['front']['offset']))
    return base.convert('RGB')


def gray(im):
    l = pc.lum(np.asarray(im))
    s = np.where(l <= 0.0031308, l * 12.92, 1.055 * np.power(l, 1 / 2.4) - 0.055)
    return Image.fromarray((np.clip(s, 0, 1) * 255).astype(np.uint8)).convert('RGB')


def worst(d):
    r = pc.measure_layers(d) if os.path.exists(os.path.join(d, 'layers.json')) else pc.measure_photo(d)
    k = min(r, key=lambda n: min(r[n]['c_ring'], r[n]['c_behind']))
    return k, min(r[k]['c_ring'], r[k]['c_behind'])


def font(sz):
    for f in ('C:/Windows/Fonts/arial.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'):
        if os.path.exists(f):
            return ImageFont.truetype(f, sz)
    return ImageFont.load_default()


def main():
    out, rows = sys.argv[1], sys.argv[2:]
    head = 34; lab = 30
    sheet = Image.new('RGB', (4 * TW, head + len(rows) * (TH + lab)), (24, 22, 20))
    dr = ImageDraw.Draw(sheet); f1, f2 = font(20), font(16)
    for i, t in enumerate(['before', 'after', 'before, grayscale', 'after, grayscale']):
        dr.text((i * TW + 10, 8), t, fill=(235, 230, 220), font=f1)
    for r, spec in enumerate(rows):
        name, dirs = spec.split('=', 1); b, a = dirs.split(':')
        y = head + r * (TH + lab)
        ims = [compose(b), compose(a)]
        ims += [gray(ims[0]), gray(ims[1])]
        for i, im in enumerate(ims):
            sheet.paste(im.resize((TW - 4, int((TW - 4) * im.height / im.width))).crop((0, 0, TW - 4, TH - 4)), (i * TW + 2, y + 2))
        (kb, cb), (ka, ca) = worst(b), worst(a)
        dr.text((10, y + TH + 4), '%s   weakest moving element (grayscale): before %s %.2f:1  ->  after %s %.2f:1' % (name, kb, cb, ka, ca),
                fill=(235, 230, 220), font=f2)
    sheet.save(out, quality=90)
    print('WROTE', out)


if __name__ == '__main__':
    main()
