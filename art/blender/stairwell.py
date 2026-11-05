# Lockwright — job arrival shot: a tenement apartment door on a stairwell landing. 1 unit = 1 mm.
#   blender -b -t 2 -P art/blender/stairwell.py -- --out art/renders/stairwell.png --res 2160x3840 --samples 160 [--night]
# Panelled oak door with an invented modern cylinder and long escutcheon, enamel number plate, card nameplate,
# coir doormat, oil-paint wainscot (lamperia) under lime paint, terrazzo landing, stair flight with handrail,
# timer light switch and an opal wall lamp. A clipboard with the dispatch slip is held in the foreground
# (blank paper: the mockup writes the job onto it through anchors exported to <out>.json).
# --night: timer light off; cold stairwell window, a lamp left on inside the flat leaks under the door.
import bpy, math, os, sys, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_common import *
from env_common import _bev
from mathutils import Vector, Matrix

arg = cli()
OUT = arg('--out', 'art/renders/test_stairwell.png'); RES = [int(v) for v in arg('--res', '540x960').split('x')]
SAMPLES = int(arg('--samples', '32')); NIGHT = '--night' in sys.argv; NUMBER = arg('--number', '12')
HAIR = arg('--hair', '1') == '1'
rng = random.Random(11)

# ---------------------------------------------------------------- materials
WALL_GREEN = (0.055, 0.115, 0.082)
lamperia = oil_paint('lamperia', WALL_GREEN, rough=0.28, under=(0.42, 0.30, 0.16), base=(0.62, 0.58, 0.50), chips=0.45,
                     scuffs=0.6, strokes='Z', seed=1, chip_scale=0.012)
stripe = oil_paint('stripe', (0.20, 0.045, 0.03), rough=0.3, chips=0.3, scuffs=0.2, strokes='X', seed=2)
upper = lime_wall('lime', (0.72, 0.68, 0.58), seed=3, dirt=0.55, cracks=0.6)
ceiling = lime_wall('ceiling', (0.70, 0.67, 0.60), seed=5, dirt=0.3, cracks=0.3)
cream = oil_paint('architrave', (0.62, 0.56, 0.43), rough=0.32, under=(0.30, 0.42, 0.33), base=(0.32, 0.2, 0.1), chips=0.35,
                  scuffs=0.3, strokes='Z', seed=4, chip_scale=0.03, edge_chips=1.0)
floor = terrazzo('terrazzo', matrix=(0.36, 0.34, 0.31), chip_scale=1.6, mute=0.35, seed=1, worn_center=(0, -700), worn_r=(700, 650))
steel = metal('satin_steel', (0.62, 0.62, 0.60), 0.26, aniso=0.5, marks='grind', marks_axis=(0, 0, 1), marks_scale=0.3,
              wear=0.3, grime=0.4, smudge=0.6, bevel_r=0.6)
nickel = metal('cyl_nickel', (0.66, 0.65, 0.62), 0.22, marks='turn', marks_axis=(0, 1, 0), wear=0.3, grime=0.6, bevel_r=0.3)
brass = metal('brass', (0.80, 0.58, 0.30), 0.3, marks='stamp', wear=0.5, grime=0.7, patina=0.6, bevel_r=0.4)
black_iron = paint('rail_iron', (0.025, 0.024, 0.022), rough=0.45, metal_col=(0.3, 0.29, 0.28), chip=0.5, grime=0.6)
bakelite = plastic('bakelite', (0.06, 0.035, 0.02), rough=0.25)
blue = enamel('enamel_blue', (0.012, 0.05, 0.20), chip=0.6)
white_en = enamel('enamel_white', (0.80, 0.80, 0.76), chip=0.0)
card = paper('name_card', (0.78, 0.74, 0.64), grime=0.4, seed=3)
slip = paper('slip', (0.83, 0.81, 0.75), grime=0.1, seed=1, lines=(8.0, 'Y', (0.70, 0.72, 0.74)))
pad_paper = paper('pad', (0.80, 0.78, 0.72), grime=0.2, seed=2)
hardboard = oak('hardboard', light=(0.30, 0.18, 0.09), dark=(0.22, 0.12, 0.06), ring=40, coat=0.3, pores=0.0, seed=9, wear=0.6)
rail_wood = oak('handrail', light=(0.42, 0.24, 0.11), dark=(0.16, 0.08, 0.035), axis='Y', seed=7, ring=2.0, coat=1.0,
                coat_rough=0.15, wear=0.8, varnish_tint=0.2)
