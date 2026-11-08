class_name LockComboView
extends LockPhotorealView
## D-59: plan-B lock screen for the thumbwheel combination lock (LOCKS.md §2.19), same method as the
## pin, warded and dial safe screens, built from Cycles layers (art/blender/plates/combo_plate.py,
## photo materials). A quarter cut-away of the lock body: the top half of each thumbwheel shows its
## digits through the body window (reading line with two index marks), the bottom half shows the
## section on the axis plane: wheel ring, sleeve wall, bore, latch bar and one sprung tooth per sleeve.
## The sleeve's gate slot passes under its tooth at 6 o'clock when the wheel shows the gate digit.
##   wheels: the plate holds blank Cycles-lit wheels; the digit band (band.png) is wrapped on each
##           wheel by combo_reel.gdshader (cylinder mapping, multiplied), so a wheel rolls exactly
##   section: slot depth in the cut = how close the slot is to 6 o'clock (round slot profile)
## States by geometry (greyscale): cable let go = every tooth up off the bore (a gap); pulled = the
## binding wheel's tooth on its bore, the others hovering; near = the slot opening under the tooth;
## set = tooth down in the slot; false notch = tooth half down in a shallow nick; slip (rolled too
## fast) = the tooth chatters on the bore while the digits run; open = bar slides along the slots,
## the cable plug comes out. The wheel under the right thumb carries the thumb's shadow.

const C_DIR := "res://assets/photoreal_families/combo/photo/"
const META := C_DIR + "layers.json"
const REEL_SHADER := "res://scripts/photoreal/combo_reel.gdshader"
const SLOTS := 5
const RETRACT_MM := 0.7       # cable let go: teeth drawn up into the bar
const HOVER_MM := 0.22        # pulled, wheel not binding: the tooth hovers over the bore
const FALSE_DIP_MM := 0.5
const SLOT_HALF_TURN := 0.045 # the gate slot shows in the cut within this turn of 6 o'clock
const BAR_SLIDE_MM := 3.0
const PLUG_OUT_MM := 6.0
const SHADOW_MM := Vector2(0.18, 0.26)

var meta := {}
var plate_size := Vector2(618, 824)
var n_wheels := 0
var first_slot := 1
var hint := ""
var _layers := {}
var _back: Node2D
var _front: Node2D
var _reels: Array[Sprite2D] = []
var _reel_mats: Array[ShaderMaterial] = []
var slots := SLOTS            # wheel slots in the plate (layers.json slots_px)
var _pos: Array[float] = []
var _gate: Array[float] = []
var _tooth: Array[float] = []   # mm past the contact surface into the slot (+), or back (-)
var _slot_vis: Array[float] = [] # visible slot depth in the cut, mm
var _false_marks: Array = []
var _bar_dx := 0.0
var _plug_dx := 0.0
var _picked := -1
var _chatter := 0.0
var _rolled := false
var _reel_plate: Array[Rect2] = []
## The part of the plate shown (plate px). The lock is wide and flat: the section shows a crop round
## it, wide in landscape, so the wheels stay >= 28 dp (CLAUDE.md) on every screen.
var _crop := Rect2(0, 0, 618, 824)
const BODY_X := Vector2(34.0, 584.0)
const PORTRAIT_ASPECT := 1.05          # (pre VA-11) section height / width in portrait
## VA-11: plate px of bench kept under the lock's lowest part (room for the chalk ticks under the teeth).
const PORTRAIT_UNDER_PX := 80.0
## VA-11: lowest plate px of the lock body drawn in the plate itself (measured on plate.png at x = 618).
const PLATE_BODY_BOTTOM := {"combo": 1011.0, "disc_detainer": 1038.0}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if FileAccess.file_exists(_dir() + "layers.json"):
		meta = JSON.parse_string(FileAccess.get_file_as_string(_dir() + "layers.json"))
	slots = maxi((meta.get("slots_px", []) as Array).size(), 1) if meta.has("slots_px") else SLOTS
	for i in slots:
		_pos.append(0.0)
		_gate.append(0.0)
		_tooth.append(0.0)
		_slot_vis.append(0.0)
		_false_marks.append([])
		_reel_plate.append(Rect2())
	var res: Array = meta.get("res", [618, 824])
	plate_size = Vector2(res[0], res[1])
	_build_viewport()
	_back = Node2D.new()
	_back.name = "ComboBack"
	_back.draw.connect(_draw_back)
	viewport.add_child(_back)
	var band := _tex(_dir() + "band.png")
	var bm: Dictionary = meta.get("band", {})
	for i in slots:
		var sp := Sprite2D.new()
		sp.name = "Reel%d" % i
		sp.centered = false
		sp.texture = _white_tex()
		var m := ShaderMaterial.new()
		m.shader = load(REEL_SHADER)
		m.set_shader_parameter("band", band)
		m.set_shader_parameter("read_a", deg_to_rad(float(meta.get("wheel", {}).get("read_deg", 30.0))))
		var bw := float(meta.get("wheel", {}).get("width_mm", 5.6))
		m.set_shader_parameter("u_scale", bw / float(bm.get("view_mm", 4.4)))
		m.set_shader_parameter("cells", float(bm.get("cells", 10)))
		sp.material = m
		sp.visible = false
		viewport.add_child(sp)
		_reels.append(sp)
		_reel_mats.append(m)
	_front = Node2D.new()
	_front.name = "ComboFront"
	_front.draw.connect(_draw_front)
	viewport.add_child(_front)
	for nm in ["plate", "front", "latch", "tooth", "plug"]:
		_layers[nm] = _tex(_dir() + nm + ".png")
	_build_overlay()
	_active_stacks = 1
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_dark(dark)
	present({}, {})


