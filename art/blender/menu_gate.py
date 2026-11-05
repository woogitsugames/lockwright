# Lockwright — MAIN MENU as a photographed object: the locksmith's corner of a tenement gate. 1 unit = 1 mm.
#   blender -b -P art/blender/menu_gate.py -- --out art/renders/menu/menu_portrait.png --res 1080x2400 --samples 160
#   ... --orient landscape --res 2400x1080           (separate landscape board: title left, menu right)
#   ... --pressed 2 --crop-row 2                      (row 2 pushed 1 mm into the felt, render only that row)
# Black ribbed felt letter board in an aluminium frame on the stairwell wall (oil-paint lamperia under lime paint,
# painted divider line), white push-in plastic letters (Archivo, OFL; every letter a separate mesh: uneven, one crooked,
# two yellowed). Under the board a beech rail with brass cup hooks, two stamped key tags and an invented key.
# Warm stairwell bulb from the upper left, faint cool window from the right, dust on top faces.
# Writes <out>_hits.json (or --hits path): per menu item the letters' rect and a full-width hit band, in px and dp.
import bpy, math, os, sys, json, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_common import *
from env_common import _bev, _new, _math, _bump
from lw_common import _noise, _mix, _maprange, _edge_mask, _cavity_mask
from mathutils import Vector, Matrix

arg = cli()
OUT = arg('--out', 'art/renders/menu/test_menu.png'); RES = [int(v) for v in arg('--res', '270x600').split('x')]
SAMPLES = int(arg('--samples', '16')); ORIENT = arg('--orient', 'portrait')
PRESSED = int(arg('--pressed', '-1')); CROP_ROW = int(arg('--crop-row', '-1'))
HITS = arg('--hits', os.path.splitext(OUT)[0] + '_hits.json')
rng = random.Random(5)
FONT = bpy.data.fonts.load(os.path.join(ROOT, 'mockups', 'ui-directions', 'fonts', 'Archivo-wdth-wght.ttf'))
MONO = bpy.data.fonts.load(os.path.join(ROOT, 'mockups', 'ui-directions', 'fonts', 'ChivoMono-wght.ttf'))

# ---------------------------------------------------------------- materials
def add_top_dust(m, amt=0.35, col=(0.50, 0.48, 0.44)):
    """Dust settles on upward faces: mix a pale grey into the base colour by normal.z and a patchy noise."""
    nt = m.node_tree; b = nt.nodes['Principled BSDF']
    src = next((lk.from_socket for lk in nt.links if lk.to_socket == b.inputs['Base Color']), None)
    if src is None: src = b.inputs['Base Color'].default_value
    g = nt.nodes.new('ShaderNodeNewGeometry'); sz = nt.nodes.new('ShaderNodeSeparateXYZ'); nt.links.new(g.outputs['Normal'], sz.inputs[0])
    up = _maprange(nt, sz.outputs[2], 0.45, 0.95, 0.0, amt)
    P = nt.nodes.new('ShaderNodeTexCoord').outputs['Object']
    patch = _maprange(nt, _noise(nt, P, 0.15, detail=6, rough=0.7), 0.35, 0.75, 0.3, 1.0)
    nt.links.new(_mix(nt, src, (*col, 1), _math(nt, 'MULTIPLY', up, patch)), b.inputs['Base Color'])
    return m

