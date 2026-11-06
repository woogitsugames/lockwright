# Lockwright — plan-B plates for the `dial_safe` lock screen (LOCKS.md §2.18, D-59/D-60).
# Invented, game-readable wheel pack (not a reproduction of any real safe lock): a steel door is cut
# away round the dial; behind it a pack of 2..4 wheels of stepped diameter (wheel 0 farthest from the
# dial and largest), so every wheel's rim shows. A fence bar above the pack carries one sprung feeler
# per wheel; each feeler rests on its own wheel's rim and drops into that wheel's gate notch. When every
# feeler is down, the fence bar drops, its stud clears the bolt notch and the bolt is drawn back.
#
# The camera looks straight down the spindle (perspective, axis = optical axis), so every rotating part
# turns in the image plane and a 2D rotation about the spindle point is exact. The game composes
# Cycles layers (RGBA, cropped) in a SubViewport sized to the on-screen pixels (N-65):
#   plate.png             static case (back), no moving parts
#   front.png             door fragment, dial bezel with the index mark (drawn over the wheels)
#   wheel0..3.png         wheels at rest: gate notch under the wheel's feeler
#   feeler0..3.png        feelers resting on their rims
#   fence.png, bolt.png   fence bar (with stud) and bolt, locked pose
#   dial20/30/40.png      dial with 20 / 30 / 40 divisions, number 0 under the index
#   ref.png               (--passes ref) everything visible, for a side-by-side check
#   layers.json           pixel geometry for the game (spindle point, crops, mm -> px per layer)
# Moving layers are rendered alone (no shadows from other parts baked in, they would turn with the
# layer); the game adds the contact shadows in 2D.
#
# Run (CPU now, final 2x plates on a GPU later):
#   blender -b -P art/blender/plates/dial_safe_plate.py -- \
#       --out-dir game/assets/photoreal_families/dial_safe/photo --res 618x824 --spp 32 --device CPU
#   (final: --res 1236x1648 --spp 256 --device GPU)
import bpy, bmesh, json, math, os, sys
import numpy as np

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
ROOT_DIR = os.path.abspath(os.path.join(BLENDER_DIR, '..', '..'))
sys.path.insert(0, BLENDER_DIR)
from lw_common import *  # noqa: F401,F403  (cyl, box, boolean, put, prism, photo_mat, area_light, ...)
from mathutils import Vector, Matrix

arg = cli()
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'dial_safe', 'photo')))
RES = [int(v) for v in arg('--res', '618x824').split('x')]
SPP = int(arg('--spp', arg('--samples', '32')))
DEVICE = arg('--device', 'CPU').upper()
PASSES = arg('--passes', 'plate,front,wheels,feelers,fence,bolt,dials').split(',')
os.makedirs(OUT_DIR, exist_ok=True)
FONT = os.path.join(ROOT_DIR, 'game', 'assets', 'fonts', 'AtkinsonHyperlegibleNext-wght.ttf')  # OFL, lining figures

# ---------------------------------------------------------------- geometry (mm; X right, Z up, Y into the door)
R = [43.0, 37.0, 31.0, 25.0]            # wheel radii, wheel 0 farthest from the dial
WY = [13.0, 9.0, 5.0, 1.0]              # wheel front faces (depth), 3 mm thick
WT = 3.0
FX = [-22.0, -10.0, 20.5, 9.5]          # feeler x per wheel
FW = 2.6                                # feeler width
NOTCH_W, NOTCH_D = 4.2, 3.2             # gate notch at the rim
FENCE_Z = 47.0                          # underside of the fence bar
BOLT_Z = (57.0, 65.0)
DIAL_R, BEZEL = 17.0, (17.6, 20.6)
DIAL_Y = -6.0                           # dial front face
CASE = (-51.0, 51.0, -64.0, 70.0)
DIST = 425.0
LENS = 150.0


def rim_z(k):
    return math.sqrt(R[k] ** 2 - FX[k] ** 2)


