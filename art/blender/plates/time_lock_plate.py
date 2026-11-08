# Lockwright — plan-B plates for the `time_lock` screen (LOCKS.md §2.24, job.museum_time_lock). This is
# a REPAIR: the museum's old time-lock movement has stopped, the locksmith puts its train back in mesh
# and gets it running again (no opening, no vault). Invented, encyclopedic-level movement, front view
# with the front plate removed: the mainspring barrel (wound by the key = left thumb), a train of five
# wheels from the barrel to the escape wheel, a rocking pallet, a small dial whose hand shows the even
# run, and the bolt dog that holds the bolt bar while the movement is set. Every wheel turns when the
# train runs (no dead gears, DESIGN.md).
#   plate.png        lacquered back plate, pillars, pivot bushings, bolt bar and dog (static)
#   front.png        the dial bridge with the dial ring and the barrel click (drawn over the train)
#   wheel0..4.png    train wheels in the SET pose (meshed, on their pivots); the game lowers them from
#                    above by (position - window centre) * travel and turns them when the train runs
#   barrel.png       the barrel with ratchet (turns a little with the key), pallet.png (rocks), hand.png
#   tweezers.png     the tweezers, tip at its anchor
#
# N-86 (2026-11-08) — the VA-09 train read as clip-art: flat identical wheels on one plane, rims
# overlapping tooth-on-tooth. Rebuilt as a real movement with the SAME game geometry (wheel centres,
# pitch radii, pinion radii, barrel, pallet, dial, travel: layers.json keys and pixel values unchanged):
#   - each wheel's pitch radius is the old radius and its pinion the old pinion radius; tooth counts at
#     one module (0.4 mm) so the ratios the game turns the train with (rim / pinion, time_lock_view.gd)
#     are exactly the tooth ratios: barrel 60 -> pinion 13, wheels 45/40/35/30 -> pinions 12/11/10/9;
#     cycloidal clock teeth (ogival addendum, radial flanks, round roots), pinion leaves with round tips;
#   - wheels stacked in depth as in a real train: wheel i+1 lies 1.6 mm in front of wheel i, its pinion
#     reaches back into wheel i's plane and meshes there (the game draws wheel0 first, wheel4 last);
#     each wheel phased so a tooth sits in the space of the pinion it drives in the set pose;
#   - moving parts are warped so they project as at depth 0 (x, z scaled by (d + y) / d about the
#     camera axis): every plane meshes in the picture and the old *_px keys stay exact;
#   - five tapered crossings, steel collets, arbors and conical front pivots; steel bushings with screws
#     on the plate under every pivot; brass barrel (the one brass part) with a windowed cover showing
#     the mainspring, steel ratchet and click; escape wheel with club teeth and a steel anchor;
#   - turned-steel wheels on a black lacquered plate (>= 3:1 in grayscale, plate_contrast.py).
# The ratchet has 30 teeth: the key turns the barrel in 12-degree clicks (2 barrel teeth), so the barrel
# stays in mesh with pinion 0 at every wind (layers.json "wind_step_deg", time_lock_view.gd).
# Run (GPU final; 16 spp + overlay check first):
#   LW_DEVICE=GPU blender -b -P art/blender/plates/time_lock_plate.py -- \
#       --out-dir game/assets/photoreal_families/time_lock/photo --res 1236x1648 --spp 256 --device GPU
import bpy, math, os, sys
from mathutils import Matrix, Vector

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
ROOT_DIR = os.path.abspath(os.path.join(BLENDER_DIR, '..', '..'))
sys.path.insert(0, BLENDER_DIR); sys.path.insert(0, THIS_DIR)
from lw_common import *  # noqa: F401,F403
from layer_plate_common import LayerRig

arg = cli()
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'time_lock', 'photo')))
RES = [int(v) for v in arg('--res', '618x824').split('x')]
SPP = int(arg('--spp', '16'))
DEVICE = arg('--device', 'CPU').upper()
PASSES = arg('--passes', 'plate,front,moving').split(',')

TRAVEL = 6.0                       # mm a wheel is lowered for lockcore position 1.0
BARREL = (-14.0, -24.0, 12.0)      # x, z, pitch radius
MODULE = 0.4
# train wheels: centre x, z, wheel pitch radius, pinion pitch radius; each pinion meshes with the rim before
def _chain():
    # each wheel's pinion meshes with the rim before it: centre distance = rim radius + pinion radius
    out, (x, z, r) = [], BARREL
    for (rr, pr, ang) in [(9.0, 2.6, 60), (8.0, 2.4, 30), (7.0, 2.2, -20), (6.0, 2.0, 30), (5.0, 1.8, -30)]:
        d = r + pr
        x, z = x + d * math.sin(math.radians(ang)), z + d * math.cos(math.radians(ang))
        out.append((round(x, 3), round(z, 3), rr, pr)); r = rr
    return out


