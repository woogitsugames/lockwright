#!/usr/bin/env python3
"""Real-time helper: Godot (Mobile) does not occlude sky/probe reflections with the AO map, so the inside
of the pin chambers reflects the open sky. For metals the albedo is the reflectance (F0), so baking AO into
it occludes reflections the way Cycles' path tracing does. Writes tex/<mat>_albedo_rt.png.
   python3 tools/ao_into_albedo.py [--strength 0.85]"""
import sys, json, pathlib
import numpy as np
from PIL import Image
root = pathlib.Path(__file__).resolve().parent.parent / 'assets'
k = float(sys.argv[sys.argv.index('--strength') + 1]) if '--strength' in sys.argv else 0.85
mats = json.load(open(root / 'scene.json'))['materials']
for name, info in mats.items():
    alb = np.asarray(Image.open(root / 'tex' / f'{name}_albedo.png').convert('RGB')).astype(np.float64) / 255
    ao = np.asarray(Image.open(root / 'tex' / f'{name}_orm.png').convert('RGB'))[..., 0].astype(np.float64) / 255
    m = float(info.get('metallic', 0))
    lin = np.where(alb <= 0.04045, alb / 12.92, ((alb + 0.055) / 1.055) ** 2.4)        # sRGB -> linear
    lin *= (1 - k * m * (1 - ao))[..., None]                                            # metals only
    out = np.where(lin <= 0.0031308, lin * 12.92, 1.055 * lin ** (1 / 2.4) - 0.055)
    Image.fromarray((np.clip(out, 0, 1) * 255 + 0.5).astype(np.uint8)).save(root / 'tex' / f'{name}_albedo_rt.png', optimize=True)
    print(name, 'metallic', m)
