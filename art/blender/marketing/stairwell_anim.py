# Lockwright marketing renders & animations: tenement stairwell scene (R01, R12, R13).
# Imports art/blender/env_common.py without modifying art/blender/*.py.
# Example single-command runs:
#   blender -b -P art/blender/marketing/stairwell_anim.py -- --preset R01 --out art/marketing/frames/R01 --res 2160x3840 --samples 128
#   blender -b -P art/blender/marketing/stairwell_anim.py -- --preset R12 --out art/marketing/frames/R12 --res 2160x3840 --samples 128
#   blender -b -P art/blender/marketing/stairwell_anim.py -- --preset R13 --still 1 --out art/marketing/stills/R13_endcard_portrait.png --res 2160x3840 --samples 256
import bpy
import bmesh
import math
import os
import sys
import random

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gpu_common import (
    ART_BLENDER_DIR, setup_gpu_cycles, ease_out_cubic, ease_in_out_cubic,
    clamp01, remap, ensure_under_10mb
)
from env_common import *
from env_common import _bev
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default

PRESET = arg('--preset', '') or (arg('--shot', '') if arg('--shot', '').startswith('R') else '')
OUT = arg('--out', 'art/marketing/previews/stairwell_test.png')
RES = [int(v) for v in arg('--res', '540x960').split('x')]
SAMPLES = int(arg('--samples', '64'))
STILL_ONLY = (arg('--still', '0') == '1') or ('--frame' in argv) or OUT.lower().endswith('.png')
STILL_FRAME = int(arg('--still_frame', arg('--frame', '-1')))
FRAME_START = int(arg('--frame_start', '1'))
FRAME_END = int(arg('--frame_end', '-1'))
BIT_DEPTH = arg('--bit_depth', '16')
HAIR = arg('--hair', '0') == '1'

PRESETS = {
    'R01': {'anim': 'timer_on',  'night': True,  'frames': 75, 'still_frame': 55, 'door_open': 0.0,  'number': '12'},
    'R12': {'anim': 'door_open', 'night': False, 'frames': 60, 'still_frame': 48, 'door_open': 25.0, 'number': '12'},
    'R13': {'anim': 'plate',     'night': False, 'frames': 1,  'still_frame': 1,  'door_open': 0.0,  'number': ''},
}

cfg = PRESETS.get(PRESET, {'anim': 'timer_on', 'night': '--night' in sys.argv, 'frames': 75, 'still_frame': 45, 'door_open': 0.0, 'number': '12'})
ANIM = arg('--anim', cfg['anim'])
NIGHT = ('--night' in sys.argv) or cfg['night']
FRAMES = int(arg('--frames', str(cfg['frames'])))
DOOR_OPEN_DEG = float(arg('--door_open', str(cfg['door_open'])))
NUMBER = arg('--number', cfg['number'])
if STILL_FRAME < 1:
    STILL_FRAME = cfg['still_frame']

rng = random.Random(11)

# ---------------------------------------------------------------- materials
WALL_GREEN = (0.055, 0.115, 0.082)
lamperia = oil_paint('lamperia', WALL_GREEN, rough=0.28, under=(0.42, 0.30, 0.16), base=(0.62, 0.58, 0.50), chips=0.45,
                     scuffs=0.6, strokes='Z', seed=1, chip_scale=0.012)
stripe = oil_paint('stripe', (0.20, 0.045, 0.03), rough=0.3, chips=0.3, scuffs=0.2, strokes='X', seed=2)
upper = lime_wall('lime', (0.72, 0.68, 0.58), seed=3, dirt=0.55, cracks=0.6)
hall_wall = lime_wall('hall_lime', (0.82, 0.75, 0.62), seed=8, dirt=0.2, cracks=0.15)
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
blue = enamel('enamel_blue', (0.012, 0.05, 0.20), chip=0.55)
white_en = enamel('enamel_white', (0.82, 0.81, 0.77), chip=0.0)
card = paper('name_card', (0.78, 0.74, 0.64), grime=0.4, seed=3)
rail_wood = oak('handrail', light=(0.42, 0.24, 0.11), dark=(0.16, 0.08, 0.035), axis='Y', seed=7, ring=2.0, coat=1.0,
                coat_rough=0.15, wear=0.8, varnish_tint=0.2)
dark = dark_mat('void', (0.01, 0.009, 0.008))
mat_rubber = rubber('mat_rubber')

def door_wood(axis, seed, center=(0, 0, 0), width=120):
    l = jitter((0.33, 0.20, 0.10), 0.14, rng)
    d = jitter((0.12, 0.06, 0.028), 0.12, rng)
    c = list(center)
    k = {'Z': 0, 'X': 2, 'Y': 0}[axis]
    c[k] += rng.uniform(-0.3, 0.3) * width
    return oak('door_%s_%d' % (axis, seed), light=l, dark=d, axis=axis, seed=seed, ring=rng.uniform(1.7, 2.8),
               incline=rng.choice((-1, 1)) * rng.uniform(0.03, 0.06), depth=rng.uniform(70, 160), coat=1.0, coat_rough=0.32,
               rough=0.5, wear=0.6, grime=0.8, flecks=0.0, varnish_tint=0.3, center=tuple(c), contrast=0.72)

