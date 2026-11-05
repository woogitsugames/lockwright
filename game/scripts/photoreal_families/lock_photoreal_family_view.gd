class_name LockPhotorealFamilyView
extends Control
## Photoreal lock screen view (Plan B, D-31 / D-37) for the 4 additional lock families:
##   - `wafer` (single-sided 5-wafer cylinder lock in mailbox door)
##   - `lever` & `lever_detector` (3-lever mortise lock with Chubb detector pawl)
##   - `warded` (wrought-iron chest lock with concentric wards and spring tumbler)
##   - `wooden_pin` (sectioned oak/ash gravity-pin lock with toothbrush peg lifter)
##
## Implements the exact same public API as LockPhotorealView (`present`, `on_event`, `set_lives`,
## `set_dark`, `touch`, `pause_requested`) and includes the T06 P0 OLED-black dark mode fix.

signal pause_requested

const TRAY_FULL := "res://assets/photoreal/tray/tray_full.png"
const TRAY_EMPTY := "res://assets/photoreal/tray/tray_empty.png"
const SECTION_ASPECT := 1236.0 / 1650.0
const TRAY_COLUMNS := [0.0, 0.233, 0.503, 0.76]
const TRAY_POCKETS := 3
const FLAP_DP := 48.0
const SMOOTH_S := 0.06
const PICK_BEND_MM := 0.45

const WAFER_X := [7.0, 12.0, 17.0, 22.0, 27.0]
const WOODEN_PIN_X := [-22.0, 0.0, 22.0]

@export var family_id: StringName = &"wafer"
@export var detector_enabled := false
@export var lives := 3: set = set_lives
@export var dark := false: set = set_dark
@export_range(0.5, 3.0) var render_scale := 1.0
@export_enum("Disabled", "2x", "4x") var msaa := 1

var viewport: SubViewport
var section_rect := Rect2()
var tray_rect := Rect2()

var _asset_dir: String
var _rig: Dictionary = {}
var _model: Node3D
var _camera: Camera3D
var _section: TextureRect
var _tray: Control
var _bg: Control
var _flap: Control
var _tray_full: Texture2D
var _tray_empty: Texture2D
var _all_mats: Array[ShaderMaterial] = []
var _plate_mats: Array[ShaderMaterial] = []
var _occ := PackedVector4Array()
var _rest := {} # Node3D -> Transform3D
var _by_name := {} # String -> Node3D
var _pick_mat: ShaderMaterial

# Smoothed presentation state
var _plug_deg := 0.0
var _wrench_deg := 0.0
var _tool_x := 0.0
var _tool_y := 0.0
var _tool_ang := 0.0
var _bolt_dx := 0.0
var _stress := 0.0
var _broken := false
var _opened := false
var _touches := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var base_fam := String(family_id)
	if base_fam == "lever_detector":
		base_fam = "lever"
		detector_enabled = true
	_asset_dir = "res://assets/photoreal_families/%s/" % base_fam
	var json_path := _asset_dir + "scene.json"
	if FileAccess.file_exists(json_path):
		_rig = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	_build_viewport()
	_build_model(base_fam)
	_build_camera()
	_build_materials(base_fam)
	_build_overlay()
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_dark(dark)
	present({}, {}, 1.0)


# ------------------------------------------------------------------ public API
func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	var elements: Array = vm.get("elements", vm.get("pins", []))
	var tension: float = float(vm.get("tension", input.get("tension", 0.0)))
	_stress = clampf(float(vm.get("stress", 0.0)), 0.0, 1.0)
	_opened = bool(vm.get("open", false)) or String(vm.get("phase", "")) == "open" or _opened
	var k := clampf(1.0 - exp(-delta / SMOOTH_S), 0.05, 1.0)

	var base_fam := String(family_id)
	if base_fam == "lever_detector" or String(vm.get("family", "")) == "lever_detector":
		base_fam = "lever"
		detector_enabled = true

	_occ.resize(5)
	for i in 5:
		_occ[i] = Vector4(0.0, 0.0, 0.0, 0.0)

	match base_fam:
		"wafer":
			_present_wafer(vm, input, elements, tension, k)
		"lever":
			_present_lever(vm, input, elements, tension, k)
		"warded":
			_present_warded(vm, input, elements, tension, k)
		"wooden_pin":
			_present_wooden_pin(vm, input, elements, tension, k)

	for m in _plate_mats:
		m.set_shader_parameter("stacks", _occ)


