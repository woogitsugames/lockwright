extends GutTest
## T42 / ONBOARDING §8: the first job of each v0.6 family runs a guided lesson (TutorialCoach with
## res://data/lessons/<family>.json). Checked here:
##   - the lesson data of all 8 families is valid and every line exists in the i18n tables;
##   - pure logic: the steps advance on their conditions, the trap interrupts and hands back, the
##     closing line shows on open, the auto variant (D-52) is used in auto mode;
##   - through the real scene, in both control modes: a scripted player (the family bots of
##     test_planb_*.gd) opens the first job, the steps advance in order, the save records the lesson,
##     and the next job of the family has only the faded (quiet) coach, later none;
##   - an idle player gets H1 → H4 in the lesson (chalk gesture at H2, the master hand at H4 does the step).

const HZ := 120
const FAMILIES := [&"dial_safe", &"combo", &"dimple", &"disc_detainer", &"egyptian", &"axial_slider", &"time_lock", &"magnetic"]
const LIFT := [&"dimple", &"egyptian", &"axial_slider", &"time_lock", &"magnetic"]
var _save_backup: Dictionary
var _settings_backup := {}


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)
	for k in ["auto_tension", "reduce_motion"]:
		_settings_backup[k] = Settings.get_value(k, false)


func after_all() -> void:
	for k in _settings_backup:
		Settings.set_value(k, _settings_backup[k])
	Save.data = _save_backup
	Save.save()
	JobRun.current_job = {}
	JobRun.mode = &"job"


func before_each() -> void:
	Save.data.erase("lessons")
	Settings.set_value("reduce_motion", false)


func _native(fam: StringName) -> bool:
	return ClassDB.class_exists("LockcoreSession") and LockcoreSession.rules_version(fam) > 0


static func _jobs(fam: StringName) -> Array:
	var out: Array = []
	for dir in ["res://data/jobs"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".json"):
				var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
				if JobRun.family_for(j) == fam:
					out.append(j)
	# career order (chapter, order, id), as the job list shows them: the family's first job is the one the
	# player meets first (D-111: sorting by id put a chapter 13 tier-3 lock in front of chapter 2's)
	var list_script: GDScript = load("res://scripts/ui/jobs_list.gd")
	out.sort_custom(list_script.job_before)
	return out


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


## The family's first job, opened as the player would (Settings decide the D-52 mode at start).
func _open(fam: StringName, auto: bool, job_i: int = 0) -> Node:
	Settings.set_value(&"auto_tension", auto)
	JobRun.start(_jobs(fam)[job_i])
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load(JobRun.lock_scene_path()).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(3)
	scene.set_physics_process(false)
	scene.sampler.set_physics_process(false)
	assert_eq(scene.sampler.auto_tension, auto, "%s: the scene reads the D-52 mode" % fam)
	return scene


func _step(scene: Node) -> void:
	scene.sampler._physics_process(1.0 / HZ)
	scene._physics_process(1.0 / HZ)


# ------------------------------------------------------------------ data
func test_lesson_data_of_every_new_family() -> void:
	for fam in FAMILIES:
		var l := TutorialCoach.load_lesson(fam)
		assert_false(l.is_empty(), "%s has a lesson" % fam)
		assert_eq(String(l.get("family", "")), String(fam))
		var keys: Array = []
		for st: Dictionary in l["steps"]:
			assert_true(st.has("id") and st.has("until"), "%s step has id + until" % fam)
			assert_true(String(st.get("thumb", "")) in ["left", "right", ""], "%s thumb" % fam)
			keys.append(st["text"])
			if st.has("text_auto"):
				keys.append(st["text_auto"])
		keys.append(l["trap"]["text"])
		keys.append(l["done"])
		for i in range(1, 6):
			assert_has(keys, "tutorial.%s.step%d" % [fam, i], "%s uses step%d" % [fam, i])
		assert_has(keys, "tutorial.%s.step1_auto" % fam, "%s has the auto variant of step 1" % fam)
		for k in keys:
			assert_true(I18n.has_key(StringName(k)), "%s: %s exists" % [fam, k])
		assert_true(String(l["right"]) in ["lift", "roll", "turn"], "%s right gesture" % fam)
	assert_false(TutorialCoach.has_lesson_for(&"pin_tumbler"), "the pin tumbler keeps its S1–S3")


