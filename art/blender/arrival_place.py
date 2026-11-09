# Lockwright — D-58 arrival scenes for jobs that do not happen on a tenement landing (D-94): small environment kits
# in the same material library and lighting approach as the stairwell kit (art/blender/stairwell.py,
# arrival_scene.py), dressed by the job's entry in art/blender/arrival_jobs.json (`"kit": "street" | "shop" |
# "corridor"`). Outputs use the arrival_scene.py names, so art/tools/arrival_export.py --job works unchanged:
#   <job>_<time>_seq/f_####.png  the walk in (36 frames @ 12 fps, motion blur)
#   <job>_<time>_hold.png/.json  the hold still (plate only: these clients have no full-body cut-out)
#
#   blender -b -P art/blender/arrival_place.py -- --job bike_interview --mode still --device GPU \
#       --still-res 1080x1920 --still-spp 512 --out-dir <master dir>
#   (--mode seq --res 1080x1920 --spp 128 for the walk; --still-res 540x960 --still-spp 32 for a preview)
# Kits (invented, unbranded, no readable text):
#   street    a 1970s large-panel block on an estate: pavement slabs, gravel drip strip, entrance with a concrete
#             canopy, a galvanised hoop rack with a city bike held by a thumbwheel cable lock (job.bike_interview)
#   shop      a small pizzeria after closing: tiled counter, chairs up on the tables, brick oven with the last embers,
#             the back-room door with a mortise (lever) lock (job.pizzeria_pays_pizza)
#   vault     the museum's vault room under the port warehouse: brick barrel vault, the old savings bank's vault
#             door with the time-lock movement behind an inspection glass, rope barrier, crate (job.museum_time_lock)
#   corridor  a developer block's corridor at dawn: porcelain floor, white walls, flat anthracite steel flat doors
#             with a magnetic-key cylinder, brushed steel numbers, LED downlights (job.night_nurse)
#   facade    old-town street fronts (D-108), `facade.style`: "tenement_gate" (an 1890 Kraków tenement's oak carriage
#             gate with the stuck key and the residents' notice: job.krakow_tenement_gate), "beguinage" (a whitewashed
#             Ghent beguinage house, green door, brother Pieter's bike: job.ghent_beguinage), "townhouse" (Saint-Gilles,
#             balcony with geraniums: look-dev only, not shipped). Wet setts with puddles and a damp-air volume for rain.
#   shop      `shop.style: "bakery"`: the same room as a Liège bakery at 3:50 (bread wall, proving rack under linen, the
#             uncle's bunch of keys hanging from the wrong key in the lock: job.liege_bakery)
# 1 unit = 1 mm. Camera looks +y; the hold target sits near the origin; floor z = 0.
import bpy, bmesh, math, os, sys, json, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from env_common import *
from env_common import _bev, _new, _sep, _math, _bump
from lw_common import _noise, _mix, _maprange, _cavity_mask
from mathutils import Vector, Matrix

arg = cli()
JOB = arg('--job', 'bike_interview'); MODE = arg('--mode', 'still')
_JOBS = json.load(open(os.path.join(HERE, 'arrival_jobs.json'), encoding='utf-8'))['jobs']
if JOB not in _JOBS or 'kit' not in _JOBS[JOB]: sys.exit('arrival_place: %s has no "kit" in arrival_jobs.json' % JOB)
J = _JOBS[JOB]; KIT = J['kit']; CAMC = J.get('camera', {})
TIME = arg('--time', J.get('times', ['day'])[0])
DEVICE = arg('--device', 'CPU').upper(); SPP = int(arg('--spp', '12')); STILL_SPP = int(arg('--still-spp', '32'))
RES = [int(v) for v in arg('--res', '270x480').split('x')]; STILL_RES = [int(v) for v in arg('--still-res', '540x960').split('x')]
FRAMES = int(arg('--frames', '36')); FPS = int(arg('--fps', '12')); STEP = int(arg('--step', '1'))
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT, 'art', 'renders', 'arrival')))
os.makedirs(OUT_DIR, exist_ok=True)
BASE = '%s_%s' % (JOB, TIME)
R = random.Random(hash(JOB) & 0xffff)
for o in list(bpy.data.objects): bpy.data.objects.remove(o, do_unlink=True)

# ---------------------------------------------------------------- shared helpers
def ph(name, tex, **kw):
    """Photo material (art/textures/photo) with the procedural fallback of lw_common."""
    return photo_mat(name, tex, **kw)

def group(name, objs, M):
    """Parent loose world-space parts to an empty and move them together (bike, chairs)."""
    e = bpy.data.objects.new(name, None); bpy.context.collection.objects.link(e)
    for o in objs:
        o.parent = e
    e.matrix_world = M
    return e

def scatter(name, items, mats):
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

def leaf_maker(bm):
    ret = bmesh.ops.create_circle(bm, cap_ends=True, segments=10, radius=1.0)
    for v in ret['verts']:
        v.co.x *= 0.62; v.co.z = 0.22 * (v.co.x ** 2) + 0.08 * v.co.y
    return ret

def cyl_y(name, r, y0, y1, x, z, mat, verts=32, bev=None):
    """Cylinder along y (knobs, cylinders, hubs)."""
    o = cyl(name, r, y1 - y0, (x, (y0 + y1) / 2, z), axis='Y', verts=verts)
    if mat: setmat(o, mat)
    if bev: _bev(o, bev, 2)
    return o

def arc(cx, cz, r, a0, a1, n=24, y=0.0):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * k / n)), y, cz + r * math.sin(math.radians(a0 + (a1 - a0) * k / n))) for k in range(n + 1)]

def sky_world(strength, elev, rot, sun_disc=False):
    """Nishita daylight sky (no HDRI): the sun lamp carries the direct light, the sky the fill."""
    w = scene.world = bpy.data.worlds.new('sky'); w.use_nodes = True; nt = w.node_tree
    sk = nt.nodes.new('ShaderNodeTexSky'); sk.sky_type = 'NISHITA'; sk.sun_elevation = math.radians(elev)
    sk.sun_rotation = math.radians(rot); sk.sun_disc = sun_disc; sk.air_density = 1.4; sk.dust_density = 2.5
    bg = nt.nodes['Background']; bg.inputs['Strength'].default_value = strength
    nt.links.new(sk.outputs['Color'], bg.inputs['Color'])

def sun_lamp(direction, energy, color, angle=0.6):
    bpy.ops.object.light_add(type='SUN'); s = bpy.context.object; s.name = 'sun'
    d = Vector(direction).normalized(); s.rotation_euler = (-d).to_track_quat('Z', 'Y').to_euler()
    s.data.energy = energy; s.data.color = color; s.data.angle = math.radians(angle); return s

def point_lamp(name, loc, energy, color, size=30):
    bpy.ops.object.light_add(type='POINT', location=loc); o = bpy.context.object; o.name = name
    o.data.energy = energy; o.data.color = color; o.data.shadow_soft_size = size; return o

def aim(name, loc):
    e = bpy.data.objects.new(name, None); scene.collection.objects.link(e); e.location = loc; return e

# common materials
dark = dark_mat('void', (0.01, 0.009, 0.008))
galv = metal('galvanised', (0.56, 0.57, 0.56), 0.38, marks='stamp', wear=0.3, grime=0.7, smudge=0.4, seed=3)
alu = metal('anodised_alu', (0.30, 0.22, 0.14), 0.32, marks='grind', marks_axis=(0, 0, 1), wear=0.2, grime=0.5)
steel = metal('satin_steel', (0.62, 0.62, 0.60), 0.26, aniso=0.5, marks='grind', marks_axis=(1, 0, 0), marks_scale=0.3, wear=0.3, grime=0.4, smudge=0.6)
black_plastic = plastic('black_plastic', (0.03, 0.03, 0.032), rough=0.4, grime=0.4)
rub = rubber('tyre')

# ================================================================ street kit (job.bike_interview)
def kit_street():
    S = J.get('street', {})
    FY = 2000                                    # facade plane (wall face)
    conc = [ph('slab%d' % i, 'workshop_concrete', scale=1400 + 90 * i, rot=17 * i, metallic=0.0, base=(0.40 - 0.025 * i, 0.385 - 0.025 * i, 0.36 - 0.025 * i),
               base_mix=0.58, tint=(1.0, 0.97, 0.92), rough_add=0.12, bump=0.9, grime=1.0, wear=0.35) for i in range(4)]
    bed = dark_mat('joint_bed', (0.035, 0.038, 0.022), 0.95)   # soil and moss in the joints
    bx('bed', -6000, 6000, -12000, FY, -80, -62, bed)
    # pavement: 500 mm slabs, a few settled and cracked
    for ix in range(-12, 12):
        for iy in range(-24, 3):
            x0, y0 = ix * 500, iy * 500 + 300
            z = R.uniform(-4, 1) - (6 if R.random() < 0.06 else 0)
            o = bx('slab', x0 + 3, x0 + 497, y0 + 3, y0 + 497, -60, z, conc[R.randrange(4)], bev=4)
            o.rotation_euler.z = math.radians(R.uniform(-0.25, 0.25))
    # gravel drip strip along the wall (y 1800..FY) and a concrete kerb edging it
    kerb = ph('kerb', 'workshop_concrete', scale=500, metallic=0.0, tint=(0.82, 0.81, 0.79), rough_add=0.1, bump=0.5, grime=0.8)
    bx('kerb', -6000, 6000, 1800, 1880, -60, 40, kerb, bev=8)
    stones = [plastic('pebble%d' % i, c, rough=0.6, seed=i, grime=0.3, sheen_scuffs=0.0) for i, c in
              enumerate(((0.42, 0.40, 0.37), (0.30, 0.28, 0.26), (0.55, 0.52, 0.47), (0.36, 0.30, 0.24)))]
    items = []
    for i in range(int(S.get('pebbles', 2600))):
        x = R.uniform(-4200, 4200); y = R.uniform(1890, FY - 10); s = R.uniform(9, 22)
        M = Matrix.Translation((x, y, -12 + R.uniform(0, 10))) @ Matrix.Rotation(R.uniform(0, 6.3), 4, 'Z') @ Matrix.Diagonal((s, s * R.uniform(0.6, 1.0), s * 0.55, 1))
        items.append((lambda bm: bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0), M, R.randrange(4)))
    scatter('gravel', items, stones)
    bx('gravel_bed', -6000, 6000, 1880, FY, -60, -14, bed)

    # ---- facade: plinth, large panels with sealed joints, windows; the entrance bay with a canopy
    panel = ph('panel', 'workshop_concrete', scale=2600, metallic=0.0, base=tuple(S.get('panel', (0.60, 0.57, 0.51))), base_mix=0.78,
               rough_add=0.15, bump=0.7, grime=1.0, wear=0.0)
    panel2 = ph('panel2', 'workshop_concrete', scale=2400, rot=90, metallic=0.0, base=tuple(S.get('panel_band', (0.42, 0.45, 0.45))), base_mix=0.78,
                rough_add=0.15, bump=0.7, grime=1.0)
    plinth = ph('plinth', 'workshop_concrete', scale=1400, metallic=0.0, base=(0.30, 0.30, 0.29), base_mix=0.7, rough_add=0.1, bump=0.8, grime=1.0)
    seal = rubber('sealant', (0.07, 0.068, 0.065), 0.6)
    pvc = plastic('pvc_white', (0.78, 0.77, 0.74), rough=0.3, grime=0.6, sheen_scuffs=0.1)
    win_glass = glass('win_glass', (0.6, 0.62, 0.62), rough=0.02)
    curtain = plastic('net_curtain', (0.72, 0.70, 0.64), rough=0.8, seed=2, grime=0.2, sheen_scuffs=0.0)
    curtain.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value = 0.3
    room = dark_mat('room', (0.05, 0.045, 0.04), 0.9)
    bx('plinth', -9000, 9000, FY, FY + 300, -60, 750, plinth, bev=6)
    stain_decal('splash', 'Y', FY - 0.5, (-6000, 6000, 0, 760), [(x, 60, 900, 260, 0.5) for x in range(-6000, 6001, 1500)],
                color=(0.12, 0.11, 0.09), rough=0.95, noise_scale=0.008)
    BAY, STOREY = 3600, 2800
    ENT = S.get('entrance_x', 1800)            # entrance bay centre
    for k in range(-3, 4):
        cx = k * BAY
        for s_ in range(5):
            z0 = 750 + s_ * STOREY; z1 = z0 + STOREY
            if s_ == 0 and cx == round(ENT / BAY) * BAY:
                continue
            wx0, wx1, wz0, wz1 = cx - 750, cx + 750, z0 + 850, z0 + 2350
            mat = panel2 if s_ % 2 else panel
            # panel around the window opening (4 pieces), 20 mm proud of the joint
            for (a, b_, c, d) in ((cx - BAY / 2 + 15, wx0, z0 + 15, z1 - 15), (wx1, cx + BAY / 2 - 15, z0 + 15, z1 - 15),
                                  (wx0, wx1, z0 + 15, wz0), (wx0, wx1, wz1, z1 - 15)):
                bx('panel', a, b_, FY - 20, FY + 300, c, d, mat, bev=6)
            bx('joint_v', cx - BAY / 2 - 15, cx - BAY / 2 + 15, FY - 8, FY + 300, z0, z1, seal)
            bx('joint_h', cx - BAY / 2, cx + BAY / 2, FY - 8, FY + 300, z0 - 15, z0 + 15, seal)
            # window: reveal, PVC frame with a mullion, glass, curtain, sill
            bx('reveal', wx0, wx1, FY + 140, FY + 300, wz0, wz1, room)
            for (a, b_, c, d) in ((wx0, wx0 + 70, wz0, wz1), (wx1 - 70, wx1, wz0, wz1), (wx0, wx1, wz0, wz0 + 70), (wx0, wx1, wz1 - 70, wz1),
                                  (cx - 35, cx + 35, wz0, wz1)):
                bx('pvc', a, b_, FY + 90, FY + 160, c, d, pvc, bev=4)
            bx('glass', wx0 + 70, wx1 - 70, FY + 120, FY + 126, wz0 + 70, wz1 - 70, win_glass)
            cc = curtain if R.random() < 0.75 else room
            bx('curtain', wx0 + 80, wx1 - 80, FY + 230, FY + 236, wz0 + 80, wz1 - 60, cc)
            bx('sill', wx0 - 40, wx1 + 40, FY - 60, FY + 140, wz0 - 40, wz0, galv, bev=3)
            if s_ < 3:   # rain off the sill ends: two grey streaks down the panel
                stain_decal('streak', 'Y', FY - 21, (wx0 - 200, wx1 + 200, max(z0 - 400, 760), wz0 - 40),
                            [(wx0 + 10, wz0 - 500, 60, 600, 0.45), (wx1 - 10, wz0 - 520, 60, 640, 0.45), (cx, wz0 - 300, 520, 160, 0.18)],
                            color=(0.16, 0.15, 0.13), rough=0.9, noise_scale=0.01)
    # entrance bay: recessed vestibule, aluminium-and-glass door, canopy slab, step, intercom, bulkhead lamp
    ex0, ex1 = ENT - 1000, ENT + 1000
    bc = round(ENT / BAY) * BAY   # the ground-floor bay the entrance sits in: wall either side of the recess
    for (a, b_) in ((bc - BAY / 2 + 15, ex0), (ex1, bc + BAY / 2 - 15)):
        if b_ - a > 20: bx('ent_wall', a, b_, FY - 20, FY + 300, 750, 750 + STOREY - 15, panel, bev=6)
    # the stair's glass-block strip left of the entrance (pressed glass blocks in mortar, 1970s)
    gb = tiles('glass_blocks', (0.42, 0.47, 0.45), grout=(0.50, 0.49, 0.46), w=190, h=190, offset=0.0, rough=0.05, mortar=12, var=0.12, bump=0.8)
    gb.node_tree.nodes['Principled BSDF'].inputs['Transmission Weight'].default_value = 0.0
    gb.node_tree.nodes['Principled BSDF'].inputs['Coat Weight'].default_value = 0.6
    gx0 = bc - BAY / 2 + S.get('glass_block_x', 900)
    bx('glass_block_strip', gx0, gx0 + 3 * 190 + 12, FY - 26, FY - 18, 1100, 1100 + 11 * 190 + 12, gb, bev=3)
    bx('gb_frame', gx0 - 40, gx0 + 3 * 190 + 52, FY - 22, FY - 19, 1060, 1100 + 11 * 190 + 52, plinth, bev=4)
    bx('joint_v', bc - BAY / 2 - 15, bc - BAY / 2 + 15, FY - 8, FY + 300, 750, 750 + STOREY, seal)
    bx('joint_v', bc + BAY / 2 - 15, bc + BAY / 2 + 15, FY - 8, FY + 300, 750, 750 + STOREY, seal)
    bx('ent_over', ex0, ex1, FY - 20, FY + 300, 3150, 750 + STOREY - 15, panel, bev=6)
    vtiles = ph('vest_tiles', 'terrazzo_grey_red', scale=700, metallic=0.0, rough_add=0.05, grime=0.8)
    bx('vest_floor', ex0, ex1, FY - 20, FY + 1400, 0, 170, vtiles, bev=5)
    bx('step', ex0 - 200, ex1 + 200, FY - 420, FY - 20, -40, 170, kerb, bev=8)
    vest = lime_wall('vest_wall', (0.62, 0.60, 0.55), seed=8, dirt=0.7, cracks=0.4)
    bx('vest_l', ex0, ex0 + 120, FY - 20, FY + 1400, 0, 3150, vest)
    bx('vest_r', ex1 - 120, ex1, FY - 20, FY + 1400, 0, 3150, vest)
    bx('vest_back', ex0, ex1, FY + 1400, FY + 1500, 0, 3150, vest)
    DY = FY + 600   # door line inside the recess
    for (a, b_) in ((ex0 + 120, ex0 + 190), (ex1 - 190, ex1 - 120), (ENT - 35, ENT + 35)):
        bx('df_v', a, b_, DY - 30, DY + 40, 170, 2550, alu, bev=3)
    for (c, d) in ((170, 260), (2480, 2550), (1000, 1060)):
        bx('df_h', ex0 + 120, ex1 - 120, DY - 30, DY + 40, c, d, alu, bev=3)
    bx('df_top', ex0 + 120, ex1 - 120, DY - 20, DY + 30, 2550, 3150, alu, bev=3)
    gl = glass('door_glass', (0.55, 0.58, 0.56), rough=0.03, dirt=0.6)
    for (a, b_) in ((ex0 + 190, ENT - 35), (ENT + 35, ex1 - 190)):
        bx('dglass', a, b_, DY, DY + 8, 260, 1000, gl); bx('dglass', a, b_, DY, DY + 8, 1060, 2480, gl)
    for sx in (-1, 1):
        tube('pull', [(ENT + sx * 110, DY - 60, 900), (ENT + sx * 110, DY - 90, 960), (ENT + sx * 110, DY - 90, 1500), (ENT + sx * 110, DY - 60, 1560)], 14, steel)
    bx('canopy', ex0 - 600, ex1 + 600, FY - 1500, FY, 3150, 3300, plinth, bev=10)
    bx('canopy_edge', ex0 - 600, ex1 + 600, FY - 1520, FY - 1500, 3130, 3320, galv, bev=2)
    ipan = bx('intercom', ex1 + 160, ex1 + 380, FY - 26, FY - 18, 1180, 1620, steel, bev=4)
    btn = metal('button', (0.70, 0.70, 0.68), 0.2, marks='turn', marks_axis=(0, 1, 0), wear=0.2, grime=0.3)
    for i in range(4):
        for j in range(5):
            cyl_y('btn', 14, FY - 34, FY - 24, ex1 + 215 + i * 37, 1230 + j * 50, btn, verts=20)
    bx('speaker', ex1 + 200, ex1 + 340, FY - 30, FY - 26, 1500, 1590, black_plastic, bev=2)
    lampm = opal_glass('bulkhead_glass', glow=0.6 if TIME != 'day' else 0.0, color=(1.0, 0.9, 0.75))
    cyl_y('bulkhead_base', 130, FY - 70, FY - 20, ENT, 2900, galv, verts=48)
    o = cyl_y('bulkhead', 110, FY - 130, FY - 60, ENT, 2900, lampm, verts=48, bev=20)
    # downpipe with brackets
    PX = ENT + BAY / 2 - 15
    tube('downpipe', [(PX, FY - 120, -20), (PX, FY - 120, 15000)], 50, galv, smooth_pts=False)
    tube('shoe', [(PX, FY - 120, 300), (PX, FY - 220, 60), (PX, FY - 300, 40)], 50, galv)
    for z in range(1500, 15000, 2000):
        bx('bracket', PX - 60, PX + 60, FY - 180, FY - 10, z, z + 30, galv)
    # ---- the hoop rack (galvanised, set in the paving) and the bike
    RY = S.get('rack_y', 800)
    for k, x in enumerate(S.get('hoops', [-1900, -1000, -100])):
        pts = [(x, RY, -40), (x, RY, 620)] + arc(x + 280, 620, 280, 180, 0, 16, RY)[1:-1] + [(x + 560, RY, 620), (x + 560, RY, -40)]
        tube('hoop%d' % k, pts, 26, galv, res=4)
        for xx in (x, x + 560):
            bx('hoop_foot', xx - 70, xx + 70, RY - 70, RY + 70, -8, 4, bed)
    bike(S, RY)
    # ---- autumn: birch leaves on the slabs, more in the joints and against the kerb
    lm = [plastic('leaf%d' % i, c, rough=0.55, seed=i, grime=0.2, sheen_scuffs=0.0) for i, c in
          enumerate(((0.62, 0.42, 0.05), (0.50, 0.30, 0.04), (0.36, 0.20, 0.05), (0.44, 0.40, 0.10)))]
    for m_ in lm:
        b_ = m_.node_tree.nodes['Principled BSDF']; b_.inputs['Subsurface Weight'].default_value = 0.2
    items = []
    for i in range(int(S.get('leaves', 420))):
        if R.random() < 0.45:
            x = R.uniform(-4000, 4000); y = R.uniform(1500, 1790)
        else:
            x = R.gauss(-600, 1700); y = R.uniform(-6000, 1700)
        s = R.uniform(18, 30)
        M = Matrix.Translation((x, y, 1.5)) @ Matrix.Rotation(R.uniform(0, 6.3), 4, 'Z') @ Matrix.Rotation(R.uniform(-0.3, 0.3), 4, 'X') @ Matrix.Diagonal((s, s, s, 1))
        items.append((leaf_maker, M, R.randrange(4)))
    scatter('leaves', items, lm)
    # ---- light: low morning sun from the left over the estate, the next block's shadow and a birch canopy as gobo
    elev, az = S.get('sun_elev', 18.0), S.get('sun_az', 215.0)   # az: deg from +x towards +y; 215 = low from the left, a little behind the camera (raking across the facade)
    d = Vector((math.cos(math.radians(az)) * math.cos(math.radians(elev)), math.sin(math.radians(az)) * math.cos(math.radians(elev)), math.sin(math.radians(elev))))
    sky_world(S.get('sky', 0.55), elev, az + 90)
    sun_lamp(-d, S.get('sun', 4.2), (1.0, 0.86, 0.68), angle=0.7)
    # birch canopy (leaf-noise card between the sun and the pavement): dappled light, never seen in the frame
    cm = bpy.data.materials.new('canopy'); cm.use_nodes = True; nt = cm.node_tree; nt.nodes.clear()
    tc = nt.nodes.new('ShaderNodeTexCoord'); vo = nt.nodes.new('ShaderNodeTexVoronoi'); vo.inputs['Scale'].default_value = 0.0035
    vo.feature = 'F1'; nt.links.new(tc.outputs['Object'], vo.inputs['Vector'])
    nz = nt.nodes.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = 0.0006; nz.inputs['Detail'].default_value = 4
    nt.links.new(tc.outputs['Object'], nz.inputs['Vector'])
    mixf = nt.nodes.new('ShaderNodeMath'); mixf.operation = 'ADD'; nt.links.new(vo.outputs['Distance'], mixf.inputs[0])
    sc = nt.nodes.new('ShaderNodeMath'); sc.operation = 'MULTIPLY'; sc.inputs[1].default_value = 0.6; nt.links.new(nz.outputs['Fac'], sc.inputs[0])
    nt.links.new(sc.outputs[0], mixf.inputs[1])
    th = nt.nodes.new('ShaderNodeMath'); th.operation = 'GREATER_THAN'; th.inputs[1].default_value = S.get('canopy_open', 0.62)
    nt.links.new(mixf.outputs[0], th.inputs[0])
    tr = nt.nodes.new('ShaderNodeBsdfTransparent'); df = nt.nodes.new('ShaderNodeBsdfDiffuse'); df.inputs['Color'].default_value = (0.05, 0.08, 0.03, 1)
    mx = nt.nodes.new('ShaderNodeMixShader'); nt.links.new(th.outputs[0], mx.inputs[0]); nt.links.new(df.outputs[0], mx.inputs[1]); nt.links.new(tr.outputs[0], mx.inputs[2])
    out = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(mx.outputs[0], out.inputs['Surface'])
    c0 = Vector(S.get('canopy_at', (-1200, -2200, 0)))
    can = bx('canopy_gobo', -4000, 4000, -4000, 4000, -1, 1, cm)
    can.matrix_world = Matrix.Translation(c0 + d * S.get('canopy_dist', 7000)) @ d.to_track_quat('Z', 'Y').to_matrix().to_4x4()
    can.visible_camera = False; can.visible_glossy = False; can.visible_diffuse = False
    # the next block across the lane: a long soft shadow over the left of the pavement
    return {'target': [(-900, RY - 300, 300), (300, RY - 300, 300), (300, RY - 300, 1000), (-900, RY - 300, 1000)]}


