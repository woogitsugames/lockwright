#!/usr/bin/env python3
# Lockwright — review board of the D-58 arrival composites with real figures (G23):
#   python3 art/tools/arrival_board.py [--out art/renders/arrival/wrong_floor_with_figures_board.jpg]
# Top row: the four composites at half size; bottom row: the figure at full resolution (scale, edges, contact shadow).
import argparse
from PIL import Image, ImageDraw

A = 'art/renders/arrival/'
SHOTS = [('wrong_floor_night_kazimierz', (60, 560, 600, 1700)), ('wrong_floor_night_teresa', (600, 560, 1000, 1400)),
         ('wrong_floor_evening_kazimierz', (60, 560, 600, 1700)), ('wrong_floor_day_kazimierz', (60, 560, 600, 1700))]


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--out', default=A + 'wrong_floor_with_figures_board.jpg')
    ap.add_argument('--note', default='G23 cut-outs (rembg BiRefNet + pymatting), arrival_composite.py')
    o = ap.parse_args(); W, H = 540, 960
    sh = Image.new('RGB', (W * 4, H + 520), (18, 18, 18)); d = ImageDraw.Draw(sh)
    for i, (n, box) in enumerate(SHOTS):
        im = Image.open(A + n + '.png').convert('RGB')
        sh.paste(im.resize((W, H), Image.LANCZOS), (i * W, 0)); d.text((i * W + 8, 8), n, fill=(240, 230, 200))
        c = im.crop(box); c.thumbnail((W, 500)); sh.paste(c, (i * W + (W - c.width) // 2, H + 10))
    d.text((8, H + 500), o.note, fill=(200, 200, 200))
    sh.save(o.out, quality=88); print('WROTE', o.out)


if __name__ == '__main__':
    main()
