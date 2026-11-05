# Lockwright — photoreal look-dev: ring combination padlock cut along the spindle (rings shown as
# sectioned slices with their gates). Units: 1 Blender unit = 1 mm. Run:
#   blender -b -P art/blender/ring_combo.py -- --out art/renders/ring_combo.png --res 1620x2160 --samples 128
# Generic, invented mechanism with game-tuned proportions (rings 10 mm thick at 13 mm pitch, ~48/64 dp on
# a 412 dp phone). Digits use Lato Bold (SIL OFL, mockups/fonts). Not a reproduction of any product.
#
# The shackle is pulled (tension), so the spindle lugs press on the left faces of the rings that are not
# gated. States, left to right:
#   R1 SET        gate at the top: lug has slipped into the gate, light gap behind it
#   R2 BINDING    gate turned away: lug pressed hard on the ring face (no gap), ring held
#   R3 FALSE GATE shallow false notch at the top: lug dips in but still bears on the ring
#   R4 FREE       gate turned away, lug not touching yet (thin gap)
import bpy, bmesh, math, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lw_common import *
from mathutils import Vector, Matrix

arg = cli()
OUT = arg('--out', 'ring_combo.png'); RES = [int(v) for v in arg('--res', '824x1100').split('x')]
SAMPLES = int(arg('--samples', '96'))
CROP = [float(v) for v in arg('--crop', '').split(',')] if arg('--crop', '') else None
FONT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'mockups', 'fonts', 'Lato-Bold.ttf')

MAT = {
    'brass':  metal('ring_brass', (0.80, 0.57, 0.27), 0.24, marks='turn', marks_axis=(1, 0, 0), marks_scale=1.2, wear=0.9, wear_col=(0.95, 0.77, 0.46), grime=0.7, patina=0.15, tint_var=0.05),
    'cut':    metal('ring_cut', (0.86, 0.64, 0.33), 0.17, aniso=0.3, marks='mill', marks_amt=0.8, wear=0.0, grime=0.2),
    'cut_b':  metal('body_cut', (0.78, 0.58, 0.30), 0.22, marks='mill', marks_amt=0.8, wear=0.0, grime=0.3),
    'cut_s':  metal('steel_cut', (0.64, 0.64, 0.65), 0.18, marks='mill', marks_amt=0.8, wear=0.0, grime=0.2),
    'body':   metal('body_brass', (0.72, 0.52, 0.25), 0.30, marks='stamp', marks_scale=0.5, wear=0.9, wear_col=(0.92, 0.74, 0.44), grime=0.8, patina=0.3, tint_var=0.08),
    'steel':  metal('spindle', (0.50, 0.50, 0.51), 0.22, aniso=0.5, marks='turn', marks_axis=(1, 0, 0), wear=0.5, grime=0.5),
    'shackle': metal('shackle', (0.58, 0.58, 0.59), 0.2, aniso=0.4, marks='grind', marks_axis=(1, 0, 0), wear=0.6, grime=0.4, smudge=1.0),
    'ink':    dark_mat('ink', (0.018, 0.016, 0.014), 0.55),
    'spring': metal('dspring', (0.55, 0.55, 0.56), 0.25, marks=None, wear=0.0, grime=0.3, bevel_r=0.0),
    'bench':  wood('bench', light=(0.22, 0.15, 0.09), dark=(0.07, 0.045, 0.03), axis='X', ring=0.4, rough=0.6, wear=0.4, grime=0.8, warp=5, center=(0, -80), sawn=0.3, checks=0.5),
}

