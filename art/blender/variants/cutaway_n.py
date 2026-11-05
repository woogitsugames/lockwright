# Lockwright — photoreal look-dev: parametric cutaway of an invented pin-tumbler cylinder (1..7 pins).
# Supports blanked chambers for practice cylinders (S1: 1 active pin, S2: 3 active pins),
# full tension wrench framing (--wrench-in-frame) with tension angle (0..14 deg), per-pin states (--states),
# Plan B static plate mode (--plate), and grayscale output (--gray-out).
# Units: 1 Blender unit = 1 mm. Generic, unbranded mechanism with game-tuned proportions.
import bpy, bmesh, math, sys, os, random
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, BLENDER_DIR)
from lw_common import *
from lw_common import _noise, _mix, _maprange, _edge_mask, _cavity_mask, _catmull

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    if name in argv:
        idx = argv.index(name)
        if idx + 1 < len(argv) and not argv[idx + 1].startswith('--'):
            return argv[idx + 1]
        return '1'
    return default

def flag(name):
    if name not in argv:
        return False
    idx = argv.index(name)
    if idx + 1 < len(argv) and not argv[idx + 1].startswith('--'):
        return argv[idx + 1].lower() not in ('0', 'false', 'no', 'off')
    return True

OUT = arg('--out', '//cutaway_n.png')
GRAY_OUT = arg('--gray-out', '')
RES = [int(v) for v in arg('--res', '2160x2880').split('x')]
SAMPLES = int(arg('--samples', '256'))
SHOT = arg('--shot', 'section')
GLB = arg('--glb', '')
DEVICE = arg('--device', 'GPU').upper()
N_PINS = max(1, min(7, int(arg('--pins', '5'))))
TOTAL_CHAMBERS = max(N_PINS, int(arg('--chambers', str(max(5, N_PINS)))))
WRENCH_IN_FRAME = flag('--wrench-in-frame')
PLATE_ONLY = flag('--plate')

# Tension angle in degrees (0..14 deg, D-12 / HUD.md §3).
# Accepts --tension-angle, --wrench-angle, --angle (deg), or --tension (0..1 or deg).
raw_angle = arg('--tension-angle', arg('--wrench-angle', arg('--angle', '')))
if raw_angle != '':
    TENSION_DEG = max(0.0, min(14.0, float(raw_angle)))
elif '--tension' in argv:
    tv = float(arg('--tension', '0.65'))
    TENSION_DEG = max(0.0, min(14.0, tv * 14.0 if tv <= 1.0 else tv))
else:
    TENSION_DEG = 10.0 if WRENCH_IN_FRAME else 6.0

DEFAULT_STATES = {
    1: ['bind'],
    2: ['set', 'bind'],
    3: ['set', 'bind', 'free'],
    4: ['set', 'spool', 'bind', 'free'],
    5: ['set', 'spool', 'bind', 'overset', 'free'],
    6: ['set', 'spool', 'bind', 'overset', 'free', 'set'],
    7: ['set', 'spool', 'set', 'bind', 'overset', 'spool', 'free'],
}
raw_states = arg('--states', '')
if raw_states:
    STATES = [s.strip().lower() for s in raw_states.split(',') if s.strip()]
    while len(STATES) < N_PINS:
        STATES.append(STATES[-1] if STATES else 'free')
    STATES = STATES[:N_PINS]
else:
    STATES = DEFAULT_STATES[N_PINS]

STATE_ALIAS = {
    'a': 'set', 'set': 'set',
    'b': 'spool', 'spool': 'spool', 'false_set': 'spool', 'falseset': 'spool', 'false': 'spool',
    'c': 'bind', 'bind': 'bind', 'binding': 'bind', 'near': 'bind', 'near_shear': 'bind',
    'd': 'overset', 'overset': 'overset', 'over': 'overset',
    'e': 'free', 'free': 'free',
    'serrated': 'serrated',
}
STATES = [STATE_ALIAS.get(s, 'free') for s in STATES]

CUT = SHOT != 'borescope'
def section_cut(o, cutter):
    if CUT:
        boolean(o, cutter)
    else:
        bpy.data.objects.remove(cutter, do_unlink=True)

# ---------------------------------------------------------------- T06 quality materials (roughness >= 0.16)
def clamp_roughness_floor(mat, min_r=0.16):
    """Guarantee every metallic shader stays >= min_r roughness across all noise/wear ranges (T06 #3)."""
    nt = mat.node_tree
    bsdf = nt.nodes.get('Principled BSDF')
    if not bsdf:
        return mat
    rough_in = bsdf.inputs['Roughness']
    if rough_in.is_linked:
        src = rough_in.links[0].from_socket
        nt.links.remove(rough_in.links[0])
        mx = nt.nodes.new('ShaderNodeMath')
        mx.operation = 'MAXIMUM'
        mx.inputs[1].default_value = min_r
        nt.links.new(src, mx.inputs[0])
        nt.links.new(mx.outputs[0], rough_in)
    else:
        rough_in.default_value = max(min_r, rough_in.default_value)
    return mat

