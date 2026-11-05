# Lockwright — shared helpers for photoreal ENVIRONMENT scenes (stairwell, workshop). 1 unit = 1 mm.
# Builds on lw_common (scene reset, mesh helpers, node helpers). Everything is procedural: no downloaded
# models or textures; the only image used is Blender's bundled CC0 studio HDRI (lw_common.world_hdri).
import bpy, bmesh, math, os, sys, json, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lw_common import *
from lw_common import _noise, _mix, _maprange, _edge_mask, _cavity_mask
from mathutils import Vector, Matrix

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
FONTS = os.path.join(ROOT, 'mockups', 'fonts')

# ---------------------------------------------------------------- geometry (object coords == world coords)
def bx(name, x0, x1, y0, y1, z0, z1, mat=None, bev=None, seg=3):
    """Axis-aligned box whose object space equals world space (so procedural textures line up across pieces)."""
    me = bpy.data.meshes.new(name); bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector(((x0 + x1) / 2 + v.co.x * (x1 - x0), (y0 + y1) / 2 + v.co.y * (y1 - y0), (z0 + z1) / 2 + v.co.z * (z1 - z0)))
    bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    if mat: o.data.materials.append(mat)
    if bev: _bev(o, bev, seg)
    return o

def _bev(o, w, seg=3, angle=40):
    md = o.modifiers.new('bev', 'BEVEL'); md.width = w; md.segments = seg; md.limit_method = 'ANGLE'
    md.angle_limit = math.radians(angle); md.harden_normals = True
    o.modifiers.new('wn', 'WEIGHTED_NORMAL').keep_sharp = True
    for p in o.data.polygons: p.use_smooth = True

def setmat(o, mat):
    o.data.materials.clear(); o.data.materials.append(mat); return o

def cut(target, cutter):
    boolean(target, cutter, 'DIFFERENCE'); return target

def tube(name, pts, r, mat=None, res=6, smooth_pts=True, caps=True):
    """Round bar / cable along a polyline (Catmull-Rom smoothed)."""
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = r; cu.bevel_resolution = res
    cu.use_fill_caps = caps
    P = [Vector(p) for p in pts]
    if smooth_pts and len(P) > 2:
        from lw_common import _catmull
        P = _catmull(P, 10)
    sp = cu.splines.new('POLY'); sp.points.add(len(P) - 1)
    for i, p in enumerate(P): sp.points[i].co = (p.x, p.y, p.z, 1)
    o = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(o)
    if mat: o.data.materials.append(mat)
    return o

def rounded_rect(w, h, r, n=8):
    pts = []
    for cx, cy, a0 in ((w / 2 - r, h / 2 - r, 0), (-w / 2 + r, h / 2 - r, 90), (-w / 2 + r, -h / 2 + r, 180), (w / 2 - r, -h / 2 + r, 270)):
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n); pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts

def slab(name, outline, thick, mat=None, bev=None, seg=3):
    """Extrude a closed 2D outline (u, v) along +Z by `thick` (object local), origin at outline origin."""
    bm = bmesh.new(); vs = [bm.verts.new((u, v, 0)) for u, v in outline]; f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [g for g in ext['geom'] if isinstance(g, bmesh.types.BMVert)]: v.co.z = thick
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    if mat: o.data.materials.append(mat)
    if bev: _bev(o, bev, seg)
    return o

def place(o, loc, rot=(0, 0, 0)):
    """Bake a rotation (degrees XYZ) and location into the mesh, so object space == world space."""
    R = Matrix.Rotation(math.radians(rot[2]), 4, 'Z') @ Matrix.Rotation(math.radians(rot[1]), 4, 'Y') @ Matrix.Rotation(math.radians(rot[0]), 4, 'X')
    if o.type == 'MESH': o.data.transform(Matrix.Translation(Vector(loc)) @ R)
    else: o.matrix_world = Matrix.Translation(Vector(loc)) @ R
    return o

def text_obj(name, body, size, font='BonaNova-Bold.ttf', extrude=0.3, align='CENTER', mat=None):
    cu = bpy.data.curves.new(name, 'FONT'); cu.body = body; cu.size = size; cu.extrude = extrude
    cu.font = bpy.data.fonts.load(os.path.join(FONTS, font)); cu.align_x = align; cu.align_y = 'CENTER'
    cu.bevel_depth = min(0.15, extrude * 0.4); cu.bevel_resolution = 2
    o = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(o)
    if mat: o.data.materials.append(mat)
    return o

