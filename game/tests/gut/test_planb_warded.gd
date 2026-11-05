extends GutTest
## N-63: the warded plan-B lock screen (scenes/photoreal/lock_job_warded.tscn). A bot opens real
## warded jobs through the real scene (InputSampler touch events in dp → WardedControl →
## lockcore → LockWardedView) in both control modes of D-52, picking the bit on the probe head;
## the layout fits portrait and landscape.

const HZ := 120
const SCENE := "res://scenes/photoreal/lock_job_warded.tscn"
var _save_backup: Dictionary


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)


func after_all() -> void:
	Save.data = _save_backup
	Save.save()
	JobRun.current_job = {}


func _native() -> bool:
	return ClassDB.class_exists("LockcoreSession")


func _warded_jobs() -> Array:
	var out: Array = []
	for dir in ["res://data/jobs", "res://data/jobs_ch7"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".json"):
				var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
				if JobRun.family_for(j) == &"warded":
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


## A player who reads the fences: taps the probe head until the right bit is on, holds the probe
## in the keyhole with the right thumb and slides the reach into the channel of the ward ahead
## (then into the bolt band); two thumbs: the left thumb pushes up for the turn with a moderate
## force, auto: the right thumb alone. Returns [opened, seconds].
func _play(job: Dictionary, auto: bool, max_s: float = 30.0) -> Array:
	JobRun.start(job)
	var scene: Node = await _open_scene(Vector2i(412, 915))
	scene.set_physics_process(false)
	var s: InputSampler = scene.sampler
	s.set_physics_process(false)
	s.auto_tension = auto
	var ctl: WardedControl = scene.control
	assert_not_null(ctl, "warded scene has the warded control")
	ctl.auto = auto
	var view: LockWardedView = scene.view
	var session: RefCounted = scene.session
	var plan: Dictionary = LockcoreSession.solve(&"warded", JobRun.seed_for(job), JobRun.tier_for(job))
	var rows: Array = plan["inputs"]
	var want_bit := int(rows[rows.size() - 1][5])
	var force := float(rows[rows.size() - 1][0])
	# bit: tap on the probe head (a real gui_input on the button)
	var tap := _touch(5, view.bit_button.size * 0.5, true)
	for i in 3:
		if ctl.bit == want_bit:
			break
		view.bit_button.gui_input.emit(tap)
	assert_eq(ctl.bit, want_bit, "the bit button selects the bit")
	var dt := 1.0 / HZ
	for i in 3:  # the swap reaches lockcore on a step with the probe out (no thumbs)
		s._physics_process(dt)
		scene._physics_process(dt)
	var right := Vector2(330, 700)
	s._unhandled_input(_touch(1, right, true))
	var left := Vector2(80, 760)
	if not auto:
		s._unhandled_input(_touch(0, left, true))
		for i in 6:
			s._unhandled_input(_drag(0, left - Vector2(0, force * InputSampler.TENSION_FULL_DP * (i + 1) / 6.0)))
	for step in int(max_s * HZ):
		var vm: Dictionary = session.describe()
		var els: Array = vm["elements"]
		var k := int(vm["pick_element"])
		var e: Dictionary = els[mini(k, els.size() - 1)]
		var target := (float(e["window_lo"]) + float(e["window_hi"])) * 0.5
		right.y -= (target - ctl.h) * InputSampler.LIFT_FULL_DP * 0.3
		s._unhandled_input(_drag(1, right))
		s._physics_process(dt)
		scene._physics_process(dt)
		if session.is_open():
			return [true, step * dt, scene]
		if session.finished():
			return [false, step * dt, scene]
	return [false, max_s, scene]


func test_every_warded_job_opens_with_two_thumbs() -> void:
	if not _native():
		pending("needs the lockcore GDExtension")
		return
	for job in _warded_jobs():
		var r: Array = await _play(job, false)
		gut.p("two thumbs %s: open=%s %.1f s" % [job["id"], r[0], r[1]])
		assert_true(r[0], "%s (two thumbs) opens (%.1f s)" % [job["id"], r[1]])


func test_every_warded_job_opens_in_auto_mode() -> void:
	if not _native():
		pending("needs the lockcore GDExtension")
		return
	for job in _warded_jobs():
		var r: Array = await _play(job, true)
		gut.p("auto %s: open=%s %.1f s" % [job["id"], r[0], r[1]])
		assert_true(r[0], "%s (D-52 auto) opens with the right thumb alone (%.1f s)" % [job["id"], r[1]])


