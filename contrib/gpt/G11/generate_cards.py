#!/usr/bin/env python3
"""Lockwright / G11: reproduce 12 x 3 paper card assets, 2 stamps and proof sheets.

Usage: python3 generate_cards.py
Requires: cairosvg >= 2, Pillow >= 9. Uses installed Comic Neue OFL font.
All output paths are relative to this script. No network or external images.
"""
from __future__ import annotations
import io
import json
import math
import random
from pathlib import Path
from xml.sax.saxutils import escape

import cairosvg
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent
DATA = json.loads((ROOT / 'cards.json').read_text(encoding='utf-8'))
W, H = 1200, 1500
PAPER = '#f3f0e5'
INK = '#444741'
SOFT = '#80817b'
BORDER = '#d5d0c1'
HAND = 'Comic Neue'

class Sketch:
    def __init__(self, seed):
        self.r = random.Random(seed)
        self.out = []

    def add(self, s): self.out.append(s)

    def line(self, points, width=4.5, color=INK, opacity=0.86, dash=None, rough=1.5):
        pts = list(points)
        if not pts: return
        seq = [pts[0]]
        for a,b in zip(pts,pts[1:]):
            length = math.dist(a,b)
            subdivisions = max(1,int(length/26))
            for k in range(1,subdivisions+1):
                t=k/subdivisions
                jitter = 0 if k==subdivisions else rough
                seq.append((a[0]+(b[0]-a[0])*t+self.r.uniform(-jitter,jitter),
                            a[1]+(b[1]-a[1])*t+self.r.uniform(-jitter,jitter)))
        coords=' '.join(f'{x:.2f},{y:.2f}' for x,y in seq)
        d = f' stroke-dasharray="{dash}"' if dash else ''
        self.add(f'<polyline points="{coords}" fill="none" stroke="{color}" stroke-opacity="{opacity}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"{d}/>')
        if opacity >= 0.7 and width>=3 and self.r.random()<0.43:
            shifted=[(x+self.r.uniform(-2.0,2.0),y+self.r.uniform(-2.0,2.0)) for x,y in pts]
            self.line(shifted,width=.8,color=SOFT,opacity=.18,rough=1.1)

    def path(self,d,width=5,color=INK,opacity=.88,fill='none',dash=None):
        ds=f' stroke-dasharray="{dash}"' if dash else ''
        self.add(f'<path d="{d}" stroke="{color}" stroke-width="{width}" stroke-opacity="{opacity}" fill="{fill}" stroke-linejoin="round" stroke-linecap="round"{ds}/>')

    def circle(self,x,y,r,fill='none',width=4,color=INK,opacity=0.78, dash=None):
        ds=f' stroke-dasharray="{dash}"' if dash else ''
        self.add(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{color}" stroke-width="{width}" stroke-opacity="{opacity}"{ds}/>')

    def ellipse(self,x,y,rx,ry,fill='none',width=4,color=INK,opacity=.82,rotation=0,dash=None):
        ds=f' stroke-dasharray="{dash}"' if dash else ''
        self.add(f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{color}" stroke-width="{width}" stroke-opacity="{opacity}" transform="rotate({rotation} {x} {y})"{ds}/>')

    def rect(self,x,y,w,h,fill='none',width=3,color=INK,opacity=.82,rx=0,dash=None):
        ds=f' stroke-dasharray="{dash}"' if dash else ''
        self.add(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{color}" stroke-width="{width}" stroke-opacity="{opacity}"{ds}/>')

    def text(self,x,y,t,size=64,rotation=-2,color=INK,opacity=.9,anchor='start',weight='normal',style='italic',letter='0'):
        self.add(f'<text x="{x}" y="{y}" font-size="{size}" font-family="{HAND}, sans-serif" font-style="{style}" font-weight="{weight}" text-anchor="{anchor}" fill="{color}" fill-opacity="{opacity}" letter-spacing="{letter}" transform="rotate({rotation} {x} {y})">{escape(str(t))}</text>')

    def arrow(self,p1,p2,width=6,head=19,color=INK,opacity=.88,curve=None,style='line'):
        x1,y1=p1; x2,y2=p2
        if curve:
            cx,cy=curve
            self.path(f'M {x1} {y1} Q {cx} {cy} {x2} {y2}',width,color,opacity)
            dx=x2-cx;dy=y2-cy
        else:
            self.line([p1,p2],width,color,opacity)
            dx=x2-x1;dy=y2-y1
        n=math.hypot(dx,dy) or 1
        ux,uy=dx/n,dy/n
        perp=(-uy,ux)
        left=(x2-ux*head+perp[0]*head*.48,y2-uy*head+perp[1]*head*.48)
        right=(x2-ux*head-perp[0]*head*.48,y2-uy*head-perp[1]*head*.48)
        self.line([left,p2,right],width*.85,color,opacity,rough=.8)

    def hatch(self,x,y,w,h,step=19,color=SOFT,opacity=.33):
        for z in range(0,int(w+h),step):
            ax=x+max(0,z-h);ay=y+min(h,z)
            bx=x+min(w,z);by=y+max(0,z-w)
            if ax<bx and ay>by: self.line([(ax,ay),(bx,by)],1.5,color,opacity,rough=1.2)

    def thumb(self,x,y,scale=1,flip=False,ghost=False):
        """Pressed-thumb glyph: no realistic hand, only fingerprint + nail oval."""
        sign=-1 if flip else 1
        op=.27 if ghost else .84
        self.ellipse(x,y,92*scale,120*scale,fill='none',width=6,color=INK,opacity=op,rotation=sign*12)
        for j in range(8):
            rx=(76-j*8)*scale
            ry=(104-j*10)*scale
            self.ellipse(x+sign*(j%2)*3*scale,y-4*scale,rx,ry,width=2.7,color=SOFT if j>3 else INK,opacity=op*(.47 if j>3 else .56),rotation=sign*11)
        self.path(f'M {x-29*scale} {y-70*scale} Q {x} {y-94*scale} {x+34*scale} {y-62*scale}',width=2.4,color=INK,opacity=op*.56)
        self.ellipse(x,y+5*scale,111*scale,139*scale,width=1.5,color=SOFT,opacity=op*.28)

    def coil(self,cx,top,turns=4,height=80,compressed=False):
        if compressed:
            self.rect(cx-22,top,44,27,'#50504c',3,color=INK,opacity=.88,rx=3)
            for off in (-18,-8,5,15): self.line([(cx+off,top+4),(cx+off+7,top+22)],1.5,'#f2f0e5',.3)
            return
        step=height/turns
        pts=[(cx-21,top)]
        for i in range(turns):
            y=top+i*step
            pts.extend([(cx+22,y+step*.24),(cx-22,y+step*.5),(cx+22,y+step*.74),(cx-21,y+step)])
        self.line(pts,2.6,color=SOFT,opacity=.8,rough=.7)

    def column(self,cx,cy,mode='loose',scale=1,small=False):
        """Deliberately invented geometry: two-part rectangular symbol in a rectangular tube."""
        # cy = horizontal divider, no tool channel represented
        w=112*scale; h=226*scale
        x=cx-w/2;y=cy-h*.64
        self.rect(x,y,w,h,rx=8,width=3.3,opacity=.7)
        self.line([(x-20,cy),(x+w+20,cy)],width=5,color=INK,opacity=.91,rough=1)
        offset = 13*scale if mode in ('binding','near','overset') else 0
        pwidth=48*scale
        px=cx-pwidth/2+offset
        if mode=='false':
            self.path(f'M {px} {cy-78*scale} L {px+pwidth} {cy-78*scale} L {px+pwidth*.66} {cy} L {px+pwidth} {cy+79*scale} L {px} {cy+79*scale} L {px+pwidth*.34} {cy} Z',2.8,fill='#a9a8a0',opacity=.64,dash='9 7')
        else:
            top=cy-91*scale if mode in ('set','open') else cy-76*scale
            lower=cy+61*scale if mode!='overset' else cy-14*scale
            # upper element
            self.rect(px,top,pwidth,62*scale,fill='#c6c5ba',rx=2,width=3,opacity=.82)
            self.hatch(px+4,top+3,pwidth-8,21*scale,16,opacity=.16)
            if mode in ('set','open'):
                self.line([(px-9*scale,cy-11*scale),(px+pwidth+9*scale,cy-11*scale)],5.3)
            # lower element
            self.rect(px,lower,pwidth,31*scale if mode=='overset' else 65*scale,fill='#d5d5cb',rx=2,width=3,opacity=.85)
        if mode=='binding':
            for i in range(3):
                self.line([(x+w-8*scale,cy-22*scale+i*16*scale),(x+w+19*scale,cy-10*scale+i*16*scale)],4.2,color=INK,opacity=.8)
        if mode=='near':
            # paired opposing wedges, narrow aperture
            self.path(f'M {cx-40*scale} {cy-11*scale} L {cx-11*scale} {cy-3*scale} L {cx-40*scale} {cy+10*scale} Z',1.4,fill='#696a62',opacity=.72)
            self.path(f'M {cx+41*scale} {cy-11*scale} L {cx+12*scale} {cy-3*scale} L {cx+41*scale} {cy+10*scale} Z',1.4,fill='#696a62',opacity=.72)
        if mode=='overset':
            self.coil(cx,top=cy-123*scale,compressed=True)
            self.line([(cx-40*scale,cy-136*scale),(cx+40*scale,cy-136*scale)],width=5.5)
            self.line([(cx-40*scale,cy-146*scale),(cx-40*scale,cy-128*scale)],width=4.5)
            self.line([(cx+40*scale,cy-146*scale),(cx+40*scale,cy-128*scale)],width=4.5)
        elif mode not in ('open','set'):
            self.coil(cx,top=cy-133*scale,height=47*scale,turns=3)
        if mode=='bounce':
            self.arrow((cx,cy+170*scale),(cx,cy+126*scale),3,13,color=SOFT,opacity=.55)
            self.path(f'M {cx-30*scale} {cy+130*scale} Q {cx} {cy+103*scale} {cx+30*scale} {cy+130*scale}',3,SOFT,.48)

    def dial(self,cx,cy,r=108,rotation=0,steps=12,active=1):
        self.circle(cx,cy,r,fill='#f2f1e8',width=5,opacity=.82)
        self.circle(cx,cy,r*.70,width=2.5,color=SOFT,opacity=.68)
        for i in range(steps):
            theta=-math.pi/2 + (i+rotation)*2*math.pi/steps
            r1=r*.75;r2=r*(.94 if i%3==0 else .88)
            self.line([(cx+math.cos(theta)*r1,cy+math.sin(theta)*r1),(cx+math.cos(theta)*r2,cy+math.sin(theta)*r2)],width=3 if i%3 else 5,opacity=.65,rough=.2)
        a=-math.pi/2+(rotation+active)*2*math.pi/steps
        self.line([(cx,cy),(cx+math.cos(a)*r*.60,cy+math.sin(a)*r*.60)],width=6)
        self.circle(cx,cy,8,fill=INK,width=1)

    def tube_row(self, centers, cy, modes, scale=.65):
        for x,m in zip(centers,modes): self.column(x,cy,m,scale)


def paper_background(s,card):
    s.add('<defs><clipPath id="clipPaper"><path d="M 114 124 L 201 119 L 328 125 L 446 122 L 573 119 L 695 123 L 817 119 L 944 124 L 1089 119 L 1090 1396 L 1013 1400 L 889 1396 L 742 1401 L 610 1397 L 463 1401 L 310 1398 L 205 1402 L 111 1397 Z"/></clipPath></defs>')
    path='M 114 124 L 201 119 L 328 125 L 446 122 L 573 119 L 695 123 L 817 119 L 944 124 L 1089 119 L 1090 1396 L 1013 1400 L 889 1396 L 742 1401 L 610 1397 L 463 1401 L 310 1398 L 205 1402 L 111 1397 Z'
    s.add(f'<path d="{path}" transform="translate(11 15)" fill="#44463d" fill-opacity=".12"/>')
    s.add(f'<path d="{path}" fill="{PAPER}" stroke="{BORDER}" stroke-width="3.6"/>')
    s.add('<g clip-path="url(#clipPaper)">')
    # paper pulp fibers: sparse, subtle, hand made, not photographic stock texture
    for j in range(640):
        x=s.r.uniform(114,1090); y=s.r.uniform(123,1397)
        ln=s.r.uniform(3,16)
        op=s.r.uniform(.025,.095)
        s.add(f'<path d="M {x:.1f} {y:.1f} l {ln:.1f} {s.r.uniform(-3,2):.1f}" stroke="#68685f" stroke-opacity="{op:.3f}" stroke-width="{s.r.uniform(.5,1.2):.2f}" stroke-linecap="round"/>')
    # light crumples and unequal corners
    s.path('M 113 295 Q 157 282 192 299 T 282 286',2.0,'#79776d',.16)
    s.path('M 940 118 Q 945 190 990 225 Q 1034 256 1086 244',2.4,'#6a655c',.15)
    s.path('M 106 1155 Q 154 1171 206 1142',1.8,'#8c887c',.22)
    s.path('M 798 1394 Q 843 1361 905 1375',2.2,'#9c9687',.16)
    s.path('M 161 125 Q 179 165 165 198',2,'#b1a99b',.32)
    s.path('M 1050 125 Q 1039 162 1051 182',2,'#b1a99b',.32)
    # notepad fibers near top
    for i in range(11):
        x=235+i*72
        s.line([(x,124),(x+s.r.uniform(-4,4),144)],1.5,'#b3aa99',.45,rough=.8)
    s.add('</g>')
    # round dark hole with subtle washer / pushed-through pin
    s.ellipse(610,195,26,12,fill='#696b5e',width=2,color='#d7c9a7',opacity=.28)
    s.circle(600,182,20,fill='#777a74',width=3,color='#555a56',opacity=.78)
    s.circle(592,176,6,fill='#e0dbcb',width=0,color='#e0dbcb',opacity=.85)
    s.line([(175,311),(1025,311)],width=1.6,color=SOFT,opacity=.18,rough=3)
    s.text(178,270,card['id'],55,rotation=-3,color=INK,opacity=.66)
    s.text(1017,270,card['stage'],41,rotation=2,color=SOFT,opacity=.65,anchor='end')
    # Note area: graphite pencil rule; exists in clean variant as if waiting for a note
    s.line([(196,1122),(996,1120)],width=2.1,color=SOFT,opacity=.31,rough=2)
    s.line([(196,1349),(1001,1349)],width=1.6,color=SOFT,opacity=.16,rough=2)


def draw_card(s, key):
    if key=='steady_pressure':
        s.thumb(382,703,1.65)
        s.arrow((630,918),(630,480),8,27,curve=(670,692))
        # strength ruler (in the game, not a real-world tool)
        s.line([(822,980),(822,435)],width=8,opacity=.65)
        for j in range(11):
            y=980-j*54.5
            s.line([(815,y),(835+(15 if j%5==0 else 0),y)],width=3.2,opacity=.61)
        s.rect(797,767,50,194,fill='#8d8d83',width=1,color=SOFT,opacity=.4,rx=3)
        s.line([(779,760),(862,760)],width=8)
        s.text(856,1001,'0',35,rotation=0,opacity=.6)
        s.text(854,411,'100%',35,rotation=0,opacity=.6)
        s.ellipse(381,702,160,199,width=2,color=SOFT,opacity=.29)
    elif key=='binding':
        s.column(395,700,'loose',1.18)
        s.arrow((560,690),(676,690),7,26)
        s.column(809,700,'binding',1.18)
        s.path('M 318 928 Q 397 956 473 932',3.6,SOFT,.36)
        s.path('M 733 929 Q 808 962 894 926',3.5,INK,.49)
        s.circle(806,975,9,fill='#8b8a7f',width=0,opacity=.6)
    elif key=='right_thumb':
        s.thumb(333,860,1.18,flip=True)
        s.circle(326,858,158,width=3,color=SOFT,opacity=.32,dash='7 14')
        s.path('M 460 892 L 760 892 L 760 468',9,INK,.85)
        s.arrow((460,892),(746,892),width=6.2,head=19)
        s.arrow((760,685),(760,469),width=8,head=27)
        s.circle(760,470,32,width=3,opacity=.62)
        s.circle(755,903,28,width=2,color=SOFT,opacity=.42,dash='6 8')
        # tactile ruled track
        for k in range(7): s.line([(513+k*48,939),(513+k*48,960)],2.5,SOFT,.35)
    elif key=='near_shear':
        s.column(397,721,'binding',1.09)
        s.column(805,721,'near',1.09)
        s.arrow((543,721),(659,721),7.5,22)
        # magnified gap symbol left and right bottom
        s.path('M 309 1000 L 396 960 L 479 1000 Z',4,SOFT,.55)
        s.path('M 760 997 L 801 982 L 850 997 Z',4,INK,.69)
        s.line([(716,1041),(905,1041)],2,SOFT,.23)
    elif key=='set':
        s.column(425,690,'set',1.25)
        s.path('M 380 908 Q 422 883 469 908',4,SOFT,.5)
        s.arrow((585,706),(668,706),6.2,23)
        s.dial(840,690,130,rotation=0,steps=12,active=1)
        s.path('M 785 551 Q 854 502 922 546',5,SOFT,.59)
        for x in (895,927,956): s.line([(x,498),(x+15,473)],4.5,INK,.45)
        s.line([(725,922),(953,920)],2.7,SOFT,.28)
    elif key=='open':
        for x in (327,474,621):
            s.circle(x,473,35,fill='#cdccc1',width=4,opacity=.7)
            s.line([(x-15,473),(x+15,473)],5,INK,.68)
        s.path('M 285 544 Q 467 590 659 544',4.3,SOFT,.55)
        s.arrow((696,544),(785,544),6.4,21)
        s.dial(862,760,160,rotation=2,steps=12,active=3)
        s.arrow((752,963),(999,959),7.0,26,curve=(886,1072))
        s.rect(216,823,327,67,fill='#d5d4cb',rx=7,width=3,color=INK,opacity=.74)
        s.arrow((270,852),(494,852),6,24)
    elif key=='find_binding':
        s.tube_row([350,596,843],680,['bounce','bounce','binding'],scale=1.08)
        for x in (351,596):
            s.arrow((x-37,929),(x-38,861),3.2,13,color=SOFT,opacity=.5)
        s.ellipse(848,695,120,224,width=2.8,color=INK,opacity=.55,dash='11 12')
        s.arrow((848,1019),(848,936),5,18,color=INK,opacity=.75)
    elif key=='sequence':
        # storyboard strips of 1, 2, 3 foot markers above the same common line
        for idx,y in enumerate((488,730,970)):
            s.rect(225,y-75,755,155,fill='none',width=2,color=SOFT,opacity=.32,rx=12)
            s.line([(282,y+17),(917,y+17)],5,INK,.7)
            for n,x in enumerate((420,600,780)):
                if n<=idx:
                    s.rect(x-31,y-48,62,53,fill='#c9c8bc',width=3.0,rx=3)
                    s.line([(x-47,y+7),(x+47,y+7)],5)
                else:
                    s.rect(x-31,y-13,62,73,fill='none',width=2.7,color=SOFT,opacity=.47,rx=3,dash='8 8')
            if idx<2: s.arrow((601,y+103),(601,y+148),5,14,color=SOFT,opacity=.62)
        s.circle(987,1005,11,fill=INK,width=0,opacity=.7)
    elif key=='gentle_drop':
        s.thumb(295,542,0.89)
        s.arrow((294,657),(294,785),5.8,22,opacity=.73)
        s.ellipse(294,550,118,154,width=2.8,color=SOFT,opacity=.34,dash='8 12')
        s.tube_row([503,716,928],748,['set','set','loose'],scale=.79)
        s.rect(912,789,25,41,fill='#c3c2ba',width=0,opacity=.22)
        s.arrow((927,839),(927,992),6,23,color=INK,opacity=.78)
        s.line([(455,1047),(746,1047)],3,SOFT,.32)
    elif key=='rear_first':
        s.tube_row([331,612,890],735,['loose','loose','binding'],scale=.92)
        for n,(x,y) in enumerate(((889,458),(331,458),(612,458)),1):
            s.circle(x,y,43,fill='#eeece2',width=5,opacity=.8)
            s.text(x,y+20,n,54,anchor='middle',rotation=0,opacity=.78)
        s.arrow((839,403),(373,397),5.4,20,color=INK,opacity=.73,curve=(598,290))
        s.arrow((368,383),(580,393),5.4,20,color=INK,opacity=.73,curve=(467,360))
        s.line([(331,920),(331,952),(613,952),(613,920)],3.2,SOFT,.38,rough=2)
    elif key=='overset':
        s.column(430,740,'overset',1.35)
        s.ellipse(433,744,159,250,width=3,color=SOFT,opacity=.42,dash='11 14')
        s.arrow((659,831),(729,831),6.7,21)
        s.circle(856,735,134,fill='none',width=11,color=INK,opacity=.77)
        s.line([(958,838),(1046,926)],width=20,color=INK,opacity=.8,rough=1)
        s.circle(857,735,102,width=3,color=SOFT,opacity=.49)
        # inside magnifying-glass lens a larger abstract pin with crossed boundary
        s.line([(789,744),(926,744)],4.3,color=INK,opacity=.83)
        s.rect(823,670,63,116,fill='#bbbcb0',width=4,rx=4)
        s.hatch(824,674,61,33,13,color=INK,opacity=.2)
        s.path('M 798 629 L 798 651 L 916 651 L 916 629',5,INK,.72)
    elif key=='reset':
        s.thumb(320,569,1.04)
        s.arrow((326,714),(326,931),7,29)
        for x,dy in ((572,0),(755,42),(937,85)):
            s.rect(x-41,510+dy,82,100,fill='#c1c1b8',width=3.5,rx=4)
            s.line([(x-75,668+dy),(x+75,668+dy)],5,INK,.7)
            s.arrow((x,696+dy),(x,764+dy),4,15,color=SOFT,opacity=.73)
        s.dial(758,1000,89,rotation=0,steps=10,active=0)
        s.arrow((849,1007),(792,1090),4.4,15,color=INK,opacity=.57,curve=(890,1082))
    else: raise ValueError(key)


def build_card(card,locale):
    s=Sketch(2900+int(card['id']))
    paper_background(s,card)
    draw_card(s,card['key'])
    if locale != 'clean':
        # note area always separate from the diagram: diegetic paper, no UI overlay
        a,b=card[locale]
        size=67
        # English can be long; fit to 32ish characters per line
        if max(len(a),len(b))>27: size=56
        if max(len(a),len(b))>33: size=51
        s.text(201,1228,a,size,rotation=-2.2,opacity=.91)
        s.text(204,1320,b,size,rotation=-1.4,opacity=.91)
    source=f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<title>G11 / {card['id']} / {locale}</title>
<desc>{escape(card['alt_en'] if locale=='en' else card['alt_pl'])}</desc>
{''.join(s.out)}
</svg>'''
    outsvg=ROOT/'svg'/f'g11-{card["id"]}-{locale}.svg'
    outpng=ROOT/'png'/f'g11-{card["id"]}-{locale}.png'
    outsvg.write_text(source,encoding='utf-8')
    cairosvg.svg2png(bytestring=source.encode('utf-8'),write_to=str(outpng),output_width=W,output_height=H)
    return outpng


def stamp(locale):
    # loose, partially uneven ink impression on transparent canvas; legible at small scale
    s=Sketch(1100 if locale=='pl' else 2200)
    line1, line2=(('TO GRA, NIE KURS.','Mechanizmy są wymyślone.') if locale=='pl' else
                  ('THIS IS A GAME, NOT A COURSE.','The mechanisms are invented.'))
    # scale long English line to avoid overruns while preserving proportions
    fs1=53 if locale=='pl' else 43
    fs2=45 if locale=='pl' else 44
    s.add('<g transform="rotate(-2 600 770)">')
    s.rect(133,593,934,342,'none',9,'#6f4742',.88,rx=11)
    s.rect(149,608,901,310,'none',2.5,'#6f4742',.53,rx=8)
    for y in (620,909):
        for _ in range(28):
            x=s.r.uniform(157,1042)
            s.line([(x,y+s.r.uniform(-4,4)),(x+s.r.uniform(2,8),y+s.r.uniform(-5,5))],s.r.uniform(.5,2),'#6f4742',s.r.uniform(.2,.48),rough=.5)
    s.text(599,738,line1,fs1,rotation=0,color='#6f4742',opacity=.86,anchor='middle',weight='bold',style='normal')
    s.text(599,830,line2,fs2,rotation=0,color='#6f4742',opacity=.83,anchor='middle',weight='bold',style='normal')
    # random flyspecks around stamp only (not over letters)
    for _ in range(155):
        x=s.r.uniform(132,1060); y=s.r.uniform(593,937)
        if 641 < y < 881 and 190 < x < 1005: continue
        s.circle(round(x,1),round(y,1),round(s.r.uniform(.7,1.9),1),fill='#654b44',width=0,opacity=round(s.r.uniform(.04,.16),2))
    s.add('</g>')
    source=f'<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1500" viewBox="0 0 1200 1500"><title>Stamp {locale.upper()}</title>{"".join(s.out)}</svg>'
    (ROOT/'stamps'/f'g11-stamp-{locale}.svg').write_text(source,encoding='utf-8')
    path=ROOT/'stamps'/f'g11-stamp-{locale}.png'
    cairosvg.svg2png(bytestring=source.encode(),write_to=str(path),output_width=W,output_height=H)
    return path


def make_contact(paths):
    """PL proof + full variant audit sheet, all generated locally."""
    cols,rows=4,3
    tw,th=255,318
    pad=28
    bg=Image.new('RGB',(cols*tw+(cols+1)*pad,rows*th+(rows+1)*pad+120),'#e4e3dd')
    d=ImageDraw.Draw(bg)
    for i,c in enumerate(DATA):
        im=Image.open(ROOT/'png'/f'g11-{c["id"]}-pl.png').convert('RGBA')
        im.thumbnail((tw,th-44),Image.Resampling.LANCZOS)
        x=pad+(i%4)*(tw+pad);y=pad+(i//4)*(th+pad)
        bg.paste(im,(x+(tw-im.width)//2,y),im)
        d.text((x+11,y+th-39),f'{c["id"]}  {c["stage"]} / {c["key"]}',fill='#33332e')
    d.text((pad,bg.height-61),'LOCKWRIGHT / G11   |   MASTER TUTORIAL NOTES   |   PL PREVIEW',fill='#383932')
    bg.save(ROOT/'sheets'/'g11-contact-sheet-pl.png',optimize=True)

    cw,ch=185,255
    pad=17
    variants=('pl','en','clean')
    out=Image.new('RGB',(6*(cw+pad)+pad,6*(ch+pad)+pad+72),'#e7e5e0')
    od=ImageDraw.Draw(out)
    for i,card in enumerate(DATA):
        row=i//2;half=(i%2)*3
        for j,v in enumerate(variants):
            col=half+j;x=pad+col*(cw+pad);y=pad+row*(ch+pad)
            im=Image.open(ROOT/'png'/f'g11-{card["id"]}-{v}.png').convert('RGBA')
            im.thumbnail((cw,ch-25),Image.Resampling.LANCZOS)
            out.paste(im,(x+(cw-im.width)//2,y),im)
            od.text((x+7,y+ch-23),f'{card["id"]} / {v.upper()}',fill='#3a3b37')
    od.text((pad,out.height-48),'G11   /   ALL 36 VARIANTS   /   PL · EN · CLEAN',fill='#41413c')
    out.save(ROOT/'sheets'/'g11-contact-sheet-all-variants.png',optimize=True)


def main():
    for name in ('png','svg','stamps','sheets'):(ROOT/name).mkdir(exist_ok=True)
    paths=[]
    for card in DATA:
        for variant in ('pl','en','clean'):
            paths.append(build_card(card,variant))
    for locale in ('pl','en'):paths.append(stamp(locale))
    make_contact(paths)
    # automatic asset QA, not a replacement for independent newcomer test
    assert len(DATA)==12
    assert len(list((ROOT/'png').glob('*.png')))==36
    for p in paths:
        im=Image.open(p)
        assert im.size==(1200,1500) and im.mode=='RGBA', (p,im.size,im.mode)
        assert im.getpixel((0,0))[3]==0, p
        assert p.stat().st_size < 20_000_000, p
    print(f'Generated {len(paths)} transparent PNGs, 38 SVGs and 2 proof sheets.')
    for p in paths: print(p.relative_to(ROOT),p.stat().st_size)

if __name__=='__main__': main()