func on_event(e: Dictionary) -> void:
	match StringName(e.get("kind", &"")):
		&"break":
			_broken = true
			if lives > 0:
				set_lives(lives - 1)
		&"open":
			_opened = true


func set_lives(n: int) -> void:
	lives = clampi(n, 0, TRAY_POCKETS)
	if _tray:
		_tray.queue_redraw()


## "In the dark" (HUD.md §10 & contrib/gpt/T06 P0 fix):
## True OLED black (#000000); 3D section and leather roll are completely hidden;
## only the subtle relief outline of the pause flap (~3:1 contrast) and optional
## faint touch dent (~1.5:1 contrast) remain visible.
func set_dark(on: bool) -> void:
	dark = on
	for m in _all_mats:
		m.set_shader_parameter("exposure", 0.0 if on else 1.0)
	if _section:
		_section.visible = not on
	if _bg:
		_bg.queue_redraw()
	if _tray:
		_tray.queue_redraw()
	if _flap:
		_flap.queue_redraw()


func touch(index: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if not _touches.has(index):
			_touches[index] = {"start": pos, "pos": pos}
		_touches[index]["pos"] = pos
	else:
		_touches.erase(index)
	if _tray:
		_tray.queue_redraw()


# ------------------------------------------------------------------ build
func _build_viewport() -> void:
	viewport = SubViewport.new()
	viewport.name = "Section3D"
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][msaa]
	viewport.size = Vector2i(824, 1100)
	add_child(viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.028, 0.025)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.glow_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	viewport.add_child(we)

	_section = TextureRect.new()
	_section.name = "Section"
	_section.texture = viewport.get_texture()
	_section.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_section.stretch_mode = TextureRect.STRETCH_SCALE
	_section.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_section)


func _build_model(base_fam: String) -> void:
	var glb_path := _asset_dir + "%s_baked.glb" % base_fam
	var packed := load(glb_path) as PackedScene
	if packed == null:
		_model = Node3D.new()
		viewport.add_child(_model)
		return
	_model = packed.instantiate()
	for c in _model.find_children("*", "Camera3D", true, false):
		c.get_parent().remove_child(c)
		c.free()
	viewport.add_child(_model)
	for n in _model.find_children("*", "Node3D", true, false):
		_rest[n] = n.transform
		_by_name[String(n.name)] = n


