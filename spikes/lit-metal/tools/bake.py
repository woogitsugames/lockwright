# Spike 4: bakes the procedural Cycles materials of art/blender/cutaway.py to textures and
# exports the scene for Godot. art/ is read-only for this session, so the scene script is
# executed as-is with only its final render call disabled.
#
#   blender -b -P spikes/lit-metal/tools/bake.py -- [--size 2048] [--ao-samples 64] [--quick]
#
# Output (spikes/lit-metal/assets/):
#   cutaway_baked.glb          meshes (modifiers applied, springs as meshes), UVs per material atlas,
#                              material names kept; node names kept for animation (a_key, a_drv, ...)
#   tex/<mat>_albedo.png       base colour (sRGB), incl. the crevice grime of the node material
#   tex/<mat>_normal.png       tangent-space normal (OpenGL convention, +Y), incl. machining bump
#   tex/<mat>_orm.png          R = ambient occlusion, G = roughness, B = metallic
#   scene.json                 lights, camera, exposure, world strength (Godot builds the rig from it)
import bpy, sys, os, json, math, time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
SCENE_SRC = os.path.join(ROOT, 'art', 'blender', 'cutaway.py')
OUT = os.path.join(HERE, '..', 'assets')

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default
SIZE = int(arg('--size', '2048'))
AO_SAMPLES = int(arg('--ao-samples', '64'))
QUICK = '--quick' in argv

# ---------------------------------------------------------------- build the scene (no render)
src = open(SCENE_SRC).read()
assert 'bpy.ops.render.render(write_still=True)' in src
src = src.replace('bpy.ops.render.render(write_still=True)', 'pass')
sys.argv = [sys.argv[0], '--', '--out', '/tmp/lw_unused.png', '--res', '1236x1650']
g = {'__file__': SCENE_SRC, '__name__': '__main__'}
exec(compile(src, SCENE_SRC, 'exec'), g)
scene = bpy.context.scene
os.makedirs(os.path.join(OUT, 'tex'), exist_ok=True)

def select_only(objs):
    bpy.ops.object.mode_set(mode='OBJECT') if bpy.context.object and bpy.context.object.mode != 'OBJECT' else None
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]

# ---------------------------------------------------------------- meshes: curves -> mesh, apply modifiers
for o in list(bpy.data.objects):
    if o.type in ('MESH', 'CURVE'):
        select_only([o])
        bpy.ops.object.convert(target='MESH')
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
import bmesh
for o in meshes:  # tangent space (normal bake, glTF tangents) needs tris/quads
    bm = bmesh.new(); bm.from_mesh(o.data)
    ngons = [f for f in bm.faces if len(f.verts) > 4]
    if ngons:
        bmesh.ops.triangulate(bm, faces=ngons)
        bm.to_mesh(o.data)
    bm.free()

# ---------------------------------------------------------------- per-material atlases
by_mat = {}
for o in meshes:
    by_mat.setdefault(o.data.materials[0].name, []).append(o)
small = {'spring': 1024, 'iron': 1024, 'handle': 512, 'recess': 512, 'steel': 1024, 'brass_k': 1024, 'pick': 1024}
info = {}
for name, objs in by_mat.items():
    select_only(objs)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=0.004, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.pack_islands(margin=0.004, rotate=True)
    bpy.ops.object.mode_set(mode='OBJECT')
    info[name] = {'objects': [o.name for o in objs], 'size': min(SIZE, small.get(name, SIZE))}

# ---------------------------------------------------------------- bake
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.render.bake.margin = 16
scene.render.bake.use_clear = True

def principled(mat):
    return next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')

def bake(name, kind, colorspace, samples):
    mat = bpy.data.materials[name]
    size = info[name]['size']
    img = bpy.data.images.new(f'{name}_{kind}', size, size, alpha=False, float_buffer=(kind == 'normal'))
    img.colorspace_settings.name = colorspace
    node = mat.node_tree.nodes.new('ShaderNodeTexImage'); node.image = img
    for n in mat.node_tree.nodes:
        n.select = False
    node.select = True; mat.node_tree.nodes.active = node
    select_only([bpy.data.objects[o] for o in info[name]['objects']])
    scene.cycles.samples = samples
    t0 = time.time()
    if kind == 'albedo':
        bsdf = principled(mat); metal = bsdf.inputs['Metallic'].default_value
        bsdf.inputs['Metallic'].default_value = 0.0  # diffuse colour pass is black for metals
        bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'})
        bsdf.inputs['Metallic'].default_value = metal
    elif kind == 'rough':
        bpy.ops.object.bake(type='ROUGHNESS')
    elif kind == 'normal':
        bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT')
    elif kind == 'ao':
        bpy.ops.object.bake(type='AO')
    mat.node_tree.nodes.remove(node)
    print(f'baked {name}_{kind} {size}px in {time.time() - t0:.1f}s', flush=True)
    return img