# ---------------------------------------------------------------- architecture
W0, W1 = -1700, 1900
WT = 380
CEIL = 3350
DX0, DX1, DTOP = -470, 470, 2130
LAMP_Z, STRIPE = 1500, 22

def wall_bands(name, x0, x1, y0, y1, holes=()):
    parts = []
    for nm, z0, z1, mt in (('lamp', 0, LAMP_Z, lamperia), ('str', LAMP_Z, LAMP_Z + STRIPE, stripe), ('lime', LAMP_Z + STRIPE, CEIL, upper)):
        o = bx('%s_%s' % (name, nm), x0, x1, y0, y1, z0, z1, mt)
        for h in holes:
            if h[4] < z1 and h[5] > z0:
                cut(o, bx('hole', *h))
        _bev(o, 1.5, 2, 30)
        parts.append(o)
    return parts

wall_bands('back', W0, W1, 0, WT, holes=[(DX0, DX1, -10, WT + 10, -10, DTOP)])
wall_bands('left', -1700 - WT, -1700, -4200, 0)
bx('behind', -2200, 2400, -4300, -4200, 0, CEIL, upper)
bx('ceiling', -2200, 2400, -4300, 2200, CEIL, CEIL + 200, ceiling)
bx('floor', -1700, 2400, -4300, 0, -60, 0, floor)
skirt = terrazzo('skirting', matrix=(0.30, 0.29, 0.27), seed=4)
bx('skirt_l', W0, DX0 - 95, -14, 0, 0, 95, skirt, bev=3)
bx('skirt_r', DX1 + 95, 700, -14, 0, 0, 95, skirt, bev=3)
bx('skirt_side', -1700, -1686, -4200, 0, 0, 95, skirt, bev=3)
bx('threshold', DX0, DX1, -22, 120, 0, 20, door_wood('X', 21, (0, 50, 10), 100), bev=3)

# Warm apartment interior behind the door (visible when door swings open in R12)
hall_parquet = oak('hall_parquet', light=(0.48, 0.31, 0.16), dark=(0.24, 0.13, 0.06), axis='Y', seed=19, ring=2.1, coat=0.9, coat_rough=0.22)
bx('inside_floor', -1200, 1200, 105, 2400, -20, 0, hall_parquet)
bx('inside_wall_back', -1200, 1200, 2100, 2250, 0, CEIL, hall_wall)
bx('inside_wall_l', -1200, -950, 380, 2100, 0, CEIL, hall_wall)
bx('inside_wall_r', 950, 1200, 380, 2100, 0, CEIL, hall_wall)
bx('inside_skirt', -1200, 1200, 2085, 2100, 0, 95, cream, bev=2)
# Warm wooden console/frame edge inside the hallway for lived-in depth (no characters)
bx('inside_wainscot', -1200, 1200, 2092, 2100, 95, 1100, door_wood('X', 88, (0, 2095, 600), 140), bev=2)

# Architrave + jamb
AW, AP = 95, 24
for x0, x1 in ((DX0 - AW, DX0), (DX1, DX1 + AW)):
    bx('arch_v', x0, x1, -AP, 0, 0, DTOP + AW, cream, bev=2.5)
    xb = (x0, x0 + 22) if x0 < 0 else (x1 - 22, x1)
    bx('arch_band', xb[0], xb[1], -AP - 9, -AP + 1, 0, DTOP + AW, cream, bev=2.5)
bx('arch_h', DX0 + 0.5, DX1 - 0.5, -AP + 0.5, 0, DTOP, DTOP + AW - 0.5, cream, bev=2.5)
bx('arch_hb', DX0 - AW + 22.5, DX1 + AW - 22.5, -AP - 9, -AP + 1, DTOP + AW - 22, DTOP + AW, cream, bev=2.5)
for x0, x1 in ((DX0, DX0 + 24), (DX1 - 24, DX1)):
    bx('jamb', x0, x1, 0, 380, 0, DTOP, cream, bev=1.5)
bx('jamb_h', DX0, DX1, 0, 380, DTOP - 24, DTOP, cream, bev=1.5)

# ---------------------------------------------------------------- Door leaf & hardware (parented to hinge for R12)
LX0, LX1, LZ0, LZ1, LY = DX0 + 26, DX1 - 26, 29, DTOP - 26, 60
SW, TR, LR0, LR1, BR, MW = 120, 125, 905, 1080, 215, 92