def machined_cut_metal(name, base, rough, aniso=0.65, mill_scale=4.8, mill_loc=(-48, 0, 22),
                       grind_stretch=(0.05, 1.0, 3.2), chamfer_rough=0.54, chamfer_darken=0.78,
                       patina=0.18, grime=0.65, seed=1.0):
    """Face-milled & ground metal for cylinder housing and plug cut planes (T06 #3, #4):
    - Spherical/planar milling cutter arcs in the XZ cut plane + fine horizontal surface-grind streaks
    - Anisotropy aligned with machining direction
    - Matte deburred chamfers (roughness ~0.54, darkened) via convex-edge AO mask
    - Strict roughness floor >= 0.16 (no mirror chrome)"""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    l = nt.links
    bsdf = nt.nodes['Principled BSDF']
    bsdf.inputs['Metallic'].default_value = 1.0
    bsdf.inputs['Anisotropic'].default_value = aniso

    tc = nt.nodes.new('ShaderNodeTexCoord')
    P = tc.outputs['Object']

    # Separate Y so the flat cutaway face (y ~ 0) shows face-milling arcs + horizontal grinding,
    # while internal bores/chambers (y > 0.12) show horizontal cylindrical reaming/boring rings (T06 #3/#4).
    sep_xyz = nt.nodes.new('ShaderNodeSeparateXYZ')
    l.new(P, sep_xyz.inputs['Vector'])
    in_bore = _maprange(nt, sep_xyz.outputs['Y'], 0.06, 0.22, 0.0, 1.0)

    # 1) Cutaway face (y ~ 0): fly-cutter face-milling arcs + directional surface-grinding streaks along X
    mp_mill = nt.nodes.new('ShaderNodeMapping')
    mp_mill.inputs['Location'].default_value = (mill_loc[0] + seed * 3.1, mill_loc[1], mill_loc[2] - seed * 1.7)
    mp_mill.inputs['Scale'].default_value = (1.0, 0.08, 1.0)
    l.new(P, mp_mill.inputs['Vector'])

    wv_coarse = nt.nodes.new('ShaderNodeTexWave')
    wv_coarse.wave_type = 'RINGS'
    wv_coarse.rings_direction = 'SPHERICAL'
    wv_coarse.inputs['Scale'].default_value = mill_scale * 0.34
    wv_coarse.inputs['Distortion'].default_value = 0.42
    wv_coarse.inputs['Detail'].default_value = 3.0
    l.new(mp_mill.outputs['Vector'], wv_coarse.inputs['Vector'])

    wv_fine = nt.nodes.new('ShaderNodeTexWave')
    wv_fine.wave_type = 'RINGS'
    wv_fine.rings_direction = 'SPHERICAL'
    wv_fine.inputs['Scale'].default_value = mill_scale
    wv_fine.inputs['Distortion'].default_value = 0.55
    wv_fine.inputs['Detail'].default_value = 5.0
    l.new(mp_mill.outputs['Vector'], wv_fine.inputs['Vector'])

    wv_mill = _mix(nt, wv_coarse.outputs['Fac'], wv_fine.outputs['Fac'], 0.48, dtype='FLOAT')
    fn_grind = _noise(nt, P, 5.5, detail=10, rough=0.68, stretch=grind_stretch)
    face_marks = _mix(nt, wv_mill, fn_grind, 0.42, dtype='FLOAT')

    # 2) Internal bores (y > 0.12): horizontal reaming/turning rings around chamber Z axes
    wv_bore = nt.nodes.new('ShaderNodeTexWave')
    wv_bore.wave_type = 'BANDS'
    wv_bore.bands_direction = 'Z'
    wv_bore.inputs['Scale'].default_value = 3.6
    wv_bore.inputs['Distortion'].default_value = 0.45
    wv_bore.inputs['Detail'].default_value = 4.0
    l.new(P, wv_bore.inputs['Vector'])
    bore_marks = _mix(nt, wv_bore.outputs['Fac'], _noise(nt, P, 24.0, detail=6), 0.32, dtype='FLOAT')

    marks_h = _mix(nt, face_marks, bore_marks, in_bore, dtype='FLOAT')

    # Base roughness variation + handling smudges + machining micro-grooves
    rv = _noise(nt, P, 28.0, detail=6)
    r = _maprange(nt, rv, 0.25, 0.75, max(0.16, rough - 0.04), rough + 0.05)
    r_marks = _maprange(nt, marks_h, 0.18, 0.82, max(0.16, rough - 0.05), rough + 0.085)
    r = _mix(nt, r, r_marks, 0.65, dtype='FLOAT')

    # Subtle colour variation + machining tone + oil patina + cavity grime
    tv = _noise(nt, P, 1.4, detail=4)
    col = _mix(nt, (*[c * 0.95 for c in base], 1), (*[min(1.0, c * 1.04) for c in base], 1), tv)
    mtone = _maprange(nt, marks_h, 0.0, 1.0, 0.90, 1.04)
    col_m = nt.nodes.new('ShaderNodeMix')
    col_m.data_type = 'RGBA'
    col_m.blend_type = 'MULTIPLY'
    col_m.inputs['Factor'].default_value = 1.0
    l.new(col, col_m.inputs['A'])
    l.new(mtone, col_m.inputs['B'])
    col = col_m.outputs['Result']

    if patina > 0:
        pm = _maprange(nt, _noise(nt, P, 0.55, detail=7, rough=0.65), 0.44, 0.66, 0.0, patina)
        col = _mix(nt, col, (base[0] * 0.48, base[1] * 0.42, base[2] * 0.35, 1), pm)
        r = _mix(nt, r, min(1.0, rough + 0.16), pm, dtype='FLOAT')

    if grime > 0:
        cm = _cavity_mask(nt, 1.8, 0.32, 0.96)
        gm = _maprange(nt, _mix(nt, cm, _noise(nt, P, 2.2, detail=6), 0.28, dtype='FLOAT'), 0.0, 1.0, 0.0, grime)
        col = _mix(nt, col, (0.045, 0.038, 0.032, 1), gm)
        r = _mix(nt, r, 0.72, gm, dtype='FLOAT')

    # Matte deburred chamfers on convex edges (T06 #4)
    em = _edge_mask(nt, dist=0.22, lo=0.66, hi=0.96)
    r = _mix(nt, r, chamfer_rough, em, dtype='FLOAT')
    col = _mix(nt, col, (*[c * chamfer_darken for c in base], 1), em, dtype='RGBA')

    l.new(col, bsdf.inputs['Base Color'])
    l.new(r, bsdf.inputs['Roughness'])
    l.new(_maprange(nt, marks_h, 0.0, 1.0, 0.06, 0.24), bsdf.inputs['Anisotropic Rotation'])

    # Bevel + machining bump normal
    bv = nt.nodes.new('ShaderNodeBevel')
    bv.samples = 6
    bv.inputs['Radius'].default_value = 0.05
    bp = nt.nodes.new('ShaderNodeBump')
    bp.inputs['Strength'].default_value = 0.058
    bp.inputs['Distance'].default_value = 0.018
    l.new(marks_h, bp.inputs['Height'])
    l.new(bv.outputs['Normal'], bp.inputs['Normal'])
    l.new(bp.outputs['Normal'], bsdf.inputs['Normal'])

    tg = nt.nodes.new('ShaderNodeTangent')
    tg.direction_type = 'RADIAL'
    tg.axis = 'Y'
    l.new(tg.outputs['Tangent'], bsdf.inputs['Tangent'])

    return clamp_roughness_floor(m, 0.16)

def add_matte_chamfer_honing(mat, chamfer_rough=0.52, darken=0.82):
    """Matte deburred chamfers via convex-edge mask so cut edges and shear line never flash bright (T06 #4)."""
    nt = mat.node_tree
    l = nt.links
    bsdf = nt.nodes.get('Principled BSDF')
    if not bsdf:
        return mat
    em = _edge_mask(nt, dist=0.20, lo=0.68, hi=0.96)
    if bsdf.inputs['Roughness'].is_linked:
        r_src = bsdf.inputs['Roughness'].links[0].from_socket
        l.remove(bsdf.inputs['Roughness'].links[0])
        r_out = _mix(nt, r_src, chamfer_rough, em, dtype='FLOAT')
        l.new(r_out, bsdf.inputs['Roughness'])
    if bsdf.inputs['Base Color'].is_linked:
        c_src = bsdf.inputs['Base Color'].links[0].from_socket
        l.remove(bsdf.inputs['Base Color'].links[0])
        c_dark = nt.nodes.new('ShaderNodeVectorMath')
        c_dark.operation = 'SCALE'
        c_dark.inputs['Scale'].default_value = darken
        l.new(c_src, c_dark.inputs[0])
        c_out = _mix(nt, c_src, c_dark.outputs[0], em, dtype='RGBA')
        l.new(c_out, bsdf.inputs['Base Color'])
    return clamp_roughness_floor(mat, 0.16)

