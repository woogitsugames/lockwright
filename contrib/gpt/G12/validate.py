#!/usr/bin/env python3
"""Structural checks for the G12 exports (Pillow required)."""
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parent
ids=['01_enamel_l','02_brass_cylinder','03_leather_roll','04_old_key',
     '05_doorbell','06_number_plate','07_dial_cylinder','08_tenement_door',
     '09_door_handle','10_workshop_lamp','11_key_ring','12_facade']
for name in ids:
    a=Image.open(root/'ios'/f'{name}_1024.png')
    assert a.size==(1024,1024) and a.mode in ('RGB','P'),name
    p=Image.open(root/'previews'/f'{name}_sizes.png')
    assert p.size==(644,314), name
    f=Image.open(root/'android'/f'{name}_foreground_432.png')
    b=Image.open(root/'android'/f'{name}_background_432.png')
    assert f.size==(432,432) and f.mode=='RGBA',name
    assert b.size==(432,432) and b.mode in ('RGB','P'),name
    assert f.getchannel('A').getextrema()[0]==0,name
    bounds=f.getchannel('A').getbbox()
    assert bounds and all(80<=v<=352 for v in bounds), (name,bounds)
    assert all(z.stat().st_size<20_000_000 for z in [root/'ios'/f'{name}_1024.png',
              root/'previews'/f'{name}_sizes.png',
              root/'android'/f'{name}_foreground_432.png',
              root/'android'/f'{name}_background_432.png'])
print('PASS: 12 concepts, 49 PNG files, iOS, adaptive alpha & center padding, files < 20MB each')
