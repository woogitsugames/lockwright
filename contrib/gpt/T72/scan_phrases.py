"""Inventory repeated 3-word phrases across all job dialogue and after-lines."""
import csv
import re
from collections import defaultdict
from pathlib import Path

source = Path('game/i18n/content.csv')
out = Path('contrib/gpt/T72/phrases_all_languages.csv')
with source.open(encoding='utf-8-sig', newline='') as f:
    rows = [r for r in csv.DictReader(f)
            if r['keys'].startswith('job.') and re.search(r'\.(line|after)\.\d+$', r['keys'])]
with out.open('w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['language', 'phrase', 'occurrences', 'keys', 'context_values'])
    for lang in ['en', 'pl', 'de', 'fr', 'es']:
        groups = defaultdict(list)
        for row in rows:
            words = re.findall(r'[^\W\d_]+', row[lang].casefold(), re.UNICODE)
            for gram in set(tuple(words[i:i+3]) for i in range(len(words)-2)):
                groups[' '.join(gram)].append(row)
        for phrase, matches in sorted(groups.items(), key=lambda item: (-len(item[1]), item[0])):
            if len(matches) >= 2:
                writer.writerow([lang, phrase, len(matches), ' | '.join(r['keys'] for r in matches),
                                 ' | '.join(r[lang] for r in matches)])
