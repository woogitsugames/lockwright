extends GutTest
## HANDOVER §5.3: in landscape the lock screen's bottom strip cut off the picks and the loupe (the
## combo and disc detainer screens still had it after the side-column fix of the other families).
## Every playable lock screen in landscape, also round a notch and a gesture bar (SafeArea test
## insets): the whole leather roll (picks + loupe) is on screen inside the safe area, beside the
## section, and the loupe target is >= 48 dp inside the safe area. N-78: the section takes the room
## between the plug face and the roll (the wafer plate was tiny). N-77: one tap on the loupe opens it
## on every screen (a phone tap = touch + emulated click, which used to toggle it twice).

## [window dp, safe-area insets dp (left, top, right, bottom)]
const CASES := [
	[Vector2i(915, 412), Vector4(48, 0, 48, 21)],   # notch on a side + gesture bar
	[Vector2i(915, 412), Vector4.ZERO],
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
	for fam in scenes:
		if not JobRun.PHOTOREAL_READY.has(fam):
			continue
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
			if ins == Vector4.ZERO and size == Vector2i(915, 412):
				assert_gte(view.section_rect.size.x, size.y * LockPhotorealView.SECTION_ASPECT * 1.3, tag + ": N-78 section not tiny")
			vp.queue_free()
			await wait_frames(1)


func test_tap_gate_one_press_per_tap() -> void:
	var g := TapGate.new()
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	assert_true(g.accept(touch, 1000), "the touch is the press")
	assert_false(g.accept(click, 1000), "the click emulated from the same tap is swallowed")
	var up := InputEventScreenTouch.new()
	assert_false(g.accept(up, 1100), "a release is not a press")
	assert_true(g.accept(click, 1000 + TapGate.WINDOW_MS), "the next tap counts")


func _tap(vp: SubViewport, at: Vector2) -> void:
	# what a phone sends for one tap: the touch, then the mouse click emulated from it
	var t := InputEventScreenTouch.new()
	t.position = at
	t.pressed = true
	vp.push_input(t, true)
	var m := InputEventMouseButton.new()
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
