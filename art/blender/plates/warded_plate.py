# Lockwright — GPU plate + matcap + normal/ORM + GLB generator for `warded` family.
# Based on art/blender/warded.py, game/assets/photoreal/tools/render_plate.py, and spikes/lit-metal/tools/bake.py.
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
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'warded')))
RES = [int(v) for v in arg('--res', '1236x1650').split('x')]
SAMPLES = int(arg('--samples', '160'))
BIT_DEG_REST = 76.0
BIT_A = math.radians(BIT_DEG_REST)
LIFT_REST = 1.38

# ---------------------------------------------------------------- materials (T06 satin/forged finish: roughness >= 0.25)
MAT = {
    'case':    iron('case_iron', rust=0.7, base=(0.2, 0.19, 0.18), rough=0.48, polish=0.4, seed=1),
    'ward':    iron('ward_iron', rust=0.6, base=(0.21, 0.2, 0.19), rough=0.45, polish=0.8, scale=2.0, seed=2),
    'bolt':    iron('bolt_iron', rust=0.35, base=(0.26, 0.25, 0.24), rough=0.38, polish=1.0, scale=1.5, seed=3),
    'tumbler': iron('tumb_iron', rust=0.45, base=(0.23, 0.22, 0.21), rough=0.42, polish=0.9, scale=1.8, seed=4),
    'spring':  metal('leaf', (0.16, 0.16, 0.17), 0.35, marks='grind', marks_axis=(1, 0, 0), wear=0.7, wear_col=(0.4, 0.39, 0.38), grime=0.8, grime_col=(0.12, 0.05, 0.02)),
    'pin':     metal('drillpin', (0.40, 0.39, 0.38), 0.34, marks='turn', marks_axis=(0, 1, 0), wear=0.8, grime=0.9, grime_col=(0.14, 0.06, 0.02)),
    'probe':   metal('probe', (0.56, 0.56, 0.57), 0.26, aniso=0.5, marks='grind', marks_axis=(1, 0, 0), wear=0.4, grime=0.1),
    'cut':     metal('cover_cut', (0.42, 0.41, 0.40), 0.36, marks='grind', marks_axis=(1, 1, 0), wear=0.0, grime=0.3),
    'wood':    wood('chest_oak', light=(0.34, 0.22, 0.12), dark=(0.13, 0.075, 0.04), axis='X', ring=0.6, rough=0.72, wear=0.6, grime=0.9, warp=3.0, center=(0, 60), oiled=0.0),
    'dark':    dark_mat('hole', (0.01, 0.008, 0.006), 0.95),
}

PIN = Vector((0.0, 0.0, -8.0))
DZ = 2.8
BIT_R = 25.6
X0, X1, Z0, Z1, RC, WALL, DEPTH, BP = -34.0, 34.0, -42.0, 42.0, 7.0, 1.8, 10.0, 2.0

def rrect(x0, x1, z0, z1, r, n=8):
    pts = []
    for cx, cz, a0 in [(x1 - r, z0 + r, -90), (x1 - r, z1 - r, 0), (x0 + r, z1 - r, 90), (x0 + r, z0 + r, 180)]:
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n); pts.append((cx + r * math.cos(a), cz + r * math.sin(a)))
    return pts

def sector(name, r0, r1, a0, a1, y0, y1, c=PIN, n=48):
    a0, a1 = math.radians(a0), math.radians(a1); k = max(4, int(n * abs(a1 - a0) / math.pi))
    outer = [(c.x + r1 * math.cos(a0 + (a1 - a0) * i / k), c.z + r1 * math.sin(a0 + (a1 - a0) * i / k)) for i in range(k + 1)]
    inner = [(c.x + r0 * math.cos(a1 - (a1 - a0) * i / k), c.z + r0 * math.sin(a1 - (a1 - a0) * i / k)) for i in range(k + 1)]
    return prism(name, outer + inner, y0, y1)

