# Lockwright — D-58 arrival scene: a 2-3 s camera move up the last flight of a tenement stair to the client's
# landing, ending on a door framing shot (the "hold" still) with anchors for compositing the client cut-out.
# Built on the stairwell kit: art/blender/stairwell.py is executed unchanged (its --norender path) and this
# script edits the result: arriving flight + stair window cut into the landing, brass number plate, a handmade
# wreath, wall mailbox with a name card, a moving camera and time-of-day lighting. 1 unit = 1 mm.
#
#   blender -b -P art/blender/arrival_scene.py -- --job wrong_floor --time night --mode both
#       --mode seq|still|both|anchors|shadow   what to render (anchors = JSON only, no render)
#       --time day|evening|night               lighting
#       --device CPU|GPU   --spp 12 --still-spp 64   --res 270x480 --still-res 540x960
#       --frames 30 --fps 12 --step 1          (step > 1 renders every n-th frame for a quick look)
#       --door closed|ajar                     ajar = opened on the chain (doorway slot for the second speaker)
#       --figure SLOT=path.png                 with --mode shadow: card that only casts shadows, writes a
#                                              shadow-ratio map for art/blender/arrival_composite.py
#       --hair 0|1 (coir doormat fibres; 1 for finals)   --out-dir art/renders/arrival
# Outputs (in --out-dir): <job>_<time>[_ajar]_seq/f_####.png, <..>_hold.png, <..>_hold.json (D-41 anchors + figure
# slots: feet line, height px, lights), <..>_hold_depth.png (16-bit planar depth, occlusion matte for figures),
# <..>_shadow_<slot>.png (shadow ratio, --mode shadow). Commands for the GPU finals: art/renders/arrival/README.md.
import bpy, math, os, sys, json, random, runpy, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from env_common import *
from env_common import _bev
from mathutils import Vector, Matrix

arg = cli()
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
JOB = arg('--job', 'wrong_floor'); MODE = arg('--mode', 'both')
# per-job dressing (door, number, props, camera end, figure slots) is data: art/blender/arrival_jobs.json
_JOBS = json.load(open(os.path.join(HERE, 'arrival_jobs.json'), encoding='utf-8'))['jobs']
if JOB not in _JOBS: sys.exit('arrival_scene: unknown --job %s (add it to arrival_jobs.json)' % JOB)
J = _JOBS[JOB]; DOORC = J.get('door', {}); CAMC = J.get('camera', {})
TIME = arg('--time', J.get('times', ['night'])[0])
DEVICE = arg('--device', 'CPU').upper(); SPP = int(arg('--spp', '12')); STILL_SPP = int(arg('--still-spp', '64'))
RES = [int(v) for v in arg('--res', '270x480').split('x')]; STILL_RES = [int(v) for v in arg('--still-res', '540x960').split('x')]
FRAMES = int(arg('--frames', '36')); FPS = int(arg('--fps', '12')); STEP = int(arg('--step', '1'))
DOOR = arg('--door', DOORC.get('state', 'closed')); HAIR = arg('--hair', '0'); NUMBER = arg('--number', str(J.get('number', '19')))
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT, 'art', 'renders', 'arrival')))
THREADS = int(arg('--threads', '0'))
FIGS = dict(v.split('=', 1) for i, v in enumerate(argv) if i and argv[i - 1] == '--figure')
os.makedirs(OUT_DIR, exist_ok=True)
# '_ajar' only marks a second door state of a job (wrong_floor: Teresa opens); a job whose door is open anyway has none
BASE = '%s_%s' % (JOB, TIME) + ('_ajar' if DOOR == 'ajar' and DOORC.get('state', 'closed') != 'ajar' else '')
STYLE = DOORC.get('style', 'oak'); PLATE = J.get('plate', 'brass'); WREATH = bool(J.get('wreath', False))
STAIR = J.get('stair', 'wood'); MAILBOX = J.get('mailbox', {}); PROPS_CFG = J.get('props', [])
PAD = 34 if STYLE == 'padded' else 0     # leatherette padding: the door face comes forward, hardware with it

# ---------------------------------------------------------------- 1. the stairwell kit, unchanged
_tmp = tempfile.mkdtemp(prefix='lw_arrival_')
_saved = sys.argv
sys.argv = ['blender', '--', '--out', os.path.join(_tmp, 'kit.png'), '--norender', '--number', NUMBER, '--hair', HAIR]
K = runpy.run_path(os.path.join(HERE, 'stairwell.py'), run_name='stairwell_kit')
sys.argv = _saved
g = lambda n: K[n]
DX0, DX1, DTOP, AW, LY = g('DX0'), g('DX1'), g('DTOP'), g('AW'), g('LY')
LX0, LX1, LZ0, LZ1, TR = g('LX0'), g('LX1'), g('LZ0'), g('LZ1'), g('TR')
CEIL, WT, LAMP_Z, STRIPE = g('CEIL'), g('WT'), g('LAMP_Z'), g('STRIPE')
G, LAMPX, SWX, SWZ, HX, HZ = g('G'), g('LAMPX'), g('SWX'), g('SWZ'), g('HX'), g('HZ')
NP, NPW, NPH, EP = g('NP'), g('NPW'), g('NPH'), g('EP')
lamperia, stripe, upper, ceiling_m, cream = g('lamperia'), g('stripe'), g('upper'), g('ceiling'), g('cream')
floor_m, skirt, black_iron, steel, brass, rail_wood = g('floor'), g('skirt'), g('black_iron'), g('steel'), g('brass'), g('rail_wood')
card_m, dark, door_wood, rng = g('name_card') if 'name_card' in K else g('card'), g('dark'), g('door_wood'), random.Random(58)

def drop(*prefixes):
    for o in list(bpy.data.objects):
        if o.name.startswith(prefixes): bpy.data.objects.remove(o, do_unlink=True)
# props that belong to the static shot or are rebuilt here
drop('hand_grime', 'clipboard', 'pencil', 'body', 'floor', 'behind', 'ceiling', 'skirt_side', 'left_', 'inside_floor', 'aim',
     *(('enamel_', 'number', 'ep_screw') if PLATE != 'enamel' else ()), *(() if J.get('flyer', True) else ('flyer',)))
for o in list(bpy.data.objects):
    if o.type == 'LIGHT': bpy.data.objects.remove(o, do_unlink=True)
for c in list(bpy.data.cameras): bpy.data.cameras.remove(c)

# ---------------------------------------------------------------- 2. arriving flight (left), stair window
# U-stair: we arrive up a flight along the left wall heading +y (towards the door wall); the kit's flight on
# the right leaves upwards heading -y. Top of our flight at y = TOPY, half-landing NSTEP risers below.
FX0, FX1 = -1700, -560          # flight channel (between the outer wall and the spine wall)
RISE, TREAD, NSTEP = 172, 285, 10
TOPY = -2600
HALFZ = -RISE * NSTEP           # half-landing level (-1720)
Y_BOT = TOPY - (NSTEP - 1) * TREAD   # foot of the flight (-5165)
BACKY, LOWZ = -6400, -1980
def stair_z(y):
    """Walking surface height along the flight (continuous, through the nosings)."""
    if y >= TOPY: return 0.0
    if y <= Y_BOT: return HALFZ
    return HALFZ + (y - Y_BOT) / (TOPY - Y_BOT) * (-HALFZ - RISE) + RISE * 0.5
# floors: landing (with the stair opening), half-landing
bx('floor_landing', FX1, 2400, -4300, 0, -220, 0, floor_m)
bx('floor_top', FX0, FX1, TOPY, 0, -220, 0, floor_m)
bx('floor_nosing', FX0, FX1, TOPY - 25, TOPY + 30, -40, 2, door_wood('X', 300, ((FX0 + FX1) / 2, TOPY, 0), 40), bev=3)
bx('floor_half', FX0, FX1, BACKY, Y_BOT, HALFZ - 60, HALFZ, terrazzo('half_terrazzo', matrix=(0.34, 0.32, 0.30), seed=7, chip_scale=1.6, mute=0.35))
for k in range(NSTEP - 1):
    y0 = Y_BOT + k * TREAD; y1 = y0 + TREAD; z1 = HALFZ + (k + 1) * RISE
    bx('a_tread%d' % k, FX0, FX1, y0, y1 + 25, z1 - 40, z1, door_wood('X', 310 + k, ((FX0 + FX1) / 2, (y0 + y1) / 2, z1), 40), bev=3)
    bx('a_riser%d' % k, FX0, FX1, y0, y0 + 22, z1 - RISE, z1 - 40, cream, bev=1.5)
    bx('a_fill%d' % k, FX0, FX1, y0 + 22, y1 + 25, LOWZ, z1 - 40, upper)
bx('a_riser_top', FX0, FX1, TOPY - 22, TOPY, -RISE, -40, cream, bev=1.5)
bx('a_fill_half', FX0, FX1, BACKY, Y_BOT, LOWZ, HALFZ - 60, upper)

def yz_prism(name, pts, x0, x1, mat):
    """Closed outline in the YZ plane, extruded between x0 and x1 (walls whose paint line follows the stair)."""
    bm = bmesh.new(); vs = [bm.verts.new((x0, y, z)) for y, z in pts]; f = bm.faces.new(vs)
    ex = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [q for q in ex['geom'] if isinstance(q, bmesh.types.BMVert)]: v.co.x = x1
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); o.data.materials.append(mat); return o

def paint_line(y):   # lamperia top: 1500 above the walking line, level on the landings
    return min(LAMP_Z, max(HALFZ + LAMP_Z, stair_z(y) - RISE * 0.5 + LAMP_Z))
ys = [BACKY, Y_BOT, TOPY, 0]
WIN = (-1580, -1010, 980, 2560)          # stair window in the landing's back wall (courtyard side): x0, x1, z0, z1
def walls(name, xa, xb, ya, yb, face, holes=()):
    """Lamperia / stripe / lime on one wall plane (face = side the paint is on, for a 1 mm proud stripe)."""
    yy = [y for y in ys if ya <= y <= yb]
    yy = sorted(set([ya, yb] + yy))
    lam = yz_prism(name + '_lam', [(y, LOWZ) for y in yy] + [(y, paint_line(y)) for y in reversed(yy)], xa, xb, lamperia)
    xs = (xa - 1, xb) if face > 0 else (xa, xb + 1)
    st = yz_prism(name + '_str', [(y, paint_line(y)) for y in yy] + [(y, paint_line(y) + STRIPE) for y in reversed(yy)], *xs, stripe)
    li = yz_prism(name + '_lime', [(y, paint_line(y) + STRIPE) for y in yy] + [(y, CEIL) for y in reversed(yy)], xa, xb, upper)
    for o in (lam, st, li):
        for h in holes:
            if h[4] < max(paint_line(y) for y in yy) + STRIPE + 2000: cut(o, bx('hole', *h))
        _bev(o, 1.5, 2, 30)
    return lam, st, li
walls('outer', FX0 - WT, FX0, BACKY, 0, +1)
for nm in ('back_lamp', 'back_str', 'back_lime'):
    cut(bpy.data.objects[nm], bx('hole', WIN[0], WIN[1], -10, WT + 10, WIN[2], WIN[3]))
walls('spine', FX1, FX1 + 120, BACKY, -4300, -1)
bx('spine_low', FX1, FX1 + 120, -4300, TOPY, LOWZ, -220, upper)         # under the landing edge
bx('behind_flight', FX0 - WT, FX1 + 120, BACKY - 100, BACKY, LOWZ, CEIL, upper)
bx('behind', FX1, 2400, -4400, -4300, -220, CEIL, upper)
bx('ceiling', FX0 - WT, 2400, BACKY - 100, WT, CEIL, CEIL + 200, ceiling_m)
bx('skirt_side', FX0, FX0 + 14, TOPY, 0, 0, 95, skirt, bev=3)

# landing edge balustrade over the flight (x = FX1) and a wall rail along the flight on the spine side
RAIL = 900
for y in range(TOPY - 60, -4300, -140):
    bx('lb', FX1 + 40, FX1 + 52, y - 6, y + 6, 0, RAIL - 30, black_iron, bev=1.2)
lbp = [(FX1 + 46, -4280, RAIL), (FX1 + 46, TOPY - 40, RAIL), (FX1 + 46, TOPY + 120, RAIL)]
tube('landing_rail', lbp, 28, rail_wood, res=5, smooth_pts=False)
bx('landing_newel', FX1 + 8, FX1 + 84, TOPY - 40, TOPY + 36, 0, RAIL + 140, door_wood('Z', 330, (FX1 + 46, TOPY, 500), 70), bev=4)
wr = [(FX0 + 60, y, stair_z(y) + RAIL - 40) for y in (Y_BOT - 300, Y_BOT, TOPY, TOPY + 500)]
wr[0] = (FX0 + 60, Y_BOT - 300, HALFZ + RAIL - 40); wr[-1] = (FX0 + 60, TOPY + 500, RAIL - 40)
tube('wall_rail', wr, 24, rail_wood, res=5)
for y in (Y_BOT + 300, (Y_BOT + TOPY) / 2, TOPY - 200):
    z = stair_z(y) + RAIL - 40
    tube('rail_bracket', [(FX0 + 2, y, z - 55), (FX0 + 40, y, z - 55), (FX0 + 60, y, z - 26)], 6, black_iron, smooth_pts=False)
    cyl('rail_rose', 18, 6, (FX0 + 3, y, z - 55), axis='X', verts=32).data.materials.append(black_iron)