# ---------------------------------------------------------------- shading helpers
def _new(name):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree
    return m, nt, nt.links, nt.nodes['Principled BSDF'], nt.nodes.new('ShaderNodeTexCoord').outputs['Object']

def _sep(nt, vec):
    s = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(vec, s.inputs[0]); return s.outputs

def _math(nt, op, a, b=None, c=None):
    m = nt.nodes.new('ShaderNodeMath'); m.operation = op
    for i, v in enumerate((a, b, c)):
        if v is None: continue
        if hasattr(v, 'links'): nt.links.new(v, m.inputs[i])
        else: m.inputs[i].default_value = v
    return m.outputs[0]

def _bump(nt, h, strength, dist, normal=None):
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = strength; bp.inputs['Distance'].default_value = dist
    nt.links.new(h, bp.inputs['Height'])
    if normal is not None: nt.links.new(normal, bp.inputs['Normal'])
    return bp.outputs['Normal']

def _ramp(nt, fac, stops, interp='LINEAR'):
    cr = nt.nodes.new('ShaderNodeValToRGB'); cr.color_ramp.interpolation = interp; e = cr.color_ramp.elements
    e[0].position, e[0].color = stops[0][0], (*stops[0][1], 1)
    e[1].position, e[1].color = stops[-1][0], (*stops[-1][1], 1)
    for p, c in stops[1:-1]:
        x = e.new(p); x.color = (*c, 1)
    nt.links.new(fac, cr.inputs['Fac']); return cr.outputs['Color']

def _offset(nt, P, seed):
    if not seed: return P
    mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (seed * 131.7, seed * 57.3, seed * 291.1)
    nt.links.new(P, mp.inputs['Vector']); return mp.outputs['Vector']

def jitter(c, amt, rng):
    k = 1 + rng.uniform(-amt, amt); h = rng.uniform(-amt, amt) * 0.5
    return (max(0, c[0] * k * (1 + h)), max(0, c[1] * k), max(0, c[2] * k * (1 - h)))

