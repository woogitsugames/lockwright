# Lockwright — photoreal look-dev: lever mortise lock in a tenement door, cover plate removed.
# Units: 1 Blender unit = 1 mm. Run:
#   blender -b -P art/blender/lever.py -- --out art/renders/lever.png --res 1620x2160 --samples 128
# Generic, unbranded mechanism with game-tuned proportions: three brass levers spaced 2.6 mm apart on the
# pivot (spacer washers), so the camera from lower right shows each one shifted right-up (2.5D stack).
# Not a reproduction of any real product.
#
# The bolt is thrown (locked). The tension arm pushes the bolt back, so the stump presses against the
# levers that are not gated. States (front lever first):
#   L1 TOO LOW   lifted 1.5 of 3.5 mm: the gate is still below the stump, stump bears on the upper tooth
#   L2 IN GATE   lifted exactly: the gate channel is level with the stump, light gap above and below
#   L3 TOO HIGH  lifted 5.0 of 3.0 mm: the gate passed above the stump, stump bears on the lower tooth
# Optional (--detector 1): a detector pawl on L3 drops behind the bolt tail.
import bpy, bmesh, math, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lw_common import *
from mathutils import Vector, Matrix

arg = cli()
OUT = arg('--out', 'lever.png'); RES = [int(v) for v in arg('--res', '824x1100').split('x')]
SAMPLES = int(arg('--samples', '96')); DETECTOR = int(arg('--detector', '0'))
CROP = [float(v) for v in arg('--crop', '').split(',')] if arg('--crop', '') else None

MAT = {
    'case':   paint('japan', (0.022, 0.021, 0.020), rough=0.38, metal_col=(0.42, 0.41, 0.40), chip=0.8, grime=0.7),
    'brass':  metal('lever_brass', (0.78, 0.55, 0.25), float(arg('--br', '0.2')), marks='stamp', marks_scale=0.8, wear=0.9, wear_col=(0.95, 0.76, 0.45), grime=0.8, grime_col=(0.06, 0.045, 0.02), tint_var=0.06, patina=float(arg('--patina', '0.4'))),
    'bolt':   metal('bolt_brass', (0.70, 0.50, 0.24), 0.30, marks='grind', marks_axis=(1, 0, 0), wear=0.8, wear_col=(0.92, 0.72, 0.42), grime=0.9, grime_col=(0.05, 0.04, 0.02), tint_var=0.08),
    'forend': metal('forend', (0.72, 0.52, 0.26), 0.26, marks='grind', marks_axis=(0, 0, 1), wear=0.6, grime=0.9, tint_var=0.1),
    'steel':  metal('stump', (0.46, 0.46, 0.47), 0.26, marks='turn', marks_axis=(0, 1, 0), wear=0.5, grime=0.6),
    'blued':  metal('blued', (0.10, 0.12, 0.17), 0.28, marks='grind', marks_axis=(1, 0, 0), wear=0.6, wear_col=(0.45, 0.45, 0.46), grime=0.4),
    'screw':  metal('screw_br', (0.70, 0.52, 0.28), 0.32, marks='turn', marks_axis=(1, 0, 0), wear=0.4, grime=1.0),
    'wood':   wood('door_oak', light=(0.30, 0.18, 0.085), dark=(0.11, 0.055, 0.025), axis='Z', ring=0.55, rough=0.5, coat=0.35, wear=0.3, grime=0.7, warp=2.0, center=(31, -18)),
    'paint':  paint('door_paint', (0.30, 0.20, 0.12), rough=0.5, metal_col=(0.36, 0.22, 0.11), chip=0.5),
    'pick':   metal('crank', (0.60, 0.60, 0.61), 0.2, aniso=0.6, marks='grind', marks_axis=(1, 0, 0), wear=0.3, grime=0.1),
    'wire':   metal('lifter', (0.62, 0.62, 0.63), 0.22, marks='turn', marks_axis=(0, 1, 0), wear=0.2, grime=0.1),
    'dark':   dark_mat('cavity', (0.012, 0.011, 0.010), 0.9),
}

