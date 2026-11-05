# Lockwright — photoreal look-dev: cutaway of an invented pin-tumbler cylinder in a door.
# Units: 1 Blender unit = 1 mm. Run:
#   blender -b -P art/blender/cutaway.py -- --out art/renders/cutaway.png --res 824x1100 --samples 96
# Generic, unbranded mechanism with game-tuned proportions. Not a reproduction of any real product.
import bpy, bmesh, math, sys, os, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lw_common import *
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
def arg(name, default):
    return argv[argv.index(name) + 1] if name in argv else default
OUT = arg('--out', '//cutaway.png'); RES = [int(v) for v in arg('--res', '824x1100').split('x')]
SAMPLES = int(arg('--samples', '96')); SHOT = arg('--shot', 'section'); GLB = arg('--glb', '')
# shots: section (default), loupe, microscope (optical views of the cut), borescope (camera inside the keyway of the
# uncut cylinder: the section cut is skipped so the keyway is a closed, dark channel lit only by the probe's LED ring)
CUT = SHOT != 'borescope'
def section_cut(o, cutter):
    if CUT: boolean(o, cutter)
    else: bpy.data.objects.remove(cutter, do_unlink=True)

# ---------------------------------------------------------------- geometry (cut plane y = 0, keep y >= 0)
PINS_X = [5.0, 9.0, 13.0, 17.0, 21.0]
R_HOUSE, R_PLUG, TOWER_W, TOWER_TOP, LEN = 8.5, 6.4, 10.0, 24.0, 30.0
SHEAR = R_PLUG  # top of plug at z = 6.4
CHAMBER_R = 1.55; KEYWAY = (-5.2, 2.6)  # z range of keyway slot

# housing: round body + tower with rounded top
house = cyl('housing', R_HOUSE, LEN, (LEN / 2, 0, 0), axis='X', verts=96)
tower = box('tower', 0, LEN, -TOWER_W / 2, TOWER_W / 2, 0, TOWER_TOP - TOWER_W / 2)
boolean(house, tower, 'UNION')
cap = cyl('towercap', TOWER_W / 2, LEN, (LEN / 2, 0, TOWER_TOP - TOWER_W / 2), axis='X', verts=64)
boolean(house, cap, 'UNION')
boolean(house, cyl('bore', R_PLUG + 0.2, LEN + 2, (LEN / 2, 0, 0), axis='X', verts=128))  # 0.12 mm clearance = visible shear gap
for x in PINS_X:
    boolean(house, cyl('ch', CHAMBER_R, TOWER_TOP, (x, 0, SHEAR + (TOWER_TOP - 1.2 - SHEAR) / 2 - 0.4), verts=48))
section_cut(house, box('cut', -1, LEN + 1, -20, 0, -20, 40))  # section cut
link(house, M['nickel']); bevel(house, 0.1)

# plug with keyway and chambers
plug = cyl('plug', R_PLUG, LEN + 1.5, (LEN / 2 - 0.75, 0, 0), axis='X', verts=128)
boolean(plug, box('keyway', -2, LEN - 1.5, -1.2, 1.2, KEYWAY[0], KEYWAY[1]))
boolean(plug, box('ward', -2, LEN - 1.5, -2.0, 2.0, -1.4, 0.2))  # profile ward widens the slot
for x in PINS_X:
    boolean(plug, cyl('pc', CHAMBER_R, 6, (x, 0, KEYWAY[1] + 1.5)))
section_cut(plug, box('cut', -3, LEN + 2, -20, 0, -20, 20))
link(plug, M['brass']); bevel(plug, 0.1)
# front face lip of the plug (rounded collar)
collar = cyl('collar', R_HOUSE + 0.6, 1.6, (-0.8, 0, 0), axis='X', verts=128)
boolean(collar, box('kw2', -3, 1, -1.2, 1.2, KEYWAY[0], KEYWAY[1]))
boolean(collar, cyl('inner', R_PLUG, 4, (-0.8, 0, 0), axis='X', verts=128))
section_cut(collar, box('cut', -3, 2, -20, 0, -20, 20)); link(collar, M['nickel']); bevel(collar, 0.12)

