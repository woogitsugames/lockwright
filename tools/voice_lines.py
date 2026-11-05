#!/usr/bin/env python3
"""Voiced dialogue lines for jobs (D-57): cast, TTS, normalisation, .import files.

Source of truth for the TEXT is game/i18n/content.csv (`<job_id>.line.N`, columns en/pl/de); the SPEAKER of each line
is `lines[N-1]` in game/data/jobs*/<job_id>.json. Every speaker has one fixed, fictional ElevenLabs voice (designed
from a text description with Voice Design, never cloned) that reads both languages; see game/data/voice_cast.json.

Subcommands
  python3 tools/voice_lines.py inventory                 # list lines, speakers, counts
  python3 tools/voice_lines.py design-payload            # JSON of CAST descriptions + sample texts (for Voice Design)
  python3 tools/voice_lines.py tts-payload [--jobs a,b] [--lang pl,en]   # JSON list of TTS requests
  python3 tools/voice_lines.py manifest                  # contrib/voice/tts_inputs.json: exact tagged TTS input per file
  python3 tools/voice_lines.py synth  [--jobs ...] [--lang ...]           # call the API directly (needs ELEVENLABS_API_KEY)
  python3 tools/voice_lines.py finish DIR                # raw PCM/WAV in DIR (<lang>/<key>.pcm) -> normalised .ogg + .import
  python3 tools/voice_lines.py qa [--lang pl,en]         # duration/loudness/ASR word error rate (faster-whisper)

How it was actually run (2026-11-05): the session had no API key, only the ElevenLabs connection in Composio.
Voice Design (ELEVENLABS_DESIGN_VOICE, model eleven_ttv_v3, 3 previews per character), choice of the preview
(pitch range for age/gender + ASR confidence), ELEVENLABS_CREATE_VOICE_FROM_PREVIEW, then ELEVENLABS_TEXT_TO_SPEECH
with the payload from `tts-payload` (output pcm_48000), executed in the Composio workbench; the PCM files were
downloaded and passed to `finish`. With ELEVENLABS_API_KEY set, `synth` does the same over the public REST API.
"""
import argparse, csv, glob, hashlib, io, json, os, pathlib, re, subprocess, sys, urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
GAME = ROOT / 'game'
OUT = GAME / 'assets/audio/lines'
CAST_JSON = GAME / 'data/voice_cast.json'
LANGS = ('pl', 'en')            # D-57: PL + EN now; 'de' can be added later with the same voices
MODEL = 'eleven_v4_turbo'       # owner's choice (cheaper); fallback 'eleven_v4'. Not v3 / multilingual v2.
TAGS_JSON = ROOT / 'contrib/voice/tags.json'   # audio tags per line key, e.g. "[tired]" (TTS input only)
MANIFEST = ROOT / 'contrib/voice/tts_inputs.json'
TARGET_LUFS = -18.0
PAD_MS = 60                     # silence kept at both ends after trimming (<= 150 ms)

# Spoken form for TTS where the subtitle uses digits (subtitles stay as in content.csv).
TTS_OVERRIDES = {
    ('job.krakow_tenement_gate.line.3', 'pl'): 'Dzień dobry. Mam tu praktykę. Egzamin zdałam, pokój czterysta dwanaście pomógł.',
    ('job.krakow_tenement_gate.line.3', 'en'): "Hello again. I'm an intern here now. I passed the exam. Room four-twelve helped.",
    ('job.student_dorm.line.2', 'en'): 'Zuzanna Wilk, room four-twelve. On my list and in my head.',
    ('job.kiosk_shutter.line.3', 'en'): "From opening day in ninety-four. My moustache looked better than the kiosk.",
}

