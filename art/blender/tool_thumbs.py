# Lockwright — VA-14: studio thumbnails of every workshop tool (game/data/tools.json), one per row of the
# Workshop "Narzędzia" tab. Same photo material library as the lock plates (art/textures/photo via
# lw_common.photo_mat), the same stamped-blade geometry as tray.py / cutaway.py (lw_common.flat_tool), the
# magnet probe and dimple flag of plates/tool_layers.py, tray.py's loupe, and optics.py's microscope and
# borescope (its builders are executed without its bench and render block).
# Each tool lies on one neutral, dark, matte leather backing, lit like tray.py (low warm key from the top
# left, cool fill, soft rim); no chrome (metal roughness >= 0.16), no glow, no gold rim light.
# Output: RGB PNG renders at --px (320 = 2x supersample of the 160 px file, i.e. 2x the 80 dp slot in the row).
# Run (CPU is fine, the frames are small):
#   blender -b -P art/blender/tool_thumbs.py -- --out-dir qa/out/tool_thumbs --px 320 --spp 96 \
#       [--tools pk_hook,ob_loupe] [--screen art/renders/borescope_view.png]   # GPU: LW_DEVICE=GPU (lw_common)
#   python art/tools/tool_thumbs_post.py qa/out/tool_thumbs   # -> game/assets/ui/tools/<id>.webp + contact sheet
import bpy, bmesh, math, os, sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, THIS_DIR)
from lw_common import *  # noqa: F401,F403
from lw_common import _noise, _mix, _maprange
from mathutils import Vector, Matrix
from bpy_extras.object_utils import world_to_camera_view

arg = cli()
ROOT = os.path.abspath(os.path.join(THIS_DIR, '..', '..'))
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT, 'qa', 'out', 'tool_thumbs')))
PX = int(arg('--px', '320'))
SPP = int(arg('--spp', '96'))
os.makedirs(OUT_DIR, exist_ok=True)

# ---------------------------------------------------------------- materials (photo library)
STEEL = photo_mat('ph_tool_steel', 'spring_steel_polished', scale=20, rot=0, tint=(0.86, 0.86, 0.87), rough_add=0.10, bump=0.1, wear=0.3)
GROUND = photo_mat('ph_steel_ground', 'steel_ground', scale=30, rot=0, base=(0.50, 0.51, 0.53), base_mix=0.45, bump=0.15, grime=0.3)
BLACKOX = photo_mat('ph_black_oxide', 'spring_steel_polished', scale=20, rot=0, base=(0.07, 0.07, 0.075), base_mix=0.88, rough_add=0.12, bump=0.1, wear=0.5, grime=0.3)
BLUED = photo_mat('ph_heat_tint', 'steel_heat_tint', scale=60, rot=0, rough_add=0.08, bump=0.1, wear=0.4, grime=0.3)
MAGNET = photo_mat('ph_magnet', 'nickel_satin', scale=10, rot=90, base=(0.10, 0.10, 0.11), base_mix=0.75, rough_add=0.12, wear=0.6, grime=0.4)
NICKEL = photo_mat('ph_nickel', 'nickel_satin', scale=30, rot=0, base=(0.60, 0.60, 0.58), base_mix=0.35, wear=0.25, grime=0.5)
BRASS = photo_mat('ph_brass_turned', 'brass_turned', scale=24, rot=90, base=(0.86, 0.64, 0.34), base_mix=0.4, rough_add=0.06, wear=0.4, grime=0.5)
GRIP = photo_mat('ph_grip', 'leather_chocolate', scale=14, rot=0, metallic=0.0, rough_add=0.05, bump=0.3)
WALNUT = photo_mat('ph_walnut', 'g03:walnut_dark', scale=60, rot=0, metallic=0.0, coat=0.3, bump=0.3, grime=0.4)
OAK = photo_mat('ph_oak', 'g03:oak_satin', scale=60, rot=0, metallic=0.0, coat=0.3, bump=0.3, grime=0.4)
COVER = photo_mat('ph_cover', 'leather_brown_worn', scale=70, rot=0, metallic=0.0, tint=(0.62, 0.5, 0.42), rough_add=0.05, bump=0.5,
                  grime=0.6, chamfer_matte=0.0, sheen=0.3)
for k, m in (('t_blackox', BLACKOX), ('t_steel', STEEL), ('t_ground', GROUND), ('t_blued', BLUED), ('t_grip', GRIP)):
    M[k] = m  # flat_tool() takes a key of lw_common.M