def felt_mat():
    """Black needle felt: fibre mottling, sheen, a few light lint specks and a little grey dust."""
    m, nt, l, b, P = _new('felt')
    fib = _noise(nt, P, 3.0, detail=10, rough=0.75)
    mot = _noise(nt, P, 0.04, detail=4)
    col = _mix(nt, (0.010, 0.010, 0.010, 1), (0.030, 0.029, 0.027, 1), _maprange(nt, fib, 0.35, 0.75))
    col = _mix(nt, col, (0.006, 0.006, 0.006, 1), _maprange(nt, mot, 0.4, 0.65, 0, 0.5))
    lint = _maprange(nt, _noise(nt, P, 0.9, detail=3, rough=0.4, dist=0.6), 0.74, 0.78)
    col = _mix(nt, col, (0.28, 0.27, 0.25, 1), _math(nt, 'MULTIPLY', lint, 0.55))
    dust = _maprange(nt, _noise(nt, P, 0.012, detail=5), 0.55, 0.8, 0, 0.18)
    col = _mix(nt, col, (0.20, 0.19, 0.18, 1), dust)
    l.new(col, b.inputs['Base Color']); b.inputs['Roughness'].default_value = 0.95
    b.inputs['Sheen Weight'].default_value = 0.8; b.inputs['Sheen Roughness'].default_value = 0.45
    b.inputs['Sheen Tint'].default_value = (0.55, 0.55, 0.55, 1); b.inputs['Specular IOR Level'].default_value = 0.25
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.6
    l.new(_bump(nt, _mix(nt, fib, _noise(nt, P, 8.0, detail=4), 0.5, dtype='FLOAT'), 0.35, 0.15, bv.outputs['Normal']), b.inputs['Normal'])
    return m

green = photo_mat('ph_wall_green', 'wall_oil_paint_green', scale=900, metallic=0.0, rough_mul=0.8, bump=0.25, grime=0.3,
                  base=(0.05, 0.11, 0.075), base_mix=0.35)
lime = photo_mat('ph_wall_lime', 'wall_lime_plaster', scale=900, metallic=0.0, bump=0.3, grime=0.2)
stripe = oil_paint('stripe', (0.20, 0.045, 0.03), rough=0.3, chips=0.3, scuffs=0.2, strokes='X', seed=2)
alu = add_top_dust(photo_mat('ph_alu', 'nickel_satin', scale=140, metallic=1.0, base=(0.66, 0.66, 0.64), base_mix=0.35, rough_add=0.08, wear=0.2, grime=0.6), 0.45)
felt = felt_mat()
letter_w = add_top_dust(plastic('letter_white', (0.80, 0.80, 0.77), rough=0.33, grime=0.35, sheen_scuffs=0.2), 0.4)
letter_y = add_top_dust(plastic('letter_old', (0.76, 0.72, 0.60), rough=0.38, grime=0.5, sheen_scuffs=0.2), 0.45)
beech = add_top_dust(photo_mat('ph_beech', 'bench_beech_top', scale=320, metallic=0.0, coat=0.2, bump=0.2, grime=0.4), 0.3)
brass = photo_mat('ph_brass', 'brass_patina_grease', scale=60, metallic=1.0, base=(0.70, 0.55, 0.32), base_mix=0.45, rough_add=0.1, wear=0.3, grime=0.6)
tag_alu = photo_mat('ph_tag_alu', 'nickel_satin', scale=50, metallic=1.0, base=(0.70, 0.70, 0.68), base_mix=0.3, rough_add=0.12, wear=0.4, grime=0.8)
ring_steel = photo_mat('ph_ring', 'steel_ground', scale=30, metallic=1.0, rough_add=0.05, grime=0.4)

# ---------------------------------------------------------------- layout
PITCH = 6.5                       # felt rib pitch; letter baselines sit in a groove
RIB_FACE, BACK, FRAME_Y = -12.0, -9.0, -21.0
FR = 22.0                         # frame width
if ORIENT == 'portrait':
    IW = 420.0; TOP = 2050.0; BX = 0.0
    TITLE = [('POGOTOWIE ZAMKOWE', 15.0, 24.0, 0), ('LOCKWRIGHT', 36.0, 62.0, 0)]      # text, cap, top (mm from inner top), x
    MENU_X, MENU_TOP, PRIM_BAND, BAND = 22.0, 132.0, 88.0, 66.0
    IH = MENU_TOP + PRIM_BAND + 5 * BAND + 22.0