TRAIN = _chain()
PALLET = (TRAIN[-1][0], TRAIN[-1][1] + 6.6)
DIAL = (-19.0, 18.0, 9.0)          # small run dial: centre, radius
Y_PLATE, Y_WHEEL = 6.0, 0.0
# depth of each meshing plane (+y = away from the camera): barrel teeth at the back, wheel0 in front of
# the barrel, every next wheel 1.6 mm nearer the camera (the game draws them in this order)
Y_BARREL_TEETH = 4.3
Y_RIM = [1.6, 0.0, -1.6, -3.2, -4.8]
RIM_T = 0.7
N_BARREL = round(2 * BARREL[2] / MODULE)                                   # 60
N_WHEEL = [round(2 * r / MODULE) for (_, _, r, _) in TRAIN[:4]]            # 45, 40, 35, 30
N_PINION = [round(2 * pr / MODULE) for (_, _, _, pr) in TRAIN]             # 13, 12, 11, 10, 9
N_ESCAPE = 15
ESC_PHASE = 30.0                   # tooth tips at 30 + 24 k deg: the pallets (+-48) sit 0.75 pitch behind a tip
RATCHET_TEETH = 30
WIND_STEP = 360.0 / RATCHET_TEETH  # 12 deg = 2 barrel teeth: the barrel stays in mesh at every click
assert abs(360.0 / N_BARREL * round(WIND_STEP * N_BARREL / 360.0) - WIND_STEP) < 1e-9

# Look (N-86): a black lacquered back plate (like the lever and warded cases), turned-steel wheels with
# concentric turning marks, polished steel pinions/arbors, the brass barrel as the one warm part, blued
# screws; every moving part >= 3:1 against the plate in grayscale.
M = {
    'plate': paint('lacquer', (0.013, 0.0125, 0.012), rough=0.36, metal_col=(0.40, 0.40, 0.40), chip=0.35, grime=0.45, peel=0.01),
    'pillar': photo_mat('ph_pillar', 'nickel_satin', scale=10, rot=90, base=(0.58, 0.58, 0.57), base_mix=0.35, rough_add=0.10, bump=0.1, grime=0.6),
    'bridge': photo_mat('ph_bridge', 'nickel_satin', scale=30, rot=90, base=(0.50, 0.50, 0.50), base_mix=0.45, rough_add=0.12, bump=0.12, grime=0.7, wear=0.3),
    'wheel': photo_mat('ph_wheel', 'brass_turned', scale=24, flat=True, base=(0.50, 0.51, 0.53), base_mix=0.55, tint=(0.86, 0.96, 1.14),
                       rough_add=-0.03, bump=0.3, grime=0.5, wear=0.3),
    'barrel': photo_mat('ph_barrel', 'brass_turned', scale=30, flat=True, base=(0.90, 0.70, 0.38), base_mix=0.45, rough_add=0.06, bump=0.12, grime=0.6, wear=0.4),
    'barrel_in': photo_mat('ph_barrel_in', 'brass_patina_grease', scale=30, base=(0.40, 0.29, 0.14), base_mix=0.5, rough_add=0.1, bump=0.1, grime=0.8),
    'steel': photo_mat('ph_steel', 'steel_ground', scale=12, rot=0, base=(0.66, 0.67, 0.68), base_mix=0.4, rough_add=0.06, bump=0.1),
    'pinion': photo_mat('ph_pinion', 'spring_steel_polished', scale=8, rot=90, base=(0.74, 0.75, 0.76), base_mix=0.4, rough_add=0.16, bump=0.06, grime=0.3),
    'pallet': photo_mat('ph_pallet', 'spring_steel_polished', scale=10, rot=0, base=(0.74, 0.75, 0.76), base_mix=0.3, rough_add=0.10, bump=0.08, wear=0.2),
    'spring': photo_mat('ph_mainspring', 'steel_heat_tint', scale=10, rot=0, base=(0.10, 0.11, 0.15), base_mix=0.7, rough_add=0.04),
    'blued': photo_mat('ph_blued', 'steel_heat_tint', scale=10, rot=0, base=(0.12, 0.14, 0.25), base_mix=0.6, rough_add=0.05),
    'enamel': dark_mat('dial_enamel', (0.86, 0.84, 0.78), 0.35),
    'ink': dark_mat('dial_ink', (0.04, 0.04, 0.045), 0.5),
    'dark': dark_mat('hole', (0.012, 0.011, 0.010), 0.9),
    'wood': photo_mat('ph_case', 'g03:oak_satin', scale=200, rot=90, metallic=0.0, tint=(0.62, 0.48, 0.36), rough_add=0.1, coat=0.2, bump=0.3, grime=0.6),
}



