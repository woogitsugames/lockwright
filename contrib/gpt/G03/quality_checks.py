#!/usr/bin/env python3
"""Validate 12 PBR maps and two photo references in a complete G03 pack."""
import json
from pathlib import Path
import numpy as np
from PIL import Image

HERE=Path(__file__).resolve().parent
MATS=HERE/'materials'
NAMES=['oak_satin','oak_bottle_green','pine_cream','walnut_dark']
TYPES=['albedo','height','roughness']
results={"materials":{},"references":[],"previews":[],"all_pass":True}
for name in NAMES:
    results['materials'][name]={}
    for typ in TYPES:
        file=MATS/f'{name}_{typ}_2048.png'
        with Image.open(file) as im:
            a=np.array(im)
            edge_lr=float(np.max(np.abs(a[:,0].astype(np.float64)-a[:,-1].astype(np.float64))))
            edge_tb=float(np.max(np.abs(a[0].astype(np.float64)-a[-1].astype(np.float64))))
            nbytes=file.stat().st_size
            success=(im.size==(2048,2048) and edge_lr==0 and edge_tb==0 and nbytes<20_000_000
                and (a.dtype==np.uint16 if typ=='height' else a.dtype==np.uint8) and a.std()>3)
            results['materials'][name][typ]={
                'path':str(file.relative_to(HERE)),
                'size':list(im.size),'dtype':str(a.dtype),'bytes':nbytes,
                'seam_lr_max':edge_lr,'seam_tb_max':edge_tb,
                'stddev':round(float(a.std()),2),'ok':bool(success)}
            results['all_pass'] &= bool(success)
for f in sorted((HERE/'references').glob('*.jpg')):
    with Image.open(f) as im:
        results['references'].append({'path':str(f.relative_to(HERE)),'size':list(im.size),'bytes':f.stat().st_size})
for f in sorted((HERE/'previews').glob('*.jpg')):
    with Image.open(f) as im:
        results['previews'].append({'path':str(f.relative_to(HERE)),'size':list(im.size),'bytes':f.stat().st_size})
results['all_pass'] &= len(results['references'])==2 and len(results['previews'])==2
(HERE/'QA.json').write_text(json.dumps(results,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('PASS' if results['all_pass'] else 'FAIL',len(NAMES)*len(TYPES),'maps;',len(results['references']),'references;',len(results['previews']),'previews')
for k,files in results['materials'].items():
    print(k,[(ch,v['ok'],v['bytes']) for ch,v in files.items()])
if not results['all_pass']: raise SystemExit(1)