dark = dark_mat('void', (0.01, 0.009, 0.008))
mat_rubber = rubber('mat_rubber')

def door_wood(axis, seed, center=(0, 0, 0), width=120):
    """Each piece gets its own log: pith offset across the board (so arches sit off-centre), own ring width and tone."""
    l = jitter((0.33, 0.20, 0.10), 0.14, rng); d = jitter((0.12, 0.06, 0.028), 0.12, rng)
    c = list(center)
    k = {'Z': 0, 'X': 2, 'Y': 0}[axis]                      # across-board coordinate
    c[k] += rng.uniform(-0.3, 0.3) * width
    return oak('door_%s_%d' % (axis, seed), light=l, dark=d, axis=axis, seed=seed, ring=rng.uniform(1.7, 2.8),
               incline=rng.choice((-1, 1)) * rng.uniform(0.03, 0.06), depth=rng.uniform(70, 160), coat=1.0, coat_rough=0.22,
               rough=0.5, wear=0.6, grime=0.8, flecks=0.0, varnish_tint=0.3, center=tuple(c), contrast=0.72)

# ---------------------------------------------------------------- architecture
W0, W1 = -1700, 1900          # back wall extent (x)
WT = 380                       # wall thickness (door reveal)
CEIL = 3350
DX0, DX1, DTOP = -470, 470, 2130   # door opening
LAMP_Z, STRIPE = 1500, 22

def wall_bands(name, x0, x1, y0, y1, holes=()):
    """Back wall split into lamperia / stripe / lime bands; holes = list of cutter-boxes args."""
    parts = []
    for nm, z0, z1, mt in (('lamp', 0, LAMP_Z, lamperia), ('str', LAMP_Z, LAMP_Z + STRIPE, stripe), ('lime', LAMP_Z + STRIPE, CEIL, upper)):
        o = bx('%s_%s' % (name, nm), x0, x1, y0, y1, z0, z1, mt)
        for h in holes:
            if h[4] < z1 and h[5] > z0: cut(o, bx('hole', *h))
        _bev(o, 1.5, 2, 30); parts.append(o)
    return parts

wall_bands('back', W0, W1, 0, WT, holes=[(DX0, DX1, -10, WT + 10, -10, DTOP)])
# lime wall bevel would round the band joints; the stripe sits 1 mm proud like a painted line over the joint
# side wall (left), wall behind the camera, ceiling, floor
wall_bands('left', -1700 - WT, -1700, -4200, 0)
bx('behind', -2200, 2400, -4300, -4200, 0, CEIL, upper)
bx('ceiling', -2200, 2400, -4300, WT, CEIL, CEIL + 200, ceiling)
bx('floor', -1700, 2400, -4300, 0, -60, 0, floor)
# skirting: terrazzo cove 90 mm along walls (darker matrix)
skirt = terrazzo('skirting', matrix=(0.30, 0.29, 0.27), seed=4)
bx('skirt_l', W0, DX0 - 95, -14, 0, 0, 95, skirt, bev=3)
bx('skirt_r', DX1 + 95, 700, -14, 0, 0, 95, skirt, bev=3)
bx('skirt_side', -1700, -1686, -4200, 0, 0, 95, skirt, bev=3)
# door reveal lining is part of the wall bands (the hole faces); threshold
bx('threshold', DX0, DX1, -22, 120, 0, 20, door_wood('X', 21, (0, 50, 10), 100), bev=3)

# ---------------------------------------------------------------- architrave + jamb (painted, chipped)
AW, AP = 95, 24
for x0, x1 in ((DX0 - AW, DX0), (DX1, DX1 + AW)):
    bx('arch_v', x0, x1, -AP, 0, 0, DTOP + AW, cream, bev=2.5)
    xb = (x0, x0 + 22) if x0 < 0 else (x1 - 22, x1)                 # back band (outer step)
    bx('arch_band', xb[0], xb[1], -AP - 9, -AP + 1, 0, DTOP + AW, cream, bev=2.5)
