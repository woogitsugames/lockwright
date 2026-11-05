# Lockwright — the locksmith's workshop bench (hub / menu screen). 1 unit = 1 mm.
#   blender -b -t 2 -P art/blender/workshop.py -- --out art/renders/workshop.png --res 2160x3840 --samples 160
# Laminated beech bench against a limewashed brick wall: bench vice holding a practice cylinder, an invented
# key-cutting machine, pegboard with hand tools and a pick set, key-blank board, a glass showcase of opened
# locks on a shelf, an articulated lamp (warm key light), notebook, phone, clipboard with dispatch slips.
# Diegetic menu: the mockup writes onto the tags, slip, notebook label and phone screen via <out>.json anchors.
import bpy, math, os, sys, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_common import *
from env_common import _bev
from lw_common import flat_tool
from mathutils import Vector, Matrix

arg = cli()
OUT = arg('--out', 'art/renders/test_workshop.png'); RES = [int(v) for v in arg('--res', '540x960').split('x')]
SAMPLES = int(arg('--samples', '32')); CROP = arg('--crop', '')
rng = random.Random(5)
BZ = 900                                   # bench top height
BY0, BY1 = -690, -30                       # bench front / back

# ---------------------------------------------------------------- materials
bricks = brick_wall('bricks', brick=(0.34, 0.19, 0.13), seed=2, wash_amt=0.95)
plaster = lime_wall('plaster', (0.66, 0.64, 0.58), seed=8, dirt=0.4, cracks=0.4)
ceil_m = lime_wall('ceil', (0.62, 0.60, 0.55), seed=9, dirt=0.3, cracks=0.2)
concrete = terrazzo('concrete', matrix=(0.34, 0.33, 0.31), seed=6)
vice_paint = paint('vice_paint', (0.05, 0.10, 0.14), rough=0.38, metal_col=(0.42, 0.42, 0.41), chip=0.9, grime=0.8)
mach_paint = paint('mach_paint', (0.10, 0.13, 0.11), rough=0.35, metal_col=(0.45, 0.45, 0.44), chip=0.6, grime=0.8)
lamp_paint = paint('lamp_paint', (0.07, 0.12, 0.09), rough=0.3, metal_col=(0.5, 0.5, 0.48), chip=0.5, grime=0.5)
steel = metal('steel', (0.58, 0.58, 0.57), 0.28, marks='grind', marks_scale=0.6, wear=0.5, grime=0.7, smudge=0.6, bevel_r=0.4)
bright = metal('bright_steel', (0.70, 0.70, 0.69), 0.18, marks='turn', marks_axis=(1, 0, 0), wear=0.3, grime=0.5, bevel_r=0.3)
dark_steel = metal('dark_steel', (0.22, 0.22, 0.22), 0.4, marks='stamp', wear=0.6, grime=0.6, bevel_r=0.3)
brass = metal('brass', (0.80, 0.58, 0.30), 0.28, marks='stamp', wear=0.5, grime=0.7, patina=0.5, bevel_r=0.3)
nickel = metal('nickel', (0.66, 0.65, 0.62), 0.24, marks='stamp', wear=0.4, grime=0.5, bevel_r=0.3)
iron_old = iron('iron_old', rust=0.5, scale=0.5)
brass_c = metal('brass_clean', (0.86, 0.64, 0.34), 0.2, marks='grind', marks_scale=2.0, wear=0.3, grime=0.3, patina=0.1, bevel_r=0.3)
pegboard_m = None
handle_wood = oak('handle_wood', light=(0.55, 0.36, 0.18), dark=(0.30, 0.16, 0.07), axis='Z', ring=1.5, coat=0.4, seed=3, wear=0.8)
amber = plastic('amber', (0.45, 0.20, 0.03), rough=0.15)
red_dip = plastic('red_dip', (0.28, 0.035, 0.025), rough=0.5)
black_pl = plastic('black_pl', (0.02, 0.02, 0.02), rough=0.35)
felt = rubber('felt', (0.03, 0.09, 0.05), rough=0.95)
glass_m = glass('case_glass', (0.96, 0.98, 0.97), rough=0.0, dirt=0.6)
manila = paper('manila', (0.62, 0.48, 0.30), grime=0.4, seed=4)
slip_m = paper('slip', (0.83, 0.81, 0.75), grime=0.1, seed=1, lines=(8.0, 'Y', (0.72, 0.74, 0.76)))
pad_m = paper('pad', (0.80, 0.78, 0.72), grime=0.25, seed=2)
label_m = paper('label', (0.84, 0.82, 0.74), grime=0.3, seed=6)
cotton = paper('string', (0.75, 0.72, 0.64), fibre=0.5)
hardboard = plastic('hardboard', (0.15, 0.085, 0.04), rough=0.55, seed=2, grime=0.6, sheen_scuffs=0.5)
cover = oil_paint('notebook_cover', (0.07, 0.11, 0.16), rough=0.6, under=(0.5, 0.45, 0.35), base=(0.45, 0.4, 0.3), chips=0.2,
                  scuffs=0.8, strokes='Y', seed=3, chip_scale=0.05, edge_chips=1.5)
cloth = rubber('cloth', (0.05, 0.04, 0.035), rough=0.9)
screen_m = bpy.data.materials.new('screen'); screen_m.use_nodes = True
sb = screen_m.node_tree.nodes['Principled BSDF']; sb.inputs['Base Color'].default_value = (0.005, 0.005, 0.006, 1)
sb.inputs['Roughness'].default_value = 0.04; sb.inputs['Coat Weight'].default_value = 1.0; sb.inputs['Coat Roughness'].default_value = 0.02
alu = metal('alu', (0.55, 0.55, 0.56), 0.35, marks='grind', marks_scale=2, wear=0.2, grime=0.3, bevel_r=0.5)
mug_m = enamel('mug_enamel', (0.78, 0.77, 0.72), rough=0.1, chip=0.7)
mug_rim = enamel('mug_rim', (0.02, 0.06, 0.22), rough=0.1, chip=0.7)
tea = bpy.data.materials.new('tea'); tea.use_nodes = True
tb = tea.node_tree.nodes['Principled BSDF']; tb.inputs['Base Color'].default_value = (0.05, 0.02, 0.008, 1); tb.inputs['Roughness'].default_value = 0.02
void = dark_mat('void')