else:
    IW = 900.0; TOP = 2000.0; BX = -190.0
    TITLE = [('POGOTOWIE ZAMKOWE', 15.0, 40.0, 0), ('LOCKWRIGHT', 40.0, 80.0, 0), ('CAŁĄ DOBĘ · BRAMA, PARTER', 13.0, 150.0, 0)]
    MENU_X, MENU_TOP, PRIM_BAND, BAND = 486.0, 22.0, 88.0, 75.0
    IH = MENU_TOP + PRIM_BAND + 5 * BAND + 22.0
X0 = BX - IW / 2; ZT = TOP - FR; ZB = ZT - IH
MENU = [('ZACZNIJ DYŻUR', 28.0), ('ZLECENIA', 25.0), ('WARSZTAT', 25.0), ('GABLOTA', 25.0), ('USTAWIENIA', 25.0), ('O GRZE', 25.0)]
IDS = ['start', 'jobs', 'workshop', 'showcase', 'settings', 'about']

# ---------------------------------------------------------------- wall: lamperia / divider / lime
DIV = 1560.0
bx('wall_green', -1600, 1600, 0, 60, 0, DIV, green)
bx('wall_stripe', -1600, 1600, -0.6, 60, DIV, DIV + 14, stripe)
bx('wall_lime', -1600, 1600, 0, 60, DIV + 14, 3200, lime)

# ---------------------------------------------------------------- board: backing, ribs, frame
bx('board_back', X0, X0 + IW, BACK, 0, ZB, ZT, felt)
rib = bx('rib', X0, X0 + IW, RIB_FACE, BACK, ZB + 1.0, ZB + 1.0 + PITCH - 2.0, felt)
_bev(rib, 0.9, 3, 30)
ar = rib.modifiers.new('arr', 'ARRAY'); ar.use_relative_offset = False; ar.use_constant_offset = True
ar.constant_offset_displace = (0, 0, PITCH); ar.count = int(IH / PITCH)
rib.modifiers.move(len(rib.modifiers) - 1, 0)
for nm, a in (('fr_t', (X0 - FR, X0 + IW + FR, ZT, ZT + FR)), ('fr_b', (X0 - FR, X0 + IW + FR, ZB - FR, ZB)),
              ('fr_l', (X0 - FR, X0, ZB, ZT)), ('fr_r', (X0 + IW, X0 + IW + FR, ZB, ZT))):
    bx(nm, a[0], a[1], FRAME_Y, 0, a[2], a[3], alu, bev=2.2, seg=3)
    bx(nm + '_lip', a[0] + (4 if nm != 'fr_r' else 0), a[1] - (4 if nm != 'fr_l' else 0), FRAME_Y - 1.2, FRAME_Y,
       a[2] + (4 if nm != 'fr_t' else 0), a[3] - (4 if nm != 'fr_b' else 0), alu, bev=0.6, seg=2)
for sx, sz in ((X0 - FR / 2, ZT + FR / 2), (X0 + IW + FR / 2, ZT + FR / 2), (X0 - FR / 2, ZB - FR / 2), (X0 + IW + FR / 2, ZB - FR / 2)):
    screw_head('screw', (sx, FRAME_Y - 1.2, sz), 4.2, 2.0, axis='Y', slot=True, kind='pan', mat=ring_steel, rot=rng.uniform(0, 180))

# ---------------------------------------------------------------- letters
def snap(z): return ZB + round((z - ZB) / PITCH) * PITCH + 1.0 - 0.6     # baseline: just above a groove bottom

measure = {}
def glyph(ch, size, mat, name):
    cu = bpy.data.curves.new(name, 'FONT'); cu.body = ch; cu.size = size; cu.font = FONT
    cu.extrude = 1.5; cu.bevel_depth = 0.35; cu.bevel_resolution = 2; cu.align_x = 'LEFT'; cu.align_y = 'BOTTOM_BASELINE'
    o = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(o); o.data.materials.append(mat); return o