def turned(mat, aniso=0.75):
    """Concentric turning: anisotropic highlight running round the part's own Y axis (object origin =
    the arbor), the circular streak a turned or lapped face throws in a product photo."""
    nt = mat.node_tree; b = nt.nodes['Principled BSDF']
    tg = nt.nodes.new('ShaderNodeTangent'); tg.direction_type = 'RADIAL'; tg.axis = 'Y'
    b.inputs['Anisotropic'].default_value = aniso
    nt.links.new(tg.outputs['Tangent'], b.inputs['Tangent'])
    return mat


turned(M['wheel']); turned(M['barrel'], 0.6)

rig = LayerRig(scene, RES, SPP, DEVICE, OUT_DIR, center=(-4.0, -2.0), width_mm=72.0)


# ---------------------------------------------------------------- 2D outlines (x, z), angle 0 = up, + = clockwise
def _pol(r, a):
    return (r * math.sin(a), r * math.cos(a))


def tooth_outline(n, m, phase, kind='wheel', samples=7):
    """Clock gear outline: n teeth of module m, tooth k centred on angle phase + k * 2pi / n.
    wheel: ogival addendum 1.35 m, radial flanks, dedendum 1.6 m, tooth 1.45 m thick at the pitch circle.
    pinion: round-tipped leaves (addendum 0.53 m), radial flanks, dedendum 1.85 m, leaf 1.05 m thick."""
    R = n * m / 2.0
    if kind == 'wheel':
        ha, hf, s = 1.35 * m, 1.6 * m, 1.45 * m
    else:
        ha, hf, s = 0.525 * m, 1.85 * m, 1.05 * m
    Rr, p = R - hf, 2 * math.pi / n
    beta = (s / 2) / R
    rf = min(0.45 * m, 0.45 * (p - 2 * beta) * Rr)
    pts = []
    for k in range(n):
        c = phase + k * p
        pts.append(_pol(Rr + rf, c - beta))                       # leading radial flank (root -> pitch)
        for j in range(samples + 1):                              # addendum: semi-ellipse, pitch -> tip -> pitch
            u = math.pi * j / samples
            h, w = ha * math.sin(u), (s / 2) * math.cos(u)
            rr = R + h
            pts.append(_pol(rr, c - w / rr))
        pts.append(_pol(Rr + rf, c + beta))                       # trailing flank
        for j in range(1, samples):                               # round root to the next tooth
            t = j / samples
            pts.append(_pol(Rr + rf * (1 - math.sin(math.pi * t)), c + beta + t * (p - 2 * beta)))
    return pts


def escape_outline(n, r_tip, r_root, phase):
    """Club-toothed escape wheel (leading face slightly undercut, curved back), tooth tip k at phase + k p."""
    p, pts = 2 * math.pi / n, []
    for k in range(n):
        c = phase + k * p
        pts += [_pol(r_root, c - 0.10 * p), _pol(r_tip - 0.15, c - 0.02 * p), _pol(r_tip, c), _pol(r_tip, c + 0.10 * p),
                _pol(r_tip - 0.30, c + 0.20 * p), _pol(r_tip - 0.75, c + 0.42 * p), _pol(r_root + 0.35, c + 0.70 * p), _pol(r_root, c + 0.85 * p)]
    return pts


def chaikin(pts, it=2):
    for _ in range(it):
        out = []
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            out += [(0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]), (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1])]
        pts = out
    return pts


def window_outline(r_in, r_out, a0, a1, w_in, w_out, seg=10):
    """Crossing window between two tapered spokes at angles a0 < a1 (spoke widths w_in at the hub,
    w_out at the rim), rounded corners."""
    def edge(a, side, r, w):  # point on a spoke's edge at radius r: offset w/2 from the spoke centre line
        return (r * math.sin(a) + side * (w / 2) * math.cos(a), r * math.cos(a) - side * (w / 2) * math.sin(a))
    pts = [edge(a0, 1, r_in, w_in), edge(a0, 1, r_out, w_out)]
    b0, b1 = a0 + (w_out / 2) / r_out, a1 - (w_out / 2) / r_out
    pts += [_pol(r_out, b0 + (b1 - b0) * j / seg) for j in range(1, seg)]
    pts += [edge(a1, -1, r_out, w_out), edge(a1, -1, r_in, w_in)]
    c0, c1 = a1 - (w_in / 2) / r_in, a0 + (w_in / 2) / r_in
    pts += [_pol(r_in, c0 + (c1 - c0) * j / 4) for j in range(1, 4)]
    return chaikin(pts, 3)