bx('arch_h', DX0 + 0.5, DX1 - 0.5, -AP + 0.5, 0, DTOP, DTOP + AW - 0.5, cream, bev=2.5)
bx('arch_hb', DX0 - AW + 22.5, DX1 + AW - 22.5, -AP - 9, -AP + 1, DTOP + AW - 22, DTOP + AW, cream, bev=2.5)
for x0, x1 in ((DX0, DX0 + 24), (DX1 - 24, DX1)):
    bx('jamb', x0, x1, 0, 150, 0, DTOP, cream, bev=1.5)
bx('jamb_h', DX0, DX1, 0, 150, DTOP - 24, DTOP, cream, bev=1.5)
bx('stop_h', DX0 + 24, DX1 - 24, 112, 150, DTOP - 40, DTOP - 24, cream, bev=1)

# ---------------------------------------------------------------- door leaf (separate stiles/rails/panels)
LX0, LX1, LZ0, LZ1, LY = DX0 + 26, DX1 - 26, 24, DTOP - 26, 60      # leaf front at y = 60, back at 105
SW, TR, LR0, LR1, BR, MW = 120, 125, 905, 1080, 215, 92
pieces = [
    ('stile_l', LX0, LX0 + SW, LZ0, LZ1, 'Z'), ('stile_r', LX1 - SW, LX1, LZ0, LZ1, 'Z'),
    ('rail_t', LX0 + SW, LX1 - SW, LZ1 - TR, LZ1, 'X'), ('rail_lock', LX0 + SW, LX1 - SW, LR0, LR1, 'X'),
    ('rail_b', LX0 + SW, LX1 - SW, LZ0, LZ0 + BR, 'X'),
    ('mun_u', -MW / 2, MW / 2, LR1, LZ1 - TR, 'Z'), ('mun_l', -MW / 2, MW / 2, LZ0 + BR, LR0, 'Z'),
]
for i, (nm, x0, x1, z0, z1, ax) in enumerate(pieces):
    bx(nm, x0, x1, LY, LY + 45, z0, z1, door_wood(ax, 30 + i, ((x0 + x1) / 2, LY, (z0 + z1) / 2), min(x1 - x0, z1 - z0)), bev=1.6, seg=2)
panels = [(LX0 + SW, -MW / 2, LR1, LZ1 - TR), (MW / 2, LX1 - SW, LR1, LZ1 - TR),
          (LX0 + SW, -MW / 2, LZ0 + BR, LR0), (MW / 2, LX1 - SW, LZ0 + BR, LR0)]

def raised_panel(name, x0, x1, z0, z1, y_field=64, y_flat=74, inset=42, mat=None):
    """Raised-and-fielded panel: flat margin at y_flat, sloped bevel up to the field at y_field."""
    bm = bmesh.new()
    def ring(xa, xb, za, zb, y): return [bm.verts.new(p) for p in ((xa, y, za), (xb, y, za), (xb, y, zb), (xa, y, zb))]
    a = ring(x0, x1, z0, z1, y_flat + 14)              # back
    bfl = ring(x0, x1, z0, z1, y_flat)                 # margin plane at the frame
    c = ring(x0 + 12, x1 - 12, z0 + 12, z1 - 12, y_flat)
    d = ring(x0 + inset, x1 - inset, z0 + inset, z1 - inset, y_field + 3)
    e = ring(x0 + inset + 6, x1 - inset - 6, z0 + inset + 6, z1 - inset - 6, y_field)
    for r1, r2 in ((a, bfl), (bfl, c), (c, d), (d, e)):
        for i in range(4): bm.faces.new((r1[i], r1[(i + 1) % 4], r2[(i + 1) % 4], r2[i]))
    bm.faces.new(list(reversed(a))); bm.faces.new(e)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); o.data.materials.append(mat)
    _bev(o, 1.2, 2, 20); return o

for i, (x0, x1, z0, z1) in enumerate(panels):
    raised_panel('panel%d' % i, x0, x1, z0, z1, mat=door_wood('Z', 50 + i, ((x0 + x1) / 2, 70, (z0 + z1) / 2), x1 - x0))
    # bolection moulding: quarter-round strip around the panel opening
    mo = door_wood('Z', 60 + i, ((x0 + x1) / 2, 61, (z0 + z1) / 2), 30)
    pts = [(x0 + 1, 61, z0 + 1), (x1 - 1, 61, z0 + 1), (x1 - 1, 61, z1 - 1), (x0 + 1, 61, z1 - 1), (x0 + 1, 61, z0 + 1)]
    t = tube('mould%d' % i, pts, 9, mo, smooth_pts=False); t.data.bevel_resolution = 3