def bike(S, RY):
    """A city bike (diamond frame, mudguards, chain guard, rear carrier) leaning on the middle hoop, its front
    wheel and frame held to the hoop by a coiled cable lock with four thumbwheels."""
    B = S.get('bike', {})
    frame = paint('bike_paint', tuple(B.get('color', (0.035, 0.11, 0.075))), rough=B.get('rough', 0.32), metal_col=(0.5, 0.5, 0.5), chip=B.get('chip', 0.4), grime=B.get('grime', 0.5))
    if B.get('rust'):   # D-110: Borys's bike before the restoration: paint gone to rust bloom
        frame = iron('bike_rust', rust=B['rust'], base=tuple(B.get('color', (0.12, 0.08, 0.06))), polish=0.1, seed=5, scale=0.7)
    chrome_free = metal('bike_steel', (0.52, 0.52, 0.51), 0.3, marks='turn', marks_axis=(0, 1, 0), wear=0.3, grime=0.6)
    rim_m = metal('rim_alu', (0.66, 0.66, 0.65), 0.3, marks='turn', marks_axis=(0, 1, 0), wear=0.2, grime=0.5)
    spoke_m = metal('spoke', (0.6, 0.6, 0.6), 0.28, marks=None, grime=0.4)
    saddle_m = plastic('saddle', (0.05, 0.035, 0.025), rough=0.45, grime=0.4)
    guard_m = paint('guard_paint', tuple(B.get('guard', (0.05, 0.05, 0.05))), rough=0.35, chip=0.3)
    cable_m = plastic('cable_pvc', (0.025, 0.03, 0.04), rough=0.3, grime=0.3, sheen_scuffs=0.2)
    lock_m = plastic('lock_body', (0.03, 0.03, 0.03), rough=0.5, grime=0.4)
    wheel_m = metal('lock_wheel', (0.58, 0.57, 0.55), 0.3, marks='turn', marks_axis=(1, 0, 0), wear=0.4, grime=0.6)
    parts = []
    WR = 335; RA, FA = Vector((-545, 0, WR)), Vector((515, 0, WR))
    BB = Vector((0, 0, 290)); ST = Vector((-160, 0, 800)); HT = Vector((395, 0, 790)); HB = Vector((430, 0, 650))
    for c in (RA, FA):
        tor = bpy.ops.mesh.primitive_torus_add(major_radius=WR - 17, minor_radius=19, major_segments=96, minor_segments=16, location=c, rotation=(math.pi / 2, 0, 0))
        t = bpy.context.object; t.name = 'tyre'; setmat(t, rub); parts.append(t)
        bpy.ops.mesh.primitive_torus_add(major_radius=WR - 38, minor_radius=9, major_segments=96, minor_segments=8, location=c, rotation=(math.pi / 2, 0, 0))
        r_ = bpy.context.object; r_.name = 'rim'; r_.scale = (1, 1, 1.6); setmat(r_, rim_m); parts.append(r_)
        parts.append(cyl_y('hub', 22, c.y - 50, c.y + 50, c.x, c.z, chrome_free, verts=24))
        for k in range(32):
            a = 2 * math.pi * k / 32; side = 1 if k % 2 else -1
            a2 = a + side * 0.35
            p0 = c + Vector((math.cos(a) * 20, side * 40, math.sin(a) * 20)); p1 = c + Vector((math.cos(a2) * (WR - 45), side * 6, math.sin(a2) * (WR - 45)))
            parts.append(tube('spoke', [p0, p1], 1.1, spoke_m, res=2, smooth_pts=False, caps=False))
        # mudguard: a flattened arc over the top of the wheel
        g = tube('guard', arc(c.x, c.z, WR + 22, 160 if c is RA else 20, 20 if c is RA else 200, 30), 24, guard_m, res=3)
        g.scale = (1, 1.9, 1); g.location = (0, 0, 0); parts.append(g)
    T = lambda nm, a, b_, r: parts.append(tube(nm, [a, b_], r, frame, res=6, smooth_pts=False))
    T('down', BB, HB, 19); T('seat', BB, ST, 16); T('top', ST + Vector((10, 0, -40)), HT + Vector((0, 0, -20)), 15)
    T('head', HB + Vector((5, 0, -30)), HT + Vector((-5, 0, 40)), 20)
    for sy in (-38, 38):
        T('chainstay', BB + Vector((0, sy * 0.4, 0)), RA + Vector((0, sy, 0)), 9)
        T('seatstay', ST + Vector((10, sy * 0.3, -60)), RA + Vector((0, sy, 0)), 8)
        parts.append(tube('fork', [HB + Vector((0, sy * 0.4, -30)), HB + Vector((40, sy, -200)), FA + Vector((0, sy, 0))], 10, frame, res=6))
        parts.append(tube('carrier_stay', [RA + Vector((0, sy, 0)), RA + Vector((60, sy, 330))], 6, chrome_free, res=3, smooth_pts=False))
    parts.append(bx('carrier', -720, -230, -75, 75, WR + 330, WR + 345, chrome_free, bev=3))
    for xx in range(-700, -240, 60):
        parts.append(bx('carrier_bar', xx, xx + 10, -75, 75, WR + 325, WR + 340, chrome_free))
    # seat post, saddle, stem, swept-back city bar, grips
    T('post', ST, ST + Vector((-30, 0, 120)), 13)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=32, ring_count=16, location=ST + Vector((-45, 0, 150)))
    sd = bpy.context.object; sd.name = 'saddle'; sd.scale = (140, 85, 40); setmat(sd, saddle_m); _bev(sd, 0.01, 1); parts.append(sd)
    T('stem', HT + Vector((-5, 0, 40)), HT + Vector((-15, 0, 170)), 13)
    bar = [HT + Vector((-15, -280, 160)), HT + Vector((40, -230, 175)), HT + Vector((10, -60, 175)), HT + Vector((-15, 0, 172)),
           HT + Vector((10, 60, 175)), HT + Vector((40, 230, 175)), HT + Vector((-15, 280, 160))]
    parts.append(tube('bar', bar, 11, chrome_free, res=4))
    for sy in (-1, 1):
        parts.append(tube('grip', [HT + Vector((-15, sy * 270, 162)), HT + Vector((-95, sy * 300, 150))], 17, saddle_m, res=4))
    # cranks, chainring, chain guard, pedals
    parts.append(cyl_y('chainring', 95, 42, 50, BB.x, BB.z, chrome_free, verts=48))
    cg = bx('chainguard', -520, 120, 52, 60, BB.z - 30, BB.z + 110, guard_m, bev=6); parts.append(cg)
    for sy, ang in ((60, 35), (-60, 215)):
        e = BB + Vector((170 * math.cos(math.radians(ang)), sy, 170 * math.sin(math.radians(ang))))
        parts.append(tube('crank', [BB + Vector((0, sy, 0)), e], 12, chrome_free, res=3, smooth_pts=False))
        parts.append(bx('pedal', e.x - 50, e.x + 50, e.y + (10 if sy > 0 else -110), e.y + (110 if sy > 0 else -10), e.z - 12, e.z + 12, black_plastic, bev=3))
    if B.get('basket'):   # wicker basket on a front carrier over the wheel (brother Pieter's bike, D-108)
        wick = tiles('wicker', (0.42, 0.28, 0.13), grout=(0.16, 0.10, 0.05), w=18, h=9, offset=0.5, rough=0.7, mortar=1.6, axis='X', var=0.25, bump=1.2)
        wick2 = tiles('wicker_f', (0.42, 0.28, 0.13), grout=(0.16, 0.10, 0.05), w=18, h=9, offset=0.5, rough=0.7, mortar=1.6, axis='Y', var=0.25, bump=1.2)
        bc = FA + Vector((40, 0, WR + 330))
        bk = lathe_open('basket', [(150, 0), (165, 60), (180, 160), (188, 230)], x=bc.x, y=bc.y, seg=48, thick=8, mat=wick)
        bk.location.z = bc.z; parts.append(bk)
        parts.append(cyl('basket_floor', 150, 10, (bc.x, bc.y, bc.z + 5), verts=48)); parts[-1].data.materials.append(wick2)
        parts.append(tube('basket_rim', arc(0, 0, 190, 0, 360, 48), 10, wick, smooth_pts=False))
        parts[-1].rotation_euler.x = math.radians(90); parts[-1].location = (bc.x, bc.y, bc.z + 232)
        for sy in (-60, 60):
            parts.append(tube('basket_stay', [FA + Vector((0, sy, 0)), bc + Vector((-20, sy, 5))], 6, chrome_free, res=3, smooth_pts=False))
    if not B.get('cable', True):
        M = Matrix.Translation(Vector(B.get('at', (-640, RY - 160, 0)))) @ Matrix.Rotation(math.radians(B.get('yaw', 0.0)), 4, 'Z') @ Matrix.Rotation(math.radians(B.get('lean', 4.0)), 4, 'X')
        group('bike', parts, M); return
    # the cable lock: coiled cable through the front wheel and round the hoop, the thumbwheel body on top
    L = S.get('lock', {})
    hoop_x = L.get('hoop_x', 320)   # in bike space, the hoop leg the bike leans on
    cab = [FA + Vector((-60, 30, 240)), FA + Vector((10, 120, 300)), FA + Vector((-120, 230, 360)), Vector((hoop_x, 250, 560)),
           Vector((hoop_x - 120, 150, 610)), HB + Vector((-60, 40, -60)), FA + Vector((-150, -40, 330)), FA + Vector((-80, -30, 260))]
    parts.append(tube('cable', cab, 7, cable_m, res=4))
    lb = FA + Vector((-150, -45, 345))
    body = bx('lock_body', -48, 48, -16, 16, -26, 26, lock_m, bev=6); body.location = lb; body.rotation_euler = (0, math.radians(-18), 0); parts.append(body)
    for i in range(4):
        w = cyl('lock_wheel', 11, 14, (0, 0, 0), axis='X', verts=24); setmat(w, wheel_m)
        w.location = lb + Matrix.Rotation(math.radians(-18), 3, 'Y') @ Vector((-28 + i * 18.7, -17, 2)); w.rotation_euler = (0, math.radians(-18), 0)
        parts.append(w)
        for k in range(10):   # ribs on the rim of each wheel (digits are not read; the ribs catch the light)
            a = 2 * math.pi * k / 10
            rb = bx('rib', -6, 6, -0.8, 0.8, 10.5, 12.2, wheel_m); rb.rotation_euler = (a, 0, 0); rb.parent = w; rb.matrix_parent_inverse = Matrix.Identity(4)
    M = Matrix.Translation(Vector(B.get('at', (-640, RY - 160, 0)))) @ Matrix.Rotation(math.radians(B.get('yaw', 0.0)), 4, 'Z') @ Matrix.Rotation(math.radians(B.get('lean', 4.0)), 4, 'X')
    group('bike', parts, M)


# ================================================================ tiles (grout as a brick pattern: one plane, no box per tile)
def tiles(name, color, grout=(0.55, 0.54, 0.50), w=150.0, h=75.0, offset=0.5, rough=0.12, mortar=2.5, axis='Y', var=0.06, bump=0.4, seed=0.0):
    """Glazed tiles: per-tile tone variation, a slight wave in the glaze, matte grout lines that dip (bump)."""
    m, nt, l, b, P = _new(name)
    X, Y, Z = _sep(nt, P)
    cx = nt.nodes.new('ShaderNodeCombineXYZ')
    if axis == 'Y':
        l.new(X, cx.inputs[0]); l.new(Z, cx.inputs[1])
    elif axis == 'X':
        l.new(Y, cx.inputs[0]); l.new(Z, cx.inputs[1])
    else:
        l.new(X, cx.inputs[0]); l.new(Y, cx.inputs[1])
    br = nt.nodes.new('ShaderNodeTexBrick'); br.offset = offset; br.squash_frequency = 1
    br.inputs['Scale'].default_value = 1.0; br.inputs['Brick Width'].default_value = w; br.inputs['Row Height'].default_value = h
    br.inputs['Mortar Size'].default_value = mortar; br.inputs['Mortar Smooth'].default_value = 0.3; br.inputs['Bias'].default_value = 0.0
    br.inputs['Color1'].default_value = (*color, 1); br.inputs['Color2'].default_value = (*[c * (1 - var) for c in color], 1)
    br.inputs['Mortar'].default_value = (*grout, 1); l.new(cx.outputs[0], br.inputs['Vector'])
    dirt = _maprange(nt, _noise(nt, P, 0.003, detail=6, rough=0.7), 0.45, 0.8, 0.0, 0.25)
    col = _mix(nt, br.outputs['Color'], (0.20, 0.17, 0.12, 1), dirt)
    l.new(col, b.inputs['Base Color'])
    r = _mix(nt, rough, 0.85, br.outputs['Fac'], dtype='FLOAT'); l.new(r, b.inputs['Roughness'])
    wave = _noise(nt, P, 0.02 + seed * 0.001, detail=3)
    hgt = _math(nt, 'SUBTRACT', _math(nt, 'MULTIPLY', wave, 0.15), br.outputs['Fac'])
    l.new(_bump(nt, hgt, bump, 1.5), b.inputs['Normal'])
    return m


def bakery_wall(S, FY, CX1):
    """Bakery (job.liege_bakery, D-108): instead of the oven, the bread wall behind the counter: timber shelving with
    slanted wicker bread trays, empty at 3:50 but for three rolls left from yesterday; a glass display on the counter."""
    shelf_w = oak('bread_shelf', light=(0.46, 0.33, 0.19), dark=(0.26, 0.17, 0.08), axis='X', seed=57, ring=1.6, coat=0.5, coat_rough=0.4, wear=0.7, grime=0.8)
    wick = tiles('bread_wicker', (0.44, 0.30, 0.14), grout=(0.16, 0.10, 0.05), w=16, h=8, offset=0.5, rough=0.7, mortar=1.4, axis='Z', var=0.25, bump=1.0)
    X0w, X1w = S.get('bread_x', (-3150, -1500)); Yb = FY - 30
    for x in (X0w, X1w - 40):
        bx('bread_upright', x, x + 40, Yb - 520, Yb, 0, 2500, shelf_w, bev=3)
    crust = plastic('crust', (0.36, 0.17, 0.05), rough=0.55, seed=3, grime=0.1, sheen_scuffs=0.0)
    for k, z in enumerate((1150, 1500, 1850, 2200)):
        tr_ = bx('bread_tray', X0w + 45, X1w - 45, -480, 0, 0, 18, wick, bev=4)
        tr_.matrix_world = Matrix.Translation((0, Yb, z)) @ Matrix.Rotation(math.radians(14), 4, 'X')
        lip = bx('bread_lip', X0w + 45, X1w - 45, -500, -470, 0, 90, shelf_w, bev=3)
        lip.matrix_world = tr_.matrix_world
        if k == 1:   # three rolls left from yesterday
            for i in range(3):
                bpy.ops.mesh.primitive_uv_sphere_add(radius=1, location=(X0w + 300 + i * 190, Yb - 300, z + 18 + 40 - 300 * math.tan(math.radians(14))))
                o = bpy.context.object; o.scale = (80, 55, 40); o.rotation_euler = (math.radians(14), 0, R.uniform(-0.3, 0.3)); setmat(o, crust)
    # glass display case on the counter, empty trays
    gl = glass('display_glass', (0.92, 0.94, 0.93), rough=0.01, dirt=0.5)
    DX0_, DX1_ = -3000, CX1 - 120
    for (a, b_, c, d, e_, f_) in ((DX0_, DX1_, -2560, -2552, 1040, 1420), (DX0_, DX1_, -2560, -2200, 1412, 1420)):
        bx('display_glass', a, b_, c, d, e_, f_, gl).visible_shadow = False
    tray_m = metal('display_tray', (0.66, 0.66, 0.64), 0.28, marks='grind', marks_axis=(1, 0, 0), wear=0.3, grime=0.5)
    for i in range(3):
        bx('display_tray', DX0_ + 60 + i * 600, DX0_ + 580 + i * 600, -2500, -2240, 1045, 1060, tray_m, bev=3)


def bakery_props(S, FY, LY, HX, HZ, CX1, shelf_m):
    """The story at the back-room door: the uncle's bunch of thirty unlabelled keys still hanging from the wrong key
    in the lock; a proving rack of dough under linen in front of it; flour everywhere."""
    key_ms = [metal('key_brass', (0.74, 0.58, 0.32), 0.3, marks='stamp', wear=0.6, grime=0.6, patina=0.3),
              metal('key_steel', (0.62, 0.62, 0.60), 0.3, marks='stamp', wear=0.5, grime=0.6),
              metal('key_nickel', (0.70, 0.69, 0.66), 0.25, marks='stamp', wear=0.4, grime=0.5)]
    KY = LY - 7; KZ = HZ - 100
    tube('wrong_key_shank', [(HX, KY, KZ), (HX, KY - 55, KZ)], 4, key_ms[1], smooth_pts=False)
    bx('wrong_key_bow', HX - 22, HX + 22, KY - 62, KY - 55, KZ - 18, KZ + 18, key_ms[1], bev=3)
    RC = Vector((HX, KY - 66, KZ - 60))   # the ring hangs from the bow's hole
    bpy.ops.mesh.primitive_torus_add(major_radius=40, minor_radius=2.4, major_segments=48, minor_segments=8, location=RC, rotation=(0, math.radians(90), 0))
    setmat(bpy.context.object, key_ms[1])
    rk = random.Random(30)
    for i in range(int(S.get('keys', 30))):
        a = math.radians(rk.uniform(205, 335))       # where on the ring (its lower arc, in the y-z plane)
        p0 = RC + Vector((0, 40 * math.cos(a), 40 * math.sin(a)))
        swing = math.radians(rk.gauss(0, 16)); L = rk.uniform(46, 76)
        d = Vector((rk.uniform(-0.25, 0.25), math.sin(swing) - 0.15, -math.cos(swing))).normalized()
        m_ = key_ms[rk.randrange(3)]
        bow_c = p0 + d * 15
        side = d.cross(Vector((1, 0, 0)))
        side = side.normalized() if side.length > 1e-3 else Vector((0, 1, 0))
        rot = Matrix((side, d, side.cross(d))).transposed().to_4x4()   # local x = side, y = along the key, z = face normal
        bw = cyl('key_bow', 13, 2.2, (0, 0, 0), axis='Z', verts=24); bw.matrix_world = Matrix.Translation(bow_c) @ rot; setmat(bw, m_)
        tube('key_blade', [tuple(bow_c + d * 10), tuple(bow_c + d * (10 + L))], 2.6, m_, res=2, smooth_pts=False)
        bt = bx('key_bit', -5, 5, -7, 7, -1.2, 1.2, m_); bt.matrix_world = Matrix.Translation(bow_c + d * (4 + L) + side * 5) @ rot
    # proving rack: steel frame on castors, trays of dough rounds under linen
    rx, ry = S.get('rack', (900, 1400))
    for (dx, dy) in ((-330, -230), (330, -230), (-330, 230), (330, 230)):
        bx('rack_post', rx + dx - 12, rx + dx + 12, ry + dy - 12, ry + dy + 12, 90, 1750, shelf_m, bev=2)
        cyl('castor', 38, 30, (rx + dx, ry + dy, 40), axis='X', verts=24).data.materials.append(black_plastic)
    dough = plastic('dough', (0.80, 0.70, 0.52), rough=0.6, seed=6, grime=0.0, sheen_scuffs=0.0)
    dough.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value = 0.25
    linen = plastic('linen', (0.78, 0.76, 0.70), rough=0.92, seed=7, grime=0.25, sheen_scuffs=0.0)
    linen.node_tree.nodes['Principled BSDF'].inputs['Sheen Weight'].default_value = 0.5
    items = []
    for k, z in enumerate((260, 520, 780, 1040, 1300, 1560)):
        bx('rack_tray', rx - 320, rx + 320, ry - 220, ry + 220, z, z + 14, shelf_m, bev=2)
        if k < 5:
            for i in range(4):
                for j in range(3):
                    s = R.uniform(52, 60) * (1.0 + 0.12 * k / 5)
                    items.append((lambda bm: bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=12, radius=1.0),
                                  Matrix.Translation((rx - 230 + i * 155, ry - 140 + j * 140, z + 14 + s * 0.4)) @ Matrix.Diagonal((s, s, s * 0.65, 1)), 0))
    scatter('dough_rounds', items, [dough])
    # linen over the top tray, falling over the front edge in soft folds (a grid draped by hand: sag + folds)
    bm = bmesh.new(); NU, NV = 48, 40; rows = []
    for j in range(NV + 1):
        t = j / NV; row = []
        for i in range(NU + 1):
            u = i / NU; x = rx - 350 + 700 * u
            if t < 0.55:   # across the top, back to front, a slight sag between the dough rows
                y = ry + 245 - 500 * (t / 0.55); z = 1652 + 28 * math.sin(math.pi * u * 4) ** 2 * (t / 0.55) - 6
                yo = 0
            else:          # over the edge and down, folds deepening towards the hem
                s = (t - 0.55) / 0.45
                y = ry - 255 - 40 * math.sin(math.pi * s * 0.8); z = 1652 - 430 * s
                yo = -(18 + 26 * s) * (0.5 + 0.5 * math.sin(x * 0.045 + 1.3 * math.sin(x * 0.011)))
            row.append(bm.verts.new((x, y + yo, z)))
        rows.append(row)
    for j in range(NV):
        for i in range(NU):
            bm.faces.new((rows[j][i], rows[j][i + 1], rows[j + 1][i + 1], rows[j + 1][i]))
    me = bpy.data.meshes.new('linen'); bm.to_mesh(me); bm.free()
    lo = bpy.data.objects.new('linen', me); bpy.context.collection.objects.link(lo); lo.data.materials.append(linen)
    for p_ in me.polygons: p_.use_smooth = True
    sol = lo.modifiers.new('sol', 'SOLIDIFY'); sol.thickness = 2.0
    stain_decal('flour_rack', 'Z', 0.5, (rx - 900, rx + 900, ry - 900, ry + 700), [(rx, ry, 600, 500, 0.35)], color=(0.80, 0.78, 0.72), rough=0.95, noise_scale=0.02)


def atelier_wall(S, FY):
    """Gosia's restoration workshop at the port (D-110): instead of the oven, a pegboard tool wall with clamps,
    chisels, a coping saw and a mallet on its hooks, a shelf of glue pots and brushes above it."""
    peg = ph('pegboard', 'pegboard_brown', scale=900, metallic=0.0, rough_add=0.05, bump=0.8, grime=0.8)
    PX0, PX1 = S.get('peg_x', (-3050, -1300)); y = FY - 20
    bx('pegboard', PX0, PX1, y - 12, y, 900, 2200, peg)
    for (a, b_) in ((PX0 - 30, PX0), (PX1, PX1 + 30)):
        bx('peg_batten', a, b_, y - 30, y, 880, 2220, oak('peg_batten', light=(0.50, 0.38, 0.22), dark=(0.30, 0.20, 0.10), axis='Z', seed=151, coat=0.0, rough=0.7), bev=3)
    iron_c = paint('clamp_red', (0.45, 0.05, 0.03), rough=0.4, metal_col=(0.5, 0.5, 0.5), chip=0.5, grime=0.6)
    bar = metal('clamp_bar', (0.55, 0.55, 0.54), 0.35, marks='grind', marks_axis=(0, 0, 1), wear=0.5, grime=0.7)
    handle = oak('tool_handle', light=(0.62, 0.45, 0.25), dark=(0.40, 0.26, 0.12), axis='Z', seed=153, coat=0.3, rough=0.5, wear=0.8, grime=0.8)
    rt = random.Random(77)
    x = PX0 + 120
    for k in range(5):   # F-clamps hanging from their bars
        L = rt.uniform(500, 800)
        tube('clamp_bar', [(x, y - 40, 2050), (x, y - 40, 2050 - L)], 9, bar, smooth_pts=False)
        bx('clamp_jaw', x - 10, x + 90, y - 60, y - 22, 2010, 2060, iron_c, bev=4)
        bx('clamp_jaw2', x - 10, x + 90, y - 60, y - 22, 2050 - L * 0.6, 2050 - L * 0.6 + 50, iron_c, bev=4)
        tube('clamp_screw', [(x + 70, y - 41, 2050 - L * 0.6), (x + 70, y - 41, 2050 - L * 0.6 - 140)], 6, bar, smooth_pts=False)
        tube('clamp_grip', [(x + 70, y - 41, 2050 - L * 0.6 - 140), (x + 70, y - 41, 2050 - L * 0.6 - 260)], 16, handle, smooth_pts=False)
        x += rt.uniform(110, 150)
    x += 60
    for k in range(6):   # chisels in a rack
        bx('chisel_rack', x - 20, x + 400, y - 70, y - 20, 1500, 1530, handle, bev=3)
        tube('chisel_handle', [(x + k * 65, y - 45, 1640), (x + k * 65, y - 45, 1520)], 13, handle, smooth_pts=False)
        bx('chisel_blade', x + k * 65 - 6 - k * 1.5, x + k * 65 + 6 + k * 1.5, y - 48, y - 42, 1330, 1500, bar)
    tube('mallet_head', [(x + 60, y - 70, 1150), (x + 260, y - 70, 1150)], 45, handle, smooth_pts=False)
    tube('mallet_handle', [(x + 160, y - 70, 1150), (x + 160, y - 70, 900)], 13, handle, smooth_pts=False)
    shelf = oak('atelier_shelf', light=(0.48, 0.36, 0.22), dark=(0.28, 0.19, 0.10), axis='X', seed=155, coat=0.0, rough=0.7, wear=0.6, grime=1.0)
    bx('glue_shelf', PX0 - 30, PX1 + 30, y - 260, y, 2260, 2290, shelf, bev=3)
    tins = [metal('tin%d' % i, c, 0.35, marks=None, wear=0.6, grime=1.0) for i, c in enumerate(((0.55, 0.55, 0.53), (0.45, 0.20, 0.10), (0.20, 0.30, 0.40)))]
    xx = PX0 + 40
    while xx < PX1 - 150:
        r = rt.uniform(55, 95); h = rt.uniform(110, 190)
        cyl('tin', r, h, (xx + r, y - 130, 2290 + h / 2), verts=32).data.materials.append(tins[rt.randrange(3)])
        if rt.random() < 0.5:
            tube('brush', [(xx + r, y - 130, 2290 + h - 10), (xx + r + 30, y - 140, 2290 + h + 180)], 8, handle, smooth_pts=False)
        xx += 2 * r + rt.uniform(15, 60)