def annulus_slot(r0, r1, a0, a1, seg=24):
    """Kidney-shaped window between radii r0 < r1 and angles a0 < a1, rounded corners."""
    pts = [_pol(r1, a0 + (a1 - a0) * j / seg) for j in range(seg + 1)]
    pts += [_pol(r0, a1 - (a1 - a0) * j / seg) for j in range(seg + 1)]
    return chaikin(pts, 4)


def spiral_band(r0, r1, turns, thick, a0=0.0, seg_per_turn=72):
    """Archimedean strip (the mainspring) from r0 to r1, `thick` wide, as one closed outline."""
    n = int(turns * seg_per_turn)
    mid = [(r0 + (r1 - r0) * i / n, a0 + 2 * math.pi * turns * i / n) for i in range(n + 1)]
    outer = [_pol(r + thick / 2, a) for r, a in mid]
    inner = [_pol(r - thick / 2, a) for r, a in mid]
    return outer + inner[::-1]


def direction(a, b):
    """Angle (0 = up, clockwise) from point a to point b, both (x, z)."""
    return math.atan2(b[0] - a[0], b[1] - a[1])


# ---------------------------------------------------------------- object helpers
def ortho_warp(objs):
    """Projective warp about the camera axis: x, z of every vertex scaled by (d + y) / d (d = camera
    distance to y = 0), so each part projects exactly as it would at depth 0 (the *_px keys of
    layers.json are computed there), while its planes keep their true depth for meshing and shading."""
    bpy.context.view_layer.update()
    d, (cx, cz) = rig.dist, rig.center
    for o in objs:
        if o.type != 'MESH':
            continue
        mw = o.matrix_world.copy(); inv = mw.inverted()
        for v in o.data.vertices:
            w = mw @ v.co; k = (d + w.y) / d
            v.co = inv @ Vector((cx + (w.x - cx) * k, w.y, cz + (w.z - cz) * k))
        o.data.update()
    return objs


def arbor_parts(name, x, z, y_front, y_back, collet_y, collet_r=1.25, r=0.45):
    """Steel arbor from a conical front pivot to the plate, with a turned collet in front of the wheel."""
    parts = []
    shaft = cyl(name + '_arbor', r, y_back - y_front, (x, (y_front + y_back) / 2, z), axis='Y', verts=32)
    put(shaft, M['steel'], 0.05, 2); parts.append(shaft)
    tip = lathe(name + '_pivot', [(r, 0.0), (r * 0.62, 0.45), (0.12, 0.8), (0.001, 0.86)], 0, 0, seg=32)
    tip.modifiers.clear(); tip.data.transform(Matrix.Rotation(math.pi / 2, 4, 'X')); tip.location = (x, y_front, z)
    put(tip, M['pinion'], None); parts.append(tip)
    col = lathe(name + '_collet', [(collet_r, 0.0), (collet_r, 0.35), (collet_r * 0.8, 0.62), (r + 0.25, 0.75), (r + 0.25, 0.9), (0.001, 0.9)], 0, 0, seg=64)
    col.data.transform(Matrix.Rotation(math.pi / 2, 4, 'X')); col.location = (x, collet_y, z)
    put(col, M['steel'], None); parts.append(col)
    return parts


def crossed_wheel(name, x, z, outline, y_mid, r_rim_in, r_hub, spokes=5, spoke_in=1.3, spoke_out=0.75, rot=0.0, mat=None):
    """Toothed rim with tapered crossings (spokes) and a hub, RIM_T thick, centred on depth y_mid."""
    y0, y1 = y_mid - RIM_T / 2, y_mid + RIM_T / 2
    g = prism(name, outline, y0, y1)
    for k in range(spokes):
        a0 = rot + 2 * math.pi * k / spokes
        w = prism('win', window_outline(r_hub, r_rim_in, a0, a0 + 2 * math.pi / spokes, spoke_in, spoke_out), y0 - 1, y1 + 1)
        boolean(g, w)
    boolean(g, cyl('ax', 0.46, 10, (0, y_mid, 0), axis='Y', verts=32))
    g.location = (x, 0, z)
    put(g, mat or M['wheel'], 0.1, 2)
    return g


def pinion(name, x, z, n, phase, y_front, y_back):
    o = prism(name, tooth_outline(n, MODULE, phase, 'pinion', 5), y_front, y_back)
    o.location = (x, 0, z); put(o, M['pinion'], 0.05, 2)
    return o


