# Lockwright — plan-B plates for the `egyptian` lock screen (ancient wooden pin bolt, LOCKS.md §2.22;
# job.dollhouse_wooden_lock: the dollhouse's wooden lock). Invented, encyclopedic-level picture: a
# wooden staple block on a painted door, cut away at the front; the wooden bolt runs through it; up to
# five wooden pegs drop by gravity from their channels into holes in the bolt. A lifter in the bolt's
# hollow underside raises a peg; a peg whose bottom clears the bolt's top (the shear line) no longer
# holds the bolt; with every peg up and the bolt pulled, the bolt slides out.
#   plate.png     door boards, the back half of the block with the peg channels and the bolt passage
#   front.png     the front of the block round the cut-away (drawn over everything)
#   bolt.png      the bolt (front half cut away: holes and the hollow underside show), locked pose
#   peg0..4.png   pegs in the SET pose (bottom just above the bolt's top); the game moves them by
#                 (position - window centre) * travel, so each peg's own gate lands on the shear line
#   lifter.png    the lifter, tip at its anchor point
# Run (CPU now, final on a GPU later):
#   blender -b -P art/blender/plates/egyptian_plate.py -- \
#       --out-dir game/assets/photoreal_families/egyptian/photo --res 618x824 --spp 16 --device CPU
import bpy, math, os, sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
ROOT_DIR = os.path.abspath(os.path.join(BLENDER_DIR, '..', '..'))
sys.path.insert(0, BLENDER_DIR); sys.path.insert(0, THIS_DIR)
from lw_common import *  # noqa: F401,F403
from layer_plate_common import LayerRig

arg = cli()
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'egyptian', 'photo')))
RES = [int(v) for v in arg('--res', '618x824').split('x')]
SPP = int(arg('--spp', '16'))
DEVICE = arg('--device', 'CPU').upper()
PASSES = arg('--passes', 'plate,front,moving').split(',')

SLOTS = [-16.0, -8.0, 0.0, 8.0, 16.0]
PEG_R, PEG_L = 1.9, 14.0
TRAVEL = 7.0                      # mm of peg lift for lockcore position 1.0
SET_GAP = 0.25                    # set pose: peg bottom this far above the bolt's top (z = 0)
BOLT_Z = (-7.0, 0.0)
CH_Z = (-7.0, -5.0)               # hollow underside of the bolt (lifter channel)
BLOCK = (-28.0, 28.0, -11.0, 25.0)
WIN = (-23.0, 23.0, -9.5, 21.0)   # cut-away in the block's front
OPEN_SLIDE = 14.0

# VA-09 look (2026-11-08): wood on wood is kept, but in three clear values. The back half of the block
# (behind the pegs and the bolt) is old oak blackened by smoke and oil, the channels are dark; the bolt
# is pale worn ash-like oak and the pegs are pale boxwood-like beech, so each moving part reads >= 3:1
# in grayscale. The front frame keeps the mid oak tone.
M = {
    'door':  photo_mat('ph_door', 'pine_floor_painted', scale=160, rot=90, metallic=0.0, tint=(0.82, 0.78, 0.76), rough_add=0.05, bump=0.3, grime=0.4),
    'block': photo_mat('ph_block', 'g03:oak_satin', scale=120, rot=0, metallic=0.0, tint=(0.95, 0.85, 0.72), rough_add=0.12, coat=0.1, bump=0.35, grime=0.8, wear=0.5),
    'inner': photo_mat('ph_inner', 'g03:oak_satin', scale=120, rot=0, offset=(37, 0, 11), metallic=0.0, tint=(0.16, 0.12, 0.09), rough_add=0.18, coat=0.05, bump=0.4, grime=0.9, wear=0.2),
    'endgrain': photo_mat('ph_endgrain', 'g03:oak_satin', scale=40, rot=90, metallic=0.0, tint=(0.80, 0.66, 0.50), rough_add=0.25, bump=0.5, grime=0.6),
    'bolt':  photo_mat('ph_bolt', 'g03:oak_satin', scale=90, rot=0, offset=(11, 0, 3), metallic=0.0, base=(0.72, 0.58, 0.40), base_mix=0.56, rough_add=0.1, coat=0.15, bump=0.3, grime=0.5, wear=0.6),
    'peg':   photo_mat('ph_peg', 'bench_beech_top', scale=30, rot=90, metallic=0.0, base=(0.90, 0.76, 0.52), base_mix=0.38, rough_add=0.1, bump=0.25, wear=0.6, grime=0.4),
    'lifter': photo_mat('ph_lifter', 'steel_ground', scale=20, rot=0, base=(0.80, 0.81, 0.82), base_mix=0.5, rough_add=0.22, bump=0.15, wear=0.3),
    'dark':  dark_mat('channel', (0.012, 0.009, 0.007), 0.9),
    'nail':  photo_mat('ph_nail', 'iron_painted_rust', scale=12, metallic=0.4, rough_add=0.1),
}

rig = LayerRig(scene, RES, SPP, DEVICE, OUT_DIR, center=(0.0, 4.0), width_mm=64.0)

