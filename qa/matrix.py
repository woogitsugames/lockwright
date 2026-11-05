#!/usr/bin/env python3
"""Summary table of qa/run_matrix.sh runs -> qa/out/matrix.md (Polish, for the owner and SESSION-C-REVIEW)."""
import json, pathlib, sys

out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else 'qa/out')
L = ['# QA kariery — macierz profili', '',
     '| Przebieg | Profil | Język | Ciemność | Zlecenia | Zamki otwarte / próby | Soft-locki | Brak. klucze | Monety | Czas sym. | Zdarzenia bez dźwięku / haptyki | Ekonomia > 10% |',
     '|---|---|---|---|---|---|---|---|---|---|---|---|']
for name in ['solver', 'feel', 'clumsy', 'en', 'dark']:
    p = out / name / 'report.json'
    if not p.exists():
        L.append(f'| {name} | — | — | — | brak raportu | | | | | | | |')
        continue
    r = json.loads(p.read_text())
    b = r.get('bot', {})
    locks = b.get('locks', [])
    opened = sum(1 for k in locks if k.get('opened'))
    ch = r.get('channels', {})
    eco = r.get('economy', {}).get('over_10pct', [])
    L.append(f"| {name} | {b.get('profile', '?')} | {b.get('lang', 'system')} | {b.get('dark', False)} | "
             f"{len(b.get('jobs_completed', []))} / {b.get('jobs_total', '?')} | {opened} / {len(locks)} | {len(b.get('softlocks', []))} | "
             f"{len(r.get('missing_i18n_keys', []))} | {b.get('coins', '?')} | {b.get('sim_seconds', '?')} s | "
             f"{len(ch.get('without_audio', []))} / {len(ch.get('without_haptic', []))} | {len(set(eco))} |")
L += ['', 'Szczegóły: `qa/out/<przebieg>/report.md`.']
(out / 'matrix.md').write_text('\n'.join(L) + '\n')
print('\n'.join(L))
