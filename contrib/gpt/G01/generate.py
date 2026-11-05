#!/usr/bin/env python3
"""Recreate G01 transparent plate PNGs and contact sheet from source_sheet.webp.

Requires: Pillow>=10, numpy>=1.24, opencv-python-headless>=4.8
Run inside contrib/gpt/G01: python generate.py
"""
from __future__ import annotations
from pathlib import Path
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE=Path(__file__).resolve().parent
SOURCE=HERE/'source_sheet.webp'
SIZE=1024
# Six columns by six rows; coordinates describe independent camera framing.
XS=((30,275),(279,522),(528,769),(777,1019),(1024,1269),(1272,1517))
YS=((17,174),(191,345),(363,518),(533,695),(705,859),(871,1016))
SIGN_NAMES=[
 ('administracja','pl','Administracja'),('dozorca','pl','Dozorca'),
 ('pralnia','pl','Pralnia'),('strych','pl','Strych'),
 ('piwnica','pl','Piwnica'),('warsztat_slusarski','pl','Warsztat ślusarski'),
 ('administration','en','Administration'),('caretaker','en','Caretaker'),
 ('laundry','en','Laundry'),('attic','en','Attic'),
 ('cellar','en','Cellar'),('locksmith_workshop','en','Locksmith Workshop'),
]
ENTRIES=[(f'plate_{i:02}.png',f'{i:02}',str(i)) for i in range(1,25)] + [
 (f'plate_sign_{stem}_{lang}.png',f'{label} ({lang.upper()})',label)
 for stem,lang,label in SIGN_NAMES]

def extract_one(source:np.ndarray,index:int) -> Image.Image:
    row,col=divmod(index,6)
    x0,x1=XS[col];y0,y1=YS[row]
    cell=source[y0:y1,x0:x1].copy()
    h,w=cell.shape[:2]
    # Isolate the plate, not its cast shadow or the neutral grey sheet background.
    mask=np.full((h,w),cv2.GC_PR_BGD,np.uint8)
    mask[8:-8,8:-8]=cv2.GC_PR_FGD
    mask[:7,:]=mask[-7:,:]=cv2.GC_BGD
    mask[:,:7]=mask[:,-7:]=cv2.GC_BGD
    mask[35:h-36,44:w-44]=cv2.GC_FGD
    bgd=np.zeros((1,65),np.float64)
    fgd=np.zeros((1,65),np.float64)
    cv2.grabCut(cell,mask,None,bgd,fgd,7,cv2.GC_INIT_WITH_MASK)
    raw=np.uint8(np.where((mask==cv2.GC_FGD)|(mask==cv2.GC_PR_FGD),255,0))
    raw=cv2.morphologyEx(raw,cv2.MORPH_CLOSE,np.ones((5,5),np.uint8))
    contours,_=cv2.findContours(raw,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        raise ValueError(f'No plate silhouette in cell {index+1}')
    alpha=np.zeros_like(raw)
    cv2.drawContours(alpha,[max(contours,key=cv2.contourArea)],-1,255,-1)
    # Smooth one-pixel silhouette edge only; preserve scratch and rust details.
    alpha=cv2.GaussianBlur(alpha,(3,3),0.5)
    yy,xx=np.nonzero(alpha>150)
    if len(xx)<1000:
        raise ValueError(f'Too little foreground in cell {index+1}')
    bounds=(int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1))
    rgba=Image.fromarray(np.dstack((cell,alpha)).astype('uint8'),'RGBA').crop(bounds)
    width=940
    height=round(rgba.height*width/rgba.width)
    if height>940:
        height=940;width=round(rgba.width*height/rgba.height)
    rgba=rgba.resize((width,height),Image.Resampling.LANCZOS)
    rgba=rgba.filter(ImageFilter.UnsharpMask(radius=1.15,percent=170,threshold=2))
    canvas=Image.new('RGBA',(SIZE,SIZE),(0,0,0,0))
    canvas.alpha_composite(rgba,((SIZE-width)//2,(SIZE-height)//2))
    return canvas

def font(size:int)->ImageFont.FreeTypeFont:
    for path in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
                 '/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf']:
        if Path(path).exists():return ImageFont.truetype(path,size)
    return ImageFont.load_default()

def contact(assets:list[tuple[Image.Image,str]])->Image.Image:
    columns,rows=6,6
    cellw,cellh=424,314
    canvas=Image.new('RGB',(columns*cellw,rows*cellh),(128,127,123))
    draw=ImageDraw.Draw(canvas)
    typeface=font(23)
    for i,(plate,label) in enumerate(assets):
        x=i%columns*cellw;y=i//columns*cellh
        # Checkerboard indicates actual transparency around the enamel object.
        tile=Image.new('RGBA',(cellw-18,cellh-54),(0,0,0,0))
        dt=ImageDraw.Draw(tile)
        for ky in range(0,tile.height,24):
            for kx in range(0,tile.width,24):
                color=(171,170,166,255) if (kx//24+ky//24)%2 else (194,193,189,255)
                dt.rectangle((kx,ky,kx+23,ky+23),fill=color)
        thumbnail=plate.copy()
        thumbnail.thumbnail((cellw-28,cellh-70),Image.Resampling.LANCZOS)
        tile.alpha_composite(thumbnail,((tile.width-thumbnail.width)//2,(tile.height-thumbnail.height)//2))
        canvas.paste(tile.convert('RGB'),(x+9,y+7))
        bbox=draw.textbbox((0,0),label,font=typeface)
        text_w=bbox[2]-bbox[0]
        if text_w>cellw-22:
            localfont=font(19)
            bb=draw.textbbox((0,0),label,font=localfont);text_w=bb[2]-bb[0]
        else:localfont=typeface
        draw.text((x+(cellw-text_w)//2,y+cellh-44),label,fill=(247,244,236),font=localfont)
    return canvas

def main(start=0,stop=36):
    source=np.asarray(Image.open(SOURCE).convert('RGB'))
    if source.shape[:2]!=(1024,1536):
        raise ValueError(f'Unexpected source dimensions: {source.shape[:2]}')
    result=[]
    for i in range(start,stop):
        fname,label,_=ENTRIES[i]
        plate=extract_one(source,i)
        plate.save(HERE/fname,format='PNG',compress_level=6,optimize=False)
        result.append((plate,label))
        print(fname)
    if start==0 and stop==36:
        contact(result).save(HERE/'contact_sheet.png',format='PNG',compress_level=6)
    print(f'Generated PNGs {start+1} through {stop}')

def make_contact_from_disk():
    assets=[(Image.open(HERE/f).convert('RGBA'),label) for f,label,_ in ENTRIES]
    contact(assets).save(HERE/'contact_sheet.png',format='PNG',compress_level=6)

if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser()
    p.add_argument('--start',type=int,default=0,help='zero-based first plate')
    p.add_argument('--stop',type=int,default=36,help='zero-based exclusive last plate')
    p.add_argument('--contact-only',action='store_true')
    a=p.parse_args()
    if a.contact_only: make_contact_from_disk()
    else: main(a.start,a.stop)