HINGE_PIVOT = Vector((LX0 + 8, LY + 42, 0))
door_hinge = bpy.data.objects.new('door_hinge', None)
scene.collection.objects.link(door_hinge)
door_hinge.location = HINGE_PIVOT

door_parts = []
pieces = [
    ('stile_l', LX0, LX0 + SW, LZ0, LZ1, 'Z'), ('stile_r', LX1 - SW, LX1, LZ0, LZ1, 'Z'),
    ('rail_t', LX0 + SW, LX1 - SW, LZ1 - TR, LZ1, 'X'), ('rail_lock', LX0 + SW, LX1 - SW, LR0, LR1, 'X'),
    ('rail_b', LX0 + SW, LX1 - SW, LZ0, LZ0 + BR, 'X'),
    ('mun_u', -MW / 2, MW / 2, LR1, LZ1 - TR, 'Z'), ('mun_l', -MW / 2, MW / 2, LZ0 + BR, LR0, 'Z'),
]
for i, (nm, x0, x1, z0, z1, ax) in enumerate(pieces):
    o = bx(nm, x0, x1, LY, LY + 45, z0, z1, door_wood(ax, 30 + i, ((x0 + x1) / 2, LY, (z0 + z1) / 2), min(x1 - x0, z1 - z0)), bev=1.6, seg=2)
    door_parts.append(o)

panels = [(LX0 + SW, -MW / 2, LR1, LZ1 - TR), (MW / 2, LX1 - SW, LR1, LZ1 - TR),
          (LX0 + SW, -MW / 2, LZ0 + BR, LR0), (MW / 2, LX1 - SW, LZ0 + BR, LR0)]

def raised_panel(name, x0, x1, z0, z1, y_field=64, y_flat=74, inset=42, mat=None):
    bm = bmesh.new()
    def ring(xa, xb, za, zb, y):
        return [bm.verts.new(p) for p in ((xa, y, za), (xb, y, za), (xb, y, zb), (xa, y, zb))]
    a = ring(x0, x1, z0, z1, y_flat + 14)
    bfl = ring(x0, x1, z0, z1, y_flat)
    c = ring(x0 + 12, x1 - 12, z0 + 12, z1 - 12, y_flat)
    d = ring(x0 + inset, x1 - inset, z0 + inset, z1 - inset, y_field + 3)
    e = ring(x0 + inset + 6, x1 - inset - 6, z0 + inset + 6, z1 - inset - 6, y_field)
    for r1, r2 in ((a, bfl), (bfl, c), (c, d), (d, e)):
        for i in range(4):
            bm.faces.new((r1[i], r1[(i + 1) % 4], r2[(i + 1) % 4], r2[i]))
    bm.faces.new(list(reversed(a)))
    bm.faces.new(e)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat)
    _bev(o, 1.2, 2, 20)
    return o

for i, (x0, x1, z0, z1) in enumerate(panels):
    p_obj = raised_panel('panel%d' % i, x0, x1, z0, z1, mat=door_wood('Z', 50 + i, ((x0 + x1) / 2, 70, (z0 + z1) / 2), x1 - x0))
    door_parts.append(p_obj)
    mo = door_wood('Z', 60 + i, ((x0 + x1) / 2, 61, (z0 + z1) / 2), 30)
    pts = [(x0 + 1, 61, z0 + 1), (x1 - 1, 61, z0 + 1), (x1 - 1, 61, z1 - 1), (x0 + 1, 61, z1 - 1), (x0 + 1, 61, z0 + 1)]
    t = tube('mould%d' % i, pts, 9, mo, smooth_pts=False)
    t.data.bevel_resolution = 3
    door_parts.append(t)

# Hardware on the door
HX, HZ, CZ = LX1 - 62, 1050, 1050 - 72
esc = slab('escutcheon', rounded_rect(46, 252, 10), 8, steel, bev=1.6)
place(esc, (HX, LY, HZ - 36), rot=(90, 0, 0))
cut(esc, cyl('cylhole', 9.4, 40, (HX, LY - 4, CZ), axis='Y', verts=64))
door_parts.append(esc)

cyl_front = lathe_x('cyl_face', [(0, 0.01), (0, 8.2), (0.8, 8.9), (3.6, 8.9), (3.6, 0.01)], seg=96)
cyl_front.data.transform(Matrix.Rotation(math.radians(90), 4, 'Z'))
cyl_front.location = (HX, LY - 11.5, CZ)
setmat(cyl_front, nickel); _bev(cyl_front, 0.3, 2, 30)
plug = cyl('plug', 6.1, 3.0, (HX, LY - 10.0, CZ), axis='Y', verts=96); setmat(plug, brass)
kw = bx('keyway', HX - 1.0, HX + 1.0, LY - 20, LY + 5, CZ - 5.2, CZ + 3.4)
boolean(kw, bx('kwa', HX - 2.0, HX + 2.0, LY - 20, LY + 5, CZ - 2.4, CZ - 0.9), 'UNION')
cut(plug, kw)
cut(cyl_front, cyl('plughole', 6.3, 30, (HX, LY - 10, CZ), axis='Y', verts=96))
kw_dark = bx('kw_dark', HX - 2.5, HX + 2.5, LY - 9.0, LY - 8.5, CZ - 6, CZ + 4, dark)
door_parts.extend([cyl_front, plug, kw_dark])