MAT = {
    'nickel': machined_cut_metal(
        'nickel_v2', (0.60, 0.60, 0.58), 0.29, aniso=0.68,
        mill_scale=5.2, mill_loc=(-52, 0, 24), grind_stretch=(0.05, 1.0, 3.2),
        chamfer_rough=0.54, chamfer_darken=0.78, patina=0.14, grime=0.62, seed=1.0
    ),
    'nickel_chamfer': clamp_roughness_floor(metal(
        'nickel_chamfer', (0.40, 0.40, 0.39), 0.55, aniso=0.25,
        marks='grind', marks_scale=2.0, marks_axis=(1, 0, 0), marks_amt=0.5,
        wear=0.0, grime=0.75, smudge=0.3, bevel_r=0.02, seed=2.0
    ), 0.45),
    'brass': machined_cut_metal(
        'brass_v2', (0.85, 0.60, 0.26), 0.24, aniso=0.62,
        mill_scale=4.4, mill_loc=(-38, 0, -12), grind_stretch=(0.04, 1.0, 2.8),
        chamfer_rough=0.52, chamfer_darken=0.76, patina=0.18, grime=0.62, seed=3.0
    ),
    'brass_chamfer': clamp_roughness_floor(metal(
        'brass_chamfer', (0.52, 0.36, 0.15), 0.56, aniso=0.2,
        marks='turn', marks_scale=1.8, marks_axis=(1, 0, 0), marks_amt=0.5,
        wear=0.0, grime=0.78, smudge=0.3, bevel_r=0.02, seed=4.0
    ), 0.46),
    'cap_brass': add_matte_chamfer_honing(metal(
        'cap_brass', (0.78, 0.55, 0.24), 0.28, aniso=0.5,
        marks='turn', marks_scale=1.5, marks_axis=(0, 0, 1), marks_amt=0.9,
        wear=0.2, grime=0.68, patina=0.25, bevel_r=0.04, seed=5.0
    ), chamfer_rough=0.50, darken=0.82),
    'blank_steel': clamp_roughness_floor(metal(
        'blank_steel', (0.16, 0.17, 0.19), 0.46, aniso=0.35,
        marks='turn', marks_scale=1.4, marks_axis=(0, 0, 1), marks_amt=0.85,
        wear=0.2, wear_col=(0.24, 0.25, 0.27), grime=0.8, bevel_r=0.04, seed=9.0
    ), 0.38),
    'pick': add_matte_chamfer_honing(metal(
        'pick_v2', (0.70, 0.70, 0.69), 0.20, aniso=0.68,
        marks='grind', marks_scale=1.3, marks_axis=(1, 0, 0), marks_amt=0.85,
        wear=0.35, wear_col=(0.75, 0.75, 0.74), grime=0.25, smudge=0.35, bevel_r=0.04, seed=6.0
    ), chamfer_rough=0.42, darken=0.88),
    'wrench': add_matte_chamfer_honing(metal(
        'wrench_v2', (0.62, 0.63, 0.64), 0.23, aniso=0.64,
        marks='grind', marks_scale=1.2, marks_axis=(0, 0, 1), marks_amt=0.9,
        wear=0.45, wear_col=(0.70, 0.70, 0.71), grime=0.38, smudge=0.45, bevel_r=0.04, seed=7.0
    ), chamfer_rough=0.45, darken=0.86),
    'iron': iron('esc_iron', rust=0.32, base=(0.17, 0.165, 0.16), rough=0.58, polish=0.45, scale=1.2, seed=2.0),
    'wood': oak('door_oak', light=(0.44, 0.27, 0.13), dark=(0.16, 0.08, 0.035), axis='Z', plank=0.0,
                ring_mm=1.65, lacquer=0.68, rough=0.44, coat_rough=0.19, pores=1.2, wear=0.45, grime=0.62, bump=1.25, seed=4.0),
    'handle': dark_mat('pick_handle_mat', (0.18, 0.045, 0.03), rough=0.48),
    'recess': dark_mat('recess_dark', (0.015, 0.014, 0.013), rough=0.95),
    'shear_shadow': dark_mat('shear_shadow', (0.008, 0.007, 0.007), rough=0.98),
}

# Per-pin turned materials with subtle seed variation so pins are never identical clones
KEY_PIN_MATS = [
    add_matte_chamfer_honing(metal(
        f'brass_k_{i}', (0.87 - 0.012 * (i % 3), 0.64 - 0.01 * (i % 2), 0.31), 0.20 + 0.01 * (i % 3),
        aniso=0.66, marks='turn', marks_scale=1.6 + 0.15 * i, marks_axis=(0, 0, 1), marks_amt=0.95,
        wear=0.35, wear_col=(0.91, 0.69, 0.37), grime=0.42, smudge=0.38, patina=0.15 + 0.04 * (i % 3),
        bevel_r=0.03, seed=10.0 + i * 3.7
    ), chamfer_rough=0.46, darken=0.84)
    for i in range(7)
]
DRV_PIN_MATS = [
    add_matte_chamfer_honing(metal(
        f'steel_drv_{i}', (0.47 + 0.01 * (i % 3), 0.48 + 0.01 * (i % 2), 0.50), 0.23 + 0.012 * (i % 3),
        aniso=0.62, marks='turn', marks_scale=1.7 + 0.12 * i, marks_axis=(0, 0, 1), marks_amt=0.9,
        wear=0.3, wear_col=(0.56, 0.57, 0.59), grime=0.48, smudge=0.35, patina=0.12 + 0.03 * (i % 2),
        bevel_r=0.03, seed=30.0 + i * 4.1
    ), chamfer_rough=0.48, darken=0.84)
    for i in range(7)
]
SPRING_MATS = [
    clamp_roughness_floor(metal(
        f'spring_mat_{i}', (0.53 + 0.015 * (i % 3), 0.53 + 0.01 * (i % 2), 0.54), 0.25 + 0.015 * (i % 3),
        aniso=0.45, marks=None, wear=0.15, grime=0.45, patina=0.14 + 0.05 * (i % 3), bevel_r=0.0, seed=50.0 + i * 5.3
    ), 0.20)
    for i in range(7)
]