# bore plugs (caps) closing the chambers at the top of the tower
for x in PINS_X:
    c = cyl('cap', CHAMBER_R + 0.02, 1.2, (x, 0, TOWER_TOP - 1.6 - 0.4 + 0.6)); section_cut(c, box('cut', x - 3, x + 3, -5, 0, 0, 40)); link(c, M['brass']); bevel(c, 0.08)

# ---------------------------------------------------------------- pin stacks (game states a..e)
TOP = TOWER_TOP - 2.0 - 0.4  # underside of caps
KP_FLOOR = KEYWAY[1] - 1.4    # resting key-pin tip height inside the keyway
# a: SET — driver resting on plug top (shear), key pin dropped
pin('a_key', PINS_X[0], KP_FLOOR, 4.6, tip=True, mat='brass_k')
pin('a_drv', PINS_X[0], SHEAR + 0.2, 4.0); spring('a_spr', PINS_X[0], SHEAR + 4.12, TOP, 9)
# b: FALSE SET — spool caught: waist straddles shear
pin('b_key', PINS_X[1], KP_FLOOR, 4.8, tip=True, mat='brass_k')
spool('b_drv', PINS_X[1], KP_FLOOR + 4.8, 4.4, SHEAR + 0.06); spring('b_spr', PINS_X[1], KP_FLOOR + 9.2, TOP, 9)
# c: BINDING + near shear — lifted by the pick, driver jammed (slight tilt)
cz = KP_FLOOR + 1.0
pin('c_key', PINS_X[2], cz, 4.9, tip=True, mat='brass_k')
pin('c_drv', PINS_X[2], cz + 4.9, 4.0, tilt=math.radians(-2.2)); spring('c_spr', PINS_X[2], cz + 8.9, TOP, 9)
# d: OVERSET — key pin pushed past the shear line, spring nearly solid
dz = KP_FLOOR + 3.2
pin('d_key', PINS_X[3], dz, 5.4, tip=True, mat='brass_k')
pin('d_drv', PINS_X[3], dz + 5.4, 4.0); spring('d_spr', PINS_X[3], dz + 9.4, TOP, 9, wire=0.24)
# e: FREE — at rest, driver across the shear line
pin('e_key', PINS_X[4], KP_FLOOR, 4.2, tip=True, mat='brass_k')
pin('e_drv', PINS_X[4], KP_FLOOR + 4.2, 4.0); spring('e_spr', PINS_X[4], KP_FLOOR + 8.2, TOP, 9)

# ---------------------------------------------------------------- tools: tension wrench + hook pick (spring steel, flat)
# hook pick: shaft along keyway, slight bend under stress, hook under pin c
hook = [(-46, -3.6), (-25, -3.55), (-5, -3.45), (5, -3.3), (9.5, -3.05), (11.6, -2.5), (12.5, -1.4), (12.85, cz - 0.55)]
flat_tool('pick', hook, 1.1, 0.55, 0.6)
# pick handle (outside the door, off to the left)
h = box('pick_handle', -60, -44, 0.1, 2.2, -4.6, -2.2); link(h, M['handle']); bevel(h, 0.5)
# tension wrench: short leg in the bottom of the keyway, long leg down along the door face
wr = [(4.0, -4.6), (-3.2, -4.6), (-4.3, -4.9), (-4.9, -5.8), (-5.0, -7.2), (-5.0, -40)]
flat_tool('wrench', wr, 1.5, 0.75, 0.4, tip='flat')