# stair window: painted timber frame, mullion + transom, ribbed (obscured) glass, sky beyond
win_paint = oil_paint('window_paint', (0.70, 0.66, 0.56), rough=0.35, chips=0.5, scuffs=0.3, strokes='Z', seed=8, edge_chips=1.0)
wx0, wx1, wz0, wz1 = WIN; WY = WT * 0.55
for nm, a, b, c, d in (('wf_l', wx0, wx0 + 70, wz0, wz1), ('wf_r', wx1 - 70, wx1, wz0, wz1), ('wf_b', wx0, wx1, wz0, wz0 + 80),
                       ('wf_t', wx0, wx1, wz1 - 70, wz1), ('wf_m', (wx0 + wx1) / 2 - 28, (wx0 + wx1) / 2 + 28, wz0, wz1 - 520),
                       ('wf_tr', wx0, wx1, wz1 - 520, wz1 - 470)):
    bx(nm, a, b, WY - 35, WY + 35, c, d, win_paint, bev=2)
bx('w_sill', wx0 - 40, wx1 + 40, -40, WY, wz0 - 30, wz0, terrazzo('sill', matrix=(0.40, 0.38, 0.35), seed=9), bev=3)
bx('w_reveal_paint', wx0 - 2, wx1 + 2, 0, WY - 34, wz1 - 1, wz1 + 1, upper)
ribbed = bpy.data.materials.new('ribbed_glass'); ribbed.use_nodes = True
rb = ribbed.node_tree.nodes['Principled BSDF']
rb.inputs['Transmission Weight'].default_value = 1.0; rb.inputs['Roughness'].default_value = 0.22; rb.inputs['IOR'].default_value = 1.5
rb.inputs['Base Color'].default_value = (0.86, 0.90, 0.88, 1)
bx('w_glass', wx0 + 10, wx1 - 10, WY - 3, WY + 3, wz0 + 10, wz1 - 10, ribbed).visible_shadow = False
SKY = {'night': ((0.10, 0.16, 0.34), 0.25), 'evening': ((0.22, 0.34, 0.80), 1.2), 'day': ((0.86, 0.90, 0.98), 4.0)}[TIME]
sky = bx('w_sky', wx0 - 1500, -820, WT + 2500, WT + 2520, wz0 - 1500, wz1 + 1500, emissive('sky', SKY[0], SKY[1], (0, 0, 0)))
sky.visible_shadow = False
stain_decal('floor_grime', 'Z', 0.2, (FX1, 2400, -4300, 0), [(0, -30, 900, 70, 0.5), (DX0 - 150, -400, 120, 380, 0.25)], color=(0.09, 0.08, 0.065), rough=0.7, noise_scale=0.03)

# ---------------------------------------------------------------- 3. the door dressing for this job
# ---------------------------------------------------------------- 3a. door style for this job (arrival_jobs.json)
LEAF_WOOD = ('stile_l', 'stile_r', 'rail_t', 'rail_lock', 'rail_b', 'mun_u', 'mun_l')   # kit leaf pieces (exact names)
HARDWARE = ('escutcheon', 'cyl_face', 'plug', 'keyway', 'kw_dark', 'rose', 'lever', 'peep', 'nameframe', 'namecard', 'np_screw',
            'enamel_', 'number', 'ep_screw')
FACE = LY - PAD                      # front plane of the door face (the leatherette cushion on a padded door)
if STYLE == 'painted':   # old leaf under many coats of oil paint: panels, mouldings and the old repair all painted over
    leaf_paint = oil_paint('leaf_paint', tuple(DOORC.get('paint', (0.20, 0.085, 0.04))), rough=0.3, under=(0.42, 0.36, 0.26),
                           base=(0.30, 0.19, 0.10), chips=0.35, scuffs=0.45, strokes='Z', seed=21, chip_scale=0.03, edge_chips=1.0)
    for o in bpy.data.objects:
        if (o.name in LEAF_WOOD or o.name.startswith(('panel', 'mould', 'old_plug'))) and o.type in ('MESH', 'CURVE'):
            for sl in o.material_slots: sl.material = leaf_paint
elif STYLE == 'padded':  # PRL "obite drzwi": leatherette over wadding, rolled edge, brass upholstery nails laced in diamonds
    drop('old_plug')
    for o in bpy.data.objects:
        if o.name.startswith(HARDWARE): o.location.y -= PAD
    leather = (photo_mat('ph_door_leather', DOORC.get('leather', 'leather_chocolate'), scale=420, metallic=0.0, bump=0.6, coat=0.25,
                         grime=0.4, wear=0.25) if photo_enabled() else plastic('door_leather', (0.10, 0.05, 0.03), rough=0.45))
    nail_m = metal('upholstery_nail', (0.74, 0.55, 0.30), 0.3, marks='stamp', wear=0.5, grime=0.6, patina=0.5, bevel_r=0.4)
    cord_m = paint('lacing_cord', (0.30, 0.22, 0.12), rough=0.5, metal_col=(0.5, 0.4, 0.2), chip=0.0, grime=0.5)
    PX0, PX1, PZ0, PZ1 = LX0 + 34, LX1 - 34, LZ0 + 40, LZ1 - 40
    STEP_D = 150.0                                   # diamond lattice: nails where the lacing crosses
    nails = []
    cx, cz = (PX0 + PX1) / 2, (PZ0 + PZ1) / 2
    for i in range(-8, 9):
        for k in range(-16, 17):
            if (i + k) % 2: continue
            x, z = cx + i * STEP_D / 2, cz + k * STEP_D / 2
            if PX0 + 20 < x < PX1 - 20 and PZ0 + 20 < z < PZ1 - 20 and not (abs(x - HX) < 90 and abs(z - HZ + 30) < 200) \
                    and not (abs(x) < 70 and abs(z - 1585) < 60) and not (abs(x) < 90 and abs(z - NP[2]) < 50) \
                    and not (DOORC.get('new_deadbolt') and abs(x - HX) < 70 and abs(z - HZ - 330) < 70):
                nails.append((x, z))
    nail_set = {(round(x), round(z)) for x, z in nails}
    def tuft(x, z):   # cushion height at a point: pulled in at nails and along the lacing, full in between
        d = min([(x - a) ** 2 + (z - b) ** 2 for a, b in nails] or [1e9])
        u, v = (x - cx + z - cz) / STEP_D, (x - cx - z + cz) / STEP_D      # distance to the diagonal lacing lines
        dl = min(abs(u - round(u)), abs(v - round(v))) * STEP_D / 1.414
        e = min(1.0, (x - PX0) / 60, (PX1 - x) / 60, (z - PZ0) / 60, (PZ1 - z) / 60)
        return PAD * (1.0 - 0.55 * math.exp(-d / 900.0) - 0.22 * math.exp(-dl * dl / 300.0)) * max(0.0, e) ** 0.5
    bm = bmesh.new(); NXg, NZg = 96, 220
    grid = [[bm.verts.new((PX0 + (PX1 - PX0) * a / NXg, 0, PZ0 + (PZ1 - PZ0) * c / NZg)) for a in range(NXg + 1)] for c in range(NZg + 1)]
    for c in range(NZg):
        for a in range(NXg):
            bm.faces.new((grid[c][a], grid[c][a + 1], grid[c + 1][a + 1], grid[c + 1][a]))
    for v in bm.verts: v.co.y = LY - 2 - tuft(v.co.x, v.co.z)
    bm.normal_update()
    for f in bm.faces:
        f.smooth = True
        if f.normal.y > 0: f.normal_flip()
    me = bpy.data.meshes.new('padding'); bm.to_mesh(me); bm.free()
    pad = bpy.data.objects.new('padding', me); bpy.context.collection.objects.link(pad); pad.data.materials.append(leather)
    # rolled edge round the leaf (a leatherette tube stuffed with wadding) on a flat border
    bx('pad_border', LX0, LX1, LY - 6, LY, LZ0, LZ1, leather, bev=2)
    RY = LY - PAD * 0.55
    roll = [(PX0 - 6, RY, PZ0 - 6), (PX1 + 6, RY, PZ0 - 6), (PX1 + 6, RY, PZ1 + 6), (PX0 - 6, RY, PZ1 + 6), (PX0 - 6, RY, PZ0 - 6)]
    tube('pad_roll', roll, 19, leather, res=4, smooth_pts=False)
    for x, z in nails:
        screw_head('pad_nail', (x, LY - 2 - tuft(x, z) - 0.5, z), 6.0, 3.2, axis='-Y', slot=False, kind='dome', mat=nail_m)
    edge = [(PX0 - 6 + (PX1 - PX0 + 12) * q / 12, PZ0 - 30) for q in range(13)] + [(PX0 - 6 + (PX1 - PX0 + 12) * q / 12, PZ1 + 30) for q in range(13)] + \
           [(PX0 - 30, PZ0 + (PZ1 - PZ0) * q / 28) for q in range(29)] + [(PX1 + 30, PZ0 + (PZ1 - PZ0) * q / 28) for q in range(29)]
    for x, z in edge:   # a row of nails holding the border outside the roll
        screw_head('pad_nail_edge', (x, LY - 7.5, z), 5.0, 2.6, axis='-Y', slot=False, kind='dome', mat=nail_m)
    for x, z in nails:  # the lacing: thin cord from nail to nail along the diagonals, sunk into the cushion
        for dx, dz in ((STEP_D / 2, STEP_D / 2), (STEP_D / 2, -STEP_D / 2)):
            if (round(x + dx), round(z + dz)) in nail_set:
                pts = [(x + dx * q / 6, LY - 2 - tuft(x + dx * q / 6, z + dz * q / 6) - 1.2, z + dz * q / 6) for q in range(7)]
                tube('pad_cord', pts, 1.6, cord_m, res=2)
if DOORC.get('new_deadbolt'):   # a second, brand-new lock above the old one: bright rose, crisp plug, no grime yet
    new_steel = metal('new_steel', (0.72, 0.72, 0.70), 0.16, marks='turn', marks_axis=(0, 1, 0), wear=0.0, grime=0.0, bevel_r=0.4)
    new_brass = metal('new_brass', (0.86, 0.66, 0.36), 0.2, marks='turn', marks_axis=(0, 1, 0), wear=0.0, grime=0.05, bevel_r=0.3)
    DBZ = HZ + 330
    r_ = lathe_x('db_rose', [(0, 0.01), (0, 27), (2.5, 27), (7, 23), (9, 18), (9, 0.01)], seg=96)
    r_.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); r_.location = (HX, FACE - 1, DBZ); setmat(r_, new_steel)
    pg = cyl('db_plug', 9.0, 3.0, (HX, FACE - 10.6, DBZ), axis='Y', verts=96); setmat(pg, new_brass)
    kw2 = bx('db_kw', HX - 1.1, HX + 1.1, FACE - 30, FACE, DBZ - 6, DBZ + 4); cut(pg, kw2)
    bx('db_kw_dark', HX - 2.4, HX + 2.4, FACE - 9.4, FACE - 9.0, DBZ - 7, DBZ + 5, dark)
    cut(r_, cyl('db_hole', 9.2, 30, (HX, FACE - 10, DBZ), axis='Y', verts=96))

# ---------------------------------------------------------------- 3b. number plate, name card, wreath
if PLATE == 'brass':
    # brass number plate (engraved, black-filled numerals) replaces the enamel one
    brass_plate = metal('plate_brass', (0.78, 0.56, 0.28), 0.28, marks='grind', marks_axis=(1, 0, 0), wear=0.6, grime=0.8, patina=0.5, bevel_r=0.5)
    black_fill = paint('engrave_fill', (0.015, 0.013, 0.012), rough=0.5, chip=0.2, grime=0.2)
    PW, PH = 112, 74
    pl = slab('number_plate', rounded_rect(PW, PH, 4), 2.2, brass_plate, bev=0.8)
    place(pl, (EP[0], FACE - 0.5, EP[2]), rot=(90, -1.2, 0))
    num = text_obj('number_19', NUMBER, 50, extrude=0.25, mat=black_fill); num.data.offset_y = -1.0
    num.matrix_world = Matrix.Translation(Vector((EP[0], FACE - 2.5, EP[2] - 1.5))) @ Matrix.Rotation(math.radians(-1.2), 4, 'Y') @ Matrix.Rotation(math.radians(90), 4, 'X')
    for sx in (-1, 1):
        screw_head('np2_screw', (EP[0] + sx * (PW / 2 - 8), FACE - 2.6, EP[2]), 2.0, 1.0, axis='-Y', mat=brass_plate, rot=rng.uniform(0, 3))