def bevel_matte(o, w=0.12, seg=3, chamfer_mat=None):
    """Bevel modifier that assigns a matte deburred material to the chamfer faces (T06 #4)."""
    if o.type == 'MESH':
        for ob in bpy.context.selected_objects:
            ob.select_set(False)
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(35), keep_sharp_edges=True)
    md = o.modifiers.new('bev', 'BEVEL')
    md.width = w
    md.segments = seg
    md.limit_method = 'ANGLE'
    md.angle_limit = math.radians(40)
    md.harden_normals = True
    if chamfer_mat is not None:
        if chamfer_mat.name not in o.data.materials:
            o.data.materials.append(chamfer_mat)
        md.material = list(o.data.materials).index(chamfer_mat)
    wn = o.modifiers.new('wn', 'WEIGHTED_NORMAL')
    wn.keep_sharp = True
    return o

# ---------------------------------------------------------------- geometry (cut plane y = 0, keep y >= 0)
PITCH = 4.0
ALL_X = [5.0 + PITCH * i for i in range(TOTAL_CHAMBERS)]
PINS_X = ALL_X[:N_PINS]
BLANK_X = ALL_X[N_PINS:]

R_HOUSE, R_PLUG, TOWER_W, TOWER_TOP = 8.5, 6.38, 10.0, 24.0
LEN = 30.0 + PITCH * (TOTAL_CHAMBERS - 5)
SHEAR = R_PLUG  # top of plug at z = 6.38
SHEAR_GAP = 0.24  # dark 0.24 mm shear gap (>= 2 dp on phone)
R_BORE = R_PLUG + SHEAR_GAP
CHAMBER_R = 1.55
KEYWAY = (-5.2, 2.6)

# housing: round body + tower with rounded top
house = cyl('housing', R_HOUSE, LEN, (LEN / 2, 0, 0), axis='X', verts=128)
tower = box('tower', 0, LEN, -TOWER_W / 2, TOWER_W / 2, 0, TOWER_TOP - TOWER_W / 2)
boolean(house, tower, 'UNION')
cap = cyl('towercap', TOWER_W / 2, LEN, (LEN / 2, 0, TOWER_TOP - TOWER_W / 2), axis='X', verts=64)
boolean(house, cap, 'UNION')
boolean(house, cyl('bore', R_BORE, LEN + 2, (LEN / 2, 0, 0), axis='X', verts=128))
for x in ALL_X:
    boolean(house, cyl('ch', CHAMBER_R, TOWER_TOP, (x, 0, SHEAR + (TOWER_TOP - 1.2 - SHEAR) / 2 - 0.4), verts=48))
section_cut(house, box('cut', -1, LEN + 1, -20, 0, -20, 40))
link(house, MAT['nickel'])
bevel_matte(house, 0.11, seg=3, chamfer_mat=MAT['nickel_chamfer'])

# Dark shadow liner inside the shear gap just behind the cut plane (prevents any light leak / bright line on shear!)
shear_liner = box('shear_liner', 0.05, LEN - 0.05, 0.32, 1.8, SHEAR - 0.03, R_BORE + 0.03)
for x in ALL_X:
    boolean(shear_liner, cyl('sl_ch', CHAMBER_R + 0.08, 4.0, (x, 0, SHEAR), verts=32))
link(shear_liner, MAT['shear_shadow'])

# plug with keyway and active chambers
plug = cyl('plug', R_PLUG, LEN + 1.5, (LEN / 2 - 0.75, 0, 0), axis='X', verts=128)
boolean(plug, box('keyway', -2, LEN - 1.5, -1.2, 1.2, KEYWAY[0], KEYWAY[1]))
boolean(plug, box('ward', -2, LEN - 1.5, -2.0, 2.0, -1.4, 0.2))
for x in PINS_X:
    boolean(plug, cyl('pc', CHAMBER_R, 6, (x, 0, KEYWAY[1] + 1.5), verts=48))
# For blanked chambers (S1/S2), shallow blind counterbore at the top of the plug so the shear line still shows the chamber position
for x in BLANK_X:
    boolean(plug, cyl('pc_blind', CHAMBER_R, 1.2, (x, 0, SHEAR - 0.2), verts=48))
section_cut(plug, box('cut', -3, LEN + 2, -20, 0, -20, 20))
link(plug, MAT['brass'])
bevel_matte(plug, 0.11, seg=3, chamfer_mat=MAT['brass_chamfer'])

# front face lip of the plug (rounded collar) with engraved rotation scale ticks (HUD.md §3)
collar = cyl('collar', R_HOUSE + 0.6, 1.6, (-0.8, 0, 0), axis='X', verts=128)
boolean(collar, box('kw2', -3, 1, -1.2, 1.2, KEYWAY[0], KEYWAY[1]))
boolean(collar, cyl('inner', R_PLUG, 4, (-0.8, 0, 0), axis='X', verts=128))
for k_tick in range(7):
    ang = math.radians(k_tick * 7.5)
    tz = (R_HOUSE + 0.2) * math.cos(ang)
    ty = (R_HOUSE + 0.2) * math.sin(ang)
    if ty >= -0.2:
        tk = box(f'tick_{k_tick}', -1.65, -0.35 if k_tick == 0 else -0.65, ty - 0.09, ty + 0.09, tz - 0.09, tz + 0.8)
        boolean(collar, tk)
section_cut(collar, box('cut', -3, 2, -20, 0, -20, 20))
link(collar, MAT['nickel'])
bevel_matte(collar, 0.12, seg=3, chamfer_mat=MAT['nickel_chamfer'])

# bore plugs (caps) closing the active chambers at the top of the tower
for x in PINS_X:
    c = cyl('cap', CHAMBER_R + 0.02, 1.2, (x, 0, TOWER_TOP - 1.6 - 0.4 + 0.6), verts=48)
    section_cut(c, box('cut', x - 3, x + 3, -5, 0, 0, 40))
    link(c, MAT['cap_brass'])
    bevel_matte(c, 0.08, seg=2, chamfer_mat=MAT['brass_chamfer'])

