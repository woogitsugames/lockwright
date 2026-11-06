# GPU readability render: keep warded.py geometry/materials/camera and add a ward-only key.
# blender -b -P art/blender/warded_contrast.py -- --out art/renders/warded.png \
#     --res 1620x2160 --samples 128 --ward-key 100000
# Light linking: https://docs.blender.org/manual/en/4.2/render/cycles/object_settings/light_linking.html
import bpy
import os

source = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'warded.py')
with open(source, encoding='utf-8') as stream:
    code = stream.read().replace('bpy.ops.render.render(write_still=True)', 'pass')
g = {'__file__': source, '__name__': '__warded_contrast__'}
exec(compile(code, source, 'exec'), g)

receivers = bpy.data.collections.new('ward_readability_receivers')
for obj in bpy.data.objects:
    if obj.name.split('.')[0] in ('ward', 'wr'):
        receivers.objects.link(obj)
aim = bpy.data.objects.new('ward_readability_aim', None)
bpy.context.scene.collection.objects.link(aim)
pin = g['PIN']
aim.location = (pin.x, 4.0, pin.z)
energy = float(g['arg']('--ward-key', '100000'))
g['area_light']('ward_readability_key', (-25, -80, 30), aim, 35, energy, (1.0, 0.95, 0.88))
bpy.data.objects['ward_readability_key'].light_linking.receiver_collection = receivers
bpy.context.scene.cycles.use_light_tree = True
print('WARD_READABILITY_KEY', energy, 'receivers', [o.name for o in receivers.objects])
bpy.ops.render.render(write_still=True)
