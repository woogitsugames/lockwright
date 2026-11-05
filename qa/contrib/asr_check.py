#!/usr/bin/env python3
"""Automatic "listening" for wordless voices (session C, stage 5, task 2: S03).
Runs offline speech recognition (faster-whisper) on every WAV and flags files where the recogniser hears words
with confidence. Wordless mumbles usually come back empty, as a single filler ("hmm", "mm") or with low confidence.

   python3 qa/contrib/asr_check.py contrib/gpt/S03 [--model small] [--out qa/out/contrib/S03_asr.json]

A file is flagged ("słowa") when, in auto-language mode or forced PL/EN, a segment has no_speech_prob < 0.5,
avg_logprob > -0.8 and contains at least one alphabetic token of >= 3 letters that is not a filler.
Treat flags as "needs a human ear", not as proof: Whisper also hallucinates words in noise."""
import argparse, json, pathlib, re, sys, wave

import numpy as np

FILLERS = {'hmm', 'hm', 'mm', 'mmm', 'mhm', 'uh', 'um', 'ah', 'oh', 'eh', 'ha', 'huh', 'hah', 'aha', 'ehh', 'ahh', 'ohh', 'uhh',
           'umm', 'hmph', 'pff', 'psst', 'shh', 'tsk', 'ooh', 'aah', 'och', 'ach', 'ech', 'yh', 'eee', 'aaa', 'ooo', 'mmhm'}


def looping(text):
    """Whisper's typical hallucination on non-speech: one or two words repeated over and over."""
    t = re.findall(r"[^\W\d_]+", text.lower())
    return len(t) >= 6 and len(set(t)) / len(t) < 0.35


def tokens(text):
    return [t for t in re.findall(r"[^\W\d_]+", text.lower()) if len(t) >= 3 and t not in FILLERS
            and not re.fullmatch(r'(.)\1+', t) and not re.fullmatch(r'(h?[aeiouy]+h*|m+|h+m+)', t)
            and not re.search(r'(.)\1{3,}', t)]  # onomatopoeia like "bzzzz"


def load16k(path):
    """WAV -> mono float32 at 16 kHz (linear interpolation is enough for recognition)."""
    with wave.open(str(path)) as w:
        sr, ch, sw, n = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
        raw = w.readframes(n)
    dt = {1: np.uint8, 2: '<i2', 4: '<i4'}.get(sw)
    if sw == 3:
        b = np.frombuffer(raw, np.uint8).reshape(-1, 3).astype(np.int32)
        x = ((b[:, 0] | (b[:, 1] << 8) | (b[:, 2] << 16)) << 8 >> 8) / 8388608.0
    else:
        x = np.frombuffer(raw, dt).astype(np.float64)
        x = (x - 128) / 128 if sw == 1 else x / float(2 ** (8 * sw - 1))
    if ch > 1:
        x = x.reshape(-1, ch).mean(axis=1)
    t = np.arange(0, len(x) / sr, 1 / 16000)
    return np.interp(t, np.arange(len(x)) / sr, x).astype(np.float32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('dir')
    ap.add_argument('--model', default='small')
    ap.add_argument('--out')
    a = ap.parse_args()
    from faster_whisper import WhisperModel
    model = WhisperModel(a.model, device='cpu', compute_type='int8')
    files = sorted(pathlib.Path(a.dir).rglob('*.wav'))
    rows, flagged = [], []
    for f in files:
        rec = {'file': str(f.relative_to(a.dir)), 'runs': {}}
        hit = []
        audio = load16k(f)
        for lang in (None, 'pl', 'en'):
            segs, info = model.transcribe(audio, language=lang, beam_size=1, vad_filter=False,
                                          condition_on_previous_text=False, temperature=0.0)
            segs = list(segs)
            text = ' '.join(s.text.strip() for s in segs).strip()
            good = [s for s in segs if s.no_speech_prob < 0.5 and s.avg_logprob > -0.8 and not looping(s.text)]
            words = sorted({w for s in good for w in tokens(s.text)})
            rec['runs'][lang or f'auto:{info.language}'] = {'text': text[:120], 'words': words,
                'min_no_speech': round(min((s.no_speech_prob for s in segs), default=1.0), 2),
                'max_logprob': round(max((s.avg_logprob for s in segs), default=-9), 2)}
            hit += words
        rec['flag'] = bool(hit)
        rec['words'] = sorted(set(hit))
        rows.append(rec)
        if hit:
            flagged.append(rec)
        print(f"{'SŁOWA' if hit else 'ok   '} {rec['file']}  {rec['words'][:6]}", flush=True)
    res = {'model': a.model, 'files': len(rows), 'flagged': len(flagged), 'rows': rows}
    if a.out:
        pathlib.Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        pathlib.Path(a.out).write_text(json.dumps(res, indent=1, ensure_ascii=False))
    print(f'files {len(rows)}, flagged {len(flagged)}')


if __name__ == '__main__':
    main()
