class_name LockWaferView
extends LockPhotorealView
## N-63: plan-B lock screen for the wafer lock (LOCKS.md §2.4), same method and same thumbs as
## the pin screen: the cutaway of art/renders/wafer.png (mailbox door, brass plug with five
## wafers) rendered in Cycles with the photo materials (art/blender/plates/photo_plates.py):
##   - static lock: plate.png (no wafers, springs, pick) projected through the camera; plug and
##     tension wrench projected from their rest pose so they turn with the tension;
##   - wafers, springs, pick: projected from parts.png at the GLB rest pose (all wafers set).
## States by geometry (WaferPose of the GEM2 view): free = the wafer's tab down in the lower
## housing slot, bound = leaning on the slot wall, set = flush with the plug (both shear lines
## clear), false set = caught on the anti-pick step, overset = its top in the upper slot.
## Chambers the lock does not use are empty slots (the wafer is left out, not shown as set).

const F_DIR := "res://assets/photoreal_families/wafer/"
const F_SCENE := F_DIR + "scene.json"
const F_GLB := F_DIR + "wafer_baked.glb"
const F_PLATE := F_DIR + "photo/plate.png"
const F_PARTS := F_DIR + "photo/parts.png"
const WAFER_X := [7.0, 12.0, 17.0, 22.0, 27.0]
const PLUG_R := 7.0             # shear radius (top and bottom)
const WAFER_HALF_H := 6.97
const NOTCH_Y := 2.6
const BRIDGE_Y := 6.2
const REST_DZ := -1.8
const FALSE_SET_DZ := -0.38
const OVERSET_MIN_DZ := 1.35
const DEFAULT_TARGET := 0.55
const BIND_TILT_DEG := 1.4
const FALSE_TILT_DEG := 2.4
const BIND_SX := 0.08
const W_PICK_REST_X := 17.0
const STATIC_MOVERS := ["plug", "wrench"]
const PARTS := ["pick", "pick_handle"]

var _by := {}
var _n := 5


static func wafer_pose(el: Dictionary) -> Dictionary:
	var target := DEFAULT_TARGET
	if el.has("window_lo") and el.has("window_hi"):
		target = (float(el["window_lo"]) + float(el["window_hi"])) * 0.5
	target = maxf(target, 0.15)
	var p := float(el.get("position", 0.0))
	var dz := REST_DZ + (p / target) * (-REST_DZ)
	var tilt := 0.0
	var sx := 0.0
	match String(el.get("state", "free")):
		"free":
			dz = minf(dz, -0.45)
		"bound", "near":
			dz = clampf(dz, REST_DZ, -0.22)
			tilt = BIND_TILT_DEG
			sx = BIND_SX
		"set":
			dz = 0.0
		"false_set":
			dz = FALSE_SET_DZ
			tilt = FALSE_TILT_DEG
			sx = BIND_SX * 1.75
		"overset":
			dz = maxf(dz, OVERSET_MIN_DZ)
			tilt = 0.45
			sx = BIND_SX * 0.5
		"jammed", "detector":
			dz = 1.85
			tilt = -2.6
			sx = -0.12
	return {"dz": dz, "tilt_deg": tilt, "sx": sx, "spring_bottom_y": clampf(NOTCH_Y + dz, 0.5, BRIDGE_Y - 0.55)}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rig = JSON.parse_string(FileAccess.get_file_as_string(F_SCENE))
	_build_viewport()
	_model = (load(F_GLB) as PackedScene).instantiate()
	for c in _model.find_children("*", "Camera3D", true, false):
		c.get_parent().remove_child(c)
		c.free()
	viewport.add_child(_model)
	for n in _model.find_children("*", "Node3D", true, false):
		_rest[n] = n.transform
		_by[String(n.name)] = n
	_plug = _by.get("plug")
	_wrench = _by.get("wrench")
	_build_camera()
	var plate := _tex(F_PLATE)
	var parts := _tex(F_PARTS)
	var static_mat := _mat("plate.gdshader")
	static_mat.set_shader_parameter("plate", plate)
	for mi: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var nm := String(mi.name)
		var tex: Texture2D = null
		if nm in STATIC_MOVERS:
			tex = plate
		elif nm in PARTS or nm.begins_with("wafer") or nm.begins_with("wspr"):
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


func _set_wafers(n: int) -> void:
	_n = n
	for i in WAFER_X.size():
		for nm in ["wafer%d" % i, "wspr%d" % i]:
			if _by.has(nm):
				(_by[nm] as Node3D).visible = i < n


