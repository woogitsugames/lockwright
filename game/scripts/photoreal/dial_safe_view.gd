class_name LockDialSafeView
extends LockPhotorealView
## D-59: plan-B lock screen for the dial safe (LOCKS.md §2.18), same method as the pin and warded
## screens, built from Cycles layers (art/blender/plates/dial_safe_plate.py, photo materials):
##   the door is cut away round the dial; behind it a pack of 2–4 wheels of stepped diameter (wheel 0
##   farthest from the dial and largest), so every rim shows. A fence bar above the pack carries one
##   sprung feeler per wheel; each feeler rests on its own rim and drops into that wheel's gate
##   notch. With every wheel in its gate, the dial on the mark and the handle pressed, the fence bar
##   drops, its stud clears the bolt notch and the bolt is drawn back.
## The camera looks down the spindle, so every turning part turns in the picture plane: the layers
## are drawn into the section SubViewport (sized to the on-screen pixels, N-65) with exact 2D
## rotations about the spindle point. Contact shadows are added in 2D (a layer never carries a
## shadow of another part round with it).
## States by geometry (greyscale): handle let go = the whole fence lifted off the rims (a gap);
## listening = feelers on the rims; near / gate = the feeler sinks into the passing notch; set =
## the wheel stopped with its feeler down in the notch; false notch = feeler half down in a shallow
## notch; clamped (handle too hard) = fence pressed, dial shaking; open = fence dropped, bolt back.
## HUD as everywhere: the plug face shows the handle (arm = pressure, turns when the bolt goes
## back), picks in the roll, leather flap, loupe.

const D_DIR := "res://assets/photoreal_families/dial_safe/photo/"
const META := D_DIR + "layers.json"
const LIFT_MM := 1.3          # handle let go: the fence and feelers rise off the rims
const CLAMP_MM := 0.35        # handle too hard: the fence presses down
const FALSE_DIP_MM := 1.0     # a feeler in a shallow false notch
const NOTCH_HALF_MM := 2.1    # gate notch half width at the rim (plate script NOTCH_W / 2)
const FEELER_HALF_MM := 1.3   # feeler half width (FW / 2)
const SHADOW_MM := Vector2(0.55, 0.8)  # 2D contact shadow (key light from the top left)

var meta := {}
var plate_size := Vector2(618, 824)
var n_wheels := 0
var divisions := 20
var hint := ""                 # first jobs: one chalk line (set by the lock scene)
var _layers := {}              # name -> Texture2D
var _canvas: Node2D
var _spindle := Vector2.ZERO
var _wheel_rot: Array[float] = [0.0, 0.0, 0.0, 0.0]   # radians, clockwise
var _feeler_dip: Array[float] = [0.0, 0.0, 0.0, 0.0]  # mm below the rest pose (rim contact)
var _false_marks: Array = [[], [], [], []]            # per wheel: positions of discovered false notches
var _gate: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _win: Array[float] = [0.1, 0.1, 0.1, 0.1]
var _fence_dy := 0.0          # mm, + = down
var _bolt_dx := 0.0           # mm, + = drawn back (left)
var _dial_rot := 0.0
var _jam := 0.0
var _handle := 0.0            # PlugFace turn when the bolt goes back
var _moved := false           # the dial has been turned (chalk hint goes)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if FileAccess.file_exists(META):
		meta = JSON.parse_string(FileAccess.get_file_as_string(META))
	var res: Array = meta.get("res", [618, 824])
	plate_size = Vector2(res[0], res[1])
	var sp: Array = meta.get("spindle_px", [plate_size.x * 0.5, plate_size.y * 0.5])
	_spindle = Vector2(sp[0], sp[1])
	_build_viewport()
	_canvas = Node2D.new()
	_canvas.name = "DialSafeCanvas"
	_canvas.draw.connect(_draw_section)
	viewport.add_child(_canvas)
	for nm in ["plate", "front", "fence", "bolt", "wheel0", "wheel1", "wheel2", "wheel3",
			"feeler0", "feeler1", "feeler2", "feeler3", "dial20", "dial30", "dial40"]:
		_layers[nm] = _tex(D_DIR + nm + ".png")
	_build_overlay()
	_active_stacks = 1
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_dark(dark)
	present({}, {})


