#!/usr/bin/env python3
"""Single-command batch renderer for Lockwright GEM4 cutaway variants (1, 3, 5, 6, 7 pins).

Renders:
  1) Standard cutaway variants (1, 3, 5, 6, 7 pins) -> art/renders/variants/cutaway_{N}pin.png + .gray.png
  2) Full tension-wrench framing variants (1, 3, 5, 6, 7 pins) -> art/renders/variants/cutaway_{N}pin_wrench.png + .gray.png
  3) Plan B static plates (no moving parts) -> art/renders/variants/plates/plate_{N}pin[_wrench].png
  4) Before/After visual comparison with art/renders/section.{png,jpg} -> art/renders/variants/compare_before_after.png

Usage (either with system Python or Blender's bundled Python):
  python art/blender/variants/render_all_variants.py
  "C:\\Program Files\\Blender Foundation\\Blender 5.2\\blender.exe" -b -P art/blender/variants/render_all_variants.py
"""
import json
import os
import shutil
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
OUT_DIR = os.path.join(REPO_ROOT, 'art', 'renders', 'variants')
PLATES_DIR = os.path.join(OUT_DIR, 'plates')
CUTAWAY_SCRIPT = os.path.join(HERE, 'cutaway_n.py')
PLATE_SCRIPT = os.path.join(HERE, 'render_plate_n.py')

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]


def get_arg(name, default):
    if name in argv:
        idx = argv.index(name)
        if idx + 1 < len(argv) and not argv[idx + 1].startswith('--'):
            return argv[idx + 1]
    return default


RES = get_arg('--res', '2160x2880')
SAMPLES = get_arg('--samples', '256')
DEVICE = get_arg('--device', 'GPU')


