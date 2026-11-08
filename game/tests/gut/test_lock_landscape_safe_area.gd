extends GutTest
## HANDOVER §5.3: in landscape the lock screen's bottom strip cut off the picks and the loupe (the
## combo and disc detainer screens still had it after the side-column fix of the other families).
## Every playable lock screen in landscape, also round a notch and a gesture bar (SafeArea test
## insets): the whole leather roll (picks + loupe) is on screen inside the safe area, beside the
## section, and the loupe target is >= 48 dp inside the safe area. N-78: the section takes the room
## between the plug face and the roll (the wafer plate was tiny). N-77: one tap on the loupe opens it
## on every screen (a phone tap = touch + emulated click, which used to toggle it twice).
## Also 892x412 (SM-A165F) with and without insets, lever_detector, and the mechanism's elements
## inside the cover-cropped section (the wider section must not crop what the player works on).

## [window dp, safe-area insets dp (left, top, right, bottom)]
const CASES := [
	[Vector2i(915, 412), Vector4(48, 0, 48, 21)],   # notch on a side + gesture bar
	[Vector2i(915, 412), Vector4.ZERO],
	[Vector2i(892, 412), Vector4.ZERO],             # SM-A165F 2340x1080 px (N-78), no insets reported
	[Vector2i(892, 412), Vector4(32, 0, 0, 16)],    # same phone, cutout on the left + gesture bar
	[Vector2i(800, 360), Vector4.ZERO],
	[Vector2i(1916, 1080), Vector4(32, 0, 0, 24)],
]


func after_each() -> void:
	SafeArea.override_dp = SafeArea.OVERRIDE_OFF
	JobRun.current_job = {}


func _scenes() -> Dictionary:
	var out := {&"pin_tumbler": "res://scenes/lock_job.tscn"}
	out.merge(JobRun.PLANB_SCENES)
	return out


func _first_job(fam: StringName) -> Dictionary:
	for f in DirAccess.get_files_at("res://data/jobs"):
		if f.ends_with(".json"):
			var j: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + f))
			if j is Dictionary and JobRun.family_for(j) == fam and JobRun.outcome_for(j) != &"talk":
				return j
	return {}


func test_landscape_roll_column_math() -> void:
	# a share of the safe width, never wider than the whole roll at full safe height
	assert_almost_eq(LockPhotorealView.landscape_roll_width(Vector2(819, 391), Vector2(1080, 960)), 819 * 0.28, 0.01)
	assert_almost_eq(LockPhotorealView.landscape_roll_width(Vector2(3000, 400), Vector2(1080, 960)), 450.0 + LockPhotorealView.ROLL_MARGIN, 0.01)