def row(text, cap, top_mm, x_mm, tag, crooked=None, old=()):
    """Lay out one line of push-in letters; returns the list of letter objects. cap height ~ 0.7 em for Archivo."""
    size = cap / 0.7; base = snap(ZT - top_mm - cap)
    objs = []
    for i, ch in enumerate(text):
        if ch == ' ': objs.append(None); continue
        objs.append(glyph(ch, size, letter_y if i in old else letter_w, '%s_%d' % (tag, i)))
    bpy.context.view_layer.update()
    x = X0 + x_mm
    for i, (ch, o) in enumerate(zip(text, objs)):
        if o is None: x += 0.34 * size; continue
        bb = [Vector(v) for v in o.bound_box]; minx = min(v.x for v in bb); w = max(v.x for v in bb) - minx
        rz = math.radians(7.0 if crooked == i else rng.uniform(-0.9, 0.9))
        o.rotation_euler = (math.radians(90) + math.radians(rng.uniform(-0.6, 0.6)), rz, math.radians(rng.uniform(-1.2, 1.2)))
        o.location = (x - minx, RIB_FACE - 1.5 - rng.uniform(0.0, 0.35), base + rng.uniform(-0.45, 0.45) + (1.2 if crooked == i else 0))
        x += w + 0.1 * size + rng.uniform(-0.5, 0.5)
    return [o for o in objs if o], base

for text, cap, top, xm in TITLE:
    row(text, cap, top, 22.0 + xm, 'title', old=(2, 7) if text == 'LOCKWRIGHT' else ())

rows = []
top = MENU_TOP
for i, (text, cap) in enumerate(MENU):
    band = PRIM_BAND if i == 0 else BAND
    objs, base = row(text, cap, top + (band - cap) / 2, MENU_X, 'menu%d' % i, crooked=3 if text == 'GABLOTA' else None,
                     old=(4,) if text == 'USTAWIENIA' else ())
    rows.append({'id': IDS[i], 'label': text, 'objs': objs, 'band': (ZT - top - band, ZT - top), 'base': base, 'cap': cap})
    if text == 'ZLECENIA':   # small letters: two new jobs
        bpy.context.view_layer.update()
        xe = max((o.matrix_world @ Vector(v)).x for o in objs for v in o.bound_box) - X0
        row('2 NOWE', 13.0, top + (band - cap) / 2 + 12.0, xe + 26.0, 'nowe', old=(0,))
    top += band

if PRESSED >= 0:   # baked pressed state: the whole row sits 1 mm deeper in the felt
    for o in rows[PRESSED]['objs']: o.location.y += 1.0

# ---------------------------------------------------------------- hook rail, key tags, invented key
if ORIENT == 'portrait': RX, RZ, RW = 40.0, ZB - FR - 92.0, 300.0
else: RX, RZ, RW = BX + IW / 2 + FR + 210.0, 1640.0, 260.0
bx('rail', RX - RW / 2, RX + RW / 2, -18, 0, RZ - 26, RZ + 26, beech, bev=2.5)
for sx in (RX - RW / 2 + 16, RX + RW / 2 - 16):
    screw_head('rail_screw', (sx, -18.2, RZ), 3.6, 1.6, axis='Y', slot=True, kind='pan', mat=brass, rot=rng.uniform(0, 180))

def cup_hook(x, z):
    pts = [(x, -16, z - 8), (x, -24, z - 8), (x, -31, z - 6), (x, -34, z), (x, -32, z + 6), (x, -28, z + 8)]
    tube('hook', pts, 1.7, brass, res=4)
    c = cyl('collar', 3.0, 2.0, (x, -19, z - 8), axis='Y', verts=24); setmat(c, brass); _bev(c, 0.5, 2)
    return Vector((x, -33.5, z - 7.5))          # where a ring hangs (inside of the bend)