# the card name plate moves down to make room for the wreath (it stays the D-41 text anchor)
if PLATE != 'brass':
    PW, PH = 128, 88       # the kit's enamel plate stays
    # its white line and numerals are thinner than enamel()'s edge-chip mask, which turned them all to iron (a blank
    # blue plate): plain glassy white for the print, the plate keeps its chipped rim
    ew = bpy.data.materials.new('enamel_print'); ew.use_nodes = True; pb_ = ew.node_tree.nodes['Principled BSDF']
    pb_.inputs['Base Color'].default_value = (0.78, 0.77, 0.72, 1); pb_.inputs['Roughness'].default_value = 0.12
    pb_.inputs['Coat Weight'].default_value = 0.6; pb_.inputs['Coat Roughness'].default_value = 0.03
    for o in bpy.data.objects:
        if o.name.startswith(('enamel_line', 'number')) and o.type in ('MESH', 'FONT'):
            for sl in o.material_slots: sl.material = ew
NP_DZ = -185 if WREATH else 0
for o in bpy.data.objects:
    if o.name.startswith(('nameframe', 'namecard', 'np_screw')): o.location.z += NP_DZ
NPZ = NP[2] + NP_DZ

if WREATH:
    # handmade wreath: twisted willow ring, dried flowers and leaves wired on, linen ribbon to a pin in the top rail
    WC = Vector((0, FACE - 34, 1650)); WR, Wr = 150, 34
    willow = oak('willow', light=(0.36, 0.26, 0.15), dark=(0.17, 0.11, 0.06), axis='Z', seed=3, ring=1.5, coat=0.0, rough=0.8, wear=0.0)
    for s in range(7):   # several overlapping twisted rods
        pts = []; ph = rng.uniform(0, 6.28); tw = rng.uniform(2.5, 4.0)
        for i in range(97):
            a = 2 * math.pi * i / 96; r = WR + Wr * 0.45 * math.cos(tw * a + ph); dy = Wr * 0.45 * math.sin(tw * a + ph)
            pts.append((WC.x + r * math.cos(a), WC.y + dy, WC.z + r * math.sin(a)))
        tube('willow%d' % s, pts, rng.uniform(4, 6.5), willow, res=3)
    FLOWER = [((0.58, 0.24, 0.24), 'rose'), ((0.36, 0.26, 0.52), 'lavender'), ((0.78, 0.55, 0.12), 'tansy'),
              ((0.82, 0.76, 0.62), 'statice'), ((0.55, 0.12, 0.08), 'rosehip')]
    fmats = [plastic('dried_%s' % n, c, rough=0.7, seed=i, grime=0.3, sheen_scuffs=0.0) for i, (c, n) in enumerate(FLOWER)]
    leaf_m = plastic('dried_leaf', (0.30, 0.32, 0.20), rough=0.65, seed=9, grime=0.2, sheen_scuffs=0.0)
    bm = bmesh.new()
    for i in range(240):
        a = rng.uniform(0, 2 * math.pi); rr = WR + rng.uniform(-Wr, Wr) * 0.9
        if rng.random() < 0.55 and math.sin(a) > -0.2 and abs(math.cos(a)) < 0.45: continue  # sparser at the top (handmade)
        p = Vector((WC.x + rr * math.cos(a), WC.y - rng.uniform(10, 30), WC.z + rr * math.sin(a)))
        if rng.random() < 0.38:   # leaf: thin ellipse, tangent-ish
            ret = bmesh.ops.create_circle(bm, cap_ends=True, segments=8, radius=1.0)
            L, W_ = rng.uniform(26, 44), rng.uniform(8, 13)
            M = (Matrix.Translation(p) @ Matrix.Rotation(a + math.pi / 2 + rng.uniform(-0.7, 0.7), 4, 'Y') @
                 Matrix.Rotation(math.radians(90 + rng.uniform(-30, 30)), 4, 'X') @ Matrix.Diagonal((L, W_, 1, 1)))
            bmesh.ops.transform(bm, matrix=M, verts=ret['verts'])
            for f in {f for v in ret['verts'] for f in v.link_faces}: f.material_index = len(fmats)
        else:
            k = rng.choices(range(len(FLOWER)), weights=(3, 3, 2, 3, 1))[0]
            ret = bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0)
            s_ = rng.uniform(8, 16) if k != 1 else rng.uniform(5, 7)
            M = Matrix.Translation(p) @ Matrix.Rotation(rng.uniform(0, 6.3), 4, 'Z') @ Matrix.Diagonal((s_, s_ * 0.75, s_ * (2.4 if k == 1 else 1.0), 1))
            bmesh.ops.transform(bm, matrix=M, verts=ret['verts'])
            for f in {f for v in ret['verts'] for f in v.link_faces}: f.material_index = k
    me = bpy.data.meshes.new('wreath_dressing'); bm.to_mesh(me); bm.free()
    wd = bpy.data.objects.new('wreath_dressing', me); bpy.context.collection.objects.link(wd)
    for m_ in fmats + [leaf_m]: wd.data.materials.append(m_)
    for p in wd.data.polygons: p.use_smooth = True
    linen = paper('linen_ribbon', (0.70, 0.64, 0.52), fibre=1.5, seed=4, grime=0.3)
    pin_z = LZ1 - TR - 12
    tube('ribbon_l', [(WC.x - 14, WC.y + 4, WC.z + WR + 10), (WC.x - 6, FACE - 6, pin_z - 60), (WC.x, FACE - 3, pin_z)], 3.5, linen, res=2)
    tube('ribbon_r', [(WC.x + 14, WC.y + 4, WC.z + WR + 10), (WC.x + 6, FACE - 6, pin_z - 60), (WC.x, FACE - 3, pin_z)], 3.5, linen, res=2)
    screw_head('wreath_pin', (WC.x, FACE - 2, pin_z), 2.4, 2.0, axis='-Y', slot=False, kind='dome', mat=brass)
    for sx in (-1, 1):   # bow at the bottom
        tube('bow', [(WC.x, WC.y - 22, WC.z - WR - 10), (WC.x + sx * 34, WC.y - 26, WC.z - WR - 2), (WC.x + sx * 42, WC.y - 24, WC.z - WR - 30),
                     (WC.x, WC.y - 22, WC.z - WR - 10)], 6, linen, res=2)
        tube('bow_tail', [(WC.x, WC.y - 22, WC.z - WR - 12), (WC.x + sx * 18, WC.y - 18, WC.z - WR - 60), (WC.x + sx * 26, WC.y - 14, WC.z - WR - 105)], 5, linen, res=2)
# wall mailbox (painted steel) right of the door: name card window + slot
MBX0, MBX1, MBZ0, MBZ1 = 585, 735, 980, 1230
mb_paint = paint('mailbox_paint', (0.10, 0.17, 0.12), rough=0.38, metal_col=(0.4, 0.4, 0.4), chip=0.4, grime=0.7)
bx('mailbox', MBX0, MBX1, -82, -1, MBZ0, MBZ1, mb_paint, bev=3)
bx('mailbox_lid', MBX0 - 3, MBX1 + 3, -90, -60, MBZ1 - 10, MBZ1 + 8, mb_paint, bev=3)
bx('mailbox_slot', MBX0 + 22, MBX1 - 22, -84, -78, MBZ1 - 52, MBZ1 - 40, dark)
MC = ((MBX0 + MBX1) / 2, MBZ0 + 70); MCW, MCH = 96, 34
mcf = slab('mb_cardframe', rounded_rect(MCW + 10, MCH + 10, 2), 1.6, steel, bev=0.4)
cut(mcf, place(slab('mbwin', rounded_rect(MCW - 4, MCH - 4, 1), 10), (0, 0, -4)))
place(mcf, (MC[0], -83, MC[1]), rot=(90, 0, 0))
bx('mb_card', MC[0] - MCW / 2, MC[0] + MCW / 2, -83.4, -82.9, MC[1] - MCH / 2, MC[1] + MCH / 2, card_m)
bx('mb_lock', MC[0] - 7, MC[0] + 7, -88, -82, MBZ0 + 150, MBZ0 + 164, steel, bev=1)

# stain decals (env_common.stain_decal): no specular on the dirt layer, otherwise the decal adds a sheen the matte
# paint/terrazzo under it does not have and shows as a pale oval under a grazing light (also visible in stairwell.png)
for m_ in bpy.data.materials:
    if m_.use_nodes and any(n.type == 'BSDF_TRANSPARENT' for n in m_.node_tree.nodes) and 'Principled BSDF' in m_.node_tree.nodes:
        pb = m_.node_tree.nodes['Principled BSDF']; pb.inputs['Specular IOR Level'].default_value = 0.0

# ---------------------------------------------------------------- 4. door state and the flat behind it
leaf = [o for o in bpy.data.objects if o.type in ('MESH', 'CURVE', 'FONT')]
def in_leaf(o):
    bpy.context.view_layer.update()
    pts = [o.matrix_world @ Vector(c) for c in o.bound_box]
    return (min(p.x for p in pts) > LX0 - 150 and max(p.x for p in pts) < LX1 + 20 and min(p.y for p in pts) > LY - 80 - PAD
            and max(p.y for p in pts) < LY + 50 and min(p.z for p in pts) > LZ0 - 2 and max(p.z for p in pts) < LZ1 + 2)
leaf = [o for o in leaf if in_leaf(o) and not o.name.startswith(('floor', 'stain', 'door_grime'))]
hinge = bpy.data.objects.new('door_hinge', None); bpy.context.collection.objects.link(hinge)
hinge.location = (LX0, LY + 45, 0); bpy.context.view_layer.update()
for o in leaf:
    o.parent = hinge; o.matrix_parent_inverse = hinge.matrix_world.inverted()
if DOOR == 'ajar':
    drop('flyer')
    hinge.rotation_euler.z = math.radians(DOORC.get('ajar_deg', 38))   # inward (+y), hinge on the left
bpy.context.view_layer.update()
if DOOR == 'ajar' and DOORC.get('chain', True):   # chain hooked but slack: staple on the jamb, slide on the leaf
    tip = hinge.matrix_world @ Vector((LX1 - LX0 - 40, -45 + LY - LY, 1500))
    chain = steel
    p0 = Vector((DX1 - 12, 40, 1500)); p1 = Vector((tip.x, tip.y - 8, 1500))
    n = 9
    for i in range(n):
        q = p0.lerp(p1, (i + 0.5) / n); q.z -= 30 * math.sin(math.pi * (i + 0.5) / n)
        tor = bpy.data.objects.new('chain', bpy.data.meshes.new('chain')); bpy.context.collection.objects.link(tor)
        bmc = bmesh.new(); bmesh.ops.create_circle(bmc, segments=12, radius=7)
        bmc.to_mesh(tor.data); bmc.free(); tor.location = q
        tor.rotation_euler = (math.radians(90 * (i % 2)), 0, math.atan2(p1.y - p0.y, p1.x - p0.x))
        sk = tor.modifiers.new('sk', 'SKIN')
        for v in tor.data.skin_vertices[0].data: v.radius = (1.6, 1.6)
        tor.data.materials.append(steel)
# the hall of the flat (only seen through the gap / under the door)
hall_wall = lime_wall('hall_wall', (0.70, 0.62, 0.48), seed=11, dirt=0.2, cracks=0.1)
parquet = oak('parquet', light=(0.42, 0.26, 0.12), dark=(0.20, 0.11, 0.05), axis='Y', seed=12, ring=1.8, coat=1.0, coat_rough=0.25, wear=0.6)
bx('hall_floor', -700, 1100, 150, 3200, -30, 0, parquet)
bx('hall_l', -800, -700, 150, 3200, 0, 2900, hall_wall); bx('hall_r', 1100, 1200, 150, 3200, 0, 2900, hall_wall)
bx('hall_back', -800, 1200, 3200, 3300, 0, 2900, hall_wall); bx('hall_ceil', -800, 1200, 150, 3300, 2900, 3000, hall_wall)
bx('hall_coats', 700, 1080, 900, 1900, 900, 1900, plastic('coats', (0.18, 0.12, 0.10), rough=0.8))   # coats on hooks (dark mass)

# ---------------------------------------------------------------- 4b. photo-material pass (art/textures/photo, D-48)
# The kit is procedural; here the big surfaces get the Magnific photo maps, then layers of use on top:
# plaster patches and old paint showing through, a grime band along the floor that follows the stair line,
# scuffs low on the dado, fingerprints/grease on brass. `--photo 0` keeps the procedural kit.
from lw_common import _noise, _mix, _maprange
from env_common import _math, _sep
def base_socket(m):
    nt = m.node_tree; b = nt.nodes['Principled BSDF']
    src = next((lk.from_socket for lk in nt.links if lk.to_socket == b.inputs['Base Color']), None)
    return nt, b, (src if src is not None else b.inputs['Base Color'].default_value)