# ---------------------------------------------------------------- case, back plate, pillars, bushings
case = box('case', -60, 60, Y_PLATE + 3.0, Y_PLATE + 12.0, -60, 70); put(case, M['wood'], 0.5, 2); rig.objs['back'].append(case)
bp = box('backplate', -38, 30, Y_PLATE, Y_PLATE + 3.0, -44, 40); put(bp, M['plate'], 0.5, 4); rig.objs['back'].append(bp)
for (px, pz) in [(-34, -40), (26, -40), (-34, 36), (26, 36)]:
    pil = lathe('pillar', [(2.4, 0.0), (2.4, 6.6), (2.1, 7.1), (1.5, 7.3), (1.5, 8.0), (0.001, 8.0)], 0, 0, seg=48)
    pil.data.transform(Matrix.Rotation(math.pi / 2, 4, 'X')); pil.location = (px, Y_PLATE, pz); pil.modifiers.clear()
    put(pil, M['pillar'], 0.15, 2); rig.objs['back'].append(pil)
    rig.objs['back'].append(screw_head('pscrew', (px, Y_PLATE - 8.0, pz), 2.0, 1.0, axis='-Y', slot=True, kind='pan', mat=M['blued'], rot=0.4 + px))
bush = []
for i, (x, z) in enumerate([(t[0], t[1]) for t in TRAIN] + [BARREL[:2], PALLET]):
    big = i == 5
    rb = 2.6 if big else 1.6
    ring = cyl('bushing', rb, 0.5, (x, Y_PLATE - 0.25, z), axis='Y', verts=48)
    boolean(ring, cyl('bh', 0.55 if not big else 1.9, 2, (x, Y_PLATE - 0.25, z), axis='Y', verts=32))
    put(ring, M['steel'], 0.08, 2); bush.append(ring)
    hole = cyl('pivot_hole', 0.55 if not big else 1.9, 0.2, (x, Y_PLATE - 0.05, z), axis='Y', verts=32); put(hole, M['dark']); bush.append(hole)
    for s in (0, 1):  # two tiny chaton screws, rotated per bushing
        a = 0.7 + 1.9 * i + math.pi * s
        sx, sz = x + (rb + 0.75) * math.sin(a), z + (rb + 0.75) * math.cos(a)
        bush.append(screw_head('bscrew', (sx, Y_PLATE - 0.02, sz), 0.75, 0.45, axis='-Y', slot=True, kind='pan', mat=M['blued'], rot=a * 3))
ortho_warp(bush); rig.objs['back'] += bush

# bolt bar and bolt dog (static: the dog holds the bar while the movement is set). Bottom right, under
# the train, the bar runs out through a guide to the vault's bolt work.
YB = Y_PLATE - 1.6
bar = box('boltbar', -2.0, 34.0, YB - 1.1, YB + 1.1, -36.2, -32.6)
boolean(bar, box('dognotch', 11.2, 13.4, YB - 2, YB + 2, -33.8, -32.0))
boolean(bar, box('slot', 18.0, 26.0, YB - 2, YB + 2, -35.2, -33.6))
put(bar, M['steel'], 0.12, 2); rig.objs['back'].append(bar)
gd = box('guide', 19.6, 24.4, YB - 2.1, Y_PLATE, -36.8, -32.0); boolean(gd, box('gslot', 18, 26, YB - 1.25, YB + 1.25, -36.4, -32.4))
put(gd, M['bridge'], 0.12, 2); rig.objs['back'].append(gd)
for gx in (20.6, 23.4):
    rig.objs['back'].append(screw_head('gscrew', (gx, YB - 2.1, -34.4), 0.8, 0.5, axis='-Y', slot=True, kind='pan', mat=M['blued'], rot=gx))
stud = cyl('dogstud', 0.9, 3.0, (16.5, YB - 1.0, -26.0), axis='Y', verts=32); put(stud, M['steel'], 0.05, 2); rig.objs['back'].append(stud)
for nm, path, wd in [('dog_nose', [(16.5, -26.0), (14.6, -29.0), (12.9, -32.2), (12.3, -33.5)], 1.5),
                     ('dog_tail', [(16.5, -26.0), (12.0, -24.2), (7.8, -23.0)], 1.1)]:
    arm = flat_tool(nm, path, wd, 1.2, YB, tip='round'); arm.data.materials[0] = M['steel']; rig.objs['back'].append(arm)
boss = cyl('dog_boss', 1.9, 1.2, (16.5, YB, -26.0), axis='Y', verts=48); put(boss, M['steel'], 0.1, 2); rig.objs['back'].append(boss)
rig.objs['back'].append(screw_head('dogscrew', (16.5, YB - 0.6, -26.0), 1.3, 0.7, axis='-Y', slot=True, kind='pan', mat=M['blued'], rot=0.3))
dsp = flat_tool('dogspring', [(26.0, -23.0), (24.5, -24.8), (20.6, -25.4), (18.2, -24.4)], 0.4, 0.8, YB, tip='round')
dsp.data.materials[0] = M['blued']; rig.objs['back'].append(dsp)
rig.objs['back'].append(screw_head('springscrew', (26.0, YB - 0.4, -23.0), 0.9, 0.5, axis='-Y', slot=True, kind='pan', mat=M['blued'], rot=1.1))

