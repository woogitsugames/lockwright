extends GutTest
## ONBOARDING §2 on the real lock screen: TutorialHints (HintLadder + GhostHand) in the
## tutorial scene. An idle player climbs H1 15 s → H2 30 s (ghost) → H3 45 s (chalk) →
## H4 60 s (the lock really does the step); progress resets the ladder; the ghost never
## takes a touch; H4 plays at most once per step. Both D-52 control modes.

const HZ := 120
var _save_backup: Dictionary


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)


func after_all() -> void:
	Settings.set_value(&"auto_tension", false)
	Save.data = _save_backup
	Save.save()
	JobRun.current_job = {}
	JobRun.mode = &"job"


func _open(auto: bool) -> Array:
	Settings.set_value(&"auto_tension", auto)  # the scene reads the D-52 mode when it starts
	JobRun.start_tutorial(0)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load("res://scenes/lock_job.tscn").instantiate()
	vp.add_child(scene)
	await wait_physics_frames(2)
	scene.set_physics_process(false)
	scene.sampler.set_physics_process(false)
	assert_eq(scene.sampler.auto_tension, auto)
	return [scene, vp, scene.hints]


func _idle(scene: Node, seconds: float) -> void:
	for i in int(seconds * HZ):
		scene.sampler._physics_process(1.0 / HZ)
		scene._physics_process(1.0 / HZ)


func _touch(idx: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var t := InputEventScreenTouch.new()
	t.index = idx
	t.position = pos
	t.pressed = pressed
	return t


func test_idle_player_escalates_h1_to_h4_and_the_lock_does_the_step() -> void:
	for auto in [false, true]:
		var o: Array = await _open(auto)
		var scene: Node = o[0]
		var hints: TutorialHints = o[2]
		assert_not_null(hints, "the tutorial lock runs the hint ladder")
		var tag := "auto=%s" % auto
		_idle(scene, 14.5)
		assert_eq(hints.ladder.level, 0, tag + ": H0 before 15 s")
		_idle(scene, 1.0)
		assert_eq(hints.ladder.level, 1, tag + ": H1 nudge at 15 s")
		assert_gt(scene.view.hint_dent_s, 0.0, tag + ": H1 thumb imprint in the leather")
		_idle(scene, 15.0)
		assert_eq(hints.ladder.level, 2, tag + ": H2 at 30 s")
		assert_true(hints.ghost.is_playing(), tag + ": H2 plays the ghost thumb")
		_idle(scene, 15.0)
		assert_eq(hints.ladder.level, 3, tag + ": H3 at 45 s")
		assert_eq(scene.view.chalk_level, ChalkLayer.Level.FULL, tag + ": H3 chalk")
		assert_eq(scene.view.hint_arrows, "right" if auto else "left", tag + ": H3 arrow at the thumb that has to move")
		var before: Dictionary = scene.session.describe()
		_idle(scene, 15.0)
		assert_eq(hints.h4_steps.size(), 1, tag + ": H4 at 60 s")
		_idle(scene, 8.0)
		var after: Dictionary = scene.session.describe()
		var moved := false
		for i in after["elements"].size():
			var st := String(after["elements"][i]["state"])
			if st != String(before["elements"][i]["state"]):
				moved = true
		assert_true(moved or bool(after.get("open", false)), tag + ": the master hand really moved the lock (%s)" % [after["elements"]])
		var hist: Array = Save.get_value("tutorial/hint_history", [])
		assert_gt(hist.size(), 3, tag + ": telemetry keeps every level")


func test_progress_resets_the_ladder() -> void:
	var o: Array = await _open(false)
	var scene: Node = o[0]
	var hints: TutorialHints = o[2]
	_idle(scene, 20.0)
	assert_eq(hints.ladder.level, 1)
	# the player finally holds tension: a bind (progress / next step) brings the ladder to H0
	var s: InputSampler = scene.sampler
	s._unhandled_input(_touch(0, Vector2(80, 700), true))
	var d := InputEventScreenDrag.new()
	d.index = 0
	d.position = Vector2(80, 630)
	s._unhandled_input(d)
	_idle(scene, 2.0)
	assert_eq(hints.ladder.level, 0, "progress resets to H0 (step %s)" % hints.step)


func test_ghost_does_not_take_touches() -> void:
	var o: Array = await _open(false)
	var scene: Node = o[0]
	var vp: SubViewport = o[1]
	var hints: TutorialHints = o[2]
	_idle(scene, 31.0)
	assert_true(hints.ghost.is_playing())
	assert_eq(hints.ghost.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	var at := hints.ghost.ghost_center
	vp.push_input(_touch(0, at, true))
	assert_true(scene.sampler.left_down(), "a touch on the ghost reaches the thumb sampler")
	vp.push_input(_touch(0, at, false))


func test_h4_at_most_once_per_step() -> void:
	for auto in [false, true]:
		var o: Array = await _open(auto)
		var scene: Node = o[0]
		var hints: TutorialHints = o[2]
		_idle(scene, 200.0)
		var seen := {}
		for st in hints.h4_steps:
			assert_false(seen.has(st), "auto=%s: H4 twice in step %s (%s)" % [auto, st, hints.h4_steps])
			seen[st] = true
		assert_gt(hints.h4_steps.size(), 0)


func test_dark_mode_hints_have_no_picture_until_h4() -> void:
	var o: Array = await _open(false)
	var scene: Node = o[0]
	var hints: TutorialHints = o[2]
	scene.view.set_dark(true)
	_idle(scene, 31.0)
	assert_false(hints.ghost.is_playing(), "in the dark H2 is sound + haptics only")
	_idle(scene, 15.0)
	assert_eq(scene.view.hint_arrows, "", "in the dark H3 draws no chalk arrow")
	_idle(scene, 15.0)
	assert_false(scene.view.dark, "H4 lights the scene for a moment")
	_idle(scene, 3.0)
	assert_true(scene.view.dark, "and the light goes off again")


func test_screen_reader_hears_h2_to_h4() -> void:
	# ONBOARDING §11: H2 the gesture, H3 the chalk, H4 the master hand; nothing without a reader
	var o: Array = await _open(false)
	var scene: Node = o[0]
	var hints: TutorialHints = o[2]
	hints.screen_reader_override = 0
	_idle(scene, 31.0)
	assert_eq(hints.spoken.size(), 0, "no screen reader: silent")
	hints.screen_reader_override = 1
	_idle(scene, 30.0)
	assert_eq(hints.spoken, [&"tutorial.say_chalk", &"tutorial.say_master"] as Array[StringName], "H3 + H4 spoken")
	var o2: Array = await _open(false)
	var h2: TutorialHints = o2[2]
	h2.screen_reader_override = 1
	_idle(o2[0], 31.0)
	assert_eq(h2.spoken, [&"tutorial.say_tension"] as Array[StringName], "H2 says the tension gesture")
	for k in [&"tutorial.say_tension", &"tutorial.say_lift", &"tutorial.say_warded", &"tutorial.say_chalk", &"tutorial.say_master"]:
		assert_ne(I18n.t(k), String(k), "%s translated" % k)


func test_ladder_thresholds_sorted_and_history_capped() -> void:
	var l := HintLadder.new()
	l.thresholds = PackedFloat32Array([45.0, 15.0, -3.0, 30.0, 60.0, 90.0])
	assert_eq(Array(l.thresholds), [15.0, 30.0, 45.0, 60.0], "sorted, negatives dropped, 4 levels")
	l.start_step(&"a")
	for i in 400:
		l.update(20.0)
		l.progress()
	assert_lte(l.history.size(), HintLadder.HISTORY_MAX)