# ---------------------------------------------------------------- materials
def oak(name, light=(0.50, 0.33, 0.18), dark=(0.23, 0.12, 0.055), axis='Z', seed=0.0, ring=2.4, incline=0.018,
        depth=110.0, coat=0.9, coat_rough=0.2, rough=0.5, wear=0.5, grime=0.6, pores=1.0, flecks=0.0, varnish_tint=0.0,
        center=(0.0, 0.0, 0.0), contrast=1.0):
    """Flat-sawn ring-porous hardwood. The board is cut slightly inclined to the log axis, so ring radius changes
    along the length and the rings draw cathedral arches (not parallel stripes); ring widths vary, earlywood
    carries open pores, a varnish coat sits on top. Object coords in mm; `axis` = grain direction."""
    m, nt, l, b, P = _new(name)
    if any(center):  # pith of this board's log: per-piece, so neighbouring boards never share a figure
        c0 = nt.nodes.new('ShaderNodeMapping'); c0.inputs['Location'].default_value = tuple(-c for c in center)
        l.new(P, c0.inputs['Vector']); P = c0.outputs['Vector']
    mp = nt.nodes.new('ShaderNodeMapping'); l.new(P, mp.inputs['Vector'])
    mp.inputs['Rotation'].default_value = {'X': (0, math.pi / 2, 0), 'Y': (math.pi / 2, 0, 0), 'Z': (0, 0, 0)}[axis]
    Q = mp.outputs['Vector']; X, Y, Z = _sep(nt, Q)
    Q = _offset(nt, Q, seed)          # noise seed only (the ring geometry stays centred on the board)
    # low-frequency figure: the log is not a perfect cylinder
    w1 = _noise(nt, Q, 0.004, detail=3, rough=0.5, stretch=(1, 1, 0.12))
    w2 = _noise(nt, Q, 0.02, detail=4, rough=0.55, stretch=(1, 1, 0.08))
    d = _math(nt, 'MULTIPLY_ADD', Z, incline, depth + seed * 13 % 40)
    d = _math(nt, 'ADD', d, Y)
    d = _math(nt, 'MULTIPLY_ADD', _math(nt, 'SUBTRACT', w1, 0.5), 60.0, d)
    xx = _math(nt, 'MULTIPLY_ADD', _math(nt, 'SUBTRACT', w2, 0.5), 9.0, X)
    r = _math(nt, 'SQRT', _math(nt, 'ADD', _math(nt, 'MULTIPLY', xx, xx), _math(nt, 'MULTIPLY', d, d)))
    # irregular ring widths: noise of the radius itself
    rn = nt.nodes.new('ShaderNodeTexNoise'); rn.noise_dimensions = '1D'; rn.inputs['Scale'].default_value = 0.08; rn.inputs['Detail'].default_value = 5
    l.new(r, rn.inputs['W'])
    r2 = _math(nt, 'MULTIPLY_ADD', rn.outputs['Fac'], ring * 6.0, r)
    t = _math(nt, 'FRACT', _math(nt, 'DIVIDE', r2, ring))
    late = _maprange(nt, t, 0.55, 0.97)                          # latewood band at the end of each ring
    late = _math(nt, 'POWER', late, 1.6)
    late = _math(nt, 'MULTIPLY', late, contrast)
    col = _mix(nt, (*light, 1), (*dark, 1), late)
    # pores: in the earlywood, short stretched dark dashes along the grain
    po = _noise(nt, Q, 2.2, detail=3, rough=0.5, stretch=(1, 1, 0.035))
    pm = _maprange(nt, po, 0.58, 0.7, 0.0, 0.55 * pores)
    pm = _math(nt, 'MULTIPLY', pm, _maprange(nt, t, 0.0, 0.5, 1.0, 0.25))
    col = _mix(nt, col, (*[c * 0.35 for c in dark], 1), pm)
    # fine fibre streaks + mineral/colour streaks along the board
    fs = _noise(nt, Q, 0.9, detail=8, rough=0.65, stretch=(1, 1, 0.01))
    col = _mix(nt, col, (*[c * 0.78 for c in light], 1), _maprange(nt, fs, 0.35, 0.75, 0.0, 0.35))
    ms = _noise(nt, Q, 0.012, detail=3, stretch=(1, 1, 0.15))
    col = _mix(nt, col, (*[c * 0.7 for c in dark], 1), _maprange(nt, ms, 0.5, 0.75, 0.0, 0.45))
    if flecks:  # medullary ray flecks
        fl = nt.nodes.new('ShaderNodeTexVoronoi'); fl.inputs['Scale'].default_value = 0.35
        st = nt.nodes.new('ShaderNodeMapping'); st.inputs['Scale'].default_value = (1.0, 1.0, 0.12); l.new(Q, st.inputs['Vector']); l.new(st.outputs['Vector'], fl.inputs['Vector'])
        fm = _maprange(nt, fl.outputs['Distance'], 0.08, 0.02, 0.0, flecks)
        col = _mix(nt, col, (*[min(1, c * 1.2) for c in light], 1), fm)
    if varnish_tint:
        col = _mix(nt, col, (0.35, 0.16, 0.05, 1), varnish_tint, mode='MULTIPLY')
    if wear:
        em = _edge_mask(nt, 1.5, 0.6, 0.97)
        wm = _maprange(nt, _mix(nt, 0.0, em, _noise(nt, Q, 0.08, detail=5), dtype='FLOAT'), 0.2, 0.5, 0.0, wear)
        col = _mix(nt, col, (*[min(1, c * 1.35) for c in light], 1), wm)
    if grime:
        cm = _maprange(nt, _cavity_mask(nt, 6.0, 0.3, 0.92), 0, 1, 0, grime)
        col = _mix(nt, col, (0.04, 0.025, 0.015, 1), cm)
    l.new(col, b.inputs['Base Color'])
    rr = _maprange(nt, late, 0, 1, rough - 0.06, rough + 0.06)
    rr = _mix(nt, rr, rough + 0.25, pm, dtype='FLOAT')
    l.new(rr, b.inputs['Roughness'])
    b.inputs['Coat Weight'].default_value = coat; b.inputs['Coat IOR'].default_value = 1.5
    cr_ = _maprange(nt, _noise(nt, Q, 0.01, detail=4, stretch=(1, 1, 0.3)), 0.3, 0.7, coat_rough * 0.6, coat_rough * 1.8)
    l.new(cr_, b.inputs['Coat Roughness'])
    h = _mix(nt, _math(nt, 'MULTIPLY', late, 0.3), 0.0, pm, dtype='FLOAT')
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.8
    nrm = _bump(nt, h, 0.35, 0.06, bv.outputs['Normal'])
    l.new(nrm, b.inputs['Normal'])
    # varnish follows the wood loosely: brush ripples, dust nibs
    vb = _mix(nt, _noise(nt, Q, 0.05, detail=6, stretch=(1, 1, 0.1)), _noise(nt, Q, 3.0, detail=2), 0.25, dtype='FLOAT')
    l.new(_bump(nt, vb, 0.08, 0.05, bv.outputs['Normal']), b.inputs['Coat Normal'])
    return m