## Asset folder (the disc detainer view reuses this view with its own plates).
func _dir() -> String:
	return C_DIR


## +1: a rising lockcore position rolls the wheel's front up (thumb up); -1 for families whose
## position runs the other way under the thumb (disc detainer).
func _reel_sign() -> float:
	return 1.0


## +1: the teeth move down into the slots (combo sleeves); -1: up (disc detainer sidebar).
func _tdir() -> float:
	return float(meta.get("tooth_dir", 1.0))


static func _white_tex() -> Texture2D:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ geometry
func _wm() -> Dictionary:
	return meta.get("wheel", {"radius_mm": 7.0, "width_mm": 5.6, "px_per_mm_front": 8.4, "px_per_mm_section": 8.6, "read_deg": 30.0})


func _sm() -> Dictionary:
	return meta.get("sleeve", {"bore_mm": 2.2, "outer_mm": 4.0, "notch_depth_mm": 1.2, "tooth_w_mm": 1.6})


func slot_of(i: int) -> int:
	return clampi(first_slot + i, 0, slots - 1)


func _slot_x(slot: int, section: bool = true) -> float:
	var key := "slots_section_px" if section else "slots_px"
	var a: Array = meta.get(key, [])
	if slot < a.size():
		return float(a[slot])
	return plate_size.x * 0.5 + (slot - 2) * 7.0 * float(_wm()["px_per_mm_section"])


func _axis_y() -> float:
	return float(meta.get("axis_px", plate_size.y * 0.45))


func _layer_pos(nm: String) -> Vector2:
	var o: Array = meta.get("layers", {}).get(nm, {}).get("offset", [0, 0])
	return Vector2(o[0], o[1])


static func wrap_half(d: float) -> float:
	return fposmod(d + 0.5, 1.0) - 0.5


## Visible depth (mm) of a round-bottomed slot in the cut, for a slot this far (turns) from 6 o'clock.
static func slot_depth(off_turns: float, depth_mm: float) -> float:
	var x := absf(off_turns) / SLOT_HALF_TURN
	return depth_mm * sqrt(maxf(0.0, 1.0 - x * x))


func tooth_dip(i: int) -> float:
	return _tooth[slot_of(i)]


