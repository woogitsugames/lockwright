#!/usr/bin/env python3
"""S01: deterministic, original procedural chamber score for Lockwright.

No samples, soundfonts, generative-audio API, or external composition data.
Requires numpy, scipy, soundfile, pyloudnorm, mido, matplotlib, ffmpeg.
Run: python render_music.py [--output DIR] [--only NAME]
All work is confined to the chosen output directory (normally this script's folder).
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import math
import os
from pathlib import Path
import shutil
import subprocess

import mido
import numpy as np
import pyloudnorm as pyln
import soundfile as sf
from scipy import signal

FS = 48000
BPM = 80
BEAT = 60.0 / BPM
BAR = 4 * BEAT
SEED = 520126
DATE = "2026-11-05"

# Original harmonies: C major with borrowed iv, extended dominants and gentle voice-leading.
HARMONY = [
    ("Cmaj9",  [36, 48, 55, 59, 62, 64]),
    ("Am9",    [33, 45, 52, 57, 60, 64]),
    ("Dm9",    [38, 50, 57, 60, 64, 65]),
    ("G13",    [31, 43, 53, 57, 62, 64]),
    ("Em7",    [40, 52, 55, 59, 62, 67]),
    ("A9",     [33, 45, 55, 61, 64, 71]),
    ("Dm9",    [38, 50, 57, 60, 64, 65]),
    ("G7sus",  [31, 43, 53, 60, 62, 65]),
    ("Fmaj9",  [41, 53, 57, 60, 64, 67]),
    ("Fm6",    [41, 53, 56, 60, 62, 65]),
    ("Cmaj9/E",[40, 52, 55, 59, 62, 64]),
    ("A7b9",   [33, 45, 55, 61, 64, 70]),
    ("Dm9",    [38, 50, 57, 60, 64, 65]),
    ("G13",    [31, 43, 53, 57, 62, 64]),
    ("C6/9",   [36, 48, 57, 62, 64, 67]),
    ("G13",    [31, 43, 53, 57, 62, 64]),
]

# The eight-bar hook was written for this score; not sampled or transcribed.
HOOK = [
    [(0.0,64,.62),(1.0,67,.61),(2.5,69,.38),(3.0,67,.64)],
    [(0.0,64,.95),(1.75,62,.65),(3.0,60,.64)],
    [(0.0,65,.85),(1.0,64,.64),(2.0,62,.72),(3.0,57,.55)],
    [(0.0,62,.85),(1.5,64,.64),(2.5,65,.43),(3.5,67,.38)],
    [(0.0,67,.89),(1.5,71,.64),(2.5,69,.45)],
    [(0.0,67,.82),(1.0,64,.62),(2.0,61,.79)],
    [(0.0,65,.86),(1.25,64,.65),(2.5,62,.72)],
    [(0.0,62,.90),(1.5,59,.65),(3.0,62,.41)],
]

@dataclass(frozen=True)
class Note:
    start: float
    length: float
    midi: int
    velocity: float
    kind: str


def midi_hz(note: int) -> float:
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def score_main() -> tuple[list[Note], float]:
    events = []
    for b in range(24):
        harm = HARMONY[(b % 8) if b < 16 else ((b + 8) % 16)]
        _,chord = harm
        root = chord[1] - 12
        sec = b * BAR
        # Sparse, humanized low upright bass; no walking-bass swagger.
        for beat, n, d, v in [(0,root,1.20,.44),(2.55,chord[2]-24,.55,.29)]:
            events.append(Note(sec + beat * BEAT, d * BEAT, n, v, "bass"))
        voicing = sorted(set(chord[3:6]))
        for beat,d,v in ((0,.94,.36),(2.05,.66,.27)):
            for ni,n in enumerate(voicing):
                events.append(Note(sec + beat * BEAT + .016 * ni, d * BEAT, n, v * (1 if ni==1 else .88), "piano"))
        if b != 23:
            for k,(beat,n,d) in enumerate(HOOK[b % 8]):
                # Microvariation after initial presentation; identical harmonic footprint.
                note = n + (12 if b == 12 and k == 0 else 0)
                vel = .45 if b >= 16 else .50
                events.append(Note(sec+beat*BEAT+.012, d*BEAT, note,vel,"piano"))
        if 7 <= b <= 16 and b % 2 == 1:
            for beat,n,d in ((.7,chord[4],1.2),(2.40,chord[5],.8)):
                events.append(Note(sec+beat*BEAT, d*BEAT,n,.30,"clarinet"))
        for beat,v in ((1,.16),(3,.12)):
            events.append(Note(sec+beat*BEAT,.19,38,v,"brush"))
    # Last bar resolves without a sharp finale; tail is allowed to decay.
    events += [Note(23*BAR,1.55,60,.36,"piano"),Note(23*BAR,1.55,64,.30,"piano")]
    return events,24*BAR


def score_menu() -> tuple[list[Note], float]:
    events=[]
    rng=np.random.default_rng(SEED)
    for b in range(48):
        _, chord = HARMONY[b%16]
        sec=b*BAR
        root=chord[1]-12
        events.append(Note(sec,.83*BEAT,root,.36,"bass"))
        if b%4 != 3:
            events.append(Note(sec+2.48*BEAT,.53*BEAT,chord[2]-24,.23,"bass"))
        for idx,(beat,d,v) in enumerate(((.10,1.2,.26),(2.12,.78,.24))):
            if b%8==7 and idx==1:
                continue
            ns=sorted(set(chord[3:6]))
            for j,n in enumerate(ns):
                events.append(Note(sec+beat*BEAT + .009*j,d*BEAT,n,v*(.80+.08*j),"piano"))
        # Loosely improvised original piano answer, never busy in the workshop.
        if b%4 in (0,2):
            choices = sorted(set(chord[3:6]))
            pitches = rng.choice(choices,size=2,replace=False)
            for beat,n in ((1.24,int(pitches[0])),(3.25,int(pitches[1]))):
                events.append(Note(sec+beat*BEAT,.49*BEAT,n,.25,"piano"))
        if 16<=b<33 and b%4 in (1,2):
            for beat,n in ((.70,chord[4]),(2.45,chord[5])):
                events.append(Note(sec+beat*BEAT,1.00*BEAT,n,.20,"clarinet"))
        for beat,v in ((1.0,.10),(3.0,.08)):
            events.append(Note(sec+beat*BEAT,.14,38,v,"brush"))
    return events,48*BAR


def score_lock() -> tuple[list[Note], float]:
    # Slow overlapping chords, no pulse, bass, percussion or high notes.
    chords=[HARMONY[i][1] for i in [0,1,2,3,8,9,10,15]]
    notes=[]
    for i, chord in enumerate(chords):
        for n in [chord[1],chord[2],chord[3]]:
            notes.append(Note(i*15,15,n,.24,"pad"))
    return notes,120.0


def score_jingle(name: str) -> tuple[list[Note],float]:
    # Six distinct, restrained bookends; every interval chosen for this project.
    specs={
     "door_open": (3.2, [(0.00,60,.46,.41,"piano"),(.38,64,.56,.37,"piano"),
      (.83,67,.60,.42,"piano"),(1.40,69,1.25,.31,"clarinet"),
      (1.40,60,1.14,.28,"piano"),(1.40,64,1.14,.25,"piano")]),
     "dignified_refusal": (3.1,[(.05,65,.73,.24,"piano"),(.70,64,.73,.24,"piano"),
      (1.42,62,.96,.21,"piano"),(1.42,53,1.13,.18,"bass"),
      (1.47,60,1.12,.19,"piano")]),
     "new_chapter": (3.65,[(.00,60,.40,.39,"piano"),(.31,62,.50,.36,"piano"),
      (.70,64,.48,.36,"piano"),(1.12,67,.65,.41,"piano"),
      (1.75,72,1.10,.36,"clarinet"),(1.78,60,1.14,.26,"piano"),
      (1.78,67,1.13,.29,"piano")]),
     "new_tool": (2.65,[(.04,64,.28,.37,"piano"),(.27,67,.31,.35,"piano"),
      (.64,69,.43,.35,"piano"),(1.16,62,.84,.29,"piano"),
      (1.16,69,.84,.29,"piano")]),
     "showcase_exhibit": (3.45,[(0.0,67,.56,.29,"piano"),(.60,71,.68,.32,"piano"),
      (1.27,74,1.20,.29,"piano"),(1.28,59,1.29,.22,"piano"),
      (1.29,62,1.27,.23,"piano"),(1.35,67,1.19,.19,"clarinet")]),
     "end_of_day": (3.75,[(.06,69,.78,.27,"clarinet"),(.60,67,.85,.25,"piano"),
      (1.20,64,.95,.30,"piano"),(1.90,60,1.18,.29,"piano"),
      (1.92,57,1.18,.22,"piano"),(1.97,48,1.08,.24,"bass")]),
    }
    dur, notes = specs[name]
    return [Note(t,d,m,v,k) for t,m,d,v,k in notes],dur


def synth_note(note: Note,rng: np.random.Generator) -> np.ndarray:
    """Dry original synthesis: detuned damped bars/strings, no third-party waveforms."""
    f=midi_hz(note.midi)
    kind=note.kind
    if kind=="brush":
        dur=.165
        n=max(1,int(dur*FS))
        z=rng.standard_normal(n).astype(np.float32)
        z=signal.sosfilt(signal.butter(2,[360,2000],btype="bandpass",fs=FS,output="sos"),z)
        t=np.arange(n,dtype=np.float64)/FS
        env=(1-np.exp(-t/0.007))*np.exp(-t/0.042)
        return (.25*note.velocity*z*env).astype(np.float32)
    tail={"piano":.80,"bass":.49,"clarinet":.21}[kind]
    dur=note.length+tail
    n=int(round(dur*FS))
    t=np.arange(n,dtype=np.float64)/FS
    if kind=="piano":
        weights=[1.,.46,.25,.135,.067,.035]
        f_bend=0.00016
        tau=1.65 * np.sqrt(261.63/f)
        y=np.zeros(n,dtype=np.float64)
        for k,weight in enumerate(weights,1):
            fk=f*k*np.sqrt(1+f_bend*k*k)
            tone=np.sin(2*np.pi*fk*t+(.13*k))
            y+=weight*tone*np.exp(-t/(tau/(.78+.25*k)))
        # Soft felt hammer: impact is not sharp or metallic.
        env=(1-np.exp(-t/.007))*np.exp(-np.maximum(t-note.length,0)/.18)
        y *= env
        attack_n=min(1400,n)
        hammer=rng.standard_normal(attack_n)
        hammer=signal.sosfilt(signal.butter(3,1700,fs=FS,output="sos"),hammer)
        y[:attack_n]+=.034*hammer*np.exp(-np.arange(attack_n)/410)
        return (.067*note.velocity*y).astype(np.float32)
    if kind=="bass":
        y=np.zeros(n,dtype=np.float64)
        for k,w in enumerate([1.0,.38,.21,.10,.055],1):
            y += w*np.sin(2*np.pi*f*k*t + 0.08*k)*np.exp(-t/(.76/(.75+.26*k)))
        env=(1-np.exp(-t/.006))*np.exp(-np.maximum(t-note.length,0)/.11)
        return (.095*note.velocity*y*env).astype(np.float32)
    # Clarinet: predominantly odd harmonics, warm woody, unobtrusive.
    y=np.zeros(n,dtype=np.float64)
    for k,w in [(1,1.),(3,.21),(5,.095),(7,.025)]:
        y+= w*np.sin(2*np.pi*f*k*t)*np.exp(-t/6.0)
    at=np.minimum(1.0,t/.085)
    rel=np.minimum(1.0,np.maximum(note.length-t,0)/.19)
    env=(at*at*(3-2*at))*(rel*rel*(3-2*rel))
    return (.041*note.velocity*y*env).astype(np.float32)


def put_wrap(out: np.ndarray, voice: np.ndarray, start: int, pan: float) -> None:
    length=len(out)
    start=start % length
    lg=math.sqrt(.5*(1-pan))
    rg=math.sqrt(.5*(1+pan))
    end=min(length,start+len(voice))
    part=voice[:end-start]
    out[start:end,0] += lg*part
    out[start:end,1] += rg*part
    if end-start<len(voice):
        rest=voice[end-start:]
        out[:len(rest),0]+=lg*rest
        out[:len(rest),1]+=rg*rest


def render_percussion_and_instruments(notes: list[Note], duration:float) -> np.ndarray:
    rng=np.random.default_rng(SEED + len(notes))
    out=np.zeros((int(round(duration*FS)),2),dtype=np.float32)
    for i,note in enumerate(notes):
        if note.kind == "pad":
            continue
        sample=synth_note(note,rng)
        pan={"piano":(-.19+.09*(i%4)),"bass":-.03,"brush":.17,"clarinet":.20}[note.kind]
        put_wrap(out,sample,int(round(note.start*FS)),pan)
    # Original minimal periodic room response (no sourced impulse-response samples).
    for c in range(2):
        dry=out[:,c].copy()
        cross=out[:,1-c]
        out[:,c] += .053*np.roll(dry,int(.083*FS))+.038*np.roll(cross,int(.132*FS))
    return out


def render_pad(duration:float) -> np.ndarray:
    n=int(round(duration*FS)); t=np.arange(n,dtype=np.float64)/FS
    out=np.zeros((n,2),dtype=np.float32)
    chords=[HARMONY[i][1] for i in (0,1,2,3,8,9,10,15)]
    step=duration/len(chords)
    fade=3.0
    for ci,chord in enumerate(chords):
        local=np.remainder(t-ci*step,duration)
        local=np.where(local>duration-fade,local-duration,local)
        weights=np.zeros(n,dtype=np.float32)
        up=(-fade<=local)&(local<fade)
        weights[up]=np.sin((local[up]+fade)*np.pi/(4*fade))**2
        mid=(fade<=local)&(local<step-fade)
        weights[mid]=1
        down=(step-fade<=local)&(local<step+fade)
        weights[down]=np.cos((local[down]-(step-fade))*np.pi/(4*fade))**2
        for k,p in enumerate([chord[1],chord[2],chord[3]]):
            freq=midi_hz(p)
            # Quantization to whole cycles/period makes the steady tone sample-loop exact.
            f=round(freq*duration)/duration
            phase=(2*np.pi*f*t) + .007*np.sin(2*np.pi*3*t/duration + k)
            y=np.sin(phase)
            if 2*f<710:
                y+=.13*np.sin(2*phase+.23)
            amp=.027 * (.76 if k else 1.)
            out[:,0]+=(amp*weights*y).astype(np.float32)
            out[:,1]+=(amp*weights*np.sin(phase+.055*(k+1))).astype(np.float32)
    # Redundant steep low-pass protects the important 2-6 kHz mechanical clicks.
    sos=signal.butter(9,780,btype="lowpass",fs=FS,output="sos")
    out=signal.sosfiltfilt(sos,np.concatenate((out,out,out),axis=0),axis=0)[n:2*n].astype(np.float32)
    return out


def prepare_audio(name:str,notes:list[Note],length:float) -> np.ndarray:
    if name=="lock_harmony":
        out=render_pad(length)
    else:
        out=render_percussion_and_instruments(notes,length)
    # Limit extreme peaks gently without spectral pumping.
    out=np.tanh(out*2.7).astype(np.float32)
    if name=="lock_harmony":
        sos=signal.butter(10,790,btype="lowpass",fs=FS,output="sos")
        # Triple-period padding avoids edge transient caused by zero initial state.
        N=len(out)
        out=signal.sosfiltfilt(sos,np.tile(out,(3,1)),axis=0)[N:2*N].astype(np.float32)
    meter=pyln.Meter(FS)
    before=meter.integrated_loudness(out)
    target=-14.0 if name.startswith("jingle_") else -16.0
    out=pyln.normalize.loudness(out,before,target).astype(np.float32)
    after=meter.integrated_loudness(out)
    peak=float(np.max(np.abs(out)))
    if peak>=.95:
        # Peak-limiting with a smooth saturation only if headroom requires it.
        for _ in range(3):
            out=(.91*np.tanh(out/.91)).astype(np.float32)
            measured=meter.integrated_loudness(out)
            out=pyln.normalize.loudness(out,measured,target).astype(np.float32)
            if float(np.max(np.abs(out))) < .95:
                break
        after=meter.integrated_loudness(out)
    return out


def save_midi(path:Path,notes:list[Note],duration:float) -> None:
    mf=mido.MidiFile(type=1,ticks_per_beat=480)
    meta=mido.MidiTrack()
    mf.tracks.append(meta)
    meta.append(mido.MetaMessage("track_name",name="Lockwright S01 original score",time=0))
    meta.append(mido.MetaMessage("set_tempo",tempo=mido.bpm2tempo(BPM),time=0))
    meta.append(mido.MetaMessage("time_signature",numerator=4,denominator=4,time=0))
    programs={"piano":0,"bass":32,"clarinet":71,"brush":0,"pad":89}
    chans={"piano":0,"bass":1,"clarinet":2,"brush":9,"pad":3}
    for kind in ("piano","bass","clarinet","brush","pad"):
        these=[n for n in notes if n.kind==kind]
        if not these: continue
        track=mido.MidiTrack();mf.tracks.append(track)
        track.append(mido.MetaMessage("track_name",name=kind,time=0))
        if kind!="brush":track.append(mido.Message("program_change",channel=chans[kind],program=programs[kind],time=0))
        ev=[]
        for note in these:
            # MIDI note-offs do not implement the custom time-varying synthesis exactly.
            on=max(0,int(round(note.start/BEAT*480)))
            off=int(round((note.start+note.length)/BEAT*480))
            num=38 if kind=="brush" else note.midi
            vel=max(1,min(127,int(round(127*note.velocity))))
            ev.append((on,1,mido.Message("note_on",channel=chans[kind],note=num,velocity=vel,time=0)))
            ev.append((off,0,mido.Message("note_off",channel=chans[kind],note=num,velocity=0,time=0)))
        last=0
        for tick,typ,message in sorted(ev,key=lambda z:(z[0],z[1])):
            track.append(message.copy(time=tick-last));last=tick
    mf.save(path)


def write_wav_segments(base:Path,name:str,out:np.ndarray,short:bool) -> list[str]:
    files=[]
    seg_secs=60.0 # Each PCM24 stereo segment ~17.3 MB, strictly < 20 MB.
    samples_per=int(seg_secs*FS)
    for i,st in enumerate(range(0,len(out),samples_per),1):
        suffix="" if short else f"_part{i:02d}"
        path=base/f"{name}{suffix}.wav"
        sf.write(path,out[st:st+samples_per],FS,subtype="PCM_24")
        assert path.stat().st_size<20_000_000,path
        files.append(str(path))
    return files


def write_ogg(base:Path,name:str,out:np.ndarray) -> Path:
    # ffmpeg reads normalized float raw audio and writes perceptually transparent Vorbis.
    path=base/(name+".ogg")
    p=subprocess.Popen(["ffmpeg","-hide_banner","-loglevel","error","-y",
        "-f","f32le","-ar",str(FS),"-ac","2","-i","pipe:0",
        "-c:a","libvorbis","-q:a","5",str(path)],stdin=subprocess.PIPE)
    assert p.stdin is not None
    # Avoid very large Python bytes objects in multiple encoder copies.
    try:
        for st in range(0,len(out),240000):
            p.stdin.write(out[st:st+240000].astype('<f4',copy=False).tobytes())
    except BrokenPipeError:
        raise RuntimeError("ffmpeg encoder failed")
    finally:
        p.stdin.close()
    assert p.wait()==0, "ffmpeg failed"
    return path


def qa_signal(name:str,out:np.ndarray,sr:int=FS) -> dict:
    meter=pyln.Meter(sr)
    lufs=meter.integrated_loudness(out)
    peak=max(1e-15,np.max(np.abs(out)))
    endpoint=np.max(np.abs(out[0]-out[-1]))
    # Relative to median instantaneous sample difference in that signal.
    sample_diff=np.sqrt(np.mean(np.diff(out,axis=0)**2))
    cross=out[0]-out[-1]
    prev=out[-1]-out[-2]
    nxt=out[1]-out[0]
    seam_slope_mismatch=max(np.max(np.abs(cross-prev)),np.max(np.abs(cross-nxt)))
    # Spectrum uses wide bands to confirm exclusion of mechanically important clicks.
    freq, ps_ch = signal.welch(out[:min(len(out),sr*20),:],fs=sr,
             window="hann",nperseg=8192,axis=0)
    ps=np.mean(ps_ch,axis=1)
    lo=np.sum(ps[(freq>=60)&(freq<2000)])
    hi=np.sum(ps[(freq>=2000)&(freq<=6000)])
    ratio=10*np.log10(max(1e-30,hi)/max(lo,1e-30))
    return {"duration_s":round(len(out)/FS,5),"sample_rate_hz":FS,"channels":2,
      "lufs_integrated":round(float(lufs),3),"sample_peak_dbfs":round(float(20*np.log10(peak)),3),
      "seam_absolute_jump":round(float(endpoint),9),
      "seam_slope_mismatch":round(float(seam_slope_mismatch),9),
      "seam_slope_mismatch_vs_diff_rms":round(float(seam_slope_mismatch/sample_diff),4),
      "band_2000_6000_vs_60_2000_db":round(float(ratio),2)}


def save_spectrogram(path:Path,out:np.ndarray) -> None:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.colors import Normalize
    f,t,S=signal.spectrogram(out[:,0],FS,window="hann",nperseg=4096,noverlap=3072,mode="magnitude")
    keep=f<=7000
    sdb=20*np.log10(np.maximum(1e-12,S[keep]))
    plt.figure(figsize=(13,4.7),dpi=120)
    mesh=plt.pcolormesh(t,f[keep],sdb,shading="auto",cmap="magma",norm=Normalize(vmin=-110,vmax=-30))
    plt.axhspan(2000,6000,alpha=.14,color="white",label="Reserved for lock clicks: 2–6 kHz")
    plt.ylim(0,7000);plt.xlim(0,len(out)/FS)
    plt.ylabel("Frequency / Hz");plt.xlabel("Time / s")
    plt.title("S01 • In-lock harmony: spectrogram (48 kHz)")
    plt.legend(loc="upper right",fontsize=8)
    c=plt.colorbar(mesh);c.set_label("Magnitude / dBFS-related")
    plt.tight_layout();plt.savefig(path);plt.close()


def render_all(destination:Path,only: str|None=None)->None:
    aud=destination/"audio";sc=destination/"score";qa=destination/"qa"
    for d in (aud,sc,qa): d.mkdir(parents=True,exist_ok=True)
    scores={"main_theme":score_main,"menu_workshop":score_menu,"lock_harmony":score_lock}
    for name in ("door_open","dignified_refusal","new_chapter","new_tool","showcase_exhibit","end_of_day"):
        scores["jingle_"+name]=lambda n=name:score_jingle(n)
    report={}
    for name,construct in scores.items():
        if only and name!=only:continue
        print(f"[S01] rendering {name}",flush=True)
        notes,length=construct()
        save_midi(sc/(name+".mid"),notes,length)
        mixed=prepare_audio(name,notes,length)
        wav=write_wav_segments(aud,name,mixed,name.startswith('jingle_'))
        ogg=write_ogg(aud,name,mixed)
        report[name]=qa_signal(name,mixed)
        report[name]["wav_segments"]=[Path(x).name for x in wav]
        report[name]["ogg_file"]=ogg.name
        if name=="lock_harmony":save_spectrogram(qa/"lock_harmony_spectrogram.png",mixed)
        print(f"[S01] {name}: {report[name]}",flush=True)
    existing=qa/"measurements.json"
    if existing.exists():
        old=json.loads(existing.read_text('utf-8'))
        old.update(report);report=old
    existing.write_text(json.dumps(report,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")


if __name__=="__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=Path(__file__).resolve().parent)
    parser.add_argument('--only',help='Track id; omit for all nine tracks')
    args=parser.parse_args()
    render_all(args.output,args.only)
