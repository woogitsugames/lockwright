extends GutTest
## D-59: the thumbwheel combination lock plan-B screen (scenes/photoreal/lock_job_combo.tscn). A bot
## opens every combo job through the real scene (InputSampler touch events in dp → ComboControl →
## lockcore → LockComboView) in both control modes of D-52: the right thumb picks a wheel (across)
## and rolls it (up/down), the left thumb pulls the cable (or the auto pull). It watches what the cut
## shows: which tooth sits on its bore (the binding wheel) and the digits. Layout fits portrait and
## landscape; every state differs by geometry (greyscale).

const HZ := 120
const SCENE := "res://scenes/photoreal/lock_job_combo.tscn"
const DISC_SCENE := "res://scenes/photoreal/lock_job_disc_detainer.tscn"
var _scene_path := SCENE
const DialTest := preload("res://tests/gut/test_planb_dial_safe.gd")
var _save_backup: Dictionary


func before_each() -> void:
	_scene_path = SCENE


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)


func after_all() -> void:
	Save.data = _save_backup
	Save.save()
	JobRun.current_job = {}


func _native() -> bool:
	return ClassDB.class_exists("LockcoreSession") and LockcoreSession.rules_version(&"combo") > 0


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
	var scene: Node = load(_scene_path).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(3)
	return scene


## Pull, find the binding wheel, put the right thumb on it and roll it slowly (shortest way) to its
## gate; a wheel caught in a false notch is freed by easing the pull (two thumbs: the left thumb
## eases off; auto: a tap on the left zone). Returns [opened, seconds, scene].
func _play(job: Dictionary, auto: bool, max_s: float = 90.0) -> Array:
	JobRun.start(job)
	var scene: Node = await _open_scene(Vector2i(412, 915))
	scene.set_physics_process(false)
	var s: InputSampler = scene.sampler
	s.set_physics_process(false)
	s.auto_tension = auto
	scene.fam_control = null
	var ctl: ComboControl = scene._fam()
	assert_not_null(ctl, "combo scene has the combo control")
	var session: RefCounted = scene.session
	var dt := 1.0 / HZ
	var half := 206.0
	var left := Vector2(80, 760)
	var pull := 0.34
	if not auto:
		s._unhandled_input(_touch(0, left, true))
		for i in 6:
			s._unhandled_input(_drag(0, left - Vector2(0, pull * InputSampler.TENSION_FULL_DP * (i + 1) / 6.0)))
	var right_down := false
	var right := Vector2.ZERO
	var target := -1
	var ease_left := 0
	var settle := 0
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
			# caught in a false notch: ease the pull and roll that wheel on past the notch while it is
			# loose (auto: a tap on the left zone while rolling it)
			ease_left = 60
			unstick = caught
			if not auto:
				s._unhandled_input(_drag(0, left - Vector2(0, 0.15 * InputSampler.TENSION_FULL_DP)))
		if ease_left > 0:
			ease_left -= 1
			if auto and ease_left == 48:
				s._unhandled_input(_touch(0, left, true))
				s._unhandled_input(_touch(0, left, false))  # a quick tap: let go for 0.1 s
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
				# on past the false notch, the way the gate lies
				var ue: Dictionary = els[unstick]
				var ug := fposmod((float(ue["window_lo"]) + float(ue["window_hi"])) * 0.5, 1.0)
				var uway := signf(LockComboView.wrap_half(ug - float(ue["position"])))
				speed = uway * (0.9 if auto else 0.5)
		if b >= 0:
			var x := half + (float(b) + 0.5) / n * half
			if b != target or not right_down:
				if right_down:
					s._unhandled_input(_touch(1, right, false))
				right = Vector2(x, 700)
				s._unhandled_input(_touch(1, right, true))
				right_down = true
				target = b
				settle = 0
			var e: Dictionary = els[b]
			var g := fposmod((float(e["window_lo"]) + float(e["window_hi"])) * 0.5, 1.0)
			var off: float = LockComboView.wrap_half(g - float(e["position"]))
			if int(vm["pick_element"]) == b:
				speed = signf(off) * clampf(absf(off) * 3.0, 0.12, 0.35)
			settle += 1
		if OS.has_environment("LW_DEBUG") and step % 240 == 0:
			print("t=%.0f T=%.2f b=%d pick=%d spd=%.2f in=%s %s" % [step * dt, float(vm["tension"]), b, int(vm["pick_element"]), speed, str(scene._last_input),  els.map(func(e): return "%s@%.3f[%.2f]" % [e["state"], e["position"], (float(e["window_lo"]) + float(e["window_hi"])) * 0.5])])
		var defl: float = ComboControl.deflection_for(speed)
		if right_down:
			s._unhandled_input(_drag(1, right - Vector2(0, defl * InputSampler.LIFT_FULL_DP)))
		s._physics_process(dt)
		scene._physics_process(dt)
		if session.is_open():
			return [true, step * dt, scene]
		if session.finished():
			return [false, step * dt, scene]
	gut.p("stuck: %s" % [session.describe()])
	return [false, max_s, scene]


