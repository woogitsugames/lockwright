# Lockwright — plan-B plates for the `time_lock` screen (LOCKS.md §2.24, job.museum_time_lock). This is
# a REPAIR: the museum's old time-lock movement has stopped, the locksmith puts its train back in mesh
# and gets it running again (no opening, no vault). Invented, encyclopedic-level movement, front view
# with the front plate removed: the mainspring barrel (wound by the key = left thumb), a train of up to
# five wheels from the barrel to the escape wheel, a rocking pallet, and a small dial whose hand shows
# the even run. Every wheel turns when the train runs (no dead gears, DESIGN.md).
#   plate.png        back plate, pillars, pivot holes (static)
#   front.png        the dial bridge with the dial ring (drawn over the train)
#   wheel0..4.png    train wheels in the SET pose (meshed, on their pivots); the game lowers them from
#                    above by (position - window centre) * travel and turns them when the train runs
#   barrel.png       the barrel with ratchet (turns a little with the key), pallet.png (rocks), hand.png
#   tweezers.png     the tweezers, tip at its anchor
# Run (CPU now, final on a GPU later):
#   blender -b -P art/blender/plates/time_lock_plate.py -- \
#       --out-dir game/assets/photoreal_families/time_lock/photo --res 618x824 --spp 16 --device CPU
import bpy, math, os, sys
from mathutils import Matrix

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
BARREL = (-14.0, -24.0, 12.0)      # x, z, radius
# train wheels: centre x, z, wheel radius, pinion radius; each meshes with the previous wheel/barrel
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

# VA-09 look (2026-11-08): no brass-on-brass. A black japanned back plate (like the warded case and the
# lever case), nickel-bright steel train wheels with radial turning marks, the brass barrel as the one
# warm part, a polished steel pallet; every moving part >= 3:1 against the plate in grayscale.
M = {
    'plate': photo_mat('ph_japan', 'iron_painted_rust', scale=28, rot=0, metallic=0.0, base=(0.022, 0.021, 0.020), base_mix=0.82, rough_add=0.05, bump=0.25, grime=0.5, wear=0.25),
    'pillar': photo_mat('ph_pillar', 'nickel_satin', scale=10, rot=90, base=(0.58, 0.58, 0.57), base_mix=0.35, rough_add=0.10, bump=0.1, grime=0.6),
    'bridge': photo_mat('ph_bridge', 'brass_face_milled', scale=40, rot=90, base=(0.60, 0.46, 0.24), base_mix=0.55, rough_add=0.16, bump=0.12, grime=0.8, wear=0.5),
    'wheel': photo_mat('ph_wheel', 'brass_turned', scale=24, flat=True, base=(0.62, 0.64, 0.66), base_mix=0.6, rough_add=0.04, bump=0.12, grime=0.35, wear=0.3),
    'barrel': photo_mat('ph_barrel', 'brass_turned', scale=30, flat=True, base=(0.86, 0.68, 0.38), base_mix=0.4, rough_add=0.06, bump=0.12, grime=0.5, wear=0.4),
    'steel': photo_mat('ph_steel', 'steel_ground', scale=12, rot=0, base=(0.70, 0.71, 0.72), base_mix=0.4, rough_add=0.08, bump=0.1),
    'pallet': photo_mat('ph_pallet', 'spring_steel_polished', scale=10, rot=0, base=(0.74, 0.75, 0.76), base_mix=0.3, rough_add=0.12, bump=0.08, wear=0.2),
    'blued': photo_mat('ph_blued', 'steel_heat_tint', scale=10, rot=0, base=(0.12, 0.14, 0.25), base_mix=0.6, rough_add=0.05),
    'enamel': dark_mat('dial_enamel', (0.86, 0.84, 0.78), 0.35),
    'ink': dark_mat('dial_ink', (0.04, 0.04, 0.045), 0.5),
    'dark': dark_mat('hole', (0.012, 0.011, 0.010), 0.9),
    'wood': photo_mat('ph_case', 'g03:oak_satin', scale=200, rot=90, metallic=0.0, tint=(0.62, 0.48, 0.36), rough_add=0.1, coat=0.2, bump=0.3, grime=0.6),
}