def floor_line(nt, P):
    """Height of the walking surface under a wall point: 0 on the landing, the stair line along the flight."""
    X, Y, Z = _sep(nt, P)
    t = _maprange(nt, Y, Y_BOT, TOPY, 0.0, 1.0)
    return Z, _math(nt, 'ADD', _math(nt, 'MULTIPLY', t, -HALFZ), HALFZ)
def layer_use(m, grime_h=320, grime=0.55, patches=0.0, patch_col=(0.80, 0.77, 0.70), scuffs=0.0, seed=0.0):
    nt, b, col = base_socket(m); l = nt.links
    P = nt.nodes.new('ShaderNodeTexCoord').outputs['Object']
    if patches:   # replastered patches (lighter, smoother) and old paint layers where the top coat flaked
        pm = _maprange(nt, _noise(nt, P, 0.0024, detail=6, rough=0.65, dist=1.2), 0.60, 0.615, 0.0, patches * 0.45)
        col = _mix(nt, col, (*patch_col, 1), pm)
        fl = _maprange(nt, _noise(nt, P, 0.006, detail=10, rough=0.8, dist=0.6), 0.67, 0.685, 0.0, patches * 0.7)
        col = _mix(nt, col, (0.47, 0.52, 0.42, 1), fl)          # old green-grey coat under the lime
    if scuffs:    # shoe and bag scuffs: grey-black streaks low on the dado
        Z, F = floor_line(nt, P); h = _math(nt, 'SUBTRACT', Z, F)
        band = _maprange(nt, h, 450, 120, 0.0, 1.0)
        sc = _maprange(nt, _noise(nt, P, 0.02, detail=6, rough=0.6, stretch=(4.0, 4.0, 0.6)), 0.62, 0.7, 0.0, scuffs)
        col = _mix(nt, col, (0.08, 0.08, 0.075, 1), _math(nt, 'MULTIPLY', band, sc))
    if grime:     # dirt band along the floor (mop line), broken by noise
        Z, F = floor_line(nt, P); h = _math(nt, 'SUBTRACT', Z, F)
        g = _maprange(nt, h, grime_h, 0.0, 0.0, grime)
        g = _math(nt, 'MULTIPLY', g, _maprange(nt, _noise(nt, P, 0.01, detail=5), 0.3, 0.7, 0.5, 1.0))
        col = _mix(nt, col, (0.10, 0.085, 0.06, 1), g)
    l.new(col, b.inputs['Base Color']); return m
if photo_enabled():
    ph_lime = layer_use(photo_mat('ph_lime', 'wall_lime_plaster', scale=1000, metallic=0.0, bump=0.5, grime=0.4, tint=(0.82, 0.78, 0.69)),
                        grime_h=200, grime=0.35, patches=1.0, patch_col=(0.86, 0.83, 0.76))
    LAMP_C = J.get('lamperia')   # building's dado colour: the green photo pulled towards it (detail kept)
    ph_green = layer_use(photo_mat('ph_lamperia', 'wall_oil_paint_green', scale=760, metallic=0.0, bump=0.45, coat=0.35, grime=0.5,
                                   base=tuple(LAMP_C) if LAMP_C else (0.07, 0.14, 0.10), base_mix=0.8 if LAMP_C else 0.3),
                         grime_h=260, grime=0.6, scuffs=0.8)
    ph_ceiling = photo_mat('ph_ceiling', 'wall_lime_plaster', scale=1300, metallic=0.0, bump=0.3, grime=0.2, tint=(0.84, 0.81, 0.74))
    ph_terr = photo_mat('ph_terrazzo', 'terrazzo_grey_red', scale=900, metallic=0.0, bump=0.3, grime=0.6, wear=0.3, base=(0.40, 0.37, 0.34), base_mix=0.35)
    ph_brass = photo_mat('ph_brass', 'brass_patina_grease', scale=60, metallic=1.0, base=(0.70, 0.52, 0.28), base_mix=0.4, rough_add=0.08, wear=0.4, grime=0.8)
    SWAP = {upper: ph_lime, lamperia: ph_green, ceiling_m: ph_ceiling, floor_m: ph_terr, brass: ph_brass,
            bpy.data.materials['half_terrazzo']: ph_terr, bpy.data.materials['skirting']: ph_terr}
    if PLATE == 'brass': SWAP[brass_plate] = ph_brass
    for o in bpy.data.objects:
        if o.type in ('MESH', 'CURVE', 'FONT'):
            for sl in o.material_slots:
                if sl.material in SWAP: sl.material = SWAP[sl.material]
    # worn path on the landing: polished lighter centre from the stairs to the door, darker edges (decal-free: a
    # second terrazzo copy would double the textures, so the floor_grime decal + its stronger spots do it)
    stain_decal('floor_edge', 'Z', 0.25, (FX1, 2400, -4300, -10), [(FX1 + 60, -2000, 90, 2600, 0.55), (900, -900, 260, 900, 0.3),
                (-200, -2650, 700, 60, 0.35)], color=(0.07, 0.06, 0.045), rough=0.75, noise_scale=0.03)
    # door: hand grime round the lever and cylinder, kick marks at the bottom rail
    # (not on a painted leaf: the matte decal over glossy paint read as a pale oval; the paint has its own grime)
    if STYLE == 'painted': drop('door_grime')   # the kit's decal too
    else:
        stain_decal('handle_grime', 'Y', LY - 0.35, (HX - 260, LX1, HZ - 330, HZ + 260),
                    [(HX - 60, HZ - 10, 110, 150, 0.45), (HX + 10, HZ - 80, 50, 60, 0.35)], color=(0.035, 0.022, 0.012), rough=0.55, noise_scale=0.05)
    stain_decal('kick_marks', 'Y', LY - 0.35, (LX0, LX1, LZ0, LZ0 + 260), [(0, LZ0 + 60, 420, 120, 0.5)],
                color=(0.04, 0.03, 0.02), rough=0.7, noise_scale=0.06)
if DOOR == 'ajar':   # the door's decals swing with the leaf (they were left hanging in the doorway)
    M0 = Matrix.Translation(hinge.location)
    for o in bpy.data.objects:
        if o.name.startswith(('handle_grime', 'kick_marks', 'door_grime')):
            o.parent = hinge; o.matrix_parent_inverse = M0.inverted()
for m_ in bpy.data.materials:   # decals: no specular sheen (see above)
    if m_.use_nodes and any(n.type == 'BSDF_TRANSPARENT' for n in m_.node_tree.nodes) and 'Principled BSDF' in m_.node_tree.nodes:
        m_.node_tree.nodes['Principled BSDF'].inputs['Specular IOR Level'].default_value = 0.0

# ---------------------------------------------------------------- 4c. the flat's hall (seen through the open door)
# cement-tile floor, a runner, coats on a hook rail, a shoe cabinet, a framed photo and a warm wall lamp
if photo_enabled():
    setmat(bpy.data.objects['hall_floor'], photo_mat('ph_cement_tiles', 'cement_tiles', scale=600, metallic=0.0, bump=0.3, grime=0.5, wear=0.3,
                                                   base=(0.50, 0.42, 0.34), base_mix=0.3))
drop('hall_coats')
runner = plastic('runner', (0.30, 0.07, 0.05), rough=0.9, seed=4, grime=0.5, sheen_scuffs=0.0)
nt_, b_, c_ = base_socket(runner); Pp = nt_.nodes.new('ShaderNodeTexCoord').outputs['Object']; Xr, Yr, Zr = _sep(nt_, Pp)
stripes = _maprange(nt_, _math(nt_, 'ABSOLUTE', _math(nt_, 'SINE', _math(nt_, 'MULTIPLY', Xr, 0.06))), 0.85, 0.95)
nt_.links.new(_mix(nt_, c_, (0.62, 0.48, 0.22, 1), stripes), b_.inputs['Base Color'])
bx('runner', -330, 330, 300, 2900, 0, 6, runner, bev=2)
coat_cols = [(0.10, 0.12, 0.16), (0.30, 0.20, 0.12), (0.14, 0.13, 0.11), (0.42, 0.33, 0.22)]
bx('hook_rail', 1060, 1100, 700, 2000, 1700, 1790, door_wood('Y', 400, (1080, 1350, 1745), 90), bev=3)
for i, c in enumerate(coat_cols):   # coats: soft slabs hanging from the rail, slightly turned
    y = 830 + i * 330; w = 280 + 40 * (i % 2)
    co = bx('coat%d' % i, 960 - 40 * (i % 2), 1060, y - w / 2, y + w / 2, 650 + 120 * (i % 3), 1740, plastic('coat%d' % i, c, rough=0.85, seed=i, grime=0.2), bev=40, seg=4)
    co.rotation_euler.z = math.radians(rng.uniform(-8, 8))
bx('shelf_hat', 900, 1100, 700, 2000, 1950, 1975, door_wood('Y', 401, (1000, 1350, 1960), 90), bev=2)
bx('shoe_cabinet', 760, 1100, 2150, 2950, 0, 900, oil_paint('cabinet', (0.62, 0.58, 0.48), rough=0.35, chips=0.3, scuffs=0.3, seed=12), bev=4)
bx('photo_frame', -150, 150, 3190, 3200, 1450, 1830, door_wood('X', 402, (0, 3195, 1640), 40), bev=2)
bx('photo', -125, 125, 3188, 3191, 1475, 1805, paper('photo', (0.55, 0.50, 0.42), grime=0.3, seed=5))
hl = lathe('hall_lamp', [(0.1, 2150), (70, 2160), (95, 2230), (80, 2300), (40, 2330), (0.1, 2335)], 600, 3150, seg=48)
setmat(hl, opal_glass('hall_opal', glow=3.0 if TIME != 'day' else 0.0))
bpy.ops.object.light_add(type='POINT', location=(600, 3060, 2240)); hlamp = bpy.context.object; hlamp.name = 'hall_bulb'
hlamp.data.energy = (1.6e7 if TIME != 'day' else 0.0); hlamp.data.color = (1.0, 0.64, 0.36); hlamp.data.shadow_soft_size = 40

# ---------------------------------------------------------------- 4e. stair finish and the job's story props (arrival_jobs.json)
# Osiedle blocks have cast terrazzo flights instead of the tenement's oak treads (the kit's right-hand flight too).
TERR = bpy.data.materials.get('ph_terrazzo') or floor_m
if STAIR == 'terrazzo':
    for o in bpy.data.objects:
        if o.name.startswith(('a_tread', 'a_riser', 'floor_nosing', 'tread', 'riser')) and o.type == 'MESH':
            for sl in o.material_slots: sl.material = TERR

