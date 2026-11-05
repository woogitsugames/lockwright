#!/usr/bin/env python3
"""Lockwright S03v2: original non-lexical character voice synthesizer.

Requirements: Python 3.10+, numpy, scipy, soundfile, pyloudnorm.
Run from any directory; WAV files are produced next to this script.
No voice recordings, cloned voices or external speech services are used.
"""
from __future__ import annotations
import json
import math
from pathlib import Path
import numpy as np
import scipy
from scipy.signal import lfilter
import soundfile as sf
import pyloudnorm as pyln

SR=48000
ROOT=Path(__file__).resolve().parent
TARGET_LUFS=-28.0
EVENTS={
    'greeting':  dict(seconds=.72, notes=(0,2,0), vowel='m', beats=(.002,.995), dynamics=.93),
    'surprise':  dict(seconds=.69, notes=(0,5,3), vowel='a', beats=(.002,.995), dynamics=1.0),
    'relief':    dict(seconds=1.04,notes=(2,0,-3),vowel='u', beats=(.002,.995), dynamics=.78),
    'thanks':    dict(seconds=.87, notes=(0,2,-1),vowel='o', beats=(.002,.40,.49,.995), dynamics=.90),
    'impatient': dict(seconds=.89, notes=(1,-1,-3),vowel='m', beats=(.002,.37,.48,.995), dynamics=.90),
    'sad':       dict(seconds=1.12,notes=(0,-2,-5),vowel='u', beats=(.002,.995), dynamics=.68),
    'laugh':     dict(seconds=1.08,notes=(1,3,0),vowel='a', beats=(.002,.21,.24,.44,.47,.67,.70,.995), dynamics=.96),
    'goodbye':   dict(seconds=.78, notes=(1,0,-3),vowel='o', beats=(.002,.995), dynamics=.77),
}
# id, label, age, register/pitch, breath, grain, manner; synthetic pitch/formants only.
P=[
('agnieszka','Agnieszka',45,'f',183,.22,.10,'spokojna, opiekuńcza pielęgniarka'),
('aino','Aino',50,'f',174,.15,.16,'rzeczowa fińska mechanik okrętowa'),
('bartek','Bartek',29,'m',138,.17,.04,'roześmiany pan młody'),
('basia','Basia',42,'f',205,.13,.07,'dokładna sekretarka wspólnoty'),
('bride','Panna młoda',28,'f',234,.17,.06,'poruszona, pogodna'),
('captain','Kapitan',55,'m',111,.15,.23,'stanowczy, opanowany'),
('claimant','Kobieta przy drzwiach',34,'f',201,.18,.17,'niepewna, zdenerwowana'),
('darek','Darek',40,'m',148,.23,.19,'zdenerwowany, natarczywy'),
('elzbieta','Elżbieta',47,'f',184,.11,.08,'rzeczowa zarządczyni'),
('ewa','Ewa',46,'f',202,.16,.08,'zdecydowana siostra'),
('gosia','Gosia',36,'f',197,.13,.07,'spokojna renowatorka'),
('hall_manager','Kierownik sali',44,'m',136,.18,.11,'nieco zniecierpliwiony'),
('hania','Hania',7,'child',341,.12,.01,'dziecko, radosna i ciekawa'),
('headteacher','Dyrektorka szkoły',54,'f',174,.12,.13,'uprzejma, zdecydowana'),
('iga','Iga',27,'f',223,.12,.06,'energiczna perkusistka'),
('irena','Irena',79,'f',151,.30,.24,'starsza, cicha bibliotekarka'),
('jacques','Jacques',58,'m',133,.18,.16,'uprzejmy, przyjazny sąsiad'),
('kazimierz','Kazimierz',60,'m',127,.24,.24,'wesoły i nieco zamyślony'),
('krysia','Krysia',65,'f',177,.23,.22,'doświadczona, serdeczna'),
('kuba','Kuba',23,'m',166,.15,.08,'młody, nieco zdenerwowany'),
('leopold','Leopold',70,'m',111,.26,.28,'starszy antykwariusz, łagodny'),
('magda','Magda',41,'f',202,.17,.09,'żywa tłumaczka'),
('marcel','Marcel',29,'m',150,.18,.13,'zabiegany kurier'),
('marek','Marek',43,'m',142,.11,.12,'ostrożny spadkobierca'),
('martine','Martine',64,'f',177,.19,.20,'dostojna, serdeczna'),
('mietek','Mietek',62,'m',124,.23,.26,'starszy rzemieślnik'),
('nadia','Nadia',29,'f',224,.12,.06,'energiczna piekarka'),
('neighbour_lucyna','Sąsiadka Lucyny',61,'f',170,.22,.16,'troskliwa, dyskretna'),
('neighbour_robe','Sąsiad w szlafroku',52,'m',135,.29,.19,'zaspany, zirytowany'),
('norbert','Norbert',43,'m',147,.17,.10,'zaniepokojony o siostrę'),
('pieter','Pieter',66,'m',122,.19,.19,'spokojny opiekun domu'),
('piotr','Piotr',38,'m',146,.17,.11,'praktyczny brat'),
('renata','Renata',52,'f',218,.16,.13,'szybka i rezolutna właścicielka pizzerii'),
('stranger','Mężczyzna w garniturze',39,'m',132,.10,.08,'grzeczny, naciskający'),
('teresa','Teresa',68,'f',174,.22,.19,'serdeczna, powściągliwa'),
('tomasz','Tomasz',37,'m',141,.17,.11,'cierpliwy stolarz, ojciec Hani'),
('waldek','Waldek',59,'m',121,.18,.21,'rzeczowy sąsiad'),
('wanda','Wanda',63,'f',165,.16,.16,'konkretna zarządczyni kamienicy'),
('zbyszek','Zbyszek',74,'m',114,.29,.26,'starszy działkowiec, pogodny'),
]
assert len(P)==39 and len(set(x[0] for x in P))==39
assert list(EVENTS)==['greeting','surprise','relief','thanks','impatient','sad','laugh','goodbye']
METER=pyln.Meter(SR, block_size=.400)


