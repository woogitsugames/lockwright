# Lockwright — plan-B plates in the photo-material look (N-63) for `wafer` and `lever`.
# Runs the look-dev scene art/blender/<family>.py (read only), puts its moving parts in the rest
# pose of the baked GLB (art/blender/plates/<family>_plate.py, same camera), then renders:
#   parts.png  everything (the game projects the moving parts from it at their rest pose)
#   plate.png  the static lock without the moving parts
# Run (CPU is fine, OIDN denoise):
#   blender -b -P art/blender/plates/photo_plates.py -- --family wafer \
#       --out-dir game/assets/photoreal_families/wafer/photo --res 1236x1650 --samples 48
import bpy, os, sys

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
ROOT_DIR = os.path.abspath(os.path.join(BLENDER_DIR, '..', '..'))
sys.path.insert(0, BLENDER_DIR)

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def _arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default

FAMILY = _arg('--family', 'wafer')
OUT_DIR = os.path.abspath(_arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', FAMILY, 'photo')))
RES = _arg('--res', '1236x1650')
SAMPLES = _arg('--samples', '48')
PASSES = _arg('--passes', 'parts,plate').split(',')
DETECTOR = _arg('--detector', '0')  # lever: 1 = the detector lever in (parts_detector.png)
os.makedirs(OUT_DIR, exist_ok=True)

CONFIG = {
    # GLB rest: every wafer set (dz 0), as wafer_plate.py
    'wafer': {
        'replace': [("STATE = [('set', 0.0, 0.0, 0.0), ('set', 0.0, 0.0, 0.0), ('bind', -0.7, 1.3, 0.06), ('over', 1.4, 0.0, 0.0), ('free', -1.8, 0.0, 0.0)]",
                     "STATE = [('set', 0.0, 0.0, 0.0) for _ in range(5)]")],
        'moving': ['wafer%d' % i for i in range(5)] + ['wspr%d' % i for i in range(5)] + ['pick', 'pick_handle'],
    },
    # GLB rest: every lever at its needed lift (gate on the stump), as lever_plate.py
    'lever': {
        'replace': [('(0.9, 3.5, 1.5, -11.2)', '(0.9, 3.5, 3.5, -11.2)'), ('(7.3, 3.0, 5.0, -11.6)', '(7.3, 3.0, 3.0, -11.6)')],
        'moving': ['lever%d' % i for i in range(3)] + ['spring%d' % i for i in range(3)] + ['rivet%d' % i for i in range(3)]
                  + ['detector', 'stump', 'lifter', 'tension', 'tension_shaft'],
    },
}[FAMILY]

sys.argv = [sys.argv[0], '--', '--res', RES, '--samples', SAMPLES, '--out', os.path.join(OUT_DIR, 'parts.png')] + (['--detector', DETECTOR] if FAMILY == 'lever' else [])
src = open(os.path.join(BLENDER_DIR, FAMILY + '.py'), encoding='utf-8').read()
for a, b in CONFIG['replace']:
    if a not in src:
        raise SystemExit('photo_plates: %s.py changed, rest pose line not found: %s' % (FAMILY, a))
    src = src.replace(a, b)
src = src.replace('bpy.ops.render.render(write_still=True)', 'pass  # rendered by photo_plates.py')
g = {'__file__': os.path.join(BLENDER_DIR, FAMILY + '.py'), '__name__': '__lw_family__'}
exec(compile(src, FAMILY + '.py', 'exec'), g)

scene = bpy.context.scene
moving = [o for o in bpy.data.objects if o.name.split('.')[0] in CONFIG['moving']]
print('MOVING', sorted(o.name for o in moving))


def render(name):
    if name.split('.')[0] not in PASSES:
        return
    if DETECTOR == '1':
        name = name.replace('.png', '_detector.png')
    scene.render.filepath = os.path.join(OUT_DIR, name)
    bpy.ops.render.render(write_still=True)
    print('WROTE', scene.render.filepath)


render('parts.png')
for o in moving:
    o.hide_render = True
render('plate.png')