def split_ring(c, r=11.0, wire=1.1, yaw=25.0):
    bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=wire, major_segments=48, minor_segments=10,
                                     location=(c.x, c.y, c.z - r + 1.5), rotation=(math.radians(90), 0, math.radians(yaw)))
    o = bpy.context.object; setmat(o, ring_steel); smooth(o); return Vector((c.x, c.y, c.z - 2 * r + 3.0))

def key_tag(name, top, text, mat, w=34.0, h=70.0, rot=0.0):
    """Stamped key tag hanging from its hole: rounded rect in XZ, 1.6 mm thick, number punched 0.4 mm deep."""
    pts = [(u, v - h / 2 - 6) for u, v in rounded_rect(w, h, 7)]
    t = prism(name, [(top.x + u, top.z + v) for u, v in pts], top.y - 0.8, top.y + 0.8); setmat(t, mat)
    hole = cyl('hole', 3.2, 6, (top.x, top.y, top.z - 6.5), axis='Y', verts=24); cut(t, hole)
    cu = bpy.data.curves.new(name + '_n', 'FONT'); cu.body = text; cu.size = 15.0; cu.font = MONO; cu.extrude = 1.0
    cu.align_x = 'CENTER'; cu.align_y = 'CENTER'
    s = bpy.data.objects.new(name + '_n', cu); bpy.context.collection.objects.link(s)
    s.rotation_euler = (math.radians(90), 0, 0); s.location = (top.x, top.y - 0.8 - 0.6, top.z - 6 - h * 0.55)
    bpy.context.view_layer.objects.active = s; s.select_set(True); bpy.ops.object.convert(target='MESH'); s.select_set(False)
    cut(t, s); _bev(t, 0.35, 2, 30)
    t.rotation_mode = 'XYZ'
    M = Matrix.Translation(top) @ Matrix.Rotation(math.radians(rot), 4, 'Y') @ Matrix.Translation(-top)
    t.data.transform(M); return t

def invented_key(top, rot=0.0):
    """A flat key that matches no real profile: round-cornered bow with a hole, plain blade with three cuts."""
    bow = [(u, v - 16) for u, v in rounded_rect(30, 28, 9)]
    o = prism('key_bow', [(top.x + u, top.z + v) for u, v in bow], top.y - 1.1, top.y + 1.1); setmat(o, ring_steel)
    cut(o, cyl('kh', 4.0, 6, (top.x, top.y, top.z - 7), axis='Y', verts=24))
    blade = [(-4.5, -29), (4.5, -29), (4.5, -76), (1.0, -80), (-4.5, -80), (-4.5, -71), (-8.5, -68), (-8.5, -62), (-4.5, -60),
             (-4.5, -52), (-9, -49), (-9, -44), (-4.5, -41)]
    k = prism('key_blade', [(top.x + u, top.z + v) for u, v in blade], top.y - 1.0, top.y + 1.0); setmat(k, ring_steel)
    for p in (o, k):
        _bev(p, 0.4, 2, 30)
        p.data.transform(Matrix.Translation(top) @ Matrix.Rotation(math.radians(rot), 4, 'Y') @ Matrix.Translation(-top))

hx = [RX - 80, RX + 10, RX + 95]
h1 = cup_hook(hx[0], RZ); r1 = split_ring(h1, yaw=20); key_tag('tag13', r1, '13', tag_alu, rot=-3)
h2 = cup_hook(hx[1], RZ); r2 = split_ring(h2, r=13, yaw=-30); key_tag('tag14', r2 + Vector((-3, 0, 1)), '14', brass, rot=6)
invented_key(r2 + Vector((5, -2.5, 2)), rot=-10)
cup_hook(hx[2], RZ)

# ---------------------------------------------------------------- light
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (BX, 0, (ZT + ZB) / 2)
bpy.ops.object.light_add(type='POINT', location=(BX - 1100, -900, TOP + 650)); bulb = bpy.context.object
bulb.data.shadow_soft_size = 30; bulb.data.energy = float(arg('--bulb', '5.5e7')); bulb.data.color = (1.0, 0.70, 0.43)
area_light('window', (BX + 1800, -1600, 1900), AIM, 1400, float(arg('--window', '5e6')), (0.75, 0.84, 1.0), size_y=1800)
area_light('bounce', (BX, -2600, 900), AIM, 2200, 3e5, (1.0, 0.85, 0.7))
world_hdri(strength=0.06, sat=0.3)