def floor_z(x, y):
    """Top of the walking surface under (x, y): landing 0, the arriving flight's treads below TOPY, the doormat."""
    if y < TOPY and FX0 < x < FX1:
        k = int((y - Y_BOT) // TREAD)
        return HALFZ if k < 0 else HALFZ + (k + 1) * RISE
    if -385 < x < 385 and -585 < y < -55: return 19.0       # coir mat (fibre tips ~29, the props settle in)
    return 0.0

def _scatter_mesh(name, items, mats):
    """items: (bmesh-maker, matrix, material index) -> one object; small loose things in one mesh keep the scene light."""
    bm = bmesh.new()
    for make, M, mi in items:
        ret = make(bm)
        bmesh.ops.transform(bm, matrix=M, verts=ret['verts'])
        for f in {f for v in ret['verts'] for f in v.link_faces}: f.material_index = mi
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    for m_ in mats: o.data.materials.append(m_)
    for p in o.data.polygons: p.use_smooth = True
    return o

def walk_path(t, rng_, spread):
    """A point near the walking line: top of the arriving flight -> round the newel -> the doormat."""
    p0, p1, p2 = Vector((-1130, -3300)), Vector((-950, -900)), Vector((-40, -330))
    q = p0 * (1 - t) ** 2 + p1 * 2 * t * (1 - t) + p2 * t * t
    return q.x + rng_.gauss(0, spread), q.y + rng_.gauss(0, spread * 0.7)

PRNG = random.Random(hash(JOB) & 0xffff)
envelope_cols = [(0.84, 0.82, 0.76), (0.80, 0.74, 0.58), (0.86, 0.85, 0.82), (0.70, 0.76, 0.80), (0.78, 0.70, 0.62)]

def envelope(name, M, col_i, size=(220, 110)):
    """A closed envelope: card slab with a shallow flap ridge (no print, no stamps with text)."""
    w, h = size
    m_ = paper('env_%d' % col_i, envelope_cols[col_i % len(envelope_cols)], fibre=1.2, seed=col_i, grime=0.25)
    e = slab(name, rounded_rect(w, h, 1.5), 0.6, m_, bev=0.2)
    flap = tube(name + '_flap', [(-w / 2 + 2, h / 2 - 2, 0.62), (0, h * 0.02, 0.62), (w / 2 - 2, h / 2 - 2, 0.62)], 0.35, m_, res=1, smooth_pts=False)
    for o in (e, flap): o.matrix_world = M @ o.matrix_world
    return e

def flyer(name, M, col, size=(148, 210)):
    """A folded takeaway/service flyer: two-tone print blocks (abstract, no text), slight fold."""
    m_ = paper('flyer_%s' % name, col, fibre=0.6, seed=len(name), grime=0.2, lines=(31.0, 'Y', tuple(c * 0.75 for c in col)))
    f = slab(name, rounded_rect(size[0], size[1], 0.8), 0.25, m_)
    f.matrix_world = M @ f.matrix_world
    return f

def P_gas_riser(c):
    """Grandma's broth: the gas riser on the landing, painted gas-yellow, quarter-turn valve with its lever across
    the pipe (shut by the neighbour). Clips into the wall, a short branch into the flat through the wall."""
    x = c.get('x', -880); vz = c.get('valve_z', 1180); y = -46
    yellow = paint('gas_yellow', (0.62, 0.42, 0.04), rough=0.42, metal_col=(0.35, 0.33, 0.30), chip=0.35, grime=0.8)
    red = paint('valve_red', (0.40, 0.03, 0.02), rough=0.38, metal_col=(0.4, 0.4, 0.4), chip=0.4, grime=0.5)
    brass_v = bpy.data.materials.get('ph_brass') or brass
    tube('gas_pipe_lo', [(x, y, -40), (x, y, vz - 48)], 16.5, yellow, res=4, smooth_pts=False)
    tube('gas_pipe_hi', [(x, y, vz + 48), (x, y, CEIL + 40)], 16.5, yellow, res=4, smooth_pts=False)
    for z in (420, 2050, 2900):
        tube('gas_clip', [(x - 22, -2, z), (x - 22, y, z), (x + 22, y, z), (x + 22, -2, z)], 2.6, black_iron, res=2, smooth_pts=False)
    body = cyl('gas_valve', 24, 70, (x, y, vz), axis='Z', verts=48); setmat(body, brass_v)
    for dz in (-42, 42):
        n_ = cyl('gas_valve_nut', 22, 14, (x, y, vz + dz), axis='Z', verts=6); setmat(n_, brass_v)
    st = cyl('gas_stem', 6, 22, (x, y - 30, vz), axis='Y', verts=24); setmat(st, steel)
    ang = 0.0 if c.get('closed', True) else 90.0     # lever across the pipe = closed
    lv = bx('gas_lever', -6, 112, -7, 7, -3, 3, red, bev=2.5)
    lv.location = (x, y - 42, vz); lv.rotation_euler = (math.radians(90), 0, 0); lv.rotation_euler.y = math.radians(ang + 8)
    tube('gas_branch', [(x, y, 2650), (x + 160, y, 2650), (x + 160, -2, 2650)], 11, yellow, res=3, smooth_pts=False)
    stain_decal('gas_grime', 'Y', -0.6, (x - 160, x + 160, vz - 260, vz + 220), [(x + 30, vz - 20, 90, 120, 0.4)],
                color=(0.05, 0.045, 0.03), rough=0.6, noise_scale=0.05)

def P_cat_bowl(c):
    """Cat at home: an enamel bowl with dry food on the hall runner."""
    x, y = c.get('at', (320, 1150))
    bowl_m = enamel('cat_bowl', (0.62, 0.66, 0.68), chip=0.4)
    b_ = lathe('cat_bowl', [(0.1, 6), (52, 6), (62, 10), (78, 44), (82, 47), (76, 48), (60, 18), (0.1, 16)], x, y, seg=64)
    setmat(b_, bowl_m)
    food = plastic('cat_food', (0.20, 0.10, 0.045), rough=0.6, seed=3, grime=0.2, sheen_scuffs=0.0)
    items = []
    for i in range(70):
        a = PRNG.uniform(0, 6.283); r = 58 * math.sqrt(PRNG.random())
        M = Matrix.Translation((x + r * math.cos(a), y + r * math.sin(a), 20 + PRNG.uniform(0, 9))) @ Matrix.Diagonal((5.5, 5.5, 3.5, 1))
        items.append((lambda bm: bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0), M, 0))
    _scatter_mesh('cat_food', items, [food])

def P_toy_mouse(c):
    """A felt toy mouse dropped in the hall, tail curled."""
    x, y, rot = c.get('at', (80, 820, 28))
    felt = plastic('felt_grey', (0.30, 0.29, 0.27), rough=0.95, seed=5, grime=0.3, sheen_scuffs=0.0)
    M = Matrix.Translation((x, y, 9)) @ Matrix.Rotation(math.radians(rot), 4, 'Z')
    body = _scatter_mesh('toy_mouse', [(lambda bm: bmesh.ops.create_uvsphere(bm, u_segments=24, v_segments=14, radius=1.0),
                                        M @ Matrix.Diagonal((30, 14, 12, 1)), 0)] +
                         [(lambda bm: bmesh.ops.create_uvsphere(bm, u_segments=12, v_segments=8, radius=1.0),
                           M @ Matrix.Translation((22, s * 9, 9)) @ Matrix.Diagonal((2.5, 6, 6, 1)), 0) for s in (-1, 1)], [felt])
    tail = [M @ Vector(p) for p in ((-28, 0, 2), (-55, 8, 1), (-75, -4, 1), (-90, -18, 1))]
    tube('toy_tail', [tuple(p) for p in tail], 1.6, plastic('tail_cord', (0.55, 0.45, 0.40), rough=0.8), res=2)

def P_drill_dust(c):
    """The new deadbolt went in days ago: fine drill dust and a few chips on the floor under it, by the threshold."""
    wood_dust = plastic('drill_dust', (0.82, 0.72, 0.55), rough=0.9, seed=7, grime=0.0, sheen_scuffs=0.0)
    paint_dust = plastic('paint_dust', (0.85, 0.83, 0.78), rough=0.9, seed=8, grime=0.0, sheen_scuffs=0.0)
    items = []
    for i in range(2600):
        x = HX + 15 + PRNG.gauss(0, 40); y = -14 - abs(PRNG.gauss(0, 55))
        if PRNG.random() < 0.15: x += PRNG.gauss(0, 70); y -= abs(PRNG.gauss(0, 60))
        s_ = PRNG.uniform(0.9, 2.4) if PRNG.random() > 0.08 else PRNG.uniform(3.0, 6.0)
        M = Matrix.Translation((x, y, s_ * 0.3)) @ Matrix.Rotation(PRNG.uniform(0, 6.3), 4, 'Z') @ Matrix.Diagonal((s_, s_ * 0.7, s_ * 0.35, 1))
        items.append((lambda bm: bmesh.ops.create_icosphere(bm, subdivisions=0, radius=1.0), M, 0 if PRNG.random() < 0.8 else 1))
    for i in range(60):   # a few grains caught on the threshold edge
        M = Matrix.Translation((HX - 30 + PRNG.gauss(0, 30), PRNG.uniform(-20, 40), 20.3)) @ Matrix.Diagonal((0.9, 0.7, 0.3, 1))
        items.append((lambda bm: bmesh.ops.create_icosphere(bm, subdivisions=0, radius=1.0), M, 0))
    _scatter_mesh('drill_dust', items, [wood_dust, paint_dust])

def P_cake_box(c):
    """Wedding cake in a white card box on the doormat: lid over base, satin ribbon both ways with a bow."""
    x, y = c.get('at', (-60, -300)); z0 = floor_z(x, y); yaw = math.radians(c.get('yaw', 9))
    card = paper('cake_card', (0.86, 0.85, 0.81), fibre=0.8, seed=6, grime=0.18)
    satin = plastic('cake_ribbon', (0.78, 0.66, 0.46), rough=0.22, seed=2, grime=0.1, sheen_scuffs=0.0)
    W, H = 300, 135
    M = Matrix.Translation((x, y, z0)) @ Matrix.Rotation(yaw, 4, 'Z')
    parts = [bx('cake_base', -W / 2, W / 2, -W / 2, W / 2, 0, H - 30, card, bev=1.2),
             bx('cake_lid', -W / 2 - 4, W / 2 + 4, -W / 2 - 4, W / 2 + 4, H - 48, H, card, bev=1.5),
             bx('cake_rib_x', -W / 2 - 5, W / 2 + 5, -11, 11, H - 1, H + 0.8, satin),
             bx('cake_rib_y', -11, 11, -W / 2 - 5, W / 2 + 5, H - 0.5, H + 1.2, satin),
             bx('cake_rib_xs', -W / 2 - 5.5, -W / 2 - 4.2, -11, 11, H - 48, H, satin), bx('cake_rib_xs2', W / 2 + 4.2, W / 2 + 5.5, -11, 11, H - 48, H, satin),
             bx('cake_rib_ys', -11, 11, -W / 2 - 5.5, -W / 2 - 4.2, H - 48, H, satin), bx('cake_rib_ys2', -11, 11, W / 2 + 4.2, W / 2 + 5.5, H - 48, H, satin)]
    for sx in (-1, 1):   # bow loops and tails
        parts.append(tube('cake_bow', [(0, 0, H + 2), (sx * 40, -14, H + 16), (sx * 58, 6, H + 8), (0, 0, H + 3)], 7, satin, res=2))
        parts.append(tube('cake_tail', [(0, 0, H + 2), (sx * 22, 30, H + 1.5), (sx * 34, 70, H + 1.2)], 6, satin, res=2))
    for o in parts:
        o.matrix_world = M @ o.matrix_world
        if o.type == 'CURVE': o.data.bevel_resolution = 2

def P_petals(c):
    """Rose petals and a few leaves dropped from the bouquet, thickest by the door, thinning down the stairs."""
    reds = [plastic('petal_red', (0.36, 0.02, 0.035), rough=0.45, seed=1, grime=0.05, sheen_scuffs=0.0),
            plastic('petal_ivory', (0.80, 0.74, 0.62), rough=0.45, seed=2, grime=0.05, sheen_scuffs=0.0),
            plastic('petal_leaf', (0.08, 0.13, 0.05), rough=0.5, seed=3, grime=0.05, sheen_scuffs=0.0)]
    for m_ in reds[:2]:
        b_ = m_.node_tree.nodes['Principled BSDF']; b_.inputs['Subsurface Weight'].default_value = 0.25
        b_.inputs['Sheen Weight'].default_value = 0.3
    items = []
    def petal_maker(bm):
        ret = bmesh.ops.create_circle(bm, cap_ends=True, segments=12, radius=1.0)
        for v in ret['verts']: v.co.z = 0.18 * (v.co.x ** 2 + 0.4 * v.co.y ** 2)
        return ret
    for i in range(int(c.get('n', 70))):
        t = PRNG.random() ** 0.55
        x, y = walk_path(t, PRNG, 120 + 160 * (1 - t))
        L = PRNG.uniform(18, 30); k = 0 if PRNG.random() < 0.7 else (1 if PRNG.random() < 0.75 else 2)
        if k == 2: L *= 1.4
        z = floor_z(x, y) + 0.6
        M = (Matrix.Translation((x, y, z)) @ Matrix.Rotation(PRNG.uniform(0, 6.3), 4, 'Z') @
             Matrix.Rotation(PRNG.uniform(-0.25, 0.25), 4, 'X') @ Matrix.Diagonal((L, L * (0.75 if k < 2 else 0.4), L * 0.6, 1)))
        items.append((petal_maker, M, k))
    _scatter_mesh('petals', items, reds)

def P_rice(c):
    """Rice thrown at the church, shaken out of hair and lapels on the way up: grains along the path and on the mat."""
    rice_m = plastic('rice', (0.80, 0.78, 0.70), rough=0.35, seed=4, grime=0.0, sheen_scuffs=0.0)
    rice_m.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value = 0.4
    items = []
    for i in range(int(c.get('n', 900))):
        t = PRNG.random() ** 0.4
        x, y = walk_path(t, PRNG, 90 + 200 * (1 - t))
        z = floor_z(x, y) + 1.0
        M = Matrix.Translation((x, y, z)) @ Matrix.Rotation(PRNG.uniform(0, 6.3), 4, 'Z') @ Matrix.Diagonal((3.3, 1.3, 1.1, 1))
        items.append((lambda bm: bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0), M, 0))
    _scatter_mesh('rice', items, [rice_m])

def P_post_pile(c):
    """Nobody home for weeks: letters and flyers on the mat, one pushed under the door, more in the door gap."""
    cols = [(0.46, 0.20, 0.13), (0.20, 0.27, 0.34), (0.62, 0.52, 0.28), (0.30, 0.36, 0.26)]   # muted print, no text
    k = 0
    for i in range(7):   # letters fanned on the mat in front of the door, some overlapping
        x = PRNG.uniform(-220, 230); y = PRNG.uniform(-330, -110)
        M = Matrix.Translation((x, y, floor_z(x, y) + 2 + i * 0.7)) @ Matrix.Rotation(PRNG.uniform(-0.9, 0.9), 4, 'Z')
        envelope('post_env%d' % i, M, i, size=(220, 110) if i % 3 else (162, 114)); k += 1
    for i in range(4):
        x = PRNG.uniform(-240, 240); y = PRNG.uniform(-420, -120)
        M = Matrix.Translation((x, y, floor_z(x, y) + 6 + i * 0.6)) @ Matrix.Rotation(PRNG.uniform(-1.2, 1.2), 4, 'Z')
        flyer('post_fly%d' % i, M, cols[i % len(cols)])
    # half pushed under the leaf (the gap over the threshold)
    M = Matrix.Translation((80, -10, 20.5)) @ Matrix.Rotation(math.radians(6), 4, 'Z')
    envelope('post_under', M, 2, size=(220, 110))
    for i, (z, r) in enumerate(((880, -12), (1420, 9))):   # flyers wedged in the gap on the lock side
        M = Matrix.Translation((LX1 + 1.5, 16, z)) @ Matrix.Rotation(math.radians(78), 4, 'Z') @ Matrix.Rotation(math.radians(r), 4, 'Y') @ \
            Matrix.Rotation(math.radians(90), 4, 'X')
        flyer('gap_fly%d' % i, M, cols[(i + 1) % len(cols)], size=(100, 150))

