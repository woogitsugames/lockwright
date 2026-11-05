#!/usr/bin/env python3
"""Independent QA: verify published S01 binary assets and write measurements."""
from __future__ import annotations
import json
from pathlib import Path
import numpy as np
import soundfile as sf
from render_music import FS, qa_signal

ROOT=Path(__file__).resolve().parent
TRACKS=["main_theme","menu_workshop","lock_harmony",
        "jingle_door_open","jingle_dignified_refusal","jingle_new_chapter",
        "jingle_new_tool","jingle_showcase_exhibit","jingle_end_of_day"]


def verify(root:Path=ROOT):
    measurements={}
    for name in TRACKS:
        parts=sorted((root/"audio").glob(name+"_part*.wav"))
        if not parts:parts=[root/"audio"/(name+".wav")]
        assert all(f.exists() for f in parts),name
        for f in parts:
            info=sf.info(f)
            assert info.samplerate==FS and info.channels==2 and info.subtype=="PCM_24",str(info)
            assert f.stat().st_size < 20_000_000,f"File >20 MB: {f}"
        wav=np.concatenate([sf.read(p,dtype="float32")[0] for p in parts])
        ogg=root/"audio"/(name+".ogg")
        oinfo=sf.info(ogg)
        assert oinfo.samplerate==FS and oinfo.channels==2, str(oinfo)
        decoded,_=sf.read(ogg,dtype="float32")
        assert len(wav)==len(decoded),(name,len(wav),len(decoded))
        result=qa_signal(name,wav)
        result["ogg_lufs_integrated"]=qa_signal(name,decoded)["lufs_integrated"]
        result["wav_segments"]=[x.name for x in parts]
        result["ogg_file"]=ogg.name
        expected=-14 if name.startswith("jingle_") else -16
        assert abs(result["lufs_integrated"]-expected)<.1,(name,result)
        if name in ("menu_workshop","lock_harmony"):
            assert result["seam_slope_mismatch_vs_diff_rms"]<.06,(name,result)
        if name=="lock_harmony":
            assert result["band_2000_6000_vs_60_2000_db"] < -75,(name,result)
        assert (root/"score"/(name+".mid")).exists(),name
        measurements[name]=result
        print(name,result)
    (root/"qa"/"measurements.json").write_text(json.dumps(measurements,indent=2,ensure_ascii=False)+"\n",encoding="utf8")
    print('PASS: 9 score MIDI, 9 OGG, 13 WAV files, format, loudness, spectrum and seams')


if __name__=='__main__':verify()