# ---------------------------------------------------------------- case: back plate, walls, cover fragment
bp = prism('backplate', rrect(X0, X1, Z0, Z1, RC), DEPTH, DEPTH + BP)
for ex, ez in [(X0 - 7, Z1 - 12), (X0 - 7, Z0 + 12), (X1 + 7, Z0 + 12)]:
    ear = cyl('ear', 6.0, BP, (ex, DEPTH + BP / 2, ez), axis='Y', verts=48); boolean(bp, ear, 'UNION')
    boolean(bp, box('earbr', min(ex, ex * 0.8), max(ex, ex * 0.8), DEPTH, DEPTH + BP, ez - 6, ez + 6), 'UNION')
kh = cyl('kh', 3.2, 10, (PIN.x, DEPTH, PIN.z), axis='Y', verts=64)
boolean(kh, box('khs', PIN.x - 1.5, PIN.x + 1.5, DEPTH - 5, DEPTH + 5, PIN.z - BIT_R - 0.6, PIN.z), 'UNION')
boolean(bp, kh); put(bp, MAT['case'], 0.35, 3)

walls = prism('walls', rrect(X0, X1, Z0, Z1, RC), 0.0, DEPTH)
boolean(walls, prism('in', rrect(X0 + WALL, X1 - WALL, Z0 + WALL, Z1 - WALL, RC - WALL), -1, DEPTH + 1))
boolean(walls, box('boltslot', X1 - 3, X1 + 3, 3.0, 9.0, 12.0 + DZ, 21.0 + DZ))
put(walls, MAT['case'], 0.3, 3)

cov = prism('cover', rrect(X0, X1, Z0, Z1, RC), -1.6, 0.0)
cutter = box('cc', -80, 80, -10, 10, -160, 0); cutter.rotation_euler = (0, math.radians(40), 0)
cutter.location = (24, 0, 34); bpy.context.view_layer.objects.active = cutter; bpy.ops.object.transform_apply(location=True, rotation=True)
boolean(cov, cutter); put(cov, MAT['case'], 0.25, 2)

for idx, (rx, rz) in enumerate([(X1 - 4.0, Z1 - 4.0), (X1 - 4.0, 26.0), (16.0, Z1 - 4.0)]):
    screw_head(f'crivet{idx}', (rx, -1.6, rz), 2.3, 1.2, axis='-Y', slot=False, kind='dome', mat=MAT['case'])
for idx, (rx, rz) in enumerate([(X0 + 5, Z0 + 5), (X1 - 5, Z0 + 5), (X0 + 5, Z1 - 5)]):
    screw_head(f'brivet{idx}', (rx, DEPTH, rz), 2.4, 1.1, axis='-Y', slot=False, kind='dome', mat=MAT['case'])
for idx, (ex, ez) in enumerate([(X0 - 7, Z1 - 12), (X0 - 7, Z0 + 12), (X1 + 7, Z0 + 12)]):
    nh = box(f'nail{idx}', ex - 2.6, ex + 2.6, DEPTH - 1.4, DEPTH, ez - 2.6, ez + 2.6)
    nh.rotation_euler = (0, math.radians(17 + ex), 0); bpy.context.view_layer.objects.active = nh; bpy.ops.object.transform_apply(rotation=True)
    put(nh, MAT['ward'], 0.5, 3)

# ---------------------------------------------------------------- drill pin + wards (rings with gaps)
put(cyl('pin', 2.2, DEPTH - 1.0, (PIN.x, 1.0 + (DEPTH - 1.0) / 2, PIN.z), axis='Y', verts=64), MAT['pin'], 0.2, 3)
bit_deg = BIT_DEG_REST
WARDS = [
    (9.6, 11.4, [(bit_deg + 13, bit_deg + 347)], 5.0),
    (17.4, 19.2, [(bit_deg + 10, 205 - 9), (205 + 9, bit_deg + 360 - 10)], 4.0),
]
w_idx = 0
for r0, r1, arcs, y0 in WARDS:
    for a0, a1 in arcs:
        w = sector(f'ward{w_idx}', r0, r1, a0, a1, y0, DEPTH + 0.05); put(w, MAT['ward'], 0.22, 3)
        for ri, a in enumerate((a0 + 8, a1 - 8)):
            rr = (r0 + r1) / 2
            screw_head(f'wr_{w_idx}_{ri}', (PIN.x + rr * math.cos(math.radians(a)), y0, PIN.z + rr * math.sin(math.radians(a))), 0.75, 0.4, axis='-Y', slot=False, kind='dome', mat=MAT['ward'])
        w_idx += 1