# ---------------------------------------------------------------- layout (cover side y = 0, back plate at y = 14)
PIV = Vector((-22.0, 0, 4.0))
STUMP_X, STUMP_R = 7.7, 2.2            # stump bearing on the pocket walls (bolt pushed back by 0.3 mm)
LEVERS = [  # (y0, needed lift, actual lift, belly z)
    (0.9, 3.5, 1.5, -11.2),
    (4.1, 2.5, 2.5, -12.0),
    (7.3, 3.0, 5.0, -11.6),
]
LT = 1.6   # lever thickness
BACK_Y = 14.0

def lever_outline(belly):
    pts = [(PIV.x, PIV.z - 5.0), (-14, -4.5), (-9.5, belly + 0.8), (-8.5, belly), (1.5, belly), (3.0, belly + 1.0),
           (12.0, -10.5), (15.2, -9.8), (16.0, -8.6), (16.0, 10.8), (15.0, 12.0), (-6, 13.2), (PIV.x, PIV.z + 5.0)] + [
        (PIV.x - 5.0 * math.sin(math.radians(k * 15)), PIV.z + 5.0 * math.cos(math.radians(k * 15))) for k in range(1, 12)]
    return pts

def make_lever(i, y0, need, lift, belly):
    o = prism('lever%d' % i, lever_outline(belly), y0, y0 + LT)
    gz = -need  # gate centre (lever coords, stump at z = 0)
    boolean(o, box('pocketA', STUMP_X + 0.3 - 2.6, STUMP_X + 0.3 + 2.6, -5, 20, -9.0, 2.7))
    boolean(o, box('pocketB', -6.6, -1.4, -5, 20, -9.0, 2.7))
    boolean(o, box('gate', -2.0, STUMP_X, -5, 20, gz - 2.45, gz + 2.45))
    boolean(o, cyl('pivh', 2.08, 30, (PIV.x, 0, PIV.z), axis='Y', verts=48))
    # lightening hole + stamped number boss, like a real lever
    boolean(o, cyl('lh', 2.2, 30, (-13.0, 0, 6.5), axis='Y', verts=48))
    ang = lift / (STUMP_X - PIV.x)
    o.matrix_world = Matrix.Translation(PIV) @ Matrix.Rotation(-ang, 4, 'Y') @ Matrix.Translation(-PIV)
    put(o, MAT['brass'], 0.18, 3)
    # flat spring riveted at the rear top, pressing on the case top flange
    M_ = o.matrix_world
    a = M_ @ Vector((-12.0, 0, 12.6)); tip = Vector((8.0, 0, 27.6))
    mid1 = M_ @ Vector((-6.0, 0, 13.6))
    path = [(a.x, a.z + 0.1), (mid1.x, mid1.z + 0.5), ((mid1.x + tip.x) / 2, (mid1.z + tip.z) / 2 + 2.6), (tip.x - 2.5, tip.z - 0.4), (tip.x, tip.z)]
    sp = flat_tool('spring%d' % i, path, 0.55, LT - 0.3, y0 + LT / 2, tip='round'); sp.data.materials[0] = MAT['blued']
    rv = M_ @ Vector((-11.0, 0, 12.4))
    r = screw_head('rivet%d' % i, (rv.x, y0 - 0.02, rv.z + 0.4), 1.0, 0.55, axis='-Y', slot=False, kind='dome', mat=MAT['steel'])
    # stamped lever number (raised dots are too fussy; a punched dot pattern = lever position)
    for k in range(i + 1):
        d = M_ @ Vector((-17.5 + k * 1.3, 0, 9.2))
        dot = cyl('punch', 0.32, 0.3, (d.x, y0 - 0.05, d.z), axis='Y', verts=16); boolean(o, dot)
    return o

levers = [make_lever(i, *L) for i, L in enumerate(LEVERS)]
# spacer washers on the pivot + pivot post with a riveted head
for i in range(len(LEVERS)):
    y0 = LEVERS[i][0] + LT
    y1 = LEVERS[i + 1][0] if i + 1 < len(LEVERS) else 9.0
    w = lathe_x('spacer', [(0, 2.05), (0, 3.4), (y1 - y0, 3.4), (y1 - y0, 2.05)], seg=64)
    w.data.transform(Matrix.Rotation(math.pi / 2, 4, 'Z')); w.location = (PIV.x, y0, PIV.z); put(w, MAT['bolt'], 0.08, 2)
