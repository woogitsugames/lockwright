# Lockwright look-dev: observation tools after the loupe (D-13). Product shots on the workshop bench.
#   --obj microscope : compact stereo inspection microscope (bench stand, LED ring illuminator)
#   --obj borescope  : flexible inspection probe (braided cable, LED-ring tip) with a small handheld screen
# Run:
#   blender -b -t 2 -P art/blender/optics.py -- --obj microscope --out art/renders/microscope.png --res 2160x2880 --samples 160
#   blender -b -t 2 -P art/blender/optics.py -- --obj borescope --out art/renders/borescope.png --res 2160x2880 --samples 160 \
#       --screen art/renders/borescope_view.png
# Invented, unbranded designs: no names, logos or text on the parts. Units: 1 Blender unit = 1 mm.
import bpy, bmesh, math, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lw_common import *
from lw_common import _maprange, _cavity_mask, _mix, _noise, _catmull
from mathutils import Vector, Matrix

arg = cli()
OBJ = arg('--obj', 'microscope'); OUT = arg('--out', 'art/renders/test_%s.png' % OBJ)
RES = [int(v) for v in arg('--res', '540x720').split('x')]; SAMPLES = int(arg('--samples', '32'))
SCREEN = arg('--screen', '')

# ================================================================ geometry helpers
def revolve(name, loop, seg=96):
    """Solid of revolution around local Z from a closed (r, z) loop (rings, tubes, cups with walls)."""
    bm = bmesh.new(); rings = []
    for r, z in loop:
        rings.append([bm.verts.new((r * math.cos(2 * math.pi * i / seg), r * math.sin(2 * math.pi * i / seg), z)) for i in range(seg)])
    for a, b in zip(rings, rings[1:] + rings[:1]):
        for i in range(seg): bm.faces.new((a[i], a[(i + 1) % seg], b[(i + 1) % seg], b[i]))
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-4)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); return o

def solid_rev(name, prof, seg=96):
    """Closed solid from an open (r, z) outline that starts and ends on the axis."""
    return revolve(name, [(max(r, 0.0005), z) for r, z in prof], seg)

def rrect(w, h, r, n=10, cx=0.0, cy=0.0):
    pts = []
    for qx, qy, a0 in ((1, 1, 0), (-1, 1, 90), (-1, -1, 180), (1, -1, 270)):
        c = (cx + qx * (w / 2 - r), cy + qy * (h / 2 - r))
        for k in range(n + 1):
            a = math.radians(a0 + 90 * k / n); pts.append((c[0] + r * math.cos(a), c[1] + r * math.sin(a)))
    return pts

def slab(name, pts, z0, z1):
    """Extrude a closed XY outline between z0 and z1."""
    bm = bmesh.new(); vs = [bm.verts.new((x, y, z0)) for x, y in pts]
    f = bm.faces.new(vs); ext = bmesh.ops.extrude_face_region(bm, geom=[f])
    for v in [g for g in ext['geom'] if isinstance(g, bmesh.types.BMVert)]: v.co.z = z1
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); return o

def ribbed(name, r_out, r_in, n, z0, z1, flat=0.45):
    """Knurled / ribbed knob around local Z: n flat-topped ribs with rounded valleys."""
    pts = []
    for i in range(n):
        for t, r in ((0.0, r_in), (0.5 - flat / 2, r_out), (0.5 + flat / 2, r_out)):
            a = 2 * math.pi * (i + t) / n; pts.append((r * math.cos(a), r * math.sin(a)))
    return slab(name, pts, z0, z1)

def xform(o, R=Matrix.Identity(3), t=(0, 0, 0)):
    o.data.transform(Matrix.Translation(t) @ R.to_4x4()); return o

def finish(o, mat, bev=0.4, seg=3, angle=35):
    put(o, mat, bev, seg, angle=angle); return o