# ---------------------------------------------------------------- door + escutcheon (section)
door = box('door', 0.0, 44, 0, 24, -60, 60)
prof = cyl('hole', R_HOUSE + 0.3, 60, (22, 0, 0), axis='X', verts=96)
t2 = box('t2', -5, 50, -TOWER_W / 2 - 0.3, TOWER_W / 2 + 0.3, 0, TOWER_TOP - TOWER_W / 2)
boolean(prof, t2, 'UNION'); boolean(prof, cyl('t3', TOWER_W / 2 + 0.3, 60, (22, 0, TOWER_TOP - TOWER_W / 2), axis='X'), 'UNION')
boolean(door, prof); link(door, M['wood']); bevel(door, 0.3)
esc = box('escutcheon', -3.2, 0.0, 0, 14, -34, 44)
hole = cyl('eh', R_HOUSE + 0.9, 8, (-1.6, 0, 0), axis='X', verts=96); boolean(esc, hole)
link(esc, M['iron']); bevel(esc, 0.4)
# a dark interior behind the cut, so open space reads as depth, not white
back = box('back', -80, 80, 30, 31, -80, 80); link(back, M['recess'])

# ---------------------------------------------------------------- light + camera
w = scene.world = bpy.data.worlds.new('w'); w.use_nodes = True
env = w.node_tree.nodes.new('ShaderNodeTexEnvironment')
env.image = bpy.data.images.load(os.path.join(bpy.utils.resource_path('LOCAL'), 'datafiles', 'studiolights', 'world', 'interior.exr'))
bg = w.node_tree.nodes['Background']; bg.inputs['Strength'].default_value = 0.25
w.node_tree.links.new(env.outputs['Color'], bg.inputs['Color'])

AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (13, 0, 7)
def area(name, loc, rot, size, energy, color):
    bpy.ops.object.light_add(type='AREA', location=loc); L = bpy.context.object; L.name = name
    L.data.size = size; L.data.energy = energy; L.data.color = color
    c = L.constraints.new('TRACK_TO'); c.target = AIM; c.track_axis = 'TRACK_NEGATIVE_Z'; c.up_axis = 'UP_Y'; return L
# warm stair-light key from upper left-front, cool fill from right, low rim from below-back
area('key', (-70, -45, 120), None, 50, 1100, (1.0, 0.84, 0.66))
area('fill', (110, -90, 0), None, 90, 120, (0.95, 0.95, 1.0))
area('rim', (20, -30, -90), None, 30, 120, (1.0, 0.95, 0.9))
# product-shot sheen: big softbox at the mirror direction of the camera about the cut plane
sheen = Vector((math.sin(math.radians(24)), -math.cos(math.radians(24)), -math.sin(math.radians(11)))).normalized() * 260
area('sheen', tuple(Vector((14.5, 0, 8)) + sheen + Vector((0, 0, 40))), None, 160, 260, (1.0, 0.97, 0.92))

cam_d = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cam_d); scene.collection.objects.link(cam); scene.camera = cam
cam_d.lens = 180; cam_d.sensor_fit = 'HORIZONTAL'; cam_d.sensor_width = 36
yaw = math.radians(-22); pitch = math.radians(10); dist = 158
target = Vector((13.5, 0, 9.0))
cam.location = target + Vector((math.sin(yaw) * dist, -math.cos(yaw) * dist * math.cos(pitch), math.sin(pitch) * dist))
cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
cam_d.dof.use_dof = False  # everything in focus: the player must read every pin
if SHOT == 'loupe':  # macro through the loupe: shear line at pin c
    tx, tz = [float(v) for v in arg('--target', '%f,%f' % (PINS_X[2], SHEAR)).split(',')]
    target = Vector((tx, 0.0, tz)); dist = float(arg('--dist', '42')); cam_d.lens = 180
    cam.location = target + Vector((math.sin(yaw) * dist, -math.cos(yaw) * dist * math.cos(pitch), math.sin(pitch) * dist))
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler()
    cam_d.dof.use_dof = True; cam_d.dof.focus_distance = dist; cam_d.dof.aperture_fstop = 22; AIM.location = target