# ---------------------------------------------------------------- probe bit (ward probe): tube over pin + flat bit
c, s_ = math.cos(BIT_A), math.sin(BIT_A)
tube = lathe_x('probe_tube', [(-2.0, 2.3), (-2.0, 3.0), (30.0, 3.0), (30.0, 2.3)], seg=64)
tube.data.transform(Matrix.Rotation(math.pi / 2, 4, 'Z')); tube.location = (PIN.x, 1.6, PIN.z); put(tube, MAT['probe'], 0.12, 2)
bit = box('bit', 2.6, BIT_R, 1.6, 9.4, -1.25, 1.25)
boolean(bit, box('bitstep', 13.5, 15.5, 0, 3.2, -2, 2))
bit.data.transform(Matrix.Rotation(-BIT_A, 4, 'Y')); bit.location = (PIN.x, 0, PIN.z); put(bit, MAT['probe'], 0.3, 3)

# ---------------------------------------------------------------- bolt with talon notches, stepped stud notch + staples
bolt = box('bolt', -28.0, 44.0, 3.4, 8.6, 12.6 + DZ, 20.6 + DZ)
for nx in (PIN.x + BIT_R * c - 1.7 + 0.2, PIN.x - 4.5):
    boolean(bolt, box('talon', nx, nx + 3.4, 0, 20, 11 + DZ, 15.4 + DZ))
# Main tumbler stud notch + shallow false-set shelf on its right side
boolean(bolt, box('stud_notch', -8.8, -5.6, 0, 20, 18.8 + DZ, 22 + DZ))
boolean(bolt, box('stud_fstep', -5.6, -4.0, 0, 20, 19.65 + DZ, 22 + DZ))
# Secondary trap/detector notch to the left of the main stud notch
boolean(bolt, box('stud_trap', -12.2, -9.8, 0, 20, 18.4 + DZ, 22 + DZ))
put(bolt, MAT['bolt'], 0.35, 3)

for idx, sx in enumerate((-22.0, 22.0)):
    st = box(f'staple{idx}', sx - 3, sx + 3, 1.6, DEPTH, 11.0 + DZ, 22.2 + DZ)
    boolean(st, box('sti', sx - 4, sx + 4, 3.3, DEPTH + 1, 12.5 + DZ, 20.7 + DZ)); put(st, MAT['case'], 0.3, 3)
    screw_head(f'srivet{idx}', (sx, 1.6, 21.4 + DZ), 1.4, 0.7, axis='-Y', slot=False, kind='dome', mat=MAT['case'])

# ---------------------------------------------------------------- tumbler (spring catch) + leaf spring
TPIV = Vector((-24.0, 0.0, 26.0 + DZ))
tum = prism('tumbler', [(-28.5, 23.5), (-20, 22.0), (-4.5, 22.0), (2.0, 21.4), (2.0, 13.2), (3.4, 12.2), (7.8, 12.2), (8.6, 13.6), (8.6, 23.0), (6.0, 26.0), (-20, 28.8), (-27.5, 29.0)], 1.0, 3.0)
tum.data.transform(Matrix.Translation((0, 0, DZ)))
boolean(tum, cyl('tph', 1.5, 10, (TPIV.x, 0, TPIV.z), axis='Y', verts=32))
ang = LIFT_REST / (-7.2 - TPIV.x)
tum.matrix_world = Matrix.Translation(TPIV) @ Matrix.Rotation(-ang, 4, 'Y') @ Matrix.Translation(-TPIV)
put(tum, MAT['tumbler'], 0.25, 3)

stud_c = tum.matrix_world @ Vector((-7.2, 0, 20.6 + DZ))
put(cyl('tstud', 1.2, 4.4, (stud_c.x, 4.8, stud_c.z), axis='Y', verts=32), MAT['pin'], 0.1, 2)
screw_head('tpivot', (TPIV.x, 1.0, TPIV.z), 2.2, 1.0, axis='-Y', slot=False, kind='dome', mat=MAT['case'])
put(cyl('tpost', 1.45, DEPTH, (TPIV.x, DEPTH / 2 + 0.5, TPIV.z), axis='Y', verts=32), MAT['pin'], 0.05)

