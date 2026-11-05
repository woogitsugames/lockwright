# Lockwright look-dev: leather tool roll seen from above (lives = spare picks; empty pocket = lost pick).
#   blender -b -P art/blender/tray.py -- --out art/renders/tray.png --res 2160x1920 --samples 160
# Scene axes: the roll lies in the XZ plane (leather face at y = -2), the camera looks along +Y, "up" off
# the table is -Y. Units: 1 mm. Lights are sized in Blender's metre-based power units, so a key at ~250 mm
# needs ~10^5 W to out-weigh the HDRI (irradiance ~ P / (pi d^2)); otherwise the scene goes flat.
import bpy, bmesh, math, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lw_common import *
from lw_common import _noise, _mix, _maprange, _edge_mask, _cavity_mask
from mathutils import Vector, Matrix

arg = cli()
OUT = arg('--out', 'tray.png'); RES = [int(v) for v in arg('--res', '1080x960').split('x')]
SAMPLES = int(arg('--samples', '96')); LOST = int(arg('--lost', '1'))
CZ = float(arg('--cz', '4'))  # vertical centre of the frame (taller frame shows more leather above/below)

# ---------------------------------------------------------------- materials
def leather(name, color, rough=0.55, grain=1.0, wear=0.5, seed=0.0, burnish=0.0):
    """Vegetable-tanned leather: pebble grain (voronoi cells), creases, tonal mottling, darker handled
    patches, satin roughness variation, lighter scuffs on convex edges, sheen."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links
    b = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord'); P = tc.outputs['Object']
    if seed:
        mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (seed * 13.1, seed * 3.7, seed * 7.9)
        l.new(P, mp.inputs['Vector']); P = mp.outputs['Vector']
    # pebble grain: voronoi F1 smooth distance, cells ~0.7 mm, randomised
    wp = nt.nodes.new('ShaderNodeTexNoise'); wp.inputs['Scale'].default_value = 0.6; wp.inputs['Detail'].default_value = 3
    l.new(P, wp.inputs['Vector'])
    wv = nt.nodes.new('ShaderNodeVectorMath'); wv.operation = 'MULTIPLY_ADD'; l.new(wp.outputs['Color'], wv.inputs[0])
    wv.inputs[1].default_value = (0.8, 0.8, 0.8); l.new(P, wv.inputs[2])
    vo = nt.nodes.new('ShaderNodeTexVoronoi'); vo.feature = 'SMOOTH_F1'; vo.inputs['Scale'].default_value = 1.35 * grain
    vo.inputs['Smoothness'].default_value = 0.6; vo.inputs['Randomness'].default_value = 1.0; l.new(wv.outputs[0], vo.inputs['Vector'])
    cell = _maprange(nt, vo.outputs['Distance'], 0.0, 0.55)
    # creases: thin random valleys (leather flexing), stronger in places
    cn = _noise(nt, P, 0.35, detail=8, rough=0.62, dist=0.6)
    sub = nt.nodes.new('ShaderNodeMath'); sub.operation = 'SUBTRACT'; l.new(cn, sub.inputs[0]); sub.inputs[1].default_value = 0.5
    ab = nt.nodes.new('ShaderNodeMath'); ab.operation = 'ABSOLUTE'; l.new(sub.outputs[0], ab.inputs[0])
    crease = _maprange(nt, ab.outputs[0], 0.018, 0.0)
    cgate = _maprange(nt, _noise(nt, P, 0.12, detail=2), 0.45, 0.65)
    crease = _mix(nt, 0.0, crease, cgate, dtype='FLOAT')
    # colour: mottled tone + handled darker patches + crease darkening + valleys of the grain darker
    mot = _noise(nt, P, 0.18, detail=6, rough=0.6)
    col = _mix(nt, (*[c * 0.72 for c in color], 1), (*[min(1, c * 1.18) for c in color], 1), _maprange(nt, mot, 0.3, 0.7))
    hp = _maprange(nt, _noise(nt, P, 0.05, detail=3), 0.5, 0.75, 0.0, 0.55)
    col = _mix(nt, col, (*[c * 0.55 for c in color], 1), hp)
    col = _mix(nt, col, (*[c * 0.6 for c in color], 1), _maprange(nt, cell, 0.5, 1.0, 0.0, 0.5))
    col = _mix(nt, col, (*[c * 0.35 for c in color], 1), crease)
    em = _edge_mask(nt, 1.2, 0.55, 0.97)
    if wear:  # scuffed lighter, drier edges
        wm = _maprange(nt, _mix(nt, 0.0, em, _noise(nt, P, 1.5, detail=5), dtype='FLOAT'), 0.15, 0.45, 0.0, wear)
        col = _mix(nt, col, (*[min(1, c * 1.55) for c in color], 1), wm)
    gm = _maprange(nt, _cavity_mask(nt, 2.5, 0.3, 0.95), 0, 1, 0, 0.7)
    col = _mix(nt, col, (0.03, 0.017, 0.009, 1), gm)
    l.new(col, b.inputs['Base Color'])
    # roughness: satin with polished (handled) patches, rough in crease valleys
    r = _maprange(nt, mot, 0.3, 0.7, rough - 0.08, rough + 0.08)
    r = _mix(nt, r, rough - 0.2 - burnish * 0.1, hp, dtype='FLOAT')
    r = _mix(nt, r, min(1, rough + 0.2), crease, dtype='FLOAT')
    l.new(r, b.inputs['Roughness'])
    b.inputs['Sheen Weight'].default_value = 0.35; b.inputs['Sheen Roughness'].default_value = 0.45
    b.inputs['Specular IOR Level'].default_value = 0.45
    # relief: grain cells + creases + soft large undulation
    h = _mix(nt, cell, 1.0, crease, dtype='FLOAT')
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.6 * grain; bp.inputs['Distance'].default_value = 0.06
    l.new(h, bp.inputs['Height'])
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.5; l.new(bv.outputs['Normal'], bp.inputs['Normal'])
    l.new(bp.outputs['Normal'], b.inputs['Normal'])
    return m

def thread_mat():
    m = bpy.data.materials.new('linen'); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord')
    tw = _noise(nt, tc.outputs['Object'], 6.0, detail=4, stretch=(1, 1, 0.2))  # twisted waxed linen
    nt.links.new(_mix(nt, (0.40, 0.30, 0.18, 1), (0.62, 0.50, 0.32, 1), tw), b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.45; b.inputs['Sheen Weight'].default_value = 0.5
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.4; nt.links.new(tw, bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], b.inputs['Normal'])
    return m

def glass_mat():
    """Lens glass that lets shadow rays through (no caustics in the render, so plain glass would go black)."""
    m = bpy.data.materials.new('glass'); m.use_nodes = True; nt = m.node_tree; l = nt.links
    out = nt.nodes['Material Output']; g = nt.nodes['Principled BSDF']
    g.inputs['Transmission Weight'].default_value = 1.0; g.inputs['Roughness'].default_value = 0.02; g.inputs['IOR'].default_value = 1.52
    g.inputs['Base Color'].default_value = (0.97, 0.99, 0.98, 1)
    tr = nt.nodes.new('ShaderNodeBsdfTransparent'); lp = nt.nodes.new('ShaderNodeLightPath')
    mx = nt.nodes.new('ShaderNodeMixShader'); l.new(lp.outputs['Is Shadow Ray'], mx.inputs[0])
    l.new(g.outputs[0], mx.inputs[1]); l.new(tr.outputs[0], mx.inputs[2]); l.new(mx.outputs[0], out.inputs['Surface'])
    return m

LE = leather('leather', (0.30, 0.155, 0.07), 0.55, seed=0.0, wear=0.4)
LE2 = leather('pocket', (0.25, 0.125, 0.055), 0.5, seed=3.0, wear=0.9, burnish=1.0)
LE3 = leather('imprint', (0.2, 0.1, 0.045), 0.3, grain=0.35, seed=5.0, wear=0.0)
TH = thread_mat(); GL = glass_mat()
PICK = metal('pick_steel', (0.64, 0.64, 0.65), 0.2, aniso=0.6, marks='grind', marks_axis=(0, 0, 1), marks_scale=1.4,
             wear=0.6, wear_col=(0.8, 0.8, 0.8), grime=0.35, smudge=0.6, bevel_r=0.08)
BRASS = metal('ring_brass', (0.80, 0.58, 0.28), 0.24, marks='turn', marks_axis=(0, 1, 0), wear=0.7, wear_col=(0.95, 0.78, 0.48),
              grime=0.6, patina=0.3)
RUB = bpy.data.materials.new('loupe_body'); RUB.use_nodes = True
_rb = RUB.node_tree.nodes['Principled BSDF']; _rb.inputs['Base Color'].default_value = (0.025, 0.024, 0.023, 1)
_rb.inputs['Roughness'].default_value = 0.42; _rb.inputs['Coat Weight'].default_value = 0.0

# ---------------------------------------------------------------- geometry
def undulation(x, z, seed):
    random.seed(seed); ph = [random.uniform(0, 6.28) for _ in range(3)]
    return 0.25 * math.sin(x * 0.11 + ph[0]) * math.sin(z * 0.07 + ph[1]) + 0.15 * math.sin(x * 0.23 + z * 0.19 + ph[2])

def leather_slab(name, x0, x1, z0, z1, y_face, thick, mat, puff=0.0, cuts=40, seed=0, bev=0.9):
    """Subdivided slab with gentle undulation (leather is never flat) and rounded cut edges."""
    o = box(name, x0, x1, y_face, y_face + thick, z0, z1)
    md = o.modifiers.new('sub', 'SUBSURF'); md.subdivision_type = 'SIMPLE'; md.levels = md.render_levels = 0
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.subdivide(number_cuts=cuts); bpy.ops.object.mode_set(mode='OBJECT')
    o.modifiers.clear()
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2; hx, hz = (x1 - x0) / 2, (z1 - z0) / 2
    for v in o.data.vertices:
        if v.co.y < y_face + thick * 0.5:  # front face only
            u = (v.co.x - cx) / hx; w = (v.co.z - cz) / hz
            d = undulation(v.co.x, v.co.z, seed)
            if puff: d += puff * max(0.0, 1 - u * u) * max(0.0, 1 - max(0.0, w) ** 6)  # pocket bulges over the tool
            v.co.y -= d
    put(o, mat, bev, 4, harden=False)
    return o

def stitches(xs, z0, z1, pitch, y, ang=28.0):
    """Saddle-stitch line along Z: short slanted waxed-thread capsules sitting in the grain."""
    n = int((z1 - z0) / pitch)
    for k in range(n):
        z = z0 + k * pitch + pitch * 0.5
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1.0, location=(xs, y, z))
        s = bpy.context.object; s.scale = (0.32, 0.22, pitch * 0.36); s.rotation_euler = (0, math.radians(ang), 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True); smooth(s); link(s, TH)

def stitches_h(zs, x0, x1, pitch, y, ang=28.0):
    n = int((x1 - x0) / pitch)
    for k in range(n):
        x = x0 + k * pitch + pitch * 0.5
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1.0, location=(x, y, zs))
        s = bpy.context.object; s.scale = (pitch * 0.36, 0.22, 0.32); s.rotation_euler = (0, math.radians(ang), 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True); smooth(s); link(s, TH)

# roll body (big enough to fill any frame), with an edge-stitched fold line near the top
roll = leather_slab('roll', -110, 110, -130, 130, -2.0, 3.0, LE, cuts=60, seed=1)
fold = leather_slab('fold', -110, 110, 47, 130, -3.6, 1.7, LE, cuts=40, seed=2, bev=0.6)
stitches_h(50.0, -100, 100, 3.6, -3.62)

POCKET_X = [-48, -16, 16]
for i, x in enumerate(POCKET_X):
    leather_slab('flap%d' % i, x - 14, x + 14, -130, -4, -4.0, 2.0, LE2, puff=0.9, cuts=30, seed=10 + i, bev=1.4)
    for sx in (x - 11.8, x + 11.8):
        stitches(sx, -128, -6.5, 3.6, -4.15 - 0.4, ang=28 if sx < x else -28)
    if i >= 3 - LOST:  # lost pick: compressed, darker, glossier imprint of its outline left in the leather
        pts = [(x, -10), (x, 18), (x + 0.2, 22), (x + 1.4, 25), (x + 3.0, 26.2)]
        floor = -2.0 - undulation(x, 8, 1) + 0.3   # groove ~0.3 mm deep, following the leather
        im = flat_tool('imprint%d' % i, pts, 1.9, 8.0, floor - 4.0, mat='brass')
        im.data.materials.clear(); im.data.materials.append(LE3)
        im.modifiers.clear()
        md = roll.modifiers.new('imp', 'BOOLEAN'); md.operation = 'DIFFERENCE'; md.object = im; md.solver = 'FAST'
        bpy.context.view_layer.objects.active = roll; roll.modifiers.move(len(roll.modifiers) - 1, 0)
        bpy.ops.object.modifier_apply(modifier='imp'); bpy.data.objects.remove(im, do_unlink=True)
        if LE3.name not in roll.data.materials: roll.data.materials.append(LE3)
        mi = list(roll.data.materials).index(LE3)
        for pg in roll.data.polygons:
            c = pg.center
            if abs(c.x - x - 1.5) < 4 and -11 < c.z < 28 and -0.5 > c.y > -2.0 - undulation(c.x, c.z, 1) + 0.08: pg.material_index = mi
        continue
    if i == 0:   # hook: short upturned tip
        pts = [(x, -60), (x, 16), (x + 0.3, 21), (x + 1.5, 24.5), (x + 3.4, 26)]
    else:        # rake: smooth humps
        pts = [(x, -60), (x, 12), (x + 0.9, 16), (x - 0.3, 20), (x + 0.9, 24), (x, 28)]
    t = flat_tool('pick%d' % i, pts, 1.5, 0.6, -2.42)
    t.data.materials.clear(); t.data.materials.append(PICK)
    t.rotation_euler = (0, math.radians((-1.2, 0.8)[i]), 0)

# watchmaker's loupe standing lens-up on the leather: conical ribbed body, turned brass ring, glass
def revolve_y(name, loop, seg=128):
    """Closed (r, h) outline revolved around the Y axis (h along -Y, i.e. up off the table)."""
    bm = bmesh.new(); rings = []
    for r, h in loop:
        rings.append([bm.verts.new((r * math.cos(2 * math.pi * k / seg), -h, r * math.sin(2 * math.pi * k / seg))) for k in range(seg)])
    for a, c in zip(rings, rings[1:] + rings[:1]):
        for k in range(seg): bm.faces.new((a[k], a[(k + 1) % seg], c[(k + 1) % seg], c[k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); smooth(o); return o

body_loop = [(13.0, 0.0), (15.2, 0.0), (15.4, 0.5)]
for k in range(9):  # grip ribs on the cone
    h0 = 1.2 + k * 1.25; r0 = 15.4 - k * 0.33
    body_loop += [(r0, h0), (r0 + 0.35, h0 + 0.35), (r0 + 0.35, h0 + 0.8), (r0 - 0.05, h0 + 1.1)]
body_loop += [(12.3, 13.0), (12.2, 14.5), (10.8, 14.6), (10.6, 1.0), (12.4, 0.6)]
LX, LZ = 44.0, -9.0
body = revolve_y('loupe', body_loop); put(body, RUB)
ring = revolve_y('ring', [(10.2, 14.2), (12.4, 14.2), (12.5, 16.4), (12.1, 16.9), (10.3, 16.9), (10.0, 16.2)]); put(ring, BRASS)
lens = revolve_y('lens', [(0.0, 15.1), (10.3, 15.1), (10.3, 15.7), (9.6, 16.5), (5.0, 16.95), (0.0, 17.05)]); put(lens, GL)
for o in (body, ring, lens):
    o.matrix_world = Matrix.Translation((LX, -2.0, LZ)) @ Matrix.Rotation(math.radians(-6), 4, 'Z') @ Matrix.Rotation(math.radians(4), 4, 'X')

# ---------------------------------------------------------------- light + camera
world_hdri(float(arg('--world', '0.06')), sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 0, CZ)
kx, ky, kz, ks, ke = [float(v) for v in arg('--key', '-230,-110,190,70,260000').split(',')]
area_light('key', (kx, ky, kz), AIM, ks, ke, (1.0, 0.84, 0.66))           # low warm key: rakes the grain
area_light('fill', (200, -260, -60), AIM, 160, float(arg('--fill', '45000')), (0.92, 0.95, 1.0))
area_light('rim', (120, -60, 230), AIM, 60, float(arg('--rim', '60000')), (1.0, 0.93, 0.85))
cd = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cd); scene.collection.objects.link(cam); scene.camera = cam
cd.lens = 120; cd.sensor_fit = 'HORIZONTAL'; cd.sensor_width = 36; cd.dof.use_dof = False; cd.clip_start = 1
cam.location = (0, -400, CZ + 7); cam.rotation_euler = (Vector((0, 0, CZ)) - cam.location).to_track_quat('-Z', 'Z').to_euler()
# product sheen on the steel: strip softbox near the mirror direction, shifted so its edge grades across the picks
mirror_softbox('sheen', (0, 0, CZ), cam, dist=380, size=float(arg('--ss', '90')), size_y=float(arg('--ssy', '240')),
               energy=float(arg('--sheen', '60000')), shift=(float(arg('--sx', '4')), 0, float(arg('--sz', '8'))))
render_setup(OUT, RES, SAMPLES, exposure=float(arg('--exp', '0.0')))
if arg("--norender", "0") == "1":
    for o in bpy.data.objects:
        if o.type == "MESH" and not o.name.startswith("Sphere"): print("OBJ", o.name, len(o.data.polygons), [m.name for m in o.data.materials], o.dimensions[:])
    raise SystemExit
bpy.ops.render.render(write_still=True); print('WROTE', scene.render.filepath)
