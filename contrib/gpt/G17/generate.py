#!/usr/bin/env python3
"""Generate text-free 9-slice enamel plaques from approved AI source images.
Requires Pillow and NumPy. No content outside contrib/gpt/G17 is written.
"""
from __future__ import annotations
import json
import math
from pathlib import Path
from PIL import ImageCms
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

DIR = Path(__file__).resolve().parent
SRGB_ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
SRC_W = DIR / 'source/enamel_wide_chatgpt.png'
SRC_Q = DIR / 'source/enamel_square_chatgpt.png'
DATE = '2026-11-05'
COLORS = {
    'navy': (9, 31, 77),
    'bottle_green': (17, 67, 44),
    'ivory': (219, 210, 184),
    'burgundy': (107, 25, 44),
}


def crop_asset(src: Image.Image, threshold: int = 180) -> Image.Image:
    alpha = np.array(src.convert('RGBA'))[:, :, 3]
    yy, xx = np.where(alpha > threshold)
    # Keep at least the outer enamel silhouette, not the long AI cast shadow.
    return src.crop((max(0, int(xx.min()) - 3), max(0, int(yy.min()) - 3),
                     min(src.width, int(xx.max()) + 4), min(src.height, int(yy.max()) + 4)))


def remove_cast_shadow(im: Image.Image) -> Image.Image:
    arr = np.array(im.convert('RGBA'), dtype=np.float32)
    # Isolate physical enamel; create the actual maximum-12px shadow later.
    arr[:, :, 3] = np.clip((arr[:, :, 3] - 100) * (255 / 147), 0, 255)
    return Image.fromarray(np.uint8(np.rint(arr)), 'RGBA')


def nine_slice_clean_horizontal(src: Image.Image, width: int, height: int,
                                 end_margin: int, primary: bool = False) -> Image.Image:
    # No chips or screws in stretchable center: sample ONE clean slice between chips.
    # Remapping is done in source space before 9-slice margins are announced.
    raw = np.array(src)
    h, w = raw.shape[:2]
    left_source = int(w * .24)
    right_source = int(w * .77)
    left = src.crop((0, 0, left_source, h)).resize((end_margin, height), Image.Resampling.LANCZOS)
    right = src.crop((right_source, 0, w, h)).resize((end_margin, height), Image.Resampling.LANCZOS)
    middle_width = width - 2 * end_margin
    # Visually clean at original position ~44.5%; no horizontal row of chips.
    a = int(w * .445)
    b = min(w, a + int(w * .025))
    center_strip = src.crop((a, 0, b, h))
    mid = center_strip.resize((middle_width, height), Image.Resampling.BICUBIC)
    out = Image.new('RGBA', (width, height))
    out.paste(left, (0, 0))
    out.paste(mid, (end_margin, 0))
    out.paste(right, (width - end_margin, 0))
    # Crossfade texture across two join boundaries, preserving border geometry.
    A = np.array(out, dtype=np.float32)
    for x in [end_margin, width - end_margin]:
        smooth = 24
        lo, hi = x - smooth, x + smooth
        if hi < width:
            # Reconstruct a gently feathered 48 px passage from each side of the join.
            lcol = A[:, lo:lo+5, :].mean(axis=1)
            rcol = A[:, hi-5:hi, :].mean(axis=1)
            for col in range(lo, hi):
                t = (col - lo) / max(1, hi - lo - 1)
                blend = (1-t) * lcol + t * rcol
                # Blend mainly enamel core; top/bottom seam is less visible if blurred.
                A[:, col, :] = .35*A[:, col, :] + .65*blend
    return Image.fromarray(np.uint8(np.clip(A,0,255)), 'RGBA')


def recolor(im: Image.Image, shade: str) -> Image.Image:
    if shade == 'navy':
        return im
    p = np.array(im, dtype=np.float32)
    rgb = p[:, :, :3]
    r, g, b = rgb[:, :, 0].copy(), rgb[:, :, 1].copy(), rgb[:, :, 2].copy()
    # Detect original light cream trim BEFORE recoloring the navy enamel.
    cream_original = (np.clip((r-140)/55,0,1) * np.clip((g-120)/55,0,1)
          * np.clip((r-b-12)/42,0,1) * np.clip((b-95)/52,0,1) * .96)
    # Saturated blue enamel alone; no recolor on the exposed rust or dark screw holes.
    chroma = np.minimum(b-r, b-g)
    blue = np.clip((chroma - 8) / 34, 0, 1)
    blue *= np.clip((b - 28) / 30, 0, 1)
    # Gloss responds to incoming source light, rather than using a flat fill.
    original_luminance = .24*r + .54*g + .22*b
    glint = np.clip((original_luminance - 29) / 85, -.32, 1.15)
    target = np.array(COLORS[shade], dtype=np.float32)
    val = np.clip(target[None,None,:] * (1+ .33*glint[...,None]) + 16*glint[...,None], 0,255)
    rgb[:] = rgb*(1-blue[...,None]) + val*blue[...,None]
    if shade == 'ivory':
        # Original cream pinstripe becomes dark charcoal only; protect inner ivory field.
        rgb[:] = rgb * (1-cream_original[...,None]) + np.array([43,46,41])[None,None,:] * cream_original[...,None]
    p[:,:,:3]=rgb
    return Image.fromarray(np.uint8(np.rint(np.clip(p, 0,255))), 'RGBA')


