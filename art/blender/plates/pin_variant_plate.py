# Lockwright — VA-10: own static section for the two D-59 families built on the pin cut-away
# (LOCKS.md §2.20 dimple, §2.25 magnetic). Runs art/blender/cutaway.py unchanged (same camera, same
# moving pins, same plug), like game/assets/photoreal/tools/render_plate.py, then changes only static
# parts that the game's moving pins never cover, so the pin screen's GLB, PinPose and hit-testing stay valid:
#   dimple    the lower keyway is filled (a flat slot for a flat dimple key) and four side-drilled
#             chambers come up from below at alternating angles between the top pins, each with its own
#             key pin, driver and spring: "pins from more than one direction onto the key's flat".
#   magnetic  the lower keyway is filled and four magnet rotors sit in round pockets below it, each a
#             two-tone disc (polarity halves, nickel / black) turned to its own angle, with a steel axle.
# Outputs (camera, size and moving-part removal identical to the pin plate):
#   --out  plate_<variant>_1236x1650.png   static plate (moving pins, springs, pick removed)
#   --ref  ref_<variant>.png               optional: the same frame with the pins in, no hook (contact sheet)
# Run:
#   blender -b -P art/blender/plates/pin_variant_plate.py -- --variant dimple --res 2472x3300 --samples 128 \
#       --out game/assets/photoreal/plate/plate_dimple_1236x1650.png      (LW_DEVICE=GPU for the GPU)
import bpy, math, os, sys
from mathutils import Matrix, Vector

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
ROOT_DIR = os.path.abspath(os.path.join(BLENDER_DIR, '..', '..'))
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default
VARIANT = arg('--variant', 'dimple')
RES = arg('--res', '1236x1650'); SAMPLES = arg('--samples', '64')
OUT = os.path.abspath(arg('--out', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal', 'plate', 'plate_%s_1236x1650.png' % VARIANT)))
REF = arg('--ref', '')

SCENE_SRC = os.path.join(BLENDER_DIR, 'cutaway.py')
src = open(SCENE_SRC, encoding='utf-8').read().replace('bpy.ops.render.render(write_still=True)', 'pass')
sys.argv = [sys.argv[0], '--', '--out', OUT, '--res', RES, '--samples', SAMPLES]
g = {'__file__': SCENE_SRC, '__name__': '__main__'}
exec(compile(src, SCENE_SRC, 'exec'), g)
for k in ('M', 'LEN', 'KEYWAY', 'R_PLUG', 'R_HOUSE', 'box', 'cyl', 'boolean', 'link', 'bevel', 'lathe', 'spring', 'photo_mat', 'dark_mat'):
    globals()[k] = g[k]

plug = bpy.data.objects['plug']; house = bpy.data.objects['housing']
MAG = {
    'north': photo_mat('ph_mag_n', 'nickel_satin', scale=8, rot=0, base=(0.72, 0.72, 0.70), base_mix=0.35, rough_add=0.05, bump=0.1, wear=0.3),
    'south': photo_mat('ph_mag_s', 'nickel_satin', scale=8, rot=90, base=(0.035, 0.035, 0.04), base_mix=0.85, rough_add=0.15, bump=0.1, grime=0.3),
}


def bake(o):
    """Apply the bevel/normal modifiers, so later cuts work on the final mesh."""
    for ob in bpy.context.selected_objects: ob.select_set(False)
    o.select_set(True); bpy.context.view_layer.objects.active = o
    for md in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=md.name)


def cut(target, cutter, solver='EXACT', keep=False):
    bpy.context.view_layer.update()
    md = target.modifiers.new('b', 'BOOLEAN'); md.operation = 'DIFFERENCE'; md.object = cutter; md.solver = solver
    if solver == 'EXACT': md.use_self = True
    bpy.context.view_layer.objects.active = target; bpy.ops.object.modifier_apply(modifier=md.name)
    if not keep: bpy.data.objects.remove(cutter, do_unlink=True)


bake(plug); bake(house)
fill = None
def fill_keyway(z_top):
    """Close the keyway below z_top (a separate plug-brass block, so the cut faces stay clean)."""
    global fill
    fill = box('kw_fill', 0.4, LEN - 1.6, 0.0, 2.05, KEYWAY[0] - 0.05, z_top)
    link(fill, M['brass'])


if VARIANT == 'dimple':
    SLOT_FLOOR = -1.5
    fill_keyway(SLOT_FLOOR)
    for i, x in enumerate([7.0, 11.0, 15.0, 19.0]):
        ang = math.radians(-24.0)               # one slanted side row (down and towards the bolt side)
        th = math.pi + ang                       # body direction: down and to the side
        u = Vector((math.sin(th), 0.0, math.cos(th)))
        P = Vector((x, 0.0, SLOT_FLOOR + 0.25))  # key-pin tip just proud of the slot floor (on the key's flat)
        L = 9.0
        b = cyl('side_bore', 0.98, L, (0.0, 0.0, 0.0), axis='Z', verts=40)
        b.matrix_world = Matrix.Translation(P + u * (L / 2 - 0.2)) @ Matrix.Rotation(th, 4, 'Y')
        for tgt in (plug, house, fill):
            cut(tgt, b, keep=True)
        bpy.data.objects.remove(b, do_unlink=True)
        kp = lathe('side_key%d' % i, [(0.02, 0.0), (0.4, 0.1), (0.75, 0.35), (0.85, 0.6), (0.85, 4.3), (0.75, 4.45)], 0.0, y=0.9)
        link(kp, M['brass_k'])
        dr = lathe('side_drv%d' % i, [(0.75, 4.5), (0.85, 4.62), (0.85, 6.2), (0.75, 6.32)], 0.0, y=0.9)
        link(dr, M['steel'])
        sp = spring('side_spr%d' % i, 0.0, 6.36, 8.3, 4, r=0.62, wire=0.14, y=0.9)
        for o in (kp, dr, sp):
            o.matrix_world = Matrix.Translation(P) @ Matrix.Rotation(th, 4, 'Y') @ o.matrix_world
elif VARIANT == 'magnetic':
    fill_keyway(-2.4)
    for i, x in enumerate([7.0, 11.0, 15.0, 19.0]):
        c = Vector((x, 0.0, -4.35)); r = 1.32
        pk = cyl('rotor_pocket', r + 0.14, 5.0, (c.x, 0.0, c.z), axis='Y', verts=64)
        for tgt in (plug, fill):
            cut(tgt, pk, keep=True)
        bpy.data.objects.remove(pk, do_unlink=True)
        rot = math.radians([20.0, 110.0, -35.0, 70.0][i])
        for half, mat in ((0, MAG['north']), (1, MAG['south'])):
            d = cyl('rotor%d_%d' % (i, half), r, 1.8, (0.0, 0.9 + 0.02, 0.0), axis='Y', verts=64)
            # keep one half (z >= 0 for N, z <= 0 for S), then turn the rotor to its angle
            boolean(d, box('half', -3, 3, -1, 4, -3, 0.0) if half == 0 else box('half', -3, 3, -1, 4, 0.0, 3))
            link(d, mat); bevel(d, 0.08, 2)
            d.matrix_world = Matrix.Translation(c) @ Matrix.Rotation(rot, 4, 'Y') @ d.matrix_world
        ax = cyl('rotor_axle%d' % i, 0.32, 2.2, (c.x, 1.0, c.z), axis='Y', verts=24); link(ax, M['steel'])
        gr = box('rotor_mark%d' % i, -0.12, 0.12, -0.05, 0.05, r * 0.45, r * 0.92)  # a filed index mark on the N half
        link(gr, MAG['south']); gr.matrix_world = Matrix.Translation(c) @ Matrix.Rotation(rot, 4, 'Y') @ gr.matrix_world
else:
    raise SystemExit('pin_variant_plate: --variant dimple|magnetic')

scene = bpy.context.scene
MOVING = [f'{p}_{k}' for p in 'abcde' for k in ('key', 'drv', 'spr')] + ['pick', 'pick_handle']
if REF:  # pins in, the hook out (the game draws the family's own tool layer instead)
    for n in ('pick', 'pick_handle'):
        bpy.data.objects[n].hide_render = True
    scene.render.filepath = os.path.abspath(REF)
    bpy.ops.render.render(write_still=True)
    print('WROTE', scene.render.filepath)
for n in MOVING:
    bpy.data.objects[n].hide_render = True
scene.render.filepath = OUT
bpy.ops.render.render(write_still=True)
print('PLATE-DONE', OUT)