def feeler_angle(k):
    return math.atan2(FX[k], rim_z(k))  # clockwise from 12 o'clock


def rot_y(o, ang, about=(0.0, 0.0)):
    o.data.transform(Matrix.Translation((about[0], 0, about[1])) @ Matrix.Rotation(ang, 4, 'Y') @ Matrix.Translation((-about[0], 0, -about[1])))
    return o


def text_obj(name, s, size, y, z, ang):
    """Raised numeral on a dial face: in the XZ plane facing the camera, at radius z, turned by ang (cw)."""
    bpy.ops.object.text_add(location=(0, 0, 0))
    t = bpy.context.object; t.name = name
    t.data.body = s
    if os.path.exists(FONT):
        t.data.font = bpy.data.fonts.load(FONT, check_existing=True)
    t.data.size = size; t.data.align_x = 'CENTER'; t.data.align_y = 'CENTER'; t.data.extrude = 0.08
    bpy.ops.object.convert(target='MESH')
    t = bpy.context.object
    t.data.transform(Matrix.Rotation(math.pi / 2, 4, 'X'))
    t.data.transform(Matrix.Translation((0, y, z)))
    rot_y(t, ang)
    return t


def join(objs, name):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.object; o.name = name
    return o


# ---------------------------------------------------------------- materials (photo PBR, art/textures/photo)
M = {
    'case':   photo_mat('ph_case', 'steel_cast_grey_paint', scale=120, metallic=0.0, base=(0.20, 0.21, 0.20), base_mix=0.35, rough_add=0.05, bump=0.3, grime=0.6, wear=0.3),
    'back':   photo_mat('ph_back', 'steel_cast_grey_paint', scale=160, offset=(40, 0, 25), metallic=0.0, base=(0.13, 0.135, 0.13), base_mix=0.45, rough_add=0.08, bump=0.3, grime=0.8),
    # wheels: the turned (radial) brass photo, centred on the spindle, so the finish is rotation-invariant
    # (a rotating layer never carries a directional streak round with it)
    'brass':  photo_mat('ph_wheel_brass', 'brass_turned', scale=92, flat=True, base=(0.80, 0.60, 0.32), base_mix=0.4, rough_add=0.06, bump=0.12, wear=0.2, grime=0.5),
    'nickel': photo_mat('ph_wheel_nickel', 'brass_turned', scale=92, flat=True, base=(0.62, 0.62, 0.60), base_mix=0.75, rough_add=0.04, bump=0.12, wear=0.2, grime=0.5),
    'steel':  photo_mat('ph_steel', 'steel_ground', scale=36, rot=0, base=(0.55, 0.56, 0.57), base_mix=0.4, rough_add=0.06, bump=0.15, grime=0.4),
    'bolt':   photo_mat('ph_bolt', 'steel_ground', scale=48, rot=0, base=(0.42, 0.42, 0.43), base_mix=0.5, rough_add=0.10, bump=0.2, wear=0.6, grime=0.7),
    'door':   photo_mat('ph_door', 'wall_oil_paint_green', scale=220, metallic=0.0, base=(0.08, 0.14, 0.10), base_mix=0.35, rough_add=0.0, coat=0.25, bump=0.25, wear=0.3, grime=0.4),
    'cut':    photo_mat('ph_door_cut', 'steel_ground', scale=30, rot=60, base=(0.45, 0.45, 0.46), base_mix=0.45, rough_add=0.18, bump=0.3, grime=0.3),
    'dial':   photo_mat('ph_dial', 'steel_cast_grey_paint', scale=60, metallic=0.0, base=(0.025, 0.025, 0.028), base_mix=0.7, rough_add=-0.05, coat=0.4, bump=0.1, wear=0.2),
    'bone':   dark_mat('dial_ivory', (0.86, 0.82, 0.72), 0.45),
    'knurl':  photo_mat('ph_knurl', 'nickel_satin', scale=20, rot=90, base=(0.58, 0.58, 0.57), base_mix=0.3, rough_add=0.08, wear=0.5, grime=0.6),
}