# ------------------------------------------------------------------ geometry helpers
func _wheel_meta(k: int) -> Dictionary:
	var w: Array = meta.get("wheels", [])
	return w[k] if k < w.size() else {"radius_mm": 43.0 - 6.0 * k, "px_per_mm": 3.6, "notch_angle_deg": 0.0}


func _feeler_meta(k: int) -> Dictionary:
	var f: Array = meta.get("feelers", [])
	return f[k] if k < f.size() else {"tip_px": [plate_size.x * 0.5, plate_size.y * 0.3], "px_per_mm": 3.6}


func _layer_pos(nm: String) -> Vector2:
	var l: Dictionary = meta.get("layers", {}).get(nm, {})
	var o: Array = l.get("offset", [0, 0])
	return Vector2(o[0], o[1])


## Signed turn from a to b, wrapped to [-0.5, 0.5).
static func wrap_half(d: float) -> float:
	return fposmod(d + 0.5, 1.0) - 0.5


## Display offset of a wheel from its gate (turns). Inside the gate window the wheel is drawn
## within the notch clearance (lockcore counts the whole window as "in the gate"; a 1:1 picture
## would show the notch beside the feeler); outside, the rest of the turn is stretched so the
## mapping stays continuous all the way round.
func display_offset(k: int, pos: float) -> float:
	var d := wrap_half(pos - _gate[k])
	var w := maxf(_win[k] * 0.5, 0.001)
	var r_mm := float(_wheel_meta(k)["radius_mm"])
	var c := clampf((NOTCH_HALF_MM - FEELER_HALF_MM) / (w * TAU * r_mm), 0.02, 1.0)
	var a := absf(d)
	var out := c * minf(a, w)
	if a > w:
		out += (a - w) * (0.5 - c * w) / maxf(0.5 - w, 0.001)
	return signf(d) * out


## Feeler depth (mm) for a notch passing under it: full inside the clearance, none once the
## notch is a feeler width away.
static func notch_dip(off_mm: float, depth_mm: float) -> float:
	var a := absf(off_mm)
	var full := NOTCH_HALF_MM - FEELER_HALF_MM
	var none := NOTCH_HALF_MM + FEELER_HALF_MM
	return depth_mm * clampf((none - a) / (none - full), 0.0, 1.0)


func wheel_rot(k: int) -> float:
	return _wheel_rot[k]


func feeler_dip(k: int) -> float:
	return _feeler_dip[k]


func fence_dy() -> float:
	return _fence_dy


func bolt_dx() -> float:
	return _bolt_dx


func dial_rot() -> float:
	return _dial_rot


func set_hint(s: String) -> void:
	hint = s


## Section point (plate pixels) → view coordinates.
func plate_to_screen(p: Vector2) -> Vector2:
	var disp := _section_display()
	return disp.position + p / plate_size * disp.size


## Screen point of wheel k's feeler tip (tests, chalk, loupe).
func feeler_tip_screen(k: int) -> Vector2:
	var fm := _feeler_meta(k)
	var tp: Array = fm["tip_px"]
	return plate_to_screen(Vector2(tp[0], tp[1] + (_feeler_dip[k] + _fence_dy) * float(fm["px_per_mm"])))


