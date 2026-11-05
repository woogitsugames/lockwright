# Lockwright marketing renders & animations: leather tool roll on doormat (R02) and address envelope (R03).
# Imports art/blender/lw_common.py without modifying art/blender/*.py.
# Example single-command runs:
#   blender -b -P art/blender/marketing/tray_anim.py -- --preset R02 --out art/marketing/frames/R02 --res 2160x3840 --samples 128
#   blender -b -P art/blender/marketing/tray_anim.py -- --preset R03 --out art/marketing/frames/R03 --res 2160x3840 --samples 128
import bpy
import bmesh
import math
import sys
import os
import random

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gpu_common import (
    ART_BLENDER_DIR, setup_gpu_cycles, ease_out_cubic, ease_in_out_cubic,
    clamp01, remap, ensure_under_10mb
)
from lw_common import *
from lw_common import _noise, _mix, _maprange, _edge_mask, _cavity_mask
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default

PRESET = arg('--preset', '') or (arg('--shot', '') if arg('--shot', '').startswith('R') else '')
OUT = arg('--out', 'art/marketing/previews/tray_test.png')
RES = [int(v) for v in arg('--res', '540x960').split('x')]
SAMPLES = int(arg('--samples', '64'))
STILL_ONLY = (arg('--still', '0') == '1') or ('--frame' in argv) or OUT.lower().endswith('.png')
STILL_FRAME = int(arg('--still_frame', arg('--frame', '-1')))
FRAME_START = int(arg('--frame_start', '1'))
FRAME_END = int(arg('--frame_end', '-1'))
BIT_DEPTH = arg('--bit_depth', '16')

PRESETS = {
    'R02': {'anim': 'unroll',   'lost': 0, 'frames': 75, 'still_frame': 50},
    'R03': {'anim': 'envelope', 'lost': 0, 'frames': 60, 'still_frame': 40},
}
cfg = PRESETS.get(PRESET, {'anim': 'unroll', 'lost': 0, 'frames': 75, 'still_frame': 50})
ANIM = arg('--anim', cfg['anim'])
LOST = int(arg('--lost', str(cfg['lost'])))
FRAMES = int(arg('--frames', str(cfg['frames'])))
if STILL_FRAME < 1:
    STILL_FRAME = cfg['still_frame']

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
FONTS = os.path.join(ROOT, 'mockups', 'fonts')