# ---------------------------------------------------------------- moving: barrel
bx, bz, br = BARREL
w0c = TRAIN[0][:2]
bparts = []
bphase = direction((bx, bz), w0c)                         # a barrel tooth points at pinion 0
teeth = prism('barrel_teeth', tooth_outline(N_BARREL, MODULE, bphase, 'wheel', 6), Y_BARREL_TEETH - 0.4, Y_BARREL_TEETH + 0.4)
boolean(teeth, cyl('bt_in', 10.6, 10, (0, Y_BARREL_TEETH, 0), axis='Y', verts=128))
teeth.location = (bx, 0, bz); put(teeth, M['barrel'], 0.06, 2); bparts.append(teeth)
drum = cyl('barrel_drum', 11.2, 3.2, (bx, 3.9, bz), axis='Y', verts=128)
boolean(drum, cyl('drum_in', 10.5, 3.0, (bx, 3.4, bz), axis='Y', verts=128))
put(drum, M['barrel'], 0.12, 2); bparts.append(drum)
floor_ = cyl('barrel_floor', 10.5, 0.2, (bx, 4.75, bz), axis='Y', verts=96); put(floor_, M['barrel_in']); bparts.append(floor_)
spring = prism('mainspring', spiral_band(2.4, 10.25, 9.0, 0.32, a0=0.6), 2.6, 4.6); spring.location = (bx, 0, bz)
put(spring, M['spring'], 0.05, 2); bparts.append(spring)
barb = cyl('barrel_arbor', 2.0, 3.6, (bx, 3.4, bz), axis='Y', verts=48); put(barb, M['steel'], 0.08, 2); bparts.append(barb)
cover = cyl('barrel_cover', 10.8, 0.45, (bx, 2.2, bz), axis='Y', verts=128)
for k in range(3):
    a0 = math.radians(20 + 120 * k)
    sl = prism('cwin', annulus_slot(5.3, 9.1, a0, a0 + math.radians(66)), 1.0, 3.4); sl.location = (bx, 0, bz); boolean(cover, sl)
boolean(cover, cyl('ch', 2.05, 4, (bx, 2.2, bz), axis='Y', verts=48))
put(cover, M['barrel'], 0.08, 2); bparts.append(cover)
for k in range(3):                                        # cover lip notches (prising points), like a real barrel
    a = math.radians(80 + 120 * k)
    n_ = cyl('lip', 0.5, 0.5, (bx + 10.8 * math.sin(a), 2.0, bz + 10.8 * math.cos(a)), axis='Y', verts=16)
    put(n_, M['dark']); bparts.append(n_)
ratch = []
for k in range(RATCHET_TEETH):                            # ratchet: sawtooth (one face radial)
    a = 2 * math.pi * k / RATCHET_TEETH
    ratch += [_pol(3.55, a), _pol(4.3, a), _pol(3.55, a + 2 * math.pi / RATCHET_TEETH * 0.98)]
rat = prism('ratchet', ratch, 1.55, 2.0); rat.location = (bx, 0, bz); put(rat, M['steel'], 0.05, 2); bparts.append(rat)
sq = box('winding_square', -1.2, 1.2, 0.4, 1.6, -1.2, 1.2); sq.location = (bx, 0, bz); put(sq, M['steel'], 0.12, 2); bparts.append(sq)
rig.objs['moving']['barrel'] = ortho_warp(bparts)

# ---------------------------------------------------------------- moving: the train
for i, (x, z, r, pr) in enumerate(TRAIN):
    parts = []
    ym = Y_RIM[i]
    prev = (bx, bz) if i == 0 else TRAIN[i - 1][:2]
    plane_prev = Y_BARREL_TEETH if i == 0 else Y_RIM[i - 1]
    # pinion: a space faces the wheel that drives it (that wheel has a tooth pointing here)
    pphase = direction((x, z), prev) + math.pi / N_PINION[i]
    parts.append(pinion('wheel%d_pin' % i, x, z, N_PINION[i], pphase, ym + RIM_T / 2, plane_prev + 0.75))
    if i < 4:
        nxt = TRAIN[i + 1][:2]
        outline = tooth_outline(N_WHEEL[i], MODULE, direction((x, z), nxt), 'wheel', 6)
        rim_in, hub = r - 1.6 * MODULE - 1.05, 1.8
        parts.append(crossed_wheel('wheel%d' % i, x, z, outline, ym, rim_in, hub, 5, 1.25, 0.7, rot=0.35 * i + 0.2))
    else:
        # escape wheel: club teeth; the anchor's pallets (+-48 deg from up) sit behind a tooth, clear of the next
        outline = escape_outline(N_ESCAPE, r + 0.25, r - 1.1, math.radians(ESC_PHASE))
        parts.append(crossed_wheel('wheel%d' % i, x, z, outline, ym, r - 1.85, 1.5, 4, 0.95, 0.55, rot=0.4))
    parts += arbor_parts('wheel%d' % i, x, z, ym - RIM_T / 2 - 1.75, Y_PLATE - 0.1, ym - RIM_T / 2)
    rig.objs['moving']['wheel%d' % i] = ortho_warp(parts)

