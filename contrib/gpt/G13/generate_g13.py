#!/usr/bin/env python3
"""Build the G13 artwork exports from the 4 source PNGs, with Pillow/FontTools/CairoSVG.
Only writes to the directory containing this script. All logo glyphs are vector outlines.
"""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw, ImageFont, ImageFilter, ImageEnhance
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from io import BytesIO
from math import sin, pi
import cairosvg
import re, os

ROOT=Path(__file__).resolve().parent
SRC=ROOT/'source'
FONT_DIR=Path('/usr/share/fonts/truetype/ebgaramond')
FONT_BOLD=FONT_DIR/'EBGaramond12-Bold.ttf'
FONT_REG=FONT_DIR/'EBGaramond12-Regular.ttf'
FONT_ITALIC=FONT_DIR/'EBGaramond12-Italic.ttf'
FONT_SANS=Path('/usr/share/fonts/truetype/lato/Lato-Regular.ttf')
IVORY='#F3E8D2'
PARCH='#ECE1C9'
BRASS='#C29F68'
DARK='#211A14'

for d in ['key-art','feature','social','logos','preview']: (ROOT/d).mkdir(exist_ok=True)
IMAGES={p.stem:Image.open(p).convert('RGB') for p in SRC.glob('*.png')}


def fit(im, size, anchor=(.5,.5)):
    W,H=size; w,h=im.size
    scale=max(W/w,H/h)
    nw,nh=int(round(w*scale)),int(round(h*scale))
    im=im.resize((nw,nh),Image.Resampling.LANCZOS)
    x=max(0,min(nw-W,int((nw-W)*anchor[0])))
    y=max(0,min(nh-H,int((nh-H)*anchor[1])))
    return im.crop((x,y,x+W,y+H))