# ------------------------------------------------------------------ public API
func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	var els: Array = vm.get("elements", [])
	n_wheels = mini(els.size(), 4)
	divisions = int(vm.get("dial_divisions", divisions)) if int(vm.get("dial_divisions", 0)) > 0 else divisions
	var k := 1.0 - exp(-delta / SMOOTH_S)
	var tension := float(vm.get("tension", input.get("tension", 0.0)))
	var res := float(vm.get("tension_resistance", 0.0))
	_opened = bool(vm.get("open", false)) or _opened
	var hold := 1.0 if _opened else clampf(float(vm.get("hold_progress", vm.get("core_rotation", 0.0))), 0.0, 1.0)
	var jammed := false
	for e in els:
		if String(e.get("state", "")) == "jammed":
			jammed = true
	# the handle presses the fence onto the wheels once lockcore stops reading it as "let go" (T / 4)
	var pressed := tension > 0.02 and res > tension * 0.3
	var fence_down := hold > 0.0 or _opened
	var dial := float(vm.get("dial", 0.0))
	if absf(float(input.get("pick_lift", 0.0))) > 0.0:
		_moved = true
	_jam = lerpf(_jam, 1.0 if jammed else 0.0, k)
	var shake := 0.012 * _jam * sin(Time.get_ticks_msec() * 0.08)
	_dial_rot = lerp_angle(_dial_rot, dial * TAU + shake, k) if delta < 0.5 else dial * TAU
	for i in n_wheels:
		var e: Dictionary = els[i]
		var lo := float(e.get("window_lo", 0.0))
		var hi := float(e.get("window_hi", 0.1))
		_gate[i] = fposmod((lo + hi) * 0.5, 1.0)
		_win[i] = hi - lo
		var pos := float(e.get("position", 0.0))
		var st := String(e.get("state", "free"))
		if st == "false_set":
			_note_false(i, pos)
		var off := display_offset(i, pos)
		var target_rot := off * TAU
		_wheel_rot[i] = lerp_angle(_wheel_rot[i], target_rot, k) if delta < 0.5 else target_rot
		var r_mm := float(_wheel_meta(i)["radius_mm"])
		var depth := float(meta.get("notch_depth_mm", 3.2)) - 0.2
		var dip := notch_dip(wrap_half(_wheel_rot[i] / TAU) * TAU * r_mm, depth)
		if st == "false_set":
			dip = maxf(dip, FALSE_DIP_MM)
		if not pressed and not fence_down:
			dip = 0.0
		if fence_down:
			dip = 0.0  # the whole bar drops with the feelers in the gates (below)
		_feeler_dip[i] = lerpf(_feeler_dip[i], dip, k) if delta < 0.5 else dip
	var fdy := 0.0
	if fence_down:
		fdy = float(meta.get("notch_depth_mm", 3.2)) - 0.2
	elif not pressed:
		fdy = -LIFT_MM
	elif jammed:
		fdy = CLAMP_MM
	_fence_dy = lerpf(_fence_dy, fdy, k) if delta < 0.5 else fdy
	var throw := float(meta.get("bolt", {}).get("throw_mm", 14.0))
	_bolt_dx = lerpf(_bolt_dx, throw * hold, k) if delta < 0.5 else throw * hold
	_handle = lerpf(_handle, 90.0 * hold, k)
	_last_vm = vm
	_last_input = input
	_canvas.queue_redraw()
	_update_d_face(tension, res, delta)
	_update_d_chalk(vm, delta)
	_update_d_eyepiece(vm, delta)


func on_event(e: Dictionary) -> void:
	match StringName(e.get("kind", &"")):
		&"open":
			_opened = true
		&"set", &"gate_align":
			_set_flash = 1.0


func _note_false(i: int, pos: float) -> void:
	for p in _false_marks[i]:
		if absf(wrap_half(float(p) - pos)) < 0.6 / maxf(divisions, 1):
			return
	_false_marks[i].append(pos)


# ------------------------------------------------------------------ drawing (inside the SubViewport)
func _draw_layer(nm: String, xf: Transform2D, shadow: float = 0.42) -> void:
	var tex: Texture2D = _layers.get(nm)
	if tex == null:
		return
	var at := _layer_pos(nm)
	var s := float(viewport.size.x) / plate_size.x
	var ppm := float(_wheel_meta(0)["px_per_mm"])
	if shadow > 0.0 and not dark:
		var sh := SHADOW_MM * ppm
		for j in 2:
			var o := sh * (1.0 + 0.8 * j)
			_canvas.draw_set_transform_matrix(Transform2D().scaled(Vector2(s, s)) * Transform2D(0.0, o) * xf)
			_canvas.draw_texture(tex, at, Color(0, 0, 0, shadow * (0.6 if j == 0 else 0.35)))
	_canvas.draw_set_transform_matrix(Transform2D().scaled(Vector2(s, s)) * xf)
	_canvas.draw_texture(tex, at)