objs = {'back': [], 'front': [], 'moving': {}}

# ---------------------------------------------------------------- case (static, back)
x0, x1, z0, z1 = CASE
bp = box('backplate', x0, x1, 20.0, 24.0, z0, z1); put(bp, M['back'], 0.3, 2); objs['back'].append(bp)
walls = box('walls', x0, x1, -2.0, 20.0, z0, z1)
boolean(walls, box('wi', x0 + 3.2, x1 - 3.2, -5, 25, z0 + 3.2, z1 - 3.2))
boolean(walls, box('boltslot', x1 - 6, x1 + 6, 2.0, 12.0, BOLT_Z[0] - 0.6, BOLT_Z[1] + 0.6))
put(walls, M['case'], 0.4, 3); objs['back'].append(walls)
# spindle tube from the back plate and its boss
boss = cyl('boss', 6.5, 4.0, (0, 18.0, 0), axis='Y'); put(boss, M['case'], 0.3, 2); objs['back'].append(boss)
tube = cyl('tube', 3.2, 22.0, (0, 8.0, 0), axis='Y'); put(tube, M['steel'], 0.1, 2); objs['back'].append(tube)
# bolt guides (staples) and fence-bar guide posts
for gx in (-30.0, 30.0):
    st = box('staple', gx - 4, gx + 4, 3.0, 20.0, BOLT_Z[0] - 3, BOLT_Z[1] + 3)
    boolean(st, box('sti', gx - 5, gx + 5, 1.0, 16.0, BOLT_Z[0] - 0.4, BOLT_Z[1] + 0.4)); put(st, M['case'], 0.3, 2); objs['back'].append(st)
for px in (-30.0, 30.0):
    post = cyl('post', 1.6, 18.0, (px, 10.0, FENCE_Z + 2.5), axis='Y'); put(post, M['steel'], 0.1, 2); objs['back'].append(post)
for (rx, rz) in [(x0 + 7, z0 + 7), (x1 - 7, z0 + 7), (x0 + 7, z1 - 7), (x1 - 7, z1 - 7)]:
    objs['back'].append(screw_head('cscrew', (rx, 20.0, rz), 3.0, 1.6, axis='-Y', slot=True, kind='pan', mat=M['case'], rot=0.6))
# lower: relocker plate (static, generic) with two screws
rl = box('relock', -26.0, 26.0, 14.0, 20.0, -58.0, -47.0); put(rl, M['case'], 0.5, 3); objs['back'].append(rl)
for sx in (-20.0, 20.0):
    objs['back'].append(screw_head('rscrew', (sx, 14.0, -52.5), 2.2, 1.2, axis='-Y', slot=True, kind='pan', mat=M['steel'], rot=0.3 + sx))

# ---------------------------------------------------------------- wheels (moving, rest: gate under the feeler)
for k in range(4):
    w = cyl('wheel%d' % k, R[k], WT, (0, WY[k] + WT / 2, 0), axis='Y', verts=192)
    boolean(w, cyl('hub', 3.8, 10, (0, WY[k] + 1.5, 0), axis='Y', verts=48))
    # lightening holes (the wheel behind shows through) and a stepped face ring
    for j in range(3):
        a = math.radians(60 + 120 * j); rr = R[k] * 0.58
        boolean(w, cyl('lh', R[k] * 0.13, 10, (rr * math.sin(a), WY[k] + 1.5, rr * math.cos(a)), axis='Y', verts=48))
    notch = box('notch', -NOTCH_W / 2, NOTCH_W / 2, WY[k] - 2, WY[k] + WT + 2, R[k] - NOTCH_D, R[k] + 2)
    rot_y(notch, feeler_angle(k)); boolean(w, notch)
    put(w, M['brass'] if k % 2 == 0 else M['nickel'], 0.25, 2)
    # drive pin (fly) on the face: shows the turn even far from the gate
    a = feeler_angle(k) + math.pi * 0.85
    fly = cyl('fly%d' % k, 1.3, 2.2, (R[k] * 0.82 * math.sin(a), WY[k] - 1.0, R[k] * 0.82 * math.cos(a)), axis='Y', verts=32)
    put(fly, M['steel'], 0.15, 2)
    objs['moving']['wheel%d' % k] = [w, fly]

