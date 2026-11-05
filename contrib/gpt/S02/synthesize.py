#!/usr/bin/env python3
"""S02 original tenement acoustics. No external recordings or sampled music.

Python >=3.10, numpy, scipy, soundfile, pyloudnorm. Deterministic seed.
Usage: python synthesize.py [--out DIR] [--seed 20261105]
All output locations are relative to S02 and contain no third-party material.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import math
import struct
from datetime import date
from pathlib import Path

import numpy as np
import soundfile as sf
import scipy.signal as ss
import pyloudnorm as pyln

SR=48000
DATE='2026-11-05'
RNG_SEED=20261105

# Original additive contact resonance and granular friction models.
def bump(y:np.ndarray, t:float, amp:float, freqs:list[float], decays:list[float], rng:np.random.Generator,
         width:float=.12, noise:float=.28):
    start=int(round(t*SR))
    if start>=len(y):return
    if start<0:raise ValueError('negative hit time')
    n=min(len(y)-start,max(100,int(SR*width)))
    tt=np.arange(n,dtype=np.float64)/SR
    attack=np.minimum(1.,tt/.00035)
    sound=np.zeros(n,dtype=np.float64)
    for k,(f,tau) in enumerate(zip(freqs,decays)):
        detune=1+rng.uniform(-.016,.016)
        sound+=(1/(1+.72*k))*np.exp(-tt/max(.001,tau))*np.sin(2*np.pi*f*detune*tt)
    sound/=max(1,len(freqs))**.6
    if noise:
        rough=rng.normal(size=n)
        rough=ss.sosfilt(ss.butter(2,[170,4500],btype='bandpass',fs=SR,output='sos'),rough)
        sound+=noise*rough*np.exp(-tt/np.clip(width*.22,.015,.12))
    y[start:start+n]+=amp*attack*sound

def friction(y:np.ndarray,start:float,duration:float,amp:float,rng:np.random.Generator,
             low:float=180,high:float=3600,texture:float=22):
    n0=int(start*SR)
    if n0>=len(y):return
    n=min(int(duration*SR),len(y)-n0)
    if n<16:return
    tt=np.arange(n)/SR
    noise=rng.normal(size=n)
    sos=ss.butter(2,[low,high],btype='bandpass',fs=SR,output='sos')
    filt=ss.sosfilt(sos,noise)
    # Tiny, irregular stick-slip impulses, never a periodic synth alarm.
    flutter=.55+.45*np.sin(2*np.pi*(texture*tt+1.3*np.sin(tt*3)))**2
    window=np.sin(np.pi*np.minimum(1,tt/duration))**.7
    y[n0:n0+n]+=amp*filt*flutter*window

def envelope_and_peak(y:np.ndarray,target_db:float=-12):
    y=np.asarray(y,dtype=np.float64)
    if not np.any(y):raise ValueError('empty signal')
    y-=np.mean(y)
    # Prevent clicks at file boundaries while keeping contact onset <=5ms.
    n=min(len(y)//10,int(.022*SR))
    if n:y[-n:]*=np.linspace(1,0,n)
    y[:min(12,len(y))]*=np.linspace(0,1,min(12,len(y)))
    peak=np.max(np.abs(y))
    if peak==0:raise ValueError('silent signal')
    y*=10**(target_db/20)/peak
    return y.astype('float32')

def step(kind:str,v:int,rng:np.random.Generator)->np.ndarray:
    length=.48+rng.uniform(0,.30)
    y=np.zeros(int(length*SR),dtype=np.float64)
    heavier=(v%4==2 or v%4==3)
    if kind=='wood':
        base=[93,187,318,514]
        bump(y,0,.72 if heavier else .48,base,[.085,.065,.042,.030],rng,.27,.55)
        bump(y,.135+rng.uniform(-.02,.02),.38,[114,230,460],[.065,.052,.026],rng,.18,.29)
        friction(y,.02,.30,.06,rng,70,1600,18)
        # Flex of the stair tread, not horror-string creaking.
        d=.26;tt=np.arange(int(d*SR))/SR;p=int(.18*SR)
        creak=.075*np.sin(2*np.pi*(185+18*tt/d)*tt)*np.sin(np.pi*tt/d)**2
        y[p:p+len(tt)]+=creak[:max(0,len(y)-p)]
    else:
        bump(y,0,.62 if heavier else .4,[220,450,970,1730],[.038,.034,.025,.019],rng,.16,.72)
        bump(y,.09+rng.uniform(.008,.04),.28,[305,710,1180],[.033,.025,.018],rng,.12,.48)
        friction(y,.014,.27,.06,rng,350,7000,32)
    return envelope_and_peak(y)

def knock(v:int,rng:np.random.Generator)->np.ndarray:
    style=['shy','shy','firm','firm','urgent','urgent'][v-1]
    ts={'shy':[0,.53],'firm':[0,.24,.56],'urgent':[0,.18,.34,.65]}[style]
    ts=[t+rng.uniform(-.016,.016) if t else 0 for t in ts]
    y=np.zeros(int((max(ts)+.40)*SR),dtype=np.float64)
    for i,t in enumerate(ts):
        amp= {'shy':.4,'firm':.63,'urgent':.75}[style]*(1+.12*rng.normal())
        bump(y,t,amp,[148,285,540,950],[.077,.063,.037,.020],rng,.23,.25)
        if style=='urgent':bump(y,t+.014,.13,[96,440],[.043,.035],rng,.13,.2)
    return envelope_and_peak(y)

def bell(v:int,rng:np.random.Generator)->np.ndarray:
    # Three invented older apartment bells: short metal strike, tremulous coil,
    # or long two-coil electromechanical buzz; no sampled or recognizable tune.
    lengths={1:1.55,2:2.04,3:1.43};y=np.zeros(int(lengths[v]*SR),dtype=np.float64)
    if v==1: events=[(0,420),(.61,660)]
    elif v==2:events=[(0,530),(.26,755),(.95,525)]
    else:events=[(0,485),(.17,474),(.40,490)]
    for t,f in events:
        bump(y,t,.6,[f,f*2.11,f*2.94],[.40,.18,.12],rng,.53,.10)
    tt=np.arange(len(y))/SR
    if v!=1:
        gate=(np.sin(2*np.pi*(23 if v==2 else 30)*tt)>-.12).astype(float)
        gate=ss.sosfilt(ss.butter(1,3400,fs=SR,output='sos'),gate)
        y+=.035*np.sin(2*np.pi*(126 if v==2 else 118)*tt)*gate*np.exp(-tt/1.4)
    return envelope_and_peak(y)

def switch(v:int,rng:np.random.Generator)->np.ndarray:
    y=np.zeros(int(.37*SR))
    bump(y,0,.75,[370,925,1910],[.026,.014,.009],rng,.12,.45)
    bump(y,.072 if v==1 else .105,.21,[128,420],[.040,.018],rng,.10,.30)
    return envelope_and_peak(y)

def timer(v:int,rng:np.random.Generator)->np.ndarray:
    y=np.zeros(int(8*SR),dtype=np.float64)
    for i in range((32 if v==1 else 16)):
        t=i*(.25 if v==1 else .5)
        bump(y,t,.32,[720+90*(i%2),1360+70*(i%2)],[.015,.007],rng,.041,.12)
    return envelope_and_peak(y)

def bulb(v:int,rng:np.random.Generator)->np.ndarray:
    y=np.zeros(int(.46*SR))
    bump(y,0,.40,[142,610,1550],[.021,.012,.008],rng,.09,.15)
    # Loose glass/filament ping after the stair timer releases.
    bump(y,.12+.04*v,.11,[460,1120],[.13,.075],rng,.20,.03)
    return envelope_and_peak(y)

def hinge(v:int,rng:np.random.Generator)->np.ndarray:
    duration=1.0+.17*v
    y=np.zeros(int(duration*SR),dtype=np.float64)
    bump(y,0,.21,[240,690],[.027,.013],rng,.06,.20)
    dur=duration-.24;tt=np.arange(int(dur*SR))/SR
    freq=(148+v*25)+(38+v*5)*tt/dur + 10*np.sin(2*np.pi*(2+v/4)*tt)
    ph=np.cumsum(2*np.pi*freq/SR)
    env=np.sin(np.pi*tt/dur)**1.3
    grit=(np.sin(2*np.pi*(11+v*2)*tt)>.22).astype(float)*.24+.55
    d=.19
    y[int(d*SR):int(d*SR)+len(tt)]+=.14*np.sin(ph)*env*grit
    friction(y,.14,duration-.2,.085,rng,270,3400,14+v)
    bump(y,duration-.1,.15,[162,406],[.040,.018],rng,.085,.20)
    return envelope_and_peak(y)

def handle(v:int,rng:np.random.Generator)->np.ndarray:
    y=np.zeros(int((.45+.08*v)*SR))
    bump(y,0,.43,[515,1250,2380],[.047,.028,.014],rng,.11,.18)
    friction(y,.045,.11+.04*v,.052,rng,530,3500,35)
    bump(y,.18+.035*v,.54,[345,720,1500],[.063,.045,.027],rng,.18,.3)
    return envelope_and_peak(y)

# Ambience: colored stochastic fields + circular spatialized events. The noise
# is blended across a 0.9-s cyclic seam BEFORE adding periodic room events.
def filtered_noise(rng:np.random.Generator,size:int,lo:float|None=None,hi:float|None=None)->np.ndarray:
    noise=rng.normal(0,1,size).astype('float32')
    if lo and hi:so=ss.butter(2,[lo,hi],btype='bandpass',fs=SR,output='sos')
    elif lo:so=ss.butter(2,lo,btype='highpass',fs=SR,output='sos')
    else:so=ss.butter(2,hi,btype='lowpass',fs=SR,output='sos')
    return ss.sosfilt(so,noise).astype('float32')

def cyclic_field(rng,size,lo,hi):
    seam=int(.9*SR)
    raw=filtered_noise(rng,size+seam,lo,hi)
    x=raw[:size].copy()
    w=np.linspace(0,1,seam,dtype=np.float32)
    w=w*w*(3-2*w)
    x[:seam]=raw[size:size+seam]*(1-w)+raw[:seam]*w
    return x

def add_spatial(left,right,time,sound,vol,pan=-.2,delay=.018,refl=.17):
    # Place events around the circular time axis, including early wall reflections.
    n=len(left);base=int(time*SR)%n
    def place(buf,p,src,mag):
        p=p%n
        k=min(len(src),n-p)
        buf[p:p+k]+=src[:k]*mag
        if k<len(src):buf[:len(src)-k]+=src[k:]*mag
    place(left,base,sound,vol*(1-pan)*.5)
    place(right,base+int(delay*SR),sound,vol*(1+pan)*.5)
    place(left,base+int(.047*SR),sound,vol*refl*.38)
    place(right,base+int(.066*SR),sound,vol*refl*.43)

def env_event(kind,rng,length=.38,amp=1):
    y=np.zeros(int(SR*length))
    if kind=='bark':
        tt=np.arange(len(y))/SR
        ph=2*np.pi*(104*tt+18*tt*tt)
        y+=(np.sin(ph)+.23*np.sin(2.6*ph))*(np.sin(np.pi*tt/length)**2)*np.exp(-tt*6)
        friction(y,.005,length-.015,.3,rng,125,1400,47)
    elif kind=='drip':
        bump(y,0,.42,[780,1410,2240],[.090,.035,.019],rng,.16,.13)
    elif kind=='clock':
        bump(y,0,.47,[490,1370,2840],[.018,.009,.005],rng,.10,.17)
    elif kind=='door':
        bump(y,0,.63,[83,165,390],[.19,.13,.063],rng,.27,.42)
    elif kind=='step':
        bump(y,0,.48,[120,228,520],[.09,.05,.024],rng,.23,.36)
    elif kind=='tool':
        bump(y,0,.65,[420,1160,2390],[.07,.047,.026],rng,.18,.2)
    return y*amp

def ambience(kind,rng:np.random.Generator)->np.ndarray:
    size=SR*60
    # Stable but not sterile: distinct low airflow, textured air, structure buzz.
    l=cyclic_field(rng,size,55,310);r=cyclic_field(rng,size,55,310)
    l=.65*l+.37*cyclic_field(rng,size,260,2800)
    r=.65*r+.37*cyclic_field(rng,size,260,2800)
    deep_l=cyclic_field(rng,size,40,110);deep_r=cyclic_field(rng,size,40,110)
    l=l+.35*deep_l;r=r+.36*deep_r
    # Temporal envelopes are periodic over exactly 60 s.
    tt=np.arange(size,dtype=np.float32)/SR
    swell=1+.14*np.sin(2*np.pi*2*tt/60+.3)+.09*np.cos(2*np.pi*7*tt/60)
    l*=swell;r*=1.01*swell
    if kind=='stairwell_day':
        for i in range(3):
            add_spatial(l,r,10.8+i*.28,env_event('bark',rng,.32),.15,-.68,.035,.12)
            add_spatial(l,r,41.6+i*.33,env_event('bark',rng,.28),.11,-.72,.041,.13)
        for i in range(7):add_spatial(l,r,23+i*.61,env_event('step',rng),.055,.4,.035,.34)
        # Radio behind a wall: random breath-like filtered noise, no syllables
        # or identifiable voice/music, intentionally not sampled speech.
        radio=cyclic_field(rng,size,240,850)
        gate=(.23+.35*np.sin(2*np.pi*263*tt/60)**2)*(.6+.4*np.cos(2*np.pi*71*tt/60)**2)
        l+=.033*radio*gate;r+=.015*radio*gate
    elif kind=='stairwell_evening':
        for i in range(8):add_spatial(l,r,13.8+i*.66,env_event('step',rng),.07,-.5,.023,.35)
        for t in [28.35,44.72]:add_spatial(l,r,t,env_event('door',rng,.51),.095,.2,.045,.5)
        l*=.82;r*=.82
    elif kind=='stairwell_night':
        l*=.62;r*=.61
        t=3.6
        while t<58:
            add_spatial(l,r,t,env_event('drip',rng,.33),.10,.47,.015,.24)
            t+=3.2+rng.uniform(.4,3.6)
    elif kind=='courtyard_rain':
        rainl=cyclic_field(rng,size,480,11500);rainr=cyclic_field(rng,size,480,11500)
        l=.46*l+.6*rainl;r=.46*r+.6*rainr
        t=1.3
        while t<58.5:
            add_spatial(l,r,t,env_event('drip',rng,.17),rng.uniform(.025,.06),rng.uniform(-.75,.75),.004,.08)
            t+=rng.uniform(.23,.67)
        # Low, occasional gutter splash.
        for t in [11.8,28.2,47.3]:add_spatial(l,r,t,env_event('drip',rng,.4),.12,-.45,.024,.18)
    elif kind=='workshop':
        l*=.65;r*=.64
        for i in range(60):
            add_spatial(l,r,i+.23,env_event('clock',rng,.1),.10,-.35,.003,.12)
            add_spatial(l,r,i+.73,env_event('clock',rng,.1),.07,-.28,.003,.12)
        # Subtle distant tram: moving rolling hum and wheel vibration.
        for t0,dur,intensity in [(12,10,.09),(40.5,8,.065)]:
            ix=int(t0*SR);n=int(dur*SR);t=np.arange(n)/SR
            env=np.sin(np.pi*t/dur)**2
            tram=intensity*env*(np.sin(2*np.pi*(64*t+.52*t*t))+.3*np.sin(2*np.pi*103*t)+.18*np.sin(2*np.pi*164*t))
            l[ix:ix+n]+=tram*.7;r[ix:ix+n]+=tram*.9
        for t in [29.4,33.1]:add_spatial(l,r,t,env_event('tool',rng,.25),.07,.3,.007,.2)
    else:raise ValueError(kind)
    data=np.column_stack((l,r)).astype('float32')
    meter=pyln.Meter(SR,block_size=.4)
    original=float(meter.integrated_loudness(data))
    data*=10**((-18-original)/20)
    # Conservative crest limiting without peak clipping, then remeasure.
    peak=float(np.max(np.abs(data)))
    if peak>.94:
        data=np.tanh(data/(peak/.88)).astype('float32')*.88
        current=float(meter.integrated_loudness(data))
        gain=10**((-18-current)/20)
        if float(np.max(np.abs(data)))*gain<=.97:data*=gain
    return data

def append_loop_metadata(path:Path,frames:int):
    # Standard RIFF 'smpl' chunk, forward loop 0..frames-1 (inclusive).
    fields=[0,0,round(1_000_000_000/SR),60,0,0,0,1,0]
    smpl=struct.pack('<9I',*fields)+struct.pack('<6I',0,0,0,frames-1,0,0)
    with path.open('r+b') as f:
        f.seek(0,2);f.write(b'smpl'+struct.pack('<I',len(smpl))+smpl)
        size=f.tell();f.seek(4);f.write(struct.pack('<I',size-8))

def write_wave(root:Path,rel:str,y:np.ndarray,desc_pl:str,desc_en:str,method:str,records:list):
    path=root/rel;path.parent.mkdir(parents=True,exist_ok=True)
    sf.write(path,y,SR,format='WAV',subtype='PCM_24')
    if y.ndim==2:append_loop_metadata(path,len(y))
    with sf.SoundFile(path) as s:
        assert s.samplerate==SR and s.subtype=='PCM_24'
        assert s.channels==(2 if y.ndim==2 else 1)
    peak=20*np.log10(max(1e-14,float(np.max(np.abs(y)))))
    d={'file':rel,'description_pl':desc_pl,'description_en':desc_en,
       'method':method,'sample_rate':SR,'bits_per_sample':24,'channels':2 if y.ndim==2 else 1,
       'frames':len(y),'duration_s':round(len(y)/SR,6),'peak_dbfs':round(peak,3),
       'size_bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
       'created':DATE,'edited':True,'editing':'automatic finishing: DC removal, fades and normalization' if y.ndim==1 else 'automatic seamless wrap, -18 LUFS normalization and RIFF smpl loop metadata'}
    if y.ndim==2:
        d['integrated_lufs']=round(float(pyln.Meter(SR).integrated_loudness(y)),3)
        d['loop_samples']=[0,len(y)-1]
        d['seam_step']=round(float(np.max(np.abs(y[0]-y[-1]))),6)
    else:
        threshold=np.max(np.abs(y))*10**(-30/20)
        indices=np.where(np.abs(y)>=threshold)[0]
        d['onset_ms']=round(float(indices[0]*1000/SR),4) if len(indices) else None
    records.append(d)
    print(f"{rel}: {d['duration_s']:>6.2f}s {d['peak_dbfs']:>6.2f} dBFS"+(f" {d.get('integrated_lufs')} LUFS" if y.ndim==2 else f" onset {d['onset_ms']} ms"),flush=True)

def main():
    p=argparse.ArgumentParser();p.add_argument('--out',type=Path,default=Path(__file__).resolve().parent)
    p.add_argument('--seed',type=int,default=RNG_SEED);args=p.parse_args()
    root=args.out;root.mkdir(parents=True,exist_ok=True)
    rng=np.random.default_rng(args.seed)
    records=[]
    for material,stem,pl,en in [('wood','step_wood','Krok po drewnianych schodach','Step on wooden staircase'),('terrazzo','step_terrazzo','Krok po lastryko','Footstep on terrazzo')]:
        for v in range(1,9):
            write_wave(root,f'foley/{stem}_{v:02}.wav',step(material,v,rng),f'{pl}; wariant {v}',f'{en}; variation {v}',f'original modal heel/toe synth; material={material}; variation={v}; seed={args.seed}',records)
    for v in range(1,7):
        tone='nieśmiały' if v<=2 else 'stanowczy' if v<=4 else 'pilny, autorytatywny (bez syren)'
        write_wave(root,f'foley/door_knock_{v:02}.wav',knock(v,rng),f'Stukanie do drzwi: {tone}; wariant {v}',f'Door knock: {tone}; variation {v}',f'original resonant wood contact series; {tone}; variation={v}; seed={args.seed}',records)
    for v in range(1,4):
        write_wave(root,f'foley/apartment_bell_{v:02}.wav',bell(v,rng),f'Wymyślony stary dzwonek mieszkania; wariant {v}',f'Original old-fashioned apartment bell; variation {v}',f'original fictional chime + electromechanical coil; variation={v}; seed={args.seed}',records)
    for v in range(1,3):
        write_wave(root,f'foley/timer_switch_{v:02}.wav',switch(v,rng),f'Klik włącznika światła na minutnik; wariant {v}',f'Timed stair-light switch click; variation {v}',f'original resonant bakelite/metal switch contact; variation={v}; seed={args.seed}',records)
        write_wave(root,f'foley/timer_ticking_{v:02}.wav',timer(v,rng),f'Tykanie starego minutnika; wariant {v}',f'Old staircase timer ticking; variation {v}',f'original timer ticks at {4 if v==1 else 2} Hz; variation={v}; seed={args.seed}',records)
        write_wave(root,f'foley/light_bulb_off_{v:02}.wav',bulb(v,rng),f'Wygaśnięcie żarówki, z towarzyszącym lekkim trzaskiem wyłącznika; wariant {v}',f'Bulb goes out, subtle switch release; variation {v}',f'original switch release and subtle filament tone; variation={v}; seed={args.seed}',records)
    for v in range(1,6):
        write_wave(root,f'foley/door_hinge_{v:02}.wav',hinge(v,rng),f'Skrzypienie zawiasów otwieranych drzwi; wariant {v}',f'Opening door hinge squeak; variation {v}',f'original damped hinge stick-slip friction; variation={v}; seed={args.seed}',records)
    for v in range(1,4):
        write_wave(root,f'foley/door_handle_{v:02}.wav',handle(v,rng),f'Szczęk klamki i zapadki; wariant {v}',f'Door handle/latch clack; variation {v}',f'original metal latch resonance and slip; variation={v}; seed={args.seed}',records)
    for kind,pl,en in [
        ('stairwell_day','Klatka schodowa w dzień: daleki pies, radio bez muzyki za ścianą','Daytime stairwell, distant dog and unintelligible wall-muffled radio noise'),
        ('stairwell_evening','Klatka schodowa wieczorem: kroki, zamykanie drzwi','Evening stairwell, footsteps and distant door closing'),
        ('stairwell_night','Klatka schodowa nocą: cisza budynku i kapanie','Night stairwell, building room tone and occasional drips'),
        ('courtyard_rain','Podwórko podczas deszczu: szum deszczu i rynny','Rainy courtyard, rain wash and sparse gutter drips'),
        ('workshop','Warsztat: zegar na ścianie i daleki przejazd tramwaju','Workshop, wall clock and distant tram pass')]:
        a=ambience(kind,rng)
        write_wave(root,f'ambience/{kind}.wav',a,pl,en,f'original colored stochastic periodic field, spatial modal events, EBU-R128 -18 LUFS, 60s seam; scene={kind}; seed={args.seed}',records)
    (root/'manifest.json').write_text(json.dumps({'project':'Lockwright','order':'S02','tool':'Python 3 + NumPy + SciPy + SoundFile + pyloudnorm',
        'method':'original procedural synthesis, no sampled recordings','seed':args.seed,'created':DATE,'files':records},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'DONE: {len(records)} audio files. {sum(e["size_bytes"] for e in records)/1e6:.1f} MB',flush=True)

if __name__=='__main__':main()