func test_combo_control_mapping() -> void:
	assert_eq(ComboControl.wheel_speed(0.0), 0.0)
	assert_lt(ComboControl.wheel_speed(-0.5), 0.0, "down = digit down")
	for v in [0.1, 0.4, 0.8]:
		assert_almost_eq(ComboControl.wheel_speed(ComboControl.deflection_for(v)), v, 0.002)


func test_every_combo_job_opens_with_two_thumbs() -> void:
	if not _native():
		pending("needs the lockcore GDExtension v0.6")
		return
	var jobs := DialTest.jobs_of(&"combo")
	assert_gt(jobs.size(), 1, "combo jobs exist (D-59: 2)")
	for job in jobs:
		var r: Array = await _play(job, false)
		gut.p("two thumbs %s: open=%s %.1f s" % [job["id"], r[0], r[1]])
		assert_true(r[0], "%s (two thumbs) opens (%.1f s)" % [job["id"], r[1]])


func test_every_combo_job_opens_in_auto_mode() -> void:
	if not _native():
		pending("needs the lockcore GDExtension v0.6")
		return
	for job in DialTest.jobs_of(&"combo"):
		var r: Array = await _play(job, true)
		gut.p("auto %s: open=%s %.1f s" % [job["id"], r[0], r[1]])
		assert_true(r[0], "%s (D-52 auto) opens (%.1f s)" % [job["id"], r[1]])
		if r[0]:
			var view: LockComboView = r[2].view
			for i in 40:
				view.present(r[2].session.describe(), {}, 1.0 / 60.0)
			assert_gt(view.plug_dx(), 4.0, "open: the cable plug comes out")


func test_job_is_routed_to_the_combo_scene() -> void:
	var job: Dictionary = DialTest.jobs_of(&"combo")[0]
	JobRun.start(job)
	assert_eq(JobRun.family_for(job), &"combo", "D-60: job family combo is the lockcore combo family")
	assert_true(JobRun.is_playable(job))
	assert_eq(JobRun.lock_scene_path(), SCENE)
	JobRun.current_job = {}


func test_layout_fits_portrait_and_landscape() -> void:
	JobRun.start(DialTest.jobs_of(&"combo")[0])
	for size in [Vector2i(412, 915), Vector2i(360, 800), Vector2i(915, 412)]:
		var scene: Node = await _open_scene(size)
		var view: LockComboView = scene.view
		var tag := "%dx%d" % [size.x, size.y]
		var screen := Rect2(Vector2.ZERO, Vector2(size))
		assert_true(view.section_rect.size.x > 100.0, tag + " section shown")
		var flap: Control = view.get_node("PauseFlap")
		assert_gte(flap.size.x, 48.0, tag + " pause flap")
		assert_true(screen.encloses(flap.get_rect()), tag + " pause flap on screen")
		for i in view.n_wheels:
			var rr := view.reel_rect_screen(i)
			assert_gte(rr.size.x, 28.0, tag + " wheel %d >= 28 dp wide" % i)
			assert_true(view.section_rect.encloses(rr.grow(-1.0)), tag + " wheel %d inside the section" % i)
			assert_true(view.section_rect.has_point(view.tooth_tip_screen(i)), tag + " tooth %d inside the section" % i)


