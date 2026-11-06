# Lockwright — GPU plate + matcap + normal/ORM + GLB generator for `lever` (and `lever_detector`) family.
# Based on art/blender/lever.py, game/assets/photoreal/tools/render_plate.py, and spikes/lit-metal/tools/bake.py.
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
LEVER_COUNT = int(arg('--levers', '3'))
if LEVER_COUNT not in (3, 5):
    raise ValueError('--levers must be 3 or 5')
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'lever')))
RES = [int(v) for v in arg('--res', '1236x1650').split('x')]
SAMPLES = int(arg('--samples', '160'))
OPEN = 1

# ---------------------------------------------------------------- materials (T06 satin finish: roughness >= 0.24)
MAT = {
    'case':   paint('japan', (0.022, 0.021, 0.020), rough=0.38, metal_col=(0.42, 0.41, 0.40), chip=0.8, grime=0.7),
    'brass':  metal('lever_brass', (0.78, 0.55, 0.25), float(arg('--br', '0.25')), marks='stamp', marks_scale=0.8, wear=0.9, wear_col=(0.93, 0.74, 0.43), grime=0.8, grime_col=(0.06, 0.045, 0.02), tint_var=0.06, patina=0.4),
    'bolt':   metal('bolt_brass', (0.70, 0.50, 0.24), 0.30, marks='grind', marks_axis=(1, 0, 0), wear=0.8, wear_col=(0.90, 0.70, 0.40), grime=0.9, grime_col=(0.05, 0.04, 0.02), tint_var=0.08),
    'forend': metal('forend', (0.72, 0.52, 0.26), 0.28, marks='grind', marks_axis=(0, 0, 1), wear=0.6, grime=0.9, tint_var=0.1),
    'steel':  metal('stump', (0.46, 0.46, 0.47), 0.26, marks='turn', marks_axis=(0, 1, 0), wear=0.5, grime=0.6),
    'blued':  metal('blued', (0.28, 0.32, 0.40), 0.25, marks='grind', marks_axis=(1, 0, 0), wear=0.7, wear_col=(0.58, 0.58, 0.60), grime=0.3),
    'screw':  metal('screw_br', (0.70, 0.52, 0.28), 0.32, marks='turn', marks_axis=(1, 0, 0), wear=0.4, grime=1.0),
    'wood':   oak('door_oak', light=(0.40, 0.25, 0.12), dark=(0.17, 0.09, 0.04), axis='Z', ring_mm=2.4, lacquer=0.75, rough=0.44, wear=0.5, grime=0.7, seed=1.0),
    'wood2':  oak('jamb_oak', light=(0.36, 0.22, 0.10), dark=(0.15, 0.08, 0.035), axis='Z', ring_mm=1.8, lacquer=0.7, rough=0.46, wear=0.6, grime=0.8, seed=5.0),
    'paint':  paint('door_paint', (0.30, 0.20, 0.12), rough=0.5, metal_col=(0.36, 0.22, 0.11), chip=0.5),
    'pick':   metal('crank', (0.60, 0.60, 0.61), 0.24, aniso=0.6, marks='grind', marks_axis=(1, 0, 0), wear=0.3, grime=0.1),
    'wire':   metal('lifter', (0.62, 0.62, 0.63), 0.24, marks='turn', marks_axis=(0, 1, 0), wear=0.2, grime=0.1),
    'dark':   dark_mat('cavity', (0.012, 0.011, 0.010), 0.9),
}

# ---------------------------------------------------------------- layout (cover side y = 0, back plate at y = 14)
PIV = Vector((-22.0, 0.0, 4.0))
STUMP_X, STUMP_R = 7.7, 2.2
# Canonical rest pose: lift == need so at rest (delta_lift = 0), every lever's true gate is level with the stump (z = 0)
LEVERS = [  # (y0, needed lift, rest lift, belly z)
    (0.9, 3.5, 3.5, -11.2),
    (4.1, 2.5, 2.5, -12.0),
    (7.3, 3.0, 3.0, -11.6),
]
LT = 1.25
BACK_Y = 14.0
BOLT_Y = 9.0
CAM_Y = 6.0
if LEVER_COUNT == 5:
    from lever_layout import detector_levers
    LEVERS = detector_levers()
    BACK_Y, BOLT_Y, CAM_Y = 33.0, 28.0, 15.5
CUT_Y = BACK_Y + 6.0


def lever_outline(belly):
    pts = [(PIV.x, PIV.z - 5.0), (-14, -4.5), (-9.5, belly + 0.8), (-8.5, belly), (1.5, belly), (3.0, belly + 1.0),
           (12.0, -10.5), (15.2, -9.8), (16.0, -8.6), (16.0, 10.8), (15.0, 12.0), (-6, 13.2), (PIV.x, PIV.z + 5.0)] + [
        (PIV.x - 5.0 * math.sin(math.radians(k * 15)), PIV.z + 5.0 * math.cos(math.radians(k * 15))) for k in range(1, 12)]
    return pts

