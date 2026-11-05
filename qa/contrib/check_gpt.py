#!/usr/bin/env python3
"""Automatic intake checks for ChatGPT deliveries in contrib/gpt/<ID>/ (session C, stage 4, task 2).

The human verdict (accepted / needs fixes / rejected) is written in contrib/REVIEW.md; this script gathers the
evidence: files, README/ASSETS presence, ASSETS coverage (every binary named, prompt + tool present), image sizes and
alpha, seam score + 2x2 previews for tileable textures, audio onset / LUFS / true peak / loop seam, CSV and JSON
validity, a brand and tone word scan, and a contact sheet for images.

   python3 qa/contrib/check_gpt.py [--out qa/out/contrib] [ID ...]      (default: every contrib/gpt/<ID>/)
"""
import argparse, csv, io, json, math, pathlib, re, sys, wave

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
GPT = pathlib.Path(__import__('os').environ.get('CONTRIB_GPT', ROOT / 'contrib' / 'gpt'))
sys.path.insert(0, str(ROOT / 'audio' / 'v2'))
import loudness  # noqa: E402  (BS.1770 meter from audio/v2)

IMG = {'.png', '.jpg', '.jpeg', '.webp'}
AUD = {'.wav'}
BIN = IMG | AUD | {'.ogg', '.mp3', '.flac', '.svg', '.pdf', '.ttf', '.otf'}
# real brands that must not appear in deliveries (locks, cars) + tone words that suggest a burglar aesthetic.
BRANDS = ['yale', 'abloy', 'assa', 'gerda', 'mul-t-lock', 'multlock', 'kwikset', 'schlage', 'medeco', 'master lock',
          'abus', 'evva', 'kaba', 'winkhaus', 'vachette', 'cisa', 'dormakaba', 'sargent', 'toyota', 'volkswagen',
          'mercedes', 'bmw', 'skoda', 'škoda', 'opel', 'fiat', 'renault', 'peugeot', 'tesla', 'audi', 'ford ']
TONE = ['heist', 'burglar', 'break-in', 'break in', 'włamyw', 'włamani', 'włamyw', 'skok na', 'łup', 'loot', 'crack the safe',
        'balaclava', 'kominiark', 'thief', 'złodziej', 'unlock your potential', 'get started', 'welcome!']


def seam_score(im: Image.Image) -> float:
    """Edge discontinuity of a tile: mean |col0 - col_last| (and rows) over the mean |col_i - col_i+1| inside.
    ~1 = seamless, > 2 = visible seam likely."""
    a = np.asarray(im.convert('L'), dtype=np.float32)
    if a.shape[0] < 8 or a.shape[1] < 8:
        return float('nan')
    inner_x = np.mean(np.abs(np.diff(a, axis=1)))
    inner_y = np.mean(np.abs(np.diff(a, axis=0)))
    edge_x = np.mean(np.abs(a[:, 0] - a[:, -1]))
    edge_y = np.mean(np.abs(a[0, :] - a[-1, :]))
    return float(max(edge_x / max(inner_x, 1e-3), edge_y / max(inner_y, 1e-3)))


def is_tile(path: pathlib.Path, did: str) -> bool:
    n = path.name.lower()
    if any(k in n for k in ('preview', '2x2', 'sheet', 'contact', 'arkusz')):
        return False
    return did in ('G02', 'G03', 'G04', 'G05', 'G06') or any(k in n for k in ('tile', 'albedo', 'height', 'rough', 'normal'))


