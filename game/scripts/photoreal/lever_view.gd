class_name LockLeverView
extends LockPhotorealView
## N-63: plan-B lock screen for the lever lock (LOCKS.md §2.7), same method and thumbs as the
## pin screen: the mortise lock of art/renders/lever.png rendered in Cycles with the photo
## materials (art/blender/plates/photo_plates.py):
##   - static case and the bolt: plate.png projected through the camera; bolt + its stud move
##     with the throw (projected from their rest pose);
##   - levers, their springs and rivets, the stump, lifter and tension tool: projected from
##     parts.png at the GLB rest pose (every gate on the stump).
## States by geometry (LeverPose of the GEM2 view): free = gate under the stump, bound = the
## lever's upper tooth bearing on the stump, set = gate on the stump (light above and below),
## false set = the stump in a false notch, overset = gate lifted past the stump.

## Assets per family folder (docs/handoff/LOCAL-SESSION-PROMPT.md (b)): <fam>_baked.glb with
## lever0..leverN-1 / spring<i> / rivet<i> (N <= 6), scene.json (camera, pivot, stump_x,
## lever_specs[i].y0, detector_pivot), photo/plate.png + photo/parts.png. lever_detector uses its
## own folder when it exists, else the 3-lever lever folder.
const FAM_ROOT := "res://assets/photoreal_families/"
const MAX_LEVERS := 6
const DET_TRIP_DEG := -18.5
var PIVOT := Vector3(-22.0, 4.0, 0.0)       # from scene.json "pivot" when present
var STUMP := Vector3(7.7, 0.0, 0.0)        # from scene.json "stump_x"
var DET_PIVOT := Vector3(10.2, 5.8, -8.55) # from scene.json "detector_pivot"
var _dir := FAM_ROOT + "lever/"
var _glb_name := "lever_baked.glb"
const ARM_LEN := 29.7
const GATE_HALF_H := 2.45
const REST_DELTA_LIFT := -3.2
const FALSE_GATE_LIFT := -2.25
const OVERSET_MIN_LIFT := 2.35
const DEFAULT_TARGET := 0.52
var LEVER_DEPTH: Array = [0.9, 4.1, 7.3]   # Blender y of each lever (scene.json lever_specs[i].y0)
var _mesh_levers := 3                      # levers in the GLB
const KEYHOLE := Vector3(-3.0, -18.0, 0.0)
const BOLT_NODES := ["bolt", "stud", "stud_post"]
const PART_PREFIX := ["lever", "spring", "rivet", "detector", "stump", "lifter", "tension"]

## lever_detector (LOCKS.md §2.8): the detector lever is in; a trip throws it into the bolt's
## tail notch, it falls back as the key is turned back (reset_progress).
@export var detector := false
var _by := {}
var _det_deg := 0.0
var _bolt_dx := 0.0
var _tool_deg := 0.0
var _lift_deg := 0.0
var _depth_z := 0.0
var _n := 3


static func lever_pose(el: Dictionary) -> Dictionary:
	var target := DEFAULT_TARGET
	if el.has("window_lo") and el.has("window_hi"):
		target = (float(el["window_lo"]) + float(el["window_hi"])) * 0.5
	target = maxf(target, 0.15)
	var p := float(el.get("position", 0.0))
	var d := REST_DELTA_LIFT + (p / target) * (-REST_DELTA_LIFT)
	var bolt_dx := 0.0
	match String(el.get("state", "free")):
		"free":
			d = minf(d, -1.2)
		"bound", "near":
			d = clampf(d, REST_DELTA_LIFT + 0.4, -0.65)
			bolt_dx = -0.42
		"set":
			d = 0.0
			bolt_dx = -0.85
		"false_set":
			d = FALSE_GATE_LIFT
			bolt_dx = -1.38
		"overset":
			d = maxf(d, OVERSET_MIN_LIFT)
			bolt_dx = -0.30
		"jammed", "detector":
			d = 3.1
			bolt_dx = 0.15
	return {"delta_lift": d, "rot_deg": rad_to_deg(d / ARM_LEN), "bolt_dx": bolt_dx}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if detector and FileAccess.file_exists(FAM_ROOT + "lever_detector/scene.json"):
		_dir = FAM_ROOT + "lever_detector/"
		_glb_name = "lever_detector_baked.glb"
	_rig = JSON.parse_string(FileAccess.get_file_as_string(_dir + "scene.json"))
	_read_rig()
	_build_viewport()
	_model = (load(_dir + _glb_name) as PackedScene).instantiate()
	for c in _model.find_children("*", "Camera3D", true, false):
		c.get_parent().remove_child(c)
		c.free()
	viewport.add_child(_model)
	for n in _model.find_children("*", "Node3D", true, false):
		_rest[n] = n.transform
		_by[String(n.name)] = n
	if _by.has("detector"):
		(_by["detector"] as Node3D).visible = detector  # plain lever lock: no detector lever
	_build_camera()
	_mesh_levers = 0
	while _mesh_levers < MAX_LEVERS and _by.has("lever%d" % _mesh_levers):
		_mesh_levers += 1
	if LEVER_DEPTH.size() < _mesh_levers:
		for i in range(LEVER_DEPTH.size(), _mesh_levers):
			LEVER_DEPTH.append(0.9 + 3.2 * i)
	var plate := _tex(_dir + "photo/plate.png")
	var det_parts := _dir + "photo/parts_detector.png"  # 3-lever folder: the pass with the detector in
	var parts := _tex(det_parts if detector and ResourceLoader.exists(det_parts) else _dir + "photo/parts.png")
	var static_mat := _mat("plate.gdshader")
	static_mat.set_shader_parameter("plate", plate)
	for mi: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var nm := String(mi.name)
		var tex: Texture2D = null
		if nm in BOLT_NODES:
			tex = plate
		else:
			for p in PART_PREFIX:
				if nm.begins_with(p):
					tex = parts
		if tex == null:
			mi.material_override = static_mat
			continue
		var r := _mat("plate_rest.gdshader")
		r.set_shader_parameter("plate", tex)
		r.set_shader_parameter("rest_model", Projection(_rest[mi]))
		mi.material_override = r
	_build_overlay()
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_dark(dark)
	present({}, {})