func _build_camera() -> void:
	_camera = Camera3D.new()
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	var c: Dictionary = _rig.get("camera", {})
	var hfov: float = float(c.get("hfov_deg", 28.0))
	_camera.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(hfov) * 0.5) / SECTION_ASPECT))
	_camera.near = 10.0
	_camera.far = 2000.0
	viewport.add_child(_camera)
	var p: Array = c.get("position", [0.0, 0.0, 100.0])
	var t: Array = c.get("target", [0.0, 0.0, 0.0])
	_camera.look_at_from_position(Vector3(p[0], p[1], p[2]), Vector3(t[0], t[1], t[2]), Vector3.UP)
	_camera.current = true


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _mat(shader_file: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/photoreal_families/" + shader_file)
	_all_mats.append(m)
	return m


func _matcap_mat(mname: String, base_fam: String) -> ShaderMaterial:
	var m := _mat("family_matcap.gdshader")
	m.set_shader_parameter("matcap", _tex(_asset_dir + "matcap/matcap_%s.png" % mname))
	m.set_shader_parameter("normal_map", _tex(_asset_dir + "tex/%s_normal.png" % mname))
	m.set_shader_parameter("orm", _tex(_asset_dir + "tex/%s_orm.png" % mname))
	m.set_shader_parameter("albedo_map", _tex(_asset_dir + "tex/%s_albedo.png" % mname))
	var alb_mix := 0.18
	if base_fam == "wooden_pin" and ("wood" in mname or "lifter" in mname):
		alb_mix = 0.45
	elif base_fam == "warded" and ("iron" in mname):
		alb_mix = 0.35
	m.set_shader_parameter("albedo_mix", alb_mix)
	return m


func _build_materials(base_fam: String) -> void:
	if _model == null:
		return
	var plate := _tex(_asset_dir + "plate/plate_1236x1650.png")
	var static_mat := _mat("family_plate.gdshader")
	static_mat.set_shader_parameter("plate", plate)
	if base_fam == "wafer":
		static_mat.set_shader_parameter("shear_y", WaferPose.PLUG_R)
		static_mat.set_shader_parameter("cap_y", WaferPose.BRIDGE_Y)
	elif base_fam == "wooden_pin":
		static_mat.set_shader_parameter("shear_y", WoodenPinPose.BOLT_TOP_Y)
		static_mat.set_shader_parameter("cap_y", WoodenPinPose.STEP_Y)
	else:
		static_mat.set_shader_parameter("shear_y", -999.0)
	_plate_mats.append(static_mat)

	var moving_list: Array = _rig.get("moving_nodes", [])
	var moving_set := {}
	for nm in moving_list:
		moving_set[String(nm)] = true

	var matcaps := {}
	for mi: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		var nm := String(mi.name)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var override: Material = static_mat
		if (base_fam == "wafer" and (nm == "plug" or nm == "wrench")) or (base_fam == "lever" and (nm == "bolt" or nm == "stud")):
			var r := _mat("family_plate_rest.gdshader")
			r.set_shader_parameter("plate", plate)
			r.set_shader_parameter("rest_model", Projection(_rest[mi]))
			r.set_shader_parameter("shear_y", WaferPose.PLUG_R if base_fam == "wafer" else -999.0)
			r.set_shader_parameter("cap_y", WaferPose.BRIDGE_Y)
			_plate_mats.append(r)
			override = r
		elif moving_set.has(nm):
			var src := mi.mesh.surface_get_material(0) if mi.mesh and mi.mesh.get_surface_count() > 0 else null
			var mname := src.resource_name if src and src.resource_name != "" else ""
			if mname == "":
				mname = _find_material_for_node(nm)
			if nm in ["pick", "lifter", "probe_tube", "bit"]:
				_pick_mat = _matcap_mat(mname, base_fam)
				override = _pick_mat
			else:
				if not matcaps.has(mname):
					matcaps[mname] = _matcap_mat(mname, base_fam)
				override = matcaps[mname]
		mi.material_override = override


func _find_material_for_node(node_name: String) -> String:
	var mats: Dictionary = _rig.get("materials", {})
	for mname in mats.keys():
		var objs: Array = mats[mname].get("objects", [])
		if objs.has(node_name):
			return String(mname)
	return mats.keys()[0] if mats.size() > 0 else "steel"


func _build_overlay() -> void:
	_tray_full = _tex(TRAY_FULL)
	_tray_empty = _tex(TRAY_EMPTY)
	if _tray_full == null:
		_tray_full = _tray_empty
	_bg = Control.new()
	_bg.name = "Backdrop"
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.draw.connect(_draw_bg)
	add_child(_bg)
	move_child(_bg, 0)

	_tray = Control.new()
	_tray.name = "Tray"
	_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tray.draw.connect(_draw_tray)
	add_child(_tray)

	_flap = Control.new()
	_flap.name = "PauseFlap"
	_flap.mouse_filter = Control.MOUSE_FILTER_STOP
	_flap.custom_minimum_size = Vector2(FLAP_DP, FLAP_DP)
	_flap.draw.connect(_draw_flap)
	_flap.gui_input.connect(_on_flap_input)
	add_child(_flap)


# ------------------------------------------------------------------ layout
func _layout() -> void:
	var r := get_rect()
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	var safe := _safe_rect(r)
	if safe.size.y >= safe.size.x:
		var h := minf(r.size.x / SECTION_ASPECT, safe.size.y * 0.72)
		section_rect = Rect2(r.position, Vector2(r.size.x, safe.position.y - r.position.y + h))
		tray_rect = Rect2(Vector2(r.position.x, section_rect.end.y), Vector2(r.size.x, r.end.y - section_rect.end.y))
	else:
		var th := r.size.y * 0.26
		var sh := r.size.y - th
		var sw := sh * SECTION_ASPECT
		section_rect = Rect2(Vector2(r.position.x + (r.size.x - sw) * 0.5, r.position.y), Vector2(sw, sh))
		tray_rect = Rect2(Vector2(section_rect.position.x - sw * 0.25, section_rect.end.y), Vector2(sw * 1.5, th))

	_section.position = section_rect.position
	_section.size = section_rect.size
	_section.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var px_scale := _physical_scale()
	var vp_h := int(round(section_rect.size.y * px_scale * render_scale))
	var vp_w := int(round(vp_h * SECTION_ASPECT))
	if section_rect.size.x / section_rect.size.y > SECTION_ASPECT:
		vp_w = int(round(section_rect.size.x * px_scale * render_scale))
		vp_h = int(round(vp_w / SECTION_ASPECT))
	viewport.size = Vector2i(maxi(vp_w, 16), maxi(vp_h, 16))

	_tray.position = tray_rect.position
	_tray.size = tray_rect.size
	var corner := Vector2(safe.end.x - FLAP_DP - 8.0, safe.position.y + 8.0)
	if safe.size.x > safe.size.y:
		corner = Vector2(safe.position.x + 8.0, safe.position.y + 8.0)
	_flap.position = corner
	_flap.size = Vector2(FLAP_DP, FLAP_DP)
	_tray.queue_redraw()
	_flap.queue_redraw()
	_bg.queue_redraw()


func _physical_scale() -> float:
	var vis := get_viewport().get_visible_rect().size
	var win := Vector2(get_window().size) if get_window() else vis
	if vis.x <= 0.0:
		return 1.0
	return maxf(win.x / vis.x, 1.0)


func _safe_rect(r: Rect2) -> Rect2:
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var win := Vector2(get_window().size) if get_window() else r.size
	if safe.size.x <= 0.0 or win.x <= 0.0 or not OS.has_feature("mobile"):
		return r
	var s := r.size / win
	return Rect2(safe.position * s, safe.size * s).intersection(r)


# ------------------------------------------------------------------ family pose application
func _present_wafer(vm: Dictionary, input: Dictionary, elements: Array, tension: float, k: float) -> void:
	var rot := clampf(float(vm.get("core_rotation", 0.0)), 0.0, 1.0)
	var has_false := false
	for el in elements:
		if String(el.get("state", "")) == "false_set":
			has_false = true
			break
	var target_deg := minf(rot * 90.0, 12.0) + 1.2 * clampf(tension, 0.0, 1.0)
	if has_false:
		target_deg = maxf(target_deg, 3.6)
	if _opened:
		target_deg = 24.0
	_plug_deg = lerpf(_plug_deg, target_deg, k)
	_wrench_deg = lerpf(_wrench_deg, _plug_deg + 14.0 * clampf(tension, 0.0, 1.0), k)

	var plug_basis := Basis(Vector3.RIGHT, deg_to_rad(-_plug_deg))
	var plug_xf := Transform3D(plug_basis, Vector3.ZERO)
	if _by_name.has("plug"):
		var n: Node3D = _by_name["plug"]
		n.transform = plug_xf * _rest[n]
	if _by_name.has("wrench"):
		var n: Node3D = _by_name["wrench"]
		n.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-_wrench_deg)), Vector3.ZERO) * _rest[n]

	var n_wafers := WAFER_X.size()
	for i in n_wafers:
		var el: Dictionary = elements[i] if i < elements.size() else {"state": &"set", "position": WaferPose.DEFAULT_TARGET}
		var p := WaferPose.pose(el)
		var wx: float = WAFER_X[i]
		var wf_name := "wafer%d" % i
		if _by_name.has(wf_name):
			var wf: Node3D = _by_name[wf_name]
			var piv := Vector3(wx, 0.0, 0.0)
			var tilt := Transform3D(Basis(Vector3.BACK, deg_to_rad(p["tilt_deg"])), Vector3.ZERO)
			var shift := Transform3D(Basis.IDENTITY, Vector3(p["sx"], p["dz"], 0.0))
			wf.transform = plug_xf * shift * Transform3D(Basis.IDENTITY, piv) * tilt * Transform3D(Basis.IDENTITY, -piv) * _rest[wf]
		var sp_name := "wspr%d" % i
		if _by_name.has(sp_name):
			var sp: Node3D = _by_name[sp_name]
			var hi := WaferPose.BRIDGE_Y
			var rest_lo := WaferPose.NOTCH_Y
			var cur_lo: float = p["spring_bottom_y"]
			var sc_y := clampf((hi - cur_lo) / maxf(hi - rest_lo, 0.1), 0.15, 1.85)
			var sp_xf := Transform3D(Basis.from_scale(Vector3(1.0, sc_y, 1.0)), Vector3(p["sx"], hi * (1.0 - sc_y), 0.0))
			sp.transform = plug_xf * sp_xf * _rest[sp]
		_occ[i] = Vector4(wx + p["sx"], p["bottom_y"], p["top_y"], 1.35)

	# Pick pose
	var depth := clampf(float(vm.get("pick_depth", input.get("pick_depth", 0.5))), 0.0, 1.0)
	var lift := float(vm.get("pick_lift", input.get("pick_lift", 0.0)))
	var idx := int(vm.get("active_element", vm.get("pick_element", -1)))
	var px: float = lerpf(WAFER_X[0], WAFER_X[n_wafers - 1], depth)
	if idx >= 0 and idx < n_wafers:
		px = WAFER_X[idx]
	else:
		idx = clampi(int(round((px - WAFER_X[0]) / 5.0)), 0, n_wafers - 1)
	var py := -0.4 + lift * 1.8
	if idx < elements.size():
		var wp := WaferPose.pose(elements[idx])
		py = float(wp["dz"]) + 0.42
	_tool_x = lerpf(_tool_x, px - 17.0, k)
	_tool_y = lerpf(_tool_y, py - 0.42, k)
	var pick_off := Vector3(_tool_x, _tool_y - (0.6 if _broken else 0.0), 0.0)
	for pnm in ["pick", "pick_handle"]:
		if _by_name.has(pnm):
			var pn: Node3D = _by_name[pnm]
			pn.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-_plug_deg * 0.5)), Vector3.ZERO) * Transform3D(Basis.IDENTITY, pick_off) * _rest[pn]
	if _pick_mat:
		var shake := 0.04 * sin(Time.get_ticks_msec() * 0.09) if _stress >= 0.9 else 0.0
		_pick_mat.set_shader_parameter("bend", PICK_BEND_MM * _stress + shake)