# ------------------------------------------------------------------ pure logic
func _vm(states: Array, open: bool = false, stress: float = 0.0) -> Dictionary:
	var els := []
	for s in states:
		els.append({"state": s, "position": 0.0, "window_lo": 0.45, "window_hi": 0.55})
	return {"elements": els, "open": open, "stress": stress}


func _feed(c: TutorialCoach, vm: Dictionary, input: Dictionary, events: Array, left: bool, right: bool, s: float) -> void:
	for i in int(s * HZ):
		c.update(vm, input, events if i == 0 else [], left, right, 1.0 / HZ)


func _trap_vm(l: Dictionary) -> Dictionary:
	var tr: Dictionary = l["trap"]
	if not (tr.get("states", []) as Array).is_empty():
		return _vm(["set", String(tr["states"][0]), "free"])
	return _vm(["set", "bound", "free"], false, float(tr.get("stress_over", 0.0)) + 0.2)


func test_steps_trap_and_closing_line_pure_logic() -> void:
	for fam in FAMILIES:
		var l := TutorialCoach.load_lesson(fam)
		var c := TutorialCoach.new(0, false, false)
		c.set_lesson(l)
		var t := {"tension": 0.4, "pick_lift": 0.0}
		assert_eq(c.lesson_step_id(), &"hold")
		assert_eq(String(c.text_key()), "tutorial.%s.step1" % fam)
		assert_eq(c.lesson_thumb(), "left")
		_feed(c, _vm(["free", "free", "free"]), {"tension": 0.4, "pick_lift": 0.0}, [], true, false, 0.6)
		assert_eq(c.lesson_step_id(), &"move", "%s: held tension ends step 1" % fam)
		assert_eq(c.lesson_thumb(), "right")
		t = {"tension": 0.4, "pick_lift": 0.2}
		_feed(c, _vm(["bound", "free", "free"]), t, [], true, true, 0.5)
		assert_eq(c.lesson_step_id(), &"feel", "%s: moving the right thumb ends step 2" % fam)
		# the trap interrupts, stays up while it holds (and min_s after), then hands the step back
		var tr: Dictionary = l["trap"]
		_feed(c, _trap_vm(l), t, [{"kind": StringName(tr["events"][0])}] if not (tr.get("events", []) as Array).is_empty() else [], true, true, 1.0)
		assert_true(c.lesson_trap, "%s: the trap line is up" % fam)
		assert_eq(String(c.text_key()), "tutorial.%s.step4" % fam)
		_feed(c, _vm(["set", "bound", "free"]), t, [], true, true, 2.5)
		assert_false(c.lesson_trap, "%s: the trap line goes after the trap" % fam)
		assert_eq(c.lesson_step_id(), &"feel", "%s: back to the step it interrupted" % fam)
		var ev: String = l["steps"][2]["until"]["events"][0]
		_feed(c, _vm(["set", "bound", "free"]), t, [{"kind": StringName(ev)}], true, true, 0.1)
		assert_eq(c.lesson_step_id(), &"free", "%s: '%s' ends step 3" % [fam, ev])
		assert_eq(c.text_key(), &"", "%s: no line in the free step" % fam)
		_feed(c, _vm(["set", "set", "set"], true), t, [{"kind": &"open"}], true, true, 0.1)
		assert_eq(c.lesson_step_id(), &"done")
		assert_eq(String(c.text_key()), "tutorial.%s.step5" % fam, "%s: closing line on open" % fam)
		assert_eq(c.lesson_history.slice(0, 3), [&"hold", &"move", &"feel"] as Array[StringName])