top_c = tum.matrix_world @ Vector((-2.0, 0, 27.3 + DZ))
lp = [(-30.0, Z1 - WALL - 0.4), (-22.0, Z1 - WALL - 1.0), (-12.0, Z1 - 4.6), (-5.0, top_c.z + 1.4), (top_c.x, top_c.z + 0.3)]
leaf = flat_tool('leaf', lp, 1.3, 3.6, 2.0, tip='round'); leaf.data.materials[0] = MAT['spring']
screw_head('lrivet', (-27.5, 0.2, Z1 - WALL - 0.9), 1.5, 0.8, axis='-Y', slot=False, kind='dome', mat=MAT['case'])
put(box('lblock', -32.2, -25.0, 0.2, DEPTH, Z1 - WALL - 2.4, Z1 - WALL), MAT['case'], 0.2, 2)

# ---------------------------------------------------------------- chest board behind (oak planks)
for i, (bz0, bz1) in enumerate([(-170, -58.4), (-58.0, 51.6), (52.0, 170)]):
    wm = oak('chest_oak%d' % i, light=(0.36, 0.23, 0.115), dark=(0.15, 0.085, 0.04), axis='X', ring_mm=2.0 + 0.5 * i, lacquer=0.45,
             rough=0.5, coat_rough=0.22, wear=0.7, grime=0.9, scratches=0.8, seed=2.0 + i * 1.7)
    bd = box('board%d' % i, -140, 140, DEPTH + BP, DEPTH + BP + 22, bz0, bz1); put(bd, wm, 0.6, 3)
kd = cyl('khd', 3.0, 1.0, (PIN.x, DEPTH + BP + 0.6, PIN.z), axis='Y', verts=48)
boolean(kd, box('khds', PIN.x - 1.3, PIN.x + 1.3, DEPTH, DEPTH + 4, PIN.z - BIT_R, PIN.z), 'UNION'); put(kd, MAT['dark'])

# ---------------------------------------------------------------- light + camera
world_hdri(float(arg('--world', '0.05')), sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 5, 0)
kx, ky, kz, ks, ke = [float(v) for v in arg('--key', '-110,-120,150,42,185000').split(',')]
area_light('key', (kx, ky, kz), AIM, ks, ke, (1.0, 0.82, 0.62))
area_light('fill', (150, -120, -30), AIM, 100, float(arg('--fill', '2600')), (0.92, 0.95, 1.0))
area_light('rim', (60, 40, -150), AIM, 50, float(arg('--rim', '2500')), (1.0, 0.9, 0.8))
target_pt = (float(arg('--tx', '0')), 5.0, float(arg('--tz', '-3')))
cam = look_camera(target_pt, float(arg('--yaw', '-9')), float(arg('--pitch', '11')), float(arg('--dist', '265')), lens=float(arg('--lens', '120')))
mirror_softbox('sheen', (0, 0, 0), cam, size=float(arg('--ss', '36')), size_y=float(arg('--ssy', '90')), energy=float(arg('--sheen', '8500')), shift=(float(arg('--sx', '-5')), 0, float(arg('--sz', '4'))))
render_setup(os.path.join(OUT_DIR, 'plate', 'plate_1236x1650.png'), RES, SAMPLES, exposure=0.25)

MOVING = ['probe_tube', 'bit', 'bolt', 'tumbler', 'tstud', 'leaf']
EXTRA = {
    'pin_pivot': [PIN.x, PIN.z, -PIN.y],
    'tumbler_pivot': [TPIV.x, TPIV.z, -TPIV.y],
    'bit_deg_rest': BIT_DEG_REST,
    'lift_rest_mm': LIFT_REST,
    'stud_x_rest': -7.2,
    'bolt_notch_z': 20.6 + DZ,
}

P.run_family_pipeline(
    family_name='warded',
    out_dir=OUT_DIR,
    moving_names=MOVING,
    camera_target=target_pt,
    matcap_centre=(0.0, 2.0, 0.0),
    extra_meta=EXTRA,
    plate_res=tuple(RES),
    plate_samples=SAMPLES,
    tex_size=1024,
    ao_samples=32,
)
