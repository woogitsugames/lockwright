extends GutTest
## D-80: hints are chalk-only (the G23 ghost hand of D-76/D-77 is gone). ChalkHint draws a chalk
## touch ring and a chalk trail drawn on along the gesture (H2), follows the virtual touch point of
## the master hand (H4: the game moves the tool itself), shows static chalk with Reduce Motion, never
## takes a touch, and keeps every mark inside the safe area and off the tension wrench (N-73).
## The scene part checks every hint element (H2 trail + ring, H3 chalk thumbs + arrows, H4 trail +
## ring, off the wrench and the loupe) against the safe area in 412x915 and 915x412, for the pin tutorial and three plan-B lessons,
## in both D-52 control modes.

const HZ := 120
const LESSONS := [&"combo", &"dial_safe", &"magnetic"]
## Safe-area insets (dp: left, top, right, bottom) of a phone with a notch and a gesture bar.
const INSETS := {Vector2i(412, 915): Vector4(0, 32, 0, 24), Vector2i(915, 412): Vector4(40, 0, 40, 20)}

var _save_backup: Dictionary
var _settings_backup := {}


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)
	for k in ["auto_tension", "reduce_motion"]:
		_settings_backup[k] = Settings.get_value(k, false)


func after_all() -> void:
	for k in _settings_backup:
		Settings.set_value(k, _settings_backup[k])
	SafeArea.override_dp = SafeArea.OVERRIDE_OFF
	Save.data = _save_backup
	Save.save()
	JobRun.current_job = {}
	JobRun.mode = &"job"


func after_each() -> void:
	SafeArea.override_dp = SafeArea.OVERRIDE_OFF


# ------------------------------------------------------------------ unit
func _hint(size := Vector2(412, 915)) -> ChalkHint:
	var parent := Control.new()
	parent.size = size
	add_child_autofree(parent)
	var h := ChalkHint.new()
	parent.add_child(h)
	h.bounds = Rect2(Vector2.ZERO, size)
	return h


func _run(h: ChalkHint, seconds: float, dt := 1.0 / 120.0) -> void:
	for i in int(seconds / dt):
		h.advance(dt)