func test_auto_mode_variant_and_lost_tension() -> void:
	for fam in FAMILIES:
		var l := TutorialCoach.load_lesson(fam)
		var a := TutorialCoach.new(0, false, true)
		a.set_lesson(l)
		assert_eq(String(a.text_key()), "tutorial.%s.step1_auto" % fam, "%s auto line" % fam)
		assert_eq(a.lesson_thumb(), "right", "%s: auto mode cues the right thumb" % fam)
		_feed(a, _vm(["free", "free"]), {"tension": 0.35, "pick_lift": 0.0}, [], false, true, 0.05)
		assert_eq(a.lesson_step_id(), &"move", "%s: the right thumb ends the auto step 1" % fam)
		# two thumbs: letting go of the left thumb brings step 1 back
		var c := TutorialCoach.new(0, false, false)
		c.set_lesson(l)
		_feed(c, _vm(["free"]), {"tension": 0.4, "pick_lift": 0.0}, [], true, false, 0.6)
		assert_eq(c.lesson_step_id(), &"move")
		_feed(c, _vm(["free"]), {"tension": 0.0, "pick_lift": 0.0}, [], false, false, 1.6)
		assert_eq(c.lesson_step_id(), &"hold", "%s: lost tension brings the first step back" % fam)
		# the faded coach: same steps, no lines
		var q := TutorialCoach.new(0, false, false)
		q.set_lesson(l, true)
		assert_eq(q.text_key(), &"", "%s: the faded coach writes nothing" % fam)
		assert_false(q.guided)


# ------------------------------------------------------------------ bots (from test_planb_*.gd)
## Lift families: left thumb holds ~72 dp, right thumb lifts one element at a time slowly.
func _play_lift(fam: StringName, scene: Node, auto: bool, max_s: float) -> bool:
	var s: InputSampler = scene.sampler
	var session: RefCounted = scene.session
	var sz := s._size()
	var left_x := sz.x * 0.2
	var n: int = session.describe()["elements"].size()
	var dt := 1.0 / HZ
	var left_y := 700.0
	var t_dp := 12.0 * 6
	var press_left := func() -> void:
		s._unhandled_input(_touch(0, Vector2(left_x, left_y), true))
		for i in 6:
			s._unhandled_input(_drag(0, Vector2(left_x, left_y - t_dp * (i + 1) / 6.0)))
	if not auto:
		press_left.call()
	var el := 0
	var lift_dp := 0.0
	var right_y := 760.0
	var pressed := false
	var cooldown := 0
	var speed := 50.0 if fam == &"magnetic" else 70.0
	for step in int(max_s * HZ):
		if cooldown > 0:
			cooldown -= 1
			if cooldown == 0 and not auto:
				press_left.call()
		var x := sz.x * 0.5 + sz.x * 0.5 * (el + 0.5) / n
		if not pressed:
			s._unhandled_input(_touch(1, Vector2(x, right_y), true))
			pressed = true
			lift_dp = 0.0
		else:
			lift_dp += speed * dt
			s._unhandled_input(_drag(1, Vector2(x, right_y - lift_dp)))
		s._physics_process(dt)
		scene._physics_process(dt)
		var vm: Dictionary = session.describe()
		if session.finished():
			return session.is_open()
		var next := lift_dp > 0.9 * InputSampler.LIFT_FULL_DP
		var oversets := 0
		var all_set := true
		for e in vm["elements"]:
			if String(e["state"]) in ["overset", "jammed"]:
				oversets += 1
			all_set = all_set and String(e["state"]) == "set"
		if all_set:
			s._unhandled_input(_touch(1, Vector2(x, right_y - lift_dp), false))
			pressed = true
			continue
		if String(vm["elements"][el]["state"]) == "set":
			next = true
		var caught := false
		for e in vm["elements"]:
			caught = caught or String(e["state"]) == "false_set"
		if not auto and cooldown == 0:
			var want := 0.17 * InputSampler.TENSION_FULL_DP if caught else t_dp
			s._unhandled_input(_drag(0, Vector2(left_x, left_y - want)))
		if oversets > 0 and cooldown == 0:
			next = true
			if auto:
				s._unhandled_input(_touch(0, Vector2(left_x, left_y), true))
				s._unhandled_input(_touch(0, Vector2(left_x, left_y), false))
			else:
				s._unhandled_input(_touch(0, Vector2(left_x, left_y - t_dp), false))
				cooldown = 24
		if next:
			s._unhandled_input(_touch(1, Vector2(x, right_y - lift_dp), false))
			pressed = false
			for k in n:
				el = (el + 1) % n
				if String(vm["elements"][el]["state"]) != "set":
					break
	return false


