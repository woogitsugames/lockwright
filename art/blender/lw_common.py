# Shared materials and mesh helpers for Lockwright look-dev scenes (1 unit = 1 mm).
import bpy, bmesh, math, os, random
from mathutils import Vector, Matrix
random.seed(7)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ---------------------------------------------------------------- materials
def node_mat(name, base, metallic, rough, rough_var=0.06, aniso=0.0, scratch=0.0, scale=60.0, coat=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True
    nt = m.node_tree; n = nt.nodes; l = nt.links
    bsdf = n['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = (*base, 1)
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Anisotropic'].default_value = aniso
    bsdf.inputs['Coat Weight'].default_value = coat
    tc = n.new('ShaderNodeTexCoord')
    # roughness variation (fingerprints, wear) + directional machining scratches
    noise = n.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = scale; noise.inputs['Detail'].default_value = 8
    l.new(tc.outputs['Object'], noise.inputs['Vector'])
    ramp = n.new('ShaderNodeMapRange'); ramp.inputs['To Min'].default_value = rough - rough_var; ramp.inputs['To Max'].default_value = rough + rough_var
    l.new(noise.outputs['Fac'], ramp.inputs['Value'])
    rough_out = ramp.outputs['Result']
    if scratch > 0:
        # face-milling arcs: large-radius rings ~1.4 mm apart, plus fine stretched noise (lathe/grind)
        mp = n.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (-60, 0, 25)
        l.new(tc.outputs['Object'], mp.inputs['Vector'])
        wv = n.new('ShaderNodeTexWave'); wv.wave_type = 'RINGS'; wv.inputs['Scale'].default_value = 6.0
        wv.inputs['Distortion'].default_value = 1.2; wv.inputs['Detail'].default_value = 6; wv.inputs['Detail Scale'].default_value = 2
        l.new(mp.outputs['Vector'], wv.inputs['Vector'])
        mp2 = n.new('ShaderNodeMapping'); mp2.inputs['Scale'].default_value = (0.05, 1, 3.0)
        l.new(tc.outputs['Object'], mp2.inputs['Vector'])
        fn = n.new('ShaderNodeTexNoise'); fn.inputs['Scale'].default_value = 4; fn.inputs['Detail'].default_value = 10
        l.new(mp2.outputs['Vector'], fn.inputs['Vector'])
        mx = n.new('ShaderNodeMix'); mx.data_type = 'FLOAT'; mx.inputs['Factor'].default_value = 0.5
        l.new(wv.outputs['Fac'], mx.inputs['A']); l.new(fn.outputs['Fac'], mx.inputs['B'])
        mix = n.new('ShaderNodeMix'); mix.data_type = 'FLOAT'; mix.inputs['Factor'].default_value = scratch * 0.16
        l.new(rough_out, mix.inputs['A']); l.new(mx.outputs['Result'], mix.inputs['B'])
        rough_out = mix.outputs['Result']
        bump = n.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.012 * scratch; bump.inputs['Distance'].default_value = 0.02
        l.new(mx.outputs['Result'], bump.inputs['Height']); l.new(bump.outputs['Normal'], bsdf.inputs['Normal'])
    # grime in crevices: ambient occlusion darkens base colour
    ao = n.new('ShaderNodeAmbientOcclusion'); ao.inputs['Distance'].default_value = 0.8
    ao.inputs['Color'].default_value = (*base, 1)
    dark = n.new('ShaderNodeMix'); dark.data_type = 'RGBA'; dark.blend_type = 'MULTIPLY'; dark.inputs['Factor'].default_value = 0.55
    l.new(ao.outputs['Color'], dark.inputs['A']); l.new(ao.outputs['AO'], dark.inputs['B'])
    if scratch > 0:
        tone = n.new('ShaderNodeMapRange'); tone.inputs['To Min'].default_value = 0.95; tone.inputs['To Max'].default_value = 1.0
        l.new(mx.outputs['Result'], tone.inputs['Value'])
        tint = n.new('ShaderNodeMix'); tint.data_type = 'RGBA'; tint.blend_type = 'MULTIPLY'; tint.inputs['Factor'].default_value = 1.0
        l.new(dark.outputs['Result'], tint.inputs['A']); l.new(tone.outputs['Result'], tint.inputs['B'])
        l.new(tint.outputs['Result'], bsdf.inputs['Base Color'])
    else:
        l.new(dark.outputs['Result'], bsdf.inputs['Base Color'])
    l.new(rough_out, bsdf.inputs['Roughness'])
    return m

M = {
    'brass':   node_mat('brass',   (0.88, 0.62, 0.27), 1.0, 0.24, 0.06, aniso=0.6, scratch=0.4, scale=40),
    'brass_k': node_mat('brass_k', (0.90, 0.68, 0.36), 1.0, 0.18, 0.04, scale=90),           # key pins: turned, brighter
    'nickel':  node_mat('nickel',  (0.60, 0.60, 0.58), 1.0, 0.30, 0.08, aniso=0.7, scratch=0.85, scale=35),
    'steel':   node_mat('steel',   (0.52, 0.53, 0.55), 1.0, 0.22, 0.05, scale=90),           # hardened driver pins: darker, glossier
    'spring':  node_mat('spring',  (0.62, 0.62, 0.62), 1.0, 0.25, 0.03),
    'pick':    node_mat('pick',    (0.78, 0.78, 0.77), 1.0, 0.16, 0.04, aniso=0.6, scratch=0.15),
    'iron':    node_mat('iron',    (0.20, 0.19, 0.18), 0.8, 0.62, 0.12, scale=25),
    'handle':  node_mat('handle',  (0.24, 0.06, 0.04), 0.0, 0.45, 0.05),
    'recess':  node_mat('recess',  (0.05, 0.045, 0.04), 0.0, 0.8, 0.05),
}

def wood_mat():
    m = bpy.data.materials.new('wood'); m.use_nodes = True; n = m.node_tree.nodes; l = m.node_tree.links
    b = n['Principled BSDF']; b.inputs['Roughness'].default_value = 0.55; b.inputs['Coat Weight'].default_value = 0.25; b.inputs['Coat Roughness'].default_value = 0.35
    tc = n.new('ShaderNodeTexCoord'); mp = n.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = (1.0, 1, 0.04)
    l.new(tc.outputs['Object'], mp.inputs['Vector'])
    w = n.new('ShaderNodeTexWave'); w.wave_type = 'BANDS'; w.bands_direction = 'X'; w.inputs['Scale'].default_value = 0.22
    w.inputs['Distortion'].default_value = 14; w.inputs['Detail'].default_value = 6; w.inputs['Detail Scale'].default_value = 1.5
    l.new(mp.outputs['Vector'], w.inputs['Vector'])
    cr = n.new('ShaderNodeValToRGB'); cr.color_ramp.elements[0].color = (0.16, 0.075, 0.03, 1); cr.color_ramp.elements[1].color = (0.36, 0.19, 0.09, 1)
    l.new(w.outputs['Fac'], cr.inputs['Fac']); l.new(cr.outputs['Color'], b.inputs['Base Color'])
    bump = n.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.15; l.new(w.outputs['Fac'], bump.inputs['Height']); l.new(bump.outputs['Normal'], b.inputs['Normal'])
    return m
M['wood'] = wood_mat()

# ---------------------------------------------------------------- helpers
def link(o, mat):
    o.data.materials.clear(); o.data.materials.append(mat); bpy.context.collection.objects.link(o) if o.name not in bpy.context.collection.objects else None; return o

def cyl(name, r, h, loc, axis='Z', verts=64):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=loc)
    o = bpy.context.object; o.name = name
    if axis == 'X': o.rotation_euler = (0, math.pi / 2, 0)
    if axis == 'Y': o.rotation_euler = (math.pi / 2, 0, 0)
    bpy.ops.object.transform_apply(rotation=True); return o

def box(name, x0, x1, y0, y1, z0, z1):
    bpy.ops.mesh.primitive_cube_add(size=1, location=((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
    o = bpy.context.object; o.name = name; o.scale = (x1 - x0, y1 - y0, z1 - z0); bpy.ops.object.transform_apply(scale=True); return o

def boolean(target, cutter, op='DIFFERENCE'):
    md = target.modifiers.new('b', 'BOOLEAN'); md.operation = op; md.object = cutter; md.solver = 'EXACT'
    bpy.context.view_layer.objects.active = target; bpy.ops.object.modifier_apply(modifier=md.name)
    bpy.data.objects.remove(cutter, do_unlink=True)

def bevel(o, w=0.12, seg=3):
    md = o.modifiers.new('bev', 'BEVEL'); md.width = w; md.segments = seg; md.limit_method = 'ANGLE'; md.angle_limit = math.radians(40)
    o.modifiers.new('wn', 'WEIGHTED_NORMAL')

def smooth(o):
    for p in o.data.polygons: p.use_smooth = True

def lathe(name, profile, x, y=1.5, tilt=0.0, seg=48):
    """profile: list of (radius, z) from bottom to top; solid of revolution around vertical axis at (x, y)."""
    bm = bmesh.new(); rings = []
    for r, z in profile:
        ring = [bm.verts.new((x + r * math.cos(2 * math.pi * i / seg), y + r * math.sin(2 * math.pi * i / seg), z)) for i in range(seg)]
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for i in range(seg):
            bm.faces.new((a[i], a[(i + 1) % seg], b[(i + 1) % seg], b[i]))
    bm.faces.new(list(reversed(rings[0]))); bm.faces.new(rings[-1])
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); smooth(o)
    if tilt:
        piv = Vector((x, y, profile[0][1])); o.matrix_world = Matrix.Translation(piv) @ Matrix.Rotation(tilt, 4, 'Y') @ Matrix.Translation(-piv)
    md = o.modifiers.new('bev', 'BEVEL'); md.width = 0.06; md.segments = 2; md.limit_method = 'ANGLE'
    return o

def pin(name, x, z0, length, r=1.42, chamfer=0.18, tip=False, mat='steel', tilt=0.0):
    if tip:  # key pin: rounded/pointed bottom that rides on the key
        prof = [(0.02, z0), (0.5, z0 + 0.12), (0.95, z0 + 0.45), (r - 0.05, z0 + 0.95), (r, z0 + 1.1), (r, z0 + length - chamfer), (r - chamfer, z0 + length)]
    else:
        prof = [(r - chamfer, z0), (r, z0 + chamfer), (r, z0 + length - chamfer), (r - chamfer, z0 + length)]
    return link(lathe(name, prof, x, tilt=tilt), M[mat])

def spool(name, x, z0, length, waist_z, r=1.42, wr=0.95):
    h = 0.45
    prof = [(r - 0.15, z0), (r, z0 + 0.15), (r, waist_z - h - 0.25), (wr, waist_z - h + 0.05), (wr, waist_z + h - 0.05), (r, waist_z + h + 0.25), (r, z0 + length - 0.15), (r - 0.15, z0 + length)]
    return link(lathe(name, prof, x), M['steel'])

def spring(name, x, z0, z1, coils, r=1.15, wire=0.22, y=1.5):
    cu = bpy.data.curves.new(name, 'CURVE'); cu.dimensions = '3D'; cu.bevel_depth = wire; cu.bevel_resolution = 4
    sp = cu.splines.new('POLY'); n = int(coils * 24); sp.points.add(n)
    for i in range(n + 1):
        t = i / n; a = t * coils * 2 * math.pi
        # closed ends: the first and last coil have (almost) zero pitch, like a real compression spring
        e = 1.0 / coils; L = z1 - z0; w = wire * 2.05
        if t < e: zt = (t / e) * w
        elif t > 1 - e: zt = L - ((1 - t) / e) * w
        else: zt = w + (t - e) / (1 - 2 * e) * (L - 2 * w)
        sp.points[i].co = (x + r * math.cos(a), y + r * math.sin(a), z0 + zt, 1)
    o = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(o); o.data.materials.append(M['spring']); return o


def _catmull(pts, n=12):
    """Smooth a polyline (list of Vector) with centripetal-ish Catmull-Rom, n samples per segment."""
    P = [pts[0]] + pts + [pts[-1]]; out = []
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(n):
            t = k / n; t2 = t * t; t3 = t2 * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(pts[-1]); return out

def flat_tool(name, path, height, thick, y, mat='pick', tip='round'):
    """Stamped flat-stock tool (pick blade, tension wrench): smooth centreline in XZ, constant height,
    rounded polished tip, extruded `thick` along Y, edges eased with a small harden-normals bevel."""
    c = _catmull([Vector((x, 0, z)) for x, z in path])
    left, right = [], []
    for i, p in enumerate(c):
        d = (c[min(i + 1, len(c) - 1)] - c[max(i - 1, 0)]).normalized(); nrm = Vector((-d.z, 0, d.x))
        left.append(p + nrm * height / 2); right.append(p - nrm * height / 2)
    outline = left[:]
    if tip == 'round':  # semicircular cap at the working end
        d = (c[-1] - c[-2]).normalized(); nrm = Vector((-d.z, 0, d.x))
        for k in range(1, 12):
            a = math.pi * k / 12
            outline.append(c[-1] + nrm * math.cos(a) * height / 2 + d * math.sin(a) * height / 2)
    outline += right[::-1]
    bm = bmesh.new()
    vs = [bm.verts.new((v.x, y - thick / 2, v.z)) for v in outline]
    f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [g for g in ext['geom'] if isinstance(g, bmesh.types.BMVert)]: v.co.y += thick
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    b = o.modifiers.new('bev', 'BEVEL'); b.width = min(thick, height) * 0.22; b.segments = 3; b.limit_method = 'ANGLE'; b.angle_limit = math.radians(50); b.harden_normals = True
    for poly in me.polygons: poly.use_smooth = True
    me.materials.append(M[mat]); return o


# ================================================================ v2 additions (append-only)
# Used by the family scenes (wafer, lever, warded, wooden_pin, ring_combo). Nothing above this line changes,
# so cutaway.py / tray.py render exactly as before.
def _nn(nt, t, x=0, **inputs):
    nd = nt.nodes.new(t)
    for k, v in inputs.items():
        if k in nd.inputs: nd.inputs[k].default_value = v
        else: setattr(nd, k, v)
    return nd

def _mix(nt, a, b, fac, mode='MIX', dtype='RGBA'):
    m = nt.nodes.new('ShaderNodeMix'); m.data_type = dtype
    if dtype == 'RGBA': m.blend_type = mode
    l = nt.links
    def put(sock, val):
        if hasattr(val, 'is_linked') or hasattr(val, 'links'): l.new(val, sock)
        else: sock.default_value = val
    idx = {'FLOAT': (0, 2, 3), 'RGBA': (0, 6, 7)}[dtype]
    put(m.inputs[idx[0]], fac); put(m.inputs[idx[1]], a); put(m.inputs[idx[2]], b)
    return m.outputs[{'FLOAT': 0, 'RGBA': 2}[dtype]]

def _maprange(nt, sock, a, b, c=0.0, d=1.0, clamp=True):
    m = nt.nodes.new('ShaderNodeMapRange'); m.clamp = clamp
    m.inputs['From Min'].default_value = a; m.inputs['From Max'].default_value = b
    m.inputs['To Min'].default_value = c; m.inputs['To Max'].default_value = d
    nt.links.new(sock, m.inputs['Value']); return m.outputs['Result']

def _edge_mask(nt, dist=0.25, lo=0.70, hi=0.98):
    """Convex-edge mask (1 on worn edges) from Cycles AO in 'inside' mode."""
    ao = nt.nodes.new('ShaderNodeAmbientOcclusion'); ao.inside = True; ao.only_local = True; ao.samples = 8
    ao.inputs['Distance'].default_value = dist
    return _maprange(nt, ao.outputs['AO'], hi, lo)   # AO inside ~1 on flats, drops on sharp convex edges

def _cavity_mask(nt, dist=1.0, lo=0.35, hi=0.95):
    """Concave mask (1 in crevices) for dust and grime."""
    ao = nt.nodes.new('ShaderNodeAmbientOcclusion'); ao.only_local = False; ao.samples = 8
    ao.inputs['Distance'].default_value = dist
    return _maprange(nt, ao.outputs['AO'], hi, lo)

def _noise(nt, vec, scale, detail=6, rough=0.55, dist=0.0, stretch=None):
    if stretch is not None:
        mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Scale'].default_value = stretch
        nt.links.new(vec, mp.inputs['Vector']); vec = mp.outputs['Vector']
    n = nt.nodes.new('ShaderNodeTexNoise'); n.inputs['Scale'].default_value = scale; n.inputs['Detail'].default_value = detail
    n.inputs['Roughness'].default_value = rough; n.inputs['Distortion'].default_value = dist
    nt.links.new(vec, n.inputs['Vector']); return n.outputs['Fac']

def metal(name, base, rough, aniso=0.0, marks='grind', marks_scale=1.0, marks_axis=(1, 0, 0), marks_amt=1.0,
          wear=0.5, wear_col=None, grime=0.5, grime_col=(0.05, 0.04, 0.03), smudge=0.5, bevel_r=0.04, metallic=1.0,
          tint_var=0.04, seed=0.0, patina=0.0):
    """Physically plausible machined metal. marks: 'grind' (linear, along marks_axis), 'mill' (face-mill arcs),
    'turn' (circumferential lathe lines around marks_axis), 'stamp' (fine isotropic + rolling streaks), None."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links
    b = nt.nodes['Principled BSDF']; b.inputs['Metallic'].default_value = metallic; b.inputs['Anisotropic'].default_value = aniso
    tc = nt.nodes.new('ShaderNodeTexCoord'); P = tc.outputs['Object']
    if seed:
        mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (seed * 17.3, seed * 5.1, seed * 9.7); l.new(P, mp.inputs['Vector']); P = mp.outputs['Vector']
    ax = Vector(marks_axis).normalized()
    # --- machining marks height field
    mk = None
    if marks == 'grind':
        s = [0.03 if abs(a) > 0.5 else 3.0 for a in ax]
        mk = _noise(nt, P, 9.0 * marks_scale, detail=12, rough=0.7, stretch=s)
    elif marks == 'turn':
        s = [3.0 if abs(a) > 0.5 else 0.0 for a in ax]
        w = nt.nodes.new('ShaderNodeTexWave'); w.wave_type = 'BANDS'; w.bands_direction = 'X'
        mp = nt.nodes.new('ShaderNodeMapping'); l.new(P, mp.inputs['Vector'])
        # rotate so that marks_axis maps to X
        if abs(ax.z) > 0.5: mp.inputs['Rotation'].default_value = (0, math.pi / 2, 0)
        elif abs(ax.y) > 0.5: mp.inputs['Rotation'].default_value = (0, 0, math.pi / 2)
        w.inputs['Scale'].default_value = 7.0 * marks_scale; w.inputs['Distortion'].default_value = 0.6
        w.inputs['Detail'].default_value = 4; l.new(mp.outputs['Vector'], w.inputs['Vector'])
        fn = _noise(nt, P, 30 * marks_scale, detail=8)
        mk = _mix(nt, w.outputs['Fac'], fn, 0.35, dtype='FLOAT')
    elif marks == 'mill':
        mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (-55, 0, 30)
        mp.inputs['Scale'].default_value = (1, 0.0, 1) if abs(ax.y) > 0.5 else (1, 1, 1)
        l.new(P, mp.inputs['Vector'])
        w = nt.nodes.new('ShaderNodeTexWave'); w.wave_type = 'RINGS'; w.inputs['Scale'].default_value = 5.0 * marks_scale
        w.inputs['Distortion'].default_value = 1.0; w.inputs['Detail'].default_value = 5; l.new(mp.outputs['Vector'], w.inputs['Vector'])
        fn = _noise(nt, P, 5 * marks_scale, detail=10, rough=0.7, stretch=(0.06, 1, 3))
        mk = _mix(nt, w.outputs['Fac'], fn, 0.5, dtype='FLOAT')
    elif marks == 'stamp':
        a = _noise(nt, P, 3.0 * marks_scale, detail=10, rough=0.65, stretch=(0.05, 2.0, 2.0))
        bfine = _noise(nt, P, 80 * marks_scale, detail=4)
        mk = _mix(nt, a, bfine, 0.5, dtype='FLOAT')
    # --- roughness: base +- fine variation, smudges, marks
    rv = _noise(nt, P, 25, detail=6)
    r = _maprange(nt, rv, 0.3, 0.7, rough * 0.85, rough * 1.15)
    sm = _maprange(nt, _noise(nt, P, 0.35, detail=4, rough=0.6), 0.45, 0.75, 0.0, 1.0)
    r = _mix(nt, r, min(1.0, rough + 0.14), sm, dtype='FLOAT') if smudge else r
    if mk is not None:
        r = _mix(nt, r, _maprange(nt, mk, 0.3, 0.7, rough * 0.8, rough * 1.25), 0.45 * marks_amt, dtype='FLOAT')
    # --- base colour: subtle tint variation, grime in crevices, brighter worn edges
    tv = _noise(nt, P, 1.2, detail=3)
    col = _mix(nt, (*[c * (1 - tint_var) for c in base], 1), (*[min(1, c * (1 + tint_var)) for c in base], 1), tv)
    if patina:  # tarnish: darker, browner, rougher blotches (fingerprints, oxidation), never on worn edges
        pm = _maprange(nt, _noise(nt, P, 0.6, detail=8, rough=0.65), 0.42, 0.62, 0.0, patina)
        col = _mix(nt, col, (base[0] * 0.42, base[1] * 0.36, base[2] * 0.30, 1), pm)
        r = _mix(nt, r, min(1.0, rough + 0.2), pm, dtype='FLOAT')
    em = _edge_mask(nt) if wear else None
    if wear:
        wc = wear_col or tuple(min(1, c * 1.08) for c in base)
        wm = _mix(nt, 0.0, em, _maprange(nt, _noise(nt, P, 3.0, detail=5), 0.35, 0.6), dtype='FLOAT')
        wm = _maprange(nt, wm, 0.0, 1.0, 0.0, wear)
        col = _mix(nt, col, (*wc, 1), wm)
        r = _mix(nt, r, max(0.16, rough * 0.7), wm, dtype='FLOAT')
    if grime:
        cm = _cavity_mask(nt, 2.0, 0.3, 0.97)
        gm = _maprange(nt, _mix(nt, cm, _noise(nt, P, 2.0, detail=6), 0.3, dtype='FLOAT'), 0.0, 1.0, 0.0, grime)
        col = _mix(nt, col, (*grime_col, 1), gm)
        r = _mix(nt, r, 0.75, gm, dtype='FLOAT')
        b.inputs['Metallic'].default_value = metallic
    l.new(col, b.inputs['Base Color']); l.new(r, b.inputs['Roughness'])
    # --- normal: bevel-rounded edges + machining relief
    nrm = None
    if bevel_r:
        bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = bevel_r; nrm = bv.outputs['Normal']
    if mk is not None:
        bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.045 * marks_amt; bp.inputs['Distance'].default_value = 0.01
        l.new(mk, bp.inputs['Height'])
        if nrm is not None: l.new(nrm, bp.inputs['Normal'])
        nrm = bp.outputs['Normal']
    if nrm is not None: l.new(nrm, b.inputs['Normal'])
    if aniso and marks in ('grind', 'turn'):
        tg = nt.nodes.new('ShaderNodeTangent'); tg.direction_type = 'RADIAL'
        tg.axis = 'X' if abs(ax.x) > 0.5 else ('Y' if abs(ax.y) > 0.5 else 'Z'); l.new(tg.outputs['Tangent'], b.inputs['Tangent'])
    return m

def paint(name, color, rough=0.42, metal_col=(0.55, 0.55, 0.56), chip=0.6, grime=0.5, peel=0.015):
    """Powder coat / enamel over steel: orange-peel bump, chipped edges exposing metal, dust in corners."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links
    out = nt.nodes['Material Output']; pb = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord'); P = tc.outputs['Object']
    tv = _noise(nt, P, 0.6, detail=3)
    col = _mix(nt, (*[c * 0.9 for c in color], 1), (*[min(1, c * 1.06) for c in color], 1), tv)
    cm = _maprange(nt, _cavity_mask(nt, 1.5), 0, 1, 0, grime)
    col = _mix(nt, col, (0.09, 0.08, 0.065, 1), cm)
    l.new(col, pb.inputs['Base Color'])
    r = _maprange(nt, _noise(nt, P, 2.0, detail=6), 0.3, 0.7, rough - 0.06, rough + 0.08)
    r = _mix(nt, r, 0.8, cm, dtype='FLOAT'); l.new(r, pb.inputs['Roughness'])
    pb.inputs['Coat Weight'].default_value = 0.0
    op = _noise(nt, P, 9.0, detail=2, rough=0.4)
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.08; bp.inputs['Distance'].default_value = peel
    l.new(op, bp.inputs['Height'])
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.08; l.new(bv.outputs['Normal'], bp.inputs['Normal'])
    l.new(bp.outputs['Normal'], pb.inputs['Normal'])
    # chipped edges: bare steel
    mb = nt.nodes.new('ShaderNodeBsdfPrincipled'); mb.inputs['Base Color'].default_value = (*metal_col, 1)
    mb.inputs['Metallic'].default_value = 1.0; mb.inputs['Roughness'].default_value = 0.32
    l.new(bv.outputs['Normal'], mb.inputs['Normal'])
    em = _edge_mask(nt, 0.3, 0.6, 0.97)
    ch = _maprange(nt, _noise(nt, P, 2.5, detail=8, rough=0.7), 0.42, 0.52)
    msk = _mix(nt, 0.0, em, ch, dtype='FLOAT'); msk = _maprange(nt, msk, 0.35, 0.6, 0.0, chip)
    sh = nt.nodes.new('ShaderNodeMixShader'); l.new(msk, sh.inputs[0]); l.new(pb.outputs[0], sh.inputs[1]); l.new(mb.outputs[0], sh.inputs[2])
    l.new(sh.outputs[0], out.inputs['Surface'])
    return m

def iron(name, rust=0.6, base=(0.16, 0.155, 0.15), rough=0.55, polish=0.5, scale=1.0, seed=0.0):
    """Wrought / cast iron with patina and rust: rust gathers in crevices and pits, handled edges are rubbed
    back to dark metal. Rust is a dielectric layer (no metallic shine)."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links
    out = nt.nodes['Material Output']; fe = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord'); P = tc.outputs['Object']
    if seed:
        mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (seed * 13.1, seed * 7.7, seed * 3.3); l.new(P, mp.inputs['Vector']); P = mp.outputs['Vector']
    big = _noise(nt, P, 0.18 * scale, detail=8, rough=0.62)
    mid = _noise(nt, P, 1.4 * scale, detail=10, rough=0.7)
    fine = _noise(nt, P, 14 * scale, detail=6, rough=0.7)
    # iron layer: dark, mottled, partly metallic (mill scale + rubbed)
    ic = _mix(nt, (base[0] * 0.6, base[1] * 0.6, base[2] * 0.62, 1), (*[c * 1.5 for c in base], 1), mid)
    fe.inputs['Metallic'].default_value = 0.75; l.new(ic, fe.inputs['Base Color'])
    l.new(_maprange(nt, fine, 0.3, 0.7, rough - 0.15, rough + 0.15), fe.inputs['Roughness'])
    # rust layer
    ru = nt.nodes.new('ShaderNodeBsdfPrincipled'); ru.inputs['Metallic'].default_value = 0.0
    cr = nt.nodes.new('ShaderNodeValToRGB'); e = cr.color_ramp.elements
    e[0].position = 0.25; e[0].color = (0.10, 0.045, 0.02, 1); e[1].position = 0.75; e[1].color = (0.42, 0.17, 0.06, 1)
    e2 = cr.color_ramp.elements.new(0.5); e2.color = (0.24, 0.09, 0.035, 1)
    l.new(_mix(nt, mid, fine, 0.4, dtype='FLOAT'), cr.inputs['Fac']); l.new(cr.outputs['Color'], ru.inputs['Base Color'])
    l.new(_maprange(nt, fine, 0.3, 0.7, 0.72, 0.95), ru.inputs['Roughness'])
    # mask: noise patches + crevices - rubbed edges
    msk = _maprange(nt, _mix(nt, big, mid, 0.45, dtype='FLOAT'), 0.62 - rust * 0.25, 0.70 - rust * 0.25)
    cav = _cavity_mask(nt, 2.0, 0.3, 0.9)
    msk = _mix(nt, msk, 1.0, _maprange(nt, cav, 0, 1, 0, rust), dtype='FLOAT')
    em = _edge_mask(nt, 0.5, 0.6, 0.97)
    msk = _mix(nt, msk, 0.0, _maprange(nt, em, 0, 1, 0, polish), dtype='FLOAT')
    # height: rust is raised & pitted, iron has hammer/cast texture
    h = _mix(nt, _mix(nt, mid, fine, 0.5, dtype='FLOAT'), _maprange(nt, fine, 0.4, 0.8, 0.6, 1.0), msk, dtype='FLOAT')
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.35; bp.inputs['Distance'].default_value = 0.06
    l.new(h, bp.inputs['Height'])
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.15; l.new(bv.outputs['Normal'], bp.inputs['Normal'])
    l.new(bp.outputs['Normal'], fe.inputs['Normal']); l.new(bp.outputs['Normal'], ru.inputs['Normal'])
    sh = nt.nodes.new('ShaderNodeMixShader'); l.new(msk, sh.inputs[0]); l.new(fe.outputs[0], sh.inputs[1]); l.new(ru.outputs[0], sh.inputs[2])
    l.new(sh.outputs[0], out.inputs['Surface'])
    return m

def wood(name, light=(0.42, 0.26, 0.13), dark=(0.20, 0.10, 0.045), axis='X', ring=0.9, rough=0.6, coat=0.0,
         wear=0.5, grime=0.6, pores=1.0, seed=0.0, oiled=0.2, warp=3.0, center=(37, -61)):
    """Real wood: annual rings around the grain axis (log centre offset), distorted, with stretched pores,
    medullary flecks, worn lighter edges and dark handling grime in corners."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links
    b = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord'); P = tc.outputs['Object']
    # map so that the grain axis becomes Z (rings = distance from Z axis)
    mp = nt.nodes.new('ShaderNodeMapping'); l.new(P, mp.inputs['Vector'])
    rot = {'X': (0, math.pi / 2, 0), 'Y': (math.pi / 2, 0, 0), 'Z': (0, 0, 0)}[axis]
    mp.inputs['Rotation'].default_value = rot; mp.inputs['Location'].default_value = (center[0] + seed * 11, center[1] - seed * 7, seed * 23)
    Q = mp.outputs['Vector']
    # warp coordinates with low-frequency noise (figure)
    wn = nt.nodes.new('ShaderNodeTexNoise'); wn.inputs['Scale'].default_value = 0.05; wn.inputs['Detail'].default_value = 3
    st = nt.nodes.new('ShaderNodeMapping'); st.inputs['Scale'].default_value = (1, 1, 0.08); l.new(Q, st.inputs['Vector'])
    l.new(st.outputs['Vector'], wn.inputs['Vector'])
    wv = nt.nodes.new('ShaderNodeVectorMath'); wv.operation = 'SCALE'; wv.inputs['Scale'].default_value = 0.0
    cen = nt.nodes.new('ShaderNodeVectorMath'); cen.operation = 'SUBTRACT'; l.new(wn.outputs['Color'], cen.inputs[0]); cen.inputs[1].default_value = (0.5, 0.5, 0.5)
    sc = nt.nodes.new('ShaderNodeVectorMath'); sc.operation = 'SCALE'; sc.inputs['Scale'].default_value = warp; l.new(cen.outputs[0], sc.inputs[0])
    add = nt.nodes.new('ShaderNodeVectorMath'); add.operation = 'ADD'; l.new(Q, add.inputs[0]); l.new(sc.outputs[0], add.inputs[1])
    flat = nt.nodes.new('ShaderNodeMapping'); flat.inputs['Scale'].default_value = (1, 1, 0); l.new(add.outputs[0], flat.inputs['Vector'])
    ln = nt.nodes.new('ShaderNodeVectorMath'); ln.operation = 'LENGTH'; l.new(flat.outputs['Vector'], ln.inputs[0])
    # uneven ring widths: 1D noise of the radius itself shifts the ring phase
    rn = nt.nodes.new('ShaderNodeTexNoise'); rn.noise_dimensions = '1D'; rn.inputs['Scale'].default_value = 0.35 * ring; rn.inputs['Detail'].default_value = 4
    l.new(ln.outputs['Value'], rn.inputs['W'])
    rj = nt.nodes.new('ShaderNodeMath'); rj.operation = 'MULTIPLY_ADD'; l.new(rn.outputs['Fac'], rj.inputs[0]); rj.inputs[1].default_value = 4.0 / max(ring, 0.05)
    l.new(ln.outputs['Value'], rj.inputs[2])
    rr = nt.nodes.new('ShaderNodeMath'); rr.operation = 'MULTIPLY'; rr.inputs[1].default_value = ring; l.new(rj.outputs[0], rr.inputs[0])
    fr = nt.nodes.new('ShaderNodeMath'); fr.operation = 'FRACT'; l.new(rr.outputs[0], fr.inputs[0])
    # late wood: sharp dark band at the end of each ring, early wood soft
    pw = nt.nodes.new('ShaderNodeMath'); pw.operation = 'POWER'; pw.inputs[1].default_value = 3.0; l.new(fr.outputs[0], pw.inputs[0])
    jitter = _noise(nt, Q, 0.6, detail=4, stretch=(1, 1, 0.08))
    band = _mix(nt, pw.outputs[0], jitter, 0.25, dtype='FLOAT')
    cr = nt.nodes.new('ShaderNodeValToRGB'); e = cr.color_ramp.elements
    e[0].position = 0.0; e[0].color = (*light, 1); e[1].position = 0.85; e[1].color = (*dark, 1)
    mid = cr.color_ramp.elements.new(0.45); mid.color = (*[(a * 0.65 + b2 * 0.35) for a, b2 in zip(light, dark)], 1)
    l.new(band, cr.inputs['Fac'])
    col = cr.outputs['Color']
    # pores: fine stretched dark streaks along the grain
    po = _noise(nt, Q, 40.0, detail=4, rough=0.6, stretch=(1, 1, 0.025))
    pm = _maprange(nt, po, 0.62, 0.72, 0.0, 0.35 * pores)
    col = _mix(nt, col, (*[c * 0.45 for c in dark], 1), pm)
    # colour variation board-to-board
    tv = _noise(nt, Q, 0.05, detail=2)
    col = _mix(nt, col, (*[c * 0.8 for c in light], 1), _maprange(nt, tv, 0.3, 0.7, 0.0, 0.35))
    em = _edge_mask(nt, 0.6, 0.6, 0.97) if wear else None
    if wear:
        wm = _maprange(nt, _mix(nt, 0.0, em, _noise(nt, Q, 0.8, detail=5), dtype='FLOAT'), 0.2, 0.5, 0.0, wear)
        col = _mix(nt, col, (*[min(1, c * 1.25) for c in light], 1), wm)
    if grime:
        cm = _maprange(nt, _cavity_mask(nt, 3.0, 0.3, 0.92), 0, 1, 0, grime)
        col = _mix(nt, col, (0.05, 0.03, 0.018, 1), cm)
    l.new(col, b.inputs['Base Color'])
    r = _maprange(nt, band, 0.0, 1.0, rough - 0.08, rough + 0.06)
    if oiled:
        r = _mix(nt, r, rough - 0.25, _maprange(nt, _noise(nt, Q, 0.12, detail=3), 0.5, 0.7, 0.0, oiled), dtype='FLOAT')
    l.new(r, b.inputs['Roughness'])
    b.inputs['Coat Weight'].default_value = coat; b.inputs['Coat Roughness'].default_value = 0.3
    b.inputs['Sheen Weight'].default_value = 0.15
    h = _mix(nt, band, pm, 0.6, dtype='FLOAT')
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.25; bp.inputs['Distance'].default_value = 0.05
    l.new(h, bp.inputs['Height'])
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.25; l.new(bv.outputs['Normal'], bp.inputs['Normal'])
    l.new(bp.outputs['Normal'], b.inputs['Normal'])
    return m

def dark_mat(name, col=(0.02, 0.018, 0.016), rough=0.85):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*col, 1); b.inputs['Roughness'].default_value = rough; return m

def put(o, mat, bev=None, seg=3, harden=True, angle=40):
    """Assign material, link, bevel + weighted (hardened) normals."""
    link(o, mat)
    if o.type == 'MESH':
        # smooth curved faces, keep flat (cut) faces flat: no shading gradients across n-gons
        for ob in bpy.context.selected_objects: ob.select_set(False)
        o.select_set(True); bpy.context.view_layer.objects.active = o
        bpy.ops.object.shade_smooth_by_angle(angle=math.radians(angle - 5), keep_sharp_edges=True)
    if bev:
        md = o.modifiers.new('bev', 'BEVEL'); md.width = bev; md.segments = seg; md.limit_method = 'ANGLE'
        md.angle_limit = math.radians(angle); md.harden_normals = harden
        o.modifiers.new('wn', 'WEIGHTED_NORMAL').keep_sharp = True
    return o

def prism(name, pts, y0, y1, axis='Y'):
    """Extrude a closed 2D outline [(u, v), ...] (XZ plane) between y0 and y1."""
    bm = bmesh.new()
    vs = [bm.verts.new((u, y0, v)) for u, v in pts]
    f = bm.faces.new(vs)
    ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [g for g in ext['geom'] if isinstance(g, bmesh.types.BMVert)]: v.co.y = y1
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); return o

def screw_head(name, loc, r, h, axis='Y', slot=True, kind='pan', mat=None, rot=0.0):
    """Pan/cheese/dome screw head (or rivet when slot=False, kind='dome'), axis = direction it faces."""
    if kind == 'dome':
        prof = [(0.001, 0), (r, 0), (r * 0.97, h * 0.35), (r * 0.8, h * 0.75), (r * 0.45, h * 0.97), (0.001, h)]
    else:
        prof = [(0.001, 0), (r, 0), (r, h * 0.55), (r * 0.9, h * 0.9), (r * 0.7, h), (0.001, h)]
    o = lathe(name, prof, 0, 0, seg=48); o.modifiers.clear()
    if slot:
        s = box('slot', -r * 1.2, r * 1.2, -r * 0.11, r * 0.11, h * 0.45, h * 1.5); boolean(o, s)
        o.rotation_euler = (0, 0, rot); bpy.context.view_layer.objects.active = o
        o.select_set(True); bpy.ops.object.transform_apply(rotation=True)
    R = {'Z': Matrix.Identity(4), 'Y': Matrix.Rotation(-math.pi / 2, 4, 'X'), '-Y': Matrix.Rotation(math.pi / 2, 4, 'X'),
         'X': Matrix.Rotation(math.pi / 2, 4, 'Y'), '-X': Matrix.Rotation(-math.pi / 2, 4, 'Y'), '-Z': Matrix.Rotation(math.pi, 4, 'X')}[axis]
    o.data.transform(R); o.location = loc
    smooth(o)
    if mat: put(o, mat, 0.04, 2)
    return o

def thread(name, r_minor, r_major, pitch, x0, x1, axis='X', loc=(0, 0, 0)):
    """Real helical V-thread (Screw modifier on a triangular profile) along X from x0 to x1."""
    turns = max(1, int((x1 - x0) / pitch))
    bm = bmesh.new(); hp = pitch / 2
    prof = [(x0, r_minor), (x0 + hp * 0.9, r_major), (x0 + hp * 1.1, r_major), (x0 + pitch, r_minor)]
    vs = [bm.verts.new((px, 0, pz)) for px, pz in prof]
    for a, c in zip(vs, vs[1:]): bm.edges.new((a, c))
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    sc = o.modifiers.new('scr', 'SCREW'); sc.axis = 'X'; sc.screw_offset = pitch; sc.iterations = turns; sc.steps = 48; sc.render_steps = 48
    sc.use_merge_vertices = True; sc.use_normal_calculate = True
    bpy.context.view_layer.objects.active = o; bpy.ops.object.modifier_apply(modifier='scr')
    o.location = loc; smooth(o); return o

def world_hdri(strength=0.25, which='interior.exr', rot=0.0, sat=0.45):
    w = scene.world = bpy.data.worlds.new('w'); w.use_nodes = True; nt = w.node_tree
    env = nt.nodes.new('ShaderNodeTexEnvironment')
    env.image = bpy.data.images.load(os.path.join(bpy.utils.resource_path('LOCAL'), 'datafiles', 'studiolights', 'world', which))
    if rot:
        tc = nt.nodes.new('ShaderNodeTexCoord'); mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Rotation'].default_value = (0, 0, rot)
        nt.links.new(tc.outputs['Generated'], mp.inputs['Vector']); nt.links.new(mp.outputs['Vector'], env.inputs['Vector'])
    bg = nt.nodes['Background']; bg.inputs['Strength'].default_value = strength
    hs = nt.nodes.new('ShaderNodeHueSaturation'); hs.inputs['Saturation'].default_value = sat
    nt.links.new(env.outputs['Color'], hs.inputs['Color']); nt.links.new(hs.outputs['Color'], bg.inputs['Color']); return w

def area_light(name, loc, aim, size, energy, color=(1, 1, 1), size_y=None, spread=None):
    bpy.ops.object.light_add(type='AREA', location=loc); L = bpy.context.object; L.name = name
    L.data.size = size; L.data.energy = energy; L.data.color = color
    if size_y: L.data.shape = 'RECTANGLE'; L.data.size_y = size_y
    if spread: L.data.spread = math.radians(spread)
    c = L.constraints.new('TRACK_TO'); c.target = aim; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'; return L

def look_camera(target, yaw_deg, pitch_deg, dist, lens=180, sensor=36, roll_deg=0.0):
    cd = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cd); scene.collection.objects.link(cam); scene.camera = cam
    cd.lens = lens; cd.sensor_fit = 'HORIZONTAL'; cd.sensor_width = sensor; cd.dof.use_dof = False; cd.clip_start = 1; cd.clip_end = 5000
    t = Vector(target); yaw = math.radians(yaw_deg); pitch = math.radians(pitch_deg)
    cam.location = t + Vector((math.sin(yaw) * dist * math.cos(pitch), -math.cos(yaw) * dist * math.cos(pitch), math.sin(pitch) * dist))
    q = (t - cam.location).to_track_quat('-Z', 'Y')
    if roll_deg: q = q @ Matrix.Rotation(math.radians(roll_deg), 4, 'Z').to_quaternion()
    cam.rotation_euler = q.to_euler(); return cam