func _rot_about(a: float, p: Vector2) -> Transform2D:
	return Transform2D(0.0, p) * Transform2D(a, Vector2.ZERO) * Transform2D(0.0, -p)


func _draw_section() -> void:
	var s := float(viewport.size.x) / plate_size.x
	var plate: Texture2D = _layers.get("plate")
	_canvas.draw_set_transform_matrix(Transform2D().scaled(Vector2(s, s)))
	if plate != null:
		_canvas.draw_texture_rect(plate, Rect2(Vector2.ZERO, plate_size), false)
	else:
		_canvas.draw_rect(Rect2(Vector2.ZERO, plate_size), Color(0.12, 0.12, 0.12))
	var n := maxi(n_wheels, 1) if not _last_vm.is_empty() else 2
	for i in n:
		_draw_layer("wheel%d" % i, _rot_about(_wheel_rot[i], _spindle), 0.5)
		_draw_false_notches(i, s)
	# feelers ride with the fence bar; each one sinks into its own notch
	var fppm := float(meta.get("fence", {}).get("px_per_mm", 3.6))
	for i in n:
		var fm := _feeler_meta(i)
		var dy := (_fence_dy + _feeler_dip[i]) * float(fm["px_per_mm"])
		_draw_layer("feeler%d" % i, Transform2D(0.0, Vector2(0, dy)), 0.45)
	_draw_layer("fence", Transform2D(0.0, Vector2(0, _fence_dy * fppm)), 0.45)
	var bppm := float(meta.get("bolt", {}).get("px_per_mm", 3.6))
	_draw_layer("bolt", Transform2D(0.0, Vector2(-_bolt_dx * bppm, 0)), 0.45)
	_draw_layer("front", Transform2D.IDENTITY, 0.5)
	var dn := "dial%d" % (20 if divisions <= 20 else (30 if divisions <= 30 else 40))
	_draw_layer(dn, _rot_about(_dial_rot, _spindle), 0.5)
	_canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
	if dark:
		_canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(viewport.size)), Color(0, 0, 0, 0.985))


## Shallow false notches the fence has found (lockcore only says how many a wheel has): a dark
## nick in the rim, turning with the wheel.
func _draw_false_notches(i: int, s: float) -> void:
	if _false_marks[i].is_empty():
		return
	var wm := _wheel_meta(i)
	var ppm := float(wm["px_per_mm"])
	var r := float(wm["radius_mm"]) * ppm
	var base := deg_to_rad(float(wm.get("notch_angle_deg", 0.0)))
	for p in _false_marks[i]:
		var a := base + _wheel_rot[i] - display_offset(i, float(p)) * TAU
		var dir := Vector2(sin(a), -cos(a))
		var tan_ := Vector2(cos(a), sin(a))
		var c := _spindle + dir * (r - FALSE_DIP_MM * ppm * 0.5)
		var hw := NOTCH_HALF_MM * ppm
		var hd := FALSE_DIP_MM * ppm * 0.5 + 1.0
		var pts := PackedVector2Array([c - tan_ * hw - dir * hd, c + tan_ * hw - dir * hd, c + tan_ * hw + dir * hd, c - tan_ * hw + dir * hd])
		_canvas.draw_set_transform_matrix(Transform2D().scaled(Vector2(s, s)))
		_canvas.draw_colored_polygon(pts, Color(0.04, 0.035, 0.03, 0.85))


# ------------------------------------------------------------------ dark, face, chalk, loupe
func set_dark(on: bool) -> void:
	super.set_dark(on)
	if _canvas:
		_canvas.queue_redraw()