# Voice Design brief per speaker: gender, age, temperament (docs/CLIENTS.md, job .client texts, cast portraits).
# `accent` is how the character speaks Polish/English (all are native Polish unless stated).
CAST = {
    'locksmith': ('m', 45, 'Calm, warm Polish man in his mid forties, an emergency locksmith. Low-medium pitch, steady unhurried pace, kind and reassuring, dry humour, a slight smile in the voice.'),
    'halina': ('f', 81, 'Elderly Polish grandmother, 81, warm and motherly but firm about food, slightly shaky older voice, lively, says "synku".'),
    'zosia': ('f', 75, 'Polish woman about 75, matter-of-fact neighbour with tender irritation, clear brisk older voice, practical.'),
    'stefan': ('m', 67, 'Polish man of 67 who runs a newspaper kiosk, a chatty storyteller, slightly husky friendly voice, amused.'),
    'roman': ('m', 58, 'Polish building administrator, 58, dry, efficient, few words, flat businesslike baritone.'),
    'marta': ('f', 34, 'Polish graphic designer, 34, ironic and witty with warmth underneath, relaxed mid-pitch voice.'),
    'zuzanna': ('f', 20, 'Polish student, 20, quick, curious and a bit of a know-it-all, bright youthful energetic voice.'),
    'edek': ('m', 63, 'Polish dormitory porter, 63, good-humoured, proud of his memory, warm slightly gravelly voice.'),
    'ola': ('f', 38, 'Polish biology teacher, 38, patient, explains things clearly, kind and composed mid-pitch voice.'),
    'krystyna': ('f', 68, 'Polish woman in her late sixties, reserved, says little and precisely, soft low older voice.'),
    'wladyslaw': ('m', 84, 'Very old Polish master locksmith, 84, short sentences, a spark of mischief, firm but aged voice, slow.'),
    'rygiel': ('f', 50, 'Polish museum curator, about 50, pedantic and precise, crisp clear articulate voice, polite.'),
    'jadwiga': ('f', 72, 'Retired Polish schoolteacher, early seventies, confident teacherly voice, clear diction, a bit theatrical.'),
    'kuba': ('m', 23, 'Young Polish man, 23, fresh graduate, nervous and self-ironic, light youthful voice, speaks fast.'),
    'iga': ('f', 27, 'Polish rock drummer, 27, punchy, cool and energetic, slightly husky young voice.'),
    'hall_manager': ('m', 45, 'Polish rehearsal-hall manager, mid forties, methodical, a bit bored, plain mid-low voice.'),
    'gosia': ('f', 36, 'Polish furniture restorer, 36, calm, precise and warm, gentle mid-pitch voice.'),
    'magda': ('f', 41, 'Polish translator living in Brussels, 41, lively, witty and theatrical, expressive mid-pitch voice.'),
    'jacques': ('m', 62, 'Belgian man around sixty, gentle and charming, speaks with a noticeable French accent, soft baritone.'),
    'martine': ('f', 78, 'Elderly Belgian woman, late seventies, gentle and emotional, speaks with a French accent, soft older voice.'),
    'hania': ('f', 7, 'Little girl about seven years old, sweet, earnest and serious, high child voice.'),
    'tomasz': ('m', 40, 'Polish carpenter, about 40, quiet and grounded, warm low voice, modest.'),
    'aino': ('f', 50, 'Finnish ship engineer officer, 50, calm, dry and laconic, speaks with a light Nordic accent, low steady female voice.'),
    'captain': ('m', 60, 'Bearded ship captain about 60, Nordic, deep authoritative but warm voice, light Finnish accent, measured.'),
    'pieter': ('m', 66, 'Flemish lay brother, 66, gentle, humorous and kind, speaks with a light Dutch-Flemish accent, soft warm voice.'),
    'krysia': ('f', 70, 'Polish woman about 70, cheerful regular at the bus stop, bright friendly older voice, quick.'),
    'leopold': ('m', 70, 'Refined Polish antiquarian, 70, cultured and courteous, slow elegant baritone, slightly old-fashioned.'),
    'wanda': ('f', 60, 'Polish housing-association manager about 60, strict and bureaucratic but fair, firm clear voice.'),
    'nadia': ('f', 29, 'Young baker, 29, warm, practical and a little tired at four in the morning, soft friendly voice.'),
    'bartek': ('m', 28, 'Young Polish groom, 28, tipsy and happy after his wedding, sheepish, friendly light voice.'),
    'bride': ('f', 27, 'Young Polish bride, 27, tipsy and giggly after the wedding party, bright warm voice.'),
    'neighbour_robe': ('m', 62, 'Polish man in his sixties woken at 4 a.m. in a bathrobe, sleepy, grumpy but good-natured, rough low voice.'),
    'agnieszka': ('f', 45, 'Polish nurse, 45, exhausted after a twelve-hour shift, soft, slow, gentle voice.'),
    'renata': ('f', 52, 'Polish pizzeria owner, 52, talks fast, energetic, warm and loud-hearted, full mid voice.'),
    'mietek': ('m', 38, 'Polish kebab-shop owner, late thirties, jovial and hearty, friendly mid-low voice.'),
    'claimant': ('f', 33, 'Polish woman in her early thirties, too smooth and polite, a little nervous, mid-pitch voice.'),
    'neighbour_lucyna': ('f', 66, 'Polish woman in her sixties, alert, kind and slightly nosy neighbour, clear older voice.'),
    'darek': ('m', 40, 'Polish man about 40, agitated and defensive, tense clipped speech, mid-low voice.'),
    'stranger': ('m', 45, 'Polish man in a suit, mid forties, polite, slick and talks very fast, smooth mid voice.'),
    'marek': ('m', 46, 'Polish man in his mid forties, pushy and a bit scheming, confident mid voice.'),
    'piotr': ('m', 42, 'Polish man in his early forties, practical and calm, easygoing baritone.'),
    'ewa': ('f', 48, 'Polish woman, late forties, wry and nostalgic, warm mid-low voice.'),
    'irena': ('f', 79, 'Polish widow, 79, retired librarian, quiet, gentle, restrained emotion, soft aged voice.'),
    'kazimierz': ('m', 60, 'Polish man of 60 coming home from a name-day party, merry and a bit tipsy, jovial warm baritone.'),
    'teresa': ('f', 70, 'Polish woman about 70, startled behind her door, then proud and chatty, clear older voice.'),
    'basia': ('f', 45, 'Polish residents-committee secretary, mid forties, organised and cheerful, bright mid voice.'),
    'elzbieta': ('f', 52, 'Polish tenement manager, early fifties, firm and professional, composed clear voice.'),
    'norbert': ('m', 43, 'Polish man, 43, worried and evasive, slightly whiny mid voice.'),
    'marcel': ('m', 29, 'Young courier, 29, harried but polite, light friendly voice.'),
    'waldek': ('m', 72, 'Polish allotment gardener about 72, gruff, friendly and teasing, rough older voice.'),
    'zbyszek': ('m', 74, 'Polish allotment gardener, 74, cheerful and folksy, slightly raspy older voice, proud.'),
    'headteacher': ('f', 55, 'Polish school headmistress, mid fifties, formal, clear and composed voice.'),
}

