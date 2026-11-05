# Lockwright — main menu proof: render driver + compositing (pressed example, comparison with the lock renders).
#   python3 art/blender/menu_compose.py --render-all [--blender PATH] [--samples 160]   # all renders, then compose (~2-3 h, 4 cores)
#   python3 art/blender/menu_compose.py                                               # compose only (renders already in place)
# Outputs in art/renders/menu/: menu_portrait.png, menu_landscape.png, menu_hits.json, menu_hits_landscape.json,
# menu_pressed_jobs.png (the swap sprite), menu_pressed_example.png (portrait with the sprite pasted at its hit rect),
# menu_pressed_zoom.png (normal vs pressed row, 2x), compare_with_locks.jpg (menu next to three lock renders, same height).
import json, os, subprocess, sys
from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
D = os.path.join(ROOT, 'art', 'renders', 'menu')
argv = sys.argv[1:]
def arg(n, d): return argv[argv.index(n) + 1] if n in argv else d
BL = arg('--blender', '/opt/tools/blender-4.2.9-linux-x64/blender'); SPP = arg('--samples', '160')
PRESSED_ROW, PRESSED_ID = 1, 'jobs'

def blender(*a):
    cmd = [BL, '-b', '-P', os.path.join(ROOT, 'art', 'blender', 'menu_gate.py'), '--'] + list(a)
    print('>>', ' '.join(cmd), flush=True); subprocess.run(cmd, check=True, cwd=ROOT, stdout=subprocess.DEVNULL)

if '--render-all' in argv:
    p = lambda n: os.path.join(D, n)
    blender('--out', p('menu_portrait.png'), '--res', '1080x2400', '--samples', SPP, '--hits', p('menu_hits.json'))
    blender('--out', p('menu_pressed_%s.png' % PRESSED_ID), '--res', '1080x2400', '--samples', SPP,
            '--pressed', str(PRESSED_ROW), '--crop-row', str(PRESSED_ROW))
    blender('--out', p('menu_landscape.png'), '--res', '2400x1080', '--orient', 'landscape', '--samples', SPP,
            '--hits', p('menu_hits_landscape.json'))

# ---- pressed example: paste the sprite at hit_rect - margin
hits = json.load(open(os.path.join(D, 'menu_hits.json')))
base = Image.open(os.path.join(D, 'menu_portrait.png')).convert('RGB')
it = next(i for i in hits['items'] if i['id'] == PRESSED_ID)
m = hits.get('pressed_margin_px', 20); x, y, w, h = it['hit_rect']
spr = Image.open(os.path.join(D, it['pressed_sprite'])).convert('RGB')
x0, y0 = max(0, x - m), max(0, y - m)
print('sprite', spr.size, 'expected', (min(base.width, x + w + m) - x0, min(base.height, y + h + m) - y0))
ex = base.copy(); ex.paste(spr, (x0, y0)); ex.save(os.path.join(D, 'menu_pressed_example.png'), optimize=True)
# zoom: the same row normal (top) and pressed (bottom), 2x
box = (x0, y0, x0 + spr.width, y0 + spr.height)
a, b = base.crop(box), ex.crop(box)
z = Image.new('RGB', (a.width * 2, a.height * 4 + 16), (20, 20, 20))
z.paste(a.resize((a.width * 2, a.height * 2), Image.LANCZOS), (0, 0)); z.paste(b.resize((a.width * 2, a.height * 2), Image.LANCZOS), (0, a.height * 2 + 16))
z.save(os.path.join(D, 'menu_pressed_zoom.png'), optimize=True)

# ---- comparison with the lock renders at the same height
H = 1600
imgs = [base] + [Image.open(os.path.join(ROOT, 'art', 'renders', n + '.png')).convert('RGB') for n in ('wafer', 'lever', 'ring_combo')]
imgs = [im.resize((round(im.width * H / im.height), H), Image.LANCZOS) for im in imgs]
G = 24; Wt = sum(im.width for im in imgs) + G * (len(imgs) + 1)
c = Image.new('RGB', (Wt, H + 2 * G), (14, 14, 14)); xx = G
for im in imgs: c.paste(im, (xx, G)); xx += im.width + G
c.save(os.path.join(D, 'compare_with_locks.jpg'), quality=90)
land = os.path.join(D, 'menu_landscape.png')
if os.path.exists(land):   # landscape next to two locks, same height
    L = Image.open(land).convert('RGB'); H2 = 900
    row = [L] + [Image.open(os.path.join(ROOT, 'art', 'renders', n + '.png')).convert('RGB') for n in ('warded', 'wooden_pin')]
    row = [im.resize((round(im.width * H2 / im.height), H2), Image.LANCZOS) for im in row]
    c2 = Image.new('RGB', (sum(im.width for im in row) + G * 4, H2 + 2 * G), (14, 14, 14)); xx = G
    for im in row: c2.paste(im, (xx, G)); xx += im.width + G
    c2.save(os.path.join(D, 'compare_landscape_with_locks.jpg'), quality=90)
print('composed')