def oil_paint(name, color, rough=0.3, under=(0.62, 0.56, 0.42), base=(0.55, 0.5, 0.42), chips=0.4, scuffs=0.4,
              grime=0.6, strokes='Z', seed=0.0, chip_scale=0.02, edge_chips=0.6):
    """Several layers of glossy oil paint over plaster/wood: brush strokes, orange peel, scuffs (matte, lighter),
    chips through to an older layer and the substrate, dirt in corners."""
    m, nt, l, b, P = _new(name); P = _offset(nt, P, seed)
    st = (0.02, 1, 1) if strokes == 'X' else ((1, 1, 0.02) if strokes == 'Z' else (1, 0.02, 1))
    br = _noise(nt, P, 0.6, detail=6, rough=0.6, stretch=st)
    tv = _noise(nt, P, 0.003, detail=4)
    col = _mix(nt, (*[c * 0.88 for c in color], 1), (*[min(1, c * 1.1) for c in color], 1), tv)
    col = _mix(nt, col, (*[c * 0.93 for c in color], 1), _maprange(nt, br, 0.4, 0.6, 0, 0.6))
    # chips: sparse irregular flakes, more on convex edges
    ch = _noise(nt, P, chip_scale, detail=10, rough=0.72, dist=0.4)
    em = _edge_mask(nt, 2.0, 0.6, 0.97)
    chm = _math(nt, 'ADD', ch, _math(nt, 'MULTIPLY', em, 0.25 * edge_chips))
    chip1 = _maprange(nt, chm, 0.80 - chips * 0.18, 0.82 - chips * 0.18)       # top coat gone
    chip2 = _maprange(nt, chm, 0.86 - chips * 0.16, 0.875 - chips * 0.16)      # down to substrate
    col = _mix(nt, col, (*under, 1), chip1)
    col = _mix(nt, col, (*base, 1), chip2)
    # scuffs: horizontal rub marks, matte and lighter
    sc = _noise(nt, P, 0.05, detail=8, rough=0.7, stretch=(0.08, 1, 1.6))
    scm = _maprange(nt, sc, 0.66 - scuffs * 0.08, 0.8 - scuffs * 0.08, 0, 0.6)
    col = _mix(nt, col, (*[min(1, c * 1.3 + 0.04) for c in color], 1), scm)
    cm = _maprange(nt, _cavity_mask(nt, 8.0, 0.3, 0.95), 0, 1, 0, grime)
    dn = _noise(nt, P, 0.01, detail=6)
    col = _mix(nt, col, (0.06, 0.05, 0.035, 1), _math(nt, 'MULTIPLY', cm, _maprange(nt, dn, 0.3, 0.7, 0.5, 1.0)))
    l.new(col, b.inputs['Base Color'])
    r = _maprange(nt, _noise(nt, P, 0.02, detail=5), 0.3, 0.7, rough * 0.75, rough * 1.35)
    r = _mix(nt, r, 0.75, chip1, dtype='FLOAT'); r = _mix(nt, r, 0.6, scm, dtype='FLOAT'); r = _mix(nt, r, 0.8, cm, dtype='FLOAT')
    l.new(r, b.inputs['Roughness'])
    # height: strokes + orange peel + chip steps
    op = _noise(nt, P, 1.5, detail=2, rough=0.4)
    h = _mix(nt, _mix(nt, br, op, 0.4, dtype='FLOAT'), 0.0, _math(nt, 'MAXIMUM', chip1, chip2), dtype='FLOAT')
    h = _math(nt, 'SUBTRACT', h, _math(nt, 'MULTIPLY', chip2, 0.5))
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 1.2
    l.new(_bump(nt, h, 0.25, 0.25, bv.outputs['Normal']), b.inputs['Normal'])
    return m