# ---------------------------------------------------------------- materials
def leather(name, color, rough=0.55, grain=1.0, wear=0.5, seed=0.0, burnish=0.0):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links
    b = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord'); P = tc.outputs['Object']
    if seed:
        mp = nt.nodes.new('ShaderNodeMapping'); mp.inputs['Location'].default_value = (seed * 13.1, seed * 3.7, seed * 7.9)
        l.new(P, mp.inputs['Vector']); P = mp.outputs['Vector']
    wp = nt.nodes.new('ShaderNodeTexNoise'); wp.inputs['Scale'].default_value = 0.6; wp.inputs['Detail'].default_value = 3
    l.new(P, wp.inputs['Vector'])
    wv = nt.nodes.new('ShaderNodeVectorMath'); wv.operation = 'MULTIPLY_ADD'; l.new(wp.outputs['Color'], wv.inputs[0])
    wv.inputs[1].default_value = (0.8, 0.8, 0.8); l.new(P, wv.inputs[2])
    vo = nt.nodes.new('ShaderNodeTexVoronoi'); vo.feature = 'SMOOTH_F1'; vo.inputs['Scale'].default_value = 1.35 * grain
    vo.inputs['Smoothness'].default_value = 0.6; vo.inputs['Randomness'].default_value = 1.0; l.new(wv.outputs[0], vo.inputs['Vector'])
    cell = _maprange(nt, vo.outputs['Distance'], 0.0, 0.55)
    cn = _noise(nt, P, 0.35, detail=8, rough=0.62, dist=0.6)
    sub = nt.nodes.new('ShaderNodeMath'); sub.operation = 'SUBTRACT'; l.new(cn, sub.inputs[0]); sub.inputs[1].default_value = 0.5
    ab = nt.nodes.new('ShaderNodeMath'); ab.operation = 'ABSOLUTE'; l.new(sub.outputs[0], ab.inputs[0])
    crease = _maprange(nt, ab.outputs[0], 0.012, 0.0)
    cgate = _maprange(nt, _noise(nt, P, 0.12, detail=2), 0.45, 0.65)
    crease = _mix(nt, 0.0, crease, cgate, dtype='FLOAT')
    mot = _noise(nt, P, 0.18, detail=6, rough=0.6)
    col = _mix(nt, (*[c * 0.72 for c in color], 1), (*[min(1, c * 1.18) for c in color], 1), _maprange(nt, mot, 0.3, 0.7))
    hp = _maprange(nt, _noise(nt, P, 0.05, detail=3), 0.5, 0.75, 0.0, 0.55)
    col = _mix(nt, col, (*[c * 0.55 for c in color], 1), hp)
    col = _mix(nt, col, (*[c * 0.6 for c in color], 1), _maprange(nt, cell, 0.5, 1.0, 0.0, 0.5))
    col = _mix(nt, col, (*[c * 0.62 for c in color], 1), crease)
    em = _edge_mask(nt, 1.2, 0.55, 0.97)
    if burnish:
        bm_ = _maprange(nt, em, 0.2, 0.8, 0.0, burnish)
        col = _mix(nt, col, (*[c * 0.4 for c in color], 1), bm_)
    if wear:
        wm = _maprange(nt, _mix(nt, 0.0, em, _noise(nt, P, 1.5, detail=5), dtype='FLOAT'), 0.15, 0.45, 0.0, wear)
        col = _mix(nt, col, (*[min(1, c * 1.55) for c in color], 1), wm)
    gm = _maprange(nt, _cavity_mask(nt, 2.5, 0.3, 0.95), 0, 1, 0, 0.7)
    col = _mix(nt, col, (0.03, 0.017, 0.009, 1), gm)
    l.new(col, b.inputs['Base Color'])
    r = _maprange(nt, mot, 0.3, 0.7, rough - 0.08, rough + 0.08)
    r = _mix(nt, r, rough - 0.2 - burnish * 0.1, hp, dtype='FLOAT')
    r = _mix(nt, r, min(1, rough + 0.2), crease, dtype='FLOAT')
    l.new(r, b.inputs['Roughness'])
    b.inputs['Sheen Weight'].default_value = 0.35; b.inputs['Sheen Roughness'].default_value = 0.45
    b.inputs['Specular IOR Level'].default_value = 0.45
    h = _mix(nt, cell, 1.0, crease, dtype='FLOAT')
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.6 * grain; bp.inputs['Distance'].default_value = 0.06
    l.new(h, bp.inputs['Height'])
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.5; l.new(bv.outputs['Normal'], bp.inputs['Normal'])
    l.new(bp.outputs['Normal'], b.inputs['Normal'])
    return m