# ---------------------------------------------------------------- hardware
HX, HZ, CZ = LX1 - 62, 1050, 1050 - 72          # handle and cylinder centres on the lock stile
# long escutcheon: rounded slab on the door face
esc = slab('escutcheon', rounded_rect(46, 252, 10), 8, steel, bev=1.6)
place(esc, (HX, LY, HZ - 36), rot=(90, 0, 0))    # slab +Z -> world -Y (towards the corridor)
cut(esc, cyl('cylhole', 9.4, 40, (HX, LY - 4, CZ), axis='Y', verts=64))
# invented cylinder face: round front with a short tower (not a real profile), keyway with two wards
cyl_front = lathe_x('cyl_face', [(0, 0.01), (0, 8.2), (0.8, 8.9), (3.6, 8.9), (3.6, 0.01)], seg=96)
cyl_front.data.transform(Matrix.Rotation(math.radians(90), 4, 'Z')); cyl_front.location = (HX, LY - 11.5, CZ)
setmat(cyl_front, nickel); _bev(cyl_front, 0.3, 2, 30)
plug = cyl('plug', 6.1, 3.0, (HX, LY - 10.0, CZ), axis='Y', verts=96); setmat(plug, brass)
kw = bx('keyway', HX - 1.0, HX + 1.0, LY - 20, LY + 5, CZ - 5.2, CZ + 3.4)
boolean(kw, bx('kwa', HX - 2.0, HX + 2.0, LY - 20, LY + 5, CZ - 2.4, CZ - 0.9), 'UNION')
cut(plug, kw); cut(cyl_front, cyl('plughole', 6.3, 30, (HX, LY - 10, CZ), axis='Y', verts=96))
bx('kw_dark', HX - 2.5, HX + 2.5, LY - 9.0, LY - 8.5, CZ - 6, CZ + 4, dark)
# lever handle: rose + bent round bar
rose = lathe_x('rose', [(0, 0.01), (0, 17), (3, 17), (6, 13), (9, 11), (9, 0.01)], seg=64)
rose.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); rose.location = (HX, LY - 8, HZ); setmat(rose, steel)
lever = tube('lever', [(HX, LY - 12, HZ), (HX, LY - 48, HZ), (HX - 6, LY - 62, HZ), (HX - 30, LY - 66, HZ),
                       (HX - 135, LY - 64, HZ - 2)], 9.5, steel, res=6)
# peephole and card nameplate
ph = lathe_x('peep', [(0, 0.01), (0, 16), (2, 15.5), (4, 12), (5, 8), (5, 0.01)], seg=64)
ph.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); ph.location = (0, LY, 1585); setmat(ph, brass)
lens_m = glass('peep_glass', (0.3, 0.32, 0.3)) if not NIGHT else emissive('peep_glow', (1.0, 0.62, 0.3), 0.6, (0.05, 0.04, 0.03))
cyl('peep_lens', 6.5, 1, (0, LY - 5.3, 1585), axis='Y', verts=48).data.materials.append(lens_m)
NP = (0, LY, 1478); NPW, NPH = 118, 40
frame = slab('nameframe', rounded_rect(NPW, NPH, 3), 2.2, brass, bev=0.5)
cut(frame, place(slab('win', rounded_rect(NPW - 14, NPH - 12, 1.5), 10), (0, 0, -4)))
place(frame, (NP[0], NP[1] - 1, NP[2]), rot=(90, 0, 0))
nc = bx('namecard', NP[0] - NPW / 2 + 5, NP[0] + NPW / 2 - 5, LY - 0.9, LY - 0.4, NP[2] - NPH / 2 + 4, NP[2] + NPH / 2 - 4, card)
for sx in (-1, 1):
    screw_head('np_screw', (NP[0] + sx * (NPW / 2 - 3.5), LY - 3.2, NP[2]), 1.8, 1.0, axis='-Y', mat=brass, rot=rng.uniform(0, 3))
