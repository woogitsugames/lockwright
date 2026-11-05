# Lockwright photoreal lock screen: Cycles plate for plan B (D-31) — the static scene only.
#   blender -b -t 2 -P game/assets/photoreal/tools/render_plate.py -- --res 1236x1650 --samples 64 \
#       --out game/assets/photoreal/plate/plate_1236x1650.png [--scene art/blender/cutaway.py]
# Unlike spikes/lit-metal/tools/render_refs.py (--what plate), the moving parts (pins, springs, pick)
# are removed from the render entirely (hide_render), so they leave no baked shadow or reflection in
# the plate: in the game they move, and a shadow at the Blender pose would show as a ghost.
# The plug and the tension wrench stay in the plate (the game turns them a little, plate_rest.gdshader).
# art/blender/cutaway.py runs unchanged; only its final render call is disabled.
import bpy, sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..', '..'))
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default
SCENE_SRC = os.path.abspath(arg('--scene', os.path.join(ROOT, 'art', 'blender', 'cutaway.py')))
RES = arg('--res', '1236x1650'); SAMPLES = arg('--samples', '64')
OUT = os.path.abspath(arg('--out', os.path.join(HERE, '..', 'plate', 'plate_1236x1650.png')))

src = open(SCENE_SRC).read().replace('bpy.ops.render.render(write_still=True)', 'pass')
sys.argv = [sys.argv[0], '--', '--out', OUT, '--res', RES, '--samples', SAMPLES]
exec(compile(src, SCENE_SRC, 'exec'), {'__file__': SCENE_SRC, '__name__': '__main__'})

MOVING = [f'{p}_{k}' for p in 'abcde' for k in ('key', 'drv', 'spr')] + ['pick', 'pick_handle']
for n in MOVING:
    bpy.data.objects[n].hide_render = True
bpy.ops.render.render(write_still=True)
print('PLATE-DONE', OUT)
