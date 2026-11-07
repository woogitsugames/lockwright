extends GutTest
## N-77: on the phone a tap on the loupe in the roll did nothing (wafer, "Kiosk przed szóstą"): four
## taps gave identical frames and Back went straight to the pause. A tap on Android is TWO events
## for the GUI: the InputEventScreenTouch and the InputEventMouseButton that Godot emulates from it
## (input_devices/pointing/emulate_mouse_from_touch, on by default). The loupe target toggled on
## both, so every tap opened and closed the eyepiece in the same frame. Fixed by TapGate (D-80, drops the emulated echo); this
## test adds what the landscape test does not cover: the hint ladder on screen (H2 ghost thumb, H3
## chalk arrows over the roll), every family in JobRun.PLANB_SCENES (lever_detector too), the tap not
## leaking into the right-thumb zone, the pick frozen while the loupe is open.
##
## Every lock screen (pin + every plan-B host in JobRun.PLANB_SCENES), portrait and landscape, with
## the hint ladder up to H3 (ghost thumb played, chalk arrows over the roll): a tap on the loupe
## centre delivered as the platform delivers it (touch + emulated mouse, then both releases) opens
## the eyepiece, does not reach the right-thumb zone, and a second tap closes it.

const SIZES := [Vector2i(412, 915), Vector2i(915, 412)]


func before_each() -> void:
	JobRun.current_job = {}


func after_each() -> void:
	JobRun.current_job = {}
	SafeArea.override_dp = SafeArea.OVERRIDE_OFF
	get_tree().paused = false


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


## Hint ladder on the screen even when this save has no coach for the family (lesson done, > 3 jobs).
func _ensure_hints(scene: Node) -> TutorialHints:
	if scene.get("hints") == null:
		if scene.get("coach") == null:
			var c := TutorialCoach.new(0, false, scene.sampler.auto_tension)
			c.family = scene.family
			scene.coach = c
			scene.view.coach = c
		scene.hints = TutorialHints.new()
		scene.hints.name = "TutorialHints"
		scene.add_child(scene.hints)
		scene.hints.setup(scene.view, scene.coach, scene.family, scene.sampler.auto_tension, scene.control)
	return scene.hints


## One finger tap the way Android + Godot deliver it to the GUI.
func _tap(vp: SubViewport, pos: Vector2) -> void:
	for pressed in [true, false]:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = pos
		t.pressed = pressed
		vp.push_input(t)
		var m := InputEventMouseButton.new()  # emulate_mouse_from_touch
		m.device = InputEvent.DEVICE_ID_EMULATION
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = pos
		m.global_position = pos
		m.pressed = pressed
		m.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		vp.push_input(m)
		await get_tree().process_frame


func test_tap_on_loupe_opens_it_on_every_lock_screen_with_hints() -> void:
	ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", true)
	var scenes := _scenes()
	assert_gt(scenes.size(), 12, "pin + every plan-B family")
	for fam in scenes:
		var job := _first_job(fam)
		if not job.is_empty():
			JobRun.start(job)
		for size in SIZES:
			var vp := SubViewport.new()
			vp.size = size
			vp.handle_input_locally = true
			add_child(vp)
			var scene: Node = load(scenes[fam]).instantiate()
			vp.add_child(scene)
			await wait_physics_frames(2)
			var tag := "%s %dx%d" % [fam, size.x, size.y]
			var view: LockPhotorealView = scene.view
			var hints := _ensure_hints(scene)
			hints.jump_to(3)  # H2 ghost played, H3 chalk arrows on the right thumb
			await wait_physics_frames(2)
			var loupe := view.loupe_rect()
			assert_true(Rect2(Vector2.ZERO, Vector2(size)).encloses(loupe), tag + ": loupe %s on screen" % loupe)
			assert_false(view.zoomed, tag + ": starts closed")
			var toggles: Array = []
			view.loupe_toggled.connect(func(on: bool) -> void: toggles.append(on))
			await _tap(vp, loupe.get_center())
			assert_eq(toggles, [true], tag + ": one tap = one toggle (touch + emulated mouse)")
			assert_true(view.zoomed, tag + ": a tap on the loupe centre opens the eyepiece")
			assert_true(view._eyepiece.visible, tag + ": eyepiece shown")
			assert_false(scene.sampler.right_down(), tag + ": the tap did not go to the right thumb zone")
			assert_true(scene.sampler.frozen, tag + ": pick frozen while the loupe is open")
			assert_false(bool(scene.get("_paused")), tag + ": no pause")
			await _tap(vp, loupe.get_center())
			assert_false(view.zoomed, tag + ": a quick second tap closes it")
			vp.queue_free()
			await get_tree().process_frame
		JobRun.current_job = {}


## Same double press on the warded probe head: one tap must step the bit once, not twice (with
## two bit slots two steps put it back where it was).
func test_tap_on_warded_bit_steps_once() -> void:
	ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", true)
	var job := _first_job(&"warded")
	if not job.is_empty():
		JobRun.start(job)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.handle_input_locally = true
	add_child_autofree(vp)
	var scene: Node = load(JobRun.PLANB_SCENES[&"warded"]).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(2)
	var btn: Control = scene.view.bit_button
	assert_true(btn.visible and btn.size.x >= 48.0, "bit target shown")
	var before: int = scene.control.bit
	var presses: Array = []
	scene.view.bit_pressed.connect(func() -> void: presses.append(1))
	await _tap(vp, btn.get_global_rect().get_center())
	assert_eq(presses.size(), 1, "one tap = one bit press")
	assert_ne(scene.control.bit, before, "the bit changed")