func slot_visible(i: int) -> float:
	return _slot_vis[slot_of(i)]


func reel_pos(i: int) -> float:
	return _pos[slot_of(i)]


func bar_dx() -> float:
	return _bar_dx


func plug_dx() -> float:
	return _plug_dx


func set_hint(s: String) -> void:
	hint = s


func plate_to_screen(p: Vector2) -> Vector2:
	var disp := _section_display()
	return disp.position + (p - _crop.position) / _crop.size * disp.size


## Screen point of wheel i's tooth tip (tests, chalk, loupe).
func tooth_tip_screen(i: int) -> Vector2:
	var s := slot_of(i)
	var ppm := float(_wm()["px_per_mm_section"])
	return plate_to_screen(Vector2(_slot_x(s), _axis_y() + (float(_sm()["bore_mm"]) + _tdir() * _tooth[s]) * ppm))


## Tooth width on screen, dp (CLAUDE.md: elements >= 28 dp).
func tooth_width_screen() -> float:
	var w := float(_sm()["tooth_w_mm"]) * float(_wm()["px_per_mm_section"])
	return (plate_to_screen(Vector2(w, 0)) - plate_to_screen(Vector2.ZERO)).x


## Screen rect of wheel i's visible digits (tests).
func reel_rect_screen(i: int) -> Rect2:
	var r: Rect2 = _reel_plate[slot_of(i)]
	var a := plate_to_screen(r.position)
	var b := plate_to_screen(r.end)
	return Rect2(a, b - a)


# ------------------------------------------------------------------ public API
func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	var els: Array = vm.get("elements", [])
	var n := mini(els.size(), slots)
	if n != n_wheels:
		n_wheels = n
		first_slot = int((slots - n) / 2.0) if n > 0 else 1
	var k := 1.0 - exp(-delta / SMOOTH_S)
	var snap := delta >= 0.5
	var tension := float(vm.get("tension", input.get("tension", 0.0)))
	_opened = bool(vm.get("open", false)) or _opened
	var pulled := tension >= 0.1 or _opened
	_picked = int(vm.get("pick_element", -1))
	if absf(float(input.get("pick_lift", 0.0))) > 0.0:
		_rolled = true
	var depth := float(_sm()["notch_depth_mm"])
	var slipping := false
	for s in slots:
		_tooth[s] = lerpf(_tooth[s], -RETRACT_MM, k)
		_slot_vis[s] = 0.0
	for i in n:
		var e: Dictionary = els[i]
		var s := slot_of(i)
		var st := String(e.get("state", "free"))
		var lo := float(e.get("window_lo", 0.0))
		var hi := float(e.get("window_hi", 0.06))
		_gate[s] = fposmod((lo + hi) * 0.5, 1.0)
		var pos := float(e.get("position", 0.0))
		if st == "false_set":
			_note_false(s, pos)
		_pos[s] = pos if snap else _pos[s] + wrap_half(pos - _pos[s]) * k
		var off := wrap_half(_pos[s] - _gate[s])
		var vis := slot_depth(off, depth)
		for f in _false_marks[s]:
			vis = maxf(vis, slot_depth(wrap_half(_pos[s] - float(f)), FALSE_DIP_MM))
		_slot_vis[s] = vis
		var target := -RETRACT_MM
		if pulled:
			match st:
				"set":
					target = depth
				"false_set":
					target = FALSE_DIP_MM
				"bound", "near":
					target = vis
				"overset":
					target = 0.0
					slipping = true
				_:
					target = -HOVER_MM if not _opened else depth
		if _opened:
			target = depth
		_tooth[s] = target if snap else lerpf(_tooth[s], target, k)
		if st == "overset":
			_tooth[s] -= 0.12 * absf(sin(Time.get_ticks_msec() * 0.06))
		_reel_mats[s].set_shader_parameter("pos", _pos[s] * _reel_sign())
	_chatter = 1.0 if slipping else 0.0
	var core := clampf(float(vm.get("core_rotation", 0.0)), 0.0, 1.0)
	var bar_t := BAR_SLIDE_MM * (1.0 if _opened else core)
	var plug_t := PLUG_OUT_MM * (1.0 if _opened else 0.0)
	_bar_dx = bar_t if snap else lerpf(_bar_dx, bar_t, k)
	_plug_dx = plug_t if snap else lerpf(_plug_dx, plug_t, k)
	_last_vm = vm
	_last_input = input
	_place_reels()
	_back.queue_redraw()
	_front.queue_redraw()
	_update_c_face(tension, float(vm.get("tension_resistance", 0.0)), delta)
	_update_c_chalk(vm, delta)
	_update_c_eyepiece(vm, delta)


