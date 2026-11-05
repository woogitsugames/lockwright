# Lockwright photoreal lock screen: Cycles plate for plan B (D-31) — the static scene only,
# supporting --pins N (1..7) and --wrench-in-frame.
# Modeled on game/assets/photoreal/tools/render_plate.py.
#   blender -b -P art/blender/variants/render_plate_n.py -- --pins 5 --res 2160x2880 --samples 256 \
#       --out art/renders/variants/plates/plate_5pin.png [--wrench-in-frame] [--tension-angle 9.5]
import bpy, sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
SCENE_SRC = os.path.join(HERE, 'cutaway_n.py')
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []

if '--plate' not in argv:
    sys.argv.append('--plate')

src = open(SCENE_SRC, encoding='utf-8').read()
exec(compile(src, SCENE_SRC, 'exec'), {'__file__': SCENE_SRC, '__name__': '__main__'})
print('PLATE-DONE')