func test_ward_spans_are_measured_from_lockcore() -> void:
	if not _native():
		pending("needs the lockcore GDExtension")
		return
	var job: Dictionary = _warded_jobs()[0]
	JobRun.start(job)
	var scene: Node = await _open_scene(Vector2i(412, 915))
	var view: LockWardedView = scene.view
	var n: int = scene.session.describe()["elements"].size() - 1
	assert_eq(view.spans.size(), n, "one span per ward")
	var prev := 0.0
	for sp: Vector2 in view.spans:
		assert_gt(sp.x, prev, "spans increase")
		assert_gt(sp.y, sp.x)
		assert_lt(sp.y, WardedControl.A_BOLT, "wards end before the bolt")
		prev = sp.y


func test_bit_swaps_only_out_of_the_keyhole() -> void:
	var ctl := WardedControl.new(2)
	assert_eq(ctl.options, 3)
	assert_true(ctl.cycle_bit({"core_rotation": 0.0}, false))
	assert_eq(ctl.bit, 1)
	assert_false(ctl.cycle_bit({"core_rotation": 0.2}, false), "turned: no swap")
	assert_false(ctl.cycle_bit({"core_rotation": 0.0}, true), "probe held in: no swap")
	assert_eq(WardedControl.new(1).options, 2, "tier 1 offers two bits")


func test_layout_fits_portrait_and_landscape() -> void:
	JobRun.start(_warded_jobs()[0])
	for size in [Vector2i(412, 915), Vector2i(360, 800), Vector2i(915, 412)]:
		var scene: Node = await _open_scene(size)
		var view: LockWardedView = scene.view
		var tag := "%dx%d" % [size.x, size.y]
		var screen := Rect2(Vector2.ZERO, Vector2(size))
		assert_true(view.section_rect.size.x > 100.0 and view.section_rect.size.y > 100.0, tag + " section shown")
		assert_gte(view.bit_button.size.x, 48.0, tag + " bit target >= 48 dp")
		assert_true(screen.encloses(view.bit_button.get_rect()), tag + " bit target on screen")
		assert_true(view.section_rect.has_point(view.bit_button.get_rect().get_center()), tag + " bit target over the probe")
		var flap: Control = view.get_node("PauseFlap")
		assert_gte(flap.size.x, 48.0, tag + " pause flap")
		assert_true(screen.encloses(flap.get_rect()), tag + " pause flap on screen")
		var head := view.bit_head_screen()
		assert_true(view.section_rect.has_point(head), tag + " bit head inside the section")


func test_states_read_by_geometry() -> void:
	# blocked / turning / set / open: the probe angle, tumbler lift and bolt throw differ
	JobRun.start(_warded_jobs()[0])
	var scene: Node = await _open_scene(Vector2i(412, 915))
	var view: LockWardedView = scene.view
	var bolt := {"state": &"free", "position": 0.0, "window_lo": 0.4, "window_hi": 0.58}
	var ward := {"state": &"bound", "position": 0.5, "window_lo": 0.4, "window_hi": 0.6}
	var sig := func(vm: Dictionary) -> String:
		for i in 90:
			view.present(vm, {}, 1.0 / 60.0)
		return "%.0f|%.2f|%.1f" % [view._angle, view._tumb_lift, view._bolt_dx]
	var seen := {}
	for c in [[0.2, &"free", 0.0], [0.5, &"free", 0.0], [0.86, &"bound", 0.22], [0.93, &"set", 0.62]]:
		var b := bolt.duplicate()
		b["state"] = c[1]
		b["position"] = c[2]
		var key: String = sig.call({"elements": [ward, b], "core_rotation": c[0], "pick_lift": 0.5})
		assert_false(seen.has(key), "state %s looks like %s" % [c, seen.get(key, "")])
		seen[key] = c
	var o := bolt.duplicate()
	o["state"] = &"set"
	o["position"] = 1.0
	sig.call({"elements": [ward, o], "core_rotation": 1.0, "open": true, "pick_lift": 0.5})
	assert_almost_eq(view._bolt_dx, -LockWardedView.BOLT_THROW, 0.3, "open: the bolt is thrown")