rose = lathe_x('rose', [(0, 0.01), (0, 17), (3, 17), (6, 13), (9, 11), (9, 0.01)], seg=64)
rose.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); rose.location = (HX, LY - 8, HZ); setmat(rose, steel)
lever = tube('lever', [(HX, LY - 12, HZ), (HX, LY - 48, HZ), (HX - 6, LY - 62, HZ), (HX - 30, LY - 66, HZ),
                       (HX - 135, LY - 64, HZ - 2)], 9.5, steel, res=6)
door_parts.extend([rose, lever])

ph = lathe_x('peep', [(0, 0.01), (0, 16), (2, 15.5), (4, 12), (5, 8), (5, 0.01)], seg=64)
ph.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); ph.location = (0, LY, 1585); setmat(ph, brass)
lens_m = emissive('peep_glow', (1.0, 0.62, 0.3), 0.8 if NIGHT else 0.15, (0.05, 0.04, 0.03))
plens = cyl('peep_lens', 6.5, 1, (0, LY - 5.3, 1585), axis='Y', verts=48)
plens.data.materials.append(lens_m)
door_parts.extend([ph, plens])

NP = (0, LY, 1478); NPW, NPH = 118, 40
frame = slab('nameframe', rounded_rect(NPW, NPH, 3), 2.2, brass, bev=0.5)
cut(frame, place(slab('win', rounded_rect(NPW - 14, NPH - 12, 1.5), 10), (0, 0, -4)))
place(frame, (NP[0], NP[1] - 1, NP[2]), rot=(90, 0, 0))
nc = bx('namecard', NP[0] - NPW / 2 + 5, NP[0] + NPW / 2 - 5, LY - 0.9, LY - 0.4, NP[2] - NPH / 2 + 4, NP[2] + NPH / 2 - 4, card)
door_parts.extend([frame, nc])
for sx in (-1, 1):
    sc_np = screw_head('np_screw', (NP[0] + sx * (NPW / 2 - 3.5), LY - 3.2, NP[2]), 1.8, 1.0, axis='-Y', mat=brass, rot=rng.uniform(0, 3))
    door_parts.append(sc_np)

# Enamel plate: in R13 ('plate'), wider blank enamel plate without number for title overlay
EP = (0, LY, LZ1 - TR / 2)
EW, EH = (256, 112) if ANIM == 'plate' else (128, 88)
ep = slab('enamel_plate', rounded_rect(EW, EH, 12), 2.0, blue, bev=1.4, seg=4)
ep_rot = (90, 0.6 if ANIM == 'plate' else 1.6, 0)
inner = slab('enamel_line', rounded_rect(EW - 14, EH - 14, 7), 0.25, white_en)
cut(inner, place(slab('enamel_line_in', rounded_rect(EW - 20, EH - 20, 5), 4.0), (0, 0, -1)))
place(inner, (0, 0, 2.0))
for o in (ep, inner):
    place(o, (EP[0], EP[1] - 1, EP[2]), rot=ep_rot)
    door_parts.append(o)

if NUMBER:
    num = text_obj('number', NUMBER, 56, extrude=0.15, mat=white_en)
    bpy.context.view_layer.update()
    num.data.offset_y = -1.0
    num.matrix_world = Matrix.Translation(Vector((EP[0], EP[1] - 3.3, EP[2] - 2))) @ Matrix.Rotation(math.radians(ep_rot[1]), 4, 'Y') @ Matrix.Rotation(math.radians(90), 4, 'X')
    door_parts.append(num)

for sx, sz in ((-1, 1), (1, -1)):
    sc_ep = screw_head('ep_screw', (EP[0] + sx * (EW / 2 - 9), LY - 3.5, EP[2] + sz * (EH / 2 - 9)), 2.2, 1.2, axis='-Y', mat=steel, rot=rng.uniform(0, 3))
    door_parts.append(sc_ep)

old_p = bx('old_plug', HX - 9, HX + 9, LY - 0.2, LY + 2, 1260 - 9, 1260 + 9, door_wood('Y', 77), bev=4, seg=4)
door_parts.append(old_p)

# Latch bolt on side edge of door (visible when door swings open in R12)
latch_bolt = bx('latch_bolt', LX1 - 2, LX1 + 14, LY + 16, LY + 28, HZ - 55, HZ - 25, brass, bev=1.5)
door_parts.append(latch_bolt)

