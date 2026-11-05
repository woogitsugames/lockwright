# Lockwright — GPU plate + matcap + normal/ORM + GLB generator for `wafer` family.
# Based on art/blender/wafer.py, game/assets/photoreal/tools/render_plate.py, and spikes/lit-metal/tools/bake.py.
import bpy, bmesh, math, sys, os

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, ".."))
ROOT_DIR = os.path.abspath(os.path.join(THIS_DIR, "..", "..", ".."))
for p in (THIS_DIR, BLENDER_DIR):
    if p not in sys.path:
        sys.path.insert(0, p)

from lw_common import *
import plate_common as P
from mathutils import Vector, Matrix

arg = cli()
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'wafer')))
RES = [int(v) for v in arg('--res', '1236x1650').split('x')]
SAMPLES = int(arg('--samples', '160'))

# ---------------------------------------------------------------- materials (T06 satin finish: roughness >= 0.24)
MAT = {
    'zamak':     metal('zamak', (0.54, 0.53, 0.50), 0.32, aniso=0.5, marks='mill', marks_amt=1.1, wear=0.45, grime=0.8),
    'zamak_o':   metal('zamak_o', (0.61, 0.60, 0.57), 0.34, marks='turn', marks_axis=(1, 0, 0), marks_scale=1.6, wear=0.6, grime=0.7),
    'brass':     metal('brass2', (0.74, 0.50, 0.21), float(arg('--br', '0.26')), aniso=0.45, marks='mill', marks_amt=1.05, wear=0.5, wear_col=(0.92, 0.72, 0.40), grime=0.65),
    'wafer':     metal('wafer', (0.42, 0.43, 0.45), 0.26, marks='stamp', marks_scale=1.0, wear=0.7, wear_col=(0.66, 0.66, 0.67), grime=0.45, bevel_r=0.03),
    'spring':    metal('spring2', (0.56, 0.56, 0.57), 0.26, marks=None, wear=0.0, grime=0.3, bevel_r=0.0),
    'zinc':      metal('zinc', (0.66, 0.67, 0.70), 0.32, marks='stamp', marks_scale=0.5, wear=0.5, grime=0.6, tint_var=0.08),
    'cam':       metal('cam', (0.46, 0.46, 0.47), 0.34, marks='stamp', wear=0.8, wear_col=(0.62, 0.62, 0.62), grime=0.6),
    'paint':     paint('powder', (0.105, 0.135, 0.115), rough=0.48, chip=0.7),
    'paint_cut': metal('sheet_cut', (0.55, 0.55, 0.55), 0.34, marks='grind', marks_axis=(0, 0, 1), wear=0.0, grime=0.4),
    'pick':      metal('pick2', (0.62, 0.62, 0.63), 0.24, aniso=0.65, marks='grind', marks_axis=(1, 0, 0), wear=0.3, grime=0.1),
    'wrench':    metal('wrench2', (0.42, 0.42, 0.43), 0.30, marks='grind', marks_axis=(1, 0, 0), wear=0.6, grime=0.2),
    'handle':    dark_mat('handle2', (0.05, 0.05, 0.055), 0.6),
    'back':      dark_mat('back2', (0.012, 0.012, 0.013), 0.9),
}

# ---------------------------------------------------------------- dimensions (cut plane y = 0, keep y >= 0)
R_P, R_B, R_H = 7.0, 7.12, 11.0
T, PITCH = 2.4, 5.0
WX = [7.0 + PITCH * i for i in range(5)]
W_HALF_Y = 3.6
WIN = (-2.0, 2.0, -5.0, 1.6)
NOTCH_Y, NOTCH_Z = 1.25, 2.6
BRIDGE_Z = 6.2
KEYWAY = (-4.8, 3.2)
PC, HC = 0.15, 0.25
L_H = 31.0
# Canonical neutral rest pose (dz = 0, tilt = 0, sx = 0) so Godot WaferPose drives all motion cleanly
STATE = [('set', 0.0, 0.0, 0.0) for _ in range(5)]