def beech(seed, center, width=40):
    l = jitter((0.40, 0.26, 0.14), 0.14, rng); d = jitter((0.24, 0.13, 0.06), 0.14, rng)
    c = list(center); c[2] += rng.uniform(-0.4, 0.4) * width
    return oak('beech%d' % seed, light=l, dark=d, axis='X', seed=seed, ring=rng.uniform(2.0, 3.5), incline=rng.uniform(-0.04, 0.04),
               depth=rng.uniform(80, 200), coat=0.0, rough=0.55, wear=0.9, grime=0.9, pores=0.35, flecks=0.6, center=tuple(c), contrast=0.6)

# ---------------------------------------------------------------- room
bx('wall', -1800, 1800, 0, 250, 0, 3000, bricks)
bx('wall_l', -1900, -1800, -3200, 250, 0, 3000, plaster)
bx('wall_r', 1800, 1900, -3200, 250, 0, 3000, plaster)
bx('wall_b', -1900, 1900, -3300, -3200, 0, 3000, plaster)
bx('ceiling', -1900, 1900, -3300, 250, 3000, 3100, ceil_m)
bx('floor', -1900, 1900, -3300, 250, -50, 0, concrete)

# ---------------------------------------------------------------- bench: laminated beech strips, apron, drawer
SW = 41.25
for i in range(16):
    y0 = BY0 + i * SW; y1 = y0 + SW - 0.4
    bx('strip%d' % i, -1150, 1150, y0, y1, BZ - 60, BZ, beech(10 + i, (0, (y0 + y1) / 2, BZ - 30)), bev=1.2, seg=2)
# wear decal: oil stains, mug rings, cut marks (transparent where clean)
dm = bpy.data.materials.new('bench_grime'); dm.use_nodes = True; nt = dm.node_tree; l = nt.links
from env_common import _noise, _mix, _maprange, _math, _sep, _bump
outn = nt.nodes['Material Output']; pb = nt.nodes['Principled BSDF']
P = nt.nodes.new('ShaderNodeTexCoord').outputs['Object']; X, Y, Z = _sep(nt, P)
stain = _maprange(nt, _noise(nt, P, 0.006, detail=8, rough=0.7, dist=0.5), 0.58, 0.72, 0, 0.6)
spots = _maprange(nt, _noise(nt, P, 0.05, detail=6, rough=0.6), 0.74, 0.77, 0, 0.4)
def ring_mask(cx, cy, r, w):
    dx = _math(nt, 'SUBTRACT', X, cx); dy = _math(nt, 'SUBTRACT', Y, cy)
    d = _math(nt, 'SQRT', _math(nt, 'ADD', _math(nt, 'MULTIPLY', dx, dx), _math(nt, 'MULTIPLY', dy, dy)))
    return _maprange(nt, _math(nt, 'ABSOLUTE', _math(nt, 'SUBTRACT', d, r)), w, 0)
