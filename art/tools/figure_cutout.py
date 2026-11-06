#!/usr/bin/env python3
# Lockwright — D-58 arrival figures: cut a full-body photo (plain light-grey studio background) out with alpha.
#
#   pip install rembg onnxruntime          # once; the model (BiRefNet portrait, ~900 MB) downloads on first use
#   python3 art/tools/figure_cutout.py contrib/gpt/G23/images/D1_kazimierz_fullbody.png art/renders/arrival/figures/kazimierz.png
#   python3 art/tools/figure_cutout.py SRC OUT [--mask precomputed_mask.png] [--model birefnet-portrait] [--keep-box x0,y0,x1,y1]
#   D1 (Kazimierz): --keep-box 380,175,425,250  (the grey key is close to the studio grey; the model drops it)
#
# 1. matte: rembg BiRefNet-portrait soft mask (keeps wisps of hair as partial alpha);
# 2. clean-up: alpha below 3 % -> 0, above 97 % -> 1, only the largest blob (no specks, no floor shadow:
#    the studio's soft shadow under the shoes is background, the plate gets its own shadow);
#    --keep-box: inside the box a colour key against the box's own border (local background) is added to the
#    matte, for props the model loses (the key in Kazimierz's hand);
# 3. colour decontamination: pymatting estimate_foreground_ml solves for the foreground colour under the
#    partial alpha, so the grey studio light does not stay as a halo on the hair and the coat's edge;
# 4. crop to the alpha bbox + 16 px, save RGBA PNG.
import argparse
import numpy as np
from PIL import Image
from scipy import ndimage


def matte(img, model):
    from rembg import new_session, remove
    return np.asarray(remove(img, session=new_session(model), only_mask=True)).astype(np.float64) / 255.0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src'); ap.add_argument('out')
    ap.add_argument('--mask'); ap.add_argument('--model', default='birefnet-portrait')
    ap.add_argument('--keep-box', action='append', default=[])
    o = ap.parse_args()
    img = Image.open(o.src).convert('RGB')
    a = np.asarray(Image.open(o.mask).convert('L')).astype(np.float64) / 255.0 if o.mask else matte(img, o.model)
    a = np.clip((a - 0.03) / 0.94, 0, 1)
    rgb8 = np.asarray(img).astype(np.float64)
    for kb in o.keep_box:
        x0, y0, x1, y1 = (int(v) for v in kb.split(','))
        box = rgb8[y0:y1, x0:x1]
        border = np.concatenate([box[0], box[-1], box[:, 0], box[:, -1]])
        bg = np.median(border, 0)
        d = np.sqrt(((box - bg) ** 2).sum(-1))
        k = np.clip((d - 14.0) / 18.0, 0, 1)
        core = ndimage.binary_fill_holes(ndimage.binary_closing(k > 0.5, iterations=2))
        k = np.where(core, 1.0, k * ndimage.binary_dilation(core, iterations=2))
        a[y0:y1, x0:x1] = np.maximum(a[y0:y1, x0:x1], k)
    lab, n = ndimage.label(a > 0.5)
    if n > 1:
        sizes = ndimage.sum(np.ones_like(a), lab, range(1, n + 1)); keep = lab == 1 + int(np.argmax(sizes))
        keep = ndimage.binary_dilation(keep, iterations=12)        # keep the soft fringe around the main blob
        a = a * keep
    from pymatting import estimate_foreground_ml
    rgb = np.asarray(img).astype(np.float64) / 255.0
    fg = np.clip(estimate_foreground_ml(rgb, a), 0, 1)
    out = np.dstack([fg, a])
    ys, xs = np.nonzero(a > 0.01)
    y0, y1 = max(0, ys.min() - 16), min(a.shape[0], ys.max() + 17); x0, x1 = max(0, xs.min() - 16), min(a.shape[1], xs.max() + 17)
    Image.fromarray((out[y0:y1, x0:x1] * 255 + 0.5).astype(np.uint8), 'RGBA').save(o.out, optimize=True)
    print('WROTE', o.out, (x1 - x0, y1 - y0))


if __name__ == '__main__':
    main()
