#!/usr/bin/env python3
"""Validation for the G03-v2 texture pack, cross-edge continuity and outputs."""
from pathlib import Path
import numpy as np
from PIL import Image
import json, sys
ROOT=Path(__file__).resolve().parents[1]
keys=('oak_satin','oak_bottle_green','pine_cream','walnut_dark')
recs=[];errors=[]
for k in keys:
 item={'material':k,'maps':{}}
 for t in ('albedo','height','roughness'):
  p=ROOT/'materials'/f'{k}_{t}_2048.png'
  if not p.exists():errors.append('MISSING '+str(p));continue
  img=Image.open(p)
  arr=np.asarray(img).astype(np.int32)
  if img.size!=(2048,2048):errors.append('SIZE '+str(p))
  if t=='albedo' and arr.ndim!=3:errors.append('ALBEDO CHANNELS '+str(p))
  if t!='albedo' and arr.ndim!=2:errors.append('GRAY CHANNELS '+str(p))
  if t=='height' and np.asarray(img).dtype!=np.uint16:errors.append('HEIGHT BITDEPTH '+str(p))
  if p.stat().st_size>20*1024*1024:errors.append('OVER 20 MiB '+str(p))
  dx=np.abs(arr[:,0]-arr[:,-1]);dy=np.abs(arr[0]-arr[-1]);
  if max(dx.max(),dy.max())>1:errors.append('EDGE DISCONTINUITY '+str(p))
  item['maps'][t]={'dimensions':img.size,'mode':img.mode,'bytes':p.stat().st_size,'max_x_delta':int(dx.max()),'max_y_delta':int(dy.max())}
 for p in (ROOT/'previews'/f'{k}_albedo_2x2.jpg',):
  if not p.is_file():errors.append('MISSING '+str(p))
 recs.append(item)
for p in [ROOT/'references'/'reference_oak_brass_escutcheon_A.jpg',ROOT/'references'/'reference_oak_brass_escutcheon_B.jpg',ROOT/'previews'/'pbr_overview.jpg',ROOT/'previews'/'materials_overview_2x2.jpg']:
 if not p.is_file():errors.append('MISSING '+str(p))
print(json.dumps({'pass':not errors,'errors':errors,'materials':recs},ensure_ascii=False,indent=2))
sys.exit(bool(errors))
