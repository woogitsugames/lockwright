extends GutTest
## N-64: after the tutorial, "Zacznij dyżur" (main menu) and the control choice start the
## shift (run_loop), never a bare lock without a job; a lock that ends with no job, or with a
## broken pick, never leaves the player on a lock that ignores input; the run progresses.
## N-66: the payment receipt is filled in and every button on it has text.

const LOCK_JOB := "res://scenes/lock_job.tscn"
const RUN_LOOP := "res://scenes/run_loop.tscn"
const MAIN_MENU := "res://scenes/main_menu.tscn"

var _save_keys := {}
var _settings_keys := {}


func before_each() -> void:
	for k in ["tutorial_done", "coins", "jobs_completed", "stats/locks_opened", "stats/locks_broken", "stats/runs_finished"]:
		_save_keys[k] = Save.get_value(k, null)
	for k in [&"control_chosen", &"auto_tension"]:
		_settings_keys[k] = Settings.get_value(k, null)
	Events.change_scenes = false
	Events.last_target = ""
	RunState.reset()


func after_each() -> void:
	Events.change_scenes = true
	Events.scene_override = null
	Events._fail_scene = null
	for k in _save_keys:
		if _save_keys[k] != null:
			Save.set_value(k, _save_keys[k])
	for k in _settings_keys:
		if _settings_keys[k] != null:
			Settings.set_value(k, _settings_keys[k])
	JobRun.current_job = {}
	JobRun.mode = &"job"
	JobRun.tutorial_stage = 0
	RunState.reset()
	get_tree().paused = false


## The scene change_scene_to_file put into the tree (GUT has no current scene of its own).
func _changed_to() -> String:
	await get_tree().process_frame
	await get_tree().process_frame
	var cs := get_tree().current_scene
	if cs == null:
		return ""
	var path := cs.scene_file_path
	cs.queue_free()
	await get_tree().process_frame
	return path


func _stub(path: String) -> Node:
	var stub := Control.new()
	stub.scene_file_path = path
	add_child_autofree(stub)
	Events.scene_override = stub
	return stub


func _after_tutorial(mode: StringName) -> void:
	# S3 opened: JobRun.complete() cleared the job; mode is still "tutorial" in the same
	# session, or "job" after the app was restarted (static JobRun reset)
	Save.set_value("tutorial_done", true)
	Settings.set_value(&"control_chosen", true)
	JobRun.mode = mode
	JobRun.tutorial_stage = 3 if mode == &"tutorial" else 0
	JobRun.current_job = {}


func test_main_menu_play_after_tutorial_starts_the_run() -> void:
	for mode in [&"tutorial", &"job"]:
		_after_tutorial(mode)
		var menu: Node = load(MAIN_MENU).instantiate()
		add_child_autofree(menu)
		menu._on_play()
		var to := await _changed_to()
		assert_eq(to, RUN_LOOP, "mode %s: play after the tutorial must open the shift, not %s" % [mode, to])
		assert_ne(to, LOCK_JOB, "never a lock without a job")
		menu.queue_free()


func test_control_choice_after_tutorial_starts_the_run() -> void:
	_after_tutorial(&"job")
	var cc: Node = load("res://scenes/control_choice.tscn").instantiate()
	add_child_autofree(cc)
	await get_tree().process_frame
	cc.select(false)
	cc.confirm()
	assert_eq(await _changed_to(), RUN_LOOP)
	cc.queue_free()


func test_lock_opened_with_empty_job_returns_to_menu() -> void:
	for mode in [&"tutorial", &"job"]:
		_after_tutorial(mode)
		_stub(LOCK_JOB)
		Events.last_target = ""
		Events.lock_opened.emit()
		assert_eq(Events.last_target, MAIN_MENU, "mode %s: an opened lock without a job goes to the menu" % mode)
	assert_eq(JobRun.tutorial_stage, 0, "an empty-job opening must not advance the tutorial")