def P_obituary(c):
    """Uncle Bogdan's death notice (klepsydra) taped to the landing wall: white card, black border, a small cross,
    the name and the funeral lines as unreadable grey bars (no text)."""
    x0, z0 = c.get('at', (548, 1330)); W, H = c.get('size', (230, 165))
    card = paper('obit_card', (0.84, 0.83, 0.79), fibre=0.8, seed=12, grime=0.12)
    ink = plastic('obit_ink', (0.015, 0.015, 0.015), rough=0.6, grime=0.0, sheen_scuffs=0.0)
    grey = plastic('obit_print', (0.18, 0.18, 0.18), rough=0.6, grime=0.0, sheen_scuffs=0.0)
    y = -1.2; tilt = math.radians(c.get('tilt', -1.5))
    parts = [bx('obit', 0, W, y - 0.4, y, 0, H, card)]
    b = 9
    for (a, b_, cc, d) in ((0, W, 0, b), (0, W, H - b, H), (0, b, 0, H), (W - b, W, 0, H)):
        parts.append(bx('obit_border', a, b_, y - 0.6, y - 0.4, cc, d, ink))
    cx = W / 2
    parts.append(bx('obit_cross_v', cx - 1.6, cx + 1.6, y - 0.6, y - 0.4, H - 38, H - 16, ink))
    parts.append(bx('obit_cross_h', cx - 6, cx + 6, y - 0.6, y - 0.4, H - 25, H - 22, ink))
    for (w, z, h) in ((150, H - 62, 11), (110, H - 80, 4), (170, 58, 3.5), (160, 48, 3.5), (120, 38, 3.5), (90, 24, 3)):
        parts.append(bx('obit_line', cx - w / 2, cx + w / 2, y - 0.6, y - 0.4, z, z + h, ink if h > 8 else grey))
    tape = plastic('obit_tape', (0.80, 0.78, 0.70), rough=0.25, grime=0.1)
    tape.node_tree.nodes['Principled BSDF'].inputs['Transmission Weight'].default_value = 0.5
    for (tx, tz, a) in ((8, H - 6, 35), (W - 8, H - 6, -35)):
        t_ = bx('obit_tape', -24, 24, y - 1.0, y - 0.6, -8, 8, tape); t_.location = (tx, 0, tz); t_.rotation_euler.y = math.radians(a)
        parts.append(t_)
    M = Matrix.Translation((x0, 0, z0)) @ Matrix.Rotation(tilt, 4, 'Y')
    for o in parts:
        o.matrix_world = M @ o.matrix_world


def P_suitcase(c):
    """A wheeled suitcase standing in the hall, handle still up: one of the heirs came straight from the train."""
    x, y = c.get('at', (700, 1000)); yaw = math.radians(c.get('yaw', -20))
    shell = plastic('case_shell', tuple(c.get('color', (0.04, 0.06, 0.10))), rough=0.35, seed=3, grime=0.4, sheen_scuffs=0.4)
    alu_h = metal('case_handle', (0.55, 0.55, 0.54), 0.3, marks='grind', marks_axis=(0, 0, 1), wear=0.3, grime=0.4)
    W, D, H = 420, 250, 640
    parts = [bx('case', -W / 2, W / 2, -D / 2, D / 2, 60, 60 + H, shell, bev=40, seg=4)]
    for k in range(-2, 3):   # moulded ribs
        parts.append(bx('case_rib', k * 70 - 8, k * 70 + 8, -D / 2 - 3, -D / 2 + 2, 120, H, shell, bev=4))
    for sx in (-1, 1):
        parts.append(tube('case_tube', [(sx * 90, D / 2 - 20, 60 + H), (sx * 90, D / 2 - 20, 60 + H + 420)], 9, alu_h, smooth_pts=False))
        parts.append(cyl('case_wheel', 30, 26, (sx * (W / 2 - 50), D / 2 - 50, 30), axis='X', verts=24))
        parts[-1].data.materials.append(rubber('case_wheel_r'))
    parts.append(bx('case_grip', -110, 110, D / 2 - 40, D / 2, 60 + H + 400, 60 + H + 440, plastic('case_grip_p', (0.03, 0.03, 0.03), rough=0.5), bev=8))
    M = Matrix.Translation((x, y, 0)) @ Matrix.Rotation(yaw, 4, 'Z')
    for o in parts:
        o.matrix_world = M @ o.matrix_world


def P_shoes(c):
    """Shoes taken off inside the door, as one does: pairs on the hall floor (men's leather, a pair of boots)."""
    shoe_ms = [plastic('shoe_leather%d' % i, col, rough=0.35, seed=i, grime=0.3, sheen_scuffs=0.4) for i, col in
               enumerate(((0.035, 0.022, 0.014), (0.012, 0.012, 0.012), (0.10, 0.055, 0.03)))]
    sole = rubber('shoe_sole', (0.06, 0.05, 0.045), 0.7)
    for k, (x, y, a, size) in enumerate(c.get('pairs', ((-260, 520, 12, 1.0), (60, 470, -8, 1.05)))):
        for s_ in (-1, 1):
            M = Matrix.Translation((x + s_ * 62, y + PRNG.uniform(-20, 20), 0)) @ Matrix.Rotation(math.radians(a + 90 + PRNG.uniform(-6, 6)), 4, 'Z') @ Matrix.Diagonal((size, size, size, 1))
            m_ = shoe_ms[k % len(shoe_ms)]
            parts = [bx('shoe_sole', -140, 140, -48, 48, 0, 22, sole, bev=10), bx('shoe_upper', -130, 50, -44, 44, 18, 105, m_, bev=32),
                     bx('shoe_toe', 30, 136, -42, 42, 18, 62, m_, bev=26), bx('shoe_heel', -140, -80, -44, 44, 0, 34, sole, bev=6)]
            for o in parts:
                o.matrix_world = M @ o.matrix_world

def P_scooter(c):
    """Hania's kick scooter left on the landing: deck with grip tape, two small wheels, the T-bar, a ribbon on the grip."""
    x, y = c.get('at', (-640, -420)); yaw = math.radians(c.get('yaw', 70)); lean = math.radians(c.get('lean', 0))
    frame_p = paint('scooter_paint', tuple(c.get('color', (0.55, 0.12, 0.25))), rough=0.3, metal_col=(0.6, 0.6, 0.6), chip=0.4, grime=0.5)
    alu = metal('scooter_alu', (0.66, 0.66, 0.65), 0.3, marks='grind', marks_axis=(0, 0, 1), wear=0.4, grime=0.5)
    grip = plastic('grip_tape', (0.03, 0.03, 0.03), rough=0.9, seed=2, grime=0.6, sheen_scuffs=0.0)
    wheel = plastic('scooter_wheel', (0.75, 0.70, 0.55), rough=0.4, seed=3, grime=0.6)
    parts = [bx('deck', -260, 260, -55, 55, 70, 95, frame_p, bev=10), bx('deck_grip', -240, 240, -48, 48, 95, 96.5, grip)]
    for wx in (-320, 300):
        w = cyl('sc_wheel', 60, 24, (wx, 0, 60), axis='Y', verts=32); setmat(w, wheel); parts.append(w)
        parts.append(cyl('sc_hub', 18, 30, (wx, 0, 60), axis='Y', verts=16)); parts[-1].data.materials.append(alu)
    parts.append(tube('sc_fork', [(300, 0, 60), (300, 0, 150), (290, 0, 220)], 14, frame_p, smooth_pts=False))
    parts.append(tube('sc_stem', [(290, 0, 220), (270, 0, 760)], 15, alu, smooth_pts=False))
    parts.append(tube('sc_bar', [(270, -230, 770), (270, 230, 770)], 13, alu, smooth_pts=False))
    for s_ in (-1, 1):
        parts.append(tube('sc_handgrip', [(270, s_ * 120, 770), (270, s_ * 235, 770)], 17, plastic('sc_grip_p', (0.80, 0.30, 0.45), rough=0.6, seed=4), smooth_pts=False))
    parts.append(tube('sc_ribbon', [(270, 236, 770), (265, 245, 720), (275, 250, 660), (262, 258, 610)], 3, plastic('ribbon', (0.85, 0.80, 0.30), rough=0.4), res=2))
    parts.append(bx('sc_rear_guard', -360, -250, -40, 40, 112, 120, frame_p, bev=3))
    M = Matrix.Translation((x, y, 0)) @ Matrix.Rotation(yaw, 4, 'Z') @ Matrix.Rotation(lean, 4, 'X')
    for o in parts:
        o.matrix_world = M @ o.matrix_world


def P_plank(c):
    """Tomasz's oak board for the new wooden key, leaning by the door, and a few curls of shaving on the mat."""
    x = c.get('x', 640); W = c.get('w', 150); L = c.get('len', 1150)
    board = oak('key_plank', light=(0.62, 0.46, 0.28), dark=(0.40, 0.27, 0.13), axis='Z', seed=101, ring=2.0, coat=0.0, rough=0.7, wear=0.2, grime=0.2)
    p_ = bx('plank', -W / 2, W / 2, -12, 12, 0, L, board, bev=1.5)
    p_.matrix_world = Matrix.Translation((x, -70, 0)) @ Matrix.Rotation(math.radians(-8), 4, 'X') @ Matrix.Rotation(math.radians(4), 4, 'Y')
    shav = plastic('shaving', (0.78, 0.62, 0.40), rough=0.6, seed=6, grime=0.0, sheen_scuffs=0.0)
    shav.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value = 0.3
    for i in range(int(c.get('shavings', 0))):   # 0: curls read as letters at this distance (D-105)
        cx, cy = PRNG.uniform(-300, 300) * 0.6 + x * 0.25, PRNG.uniform(-420, -120); r = PRNG.uniform(5, 9); a0 = PRNG.uniform(0, 6.3)
        pts = [(cx + r * (1 + 0.25 * t) * math.cos(a0 + t), cy + 2.5 * t, floor_z(cx, cy) + r * 1.2 + r * (1 + 0.25 * t) * math.sin(a0 + t)) for t in [k * 0.4 for k in range(22)]]
        o = tube('shaving', pts, 0.0, shav, res=1)
        o.data.bevel_depth = 0.0; o.data.extrude = PRNG.uniform(3.5, 6.0); o.data.use_fill_caps = False   # a thin ribbon, not a wire

def P_book_stack(c):
    """Mrs Irena sorts her late husband's books: two stacks tied with twine by the door, for the library sale."""
    x0, y0 = c.get('at', (-650, -260))
    cols = [(0.22, 0.06, 0.05), (0.08, 0.12, 0.09), (0.32, 0.24, 0.13), (0.06, 0.07, 0.11), (0.45, 0.38, 0.26), (0.14, 0.08, 0.05)]
    mats = [plastic('book_cloth%d' % i, col, rough=0.6, seed=i, grime=0.4, sheen_scuffs=0.2) for i, col in enumerate(cols)]
    pages = paper('book_pages', (0.78, 0.74, 0.62), fibre=1.0, seed=7, grime=0.3)
    twine = plastic('book_twine', (0.55, 0.45, 0.30), rough=0.9, grime=0.2, sheen_scuffs=0.0)
    for s, (dx, dy, n) in enumerate(((0, 0, 7), (300, 40, 5))):
        z = 0.0
        for i in range(n):
            w = PRNG.uniform(150, 210); d = PRNG.uniform(220, 280); h = PRNG.uniform(22, 48); a = math.radians(PRNG.uniform(-7, 7))
            M = Matrix.Translation((x0 + dx, y0 + dy, z)) @ Matrix.Rotation(a, 4, 'Z')
            for o in (bx('book', -w / 2, w / 2, -d / 2, d / 2, 0, h, mats[PRNG.randrange(len(mats))], bev=2),
                      bx('book_pages', -w / 2 + 6, w / 2 + 1, -d / 2 + 4, d / 2 - 4, 3, h - 3, pages)):
                o.matrix_world = M @ o.matrix_world
            z += h
        cx, cy = x0 + dx, y0 + dy
        tube('twine_a', [(cx - 115, cy, -1), (cx - 115, cy, z + 2), (cx + 115, cy, z + 2), (cx + 115, cy, -1)], 1.4, twine, smooth_pts=False)
        tube('twine_b', [(cx, cy - 145, -1), (cx, cy - 145, z + 3), (cx, cy + 145, z + 3), (cx, cy + 145, -1)], 1.4, twine, smooth_pts=False)
        tube('twine_knot', [(cx - 8, cy - 4, z + 3), (cx + 12, cy - 14, z + 9), (cx + 26, cy - 34, z + 4)], 1.6, twine)

