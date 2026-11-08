# Lockwright — main menu (D-62): the ONE command that renders every menu file the game needs, composes the review
# sheets and exports the game assets.
#
#   python3 art/blender/menu_compose.py --render-all --samples 256 --device OPTIX     # owner's GPU: final, everything
#   python3 art/blender/menu_compose.py --render-missing --samples 48                 # CPU draft: only files not there yet
#   python3 art/blender/menu_compose.py                                               # no render: hits + compose + game export
#
# Options:
#   --render-all | --render-missing   render base images and pressed sprites (all / only missing files)
#   --samples N          Cycles samples of the full images (default 160); --sprite-samples N for the pressed crops (default = --samples)
#   --device D           CPU (default) | OPTIX | CUDA | HIP | METAL | ONEAPI   (passed to menu_gate.py)
#   --langs pl,en,de     label languages (game/i18n/strings.csv, menu.*); --orients portrait,landscape
#   --blender PATH       Blender 4.2 binary (default /opt/tools/blender-4.2.9-linux-x64/blender)
#   --no-game            skip the export to game/assets/ui/menu/
#   --no-sheets          do not rewrite the review sheets (compare_*.jpg, menu_langs.jpg, menu_pressed_*.jpg/png)
#   --vw MM / --vh MM    camera view of the portrait (width, mm) / landscape (height, mm) board, passed to EVERY Blender call
#                        of that orientation (full render, pressed sprites, hits). Default: the value recorded in the hits
#                        JSON ("view"), else portrait --vw 600 (D-66: board ~75% of the width, the owner's GPU finals) and
#                        landscape --vh 585 (= the scene default). The value used is written back into the hits JSON and the layout.
#   --accept-hits        accept regenerated hit rects that differ from the hits JSON already there (otherwise: abort and
#                        restore the old JSON, so a hits-only run can never silently move the zones off the delivered renders)
#
# Renders (art/renders/menu/; PL has no language suffix, EN/DE end in _en/_de):
#   menu_portrait[_xx].png 1080x2400, menu_landscape[_xx].png 2400x1080, menu_hits[_landscape][_xx].json,
#   menu_pressed_<id>[_landscape][_xx].png (one per item: the row pushed in, only its hit rect + 20 px rendered)
# Review sheets: menu_pressed_example.png, menu_pressed_zoom.png, compare_*.jpg, menu_langs.jpg (all languages side by side),
#   menu_pressed_all.jpg (every pressed sprite pasted over its base, per language and orientation)
# Game (game/assets/ui/menu/): menu_<orient>_<lang>.webp, menu_pressed_<id>_<orient>_<lang>.webp (sprite feathered into the
#   base over the 20 px margin, so draft/final noise never shows a seam), menu_layout.json (hit rects, focus rect, margin).
import json, os, subprocess, sys, time
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
D = os.path.join(ROOT, 'art', 'renders', 'menu')
GAME = os.path.join(ROOT, 'game', 'assets', 'ui', 'menu')
argv = sys.argv[1:]
def arg(n, d): return argv[argv.index(n) + 1] if n in argv else d
BL = arg('--blender', '/opt/tools/blender-4.2.9-linux-x64/blender'); SPP = arg('--samples', '160')
SPP_SPRITE = arg('--sprite-samples', SPP); DEVICE = arg('--device', 'CPU').upper()
LANGS = arg('--langs', 'pl,en,de').split(','); ORIENTS = arg('--orients', 'portrait,landscape').split(',')
RENDER_ALL = '--render-all' in argv; RENDER_MISSING = '--render-missing' in argv
# D-66: camera view per orientation. Portrait finals (GPU, 2026-11-06) use --vw 600 (board 798/1080 px = 74% of the width);
# menu_gate.py's own portrait default (432, the close v2 camera) must never be used for this menu again.
VIEW_DEFAULT = {'portrait': ('--vw', '600'), 'landscape': ('--vh', '585')}   # landscape: = menu_gate.py default
# --gate-args "--fill 2e5 --bounce 6e4": extra lighting flags passed to EVERY menu_gate.py call (same light on base + sprites)
GATE_ARGS = arg('--gate-args', '').split()
VIEW_CLI = {'portrait': arg('--vw', None), 'landscape': arg('--vh', None)}
IDS = ['start', 'jobs', 'workshop', 'showcase', 'settings', 'about']
RES = {'portrait': '1080x2400', 'landscape': '2400x1080'}
MARGIN = 20
WEBP_Q = 88          # base images; sprites use the same quality

