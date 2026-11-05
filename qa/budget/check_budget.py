#!/usr/bin/env python3
"""Performance budget check for CI (session C, stage 3, task 9). Budgets: qa/budget/budgets.json, rationale in
docs/handoff/POMIARY.md §8. Measures on a COPY of game/ (game/ is not modified):
  - size of the Android resource pack (godot --export-pack "Android"), optional APK size (--apk FILE),
  - headless startup time (boot scene + 5 frames) and the plan B lock scene, peak RSS of the boot.
   python3 qa/budget/check_budget.py [--godot godot] [--apk path.apk] [--out qa/out/budget]
Exit 1 when any value exceeds its "fail" limit; "warn" is reported (GitHub ::warning) but passes."""
import argparse, json, os, pathlib, shutil, statistics, subprocess, sys, tempfile, time

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent


def run_timed(cmd):
    """Wall time and peak RSS (MB) of this one child process (os.wait4 gives per-process rusage)."""
    t0 = time.monotonic()
    p = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    _, status, ru = os.wait4(p.pid, 0)
    dt = time.monotonic() - t0
    return dt, ru.ru_maxrss / 1024.0, os.waitstatus_to_exitcode(status)


def pack_breakdown(work, depth=3, top=15):
    """Approximate pack contents per source directory: imported artefacts (.godot/imported, via *.import dest_files)
    for imported sources, raw size for everything else. Folders with .gdignore are skipped like Godot does."""
    ignored = [p.parent for p in work.rglob('.gdignore')]
    sizes = {}
    for f in work.rglob('*'):
        if not f.is_file() or '.godot' in f.parts or f.suffix == '.import':
            continue
        if any(ig == f.parent or ig in f.parents for ig in ignored):
            continue
        imp = f.with_name(f.name + '.import')
        n = 0
        if imp.exists():
            for line in imp.read_text(errors='replace').splitlines():
                if line.startswith('dest_files='):
                    for d in line.split('"')[1::2]:
                        q = work / d.replace('res://', '')
                        n += q.stat().st_size if q.exists() else 0
        else:
            n = f.stat().st_size
        key = '/'.join(f.relative_to(work).parent.parts[:depth]) or '.'
        sizes[key] = sizes.get(key, 0) + n
    return sorted(sizes.items(), key=lambda kv: -kv[1])[:top]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--godot', default=os.environ.get('GODOT', 'godot'))
    ap.add_argument('--apk')
    ap.add_argument('--out', default=str(ROOT / 'qa/out/budget'))
    a = ap.parse_args()
    budgets = json.loads((HERE / 'budgets.json').read_text())['ci']
    out = pathlib.Path(a.out); out.mkdir(parents=True, exist_ok=True)
    work = pathlib.Path(tempfile.mkdtemp(prefix='lw_budget_')) / 'game'
    shutil.copytree(ROOT / 'game', work, ignore=shutil.ignore_patterns('.godot', 'build', 'android'))
    g = a.godot
    subprocess.run([g, '--headless', '--path', str(work), '--import'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=600)
    m = {}
    pck = work.parent / 'android.pck'
    subprocess.run([g, '--headless', '--path', str(work), '--export-pack', 'Android', str(pck)],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=600)
    m['pck_android_mb'] = round(pck.stat().st_size / 1e6, 1) if pck.exists() else None
    if a.apk and pathlib.Path(a.apk).exists():
        m['apk_mb'] = round(pathlib.Path(a.apk).stat().st_size / 1e6, 1)
    run_timed([g, '--headless', '--path', str(work), '--quit-after', '5'])  # warm the file cache
    boots = [run_timed([g, '--headless', '--path', str(work), '--quit-after', '5']) for _ in range(5)]
    m['startup_headless_s'] = round(statistics.median(b[0] for b in boots), 2)
    m['startup_rss_mb'] = round(max(b[1] for b in boots), 0)
    locks = [run_timed([g, '--headless', '--path', str(work), 'res://scenes/photoreal/lock_photoreal.tscn', '--quit-after', '5'])
             for _ in range(3)]
    m['lock_scene_headless_s'] = round(statistics.median(b[0] for b in locks), 2)
    rows, worst = [], 0
    for k, v in m.items():
        b = budgets.get(k)
        if v is None or not b:
            rows.append((k, v, '—', 'brak pomiaru')); continue
        st = 'OK'
        if v > b['fail']:
            st, worst = 'PRZEKROCZONY', 2
        elif v > b['warn']:
            st, worst = 'ostrzeżenie', max(worst, 1)
        rows.append((k, v, f"{b['warn']} / {b['fail']}", st))
        if st != 'OK' and os.environ.get('GITHUB_ACTIONS'):
            print(f"::{'error' if st == 'PRZEKROCZONY' else 'warning'}::budget {k} = {v} (warn {b['warn']}, fail {b['fail']})")
    md = ['# Budżety wydajności — CI', '', '| Miara | Wartość | Próg ostrz. / błąd | Stan |', '|---|---|---|---|']
    md += [f'| `{k}` | {v} | {lim} | {st} |' for k, v, lim, st in rows]
    try:
        bd = pack_breakdown(work)
    except Exception as e:  # diagnostics only, never fail the budget on it
        bd, md = [], md + ['', f'(rozbicie paczki niedostępne: {e})']
    if bd:
        md += ['', '## Co zajmuje paczkę (przybliżenie: zasoby po imporcie, wg katalogu źródłowego)', '',
               '| Katalog w `game/` | MB |', '|---|---|']
        md += [f'| `{k}` | {v / 1e6:.1f} |' for k, v in bd]
    md += ['', 'Progi i uzasadnienie: `docs/handoff/POMIARY.md` §8, `qa/budget/budgets.json`.']
    (out / 'budget.md').write_text('\n'.join(md) + '\n')
    (out / 'budget.json').write_text(json.dumps({'measured': m, 'budgets': budgets}, indent=2))
    print('\n'.join(md))
    shutil.rmtree(work.parent, ignore_errors=True)
    sys.exit(1 if worst == 2 else 0)


if __name__ == '__main__':
    main()
