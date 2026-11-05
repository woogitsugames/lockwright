#!/usr/bin/env python3
"""QA career report: merges the bot's QA_REPORT JSON with what the Godot log shows.
   python3 qa/report.py <career.log> <out-dir> <exit-code>
Writes report.json and report.md. Findings: crashes (exit code, signals, SCRIPT ERROR), soft-locks, screens without
an exit, unknown screens, missing i18n keys (I18n warnings), engine errors, per-lock timings, session time."""
import sys, os, json, re, pathlib, collections

log_path, out_dir, code = sys.argv[1], pathlib.Path(sys.argv[2]), int(sys.argv[3])
text = pathlib.Path(log_path).read_text(errors='replace')
bot = {}
for line in text.splitlines():
    if line.startswith('QA_REPORT '):
        bot = json.loads(line[len('QA_REPORT '):])
missing = sorted(set(re.findall(r'missing translation for key ([\w.\-]+)', text)))
script_errors = [l.strip() for l in text.splitlines() if 'SCRIPT ERROR' in l]
errors = [l.strip() for l in text.splitlines() if l.startswith('ERROR:') and 'ALSA' not in l and 'audio_driver' not in l]
err_counts = collections.Counter(re.sub(r'\d+', 'N', e)[:160] for e in errors)
crashed = code not in (0,) or 'Program crashed' in text or 'handle_crash' in text or not bot
timeout = code == 124
rep = {
    'schema': 'lockwright.qa-report/1', 'exit_code': code, 'crashed': crashed and not timeout, 'timeout': timeout,
    'bot': bot, 'missing_i18n_keys': missing, 'script_errors': script_errors[:50], 'engine_errors': dict(err_counts.most_common(30)),
}
(out_dir / 'report.json').write_text(json.dumps(rep, indent=2, ensure_ascii=False))
L = ['# QA kariery — raport', '']
verdict = 'OK' if (bot.get('finished') and not script_errors and not missing and not crashed
                  and not bot.get('softlocks') and not bot.get('dead_ends')) else 'PROBLEMY'
L.append(f"**Wynik: {verdict}** · exit {code}{' (timeout)' if timeout else ''} · koniec: `{bot.get('end_reason', 'brak raportu bota')}`")
L.append('')
L.append('| Miara | Wartość |')
L.append('|---|---|')
L.append(f"| Zlecenia ukończone / wszystkie | {len(bot.get('jobs_completed', []))} / {bot.get('jobs_total', '?')} |")
L.append(f"| Samouczek ukończony | {bot.get('tutorial_done')} |")
L.append(f"| Zakupy w warsztacie (akcje) | {bot.get('purchases', 0)} |")
L.append(f"| Gablota: otwarte notki | {bot.get('showcase_opened', 0)} |")
L.append(f"| Monety na końcu | {bot.get('coins', '?')} |")
L.append(f"| Czas sesji (symulowany, 120 Hz) | {bot.get('sim_seconds', '?')} s |")
L.append(f"| Czas zegarowy | {bot.get('wall_seconds', '?')} s |")
L.append(f"| Decyzje bota | {bot.get('decisions', '?')} |")
L.append('')
for title, key in (('Soft-locki', 'softlocks'), ('Ekrany bez wyjścia', 'dead_ends')):
    items = bot.get(key, [])
    L.append(f'## {title} ({len(items)})')
    L += [f"- `{i.get('scene', '')}` — {i.get('reason', '')}" + (f" (zlecenie `{i['job']}`)" if i.get('job') else '') for i in items] or ['- brak']
    L.append('')
L.append(f"## Nieznane ekrany (polityka ogólna) ({len(bot.get('unknown_scenes', []))})")
L += [f'- `{s}`' for s in bot.get('unknown_scenes', [])] or ['- brak']
L.append('')
L.append(f'## Brakujące klucze i18n ({len(missing)})')
L += [f'- `{k}`' for k in missing] or ['- brak']
L.append('')
L.append(f'## Błędy skryptów ({len(script_errors)})')
L += [f'- `{e[:200]}`' for e in script_errors[:20]] or ['- brak']
L.append('')
L.append('## Błędy silnika (najczęstsze)')
L += [f'- {n}× `{e}`' for e, n in err_counts.most_common(15)] or ['- brak']
L.append('')
locks = bot.get('locks', [])
L.append(f'## Zamki ({len(locks)})')
L.append('| Zlecenie | Rodzina | Tier | Kroki bota | Czas [s] | Otwarty | Błąd |')
L.append('|---|---|---|---|---|---|---|')
for k in locks:
    L.append(f"| {k.get('job') or '—'} | {k.get('family')} | {k.get('tier')} | {k.get('bot_steps', '')} | {k.get('sim_s', '')} | {k.get('opened', '')} | {k.get('error', '')} |")