rings = _math(nt, 'MAXIMUM', ring_mask(-60, -300, 41, 2.2), ring_mask(-10, -330, 41, 1.6))
rings = _math(nt, 'MULTIPLY', rings, _maprange(nt, _noise(nt, P, 0.08, detail=4), 0.3, 0.7, 0.2, 0.8))
cuts = _noise(nt, P, 0.04, detail=10, rough=0.75, stretch=(0.02, 1.0, 1.0))
cutm = _maprange(nt, _math(nt, 'ABSOLUTE', _math(nt, 'SUBTRACT', cuts, 0.5)), 0.006, 0.0)
cutm = _math(nt, 'MULTIPLY', cutm, _maprange(nt, _noise(nt, P, 0.01, detail=2), 0.55, 0.6))
mask = _math(nt, 'MINIMUM', _math(nt, 'ADD', _math(nt, 'ADD', stain, spots), _math(nt, 'ADD', rings, cutm)), 1.0)
pb.inputs['Base Color'].default_value = (0.05, 0.03, 0.015, 1); pb.inputs['Roughness'].default_value = 0.35
tr = nt.nodes.new('ShaderNodeBsdfTransparent'); ms = nt.nodes.new('ShaderNodeMixShader')
l.new(mask, ms.inputs[0]); l.new(tr.outputs[0], ms.inputs[1]); l.new(pb.outputs[0], ms.inputs[2]); l.new(ms.outputs[0], outn.inputs['Surface'])
decal = bx('bench_grime', -1150, 1150, BY0, BY1, BZ + 0.05, BZ + 0.06, dm)
decal.visible_shadow = False
# apron + drawer + legs
apron = beech(40, (0, BY0, BZ - 120))
bx('apron', -1150, 1150, BY0 + 10, BY0 + 32, BZ - 190, BZ - 60, apron, bev=2)
dw = beech(41, (0, BY0, BZ - 125))
bx('drawer', -330, 330, BY0 + 4, BY0 + 12, BZ - 180, BZ - 70, dw, bev=1.5)
for x in (-1080, 1080):
    bx('leg', x - 45, x + 45, BY0 + 20, BY0 + 110, 0, BZ - 60, beech(42 + x // 1000, (x, BY0 + 65, 400)), bev=3)
pull = lathe_x('pull', [(0, 0.01), (0, 14), (3, 14), (5, 6), (14, 5), (18, 9), (22, 9), (24, 0.01)], seg=48)
pull.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); pull.location = (0, BY0 + 4, BZ - 125); setmat(pull, brass)
# card holder on the drawer (label slot)
fr = slab('dr_frame', rounded_rect(84, 36, 3), 1.6, brass, bev=0.4)
cut(fr, place(slab('dr_win', rounded_rect(72, 24, 2), 8), (0, 0, -3)))
place(fr, (0, BY0 + 3, BZ - 95), rot=(90, 0, 0))
bx('dr_card', -38, 38, BY0 + 3.2, BY0 + 3.8, BZ - 112, BZ - 78, label_m)

# ---------------------------------------------------------------- pegboard + tools
PX0, PX1, PZ0, PZ1, PY = -30, 660, 990, 1720, -22
pm = bpy.data.materials.new('pegboard'); pm.use_nodes = True; nt = pm.node_tree; l = nt.links; pb = nt.nodes['Principled BSDF']
P = nt.nodes.new('ShaderNodeTexCoord').outputs['Object']; X, Y, Z = _sep(nt, P)
fx = _math(nt, 'SUBTRACT', _math(nt, 'FRACT', _math(nt, 'DIVIDE', X, 25.4)), 0.5)
fz = _math(nt, 'SUBTRACT', _math(nt, 'FRACT', _math(nt, 'DIVIDE', Z, 25.4)), 0.5)
dd = _math(nt, 'SQRT', _math(nt, 'ADD', _math(nt, 'MULTIPLY', fx, fx), _math(nt, 'MULTIPLY', fz, fz)))
hole = _maprange(nt, dd, 0.135, 0.115)
base = _mix(nt, (0.27, 0.16, 0.085, 1), (0.20, 0.115, 0.06, 1), _noise(nt, P, 0.01, detail=6))
base = _mix(nt, base, (0.12, 0.07, 0.04, 1), _maprange(nt, _noise(nt, P, 0.003, detail=5, rough=0.7), 0.55, 0.75, 0, 0.6))
l.new(_mix(nt, base, (0.008, 0.006, 0.005, 1), hole), pb.inputs['Base Color'])
l.new(_maprange(nt, _noise(nt, P, 0.6, detail=4), 0.3, 0.7, 0.55, 0.75), pb.inputs['Roughness'])
l.new(_bump(nt, _math(nt, 'SUBTRACT', _math(nt, 'MULTIPLY', _noise(nt, P, 0.8, detail=3), 0.2), hole), 0.6, 1.5), pb.inputs['Normal'])
bx('pegboard', PX0, PX1, PY, PY + 5, PZ0, PZ1, pm, bev=1)
for x in (PX0 + 20, PX1 - 20):
    bx('batten', x - 15, x + 15, PY + 5, 0, PZ0, PZ1, beech(60, (x, -10, 1300)))
def hole_pt(i, j): return (PX0 + 12.7 + 25.4 * i, PZ0 + 12.7 + 25.4 * j)
def peg(i, j, length=45, up=14):
    x, z = hole_pt(i, j)
    return tube('peg', [(x, PY + 5, z), (x, PY - length, z), (x, PY - length - 6, z + up)], 2.4, bright, res=3)
# hammer (head up) on two pegs
hx, hz = hole_pt(25, 9)
peg(24, 18); peg(26, 18)
lathe('hammer_handle', [(0.1, 1060), (13, 1062), (15, 1100), (12.5, 1250), (11, 1370), (12, 1440), (0.1, 1442)], 0, 0, seg=32).location = (hx, PY - 30, 0)
bpy.data.objects['hammer_handle'].data.materials.append(handle_wood)
hh = bx('hammer_head', hx - 55, hx + 55, PY - 45, PY - 15, 1440, 1474, dark_steel, bev=3)
bx('hammer_face', hx + 55, hx + 70, PY - 44, PY - 16, 1441, 1473, bright, bev=4, seg=4)
# screwdriver rack: wooden strip with four drivers, handles up
bx('sd_rack', 30, 300, PY - 60, PY, 1585, 1605, beech(61, (165, -50, 1595)), bev=2)
for k, (mat_h, L, r) in enumerate(((amber, 105, 15), (handle_wood, 95, 14), (amber, 90, 13), (red_dip, 80, 11), (handle_wood, 70, 10))):
    x = 60 + k * 55
    lathe('sd_h', [(0.1, 1605), (r * 0.55, 1606), (r * 0.8, 1612), (r, 1630), (r, 1605 + L - 15), (r * 0.8, 1605 + L - 4), (0.1, 1605 + L)],
          x, PY - 30, seg=40).data.materials.append(mat_h)
    shaft = 160 - k * 18
    lathe('sd_s', [(0.1, 1600 - shaft), (r * 0.25, 1600 - shaft + 2), (r * 0.25, 1606)], x, PY - 30, seg=24).data.materials.append(bright)
    bx('sd_tip', x - r * 0.33, x + r * 0.33, PY - 31, PY - 29, 1600 - shaft - 10, 1600 - shaft + 4, bright, bev=0.4)
# pick set on a magnetic strip
bx('mag_strip', 40, 330, PY - 14, PY, 1395, 1420, black_pl, bev=2)
tips = [
    [(0, 0), (0, -150), (0.3, -158), (2.2, -160), (3.0, -157)],                        # short hook
    [(0, 0), (0, -145), (1.5, -152), (3.5, -152), (1.0, -158)],                        # half diamond
    [(0, 0), (0, -125), (1.4, -129), (-0.4, -134), (1.4, -139), (-0.4, -144), (1.2, -149), (0, -156)],  # rake
    [(0, 0), (0, -150), (0.5, -156), (2.6, -159), (4.6, -156)],                        # deep hook
    [(0, 0), (0, -150), (0.8, -154), (0.8, -158)],                                     # ball-ish
    [(0, 0), (0, -120), (1.6, -126), (-0.4, -131), (1.8, -136), (0, -141), (1.6, -146), (0, -152)],
]
for k, t in enumerate(tips):
    x0 = 70 + k * 40
    flat_tool('pick%d' % k, [(x0 + u * 3.2, 1415 + v) for u, v in t], 2.6, 0.7, PY - 16)
    bx('pick_grip%d' % k, x0 - 4.5, x0 + 4.5, PY - 20, PY - 12, 1330, 1412, red_dip if k % 2 else black_pl, bev=2.5, seg=4)
for k in range(2):  # tension wrenches
    x0 = 320 - k * 12
    flat_tool('wrench%d' % k, [(x0, 1416), (x0, 1300), (x0 - 1, 1294), (x0 - 14, 1293)], 3.2, 0.9, PY - 16, tip='flat')
# two files and pliers on pegs
for k, (x0, L) in enumerate(((420, 210), (470, 180))):
    i, j = int((x0 - PX0) / 25.4), 26
    peg(i, j, 40, 10)
    x, z = hole_pt(i, j)
    lathe('file_h', [(0.1, z - 12), (8, z - 14), (11, z - 40), (12, z - 95), (9, z - 108), (0.1, z - 110)], x, PY - 36, seg=32).data.materials.append(handle_wood)
    f = prism('file', [(x - 2, z - 108), (x + 2, z - 108), (x + 9, z - 125), (x + 6, z - 108 - L), (x - 6, z - 108 - L), (x - 9, z - 125)], PY - 40, PY - 32)
    setmat(f, dark_steel); _bev(f, 0.6, 2)
def pliers(name, x, z, ang):
    out = []
    for s in (-1, 1):
        pts = [(0, 0), (s * 7, -4), (s * 9, -30), (s * 6, -55), (s * 4, -60), (s * 16, -75), (s * 22, -160), (s * 15, -162), (s * 6, -78), (s * -2, -58), (s * -3, -30), (s * -2, -6)]
        R = Matrix.Rotation(math.radians(ang), 3, 'Y')
        p = prism(name + str(s), [(x + (R @ Vector((u, 0, v))).x, z + (R @ Vector((u, 0, v))).z) for u, v in pts], PY - 48 - (s + 1) * 4, PY - 42 - (s + 1) * 4)
        setmat(p, steel); _bev(p, 0.8, 2); out.append(p)
        g = tube(name + 'g' + str(s), [(x + (R @ Vector((s * 12, 0, -85))).x, PY - 45 - (s + 1) * 4, z + (R @ Vector((s * 12, 0, -85))).z),
                                     (x + (R @ Vector((s * 19, 0, -158))).x, PY - 45 - (s + 1) * 4, z + (R @ Vector((s * 19, 0, -158))).z)], 6.5, red_dip)
    cyl(name + 'pivot', 5.5, 18, (x + (R @ Vector((0, 0, -40))).x, PY - 45, z + (R @ Vector((0, 0, -40))).z), axis='Y', verts=24).data.materials.append(bright)
peg(22, 13, 50, 12); pliers('pliers', hole_pt(22, 13)[0], hole_pt(22, 13)[1] + 70, 180)
# ---------------------------------------------------------------- key blank board (left, under the shelf)
KX0, KX1, KZ0, KZ1 = -610, -170, 985, 1270
bx('kb_board', KX0, KX1, -24, 0, KZ0, KZ1, beech(70, (-390, -12, 1170), 300), bev=2)
def blank_outline(kind):
    blade = [(-4.5, 1.5), (-4.5, -6), (-4.2, -36), (-1, -40), (4.2, -36), (4.2, -6), (4.5, 1.5)]
    if kind == 0:
        bow = [(13 * math.cos(math.radians(a)), 13 + 13 * math.sin(math.radians(a))) for a in range(-60, 241, 10)]
    else:
        bow = [(12, 2), (14, 6), (14, 22), (10, 27), (-10, 27), (-14, 22), (-14, 6), (-12, 2)]
    return blade + bow
blank_me = {}
for kind in (0, 1):
    o = prism('blank_proto%d' % kind, blank_outline(kind), -1.0, 1.0)
    cut(o, cyl('bh', 3.2, 6, (0, 0, 17), axis='Y', verts=24)); _bev(o, 0.3, 1); setmat(o, brass_c)
    blank_me[kind] = o
for r_ in range(3):
    for c_ in range(8):
        x = KX0 + 38 + c_ * 52; z = KZ1 - 40 - r_ * 100
        tube('kb_hook', [(x, -24, z), (x, -36, z), (x, -40, z + 6)], 1.4, bright, res=2)
        for n in range(rng.randint(1, 3)):
            kind = rng.randint(0, 1); src = blank_me[kind]
            b = src.copy(); b.data = src.data; bpy.context.collection.objects.link(b)
            b.material_slots[0].link = 'OBJECT'; b.material_slots[0].material = rng.choice((brass_c, brass_c, nickel))
            b.matrix_world = Matrix.Translation(Vector((x, -32 - n * 2.2, z - 19 + 6))) @ Matrix.Rotation(math.radians(rng.uniform(-6, 6)), 4, 'Y')
for k in (0, 1):
    blank_me[k].hide_render = True

# ---------------------------------------------------------------- shelf + glass showcase (opened locks)
SH_Z, SX0_, SX1_ = 1330, -640, -45
bx('shelf', SX0_, SX1_, -250, 0, SH_Z - 28, SH_Z, beech(80, (-360, -125, SH_Z - 14), 200), bev=2)
for x in (SX0_ + 60, SX1_ - 60):
    tube('bracket', [(x, -6, SH_Z - 200), (x, -6, SH_Z - 30), (x, -200, SH_Z - 30), (x, -6, SH_Z - 200)], 6, vice_paint, smooth_pts=False)
CX0, CX1, CY0, CY1, CZ0, CZ1 = -570, -70, -235, -20, SH_Z, SH_Z + 270
case_wood = oak('case_wood', light=(0.30, 0.16, 0.07), dark=(0.10, 0.045, 0.02), axis='X', seed=17, ring=3.5, coat=1.0, coat_rough=0.12,
                varnish_tint=0.2, center=(0, CY0, CZ0 + 20))
bx('case_base', CX0, CX1, CY0, CY1, CZ0, CZ0 + 45, case_wood, bev=2.5)
bx('case_felt', CX0 + 12, CX1 - 12, CY0 + 12, CY1 - 12, CZ0 + 45, CZ0 + 48, felt)
bx('case_back', CX0 + 18, CX1 - 18, CY1 - 20, CY1 - 18, CZ0 + 45, CZ1 - 18, paper('linen', (0.36, 0.32, 0.25), fibre=1.0, seed=7))
for x0, x1 in ((CX0, CX0 + 18), (CX1 - 18, CX1)):
    for y0, y1 in ((CY0, CY0 + 18), (CY1 - 18, CY1)):
        bx('case_post', x0, x1, y0, y1, CZ0 + 45, CZ1, case_wood, bev=1.5)
bx('case_top_f', CX0, CX1, CY0, CY0 + 18, CZ1 - 18, CZ1, case_wood, bev=1.5)
bx('case_top_b', CX0, CX1, CY1 - 18, CY1, CZ1 - 18, CZ1, case_wood, bev=1.5)
bx('case_glass_f', CX0 + 18, CX1 - 18, CY0 + 7, CY0 + 10, CZ0 + 45, CZ1 - 18, glass_m)
bx('case_glass_t', CX0 + 2, CX1 - 2, CY0 + 2, CY1 - 2, CZ1, CZ1 + 4, glass_m)
for x in (CX0 + 7, CX1 - 11):
    bx('case_glass_s', x, x + 3, CY0 + 18, CY1 - 18, CZ0 + 45, CZ1 - 18, glass_m)
knob = lathe_x('case_knob', [(0, 0.01), (0, 5), (6, 6), (10, 9), (13, 8), (14, 0.01)], seg=32)
knob.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); knob.location = ((CX0 + CX1) / 2, CY0, CZ0 + 22); setmat(knob, brass)
# exhibits: open padlock, warded box lock with its key, wooden pin lock
FZ = CZ0 + 48
EXP = -470
pl = slab('ex_padlock', rounded_rect(54, 46, 6), 20, brass, bev=1.5); place(pl, (EXP, -140, FZ + 23), rot=(90, 0, 0))
sh = tube('ex_shackle', [(EXP - 16, -150, FZ + 44), (EXP - 16, -150, FZ + 92), (EXP, -150, FZ + 108), (EXP + 16, -150, FZ + 92), (EXP + 16, -150, FZ + 72)], 4.5, bright)
bl = bx('ex_boxlock', -405, -260, -170, -150, FZ, FZ + 110, iron_old, bev=2)
cut(bl, prism('kh', [(-337, FZ + 70), (-327, FZ + 70), (-329, FZ + 52), (-325, FZ + 34), (-339, FZ + 34), (-335, FZ + 52)], -200, -100))
bx('ex_boxlock_back', -401, -264, -150, -144, FZ + 4, FZ + 106, void)
for x, z in ((-395, FZ + 10), (-270, FZ + 10), (-395, FZ + 100), (-270, FZ + 100)):
    screw_head('bl_screw', (x, -170.5, z), 4, 2, axis='-Y', mat=iron_old, rot=rng.uniform(0, 3))