def atelier_props(S, FY, shelf_m, SX0, SX1):
    """The old workbench Gosia bought (the drawer is the job), a chair stripped to bare wood on sawhorses, a cabinet
    under a dust sheet, tins and jars on the steel shelf, shavings and sawdust on the floor."""
    rt = random.Random(78)
    bench = oak('old_bench', light=tuple(S.get('bench_light', (0.48, 0.34, 0.19))), dark=(0.24, 0.15, 0.07), axis='X', seed=161, ring=2.6, coat=0.1, rough=0.7, wear=1.0, grime=1.0)
    BX, BY = S.get('bench_at', (0, 1500)); BW, BD, BH = 1900, 700, 880
    bx('bench_top', BX - BW / 2, BX + BW / 2, BY - BD / 2, BY + BD / 2, BH - 90, BH, bench, bev=6)
    for dx in (-BW / 2 + 60, BW / 2 - 150):
        for dy in (-BD / 2 + 50, BD / 2 - 140):
            bx('bench_leg', BX + dx, BX + dx + 90, BY + dy, BY + dy + 90, 0, BH - 90, bench, bev=5)
    bx('bench_stretcher', BX - BW / 2 + 60, BX + BW / 2 - 60, BY - BD / 2 + 60, BY - BD / 2 + 120, 150, 230, bench, bev=4)
    bx('bench_apron', BX - BW / 2 + 60, BX + BW / 2 - 60, BY - BD / 2 + 20, BY - BD / 2 + 45, BH - 260, BH - 90, bench, bev=3)
    # the locked drawer in the apron, its brass escutcheon facing us
    DX0, DX1 = BX - 330, BX + 330; DY = BY - BD / 2 + 15
    bx('drawer_front', DX0, DX1, DY - 8, DY + 10, BH - 245, BH - 105, bench, bev=4)
    brass_e = metal('drawer_brass', (0.72, 0.54, 0.28), 0.32, marks='stamp', wear=0.7, grime=0.9, patina=0.6)
    bx('drawer_escutcheon', BX - 22, BX + 22, DY - 11, DY - 8, BH - 210, BH - 140, brass_e, bev=2)
    bx('drawer_keyhole', BX - 4, BX + 4, DY - 11.6, DY - 10.9, BH - 195, BH - 168, dark); cyl_y('drawer_kh_top', 6, DY - 11.6, DY - 10.9, BX, BH - 165, dark, verts=16)
    # front vice on the left end
    vice_m = paint('vice_iron', (0.06, 0.08, 0.07), rough=0.45, metal_col=(0.45, 0.45, 0.45), chip=0.6, grime=0.8)
    bx('vice_jaw', BX - BW / 2 + 40, BX - BW / 2 + 300, BY - BD / 2 - 60, BY - BD / 2 - 10, BH - 220, BH, bench, bev=4)
    tube('vice_screw', [(BX - BW / 2 + 170, BY - BD / 2 - 10, BH - 120), (BX - BW / 2 + 170, BY - BD / 2 - 160, BH - 120)], 14, vice_m, smooth_pts=False)
    tube('vice_tommy', [(BX - BW / 2 + 70, BY - BD / 2 - 165, BH - 120), (BX - BW / 2 + 270, BY - BD / 2 - 165, BH - 120)], 9, vice_m, smooth_pts=False)
    # on the bench: a hand plane, a block of beeswax, rags, the collection photo of the bench face down
    plane_m = paint('plane_body', (0.05, 0.10, 0.20), rough=0.35, metal_col=(0.55, 0.55, 0.55), chip=0.6, grime=0.6)
    bx('hand_plane', BX + 250, BX + 500, BY - 80, BY - 10, BH, BH + 70, plane_m, bev=8)
    tube('plane_knob', [(BX + 470, BY - 45, BH + 70), (BX + 470, BY - 45, BH + 140)], 18, oak('knob', light=(0.45, 0.20, 0.10), dark=(0.30, 0.10, 0.05), axis='Z', seed=163, coat=0.8), smooth_pts=False)
    bx('rag', BX - 200, BX + 50, BY + 30, BY + 230, BH, BH + 22, plastic('rag', (0.62, 0.55, 0.45), rough=0.95, seed=7, grime=0.9), bev=10)
    bx('photo_print', BX + 600, BX + 760, BY + 40, BY + 160, BH, BH + 1.2, paper('print_back', (0.80, 0.79, 0.74), seed=8, grime=0.3))
    # a chair stripped to bare wood upside down on two sawhorses, right of the bench
    horse = oak('sawhorse', light=(0.58, 0.45, 0.28), dark=(0.38, 0.27, 0.14), axis='X', seed=165, coat=0.0, rough=0.8, wear=0.7, grime=1.0)
    CX, CY = S.get('chair_at', (1500, 600))
    for dy in (-260, 260):
        bx('horse_beam', CX - 450, CX + 450, CY + dy - 40, CY + dy + 40, 640, 720, horse, bev=4)
        for sx in (-1, 1):
            for sy in (-1, 1):
                tube('horse_leg', [(CX + sx * 380, CY + dy, 680), (CX + sx * 430, CY + dy + sy * 160, 0)], 22, horse, res=3, smooth_pts=False)
    bare = oak('bare_beech', light=(0.72, 0.58, 0.40), dark=(0.58, 0.44, 0.28), axis='Z', seed=167, coat=0.0, rough=0.75, wear=0.3, grime=0.3)
    parts = [bx('cs_seat', -220, 220, -220, 220, 0, 35, bare, bev=6)]
    for (lx, ly) in ((-190, -190), (190, -190), (-190, 190), (190, 190)):
        parts.append(tube('cs_leg', [(lx, ly, 35), (lx * 1.08, ly * 1.08, 470)], 17, bare, res=3, smooth_pts=False))
    parts.append(tube('cs_back', [(-190, 190, 0), (-200, 205, -430), (200, 205, -430), (190, 190, 0)], 15, bare, res=3, smooth_pts=False))
    group('stripped_chair', parts, Matrix.Translation((CX, CY, 760)) @ Matrix.Rotation(math.radians(12), 4, 'Z'))
    # a cabinet waiting under a dust sheet (soft box), against the left wall in front
    sheet = plastic('dust_sheet', (0.74, 0.71, 0.64), rough=0.95, seed=9, grime=0.6, sheen_scuffs=0.0)
    QX, QY = S.get('sheet_at', (-2300, 300))
    bx('sheeted', QX - 450, QX + 450, QY - 300, QY + 300, 0, 1700, sheet, bev=90, seg=4)
    bx('sheet_hem', QX - 480, QX + 480, QY - 330, QY + 330, 0, 120, sheet, bev=40, seg=3)
    # tins and jars on the steel shelf instead of boxes
    tins = [metal('shelf_tin%d' % i, c, 0.35, marks=None, wear=0.6, grime=1.0) for i, c in enumerate(((0.55, 0.55, 0.53), (0.35, 0.12, 0.06), (0.18, 0.25, 0.32)))]
    for z0 in (180, 730, 1280):
        x = SX0 + 50
        while x < SX1 - 200:
            r = rt.uniform(70, 120); h = rt.uniform(130, 260)
            cyl('stin', r, h, (x + r, FY - 300 + rt.uniform(-60, 60), z0 + h / 2), verts=32).data.materials.append(tins[rt.randrange(3)])
            x += 2 * r + rt.uniform(10, 50)
    # boards leaning on the back wall between the door and the shelf, a bureau waiting its turn by the pegboard
    for k in range(5):
        w = rt.uniform(140, 260); L = rt.uniform(1700, 2300); x = 750 + k * 120
        bd = oak('lean_board%d' % k, light=(0.52 - 0.04 * k, 0.38, 0.22), dark=(0.32, 0.21, 0.10), axis='Z', seed=171 + k, coat=0.0, rough=0.8, wear=0.3, grime=0.6)
        o_ = bx('lean_board', -w / 2, w / 2, -12, 12, 0, L, bd, bev=2)
        o_.matrix_world = Matrix.Translation((x, FY - 120 - k * 30, 0)) @ Matrix.Rotation(math.radians(-6 - k), 4, 'X') @ Matrix.Rotation(math.radians(rt.uniform(-3, 3)), 4, 'Y')
    bur = oak('bureau_wood', light=(0.36, 0.18, 0.08), dark=(0.18, 0.08, 0.03), axis='X', seed=181, coat=0.6, coat_rough=0.35, wear=0.9, grime=0.9)
    UX, UY = S.get('bureau_at', (-1700, 1900))
    bx('bureau', UX - 450, UX + 450, UY - 250, UY + 250, 0, 780, bur, bev=4)
    sl_ = bx('bureau_lid', UX - 450, UX + 450, -10, 10, 0, 420, bur, bev=4); sl_.matrix_world = Matrix.Translation((UX, UY - 250, 780)) @ Matrix.Rotation(math.radians(-38), 4, 'X')
    bx('bureau_top', UX - 450, UX + 450, UY + 80, UY + 250, 780, 1110, bur, bev=4)
    for z in (180, 420, 620):
        bx('bureau_drawer', UX - 400, UX + 400, UY - 258, UY - 250, z, z + 170, bur, bev=3)
    # shavings swept into a heap by the bench leg, sawdust round it
    shav = plastic('shaving_pile', (0.70, 0.55, 0.34), rough=0.7, seed=10, grime=0.1, sheen_scuffs=0.0)
    items = []
    for i in range(500):
        a_ = rt.uniform(0, 6.3); r = abs(rt.gauss(0, 140)); s = rt.uniform(10, 22)
        M = Matrix.Translation((BX + BW / 2 + 150 + r * math.cos(a_), BY - 300 + r * math.sin(a_) * 0.7, max(0, 60 - r * 0.35) * rt.random())) @ \
            Matrix.Rotation(rt.uniform(0, 6.3), 4, 'Z') @ Matrix.Rotation(rt.uniform(0, 6.3), 4, 'X') @ Matrix.Diagonal((s, s * 0.6, s * 0.15, 1))
        items.append((leaf_maker, M, 0))
    scatter('shavings', items, [shav])


def kit_shop():
    """A small pizzeria after closing (23:30): the back-room door at the end of the counter, the dining room dark."""
    S = J.get('shop', {})
    FY = 3000; X0, X1 = -3200, 3000; CEIL = 3050
    floor = (ph('shop_floor', 'workshop_concrete', scale=1400, metallic=0.0, base=(0.34, 0.32, 0.29), base_mix=0.5, rough_add=0.1, bump=0.8, grime=1.0, wear=0.5)
             if S.get('style') == 'atelier' else ph('shop_floor', 'cement_tiles', scale=S.get('floor_scale', 300), metallic=0.0, base=(0.30, 0.22, 0.17), base_mix=0.45, tint=(0.85, 0.80, 0.74), rough_add=0.1, bump=0.3, grime=1.0, wear=0.6))
    bx('floor', X0, X1, -6000, FY, -40, 0, floor)
    STYLE = S.get('style', 'pizzeria')
    wall_t = tiles('wall_tiles', (0.82, 0.81, 0.77), grout=(0.42, 0.40, 0.37), w=150, h=75, rough=0.08) if STYLE != 'atelier' else \
        lime_wall('shop_lower', tuple(S.get('lower', (0.50, 0.46, 0.40))), seed=14, dirt=1.0, cracks=0.6)
    upper = lime_wall('shop_upper', tuple(S.get('upper', (0.62, 0.46, 0.28))), seed=11, dirt=0.6, cracks=0.3)
    ceil = lime_wall('shop_ceiling', (0.66, 0.62, 0.55), seed=12, dirt=0.4, cracks=0.3)
    DX0, DX1, DTOP = -450, 450, 2060
    TILE_TOP = 1400
    for nm, z0, z1, m_ in (('t', 0, TILE_TOP, wall_t), ('u', TILE_TOP, CEIL, upper)):
        o = bx('back_' + nm, X0, X1, FY, FY + 200, z0, z1, m_)
        cut(o, bx('hole', DX0 - 60, DX1 + 60, FY - 10, FY + 210, -10, DTOP + 60))
        bx('side_' + nm, X1, X1 + 200, -6000, FY + 200, z0, z1, m_)
        bx('lside_' + nm, X0 - 200, X0, -6000, FY + 200, z0, z1, m_)
    if STYLE != 'atelier':
        bx('tile_cap', X0, X1, FY - 12, FY, TILE_TOP - 4, TILE_TOP + 22, tiles('cap', (0.20, 0.30, 0.22), w=150, h=26, rough=0.1), bev=4)
    bx('ceiling', X0 - 200, X1 + 200, -6000, FY + 200, CEIL, CEIL + 100, ceil)
    bx('behind', X0, X1, -6100, -6000, 0, CEIL, upper)
    # the back-room door: painted timber in a painted frame, aluminium kick plate, mortise lever lock (brass)
    dpaint = oil_paint('door_paint', tuple(S.get('door', (0.10, 0.20, 0.13))), rough=0.28, under=(0.55, 0.45, 0.30), base=(0.30, 0.20, 0.10),
                       chips=0.5, scuffs=0.7, strokes='Z', seed=5, chip_scale=0.02, edge_chips=1.0)
    fpaint = oil_paint('frame_paint', (0.70, 0.66, 0.56), rough=0.3, chips=0.4, scuffs=0.5, strokes='Z', seed=6, edge_chips=1.0)
    for (a, b_, c, d) in ((DX0 - 60, DX0, 0, DTOP + 60), (DX1, DX1 + 60, 0, DTOP + 60), (DX0 - 60, DX1 + 60, DTOP, DTOP + 60)):
        bx('arch', a, b_, FY - 25, FY + 200, c, d, fpaint, bev=5)
    LY = FY + 40
    bx('leaf', DX0 + 3, DX1 - 3, LY, LY + 44, 8, DTOP - 3, dpaint, bev=3)
    for (a, b_, c, d) in ((DX0 + 90, DX1 - 90, 1150, 1900), (DX0 + 90, DX1 - 90, 260, 1000)):   # two flat panels, beads proud
        for (p, q, r_, s_) in ((a, b_, d - 18, d), (a, b_, c, c + 18), (a, a + 18, c, d), (b_ - 18, b_, c, d)):
            bx('bead', p, q, LY - 10, LY, r_, s_, dpaint, bev=3)
    kick = metal('kick_plate', (0.62, 0.62, 0.60), 0.35, marks='grind', marks_axis=(1, 0, 0), wear=0.6, grime=0.8, smudge=0.8)
    bx('kick', DX0 + 15, DX1 - 15, LY - 3, LY, 20, 230, kick, bev=1)
    brass_m = metal('lock_brass', (0.76, 0.56, 0.30), 0.32, marks='stamp', wear=0.7, grime=0.8, patina=0.5)
    HX, HZ = DX1 - 85, 1040
    bx('escutcheon', HX - 24, HX + 24, LY - 6, LY, HZ - 150, HZ + 40, brass_m, bev=3)
    bx('keyhole', HX - 5, HX + 5, LY - 7, LY - 5.9, HZ - 115, HZ - 85, dark)
    cyl_y('keyhole_top', 8, LY - 7, LY - 5.9, HX, HZ - 82, dark, verts=20)
    tube('handle', [(HX, LY - 6, HZ), (HX, LY - 60, HZ), (HX - 120, LY - 62, HZ - 4)], 10, brass_m, res=4)
    # flour: a dusty hand print by the handle, a drift on the floor in front of the threshold
    stain_decal('flour_hand', 'Y', LY - 7.5, (HX - 260, HX - 20, HZ - 200, HZ + 200), [(HX - 150, HZ + 40, 50, 70, 0.45), (HX - 120, HZ - 60, 90, 60, 0.25)],
                color=tuple(S.get('dust', (0.82, 0.80, 0.74))), rough=0.95, noise_scale=0.05)
    stain_decal('flour_floor', 'Z', 0.4, (DX0 - 300, DX1 + 400, FY - 900, FY - 10), [(80, FY - 300, 420, 260, 0.55), (360, FY - 120, 200, 120, 0.5)],
                color=tuple(S.get('dust', (0.80, 0.78, 0.72))), rough=0.95, noise_scale=0.03)
    # counter on the left: tiled front, terrazzo top, the brick oven in the corner behind it
    CX1 = S.get('counter_end', -1250)
    if S.get('counter', True):
        ctl = tiles('counter_tiles', (0.12, 0.26, 0.20), grout=(0.5, 0.48, 0.44), w=100, h=100, offset=0.0, rough=0.08, axis='X')
        bx('counter_front', -3200, CX1, -2600, -1950, 0, 1000, ctl)
        bx('counter_end', CX1 - 30, CX1, -2600, S.get('counter_y1', 850), 0, 1000, ctl)
        marble = ph('counter_top', 'terrazzo_grey_red', scale=900, metallic=0.0, rough_add=-0.05, coat=0.4, bump=0.1, grime=0.3)
        bx('counter_top', -3200, CX1 + 40, -2650, S.get('counter_y1', 850) + 50, 1000, 1040, marble, bev=6)
    PIZZA = S.get('style', 'pizzeria') == 'pizzeria'
    if PIZZA:   # brick oven with the last embers in the corner, plates on the counter
        brick = brick_wall('oven_brick', brick=(0.40, 0.17, 0.09), wash=(0.62, 0.58, 0.52), wash_amt=0.15, seed=9, axis='Y')
        oc = Vector(S.get('oven', (-2550, 2050, 1040)))
        bx('oven_base', oc.x - S.get('oven_r', 720) - 30, oc.x + S.get('oven_r', 720) + 30, oc.y - S.get('oven_r', 720) - 30, FY, 0, 1040, brick, bev=6)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=64, ring_count=32, location=oc)
        OR = S.get('oven_r', 720)
        dome = bpy.context.object; dome.name = 'oven_dome'; dome.scale = (OR, OR, OR * 0.86)
        setmat(dome, lime_wall('oven_plaster', (0.34, 0.29, 0.24), seed=13, dirt=1.0, cracks=0.9))
        bpy.ops.object.transform_apply(scale=True)
        cut(dome, bx('below', -5000, 5000, -5000, 5000, -5000, oc.z))
        cut(dome, bx('mouth_cut', oc.x - 240, oc.x + 240, oc.y - OR - 200, oc.y - OR + 300, oc.z, oc.z + 250))
        cut(dome, bx('mouth_cut_top', oc.x - 160, oc.x + 160, oc.y - OR - 200, oc.y - OR + 300, oc.z, oc.z + 320))
        arch_pts = [(oc.x - 300, 0, oc.z)] + [(oc.x + 300 * math.cos(math.radians(180 - 180 * k / 12)), 0, oc.z + 120 + 230 * math.sin(math.radians(180 * k / 12))) for k in range(13)] + [(oc.x + 300, 0, oc.z)]
        for k in range(len(arch_pts) - 1):
            a_, b2 = Vector(arch_pts[k]), Vector(arch_pts[k + 1])
            br_ = bx('arch_brick', -60, 60, -110, 0, -35, 35, brick, bev=4)
            mid = (a_ + b2) / 2; ang = math.atan2(b2.z - a_.z, b2.x - a_.x)
            br_.matrix_world = Matrix.Translation((mid.x, oc.y - OR + 70, mid.z)) @ Matrix.Rotation(-ang, 4, 'Y')
        bpy.ops.mesh.primitive_uv_sphere_add(radius=1, segments=48, ring_count=24, location=oc)
        inner = bpy.context.object; inner.name = 'oven_inner'; inner.scale = (OR - 80, OR - 80, OR * 0.86 - 80); setmat(inner, dark_mat('soot', (0.015, 0.012, 0.01), 0.9))
        bpy.ops.object.transform_apply(scale=True)
        cut(inner, bx('below2', -5000, 5000, -5000, 5000, -5000, oc.z))
        cut(inner, bx('mouth_cut2', oc.x - 240, oc.x + 240, oc.y - OR - 200, oc.y - OR + 400, oc.z, oc.z + 250))
        cut(inner, bx('mouth_cut2t', oc.x - 160, oc.x + 160, oc.y - OR - 200, oc.y - OR + 400, oc.z, oc.z + 320))
        bx('oven_floor', oc.x - OR + 90, oc.x + OR - 90, oc.y - OR + 90, oc.y + OR - 90, oc.z - 10, oc.z, dark_mat('hearth', (0.05, 0.035, 0.025), 0.9))
        ember = emissive('embers', (1.0, 0.32, 0.06), S.get('embers', 6.0) if TIME != 'day' else 0.0, (0.03, 0.02, 0.015))
        items = []
        for i in range(160):
            a = R.uniform(0, 6.3); rr = R.uniform(0, OR * 0.5); s = R.uniform(12, 35)
            M = Matrix.Translation((oc.x + rr * math.cos(a) * 0.7, oc.y - OR * 0.25 + rr * math.sin(a) * 0.6, oc.z + 6)) @ Matrix.Diagonal((s, s * 0.8, s * 0.6, 1))
            items.append((lambda bm: bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0), M, 0 if R.random() < 0.35 else 1))
        scatter('ember_bed', items, [ember, dark_mat('ash', (0.06, 0.055, 0.05), 0.9)])
        if TIME != 'day':
            point_lamp('ember_light', (oc.x, oc.y - OR * 0.2, oc.z + 90), S.get('ember_w', 3.5e7), (1.0, 0.36, 0.08), size=180)
        plate_m = plastic('plates', (0.80, 0.79, 0.75), rough=0.12, grime=0.2, sheen_scuffs=0.1)
        for i in range(9):
            cyl('plate', 130, 14, (CX1 - 250 + R.uniform(-3, 3), 420 + R.uniform(-3, 3), 1047 + i * 15), verts=48).data.materials.append(plate_m)
    elif STYLE == 'bakery':
        bakery_wall(S, FY, CX1)
    else:
        atelier_wall(S, FY)
    tray = oak('dough_tray', light=(0.55, 0.42, 0.26), dark=(0.36, 0.25, 0.13), axis='X', seed=51, ring=1.5, coat=0.0, rough=0.7, wear=0.4)
    for i in range(3):
        bx('dough_tray', CX1 - 1100, CX1 - 450, -700 - i * 4, 0 - i * 4, 1040 + i * 95, 1130 + i * 95, tray, bev=6)
    # stacked plain pizza boxes and flour sacks on a steel shelf to the right of the door
    shelf_m = metal('shelf_steel', (0.64, 0.64, 0.62), 0.3, marks='grind', marks_axis=(1, 0, 0), wear=0.3, grime=0.6, smudge=0.7)
    SX0, SX1 = S.get('shelf_x', (800, 1900))
    for z in (150, 700, 1250, 1800):
        bx('shelf', SX0, SX1, FY - 520, FY - 20, z, z + 30, shelf_m, bev=2)
    for x in (SX0, SX1 - 30):
        for y in (FY - 520, FY - 50):
            bx('upright', x, x + 30, y, y + 30, 0, 1900, shelf_m, bev=2)
    kraft = paper('kraft', (0.50, 0.36, 0.22), fibre=1.4, seed=4, grime=0.3)
    for k, (x, z0, n) in enumerate(() if STYLE == 'atelier' else ((SX0 + 60, 180, 9), (SX0 + 420, 180, 6), (SX0 + 60, 730, 12), (SX0 + 450, 730, 4))):
        for i in range(n):
            dx = R.uniform(-8, 8); bx('pbox', x + dx, x + dx + 340, FY - 470, FY - 130, z0 + i * 42, z0 + i * 42 + 40, kraft, bev=2)
    sack = plastic('flour_sack', (0.74, 0.70, 0.60), rough=0.85, seed=6, grime=0.4, sheen_scuffs=0.0)
    for k, x in enumerate(() if STYLE == 'atelier' else (SX0 + 120, SX0 + 560)):   # paper flour sacks, slumped (beveled blocks, a fold on top)
        sk = bx('sack', x, x + 400, FY - 470, FY - 150, 1280, 1280 + 330 - 40 * k, sack, bev=60, seg=4)
        sk.rotation_euler.z = math.radians(R.uniform(-6, 6))
        bx('sack_fold', x + 20, x + 380, FY - 330, FY - 290, 1280 + 300 - 40 * k, 1280 + 345 - 40 * k, sack, bev=15)
    # dining room on the right: tables with the chairs up, legs to the ceiling
    wood_t = oak('table_top', light=(0.40, 0.26, 0.14), dark=(0.20, 0.11, 0.05), axis='X', seed=31, ring=2.0, coat=1.0, coat_rough=0.2, wear=0.6)
    chair_m = oak('chair_wood', light=(0.30, 0.17, 0.08), dark=(0.13, 0.06, 0.03), axis='Z', seed=33, ring=1.4, coat=1.0, coat_rough=0.25, wear=0.7)
    for (tx_, ty_) in S.get('tables', [(1800, -900), (1900, -3000)]):
        bx('table', tx_ - 400, tx_ + 400, ty_ - 400, ty_ + 400, 730, 760, wood_t, bev=4)
        cyl('tbase', 30, 730, (tx_, ty_, 365), verts=24).data.materials.append(shelf_m)
        cyl('tfoot', 230, 18, (tx_, ty_, 9), verts=48).data.materials.append(shelf_m)
        for k, (ox, oy, yaw) in enumerate(((-200, -110, 0), (200, 110, 180))):
            parts = [bx('seat', -200, 200, -200, 200, 0, 30, chair_m, bev=4)]
            for (lx, ly) in ((-170, -170), (170, -170), (-170, 170), (170, 170)):
                parts.append(tube('leg', [(lx, ly, 30), (lx * 1.1, ly * 1.1, 470)], 14, chair_m, res=3, smooth_pts=False))
            parts.append(tube('back', [(-170, 170, 30), (-180, 185, -380), (0, 200, -440), (180, 185, -380), (170, 170, 30)], 13, chair_m, res=3))
            group('chair', parts, Matrix.Translation((tx_ + ox, ty_ + oy, 791)) @ Matrix.Rotation(math.radians(yaw + R.uniform(-8, 8)), 4, 'Z'))
    frame_w = oak('pic_frame', light=(0.20, 0.12, 0.06), dark=(0.08, 0.04, 0.02), axis='X', seed=41, ring=1.2, coat=1.0, coat_rough=0.3, wear=0.4)
    prints = [paper('print%d' % i, c, fibre=0.6, seed=i, grime=0.5) for i, c in enumerate(((0.30, 0.24, 0.16), (0.22, 0.26, 0.24), (0.36, 0.30, 0.20)))]
    for i, (px, pz, pw, ph_) in enumerate(S.get('pictures', [(-1050, 1900, 420, 320), (1250, 1850, 360, 460), (2050, 1950, 300, 300)])):
        bx('pic_frame', px - pw / 2 - 30, px + pw / 2 + 30, FY - 28, FY, pz - ph_ / 2 - 30, pz + ph_ / 2 + 30, frame_w, bev=4)
        bx('pic', px - pw / 2, px + pw / 2, FY - 30, FY - 27, pz - ph_ / 2, pz + ph_ / 2, prints[i % 3])
    clk = Vector((0, FY - 30, 2550))
    cyl_y('clock_rim', 170, clk.y - 40, clk.y, clk.x, clk.z, black_plastic, verts=64, bev=4)
    cyl_y('clock_face', 152, clk.y - 41, clk.y - 39, clk.x, clk.z, paper('clock_face', (0.80, 0.78, 0.70), seed=9, grime=0.3), verts=64)
    for k in range(12):
        a = 2 * math.pi * k / 12; L_ = 22 if k % 3 == 0 else 12
        t_ = bx('tick', -3, 3, 0, 1, 0, L_, black_plastic); t_.location = (clk.x + 128 * math.sin(a), clk.y - 42, clk.z + 128 * math.cos(a) - L_ / 2)
        t_.rotation_euler = (0, a, 0)
    for (ln, ang, w_) in ((100, S.get('clock', (345, 255))[0], 6), (70, S.get('clock', (345, 255))[1], 8)):   # minute, hour (deg clockwise from 12)
        h_ = bx('hand', -w_ / 2, w_ / 2, 0, 2, 0, ln, black_plastic); h_.location = (clk.x, clk.y - 44, clk.z); h_.rotation_euler = (0, math.radians(ang), 0)
    if STYLE == 'bakery':
        bakery_props(S, FY, LY, HX, HZ, CX1, shelf_m)
    elif STYLE == 'atelier':
        atelier_props(S, FY, shelf_m, SX0, SX1)
    # light: one pendant left on over the end of the counter, the street lamp through the shop window behind us
    shade = metal('pendant', (0.08, 0.09, 0.08), 0.35, marks=None, grime=0.3, metallic=0.0)
    PL = Vector(S.get('pendant', (-1700, 300, 2250)))
    tube('flex', [(PL.x, PL.y, CEIL), (PL.x, PL.y, PL.z + 160)], 3, black_plastic, smooth_pts=False)
    sh = lathe_open('shade', [(30, 160), (60, 150), (190, 20), (200, 0)], x=PL.x, y=PL.y, seg=64, thick=1.5, mat=shade)
    sh.location.z = PL.z
    bulb_m = emissive('bulb_glow', (1.0, 0.75, 0.45), 30.0 if TIME != 'day' else 0.0)
    bpy.ops.mesh.primitive_uv_sphere_add(radius=45, location=(PL.x, PL.y, PL.z + 50)); setmat(bpy.context.object, bulb_m)
    bpy.context.object.visible_shadow = False
    point_lamp('pendant_bulb', (PL.x, PL.y, PL.z + 40), S.get('pendant_w', 4.0e7), (1.0, 0.70, 0.42), size=40)
    world_hdri(0.003, 'interior.exr', sat=0.3)
    a = aim('aim_street', (0, 0, 1000))
    sl = area_light('street_lamp', (600, -5900, 2300), a, 2400, S.get('street_w', 8.0e7), (0.62, 0.72, 1.0), size_y=1600)   # the shop window behind us
    sl.visible_camera = False; sl.visible_glossy = False
    return {'door': [(DX0, LY, DTOP), (DX1, LY, DTOP), (DX1, LY, 0), (DX0, LY, 0)],
            'lock': [(HX - 30, LY - 6, HZ + 50), (HX + 30, LY - 6, HZ + 50), (HX + 30, LY - 6, HZ - 160), (HX - 30, LY - 6, HZ - 160)]}


