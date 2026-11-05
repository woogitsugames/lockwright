# Lockwright — plan-B plates for the `combo` lock screen (thumbwheel combination lock, LOCKS.md §2.19).
# Invented, game-readable mechanism (no real product): a cast body with a row of up to five thumbwheels
# on one axis. Each wheel sits on a sleeve; the sleeve bore has an axial gate slot. A latch bar runs
# through the bores and carries one sprung tooth per sleeve; pulling the cable presses the teeth onto
# the bores. When every slot is under its tooth the teeth drop in, the bar slides along the slots and the
# cable plug comes free.
# Quarter cut-away: the front-lower quarter of the body, wheels and sleeves is removed (cut on the
# vertical plane through the axis), so the top half of each wheel shows its digits and the bottom half
# shows the section: wheel ring, sleeve wall (where the gate slot passes at 6 o'clock), bore, latch bar
# and teeth. Front camera, axis horizontal.
#   plate.png       static: bench, body (incl. the section faces), blank wheels (no digits), sleeves
#   front.png       the body front round the wheel window with the reading line (drawn over the wheels)
#   latch.png       the latch bar (section), locked pose
#   tooth.png       one sprung tooth at slot 0, resting on the bore (the game moves it per slot)
#   plug.png        the cable plug held by the bar
#   band.png        the digit band of one wheel, unrolled (white = blank metal, the game multiplies it
#                   over the blank wheel of the plate with a cylinder mapping)
#   ref.png         (--passes ref) everything, for comparison
#   layers.json     pixel geometry (axis, slot centres, wheel radius, mm -> px, crops)
# Run (CPU now, final 2x on a GPU later):
#   blender -b -P art/blender/plates/combo_plate.py -- \
#       --out-dir game/assets/photoreal_families/combo/photo --res 618x824 --spp 16 --device CPU
import bpy, json, math, os, sys
import numpy as np

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
ROOT_DIR = os.path.abspath(os.path.join(BLENDER_DIR, '..', '..'))
sys.path.insert(0, BLENDER_DIR)
from lw_common import *  # noqa: F401,F403
from mathutils import Vector, Matrix

arg = cli()
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'combo', 'photo')))
RES = [int(v) for v in arg('--res', '618x824').split('x')]
SPP = int(arg('--spp', arg('--samples', '16')))
DEVICE = arg('--device', 'CPU').upper()
PASSES = arg('--passes', 'plate,front,latch,tooth,plug,band').split(',')
os.makedirs(OUT_DIR, exist_ok=True)
FONT = os.path.join(ROOT_DIR, 'game', 'assets', 'fonts', 'BonaNova-Bold.ttf')

# ---------------------------------------------------------------- geometry (mm; X along the axis, Z up, Y away from camera)
SLOTS = [-14.0, -7.0, 0.0, 7.0, 14.0]
WR, WW = 7.0, 5.6             # wheel radius, width
SR, BR = 4.0, 2.2             # sleeve outer radius, bore radius
BODY = (-21.0, 21.0, -11.0, 10.0)
WIN = (-17.6, 17.6)           # wheel window in the body front (x)
READ_DEG = 30.0               # reading line: degrees above the front
TOOTH_W = 1.6
NOTCH_D = 1.2
DIST, LENS = 215.0, 150.0


def cutter():
    """Front-lower quarter: y < 0 and z < 0."""
    return box('qcut', -60, 60, -60, 0.0, -60, 0.0)


def qcut(o):
    boolean(o, cutter())
    return o


