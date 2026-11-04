# Lockwright look-dev: leather tool roll seen from above (lives = spare picks; empty pocket = lost pick).
#   blender -b -P art/blender/tray.py -- --out art/renders/tray.png --res 824x730 --samples 96
import bpy, bmesh, math, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lw_common import *
from mathutils import Vector

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(n, d): return argv[argv.index(n) + 1] if n in argv else d
OUT = arg('--out', 'tray.png'); RES = [int(v) for v in arg('--res', '824x330').split('x')]; SAMPLES = int(arg('--samples', '96'))
LOST = int(arg('--lost', '1'))

def leather(name, color, rough=0.62):
    m = bpy.data.materials.new(name); m.use_nodes = True; n = m.node_tree.nodes; l = m.node_tree.links
    b = n['Principled BSDF']; b.inputs['Roughness'].default_value = rough; b.inputs['Sheen Weight'].default_value = 0.3
    tc = n.new('ShaderNodeTexCoord')
    vor = n.new('ShaderNodeTexVoronoi'); vor.inputs['Scale'].default_value = 1.6; l.new(tc.outputs['Object'], vor.inputs['Vector'])
    noi = n.new('ShaderNodeTexNoise'); noi.inputs['Scale'].default_value = 0.08; noi.inputs['Detail'].default_value = 6; l.new(tc.outputs['Object'], noi.inputs['Vector'])
    cr = n.new('ShaderNodeValToRGB'); cr.color_ramp.elements[0].color = (*[c * 0.55 for c in color], 1); cr.color_ramp.elements[1].color = (*color, 1)
    l.new(noi.outputs['Fac'], cr.inputs['Fac']); l.new(cr.outputs['Color'], b.inputs['Base Color'])
    bump = n.new('ShaderNodeBump'); bump.inputs['Strength'].default_value = 0.25; l.new(vor.outputs['Distance'], bump.inputs['Height']); l.new(bump.outputs['Normal'], b.inputs['Normal'])
    return m
LE = leather('leather', (0.34, 0.18, 0.085)); LE2 = leather('pocket', (0.24, 0.12, 0.055), 0.7); LE3 = leather('imprint', (0.10, 0.05, 0.025), 0.8)

# roll body; three pockets side by side, tools standing up, tips out (wear is visible on the tips)
base = box('roll', -80, 80, -2, 0, -80, 60); base.data.materials.append(LE); bevel(base, 1.2, 4)
for i in range(3):
    x = -36 + i * 36
    flap = box('flap%d' % i, x - 14, x + 14, -4.6, -2, -80, -4); flap.data.materials.append(LE2); bevel(flap, 2.0, 6)
    for k in range(16):  # stitching along both sides of the flap
        for sx in (x - 12.2, x + 11.6):
            st = box('st', sx, sx + 0.6, -4.75, -4.5, -78 + k * 4.6, -76.6 + k * 4.6); st.data.materials.append(M['handle'])
    if i >= 3 - LOST:
        imp = box('imprint%d' % i, x - 1.4, x + 1.4, -2.04, -1.95, -4, 30); imp.data.materials.append(LE3)  # worn imprint of the lost pick
        continue
    if i == 0:   # hook: worn tip with burrs
        pts = [(x, -60), (x, 18), (x + 0.6, 24), (x + 3.2, 28), (x + 6.4, 29.5)]
    elif i == 1:  # rake: three humps
        pts = [(x, -60), (x, 14), (x + 1.8, 18), (x, 22), (x + 1.8, 26), (x, 30)]
    t = flat_tool('pick%d' % i, pts, 1.8, 0.6, -2.7)
    if i == 0:
        for k in range(3):
            bb = box('burr', x + 5.2 + k * 0.6, x + 5.8 + k * 0.6, -3.4, -2.7, 29.2 + k * 0.4, 30.1 + k * 0.4); bb.data.materials.append(M['pick'])
# light + camera (top-down, slight tilt)
w = scene.world = bpy.data.worlds.new('w'); w.use_nodes = True
env = w.node_tree.nodes.new('ShaderNodeTexEnvironment')
env.image = bpy.data.images.load(os.path.join(bpy.utils.resource_path('LOCAL'), 'datafiles', 'studiolights', 'world', 'interior.exr'))
w.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.3
w.node_tree.links.new(env.outputs['Color'], w.node_tree.nodes['Background'].inputs['Color'])
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM)
def area(name, loc, size, energy, color):
    bpy.ops.object.light_add(type='AREA', location=loc); L = bpy.context.object; L.data.size = size; L.data.energy = energy; L.data.color = color
    c = L.constraints.new('TRACK_TO'); c.target = AIM; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'
area('key', (-120, -160, 140), 80, 6000, (1.0, 0.85, 0.68)); area('fill', (160, -150, -40), 120, 500, (0.9, 0.93, 1.0))
cd = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cd); scene.collection.objects.link(cam); scene.camera = cam
cd.lens = 120; cd.sensor_width = 36; cam.location = (0, -400, 16); cam.rotation_euler = (Vector((0, 0, 9)) - cam.location).to_track_quat('-Z', 'Z').to_euler()
scene.render.engine = 'CYCLES'; scene.cycles.samples = SAMPLES; scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = RES
scene.view_settings.view_transform = 'AgX'; scene.view_settings.look = 'AgX - Medium High Contrast'
scene.render.filepath = os.path.abspath(OUT); bpy.ops.render.render(write_still=True); print('WROTE', scene.render.filepath)
