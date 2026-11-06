extends GutTest
## N-63: plan-B lock screens of the wafer and lever families (scenes/photoreal/lock_job_<family>.tscn).
## A patient player (the pin S1 bot of test_tutorial_s1.gd) opens every job of the family through
## the real scene: touch events in dp → InputSampler → lockcore → LockWaferView / LockLeverView,
## in both control modes of D-52; the layout fits portrait and landscape.

const HZ := 120
const SCENES := {
	&"wafer": "res://scenes/photoreal/lock_job_wafer.tscn",
	&"lever": "res://scenes/photoreal/lock_job_lever.tscn",
	&"lever_detector": "res://scenes/photoreal/lock_job_lever_detector.tscn",
}
var _save_backup: Dictionary


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)


func after_all() -> void:
	Save.data = _save_backup
	Save.save()
	JobRun.current_job = {}


func _jobs(fam: StringName) -> Array:
	var out: Array = []
	for dir in ["res://data/jobs", "res://data/jobs_ch7"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".json"):
				var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
				if JobRun.family_for(j) == fam:
					out.append(j)
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


func _open_scene(fam: StringName, size: Vector2i) -> Node:
	var vp := SubViewport.new()
	vp.size = size
	add_child_autofree(vp)
	var scene: Node = load(SCENES[fam]).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(3)
	return scene


## Left thumb ~70 dp up and held (unless auto); right thumb under one element at a time, dragged up
## slowly; on a set it lets go and tries the next unset one, on an overset it lets go of the
## tension for a moment. Returns [opened, seconds].
func _play(fam: StringName, job: Dictionary, auto: bool, max_s: float = 120.0) -> Array:
	JobRun.start(job)
	var scene: Node = await _open_scene(fam, Vector2i(412, 915))
	scene.set_physics_process(false)
	var s: InputSampler = scene.sampler
	s.set_physics_process(false)
	s.auto_tension = auto
	var session: RefCounted = scene.session
	var sz := s._size()
	var left_x := sz.x * 0.2
	var right_x0 := sz.x * 0.5
	var right_w := sz.x * 0.5
	var n: int = session.describe()["elements"].size()
	var dt := 1.0 / HZ
	var left_y := 700.0
	var press_left := func() -> void:
		s._unhandled_input(_touch(0, Vector2(left_x, left_y), true))
		for i in 6:
			s._unhandled_input(_drag(0, Vector2(left_x, left_y - 12.0 * (i + 1))))
	if not auto:
		press_left.call()
	var el := 0
	var lift_dp := 0.0
	var right_y := 760.0
	var pressed := false
	var cooldown := 0
	var resets := 0
	# Detector lock (LOCKS.md §2.8): any lever lifted past its gate trips the detector, and the
	# third trip blocks the lock. A patient player only lifts the lever that visibly bears on the
	# stump ("bound"): never a free one blindly to the top, as on the plain lever lock.
	var careful := fam == &"lever_detector"
	var eased := false
	for step in int(max_s * HZ):
		if cooldown > 0:
			cooldown -= 1
			if cooldown == 0 and not auto:
				press_left.call()
				eased = false
		if careful and not pressed:
			var b := _bound_index(session.describe())
			if b < 0:
				s._physics_process(dt)
				scene._physics_process(dt)
				if session.is_open() or session.finished():
					return [session.is_open(), step * dt]
				continue
			el = b
		var x := right_x0 + right_w * (el + 0.5) / n
		if not pressed:
			s._unhandled_input(_touch(1, Vector2(x, right_y), true))
			pressed = true
			lift_dp = 0.0
		else:
			lift_dp += 70.0 * dt
			s._unhandled_input(_drag(1, Vector2(x, right_y - lift_dp)))
		s._physics_process(dt)
		scene._physics_process(dt)
		var vm: Dictionary = session.describe()
		if String(vm["elements"][0]["state"]) == "jammed":
			# detector tripped: let go, turn the key back (left thumb down / held in auto) until reset
			s._unhandled_input(_touch(1, Vector2(x, right_y - lift_dp), false))
			pressed = false
			s._unhandled_input(_touch(0, Vector2(left_x, left_y), false))
			s._unhandled_input(_touch(0, Vector2(left_x, left_y), true))
			if not auto:
				s._unhandled_input(_drag(0, Vector2(left_x, left_y + 60.0)))
			var guard := 0
			while String(session.describe()["elements"][0]["state"]) == "jammed" and guard < 6 * HZ and not session.finished():
				guard += 1
				s._physics_process(dt)
				scene._physics_process(dt)
			s._unhandled_input(_touch(0, Vector2(left_x, left_y + 60.0), false))
			resets += 1
			if session.finished():
				return [session.is_open(), step * dt]
			if not auto:
				press_left.call()
				eased = false
			continue
		if OS.has_environment("LW_DEBUG") and step % 120 == 0:
			print("t=%.0f el=%d T=%.2f lift=%.2f resets=%d %s" % [step * dt, el, s.sample()["tension"], s.sample()["pick_lift"], resets, vm["elements"].map(func(e): return "%s@%.2f[%.2f-%.2f]" % [e["state"], e["position"], e["window_lo"], e["window_hi"]])])
		var next := lift_dp > 0.9 * InputSampler.LIFT_FULL_DP
		if careful and not auto and cooldown == 0:
			# false gate (LOCKS.md §2.7): ease the left thumb into the counter-rotation band
			# (0.12–0.21) while lifting, back to the working tension once the lever is out
			var spool := String(vm["elements"][el]["state"]) == "false_set"
			if spool != eased:
				eased = spool
				s._unhandled_input(_drag(0, Vector2(left_x, left_y - (34.0 if spool else 72.0))))
		if careful and String(vm["elements"][el]["state"]) == "free":
			next = true  # the lever let go of the stump (dropped or lost binding): look again
		var oversets := 0
		if session.is_open():
			return [true, step * dt]
		if session.finished():
			return [false, step * dt]
		for e in vm["elements"]:
			if String(e["state"]) == "overset":
				oversets += 1
		if String(vm["elements"][el]["state"]) == "set":
			next = true
		if oversets > 0 and cooldown == 0:
			next = true
			if auto:
				s._unhandled_input(_touch(0, Vector2(left_x, left_y), true))
				s._unhandled_input(_touch(0, Vector2(left_x, left_y), false))
			else:
				s._unhandled_input(_touch(0, Vector2(left_x, left_y - 72.0), false))
				cooldown = 24
		if next:
			s._unhandled_input(_touch(1, Vector2(x, right_y - lift_dp), false))
			pressed = false
			for k in n:
				el = (el + 1) % n
				if String(vm["elements"][el]["state"]) != "set":
					break
	return [false, max_s]