def lime_wall(name, color=(0.74, 0.70, 0.62), seed=0.0, dirt=0.5, cracks=0.5):
    """Matte distemper/lime paint over old plaster: trowel undulation, sand grain, stains, hairline cracks."""
    m, nt, l, b, P = _new(name); P = _offset(nt, P, seed)
    big = _noise(nt, P, 0.0018, detail=5, rough=0.6)
    mid = _noise(nt, P, 0.012, detail=8, rough=0.65)
    col = _mix(nt, (*[c * 0.86 for c in color], 1), (*color, 1), _maprange(nt, big, 0.3, 0.7))
    stain = _maprange(nt, _noise(nt, P, 0.004, detail=8, rough=0.7, dist=0.6), 0.55, 0.8, 0, 0.35 * dirt)
    col = _mix(nt, col, (0.45, 0.38, 0.28, 1), stain)
    # hairline cracks: thin ridges of a noise field, gated to a few regions
    cn = _noise(nt, P, 0.006, detail=6, rough=0.6, dist=0.3)
    ab = _math(nt, 'ABSOLUTE', _math(nt, 'SUBTRACT', cn, 0.5))
    gate = _maprange(nt, _noise(nt, P, 0.0015, detail=2), 0.55, 0.62, 0, cracks)
    crk = _math(nt, 'MULTIPLY', _maprange(nt, ab, 0.006, 0.0), gate)
    col = _mix(nt, col, (0.22, 0.19, 0.15, 1), crk)
    cm = _maprange(nt, _cavity_mask(nt, 40.0, 0.4, 0.97), 0, 1, 0, dirt)
    col = _mix(nt, col, (0.3, 0.25, 0.18, 1), cm)
    l.new(col, b.inputs['Base Color'])
    l.new(_maprange(nt, mid, 0.3, 0.7, 0.82, 0.95), b.inputs['Roughness'])
    sand = _noise(nt, P, 1.2, detail=2, rough=0.5)
    h = _mix(nt, _mix(nt, big, mid, 0.5, dtype='FLOAT'), sand, 0.25, dtype='FLOAT')
    h = _math(nt, 'SUBTRACT', h, _math(nt, 'MULTIPLY', crk, 0.3))
    l.new(_bump(nt, h, 0.22, 0.6), b.inputs['Normal'])
    b.inputs['Specular IOR Level'].default_value = 0.3
    return m

