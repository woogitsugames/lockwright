#!/usr/bin/env python3
"""Create the two original, wordless pencil/chalk control-choice illustrations."""
from __future__ import annotations
import hashlib
import io
import math
from pathlib import Path

import cairosvg
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = Path(__file__).resolve().parent
SIZE = 768
SEED = 190052
STYLE_PROMPT = (
    'Hand-drawn pencil and chalk educational thumbnail for Lockwright: a fictitious, '
    'brandless upright smartphone, a simplified deliberately non-realistic cutaway '
    'mechanism at the top of the display, and clear thumb touch gestures. '
    'Quiet graphite contour with muted off-white chalk ghost lines, paper notebook '
    'sensibility consistent with the master Henryk notes; restrained drawing, no '
    'text, no logo, no recognizable hardware model, no realistic lock instructions. '
    'Matching crop and scale for both controls. The smartphone is in the same place.'
)

BASE = '''
<!-- simplified, imaginary horizontal lock cutaway; not a real lock mechanism -->
<g class="pencil" stroke-width="4.6" fill="none" stroke-linejoin="round" stroke-linecap="round">
  <path d="M255 264 Q258 249 270 250 H502 Q511 254 511 266 V364 Q510 379 499 379 H267 Q253 374 255 359 Z" />
  <path d="M265 310 H501" stroke-width="3.5"/>
  <path d="M267 344 H499" stroke-width="6"/>
  <path d="M276 285 H491" stroke-width="2.7" opacity=".65"/>
  <path d="M269 367 H501" stroke-width="2.3" opacity=".64"/>
  <path d="M295 258 V246 M472 257 V246" opacity=".5" stroke-width="2.3"/>
  <path d="M303 281 V308 M351 281 V308 M400 281 V308 M449 281 V308" opacity=".7" stroke-width="3"/>
  <path d="M303 319 V347 M351 319 V347 M400 319 V347 M449 319 V347" opacity=".7" stroke-width="3"/>
  <path d="M289 379 V405 H324" stroke-width="8"/>
  <path d="M289 380 V399 H316" stroke="white" stroke-width="2" opacity=".9"/>
</g>
<g fill="#655e50" fill-opacity=".12" stroke="#4a463c" stroke-width="3" stroke-linejoin="round">
  <rect x="288" y="302" width="29" height="32" rx="6"/>
  <rect x="336" y="295" width="29" height="39" rx="6"/>
  <rect x="385" y="304" width="29" height="30" rx="6"/>
  <rect x="434" y="299" width="29" height="35" rx="6"/>
</g>
<g class="pencil" stroke-width="2" opacity=".42">
  <path d="M272 293 l16 -8 M275 299 l22 -9 M462 354 l18 -8 M463 360 l27 -11"/>
  <path d="M329 266 l9 -7 M385 269 l10 -7 M430 267 l12 -8"/>
</g>
<!-- common phone outline and frame -->
<g class="pencil" fill="none" stroke-linejoin="round" stroke-linecap="round">
  <rect x="198" y="73" width="370" height="628" rx="52" stroke-width="7"/>
  <rect x="203" y="79" width="362" height="617" rx="49" stroke-width="1.8" opacity=".36"/>
  <rect x="218" y="111" width="330" height="535" rx="24" stroke-width="3.8"/>
  <path d="M343 94 H423" stroke-width="4" opacity=".62"/>
  <path d="M368 674 H405" stroke-width="3" opacity=".44"/>
  <path d="M208 162 V208 M556 495 V547" stroke-width="1.6" opacity=".45"/>
</g>
<g class="pencil" opacity=".29" stroke-width="2.1" fill="none">
  <path d="M228 129 L232 164 M231 570 L237 613 M535 128 L531 178"/>
  <path d="M234 191 L238 205 M529 573 L532 609"/>
</g>
'''
# All geometry refers to the same upright phone; touch marks and gestures are layered later.
RIGHT_HAND = '''
<g fill="#ebe3d2" fill-opacity=".86" stroke="#514b42" stroke-width="5.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M720 739 Q706 706 682 677 Q656 652 625 649 L561 635 Q537 626 527 605 
           Q517 587 514 566 L498 511 Q491 492 478 490 Q461 491 455 503 Q450 514 459 535
           L475 581 Q461 572 445 572 Q425 573 429 591 Q432 609 455 617
           Q445 610 436 612 Q422 615 427 629 Q429 644 453 651
           Q443 644 440 652 Q435 664 455 678 L510 712 L544 739 Z"/>
</g>
<g class="pencil" stroke-width="2.6" opacity=".76" fill="none" stroke-linecap="round">
  <path d="M481 503 Q476 497 468 505 M468 546 Q475 566 475 580"/>
  <path d="M455 617 L486 626 M454 652 L486 663 M504 583 Q515 632 556 651"/>
  <path d="M549 687 Q596 687 629 714" opacity=".45"/>
</g>
'''
LEFT_HAND = '''
<g fill="#ebe3d2" fill-opacity=".86" stroke="#514b42" stroke-width="5.2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M48 739 Q62 706 86 677 Q112 652 143 649 L207 635 Q231 626 241 605
           Q251 587 254 566 L270 511 Q277 492 290 490 Q307 491 313 503 Q318 514 309 535
           L293 581 Q307 572 323 572 Q343 573 339 591 Q336 609 313 617
           Q323 610 332 612 Q346 615 341 629 Q339 644 315 651
           Q325 644 328 652 Q333 664 313 678 L258 712 L224 739 Z"/>
</g>
<g class="pencil" stroke-width="2.6" opacity=".76" fill="none" stroke-linecap="round">
  <path d="M287 503 Q292 497 300 505 M300 546 Q293 566 293 580"/>
  <path d="M313 617 L282 626 M314 652 L282 663 M264 583 Q253 632 212 651"/>
  <path d="M219 687 Q172 687 139 714" opacity=".45"/>
</g>
'''