def render_state(plate: Image.Image, pressed: bool, out_size: tuple[int, int]) -> Image.Image:
    w,h = out_size
    # Source plate is already at exact size, leaving ample room for outline and 12px shadow.
    canvas = Image.new('RGBA', out_size, (0,0,0,0))
    physical = plate.copy()
    if pressed:
        p = np.array(physical, dtype=np.float32)
        p[:,:,:3] *= .975
        physical = Image.fromarray(np.uint8(p.clip(0,255)), 'RGBA')
    offset_y = 7 if pressed else 2
    # Placement: both variants use the exact same crop, scale and canvas.
    px = int(w*.010)
    py = int(h*.044) + offset_y
    plate_w = w - px*2
    plate_h = h - int(h*.105)
    physical = physical.resize((plate_w,plate_h),Image.Resampling.LANCZOS)
    mask = physical.getchannel('A')
    # Only 0–12 px external shadow; lower alpha after pressing.
    shadow = Image.new('RGBA',out_size)
    shadow_mask = Image.new('L',out_size)
    shadow_mask.paste(mask,(px,py+ (3 if pressed else 6)))
    blur = shadow_mask.filter(ImageFilter.GaussianBlur(2.5 if pressed else 4.0))
    shadow_alpha = blur.point(lambda v: int(v*(.11 if pressed else .26)))
    shadow.putalpha(shadow_alpha)
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(physical,(px,py))
    return canvas


def render_square(plate: Image.Image) -> Image.Image:
    plate = plate.resize((480,480), Image.Resampling.LANCZOS)
    out = Image.new('RGBA',(512,512))
    sm=Image.new('L',(512,512))
    sm.paste(plate.getchannel('A'),(16,18))
    a = sm.filter(ImageFilter.GaussianBlur(4)).point(lambda v:int(v*.20))
    shade=Image.new('RGBA',(512,512),(0,0,0,0))
    shade.putalpha(a)
    out.alpha_composite(shade)
    out.alpha_composite(plate,(16,16))
    return out


def make_contact(files: list[tuple[str, Image.Image]]) -> None:
    cols, cw, ch = 2, 760, 320
    rows=math.ceil(len(files)/cols)
    board=Image.new('RGB',(cols*cw+60,rows*ch+60),(228,226,219))
    d=ImageDraw.Draw(board)
    try: f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',22)
    except OSError: f=ImageFont.load_default()
    for i,(name,im) in enumerate(files):
        c,r=i%cols,i//cols
        x,y=30+c*cw,30+r*ch
        d.rounded_rectangle((x,y,x+cw-15,y+ch-15),radius=8,fill=(206,204,197),outline=(175,175,168),width=2)
        # Checkerboard behind transparency, strictly for contact sheet.
        for ry in range(y+32,y+ch-26,22):
            for rx in range(x+22,x+cw-36,22):
                d.rectangle((rx,ry,rx+21,ry+21),fill=(230,230,225) if (rx//22+ry//22)%2 else (245,245,243))
        thumb=im.copy();thumb.thumbnail((cw-72,ch-108),Image.Resampling.LANCZOS)
        board.paste(thumb,(x+(cw-thumb.width)//2,y+52+(ch-108-thumb.height)//2),thumb)
        d.text((x+26,y+9),name,fill=(39,42,42),font=f)
    board.save(DIR/'contact_sheet.jpg',quality=93,subsampling=0)


def main():
    src=remove_cast_shadow(crop_asset(Image.open(SRC_W).convert('RGBA')))
    sq=remove_cast_shadow(crop_asset(Image.open(SRC_Q).convert('RGBA')))
    files=[]; manifest={'format':'png','color_space':'sRGB','bit_depth':8,'alpha':True,
        'nine_slice_notes':'Corners, holes and chips are in the fixed edges. Middle is artificially stretched from a clean narrow enamel band.',
        'plates':{}}
    for color in COLORS:
        base=nine_slice_clean_horizontal(src,1600,400,end_margin=340)
        base=recolor(base,color)
        for state in ['normal','pressed']:
            fname=f'button_{color}_{state}.png'
            result=render_state(base,state=='pressed',(1600,400))
            result.save(DIR/fname,optimize=True,icc_profile=SRGB_ICC)
            manifest['plates'][fname]={'width':1600,'height':400,
                'margins':{'left':350,'top':85,'right':350,'bottom':85},
                'color':color,'state':state}
            files.append((fname,result))
    main_plate=recolor(nine_slice_clean_horizontal(src,1500,500,end_margin=320), 'navy')
    for state in ['normal','pressed']:
        fname=f'primary_navy_{state}.png'
        result=render_state(main_plate,state=='pressed',(1500,500))
        result.save(DIR/fname,optimize=True,icc_profile=SRGB_ICC)
        manifest['plates'][fname]={'width':1500,'height':500,
            'margins':{'left':335,'top':100,'right':335,'bottom':100},
            'color':'navy','state':state,'border':'thick (vertical scale for primary)'}
        files.append((fname,result))
    for color in COLORS:
        fname=f'initial_{color}.png'
        result=render_square(recolor(sq,color))
        result.save(DIR/fname,optimize=True,icc_profile=SRGB_ICC)
        manifest['plates'][fname]={'width':512,'height':512,'color':color,'state':'normal',
                                   'nine_slice':False}
        files.append((fname,result))
    (DIR/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    make_contact(files)
    assert len(files)==14
    for nm,im in files:
        assert im.mode=='RGBA' and im.size==tuple(manifest['plates'][nm][k] for k in ['width','height'])
    print('G17 OK: 14 images, manifest, contact_sheet.jpg')

if __name__=='__main__':main()