def audio_stats(path: pathlib.Path) -> dict:
    with wave.open(str(path)) as w:
        sr, ch, sw, n = w.getframerate(), w.getnchannels(), w.getsampwidth(), w.getnframes()
        raw = w.readframes(n)
    if sw == 2:
        x = np.frombuffer(raw, '<i2').astype(np.float64) / 32768
    elif sw == 3:
        b = np.frombuffer(raw, np.uint8).reshape(-1, 3)
        x = ((b[:, 0].astype(np.int32) | (b[:, 1].astype(np.int32) << 8) | (b[:, 2].astype(np.int32) << 16)) << 8 >> 8) / 8388608.0
    elif sw == 4:
        x = np.frombuffer(raw, '<i4').astype(np.float64) / 2147483648
    else:
        x = (np.frombuffer(raw, np.uint8).astype(np.float64) - 128) / 128
    x = x.reshape(-1, ch).mean(axis=1) if ch > 1 else x
    peak = float(np.max(np.abs(x))) if x.size else 0.0
    thr = peak * 0.1  # onset: first sample at -20 dB re peak
    onset_ms = float(np.argmax(np.abs(x) >= thr) / sr * 1000) if peak > 0 else -1
    loop = 'loop' in path.name.lower() or 'amb' in path.name.lower()
    seam = None
    if loop and x.size > sr // 10:
        k = max(1, sr // 1000)  # 1 ms
        jump = abs(float(x[0]) - float(x[-1]))
        local = float(np.mean(np.abs(np.diff(x[-k * 10:])))) + 1e-9
        seam = round(jump / local, 1)
    st = {'sr': sr, 'channels': ch, 'bits': sw * 8, 'dur_s': round(x.size / sr, 3), 'peak_dbfs': round(20 * math.log10(peak), 1) if peak > 0 else -120,
          'onset_ms': round(onset_ms, 2), 'loop_seam_ratio': seam, 'clipped': int(np.sum(np.abs(x) >= 0.999))}
    try:
        st['lufs_i'] = round(loudness.integrated(x, sr, circular=loop), 1)
        st['lufs_m_max'] = round(loudness.momentary_max(x, sr, circular=loop), 1)
        st['true_peak_db'] = round(loudness.true_peak_db(x, circular=loop), 1)
    except Exception as e:  # very short or silent files
        st['lufs_error'] = str(e)[:80]
    return st


def scan_text(text: str) -> list:
    low = text.lower()
    hits = [w for w in BRANDS if re.search(r'(?<![a-ząćęłńóśźż])' + re.escape(w.strip()) + r'(?![a-ząćęłńóśźż])', low)]
    hits += [w for w in TONE if w in low]
    return sorted(set(hits))


def check(did: str, out: pathlib.Path) -> dict:
    d = GPT / did
    files = sorted(p for p in d.rglob('*') if p.is_file())
    rep = {'id': did, 'files': len(files), 'bytes': sum(p.stat().st_size for p in files), 'problems': [], 'notes': [],
           'images': [], 'audio': [], 'data': [], 'text_hits': {}}
    readme = d / 'README.md'
    assets = d / 'ASSETS.md'
    if not readme.exists():
        rep['problems'].append('brak README.md (raport po polsku)')
    bins = [p for p in files if p.suffix.lower() in BIN]
    if bins and not assets.exists():
        rep['problems'].append('brak ASSETS.md przy plikach binarnych (D-42)')
    if assets.exists():
        at = assets.read_text(errors='replace')
        low = at.lower()
        missing = [p.name for p in bins if p.name.lower() not in low and p.stem.lower() not in low]
        if missing:
            rep['problems'].append(f'ASSETS.md nie wymienia {len(missing)} plików, np. {", ".join(missing[:5])}')
        if 'prompt' not in low:
            rep['problems'].append('ASSETS.md bez promptów')
        if not re.search(r'chatgpt|dall|gpt-|sora|midjourney|stable diffusion|suno|udio|elevenlabs|narzędzi|tool', low):
            rep['problems'].append('ASSETS.md nie podaje narzędzia')
    big = [p.name for p in files if p.stat().st_size > 20e6]
    if big:
        rep['problems'].append(f'pliki > 20 MB: {big}')
    od = out / did
    od.mkdir(parents=True, exist_ok=True)
    thumbs = []
    for p in files:
        suf = p.suffix.lower()
        rel = str(p.relative_to(d))
        if suf in IMG:
            try:
                im = Image.open(p)
                info = {'file': rel, 'size': im.size, 'mode': im.mode}
                if is_tile(p, did):
                    s = seam_score(im)
                    info['seam'] = round(s, 2)
                    if s > 2.0:
                        rep['problems'].append(f'{rel}: prawdopodobny szew (wsk. {s:.1f})')
                    t = im.convert('RGB')
                    t = t.resize((512, round(512 * t.height / t.width)))
                    g = Image.new('RGB', (t.width * 2, t.height * 2))
                    for i in range(2):
                        for j in range(2):
                            g.paste(t, (i * t.width, j * t.height))
                    g.save(od / f'{p.stem}_2x2.jpg', quality=85)
                rep['images'].append(info)
                th = im.convert('RGBA')
                th.thumbnail((256, 256))
                bg = Image.new('RGB', (256, 256), (128, 128, 128))
                bg.paste(th, ((256 - th.width) // 2, (256 - th.height) // 2), th)
                thumbs.append(bg)
            except Exception as e:
                rep['problems'].append(f'{rel}: nie otwiera się ({e})')
        elif suf in AUD:
            try:
                st = audio_stats(p)
                st['file'] = rel
                rep['audio'].append(st)
                if st['clipped'] > 0:
                    rep['problems'].append(f'{rel}: przester ({st["clipped"]} próbek)')
                if st.get('loop_seam_ratio') and st['loop_seam_ratio'] > 8:
                    rep['problems'].append(f'{rel}: skok na łączeniu pętli (×{st["loop_seam_ratio"]})')
            except Exception as e:
                rep['problems'].append(f'{rel}: nie czyta się jako WAV ({e})')
        elif suf in {'.ogg', '.mp3', '.flac'}:
            rep['notes'].append(f'{rel}: format {suf} — pomiar tylko dla WAV')
        elif suf == '.json':
            try:
                json.loads(p.read_text())
                rep['data'].append({'file': rel, 'ok': True})
            except Exception as e:
                rep['data'].append({'file': rel, 'ok': False})
                rep['problems'].append(f'{rel}: niepoprawny JSON ({e})')
        elif suf == '.csv':
            try:
                rows = list(csv.reader(io.StringIO(p.read_text())))
                widths = {len(r) for r in rows if r}
                ok = len(widths) == 1
                rep['data'].append({'file': rel, 'rows': len(rows), 'cols': sorted(widths), 'ok': ok})
                if not ok:
                    rep['problems'].append(f'{rel}: CSV ma różną liczbę kolumn {sorted(widths)}')
            except Exception as e:
                rep['problems'].append(f'{rel}: niepoprawny CSV ({e})')
        if suf in {'.md', '.txt', '.csv', '.json', '.svg'}:
            hits = scan_text(p.read_text(errors='replace'))
            if hits:
                rep['text_hits'][rel] = hits
    if thumbs:
        cols = 6
        rows = math.ceil(len(thumbs) / cols)
        sheet = Image.new('RGB', (cols * 260, rows * 260), (255, 255, 255))
        for k, t in enumerate(thumbs):
            sheet.paste(t, ((k % cols) * 260 + 2, (k // cols) * 260 + 2))
        sheet.save(od / 'contact.jpg', quality=80)
    return rep


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('ids', nargs='*')
    ap.add_argument('--out', default=str(ROOT / 'qa/out/contrib'))
    a = ap.parse_args()
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    ids = a.ids or sorted(p.name for p in GPT.iterdir() if p.is_dir()) if GPT.exists() else []
    reps = [check(i, out) for i in ids]
    (out / 'report.json').write_text(json.dumps(reps, indent=2, ensure_ascii=False, default=str))
    for r in reps:
        print(f"{r['id']}: {r['files']} plików, {r['bytes'] / 1e6:.1f} MB, problemy: {len(r['problems'])}")
        for p in r['problems'][:12]:
            print('   -', p)
        if r['text_hits']:
            print('   słowa do sprawdzenia:', r['text_hits'])
    if not reps:
        print('brak dostaw w contrib/gpt/')


if __name__ == '__main__':
    main()