def sweep(name, pts, r, seg=20, n=10, cap=True):
    """Tube along a Catmull-Rom path with parallel-transport frames and UVs in millimetres
    (u = around, v = along), for braid / rubber textures."""
    c = _catmull([Vector(p) for p in pts], n)
    bm = bmesh.new(); uvl = bm.loops.layers.uv.new('UVMap'); rings = []; vs_len = []; L = 0.0
    nrm = (c[1] - c[0]).normalized().orthogonal().normalized()
    for i, p in enumerate(c):
        t = (c[min(i + 1, len(c) - 1)] - c[max(i - 1, 0)]).normalized()
        nrm = (nrm - t * nrm.dot(t)).normalized(); b = t.cross(nrm)
        if i: L += (p - c[i - 1]).length
        rings.append([bm.verts.new(p + (nrm * math.cos(2 * math.pi * k / seg) + b * math.sin(2 * math.pi * k / seg)) * r) for k in range(seg)])
        vs_len.append(L)
    circ = 2 * math.pi * r
    for i in range(len(rings) - 1):
        for k in range(seg):
            f = bm.faces.new((rings[i][k], rings[i][(k + 1) % seg], rings[i + 1][(k + 1) % seg], rings[i + 1][k]))
            for lp, (uu, vv) in zip(f.loops, ((k, i), (k + 1, i), (k + 1, i + 1), (k, i + 1))):
                lp[uvl].uv = (uu / seg * circ, vs_len[vv])
    if cap:
        bm.faces.new(list(reversed(rings[0]))); bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); smooth(o); return o, c

# ================================================================ materials
def anodised(name, col, rough=0.34, wear=0.25, seed=0.0):
    """Bead-blasted, anodised aluminium: fine isotropic grain, dyed oxide over metal, edges rubbed to bare alloy."""
    m = metal(name, col, rough, marks='stamp', marks_scale=3.0, marks_amt=0.6, wear=wear, wear_col=(0.70, 0.70, 0.69),
              grime=0.3, smudge=0.6, bevel_r=0.25, seed=seed)
    b = m.node_tree.nodes['Principled BSDF']; b.inputs['Coat Weight'].default_value = 0.25; b.inputs['Coat Roughness'].default_value = 0.4
    return m

def rubber(name, col=(0.028, 0.027, 0.026), rough=0.62, grain=60.0):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links; b = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord'); P = tc.outputs['Object']
    cm = _maprange(nt, _cavity_mask(nt, 1.5), 0, 1, 0, 0.5)
    l.new(_mix(nt, (*col, 1), (col[0] * 2.4, col[1] * 2.3, col[2] * 2.1, 1), cm), b.inputs['Base Color'])  # pale dust in crevices
    l.new(_maprange(nt, _noise(nt, P, 0.8, 4), 0.3, 0.7, rough - 0.08, rough + 0.06), b.inputs['Roughness'])
    b.inputs['Sheen Weight'].default_value = 0.15
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.12; bp.inputs['Distance'].default_value = 0.02
    l.new(_noise(nt, P, grain, 3), bp.inputs['Height']); l.new(bp.outputs['Normal'], b.inputs['Normal'])
    return m

def glass(name, tint=(1, 1, 1), coat=True, rough=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*tint, 1); b.inputs['Transmission Weight'].default_value = 1.0
    b.inputs['Roughness'].default_value = rough; b.inputs['IOR'].default_value = 1.52
    if coat:  # anti-reflection coating: faint tinted reflections, not a rainbow
        b.inputs['Thin Film Thickness'].default_value = 140.0; b.inputs['Thin Film IOR'].default_value = 1.38
    return m

def plastic(name, col, rough=0.4, trans=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*col, 1); b.inputs['Roughness'].default_value = rough
    b.inputs['Transmission Weight'].default_value = trans; return m

def emissive(name, col, strength):
    m = bpy.data.materials.new(name); m.use_nodes = True; b = m.node_tree.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (*col, 1); b.inputs['Roughness'].default_value = 0.35
    b.inputs['Emission Color'].default_value = (*col, 1); b.inputs['Emission Strength'].default_value = strength; return m

