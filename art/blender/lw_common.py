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
        # flat ground ends: first/last coil closed
        zt = t * (z1 - z0)
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
