# Lockwright — plan-B plates for the `axial_slider` screen (bureau slider lock, LOCKS.md §2.23;
# job.bramah_bureau). Invented, encyclopedic-level picture: the brass lock case of a bureau, cut away;
# up to six sliders lie side by side (the ring round the core shown unrolled into rows), each with a
# gate notch; a steel locking plate crosses them. A slider pushed in to its depth brings its notch onto
# the plate; with every notch on the plate the core turns and throws the bolt.
#   plate.png        bureau wood, case back, the locking plate (behind the sliders: it shows through
#                    a notch that sits on it), the slider guides
#   front.png        the case front round the cut-away
#   slider0..5.png   sliders in the SET pose (notch on the plate); the game moves them along the travel
#   bolt.png         the bolt, locked pose; pusher.png the pusher, tip at its anchor
# Run (CPU now, final on a GPU later):
#   blender -b -P art/blender/plates/axial_slider_plate.py -- \
#       --out-dir game/assets/photoreal_families/axial_slider/photo --res 618x824 --spp 16 --device CPU
import bpy, math, os, sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
ROOT_DIR = os.path.abspath(os.path.join(BLENDER_DIR, '..', '..'))
sys.path.insert(0, BLENDER_DIR); sys.path.insert(0, THIS_DIR)
from lw_common import *  # noqa: F401,F403
from layer_plate_common import LayerRig

arg = cli()
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'axial_slider', 'photo')))
RES = [int(v) for v in arg('--res', '618x824').split('x')]
SPP = int(arg('--spp', '16'))
DEVICE = arg('--device', 'CPU').upper()
PASSES = arg('--passes', 'plate,front,moving').split(',')

ROWS = [15.0, 9.0, 3.0, -3.0, -9.0, -15.0]   # slider centre lines (z)
SL_H, SL_L = 3.6, 36.0                        # slider height, length (x from -26 to +10 in the set pose)
SL_X0 = -26.0
NOTCH_W, NOTCH_D = 3.2, 1.8
TRAVEL = 8.0                                  # mm pushed in (to the right) for lockcore position 1.0
CASE = (-34.0, 22.0, -26.0, 26.0)

M = {
    'wood':   photo_mat('ph_bureau', 'g03:oak_satin', scale=220, rot=0, metallic=0.0, tint=(0.62, 0.38, 0.24), rough_add=0.05, coat=0.4, bump=0.3, grime=0.5),
    'case':   photo_mat('ph_case', 'brass_patina_grease', scale=70, rot=10, base=(0.62, 0.48, 0.26), base_mix=0.45, rough_add=0.15, bump=0.2, grime=0.7),
    'cut':    photo_mat('ph_cut', 'brass_face_milled', scale=20, rot=40, base=(0.85, 0.66, 0.36), base_mix=0.45, rough_add=0.2, bump=0.2),
    'slider': photo_mat('ph_slider', 'steel_ground', scale=18, rot=0, base=(0.80, 0.81, 0.82), base_mix=0.45, rough_add=0.04, bump=0.12, grime=0.25),
    'plate':  photo_mat('ph_lplate', 'steel_heat_tint', scale=14, rot=90, base=(0.16, 0.17, 0.24), base_mix=0.55, rough_add=0.1),
    'bolt':   photo_mat('ph_bolt', 'brass_face_milled', scale=30, rot=0, base=(0.80, 0.62, 0.32), base_mix=0.4, rough_add=0.12, wear=0.5, grime=0.5),
    'dark':   dark_mat('cavity', (0.02, 0.016, 0.012), 0.9),
}

rig = LayerRig(scene, RES, SPP, DEVICE, OUT_DIR, center=(-6.0, 0.0), width_mm=70.0)
x0, x1, z0, z1 = CASE

# ---------------------------------------------------------------- back: bureau, case back, guides, locking plate
wood = box('bureau', -200, 200, 10.0, 30.0, -200, 200); put(wood, M['wood'], 0.5, 2); rig.objs['back'].append(wood)
back = box('case_back', x0, x1, 4.0, 10.0, z0, z1); put(back, M['case'], 0.4, 3); rig.objs['back'].append(back)
cav = box('cavity', x0 + 3, x1 - 3, 3.9, 4.0, z0 + 3, z1 - 3); put(cav, M['dark']); rig.objs['back'].append(cav)
for z in ROWS:  # guide grooves between the rows
    for dz in (-SL_H / 2 - 0.5, SL_H / 2 + 0.5):
        g = box('guide', x0 + 3, x1 - 3, 2.6, 4.0, z + dz - 0.35, z + dz + 0.35); put(g, M['cut'], 0.05, 2); rig.objs['back'].append(g)