func test_every_lock_screen_shows_whole_roll_and_loupe_in_landscape_safe_area() -> void:
	var scenes := _scenes()
	for fam in scenes:  # every plan-B screen, lever_detector too (not in PHOTOREAL_READY)
		var job := _first_job(fam)
		if job.is_empty():
			continue
		JobRun.start(job)
		for c in CASES:
			var size: Vector2i = c[0]
			var ins: Vector4 = c[1]
			SafeArea.override_dp = ins
			var vp := SubViewport.new()
			vp.size = size
			add_child(vp)
			var scene: Node = load(scenes[fam]).instantiate()
			vp.add_child(scene)
			await wait_physics_frames(2)
			var view: LockPhotorealView = scene.view
			var tag := "%s %dx%d insets %s" % [fam, size.x, size.y, ins]
			var safe := Rect2(Vector2(ins.x, ins.y), Vector2(size) - Vector2(ins.x + ins.z, ins.y + ins.w))
			var m: Array = view._tray_map()
			assert_eq(m[3], m[2], tag + ": the whole roll image is shown (no crop)")
			var roll := Rect2(view.tray_rect.position + (m[4] as Vector2), (m[2] as Vector2) * float(m[0]))
			assert_true(safe.grow(1.0).encloses(roll), tag + ": roll %s inside safe %s" % [roll, safe])
			assert_false(roll.intersects(view.section_rect.grow(-1.0)), tag + ": roll beside the section")
			var loupe: Rect2 = view.loupe_rect()
			assert_gte(loupe.size.x, 48.0, tag + ": loupe target")
			assert_gte(loupe.size.y, 48.0, tag + ": loupe target")
			assert_true(safe.grow(1.0).encloses(loupe), tag + ": loupe %s inside safe" % loupe)
			assert_true(view.section_rect.size.x > 100.0 and view.section_rect.size.y > 100.0, tag + ": section shown")
			assert_lt(roll.end.x, safe.end.x - 4.0, tag + ": bare leather right of the roll (loupe ring not cut)")
			# the wider, cover-cropped section must not crop the mechanism itself: every element is
			# inside the shown section, off the plug face and the roll
			var face := Rect2(view._face.position, view._face.size)
			assert_true(safe.grow(1.0).encloses(face), tag + ": plug face %s inside safe" % face)
			assert_false(face.intersects(view.section_rect.grow(-1.0)), tag + ": face beside the section")
			for p in _mechanism_points(view):
				assert_true(view.section_rect.grow(-4.0).has_point(p), tag + ": element %s inside section %s" % [p, view.section_rect])
				assert_false(roll.has_point(p) or face.has_point(p), tag + ": element %s not under the roll / face" % p)
			# D-85: whole parts, not one point each: every mechanism part's bounding box keeps its top
			# and bottom inside the (centre-cropped) section, so no spring tip or plug bottom is cut
			var rects := _mechanism_rects(view, fam)
			assert_gt(rects.size(), 0, tag + ": mechanism parts found")
			for pr in rects:
				# what the full plate shows (an anchored spring end may leave the plate on every screen)
				var rr: Rect2 = (pr[1] as Rect2).intersection(view._section_display())
				if rr.size.y <= 0.0:
					continue
				assert_true(rr.position.y >= view.section_rect.position.y - 1.0 and rr.end.y <= view.section_rect.end.y + 1.0,
					tag + ": part %s %s not cut by section %s" % [pr[0], rr, view.section_rect])
			if ins == Vector4.ZERO and size == Vector2i(915, 412):
				# N-78: wider than the old 3:4 where the plate has bench round the mechanism (D-85)
				var want := minf(LockPhotorealView.landscape_max_for(fam), 1.3 * LockPhotorealView.SECTION_ASPECT)
				assert_gte(view.section_rect.size.x, size.y * want - 1.0, tag + ": N-78 section not tiny")
			vp.queue_free()
			await wait_frames(1)


func test_tap_gate_one_press_per_tap() -> void:
	var g := TapGate.new()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	var echo := InputEventMouseButton.new()  # what emulate_mouse_from_touch sends for the same tap
	echo.device = InputEvent.DEVICE_ID_EMULATION
	echo.button_index = MOUSE_BUTTON_LEFT
	echo.pressed = true
	assert_true(g.accept(touch), "the touch is the press")
	assert_false(g.accept(echo), "the click emulated from the same tap is swallowed")
	var up := InputEventScreenTouch.new()
	assert_false(g.accept(up), "a release is not a press")
	assert_true(g.accept(touch), "a quick next tap counts (no time window)")
	var click := InputEventMouseButton.new()  # a real mouse (desktop / editor)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert_true(g.accept(click), "a real mouse click counts")


func _tap(vp: SubViewport, at: Vector2) -> void:
	# what a phone sends for one tap: the touch, then the mouse click emulated from it
	var t := InputEventScreenTouch.new()
	t.position = at
	t.pressed = true
	vp.push_input(t, true)
	var m := InputEventMouseButton.new()
	m.device = InputEvent.DEVICE_ID_EMULATION  # Godot marks the emulated click
	m.button_index = MOUSE_BUTTON_LEFT
	m.position = at
	m.global_position = at
	m.pressed = true
	vp.push_input(m, true)
	await wait_frames(1)
	for e in [t.duplicate(), m.duplicate()]:
		e.pressed = false
		vp.push_input(e, true)
	await wait_frames(1)