key = lathe_x('ex_key', [(0, 0.01), (0, 4), (70, 4), (72, 6), (78, 6), (80, 4), (84, 4), (84, 0.01)], seg=24)
key.location = (-405, -205, FZ + 6); key.rotation_euler = (0, 0, math.radians(14)); setmat(key, iron_old)
tor = tube('ex_key_ring', [(-405 + 14 * math.cos(a) - 14, -205 - 3 * math.sin(a), FZ + 6 + 14 * math.sin(a)) for a in [i * math.pi / 8 for i in range(17)]], 3, iron_old)
bit = bx('ex_key_bit', -327, -317, -205 - 2, -205 + 2, FZ + 6 - 18, FZ + 6, iron_old, bev=0.8)
wl = bx('ex_woodlock', -215, -105, -190, -130, FZ, FZ + 70, oak('ex_wood', light=(0.5, 0.36, 0.2), dark=(0.3, 0.18, 0.08), axis='X', seed=4,
                                                               ring=2.5, coat=0.1, center=(-170, -160, FZ + 35)), bev=4)
bx('ex_woodbolt', -240, -85, -175, -150, FZ + 25, FZ + 45, oak('ex_bolt', light=(0.45, 0.30, 0.15), dark=(0.25, 0.14, 0.06), axis='X', seed=5,
                                                               ring=2.5, coat=0.1, center=(-170, -160, FZ + 35)), bev=3)

