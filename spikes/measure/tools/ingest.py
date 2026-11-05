#!/usr/bin/env python3
"""Reads measurement JSON files (schema lockwright.measure/1, spikes/measure/SPEC.md), recomputes p50/p95 and
verdicts from samples_ms with spikes/measure/thresholds.json, and writes a results table into docs/TECH.md
between <!-- MEASURE:BEGIN --> and <!-- MEASURE:END --> (the section is created at the end if missing).

  python3 spikes/measure/tools/ingest.py results/*.json            # update docs/TECH.md
  python3 spikes/measure/tools/ingest.py results/*.json --print    # only print the table
Files can also be pasted text (the share sheet sends the JSON as text): save it as .json first."""
import sys, json, pathlib, datetime, re

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent.parent
TH = json.loads((HERE.parent / 'thresholds.json').read_text())
TECH = ROOT / 'docs' / 'TECH.md'
BEGIN, END = '<!-- MEASURE:BEGIN -->', '<!-- MEASURE:END -->'
WORD = {'pass': 'przechodzi', 'border': 'na granicy', 'fail': 'NIE przechodzi', 'no_data': 'brak danych'}

def pct(xs, q):
    s = sorted(xs)
    return s[min(len(s) - 1, int(q * (len(s) - 1) + 0.5))] if s else None

def stat(m):
    if not isinstance(m, dict):
        return None, None, 0
    xs = [float(v) for v in m.get('samples_ms', []) if v is not None and v >= 0]
    if xs:
        return pct(xs, 0.5), pct(xs, 0.95), len(xs)
    return m.get('p50_ms'), m.get('p95_ms'), int(m.get('n', 0))

def verdict_p95(p95, n, key, cls):
    th = TH.get(key, {}).get(cls)
    if p95 is None or n < 5 or not th:
        return 'no_data'
    lim = th['pass']; fail = th.get('fail', lim * 1.25)
    return 'pass' if p95 <= lim else ('border' if p95 <= fail else 'fail')

def verdict_max(v, lim):
    if v is None or v < 0:
        return 'no_data'
    return 'pass' if v <= lim else ('border' if v <= lim * 1.25 else 'fail')

def device_class(d):
    """Class used for thresholds. Older app builds labelled every Samsung SM-A*/SM-M* as 'samsung_a'; budget lines
    (A0x/A1x/A2x, M0x-M2x) and any phone with an A0/none haptic tier (ERM without amplitude control) are 'budget'
    (TECH §6.2 #8/#9, GEM3 BUG-12). Returns (class, label shown in the table)."""
    cls = d.get('class', 'budget')
    tier = d.get('haptic_tier', '')
    fixed = cls
    if tier in ('A0', 'none'):
        fixed = 'budget'
    elif cls == 'samsung_a':
        mm = re.match(r'SM-[AM](\d)', str(d.get('model', '')).upper())
        if mm and int(mm.group(1)) < 3:
            fixed = 'budget'
    return fixed, (cls if fixed == cls else f'{fixed} (aplikacja: {cls})')

def row(doc, name):
    d = doc.get('device', {}); m = doc.get('metrics', {})
    cls, cls_label = device_class(d)
    cells = [f"{d.get('manufacturer', '')} {d.get('model', '')}".strip(), f"{d.get('platform', '')} {d.get('os', '')}",
             cls_label, d.get('haptic_tier', '?'), f"{d.get('accel_hz', m.get('accel_hz', '?'))}"]
    out = []
    for key, mk in (('haptic_tap_p95_ms', 'haptic_tap'), ('haptic_call_p95_ms', 'haptic_call'), ('audio_tap_p95_ms', 'audio_tap')):
        p50, p95, n = stat(m.get(mk))
        v = verdict_p95(p95, n, key, cls)
        rej = int((m.get(mk) or {}).get('rejected', 0) or 0) if isinstance(m.get(mk), dict) else 0
        out.append(f"{p50:.0f} / {p95:.0f} ms ({WORD[v]})" if p95 is not None and n
                   else WORD['no_data'] + (f' (odrzucone {rej}/{rej + n})' if rej else ''))
    f50, _, fn = stat(m.get('audio_call_fast')); e50, _, en = stat(m.get('audio_call_engine'))
    if fn >= 5 and en >= 5:
        g = e50 - f50; mn = TH['audio_oboe_gain_ms']['min']
        v = 'pass' if g >= mn else ('border' if g >= 0.75 * mn else 'fail')
        out.append(f"{f50:.0f} vs {e50:.0f} ms → {g:.0f} ms ({WORD[v]})")
    else:
        out.append(f"{f50:.0f} ms (bez porównania)" if fn else WORD['no_data'])
    gap = m.get('continuous_max_gap_ms')
    if m.get('continuous_tier', d.get('haptic_tier')) in ('A0', 'none') and isinstance(gap, (int, float)):
        out.append(f"{gap:.0f} ms (nie dotyczy: {m.get('continuous_tier', d.get('haptic_tier'))} bez oporu ciągłego, TECH §2.2)")
        gap = None
    else:
        out.append(f"{gap:.0f} ms ({WORD[verdict_max(gap, TH['continuous_max_gap_ms']['pass'])]})" if isinstance(gap, (int, float)) and gap >= 0 else WORD['no_data'])
    _, s95, sn = stat(m.get('audio_haptic_sync'))
    out.append(f"{s95:.0f} ms ({WORD[verdict_max(s95, TH['audio_haptic_sync_ms']['pass'])]})" if sn >= 5 else WORD['no_data'])
    return '| ' + ' | '.join(cells + out + [doc.get('created_utc', '')[:10], name]) + ' |'

def table(files):
    head = ('| Telefon | System | Klasa | Tier haptyki | Akcel. [Hz] | Stuknięcie→drganie p50/p95 | Polecenie→drganie p50/p95 '
            '| Stuknięcie→klik p50/p95 | Dźwięk: szybka vs silnik (p50) | Przerwa w oporze | Dźwięk↔drganie p95 | Data | Plik |')
    sep = '|' + '---|' * 13
    rows = []
    for f in files:
        doc = json.loads(pathlib.Path(f).read_text(encoding='utf-8'))
        if doc.get('schema') != 'lockwright.measure/1':
            print(f'skip {f}: schema {doc.get("schema")}', file=sys.stderr); continue
        rows.append(row(doc, pathlib.Path(f).name))
    note = (f'Aktualizacja: {datetime.date.today().isoformat()} (`spikes/measure/tools/ingest.py`). Metoda D-33: akcelerometr i mikrofon telefonu + znaczniki '
            'wewnętrzne; dokładność 2–5 ms (akcelerometr ≥ 200 Hz) albo ±10 ms (100 Hz, iPhone). Progi: `spikes/measure/thresholds.json` (= §4). '
            '„Stuknięcie→…” liczone od drgania obudowy przy uderzeniu palca, więc obejmuje opóźnienie ekranu dotykowego.')
    return '\n'.join([BEGIN, '', note, '', head, sep] + rows + ['', END])

def main(a):
    files = [x for x in a if x.endswith('.json')]
    if not files:
        print(__doc__); return 2
    t = table(files)
    if '--print' in a:
        print(t); return 0
    s = TECH.read_text(encoding='utf-8')
    if BEGIN in s and END in s:
        s = s[:s.index(BEGIN)] + t + s[s.index(END) + len(END):]
    else:
        s = s.rstrip() + '\n\n## 8. Wyniki pomiarów na telefonach właściciela (D-33)\n\n' + t + '\n'
    TECH.write_text(s, encoding='utf-8')
    print(f'updated {TECH} with {len(files)} file(s)')
    return 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