bpy.context.view_layer.update()
for o in door_parts:
    mw = o.matrix_world.copy()
    o.parent = door_hinge
    o.matrix_parent_inverse = door_hinge.matrix_world.inverted()
    o.matrix_world = mw

# ---------------------------------------------------------------- doorbell, timer switch, conduit, lamp
bp = slab('bell_plate', rounded_rect(52, 72, 4), 6, bakelite, bev=1.2); place(bp, (DX1 + AW + 95, 0, 1450), rot=(90, 0, 0))
bb = cyl('bell_btn', 9, 8, (DX1 + AW + 95, -8, 1458), axis='Y', verts=48); setmat(bb, plastic('bell_btn', (0.55, 0.50, 0.40), 0.3)); _bev(bb, 1.5, 3)
SWX, SWZ = DX0 - AW - 165, 1360
sbox = lathe_x('switch_box', [(0, 0.01), (0, 38), (18, 36), (26, 30), (28, 0.01)], seg=64)
sbox.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); sbox.location = (SWX, 0, SWZ); setmat(sbox, bakelite)
sbtn = cyl('switch_btn', 15, 14, (SWX, -28, SWZ), axis='Y', verts=64); setmat(sbtn, plastic('switch_btn', (0.03, 0.028, 0.026), 0.2)); _bev(sbtn, 2.5, 4)
ind_m = emissive('indicator', (1.0, 0.38, 0.08), 9.0 if NIGHT else 0.4, (0.2, 0.08, 0.03))
cyl('switch_ind', 3.2, 2, (SWX, -35.5, SWZ + 7), axis='Y', verts=32).data.materials.append(ind_m)

LAMPX, LAMPZ = SWX - 10, 2420
conduit_m = paint('conduit', (0.66, 0.62, 0.52), rough=0.5, chip=0.3, grime=0.7)
tube('conduit1', [(SWX, -9, SWZ + 38), (SWX, -9, LAMPZ - 80)], 8, conduit_m, smooth_pts=False)
tube('conduit2', [(LAMPX, -9, LAMPZ + 70), (LAMPX, -9, CEIL - 120), (LAMPX + 30, -9, CEIL - 30), (LAMPX + 120, -30, CEIL - 9), (LAMPX + 2400, -30, CEIL - 9)], 8, conduit_m)
tube('bellwire', [(DX1 + AW + 95, -4, 1486), (DX1 + AW + 95, -4, CEIL - 10)], 3, conduit_m, smooth_pts=False)
for z in (1700, 2100):
    bx('clip', SWX - 11, SWX + 11, -18, -1, z - 6, z + 6, steel, bev=1)

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
globe_mat_on = opal_glass('opal_on', glow=2.5)
globe_mat_off = opal_glass('opal_off', glow=0.0)
setmat(globe, globe_mat_off if NIGHT else globe_mat_on)
globe.visible_shadow = False

# ---------------------------------------------------------------- stair flight + handrail
SX0, SX1, RISE, TREAD, SY0 = 760, 1880, 172, 285, -330
for k in range(12):
    y1 = SY0 - k * TREAD; y0 = y1 - TREAD; z1 = (k + 1) * RISE
    bx('tread%d' % k, SX0, SX1, y0 - 25, y1, z1 - 40, z1, door_wood('X', 100 + k, ((SX0 + SX1) / 2, (y0 + y1) / 2, z1), 40), bev=3)
    bx('riser%d' % k, SX0 + 5, SX1, y1 - 22, y1, z1 - RISE, z1 - 40, cream, bev=1.5)
    bx('fill%d' % k, SX0 - 20, SX1, y0, y1, 0, z1 - 40, upper)
string = bmesh.new()
sv = [string.verts.new(p) for p in ((SX0 - 30, SY0 + 40, -40), (SX0 - 30, SY0 + 40, 260), (SX0 - 30, SY0 - 12 * TREAD, 12 * RISE + 260),
                                    (SX0 - 30, SY0 - 12 * TREAD, 12 * RISE - 300))]
f_s = string.faces.new(sv); ex = bmesh.ops.extrude_face_region(string, geom=[f_s])
for v in [g for g in ex['geom'] if isinstance(g, bmesh.types.BMVert)]:
    v.co.x += 42
bmesh.ops.recalc_face_normals(string, faces=string.faces)
sm = bpy.data.meshes.new('string'); string.to_mesh(sm); string.free()
so = bpy.data.objects.new('string', sm); bpy.context.collection.objects.link(so); sm.materials.append(lamperia); _bev(so, 2, 2)

RAIL_H = 920
def nosing(y):
    return max(0.0, (SY0 - y) / TREAD * RISE) + RISE * 0.5