# ---------------------------------------------------------------- bench vice with a practice cylinder
VX, VY = -250, -380
bx('vice_base', VX - 80, VX + 80, VY - 60, VY + 60, BZ, BZ + 14, vice_paint, bev=3)
for sx in (-1, 1):
    for sy in (-1, 1):
        screw_head('vb', (VX + sx * 62, VY + sy * 42, BZ + 14), 7, 5, axis='Z', slot=False, kind='pan', mat=dark_steel)
def casting(name, prof, half_w, mat):
    o = prism(name, prof, -half_w, half_w)
    o.data.transform(Matrix.Translation(Vector((VX, VY, BZ))) @ Matrix.Rotation(math.radians(90), 4, 'Z'))
    setmat(o, mat); _bev(o, 5, 4, 30); return o
casting('vice_rear', [(-4, 14), (62, 14), (78, 26), (82, 58), (72, 90), (54, 102), (40, 122), (-4, 122)], 68, vice_paint)
bx('vice_anvil', VX - 45, VX + 45, VY + 55, VY + 110, BZ + 100, BZ + 122, vice_paint, bev=5)
bx('vice_slide', VX - 32, VX + 32, VY - 210, VY + 40, BZ + 40, BZ + 92, bright, bev=2)
casting('vice_front', [(-90, 34), (-32, 34), (-32, 122), (-58, 122), (-78, 104), (-90, 72)], 68, vice_paint)
jaw_m = metal('jaw', (0.5, 0.5, 0.49), 0.35, marks='grind', marks_axis=(0, 0, 1), marks_scale=3, marks_amt=2.5, wear=0.6, grime=0.8, bevel_r=0.3)
bx('jaw_r', VX - 66, VX + 66, VY - 4, VY + 2, BZ + 92, BZ + 122, jaw_m, bev=0.8)
bx('jaw_f', VX - 66, VX + 66, VY - 32, VY - 26, BZ + 92, BZ + 122, jaw_m, bev=0.8)
lathe_x('vice_screw', [(0, 0.01), (0, 11), (150, 11), (150, 0.01)], seg=32).data.materials.append(bright)
s_ = bpy.data.objects['vice_screw']; s_.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); s_.location = (VX, VY - 85, BZ + 66)
boss = cyl('vice_boss', 20, 36, (VX, VY - 250, BZ + 66), axis='Y', verts=48); setmat(boss, vice_paint); _bev(boss, 2, 3)
tbar = cyl('vice_tbar', 7, 240, (VX + 40, VY - 255, BZ + 66), axis='X', verts=24); setmat(tbar, bright)
for x in (VX + 40 - 125, VX + 40 + 125):
    o = lathe_x('tknob', [(0, 0.01), (0, 9), (3, 12), (14, 12), (17, 9), (18, 0.01)], seg=32); o.location = (x - 9, VY - 255, BZ + 66); setmat(o, bright)
# practice cylinder clamped upright: round body, milled window exposing five pin chambers
PCX, PCZ = VX, BZ + 122
body = lathe('pc_body', [(0.1, PCZ - 40), (11, PCZ - 40), (11.4, PCZ + 48), (10, PCZ + 50), (0.1, PCZ + 50)], PCX, VY - 14, seg=64)
setmat(body, nickel)
cut(body, bx('pc_win', PCX - 30, PCX + 30, VY - 40, VY - 20, PCZ + 6, PCZ + 46))
bx('pc_dark', PCX - 9, PCX + 9, VY - 13, VY - 10, PCZ + 6, PCZ + 46, void)
for k in range(5):
    z = PCZ + 10 + k * 7.5
    setmat(cyl('pc_kpin', 1.5, 6.5, (PCX - 4, VY - 17, z), axis='X', verts=16), brass)
    setmat(cyl('pc_dpin', 1.5, 6.0 - (k % 3), (PCX + 3, VY - 17, z), axis='X', verts=16), bright)