# ---------------------------------------------------------------- moving: anchor (pallet)
px_, pz_ = PALLET
ex, ez = TRAIN[-1][:2]
yp = Y_RIM[4]
anchor = []
boss = cyl('pallet', 1.45, 0.7, (px_, yp, pz_), axis='Y', verts=48); put(boss, M['pallet'], 0.08, 2); anchor.append(boss)
tail = flat_tool('pallet_tail', [(px_, pz_), (px_, pz_ + 1.6), (px_, pz_ + 2.7)], 0.9, 0.7, yp, tip='round')
tail.data.materials[0] = M['pallet']; anchor.append(tail)
for side in (-1, 1):                                      # pallet stones: radial to the escape wheel, in a tooth space
    a = side * math.radians(48)
    tipx, tipz = ex + 4.5 * math.sin(a), ez + 4.5 * math.cos(a)
    outx, outz = ex + 6.4 * math.sin(a), ez + 6.4 * math.cos(a)
    L = math.hypot(outx - tipx, outz - tipz); ux, uz = (outx - tipx) / L, (outz - tipz) / L; nx_, nz_ = uz, -ux
    w = 0.32
    arm = flat_tool('pallet_arm', [(px_, pz_), (px_ + side * 2.4, pz_ - 0.7), (outx - 0.25 * ux, outz - 0.25 * uz)], 1.05, 0.7, yp, tip='round')
    arm.data.materials[0] = M['pallet']; anchor.append(arm)
    st = prism('stone', [(tipx + nx_ * w, tipz + nz_ * w), (outx + nx_ * w, outz + nz_ * w), (outx - nx_ * w, outz - nz_ * w), (tipx - nx_ * w, tipz - nz_ * w)],
               yp - 0.3, yp + 0.3)
    put(st, M['pallet'], 0.04, 2); anchor.append(st)
anchor += arbor_parts('pallet', px_, pz_, yp - 0.35 - 1.6, Y_PLATE - 0.1, yp - 0.35, collet_r=1.0, r=0.42)
rig.objs['moving']['pallet'] = ortho_warp(anchor)

# ---------------------------------------------------------------- moving: hand, tweezers
dx, dz, dr = DIAL
hand = prism('hand', [(-0.35, -1.6), (0.35, -1.6), (0.18, dr - 1.4), (0.0, dr - 0.8), (-0.18, dr - 1.4)], Y_WHEEL - 6.4, Y_WHEEL - 6.0)
put(hand, M['blued'], 0.05, 2)
hub = cyl('hand_hub', 0.9, 0.6, (0, Y_WHEEL - 6.3, 0), axis='Y', verts=24); put(hub, M['blued'], 0.05, 2)
for o in (hand, hub):
    o.location = (dx, 0, dz)
rig.objs['moving']['hand'] = [hand, hub]
tw = []
for side in (-1, 1):  # in front of the whole train (the game draws them over the wheels)
    arm = prism('tw_arm', [(side * 0.15, 0.0), (side * 0.75, 0.0), (side * 1.8 + 9.0, 20.0), (side * 0.9 + 9.0, 20.0)], Y_WHEEL - 8.2, Y_WHEEL - 7.6)
    put(arm, M['steel'], 0.06, 2); tw.append(arm)
rig.objs['moving']['tweezers'] = ortho_warp(tw)