post = cyl('post', 2.0, BACK_Y - 0.6, (PIV.x, (BACK_Y + 0.6) / 2, PIV.z), axis='Y', verts=48); put(post, MAT['steel'], 0.05)
screw_head('post_head', (PIV.x, 0.62, PIV.z), 2.9, 0.75, axis='-Y', slot=False, kind='dome', mat=MAT['steel'])

# ---------------------------------------------------------------- bolt (cast brass) with steel stump and talon
bolt = box('bolt', -9.0, 38.0, 9.0, 13.6, -6.5, 6.5)
boolean(bolt, box('talon', -1.0, 3.2, 0, 20, -7, -4.2))
boolean(bolt, box('tail_slot', -9.5, -4.0, 0, 20, -2.0, 2.0))        # guide slot riding on a case stud
boolean(bolt, box('relief', 30, 40, 0, 20, 5.2, 7))
put(bolt, MAT['bolt'], 0.35, 3)
stump = cyl('stump', STUMP_R, 9.0 - 0.3, (STUMP_X, (9.0 + 0.3) / 2, 0.0), axis='Y', verts=64); put(stump, MAT['steel'], 0.12, 2)
screw_head('stud', (-6.6, 9.0, 0), 1.7, 0.6, axis='-Y', slot=False, kind='dome', mat=MAT['steel'])
put(cyl('stud_post', 1.8, 5.2, (-6.6, 11.4, 0), axis='Y', verts=32), MAT['steel'], 0.05)

if DETECTOR:
    det = prism('detector', [(10.2, 2.4), (16.5, 2.4), (16.5, 7.8), (14.0, 9.5), (10.2, 9.5)], 8.25, 8.95)
    det.matrix_world = levers[2].matrix_world.copy(); put(det, MAT['blued'], 0.1)

# ---------------------------------------------------------------- case: back plate + flanges (black japanned steel)
CX0, CX1, CZ0, CZ1, FL = -30.0, 26.0, -30.0, 30.0, 1.5
back = box('back', CX0, CX1, BACK_Y, BACK_Y + FL, CZ0, CZ1)
kh = cyl('kh', 3.3, 10, (-3.0, BACK_Y, -18.0), axis='Y', verts=64); boolean(kh, box('khs', -4.6, -1.4, BACK_Y - 5, BACK_Y + 5, -25.5, -18), 'UNION')
boolean(back, kh); put(back, MAT['case'], 0.3, 3)
top = box('top', CX0, CX1, 0.0, BACK_Y, CZ1 - FL, CZ1); put(top, MAT['case'], 0.3, 3)
bot = box('bottom', CX0, CX1, 0.0, BACK_Y, CZ0, CZ0 + FL); put(bot, MAT['case'], 0.3, 3)
rear = box('rearwall', CX0, CX0 + FL, 0.0, BACK_Y, CZ0, CZ1); put(rear, MAT['case'], 0.3, 3)
# bolt guide bridge and cover-screw posts (brass bosses, tapped)
for (px, pz) in [(-25.5, 24.5), (-25.5, -24.5), (20.5, -24.5), (21.0, 23.0)]:
    p = cyl('boss', 2.4, BACK_Y - 0.4, (px, (BACK_Y + 0.4) / 2, pz), axis='Y', verts=48)
    boolean(p, cyl('tap', 1.0, 30, (px, 0, pz), axis='Y', verts=24)); put(p, MAT['screw'], 0.15, 2)
gb = box('guide', 18.0, 26.0, 0.0, 9.0, 6.6, 8.0); put(gb, MAT['case'], 0.2, 2)
gb2 = box('guide2', 18.0, 26.0, 0.0, 9.0, -8.0, -6.6); put(gb2, MAT['case'], 0.2, 2)
# forend: brass plate, wider than the case, with countersunk screws
fe = box('forend', CX1, CX1 + 3.0, -3.5, BACK_Y + FL + 3.5, -46, 46)
boolean(fe, box('fehole', CX1 - 1, CX1 + 4, 8.8, 13.8, -6.7, 6.7)); put(fe, MAT['forend'], 0.4, 3)
for zz in (-40.0, 40.0):
    s = screw_head('fscrew', (CX1 + 3.0, BACK_Y / 2, zz), 3.4, 1.0, axis='X', slot=True, kind='pan', mat=None, rot=math.radians(30 if zz > 0 else 75)); put(s, MAT['screw'], 0.05, 2)