def cut_half(o, x0=-80, x1=120):
    boolean(o, box('cut', x0, x1, -60, 0, -80, 80))

# ---------------------------------------------------------------- housing: flange + threaded body + rear shoulder
prof = [(-2.6, 7.6), (-2.6, 12.6), (-2.3, 13.2), (-0.25, 13.2), (0.0, 12.9), (0.0, R_H - 0.7)]
prof += sawtooth(1.2, 27.0, R_H - 0.7, R_H, 1.0)
prof += [(27.6, R_H - 0.7), (27.6, R_H - 1.0), (L_H - 0.4, R_H - 1.0), (L_H, R_H - 1.4), (L_H, 7.6)]
house = lathe_x('housing', prof, seg=160)
boolean(house, lathe_x('bore', [(-5, R_B), (L_H + 3, R_B)], seg=160))
for x in WX:
    w = T / 2 + HC
    boolean(house, box('hs_top', x - w, x + w, -W_HALF_Y - 0.2, W_HALF_Y + 0.2, 5.0, 8.9))
    boolean(house, box('hs_bot', x - w, x + w, -W_HALF_Y - 0.2, W_HALF_Y + 0.2, -9.0, -5.0))
cut_half(house); put(house, MAT['zamak'], 0.07, 2)

# ---------------------------------------------------------------- plug (brass) with keyway, wafer slots, tail
plug = lathe_x('plug', [(-2.25, 5.6), (-2.25, 6.85), (-2.1, R_P), (L_H + 0.4, R_P), (L_H + 0.4, 4.2), (L_H + 3.4, 4.2), (L_H + 3.4, 3.6)], seg=160)
boolean(plug, box('kw', -5, 29.3, -1.1, 1.1, KEYWAY[0], KEYWAY[1]))
boolean(plug, box('kw_ward', -5, 29.3, -1.6, 1.6, -2.2, -0.6))
boolean(plug, box('kw_mouth', -5, -1.4, -1.5, 1.5, KEYWAY[0] - 0.3, KEYWAY[1] + 0.3))
for x in WX:
    boolean(plug, box('ps', x - T / 2 - PC, x + T / 2 + PC, -W_HALF_Y - 0.15, W_HALF_Y + 0.15, -9, 9))
boolean(plug, box('flat', L_H + 0.6, L_H + 4, -9, 9, 3.0, 9)); boolean(plug, box('flat2', L_H + 0.6, L_H + 4, -9, 9, -9, -3.0))
cut_half(plug); put(plug, MAT['brass'], 0.14, 3)

for i, x in enumerate(WX):
    br = box(f'bridge{i}', x - T / 2 - PC, x + T / 2 + PC, -NOTCH_Y - 0.3, NOTCH_Y + 0.3, BRIDGE_Z, 7.4)
    boolean(br, lathe_x('bc', [(x - 3, R_P), (x + 3, R_P)], seg=96), 'INTERSECT'); cut_half(br); put(br, MAT['brass'], 0.1, 2)