for k in range(12):
    for j in range(2):
        y = SY0 - k * TREAD - TREAD * (0.3 + 0.5 * j)
        z0 = (k + 1) * RISE; z1 = nosing(y) + RAIL_H - 30
        bx('bal', SX0 - 18, SX0 - 6, y - 6, y + 6, z0 - 2, z1, black_iron, bev=1.2)
        zc = z0 + (z1 - z0) * 0.45
        bx('bal_collar', SX0 - 21, SX0 - 3, y - 9, y + 9, zc - 14, zc + 14, black_iron, bev=2)
bx('newel', SX0 - 50, SX0 + 26, SY0 - 20, SY0 + 56, 0, RAIL_H + 230, door_wood('Z', 140, (SX0 - 12, SY0 + 18, 600), 70), bev=4)
lathe('newel_cap', [(0.1, RAIL_H + 230), (46, RAIL_H + 230), (50, RAIL_H + 248), (30, RAIL_H + 268), (8, RAIL_H + 300), (0.1, RAIL_H + 304)], 0, 0, seg=64).location = (SX0 - 12, SY0 + 18, 0)
bpy.data.objects['newel_cap'].data.materials.append(door_wood('Z', 141, (SX0 - 12, SY0 + 18, 1200), 70))
rail_pts = [(SX0 - 12, SY0 - 10, RAIL_H + 150)] + [(SX0 - 12, SY0 - 120 - k * TREAD, nosing(SY0 - 120 - k * TREAD) + RAIL_H) for k in range(12)]
hr = tube('handrail', rail_pts, 30, rail_wood, res=5)
hr.data.bevel_mode = 'ROUND'

# ---------------------------------------------------------------- doormat
MX0, MX1, MY0, MY1 = -385, 385, -585, -55
bx('mat_back', MX0, MX1, MY0, MY1, 0, 7, mat_rubber, bev=2)
coir_base = rubber('coir_base', (0.05, 0.032, 0.018), rough=0.95)
bx('mat_top', MX0 + 6, MX1 - 6, MY0 + 6, MY1 - 6, 7, 13, coir_base)
if HAIR and ANIM != 'plate':
    pm_ = bpy.data.meshes.new('fibre_bed'); bmp = bmesh.new()
    bmesh.ops.create_grid(bmp, x_segments=94, y_segments=64, size=0.5)
    for v in bmp.verts:
        v.co = Vector(((MX0 + MX1) / 2 + v.co.x * (MX1 - MX0 - 12), (MY0 + MY1) / 2 + v.co.y * (MY1 - MY0 - 12), 12.5))
    bmp.to_mesh(pm_); bmp.free()
    top = bpy.data.objects.new('fibre_bed', pm_); bpy.context.collection.objects.link(top)
    top.data.materials.append(coir_base)
    mp = top.modifiers.new('fibres', 'PARTICLE_SYSTEM'); ps = mp.particle_system; st = ps.settings
    st.type = 'HAIR'; st.count = 95 * 65; st.hair_length = 16; st.emit_from = 'VERT'; st.use_emit_random = False
    st.use_advanced_hair = True; st.normal_factor = 1.0; st.factor_random = 0.12; st.use_modifier_stack = True
    st.child_type = 'SIMPLE'; st.child_percent = 2; st.rendered_child_count = 24; st.child_radius = 3.4; st.child_roundness = 1.0
    st.clump_factor = -0.45; st.clump_shape = 0.2; st.roughness_1 = 0.5; st.roughness_1_size = 0.5; st.roughness_endpoint = 1.4
    st.roughness_2 = 0.5; st.roughness_2_size = 1.2; st.child_length = 0.92; st.child_length_threshold = 0.3
    st.root_radius = 1.0; st.tip_radius = 0.45; st.radius_scale = 0.7; st.render_step = 3; st.display_step = 2
    top.data.materials.append(hair_mat('coir', light=(0.44, 0.30, 0.16), dark=(0.21, 0.13, 0.065), border=(MX0, MX1, MY0, MY1, 48, (0.045, 0.03, 0.02))))
    st.material = 2

# ---------------------------------------------------------------- traces of use
stain_decal('soot', 'Y', -0.6, (LAMPX - 400, LAMPX + 400, LAMPZ - 120, CEIL), [(LAMPX, LAMPZ + 250, 160, 380, 0.55), (LAMPX, LAMPZ + 700, 260, 400, 0.25)],
            color=(0.10, 0.085, 0.06))
stain_decal('hand_grime', 'Y', -0.6, (SWX - 160, SWX + 160, SWZ - 200, SWZ + 170), [(SWX + 10, SWZ - 10, 70, 60, 0.45), (SWX + 40, SWZ - 60, 40, 40, 0.3)],
            color=(0.05, 0.06, 0.045), rough=0.5, noise_scale=0.05)