func _wheel(st: String, pos: float, gate: float = 0.5) -> Dictionary:
	return {"state": StringName(st), "position": pos, "window_lo": gate - 0.03, "window_hi": gate + 0.03, "variant": 0}


func test_states_read_by_geometry() -> void:
	JobRun.start(DialTest.jobs_of(&"combo")[0])
	var scene: Node = await _open_scene(Vector2i(412, 915))
	scene.set_physics_process(false)
	var view: LockComboView = scene.view
	var sig := func(vm: Dictionary) -> String:
		for i in 90:
			view.present(vm, {"tension": vm.get("tension", 0.0)}, 1.0 / 60.0)
		return "%.1f|%.1f|%.1f|%.2f" % [view.tooth_dip(0), view.slot_visible(0), view.plug_dx(), view.reel_pos(0)]
	var o := _wheel("free", 0.1, 0.7)
	var cases := {
		"let go": {"elements": [_wheel("free", 0.2), o, o], "tension": 0.0, "pick_element": 0},
		"free, pulled": {"elements": [_wheel("free", 0.2), _wheel("bound", 0.1, 0.7), o], "tension": 0.34, "pick_element": 0},
		"binding": {"elements": [_wheel("bound", 0.2), o, o], "tension": 0.34, "pick_element": 0},
		"near": {"elements": [_wheel("near", 0.48), o, o], "tension": 0.34, "pick_element": 0},
		"set": {"elements": [_wheel("set", 0.5), _wheel("bound", 0.1, 0.7), o], "tension": 0.34, "pick_element": 0},
		"false": {"elements": [_wheel("false_set", 0.3), o, o], "tension": 0.34, "pick_element": 0},
		"open": {"elements": [_wheel("set", 0.5), _wheel("set", 0.7, 0.7), _wheel("set", 0.7, 0.7)], "tension": 0.34, "open": true, "core_rotation": 1.0},
	}
	var seen := {}
	for nm in cases:
		var key: String = sig.call(cases[nm])
		assert_false(seen.has(key), "state %s looks like %s (%s)" % [nm, seen.get(key, ""), key])
		seen[key] = nm
	view._opened = false
	# slip: the tooth chatters (moves between frames) while it is on the bore
	var slip := {"elements": [_wheel("overset", 0.3), o, o], "tension": 0.34, "pick_element": 0}
	sig.call(slip)
	var ys := {}
	for i in 12:
		view.present(slip, {"tension": 0.34}, 1.0 / 60.0)
		ys["%.2f" % view.tooth_dip(0)] = true
		await wait_physics_frames(1)
	assert_gt(ys.size(), 1, "slip: the tooth chatters")
	# the tooth gap when the cable is let go is at least 2 dp on screen
	sig.call(cases["let go"])
	var up := view.tooth_tip_screen(0)
	sig.call(cases["binding"])
	assert_gte(view.tooth_tip_screen(0).y - up.y, 2.0, "cable let go: a visible gap over the bore")


func test_scripted_stages_through_lockcore() -> void:
	if not _native():
		pending("needs the lockcore GDExtension v0.6")
		return
	JobRun.start(DialTest.jobs_of(&"combo")[0])
	var scene: Node = await _open_scene(Vector2i(412, 915))
	scene.set_physics_process(false)
	scene._simulate_stage("slip")
	var states: Array = scene.session.describe()["elements"].map(func(e: Dictionary) -> String: return String(e["state"]))
	assert_true(states.has("overset"), "stage 'slip': a wheel slips (%s)" % [states])


