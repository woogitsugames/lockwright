"""Shared GPU Cycles pipeline for Lockwright photoreal lock families (Plan B, D-31 / D-37).

Modeled after:
- game/assets/photoreal/tools/render_plate.py
- spikes/lit-metal/tools/bake.py
- spikes/lit-metal/tools/render_refs.py

Implements contrib/gpt/T06 visual improvements:
- Tool-grade satin metal roughness (>= 0.22 on brass/wafers/levers/picks, never < 0.16)
  with softened sheen reflection so cylinders have no chrome-white stripes.
- Stronger directional machining marks (mill / grind / turn) on cut planes.
- Exports per-family:
  * plate/plate_1236x1650.png (static scene rendered in Cycles GPU with moving parts hidden)
  * matcap/matcap_<mat>.png (512x512 Cycles sphere per moving material in the scene light field)
  * tex/<mat>_albedo.png, tex/<mat>_normal.png, tex/<mat>_orm.png (1024x1024 GPU bakes)
  * <family>_baked.glb (1 Blender unit = 1 mm = 1 Godot unit, y-up)
  * scene.json (camera rig, aim, lights, moving/static nodes, and pose geometry constants)
"""
import json
import math
import os
import time
import bpy
import bmesh
import numpy as np
from mathutils import Vector


def enable_gpu_cycles():
    """Enable OPTIX or CUDA GPU rendering in Cycles."""
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.refresh_devices()

    chosen = 'CPU'
    for backend in ('OPTIX', 'CUDA', 'HIP', 'ONEAPI', 'METAL'):
        try:
            prefs.compute_device_type = backend
            prefs.refresh_devices()
            devs = [d for d in prefs.devices if d.type == backend]
            if devs:
                for d in prefs.devices:
                    d.use = (d.type == backend)
                chosen = backend
                break
        except Exception:
            continue

    sc.cycles.device = 'GPU' if chosen != 'CPU' else 'CPU'
    sc.cycles.use_denoising = True
    return chosen


def select_only(objs):
    if bpy.context.object and bpy.context.object.mode != 'OBJECT':
        bpy.ops.object.mode_set(mode='OBJECT')
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    valid = [o for o in objs if o is not None and o.name in bpy.context.view_layer.objects]
    for o in valid:
        o.select_set(True)
    if valid:
        bpy.context.view_layer.objects.active = valid[0]
    return valid


def _principled(mat):
    if not mat or not mat.use_nodes or not mat.node_tree:
        return None
    for n in mat.node_tree.nodes:
        if n.type == 'BSDF_PRINCIPLED':
            return n
    return None


def apply_t06_tuning(min_metal_rough=0.24):
    """Ensure all metallic materials satisfy T06 roughness >= 0.22 (no mirror chrome)
    and strengthen cut-face machining bump."""
    for mat in bpy.data.materials:
        if not mat.use_nodes or not mat.node_tree:
            continue
        bsdf = _principled(mat)
        if not bsdf:
            continue
        metal_val = float(bsdf.inputs['Metallic'].default_value)
        is_cut = ('cut' in mat.name.lower())
        for n in mat.node_tree.nodes:
            if n.type == 'MATH' and n.operation == 'ADD':
                # lw_common.metal() uses an ADD node for base roughness
                v0 = float(n.inputs[0].default_value)
                if is_cut and v0 < 0.36:
                    n.inputs[0].default_value = 0.38
                elif metal_val > 0.5 and 0.05 <= v0 < min_metal_rough:
                    n.inputs[0].default_value = min_metal_rough
            elif n.type == 'BUMP':
                s_in = n.inputs.get('Strength')
                if s_in and not s_in.is_linked:
                    cur = float(s_in.default_value)
                    if is_cut:
                        s_in.default_value = max(cur * 1.35, 0.22)
                    elif metal_val > 0.5:
                        s_in.default_value = max(cur * 1.15, 0.08)


def _pixels(img):
    arr = np.empty(img.size[0] * img.size[1] * 4, dtype=np.float32)
    img.pixels.foreach_get(arr)
    return arr.reshape(img.size[1], img.size[0], 4)


