class_name LockLiftLayerView
extends LockPhotorealView
## D-59: plan-B screens for the lift-based families added in lockcore v0.6 that have their own
## mechanism picture (egyptian pegs, time-lock wheels, axial sliders). Built like the dial safe screen:
## Cycles layers (art/blender/plates/<family>_plate.py with layer_plate_common.py) composed in the
## section SubViewport, which is sized to the on-screen pixels (N-65). Each element is a layer rendered
## in its SET pose; it is moved along the family's travel vector by (position - window centre), so at
## its own gate it sits exactly on the shear line, below it short, above it over. The tool layer follows
## the picked element (or the thumb between elements); the progress layer (bolt, hand) follows
## hold_progress / core_rotation. Contact shadows are 2D, as on the dial safe screen.
## States by geometry: free = resting low; bound = leaning a little on its channel; near = just under
## the line; set = on the line (chalk ledge when chalk is on); overset = past the line and wedged
## (tilted); open = progress layer thrown.

@export var asset_dir := "res://assets/photoreal_families/egyptian/photo/"
@export var element_layer := "peg"
@export var tool_layer := "lifter"
@export var progress_layer := "bolt"
@export var bind_tilt_deg := 1.5
@export var over_tilt_deg := 5.0

var meta := {}
var plate_size := Vector2(618, 824)
var n_el := 0
var first_slot := 0
var hint := ""
var _layers := {}
var _canvas: Node2D
var _off: Array[float] = []      # smoothed element offset from its set pose, in position units
var _tilt: Array[float] = []
var _tool_at := Vector2.ZERO     # plate px of the tool tip
var _progress := 0.0
var _moved := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if FileAccess.file_exists(asset_dir + "layers.json"):
		meta = JSON.parse_string(FileAccess.get_file_as_string(asset_dir + "layers.json"))
	var res: Array = meta.get("res", [618, 824])
	plate_size = Vector2(res[0], res[1])
	_build_viewport()
	_canvas = Node2D.new()
	_canvas.name = "LiftLayers"
	_canvas.draw.connect(_draw_section)
	viewport.add_child(_canvas)
	for nm in meta.get("layers", {}).keys():
		_layers[nm] = _tex(asset_dir + String(nm) + ".png")
	for i in slot_count():
		_off.append(0.0)
		_tilt.append(0.0)
	_build_overlay()
	_active_stacks = 1
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_dark(dark)
	present({}, {})


func slot_count() -> int:
	return maxi((meta.get("slots_px", []) as Array).size(), 1)


func slot_of(i: int) -> int:
	return clampi(first_slot + i, 0, slot_count() - 1)


func anchor(slot: int) -> Vector2:
	var a: Array = meta.get("slots_px", [[plate_size.x * 0.5, plate_size.y * 0.5]])
	var p: Array = a[clampi(slot, 0, a.size() - 1)]
	return Vector2(p[0], p[1])


func travel() -> Vector2:
	var t: Array = meta.get("travel_px", [0.0, -50.0])
	return Vector2(t[0], t[1])


func _layer_pos(nm: String) -> Vector2:
	var o: Array = meta.get("layers", {}).get(nm, {}).get("offset", [0, 0])
	return Vector2(o[0], o[1])


func set_hint(s: String) -> void:
	hint = s


func plate_to_screen(p: Vector2) -> Vector2:
	var disp := _section_display()
	return disp.position + p / plate_size * disp.size


## Element i's anchor point on screen in its current pose (tests, chalk, loupe).
func element_screen(i: int) -> Vector2:
	var s := slot_of(i)
	return plate_to_screen(anchor(s) + travel() * _off[s])


func element_offset(i: int) -> float:
	return _off[slot_of(i)]


func element_tilt(i: int) -> float:
	return _tilt[slot_of(i)]


func progress() -> float:
	return _progress


func tool_tip_screen() -> Vector2:
	return plate_to_screen(_tool_at)


