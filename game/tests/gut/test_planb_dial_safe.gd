extends GutTest
## D-59: the dial safe plan-B lock screen (scenes/photoreal/lock_job_dial_safe.tscn). A bot opens
## every dial_safe job through the real scene (InputSampler touch events in dp → DialSafeControl →
## lockcore → LockDialSafeView) in both control modes of D-52: right thumb = the dial as a scroll
## wheel, left thumb = the handle (or the auto handle). It reads only what the cut-away shows
## (wheel positions, gate notches, the dial), like a player watching the feelers. Layout fits
## portrait and landscape; every state differs by geometry (greyscale).

const HZ := 120
const SCENE := "res://scenes/photoreal/lock_job_dial_safe.tscn"
var _save_backup: Dictionary


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)


func after_all() -> void:
	Save.data = _save_backup
	Save.save()
	JobRun.current_job = {}


func _native() -> bool:
	return ClassDB.class_exists("LockcoreSession") and LockcoreSession.rules_version(&"dial_safe") > 0


static func jobs_of(fam: StringName) -> Array:
	var out: Array = []
	for dir in ["res://data/jobs", "res://data/jobs_ch7"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".json"):
				var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
				if String(j.get("family", "")) == String(fam):
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


func _open_scene(size: Vector2i) -> Node:
	var vp := SubViewport.new()
	vp.size = size
	add_child_autofree(vp)
	var scene: Node = load(SCENE).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(3)
	return scene


## The usual procedure (LOCKS.md §2.18): right until wheel 0 is carried, stop it on its gate; left
## for wheel 1; … ; then back to the mark and press the handle. Returns [opened, seconds, scene].
func _play(job: Dictionary, auto: bool, max_s: float = 120.0) -> Array:
	JobRun.start(job)
	var scene: Node = await _open_scene(Vector2i(412, 915))
	scene.set_physics_process(false)
	var s: InputSampler = scene.sampler
	s.set_physics_process(false)
	s.auto_tension = auto
	scene.fam_control = null
	var ctl: DialSafeControl = scene._fam()
	assert_not_null(ctl, "dial safe scene has the dial control")
	var session: RefCounted = scene.session
	var dt := 1.0 / HZ
	var right := Vector2(330, 700)
	var left := Vector2(80, 760)
	s._unhandled_input(_touch(1, right, true))
	if not auto:
		s._unhandled_input(_touch(0, left, true))
		for i in 6:
			s._unhandled_input(_drag(0, left - Vector2(0, 0.40 * InputSampler.TENSION_FULL_DP * (i + 1) / 6.0)))
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
		var defl: float = DialSafeControl.deflection_for(speed / 1.0)
		s._unhandled_input(_drag(1, right - Vector2(0, defl * InputSampler.LIFT_FULL_DP)))
		s._physics_process(dt)
		scene._physics_process(dt)
		if session.is_open():
			return [true, step * dt, scene]
		if session.finished():
			return [false, step * dt, scene]
	gut.p("stuck: phase %d vm %s" % [phase, session.describe()])
	return [false, max_s, scene]


func test_dial_control_mapping() -> void:
	assert_eq(DialSafeControl.dial_speed(0.0), 0.0, "a still thumb holds the dial")
	assert_gt(DialSafeControl.dial_speed(0.05), 1.0 / 16.0, "the smallest turn is above lockcore's dead zone")
	assert_lt(DialSafeControl.dial_speed(-0.05), 0.0, "down = left")
	assert_almost_eq(DialSafeControl.dial_speed(1.0), 1.0, 0.001)
	for v in [0.1, 0.3, 0.7]:
		assert_almost_eq(DialSafeControl.dial_speed(DialSafeControl.deflection_for(v)), v, 0.002, "inverse at %s" % v)


func test_every_dial_safe_job_opens_with_two_thumbs() -> void:
	if not _native():
		pending("needs the lockcore GDExtension v0.6")
		return
	var jobs := jobs_of(&"dial_safe")
	assert_gt(jobs.size(), 1, "dial safe jobs exist (D-59: 2)")
	for job in jobs:
		var r: Array = await _play(job, false)
		gut.p("two thumbs %s: open=%s %.1f s" % [job["id"], r[0], r[1]])
		assert_true(r[0], "%s (two thumbs) opens (%.1f s)" % [job["id"], r[1]])


func test_every_dial_safe_job_opens_in_auto_mode() -> void:
	if not _native():
		pending("needs the lockcore GDExtension v0.6")
		return
	for job in jobs_of(&"dial_safe"):
		var r: Array = await _play(job, true)
		gut.p("auto %s: open=%s %.1f s" % [job["id"], r[0], r[1]])
		assert_true(r[0], "%s (D-52 auto) opens with the right thumb alone (%.1f s)" % [job["id"], r[1]])
		if r[0]:
			var view: LockDialSafeView = r[2].view
			for i in 40:
				view.present(r[2].session.describe(), {}, 1.0 / 60.0)
			assert_gt(view.bolt_dx(), 10.0, "open: the bolt is drawn back")


