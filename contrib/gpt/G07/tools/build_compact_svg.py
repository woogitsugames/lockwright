#!/usr/bin/env python3
"""Self-contained SVG gallery frames using a shared embedded AI-generated contact sheet."""
from __future__ import annotations
from pathlib import Path
from PIL import Image
import base64, html

BASE=Path(__file__).resolve().parents[1]
source=Image.open(BASE/'source'/'concept_sheet_original.png').convert('RGB').crop((0,0,1199,1058))
source.resize((720,636),Image.Resampling.LANCZOS).save(BASE/'source'/'concept_sheet_compact.webp',format='WEBP',quality=7,method=6)
data=base64.b64encode((BASE/'source'/'concept_sheet_compact.webp').read_bytes()).decode('ascii')
rects=[
('01_apartment_day',(1,1,259,538)),
('02_apartment_evening',(262,1,490,538)),
('03_apartment_night_timer',(494,1,712,538)),
('04_apartment_rainy_evening',(715,1,966,538)),
('05_attic',(970,1,1198,538)),
('06_cellar',(1,545,248,1058)),
('07_kiosk_shutter',(252,545,487,1058)),
('08_changing_room_locker',(491,545,712,1058)),
('09_courtyard_gate',(715,545,965,1058)),
('10_workshop_door',(970,545,1198,1058)),
]
for name,(l,t,r,b) in rects:
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="2340" viewBox="{l} {t} {r-l} {b-t}" preserveAspectRatio="none">
<image x="0" y="0" width="1199" height="1058" preserveAspectRatio="none" href="data:image/webp;base64,{data}"/>
</svg>'''
    (BASE/'images'/f'{name}.svg').write_text(svg,encoding='utf-8')

labels=['Dzien / Day','Wieczor / Evening','Noc / Night','Deszcz / Rain','Strych / Attic','Piwnica / Cellar','Kiosk / Kiosk','Szatnia / Changing room','Brama / Gate','Warsztat / Workshop']
# Single source in one image element (contact sheet), captions below artwork in two rows of text.
text=''.join(f'<text x="{30+(i%5)*235}" y="{1130+(i//5)*35}" font-size="20" fill="#34312c">{i+1:02d} {html.escape(n)}</text>' for i,n in enumerate(labels))
preview=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1199" height="1260" viewBox="0 0 1199 1260">
<rect x="0" y="0" width="1199" height="1260" fill="#f2eee7"/>
<image x="0" y="0" width="1199" height="1058" href="data:image/webp;base64,{data}"/>
<text x="30" y="1090" font-family="sans-serif" font-size="27" fill="#26231e">Lockwright — G07 | Przyjazd do klienta / Arrival at the door</text>
{text}
</svg>'''
(BASE/'preview.svg').write_text(preview,encoding='utf-8')
print('SVG frames',len(rects),'embedded source size', (BASE/'source'/'concept_sheet_compact.webp').stat().st_size,'bytes', 'payload b64 chars',len(data))
