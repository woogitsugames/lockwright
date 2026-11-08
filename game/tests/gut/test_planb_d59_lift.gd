extends GutTest
## D-59: plan-B screens of the lift-based families added in lockcore v0.6 (magnetic, dimple, egyptian,
## time_lock, axial_slider). A patient player opens every job of each family through the real scene
## (touch events in dp → InputSampler → lockcore → the family view) in both control modes of D-52:
## the left thumb holds a steady tension (or the auto tension), the right thumb works one element at a
## time, lifting slowly; on a set it moves to the next, on an overset it lets go of the tension for a
## moment. Layout fits portrait and landscape; the family's own tool / parts are where lockcore says.

const HZ := 120
const SCENES := {
	&"magnetic": "res://scenes/photoreal/lock_job_magnetic.tscn",
	&"dimple": "res://scenes/photoreal/lock_job_dimple.tscn",
	&"egyptian": "res://scenes/photoreal/lock_job_egyptian.tscn",
	&"time_lock": "res://scenes/photoreal/lock_job_time_lock.tscn",
	&"axial_slider": "res://scenes/photoreal/lock_job_axial_slider.tscn",
}
var _save_backup: Dictionary


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)


func after_all() -> void:
	Save.data = _save_backup
	Save.save()
	JobRun.current_job = {}


func _native(fam: StringName) -> bool:
	return ClassDB.class_exists("LockcoreSession") and LockcoreSession.rules_version(fam) > 0


static func jobs(fam: StringName) -> Array:
	var out: Array = []
	for dir in ["res://data/jobs"]:
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


## Returns [opened, seconds, scene].
func _play(fam: StringName, job: Dictionary, auto: bool, max_s: float = 120.0) -> Array:
	JobRun.start(job)
	var scene: Node = await _open_scene(fam, Vector2i(412, 915))
	scene.set_physics_process(false)
	var s: InputSampler = scene.sampler
	s.set_physics_process(false)
	s.auto_tension = auto
	if scene.has_method("_fam"):
		scene.fam_control = null
		scene._fam()
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
		if fam == &"magnetic" and not pressed:
			# T43 magnetic t2: the probe's field also tugs the neighbours, so a patient player lifts only
			# the pin that binds now (never a free one to the top) and waits while none binds
			var b := -1
			for i in n:
				if String(session.describe()["elements"][i]["state"]) == "bound":
					b = i
					break
			if b < 0:
				s._physics_process(dt)
				scene._physics_process(dt)
				if session.is_open() or session.finished():
					return [session.is_open(), step * dt, scene]
				continue
			el = b
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
		if OS.has_environment("LW_DEBUG") and step % 60 == 0:
			print("t=%.1f el=%d lift=%.0f %s" % [step * dt, el, lift_dp, vm["elements"].map(func(e): return "%s@%.2f[%.2f]" % [e["state"], e["position"], e["window_lo"]])])
		if session.is_open():
			return [true, step * dt, scene]
		if session.finished():
			return [false, step * dt, scene]
		var next := lift_dp > 0.9 * InputSampler.LIFT_FULL_DP
		var oversets := 0
		var all_set := true
		for e in vm["elements"]:
			if String(e["state"]) in ["overset", "jammed"]:
				oversets += 1
			all_set = all_set and String(e["state"]) == "set"
		if all_set:
			# time_lock: everything meshed — keep the key in the run band and let it run
			s._unhandled_input(_touch(1, Vector2(x, right_y - lift_dp), false))
			pressed = true
			continue
		if String(vm["elements"][el]["state"]) == "set":
			next = true
		# a telescoping pin / spool caught at the false gate: ease into the counter-rotation band
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
	gut.p("stuck %s: %s" % [fam, session.describe()["elements"]])
	return [false, max_s, scene]