# ---------------------------------------------------------------- door + block (back half) + channels
door = box('door', -200, 200, 8.0, 20.0, -200, 200); put(door, M['door'], 0.4, 2); rig.objs['back'].append(door)
x0, x1, z0, z1 = BLOCK
back = box('block_back', x0, x1, 0.0, 8.0, z0, z1)
boolean(back, box('pass', -60, 60, -1, 4.5, BOLT_Z[0] - 0.4, BOLT_Z[1] + 0.4))
for x in SLOTS:
    boolean(back, cyl('ch', PEG_R + 0.25, 30, (x, 0.0, 12.0), axis='Z', verts=48))
put(back, M['inner'], 0.4, 3); rig.objs['back'].append(back)
for x in SLOTS:  # dark bottom of each channel's back half
    c = cyl('chd', PEG_R + 0.2, z1 - 3.0, (x, 0.35, (z1 - 3.0) / 2.0 + 0.4), axis='Z', verts=48)
    boolean(c, box('chf', -60, 60, -10, 0.3, -60, 60)); put(c, M['dark']); rig.objs['back'].append(c)
for (nx, nz) in [(x0 + 4, z1 - 4), (x1 - 4, z1 - 4), (x0 + 4, z0 + 4), (x1 - 4, z0 + 4)]:
    rig.objs['front'].append(screw_head('peg_nail', (nx, -6.0, nz), 1.6, 0.9, axis='-Y', slot=False, kind='dome', mat=M['nail']))

# ---------------------------------------------------------------- block front (around the cut-away)
front = box('block_front', x0, x1, -6.0, 0.0, z0, z1)
boolean(front, box('win', WIN[0], WIN[1], -10, 2, WIN[2], WIN[3]))
boolean(front, box('pass_f', -60, 60, -4.5, 1, BOLT_Z[0] - 0.4, BOLT_Z[1] + 0.4))
put(front, M['block'], 0.5, 3); rig.objs['front'].append(front)
# end-grain skin on the cut faces of the window
for (a, b, c, d) in [(WIN[0] - 0.02, WIN[0] + 0.0, WIN[2], WIN[3]), (WIN[1], WIN[1] + 0.02, WIN[2], WIN[3])]:
    sk = box('skin', a, b, -6.0, 0.0, c, d); put(sk, M['endgrain']); rig.objs['front'].append(sk)

# ---------------------------------------------------------------- bolt (front half cut away), pegs, lifter
bolt = box('bolt', -70.0, 31.0, -4.0, 4.0, BOLT_Z[0], BOLT_Z[1])
for x in SLOTS:
    boolean(bolt, cyl('bh', PEG_R + 0.2, 20, (x, 0, -2.0), axis='Z', verts=48))
boolean(bolt, box('chan', -80, 23.0, -2.6, 2.6, CH_Z[0] - 1, CH_Z[1]))
boolean(bolt, box('boltcut', -80, 40, -10, 0.0, -20, 20))  # cut-away: the front half
put(bolt, M['bolt'], 0.3, 3)
rig.objs['moving']['bolt'] = [bolt]
for i, x in enumerate(SLOTS):
    p = cyl('peg%d' % i, PEG_R, PEG_L, (x, 0.0, SET_GAP + PEG_L / 2), axis='Z', verts=48)
    put(p, M['peg'], 0.45, 3)
    rig.objs['moving']['peg%d' % i] = [p]
lift = box('lifter_bar', -60.0, 0.6, -1.2, 1.2, -4.6, -3.8)
post = box('lifter_tip', -1.4, 0.6, -1.2, 1.2, -4.6, 0.0)
boolean(post, lift, 'UNION'); put(post, M['lifter'], 0.15, 2)
rig.objs['moving']['lifter'] = [post]

# ---------------------------------------------------------------- light + camera, render
world_hdri(0.08, sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (0, 0, 4)
area_light('key', (-110, -200, 160), AIM, 60, float(arg('--key', '260000')), (1.0, 0.86, 0.70))
area_light('fill', (160, -200, -30), AIM, 100, 8000, (0.9, 0.94, 1.0))
area_light('rim', (40, -30, 180), AIM, 50, 3000, (1.0, 0.92, 0.82))
rig.camera()
render_setup(os.path.join(OUT_DIR, 'ref.png'), RES, SPP, exposure=float(arg('--exp', '0.5')))
rig.gpu()
rig.meta.update({
    'family': 'egyptian', 'travel_px': rig.vec(0.0, TRAVEL, 0.0),
    'slots_px': [rig.px(x, SET_GAP, 0.0) for x in SLOTS],       # peg bottom centre in the set pose
    'shear_px': [rig.px(WIN[0] + 1.0, 0.0, 0.0), rig.px(WIN[1] - 1.0, 0.0, 0.0)],
    'bolt_open_px': rig.vec(-OPEN_SLIDE, 0.0, 0.0),
    'lifter_tip_px': rig.px(-0.4, 0.0, 0.0),                     # lifter rendered with its tip at (0, 0)
    'ppm': rig.ppm(0.0), 'peg_len_mm': PEG_L, 'peg_r_mm': PEG_R,
})
rig.run(PASSES)