# ---------------------------------------------------------------- feelers + fence bar + bolt (moving)
for k in range(4):
    top = FENCE_Z + 2.0
    f = box('feeler%d' % k, FX[k] - FW / 2, FX[k] + FW / 2, WY[k] + 0.4, WY[k] + WT - 0.4, rim_z(k) + 0.02, top)
    put(f, M['steel'], 0.35, 3)
    cap = cyl('fcap%d' % k, 1.6, WT - 0.6, (FX[k], WY[k] + WT / 2, top), axis='Y', verts=32); put(cap, M['steel'], 0.1, 2)
    objs['moving']['feeler%d' % k] = [f, cap]
fence = box('fence', -27.0, 25.0, -1.0, 16.0, FENCE_Z, FENCE_Z + 5.0)
for k in range(4):  # slots the feelers ride in
    boolean(fence, box('fs', FX[k] - FW / 2 - 0.3, FX[k] + FW / 2 + 0.3, WY[k] + 0.2, WY[k] + WT - 0.2, FENCE_Z - 1, FENCE_Z + 4.0))
put(fence, M['bolt'], 0.35, 3)
stud = cyl('stud', 1.6, 6.0, (6.0, 4.0, FENCE_Z + 5.0 + 1.6), axis='Y', verts=32); put(stud, M['steel'], 0.1, 2)
objs['moving']['fence'] = [fence, stud]
bolt = box('bolt', -18.0, 62.0, 2.5, 11.5, BOLT_Z[0], BOLT_Z[1])
boolean(bolt, box('bn', 6.0 - 2.2, 6.0 + 2.2, 0, 14, BOLT_Z[0] - 1, BOLT_Z[0] + 1.9))  # stud notch
put(bolt, M['bolt'], 0.45, 3)
objs['moving']['bolt'] = [bolt]

# ---------------------------------------------------------------- door fragment + bezel (static, front)
door = prism('door', [(x0 - 30, z0 - 30), (x1 + 30, z0 - 30), (x1 + 30, -46.0), (14.0, -60.0), (-24.0, -40.0), (-36.0, -8.0), (x0 - 30, 6.0)], -16.0, -4.0)
put(door, M['door'], 0.4, 3); objs['front'].append(door)
# bare cut face: a thin strip along the cut edge, a little proud
cutpts = [(x1 + 30, -46.0), (14.0, -60.0), (-24.0, -40.0), (-36.0, -8.0), (x0 - 30, 6.0)]
for (ax, az), (bx, bz) in zip(cutpts, cutpts[1:]):
    dx, dz = bx - ax, bz - az; L = math.hypot(dx, dz); nx, nz = -dz / L, dx / L
    strip = prism('cutface', [(ax, az), (bx, bz), (bx - nx * 1.4, bz - nz * 1.4), (ax - nx * 1.4, az - nz * 1.4)], -16.3, -3.8)
    put(strip, M['cut'], 0.15, 2); objs['front'].append(strip)
bez = cyl('bezel', BEZEL[1], 3.0, (0, DIAL_Y + 3.5, 0), axis='Y', verts=160)
boolean(bez, cyl('bzi', BEZEL[0], 10, (0, DIAL_Y + 3.5, 0), axis='Y', verts=160)); put(bez, M['knurl'], 0.3, 2); objs['front'].append(bez)
idx = prism('index', [(-1.1, BEZEL[1] - 0.2), (1.1, BEZEL[1] - 0.2), (0.0, BEZEL[0] + 0.3)], DIAL_Y + 1.9, DIAL_Y + 2.05)
put(idx, M['bone']); objs['front'].append(idx)
arm = box('bezel_arm', -2.0, 2.0, DIAL_Y + 2.0, -2.0, BEZEL[1] - 1.0, 30.0)  # holds the bezel to the door (top)
put(arm, M['knurl'], 0.3, 2); objs['front'].append(arm)

