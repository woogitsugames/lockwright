class_name LockPhotorealView
extends Control
## Photoreal lock screen view (plan B, D-31 accepted): the cutaway from art/blender/cutaway.py at the
## Cycles camera, rendered as
##   - static parts: the Cycles plate projected through the camera (plate.gdshader),
##   - plug and tension wrench: the plate projected from their rest pose, so they can turn a little
##     (plate_rest.gdshader),
##   - key pins, drivers, springs, pick: Cycles matcap + baked normal/AO (matcap.gdshader).
## Zero lights, zero probes. Diegetic HUD only (D-12, HUD.md): tension = wrench angle + plug face
## rotation, lives = picks in the leather roll, pause = a leather flap. No bars, no counters.
##
## Pure presentation: feed it with present(view_model, input) every physics step and with
## on_event(event) for each lockcore event. It never talks to the session itself.

signal pause_requested

const DIR := "res://assets/photoreal/"
const SCENE_JSON := DIR + "scene.json"
const GLB := DIR + "cutaway_baked.glb"
const PLATE := DIR + "plate/plate_1236x1650.png"
const TRAY_FULL := DIR + "tray/tray_full.png"
const TRAY_EMPTY := DIR + "tray/tray_empty.png"
const SECTION_ASPECT := 1236.0 / 1650.0  # width / height of the plate (3:4 Cycles frame)
const PINS_X := [5.0, 9.0, 13.0, 17.0, 21.0]
const STACK_NAMES := ["a", "b", "c", "d", "e"]
const PICK_REST_X := 13.0      # Blender hook rests under pin c
const PICK_REST_TIP := 2.2     # ... touching its key-pin tip (cz)
const PLUG_MAX_DEG := 12.0     # visible plug turn while picking (open turns further, see _plug_target)
const PLUG_PLAY_DEG := 1.2     # tension takes up the plug's play before anything sets
const WRENCH_MAX_DEG := 14.0   # HUD.md §3: wrench arm 0° → 14° for T 0 → 1
const PICK_BEND_MM := 0.45     # HUD.md §3: shaft bow at stress 1 (≈ 6 dp)
const SMOOTH_S := 0.06         # critically damped follow, no overshoot (DESIGN.md: 100–250 ms)
# Tray (art/blender/tray.py, 1080×960): pocket column boundaries as fractions of the image width.
const TRAY_COLUMNS := [0.0, 0.233, 0.503, 0.76]
const TRAY_POCKETS := 3
const FLAP_DP := 48.0

@export var lives := 3: set = set_lives
@export var dark := false: set = set_dark
@export_range(0.5, 3.0) var render_scale := 1.0  ## 3D pixels per physical pixel (1.0 = native)
@export_enum("Disabled", "2x", "4x") var msaa := 1

var viewport: SubViewport
var section_rect := Rect2()
var tray_rect := Rect2()

var _rig: Dictionary
var _model: Node3D
var _camera: Camera3D
var _section: TextureRect
var _tray: Control
var _bg: Control
var _flap: Control
var _tray_full: Texture2D
var _tray_empty: Texture2D
var _all_mats: Array[ShaderMaterial] = []
var _plate_mats: Array[ShaderMaterial] = []  # receive the pins' contact occlusion
var _occ := PackedVector4Array()
var _plug: Node3D
var _wrench: Node3D
var _pick: MeshInstance3D
var _pick_handle: Node3D
var _pick_mat: ShaderMaterial
var _rest := {}                       # Node3D -> Transform3D (Cycles pose)
var _stacks: Array[Dictionary] = []   # per chamber: key, driver, spool_driver, spring, spring lo/hi
var _key_len_mesh := 4.2
var _key_bottom_mesh := 1.2
var _drv_len := 4.0
var _spool_len := 4.4
var _active_stacks := 5
# smoothed presentation state
var _plug_deg := 0.0
var _wrench_deg := 0.0
var _pick_x := PICK_REST_X
var _pick_tip := PICK_REST_TIP
var _stress := 0.0
var _broken := false
var _opened := false
var _touches := {}                    # index -> {pos, start}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rig = JSON.parse_string(FileAccess.get_file_as_string(SCENE_JSON))
	_build_viewport()
	_build_model()
	_build_camera()
	_build_materials()
	_build_stacks()
	_build_overlay()
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_dark(dark)
	present({}, {})