PROPS = {'gas_riser': P_gas_riser, 'cat_bowl': P_cat_bowl, 'toy_mouse': P_toy_mouse, 'drill_dust': P_drill_dust,
         'cake_box': P_cake_box, 'petals': P_petals, 'rice': P_rice, 'post_pile': P_post_pile,
         'obituary': P_obituary, 'suitcase': P_suitcase, 'shoes': P_shoes,   # D-105: job.uncle_safe_heirs
         'scooter': P_scooter, 'plank': P_plank,
         'book_stack': P_book_stack}   # D-105: job.widow_bureau       # D-105: job.dollhouse_wooden_lock
# mailbox: a letter sticking out of the slot (grandma: "the letter in the mailbox is addressed to you"),
# or stuffed full (nobody has emptied it for weeks)
mb_items = 1 if MAILBOX.get('letter_out') else (5 if MAILBOX.get('overflow') else 0)
for i in range(mb_items):
    out = 85 + 20 * (i % 3); tilt = 38 - 7 * (i % 4) + 4 * (i // 4); dx = (i - 2) * 9 if i else 0   # drooping out of the slot
    M = (Matrix.Translation(((MBX0 + MBX1) / 2 + dx, -84, MBZ1 - 46 + 2 * i)) @ Matrix.Rotation(math.radians(tilt), 4, 'X') @
         Matrix.Translation((0, -(out - 60) / 2, 0)) @ Matrix.Rotation(math.radians(PRNG.uniform(-6, 6)), 4, 'Z') @ Matrix.Rotation(math.radians(90), 4, 'Z'))
    envelope('mb_letter%d' % i, M, i + 1, size=(out + 60, 98 - 6 * (i % 2)))
if MAILBOX.get('overflow'):
    x, y = MBX0 + 40, -170
    envelope('mb_fallen', Matrix.Translation((x, y, 0.4)) @ Matrix.Rotation(math.radians(24), 4, 'Z'), 4)
for pc in PROPS_CFG:
    if pc['type'] not in PROPS: sys.exit('arrival_scene: unknown prop %s' % pc['type'])
    PROPS[pc['type']](pc)
for m_ in bpy.data.materials:   # decals added by the props: no specular sheen either
    if m_.use_nodes and any(n.type == 'BSDF_TRANSPARENT' for n in m_.node_tree.nodes) and 'Principled BSDF' in m_.node_tree.nodes:
        m_.node_tree.nodes['Principled BSDF'].inputs['Specular IOR Level'].default_value = 0.0

# ---------------------------------------------------------------- 4d. the courtyard behind the stair window
# limewashed brick of the next wing across the yard, its windows (a few lit at night), a strip of sky above
ribbed.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value = 0.07   # old clear glass, slight waviness
CY = WT + 5200
court = bx('court_wall', -9000, 1500, CY, CY + 300, -6000, 6600, brick_wall('court_brick', brick=(0.40, 0.22, 0.14), wash=(0.62, 0.60, 0.55), wash_amt=0.55, seed=4))
win_dark = glass('court_glass', (0.25, 0.27, 0.28), rough=0.05)
lit = emissive('court_lit', (1.0, 0.66, 0.35), 0.9 if TIME == 'night' else (1.2 if TIME == 'evening' else 0.0), (0.05, 0.05, 0.05))
crng = random.Random(J.get('court_seed', 21))
for ix, x in enumerate(range(-6200, 1200, 1500)):
    for iz, z in enumerate((-3800, -400, 3000)):
        m_ = lit if (TIME != 'day' and crng.random() < 0.3) else win_dark
        bx('cw_frame', x - 20, x + 920, CY - 60, CY, z - 20, z + 1520, oil_paint('cw_paint', (0.55, 0.52, 0.45), rough=0.4, seed=ix), bev=4)
        bx('cw_glass', x + 40, x + 860, CY - 70, CY - 40, z + 40, z + 1460, m_)
        bx('cw_sill', x - 60, x + 960, CY - 140, CY, z - 60, z, oil_paint('cw_sill', (0.30, 0.29, 0.27), rough=0.6, seed=ix))
drop('w_sky')
if TIME != 'day':   # the yard at night: a sodium lamp low on the far wall grazes the brick, the sky lifts the top
    ay = bpy.data.objects.new('aim_court', None); scene.collection.objects.link(ay); ay.location = (-2500, CY, 2500)
    area_light('court_lamp', (-1200, CY - 2500, -2500), ay, 600, (1.2e8 if TIME == 'night' else 5e7), (1.0, 0.55, 0.25))
SKY = {'night': ((0.06, 0.09, 0.20), 0.25), 'evening': ((0.18, 0.28, 0.70), 1.2), 'day': ((0.80, 0.86, 0.96), 4.0)}[TIME]
sky = bx('w_sky', -9000, 3000, CY + 8000, CY + 8020, -6000, 30000, emissive('sky2', SKY[0], SKY[1], (0, 0, 0))); sky.visible_shadow = False

# ---------------------------------------------------------------- 5. lighting by time of day
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (-1100, -3600, 0)
AIM2 = bpy.data.objects.new('aim2', None); scene.collection.objects.link(AIM2); AIM2.location = (0, 1200, 0)
WARM = (1.0, 0.66, 0.38)                       # ~2700 K incandescent behind opal glass
L = {   # time: bulb W, window W, window colour, world, interior W, exposure, glow
    'night':   (5.0e7, 6.0e7, (0.50, 0.62, 1.00), 0.004, 1.2e7, -0.2, 2.2),
    'evening': (4.5e7, 1.1e8, (0.45, 0.58, 1.00), 0.010, 6.0e6, -0.2, 2.0),
    'day':     (0.0,   2.5e8, (0.85, 0.92, 1.00), 0.050, 0.0,    0.1, 0.0),
}[TIME]
BULB_W, WIN_W, WIN_C, WORLD, IN_W, EXPO, GLOW = L
world_hdri(WORLD, 'interior.exr', sat=0.3)
setmat(bpy.data.objects['globe'], opal_glass('opal_' + TIME, glow=GLOW))
bpy.data.objects['globe'].visible_shadow = False
if BULB_W:
    bpy.ops.object.light_add(type='POINT', location=tuple(G)); bulb = bpy.context.object; bulb.name = 'bulb'
    bulb.data.shadow_soft_size = 35; bulb.data.energy = BULB_W; bulb.data.color = WARM
    bpy.data.materials['indicator'].node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 0.4
AIMW = bpy.data.objects.new('aimw', None); scene.collection.objects.link(AIMW); AIMW.location = ((WIN[0] + WIN[1]) / 2 + 300, -2000, 0)
win_light = area_light('window_light', ((WIN[0] + WIN[1]) / 2, WT + 600, (WIN[2] + WIN[3]) / 2 + 300), AIMW,
                       WIN[1] - WIN[0], WIN_W, WIN_C, size_y=WIN[3] - WIN[2])
win_light.visible_camera = False; win_light.visible_glossy = False; win_light.visible_transmission = False   # the glass shows the sky plane, not the lamp
if TIME == 'day':   # low sun over the courtyard roofs: a hard patch through the window onto the landing
    bpy.ops.object.light_add(type='SUN'); sun = bpy.context.object; sun.name = 'sun'
    d = Vector((0.55, -1.0, -2.2)).normalized()
    sun.rotation_euler = (-d).to_track_quat('Z', 'Y').to_euler()
    sun.data.energy = 6.0; sun.data.color = (1.0, 0.90, 0.74); sun.data.angle = math.radians(0.6)
if TIME == 'day':   # skylight bouncing down the stairwell from above the right-hand flight
    area_light('skylight', (1300, -2600, CEIL - 50), AIM2, 1600, 6e7, (0.92, 0.95, 1.0), size_y=2400)
if IN_W:   # a lamp left on in the flat: leaks under the door / through the gap and the peephole
    fl_ = area_light('flat_lamp', (0, 1600, 2700), AIM2, 600, IN_W * (3.0 if DOOR == 'ajar' else 1.0), (1.0, 0.70, 0.42))
    if JOB != 'wrong_floor':   # a fill, not a fixture: never seen directly or as a highlight (it showed as a pale disc in the doorway)
        fl_.visible_camera = False; fl_.visible_glossy = False

# ---------------------------------------------------------------- 6. camera: up the last steps, onto the landing
cam = photo_camera((0, 0, 0), lens=22.0)
cam.data.sensor_fit = 'VERTICAL'; cam.data.sensor_height = 36.0; cam.data.sensor_width = 36.0
EYE = 1590
CAM_END = Vector(CAMC.get('end', (-170, -2560, EYE - 10))); END_YAW, END_PITCH = CAMC.get('end_yaw', 1.5), CAMC.get('end_pitch', 0.0)
END_SHIFT = tuple(CAMC.get('end_shift', (0.0, -0.105)))
KEYS = [  # (t, x, y, yaw, pitch)
    (0.00, -1150, TOPY - 6.4 * TREAD, -6.0, -6.0),
    (0.35, -1120, TOPY - 3.6 * TREAD, -7.0, -2.0),
    (0.72, -930, TOPY - 0.6 * TREAD, -4.0, 0.0),
    (1.00, CAM_END.x, CAM_END.y, END_YAW, END_PITCH),
]
def ease(t): return t * t * (3 - 2 * t) if t < 1 else 1.0
def ease_walk(t):   # starts already walking, slows to a stop: cubic with initial slope 0.8
    return 0.8 * t + 1.4 * t * t - 1.2 * t * t * t
def catmull(p0, p1, p2, p3, u):
    return 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u ** 3)
def cam_at(t):
    s = ease_walk(t)
    ks = KEYS
    i = max(j for j in range(len(ks) - 1) if ks[j][0] <= s) if s < 1 else len(ks) - 2
    u = (s - ks[i][0]) / (ks[i + 1][0] - ks[i][0])
    P = [ks[max(0, min(len(ks) - 1, j))] for j in (i - 1, i, i + 1, i + 2)]
    val = [catmull(*[p[c] for p in P], u) for c in range(1, 5)]
    x, y, yaw, pitch = val
    z = stair_z(min(y, TOPY + 1)) + EYE + (CAM_END.z - EYE) * ease(max(0, (s - 0.7) / 0.3))
    # footfalls: a 14 mm dip and 0.5 deg roll per step, fading as we stop
    ph = (y - KEYS[0][2]) / TREAD; fade = 1 - ease(max(0, (s - 0.75) / 0.25))
    z -= 14 * fade * (0.5 - 0.5 * math.cos(2 * math.pi * ph)); roll = 0.5 * fade * math.sin(math.pi * ph)
    sh = ease(max(0, (s - 0.45) / 0.55))
    return Vector((x, y, z)), yaw, pitch, roll, (END_SHIFT[0] * sh, END_SHIFT[1] * sh)
scene.render.fps = FPS; scene.frame_start = 1; scene.frame_end = FRAMES
for f in range(1, FRAMES + 1):
    t = (f - 1) / (FRAMES - 1)
    p, yaw, pitch, roll, sh = cam_at(t)
    cam.location = p; cam.rotation_euler = (math.radians(90 + pitch), math.radians(roll), math.radians(yaw))
    cam.data.shift_x, cam.data.shift_y = sh
    cam.keyframe_insert('location', frame=f); cam.keyframe_insert('rotation_euler', frame=f)
    cam.data.keyframe_insert('shift_x', frame=f); cam.data.keyframe_insert('shift_y', frame=f)
for fc in list(cam.animation_data.action.fcurves) + list(cam.data.animation_data.action.fcurves):
    for kp in fc.keyframe_points: kp.interpolation = 'LINEAR'

