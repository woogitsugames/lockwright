# Lockwright marketing renders & animations: pin-tumbler cutaway (R04-R11, R14-R16).
# Imports art/blender/lw_common.py without modifying art/blender/*.py.
# Example single-command runs:
#   blender -b -P art/blender/marketing/cutaway_anim.py -- --preset R07 --out art/marketing/frames/R07 --res 2160x3840 --samples 128
#   blender -b -P art/blender/marketing/cutaway_anim.py -- --preset R07 --still 1 --out art/marketing/stills/R07_set_macro.png --res 3840x2160 --samples 256
import bpy
import bmesh
import math
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gpu_common import (
    ART_BLENDER_DIR, setup_gpu_cycles, ease_out_cubic, ease_in_out_cubic,
    clamp01, remap, ensure_under_10mb
)
from photo_materials_v2 import apply_photo_materials
from lw_common import *
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default

PRESET = arg('--preset', '') or (arg('--shot', '') if arg('--shot', '').startswith('R') else '')
OUT = arg('--out', 'art/marketing/previews/cutaway_test.png')
RES = [int(v) for v in arg('--res', '540x960').split('x')]
SAMPLES = int(arg('--samples', '64'))
FPS = int(arg('--fps', '30'))
STILL_ONLY = (arg('--still', '0') == '1') or ('--frame' in argv) or OUT.lower().endswith('.png')
STILL_FRAME = int(arg('--still_frame', arg('--frame', '-1')))
FRAME_START = int(arg('--frame_start', '1'))
FRAME_END = int(arg('--frame_end', '-1'))
BIT_DEPTH = arg('--bit_depth', '16')

PRESETS = {
    'R04': {'shot': 'push',        'anim': 'push',      'states': 'e,e,e,e,e', 'frames': 90,  'still_frame': 65, 'tension': 2.0, 'dim': 0.0},
    'R04_V2_FULL': {'shot': 'full_tools', 'anim': 'push', 'states': 'e,e,e,e,e', 'frames': 75, 'still_frame': 55, 'tension': 2.0, 'dim': 0.0},
    'R05': {'shot': 'tension_07',  'anim': 'tension',   'states': 'e,e,e,e,e', 'frames': 30,  'still_frame': 25, 'tension': 2.0, 'dim': 0.0},
    'R06': {'shot': 'pin_c_05',    'anim': 'bind_c',    'states': 'a,e,c,e,e', 'frames': 90,  'still_frame': 55, 'tension': 2.2, 'dim': 0.0},
    'R07': {'shot': 'macro_shear', 'anim': 'set_c',     'states': 'a,b,c,e,e', 'frames': 45,  'still_frame': 30, 'tension': 2.5, 'dim': 0.0},
    'R08': {'shot': 'macro_spool', 'anim': 'spool_b',   'states': 'a,b,a,e,e', 'frames': 60,  'still_frame': 35, 'tension': 4.5, 'dim': 0.0},
    'R09': {'shot': 'counter_06',  'anim': 'counter_b', 'states': 'a,b,a,e,e', 'frames': 60,  'still_frame': 25, 'tension': 4.0, 'dim': 0.0},
    'R10': {'shot': 'section',     'anim': 'dim',       'states': 'a,b,c,e,e', 'frames': 90,  'still_frame': 45, 'tension': 2.5, 'dim': 0.95},
    'R11': {'shot': 'section_open','anim': 'open',      'states': 'a,a,a,a,a', 'frames': 45,  'still_frame': 35, 'tension': 14.0,'dim': 0.0},
    'R14': {'shot': 'macro_d',     'anim': 'overset_d', 'states': 'a,b,a,d,e', 'frames': 45,  'still_frame': 32, 'tension': 2.5, 'dim': 0.0},
    'R15': {'shot': 'stress_06',   'anim': 'break',     'states': 'a,b,c,e,e', 'frames': 60,  'still_frame': 20, 'tension': 3.5, 'dim': 0.0},
    'R16_loupe':      {'shot': 'loupe',      'anim': 'none', 'states': 'a,b,c,d,e', 'frames': 1, 'still_frame': 1, 'tension': 2.2, 'dim': 0.0},
    'R16_microscope': {'shot': 'microscope', 'anim': 'none', 'states': 'a,b,c,d,e', 'frames': 1, 'still_frame': 1, 'tension': 2.2, 'dim': 0.0},
    'R16_borescope':  {'shot': 'borescope',  'anim': 'none', 'states': 'a,b,c,d,e', 'frames': 1, 'still_frame': 1, 'tension': 2.2, 'dim': 0.0},
}

cfg = PRESETS.get(PRESET, {'shot': 'section', 'anim': 'none', 'states': 'a,b,c,d,e', 'frames': 1, 'still_frame': 1, 'tension': 2.0, 'dim': 0.0})
raw_shot = arg('--shot', cfg['shot'])
SHOT = cfg['shot'] if raw_shot in PRESETS else raw_shot
ANIM = arg('--anim', cfg['anim'])
STATES = [s.strip() for s in arg('--states', cfg['states']).split(',')]
FRAMES = int(arg('--frames', str(cfg['frames'])))
TENSION_DEG = float(arg('--tension', str(cfg['tension'])))
DIM_TARGET = float(arg('--dim', str(cfg['dim'])))
if STILL_FRAME < 1:
    STILL_FRAME = cfg['still_frame']

CUT = SHOT != 'borescope'
def section_cut(o, cutter):
    if CUT:
        boolean(o, cutter)
    else:
        bpy.data.objects.remove(cutter, do_unlink=True)

def mark_cut_plane(o, cut_mat):
    if not CUT:
        return o
    if cut_mat.name not in o.data.materials:
        o.data.materials.append(cut_mat)
    mi = list(o.data.materials).index(cut_mat)
    for pg in o.data.polygons:
        if pg.normal.y < -0.95 and abs(pg.center.y) < 0.04:
            pg.material_index = mi
    return o

