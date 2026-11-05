#!/usr/bin/env python3
"""Original procedural, sample-free quiet enamel-plate UI sounds for Lockwright."""
from __future__ import annotations
import hashlib
import json
import math
import wave
from pathlib import Path

import numpy as np
import pyloudnorm as pyln
from scipy.signal import butter, sosfilt

OUT = Path(__file__).resolve().parent
SFX = OUT / 'sfx'
RATE = 48000
RNG_SEED = 5051905
METER = pyln.Meter(RATE, block_size=0.400)


def colored_noise(rng, n, lo, hi):
    raw = rng.standard_normal(n)
    if hi >= RATE/2:
        hi = RATE/2-100
    if lo <= 0:
        sos = butter(3, hi, fs=RATE, btype='lowpass', output='sos')
    else:
        sos = butter(3, [lo, hi], fs=RATE, btype='bandpass', output='sos')
    result = sosfilt(sos, raw)
    result = result / max(1e-12, np.std(result))
    return result


def gate_fade(sig, fade_in, fade_out):
    n = len(sig)
    a = int(RATE*fade_in)
    b = int(RATE*fade_out)
    if a:
        sig[:a] *= np.sin(np.linspace(0,math.pi/2,a,endpoint=True))**2
    if b:
        sig[-b:] *= np.cos(np.linspace(0,math.pi/2,b,endpoint=True))**2
    sig[-1] = 0.0
    return sig


def note(kind, variant):
    # Stable seed independent of call order and filenames.
    family_code = {'press': 1100, 'release': 2200, 'disabled': 3300, 'whoosh_soft': 4400}[kind]
    rng = np.random.default_rng(RNG_SEED + family_code + variant * 97)
    d = {'press': 0.109, 'release': 0.066, 'disabled': 0.071, 'whoosh_soft': 0.176}[kind]
    delta = {'press': 0.009, 'release': 0.008, 'disabled': 0.008, 'whoosh_soft': 0.018}[kind]
    d += (variant-1) * delta
    n = int(round(d*RATE))
    t = np.arange(n) / RATE
    shift = (variant-3.0)/5.0
    pitch = 1.0 + shift*0.055 + rng.uniform(-.012,.012)
    tilt = 1.0+shift*.075
    start = .0003
    u = np.maximum(0,t-start)
    h = (t>=start).astype(float)

    if kind in ('press', 'release', 'disabled'):
        low = colored_noise(rng, n, 50, 720 if kind != 'disabled' else 430)
        high = colored_noise(rng, n, 380, 5500 if kind=='press' else (3200 if kind=='release' else 1200))
        if kind == 'press':
            # Fingertip contact, solid wood under panel, then restrained enamel ring.
            burst = (.25*low + .27*high)*np.exp(-u/.0046)*h
            thump = .68*np.sin(2*np.pi*(205*pitch)*u + .5)*np.exp(-u/.041)*h
            ring = (.43*np.sin(2*np.pi*(805*pitch)*u+.23) * np.exp(-u/.068)
                   + .17*np.sin(2*np.pi*(1340*pitch)*u + 1.2)*np.exp(-u/.039))*h
            # Slight non-harmonic overtone makes the enamel distinct from brass.
            resonance = .07*np.sin(2*np.pi*(2110*pitch)*u+.33)*np.exp(-u/.029)*h
            x = (burst + thump + ring + resonance)*tilt
            gate_fade(x, .00065, .006)
        elif kind == 'release':
            burst=(.17*low+.15*high)*np.exp(-u/.0038)*h
            body=.55*np.sin(2*np.pi*170*pitch*u+.29)*np.exp(-u/.030)*h
            ring=(.19*np.sin(2*np.pi*910*pitch*u+.66)*np.exp(-u/.033))*h
            x= (burst + body + ring)*tilt
            gate_fade(x,.00055,.004)
        else:
            # Finger through cloth: low-pass thud and no metal overtone.
            burst=.31*low*np.exp(-u/.0077)*h
            body=.66*np.sin(2*np.pi*137*pitch*u + .24)*np.exp(-u/.036)*h
            x=(burst+body)*tilt
            x=sosfilt(butter(3,680,fs=RATE,btype='lowpass',output='sos'),x)
            gate_fade(x,.0008,.007)
    else:
        # Soft leather/paper brushing: broadband noise in a single contact, not an FX sweep.
        soft = colored_noise(rng,n,380 + 25*variant,3300 + 40*variant)
        coarse = colored_noise(rng,n,600,7500)
        r = np.clip((t + .011)/(d+.008),0,1)
        contour=np.sin(np.pi*r)**0.92
        contour *= (1+.11*np.sin(2*np.pi*(18 + variant*1.2)*t+variant))
        x=.55*np.tanh(3.2*(.28*soft +.09*coarse))*contour
        # A few tiny surface interruptions add a tactile texture without being clicks.
        for k in range(5):
            pos=d*(.18 + .12*k)+rng.uniform(-.004,.004)
            scratch=np.exp(-.5*((t-pos)/(.0032+rng.uniform(0,.001)))**2)
            x+=.065*soft*scratch
        gate_fade(x,.00075,.012)

    # Short SFX cannot be conventionally measured over a complete 400ms R128 block.
    # Measure a 400ms padded observation frame, state that method in manifest.
    padded=np.pad(x,(0,max(0,int(RATE*.4)-n)))
    before=float(METER.integrated_loudness(padded))
    if not np.isfinite(before):
        raise ValueError(f'LUFS measurement invalid: {kind} {variant}')
    target={'press':-24.0,'release':-26.5,'disabled':-28.5,'whoosh_soft':-28.0}[kind]
    target += rng.uniform(-0.28,.28)
    x*=10**((target-before)/20.)

    # Keep transients safe and close to the existing menu loudness envelope.
    peak=float(np.max(np.abs(x)))
    peak_lim={'press':-12.5,'release':-15.0,'disabled':-17.0,'whoosh_soft':-18.0}[kind]
    if peak > 10**(peak_lim/20):
        x*=10**(peak_lim/20)/peak
    # A gently sustained level envelope improves low-volume mobile playback.
    # Avoid brick-wall limiting: preserve sample sign and relative motion.
    # This compressor leaves the first touch audible and the plate resonance dry.
    power = {'press':.31,'release':.22,'disabled':.22,'whoosh_soft':1.0}[kind]
    if power != 1.0:
        original_peak=float(np.max(np.abs(x)))
        x=np.sign(x)*np.power(np.abs(x),power)
        x*=original_peak/max(1e-12,float(np.max(np.abs(x))))
    return x


