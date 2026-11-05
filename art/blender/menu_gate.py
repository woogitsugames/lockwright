# Lockwright — MAIN MENU as a photographed object: the tenants' felt letter board in a tenement stairwell. 1 unit = 1 mm.
# Reproduce every menu deliverable (art/renders/menu/) with ONE command (~2-3 h on 4 CPU cores):
#   sh -c 'B=/opt/tools/blender-4.2.9-linux-x64/blender; python3 art/blender/menu_compose.py --render-all --blender $B'
# Single renders:
#   blender -b -P art/blender/menu_gate.py -- --out art/renders/menu/menu_portrait.png --res 1080x2400 --samples 160 --hits art/renders/menu/menu_hits.json
#   ... --orient landscape --res 2400x1080 --hits art/renders/menu/menu_hits_landscape.json   (re-composed board: title + primary left, menu right)
#   ... --pressed 1 --crop-row 1 --out .../menu_pressed_jobs.png   (row 1 pushed into the felt, only that row's hit rect rendered)
#   ... --shot settings                                           (close-up: typed index card pinned to the same board)
# Scene: black ribbed felt board in a dark-stained, worn wooden frame, screwed to a stairwell wall (photo oil-paint lamperia,
# painted divider line, photo lime plaster with a repaired patch, flaked paint, soot and hand grime, a painted-over cable).
# White push-in plastic letters (Archivo, OFL), every letter its own mesh: uneven spacing and baselines, tilted, some pushed
# in less, yellowed / grimy ones, two chipped, one replacement from another set (Chivo). Loose letters on the bottom ledge.
# Under the board an oak hook rail with brass cup hooks, three big stamped key tags, a paper ring tag and invented keys.
# Light: one warm stairwell bulb high on the left, raking the board (deep fall-off to the lower right), a faint cool window.
# Writes the hits JSON: per menu item the letters' rect and the hit band, in px and dp.
import bpy, math, os, sys, json, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from env_common import *
from env_common import _bev, _new, _math, _bump
from lw_common import _noise, _mix, _maprange, _edge_mask, _cavity_mask
from mathutils import Vector, Matrix

arg = cli()
OUT = arg('--out', 'art/renders/menu/test_menu.png'); RES = [int(v) for v in arg('--res', '270x600').split('x')]
SAMPLES = int(arg('--samples', '16')); ORIENT = arg('--orient', 'portrait')
PRESSED = int(arg('--pressed', '-1')); CROP_ROW = int(arg('--crop-row', '-1')); SHOT = arg('--shot', 'menu')
HITS = arg('--hits', os.path.splitext(OUT)[0] + '_hits.json')
rng = random.Random(11)
FD = os.path.join(ROOT, 'mockups', 'ui-directions', 'fonts')
FONT = bpy.data.fonts.load(os.path.join(FD, 'Archivo-wdth-wght.ttf'))
FONT_ALT = bpy.data.fonts.load(os.path.join(FD, 'Chivo-wght.ttf'))          # one letter from another set
MONO = bpy.data.fonts.load(os.path.join(FD, 'ChivoMono-wght.ttf'))
HAND = bpy.data.fonts.load(os.path.join(FD, 'Kalam-Regular.ttf'))

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
    """Black needle felt: fibre mottling, sheen (so the ribs read under raking light), lint specks, grey dust in the grooves."""
    m, nt, l, b, P = _new('felt')
    fib = _noise(nt, P, 3.0, detail=10, rough=0.75)
    mot = _noise(nt, P, 0.04, detail=4)
    col = _mix(nt, (0.013, 0.013, 0.013, 1), (0.036, 0.035, 0.033, 1), _maprange(nt, fib, 0.35, 0.75))
    col = _mix(nt, col, (0.008, 0.008, 0.008, 1), _maprange(nt, mot, 0.4, 0.65, 0, 0.5))
    lint = _maprange(nt, _noise(nt, P, 0.9, detail=3, rough=0.4, dist=0.6), 0.745, 0.775)
    col = _mix(nt, col, (0.30, 0.29, 0.27, 1), _math(nt, 'MULTIPLY', lint, 0.6))
    dust = _maprange(nt, _noise(nt, P, 0.012, detail=5), 0.55, 0.8, 0, 0.22)
    col = _mix(nt, col, (0.20, 0.19, 0.18, 1), dust)
    gd = _math(nt, 'MULTIPLY', _maprange(nt, _cavity_mask(nt, 1.5, 0.3, 0.95), 0, 1, 0, 0.6), _maprange(nt, _noise(nt, P, 0.05, detail=6), 0.4, 0.75, 0.2, 1.0))
    col = _mix(nt, col, (0.26, 0.25, 0.23, 1), gd)
    l.new(col, b.inputs['Base Color']); b.inputs['Roughness'].default_value = 0.9
    b.inputs['Sheen Weight'].default_value = 0.4; b.inputs['Sheen Roughness'].default_value = 0.35
    b.inputs['Sheen Tint'].default_value = (0.6, 0.6, 0.6, 1); b.inputs['Specular IOR Level'].default_value = 0.3
    bv = nt.nodes.new('ShaderNodeBevel'); bv.samples = 6; bv.inputs['Radius'].default_value = 0.6
    l.new(_bump(nt, _mix(nt, fib, _noise(nt, P, 8.0, detail=4), 0.5, dtype='FLOAT'), 0.35, 0.15, bv.outputs['Normal']), b.inputs['Normal'])
    return m