def make_lever(i, y0, need, lift, belly):
    o = prism('lever%d' % i, lever_outline(belly), y0, y0 + LT)
    gz = -need  # gate centre in lever coords (stump at z = 0 when lifted by `need`)
    boolean(o, box('pocketA', STUMP_X + 0.3 - 2.6, 20.0 if OPEN else STUMP_X + 0.3 + 2.6, -5, CUT_Y, -9.0, 2.7))
    boolean(o, box('pocketB', -6.6, -1.4, -5, CUT_Y, -9.0, 2.7))
    # True gate channel
    boolean(o, box('gate', -2.0, STUMP_X, -5, CUT_Y, gz - 2.45, gz + 2.45))
    # Anti-pick false gate notch cut into the upper gating tooth (catches stump when delta_lift = -2.2 mm)
    boolean(o, box('fgate_hi', STUMP_X - 1.35, STUMP_X + 0.6, -5, CUT_Y, gz + 3.05, gz + 5.15))
    # Secondary false notch on the lower tooth
    boolean(o, box('fgate_lo', STUMP_X - 1.25, STUMP_X + 0.6, -5, CUT_Y, gz - 5.05, gz - 3.10))
    boolean(o, cyl('pivh', 2.08, 2 * CUT_Y, (PIV.x, 0, PIV.z), axis='Y', verts=48))
    boolean(o, cyl('lh', 2.2, 2 * CUT_Y, (-13.0, 0, 6.5), axis='Y', verts=48))
    ang = lift / (STUMP_X - PIV.x)
    o.matrix_world = Matrix.Translation(PIV) @ Matrix.Rotation(-ang, 4, 'Y') @ Matrix.Translation(-PIV)
    put(o, MAT['brass'], 0.18, 3)

    M_ = o.matrix_world
    a = M_ @ Vector((-12.0, 0, 12.6)); tip = Vector((8.0, 0, 27.6))
    mid1 = M_ @ Vector((-6.0, 0, 13.6))
    path = [(a.x, a.z + 0.1), (mid1.x, mid1.z + 0.5), ((mid1.x + tip.x) / 2, (mid1.z + tip.z) / 2 + 2.6), (tip.x - 2.5, tip.z - 0.4), (tip.x, tip.z)]
    sp = flat_tool('spring%d' % i, path, 0.55, LT - 0.3, y0 + LT / 2, tip='round'); sp.data.materials[0] = MAT['blued']
    rv = M_ @ Vector((-11.0, 0, 12.4))
    screw_head('rivet%d' % i, (rv.x, y0 - 0.02, rv.z + 0.4), 1.0, 0.55, axis='-Y', slot=False, kind='dome', mat=MAT['steel'])
    for k in range(i + 1):
        d = M_ @ Vector((-17.5 + k * 1.3, 0, 9.2))
        dot = cyl('punch', 0.32, 0.3, (d.x, y0 - 0.05, d.z), axis='Y', verts=16); boolean(o, dot)
    return o

levers = [make_lever(i, *L) for i, L in enumerate(LEVERS)]
for i in range(len(LEVERS)):
    y0 = LEVERS[i][0] + LT
    y1 = LEVERS[i + 1][0] if i + 1 < len(LEVERS) else BOLT_Y
    w = lathe_x(f'spacer{i}', [(0, 2.05), (0, 3.4), (y1 - y0, 3.4), (y1 - y0, 2.05)], seg=64)
    w.data.transform(Matrix.Rotation(math.pi / 2, 4, 'Z')); w.location = (PIV.x, y0, PIV.z); put(w, MAT['bolt'], 0.08, 2)
post = cyl('post', 2.0, BACK_Y - 0.6, (PIV.x, (BACK_Y + 0.6) / 2, PIV.z), axis='Y', verts=48); put(post, MAT['steel'], 0.05)
screw_head('post_head', (PIV.x, 0.62, PIV.z), 2.9, 0.75, axis='-Y', slot=False, kind='dome', mat=MAT['steel'])

# ---------------------------------------------------------------- bolt (cast brass) with steel stump, talon, and detector notch
bolt = box('bolt', -9.0, 38.0, BOLT_Y, BOLT_Y + 4.6, -6.5, 6.5)
boolean(bolt, box('talon', -1.0, 3.2, 0, CUT_Y, -7, -4.2))
boolean(bolt, box('tail_slot', -9.5, -4.0, 0, CUT_Y, -2.0, 2.0))
boolean(bolt, box('relief', 30, 40, 0, CUT_Y, 5.2, 7))
# Detector catch notch on top of bolt tail (engaged when detector pawl trips)
boolean(bolt, box('det_notch', 9.6, 13.2, BOLT_Y - 1.0, BOLT_Y + 5.5, 4.2, 7.0))
put(bolt, MAT['bolt'], 0.35, 3)