## Lever that bears on the stump now (lockcore "bound", or caught in a false gate), or -1.
func _bound_index(vm: Dictionary) -> int:
	var els: Array = vm["elements"]
	for i in els.size():
		if String(els[i]["state"]) in ["bound", "false_set"]:
			return i
	return -1


func _check_family(fam: StringName) -> void:
	if not ClassDB.class_exists("LockcoreSession"):
		pending("needs the lockcore GDExtension")
		return
	var jobs := _jobs(fam)
	assert_gt(jobs.size(), 0, "jobs of %s exist" % fam)
	for job in jobs:
		for auto in [false, true]:
			var r: Array = await _play(fam, job, auto)
			gut.p("%s %s auto=%s: open=%s %.1f s" % [fam, job["id"], auto, r[0], r[1]])
			assert_true(r[0], "%s (%s, auto=%s) opens through the plan-B view (%.1f s)" % [job["id"], fam, auto, r[1]])


func test_every_wafer_job_opens_in_both_modes() -> void:
	await _check_family(&"wafer")


func test_every_lever_job_opens_in_both_modes() -> void:
	await _check_family(&"lever")


func test_every_lever_detector_job_opens_in_both_modes() -> void:
	# lockcore lever_detector (t5–t6) has 5 levers; the family unlocks with its own 5-lever
	# model in assets/photoreal_families/lever_detector/ (N-68, JobRun.planb_ready).
	if not JobRun.planb_ready(&"lever_detector"):
		pending("lever_detector waits for a 5-lever plan-B model")
		return
	await _check_family(&"lever_detector")


