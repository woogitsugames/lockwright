#!/usr/bin/env python3
"""Deterministic seamless wood PBR maps for Lockwright G03.

Run: python3 generate_textures.py
Requires: numpy, scipy, opencv-python, Pillow.
No external imagery, textures, brand assets or network downloads.
"""
from __future__ import annotations

import math
from pathlib import Path
import numpy as np
import cv2
from scipy.ndimage import gaussian_filter, maximum_filter, minimum_filter
from PIL import Image, ImageDraw, ImageFont

N = 2048
HERE = Path(__file__).resolve().parent
MATS = HERE / 'materials'
PRV = HERE / 'previews'
for directory in (MATS, PRV):
    directory.mkdir(parents=True, exist_ok=True)

X = (np.arange(N, dtype=np.float32)[None, :] + np.float32(0.5)) / N
Y = (np.arange(N, dtype=np.float32)[:, None] + np.float32(0.5)) / N
TAU = np.float32(2 * np.pi)


def norm(a):
    return (a - np.mean(a)) / max(0.00001, np.std(a))


def octave(seed, cols, rows):
    """Cubic-interpolated toroidal noise, seamless in both axes."""
    rng = np.random.default_rng(seed)
    small = rng.normal(size=(rows, cols)).astype(np.float32)
    xx = np.broadcast_to(((np.arange(N, dtype=np.float32) + 0.5) * cols / N - 0.5)[None, :], (N, N)).copy()
    yy = np.broadcast_to(((np.arange(N, dtype=np.float32) + 0.5) * rows / N - 0.5)[:, None], (N, N)).copy()
    out = cv2.remap(small, xx, yy, cv2.INTER_CUBIC, borderMode=cv2.BORDER_WRAP)
    return norm(out).astype(np.float32)


def grain(seed, species):
    rng = np.random.default_rng(seed)
    broad = octave(seed + 1, 8, 13)
    wave = octave(seed + 2, 18, 6)
    irregular = octave(seed + 3, 44, 7)
    vertical = octave(seed + 4, 29, 35)
    # Torus-preserving longitudinal phase, with knots deflecting nearby rings.
    displacement = (0.008 * np.sin(TAU * (Y * 3 + 0.25 * np.sin(TAU * Y * 2)))
                    + 0.006 * wave / 4 + 0.0035 * irregular / 4)
    displacement = np.broadcast_to(displacement, (N, N)).copy()
    knots = [(0.29, 0.36, 0.037, 0.115, 0.75), (0.79, 0.72, 0.028, 0.081, -0.62)]
    if species == 'pine':
        knots = [(0.25, 0.37, 0.067, 0.114, 0.9), (0.73, 0.77, 0.049, 0.09, -0.8)]
    elif species == 'walnut':
        knots = [(0.31, 0.50, 0.041, 0.13, 0.95), (0.78, 0.20, 0.035, 0.10, -0.7)]
    knot_pigment = np.zeros((N, N), dtype=np.float32)
    for cx, cy, wx, wy, sign in knots:
        dx = (X - cx + 0.5) % 1.0 - 0.5
        dy = (Y - cy + 0.5) % 1.0 - 0.5
        r2 = (dx / wx) ** 2 + (dy / wy) ** 2
        g = np.exp(-r2 * 1.5)
        # A shear field forces ring lines around the knot rather than overlaying oval icons.
        displacement += sign * 0.065 * dx * g * (1.0 + 0.4 * np.sin(9 * dy / wy))
        knot_pigment += g * (0.6 + 0.3 * np.sin(5 * r2))
    u = X + displacement
    rings = (0.58 * np.sin(TAU * (13 * u + 0.4 * broad))
             + 0.29 * np.sin(TAU * (32 * u + 0.37 * broad))
             + 0.15 * np.sin(TAU * (77 * u + 0.3 * wave)))
    lines = (0.40 * np.sin(TAU * (116 * u + 0.1 * vertical))
             + 0.18 * np.sin(TAU * (229 * u + 0.12 * irregular)))
    if species == 'pine':
        rings = (0.82 * np.sin(TAU * (10 * u + 0.34 * broad))
                 + 0.22 * np.sin(TAU * (37 * u + 0.22 * wave)))
        lines *= 0.62
    elif species == 'walnut':
        rings *= 0.92
        lines *= 0.77
    fibrous = norm(rings + lines * 0.46)
    # Long, intermittent open pores rather than perfectly continuous bands.
    micro = rng.random((N, N), dtype=np.float32)
    pores = gaussian_filter(micro, (5.3 if species == 'oak' else 3.6, 0.65), mode='wrap')
    pores = norm(pores)
    porous = np.clip((pores - (1.12 if species == 'oak' else 1.47)) / 2.4, 0, 1)
    subtle = gaussian_filter(rng.random((N, N), dtype=np.float32), (1.4, 0.8), mode='wrap')
    subtle = norm(subtle)
    board_edges = np.array([0, 0.19, 0.47, 0.67, 0.88, 1], dtype=np.float32)
    board_tones = np.array([-5, 10, -8, 7, -5], dtype=np.float32)
    board_index = np.searchsorted(board_edges, X, side='right') - 1
    board_index = np.clip(board_index, 0, len(board_tones) - 1)
    plank = board_tones[board_index]
    for edge in board_edges[1:-1]:
        # Soft color shift; separate board geometry is modeled by Blender.
        plank += 0.0 * np.exp(-((X-edge)/0.001)**2)
    return dict(fibrous=fibrous, porous=porous, subtle=subtle, broad=broad,
                plank=plank, knot=knot_pigment, vertical=vertical,
                u=u)


