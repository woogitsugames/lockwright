#!/usr/bin/env python3
"""Lockwright G12 — procedurally generated, original mobile app icon proposals.

Renders iOS 1024x1024, size-strip previews, Android adaptive layers, and a
bilingual contact sheet. No source photos, logos, brands or real hardware plans.

Run: python3 generate_icons.py
Dependencies: Pillow>=10, numpy>=1.24
"""
from __future__ import annotations

from pathlib import Path
import math
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops, ImageOps

ROOT = Path(__file__).resolve().parent
SIZE = 1024
DATE = '2026-11-05'
FONT_SERIF = '/usr/share/fonts/truetype/noto/NotoSerif-Bold.ttf'
FONT_SANS = '/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf'
FONT_SANS_BOLD = '/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf'
SEEDS = [1301,1477,1511,1613,1741,1823,1973,2111,2213,2341,2473,2593]

DESIGNS = [
    ('01','enamel_l','Tabliczka emaliowana „L”','Enamel L plate','ivory enamel, navy serif L, worn dark-blue edge, four old screws','navy'),
    ('02','brass_cylinder','Czoło wkładki','Brass cylinder face','satiny brass concentric face, imagined geometric central slot, wood','wood'),
    ('03','leather_roll','Zwijka skórzana','Closed leather tool roll','closed brown leather roll, neat stitching, large brass snap','linen'),
    ('04','old_key','Stary klucz','Old key','single silver antique invented key lying diagonally on leather','leather'),
    ('05','doorbell','Dzwonek do mieszkania','Apartment doorbell','big ivory pushbutton and patinated brass bezel on green wood','green'),
    ('06','number_plate','Tabliczka z numerem 12','Number 12 plate','cream ceramic 12 plate with navy border and screws on green paint','green'),
    ('07','dial_cylinder','Wkładka z podziałką','Cylinder and dial','brass cylinder inside scaled industrial brass faceplate','plaster'),
    ('08','tenement_door','Drzwi kamienicy','Tenement door','solid old oak door with inlaid panels and warm transom light','plaster'),
    ('09','door_handle','Klamka z szyldem','Door handle and plate','large curved worn brass door handle on oak door','wood'),
    ('10','workshop_lamp','Lampa warsztatowa','Workshop lamp','dark green anglepoise lamp shining on quiet timber workbench','workshop'),
    ('11','key_ring','Pęk kluczy','Keys on a ring','large ring and three distinct invented steel and brass keys','leather'),
    ('12','facade','Fasada kamienicy','Tenement facade','close-up of cream tenement bay with sage window and stone cornice','daylight'),
]

# Procedural texture system: deterministic multiscale pigment/noise, shaded without
# any photographic input. A single subtle warm key light comes from upper left.
BG_COLORS = {
    'navy':(31,52,69), 'wood':(98,60,35), 'linen':(174,161,137),
    'leather':(96,57,37), 'green':(64,91,69), 'plaster':(184,165,136),
    'workshop':(50,66,63), 'daylight':(157,169,161),
}


def font(path,size):
    try: return ImageFont.truetype(path,size)
    except OSError: return ImageFont.load_default()


def multiscale_noise(w,h,seed):
    rng = np.random.default_rng(seed)
    out=np.zeros((h,w),dtype=np.float32)
    for sc,weight in [(16,11.5),(64,4.3),(256,1.6)]:
        ww=max(2,math.ceil(w/sc)); hh=max(2,math.ceil(h/sc))
        v=rng.normal(0,1,(hh,ww)).astype(np.float32)
        im=Image.fromarray(v,'F').resize((w,h),Image.Resampling.BICUBIC)
        out += np.asarray(im,dtype=np.float32)*weight
    out += rng.normal(0,1,(h,w)).astype(np.float32)*1.5
    return out