## N-72: the reset path of the detector through the real scene: a free lever lifted blindly to
## the top trips the detector (all levers jammed); letting go and turning back (left thumb down,
## or held in D-52 auto) for reset_steps frees the levers again.
func test_lever_detector_trip_resets_in_both_modes() -> void:
	if not ClassDB.class_exists("LockcoreSession") or not JobRun.planb_ready(&"lever_detector"):
		pending("needs the lockcore GDExtension and the 5-lever plan-B model")
		return
	var job: Dictionary = _jobs(&"lever_detector")[0]
	for auto in [false, true]:
		JobRun.start(job)
		var scene: Node = await _open_scene(&"lever_detector", Vector2i(412, 915))
		scene.set_physics_process(false)
		var s: InputSampler = scene.sampler
		s.set_physics_process(false)
		s.auto_tension = auto
		var session: RefCounted = scene.session
		var sz := s._size()
		var n: int = session.describe()["elements"].size()
		var left := Vector2(sz.x * 0.2, 700.0)
		var dt := 1.0 / HZ
		s._unhandled_input(_touch(0, left, true))
		if not auto:
			for i in 6:
				s._unhandled_input(_drag(0, left - Vector2(0, 12.0 * (i + 1))))
		var step := func() -> void:
			s._physics_process(dt)
			scene._physics_process(dt)
		for i in 60:
			step.call()
		var vm: Dictionary = session.describe()
		var free_el := -1
		for i in n:
			if String(vm["elements"][i]["state"]) == "free":
				free_el = i
				break
		assert_gt(free_el, -1, "a free lever to over-lift (auto=%s)" % auto)
		var x := sz.x * 0.5 + sz.x * 0.5 * (free_el + 0.5) / n
		s._unhandled_input(_touch(1, Vector2(x, 760.0), true))
		var tripped := false
		for i in 3 * HZ:
			s._unhandled_input(_drag(1, Vector2(x, 760.0 - minf(70.0 * i * dt, InputSampler.LIFT_FULL_DP))))
			step.call()
			if String(session.describe()["elements"][0]["state"]) == "jammed":
				tripped = true
				break
		assert_true(tripped, "over-lifting a free lever trips the detector (auto=%s)" % auto)
		s._unhandled_input(_touch(1, Vector2(x, 600.0), false))
		s._unhandled_input(_touch(0, left, false))
		s._unhandled_input(_touch(0, left, true))
		if not auto:
			s._unhandled_input(_drag(0, left + Vector2(0, 60.0)))
		var progress := 0.0
		var reset := false
		for i in 4 * HZ:
			step.call()
			vm = session.describe()
			progress = maxf(progress, float(vm.get("reset_progress", 0.0)))
			if String(vm["elements"][0]["state"]) != "jammed":
				reset = true
				break
		s._unhandled_input(_touch(0, left + Vector2(0, 60.0), false))
		gut.p("lever_detector trip/reset auto=%s: reset=%s progress=%.2f" % [auto, reset, progress])
		assert_true(reset, "turning back resets the detector (auto=%s)" % auto)
		assert_gt(progress, 0.5, "reset_progress grows while turning back (auto=%s)" % auto)
		assert_false(session.finished(), "one trip does not block the lock (auto=%s)" % auto)


func test_layout_fits_portrait_and_landscape() -> void:
	for fam in SCENES:
		JobRun.start(_jobs(fam)[0])
		for size in [Vector2i(412, 915), Vector2i(360, 800), Vector2i(915, 412)]:
			var scene: Node = await _open_scene(fam, size)
			var view: LockPhotorealView = scene.view
			var tag := "%s %dx%d" % [fam, size.x, size.y]
			var screen := Rect2(Vector2.ZERO, Vector2(size))
			assert_true(view.section_rect.size.x > 100.0 and view.section_rect.size.y > 100.0, tag + " section shown")
			var flap: Control = view.get_node("PauseFlap")
			assert_gte(flap.size.x, 48.0, tag + " pause flap")
			assert_true(screen.encloses(flap.get_rect()), tag + " pause flap on screen")
			var loupe: Control = view.get_node("LoupeButton")
			assert_gte(loupe.size.x, 48.0, tag + " loupe target")
			assert_true(screen.intersects(loupe.get_rect()), tag + " loupe on screen")


func test_unused_wafer_chambers_are_empty() -> void:
	var job: Dictionary = _jobs(&"wafer")[0]
	JobRun.start(job)
	var scene: Node = await _open_scene(&"wafer", Vector2i(412, 915))
	var n: int = scene.session.describe()["elements"].size()
	var view: LockWaferView = scene.view
	for i in 5:
		var w: Node3D = view._by.get("wafer%d" % i)
		if w:
			assert_eq(w.visible, i < n, "wafer %d shown only if the lock has it" % i)


