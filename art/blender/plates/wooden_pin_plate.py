# Lockwright — GPU plate + matcap + normal/ORM + GLB generator for `wooden_pin` family.
# Based on art/blender/wooden_pin.py, game/assets/photoreal/tools/render_plate.py, and spikes/lit-metal/tools/bake.py.
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
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'wooden_pin')))
RES = [int(v) for v in arg('--res', '1236x1650').split('x')]
SAMPLES = int(arg('--samples', '160'))

# ---------------------------------------------------------------- materials (T06 oiled hardwood + satin bronze)
MAT = {
    'housing': oak('housing', light=(0.27, 0.19, 0.12), dark=(0.10, 0.07, 0.045), axis='Z', ring_mm=2.6, lacquer=0.15, rough=0.62, coat_rough=0.35,
                   var=0.1, wear=0.8, grime=1.0, scratches=0.3, warp=1.2, seed=1.0, bump=1.5),
    'bolt':    oak('boltwood', light=(0.58, 0.43, 0.27), dark=(0.30, 0.20, 0.11), axis='X', ring_mm=2.0, lacquer=0.25, rough=0.50, coat_rough=0.30,
                   var=0.1, wear=1.0, grime=0.8, scratches=0.6, warp=0.8, seed=2.0, bump=1.5),
    'pin':     wood('pinwood', light=(0.15, 0.09, 0.05), dark=(0.05, 0.028, 0.016), axis='Z', ring=1.4, rough=0.44, coat=0.15, wear=1.0, grime=0.6, warp=1.5, center=(14, 9), oiled=0.55, seed=3),
    'door':    oak('doorplank', light=(0.33, 0.27, 0.20), dark=(0.14, 0.11, 0.08), axis='Z', ring_mm=3.0, lacquer=0.0, rough=0.70,
                   coat_rough=0.3, var=0.12, wear=0.5, grime=1.0, scratches=0.0, warp=1.6, seed=4.0, bump=1.8),
    'door2':   oak('doorplank2', light=(0.30, 0.25, 0.19), dark=(0.13, 0.10, 0.075), axis='Z', ring_mm=2.4, lacquer=0.0, rough=0.72,
                   coat_rough=0.3, var=0.12, wear=0.5, grime=1.0, scratches=0.0, warp=1.4, seed=7.0, bump=1.8),
    'lifter':  wood('lifter', light=(0.42, 0.28, 0.15), dark=(0.18, 0.10, 0.05), axis='X', ring=1.0, rough=0.38, coat=0.2, wear=1.0, grime=0.3, warp=1.0, center=(0, 20), oiled=0.7, seed=6),
    'bronze':  metal('bronze', (0.55, 0.36, 0.20), 0.30, marks='stamp', marks_scale=0.3, wear=0.9, wear_col=(0.80, 0.55, 0.32), grime=0.9, grime_col=(0.08, 0.10, 0.07), patina=0.6),
    'dark':    dark_mat('gap', (0.01, 0.008, 0.006), 0.95),
    'nail':    wood('treenail', light=(0.36, 0.26, 0.16), dark=(0.14, 0.09, 0.05), axis='Y', ring=0.9, rough=0.6, wear=0.3, grime=1.0, warp=0.6, center=(1.2, 0.7), oiled=0.0, sawn=0.5, seed=7),
}

PX = [-22.0, 0.0, 22.0]
PIN_R, BORE_R, WIDE_R, HOLE_R = 6.0, 6.35, 7.9, 6.45
BOLT_Z = (-14.0, 14.0); BOLT_Y = (-15.0, 15.0)
STEP_Z = 36.0; PIN_L = 34.0; COLLAR_H = 4.0
GROOVE = (-14.0, -5.0, -7.0, 7.0)
# Canonical rest pose: bolt at dx = 0, all 3 gravity pins at lift = 0 (foot at z = +6.0 mm, 8 mm inside bolt)
BOLT_DX = 0.0
STATES = [('free', 0.0, 0.0) for _ in range(3)]