face = lathe('pc_face', [(0.1, PCZ + 50), (8.5, PCZ + 50), (9, PCZ + 52), (0.1, PCZ + 52)], PCX, VY - 14, seg=48); setmat(face, brass)

# ---------------------------------------------------------------- key-cutting machine (invented, generic)
KMX, KMY = 270, -290
km_base = slab('km_base', rounded_rect(330, 230, 24), 55, mach_paint, bev=6, seg=4); place(km_base, (KMX, KMY, BZ))
for sx in (-1, 1):
    for sy in (-1, 1):
        cyl('km_foot', 14, 8, (KMX + sx * 140, KMY + sy * 90, BZ + 2), verts=24).data.materials.append(black_pl)
mot = lathe_x('km_motor', [(0, 0.01), (0, 48), (6, 55), (180, 55), (186, 48), (186, 0.01)], seg=64)
mot.location = (KMX - 95, KMY + 70, BZ + 135); setmat(mot, mach_paint)
for k in range(9):
    bx('km_fin', KMX - 70 + k * 16, KMX - 66 + k * 16, KMY + 70 - 57, KMY + 70 + 57, BZ + 135 - 57, BZ + 135 + 57, mach_paint, bev=1.5)
bx('km_post', KMX - 30, KMX + 30, KMY + 40, KMY + 100, BZ + 55, BZ + 90, mach_paint, bev=4)
shaft = lathe_x('km_shaft', [(0, 0.01), (0, 6), (260, 6), (260, 0.01)], seg=24); shaft.location = (KMX - 130, KMY + 5, BZ + 125); setmat(shaft, bright)
cutter = lathe_x('km_cutter', [(0, 0.01), (0, 34), (1, 36), (5, 36), (6, 34), (6, 0.01)], seg=96); cutter.location = (KMX + 82, KMY + 5, BZ + 125)
cm_ = metal('cutter', (0.62, 0.62, 0.6), 0.22, marks='turn', marks_axis=(1, 0, 0), marks_scale=4, marks_amt=2, wear=0.2, grime=0.3)
setmat(cutter, cm_)
guard = cyl('km_guard', 44, 16, (KMX + 85, KMY + 5, BZ + 125), axis='X', verts=64)
cut(guard, cyl('gin', 41, 13, (KMX + 85, KMY + 5, BZ + 125), axis='X', verts=64))
cut(guard, bx('gcut', KMX + 60, KMX + 110, KMY - 60, KMY + 5, BZ + 60, BZ + 132)); setmat(guard, mach_paint); _bev(guard, 0.6, 2)
trc = lathe_x('km_tracer', [(0, 0.01), (0, 9), (20, 9), (28, 2), (30, 0.01)], seg=32); trc.location = (KMX - 140, KMY + 5, BZ + 125); setmat(trc, bright)
# carriage with two clamps holding the original key and a blank
bx('km_rail', KMX - 140, KMX + 140, KMY - 70, KMY - 50, BZ + 55, BZ + 68, bright, bev=1)
car = bx('km_carriage', KMX - 125, KMX + 125, KMY - 60, KMY - 20, BZ + 68, BZ + 105, mach_paint, bev=3)
for cx in (KMX - 92, KMX + 92):
    bx('km_clamp', cx - 22, cx + 22, KMY - 40, KMY - 4, BZ + 105, BZ + 118, bright, bev=1)
    o = lathe('km_knob', [(0.1, BZ + 118), (5, BZ + 118), (5, BZ + 130), (14, BZ + 132), (15, BZ + 142), (12, BZ + 146), (0.1, BZ + 147)], cx, KMY - 22, seg=24)
    setmat(o, black_pl)
for cx, teeth in ((KMX - 92, True), (KMX + 92, False)):
    prof = [(-38, 0), (-38, 8)] + ([(-30, 8), (-27, 4), (-22, 8), (-17, 3), (-12, 8), (-7, 5), (-3, 8)] if teeth else []) + [(0, 8), (4, 4), (4, 0)]
    b = prism('km_key', [(cx + u + 30, BZ + 112 + v) for u, v in prof], KMY - 13, KMY - 11)
    setmat(b, brass if teeth else nickel); _bev(b, 0.2, 1)
lever = tube('km_lever', [(KMX + 125, KMY - 40, BZ + 86), (KMX + 170, KMY - 60, BZ + 90), (KMX + 210, KMY - 150, BZ + 105)], 5, bright)
bl_ = lathe('km_ball', [(0.1, -16), (9, -14), (14, -6), (15, 0), (14, 6), (9, 14), (0.1, 16)], KMX + 214, KMY - 158, seg=32)
bl_.location.z = BZ + 108; setmat(bl_, black_pl)
bx('km_tray', KMX + 40, KMX + 130, KMY - 45, KMY + 45, BZ + 55, BZ + 58, steel, bev=0.5)
bx('km_plate', KMX - 60, KMX + 20, KMY - 117, KMY - 115, BZ + 12, BZ + 40, brass, bev=0.5)   # blank plate (no maker)
# brass shavings scattered on the tray and the bench
sh_me = bpy.data.meshes.new('shaving'); import bmesh as _bm; bm_ = _bm.new()
_bm.ops.create_cube(bm_, size=1.0)
for v in bm_.verts: v.co = Vector((v.co.x * 1.6, v.co.y * 0.5, v.co.z * 0.25))
bm_.to_mesh(sh_me); bm_.free()
for n in range(260):
    if n < 120: p = (KMX + rng.uniform(45, 125), KMY + rng.uniform(-40, 40), BZ + 58.2)
    else:
        a = rng.uniform(0, 6.28); r = abs(rng.gauss(0, 70)); p = (KMX + 90 + math.cos(a) * r * 1.4, KMY - 80 + math.sin(a) * r, BZ + 0.2)
    o = bpy.data.objects.new('shav', sh_me); bpy.context.collection.objects.link(o); o.location = p
    o.rotation_euler = (rng.uniform(0, 0.6), rng.uniform(0, 0.6), rng.uniform(0, 6.28)); o.scale = (rng.uniform(0.4, 1.4),) * 3
sh_me.materials.append(brass)