def render_setup(out, res, samples, exposure=0.0, look='AgX - Medium High Contrast', bounces=8, crop=None):
    s = scene; s.render.engine = 'CYCLES'; s.cycles.device = 'CPU'; s.cycles.samples = samples
    s.cycles.use_denoising = True; s.cycles.denoiser = 'OPENIMAGEDENOISE'
    s.cycles.denoising_input_passes = 'RGB_ALBEDO_NORMAL'; s.cycles.denoising_prefilter = 'ACCURATE'
    s.cycles.adaptive_threshold = 0.006; s.cycles.max_bounces = bounces; s.cycles.glossy_bounces = 6
    s.cycles.caustics_reflective = False; s.cycles.caustics_refractive = False; s.cycles.blur_glossy = 0.5
    s.render.film_transparent = False; s.view_settings.exposure = exposure
    s.render.resolution_x, s.render.resolution_y = res; s.render.resolution_percentage = 100
    s.view_settings.view_transform = 'AgX'; s.view_settings.look = look
    s.render.filepath = os.path.abspath(out)
    if crop:  # (x0, y0, x1, y1) in 0..1, y up: render a region only, for close inspection at final resolution
        s.render.use_border = True; s.render.use_crop_to_border = True
        s.render.border_min_x, s.render.border_min_y, s.render.border_max_x, s.render.border_max_y = crop

