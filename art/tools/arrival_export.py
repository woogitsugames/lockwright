#!/usr/bin/env python3
# Lockwright — D-58 arrival scene: game assets from the arrival renders (phone-sized WebP), data-driven per job.
#
#   python3 art/tools/arrival_export.py                       # job wrong_floor, all times it has
#   python3 art/tools/arrival_export.py --job grandma_broth   # any job in JOBS (--job all: every job)
#   python3 art/tools/arrival_export.py --master build/local-session/arrival-master   # full GPU sequences (local)
#   python3 art/tools/arrival_export.py --shadows      # use the GPU shadow maps <plate>_shadow_<figure>.png
#
# Per time of day <t> it writes game/assets/arrival/<job>/<t>/:
#   seq/f_01.webp .. f_36.webp  the stair climb (12 fps). Source: the full GPU frames in --master
#                               (<job>_<t>_seq/f_####.png, scaled to --seq-width) if present, else the 36 tiles of
#                               art/renders/arrival/<job>_<t>_final_contact.png (178x318, frame label in-painted):
#                               an interim, soft but the right light and camera path.
#   plate_<figure>.webp         the GPU hold frame with the figure's 2D shadow, no figure (1080x1920)
#   figure_<figure>.webp        the figure alone, full-frame RGBA, so plate + figure stack 1:1 in any TextureRect
#                               with the same stretch mode; the game scales it about the feet for a breathing loop
#   plate.webp                  plate-only jobs (no full-body cut-out of the client: everyone but Kazimierz and
#                               Teresa): the GPU hold frame itself, no figure layer, no anchors (`hold: ""` in the data)
# and updates the job's `anchors` in game/data/arrival_scenes.json (feet/head 0..1 per time and figure).
# The layers come from art/blender/arrival_composite.py --layers-out with the same settings as the reviewed
# composites (art/renders/arrival/README.md), so plate + figure == wrong_floor_<t>_<figure>.png.
#
# .import files: existing ones are never touched or deleted (they are tracked in git, D-55: lossy WebP); a texture
# without one gets a lossy .import (compress/mode=1, lossy_quality 0.8). Godot adds uid/path on the next import;
# commit them with `git add -f` (*.import is gitignored).
import argparse, json, os, subprocess, sys, tempfile
import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
A = os.path.join(ROOT, 'art', 'renders', 'arrival')
G = ['--tint-gain', '2.0', '--sat', '1.2', '--wrap', '0.25']
# job -> time -> [(figure or None, plate, extra composite args)]; mirrors the commands in art/renders/arrival/README.md
JOBS = {
    'wrong_floor': {
        'night': [('kazimierz', 'wrong_floor_night_hold.png', ['--exposure', '1.5']),
                  ('teresa', 'wrong_floor_night_ajar_hold.png', ['--feet-world', 'teresa=560,720', '--occlude-mm', '0', '--exposure', '2.6'])],
        'evening': [('kazimierz', 'wrong_floor_evening_hold.png', ['--exposure', '1.15'])],
        'day': [('kazimierz', 'wrong_floor_day_hold.png', ['--exposure', '1.1'])],
    },
    # plate-only scenes (art/blender/arrival_jobs.json; no cut-out of these clients)
    'grandma_broth': {'day': [(None, 'grandma_broth_day_hold.png', [])]},
    'cat_bathroom': {'evening': [(None, 'cat_bathroom_evening_hold.png', [])]},
    'refuse_ex_partner': {'night': [(None, 'refuse_ex_partner_night_hold.png', [])]},
    'newlyweds_4am': {'night': [(None, 'newlyweds_4am_night_hold.png', [])]},
    'refuse_rush_bribe': {'night': [(None, 'refuse_rush_bribe_night_hold.png', [])]},
    # D-94: places that are not a tenement landing (art/blender/arrival_place.py kits)
    'night_nurse': {'night': [(None, 'night_nurse_night_hold.png', [])]},
    'pizzeria_pays_pizza': {'evening': [(None, 'pizzeria_pays_pizza_evening_hold.png', [])]},
    'bike_interview': {'day': [(None, 'bike_interview_day_hold.png', [])]},
}
CONTACT_COLS, CONTACT_W = 6, 1080   # arrival_composite.contact() defaults
IMPORT_TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="res://{res}"

[params]