def flake_decal(name, bounds, centre, radii, under=(0.66, 0.62, 0.52), rim=(0.05, 0.045, 0.035), amount=0.6, scale=0.02, y=-0.25):
    """Paint flaked off in islands: transparent outside the flakes, an older lighter layer inside, a dark lifted rim around each
    flake. bounds (x0, x1, z0, z1); the islands thin out with an elliptical falloff around centre/radii."""
    m, nt, l, b, P = _new(name); out = nt.nodes['Material Output']
    from env_common import _sep
    X, Y, Z = _sep(nt, P)
    du = _math(nt, 'DIVIDE', _math(nt, 'SUBTRACT', X, centre[0]), radii[0]); dv = _math(nt, 'DIVIDE', _math(nt, 'SUBTRACT', Z, centre[1]), radii[1])
    fall = _math(nt, 'EXPONENT', _math(nt, 'MULTIPLY', _math(nt, 'ADD', _math(nt, 'MULTIPLY', du, du), _math(nt, 'MULTIPLY', dv, dv)), -2.0))
    n = _noise(nt, P, scale, detail=12, rough=0.72, dist=0.5)
    v = _math(nt, 'ADD', n, _math(nt, 'MULTIPLY', fall, 0.35 * amount))
    inner = _maprange(nt, v, 0.74, 0.745); edge = _maprange(nt, v, 0.71, 0.74)
    col = _mix(nt, (*rim, 1), (*under, 1), inner)
    b.inputs['Roughness'].default_value = 0.85
    l.new(col, b.inputs['Base Color'])
    l.new(_bump(nt, _math(nt, 'SUBTRACT', 1.0, inner), 0.6, 0.4), b.inputs['Normal'])
    tr = nt.nodes.new('ShaderNodeBsdfTransparent'); ms = nt.nodes.new('ShaderNodeMixShader')
    l.new(edge, ms.inputs[0]); l.new(tr.outputs[0], ms.inputs[1]); l.new(b.outputs[0], ms.inputs[2]); l.new(ms.outputs[0], out.inputs['Surface'])
    x0, x1, z0, z1 = bounds
    o = bx(name, x0, x1, y - 0.05, y, z0, z1, m); o.visible_shadow = False; return o

green = photo_mat('ph_lamperia', 'wall_oil_paint_green', scale=760, metallic=0.0, bump=0.45, coat=0.35, grime=0.5,
                  base=(0.05, 0.10, 0.075), base_mix=0.25)
lime = photo_mat('ph_wall_lime', 'wall_lime_plaster', scale=1000, metallic=0.0, bump=0.5, grime=0.5, tint=(0.80, 0.76, 0.68))
patch_m = lime_wall('patch', color=(0.80, 0.78, 0.72), seed=3, dirt=0.25, cracks=0.0)
stripe = oil_paint('stripe', (0.16, 0.04, 0.03), rough=0.3, chips=0.8, scuffs=0.9, strokes='X', seed=2, edge_chips=1.0)
wood_fr = photo_mat('ph_frame', 'bench_beech_top', scale=420, rot=0, metallic=0.0, base=(0.10, 0.055, 0.03), base_mix=0.42,
                    coat=0.45, bump=0.25, wear=0.55, grime=0.7)
wood_fr = add_top_dust(wood_fr, 0.45)
alu = add_top_dust(photo_mat('ph_alu', 'nickel_satin', scale=140, metallic=1.0, base=(0.66, 0.66, 0.64), base_mix=0.35, rough_add=0.08, wear=0.2, grime=0.6), 0.45)
felt = felt_mat()
def letter_mat(name, col, rough, grime, dust):
    m = add_top_dust(plastic(name, col, rough=rough, grime=grime, sheen_scuffs=0.35), dust)
    m.node_tree.nodes['Principled BSDF'].inputs['Coat Weight'].default_value = 0.2; return m
letter_w = letter_mat('letter_white', (0.80, 0.80, 0.77), 0.26, 0.45, 0.5)
letter_y = letter_mat('letter_old', (0.74, 0.69, 0.55), 0.32, 0.7, 0.6)
letter_g = letter_mat('letter_grimy', (0.62, 0.61, 0.58), 0.36, 0.9, 0.7)
stamp_ink = dark_mat('stamp_grime', (0.025, 0.022, 0.02), rough=0.8)
beech = add_top_dust(photo_mat('ph_beech', 'bench_beech_top', scale=320, metallic=0.0, coat=0.25, bump=0.25, grime=0.6, wear=0.4,
                               base=(0.30, 0.18, 0.09), base_mix=0.3), 0.35)
brass = photo_mat('ph_brass', 'brass_patina_grease', scale=60, metallic=1.0, base=(0.62, 0.48, 0.28), base_mix=0.45, rough_add=0.14, wear=0.3, grime=0.7)
tag_alu = photo_mat('ph_tag_alu', 'nickel_satin', scale=50, metallic=1.0, base=(0.74, 0.74, 0.72), base_mix=0.4, rough_add=0.12, wear=0.4, grime=0.9)
tag_steel = photo_mat('ph_tag_steel', 'iron_painted_rust', scale=90, metallic=0.0, rough_add=0.05, grime=0.6, wear=0.6,
                      base=(0.30, 0.06, 0.04), base_mix=0.35)
