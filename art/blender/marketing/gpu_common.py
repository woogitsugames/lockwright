# Shared GPU / Cycles setup and animation helpers for Lockwright marketing renders (GEM1).
import bpy
import math
import os
import sys
import time
import json

ART_BLENDER_DIR = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
if ART_BLENDER_DIR not in sys.path:
    sys.path.insert(0, ART_BLENDER_DIR)


def setup_gpu_cycles(scene, samples=128, denoiser='OPTIX', use_dof=False, persistent=True, color_depth='16'):
    """Configure Cycles to use the fastest available GPU (OptiX -> CUDA -> HIP -> METAL -> CPU)
    with Albedo+Normal denoising and AgX color management (no bloom/glare)."""
    scene.render.engine = 'CYCLES'
    prefs = bpy.context.preferences.addons['cycles'].preferences
    selected_backend = 'CPU'
    gpu_name = 'CPU'

    for backend in ('OPTIX', 'CUDA', 'HIP', 'METAL', 'ONEAPI'):
        try:
            prefs.compute_device_type = backend
            prefs.refresh_devices()
            devs = prefs.get_devices_for_type(backend)
            gpu_devs = [d for d in devs if d.type == backend]
            if gpu_devs:
                for d in prefs.devices:
                    d.use = (d.type == backend)
                selected_backend = backend
                gpu_name = gpu_devs[0].name
                break
        except Exception:
            continue

    scene.cycles.device = 'GPU' if selected_backend != 'CPU' else 'CPU'
    scene.cycles.samples = samples
    scene.cycles.use_adaptive_sampling = True
    if str(color_depth) == '8':
        scene.cycles.adaptive_threshold = 0.03
        scene.cycles.max_bounces = 4
        scene.cycles.diffuse_bounces = 2
        scene.cycles.glossy_bounces = 3
        scene.cycles.transmission_bounces = 2
        scene.cycles.transparent_max_bounces = 4
        scene.cycles.sample_clamp_indirect = 8.0
    else:
        scene.cycles.adaptive_threshold = 0.008
    scene.cycles.use_auto_tile = False
    scene.cycles.use_denoising = True

    # Use requested denoiser if supported, fallback to OPENIMAGEDENOISE
    if denoiser.upper() == 'OPTIX' and selected_backend == 'OPTIX':
        scene.cycles.denoiser = 'OPTIX'
    else:
        scene.cycles.denoiser = 'OPENIMAGEDENOISE'
        scene.cycles.denoising_prefilter = 'ACCURATE'
    scene.cycles.denoising_input_passes = 'RGB_ALBEDO_NORMAL'

    try:
        scene.render.compositor_device = 'GPU'
    except Exception:
        pass

    scene.render.use_persistent_data = persistent
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB'
    scene.render.image_settings.color_depth = str(color_depth)
    scene.render.image_settings.compression = 15 if str(color_depth) == '8' else 90

    if scene.camera and scene.camera.data and not use_dof:
        scene.camera.data.dof.use_dof = False

    return selected_backend, gpu_name


def ease_out_cubic(t):
    t = max(0.0, min(1.0, float(t)))
    return 1.0 - (1.0 - t) ** 3


def ease_in_out_cubic(t):
    t = max(0.0, min(1.0, float(t)))
    if t < 0.5:
        return 4.0 * t * t * t
    return 1.0 - ((-2.0 * t + 2.0) ** 3) / 2.0


def clamp01(t):
    return max(0.0, min(1.0, float(t)))


def remap(val, a, b):
    if abs(b - a) < 1e-9:
        return 0.0
    return clamp01((val - a) / (b - a))


def ensure_under_10mb(filepath):
    """If a PNG file exceeds 9.8 MB (e.g. 16-bit 4K still for git), re-save it as 8-bit PNG via Blender image API."""
    if not os.path.exists(filepath):
        return
    size_mb = os.path.getsize(filepath) / (1024 * 1024)
    if size_mb <= 9.8:
        return
    img = bpy.data.images.load(filepath)
    scene = bpy.context.scene
    prev_depth = scene.render.image_settings.color_depth
    prev_comp = scene.render.image_settings.compression
    scene.render.image_settings.color_depth = '8'
    scene.render.image_settings.compression = 100
    img.save_render(filepath, scene=scene)
    bpy.data.images.remove(img)
    scene.render.image_settings.color_depth = prev_depth
    scene.render.image_settings.compression = prev_comp