# ---------------------------------------------------------------- dials (moving; three numberings)
def make_dial(div):
    parts = []
    d = cyl('dial%d' % div, DIAL_R, 4.0, (0, DIAL_Y + 2.0, 0), axis='Y', verts=180)
    for j in range(60):  # knurled grip notches on the rim
        a = 2 * math.pi * j / 60
        boolean(d, rot_y(box('kn', -0.45, 0.45, DIAL_Y - 1, DIAL_Y + 5, DIAL_R - 0.5, DIAL_R + 1), a))
    put(d, M['knurl'], 0.15, 2); parts.append(d)
    face = cyl('dface%d' % div, DIAL_R - 1.3, 0.6, (0, DIAL_Y - 0.25, 0), axis='Y', verts=180); put(face, M['dial'], 0.1, 2); parts.append(face)
    cap = cyl('dcap%d' % div, 4.6, 2.4, (0, DIAL_Y - 1.6, 0), axis='Y', verts=96); put(cap, M['knurl'], 0.4, 3); parts.append(cap)
    step = max(1, div // 10)
    for n in range(div):
        a = -2 * math.pi * n / div  # numbers increase counter-clockwise: turning right brings higher ones up
        major = n % step == 0
        tick = box('tick', -0.22 if major else -0.14, 0.22 if major else 0.14, DIAL_Y - 0.62, DIAL_Y - 0.5, 14.0 if major else 14.6, 15.4)
        put(rot_y(tick, a), M['bone']); parts.append(tick)
        if major:
            parts.append(put(text_obj('num', str(n), 3.4, DIAL_Y - 0.62, 10.9, a), M['bone']))
    return parts

for div in (20, 30, 40):
    objs['moving']['dial%d' % div] = make_dial(div)

# ---------------------------------------------------------------- light + camera (axis = optical axis)
world_hdri(0.05, sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 8, 0)
area_light('key', (-120, -230, 170), AIM, 70, 300000, (1.0, 0.84, 0.66))
area_light('fill', (170, -220, -40), AIM, 110, 9000, (0.9, 0.94, 1.0))
area_light('rim', (40, -40, 200), AIM, 60, 4000, (1.0, 0.92, 0.82))
cd = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cd); scene.collection.objects.link(cam); scene.camera = cam
cd.lens = LENS; cd.sensor_fit = 'HORIZONTAL'; cd.sensor_width = 36.0; cd.clip_start = 1; cd.clip_end = 5000
cam.location = (0, -DIST, 0); cam.rotation_euler = (math.pi / 2, 0, 0)
render_setup(os.path.join(OUT_DIR, 'ref.png'), RES, SPP, exposure=float(arg('--exp', '0.5')))
scene.cycles.device = 'GPU' if DEVICE == 'GPU' else 'CPU'
if DEVICE == 'GPU':
    try:
        enable = __import__('plate_common').enable_gpu_cycles
        enable()
    except Exception as e:  # noqa: BLE001
        print('GPU setup failed, CPU:', e)
scene.render.image_settings.color_mode = 'RGBA'
scene.render.image_settings.color_depth = '8'


# ---------------------------------------------------------------- passes
def all_moving():
    return [o for lst in objs['moving'].values() for o in lst]


def set_vis(o, cam_on, shadow_on=True, hidden=False):
    o.hide_render = hidden
    o.visible_camera = cam_on
    o.visible_shadow = shadow_on


def px_per_mm(depth):
    f_px = LENS / 36.0 * RES[0]
    return f_px / (DIST + depth)