func on_event(e: Dictionary) -> void:
	match StringName(e.get("kind", &"")):
		&"open":
			_opened = true
		&"set", &"gate_align":
			_set_flash = 1.0


func _note_false(s: int, pos: float) -> void:
	for p in _false_marks[s]:
		if absf(wrap_half(float(p) - pos)) < 0.03:
			return
	_false_marks[s].append(pos)


# ------------------------------------------------------------------ drawing (inside the SubViewport)
func _vs() -> float:
	return float(viewport.size.x) / _crop.size.x


## Plate pixels → section viewport pixels (the crop is scaled to fill the viewport).
func _view_xf() -> Transform2D:
	var s := _vs()
	return Transform2D().scaled(Vector2(s, s)) * Transform2D(0.0, -_crop.position)


func _place_reels() -> void:
	var s := _vs()
	var wm := _wm()
	var ppm := float(wm["px_per_mm_front"])
	var r := float(wm["radius_mm"]) * ppm
	var w := float(wm["width_mm"]) * ppm
	for slot in slots:
		var sp := _reels[slot]
		var used := slot >= first_slot and slot < first_slot + n_wheels
		sp.visible = used and not _last_vm.is_empty()
		var x := _slot_x(slot, false) - w * 0.5
		_reel_plate[slot] = Rect2(x, _axis_y() - r, w, r)
		sp.position = (Vector2(x, _axis_y() - r) - _crop.position) * s
		sp.scale = Vector2(w, r) / Vector2(sp.texture.get_size()) * s
		_reel_mats[slot].set_shader_parameter("dim", 0.0 if dark else 1.0)


func _draw_layer(c: CanvasItem, nm: String, xf: Transform2D, shadow: float = 0.4) -> void:
	var tex: Texture2D = _layers.get(nm)
	if tex == null:
		return
	var at := _layer_pos(nm)
	var s := _vs()
	var ppm := float(_wm()["px_per_mm_section"])
	if shadow > 0.0 and not dark:
		for j in 2:
			var o := SHADOW_MM * ppm * (1.0 + 0.8 * j)
			c.draw_set_transform_matrix(_view_xf() * Transform2D(0.0, o) * xf)
			c.draw_texture(tex, at, Color(0, 0, 0, shadow * (0.6 if j == 0 else 0.35)))
	c.draw_set_transform_matrix(_view_xf() * xf)
	c.draw_texture(tex, at)


## VA-11: lowest plate px of the lock (its body in the plate, front, latch, tooth, plug) — the crop keeps it in.
func lock_bottom_px() -> float:
	var b := maxf(_axis_y(), float(PLATE_BODY_BOTTOM.get(String(meta.get("family", "")), 0.0)))
	for nm in ["front", "latch", "tooth", "plug"]:
		var l: Dictionary = meta.get("layers", {}).get(nm, {})
		if l.has("offset") and l.has("size"):
			b = maxf(b, float(l["offset"][1]) + float(l["size"][1]))
	return b


