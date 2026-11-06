"""Convert the existing T73 delivery into the requested six-column format."""
import csv
import io
import subprocess
from pathlib import Path

raw = subprocess.check_output(['git', 'show', 'HEAD:contrib/gpt/T73/verification_variants.csv'])
rows = csv.DictReader(io.StringIO(raw.decode('utf-8-sig'), newline=''))
target = Path('contrib/gpt/T73/verification_i18n.csv')
with target.open('w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['keys', 'en', 'pl', 'de', 'fr', 'es'])
    for row in rows:
        card = row['card_key'].removeprefix('verify.card.')
        variant = row['variant']
        for part in ('question', 'answer'):
            en = row[f'{part}_en'].replace('neighbours', 'neighbors').replace('neighbour', 'neighbor')
            writer.writerow([f'verify.extra.{card}.v{variant}.{part}', en,
                             row[f'{part}_pl'], row[f'{part}_de'], '', ''])