# enamel number plate: domed, slightly crooked, on the top rail
EP = (0, LY, LZ1 - TR / 2); EW, EH = 128, 88
ep = slab('enamel_plate', rounded_rect(EW, EH, 12), 2.0, blue, bev=1.4, seg=4)
ep_rot = (90, 1.6, 0)
inner = slab('enamel_line', rounded_rect(EW - 14, EH - 14, 7), 0.25, white_en)
cut(inner, place(slab('enamel_line_in', rounded_rect(EW - 20, EH - 20, 5), 4.0), (0, 0, -1))); place(inner, (0, 0, 2.0))
num = text_obj('number', NUMBER, 56, extrude=0.15, mat=white_en); bpy.context.view_layer.update()
num.data.offset_y = -1.0
for o in (ep, inner):
    place(o, (EP[0], EP[1] - 1, EP[2]), rot=ep_rot)
num.matrix_world = Matrix.Translation(Vector((EP[0], EP[1] - 3.3, EP[2] - 2))) @ Matrix.Rotation(math.radians(ep_rot[1]), 4, 'Y') @ Matrix.Rotation(math.radians(90), 4, 'X')
for sx, sz in ((-1, 1), (1, -1)):
    screw_head('ep_screw', (EP[0] + sx * (EW / 2 - 9), LY - 3.5, EP[2] + sz * (EH / 2 - 9)), 2.2, 1.2, axis='-Y', mat=steel, rot=rng.uniform(0, 3))
# old repaired hole from a previous lock: dowel plug in the stile (story: the door has had locks before)
bx('old_plug', HX - 9, HX + 9, LY - 0.2, LY + 2, 1260 - 9, 1260 + 9, door_wood('Y', 77), bev=4, seg=4)

# ---------------------------------------------------------------- doorbell, timer switch, conduit, lamp
bp = slab('bell_plate', rounded_rect(52, 72, 4), 6, bakelite, bev=1.2); place(bp, (DX1 + AW + 95, 0, 1450), rot=(90, 0, 0))
bb = cyl('bell_btn', 9, 8, (DX1 + AW + 95, -8, 1458), axis='Y', verts=48); setmat(bb, plastic('bell_btn', (0.55, 0.50, 0.40), 0.3)); _bev(bb, 1.5, 3)
SWX, SWZ = DX0 - AW - 165, 1360
sbox = lathe_x('switch_box', [(0, 0.01), (0, 38), (18, 36), (26, 30), (28, 0.01)], seg=64)
sbox.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); sbox.location = (SWX, 0, SWZ); setmat(sbox, bakelite)
sbtn = cyl('switch_btn', 15, 14, (SWX, -28, SWZ), axis='Y', verts=64); setmat(sbtn, plastic('switch_btn', (0.03, 0.028, 0.026), 0.2)); _bev(sbtn, 2.5, 4)
ind_m = emissive('indicator', (1.0, 0.38, 0.08), 3.0 if NIGHT else 0.4, (0.2, 0.08, 0.03))
cyl('switch_ind', 3.2, 2, (SWX, -35.5, SWZ + 7), axis='Y', verts=32).data.materials.append(ind_m)
LAMPX, LAMPZ = SWX - 10, 2420
conduit_m = paint('conduit', (0.66, 0.62, 0.52), rough=0.5, chip=0.3, grime=0.7)
tube('conduit1', [(SWX, -9, SWZ + 38), (SWX, -9, LAMPZ - 80)], 8, conduit_m, smooth_pts=False)
tube('conduit2', [(LAMPX, -9, LAMPZ + 70), (LAMPX, -9, CEIL - 120), (LAMPX + 30, -9, CEIL - 30), (LAMPX + 120, -30, CEIL - 9), (LAMPX + 2400, -30, CEIL - 9)], 8, conduit_m)
tube('bellwire', [(DX1 + AW + 95, -4, 1486), (DX1 + AW + 95, -4, CEIL - 10)], 3, conduit_m, smooth_pts=False)
for z in (1700, 2100):
    bx('clip', SWX - 11, SWX + 11, -18, -1, z - 6, z + 6, steel, bev=1)