if photo_enabled():  # photo PBR maps (art/textures/photo); --photo 0 = procedural
    MAT.update({
        'brass':  photo_mat('ph_ring_brass', 'brass_face_milled', scale=40, rot=90, tint=(1.05, 0.98, 0.86), bump=0.15, wear=0.8, grime=0.6),
        'cut':    photo_mat('ph_ring_cut', 'brass_face_milled', scale=30, rot=42, tint=(1.15, 1.05, 0.9), bump=0.15, grime=0.2),
        'cut_s':  photo_mat('ph_spindle_cut', 'steel_ground', scale=14, rot=42, tint=(0.95, 0.95, 0.97), grime=0.2),
        'steel':  photo_mat('ph_spindle', 'steel_ground', scale=16, rot=0, tint=(0.85, 0.86, 0.88), wear=0.3, grime=0.4),
        'shackle': photo_mat('ph_shackle', 'spring_steel_polished', scale=30, bump=0.12, wear=0.4, grime=0.3),
    })

R_OUT, R_IN, SP_R, LUG_R, THK, PITCH = 15.0, 6.0, 4.6, 8.4, 10.0, 13.0   # tall lugs: gates read at phone size
RX = [-19.5 + PITCH * i for i in range(4)]       # ring centres along X
STATES = [('set', 0, 0.0), ('bind', 144, 0.0), ('false', 0, 0.0), ('free', 252, 0.8)]  # gate angle (deg from top), gap
SHIFT = 0.0

def mark_cut(o, mat):
    """Give the faces lying on the section plane (y = 0) their own milled finish, so the cut reads as a cut."""
    if mat.name not in o.data.materials: o.data.materials.append(mat)
    mi = list(o.data.materials).index(mat)
    for pg in o.data.polygons:
        if pg.normal.y < -0.99 and abs(pg.center.y) < 0.02: pg.material_index = mi
    return o

def tri(o):
    """Triangulate long concave section n-gons (boolean results), so bevel + smooth-by-angle cannot fold them."""
    bm = bmesh.new(); bm.from_mesh(o.data)
    bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4], quad_method='BEAUTY', ngon_method='EAR_CLIP')
    bm.to_mesh(o.data); bm.free(); return o

def cut_half(o):
    boolean(o, box('cut', -300, 300, -200, 0, -300, 300))

def digit_mesh(name, text, x, ang, size, z0, z1):
    """Digit glyph as a closed mesh between radii z0..z1 on the flat at `ang` (deg from the top, towards +y).
    Every digit has the same orientation on the wheel (glyph X = ring axis, glyph up = direction of rotation),
    like stamped dial wheels, so nothing is ever turned or mirrored."""
    cu = bpy.data.curves.new(name, 'FONT'); cu.body = text; cu.align_x = 'CENTER'; cu.align_y = 'CENTER'
    cu.size = size; cu.extrude = (z1 - z0) / 2; cu.offset_y = 0.0
    try: cu.font = bpy.data.fonts.load(FONT, check_existing=True)
    except Exception: pass
    t = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(t)
    for ob in bpy.context.selected_objects: ob.select_set(False)
    t.select_set(True); bpy.context.view_layer.objects.active = t
    bpy.ops.object.convert(target='MESH')
    t = bpy.context.view_layer.objects.active
    t.data.transform(Matrix.Rotation(-math.radians(ang), 4, 'X') @ Matrix.Translation((x, 0, (z0 + z1) / 2)))
    t.matrix_world = Matrix.Identity(4)
    return t

ENGRAVE, INK_TOP, DIGIT_SIZE = 0.32, 0.07, 7.4   # mm deep, ink fill sits 0.07 mm below the flat, glyph size

