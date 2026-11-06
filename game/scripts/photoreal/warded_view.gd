class_name LockWardedView
extends LockPhotorealView
## N-63: plan-B lock screen for the warded lock (LOCKS.md §2.2), same method as the pin screen:
##   - static parts: the Cycles plate in the photo-material look of art/renders/warded.png
##     (art/blender/plates/warded_photo_plate.py, plate.png: no moving parts, no rings),
##     projected through the fixed camera;
##   - moving parts of the baked GLB (probe, bit, bolt, tumbler, stud, leaf spring) projected
##     from the same render with the parts in (parts.png) at their rest pose (plate_rest);
##   - the lock's own wards (lockcore spans and gaps) as iron fences on the back plate, cut from
##     a Cycles iron slab render (wards.png) through the same camera.
## Front view, turn axis into the screen. The probe turns from the keyhole (down) round the right
## side up to the bolt; a ward is a fence across the turn with a channel at the heights it lets
## through; the bit's reach (tip height) has to sit in the channel. At the top the bit lifts the
## tumbler off the bolt (set) and throws the bolt (open). Every state is geometry: blocked = the
## bit stands at a fence, aligned = the head in front of the channel, set = tumbler up, open =
## bolt out. Same diegetic HUD as pins: probe handle + force arm on the plug face, picks in the
## roll, leather flap.

const W_DIR := "res://assets/photoreal_families/warded/"
const W_SCENE := W_DIR + "scene.json"
const W_GLB := W_DIR + "warded_baked.glb"
const W_PLATE := W_DIR + "photo/plate.png"
const W_PARTS := W_DIR + "photo/parts.png"
const W_WARDS := W_DIR + "photo/wards.png"
const PIN := Vector3(0.0, -8.0, 0.0)       # drill pin (turn axis), Godot mm
const BIT_REST_DEG := 76.0                 # bit angle in the renders
const ANGLE0 := -90.0                      # theta 0: bit down the keyhole slot
const SPAN_DEG := 158.0 / 0.82             # theta a_bolt → 68°: the bit meets the talon
const BIT_LEN := 25.6                      # rest tip radius
const R_H0 := 17.0                         # tip radius at h = 0
const R_HS := 12.0                         # mm per unit of h
const FENCE_R := Vector2(16.0, 30.0)       # ward slab (wards.png)
const FENCE_Z := Vector2(-10.0, -7.0)      # back plate .. fence top
const FENCE_PAD_DEG := 4.0                 # half the bar's width at the fences: a stopped bar touches the fence
const TPIV := Vector3(-24.0, 28.8, 0.0)    # tumbler pivot
const TUMB_ARM := 16.8
const LIFT_REST := 1.38                    # tumbler lift in the renders (stud clears the notch)
const LEAF_PIV := Vector3(-27.5, 39.3, 0.0)
const BOLT_THROW := 7.0
const SET_FRAC := (0.92 - 0.82) / (1.0 - 0.82)  # bolt element position at a_set
const HEAD_W := 3.6                       # bit head across the bit (the bar is 2.5)
const HEAD_D := 8.4                        # depth: stands 0.6 mm proud of the bar's face
const HEAD_ZC := -5.2
const MOVING := ["probe_tube", "bit", "bolt", "tumbler", "tstud", "leaf"]

var spans: Array = []                      # Vector2(a_lo, a_hi) per ward (lockcore turn fraction)
var bit_slot := 0
var bit_w := 0.12
var bit_button: Control
var _n_wards := -1
var _fences: Array[MeshInstance3D] = []
var _fence_mat: ShaderMaterial
var _parts_tex: Texture2D
var _tooth: MeshInstance3D
var _tooth_mat: ShaderMaterial
var _by := {}
var _angle := ANGLE0
var _reach := BIT_LEN
var _tumb_lift := 0.0
var _bolt_dx := 0.0
var _gaps: Array = []
var _bolt_band := Vector2(0.4, 0.58)

signal bit_pressed


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rig = JSON.parse_string(FileAccess.get_file_as_string(W_SCENE))
	_build_viewport()
	_build_w_model()
	_build_camera()
	_build_w_materials()
	_build_overlay()
	_build_bit_button()
	_active_stacks = 1
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_dark(dark)
	present({}, {})