def braid(name, col=(0.62, 0.62, 0.61), w=0.9, k=1.25, wires=6):
    """Stainless over-braid on a sweep() tube: two counter-wound families of flat wire bundles, over/under weave."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links; b = nt.nodes['Principled BSDF']
    b.inputs['Metallic'].default_value = 1.0
    uv = nt.nodes.new('ShaderNodeUVMap'); sx = nt.nodes.new('ShaderNodeSeparateXYZ'); l.new(uv.outputs['UV'], sx.inputs[0])
    def mth(op, a, c=None, d=None):
        n_ = nt.nodes.new('ShaderNodeMath'); n_.operation = op
        for i, v in enumerate((a, c, d)):
            if v is None: continue
            if hasattr(v, 'links'): l.new(v, n_.inputs[i])
            else: n_.inputs[i].default_value = v
        return n_.outputs[0]
    U, V = sx.outputs['X'], sx.outputs['Y']
    A = mth('DIVIDE', mth('MULTIPLY_ADD', V, k, U), w); B = mth('DIVIDE', mth('SUBTRACT', U, mth('MULTIPLY', V, k)), w)
    over = mth('PINGPONG', mth('ADD', mth('FLOOR', A), mth('FLOOR', B)), 1.0)        # 0/1 checker of the weave
    def strand(T):  # bundle of `wires` round wires across one strand + crown of the strand
        fr = mth('FRACT', T); crown = mth('SINE', mth('MULTIPLY', fr, math.pi))
        ripple = mth('ABSOLUTE', mth('SINE', mth('MULTIPLY', fr, math.pi * wires)))
        return mth('MULTIPLY', crown, mth('ADD', mth('MULTIPLY', ripple, 0.5), 0.5))
    hA, hB = strand(A), strand(B)
    hh = mth('MAXIMUM', _mix(nt, 0.0, hA, over, dtype='FLOAT'), _mix(nt, 0.0, hB, mth('SUBTRACT', 1.0, over), dtype='FLOAT'))
    hh = mth('MAXIMUM', hh, mth('MULTIPLY', mth('MAXIMUM', hA, hB), 0.55))
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.6; bp.inputs['Distance'].default_value = 0.08
    l.new(hh, bp.inputs['Height']); l.new(bp.outputs['Normal'], b.inputs['Normal'])
    low = mth('SUBTRACT', 1.0, hh)  # valleys: darker (occlusion + grime), rougher
    l.new(_mix(nt, (*col, 1), (col[0] * 0.25, col[1] * 0.24, col[2] * 0.22, 1), mth('POWER', low, 2.0)), b.inputs['Base Color'])
    l.new(_maprange(nt, low, 0.0, 1.0, 0.24, 0.55), b.inputs['Roughness'])
    b.inputs['Anisotropic'].default_value = 0.3
    return m

def screen_mat(name, path, strength=1.6):
    """Display under cover glass: black matrix when off; the probe image as emission, glossy glass on top."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links; b = nt.nodes['Principled BSDF']
    b.inputs['Base Color'].default_value = (0.006, 0.007, 0.008, 1); b.inputs['Roughness'].default_value = 0.35
    b.inputs['Coat Weight'].default_value = 1.0; b.inputs['Coat Roughness'].default_value = 0.03; b.inputs['Coat IOR'].default_value = 1.52
    if path and os.path.exists(path):
        tx = nt.nodes.new('ShaderNodeTexImage'); tx.image = bpy.data.images.load(os.path.abspath(path)); tx.extension = 'CLIP'
        tc = nt.nodes.new('ShaderNodeTexCoord'); l.new(tc.outputs['UV'], tx.inputs['Vector'])
        l.new(tx.outputs['Color'], b.inputs['Emission Color']); b.inputs['Emission Strength'].default_value = strength
    return m

MAT = {
    'paint':   paint('cast', (0.060, 0.066, 0.062), rough=0.5, chip=0.12, grime=0.45, peel=0.05),
    'ano_nat': anodised('ano_nat', (0.60, 0.61, 0.62), 0.32, seed=1.0),
    'ano_dk':  anodised('ano_dk', (0.075, 0.075, 0.08), 0.36, wear=0.35, seed=2.0),
    'ano_br':  anodised('ano_br', (0.30, 0.22, 0.14), 0.34, wear=0.3, seed=3.0),   # warm bronze accent rings
    'rubber':  rubber('rubber'),
    'rub_soft': rubber('rub_soft', (0.035, 0.034, 0.033), 0.7, grain=140),
    'glass':   glass('glass'),
    'steel':   metal('steel_p', (0.60, 0.60, 0.60), 0.18, marks='turn', marks_axis=(0, 0, 1), wear=0.2, grime=0.3),
    'black':   plastic('black', (0.02, 0.02, 0.022), 0.32),
    'stage':   plastic('stage', (0.032, 0.032, 0.034), 0.55),
    'tick':    plastic('tick', (0.70, 0.68, 0.62), 0.5),
}

def bench():
    top = slab('bench', rrect(1400, 1000, 4, 2), -30, 0)
    put(top, wood('bench_wood', light=(0.46, 0.30, 0.16), dark=(0.24, 0.13, 0.06), axis='X', ring=0.7, rough=0.55,
                  oiled=0.45, wear=0.5, grime=0.5, warp=2.0), 1.0)
    return top