def thread_mat():
    m = bpy.data.materials.new('linen'); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord')
    tw = _noise(nt, tc.outputs['Object'], 6.0, detail=4, stretch=(1, 1, 0.2))
    nt.links.new(_mix(nt, (0.40, 0.30, 0.18, 1), (0.62, 0.50, 0.32, 1), tw), b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.45; b.inputs['Sheen Weight'].default_value = 0.5
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 0.4; nt.links.new(tw, bp.inputs['Height']); nt.links.new(bp.outputs['Normal'], b.inputs['Normal'])
    return m

def glass_mat():
    m = bpy.data.materials.new('glass'); m.use_nodes = True; nt = m.node_tree; l = nt.links
    out = nt.nodes['Material Output']; g = nt.nodes['Principled BSDF']
    g.inputs['Transmission Weight'].default_value = 1.0; g.inputs['Roughness'].default_value = 0.02; g.inputs['IOR'].default_value = 1.52
    g.inputs['Base Color'].default_value = (0.97, 0.99, 0.98, 1)
    tr = nt.nodes.new('ShaderNodeBsdfTransparent'); lp = nt.nodes.new('ShaderNodeLightPath')
    mx = nt.nodes.new('ShaderNodeMixShader'); l.new(lp.outputs['Is Shadow Ray'], mx.inputs[0])
    l.new(g.outputs[0], mx.inputs[1]); l.new(tr.outputs[0], mx.inputs[2]); l.new(mx.outputs[0], out.inputs['Surface'])
    return m

def coir_mat():
    m = bpy.data.materials.new('coir_mat'); m.use_nodes = True; nt = m.node_tree; l = nt.links; b = nt.nodes['Principled BSDF']
    tc = nt.nodes.new('ShaderNodeTexCoord'); P = tc.outputs['Object']
    wv = nt.nodes.new('ShaderNodeTexWave'); wv.wave_type = 'BANDS'; wv.bands_direction = 'DIAGONAL'
    wv.inputs['Scale'].default_value = 0.35; wv.inputs['Distortion'].default_value = 2.2; wv.inputs['Detail'].default_value = 6.0
    l.new(P, wv.inputs['Vector'])
    n1 = _noise(nt, P, 0.55, detail=10, rough=0.82, stretch=(1.2, 1.0, 0.35))
    n2 = _noise(nt, P, 3.6, detail=8, rough=0.85)
    fib = _mix(nt, _mix(nt, n1, n2, 0.55, dtype='FLOAT'), wv.outputs['Fac'], 0.45, dtype='FLOAT')
    col = _mix(nt, (0.14, 0.082, 0.038, 1), (0.44, 0.29, 0.15, 1), fib)
    l.new(col, b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.92; b.inputs['Sheen Weight'].default_value = 0.45
    bp = nt.nodes.new('ShaderNodeBump'); bp.inputs['Strength'].default_value = 1.0; bp.inputs['Distance'].default_value = 0.45
    l.new(fib, bp.inputs['Height']); l.new(bp.outputs['Normal'], b.inputs['Normal'])
    return m

LE = leather('leather', (0.30, 0.155, 0.07), 0.55, seed=0.0, wear=0.4)
LE2 = leather('pocket', (0.25, 0.125, 0.055), 0.5, seed=3.0, wear=0.5, burnish=1.0)
LE3 = leather('imprint', (0.2, 0.1, 0.045), 0.3, grain=0.35, seed=5.0, wear=0.0)
TH = thread_mat(); GL = glass_mat(); COIR = coir_mat()
MAT_RUB = dark_mat('mat_rub', (0.025, 0.024, 0.022), 0.78)
TERRAZZO = dark_mat('terrazzo_bg', (0.18, 0.17, 0.155), 0.45)

PICK = metal('pick_steel', (0.64, 0.64, 0.65), 0.20, aniso=0.6, marks='grind', marks_axis=(0, 0, 1), marks_scale=1.4,
             wear=0.6, wear_col=(0.8, 0.8, 0.8), grime=0.35, smudge=0.6, bevel_r=0.08)
WRENCH_M = metal('wrench_steel', (0.52, 0.53, 0.54), 0.24, aniso=0.5, marks='grind', marks_axis=(0, 0, 1), marks_scale=1.2,
                 wear=0.5, grime=0.4, bevel_r=0.08)
BRASS = metal('ring_brass', (0.80, 0.58, 0.28), 0.24, marks='turn', marks_axis=(0, 1, 0), wear=0.7, wear_col=(0.95, 0.78, 0.48),
              grime=0.6, patina=0.3)
RUB = bpy.data.materials.new('loupe_body'); RUB.use_nodes = True
_rb = RUB.node_tree.nodes['Principled BSDF']; _rb.inputs['Base Color'].default_value = (0.025, 0.024, 0.023, 1)
_rb.inputs['Roughness'].default_value = 0.42

# ---------------------------------------------------------------- Doormat & Terrazzo landing under the roll
doormat_rub = box('doormat_rubber', -220, 220, 1.5, 6.0, -280, 280); put(doormat_rub, MAT_RUB, 1.5, 2)
doormat_coir = box('doormat_coir', -204, 204, 0.8, 2.0, -264, 264); put(doormat_coir, COIR, 0.8, 2)
terrazzo_fl = box('terrazzo_floor', -450, 450, 5.5, 10.0, -550, 550); put(terrazzo_fl, TERRAZZO)

# ---------------------------------------------------------------- Tool roll geometry
def undulation(x, z, seed):
    random.seed(seed); ph = [random.uniform(0, 6.28) for _ in range(3)]
    return 0.25 * math.sin(x * 0.11 + ph[0]) * math.sin(z * 0.07 + ph[1]) + 0.15 * math.sin(x * 0.23 + z * 0.19 + ph[2])

def leather_slab(name, x0, x1, z0, z1, y_face, thick, mat, puff=0.0, cuts=40, seed=0, bev=0.9, shape=None):
    o = box(name, x0, x1, y_face, y_face + thick, z0, z1)
    md = o.modifiers.new('sub', 'SUBSURF'); md.subdivision_type = 'SIMPLE'; md.levels = md.render_levels = 0
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.subdivide(number_cuts=cuts); bpy.ops.object.mode_set(mode='OBJECT')
    o.modifiers.clear()
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2; hx, hz = (x1 - x0) / 2, (z1 - z0) / 2
    for v in o.data.vertices:
        if v.co.y < y_face + thick * 0.5:
            u = (v.co.x - cx) / hx; w = (v.co.z - cz) / hz
            d = undulation(v.co.x, v.co.z, seed)
            if puff:
                d += puff * max(0.0, 1 - u * u) * max(0.0, 1 - max(0.0, w) ** 6)
            if shape:
                d += shape(v.co.x, v.co.z)
            v.co.y -= d
    put(o, mat, bev, 4, harden=False)
    return o

def stitches(xs, z0, z1, pitch, y, ang=28.0):
    n = int((z1 - z0) / pitch)
    for k in range(n):
        z = z0 + k * pitch + pitch * 0.5
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=1.0, location=(xs, y(z) if callable(y) else y, z))
        s = bpy.context.object; s.scale = (0.26, 0.2, pitch * 0.33); s.rotation_euler = (0, math.radians(ang), 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True); smooth(s); link(s, TH)

def stitches_h(zs, x0, x1, pitch, y, ang=28.0):
    n = int((x1 - x0) / pitch)
    for k in range(n):
        x = x0 + k * pitch + pitch * 0.5
        bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=6, radius=1.0, location=(x, y, zs))
        s = bpy.context.object; s.scale = (pitch * 0.33, 0.2, 0.26); s.rotation_euler = (0, math.radians(ang), 0)
        bpy.ops.object.transform_apply(scale=True, rotation=True); smooth(s); link(s, TH)