FILLER = {
    'child': 'A potem pójdziemy na lody, bo tata obiecał. Ja pamiętam wszystko, co tata obiecuje.',
    'default': 'Dobrze, to poczekam tutaj na klatce. Proszę się nie spieszyć, naprawdę mamy jeszcze trochę czasu.',
}


def read_csv():
    with open(GAME / 'i18n/content.csv', encoding='utf-8', newline='') as f:
        rows = list(csv.reader(f))
    hdr = rows[0]
    return {r[0]: dict(zip(hdr[1:], r[1:])) for r in rows[1:] if r}


def inventory():
    rows = read_csv()
    out = []
    for f in sorted(glob.glob(str(GAME / 'data/jobs/*.json')) + glob.glob(str(GAME / 'data/jobs_ch7/*.json'))):
        d = json.load(open(f, encoding='utf-8'))
        for i, sp in enumerate(d.get('lines', [])):
            key = f"{d['id']}.line.{i + 1}"
            out.append({'job': d['id'], 'key': key, 'speaker': sp, 'text': rows[key]})
    return out


def tts_text(key, lang, text, tags=None):
    """Exact TTS input: optional audio tag(s) + spoken form. Subtitles (content.csv) never contain tags."""
    t = TTS_OVERRIDES.get((key, lang), text)
    tag = (tags or {}).get(key)
    return f'{tag} {t}' if tag else t


def design_payload():
    inv = inventory()
    res = {}
    for sp, (g, age, desc) in CAST.items():
        txt = ' '.join(l['text']['pl'] for l in inv if l['speaker'] == sp)
        fill = FILLER['child'] if age < 12 else FILLER['default']
        while len(txt) < 110:
            txt = (txt + ' ' + fill).strip()
        res[sp] = {'gender': g, 'age': age, 'description': desc, 'text': txt[:990]}
    return res