def sfx(lang): return '' if lang == 'pl' else '_' + lang
def base_png(o, lang): return os.path.join(D, 'menu_%s%s.png' % (o, sfx(lang)))
def hits_json(o, lang): return os.path.join(D, 'menu_hits%s%s.json' % ('' if o == 'portrait' else '_landscape', sfx(lang)))
def sprite_png(o, lang, iid): return os.path.join(D, 'menu_pressed_%s%s%s.png' % (iid, '' if o == 'portrait' else '_landscape', sfx(lang)))

def blender(*a):
    cmd = [BL, '-b', '-P', os.path.join(ROOT, 'art', 'blender', 'menu_gate.py'), '--'] + list(a) + ['--device', DEVICE] + GATE_ARGS
    t = time.time(); print('>>', ' '.join(cmd), flush=True)
    subprocess.run(cmd, check=True, cwd=ROOT, stdout=subprocess.DEVNULL)
    print('   %.0f s' % (time.time() - t), flush=True)

def need(path): return RENDER_ALL or (RENDER_MISSING and not os.path.exists(path))

def view_of(o, lang):
    """(flag, value) of the camera view for orientation o: CLI > recorded in the hits JSON > D-66 default."""
    flag, val = VIEW_DEFAULT[o]
    if VIEW_CLI[o] is not None: return flag, VIEW_CLI[o]
    if os.path.exists(hits_json(o, lang)):
        rec = (json.load(open(hits_json(o, lang))).get('view') or {}).get(flag.strip('-'))
        if rec is not None: return flag, str(rec)
    return flag, val

def record_view(o, lang, flag, val):
    p = hits_json(o, lang); h = json.load(open(p))
    h['view'] = {flag.strip('-'): (float(val) if val is not None else None), 'by': 'art/blender/menu_compose.py'}
    with open(p, 'w') as f: json.dump(h, f, indent=1)

def hit_geometry(p):
    if not os.path.exists(p): return None
    h = json.load(open(p)); return [h.get('board_rect'), h.get('focus_rect'), [(i['id'], i['hit_rect']) for i in h['items']]]

# ---------------------------------------------------------------- 1. renders (+ hits JSON for every language/orientation)
for o in ORIENTS:
    for lang in LANGS:
        flag, val = view_of(o, lang)
        common = ['--res', RES[o], '--orient', o, '--lang', lang] + ([flag, val] if val is not None else [])
        if need(base_png(o, lang)):
            blender('--out', base_png(o, lang), '--samples', SPP, '--hits', hits_json(o, lang), *common)
        else:   # hits only (cheap, deterministic: same scene as the render) -- must reproduce the delivered geometry
            old = open(hits_json(o, lang)).read() if os.path.exists(hits_json(o, lang)) else None
            before = hit_geometry(hits_json(o, lang))
            blender('--out', base_png(o, lang), '--hits', hits_json(o, lang), '--norender', *common)
            after = hit_geometry(hits_json(o, lang))
            if before is not None and after != before and '--accept-hits' not in argv:
                open(hits_json(o, lang), 'w').write(old)
                sys.exit('hits %s/%s: regenerated rects differ from the delivered ones (camera %s %s?) -- old JSON restored; '
                         'pass the camera the renders used (--vw/--vh) or --accept-hits' % (o, lang, flag, val))
        record_view(o, lang, flag, val)
        for i, iid in enumerate(IDS):
            if need(sprite_png(o, lang, iid)):
                blender('--out', sprite_png(o, lang, iid), '--samples', SPP_SPRITE, '--pressed', str(i), '--crop-row', str(i), *common)

def load_hits(o, lang): return json.load(open(hits_json(o, lang)))

def feathered(base, spr, x0, y0, m=MARGIN):
    """Sprite blended into the base: full inside hit_rect, linear ramp over the margin to the base at the sprite's edge."""
    under = base.crop((x0, y0, x0 + spr.width, y0 + spr.height))
    mask = Image.new('L', spr.size, 0); dr = ImageDraw.Draw(mask)
    for k in range(m):
        dr.rectangle((k, k, spr.width - 1 - k, spr.height - 1 - k), fill=round(255 * (k + 1) / m))
    return Image.composite(spr, under, mask)