# ------------------------------------------------------------------ build
func _build_w_model() -> void:
	_model = (load(W_GLB) as PackedScene).instantiate()
	for c in _model.find_children("*", "Camera3D", true, false):
		c.get_parent().remove_child(c)
		c.free()
	viewport.add_child(_model)
	for n in _model.find_children("*", "Node3D", true, false):
		_rest[n] = n.transform
		_by[String(n.name)] = n
		# the two decorative rings of the renders are not this lock's wards
		var nm := String(n.name)
		if nm.begins_with("ward") or nm.begins_with("wr_"):
			n.visible = false
	for nm in ["probe_tube", "bit"]:
		if not _by.has(nm):
			push_warning("warded GLB: no %s" % nm)


func _projected(tex: Texture2D) -> ShaderMaterial:
	var m := _mat("plate.gdshader")
	m.set_shader_parameter("plate", tex)
	return m


func _build_w_materials() -> void:
	var plate := _tex(W_PLATE)
	_parts_tex = _tex(W_PARTS)
	var static_mat := _projected(plate)
	for mi: MeshInstance3D in _model.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var nm := String(mi.name)
		if nm in MOVING:
			var r := _mat("plate_rest.gdshader")
			r.set_shader_parameter("plate", _parts_tex)
			r.set_shader_parameter("rest_model", Projection(_rest[mi]))
			mi.material_override = r
		else:
			mi.material_override = static_mat
	_fence_mat = _mat("ward_fence.gdshader")
	_fence_mat.set_shader_parameter("plate", _tex(W_WARDS))
	# the head of the bit (its reach and thickness = the chosen bit), textured from the bit's tip
	_tooth = MeshInstance3D.new()
	_tooth.name = "bit_head"
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, HEAD_W, HEAD_D)
	_tooth.mesh = bm
	_tooth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tooth_mat = _mat("plate_rest.gdshader")
	_tooth_mat.set_shader_parameter("plate", _parts_tex)
	_tooth_mat.set_shader_parameter("rest_model", Projection(_radial_xf(BIT_REST_DEG, BIT_LEN - 1.6, 1.6, 2.2 / HEAD_W)))
	_tooth.material_override = _tooth_mat
	_model.add_child(_tooth)


func _build_bit_button() -> void:
	bit_button = Control.new()
	bit_button.name = "BitButton"
	bit_button.mouse_filter = Control.MOUSE_FILTER_STOP
	bit_button.gui_input.connect(func(ev: InputEvent) -> void:
		var down: bool = (ev is InputEventScreenTouch and ev.pressed) or (ev is InputEventMouseButton and ev.pressed)
		if down:
			bit_button.accept_event()
			bit_pressed.emit())
	add_child(bit_button)


## Transform of a radial piece: centre at radius r on the ray at angle deg from the pin, its local
## x along the ray, scaled to the radial size sx.
func _radial_xf(deg: float, r: float, sx: float, sy: float = 1.0) -> Transform3D:
	var b := Basis(Vector3.BACK, deg_to_rad(deg))
	return Transform3D(b, PIN) * Transform3D(Basis.from_scale(Vector3(sx, sy, 1)), Vector3(r, 0, HEAD_ZC))


## lockcore warded spans + gaps → fences. Called by the lock scene once per session.
func set_wards(p_spans: Array) -> void:
	spans = p_spans
	_n_wards = -1  # rebuilt on the next present()


func set_bit(slot: int, width: float) -> void:
	bit_slot = slot
	bit_w = width


func turn_deg(theta: float) -> float:
	return ANGLE0 + clampf(theta, 0.0, 1.05) * SPAN_DEG


func reach_mm(h: float) -> float:
	return R_H0 + clampf(h, 0.0, 1.0) * R_HS