ring_steel = photo_mat('ph_ring', 'steel_ground', scale=30, metallic=1.0, rough_add=0.08, grime=0.5)
key_nickel = photo_mat('ph_key', 'nickel_satin', scale=40, metallic=1.0, base=(0.70, 0.69, 0.66), base_mix=0.25, rough_add=0.1, wear=0.5, grime=0.8)
card_tag = paper('ring_tag_paper', (0.80, 0.76, 0.64), grime=0.5, seed=7)
pencil = dark_mat('pencil', (0.06, 0.06, 0.07), rough=0.55)
cable_paint = photo_mat('ph_cable', 'wall_lime_plaster', scale=300, metallic=0.0, bump=0.2, grime=0.8, tint=(0.52, 0.49, 0.43))

# ---------------------------------------------------------------- layout (x right, z up, y into the wall; wall face y = 0)
PITCH = 6.5                         # felt rib pitch; letter baselines sit in a groove
BACK, RIB_FACE = -3.0, -15.0        # felt base face at y=-12, rib crowns at -15
FRAME_Y = -32.0; FR = 30.0          # frame depth and width
if ORIENT == 'portrait':
    IW = 382.0; TOP = 2060.0; BX = 0.0
    TITLE = [('POGOTOWIE ZAMKOWE', 15.0, 24.0, 2.0), ('LOCKWRIGHT', 47.0, 52.0, 0.0)]     # text, cap, top (mm from inner top), x
    # id, text, cap, band top, band height, text x, band x0, band x1 (mm from the inner top-left)
    MENU = [('start', 'ZACZNIJ DYŻUR', 35.0, 140.0, 102.0, 20.0, 0, IW)]
    for i, (iid, t) in enumerate((('jobs', 'ZLECENIA'), ('workshop', 'WARSZTAT'), ('showcase', 'GABLOTA'), ('settings', 'USTAWIENIA'), ('about', 'O GRZE'))):
        MENU.append((iid, t, 30.0, 242.0 + i * 84.0, 84.0, 22.0, 0, IW))
    IH = 242.0 + 5 * 84.0 + 18.0
else:
    IW = 846.0; TOP = 1990.0; BX = -170.0
    TITLE = [('POGOTOWIE ZAMKOWE', 16.0, 30.0, 2.0), ('LOCKWRIGHT', 52.0, 62.0, 0.0)]
    MENU = [('start', 'ZACZNIJ DYŻUR', 36.0, 296.0, 110.0, 20.0, 0, 452)]
    for i, (iid, t) in enumerate((('jobs', 'ZLECENIA'), ('workshop', 'WARSZTAT'), ('showcase', 'GABLOTA'), ('settings', 'USTAWIENIA'), ('about', 'O GRZE'))):
        MENU.append((iid, t, 30.0, 20.0 + i * 78.0, 78.0, 488.0, 466, IW))
    IH = 20.0 + 5 * 78.0 + 18.0
if SHOT == 'settings': TITLE = [('‹ WSTECZ', 14.0, 22.0, 116.0)]; MENU = []
X0 = BX - IW / 2; ZT = TOP - FR; ZB = ZT - IH

# ---------------------------------------------------------------- wall: lamperia / divider / lime, wear
DIV = ZB + 300.0 if ORIENT == 'portrait' else ZB + 150.0       # the divider line runs behind the board
bx('wall_green', -2400, 2400, 0, 60, -400, DIV, green)
bx('wall_stripe', -2400, 2400, -0.6, 60, DIV, DIV + 12, stripe)
bx('wall_lime', -2400, 2400, 0, 60, DIV + 12, 3600, lime)
# hand grime on the lamperia (people lean and brush past), soot plume above where the bulb hangs, grime round the frame
stain_decal('dado_scuffs', 'Y', -0.3, (-2400, 2400, DIV - 420, DIV + 40),
            [(-420, DIV - 180, 380, 140, 0.45), (380, DIV - 260, 460, 120, 0.4), (60, DIV - 40, 900, 40, 0.3), (700, DIV - 340, 300, 160, 0.35)],
            color=(0.05, 0.045, 0.035), rough=0.55, noise_scale=0.025)
stain_decal('soot', 'Y', -0.35, (-2400, 2400, ZT - 200, 3600),
            [(X0 - 420, TOP + 520, 260, 520, 0.55), (X0 - 300, TOP + 220, 420, 200, 0.25), (BX, TOP + 40, IW * 0.7, 60, 0.22)],
            color=(0.12, 0.10, 0.08), rough=0.9, noise_scale=0.012)
stain_decal('frame_grime', 'Y', -0.4, (X0 - 200, X0 + IW + 200, ZB - 200, TOP + 160),
            [(X0 - FR, (ZT + ZB) / 2, 40, IH * 0.45, 0.35), (X0 + IW + FR, (ZT + ZB) / 2 - 60, 50, IH * 0.4, 0.45),
             (BX, ZB - FR - 10, IW * 0.5, 30, 0.3), (X0 + IW + FR + 10, ZB - 20, 60, 80, 0.4)],
            color=(0.07, 0.06, 0.045), rough=0.7, noise_scale=0.03)