func test_one_tap_opens_the_loupe_on_every_lock_screen() -> void:
	var scenes := _scenes()
	for fam in scenes:
		if not JobRun.PHOTOREAL_READY.has(fam):
			continue
		var job := _first_job(fam)
		if job.is_empty():
			continue
		JobRun.start(job)
		for size in [Vector2i(412, 915), Vector2i(915, 412)]:
			var vp := SubViewport.new()
			vp.size = size
			vp.handle_input_locally = true
			add_child(vp)
			var scene: Node = load(scenes[fam]).instantiate()
			vp.add_child(scene)
			await wait_physics_frames(2)
			var view: LockPhotorealView = scene.view
			var tag := "%s %dx%d" % [fam, size.x, size.y]
			await _tap(vp, view.loupe_rect().get_center())
			assert_true(view.zoomed, tag + ": one tap on the loupe opens the eyepiece")
			vp.queue_free()
			await wait_frames(1)


## Screen points of the mechanism's elements (pins, wafers, levers, wheels, pegs ...).
func _mechanism_points(view: LockPhotorealView) -> Array:
	var out := []
	if view.has_method("wafer_screen"):
		for i in 5:
			out.append(view.wafer_screen(i))
	elif view.has_method("element_screen"):
		for i in view.get("n_el"):
			out.append(view.element_screen(i))
	elif view.has_method("gate_screen"):
		for i in view.lever_count():
			out.append(view.gate_screen(i))
	elif view.has_method("tooth_tip_screen"):
		for i in view.get("n_wheels"):
			out.append(view.tooth_tip_screen(i))
	elif view.has_method("feeler_tip_screen"):
		for i in view.get("n_wheels"):
			out.append(view.feeler_tip_screen(i))
	elif view.has_method("bit_head_screen"):
		out.append(view.bit_head_screen())
	else:
		for i in view._active_stacks:
			out.append(view.mm_to_screen(Vector3(LockPhotorealView.PINS_X[i], PinPose.SHEAR, 0.0)))
	return out


## D-85: mesh names of the parts the player works on (and the plug / frame round them) per 3D screen;
## the outer shell, the door, the bench and the tools (pick, wrench) are left out.
const MECHANISM_MESHES := {
	&"pin_tumbler": "^(cap(_[0-9]+)?|[a-e]_spr|[a-e]_(key|drv)_live|e_blank|plug)$",
	&"wafer": "^(wafer[0-9]|wspr[0-9]|bridge[0-9]|plug)$",
	&"lever": "^(lever[0-9]|spring[0-9]|stump|stud|post|post_head|bolt|detector.*)$",
	&"warded": "^(tumbler|leaf|lblock|bolt|bit|bit_head|pin|khd|fence[0-9]_(in|out)|staple[0-9]|tstud|tpivot)$",
}
const MESH_FAMILY := {&"dimple": &"pin_tumbler", &"magnetic": &"pin_tumbler", &"lever_detector": &"lever"}


## [name, screen rect] of each mechanism part: projected mesh bounds (3D screens) or the Cycles
## layer rects (layer screens; the plate, the tool and the dial safe's door front left out).
func _mechanism_rects(view: LockPhotorealView, fam: StringName) -> Array:
	var out := []
	var layers: Variant = view.get("meta")
	if layers is Dictionary and (layers as Dictionary).has("layers") and view.has_method("plate_to_screen"):
		var skip := ["plate", String(view.get("tool_layer")) if view.get("tool_layer") != null else ""]
		if fam == &"dial_safe":
			skip.append("front")
		for nm in (layers["layers"] as Dictionary):
			if skip.has(String(nm)):
				continue
			var l: Dictionary = layers["layers"][nm]
			var o := Vector2(l["offset"][0], l["offset"][1])
			var a: Vector2 = view.plate_to_screen(o)
			var b: Vector2 = view.plate_to_screen(o + Vector2(l["size"][0], l["size"][1]))
			out.append([nm, Rect2(a, b - a)])
		return out
	var re := RegEx.create_from_string(MECHANISM_MESHES.get(MESH_FAMILY.get(fam, fam), "^$"))
	for n in view.viewport.find_children("*", "VisualInstance3D", true, false):
		var vi := n as VisualInstance3D
		if not vi.is_visible_in_tree() or re.search(String(vi.name)) == null:
			continue
		var bb := vi.global_transform * vi.get_aabb()
		var r := Rect2(view.mm_to_screen(bb.position), Vector2.ZERO)
		for k in 8:
			r = r.expand(view.mm_to_screen(bb.get_endpoint(k)))
		out.append([vi.name, r])
	return out