func _update_d_face(tension: float, res: float, delta: float) -> void:
	if _face == null:
		return
	var t := clampf(tension, 0.0, 1.0)
	_set_flash = maxf(_set_flash - delta / 0.2, 0.0)
	var k := 1.0 - exp(-delta / SMOOTH_S)
	var face := _handle + _set_flash * 1.5
	_face.face_deg = lerpf(_face.face_deg, face, k)
	_face.arm_deg = lerpf(_face.arm_deg, face + PlugFace.ARM_MAX_DEG * t, k)
	_face.bow = clampf(res, 0.0, 1.0)
	_face.tremor = _jam
	_face.tension = t
	_face.gauge = chalk_gauge and chalk_level != ChalkLayer.Level.OFF
	_face.opened = _opened
	_face.queue_redraw()


func _update_d_chalk(vm: Dictionary, delta: float) -> void:
	if _chalk == null:
		return
	_chalk.level = chalk_level
	if chalk_level == ChalkLayer.Level.OFF or _last_vm.is_empty():
		_chalk.marks = {}
		_chalk.text = ""
		_chalk.tick(delta)
		return
	var m := {}
	var paths: Array = []
	# a chalk stroke across each rim at its feeler: "the gate stops here"
	for i in n_wheels:
		var fm := _feeler_meta(i)
		var tp: Array = fm["tip_px"]
		var ppm := float(fm["px_per_mm"])
		var tip := Vector2(tp[0], tp[1])
		var dir := (tip - _spindle).normalized()
		var a := plate_to_screen(tip - dir * 1.2 * ppm - dir.orthogonal() * 3.6 * ppm)
		var b := plate_to_screen(tip - dir * 1.2 * ppm + dir.orthogonal() * 3.6 * ppm)
		paths.append(PackedVector2Array([a, b]))
	# the opening mark: a short stroke beside the index on the bezel
	var ip: Array = meta.get("index_px", [_spindle.x, _spindle.y - 75.0])
	var ix := plate_to_screen(Vector2(ip[0], ip[1]))
	paths.append(PackedVector2Array([ix + Vector2(-14, -10), ix + Vector2(-4, -2)]))
	paths.append(PackedVector2Array([ix + Vector2(14, -10), ix + Vector2(4, -2)]))
	m["paths"] = paths
	var r := get_rect()
	var safe := _safe_rect(r)
	var portrait := safe.size.y >= safe.size.x
	var thumbs_y := tray_rect.position.y + tray_rect.size.y * (0.66 if portrait else 0.75)
	m["left_anchor"] = Vector2(r.size.x * (0.22 if portrait else 0.12), thumbs_y)
	m["right_anchor"] = Vector2(r.size.x * (0.70 if portrait else 0.88), thumbs_y)
	m["hint_left"] = not chalk_gauge and float(vm.get("tension", 0.0)) < 0.1
	m["hint_vertical"] = not _moved
	m["text_rect"] = Rect2(Vector2(safe.position.x + 16.0, safe.position.y + 10.0), Vector2(safe.size.x - FLAP_DP - 48.0, 72.0))
	if not portrait:
		m["text_rect"] = Rect2(Vector2(section_rect.end.x + 16.0, safe.position.y + 16.0), Vector2(safe.end.x - section_rect.end.x - 32.0, 160.0))
	var any_set := false
	for e in vm.get("elements", []):
		any_set = any_set or String(e.get("state", "")) == "set"
	_chalk.marks = m
	_chalk.text = hint if not any_set and not _opened else ""
	_chalk.tick(delta)


func _update_d_eyepiece(vm: Dictionary, delta: float) -> void:
	if _eyepiece == null:
		return
	_eyepiece.tick(delta)
	if not _eyepiece.visible:
		return
	var idx := int(vm.get("pick_element", -1))
	if idx < 0 or idx >= n_wheels:
		idx = 0
		for i in n_wheels:
			if String(vm["elements"][i].get("state", "")) != "set":
				idx = i
				break
	var focus := feeler_tip_screen(idx)
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