# ---------------------------------------------------------------- Satin machined materials (roughness >= 0.18, zero chrome)
MAT_SATIN = {
    'nickel_body': metal('nickel_body', (0.58, 0.58, 0.56), 0.28, aniso=0.55, marks='turn', marks_axis=(1, 0, 0), marks_scale=1.1, wear=0.35, grime=0.55, bevel_r=0.05),
    'nickel_cut':  metal('nickel_cut',  (0.62, 0.61, 0.59), 0.25, aniso=0.65, marks='mill', marks_axis=(0, 1, 0), marks_scale=0.9, marks_amt=1.1, wear=0.15, grime=0.35, bevel_r=0.04),
    'brass_plug':  metal('brass_plug',  (0.82, 0.58, 0.26), 0.24, aniso=0.55, marks='turn', marks_axis=(1, 0, 0), marks_scale=1.2, wear=0.45, wear_col=(0.94, 0.74, 0.42), grime=0.55, patina=0.25, bevel_r=0.05),
    'brass_cut':   metal('brass_cut',   (0.85, 0.61, 0.28), 0.22, aniso=0.60, marks='mill', marks_axis=(0, 1, 0), marks_scale=1.0, marks_amt=1.0, wear=0.20, grime=0.35, bevel_r=0.04),
    'brass_shelf': metal('brass_shelf', (0.92, 0.72, 0.38), 0.20, aniso=0.45, marks='turn', marks_axis=(1, 0, 0), marks_scale=1.4, wear=0.50, grime=0.15, bevel_r=0.03),
    'brass_key':   metal('brass_key',   (0.88, 0.66, 0.34), 0.20, aniso=0.50, marks='turn', marks_axis=(0, 0, 1), marks_scale=1.8, wear=0.40, grime=0.30, bevel_r=0.04),
    'steel_drv':   metal('steel_drv',   (0.45, 0.46, 0.49), 0.22, aniso=0.50, marks='turn', marks_axis=(0, 0, 1), marks_scale=1.8, wear=0.35, grime=0.45, bevel_r=0.04),
    'spring_st':   metal('spring_st',   (0.55, 0.56, 0.57), 0.26, aniso=0.30, marks=None, wear=0.1, grime=0.40, bevel_r=0.0),
    'pick_st':     metal('pick_st',     (0.72, 0.72, 0.71), 0.20, aniso=0.65, marks='grind', marks_axis=(1, 0, 0), marks_scale=1.4, wear=0.35, grime=0.25, smudge=0.4, bevel_r=0.04),
    'wrench_st':   metal('wrench_st',   (0.52, 0.53, 0.54), 0.25, aniso=0.55, marks='grind', marks_axis=(0, 0, 1), marks_scale=1.2, wear=0.50, grime=0.40, bevel_r=0.05),
    'cam_dark':    metal('cam_dark',    (0.28, 0.29, 0.31), 0.32, aniso=0.40, marks='stamp', marks_scale=0.8, wear=0.65, grime=0.70, bevel_r=0.06),
    'bolt_brass':  metal('bolt_brass',  (0.76, 0.54, 0.25), 0.26, aniso=0.50, marks='grind', marks_axis=(1, 0, 0), wear=0.6, grime=0.55, bevel_r=0.08),
    'scale_ink':   dark_mat('scale_ink', (0.025, 0.022, 0.020), rough=0.75),
}
M['brass_k'] = MAT_SATIN['brass_key']
M['steel'] = MAT_SATIN['steel_drv']
M['spring'] = MAT_SATIN['spring_st']
M['pick'] = MAT_SATIN['pick_st']

# D-48 / D-49: use photographic PBR maps if available, keeping procedural fallback.
# Supply --require_photo 1 for GEM1-v2 final renders to prohibit silent fallback.
PHOTO_PBR_REPORT = apply_photo_materials(MAT_SATIN, strict=(arg('--require_photo', '0') == '1'))

# ---------------------------------------------------------------- Static housing, door, escutcheon
PINS_X = [5.0, 9.0, 13.0, 17.0, 21.0]
KEY_LEN = [4.6, 4.8, 4.9, 5.4, 4.2]
DRV_LEN = [4.0, 4.4, 4.0, 4.0, 4.0]
R_HOUSE, R_PLUG, TOWER_W, TOWER_TOP, LEN = 8.5, 6.4, 10.0, 24.0, 30.0
SHEAR = R_PLUG  # z = 6.4
CHAMBER_R = 1.55
KEYWAY = (-5.2, 2.6)
TOP = TOWER_TOP - 2.0 - 0.4
KP_FLOOR = KEYWAY[1] - 1.4

house = cyl('housing', R_HOUSE, LEN, (LEN / 2, 0, 0), axis='X', verts=96)
tower = box('tower', 0, LEN, -TOWER_W / 2, TOWER_W / 2, 0, TOWER_TOP - TOWER_W / 2)
boolean(house, tower, 'UNION')
cap = cyl('towercap', TOWER_W / 2, LEN, (LEN / 2, 0, TOWER_TOP - TOWER_W / 2), axis='X', verts=64)
boolean(house, cap, 'UNION')
boolean(house, cyl('bore', R_PLUG + 0.22, LEN + 2, (LEN / 2, 0, 0), axis='X', verts=128))
for x in PINS_X:
    boolean(house, cyl('ch', CHAMBER_R, TOWER_TOP, (x, 0, SHEAR + (TOWER_TOP - 1.2 - SHEAR) / 2 - 0.4), verts=48))
section_cut(house, box('cut', -1, LEN + 1, -20, 0, -20, 40))
link(house, MAT_SATIN['nickel_body'])
mark_cut_plane(house, MAT_SATIN['nickel_cut'])
bevel(house, 0.09)

# Plug with keyway and chambers (cut plane stays flush at y=0 so chambers are never occluded)
plug = cyl('plug', R_PLUG, LEN + 1.5, (LEN / 2 - 0.75, 0, 0), axis='X', verts=128)
boolean(plug, box('keyway', -2, LEN - 1.5, -1.2, 1.2, KEYWAY[0], KEYWAY[1]))
boolean(plug, box('ward', -2, LEN - 1.5, -2.0, 2.0, -1.4, 0.2))
for x in PINS_X:
    boolean(plug, cyl('pc', CHAMBER_R, 6, (x, 0, KEYWAY[1] + 1.5)))