def pulse_envelope(n, spec, shift):
    """Smooth onset/decay per nonverbal exhalation; events contain no phonemes."""
    t=np.arange(n, dtype=np.float64)/n
    result=np.zeros(n,dtype=np.float64)
    intervals=spec['beats']
    for j in range(0,len(intervals),2):
        start,end=intervals[j],intervals[j+1]
        rel=(t-start)/max(end-start,1e-6)
        gate=(rel>=0)&(rel<=1)
        v=np.zeros(n)
        u=rel[gate]
        # fast (<15ms) but smooth onset; last ~50ms fades softly
        rise=np.minimum(u/.035,1.0)
        fall=np.minimum((1.0-u)/.095,1.0)
        v[gate]=np.minimum(np.sin(np.minimum(rise,1)*np.pi/2),1) * np.maximum(fall,0)**1.2
        result+=v*(1.0 if j==0 else (.94-0.05*shift))
    return np.clip(result,0,1)


def sine_tone(n,freq,phase,partials):
    """Additive glottal source, not a speech sample."""
    res=np.zeros(n)
    for h,coef in partials:
        res+=coef*np.sin(phase*h+(h*.18))
    return res


def formant(x,f,q):
    # Stable resonator using normalized IIR peak.
    w=2*np.pi*f/SR
    alpha=np.sin(w)/(2*q)
    b=np.array([alpha,0,-alpha])/(1+alpha)
    a=np.array([1,-2*np.cos(w)/(1+alpha),(1-alpha)/(1+alpha)])
    return lfilter(b,a,x)