def kit_corridor():
    """A developer block's corridor at 7:20 (dawn, motion-sensor LEDs on): flat 14 at the end of a short branch."""
    S = J.get('corridor', {})
    FY = 2600; X0, X1 = -1000, 1000; CEIL = 2650
    floor = tiles('porcelain', tuple(S.get('floor', (0.42, 0.41, 0.39))), grout=(0.20, 0.20, 0.19), w=600, h=1200, offset=0.0, rough=0.06, mortar=3.0, axis='Z', var=0.05, bump=0.3)
    bx('floor', X0 - 1500, X1 + 3000, -9000, FY, -40, 0, floor)
    wall = lime_wall('corr_wall', tuple(S.get('wall', (0.80, 0.79, 0.76))), seed=21, dirt=0.25, cracks=0.05)
    ceil = lime_wall('corr_ceiling', (0.80, 0.80, 0.78), seed=22, dirt=0.1, cracks=0.0)
    accent = ph('veneer', 'g03:oak_satin', scale=2400, rot=0, metallic=0.0, base=tuple(S.get('veneer', (0.55, 0.40, 0.26))), base_mix=0.45, rough_add=0.08, coat=0.15, bump=0.15, grime=0.1)
    DX0, DX1, DTOP = -450, 450, 2080
    back = bx('end_wall', X0, X1, FY, FY + 250, 0, CEIL, wall if S.get('dorm') else accent)   # D-110: the dorm's end wall is painted
    cut(back, bx('hole', DX0 - 40, DX1 + 40, FY - 10, FY + 260, -10, DTOP + 40))
    WIN = S.get('window', (1900, 500))     # side window in the left wall near the door (y range): dawn rakes across the floor
    lwall = bx('left_wall', X0 - 200, X0, -9000, FY + 250, 0, CEIL, wall)
    rwall = bx('right_wall', X1, X1 + 200, -9000, FY + 250, 0, CEIL, wall)
    NDOORS = S.get('neighbours', (-1500, -5300))   # neighbours' doors in the right wall (y of the leaf centre)
    for yc in NDOORS:
        cut(rwall, bx('nhole', X1 - 10, X1 + 210, yc - 490, yc + 490, -10, 2120))
    cut(lwall, bx('whole', X0 - 300, X0 + 10, WIN[1], WIN[0], 900, 2350))
    bx('ceiling', X0 - 300, X1 + 300, -9000, FY + 250, CEIL, CEIL + 120, ceil)
    bx('behind', X0, X1, -9100, -9000, 0, CEIL, wall)
    skirt = plastic('skirting', (0.78, 0.78, 0.76), rough=0.35, grime=0.4, sheen_scuffs=0.2)
    for (a, b_, c, d) in ((X0, X0 + 12, -9000, FY), (X1 - 12, X1, -9000, FY)):
        bx('skirt', a, b_, c, d, 0, 80, skirt, bev=2)
    # the window: grey PVC frame, dawn glass, a sill, the next block's lit windows far out
    pvc = plastic('pvc_grey', (0.18, 0.19, 0.20), rough=0.3, grime=0.3)
    for (y0_, y1_, z0_, z1_) in ((WIN[1], WIN[0], 900, 960), (WIN[1], WIN[0], 2290, 2350), (WIN[1], WIN[1] + 60, 900, 2350), (WIN[0] - 60, WIN[0], 900, 2350)):
        bx('wframe', X0 - 120, X0 - 60, y0_, y1_, z0_, z1_, pvc, bev=3)
    wg = bx('wglass', X0 - 95, X0 - 90, WIN[1] + 60, WIN[0] - 60, 960, 2290, glass('dawn_glass', (0.7, 0.72, 0.74), rough=0.02))
    wg.visible_shadow = False   # no caustics: let the dawn through the pane
    bx('wsill', X0 - 10, X0 + 160, WIN[1] - 40, WIN[0] + 40, 860, 900, ph('sill_stone', 'terrazzo_grey_red', scale=500, metallic=0.0, grime=0.3), bev=4)
    dawn = {'night': ((0.35, 0.48, 0.80), 2.5), 'evening': ((0.30, 0.40, 0.75), 2.0), 'day': ((0.80, 0.86, 0.96), 8.0)}[TIME]
    bx('dawn_sky', X0 - 30000, X0 - 29990, -40000, 60000, -5000, 40000, emissive('dawn', dawn[0], dawn[1], (0, 0, 0)))
    bx('far_block', X0 - 14000, X0 - 13700, -6000, 30000, -3000, 4200, ph('far_panel', 'wall_lime_plaster', scale=2000, metallic=0.0, base=(0.35, 0.36, 0.38), base_mix=0.7))
    lit = emissive('far_lit', (1.0, 0.72, 0.42), 1.2, (0.05, 0.05, 0.05))
    for y in range(-6000, 30000, 2200):
        for z in range(-2000, 4200, 2800):
            if z + 1300 < 4200: bx('far_win', X0 - 13710, X0 - 13699, y, y + 1200, z, z + 1300, lit if R.random() < 0.35 else dark)
    # flat 14: steel frame, flat anthracite leaf, lever on a rose, magnetic-key cylinder, viewer, brushed steel numbers
    frame_m = paint('door_frame', (0.06, 0.065, 0.07), rough=0.38, metal_col=(0.5, 0.5, 0.5), chip=0.15, grime=0.3)
    leaf_m = ph('door_leaf', 'steel_cast_grey_paint', scale=600, metallic=0.0, base=tuple(S.get('door', (0.075, 0.08, 0.085))), base_mix=0.72,
                rough_add=0.02, coat=0.25, bump=0.15, grime=0.3, wear=0.25)
    for (a, b_, c, d) in ((DX0 - 40, DX0, 0, DTOP + 40), (DX1, DX1 + 40, 0, DTOP + 40), (DX0 - 40, DX1 + 40, DTOP, DTOP + 40)):
        bx('dframe', a, b_, FY - 20, FY + 80, c, d, frame_m, bev=2)
    LY = FY + 20
    bx('leaf', DX0 + 2, DX1 - 2, LY, LY + 60, 6, DTOP - 2, leaf_m, bev=2)
    nh = metal('n_lever', (0.62, 0.62, 0.60), 0.26, aniso=0.5, marks='grind', marks_axis=(0, 1, 0), wear=0.2, grime=0.3)
    for yc in NDOORS:   # the neighbours' doors in the right wall: same frame and leaf, lever towards us
        for (a, b_, c, d) in ((yc - 490, yc - 450, 0, 2120), (yc + 450, yc + 490, 0, 2120), (yc - 490, yc + 490, 2080, 2120)):
            bx('nframe', X1 - 20, X1 + 80, a, b_, c, d, frame_m, bev=2)
        bx('nleaf', X1 + 20, X1 + 80, yc - 448, yc + 448, 6, 2078, leaf_m, bev=2)
        tube('nlever', [(X1 + 20, yc - 360, 1040), (X1 - 35, yc - 360, 1040), (X1 - 38, yc - 225, 1037)], 10, nh, res=4)
        cyl('nrose', 27, 9, (X1 + 15, yc - 360, 1040), axis='X', verts=40).data.materials.append(nh)
    for z in (300, 1050, 1800):   # pressed panel lines of a security door
        bx('groove', DX0 + 70, DX1 - 70, LY - 0.5, LY + 1, z, z + 3, dark)
    brushed = metal('brushed', (0.66, 0.66, 0.64), 0.24, aniso=0.6, marks='grind', marks_axis=(1, 0, 0), marks_scale=0.25, wear=0.2, grime=0.3, smudge=0.5)
    HX, HZ = DX1 - 90, 1040
    cyl_y('rose', 27, LY - 9, LY, HX, HZ, brushed, verts=48, bev=1.5)
    tube('lever', [(HX, LY - 9, HZ), (HX, LY - 55, HZ), (HX - 135, LY - 58, HZ - 3)], 10, brushed, res=4)
    cyl_y('cyl_rose', 26, LY - 8, LY, HX, HZ - 180, brushed, verts=48, bev=1.5)
    cyl_y('cyl_face', 17, LY - 11, LY - 8, HX, HZ - 180, metal('cyl_face', (0.70, 0.70, 0.68), 0.2, marks='turn', marks_axis=(0, 1, 0), wear=0.4, grime=0.5), verts=40)
    bx('magkey_slot', HX - 9, HX + 9, LY - 11.6, LY - 10.9, HZ - 182, HZ - 178, dark)
    cyl_y('magring', 21, LY - 9.2, LY - 8.6, HX, HZ - 180, black_plastic, verts=40)
    cyl_y('viewer', 11, LY - 8, LY, 0, 1520, brushed, verts=32)
    font = 'Lato-Regular.ttf'
    num = str(J.get('number', '5'))
    for k, ch in enumerate(num):
        t = text_obj('num' + ch, ch, 120, font=font, extrude=2.0, mat=brushed)
        t.rotation_euler = (math.radians(90), 0, 0); t.location = ((k - (len(num) - 1) / 2) * 80, LY - 4, 1760)
    bell = plastic('bell_white', (0.78, 0.78, 0.76), rough=0.3, grime=0.3)
    bx('bell', DX1 + 110, DX1 + 180, FY - 24, FY, 1180, 1250, bell, bev=4)
    cyl_y('bell_btn', 18, FY - 30, FY - 24, DX1 + 145, 1215, plastic('bell_btn', (0.12, 0.12, 0.13), rough=0.3), verts=24)
    bx('doormat', -380, 380, FY - 560, FY - 60, 0, 9, rubber('mat_grey', (0.07, 0.07, 0.072), 0.8), bev=3)
    # a lived-in new block: scuffs low on the walls, shoe marks on the porcelain, a flush service cabinet, a smoke detector
    stain_decal('shoe_marks', 'Z', 0.3, (-700, 700, FY - 1400, FY - 560), [(0, FY - 700, 380, 260, 0.14), (-150, FY - 1100, 200, 200, 0.08)],
                color=(0.12, 0.11, 0.10), rough=0.6, noise_scale=0.02)
    stain_decal('end_scuff', 'Y', LY - 0.5, (DX0, DX1, 0, 400), [(0, 120, 300, 120, 0.4)], color=(0.03, 0.03, 0.03), rough=0.5, noise_scale=0.05)
    cab = paint('cabinet', (0.78, 0.78, 0.76), rough=0.4, chip=0.1, grime=0.4)
    bx('cabinet', X1 - 4, X1, -3700, -3100, 300, 1900, cab, bev=2)
    for z in (330, 1870):
        bx('cab_gap', X1 - 5, X1 - 4, -3700, -3100, z - 1, z + 1, dark)
    cyl('cab_lock', 12, 6, (X1 - 6, -3150, 1100), axis='X', verts=24).data.materials.append(brushed)
    bpy.ops.mesh.primitive_cylinder_add(radius=55, depth=40, location=(250, 900, CEIL - 20)); sd = bpy.context.object; sd.name = 'smoke'; setmat(sd, bell); _bev(sd, 10, 3)
    if NDOORS:
        yc = NDOORS[0]
        bx('n_mat', X1 - 560, X1 - 40, yc - 330, yc + 330, 0, 9, rubber('n_mat', (0.09, 0.07, 0.05), 0.85), bev=3)
        shoe = plastic('shoe', (0.05, 0.045, 0.04), rough=0.45, grime=0.4)
        sole = rubber('sole', (0.10, 0.09, 0.085), 0.7)
        for k, (sx, sy, a) in enumerate(((X1 - 330, yc - 150, 4), (X1 - 330, yc - 40, -3))):
            M = Matrix.Translation((sx, sy, 9)) @ Matrix.Rotation(math.radians(a), 4, 'Z')
            parts = [bx('sole', -130, 130, -44, 44, 0, 16, sole, bev=6), bx('upper', -122, 60, -40, 40, 14, 95, shoe, bev=30), bx('toe', 40, 124, -38, 38, 14, 55, shoe, bev=22)]
            for o in parts: o.matrix_world = M @ o.matrix_world
        umb = plastic('umbrella', (0.08, 0.10, 0.16), rough=0.6, grime=0.2)
        u = lathe_open('umbrella', [(4, 0), (30, 120), (42, 420), (34, 700), (12, 820)], x=0, y=0, seg=12, thick=0, mat=umb)
        tube('umb_shaft', [(0, 0, -40), (0, 0, 900)], 6, metal('umb_steel', (0.5, 0.5, 0.5), 0.3, marks=None), smooth_pts=False).parent = u
        tube('umb_handle', [(0, 0, 900), (0, 0, 1000), (0, 30, 1040), (0, 60, 1000)], 11, black_plastic).parent = u
        u.matrix_world = Matrix.Translation((X1 - 60, yc + 540, 40)) @ Matrix.Rotation(math.radians(-8), 4, 'Y')
    if S.get('dorm'):   # D-110: a campus dorm, not a developer block: whiteboard and stickers on the door, a drying rack
        wb = plastic('whiteboard', (0.86, 0.86, 0.84), rough=0.15, grime=0.3, sheen_scuffs=0.3)
        bx('wb', -260, 60, LY - 4, LY - 1, 1180, 1520, wb, bev=2)
        bx('wb_frame', -268, 68, LY - 3, LY - 0.5, 1172, 1528, plastic('wb_frame', (0.55, 0.55, 0.56), rough=0.3))
        mk = [plastic('marker%d' % i, col, rough=0.5) for i, col in enumerate(((0.05, 0.1, 0.45), (0.6, 0.05, 0.05), (0.05, 0.3, 0.1)))]
        rk = random.Random(412)
        for i in range(9):   # marker scribbles (no letters: loops and dashes)
            x = rk.uniform(-235, -20); z = rk.uniform(1210, 1490); m_ = mk[rk.randrange(3)]
            pts = [(x + t * 14, LY - 4.5, z + 9 * math.sin(t * 1.7 + i)) for t in range(rk.randint(4, 8))]
            tube('scribble', pts, 1.6, m_)
        for i in range(6):   # stickers, a timetable sheet
            x = rk.uniform(-380, 300); z = rk.uniform(700, 1100)
            col = rk.choice(((0.85, 0.75, 0.10), (0.15, 0.45, 0.70), (0.80, 0.25, 0.30), (0.20, 0.60, 0.35), (0.9, 0.9, 0.88)))
            st_ = bx('sticker', -35, 35, LY - 1.2, LY - 0.8, -25, 25, plastic('sticker%d' % i, col, rough=0.3)); st_.location = (x, 0, z); st_.rotation_euler.y = math.radians(rk.uniform(-25, 25))
        bx('timetable', 120, 330, LY - 1.5, LY - 1.0, 1200, 1490, paper('timetable', (0.86, 0.85, 0.80), seed=4, grime=0.2, lines=(14.0, 'Z', (0.3, 0.3, 0.35))))
        # folding drying rack with towels against the left wall
        rack = metal('rack_steel', (0.80, 0.80, 0.78), 0.3, marks=None, grime=0.4)
        RX, RY = X0 + 260, S.get('rack_y', -1900)
        for dy in (-420, 420):
            tube('rack_leg', [(RX - 220, RY + dy, 0), (RX, RY + dy, 1000), (RX + 220, RY + dy, 0)], 7, rack, smooth_pts=False)
        for k in range(-3, 4):
            tube('rack_bar', [(RX + k * 30, RY - 430, 1000 - abs(k) * 120), (RX + k * 30, RY + 430, 1000 - abs(k) * 120)], 4, rack, smooth_pts=False)
        towel = [plastic('towel%d' % i, col, rough=0.95, seed=i, grime=0.2, sheen_scuffs=0.0) for i, col in enumerate(((0.55, 0.15, 0.12), (0.12, 0.25, 0.45), (0.80, 0.78, 0.70)))]
        for i, (k, y0, y1) in enumerate(((0, -380, -40), (-2, 0, 380), (2, -300, 200))):
            zt = 1000 - abs(k) * 120
            bx('towel', RX + k * 30 - 6, RX + k * 30 + 6, RY + y0, RY + y1, zt - 520, zt + 4, towel[i], bev=3)
    # LED downlights (motion sensor: on at this hour) and the dawn through the window
    led = emissive('led_disc', (1.0, 0.94, 0.86), 60.0)
    trim = plastic('led_trim', (0.85, 0.85, 0.84), rough=0.3, grime=0.1)
    for y in S.get('downlights', (2000, 200, -1600, -3400, -5200)):
        cyl('led_trim', 85, 8, (0, y, CEIL - 4), verts=48).data.materials.append(trim)
        cyl('led', 70, 4, (0, y, CEIL - 8), verts=48).data.materials.append(led)
        bpy.ops.object.light_add(type='SPOT', location=(0, y, CEIL - 60)); L = bpy.context.object; L.name = 'led%d' % y
        L.data.energy = S.get('led_w', 1.6e7) * (S.get('led_near', 1.6) if y > 1500 else S.get('led_far', 0.45)); L.data.color = (1.0, 0.92, 0.82); L.data.shadow_soft_size = 60
        L.data.spot_size = math.radians(S.get('spot_deg', 110)); L.data.spot_blend = 0.35
    world_hdri(0.004, 'interior.exr', sat=0.3)
    a = aim('aim_win', (700, (WIN[0] + WIN[1]) / 2 - 300, 0))
    wl = area_light('window_dawn', (X0 - 1200, (WIN[0] + WIN[1]) / 2, 2000), a, 1300, S.get('dawn_w', 6.0e7), dawn[0], size_y=1300)
    wl.visible_camera = False; wl.visible_glossy = False
    return {'door': [(DX0, LY, DTOP), (DX1, LY, DTOP), (DX1, LY, 0), (DX0, LY, 0)],
            'cylinder': [(HX - 30, LY - 10, HZ - 150), (HX + 30, LY - 10, HZ - 150), (HX + 30, LY - 10, HZ - 210), (HX - 30, LY - 10, HZ - 210)]}