def cut_half(o):
    boolean(o, box('cut', -400, 400, -200, 0, -400, 400))

# ---------------------------------------------------------------- housing (thick beam) with bolt channel and pin bores
H = box('housing', -50, 50, -22, 22, -34, 78)
boolean(H, box('channel', -60, 60, BOLT_Y[0] - 0.8, BOLT_Y[1] + 0.8, BOLT_Z[0] - 0.8, BOLT_Z[1] + 0.6))
for x in PX:
    boolean(H, cyl('bore', BORE_R, STEP_Z - BOLT_Z[1] + 1, (x, 0, (STEP_Z + BOLT_Z[1]) / 2), verts=64))
    boolean(H, cyl('wide', WIDE_R, 70 - STEP_Z, (x, 0, (70 + STEP_Z) / 2), verts=64))
for (tx, tz) in [(-38, 50), (38, 50), (-38, -24), (38, -24)]:
    boolean(H, cyl('tnh', 4.0, 80, (tx, 10, tz), axis='Y', verts=48))
cut_half(H); put(H, MAT['housing'], 0.8, 4)

for idx, x in enumerate(PX):
    cp = cyl(f'cap{idx}', WIDE_R + 0.05, 8.0, (x, 0, 74.0), verts=64); cut_half(cp); put(cp, MAT['pin'], 0.4, 3)
    # Dark interior backing inside the pin bore so grayscale contrast behind moving pins is strong
    put(box(f'bore_dark{idx}', x - WIDE_R + 0.4, x + WIDE_R - 0.4, 6.2, 7.8, BOLT_Z[1] - 0.5, 70.0), MAT['dark'])

for idx, (tx, tz) in enumerate([(-38, 50), (38, 50), (-38, -24), (38, -24)]):
    tn = cyl(f'treenail{idx}', 3.98, 60, (tx, 10, tz), axis='Y', verts=48); cut_half(tn); put(tn, MAT['nail'], 0.3, 3)

# ---------------------------------------------------------------- bolt (lighter wood, burnished by use)
bolt = box('bolt', -160 + BOLT_DX, 130 + BOLT_DX, BOLT_Y[0], BOLT_Y[1], BOLT_Z[0], BOLT_Z[1])
boolean(bolt, box('groove', -36 + BOLT_DX, 140, GROOVE[2], GROOVE[3], GROOVE[0] - 1, GROOVE[1]))
for x in PX:
    boolean(bolt, cyl('hole', HOLE_R, 30, (x + BOLT_DX, 0, 0), verts=64))
cut_half(bolt); put(bolt, MAT['bolt'], 0.6, 4)

# ---------------------------------------------------------------- pins (turned dark hardwood, collar at top + false-set waist groove)
REST_FOOT_Z = STEP_Z + COLLAR_H - PIN_L  # +6.0 mm
for i, ((st, lift, tilt), x) in enumerate(zip(STATES, PX)):
    z0 = REST_FOOT_Z + lift
    prof = [
        (PIN_R - 0.9, z0),
        (PIN_R - 0.2, z0 + 0.35),
        (PIN_R, z0 + 1.0),
        # Turned anti-pick false-set waist groove (catches on bolt rim at lift ~ 4.5 mm)
        (PIN_R, z0 + 2.8),
        (PIN_R - 1.15, z0 + 3.2),
        (PIN_R - 1.15, z0 + 4.5),
        (PIN_R, z0 + 4.9),
        (PIN_R, z0 + PIN_L - COLLAR_H - 0.6),
        (PIN_R + 0.6, z0 + PIN_L - COLLAR_H),
        (WIDE_R - 0.35, z0 + PIN_L - COLLAR_H + 0.3),
        (WIDE_R - 0.3, z0 + PIN_L - 1.0),
        (WIDE_R - 1.2, z0 + PIN_L - 0.1),
        (2.0, z0 + PIN_L),
    ]
    yc = 0.0
    xc = x
    p = lathe('pin%d' % i, prof, xc, y=yc, seg=64); p.modifiers.clear()
    put(p, MAT['pin'], 0.0)