# ------------------------------------------------------------------ public API
func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	var els: Array = vm.get("elements", [])
	var n := mini(els.size(), slot_count())
	if n != n_el:
		n_el = n
		first_slot = int((slot_count() - n) / 2.0) if n > 0 else 0
	var k := 1.0 - exp(-delta / SMOOTH_S)
	var snap := delta >= 0.5
	_opened = bool(vm.get("open", false)) or _opened
	_stress = clampf(float(vm.get("stress", 0.0)), 0.0, 1.0)
	var tension := float(vm.get("tension", input.get("tension", 0.0)))
	if absf(float(input.get("pick_lift", 0.0))) > 0.02:
		_moved = true
	for i in n:
		var e: Dictionary = els[i]
		var s := slot_of(i)
		var target := (float(e.get("window_lo", 0.5)) + float(e.get("window_hi", 0.6))) * 0.5
		var pos := float(e.get("position", 0.0))
		var st := String(e.get("state", "free"))
		var off := pos - target
		if st == "set":
			off = 0.0
		var tilt := 0.0
		match st:
			"bound", "near":
				tilt = bind_tilt_deg
			"overset", "jammed":
				tilt = over_tilt_deg
		_off[s] = off if snap else lerpf(_off[s], off, k)
		_tilt[s] = tilt if snap else lerpf(_tilt[s], tilt, k)
	var prog := 1.0 if _opened else clampf(float(vm.get("hold_progress", 0.0)), 0.0, 1.0)
	_progress = prog if snap else lerpf(_progress, prog, k)
	# tool: under the picked element (its anchor in the current pose), else between elements by depth
	var idx := int(vm.get("pick_element", -1))
	var tip: Vector2
	var lift := float(input.get("pick_lift", 0.0))
	if idx >= 0 and idx < n:
		var s2 := slot_of(idx)
		tip = anchor(s2) + travel() * (_off[s2] if lift > 0.02 else minf(_off[s2], -0.6 + lift))
	elif n > 0:
		var depth := clampf(float(input.get("pick_depth", 0.5)), 0.0, 1.0)
		var a := anchor(slot_of(0))
		var b := anchor(slot_of(n - 1))
		tip = a.lerp(b, depth) + travel() * (-0.6 + maxf(lift, 0.0))
	else:
		tip = anchor(0) + travel() * -0.6
	_tool_at = tip if snap else _tool_at.lerp(tip, k)
	_last_vm = vm
	_last_input = input
	_canvas.queue_redraw()
	_update_l_face(tension, float(vm.get("tension_resistance", 0.0)), delta)
	_update_l_chalk(els, delta)
	_update_l_eyepiece(vm, delta)


func on_event(e: Dictionary) -> void:
	match StringName(e.get("kind", &"")):
		&"break":
			_broken = true
			if lives > 0:
				set_lives(lives - 1)
		&"open":
			_opened = true
		&"set":
			_set_flash = 1.0


# ------------------------------------------------------------------ drawing
func _vs() -> float:
	return float(viewport.size.x) / plate_size.x


func _draw_layer(nm: String, xf: Transform2D, shadow: float = 0.42) -> void:
	var tex: Texture2D = _layers.get(nm)
	if tex == null:
		return
	var at := _layer_pos(nm)
	var s := _vs()
	var sh := Vector2(0.5, 0.75) * float(meta.get("ppm", 8.0))
	if shadow > 0.0 and not dark:
		for j in 2:
			_canvas.draw_set_transform_matrix(Transform2D().scaled(Vector2(s, s)) * Transform2D(0.0, sh * (1.0 + 0.8 * j)) * xf)
			_canvas.draw_texture(tex, at, Color(0, 0, 0, shadow * (0.6 if j == 0 else 0.35)))
	_canvas.draw_set_transform_matrix(Transform2D().scaled(Vector2(s, s)) * xf)
	_canvas.draw_texture(tex, at)


func _rot_about(deg: float, p: Vector2) -> Transform2D:
	return Transform2D(0.0, p) * Transform2D(deg_to_rad(deg), Vector2.ZERO) * Transform2D(0.0, -p)


## Element i's transform (plate px): moved along the travel, leaning about its anchor.
func _element_xf(slot: int) -> Transform2D:
	var a := anchor(slot)
	var d := travel() * _off[slot]
	if element_layer_per_slot():
		return Transform2D(0.0, d) * _rot_about(_tilt[slot], a)
	var a0 := anchor(0)  # one layer rendered at slot 0, moved to every slot
	return Transform2D(0.0, d + (a - a0)) * _rot_about(_tilt[slot], a0)


## true: one layer per slot (peg0, peg1, …); false: one layer moved to every slot.
func element_layer_per_slot() -> bool:
	return _layers.has(element_layer + "1")


func _draw_section() -> void:
	var s := _vs()
	_canvas.draw_set_transform_matrix(Transform2D().scaled(Vector2(s, s)))
	var plate: Texture2D = _layers.get("plate")
	if plate != null:
		_canvas.draw_texture_rect(plate, Rect2(Vector2.ZERO, plate_size), false)
	if not _last_vm.is_empty():
		_draw_progress_layer()
		_draw_elements()
		_draw_extra_back()
		var tp: Array = meta.get(tool_layer + "_tip_px", [0.0, 0.0])
		if tool_layer != "" and _layers.has(tool_layer):
			var d := _tool_at - Vector2(tp[0], tp[1])
			if _broken:
				d.y += 4.0
			_draw_layer(tool_layer, Transform2D(0.0, d), 0.4)
	_draw_layer("front", Transform2D.IDENTITY, 0.5)
	_draw_extra_front()
	_canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
	if dark:
		_canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(viewport.size)), Color(0, 0, 0, 0.985))