# Blanked chambers (zaślepione komory) for practice cylinder variants (S1: 1 active pin, S2: 3 active pins)
for idx_b, x in enumerate(BLANK_X):
    b_prof = [
        (0.001, SHEAR + 0.18),
        (CHAMBER_R - 0.22, SHEAR + 0.18),
        (CHAMBER_R - 0.06, SHEAR + 0.38),
        (CHAMBER_R - 0.06, SHEAR + 3.2),
        (CHAMBER_R - 0.28, SHEAR + 3.5),
        (CHAMBER_R - 0.28, SHEAR + 4.3),
        (CHAMBER_R - 0.06, SHEAR + 4.6),
        (CHAMBER_R - 0.06, TOWER_TOP - 2.6),
        (CHAMBER_R + 0.02, TOWER_TOP - 2.4),
        (CHAMBER_R + 0.02, TOWER_TOP - 0.9),
        (CHAMBER_R - 0.18, TOWER_TOP - 0.9),
        (0.001, TOWER_TOP - 0.9),
    ]
    bp = lathe(f'blank_plug_{idx_b}', b_prof, x, y=1.5, seg=48)
    bp.modifiers.clear()  # Clear lathe's default bevel before boolean cuts so modifiers apply cleanly
    boolean(bp, box(f'bslot_{idx_b}', x - 2.0, x + 2.0, 0.0, 3.0, TOWER_TOP - 1.35, TOWER_TOP - 0.5))
    if CUT:
        boolean(bp, box(f'bcut_{idx_b}', x - 3, x + 3, -5, 0.28, 0, 40))
    link(bp, MAT['blank_steel'])
    bevel_matte(bp, 0.06, seg=2)
    p_ins = cyl(f'blank_core_{idx_b}', CHAMBER_R - 0.05, 0.9, (x, 1.5, SHEAR - 0.45), verts=48)
    if CUT:
        boolean(p_ins, box(f'bcut2_{idx_b}', x - 3, x + 3, -5, 0.28, 0, 20))
    link(p_ins, MAT['brass_chamfer'])

# ---------------------------------------------------------------- varied springs & pin helpers (T06 #3, #4)
def varied_spring(name, idx, x, z0, z1, base_coils=9.0, r=1.15, wire=0.22, y=1.5, compressed=False):
    """Compression spring with realistic per-chamber variations in phase, coil count, pitch irregularity,
    and subtle lateral micro-wobble so springs never look like CAD clones (T06 #3/#4)."""
    rng = random.Random(101 + idx * 37)
    coils = base_coils + (0.4 if compressed else rng.uniform(-0.45, 0.45))
    phase = idx * 1.45 + rng.uniform(-0.55, 0.55)
    r_var = r + rng.uniform(-0.03, 0.03)
    w_var = wire + (0.0 if compressed else rng.uniform(-0.01, 0.012))
    pitch_wave_amp = 0.015 if compressed else rng.uniform(0.035, 0.065)
    pitch_wave_freq = rng.choice([1.0, 1.5, 2.0]) * math.pi
    pitch_wave_ph = rng.uniform(0, math.pi * 2)
    wobble_x = rng.uniform(-0.045, 0.045)
    wobble_y = rng.uniform(-0.035, 0.035)

    cu = bpy.data.curves.new(name, 'CURVE')
    cu.dimensions = '3D'
    cu.bevel_depth = w_var
    cu.bevel_resolution = 5
    sp = cu.splines.new('POLY')
    n = int(coils * 28)
    sp.points.add(n)
    L = max(z1 - z0, w_var * 4.2)
    e = 1.0 / coils
    w_end = w_var * 2.08
    for i in range(n + 1):
        t = i / n
        a = phase + t * coils * 2 * math.pi
        if t < e:
            zt = (t / e) * w_end
        elif t > 1 - e:
            zt = L - ((1 - t) / e) * w_end
        else:
            u = (t - e) / (1 - 2 * e)
            u_warped = u + pitch_wave_amp * math.sin(u * pitch_wave_freq + pitch_wave_ph) * math.sin(u * math.pi)
            zt = w_end + u_warped * (L - 2 * w_end)
        env = math.sin(t * math.pi)
        cx = x + wobble_x * math.sin(t * 2 * math.pi + phase) * env + (r_var + 0.015 * math.cos(a * 0.5)) * math.cos(a)
        cy = y + wobble_y * math.cos(t * 2 * math.pi + phase) * env + (r_var + 0.015 * math.sin(a * 0.5)) * math.sin(a)
        sp.points[i].co = (cx, cy, z0 + zt, 1)
    o = bpy.data.objects.new(name, cu)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(SPRING_MATS[idx % len(SPRING_MATS)])
    return o

def make_key_pin(name, idx, x, z0, length, r=1.42, chamfer=0.20, dx=0.0):
    prof = [
        (0.02, z0),
        (0.50, z0 + 0.12),
        (0.95, z0 + 0.45),
        (r - 0.05, z0 + 0.95),
        (r, z0 + 1.10),
        (r, z0 + length - chamfer),
        (r - chamfer, z0 + length),
        (0.001, z0 + length),
    ]
    o = lathe(name, prof, x + dx, tilt=0.0, seg=64)
    link(o, KEY_PIN_MATS[idx % len(KEY_PIN_MATS)])
    o.modifiers['bev'].width = 0.07
    o.modifiers['bev'].harden_normals = True
    return o

def make_driver_pin(name, idx, x, z0, length, r=1.42, chamfer=0.20, tilt=0.0, dx=0.0, foot=False):
    if foot:
        prof = [
            (0.001, z0),
            (r - 0.04, z0),
            (r - 0.04, z0 + 0.24),
            (r - 0.22, z0 + 0.30),
            (r - 0.22, z0 + 0.52),
            (r, z0 + 0.64),
            (r, z0 + length - chamfer),
            (r - chamfer, z0 + length),
            (0.001, z0 + length),
        ]
    else:
        prof = [
            (0.001, z0),
            (r - chamfer, z0),
            (r, z0 + chamfer),
            (r, z0 + length - chamfer),
            (r - chamfer, z0 + length),
            (0.001, z0 + length),
        ]
    o = lathe(name, prof, x + dx, tilt=tilt, seg=64)
    link(o, DRV_PIN_MATS[idx % len(DRV_PIN_MATS)])
    o.modifiers['bev'].width = 0.07
    o.modifiers['bev'].harden_normals = True
    return o

def make_spool_pin(name, idx, x, z0, length, waist_z, r=1.42, wr=0.84, tilt=0.0, dx=0.0):
    h = 0.52
    prof = [
        (0.001, z0),
        (r - 0.16, z0),
        (r, z0 + 0.16),
        (r, waist_z - h - 0.22),
        (wr, waist_z - h + 0.04),
        (wr, waist_z + h - 0.04),
        (r, waist_z + h + 0.22),
        (r, z0 + length - 0.16),
        (r - 0.16, z0 + length),
        (0.001, z0 + length),
    ]
    o = lathe(name, prof, x + dx, tilt=tilt, seg=64)
    link(o, DRV_PIN_MATS[idx % len(DRV_PIN_MATS)])
    o.modifiers['bev'].width = 0.06
    o.modifiers['bev'].harden_normals = True
    return o

