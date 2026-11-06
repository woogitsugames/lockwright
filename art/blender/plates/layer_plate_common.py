# Lockwright — shared helpers for plan-B layer plates (D-59 families): a front camera on the picture
# plane (perspective, long lens), RGBA layers rendered one moving part at a time (no shadows of other
# moving parts baked in), crops, and layers.json with the pixel geometry the game needs.
# Used by egyptian_plate.py, time_lock_plate.py, axial_slider_plate.py. CLI of every plate script:
#   --out-dir DIR --res WxH --spp N --device CPU|GPU [--passes plate,front,<layer>,...] [--exp E]
import json, math, os
import bpy
import numpy as np
from mathutils import Vector


class LayerRig:
    def __init__(self, scene, res, spp, device, out_dir, center=(0.0, 0.0), width_mm=80.0, lens=150.0):
        self.scene, self.res, self.spp, self.device, self.out_dir = scene, res, spp, device, out_dir
        self.center, self.lens = center, lens
        self.dist = width_mm * lens / 36.0
        self.objs = {'back': [], 'front': [], 'moving': {}}
        self.meta = {'res': list(res), 'spp': spp, 'device': device, 'layers': {}}
        os.makedirs(out_dir, exist_ok=True)

    def camera(self):
        cd = bpy.data.cameras.new('cam'); cam = bpy.data.objects.new('cam', cd); self.scene.collection.objects.link(cam)
        self.scene.camera = cam
        cd.lens = self.lens; cd.sensor_fit = 'HORIZONTAL'; cd.sensor_width = 36.0; cd.clip_start = 1; cd.clip_end = 5000
        cam.location = (self.center[0], -self.dist, self.center[1]); cam.rotation_euler = (math.pi / 2, 0, 0)
        return cam

    def ppm(self, depth=0.0):
        """Pixels per mm at depth y (mm, + = away from the camera)."""
        return self.lens / 36.0 * self.res[0] / (self.dist + depth)

    def px(self, x, z, depth=0.0):
        s = self.ppm(depth)
        return [self.res[0] / 2 + (x - self.center[0]) * s, self.res[1] / 2 - (z - self.center[1]) * s]

    def vec(self, dx, dz, depth=0.0):
        """A displacement in mm (picture plane) as a pixel vector."""
        s = self.ppm(depth)
        return [dx * s, -dz * s]

    def gpu(self):
        if self.device == 'GPU':
            try:
                __import__('plate_common').enable_gpu_cycles()
            except Exception as e:  # noqa: BLE001
                print('GPU setup failed, CPU:', e)
        self.scene.render.image_settings.color_mode = 'RGBA'
        self.scene.render.image_settings.color_depth = '8'

    def _all_moving(self):
        return [o for lst in self.objs['moving'].values() for o in lst]

    @staticmethod
    def _vis(o, cam_on, shadow_on=True, hidden=False):
        o.hide_render = hidden
        o.visible_camera = cam_on
        o.visible_shadow = shadow_on

    def crop_save(self, tmp, name, rgba=True):
        img = bpy.data.images.load(tmp, check_existing=False)
        w, h = img.size
        a = np.empty(w * h * 4, dtype=np.float32); img.pixels.foreach_get(a); a = a.reshape(h, w, 4)[::-1]
        if rgba:
            ys, xs = np.nonzero(a[..., 3] > 0.004)
            if len(xs) == 0:
                print('EMPTY layer', name); bpy.data.images.remove(img); return
            x0, x1, y0, y1 = max(xs.min() - 2, 0), min(xs.max() + 3, w), max(ys.min() - 2, 0), min(ys.max() + 3, h)
        else:
            x0, x1, y0, y1 = 0, w, 0, h
        c = np.ascontiguousarray(a[y0:y1, x0:x1][::-1])
        out = bpy.data.images.new(name, x1 - x0, y1 - y0, alpha=True)
        out.pixels.foreach_set(c.ravel())
        out.filepath_raw = os.path.join(self.out_dir, name + '.png'); out.file_format = 'PNG'; out.save()
        self.meta['layers'][name] = {'offset': [int(x0), int(y0)], 'size': [int(x1 - x0), int(y1 - y0)]}
        bpy.data.images.remove(out); bpy.data.images.remove(img)
        print('WROTE', name, self.meta['layers'][name], flush=True)

    def render_pass(self, name, show, back_cam=False, front_cam=False, transparent=True):
        for o in self.objs['back']:
            self._vis(o, back_cam, shadow_on=not transparent)
        for o in self.objs['front']:
            self._vis(o, front_cam, shadow_on=(not transparent) or front_cam)
        for o in self._all_moving():
            self._vis(o, False, hidden=True)
        for o in show:
            self._vis(o, True, hidden=False)
        self.scene.render.film_transparent = transparent
        tmp = os.path.join(self.out_dir, '_tmp_%s.png' % name)
        self.scene.render.filepath = tmp
        bpy.ops.render.render(write_still=True)
        self.crop_save(tmp, name, rgba=transparent)
        os.remove(tmp)

    def run(self, passes):
        if 'ref' in passes:
            for o in self.objs['back'] + self.objs['front'] + self._all_moving():
                self._vis(o, True)
            self.scene.render.film_transparent = False
            self.scene.render.filepath = os.path.join(self.out_dir, 'ref.png')
            bpy.ops.render.render(write_still=True)
        if 'plate' in passes:
            self.render_pass('plate', [], back_cam=True, transparent=False)
        if 'front' in passes and self.objs['front']:
            self.render_pass('front', [], front_cam=True)
        for name, lst in self.objs['moving'].items():
            if 'moving' in passes or name in passes:
                self.render_pass(name, lst)
        mp = os.path.join(self.out_dir, 'layers.json')
        if os.path.exists(mp):
            old = json.load(open(mp)).get('layers', {})
            old.update(self.meta['layers']); self.meta['layers'] = old
        json.dump(self.meta, open(mp, 'w'), indent=1)
        print('DONE', self.out_dir)