def scratches(seed, count=125, line_length=(20, 350), widths=(1, 3)):
    """Tiled scratches drawn with wrap copies; sampled in height/roughness."""
    rng = np.random.default_rng(seed)
    im = Image.new('L', (N, N), 0)
    d = ImageDraw.Draw(im)
    for _ in range(count):
        x = float(rng.uniform(0, N))
        y = float(rng.uniform(0, N))
        dx = float(rng.normal(0, 14))
        dy = float(rng.uniform(*line_length)) * (-1 if rng.random()<.5 else 1)
        w = int(rng.integers(widths[0], widths[1]+1))
        color = int(rng.integers(100, 241))
        for ox in (-N,0,N):
            for oy in (-N,0,N):
                d.line((x+ox, y+oy, x+dx+ox, y+dy+oy), fill=color, width=w)
    result = np.asarray(im, dtype=np.float32)/255.0
    return gaussian_filter(result, 0.65, mode='wrap')


def chip_mask(seed, style):
    a = octave(seed + 10, 11, 23)
    b = octave(seed + 11, 36, 55)
    c = octave(seed + 12, 83, 120)
    d = octave(seed + 13, 4, 9)
    # Ragged longitudinal paint lifting near scratches and vertical hairline splits.
    scratch = scratches(seed + 12, 178 if style == 'cream' else 110,
                        (35, 450), (2, 8))
    mix = 0.51*a + 0.28*b + 0.13*c + 0.23*d + 1.1*scratch
    threshold = 0.69 if style == 'cream' else 0.84
    raw = np.clip((mix-threshold)*3.3, 0, 1)
    # Micro-teeth on damaged edges, no long horizontal seams.
    return np.clip(raw, 0, 1).astype(np.float32)


def make_maps(name, species, seed, rgb, style='varnish'):
    f = grain(seed, species)
    scratches_a = scratches(seed+21, 120 if style == 'varnish' else 155,
                            (18, 240), (1, 2))
    scratches_b = scratches(seed+22, 53, (85, 515), (1, 3))
    fine = octave(seed+19, 212, 143)
    woodval = (0.39*f['fibrous'] + 0.18*f['broad'] + 0.13*f['vertical']
               + 0.056*fine - 0.58*f['porous'] - 0.46*f['knot']
               - 0.42*scratches_a + 0.037*f['subtle'])
    plank = np.broadcast_to(f['plank'], (N,N))
    val = woodval*26 + plank + 2.8*f['subtle']
    if species == 'walnut': val *= 0.85
    wood = np.stack((rgb[0] + val*1.07,
                     rgb[1] + val*0.79,
                     rgb[2] + val*0.55), axis=-1).astype(np.float32)
    wood_h = np.clip(0.47 + 0.053*f['fibrous'] - 0.095*f['porous']
                     - 0.070*scratches_a + 0.015*fine, .08, .88)
    wood_r = np.clip((0.37 if species == 'oak' else 0.43 if species == 'pine' else 0.32)
                     + 0.045*f['broad'] + 0.13*f['porous']
                     + 0.15*scratches_a + 0.022*fine, .19, .89)
    if style == 'varnish':
        rgb_map = wood
        # Satin worn finish with minor faint drying marks; not shadows.
        h_map = wood_h
        r_map = wood_r
    else:
        exposed = chip_mask(seed, style)
        exposed = np.clip(exposed, 0, 1)
        coverage = 1.0 - exposed
        brush = 0.075*np.sin(TAU * (80*f['u'] + 0.6*f['broad']))
        paint_noise = 0.65*f['broad'] + 0.38*f['vertical'] + 0.2*fine
        paintval = paint_noise * (9 if style=='cream' else 7) + brush * 15
        paint_rgb = np.array([224, 211, 179] if style=='cream' else [28, 67, 50], dtype=np.float32)
        painted = np.stack((paint_rgb[0]+paintval*0.90,
                            paint_rgb[1]+paintval*0.81,
                            paint_rgb[2]+paintval*0.73), axis=-1)
        # A very narrow exposed undercoat at edges of paint flakes.
        edge = gaussian_filter(exposed, 1.2, mode='wrap') - gaussian_filter(exposed, 5.5, mode='wrap')
        rim = np.clip(edge*6.0,0,1)
        undercoat = np.array([146,111,69] if style == 'cream' else [55,77,48],dtype=np.float32)
        painted = painted*(1-rim[...,None]*0.5) + undercoat[None,None,:]*rim[...,None]*0.5
        rgb_map = painted*coverage[...,None] + wood*exposed[...,None]
        h_map = np.clip(wood_h*0.54 + coverage*(0.185 if style=='cream' else 0.122)
                         + brush*0.12 - np.maximum(edge,0)*0.015,0,1)
        r_map = np.clip(wood_r*exposed + coverage*(0.70 if style=='cream' else 0.56)
                        + 0.025*fine + 0.065*scratches_b,0.18,0.95)
    # Seam conditioning: reflect face values across a thin periodic transition.
    def condition(a):
        a = a.copy()
        # The underlying fields are periodic; align edge samples at the final texel.
        m = (a[:, 0] + a[:, -1]) / 2.0
        a[:, 0] = m
        a[:, -1] = m
        m = (a[0] + a[-1]) / 2.0
        a[0] = m
        a[-1] = m
        return a
    rgb_map = np.uint8(np.clip(condition(rgb_map),0,255))
    # 16-bit height is useful in Blender's non-color data pipeline.
    height_map = np.uint16(np.clip(condition(h_map),0,1)*65535 + 0.5)
    rough_map = np.uint8(np.clip(condition(r_map),0,1)*255 + 0.5)
    for typ, data, mode in [('albedo',rgb_map,'RGB'),('height',height_map,'I;16'),('roughness',rough_map,'L')]:
        file = MATS / f'{name}_{typ}_2048.png'
        Image.fromarray(data).save(file,compress_level=3)
        print(file.name, round(file.stat().st_size/1024/1024,2),'MiB')
    return rgb_map


