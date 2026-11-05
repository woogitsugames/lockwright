extends GutTest
## N-61 / N-62 / D-52: the tutorial lock S1 opens with plain thumb input fed through the real
## InputSampler (touch events in dp) into lockcore, in both control modes, and the guided chalk
## steps appear in order. Uses the GDExtension when present (CI builds it), else FakeLockSession.
## S1–S3 are the authored locks of docs/LEVELS.md §2 (game/data/tutorial/*.json, create_from_json).

const HZ := 120
var LEFT_X := 80.0
var RIGHT_X0 := 206.0  # right zone starts at half of the viewport width
var RIGHT_W := 206.0


func _touch(idx: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var t := InputEventScreenTouch.new()
	t.index = idx
	t.position = pos
	t.pressed = pressed
	return t


func _drag(idx: int, pos: Vector2) -> InputEventScreenDrag:
	var d := InputEventScreenDrag.new()
	d.index = idx
	d.position = pos
	return d


func _session(sd: int = -1, tier: int = 1, spec: String = "") -> RefCounted:
	if sd < 0:
		sd = JobRun.seed_for({"id": "tutorial.s1"})
	var scene := load("res://scripts/photoreal/lock_photoreal.gd")
	if spec != "":
		return scene.make_spec_session(spec, &"pin_tumbler", sd, tier)
	return scene.make_session(&"pin_tumbler", sd, tier)


func _native() -> bool:
	return ClassDB.class_exists("LockcoreSession")


## A patient beginner: left thumb dragged ~70 dp up and held (unless auto), right thumb pressed
## under one pin at a time and dragged up slowly; on a click it lets go and tries the next pin,
## on "too high" it lets go of the tension for a moment. Returns [opened, seconds, coach].
func _play(auto: bool, max_s: float = 90.0, sd: int = -1, tier: int = 1, spec: String = JobRun.TUTORIAL_SPECS[0]) -> Array:
	var s := InputSampler.new()
	add_child_autofree(s)
	s.auto_tension = auto
	var sz := s._size()
	LEFT_X = sz.x * 0.2
	RIGHT_X0 = sz.x * 0.5
	RIGHT_W = sz.x * 0.5
	var session := _session(sd, tier, spec)
	var coach := TutorialCoach.new(0, true, auto)
	var n: int = session.describe().get("elements", session.describe().get("pins", [])).size()
	var dt := 1.0 / HZ
	var left_y := 700.0
	if not auto:
		s._unhandled_input(_touch(0, Vector2(LEFT_X, left_y), true))
		for i in 6:
			s._unhandled_input(_drag(0, Vector2(LEFT_X, left_y - 12.0 * (i + 1))))
	var pin := 0
	var lift_dp := 0.0
	var right_y := 760.0
	var pressed := false
	var cooldown := 0
	for step in int(max_s * HZ):
		if cooldown > 0:
			cooldown -= 1
			if cooldown == 0 and not auto:
				s._unhandled_input(_touch(0, Vector2(LEFT_X, left_y), true))
				for i in 6:
					s._unhandled_input(_drag(0, Vector2(LEFT_X, left_y - 12.0 * (i + 1))))
		var x := RIGHT_X0 + RIGHT_W * (pin + 0.5) / n
		if not pressed:
			s._unhandled_input(_touch(1, Vector2(x, right_y), true))
			pressed = true
			lift_dp = 0.0
		else:
			lift_dp += 70.0 * dt  # ≈ 0.35 lift per second: slow, like the chalk says
			s._unhandled_input(_drag(1, Vector2(x, right_y - lift_dp)))
		s._physics_process(dt)
		var inp := s.sample()
		var ev: Array = session.step(inp["tension"], inp["pick_depth"], inp["pick_lift"])
		var vm: Dictionary = session.describe()
		coach.update(vm, inp, ev, s.left_down(), s.right_down(), dt)
		if OS.has_environment("LW_DEBUG") and step % 60 == 0:
			print("t=%.1f pin=%d in=%s vm=%s" % [step / 120.0, pin, inp, vm["elements"].map(func(e): return "%s@%.2f[%.2f-%.2f]" % [e["state"], e["position"], e.get("window_lo", 0), e.get("window_hi", 0)])])
		var next := lift_dp > 0.9 * InputSampler.LIFT_FULL_DP
		for e in ev:
			if e["kind"] == &"set":
				next = true
			if e["kind"] == &"overset":
				next = true
				if auto:
					s._unhandled_input(_touch(0, Vector2(LEFT_X, left_y), true))
					s._unhandled_input(_touch(0, Vector2(LEFT_X, left_y), false))
				else:
					s._unhandled_input(_touch(0, Vector2(LEFT_X, left_y - 72.0), false))
					cooldown = 24
		if next:
			s._unhandled_input(_touch(1, Vector2(x, right_y - lift_dp), false))
			pressed = false
			# a sensible player can see which pins already sit on the shear line: skip them
			for k in n:
				pin = (pin + 1) % n
				if String(vm["elements"][pin]["state"]) != "set":
					break
		if session.is_open():
			coach.update(vm, inp, [], s.left_down(), s.right_down(), dt)
			return [true, step / float(HZ), coach]
	return [false, max_s, coach]


func test_s1_opens_with_two_thumbs() -> void:
	var r := _play(false)
	gut.p("two thumbs: %s" % [r])
	assert_true(r[0], "S1 must open with a held left thumb and a slow right thumb")
	assert_lt(r[1], 60.0, "S1 target 20–40 s for a novice; the patient bot needs %.1f s" % r[1])
	var c: TutorialCoach = r[2]
	var want := [TutorialCoach.Step.TENSION, TutorialCoach.Step.PICK, TutorialCoach.Step.BINDING, TutorialCoach.Step.CLICK]
	assert_eq(c.history.slice(0, 4), want, "steps 1–4 in order (N-61): %s" % [c.history])
	assert_eq(c.history.back(), TutorialCoach.Step.OPEN)


func test_s1_opens_in_auto_tension_with_right_thumb_only() -> void:
	var r := _play(true)
	assert_true(r[0], "D-52: S1 must open with the right thumb alone in auto-tension mode")
	var c: TutorialCoach = r[2]
	assert_eq(c.history[0], TutorialCoach.Step.PICK, "auto mode skips the left-thumb step")
	assert_false(c.history.has(TutorialCoach.Step.TENSION))
	assert_eq(c.history.back(), TutorialCoach.Step.OPEN)


func test_authored_tutorial_locks_load() -> void:
	# LEVELS.md §2: S1 one pin (window 0.20), S2 and S3 three pins (windows 0.16 / 0.12)
	if not _native():
		pending("LockcoreSession GDExtension not loaded (FakeLockSession plays generated t1)")
		return
	var want := [["pin.s1", 1, 0.20], ["pin.s2", 3, 0.16], ["pin.s3", 3, 0.12]]
	for i in 3:
		var s: RefCounted = ClassDB.instantiate("LockcoreSession")
		assert_true(s.create_from_json(FileAccess.get_file_as_string(JobRun.TUTORIAL_SPECS[i])), "%s parses" % want[i][0])
		assert_eq(s.spec_id(), want[i][0])
		var els: Array = s.describe()["elements"]
		assert_eq(els.size(), want[i][1], "%s pin count" % want[i][0])
		assert_almost_eq(float(els[0]["window_hi"]) - float(els[0]["window_lo"]), want[i][2], 0.002, "%s shear window" % want[i][0])
	JobRun.start_tutorial(1)
	assert_eq(JobRun.current_job.get("lock_spec", ""), JobRun.TUTORIAL_SPECS[1], "tutorial stage carries its authored lock")
	JobRun.current_job = {}
	JobRun.mode = &"job"


func test_create_from_json_rejects_a_bad_file() -> void:
	if not _native():
		pending("LockcoreSession GDExtension not loaded")
		return
	var s: RefCounted = ClassDB.instantiate("LockcoreSession")
	var bad := FileAccess.get_file_as_string(JobRun.TUTORIAL_SPECS[0]).replace("\"win_shear_q16\": 13107", "\"win_shear_qq16\": 13107")
	assert_false(s.create_from_json(bad), "strict parser: unknown / missing key fails")
	assert_gt(s.last_errors().size(), 0)
	assert_false(s.create_from_json("{"), "broken JSON fails")
	assert_true(s.describe().is_empty(), "no session after a failed parse")


func test_tutorial_stages_and_early_jobs_open_in_both_modes() -> void:
	# authored S1–S3 and the first tier-1/2 jobs: the same patient input opens them (D-52 both modes)
	for spec in JobRun.TUTORIAL_SPECS:
		for auto in [false, true]:
			var r := _play(auto, 120.0, -1, 1, spec)
			assert_true(r[0], "%s auto=%s should open (%.1f s)" % [spec.get_file(), auto, r[1]])
	for tier in [1, 2]:
		for sd in [1, 7, 42]:
			for auto in [false, true]:
				var r := _play(auto, 120.0, sd, tier, "")
				assert_true(r[0], "tier %d seed %d auto=%s should open (%.1f s)" % [tier, sd, auto, r[1]])


func test_lift_without_tension_never_sets_and_shows_hint() -> void:
	# N-58: a right thumb alone (two-thumb mode) moves pins but sets nothing; after 2 s the
	# chalk hint asks for the left thumb
	var s := InputSampler.new()
	add_child_autofree(s)
	s.auto_tension = false
	var session := _session(-1, 1, JobRun.TUTORIAL_SPECS[0])
	var coach := TutorialCoach.new(0, false, false)
	var rx := s._size().x * 0.75
	s._unhandled_input(_touch(1, Vector2(rx, 760), true))
	var sets := 0
	for step in 4 * HZ:
		s._unhandled_input(_drag(1, Vector2(rx, 760 - minf(step, 120))))
		s._physics_process(1.0 / HZ)
		var inp := s.sample()
		var ev: Array = session.step(inp["tension"], inp["pick_depth"], inp["pick_lift"])
		sets += ev.filter(func(e: Dictionary) -> bool: return e["kind"] == &"set").size()
		coach.update(session.describe(), inp, ev, s.left_down(), s.right_down(), 1.0 / HZ)
	assert_eq(sets, 0, "no tension, no set")
	assert_true(coach.hint_tension, "N-58 chalk hint after ~2 s of lifting with no tension")
	assert_eq(coach.text_key(), &"lock.hint_tension")


func test_tension_step_does_not_pass_without_binding() -> void:
	var coach := TutorialCoach.new(0, true, false)
	var vm := {"elements": [{"state": &"free"}, {"state": &"free"}], "pick_element": 0}
	for i in 240:
		coach.update(vm, {"tension": 0.0, "pick_lift": 0.4}, [], false, true, 1.0 / HZ)
	assert_eq(coach.step, TutorialCoach.Step.TENSION, "S1 step 1 waits for real tension")


func test_step_texts_exist_in_pl_en_de() -> void:
	for key in ["tutorial.s1_tension", "tutorial.s1_pick", "tutorial.s1_binding", "tutorial.s1_click",
			"tutorial.s1_overset", "tutorial.s1_overset_auto", "tutorial.s1_open", "lock.hint_tension",
			"lock.zone_tension", "lock.flap_pause", "tutorial.frame_tension", "tutorial.frame_lift",
			"tutorial.frame_click", "tutorial.frame_lift_auto", "tutorial.note_game"]:
		for loc in ["pl", "en", "de"]:
			TranslationServer.set_locale(loc)
			assert_ne(TranslationServer.translate(key), key, "missing %s: %s" % [loc, key])
	TranslationServer.set_locale("en")