## Dial safe: right until wheel 0 is carried, stop on its gate; left for wheel 1; … ; then the mark.
func _play_dial(scene: Node, auto: bool, max_s: float) -> bool:
	var s: InputSampler = scene.sampler
	var session: RefCounted = scene.session
	var dt := 1.0 / HZ
	var right := Vector2(330, 700)
	var left := Vector2(80, 760)
	if not auto:
		s._unhandled_input(_touch(0, left, true))
		for i in 6:
			s._unhandled_input(_drag(0, left - Vector2(0, 0.40 * InputSampler.TENSION_FULL_DP * (i + 1) / 6.0)))
		for i in 80:  # the player settles the handle before turning (lesson step 1)
			s._physics_process(dt)
			scene._physics_process(dt)
	s._unhandled_input(_touch(1, right, true))
	var vm: Dictionary = session.describe()
	var n: int = vm["elements"].size()
	var div := int(vm["dial_divisions"])
	var phase := 0
	var start_pos := float(vm["elements"][0]["position"])
	var carried := false
	var settle := 0
	for step in int(max_s * HZ):
		vm = session.describe()
		var els: Array = vm["elements"]
		var speed := 0.0
		if phase < n:
			var dir := 1.0 if phase % 2 == 0 else -1.0
			var e: Dictionary = els[phase]
			var pos := float(e["position"])
			var g := fposmod((float(e["window_lo"]) + float(e["window_hi"])) * 0.5, 1.0)
			if not carried and absf(LockDialSafeView.wrap_half(pos - start_pos)) > 0.5 / div:
				carried = true
			var off: float = LockDialSafeView.wrap_half(pos - g)
			if carried and absf(off) < 0.3 / div:
				settle += 1
				if settle > 40 and String(e["state"]) == "set":
					phase += 1
					settle = 0
					carried = false
					if phase < n:
						start_pos = float(els[phase]["position"])
			else:
				var dist := fposmod((g - pos) * dir, 1.0) if carried else 1.0
				speed = dir * clampf(dist * 2.5, 0.09, 0.6)
		else:
			var dirf := 1.0 if (n - 1) % 2 == 1 else -1.0
			var dial := float(vm["dial"])
			if absf(LockDialSafeView.wrap_half(dial)) > 0.3 / div:
				speed = dirf * clampf(fposmod(-dial * dirf, 1.0) * 2.5, 0.09, 0.6)
		var defl: float = DialSafeControl.deflection_for(speed)
		s._unhandled_input(_drag(1, right - Vector2(0, defl * InputSampler.LIFT_FULL_DP)))
		s._physics_process(dt)
		scene._physics_process(dt)
		if session.finished():
			return session.is_open()
	return false