RUB = bpy.data.materials.new('loupe_body'); RUB.use_nodes = True   # tray.py's loupe body
_rb = RUB.node_tree.nodes['Principled BSDF']; _rb.inputs['Base Color'].default_value = (0.025, 0.024, 0.023, 1); _rb.inputs['Roughness'].default_value = 0.42


def glass_mat():
    """tray.py: lens glass that lets shadow rays through (no caustics, plain glass would go black)."""
    m = bpy.data.materials.new('glass'); m.use_nodes = True; nt = m.node_tree; l = nt.links
    out = nt.nodes['Material Output']; g = nt.nodes['Principled BSDF']
    g.inputs['Transmission Weight'].default_value = 1.0; g.inputs['Roughness'].default_value = 0.02; g.inputs['IOR'].default_value = 1.52
    g.inputs['Base Color'].default_value = (0.97, 0.99, 0.98, 1)
    tr = nt.nodes.new('ShaderNodeBsdfTransparent'); lp = nt.nodes.new('ShaderNodeLightPath')
    mx = nt.nodes.new('ShaderNodeMixShader'); l.new(lp.outputs['Is Shadow Ray'], mx.inputs[0])
    l.new(g.outputs[0], mx.inputs[1]); l.new(tr.outputs[0], mx.inputs[2]); l.new(mx.outputs[0], out.inputs['Surface'])
    return m


GLASS = glass_mat()