section_cut(plug, box('cut', -3, LEN + 2, -20, 0, -20, 20))
link(plug, MAT_SATIN['brass_plug'])
mark_cut_plane(plug, MAT_SATIN['brass_cut'])
bevel(plug, 0.09)

# Warm brass reflective backing inside lower plug chambers (behind pins, y=2.7..3.0) so that when a pin is SET
# and a gap opens between key pin and driver pin below SHEAR, a crisp bright gap ("jasna szczelina") is visible!
if CUT:
    for x in PINS_X:
        gap_back = box('gap_refl_%d' % int(x), x - 1.35, x + 1.35, 2.75, 3.05, SHEAR - 0.85, SHEAR + 0.05)
        link(gap_back, MAT_SATIN['brass_shelf'])

# Front collar with engraved rotation ticks (HUD.md §3: 12 ticks every 7.5 deg)
collar = cyl('collar', R_HOUSE + 0.6, 1.6, (-0.8, 0, 0), axis='X', verts=128)
boolean(collar, box('kw2', -3, 1, -1.2, 1.2, KEYWAY[0], KEYWAY[1]))
boolean(collar, cyl('inner', R_PLUG + 0.05, 4, (-0.8, 0, 0), axis='X', verts=128))
section_cut(collar, box('cut', -3, 2, -20, 0, -20, 20))
link(collar, MAT_SATIN['nickel_body'])
mark_cut_plane(collar, MAT_SATIN['nickel_cut'])
bevel(collar, 0.10)

if CUT:
    for k in range(7):
        ang = math.radians(k * 7.5)
        r0 = R_PLUG + 0.15
        r1 = R_PLUG + (0.95 if k in (0, 2) else 0.65)
        tk = box('scale_tick_%d' % k, -1.65, -1.52, r0 * math.sin(ang) - 0.08, r1 * math.sin(ang) + 0.08,
                 r0 * math.cos(ang) - 0.08, r1 * math.cos(ang) + 0.08)
        link(tk, MAT_SATIN['scale_ink'])

# Bore plugs (caps) closing the chambers at the top of the tower
for x in PINS_X:
    c = cyl('cap', CHAMBER_R + 0.02, 1.2, (x, 0, TOWER_TOP - 1.6 - 0.4 + 0.6))
    section_cut(c, box('cut', x - 3, x + 3, -5, 0, 0, 40))
    link(c, MAT_SATIN['brass_plug'])
    mark_cut_plane(c, MAT_SATIN['brass_cut'])
    bevel(c, 0.08)

# Rear actuator cam & deadbolt in mortise (clearly visible on the right of the cylinder in R11)
cam_lug = box('cam_lug', LEN + 0.2, LEN + 2.8, 0.2, 4.2, -9.5, 4.5)
link(cam_lug, MAT_SATIN['cam_dark']); bevel(cam_lug, 0.15)
deadbolt = box('deadbolt', LEN + 3.0, LEN + 15.0, 0.1, 7.5, -7.5, 3.5)
link(deadbolt, MAT_SATIN['bolt_brass']); bevel(deadbolt, 0.25)

# Door + escutcheon
door = box('door', 0.0, 44, 0, 24, -60, 60)
prof = cyl('hole', R_HOUSE + 0.3, 60, (22, 0, 0), axis='X', verts=96)
t2 = box('t2', -5, 50, -TOWER_W / 2 - 0.3, TOWER_W / 2 + 0.3, 0, TOWER_TOP - TOWER_W / 2)
boolean(prof, t2, 'UNION')
boolean(prof, cyl('t3', TOWER_W / 2 + 0.3, 60, (22, 0, TOWER_TOP - TOWER_W / 2), axis='X'), 'UNION')
boolean(prof, box('mortise_pocket', LEN - 0.2, 45, -8, 12, -14, 8), 'UNION')
boolean(door, prof)
link(door, oak('door_oak_cut', light=(0.40, 0.25, 0.12), dark=(0.17, 0.09, 0.04), axis='Z', ring_mm=2.4, lacquer=0.7, rough=0.48, wear=0.5, grime=0.7, seed=2.0))
bevel(door, 0.3)

esc = box('escutcheon', -3.2, 0.0, 0, 14, -34, 44)
hole = cyl('eh', R_HOUSE + 0.9, 8, (-1.6, 0, 0), axis='X', verts=96)
boolean(esc, hole)
link(esc, M['iron']); bevel(esc, 0.4)

back = box('back', -80, 80, 30, 31, -80, 80)
link(back, M['recess'])

# ---------------------------------------------------------------- Dynamic objects builder per frame
DYNAMIC_PREFIXES = ('pin_dyn_', 'spr_dyn_', 'pick_dyn', 'pick_tip_dyn', 'pick_handle_dyn', 'wrench_dyn', 'stress_mark_', 'plug_tick_dyn', 'shelf_dyn_')

def clear_dynamic():
    for o in list(bpy.data.objects):
        if o.name.startswith(DYNAMIC_PREFIXES):
            me = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            if me and me.users == 0:
                if isinstance(me, bpy.types.Mesh):
                    bpy.data.meshes.remove(me)
                elif isinstance(me, bpy.types.Curve):
                    bpy.data.curves.remove(me)

def make_spring_phased(name, x, z0, z1, coils, r=1.15, wire=0.22, y=1.5, phase=0.0):
    cu = bpy.data.curves.new(name, 'CURVE')
    cu.dimensions = '3D'
    cu.bevel_depth = wire
    cu.bevel_resolution = 4
    sp = cu.splines.new('POLY')
    n = int(coils * 24)
    sp.points.add(n)
    L = max(1.2, z1 - z0)
    w = wire * 2.05
    e = 1.0 / coils
    for i in range(n + 1):
        t = i / n
        a = t * coils * 2 * math.pi + phase
        if t < e:
            zt = (t / e) * w
        elif t > 1 - e:
            zt = L - ((1 - t) / e) * w
        else:
            zt = w + (t - e) / (1 - 2 * e) * (L - 2 * w)
        sp.points[i].co = (x + r * math.cos(a), y + r * math.sin(a), z0 + zt, 1)
    o = bpy.data.objects.new(name, cu)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(MAT_SATIN['spring_st'])
    return o