stain_decal('floor_grime', 'Z', 0.2, (W0, 2400, -4200, 0), [(0, -30, 900, 70, 0.5), (-1100, -30, 600, 60, 0.6), (DX0 - 150, -400, 120, 380, 0.25)],
            color=(0.09, 0.08, 0.065), rough=0.7, noise_scale=0.03)

# ---------------------------------------------------------------- lights (controllable per frame)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 0, 1100)
w_world = world_hdri(0.015, 'interior.exr', sat=0.3)

bpy.ops.object.light_add(type='POINT', location=tuple(G))
L_bulb = bpy.context.object; L_bulb.name = 'bulb'
L_bulb.data.shadow_soft_size = 35; L_bulb.data.energy = 1.6e8; L_bulb.data.color = (1.0, 0.68, 0.40)

L_window = area_light('window', (2600, -2600, 3000), AIM, 1800, 2.0e7, (0.72, 0.82, 1.0), size_y=2200)
L_bounce = area_light('bounce', (0, -4000, 1800), AIM, 2500, 2.0e6, (1.0, 0.85, 0.7))

a2 = bpy.data.objects.new('aim2', None); scene.collection.objects.link(a2); a2.location = (-300, 0, 2400)
L_street = area_light('street', (2500, -1500, 900), a2, 400, 3.2e7, (1.0, 0.55, 0.22))

a3 = bpy.data.objects.new('aim3', None); scene.collection.objects.link(a3); a3.location = (0, 0, 900)
L_inside = area_light('inside', (80, 950, 1850), a3, 850, 1.4e8, (1.0, 0.66, 0.36))

# Camera setup
cam = photo_camera((0, -2620, 1600), yaw=0.0, lens=35.0, shift=(-0.04, -0.05))
cam.data.sensor_fit = 'HORIZONTAL'
cam.data.sensor_width = 36.0

def clean_photo_finish(vignette=0.18, dispersion=0.004):
    scene.use_nodes = True
    nt = scene.node_tree
    nt.nodes.clear()
    l = nt.links
    rl = nt.nodes.new('CompositorNodeRLayers')
    out = nt.nodes.new('CompositorNodeComposite')
    ld = nt.nodes.new('CompositorNodeLensdist')
    ld.use_fit = True
    ld.inputs['Distortion'].default_value = 0.0
    ld.inputs['Dispersion'].default_value = dispersion
    l.new(rl.outputs['Image'], ld.inputs['Image'])
    em = nt.nodes.new('CompositorNodeEllipseMask')
    em.width = 0.86
    em.height = 0.86
    em.inputs['Value'].default_value = 1.0
    bl = nt.nodes.new('CompositorNodeBlur')
    bl.filter_type = 'FAST_GAUSS'
    bl.use_relative = True
    bl.factor_x = 35.0
    bl.factor_y = 35.0
    bl.size_x = 1
    bl.size_y = 1
    l.new(em.outputs['Mask'], bl.inputs['Image'])
    mr = nt.nodes.new('CompositorNodeMapRange')
    mr.inputs['To Min'].default_value = 1.0 - vignette
    mr.inputs['To Max'].default_value = 1.0
    l.new(bl.outputs['Image'], mr.inputs['Value'])
    mx = nt.nodes.new('CompositorNodeMixRGB')
    mx.blend_type = 'MULTIPLY'
    mx.inputs['Fac'].default_value = 1.0
    l.new(ld.outputs['Image'], mx.inputs[1])
    l.new(mr.outputs['Value'], mx.inputs[2])
    l.new(mx.outputs['Image'], out.inputs['Image'])

clean_photo_finish(0.18, 0.004)

