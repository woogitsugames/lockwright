#!/usr/bin/env python3
"""S02 format, loudness, onset, seam and provenance validation."""
from __future__ import annotations
import hashlib
import json
import pathlib
import struct
import sys

import numpy as np
import pyloudnorm as pyln
import soundfile as sf

ROOT=pathlib.Path(__file__).resolve().parent
SR=48000

def fail(msg):
    print('FAIL: '+msg)
    raise SystemExit(1)

def validate():
    metadata=json.loads((ROOT/'manifest.json').read_text(encoding='utf8'))
    rows=metadata['files']
    if len(rows)<40:fail('expected >=40 audio files')
    observed={x.relative_to(ROOT).as_posix() for x in ROOT.rglob('*.wav')}
    declared={e['file'] for e in rows}
    if observed!=declared:fail(f'files mismatch: extra={observed-declared}, missing={declared-observed}')
    for row in rows:
        path=ROOT/row['file']
        if path.stat().st_size>20_000_000:fail(f'file larger than 20MB: {path.name}')
        if hashlib.sha256(path.read_bytes()).hexdigest()!=row['sha256']:fail(f'hash mismatch: {path.name}')
        with sf.SoundFile(path) as f:
            if (f.samplerate,f.subtype)!=(SR,'PCM_24'):fail(f'wrong format: {path.name}')
            if f.channels!=(2 if row['file'].startswith('ambience/') else 1):fail(f'wrong channel count: {path.name}')
            y=f.read(dtype='float32')
        if len(y)!=row['frames']:fail(f'wrong sample count: {path.name}')
        pk=20*np.log10(float(np.max(np.abs(y))))
        if row['file'].startswith('ambience/'):
            if len(y)!=60*SR:fail(f'wrong loop duration: {path.name}')
            lu=pyln.Meter(SR).integrated_loudness(y)
            if abs(lu+18)>.2:fail(f'loudness not -18 LUFS: {path.name}: {lu:.2f}')
            if pk>=-1:fail(f'clipping risk: {path.name}: {pk:.2f}')
            raw=path.read_bytes()
            i=raw.rfind(b'smpl')
            if i<44 or raw[i+4:i+8]!=struct.pack('<I',60):fail(f'missing smpl chunk: {path.name}')
            if struct.unpack_from('<I',raw,i+56)[0]!=len(y)-1:fail(f'wrong smpl loop end: {path.name}')
            diff=np.max(np.abs(np.diff(y,axis=0)),axis=1)
            seam=float(np.max(np.abs(y[0]-y[-1])))
            if seam>float(np.quantile(diff,.9999)):fail(f'seam discontinuity in loop: {path.name}')
            print(f'OK {row["file"]}: {lu:.2f} LUFS, peak {pk:.2f} dBFS, seam {seam:.4f}')
        else:
            if abs(pk+12)>.08:fail(f'wrong foley peak: {path.name}: {pk:.2f}')
            threshold=np.max(np.abs(y))*10**(-30/20)
            onset=float(np.flatnonzero(np.abs(y)>=threshold)[0]/SR*1e3)
            if onset>5:fail(f'foley onset >5ms: {path.name}: {onset:.2f}')
            if np.max(np.abs(y[-100:]))>.006:fail(f'audible foley tail truncation: {path.name}')
            print(f'OK {row["file"]}: peak {pk:.2f} dBFS; onset {onset:.3f}ms')
    print(f'PASS: {len(rows)} WAV assets, all verified.')

if __name__=='__main__':validate()