M = {
    'bench':  photo_mat('ph_bench', 'bench_beech_top', scale=220, rot=0, metallic=0.0, rough_add=0.05, bump=0.3, grime=0.3),
    'body':   photo_mat('ph_body', 'steel_cast_grey_paint', scale=60, metallic=0.0, base=(0.10, 0.11, 0.12), base_mix=0.4, rough_add=0.02, coat=0.3, bump=0.25, wear=0.5, grime=0.5),
    'cast':   photo_mat('ph_cast_cut', 'steel_ground', scale=16, rot=70, base=(0.50, 0.50, 0.50), base_mix=0.5, rough_add=0.22, bump=0.25, grime=0.2),
    'wheel':  photo_mat('ph_wheel', 'nickel_satin', scale=18, rot=90, base=(0.66, 0.66, 0.64), base_mix=0.35, rough_add=0.06, wear=0.4, grime=0.6),
    'sleeve': photo_mat('ph_sleeve', 'brass_face_milled', scale=10, rot=90, base=(0.80, 0.60, 0.30), base_mix=0.5, rough_add=0.12, bump=0.15, grime=0.3),
    'bar':    photo_mat('ph_bar', 'steel_ground', scale=12, rot=0, base=(0.60, 0.61, 0.62), base_mix=0.4, rough_add=0.10, bump=0.15, grime=0.3),
    'plug':   photo_mat('ph_plug', 'nickel_satin', scale=12, rot=0, base=(0.55, 0.55, 0.54), base_mix=0.3, rough_add=0.06, wear=0.4, grime=0.4),
    'cable':  photo_mat('ph_cable', 'leather_chocolate', scale=14, rot=90, metallic=0.0, base=(0.05, 0.05, 0.055), base_mix=0.7, rough_add=-0.1, coat=0.6, bump=0.3),
    'dark':   dark_mat('cavity', (0.012, 0.010, 0.009), 0.9),
    'ink':    dark_mat('ink', (0.03, 0.028, 0.026), 0.6),
    'paint':  dark_mat('index_paint', (0.80, 0.76, 0.66), 0.5),
}

objs = {'back': [], 'front': [], 'moving': {}}

# ---------------------------------------------------------------- bench + body
bench = box('bench', -200, 200, 14.0, 40.0, -200, 200); put(bench, M['bench'], 0.5, 2); objs['back'].append(bench)
x0, x1, z0, z1 = BODY
body = box('body', x0, x1, -7.5, 14.0, z0, z1)
boolean(body, box('win', WIN[0], WIN[1], -9, 9, -WR - 0.8, WR + 0.8))       # wheel bay (through the body)
boolean(body, cyl('bore', BR + 0.02, 60, (0, 0, 0), axis='X'))
put(qcut(body), M['body'], 0.35, 3)
objs['back'].append(body)
# section faces of the cast body show the cut material (a thin skin on the cut plane)
skin = box('bodyskin', x0 + 0.05, x1 - 0.05, -0.02, 0.0, z0 + 0.05, -0.05)
boolean(skin, box('sw', WIN[0], WIN[1], -1, 1, -WR - 0.8, 0.5))
boolean(skin, cyl('sb', BR + 0.02, 60, (0, 0, 0), axis='X'))
put(skin, M['cast']); objs['back'].append(skin)
# webs between wheels (part of the body, axis supports)
for xs in [(-17.6 + 0.0), -10.5, -3.5, 3.5, 10.5, 17.6]:
    web = cyl('web', WR - 1.2, 1.2, (xs, 0, 0), axis='X', verts=96)
    boolean(web, cyl('wb', BR + 0.02, 10, (xs, 0, 0), axis='X'))
    put(qcut(web), M['body'], 0.1, 2); objs['back'].append(web)
# cable on the left, plug socket on the right
cab = cyl('cable', 2.6, 60, (x0 - 30, 4.0, -2.0), axis='X', verts=48); put(cab, M['cable'], 0.2, 2); objs['back'].append(cab)
fer = cyl('ferrule', 3.4, 5.0, (x0 - 2.5, 4.0, -2.0), axis='X', verts=48); put(fer, M['plug'], 0.3, 2); objs['back'].append(fer)

