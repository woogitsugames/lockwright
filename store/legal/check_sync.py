#!/usr/bin/env python3
"""store/legal/privacy_{pl,en}.md must carry the same policy text as store/privacy.md §1 / §2 (the source of truth)."""
import pathlib, re, sys
HERE = pathlib.Path(__file__).resolve().parent
src = (HERE.parent / 'privacy.md').read_text()
def part(a, b):
    s = src[src.index(a):src.index(b)]
    return s.split('\n', 1)[1].strip().strip('-').strip()
want = {'pl': part('## 1. Polityka', '## 2. Privacy'), 'en': part('## 2. Privacy', '## 3.')}
bad = 0
for lang, text in want.items():
    p = HERE / f'privacy_{lang}.md'
    body = p.read_text().split('<!-- BEGIN -->', 1)[1].split('<!-- END -->', 1)[0].strip()
    if re.sub(r'\s+', ' ', body) != re.sub(r'\s+', ' ', text):
        print(f'OUT OF SYNC: {p.name} vs store/privacy.md'); bad += 1
print('OK' if not bad else 'FAIL')
sys.exit(1 if bad else 0)