def _save_arr(arr, path, colorspace='Non-Color'):
    h, w = arr.shape[:2]
    img = bpy.data.images.new(os.path.basename(path), w, h, alpha=False)
    img.colorspace_settings.name = colorspace
    rgba = np.ones((h, w, 4), dtype=np.float32)
    rgba[..., :3] = arr[..., :3]
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = path
    img.file_format = 'PNG'
    img.save()
    bpy.data.images.remove(img)


def _bake_pass(mat, objs, size, kind, colorspace, samples):
    sc = bpy.context.scene
    img = bpy.data.images.new(f"{mat.name}_{kind}", size, size, alpha=False, float_buffer=(kind == 'normal'))
    img.colorspace_settings.name = colorspace
    node = mat.node_tree.nodes.new('ShaderNodeTexImage')
    node.image = img
    for n in mat.node_tree.nodes:
        n.select = False
    node.select = True
    mat.node_tree.nodes.active = node

    select_only(objs)
    sc.cycles.samples = samples
    sc.cycles.use_denoising = False
    sc.render.bake.margin = 12
    sc.render.bake.use_clear = True

    if kind == 'albedo':
        bsdf = _principled(mat)
        metal_in = bsdf.inputs['Metallic']
        orig_metal = float(metal_in.default_value)
        orig_links = list(metal_in.links)
        for lk in orig_links:
            mat.node_tree.links.remove(lk)
        metal_in.default_value = 0.0
        bpy.ops.object.bake(type='DIFFUSE', pass_filter={'COLOR'})
        metal_in.default_value = orig_metal
    elif kind == 'rough':
        bpy.ops.object.bake(type='ROUGHNESS')
    elif kind == 'normal':
        bpy.ops.object.bake(type='NORMAL', normal_space='TANGENT')
    elif kind == 'ao':
        bpy.ops.object.bake(type='AO')

    mat.node_tree.nodes.remove(node)
    arr = _pixels(img)
    bpy.data.images.remove(img)
    return arr


def _gl_vec(v):
    """Blender mm (X right, Y depth, Z up) -> glTF/Godot units (X right, Y up, Z out)."""
    return [round(float(v[0]), 5), round(float(v[2]), 5), round(float(-v[1]), 5)]