stump = cyl('stump', STUMP_R, BOLT_Y - 0.3, (STUMP_X, (BOLT_Y + 0.3) / 2, 0.0), axis='Y', verts=64); put(stump, MAT['steel'], 0.12, 2)
screw_head('stud', (-6.6, BOLT_Y, 0), 1.7, 0.6, axis='-Y', slot=False, kind='dome', mat=MAT['steel'])
put(cyl('stud_post', 1.8, 5.2, (-6.6, BOLT_Y + 2.4, 0), axis='Y', verts=32), MAT['steel'], 0.05)

# Always build the Chubb-style detector pawl (`detector` node) for `lever_detector`
det = prism('detector', [(9.8, 4.2), (16.5, 4.8), (16.5, 8.4), (13.8, 10.2), (9.8, 9.8)], BOLT_Y - 0.85, BOLT_Y - 0.05)
det.matrix_world = levers[-1].matrix_world.copy()
put(det, MAT['blued'], 0.1)

# ---------------------------------------------------------------- case: back plate + flanges (black japanned steel)
CX0, CX1, CZ0, CZ1, FL = -30.0, 26.0, -30.0, 30.0, 1.5
back = box('back', CX0, CX1, BACK_Y, BACK_Y + FL, CZ0, CZ1)
kh = cyl('kh', 3.3, 10, (-3.0, BACK_Y, -18.0), axis='Y', verts=64); boolean(kh, box('khs', -4.6, -1.4, BACK_Y - 5, BACK_Y + 5, -25.5, -18), 'UNION')
boolean(back, kh); put(back, MAT['case'], 0.3, 3)
top = box('top', CX0, CX1, 0.0, BACK_Y, CZ1 - FL, CZ1); put(top, MAT['case'], 0.3, 3)
bot = box('bottom', CX0, CX1, 0.0, BACK_Y, CZ0, CZ0 + FL); put(bot, MAT['case'], 0.3, 3)
rear = box('rearwall', CX0, CX0 + FL, 0.0, BACK_Y, CZ0, CZ1); put(rear, MAT['case'], 0.3, 3)

for idx, (px, pz) in enumerate([(-25.5, 24.5), (-25.5, -24.5), (20.5, -24.5), (21.0, 23.0)]):
    p = cyl(f'boss{idx}', 2.4, BACK_Y - 0.4, (px, (BACK_Y + 0.4) / 2, pz), axis='Y', verts=48)
    boolean(p, cyl('tap', 1.0, 30, (px, 0, pz), axis='Y', verts=24)); put(p, MAT['screw'], 0.15, 2)
gb = box('guide', 18.0, 26.0, 0.0, BOLT_Y, 6.6, 8.0); put(gb, MAT['case'], 0.2, 2)
gb2 = box('guide2', 18.0, 26.0, 0.0, BOLT_Y, -8.0, -6.6); put(gb2, MAT['case'], 0.2, 2)

fe = box('forend', CX1, CX1 + 3.0, -3.5, BACK_Y + FL + 3.5, -46, 46)
boolean(fe, box('fehole', CX1 - 1, CX1 + 4, BOLT_Y - 0.2, BOLT_Y + 4.8, -6.7, 6.7)); put(fe, MAT['forend'], 0.4, 3)
for idx, zz in enumerate((-40.0, 40.0)):
    s = screw_head(f'fscrew{idx}', (CX1 + 3.0, BACK_Y / 2, zz), 3.4, 1.0, axis='X', slot=True, kind='pan', mat=None, rot=math.radians(30 if zz > 0 else 75)); put(s, MAT['screw'], 0.05, 2)

# ---------------------------------------------------------------- door stile & jamb
stile = box('stile', -90, CX1, -6.0, max(40.0, BACK_Y + 24.0), -120, 120)
boolean(stile, box('mortise', CX0 - 0.4, CX1 + 1, -0.0, BACK_Y + FL + 0.3, CZ0 - 0.4, CZ1 + 0.4))
boolean(stile, box('cutfront', -100, CX1 + 10, -20, 0.0, -130, 130))
put(stile, MAT['wood'], 0.4, 3)
jamb = box('jamb', CX1 + 4.2, 120, 0.0, 60, -120, 120)
boolean(jamb, box('strike_pocket', CX1 + 3, CX1 + 18, BOLT_Y - 1.0, BOLT_Y + 5.4, -7.6, 7.6)); put(jamb, MAT['wood2'], 0.4, 3)
sk = box('strike', CX1 + 4.2, CX1 + 6.0, -3.0, BACK_Y + 5, -30, 30)
boolean(sk, box('skh', CX1 + 3, CX1 + 7, BOLT_Y - 0.6, BOLT_Y + 5.2, -7.2, 7.2)); boolean(sk, box('cutfront2', CX1, CX1 + 8, -10, 0.0, -40, 40))
put(sk, MAT['forend'], 0.3, 3)
put(box('strike_dark', CX1 + 9, CX1 + 18.5, BOLT_Y - 2.0, BOLT_Y + 6.4, -8, 8), MAT['dark'])