func test_tutorial_opening_still_goes_back_to_tutorial() -> void:
	JobRun.start_tutorial(1)
	_stub(LOCK_JOB)
	Events.lock_opened.emit()
	assert_eq(Events.last_target, "res://scenes/tutorial.tscn")
	assert_eq(JobRun.tutorial_stage, 2)


func test_job_opening_goes_to_payment() -> void:
	JobRun.start(JobRun.job_by_id("job.allotment_shed"))
	_stub(LOCK_JOB)
	Events.lock_opened.emit()
	assert_eq(Events.last_target, "res://scenes/job_payment.tscn")


func test_broken_pick_leaves_the_lock() -> void:
	# a broken pick ends the lockcore session: staying on the lock looked like a frozen game
	var cases := [
		[&"run", {"id": "run.0", "family": "pin_tumbler", "tier": 1, "reward_coins": 10, "i18n": {}}, RUN_LOOP],
		[&"job", JobRun.job_by_id("job.allotment_shed"), "res://scenes/jobs_list.tscn"],
		[&"tutorial", {}, "res://scenes/tutorial.tscn"],
		[&"job", {}, MAIN_MENU],
	]
	for c in cases:
		if c[0] == &"tutorial":
			JobRun.start_tutorial(1)
		else:
			JobRun.mode = c[0]
			JobRun.current_job = c[1]
		_stub(LOCK_JOB)
		Events.last_target = ""
		Events.lock_failed.emit(&"break")
		assert_eq(Events.last_target, c[2], "%s: after a break" % [c[0]])
	assert_eq(RunState.lives, RunState.LIVES - 1, "a broken run lock costs a life")
	assert_eq(RunState.n, 1)


func test_run_progresses_and_ends() -> void:
	var tiers := []
	for i in 6:
		JobRun.mode = &"run"
		JobRun.current_job = RunState.next_job()
		tiers.append(int(JobRun.current_job["tier"]))
		assert_eq(String(JobRun.current_job["id"]), "run.%d" % i, "lock %d of the run" % i)
		_stub(LOCK_JOB)
		Events.lock_opened.emit()
		assert_eq(Events.last_target, RUN_LOOP)
		assert_eq(RunState.n, i + 1, "the run counts locks across run_loop reloads")
	assert_eq(RunState.opened, 6)
	assert_gt(tiers.back(), tiers.front(), "the tier curve rises: %s" % [tiers])
	assert_eq(RunState.coins, tiers.reduce(func(a, t): return a + 10 * t, 0))
	# run_loop.tscn, reloaded, shows the next lock number
	var loop: Node = load(RUN_LOOP).instantiate()
	add_child_autofree(loop)
	assert_string_contains(loop.get_node("VBox/Info").text, "7")
	# three breaks end the run
	for i in 3:
		JobRun.mode = &"run"
		JobRun.current_job = RunState.next_job()
		_stub(LOCK_JOB)
		Events._fail_scene = null
		Events.lock_failed.emit(&"break")
	assert_true(RunState.finished)
	var done: Node = load(RUN_LOOP).instantiate()
	add_child_autofree(done)
	assert_ne(done.get_node("VBox/StartButton").text, "", "finished run: continue button has text")