# ---------------------------------------------------------------- wheels (blank) + sleeves, all in the plate
for i, xs in enumerate(SLOTS):
    w = cyl('wheel%d' % i, WR, WW, (xs, 0, 0), axis='X', verts=160)
    boolean(w, cyl('wi', SR + 0.02, 10, (xs, 0, 0), axis='X'))
    for j in range(40):  # fine ribs on the rim (grip), between the digits
        a = 2 * math.pi * (j + 0.5) / 40
        rib = box('rib', xs - WW / 2 - 0.1, xs + WW / 2 + 0.1, -0.18, 0.18, WR - 0.25, WR + 0.5)
        rib.data.transform(Matrix.Rotation(a, 4, 'X')); boolean(w, rib)
    put(qcut(w), M['wheel'], 0.12, 2); objs['back'].append(w)
    s = cyl('sleeve%d' % i, SR, WW - 0.4, (xs, 0, 0), axis='X', verts=96)
    boolean(s, cyl('sb', BR, 10, (xs, 0, 0), axis='X'))
    put(qcut(s), M['sleeve'], 0.08, 2); objs['back'].append(s)
# the bore behind the bar: a dark cavity half-pipe
cav = cyl('cav', BR - 0.05, 40, (0, 0.05, 0), axis='X', verts=48); boolean(cav, box('ch', -60, 60, -60, 0.05, -60, 60)); put(cav, M['dark'])
objs['back'].append(cav)

# ---------------------------------------------------------------- body front (upper) with the window and the reading line
fr = box('front', x0, x1, -8.6, -7.5, 0.0, z1)
boolean(fr, box('fw', WIN[0], WIN[1], -10, -6, -1, WR * math.sin(math.radians(68))))
put(fr, M['body'], 0.25, 3); objs['front'].append(fr)
ra = math.radians(READ_DEG)
for side in (-1, 1):
    # index arrows at both ends of the window, pointing at the reading line
    x = WIN[0] - 0.2 if side < 0 else WIN[1] + 0.2
    tri = prism('idx', [(x, WR * math.sin(ra) - 0.7), (x, WR * math.sin(ra) + 0.7), (x - side * 1.6, WR * math.sin(ra))], -8.7, -8.55)
    put(tri, M['paint']); objs['front'].append(tri)
line = box('readline', WIN[0], WIN[1], -WR * math.cos(ra) - 0.35, -WR * math.cos(ra) - 0.25, WR * math.sin(ra) - 0.05, WR * math.sin(ra) + 0.05)
put(line, M['ink']); objs['front'].append(line)
for xs in (x0 + 1.8, x1 - 1.8):
    objs['front'].append(screw_head('fscrew', (xs, -8.6, z1 - 2.0), 0.9, 0.5, axis='-Y', slot=False, kind='dome', mat=M['plug']))

# ---------------------------------------------------------------- moving: latch bar, tooth, plug
bar = cyl('bar', BR - 0.25, 44.0, (-0.5, 0, 0), axis='X', verts=64)
boolean(bar, box('flat', -40, 40, -10, 10, -10, -1.2))   # flat underside the teeth ride in
put(qcut(bar), M['bar'], 0.08, 2)
objs['moving']['latch'] = [bar]
tooth = box('tooth', SLOTS[0] - TOOTH_W / 2, SLOTS[0] + TOOTH_W / 2, -1.6, 1.6, -BR - 0.0, -0.9)
put(qcut(tooth), M['bar'], 0.15, 2)
objs['moving']['tooth'] = [tooth]
plug = cyl('plug', 2.0, 7.0, (x1 + 3.0, 0, 0), axis='X', verts=64)
boolean(plug, cyl('pg', 2.4, 1.2, (x1 - 0.2, 0, 0), axis='X', verts=64))  # groove the bar holds
put(plug, M['plug'], 0.2, 2)
pc = cyl('pcable', 2.6, 40, (x1 + 26.0, 0, 0), axis='X', verts=48); put(pc, M['cable'], 0.2, 2)
objs['moving']['plug'] = [plug, pc]

