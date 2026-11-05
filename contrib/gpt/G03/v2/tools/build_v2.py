#!/usr/bin/env python3
"""G03-v2: image-derived texture quilting; no synthetic wood-grain generation.

Source: three OpenAI image-generation overview images. Inputs are cropped with
extract.py. Output: tileable image-derived albedo, approximate height, roughness.
"""
from pathlib import Path
import json, hashlib, random
import numpy as np
import cv2
from PIL import Image, ImageDraw, ImageFont, ImageOps
ROOT=Path(__file__).resolve().parents[1]
N=2048
VARIANTS=['oak_satin','oak_bottle_green','pine_cream','walnut_dark']
SEED={'oak_satin':5213, 'oak_bottle_green':6241, 'pine_cream':7259, 'walnut_dark':8263}
LABELS={'oak_satin':('Stary dąb satynowy','Satin old oak'),
        'oak_bottle_green':('Dąb butelkowa zieleń','Bottle-green painted oak'),
        'pine_cream':('Kremowa sosna','Cream painted pine'),
        'walnut_dark':('Ciemny orzech','Dark walnut')}

def taper(n, fade):
    """Flat-topped Hann tapers, zero at patch boundaries."""
    z=np.ones(n,dtype=np.float32)
    t=(np.arange(fade,dtype=np.float32)+0.5)/fade
    ramp=np.sin(np.pi*t/2)**2
    z[:fade]=ramp
    z[-fade:]=ramp[::-1]
    return z

def sample_patch(sources, w, h, rng):
    typ=rng.choices([0,1,2],[0.50,0.28,0.22])[0]
    src=sources[typ]
    ih,iw=src.shape[:2]
    # Slightly varied source framing. Keep vertical grain direction.
    cropw=max(145,int(iw*rng.uniform(.76, .99)))
    croph=max(125,int(ih*rng.uniform(.78, .99)))
    cropw=min(iw,cropw);croph=min(ih,croph)
    xmargin=rng.randrange(0,iw-cropw+1);ymargin=rng.randrange(0,ih-croph+1)
    sl=src[ymargin:ymargin+croph,xmargin:xmargin+cropw]
    if rng.random()<0.5: sl=np.ascontiguousarray(sl[:,::-1])
    if rng.random()<0.2: sl=np.ascontiguousarray(sl[::-1,:])
    out=cv2.resize(sl,(w,h),interpolation=cv2.INTER_CUBIC)
    # Narrow grading differences emulate variations between timbers, do not invent grain.
    gain_value=rng.uniform(.97,1.03)
    gain=np.array([gain_value*rng.uniform(.995,1.005),gain_value*rng.uniform(.995,1.005),gain_value*rng.uniform(.995,1.005)],dtype=np.float32)
    out=np.clip((out.astype(np.float32)-113)*rng.uniform(.96,1.04)+113,0,255)*gain.reshape(1,1,3)
    return np.uint8(np.clip(out,0,255))