# ------------------------------------------------------------------ public API
## Applies one lockcore ViewModel (LockcoreSession.describe() or FakeLockSession.describe()) and the
## sampled input ({tension, pick_depth, pick_lift}). Call once per physics step.
func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	var elements: Array = vm.get("elements", vm.get("pins", []))
	var default_target := PinPose.DEFAULT_TARGET
	if vm.has("pins"):  # FakeLockSession: set window is at the top of the travel
		default_target = 1.0
	var n := mini(elements.size(), _stacks.size())
	if elements.size() > 0 and n != _active_stacks:
		_set_active_stacks(n)
	var tension: float = float(vm.get("tension", input.get("tension", 0.0)))
	_stress = clampf(float(vm.get("stress", 0.0)), 0.0, 1.0)
	_opened = bool(vm.get("open", false)) or _opened
	var k := 1.0 - exp(-delta / SMOOTH_S)
	_plug_deg = lerpf(_plug_deg, _plug_target(vm, tension), k)
	_wrench_deg = lerpf(_wrench_deg, _plug_deg + WRENCH_MAX_DEG * clampf(tension, 0.0, 1.0), k)
	_apply_plug_and_wrench()
	_occ.resize(_stacks.size())
	for i in _stacks.size():
		_occ[i] = Vector4(PINS_X[i], 0.0, 0.0, 0.0)
	for i in n:
		_pose_stack(i, elements[i], default_target)
	for m in _plate_mats:
		m.set_shader_parameter("stacks", _occ)
	_pose_pick(vm, input, elements, default_target, k)


## One lockcore event ({kind, element, intensity, material}). Only events that change the picture
## without a ViewModel field are handled here; everything else is already in present().
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


## "In the dark" (HUD.md §10): the stair-light timer goes off; only sound and haptics remain.
func set_dark(on: bool) -> void:
	dark = on
	for m in _all_mats:
		m.set_shader_parameter("exposure", 0.06 if on else 1.0)
	if _tray:
		_tray.visible = not on
		_tray.queue_redraw()


## Thumb dent under a live touch (HUD.md §5.2). The InputSampler owns the input; this only draws.
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
	# The plate is display-referred (AgX in Cycles): pass it through untouched.
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.045, 0.04)
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


func _build_model() -> void:
	_model = (load(GLB) as PackedScene).instantiate()
	for c in _model.find_children("*", "Camera3D", true, false):
		c.get_parent().remove_child(c)
		c.free()
	viewport.add_child(_model)
	for n in _model.find_children("*", "Node3D", true, false):
		_rest[n] = n.transform  # the glTF root is at the origin: local == world
	_plug = _model.find_child("plug", true, false)
	_wrench = _model.find_child("wrench", true, false)
	_pick = _model.find_child("pick", true, false)
	_pick_handle = _model.find_child("pick_handle", true, false)


func _build_camera() -> void:
	var c: Dictionary = _rig["camera"]
	_camera = Camera3D.new()
	# Blender sensor_fit HORIZONTAL: fixed horizontal FOV. The section viewport always has the plate's
	# aspect, so derive the vertical FOV once and keep the height.
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(c["hfov_deg"]) * 0.5) / SECTION_ASPECT))
	_camera.near = 20.0
	_camera.far = 1000.0
	viewport.add_child(_camera)
	var p: Array = c["position"]
	var t: Array = c["target"]
	_camera.look_at_from_position(Vector3(p[0], p[1], p[2]), Vector3(t[0], t[1], t[2]), Vector3.UP)
	_camera.current = true


func _tex(path: String) -> Texture2D:
	return load(path) if ResourceLoader.exists(path) else null