def make_serrated_pin(name, idx, x, z0, length, r=1.42, tilt=0.0, dx=0.0):
    prof = [(0.001, z0), (r - 0.16, z0), (r, z0 + 0.16)]
    for g in range(3):
        gz = z0 + 0.9 + g * 0.85
        prof += [(r, gz - 0.14), (r - 0.24, gz - 0.05), (r - 0.24, gz + 0.05), (r, gz + 0.14)]
    prof += [(r, z0 + length - 0.16), (r - 0.16, z0 + length), (0.001, z0 + length)]
    o = lathe(name, prof, x + dx, tilt=tilt, seg=64)
    link(o, DRV_PIN_MATS[idx % len(DRV_PIN_MATS)])
    o.modifiers['bev'].width = 0.05
    o.modifiers['bev'].harden_normals = True
    return o

# ---------------------------------------------------------------- pin stacks (states per active chamber)
TOP = TOWER_TOP - 2.0 - 0.4  # underside of caps
KP_FLOOR = KEYWAY[1] - 1.45  # resting key-pin tip height inside the keyway
STACK_LETTERS = 'abcdefg'

pick_target_idx = 0
for idx, st in enumerate(STATES):
    if st == 'bind':
        pick_target_idx = idx
        break
if '--pick-pin' in argv:
    pick_target_idx = max(0, min(N_PINS - 1, int(arg('--pick-pin', '1')) - 1))

pick_tip_z = KP_FLOOR + 1.0
for idx, (x, st) in enumerate(zip(PINS_X, STATES)):
    p = STACK_LETTERS[idx]
    klen_var = ((idx * 3) % 5 - 2) * 0.12
    if st == 'set':
        klen = 4.45 + klen_var * 0.5
        make_key_pin(f'{p}_key', idx, x, KP_FLOOR, klen)
        make_driver_pin(f'{p}_drv', idx, x, SHEAR + 0.24, 4.0, foot=True)
        varied_spring(f'{p}_spr', idx, x, SHEAR + 4.18, TOP, 9.0)
        if idx == pick_target_idx:
            pick_tip_z = KP_FLOOR
    elif st == 'spool':
        klen = 4.75
        make_key_pin(f'{p}_key', idx, x, KP_FLOOR, klen, dx=0.04)
        make_spool_pin(f'{p}_drv', idx, x, KP_FLOOR + klen, 4.4, SHEAR + 0.06, tilt=math.radians(1.6), dx=0.05)
        varied_spring(f'{p}_spr', idx, x, KP_FLOOR + klen + 4.4, TOP, 9.0)
        if idx == pick_target_idx:
            pick_tip_z = KP_FLOOR
    elif st == 'bind':
        cz = KP_FLOOR + 1.05
        klen = 4.85
        make_key_pin(f'{p}_key', idx, x, cz, klen, dx=0.08)
        make_driver_pin(f'{p}_drv', idx, x, cz + klen, 4.0, tilt=math.radians(-2.6), dx=0.09)
        varied_spring(f'{p}_spr', idx, x, cz + klen + 4.0, TOP, 9.0)
        if idx == pick_target_idx:
            pick_tip_z = cz
    elif st == 'overset':
        dz = KP_FLOOR + 3.25
        klen = 5.4
        make_key_pin(f'{p}_key', idx, x, dz, klen, dx=-0.04)
        make_driver_pin(f'{p}_drv', idx, x, dz + klen, 4.0, dx=-0.04)
        varied_spring(f'{p}_spr', idx, x, dz + klen + 4.0, TOP, 9.5, wire=0.25, compressed=True)
        if idx == pick_target_idx:
            pick_tip_z = dz
    elif st == 'serrated':
        cz = KP_FLOOR + 0.55
        klen = 4.65
        make_key_pin(f'{p}_key', idx, x, cz, klen, dx=0.06)
        make_serrated_pin(f'{p}_drv', idx, x, cz + klen, 4.1, tilt=math.radians(-1.5), dx=0.06)
        varied_spring(f'{p}_spr', idx, x, cz + klen + 4.1, TOP, 9.0)
        if idx == pick_target_idx:
            pick_tip_z = cz
    else:
        klen = 4.2 + klen_var
        make_key_pin(f'{p}_key', idx, x, KP_FLOOR, klen)
        make_driver_pin(f'{p}_drv', idx, x, KP_FLOOR + klen, 4.0)
        varied_spring(f'{p}_spr', idx, x, KP_FLOOR + klen + 4.0, TOP, 8.8)
        if idx == pick_target_idx:
            pick_tip_z = KP_FLOOR

# ---------------------------------------------------------------- tools: hook pick + tension wrench (0..14 deg)
def clean_flat_tool(name, path, height, thick, y, mat_obj, tip='round', use_catmull=True):
    """Quad-strip stamped flat-stock tool (pick blade, tension wrench) with T-junction-free rounded cap."""
    c = _catmull([Vector((x, 0, z)) for x, z in path]) if use_catmull else [Vector((x, 0, z)) for x, z in path]
    left, right = [], []
    for i, p in enumerate(c):
        if i == 0:
            d = (c[1] - c[0]).normalized()
        elif i == len(c) - 1:
            d = (c[-1] - c[-2]).normalized()
        else:
            d = (c[i + 1] - c[i - 1]).normalized()
        nrm = Vector((-d.z, 0, d.x))
        left.append(p + nrm * (height / 2))
        right.append(p - nrm * (height / 2))
    bm = bmesh.new()
    vL = [bm.verts.new((v.x, y - thick / 2, v.z)) for v in left]
    vR = [bm.verts.new((v.x, y - thick / 2, v.z)) for v in right]
    faces = []
    for i in range(len(c) - 1):
        faces.append(bm.faces.new((vL[i], vL[i + 1], vR[i + 1], vR[i])))
    if tip == 'round':
        d = (c[-1] - c[-2]).normalized()
        nrm = Vector((-d.z, 0, d.x))
        # Build symmetric pairs along the semicircular cap so every cap face is a clean quad with no T-junctions
        steps = 6
        prev_l, prev_r = vL[-1], vR[-1]
        for k in range(1, steps):
            a = (math.pi * 0.5) * (k / steps)
            pt_l = c[-1] + nrm * math.cos(a) * (height / 2) + d * math.sin(a) * (height / 2)
            pt_r = c[-1] - nrm * math.cos(a) * (height / 2) + d * math.sin(a) * (height / 2)
            nl = bm.verts.new((pt_l.x, y - thick / 2, pt_l.z))
            nr = bm.verts.new((pt_r.x, y - thick / 2, pt_r.z))
            faces.append(bm.faces.new((prev_l, nl, nr, prev_r)))
            prev_l, prev_r = nl, nr
        pt_tip = c[-1] + d * (height / 2)
        v_tip = bm.verts.new((pt_tip.x, y - thick / 2, pt_tip.z))
        faces.append(bm.faces.new((prev_l, v_tip, prev_r)))
    ext = bmesh.ops.extrude_face_region(bm, geom=faces)
    for v in [g for g in ext['geom'] if isinstance(g, bmesh.types.BMVert)]:
        v.co.y += thick
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    b = o.modifiers.new('bev', 'BEVEL')
    b.width = min(thick, height) * 0.20
    b.segments = 3
    b.limit_method = 'ANGLE'
    b.angle_limit = math.radians(52)
    b.harden_normals = True
    for poly in me.polygons:
        poly.use_smooth = True
    me.materials.append(mat_obj)
    return o

