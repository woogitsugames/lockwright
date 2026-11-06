# Lockwright — plan-B tool layers for D-59 families that reuse the pin cut-away (LOCKS.md §2.20, §2.25).
# Renders one RGBA layer per tool, side view (orthographic, the picture plane of the pin cut-away), lit
# like art/blender/cutaway.py (warm key from the top left, cool fill), photo materials:
#   magnet_probe.png   magnetic: a steel rod with a dark magnet capsule at the tip (never touches a pin)
#   dimple_flag.png    dimple: a flat bar with the flag paddle bent up at the tip
# layers.json: per tool the tip point in pixels and pixels per mm, so the game scales the layer to the
# cut-away (mm_to_screen) and puts the tip where lockcore's pick is.
# Run (CPU now, final on a GPU later):
#   blender -b -P art/blender/plates/tool_layers.py -- \
#       --out-dir game/assets/photoreal_families/tools --ppmm 24 --spp 32 --device CPU
import bpy, json, math, os, sys
import numpy as np

THIS_DIR = os.path.dirname(os.path.abspath(__file__))
BLENDER_DIR = os.path.abspath(os.path.join(THIS_DIR, '..'))
ROOT_DIR = os.path.abspath(os.path.join(BLENDER_DIR, '..', '..'))
sys.path.insert(0, BLENDER_DIR)
from lw_common import *  # noqa: F401,F403
from mathutils import Matrix

arg = cli()
OUT_DIR = os.path.abspath(arg('--out-dir', os.path.join(ROOT_DIR, 'game', 'assets', 'photoreal_families', 'tools')))
PPMM = float(arg('--ppmm', arg('--res', '24')))   # pixels per mm (final: 48)
SPP = int(arg('--spp', '32'))
DEVICE = arg('--device', 'CPU').upper()
TOOLS = arg('--tools', 'magnet_probe,dimple_flag').split(',')
os.makedirs(OUT_DIR, exist_ok=True)

M = {
    'steel': photo_mat('ph_tool_steel', 'spring_steel_polished', scale=20, rot=0, tint=(0.86, 0.86, 0.87), rough_add=0.10, bump=0.1, wear=0.3),
    'magnet': photo_mat('ph_magnet', 'nickel_satin', scale=10, rot=90, base=(0.10, 0.10, 0.11), base_mix=0.75, rough_add=0.12, wear=0.6, grime=0.4),
    'grip': photo_mat('ph_grip', 'leather_chocolate', scale=14, rot=0, metallic=0.0, rough_add=0.05, bump=0.3),
}

objs = {}
# magnet probe: rod along X ending at x = 0, capsule at the tip, tip top at z = 0
rod = cyl('rod', 0.55, 30.0, (-16.5, 0, -0.9), axis='X', verts=48); put(rod, M['steel'], 0.05, 2)
cap = lathe_x('capsule', [(-3.4, 0.001), (-3.4, 0.9), (-3.0, 0.95), (-0.3, 0.95), (0.0, 0.6), (0.05, 0.001)], seg=64, z=-0.95)
put(cap, M['magnet'])
band = cyl('band', 1.0, 0.4, (-3.5, 0, -0.95), axis='X', verts=48); put(band, M['steel'], 0.05, 2)
objs['magnet_probe'] = [rod, cap, band]
# dimple flag: flat bar 0.5 mm thick, 1.6 mm high, paddle bent up at the tip (tip top at z = 0, x = 0)
bar = box('fbar', -32.0, -0.7, -0.4, 0.4, -2.4, -1.0)
pad = box('fpad', -1.4, 0.0, -0.4, 0.4, -2.4, 0.0)
boolean(pad, bar, 'UNION'); bar = pad; put(bar, M['steel'], 0.10, 2)
objs['dimple_flag'] = [bar]

world_hdri(0.08, sat=0.4)
AIM = bpy.data.objects.new('aim', None); scene.collection.objects.link(AIM); AIM.location = (-8, 0, -1)
area_light('key', (-60, -120, 90), AIM, 40, 60000, (1.0, 0.84, 0.66))
area_light('fill', (80, -120, -30), AIM, 60, 4000, (0.9, 0.94, 1.0))
W_MM, H_MM = 36.0, 6.0
cd = bpy.data.cameras.new('ocam'); cam = bpy.data.objects.new('ocam', cd); scene.collection.objects.link(cam); scene.camera = cam
cd.type = 'ORTHO'; cd.ortho_scale = W_MM; cd.sensor_fit = 'HORIZONTAL'
cam.location = (-W_MM / 2 + 1.0, -100, -1.5); cam.rotation_euler = (math.pi / 2, 0, 0)
RES = [int(W_MM * PPMM), int(H_MM * PPMM)]
render_setup(os.path.join(OUT_DIR, '_tmp.png'), RES, SPP, exposure=float(arg('--exp', '2.2')))
if DEVICE == 'GPU':
    try:
        __import__('plate_common').enable_gpu_cycles()
    except Exception as e:  # noqa: BLE001
        print('GPU setup failed, CPU:', e)
scene.render.film_transparent = True
scene.render.image_settings.color_mode = 'RGBA'

meta = {'ppmm': PPMM, 'tools': {}}
mp = os.path.join(OUT_DIR, 'layers.json')
if os.path.exists(mp):
    meta['tools'] = json.load(open(mp)).get('tools', {})
for name in TOOLS:
    for k, lst in objs.items():
        for o in lst:
            o.hide_render = k != name
    tmp = os.path.join(OUT_DIR, '_tmp_%s.png' % name)
    scene.render.filepath = tmp
    bpy.ops.render.render(write_still=True)
    img = bpy.data.images.load(tmp)
    w, h = img.size
    a = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(a); a = a.reshape(h, w, 4)[::-1]
    ys, xs = np.nonzero(a[..., 3] > 0.004)
    x0, x1, y0, y1 = max(xs.min() - 2, 0), min(xs.max() + 3, w), max(ys.min() - 2, 0), min(ys.max() + 3, h)
    c = np.ascontiguousarray(a[y0:y1, x0:x1][::-1])
    out = bpy.data.images.new(name, x1 - x0, y1 - y0, alpha=True); out.pixels.foreach_set(c.ravel())
    out.filepath_raw = os.path.join(OUT_DIR, name + '.png'); out.file_format = 'PNG'; out.save()
    # tip (x = 0, z = 0) in the crop
    cx = (0.0 - (cam.location.x - W_MM / 2)) * PPMM - x0
    cy = (cam.location.z + H_MM / 2 - 0.0) * PPMM - y0
    meta['tools'][name] = {'tip_px': [float(cx), float(cy)], 'size': [int(x1 - x0), int(y1 - y0)]}
    os.remove(tmp)
    print('WROTE', name, meta['tools'][name], flush=True)
json.dump(meta, open(mp, 'w'), indent=1)
print('DONE')