def terrazzo(name, matrix=(0.42, 0.40, 0.36), seed=0.0, polish=0.6, worn_center=None, worn_r=(500, 400)):
    """Cast terrazzo (lastryko): marble chips of several sizes in grey cement, ground and polished, then worn."""
    m, nt, l, b, P = _new(name); P = _offset(nt, P, seed)
    def chips(scale, thr, pal):
        dn = nt.nodes.new('ShaderNodeTexNoise'); dn.inputs['Scale'].default_value = scale * 2.5; dn.inputs['Detail'].default_value = 3
        l.new(P, dn.inputs['Vector'])
        dv = nt.nodes.new('ShaderNodeVectorMath'); dv.operation = 'MULTIPLY_ADD'
        l.new(dn.outputs['Color'], dv.inputs[0]); dv.inputs[1].default_value = (0.35 / scale,) * 3; l.new(P, dv.inputs[2])
        vo = nt.nodes.new('ShaderNodeTexVoronoi'); vo.inputs['Scale'].default_value = scale; vo.inputs['Randomness'].default_value = 1.0
        l.new(dv.outputs['Vector'], vo.inputs['Vector'])
        vd = nt.nodes.new('ShaderNodeTexVoronoi'); vd.feature = 'DISTANCE_TO_EDGE'; vd.inputs['Scale'].default_value = scale
        vd.inputs['Randomness'].default_value = 1.0; l.new(dv.outputs['Vector'], vd.inputs['Vector'])
        mask = _maprange(nt, vd.outputs['Distance'], thr, thr + 0.04)          # chip interior, matrix along cell edges
        cc = _sep(nt, vo.outputs['Color'])[0]
        return mask, _ramp(nt, cc, pal, 'CONSTANT'), cc
    pal1 = [(0.0, (0.80, 0.78, 0.72)), (0.30, (0.55, 0.53, 0.50)), (0.50, (0.12, 0.11, 0.105)), (0.62, (0.62, 0.42, 0.30)),
            (0.75, (0.86, 0.84, 0.78)), (0.88, (0.38, 0.22, 0.16)), (1.0, (0.70, 0.66, 0.58))]
    pal2 = [(0.0, (0.74, 0.72, 0.66)), (0.4, (0.20, 0.19, 0.18)), (0.6, (0.88, 0.86, 0.80)), (0.8, (0.52, 0.36, 0.26)), (1.0, (0.60, 0.58, 0.54))]
    m1, c1, k1 = chips(0.05, 0.10, pal1)
    m2, c2, k2 = chips(0.16, 0.13, pal2)
    m3, c3, k3 = chips(0.55, 0.22, pal2)
    mtx = _mix(nt, (*[c * 0.85 for c in matrix], 1), (*matrix, 1), _noise(nt, P, 0.02, detail=6))
    col = _mix(nt, mtx, c3, m3); col = _mix(nt, col, c2, m2); col = _mix(nt, col, c1, m1)
    # inside each chip: marble veining / tone variation
    vein = _noise(nt, P, 0.25, detail=8, rough=0.7)
    col = _mix(nt, col, (0.5, 0.48, 0.45, 1), _math(nt, 'MULTIPLY', _maprange(nt, vein, 0.55, 0.7, 0, 0.3), m1))
    # wear: dull and grey along the walking path, dirt in the joints and along walls
    X, Y, Zc = _sep(nt, P)
    worn = None
    if worn_center:
        dx = _math(nt, 'DIVIDE', _math(nt, 'SUBTRACT', X, worn_center[0] + seed * 131.7), worn_r[0])
        dy = _math(nt, 'DIVIDE', _math(nt, 'SUBTRACT', Y, worn_center[1] + seed * 57.3), worn_r[1])
        rr = _math(nt, 'SQRT', _math(nt, 'ADD', _math(nt, 'MULTIPLY', dx, dx), _math(nt, 'MULTIPLY', dy, dy)))
        worn = _maprange(nt, rr, 1.0, 0.2)
        wn = _noise(nt, P, 0.01, detail=5)
        worn = _math(nt, 'MULTIPLY', worn, _maprange(nt, wn, 0.3, 0.7, 0.5, 1.0))
        col = _mix(nt, col, (0.36, 0.34, 0.31, 1), _math(nt, 'MULTIPLY', worn, 0.35))
    dirt = _maprange(nt, _noise(nt, P, 0.006, detail=8, rough=0.7), 0.5, 0.8, 0, 0.35)
    col = _mix(nt, col, (0.16, 0.14, 0.11, 1), dirt)
    cm = _maprange(nt, _cavity_mask(nt, 25.0, 0.4, 0.95), 0, 1, 0, 0.8)
    col = _mix(nt, col, (0.08, 0.07, 0.055, 1), cm)
    l.new(col, b.inputs['Base Color'])
    r = _maprange(nt, _noise(nt, P, 0.05, detail=6), 0.3, 0.7, 0.18, 0.32)
    r = _mix(nt, r, 0.5, _math(nt, 'MULTIPLY', m1, 0.0 + (1 - polish)), dtype='FLOAT')
    if worn is not None: r = _mix(nt, r, 0.55, worn, dtype='FLOAT')
    r = _mix(nt, r, 0.7, dirt, dtype='FLOAT'); r = _mix(nt, r, 0.85, cm, dtype='FLOAT')
    l.new(r, b.inputs['Roughness'])
    # micro scratches + chip relief + pits
    scr = _noise(nt, P, 0.4, detail=10, rough=0.75, stretch=(0.03, 1, 1))
    pit = _maprange(nt, _noise(nt, P, 0.9, detail=2), 0.72, 0.8, 0, 1)
    h = _math(nt, 'SUBTRACT', _mix(nt, _math(nt, 'MULTIPLY', m1, 0.15), scr, 0.3, dtype='FLOAT'), pit)
    l.new(_bump(nt, h, 0.15, 0.15), b.inputs['Normal'])
    return m

def enamel(name, color, rough=0.06, chip=0.5, iron_col=(0.05, 0.045, 0.04)):
    """Vitreous enamel on pressed steel: glassy, slightly wavy, chipped to black iron at the rim and holes."""
    m, nt, l, b, P = _new(name)
    col = _mix(nt, (*color, 1), (*[c * 0.85 for c in color], 1), _noise(nt, P, 0.05, detail=4))
    em = _edge_mask(nt, 1.2, 0.55, 0.97)
    ch = _maprange(nt, _mix(nt, em, _noise(nt, P, 0.12, detail=8, rough=0.7), 0.45, dtype='FLOAT'), 0.5 + 0.2 * (1 - chip), 0.52 + 0.2 * (1 - chip))
    col = _mix(nt, col, (*iron_col, 1), ch)
    l.new(col, b.inputs['Base Color'])
    l.new(_mix(nt, _maprange(nt, _noise(nt, P, 0.2, detail=3), 0.3, 0.7, rough, rough * 2.2), 0.6, ch, dtype='FLOAT'), b.inputs['Roughness'])
    b.inputs['Coat Weight'].default_value = 0.6; b.inputs['Coat Roughness'].default_value = 0.03
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.6
    l.new(_bump(nt, _mix(nt, _noise(nt, P, 0.08, detail=3), 0.0, ch, dtype='FLOAT'), 0.15, 0.08, bv.outputs['Normal']), b.inputs['Normal'])
    return m