func _mat(shader: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/photoreal/" + shader)
	_all_mats.append(m)
	return m


func _matcap_mat(mname: String) -> ShaderMaterial:
	var m := _mat("matcap.gdshader")
	m.set_shader_parameter("matcap", _tex(DIR + "matcap/matcap_%s.png" % mname))
	m.set_shader_parameter("normal_map", _tex(DIR + "tex/%s_normal.png" % mname))
	m.set_shader_parameter("orm", _tex(DIR + "tex/%s_orm.png" % mname))
	return m


func _is_moving(node_name: String) -> bool:
	if node_name in ["pick", "pick_handle"]:
		return true
	var parts := node_name.split("_")
	return parts.size() == 2 and STACK_NAMES.has(parts[0]) and parts[1] in ["key", "drv", "spr"]


func _build_materials() -> void:
	var plate := _tex(PLATE)
	var static_mat := _mat("plate.gdshader")
	static_mat.set_shader_parameter("plate", plate)
	_plate_mats.append(static_mat)
	var matcaps := {}
	for mi: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		var nm := String(mi.name)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var override: Material = static_mat
		if nm == "plug" or nm == "wrench":
			var r := _mat("plate_rest.gdshader")
			r.set_shader_parameter("plate", plate)
			r.set_shader_parameter("rest_model", Projection(_rest[mi]))
			_plate_mats.append(r)
			override = r
		elif _is_moving(nm):
			var src := mi.mesh.surface_get_material(0)
			var mname := src.resource_name if src else "steel"
			if nm == "pick":
				_pick_mat = _matcap_mat("pick")
				override = _pick_mat
			else:
				if not matcaps.has(mname):
					matcaps[mname] = _matcap_mat(mname)
				override = matcaps[mname]
		mi.material_override = override


func _build_stacks() -> void:
	# One uniform key pin (e_key) and driver (e_drv) per chamber, rescaled/placed from the lock state;
	# the spool driver (b_drv) for spool variants. Springs keep their own meshes and get squeezed.
	var e_key := _model.find_child("e_key", true, false) as MeshInstance3D
	var e_drv := _model.find_child("e_drv", true, false) as MeshInstance3D
	var b_drv := _model.find_child("b_drv", true, false) as MeshInstance3D
	var kbb := e_key.get_aabb()
	_key_len_mesh = kbb.size.y
	_key_bottom_mesh = kbb.position.y
	var dbb := e_drv.get_aabb()
	_drv_len = dbb.size.y
	var sbb := b_drv.get_aabb()
	_spool_len = sbb.size.y
	for i in STACK_NAMES.size():
		var s: String = STACK_NAMES[i]
		for k in ["key", "drv"]:
			var orig := _model.find_child("%s_%s" % [s, k], true, false) as Node3D
			if orig:
				orig.visible = false
		var key := _clone(e_key, "%s_key_live" % s)
		var drv := _clone(e_drv, "%s_drv_live" % s)
		var spool := _clone(b_drv, "%s_spool_live" % s)
		spool.visible = false
		var spr := _model.find_child("%s_spr" % s, true, false) as MeshInstance3D
		var lo := 0.0
		var hi := PinPose.CAP_UNDERSIDE
		if spr:
			var bb := spr.get_aabb()
			lo = bb.position.y
			hi = bb.end.y
		_stacks.append({
			"x": float(PINS_X[i]), "key": key, "drv": drv, "spool": spool, "spr": spr,
			"spr_lo": lo, "spr_hi": hi,
			"key_x0": kbb.get_center().x, "drv_x0": dbb.get_center().x, "drv_bottom0": dbb.position.y,
			"spool_x0": sbb.get_center().x, "spool_bottom0": sbb.position.y,
		})


func _clone(src: MeshInstance3D, nm: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = nm
	m.mesh = src.mesh
	m.material_override = src.material_override
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_model.add_child(m)
	return m


func _set_active_stacks(n: int) -> void:
	# Fewer pins than chambers (t2: 3, t3: 4): the remaining chambers stay drilled but unpinned.
	# More (t6–t7): only five chambers exist in the model; extra elements are not drawn (log note).
	_active_stacks = n
	for i in _stacks.size():
		var on := i < n
		for k in ["key", "drv"]:
			(_stacks[i][k] as Node3D).visible = on
		if not on:
			(_stacks[i]["spool"] as Node3D).visible = false
		if _stacks[i]["spr"]:
			(_stacks[i]["spr"] as Node3D).visible = on


func _build_overlay() -> void:
	_tray_full = _tex(TRAY_FULL)
	_tray_empty = _tex(TRAY_EMPTY)
	if _tray_full == null:
		_tray_full = _tray_empty
	# Backdrop: the roll's bare leather, out of the light (visible beside the section in landscape).
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
		# Portrait (HUD.md §11.1): the section fills the width at the top (under the notch too), the
		# roll takes the rest; the section never takes more than 72% of the safe height.
		var h := minf(r.size.x / SECTION_ASPECT, safe.size.y * 0.72)
		section_rect = Rect2(r.position, Vector2(r.size.x, safe.position.y - r.position.y + h))
		tray_rect = Rect2(Vector2(r.position.x, section_rect.end.y), Vector2(r.size.x, r.end.y - section_rect.end.y))
	else:
		# Landscape (HUD.md §11.2): section in the middle, roll under it, thumb zones at the sides.
		var th := r.size.y * 0.26
		var sh := r.size.y - th
		var sw := sh * SECTION_ASPECT
		section_rect = Rect2(Vector2(r.position.x + (r.size.x - sw) * 0.5, r.position.y), Vector2(sw, sh))
		tray_rect = Rect2(Vector2(section_rect.position.x - sw * 0.25, section_rect.end.y), Vector2(sw * 1.5, th))
	# Keep the plate's aspect: crop (cover) rather than stretch.
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


# ------------------------------------------------------------------ pose
func _plug_target(vm: Dictionary, tension: float) -> float:
	var rot := clampf(float(vm.get("core_rotation", 0.0)), 0.0, 1.0)
	if _opened:
		return 90.0 * maxf(rot, 1.0) * 0.25 + PLUG_MAX_DEG  # open: keeps turning (limited by the plate)
	return minf(rot * 90.0, PLUG_MAX_DEG) + PLUG_PLAY_DEG * clampf(tension, 0.0, 1.0)


func _plug_basis(deg: float) -> Basis:
	# The plug axis is Blender X through the origin (Godot X). Positive = clockwise seen from the front.
	return Basis(Vector3.RIGHT, deg_to_rad(-deg))


func _apply_plug_and_wrench() -> void:
	if _plug:
		_plug.transform = Transform3D(_plug_basis(_plug_deg), Vector3.ZERO) * _rest[_plug]
	if _wrench:
		_wrench.transform = Transform3D(_plug_basis(_wrench_deg), Vector3.ZERO) * _rest[_wrench]


func _pose_stack(i: int, el: Dictionary, default_target: float) -> void:
	var st: Dictionary = _stacks[i]
	var pose := PinPose.pose(el, default_target, _drv_len)
	var plug := Transform3D(_plug_basis(_plug_deg), Vector3.ZERO)
	# key pin: e_key mesh, scaled about its tip to the cut length, moved under chamber i; turns with the plug
	var s: float = pose["key_len"] / _key_len_mesh
	var key_t := Transform3D(Basis.from_scale(Vector3(1, s, 1)), Vector3.ZERO)
	key_t.origin = Vector3(st["x"] - st["key_x0"], pose["key_bottom"] - _key_bottom_mesh * s, 0.0)
	(st["key"] as Node3D).transform = plug * key_t
	# driver (plain or spool), tilted against the chamber wall while binding
	var spool: bool = pose["spool"]
	var drv: Node3D = st["spool"] if spool else st["drv"]
	(st["spool"] as Node3D).visible = spool
	(st["drv"] as Node3D).visible = not spool
	var x0: float = st["spool_x0"] if spool else st["drv_x0"]
	var b0: float = st["spool_bottom0"] if spool else st["drv_bottom0"]
	var dlen: float = _spool_len if spool else _drv_len
	var pivot := Vector3(st["x"], pose["driver_bottom"], 0.0)
	var tilt := Transform3D(Basis(Vector3.BACK, deg_to_rad(pose["tilt_deg"])), Vector3.ZERO)
	var place := Transform3D(Basis.IDENTITY, Vector3(st["x"] - x0, pose["driver_bottom"] - b0, 0.0))
	drv.transform = Transform3D(Basis.IDENTITY, pivot) * tilt * Transform3D(Basis.IDENTITY, -pivot) * place
	_occ[i] = Vector4(st["x"], pose["key_bottom"], pose["driver_bottom"] + dlen, 1.0)
	# spring: squeezed between the driver top and the cap
	var spr: MeshInstance3D = st["spr"]
	if spr:
		var lo: float = st["spr_lo"]
		var hi: float = st["spr_hi"]
		var bottom: float = pose["driver_bottom"] + dlen
		var k := clampf((hi - bottom) / maxf(hi - lo, 0.01), 0.05, 2.0)
		spr.transform = Transform3D(Basis.from_scale(Vector3(1, k, 1)), Vector3(0, hi * (1.0 - k), 0)) * _rest[spr]


func _pose_pick(vm: Dictionary, input: Dictionary, elements: Array, default_target: float, k: float) -> void:
	if _pick == null:
		return
	var n := maxi(_active_stacks, 1)
	var depth := clampf(float(input.get("pick_depth", 0.5)), 0.0, 1.0)
	var lift := float(input.get("pick_lift", 0.0))
	var idx := int(vm.get("pick_element", -1))
	var x: float
	if idx >= 0 and idx < n:
		x = PINS_X[idx]
	else:
		# between stacks: follow depth along the chambers in use
		x = lerpf(PINS_X[0] - 2.0, PINS_X[n - 1] + 2.0, depth)
		idx = clampi(int(round((x - PINS_X[0]) / 4.0)), 0, n - 1)
	var tip := PinPose.REST_BOTTOM + minf(lift, 0.0) * 0.8
	if idx < elements.size():
		var pose := PinPose.pose(elements[idx], default_target, _drv_len)
		if absf(x - PINS_X[idx]) < 1.2:
			tip = maxf(tip, float(pose["key_bottom"])) if lift > 0.02 else minf(float(pose["key_bottom"]), tip + 0.6)
	_pick_x = lerpf(_pick_x, x, k)
	_pick_tip = lerpf(_pick_tip, tip, k)
	var off := Vector3(_pick_x - PICK_REST_X, _pick_tip - PICK_REST_TIP, 0.0)
	if _broken:
		off.y -= 0.6  # snapped: the handle drops away (HUD.md §3 "break")
	var plug := Transform3D(_plug_basis(_plug_deg * 0.5), Vector3.ZERO)
	_pick.transform = plug * Transform3D(Basis.IDENTITY, off) * _rest[_pick]
	if _pick_handle:
		_pick_handle.transform = plug * Transform3D(Basis.IDENTITY, off) * _rest[_pick_handle]
	var shake := 0.0
	if _stress >= 0.9:
		shake = 0.04 * sin(Time.get_ticks_msec() * 0.09)  # ≈ 1 dp tremor near breaking (HUD.md §3)
	if _pick_mat:
		_pick_mat.set_shader_parameter("bend", PICK_BEND_MM * _stress + shake)


# ------------------------------------------------------------------ 2D: leather roll, flap, thumb dents
func _draw_tray() -> void:
	if _tray_full == null:
		_tray.draw_rect(Rect2(Vector2.ZERO, _tray.size), Color(0.18, 0.12, 0.08))
		return
	# cover-fit the 1080×960 roll render into the tray rect, then draw each pocket column from the
	# "full" or "empty" render (same light, same camera, so the seams do not show).
	var img := Vector2(_tray_full.get_size())
	var sz := _tray.size
	var sc := maxf(sz.x / img.x, sz.y / img.y)
	var shown := sz / sc               # image pixels visible
	var origin := (img - shown) * 0.5  # top-left of the visible image region
	origin.y = 0.0                     # keep the pockets' top edge (picks) right under the section
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
	# soft contact shadow where the roll meets the section edge (no line, no glow)
	for j in 6:
		_tray.draw_rect(Rect2(0, j * 2.0, sz.x, 2.0), Color(0, 0, 0, 0.22 * (1.0 - j / 6.0)))
	# thumb dents (HUD.md §5.2): soft darker hollow under each live thumb + faint reference mark
	for t in _touches.values():
		var p: Vector2 = t["pos"] - _tray.position
		var s: Vector2 = t["start"] - _tray.position
		_dent(s, 20.0, 0.10)
		_dent(p, 28.0, 0.28)


func _draw_bg() -> void:
	var sz := _bg.size
	if _tray_empty == null:
		_bg.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.12, 0.08, 0.055))
		return
	# bare leather band above the pockets of the "empty" roll render, cover-fitted
	var src := Rect2(Vector2(0, 0), Vector2(_tray_empty.get_width(), _tray_empty.get_height() * 0.3))
	var sc := maxf(sz.x / src.size.x, sz.y / src.size.y)
	var shown := sz / sc
	src = Rect2(src.position + (src.size - shown) * 0.5, shown)
	_bg.draw_texture_rect_region(_tray_empty, Rect2(Vector2.ZERO, sz), src, Color(0.6, 0.6, 0.6))


func _dent(c: Vector2, r: float, alpha: float) -> void:
	for j in 8:
		var f := 1.0 - j / 8.0
		_tray.draw_circle(c, r * f, Color(0, 0, 0, alpha / 8.0 * 1.6))


func _draw_flap() -> void:
	# Leather flap of the roll with a brass snap: cut from the roll render, no "II" icon (HUD.md §6).
	var s := _flap.size
	if _tray_full:
		var src := Rect2(Vector2(560, 300), Vector2(120, 120))
		_flap.draw_texture_rect_region(_tray_full, Rect2(Vector2(4, 4), s - Vector2(8, 8)), src)
	_flap.draw_rect(Rect2(Vector2(4, s.y - 8), Vector2(s.x - 8, 4)), Color(0, 0, 0, 0.35))
	var c := s * 0.5
	_flap.draw_circle(c, 9.0, Color(0.20, 0.15, 0.08))
	_flap.draw_circle(c, 7.5, Color(0.62, 0.50, 0.28))
	_flap.draw_circle(c + Vector2(-2, -2), 3.0, Color(0.80, 0.70, 0.45))


func _on_flap_input(ev: InputEvent) -> void:
	if (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed):
		accept_event()
		pause_requested.emit()