roll = leather_slab('roll', -105, 105, -135, 135, -2.0, 3.0, LE, cuts=50, seed=1)
fold_flap = leather_slab('fold', -105, 105, 48, 135, -3.6, 1.7, LE, cuts=36, seed=2, bev=0.6)
stitches_h(50.0, -98, 98, 3.8, -3.62)

# Spare tension wrench pocket on the far left (HUD.md §4: napinacz, 3 wytrychy, lupa)
wr_pts = [(-80, -75), (-80, 18), (-78, 22), (-70, 24)]
wr_tool = flat_tool('spare_wrench', wr_pts, 2.2, 0.8, -2.45, tip='flat')
wr_tool.data.materials.clear(); wr_tool.data.materials.append(WRENCH_M)
leather_slab('flap_wrench', -92, -68, -130, -4, -4.0, 2.0, LE2, puff=0.8, cuts=36, seed=9, bev=1.2)
for sx in (-89.8, -70.2):
    stitches(sx, -128, -6.5, 3.8, -4.5, ang=28 if sx < -80 else -28)

POCKET_X = [-46, -14, 18]
def pick_tip(i, x):
    if i == 0:
        return [(x, 16), (x + 0.3, 21), (x + 1.5, 24.5), (x + 3.4, 26)]
    if i == 1:
        return [(x, 12), (x + 0.9, 16), (x - 0.3, 20), (x + 0.9, 24), (x, 28)]
    return [(x, 20), (x + 0.4, 22.5), (x + 1.3, 24.6), (x + 0.6, 26.6), (x, 28.5)]