def sprite_box(it, base, m):
    x, y, w, h = it['hit_rect']
    return max(0, x - m), max(0, y - m)

# ---------------------------------------------------------------- 2. review sheets
have = lambda p: os.path.exists(p)
SHEETS = '--no-sheets' not in argv
if SHEETS and have(base_png('portrait', 'pl')) and have(sprite_png('portrait', 'pl', 'jobs')):
    hits = load_hits('portrait', 'pl'); base = Image.open(base_png('portrait', 'pl')).convert('RGB')
    it = next(i for i in hits['items'] if i['id'] == 'jobs'); m = hits.get('pressed_margin_px', MARGIN)
    spr = Image.open(sprite_png('portrait', 'pl', 'jobs')).convert('RGB'); x0, y0 = sprite_box(it, base, m)
    ex = base.copy(); ex.paste(spr, (x0, y0)); ex.save(os.path.join(D, 'menu_pressed_example.png'), optimize=True)
    box = (x0, y0, x0 + spr.width, y0 + spr.height); a, b = base.crop(box), ex.crop(box)
    z = Image.new('RGB', (a.width * 2, a.height * 4 + 16), (20, 20, 20))
    z.paste(a.resize((a.width * 2, a.height * 2), Image.LANCZOS), (0, 0)); z.paste(b.resize((a.width * 2, a.height * 2), Image.LANCZOS), (0, a.height * 2 + 16))
    z.save(os.path.join(D, 'menu_pressed_zoom.png'), optimize=True)
    # comparison with the lock renders at the same height
    H, G = 1600, 24
    imgs = [base] + [Image.open(os.path.join(ROOT, 'art', 'renders', n + '.png')).convert('RGB') for n in ('wafer', 'lever', 'ring_combo')]
    imgs = [im.resize((round(im.width * H / im.height), H), Image.LANCZOS) for im in imgs]
    c = Image.new('RGB', (sum(im.width for im in imgs) + G * (len(imgs) + 1), H + 2 * G), (14, 14, 14)); xx = G
    for im in imgs: c.paste(im, (xx, G)); xx += im.width + G
    c.save(os.path.join(D, 'compare_with_locks.jpg'), quality=90)
    if have(base_png('landscape', 'pl')):
        L = Image.open(base_png('landscape', 'pl')).convert('RGB'); H2 = 900
        row = [L] + [Image.open(os.path.join(ROOT, 'art', 'renders', n + '.png')).convert('RGB') for n in ('warded', 'wooden_pin')]
        row = [im.resize((round(im.width * H2 / im.height), H2), Image.LANCZOS) for im in row]
        c2 = Image.new('RGB', (sum(im.width for im in row) + G * 4, H2 + 2 * G), (14, 14, 14)); xx = G
        for im in row: c2.paste(im, (xx, G)); xx += im.width + G
        c2.save(os.path.join(D, 'compare_landscape_with_locks.jpg'), quality=90)