def measure(signal):
    clip=np.pad(signal,(0,max(0,int(RATE*.4)-len(signal))))
    peak=float(np.max(np.abs(signal)))
    threshold=max(10**(-52/20),peak*10**(-42/20))
    loud=np.where(np.abs(signal)>threshold)[0]
    onset=(float(loud[0]/RATE*1000) if loud.size else None)
    tail=(float((len(signal)-1-loud[-1])/RATE*1000) if loud.size else None)
    return dict(
        duration_ms=round(len(signal)/RATE*1000,3),
        lufs_400ms_padded=round(float(METER.integrated_loudness(clip)),3),
        peak_dbfs=round(20*math.log10(max(1e-12,peak)),3),
        rms_dbfs=round(20*math.log10(max(1e-12,float(np.sqrt(np.mean(signal**2))))),3),
        onset_ms=round(onset,3) if onset is not None else None,
        trailing_silence_ms=round(tail,3) if tail is not None else None,
    )


def main():
    SFX.mkdir(parents=True,exist_ok=True)
    manifest = {
        'format':'WAV PCM signed 16-bit LE, mono, 48000 Hz',
        'measuring_method':'EBU R128 K-weighted 400 ms observation frame with zero padding; sub-400ms clips cannot have standard integrated LUFS. Measured from decoded int16 WAV.',
        'loudness_targets_lufs_400ms_padded': {'plate_press':-24.0,'plate_release':-26.5,'plate_disabled':-28.5,'screen_whoosh_soft':-28.0},
        'relative_onset_threshold':'max(-52 dBFS, -42 dB relative to peak)',
        'source':'Procedural synthesis, no third-party recordings or sample libraries',
        'seed':RNG_SEED,
        'files':[],
    }
    kinds=[('plate_press','press',6,80,180),('plate_release','release',6,40,120),('plate_disabled','disabled',3,40,120),('screen_whoosh_soft','whoosh_soft',3,150,250)]
    for prefix,kind,count,dmin,dmax in kinds:
        for i in range(1,count+1):
            f=SFX / f'{prefix}_{i:02}.wav'
            wave_data=note(kind,i)
            pcm=np.rint(np.clip(wave_data,-1,1)*32767).astype('<i2')
            with wave.open(str(f),'wb') as audio:
                audio.setnchannels(1);audio.setsampwidth(2);audio.setframerate(RATE)
                audio.writeframes(pcm.tobytes())
            raw=np.frombuffer(f.read_bytes()[44:],dtype='<i2').astype(np.float64)/32768
            m=measure(raw)
            m['filename']='sfx/'+f.name
            m['sha256']=hashlib.sha256(f.read_bytes()).hexdigest()
            m['sample_rate_hz']=RATE
            m['channels']=1
            m['sample_format']='pcm_s16le'
            assert dmin<=m['duration_ms']<=dmax,(f,m)
            assert m['onset_ms']<=5.0,(f,m)
            assert m['trailing_silence_ms']<=50.0,(f,m)
            assert m['peak_dbfs']<0,(f,m)
            manifest['files'].append(m)
    (OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for family in kinds:
        group=[f for f in manifest['files'] if f['filename'].split('/')[-1].startswith(family[0])]
        print(family[0],len(group),
            'duration',min(d['duration_ms'] for d in group),max(d['duration_ms'] for d in group),
            'LUFS',min(d['lufs_400ms_padded'] for d in group),max(d['lufs_400ms_padded'] for d in group),
            'peak',min(d['peak_dbfs'] for d in group),max(d['peak_dbfs'] for d in group))

if __name__ == '__main__': main()