import numpy as np
def pixels(img):
    a = np.empty(img.size[0] * img.size[1] * 4, dtype=np.float32); img.pixels.foreach_get(a)
    return a.reshape(img.size[1], img.size[0], 4)

def save(arr, path, colorspace='Non-Color'):
    h, w = arr.shape[:2]
    img = bpy.data.images.new(os.path.basename(path), w, h, alpha=False)
    img.colorspace_settings.name = colorspace
    rgba = np.ones((h, w, 4), dtype=np.float32); rgba[..., :3] = arr[..., :3]
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = path; img.file_format = 'PNG'
    img.save()

for name in by_mat:
    bsdf = principled(bpy.data.materials[name])
    metal = bsdf.inputs['Metallic'].default_value
    info[name]['metallic'] = metal
    info[name]['anisotropy'] = bsdf.inputs['Anisotropic'].default_value
    info[name]['coat'] = bsdf.inputs['Coat Weight'].default_value
    s = 1 if QUICK else 4
    alb = bake(name, 'albedo', 'sRGB', s)
    save(pixels(alb), os.path.join(OUT, 'tex', f'{name}_albedo.png'), 'sRGB')
    rough = pixels(bake(name, 'rough', 'Non-Color', s))
    nrm = pixels(bake(name, 'normal', 'Non-Color', s))
    save(nrm, os.path.join(OUT, 'tex', f'{name}_normal.png'))
    ao = pixels(bake(name, 'ao', 'Non-Color', 4 if QUICK else AO_SAMPLES))
    orm = np.zeros_like(rough)
    orm[..., 0] = ao[..., 0]; orm[..., 1] = rough[..., 0]; orm[..., 2] = metal
    save(orm, os.path.join(OUT, 'tex', f'{name}_orm.png'))

# ---------------------------------------------------------------- rig for Godot (glTF axes: x, z, -y)
def gl(v):
    return [v[0], v[2], -v[1]]
bpy.context.view_layer.update()
lights = []
for o in bpy.data.objects:
    if o.type == 'LIGHT':
        mw = o.matrix_world
        fwd = (mw.to_3x3() @ __import__('mathutils').Vector((0, 0, -1))).normalized()
        lights.append({'name': o.name, 'type': o.data.type, 'position': gl(mw.translation), 'direction': gl(fwd),
                       'size': getattr(o.data, 'size', 0.0), 'energy_w': o.data.energy, 'color': list(o.data.color)})
cam = scene.camera
rig = {
    'units': '1 Blender unit = 1 mm = 1 Godot unit',
    'camera': {'position': gl(cam.matrix_world.translation), 'lens_mm': cam.data.lens, 'sensor_width_mm': cam.data.sensor_width,
               'sensor_fit': cam.data.sensor_fit,
               'hfov_deg': math.degrees(2 * math.atan(cam.data.sensor_width / 2 / cam.data.lens)),
               'target': gl(g['target'])},
    'aim': gl(bpy.data.objects['aim'].location),
    'lights': lights,
    'world_strength': scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value,
    'world_hdri': 'interior.exr (Blender bundled studio light)',
    'exposure': scene.view_settings.exposure, 'view_transform': scene.view_settings.view_transform,
    'look': scene.view_settings.look,
    'materials': info,
}
json.dump(rig, open(os.path.join(OUT, 'scene.json'), 'w'), indent=1)

# ---------------------------------------------------------------- export: simple materials keep their names
for name in by_mat:
    mat = bpy.data.materials[name]
    nt = mat.node_tree
    for n in list(nt.nodes):
        if n.type not in ('BSDF_PRINCIPLED', 'OUTPUT_MATERIAL'):
            nt.nodes.remove(n)
for o in bpy.data.objects:
    o.select_set(o.type in ('MESH', 'CAMERA'))
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, 'cutaway_baked.glb'), use_selection=True, export_apply=True,
                          export_tangents=True, export_cameras=True, export_lights=False, export_yup=True)
# The bundled HDRI (also used by the Cycles reference) for the Godot sky.
hdri = os.path.join(bpy.utils.resource_path('LOCAL'), 'datafiles', 'studiolights', 'world', 'interior.exr')
img = bpy.data.images.load(hdri)  # Godot cannot read this EXR's compression: write Radiance HDR
scene.render.image_settings.file_format = 'HDR'; scene.view_settings.view_transform = 'Standard'
img.save_render(os.path.join(OUT, 'interior.hdr'), scene=scene)
print('BAKE-DONE', json.dumps({k: v['size'] for k, v in info.items()}))