func test_lever_states_read_by_geometry() -> void:
	var seen := {}
	for el in [{"state": &"free", "position": 0.1}, {"state": &"bound", "position": 0.2},
			{"state": &"set", "position": 0.5}, {"state": &"false_set", "position": 0.3, "variant": 1},
			{"state": &"overset", "position": 0.9}]:
		var p := LockLeverView.lever_pose(el)
		var sig := "%.2f|%.2f" % [p["delta_lift"], p["bolt_dx"]]
		assert_false(seen.has(sig), "%s looks like %s" % [el["state"], seen.get(sig, "")])
		seen[sig] = el["state"]
	for el in [{"state": &"free", "position": 0.1}, {"state": &"bound", "position": 0.2},
			{"state": &"set", "position": 0.5}, {"state": &"false_set", "position": 0.3},
			{"state": &"overset", "position": 0.9}]:
		var p := LockWaferView.wafer_pose(el)
		var sig := "w%.2f|%.1f" % [p["dz"], p["tilt_deg"]]
		assert_false(seen.has(sig), "wafer %s ambiguous" % el["state"])
		seen[sig] = el["state"]


func test_landscape_roll_shows_whole_picks_and_loupe() -> void:
	# HANDOVER §5.3: in landscape the roll strip cropped the picks and the loupe; now a column
	var scenes := {&"pin_tumbler": "res://scenes/lock_job.tscn"}
	scenes.merge(SCENES)
	for fam in scenes:
		var jobs := _jobs(fam)
		if jobs.is_empty():
			continue
		JobRun.start(jobs[0])
		for size in [Vector2i(915, 412), Vector2i(800, 360), Vector2i(1916, 1080)]:
			var vp := SubViewport.new()
			vp.size = size
			add_child_autofree(vp)
			var scene: Node = load(scenes[fam]).instantiate()
			vp.add_child(scene)
			await wait_physics_frames(2)
			var view: LockPhotorealView = scene.view
			var tag := "%s %dx%d" % [fam, size.x, size.y]
			var screen := Rect2(Vector2.ZERO, Vector2(size))
			var m: Array = view._tray_map()
			assert_eq(m[3], m[2], tag + ": the whole roll image is shown (no crop)")
			var off: Vector2 = m[4]
			var roll := Rect2(view.tray_rect.position + off, m[2] * float(m[0]))
			assert_true(screen.grow(1.0).encloses(roll), tag + ": roll on screen %s" % roll)
			assert_false(roll.intersects(view.section_rect.grow(-1.0)), tag + ": roll beside the section")
			var loupe: Rect2 = view.loupe_rect()
			assert_gte(loupe.size.x, 48.0, tag + ": loupe target")
			assert_gte(loupe.size.y, 48.0, tag + ": loupe target")
			assert_true(screen.encloses(loupe), tag + ": loupe on screen")



func test_lever_view_takes_its_lever_count_from_the_model() -> void:
	JobRun.start(_jobs(&"lever")[0])
	var scene: Node = await _open_scene(&"lever", Vector2i(412, 915))
	var view: LockLeverView = scene.view
	assert_eq(view.lever_count(), 3, "the baked lever model has 3 levers")
	assert_eq(view.LEVER_DEPTH.size(), 3, "depths from scene.json lever_specs")
	var n: int = scene.session.describe()["elements"].size()
	for i in view.lever_count():
		assert_eq((view._by["lever%d" % i] as Node3D).visible, i < n, "lever %d shown only if the lock has it" % i)


func test_one_pin_tutorial_text_has_no_sideways() -> void:
	var c := TutorialCoach.new(0, true, true)
	c.update({"elements": [{"state": &"free", "position": 0.0}]}, {}, [], false, false, 0.01)
	assert_eq(c.text_key(), &"tutorial.s1_pick_one", "S1 has one pin: no \"sideways to choose\"")
	c.update({"elements": [{"state": &"free"}, {"state": &"free"}, {"state": &"free"}]}, {}, [], false, false, 0.01)
	assert_eq(c.text_key(), &"tutorial.s1_pick")