# ---------------------------------------------------------------- camera
LENS = 85.0
if ORIENT == 'portrait':
    VW = 560.0; VH = VW * RES[1] / RES[0]; CZ = TOP + 110 - VH / 2; CX = 0.0
    D = VW * LENS / 36.0
    cam = photo_camera((CX, RIB_FACE - D, CZ), lens=LENS); cam.data.sensor_fit = 'HORIZONTAL'; cam.data.sensor_width = 36.0
else:
    VH = 640.0; VW = VH * RES[0] / RES[1]; CZ = (ZT + ZB) / 2; CX = BX + 205.0
    D = VH * LENS / 36.0
    cam = photo_camera((CX, RIB_FACE - D, CZ), lens=LENS); cam.data.sensor_fit = 'VERTICAL'; cam.data.sensor_height = 36.0

# ---------------------------------------------------------------- hits
bpy.context.view_layer.update()
W, H = RES; DP = W / 412.0 if ORIENT == 'portrait' else H / 412.0
def px_rect(pts):
    p = project(pts); xs = [q[0] * W for q in p]; ys = [q[1] * H for q in p]
    return [round(min(xs)), round(min(ys)), round(max(xs) - min(xs)), round(max(ys) - min(ys))]
items = []
for r in rows:
    ws = [o.matrix_world @ Vector(v) for o in r['objs'] for v in o.bound_box]
    x0, x1 = min(v.x for v in ws), max(v.x for v in ws); z0, z1 = min(v.z for v in ws), max(v.z for v in ws)
    tr = px_rect([(x0, RIB_FACE - 3, z0), (x1, RIB_FACE - 3, z0), (x1, RIB_FACE - 3, z1), (x0, RIB_FACE - 3, z1)])
    bz0, bz1 = r['band']; bx0 = X0 + MENU_X - 12 if ORIENT == 'landscape' else X0; bx1 = X0 + IW
    hr = px_rect([(bx0, RIB_FACE - 3, bz0), (bx1, RIB_FACE - 3, bz0), (bx1, RIB_FACE - 3, bz1), (bx0, RIB_FACE - 3, bz1)])
    capr = px_rect([(x0, RIB_FACE - 3, r['base']), (x0, RIB_FACE - 3, r['base'] + r['cap'])])
    items.append({'id': r['id'], 'label': r['label'], 'text_rect': tr, 'hit_rect': hr, 'cap_px': capr[3],
                  'hit_dp': [round(hr[2] / DP, 1), round(hr[3] / DP, 1)]})
os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
if CROP_ROW < 0:
    with open(HITS, 'w') as f:
        json.dump({'image': os.path.basename(OUT), 'width': W, 'height': H, 'orient': ORIENT, 'px_per_dp': round(DP, 4),
                   'rect': '[x, y, w, h] px, origin top-left', 'items': items}, f, indent=1)
    print('HITS', HITS)

# ---------------------------------------------------------------- render
crop = None
if CROP_ROW >= 0:
    x, y, w, h = items[CROP_ROW]['hit_rect']; m = 20
    crop = (max(0, (x - m) / W), max(0, 1 - (y + h + m) / H), min(1, (x + w + m) / W), min(1, 1 - (y - m) / H))
render_setup(OUT, RES, SAMPLES, crop=crop, look='AgX - Medium High Contrast', bounces=8)
scene.cycles.adaptive_threshold = 0.01
photo_finish(0.2, dispersion=0.004)
if '--norender' not in sys.argv:
    bpy.ops.render.render(write_still=True)
print('WROTE', scene.render.filepath)