# wall lamp: cast base, short arm, opal globe
lb = lathe_x('lamp_base', [(0, 0.01), (0, 60), (10, 56), (22, 30), (30, 24), (30, 0.01)], seg=64)
lb.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); lb.location = (LAMPX, 0, LAMPZ); setmat(lb, black_iron)
tube('lamp_arm', [(LAMPX, -25, LAMPZ), (LAMPX, -120, LAMPZ - 10), (LAMPX, -165, LAMPZ - 38)], 7, black_iron)
gal = lathe('lamp_gallery', [(46, LAMPZ - 72), (50, LAMPZ - 60), (40, LAMPZ - 44), (20, LAMPZ - 40)], 0, 0, seg=64)
gal.location = (LAMPX, -165, 0); setmat(gal, black_iron)
G = Vector((LAMPX, -165, LAMPZ - 160)); GR = 105
globe = lathe('globe', [(0.1, G.z - GR), (GR * 0.55, G.z - GR * 0.84), (GR * 0.86, G.z - GR * 0.5), (GR, G.z), (GR * 0.88, G.z + GR * 0.47),
                        (GR * 0.6, G.z + GR * 0.78), (44, G.z + GR * 0.86), (44, G.z + GR * 0.96)], 0, 0, seg=96)
globe.location = (G.x, G.y, 0); globe.modifiers.clear()
sol = globe.modifiers.new('sol', 'SOLIDIFY'); sol.thickness = 3
setmat(globe, opal_glass('opal', glow=0.0 if NIGHT else 2.5))
globe.visible_shadow = False

# ---------------------------------------------------------------- stair flight (up, along the right) + handrail
SX0, SX1, RISE, TREAD, SY0 = 760, 1880, 172, 285, -330
stair_wood = door_wood('X', 90)
for k in range(12):
    y1 = SY0 - k * TREAD; y0 = y1 - TREAD; z1 = (k + 1) * RISE
    bx('tread%d' % k, SX0, SX1, y0 - 25, y1, z1 - 40, z1, door_wood('X', 100 + k, ((SX0 + SX1) / 2, (y0 + y1) / 2, z1), 40), bev=3)
    bx('riser%d' % k, SX0 + 5, SX1, y1 - 22, y1, z1 - RISE, z1 - 40, cream, bev=1.5)
    bx('fill%d' % k, SX0 - 20, SX1, y0, y1, 0, z1 - 40, upper)      # solid masonry under the flight
# side string (painted) along the open side
string = bmesh.new()
sv = [string.verts.new(p) for p in ((SX0 - 30, SY0 + 40, -40), (SX0 - 30, SY0 + 40, 260), (SX0 - 30, SY0 - 12 * TREAD, 12 * RISE + 260),
                                    (SX0 - 30, SY0 - 12 * TREAD, 12 * RISE - 300))]
f = string.faces.new(sv); ex = bmesh.ops.extrude_face_region(string, geom=[f])
for v in [g for g in ex['geom'] if isinstance(g, bmesh.types.BMVert)]: v.co.x += 42
bmesh.ops.recalc_face_normals(string, faces=string.faces)
sm = bpy.data.meshes.new('string'); string.to_mesh(sm); string.free()
so = bpy.data.objects.new('string', sm); bpy.context.collection.objects.link(so); sm.materials.append(lamperia); _bev(so, 2, 2)
# balusters: square wrought bars with a twist in the middle, two per tread; newel post at the landing
RAIL_H = 920
def nosing(y):   # height of the stair line under y
    return max(0.0, (SY0 - y) / TREAD * RISE) + RISE * 0.5
for k in range(12):
    for j in range(2):
        y = SY0 - k * TREAD - TREAD * (0.3 + 0.5 * j)
        z0 = (k + 1) * RISE; z1 = nosing(y) + RAIL_H - 30
        bx('bal', SX0 - 18, SX0 - 6, y - 6, y + 6, z0 - 2, z1, black_iron, bev=1.2)
        zc = z0 + (z1 - z0) * 0.45
        bx('bal_collar', SX0 - 21, SX0 - 3, y - 9, y + 9, zc - 14, zc + 14, black_iron, bev=2)