## Combo / disc detainer: pull, find the binding wheel, roll it slowly to its gate; a false notch is
## left by easing the pull.
func _play_combo(scene: Node, auto: bool, max_s: float) -> bool:
	var s: InputSampler = scene.sampler
	var session: RefCounted = scene.session
	var dt := 1.0 / HZ
	var half := 206.0
	var left := Vector2(80, 760)
	var pull := 0.34
	if not auto:
		s._unhandled_input(_touch(0, left, true))
		for i in 6:
			s._unhandled_input(_drag(0, left - Vector2(0, pull * InputSampler.TENSION_FULL_DP * (i + 1) / 6.0)))
		for i in 80:
			s._physics_process(dt)
			scene._physics_process(dt)
	var right_down := false
	var right := Vector2.ZERO
	var target := -1
	var ease_left := 0
	var unstick := -1
	for step in int(max_s * HZ):
		var vm: Dictionary = session.describe()
		var els: Array = vm["elements"]
		var n := els.size()
		var b := -1
		var caught := -1
		for i in n:
			var st := String(els[i]["state"])
			if st in ["bound", "near", "overset"]:
				b = i
			if st == "false_set":
				caught = i
		if caught >= 0 and ease_left == 0:
			ease_left = 60
			unstick = caught
			if not auto:
				s._unhandled_input(_drag(0, left - Vector2(0, 0.15 * InputSampler.TENSION_FULL_DP)))
		if ease_left > 0:
			ease_left -= 1
			if auto and ease_left == 48:
				s._unhandled_input(_touch(0, left, true))
				s._unhandled_input(_touch(0, left, false))
			if ease_left == 0:
				unstick = -1
				if not auto:
					s._unhandled_input(_drag(0, left - Vector2(0, pull * InputSampler.TENSION_FULL_DP)))
		var speed := 0.0
		if unstick >= 0:
			b = -1
			var ux := half + (float(unstick) + 0.5) / n * half
			if unstick != target or not right_down:
				if right_down:
					s._unhandled_input(_touch(1, right, false))
				right = Vector2(ux, 700)
				s._unhandled_input(_touch(1, right, true))
				right_down = true
				target = unstick
			if int(vm["pick_element"]) == unstick and ease_left < 56:
				var ue: Dictionary = els[unstick]
				var ug := fposmod((float(ue["window_lo"]) + float(ue["window_hi"])) * 0.5, 1.0)
				speed = signf(LockComboView.wrap_half(ug - float(ue["position"]))) * (0.9 if auto else 0.5)
		if b >= 0:
			var x := half + (float(b) + 0.5) / n * half
			if b != target or not right_down:
				if right_down:
					s._unhandled_input(_touch(1, right, false))
				right = Vector2(x, 700)
				s._unhandled_input(_touch(1, right, true))
				right_down = true
				target = b
			var e: Dictionary = els[b]
			var g := fposmod((float(e["window_lo"]) + float(e["window_hi"])) * 0.5, 1.0)
			var off: float = LockComboView.wrap_half(g - float(e["position"]))
			if int(vm["pick_element"]) == b:
				speed = signf(off) * clampf(absf(off) * 3.0, 0.12, 0.35)
		elif unstick < 0 and not right_down:
			# nothing binds yet: rest the right thumb on the first wheel (the lesson's step 2)
			right = Vector2(half + 0.5 / n * half, 700)
			s._unhandled_input(_touch(1, right, true))
			right_down = true
			target = 0
			speed = 0.15
		var defl: float = ComboControl.deflection_for(speed)
		if right_down:
			s._unhandled_input(_drag(1, right - Vector2(0, defl * InputSampler.LIFT_FULL_DP)))
		s._physics_process(dt)
		scene._physics_process(dt)
		if session.finished():
			return session.is_open()
	return false


func _play(fam: StringName, scene: Node, auto: bool, max_s: float = 120.0) -> bool:
	if fam == &"dial_safe":
		return _play_dial(scene, auto, max_s)
	if fam in [&"combo", &"disc_detainer"]:
		return _play_combo(scene, auto, max_s)
	return _play_lift(fam, scene, auto, max_s)