# ================================================================ microscope
def microscope():
    Rx = lambda d: Matrix.Rotation(math.radians(d), 3, 'X'); Ry = lambda d: Matrix.Rotation(math.radians(d), 3, 'Y')
    SX, SY = 0.0, -22.0                       # optical axis / stage centre
    # base: cast, powder-coated, with a reversible stage plate and two spring clips
    finish(slab('base', rrect(124, 156, 16, 12, 0, 6), 0, 17), MAT['paint'], 3.2, 5)
    finish(solid_rev('stage', [(0, 16.4), (36.5, 16.4), (37, 16.9), (37, 17.6), (36.4, 18.0), (0, 18.0)]), MAT['stage'], 0.2, 2)
    xform(bpy.data.objects['stage'], t=(SX, SY, 0))
    for sx in (-1, 1):
        post = finish(solid_rev('clip_post', [(0, 17), (2.6, 17), (2.6, 21.5), (2.1, 22.4), (0, 22.4)], 48), MAT['steel'], 0.1, 2)
        xform(post, t=(sx * 30, SY + 18, 0))
        cl = finish(slab('clip', rrect(5.2, 30, 2.6, 6), 20.4, 21.0), MAT['steel'], 0.12, 2)
        xform(cl, Matrix.Rotation(math.radians(sx * 18), 3, 'Z'), (sx * 26, SY + 4, 0))
    # specimen on the stage: a key pin and a driver pin from the cylinder, lying on their sides
    kp = solid_rev('spec_key', [(0, 0), (0.5, 0.12), (0.95, 0.45), (1.37, 0.95), (1.42, 1.1), (1.42, 4.42), (1.24, 4.6), (0, 4.6)], 48)
    finish(xform(kp, Ry(90) @ Matrix.Rotation(0.3, 3, 'Z'), (-8, SY - 3, 18 + 1.42)), M['brass_k'], 0.05, 2)
    dp = solid_rev('spec_drv', [(0, 0), (1.24, 0), (1.42, 0.18), (1.42, 3.82), (1.24, 4.0), (0, 4.0)], 48)
    finish(xform(dp, Ry(90) @ Matrix.Rotation(-0.5, 3, 'Z'), (4, SY + 5, 18 + 1.42)), M['steel'], 0.05, 2)
    # pillar with a clamping collar at the foot
    PY = 54.0
    finish(xform(solid_rev('pillar', [(0, 16), (11, 16), (11, 214), (10.2, 216), (0, 216)]), t=(0, PY, 0)), MAT['ano_nat'], 0.3)
    finish(xform(ribbed('collar', 17, 15.8, 36, 16, 27), t=(0, PY, 0)), MAT['ano_dk'], 0.35, 2)
    finish(xform(ribbed('stop_ring', 15.5, 14.6, 30, 96, 104), t=(0, PY, 0)), MAT['ano_dk'], 0.3, 2)
    # focus block (rack housing) with knurled rubber knobs on both sides
    finish(slab('fblock', rrect(46, 44, 10, 8, 0, PY - 2), 104, 160), MAT['ano_dk'], 2.0, 4)
    for sx in (-1, 1):
        k = ribbed('fknob', 19, 17.6, 40, 0, 13); finish(xform(k, Ry(90 * sx), (sx * 23.5, PY - 4, 132)), MAT['rubber'], 0.5, 3)
        h = solid_rev('fhub', [(0, 0), (9, 0), (9, 2.5), (8, 3.6), (0, 3.6)], 64)
        finish(xform(h, Ry(90 * sx), (sx * 36.5, PY - 4, 132)), MAT['ano_nat'], 0.3, 2)
        cap = solid_rev('fcap', [(0, 0), (12, 0), (12, 3.5), (0, 3.5)], 64)
        finish(xform(cap, Ry(90 * sx), (sx * 21.5, PY - 4, 132)), MAT['ano_br'], 0.4, 2)
    # arm to the head
    finish(slab('arm', rrect(34, 74, 12, 8, 0, 18), 134, 156), MAT['ano_dk'], 3.0, 4)
    # head: body, objective nose, LED ring illuminator with diffuser
    finish(xform(solid_rev('head', [(0, 124), (25, 124), (28, 126.5), (31, 131), (31, 158), (29, 162), (0, 163)]), t=(SX, SY, 0)), MAT['ano_dk'], 0.6)
    finish(xform(solid_rev('nose', [(0, 108), (15.5, 108), (16.5, 109.2), (17, 114), (21, 121), (23, 124.5), (0, 124.5)]), t=(SX, SY, 0)), MAT['ano_nat'], 0.4)
    finish(xform(solid_rev('objlens', [(0, 107.6), (12, 107.6), (12, 108.4), (0, 108.4)], 64), t=(SX, SY, 0)), MAT['glass'], 0.1, 2)
    finish(xform(revolve('ledring', [(18.2, 104), (28.5, 104), (29.5, 105.4), (29.5, 113), (28, 114.5), (18.2, 114.5)]), t=(SX, SY, 0)), MAT['ano_dk'], 0.4)
    dif = emissive('diffuser', (0.95, 0.94, 0.92), float(arg('--led', '3.0')))
    dif.node_tree.nodes['Principled BSDF'].inputs['Transmission Weight'].default_value = 0.4
    finish(xform(revolve('diff', [(19.0, 103.4), (27.8, 103.4), (27.8, 104.1), (19.0, 104.1)]), t=(SX, SY, 0)), dif, 0.15, 2)
    # zoom drum on both sides of the head, with an index band of painted ticks
    for sx in (-1, 1):
        d = ribbed('zoom', 18, 16.8, 44, 0, 10); finish(xform(d, Ry(90 * sx), (sx * 31, SY, 146)), MAT['rubber'], 0.5, 3)
        band = solid_rev('zband', [(0, 0), (16.6, 0), (16.6, 4.5), (0, 4.5)], 96); finish(xform(band, Ry(90 * sx), (sx * 41, SY, 146)), MAT['ano_nat'], 0.4, 2)
        endc = solid_rev('zcap', [(0, 0), (15, 0), (15, 1.6), (13.5, 2.6), (0, 2.6)], 64); finish(xform(endc, Ry(90 * sx), (sx * 45.5, SY, 146)), MAT['ano_dk'], 0.3, 2)
        for t in range(9):
            a = math.radians(-40 + t * 10)
            hl = 1.0 if t % 2 == 0 else 0.55
            tk = box('tick', -hl, hl, -0.16, 0.16, -0.25, 0.12)
            tk.data.transform(Matrix.Translation((sx * 43.25, SY + 16.6 * math.sin(a), 146 + 16.6 * math.cos(a))) @ Matrix.Rotation(-a, 4, 'X'))
            link(tk, MAT['tick'])
    # binocular body tilted 45 degrees toward the user, two eyepiece tubes with rubber eyecups
    R45 = Rx(40.0); T = Vector((SX, SY + 4, 160))
    bb = slab('binobody', rrect(96, 38, 15, 10), 0, 26); finish(xform(bb, R45, T), MAT['ano_dk'], 2.2, 4)
    neck = solid_rev('neck', [(0, 0), (24, 0), (24, 6), (0, 6)]); finish(xform(neck, Matrix.Identity(3), (SX, SY, 160)), MAT['ano_nat'], 0.4, 2)
    for sx in (-1, 1):
        base = T + R45 @ Vector((sx * 31, 0, 22))
        tube = revolve('eyetube', [(0.0005, 0), (11, 0), (11, 30), (12.5, 31), (12.5, 52), (11.5, 53), (0.0005, 53)])
        finish(xform(tube, R45, base), MAT['ano_dk'], 0.3)
        dio = ribbed('diopter', 13.4, 12.6, 48, 33, 44); finish(xform(dio, R45, base), MAT['ano_br'], 0.25, 2)
        cup = revolve('eyecup', [(10.2, 52), (13.2, 52), (13.6, 60), (15.2, 69), (15.4, 71.5), (14.6, 72.6), (13.4, 72.2), (11.4, 64), (10.2, 60)])
        finish(xform(cup, R45, base), MAT['rub_soft'], 0.4)
        ocl = solid_rev('ocular', [(0, 55.5), (10.4, 55.5), (10.4, 57), (0, 57.6)], 64); finish(xform(ocl, R45, base), MAT['glass'], 0.1, 2)
        blk = solid_rev('ocular_bk', [(0, 54.0), (10.6, 54.0), (10.6, 55.4), (0, 55.4)], 64); finish(xform(blk, R45, base), MAT['black'], 0.05, 1)
    # power cable from the ring light, clipped along the arm and down the pillar into the base
    path = [(0, SY + 29.5, 109), (0, SY + 34, 112), (0, 2, 130), (0, 20, 133), (0, 36, 134), (8, 46, 120), (13, 56, 100),
            (13.2, 60, 60), (13.4, 62, 30), (16, 70, 18), (22, 84, 14)]
    sweep('cable', path, 1.7, 16, 10)[0].data.materials.append(MAT['rubber'])
    for z in (70, 46):
        c = finish(xform(revolve('cclip', [(11, -2.5), (13.6, -2.5), (13.8, 2.5), (11, 2.5)]), t=(0, PY, z)), MAT['ano_nat'], 0.2, 2)
    bench()
    return Vector((0, 10, 105)), (95, 215)

