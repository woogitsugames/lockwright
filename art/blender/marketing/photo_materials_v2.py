# Photo PBR adapter for GEM1-v2 Blender marketing shots (D-48, D-49).
# Preserves the original procedural materials when a map set is incomplete.
import json
import os

import bpy


# (surface, minimum_satin_roughness, normal_strength)
SURFACES = {
    "nickel_body": ("nickel_satin", 0.26, 0.25),
    "nickel_cut": ("nickel_satin", 0.26, 0.25),
    "brass_plug": ("brass_turned", 0.24, 0.20),
    "brass_cut": ("brass_face_milled", 0.24, 0.28),
    "brass_shelf": ("brass_turned", 0.24, 0.20),
    "brass_key": ("brass_turned", 0.24, 0.20),
    "steel_drv": ("steel_ground", 0.26, 0.24),
    "spring_st": ("spring_steel_polished", 0.22, 0.15),
    "pick_st": ("spring_steel_polished", 0.22, 0.15),
    "wrench_st": ("steel_ground", 0.26, 0.24),
    "cam_dark": ("steel_ground", 0.28, 0.18),
    "bolt_brass": ("brass_face_milled", 0.24, 0.24),
}


def default_maps_root():
    return os.path.abspath(os.path.join(
        os.path.dirname(__file__), "..", "..", "textures", "photo"))


def _image(path, color_space):
    image = bpy.data.images.load(path, check_existing=True)
    image.colorspace_settings.name = color_space
    return image


def _map_coords(nodes, links, radial):
    texcoord = nodes.new("ShaderNodeTexCoord")
    texcoord.label = "GEM1-v2 generated coordinates"
    if not radial:
        return texcoord.outputs["Generated"]
    # The turned-metal photograph is radial on the cylinder's YZ face.
    sep = nodes.new("ShaderNodeSeparateXYZ")
    combine = nodes.new("ShaderNodeCombineXYZ")
    links.new(texcoord.outputs["Generated"], sep.inputs["Vector"])
    links.new(sep.outputs["Y"], combine.inputs["X"])
    links.new(sep.outputs["Z"], combine.inputs["Y"])
    return combine.outputs["Vector"]


def apply_photo_materials(materials, maps_root=None, strict=False):
    """Bind photo albedo/normal/roughness to existing Principled metallic shaders.

    Each surface is replaced only when all three maps and metadata exist.
    Roughness is clamped *after* the photo roughness map to prevent mirror metal.
    strict=True raises if any required input is missing; useful for final renders.
    """
    root = maps_root or default_maps_root()
    report = {"applied": {}, "missing": {}}
    for material_name, (surface, rough_floor, normal_strength) in SURFACES.items():
        folder = os.path.join(root, surface)
        paths = {
            "color": os.path.join(folder, surface + "_albedo.jpg"),
            "roughness": os.path.join(folder, surface + "_rough.png"),
            "normal": os.path.join(folder, surface + "_normal.png"),
            "metadata": os.path.join(folder, "material.json"),
        }
        absent = [kind for kind, p in paths.items() if not os.path.isfile(p)]
        mat = materials.get(material_name)
        if mat is None or not mat.use_nodes:
            absent.append("principled_material")
        if absent:
            report["missing"][material_name] = absent
            continue
        try:
            metadata = json.load(open(paths["metadata"], encoding="utf-8"))
        except (ValueError, OSError) as exc:
            report["missing"][material_name] = ["invalid_metadata: " + str(exc)]
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            report["missing"][material_name] = ["principled_bsdf"]
            continue
        tree = mat.node_tree
        nodes, links = tree.nodes, tree.links
        for node in list(nodes):
            if node.label.startswith("GEM1-v2"):
                nodes.remove(node)
        for name in ("Base Color", "Roughness", "Normal"):
            for link in list(bsdf.inputs[name].links):
                links.remove(link)
        coords = _map_coords(nodes, links, radial=(metadata.get("mode") == "radial"))
        for slot, filename, colorspace in (
            ("color", "Albedo", "sRGB"),
            ("roughness", "Roughness", "Non-Color"),
            ("normal", "Normal", "Non-Color"),
        ):
            node = nodes.new("ShaderNodeTexImage")
            node.label = "GEM1-v2 " + slot
            node.image = _image(paths[slot], colorspace)
            node.extension = "CLIP" if metadata.get("mode") == "radial" else "REPEAT"
            node.interpolation = "Linear"
            links.new(coords, node.inputs["Vector"])
            if slot == "color":
                links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
            elif slot == "roughness":
                floor = nodes.new("ShaderNodeMath")
                floor.label = "GEM1-v2 satin roughness floor"
                floor.operation = "MAXIMUM"
                floor.inputs[1].default_value = rough_floor
                links.new(node.outputs["Color"], floor.inputs[0])
                links.new(floor.outputs[0], bsdf.inputs["Roughness"])
            else:
                normal_map = nodes.new("ShaderNodeNormalMap")
                normal_map.label = "GEM1-v2 subtle brushed normal"
                normal_map.space = "TANGENT"
                normal_map.inputs["Strength"].default_value = normal_strength
                links.new(node.outputs["Color"], normal_map.inputs["Color"])
                links.new(normal_map.outputs["Normal"], bsdf.inputs["Normal"])
        bsdf.inputs["Metallic"].default_value = 1.0
        report["applied"][material_name] = surface

    print("[GEM1-v2] Photo materials:", json.dumps(report, ensure_ascii=False), flush=True)
    if strict and report["missing"]:
        raise RuntimeError("GEM1-v2 photo materials missing: " + str(report["missing"]))
    return report