newel = bx('newel', SX0 - 50, SX0 + 26, SY0 - 20, SY0 + 56, 0, RAIL_H + 230, door_wood('Z', 140, (SX0 - 12, SY0 + 18, 600), 70), bev=4)
lathe('newel_cap', [(0.1, RAIL_H + 230), (46, RAIL_H + 230), (50, RAIL_H + 248), (30, RAIL_H + 268), (8, RAIL_H + 300), (0.1, RAIL_H + 304)], 0, 0, seg=64).location = (SX0 - 12, SY0 + 18, 0)
bpy.data.objects['newel_cap'].data.materials.append(door_wood('Z', 141, (SX0 - 12, SY0 + 18, 1200), 70))
rail_pts = [(SX0 - 12, SY0 - 10, RAIL_H + 150)] + [(SX0 - 12, SY0 - 120 - k * TREAD, nosing(SY0 - 120 - k * TREAD) + RAIL_H) for k in range(12)]
hr = tube('handrail', rail_pts, 30, rail_wood, res=5)
hr.data.bevel_mode = 'ROUND'
# handrail profile: slightly flattened oval (scale the bevel via a custom profile object would be nicer; round is fine)

# ---------------------------------------------------------------- doormat (coir on rubber backing)
MX0, MX1, MY0, MY1 = -385, 385, -585, -55
bx('mat_back', MX0, MX1, MY0, MY1, 0, 7, mat_rubber, bev=2)
coir_base = oak('coir_base', light=(0.40, 0.25, 0.11), dark=(0.20, 0.11, 0.05), axis='Y', ring=1.2, coat=0.0, rough=0.9, seed=12, wear=0, grime=0)
bx('mat_top', MX0 + 6, MX1 - 6, MY0 + 6, MY1 - 6, 7, 13, coir_base)
if HAIR:
    pm_ = bpy.data.meshes.new('fibre_bed'); bmp = bmesh.new()
    bmesh.ops.create_grid(bmp, x_segments=24, y_segments=16, size=0.5)
    for v in bmp.verts: v.co = Vector(((MX0 + MX1) / 2 + v.co.x * (MX1 - MX0 - 12), (MY0 + MY1) / 2 + v.co.y * (MY1 - MY0 - 12), 12.5))
    bmp.to_mesh(pm_); bmp.free(); top = bpy.data.objects.new('fibre_bed', pm_); bpy.context.collection.objects.link(top)
    top.data.materials.append(coir_base)
    mp = top.modifiers.new('fibres', 'PARTICLE_SYSTEM'); ps = mp.particle_system; st = ps.settings
    # coir: stiff, coarse fibres standing in tufts, tips splayed, dark gaps between tufts
    st.type = 'HAIR'; st.count = 9000; st.hair_length = 17; st.emit_from = 'FACE'; st.use_advanced_hair = True
    st.normal_factor = 1.0; st.factor_random = 0.45; st.use_modifier_stack = True
    st.child_type = 'INTERPOLATED'; st.child_percent = 3; st.rendered_child_count = 34; st.child_radius = 3.2
    st.clump_factor = -0.6; st.clump_shape = 0.3; st.roughness_1 = 0.9; st.roughness_1_size = 0.6; st.roughness_endpoint = 2.2
    st.roughness_2 = 0.6; st.roughness_2_size = 1.5; st.child_length = 0.9; st.child_length_threshold = 0.35
    st.root_radius = 1.0; st.tip_radius = 0.5; st.radius_scale = 0.75; st.render_step = 3; st.display_step = 2
    top.data.materials.append(hair_mat('coir', border=(MX0, MX1, MY0, MY1, 48, (0.06, 0.035, 0.02))))
    st.material = 2

# ---------------------------------------------------------------- lights
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 0, 1100)
world_hdri(0.01 if NIGHT else 0.02, 'interior.exr', sat=0.3)
if not NIGHT:
    bpy.ops.object.light_add(type='POINT', location=tuple(G)); bulb = bpy.context.object
    bulb.data.shadow_soft_size = 35; bulb.data.energy = 1.6e8; bulb.data.color = (1.0, 0.68, 0.40)
    # stairwell window up the flight (behind the camera, right): cool, soft
    area_light('window', (2600, -2600, 3000), AIM, 1800, 2.2e7, (0.78, 0.86, 1.0), size_y=2200)
    area_light('bounce', (0, -4000, 1800), AIM, 2500, 2e6, (1.0, 0.85, 0.7))