func _draw_back() -> void:
	var s := _vs()
	_back.draw_set_transform_matrix(_view_xf())
	var plate: Texture2D = _layers.get("plate")
	if plate != null and _crop.position.y < 0.0:
		# VA-11: the crop starts above the plate (portrait, lock low): continue the bench with the
		# plate's top band mirrored, so the section reaches the roll without a strip of bare bench
		var ext := minf(-_crop.position.y + 2.0, plate_size.y)
		_back.draw_set_transform_matrix(_view_xf() * Transform2D(Vector2(1, 0), Vector2(0, -1), Vector2.ZERO))
		_back.draw_texture_rect_region(plate, Rect2(Vector2.ZERO, Vector2(plate_size.x, ext)), Rect2(Vector2.ZERO, Vector2(plate_size.x, ext)))
		_back.draw_set_transform_matrix(_view_xf())
	if plate != null:
		_back.draw_texture_rect(plate, Rect2(Vector2.ZERO, plate_size), false)
		if _crop.position.y < 0.0:
			# a plank joint where the copy meets the plate (as the bench's other joints), no seam
			_back.draw_rect(Rect2(0.0, -4.0, plate_size.x, 7.0), Color(0.07, 0.045, 0.03, 0.85))
			_back.draw_rect(Rect2(0.0, 3.0, plate_size.x, 2.0), Color(0.55, 0.38, 0.24, 0.25))
	else:
		_back.draw_rect(Rect2(Vector2.ZERO, plate_size), Color(0.2, 0.17, 0.13))
	if _last_vm.is_empty():
		return
	var ppm := float(_wm()["px_per_mm_section"])
	var sm := _sm()
	var bore := float(sm["bore_mm"]) * ppm
	var tw := float(sm["tooth_w_mm"]) * ppm
	# gate slots in the cut: a dark round-bottomed pocket in the sleeve wall under each tooth
	for i in n_wheels:
		var slot := slot_of(i)
		var d := _slot_vis[slot] * ppm
		if d <= 0.3:
			continue
		var cx := _slot_x(slot)
		var y0 := _axis_y() + bore
		var dd := _tdir()
		var pts := PackedVector2Array()
		for j in 9:
			var t := float(j) / 8.0
			var x := cx - tw * 0.65 + tw * 1.3 * t
			pts.append(Vector2(x, y0 + dd * d * sqrt(maxf(0.0, 1.0 - pow(2.0 * t - 1.0, 2.0)))))
		pts.append(Vector2(cx + tw * 0.65, y0 - dd * 0.5))
		pts.append(Vector2(cx - tw * 0.65, y0 - dd * 0.5))
		_back.draw_colored_polygon(pts, Color(0.035, 0.03, 0.025, 0.95))
	# latch bar and teeth (teeth ride in the bar; the bar slides along the slots on opening)
	var bxf := Transform2D(0.0, Vector2(-_bar_dx * ppm, 0))
	_draw_layer(_back, "latch", bxf, 0.35)
	var x0 := _slot_x(0)
	for i in n_wheels:
		var slot := slot_of(i)
		var dx := _slot_x(slot) - x0 - _bar_dx * ppm
		_draw_layer(_back, "tooth", Transform2D(0.0, Vector2(dx, _tdir() * _tooth[slot] * ppm)), 0.4)
	_draw_layer(_back, "plug", Transform2D(0.0, Vector2(_plug_dx * ppm, 0)), 0.4)


func _draw_front() -> void:
	var s := _vs()
	_draw_layer(_front, "front", Transform2D.IDENTITY, 0.45)
	# the right thumb resting on the chosen wheel: its soft shadow over the top of that wheel
	if _picked >= 0 and _picked < n_wheels and not dark:
		var wm := _wm()
		var ppm := float(wm["px_per_mm_front"])
		var c := Vector2(_slot_x(slot_of(_picked), false), _axis_y() - float(wm["radius_mm"]) * ppm * 0.92)
		_front.draw_set_transform_matrix(_view_xf())
		for j in 6:
			var f := 1.0 - j / 6.0
			_front.draw_circle(c + Vector2(0, -2.0 * ppm), 3.6 * ppm * f, Color(0, 0, 0, 0.07))
	_front.draw_set_transform_matrix(Transform2D.IDENTITY)
	if dark:
		_front.draw_rect(Rect2(Vector2.ZERO, Vector2(viewport.size)), Color(0, 0, 0, 0.985))