# a repaired patch of fresher plaster (skimmed proud, its own paint) and flaked paint showing older layers
if ORIENT == 'portrait':
    PATCH = [(X0 + IW - 40, TOP + 160), (X0 + IW + 120, TOP + 130), (X0 + IW + 190, TOP - 60), (X0 + IW + 160, TOP - 260),
             (X0 + IW + 60, TOP - 300), (X0 + IW - 10, TOP - 180), (X0 + IW - 50, TOP + 20)]
else:
    PATCH = [(X0 - 180, TOP + 40), (X0 - 40, TOP + 80), (X0 + 120, TOP + 30), (X0 + 160, TOP - 30), (X0 - 60, TOP - 60), (X0 - 200, TOP - 20)]
pt = prism('plaster_patch', PATCH, -1.2, 0.0); setmat(pt, patch_m); _bev(pt, 1.0, 3, 30)
flake_decal('flakes_lime', (X0 - 300, X0 + IW + 300, DIV + 12, TOP + 400), (X0 + IW + 70, TOP - 330), (260, 200), amount=1.0, scale=0.018)
flake_decal('flakes_green', (-2400, 2400, DIV - 300, DIV + 12), (X0 + 60, DIV - 30), (420, 120), under=(0.55, 0.50, 0.38), amount=0.9, scale=0.03)
flake_decal('flakes_green2', (-2400, 2400, ZB - 700, DIV - 100), (X0 + IW - 30, ZB - 380), (300, 220), under=(0.40, 0.42, 0.36), amount=0.4, scale=0.024, y=-0.3)
# old nail holes and a bent nail where something hung before
for hx_, hz_ in ((X0 - 70, TOP + 90), (X0 + IW + 70, TOP + 85)):
    c = cyl('nail_hole', 2.2, 1.0, (hx_, -0.5, hz_), axis='Y', verts=16); setmat(c, dark_mat('hole', (0.02, 0.018, 0.015), 0.9))
tube('old_nail', [(X0 - 70, 1, TOP + 90), (X0 - 70, -9, TOP + 90), (X0 - 66, -13, TOP + 96)], 1.1, ring_steel, res=3, smooth_pts=False)
screw_head('old_nail_head', (X0 - 66, -13, TOP + 96), 2.4, 0.8, axis='-Y', slot=False, kind='dome', mat=ring_steel)
# a painted-over surface cable: down the wall left of the board, saddle clips every ~160 mm
CXW = X0 - FR - 34 if ORIENT == 'portrait' else X0 - FR - 60
cpts = [(CXW + 400, -5, 3600), (CXW + 400, -5, TOP + 330), (CXW + 340, -5, TOP + 270), (CXW, -5, TOP + 200), (CXW, -5, -400)]
tube('cable', [(CXW + 900, -5, TOP + 330), (CXW + 60, -5, TOP + 330), (CXW, -5, TOP + 270), (CXW, -5, -400)], 4.5, cable_paint, res=4)
for zc in range(int(TOP + 140), -400, -310):
    s = bx('clip', CXW - 5.5, CXW + 5.5, -10.0, 0, zc - 3, zc + 3, cable_paint, bev=1.4, seg=2)
    screw_head('clip_nail', (CXW + 8.0, -1.0, zc), 1.8, 0.9, axis='-Y', slot=False, kind='dome', mat=ring_steel)

# ---------------------------------------------------------------- board: backing, ribs, frame
bx('board_back', X0, X0 + IW, -12.0, BACK, ZB, ZT, felt)
rib = bx('rib', X0, X0 + IW, RIB_FACE, -12.0, ZB + 1.0, ZB + 1.0 + PITCH - 2.0, felt)
_bev(rib, 0.9, 3, 30)
ar = rib.modifiers.new('arr', 'ARRAY'); ar.use_relative_offset = False; ar.use_constant_offset = True
ar.constant_offset_displace = (0, 0, PITCH); ar.count = int(IH / PITCH)
rib.modifiers.move(len(rib.modifiers) - 1, 0)
# moulded frame: flat rail, a raised outer bead, a chamfered inner lip; butt joints like a cheap joiner's board
for nm, a in (('fr_t', (X0 - FR, X0 + IW + FR, ZT, ZT + FR)), ('fr_b', (X0 - FR, X0 + IW + FR, ZB - FR, ZB)),
              ('fr_l', (X0 - FR, X0, ZB, ZT)), ('fr_r', (X0 + IW, X0 + IW + FR, ZB, ZT))):
    bx(nm, a[0], a[1], FRAME_Y + 5, 0, a[2], a[3], wood_fr, bev=1.6, seg=3)
    o_in = {'fr_t': (0, 0, 0, 12), 'fr_b': (0, 0, 12, 0), 'fr_l': (0, 12, 0, 0), 'fr_r': (12, 0, 0, 0)}[nm]   # bead on the outer part
    bx(nm + '_bead', a[0] + o_in[0] + (0 if nm in ('fr_t', 'fr_b') else 0), a[1] - o_in[1], FRAME_Y, FRAME_Y + 5.5,
       a[2] + o_in[2], a[3] - o_in[3], wood_fr, bev=2.4, seg=4)
for sx, sz in ((X0 - FR / 2 + 2, ZT + FR / 2), (X0 + IW + FR / 2 - 2, ZT + FR / 2), (X0 - FR / 2 + 2, ZB - FR / 2), (X0 + IW + FR / 2 - 2, ZB - FR / 2)):
    screw_head('screw', (sx, FRAME_Y + 4.6, sz), 4.6, 2.2, axis='-Y', slot=True, kind='pan', mat=brass, rot=rng.uniform(0, 180))