def texture(kind,w,h,seed):
    base=BG_COLORS.get(kind,(135,111,80))
    noise=multiscale_noise(w,h,seed)
    yy,xx=np.mgrid[:h,:w].astype(np.float32)
    lit=7.0*(1-(xx/w+yy/h)*.58)
    if kind in ('wood','leather','workshop'):
        grain=3.4*np.sin(xx/11.0+2.9*np.sin(yy/160))+2.0*np.sin(xx/29+yy/110)
        if kind=='leather': grain=1.9*np.sin(yy/8+xx/23)
        noise+=grain
    if kind=='green':
        # old painted vertical panelling under a soft east-facing window
        noise+=1.3*np.sin(xx/22)
    if kind=='daylight':
        lit += 5.4*(xx/w)
    out=np.empty((h,w,3),dtype=np.uint8)
    for ch in range(3):
        sh=noise*(0.72+ch*.11)+lit*(1 if ch!=2 else .78)
        if kind=='navy' and ch==2: sh+=4
        out[:,:,ch]=np.clip(base[ch]+sh,0,255).astype(np.uint8)
    return Image.fromarray(out,'RGB')


def bg_art(kind,seed,size=SIZE):
    img=texture(kind,size,size,seed)
    d=ImageDraw.Draw(img,'RGBA'); S=size/1024
    def P(n):return round(n*S)
    if kind in ('wood','leather','workshop'):
        for x in (85,341,590,846):
            cx=P(x)
            d.line([(cx,0),(cx,size)],fill=(23,20,16,24),width=max(1,P(3)))
            d.line([(cx+P(5),0),(cx+P(5),size)],fill=(255,237,188,15),width=max(1,P(2)))
    if kind=='green':
        for x in (188,570,927):
            cx=P(x)
            d.line([(cx,0),(cx,size)],fill=(15,44,36,48),width=max(1,P(6)))
            d.line([(cx+P(9),0),(cx+P(9),size)],fill=(230,236,203,28),width=max(1,P(3)))
        # trim line on the old wainscot
        d.line([(0,P(128)),(size,P(128))],fill=(202,203,158,29),width=max(1,P(8)))
    if kind=='plaster':
        for i in range(75):
            r=random.Random(seed+i*53)
            x,y=r.randrange(size),r.randrange(size)
            d.ellipse((x,y,x+P(1),y+P(1)),fill=(70,69,55,30))
    if kind=='daylight':
        d.rectangle((0,0,size,P(225)),fill=(194,209,204,160))
    return img


def ellipse_mask(box,sz=SIZE):
    m=Image.new('L',(sz,sz)); ImageDraw.Draw(m).ellipse(box,fill=255); return m


def rounded_mask(box,radius,sz=SIZE):
    m=Image.new('L',(sz,sz)); ImageDraw.Draw(m).rounded_rectangle(box,radius=radius,fill=255);return m


def polygon_mask(pts,sz=SIZE):
    m=Image.new('L',(sz,sz));ImageDraw.Draw(m).polygon(pts,fill=255);return m