# ------------------------------------------------------------------ dark, face, chalk, loupe
func set_dark(on: bool) -> void:
	super.set_dark(on)
	if _back:
		_place_reels()
		_back.queue_redraw()
		_front.queue_redraw()


func _update_c_face(tension: float, res: float, delta: float) -> void:
	if _face == null:
		return
	var t := clampf(tension, 0.0, 1.0)
	_set_flash = maxf(_set_flash - delta / 0.2, 0.0)
	var k := 1.0 - exp(-delta / SMOOTH_S)
	var face := (90.0 if _opened else 0.0) + _set_flash * 1.5
	_face.face_deg = lerpf(_face.face_deg, face, k)
	_face.arm_deg = lerpf(_face.arm_deg, face + PlugFace.ARM_MAX_DEG * t, k)
	_face.bow = clampf(res, 0.0, 1.0)
	_face.tremor = _chatter
	_face.tension = t
	_face.gauge = chalk_gauge and chalk_level != ChalkLayer.Level.OFF
	_face.opened = _opened
	_face.queue_redraw()


func _update_c_chalk(vm: Dictionary, delta: float) -> void:
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
	var ppm := float(_wm()["px_per_mm_section"])
	var outer := float(_sm()["outer_mm"]) * ppm
	# under each sleeve: a chalk tick at 6 o'clock, "the slot has to come here"
	for i in n_wheels:
		var x := _slot_x(slot_of(i))
		var y := _axis_y() + outer + 1.2 * ppm
		paths.append(PackedVector2Array([plate_to_screen(Vector2(x, y)), plate_to_screen(Vector2(x, y + 1.6 * ppm))]))
	# a caret under the wheel the right thumb is on
	if _picked >= 0 and _picked < n_wheels:
		var px := _slot_x(slot_of(_picked))
		var py := _axis_y() + outer + 4.2 * ppm
		var a := plate_to_screen(Vector2(px - 1.4 * ppm, py + 1.6 * ppm))
		var b := plate_to_screen(Vector2(px, py))
		var c := plate_to_screen(Vector2(px + 1.4 * ppm, py + 1.6 * ppm))
		paths.append(PackedVector2Array([a, b, c]))
	m["paths"] = paths
	var r := get_rect()
	var safe := _safe_rect(r)
	var portrait := safe.size.y >= safe.size.x
	var thumbs_y := tray_rect.position.y + tray_rect.size.y * (0.66 if portrait else 0.75)
	m["left_anchor"] = Vector2(r.size.x * (0.22 if portrait else 0.12), thumbs_y)
	m["right_anchor"] = Vector2(r.size.x * (0.70 if portrait else 0.88), thumbs_y)
	m["hint_left"] = not chalk_gauge and float(vm.get("tension", 0.0)) < 0.1
	m["hint_right"] = not _rolled
	m["text_rect"] = Rect2(Vector2(safe.position.x + 16.0, safe.position.y + 10.0), Vector2(safe.size.x - FLAP_DP - 48.0, 72.0))
	if not portrait:
		# above the roll in the landscape column (the roll sits at the column's bottom)
		var roll_top := tray_rect.position.y + float((_tray_map()[4] as Vector2).y)
		var th := clampf(roll_top - safe.position.y - 24.0, 72.0, 160.0)
		m["text_rect"] = Rect2(Vector2(section_rect.end.x + 16.0, safe.position.y + 16.0), Vector2(safe.end.x - section_rect.end.x - 32.0, th))
	var any_set := false
	for e in vm.get("elements", []):
		any_set = any_set or String(e.get("state", "")) == "set"
	_chalk.text = _lesson_chalk(m, hint if not any_set and not _opened else "")
	_chalk.marks = m
	_chalk.tick(delta)


