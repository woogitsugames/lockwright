#!/usr/bin/env python3
"""Offline fallback renderer for GitHub-tracked G13 SVG layouts.
Produces exact raster dimensions from the repo's pre-existing stairwell art.
The separate high-resolution AI photo masters are in the user-delivered ZIP,
not in this repository. These are alternative in-repo previews.
"""
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw, ImageFont
ROOT = Path(__file__).resolve().parent
SRC = ROOT / "source" / "stairwell-render.png"
FONTS = ["/usr/share/fonts/truetype/ebgaramond/EBGaramond12-Bold.ttf",
         "/usr/share/fonts/opentype/ebgaramond/EBGaramond12-AllSC.otf"]
source = Image.open(SRC).convert("RGB")
def fsize(points):
    for f in FONTS:
        if Path(f).exists(): return ImageFont.truetype(f, points)
    raise RuntimeError("Install EB Garamond (SIL OFL 1.1) before rendering")
def export(path, width, height, title=False, language="en"):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    image = ImageOps.fit(source, (width, height), Image.Resampling.LANCZOS,
                        centering=(0.5, 0.47))
    if title:
        draw = ImageDraw.Draw(image, "RGBA")
        band_h = round(height*0.32 if height>width else height*0.68)
        draw.rectangle((0,0,width,band_h),fill=(18,15,12,115))
        font = fsize(round(width * (0.09 if width>height else 0.125)))
        draw.text((round(width*.07),round(height*.1)),"Lockwright",
                  font=font,fill=(242,231,211,255))
        if language in ("pl", "en"):
            subtitle = "Pogotowie Zamkowe" if language=="pl" else "Locksmith on Call"
            draw.text((round(width*.07),round(height*.22 if height>width else height*.18)),
                      subtitle,font=fsize(round(width*.027)),fill=(220,188,144,255))
    image.save(target,quality=91,optimize=True,subsampling=0)
for name,w,h in [("key-art/key-art-3840x2160-clean.jpg",3840,2160),
                 ("key-art/key-art-3840x2160-logo-space.jpg",3840,2160),
                 ("key-art/key-art-2160x3840-clean.jpg",2160,3840),
                 ("key-art/key-art-2160x3840-logo-space.jpg",2160,3840),
                 ("feature/google-play-1024x500-clean.jpg",1024,500),
                 ("feature/google-play-1024x500-title.jpg",1024,500)]:
    export(name,w,h,"title" in name)
for w,h in [(1080,1080),(1080,1920),(1500,500)]:
    for lang in ("pl","en"):
        export(f"social/social-{w}x{h}-{lang}.jpg",w,h,True,lang)