def spool_deep(name, x, z0, length, waist_z, r=1.42, wr=0.72, y=1.5):
    """Spool driver pin with a deep, crisp hourglass waist that unmistakably straddles the shear line in grayscale."""
    h = 0.62
    prof = [
        (r - 0.16, z0),
        (r, z0 + 0.16),
        (r, waist_z - h - 0.18),
        (wr, waist_z - h + 0.04),
        (wr, waist_z + h - 0.04),
        (r, waist_z + h + 0.18),
        (r, z0 + length - 0.16),
        (r - 0.16, z0 + length)
    ]
    return link(lathe(name, prof, x, y=y), MAT_SATIN['steel_drv'])

def build_pin_stack(idx, state_code, lift_override=None, tilt_override=None, spool_progress=None, plug_deg=2.0):
    x = PINS_X[idx]
    klen = KEY_LEN[idx]
    dlen = DRV_LEN[idx]
    y_pos = 0.0 if SHOT == 'borescope' else 1.5
    phase = idx * 1.15
    wire = 0.22
    tilt = 0.0
    dx_bind = 0.0

    if state_code == 'a':  # SET: driver seated on plug shelf above shear, key pin dropped, clear bright gap below!
        kz = (KP_FLOOR - 0.25) if lift_override is None else KP_FLOOR + lift_override
        dz = SHEAR + 0.34
        # Small visible brass shelf lip at z = SHEAR..SHEAR+0.34 showing the rotated plug edge supporting the driver pin
        if CUT and plug_deg >= 1.5:
            sh = box('shelf_dyn_%d' % idx, x - 1.38, x - 0.65, 0.15, 1.35, SHEAR - 0.05, SHEAR + 0.32)
            link(sh, MAT_SATIN['brass_shelf'])
    elif state_code == 'b':  # FALSE SET: spool waist caught across shear line
        kz = KP_FLOOR if lift_override is None else KP_FLOOR + lift_override
        dz = KP_FLOOR + klen if spool_progress is None else spool_progress
    elif state_code == 'c':  # BINDING / NEAR SHEAR: lifted by pick, driver tilted and pressed to chamber wall
        lift = 1.05 if lift_override is None else lift_override
        kz = KP_FLOOR + lift
        dz = kz + klen + 0.05
        tilt = math.radians(-2.6 if tilt_override is None else tilt_override)
        dx_bind = 0.08
    elif state_code == 'd':  # OVERSET: key pin pushed above shear line, spring compressed nearly solid
        lift = 3.30 if lift_override is None else lift_override
        kz = KP_FLOOR + lift
        dz = kz + klen
        wire = 0.25
    else:  # 'e' FREE: resting on keyway floor, driver straddling shear line
        lift = 0.0 if lift_override is None else lift_override
        kz = KP_FLOOR + lift
        dz = kz + klen

    kp = pin('pin_dyn_k_%d' % idx, x + dx_bind * 0.4, kz, klen, tip=True, mat='brass_k')
    if SHOT == 'borescope':
        kp.matrix_world = Matrix.Translation((0, -1.5, 0)) @ kp.matrix_world

    if idx == 1 and state_code in ('b', 'counter'):
        waist_center = dz + (SHEAR - (KP_FLOOR + klen)) + 0.05
        dp = spool_deep('pin_dyn_d_%d' % idx, x + dx_bind, dz, dlen, waist_center, r=1.42, wr=0.72, y=y_pos)
    else:
        dp = pin('pin_dyn_d_%d' % idx, x + dx_bind, dz, dlen, tilt=tilt, mat='steel')
        if SHOT == 'borescope':
            dp.matrix_world = Matrix.Translation((0, -1.5, 0)) @ dp.matrix_world

    spr_z0 = dz + dlen + 0.08
    make_spring_phased('spr_dyn_%d' % idx, x, spr_z0, TOP, 9, r=1.15, wire=wire, y=y_pos, phase=phase)


# ---------------------------------------------------------------- Lights & Camera setup
w = scene.world = bpy.data.worlds.new('w')
w.use_nodes = True
env = w.node_tree.nodes.new('ShaderNodeTexEnvironment')
env.image = bpy.data.images.load(os.path.join(bpy.utils.resource_path('LOCAL'), 'datafiles', 'studiolights', 'world', 'interior.exr'))
bg = w.node_tree.nodes['Background']
bg.inputs['Strength'].default_value = 0.22
w.node_tree.links.new(env.outputs['Color'], bg.inputs['Color'])

AIM = bpy.data.objects.new('aim', None)
scene.collection.objects.link(AIM)
AIM.location = (13, 0, 7)

def area(name, loc, size, energy, color):
    bpy.ops.object.light_add(type='AREA', location=loc)
    L = bpy.context.object
    L.name = name
    L.data.size = size
    L.data.energy = energy
    L.data.color = color
    c = L.constraints.new('TRACK_TO')
    c.target = AIM
    c.track_axis = 'TRACK_NEGATIVE_Z'
    c.up_axis = 'UP_Y'
    return L

L_key = area('key', (-70, -45, 120), 50, 1150, (1.0, 0.84, 0.66))
L_fill = area('fill', (110, -90, 0), 90, 130, (0.94, 0.96, 1.0))
L_rim = area('rim', (20, -30, -90), 30, 140, (1.0, 0.95, 0.9))
sheen_dir = Vector((math.sin(math.radians(24)), -math.cos(math.radians(24)), -math.sin(math.radians(11)))).normalized() * 260
L_sheen = area('sheen', tuple(Vector((14.5, 0, 8)) + sheen_dir + Vector((0, 0, 40))), 160, 210, (1.0, 0.97, 0.92))
BASE_ENERGIES = {'key': 1150.0, 'fill': 130.0, 'rim': 140.0, 'sheen': 210.0}