# ================================================================ borescope
def borescope():
    Rx = lambda d: Matrix.Rotation(math.radians(d), 3, 'X'); Ry = lambda d: Matrix.Rotation(math.radians(d), 3, 'Y')
    Rz = lambda d: Matrix.Rotation(math.radians(d), 3, 'Z')
    # handheld: rubber over-moulded lower shell, anodised top frame, screen under cover glass, three rubber keys
    out = [(0, 82), (30, 82), (38, 76), (40, 64), (40, 18), (33, 2), (31, -10), (31, -70), (26, -80), (0, -82)]
    full = out + [(-x, y) for x, y in reversed(out)][1:-1]
    sm = [(p.x, p.y) for p in _catmull([Vector((x, y, 0)) for x, y in full] + [Vector((full[0][0], full[0][1], 0))], 8)][:-1]
    H = Rz(-14); T = Vector((-22, 70, 0))
    lo = slab('shell_lo', sm, 0, 13); finish(xform(lo, H, T), MAT['rubber'], 3.5, 5)
    inset = [(x * 0.955, y * 0.975) for x, y in sm]
    hi = slab('shell_hi', inset, 12.5, 21); finish(xform(hi, H, T), MAT['ano_dk'], 2.2, 4)
    bez = slab('bezel', rrect(66, 54, 4, 6, 0, 46), 20.6, 21.6); finish(xform(bez, H, T), MAT['black'], 0.3, 2)
    scr = slab('screen', rrect(60, 45, 1.5, 4, 0, 47), 21.2, 21.75)
    me = scr.data; me.uv_layers.new(name='UVMap')
    for poly in me.polygons:  # planar UV across the 60 x 45 window (image is square: crop sides)
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            me.uv_layers[0].data[li].uv = ((co.x + 30) / 60 * (60 / 45) - (60 / 45 - 1) / 2, (co.y - 24.5) / 45)
    finish(xform(scr, H, T), screen_mat('screen', SCREEN, float(arg('--scr', '1.4'))), 0.2, 1)
    for i, (bx, by, r) in enumerate(((-15, -2, 6.0), (15, -2, 6.0), (0, -20, 8.5))):
        k = solid_rev('key%d' % i, [(0, 0), (r, 0), (r, 1.8), (r - 1.2, 3.0), (0, 3.2)], 64)
        finish(xform(k, H, T + H @ Vector((bx, by, 20.2))), MAT['rub_soft'], 0.4, 3)
        if i == 2:  # power key: a single raised ring, felt not read
            rg = revolve('keyring', [(3.0, 3.1), (4.0, 3.1), (4.0, 3.6), (3.0, 3.6)], 48); finish(xform(rg, H, T + H @ Vector((bx, by, 20.2))), MAT['rub_soft'], 0.1, 1)
    # grip texture: shallow ribs on the rubber flanks
    for j in range(9):
        for sx in (-1, 1):
            rb = box('grip', sx * 31.6 - 0.8, sx * 31.6 + 0.8, -66 + j * 6.0, -63.4 + j * 6.0, 3, 10)
            finish(xform(rb, H, T), MAT['rubber'], 0.5, 2)
    # lanyard loop at the foot
    ly = sweep('lanyard', [(-5, -82, 6), (-6, -92, 5), (0, -100, 3), (6, -92, 5), (5, -82, 6)], 1.1, 12, 8)[0]
    xform(ly, H, T); ly.data.materials.append(rubber('cord', (0.05, 0.045, 0.04), 0.8, 200))
    # connector at the top: knurled aluminium nut, bronze ring, tapered strain relief
    C = T + H @ Vector((0, 82, 10.5)); CR = H @ Rx(-90)
    nut = ribbed('nut', 8.2, 7.6, 30, 0, 9); finish(xform(nut, CR, C), MAT['ano_nat'], 0.25, 2)
    finish(xform(revolve('cring', [(5.6, 9), (8.0, 9), (8.0, 11), (5.6, 11)]), CR, C), MAT['ano_br'], 0.2, 2)
    finish(xform(solid_rev('relief', [(0, 11), (6.2, 11), (5.4, 18), (3.6, 30), (2.6, 40), (0, 40)]), CR, C), MAT['rubber'], 0.4, 2)
    # braided probe cable: out of the top, a loose loop to the right, back toward the camera, tip resting on the bench
    d = H @ Vector((0, 1, 0)); p0 = C + d * 39
    path = [tuple(p0), tuple(p0 + d * 25 + Vector((0, 0, -2))), (62, 140, 2.2), (150, 120, 2.2), (175, 40, 2.2), (150, -40, 2.2),
            (90, -80, 2.2), (30, -92, 2.2), (-5, -96, 2.2)]
    cab, cl = sweep('probe', path, 2.0, 24, 14)
    cab.data.materials.append(braid('braid'))
    # tip: crimped ferrule, knurled band, steel head; lens and six LEDs on the face
    tdir = (cl[-1] - cl[-2]).normalized(); TR = tdir.to_track_quat('Z', 'Y').to_matrix(); P0 = cl[-1]
    head = [(0, 0), (2.3, 0), (2.3, 4), (2.6, 4.6), (2.6, 9), (2.85, 9.4), (2.85, 18.4), (2.55, 19.0), (0, 19.0)]
    tip = finish(xform(solid_rev('tip', head, 64), TR, P0 - tdir * 0.5), MAT['steel'], 0.12, 2)
    kn = ribbed('tipknurl', 2.95, 2.75, 32, 10, 14); finish(xform(kn, TR, P0 - tdir * 0.5), MAT['steel'], 0.05, 1)
    face = P0 - tdir * 0.5 + tdir * 19.0
    finish(xform(solid_rev('tiplens', [(0, 0), (0.95, 0), (0.85, 0.25), (0.5, 0.42), (0, 0.46)], 48), TR, face - tdir * 0.1), MAT['glass'], 0.02, 1)
    finish(xform(revolve('lensbk', [(0.0005, -0.5), (1.05, -0.5), (1.05, 0.02), (0.0005, 0.02)], 48), TR, face), MAT['black'], 0.02, 1)
    ledm = emissive('led', (1.0, 0.93, 0.78), float(arg('--led', '4.0')))
    for k in range(6):
        a = 2 * math.pi * (k + 0.5) / 6
        lo_ = box('led', -0.32, 0.32, -0.32, 0.32, -0.15, 0.06); lo_.data.transform(Matrix.Translation((1.75 * math.cos(a), 1.75 * math.sin(a), 0)))
        finish(xform(lo_, TR, face), ledm, 0.05, 1)
    # cover glass protecting the head face
    bench()
    return Vector((30, 30, 8)), (300, 0)