rig = LayerRig(scene, RES, SPP, DEVICE, OUT_DIR, center=(-4.0, -2.0), width_mm=72.0)


def gear(name, r, teeth, thick, y, spokes=True, pinion=None, arbor=True):
    """Spur gear in the XZ plane at the origin (front face at y), teeth as a polygon outline."""
    pts = []
    depth = max(0.6, r * 0.09)
    for t in range(teeth):
        a0 = 2 * math.pi * t / teeth
        for f, rr in ((0.0, r - depth), (0.18, r - depth), (0.28, r), (0.62, r), (0.72, r - depth)):
            a = a0 + f * 2 * math.pi / teeth
            pts.append((rr * math.sin(a), rr * math.cos(a)))
    g = prism(name, pts, y, y + thick)
    if spokes and r > 4.5:
        for k in range(4):
            a = k * math.pi / 2 + math.pi / 4
            hole = cyl('sp', r * 0.26, 10, ((r * 0.5) * math.sin(a), y, (r * 0.5) * math.cos(a)), axis='Y', verts=40)
            boolean(g, hole)
    boolean(g, cyl('ax', 0.5, 10, (0, y, 0), axis='Y', verts=24))
    parts = [g]
    if arbor:
        arb = cyl(name + '_arbor', 0.55, 8.0, (0, y + 2.5, 0), axis='Y', verts=24); parts.append(arb)
    if pinion:
        parts += gear(name + '_pin', pinion, 8, thick + 1.2, y - 1.4, spokes=False, arbor=False)
    return parts


def place(objs, x, z):
    for o in objs:
        o.location = (x, 0, z)
    return objs


# ---------------------------------------------------------------- case, back plate, pillars, pivot holes
case = box('case', -60, 60, Y_PLATE + 3.0, Y_PLATE + 12.0, -60, 70); put(case, M['wood'], 0.5, 2); rig.objs['back'].append(case)
bp = box('backplate', -38, 30, Y_PLATE, Y_PLATE + 3.0, -44, 40); put(bp, M['plate'], 0.4, 3); rig.objs['back'].append(bp)
for (px, pz) in [(-34, -40), (26, -40), (-34, 36), (26, 36)]:
    pil = cyl('pillar', 2.4, 8.0, (px, Y_PLATE - 4.0, pz), axis='Y', verts=32); put(pil, M['pillar'], 0.2, 2); rig.objs['back'].append(pil)
    rig.objs['back'].append(screw_head('pscrew', (px, Y_PLATE - 8.0, pz), 2.0, 1.0, axis='-Y', slot=True, kind='pan', mat=M['blued'], rot=0.4 + px))
for (x, z, r, pr) in TRAIN + [(BARREL[0], BARREL[1], 0, 0), (PALLET[0], PALLET[1], 0, 0)]:
    h = cyl('pivot', 1.1, 0.4, (x, Y_PLATE - 0.15, z), axis='Y', verts=32); put(h, M['dark']); rig.objs['back'].append(h)
    ring = cyl('jewel', 1.8, 0.3, (x, Y_PLATE - 0.2, z), axis='Y', verts=32)
    boolean(ring, cyl('jh', 1.1, 2, (x, Y_PLATE - 0.2, z), axis='Y', verts=32)); put(ring, M['steel'], 0.05, 2); rig.objs['back'].append(ring)

# ---------------------------------------------------------------- moving: barrel, wheels, pallet, hand, tweezers
bx, bz, br = BARREL
barrel = gear('barrel', br, 48, 4.0, Y_WHEEL - 1.0, spokes=False)
ratchet = gear('ratchet', br * 0.55, 20, 1.0, Y_WHEEL - 2.2, spokes=False, arbor=False)[0]
sq = box('winding_square', -1.4, 1.4, Y_WHEEL - 4.0, Y_WHEEL - 2.0, -1.4, 1.4)
for o in barrel + [ratchet, sq]:
    put(o, M['barrel'] if o is not sq else M['steel'], 0.1, 2)
