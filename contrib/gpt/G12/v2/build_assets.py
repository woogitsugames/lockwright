#!/usr/bin/env python3
"""G12-v2: assemble four AI-generated photographic object crops into app assets.
Source is a ChatGPT-generated contact sheet; the crops are *not* full-native-resolution photos.
Requires Pillow, numpy, opencv-python.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import numpy as np, cv2, json, shutil, zipfile, hashlib

SRC=Path(__file__).resolve().parent/'sources'/'native_imagegen_contact_sheet.png'
ROOT=Path(__file__).resolve().parent
for folder in ['ios','android','previews','sources']:
    (ROOT/folder).mkdir(parents=True,exist_ok=True)

# All coordinates refer to the output of the native ChatGPT image generator.
ITEMS=[
 dict(code='01_enamel_l', pl='Tabliczka emaliowana „L”', en='Enamel L plate', box=(24,21,378,375), color=(44,30,23)),
 dict(code='02_brass_cylinder', pl='Czoło mosiężnej wkładki', en='Brass cylinder face', box=(404,21,758,375), color=(69,45,27)),
 dict(code='03_leather_roll', pl='Zwinięta skórzana zwijka', en='Closed leather tool roll', box=(785,21,1139,375), color=(48,30,22)),
 dict(code='04_old_key', pl='Stary klucz na skórze', en='Old key on leather', box=(1160,21,1514,375), color=(83,40,23)),
]

font_paths=['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf']
font_bold_paths=['/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf','/usr/share/fonts/truetype/liberation2/LiberationSans-Bold.ttf']
def font(size,bold=False):
  import os
  for f in (font_bold_paths if bold else font_paths):
    if os.path.exists(f): return ImageFont.truetype(f,size)
  return ImageFont.load_default()

im=Image.open(SRC).convert('RGB')
# Segmentation is hand-authored from original photo silhouettes; deliberately no background removed by AI.
def object_alpha(i):
    s=354
    out=Image.new('L',(s,s),0); d=ImageDraw.Draw(out)
    if i==0:
        d.rounded_rectangle((37,42,325,327),radius=29,fill=255)
    elif i==1:
        # The adaptive foreground uses the *face* of the cylinder without the cropped stem.
        d.ellipse((53,19,291,254),fill=255)
    elif i==2:
        # Closed rolled pouch: polygon follows its soft organic silhouette and seams.
        pts=[(5,257),(10,238),(26,214),(48,184),(69,161),(104,139),(136,112),
             (172,90),(203,51),(244,17),(274,18),(303,28),(331,51),(342,80),
             (340,119),(325,145),(303,160),(291,175),(278,205),(245,224),
             (235,247),(215,271),(194,294),(170,309),(135,333),(100,350),
             (58,351),(29,346),(9,324),(0,295)]
        d.polygon(pts, fill=255)
    else:
        # A thin metal key needs an accurately cut-out silhouette; use shape as a
        # prior for segmentation to preserve the object and remove leather.
        arr=np.array(im.crop(ITEMS[i]['box']))
        h,w=arr.shape[:2]
        mask=np.full((h,w),cv2.GC_PR_BGD,np.uint8)
        prior=np.zeros((h,w),np.uint8)
        cv2.ellipse(prior,(237,68),(82,57),-5,0,360,255,-1)
        cv2.line(prior,(211,107),(83,307),255,48)
        cv2.fillPoly(prior,[np.array([(29,252),(67,228),(104,257),(121,274),(89,330),(26,324),(12,307)],np.int32)],255)
        k=np.ones((27,27),np.uint8)
        dilation=cv2.dilate(prior,k,iterations=1)
        mask[dilation==0]=cv2.GC_BGD
        mask[prior>0]=cv2.GC_PR_FGD
        # foreground seeds follow the material's centers, not the dark leather.
        cv2.ellipse(mask,(239,70),(66,42),-5,0,360,cv2.GC_FGD,9)
        cv2.line(mask,(210,110),(89,304),cv2.GC_FGD,11)
        cv2.line(mask,(40,280),(59,301),cv2.GC_FGD,8)
        # The open loop shows leather through its center.
        cv2.ellipse(mask,(239,65),(44,24),-6,0,360,cv2.GC_BGD,-1)
        mask[:7,:]=cv2.GC_BGD; mask[-7:,:]=cv2.GC_BGD
        mask[:,:7]=cv2.GC_BGD; mask[:,-7:]=cv2.GC_BGD
        bg=np.zeros((1,65),np.float64); fg=np.zeros((1,65),np.float64)
        cv2.grabCut(cv2.cvtColor(arr,cv2.COLOR_RGB2BGR),mask,None,bg,fg,6,cv2.GC_INIT_WITH_MASK)
        fgmask=np.where((mask==cv2.GC_PR_FGD)|(mask==cv2.GC_FGD),255,0).astype('uint8')
        # Suppress tiny stray fragments, retain the largest continuous component.
        count,labels,stats,centroids=cv2.connectedComponentsWithStats(fgmask)
        if count>1:
          largest=1+np.argmax(stats[1:,cv2.CC_STAT_AREA]);fgmask=(labels==largest).astype('uint8')*255
        fgmask=cv2.morphologyEx(fgmask,cv2.MORPH_CLOSE,np.ones((3,3),np.uint8))
        out=Image.fromarray(fgmask)
    return out.filter(ImageFilter.GaussianBlur(1.15))

def texture(i,sz=432):
    rgb=np.array(ITEMS[i]['color'],float)
    rng=np.random.default_rng(2677+i)
    noise=rng.normal(size=(sz,sz)).astype(np.float32)
    coarse=cv2.GaussianBlur(noise,(0,0),24)
    coarse=coarse/(np.std(coarse)+1e-6)
    medium=cv2.GaussianBlur(noise,(0,0),5)
    medium=medium/(np.std(medium)+1e-6)
    fine=noise
    y,x=np.mgrid[0:sz,0:sz]
    if i==0: grain=3*np.sin(y*.26+np.sin(x*.035)*.9)+1.7*np.sin(y*.55+x*.018)
    elif i==1: grain=1.0*np.sin(y*.065+x*.032)
    elif i==2: grain=2.0*np.sin(x*.1+y*.045)+1.1*np.sin(y*.15)
    else: grain=1.8*np.sin(x*.08+y*.07)
    detail=(coarse*6.5 +medium*2.4+fine*2.0+grain)
    a=np.zeros((sz,sz,3),np.float32)
    for ch,factor in enumerate([1.15,1.0,.84]): a[:,:,ch]=np.clip(rgb[ch]+detail*factor,0,255)
    return Image.fromarray(a.astype('uint8'),'RGB')

def fit_foreground(crop,mask,i):
    bb=mask.getbbox()
    if bb is None: raise ValueError('Empty mask')
    source=Image.new('RGBA',crop.size,(0,0,0,0));source.paste(crop.convert('RGBA'));source.putalpha(mask)
    # Compact subject inside 264px central safe zone in 432px canvas.
    region=source.crop(bb)
    target=[202,246,223,218][i]
    fac=min(target/region.width,target/region.height)
    width=int(round(region.width*fac));height=int(round(region.height*fac))
    region=region.resize((width,height),Image.Resampling.LANCZOS)
    canvas=Image.new('RGBA',(432,432),(0,0,0,0))
    x=(432-width)//2; y=(432-height)//2
    # Subtle material shadow, with retained transparency outside subject.
    shadow_alpha=region.getchannel('A').filter(ImageFilter.GaussianBlur(7))
    shadow=Image.new('RGBA',region.size,(0,0,0,0)); shadow.paste(Image.new('RGBA',region.size,(10,6,5,85)),(0,0),shadow_alpha)
    canvas.alpha_composite(shadow,(x+3,y+5))
    canvas.alpha_composite(region,(x,y))
    return canvas

def show_preview(icon, item):
    W,H=1150,632
    c=Image.new('RGB',(W,H),(236,232,223)); d=ImageDraw.Draw(c)
    d.rectangle((0,310,W,H),fill=(30,30,31))
    d.text((28,16),item['pl'],fill=(37,34,33),font=font(25,True))
    d.text((28,50),item['en'],fill=(93,80,68),font=font(17))
    d.text((32,100),'JASNE TŁO / LIGHT',fill=(67,64,63),font=font(15,True))
    d.text((32,368),'CIEMNE TŁO / DARK',fill=(221,214,203),font=font(15,True))
    sizes=[180,120,60,48,29]
    centers=[280,528,710,856,990]
    for row in [0,1]:
        bottom=264 if row==0 else 557
        ink=(50,45,43) if row==0 else (230,225,219)
        for size,x in zip(sizes,centers):
            mini=icon.resize((size,size),Image.Resampling.LANCZOS)
            c.paste(mini,(x-size//2,bottom-size))
            d.text((x,bottom+11),f'{size} px',font=font(17 if size>=60 else 15),fill=ink,anchor='mt')
    return c

# Full-size images and source excerpts.
record=[]
for i,item in enumerate(ITEMS):
    code=item['code']
    crop=im.crop(item['box']);crop.save(ROOT/'sources'/f'{code}_source_354.png')
    ios=crop.resize((1024,1024),Image.Resampling.LANCZOS)
    ios=ImageEnhance.Contrast(ios).enhance(1.02)
    ios=ios.filter(ImageFilter.UnsharpMask(radius=1.8,percent=55,threshold=5))
    ios.save(ROOT/'ios'/f'{code}_1024.png',optimize=True)
    mask=object_alpha(i)
    foreground=fit_foreground(crop,mask,i)
    foreground.save(ROOT/'android'/f'{code}_foreground_432.png',optimize=True)
    bg=texture(i)
    bg.save(ROOT/'android'/f'{code}_background_432.png',optimize=True)
    show_preview(ios,item).save(ROOT/'previews'/f'{code}_light_dark_sizes.png',optimize=True)
    record.append((crop,ios,foreground,bg,mask))

# Contact sheet comparing 4 full-quality 48px icons, larger square icons, and their PL/EN titles.
contact=Image.new('RGB',(1380,766),(231,227,218));d=ImageDraw.Draw(contact)
d.text((38,28),'LOCKWRIGHT  /  G12 v2',font=font(36,True),fill=(44,34,29))
d.text((38,78),'Cztery fotografie przedmiotów  /  Four photographic object studies',font=font(19),fill=(84,72,61))
for i,item in enumerate(ITEMS):
    crop,ios,fg,bg,mask=record[i]
    x=32+i*342
    d.rounded_rectangle((x,134,x+318,594),radius=16,fill=(247,244,237),outline=(201,193,181),width=1)
    contact.paste(ios.resize((290,290),Image.Resampling.LANCZOS),(x+14,150))
    d.text((x+14,456),item['pl'],font=font(18,True),fill=(46,37,31))
    d.text((x+14,485),item['en'],font=font(15),fill=(93,77,66))
    d.text((x+14,532),'48 px',font=font(14,True),fill=(77,67,58))
    contact.paste(ios.resize((48,48),Image.Resampling.LANCZOS),(x+94,522))
    d.text((x+171,532),'29 px',font=font(14,True),fill=(77,67,58))
    contact.paste(ios.resize((29,29),Image.Resampling.LANCZOS),(x+232,531))
d.line((38,633,1341,633),fill=(190,179,163),width=1)
d.text((38,657),'REKOMENDACJA  /  RECOMMENDATION',font=font(16,True),fill=(95,79,61))
d.text((38,685),'01  Tabliczka L — najwyraźniejszy znak w skali 48 px',font=font(22,True),fill=(44,35,27))
d.text((38,721),'02  Wkładka — najlepszy wariant tematyczny; 03  Zwijka — najlepszy klimat rzemiosła',font=font(16),fill=(83,70,61))
contact.save(ROOT/'previews'/'contact_sheet_v2.png',optimize=True)

# Round adaptive-mask QA: the visible circle is 288px centered in the 432px layer.
adaptive=Image.new('RGB',(1340,420),(236,233,225)); ad=ImageDraw.Draw(adaptive)
ad.text((34,21),'ANDROID ADAPTIVE — PODGLĄD MASKI OKRĄGŁEJ / ROUND MASK',font=font(24,True),fill=(51,43,36))
for i,item in enumerate(ITEMS):
    code=item['code']
    bg=Image.open(ROOT/'android'/f'{code}_background_432.png').convert('RGBA')
    fg=Image.open(ROOT/'android'/f'{code}_foreground_432.png')
    bg.alpha_composite(fg)
    round_mask=Image.new('L',(432,432),0)
    ImageDraw.Draw(round_mask).ellipse((72,72,360,360),fill=255)
    bg.putalpha(round_mask)
    circ=bg.crop((72,72,360,360)).resize((256,256),Image.Resampling.LANCZOS)
    x=36+330*i
    adaptive.paste(circ,(x+20,77),circ)
    ad.text((x+4,347),item['pl'],font=font(16,True),fill=(52,42,36))
adaptive.save(ROOT/'previews'/'android_adaptive_round_mask.png',optimize=True)

# QA details exported to machine-readable JSON.
checks={}
for f in ROOT.rglob('*.png'):
    t=Image.open(f)
    checks[str(f.relative_to(ROOT))]={'width':t.width,'height':t.height,'mode':t.mode,'bytes':f.stat().st_size,
            'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}
    if f.parent.name=='ios': assert t.size==(1024,1024) and t.mode=='RGB'
    if f.parent.name=='android':assert t.size==(432,432)
    if 'foreground' in f.name: assert t.mode=='RGBA' and t.getchannel('A').getextrema()==(0,255)
    if 'background' in f.name: assert t.mode=='RGB'
    assert f.stat().st_size<=20*1024*1024
(ROOT/'qa_manifest.json').write_text(json.dumps({'files':checks, 'source':SRC.name, 'review':'visual/manual; no user testing'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Generated',len(checks),'PNGs; total bytes',sum(v['bytes'] for v in checks.values()))
for i,item in enumerate(ITEMS):print(item['code'],'alpha extrema',record[i][4].getextrema())