func _draw_progress_layer() -> void:
	if progress_layer == "":
		return
	var v: Array = meta.get(progress_layer + "_open_px", [0.0, 0.0])
	_draw_layer(progress_layer, Transform2D(0.0, Vector2(v[0], v[1]) * _progress), 0.45)


func _draw_elements() -> void:
	for i in n_el:
		var slot := slot_of(i)
		var nm := element_layer + (str(slot) if element_layer_per_slot() else "")
		_draw_layer(nm, _element_xf(slot), 0.45)


## Family hooks (time lock: the train; axial slider: the locking plate).
func _draw_extra_back() -> void:
	pass


func _draw_extra_front() -> void:
	pass


# ------------------------------------------------------------------ dark, face, chalk, loupe
func set_dark(on: bool) -> void:
	super.set_dark(on)
	if _canvas:
		_canvas.queue_redraw()


func _update_l_face(tension: float, res: float, delta: float) -> void:
	if _face == null:
		return
	var t := clampf(tension, 0.0, 1.0)
	_set_flash = maxf(_set_flash - delta / 0.2, 0.0)
	var k := 1.0 - exp(-delta / SMOOTH_S)
	var face := 90.0 * _progress + _set_flash * 1.5
	_face.face_deg = lerpf(_face.face_deg, face, k)
	_face.arm_deg = lerpf(_face.arm_deg, face + PlugFace.ARM_MAX_DEG * t, k)
	_face.bow = clampf(res, 0.0, 1.0)
	_face.tremor = clampf((_stress - 0.6) / 0.4, 0.0, 1.0)
	_face.tension = t
	_face.gauge = chalk_gauge and chalk_level != ChalkLayer.Level.OFF
	_face.opened = _opened
	_face.queue_redraw()


func _update_l_chalk(els: Array, delta: float) -> void:
	if _chalk == null:
		return
	_chalk.level = chalk_level
	if chalk_level == ChalkLayer.Level.OFF or _last_vm.is_empty():
		_chalk.marks = {}
		_chalk.text = ""
		_chalk.tick(delta)
		return
	var m := {}
	var sh: Array = meta.get("shear_px", [])
	if sh.size() == 2:
		m["shear"] = [plate_to_screen(Vector2(sh[0][0], sh[0][1])), plate_to_screen(Vector2(sh[1][0], sh[1][1]))]
	var stacks := []
	var w := float(meta.get("ppm", 8.0)) * 3.0 * section_rect.size.x / plate_size.x
	for i in n_el:
		var a := plate_to_screen(anchor(slot_of(i)))
		stacks.append({"x": a.x, "shear_y": a.y, "top_y": a.y - w * 4.0, "w": w, "state": String(els[i].get("state", "free"))})
	m["stacks"] = stacks
	var r := get_rect()
	var safe := _safe_rect(r)
	var portrait := safe.size.y >= safe.size.x
	var thumbs_y := tray_rect.position.y + tray_rect.size.y * (0.66 if portrait else 0.5)
	m["left_anchor"] = Vector2(r.size.x * (0.22 if portrait else 0.12), thumbs_y)
	m["right_anchor"] = Vector2(r.size.x * (0.70 if portrait else 0.88), thumbs_y)
	m["hint_left"] = not chalk_gauge and float(_last_vm.get("tension", 0.0)) < 0.1
	m["hint_right"] = not _moved
	m["text_rect"] = Rect2(Vector2(safe.position.x + 16.0, safe.position.y + 10.0), Vector2(safe.size.x - FLAP_DP - 48.0, 72.0))
	if not portrait:
		m["text_rect"] = Rect2(Vector2(section_rect.end.x + 16.0, safe.position.y + 16.0), Vector2(safe.end.x - section_rect.end.x - 32.0, 160.0))
	var any_set := false
	for e in els:
		any_set = any_set or String(e.get("state", "")) == "set"
	_chalk.marks = m
	_chalk.text = hint if not any_set and not _opened else ""
	_chalk.tick(delta)


func _update_l_eyepiece(vm: Dictionary, delta: float) -> void:
	if _eyepiece == null:
		return
	_eyepiece.tick(delta)
	if not _eyepiece.visible:
		return
	var idx := clampi(int(vm.get("pick_element", 0)), 0, maxi(n_el - 1, 0))
	var focus := element_screen(idx)
	var ed := _eyepiece.size.x
	var r := get_rect()
	var pos := focus - Vector2(ed, ed) * 0.5
	pos.x = clampf(pos.x, 8.0, r.size.x - ed - 8.0)
	pos.y = clampf(pos.y, 8.0, r.size.y - ed - 8.0)
	_eyepiece.position = pos
	var disp := _section_display()
	var uv := (focus - disp.position) / disp.size
	var half := Vector2(ed * 0.5 / Eyepiece.ZOOM, ed * 0.5 / Eyepiece.ZOOM) / disp.size
	_eyepiece.aim(viewport.get_texture(), uv, half)