# ---------------------------------------------------------------- wafers + springs (canonical rest pose + anti-pick false step)
def wafer(name, x, dz, tilt, sx):
    o = lathe_x(name, [(x - T / 2, R_P - 0.03), (x + T / 2, R_P - 0.03)], seg=128)
    boolean(o, box('wy', x - 3, x + 3, -W_HALF_Y, W_HALF_Y, -9, 9), 'INTERSECT')
    boolean(o, box('win', x - 3, x + 3, WIN[0], WIN[1], WIN[2], WIN[3]))
    boolean(o, box('notch', x - 3, x + 3, -NOTCH_Y, NOTCH_Y, NOTCH_Z, 9))
    # Shallow anti-pick false notches near upper/lower locking shoulders so false_set catches visibly
    boolean(o, box('fn_bot', x - T / 2 - 0.3, x - T / 2 + 0.38, -W_HALF_Y - 0.2, W_HALF_Y + 0.2, -5.85, -5.10))
    boolean(o, box('fn_top', x + T / 2 - 0.38, x + T / 2 + 0.3, -W_HALF_Y - 0.2, W_HALF_Y + 0.2, 5.10, 5.85))
    ch = box('lead', x - 3, x + 3, -0.6, 0.6, WIN[3] - 0.25, WIN[3] + 0.25); ch.rotation_euler = (math.radians(45), 0, 0)
    bpy.context.view_layer.objects.active = ch; bpy.ops.object.transform_apply(rotation=True)
    cut_half(o)
    piv = Vector((x, 0, 0))
    o.matrix_world = Matrix.Translation(Vector((sx, 0, dz))) @ Matrix.Translation(piv) @ Matrix.Rotation(math.radians(tilt), 4, 'Y') @ Matrix.Translation(-piv)
    bpy.data.objects.remove(ch, do_unlink=True)
    return put(o, MAT['wafer'], 0.11, 3)

for i, ((st, dz, tilt, sx), x) in enumerate(zip(STATE, WX)):
    wafer('wafer%d' % i, x, dz, tilt, sx)
    z0 = NOTCH_Z + dz
    sp = spring('wspr%d' % i, x + sx + math.sin(math.radians(tilt)) * NOTCH_Z, z0, BRIDGE_Z, 6, r=0.86, wire=0.18, y=0.0)
    sp.data.materials.clear(); sp.data.materials.append(MAT['spring'])

# ---------------------------------------------------------------- mailbox door & hardware
door = box('door', 0.0, 1.0, 0, 46, -70, 70)
boolean(door, lathe_x('dh', [(-1, R_H + 0.25), (2, R_H + 0.25)], seg=160)); cut_half(door)
put(door, MAT['paint'], 0.18, 2)

nut = cyl('nut', 14.4, 3.6, (1.0 + 1.8 + 0.05, 0, 0), axis='X', verts=6)
nut.rotation_euler = (math.radians(30), 0, 0); bpy.context.view_layer.objects.active = nut; bpy.ops.object.transform_apply(rotation=True)
boolean(nut, lathe_x('ch', [(1.05, 11.4), (1.05, 13.1), (1.9, 14.6), (3.8, 14.6), (4.65, 13.1), (4.65, 11.4)], seg=160), 'INTERSECT')
boolean(nut, lathe_x('nb', [(-1, R_H - 0.62), (8, R_H - 0.62)], seg=160))
cut_half(nut); put(nut, MAT['zinc'], 0.12)

lw = lathe_x('washer', [(1.0, R_H + 0.1), (1.0, 13.4), (1.05, 13.4), (1.05, R_H + 0.1)], seg=160); cut_half(lw); put(lw, MAT['zinc'])

cam_latch = box('cam', L_H + 0.7, L_H + 2.7, 0, 9.5, -31, 4.6)
boolean(cam_latch, box('cam_hole', L_H + 0.5, L_H + 3, -3.2, 3.2, -3.05, 3.05))
put(cam_latch, MAT['cam'], 0.25, 3)
wsh = lathe_x('cwash', [(L_H + 2.75, 2.0), (L_H + 2.75, 5.6), (L_H + 3.25, 5.6), (L_H + 3.25, 2.0)], seg=96); cut_half(wsh); put(wsh, MAT['zinc'], 0.05, 2)
sc = screw_head('cscrew', (L_H + 3.3, 0, 0), 4.0, 2.2, axis='X', slot=False, kind='pan')
sc.modifiers.clear()
for a in (0, 90):
    cr = box('cr', -0.8, 3, -0.55, 0.55, -2.0, 2.0); cr.location = (L_H + 4.6, 0, 0); cr.rotation_euler = (math.radians(a), 0, 0)
    bpy.context.view_layer.objects.active = cr; bpy.ops.object.transform_apply(location=True, rotation=True)
    boolean(sc, cr)
cut_half(sc); put(sc, MAT['zinc'], 0.05, 2)

