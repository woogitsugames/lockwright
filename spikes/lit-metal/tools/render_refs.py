# Spike 4: Cycles renders used by the Godot spike.
#   blender -b -P spikes/lit-metal/tools/render_refs.py -- --what reference --res 1236x1650 --samples 96 --out X.png
#   --what reference : the full cutaway (comparison target, same as art/renders/section.png at another size)
#   --what plate     : plan B background: static parts only (moving parts hidden from camera, still in reflections/shadows)
#   --what matcap    : one matcap per moving material (steel, brass_k, spring, pick): a sphere at the aim point,
#                      seen by the scene camera's direction under the same lights; --out is a directory
# art/ is read-only for this session: the scene script runs unchanged, only its render call is disabled.
import bpy, sys, os, math

HERE = os.path.dirname(os.path.abspath(__file__))
SCENE_SRC = os.path.abspath(os.path.join(HERE, '..', '..', '..', 'art', 'blender', 'cutaway.py'))
argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default
WHAT = arg('--what', 'reference'); RES = arg('--res', '1236x1650'); SAMPLES = arg('--samples', '96'); OUT = arg('--out', '/tmp/ref.png')

src = open(SCENE_SRC).read().replace('bpy.ops.render.render(write_still=True)', 'pass')
sys.argv = [sys.argv[0], '--', '--out', OUT if WHAT != 'matcap' else '/tmp/lw_matcap.png', '--res', RES, '--samples', SAMPLES]
g = {'__file__': SCENE_SRC, '__name__': '__main__'}
exec(compile(src, SCENE_SRC, 'exec'), g)
scene = bpy.context.scene
from mathutils import Vector

MOVING = [f'{p}_{k}' for p in 'abcde' for k in ('key', 'drv', 'spr')] + ['pick', 'pick_handle']

if WHAT == 'reference':
    bpy.ops.render.render(write_still=True)
elif WHAT == 'plate':
    for n in MOVING:
        bpy.data.objects[n].visible_camera = False
    bpy.ops.render.render(write_still=True)
elif WHAT == 'matcap':
    os.makedirs(OUT, exist_ok=True)
    cam = scene.camera
    fwd = (cam.matrix_world.to_3x3() @ Vector((0, 0, -1))).normalized()
    centre = Vector((13.5, -6.0, 9.0))  # in front of the cut plane, in the same light field as the pins
    for o in bpy.data.objects:
        if o.type in ('MESH', 'CURVE'):
            o.visible_camera = False
    bpy.ops.mesh.primitive_uv_sphere_add(segments=128, ring_count=64, radius=2.0, location=centre)
    sph = bpy.context.object
    for p in sph.data.polygons: p.use_smooth = True
    c2 = bpy.data.cameras.new('mc'); co = bpy.data.objects.new('mc', c2); scene.collection.objects.link(co)
    c2.type = 'ORTHO'; c2.ortho_scale = 4.0
    co.location = centre - fwd * 60; co.rotation_euler = cam.rotation_euler
    scene.camera = co
    scene.render.resolution_x = scene.render.resolution_y = 512
    scene.render.film_transparent = True
    for m in ('steel', 'brass_k', 'spring', 'pick', 'brass', 'nickel'):
        sph.data.materials.clear(); sph.data.materials.append(bpy.data.materials[m])
        scene.render.filepath = os.path.join(OUT, f'matcap_{m}.png')
        bpy.ops.render.render(write_still=True)
print('RENDER-DONE', WHAT)