# ================================================================ scene
if OBJ == 'microscope':
    tgt, (dist, _) = microscope()
    world_hdri(float(arg('--world', '0.10')), sat=0.4)
    cam = look_camera(tuple(tgt), float(arg('--yaw', '-28')), float(arg('--pitch', '14')), float(arg('--dist', '760')),
                      lens=float(arg('--lens', '85')))
else:
    tgt, _ = borescope()
    world_hdri(float(arg('--world', '0.10')), sat=0.4)
    cam = look_camera(tuple(tgt), float(arg('--yaw', '-12')), float(arg('--pitch', '42')), float(arg('--dist', '820')),
                      lens=float(arg('--lens', '70')))
cam.data.clip_start = 5; cam.data.clip_end = 20000
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = tgt
K = float(arg('--k', '1.0'))
area_light('key', (-520, -380, 620), AIM, 420, 2.2e6 * K, (1.0, 0.88, 0.74))                 # warm softbox, upper left
area_light('fill', (640, -420, 220), AIM, 600, 4.0e5 * K, (0.92, 0.95, 1.0))                  # cool window fill
area_light('rim', (260, 720, 420), AIM, 260, 1.4e6 * K, (1.0, 0.96, 0.9))                     # back rim: edges, bevels
render_setup(OUT, RES, SAMPLES, exposure=float(arg('--exp', '0.0')))
bpy.ops.render.render(write_still=True)
print('WROTE', scene.render.filepath)