def tts_payload(jobs=None, langs=LANGS):
    cast = json.load(open(CAST_JSON, encoding='utf-8'))['voices']
    tags = json.load(open(TAGS_JSON, encoding='utf-8')) if TAGS_JSON.exists() else {}
    out = []
    for l in inventory():
        if jobs and l['job'] not in jobs:
            continue
        v = cast[l['speaker']]
        for lang in langs:
            out.append({'key': l['key'], 'lang': lang, 'speaker': l['speaker'], 'voice_id': v['voice_id'],
                        'model_id': v.get('model', MODEL), 'voice_settings': v['settings'],
                        'seed': int(hashlib.sha1(l['key'].encode()).hexdigest()[:6], 16),
                        'subtitle': l['text'][lang], 'text': tts_text(l['key'], lang, l['text'][lang], tags)})
    return out


def synth(reqs, raw_dir):
    key = os.environ.get('ELEVENLABS_API_KEY')
    if not key:
        sys.exit('ELEVENLABS_API_KEY not set (see module docstring for the Composio path)')
    for r in reqs:
        p = pathlib.Path(raw_dir) / r['lang'] / f"{r['key']}.pcm"
        if p.exists():
            continue
        p.parent.mkdir(parents=True, exist_ok=True)
        body = {k: r[k] for k in ('text', 'model_id', 'voice_settings', 'seed')}
        req = urllib.request.Request(
            f"https://api.elevenlabs.io/v1/text-to-speech/{r['voice_id']}?output_format=pcm_48000",
            data=json.dumps(body).encode(), headers={'xi-api-key': key, 'Content-Type': 'application/json'})
        p.write_bytes(urllib.request.urlopen(req).read())
        print('ok', p)


IMPORT_TMPL = """[remap]

importer="oggvorbisstr"
type="AudioStreamOggVorbis"
uid="uid://{uid}"
path="res://.godot/imported/{name}-{md5}.oggvorbisstr"

[deps]

source_file="{res}"
dest_files=["res://.godot/imported/{name}-{md5}.oggvorbisstr"]

[params]

loop=false
loop_offset=0
bpm=0
beat_count=0
bar_beats=4
"""


def godot_uid(seed):
    """Deterministic uid encoded like Godot's ResourceUID::id_to_text (base 35: a-z then 0-8, 63-bit id)."""
    chars = 'abcdefghijklmnopqrstuvwxyz012345678'
    n = int(hashlib.sha256(seed.encode()).hexdigest(), 16) & ((1 << 63) - 1)
    s = ''
    while True:
        s = chars[n % 35] + s
        n //= 35
        if n == 0:
            return s


def write_import(ogg):
    res = 'res://' + str(ogg.relative_to(GAME)).replace(os.sep, '/')
    md5 = hashlib.md5(res.encode()).hexdigest()
    ogg.with_suffix('.ogg.import').write_text(IMPORT_TMPL.format(uid=godot_uid(res), name=ogg.name, md5=md5, res=res))


def finish(raw_dir):
    """PCM s16le 48 kHz mono (or WAV) -> trimmed, loudness-normalised mono 48 kHz Ogg Vorbis q4 + .import."""
    for src in sorted(pathlib.Path(raw_dir).glob('*/*')):
        if src.suffix not in ('.pcm', '.wav'):
            continue
        lang, key = src.parent.name, src.stem
        dst = OUT / lang / f'{key}.ogg'
        dst.parent.mkdir(parents=True, exist_ok=True)
        inp = ['-f', 's16le', '-ar', '48000', '-ac', '1', '-i', str(src)] if src.suffix == '.pcm' else ['-i', str(src)]
        trim = ('silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.06,areverse,'
                'silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.06,areverse')
        # two-pass loudnorm (linear) to TARGET_LUFS, true peak -1.5 dBTP
        a = subprocess.run(['ffmpeg', '-hide_banner', '-nostats', *inp, '-af',
                            f'{trim},loudnorm=I={TARGET_LUFS}:TP=-1.5:LRA=11:print_format=json', '-f', 'null', '-'],
                           capture_output=True, text=True).stderr
        m = json.loads(a[a.rindex('{'):a.rindex('}') + 1])
        ln = (f"loudnorm=I={TARGET_LUFS}:TP=-1.5:LRA=11:measured_I={m['input_i']}:measured_TP={m['input_tp']}:"
              f"measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}:offset={m['target_offset']}:linear=true")
        subprocess.run(['ffmpeg', '-v', 'error', '-y', *inp, '-af', f'{trim},{ln},aresample=48000',
                        '-ac', '1', '-ar', '48000', '-c:a', 'libvorbis', '-q:a', '4', '-map_metadata', '-1', str(dst)],
                       check=True)
        write_import(dst)
    print('done')