# ---------------------------------------------------------------- articulated lamp (warm key light)
LBX, LBY = 720, -140
bx('lamp_clamp', LBX - 25, LBX + 25, LBY - 25, LBY + 25, BZ, BZ + 40, lamp_paint, bev=4)
LT = Vector((float(arg('--lampx', '170')), float(arg('--lampy', '-600')), float(arg('--lampz', '1640'))))
J1 = Vector((LBX, LBY, BZ + 40)); J2 = Vector((LBX - 60, LBY - 120, BZ + 640)); J3 = LT + Vector((60, 40, 50))
for a, b in ((J1, J2), (J2, J3)):
    d = (b - a); n = Vector((0, 0, 1)).cross(d).normalized() * 9
    tube('lamp_arm', [a + n, b + n], 4.5, lamp_paint, smooth_pts=False); tube('lamp_arm', [a - n, b - n], 4.5, lamp_paint, smooth_pts=False)
    tube('lamp_spring', [a + (b - a) * 0.15 + Vector((0, 0, 18)), a + (b - a) * 0.75 + Vector((0, 0, 18))], 3, bright, smooth_pts=False)
for j in (J1, J2, J3):
    cyl('lamp_joint', 12, 30, tuple(j), axis='Y', verts=32).data.materials.append(bright)
HEAD = LT
AIMV = Vector((VX + 40, VY - 60, BZ)) - HEAD
SHADE_ROT = AIMV.to_track_quat('-Z', 'Y').to_euler()
SPROF = [(16, 72), (24, 60), (26, 40), (50, 10), (72, -20), (77, -27)]
inside = paint('shade_in', (0.75, 0.72, 0.64), rough=0.4, chip=0.0, grime=0.6)
shade = lathe_open('lamp_shade', SPROF, thick=0.9, mat=lamp_paint)
shade_in = lathe_open('lamp_shade_in', [(r - 1.2, z) for r, z in SPROF], thick=0.3, mat=inside)
cap = lathe('lamp_cap', [(0.1, 66), (17, 66), (17, 84), (10, 92), (0.1, 92)], 0, 0, seg=32); setmat(cap, lamp_paint)
for o in (shade, shade_in, cap):
    o.location = HEAD; o.rotation_euler = SHADE_ROT
bulbm = emissive('bulb', (1.0, 0.72, 0.45), 30.0, (0.9, 0.85, 0.8))
bulb = lathe('lamp_bulb', [(0.1, -18), (12, -14), (17, 0), (14, 14), (9, 22), (8, 32), (0.1, 33)], 0, 0, seg=32)
bulb.location = HEAD; bulb.rotation_euler = SHADE_ROT; bulb.data.materials.append(bulbm)
bulb.visible_shadow = False

# ---------------------------------------------------------------- bench items: notebook, phone, clipboard, mug, padlocks, pencil
NBX, NBY, NBR = -40, -300, 11
for z0, nm in ((0, 'nb_back'), (7.6, 'notebook')):
    nb = slab(nm, rounded_rect(152, 212, 3), 1.45, cover, bev=0.5); place(nb, (NBX, NBY, BZ + z0), rot=(0, 0, NBR))
bx('nb_pages', -72, 74, -104, 104, 1.45, 7.6, pad_m).data.transform(Matrix.Translation(Vector((NBX, NBY, BZ))) @ Matrix.Rotation(math.radians(NBR), 4, 'Z'))
sp_ = bx('nb_spine', -80, -64, -107, 107, -0.3, 9.4, cloth, bev=1.5); sp_.data.transform(Matrix.Translation(Vector((NBX, NBY, BZ))) @ Matrix.Rotation(math.radians(NBR), 4, 'Z'))
NB_M = Matrix.Translation(Vector((NBX, NBY, BZ + 9.05))) @ Matrix.Rotation(math.radians(NBR), 4, 'Z')
lab = slab('nb_label', rounded_rect(96, 44, 4), 0.2, label_m); lab.matrix_world = NB_M @ Matrix.Translation(Vector((6, 40, 0)))
nb_label = [NB_M @ Vector((6 + u, 40 + v, 0.25)) for u, v in ((-44, 18), (44, 18), (44, -18), (-44, -18))]
pen = lathe_x('pencil', [(0, 0.01), (0, 1.0), (16, 3.6), (18, 3.7), (170, 3.7), (170, 0.01)], seg=6)
pen.location = (NBX - 70, NBY - 50, BZ + 13); pen.rotation_euler = (0, 0, math.radians(32))
pen_m = oil_paint('pencil_paint', (0.55, 0.36, 0.05), rough=0.3, chips=0.1, scuffs=0.1, strokes='X'); setmat(pen, pen_m)
# phone, screen up
PHX, PHY, PHR = 35, -600, -10
ph = slab('phone', rounded_rect(74, 152, 10, 6), 8, alu, bev=2.4, seg=4); place(ph, (PHX, PHY, BZ), rot=(0, 0, PHR))
scr = slab('phone_glass', rounded_rect(71, 149, 9, 6), 0.4, screen_m, bev=0.15); place(scr, (PHX, PHY, BZ + 7.8), rot=(0, 0, PHR))
PH_M = Matrix.Translation(Vector((PHX, PHY, BZ + 8.3))) @ Matrix.Rotation(math.radians(PHR), 4, 'Z')
phone_screen = [PH_M @ Vector((u, v, 0)) for u, v in ((-33, 70), (33, 70), (33, -70), (-33, -70))]
# clipboard with the dispatch pad (Continuous mode: the shift)
CBM = Matrix.Translation(Vector((250, -555, BZ + 0.1))) @ Matrix.Rotation(math.radians(8), 4, 'Z')
clip_m = metal('clip', (0.60, 0.60, 0.58), 0.3, marks='stamp', wear=0.4, grime=0.5, bevel_r=0.5)
cb_objs, cb_corner = clipboard('clipboard', CBM, slip_m, pad_m, hardboard, clip_m, rng=rng)
slip = [cb_corner(0, 0), cb_corner(148, 0), cb_corner(148, 210), cb_corner(0, 210)]
# mug of tea
MX, MY = 115, -150
mug = lathe_open('mug', [(0.1, BZ), (38, BZ), (40, BZ + 3), (40, BZ + 92), (41.5, BZ + 95)], MX, MY, thick=2.2, mat=mug_m)
lathe('mug_rim', [(37.5, BZ + 93.5), (41.8, BZ + 93.5), (41.8, BZ + 96.5), (37.5, BZ + 96.5)], MX, MY, seg=64).data.materials.append(mug_rim)
cyl('tea', 37.5, 1, (MX, MY, BZ + 72), verts=64).data.materials.append(tea)
tube('mug_handle', [(MX + 38, MY, BZ + 78), (MX + 62, MY, BZ + 74), (MX + 66, MY, BZ + 45), (MX + 58, MY, BZ + 22), (MX + 38, MY, BZ + 20)], 5.5, mug_m)
# two padlocks (practice locks)
def padlock(name, x, y, rz, w=58, h=50, d=24, mat=brass, shackle_h=44):
    M_ = Matrix.Translation(Vector((x, y, BZ))) @ Matrix.Rotation(math.radians(rz), 4, 'Z') @ Matrix.Rotation(math.radians(-90), 4, 'X')
    bdy = slab(name, rounded_rect(w, h, 7), d, mat, bev=1.6, seg=3)       # lies on its back (front face up)
    bdy.matrix_world = Matrix.Translation(Vector((x, y, BZ + d))) @ Matrix.Rotation(math.radians(rz), 4, 'Z') @ Matrix.Rotation(math.radians(180), 4, 'X')
    R = Matrix.Translation(Vector((x, y, BZ + d / 2))) @ Matrix.Rotation(math.radians(rz), 4, 'Z')
    sw = w * 0.32
    pts = [R @ Vector((-sw, h / 2 - 5, 0)), R @ Vector((-sw, h / 2 + shackle_h * 0.6, 0)), R @ Vector((0, h / 2 + shackle_h, 0)),
           R @ Vector((sw, h / 2 + shackle_h * 0.6, 0)), R @ Vector((sw, h / 2 - 5, 0))]
    tube(name + '_shackle', pts, 5, bright)
    kh = R @ Vector((0, -h / 4, d / 2 + 0.1))
    bx(name + '_kw', kh.x - 1.2, kh.x + 1.2, kh.y - 5, kh.y + 5, BZ + d - 0.3, BZ + d + 0.05, void)