func _update_c_eyepiece(vm: Dictionary, delta: float) -> void:
	if _eyepiece == null:
		return
	_eyepiece.tick(delta)
	if not _eyepiece.visible:
		return
	var idx := clampi(int(vm.get("pick_element", 0)), 0, maxi(n_wheels - 1, 0))
	var focus := tooth_tip_screen(idx)
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


# ------------------------------------------------------------------ layout: a crop round the lock
func _layout() -> void:
	super._layout()
	if _back == null or viewport == null:
		return
	var r := get_rect()
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return
	var safe := _safe_rect(r)
	var bx: Array = meta.get("body_px", [BODY_X.x, BODY_X.y])
	var cx := (float(bx[0]) + float(bx[1])) * 0.5
	var cw := float(bx[1]) - float(bx[0])
	var cy := _axis_y() + 12.0
	if safe.size.y >= safe.size.x:
		# portrait: the lock is wide and flat, so the section is a wide band round it (not 3:4 of bench);
		# the leather roll takes the rest
		# VA-11: the roll as on every other lock screen (same height, whole width, the loupe not cut)
		# and the section down to it, the lock resting just above the roll (no strip of empty bench
		# under it); the bench above the plate's top edge is its top band mirrored (_draw_back)
		var h := minf(r.size.x / SECTION_ASPECT, safe.size.y * 0.72)
		section_rect = Rect2(r.position, Vector2(r.size.x, safe.position.y - r.position.y + h))
		var ch := cw * section_rect.size.y / section_rect.size.x
		var bottom := minf(lock_bottom_px() + PORTRAIT_UNDER_PX, plate_size.y)
		_crop = Rect2(cx - cw * 0.5, maxf(bottom - ch, -plate_size.y * 0.5), cw, ch)
		tray_rect = Rect2(Vector2(r.position.x, section_rect.end.y), Vector2(r.size.x, r.end.y - section_rect.end.y))
		_tray.position = tray_rect.position
		_tray.size = tray_rect.size
		_loupe_rect = _compute_loupe_rect()
		_loupe_btn.position = _loupe_rect.position
		_loupe_btn.size = _loupe_rect.size
		_face.position = Vector2(safe.position.x + 4.0, tray_rect.position.y + 6.0)
	else:
		# landscape (HANDOVER §5.3, as in the base view): the roll is a column on the right inside the
		# safe area (whole picks and loupe, contain-fit), the section takes the width between the plug
		# face and that column. A bottom strip here cropped the picks and hid the loupe.
		var col_w := landscape_roll_width(safe.size, _roll_size())
		var x0 := safe.end.x - col_w
		var left := safe.position.x + PlugFace.size_for(FACE_R_DP).x + 40.0
		section_rect = Rect2(Vector2(left, r.position.y), Vector2(maxf(x0 - ROLL_GAP - left, 100.0), r.size.y))
		var ch := minf(cw * section_rect.size.y / section_rect.size.x, plate_size.y)
		_crop = Rect2(cx - cw * 0.5, clampf(cy - ch * 0.5, 0.0, plate_size.y - ch), cw, ch)
		tray_rect = Rect2(Vector2(x0, safe.position.y), Vector2(col_w, safe.size.y))
		_tray.position = tray_rect.position
		_tray.size = tray_rect.size
		_loupe_rect = _compute_loupe_rect()
		_loupe_btn.position = _loupe_rect.position
		_loupe_btn.size = _loupe_rect.size
		_face.position = Vector2(section_rect.position.x - _face.size.x - 16.0, section_rect.position.y + section_rect.size.y * 0.45)
	_section.position = section_rect.position
	_section.size = section_rect.size
	var px := _physical_scale() * render_scale
	var vp := Vector2(section_rect.size) * px
	var n := vp.x * vp.y
	if n > MAX_VP_PIXELS:
		vp *= sqrt(MAX_VP_PIXELS / n)
	viewport.size = Vector2i(maxi(int(vp.x), 16), maxi(int(vp.y), 16))
	_place_reels()
	_back.queue_redraw()
	_front.queue_redraw()
	_tray.queue_redraw()