# ---------------------------------------------------------------- letters
def snap(z): return ZB + round((z - ZB) / PITCH) * PITCH + 1.0 - 0.6     # baseline: just above a groove bottom

def glyph(ch, size, mat, name, font=None):
    cu = bpy.data.curves.new(name, 'FONT'); cu.body = ch; cu.size = size; cu.font = font or FONT
    cu.extrude = 1.6; cu.bevel_depth = 0.35; cu.bevel_resolution = 2; cu.align_x = 'LEFT'; cu.align_y = 'BOTTOM_BASELINE'
    o = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(o); o.data.materials.append(mat); return o

def chip(o, size):
    """Convert to mesh and knock a corner off (an old letter that was dropped)."""
    bpy.context.view_layer.objects.active = o; o.select_set(True); bpy.ops.object.convert(target='MESH'); o.select_set(False)
    bb = [Vector(v) for v in o.bound_box]; mx = max(v.x for v in bb); my = max(v.y for v in bb)
    c = bx('chip', 0, size * 0.22, -size * 0.12, size * 0.12, -10, 10)
    c.matrix_world = Matrix.Translation((mx - size * 0.05, my - size * 0.02, 0)) @ Matrix.Rotation(math.radians(35), 4, 'Z')
    bpy.context.view_layer.update(); c.data.transform(c.matrix_world); c.matrix_world = Matrix.Identity(4)
    cut(o, c)

LETTERS = []
def row(text, cap, top_mm, x_mm, tag, seed, loose=0.0):
    """One line of push-in letters. Each letter: own spacing / baseline / tilt / depth; some old, grimy, chipped, from another set."""
    r = random.Random(seed); size = cap / 0.7; base = snap(ZT - top_mm - cap)
    objs = []
    crooked = r.choice([i for i, c in enumerate(text) if c != ' ']) if len(text) > 3 else -1
    for i, ch in enumerate(text):
        if ch == ' ': objs.append(None); continue
        u = r.random(); mat = letter_w if u < 0.72 else (letter_y if u < 0.9 else letter_g)
        alt = (r.random() < 0.06 and ch not in 'ŻĄĘŁŚĆŃÓŹ')
        o = glyph(ch, size, mat, '%s_%d' % (tag, i), FONT_ALT if alt else None)
        if r.random() < 0.07: chip(o, size)
        objs.append(o)
    bpy.context.view_layer.update()
    x = X0 + x_mm
    for i, (ch, o) in enumerate(zip(text, objs)):
        if o is None: x += 0.36 * size + r.uniform(-1.5, 3.0); continue
        bb = [Vector(v) for v in o.bound_box]; minx = min(v.x for v in bb); w = max(v.x for v in bb) - minx
        tilt = r.uniform(-2.2, 2.2) * (1 + loose)
        if i == crooked: tilt = r.choice((-1, 1)) * r.uniform(5.5, 9.0)
        lean = r.uniform(-1.0, 4.0)                    # top edge pulled out of the groove (pushed in unevenly)
        o.rotation_euler = (math.radians(90 - lean), math.radians(tilt), math.radians(r.uniform(-2.0, 2.0)))
        depth = r.uniform(0.0, 1.4)
        o.location = (x - minx, RIB_FACE - 1.7 - depth, base + r.uniform(-0.8, 0.8) + (1.2 if i == crooked else 0))
        x += w + 0.085 * size + r.uniform(-1.4, 2.4)
        LETTERS.append(o)
    return [o for o in objs if o], base

title_rows = []
for k, (text, cap, top, xm) in enumerate(TITLE):
    title_rows.append(row(text, cap, top, 20.0 + xm, 'title%d' % k, 100 + k))

rows = []
for i, (iid, text, cap, btop, bh, tx, bx0, bx1) in enumerate(MENU):
    objs, base = row(text, cap, btop + (bh - cap) / 2 - 2, tx, 'menu%d' % i, 200 + i)
    rows.append({'id': iid, 'label': text, 'objs': objs, 'band': (ZT - btop - bh, ZT - btop), 'bx': (X0 + bx0, X0 + bx1), 'base': base, 'cap': cap})

if PRESSED >= 0:   # baked pressed state: the row is pushed into the felt (its shadows shrink) and settles straight
    for o in rows[PRESSED]['objs']:
        o.location.y += 2.6; e = o.rotation_euler; o.rotation_euler = (math.radians(90) + (e[0] - math.radians(90)) * 0.2, e[1] * 0.6, e[2] * 0.3)

# loose letters lying on the bottom ledge of the frame (spares nobody put away)
if SHOT == 'menu':
    for k, (ch, xo, rz) in enumerate((('A', 0.12, 18), ('E', 0.16, -64), ('7', 0.78, 103))):
        o = glyph(ch, 24.0, letter_w if k != 1 else letter_y, 'loose_%d' % k)
        o.rotation_euler = (0, 0, math.radians(rz)); o.location = (X0 + IW * xo, RIB_FACE - 2.0 - 7.0 * (k % 2), ZB + 1.7)

