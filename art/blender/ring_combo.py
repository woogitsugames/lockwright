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
    'cut':    metal('ring_cut', (0.82, 0.60, 0.30), 0.2, marks='mill', marks_amt=0.7, wear=0.4, grime=0.5),
    'body':   metal('body_brass', (0.72, 0.52, 0.25), 0.30, marks='stamp', marks_scale=0.5, wear=0.9, wear_col=(0.92, 0.74, 0.44), grime=0.8, patina=0.3, tint_var=0.08),
    'steel':  metal('spindle', (0.50, 0.50, 0.51), 0.22, aniso=0.5, marks='turn', marks_axis=(1, 0, 0), wear=0.5, grime=0.5),
    'shackle': metal('shackle', (0.58, 0.58, 0.59), 0.2, aniso=0.4, marks='grind', marks_axis=(1, 0, 0), wear=0.6, grime=0.4, smudge=1.0),
    'ink':    dark_mat('ink', (0.018, 0.016, 0.014), 0.55),
    'spring': metal('dspring', (0.55, 0.55, 0.56), 0.25, marks=None, wear=0.0, grime=0.3, bevel_r=0.0),
    'bench':  wood('bench', light=(0.22, 0.15, 0.09), dark=(0.07, 0.045, 0.03), axis='X', ring=0.4, rough=0.6, wear=0.4, grime=0.8, warp=5, center=(0, -80), sawn=0.3, checks=0.5),
}

R_OUT, R_IN, SP_R, LUG_R, THK, PITCH = 15.0, 6.0, 4.6, 6.7, 10.0, 13.0
RX = [-19.5 + PITCH * i for i in range(4)]       # ring centres along X
STATES = [('set', 0, 0.0), ('bind', 144, 0.0), ('false', 0, 0.0), ('free', 252, 0.3)]  # gate angle (deg from top), gap
SHIFT = 0.0

def cut_half(o):
    boolean(o, box('cut', -300, 300, -200, 0, -300, 300))

def ring(i, x, st, gate_deg):
    # 10-sided dial with eased corners (one flat per digit), bore, gate notch, detent grooves
    o = cyl('ring%d' % i, R_OUT / math.cos(math.pi / 10), THK, (x, 0, 0), axis='X', verts=10)
    o.data.transform(Matrix.Rotation(math.pi / 10, 4, 'X'))
    boolean(o, lathe_x('round', [(x - THK, R_OUT - 0.05 + 0.9), (x + THK, R_OUT + 0.9)], seg=160), 'INTERSECT')
    boolean(o, lathe_x('bore', [(x - 10, R_IN), (x + 10, R_IN)], seg=128))
    # gate: a slot through the ring thickness at gate_deg from the top
    a = math.radians(gate_deg)
    if st == 'false':
        g = box('fgate', x - THK, x + THK, -1.7, 1.7, R_IN - 1, R_IN + 0.55)
    else:
        g = box('gate', x - THK, x + THK, -1.8, 1.8, R_IN - 1, LUG_R + 0.35)
    g.data.transform(Matrix.Rotation(-a, 4, 'X')); boolean(o, g)
    for k in range(10):  # detent V-grooves on the right face
        v = box('dv', x + THK / 2 - 0.5, x + THK / 2 + 1, -0.45, 0.45, R_IN + 1.6, R_IN + 3.0)
        v.data.transform(Matrix.Rotation(math.radians(36 * k + 18), 4, 'X')); boolean(o, v)
    cut_half(o); put(o, MAT['brass'], 0.25, 3)
    # digits (black-filled engraving) on the flats; the flat at the top shows the current digit
    for k in range(10):
        ang = math.radians(36 * k)
        cu = bpy.data.curves.new('d', 'FONT'); cu.body = str((k + i * 3) % 10); cu.align_x = 'CENTER'; cu.align_y = 'CENTER'
        cu.size = 7.0; cu.extrude = 0.12
        try: cu.font = bpy.data.fonts.load(FONT, check_existing=True)
        except Exception: pass
        t = bpy.data.objects.new('digit', cu); bpy.context.collection.objects.link(t)
        t.matrix_world = Matrix.Rotation(-ang, 4, 'X') @ Matrix.Translation((x, 0, R_OUT + 0.04))
        t.data.materials.append(MAT['ink'])
        # only keep digits facing the camera side that still exists after the cut (y >= 0)
        if (Matrix.Rotation(-ang, 4, 'X') @ Vector((0, 0, 1))).y < -0.05: bpy.data.objects.remove(t, do_unlink=True)
    return o