func test_real_run_lock_opens_and_counts() -> void:
	# the real photoreal lock scene + lockcore, driven by thumb events through its InputSampler
	Settings.set_value(&"auto_tension", true)
	JobRun.mode = &"run"
	JobRun.current_job = RunState.next_job()
	var lock: Node = load(JobRun.lock_scene_path()).instantiate()
	add_child_autofree(lock)
	Events.scene_override = lock
	await get_tree().physics_frame
	var s: InputSampler = lock.sampler
	assert_true(s.auto_tension)
	var sz := s._size()
	var n: int = lock.session.describe()["elements"].size()
	var pin := 0
	var lift := 0.0
	var pressed := false
	var opened := [false]
	Events.lock_opened.connect(func() -> void: opened[0] = true, CONNECT_ONE_SHOT)
	var depth_seen := 0.5
	for f in 120 * 40:
		var els: Array = lock.session.describe()["elements"]
		var x := sz.x * 0.5 + sz.x * 0.5 * (pin + 0.5) / n
		if not pressed:
			var t := InputEventScreenTouch.new()
			t.index = 1
			t.position = Vector2(x, sz.y * 0.82)
			t.pressed = true
			s._unhandled_input(t)
			pressed = true
			lift = 0.0
		else:
			lift += 70.0 / 120.0
			var d := InputEventScreenDrag.new()
			d.index = 1
			d.position = Vector2(x, sz.y * 0.82 - lift)
			s._unhandled_input(d)
		await get_tree().physics_frame
		depth_seen = lock._last_input["pick_depth"]
		if opened[0] or lock.session.finished():
			break
		var st := String(els[pin]["state"])
		if lift > 180.0 or (st == "set" and lift > 20.0) or st == "overset":
			var u := InputEventScreenTouch.new()
			u.index = 1
			u.position = Vector2(x, sz.y * 0.82 - lift)
			s._unhandled_input(u)
			pressed = false
			for k in n:
				pin = (pin + 1) % n
				if String(els[pin]["state"]) != "set":
					break
	assert_ne(depth_seen, 0.5, "the pick follows the right thumb")
	assert_true(lock.session.is_open(), "the run lock opens with plain thumb input")
	assert_true(opened[0], "lock_opened emitted")
	assert_eq(Events.last_target, RUN_LOOP)
	assert_eq(RunState.n, 1)
	assert_eq(RunState.opened, 1)


func test_payment_receipt_is_filled_after_a_job_opening() -> void:
	var job := JobRun.job_by_id("job.allotment_shed")
	JobRun.start(job)
	_stub(LOCK_JOB)
	Events.lock_opened.emit()
	assert_eq(Events.last_target, "res://scenes/job_payment.tscn")
	var pay: Control = load("res://scenes/job_payment.tscn").instantiate()
	add_child_autofree(pay)
	await get_tree().process_frame
	await get_tree().process_frame
	var r: Dictionary = pay.receipt_texts()
	for k in ["Number", "Date", "Client", "Service", "Line1", "Amount1", "Total"]:
		assert_ne(String(r.get(k, "")).strip_edges(), "", "receipt field %s filled" % k)
	assert_ne(r["Client"], "—")
	assert_string_contains(r["Amount1"], str(int(job["reward_coins"])))
	assert_ne(pay.get_node("Frame/VBox/Receipt/Paper").texture, null, "receipt paper")
	for b in pay.find_children("*", "BaseButton", true, false):
		assert_ne((b as Button).text.strip_edges(), "", "button %s has text" % b.name)
	for l in pay.find_children("*", "Label", true, false):
		if (l as Label).visible and l.name not in ["Line2", "Amount2"]:
			assert_ne((l as Label).text.strip_edges(), "", "visible label %s has text" % l.name)
	# the receipt fields sit inside the paper
	var paper_rect := Rect2(Vector2.ZERO, pay.get_node("Frame/VBox/Receipt/Paper").size)
	for k in r:
		var l: Label = pay.get_node("Frame/VBox/Receipt/Paper/" + k)
		assert_true(paper_rect.encloses(Rect2(l.position, l.size).grow(-0.5)), "%s inside the receipt" % k)
	JobRun.current_job = {}


func test_receipt_paper_in_every_ui_language() -> void:
	# VA-18: a printed receipt per UI language; anything else falls back to the EN paper
	var pay_script := load("res://scripts/ui/job_payment.gd")
	for lang in ["pl", "en", "de", "fr", "es"]:
		var path: String = pay_script.receipt_path(lang)
		assert_eq(path, "res://assets/ui/gpt/verify/receipt_%s.webp" % lang)
		assert_true(ResourceLoader.exists(path), "receipt paper %s ships" % lang)
	assert_eq(pay_script.receipt_path("de_DE"), "res://assets/ui/gpt/verify/receipt_de.webp")
	assert_eq(pay_script.receipt_path("it"), "res://assets/ui/gpt/verify/receipt_en.webp")