# ---------------------------------------------------------------- front: the dial bridge, the barrel click
bridge = prism('bridge', chaikin([(-31, 7), (-9, 7), (-7.5, 11), (-7.5, 30), (-31, 30)], 1), Y_WHEEL - 5.0, Y_WHEEL - 3.4)
boolean(bridge, cyl('dhole', dr + 0.3, 10, (dx, Y_WHEEL - 4.0, dz), axis='Y', verts=96))
put(bridge, M['bridge'], 0.3, 3); rig.objs['front'].append(bridge)
dial = cyl('dial', dr, 0.6, (dx, Y_WHEEL - 5.3, dz), axis='Y', verts=96); put(dial, M['enamel'], 0.1, 2); rig.objs['front'].append(dial)
for k in range(12):
    a = 2 * math.pi * k / 12
    tk = box('dtick', -0.18, 0.18, Y_WHEEL - 5.66, Y_WHEEL - 5.6, dr - (1.8 if k % 3 == 0 else 1.1), dr - 0.4)
    tk.data.transform(Matrix.Rotation(a, 4, 'Y')); tk.location = (dx, 0, dz); put(tk, M['ink']); rig.objs['front'].append(tk)
for (sx, sz) in [(-28, 10), (-28, 27)]:
    rig.objs['front'].append(screw_head('bscrew', (sx, Y_WHEEL - 5.0, sz), 1.5, 0.8, axis='-Y', slot=True, kind='pan', mat=M['blued'], rot=0.7 + sz))
# click: pivoted on a stud left of the ratchet, its nose in a ratchet tooth (never under a wheel or the tweezers)
ck = []
cpx, cpz = bx - 7.4, bz + 1.2
nose_a = direction((bx, bz), (cpx, cpz)) + 0.30
nx_, nz_ = bx + 4.0 * math.sin(nose_a), bz + 4.0 * math.cos(nose_a)
click = prism('click', chaikin([(cpx - 1.1, cpz + 1.0), (cpx + 1.1, cpz + 1.2), (nx_ + 0.2, nz_ + 0.6), (nx_, nz_ - 0.1), (cpx + 0.6, cpz - 1.3), (cpx - 1.0, cpz - 1.0)], 1), 1.5, 2.05)
put(click, M['steel'], 0.06, 2); ck.append(click)
ck.append(screw_head('click_screw', (cpx, 1.5, cpz), 1.1, 0.6, axis='-Y', slot=True, kind='pan', mat=M['blued'], rot=2.2))
csp = flat_tool('click_spring', [(cpx - 1.2, cpz - 4.6), (cpx - 2.2, cpz - 2.2), (cpx - 1.2, cpz - 0.6)], 0.35, 0.5, 1.8, tip='round')
csp.data.materials[0] = M['blued']; ck.append(csp)
rig.objs['front'] += ortho_warp(ck)

# ---------------------------------------------------------------- light + camera, render
world_hdri(0.08, sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 0, 6)
area_light('key', (-110, -220, 170), AIM, 60, float(arg('--key', '300000')), (1.0, 0.88, 0.74))
area_light('fill', (170, -210, -30), AIM, 100, float(arg('--fill', '14000')), (0.9, 0.94, 1.0))
area_light('rim', (40, -30, 190), AIM, 50, float(arg('--rim', '9000')), (1.0, 0.92, 0.82))
cam = rig.camera()
# product-photo sheen: a large strip softbox where the plate mirrors the camera (slid up so only its soft
# edge shows), so the flat faces of the steel wheels read bright against the black plate
mirror_softbox('sheen', (rig.center[0], 0, rig.center[1]), cam, dist=600, size=float(arg('--ss', '220')), size_y=float(arg('--ssy', '420')),
               energy=float(arg('--sheen', '220000')), shift=(0, 0, float(arg('--sz', '14'))))
render_setup(os.path.join(OUT_DIR, 'ref.png'), RES, SPP, exposure=float(arg('--exp', '0.4')))
rig.gpu()
rig.meta.update({
    'family': 'time_lock', 'travel_px': rig.vec(0.0, -TRAVEL, Y_WHEEL),
    'slots_px': [rig.px(x, z + r, Y_WHEEL) for (x, z, r, pr) in TRAIN],     # anchor: top of each wheel
    'centres_px': [rig.px(x, z, Y_WHEEL) for (x, z, r, pr) in TRAIN],
    'radii_mm': [r for (x, z, r, pr) in TRAIN], 'pinions_mm': [pr for (x, z, r, pr) in TRAIN],
    'barrel_px': rig.px(bx, bz, Y_WHEEL), 'barrel_mm': br,
    'pallet_px': rig.px(PALLET[0], PALLET[1], Y_WHEEL), 'hand_px': rig.px(dx, dz, Y_WHEEL - 6.0),
    'tweezers_tip_px': rig.px(0.0, 0.0, Y_WHEEL), 'ppm': rig.ppm(Y_WHEEL),
    'shear_px': [],
    # N-86: tooth counts (pitch radius = radii_mm at module 0.4) and the ratchet click of the key
    'teeth': N_WHEEL + [N_ESCAPE], 'pinion_leaves': N_PINION, 'barrel_teeth': N_BARREL, 'wind_step_deg': WIND_STEP,
})
rig.run(PASSES)
