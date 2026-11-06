#!/usr/bin/env python3
"""QA part 3 (session C, stage 5, task 5): every arrival screen has a G07 background, every speaking character has a
G09 portrait (and an S03 voice), and every sound the game data or code asks for exists as a file.

The mappings are read from the game itself (no copies here, so the check follows the game when it changes):
  - ARRIVAL_BG, CAST_SLOT          from game/scripts/ui/job_arrival.gd
  - EVENTS, MATERIALS, VARIANTS,   from game/scripts/autoload/sfx.gd
    AMBIENCES and the *_ROOT dirs
  - lock event sounds              from game/data/haptics_patterns.json (events.<id>.sfx.{id,variants})
  - one-shot sounds                from every Sfx.play_<kind>(&"name") call in game/scripts
  - jobs                           game/data/jobs/*.json (chapters 1-12, D-71) (place, time, lines)

    python3 qa/assets/check_assets.py [--out qa/out/assets]     -> report.md, report.json; exit 0 (findings are ⚠)
"""
import argparse, json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
GAME = ROOT / 'game'
NARRATOR = {'locksmith'}  # the player character: no portrait, no voice (CLIENTS.md)


def gd_dict(src: str, name: str) -> dict:
    """Parse a `const NAME := { ... }` GDScript dictionary of strings / nested dictionaries."""
    m = re.search(r'const\s+' + name + r'\s*:?=\s*\{', src)
    if not m:
        raise SystemExit(f'{name} not found')
    i, depth = m.end() - 1, 0
    for j in range(i, len(src)):
        depth += src[j] == '{'
        depth -= src[j] == '}'
        if depth == 0:
            body = src[i:j + 1]
            break
    body = re.sub(r'#.*', '', body)
    body = re.sub(r'&"', '"', body)  # StringName literals
    body = re.sub(r',(\s*[}\]])', r'\1', body)  # trailing commas
    return json.loads(body)


def gd_list(src: str, name: str) -> list:
    m = re.search(r'const\s+' + name + r'\s*:?=\s*\[([^\]]*)\]', src)
    return re.findall(r'&?"([^"]+)"', m.group(1)) if m else []


def gd_const(src: str, name: str) -> str:
    m = re.search(r'const\s+' + name + r'\s*:?=\s*"?([^"\n#]+)"?', src)
    return m.group(1).strip() if m else ''