# ---------------------------------------------------------------- 7. figure slots (D-41 style anchors)
# name: feet centre on the floor, nominal height (mm); speaker id from CLIENTS.md (arrival_jobs.json `slots`).
# wrong_floor/teresa (G23, 2026-11-06): behind the ajar leaf, peeking through the gap between the leaf's free edge
# (~262, 600) and the right jamb; (250, 420) stood in front of the leaf's swing. Holds rendered before this keep the
# old slot in their JSON: arrival_composite.py --feet-world teresa=560,720 re-projects it.
# Jobs without a full-body cut-out have no slots: their hold is the empty landing (plate only).
SLOTS = {k: dict(v, feet=tuple(v['feet'])) for k, v in J.get('slots', {}).items()}
def light_info(at):
    """Key/fill lights as seen from a point: colour, relative strength at the point, 3D and image-space direction."""
    out = []
    bpy.context.view_layer.update()
    for o in bpy.data.objects:
        if o.type != 'LIGHT' or o.data.energy <= 0: continue
        lp = o.matrix_world.translation; d = Vector(lp) - Vector(at); dist = d.length
        e = o.data.energy / (dist * dist) if o.data.type == 'POINT' else o.data.energy / (dist * dist) * 0.5
        a, b = project([at, Vector(at) + d.normalized() * 300])
        out.append({'name': o.name, 'type': o.data.type, 'color_linear': [round(c, 4) for c in o.data.color],
                    'strength_rel': e, 'dir3d_to_light': [round(c, 4) for c in d.normalized()],
                    'dir2d_to_light': [round(b[0] - a[0], 5), round(b[1] - a[1], 5)],
                    'elevation_deg': round(math.degrees(math.asin(max(-1, min(1, d.normalized().z)))), 1)})
    mx = max([l['strength_rel'] for l in out] or [1])
    for l in out: l['strength_rel'] = round(l['strength_rel'] / mx, 4)
    return sorted(out, key=lambda l: -l['strength_rel'])

def anchors(path, res):
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.frame_set(FRAMES)
    A = {
        'namecard': [(NP[0] - NPW / 2 + 7, FACE - 1, NPZ + NPH / 2 - 6), (NP[0] + NPW / 2 - 7, FACE - 1, NPZ + NPH / 2 - 6),
                     (NP[0] + NPW / 2 - 7, FACE - 1, NPZ - NPH / 2 + 6), (NP[0] - NPW / 2 + 7, FACE - 1, NPZ - NPH / 2 + 6)],
        'mailbox_card': [(MC[0] - MCW / 2, -84, MC[1] + MCH / 2), (MC[0] + MCW / 2, -84, MC[1] + MCH / 2),
                         (MC[0] + MCW / 2, -84, MC[1] - MCH / 2), (MC[0] - MCW / 2, -84, MC[1] - MCH / 2)],
        'number_plate': [(EP[0] - PW / 2, FACE - 3, EP[2] + PH / 2), (EP[0] + PW / 2, FACE - 3, EP[2] + PH / 2),
                         (EP[0] + PW / 2, FACE - 3, EP[2] - PH / 2), (EP[0] - PW / 2, FACE - 3, EP[2] - PH / 2)],
        'door': [(LX0, FACE, LZ1), (LX1, FACE, LZ1), (LX1, FACE, LZ0), (LX0, FACE, LZ0)],
        'cylinder': [(HX - 60, FACE - 20, HZ + 60), (HX + 40, FACE - 20, HZ + 60), (HX + 40, FACE - 20, HZ - 132), (HX - 60, FACE - 20, HZ - 132)],
    }
    if WREATH:
        A['wreath'] = [(WC.x - WR - Wr, WC.y, WC.z + WR + Wr), (WC.x + WR + Wr, WC.y, WC.z + WR + Wr),
                       (WC.x + WR + Wr, WC.y, WC.z - WR - Wr), (WC.x - WR - Wr, WC.y, WC.z - WR - Wr)]
    data = {'width': res[0], 'height': res[1], 'job': JOB, 'time': TIME, 'door': DOOR, 'fps': FPS, 'frames': FRAMES,
            'note': 'quads: [tl,tr,br,bl] normalised 0..1, origin top-left (D-41). figures: feet line and height in px of this image.',
            'anchors': {k: project(v) for k, v in A.items()}, 'figures': {}}
    cdir = (cam.matrix_world.to_quaternion() @ Vector((0, 0, -1)))
    side = Vector((cdir.y, -cdir.x, 0)).normalized()          # floor direction parallel to the image plane
    for name, s in SLOTS.items():
        F = Vector(s['feet']); H = s['height']
        (fl, fr, fc, top, chest) = project([F - side * 220, F + side * 220, F, F + Vector((0, 0, H)), F + Vector((0, 0, H * 0.72))])
        hpx = (fc[1] - top[1]) * res[1]
        data['figures'][name] = {
            'speaker': s['speaker'], 'door_state': s['state'], 'feet_world_mm': list(F), 'height_mm': H,
            'feet_center': fc, 'feet_line': [fl, fr], 'head_top': top, 'chest': chest,
            'height_px': round(hpx, 1), 'px_per_mm': round(hpx / H, 5), 'depth_mm': round((F - cam.matrix_world.translation).dot(cdir), 1),
            'occluded_by_leaf': s['state'] == 'ajar',
            'lights': light_info(F + Vector((0, 0, H * 0.72))),
        }
    data['camera'] = {'location_mm': [round(c, 2) for c in cam.matrix_world.translation], 'lens_mm': cam.data.lens,
                      'sensor_height_mm': 36.0, 'sensor_fit': 'VERTICAL', 'shift': [cam.data.shift_x, cam.data.shift_y],
                      'rotation_euler_deg': [round(math.degrees(a), 3) for a in cam.matrix_world.to_euler()]}
    with open(path, 'w') as fh: json.dump(data, fh, indent=1)
    print('ANCHORS', path)

# ---------------------------------------------------------------- 8. render
def setup_device():
    scene.render.engine = 'CYCLES'
    if DEVICE == 'GPU':
        prefs = bpy.context.preferences.addons['cycles'].preferences
        for kind in ('OPTIX', 'CUDA', 'HIP', 'METAL', 'ONEAPI'):
            try:
                prefs.compute_device_type = kind; prefs.get_devices()
            except TypeError: continue
            if any(d.type == kind for d in prefs.devices): break
        for d in prefs.devices: d.use = d.type != 'CPU'
        scene.cycles.device = 'GPU'
        print('GPU', prefs.compute_device_type, [d.name for d in prefs.devices if d.use])
    else:
        scene.cycles.device = 'CPU'
    if THREADS: scene.render.threads_mode = 'FIXED'; scene.render.threads = THREADS

def base_render(res, spp, out):
    render_setup(out, res, spp, exposure=EXPO, look='AgX - Medium High Contrast', bounces=10)
    setup_device()
    scene.cycles.adaptive_threshold = 0.02 if spp < 64 else 0.01
    if DEVICE == 'GPU' and arg('--denoiser', 'OIDN').upper() == 'OPTIX': scene.cycles.denoiser = 'OPTIX'
    VIG = {'night': 0.36, 'evening': 0.3}.get(TIME, 0.22)
    photo_finish(VIG)
    # (the centre-oval bug of photo_finish is fixed in env_common since 2026-11-08: flat (1 - VIG), as graded)
    scene.view_settings.look = 'AgX - High Contrast' if TIME == 'night' else 'AgX - Base Contrast'

if MODE in ('seq', 'both'):
    seq_dir = os.path.join(OUT_DIR, BASE + '_seq'); os.makedirs(seq_dir, exist_ok=True)
    base_render(RES, SPP, os.path.join(seq_dir, 'f_####'))
    scene.render.use_motion_blur = True; scene.render.motion_blur_shutter = 0.5
    scene.render.use_persistent_data = True; scene.render.image_settings.file_format = 'PNG'
    scene.frame_step = STEP
    bpy.ops.render.render(animation=True)
    scene.frame_step = 1; scene.render.use_motion_blur = False
    print('WROTE SEQ', seq_dir)
if MODE in ('still', 'both', 'anchors', 'shadow'):
    still = os.path.join(OUT_DIR, BASE + '_hold.png')
    base_render(STILL_RES, STILL_SPP, still)
    scene.frame_set(FRAMES)
    anchors(os.path.splitext(still)[0] + '.json', STILL_RES)
    if MODE in ('still', 'both'):
        # depth matte for occlusion of composited figures (door leaf, jamb, newel in front of a slot):
        # planar camera depth in mm, 16-bit PNG, value = depth / DEPTH_MAX (written by the compositor, no extra render)
        DEPTH_MAX = 20000.0
        scene.view_layers[0].use_pass_z = True
        nt = scene.node_tree; rl = [n for n in nt.nodes if n.type == 'R_LAYERS'][0]
        mr = nt.nodes.new('CompositorNodeMapRange'); mr.inputs['From Max'].default_value = DEPTH_MAX; mr.use_clamp = True
        nt.links.new(rl.outputs['Depth'], mr.inputs['Value'])
        fo = nt.nodes.new('CompositorNodeOutputFile'); fo.base_path = OUT_DIR
        fo.format.file_format = 'PNG'; fo.format.color_mode = 'BW'; fo.format.color_depth = '16'
        fo.format.color_management = 'OVERRIDE'; fo.format.view_settings.view_transform = 'Standard'
        fo.format.view_settings.look = 'None'; fo.format.view_settings.exposure = 0
        fo.file_slots[0].path = BASE + '_hold_depth_'
        nt.links.new(mr.outputs['Value'], fo.inputs[0])
        bpy.ops.render.render(write_still=True); print('WROTE', still)
        src = os.path.join(OUT_DIR, BASE + '_hold_depth_%04d.png' % scene.frame_current)
        if os.path.exists(src): os.replace(src, os.path.join(OUT_DIR, BASE + '_hold_depth.png'))
        with open(os.path.splitext(still)[0] + '.json') as fh: J = json.load(fh)
        J['depth_png'] = {'file': BASE + '_hold_depth.png', 'depth_max_mm': DEPTH_MAX, 'encoding': 'planar camera depth = value/65535*depth_max_mm'}
        with open(os.path.splitext(still)[0] + '.json', 'w') as fh: json.dump(J, fh, indent=1)
if MODE == 'shadow':
    # The figure as a camera-invisible card that only casts shadows (alpha from the cut-out); every scene
    # surface becomes a shadow catcher, so the Shadow Catcher pass is the ratio lit-with / lit-without.
    for o in bpy.data.objects:
        if o.type in ('MESH', 'CURVE', 'FONT'): o.is_shadow_catcher = True
    scene.render.film_transparent = True
    vl = scene.view_layers[0]; vl.cycles.use_pass_shadow_catcher = True
    cdir = (cam.matrix_world.to_quaternion() @ Vector((0, 0, -1))); yaw = math.atan2(cdir.y, cdir.x) - math.pi / 2
    for slot, png in FIGS.items():
        s = SLOTS[slot]; img = bpy.data.images.load(os.path.abspath(png))
        w, h = img.size; px = list(img.pixels[:])
        ys_ = [j for j in range(h) if any(px[(j * w + i) * 4 + 3] > 0.5 for i in range(0, w, 4))]
        xs_ = [i for i in range(0, w, 2) if any(px[(j * w + i) * 4 + 3] > 0.5 for j in range(0, h, 4))]
        j0, j1, i0, i1 = min(ys_), max(ys_), min(xs_), max(xs_)
        mm = s['height'] / (j1 - j0)                      # alpha bbox height == figure height
        me = bpy.data.meshes.new('card'); bm_ = bmesh.new()
        u0, u1 = (0 - (i0 + i1) / 2) * mm, (w - (i0 + i1) / 2) * mm; z0, z1 = -j0 * mm, (h - j0) * mm
        vs = [bm_.verts.new((u0, 0, z0)), bm_.verts.new((u1, 0, z0)), bm_.verts.new((u1, 0, z1)), bm_.verts.new((u0, 0, z1))]
        bm_.faces.new(vs); uv = bm_.loops.layers.uv.new()
        for f in bm_.faces:
            for lp, (a, b) in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))): lp[uv].uv = (a, b)
        bm_.to_mesh(me); bm_.free()
        card = bpy.data.objects.new('figure_card_' + slot, me); bpy.context.collection.objects.link(card)
        card.location = s['feet']; card.rotation_euler.z = yaw
        m = bpy.data.materials.new('card_' + slot); m.use_nodes = True; nt = m.node_tree
        tex = nt.nodes.new('ShaderNodeTexImage'); tex.image = img
        bsdf = nt.nodes['Principled BSDF']; bsdf.inputs['Base Color'].default_value = (0.2, 0.2, 0.2, 1)
        nt.links.new(tex.outputs['Alpha'], bsdf.inputs['Alpha']); m.blend_method = 'CLIP' if hasattr(m, 'blend_method') else None
        card.data.materials.append(m); card.is_shadow_catcher = False
        card.visible_camera = False; card.visible_glossy = False; card.visible_diffuse = True; card.visible_shadow = True
        # hide the other slots' state: the ajar door only when the doorway figure is composited
    nt = scene.node_tree; nt.nodes.clear()
    rl = nt.nodes.new('CompositorNodeRLayers'); out = nt.nodes.new('CompositorNodeComposite')
    nt.links.new(rl.outputs['Shadow Catcher'], out.inputs['Image'])
    scene.view_settings.view_transform = 'Standard'; scene.view_settings.look = 'None'; scene.view_settings.exposure = 0
    scene.render.image_settings.color_depth = '16'; scene.render.film_transparent = True
    scene.render.filepath = os.path.join(OUT_DIR, BASE + '_shadow_' + '_'.join(FIGS) + '.png')
    bpy.ops.render.render(write_still=True); print('WROTE', scene.render.filepath)
