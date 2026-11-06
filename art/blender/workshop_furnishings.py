# Lockwright — cosmetic workshop furnishings (D-71): one Blender collection per item, built into the workshop
# scene of art/blender/workshop.py and rendered as variant layers (`--layers DIR`). Every item is invented, generic
# and unbranded; no text, logos or real products. Ids match game/data/furnishings.json.
#   plant          geranium in a terracotta pot on the bench, by the wall
#   rug            woven runner on the floor under the bench
#   shelf_light    warm light strip under the showcase shelf (lights the key-blank board)
#   radio          small valve radio in a walnut cabinet, bench back left
#   certificate    framed journeyman's certificate (ruled lines + wax seal, no text) above the showcase
#   case_velvet    showcase: burgundy velvet bed, brass plaques, second warm light
#   clock          round workshop wall clock between the key board and the pegboard
#   thanks_cards   clients' thank-you cards clipped to the pegboard
#   vise           graphite swivel bench vise with brass jaw covers (replaces the teal vise)
#   exhibit_shelf  oak pegboard shelf with three old locks
import bpy, bmesh, math, random
from mathutils import Vector, Matrix
from env_common import *
from env_common import _bev, _noise, _mix, _maprange, _math, _sep, _bump, _ramp

IDS = ['plant', 'rug', 'shelf_light', 'radio', 'certificate', 'case_velvet', 'clock', 'thanks_cards', 'vise', 'exhibit_shelf']
# Items that replace part of the base scene: the base objects in this collection are hidden when the item is shown.
REPLACES = {'vise': 'base_vise'}


_open = []  # (collection, objects that existed before begin())


def begin(name):
    """Create a collection under the scene root; every object created until end() is moved into it."""
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[name]
    _open.append((col, set(bpy.data.objects)))
    return col


def end():
    # some helpers (bpy.ops, curve objects) can link to another collection than the active one: move them all
    col, before = _open.pop()
    for o in bpy.data.objects:
        if o not in before:
            for c in list(o.users_collection):
                if c != col:
                    c.objects.unlink(o)
            if col not in o.users_collection:
                col.objects.link(o)
    bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection


def ico(name, r, loc, scale=(1, 1, 1), mat=None, subdiv=2):
    me = bpy.data.meshes.new(name); bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=r)
    bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    o.location = loc; o.scale = scale
    for p in me.polygons: p.use_smooth = True
    if mat: me.materials.append(mat)
    return o


def woven(name, stops, pitch=38.0, axis='X', seed=0):
    """Flat-woven wool: colour bands across `axis` (stops = [(pos 0..1, rgb)]), weave bump, fibre fuzz."""
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; l = nt.links; b = nt.nodes['Principled BSDF']
    P = nt.nodes.new('ShaderNodeTexCoord').outputs['Object']; X, Y, Z = _sep(nt, P)
    u = {'X': X, 'Y': Y}[axis]; v = {'X': Y, 'Y': X}[axis]
    band = _math(nt, 'FRACT', _math(nt, 'DIVIDE', u, pitch * len(stops)))
    col = _ramp(nt, band, stops, interp='CONSTANT')
    weave = _math(nt, 'MULTIPLY', _math(nt, 'SINE', _math(nt, 'MULTIPLY', u, 1.6)), _math(nt, 'SINE', _math(nt, 'MULTIPLY', v, 1.6)))
    col = _mix(nt, col, (0.02, 0.015, 0.01, 1), _maprange(nt, _noise(nt, P, 0.01, detail=6, rough=0.7), 0.45, 0.8, 0, 0.45))
    l.new(col, b.inputs['Base Color'])
    b.inputs['Roughness'].default_value = 0.95; b.inputs['Sheen Weight'].default_value = 0.6
    l.new(_bump(nt, _math(nt, 'ADD', _math(nt, 'MULTIPLY', weave, 0.5), _noise(nt, P, 1.2, detail=4)), 0.35, 0.8), b.inputs['Normal'])
    return m


