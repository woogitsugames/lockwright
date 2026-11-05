# Lockwright — plan-B plates for the `warded` lock screen, in the photo-material look of
# art/renders/warded.png (N-63). Runs the scene of art/blender/warded.py unchanged (read only) and
# renders three passes at its camera (identical to the GEM2 rig in
# game/assets/photoreal_families/warded/scene.json, so the baked GLB lines up):
#   parts.png  everything except the two decorative ward rings: the moving parts (probe, bit, bolt,
#              tumbler, stud, leaf spring) are projected from it at their rest pose (plate_rest)
#   plate.png  the static lock: no moving parts, no rings (the game draws the lock's own wards)
#   wards.png  an iron annulus slab on the back plate (r 16..30 mm around the drill pin); the game
#              cuts the lock's ward fences out of it (screen-projected, like the plate)
# Run (CPU is fine, OIDN denoise):
#   blender -b -P art/blender/plates/warded_photo_plate.py -- --out-dir game/assets/photoreal_families/warded/photo \
#       --res 1236x1650 --samples 64
import bpy, math, os, sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
ROOT_DIR = os.path.abspath(os.path.join(BLENDER_DIR, '..', '..'))
sys.path.insert(0, BLENDER_DIR)

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def _arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default

OUT_DIR = os.path.abspath(_arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'warded', 'photo')))
RES = _arg('--res', '1236x1650')
SAMPLES = _arg('--samples', '64')
os.makedirs(OUT_DIR, exist_ok=True)

# warded.py reads its own CLI (--res/--samples/--out): hand it ours, then run it without its final render.
sys.argv = [sys.argv[0], '--', '--res', RES, '--samples', SAMPLES, '--out', os.path.join(OUT_DIR, 'parts.png')]
src = open(os.path.join(BLENDER_DIR, 'warded.py'), encoding='utf-8').read()
src = src.replace('bpy.ops.render.render(write_still=True)', 'pass  # rendered by warded_photo_plate.py')
g = {'__file__': os.path.join(BLENDER_DIR, 'warded.py'), '__name__': '__warded__'}
exec(compile(src, 'warded.py', 'exec'), g)

scene = bpy.context.scene
MOVING = ('probe_tube', 'bit', 'bolt', 'tumbler', 'tstud', 'leaf')
objs = list(bpy.data.objects)
rings = [o for o in objs if o.name.split('.')[0] in ('ward', 'wr')]
moving = [o for o in objs if o.name.split('.')[0] in MOVING]
print('RINGS', [o.name for o in rings])
print('MOVING', [o.name for o in moving])


def hide(lst, on):
    for o in lst:
        o.hide_render = on


def render(name):
    scene.render.filepath = os.path.join(OUT_DIR, name)
    bpy.ops.render.render(write_still=True)
    print('WROTE', scene.render.filepath)


hide(rings, True)
render('parts.png')
hide(moving, True)
render('plate.png')

# ward layer: one annulus slab of the ward iron on the back plate (Blender Y = depth, plate at DEPTH)
PIN, DEPTH = g['PIN'], g['DEPTH']
slab = g['sector']('wardslab', 16.0, 30.0, -180.0, 180.0, DEPTH - 3.0, DEPTH + 0.05, n=128)
g['put'](slab, g['MAT']['ward'], 0.22, 3)
render('wards.png')