func test_gesture_draws_the_trail_on_then_fades() -> void:
	var h := _hint()
	assert_eq(h.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never takes a touch")
	assert_eq(h.material, ChalkLayer.grain_material(), "the same chalk grain as the lesson lines")
	assert_between(ChalkHint.FADE_S, 0.1, 0.25, "DESIGN: animations 100-250 ms")
	var progress: Array[float] = []
	h.gesture_progress.connect(func(t: float) -> void: progress.append(t))
	var finished := [false]
	h.gesture_finished.connect(func() -> void: finished[0] = true)
	h.play_gesture(Vector2(200, 700), Vector2(200, 600), 0.6, 1)
	assert_true(h.is_playing())
	assert_false(h.is_static())
	_run(h, ChalkHint.FADE_S + 0.3)
	assert_gt(h.trail.size(), 3, "the trail is drawn on behind the ring")
	assert_lt(h.touch_point.y, 700.0)
	assert_gt(h.touch_point.y, 600.0, "half way the ring is between start and end")
	_run(h, 0.32)
	assert_almost_eq(h.touch_point.y, 600.0, 0.5, "the ring ends on the gesture's end")
	assert_true(progress.size() > 10 and progress.max() >= 1.0, "progress 0..1 for the scene's answer")
	_run(h, ChalkHint.FADE_S + 0.05)
	assert_false(h.is_playing(), "then the chalk fades out")
	assert_true(finished[0])
	assert_eq(h.drawn_rect(), Rect2(), "nothing drawn when idle")


func test_hold_and_repeats() -> void:
	var h := _hint()
	h.play_gesture(Vector2(100, 700), Vector2(100, 640), 0.3, 2, 0.5)
	_run(h, ChalkHint.FADE_S + 0.35)
	assert_true(h._holding, "the hold shows the inner ring")
	_run(h, 0.5 + ChalkHint.FADE_S + 0.05)
	assert_true(h.is_playing(), "second repeat")
	assert_lt(h.trail.size(), 4, "the second repeat starts a new trail at the start pose")
	_run(h, 0.3 + 0.5 + ChalkHint.FADE_S + 0.05)
	assert_false(h.is_playing())


func test_reduce_motion_draws_static_chalk() -> void:
	var h := _hint()
	h.reduce_motion = true
	var progress := []
	h.gesture_progress.connect(func(t: float) -> void: progress.append(t))
	h.play_gesture(Vector2(200, 700), Vector2(200, 600), 0.6, 2)
	assert_true(h.is_static(), "Reduce Motion: static chalk")
	assert_eq(h.trail.size(), 2, "the whole path at once")
	var at := h.touch_point
	_run(h, 0.8)
	assert_eq(h.touch_point, at, "nothing travels")
	assert_eq(progress.size(), 0, "no animated answer")
	_run(h, 2.0)
	assert_false(h.is_playing(), "and it goes away after the gesture's time")
	h.begin_follow(Vector2(100, 700), Vector2(100, 600))
	h.follow(Vector2(100, 650))
	assert_eq(h.trail.size(), 2, "H4 with Reduce Motion: the planned path, static")
	h.end_follow()
	_run(h, ChalkHint.FADE_S + 0.05)
	assert_false(h.is_playing())


func test_follow_tracks_the_virtual_touch() -> void:
	var h := _hint()
	h.begin_follow(Vector2(100, 760), Vector2(100, 690))
	_run(h, ChalkHint.FADE_S)
	for i in 20:
		h.follow(Vector2(100, 760 - i * 3.5))
	assert_almost_eq(h.touch_point.y, 760.0 - 19 * 3.5, 0.01, "the ring sits on the last touch point")
	assert_gt(h.trail.size(), 10, "the trail follows it")
	h.end_follow()
	h.follow(Vector2(100, 300))
	assert_ne(h.touch_point.y, 300.0, "no following after the master hand is done")
	_run(h, ChalkHint.FADE_S + 0.05)
	assert_false(h.is_playing())


func test_clamped_inside_bounds_and_off_the_wrench() -> void:
	var h := _hint()
	h.bounds = Rect2(0, 32, 412, 915 - 56)
	# N-73: the last element's column sits at 0.95 of the width; the ring used to leave the screen
	h.play_gesture(Vector2(405, 900), Vector2(405, 790), 0.5, 1)
	for i in 120:
		h.advance(1.0 / 120.0)
		if h.drawn_rect().size != Vector2.ZERO:
			assert_true(h.bounds.encloses(h.drawn_rect()), "inside the safe area: %s" % h.drawn_rect())
	var wrench := Rect2(10, 500, 90, 90)
	h.avoid = [wrench]
	h.begin_follow(Vector2(55, 545), Vector2(55, 480))
	_run(h, ChalkHint.FADE_S)
	h.follow(Vector2(55, 545))
	var ring := Rect2(h.touch_point - Vector2.ONE * ChalkHint.RING_R, Vector2.ONE * 2.0 * ChalkHint.RING_R)
	assert_false(ring.intersects(wrench), "the ring is pushed off the wrench (%s)" % ring)
	assert_true(h.bounds.encloses(h.drawn_rect()))


func test_mirror_for_swapped_thumbs() -> void:
	var h := _hint()
	h.mirror = true
	h.play_gesture(Vector2(100, 700), Vector2(100, 640), 0.3, 1)
	assert_almost_eq(h.touch_point.x, 312.0, 0.01, "left-handed: the other thumb zone")


func test_no_ghost_hand_left_in_the_game() -> void:
	assert_false(ResourceLoader.exists("res://scripts/tutorial/ghost_hand.gd"), "GhostHand removed (D-80)")
	assert_false(DirAccess.dir_exists_absolute("res://assets/ui/ghost"), "G23 silhouettes are not in the game")


# ------------------------------------------------------------------ scene: safe area
func _open_tutorial(auto: bool, size: Vector2i) -> Node:
	Settings.set_value(&"auto_tension", auto)
	JobRun.start_tutorial(0)
	return await _mount("res://scenes/lock_job.tscn", size)


func _open_lesson(fam: StringName, auto: bool, size: Vector2i) -> Node:
	Settings.set_value(&"auto_tension", auto)
	Save.data.erase("lessons")
	var job := {}
	var files := Array(DirAccess.get_files_at("res://data/jobs"))
	files.sort()
	for f in files:
		if String(f).ends_with(".json"):
			var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + f))
			if JobRun.family_for(j) == fam and (job.is_empty() or String(j["id"]) < String(job["id"])):
				job = j
	JobRun.start(job)
	return await _mount(JobRun.lock_scene_path(), size)


func _mount(path: String, size: Vector2i) -> Node:
	SafeArea.override_dp = INSETS[size]
	Settings.set_value("reduce_motion", false)
	var vp := SubViewport.new()
	vp.size = size
	add_child_autofree(vp)
	var scene: Node = load(path).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(3)
	scene.set_physics_process(false)
	scene.sampler.set_physics_process(false)
	return scene


func _step(scene: Node, seconds: float, check: Callable = Callable()) -> void:
	for i in int(seconds * HZ):
		scene.sampler._physics_process(1.0 / HZ)
		scene._physics_process(1.0 / HZ)
		if scene.hints != null:
			scene.hints.chalk_hint.advance(1.0 / HZ)
		if check.is_valid() and i % 4 == 0:
			check.call()