# ---------------------------------------------------------------- door stile (painted oak) with mortise, frame jamb + strike
stile = box('stile', -90, CX1, -6.0, 40.0, -120, 120)
boolean(stile, box('mortise', CX0 - 0.4, CX1 + 1, -0.0, BACK_Y + FL + 0.3, CZ0 - 0.4, CZ1 + 0.4))
boolean(stile, box('cutfront', -100, CX1 + 10, -20, 0.0, -130, 130))
put(stile, MAT['wood'], 0.4, 3)
jamb = box('jamb', CX1 + 4.2, 120, 0.0, 60, -120, 120)
boolean(jamb, box('strike_pocket', CX1 + 3, CX1 + 18, 8.0, 14.4, -7.6, 7.6)); put(jamb, MAT['wood'], 0.4, 3)
sk = box('strike', CX1 + 4.2, CX1 + 6.0, -3.0, BACK_Y + 5, -30, 30)
boolean(sk, box('skh', CX1 + 3, CX1 + 7, 8.4, 14.2, -7.2, 7.2)); boolean(sk, box('cutfront2', CX1, CX1 + 8, -10, 0.0, -40, 40))
put(sk, MAT['forend'], 0.3, 3)
put(box('strike_dark', CX1 + 9, CX1 + 18.5, 7.0, 15.4, -8, 8), MAT['dark'])

# ---------------------------------------------------------------- tools through the back keyhole (two-piece lever crank)
# lifter: 1.3 mm wire, shaft along Y out through the keyhole, bent up under the belly of L1
belly1 = levers[0].matrix_world @ Vector((-3.5, 0, LEVERS[0][3]))
lp = [Vector((-3.0, 40, -16.6)), Vector((-3.0, 2.9, -16.6)), Vector((-3.0, 1.7, -15.6)), Vector((-3.2, 1.7, belly1.z - 0.7))]
cu = bpy.data.curves.new('lifter', 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = 0.65; cu.bevel_resolution = 4
sp = cu.splines.new('BEZIER'); sp.bezier_points.add(len(lp) - 1)
for bp, p in zip(sp.bezier_points, lp): bp.co = p; bp.handle_left_type = bp.handle_right_type = 'AUTO'
lo = bpy.data.objects.new('lifter', cu); bpy.context.collection.objects.link(lo); cu.materials.append(MAT['wire'])
# tension arm: flat stock through the keyhole slot, tip in the bolt talon
ta = flat_tool('tension', [(-3.0, -24.5), (-3.0, -12.0), (-1.6, -8.4), (0.4, -6.0), (0.6, -5.0)], 1.6, 0.9, 11.2, tip='flat')
ta.data.materials[0] = MAT['pick']
tb = box('tension_shaft', -3.8, -2.2, 11.2, 60, -25.4, -23.6); put(tb, MAT['pick'], 0.3)

# ---------------------------------------------------------------- light + camera
world_hdri(float(arg('--world', '0.05')), sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (-2, 6, 0)
kx, ky, kz, ks, ke = [float(v) for v in arg('--key', '-90,-110,140,40,160000').split(',')]
area_light('key', (kx, ky, kz), AIM, ks, ke, (1.0, 0.84, 0.66))
area_light('fill', (140, -110, -20), AIM, 90, float(arg('--fill', '2500')), (0.94, 0.96, 1.0))
area_light('rim', (40, -20, -130), AIM, 40, float(arg('--rim', '3000')), (1.0, 0.95, 0.9))
cam = look_camera((float(arg('--tx', '-1')), 6, float(arg('--tz', '-2'))), float(arg('--yaw', '32')), float(arg('--pitch', '-18')),
                  float(arg('--dist', '190')), lens=float(arg('--lens', '120')))
mirror_softbox('sheen', (0, 0, 0), cam, size=float(arg('--ss', '25')), size_y=float(arg('--ssy', '60')), energy=float(arg('--sheen', '15000')),
               shift=(float(arg('--sx', '-6')), 0, float(arg('--sz', '4'))))
render_setup(OUT, RES, SAMPLES, exposure=float(arg('--exp', '0.0')), crop=CROP)
bpy.ops.render.render(write_still=True)
print('WROTE', scene.render.filepath)