# all languages side by side (portrait row over landscape row) and every pressed sprite over its base
G = 24; langs = [l for l in LANGS if have(base_png('portrait', l)) and have(base_png('landscape', l))]
if SHEETS and langs:
    P = [Image.open(base_png('portrait', l)).convert('RGB').resize((540, 1200), Image.LANCZOS) for l in langs]
    Lw = [Image.open(base_png('landscape', l)).convert('RGB').resize((1200, 540), Image.LANCZOS) for l in langs]
    Wt = max(len(P) * (540 + G) + G, 1200 + 2 * G); sheet = Image.new('RGB', (Wt, 1200 + 3 * G + len(Lw) * (540 + G)), (14, 14, 14))
    for k, im in enumerate(P): sheet.paste(im, (G + k * (540 + G), G))
    for k, im in enumerate(Lw): sheet.paste(im, (G, 1200 + 2 * G + k * (540 + G)))
    sheet.save(os.path.join(D, 'menu_langs.jpg'), quality=85)
    tiles = []
    for o in ORIENTS:
        for l in langs:
            hits = load_hits(o, l); base = Image.open(base_png(o, l)).convert('RGB'); m = hits.get('pressed_margin_px', MARGIN)
            for it in hits['items']:
                sp = sprite_png(o, l, it['id'])
                if not have(sp): continue
                spr = Image.open(sp).convert('RGB'); x0, y0 = sprite_box(it, base, m)
                pair = Image.new('RGB', (spr.width, spr.height * 2 + 6), (200, 40, 30))
                pair.paste(base.crop((x0, y0, x0 + spr.width, y0 + spr.height)), (0, 0)); pair.paste(feathered(base, spr, x0, y0, m), (0, spr.height + 6))
                tiles.append(pair.resize((pair.width // 2, pair.height // 2), Image.LANCZOS))
    if tiles:
        cols = 6; tw = max(t.width for t in tiles); th = max(t.height for t in tiles)
        rows_ = (len(tiles) + cols - 1) // cols
        sh = Image.new('RGB', (cols * (tw + 12) + 12, rows_ * (th + 12) + 12), (14, 14, 14))
        for k, t in enumerate(tiles): sh.paste(t, (12 + (k % cols) * (tw + 12), 12 + (k // cols) * (th + 12)))
        sh.save(os.path.join(D, 'menu_pressed_all.jpg'), quality=85)

# ---------------------------------------------------------------- 3. game export
IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"

[deps]

source_file="res://assets/ui/menu/%s"

[params]

compress/mode=1
compress/high_quality=false
compress/lossy_quality=0.85
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
process/size_limit=2400
detect_3d/compress_to=1
"""

def write_webp(img, name):
    p = os.path.join(GAME, name); img.save(p, 'WEBP', quality=WEBP_Q, method=6)
    imp = p + '.import'
    if not os.path.exists(imp):          # lossy import settings; Godot fills in uid/dest on --import
        open(imp, 'w').write(IMPORT % name)
    return os.path.getsize(p)

if '--no-game' not in argv:
    os.makedirs(GAME, exist_ok=True)
    layout = {'schema': 'lockwright.menu_layout/1', 'note': 'generated by art/blender/menu_compose.py; rects [x, y, w, h] in image px',
              'pressed_margin_px': MARGIN, 'langs': [], 'orients': {}}
    total = 0
    for o in ORIENTS:
        ref = None
        for lang in LANGS:
            if not have(base_png(o, lang)) or not all(have(sprite_png(o, lang, i)) for i in IDS):
                print('game export: skip %s/%s (render missing)' % (o, lang)); continue
            hits = load_hits(o, lang)
            rects = {it['id']: it['hit_rect'] for it in hits['items']}
            if ref is None:
                ref = {'size': [hits['width'], hits['height']], 'px_per_dp': hits['px_per_dp'], 'view': hits.get('view'),
                       'board_rect': hits['board_rect'], 'focus_rect': hits['focus_rect'],
                       'items': [{'id': it['id'], 'hit_rect': it['hit_rect']} for it in hits['items']]}
            else:   # hit bands do not depend on the label text: one layout per orientation
                assert all(rects[i['id']] == i['hit_rect'] for i in ref['items']), 'hit rects differ between languages (%s)' % lang
                f, g = ref['focus_rect'], hits['focus_rect']
                x0, y0 = min(f[0], g[0]), min(f[1], g[1]); x1, y1 = max(f[0] + f[2], g[0] + g[2]), max(f[1] + f[3], g[1] + g[3])
                ref['focus_rect'] = [x0, y0, x1 - x0, y1 - y0]
            base = Image.open(base_png(o, lang)).convert('RGB')
            total += write_webp(base, 'menu_%s_%s.webp' % (o, lang))
            for it in hits['items']:
                spr = Image.open(sprite_png(o, lang, it['id'])).convert('RGB'); x0, y0 = sprite_box(it, base, MARGIN)
                total += write_webp(feathered(base, spr, x0, y0), 'menu_pressed_%s_%s_%s.webp' % (it['id'], o, lang))
                ri = next(r for r in ref['items'] if r['id'] == it['id'])
                ri.setdefault('sprite_rect', [x0, y0, spr.width, spr.height])   # where the pressed sprite goes (image px)
            if lang not in layout['langs']: layout['langs'].append(lang)
        if ref: layout['orients'][o] = ref
    with open(os.path.join(GAME, 'menu_layout.json'), 'w') as f:
        json.dump(layout, f, indent=1)
    print('game export: %s, %.2f MB of WebP' % (GAME, total / 1e6))
print('composed')