def ring(i, x, st, gate_deg):
    # 10-sided dial with eased corners (one flat per digit), bore, gate notch, detent grooves.
    # Flats at 18 + 36k deg: the section plane (y = 0) runs along two edges, so every flat that is left after the cut
    # is whole and so is its digit; the flat at 18 deg faces the camera and shows the current digit.
    o = cyl('ring%d' % i, R_OUT / math.cos(math.pi / 10), THK, (x, 0, 0), axis='X', verts=10)
    boolean(o, lathe_x('round', [(x - THK, R_OUT - 0.05 + 0.9), (x + THK, R_OUT + 0.9)], seg=160), 'INTERSECT')
    boolean(o, lathe_x('bore', [(x - 10, R_IN), (x + 10, R_IN)], seg=128))
    # gate: a slot through the ring thickness at gate_deg from the top
    a = math.radians(gate_deg)
    if st == 'false':
        g = box('fgate', x - THK, x + THK, -1.7, 1.7, R_IN - 1, R_IN + 1.1)   # shallow: the lug dips in, cannot pass
    else:
        g = box('gate', x - THK, x + THK, -1.8, 1.8, R_IN - 1, LUG_R + 0.45)
    g.data.transform(Matrix.Rotation(-a, 4, 'X')); boolean(o, g)
    for k in range(10):  # detent V-grooves on the right face
        v = box('dv', x + THK / 2 - 0.5, x + THK / 2 + 1, -0.45, 0.45, R_IN + 1.6, R_IN + 3.0)
        v.data.transform(Matrix.Rotation(math.radians(36 * k + 18), 4, 'X')); boolean(o, v)
    cut_half(o)
    # digits 0-9 engraved into the flats (only the five flats left after the cut), filled with black ink
    for k in range(5):
        ang, txt = 18 + 36 * k, str((k + i * 3) % 10)
        boolean(o, digit_mesh('engrave', txt, x, ang, DIGIT_SIZE, R_OUT - ENGRAVE, R_OUT + 1.0))
        ink = digit_mesh('digit', txt, x, ang, DIGIT_SIZE * 0.995, R_OUT - ENGRAVE - 0.05, R_OUT - INK_TOP)
        ink.data.materials.append(MAT['ink'])
    put(o, MAT['brass'], 0.25, 3); mark_cut(o, MAT['cut'])
    return o

for i, ((st, gdeg, gap), x) in enumerate(zip(STATES, RX)):
    ring(i, x, st, gdeg)
    # fixed spacer washer + detent ball and spring between rings (shown at the bottom of the section)
    if i < 3:
        sx = x + THK / 2 + (PITCH - THK) / 2
        # a real tube (lathe_x would cap both ends with discs and hide the spindle behind them)
        w = cyl('spacer', R_OUT - 2.2, 2.4, (sx, 0, 0), axis='X', verts=128); boolean(w, cyl('sb', LUG_R + 0.3, 6, (sx, 0, 0), axis='X', verts=128))
        boolean(w, cyl('bp', 0.8, 4, (sx, 0, -(R_IN + 2.3)), axis='X', verts=24)); cut_half(w); put(w, MAT['body'], 0.12, 2); mark_cut(w, MAT['cut_b'])
        b = bpy.ops.mesh.primitive_uv_sphere_add(radius=0.75, location=(sx - 1.25, 0.7, -(R_IN + 2.3))); put(bpy.context.object, MAT['steel'])

# ---------------------------------------------------------------- spindle (shackle leg) with lugs
sp = lathe_x('spindle', [(-27.0, 3.6), (-26.5, SP_R), (30.0, SP_R), (30.0, 3.0)], seg=96)
for (st, gdeg, gap), x in zip(STATES, RX):
    face = x - THK / 2           # left face of the ring
    if st == 'set': lx0 = face + 1.2                     # lug has entered the gate
    else: lx0 = face - 3.0 - gap                         # pressed on the face (gap 0) or just short of it
    lug = box('lug', lx0, lx0 + 3.0, -1.5, 1.5, SP_R - 0.4, LUG_R)
    boolean(sp, lug, 'UNION')
cut_half(sp); tri(sp); put(sp, MAT['steel'], 0.08, 2); mark_cut(sp, MAT['cut_s'])

# ---------------------------------------------------------------- body (left), end cap (right), shackle
body = prism('body', [(-56 + 3 * (1 - math.cos(math.radians(t))), -17 + 3 * (1 - math.sin(math.radians(t)))) for t in range(0, 91, 15)] +
             [(-27.2, -17.0), (-27.2, 24.0)] + [(-56 + 4 - 4 * math.sin(math.radians(t)), 24 - 4 + 4 * math.cos(math.radians(t))) for t in range(0, 91, 15)], -17, 17)