func _present_lever(vm: Dictionary, input: Dictionary, elements: Array, tension: float, k: float) -> void:
	var n_mesh := 3
	var piv := Vector3(LeverPose.PIVOT_X, LeverPose.PIVOT_Y, 0.0)
	var any_tripped := false
	var min_bolt_dx := 0.0
	var all_set := elements.size() > 0

	for i in n_mesh:
		var el: Dictionary
		if elements.size() == 0:
			el = {"state": &"free", "position": 0.0}
			all_set = false
		elif i < elements.size():
			el = elements[i]
		else:
			el = elements[elements.size() - 1]
		if String(el.get("state", "")) != "set":
			all_set = false

		var p := LeverPose.pose(el)
		if bool(p["detector_tripped"]):
			any_tripped = true
		min_bolt_dx = minf(min_bolt_dx, float(p["bolt_dx"]))

		var rot_xf := Transform3D(Basis.IDENTITY, piv) * Transform3D(Basis(Vector3.BACK, deg_to_rad(p["rot_deg"])), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -piv)
		for prefix in ["lever", "rivet"]:
			var nm := "%s%d" % [prefix, i]
			if _by_name.has(nm):
				var node: Node3D = _by_name[nm]
				node.transform = rot_xf * _rest[node]
		var sp_nm := "spring%d" % i
		if _by_name.has(sp_nm):
			var sp: Node3D = _by_name[sp_nm]
			var sp_rot := Transform3D(Basis.IDENTITY, piv) * Transform3D(Basis(Vector3.BACK, deg_to_rad(p["rot_deg"] * 0.55)), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -piv)
			sp.transform = sp_rot * _rest[sp]
		_occ[i] = Vector4(LeverPose.STUMP_X, p["gate_lo_y"], p["gate_hi_y"], 2.4)

	var rot_prog := clampf(float(vm.get("core_rotation", 0.0)), 0.0, 1.0)
	var target_bolt_dx := min_bolt_dx - rot_prog * 6.0 - (0.35 * tension if not any_tripped else 0.0)
	if all_set:
		target_bolt_dx = minf(target_bolt_dx, -1.65)
	if _opened:
		target_bolt_dx = -11.5
	if any_tripped:
		target_bolt_dx = 0.25 # Detector pawl locks the bolt tail
	_bolt_dx = lerpf(_bolt_dx, target_bolt_dx, k)

	var bolt_xf := Transform3D(Basis.IDENTITY, Vector3(_bolt_dx, 0.0, 0.0))
	for bnm in ["bolt", "stump", "stud"]:
		if _by_name.has(bnm):
			var bn: Node3D = _by_name[bnm]
			bn.transform = bolt_xf * _rest[bn]

	if _by_name.has("detector"):
		var det: Node3D = _by_name["detector"]
		det.visible = detector_enabled or any_tripped
		var det_piv := Vector3(10.2, 5.8, -8.55)
		var reset_prog := clampf(float(vm.get("reset_progress", 0.0)), 0.0, 1.0)
		var det_deg := LeverPose.DETECTOR_TRIP_DEG * (1.0 - reset_prog) if any_tripped else 0.0
		var det_xf := Transform3D(Basis.IDENTITY, det_piv) * Transform3D(Basis(Vector3.BACK, deg_to_rad(det_deg)), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -det_piv)
		det.transform = det_xf * _rest[det]

	# Tensioner and lifter wire around the keyhole (-3.0, -18.0)
	var kh_piv := Vector3(-3.0, -18.0, 0.0)
	var tens_deg := clampf(tension, -1.0, 1.0) * 10.0 - _bolt_dx * 1.8
	var tens_xf := Transform3D(Basis.IDENTITY, kh_piv) * Transform3D(Basis(Vector3.BACK, deg_to_rad(tens_deg)), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -kh_piv)
	for tnm in ["tension", "tension_shaft"]:
		if _by_name.has(tnm):
			var tn: Node3D = _by_name[tnm]
			tn.transform = tens_xf * _rest[tn]

	if _by_name.has("lifter"):
		var lf: Node3D = _by_name["lifter"]
		var active_el: Dictionary = elements[0] if elements.size() > 0 else {"state": &"free", "position": 0.0}
		var lp := LeverPose.pose(active_el)
		var lift_deg := float(lp["rot_deg"]) * 1.35
		var lf_xf := Transform3D(Basis.IDENTITY, kh_piv) * Transform3D(Basis(Vector3.BACK, deg_to_rad(lift_deg)), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -kh_piv)
		lf.transform = lf_xf * _rest[lf]


