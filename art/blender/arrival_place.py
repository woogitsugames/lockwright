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
# 1 unit = 1 mm. Camera looks +y; the hold target sits near the origin; floor z = 0.
import bpy, bmesh, math, os, sys, json, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from env_common import *
from env_common import _bev, _new, _sep, _math, _bump
from lw_common import _noise, _mix, _maprange
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
    frame = paint('bike_paint', tuple(B.get('color', (0.035, 0.11, 0.075))), rough=0.32, metal_col=(0.5, 0.5, 0.5), chip=0.4, grime=0.5)
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


def kit_shop():
    """A small pizzeria after closing (23:30): the back-room door at the end of the counter, the dining room dark."""
    S = J.get('shop', {})
    FY = 3000; X0, X1 = -3200, 3000; CEIL = 3050
    floor = ph('shop_floor', 'cement_tiles', scale=S.get('floor_scale', 300), metallic=0.0, base=(0.30, 0.22, 0.17), base_mix=0.45, tint=(0.85, 0.80, 0.74), rough_add=0.1, bump=0.3, grime=1.0, wear=0.6)
    bx('floor', X0, X1, -6000, FY, -40, 0, floor)
    wall_t = tiles('wall_tiles', (0.82, 0.81, 0.77), grout=(0.42, 0.40, 0.37), w=150, h=75, rough=0.08)
    upper = lime_wall('shop_upper', tuple(S.get('upper', (0.62, 0.46, 0.28))), seed=11, dirt=0.6, cracks=0.3)
    ceil = lime_wall('shop_ceiling', (0.66, 0.62, 0.55), seed=12, dirt=0.4, cracks=0.3)
    DX0, DX1, DTOP = -450, 450, 2060
    TILE_TOP = 1400
    for nm, z0, z1, m_ in (('t', 0, TILE_TOP, wall_t), ('u', TILE_TOP, CEIL, upper)):
        o = bx('back_' + nm, X0, X1, FY, FY + 200, z0, z1, m_)
        cut(o, bx('hole', DX0 - 60, DX1 + 60, FY - 10, FY + 210, -10, DTOP + 60))
        bx('side_' + nm, X1, X1 + 200, -6000, FY + 200, z0, z1, m_)
        bx('lside_' + nm, X0 - 200, X0, -6000, FY + 200, z0, z1, m_)
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
                color=(0.82, 0.80, 0.74), rough=0.95, noise_scale=0.05)
    stain_decal('flour_floor', 'Z', 0.4, (DX0 - 300, DX1 + 400, FY - 900, FY - 10), [(80, FY - 300, 420, 260, 0.55), (360, FY - 120, 200, 120, 0.5)],
                color=(0.80, 0.78, 0.72), rough=0.95, noise_scale=0.03)
    # counter on the left: tiled front, terrazzo top, the brick oven in the corner behind it
    CX1 = S.get('counter_end', -1250)
    ctl = tiles('counter_tiles', (0.12, 0.26, 0.20), grout=(0.5, 0.48, 0.44), w=100, h=100, offset=0.0, rough=0.08, axis='X')
    bx('counter_front', -3200, CX1, -2600, -1950, 0, 1000, ctl)
    bx('counter_end', CX1 - 30, CX1, -2600, S.get('counter_y1', 850), 0, 1000, ctl)
    marble = ph('counter_top', 'terrazzo_grey_red', scale=900, metallic=0.0, rough_add=-0.05, coat=0.4, bump=0.1, grime=0.3)
    bx('counter_top', -3200, CX1 + 40, -2650, S.get('counter_y1', 850) + 50, 1000, 1040, marble, bev=6)
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
    tray = oak('dough_tray', light=(0.55, 0.42, 0.26), dark=(0.36, 0.25, 0.13), axis='X', seed=51, ring=1.5, coat=0.0, rough=0.7, wear=0.4)
    for i in range(3):
        bx('dough_tray', CX1 - 1100, CX1 - 450, -700 - i * 4, 0 - i * 4, 1040 + i * 95, 1130 + i * 95, tray, bev=6)
    # stacked plain pizza boxes and flour sacks on a steel shelf to the right of the door
    shelf_m = metal('shelf_steel', (0.64, 0.64, 0.62), 0.3, marks='grind', marks_axis=(1, 0, 0), wear=0.3, grime=0.6, smudge=0.7)
    SX0, SX1 = 800, 1900
    for z in (150, 700, 1250, 1800):
        bx('shelf', SX0, SX1, FY - 520, FY - 20, z, z + 30, shelf_m, bev=2)
    for x in (SX0, SX1 - 30):
        for y in (FY - 520, FY - 50):
            bx('upright', x, x + 30, y, y + 30, 0, 1900, shelf_m, bev=2)
    kraft = paper('kraft', (0.50, 0.36, 0.22), fibre=1.4, seed=4, grime=0.3)
    for k, (x, z0, n) in enumerate(((SX0 + 60, 180, 9), (SX0 + 420, 180, 6), (SX0 + 60, 730, 12), (SX0 + 450, 730, 4))):
        for i in range(n):
            dx = R.uniform(-8, 8); bx('pbox', x + dx, x + dx + 340, FY - 470, FY - 130, z0 + i * 42, z0 + i * 42 + 40, kraft, bev=2)
    sack = plastic('flour_sack', (0.74, 0.70, 0.60), rough=0.85, seed=6, grime=0.4, sheen_scuffs=0.0)
    for k, x in enumerate((SX0 + 120, SX0 + 560)):   # paper flour sacks, slumped (beveled blocks, a fold on top)
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
    for (ln, ang, w_) in ((100, 345, 6), (70, 255, 8)):   # 23:30
        h_ = bx('hand', -w_ / 2, w_ / 2, 0, 2, 0, ln, black_plastic); h_.location = (clk.x, clk.y - 44, clk.z); h_.rotation_euler = (0, math.radians(ang), 0)
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
    back = bx('end_wall', X0, X1, FY, FY + 250, 0, CEIL, accent)
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


KITS = {'street': kit_street, 'shop': kit_shop, 'corridor': kit_corridor, 'vault': kit_vault}
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