## scene.json (Blender units, y-up already converted by the plate pipeline): pivot, stump_x,
## lever_specs[i].y0, detector_pivot.
func _read_rig() -> void:
	if _rig.has("pivot"):
		var p: Array = _rig["pivot"]
		PIVOT = Vector3(p[0], p[1], 0.0)
	if _rig.has("stump_x"):
		STUMP = Vector3(float(_rig["stump_x"]), 0.0, 0.0)
	if _rig.has("detector_pivot"):
		var d: Array = _rig["detector_pivot"]
		DET_PIVOT = Vector3(d[0], d[1], d[2])
	if _rig.has("lever_specs"):
		LEVER_DEPTH = []
		for spec in _rig["lever_specs"]:
			LEVER_DEPTH.append(float(spec.get("y0", 0.9 + 3.2 * LEVER_DEPTH.size())))


## Levers this view can show (the GLB's); lockcore locks with more stay off PHOTOREAL_READY.
func lever_count() -> int:
	return _mesh_levers


func _xf(nm: String, t: Transform3D) -> void:
	if _by.has(nm):
		(_by[nm] as Node3D).transform = t * _rest[_by[nm]]


func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	var els: Array = vm.get("elements", [])
	_n = clampi(els.size(), 1, _mesh_levers) if els.size() > 0 else _mesh_levers
	_active_stacks = _n
	var tension := float(vm.get("tension", input.get("tension", 0.0)))
	_stress = clampf(float(vm.get("stress", 0.0)), 0.0, 1.0)
	_opened = bool(vm.get("open", false)) or _opened
	var k := 1.0 - exp(-delta / SMOOTH_S)
	var min_dx := 0.0
	var idx := clampi(int(vm.get("pick_element", -1)), -1, _mesh_levers - 1)
	var active_rot := 0.0
	for i in _mesh_levers:
		var shown := els.is_empty() or i < els.size()  # a lock with fewer levers leaves the rest out
		for nm in ["lever%d" % i, "spring%d" % i, "rivet%d" % i]:
			if _by.has(nm):
				(_by[nm] as Node3D).visible = shown
		var el: Dictionary = els[mini(i, els.size() - 1)] if els.size() > 0 else {"state": &"free", "position": 0.0}
		var p := lever_pose(el)
		min_dx = minf(min_dx, float(p["bolt_dx"]))
		if i == idx:
			active_rot = p["rot_deg"]
		var rot := Transform3D(Basis(Vector3.BACK, deg_to_rad(p["rot_deg"])), PIVOT) * Transform3D(Basis.IDENTITY, -PIVOT)
		_xf("lever%d" % i, rot)
		_xf("rivet%d" % i, rot)
		var srot := Transform3D(Basis(Vector3.BACK, deg_to_rad(p["rot_deg"] * 0.55)), PIVOT) * Transform3D(Basis.IDENTITY, -PIVOT)
		_xf("spring%d" % i, srot)
	var throw := clampf(float(vm.get("core_rotation", 0.0)), 0.0, 1.0)
	var dx := min_dx - throw * 6.0 - 0.35 * clampf(tension, 0.0, 1.0)
	var tripped := false
	for e in els:
		if String(e.get("state", "")) in ["jammed", "detector"]:
			tripped = true
	if tripped:
		dx = 0.25  # the detector holds the bolt's tail
	if _opened:
		dx = -11.5
	var det_target := DET_TRIP_DEG * (1.0 - clampf(float(vm.get("reset_progress", 0.0)), 0.0, 1.0)) if tripped else 0.0
	_det_deg = lerpf(_det_deg, det_target, k)
	_xf("detector", Transform3D(Basis(Vector3.BACK, deg_to_rad(_det_deg)), DET_PIVOT) * Transform3D(Basis.IDENTITY, -DET_PIVOT))
	_bolt_dx = lerpf(_bolt_dx, dx, k)
	var bolt := Transform3D(Basis.IDENTITY, Vector3(_bolt_dx, 0, 0))
	for nm in BOLT_NODES + ["stump"]:
		_xf(nm, bolt)
	# tension tool turns with the force and the throw; the lifter follows the lever it is under
	_tool_deg = lerpf(_tool_deg, clampf(tension, 0.0, 1.0) * 10.0 - _bolt_dx * 1.8, k)
	var trot := Transform3D(Basis(Vector3.BACK, deg_to_rad(_tool_deg)), KEYHOLE) * Transform3D(Basis.IDENTITY, -KEYHOLE)
	_xf("tension", trot)
	_xf("tension_shaft", trot)
	var lift := float(input.get("pick_lift", 0.0))
	_lift_deg = lerpf(_lift_deg, (active_rot * 1.35 if idx >= 0 else minf(lift, 0.0) * 8.0) - (6.0 if _broken else 0.0), k)
	var depth := clampf(float(input.get("pick_depth", 0.5)), 0.0, 1.0)
	var mid: float = LEVER_DEPTH[(_mesh_levers - 1) / 2]
	var y0: float = LEVER_DEPTH[idx] if idx >= 0 else lerpf(LEVER_DEPTH[0], LEVER_DEPTH[_mesh_levers - 1], depth)
	_depth_z = lerpf(_depth_z, -(y0 - mid), k)
	var lrot := Transform3D(Basis.IDENTITY, Vector3(0, 0, _depth_z)) * Transform3D(Basis(Vector3.BACK, deg_to_rad(_lift_deg)), KEYHOLE) * Transform3D(Basis.IDENTITY, -KEYHOLE)
	_xf("lifter", lrot)
	_last_vm = vm
	_last_input = input
	_update_face(vm, tension, delta)
	_update_l_chalk(els, idx, delta)
	_update_l_eyepiece(delta)