def _norm_words(t):
    t = re.sub(r'\[[^\]]*\]', ' ', t.lower())
    return re.findall(r"[^\W_]+(?:'[^\W_]+)?", t)


def wer(ref, hyp):
    r, h = _norm_words(ref), _norm_words(hyp)
    d = list(range(len(h) + 1))
    for i in range(1, len(r) + 1):
        prev, d[0] = d[0], i
        for j in range(1, len(h) + 1):
            cur = min(d[j] + 1, d[j - 1] + 1, prev + (r[i - 1] != h[j - 1]))
            prev, d[j] = d[j], cur
    return d[len(h)], max(len(r), 1)


def qa(langs, model='small', out_json=None):
    """Duration, integrated loudness, leading/trailing silence and ASR word error rate against the subtitle."""
    from faster_whisper import WhisperModel
    import numpy as np
    m = WhisperModel(model, device='cpu', compute_type='int8')
    rows = read_csv()
    res, tot = [], {}
    for lang in langs:
        for ogg in sorted((OUT / lang).glob('*.ogg')):
            key = ogg.stem
            pcm = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(ogg), '-ac', '1', '-ar', '16000', '-f', 'f32le', '-'],
                                 capture_output=True, check=True).stdout
            x = np.frombuffer(pcm, np.float32)
            lu = subprocess.run(['ffmpeg', '-hide_banner', '-nostats', '-i', str(ogg), '-af', 'ebur128', '-f', 'null', '-'],
                                capture_output=True, text=True).stderr
            li = float(re.findall(r'I:\s+(-?[\d.]+) LUFS', lu)[-1])
            env = np.abs(x) > 10 ** (-45 / 20)
            nz = np.nonzero(env)[0]
            lead, trail = (nz[0] / 16000, (len(x) - nz[-1]) / 16000) if len(nz) else (0, 0)
            segs, _ = m.transcribe(x, language=lang, beam_size=5, vad_filter=False)
            hyp = ' '.join(s.text.strip() for s in segs)
            e, n = wer(rows[key][lang], hyp)
            t = tot.setdefault(lang, [0, 0]); t[0] += e; t[1] += n
            res.append({'file': f'{lang}/{ogg.name}', 'dur': round(len(x) / 16000, 2), 'lufs': li,
                        'lead_ms': round(lead * 1000), 'trail_ms': round(trail * 1000),
                        'wer': round(e / n, 3), 'ref': rows[key][lang], 'asr': hyp})
            print(json.dumps(res[-1], ensure_ascii=False), flush=True)
    summary = {l: round(e / n, 4) for l, (e, n) in tot.items()}
    print('WER', summary)
    if out_json:
        pathlib.Path(out_json).write_text(json.dumps({'wer': summary, 'files': res}, ensure_ascii=False, indent=1) + '\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd')
    ap.add_argument('arg', nargs='?')
    ap.add_argument('--jobs')
    ap.add_argument('--lang', default=','.join(LANGS))
    a = ap.parse_args()
    jobs = set(a.jobs.split(',')) if a.jobs else None
    langs = a.lang.split(',')
    if a.cmd == 'inventory':
        inv = inventory()
        from collections import Counter
        print(len(inv), 'lines;', Counter(l['speaker'] for l in inv).most_common())
    elif a.cmd == 'design-payload':
        print(json.dumps(design_payload(), ensure_ascii=False, indent=1))
    elif a.cmd == 'tts-payload':
        print(json.dumps(tts_payload(jobs, langs), ensure_ascii=False))
    elif a.cmd == 'manifest':
        reqs = tts_payload(None, langs)
        MANIFEST.write_text(json.dumps({f"{r['lang']}/{r['key']}.ogg": {k: r[k] for k in (
            'speaker', 'voice_id', 'model_id', 'voice_settings', 'seed', 'text', 'subtitle')} for r in reqs},
            ensure_ascii=False, indent=1, sort_keys=True) + '\n', encoding='utf-8')
        print(MANIFEST, len(reqs))
    elif a.cmd == 'synth':
        synth(tts_payload(jobs, langs), a.arg or 'contrib/voice/raw')
    elif a.cmd == 'qa':
        qa(langs, out_json=a.arg)
    elif a.cmd == 'finish':
        finish(a.arg)
    else:
        sys.exit(__doc__)


if __name__ == '__main__':
    main()