func _rebuild_fences(gaps: Array) -> void:
	for f in _fences:
		f.queue_free()
	_fences.clear()
	_n_wards = gaps.size()
	var sp := spans if spans.size() == gaps.size() else WardedControl.default_spans(gaps.size())
	for i in gaps.size():
		var a0 := turn_deg(sp[i].x) + FENCE_PAD_DEG
		var a1 := turn_deg(sp[i].y) + FENCE_PAD_DEG
		var g: Vector2 = gaps[i]
		var r_lo := reach_mm(g.x)
		var r_hi := reach_mm(g.y)
		if r_lo > FENCE_R.x + 0.4:
			_fences.append(_fence(a0, a1, FENCE_R.x, r_lo, "fence%d_in" % i))
		if r_hi < FENCE_R.y - 0.4:
			_fences.append(_fence(a0, a1, r_hi, FENCE_R.y, "fence%d_out" % i))


## An annular sector prism (the lock's ward) on the back plate.
func _fence(a0: float, a1: float, r0: float, r1: float, nm: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var k := maxi(4, int(absf(a1 - a0) / 3.0))
	var ring := func(r: float, z: float) -> PackedVector3Array:
		var out := PackedVector3Array()
		for j in k + 1:
			var a := deg_to_rad(lerpf(a0, a1, float(j) / k))
			out.append(PIN + Vector3(cos(a) * r, sin(a) * r, z))
		return out
	var it: PackedVector3Array = ring.call(r0, FENCE_Z.y)
	var ot: PackedVector3Array = ring.call(r1, FENCE_Z.y)
	var ib: PackedVector3Array = ring.call(r0, FENCE_Z.x)
	var ob: PackedVector3Array = ring.call(r1, FENCE_Z.x)
	var quad := func(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
		st.set_normal(n)
		for v in [a, b, c, a, c, d]:
			st.add_vertex(v)
	for j in k:
		var am := deg_to_rad(lerpf(a0, a1, (j + 0.5) / k))
		var radial := Vector3(cos(am), sin(am), 0)
		quad.call(it[j], ot[j], ot[j + 1], it[j + 1], Vector3.BACK)        # top
		quad.call(ob[j], ot[j], ot[j + 1], ob[j + 1], radial)              # outer wall
		quad.call(ib[j], it[j], it[j + 1], ib[j + 1], -radial)             # inner wall
	var t0 := Vector3(-sin(deg_to_rad(a0)), cos(deg_to_rad(a0)), 0)
	quad.call(ib[0], ob[0], ot[0], it[0], -t0)                             # end walls
	quad.call(ib[k], ob[k], ot[k], it[k], t0)
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = st.commit()
	mi.material_override = _fence_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_model.add_child(mi)
	return mi


# ------------------------------------------------------------------ public API
func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	var els: Array = vm.get("elements", [])
	var gaps: Array = []
	for i in maxi(els.size() - 1, 0):
		gaps.append(Vector2(float(els[i].get("window_lo", 0.4)), float(els[i].get("window_hi", 0.6))))
	if els.size() > 0:
		var b: Dictionary = els[els.size() - 1]
		_bolt_band = Vector2(float(b.get("window_lo", 0.4)), float(b.get("window_hi", 0.58)))
		if gaps.size() != _n_wards or gaps != _gaps:
			_gaps = gaps
			_rebuild_fences(gaps)
	var theta := float(vm.get("core_rotation", 0.0))
	var tension := float(vm.get("tension", input.get("tension", 0.0)))
	_stress = clampf(float(vm.get("stress", 0.0)), 0.0, 1.0)
	_opened = bool(vm.get("open", false)) or _opened
	var k := 1.0 - exp(-delta / SMOOTH_S)
	var bolt: Dictionary = els[els.size() - 1] if els.size() > 0 else {}
	var bolt_state := String(bolt.get("state", "free"))
	var bolt_pos := float(bolt.get("position", 0.0))
	# probe: turn and reach
	var shake := 0.0
	if _stress >= 0.6:
		shake = (_stress - 0.6) * 2.5 * sin(Time.get_ticks_msec() * 0.09)  # ≤ 1° tremor near the limit
	_angle = lerpf(_angle, turn_deg(1.0 if _opened else theta), k)
	var h := float(vm.get("pick_lift", input.get("pick_lift", 0.5)))
	_reach = lerpf(_reach, reach_mm(h), k)
	# tumbler: down on the bolt until the bit lifts it (bound → set), bolt thrown from set to open
	var lift_target := 0.0
	var dx_target := 0.0
	if bolt_state in ["bound", "set"] or _opened:
		lift_target = LIFT_REST * clampf(bolt_pos / SET_FRAC, 0.0, 1.0) + (0.3 if bolt_state == "set" else 0.0)
		dx_target = -BOLT_THROW * clampf((bolt_pos - SET_FRAC) / (1.0 - SET_FRAC), 0.0, 1.0)
	if _opened:
		lift_target = LIFT_REST + 0.3
		dx_target = -BOLT_THROW
	_tumb_lift = lerpf(_tumb_lift, lift_target, k)
	_bolt_dx = lerpf(_bolt_dx, dx_target, k)
	_pose_parts(shake)
	_last_vm = vm
	_last_input = input
	_update_w_face(theta, tension, delta)
	_update_w_chalk(els, delta)
	_update_w_eyepiece(delta)


func on_event(e: Dictionary) -> void:
	match StringName(e.get("kind", &"")):
		&"break":
			_broken = true
			if lives > 0:
				set_lives(lives - 1)
		&"open":
			_opened = true
		&"set", &"gate_align":
			_set_flash = 1.0


func _pose_parts(shake: float) -> void:
	var d := _angle + shake - BIT_REST_DEG
	var turn := Transform3D(Basis(Vector3.BACK, deg_to_rad(d)), PIN) * Transform3D(Basis.IDENTITY, -PIN)
	if _broken:
		turn = Transform3D(Basis.IDENTITY, Vector3(0, -0.8, 0)) * turn  # the bent probe sags in the keyhole
	var tip := _reach - bit_w * R_HS * 0.5 + 0.3  # the bar ends under the head
	var ra := deg_to_rad(BIT_REST_DEG)
	var stretch := Basis(Vector3.BACK, ra) * Basis.from_scale(Vector3(tip / BIT_LEN, 1, 1)) * Basis(Vector3.BACK, -ra)
	var reach_xf := Transform3D(stretch, PIN) * Transform3D(Basis.IDENTITY, -PIN)
	if _by.has("bit"):
		_by["bit"].transform = turn * reach_xf * _rest[_by["bit"]]
	if _by.has("probe_tube"):
		_by["probe_tube"].transform = turn * _rest[_by["probe_tube"]]
	var head := _radial_xf(BIT_REST_DEG, _reach, maxf(bit_w * R_HS, 0.5))
	_tooth.transform = turn * head
	var tdeg := rad_to_deg((_tumb_lift - LIFT_REST) / TUMB_ARM)
	var trot := Transform3D(Basis(Vector3.BACK, deg_to_rad(tdeg)), TPIV) * Transform3D(Basis.IDENTITY, -TPIV)
	for nm in ["tumbler", "tstud"]:
		if _by.has(nm):
			_by[nm].transform = trot * _rest[_by[nm]]
	if _by.has("leaf"):
		var lrot := Transform3D(Basis(Vector3.BACK, deg_to_rad(tdeg * 0.45)), LEAF_PIV) * Transform3D(Basis.IDENTITY, -LEAF_PIV)
		_by["leaf"].transform = lrot * _rest[_by["leaf"]]
	if _by.has("bolt"):
		_by["bolt"].transform = Transform3D(Basis.IDENTITY, Vector3(_bolt_dx, 0, 0)) * _rest[_by["bolt"]]


## Screen point of the bit head (tests, chalk, loupe).
func bit_head_screen() -> Vector2:
	var a := deg_to_rad(_angle)
	return mm_to_screen(PIN + Vector3(cos(a) * _reach, sin(a) * _reach, FENCE_Z.y))


# ------------------------------------------------------------------ layout extras
func _layout() -> void:
	super._layout()
	if bit_button == null or viewport == null:
		return
	# the probe head over the drill pin: tap = next bit (only out of the keyhole, unturned)
	var c := mm_to_screen(PIN + Vector3(0, 0, -1.6))
	if c == Vector2.ZERO:
		c = section_rect.get_center()
	var s := Vector2(LOUPE_MIN_DP, LOUPE_MIN_DP)
	bit_button.position = c - s * 0.5
	bit_button.size = s


func set_dark(on: bool) -> void:
	super.set_dark(on)
	if bit_button:
		bit_button.visible = not on


# ------------------------------------------------------------------ face, chalk, loupe
func _update_w_face(theta: float, tension: float, delta: float) -> void:
	if _face == null:
		return
	var t := clampf(tension, 0.0, 1.0)
	# the probe handle seen from the front: the keyway mark turns with the probe (90° per quarter)
	var face := clampf(theta, 0.0, 1.0) * SPAN_DEG * 0.5
	_set_flash = maxf(_set_flash - delta / 0.2, 0.0)
	face += _set_flash * 1.5
	var k := 1.0 - exp(-delta / SMOOTH_S)
	_face.face_deg = lerpf(_face.face_deg, face, k)
	_face.arm_deg = lerpf(_face.arm_deg, face + PlugFace.ARM_MAX_DEG * t, k)
	_face.bow = clampf(float(_last_vm.get("tension_resistance", 0.0)), 0.0, 1.0)
	_face.tremor = clampf((_stress - 0.6) / 0.4, 0.0, 1.0)
	_face.tension = t
	_face.gauge = chalk_gauge and chalk_level != ChalkLayer.Level.OFF
	_face.opened = _opened
	_face.queue_redraw()


func _arc_pts(a0: float, a1: float, r: float, z: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var k := maxi(3, int(absf(a1 - a0) / 4.0))
	for j in k + 1:
		var a := deg_to_rad(lerpf(a0, a1, float(j) / k))
		out.append(mm_to_screen(PIN + Vector3(cos(a) * r, sin(a) * r, z)))
	return out


func _update_w_chalk(els: Array, delta: float) -> void:
	if _chalk == null:
		return
	_chalk.level = chalk_level
	if chalk_level == ChalkLayer.Level.OFF:
		_chalk.marks = {}
		_chalk.text = ""
		_chalk.tick(delta)
		return
	var m := {}
	var paths: Array = []
	var sp := spans if spans.size() == _gaps.size() else WardedControl.default_spans(_gaps.size())
	# the channel of each ward: two chalk arcs along its edges, over the span
	for i in _gaps.size():
		var a0 := turn_deg(sp[i].x)
		var a1 := turn_deg(sp[i].y) + FENCE_PAD_DEG
		paths.append(_arc_pts(a0, a1, reach_mm(_gaps[i].x), FENCE_Z.y))
		paths.append(_arc_pts(a0, a1, reach_mm(_gaps[i].y), FENCE_Z.y))
	# the bolt band at the top: where the bit has to reach to catch the bolt
	var b0 := turn_deg(0.80)
	var b1 := turn_deg(0.86)
	paths.append(_arc_pts(b0, b1, reach_mm(_bolt_band.x), FENCE_Z.y))
	paths.append(_arc_pts(b0, b1, reach_mm(_bolt_band.y), FENCE_Z.y))
	m["paths"] = paths
	var r := get_rect()
	var safe := _safe_rect(r)
	var portrait := safe.size.y >= safe.size.x
	var thumbs_y := tray_rect.position.y + tray_rect.size.y * (0.66 if portrait else 0.75)
	m["left_anchor"] = Vector2(r.size.x * (0.22 if portrait else 0.12), thumbs_y)
	m["right_anchor"] = Vector2(r.size.x * (0.70 if portrait else 0.88), thumbs_y)
	var turned := float(_last_vm.get("core_rotation", 0.0)) > 0.02
	m["hint_left"] = not turned and coach == null and not chalk_gauge
	m["hint_vertical"] = not turned
	var text := _coach_text(m)
	_apply_hint_marks(m)
	_chalk.marks = m
	_chalk.text = text
	_chalk.tick(delta)


func _update_w_eyepiece(delta: float) -> void:
	if _eyepiece == null:
		return
	_eyepiece.tick(delta)
	if not _eyepiece.visible:
		return
	var focus := bit_head_screen()
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