for i, ((st, gdeg, gap), x) in enumerate(zip(STATES, RX)):
    ring(i, x, st, gdeg)
    # fixed spacer washer + detent ball and spring between rings (shown at the bottom of the section)
    if i < 3:
        sx = x + THK / 2 + (PITCH - THK) / 2
        w = lathe_x('spacer', [(sx - 1.2, LUG_R + 0.3), (sx - 1.2, R_OUT - 2.2), (sx + 1.2, R_OUT - 2.2), (sx + 1.2, LUG_R + 0.3)], seg=128)
        boolean(w, cyl('bp', 0.8, 4, (sx, 0, -(R_IN + 2.3)), axis='X', verts=24)); cut_half(w); put(w, MAT['body'], 0.12, 2)
        b = bpy.ops.mesh.primitive_uv_sphere_add(radius=0.75, location=(sx - 1.25, 0.7, -(R_IN + 2.3))); put(bpy.context.object, MAT['steel'])

# ---------------------------------------------------------------- spindle (shackle leg) with lugs
sp = lathe_x('spindle', [(-27.0, 3.6), (-26.5, SP_R), (30.0, SP_R), (30.0, 3.0)], seg=96)
for (st, gdeg, gap), x in zip(STATES, RX):
    face = x - THK / 2           # left face of the ring
    if st == 'set': lx0 = face + 1.2                     # lug has entered the gate
    else: lx0 = face - 3.0 - gap                         # pressed on the face (gap 0) or just short of it
    lug = box('lug', lx0, lx0 + 3.0, -1.5, 1.5, SP_R - 0.4, LUG_R)
    boolean(sp, lug, 'UNION')
cut_half(sp); put(sp, MAT['steel'], 0.08, 2)

# ---------------------------------------------------------------- body (left), end cap (right), shackle
body = prism('body', [(-56 + 3 * (1 - math.cos(math.radians(t))), -17 + 3 * (1 - math.sin(math.radians(t)))) for t in range(0, 91, 15)] +
             [(-27.2, -17.0), (-27.2, 24.0)] + [(-56 + 4 - 4 * math.sin(math.radians(t)), 24 - 4 + 4 * math.cos(math.radians(t))) for t in range(0, 91, 15)], -17, 17)
boolean(body, lathe_x('bh', [(-60, SP_R + 0.15), (-26, SP_R + 0.15)], seg=96))
boolean(body, cyl('latch', 4.4, 40, (-40, 0, 20), verts=64))
cut_half(body); put(body, MAT['body'], 0.5, 3)
for (rx, rz) in [(-51.0, -12.0), (-51.0, 19.0), (-31.5, -12.0)]:
    screw_head('brivet', (rx, 17.0, rz), 1.4, 0.5, axis='Y', slot=False, kind='dome', mat=MAT['body'])
cap = lathe_x('cap', [(26.2, SP_R + 0.2), (26.2, 16.0), (27.6, 17.0), (31.0, 17.0), (32.5, 15.6), (32.5, SP_R + 0.2)], seg=160)
cut_half(cap); put(cap, MAT['body'], 0.25, 3)
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
put(box('bench', -300, 300, 90, 110, -300, 300), paint('wall', (0.10, 0.095, 0.085), rough=0.7, chip=0.0, grime=0.0), 0.0)

# ---------------------------------------------------------------- light + camera
world_hdri(float(arg('--world', '0.05')), sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (-6, 0, 8)
kx, ky, kz, ks, ke = [float(v) for v in arg('--key', '-160,-170,220,60,400000').split(',')]
area_light('key', (kx, ky, kz), AIM, ks, ke, (1.0, 0.84, 0.66))
area_light('fill', (220, -180, -10), AIM, 120, float(arg('--fill', '6000')), (0.92, 0.95, 1.0))
area_light('rim', (60, 80, 220), AIM, 60, float(arg('--rim', '12000')), (1.0, 0.92, 0.85))
cam = look_camera((float(arg('--tx', '-5')), 0, float(arg('--tz', '12'))), float(arg('--yaw', '-15')), float(arg('--pitch', '30')),
                  float(arg('--dist', '345')), lens=float(arg('--lens', '120')))
mirror_softbox('sheen', (0, 0, 0), cam, dist=400, size=float(arg('--ss', '40')), size_y=float(arg('--ssy', '120')), energy=float(arg('--sheen', '25000')),
               shift=(float(arg('--sx', '-5')), 0, float(arg('--sz', '4'))))
render_setup(OUT, RES, SAMPLES, exposure=float(arg('--exp', '0.0')), crop=CROP)
bpy.ops.render.render(write_still=True)
print('WROTE', scene.render.filepath)
