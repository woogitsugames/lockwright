# Lockwright — settings close-up for menu_gate.py --shot settings: a typed index card pinned to the letter board (exec'd in menu_gate's namespace).
MONO_R = bpy.data.fonts.load(os.path.join(ROOT, 'mockups', 'ui-directions', 'fonts', 'CourierPrime-Regular.ttf'))
MONO_B = bpy.data.fonts.load(os.path.join(ROOT, 'mockups', 'ui-directions', 'fonts', 'CourierPrime-Bold.ttf'))
card_m = paper('card', (0.90, 0.895, 0.87), grime=0.04, seed=4)
card_m.node_tree.nodes['Principled BSDF'].inputs['Specular IOR Level'].default_value = 0.2
ink = dark_mat('ink', (0.018, 0.018, 0.022), rough=0.6)
red = dark_mat('red_ink', (0.40, 0.035, 0.03), rough=0.55)
blue = dark_mat('rule_blue', (0.42, 0.52, 0.62), rough=0.7)
CW, CH = 150.0, 262.0; CXL_ = -CW / 2; CZT_ = ZT - 52.0; CY = RIB_FACE - 3.4      # card front plane (y)
# card: subdivided sheet, the bottom-right corner curls towards the camera
import bmesh as _bm
bm = _bm.new(); NU, NV = 30, 52
vs = [[bm.verts.new((CXL_ + CW * i / NU, CY + 0.3, CZT_ - CH * j / NV)) for i in range(NU + 1)] for j in range(NV + 1)]
for j in range(NV):
    for i in range(NU): bm.faces.new((vs[j][i], vs[j][i + 1], vs[j + 1][i + 1], vs[j + 1][i]))
for j in range(NV + 1):
    for i in range(NU + 1):
        u, v = i / NU, 1 - j / NV
        c = max(0.0, (u - 0.72) / 0.28) * max(0.0, (0.07 - v) / 0.07); vs[j][i].co.y -= 9.0 * c * c
me = bpy.data.meshes.new('card'); bm.to_mesh(me); bm.free()
co = bpy.data.objects.new('card', me); bpy.context.collection.objects.link(co); co.data.materials.append(card_m)
sm = co.modifiers.new('sol', 'SOLIDIFY'); sm.thickness = 0.3; smooth(co)
def strip(name, x0, x1, z0, z1, mat):
    return bx(name, x0, x1, CY - 0.06, CY - 0.02, z0, z1, mat)
def typed(name, text, x, base, em=6.2, bold=False, mat=None):
    cu = bpy.data.curves.new(name, 'FONT'); cu.body = text; cu.size = em; cu.font = MONO_B if (bold or em > 5.5) else MONO_R
    cu.align_x = 'LEFT'; cu.align_y = 'BOTTOM_BASELINE'; cu.extrude = 0.0; cu.fill_mode = 'BOTH'
    o = bpy.data.objects.new(name, cu); bpy.context.collection.objects.link(o); o.data.materials.append(mat or ink)
    o.rotation_euler = (math.radians(90), math.radians(rng.uniform(-0.25, 0.25)), 0)
    o.location = (x, CY - 0.08, base + rng.uniform(-0.12, 0.12)); return o
ADV = 6.2 * 0.6; LM = CXL_ + 10.0
col = lambda n: LM + n * ADV
z = CZT_ - 9.0
def line(h): 
    global z
    top = z; z -= h; return top, z
t, b = line(18); typed('hdr', 'KARTA USTAWIEŃ', col(0), b + 6, bold=True); typed('hdr2', 'dyżurny: ty', col(21), b + 6, em=5.0)
strip('hdr_rule', CXL_ + 6, CXL_ + CW - 6, b + 2.2, b + 3.0, red)
def section(name):
    t, b = line(11); typed('sec_' + name, name, col(0), b + 2.5, em=5.0, bold=True, mat=red)
def ctl(rid, label, tokens, h=21.0, lab_bold=False):
    t, b = line(h); base = b + h * 0.36
    if label: typed(rid + '_l', label, col(0), base, bold=lab_bold)
    objs = []
    for tid, n, txt, bold in tokens:
        o = typed(rid + '_' + tid, txt, col(n), base, bold=bold); objs.append((tid, o))
    strip(rid + '_rule', CXL_ + 6, CXL_ + CW - 6, b + 0.6, b + 0.9, blue)
    CARD_ITEMS.append({'id': rid, 'band': (b, t), 'tokens': objs, 'base': base})
scale = lambda v: '0 ' + '=' * (round(v / 10) - 1) + '|' + '·' * (10 - round(v / 10))
section('HAPTYKA')
ctl('haptics', 'Haptyka', [('on', 17, '[X] wł.', True), ('off', 26, '[ ] wył.', False)])
ctl('intensity', 'Intensywność', [('scale', 16, scale(100) + ' 100%', False)])
ctl('test_pulse', None, [('button', 0, '[ IMPULS PRÓBNY ]', True)])
section('DŹWIĘK')
ctl('master', 'Głośność gł.', [('scale', 16, scale(100) + ' 100%', False)])
ctl('sfx', 'Efekty', [('scale', 16, scale(100) + ' 100%', False)])
ctl('ambient', 'Tło', [('scale', 16, scale(80) + '  80%', False)])
section('STEROWANIE')
t, b = line(9); typed('auto_l', 'Napięcie automatyczne', col(0), b + 1.5)
ctl('auto_tension', None, [('on', 0, '[ ] wł.', False), ('off', 9, '[X] wył.', True)], h=21.0)
t, b = line(15)
typed('note1', 'Napięcie trzyma się samo, a ty', col(0), b + 8.5, em=4.6); typed('note2', 'prowadzisz wytrych jednym kciukiem.', col(0), b + 3.0, em=4.6)
ctl('language', 'Język', [('pl', 9, '[X] polski', True), ('en', 21, '[ ] English', False)])
# thumbtack through the top of the card
tk = cyl('tack_head', 5.5, 1.3, (0, CY - 1.2, CZT_ - 5.0), axis='Y', verts=48); setmat(tk, alu); _bev(tk, 0.5, 3)
dm = screw_head('tack_dome', (0, CY - 1.9, CZT_ - 5.0), 3.6, 1.6, axis='Y', slot=False, kind='dome', mat=alu)

# ---------------------------------------------------------------- light
