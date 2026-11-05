#!/usr/bin/env python3
"""Deterministic 3-frame fictional lock tutorial illustration over AI graph paper.
Requires Pillow. The three animation cels share geometry and paper pixels.
"""
from __future__ import annotations
from pathlib import Path
from PIL import ImageCms
import math, random
from PIL import Image, ImageDraw, ImageEnhance, ImageFont

DIR=Path(__file__).resolve().parent
SRGB_ICC = ImageCms.ImageCmsProfile(ImageCms.createProfile('sRGB')).tobytes()
SIZE=1080
S=2
W=H=SIZE*S
GRAPHITE=(53,49,44)
PENCIL=(79,75,68)
PAPER=(229,212,182)
CHALK=(248,245,231)


def pt(xy): return tuple(int(round(v*S)) for v in xy)

def boxcoords(q): return tuple(int(round(v*S)) for v in q)

class Sketch:
    def __init__(self, im):
        self.im=im
        self.d=ImageDraw.Draw(im, 'RGBA')
    def line(self, points, width=2.2, alpha=180, color=PENCIL, noisy=True):
        xy=[pt(p) for p in points]
        ww=max(1,round(width*S))
        rgba=(*color,alpha)
        self.d.line(xy,fill=rgba,width=ww,joint='curve')
        if noisy and len(xy)>1:
            # offset thin graphite line: mimics loose hand overdraw, stable across frames
            xy2=[(a+S,b+round(S*.5)) for a,b in xy]
            self.d.line(xy2,fill=(*color,int(alpha*.19)),width=max(1,ww//2))
    def arc(self, bbox, start, end, width=3, alpha=180, color=PENCIL):
        self.d.arc(boxcoords(bbox),start,end, fill=(*color,alpha),width=max(1,round(width*S)))
    def ellipse(self, bbox, fill=None, outline=PENCIL, width=2.5, alpha=200):
        self.d.ellipse(boxcoords(bbox),fill=(*fill,45) if fill else None,
                       outline=(*outline,alpha) if outline else None,width=max(1,int(width*S)))
    def rect(self,bbox,r=4,fill=None,width=3,alpha=170,color=PENCIL):
        self.d.rounded_rectangle(boxcoords(bbox),radius=round(r*S),
                  fill=(*fill,30) if fill else None,outline=(*color,alpha),
                  width=max(1,int(width*S)))
    def arrow(self,start,end,double=False, color=PENCIL,alpha=215,width=3):
        self.line([start,end],width,alpha,color)
        pairs = [(start,end), (end,start)] if double else [(start,end)]
        for origin,tip in pairs:
            angle=math.atan2(tip[1]-origin[1],tip[0]-origin[0]); head=18
            a=(tip[0]-head*math.cos(angle-.52),tip[1]-head*math.sin(angle-.52))
            b=(tip[0]-head*math.cos(angle+.52),tip[1]-head*math.sin(angle+.52))
            self.line([a,tip,b],width,alpha,color)
    def thumb(self,hand,x,y):
        # Outline is a loose schematic hand gesture, no photographed person.
        direction=1 if hand=='left' else -1
        # Palm, shaft, raised thumb, two creases.
        self.rect((x-33,y+14,x+42,y+119),r=25,fill=None,width=3,alpha=130)
        self.line([(x-18,y+27),(x-19,y-23),(x-12,y-47),(x+2,y-52),
                   (x+17,y-41),(x+17,y+1)],width=5,alpha=175)
        self.arc((x-29,y+20,x+40,y+71),235,30,width=3,alpha=155)
        for shift in (70,83,96):self.line([(x-16,y+shift),(x+24,y+shift+3)],width=1.3,alpha=90)
        self.line([(x+36,y+25),(x+47,y+29),(x+42,y+51)],width=2.2,alpha=125)
        self.line([(x-36,y+40),(x-42,y+65),(x-30,y+79)],width=2,alpha=105)


def baseline(sk:Sketch, stage:int):
    # Same pencil construction in all frames. Two planes represent fictitious mechanism.
    sk.rect((233,313,850,745),r=58,fill=(136,126,109),width=5,alpha=216)
    sk.rect((258,337,827,720),r=43,fill=(177,167,148),width=2,alpha=103)
    for j in range(7):
        y=352+j*47
        sk.line([(273,y),(287,y-9)],width=1.2,alpha=63)
        sk.line([(805,y+1),(820,y-7)],width=1.2,alpha=57)
    # One single continuous core. The scratch arc below tracks core rotation.
    shift=5 if stage==3 else 0
    sk.rect((273+shift,523,811+shift,697),r=69,fill=(151,141,119),width=4,alpha=217)
    sk.arc((280+shift,521,810+shift,704),174,12,width=2,alpha=115)
    # Deep keyway represented only as an invented symbolic slot.
    sk.line([(297+shift,622),(352+shift,622),(379+shift,654)],width=9,alpha=177,color=GRAPHITE)
    sk.line([(309+shift,641),(363+shift,641)],width=3,alpha=120)
    # Three identical abstract chambers, edges below identical across frames.
    for idx,x in enumerate((395,540,685)):
        sk.rect((x-34,382,x+34,617),r=18,fill=(147,132,114),width=3.5,alpha=197)
        # Pencil spring, intentionally iconographic not dimensionally meaningful.
        turns=8
        spring=[]
        for t in range(turns+1):
            spring.append((x+(13 if t%2==0 else -13),400+t*9))
        sk.line(spring,width=2.1,alpha=145,color=(64,62,60))
        # Upper pin (top) terminates at or near division.
        selected=idx==1
        upper_end=524 if (stage!=3 or not selected) else 517
        skew=4 if (stage==1 and idx==0) else 0
        sk.rect((x-23+skew,477,x+23+skew,upper_end),r=7,fill=(80,80,76),width=3.1,alpha=210)
        # Lower pin, left in core: rises on second frame, settles on third.
        up=0 if not selected or stage==1 else (22 if stage==2 else 14)
        sk.rect((x-21,544-up,x+21,636-up),r=10,
                fill=(187,174,146),width=2.7,alpha=203)
        sk.line([(x-12,578-up),(x+11,578-up)],width=1.5,alpha=104)
    # Shear line in graphite; stronger when lift/click matters.
    sk.line([(278,522),(814,522)],width=3.1,alpha=230 if stage>=2 else 149,
            color=(40,43,43))
    # White chalk guideline, one of the game's visual affordances.
    sk.line([(281,526),(811,526)],width=1.9,alpha=184,color=CHALK)
    # Dashed register notches, no digits.
    for xx in range(360,769,40):
        sk.line([(xx,702),(xx,712+(5 if xx%80==0 else 0))],width=1.8,alpha=114)
    if stage==3:
        sk.arc((341,546,744,694),200,332,width=3.4,alpha=153,color=(61,58,51))


def tools_and_gestures(sk:Sketch,stage:int):
    # The abstract tension bar below the core stays in the same place in all cels.
    sk.line([(322,665),(359,665),(359,685),(398,685)],width=8,alpha=215,color=GRAPHITE)
    sk.line([(319,665),(318,730)],width=7,alpha=210,color=GRAPHITE)
    sk.line([(312,730),(329,730)],width=3,alpha=120)
    # Small hand at left as a visual cue. Keep scale in every frame.
    sk.thumb('left',145,652)
    if stage==1:
        sk.arrow((147,607),(147,483),alpha=221,width=3)
        sk.arc((714,591,780,658),200,342,width=4,alpha=200)
        sk.arrow((784,601),(769,584),alpha=200,width=2.3)
        # Three short binding friction marks near left chamber.
        for k in range(3):
            sk.line([(429+7*k,526-11*k),(434+7*k,519-11*k)],width=2,alpha=192)
    if stage>=2:
        # Stylised pick is shown in the invented cutaway, not a branded real tool.
        sk.line([(825,774),(758,747),(694,714),(585,683),(550,630)],
                width=6,alpha=218,color=GRAPHITE)
        sk.line([(816,774),(753,748)],width=2,alpha=106)
        sk.thumb('right',932,654)
    if stage==2:
        sk.arrow((932,600),(932,466),width=3.2)
        sk.arrow((849,899),(1006,899),double=True,width=3.2,alpha=205)
        sk.line([(531,614),(530,567)],width=2.6,alpha=230,color=CHALK)
        for k in range(4):
            sk.line([(520+k*5,531),(520+k*5,516)],width=1.1,alpha=117,color=(40,39,40))
    if stage==3:
        # Exactly three short, radial click strokes: no star, text or tick mark.
        center=(584,502)
        for angle in (-35,-5,27):
            rad=math.radians(angle)
            a=(center[0]+13*math.cos(rad),center[1]+13*math.sin(rad))
            b=(center[0]+37*math.cos(rad),center[1]+37*math.sin(rad))
            sk.line([a,b],width=4,alpha=226,color=GRAPHITE)
        sk.arc((689,567,787,660),201,335,width=4.2,alpha=204)
        sk.arrow((766,592),(785,587),width=2.4,alpha=191)
        sk.line([(513,523),(567,523)],width=4.4,alpha=204,color=CHALK)


def make_sheet(imgs:dict[str,tuple[Image.Image,Image.Image]]):
    thumb=480; cell_w=580; cell_h=585
    b=Image.new('RGB',(cell_w*3,cell_h*2+50),(223,218,208))
    d=ImageDraw.Draw(b)
    try:f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',22)
    except OSError:f=ImageFont.load_default()
    for row in range(2):
        for col,name in enumerate(imgs):
            im=imgs[name][row].copy()
            if row==1:
                # Checkerboard only for alpha previews, not for exported image.
                check=Image.new('RGBA',im.size,(245,245,241,255))
                dc=ImageDraw.Draw(check)
                for yy in range(0,1080,48):
                    for xx in range(0,1080,48):
                        if (xx//48+yy//48)%2:
                            dc.rectangle((xx,yy,xx+47,yy+47),fill=(224,223,218,255))
                check.alpha_composite(im)
                im=check.convert('RGB')
            im=im.resize((thumb,thumb),Image.Resampling.LANCZOS)
            x=col*cell_w+50;y=row*cell_h+55
            d.text((x,y-32),f'{name}'+(' (alpha)' if row else ''),font=f,fill=(52,51,46))
            b.paste(im,(x,y))
    b.save(DIR/'contact_sheet.jpg',quality=94,subsampling=0)


def main():
    paper=Image.open(DIR/'source/graph_paper_chatgpt.png').convert('RGB').resize((1080,1080),Image.Resampling.LANCZOS)
    # Same paper pixel-for-pixel under each cel. No text is included in any PNG.
    imgs={}
    for n,name in [(1,'frame_1_tension'),(2,'frame_2_lift'),(3,'frame_3_click')]:
        lay=Image.new('RGBA',(W,H),(0,0,0,0))
        sk=Sketch(lay)
        baseline(sk,n)
        tools_and_gestures(sk,n)
        lay=lay.resize((SIZE,SIZE),Image.Resampling.LANCZOS)
        lay.save(DIR/f'{name}_alpha.png',optimize=True,icc_profile=SRGB_ICC)
        bg=paper.copy().convert('RGBA')
        bg.alpha_composite(lay)
        bg.save(DIR/f'{name}.png',optimize=True,icc_profile=SRGB_ICC)
        imgs[name]=(bg,lay)
    make_sheet(imgs)
    # Deterministic pixel alignment QA; opaque outputs all same paper backdrop.
    for name,(bg,lay) in imgs.items():
        assert bg.size==lay.size==(1080,1080)
        assert bg.getpixel((0,0))[:3]==(*paper.getpixel((0,0)),)
        assert lay.getpixel((0,0))[3]==0
    print('G18 OK: 6 PNG, 1080-square; shared paper and frame geometry')

if __name__=='__main__':main()