for i, x in enumerate(POCKET_X):
    full = i < 3 - LOST
    def pocket_shape(px, pz, x=x, full=full):
        a = abs(px - x)
        side = 0.35 * math.exp(-((a - 11.8) / 1.0) ** 2)
        if full:
            across = 1.0 / (1.0 + math.exp((a - 4.6) / 0.55))
            along = 1.0 / (1.0 + math.exp((pz + 12.0) / 1.4))
            return 1.5 * across * along - side
        sag = -0.7 * math.exp(-((pz + 6.0) / 7.0) ** 2) * max(0.0, 1 - (a / 12.0) ** 2)
        fold_s = -0.45 * math.exp(-((pz + 34.0) / 2.2) ** 2) * max(0.0, 1 - (a / 13.0) ** 2)
        return sag + fold_s - side
    leather_slab('flap%d' % i, x - 14, x + 14, -130, -4, -4.0, 2.0, LE2, puff=0.9 if full else 0.25, cuts=40, seed=10 + i, bev=1.4, shape=pocket_shape)
    for sx in (x - 11.8, x + 11.8):
        def surf(z, sx=sx, x=x, i=i, full=full):
            u = (sx - x) / 14.0; w = (z + 67.0) / 63.0
            d = undulation(sx, z, 10 + i) + (0.9 if full else 0.25) * max(0.0, 1 - u * u) * max(0.0, 1 - max(0.0, w) ** 6) + pocket_shape(sx, z)
            return -4.0 - d - 0.08
        stitches(sx, -128, -6.5, 3.8, surf, ang=28 if sx < x else -28)
    if full:
        tip = pick_tip(i, x)
        pts = [(x, z) for z in range(-60, int(tip[0][1]), 3)] + tip
        t = flat_tool('pick%d' % i, pts, 1.5, 0.6, -2.42)
        t.data.materials.clear(); t.data.materials.append(PICK)
        bm = bmesh.new(); bm.from_mesh(t.data)
        bmesh.ops.triangulate(bm, faces=[f for f in bm.faces if len(f.verts) > 4], quad_method='BEAUTY', ngon_method='EAR_CLIP')
        bm.to_mesh(t.data); bm.free()
        t.modifiers['bev'].harden_normals = False
        t.rotation_euler = (0, math.radians((-1.2, 0.8, -0.5)[i]), 0)

