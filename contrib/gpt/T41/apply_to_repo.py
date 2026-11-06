#!/usr/bin/env python3
"""Integrate T41 FR/ES into T31/T32 v2 bundles without destroying other translations.

Run from a checkout of woogitsugames/lockwright:
    python contrib/gpt/T41/apply_to_repo.py
    python contrib/gpt/validate_v2_localizations.py --json

The program only edits the four FR/ES CSVs and does not touch core game files.
"""
from __future__ import annotations
import argparse
import csv
import io
import pathlib
import re
import sys

BASE=pathlib.Path(__file__).resolve().parent
FILES={'fr':'T31','es':'T32'}
PARTS={'line':'content','ui':'strings'}
PLACEHOLDER=re.compile(r'\{[A-Za-z_0-9]+\}')

def load(path):
    with path.open('r',encoding='utf-8-sig',newline='') as f:
        reader=csv.DictReader(f)
        return reader.fieldnames or [], list(reader)

def write_csv(path,header,rows):
    tmp=path.with_suffix(path.suffix+'.tmp')
    with tmp.open('w',encoding='utf-8',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=header,lineterminator='\n')
        writer.writeheader();writer.writerows(rows)
    tmp.replace(path)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--root',type=pathlib.Path,default=BASE.parents[2],help='repository root')
    ap.add_argument('--dry-run',action='store_true')
    args=ap.parse_args()
    root=args.root.resolve()
    source_files={}
    for part in ('content','strings'):
        s=root/'game'/'i18n'/(part+'.csv')
        h,rows=load(s)
        if h[:2]!=['keys','en']:raise ValueError(f'Unexpected header in {s}: {h}')
        source_files[part]={r['keys']:r for r in rows}
    combined={}
    for filename in ('lines_fr_es.csv','supplemental_ui_fr_es.csv'):
        hdr,rows=load(BASE/filename)
        if hdr!=['keys','fr','es']:raise ValueError(f'Unexpected header: {filename}: {hdr}')
        for row in rows:
            key=row['keys']
            if key in combined:raise ValueError(f'Duplicate T41 key {key}')
            part='content' if '.line.' in key else 'strings'
            if key not in source_files[part]:raise ValueError(f'T41 key missing from {part}: {key}')
            for lang in ('fr','es'):
                if not row[lang].strip():raise ValueError(f'Blank {lang} for {key}')
                before=PLACEHOLDER.findall(source_files[part][key]['en'])
                after=PLACEHOLDER.findall(row[lang])
                if sorted(before)!=sorted(after):raise ValueError(f'Placeholder mismatch for {lang}:{key}')
                if part=='content' and len(row[lang])>90:raise ValueError(f'Dialog too long {lang}:{key}')
            combined[key]=(part,row)
    expected_lines=sum('.line.' in key for key in combined)
    if len(combined)!=200 or expected_lines!=164:
        raise ValueError(f'Expected 181 T41 + 19 supplemental: got {len(combined)} / {expected_lines} dialogues')
    for lang,task in FILES.items():
        for part in ('strings','content'):
            target=root/'contrib'/'gpt'/task/(f'{part}_{lang}_v2.csv')
            header,rows=load(target)
            expected_header=['key',f'{lang}_old',f'{lang}_new','note']
            if header!=expected_header:raise ValueError(f'Unexpected target header {target}: {header}')
            current={r['key']:r for r in rows}
            if len(current)!=len(rows):raise ValueError(f'Duplicate target keys in {target}')
            edited=created=0
            for key,(p,entry) in combined.items():
                if p!=part:continue
                new=entry[lang]
                if key not in current:
                    current[key]={'key':key,f'{lang}_old':'',f'{lang}_new':new,
                                  'note':'T41: nowa etykieta UI i wersja językowa'}
                    created+=1
                elif current[key][f'{lang}_new']!=new:
                    record=current[key];record[f'{lang}_new']=new
                    reason=('T41: dialog dla lektora; forma grzecznościowa i liczby słownie' if part=='content'
                            else 'T41: czytelna podpowiedź UI')
                    note=record.get('note','').strip()
                    if reason not in note:record['note']=(note+'; '+reason).lstrip('; ')
                    edited+=1
            missing=set(source_files[part])-set(current)
            extra=set(current)-set(source_files[part])
            if missing or extra:raise ValueError(f'{target}: missing {sorted(missing)}, extra {sorted(extra)}')
            ordered=[current[k] for k in source_files[part]]
            if not args.dry_run:write_csv(target,header,ordered)
            print(f'{lang} {part}: {len(ordered)} keys; changed {edited}; added {created}; missing 0; extra 0')
    print('T41 completed' if not args.dry_run else 'T41 dry run completed')

if __name__=='__main__':
    try:main()
    except (OSError,ValueError) as e:
        print(f'T41 integration failed: {e}',file=sys.stderr);sys.exit(1)