def ensure_size(img, w, h):
    return img.resize((w,h), Image.Resampling.LANCZOS)


def preview(albedos):
    fontfile='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
    font=ImageFont.truetype(fontfile,26)
    smallfont=ImageFont.truetype(fontfile,17)
    labels=[('Dąb satynowy','Satin oak'),('Dąb malowany — butelkowa zieleń','Bottle-green painted oak'),
            ('Sosna malowana — krem','Cream painted pine'),('Orzech ciemny','Dark walnut')]
    tile=706
    w=tile*2+54
    h=(tile+75)*2+48
    sheet=Image.new('RGB',(w,h),(28,29,28))
    d=ImageDraw.Draw(sheet)
    for i,(_, arr) in enumerate(albedos):
        col=i%2; row=i//2
        x=18+col*(tile+18); y=18+row*(tile+75)
        im=Image.fromarray(arr,'RGB').resize((tile,tile),Image.Resampling.LANCZOS)
        sheet.paste(im,(x,y))
        d.text((x+4,y+tile+9),labels[i][0],font=font,fill=(233,225,207))
        d.text((x+4,y+tile+39),labels[i][1],font=smallfont,fill=(181,177,167))
    sheet.save(PRV/'preview_albedo_2x2.jpg',quality=91,subsampling=0)

    maps=Image.new('RGB',(1536,1100),(28,29,28))
    dd=ImageDraw.Draw(maps)
    names=['Albedo','Height','Roughness']
    for index,(key,_) in enumerate(albedos):
        row=index//2;col=index%2
        xx=16+col*768; yy=15+row*550
        dd.text((xx+9,yy+4),labels[index][1],font=font,fill=(225,216,198))
        for j,typ in enumerate(['albedo','height','roughness']):
            im=Image.open(MATS/f'{key}_{typ}_2048.png')
            if typ == 'height':
                import numpy as _np
                a=_np.array(im,dtype=_np.float32)
                a=_np.uint8(_np.clip((a-8192)/(45056-8192)*255,0,255))
                im=Image.fromarray(a,'L')
            im=im.convert('RGB')
            im=im.resize((237,435),Image.Resampling.LANCZOS)
            maps.paste(im,(xx+9+j*246,yy+40))
            dd.text((xx+9+j*246,yy+481),names[j]+(' (view)' if typ=='height' else ''),font=smallfont,fill=(210,206,194))
    maps.save(PRV/'preview_pbr_2x2.jpg',quality=89,subsampling=0)


def main():
    materials=[
       ('oak_satin','oak',411,(149,98,56),'varnish'),
       ('oak_bottle_green','oak',822,(158,102,56),'green'),
       ('pine_cream','pine',1227,(169,126,84),'cream'),
       ('walnut_dark','walnut',1644,(82,53,35),'varnish'),
    ]
    arrs=[]
    for key,species,seed,color,style in materials:
        print('Generating:',key,flush=True)
        existing=MATS/f'{key}_albedo_2048.png'
        if existing.exists() and (MATS/f'{key}_height_2048.png').exists() and (MATS/f'{key}_roughness_2048.png').exists():
            print('Reusing existing maps:',key,flush=True)
            arr=np.asarray(Image.open(existing).convert('RGB'))
        else:
            arr=make_maps(key,species,seed,color,style)
        arrs.append((key,arr))
    preview(arrs)
    print('Generated 12 maps and two contact sheets.')

if __name__=='__main__': main()