# ---------------------------------------------------------------- hook rail, key tags, invented keys
if ORIENT == 'portrait': RX, RZ, RW = BX + 10.0, ZB - FR - 70.0, 380.0
else: RX, RZ, RW = X0 + IW + FR + 210.0, ZT - 30.0, 300.0
if SHOT == 'settings': RZ = ZB - 4000.0   # rail out of shot
bx('rail', RX - RW / 2, RX + RW / 2, -20, 0, RZ - 30, RZ + 30, beech, bev=3.0)
for sx in (RX - RW / 2 + 18, RX + RW / 2 - 18):
    screw_head('rail_screw', (sx, -20.2, RZ + 4), 3.8, 1.6, axis='-Y', slot=True, kind='pan', mat=brass, rot=rng.uniform(0, 180))

def cup_hook(x, z):
    pts = [(x, -18, z - 10), (x, -27, z - 10), (x, -36, z - 8), (x, -40, z), (x, -37, z + 8), (x, -32, z + 10)]
    tube('hook', pts, 2.0, brass, res=4)
    c = cyl('collar', 3.6, 2.2, (x, -21, z - 10), axis='Y', verts=24); setmat(c, brass); _bev(c, 0.5, 2)
    return Vector((x, -39.0, z - 9.0))          # where a ring hangs (inside of the bend)

def split_ring(c, r=13.0, wire=1.3, yaw=25.0):
    bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=wire, major_segments=48, minor_segments=10,
                                     location=(c.x, c.y, c.z - r + 1.5), rotation=(math.radians(90), 0, math.radians(yaw)))
    o = bpy.context.object; setmat(o, ring_steel); smooth(o); return Vector((c.x, c.y, c.z - 2 * r + 3.5))

def hang(objs, pivot, rot_y, rot_z):
    """Swing hanging pieces about their hole: rot_y in the wall plane, rot_z turns the tag out of the plane (catches the light)."""
    M = Matrix.Translation(pivot) @ Matrix.Rotation(math.radians(rot_z), 4, 'Z') @ Matrix.Rotation(math.radians(rot_y), 4, 'Y') @ Matrix.Translation(-pivot)
    for o in objs:
        if o.type == 'MESH': o.data.transform(o.matrix_world); o.matrix_world = Matrix.Identity(4); o.data.transform(M)
        else: o.matrix_world = M @ o.matrix_world

def key_tag(name, top, text, mat, w=80.0, h=150.0, rot=0.0, swing=0.0, num=54.0):
    """Stamped key tag hanging from its hole: rounded rect, 1.8 mm thick, number punched 0.5 mm deep with grime packed in."""
    pts = [(u, v - h / 2 - 7) for u, v in rounded_rect(w, h, 9)]
    t = prism(name, [(top.x + u, top.z + v) for u, v in pts], top.y - 0.9, top.y + 0.9); setmat(t, mat)
    cut(t, cyl('hole', 3.8, 6, (top.x, top.y, top.z - 7.5), axis='Y', verts=24))
    cu = bpy.data.curves.new(name + '_n', 'FONT'); cu.body = text; cu.size = num; cu.font = MONO; cu.extrude = 1.0
    cu.align_x = 'CENTER'; cu.align_y = 'CENTER'
    s = bpy.data.objects.new(name + '_n', cu); bpy.context.collection.objects.link(s)
    s.rotation_euler = (math.radians(90), math.radians(rng.uniform(-4, 4)), 0); s.location = (top.x + rng.uniform(-2, 2), top.y - 0.9 - 0.5, top.z - 7 - h * 0.56)
    bpy.context.view_layer.objects.active = s; s.select_set(True); bpy.ops.object.convert(target='MESH'); s.select_set(False)
    fill = s.copy(); fill.data = s.data.copy(); bpy.context.collection.objects.link(fill)
    cut(t, s); _bev(t, 0.4, 2, 30)
    fill.scale = (1, 1, 0.06); fill.location.y = top.y - 0.9 + 0.5; setmat(fill, stamp_ink)
    bpy.context.view_layer.update()
    hang([t, fill], top, rot, swing); return t

def ring_tag(name, top, text, rot=0.0, swing=0.0, R=27.0):
    """Round paper tag with a steel rim, pencilled label."""
    c = Vector((top.x, top.y, top.z - R - 4))
    p = cyl(name, R, 0.5, (c.x, c.y, c.z), axis='Y', verts=64); setmat(p, card_tag)
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=1.1, major_segments=64, minor_segments=8, location=c, rotation=(math.radians(90), 0, 0))
    rim = bpy.context.object; setmat(rim, ring_steel); smooth(rim)
    cu = bpy.data.curves.new(name + '_t', 'FONT'); cu.body = text; cu.size = 11.0; cu.font = HAND; cu.align_x = 'CENTER'; cu.align_y = 'CENTER'
    s = bpy.data.objects.new(name + '_t', cu); bpy.context.collection.objects.link(s); s.data.materials.append(pencil)
    s.rotation_euler = (math.radians(90), math.radians(-6), 0); s.location = (c.x, c.y - 0.3, c.z - 2)
    bpy.context.view_layer.objects.active = s; s.select_set(True); bpy.ops.object.convert(target='MESH'); s.select_set(False)
    hang([p, rim, s], top, rot, swing)