cam_d = bpy.data.cameras.new('cam')
cam = bpy.data.objects.new('cam', cam_d)
scene.collection.objects.link(cam)
scene.camera = cam
cam_d.lens = 180
cam_d.sensor_fit = 'HORIZONTAL'
cam_d.sensor_width = 36
cam_d.dof.use_dof = False

def set_cam_orbit(target_vec, dist, yaw_deg=-22.0, pitch_deg=10.0, lens=180.0):
    cam_d.lens = lens
    cam_d.dof.use_dof = False
    yaw = math.radians(yaw_deg)
    pitch = math.radians(pitch_deg)
    t = Vector(target_vec)
    cam.location = t + Vector((math.sin(yaw) * dist, -math.cos(yaw) * dist * math.cos(pitch), math.sin(pitch) * dist))
    cam.rotation_euler = (t - cam.location).to_track_quat('-Z', 'Y').to_euler()
    AIM.location = t

def optics_post(dispersion=0.0, distortion=0.0, vignette=0.0, soft=0.25):
    scene.use_nodes = True
    nt = scene.node_tree
    nt.nodes.clear()
    rl = nt.nodes.new('CompositorNodeRLayers')
    comp = nt.nodes.new('CompositorNodeComposite')
    img = rl.outputs['Image']
    if dispersion or distortion:
        ld = nt.nodes.new('CompositorNodeLensdist')
        ld.use_fit = distortion > 0
        ld.inputs['Distortion'].default_value = distortion
        ld.inputs['Dispersion'].default_value = dispersion
        nt.links.new(img, ld.inputs['Image'])
        img = ld.outputs['Image']
    if vignette:
        em = nt.nodes.new('CompositorNodeEllipseMask')
        em.width = em.height = 1.0 - soft * 0.6
        em.inputs['Value'].default_value = 1.0
        bl = nt.nodes.new('CompositorNodeBlur')
        bl.filter_type = 'GAUSS'
        bl.use_relative = True
        bl.factor_x = bl.factor_y = soft * 100
        bl.size_x = bl.size_y = 1
        nt.links.new(em.outputs['Mask'], bl.inputs['Image'])
        mr = nt.nodes.new('CompositorNodeMapRange')
        mr.inputs['To Min'].default_value = 1.0 - vignette
        nt.links.new(bl.outputs['Image'], mr.inputs['Value'])
        mx = nt.nodes.new('CompositorNodeMixRGB')
        mx.blend_type = 'MULTIPLY'
        mx.inputs['Fac'].default_value = 1.0
        nt.links.new(img, mx.inputs[1])
        nt.links.new(mr.outputs['Value'], mx.inputs[2])
        img = mx.outputs['Image']
    nt.links.new(img, comp.inputs['Image'])

def emitter(name, obj, strength, color=(1.0, 0.96, 0.9)):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    e = nt.nodes.new('ShaderNodeEmission')
    e.inputs['Strength'].default_value = strength
    e.inputs['Color'].default_value = (*color, 1)
    o = nt.nodes.new('ShaderNodeOutputMaterial')
    nt.links.new(e.outputs[0], o.inputs['Surface'])
    obj.data.materials.clear()
    obj.data.materials.append(m)
    obj.visible_camera = False
    return obj

if SHOT == 'loupe':
    set_cam_orbit((PINS_X[2], 0.0, SHEAR), 42.0, yaw_deg=-22.0, pitch_deg=10.0, lens=180.0)
    optics_post(dispersion=0.004, vignette=0.35, soft=0.3)
elif SHOT == 'microscope':
    set_cam_orbit(((PINS_X[0] + PINS_X[1]) / 2, 0.0, SHEAR + 0.2), 30.0, yaw_deg=-14.0, pitch_deg=6.0, lens=180.0)
    ax = (AIM.location - cam.location).normalized()
    bpy.ops.mesh.primitive_torus_add(major_radius=28.0, minor_radius=2.0, major_segments=96, minor_segments=12)
    ring = bpy.context.object
    ring.name = 'led_ring'
    ring.location = AIM.location - ax * 70.0
    ring.rotation_euler = ax.to_track_quat('Z', 'Y').to_euler()
    emitter('ring_led', ring, 12.0, (1.0, 0.97, 0.92))
    optics_post(dispersion=0.010, vignette=0.45, soft=0.3)