def tileable_texture(variant):
    rng=random.Random(SEED[variant]);grid=6
    # Patch synthesis on a torus; quilt patches overlap and wrap in U/V.
    step=N//grid; overlap=105; pw=step+overlap*2; ph=pw
    sources=[cv2.cvtColor(cv2.imread(str(ROOT/'sources'/f'{variant}_source_{i}.jpg')),cv2.COLOR_BGR2RGB) for i in [1,2,3]]
    acc=np.zeros((N,N,3),dtype=np.float32); wt=np.zeros((N,N),dtype=np.float32)
    mask=np.outer(taper(ph,110),taper(pw,110))
    for yi in range(grid+1):
        for xi in range(grid+1):
            # row and column after 6 wrap but have unique samples, richer variation
            x0=int(round(xi*N/grid))-overlap + rng.randrange(-33,34)
            y0=int(round(yi*N/grid))-overlap + rng.randrange(-33,34)
            patch=sample_patch(sources,pw,ph,rng).astype(np.float32)
            ix=(np.arange(x0,x0+pw,dtype=np.int32)%N)
            iy=(np.arange(y0,y0+ph,dtype=np.int32)%N)
            acc[np.ix_(iy,ix)]+=patch*mask[:,:,None]
            wt[np.ix_(iy,ix)]+=mask
    img=acc/np.maximum(wt[:,:,None],1e-6)
    # Flatten broad photograph illumination gradients, retain actual pores and paint edges.
    img8=np.uint8(np.clip(img,0,255))
    lab=cv2.cvtColor(img8,cv2.COLOR_RGB2LAB).astype(np.float32)
    L=lab[:,:,0].copy()
    large=cv2.GaussianBlur(L,(0,0),sigmaX=65)
    lab[:,:,0]=np.clip(L-0.27*(large-np.mean(large)),0,255)
    img=cv2.cvtColor(np.uint8(lab),cv2.COLOR_LAB2RGB)
    # gentle unsharp boost lost by collage crop; does not invent stripes.
    blur=cv2.GaussianBlur(img,(0,0),sigmaX=1.15)
    img=np.uint8(np.clip(1.19*img.astype(np.float32)-.19*blur.astype(np.float32),0,255))
    # Exact matching values at opposing image edges with small feather, avoids hard seam.
    img=close_edges(img.astype(np.float32),width=44)
    return np.uint8((np.uint8(np.clip(img,0,255))//4)*4)

def close_edges(array,width=44):
    out=array.copy();W=width
    for k in range(W):
        a=(1-k/W)**2
        left=out[:,k,:].copy();right=out[:,-1-k,:].copy()
        avg=(left+right)*.5
        out[:,k,:]=left*(1-a)+avg*a
        out[:,-1-k,:]=right*(1-a)+avg*a
    for k in range(W):
        a=(1-k/W)**2
        top=out[k,:,:].copy();bot=out[-1-k,:,:].copy()
        avg=(top+bot)*.5
        out[k,:,:]=top*(1-a)+avg*a
        out[-1-k,:,:]=bot*(1-a)+avg*a
    # enforce exact equality (for all channels) to remove image wrap boundary gradient
    edge=((out[:,0,:]+out[:,-1,:])*.5)
    out[:,0,:]=edge;out[:,-1,:]=edge
    edge=((out[0,:,:]+out[-1,:,:])*.5)
    out[0,:,:]=edge;out[-1,:,:]=edge
    return out

def maps_from_albedo(rgb, variant):
    gray=cv2.cvtColor(rgb,cv2.COLOR_RGB2GRAY).astype(np.float32)/255.0
    local10=cv2.GaussianBlur(gray,(0,0),5)
    local55=cv2.GaussianBlur(gray,(0,0),29)
    detail=gray-local10
    medium=gray-local55
    # Edges/cavities inferred from image contrast. Not scanned physical topography.
    h=np.full(gray.shape,0.5,dtype=np.float32)+detail*.60+medium*.19
    rough_base={'oak_satin':.39,'oak_bottle_green':.46,'pine_cream':.60,'walnut_dark':.40}[variant]
    rough=np.full(gray.shape,rough_base,dtype=np.float32)
    rough+=np.minimum(np.abs(detail)*.52,.08)
    rough+=np.minimum(np.abs(medium)*.18,.05)
    rgbf=rgb.astype(np.float32)
    if variant=='oak_bottle_green':
        r,g,b=rgbf[:,:,0],rgbf[:,:,1],rgbf[:,:,2]
        exposed=((r>g*1.12) & (r>65) & (r>b*1.28)).astype(np.uint8)
        exposed=cv2.medianBlur(exposed*255,3)/255.0
        paint=1-exposed
        # Paint ridge at the boundary and recessed exposed timber.
        dist=cv2.distanceTransform(np.uint8(paint>0.5),cv2.DIST_L2,3)
        ridge=np.exp(-((dist-2.0)/3.0)**2)*(paint>0.5)
        h+=paint*.050-exposed*.040+ridge*.070
        rough+=exposed*.28+ridge*.055
    elif variant=='pine_cream':
        lab=cv2.cvtColor(rgb,cv2.COLOR_RGB2LAB)
        L=lab[:,:,0].astype(np.float32)
        paint=cv2.GaussianBlur(np.uint8(L>170),(3,3),0).astype(np.float32)
        exposed=1-paint
        dist=cv2.distanceTransform(np.uint8(paint>.5),cv2.DIST_L2,3)
        ridge=np.exp(-((dist-3.0)/4.0)**2)*(paint>.5)
        h+=paint*.075-exposed*.030+ridge*.090
        rough+=exposed*.13+ridge*.065
    elif variant=='oak_satin':
        rough+=np.clip(-detail,0,.12)*.4
    elif variant=='walnut_dark':
        rough+=np.clip(-detail,0,.12)*.3
    h=np.clip(h,.16,.84);rough=np.clip(rough,.16,.94)
    ht=np.uint16(np.round(h*65535))
    rt=np.uint8(np.round(rough*255))
    # make derived maps tile perfectly too
    ht=np.uint16(np.clip(close_edges(ht.astype(np.float32)[:,:,None])[:,:,0],0,65535))
    ht=np.uint16(ht//64*64)  # 10-bit effective data in 16-bit PNG container
    rt=np.uint8(np.clip(close_edges(rt.astype(np.float32)[:,:,None])[:,:,0],0,255))
    return ht,rt

font_candidates=['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','C:/Windows/Fonts/segoeui.ttf','C:/Windows/Fonts/arial.ttf']
def get_font(size):
    for path in font_candidates:
        if Path(path).is_file(): return ImageFont.truetype(path,size)
    return ImageFont.load_default()
font=get_font(36)

def previews(k,im,ht,rough):
    # native tile samples downscaled to 900 then tiled twice; 2x2 preview = 1800 x 1800
    tile=Image.fromarray(im).resize((900,900),Image.Resampling.LANCZOS)
    tilemap=Image.new('RGB',(1800,1800))
    for yi in range(2):
     for xi in range(2):tilemap.paste(tile,(xi*900,yi*900))
    tilemap.save(ROOT/'previews'/f'{k}_albedo_2x2.jpg',quality=93,subsampling=0)
    return tile

records=[]
for k in VARIANTS:
    albedo=tileable_texture(k)
    height,rough=maps_from_albedo(albedo,k)
    a=ROOT/'materials'/f'{k}_albedo_2048.png'
    h=ROOT/'materials'/f'{k}_height_2048.png'
    r=ROOT/'materials'/f'{k}_roughness_2048.png'
    Image.fromarray(albedo,'RGB').save(a,optimize=False,compress_level=3)
    Image.fromarray(height).save(h,optimize=False,compress_level=3)
    Image.fromarray(rough,'L').save(r,optimize=False,compress_level=3)
    previews(k,albedo,height,rough)
    m={}
    for label,ar in [('albedo',albedo),('height',height),('roughness',rough)]:
      if label=='albedo':
        dx=np.abs(ar[:,0,:].astype(int)-ar[:,-1,:].astype(int));dy=np.abs(ar[0,:,:].astype(int)-ar[-1,:,:].astype(int))
      else:
        dx=np.abs(ar[:,0].astype(int)-ar[:,-1].astype(int));dy=np.abs(ar[0,:].astype(int)-ar[-1,:].astype(int))
      m[label]={'max_x':int(dx.max()),'max_y':int(dy.max()),'mean_x':float(dx.mean()),'mean_y':float(dy.mean())}
    records.append({'material':k,'size':[2048,2048],'seam_metrics':m,'bytes':{'albedo':a.stat().st_size,'height':h.stat().st_size,'roughness':r.stat().st_size}})
    print(k, records[-1],flush=True)

# overview and PBR comparison sheet for documentation
w=680; pad=24; label_h=72
sheet=Image.new('RGB',(w*2+pad*3, (w+label_h)*2+pad*3),(42,42,42))
d=ImageDraw.Draw(sheet)
for idx,k in enumerate(VARIANTS):
    x=pad+(idx%2)*(w+pad);y=pad+(idx//2)*(w+label_h+pad)
    i=Image.open(ROOT/'materials'/f'{k}_albedo_2048.png').resize((w,w),Image.Resampling.LANCZOS)
    sheet.paste(i,(x,y))
    d.text((x+10,y+w+12),LABELS[k][0],fill='white',font=get_font(27))
    d.text((x+10,y+w+43),LABELS[k][1],fill='white',font=get_font(22))
sheet.save(ROOT/'previews'/'materials_overview_2x2.jpg',quality=92,subsampling=0)

pbr=Image.new('RGB',(3*480+4*20,4*410+5*18),(32,32,32));dd=ImageDraw.Draw(pbr)
for yi,k in enumerate(VARIANTS):
   for xi,m in enumerate(['albedo','height','roughness']):
      im=Image.open(ROOT/'materials'/f'{k}_{m}_2048.png')
      if m=='height':
         aa=np.asarray(im,dtype=np.float32)
         lo,hi=np.percentile(aa,[2,98])
         aa=np.uint8(np.clip((aa-lo)/max(1,hi-lo)*255,0,255))
         im=Image.fromarray(aa,'L')
      im=im.convert('RGB').resize((480,375),Image.Resampling.LANCZOS)
      x=20+xi*500;y=18+yi*428
      pbr.paste(im,(x,y))
      dd.text((x+4,y+378),f'{LABELS[k][1]} / {m}',fill='white',font=get_font(22))
pbr.save(ROOT/'previews'/'pbr_overview.jpg',quality=90,subsampling=0)

q={'data': '2026-11-05','generation_source':'3 OpenAI generated image boards, cropped then image-derived quilt','full_resolution_source':False,'map_resolution':[2048,2048], 'materials':records,'all_sized_under_20_mb':all(v<20*1024*1024 for rec in records for v in rec['bytes'].values()),'source_images_1':str(ROOT/'sources'),'notes':['Generated boards contained only 200-380 px material crops. 2048 maps are synthesized from enlarged photographic patches; not original 2048 photographs.','Height is contrast-derived and not physical measurement.','2x2 visual tiling review required before final use.']}
(ROOT/'QA.json').write_text(json.dumps(q,ensure_ascii=False,indent=2),encoding='utf-8')
print('DONE',flush=True)