def invented_key(top, rot=0.0, sc=1.0, swing=0.0):
    """A flat key that matches no real profile: round-cornered bow with a hole, plain blade with three cuts."""
    bow = [(u, v - 16) for u, v in rounded_rect(30, 28, 9)]
    o = prism('key_bow', [(top.x + u, top.z + v) for u, v in bow], top.y - 1.1, top.y + 1.1); setmat(o, key_nickel)
    cut(o, cyl('kh', 4.0, 6, (top.x, top.y, top.z - 7), axis='Y', verts=24))
    blade = [(-4.5, -29), (4.5, -29), (4.5, -76), (1.0, -80), (-4.5, -80), (-4.5, -71), (-8.5, -68), (-8.5, -62), (-4.5, -60),
             (-4.5, -52), (-9, -49), (-9, -44), (-4.5, -41)]
    k = prism('key_blade', [(top.x + u, top.z + v) for u, v in blade], top.y - 1.0, top.y + 1.0); setmat(k, key_nickel)
    for p in (o, k):
        _bev(p, 0.4, 2, 30)
        p.data.transform(Matrix.Translation(top) @ Matrix.Scale(sc, 4) @ Matrix.Translation(-top))
    hang([o, k], top, rot, swing)

if SHOT == 'menu':
    if ORIENT == 'portrait': hx = [RX - 145, RX - 45, RX + 52, RX + 142]
    else: hx = [RX - 100, RX, RX + 100]
    h = cup_hook(hx[0], RZ); r1 = split_ring(h, yaw=20); key_tag('tag13', r1, '13', tag_alu, rot=-4, swing=-8)
    invented_key(r1 + Vector((4, 3.0, 2)), rot=9, sc=1.5, swing=10)
    h = cup_hook(hx[1], RZ); r2 = split_ring(h, r=15, yaw=-30); key_tag('tag14', r2 + Vector((-3, 0, 1)), '14', brass, rot=5, swing=12)
    invented_key(r2 + Vector((6, 3.0, 2)), rot=-14, sc=1.6, swing=-6)
    h = cup_hook(hx[2], RZ)
    if ORIENT == 'portrait':
        r3 = split_ring(h, r=12, yaw=15); key_tag('tag7', r3, '7', tag_steel, rot=-2, swing=-18, w=70, h=128)
        h = cup_hook(hx[3], RZ); r4 = split_ring(h, r=10, yaw=-10); ring_tag('rtag', r4, 'piwnica', rot=3, swing=14)
    else:
        r3 = split_ring(h, r=12, yaw=15); ring_tag('rtag', r3, 'piwnica', rot=3, swing=14)

# ---------------------------------------------------------------- settings: typed index card pinned to the board
CARD_ITEMS = []
if SHOT == 'settings':
    exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'menu_settings_card.py')).read())

# ---------------------------------------------------------------- light: one warm bulb raking from high left, deep fall-off
CTR = Vector((BX, 0, (ZT + ZB) / 2))
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = CTR
bpy.ops.object.light_add(type='SPOT', location=(X0 - 170, -300, TOP + 200)); bulb = bpy.context.object
bulb.data.shadow_soft_size = float(arg('--soft', '22')); bulb.data.energy = float(arg('--bulb', '5.5e7')); bulb.data.color = (1.0, 0.70, 0.44)
bulb.data.spot_size = math.radians(78); bulb.data.spot_blend = 1.0
a_b = bpy.data.objects.new('aim_bulb', None); scene.collection.objects.link(a_b)
a_b.location = (BX - 10, 0, (ZT + ZB) / 2 + 20) if ORIENT == 'portrait' else (BX + 160, 0, (ZT + ZB) / 2 - 60)
cb = bulb.constraints.new('TRACK_TO'); cb.target = a_b; cb.track_axis = 'TRACK_NEGATIVE_Z'; cb.up_axis = 'UP_Y'
area_light('window', (BX + 1800, -1100, ZB - 200), AIM, 1200, float(arg('--window', '1.2e6')), (0.60, 0.72, 1.0), size_y=1600)
area_light('bounce', (BX + 300, -2600, (ZT + ZB) / 2 - 300), AIM, 1600, float(arg('--bounce', '9e4')), (1.0, 0.84, 0.66))
world_hdri(strength=0.012, sat=0.3)

# ---------------------------------------------------------------- camera: slightly from the right and above, 50 mm
if SHOT == 'settings':
    LENS = 85.0; VW = 178.0; CZT_ = ZT - 52.0
    cam = look_camera((0, RIB_FACE, CZT_ + 46.0 - VW * RES[1] / RES[0] / 2), 0, 0, VW * LENS / 36.0, lens=LENS)
elif ORIENT == 'portrait':
    LENS = 50.0; VW = float(arg('--vw', '560'))
    TZ = (TOP + 90 + RZ - 250) / 2
    cam = look_camera((BX + 2, RIB_FACE, TZ), float(arg('--yaw', '7')), float(arg('--pitch', '4')), VW * LENS / 36.0, lens=LENS)
else:
    LENS = 50.0; VH = float(arg('--vh', '560')); VW = VH * RES[0] / RES[1]
    CXL = (X0 - FR + RX + RW / 2) / 2
    cam = look_camera((CXL, RIB_FACE, (ZT + ZB) / 2 - 6), float(arg('--yaw', '6')), float(arg('--pitch', '3')), VW * LENS / 36.0, lens=LENS)