## Screen point of lever i's gate centre (tests, chalk).
func gate_screen(i: int) -> Vector2:
	var el: Dictionary = (_last_vm.get("elements", []) as Array)[i] if i < (_last_vm.get("elements", []) as Array).size() else {}
	var d: float = lever_pose(el)["delta_lift"] if not el.is_empty() else 0.0
	return mm_to_screen(STUMP + Vector3(0, d, -(LEVER_DEPTH[clampi(i, 0, _mesh_levers - 1)] - LEVER_DEPTH[(_mesh_levers - 1) / 2])))


func _update_l_chalk(els: Array, idx: int, delta: float) -> void:
	if _chalk == null:
		return
	_chalk.level = chalk_level
	if chalk_level == ChalkLayer.Level.OFF:
		if _goal_only(delta):  # D-79 practice goal
			return
		_chalk.marks = {}
		_chalk.text = ""
		_chalk.tick(delta)
		return
	var m := {}
	# the stump's height: where every gate has to stand
	var a := mm_to_screen(STUMP + Vector3(-6, 0, 0))
	var b := mm_to_screen(STUMP + Vector3(6, 0, 0))
	m["shear"] = [a, b]
	var stacks := []
	var w := absf((mm_to_screen(STUMP + Vector3(2.2, 0, 0)) - mm_to_screen(STUMP - Vector3(2.2, 0, 0))).x)
	for i in mini(els.size(), _mesh_levers):
		var g := gate_screen(i)
		var top := mm_to_screen(STUMP + Vector3(0, 6.0, 0))
		stacks.append({"x": g.x + (i - 1) * w * 0.9, "shear_y": a.y, "top_y": top.y, "w": w * 0.8, "state": String(els[i].get("state", "free"))})
	m["stacks"] = stacks
	var r := get_rect()
	var safe := _safe_rect(r)
	var portrait := safe.size.y >= safe.size.x
	var thumbs_y := tray_rect.position.y + tray_rect.size.y * (0.66 if portrait else 0.75)
	m["left_anchor"] = Vector2(r.size.x * (0.22 if portrait else 0.12), thumbs_y)
	m["right_anchor"] = Vector2(r.size.x * (0.70 if portrait else 0.88), thumbs_y)
	var t := float(_last_input.get("tension", 0.0))
	m["hint_left"] = t < 0.1 and not chalk_gauge
	m["hint_right"] = t >= 0.1 and float(_last_input.get("pick_lift", 0.0)) < 0.05
	var text := _coach_text(m)
	_apply_hint_marks(m)
	_chalk.marks = m
	_chalk.text = text
	_chalk.tick(delta)


func _update_l_eyepiece(delta: float) -> void:
	if _eyepiece == null:
		return
	_eyepiece.tick(delta)
	if not _eyepiece.visible:
		return
	var focus := mm_to_screen(STUMP)
	var ed := _eyepiece.size.x
	var r := get_rect()
	var pos := focus - Vector2(ed, ed) * 0.5
	pos.x = clampf(pos.x, 8.0, r.size.x - ed - 8.0)
	pos.y = clampf(pos.y, 8.0, r.size.y - ed - 8.0)
	_eyepiece.position = pos
	var disp := _section_display()
	var half := Vector2(ed * 0.5 / Eyepiece.ZOOM, ed * 0.5 / Eyepiece.ZOOM) / disp.size
	_eyepiece.aim(viewport.get_texture(), (focus - disp.position) / disp.size, half)
