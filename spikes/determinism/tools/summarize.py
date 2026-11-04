#!/usr/bin/env python3
"""Builds the results table (Markdown) from results/*.txt written by run_platform.sh.
   python3 tools/summarize.py results [--reference x86_64-gcc] > table.md
Exit 1 when any hash differs from the reference platform."""
import sys, pathlib

def load(p):
    d = {}
    for line in p.read_text().splitlines():
        if '=' in line:
            k, v = line.split('=', 1); d[k] = v
    return d

args = sys.argv[1:]
root = pathlib.Path(args[0] if args else 'results')
ref_name = args[args.index('--reference') + 1] if '--reference' in args else 'x86_64-gcc'
runs = {p.stem: load(p) for p in sorted(root.glob('*.txt')) if not p.stem.count('.')}
if ref_name not in runs:
    ref_name = sorted(runs)[0]
ref = runs[ref_name]
keys = [k for k in ref if k.startswith('golden.')] + ['verify_seeds_csv_sha256']
order = [ref_name] + [n for n in runs if n != ref_name]
ok = True
print('| Build | Platform / compiler | ctest | ' + ' | '.join(k.replace('golden.', '') for k in keys) + ' | replay_fuzz 10 000 |')
print('|' + '---|' * (4 + len(keys)))
for n in order:
    r = runs[n]
    cells = []
    for k in keys:
        v = r.get(k, '–')
        same = v == ref.get(k)
        ok &= same
        cells.append(f'`{v}`' + ('' if same else ' **≠**'))
    fuzz = r.get('fuzz_summary', '')
    match = fuzz.split(':', 1)[-1].split(';')[0].strip() if 'checked' in fuzz else r.get('fuzz', '–')
    ok &= r.get('fuzz') == 'pass' and r.get('ctest') == 'pass'
    print(f"| {n} | {r.get('platform', '?').split(' (')[0]} | {r.get('ctest', '?')} | " + ' | '.join(cells) + f" | {match} |")
print()
print('step() cost (native builds only are meaningful; qemu adds 10-50x):')
print()
for n in order:
    for k, v in runs[n].items():
        if k.startswith('bench.'):
            print(f'- {n} {k[6:]}: {v}')
print()
print('RESULT:', 'all hashes identical to ' + ref_name if ok else 'MISMATCH (see above)')
sys.exit(0 if ok else 1)