def find_blender():
    try:
        import bpy
        if getattr(bpy.app, 'binary_path', ''):
            return bpy.app.binary_path
    except ImportError:
        pass
    env_b = os.environ.get('BLENDER')
    if env_b and os.path.exists(env_b):
        return env_b
    which_b = shutil.which('blender')
    if which_b:
        return which_b
    candidates = [
        r'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe',
        r'C:\Program Files\Blender Foundation\Blender 5.1\blender.exe',
        r'C:\Program Files\Blender Foundation\Blender 5.0\blender.exe',
        r'C:\Program Files\Blender Foundation\Blender 4.3\blender.exe',
        r'C:\Program Files\Blender Foundation\Blender 4.2\blender.exe',
        '/Applications/Blender.app/Contents/MacOS/Blender',
        '/usr/bin/blender',
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    raise FileNotFoundError('Could not locate Blender executable. Set BLENDER environment variable.')


PIN_COUNTS = [1, 3, 5, 6, 7]

# Progressive tension angles across the 0..14 deg range (D-12 / HUD.md §3) for wrench-in-frame variants
WRENCH_ANGLES = {
    1: 4.0,
    3: 7.0,
    5: 10.0,
    6: 12.0,
    7: 14.0,
}


def run_job(blender_bin, script_path, extra_args, label, primary_out):
    cmd = [
        blender_bin, '-b', '-P', script_path, '--',
        '--res', RES,
        '--samples', str(SAMPLES),
        '--device', DEVICE,
    ] + extra_args
    print(f'\n=== [{label}] Running: {" ".join(cmd)} ===', flush=True)
    t0 = time.perf_counter()
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    dt = time.perf_counter() - t0
    if proc.returncode != 0:
        print(proc.stdout)
        raise RuntimeError(f'Job {label} failed with exit code {proc.returncode}')
    for line in proc.stdout.splitlines():
        if line.startswith('WROTE') or 'Saved:' in line:
            print('  ', line, flush=True)
    size_bytes = os.path.getsize(primary_out) if os.path.exists(primary_out) else 0
    gray_path = primary_out[:-4] + '.gray.png'
    gray_bytes = os.path.getsize(gray_path) if os.path.exists(gray_path) else 0
    print(f'=== [{label}] Done in {dt:.2f}s ({size_bytes / (1024 * 1024):.2f} MB) ===', flush=True)
    return {
        'label': label,
        'path': os.path.relpath(primary_out, REPO_ROOT).replace('\\', '/'),
        'seconds': round(dt, 2),
        'size_bytes': size_bytes,
        'size_mb': round(size_bytes / (1024 * 1024), 2),
        'gray_path': os.path.relpath(gray_path, REPO_ROOT).replace('\\', '/') if gray_bytes else None,
        'gray_mb': round(gray_bytes / (1024 * 1024), 2) if gray_bytes else None,
    }


def build_before_after_comparison():
    """Create side-by-side + split before/after visual comparison with art/renders/section.{png,jpg}."""
    try:
        import bpy
        import numpy as np
    except ImportError:
        return None

    before_path = os.path.join(REPO_ROOT, 'art', 'renders', 'section.png')
    if not os.path.exists(before_path):
        before_path = os.path.join(REPO_ROOT, 'art', 'renders', 'section.jpg')
    after_path = os.path.join(OUT_DIR, 'cutaway_5pin.png')
    if not (os.path.exists(before_path) and os.path.exists(after_path)):
        return None

    img_b = bpy.data.images.load(before_path)
    img_a = bpy.data.images.load(after_path)
    w, h = img_a.size[0], img_a.size[1]
    if img_b.size[0] != w or img_b.size[1] != h:
        img_b.scale(w, h)

    arr_b = np.empty(w * h * 4, dtype=np.float32)
    arr_a = np.empty(w * h * 4, dtype=np.float32)
    img_b.pixels.foreach_get(arr_b)
    img_a.pixels.foreach_get(arr_a)
    arr_b = arr_b.reshape((h, w, 4))
    arr_a = arr_a.reshape((h, w, 4))

    # Build a 2160x2880 composite comparison sheet:
    # Top 62% (rows h - int(h*0.62) .. h): Left half = BEFORE (section.py), Right half = AFTER (cutaway_n.py)
    # Bottom 38% (rows 0 .. int(h*0.38)): 2x zoomed detail crop of the shear line, chamfers, pins & springs
    # (Left half = BEFORE 2x zoom on shear line/chambers, Right half = AFTER 2x zoom on shear line/chambers)
    comp = np.zeros((h, w, 4), dtype=np.float32)
    comp[:, :, 3] = 1.0
    split_y = int(h * 0.36)
    mid_x = w // 2

    # Top panel: full frame side-by-side (scaled to 50% width, 64% height, or direct split)
    top_h = h - split_y
    # Subsample 2x horizontally and vertically to fit fullBefore (left) and fullAfter (right) side-by-side!
    half_h = min(top_h - 16, h // 2)
    half_w = min(mid_x - 16, w // 2)
    b_small = arr_b[::2, ::2, :][:half_h, :half_w, :]
    a_small = arr_a[::2, ::2, :][:half_h, :half_w, :]
    y0_top = split_y + (top_h - half_h) // 2
    x0_left = (mid_x - half_w) // 2
    x0_right = mid_x + (mid_x - half_w) // 2
    comp[y0_top:y0_top + half_h, x0_left:x0_left + half_w, :] = b_small
    comp[y0_top:y0_top + half_h, x0_right:x0_right + half_w, :] = a_small

    # Bottom panel: 1:1 native-resolution close-up crop of shear line + chambers 1..4 + springs
    # In Blender image coords (row 0 = bottom, row h = top):
    # Shear line & pins sit around rows 0.38*h .. 0.74*h, cols 0.16*w .. 0.66*w
    crop_h = split_y - 12
    crop_w = mid_x - 12
    cy0 = int(h * 0.37)
    cx0 = int(w * 0.16)
    comp[6:6 + crop_h, 6:6 + crop_w, :] = arr_b[cy0:cy0 + crop_h, cx0:cx0 + crop_w, :]
    comp[6:6 + crop_h, mid_x + 6:mid_x + 6 + crop_w, :] = arr_a[cy0:cy0 + crop_h, cx0:cx0 + crop_w, :]

    # Divider lines (subtle brass tint)
    comp[split_y - 2:split_y + 2, :, :3] = (0.55, 0.38, 0.16)
    comp[:, mid_x - 2:mid_x + 2, :3] = (0.55, 0.38, 0.16)

    comp_path = os.path.join(OUT_DIR, 'compare_before_after.png')
    img_c = bpy.data.images.new('compare_ba', width=w, height=h, alpha=False)
    img_c.pixels.foreach_set(comp.ravel())
    img_c.filepath_raw = comp_path
    img_c.file_format = 'PNG'
    img_c.save()

    bpy.data.images.remove(img_b)
    bpy.data.images.remove(img_a)
    bpy.data.images.remove(img_c)
    size_mb = os.path.getsize(comp_path) / (1024 * 1024)
    print(f'WROTE-COMPARE {comp_path} ({size_mb:.2f} MB)', flush=True)
    return {
        'label': 'compare_before_after',
        'path': 'art/renders/variants/compare_before_after.png',
        'size_mb': round(size_mb, 2),
    }


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    os.makedirs(PLATES_DIR, exist_ok=True)
    blender_bin = find_blender()
    print(f'Using Blender executable: {blender_bin}', flush=True)

    results = []
    t_start = time.perf_counter()

    # 1. Standard cutaway renders (1, 3, 5, 6, 7 pins) + .gray.png
    for n in PIN_COUNTS:
        out_png = os.path.join(OUT_DIR, f'cutaway_{n}pin.png')
        gray_png = os.path.join(OUT_DIR, f'cutaway_{n}pin.gray.png')
        res = run_job(
            blender_bin,
            CUTAWAY_SCRIPT,
            ['--pins', str(n), '--out', out_png, '--gray-out', gray_png],
            f'cutaway_{n}pin',
            out_png,
        )
        results.append(res)

    # 2. Full tension-wrench framing renders (1, 3, 5, 6, 7 pins) + .gray.png
    for n in PIN_COUNTS:
        out_png = os.path.join(OUT_DIR, f'cutaway_{n}pin_wrench.png')
        gray_png = os.path.join(OUT_DIR, f'cutaway_{n}pin_wrench.gray.png')
        angle = WRENCH_ANGLES[n]
        res = run_job(
            blender_bin,
            CUTAWAY_SCRIPT,
            [
                '--pins', str(n),
                '--wrench-in-frame',
                '--tension-angle', str(angle),
                '--out', out_png,
                '--gray-out', gray_png,
            ],
            f'cutaway_{n}pin_wrench',
            out_png,
        )
        results.append(res)

    # 3. Plan B static plates (no moving parts) -> art/renders/variants/plates/
    for n in PIN_COUNTS:
        out_plate = os.path.join(PLATES_DIR, f'plate_{n}pin.png')
        res = run_job(
            blender_bin,
            PLATE_SCRIPT,
            ['--pins', str(n), '--out', out_plate],
            f'plate_{n}pin',
            out_plate,
        )
        results.append(res)

    for n in PIN_COUNTS:
        out_plate_w = os.path.join(PLATES_DIR, f'plate_{n}pin_wrench.png')
        angle = WRENCH_ANGLES[n]
        res = run_job(
            blender_bin,
            PLATE_SCRIPT,
            ['--pins', str(n), '--wrench-in-frame', '--tension-angle', str(angle), '--out', out_plate_w],
            f'plate_{n}pin_wrench',
            out_plate_w,
        )
        results.append(res)

    # 4. Before/After comparison image
    cmp_info = build_before_after_comparison()

    total_sec = round(time.perf_counter() - t_start, 2)
    manifest = {
        'resolution': RES,
        'samples': int(SAMPLES),
        'device': DEVICE,
        'total_seconds': total_sec,
        'jobs': results,
        'comparison': cmp_info,
    }
    manifest_path = os.path.join(OUT_DIR, 'render_manifest.json')
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=2)
    print(f'\nALL VARIANTS COMPLETED in {total_sec:.2f}s. Manifest: {manifest_path}', flush=True)


if __name__ == '__main__':
    main()