func test_job_is_routed_to_the_dial_safe_scene() -> void:
	var job: Dictionary = jobs_of(&"dial_safe")[0]
	JobRun.start(job)
	assert_eq(JobRun.family_for(job), &"dial_safe")
	assert_true(JobRun.is_playable(job), "dial safe jobs are offered")
	assert_eq(JobRun.lock_scene_path(), SCENE)
	JobRun.current_job = {}


func test_layout_fits_portrait_and_landscape() -> void:
	JobRun.start(jobs_of(&"dial_safe")[0])
	for size in [Vector2i(412, 915), Vector2i(360, 800), Vector2i(915, 412)]:
		var scene: Node = await _open_scene(size)
		var view: LockDialSafeView = scene.view
		var tag := "%dx%d" % [size.x, size.y]
		var screen := Rect2(Vector2.ZERO, Vector2(size))
		assert_true(view.section_rect.size.x > 100.0 and view.section_rect.size.y > 100.0, tag + " section shown")
		var flap: Control = view.get_node("PauseFlap")
		assert_gte(flap.size.x, 48.0, tag + " pause flap")
		assert_true(screen.encloses(flap.get_rect()), tag + " pause flap on screen")
		assert_gte(view.loupe_rect().size.x, 48.0, tag + " loupe target >= 48 dp")
		for k in view.n_wheels:
			assert_true(view.section_rect.has_point(view.feeler_tip_screen(k)), tag + " feeler %d inside the section" % k)
		# N-65: the section is rendered at the on-screen pixel size, not a fixed texture
		var disp_h: float = view.section_rect.size.y
		assert_almost_eq(float(view.viewport.size.y), disp_h * view._physical_scale() * view.render_scale, disp_h * 0.08 + 4.0, tag + " viewport follows the screen")


func _wheel(st: String, pos: float, gate: float = 0.5) -> Dictionary:
	return {"state": StringName(st), "position": pos, "window_lo": gate - 0.06, "window_hi": gate + 0.06, "variant": 0}


func test_states_read_by_geometry() -> void:
	# let go / listening / notch passing / set / false notch / clamped / open: feeler depth, fence
	# height, bolt throw and the wheel's turn differ (no colour needed)
	JobRun.start(jobs_of(&"dial_safe")[0])
	var scene: Node = await _open_scene(Vector2i(412, 915))
	scene.set_physics_process(false)
	var view: LockDialSafeView = scene.view
	var sig := func(vm: Dictionary) -> String:
		for i in 90:
			view.present(vm, {"tension": vm.get("tension", 0.0)}, 1.0 / 60.0)
		return "%.1f|%.1f|%.1f|%.0f" % [view.feeler_dip(0), view.fence_dy(), view.bolt_dx(), rad_to_deg(view.wheel_rot(0))]
	var other := _wheel("free", 0.1, 0.8)
	var cases := {
		"let go": {"elements": [_wheel("free", 0.2), other], "tension": 0.0, "tension_resistance": 0.0, "dial_divisions": 20},
		"listening": {"elements": [_wheel("bound", 0.2), other], "tension": 0.4, "tension_resistance": 0.32, "dial_divisions": 20},
		"near": {"elements": [_wheel("near", 0.47), other], "tension": 0.4, "tension_resistance": 0.32, "dial_divisions": 20},
		"set": {"elements": [_wheel("set", 0.5), other], "tension": 0.4, "tension_resistance": 0.2, "dial_divisions": 20},
		"false": {"elements": [_wheel("false_set", 0.3), other], "tension": 0.4, "tension_resistance": 0.32, "dial_divisions": 20},
		"clamped": {"elements": [_wheel("jammed", 0.2), _wheel("jammed", 0.1, 0.8)], "tension": 0.8, "tension_resistance": 0.8, "dial_divisions": 20},
		"open": {"elements": [_wheel("set", 0.5), _wheel("set", 0.8, 0.8)], "tension": 0.4, "tension_resistance": 0.1, "hold_progress": 1.0, "core_rotation": 1.0, "open": true, "dial_divisions": 20},
	}
	var seen := {}
	for nm in cases:
		var key: String = sig.call(cases[nm])
		assert_false(seen.has(key), "state %s looks like %s (%s)" % [nm, seen.get(key, ""), key])
		seen[key] = nm
	assert_gt(view.feeler_dip(0), 2.5, "open: the feelers are down in the gates")
	# the feeler gap when the handle is let go is at least 2 dp on screen (CLAUDE.md division line)
	sig.call(cases["let go"])
	var up := view.feeler_tip_screen(0)
	sig.call(cases["listening"])
	assert_gte(view.feeler_tip_screen(0).y - up.y, 2.0, "handle let go: a visible gap over the rim")


func test_scripted_stages_through_lockcore() -> void:
	if not _native():
		pending("needs the lockcore GDExtension v0.6")
		return
	JobRun.start(jobs_of(&"dial_safe")[0])
	var scene: Node = await _open_scene(Vector2i(412, 915))
	scene.set_physics_process(false)
	scene._simulate_stage("set")
	var els: Array = scene.session.describe()["elements"]
	assert_eq(String(els[0]["state"]), "set", "stage 'set': wheel 0 left in its gate")