px_target = PINS_X[pick_target_idx]
hook = [
    (-46.0, -3.6),
    (-25.0, -3.55),
    (-5.0, -3.45),
    (max(-1.0, px_target - 8.0), -3.3),
    (px_target - 3.5, -3.05),
    (px_target - 1.4, -2.5),
    (px_target - 0.5, -1.4),
    (px_target - 0.15, pick_tip_z - 0.55),
]
pick_obj = clean_flat_tool('pick', hook, 1.1, 0.55, 0.6, MAT['pick'], tip='round', use_catmull=True)

h = box('pick_handle', -60, -44, 0.1, 2.2, -4.6, -2.2)
link(h, MAT['handle'])
bevel(h, 0.5)

# Tension wrench: short toe in bottom of keyway, smooth circular elbow (R=1.65 mm > height/2 so inner edge never cusps),
# long lever arm extending down below the cylinder.
# When WRENCH_IN_FRAME is used, the full arm (length 19.5 mm) is framed and rotated by TENSION_DEG (0..14 deg)
# across the lower door stile / escutcheon, with elastic bow (0..3 dp, HUD.md §3).
ARM_LEN = 19.5 if WRENCH_IN_FRAME else 33.0
rad_t = math.radians(TENSION_DEG if WRENCH_IN_FRAME else 0.0)
pivot_x, pivot_z = -2.2, -5.0
bow = 0.44 * (TENSION_DEG / 14.0) if WRENCH_IN_FRAME else 0.0

R_elbow = 1.65
elbow_cx = pivot_x + R_elbow
elbow_cz = -4.6 - R_elbow
wr = [(4.2, -4.6), (1.8, -4.6), (elbow_cx, -4.6)]
# Smooth elbow arc from top (angle pi/2) to left-down (angle pi + rad_t)
for k in range(1, 13):
    ang = (math.pi * 0.5) + (math.pi * 0.5 + rad_t) * (k / 12.0)
    wx = elbow_cx + R_elbow * math.cos(ang)
    wz = elbow_cz + R_elbow * math.sin(ang)
    wr.append((wx, wz))

arm_start_x, arm_start_z = wr[-1]
arm_dir_x, arm_dir_z = math.sin(rad_t), -math.cos(rad_t)
arm_nrm_x, arm_nrm_z = math.cos(rad_t), math.sin(rad_t)
rem_len = ARM_LEN - R_elbow
for k in range(1, 17):
    u = k / 16.0
    dist_u = rem_len * u
    b_off = bow * 4.0 * u * (1.0 - u)
    wx = arm_start_x + arm_dir_x * dist_u + arm_nrm_x * b_off
    wz = arm_start_z + arm_dir_z * dist_u + arm_nrm_z * b_off
    wr.append((wx, wz))

wrench_obj = clean_flat_tool(
    'wrench', wr, 1.38, 0.76,
    0.38 if not WRENCH_IN_FRAME else -0.35,
    MAT['wrench'],
    tip='round' if WRENCH_IN_FRAME else 'flat',
    use_catmull=False
)
if WRENCH_IN_FRAME and TENSION_DEG > 0:
    piv3 = Vector((pivot_x, -0.35, pivot_z))
    wrench_obj.matrix_world = (
        Matrix.Translation(piv3)
        @ Matrix.Rotation(math.radians(-TENSION_DEG * 0.30), 4, 'X')
        @ Matrix.Translation(-piv3)
    )

# ---------------------------------------------------------------- door + escutcheon (section)
DOOR_X1 = max(44.0, LEN + 14.0)
door = box('door', 0.0, DOOR_X1, 0, 24, -65, 60)
prof = cyl('hole', R_HOUSE + 0.3, DOOR_X1 + 16.0, (DOOR_X1 / 2, 0, 0), axis='X', verts=96)
t2 = box('t2', -5, DOOR_X1 + 6.0, -TOWER_W / 2 - 0.3, TOWER_W / 2 + 0.3, 0, TOWER_TOP - TOWER_W / 2)
boolean(prof, t2, 'UNION')
boolean(prof, cyl('t3', TOWER_W / 2 + 0.3, DOOR_X1 + 16.0, (DOOR_X1 / 2, 0, TOWER_TOP - TOWER_W / 2), axis='X'), 'UNION')
boolean(door, prof)
link(door, MAT['wood'])
bevel(door, 0.3)

esc = box('escutcheon', -3.2, 0.0, 0, 14, -42, 44)
hole = cyl('eh', R_HOUSE + 0.9, 8, (-1.6, 0, 0), axis='X', verts=96)
boolean(esc, hole)
link(esc, MAT['iron'])
bevel(esc, 0.4)

# Diegetic brass angle gauge plate (0..14 deg reference ticks) mounted below the keyway when wrench is in frame
if WRENCH_IN_FRAME:
    gauge_plate = box('wrench_gauge_plate', -3.2, 4.5, -0.05, 0.9, pivot_z - ARM_LEN - 1.2, pivot_z - ARM_LEN + 3.2)
    link(gauge_plate, MAT['iron'])
    bevel(gauge_plate, 0.18)
    for deg_mark in (0.0, 7.0, 14.0):
        rm = math.radians(deg_mark)
        r_arc = ARM_LEN - 0.6
        mx = pivot_x + r_arc * math.sin(rm)
        mz = pivot_z - r_arc * math.cos(rm)
        pin_mark = cyl(f'wtick_{int(deg_mark)}', 0.38 if deg_mark in (0.0, 14.0) else 0.25, 0.45, (mx, -0.08, mz), axis='Y', verts=24)
        link(pin_mark, MAT['cap_brass'])

# Dark interior behind the cut so open space reads as depth, not white
back = box('back', -90, DOOR_X1 + 50, 30, 31, -90, 90)
link(back, MAT['recess'])

# ---------------------------------------------------------------- light + camera
w = scene.world = bpy.data.worlds.new('w')
w.use_nodes = True
env = w.node_tree.nodes.new('ShaderNodeTexEnvironment')
env.image = bpy.data.images.load(os.path.join(bpy.utils.resource_path('LOCAL'), 'datafiles', 'studiolights', 'world', 'interior.exr'))
bg = w.node_tree.nodes['Background']
bg.inputs['Strength'].default_value = 0.16
hs = w.node_tree.nodes.new('ShaderNodeHueSaturation')
hs.inputs['Saturation'].default_value = 0.55
w.node_tree.links.new(env.outputs['Color'], hs.inputs['Color'])
w.node_tree.links.new(hs.outputs['Color'], bg.inputs['Color'])