# ---------------------------------------------------------------- light + camera
world_hdri(0.06, sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 0, 0)
area_light('key', (-90, -170, 140), AIM, 50, 160000, (1.0, 0.85, 0.68))
area_light('fill', (140, -170, -20), AIM, 90, 7000, (0.9, 0.94, 1.0))
area_light('rim', (30, 40, 160), AIM, 50, 3000, (1.0, 0.92, 0.82))
cd = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cd); scene.collection.objects.link(cam); scene.camera = cam
cd.lens = LENS; cd.sensor_fit = 'HORIZONTAL'; cd.sensor_width = 36.0; cd.clip_start = 1; cd.clip_end = 5000
CAM_Z = -4.0
cam.location = (0, -DIST, CAM_Z); cam.rotation_euler = (math.pi / 2, 0, 0)
render_setup(os.path.join(OUT_DIR, 'ref.png'), RES, SPP, exposure=float(arg('--exp', '0.4')))
if DEVICE == 'GPU':
    try:
        __import__('plate_common').enable_gpu_cycles()
    except Exception as e:  # noqa: BLE001
        print('GPU setup failed, CPU:', e)
scene.render.image_settings.color_mode = 'RGBA'
scene.render.image_settings.color_depth = '8'


def px_per_mm(depth):
    return LENS / 36.0 * RES[0] / (DIST + depth)


def to_px(x, z, depth):
    s = px_per_mm(depth)
    return [RES[0] / 2 + x * s, RES[1] / 2 - (z - CAM_Z) * s]


meta = {'family': 'combo', 'res': RES, 'spp': SPP, 'device': DEVICE, 'layers': {},
        'axis_px': to_px(0, 0, 0)[1], 'slots_px': [to_px(x, 0, -WR)[0] for x in SLOTS],
        'slots_section_px': [to_px(x, 0, 0)[0] for x in SLOTS],
        'wheel': {'radius_mm': WR, 'width_mm': WW, 'px_per_mm_front': px_per_mm(-WR), 'px_per_mm_section': px_per_mm(0.0),
                  'read_deg': READ_DEG, 'window_top_deg': 68.0},
        'sleeve': {'bore_mm': BR, 'outer_mm': SR, 'notch_depth_mm': NOTCH_D, 'tooth_w_mm': TOOTH_W},
        'slot_pitch_mm': 7.0}


def crop_save(tmp, name, rgba=True):
    img = bpy.data.images.load(tmp, check_existing=False)
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(a); a = a.reshape(h, w, 4)[::-1]
    if rgba:
        ys, xs = np.nonzero(a[..., 3] > 0.004)
        if len(xs) == 0:
            print('EMPTY layer', name); bpy.data.images.remove(img); return
        x0_, x1_, y0_, y1_ = max(xs.min() - 2, 0), min(xs.max() + 3, w), max(ys.min() - 2, 0), min(ys.max() + 3, h)
    else:
        x0_, x1_, y0_, y1_ = 0, w, 0, h
    c = np.ascontiguousarray(a[y0_:y1_, x0_:x1_][::-1])
    out = bpy.data.images.new(name, x1_ - x0_, y1_ - y0_, alpha=True)
    out.pixels.foreach_set(c.ravel())
    out.filepath_raw = os.path.join(OUT_DIR, name + '.png'); out.file_format = 'PNG'; out.save()
    meta['layers'][name] = {'offset': [int(x0_), int(y0_)], 'size': [int(x1_ - x0_), int(y1_ - y0_)]}
    bpy.data.images.remove(out); bpy.data.images.remove(img)
    print('WROTE', name, meta['layers'][name], flush=True)


def all_moving():
    return [o for lst in objs['moving'].values() for o in lst]


def set_vis(o, cam_on, shadow_on=True, hidden=False):
    o.hide_render = hidden
    o.visible_camera = cam_on
    o.visible_shadow = shadow_on


def render_pass(name, show, back_cam=False, front_cam=False, transparent=True):
    for o in objs['back']:
        set_vis(o, back_cam, shadow_on=not transparent)
    for o in objs['front']:
        set_vis(o, front_cam, shadow_on=(not transparent) or front_cam)
    for o in all_moving():
        set_vis(o, False, hidden=True)
    for o in show:
        set_vis(o, True, hidden=False)
    scene.render.film_transparent = transparent
    tmp = os.path.join(OUT_DIR, '_tmp_%s.png' % name)
    scene.render.filepath = tmp
    bpy.ops.render.render(write_still=True)
    crop_save(tmp, name, rgba=transparent)
    os.remove(tmp)