rig.objs['moving']['barrel'] = place(barrel + [ratchet, sq], bx, bz)
for i, (x, z, r, pr) in enumerate(TRAIN):
    parts = gear('wheel%d' % i, r, max(24, int(r * 7)), 1.2, Y_WHEEL, pinion=pr)
    for o in parts:
        put(o, M['wheel'] if 'arbor' not in o.name else M['steel'], 0.08, 2)
    rig.objs['moving']['wheel%d' % i] = place(parts, x, z)
pal = prism('pallet', [(-6.5, 0.6), (6.5, 0.6), (5.5, -2.2), (4.6, -2.2), (3.6, -0.6), (-3.6, -0.6), (-4.6, -2.2), (-5.5, -2.2)], Y_WHEEL - 0.2, Y_WHEEL + 1.0)
put(pal, M['pallet'], 0.08, 2)
palarb = cyl('pallet_arbor', 0.7, 6.0, (0, Y_WHEEL + 2.0, 0), axis='Y', verts=24); put(palarb, M['steel'], 0.05, 2)
rig.objs['moving']['pallet'] = place([pal, palarb], PALLET[0], PALLET[1])
dx, dz, dr = DIAL
hand = prism('hand', [(-0.35, -1.6), (0.35, -1.6), (0.18, dr - 1.4), (0.0, dr - 0.8), (-0.18, dr - 1.4)], Y_WHEEL - 6.4, Y_WHEEL - 6.0)
put(hand, M['blued'], 0.05, 2)
hub = cyl('hand_hub', 0.9, 0.6, (0, Y_WHEEL - 6.3, 0), axis='Y', verts=24); put(hub, M['blued'], 0.05, 2)
rig.objs['moving']['hand'] = place([hand, hub], dx, dz)
tw = []
for side in (-1, 1):
    arm = prism('tw_arm', [(side * 0.15, 0.0), (side * 0.75, 0.0), (side * 1.8 + 9.0, 20.0), (side * 0.9 + 9.0, 20.0)], Y_WHEEL - 3.2, Y_WHEEL - 2.6)
    put(arm, M['steel'], 0.06, 2); tw.append(arm)
rig.objs['moving']['tweezers'] = tw

# ---------------------------------------------------------------- front: the dial bridge
bridge = prism('bridge', [(-31, 7), (-9, 7), (-7.5, 11), (-7.5, 30), (-31, 30)], Y_WHEEL - 5.0, Y_WHEEL - 3.4)
boolean(bridge, cyl('dhole', dr + 0.3, 10, (dx, Y_WHEEL - 4.0, dz), axis='Y', verts=96))
put(bridge, M['bridge'], 0.3, 3); rig.objs['front'].append(bridge)
dial = cyl('dial', dr, 0.6, (dx, Y_WHEEL - 5.3, dz), axis='Y', verts=96); put(dial, M['enamel'], 0.1, 2); rig.objs['front'].append(dial)
for k in range(12):
    a = 2 * math.pi * k / 12
    tk = box('dtick', -0.18, 0.18, Y_WHEEL - 5.66, Y_WHEEL - 5.6, dr - (1.8 if k % 3 == 0 else 1.1), dr - 0.4)
    tk.data.transform(Matrix.Rotation(a, 4, 'Y')); tk.location = (dx, 0, dz); put(tk, M['ink']); rig.objs['front'].append(tk)
for (sx, sz) in [(-28, 10), (-28, 27)]:
    rig.objs['front'].append(screw_head('bscrew', (sx, Y_WHEEL - 5.0, sz), 1.5, 0.8, axis='-Y', slot=True, kind='pan', mat=M['blued'], rot=0.7 + sz))

# ---------------------------------------------------------------- light + camera, render
world_hdri(0.08, sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 0, 6)
area_light('key', (-110, -220, 170), AIM, 60, float(arg('--key', '300000')), (1.0, 0.88, 0.74))
area_light('fill', (170, -210, -30), AIM, 100, 12000, (0.9, 0.94, 1.0))
area_light('rim', (40, -30, 190), AIM, 50, 6000, (1.0, 0.92, 0.82))
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
})
rig.run(PASSES)
