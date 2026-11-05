#!/usr/bin/env python3
"""Verify the S04 diegetic UI bank using Python 3 standard library only."""
from pathlib import Path
import argparse
import math
import struct
import wave

SR = 48000
CUES = (
    "tool_roll_open", "tool_roll_close", "pick_remove", "pick_insert",
    "brass_snap_pause", "notebook_page_turn", "chalk_on_metal",
    "loupe_set_down", "loupe_apply", "borescope_power_on",
    "phone_job_vibrate", "showcase_drawer", "showcase_glass_door",
    "coins_on_counter", "stamp_cancel", "borescope_hum_loop",
)

def has_smpl(blob: bytes, frames: int) -> bool:
    if blob[:4] != b"RIFF" or blob[8:12] != b"WAVE":
        return False
    pos = 12
    while pos + 8 <= len(blob):
        name, size = blob[pos:pos+4], struct.unpack_from("<I", blob, pos+4)[0]
        if name == b"smpl":
            if size != 60 or pos + 8 + size > len(blob):
                return False
            f = struct.unpack_from("<15I", blob, pos + 8)
            return f[7] == 1 and f[10] == 0 and f[11] == 0 and f[12] == frames-1 and f[13] == 0
        pos += 8 + size + (size & 1)
    return False

def check(root: Path) -> None:
    wanted = {root / "ui" / name / f"{name}_{i:02}.wav" for name in CUES for i in range(1,7)}
    found = set((root / "ui").rglob("*.wav"))
    problems = [f"Missing: {f}" for f in sorted(wanted-found)] + [f"Unexpected: {f}" for f in sorted(found-wanted)]
    max_onset, max_duration, max_seam_ratio = 0., 0., 0.
    peaks = []
    for file in sorted(wanted & found):
        try:
            with wave.open(str(file), "rb") as w:
                if (w.getnchannels(),w.getframerate(),w.getsampwidth(),w.getcomptype()) != (1,SR,2,"NONE"):
                    raise ValueError("expected 48kHz mono PCM16 WAV")
                frames=w.getnframes()
                raw=w.readframes(frames)
            if len(raw) != frames*2:
                raise ValueError("short WAV data")
            samples=struct.unpack(f"<{frames}h",raw)
            peak=max(abs(s) for s in samples)
            if not peak: raise ValueError("silent WAV")
            db=20*math.log10(peak/32768)
            onset=next(i for i,s in enumerate(samples) if abs(s)>=peak*10**(-30/20))/SR*1000
            dur=frames/SR*1000
            dc=20*math.log10(max(abs(sum(samples)/frames/32768),1e-12))
            looping=file.parent.name=="borescope_hum_loop"
            if abs(db+14)>.1: raise ValueError(f"peak {db:.3f} dBFS")
            if onset>2: raise ValueError(f"onset {onset:.4f} ms")
            if not looping and dur>600: raise ValueError(f"one-shot {dur:.2f} ms")
            if dc>-60: raise ValueError(f"DC {dc:.2f} dBFS")
            if looping:
                if dur!=1000: raise ValueError("loop duration is not 1000 ms")
                if not has_smpl(file.read_bytes(),frames): raise ValueError("missing smpl 0..N-1")
                steps=sorted(abs(samples[i]-samples[i-1]) for i in range(1,frames))
                p999=steps[min(len(steps)-1,int(.999*len(steps)))]
                ratio=abs(samples[0]-samples[-1])/max(1,p999)
                max_seam_ratio=max(max_seam_ratio,ratio)
                if ratio>1: raise ValueError(f"loop seam vs p99.9: {ratio:.2f}")
            elif samples[-1]!=0: raise ValueError("one-shot missing fade-out to zero")
            peaks.append(db)
            max_onset=max(max_onset,onset)
            if not looping:max_duration=max(max_duration,dur)
        except (ValueError,OSError,EOFError,struct.error) as e:
            problems.append(f"{file.relative_to(root)}: {e}")
    print(f"Files: {len(found)}/{len(wanted)}, max onset: {max_onset:.4f} ms, max one-shot: {max_duration:.1f} ms")
    print(f"Peak: {min(peaks,default=0):.3f}..{max(peaks,default=0):.3f} dBFS, loop seam/p99.9 max: {max_seam_ratio:.2f}")
    for problem in problems: print("FAIL:",problem)
    if problems: raise SystemExit(1)
    print("PASS: file count, RIFF/PCM, onset, peak, length, DC, fade and loop markers")

if __name__ == "__main__":
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root",type=Path,default=Path(__file__).resolve().parent)
    args=parser.parse_args()
    check(args.root)