def build(g):
    """g = globals() of workshop.py (materials, bench constants, helpers). Returns {id: collection}."""
    rng = random.Random(71)
    BZ, CX0, CX1, CY0, CY1, CZ0, CZ1 = g['BZ'], g['CX0'], g['CX1'], g['CY0'], g['CY1'], g['CZ0'], g['CZ1']
    SH_Z, PY = g['SH_Z'], g['PY']
    brass, bright, iron_old, nickel = g['brass'], g['bright'], g['iron_old'], g['nickel']
    black_pl, label_m, glass_m, cotton = g['black_pl'], g['label_m'], g['glass_m'], g['cotton']
    out = {}

    # ------------------------------------------------------------ plant: geranium on the bench, by the wall under the clock
    out['plant'] = begin('furn_plant')
    PX, PY_, PZ = -5, -115, BZ
    terracotta = plastic('terracotta', (0.42, 0.16, 0.075), rough=0.85, seed=3, grime=0.7)
    saucer = lathe('pot_saucer', [(0.1, PZ), (62, PZ), (66, PZ + 12), (60, PZ + 12), (58, PZ + 4), (0.1, PZ + 4)], PX, PY_, seg=48)
    setmat(saucer, terracotta)
    pot = lathe_open('pot', [(42, PZ + 4), (44, PZ + 6), (54, PZ + 80), (60, PZ + 82), (60, PZ + 96), (55, PZ + 97)], PX, PY_, thick=4, mat=terracotta)
    soil = plastic('soil', (0.05, 0.035, 0.025), rough=0.95, grime=0.0)
    cyl('pot_soil', 53, 4, (PX, PY_, PZ + 86), verts=48).data.materials.append(soil)
    leaf = plastic('leaf', (0.07, 0.17, 0.045), rough=0.55, seed=5, grime=0.2)
    leaf_d = plastic('leaf_dark', (0.035, 0.10, 0.03), rough=0.6, seed=6, grime=0.2)
    stem = plastic('stem', (0.16, 0.22, 0.08), rough=0.6, grime=0.0)
    bloom = plastic('bloom', (0.62, 0.05, 0.05), rough=0.45, grime=0.0)
    base = Vector((PX, PY_, PZ + 88))
    for k in range(22):
        a = rng.uniform(0, 2 * math.pi); r = rng.uniform(25, 62); h = rng.uniform(15, 60)
        tip = base + Vector((math.cos(a) * r, math.sin(a) * r * 0.8, h))
        tube('stem', [base + Vector((math.cos(a) * 10, math.sin(a) * 10, 0)), base + (tip - base) * 0.6 + Vector((0, 0, 12)), tip], 2.0, stem)
        lf = ico('leaf', rng.uniform(24, 34), tip, scale=(1.0, 1.0, 0.18), mat=leaf if k % 3 else leaf_d)
        lf.rotation_euler = (rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6), rng.uniform(0, 6.28))
    for k in range(3):
        a = k * 2.1 + 0.4
        top = base + Vector((math.cos(a) * 40, math.sin(a) * 30, rng.uniform(85, 105)))
        tube('flower_stem', [base, base + (top - base) * 0.5 + Vector((math.cos(a) * 8, 0, 0)), top], 1.8, stem)
        for n in range(14):
            d = Vector((rng.gauss(0, 1), rng.gauss(0, 1), rng.gauss(0, 0.6))).normalized() * rng.uniform(4, 16)
            ico('petal', rng.uniform(5, 7), top + d, scale=(1, 1, 0.6), mat=bloom, subdiv=1)
    end()

    # ------------------------------------------------------------ rug: woven runner under the bench
    out['rug'] = begin('furn_rug')
    rug_m = woven('rug_wool', [(0.0, (0.30, 0.045, 0.03)), (0.22, (0.50, 0.33, 0.10)), (0.34, (0.30, 0.045, 0.03)),
                               (0.56, (0.05, 0.08, 0.16)), (0.68, (0.62, 0.56, 0.44)), (0.80, (0.05, 0.08, 0.16))], pitch=30, axis='X')
    bx('rug', -880, 880, -640, -60, 0, 6, rug_m, bev=2.5, seg=2)
    for y in range(-634, -60, 14):  # fringe at both short ends
        for s in (-1, 1):
            tube('fringe', [(s * 882, y, 3), (s * rng.uniform(905, 920), y + rng.uniform(-4, 4), 1)], 1.3, cotton, res=2)
    end()

    # ------------------------------------------------------------ shelf light: warm strip under the showcase shelf
    out['shelf_light'] = begin('furn_shelf_light')
    alu_s = metal('strip_alu', (0.62, 0.62, 0.62), 0.35, marks='grind', marks_scale=2, wear=0.2, grime=0.3, bevel_r=0.3)
    sx0, sx1 = g['SX0_'] + 40, g['SX1_'] - 40
    bx('strip_body', sx0, sx1, -210, -190, SH_Z - 40, SH_Z - 28, alu_s, bev=1)
    bx('strip_diffuser', sx0 + 4, sx1 - 4, -208, -192, SH_Z - 41, SH_Z - 40, emissive('strip_glow', (1.0, 0.76, 0.5), 8.0, (0.9, 0.88, 0.84)))
    tube('strip_cable', [(sx1, -200, SH_Z - 34), (sx1 + 20, -60, SH_Z - 34), (sx1 + 30, -8, SH_Z - 120), (sx1 + 34, -8, BZ + 4)], 2.2, black_pl)
    aim = bpy.data.objects.new('aim_strip', None); bpy.context.collection.objects.link(aim); aim.location = ((sx0 + sx1) / 2, -10, 1080)
    area_light('strip_light', ((sx0 + sx1) / 2, -200, SH_Z - 44), aim, sx1 - sx0, 1.6e6, (1.0, 0.76, 0.5), size_y=16)
    end()

    # ------------------------------------------------------------ radio: small valve radio, bench back left
    out['radio'] = begin('furn_radio')
    RX, RY0, RY1 = -390, -215, -60
    walnut = oak('radio_walnut', light=(0.28, 0.15, 0.07), dark=(0.09, 0.045, 0.02), axis='X', seed=21, ring=2.2, coat=1.0, coat_rough=0.15,
                 varnish_tint=0.3, center=(RX, RY0, BZ + 100))
    bx('radio_case', RX - 160, RX + 160, RY0, RY1, BZ + 6, BZ + 196, walnut, bev=12, seg=4)
    for sx in (-1, 1):
        cyl('radio_foot', 9, 6, (RX + sx * 130, (RY0 + RY1) / 2, BZ + 3), verts=24).data.materials.append(black_pl)
    grille = woven('radio_cloth', [(0.0, (0.36, 0.28, 0.17)), (0.5, (0.30, 0.23, 0.14))], pitch=1.6, axis='X')
    bx('radio_grille', RX - 140, RX + 10, RY0 - 1.5, RY0 + 2, BZ + 30, BZ + 172, grille, bev=4)
    for k in range(4):  # wooden slats over the cloth
        x = RX - 118 + k * 38
        bx('radio_slat', x - 5, x + 5, RY0 - 5, RY0, BZ + 32, BZ + 170, walnut, bev=2)
    dial_paper = paper('radio_dial', (0.82, 0.74, 0.55), fibre=0.4, seed=9, grime=0.3, lines=(6.0, 'X', (0.25, 0.18, 0.10)))
    bx('radio_dial', RX + 30, RX + 140, RY0 - 1, RY0 + 1, BZ + 110, BZ + 170, dial_paper)
    bx('radio_dial_glass', RX + 26, RX + 144, RY0 - 3, RY0 - 1.5, BZ + 106, BZ + 174, glass_m)
    bx('radio_needle', RX + 78, RX + 80, RY0 - 1.6, RY0 - 1.2, BZ + 114, BZ + 166, g['red_dip'])
    trim = slab('radio_trim', rounded_rect(124, 74, 6), 2, brass, bev=0.5)
    cut(trim, place(slab('trim_win', rounded_rect(114, 64, 4), 8), (0, 0, -3)))
    place(trim, (RX + 85, RY0 - 3, BZ + 140), rot=(90, 0, 0))
    for x in (RX + 50, RX + 120):
        k_ = cyl('radio_knob', 16, 18, (x, RY0 - 9, BZ + 62), axis='Y', verts=40); setmat(k_, plastic('bakelite', (0.08, 0.035, 0.02), rough=0.25)); _bev(k_, 2, 3)
        bx('radio_knob_mark', x - 1.2, x + 1.2, RY0 - 18.5, RY0 - 17.9, BZ + 66, BZ + 76, label_m)
    tube('radio_cable', [(RX + 150, RY1, BZ + 20), (RX + 200, RY1 + 30, BZ + 2), (RX + 260, -40, BZ + 1)], 2.4, black_pl)
    end()

    # ------------------------------------------------------------ certificate: framed, above the showcase
    out['certificate'] = begin('furn_certificate')
    FX, FZ = -215, 1688
    frame_w = oak('cert_frame', light=(0.20, 0.10, 0.045), dark=(0.07, 0.035, 0.015), axis='X', seed=33, ring=3.0, coat=1.0, coat_rough=0.2,
                  center=(FX, -10, FZ))
    for x0, x1, z0, z1 in ((FX - 80, FX + 80, FZ + 45, FZ + 58), (FX - 80, FX + 80, FZ - 58, FZ - 45),
                           (FX - 80, FX - 67, FZ - 45, FZ + 45), (FX + 67, FX + 80, FZ - 45, FZ + 45)):
        bx('cert_frame', x0, x1, -22, -2, z0, z1, frame_w, bev=1.5)
    bx('cert_mat', FX - 68, FX + 68, -12, -10, FZ - 46, FZ + 46, paper('cert_mat', (0.80, 0.77, 0.68), fibre=0.5, seed=11))
    cert_p = paper('cert_paper', (0.86, 0.82, 0.70), fibre=0.8, seed=12, grime=0.25, lines=(7.0, 'Z', (0.30, 0.26, 0.20)))
    bx('cert_sheet', FX - 48, FX + 48, -13, -12, FZ - 32, FZ + 22, cert_p)
    bx('cert_head', FX - 34, FX + 34, -13.2, -12.6, FZ + 28, FZ + 35, paper('cert_head', (0.25, 0.10, 0.06), fibre=0.2))
    seal = cyl('cert_seal', 9, 2.5, (FX + 28, -13.5, FZ - 24), axis='Y', verts=32); setmat(seal, plastic('wax', (0.42, 0.03, 0.025), rough=0.35))
    bx('cert_glass', FX - 69, FX + 69, -17, -16, FZ - 47, FZ + 47, glass_m)
    tube('cert_wire', [(FX - 50, -6, FZ + 46), (FX, -4, FZ + 80), (FX + 50, -6, FZ + 46)], 0.8, bright, smooth_pts=False)
    end()

    # ------------------------------------------------------------ showcase upgrade: velvet bed, plaques, second light
    out['case_velvet'] = begin('furn_case_velvet')
    velvet = bpy.data.materials.new('velvet'); velvet.use_nodes = True; vb = velvet.node_tree.nodes['Principled BSDF']
    vb.inputs['Base Color'].default_value = (0.085, 0.012, 0.016, 1); vb.inputs['Roughness'].default_value = 1.0
    vb.inputs['Sheen Weight'].default_value = 0.6; vb.inputs['Sheen Roughness'].default_value = 0.4
    vb.inputs['Sheen Tint'].default_value = (0.9, 0.55, 0.5, 1)
    bx('case_velvet', CX0 + 14, CX1 - 14, CY0 + 14, CY1 - 20, CZ0 + 47.6, CZ0 + 48.4, velvet)
    bx('case_back_velvet', CX0 + 19, CX1 - 19, CY1 - 21, CY1 - 20.4, CZ0 + 48, CZ1 - 19, velvet)
    for x in (-470, -333, -160):
        p_ = bx('case_plaque', x - 26, x + 26, CY0 + 26, CY0 + 28, CZ0 + 49, CZ0 + 63, brass, bev=0.5)
        p_.rotation_euler = (math.radians(-25), 0, 0)
        bx('case_plaque_line', x - 18, x + 18, CY0 + 25.4, CY0 + 25.9, CZ0 + 55, CZ0 + 57, g['dark_steel'])
    aim2 = bpy.data.objects.new('aim_case2', None); bpy.context.collection.objects.link(aim2)
    aim2.location = ((CX0 + CX1) / 2, CY1 - 40, CZ0 + 60)
    area_light('case_light2', ((CX0 + CX1) / 2, CY0 + 30, CZ1 - 22), aim2, 420, 2.5e5, (1.0, 0.82, 0.62), size_y=30)
    end()

    # ------------------------------------------------------------ clock: wall clock between the key board and the pegboard
    out['clock'] = begin('furn_clock')
    KX, KY, KZ, R = -100, -10, 1062, 66
    rim = oak('clock_rim', light=(0.42, 0.26, 0.12), dark=(0.20, 0.11, 0.05), axis='Z', seed=41, ring=2.0, coat=1.0, coat_rough=0.15,
              center=(KX, KY, KZ))
    o = cyl('clock_body', R, 26, (KX, KY - 13, KZ), axis='Y', verts=96); setmat(o, rim); _bev(o, 4, 4)
    face = cyl('clock_face', R - 9, 2, (KX, KY - 27, KZ), axis='Y', verts=96); setmat(face, paper('clock_dial', (0.88, 0.85, 0.76), fibre=0.3, seed=2, grime=0.15))
    ink = g['black_pl']
    for h in range(12):
        a = math.radians(h * 30); L = 9 if h % 3 == 0 else 5; w = 2.0 if h % 3 == 0 else 1.0
        c = Vector((KX + math.sin(a) * (R - 18), KY - 28.2, KZ + math.cos(a) * (R - 18)))
        mk = bx('clock_tick', -w, w, -0.3, 0.3, -L / 2, L / 2, ink); mk.location = c; mk.rotation_euler = (0, a, 0)
    for ang, L, w, mat, y in ((-58, 34, 2.4, ink, -29.0), (122, 46, 1.6, ink, -29.6), (200, 50, 0.6, g['red_dip'], -30.2)):
        hd = bx('clock_hand', -w, w, -0.3, 0.3, -6, L, mat); hd.location = (KX, KY + y, KZ); hd.rotation_euler = (0, math.radians(ang), 0)
    cyl('clock_hub', 3.2, 3, (KX, KY - 30.5, KZ), axis='Y', verts=24).data.materials.append(brass)
    gl = lathe_open('clock_glass', [(0.1, 4), (R - 10, 0)], 0, 0, seg=96, thick=0.6, mat=glass_m)
    gl.rotation_euler = (math.radians(90), 0, 0); gl.location = (KX, KY - 30, KZ)
    tube('clock_nail', [(KX, 0, KZ + R - 8), (KX, -14, KZ + R - 6)], 1.4, bright)
    end()

    # ------------------------------------------------------------ thank-you cards clipped to the pegboard (lower left)
    out['thanks_cards'] = begin('furn_thanks_cards')
    card_cols = [(0.86, 0.83, 0.74), (0.72, 0.80, 0.86), (0.90, 0.80, 0.62), (0.84, 0.86, 0.80), (0.86, 0.74, 0.70)]
    clip_m = g['clip_m']
    xs = [10, 72, 140, 205]
    for k, x in enumerate(xs):
        w, h = rng.choice(((54, 78), (78, 54), (60, 84))); z = 1300 - rng.uniform(0, 14)
        M = Matrix.Translation(Vector((x + w / 2, PY - 1.5 - k * 0.3, z - h / 2))) @ Matrix.Rotation(math.radians(rng.uniform(-5, 5)), 4, 'Y')
        cm = paper('card%d' % k, card_cols[k % len(card_cols)], fibre=0.6, seed=20 + k, grime=0.1,
                   lines=(5.0, 'Z', (0.18, 0.20, 0.30)) if k % 2 else None)
        c = bx('card', -w / 2, w / 2, -0.4, 0.4, -h / 2, h / 2, cm); c.matrix_world = M
        if k == 2:  # a child's drawing: a house and a key in crayon blobs
            for (u, v, col) in ((-12, -8, (0.6, 0.08, 0.05)), (10, -10, (0.08, 0.25, 0.55)), (0, 14, (0.85, 0.6, 0.05))):
                d = bx('crayon', -9, 9, -0.6, -0.4, -7, 7, plastic('crayon%d' % u, col, rough=0.9, grime=0.0)); d.matrix_world = M @ Matrix.Translation(Vector((u, 0, v)))
        bx('card_clip', x + w / 2 - 10, x + w / 2 + 10, PY - 6, PY - 1, z - 6, z + 8, clip_m, bev=0.8)
    end()

    # ------------------------------------------------------------ swivel vise (replaces the painted vise)
    out['vise'] = begin('furn_vise')
    VX, VY = g['VX'], g['VY']
    ox = paint('vise2_paint', (0.035, 0.04, 0.045), rough=0.3, metal_col=(0.42, 0.42, 0.41), chip=0.4, grime=0.6)
    base_ = cyl('vise2_base', 92, 16, (VX, VY - 10, BZ + 8), verts=96); setmat(base_, ox); _bev(base_, 3, 3)
    ring = cyl('vise2_ring', 96, 4, (VX, VY - 10, BZ + 14), verts=96); setmat(ring, g['steel'])
    for k in range(36):  # degree ticks on the swivel ring
        a = math.radians(k * 10 + 5)
        t = bx('vise2_tick', -0.6, 0.6, -5 if k % 9 else -9, 0, 0, 0.5, g['dark_steel'])
        t.matrix_world = Matrix.Translation(Vector((VX + math.sin(a) * 96, VY - 10 - math.cos(a) * 96, BZ + 16))) @ Matrix.Rotation(-a, 4, 'Z')
    turn = cyl('vise2_turntable', 70, 14, (VX, VY - 10, BZ + 23), verts=96); setmat(turn, ox); _bev(turn, 3, 3)
    lk = tube('vise2_lock', [(VX + 70, VY - 40, BZ + 26), (VX + 118, VY - 70, BZ + 30)], 4.5, bright)
    lb = ico('vise2_lock_ball', 9, (VX + 120, VY - 72, BZ + 31), mat=black_pl)
    def casting(name, prof, half_w):
        o = prism(name, prof, -half_w, half_w)
        o.data.transform(Matrix.Translation(Vector((VX, VY, BZ + 16))) @ Matrix.Rotation(math.radians(90), 4, 'Z'))
        setmat(o, ox); _bev(o, 6, 4, 30); return o
    casting('vise2_rear', [(-4, 14), (58, 14), (76, 30), (80, 64), (66, 94), (40, 110), (-4, 110)], 62)
    bx('vise2_slide', VX - 30, VX + 30, VY - 200, VY + 40, BZ + 52, BZ + 100, bright, bev=2)
    casting('vise2_front', [(-86, 38), (-30, 38), (-30, 110), (-56, 110), (-76, 94), (-86, 66)], 62)
    for y0, y1 in ((VY - 2, VY + 6), (VY - 34, VY - 26)):  # brass jaw covers
        bx('vise2_jaw', VX - 64, VX + 64, y0, y1, BZ + 100, BZ + 134, brass, bev=1)
    lathe_x('vise2_screw', [(0, 0.01), (0, 11), (150, 11), (150, 0.01)], seg=32).data.materials.append(bright)
    s_ = bpy.data.objects['vise2_screw']; s_.data.transform(Matrix.Rotation(math.radians(-90), 4, 'Z')); s_.location = (VX, VY - 85, BZ + 76)
    boss = cyl('vise2_boss', 20, 36, (VX, VY - 240, BZ + 76), axis='Y', verts=48); setmat(boss, ox); _bev(boss, 2, 3)
    tb = cyl('vise2_tbar', 7, 240, (VX + 40, VY - 255, BZ + 76), axis='X', verts=24); setmat(tb, bright)
    for x in (VX + 40 - 125, VX + 40 + 125):
        o = lathe_x('vise2_knob', [(0, 0.01), (0, 9), (3, 12), (14, 12), (17, 9), (18, 0.01)], seg=32); o.location = (x - 9, VY - 255, BZ + 76); setmat(o, brass)
    # the practice cylinder stays clamped (same as the base scene, a little higher)
    PCX, PCZ = VX, BZ + 134
    body = lathe('vise2_pc', [(0.1, PCZ - 40), (11, PCZ - 40), (11.4, PCZ + 48), (10, PCZ + 50), (0.1, PCZ + 50)], PCX, VY - 14, seg=64)
    setmat(body, nickel)
    lathe('vise2_pc_face', [(0.1, PCZ + 50), (8.5, PCZ + 50), (9, PCZ + 52), (0.1, PCZ + 52)], PCX, VY - 14, seg=48).data.materials.append(brass)
    end()

    # ------------------------------------------------------------ exhibit shelf on the pegboard (lower right)
    out['exhibit_shelf'] = begin('furn_exhibit_shelf')
    SZ = 1032; ESX0, ESX1 = 140, 530
    board = oak('exh_oak', light=(0.62, 0.44, 0.24), dark=(0.36, 0.22, 0.10), axis='X', seed=55, ring=2.6, coat=0.8, coat_rough=0.25,
                center=((ESX0 + ESX1) / 2, -80, SZ))
    bx('exh_board', ESX0, ESX1, PY - 130, PY, SZ - 18, SZ, board, bev=2)
    bx('exh_lip', ESX0, ESX1, PY - 136, PY - 128, SZ - 18, SZ + 10, board, bev=1.5)
    for x in (ESX0 + 30, ESX1 - 30):
        tube('exh_bracket', [(x, PY, SZ - 120), (x, PY, SZ - 18), (x, PY - 110, SZ - 18), (x, PY, SZ - 120)], 4, g['vice_paint'], smooth_pts=False)
    E = SZ
    # (1) iron rim lock standing on its edge, with a keyhole
    rl = bx('exh_rimlock', 160, 260, PY - 90, PY - 66, E, E + 120, brass, bev=2)
    cut(rl, prism('exh_kh', [(205, E + 80), (215, E + 80), (213, E + 62), (217, E + 44), (203, E + 44), (207, E + 62)], PY - 120, PY - 60))
    bx('exh_rim_back', 164, 256, PY - 66, PY - 62, E + 4, E + 116, g['void'])
    for x, z in ((168, E + 10), (252, E + 10), (168, E + 110), (252, E + 110)):
        screw_head('exh_screw', (x, PY - 90.5, z), 4, 2, axis='-Y', mat=iron_old, rot=rng.uniform(0, 3))
    # (2) large old key on a small oak stand
    bx('exh_stand', 310, 380, PY - 85, PY - 45, E, E + 10, board, bev=1.5)
    k_ = lathe_x('exh_key', [(0, 0.01), (0, 5), (110, 5), (112, 7), (118, 7), (120, 5), (124, 5), (124, 0.01)], seg=24)
    k_.location = (300, PY - 65, E + 22); k_.rotation_euler = (0, math.radians(-12), 0); setmat(k_, iron_old)
    tube('exh_key_bow', [(300 + 18 * math.cos(a) - 18, PY - 65, E + 22 + 18 * math.sin(a) - 3.8) for a in [i * math.pi / 8 for i in range(17)]], 4, iron_old)
    bx('exh_key_bit', 408, 420, PY - 68, PY - 62, E + 22 + 25 - 30, E + 22 + 25 - 6, iron_old, bev=0.8)
    # (3) brass ring-combination padlock (three rings, no markings)
    for k in range(3):
        o = cyl('exh_ring', 22, 15, (475, PY - 70, E + 10 + k * 16), verts=48); setmat(o, brass); _bev(o, 1.2, 2)
    tube('exh_shackle', [(463, PY - 70, E + 56), (463, PY - 70, E + 92), (475, PY - 70, E + 104), (487, PY - 70, E + 92), (487, PY - 70, E + 56)], 4, bright)
    for x in (210, 345, 475):
        bx('exh_plaque', x - 18, x + 18, PY - 132, PY - 130, SZ - 14, SZ - 4, brass, bev=0.3)
    end()
    return out