func _present_warded(vm: Dictionary, input: Dictionary, elements: Array, tension: float, k: float) -> void:
	# Select the primary bolt/ward element state to drive the cutaway pose
	var el := {"state": &"free", "position": 0.0}
	if elements.size() > 0:
		el = elements[elements.size() - 1]
		for e in elements:
			var st := String(e.get("state", "free"))
			if st in ["jammed", "detector", "overset", "false_set", "bound", "set"]:
				el = e
				if st != "set":
					break

	var p := WardedPose.pose(el)
	var rot_prog := clampf(float(vm.get("core_rotation", 0.0)), 0.0, 1.0)
	var bit_deg: float = float(p["bit_delta_deg"])
	var tumb_deg: float = float(p["tumbler_delta_deg"])
	var bolt_dx: float = float(p["bolt_dx"]) - rot_prog * 8.0 - 0.25 * clampf(tension, 0.0, 1.0)
	if _opened:
		bolt_dx = -12.0

	_tool_ang = lerpf(_tool_ang, bit_deg, k)
	_tool_y = lerpf(_tool_y, tumb_deg, k)
	_bolt_dx = lerpf(_bolt_dx, bolt_dx, k)

	var pin_piv := Vector3(WardedPose.PIN_X, WardedPose.PIN_Y, 0.0)
	var bit_rot := Transform3D(Basis.IDENTITY, pin_piv) * Transform3D(Basis(Vector3.BACK, deg_to_rad(_tool_ang)), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -pin_piv)
	var rad_shift := Transform3D(Basis.IDENTITY, Vector3(0.0, float(p["bit_radial_mm"]), 0.0))
	if _by_name.has("probe_tube"):
		var pt: Node3D = _by_name["probe_tube"]
		pt.transform = bit_rot * _rest[pt]
	if _by_name.has("bit"):
		var bt: Node3D = _by_name["bit"]
		bt.transform = bit_rot * rad_shift * _rest[bt]

	var tpiv := Vector3(WardedPose.TPIV_X, WardedPose.TPIV_Y, 0.0)
	var tumb_rot := Transform3D(Basis.IDENTITY, tpiv) * Transform3D(Basis(Vector3.BACK, deg_to_rad(_tool_y)), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -tpiv)
	for tnm in ["tumbler", "tstud"]:
		if _by_name.has(tnm):
			var tn: Node3D = _by_name[tnm]
			tn.transform = tumb_rot * _rest[tn]
	if _by_name.has("leaf"):
		var lf: Node3D = _by_name["leaf"]
		var lpiv := Vector3(-27.5, 39.3, 0.0)
		var lrot := Transform3D(Basis.IDENTITY, lpiv) * Transform3D(Basis(Vector3.BACK, deg_to_rad(_tool_y * 0.45)), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -lpiv)
		lf.transform = lrot * _rest[lf]

	if _by_name.has("bolt"):
		var bn: Node3D = _by_name["bolt"]
		bn.transform = Transform3D(Basis.IDENTITY, Vector3(_bolt_dx, 0.0, 0.0)) * _rest[bn]

	_occ[0] = Vector4(WardedPose.STUD_X + _bolt_dx, WardedPose.BOLT_TOP_Y - 2.0, float(p["stud_bottom_y"]) + 3.0, 2.2)