else:
    area_light('window', (2600, -2600, 3000), AIM, 1800, 1.6e7, (0.55, 0.66, 1.0), size_y=2200)
    # sodium street light through the window, from below: warm, small, grazing up the wall
    a2 = bpy.data.objects.new('aim2', None); scene.collection.objects.link(a2); a2.location = (-300, 0, 2400)
    area_light('street', (2500, -1500, 900), a2, 400, 1.2e7, (1.0, 0.55, 0.22))
    # the flat: a lamp left on inside leaks under the door and through the peephole
    a3 = bpy.data.objects.new('aim3', None); scene.collection.objects.link(a3); a3.location = (0, 0, 0)
    area_light('inside', (0, 400, 300), a3, 700, 3.0e6, (1.0, 0.62, 0.32))
bx('inside_floor', DX0, DX1, 105, 1200, -20, 0, floor)

# ---------------------------------------------------------------- camera + clipboard held in the foreground
cam = photo_camera((150, -2420, 1500), yaw=3.5, lens=24.5, shift=(0.0, -0.14))
cam.data.sensor_fit = 'VERTICAL'; cam.data.sensor_height = 36.0; cam.data.sensor_width = 36.0
bpy.context.view_layer.update()
A5 = (148, 210)
clip_m = metal('clip', (0.42, 0.42, 0.41), 0.32, marks='stamp', wear=0.5, grime=0.6, bevel_r=0.5)
# held below the eye, facing up towards it, slightly rolled: the frame edge cuts the board (hands out of shot)
M_cb = cam.matrix_world @ Matrix.Translation(Vector((-120, -335, -470))) @ Matrix.Rotation(math.radians(-13), 4, 'Z') @ Matrix.Rotation(math.radians(-54), 4, 'X')
cb_objs, sheet_pt = clipboard('clipboard', M_cb, slip, pad_paper, hardboard, clip_m, rng=rng)

# ---------------------------------------------------------------- render
CROP = arg('--crop', '')
render_setup(OUT, RES, SAMPLES, crop=tuple(float(v) for v in CROP.split(',')) if CROP else None, exposure=(-0.6 if NIGHT else 0.0), look='AgX - Medium High Contrast', bounces=10)
scene.cycles.adaptive_threshold = 0.01
photo_finish(0.25 if not NIGHT else 0.35)
scene.view_settings.look = 'AgX - Medium Contrast' if NIGHT else 'AgX - Medium High Contrast'
write_anchors(os.path.splitext(os.path.abspath(OUT))[0] + '.json', {
    'slip': [sheet_pt(0, 0), sheet_pt(A5[0], 0), sheet_pt(A5[0], A5[1]), sheet_pt(0, A5[1])],
    'namecard': [(NP[0] - NPW / 2 + 7, LY - 1, NP[2] + NPH / 2 - 6), (NP[0] + NPW / 2 - 7, LY - 1, NP[2] + NPH / 2 - 6),
                 (NP[0] + NPW / 2 - 7, LY - 1, NP[2] - NPH / 2 + 6), (NP[0] - NPW / 2 + 7, LY - 1, NP[2] - NPH / 2 + 6)],
    'switch': [(SWX - 40, -30, SWZ + 40), (SWX + 40, -30, SWZ + 40), (SWX + 40, -30, SWZ - 40), (SWX - 40, -30, SWZ - 40)],
    'cylinder': [(HX - 60, LY - 20, HZ + 60), (HX + 40, LY - 20, HZ + 60), (HX + 40, LY - 20, CZ - 60), (HX - 60, LY - 20, CZ - 60)],
    'door': [(LX0, LY, LZ1), (LX1, LY, LZ1), (LX1, LY, LZ0), (LX0, LY, LZ0)],
    'mat': [(MX0, MY1, 20), (MX1, MY1, 20), (MX1, MY0, 20), (MX0, MY0, 20)],
})
if "--norender" in sys.argv:
    for o in bpy.data.objects:
        if o.name.startswith(("sheet", "clipb", "clip")): print("BB", o.name, [tuple(round(c, 1) for c in o.matrix_world @ Vector(v)) for v in (o.bound_box[0], o.bound_box[6])], o.dimensions)
else:
    bpy.ops.render.render(write_still=True)
print('WROTE', scene.render.filepath)