AUTO = '''
<!-- held-tension anchor mark, chalk, near the tensioner: a notched loop + latch -->
<g stroke="#9b927f" fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path d="M288 415 V430 Q273 439 277 451 Q286 470 305 457 L305 432" stroke-width="7"/>
  <path d="M281 449 H307 M292 410 V420" stroke-width="3.5" opacity=".76"/>
  <path d="M310 424 L318 417" stroke-width="4"/>
</g>
<g stroke="#fdfaf2" fill="none" stroke-width="2.3" opacity=".88" stroke-linecap="round">
  <path d="M292 416 V430 Q279 443 286 455 M290 451 H301"/>
</g>
<!-- intuitive right-thumb lift -->
<g stroke="#3a3935" fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path d="M475 484 L475 433" stroke-width="9"/>
  <path d="M454 452 L475 426 L496 452" stroke-width="9"/>
  <path d="M467 481 L466 456" stroke-width="2" opacity=".33"/>
</g>
<g stroke="#fff9ed" fill="none" stroke-width="2.1" opacity=".91" stroke-linecap="round">
  <path d="M477 480 V438 M459 450 L475 430 L490 447"/>
</g>
'''
TWO = '''
<!-- left: tension -->
<g stroke="#3a3935" fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path d="M294 484 L294 433" stroke-width="9"/>
  <path d="M273 452 L294 426 L315 452" stroke-width="9"/>
</g>
<!-- right: lifting and lateral double motion -->
<g stroke="#3a3935" fill="none" stroke-linecap="round" stroke-linejoin="round">
  <path d="M475 484 L475 433" stroke-width="9"/>
  <path d="M454 452 L475 426 L496 452" stroke-width="9"/>
  <path d="M430 548 H526" stroke-width="7"/>
  <path d="M447 535 L429 548 L447 562" stroke-width="6.5"/>
  <path d="M509 535 L527 548 L509 562" stroke-width="6.5"/>
</g>
<g stroke="#fff9ed" fill="none" stroke-width="2.1" opacity=".92" stroke-linecap="round">
  <path d="M296 482 V437 M278 450 L293 431 L309 450"/>
  <path d="M477 482 V437 M459 450 L474 431 L490 450"/>
  <path d="M440 546 H518"/>
</g>
'''

SVG_START = '''<svg xmlns="http://www.w3.org/2000/svg" width="768" height="768" viewBox="0 0 768 768">
<defs><style>.pencil{stroke:#4e483e;stroke-linecap:round;stroke-linejoin:round}</style></defs>
'''


def source_svg(mode: str) -> str:
    # Phone and lock are placed below the hands, so hands visibly rest on its screen.
    # Stroke marks are painted on top to remain readable at 96px size.
    hands = RIGHT_HAND if mode == 'auto' else LEFT_HAND + RIGHT_HAND
    gestures = AUTO if mode == 'auto' else TWO
    return SVG_START + BASE + hands + gestures + '\n</svg>\n'


