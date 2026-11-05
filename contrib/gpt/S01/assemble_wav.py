#!/usr/bin/env python3
"""Bit-exact WAV parts joining into one PCM24 48k stereo WAV outside Git.

Usage: python assemble_wav.py main_theme /path/out.wav
       python assemble_wav.py menu_workshop /path/out.wav
       python assemble_wav.py lock_harmony /path/out.wav
"""
import argparse
from pathlib import Path
import wave

NAMES=['main_theme','menu_workshop','lock_harmony']

def assemble(name,out_path):
    root=Path(__file__).resolve().parent/'audio'
    files=sorted(root.glob(name+'_part*.wav'))
    if not files:raise FileNotFoundError(name)
    with wave.open(str(out_path),'wb') as dst:
        for index,f in enumerate(files):
            with wave.open(str(f),'rb') as src:
                params=(src.getnchannels(),src.getsampwidth(),src.getframerate(),src.getcomptype())
                if params!=(2,3,48000,'NONE'):raise ValueError(f'Unexpected WAV format: {f} {params}')
                if index==0:dst.setparams(src.getparams())
                block=src.readframes(65536)
                while block:
                    dst.writeframesraw(block)
                    block=src.readframes(65536)
        dst.writeframes(b'')
    print('Joined losslessly:',out_path)

if __name__=='__main__':
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('track',choices=NAMES)
    ap.add_argument('output',type=Path)
    opts=ap.parse_args()
    assemble(opts.track,opts.output)