def paper(name, color=(0.80, 0.78, 0.72), fibre=1.0, seed=0.0, grime=0.2, lines=None):
    """Uncoated paper: fibre mottling, faint translucency, optional ruled lines (lines=(pitch_mm, axis, colour))."""
    m, nt, l, b, P = _new(name); P = _offset(nt, P, seed)
    fm = _noise(nt, P, 0.35, detail=8, rough=0.7)
    col = _mix(nt, (*color, 1), (*[c * 0.94 for c in color], 1), _maprange(nt, fm, 0.3, 0.7, 0, fibre))
    col = _mix(nt, col, (0.55, 0.48, 0.36, 1), _maprange(nt, _noise(nt, P, 0.02, detail=6), 0.6, 0.85, 0, grime))
    if lines:
        pitch, ax, lc = lines
        X, Y, Z = _sep(nt, P); u = {'X': X, 'Y': Y, 'Z': Z}[ax]
        f = _math(nt, 'FRACT', _math(nt, 'DIVIDE', u, pitch))
        ln = _maprange(nt, _math(nt, 'ABSOLUTE', _math(nt, 'SUBTRACT', f, 0.5)), 0.47, 0.5)
        col = _mix(nt, col, (*lc, 1), _math(nt, 'MULTIPLY', ln, 0.7))
    l.new(col, b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.75; b.inputs['Sheen Weight'].default_value = 0.3
    b.inputs['Subsurface Weight'].default_value = 0.08; b.inputs['Subsurface Radius'].default_value = (1.5, 1.2, 1.0)
    l.new(_bump(nt, _noise(nt, P, 1.5, detail=6, rough=0.7), 0.08, 0.05), b.inputs['Normal'])
    return m

def plastic(name, color, rough=0.35, seed=0.0, grime=0.5, sheen_scuffs=0.3):
    """Bakelite / moulded plastic with handling wear."""
    m, nt, l, b, P = _new(name); P = _offset(nt, P, seed)
    col = _mix(nt, (*color, 1), (*[c * 0.8 for c in color], 1), _noise(nt, P, 0.1, detail=5))
    cm = _maprange(nt, _cavity_mask(nt, 3.0, 0.3, 0.95), 0, 1, 0, grime)
    col = _mix(nt, col, (0.04, 0.035, 0.03, 1), cm)
    l.new(col, b.inputs['Base Color'])
    r = _maprange(nt, _noise(nt, P, 0.3, detail=6), 0.3, 0.7, rough * 0.7, rough * 1.4)
    em = _edge_mask(nt, 1.0, 0.6, 0.97)
    r = _mix(nt, r, rough * 0.5, _math(nt, 'MULTIPLY', em, sheen_scuffs), dtype='FLOAT')
    l.new(r, b.inputs['Roughness'])
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.5
    l.new(_bump(nt, _noise(nt, P, 0.8, detail=4), 0.05, 0.05, bv.outputs['Normal']), b.inputs['Normal'])
    return m

def rubber(name, color=(0.025, 0.024, 0.022), rough=0.75):
    m, nt, l, b, P = _new(name)
    l.new(_mix(nt, (*color, 1), (*[c * 1.6 for c in color], 1), _noise(nt, P, 0.05, detail=6)), b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = rough; b.inputs['Sheen Weight'].default_value = 0.2
    l.new(_bump(nt, _noise(nt, P, 2.0, detail=4), 0.1, 0.05), b.inputs['Normal'])
    return m

def glass(name, tint=(0.95, 0.97, 0.96), rough=0.0, ior=1.5, dirt=0.3):
    m, nt, l, b, P = _new(name)
    b.inputs['Base Color'].default_value = (*tint, 1); b.inputs['Transmission Weight'].default_value = 1.0
    b.inputs['IOR'].default_value = ior
    r = _maprange(nt, _noise(nt, P, 0.01, detail=6, rough=0.7), 0.5, 0.8, rough, rough + 0.25 * dirt)
    l.new(r, b.inputs['Roughness'])
    return m

def emissive(name, color, strength, base=(0.02, 0.02, 0.02)):
    m, nt, l, b, P = _new(name)
    b.inputs['Base Color'].default_value = (*base, 1); b.inputs['Emission Color'].default_value = (*color, 1)
    b.inputs['Emission Strength'].default_value = strength; return m

def opal_glass(name, glow=0.0, color=(1.0, 0.72, 0.42)):
    """Milky opal globe: diffuse-transmissive; `glow` adds the light of the bulb behind it (fake SSS, cheap)."""
    m, nt, l, b, P = _new(name)
    b.inputs['Base Color'].default_value = (0.88, 0.87, 0.84, 1); b.inputs['Roughness'].default_value = 0.12
    b.inputs['Coat Weight'].default_value = 1.0; b.inputs['Coat Roughness'].default_value = 0.05
    b.inputs['Subsurface Weight'].default_value = 0.6; b.inputs['Subsurface Radius'].default_value = (8, 7, 6)
    if glow:
        # brighter where the glass faces the camera through the bulb (layer weight facing)
        lw = nt.nodes.new('ShaderNodeLayerWeight'); lw.inputs['Blend'].default_value = 0.45
        g = _maprange(nt, lw.outputs['Facing'], 0.0, 1.0, 1.0, 0.35)
        l.new(_mix(nt, (*color, 1), (*color, 1), 0.0), b.inputs['Emission Color'])
        l.new(_math(nt, 'MULTIPLY', g, glow), b.inputs['Emission Strength'])
    return m

def hair_mat(name, light=(0.55, 0.36, 0.17), dark=(0.20, 0.11, 0.05), border=None):
    """Coir / bristle fibre (Principled Hair, direct colouring). border = (x0, x1, y0, y1, width, colour)."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links
    out = nt.nodes['Material Output']; nt.nodes.remove(nt.nodes['Principled BSDF'])
    h = nt.nodes.new('ShaderNodeBsdfHairPrincipled'); h.parametrization = 'COLOR'
    hi = nt.nodes.new('ShaderNodeHairInfo')
    col = _mix(nt, (*light, 1), (*dark, 1), hi.outputs['Random'])
    tc = nt.nodes.new('ShaderNodeTexCoord').outputs['Object']
    col = _mix(nt, col, (*[c * 0.55 for c in dark], 1), _maprange(nt, _noise(nt, tc, 0.01, detail=4), 0.4, 0.7, 0, 0.6))
    if border:
        x0, x1, y0, y1, w, bc = border; X, Y, Z = _sep(nt, tc)
        dx = _math(nt, 'MINIMUM', _math(nt, 'SUBTRACT', X, x0), _math(nt, 'SUBTRACT', x1, X))
        dy = _math(nt, 'MINIMUM', _math(nt, 'SUBTRACT', Y, y0), _math(nt, 'SUBTRACT', y1, Y))
        bm_ = _maprange(nt, _math(nt, 'MINIMUM', dx, dy), w, w - 4)
        col = _mix(nt, col, _mix(nt, (*bc, 1), (*[c * 1.6 for c in bc], 1), hi.outputs['Random']), bm_)
    l.new(col, h.inputs['Color'])
    h.inputs['Roughness'].default_value = 0.45; h.inputs['Radial Roughness'].default_value = 0.6
    h.inputs['Coat'].default_value = 0.1
    l.new(h.outputs[0], out.inputs['Surface']); return m

# ---------------------------------------------------------------- camera / anchors
def photo_camera(loc, look_at=None, yaw=0.0, lens=24.0, shift=(0.0, 0.0), sensor=36.0, pitch=0.0):
    """Level architectural camera: horizontal axis, verticals stay vertical, framing by lens shift."""
    cd = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cd); scene.collection.objects.link(cam); scene.camera = cam
    cd.lens = lens; cd.sensor_fit = 'AUTO'; cd.sensor_width = sensor; cd.shift_x, cd.shift_y = shift
    cd.clip_start = 10; cd.clip_end = 30000; cd.dof.use_dof = False
    cam.location = loc; cam.rotation_euler = (math.radians(90 + pitch), 0, math.radians(yaw)); return cam

def project(points):
    """World points -> normalised image coords (0..1, origin top-left)."""
    from bpy_extras.object_utils import world_to_camera_view
    bpy.context.view_layer.update(); out = []
    for p in points:
        c = world_to_camera_view(scene, scene.camera, Vector(p)); out.append([round(c.x, 5), round(1 - c.y, 5)])
    return out

def write_anchors(path, anchors):
    """anchors: {name: [tl, tr, br, bl] world points}. Written next to the render for mockup homographies."""
    data = {'width': scene.render.resolution_x, 'height': scene.render.resolution_y,
            'anchors': {k: project(v) for k, v in anchors.items()}}
    with open(path, 'w') as f: json.dump(data, f, indent=1)
    print('ANCHORS', path)