def res(path: str) -> pathlib.Path:
    return GAME / path.replace('res://', '')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=str(ROOT / 'qa/out/assets'))
    a = ap.parse_args()
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    arrival_src = (GAME / 'scripts/ui/job_arrival.gd').read_text()
    sfx_src = (GAME / 'scripts/autoload/sfx.gd').read_text()
    bg = gd_dict(arrival_src, 'ARRIVAL_BG')
    cast = gd_dict(arrival_src, 'CAST_SLOT')
    roots = {k: gd_const(sfx_src, k) for k in ('SFX_ROOT', 'AMBIENCE_ROOT', 'UI_ROOT', 'REWARD_ROOT', 'MUSIC_ROOT',
                                                'FOLEY_ROOT', 'VOICE_ROOT')}
    materials = gd_list(sfx_src, 'MATERIALS')
    ambiences = gd_list(sfx_src, 'AMBIENCES')
    variants = int(gd_const(sfx_src, 'VARIANTS') or 6)
    voice_dirs = gd_dict(sfx_src, 'VOICE_DIR') if 'VOICE_DIR' in sfx_src else {}  # N-48: shared S03 folders

    jobs = []
    for d in ('jobs',):
        for f in sorted((GAME / 'data' / d).glob('*.json')):
            j = json.loads(f.read_text())
            j['_file'] = f'{d}/{f.name}'
            jobs.append(j)

    # 1) G07 background for every arrival (same resolution rule as job_arrival.gd::_arrival_image)
    arrivals = []
    for j in jobs:
        place, time = j.get('place', 'apartment'), j.get('time', 'evening')
        problems = []
        if 'place' not in j:
            problems.append('brak pola place (gra bierze domyślne „apartment”)')
        if place not in bg:
            problems.append(f'nieznane place „{place}” → tło domyślne')
        by_place = bg.get(place, bg['apartment'])
        img = by_place.get(time, by_place.get('', '02_apartment_evening.jpg'))
        if place in bg and time not in by_place and '' not in by_place:
            problems.append(f'brak tła dla pory „{time}” → domyślne')
        f = GAME / 'assets/ui/gpt/arrival' / img
        if not f.exists():
            problems.append(f'brak pliku tła {img}')
        arrivals.append({'job': j.get('id'), 'file': j['_file'], 'place': place, 'time': time, 'image': img,
                         'problems': problems})

    # 2) G09 portrait (+ S03 voice) for every speaking character
    speakers = {}
    for j in jobs:
        for s in j.get('lines', []):
            if s in NARRATOR:
                continue
            speakers.setdefault(s, set()).add(j.get('id'))
    cast_rows = []
    voice_root = res(roots['VOICE_ROOT'])
    for s, js in sorted(speakers.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        slot = cast.get(s)
        avatar = GAME / 'assets/ui/gpt/cast' / slot / 'avatar.png' if slot else None
        # D-50: episodic Magnific portraits (job_arrival.gd) when the speaker has no G09 cast slot
        episodic = GAME / 'assets/ui/gpt/cast/episodic' / f'portrait_{s}.webp'
        has_portrait = bool(avatar and avatar.exists()) or episodic.exists()
        # the game's rule (sfx.gd play_voice, N-48): <VOICE_ROOT>/<VOICE_DIR[speaker]>/<kind>.wav or <kind>_NN.wav
        vdir = voice_dirs.get(s, s)
        vd = voice_root / vdir
        has_voice = vd.is_dir() and bool(list(vd.glob('greeting.wav')) + list(vd.glob('greeting_*.wav')))
        # files that exist but the rule does not find (a shared folder named after the cast slot)
        near = [d for d in (voice_root / s, voice_root / (slot or '').split('_', 1)[-1]) if d.is_dir()]
        near_file = next((str(f.relative_to(GAME)) for d in near for f in sorted(d.glob('greeting*.wav'))), '')
        cast_rows.append({'speaker': s, 'jobs': sorted(js), 'slot': slot, 'portrait': has_portrait, 'voice': has_voice,
                          'voice_file_not_found_by_game': '' if has_voice else near_file})

    # 3) sounds: lock events from data, ambiences, and every Sfx.play_* call in the code
    sounds = []
    hp = json.loads((GAME / 'data/haptics_patterns.json').read_text())
    sfx_root = res(roots['SFX_ROOT'])
    for ev, spec in sorted(hp.get('events', {}).items()):
        sx = spec.get('sfx') or {}
        sid, n = sx.get('id'), int(sx.get('variants', variants))
        if not sid:
            continue
        have = {m: [k for k in range(1, n + 1) if (sfx_root / sid / f'{m}_{k}.wav').exists()] for m in materials}
        full = [m for m, ks in have.items() if len(ks) == n]
        partial = {m: n - len(ks) for m, ks in have.items() if 0 < len(ks) < n}
        prob = []
        if not full:
            prob.append(f'żaden materiał nie ma kompletu {n} wariantów')
        if partial:
            prob.append('niepełne: ' + ', '.join(f'{m} (brak {c})' for m, c in partial.items()))
        sounds.append({'kind': 'lock', 'name': f'{ev} → {sid}', 'where': 'data/haptics_patterns.json',
                       'ok': not prob, 'detail': '; '.join(prob) or f'komplet: {", ".join(full)}'})
    for amb in ambiences:
        f = res(roots['AMBIENCE_ROOT']) / f'{amb}.wav'
        sounds.append({'kind': 'ambience', 'name': amb, 'where': 'sfx.gd AMBIENCES', 'ok': f.exists(),
                       'detail': '' if f.exists() else f'brak {f.relative_to(GAME)}'})
    calls = {}
    for f in sorted((GAME / 'scripts').rglob('*.gd')):
        for m in re.finditer(r'Sfx\.play_(ui|reward|foley|music|jingle|ambience|voice)\((&?"[^"]+"|[a-z_]+)', f.read_text()):
            calls.setdefault((m.group(1), m.group(2).lstrip('&').strip('"')), set()).add(str(f.relative_to(GAME)))
    one_shot_root = {'ui': 'UI_ROOT', 'reward': 'REWARD_ROOT', 'foley': 'FOLEY_ROOT'}
    for (kind, name), where in sorted(calls.items()):
        if kind in one_shot_root:
            d = res(roots[one_shot_root[kind]])
            ok = any(d.glob(f'{name}_*.wav'))
            detail = '' if ok else f'brak {d.relative_to(GAME)}/{name}_*.wav'
        elif kind in ('music', 'jingle'):
            f = res(roots['MUSIC_ROOT']) / f'{name}.ogg'
            ok, detail = f.exists(), '' if f.exists() else f'brak {f.relative_to(GAME)}'
        elif kind == 'ambience':
            f = res(roots['AMBIENCE_ROOT']) / f'{name}.wav'
            ok, detail = f.exists(), '' if f.exists() else f'brak {f.relative_to(GAME)}'
        else:  # voice(speaker, kind): speaker is a variable; checked per character above
            continue
        sounds.append({'kind': kind, 'name': name, 'where': ', '.join(sorted(where)), 'ok': ok, 'detail': detail})

    bad_arr = [r for r in arrivals if r['problems']]
    no_portrait = [r for r in cast_rows if not r['portrait']]
    no_voice = [r for r in cast_rows if not r['voice']]
    bad_snd = [r for r in sounds if not r['ok']]
    md = ['# QA zasobów: tła przyjazdu (G07), portrety (G09), dźwięki', '',
          f'Zlecenia: {len(jobs)} · tło G07 bez problemu: **{len(arrivals) - len(bad_arr)}/{len(arrivals)}** · '
          f'postacie mówiące: {len(cast_rows)}, z portretem (G09 / epizodyczny): **{len(cast_rows) - len(no_portrait)}/{len(cast_rows)}**, '
          f'z głosem S03: **{len(cast_rows) - len(no_voice)}/{len(cast_rows)}** · dźwięki: **{len(sounds) - len(bad_snd)}/{len(sounds)}** istnieją', '',
          '## Tła przyjazdu (G07)', '']
    md += ([f'- ⚠ `{r["job"]}` ({r["file"]}): ' + '; '.join(r['problems']) for r in bad_arr] or ['- wszystkie zlecenia mają tło G07'])
    md += ['', '## Postacie bez portretu (G09 albo epizodyczny Magnific, D-50) lub bez głosu', '',
           '| Postać | Zlecenia | Portret | Głos S03 |', '|---|---|---|---|']
    md += [f'| {r["speaker"]} | {len(r["jobs"])}: {", ".join(r["jobs"][:3])}{"…" if len(r["jobs"]) > 3 else ""} | '
           f'{"✅" if r["portrait"] else "⚠ brak"} | '
           f'{"✅" if r["voice"] else ("⚠ plik jest (`" + r["voice_file_not_found_by_game"] + "`), gra go nie znajduje" if r["voice_file_not_found_by_game"] else "⚠ brak")} |'
           for r in cast_rows if not r['portrait'] or not r['voice']] or ['| — | — | — | — |']
    md += ['', '## Dźwięki', '', '| Rodzaj | Nazwa | Skąd | Stan |', '|---|---|---|---|']
    md += [f'| {r["kind"]} | `{r["name"]}` | {r["where"]} | {"✅ " + r["detail"] if r["ok"] else "⚠ " + r["detail"]} |' for r in sounds]
    (out / 'report.md').write_text('\n'.join(md) + '\n')
    (out / 'report.json').write_text(json.dumps({'arrivals': arrivals, 'cast': cast_rows, 'sounds': sounds}, indent=1,
                                                ensure_ascii=False, default=list))
    print(md[2])
    if __import__('os').environ.get('GITHUB_ACTIONS'):
        for r in bad_arr:
            print(f"::warning title=QA zasobów: tło G07::{r['job']}: {'; '.join(r['problems'])}")
        if no_portrait:
            print(f"::warning title=QA zasobów: portrety G09::{len(no_portrait)} postaci bez portretu: "
                  + ', '.join(r['speaker'] for r in no_portrait[:15]))
        for r in bad_snd:
            print(f"::warning title=QA zasobów: dźwięk::{r['kind']} {r['name']}: {r['detail']}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