# ------------------------------------------------------------------ disc detainer (same view, own plates)
## LOCKS.md §2.21 reuses the ring_combo module: the same bot opens it (right thumb across = disc,
## up/down = turn the disc, left thumb = torque on the core).
func test_every_disc_detainer_job_opens_in_both_modes() -> void:
	if not (ClassDB.class_exists("LockcoreSession") and LockcoreSession.rules_version(&"disc_detainer") > 0):
		pending("needs the lockcore GDExtension v0.6")
		return
	_scene_path = DISC_SCENE
	var jobs := DialTest.jobs_of(&"disc_detainer")
	assert_gt(jobs.size(), 0, "disc detainer jobs exist")
	for job in jobs:
		JobRun.start(job)
		assert_true(JobRun.is_playable(job))
		assert_eq(JobRun.lock_scene_path(), DISC_SCENE)
		for auto in [false, true]:
			var r: Array = await _play(job, auto)
			gut.p("disc %s auto=%s: open=%s %.1f s" % [job["id"], auto, r[0], r[1]])
			assert_true(r[0], "%s (auto=%s) opens (%.1f s)" % [job["id"], auto, r[1]])


func test_disc_layout_and_states() -> void:
	_scene_path = DISC_SCENE
	JobRun.start(DialTest.jobs_of(&"disc_detainer")[0])
	for size in [Vector2i(412, 915), Vector2i(360, 800), Vector2i(915, 412)]:
		var scene: Node = await _open_scene(size)
		var view: LockComboView = scene.view
		var tag := "disc %dx%d" % [size.x, size.y]
		assert_eq(view.slots, 6, tag + " six disc slots")
		for i in view.n_wheels:
			assert_gte(view.reel_rect_screen(i).size.x, 28.0, tag + " disc %d >= 28 dp" % i)
			assert_true(view.section_rect.has_point(view.tooth_tip_screen(i)), tag + " finger %d inside" % i)
	var scene: Node = await _open_scene(Vector2i(412, 915))
	scene.set_physics_process(false)
	var view: LockComboView = scene.view
	var o := _wheel("free", 0.1, 0.7)
	var vm_free := {"elements": [_wheel("bound", 0.2), o, o, o, o], "tension": 0.0, "pick_element": 0}
	var vm_set := {"elements": [_wheel("set", 0.5), o, o, o, o], "tension": 0.34, "pick_element": 0}
	for i in 90:
		view.present(vm_free, {}, 1.0 / 60.0)
	var y_free := view.tooth_tip_screen(0).y
	for i in 90:
		view.present(vm_set, {}, 1.0 / 60.0)
	assert_lt(view.tooth_tip_screen(0).y, y_free - 2.0, "set: the finger rises into the disc gate (sidebar under the discs)")


## QA hook: qa/bot/qa_sampler.gd swaps the InputSampler for one that replays lockcore's solver rows
## (`rows`); the plan-B family screens then feed those frames to lockcore untouched.
func test_qa_solver_rows_open_combo_and_dial_safe() -> void:
	if not ClassDB.class_exists("LockcoreSession"):
		pending("needs the lockcore GDExtension")
		return
	var src := GDScript.new()
	src.source_code = "extends InputSampler\nvar rows: Array = []\nvar i := 0\nfunc _physics_process(_d: float) -> void:\n\tif i < rows.size():\n\t\ti += 1\nfunc sample() -> Dictionary:\n\tvar r: Array = rows[mini(i, rows.size() - 1)]\n\treturn {\"tension\": float(r[0]), \"pick_depth\": float(r[1]), \"pick_lift\": float(r[2]), \"rotate\": 0.0, \"push\": 0.0, \"tool\": 0}\n"
	assert_eq(src.reload(), OK)
	for pair in [[SCENE, &"combo"], [DISC_SCENE, &"disc_detainer"], ["res://scenes/photoreal/lock_job_dial_safe.tscn", &"dial_safe"]]:
		_scene_path = pair[0]
		var job: Dictionary = DialTest.jobs_of(pair[1])[0]
		JobRun.start(job)
		var scene: Node = await _open_scene(Vector2i(412, 915))
		scene.set_physics_process(false)
		var s: Node = scene.sampler
		s.set_script(src)
		s.set_physics_process(false)
		var rows: Array = LockcoreSession.solve(pair[1], JobRun.seed_for(job), JobRun.tier_for(job))["inputs"]
		s.rows = rows
		for k in rows.size() + 240:
			scene._physics_process(1.0 / HZ)
			s._physics_process(1.0 / HZ)
			if scene.session.is_open():
				break
		assert_true(scene.session.is_open(), "%s opens from the solver rows (QA bot path)" % job["id"])