L.append('')
L.append('## Odwiedzone ekrany')
L += [f'- `{s}` × {n}' for s, n in sorted(bot.get('scenes', {}).items())]
(out_dir / 'report.md').write_text('\n'.join(L) + '\n')
# ---- stage 4: economy vs tools/econ_sim.py, channels for "in the dark", profile/lang
econ_rows, econ_flags = [], []
try:
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / 'tools'))
    import econ_sim
    prof_map = {'solver': 'careful', 'feel': 'average', 'clumsy': 'clumsy'}
    prof = econ_sim.PROFILES[prof_map.get(bot.get('profile', 'solver'), 'average')]
    for k in locks:
        if 'coins_after' not in k or not k.get('job', '').startswith('job.'):
            continue
        ev = k.get('events', {})
        clean = k.get('opened') and not ev.get('drop') and not ev.get('break')
        r = int(k.get('reward_data', 0))
        exp = round(r + (r * prof['tip'] / prof['clean'] if clean else 0))
        got = int(k['coins_after']) - int(k.get('coins_before', 0))
        diff = (got - exp) / exp * 100 if exp else 0.0
        econ_rows.append((k['job'], r, exp, got, diff, clean))
        if abs(diff) > 10:
            econ_flags.append(k['job'])
except Exception as e:  # econ_sim missing or changed: report, do not fail
    econ_rows.append(('(błąd porównania)', 0, 0, 0, 0.0, str(e)[:80]))
rep['economy'] = {'rows': econ_rows, 'over_10pct': econ_flags}
ch = bot.get('channels', {})
silent = sorted(k for k, v in ch.items() if not v.get('audio'))
nohap = sorted(k for k, v in ch.items() if not v.get('haptic'))
rep['channels'] = {'kinds_seen': len(ch), 'without_audio': silent, 'without_haptic': nohap}
(out_dir / 'report.json').write_text(json.dumps(rep, indent=2, ensure_ascii=False))
L.append('')
L.append(f"## Zlecenia niewidoczne na liście w grze ({len(bot.get('not_listed', []))}): {', '.join(bot.get('not_listed', [])) or 'brak'}")
L.append('')
L.append(f"## Profil, język, tryb: `{bot.get('profile', 'solver')}` · `{bot.get('lang', 'system')}` · ciemność: {bot.get('dark', False)}")
L.append('')
L.append(f'## Kanały informacji (zdarzenia zamka → dźwięk / haptyka): {len(ch)} par zdarzenie/materiał')
L.append(f"- bez dźwięku: {', '.join(silent) or 'brak'}")
L.append(f"- bez haptyki: {', '.join(nohap) or 'brak'}")
L.append('')
L.append('## Ekonomia: gra vs `tools/econ_sim.py` (ten sam profil)')
L.append('| Zlecenie | Nagroda w danych | Oczekiwane (econ_sim: nagroda + napiwek przy czystym otwarciu) | W grze | Różnica |')
L.append('|---|---|---|---|---|')
for j, r, e, g, d, c in econ_rows:
    L.append(f"| {j} | {r} | {e} | {g} | {d:+.0f}%{' ⚠' if abs(d) > 10 else ''} |")
if not econ_rows:
    L.append('| — | — | — | — | brak zleceń z zapłatą |')

print('\n'.join(L[:14]))
(out_dir / 'report.md').write_text('\n'.join(L) + '\n')
(out_dir / 'verdict.txt').write_text(verdict + '\n')
# CI: game problems -> annotations (run stays green); workflow/engine problems -> red run
if os.environ.get('GITHUB_ACTIONS'):
    for x in bot.get('softlocks', []):
        print(f"::warning title=QA gry: soft-lock::{x.get('scene')} {x.get('job', '')}: {x.get('reason')}")
    for x in bot.get('dead_ends', []):
        print(f"::warning title=QA gry: ekran bez wyjścia::{x.get('scene')}: {x.get('reason')}")
    for k in missing[:20]:
        print(f"::warning title=QA gry: brak klucza i18n::{k}")
    for e in script_errors[:10]:
        print(f"::warning title=QA gry: błąd skryptu::{e[:200]}")
infra_fail = (not bot) or timeout or crashed
if infra_fail:
    print('::error title=QA workflow::bot did not finish (no QA_REPORT, timeout or engine crash) - see career.log')
if os.environ.get('QA_STRICT') == '1' and verdict != 'OK':
    sys.exit(1)
# blockers: the game cannot be played at all (a GDScript that does not compile, or no lock reached) -> red run
blocker = bool(script_errors) or (bot and not bot.get('locks'))
if blocker:
    print('::error title=QA gry: bloker::' + (script_errors[0][:200] if script_errors else 'no lock was reached in the whole career'))
if os.environ.get('QA_FAIL_ON_INFRA') == '1' and (infra_fail or blocker):
    sys.exit(2)