# ------------------------------------------------------------------ public API
func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	var els: Array = vm.get("elements", [])
	var n := mini(els.size(), WAFER_X.size())
	if els.size() > 0 and n != _n:
		_set_wafers(n)
	_active_stacks = _n
	var tension := float(vm.get("tension", input.get("tension", 0.0)))
	_stress = clampf(float(vm.get("stress", 0.0)), 0.0, 1.0)
	_opened = bool(vm.get("open", false)) or _opened
	var k := 1.0 - exp(-delta / SMOOTH_S)
	_plug_deg = lerpf(_plug_deg, _plug_target(vm, tension), k)
	_wrench_deg = lerpf(_wrench_deg, _plug_deg + WRENCH_MAX_DEG * clampf(tension, 0.0, 1.0), k)
	_apply_plug_and_wrench()
	var plug := Transform3D(_plug_basis(_plug_deg), Vector3.ZERO)
	for i in n:
		var p := wafer_pose(els[i])
		var x: float = WAFER_X[i]
		if _by.has("wafer%d" % i):
			var wf: Node3D = _by["wafer%d" % i]
			var piv := Vector3(x, 0, 0)
			var tilt := Transform3D(Basis(Vector3.BACK, deg_to_rad(p["tilt_deg"])), Vector3.ZERO)
			var shift := Transform3D(Basis.IDENTITY, Vector3(p["sx"], p["dz"], 0))
			wf.transform = plug * shift * Transform3D(Basis.IDENTITY, piv) * tilt * Transform3D(Basis.IDENTITY, -piv) * _rest[wf]
		if _by.has("wspr%d" % i):
			var sp: Node3D = _by["wspr%d" % i]
			var sc := clampf((BRIDGE_Y - float(p["spring_bottom_y"])) / (BRIDGE_Y - NOTCH_Y), 0.15, 1.85)
			sp.transform = plug * Transform3D(Basis.from_scale(Vector3(1, sc, 1)), Vector3(p["sx"], BRIDGE_Y * (1.0 - sc), 0)) * _rest[sp]
	_pose_w_pick(vm, input, els, k)
	_last_vm = vm
	_last_input = input
	_update_face(vm, tension, delta)
	_update_f_chalk(els, delta)
	_update_f_eyepiece(delta)


func _pose_w_pick(vm: Dictionary, input: Dictionary, els: Array, k: float) -> void:
	var n := maxi(_n, 1)
	var depth := clampf(float(input.get("pick_depth", 0.5)), 0.0, 1.0)
	var idx := int(vm.get("pick_element", -1))
	var x: float = lerpf(WAFER_X[0] - 2.0, WAFER_X[n - 1] + 2.0, depth)
	if idx >= 0 and idx < n:
		x = WAFER_X[idx]
	else:
		idx = clampi(int(round((x - WAFER_X[0]) / 5.0)), 0, n - 1)
	var y := REST_DZ + minf(float(input.get("pick_lift", 0.0)), 0.0)
	if idx < els.size() and absf(x - WAFER_X[idx]) < 1.5:
		y = float(wafer_pose(els[idx])["dz"])
	_pick_x = lerpf(_pick_x, x, k)
	_pick_tip = lerpf(_pick_tip, y, k)
	var off := Vector3(_pick_x - W_PICK_REST_X, _pick_tip - (0.6 if _broken else 0.0), 0)
	var plug := Transform3D(_plug_basis(_plug_deg * 0.5), Vector3.ZERO)
	for nm in PARTS:
		if _by.has(nm):
			_by[nm].transform = plug * Transform3D(Basis.IDENTITY, off) * _rest[_by[nm]]


func _update_f_chalk(els: Array, delta: float) -> void:
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
	var x0: float = WAFER_X[0] - 3.0
	var x1: float = WAFER_X[maxi(_n, 1) - 1] + 3.0
	# both shear lines of the plug (a wafer must clear the top and the bottom one)
	m["shear"] = [mm_to_screen(Vector3(x0, PLUG_R, 0)), mm_to_screen(Vector3(x1, PLUG_R, 0))]
	m["paths"] = [PackedVector2Array([mm_to_screen(Vector3(x0, -PLUG_R, 0)), mm_to_screen(Vector3(x1, -PLUG_R, 0))])]
	var stacks := []
	var w := absf((mm_to_screen(Vector3(WAFER_X[0] + 1.5, PLUG_R, 0)) - mm_to_screen(Vector3(WAFER_X[0] - 1.5, PLUG_R, 0))).x)
	for i in mini(els.size(), _n):
		var sp := mm_to_screen(Vector3(WAFER_X[i], PLUG_R, 0))
		var top := mm_to_screen(Vector3(WAFER_X[i], PLUG_R + 2.6, 0))
		stacks.append({"x": sp.x, "shear_y": sp.y, "top_y": top.y, "w": w, "state": String(els[i].get("state", "free"))})
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


func _update_f_eyepiece(delta: float) -> void:
	if _eyepiece == null:
		return
	_eyepiece.tick(delta)
	if not _eyepiece.visible:
		return
	var idx := int(_last_vm.get("pick_element", -1))
	if idx < 0 or idx >= _n:
		idx = clampi(int(round((_pick_x - WAFER_X[0]) / 5.0)), 0, maxi(_n - 1, 0))
	var focus := mm_to_screen(Vector3(WAFER_X[idx], PLUG_R, 0))
	var ed := _eyepiece.size.x
	var r := get_rect()
	var pos := focus - Vector2(ed, ed) * 0.5
	pos.x = clampf(pos.x, 8.0, r.size.x - ed - 8.0)
	pos.y = clampf(pos.y, 8.0, r.size.y - ed - 8.0)
	_eyepiece.position = pos
	var disp := _section_display()
	var half := Vector2(ed * 0.5 / Eyepiece.ZOOM, ed * 0.5 / Eyepiece.ZOOM) / disp.size
	_eyepiece.aim(viewport.get_texture(), (focus - disp.position) / disp.size, half)


## Screen point of the top shear line over wafer i (tests).
func wafer_screen(i: int, dz: float = 0.0) -> Vector2:
	return mm_to_screen(Vector3(WAFER_X[clampi(i, 0, 4)], PLUG_R + dz, 0))
