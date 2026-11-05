#!/usr/bin/env python3
"""Re-export ten 9:19.5 WebP concept frames from the G07 AI contact sheet.

Requirements: Python 3.10+, Pillow. Writes only inside contrib/gpt/G07/.
"""
from pathlib import Path
from PIL import Image, ImageFilter

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'source'/'concept_sheet_source.webp'
DEST=ROOT/'images'
W,H=1080,2340
RECTS=[
    ('01_apartment_day', (1,1,259,538)),
    ('02_apartment_evening',(262,1,490,538)),
    ('03_apartment_night_timer',(494,1,712,538)),
    ('04_apartment_rainy_evening',(715,1,966,538)),
    ('05_attic',(970,1,1198,538)),
    ('06_cellar',(1,545,248,1058)),
    ('07_kiosk_shutter',(252,545,487,1058)),
    ('08_changing_room_locker',(491,545,712,1058)),
    ('09_courtyard_gate',(715,545,965,1058)),
    ('10_workshop_door',(970,545,1198,1058)),
]

def crop_image(src, rect):
    region=src.crop(rect)
    aspect=W/H
    if region.width/region.height>aspect:
        desired=int(region.height*aspect)
        x=(region.width-desired)//2
        region=region.crop((x,0,x+desired,region.height))
    else:
        desired=int(region.width/aspect)
        y=max(0,int((region.height-desired)*0.22))
        region=region.crop((0,y,region.width,y+desired))
    return region.resize((W,H),Image.Resampling.LANCZOS).filter(ImageFilter.UnsharpMask(1.5,75,4))

def main():
    src=Image.open(SOURCE).convert('RGB')
    if src.size!=(1199,1312):
        raise ValueError('Unexpected contact sheet dimensions')
    DEST.mkdir(exist_ok=True)
    for name,coords in RECTS:
        crop_image(src,coords).save(DEST/f'{name}.webp',format='WEBP',quality=70,method=6)
    print('Rebuilt 10 WebP images 1080 x 2340. The preview is a separately composed derivative.')

if __name__=='__main__':
    main()