# ------------------------------------------------------------------ through the real scene
func _check_lesson_flow(fam: StringName) -> void:
	if not _native(fam):
		pending("needs the lockcore GDExtension v0.6")
		return
	for auto in [false, true]:
		Save.data.erase("lessons")
		var scene: Node = await _open(fam, auto)
		var coach: TutorialCoach = scene.coach
		var tag := "%s auto=%s" % [fam, auto]
		assert_not_null(coach, tag + ": coach")
		assert_true(coach.has_lesson() and not coach.lesson_quiet, tag + ": the first job is a lesson")
		assert_eq(scene.view.chalk_level, ChalkLayer.Level.FULL, tag + ": full chalk")
		assert_not_null(scene.hints, tag + ": hint ladder")
		var opened := _play(fam, scene, auto)
		for i in 30:  # the closing line holds the open for a moment
			_step(scene)
		assert_true(opened, tag + ": the scripted player opens the lesson lock")
		var h: Array = coach.lesson_history.filter(func(x: StringName) -> bool: return x != StringName(coach.lesson["trap"]["id"]))
		gut.p("%s: %s" % [tag, coach.lesson_history])
		var order := [&"hold", &"move", &"feel", &"free", &"done"]
		var last := -1
		for id in h:
			var k := order.find(id)
			if k < last and id == &"hold":
				last = 0  # two thumbs: a lost tension brings step 1 back — allowed
				continue
			assert_gte(k, last, tag + ": steps advance in order (%s)" % [h])
			last = k
		assert_eq(h.back(), &"done", tag + ": ends on the closing line")
		assert_has(h, &"move", tag + ": the right-thumb step showed")
		assert_true(TutorialCoach.lesson_done(fam), tag + ": the save records the lesson")
		# the next job of the family: the coach fades (quiet steps, reduced chalk), then none
		var again: Node = await _open(fam, auto, 0)
		assert_true(again.coach != null and again.coach.lesson_quiet, tag + ": the lesson runs only once")
		assert_eq(again.coach.text_key(), &"", tag + ": no lines after the lesson")
		assert_eq(again.view.chalk_level, ChalkLayer.Level.REDUCED, tag + ": reduced chalk while it fades")
		Save.set_value("lessons/%s/after" % fam, TutorialCoach.FADE_JOBS)
		var later: Node = await _open(fam, auto, 0)
		assert_null(later.coach, tag + ": no coach once it has faded")


func test_dial_safe_lesson() -> void:
	await _check_lesson_flow(&"dial_safe")


func test_combo_lesson() -> void:
	await _check_lesson_flow(&"combo")


func test_dimple_lesson() -> void:
	await _check_lesson_flow(&"dimple")


func test_disc_detainer_lesson() -> void:
	await _check_lesson_flow(&"disc_detainer")


func test_egyptian_lesson() -> void:
	await _check_lesson_flow(&"egyptian")


func test_axial_slider_lesson() -> void:
	await _check_lesson_flow(&"axial_slider")


func test_time_lock_lesson() -> void:
	await _check_lesson_flow(&"time_lock")


func test_magnetic_lesson() -> void:
	await _check_lesson_flow(&"magnetic")


## An idle player in the lesson: H1 15 s, H2 30 s (the chalk plays the family's gesture), H3 45 s
## (chalk), H4 60 s (the master hand shows the step; N-98: the lesson waits for the player), in both modes.
func test_hints_fire_in_every_lesson() -> void:
	for fam in FAMILIES:
		if not _native(fam):
			pending("needs the lockcore GDExtension v0.6")
			return
		for auto in [false, true]:
			Save.data.erase("lessons")
			var scene: Node = await _open(fam, auto)
			var hints: TutorialHints = scene.hints
			var coach: TutorialCoach = scene.coach
			var tag := "%s auto=%s" % [fam, auto]
			for i in int(30.2 * HZ):
				_step(scene)
			assert_eq(coach.lesson_step_id(), &"hold", tag + ": idle stays on step 1")
			assert_true(hints.chalk_hint.is_playing(), tag + ": H2 chalk plays the gesture")
			var g: Array = hints.gesture()
			assert_true(Vector2(g[0]).distance_to(g[1]) > 10.0 or float(g[3]) > 0.0, tag + ": the gesture moves or holds")
			var kind := hints.gesture_kind()
			assert_eq(kind, "tension" if not auto else String(coach.lesson["right"]), tag + ": gesture kind of step 1")
			for i in int(30.0 * HZ):
				_step(scene)
			var levels: Array = hints.ladder.history.map(func(e: Dictionary) -> int: return int(e["level"]))
			for lv in [1, 2, 3, 4]:
				assert_has(levels, lv, tag + ": H%d fired" % lv)
			assert_false(hints.h4_steps.is_empty(), tag + ": the master hand played")
			for i in int(6.0 * HZ):
				_step(scene)
			# N-98: the hint ladder escalates hints, not steps: after the master hand's demonstration the
			# lesson still waits for the player's own step 1
			assert_eq(coach.lesson_step_id(), &"hold", tag + ": the lesson waits for the player after H4 (%s)" % [coach.lesson_history])
			assert_lt(hints.held_tension, 0.0, tag + ": the lock is the player's again after the demonstration")