def optics_post(dispersion=0.0, distortion=0.0, vignette=0.0, soft=0.25):
    """Compositor stand-in for real optics: lateral colour fringing that grows toward the edge (Lens Distortion
    dispersion), optional barrel distortion, and a soft optical vignette. No glare, no bloom."""
    scene.use_nodes = True; nt = scene.node_tree; nt.nodes.clear()
    rl = nt.nodes.new('CompositorNodeRLayers'); comp = nt.nodes.new('CompositorNodeComposite'); img = rl.outputs['Image']
    if dispersion or distortion:
        ld = nt.nodes.new('CompositorNodeLensdist'); ld.use_fit = distortion > 0
        ld.inputs['Distortion'].default_value = distortion; ld.inputs['Dispersion'].default_value = dispersion
        nt.links.new(img, ld.inputs['Image']); img = ld.outputs['Image']
    if vignette:
        em = nt.nodes.new('CompositorNodeEllipseMask'); em.width = em.height = 1.0 - soft * 0.6
        em.inputs['Value'].default_value = 1.0
        bl = nt.nodes.new('CompositorNodeBlur'); bl.filter_type = 'GAUSS'; bl.use_relative = True
        bl.factor_x = bl.factor_y = soft * 100; bl.size_x = bl.size_y = 1
        nt.links.new(em.outputs['Mask'], bl.inputs['Image'])
        mr = nt.nodes.new('CompositorNodeMapRange'); mr.inputs['To Min'].default_value = 1.0 - vignette
        nt.links.new(bl.outputs['Image'], mr.inputs['Value'])
        mx = nt.nodes.new('CompositorNodeMixRGB'); mx.blend_type = 'MULTIPLY'; mx.inputs['Fac'].default_value = 1.0
        nt.links.new(img, mx.inputs[1]); nt.links.new(mr.outputs['Value'], mx.inputs[2]); img = mx.outputs['Image']
    nt.links.new(img, comp.inputs['Image'])

def emitter(name, obj, strength, color=(1.0, 0.96, 0.9)):
    m = bpy.data.materials.new(name); m.use_nodes = True; nt = m.node_tree; nt.nodes.clear()
    e = nt.nodes.new('ShaderNodeEmission'); e.inputs['Strength'].default_value = strength; e.inputs['Color'].default_value = (*color, 1)
    o = nt.nodes.new('ShaderNodeOutputMaterial'); nt.links.new(e.outputs[0], o.inputs['Surface'])
    obj.data.materials.clear(); obj.data.materials.append(m); obj.visible_camera = False; return obj

if SHOT == 'microscope':  # bench microscope: ~2x the loupe's magnification, narrow field, LED ring illuminator
    # default target sits between pin a (set) and pin b (spool caught in false set): the two states the loupe
    # cannot tell apart at a glance, side by side at the shear line
    tx, tz = [float(v) for v in arg('--target', '%f,%f' % ((PINS_X[0] + PINS_X[1]) / 2, SHEAR + 0.2)).split(',')]
    target = Vector((tx, 0.0, tz)); dist = float(arg('--dist', '24')); cam_d.lens = 180
    myaw = math.radians(float(arg('--yaw', '-14'))); mpitch = math.radians(float(arg('--pitch', '6')))
    cam.location = target + Vector((math.sin(myaw) * dist, -math.cos(myaw) * dist * math.cos(mpitch), math.sin(mpitch) * dist))
    cam.rotation_euler = (target - cam.location).to_track_quat('-Z', 'Y').to_euler(); AIM.location = target
    cam_d.dof.use_dof = True; cam_d.dof.focus_distance = dist; cam_d.dof.aperture_fstop = float(arg('--fstop', '16'))
    # LED ring around the objective: a diffuse annulus coaxial with the view, out of frame (behind the camera)
    ax = (target - cam.location).normalized(); rd = float(arg('--ring_d', '70')); rr = float(arg('--ring_r', '28'))
    bpy.ops.mesh.primitive_torus_add(major_radius=rr, minor_radius=2.0, major_segments=96, minor_segments=12)
    ring = bpy.context.object; ring.name = 'led_ring'
    ring.location = target - ax * rd; ring.rotation_euler = ax.to_track_quat('Z', 'Y').to_euler()
    emitter('ring_led', ring, float(arg('--ring', '60')), (1.0, 0.97, 0.92))
    for L in ('key', 'fill', 'rim', 'sheen'): bpy.data.objects[L].data.energy *= float(arg('--amb', '1.0'))
    optics_post(dispersion=float(arg('--disp', '0.012')), vignette=float(arg('--vig', '0.55')), soft=0.3)