func _check_family(fam: StringName) -> void:
	if not _native(fam):
		pending("needs the lockcore GDExtension v0.6")
		return
	var js := jobs(fam)
	assert_gt(js.size(), 0, "jobs of %s exist" % fam)
	for job in js:
		assert_true(JobRun.is_playable(job), "%s is offered" % job["id"])
		JobRun.start(job)
		assert_eq(JobRun.lock_scene_path(), SCENES[fam], "%s routes to its plan-B scene" % job["id"])
		for auto in [false, true]:
			var r: Array = await _play(fam, job, auto)
			gut.p("%s %s auto=%s: open=%s %.1f s" % [fam, job["id"], auto, r[0], r[1]])
			assert_true(r[0], "%s (%s, auto=%s) opens through the plan-B view (%.1f s)" % [job["id"], fam, auto, r[1]])


func _check_layout(fam: StringName) -> void:
	JobRun.start(jobs(fam)[0])
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
		if view.has_method("tool_tip_screen"):
			assert_true(view.section_rect.has_point(view.tool_tip_screen()), tag + " tool tip inside the section")


func test_magnetic_jobs_open_in_both_modes() -> void:
	await _check_family(&"magnetic")


func test_dimple_jobs_open_in_both_modes() -> void:
	await _check_family(&"dimple")


func test_layouts() -> void:
	for fam in SCENES:
		await _check_layout(fam)


func test_magnetic_field_trails_the_probe() -> void:
	# the field (lockcore pick_lift) lags the thumb: the ring and the pin follow, never jump
	JobRun.start(jobs(&"magnetic")[0])
	var scene: Node = await _open_scene(&"magnetic", Vector2i(412, 915))
	scene.set_physics_process(false)
	var view: LockPinFamilyView = scene.view
	var vm := {"elements": [{"state": &"bound", "position": 0.1, "window_lo": 0.5, "window_hi": 0.62, "variant": 0}],
			"pick_element": 0, "pick_lift": 0.1, "tension": 0.35}
	for i in 60:
		view.present(vm, {"tension": 0.35, "pick_lift": 0.6, "pick_depth": 0.2}, 1.0 / 60.0)
	assert_almost_eq(view.field_lift(), 0.1, 0.02, "the ring sits at lockcore's field, not at the thumb")
	assert_lt(view.tool_tip_screen().y, view.mm_to_screen(Vector3(view.PINS_X[0], PinPose.REST_BOTTOM + 0.1 * PinPose.TRAVEL, 0)).y,
			"the probe is ahead (above) of the field it drags")


func test_dimple_side_row_variant_is_masked() -> void:
	var vm := {"elements": [{"state": &"free", "position": 0.0, "variant": 16 + 1}]}
	assert_eq(int(LockPinFamilyView.pin_vm(vm)["elements"][0]["variant"]), 1, "side-row bit off, spool kept")
	assert_true(PinPose.is_spool(LockPinFamilyView.pin_vm(vm)["elements"][0]), "telescoping pin = spool pose")


## VA-10: dimple and magnetic have their own static section (side-drilled row / magnet rotors) on the
## pin cut-away camera; the pin screen keeps the shared plate. A phone loads the 1x sibling (D-87).
func test_dimple_and_magnetic_load_their_own_plate() -> void:
	for fam in [&"dimple", &"magnetic"]:
		JobRun.start(jobs(fam)[0])
		var scene: Node = await _open_scene(fam, Vector2i(412, 915))
		var view: LockPinFamilyView = scene.view
		var want: String = LockPhotorealView.PLATE_BY_FAMILY[fam]
		assert_eq(view.plate_path, want, "%s: its scene sets its own plate" % fam)
		assert_ne(view.plate_path, LockPhotorealView.PLATE, "%s: not the pin plate" % fam)
		var tex: Texture2D = view._plate_mats[0].get_shader_parameter("plate")
		assert_not_null(tex, "%s: plate loaded" % fam)
		if tex != null:
			assert_eq(tex.resource_path, LockPhotorealView.plate_variant(want, view._section_px()), "%s: the variant D-87 picks" % fam)
		var pre := LockPreload.paths_for(fam, SCENES[fam], 1080.0)
		assert_has(pre, want.replace(".png", "_1x.png"), "%s: preload warms the 1x plate the phone loads" % fam)
		assert_has(pre, "res://assets/photoreal/cutaway_baked.glb", "%s: and the pin model" % fam)
	JobRun.current_job = {}


