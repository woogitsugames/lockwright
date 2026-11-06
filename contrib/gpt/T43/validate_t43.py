#!/usr/bin/env python3
"""Validate the delivered narrative data. Usage: python3 validate_t43.py [repo_root]."""
import csv
import json
import re
import sys
from collections import Counter
from pathlib import Path

HERE = Path(__file__).resolve().parent
LIMITS = {'pin_tumbler': (2, 6), 'warded': (1, 2), 'wafer': (1, 3),
          'lever': (3, 5), 'lever_detector': (5, 6), 'dial_safe': (1, 3),
          'combo': (1, 4), 'dimple': (1, 3), 'disc_detainer': (1, 3),
          'egyptian': (1, 2), 'axial_slider': (1, 3), 'time_lock': (1, 2),
          'magnetic': (1, 2)}
NEW_FAMILIES = {'dial_safe', 'combo', 'dimple', 'disc_detainer', 'egyptian',
                'axial_slider', 'time_lock', 'magnetic'}
ALLOWED_CARDS = {'address_app', 'deed', 'id', 'inheritance', 'institution',
                 'invoice', 'lease', 'letter', 'manager', 'photo', 'receipt',
                 'resolution', 'witness'}
errors = []


def require(ok, message):
    if not ok:
        errors.append(message)


def main():
    with (HERE / 'content_t43.csv').open(encoding='utf-8', newline='') as f:
        reader = csv.DictReader(f)
        require(reader.fieldnames == ['keys', 'en', 'pl', 'de'], 'CSV header')
        rows = list(reader)
    require(len(rows) == len({r['keys'] for r in rows}), 'Duplicate CSV keys')
    by_key = {r['keys']: r for r in rows}
    for r in rows:
        require(None not in r, 'Malformed row: ' + r['keys'])
        for lang in ['pl', 'en']:
            value = r[lang]
            require(bool(value.strip()), 'Empty ' + lang + ': ' + r['keys'])
            limit = 90 if re.search(r'\.(line|after)\.\d+$', r['keys']) else 130 if r['keys'].endswith('.note') else None
            if limit:
                require(len(value) <= limit, 'Length ' + lang + ': ' + r['keys'])
            if '.line.' in r['keys'] or '.after.' in r['keys']:
                require(not re.search(r'\d', value), 'Spoken digits: ' + r['keys'])
                require('!' not in value, 'Exclamation mark: ' + r['keys'])
        require(set(re.findall(r'\{[^{}]+\}', r['en'])) == set(re.findall(r'\{[^{}]+\}', r['pl'])), 'Placeholder mismatch: ' + r['keys'])
    jobs = [json.loads(p.read_text(encoding='utf-8')) for p in sorted((HERE / 'jobs').glob('*.json'))]
    flow = json.loads((HERE / 'flow_t43.json').read_text(encoding='utf-8'))
    by_flow = {x['id']: x for x in flow}
    require(len(jobs) == 30 and len(by_flow) == 30, 'Thirty unique jobs and flow entries required')
    require(Counter(j['chapter'] for j in jobs) == {9: 8, 10: 7, 11: 7, 12: 8}, 'Chapter counts')
    require(len({j['id'] for j in jobs}) == len(jobs), 'Duplicate job ids')
    covered = Counter()
    speakers = set()
    for j in jobs:
        jid = j['id']
        f = by_flow[jid]
        lo, hi = LIMITS[j['family']]
        require(lo <= j['tier'] <= hi, 'Unsupported tier: ' + jid)
        require(j['place'] in {'apartment', 'gate', 'kiosk', 'locker', 'workshop'}, 'Place: ' + jid)
        require(j['time'] in {'day', 'evening', 'night', 'rainy'}, 'Time: ' + jid)
        require(set(j['cards']) <= ALLOWED_CARDS, 'Unknown card: ' + jid)
        require(j['threshold'] in {2, 3}, 'Threshold: ' + jid)
        require(4 <= len(j['lines']) <= 6 and 1 <= len(j['after']) <= 2, 'Dialogue counts: ' + jid)
        require('locksmith' in j['lines'], 'No locksmith line: ' + jid)
        for field in ['title', 'client', 'situation', 'note']:
            require(jid + '.' + field in by_key, 'Missing field: ' + jid + '.' + field)
        for typ, ids in [('line', j['lines']), ('after', j['after'])]:
            for i, speaker in enumerate(ids, 1):
                require(f'{jid}.{typ}.{i}' in by_key, 'Missing dialogue: ' + jid)
                speakers.add(speaker)
        require(f['grant_coins'] == j['reward_coins'], 'Flow reward mismatch: ' + jid)
        if f['kind'] == 'refusal':
            require(jid.startswith('job.refuse') and j['reward_coins'] == 0 and f['reputation'] == 5, 'Refusal contract: ' + jid)
        else:
            require(40 <= j['reward_coins'] <= 200, 'Reward range: ' + jid)
            if f['kind'] in {'open', 'clock_repair'}:
                covered[j['family']] += 1
    for c in [9, 10, 11, 12]:
        chapter = [f for f in flow if f['id'] in {j['id'] for j in jobs if j['chapter'] == c}]
        require(1 <= sum(f['kind'] == 'refusal' for f in chapter) <= 2, 'Refusals in chapter ' + str(c))
        require(sum(f['kind'] in {'no_open', 'clock_repair'} for f in chapter) == 1, 'Non-opening scene in chapter ' + str(c))
    for family in NEW_FAMILIES:
        require(covered[family] >= 2, 'New family needs two playable jobs: ' + family)
    repo = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if repo:
        old = list(csv.DictReader((repo / 'game/i18n/content.csv').open(encoding='utf-8', newline='')))
        baseline = {r['keys'] for r in old}
        all_base_keys = baseline | {r['keys'] for r in csv.DictReader((repo / 'game/i18n/strings.csv').open(encoding='utf-8', newline=''))}
        require(not baseline.intersection(by_key), 'Keys conflict with baseline content.csv')
        old_ids = {json.loads(p.read_text())['id'] for p in (repo / 'game/data/jobs').glob('*.json')}
        require(not old_ids.intersection(j['id'] for j in jobs), 'Job ids conflict with baseline')
        for speaker in speakers:
            require('cast.' + speaker + '.name' in baseline | set(by_key), 'Missing speaker name: ' + speaker)
        for j in jobs:
            for card in j['cards']:
                require('verify.card.' + card in all_base_keys, 'Missing card label: ' + card)
    result = dict(jobs=len(jobs), keys=len(rows), languages=['pl', 'en'], optional_de_missing=sum(not r['de'] for r in rows),
                  chapters=dict(Counter(j['chapter'] for j in jobs)), family_coverage=dict(sorted(covered.items())),
                  reward_coins=sum(j['reward_coins'] for j in jobs), speakers=sorted(speakers),
                  errors=errors, status='PASS' if not errors else 'FAIL')
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