func _present_wooden_pin(vm: Dictionary, input: Dictionary, elements: Array, tension: float, k: float) -> void:
	var n_pins := WOODEN_PIN_X.size()
	var all_set := elements.size() > 0
	var any_false := false
	var any_tripped := false
	var active_idx := int(vm.get("active_element", vm.get("pick_element", 1)))
	active_idx = clampi(active_idx if active_idx >= 0 else 1, 0, n_pins - 1)
	var active_pose := WoodenPinPose.pose({"state": &"free", "position": 0.0})

	for i in n_pins:
		var el: Dictionary
		if elements.size() == 0:
			el = {"state": &"free", "position": 0.0}
			all_set = false
		elif i < elements.size():
			el = elements[i]
		else:
			el = elements[elements.size() - 1]
		var st := String(el.get("state", "free"))
		if st != "set":
			all_set = false
		if st == "false_set":
			any_false = true
		if st in ["jammed", "detector"]:
			any_tripped = true

		var p := WoodenPinPose.pose(el)
		if i == active_idx or st in ["bound", "false_set", "overset", "jammed", "detector"]:
			active_pose = p
			active_idx = i

		var px: float = WOODEN_PIN_X[i]
		var pnm := "pin%d" % i
		if _by_name.has(pnm):
			var pn: Node3D = _by_name[pnm]
			var piv := Vector3(px, WoodenPinPose.REST_FOOT_Y + WoodenPinPose.PIN_LEN, 0.0)
			var tilt := Transform3D(Basis.IDENTITY, piv) * Transform3D(Basis(Vector3.BACK, deg_to_rad(p["tilt_deg"])), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -piv)
			var shift := Transform3D(Basis.IDENTITY, Vector3(p["sx"], p["lift"], 0.0))
			pn.transform = shift * tilt * _rest[pn]
		_occ[i] = Vector4(px + p["sx"], p["foot_y"], p["top_y"], 6.2)

	var rot_prog := clampf(float(vm.get("core_rotation", 0.0)), 0.0, 1.0)
	var hold_prog := clampf(float(vm.get("hold_progress", 0.0)), 0.0, 1.0)
	var target_bolt_dx := -0.6 * clampf(tension, 0.0, 1.0) - maxf(rot_prog, hold_prog * 0.35) * 14.0
	if any_false:
		target_bolt_dx = minf(target_bolt_dx, -1.85)
	elif all_set:
		target_bolt_dx = minf(target_bolt_dx, -3.2)
	if any_tripped:
		target_bolt_dx = 0.85
	if _opened:
		target_bolt_dx = -18.0
	_bolt_dx = lerpf(_bolt_dx, target_bolt_dx, k)

	if _by_name.has("bolt"):
		var bn: Node3D = _by_name["bolt"]
		bn.transform = Transform3D(Basis.IDENTITY, Vector3(_bolt_dx, 0.0, 0.0)) * _rest[bn]

	# Toothbrush peg lifter inside the underside groove
	var target_x: float = WOODEN_PIN_X[active_idx]
	var target_lift: float = float(active_pose["lifter_top_y"]) - WoodenPinPose.REST_FOOT_Y
	_tool_x = lerpf(_tool_x, target_x, k)
	_tool_y = lerpf(_tool_y, target_lift - (1.8 if _broken else 0.0), k)
	var tool_xf := Transform3D(Basis.IDENTITY, Vector3(_tool_x, _tool_y, 0.0))
	for lnm in ["lifter", "peg", "ferrule"]:
		if _by_name.has(lnm):
			var ln: Node3D = _by_name[lnm]
			ln.transform = tool_xf * _rest[ln]