# ---------------------------------------------------------------- tools: tension wrench + short hook (at canonical rest tip)
PICK_REST_X = 17.0
PICK_REST_TIP = 0.42
hook = [(-55, -3.25), (-20, -3.22), (5, -3.18), (14.4, -3.12), (15.9, -2.6), (16.65, -1.3), (16.95, PICK_REST_TIP)]
flat_tool('pick', hook, 1.0, 0.55, 0.55).data.materials[0] = MAT['pick']
ph = box('pick_handle', -80, -46, 0.05, 2.2, -4.9, -1.6); put(ph, MAT['handle'], 0.6, 4)
wr = [(3.8, -4.28), (-3.0, -4.28), (-4.1, -4.6), (-4.7, -5.6), (-4.8, -7.0), (-4.8, -60)]
flat_tool('wrench', wr, 1.0, 0.75, 0.55, tip='flat').data.materials[0] = MAT['wrench']

put(box('back', -120, 160, 70, 72, -160, 160), paint('inside', (0.07, 0.085, 0.075), rough=0.5, chip=0.0, grime=0.0), 0.0)

# ---------------------------------------------------------------- light + camera (T06: softened sheen so no chrome stripe)
world_hdri(float(arg('--world', '0.04')), sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (16, 0, 0)
kx, ky, kz, ks, ke = [float(v) for v in arg('--key', '-80,-32,100,28,105000').split(',')]
area_light('key', (kx, ky, kz), AIM, ks, ke, (1.0, 0.85, 0.68))
area_light('fill', (115, -95, 10), AIM, 90, float(arg('--fill', '2800')), (0.96, 0.97, 1.0))
area_light('rim', (30, -30, -95), AIM, 30, float(arg('--rim', '13000')), (1.0, 0.95, 0.9))
target_pt = (float(arg('--tx', '16')), 0.0, float(arg('--tz', '-1')))
look_camera(target_pt, float(arg('--yaw', '-30')), float(arg('--pitch', '16')), float(arg('--dist', '60')), lens=float(arg('--lens', '70')))
mirror_softbox('sheen', (16, 0, -2), scene.camera, size=float(arg('--ss', '42')), size_y=float(arg('--ssy', '105')), energy=float(arg('--sheen', '3600')), shift=(float(arg('--sx', '-10')), 0, float(arg('--sz', '6'))))
render_setup(os.path.join(OUT_DIR, 'plate', 'plate_1236x1650.png'), RES, SAMPLES, exposure=0.08)

MOVING = [f'wafer{i}' for i in range(5)] + [f'wspr{i}' for i in range(5)] + ['pick', 'pick_handle']
EXTRA = {
    'wafer_x': WX,
    'plug_r': R_P,
    'bore_r': R_B,
    'notch_z': NOTCH_Z,
    'bridge_z': BRIDGE_Z,
    'win_top': WIN[3],
    'pick_rest_x': PICK_REST_X,
    'pick_rest_tip': PICK_REST_TIP,
    'blender_showcase_states': [
        {'state': 'set', 'dz': 0.0, 'tilt': 0.0, 'sx': 0.0},
        {'state': 'set', 'dz': 0.0, 'tilt': 0.0, 'sx': 0.0},
        {'state': 'bound', 'dz': -0.7, 'tilt': 1.3, 'sx': 0.06},
        {'state': 'overset', 'dz': 1.4, 'tilt': 0.0, 'sx': 0.0},
        {'state': 'free', 'dz': -1.8, 'tilt': 0.0, 'sx': 0.0},
    ],
}

P.run_family_pipeline(
    family_name='wafer',
    out_dir=OUT_DIR,
    moving_names=MOVING,
    camera_target=target_pt,
    matcap_centre=(16.0, -5.0, 0.0),
    extra_meta=EXTRA,
    plate_res=tuple(RES),
    plate_samples=SAMPLES,
    tex_size=1024,
    ao_samples=32,
)