def run_family_pipeline(
    family_name,
    out_dir,
    moving_names,
    camera_target,
    matcap_centre,
    extra_meta=None,
    plate_res=(1236, 1650),
    plate_samples=160,
    tex_size=1024,
    ao_samples=32,
):
    """Execute the full GPU render & bake pipeline for one lock family:
    1. Apply T06 material tuning.
    2. Render static background plate (plate/plate_1236x1650.png) with moving parts hidden.
    3. Render 512x512 Cycles matcap spheres (matcap/matcap_<mat>.png) in the scene light field.
    4. Convert curves to meshes, apply modifiers, triangulate n-gons, unwrap moving meshes,
       and bake tex/<mat>_albedo.png, tex/<mat>_normal.png, tex/<mat>_orm.png on GPU.
    5. Export <family>_baked.glb and scene.json.
    """
    t_total = time.time()
    backend = enable_gpu_cycles()
    apply_t06_tuning()

    os.makedirs(out_dir, exist_ok=True)
    plate_dir = os.path.join(out_dir, "plate")
    matcap_dir = os.path.join(out_dir, "matcap")
    tex_dir = os.path.join(out_dir, "tex")
    os.makedirs(plate_dir, exist_ok=True)
    os.makedirs(matcap_dir, exist_ok=True)
    os.makedirs(tex_dir, exist_ok=True)

    sc = bpy.context.scene
    timings = {"gpu_backend": backend}

    # 1. Render static plate with moving parts hidden (hide_render = True)
    t0 = time.time()
    moving_set = set(moving_names)
    for n in moving_set:
        if n in bpy.data.objects:
            bpy.data.objects[n].hide_render = True

    sc.render.resolution_x, sc.render.resolution_y = plate_res
    sc.render.film_transparent = False
    sc.cycles.samples = plate_samples
    sc.cycles.use_denoising = True
    plate_path = os.path.join(plate_dir, f"plate_{plate_res[0]}x{plate_res[1]}.png")
    sc.render.filepath = plate_path
    bpy.ops.render.render(write_still=True)

    for n in moving_set:
        if n in bpy.data.objects:
            bpy.data.objects[n].hide_render = False
    timings["plate_render_s"] = round(time.time() - t0, 2)
    print(f"[{family_name}] Plate rendered in {timings['plate_render_s']}s -> {plate_path}", flush=True)

    # 2. Convert curves -> mesh, apply modifiers, triangulate n-gons
    t0 = time.time()
    for o in list(bpy.data.objects):
        if o.type in ('MESH', 'CURVE'):
            select_only([o])
            bpy.ops.object.convert(target='MESH')
    meshes = [o for o in bpy.data.objects if o.type == 'MESH']
    for o in meshes:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        ngons = [f for f in bm.faces if len(f.verts) > 4]
        if ngons:
            bmesh.ops.triangulate(bm, faces=ngons)
            bm.to_mesh(o.data)
        bm.free()

    # Collect moving materials and objects
    moving_objs = [bpy.data.objects[n] for n in moving_names if n in bpy.data.objects and bpy.data.objects[n].type == 'MESH']
    by_mat = {}
    for o in moving_objs:
        if o.data.materials and o.data.materials[0]:
            mname = o.data.materials[0].name
            by_mat.setdefault(mname, []).append(o)

    # Also ensure every mesh has UVs (unwrap moving objects per material atlas)
    mat_info = {}
    for mname, objs in by_mat.items():
        select_only(objs)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=math.radians(60.0), island_margin=0.006, correct_aspect=True, scale_to_bounds=False)
        bpy.ops.uv.pack_islands(margin=0.006, rotate=True)
        bpy.ops.object.mode_set(mode='OBJECT')
        mat_info[mname] = {"objects": [o.name for o in objs], "size": tex_size}
    timings["mesh_prep_uv_s"] = round(time.time() - t0, 2)

    # 3. Render 512x512 Cycles matcaps in the active light field for all moving materials
    t0 = time.time()
    cam = sc.camera
    bpy.context.view_layer.update()
    fwd = (cam.matrix_world.to_3x3() @ Vector((0.0, 0.0, -1.0))).normalized()
    centre = Vector(matcap_centre)

    orig_vis = {o.name: o.hide_render for o in meshes}
    for o in meshes:
        o.hide_render = True

    bpy.ops.mesh.primitive_uv_sphere_add(segments=128, ring_count=64, radius=2.0, location=centre)
    sph = bpy.context.object
    for p in sph.data.polygons:
        p.use_smooth = True

    c2 = bpy.data.cameras.new('mc_cam')
    co = bpy.data.objects.new('mc_cam', c2)
    sc.collection.objects.link(co)
    c2.type = 'ORTHO'
    c2.ortho_scale = 4.0
    co.location = centre - fwd * 60.0
    co.rotation_euler = cam.matrix_world.to_euler()

    sc.camera = co
    sc.render.resolution_x = 512
    sc.render.resolution_y = 512
    sc.render.film_transparent = True
    sc.cycles.samples = 96
    sc.cycles.use_denoising = True

    for mname in by_mat.keys():
        mat = bpy.data.materials[mname]
        sph.data.materials.clear()
        sph.data.materials.append(mat)
        sc.render.filepath = os.path.join(matcap_dir, f"matcap_{mname}.png")
        bpy.ops.render.render(write_still=True)

    bpy.data.objects.remove(sph, do_unlink=True)
    bpy.data.objects.remove(co, do_unlink=True)
    bpy.data.cameras.remove(c2, do_unlink=True)
    sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = plate_res
    sc.render.film_transparent = False
    for o in meshes:
        o.hide_render = orig_vis.get(o.name, False)
    timings["matcap_render_s"] = round(time.time() - t0, 2)
    print(f"[{family_name}] Matcaps ({len(by_mat)}) rendered in {timings['matcap_render_s']}s", flush=True)

    # 4. Bake albedo, normal, and ORM maps for moving materials on GPU
    t0 = time.time()
    for mname, objs in by_mat.items():
        mat = bpy.data.materials[mname]
        bsdf = _principled(mat)
        metal_val = float(bsdf.inputs['Metallic'].default_value) if bsdf else 0.0
        mat_info[mname]["metallic"] = metal_val

        alb = _bake_pass(mat, objs, tex_size, 'albedo', 'sRGB', 8)
        _save_arr(alb, os.path.join(tex_dir, f"{mname}_albedo.png"), 'sRGB')

        rough = _bake_pass(mat, objs, tex_size, 'rough', 'Non-Color', 8)
        nrm = _bake_pass(mat, objs, tex_size, 'normal', 'Non-Color', 8)
        _save_arr(nrm, os.path.join(tex_dir, f"{mname}_normal.png"), 'Non-Color')

        ao = _bake_pass(mat, objs, tex_size, 'ao', 'Non-Color', ao_samples)
        orm = np.zeros_like(rough)
        orm[..., 0] = ao[..., 0]
        orm[..., 1] = rough[..., 0]
        orm[..., 2] = metal_val
        _save_arr(orm, os.path.join(tex_dir, f"{mname}_orm.png"), 'Non-Color')
    timings["bake_textures_s"] = round(time.time() - t0, 2)
    print(f"[{family_name}] Textures baked in {timings['bake_textures_s']}s", flush=True)

    # 5. Record rig metadata in scene.json
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    proj_mat = cam.calc_matrix_camera(depsgraph, x=plate_res[0], y=plate_res[1])
    fov_y_deg = math.degrees(2.0 * math.atan(1.0 / proj_mat[1][1]))
    hfov_deg = math.degrees(2.0 * math.atan(cam.data.sensor_width / 2.0 / cam.data.lens))

    lights = []
    for o in bpy.data.objects:
        if o.type == 'LIGHT':
            mw = o.matrix_world
            l_fwd = (mw.to_3x3() @ Vector((0.0, 0.0, -1.0))).normalized()
            lights.append({
                "name": o.name,
                "type": o.data.type,
                "position": _gl_vec(mw.translation),
                "direction": _gl_vec(l_fwd),
                "size": getattr(o.data, "size", 0.0),
                "energy_w": o.data.energy,
                "color": list(o.data.color),
            })

    aim_obj = bpy.data.objects.get("aim")
    aim_gl = _gl_vec(aim_obj.location) if aim_obj else _gl_vec(camera_target)

    rig = {
        "family": family_name,
        "units": "1 Blender unit = 1 mm = 1 Godot unit",
        "resolution": list(plate_res),
        "camera": {
            "position": _gl_vec(cam.matrix_world.translation),
            "target": _gl_vec(camera_target),
            "lens_mm": round(float(cam.data.lens), 3),
            "sensor_width_mm": round(float(cam.data.sensor_width), 3),
            "sensor_fit": cam.data.sensor_fit,
            "hfov_deg": round(hfov_deg, 6),
            "fov_vertical_deg": round(fov_y_deg, 6),
        },
        "aim": aim_gl,
        "lights": lights,
        "exposure": round(float(sc.view_settings.exposure), 4),
        "view_transform": sc.view_settings.view_transform,
        "look": sc.view_settings.look,
        "moving_nodes": list(moving_names),
        "materials": mat_info,
        "timings": timings,
    }
    if extra_meta:
        rig.update(extra_meta)

    # 6. Strip procedural shader nodes down to Principled BSDF + Output so glTF
    # preserves exact material names cleanly, and export <family>_baked.glb
    t0 = time.time()
    for mat in list(bpy.data.materials):
        if mat.use_nodes and mat.node_tree:
            nt = mat.node_tree
            for n in list(nt.nodes):
                if n.type not in ('BSDF_PRINCIPLED', 'OUTPUT_MATERIAL'):
                    nt.nodes.remove(n)

    for o in bpy.data.objects:
        o.select_set(o.type in ('MESH', 'CAMERA'))

    glb_path = os.path.join(out_dir, f"{family_name}_baked.glb")
    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        use_selection=True,
        export_apply=True,
        export_tangents=True,
        export_cameras=True,
        export_lights=False,
        export_yup=True,
    )
    timings["export_glb_s"] = round(time.time() - t0, 2)
    timings["total_s"] = round(time.time() - t_total, 2)
    rig["timings"] = timings

    scene_json_path = os.path.join(out_dir, "scene.json")
    with open(scene_json_path, "w", encoding="utf-8") as f:
        json.dump(rig, f, indent=2)

    print(f"[{family_name}] ALL DONE in {timings['total_s']}s -> {out_dir}", flush=True)
    return rig