# Watchmaker's loupe
def revolve_y(name, loop, seg=96):
    bm = bmesh.new(); rings = []
    for r, h in loop:
        rings.append([bm.verts.new((r * math.cos(2 * math.pi * k / seg), -h, r * math.sin(2 * math.pi * k / seg))) for k in range(seg)])
    for a, c in zip(rings, rings[1:] + rings[:1]):
        for k in range(seg):
            bm.faces.new((a[k], a[(k + 1) % seg], c[(k + 1) % seg], c[k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o); smooth(o); return o

body_loop = [(13.0, 0.0), (15.2, 0.0), (15.4, 0.5)]
for k in range(9):
    h0 = 1.2 + k * 1.25; r0 = 15.4 - k * 0.33
    body_loop += [(r0, h0), (r0 + 0.35, h0 + 0.35), (r0 + 0.35, h0 + 0.8), (r0 - 0.05, h0 + 1.1)]
body_loop += [(12.3, 13.0), (12.2, 14.5), (10.8, 14.6), (10.6, 1.0), (12.4, 0.6)]
LX, LZ = 54.0, -9.0
loupe_body = revolve_y('loupe', body_loop); put(loupe_body, RUB)
loupe_ring = revolve_y('ring', [(10.2, 14.2), (12.4, 14.2), (12.5, 16.4), (12.1, 16.9), (10.3, 16.9), (10.0, 16.2)]); put(loupe_ring, BRASS)
loupe_lens = revolve_y('lens', [(0.0, 15.1), (10.3, 15.1), (10.3, 15.7), (9.6, 16.5), (5.0, 16.95), (0.0, 17.05)]); put(loupe_lens, GL)

# ---------------------------------------------------------------- R03 Envelope with invented address "ul. ... 12/4"
env_objs = []
if ANIM == 'envelope':
    env_paper = bpy.data.materials.new('env_paper'); env_paper.use_nodes = True
    ep_b = env_paper.node_tree.nodes['Principled BSDF']
    ep_b.inputs['Base Color'].default_value = (0.84, 0.80, 0.72, 1)
    ep_b.inputs['Roughness'].default_value = 0.78
    ink_dark = dark_mat('ink_addr', (0.04, 0.04, 0.05), 0.65)
    ink_faint = dark_mat('ink_faint', (0.48, 0.46, 0.42), 0.75)
    stamp_ink = dark_mat('stamp_ink', (0.12, 0.16, 0.28), 0.70)

    env_pivot = bpy.data.objects.new('env_pivot', None)
    scene.collection.objects.link(env_pivot)
    env_pivot.location = (-8.0, -7.2, 8.0)
    env_pivot.rotation_euler = (0, math.radians(-8.5), 0)

    env_box = box('envelope_body', -72, 72, -0.4, 0.4, -48, 48)
    put(env_box, env_paper, 0.25, 2)
    env_box.parent = env_pivot

    # Subtle border line & postmark circle on the envelope
    stamp_b = box('stamp_box', 44, 62, -0.5, -0.35, 18, 40)
    put(stamp_b, stamp_ink, 0.05, 1)
    stamp_b.parent = env_pivot

    # Printed address: "ul. ······ 12/4" (street blurred/obscured, flat number "12/4" sharp and clear, no postal code)
    f_path = os.path.join(FONTS, 'BonaNova-Bold.ttf')
    def add_env_text(name, body, size, x_off, z_off, mat_t):
        cu = bpy.data.curves.new(name, 'FONT')
        cu.body = body
        cu.size = size
        cu.extrude = 0.08
        if os.path.exists(f_path):
            cu.font = bpy.data.fonts.load(f_path)
        cu.align_x = 'LEFT'
        cu.align_y = 'CENTER'
        tobj = bpy.data.objects.new(name, cu)
        bpy.context.collection.objects.link(tobj)
        tobj.data.materials.append(mat_t)
        tobj.rotation_euler = (math.radians(90), 0, 0)
        tobj.location = (x_off, -0.48, z_off)
        tobj.parent = env_pivot
        return tobj

    add_env_text('txt_name', 'H. Kowalska', 6.5, -36, 6, ink_faint)
    add_env_text('txt_ul', 'ul. ————', 7.2, -36, -8, ink_faint)
    add_env_text('txt_num', '12/4', 11.5, 12, -8, ink_dark)

# Store rest coordinates of fold_flap for unroll animation
fold_rest_verts = [v.co.copy() for v in fold_flap.data.vertices]

# ---------------------------------------------------------------- Lights & Camera
world_hdri(0.06, sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 0, 0)
area_light('key', (-230, -140, 190), AIM, 80, 260000, (1.0, 0.84, 0.66))
area_light('fill', (200, -260, -60), AIM, 160, 45000, (0.92, 0.95, 1.0))
area_light('rim', (120, -80, 230), AIM, 60, 60000, (1.0, 0.93, 0.85))

cd = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cd); scene.collection.objects.link(cam); scene.camera = cam
cd.sensor_fit = 'HORIZONTAL'; cd.sensor_width = 36; cd.clip_start = 1
mirror_softbox('sheen', (0, 0, 0), cam, dist=380, size=90, size_y=240, energy=55000, shift=(4, 0, 8))

def update_tray_frame(f):
    t_norm = (f - 1) / max(1, FRAMES - 1)
    if ANIM == 'unroll':  # R02: top-down (pitch 85 deg), 50 mm, unroll in 30 frames on doormat
        cd.lens = 50.0
        cd.dof.use_dof = False
        cam.location = (0, -326, -28)
        cam.rotation_euler = (Vector((0, 0, 0)) - cam.location).to_track_quat('-Z', 'Z').to_euler()

        # Unroll animation over first 30 frames: top flap unfolds from curled over the tools to flat
        u_unroll = ease_out_cubic(remap(f, 1, 30))
        curl_angle = math.radians(155.0 * (1.0 - u_unroll))
        piv_z = 48.0
        for idx_v, v in enumerate(fold_flap.data.vertices):
            co0 = fold_rest_verts[idx_v]
            dz = max(0.0, co0.z - piv_z)
            if curl_angle > 1e-3 and dz > 0:
                r_curl = 28.0 + 40.0 * u_unroll
                theta = min(math.pi * 1.15, (dz / 85.0) * curl_angle)
                v.co.z = piv_z + dz * math.cos(theta) - (r_curl * (1 - math.cos(theta))) * 0.4
                v.co.y = co0.y - r_curl * math.sin(theta) * (1.0 - u_unroll)
            else:
                v.co = co0.copy()
        fold_flap.data.update()

        # Loupe settles onto the leather as it unrolls
        u_loupe = ease_out_cubic(remap(f, 8, 32))
        l_rot = -6.0 + 18.0 * (1.0 - u_loupe)
        for o in (loupe_body, loupe_ring, loupe_lens):
            o.matrix_world = (
                Matrix.Translation((LX + 6.0 * (1.0 - u_loupe), -2.0, LZ))
                @ Matrix.Rotation(math.radians(l_rot), 4, 'Z')
                @ Matrix.Rotation(math.radians(4), 4, 'X')
            )
        return ('unroll', round(u_unroll, 4), round(u_loupe, 4))

    elif ANIM == 'envelope':  # R03: top-down, 85 mm, shallow DOF (f/2.8), slow push-in on address "ul. ... 12/4"
        cd.lens = 85.0
        u_push = ease_in_out_cubic(t_norm)
        dist = 275.0 - 28.0 * u_push
        target = Vector((-6.0, -5.8, 2.0))
        cam.location = target + Vector((0.0, -dist * math.sin(math.radians(85.0)), -dist * math.cos(math.radians(85.0))))
        cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Z').to_euler()
        cd.dof.use_dof = True
        cd.dof.focus_distance = (target - cam.location).length
        cd.dof.aperture_fstop = 2.8
        for o in (loupe_body, loupe_ring, loupe_lens):
            o.matrix_world = Matrix.Translation((LX, -2.0, LZ)) @ Matrix.Rotation(math.radians(-6), 4, 'Z') @ Matrix.Rotation(math.radians(4), 4, 'X')
        return ('envelope', round(u_push, 4))


import shutil
use_dof_flag = (ANIM == 'envelope')
backend, gpu_name = setup_gpu_cycles(
    scene, samples=SAMPLES, denoiser='OPTIX', use_dof=use_dof_flag, persistent=True, color_depth=BIT_DEPTH
)
scene.cycles.max_bounces = 5 if not (STILL_ONLY or FRAMES == 1) else 8
scene.render.resolution_x, scene.render.resolution_y = RES
scene.render.film_transparent = False
scene.view_settings.view_transform = 'AgX'
scene.view_settings.look = 'AgX - Medium High Contrast'

print(f"[tray_anim] Preset={PRESET or 'custom'} Anim={ANIM} Res={RES[0]}x{RES[1]} Samples={SAMPLES} GPU={gpu_name} ({backend})")

if STILL_ONLY or FRAMES == 1:
    update_tray_frame(STILL_FRAME)
    out_path = os.path.abspath(OUT)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    scene.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    if 'stills' in out_path.replace('\\', '/') or 'previews' in out_path.replace('\\', '/'):
        ensure_under_10mb(out_path)
    print('WROTE STILL', out_path)
else:
    out_dir = os.path.abspath(OUT)
    if out_dir.lower().endswith('.png'):
        out_dir = os.path.splitext(out_dir)[0]
    os.makedirs(out_dir, exist_ok=True)
    f_start = max(1, FRAME_START)
    f_end = FRAMES if FRAME_END < 1 else min(FRAMES, FRAME_END)
    prev_sig = None
    prev_path = None
    for f in range(f_start, f_end + 1):
        frame_path = os.path.join(out_dir, f"frame_{f:04d}.png")
        sig = update_tray_frame(f)
        if prev_sig is not None and sig == prev_sig and prev_path and os.path.isfile(prev_path):
            shutil.copy2(prev_path, frame_path)
            print(f"COPIED STATIC HOLD FRAME {f}/{FRAMES}: {frame_path}")
        else:
            scene.render.filepath = frame_path
            bpy.ops.render.render(write_still=True)
            print(f"WROTE FRAME {f}/{FRAMES}: {frame_path}")
            prev_sig = sig
            prev_path = frame_path
