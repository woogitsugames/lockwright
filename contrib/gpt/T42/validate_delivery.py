#!/usr/bin/env python3
"""Offline QA for delivered T41 and T42 assets (stdlib only)."""
import csv,json,re,pathlib,sys,collections
P=pathlib.Path(__file__).resolve().parents[3]
T41=P/'contrib/gpt/T41';T42=P/'contrib/gpt/T42'
errors=[];warnings=[]
def read(p):
 with p.open('r',encoding='utf-8-sig',newline='') as f:
  r=csv.DictReader(f);return r.fieldnames,list(r)
header,source=read(P/'docs/handoff/gpt5/T41-input.csv')
h41,t41=read(T41/'lines_fr_es.csv')
assert h41==['keys','fr','es']
errors.extend([] if len(source)==len(t41)==181 else [f'T41 row count {len(t41)}'])
for i,(a,b) in enumerate(zip(source,t41),1):
 if a['keys']!=b['keys']:errors.append(f'Key mismatch {i}')
 limit=int(a['max_len'])
 for lang in ('fr','es'):
  val=b[lang]
  if not val or len(val)>limit:errors.append(f'T41 {i} {lang} length {len(val)} > {limit}')
  if a['kind']=='line':
   if re.search(r'\d|\.\.\.|…|[{}%€]|\b(?:forzar|crocheter|hacking|break-in)\b',val,re.I):errors.append(f'T41 {i} {lang} disallowed syntax')
   if re.search(r'\b(?:m\.|mme\.|mr\.|mrs\.|dr\.|n°|nr\.)',val,re.I):errors.append(f'T41 {i} {lang} abbreviation')
   if lang=='es' and val.count('¿')!=val.count('?'):warnings.append(f'T41 {i} ES question marks {val}')
  if a['kind']=='ui' and re.findall(r'\{[^}]+\}',a['en'])!=re.findall(r'\{[^}]+\}',val):errors.append(f'placeholder {i} {lang}')
if len({r['keys'] for r in t41})!=181:errors.append('T41 duplicate keys')
hs,supp=read(T41/'supplemental_ui_fr_es.csv')
if hs!=h41 or len(supp)!=19 or len({r['keys'] for r in supp})!=19:errors.append('T41 supplemental UI')
h42,t42=read(T42/'family_texts.csv')
if h42!=['keys','en','pl','de'] or len(t42)!=78:errors.append('T42 family header/number')
bykey={r['keys']:r for r in t42}
if len(bykey)!=len(t42):errors.append('T42 duplicate keys')
families=['dial_safe','combo','dimple','disc_detainer','egyptian','axial_slider','time_lock','magnetic']
for fam in families:
 for suffix in ['name','short']:
  if f'family.{fam}.{suffix}' not in bykey:errors.append(f'T42 missing family.{fam}.{suffix}')
 hint={'dial_safe':'lock.dial_hint','combo':'lock.combo_hint','disc_detainer':'lock.disc_hint'}.get(fam,f'lock.{fam}_hint')
 if hint not in bykey:errors.append(f'T42 missing {hint}')
 for n in range(1,6):
  if f'tutorial.{fam}.step{n}' not in bykey:errors.append(f'T42 missing step{n} {fam}')
 if fam!='time_lock':
  for k in (f'tutorial.{fam}.step1_auto',f'lock.{fam}_hint_auto'):
   if k not in bykey:errors.append(f'T42 missing {k}')
for key,row in bykey.items():
 cap=24 if key.endswith('.name') else 70 if key.endswith('.short') else 56
 for lang in ('en','pl','de'):
  value=row[lang]
  if not value or len(value)>cap:errors.append(f'T42 {key} {lang} {len(value)}/{cap}')
  if re.search(r'[{}]|https?://',value):errors.append(f'T42 forbidden syntax {key} {lang}')
 if 'egyptian' in key and re.search(r'\bpin(?:ów|y|em|ami)?\b',row['pl'],re.I):warnings.append(f'PL Egyptian pin maybe {key}')
 if 'time_lock' in key and re.search(r'\botwart[yae]|\botwórz\b',row['pl'],re.I):errors.append(f'Time lock said open: {key}')
hs,show=read(T42/'showcase_texts.csv')
if hs!=h42 or len(show)!=9 or len({r['keys'] for r in show})!=len(show):errors.append('T42 showcase CSV')
for row in show:
 if row['keys'].endswith('.title'):
  for lang in ('en','pl','de'):
   if len(row[lang])>40:errors.append('Too long title '+row['keys']+' '+lang)
 if row['keys'].endswith('.body') and not 300<=len(row['pl'])<=420:errors.append('Body length '+row['keys'])
for slug in ('combo','dimple','magnetic'):
 f=T42/'showcase'/f'showcase.{slug}.json'
 j=json.loads(f.read_text(encoding='utf-8'))
 if not all(j.get(k) for k in ('id','unlocks','source','confidence','i18n')):errors.append('Missing JSON field '+slug)
 for field,key in j['i18n'].items():
  if key not in {r['keys'] for r in show}:errors.append(f'No i18n key for {slug}.{field}')
 if not j['source'].startswith('https://'):errors.append('Invalid source URL '+slug)
less=(T42/'LESSONS.md').read_text(encoding='utf-8')
for fam in families:
 sec=less.split('## `'+fam+'`',1)
 if len(sec)!=2:errors.append('Missing lessons section '+fam);continue
 section=sec[1].split('## ',1)[0]
 for level in ('H1','H2','H3','H4'):
  if level not in section:errors.append('Missing '+level+' in '+fam)
print('T41: 181 items, including 164 audio lines and 17 UI labels; supplemental 19 UI labels')
print('T42: 78 family lines in EN/PL/DE; 8 lessons; 3 showcase objects; 9 showcase strings')
print('Validation errors:',len(errors),'warnings:',len(warnings))
for error in errors:print('ERROR',error)
for warn in warnings:print('WARN ',warn)
sys.exit(1 if errors else 0)