cam.data.dof.use_dof = True; cam.data.dof.focus_object = None
cam.data.dof.focus_distance = (cam.location - Vector((BX, RIB_FACE, (ZT + ZB) / 2))).length
cam.data.dof.aperture_fstop = 4.0 / 1000.0          # scene unit = 1 mm: f/4 equivalent

# ---------------------------------------------------------------- hits
scene.render.resolution_x, scene.render.resolution_y = RES; scene.render.resolution_percentage = 100
bpy.context.view_layer.update()
W, H = RES; DP = W / 412.0 if ORIENT == 'portrait' else H / 412.0
def px_rect(pts):
    p = project(pts); xs = [q[0] * W for q in p]; ys = [q[1] * H for q in p]
    return [round(min(xs)), round(min(ys)), round(max(xs) - min(xs)), round(max(ys) - min(ys))]
def quad(x0, x1, z0, z1, y=RIB_FACE - 3): return [(x0, y, z0), (x1, y, z0), (x1, y, z1), (x0, y, z1)]
items = []
for r in rows:
    ws = [o.matrix_world @ Vector(v) for o in r['objs'] for v in o.bound_box]
    x0, x1 = min(v.x for v in ws), max(v.x for v in ws); z0, z1 = min(v.z for v in ws), max(v.z for v in ws)
    tr = px_rect(quad(x0, x1, z0, z1))
    bz0, bz1 = r['band']; bx0, bx1 = r['bx']
    hr = px_rect(quad(bx0, bx1, bz0, bz1))
    capr = px_rect([(x0, RIB_FACE - 3, r['base']), (x0, RIB_FACE - 3, r['base'] + r['cap'])])
    items.append({'id': r['id'], 'label': r['label'], 'text_rect': tr, 'hit_rect': hr, 'cap_px': capr[3],
                  'hit_dp': [round(hr[2] / DP, 1), round(hr[3] / DP, 1)],
                  'pressed_sprite': 'menu_pressed_%s%s.png' % (r['id'], '' if ORIENT == 'portrait' else '_landscape')})
board = px_rect(quad(X0 - FR, X0 + IW + FR, ZB - FR, ZT + FR))
if SHOT == 'settings':
    objs, base = title_rows[0]
    ws = [o.matrix_world @ Vector(v) for o in objs for v in o.bound_box]
    x0, x1, z0, z1 = min(v.x for v in ws), max(v.x for v in ws), min(v.z for v in ws), max(v.z for v in ws)
    items.append({'id': 'back', 'label': '‹ WSTECZ', 'text_rect': px_rect([(x0, RIB_FACE - 3, z0), (x1, RIB_FACE - 3, z1)]),
                  'hit_rect': px_rect([(x0 - 10, RIB_FACE - 3, (z0 + z1) / 2 - 11), (x1 + 10, RIB_FACE - 3, (z0 + z1) / 2 + 11)])})
    for it in CARD_ITEMS:
        b0, b1 = it['band']
        hr = px_rect([(CXL_ + 4, CY, b0), (CXL_ + CW - 4, CY, b1)])
        toks = []
        for tid, o in it['tokens']:
            ws = [o.matrix_world @ Vector(v) for v in o.bound_box]
            toks.append({'id': tid, 'text_rect': px_rect([(min(v.x for v in ws), CY, min(v.z for v in ws)), (max(v.x for v in ws), CY, max(v.z for v in ws))])})
        capr = px_rect([(CXL_, CY, it['base']), (CXL_, CY, it['base'] + 6.2 * 0.57)])
        items.append({'id': it['id'], 'hit_rect': hr, 'hit_dp': [round(hr[2] / DP, 1), round(hr[3] / DP, 1)], 'cap_px': capr[3], 'tokens': toks})
os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
if CROP_ROW < 0:
    with open(HITS, 'w') as f:
        json.dump({'image': os.path.basename(OUT), 'width': W, 'height': H, 'orient': ORIENT, 'px_per_dp': round(DP, 4),
                   'dp_basis': '412 dp across the short side', 'rect': '[x, y, w, h] px, origin top-left',
                   'board_rect': board, 'locale': 'pl',
                   'note': 'hit_rect = the whole felt band of the item (>= 48 dp tall); pressed_sprite = the baked pressed state, '
                           'rendered over exactly hit_rect (+20 px margin, see pressed_margin_px), paste at hit_rect.xy - margin',
                   'pressed_margin_px': 20, 'items': items}, f, indent=1)
    print('HITS', HITS)
    for it in items: print('ITEM', it['id'], it['hit_rect'], it.get('hit_dp'), 'cap', it.get('cap_px'))

# ---------------------------------------------------------------- render
crop = None
if CROP_ROW >= 0:
    x, y, w, h = items[CROP_ROW]['hit_rect']; m = 20
    crop = (max(0, (x - m) / W), max(0, 1 - (y + h + m) / H), min(1, (x + w + m) / W), min(1, 1 - (y - m) / H))
render_setup(OUT, RES, SAMPLES, crop=crop, exposure=float(arg('--exposure', '0.0')), look='AgX - Medium High Contrast', bounces=8)
scene.cycles.adaptive_threshold = 0.01
scene.cycles.seed = 3
photo_finish(0.30, dispersion=0.004)
if '--norender' not in sys.argv:
    bpy.ops.render.render(write_still=True)
print('WROTE', scene.render.filepath)