boolean(body, lathe_x('bh', [(-60, SP_R + 0.15), (-26, SP_R + 0.15)], seg=96))
boolean(body, cyl('latch', 4.4, 40, (-40, 0, 20), verts=64))
cut_half(body); put(body, MAT['body'], 0.5, 3); mark_cut(body, MAT['cut_b'])
for (rx, rz) in [(-51.0, -12.0), (-51.0, 19.0), (-31.5, -12.0)]:
    screw_head('brivet', (rx, 17.0, rz), 1.4, 0.5, axis='Y', slot=False, kind='dome', mat=MAT['body'])
cap = lathe_x('cap', [(26.2, SP_R + 0.2), (26.2, 16.0), (27.6, 17.0), (31.0, 17.0), (32.5, 15.6), (32.5, SP_R + 0.2)], seg=160)
cut_half(cap); put(cap, MAT['body'], 0.25, 3); mark_cut(cap, MAT['cut_b'])
# shackle: round steel bar, U with straight legs and rounded corners
def arc(cx, cz, r, a0, a1, n=10):
    return [Vector((cx + r * math.cos(math.radians(a0 + (a1 - a0) * k / n)), 0, cz + r * math.sin(math.radians(a0 + (a1 - a0) * k / n)))) for k in range(n + 1)]
pts = [Vector((30.0, 0, 0))] + arc(34, 8, 8, -90, 0) + arc(32, 30, 10, 0, 90) + arc(-30, 30, 10, 90, 180) + [Vector((-40.0, 0, 6.0))]
cu = bpy.data.curves.new('shackle', 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = 4.2; cu.bevel_resolution = 6
spl = cu.splines.new('POLY'); spl.points.add(len(pts) - 1)
for pp, p in zip(spl.points, pts): pp.co = (*p, 1)
sh = bpy.data.objects.new('shackle', cu); bpy.context.collection.objects.link(sh); cu.materials.append(MAT['shackle'])
# a groove machined in the left leg where the latch catches it
# backdrop: a worn bench top far behind
put(box('bench', -300, 300, 90, 110, -300, 300), photo_mat('ph_bench', 'bench_beech_top', scale=220, metallic=0.0, bump=0.4, grime=0.5) if photo_enabled() else oak('bench_oak', light=(0.30, 0.20, 0.11), dark=(0.12, 0.07, 0.035), axis='X', plank=72, ring_mm=2.6,
                                                    lacquer=0.3, rough=0.55, wear=0.6, grime=0.9, scratches=0.8, seed=3.0), 0.0)

# ---------------------------------------------------------------- light + camera
world_hdri(float(arg('--world', '0.05')), sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (-6, 0, 8)
kx, ky, kz, ks, ke = [float(v) for v in arg('--key', '-160,-170,220,60,400000').split(',')]
area_light('key', (kx, ky, kz), AIM, ks, ke, (1.0, 0.84, 0.66))
area_light('fill', (220, -180, -10), AIM, 120, float(arg('--fill', '40000')), (0.92, 0.95, 1.0))
area_light('rim', (60, 80, 220), AIM, 60, float(arg('--rim', '50000')), (1.0, 0.92, 0.85))
cam = look_camera((float(arg('--tx', '-2')), 0, float(arg('--tz', '5'))), float(arg('--yaw', '-12')), float(arg('--pitch', '34')),
                  float(arg('--dist', '215')), lens=float(arg('--lens', '120')))
mirror_softbox('sheen', (0, 0, 0), cam, dist=400, size=float(arg('--ss', '40')), size_y=float(arg('--ssy', '120')), energy=float(arg('--sheen', '25000')),
               shift=(float(arg('--sx', '-5')), 0, float(arg('--sz', '4'))))
render_setup(OUT, RES, SAMPLES, exposure=float(arg('--exp', '0.0')), crop=CROP)
bpy.ops.render.render(write_still=True)
print('WROTE', scene.render.filepath)
