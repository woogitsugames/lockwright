#!/usr/bin/env python3
"""Verify all prebuilt WAV files and reported measurements without regenerating audio."""
from __future__ import annotations
import hashlib
import json
import wave
from pathlib import Path

import numpy as np
import pyloudnorm as pyln

BASE = Path(__file__).resolve().parent
RATE = 48000

def main():
    manifest = json.loads((BASE/'manifest.json').read_text(encoding='utf-8'))
    assert len(manifest['files']) == 18
    meter = pyln.Meter(RATE, block_size=.400)
    for item in manifest['files']:
        path = BASE/item['filename']
        assert path.exists(), path
        data = path.read_bytes()
        assert hashlib.sha256(data).hexdigest() == item['sha256'], path
        with wave.open(str(path)) as sound:
            assert (sound.getnchannels(),sound.getsampwidth(),sound.getframerate(),sound.getcomptype()) == (1,2,RATE,'NONE'),path
            raw = np.frombuffer(sound.readframes(sound.getnframes()),dtype='<i2').astype(np.float64)/32768
        assert len(raw) and np.max(np.abs(raw)) < 1., path
        duration = len(raw)/RATE*1000
        loud = float(meter.integrated_loudness(np.pad(raw,(0,max(0,int(RATE*.4)-len(raw))))))
        assert abs(duration-item['duration_ms']) < .005,path
        assert abs(loud-item['lufs_400ms_padded']) < .02,path
        assert item['onset_ms'] <= 5 and item['trailing_silence_ms'] <= 50, path
    assert len(list((BASE/'sfx').glob('*.wav'))) == 18
    print('PASS: all 18 WAVs, manifest SHA-256, PCM format, durations, LUFS and timing.')

if __name__=='__main__': main()