compress/mode=1
compress/high_quality=false
compress/lossy_quality=0.8
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=1920
detect_3d/compress_to=1
"""


def ensure_import(path):
    """Lossy-WebP .import next to a new game texture; an existing (tracked) one is left as it is."""
    imp = path + '.import'
    if not os.path.exists(imp):
        res = os.path.relpath(path, os.path.join(ROOT, 'game')).replace(os.sep, '/')
        with open(imp, 'w', newline='\n') as fh:
            fh.write(IMPORT_TEMPLATE.format(res=res))


def inpaint(img, box, iters=300):
    """Fill box (x0, y0, x1, y1) by diffusion from its border (the burned-in frame label on the ceiling/wall)."""
    a = np.asarray(img).astype(np.float32); x0, y0, x1, y1 = box
    m = np.zeros(a.shape[:2], bool); m[y0:y1, x0:x1] = True
    a[m] = a[y1:y1 + 4, x0:x1].reshape(-1, 3).mean(0)   # start from the strip under the label
    for _ in range(iters):
        b = a.copy()
        b[1:-1, 1:-1] = (a[:-2, 1:-1] + a[2:, 1:-1] + a[1:-1, :-2] + a[1:-1, 2:]) / 4
        a[m] = b[m]
    return Image.fromarray(np.clip(a + 0.5, 0, 255).astype(np.uint8))


def frames_from_contact(path, n=36):
    sheet = Image.open(path).convert('RGB'); tw = CONTACT_W // CONTACT_COLS
    th = sheet.height // ((n + CONTACT_COLS - 1) // CONTACT_COLS)
    out = []
    for k in range(n):
        x, y = (k % CONTACT_COLS) * tw, (k // CONTACT_COLS) * th
        tile = sheet.crop((x + 1, y + 1, x + tw - 1, y + th - 1))
        out.append(inpaint(tile, (2, 1, 44, 17)))
    return out


def export_job(o, job, data):
    cfg = JOBS[job]; dst = os.path.join(ROOT, 'game', 'assets', 'arrival', job)
    if 'job.' + job not in data['scenes']:
        sys.exit('add job.%s to %s first (dir, times, hold, steps, ...)' % (job, o.data))
    scene = data['scenes']['job.' + job]; anchors = scene.setdefault('anchors', {})
    tmp = tempfile.mkdtemp(prefix='arrival_export_')
    for t in (o.times or list(cfg)):
        td = os.path.join(dst, t); os.makedirs(os.path.join(td, 'seq'), exist_ok=True)
        # --- sequence
        mdir = os.path.join(o.master, '%s_%s_seq' % (job, t)) if o.master else ''
        if mdir and os.path.isdir(mdir):
            fs = sorted(f for f in os.listdir(mdir) if f.endswith('.png'))
            frames = [Image.open(os.path.join(mdir, f)).convert('RGB') for f in fs]
            frames = [f.resize((o.seq_width, round(f.height * o.seq_width / f.width)), Image.LANCZOS) for f in frames]
            src = mdir
        else:
            src = os.path.join(A, '%s_%s_final_contact.png' % (job, t)); frames = frames_from_contact(src)
        names = ['f_%02d.webp' % (i + 1) for i in range(len(frames))]
        sd = os.path.join(td, 'seq')
        for old in os.listdir(sd):   # only frames that are no longer produced go, with their .import
            if old.endswith('.webp') and old not in names:
                os.remove(os.path.join(sd, old))
                if os.path.exists(os.path.join(sd, old + '.import')):
                    os.remove(os.path.join(sd, old + '.import'))
        for n, f in zip(names, frames):
            p = os.path.join(sd, n)
            f.save(p, 'WEBP', quality=o.seq_q, method=6); ensure_import(p)
        print('SEQ', job, t, len(frames), 'frames', frames[0].size, 'from', os.path.relpath(src, ROOT))
        # --- hold layers
        for fig, plate, extra in cfg[t]:
            if fig is None:   # plate-only: the hold frame as it is
                p = os.path.join(td, 'plate.webp')
                Image.open(os.path.join(A, plate)).convert('RGB').save(p, 'WEBP', quality=o.hold_q, method=6); ensure_import(p)
                anchors[t] = {}
                print('HOLD', job, t, 'plate only')
                continue
            pre = os.path.join(tmp, '%s_%s' % (t, fig))
            cmd = [sys.executable, os.path.join(ROOT, 'art', 'blender', 'arrival_composite.py'), '--plate', os.path.join(A, plate),
                   '--figure', '%s=%s' % (fig, os.path.join(A, 'figures', fig + '.png'))] + G + extra + \
                  ['--out', pre + '_composite.png', '--layers-out', pre]
            shadow = os.path.join(A, plate.replace('_hold.png', '_shadow_%s.png' % fig))
            if o.shadows:
                if not os.path.exists(shadow):
                    sys.exit('missing shadow map ' + shadow)
                cmd += ['--shadow', shadow]
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
            Image.open(pre + '_plate.png').convert('RGB').save(os.path.join(td, 'plate_%s.webp' % fig), 'WEBP', quality=o.hold_q, method=6)
            fg = Image.open(pre + '_figure.png').convert('RGBA')
            fg.save(os.path.join(td, 'figure_%s.webp' % fig), 'WEBP', quality=o.hold_q + 5, alpha_quality=90, method=6)
            for n in ('plate_%s.webp' % fig, 'figure_%s.webp' % fig):
                ensure_import(os.path.join(td, n))
            meta = json.load(open(pre + '.json'))
            anchors.setdefault(t, {})[fig] = {'feet': [round(v, 4) for v in meta['feet']], 'head': [round(v, 4) for v in meta['head']]}
            print('HOLD', job, t, fig)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--job', default='wrong_floor', help='a job in JOBS, or "all"'); ap.add_argument('--times', nargs='*')
    ap.add_argument('--master', help='dir with <job>_<time>_seq/f_####.png full GPU frames (local session)')
    ap.add_argument('--seq-width', type=int, default=540); ap.add_argument('--seq-q', type=int, default=72)
    ap.add_argument('--hold-q', type=int, default=80)
    ap.add_argument('--shadows', action='store_true',
                    help='composite with the Cycles shadow maps (wrong_floor_<t>[_ajar]_shadow_<figure>.png) instead of the 2D shadow')
    ap.add_argument('--data', default=os.path.join(ROOT, 'game', 'data', 'arrival_scenes.json'))
    o = ap.parse_args()
    data = json.load(open(o.data, encoding='utf-8'))
    for job in (list(JOBS) if o.job == 'all' else [o.job]):
        export_job(o, job, data)
    with open(o.data, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, indent=2, ensure_ascii=False); f.write('\n')
    print('WROTE', os.path.relpath(o.data, ROOT))


if __name__ == '__main__':
    main()
