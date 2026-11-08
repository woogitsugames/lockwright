"""VA-14: tool thumbnails, post step. Blender renders (art/blender/tool_thumbs.py, 2x supersampled) ->
game/assets/ui/tools/<tool id>.webp at --px (default 160 = 2x the 80 dp slot in the Workshop row), with a
soft studio fall-off towards the corners, plus a contact sheet for review.

    python art/tools/tool_thumbs_post.py qa/out/tool_thumbs [--px 160] [--sheet art/renders/tool_thumbs_contact.jpg]
"""
import argparse
import glob
import os

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
OUT = os.path.join(ROOT, 'game', 'assets', 'ui', 'tools')


def lift(im, gain=1.3, gamma=0.88):
    """Print-like levels: the renders are exposed for the dark backing; on the dark Workshop paper the metal
    needs more presence (highlights up, blacks kept)."""
    a = np.asarray(im, dtype=np.float32) / 255.0
    a = np.clip(a * gain, 0, 1) ** gamma
    return Image.fromarray((a * 255 + 0.5).astype(np.uint8))


def vignette(im, strength=0.22):
    w, h = im.size
    y, x = np.mgrid[0:h, 0:w]
    r = np.hypot((x - w / 2) / (w / 2), (y - h / 2) / (h / 2)) / np.sqrt(2)
    k = 1.0 - strength * np.clip(r, 0, 1) ** 2
    a = np.asarray(im, dtype=np.float32) * k[..., None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('--px', type=int, default=160)
    ap.add_argument('--quality', type=int, default=86)
    ap.add_argument('--sheet', default=os.path.join(ROOT, 'art', 'renders', 'tool_thumbs_contact.jpg'))
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    files = sorted(f for f in glob.glob(os.path.join(a.src, '*.png')) if not os.path.basename(f).startswith('_'))
    thumbs = []
    for f in files:
        tid = os.path.splitext(os.path.basename(f))[0]
        im = vignette(lift(Image.open(f).convert('RGB').resize((a.px, a.px), Image.LANCZOS)))
        p = os.path.join(OUT, tid + '.webp')
        im.save(p, 'WEBP', quality=a.quality, method=6)
        thumbs.append(im)
        print('WROTE', p, os.path.getsize(p))
    if a.sheet and thumbs:
        cols = 6
        rows = (len(thumbs) + cols - 1) // cols
        sheet = Image.new('RGB', (cols * a.px, rows * a.px), (24, 22, 20))
        for i, im in enumerate(thumbs):
            sheet.paste(im, ((i % cols) * a.px, (i // cols) * a.px))
        sheet.save(a.sheet, quality=88)
        print('SHEET', a.sheet)


if __name__ == '__main__':
    main()