elif SHOT == 'borescope':
    bx_p, by_p, bz_p = 13.0, -0.5, -2.6
    tx_p, ty_p, tz_p = 13.0, 0.15, 2.6
    cam.location = Vector((bx_p, by_p, bz_p))
    cam.rotation_euler = (Vector((tx_p, ty_p, tz_p)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    cam_d.lens = 10.0
    cam_d.clip_start = 0.05
    cam_d.dof.use_dof = False
    bg.inputs['Strength'].default_value = 0.02
    for L in (L_key, L_fill, L_rim, L_sheen):
        L.hide_render = True
    fwd = (Vector((tx_p, ty_p, tz_p)) - cam.location).normalized()
    q = cam.rotation_euler.to_quaternion()
    right = q @ Vector((1, 0, 0))
    upv = q @ Vector((0, 1, 0))
    for k in range(6):
        a = 2 * math.pi * (k + 0.5) / 6
        p = cam.location + (right * math.cos(a) + upv * math.sin(a)) * 0.6 + fwd * 0.05
        bpy.ops.object.light_add(type='POINT', location=p)
        L = bpy.context.object
        L.name = 'led%d' % k
        L.data.energy = 150.0
        L.data.shadow_soft_size = 0.12
        L.data.color = (1.0, 0.97, 0.93)
    optics_post(dispersion=0.006, distortion=0.05, vignette=0.42, soft=0.35)


# ---------------------------------------------------------------- Frame update logic
def update_scene_for_frame(f, prev_sig=None):
    t_norm = (f - 1) / max(1, FRAMES - 1)

    states = list(STATES)
    plug_deg = TENSION_DEG * 0.75
    wrench_deg = TENSION_DEG
    dim_fac = 0.0
    pick_x = PINS_X[2]
    pick_tip_z = KP_FLOOR + 0.45
    pick_stress = 0.0
    pick_broken = False
    lift_ov = [None] * 5
    tilt_ov = [None] * 5
    spool_prog = None
    bolt_retract = 0.0

    # --- Camera framing per shot ---
    if SHOT == 'full_tools':  # R04_V2_FULL, deliberately frame both pick and tension wrench
        u = ease_in_out_cubic(t_norm)
        set_cam_orbit((-7.5, 0.0, -8.0), 330.0 - 14.0 * u,
                      yaw_deg=-18.0, pitch_deg=8.0, lens=82.0)
    elif SHOT == 'push':  # R04
        u = ease_in_out_cubic(t_norm)
        tx = 13.5 * (1 - u) + 13.0 * u
        tz = 9.0 * (1 - u) + 6.8 * u
        dist = 158.0 * (1 - u) + 106.0 * u
        set_cam_orbit((tx, 0.0, tz), dist)
    elif SHOT == 'tension_07':  # R05
        set_cam_orbit((4.5, 0.0, 1.5), 102.0, yaw_deg=-26.0, pitch_deg=8.0)
    elif SHOT == 'pin_c_05':  # R06
        set_cam_orbit((PINS_X[2], 0.0, SHEAR + 0.4), 76.0)
    elif SHOT == 'macro_shear':  # R07
        set_cam_orbit((PINS_X[2], 0.0, SHEAR), 42.0)
    elif SHOT == 'macro_spool':  # R08
        set_cam_orbit((PINS_X[1], 0.0, SHEAR + 0.1), 44.0)
    elif SHOT == 'counter_06':  # R09
        set_cam_orbit((6.5, 0.0, 3.2), 94.0, yaw_deg=-24.0, pitch_deg=9.0)
    elif SHOT == 'section_open':  # R11
        set_cam_orbit((17.5, 0.0, 6.5), 178.0)
    elif SHOT == 'macro_d':  # R14
        set_cam_orbit((PINS_X[3], 0.0, SHEAR + 0.8), 48.0)
    elif SHOT == 'stress_06':  # R15
        set_cam_orbit((8.5, 0.0, 1.2), 92.0)
    elif SHOT == 'section':
        set_cam_orbit((13.5, 0.0, 9.0), 158.0)

    # --- Animation curves ---
    if ANIM == 'push':  # R04
        u = ease_out_cubic(remap(f, 15, 65))
        wrench_deg = 2.0 * u
        plug_deg = 1.5 * u
        pick_x = PINS_X[2] - 4.0 * (1 - u)
        pick_tip_z = KP_FLOOR - 0.3

    elif ANIM == 'tension':  # R05
        u = ease_out_cubic(remap(f, 4, 22))
        wrench_deg = 2.5 * u
        plug_deg = 2.0 * u
        pick_x = PINS_X[0] - 2.0
        pick_tip_z = KP_FLOOR - 0.4

    elif ANIM == 'bind_c':  # R06
        u_lift = ease_out_cubic(remap(f, 4, 26))
        states[2] = 'c'
        lift_ov[2] = 0.2 + 0.90 * u_lift
        vib = 0.32 * math.sin(2.0 * math.pi * 3.0 * remap(f, 22, 62)) if 22 <= f <= 62 else 0.0
        tilt_ov[2] = -2.6 * u_lift + vib
        pick_x = PINS_X[2]
        pick_tip_z = KP_FLOOR + lift_ov[2] - 0.45 + (0.06 * math.sin(2.0 * math.pi * 3.0 * remap(f, 22, 62)) if 22 <= f <= 62 else 0.0)
        wrench_deg = 2.2
        plug_deg = 1.6

    elif ANIM == 'set_c':  # R07: driver pin c seats in 5 frames, key pin drops leaving bright gap
        if f < 6:
            states[2] = 'c'
            lift_ov[2] = 1.15 + 0.25 * (f / 6.0)
            tilt_ov[2] = -2.2
            pick_tip_z = KP_FLOOR + lift_ov[2] - 0.45
            plug_deg = 1.5
            wrench_deg = 2.2
        elif f <= 11:
            u = ease_out_cubic(remap(f, 6, 11))
            states[2] = 'a'
            lift_ov[2] = 1.40 * (1.0 - u) - 0.25 * u
            pick_tip_z = KP_FLOOR + 1.40 * (1.0 - 0.75 * u) - 0.45
            plug_deg = 1.5 + 2.0 * u
            wrench_deg = 2.2 + 1.5 * u
        else:
            u_drop = ease_out_cubic(remap(f, 11, 18))
            states[2] = 'a'
            lift_ov[2] = -0.25
            pick_tip_z = KP_FLOOR + (0.35 * (1.0 - u_drop)) - 0.55
            plug_deg = 3.5
            wrench_deg = 3.7

    elif ANIM == 'spool_b':  # R08: plug rotates deeper (+4 deg in 6 frames), spool waist catches on shear line
        pick_x = PINS_X[1]
        if f < 8:
            states[1] = 'c'
            lift_ov[1] = 0.6 + 0.3 * (f / 8.0)
            plug_deg = 2.5
            wrench_deg = 2.8
            pick_tip_z = KP_FLOOR + lift_ov[1] - 0.45
        else:
            u = ease_out_cubic(remap(f, 8, 14))
            states[1] = 'b'
            lift_ov[1] = 0.9 * (1.0 - u)
            spool_prog = (KP_FLOOR + KEY_LEN[1] + 0.65) * (1.0 - u) + (KP_FLOOR + KEY_LEN[1]) * u
            plug_deg = 2.5 + 4.5 * u
            wrench_deg = 2.8 + 4.0 * u
            pick_tip_z = KP_FLOOR + 0.3 * (1.0 - u) - 0.45

    elif ANIM == 'counter_b':  # R09
        pick_x = PINS_X[1]
        if f < 10:
            states[1] = 'b'
            plug_deg = 7.0
            wrench_deg = 6.8
            pick_tip_z = KP_FLOOR + 0.2
        elif f <= 34:
            u = ease_in_out_cubic(remap(f, 10, 34))
            states[1] = 'b'
            lift_ov[1] = 1.35 * u
            spool_prog = (KP_FLOOR + KEY_LEN[1]) + 1.35 * u
            plug_deg = 7.0 - 4.0 * u
            wrench_deg = 6.8 - 3.8 * u
            pick_tip_z = KP_FLOOR + lift_ov[1] - 0.45
        else:
            u = ease_out_cubic(remap(f, 34, 40))
            states[1] = 'a'
            lift_ov[1] = 1.35 * (1.0 - u) - 0.25 * u
            plug_deg = 3.0 + 1.5 * u
            wrench_deg = 3.0 + 1.5 * u
            pick_tip_z = KP_FLOOR + 0.6 * (1.0 - u) - 0.55

    elif ANIM == 'dim':  # R10: light 100% -> 5% in 12 frames, then darkness with subtle spring glint
        u_dim = ease_out_cubic(remap(f, 4, 16))
        dim_fac = 0.95 * u_dim
        if f >= 40:
            states[2] = 'a'
        if f >= 68:
            states[1] = 'a'
        plug_deg = 2.0 + (1.5 if f >= 40 else 0.0) + (1.5 if f >= 68 else 0.0)
        wrench_deg = 2.5 + (1.2 if f >= 40 else 0.0) + (1.2 if f >= 68 else 0.0)
        pick_x = PINS_X[2] if f < 52 else PINS_X[1]
        pick_tip_z = KP_FLOOR + 0.4

    elif ANIM == 'open':  # R11: all pins set, plug rotates 90 deg in 20 frames, cam retracts deadbolt
        states = ['a', 'a', 'a', 'a', 'a']
        u = ease_in_out_cubic(remap(f, 6, 26))
        plug_deg = 4.0 + 86.0 * u
        wrench_deg = 4.0 + 14.0 * u
        bolt_retract = -9.5 * u  # retracts deadbolt left into the housing!
        pick_x = PINS_X[4]
        pick_tip_z = KP_FLOOR - 0.4

    elif ANIM == 'overset_d':  # R14
        pick_x = PINS_X[3]
        u = ease_out_cubic(remap(f, 8, 16))
        states[3] = 'd' if f >= 12 else 'c'
        lift_ov[3] = 0.8 + 2.50 * u
        pick_tip_z = KP_FLOOR + lift_ov[3] - 0.45
        plug_deg = 2.2 * (1.0 - 0.4 * u)
        wrench_deg = 2.5

    elif ANIM == 'break':  # R15
        pick_x = PINS_X[2]
        states[2] = 'c'
        lift_ov[2] = 0.9
        tilt_ov[2] = -2.8
        if f < 24:
            u_st = ease_out_cubic(remap(f, 4, 19))
            pick_stress = u_st
            tremor = 0.14 * math.sin(f * 2.4) if f >= 16 else 0.0
            pick_tip_z = KP_FLOOR + 0.45 + tremor
            wrench_deg = 3.0 + 2.0 * u_st
        else:
            pick_broken = True
            pick_stress = remap(f, 24, 30)
            wrench_deg = 5.0 - 2.5 * ease_out_cubic(remap(f, 24, 32))

    # Apply light dimming (R10)
    light_mult = 1.0 - dim_fac
    L_key.data.energy = BASE_ENERGIES['key'] * light_mult
    L_fill.data.energy = BASE_ENERGIES['fill'] * light_mult
    L_rim.data.energy = BASE_ENERGIES['rim'] * (1.0 - dim_fac * 0.88)
    L_sheen.data.energy = BASE_ENERGIES['sheen'] * light_mult
    bg.inputs['Strength'].default_value = 0.22 * (1.0 - dim_fac * 0.95)

    # Rear cam rotation and deadbolt retraction
    cam_lug.rotation_euler = (math.radians(plug_deg), 0, 0)
    deadbolt.location = (bolt_retract, 0, 0)

    cam_sig = tuple(round(v, 4) for v in cam.location) + tuple(round(v, 4) for v in cam.rotation_euler)
    sig = (
        cam_sig,
        tuple(states),
        round(plug_deg, 4),
        round(wrench_deg, 4),
        round(dim_fac, 4),
        round(pick_x, 4),
        round(pick_tip_z, 4),
        round(pick_stress, 4),
        bool(pick_broken),
        tuple(None if v is None else round(v, 4) for v in lift_ov),
        tuple(None if v is None else round(v, 4) for v in tilt_ov),
        None if spool_prog is None else round(spool_prog, 4),
        round(bolt_retract, 4),
    )
    if prev_sig is not None and sig == prev_sig:
        return sig

    clear_dynamic()

    # Rotating reference indicator on plug front face (shows plug_deg against collar scale ticks)
    if CUT:
        p_ang = math.radians(min(plug_deg, 45.0))
        r_in, r_out = R_PLUG - 1.2, R_PLUG - 0.08
        ptk = box('plug_tick_dyn', -1.56, -1.42,
                  r_in * math.sin(p_ang) - 0.1, r_out * math.sin(p_ang) + 0.1,
                  r_in * math.cos(p_ang) - 0.1, r_out * math.cos(p_ang) + 0.1)
        link(ptk, MAT_SATIN['scale_ink'])

    # Build the 5 pin stacks
    for idx in range(5):
        build_pin_stack(idx, states[idx], lift_override=lift_ov[idx], tilt_override=tilt_ov[idx],
                        spool_progress=(spool_prog if idx == 1 else None), plug_deg=plug_deg)

    # Build hook pick & handle
    dx_shift = pick_x - PINS_X[2]
    if not pick_broken:
        bow = -1.85 * pick_stress
        hook = [
            (-46 + dx_shift, -3.6 - 0.4 * pick_stress),
            (-25 + dx_shift, -3.55 + bow * 0.5),
            (-5 + dx_shift,  -3.45 + bow),
            (5 + dx_shift,   -3.3 + bow * 0.7),
            (9.5 + dx_shift, -3.05 + bow * 0.3),
            (11.6 + dx_shift, -2.5),
            (12.5 + dx_shift, -1.4),
            (12.85 + dx_shift, pick_tip_z)
        ]
        p_obj = flat_tool('pick_dyn', hook, 1.1, 0.55, 0.6)
        p_obj.data.materials[0] = MAT_SATIN['pick_st']
        if pick_stress >= 0.5:
            n_marks = 1 if pick_stress < 0.7 else (2 if pick_stress < 0.88 else 3)
            for mk_i in range(n_marks):
                mx = -6.0 + dx_shift + mk_i * 1.4
                mz = -3.45 + bow
                sm = box('stress_mark_%d' % mk_i, mx - 0.12, mx + 0.12, 0.28, 0.92, mz - 0.58, mz + 0.58)
                link(sm, MAT_SATIN['scale_ink'])
        h_obj = box('pick_handle_dyn', -60 + dx_shift, -44 + dx_shift, 0.1, 2.2, -4.6, -2.2)
        link(h_obj, M['handle']); bevel(h_obj, 0.5)
    else:
        recoil = -6.0 * ease_out_cubic(remap(f, 24, 30))
        shaft_pts = [
            (-46 + recoil, -3.8),
            (-25 + recoil, -3.7),
            (-5 + recoil,  -3.6),
            (4.2 + recoil, -3.5)
        ]
        p_shaft = flat_tool('pick_dyn', shaft_pts, 1.1, 0.55, 0.6, tip='flat')
        p_shaft.data.materials[0] = MAT_SATIN['pick_st']
        tip_pts = [
            (7.5, -3.2),
            (9.8, -3.0),
            (11.6, -2.5),
            (12.5, -1.4),
            (12.85, KP_FLOOR + 0.35)
        ]
        p_tip = flat_tool('pick_tip_dyn', tip_pts, 1.1, 0.55, 0.6)
        p_tip.data.materials[0] = MAT_SATIN['pick_st']
        h_obj = box('pick_handle_dyn', -60 + recoil, -44 + recoil, 0.1, 2.2, -4.8, -2.4)
        link(h_obj, M['handle']); bevel(h_obj, 0.5)

    # Build tension wrench
    w_rad = math.radians(wrench_deg)
    wr = [
        (4.0, -4.6),
        (-3.2, -4.6),
        (-4.3, -4.9 - 0.15 * (wrench_deg / 3.0)),
        (-4.9 - 0.2 * math.sin(w_rad), -5.8),
        (-5.0 - 0.4 * math.sin(w_rad), -7.2),
        (-5.0 - 33.0 * math.sin(w_rad), -40.0 * math.cos(w_rad))
    ]
    w_obj = flat_tool('wrench_dyn', wr, 1.5, 0.75, 0.4, tip='flat')
    w_obj.data.materials[0] = MAT_SATIN['wrench_st']

    return sig


# ---------------------------------------------------------------- Render execution
import shutil
import time
backend, gpu_name = setup_gpu_cycles(
    scene, samples=SAMPLES, denoiser='OPTIX', use_dof=False, persistent=True, color_depth=BIT_DEPTH
)
if str(BIT_DEPTH) != '8':
    scene.cycles.max_bounces = 8
scene.view_settings.exposure = 0.15
scene.render.resolution_x, scene.render.resolution_y = RES
scene.render.film_transparent = False
scene.view_settings.view_transform = 'AgX'
scene.view_settings.look = 'AgX - Medium High Contrast'
if SHOT == 'borescope':
    scene.cycles.max_bounces = 6
    scene.cycles.glossy_bounces = 4
    scene.cycles.adaptive_threshold = 0.01

BATCH_PRESETS = [p.strip() for p in arg('--batch_presets', '').split(',') if p.strip()]
if BATCH_PRESETS:
    base_out = os.path.abspath(OUT)
    for bp in BATCH_PRESETS:
        bcfg = PRESETS[bp]
        PRESET = bp
        SHOT = bcfg['shot']
        ANIM = bcfg['anim']
        STATES = [s.strip() for s in bcfg['states'].split(',')]
        FRAMES = int(bcfg['frames'])
        TENSION_DEG = float(bcfg['tension'])
        DIM_TARGET = float(bcfg['dim'])
        out_dir = os.path.join(base_out, bp)
        os.makedirs(out_dir, exist_ok=True)
        t0_p = time.time()
        prev_sig = None
        prev_path = None
        print(f"[cutaway_anim] Starting batch preset={bp} Shot={SHOT} Anim={ANIM} Frames={FRAMES}", flush=True)
        for f in range(1, FRAMES + 1):
            frame_path = os.path.join(out_dir, f"frame_{f:04d}.png")
            sig = update_scene_for_frame(f, prev_sig=prev_sig)
            if prev_sig is not None and sig == prev_sig and prev_path and os.path.isfile(prev_path):
                shutil.copy2(prev_path, frame_path)
            else:
                scene.render.filepath = frame_path
                bpy.ops.render.render(write_still=True)
                prev_sig = sig
                prev_path = frame_path
        dt_p = time.time() - t0_p
        print(f"[cutaway_anim] FINISHED_PRESET {bp} in {dt_p:.2f}s ({FRAMES} frames)", flush=True)
elif STILL_ONLY or FRAMES == 1:
    update_scene_for_frame(STILL_FRAME)
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
        sig = update_scene_for_frame(f, prev_sig=prev_sig)
        if prev_sig is not None and sig == prev_sig and prev_path and os.path.isfile(prev_path):
            shutil.copy2(prev_path, frame_path)
            print(f"COPIED STATIC HOLD FRAME {f}/{FRAMES}: {frame_path}")
        else:
            scene.render.filepath = frame_path
            bpy.ops.render.render(write_still=True)
            print(f"WROTE FRAME {f}/{FRAMES}: {frame_path}")
            prev_sig = sig
            prev_path = frame_path