# ------------------------------------------------------------------ 2D: leather roll, flap, thumb dents, OLED dark mode
func _draw_bg() -> void:
	var sz := _bg.size
	if dark:
		# HUD.md §10 & contrib/gpt/T06 P0: pure OLED black (#000000)
		_bg.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.0, 0.0, 0.0, 1.0))
		return
	if _tray_empty == null:
		_bg.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.12, 0.08, 0.055))
		return
	var img := Vector2(_tray_empty.get_size())
	var src := Rect2(Vector2(0, img.y * 0.11), Vector2(img.x, img.y * 0.12))
	var tile := src.size / maxf(_physical_scale(), 1.0)
	var rows := int(ceil(sz.y / tile.y)) + 1
	var cols := int(ceil(sz.x / tile.x)) + 1
	for r in rows:
		for c in cols:
			if r % 2 == 1:
				_bg.draw_set_transform(Vector2(c * tile.x, (r + 1) * tile.y), 0.0, Vector2(1, -1))
			else:
				_bg.draw_set_transform(Vector2(c * tile.x, r * tile.y), 0.0, Vector2.ONE)
			_bg.draw_texture_rect_region(_tray_empty, Rect2(Vector2.ZERO, tile), src, Color(0.55, 0.55, 0.55))
	_bg.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_tray() -> void:
	if dark:
		# HUD.md §10: in dark mode the leather roll is hidden; only optional faint (~1.5:1) touch dents appear
		for t in _touches.values():
			var p: Vector2 = t["pos"] - _tray.position
			_tray.draw_circle(p, 26.0, Color(0.08, 0.075, 0.07, 0.85))
			_tray.draw_arc(p, 26.0, 0.0, TAU, 32, Color(0.12, 0.11, 0.10, 0.9), 1.5)
		return
	if _tray_full == null:
		_tray.draw_rect(Rect2(Vector2.ZERO, _tray.size), Color(0.18, 0.12, 0.08))
		return
	var img := Vector2(_tray_full.get_size())
	var sz := _tray.size
	var sc := maxf(sz.x / img.x, sz.y / img.y)
	var shown := sz / sc
	var origin := (img - shown) * 0.5
	origin.y = 0.0
	if sz.x / maxf(sz.y, 1.0) > 1.6:
		sc = sz.x / img.x
		shown = sz / sc
		origin = Vector2(0.0, clampf(img.y * 0.22, 0.0, maxf(img.y - shown.y, 0.0)))
	var cols: Array = TRAY_COLUMNS.duplicate()
	cols.append(1.0)
	for c in cols.size() - 1:
		var tex := _tray_full
		if c < TRAY_POCKETS and c >= lives:
			tex = _tray_empty
		var x0: float = maxf(cols[c] * img.x, origin.x)
		var x1: float = minf(cols[c + 1] * img.x, origin.x + shown.x)
		if x1 <= x0:
			continue
		var src := Rect2(Vector2(x0, origin.y), Vector2(x1 - x0, shown.y))
		var dst := Rect2(Vector2((x0 - origin.x) * sc, 0.0), Vector2((x1 - x0) * sc, sz.y))
		_tray.draw_texture_rect_region(tex, dst, src)
	for j in 6:
		_tray.draw_rect(Rect2(0, j * 2.0, sz.x, 2.0), Color(0, 0, 0, 0.22 * (1.0 - j / 6.0)))
	for t in _touches.values():
		var p: Vector2 = t["pos"] - _tray.position
		var s: Vector2 = t["start"] - _tray.position
		_dent(s, 20.0, 0.10)
		_dent(p, 28.0, 0.28)