def to_px(x, z, depth):
    s = px_per_mm(depth)
    return [RES[0] / 2 + x * s, RES[1] / 2 - z * s]


meta = {'family': 'dial_safe', 'res': RES, 'spp': SPP, 'device': DEVICE, 'spindle_px': [RES[0] / 2, RES[1] / 2],
        'wheels': [], 'feelers': [], 'layers': {}, 'notch_depth_mm': NOTCH_D, 'divisions': [20, 30, 40]}
for k in range(4):
    meta['wheels'].append({'radius_mm': R[k], 'depth_mm': WY[k], 'px_per_mm': px_per_mm(WY[k]), 'notch_angle_deg': math.degrees(feeler_angle(k))})
    meta['feelers'].append({'x_mm': FX[k], 'tip_mm': rim_z(k), 'px_per_mm': px_per_mm(WY[k] + 1.5), 'tip_px': to_px(FX[k], rim_z(k), WY[k] + 1.5)})
meta['fence'] = {'px_per_mm': px_per_mm(7.5), 'stud_px': to_px(6.0, FENCE_Z + 6.6, 4.0)}
meta['bolt'] = {'px_per_mm': px_per_mm(7.0), 'throw_mm': 14.0}
meta['dial'] = {'px_per_mm': px_per_mm(DIAL_Y), 'radius_mm': DIAL_R}
meta['index_px'] = to_px(0.0, BEZEL[1], DIAL_Y)


def crop_save(tmp, name, rgba=True):
    img = bpy.data.images.load(tmp, check_existing=False)
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(a); a = a.reshape(h, w, 4)[::-1]  # top row first
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


def render_pass(name, show, back_cam=False, front_cam=False, transparent=True):
    for o in objs['back']:
        set_vis(o, back_cam, shadow_on=not transparent)
    for o in objs['front']:
        set_vis(o, front_cam, shadow_on=(not transparent) or front_cam)
    for o in all_moving():
        set_vis(o, False, hidden=True)
    for o in show:
        set_vis(o, True, shadow_on=True, hidden=False)
    scene.render.film_transparent = transparent
    tmp = os.path.join(OUT_DIR, '_tmp_%s.png' % name)
    scene.render.filepath = tmp
    bpy.ops.render.render(write_still=True)
    crop_save(tmp, name, rgba=transparent)
    os.remove(tmp)


if 'ref' in PASSES:
    for o in objs['back'] + objs['front'] + all_moving():
        set_vis(o, True)
    for div in (30, 40):
        for o in objs['moving']['dial%d' % div]:
            o.hide_render = True
    scene.render.film_transparent = False
    scene.render.filepath = os.path.join(OUT_DIR, 'ref.png')
    bpy.ops.render.render(write_still=True)
if 'plate' in PASSES:
    render_pass('plate', [], back_cam=True, transparent=False)
if 'front' in PASSES:
    render_pass('front', [], front_cam=True)
if 'wheels' in PASSES:
    for k in range(4):
        render_pass('wheel%d' % k, objs['moving']['wheel%d' % k])
if 'feelers' in PASSES:
    for k in range(4):
        render_pass('feeler%d' % k, objs['moving']['feeler%d' % k])
if 'fence' in PASSES:
    render_pass('fence', objs['moving']['fence'])
if 'bolt' in PASSES:
    render_pass('bolt', objs['moving']['bolt'])
if 'dials' in PASSES:
    for div in (20, 30, 40):
        render_pass('dial%d' % div, objs['moving']['dial%d' % div])

mp = os.path.join(OUT_DIR, 'layers.json')
if os.path.exists(mp) and set(PASSES) != set('plate,front,wheels,feelers,fence,bolt,dials'.split(',')):
    old = json.load(open(mp))
    old_layers = old.get('layers', {}); old_layers.update(meta['layers']); meta['layers'] = old_layers
json.dump(meta, open(mp, 'w'), indent=1)
print('DONE', OUT_DIR)
