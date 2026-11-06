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
	for step in int(max_s * HZ):
		if cooldown > 0:
			cooldown -= 1
			if cooldown == 0 and not auto:
				press_left.call()
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
			if not auto:
				press_left.call()
			continue
		if OS.has_environment("LW_DEBUG") and step % 120 == 0:
			print("t=%.0f el=%d T=%.2f lift=%.2f resets=%d %s" % [step * dt, el, s.sample()["tension"], s.sample()["pick_lift"], resets, vm["elements"].map(func(e): return "%s@%.2f[%.2f-%.2f]" % [e["state"], e["position"], e["window_lo"], e["window_hi"]])])
		var next := lift_dp > 0.9 * InputSampler.LIFT_FULL_DP
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
	await _check_family(&"lever_detector")


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