# ---------------------------------------------------------------- peg lifter in the groove (canonical rest at x = 0, lift = 0)
lift_top = REST_FOOT_Z
st = box('lifter', -6.5, 160, -5.6, 5.6, GROOVE[0] + 0.6, GROOVE[0] + 6.4); put(st, MAT['lifter'], 1.2, 4)
peg = lathe('peg', [(3.6, GROOVE[0] + 5.0), (3.6, lift_top - 1.4), (3.0, lift_top - 0.3), (2.0, lift_top)], PX[1], y=0.0, seg=48)
peg.modifiers.clear(); put(peg, MAT['bronze'], 0.0)
put(box('ferrule', -7.5, 6.0, -6.0, 6.0, GROOVE[0] + 0.2, GROOVE[0] + 6.8), MAT['bronze'], 0.6, 3)

# ---------------------------------------------------------------- door: vertical planks behind
for i, (x0, x1) in enumerate([(-200, -61.4), (-60.8, 59.6), (60.2, 200)]):
    d = box('plank%d' % i, x0, x1, 22, 70, -260, 260); put(d, MAT['door'] if i % 2 == 0 else MAT['door2'], 1.0, 4)
put(box('seam', -200, 200, 60, 61, -260, 260), MAT['dark'])

# ---------------------------------------------------------------- light + camera
world_hdri(float(arg('--world', '0.05')), sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 0, 20)
kx, ky, kz, ks, ke = [float(v) for v in arg('--key', '-200,-200,260,85,680000').split(',')]
area_light('key', (kx, ky, kz), AIM, ks, ke, (1.0, 0.80, 0.58))
area_light('fill', (260, -220, 0), AIM, 160, float(arg('--fill', '14000')), (0.92, 0.95, 1.0))
area_light('rim', (80, 60, 300), AIM, 80, float(arg('--rim', '20000')), (1.0, 0.9, 0.8))
target_pt = (float(arg('--tx', '2')), 0.0, float(arg('--tz', '26')))
cam = look_camera(target_pt, float(arg('--yaw', '-16')), float(arg('--pitch', '10')), float(arg('--dist', '470')), lens=float(arg('--lens', '120')))
mirror_softbox('sheen', (0, 0, 10), cam, dist=500, size=float(arg('--ss', '70')), size_y=float(arg('--ssy', '170')), energy=float(arg('--sheen', '22000')), shift=(float(arg('--sx', '-5')), 0, float(arg('--sz', '4'))))
render_setup(os.path.join(OUT_DIR, 'plate', 'plate_1236x1650.png'), RES, SAMPLES, exposure=0.05)

MOVING = ['bolt', 'pin0', 'pin1', 'pin2', 'lifter', 'peg', 'ferrule']
EXTRA = {
    'pin_x': PX,
    'pin_r': PIN_R,
    'bore_r': BORE_R,
    'wide_r': WIDE_R,
    'bolt_top_z': BOLT_Z[1],
    'bolt_bot_z': BOLT_Z[0],
    'step_z': STEP_Z,
    'pin_len': PIN_L,
    'collar_h': COLLAR_H,
    'rest_foot_z': REST_FOOT_Z,
    'set_lift_mm': 8.0,
}

P.run_family_pipeline(
    family_name='wooden_pin',
    out_dir=OUT_DIR,
    moving_names=MOVING,
    camera_target=target_pt,
    matcap_centre=(0.0, -10.0, 20.0),
    extra_meta=EXTRA,
    plate_res=tuple(RES),
    plate_samples=SAMPLES,
    tex_size=1024,
    ao_samples=32,
)