func _dent(c: Vector2, r: float, alpha: float) -> void:
	for j in 8:
		var f := 1.0 - j / 8.0
		_tray.draw_circle(c, r * f, Color(0, 0, 0, alpha / 8.0 * 1.6))


func _draw_flap() -> void:
	var s := _flap.size
	var c := s * 0.5
	if dark:
		# HUD.md §10: only a faint relief of the pause flap (~3:1 contrast against #000000)
		var rect := Rect2(Vector2(4, 4), s - Vector2(8, 8))
		_flap.draw_rect(rect, Color(0.06, 0.055, 0.05, 1.0), true)
		_flap.draw_rect(rect, Color(0.22, 0.20, 0.18, 1.0), false, 1.5)
		_flap.draw_arc(c, 7.5, 0.0, TAU, 24, Color(0.24, 0.22, 0.19, 1.0), 1.5)
		return
	if _tray_empty:
		var src := Rect2(Vector2(480, 70), Vector2(110, 110))
		_flap.draw_texture_rect_region(_tray_empty, Rect2(Vector2(4, 4), s - Vector2(8, 8)), src)
	_flap.draw_rect(Rect2(Vector2(4, s.y - 8), Vector2(s.x - 8, 4)), Color(0, 0, 0, 0.35))
	_flap.draw_circle(c, 9.0, Color(0.20, 0.15, 0.08))
	_flap.draw_circle(c, 7.5, Color(0.62, 0.50, 0.28))
	_flap.draw_circle(c + Vector2(-2, -2), 3.0, Color(0.80, 0.70, 0.45))


func _on_flap_input(ev: InputEvent) -> void:
	if (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed):
		accept_event()
		pause_requested.emit()
