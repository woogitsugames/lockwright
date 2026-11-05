#!/usr/bin/env python3
"""Rebuild Lockwright G07 concept frames from the generated concept-sheet source.

Requires Pillow. Operates only in the parent G07 directory.
"""
from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageOps, ImageDraw, ImageFont, ImageFilter

BASE = Path(__file__).resolve().parents[1]
SOURCE = BASE / "source" / "concept_sheet_original.png"
OUT = BASE / "images"
OUT.mkdir(exist_ok=True)

# Sheet boundaries inspected manually; excludes every 2-4 px white divider and footer.
# xyxy pixel coordinates in the unchanged 1199x1312 source.
SCENES = [
    ("01_apartment_day.jpg", (1, 1, 259, 538), "Mieszkanie — dzień", "Apartment — day"),
    ("02_apartment_evening.jpg", (262, 1, 490, 538), "Mieszkanie — wieczór", "Apartment — evening"),
    ("03_apartment_night_timer.jpg", (494, 1, 712, 538), "Mieszkanie — noc, minutnik", "Apartment — night, timer"),
    ("04_apartment_rainy_evening.jpg", (715, 1, 966, 538), "Mieszkanie — deszczowy wieczór", "Apartment — rainy evening"),
    ("05_attic.jpg", (970, 1, 1198, 538), "Drzwi strychu", "Attic door"),
    ("06_cellar.jpg", (1, 545, 248, 1058), "Drzwi piwnicy", "Cellar door"),
    ("07_kiosk_shutter.jpg", (252, 545, 487, 1058), "Kiosk z roletą", "Kiosk shutter"),
    ("08_changing_room_locker.jpg", (491, 545, 712, 1058), "Szafka w szatni", "Changing-room locker"),
    ("09_courtyard_gate.jpg", (715, 545, 965, 1058), "Brama podwórka", "Courtyard gate"),
    ("10_workshop_door.jpg", (970, 545, 1198, 1058), "Drzwi warsztatu", "Workshop door"),
]

W, H = 1080, 2340
assert W * 19.5 == H * 9
source = Image.open(SOURCE).convert('RGB')
assert source.size == (1199, 1312), f"Unexpected source dimension {source.size}"

try:
    font_bold = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 27)
    font_small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 20)
except OSError:
    font_bold = ImageFont.load_default()
    font_small = ImageFont.load_default()

thumbs=[]
for filename, rect, pl, en in SCENES:
    crop = source.crop(rect)
    # Exact 9:19.5 image with mild side padding if needed. Never insert text into the frame.
    # Fill instead of stretch: crop at most 14% from edges, preserve architecture geometry.
    target_ratio=W/H
    original_ratio=crop.width/crop.height
    if original_ratio>target_ratio:
        desired_width=int(crop.height*target_ratio)
        l=(crop.width-desired_width)//2
        crop=crop.crop((l,0,l+desired_width,crop.height))
    else:
        desired_height=int(crop.width/target_ratio)
        # Crop a little bottom floor rather than upper door tops; keep centered slightly upward.
        cut=crop.height-desired_height
        t=max(0,int(cut*0.22))
        crop=crop.crop((0,t,crop.width,t+desired_height))
    im = crop.resize((W,H),Image.Resampling.LANCZOS)
    im=im.filter(ImageFilter.UnsharpMask(radius=1.5, percent=75, threshold=4))
    im.save(OUT/filename, quality=88, subsampling=0, optimize=True)
    thumbs.append((im.resize((265,574),Image.Resampling.LANCZOS),pl,en))

# Proof sheet with captions BELOW the scenes; no branding nor overlays on the images.
cols, rows=5,2
pad=18
thumb_w,thumb_h=265,574
label_h=74
header_h=95
bottom_h=48
PW=pad+cols*(thumb_w+pad)
PH=header_h + rows*(thumb_h+label_h+pad)+bottom_h
prev=Image.new('RGB',(PW,PH),(242,238,231))
d=ImageDraw.Draw(prev)
d.text((pad,17),'Lockwright | G07 | ARRIVAL AT THE DOOR',font=font_bold,fill=(42,38,32))
d.text((pad,54),'Arkusz podglądowy / Contact sheet   •   10 wariantów / 10 variants',font=font_small,fill=(83,78,71))
short_pl = ['Dzień', 'Wieczór', 'Noc — minutnik', 'Deszczowy wieczór', 'Strych', 'Piwnica', 'Kiosk — roleta', 'Szafka szatni', 'Brama podwórza', 'Warsztat']
short_en = ['Day', 'Evening', 'Night / timer', 'Rainy evening', 'Attic', 'Cellar', 'Kiosk / shutter', 'Changing-room locker', 'Courtyard gate', 'Workshop']
for i,(thumb,pl,en) in enumerate(thumbs):
    c=i%cols;r=i//cols
    x=pad+c*(thumb_w+pad); y=header_h+r*(thumb_h+label_h+pad)
    prev.paste(thumb,(x,y))
    d.text((x,y+thumb_h+8),f'{i+1:02d}  {short_pl[i]}',font=font_small,fill=(37,35,32))
    d.text((x+2,y+thumb_h+36),short_en[i],font=font_small,fill=(91,86,78))
prev.save(BASE/'preview.jpg',quality=91,subsampling=0,optimize=True)
print('Exported',len(SCENES),'frames',W,H,'and preview',prev.size)
for name,*_ in SCENES: print(name, (OUT/name).stat().st_size)
