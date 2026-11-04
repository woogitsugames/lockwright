#!/usr/bin/env python3
"""Cycles vs Godot: split image (left half Cycles, right half Godot), side-by-side, difference map and numbers.
   python3 tools/compare.py CYCLES.png GODOT.png OUT_PREFIX [--label "Godot A"]
Writes OUT_PREFIX_split.png, OUT_PREFIX_side.png, OUT_PREFIX_diff.png and prints JSON metrics:
mean abs error (0-255), PSNR (dB), SSIM on luminance (8x8 windows, own implementation), mean luminance both."""
import sys, json
import numpy as np
from PIL import Image, ImageDraw

a_path, b_path, out = sys.argv[1:4]
label = sys.argv[sys.argv.index('--label') + 1] if '--label' in sys.argv else 'Godot'
A = Image.open(a_path).convert('RGB'); B = Image.open(b_path).convert('RGB')
if B.size != A.size:
    B = B.resize(A.size, Image.LANCZOS)
a = np.asarray(A).astype(np.float64); b = np.asarray(B).astype(np.float64)
w, h = A.size

def lum(x):
    return 0.2126 * x[..., 0] + 0.7152 * x[..., 1] + 0.0722 * x[..., 2]

def ssim(x, y, k=8):
    H, W = (x.shape[0] // k) * k, (x.shape[1] // k) * k
    x = x[:H, :W].reshape(H // k, k, W // k, k); y = y[:H, :W].reshape(H // k, k, W // k, k)
    mx, my = x.mean((1, 3)), y.mean((1, 3))
    vx, vy = x.var((1, 3)), y.var((1, 3))
    cxy = ((x - mx[:, None, :, None]) * (y - my[:, None, :, None])).mean((1, 3))
    c1, c2 = (0.01 * 255) ** 2, (0.03 * 255) ** 2
    return float((((2 * mx * my + c1) * (2 * cxy + c2)) / ((mx ** 2 + my ** 2 + c1) * (vx + vy + c2))).mean())

mae = float(np.abs(a - b).mean())
mse = float(((a - b) ** 2).mean())
m = {'size': [w, h], 'mae': round(mae, 2), 'psnr_db': round(10 * np.log10(255 ** 2 / max(mse, 1e-9)), 2),
     'ssim_luma': round(ssim(lum(a), lum(b)), 4), 'mean_luma_cycles': round(float(lum(a).mean()), 1),
     'mean_luma_godot': round(float(lum(b).mean()), 1)}

split = A.copy(); split.paste(B.crop((w // 2, 0, w, h)), (w // 2, 0))
d = ImageDraw.Draw(split); lw = max(2, w // 600)
d.line([(w // 2, 0), (w // 2, h)], fill=(240, 236, 226), width=lw)
fs = max(14, w // 50)
for x, t in ((fs, 'Cycles'), (w // 2 + fs, label)):
    d.rectangle([x - 6, fs - 6, x + len(t) * fs * 0.62 + 6, fs * 2 + 4], fill=(20, 18, 16))
    d.text((x, fs), t, fill=(240, 236, 226), font_size=fs)
split.save(out + '_split.png', optimize=True)
side = Image.new('RGB', (w * 2, h)); side.paste(A, (0, 0)); side.paste(B, (w, 0))
side.resize((w, h // 2)).save(out + '_side.png', optimize=True)
diff = np.clip(np.abs(a - b).mean(2) * 4, 0, 255).astype(np.uint8)
Image.fromarray(diff).save(out + '_diff.png', optimize=True)
print(json.dumps(m))