padlock('padlock1', 520, -440, -28)
padlock('padlock2', -10, -470, 22, w=46, h=40, d=20, mat=dark_steel, shackle_h=36)
# loose keys on a ring
for k in range(3):
    kk = prism('lkey', [(u, v) for u, v in blank_outline(k % 2)], -1.0, 1.0)
    setmat(kk, brass_c if k else nickel)
    kk.matrix_world = Matrix.Translation(Vector((95 + k * 12, -440 + k * 4, BZ + 1.5 + k * 2.2))) @ Matrix.Rotation(math.radians(30 + k * 40), 4, 'Z') @ Matrix.Rotation(math.radians(90), 4, 'X')
tube('keyring', [(103 + 12 * math.cos(a), -425 + 12 * math.sin(a), BZ + 4) for a in [i * math.pi / 8 for i in range(17)]], 1.2, bright)

# ---------------------------------------------------------------- tags (diegetic menu labels)
tag_vice = tag('tag_vice', Matrix.Translation(Vector((VX + 115, VY - 175, BZ + 0.3))) @ Matrix.Rotation(math.radians(14), 4, 'Z'),
               manila, brass, string_to=(VX + 40 + 112, VY - 255, BZ + 60), string_mat=cotton)
tag_case = tag('tag_case', Matrix.Translation(Vector(((CX0 + CX1) / 2 + 30, CY0 - 16, CZ0 - 34))) @ Matrix.Rotation(math.radians(-4), 4, 'Y') @
               Matrix.Rotation(math.radians(90), 4, 'X'), manila, brass, string_to=((CX0 + CX1) / 2, CY0 - 12, CZ0 + 22), string_mat=cotton)

# ---------------------------------------------------------------- lights
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, -350, BZ)
world_hdri(0.03, 'interior.exr', sat=0.3)
bpy.ops.object.light_add(type='AREA', location=tuple(HEAD)); sp = bpy.context.object
sp.data.shape = 'DISK'; sp.data.size = 60; sp.data.spread = math.radians(80)
sp.data.energy = 2.6e7; sp.data.color = (1.0, 0.70, 0.42); sp.rotation_euler = SHADE_ROT
# window on the left wall: evening, cool; plus a dim warm practical bounce from the room
area_light('window', (-1750, -900, 1900), AIM, 1200, 1.0e7, (0.70, 0.80, 1.0), size_y=1400)
area_light('room', (600, -2900, 2600), AIM, 1800, 2.5e6, (1.0, 0.82, 0.62))
# showcase light: a warm strip under the case lid
a_case = bpy.data.objects.new('aim_case', None); scene.collection.objects.link(a_case); a_case.location = ((CX0 + CX1) / 2, (CY0 + CY1) / 2 - 30, CZ0)
area_light('case_light', ((CX0 + CX1) / 2, CY1 - 40, CZ1 - 22), a_case, 420, 7e5, (1.0, 0.8, 0.58), size_y=40)

# ---------------------------------------------------------------- camera + render
cam = photo_camera((-20, -930, 1650), yaw=0.0, lens=18.0, pitch=-39.0, shift=(0.0, 0.045))
cam.data.sensor_fit = 'VERTICAL'; cam.data.sensor_height = 36.0; cam.data.sensor_width = 36.0
render_setup(OUT, RES, SAMPLES, crop=tuple(float(v) for v in CROP.split(',')) if CROP else None, exposure=-0.25, look='AgX - Medium High Contrast', bounces=10)
scene.cycles.adaptive_threshold = 0.01
photo_finish(0.28)
write_anchors(os.path.splitext(os.path.abspath(OUT))[0] + '.json', {
    'slip': slip, 'notebook_label': nb_label, 'phone_screen': phone_screen, 'tag_vice': tag_vice, 'tag_case': tag_case,
    'case': [(CX0, CY0, CZ1), (CX1, CY0, CZ1), (CX1, CY0, CZ0), (CX0, CY0, CZ0)],
    'vice': [(VX - 90, VY - 40, BZ + 180), (VX + 90, VY - 40, BZ + 180), (VX + 90, VY - 260, BZ), (VX - 90, VY - 260, BZ)],
    'machine': [(KMX - 165, KMY - 60, BZ + 200), (KMX + 165, KMY - 60, BZ + 200), (KMX + 165, KMY - 115, BZ), (KMX - 165, KMY - 115, BZ)],
    'drawer_card': [(-34, BY0 + 3, BZ - 83), (34, BY0 + 3, BZ - 83), (34, BY0 + 3, BZ - 107), (-34, BY0 + 3, BZ - 107)],
})
bpy.ops.render.render(write_still=True)
print('WROTE', scene.render.filepath)