def update_stairwell_frame(f):
    t_norm = (f - 1) / max(1, FRAMES - 1)
    timer_lamp_fac = 1.0
    door_deg = DOOR_OPEN_DEG

    if ANIM == 'timer_on':  # R01: eye height (160cm), 35mm, push-in 0.4m in 2.5s; bulb turns on in 6 frames
        u_push = ease_in_out_cubic(t_norm)
        cam.location = (-55.0 * (1 - 0.35 * u_push), -2620.0 + 400.0 * u_push, 1600.0)
        cam.rotation_euler = (math.radians(90.0), 0, math.radians(-1.5 * (1 - 0.4 * u_push)))
        cam.data.lens = 35.0
        cam.data.shift_x, cam.data.shift_y = -0.05, -0.05
        # Timer switch clicks at frame 10; bulb warms up over frames 10..16 (6 frames)
        if f < 10:
            timer_lamp_fac = 0.0
            sbtn.location.y = -28.0
        else:
            timer_lamp_fac = ease_out_cubic(remap(f, 10, 16))
            sbtn.location.y = -28.0 + 4.0 * ease_out_cubic(remap(f, 9, 12))
        door_deg = 0.0

    elif ANIM == 'timer_off':
        cam.location = (-35.0, -2220.0, 1600.0)
        cam.rotation_euler = (math.radians(90.0), 0, math.radians(-0.9))
        cam.data.lens = 35.0
        timer_lamp_fac = 1.0 - ease_out_cubic(remap(f, 6, 18))
        door_deg = 0.0

    elif ANIM == 'door_open':  # R12: end framing of R01, door opens 0 -> 25 deg in 30 frames, warm interior light
        u_open = ease_in_out_cubic(remap(f, 1, 31))
        door_deg = 25.0 * u_open
        cam.location = (-35.75, -2220.0, 1600.0)
        cam.rotation_euler = (math.radians(90.0), 0, math.radians(-0.9))
        cam.data.lens = 35.0
        cam.data.shift_x, cam.data.shift_y = -0.05, -0.05
        timer_lamp_fac = 1.0

    elif ANIM == 'plate':  # R13: straight on the door, 85 mm, blank enamel plate for title
        cam.location = (0.0, -780.0 if RES[0] < RES[1] else -920.0, EP[2])
        cam.rotation_euler = (math.radians(90.0), 0, 0)
        cam.data.lens = 85.0
        cam.data.shift_x, cam.data.shift_y = 0.0, 0.0
        timer_lamp_fac = 1.0
        door_deg = 0.0

    # Apply door rotation around left hinge (+Z swings door inward into +Y apartment)
    door_hinge.rotation_euler = (0, 0, math.radians(door_deg))

    # Apply stairwell lighting state
    L_bulb.data.energy = 1.6e8 * timer_lamp_fac
    L_bounce.data.energy = 2.0e6 * timer_lamp_fac
    L_window.data.energy = 1.6e7 * (1 - timer_lamp_fac) + 2.2e7 * timer_lamp_fac
    L_street.data.energy = 3.5e7 * (1.0 - 0.7 * timer_lamp_fac)
    # Warm light inside flat: subtle leak under closed door, bright warm flood when door swings open
    open_light_fac = clamp01(door_deg / 25.0)
    L_inside.data.energy = 2.5e7 + 2.2e8 * open_light_fac
    setmat(globe, globe_mat_on if timer_lamp_fac > 0.15 else globe_mat_off)
    ind_m.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 9.0 * (1.0 - timer_lamp_fac) + 0.4 * timer_lamp_fac
    scene.view_settings.exposure = -0.35 * (1.0 - timer_lamp_fac)

    cam_sig = tuple(round(v, 4) for v in cam.location) + tuple(round(v, 4) for v in cam.rotation_euler)
    return (cam_sig, round(timer_lamp_fac, 4), round(door_deg, 4), round(sbtn.location.y, 4))


import shutil
backend, gpu_name = setup_gpu_cycles(
    scene, samples=SAMPLES, denoiser='OPTIX', use_dof=False, persistent=True, color_depth=BIT_DEPTH
)
scene.cycles.max_bounces = 5 if not (STILL_ONLY or FRAMES == 1) else 8
scene.cycles.adaptive_threshold = 0.015 if not (STILL_ONLY or FRAMES == 1) else 0.01
scene.render.resolution_x, scene.render.resolution_y = RES
scene.render.film_transparent = False
scene.view_settings.view_transform = 'AgX'
scene.view_settings.look = 'AgX - Medium High Contrast'

print(f"[stairwell_anim] Preset={PRESET or 'custom'} Anim={ANIM} Res={RES[0]}x{RES[1]} Samples={SAMPLES} GPU={gpu_name} ({backend})")

if STILL_ONLY or FRAMES == 1:
    update_stairwell_frame(STILL_FRAME)
    out_path = os.path.abspath(OUT)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    scene.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    if 'stills' in out_path.replace('\\', '/') or 'previews' in out_path.replace('\\', '/'):
        ensure_under_10mb(out_path)
    print('WROTE STILL', out_path)
else:
    out_dir = os.path.abspath(OUT)
    if out_dir.lower().endswith('.png'):
        out_dir = os.path.splitext(out_dir)[0]
    os.makedirs(out_dir, exist_ok=True)
    f_start = max(1, FRAME_START)
    f_end = FRAMES if FRAME_END < 1 else min(FRAMES, FRAME_END)
    prev_sig = None
    prev_path = None
    for f in range(f_start, f_end + 1):
        frame_path = os.path.join(out_dir, f"frame_{f:04d}.png")
        sig = update_stairwell_frame(f)
        if prev_sig is not None and sig == prev_sig and prev_path and os.path.isfile(prev_path):
            shutil.copy2(prev_path, frame_path)
            print(f"COPIED STATIC HOLD FRAME {f}/{FRAMES}: {frame_path}")
        else:
            scene.render.filepath = frame_path
            bpy.ops.render.render(write_still=True)
            print(f"WROTE FRAME {f}/{FRAMES}: {frame_path}")
            prev_sig = sig
            prev_path = frame_path