def simple(name, col, rough, metallic=0.0, noise=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    b.inputs['Roughness'].default_value = rough; b.inputs['Metallic'].default_value = metallic
    if noise:
        tc = nt.nodes.new('ShaderNodeTexCoord')
        n = _noise(nt, tc.outputs['Object'], 0.6, detail=6)
        nt.links.new(_mix(nt, (*[c * (1 - noise) for c in col], 1), (*col, 1), n), b.inputs['Base Color'])
    else:
        b.inputs['Base Color'].default_value = (*col, 1)
    return m


PAPER = simple('pages', (0.80, 0.74, 0.62), 0.8, noise=0.15)
GRAPHITE = simple('graphite', (0.06, 0.06, 0.065), 0.35, metallic=0.4)
PENCIL = simple('pencil_paint', (0.07, 0.16, 0.11), 0.38, noise=0.2)   # bottle green lacquer
CEDAR = simple('cedar', (0.55, 0.36, 0.22), 0.6, noise=0.25)
ELASTIC = simple('elastic', (0.03, 0.028, 0.026), 0.7)


# ---------------------------------------------------------------- geometry helpers (Z up, table at z = 0)
TO_TABLE = Matrix.Rotation(-math.pi / 2, 4, 'X')   # tray convention (XZ picture plane, -Y up) -> lying on z = 0


def flat(name, path, height, thick, mat, tip='round'):
    """lw_common.flat_tool lying on the table: path (x, y) in plan, `thick` up from z = 0."""
    o = flat_tool(name, path, height, thick, -thick / 2, mat=mat, tip=tip)
    o.data.transform(TO_TABLE)
    return o


def rod(name, prof, mat, bev=0.05):
    """lathe_x solid of revolution (prof = [(x, r), ...]) resting on the table."""
    rmax = max(r for _, r in prof)
    o = lathe_x(name, prof, seg=72, z=rmax)
    return put(o, mat, bev, 2)


def knurled(name, x0, x1, r, mat, n=60, depth=0.05):
    """Straight-knurl band: a ribbed cylinder along X (alternate vertices pulled in)."""
    rmax = r
    bm = bmesh.new(); rings = []
    for x in (x0, x1):
        ring = []
        for i in range(n * 2):
            a = 2 * math.pi * i / (n * 2); rr = r * (1 - depth * (i % 2))
            ring.append(bm.verts.new((x, rr * math.sin(a), rmax + rr * math.cos(a))))
        rings.append(ring)
    m = n * 2
    for i in range(m):
        bm.faces.new((rings[0][i], rings[0][(i + 1) % m], rings[1][(i + 1) % m], rings[1][i]))
    bm.faces.new(rings[0]); bm.faces.new(list(reversed(rings[1])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    return put(o, mat, 0.03, 1)


def wire(name, pts, r, mat):
    """Round wire along a polyline (x, y, z) with eased bends."""
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = r; cu.bevel_resolution = 4
    cu.use_fill_caps = True
    sp = cu.splines.new('NURBS'); sp.points.add(len(pts) - 1)
    for p, c in zip(sp.points, pts):
        p.co = (*c, 1)
    sp.use_endpoint_u = True; sp.order_u = 3
    o = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(o); o.data.materials.append(mat)
    return o


def handle_grip(x0, x1, h=7.0, t=2.6):
    return flat('grip', [(x0, 0), (x1, 0)], h, t, 't_grip')


def blade_pick(tip, handle=True, h=1.5, t=0.6, mat='t_steel', start=-58.0):
    """tray.py pick: straight shaft then the working end `tip` [(along, lateral)]."""
    pts = [(x, 0.0) for x in range(int(start), int(tip[0][0]), 3)] + list(tip)
    b = flat('blade', pts, h, t, mat)
    b.location.z = (2.6 - t) / 2 if handle else 0.0
    objs = [b]
    if handle:
        objs.append(handle_grip(-62, -8))
    return objs


def wood_handle(mat, x0=-64.0, x1=-10.0, r=4.6, ferrule=True):
    """Turned wooden handle with a brass ferrule (along X, the tool points to +X)."""
    prof = [(x0, 0.001), (x0, r * 0.75), (x0 + 1.5, r * 0.95), (x0 + 8, r), ((x0 + x1) / 2, r * 0.86), (x1 - 6, r * 0.92), (x1, r * 0.8), (x1, 0.001)]
    objs = [rod('handle', prof, mat, 0.2)]
    if ferrule:
        f = rod('ferrule', [(x1 - 0.5, 0.001), (x1 - 0.5, r * 0.82), (x1 + 6, r * 0.7), (x1 + 6, 0.001)], BRASS, 0.1)
        f.location.z = r - r * 0.82
        objs.append(f)
    return objs


def lift_to(objs, z_axis):
    """Put objects whose axis lies at height `cur` onto a common axis height."""
    for o in objs:
        o.location.z += z_axis


def revolve_z(name, loop, seg=128):
    """tray.py revolve_y with height along +Z: closed (r, h) outline revolved around the Z axis."""
    bm = bmesh.new(); rings = []
    for r, h in loop:
        rings.append([bm.verts.new((r * math.cos(2 * math.pi * k / seg), r * math.sin(2 * math.pi * k / seg), h)) for k in range(seg)])
    for a, c in zip(rings, rings[1:] + rings[:1]):
        for k in range(seg):
            bm.faces.new((a[k], a[(k + 1) % seg], c[(k + 1) % seg], c[k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); smooth(o); return o


# ---------------------------------------------------------------- tools (each returns its objects)
def t_tw_angle():   # L-shaped tension wrench, spring steel
    return [flat('tw', [(-40, 0), (10, 0), (12.5, -1.0), (13.6, -3.2), (13.8, -11)], 3.2, 1.0, 't_steel')]


def t_tw_bar():     # top-of-keyway bar, black-oxide spring steel, short leg
    o = flat('bar', [(-42, 0), (8, 0), (10.0, -1.2), (10.8, -3.0), (10.8, -6.5)], 4.6, 1.3, 't_blackox', tip='flat')
    return [o]


def t_tl_shackle():  # shackle puller: flat steel hook on a turned oak T-handle
    hook = flat('hook', [(-26, 0), (14, 0), (18.5, 1.5), (20.5, 5.5), (19, 9.5), (14.5, 10.5), (12, 9)], 4.0, 2.4, 't_ground')
    hook.location.z = 4.0 - 1.2
    t = rod('t', [(-14, 0.001), (-14, 3.8), (-12, 4.6), (12, 4.6), (14, 3.8), (14, 0.001)], OAK, 0.2)
    t.data.transform(Matrix.Rotation(math.pi / 2, 4, 'Z')); t.location.x = -30
    return [hook, t]


def t_pk_peg():     # wooden-pin lifter: blunt round peg on an oak handle
    objs = wood_handle(OAK)
    peg = rod('peg', [(-6, 0.001), (-6, 1.3), (30, 1.3), (32, 1.05), (32.8, 0.5), (33, 0.001)], STEEL, 0.05)
    peg.location.z = 4.6 - 1.3
    return objs + [peg]


def t_pk_hook():
    return blade_pick([(40, 0), (45, 0.3), (48.5, 1.5), (50, 3.4)])


def t_pk_ward():    # warded pick: round wire with a rectangular bit, skeleton-key bow
    shaft = rod('shaft', [(-30, 0.001), (-30, 1.4), (34, 1.4), (34, 0.001)], STEEL, 0.05)
    bit = box('bit', 28, 33.5, -0.8, 0.8, 0.0, 7.0); bit.data.transform(Matrix.Rotation(-math.pi / 2, 4, 'X'))
    bit.location = (0, 0, 1.4); put(bit, STEEL, 0.15, 2)
    bpy.ops.mesh.primitive_torus_add(major_radius=7.5, minor_radius=1.6, major_segments=72, minor_segments=16, location=(-38, 0, 1.6))
    bow = bpy.context.object; bow.name = 'bow'; put(bow, STEEL)
    return [shaft, bit, bow]


def t_pk_ripple():
    return blade_pick([(36, 0), (40, 0.9), (44, -0.3), (48, 0.9), (52, 0)])


def t_pk_wedge():   # double-wafer pick: tall half diamond
    return blade_pick([(44, 0), (46.5, 0.6), (48.6, 1.8), (50.6, 0.9), (52.5, 0)], h=1.8)


def t_pk_lever():   # lever (curtain) pick: round wire, two bends at the tip
    w = wire('lever', [(-40, 0, 1.3), (20, 0, 1.3), (30, 0, 1.3), (33, 0.5, 1.3), (34, 3, 1.3), (34, 8, 1.3), (36.5, 9.5, 1.3), (39, 9.5, 1.3)], 0.75, STEEL)
    return [w, handle_grip(-62, -14, 7.5, 2.6)]


def t_pk_crown():   # tubular pick: brass body, steel collar, ring of seven feelers
    body = rod('body', [(-50, 0.001), (-50, 5.0), (-48, 5.6), (-8, 5.6), (-6, 4.6), (0, 4.6), (0, 0.001)], BRASS, 0.2)
    kn = knurled('knurl', -40, -18, 5.75, BRASS); kn.location.z = 5.6 - 5.75
    col = rod('collar', [(0, 0.001), (0, 4.3), (6, 4.3), (7, 3.6), (7, 0.001)], NICKEL, 0.1); col.location.z = 5.6 - 4.3
    objs = [body, kn, col]
    for k in range(7):
        a = 2 * math.pi * k / 7
        f = rod('feeler%d' % k, [(6, 0.001), (6, 0.28), (14.5, 0.28), (14.8, 0.001)], STEEL, 0.0)
        f.location = (0, 2.8 * math.sin(a), 5.6 - 0.28 + 2.8 * math.cos(a))
        objs.append(f)
    return objs


def t_tl_polar():   # magnet probe (plates/tool_layers.py) on a leather-wrapped handle
    r = 1.0
    o1 = cyl('rod', 0.55, 30.0, (-16.5, 0, r), axis='X', verts=48); put(o1, STEEL, 0.05, 2)
    cap = lathe_x('capsule', [(-3.4, 0.001), (-3.4, 0.9), (-3.0, 0.95), (-0.3, 0.95), (0.0, 0.6), (0.05, 0.001)], seg=64, z=r)
    put(cap, MAGNET)
    band = cyl('band', 1.0, 0.4, (-3.5, 0, r), axis='X', verts=48); put(band, STEEL, 0.05, 2)
    h = rod('grip', [(-58, 0.001), (-58, 3.6), (-56, 4.2), (-34, 4.2), (-31, 3.0), (-31, 0.001)], GRIP, 0.3)
    fer = rod('fer', [(-32, 0.001), (-32, 2.6), (-29, 2.2), (-29, 0.001)], NICKEL, 0.1)
    for o in (o1, cap, band):
        o.location.z += 4.2 - r
    fer.location.z = 4.2 - 2.6
    return [o1, cap, band, h, fer]


def t_pk_flag():    # dimple flag (plates/tool_layers.py): flat bar, paddle bent up at the tip
    bar = box('fbar', -32.0, -0.7, -0.4, 0.4, -2.4, -1.0)
    pad = box('fpad', -1.4, 0.0, -0.4, 0.4, -2.4, 0.0)
    boolean(pad, bar, 'UNION'); put(pad, STEEL, 0.10, 2)
    pad.data.transform(Matrix.Translation((30, 1.2, 0.4)) @ Matrix.Rotation(-math.pi / 2, 4, 'X'))  # on its side: the bend shows in plan
    pad.location.z = 0.9
    return [pad] + [handle_grip(-30, 4, 7, 2.6)]


def t_pk_plunger():  # axial plunger: steel tube, brass knob, thin push rod with a paddle
    tube = rod('tube', [(-30, 0.001), (-30, 2.6), (20, 2.6), (22, 2.0), (22, 0.001)], GROUND, 0.1)
    knob = rod('knob', [(-46, 0.001), (-46, 4.0), (-44, 5.2), (-34, 5.2), (-31, 3.0), (-30, 3.0), (-30, 0.001)], BRASS, 0.2)
    kn = knurled('knurl', -43, -36, 5.35, BRASS); kn.location.z = 5.2 - 5.35
    push = rod('push', [(22, 0.001), (22, 0.7), (34, 0.7), (34, 0.001)], STEEL, 0.0)
    pad = box('pad', 33, 36, -0.25, 0.25, -1.2, 1.2); put(pad, STEEL, 0.06, 2)
    for o in (tube, push):
        o.location.z = 5.2 - max(2.6 if o is tube else 0.7, 0)
    pad.location.z = 5.2
    return [tube, knob, kn, push, pad]


def t_pk_disc():    # disc-detainer turner: nickel body, knurled brass thumb dial, bladed tip
    body = rod('body', [(-50, 0.001), (-50, 4.0), (-48, 4.6), (-2, 4.6), (0, 3.4), (0, 0.001)], NICKEL, 0.2)
    dial = knurled('dial', -8, -3, 8.0, BRASS, n=72, depth=0.035)
    sh = rod('shaft', [(0, 0.001), (0, 2.0), (16, 2.0), (16, 0.001)], GROUND, 0.05)
    tip = box('tip', 16, 20, -0.4, 0.4, -1.6, 1.6); put(tip, STEEL, 0.06, 2)
    for o in (body, sh):
        o.location.z = 8.0 - (4.6 if o is body else 2.0)
    tip.location.z = 8.0
    return [body, dial, sh, tip]


def t_pk_feather():  # sidebar pick: fine long blade, walnut handle, brass ferrule
    objs = wood_handle(WALNUT, -66, -12, 4.4)
    pts = [(x, 0.0) for x in range(-14, 42, 3)] + [(42, 0), (47, 0.35), (51, 1.1), (53, 1.7)]
    b = flat('blade', pts, 1.0, 0.4, 't_steel'); b.location.z = 4.4 - 0.2
    return objs + [b]


def t_tl_cup():     # listening cup: turned brass bell with a rubber ear piece
    bell = lathe_x('bell', [(0, 0.001), (0, 2.4), (6, 2.6), (13, 5.0), (18, 9.6), (20, 11.8), (20.8, 11.8), (20.8, 11.0),
                            (19.6, 9.8), (14.0, 4.4), (6.5, 1.6), (6.5, 0.001)], seg=96, z=11.8)
    put(bell, BRASS, 0.1, 2)
    ear = rod('ear', [(-14, 0.001), (-14, 3.6), (-12, 4.2), (-4, 4.2), (-1, 2.6), (0.5, 2.6), (0.5, 0.001)], RUB, 0.3)
    ear.location.z = 11.8 - 4.2
    return [bell, ear]


def t_tl_notes():   # leather notebook with an elastic band and a pencil
    cover = box('cover', -32, 32, -44, 44, 0, 9); put(cover, COVER, 1.2, 4)
    pages = box('pages', -30.5, 31.2, -42.5, 42.5, 0.9, 8.1); put(pages, PAPER, 0.2, 2)
    band = box('band', 22, 26, -44.6, 44.6, -0.3, 9.4); put(band, ELASTIC, 0.3, 2)
    pen = cyl('pencil', 3.4, 80, (0, 0, 0), axis='X', verts=6); put(pen, PENCIL, 0.15, 2)
    cone = lathe_x('cone', [(40, 0.001), (40, 2.95), (49, 0.7), (49, 0.001)], seg=6); put(cone, CEDAR, 0.05, 1)
    lead = lathe_x('lead', [(48.6, 0.001), (48.6, 0.78), (51, 0.15), (51.2, 0.001)], seg=24); put(lead, GRAPHITE)
    for o in (pen, cone, lead):
        o.location.z = 9 + 3.0
        o.matrix_world = Matrix.Rotation(math.radians(-24), 4, 'Z') @ o.matrix_world
        o.location.x -= 6; o.location.y += 2
    return [cover, pages, band, pen, cone, lead]


def t_kit_clock():  # time-lock kit: watchmaker's screwdriver + tweezers
    body = knurled('body', -30, 20, 3.4, NICKEL, n=70, depth=0.04)
    cap = rod('cap', [(-36, 0.001), (-36, 2.8), (-35, 3.6), (-30, 3.6), (-30, 0.001)], BRASS, 0.15)
    cone = rod('cone', [(20, 0.001), (20, 3.4), (25, 1.2), (25, 0.001)], NICKEL, 0.1)
    blade = rod('blade', [(25, 0.001), (25, 0.9), (38, 0.9), (38, 0.001)], STEEL, 0.0)
    tipb = box('tipb', 37.5, 40, -0.25, 0.25, -0.9, 0.9); put(tipb, STEEL, 0.05, 2)
    cap.location.z = 3.6 - 3.6
    for o in (body,):
        o.location.z = 0.2
    cone.location.z = 0.2
    blade.location.z = 3.6 - 0.9 + 0.0
    tipb.location.z = 3.6
    driver = [body, cap, cone, blade, tipb]
    for o in driver:
        o.location.y += 7
    tw = []
    for s in (1, -1):
        t = flat('tweez', [(-34, 2.0 * s), (-10, 2.6 * s), (20, 1.0 * s), (30, 0.25 * s)], 3.0, 0.8, 't_steel', tip='round')
        t.location.y -= 9; tw.append(t)
    joint = box('joint', -36, -30, -11.6, -6.4, 0, 0.8); put(joint, STEEL, 0.15, 2)
    return driver + tw + [joint]


def t_tl_drill():   # twist drill bit: ground shank, two helical flutes, 118-degree point
    R = 3.0; n_rings = 160; L = 44.0; seg = 64; twist = 2 * math.pi * L / 26.0
    bm = bmesh.new(); rings = []
    for i in range(n_rings + 1):
        x = i / n_rings * L; ang = twist * i / n_rings
        taper = 1.0 if x < L - 2.2 else max(0.02, (L - x) / 2.2)
        ring = []
        for k in range(seg):
            t = 2 * math.pi * k / seg; u = (t % math.pi) / math.pi
            r = R if u < 0.55 else R - 1.95 * math.sin(math.pi * (u - 0.55) / 0.45)
            r *= taper
            a = t + ang
            ring.append(bm.verts.new((x, r * math.sin(a), R + r * math.cos(a))))
        rings.append(ring)
    for a, c in zip(rings, rings[1:]):
        for k in range(seg):
            bm.faces.new((a[k], a[(k + 1) % seg], c[(k + 1) % seg], c[k]))
    bm.faces.new(rings[0]); bm.faces.new(list(reversed(rings[-1])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new('flutes'); bm.to_mesh(me); bm.free()
    fl = bpy.data.objects.new('flutes', me); bpy.context.collection.objects.link(fl); smooth(fl); fl.data.materials.append(BLUED)
    sh = rod('shank', [(-40, 0.001), (-40, 2.6), (-39.4, 3.0), (0.2, 3.0), (0.2, 0.001)], GROUND, 0.1)
    return [fl, sh]


def t_ob_loupe():   # tray.py: watchmaker's loupe standing lens-up, ribbed body, brass ring, glass
    body_loop = [(13.0, 0.0), (15.2, 0.0), (15.4, 0.5)]
    for k in range(9):
        h0 = 1.2 + k * 1.25; r0 = 15.4 - k * 0.33
        body_loop += [(r0, h0), (r0 + 0.35, h0 + 0.35), (r0 + 0.35, h0 + 0.8), (r0 - 0.05, h0 + 1.1)]
    body_loop += [(12.3, 13.0), (12.2, 14.5), (10.8, 14.6), (10.6, 1.0), (12.4, 0.6)]
    body = revolve_z('loupe', body_loop); put(body, RUB)
    ring = revolve_z('ring', [(10.2, 14.2), (12.4, 14.2), (12.5, 16.4), (12.1, 16.9), (10.3, 16.9), (10.0, 16.2)]); put(ring, BRASS)
    lens = revolve_z('lens', [(0.0, 15.1), (10.3, 15.1), (10.3, 15.7), (9.6, 16.5), (5.0, 16.95), (0.0, 17.05)]); put(lens, GLASS)
    return [body, ring, lens]


_OPTICS = None


def _optics_ns():
    """optics.py's builders and materials, without its bench and its render block."""
    global _OPTICS
    if _OPTICS is None:
        src = open(os.path.join(THIS_DIR, 'optics.py'), encoding='utf-8').read()
        head = src.split('# ================================================================ scene')[0]
        ns = {'__file__': os.path.join(THIS_DIR, 'optics.py'), '__name__': 'optics_lib'}
        exec(compile(head, 'optics.py', 'exec'), ns)
        ns['bench'] = lambda: None
        _OPTICS = ns
    return _OPTICS


def t_ob_microscope():
    _optics_ns()['microscope']()
    return None   # collected by the caller (all new objects)


def t_ob_borescope():
    _optics_ns()['borescope']()
    return None


# per tool: builder, yaw of the tool in plan (deg), camera pitch above the table (deg), camera yaw
TOOLS = {
    'tw_angle': (t_tw_angle, 32, 62, -12),
    'tw_bar': (t_tw_bar, 32, 62, -12),
    'tl_shackle': (t_tl_shackle, 30, 58, -12),
    'pk_peg': (t_pk_peg, 32, 58, -12),
    'pk_hook': (t_pk_hook, 32, 62, -12),
    'pk_ward': (t_pk_ward, 32, 60, -12),
    'pk_ripple': (t_pk_ripple, 32, 62, -12),
    'pk_wedge': (t_pk_wedge, 32, 62, -12),
    'pk_lever': (t_pk_lever, 32, 62, -12),
    'pk_crown': (t_pk_crown, 30, 50, -12),
    'tl_polar': (t_tl_polar, 32, 58, -12),
    'pk_flag': (t_pk_flag, 32, 62, -12),
    'pk_plunger': (t_pk_plunger, 30, 52, -12),
    'pk_disc': (t_pk_disc, 30, 50, -12),
    'pk_feather': (t_pk_feather, 32, 58, -12),
    'tl_cup': (t_tl_cup, 24, 40, -24),
    'tl_notes': (t_tl_notes, 12, 58, -10),
    'kit_clock': (t_kit_clock, 30, 60, -12),
    'tl_drill': (t_tl_drill, 30, 52, -12),
    'ob_loupe': (t_ob_loupe, 0, 42, -14),
    'ob_microscope': (t_ob_microscope, 0, 24, -28),
    'ob_borescope': (t_ob_borescope, 0, 50, -12),
}
ZOOM = {'pk_hook': 1.9, 'pk_ripple': 1.8, 'pk_wedge': 1.9, 'pk_feather': 1.9, 'pk_lever': 1.6, 'pk_flag': 1.5,
        'tw_angle': 1.15, 'tw_bar': 1.15, 'pk_peg': 1.3, 'pk_ward': 1.2, 'tl_polar': 1.4}
WANT = arg('--tools', ','.join(TOOLS)).split(',')


# ---------------------------------------------------------------- build every tool in its own collection
def build(tid):
    before = set(bpy.data.objects)
    coll = bpy.data.collections.new(tid); scene.collection.children.link(coll)
    fn, yaw, _, _ = TOOLS[tid]
    fn()
    new = [o for o in bpy.data.objects if o not in before and o.type in ('MESH', 'CURVE')]
    for o in new:
        for c in list(o.users_collection):
            c.objects.unlink(o)
        coll.objects.link(o)
    if yaw:
        R = Matrix.Rotation(math.radians(yaw), 4, 'Z')
        for o in new:
            o.matrix_world = R @ o.matrix_world
    return coll, new


def bbox(objs):
    dg = bpy.context.evaluated_depsgraph_get()
    pts = []
    for o in objs:
        oe = o.evaluated_get(dg)
        pts += [oe.matrix_world @ Vector(c) for c in oe.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi, pts


world_hdri(0.05, sat=0.35)
cam = look_camera((0, 0, 0), -12, 60, 300, lens=85)
cam.data.clip_start = 1; cam.data.clip_end = 50000
render_setup(os.path.join(OUT_DIR, '_tmp.png'), [PX, PX], SPP, exposure=float(arg('--exp', '0.2')))
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM)
KEY = area_light('key', (0, 0, 100), AIM, 50, 1000, (1.0, 0.85, 0.68))
FILL = area_light('fill', (0, 0, 100), AIM, 100, 1000, (0.90, 0.94, 1.0))
RIM = area_light('rim', (0, 0, 100), AIM, 60, 1000, (1.0, 0.95, 0.88))

colls = {}
for tid in WANT:
    colls[tid] = build(tid)
    colls[tid][0].hide_render = True

for tid in WANT:
    coll, objs = colls[tid]
    _, _, pitch, cyaw = TOOLS[tid]
    lo, hi, _ = bbox(objs)
    # rest on the table, centred on the origin
    off = Vector((-(lo.x + hi.x) / 2, -(lo.y + hi.y) / 2, -lo.z))
    for o in objs:
        o.location += off
    lo, hi, pts = bbox(objs)
    size = max(hi.x - lo.x, hi.y - lo.y, hi.z - lo.z)
    tgt = Vector((0, 0, (hi.z - lo.z) * 0.35))
    zoom = ZOOM.get(tid, 1.0)
    if zoom > 1.0:  # long thin tools: frame the working end, the handle runs out of the frame
        yaw = math.radians(TOOLS[tid][1])
        # the frame spans ~size / (0.8 * zoom): put the tip ~72 % of the way from the centre to the edge
        tgt += Vector((math.cos(yaw), math.sin(yaw), 0)) * max(0.0, size * 0.5 - 0.72 * size / (1.6 * zoom))
    # backing: dark matte leather, grain scaled to the tool so every thumbnail reads the same
    bpy.ops.mesh.primitive_plane_add(size=size * 300, location=(0, 0, 0)); bk = bpy.context.object; bk.name = 'backing'
    bkm = photo_mat('ph_backing_' + tid, 'leather_chocolate', scale=max(size * 3.0, 60), rot=20, plane='XY', metallic=0.0,
                    base=(0.10, 0.095, 0.09), base_mix=0.55, tint=(0.62, 0.6, 0.58), rough_add=0.15, bump=0.15,
                    chamfer_matte=0.0, sheen=0.15)
    bk.data.materials.append(bkm)
    coll.hide_render = False
    # camera: fit the tool's projected bounds into the middle 80 % of the frame
    dist = size * 2.2
    for _ in range(3):
        c2 = look_camera(tuple(tgt), cyaw, pitch, dist, lens=85)
        scene.camera = c2
        bpy.context.view_layer.update()
        pr = [world_to_camera_view(scene, c2, p) for p in pts]
        xs = [p.x for p in pr]; ys = [p.y for p in pr]
        ext = max(max(xs) - min(xs), max(ys) - min(ys))
        c2.data.shift_x = ((max(xs) + min(xs)) / 2 - 0.5)
        c2.data.shift_y = ((max(ys) + min(ys)) / 2 - 0.5)
        dist *= ext / (0.8 * zoom)
        bpy.data.objects.remove(c2, do_unlink=True)
    cam = look_camera(tuple(tgt), cyaw, pitch, dist, lens=85)
    cam.data.clip_start = max(dist * 0.01, 0.5); cam.data.clip_end = dist * 50
    bpy.context.view_layer.update()
    pr = [world_to_camera_view(scene, cam, p) for p in pts]
    xs = [p.x for p in pr]; ys = [p.y for p in pr]
    if zoom <= 1.0:  # centre the whole tool; a zoomed one stays centred on its working end
        cam.data.shift_x = ((max(xs) + min(xs)) / 2 - 0.5)
        cam.data.shift_y = ((max(ys) + min(ys)) / 2 - 0.5)
    scene.camera = cam
    # lights scale with the frame (Blender's power units are metre-based: power ~ distance^2)
    AIM.location = tgt
    d = dist
    k = (d / 318.0) ** 2
    KEY.location = tgt + Vector((-0.75, -0.35, 0.62)) * d; KEY.data.size = 0.25 * d; KEY.data.energy = 260000 * k
    FILL.location = tgt + Vector((0.65, -0.8, 0.2)) * d; FILL.data.size = 0.5 * d; FILL.data.energy = 40000 * k
    RIM.location = tgt + Vector((0.35, 0.75, 0.55)) * d; RIM.data.size = 0.2 * d; RIM.data.energy = 70000 * k
    scene.render.filepath = os.path.join(OUT_DIR, tid + '.png')
    bpy.ops.render.render(write_still=True)
    print('WROTE', tid, 'size %.1f mm, dist %.0f' % (size, dist), flush=True)
    coll.hide_render = True
    bpy.data.objects.remove(bk, do_unlink=True)
    bpy.data.objects.remove(cam, do_unlink=True)
print('DONE')