def kit_vault():
    """The museum's vault room under the port warehouse (job.museum_time_lock): a whitewashed brick barrel vault,
    polished concrete, exhibition track spots; at the end the old savings bank's vault door (dark green, nickel
    handwheel and hinges) with the time-lock movement behind a round inspection glass, a rope barrier on steel
    posts, a transport crate with the curator's cotton gloves and the transfer protocol."""
    S = J.get('vault', {})
    FY = 3000; HW_ = S.get('half_width', 1550); X0, X1 = -HW_, HW_; SPRING = S.get('spring', 2350); R0 = (X1 - X0) / 2
    floor = ph('vault_floor', 'workshop_concrete', scale=1600, metallic=0.0, base=(0.30, 0.29, 0.27), base_mix=0.55,
               rough_add=-0.25, coat=0.5, bump=0.25, grime=0.8, wear=0.2)
    bx('floor', X0, X1, -9000, FY, -40, 0, floor)
    side = brick_wall('vault_side', brick=(0.40, 0.19, 0.11), wash=(0.74, 0.71, 0.64), wash_amt=0.25, seed=3, axis='X')
    endw = brick_wall('vault_end', brick=(0.40, 0.19, 0.11), wash=(0.74, 0.71, 0.64), wash_amt=0.12, seed=5, axis='Y')
    bx('lwall', X0 - 400, X0, -9000, FY + 400, 0, SPRING, side)
    bx('rwall', X1, X1 + 400, -9000, FY + 400, 0, SPRING, side)
    # barrel vault: a half tube along y, limewashed (brick shows through the wash only on the walls)
    vm = lime_wall('vault_lime', (0.70, 0.67, 0.60), seed=17, dirt=0.8, cracks=0.6)
    VL = FY + 400 + 9000; VC = (FY + 400 - 9000) / 2
    v = cyl('vault', R0 + 300, VL, (0, VC, SPRING), axis='Y', verts=96)
    cut(v, cyl('vault_in', R0, VL + 200, (0, VC, SPRING), axis='Y', verts=96))
    cut(v, bx('vault_low', -9000, 9000, -20000, 20000, -9000, SPRING))
    setmat(v, vm)
    # end wall with the door opening; the vault door sits in a riveted steel frame
    DX0, DX1, DZ1 = -760, 760, 2120
    ew = bx('end_wall', X0, X1, FY, FY + 400, 0, SPRING + R0 + 300, endw)
    cut(ew, bx('door_hole', DX0 - 160, DX1 + 160, FY - 10, FY + 410, -10, DZ1 + 160))
    bx('behind', X0, X1, -9100, -9000, 0, SPRING + R0, endw)
    green = paint('vault_green', tuple(S.get('door', (0.025, 0.07, 0.05))), rough=0.36, metal_col=(0.42, 0.42, 0.40), chip=0.35, grime=0.6)
    frame_m = paint('vault_frame', (0.03, 0.035, 0.035), rough=0.4, metal_col=(0.45, 0.45, 0.44), chip=0.45, grime=0.7)
    nickel = metal('vault_nickel', (0.64, 0.63, 0.60), 0.24, marks='turn', marks_axis=(0, 1, 0), wear=0.3, grime=0.5, smudge=0.6)
    FL = FY - 40
    for (a, b_, c, d) in ((DX0 - 160, DX0, 0, DZ1 + 160), (DX1, DX1 + 160, 0, DZ1 + 160), (DX0 - 160, DX1 + 160, DZ1, DZ1 + 160)):
        bx('vframe', a, b_, FL - 30, FY + 40, c, d, frame_m, bev=6)
    for z in range(120, DZ1 + 100, 160):   # rivets round the frame
        for x in (DX0 - 80, DX1 + 80):
            bpy.ops.mesh.primitive_uv_sphere_add(radius=13, segments=16, ring_count=8, location=(x, FL - 30, z)); r_ = bpy.context.object; r_.scale.y = 0.5; setmat(r_, frame_m)
    for x in range(DX0 - 80, DX1 + 81, 160):
        bpy.ops.mesh.primitive_uv_sphere_add(radius=13, segments=16, ring_count=8, location=(x, FL - 30, DZ1 + 80)); r_ = bpy.context.object; r_.scale.y = 0.5; setmat(r_, frame_m)
    # the door: a stepped slab, two framed panels, nickel edge band
    bx('door_slab', DX0 + 6, DX1 - 6, FL - 140, FL, 6, DZ1 - 6, green, bev=8)
    bx('door_step', DX0 + 70, DX1 - 70, FL - 175, FL - 140, 70, DZ1 - 70, green, bev=10)
    for (a, b_, c, d) in ((DX0 + 140, DX1 - 140, 1250, DZ1 - 150), (DX0 + 140, DX1 - 140, 150, 820)):
        for (p, q, r2, s2) in ((a, b_, d - 22, d), (a, b_, c, c + 22), (a, a + 22, c, d), (b_ - 22, b_, c, d)):
            bx('panel_bead', p, q, FL - 190, FL - 175, r2, s2, nickel, bev=3)
    for zc in (380, 1760):   # hinge barrels on the left
        cyl('hinge', 70, 300, (DX0 - 20, FL - 120, zc), verts=48).data.materials.append(nickel)
        cyl('hinge_cap', 74, 20, (DX0 - 20, FL - 120, zc + 160), verts=48).data.materials.append(nickel)
    # handwheel: hub and five spokes with knobs
    HW = Vector((140, FL - 190, 1040))
    cyl_y('hub', 70, HW.y - 70, HW.y, HW.x, HW.z, nickel, verts=48, bev=6)
    cyl_y('hub_boss', 40, HW.y - 110, HW.y - 70, HW.x, HW.z, nickel, verts=32, bev=4)
    for k in range(5):
        a = 2 * math.pi * k / 5 + 0.3
        e = HW + Vector((math.cos(a) * 300, -60, math.sin(a) * 300))
        tube('spoke', [HW + Vector((0, -60, 0)), e], 14, nickel, res=4, smooth_pts=False)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=34, segments=24, ring_count=12, location=e); setmat(bpy.context.object, nickel)
    # the time lock's inspection glass: two movement dials behind a round nickel bezel (left of the handwheel)
    TL = Vector((-330, FL - 190, 1560))
    lathe_open('bezel', [(110, 0), (130, 0), (132, -18), (112, -26)], x=0, y=0, seg=64, thick=0, mat=nickel).matrix_world = Matrix.Translation(TL) @ Matrix.Rotation(math.radians(90), 4, 'X')
    cyl_y('tl_back', 112, TL.y + 5, TL.y + 40, TL.x, TL.z, metal('tl_brass', (0.70, 0.55, 0.32), 0.3, marks='turn', marks_axis=(0, 1, 0), wear=0.3, grime=0.6), verts=64)
    face = paper('tl_face', (0.82, 0.80, 0.72), seed=12, grime=0.4)
    for dx in (-48, 48):
        cyl_y('tl_dial', 40, TL.y - 2, TL.y + 4, TL.x + dx, TL.z, face, verts=48)
        for k in range(12):
            a = 2 * math.pi * k / 12
            t_ = bx('tl_tick', -1.2, 1.2, 0, 1, 30, 37, black_plastic); t_.location = (TL.x + dx, TL.y - 3, TL.z); t_.rotation_euler = (0, a, 0)
        h_ = bx('tl_hand', -2, 2, 0, 1, 0, 30, black_plastic); h_.location = (TL.x + dx, TL.y - 4, TL.z); h_.rotation_euler = (0, math.radians(200 if dx < 0 else 30), 0)
    cyl_y('tl_glass', 112, TL.y - 22, TL.y - 20, TL.x, TL.z, glass('tl_glass', (0.95, 0.96, 0.95), rough=0.02, dirt=0.5), verts=64)
    # keyhole covers and a blank maker's plate (no text)
    for x in (380, 470):
        cyl_y('kh_cover', 26, FL - 186, FL - 176, x, 1040, nickel, verts=32, bev=2)
    bx('maker_plate', -230, 230, FL - 182, FL - 176, 1900, 1990, nickel, bev=3)
    # rope barrier on steel posts, a transport crate with gloves and the protocol
    post_m = metal('post_steel', (0.12, 0.12, 0.12), 0.3, marks='turn', marks_axis=(0, 0, 1), wear=0.2, grime=0.4, metallic=0.6)
    rope_m = plastic('rope', (0.22, 0.03, 0.035), rough=0.75, seed=3, grime=0.3, sheen_scuffs=0.0)
    rope_m.node_tree.nodes['Principled BSDF'].inputs['Sheen Weight'].default_value = 0.6
    posts = S.get('posts', [(-350, 1900), (1250, 1900)])
    for (px, py) in posts:
        cyl('post_base', 160, 30, (px, py, 15), verts=48).data.materials.append(post_m)
        cyl('post', 24, 900, (px, py, 470), verts=32).data.materials.append(post_m)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=36, location=(px, py, 940)); setmat(bpy.context.object, post_m)
    for (a, b2) in zip(posts, posts[1:]):
        mid = ((a[0] + b2[0]) / 2, (a[1] + b2[1]) / 2, 700)
        tube('rope', [(a[0], a[1], 880), mid, (b2[0], b2[1], 880)], 16, rope_m, res=4)
    crate_w = oak('crate', light=(0.62, 0.50, 0.33), dark=(0.42, 0.32, 0.18), axis='X', seed=61, ring=1.6, coat=0.0, rough=0.8, wear=0.3)
    CX, CY = S.get('crate', (-1000, 1900))
    for k in range(4):   # slatted crate
        bx('crate_slat', CX - 450, CX + 450, CY - 350, CY + 350, k * 150, k * 150 + 130, crate_w, bev=4)
    bx('crate_lid', CX - 470, CX + 470, CY - 370, CY + 370, 600, 625, crate_w, bev=4)
    folder = paper('protocol', (0.75, 0.72, 0.62), seed=21, grime=0.2)
    f_ = bx('protocol', -150, 150, -105, 105, 0, 6, folder, bev=1); f_.matrix_world = Matrix.Translation((CX - 120, CY - 40, 626)) @ Matrix.Rotation(math.radians(12), 4, 'Z')
    glove = plastic('cotton_glove', (0.86, 0.85, 0.80), rough=0.9, seed=9, grime=0.15, sheen_scuffs=0.0)
    glove.node_tree.nodes['Principled BSDF'].inputs['Sheen Weight'].default_value = 0.8
    for k, (gx, gy, ga) in enumerate(((CX + 180, CY - 60, -20), (CX + 250, CY + 70, 25))):
        parts = [bx('palm', -50, 50, -60, 60, 0, 18, glove, bev=8)]
        for i in range(4):
            parts.append(tube('finger', [(-36 + i * 24, 55, 9), (-38 + i * 25, 120 + (i % 3) * 8, 8)], 9, glove, res=3, smooth_pts=False))
        parts.append(tube('thumb', [(46, 10, 9), (90, 50, 8)], 10, glove, res=3, smooth_pts=False))
        group('glove', parts, Matrix.Translation((gx, gy, 627)) @ Matrix.Rotation(math.radians(ga), 4, 'Z'))
    # exhibition track with warm spots on the door; a high basement window with grey daylight on the left
    track = metal('track', (0.04, 0.04, 0.04), 0.4, marks=None, metallic=0.3)
    TZ = SPRING + R0 - 180
    bx('track', -25, 25, -6000, FY - 200, TZ - 25, TZ, track)
    spot_m = metal('spot_body', (0.05, 0.05, 0.05), 0.35, marks=None, metallic=0.3)
    for (sy, aimp, w) in S.get('spots', [((FY - 1900), (0, FY, 900), 1.1e8), ((FY - 2900), (-330, FY, 1560), 5e7), (-600, (-1000, 1900, 600), 3e7), (-4200, (0, -2500, 0), 3e7)]):
        cyl('spot_can', 55, 160, (0, sy, TZ - 120), verts=32).data.materials.append(spot_m)
        ap = aim('spot_aim', aimp)
        bpy.ops.object.light_add(type='SPOT', location=(0, sy, TZ - 210)); L = bpy.context.object
        L.data.energy = w; L.data.color = (1.0, 0.80, 0.58); L.data.spot_size = math.radians(S.get('spot_deg', 40)); L.data.spot_blend = 0.45
        L.data.shadow_soft_size = 25
        c = L.constraints.new('TRACK_TO'); c.target = ap; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
    # cove: warm LED strips on the springing line wash the limewashed vault from below (museum lighting)
    for sx in (-1, 1):
        ap = aim('cove_aim', (-sx * HW_ * 0.4, (FY - 9000) / 2, SPRING + R0))
        cl = area_light('cove', (sx * (HW_ - 60), (FY - 9000) / 2 + 600, SPRING - 40), ap, 60, S.get('cove_w', 4e7), (1.0, 0.78, 0.52), size_y=11000)
        cl.data.shape = 'RECTANGLE'; cl.data.size = 60; cl.data.size_y = 11000
        cl.constraints.clear(); cl.rotation_euler = (0, math.radians(sx * 60), 0)
        cl.visible_camera = False; cl.visible_glossy = False
        bx('cove_strip', sx * HW_ - (60 if sx > 0 else -60) - 15, sx * HW_ - (60 if sx > 0 else -60) + 15, -9000, FY, SPRING - 60, SPRING - 30, track)
    WIN = S.get('window', (-3600, -2200))
    wcut = bx('bwin_cut', X0 - 500, X0 + 10, WIN[0], WIN[1], SPRING - 700, SPRING - 120)
    cut(bpy.data.objects['lwall'], wcut)
    bx('bwin_glass', X0 - 300, X0 - 295, WIN[0], WIN[1], SPRING - 700, SPRING - 120, glass('bwin', (0.7, 0.72, 0.72), rough=0.25, dirt=0.8)).visible_shadow = False
    bx('bwin_sky', X0 - 3000, X0 - 2990, WIN[0] - 4000, WIN[1] + 4000, SPRING - 3000, SPRING + 3000, emissive('bwin_day', (0.75, 0.80, 0.88), 3.0, (0, 0, 0)))
    a = aim('aim_bwin', (0, (WIN[0] + WIN[1]) / 2 + 600, 0))
    wl = area_light('basement_day', (X0 - 900, (WIN[0] + WIN[1]) / 2, SPRING - 400), a, 1400, S.get('day_w', 1.2e8), (0.80, 0.86, 0.96), size_y=600)
    wl.visible_camera = False; wl.visible_glossy = False
    world_hdri(0.004, 'interior.exr', sat=0.3)
    return {'door': [(DX0, FL - 140, DZ1), (DX1, FL - 140, DZ1), (DX1, FL - 140, 0), (DX0, FL - 140, 0)],
            'time_lock': [(TL.x - 130, TL.y, TL.z + 130), (TL.x + 130, TL.y, TL.z + 130), (TL.x + 130, TL.y, TL.z - 130), (TL.x - 130, TL.y, TL.z - 130)]}


# ================================================================ facade kit (old-town street fronts, D-108)
def granite(name, base=(0.36, 0.35, 0.34), rough=0.55, seed=0.0, pink=0.25):
    """Grey granite: quartz/feldspar/mica speckle at grain scale, a cloudy tone over the stone, sawn-and-worn top."""
    m, nt, l, b, P = _new(name)
    big = _noise(nt, P, 0.006 + seed * 0.0003, detail=4, rough=0.6)
    col = _mix(nt, (*[c * 0.82 for c in base], 1), (*[min(1, c * 1.12) for c in base], 1), big)
    sp1 = _maprange(nt, _noise(nt, P, 0.35 + seed * 0.01, detail=2, rough=0.4), 0.62, 0.66)      # black mica
    sp2 = _maprange(nt, _noise(nt, P, 0.22 + seed * 0.01, detail=2, rough=0.4), 0.30, 0.34, 1, 0)  # white quartz
    sp3 = _maprange(nt, _noise(nt, P, 0.15 + seed * 0.02, detail=2, rough=0.4), 0.64, 0.70, 0, pink)
    col = _mix(nt, col, (0.05, 0.05, 0.05, 1), sp1)
    col = _mix(nt, col, (0.72, 0.71, 0.68, 1), _math(nt, 'MULTIPLY', sp2, 0.6))
    col = _mix(nt, col, (0.55, 0.33, 0.26, 1), sp3)
    cm = _maprange(nt, _cavity_mask(nt, 6.0, 0.4, 0.95), 0, 1, 0, 0.6)
    col = _mix(nt, col, (0.05, 0.045, 0.04, 1), cm)
    l.new(col, b.inputs['Base Color'])
    l.new(_maprange(nt, big, 0.3, 0.7, rough * 0.85, rough * 1.15), b.inputs['Roughness'])
    h = _mix(nt, _noise(nt, P, 0.08, detail=6, rough=0.7), sp1, 0.2, dtype='FLOAT')
    l.new(_bump(nt, h, 0.35, 0.8), b.inputs['Normal'])
    return m


def wetten(mat, rough_k=0.45, dark=0.72):
    """Rain: darker albedo and a glossier surface (scales whatever already drives Base Color / Roughness)."""
    if not mat or not mat.use_nodes or 'Principled BSDF' not in mat.node_tree.nodes: return mat
    nt = mat.node_tree; b = nt.nodes['Principled BSDF']
    for sock, k, kind in ((b.inputs['Roughness'], rough_k, 'FLOAT'), (b.inputs['Base Color'], dark, 'RGBA')):
        if kind == 'FLOAT':
            mm = nt.nodes.new('ShaderNodeMath'); mm.operation = 'MULTIPLY'; mm.inputs[1].default_value = k
            if sock.is_linked:
                src = sock.links[0].from_socket; nt.links.new(src, mm.inputs[0])
            else:
                mm.inputs[0].default_value = sock.default_value
            nt.links.new(mm.outputs[0], sock)
        else:
            mm = nt.nodes.new('ShaderNodeMix'); mm.data_type = 'RGBA'; mm.blend_type = 'MULTIPLY'; mm.inputs['Factor'].default_value = 1.0
            mm.inputs[7].default_value = (dark, dark, dark, 1)
            if sock.is_linked:
                nt.links.new(sock.links[0].from_socket, mm.inputs[6])
            else:
                mm.inputs[6].default_value = sock.default_value
            nt.links.new(mm.outputs[2], sock)
    return mat


def puddles(mat, scale=0.0009, cover=0.5, seed=0.0):
    """Puddles on a wet surface: a world-space noise mask; inside it the surface goes mirror-smooth, darker and flat."""
    if not mat or not mat.use_nodes or 'Principled BSDF' not in mat.node_tree.nodes: return mat
    nt = mat.node_tree; b = nt.nodes['Principled BSDF']; l = nt.links
    tc = nt.nodes.new('ShaderNodeTexCoord')
    mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (seed * 13.1, seed * 7.7, 0); l.new(tc.outputs['Object'], mp.inputs['Vector'])
    nz = nt.nodes.new('ShaderNodeTexNoise'); nz.inputs['Scale'].default_value = scale; nz.inputs['Detail'].default_value = 6; nz.inputs['Roughness'].default_value = 0.62
    l.new(mp.outputs['Vector'], nz.inputs['Vector'])
    mask = _maprange(nt, nz.outputs['Fac'], 1.0 - cover * 0.55, 1.0 - cover * 0.55 + 0.035)
    for sock, val in ((b.inputs['Roughness'], 0.015),):
        mx = nt.nodes.new('ShaderNodeMix'); mx.data_type = 'FLOAT'; l.new(mask, mx.inputs['Factor'])
        if sock.is_linked: l.new(sock.links[0].from_socket, mx.inputs[2])
        else: mx.inputs[2].default_value = sock.default_value
        mx.inputs[3].default_value = val; l.new(mx.outputs[0], sock)
    sc = b.inputs['Base Color']
    mc = nt.nodes.new('ShaderNodeMix'); mc.data_type = 'RGBA'; mc.blend_type = 'MULTIPLY'; l.new(mask, mc.inputs['Factor'])
    if sc.is_linked: l.new(sc.links[0].from_socket, mc.inputs[6])
    else: mc.inputs[6].default_value = sc.default_value
    mc.inputs[7].default_value = (0.45, 0.45, 0.45, 1); l.new(mc.outputs[2], sc)
    if b.inputs['Normal'].is_linked:   # still water is flat: the bump fades out inside the puddle
        nm = nt.nodes.new('ShaderNodeMix'); nm.data_type = 'VECTOR'; l.new(mask, nm.inputs['Factor'])
        l.new(b.inputs['Normal'].links[0].from_socket, nm.inputs[4])
        geo = nt.nodes.new('ShaderNodeNewGeometry'); l.new(geo.outputs['Normal'], nm.inputs[5]); l.new(nm.outputs[1], b.inputs['Normal'])
    b.inputs['Coat Weight'].default_value = max(b.inputs['Coat Weight'].default_value, 0.0)
    return mat


def water_mat(name='rain_water'):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (0.02, 0.022, 0.024, 1); b.inputs['Roughness'].default_value = 0.025
    b.inputs['Transmission Weight'].default_value = 1.0; b.inputs['IOR'].default_value = 1.33
    return m


def height_field(x, y, seed, amp):
    """Settled paving: a smooth, seeded low-frequency field (mm, <= 0), so puddles gather in patches."""
    s = seed * 0.37
    f = (math.sin(x * 0.0011 + s) * math.cos(y * 0.0009 - s * 1.3) + 0.6 * math.sin(x * 0.0023 - y * 0.0017 + s * 2.1)
         + 0.4 * math.cos(x * 0.0041 + y * 0.0033 + s))
    return -amp * max(0.0, f * 0.5 + 0.15)


def setts(name, x0, x1, y0, y1, mats, size=(105, 105), gap=8, seed=1, settle=9.0, fan=0.0):
    """Granite setts in courses along x (half-bond), each stone with its own height, tilt and size, joints filled
    with dark sand; `settle` mm: depth of the settled patches (puddles stand there when it rains)."""
    rr = random.Random(seed); items = []
    w0, d0 = size; y = y0; row = 0
    while y < y1:
        d = d0 * rr.uniform(0.9, 1.1); x = x0 - (w0 * 0.5 if row % 2 else 0) - rr.uniform(0, 30)
        while x < x1:
            w = w0 * rr.uniform(0.7, 1.35)
            cx, cy = x + w / 2, y + d / 2
            top = height_field(cx, cy, seed, settle) + rr.uniform(-2.5, 2.5)
            M = (Matrix.Translation((cx, cy, top - 45)) @ Matrix.Rotation(rr.uniform(-0.09, 0.09), 4, 'Z') @
                 Matrix.Rotation(rr.uniform(-0.05, 0.05), 4, 'X') @ Matrix.Rotation(rr.uniform(-0.05, 0.05), 4, 'Y') @
                 Matrix.Diagonal(((w - gap) * 0.5, (d - gap) * 0.5, 45, 1)))
            items.append((lambda bm: bmesh.ops.create_cube(bm, size=2.0), M, rr.randrange(len(mats))))
            x += w
        y += d; row += 1
    o = scatter(name, items, mats)
    md = o.modifiers.new('bev', 'BEVEL'); md.width = 7; md.segments = 2; md.limit_method = 'ANGLE'; md.angle_limit = math.radians(40)
    return o


def flags_slabs(name, x0, x1, y0, y1, mats, size=(600, 400), gap=7, seed=2, settle=4.0):
    rr = random.Random(seed); items = []
    w, d = size; y = y0; row = 0
    while y < y1:
        x = x0 - (w * 0.5 if row % 2 else 0)
        while x < x1:
            cx, cy = x + w / 2, y + d / 2
            top = height_field(cx, cy, seed, settle) + rr.uniform(-1.5, 1.0)
            M = (Matrix.Translation((cx, cy, top - 30)) @ Matrix.Rotation(rr.uniform(-0.004, 0.004), 4, 'Z') @
                 Matrix.Diagonal(((w - gap) * 0.5, (d - gap) * 0.5, 30, 1)))
            items.append((lambda bm: bmesh.ops.create_cube(bm, size=2.0), M, rr.randrange(len(mats))))
            x += w
        y += d; row += 1
    o = scatter(name, items, mats)
    md = o.modifiers.new('bev', 'BEVEL'); md.width = 4; md.segments = 2; md.limit_method = 'ANGLE'; md.angle_limit = math.radians(40)
    return o


def panel_leaf(name, x0, x1, y, z0, z1, mat, panels, depth=50, bead=22, proud=12):
    """A framed-and-panelled timber leaf: the slab plus raised panel fields with mouldings (stiles/rails proud)."""
    out = [bx(name, x0, x1, y, y + depth, z0, z1, mat, bev=3)]
    for (a, b_, c, d) in panels:
        for (p, q, r_, s_) in ((a, b_, d - bead, d), (a, b_, c, c + bead), (a, a + bead, c, d), (b_ - bead, b_, c, d)):
            out.append(bx(name + '_bead', p, q, y - proud, y, r_, s_, mat, bev=4))
        out.append(bx(name + '_field', a + bead + 25, b_ - bead - 25, y - proud * 0.6, y, c + bead + 25, d - bead - 25, mat, bev=8))
    return out