# ---------------------------------------------------------------- tools through the back keyhole
belly1 = levers[0].matrix_world @ Vector((-3.5, 0, LEVERS[0][3]))
lp = [Vector((-3.0, BACK_Y + 26.0, -16.6)), Vector((-3.0, 2.9, -16.6)), Vector((-3.0, 1.7, -15.6)), Vector((-3.2, 1.7, belly1.z - 0.7))]
cu = bpy.data.curves.new('lifter', 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = 0.65; cu.bevel_resolution = 4
sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(lp) - 1)
for bp, p in zip(sp.bezier_points, lp):
    bp.co = p; bp.handle_left_type = bp.handle_right_type = 'AUTO'
lo = bpy.data.objects.new('lifter', cu); bpy.context.collection.objects.link(lo); cu.materials.append(MAT['wire'])

ta = flat_tool('tension', [(-3.0, -24.5), (-3.0, -12.0), (-1.6, -8.4), (0.4, -6.0), (0.6, -5.0)], 1.6, 0.9, BOLT_Y + 2.2, tip='flat')
ta.data.materials[0] = MAT['pick']
tb = box('tension_shaft', -3.8, -2.2, BOLT_Y + 2.2, BACK_Y + 46.0, -25.4, -23.6); put(tb, MAT['pick'], 0.3)

# ---------------------------------------------------------------- light + camera
world_hdri(float(arg('--world', '0.05')), sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (-2, CAM_Y, 0)
kx, ky, kz, ks, ke = [float(v) for v in arg('--key', '-90,-110,140,44,155000').split(',')]
area_light('key', (kx, ky, kz), AIM, ks, ke, (1.0, 0.84, 0.66))
area_light('fill', (140, -110, -20), AIM, 90, float(arg('--fill', '30000')), (0.94, 0.96, 1.0))
area_light('rim', (40, -20, -130), AIM, 40, float(arg('--rim', '24000')), (1.0, 0.95, 0.9))
area_light('kick', tuple(float(v) for v in arg('--kpos', '110,-90,-30').split(',')), AIM, 28, float(arg('--kick', '28000')), (1.0, 0.95, 0.88))
target_pt = (float(arg('--tx', '1')), CAM_Y, float(arg('--tz', '-2')))
cam = look_camera(target_pt, float(arg('--yaw', '40')), float(arg('--pitch', '-18')), float(arg('--dist', '160')), lens=float(arg('--lens', '120')))
mirror_softbox('sheen', (0, 0, 0), cam, size=float(arg('--ss', '36')), size_y=float(arg('--ssy', '80')), energy=float(arg('--sheen', '9500')), shift=(float(arg('--sx', '-6')), 0, float(arg('--sz', '4'))))
render_setup(os.path.join(OUT_DIR, 'plate', 'plate_1236x1650.png'), RES, SAMPLES, exposure=0.0)

MOVING = [
    *[f'{prefix}{i}' for prefix in ('lever', 'spring', 'rivet') for i in range(LEVER_COUNT)],
    'detector',
    'stump',
    'lifter', 'tension', 'tension_shaft',
]
EXTRA = {
    'pivot': [PIV.x, PIV.z, -PIV.y],
    'stump_x': STUMP_X,
    'stump_r': STUMP_R,
    'lever_specs': [
        {'y0': L[0], 'need': L[1], 'rest_lift': L[2], 'belly_z': L[3]}
        for L in LEVERS
    ],
    'detector_pivot': [10.2, 5.8, -(BOLT_Y - 0.45)],
    'keyhole_pivot': [-3.0, -18.0, -(BOLT_Y + 2.2)],
}

P.run_family_pipeline(
    family_name='lever_detector' if LEVER_COUNT == 5 else 'lever',
    out_dir=OUT_DIR,
    moving_names=MOVING,
    camera_target=target_pt,
    matcap_centre=(2.0, 2.0, 0.0),
    extra_meta=EXTRA,
    plate_res=tuple(RES),
    plate_samples=SAMPLES,
    tex_size=1024,
    ao_samples=32,
)