lp = box('locking_plate', -1.25, 1.25, 1.4, 3.8, z0 + 3, z1 - 3); put(lp, M['plate'], 0.15, 2); rig.objs['back'].append(lp)
for z in (z1 - 5, z0 + 5):
    rig.objs['back'].append(screw_head('lpscrew', (0.0, 1.4, z), 1.3, 0.7, axis='-Y', slot=True, kind='pan', mat=M['plate'], rot=0.5 + z))

# ---------------------------------------------------------------- front: the case front round the cut-away
front = box('case_front', x0, x1, -2.0, 0.0, z0, z1)
boolean(front, box('win', x0 + 4, x1 - 4, -5, 2, z0 + 4, z1 - 4))
put(front, M['case'], 0.45, 3); rig.objs['front'].append(front)
for (sx, sz) in [(x0 + 2.2, z1 - 2.2), (x1 - 2.2, z1 - 2.2), (x0 + 2.2, z0 + 2.2), (x1 - 2.2, z0 + 2.2)]:
    rig.objs['front'].append(screw_head('cscrew', (sx, -2.0, sz), 1.2, 0.6, axis='-Y', slot=True, kind='pan', mat=M['bolt'], rot=0.3 + sx))

# ---------------------------------------------------------------- moving: sliders, bolt, pusher
for i, z in enumerate(ROWS):
    s = box('slider%d' % i, SL_X0, SL_X0 + SL_L, -1.0, 2.4, z - SL_H / 2, z + SL_H / 2)
    boolean(s, box('notch', -NOTCH_W / 2, NOTCH_W / 2, -3, 4, z + SL_H / 2 - NOTCH_D, z + SL_H))
    boolean(s, box('step', SL_X0 - 1, SL_X0 + 3.0, -3, 4, z - SL_H / 2 - 1, z - SL_H / 2 + 1.0))  # pusher seat
    put(s, M['slider'], 0.18, 2)
    rig.objs['moving']['slider%d' % i] = [s]
bolt = box('bolt', 8.0, 40.0, -1.2, 2.2, -24.0, -19.5); put(bolt, M['bolt'], 0.3, 2)
rig.objs['moving']['bolt'] = [bolt]
pusher = cyl('pusher', 0.9, 40.0, (-20.0, 0.6, 0.0), axis='X', verts=32)
tipc = cyl('pusher_tip', 1.3, 2.0, (-1.0, 0.6, 0.0), axis='X', verts=32)
boolean(pusher, tipc, 'UNION'); put(pusher, M['slider'], 0.1, 2)
rig.objs['moving']['pusher'] = [pusher]

# ---------------------------------------------------------------- light + camera, render
world_hdri(0.08, sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (-6, 0, 0)
area_light('key', (-110, -200, 160), AIM, 60, 230000, (1.0, 0.85, 0.68))
area_light('fill', (160, -200, -30), AIM, 100, 8000, (0.9, 0.94, 1.0))
area_light('rim', (40, -30, 180), AIM, 50, 3000, (1.0, 0.92, 0.82))
rig.camera()
render_setup(os.path.join(OUT_DIR, 'ref.png'), RES, SPP, exposure=float(arg('--exp', '0.45')))
rig.gpu()
rig.meta.update({
    'family': 'axial_slider', 'travel_px': rig.vec(TRAVEL, 0.0, 0.0),
    'slots_px': [rig.px(SL_X0 + 1.5, z - SL_H / 2 + 0.5, 0.0) for z in ROWS],   # anchor: the pusher seat
    'notch_px': [rig.px(0.0, z + SL_H / 2, 0.0) for z in ROWS],
    'shear_px': [rig.px(0.0, z1 - 4.0, 0.0), rig.px(0.0, z0 + 4.0, 0.0)],
    'bolt_open_px': rig.vec(-10.0, 0.0, 0.0),
    'pusher_tip_px': rig.px(0.0, 0.0, 0.0), 'ppm': rig.ppm(0.0),
})
rig.run(PASSES)