def subtle_vignette(im, strength=.10):
    w,h=im.size
    mask=Image.new('L',(w,h),0)
    # build mask at 1/8 resolution
    sm=(max(64,w//10),max(64,h//10))
    m=Image.new('L',sm); p=m.load(); ww,hh=sm
    for y in range(hh):
        for x in range(ww):
            dx=(x/(ww-1)-.5)*2;dy=(y/(hh-1)-.5)*2
            p[x,y]=int(min(255,max(0,(dx*dx*.7+dy*dy*.3)*255*strength)))
    mask=m.resize((w,h),Image.Resampling.BILINEAR)
    dark=Image.new('RGB',(w,h),(14,12,10))
    return Image.composite(dark,im,mask)


def left_matte(im, strength=.46, cutoff=.51, start=.00):
    W,H=im.size
    sm=(max(32,W//14),max(32,H//14))
    mask=Image.new('L',sm); p=mask.load(); ww,hh=sm
    for x in range(ww):
        t=x/(ww-1)
        v=max(0,min(1,((cutoff-t)/max(.001,cutoff-start))))
        v=v*v*(3-2*v)
        for y in range(hh): p[x,y]=round(255*strength*v)
    dark=Image.new('RGB',(W,H),(22,19,16))
    return Image.composite(dark,im,mask.resize((W,H),Image.Resampling.BICUBIC))


def top_matte(im, strength=.65, cutoff=.37):
    W,H=im.size
    m=Image.new('L',(1,H))
    for y in range(H):
        z=max(0,1-y/(H*cutoff))
        m.putpixel((0,y),round(255*strength*z*z))
    m=m.resize((W,H)); return Image.composite(Image.new('RGB',(W,H),(24,22,19)),im,m)


def save_jpg(im, path, q=90):
    im.save(ROOT/path,quality=q,optimize=True,subsampling=0,progressive=True)

def save_png(im,path):
    im.save(ROOT/path,optimize=True)

# Key art: natural composition and alternate muted area for logo placement.
arrival=IMAGES['arrival-evening']
landing=IMAGES['arrival-landing']
portrait_source=IMAGES['arrival-bag']
land_clean=subtle_vignette(fit(arrival,(3840,2160)),.12)
land_logo=subtle_vignette(left_matte(fit(landing,(3840,2160)),.32,.51),.1)
save_jpg(land_clean,'key-art/key-art-3840x2160-clean.jpg',93)
save_jpg(land_logo,'key-art/key-art-3840x2160-logo-space.jpg',93)

# Crop to the two figures' conversation boundary: woman / notebook / sleeve.
# Rather than distorting the image, this portrait emphasizes a tighter detail.
portrait=fit(portrait_source,(2160,3840),(.685,.5))
portrait_clean=subtle_vignette(portrait,.12)
portrait_logo=top_matte(portrait_clean,.67,.33)
save_jpg(portrait_clean,'key-art/key-art-2160x3840-clean.jpg',90)
save_jpg(portrait_logo,'key-art/key-art-2160x3840-logo-space.jpg',90)

# Feature graphic: exactly 1024x500, safe title on the relatively empty left wall.
base=fit(landing,(1024,500),(.5,.5))
feature_clean=subtle_vignette(base,.08)
save_png(feature_clean,'feature/google-play-1024x500-clean.png')

# Serialize a font's outlines into a stable SVG: no font files distributed.
def font_face(path):
    font=TTFont(path)
    return (font,font.getGlyphSet(),font.getBestCmap(),font['hmtx'].metrics,font['head'].unitsPerEm)
FACES={'bold':font_face(FONT_BOLD),'regular':font_face(FONT_REG),'italic':font_face(FONT_ITALIC)}

def svg_word(text,x,y,size,face='bold',tracking=0,color=IVORY):
    font,glyphs,cmap,metrics,units=FACES[face]
    sx=size/units
    cursor=float(x); parts=[]
    for ch in text:
        nm=cmap.get(ord(ch))
        if nm is None: nm=cmap.get(ord(' '))
        if nm is None: continue
        pen=SVGPathPen(glyphs)
        glyphs[nm].draw(pen)
        d=pen.getCommands()
        if d:
            parts.append(f'<path fill="{color}" d="{d}" transform="translate({cursor:.3f},{y:.3f}) scale({sx:.8f},-{sx:.8f})"/>')
        cursor+=metrics[nm][0]*sx+tracking
    return ''.join(parts),cursor

# Title-only vector also used for exact Google Play feature headline.
txt,actual_end=svg_word('Lockwright',72,307,129,'bold',-2.5,IVORY)
feature_svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500" viewBox="0 0 1024 500">{txt}<path d="M76 353 H500" stroke="{BRASS}" stroke-width="2" opacity="0.85"/></svg>'
(ROOT/'feature/google-play-title-overlay.svg').write_text(feature_svg,encoding='utf-8')
feature_overlay=Image.open(BytesIO(cairosvg.svg2png(bytestring=feature_svg.encode(),output_width=1024,output_height=500))).convert('RGBA')
feature_titled=left_matte(feature_clean,.42,.59).convert('RGBA')
feature_titled.alpha_composite(feature_overlay)
save_png(feature_titled.convert('RGB'),'feature/google-play-1024x500-title.png')

# Three independently treated vector logos, outlined (OFL source: EB Garamond).
def logo_svg(variant,language, W=1600, H=470):
    subtitle='POGOTOWIE ZAMKOWE' if language=='pl' else 'LOCKSMITH ON CALL'
    if variant==1:
        t,ex=svg_word('Lockwright',95,256,225,'bold',-3.0,IVORY)
        st,se=svg_word(subtitle,314 if language=='pl' else 350,415,59,'regular',4.2,BRASS)
        # Custom-drawn rule and arrow-like terminal (no locks or generic icons).
        deco=f'<path d="M95 336 H1450 M95 336 l29 -12 M1450 336 l-29 -12" fill="none" stroke="{BRASS}" stroke-width="3"/>'
    elif variant==2:
        t,ex=svg_word('Lockwright',134,246,209,'regular',2.9,IVORY)
        st,se=svg_word(subtitle,345 if language=='pl' else 380,349,55,'bold',4.0,PARCH)
        # Enamel number-plate-inspired double side brackets, open not a SaaS card.
        deco=f'<path d="M94 80 h30 M94 80 v298 h30 M1520 80 h-30 M1520 80 v298 h-30" stroke="{BRASS}" fill="none" stroke-width="5"/>'
    else:
        first,a=svg_word('Lock',103,258,230,'bold',-2,IVORY)
        second,b=svg_word('wright',a-17,258,224,'italic',-2.5,IVORY)
        t=first+second
        st,se=svg_word(subtitle,320 if language=='pl' else 354,416,58,'regular',3.6,BRASS)
        deco=f'<path d="M112 335 C460 340 820 349 1395 329" fill="none" stroke="{BRASS}" stroke-width="3"/>'
        deco+='<circle cx="1451" cy="329" r="5" fill="'+BRASS+'"/>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}"><title>Lockwright / {subtitle} — concept {variant}</title>{deco}{t}{st}</svg>'

logo_rgba={}
for i in range(1,4):
    for lang in ['pl','en']:
        s=logo_svg(i,lang)
        stem=f'logos/concept-{i:02d}-{lang}'
        (ROOT/f'{stem}.svg').write_text(s,encoding='utf-8')
        pic=Image.open(BytesIO(cairosvg.svg2png(bytestring=s.encode(),output_width=1600,output_height=470))).convert('RGBA')
        pic.save(ROOT/f'{stem}.png',optimize=True)
        logo_rgba[(i,lang)]=pic

# Social exports with editorial title overlays, each PL and EN as separate files.
def add_logo(im,variant,lang,xy=(0,0),max_width=.82):
    W,H=im.size; pic=logo_rgba[(variant,lang)]
    nw=int(W*max_width); nh=int(nw*pic.height/pic.width)
    nw=max(1,nw);nh=max(1,nh)
    pic=pic.resize((nw,nh),Image.Resampling.LANCZOS)
    x,y=xy
    dest=im.convert('RGBA')
    dest.alpha_composite(pic,(x,y))
    return dest.convert('RGB')

for lang in ('pl','en'):
    # square: warm scene with a relatively small enamel-style signature top center
    sq=fit(arrival,(1080,1080),(.57,.47))
    sq=top_matte(subtle_vignette(sq,.18),.76,.36)
    sq=add_logo(sq,2,lang,(60,55),.82)
    save_jpg(sq,f'social/social-1080x1080-{lang}.jpg',91)
    # vertical: tight human encounter, logo in the upper, gently shadowed photo
    vert=fit(portrait_source,(1080,1920),(.685,.5))
    vert=subtle_vignette(vert,.18)
    # The title sits over the leather bag/wood below the client's face.
    # A soft photographic vignette provides contrast without hiding faces.
    W,H=vert.size
    m=Image.new('L',(1,H))
    for yy in range(H):
        t=max(0.0,1.0-abs(yy-1410)/530)
        m.putpixel((0,yy),round(130*t*t))
    vert=Image.composite(Image.new('RGB',(W,H),(20,17,14)),vert,m.resize((W,H)))
    vert=add_logo(vert,1,lang,(74,1240),.84)
    save_jpg(vert,f'social/social-1080x1920-{lang}.jpg',91)
    # wide: dusk corridor with welcoming client; title set on dark left side
    wide=left_matte(fit(landing,(1500,500),(.5,.42)),.56,.53)
    wide=add_logo(wide,3,lang,(55,120),.45)
    save_jpg(wide,f'social/social-1500x500-{lang}.jpg',92)

# Additional study of material detail, no person manipulating hardware.
# Frame is taken from the generated image: untouched door face and brass detail.
door_crop=fit(IMAGES['arrival-evening'],(1080,1920),(.98,.5))
save_jpg(door_crop,'preview/oak-and-brass-detail-1080x1920.jpg',90)

# Upscaled workshop concept only: a mood reference from the generated study-sheet grid.
# Not the final artwork: the original panel is only 390x215 pixels.
workshop_panel=IMAGES['study-sheet'].crop((15,666,403,886))
workshop_study=subtle_vignette(fit(workshop_panel,(1500,840)),.16)
save_jpg(workshop_study,'preview/workshop-concept-lowres.jpg',91)

# Contact sheet for approval, with readable categories.
white=(244,239,229); ink=(37,32,27)
CW,CH=2600,4200
sheet=Image.new('RGB',(CW,CH),white)
D=ImageDraw.Draw(sheet)
font_title=ImageFont.truetype(str(FONT_BOLD),112)
font_heading=ImageFont.truetype(str(FONT_BOLD),53)
font_body=ImageFont.truetype(str(FONT_SANS),36)
font_small=ImageFont.truetype(str(FONT_SANS),26)
D.text((120,55),'LOCKWRIGHT / G13',font=font_title,fill=ink)
D.text((120,205),'Key art · feature graphic · banners · logotypes',font=font_body,fill=(97,85,74))

def tile(im,box,label):
    x,y,w,h=box
    sz=(w,h-55)
    # Contain the whole sample (avoid deceptive crop on 9:16 and 3:1 exports).
    bg=Image.new('RGB',sz,(48,40,34))
    thumb=ImageOps.contain(im,sz,Image.Resampling.LANCZOS)
    ox=(sz[0]-thumb.width)//2; oy=(sz[1]-thumb.height)//2
    bg.paste(thumb,(ox,oy))
    sheet.paste(bg,(x,y+55))
    D.text((x,y+6),label,font=font_heading,fill=ink)

tile(Image.open(ROOT/'key-art/key-art-3840x2160-clean.jpg'),(120,320,1530,870),'Key art · 3840×2160')
tile(Image.open(ROOT/'key-art/key-art-2160x3840-clean.jpg'),(1730,320,740,870),'Key art · 2160×3840')
tile(Image.open(ROOT/'feature/google-play-1024x500-title.png'),(120,1310,1210,660),'Google Play · title')
tile(Image.open(ROOT/'feature/google-play-1024x500-clean.png'),(1390,1310,1080,660),'Google Play · clean')
tile(Image.open(ROOT/'social/social-1080x1080-pl.jpg'),(120,2100,740,780),'Social · 1080×1080')
tile(Image.open(ROOT/'social/social-1080x1920-en.jpg'),(920,2100,680,780),'Social · 1080×1920')
tile(Image.open(ROOT/'social/social-1500x500-pl.jpg'),(1660,2100,810,780),'Social · 1500×500')
D.text((120,3040),'THREE LOGOTYPE CONCEPTS / PL + EN',font=font_heading,fill=ink)
for i in range(1,4):
    for j,lang in enumerate(['pl','en']):
        canvas=Image.new('RGBA',(1020,240),(30,26,22,255))
        pic=logo_rgba[(i,lang)]
        w=980; h=round(w*pic.height/pic.width)
        pic=pic.resize((w,h),Image.Resampling.LANCZOS)
        canvas.alpha_composite(pic,(20,0))
        x=120+j*1220;y=3170+(i-1)*310
        sheet.paste(canvas.convert('RGB'),(x,y))
        D.text((x,y+241),f'Concept {i} · {lang.upper()}',font=font_small,fill=ink)
D.text((120,4130),'Generated 2026-11-05 · ©/usage: see ASSETS.md',font=font_small,fill=(95,92,87))
save_jpg(sheet,'preview/contact-sheet.jpg',89)

# Print a manifest for the metadata generator/verification.
for p in sorted(ROOT.rglob('*')):
    if p.is_file():
        print(f'{p.relative_to(ROOT)!s:58} {p.stat().st_size/1048576:6.2f} MiB')
