extends GutTest
## N-56 / N-57 / N-62: the plan-B lock screen shows tension, moves pins far enough to read,
## has a working loupe and a pause flap that is a real touch target.


func _scene() -> Node:
	var scene: Node = load("res://scenes/photoreal/lock_photoreal.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(4)
	return scene


func test_pin_travel_reads_on_screen() -> void:
	# N-62: lockcore position 0 → 1 must move a key pin ≥ 40 dp on the 412 dp portrait screen
	var scene: Node = await _scene()
	var view: LockPhotorealView = scene.get_node("ViewLayer/View")
	var x := 13.0
	var a := view.mm_to_screen(Vector3(x, PinPose.REST_BOTTOM, 0.0))
	var b := view.mm_to_screen(Vector3(x, PinPose.REST_BOTTOM + PinPose.TRAVEL, 0.0))
	var scale := 412.0 / maxf(view.get_rect().size.x, 1.0)  # normalise to the 412 dp width
	assert_gt(absf(a.y - b.y) * scale, 40.0, "full lift = %.1f dp" % (absf(a.y - b.y) * scale))


func test_plug_face_turn_is_visible() -> void:
	# N-62: ≥ 2 dp at the plug edge at full tension; ≥ 2 dp of wrench tip per 0.05 T (HUD.md §3)
	var edge := deg_to_rad(PlugFace.PLAY_DEG) * LockPhotorealView.FACE_R_DP
	assert_gte(edge, 2.0, "plug edge moves %.1f dp" % edge)
	var tip := deg_to_rad(PlugFace.ARM_MAX_DEG * 0.05) * LockPhotorealView.FACE_R_DP * PlugFace.ARM_LEN
	assert_gte(tip, 2.0, "wrench tip moves %.1f dp per 0.05 T" % tip)


func test_tension_turns_the_face_and_set_adds_a_tick() -> void:
	var scene: Node = await _scene()
	var view: LockPhotorealView = scene.get_node("ViewLayer/View")
	var face: PlugFace = view.get_node("PlugFace")
	var vm := {"elements": [{"state": &"bound", "position": 0.2}, {"state": &"free", "position": 0.0}], "tension": 0.0}
	for i in 30:
		view.present(vm, {"tension": 0.0}, 1.0 / 60.0)
	var rest_arm := face.arm_deg
	vm["tension"] = 0.4
	for i in 30:
		view.present(vm, {"tension": 0.4}, 1.0 / 60.0)
	assert_gt(face.arm_deg - rest_arm, 8.0, "the wrench arm turns with tension")
	var before := face.face_deg
	vm["elements"][0]["state"] = &"set"
	for i in 30:
		view.present(vm, {"tension": 0.4}, 1.0 / 60.0)
	assert_almost_eq(face.face_deg - before, PlugFace.TICK_DEG, 0.5, "a set turns the plug one tick")


func test_loupe_tap_toggles_zoomed() -> void:
	var scene: Node = await _scene()
	var view: LockPhotorealView = scene.get_node("ViewLayer/View")
	var btn: Control = view.get_node("LoupeButton")
	assert_gte(btn.size.x, 48.0, "loupe target ≥ 48 dp")
	assert_gte(btn.size.y, 48.0, "loupe target ≥ 48 dp")
	assert_false(view.zoomed)
	var t := InputEventScreenTouch.new()
	t.pressed = true
	t.position = btn.size * 0.5
	view._on_loupe_input(t)
	assert_true(view.zoomed, "first tap opens the eyepiece")
	assert_true(scene.sampler.frozen, "the pick holds still while looking (ONBOARDING §6.2)")
	assert_true(scene.go_back(), "back closes the eyepiece first")
	assert_false(view.zoomed)
	view._on_loupe_input(t)
	view._on_loupe_input(t)
	assert_false(view.zoomed, "second tap closes it")


func test_pause_flap_is_a_tongue_with_a_real_target() -> void:
	var scene: Node = await _scene()
	var view: LockPhotorealView = scene.get_node("ViewLayer/View")
	var flap: PauseFlap = view.get_node("PauseFlap")
	assert_gte(flap.size.x, 48.0)
	assert_gte(flap.size.y, 48.0)
	assert_eq(flap.position.y, 0.0, "hangs from the top edge")
	var o := flap.outline()
	assert_gt(o.size(), 10, "rounded end (cut-out shape, not a square)")
	view.pause_requested.disconnect(scene._on_pause)  # keep the test tree running
	watch_signals(view)
	flap.press()
	await wait_seconds(0.3)
	assert_signal_emitted(view, "pause_requested")


func test_unused_chambers_are_plugged() -> void:
	var scene: Node = await _scene()
	var view: LockPhotorealView = scene.get_node("ViewLayer/View")
	var vm := {"elements": [{"state": &"free"}, {"state": &"free"}, {"state": &"free"}]}
	view.present(vm, {}, 1.0 / 60.0)
	var blanks := 0
	for b in view._blanks:
		if b.visible:
			blanks += 1
	assert_eq(blanks, 2, "a 3-pin lock shows 2 plugged chambers, not empty holes (N-56)")