center_x = 13.5 + 2.0 * max(0, TOTAL_CHAMBERS - 5)
AIM = bpy.data.objects.new('aim', None)
scene.collection.objects.link(AIM)
AIM.location = (center_x, 0, 7.0 if not WRENCH_IN_FRAME else -0.5)

def area(name, loc, rot, size, energy, color, size_y=None):
    bpy.ops.object.light_add(type='AREA', location=loc)
    L = bpy.context.object
    L.name = name
    L.data.size = size
    if size_y:
        L.data.shape = 'RECTANGLE'
        L.data.size_y = size_y
    L.data.energy = energy
    L.data.color = color
    c = L.constraints.new('TRACK_TO')
    c.target = AIM
    c.track_axis = 'TRACK_NEGATIVE_Z'
    c.up_axis = 'UP_Y'
    return L

# Warm stair-light key from upper left-front, cool fill from right, low rim from below-back
area('key', (-75, -48, 125), None, 44, 1150, (1.0, 0.84, 0.66))
area('fill', (115, -95, 5), None, 95, 110, (0.94, 0.96, 1.0))
area('rim', (20, -35, -95), None, 35, 135, (1.0, 0.95, 0.9))
sheen_dir = Vector((math.sin(math.radians(20)), -math.cos(math.radians(20)), -math.sin(math.radians(15)))).normalized() * 270
area('sheen', tuple(Vector((center_x + 1.0, 0, 10)) + sheen_dir + Vector((0, 0, 48))), None, 90, 185, (1.0, 0.97, 0.92), size_y=180)

cam_d = bpy.data.cameras.new('cam')
cam = bpy.data.objects.new('cam', cam_d)
scene.collection.objects.link(cam)
scene.camera = cam
cam_d.lens = 180
cam_d.sensor_fit = 'HORIZONTAL'
cam_d.sensor_width = 36
yaw = math.radians(-22)
pitch = math.radians(10)

if WRENCH_IN_FRAME:
    span_x = (LEN + 11.2)
    dist = max(206.0, span_x * (180.0 / 36.0) * 1.04)
    target = Vector((center_x - 1.0, 0.0, -1.2))
else:
    dist = 158.0 + 18.0 * max(0, TOTAL_CHAMBERS - 5)
    target = Vector((center_x, 0.0, 9.0))

cam.location = target + Vector((math.sin(yaw) * dist, -math.cos(yaw) * dist * math.cos(pitch), math.sin(pitch) * dist))
cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
cam_d.dof.use_dof = False  # Everything in focus: no DOF on cutaway renders

# Plan B static plate mode: hide moving parts so they leave no baked shadow or reflection
MOVING = [f'{p}_{k}' for p in STACK_LETTERS for k in ('key', 'drv', 'spr')] + ['pick', 'pick_handle']
if PLATE_ONLY:
    for n_obj in MOVING:
        if n_obj in bpy.data.objects:
            bpy.data.objects[n_obj].hide_render = True

# ---------------------------------------------------------------- render setup (GPU + OIDN RGB_ALBEDO_NORMAL)
scene.render.engine = 'CYCLES'
used_dev = 'CPU'
if DEVICE != 'CPU':
    try:
        prefs = bpy.context.preferences.addons['cycles'].preferences
        for dt in ('OPTIX', 'CUDA', 'HIP', 'ONEAPI', 'METAL'):
            try:
                prefs.compute_device_type = dt
                devs = prefs.get_devices_for_type(dt)
                gpus = [d for d in devs if d.type != 'CPU']
                if gpus:
                    for d in devs:
                        d.use = (d.type != 'CPU')
                    scene.cycles.device = 'GPU'
                    used_dev = f"{dt}:{gpus[0].name}"
                    break
            except Exception:
                continue
    except Exception:
        scene.cycles.device = 'CPU'
else:
    scene.cycles.device = 'CPU'

scene.cycles.samples = SAMPLES
scene.cycles.use_denoising = True
scene.cycles.denoiser = 'OPENIMAGEDENOISE'
scene.cycles.denoising_input_passes = 'RGB_ALBEDO_NORMAL'
scene.cycles.denoising_prefilter = 'ACCURATE'
scene.cycles.max_bounces = 8
scene.cycles.glossy_bounces = 6
scene.cycles.caustics_reflective = False
scene.cycles.caustics_refractive = False
scene.cycles.blur_glossy = 0.5
scene.cycles.adaptive_threshold = 0.006
scene.render.film_transparent = False
scene.view_settings.exposure = 0.14
scene.render.resolution_x, scene.render.resolution_y = RES
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGB'
scene.render.image_settings.compression = 90
scene.view_settings.view_transform = 'AgX'
scene.view_settings.look = 'AgX - Medium High Contrast'

out_abs = os.path.abspath(OUT)
os.makedirs(os.path.dirname(out_abs), exist_ok=True)
scene.render.filepath = out_abs

if not GRAY_OUT and not flag('--no-gray') and not PLATE_ONLY and out_abs.lower().endswith('.png'):
    GRAY_OUT = out_abs[:-4] + '.gray.png'

if GLB:
    os.makedirs(os.path.dirname(os.path.abspath(GLB)), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=os.path.abspath(GLB), export_apply=True)

bpy.ops.render.render(write_still=True)
print('WROTE', out_abs, 'DEVICE', used_dev, 'PINS', N_PINS, 'WRENCH', WRENCH_IN_FRAME, 'ANGLE', TENSION_DEG)

if GRAY_OUT:
    gray_abs = os.path.abspath(GRAY_OUT)
    os.makedirs(os.path.dirname(gray_abs), exist_ok=True)
    try:
        from PIL import Image
        im = Image.open(out_abs).convert('L')
        im.save(gray_abs, optimize=True)
        print('WROTE-GRAY', gray_abs)
    except ImportError:
        import numpy as np
        img_bl = bpy.data.images.load(out_abs)
        arr = np.empty(len(img_bl.pixels), dtype=np.float32)
        img_bl.pixels.foreach_get(arr)
        arr = arr.reshape((-1, 4))
        lum = 0.2126 * arr[:, 0] + 0.7152 * arr[:, 1] + 0.0722 * arr[:, 2]
        arr[:, 0] = lum
        arr[:, 1] = lum
        arr[:, 2] = lum
        img_bl.pixels.foreach_set(arr.ravel())
        img_bl.filepath_raw = gray_abs
        img_bl.file_format = 'PNG'
        img_bl.save()
        bpy.data.images.remove(img_bl)
        print('WROTE-GRAY-NP', gray_abs)