if SHOT == 'borescope':  # flexible probe in the keyway, looking along the plug at the key pins from below
    for o in list(bpy.data.objects):  # pin stacks were offset behind the cut plane; centre them in their chambers
        if o.name[:2] in ('a_', 'b_', 'c_', 'd_', 'e_'):
            o.matrix_world = Matrix.Translation((0, -1.5, 0)) @ o.matrix_world
    bx, by, bz = [float(v) for v in arg('--probe', '0.6,-0.4,-0.5').split(',')]
    tx, ty, tz = [float(v) for v in arg('--target', '12,0,2.6').split(',')]
    cam.location = Vector((bx, by, bz)); cam.rotation_euler = (Vector((tx, ty, tz)) - cam.location).to_track_quat('-Z', 'Y').to_euler()
    cam_d.lens = float(arg('--lens', '16')); cam_d.clip_start = 0.05; cam_d.dof.use_dof = False
    # the room is shut out (only a little leaks in through the keyway mouth); the LED ring does the work
    scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = float(arg('--world', '0.02'))
    for L in ('key', 'fill', 'rim', 'sheen'): bpy.data.objects[L].hide_render = True
    fwd = (Vector((tx, ty, tz)) - cam.location).normalized()
    q = cam.rotation_euler.to_quaternion(); right = q @ Vector((1, 0, 0)); upv = q @ Vector((0, 1, 0))
    for k in range(6):  # six warm-white LEDs on a 0.6 mm ring around the lens
        a = 2 * math.pi * (k + 0.5) / 6
        p = cam.location + (right * math.cos(a) + upv * math.sin(a)) * 0.6 + fwd * 0.05
        bpy.ops.object.light_add(type='POINT', location=p); L = bpy.context.object; L.name = 'led%d' % k
        L.data.energy = float(arg('--led', '40')); L.data.shadow_soft_size = 0.12; L.data.color = (1.0, 0.97, 0.93)
    optics_post(dispersion=0.006, distortion=float(arg('--barrel', '0.06')), vignette=float(arg('--vig', '0.45')), soft=0.35)

# ---------------------------------------------------------------- render
scene.render.engine = 'CYCLES'; scene.cycles.device = 'CPU'; scene.cycles.samples = SAMPLES
scene.cycles.use_denoising = True; scene.cycles.max_bounces = 8
scene.cycles.denoising_input_passes = 'RGB_ALBEDO_NORMAL'; scene.cycles.denoising_prefilter = 'ACCURATE'
scene.cycles.adaptive_threshold = 0.006; scene.render.film_transparent = False
scene.view_settings.exposure = 0.15
scene.render.resolution_x, scene.render.resolution_y = RES; scene.render.film_transparent = False
scene.view_settings.view_transform = 'AgX'; scene.view_settings.look = 'AgX - Medium High Contrast'
scene.render.filepath = os.path.abspath(OUT)
if GLB:
    bpy.ops.export_scene.gltf(filepath=os.path.abspath(GLB), export_apply=True)
bpy.ops.render.render(write_still=True)
print('WROTE', scene.render.filepath)