def shadow(img,mask,blur=30,dy=21,dx=14,opacity=130):
    a=Image.new('RGBA',img.size,(0,0,0,0));
    m=ImageChops.offset(mask,dx,dy).filter(ImageFilter.GaussianBlur(blur))
    m=m.point(lambda p:p*opacity//255)
    a.paste((13,12,8,255),(0,0,img.width,img.height),m)
    img.alpha_composite(a)


def fill(img,mask,col,grained=False,seed=0):
    if grained:
        w,h=img.size
        rng=np.random.default_rng(seed)
        yy,xx=np.mgrid[:h,:w]
        noise=multiscale_noise(w,h,seed)
        sheen=(1-xx/w)*13+(1-yy/h)*7
        a=np.zeros((h,w,4),dtype=np.uint8)
        for q in range(3): a[:,:,q]=np.clip(col[q]+noise*(.55+q*.08)+sheen,0,255).astype(np.uint8)
        a[:,:,3]=255
        stamp=Image.fromarray(a,'RGBA')
    else:stamp=Image.new('RGBA',img.size,(*col,255))
    img.paste(stamp,(0,0),mask)


def high_light(draw,box,radius=0):
    draw.rounded_rectangle(box,radius=radius,outline=(255,241,195,80),width=5)


def screw(d,x,y,r=18):
    d.ellipse((x-r,y-r,x+r,y+r),fill=(70,57,32,255),outline=(244,218,154,210),width=3)
    d.ellipse((x-r+4,y-r+4,x+r-4,y+r-4),fill=(139,113,65,255))
    d.line((x-r*.49,y-r*.16,x+r*.49,y+r*.16),fill=(41,41,32,235),width=5)
    d.line((x-r*.46,y-r*.23,x+r*.46,y+r*.08),fill=(224,189,117,118),width=2)


def ring(d,cx,cy,r,width=22,col=(164,113,48,255),hilight=True):
    d.ellipse((cx-r,cy-r,cx+r,cy+r),outline=(52,42,26,255),width=width+13)
    d.ellipse((cx-r+4,cy-r+4,cx+r-4,cy+r-4),outline=col,width=width)
    if hilight:
        d.arc((cx-r+5,cy-r+5,cx+r-5,cy+r-5),185,317,fill=(254,219,150,205),width=max(3,width//3))
        d.arc((cx-r+7,cy-r+7,cx+r-7,cy+r-7),5,129,fill=(65,57,37,170),width=max(3,width//4))


def wood_panels(d):
    d.rounded_rectangle((132,126,892,930),radius=23,fill=(72,43,24,255),outline=(183,125,67,255),width=12)
    d.rounded_rectangle((181,154,848,887),radius=18,outline=(32,23,19,170),width=11)
    for box in [(210,203,483,492),(540,203,813,492),(210,545,483,840),(540,545,813,840)]:
        d.rounded_rectangle(box,radius=14,outline=(159,109,59,225),width=21)
        x1,y1,x2,y2=box
        d.line([(x1+21,y1+23),(x2-21,y1+23)],fill=(225,163,88,115),width=6)
        d.line([(x1+21,y2-25),(x2-21,y2-25)],fill=(28,19,17,115),width=7)


def antique_key(d,angle=0,offset=(0,0),scale=1,col=(177,164,137,255)):
    # Original fictional silhouette, not based on a manufacturer's key blank.
    ox,oy=offset
    def Q(x,y):return (int(ox+x*scale),int(oy+y*scale))
    r=70*scale
    cc=Q(0,0)
    d.ellipse((cc[0]-r,cc[1]-r,cc[0]+r,cc[1]+r),fill=(84,71,53,255),outline=(230,222,199,255),width=max(3,round(9*scale)))
    ir=41*scale
    d.ellipse((cc[0]-ir,cc[1]-ir,cc[0]+ir,cc[1]+ir),fill=(0,0,0,0)) # transparent cutout re-filled below in subject layer
    d.rounded_rectangle((*Q(-25,60),*Q(25,340)),radius=max(3,round(12*scale)),fill=col,outline=(65,60,48,190),width=max(2,round(5*scale)))
    d.polygon([Q(-25,310),Q(69,310),Q(69,355),Q(37,355),Q(37,384),Q(1,384),Q(1,362),Q(-25,362)],fill=col)
    d.line([Q(-12,79),Q(-12,315)],fill=(251,235,200,120),width=max(2,round(6*scale)))


def badge_L(subj):
    shadow(subj,rounded_mask((159,126,871,899),61),35,29,13,150)
    d=ImageDraw.Draw(subj,'RGBA')
    d.rounded_rectangle((165,125,861,897),radius=62,fill=(30,47,56,255),outline=(5,21,32,255),width=16)
    d.rounded_rectangle((202,158,824,857),radius=50,fill=(174,159,130,255),outline=(155,98,54,245),width=11)
    d.rounded_rectangle((225,182,800,832),radius=39,fill=(234,221,189,255),outline=(11,48,67,255),width=17)
    d.rounded_rectangle((242,199,783,816),radius=26,outline=(253,248,226,140),width=5)
    for (x,y) in ((239,206),(784,206),(239,813),(784,813)):screw(d,x,y,19)
    # chips reveal oxidized dark base; balanced small details are subordinate to L
    rng=random.Random(1301)
    for _ in range(33):
        x=rng.choice([r for r in range(215,800) if r<265 or r>750]);y=rng.randrange(207,812)
        d.ellipse((x,y,x+rng.randrange(6,16),y+rng.randrange(4,13)),fill=(129,111,90,115))
    f=font(FONT_SERIF,510)
    box=d.textbbox((0,0),'L',font=f)
    x=round((1024-(box[2]-box[0]))/2)-box[0];y=round((1024-(box[3]-box[1]))/2)-box[1]-12
    d.text((x+5,y+7),'L',font=f,fill=(39,55,66,75));d.text((x,y),'L',font=f,fill=(26,54,74,255),stroke_width=1,stroke_fill=(31,43,55,255))


def cylinder(subj,scaled=False):
    shadow(subj,ellipse_mask((155,147,868,862)),39,30,12,180)
    d=ImageDraw.Draw(subj,'RGBA')
    if scaled:
        d.rounded_rectangle((115,116,905,901),radius=120,fill=(144,106,55,255),outline=(62,51,36,250),width=19)
        for j in range(11):
            a=math.radians(195+j*15)
            rin,rout=302,364
            x0,y0=512+rin*math.cos(a),553+rin*math.sin(a)
            x1,y1=512+rout*math.cos(a),553+rout*math.sin(a)
            d.line((x0,y0,x1,y1),fill=(44,42,34,250),width=9 if j%5==0 else 5)
            d.line((x0-2,y0-3,x1-2,y1-3),fill=(238,205,133,180),width=2)
        cy=576;r=236
    else:cy=508;r=344
    d.ellipse((512-r-20,cy-r-20,512+r+20,cy+r+20),fill=(52,45,31,255))
    d.ellipse((512-r,cy-r,512+r,cy+r),fill=(168,117,57,255),outline=(245,214,154,240),width=13)
    d.ellipse((512-r+35,cy-r+35,512+r-35,cy+r-35),fill=(185,139,75,255),outline=(97,77,48,255),width=13)
    d.ellipse((512-r+50,cy-r+50,512+r-50,cy+r-50),outline=(255,219,142,75),width=6)
    for a in (16,74,134,192,253,310):
        ang=math.radians(a)
        rr=r-78
        xx,yy=512+rr*math.cos(ang),cy+rr*math.sin(ang)
        d.arc((xx-9,yy-9,xx+9,yy+9),0,265,fill=(71,49,27,105),width=2)
    # invented asymmetric copper inset, a design symbol rather than a real profile
    ir=76 if not scaled else 64
    d.ellipse((512-ir-11,cy-ir-11,512+ir+11,cy+ir+11),fill=(65,55,39,255),outline=(242,213,143,230),width=8)
    d.ellipse((512-ir+15,cy-ir+15,512+ir-15,cy+ir-15),fill=(116,91,51,255),outline=(214,163,89,120),width=5)
    d.rounded_rectangle((490,cy-67,530,cy+62),radius=11,fill=(41,42,38,255),outline=(231,192,120,255),width=5)
    d.line((495,cy-54,495,cy+53),fill=(220,172,98,140),width=5)
    if scaled:
        d.line((512,155,512,200),fill=(56,46,34,255),width=12)


def leather_roll(subj):
    shadow(subj,rounded_mask((170,183,844,852),92),42,28,20,170)
    d=ImageDraw.Draw(subj,'RGBA')
    # folded bag with diagonal seam, contrasting leather grain
    d.rounded_rectangle((188,204,821,864),radius=95,fill=(89,48,28,255),outline=(54,30,21,255),width=19)
    d.rounded_rectangle((209,216,802,833),radius=81,fill=(138,80,44,255),outline=(191,112,64,250),width=10)
    d.polygon([(212,228),(800,229),(790,589),(495,720),(213,586)],fill=(109,62,35,255))
    d.line([(225,257),(763,262),(776,562),(500,684),(242,575)],fill=(227,164,100,155),width=11,joint='curve')
    d.line([(238,283),(748,285),(747,540),(499,668),(250,545)],fill=(46,27,20,170),width=5,joint='curve')
    # Leather stitches along upper flap with a deliberately irregular hand-work feel
    for t in np.linspace(0,1,39):
        x=246+510*t;y=281+4*math.sin(t*math.pi)
        d.line((x,y,x+8,y+11),fill=(229,197,139,205),width=3)
    d.rounded_rectangle((426,571,605,823),radius=35,fill=(111,56,33,255),outline=(54,28,21,255),width=12)
    d.line((452,602,452,791),fill=(215,146,86,140),width=7)
    d.ellipse((468,642,573,747),fill=(60,44,27,255),outline=(218,177,100,250),width=13)
    d.ellipse((490,663,550,726),fill=(185,132,65,255),outline=(248,217,134,165),width=6)
    for x,y in [(271,360),(343,340),(675,369),(755,465),(294,744)]:
        d.arc((x,y,x+61,y+28),15,130,fill=(194,129,74,50),width=2)


def old_key(subj):
    shadow(subj,rounded_mask((240,239,784,790),64),33,25,16,85)
    # Draw a stylized skeleton key on a transparent plate and rotate as a whole.
    layer=Image.new('RGBA',(1024,1024),(0,0,0,0));d=ImageDraw.Draw(layer,'RGBA')
    # key ring
    d.ellipse((412,155,632,377),fill=(127,122,107,255),outline=(233,222,191,255),width=22)
    d.ellipse((460,203,585,328),fill=(0,0,0,0),outline=(64,59,51,255),width=12)
    d.rounded_rectangle((486,348,558,750),radius=28,fill=(162,158,142,255),outline=(67,62,52,255),width=12)
    d.polygon([(488,676),(650,676),(650,727),(604,727),(604,794),(553,794),(553,745),(489,745)],fill=(168,157,133,255))
    d.line((501,374,501,715),fill=(236,227,195,155),width=10)
    d.line((562,695,635,695),fill=(236,227,195,118),width=8)
    layer=layer.rotate(32,Image.Resampling.BICUBIC)
    alpha=layer.getchannel('A');shadow(subj,alpha,32,23,13,190)
    subj.alpha_composite(layer)


def doorbell(subj):
    shadow(subj,ellipse_mask((160,157,864,858)),45,30,16,160)
    d=ImageDraw.Draw(subj,'RGBA')
    ring(d,512,507,314,60,(171,127,62,255))
    d.ellipse((270,264,754,750),fill=(87,78,52,255),outline=(213,176,100,255),width=22)
    d.ellipse((326,315,698,689),fill=(235,220,182,255),outline=(110,96,73,255),width=20)
    d.ellipse((343,329,680,671),outline=(255,245,210,160),width=11)
    d.arc((347,345,688,684),187,301,fill=(255,253,239,210),width=15)
    for a in range(30,390,90):
        xx=int(512+296*math.cos(math.radians(a)));yy=int(507+296*math.sin(math.radians(a)))
        screw(d,xx,yy,24)


def number_plate(subj):
    shadow(subj,rounded_mask((176,221,849,811),48),31,25,14,160)
    d=ImageDraw.Draw(subj,'RGBA')
    d.rounded_rectangle((181,211,852,802),radius=62,fill=(24,51,58,255),outline=(8,34,41,255),width=14)
    d.rounded_rectangle((207,243,823,769),radius=39,fill=(238,225,196,255),outline=(37,60,69,255),width=18)
    d.rounded_rectangle((227,262,804,751),radius=29,outline=(254,241,210,130),width=6)
    for x in (247,784):
        for y in (281,735):screw(d,x,y,19)
    f=font(FONT_SERIF,329)
    b=d.textbbox((0,0),'12',font=f)
    x=(1024-(b[2]-b[0]))/2-b[0];y=(1024-(b[3]-b[1]))/2-b[1]-5
    d.text((x+4,y+7),'12',font=f,fill=(30,32,33,65))
    d.text((x,y),'12',font=f,fill=(26,52,69,255))


def tenement_door(subj):
    shadow(subj,rounded_mask((125,105,905,924),44),38,24,7,156)
    d=ImageDraw.Draw(subj,'RGBA')
    d.rounded_rectangle((129,113,898,915),radius=40,fill=(65,41,26,255),outline=(139,92,50,255),width=20)
    # transom (glass) at top, warm afternoon glow
    d.rectangle((175,147,851,338),fill=(177,146,87,255),outline=(44,35,28,255),width=21)
    d.rectangle((207,179,820,305),fill=(210,172,110,255))
    for x in (395,608):d.line((x,167,x,317),fill=(81,58,36,255),width=17)
    d.arc((222,177,800,315),190,349,fill=(246,214,156,90),width=12)
    for box in [(183,368,502,882),(521,368,841,882)]:
        d.rectangle(box,fill=(112,69,38,255),outline=(44,34,29,255),width=17)
        x1,y1,x2,y2=box
        d.rounded_rectangle((x1+37,y1+41,x2-37,y2-44),radius=16,fill=(84,54,34,255),outline=(162,107,59,255),width=15)
        d.line((x1+50,y1+55,x2-52,y1+55),fill=(230,158,90,80),width=9)
    d.ellipse((460,616,490,645),fill=(231,202,131,255),outline=(55,42,22,255),width=6)
    d.ellipse((527,616,557,645),fill=(231,202,131,255),outline=(55,42,22,255),width=6)


def door_handle(subj):
    shadow(subj,rounded_mask((240,183,792,858),73),40,32,16,130)
    d=ImageDraw.Draw(subj,'RGBA')
    d.rounded_rectangle((327,174,668,864),radius=108,fill=(142,94,54,255),outline=(53,42,31,255),width=20)
    d.rounded_rectangle((364,213,634,814),radius=91,fill=(193,145,80,255),outline=(253,215,144,255),width=8)
    d.rounded_rectangle((404,257,600,777),radius=65,fill=(164,119,66,255),outline=(70,59,40,255),width=8)
    for y in (247,790):screw(d,510,y,18)
    d.ellipse((454,435,572,553),fill=(91,71,45,255),outline=(248,205,128,255),width=16)
    d.rounded_rectangle((504,461,883,532),radius=34,fill=(178,130,70,255),outline=(68,59,40,255),width=11)
    d.arc((520,462,864,511),186,353,fill=(253,216,143,185),width=12)
    d.ellipse((841,469,895,530),fill=(114,92,62,255),outline=(230,185,115,255),width=7)


def workshop_lamp(subj):
    d=ImageDraw.Draw(subj,'RGBA')
    # a warm craft desk vignette and oversized lamp silhouette
    d.rectangle((0,768,1024,1024),fill=(108,72,43,160))
    d.line((0,764,1024,764),fill=(225,155,82,125),width=13)
    shadow(subj,rounded_mask((243,238,800,711),76),30,26,15,105)
    d.line([(499,300),(499,424)],fill=(123,137,121,255),width=30)
    d.ellipse((453,286,545,370),fill=(67,81,76,255),outline=(191,183,147,255),width=11)
    d.polygon([(364,412),(635,412),(803,647),(194,647)],fill=(48,74,70,255))
    d.polygon([(393,447),(605,447),(695,612),(302,612)],fill=(72,104,90,255))
    d.ellipse((198,614,802,676),fill=(43,56,47,255),outline=(132,143,108,255),width=12)
    d.ellipse((333,629,669,712),fill=(253,209,125,155))
    d.arc((260,580,745,689),175,355,fill=(227,228,182,170),width=10)
    # silhouettes of benign organised workshop tools on back wall
    for x in (241,354,660,769):
        d.line((x,807,x,923),fill=(50,51,44,120),width=12)


def key_ring(subj):
    shadow(subj,ellipse_mask((220,176,808,825)),36,25,16,140)
    d=ImageDraw.Draw(subj,'RGBA')
    # big metal hoop
    ring(d,516,284,118,19,(187,181,159,255))
    cols=[(182,142,78,255),(178,173,156,255),(125,124,115,255)]
    for i,(x,bottom) in enumerate([(360,818),(518,863),(662,799)]):
        y0=373+i*16;w=61
        d.ellipse((x-43,y0-62,x+43,y0+24),fill=cols[i],outline=(54,49,40,255),width=7)
        d.ellipse((x-21,y0-39,x+20,y0+2),fill=(0,0,0,0),outline=(65,62,55,255),width=4)
        d.rounded_rectangle((x-18,y0+20,x+18,bottom-56),radius=13,fill=cols[i],outline=(63,56,44,245),width=6)
        d.polygon([(x-18,bottom-105),(x+65,bottom-105),(x+65,bottom-68),(x+34,bottom-68),(x+34,bottom-23),(x+5,bottom-23),(x+5,bottom),(x-18,bottom)],fill=cols[i])
        d.line((x-8,y0+46,x-8,bottom-64),fill=(244,229,184,120),width=5)


def facade(subj):
    shadow(subj,rounded_mask((161,157,854,868),34),37,25,14,145)
    d=ImageDraw.Draw(subj,'RGBA')
    d.rounded_rectangle((184,172,852,896),radius=34,fill=(202,182,143,255),outline=(120,111,88,255),width=17)
    d.rectangle((146,214,887,289),fill=(195,176,134,255),outline=(115,105,83,255),width=8)
    d.rectangle((155,307,884,332),fill=(244,222,179,235))
    d.rectangle((163,836,873,881),fill=(156,138,109,255),outline=(88,78,67,255),width=8)
    # one central tall window made legible at reduced size
    d.rounded_rectangle((323,365,718,831),radius=24,fill=(166,175,151,255),outline=(121,111,86,255),width=34)
    d.rectangle((359,396,687,789),fill=(66,92,98,255),outline=(32,58,63,255),width=16)
    d.polygon([(374,413),(560,413),(420,780),(374,780)],fill=(167,185,173,70))
    d.line((523,398,523,789),fill=(198,192,161,255),width=18)
    d.line((363,600,692,600),fill=(190,186,160,255),width=18)
    d.rectangle((312,797,732,841),fill=(226,207,167,255),outline=(133,111,78,255),width=8)
    for x in (229,784):
        d.rectangle((x,330,x+21,844),fill=(246,221,182,115))

DRAWERS={
    'enamel_l':badge_L, 'brass_cylinder':lambda s:cylinder(s,False), 'leather_roll':leather_roll,
    'old_key':old_key, 'doorbell':doorbell, 'number_plate':number_plate,
    'dial_cylinder':lambda s:cylinder(s,True), 'tenement_door':tenement_door,
    'door_handle':door_handle, 'workshop_lamp':workshop_lamp,
    'key_ring':key_ring, 'facade':facade,
}


def render(code,slug,name_pl,name_en,description,bg,seed):
    background=bg_art(bg,seed)
    subject=Image.new('RGBA',(SIZE,SIZE),(0,0,0,0))
    DRAWERS[slug](subject)
    # gentle adaptive-style 1024 canvas drop shadow and unaltered object layer
    ios=background.convert('RGBA');ios.alpha_composite(subject)
    ios=ios.convert('RGB')
    return ios,subject,background


def save_png(image,path,mode=None):
    path.parent.mkdir(parents=True,exist_ok=True)
    if mode is not None: image=image.convert(mode)
    image.save(path,format='PNG',optimize=True,compress_level=8)


def preview(code,name_pl,ios):
    sizes=[180,120,60,48,29]
    w=644;h=314
    p=Image.new('RGB',(w,h),(247,241,229));d=ImageDraw.Draw(p)
    d.text((18,15),f'{code}  {name_pl}',font=font(FONT_SANS_BOLD,24),fill=(29,47,56))
    x=24
    for size in sizes:
        sm=ios.resize((size,size),Image.Resampling.LANCZOS)
        p.paste(sm,(x,73))
        d.text((x,78+size),f'{size} px',font=font(FONT_SANS,17),fill=(62,71,66))
        x+=size+22
    return p


def contact(rows):
    cellw=314;cellh=400; pad=25
    board=Image.new('RGB',(4*cellw+pad*2,3*cellh+pad*2+136),(242,236,224));d=ImageDraw.Draw(board)
    d.rectangle((0,0,board.width,117),fill=(30,51,66))
    d.text((36,25),'Lockwright  /  G12',font=font(FONT_SERIF,51),fill=(247,229,191))
    d.text((665,44),'12 icon directions   •   2026-11-05',font=font(FONT_SANS,22),fill=(226,221,207))
    for i,(code,name_pl,name_en,im) in enumerate(rows):
        col=i%4;row=i//4;x=pad+col*cellw;y=128+row*cellh
        thumb=im.resize((255,255),Image.Resampling.LANCZOS)
        d.rounded_rectangle((x-3,y-3,x+264,y+356),radius=15,fill=(250,247,239),outline=(198,187,168),width=2)
        board.paste(thumb,(x+4,y+9))
        d.text((x+7,y+274),f'{code}  {name_pl}',font=font(FONT_SANS_BOLD,17),fill=(29,47,56))
        d.text((x+7,y+308),name_en,font=font(FONT_SANS,16),fill=(89,87,75))
        mini=im.resize((48,48),Image.Resampling.LANCZOS)
        board.paste(mini,(x+205,y+277))
    yy=board.height-78
    d.line((28,yy,board.width-28,yy),fill=(181,170,149),width=3)
    d.text((32,yy+13),'Propozycje / Recommendations:  02 Cylinder  ·  01 Enamel L  ·  03 Leather roll',font=font(FONT_SANS_BOLD,20),fill=(29,53,61))
    return board


def make_adaptive(subject,background):
    # Scale to a 260px-wide radius inside Android's nominal central 66dp mask.
    # The source original has transparent background, so safe padding is kept.
    bbox=subject.getchannel('A').getbbox()
    item=subject.crop(bbox)
    maxside=266
    ratio=min(maxside/item.width,maxside/item.height)
    item=item.resize((max(1,round(item.width*ratio)),max(1,round(item.height*ratio))),Image.Resampling.LANCZOS)
    adaptive=Image.new('RGBA',(432,432),(0,0,0,0))
    xy=((432-item.width)//2,(432-item.height)//2)
    adaptive.alpha_composite(item,xy)
    bg=background.resize((432,432),Image.Resampling.LANCZOS).convert('RGB')
    return adaptive,bg


def main():
    output=[]
    for i,row in enumerate(DESIGNS):
        code,slug,name_pl,name_en,prompt,bg=row
        ios,subject,background=render(*row,seed=SEEDS[i])
        fg,bga=make_adaptive(subject,background)
        save_png(ios,ROOT/'ios'/f'{code}_{slug}_1024.png')
        save_png(preview(code,name_pl,ios),ROOT/'previews'/f'{code}_{slug}_sizes.png')
        save_png(fg,ROOT/'android'/f'{code}_{slug}_foreground_432.png')
        save_png(bga,ROOT/'android'/f'{code}_{slug}_background_432.png')
        output.append((code,name_pl,name_en,ios))
    save_png(contact(output),ROOT/'previews'/'contact_sheet.png')
    print(f'Created {len(output)} 1024x1024 iOS icons, previews, Android adaptive layers and contact sheet.')


if __name__=='__main__':main()