func _safe(scene: Node) -> Rect2:
	var v: Control = scene.view
	return SafeArea.shrink(v, Rect2(Vector2.ZERO, v.size))


func _check_hint_inside(scene: Node, tag: String) -> void:
	var safe := _safe(scene)
	var h: ChalkHint = scene.hints.chalk_hint
	var r := h.drawn_rect()
	if r.size != Vector2.ZERO:
		assert_true(safe.encloses(r), "%s: chalk ring/trail %s inside the safe area %s" % [tag, r, safe])
		var ring := Rect2(h.touch_point - Vector2.ONE * ChalkHint.RING_R, Vector2.ONE * 2.0 * ChalkHint.RING_R)
		assert_false(ring.intersects(scene.view.section_rect), "%s: the ring stays off the lock section %s" % [tag, scene.view.section_rect])
	var chalk: ChalkLayer = scene.view._chalk
	for m: Dictionary in chalk.hint_marks():
		assert_true(safe.encloses(m["rect"]), "%s: chalk thumb %s %s inside the safe area %s" % [tag, m["kind"], m["rect"], safe])


func _check_ladder(scene: Node, tag: String) -> void:
	var hints: TutorialHints = scene.hints
	assert_not_null(hints, tag + ": hints run")
	if hints == null:
		return
	_step(scene, 1.0)
	hints.ladder.update(29.5)  # H1 + H2 (the ladder's own timing; the scene keeps stepping)
	_step(scene, 0.1)
	assert_eq(hints.ladder.level, 2, tag + ": H2")
	assert_true(hints.chalk_hint.is_playing(), tag + ": H2 chalk gesture plays")
	assert_false(hints.chalk_hint.is_static(), tag + ": animated (no Reduce Motion)")
	assert_null(scene.view.get_node_or_null("GhostHand"), tag + ": no ghost hand")
	var seen := [0]
	_step(scene, 3.0, func() -> void:
		if hints.chalk_hint.is_playing():
			seen[0] += 1
		_check_hint_inside(scene, tag + " H2"))
	assert_gt(seen[0], 10, tag + ": H2 was checked while drawn")
	hints.ladder.update(15.0)  # H3
	_step(scene, 0.5, func() -> void: _check_hint_inside(scene, tag + " H3"))
	assert_ne(scene.view.hint_arrows, "", tag + ": H3 chalk arrows")
	hints.ladder.update(15.0)  # H4
	_step(scene, 0.05)
	assert_false(hints.h4_steps.is_empty(), tag + ": H4 fired")
	assert_eq(hints.chalk_hint.mode, ChalkHint.Mode.FOLLOW, tag + ": H4 chalk follows the master hand")
	var face = scene.view.get("_face")
	var points := {}
	_step(scene, 3.0, func() -> void:
		_check_hint_inside(scene, tag + " H4")
		var hh: ChalkHint = hints.chalk_hint
		if hh.is_playing() and hh.alpha > 0.0:
			points[Vector2i(hh.touch_point)] = true
			if face is Control and face.visible:
				var ring := Rect2(hh.touch_point - Vector2.ONE * ChalkHint.RING_R, Vector2.ONE * 2.0 * ChalkHint.RING_R)
				assert_false(ring.intersects(Rect2(face.position, face.size)), "%s H4: the ring stays off the tension wrench" % tag)
			var lr: Rect2 = scene.view.loupe_rect()
			if lr.size.x > 0.0:
				var ring2 := Rect2(hh.touch_point - Vector2.ONE * ChalkHint.RING_R, Vector2.ONE * 2.0 * ChalkHint.RING_R)
				assert_false(ring2.intersects(lr), "%s H4: the ring stays off the loupe %s (%s)" % [tag, lr, ring2]))
	assert_gt(points.size(), 0, tag + ": H4 drew the ring")


func test_hints_inside_the_safe_area_tutorial() -> void:
	for size: Vector2i in INSETS:
		for auto in [false, true]:
			var scene := await _open_tutorial(auto, size)
			_check_ladder(scene, "pin S1 %dx%d auto=%s" % [size.x, size.y, auto])


func test_hints_inside_the_safe_area_lessons() -> void:
	for fam in LESSONS:
		if not (ClassDB.class_exists("LockcoreSession") and LockcoreSession.rules_version(fam) > 0):
			pending("needs the lockcore GDExtension v0.6")
			return
		for size: Vector2i in INSETS:
			for auto in [false, true]:
				var scene := await _open_lesson(fam, auto, size)
				_check_ladder(scene, "%s %dx%d auto=%s" % [fam, size.x, size.y, auto])