def textured_paper() -> Image.Image:
    rng = np.random.default_rng(SEED)
    h = w = SIZE
    yy, xx = np.mgrid[0:h, 0:w]
    grain = rng.normal(0, 1.9, (h, w))
    light = (0.004 * (xx - 330) + 0.002 * (yy - 290))
    low = np.sin(xx * .042 + yy*.019) * .7
    base = np.stack([
        242 - light + low + grain,
        235 - light + low + grain,
        218 - light + low + grain,
    ], axis=-1)
    paper = Image.fromarray(np.uint8(np.clip(base, 0, 255)), 'RGB')
    overlay = Image.new('RGBA', (w, h))
    d = ImageDraw.Draw(overlay, 'RGBA')
    for i in range(135):
        x = int(rng.integers(0, w)); y = int(rng.integers(0, h))
        length = int(rng.integers(2, 18))
        d.line((x,y,x+length,y+int(rng.integers(-2,3))), fill=(101,95,79,int(rng.integers(3,14))),width=1)
    return Image.alpha_composite(paper.convert('RGBA'), overlay)


def rough_graphite(alpha: Image.Image, salt: int) -> Image.Image:
    """Add very fine per-pixel texture only to inked strokes, never outside drawing."""
    rng = np.random.default_rng(SEED + salt)
    rgba = np.asarray(alpha.convert('RGBA')).copy()
    # Tiny discontinuities emulate graphite tooth without compromising icon legibility.
    a = rgba[:,:,3].astype(np.float32)
    perturb = rng.normal(0, 0.025, a.shape)
    a *= np.clip(0.96 + perturb, .84, 1.)
    rgba[:,:,3] = np.uint8(np.clip(a + 0.5,0,255))
    return Image.fromarray(rgba, 'RGBA')


def make_contact(images: dict[str, Image.Image]) -> Image.Image:
    out = Image.new('RGB', (1652, 1040), '#e8e2d4')
    d = ImageDraw.Draw(out)
    font_path = next((p for p in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf'] if Path(p).exists()), None)
    font = ImageFont.truetype(font_path, 25) if font_path else ImageFont.load_default()
    for ix, name in enumerate(['auto', 'two_thumbs']):
        for row, variant in enumerate(['paper','alpha']):
            x = 50 + ix*800
            y = 72 + row*490
            if variant == 'alpha':
                tile = 20
                for v in range(0,434,tile):
                    for u in range(0,434,tile):
                        c = '#eeeae3' if (u//tile+v//tile)%2 else '#c7c5c0'
                        d.rectangle((x+u,y+v,x+u+tile,y+v+tile), fill=c)
            else:
                d.rectangle((x,y,x+432,y+432),fill='#f2ebda')
            small=images[name+'_'+variant].resize((432,432),Image.Resampling.LANCZOS)
            out.paste(small,(x,y),small if variant=='alpha' else None)
            d.rectangle((x,y,x+432,y+432),outline='#797264',width=2)
            label = {'auto_paper':'AUTO / papier', 'auto_alpha':'AUTO / alfa','two_thumbs_paper':'TWO THUMBS / papier','two_thumbs_alpha':'TWO THUMBS / alfa'}[name+'_'+variant]
            d.text((x,y-42),label,font=font,fill='#3f3b35')
    return out


def main():
    images = {}
    paper = textured_paper()
    for name in ['auto','two_thumbs']:
        svg = source_svg(name)
        (OUT/(name+'.svg')).write_text(svg,encoding='utf-8')
        raster = cairosvg.svg2png(bytestring=svg.encode(),output_width=1536,output_height=1536)
        layer = Image.open(io.BytesIO(raster)).convert('RGBA').resize((SIZE,SIZE),Image.Resampling.LANCZOS)
        layer = rough_graphite(layer, 0 if name=='auto' else 1)
        image = Image.alpha_composite(paper.copy(),layer).convert('RGB')
        stem='controls_'+name
        image.save(OUT/(stem+'.png'),optimize=True)
        layer.save(OUT/(stem+'_alpha.png'),optimize=True)
        images[name+'_paper']=image
        images[name+'_alpha']=layer
        image.resize((192,192),Image.Resampling.LANCZOS).save(OUT/('preview_'+name+'_192.png'))
        image.resize((96,96),Image.Resampling.LANCZOS).save(OUT/('preview_'+name+'_96.png'))
    make_contact(images).save(OUT/'contact-sheet.jpg',quality=90,optimize=True,subsampling=0)
    print('G19 created:',[(p.name,p.stat().st_size) for p in sorted(OUT.glob('*.png'))])

if __name__=='__main__':
    main()
