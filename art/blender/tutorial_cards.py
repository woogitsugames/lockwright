# Lockwright — VA-07: the tutorial intro cards as photoreal close-ups of the pin cut-away (art/blender/cutaway.py,
# executed unchanged: same geometry, photo materials and light as the lock screen's plate). One card per idea
# the tutorial explains before a stage (game/scripts/ui/tutorial.gd FRAMES):
#   tension   the tension wrench in the bottom of the keyway, the plug face            (tutorial.frame_tension)
#   lift      the hook under a key pin, the pin stack lifted towards the shear line     (tutorial.frame_lift)
#   set       a set pin: the driver sits on the plug top above the shear line           (tutorial.frame_click)
#   binding   three pin stacks, only the middle one binds against the pick (S2)         (tutorial.s2_intro)
#   overset   a key pin pushed past the shear line, its spring squeezed solid (S3)      (tutorial.s3_intro)
# Nothing is written into the picture: arrows or chalk belong to the game (D-83 chalk language).
# Output: <out-dir>/card_<name>.png (opaque); art/tools or the caller converts to WebP for the game.
#   LW_DEVICE=GPU blender -b -P art/blender/tutorial_cards.py -- --out-dir build/tut --res 480x592 --samples 256
import bpy, math, os, sys
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(HERE, '..', 'renders', 'tutorial_cards')))
RES = arg('--res', '480x592'); SAMPLES = arg('--samples', '128')
CARDS = arg('--cards', 'tension,lift,set,binding,overset').split(',')
os.makedirs(OUT_DIR, exist_ok=True)

SRC = os.path.join(HERE, 'cutaway.py')
src = open(SRC, encoding='utf-8').read().replace('bpy.ops.render.render(write_still=True)', 'pass')
sys.argv = [sys.argv[0], '--', '--out', os.path.join(OUT_DIR, '_scene.png'), '--res', RES, '--samples', SAMPLES]
g = {'__file__': SRC, '__name__': '__main__'}
exec(compile(src, SRC, 'exec'), g)
scene = bpy.context.scene; cam = scene.camera; cd = cam.data
PINS_X, SHEAR = g['PINS_X'], g['SHEAR']
O = bpy.data.objects
STACKS = {s: [O[s + '_key'], O[s + '_drv'], O[s + '_spr']] for s in 'abcde'}
TOOLS = [O['pick'], O['pick_handle']]
YAW, PITCH = math.radians(-22), math.radians(10)   # the lock screen's view direction (cutaway.py)


def frame(target, dist, lens=180.0, yaw=YAW, pitch=PITCH):
    t = Vector(target)
    cam.location = t + Vector((math.sin(yaw) * dist, -math.cos(yaw) * dist * math.cos(pitch), math.sin(pitch) * dist))
    cam.rotation_euler = (t - cam.location).to_track_quat('-Z', 'Y').to_euler()
    cd.lens = lens; cd.dof.use_dof = True; cd.dof.focus_distance = dist; cd.dof.aperture_fstop = 22
    cd.shift_x = cd.shift_y = 0.0


def show(objs, on=True):
    for o in objs:
        o.hide_render = not on


def free_copy(src_stack, dx, tag):
    """A free (resting) pin stack copied from stack e and moved along the plug by dx mm."""
    out = []
    for o in STACKS[src_stack]:
        c = o.copy(); c.data = o.data; c.name = '%s_%s' % (o.name, tag)
        scene.collection.objects.link(c); c.matrix_world = Matrix.Translation((dx, 0, 0)) @ o.matrix_world
        out.append(c)
    return out


def render(name):
    scene.render.filepath = os.path.join(OUT_DIR, 'card_%s.png' % name)
    bpy.ops.render.render(write_still=True)
    print('WROTE', scene.render.filepath, flush=True)


base_hidden = {o.name: o.hide_render for o in O}
extra = []
for name in CARDS:
    for o in O:
        if o.name in base_hidden: o.hide_render = base_hidden[o.name]
    for o in extra: o.hide_render = True
    if name == 'tension':     # the wrench leg in the keyway and the plug face; no pick yet
        show(TOOLS, False)
        frame((-1.5, 0.0, -5.5), 80.0)
    elif name == 'lift':      # the hook raising pin c towards the shear line
        frame((PINS_X[2] + 0.4, 0.0, 4.0), 60.0)
    elif name == 'set':       # pin a: driver above the shear line on the plug top, key pin dropped
        show(TOOLS, False)
        frame((PINS_X[0] + 0.3, 0.0, SHEAR + 0.6), 46.0)
    elif name == 'binding':   # b, c, d: only c binds against the hook; b and d rest (copies of the free stack e)
        if not extra:
            extra += free_copy('e', PINS_X[1] - PINS_X[4], 'b') + free_copy('e', PINS_X[3] - PINS_X[4], 'd')
        show(STACKS['a'] + STACKS['b'] + STACKS['d'] + STACKS['e'], False); show(extra, True)
        frame((PINS_X[2], 0.0, 6.5), 82.0)
    elif name == 'overset':   # pin d: key pin past the shear line, spring squeezed solid
        show(TOOLS, False)
        frame((PINS_X[3] + 0.3, 0.0, 8.0), 54.0)
    else:
        sys.exit('tutorial_cards: unknown card %s' % name)
    render(name)