func test_egyptian_jobs_open_in_both_modes() -> void:
	await _check_family(&"egyptian")


func _layer_states_differ(fam: StringName) -> void:
	JobRun.start(jobs(fam)[0])
	var scene: Node = await _open_scene(fam, Vector2i(412, 915))
	scene.set_physics_process(false)
	var view: LockLiftLayerView = scene.view
	var el := func(st: String, pos: float) -> Dictionary:
		return {"state": StringName(st), "position": pos, "window_lo": 0.5, "window_hi": 0.62, "variant": 0}
	var sig := func(vm: Dictionary) -> String:
		for i in 90:
			view.present(vm, {"tension": vm.get("tension", 0.0)}, 1.0 / 60.0)
		return "%.2f|%.1f|%.2f" % [view.element_offset(0), view.element_tilt(0), view.progress()]
	var other: Dictionary = el.call("free", 0.0)
	var cases := {
		"free": {"elements": [el.call("free", 0.0), other, other], "tension": 0.0},
		"bound": {"elements": [el.call("bound", 0.3), other, other], "tension": 0.35},
		"near": {"elements": [el.call("near", 0.5), other, other], "tension": 0.35},
		"set": {"elements": [el.call("set", 0.56), other, other], "tension": 0.35},
		"overset": {"elements": [el.call("overset", 0.8), other, other], "tension": 0.35},
		"open": {"elements": [el.call("set", 0.56), el.call("set", 0.56), el.call("set", 0.56)], "tension": 0.35, "hold_progress": 1.0, "open": true},
	}
	var seen := {}
	for nm in cases:
		var key: String = sig.call(cases[nm])
		assert_false(seen.has(key), "%s: state %s looks like %s (%s)" % [fam, nm, seen.get(key, ""), key])
		seen[key] = nm
	# one position unit moves an element >= 28 dp on a 412 dp screen (readable travel)
	var a := view.element_screen(0)
	view._off[view.slot_of(0)] += 1.0
	assert_gte(a.distance_to(view.element_screen(0)), 28.0, fam + ": travel is readable")


func test_egyptian_states_read_by_geometry() -> void:
	await _layer_states_differ(&"egyptian")


func test_time_lock_jobs_run_in_both_modes() -> void:
	# a repair: "open" here means the movement runs again (LOCKS.md §2.24)
	await _check_family(&"time_lock")


func test_time_lock_states_read_by_geometry() -> void:
	await _layer_states_differ(&"time_lock")


func test_time_lock_train_turns_only_when_running() -> void:
	JobRun.start(jobs(&"time_lock")[0])
	var scene: Node = await _open_scene(&"time_lock", Vector2i(412, 915))
	scene.set_physics_process(false)
	var view: LockTimeLockView = scene.view
	var el := {"state": &"set", "position": 0.5, "window_lo": 0.45, "window_hi": 0.57, "variant": 0}
	var vm := {"elements": [el, el, el], "tension": 0.35, "hold_progress": 0.0}
	for i in 30:
		view.present(vm, {"tension": 0.35}, 1.0 / 60.0)
	var p0 := view.train_phase()
	assert_false(view.is_running(), "meshed but not running: the pallet is still")
	vm["hold_progress"] = 0.4
	for i in 30:
		view.present(vm, {"tension": 0.35}, 1.0 / 60.0)
	assert_gt(view.train_phase(), p0, "running: the whole train turns")


func test_axial_slider_jobs_open_in_both_modes() -> void:
	await _check_family(&"axial_slider")


func test_axial_slider_states_read_by_geometry() -> void:
	await _layer_states_differ(&"axial_slider")