def generate(profile,event,person_index,event_index):
    id,label,age,sex,base,breath,grain,manner=profile
    d=EVENTS[event]
    # Each id has a stable unique seed and formant constellation.
    rng=np.random.default_rng(311711+person_index*2099+event_index*127)
    secs=d['seconds']*(.91+(.025*(person_index%7)))
    n=int(secs*SR)
    t=np.arange(n)/SR
    u=t/secs
    pitch_notes=np.interp(u,[0,.42,1],d['notes'])
    if sex=='child': ff=(860,2200,3310); nasal=.30
    elif sex=='f': ff=(590,1600,2950); nasal=.28
    else: ff=(500,1260,2460); nasal=.34
    formant_mod=(person_index%9-4)*16
    voice_mod=(person_index%7-3)*9
    # Stable single-vowel, pitched hum, no syllables / lexical sequence.
    vowels={'m':(-120,-220,-260), 'a':(170,240,110), 'o':(-50,-100,-50),'u':(-145,-175,-190)}
    v1,v2,v3=vowels[d['vowel']]
    f0=base*2**(pitch_notes/12)*(
        1+(.003+grain*.016)*np.sin(2*np.pi*(4.2+.23*(person_index%5))*t)
          +grain*.002*np.sin(2*np.pi*13.0*t)
    )
    phase=2*np.pi*np.cumsum(f0)/SR
    src=sine_tone(n,f0,phase,[(1,1), (2,.41), (3,.27), (4,.18), (5,.13), (6,.08)])
    src=src/(1.9)
    # Mild creak/jitter for senior voices, breath/noise for more elderly voices.
    nois=rng.normal(0,1,n)
    b=nois*.055*(breath+.08)
    f1,f2,f3=ff
    sound=(1.3*formant(src,f1+v1+formant_mod,4.5) + .85*formant(src,f2+v2+voice_mod,6.0)
          + .38*formant(src,f3+v3+formant_mod,8.0) + .30*src)
    nasality=formant(src,280+formant_mod*.35,2.2)*nasal*.32
    sound+=nasality+b +grain*.019*np.tanh(src*3.3)
    # Impatience: slight creak. Sad: softer low-pass feeling. Laugh: several breath pulses.
    if event=='laugh': sound+=nois*.026
    if event=='sad': sound=.83*sound
    env=pulse_envelope(n,d,person_index%5)
    # Output after 0.0s: fade from 0 to audibility within 10ms.
    fade=np.minimum(t/.006,1)
    sound*=env*fade*d['dynamics']
    # DC and small smoothing (avoid digital clicks).
    sound=sound-np.mean(sound)
    y=sound.astype(np.float64)
    loud=METER.integrated_loudness(y)
    if not np.isfinite(loud): raise RuntimeError(f'Invalid LUFS: {id}/{event}={loud}')
    y=pyln.normalize.loudness(y,loud,TARGET_LUFS)
    peak=float(np.max(np.abs(y)))
    if peak>.97: y*=.97/peak
    # Keep precise target by adjusting normalized peak only if it was over tolerance.
    loud2=float(METER.integrated_loudness(y))
    return y.astype(np.float32),loud2


def onset_ms(y):
    # Relative to peak; -38dB threshold constitutes audibility for QA.
    th=np.max(abs(y))*10**(-38/20)
    idx=np.flatnonzero(np.abs(y)>=th)
    if not len(idx):return (float('inf'),float('inf'))
    return (idx[0]*1000/SR, (len(y)-1-idx[-1])*1000/SR)


def main():
    manifests={}
    voices=ROOT/'voices'
    for idx,p in enumerate(P):
        id,label,age,sex,f0,breath,grain,manner=p
        files=[]
        (voices/id).mkdir(parents=True,exist_ok=True)
        for j,event in enumerate(EVENTS):
            data,lufs=generate(p,event,idx,j)
            fname=f'voices/{id}/{event}.wav'
            sf.write(ROOT/fname,data,SR,subtype='PCM_16')
            start,tail=onset_ms(data)
            files.append(dict(file=fname,seconds=round(len(data)/SR,4),LUFS=round(lufs,2),onset_ms=round(start,2),tail_ms=round(tail,2)))
            assert 0.3<=len(data)/SR<=1.5,(id,event)
            assert -29.0<=lufs<=-27.0,(id,event,lufs)
            assert start<=20,(id,event,start)
            assert tail<=100,(id,event,tail)
        manifests[id]={
            'character':label,'age':age,'voice_register':sex,'personality':manner,
            'files':files
        }
    assert sum(len(x['files']) for x in manifests.values())==312
    (ROOT/'manifest.json').write_text(json.dumps({
       'format':'48 kHz PCM16 mono WAV', 'target_LUFS_momentary': TARGET_LUFS,
       'method':'deterministic formant-based, non-lexical synthesized vocalizations',
       'voices': manifests},ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('Created',len(manifests),'characters,',sum(len(x['files']) for x in manifests.values()),'WAV clips')
    return manifests

if __name__=='__main__':main()