def window(wall, x0, x1, z0, z1, FY, depth, frame_m, glass_m, lit, rr, panes=(2, 3), sill_m=None, room_c=(1.0, 0.70, 0.40),
           curtain=None, bars=None, hood=None, glow=1.4):
    """Window in a cut opening: reveal, timber frame with casements and glazing bars, glass, a room behind it
    (warm and lit, or dark) with a sheer curtain, stone sill; optional iron bars and a moulded hood."""
    cut(wall, bx('wcut', x0, x1, FY - 400, FY + 1200, z0, z1))
    fy = FY + depth * 0.45
    for (a, b_, c, d) in ((x0, x0 + 70, z0, z1), (x1 - 70, x1, z0, z1), (x0, x1, z0, z0 + 80), (x0, x1, z1 - 70, z1)):
        bx('wframe', a, b_, fy, fy + 70, c, d, frame_m, bev=4)
    cx = (x0 + x1) / 2
    bx('wmull', cx - 30, cx + 30, fy - 10, fy + 60, z0 + 80, z1 - 70, frame_m, bev=3)
    tz = z1 - 70 - (z1 - z0) * 0.24
    bx('wtransom', x0 + 70, x1 - 70, fy - 10, fy + 60, tz - 30, tz + 30, frame_m, bev=3)
    nx, nz = panes
    for side in ((x0 + 70, cx - 30), (cx + 30, x1 - 70)):
        for k in range(1, nx):
            xx = side[0] + (side[1] - side[0]) * k / nx
            bx('wbar', xx - 12, xx + 12, fy + 15, fy + 45, z0 + 80, tz - 30, frame_m, bev=2)
        for k in range(1, nz):
            zz = z0 + 80 + (tz - 30 - z0 - 80) * k / nz
            bx('wbar', side[0], side[1], fy + 15, fy + 45, zz - 12, zz + 12, frame_m, bev=2)
    g = bx('wglass', x0 + 60, x1 - 60, fy + 30, fy + 34, z0 + 70, z1 - 60, glass_m); g.visible_shadow = False
    if lit:   # a lit room: a lamp-side glow falling off across the back wall, a dark piece of furniture in front of it
        room_m = bpy.data.materials.new('room_lit'); room_m.use_nodes = True; nt = room_m.node_tree; nt.nodes.clear()
        tc = nt.nodes.new('ShaderNodeTexCoord'); gr = nt.nodes.new('ShaderNodeTexGradient'); gr.gradient_type = 'SPHERICAL'
        mpp = nt.nodes.new('ShaderNodeMapping'); s_ = 1.0 / ((x1 - x0) * 1.3)
        mpp.inputs['Scale'].default_value = (s_, s_, s_); mpp.inputs['Location'].default_value = (-(x0 + rr.uniform(0.1, 0.9) * (x1 - x0)) * s_, 0, -(z1 - 200) * s_)
        nt.links.new(tc.outputs['Object'], mpp.inputs['Vector']); nt.links.new(mpp.outputs['Vector'], gr.inputs['Vector'])
        em = nt.nodes.new('ShaderNodeEmission'); em.inputs['Color'].default_value = (*room_c, 1)
        mm = nt.nodes.new('ShaderNodeMath'); mm.operation = 'MULTIPLY'; mm.inputs[1].default_value = glow * rr.uniform(1.2, 2.0)
        pw = nt.nodes.new('ShaderNodeMath'); pw.operation = 'POWER'; pw.inputs[1].default_value = 1.6
        nt.links.new(gr.outputs['Fac'], pw.inputs[0]); nt.links.new(pw.outputs[0], mm.inputs[0]); nt.links.new(mm.outputs[0], em.inputs['Strength'])
        out = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(em.outputs[0], out.inputs['Surface'])
        if rr.random() < 0.7:
            fx = rr.uniform(x0, x1 - 500)
            bx('wfurniture', fx, fx + rr.uniform(400, 900), fy + 600, fy + 700, z0 - 300, z0 + rr.uniform(300, 1500), dark_mat('furn', (0.03, 0.025, 0.02), 0.8))
    else:
        room_m = dark_mat('room_dark', (0.025, 0.024, 0.024), 0.9)
    bx('wroom', x0 - 400, x1 + 400, fy + 900, fy + 920, z0 - 300, z1 + 300, room_m)
    if curtain is not None:   # sheers drawn to the sides, a gap in the middle
        gap = rr.uniform(0.15, 0.4) * (x1 - x0)
        mid = (x0 + x1) / 2 + rr.uniform(-0.1, 0.1) * (x1 - x0)
        bx('wcurtain', x0 + 80, mid - gap / 2, fy + 120, fy + 124, z0 + 90, z1 - 80, curtain)
        bx('wcurtain', mid + gap / 2, x1 - 80, fy + 130, fy + 134, z0 + 90, z1 - 80, curtain)
    if sill_m:
        bx('wsill', x0 - 60, x1 + 60, FY - 70, fy + 10, z0 - 60, z0, sill_m, bev=6)
    if bars:
        for k in range(5):
            xx = x0 + 60 + (x1 - x0 - 120) * (k + 0.5) / 5
            tube('wbar_iron', [(xx, FY - 40, z0 + 20), (xx, FY - 40, z1 - 20)], 11, bars, smooth_pts=False)
        for zz in (z0 + 300, z1 - 300):
            bx('wbar_h', x0 + 40, x1 - 40, FY - 55, FY - 30, zz - 15, zz + 15, bars, bev=3)
    if hood:
        bx('whood', x0 - 120, x1 + 120, FY - 90, FY, z1 + 40, z1 + 150, hood, bev=12)
        bx('whood_top', x0 - 160, x1 + 160, FY - 130, FY, z1 + 150, z1 + 200, hood, bev=12)
        for xx in (x0 - 120, x1 + 50):
            bx('wear', xx, xx + 70, FY - 50, FY, z0 - 20, z1 + 40, hood, bev=8)


def lantern(name, x, y, z, glow, iron_m, arm=380, hang=0):
    """A wall lantern on a wrought bracket (or, hang > 0, hung on a rod of that length from a vault/arch crown):
    four-sided cage, opal panes, a warm lamp inside."""
    if hang:
        cx, cy, cz = x, y, z
        tube(name + '_rod', [(cx, cy, cz + 300), (cx, cy, cz + 300 + hang)], 10, iron_m, smooth_pts=False)
        bpy.ops.mesh.primitive_torus_add(major_radius=30, minor_radius=6, location=(cx, cy, cz + 300), rotation=(math.radians(90), 0, 0))
        setmat(bpy.context.object, iron_m)
    else:
        tube(name + '_arm', [(x, y, z + 300), (x, y - arm * 0.6, z + 330), (x, y - arm, z + 260), (x, y - arm, z + 180)], 12, iron_m)
        tube(name + '_brace', [(x, y, z), (x, y - arm * 0.55, z + 250)], 9, iron_m)
        bx(name + '_plate', x - 60, x + 60, y - 12, y, z - 40, z + 340, iron_m, bev=4)
        cx, cy, cz = x, y - arm, z - 30
    bx(name + '_cap', cx - 120, cx + 120, cy - 120, cy + 120, cz + 180, cz + 210, iron_m, bev=6)
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=150, radius2=20, depth=110, location=(cx, cy, cz + 265), rotation=(0, 0, math.pi / 4))
    setmat(bpy.context.object, iron_m)
    bx(name + '_base', cx - 95, cx + 95, cy - 95, cy + 95, cz - 210, cz - 185, iron_m, bev=4)
    for sx in (-1, 1):
        for sy in (-1, 1):
            bx(name + '_post', cx + sx * 95 - 9, cx + sx * 95 + 9, cy + sy * 95 - 9, cy + sy * 95 + 9, cz - 200, cz + 185, iron_m)
    pane = opal_glass(name + '_opal', glow=glow, color=(1.0, 0.78, 0.48))
    for (a, b_, c, d) in ((cx - 92, cx + 92, cy - 94, cy - 90), (cx - 92, cx + 92, cy + 90, cy + 94)):
        bx(name + '_pane', a, b_, c, d, cz - 185, cz + 180, pane)
    for (a, b_) in ((cx - 94, cx - 90), (cx + 90, cx + 94)):
        bx(name + '_pane', a, b_, cy - 92, cy + 92, cz - 185, cz + 180, pane)
    for ob in bpy.data.objects:   # the lamp inside shines through the opal panes and the open bottom (no shadow from them)
        if ob.name.startswith((name + '_pane', name + '_base')): ob.visible_shadow = False
    return Vector((cx, cy, cz))