def cli():
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    def arg(n, d): return argv[argv.index(n) + 1] if n in argv else d
    return arg

import sys

def lathe_x(name, prof, seg=96, y=0.0, z=0.0):
    """Closed solid of revolution around the X axis; prof = [(x, r), ...] outline from front to back."""
    bm = bmesh.new(); rings = []
    for x, r in prof:
        rings.append([bm.verts.new((x, y + r * math.sin(2 * math.pi * i / seg), z + r * math.cos(2 * math.pi * i / seg))) for i in range(seg)])
    for a, b in zip(rings, rings[1:]):
        for i in range(seg): bm.faces.new((a[i], a[(i + 1) % seg], b[(i + 1) % seg], b[i]))
    bm.faces.new(rings[0]); bm.faces.new(list(reversed(rings[-1])))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); smooth(o); return o

def sawtooth(x0, x1, r_minor, r_major, pitch):
    """(x, r) profile points of a 60-degree thread form between x0 and x1 (for lathe_x)."""
    pts = []; x = x0
    while x + pitch <= x1 + 1e-6:
        pts += [(x, r_minor), (x + pitch * 0.42, r_major), (x + pitch * 0.58, r_major)]; x += pitch
    pts.append((x, r_minor)); return pts

def mirror_softbox(name, target, cam, normal=(0, -1, 0), dist=260, size=60, size_y=180, energy=300,
                   color=(1.0, 0.97, 0.92), shift=(0, 0, 0)):
    """Strip softbox placed where the cut plane mirrors the camera, so flat machined faces catch a soft
    gradient highlight (product-photo sheen). `shift` (degrees: dx, dz) slides it so only its edge shows."""
    t = Vector(target); n = Vector(normal).normalized(); d = (cam.location - t).normalized()
    r = (2 * d.dot(n) * n - d).normalized()
    r = Matrix.Rotation(math.radians(shift[0]), 3, 'Z') @ r
    r = (r + Vector((0, 0, math.radians(shift[2])))).normalized()
    aim = bpy.data.objects.new(name + '_aim', None); scene.collection.objects.link(aim); aim.location = t
    return area_light(name, tuple(t + r * dist), aim, size, energy, color, size_y=size_y)