if 'ref' in PASSES:
    for o in objs['back'] + objs['front'] + all_moving():
        set_vis(o, True)
    scene.render.film_transparent = False
    scene.render.filepath = os.path.join(OUT_DIR, 'ref.png')
    bpy.ops.render.render(write_still=True)
if 'plate' in PASSES:
    render_pass('plate', [], back_cam=True, transparent=False)
if 'front' in PASSES:
    render_pass('front', [], front_cam=True)
if 'latch' in PASSES:
    render_pass('latch', objs['moving']['latch'])
if 'tooth' in PASSES:
    render_pass('tooth', objs['moving']['tooth'])
if 'plug' in PASSES:
    render_pass('plug', objs['moving']['plug'])

if 'band' in PASSES:
    # digit band: an orthographic top view of a flat strip, 10 cells (one digit each) of white metal
    # with engraved dark digits and a rib line between cells; v = 0 at the centre of digit 0, digits
    # increase downwards (the next digit comes up when the wheel is rolled up)
    for o in list(scene.objects):
        o.hide_render = True
    BW, CELL = 64, 64
    strip = box('strip', -WW / 2, WW / 2, 0.0, 0.5, -5.0 * 4.4, 5.0 * 4.4)
    white = dark_mat('band_white', (1.0, 1.0, 1.0), 0.6)
    white.node_tree.nodes['Principled BSDF'].inputs['Emission Color'].default_value = (1, 1, 1, 1)
    white.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 1.0
    put(strip, white)
    inkm = dark_mat('band_ink', (0.0, 0.0, 0.0), 0.6)
    for d in range(10):
        zc = 5.0 * 4.4 - (d + 0.5) * 4.4
        bpy.ops.object.text_add(location=(0, 0, 0)); t = bpy.context.object; t.data.body = str(d)
        if os.path.exists(FONT):
            t.data.font = bpy.data.fonts.load(FONT, check_existing=True)
        t.data.size = 3.3; t.data.align_x = 'CENTER'; t.data.align_y = 'CENTER'
        bpy.ops.object.convert(target='MESH'); t = bpy.context.object
        t.data.transform(Matrix.Rotation(math.pi / 2, 4, 'X')); t.data.transform(Matrix.Translation((0, -0.05, zc)))
        put(t, inkm)
        rib = box('cellrib', -WW / 2, WW / 2, -0.06, 0.0, zc - 2.2 - 0.12, zc - 2.2 + 0.12); put(rib, inkm)
    oc = bpy.data.cameras.new('ocam'); ocam = bpy.data.objects.new('ocam', oc); scene.collection.objects.link(ocam)
    oc.type = 'ORTHO'; oc.ortho_scale = 44.0; oc.sensor_fit = 'VERTICAL'
    ocam.location = (0, -50, 0); ocam.rotation_euler = (math.pi / 2, 0, 0)
    scene.camera = ocam
    scene.render.resolution_x, scene.render.resolution_y = BW, CELL * 10
    scene.render.film_transparent = False
    scene.world = None
    scene.view_settings.view_transform = 'Standard'; scene.view_settings.look = 'None'; scene.view_settings.exposure = 0.0
    scene.cycles.samples = 16
    scene.render.filepath = os.path.join(OUT_DIR, 'band.png')
    scene.render.image_settings.color_mode = 'RGB'
    bpy.ops.render.render(write_still=True)
    meta['band'] = {'cells': 10, 'size': [BW, CELL * 10], 'width_mm': WW}

mp = os.path.join(OUT_DIR, 'layers.json')
if os.path.exists(mp):
    old = json.load(open(mp)); ol = old.get('layers', {}); ol.update(meta['layers']); meta['layers'] = ol
    if 'band' not in meta and 'band' in old:
        meta['band'] = old['band']
json.dump(meta, open(mp, 'w'), indent=1)
print('DONE', OUT_DIR)