def kit_facade():
    """Old-town street fronts (D-108), one builder dressed per job: `facade.style` = "tenement_gate" (an 1890 Kraków
    tenement, its carriage gate under conservator protection: job.krakow_tenement_gate), "beguinage" (a whitewashed
    house in a Ghent beguinage: job.ghent_beguinage), "townhouse" (a Saint-Gilles townhouse with the balcony above
    the door: job.brussels_townhouse). Facade plane y = FY, street towards the camera (-y)."""
    S = J.get('facade', {}); ST = S.get('style', 'tenement_gate')
    WET = TIME == 'rainy' or S.get('wet', False)
    rr = random.Random(S.get('seed', 7))
    FY = S.get('fy', 1600)
    iron_m = paint('wrought_iron', (0.025, 0.025, 0.025), rough=0.45, metal_col=(0.30, 0.28, 0.26), chip=0.35, grime=0.6)
    gran = [granite('sett%d' % i, base=c, seed=i, rough=0.5) for i, c in
            enumerate(((0.26, 0.25, 0.24), (0.20, 0.20, 0.20), (0.31, 0.28, 0.26), (0.23, 0.24, 0.26), (0.16, 0.155, 0.15), (0.29, 0.27, 0.27)))]
    sand = dark_mat('joint_sand', (0.05, 0.045, 0.035), 0.95)
    # ---------------------------------------------------------------- ground
    PW = S.get('pavement', 1900)                     # pavement depth in front of the facade (0: a cobbled lane)
    bx('sand_bed', -9000, 9000, -14000, FY + 200, -80, -14, sand)
    if PW:
        pav = [ph('flag%d' % i, 'workshop_concrete', scale=1300 + 110 * i, rot=23 * i, metallic=0.0, base=c, base_mix=0.5, tint=(1.0, 0.98, 0.95),
                  rough_add=0.1, bump=1.0, grime=1.0, wear=0.4) for i, c in enumerate(S.get('flag_cols', ((0.36, 0.35, 0.33), (0.31, 0.30, 0.29), (0.40, 0.39, 0.37), (0.27, 0.27, 0.26))))]
        flags_slabs('pavement', -7000, 7000, FY - PW, FY, pav, size=tuple(S.get('flag', (500, 500))), seed=3, settle=S.get('flag_settle', 9.0))
        kerb = granite('kerb', base=(0.38, 0.37, 0.36), seed=21, rough=0.45)
        bx('kerb', -9000, 9000, FY - PW - 220, FY - PW, -200, 20, kerb, bev=12)
        setts('road', -6500, 6500, -13000, FY - PW - 220, gran, size=tuple(S.get('sett', (150, 120))), seed=5, settle=S.get('settle', 11.0))
        bx('road_gutter', -9000, 9000, FY - PW - 520, FY - PW - 220, -120, -16, sand)
    else:
        setts('lane', -6500, 6500, -13000, FY, gran, size=tuple(S.get('sett', (105, 105))), seed=5, settle=S.get('settle', 11.0))
    if WET:
        for k, m_ in enumerate(list(gran) + ([*pav, kerb] if PW else [])):
            wetten(m_, 0.35, 0.62); puddles(m_, S.get('puddle_scale', 0.0008), S.get('puddle_cover', 0.5), seed=S.get('seed', 7))
        wl = bx('water', -9000, 9000, -14000, FY + 100, S.get('water_z', -7.0) - 2, S.get('water_z', -7.0), water_mat())
        wl.visible_shadow = False
    # ---------------------------------------------------------------- facade wall per style
    W0, W1 = S.get('wall_x', (-7000, 7000))
    H = S.get('height', 9000)
    if ST == 'tenement_gate':
        render_m = ph('render', 'wall_lime_plaster', scale=1500, metallic=0.0, base=tuple(S.get('render', (0.56, 0.45, 0.30))), base_mix=S.get('base_mix', 0.5),
                      rough_add=0.05, bump=1.2, grime=1.0, wear=0.2)
        rust_m = ph('rustic', 'wall_lime_plaster', scale=1300, rot=90, metallic=0.0, base=tuple(S.get('rustic', (0.44, 0.40, 0.33))), base_mix=S.get('base_mix', 0.5),
                    rough_add=0.05, bump=1.3, grime=1.0, wear=0.3)
        stone = granite('plinth_stone', base=(0.30, 0.29, 0.28), seed=31, rough=0.6, pink=0.05)
        GF = 4300                                     # ground floor height (rusticated)
        wall = bx('wall_up', W0, W1, FY, FY + 600, GF, H, render_m)
        gwall = bx('wall_gf', W0, W1, FY - 20, FY + 600, 0, GF, rust_m)
        for z in range(650, GF, 380):                 # rustication grooves
            cut(gwall, bx('groove', W0 - 10, W1 + 10, FY - 40, FY - 2, z - 14, z + 14))
        bx('plinth', W0, W1, FY - 50, FY + 600, -40, 600, stone, bev=10)
        # where the render has spalled off: brick behind, broken edges
        brick_m = brick_wall('core_brick', brick=(0.40, 0.17, 0.09), wash=(0.55, 0.50, 0.42), wash_amt=0.1, seed=12)
        for (px, pz, pw, ph_) in S.get('spalls', ((2150, 900, 520, 330),)):
            bx('spall_brick', px - pw, px + pw, FY - 8, FY + 40, pz - ph_, pz + ph_, brick_m)
            for k in range(3):
                c_ = bx('spall_cut', -pw * 0.55, pw * 0.55, -60, 18, -ph_ * 0.5, ph_ * 0.5)
                c_.location = (px + (k - 1) * pw * 0.35, FY - 20, pz + (k % 2 - 0.5) * ph_ * 0.4); c_.rotation_euler.y = math.radians(17 * k - 15)
                cut(gwall if pz < GF else wall, c_)
        # cornice band over the ground floor and a sill band
        for (z0, z1, d) in ((GF - 40, GF + 60, 90), (GF + 60, GF + 170, 150), (GF + 170, GF + 210, 190), (GF + 1050, GF + 1110, 70)):
            bx('cornice', W0, W1, FY - d, FY, z0, z1, render_m, bev=10)
        # the carriage gate: arched opening, deep reveal, two panelled oak leaves, a fanlight grille
        GX0, GX1 = S.get('gate_x', (-1300, 1300)); SPR = S.get('spring', 2700); GR = (GX1 - GX0) / 2; GC = (GX0 + GX1) / 2
        arch_cut = bx('gate_cut', GX0, GX1, FY - 400, FY + 700, -50, SPR)
        cyl_cut = cyl('gate_arch_cut', GR, 1100, (GC, FY + 150, SPR), axis='Y', verts=96)
        for w_ in (gwall,):
            cut(w_, arch_cut); cut(w_, cyl_cut)
        cut(bpy.data.objects['plinth'], bx('gate_cut2', GX0, GX1, FY - 400, FY + 700, -50, SPR))
        # stone surround: voussoir band round the arch and jamb blocks
        sur = ph('surround', 'wall_lime_plaster', scale=1600, metallic=0.0, base=(0.62, 0.58, 0.50), base_mix=0.8, rough_add=0.05, bump=0.7, grime=1.0, wear=0.4)
        for k in range(15):
            a0, a1 = 180 - 180 * k / 15, 180 - 180 * (k + 1) / 15
            am = math.radians((a0 + a1) / 2)
            vb = bx('voussoir', -95, 95, -40, 0, 0, 260, sur, bev=8)
            vb.matrix_world = Matrix.Translation((GC + (GR + 5) * math.cos(am), FY - 1, SPR + (GR + 5) * math.sin(am))) @ Matrix.Rotation(-(am - math.pi / 2), 4, 'Y')
        bx('keystone', GC - 140, GC + 140, FY - 70, FY, SPR + GR - 20, SPR + GR + 330, sur, bev=10)
        for (a, b_) in ((GX0 - 260, GX0), (GX1, GX1 + 260)):
            for z in range(0, SPR, 400):
                bx('jamb_block', a + (20 if (z // 400) % 2 else 0), b_ - (0 if (z // 400) % 2 else 20), FY - 40, FY + 20, z + 600 if z == 0 else z, z + 392, sur, bev=8)
        # reveal lining (plaster) and the leaves 450 mm in
        LY = FY + 450
        bx('reveal_l', GX0 - 5, GX0, FY - 20, LY + 100, 0, SPR, render_m); bx('reveal_r', GX1, GX1 + 5, FY - 20, LY + 100, 0, SPR, render_m)
        gate_wood = oak('gate_oak', light=tuple(S.get('wood_light', (0.22, 0.14, 0.075))), dark=tuple(S.get('wood_dark', (0.08, 0.045, 0.022))), axis='Z', seed=71,
                        ring=3.0, coat=0.35, coat_rough=0.45, wear=1.0, grime=1.0)
        half = (GX1 - GX0) / 2
        for k, (a, b_) in enumerate(((GX0 + 4, GC - 3), (GC + 3, GX1 - 4))):
            panel_leaf('gate_leaf%d' % k, a, b_, LY, 10, SPR - 4, gate_wood,
                       [(a + 90, b_ - 90, 1500, SPR - 120), (a + 90, b_ - 90, 160, 1300)], depth=80, bead=36, proud=22)
            # iron studs in a grid on the lower panel frame
            for z in range(240, 1300, 260):
                for x in (a + 50, b_ - 50):
                    bpy.ops.mesh.primitive_uv_sphere_add(radius=16, segments=16, ring_count=8, location=(x, LY - 4, z)); o = bpy.context.object; o.scale.y = 0.5; setmat(o, iron_m)
        bx('meeting_stile', GC - 45, GC + 45, LY - 30, LY, 10, SPR - 4, gate_wood, bev=6)
        for (a, b_) in ((GX0 + 4, GC - 3), (GC + 3, GX1 - 4)):
            bx('kick_strap', a + 10, b_ - 10, LY - 30, LY - 22, 40, 150, iron_m, bev=3)
        stain_decal('gate_weather', 'Y', LY - 31, (GX0, GX1, 0, 900), [(GC, 120, 1500, 380, 0.55), (GC - 600, 500, 300, 400, 0.2)],
                    color=(0.16, 0.15, 0.13), rough=0.9, noise_scale=0.01)
        stain_decal('gate_hands', 'Y', LY - 31, (GC - 400, GC + 500, 800, 1500), [(GC - 180, 1200, 120, 260, 0.35), (GC + 260, 1150, 160, 180, 0.3)],
                    color=(0.03, 0.025, 0.02), rough=0.35, noise_scale=0.03)
        # a phone cable on clips across the facade over the gate, dipping into the reveal
        cab_m = plastic('cable_black', (0.02, 0.02, 0.02), rough=0.35, grime=0.4)
        tube('facade_cable', [(W0, FY - 14, GF - 260), (GX0 - 500, FY - 14, GF - 240), (GX0 - 280, FY - 14, SPR + 300), (GX0 - 280, FY - 14, 1900),
                              (GX0 - 280, FY + 200, 1880)], 6, cab_m, smooth_pts=False)
        for z in range(2000, int(SPR + 300), 400):
            bx('cable_clip', GX0 - 292, GX0 - 268, FY - 22, FY - 2, z, z + 14, cab_m)
        # fanlight: dark glass behind a sunburst iron grille in the half-round
        fan = cyl('fan_glass', GR - 10, 10, (GC, LY + 40, SPR), axis='Y', verts=96); setmat(fan, dark_mat('fan_dark', (0.02, 0.02, 0.022), 0.3))
        cut(fan, bx('fan_low', GX0 - 50, GX1 + 50, LY, LY + 80, SPR - 2000, SPR))
        bx('fan_transom', GX0, GX1, LY - 20, LY + 40, SPR - 40, SPR + 50, gate_wood, bev=6)
        for k in range(1, 12):
            am = math.radians(180 * k / 12)
            tube('fan_ray', [(GC + 120 * math.cos(am), LY + 10, SPR + 50 + 120 * math.sin(am)), (GC + (GR - 20) * math.cos(am), LY + 10, SPR + (GR - 20) * math.sin(am))], 9, iron_m, smooth_pts=False)
        tube('fan_hub', arc(GC, SPR + 50, 120, 0, 180, 24, LY + 10), 12, iron_m)
        tube('fan_ring', arc(GC, SPR, GR * 0.62, 0, 180, 32, LY + 10), 10, iron_m)
        tube('fan_rim', arc(GC, SPR, GR - 20, 0, 180, 48, LY + 10), 14, iron_m)
        # the big box lock on the right leaf, the old key stuck in it (its bow out, the bit inside)
        LX, LZ = GC + 260, 1150
        lockbox = bx('box_lock', LX - 20, LX + 260, LY - 60, LY - 22, LZ - 110, LZ + 110, iron_m, bev=6)
        rivet_m = metal('lock_iron', (0.30, 0.29, 0.27), 0.45, marks='stamp', wear=0.6, grime=0.9)
        for (x, z) in ((LX, LZ - 90), (LX, LZ + 90), (LX + 240, LZ - 90), (LX + 240, LZ + 90)):
            cyl_y('lock_rivet', 11, LY - 66, LY - 60, x, z, rivet_m, verts=16)
        bx('keyhole_plate', LX + 70, LX + 150, LY - 64, LY - 60, LZ - 80, LZ + 20, rivet_m, bev=3)
        key_m = metal('old_key', (0.36, 0.34, 0.31), 0.42, marks='stamp', wear=0.8, grime=0.8, patina=0.2)
        KX, KZ = LX + 110, LZ - 30
        tube('key_shank', [(KX, LY - 64, KZ), (KX, LY - 172, KZ)], 10, key_m, smooth_pts=False)
        bx('key_collar', KX - 14, KX + 14, LY - 150, LY - 135, KZ - 14, KZ + 14, key_m, bev=3)
        bpy.ops.mesh.primitive_torus_add(major_radius=52, minor_radius=10, major_segments=48, minor_segments=12, location=(KX, LY - 222, KZ))
        k_ = bpy.context.object; k_.name = 'key_bow'; setmat(k_, key_m)
        k_.rotation_euler = (0, math.radians(90), 0)   # ring in the vertical plane of the shank
        tube('gate_handle', [(GC - 180, LY - 22, 1050), (GC - 180, LY - 90, 1060), (GC - 180, LY - 90, 1400), (GC - 180, LY - 22, 1410)], 15, iron_m)
        # the residents' notice taped to the left leaf: "use the next tenement's courtyard" (an arrow, no words)
        note_m = paper('notice', (0.80, 0.79, 0.74) if not WET else (0.66, 0.66, 0.62), fibre=1.0, seed=3, grime=0.3, lines=(9.0, 'Z', (0.22, 0.22, 0.25)))
        NX, NZ = GC - 660, 1620
        nt_ = bx('notice', NX - 105, NX + 105, LY - 25, LY - 23.5, NZ - 148, NZ + 148, note_m)
        nt_.rotation_euler.y = math.radians(-2.5)
        tape = plastic('tape', (0.75, 0.74, 0.68), rough=0.25, grime=0.2)
        tape.node_tree.nodes['Principled BSDF'].inputs['Transmission Weight'].default_value = 0.5
        for (dx, dz, a) in ((-95, 140, 35), (95, 140, -35), (-95, -140, -30), (95, -140, 30)):
            t_ = bx('tape', -40, 40, LY - 26, LY - 25, -12, 12, tape); t_.location = (NX + dx, 0, NZ + dz); t_.rotation_euler.y = math.radians(a)
        ink = plastic('marker_ink', (0.02, 0.025, 0.05), rough=0.4, grime=0.0, sheen_scuffs=0.0)
        tube('arrow', [(NX + 70, LY - 26.5, NZ - 70), (NX - 10, LY - 26.5, NZ - 60), (NX - 70, LY - 26.5, NZ - 72)], 4.5, ink)
        tube('arrow_head', [(NX - 40, LY - 26.5, NZ - 48), (NX - 74, LY - 26.5, NZ - 72), (NX - 42, LY - 26.5, NZ - 94)], 4.5, ink, smooth_pts=False)
        # wheel guards (odbojniki): worn stone cones at both jambs
        for x in (GX0 + 160, GX1 - 160):
            g_ = lathe('wheel_guard', [(0.1, 0), (230, 0), (215, 150), (185, 380), (150, 560), (105, 680), (60, 730), (0.1, 742)], x, FY + 60, seg=24, tilt=math.radians(-3 if x < 0 else 2))
            setmat(g_, granite('guard_stone', base=(0.30, 0.29, 0.28), seed=33, rough=0.75))
            g_.modifiers['bev'].width = 4
            stain_decal('guard_dirt', 'Z', 0.5, (x - 400, x + 400, FY - 400, FY + 50), [(x, FY - 120, 330, 220, 0.5)], color=(0.04, 0.035, 0.03), rough=0.4, noise_scale=0.02)
        # windows: ground floor (barred) and two upper storeys, a few lit
        glass_m = glass('old_glass', (0.75, 0.77, 0.77), rough=0.03, dirt=0.4)
        fr_m = oil_paint('win_frame', tuple(S.get('frame', (0.62, 0.60, 0.54))), rough=0.35, chips=0.5, scuffs=0.2, seed=8, edge_chips=1.0)
        cur = plastic('sheer', (0.75, 0.72, 0.64), rough=0.8, seed=2, grime=0.2, sheen_scuffs=0.0)
        cur.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value = 0.4
        cur.node_tree.nodes['Principled BSDF'].inputs['Transmission Weight'].default_value = 0.6
        for x, lit in S.get('gf_windows', ((-3500, True), (3500, False))):
            window(gwall, x - 650, x + 650, 1000, 3300, FY, 450, fr_m, glass_m, lit, rr, panes=(2, 3), bars=iron_m, curtain=cur, glow=S.get('gf_glow', 1.6))
            stain_decal('sill_streak', 'Y', FY - 3, (x - 900, x + 900, 600, 1000), [(x - 600, 800, 70, 260, 0.4), (x + 600, 800, 70, 260, 0.4)],
                        color=(0.10, 0.09, 0.07), rough=0.6, noise_scale=0.01)
        for s_, z0 in enumerate((GF + 1110, GF + 1110 + 3500)):
            for x in S.get('up_windows', (-4200, -1500, 1500, 4200)):
                lit = rr.random() < S.get('lit', 0.45)
                window(wall, x - 640, x + 640, z0, z0 + 2350, FY, 420, fr_m, glass_m, lit, rr, panes=(1, 3), curtain=cur if rr.random() < 0.7 else None,
                       sill_m=sur, hood=sur, glow=1.2)
        lamp_at = lantern('lantern', GC, FY + 160, SPR + GR - 760, 6.0 if TIME != 'day' else 0.0, iron_m, hang=440)   # hung in the gate arch
        # rain runs: grey streaks down from the cornice and the upper sills, a damp band over the plinth
        stain_decal('cornice_runs', 'Y', FY - 22, (W0, W1, GF - 1400, GF - 40), [(x, GF - 500, 90 + 60 * (k % 3), 700, 0.35) for k, x in enumerate(range(int(W0) + 300, int(W1), 520))],
                    color=(0.16, 0.14, 0.11), rough=0.85, noise_scale=0.004)
        stain_decal('damp_band', 'Y', FY - 52, (W0, W1, 500, 1400), [(x, 650, 900, 420, 0.45) for x in range(int(W0), int(W1) + 1, 900)],
                    color=(0.12, 0.11, 0.09), rough=0.5, noise_scale=0.004)
        num_x, num_z = S.get('num_at', (GX0 - 520, 2550))
        # downpipe at the party wall
        tube('downpipe', [(W1 - 600, FY - 110, -10), (W1 - 600, FY - 110, H)], 55, metal('zinc', (0.42, 0.43, 0.42), 0.45, marks=None, grime=0.8, wear=0.2), smooth_pts=False)
        door_quad = [(GX0, LY - 22, SPR), (GX1, LY - 22, SPR), (GX1, LY - 22, 0), (GX0, LY - 22, 0)]
        PLANES = [(FY - 21.5, 600, GF - 40), (FY - 1, GF + 210, H)]
        AVOID = [(GX0 - 300, GX1 + 300, 0, SPR + GR + 400)] + [(x - 700, x + 700, 950, 3350) for x, _ in S.get('gf_windows', ((-3500, True), (3500, False)))] +                 [(x - 700, x + 700, z, z + 2600) for z in (GF + 1110, GF + 4610) for x in S.get('up_windows', (-4200, -1500, 1500, 4200))]
        lock_quad = [(LX - 20, LY - 60, LZ + 110), (LX + 260, LY - 60, LZ + 110), (LX + 260, LY - 60, LZ - 110), (LX - 20, LY - 60, LZ - 110)]
    elif ST == 'beguinage':
        wash_m = brick_wall('whitewash', brick=(0.40, 0.20, 0.12), wash=tuple(S.get('wash', (0.84, 0.83, 0.79))), wash_amt=S.get('wash_amt', 0.9), seed=3)
        tar_m = paint('tar_plinth', (0.025, 0.025, 0.027), rough=0.35, metal_col=(0.40, 0.20, 0.12), chip=0.5, grime=0.4)
        blue = granite('bluestone', base=(0.17, 0.17, 0.18), seed=41, rough=0.5, pink=0.0)
        wall = bx('wall', W0, W1, FY, FY + 450, 0, H, wash_m)
        bx('tar_band', W0, W1, FY - 6, FY + 450, -40, S.get('tar', 520), tar_m, bev=2)
        DX0, DX1 = S.get('door_x', (-500, 500)); DTOP = 2150
        cut(wall, bx('door_cut', DX0 - 10, DX1 + 10, FY - 400, FY + 500, -50, DTOP + 520))
        cut(bpy.data.objects['tar_band'], bx('door_cut2', DX0 - 10, DX1 + 10, FY - 400, FY + 500, -50, DTOP + 520))
        LY = FY + 160
        bx('step', DX0 - 140, DX1 + 140, FY - 300, FY + 20, -40, 160, blue, bev=10)
        bx('threshold', DX0, DX1, FY + 20, LY + 80, -40, 175, blue, bev=6)
        for (a, b_, c, d) in ((DX0 - 10, DX0 + 60, 175, DTOP + 510), (DX1 - 60, DX1 + 10, 175, DTOP + 510), (DX0 - 10, DX1 + 10, DTOP, DTOP + 80),
                              (DX0 - 10, DX1 + 10, DTOP + 440, DTOP + 510)):
            bx('dframe', a, b_, LY - 30, LY + 60, c, d, oil_paint('door_frame_w', (0.78, 0.77, 0.72), rough=0.3, chips=0.3, seed=4), bev=4)
        dg = oil_paint('door_green', tuple(S.get('door', (0.025, 0.075, 0.045))), rough=0.25, under=(0.30, 0.10, 0.06), base=(0.32, 0.22, 0.12),
                       chips=0.6, scuffs=0.5, strokes='Z', seed=12, edge_chips=1.2)
        panel_leaf('door', DX0 + 62, DX1 - 62, LY, 178, DTOP - 2, dg, [(DX0 + 130, DX1 - 130, 1240, DTOP - 90), (DX0 + 130, DX1 - 130, 280, 1120)], depth=55, bead=24, proud=14)
        # transom light: four panes, dark hall behind
        tg = glass('transom_glass', (0.7, 0.72, 0.72), rough=0.03, dirt=0.6)
        bx('transom_glass', DX0 + 60, DX1 - 60, LY + 20, LY + 24, DTOP + 80, DTOP + 440, tg).visible_shadow = False
        bx('transom_hall', DX0 - 100, DX1 + 100, LY + 600, LY + 620, DTOP - 200, DTOP + 700, emissive('hall_dim', (1.0, 0.72, 0.42), 0.25, (0.02, 0.02, 0.02)))
        for k in range(1, 4):
            xx = DX0 + 60 + (DX1 - DX0 - 120) * k / 4
            bx('transom_bar', xx - 14, xx + 14, LY - 10, LY + 30, DTOP + 80, DTOP + 440, bpy.data.materials['door_frame_w'], bev=3)
        # old iron lock plate with the keyhole, a ring knocker, a bell pull
        rivet_m = metal('lock_iron', (0.30, 0.29, 0.27), 0.45, marks='stamp', wear=0.6, grime=0.9)
        LX, LZ = DX1 - 170, 1080
        lp = bx('lock_plate', LX - 55, LX + 55, LY - 20, LY - 14, LZ - 150, LZ + 110, rivet_m, bev=4)
        bx('keyhole', LX - 7, LX + 7, LY - 21, LY - 19.9, LZ - 95, LZ - 45, dark); cyl_y('keyhole_top', 11, LY - 21, LY - 19.9, LX, LZ - 40, dark, verts=20)
        tube('door_knob', [(LX, LY - 14, LZ + 40), (LX, LY - 60, LZ + 40)], 10, rivet_m, smooth_pts=False)
        bpy.ops.mesh.primitive_uv_sphere_add(radius=32, location=(LX, LY - 72, LZ + 40)); setmat(bpy.context.object, rivet_m)
        KCX = (DX0 + DX1) / 2
        bpy.ops.mesh.primitive_torus_add(major_radius=70, minor_radius=11, location=(KCX, LY - 34, 1560), rotation=(math.radians(90), 0, 0))
        setmat(bpy.context.object, rivet_m)
        cyl_y('knock_boss', 30, LY - 22, LY - 14, KCX, 1630, rivet_m, verts=24)
        # windows left (and right) of the door: white frames, small panes, green shutters folded back
        glass_m = glass('old_glass', (0.75, 0.77, 0.77), rough=0.03, dirt=0.5)
        fr_m = oil_paint('win_white', (0.80, 0.79, 0.75), rough=0.3, chips=0.3, scuffs=0.2, seed=9)
        cur = plastic('lace', (0.80, 0.78, 0.72), rough=0.8, seed=2, grime=0.1, sheen_scuffs=0.0)
        cur.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value = 0.4
        for x, lit in S.get('windows', ((-1900, True), (1900, False))):
            window(wall, x - 560, x + 560, 900, 2300, FY, 330, fr_m, glass_m, lit, rr, panes=(2, 3), curtain=cur, sill_m=blue, glow=1.0)
            for sx in ((-1, 1) if S.get('shutters', False) else ()):   # shutters folded back against the wall
                sh = panel_leaf('shutter', x + sx * 560 + (0 if sx > 0 else -560), x + sx * 560 + (560 if sx > 0 else 0), FY - 50, 900, 2300, dg,
                                [(x + sx * 560 + (60 if sx > 0 else -500), x + sx * 560 + (500 if sx > 0 else -60), 980, 2220)], depth=40, bead=18, proud=8)
        for x in S.get('up_windows', (-1900, 1900)):
            window(wall, x - 500, x + 500, 3300, 4500, FY, 330, fr_m, glass_m, rr.random() < 0.5, rr, panes=(2, 2), curtain=cur, sill_m=blue, glow=0.9)
        # eaves: a timber gutter board and the tiled roof edge above the frame top
        bx('eaves', W0, W1, FY - 380, FY + 100, 5200, 5380, oil_paint('eaves', (0.06, 0.06, 0.06), rough=0.4, seed=3), bev=6)
        tube('gutter', [(W0, FY - 330, 5180), (W1, FY - 330, 5180)], 70, metal('zinc', (0.42, 0.43, 0.42), 0.45, marks=None, grime=0.8), smooth_pts=False)
        tube('downpipe', [(W1 - 900, FY - 90, -10), (W1 - 900, FY - 90, 5180), (W1 - 900, FY - 330, 5180)], 45, bpy.data.materials['zinc'])
        lamp_at = lantern('lantern', DX1 + 520, FY - 10, 2550, 6.0 if TIME != 'day' else 0.0, iron_m, arm=300)
        if S.get('bike'):
            bike(S, FY - 300)
        num_x, num_z = DX0 - 300, 1900
        door_quad = [(DX0, LY, DTOP), (DX1, LY, DTOP), (DX1, LY, 0), (DX0, LY, 0)]
        PLANES = [(FY - 1, S.get('tar', 520), H)]
        AVOID = [(DX0 - 100, DX1 + 100, 0, DTOP + 600)] + [(x - 3000 if False else x - 1150, x + 1150, 850, 2350) for x, _ in S.get('windows', ((-1900, True), (1900, False)))] +                 [(x - 560, x + 560, 3250, 4550) for x in S.get('up_windows', (-1900, 1900))]
        lock_quad = [(LX - 55, LY - 20, LZ + 110), (LX + 55, LY - 20, LZ + 110), (LX + 55, LY - 20, LZ - 150), (LX - 55, LY - 20, LZ - 150)]
    else:   # townhouse (Saint-Gilles): brick and stone, front door up two steps, the balcony with geraniums above
        brick_m = brick_wall('red_brick', brick=tuple(S.get('brick', (0.36, 0.13, 0.07))), wash=(0.55, 0.52, 0.46), wash_amt=0.02, seed=6)
        stone = ph('blue_stone', 'workshop_concrete', scale=1500, metallic=0.0, base=(0.30, 0.31, 0.32), base_mix=0.75, rough_add=0.1, bump=0.8, grime=1.0, wear=0.2)
        white = ph('white_stone', 'wall_lime_plaster', scale=1600, metallic=0.0, base=(0.70, 0.67, 0.60), base_mix=0.8, rough_add=0.05, bump=0.6, grime=1.0, wear=0.3)
        GF = 1100
        wall = bx('wall', W0, W1, FY, FY + 450, GF, H, brick_m)
        gwall = bx('wall_gf', W0, W1, FY - 30, FY + 450, -40, GF, stone, bev=8)
        for z in (2600, 4000, 6100):
            bx('band', W0, W1, FY - 30, FY, z, z + 160, white, bev=6)
        DX0, DX1 = S.get('door_x', (-620, 620)); DTOP = 3000
        for w_ in (wall, gwall):
            cut(w_, bx('door_cut', DX0 - 20, DX1 + 20, FY - 400, FY + 500, -50, DTOP + 500))
        LY = FY + 260
        for k, (z0, dy) in enumerate(((-40, 520), (150, 260))):   # two bluestone steps
            bx('step%d' % k, DX0 - 200 + k * 60, DX1 + 200 - k * 60, FY - dy, FY + 300, z0, z0 + 190, granite('step_stone', base=(0.20, 0.20, 0.21), seed=51, rough=0.45, pink=0.0), bev=8)
        Z0 = 340
        dw = oak('front_door', light=(0.30, 0.17, 0.08), dark=(0.11, 0.05, 0.02), axis='Z', seed=81, ring=2.2, coat=1.0, coat_rough=0.18, wear=0.6, grime=0.7)
        for (a, b_, c, d) in ((DX0 - 20, DX0 + 70, Z0, DTOP + 480), (DX1 - 70, DX1 + 20, Z0, DTOP + 480), (DX0 - 20, DX1 + 20, DTOP, DTOP + 110)):
            bx('dframe', a, b_, LY - 40, LY + 60, c, d, dw, bev=5)
        CXd = (DX0 + DX1) / 2
        for k, (a, b_) in enumerate(((DX0 + 72, CXd - 2), (CXd + 2, DX1 - 72))):
            panel_leaf('leaf%d' % k, a, b_, LY, Z0, DTOP - 2, dw, [(a + 80, b_ - 80, Z0 + 120, 1250)], depth=55, bead=24, proud=16)
            # glazed upper panel behind a wrought-iron grille
            gl = bx('leaf_glass', a + 90, b_ - 90, LY + 20, LY + 24, 1400, DTOP - 120, glass('door_glass', (0.72, 0.73, 0.72), rough=0.04, dirt=0.4)); gl.visible_shadow = False
            cut(bpy.data.objects['leaf%d' % k], bx('glass_cut', a + 90, b_ - 90, LY - 30, LY + 80, 1400, DTOP - 120))
            for x in range(int(a + 140), int(b_ - 100), 90):
                tube('grille', [(x, LY - 10, 1420), (x, LY - 10, DTOP - 140)], 7, iron_m, smooth_pts=False)
            for z in (1700, 2200, 2650):
                tube('grille_c', [(a + 100, LY - 12, z), ((a + b_) / 2, LY - 12, z + 80), (b_ - 100, LY - 12, z)], 8, iron_m)
        bx('hall_glow', DX0 - 200, DX1 + 200, LY + 900, LY + 920, Z0, DTOP + 600, emissive('hall_lamp', (1.0, 0.70, 0.40), S.get('hall_glow', 0.3), (0.03, 0.03, 0.03)))
        tg = glass('transom_glass', (0.7, 0.72, 0.72), rough=0.03, dirt=0.4)
        bx('transom', DX0 + 70, DX1 - 70, LY + 20, LY + 24, DTOP + 110, DTOP + 470, tg).visible_shadow = False
        brass_m = bpy.data.materials.get('ph_brass') or metal('door_brass', (0.74, 0.56, 0.30), 0.3, marks='turn', marks_axis=(0, 1, 0), wear=0.6, grime=0.7, patina=0.5)
        cyl_y('knob', 34, LY - 60, LY - 10, CXd, 1200, brass_m, verts=40, bev=6)
        LX, LZ = CXd + 150, 1050
        bx('lock_rose', LX - 22, LX + 22, LY - 14, LY - 6, LZ - 70, LZ + 70, brass_m, bev=4)
        cyl_y('lock_cyl', 15, LY - 20, LY - 14, LX, LZ - 30, brass_m, verts=32)
        bx('cyl_slot', LX - 2, LX + 2, LY - 21, LY - 20, LZ - 42, LZ - 18, dark)
        # bell panel with four blank name slots and buttons (multi-flat house)
        steel_p = metal('bell_plate', (0.66, 0.65, 0.62), 0.26, marks='grind', marks_axis=(1, 0, 0), wear=0.3, grime=0.6, smudge=0.6)
        PX = DX1 + 260
        bx('bell_plate', PX, PX + 170, FY - 36, FY - 30, 1180, 1620, steel_p, bev=4)
        for j in range(4):
            bx('name_slot', PX + 20, PX + 115, FY - 38, FY - 36, 1230 + j * 95, 1290 + j * 95, paper('slot_card', (0.78, 0.76, 0.70), seed=j, grime=0.3))
            cyl_y('bell_btn', 14, FY - 44, FY - 36, PX + 140, 1260 + j * 95, steel_p, verts=24)
        # balcony over the door: stone slab on consoles, wrought railing, geranium pots, a watering can
        BZ = S.get('balcony_z', 3650)
        BX0, BX1 = DX0 - 400, DX1 + 400
        bx('balcony_slab', BX0, BX1, FY - 850, FY, BZ - 140, BZ, white, bev=12)
        for x in (BX0 + 120, BX1 - 220):
            bx('console', x, x + 100, FY - 700, FY, BZ - 480, BZ - 140, white, bev=10)
        cut(wall, bx('fw_cut', DX0 + 20, DX1 - 20, FY - 400, FY + 500, BZ, BZ + 2500))
        for (a, b_, c, d) in ((DX0 + 20, DX0 + 100, BZ, BZ + 2500), (DX1 - 100, DX1 - 20, BZ, BZ + 2500), (DX0 + 20, DX1 - 20, BZ + 2420, BZ + 2500),
                              (CXd - 35, CXd + 35, BZ, BZ + 2420), (DX0 + 20, DX1 - 20, BZ, BZ + 90)):
            bx('fw_frame', a, b_, FY + 150, FY + 220, c, d, oil_paint('fw_paint', (0.75, 0.74, 0.70), rough=0.3, seed=5), bev=4)
        g2 = bx('fw_glass', DX0 + 90, DX1 - 90, FY + 180, FY + 184, BZ + 90, BZ + 2420, glass('fw_glass', (0.72, 0.73, 0.72), rough=0.03)); g2.visible_shadow = False
        bx('fw_room', DX0 - 300, DX1 + 300, FY + 1300, FY + 1320, BZ - 200, BZ + 2800, emissive('magda_room', (1.0, 0.72, 0.44), S.get('room_glow', 0.5), (0.03, 0.03, 0.03)))
        fwc = plastic('fw_sheer', (0.80, 0.77, 0.70), rough=0.8, seed=5, grime=0.1, sheen_scuffs=0.0)
        fwc.node_tree.nodes['Principled BSDF'].inputs['Transmission Weight'].default_value = 0.6
        bx('fw_curtain', DX0 + 100, CXd - 120, FY + 300, FY + 304, BZ + 100, BZ + 2400, fwc)
        ml = point_lamp('magda_lamp', (DX1 - 200, FY + 900, BZ + 1400), S.get('magda_w', 6e6), (1.0, 0.68, 0.38), size=120)
        ml.visible_camera = False; ml.visible_transmission = False; ml.visible_glossy = False
        rail_y = FY - 830
        tube('rail_top', [(BX0 + 30, FY - 10, BZ + 950), (BX0 + 30, rail_y, BZ + 950), (BX1 - 30, rail_y, BZ + 950), (BX1 - 30, FY - 10, BZ + 950)], 16, iron_m, smooth_pts=False)
        tube('rail_bot', [(BX0 + 30, FY - 10, BZ + 90), (BX0 + 30, rail_y, BZ + 90), (BX1 - 30, rail_y, BZ + 90), (BX1 - 30, FY - 10, BZ + 90)], 10, iron_m, smooth_pts=False)
        for x in range(int(BX0 + 90), int(BX1 - 40), 115):
            tube('baluster', [(x, rail_y, BZ), (x, rail_y, BZ + 950)], 8, iron_m, smooth_pts=False)
            if (x // 115) % 2:
                tube('scroll', [(x, rail_y, BZ + 600), (x + 40, rail_y, BZ + 660), (x + 57, rail_y, BZ + 740), (x + 30, rail_y, BZ + 780), (x + 10, rail_y, BZ + 740)], 6, iron_m)
        terra = plastic('terracotta', (0.42, 0.16, 0.08), rough=0.85, seed=7, grime=0.6, sheen_scuffs=0.0)
        soil = dark_mat('pot_soil', (0.04, 0.03, 0.02), 0.95)
        leaf_m = plastic('geranium_leaf', (0.07, 0.16, 0.04), rough=0.55, seed=3, grime=0.1, sheen_scuffs=0.0)
        flower_m = plastic('geranium_red', (0.62, 0.03, 0.03), rough=0.5, seed=4, grime=0.0, sheen_scuffs=0.0)
        for m_ in (leaf_m, flower_m):
            m_.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value = 0.3
        pots = []
        for k, px in enumerate(S.get('pots', (-900, -520, 380, 820))):
            py = rail_y + 170
            lathe('pot', [(0.1, BZ), (95, BZ), (125, BZ + 230), (135, BZ + 240), (135, BZ + 262), (0.1, BZ + 262)], px, py, seg=40).data.materials.append(terra)
            cyl('soil', 122, 6, (px, py, BZ + 240), verts=40).data.materials.append(soil)
            pots.append((px, py))
        items = []; fl = []
        for (px, py) in pots:
            for i in range(26):   # round scalloped leaves in a mound
                a = rr.uniform(0, 6.3); r = rr.uniform(10, 150); s = rr.uniform(40, 62)
                M = (Matrix.Translation((px + r * math.cos(a), py + r * math.sin(a) * 0.8, BZ + 270 + rr.uniform(0, 160) * (1 - r / 220))) @
                     Matrix.Rotation(a, 4, 'Z') @ Matrix.Rotation(rr.uniform(0.2, 0.8), 4, 'Y') @ Matrix.Diagonal((s, s, s * 0.3, 1)))
                items.append((leaf_maker, M, 0))
            for c in range(rr.randint(3, 5)):   # flower umbels on stalks
                a = rr.uniform(0, 6.3); r = rr.uniform(0, 100)
                hx, hy, hz = px + r * math.cos(a), py + r * math.sin(a), BZ + 420 + rr.uniform(0, 160)
                fl.append(tube('stalk', [(px + r * 0.4 * math.cos(a), py + r * 0.4 * math.sin(a), BZ + 300), (hx, hy, hz)], 3, leaf_m))
                for i in range(30):
                    u = Vector((rr.gauss(0, 1), rr.gauss(0, 1), abs(rr.gauss(0, 0.8)))).normalized() * rr.uniform(20, 48)
                    s = rr.uniform(9, 14)
                    items.append((lambda bm: bmesh.ops.create_icosphere(bm, subdivisions=1, radius=1.0),
                                  Matrix.Translation((hx + u.x, hy + u.y, hz + u.z)) @ Matrix.Diagonal((s, s, s * 0.55, 1)), 1))
        scatter('geraniums', items, [leaf_m, flower_m])
        # the watering can she came out with, left on the balcony floor; water dripping off the slab onto the pavement
        zinc = metal('can_zinc', (0.55, 0.56, 0.55), 0.38, marks='stamp', wear=0.3, grime=0.6, smudge=0.3)
        cx_, cy_ = 120, rail_y + 230
        lathe('can_body', [(0.1, BZ), (120, BZ), (120, BZ + 260), (110, BZ + 280), (0.1, BZ + 280)], cx_, cy_, seg=40).data.materials.append(zinc)
        tube('can_spout', [(cx_ + 100, cy_, BZ + 60), (cx_ + 260, cy_, BZ + 250), (cx_ + 320, cy_, BZ + 330)], 16, zinc, smooth_pts=False)
        tube('can_handle', [(cx_ - 110, cy_, BZ + 80), (cx_ - 170, cy_, BZ + 200), (cx_ - 110, cy_, BZ + 330), (cx_ + 20, cy_, BZ + 330)], 12, zinc)
        stain_decal('drip_wet', 'Z', 0.6, (BX0 - 200, BX1 + 200, FY - 1300, FY - 520), [(-300, FY - 900, 380, 160, 0.5), (500, FY - 870, 260, 120, 0.4)],
                    color=(0.04, 0.04, 0.045), rough=0.08, noise_scale=0.01)
        glass_m = glass('old_glass', (0.75, 0.77, 0.77), rough=0.03, dirt=0.4)
        fr_m = oil_paint('win_white', (0.76, 0.75, 0.71), rough=0.3, chips=0.3, seed=9)
        cur = plastic('sheer', (0.78, 0.75, 0.68), rough=0.8, seed=2, grime=0.1, sheen_scuffs=0.0)
        cur.node_tree.nodes['Principled BSDF'].inputs['Subsurface Weight'].default_value = 0.4
        for x in S.get('windows', (-2700, 2700)):
            window(wall, x - 650, x + 650, BZ, BZ + 2400, FY, 420, fr_m, glass_m, rr.random() < S.get('lit', 0.6), rr, panes=(1, 3), curtain=cur, sill_m=white, hood=white, glow=1.0)
            window(wall, x - 650, x + 650, 1400, 3300, FY, 420, fr_m, glass_m, rr.random() < S.get('lit', 0.5), rr, panes=(1, 3), curtain=cur, sill_m=white, glow=0.9)
            cut(gwall, bx('gw_cut', x - 650, x + 650, FY - 400, FY + 500, 1400, 3300))
        lamp_at = None
        num_x, num_z = DX1 + 345, 2150
        door_quad = [(DX0, LY, DTOP), (DX1, LY, DTOP), (DX1, LY, Z0), (DX0, LY, Z0)]
        PLANES = [(FY - 1, GF, H)]
        AVOID = [(DX0 - 100, DX1 + 100, 0, BZ + 2600)] + [(x - 700, x + 700, z, z + 2500) for z in (1400, BZ) for x in S.get('windows', (-2700, 2700))]
        lock_quad = [(LX - 22, LY - 14, LZ + 70), (LX + 22, LY - 14, LZ + 70), (LX + 22, LY - 14, LZ - 70), (LX - 22, LY - 14, LZ - 70)]
    # weathering over the whole front: soot and damp patches, lighter patch repairs (decals on the wall planes,
    # kept off the openings, which are recessed behind the decal planes)
    wr = random.Random(S.get('seed', 7) + 5)
    def free(x, z, r):
        return not any(a0 - r < x < a1 + r and b0 - r < z < b1 + r for (a0, a1, b0, b1) in AVOID)
    for k, (yy, z0, z1) in enumerate(PLANES):
        sp = []
        while len(sp) < int(30 * (z1 - z0) / H) + 4:
            x, z = wr.uniform(W0, W1), wr.uniform(z0, z1)
            if free(x, z, 250): sp.append((x, z, wr.uniform(300, 1300), wr.uniform(200, 800), wr.uniform(0.15, 0.4)))
        stain_decal('front_soot', 'Y', yy, (W0, W1, z0, z1), sp, color=tuple(S.get('soot', (0.10, 0.09, 0.075))), rough=0.85, noise_scale=0.003)
        sp = []
        while len(sp) < int(10 * (z1 - z0) / H) + 2:
            x, z = wr.uniform(W0, W1), wr.uniform(z0, z1)
            if free(x, z, 400): sp.append((x, z, wr.uniform(200, 600), wr.uniform(150, 400), wr.uniform(0.25, 0.5)))
        stain_decal('front_repair', 'Y', yy - 0.3, (W0, W1, z0, z1), sp, color=tuple(S.get('repair', (0.62, 0.58, 0.50))), rough=0.9, noise_scale=0.006)
    # house number: a small enamel plate (digits only)
    num = str(J.get('number', ''))
    if num:
        enam = enamel('num_enamel', tuple(S.get('num_col', (0.03, 0.10, 0.30))), chip=0.5)
        wide = 140 + 70 * len(num)
        bx('num_plate', num_x - wide / 2, num_x + wide / 2, FY - 45, FY - 30, num_z - 110, num_z + 110, enam, bev=8)
        nw = plastic('num_white', (0.82, 0.81, 0.76), rough=0.15, grime=0.1, sheen_scuffs=0.0)
        for k, ch in enumerate(num):
            t = text_obj('hnum' + ch, ch, 150, font='Lato-Regular.ttf', extrude=0.6, mat=nw)
            t.rotation_euler = (math.radians(90), 0, 0); t.location = (num_x + (k - (len(num) - 1) / 2) * 82, FY - 46, num_z)
    # the next house along on either side (a slightly different render, the party-wall step) and the street behind us
    for sx in (-1, 1):
        nb = ph('next_house%d' % sx, 'wall_lime_plaster', scale=2400, metallic=0.0, base=tuple(S.get('next_house', (0.50, 0.47, 0.42))), base_mix=0.75, rough_add=0.05, bump=0.7, grime=1.0)
        a, b_ = (W1, W1 + 9000) if sx > 0 else (W0 - 9000, W0)
        bx('next_house', a, b_, FY - 120 * (1 if sx > 0 else 0.5), FY + 600, 0, H + 1500, nb)
    # light
    if TIME in ('evening', 'rainy', 'night'):
        sky_world(S.get('sky', 0.18 if TIME == 'rainy' else 0.25), S.get('sun_elev', -3.0), S.get('sun_az', 200.0))
        if lamp_at is not None:
            point_lamp('lantern_bulb', tuple(lamp_at), S.get('lantern_w', 2.2e7), (1.0, 0.70, 0.40), size=60)
        a = aim('aim_street', (0, FY, 1200))
        sl = area_light('street_lamp', tuple(S.get('street_lamp', (-2600, -6500, 6200))), a, 600, S.get('street_w', 1.4e8), tuple(S.get('street_col', (0.75, 0.82, 1.0))))
        sl.visible_camera = False; sl.visible_glossy = S.get('street_glossy', True)
        if S.get('fill_w'):
            af = aim('aim_fill', (0, FY, 1500))
            fl_ = area_light('sky_fill', (0, -4000, 9000), af, 9000, S['fill_w'], (0.55, 0.65, 0.85)); fl_.visible_camera = False; fl_.visible_glossy = False
    else:
        elev, az = S.get('sun_elev', 22.0), S.get('sun_az', 230.0)
        d = Vector((math.cos(math.radians(az)) * math.cos(math.radians(elev)), math.sin(math.radians(az)) * math.cos(math.radians(elev)), math.sin(math.radians(elev))))
        sky_world(S.get('sky', 0.5), elev, az + 90); sun_lamp(-d, S.get('sun', 3.5), (1.0, 0.88, 0.72))
    # damp air: a thin scattering volume between us and the front, so lamps get a halo and depth falls off
    if S.get('mist', 0.0) > 0:
        vm = bpy.data.materials.new('mist'); vm.use_nodes = True; nt = vm.node_tree; nt.nodes.remove(nt.nodes['Principled BSDF'])
        pv = nt.nodes.new('ShaderNodeVolumePrincipled'); pv.inputs['Density'].default_value = S['mist']; pv.inputs['Anisotropy'].default_value = S.get('mist_g', 0.55)
        pv.inputs['Color'].default_value = (0.85, 0.88, 0.92, 1)
        nt.links.new(pv.outputs[0], nt.nodes['Material Output'].inputs['Volume'])
        mb = bx('mist_box', -12000, 12000, -16000, FY - 60, -100, H + 2000, vm); mb.visible_shadow = False
    # rain: streaks of splash grime low on the wall, a wet sheen on the wall foot
    if WET:
        stain_decal('splash', 'Y', FY - 52, (W0, W1, 0, 900), [(x, 120, 700, 420, 0.5) for x in range(int(W0), int(W1) + 1, 1100)],
                    color=(0.05, 0.045, 0.04), rough=0.3, noise_scale=0.006)
    return {'door': door_quad, 'lock': lock_quad}


# ================================================================ lockers kit (campus rehearsal room, D-110)
def kit_lockers():
    """The campus rehearsal room after hours (job.drummer_locker): a row of grey steel lockers with louvres and
    tubular cam locks (Iga's is number 8), acoustic panels, a drum hardware case, an amp, a music stand and cables
    on the rubber floor; fluorescent battens, one of them flickered off."""
    S = J.get('lockers', {})
    rr = random.Random(S.get('seed', 8))
    FY = S.get('fy', 2400); X0, X1 = -2200, 2200; CEIL = 2900
    floor = ph('rubber_floor', 'workshop_concrete', scale=1200, metallic=0.0, base=(0.09, 0.09, 0.095), base_mix=0.8, rough_add=0.15, bump=0.3, grime=0.8, wear=0.4)
    bx('floor', X0 - 500, X1 + 500, -9000, FY + 300, -40, 0, floor)
    wall = lime_wall('rr_wall', tuple(S.get('wall', (0.62, 0.62, 0.58))), seed=31, dirt=0.5, cracks=0.2)
    for nm, a, b_ in (('lw', X0 - 200, X0), ('rw', X1, X1 + 200)):
        bx(nm, a, b_, -9000, FY + 300, 0, CEIL, wall)
    bx('back', X0, X1, FY, FY + 200, 0, CEIL, wall)
    bx('ceiling', X0 - 300, X1 + 300, -9000, FY + 300, CEIL, CEIL + 100, lime_wall('rr_ceil', (0.70, 0.70, 0.67), seed=32, dirt=0.3, cracks=0.1))
    bx('behind', X0, X1, -9100, -9000, 0, CEIL, wall)
    # acoustic panels on both side walls: fabric-covered slabs, a few dented and stained
    fab = [plastic('felt%d' % i, c, rough=0.95, seed=i, grime=0.5, sheen_scuffs=0.0) for i, c in enumerate(((0.10, 0.10, 0.11), (0.14, 0.13, 0.12), (0.08, 0.09, 0.11)))]
    for sx, xw in ((-1, X0), (1, X1)):
        for k, y in enumerate(range(-5600, FY - 400, 1250)):
            for z0 in (600, 1850):
                a, b_ = (xw, xw + 60) if sx < 0 else (xw - 60, xw)
                o = bx('acoustic', a, b_, y, y + 1180, z0, z0 + 1180, fab[rr.randrange(3)], bev=12)
                o.rotation_euler.x = math.radians(rr.uniform(-0.6, 0.6))
    # the lockers: a bank of 8 against the back wall, number 8 nearest the centre-right
    grey = paint('locker_grey', tuple(S.get('locker', (0.36, 0.38, 0.38))), rough=0.38, metal_col=(0.55, 0.55, 0.55), chip=0.35, grime=0.7)
    steel_l = metal('cam_lock', (0.66, 0.66, 0.64), 0.25, marks='turn', marks_axis=(0, 1, 0), wear=0.4, grime=0.5)
    LW, LD, LH = 400, 500, 1850
    n = S.get('count', 8); xs = S.get('bank_x', -2200); first = S.get('first', 3)
    bx('locker_plinth', xs - 10, xs + n * LW + 10, FY - LD - 10, FY, 0, 120, dark_mat('plinth_black', (0.03, 0.03, 0.03), 0.6))
    target = None
    for k in range(n):
        x0 = xs + k * LW; num = first + k
        bx('locker_body', x0 + 2, x0 + LW - 2, FY - LD, FY, 120, 120 + LH, grey, bev=3)
        DY = FY - LD - 14
        door = bx('locker_door', x0 + 14, x0 + LW - 14, DY, DY + 14, 140, 100 + LH, grey, bev=3)
        for z in range(1500, 1800, 45):   # louvres
            bx('louvre', x0 + 90, x0 + LW - 90, DY - 6, DY, z, z + 14, grey, bev=2)
        for z in range(300, 600, 45):
            bx('louvre', x0 + 90, x0 + LW - 90, DY - 6, DY, z, z + 14, grey, bev=2)
        cyl_y('cam_rose', 17, DY - 6, DY, x0 + LW - 70, 1150, steel_l, verts=32)
        bx('cam_key', x0 + LW - 73, x0 + LW - 67, DY - 6.6, DY - 5.9, 1140, 1160, dark)
        bx('pull', x0 + LW - 100, x0 + LW - 40, DY - 26, DY - 6, 1220, 1236, steel_l, bev=3)
        np_ = bx('num_plate', x0 + LW / 2 - 50, x0 + LW / 2 + 50, DY - 2, DY, 1880, 1930, plastic('num_plate', (0.82, 0.81, 0.76), rough=0.3, grime=0.4))
        t = text_obj('lnum', str(num), 40, font='Lato-Regular.ttf', extrude=0.4, mat=plastic('num_ink', (0.05, 0.05, 0.05), rough=0.4))
        t.rotation_euler = (math.radians(90), 0, 0); t.location = (x0 + LW / 2, DY - 2.5, 1905)
        if rr.random() < 0.6:   # dents and scuffs low on the doors
            stain_decal('locker_scuff', 'Y', DY - 0.6, (x0 + 20, x0 + LW - 20, 140, 700), [(x0 + rr.uniform(60, 340), rr.uniform(200, 600), 90, 60, 0.4)],
                        color=(0.12, 0.12, 0.12), rough=0.6, noise_scale=0.05)
        if num == int(S.get('target', 8)):
            target = (x0, DY)
            # a band sticker and a strip of gaffer tape with a name in marker strokes (no letters)
            bx('gaffer', x0 + 70, x0 + LW - 70, DY - 1.2, DY - 0.6, 1300, 1345, plastic('gaffer', (0.06, 0.06, 0.06), rough=0.7))
            tube('gaffer_name', [(x0 + 100 + i * 25, DY - 1.6, 1322 + 7 * math.sin(i * 1.9)) for i in range(8)], 2.0, plastic('silver_marker', (0.7, 0.7, 0.72), rough=0.3))
            bx('band_sticker', x0 + 120, x0 + 280, DY - 1.0, DY - 0.6, 900, 1010, plastic('band_sticker', (0.75, 0.30, 0.10), rough=0.4))
    # rehearsal kit on the floor: hardware case, amp, music stand, cables
    case_m = plastic('case_black', (0.025, 0.025, 0.027), rough=0.55, seed=3, grime=0.5, sheen_scuffs=0.4)
    alu = metal('case_alu', (0.70, 0.70, 0.68), 0.3, marks='grind', marks_axis=(1, 0, 0), wear=0.4, grime=0.5)
    HX, HY = S.get('case_at', (-1250, 1500))
    bx('hw_case', HX - 520, HX + 520, HY - 200, HY + 200, 60, 400, case_m, bev=12)
    for (a, b_) in ((HX - 530, HX + 530),):
        for z in (60, 390):
            bx('case_edge', a, b_, HY - 210, HY - 195, z, z + 15, alu, bev=2)
    for x in (HX - 520, HX + 505):
        bx('case_corner', x, x + 15, HY - 210, HY + 210, 50, 410, alu, bev=2)
    for x in (HX - 400, HX + 400):
        cyl('case_wheel', 40, 30, (x, HY, 40), axis='Y', verts=24).data.materials.append(rubber('case_wheel'))
    amp = plastic('amp_tolex', (0.03, 0.03, 0.03), rough=0.6, seed=4, grime=0.6, sheen_scuffs=0.5)
    grille = tiles('amp_grille', (0.20, 0.19, 0.17), grout=(0.05, 0.05, 0.05), w=6, h=6, offset=0.0, rough=0.8, mortar=1.5, axis='Y', var=0.1, bump=0.5)
    AX, AY = S.get('amp_at', (1500, 1250))
    bx('amp', AX - 330, AX + 330, AY - 130, AY + 130, 0, 560, amp, bev=10)
    bx('amp_grille', AX - 290, AX + 290, AY - 133, AY - 129, 40, 420, grille)
    bx('amp_panel', AX - 300, AX + 300, AY - 120, AY + 120, 430, 540, alu, bev=3)
    for i in range(6):
        cyl_y('amp_knob', 12, AY - 140, AY - 120, AX - 220 + i * 80, 485, case_m, verts=16)
    # music stand with a set list clipped (bars, no text)
    MX, MY = S.get('stand_at', (300, 900))
    stand = paint('stand_black', (0.02, 0.02, 0.02), rough=0.4, chip=0.3, grime=0.4)
    tube('stand_post', [(MX, MY, 0), (MX, MY, 1050)], 10, stand, smooth_pts=False)
    for a in (0, 120, 240):
        tube('stand_leg', [(MX, MY, 280), (MX + 300 * math.cos(math.radians(a)), MY + 300 * math.sin(math.radians(a)), 0)], 8, stand, smooth_pts=False)
    desk = bx('stand_desk', MX - 250, MX + 250, MY - 8, MY, 1000, 1330, stand, bev=3); desk.rotation_euler.x = math.radians(-18)
    sl = bx('setlist', MX - 105, MX + 105, MY - 12, MY - 9, 1040, 1310, paper('setlist', (0.86, 0.85, 0.80), seed=3, grime=0.3, lines=(22.0, 'Z', (0.15, 0.15, 0.15))))
    sl.rotation_euler.x = math.radians(-18)
    cable = plastic('cable', (0.02, 0.02, 0.02), rough=0.35, grime=0.4)
    pts = [(AX - 200, AY - 100, 4.5)] + [(AX - 400 - i * 250, AY - 600 + 250 * math.sin(i * 1.2), 4.5) for i in range(9)]
    tube('floor_cable', pts, 4.5, cable)
    tube('floor_cable2', [(MX + 200, MY + 300, 4), (MX - 300, MY - 200, 4), (MX - 900, MY + 100, 4), (HX + 300, HY - 400, 4)], 4, cable)
    # the rehearsal-room rug under the kit (worn, red and indigo bands) and a guitar case leaning on the wall
    rug = plastic('rug', (0.26, 0.055, 0.045), rough=0.97, seed=11, grime=0.9, sheen_scuffs=0.0)
    rug.node_tree.nodes['Principled BSDF'].inputs['Sheen Weight'].default_value = 0.6
    band = plastic('rug_band', (0.07, 0.06, 0.16), rough=0.97, seed=12, grime=0.8, sheen_scuffs=0.0)
    rx_, ry_ = S.get('rug_at', (-700, 700))
    parts = [bx('rug', -1200, 1200, -800, 800, 0, 8, rug, bev=2)]
    for (a_, b2, c_, d_) in ((-1120, 1120, 640, 700), (-1120, 1120, -700, -640), (-1120, -1060, -700, 700), (1060, 1120, -700, 700)):
        parts.append(bx('rug_band', a_, b2, c_, d_, 8, 8.6, band))
    group('rug_g', parts, Matrix.Translation((rx_, ry_, 0)) @ Matrix.Rotation(math.radians(-4), 4, 'Z'))
    stain_decal('rug_wear', 'Z', 9.0, (rx_ - 1200, rx_ + 1200, ry_ - 800, ry_ + 800), [(rx_ - 300, ry_, 500, 300, 0.4)], color=(0.15, 0.10, 0.08), rough=0.97, noise_scale=0.01)
    gc = plastic('guitar_case', (0.04, 0.035, 0.03), rough=0.5, seed=6, grime=0.6, sheen_scuffs=0.5)
    g_ = lathe('guitar_case', [(0.1, 0), (170, 0), (180, 200), (150, 420), (190, 650), (175, 820), (70, 900), (60, 1180), (0.1, 1190)], 0, 0, seg=32)
    g_.data.materials.append(gc); g_.scale.y = 0.35
    g_.matrix_world = Matrix.Translation((X1 - 170, S.get('guitar_y', 900), 0)) @ Matrix.Rotation(math.radians(-12), 4, 'Y') @ Matrix.Diagonal((1, 0.35, 1, 1))
    # a snare on its stand and a drum stool left out
    chrome = metal('drum_chrome', (0.75, 0.75, 0.74), 0.15, marks='turn', marks_axis=(0, 0, 1), wear=0.3, grime=0.4)
    SX, SY = S.get('snare_at', (-700, 600))
    for a in (30, 150, 270):
        tube('snare_leg', [(SX, SY, 300), (SX + 280 * math.cos(math.radians(a)), SY + 280 * math.sin(math.radians(a)), 0)], 7, chrome, smooth_pts=False)
    tube('snare_post', [(SX, SY, 0), (SX, SY, 600)], 9, chrome, smooth_pts=False)
    shell = paint('snare_wrap', (0.35, 0.05, 0.05), rough=0.2, metal_col=(0.6, 0.6, 0.6), chip=0.2, grime=0.3)
    cyl('snare_shell', 180, 140, (SX, SY, 680), verts=64).data.materials.append(shell)
    cyl('snare_head', 182, 4, (SX, SY, 752), verts=64).data.materials.append(plastic('drum_head', (0.80, 0.78, 0.72), rough=0.6, seed=2, grime=0.6))
    for z in (610, 752):
        bpy.ops.mesh.primitive_torus_add(major_radius=185, minor_radius=6, location=(SX, SY, z)); setmat(bpy.context.object, chrome)
    tube('stick_a', [(SX - 60, SY - 40, 756), (SX + 260, SY - 160, 760)], 7, oak('stick', light=(0.70, 0.55, 0.35), dark=(0.55, 0.40, 0.22), axis='X', seed=141, coat=0.4, rough=0.5), smooth_pts=False)
    cyl('stool_seat', 190, 80, (SX + 600, SY + 500, 520), verts=48).data.materials.append(plastic('stool_vinyl', (0.03, 0.03, 0.03), rough=0.45, grime=0.5, sheen_scuffs=0.5))
    tube('stool_post', [(SX + 600, SY + 500, 0), (SX + 600, SY + 500, 480)], 14, chrome, smooth_pts=False)
    for a in (0, 120, 240):
        tube('stool_leg', [(SX + 600, SY + 500, 200), (SX + 600 + 260 * math.cos(math.radians(a)), SY + 500 + 260 * math.sin(math.radians(a)), 0)], 9, chrome, smooth_pts=False)
    # light: fluorescent battens (one off), cool; a warm exit-sign-free corridor glow through the door behind us
    tubeglow = emissive('fluo', (0.92, 0.96, 1.0), 25.0)
    housing = plastic('batten', (0.80, 0.80, 0.78), rough=0.4, grime=0.5)
    for k, y in enumerate(S.get('battens', (1700, -400, -2600))):
        for xx in (-700, 700):
            bx('batten', xx - 650, xx + 650, y - 60, y + 60, CEIL - 70, CEIL - 2, housing, bev=4)
            on = not (k == 1 and xx > 0)
            bx('fluo', xx - 620, xx + 620, y - 20, y + 20, CEIL - 85, CEIL - 70, tubeglow if on else plastic('fluo_off', (0.75, 0.75, 0.73), rough=0.3))
            if on:
                bpy.ops.object.light_add(type='AREA', location=(xx, y, CEIL - 90)); L = bpy.context.object; L.name = 'fluo_light'
                L.data.shape = 'RECTANGLE'; L.data.size = 1240; L.data.size_y = 60; L.data.energy = S.get('fluo_w', 3.0e6); L.data.color = (0.90, 0.95, 1.0)
                L.rotation_euler = (math.pi, 0, 0); L.visible_camera = False; L.visible_glossy = False
    world_hdri(0.004, 'interior.exr', sat=0.3)
    x0, DY = target
    return {'door': [(x0 + 14, DY, 100 + LH), (x0 + LW - 14, DY, 100 + LH), (x0 + LW - 14, DY, 140), (x0 + 14, DY, 140)],
            'lock': [(x0 + LW - 95, DY - 6, 1175), (x0 + LW - 45, DY - 6, 1175), (x0 + LW - 45, DY - 6, 1125), (x0 + LW - 95, DY - 6, 1125)]}


# ================================================================ camera, render
def camera_walk():
    cam = photo_camera((0, 0, 0), lens=CAMC.get('lens', 24.0))
    cam.data.sensor_fit = 'VERTICAL'; cam.data.sensor_height = 36.0; cam.data.sensor_width = 36.0
    keys = CAMC['keys']             # [t, x, y, z, yaw, pitch]
    end_shift = tuple(CAMC.get('end_shift', (0.0, 0.0))); step_len = CAMC.get('step', 720.0)
    def ease_walk(t): return 0.8 * t + 1.4 * t * t - 1.2 * t * t * t
    def ease(t): return t * t * (3 - 2 * t) if t < 1 else 1.0
    def catmull(p0, p1, p2, p3, u):
        return 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u ** 3)
    def at(t):
        s = ease_walk(t); ks = keys
        i = max(j for j in range(len(ks) - 1) if ks[j][0] <= s) if s < 1 else len(ks) - 2
        u = (s - ks[i][0]) / (ks[i + 1][0] - ks[i][0])
        P = [ks[max(0, min(len(ks) - 1, j))] for j in (i - 1, i, i + 1, i + 2)]
        x, y, z, yaw, pitch = [catmull(*[p[c] for p in P], u) for c in range(1, 6)]
        dist = math.hypot(x - ks[0][1], y - ks[0][2]); fade = 1 - ease(max(0, (s - 0.75) / 0.25))
        z -= 12 * fade * (0.5 - 0.5 * math.cos(2 * math.pi * dist / step_len)); roll = 0.45 * fade * math.sin(math.pi * dist / step_len)
        sh = ease(max(0, (s - 0.45) / 0.55))
        return Vector((x, y, z)), yaw, pitch, roll, (end_shift[0] * sh, end_shift[1] * sh)
    scene.render.fps = FPS; scene.frame_start = 1; scene.frame_end = FRAMES
    for f in range(1, FRAMES + 1):
        p, yaw, pitch, roll, sh = at((f - 1) / (FRAMES - 1))
        cam.location = p; cam.rotation_euler = (math.radians(90 + pitch), math.radians(roll), math.radians(yaw))
        cam.data.shift_x, cam.data.shift_y = sh
        cam.keyframe_insert('location', frame=f); cam.keyframe_insert('rotation_euler', frame=f)
        cam.data.keyframe_insert('shift_x', frame=f); cam.data.keyframe_insert('shift_y', frame=f)
    for fc in list(cam.animation_data.action.fcurves) + list(cam.data.animation_data.action.fcurves):
        for kp in fc.keyframe_points: kp.interpolation = 'LINEAR'
    return cam


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
    else:
        scene.cycles.device = 'CPU'


def base_render(res, spp, out, expo, vig, look):
    render_setup(out, res, spp, exposure=expo, look=look, bounces=10)
    setup_device()
    scene.cycles.adaptive_threshold = 0.02 if spp < 64 else 0.01
    photo_finish(vig)
    # env_common.photo_finish is fixed on main (D-89): no bright centre ellipse any more


KITS = {'street': kit_street, 'shop': kit_shop, 'corridor': kit_corridor, 'vault': kit_vault, 'facade': kit_facade, 'lockers': kit_lockers}
info = KITS[KIT]()
cam = camera_walk()
LOOK = J.get('look', {}).get(TIME, {})
EXPO, VIG, AGX = LOOK.get('exposure', 0.0), LOOK.get('vignette', 0.22), LOOK.get('agx', 'AgX - Base Contrast')

if MODE in ('seq', 'both'):
    seq_dir = os.path.join(OUT_DIR, BASE + '_seq'); os.makedirs(seq_dir, exist_ok=True)
    base_render(RES, SPP, os.path.join(seq_dir, 'f_####'), EXPO, VIG, AGX)
    scene.render.use_motion_blur = True; scene.render.motion_blur_shutter = 0.5
    scene.render.use_persistent_data = True; scene.render.image_settings.file_format = 'PNG'
    scene.frame_step = STEP
    bpy.ops.render.render(animation=True)
    scene.frame_step = 1; scene.render.use_motion_blur = False
    print('WROTE SEQ', seq_dir)
if MODE in ('still', 'both', 'anchors'):
    still = os.path.join(OUT_DIR, BASE + '_hold.png')
    base_render(STILL_RES, STILL_SPP, still, EXPO, VIG, AGX)
    scene.frame_set(FRAMES)
    scene.render.resolution_x, scene.render.resolution_y = STILL_RES
    data = {'width': STILL_RES[0], 'height': STILL_RES[1], 'job': JOB, 'time': TIME, 'kit': KIT, 'fps': FPS, 'frames': FRAMES,
            'note': 'plate-only hold (no client cut-out): anchors are quads [tl,tr,br,bl] normalised 0..1, origin top-left (D-41).',
            'anchors': {k: project(v) for k, v in info.items()}, 'figures': {},
            'camera': {'location_mm': [round(c, 2) for c in cam.matrix_world.translation], 'lens_mm': cam.data.lens,
                       'sensor_height_mm': 36.0, 'sensor_fit': 'VERTICAL', 'shift': [cam.data.shift_x, cam.data.shift_y],
                       'rotation_euler_deg': [round(math.degrees(a), 3) for a in cam.matrix_world.to_euler()]}}
    with open(os.path.splitext(still)[0] + '.json', 'w') as fh: json.dump(data, fh, indent=1)
    if MODE != 'anchors':
        bpy.ops.render.render(write_still=True); print('WROTE', still)
