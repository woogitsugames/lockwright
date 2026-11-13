extends GutTest
## D-121 / ONBOARDING §9.1: the spool lesson. Before the first pin_tumbler lock at the tier where
## security pins start (res://data/tool_caution.json), the lock screen plays a security lesson on its
## own authored lock (res://data/tutorial/l_spool.json: three stacks, the middle one a spool) with the
## lesson coach of the family lessons (res://data/lessons/pin_tumbler_spool.json). Checked here:
##   - data: the lesson, its lock and its lines (five languages, two chalk lines);
##   - pure logic: first pin, the spool's false set (trap line, auto variant), free, the closing line;
##   - when it is due: the family's first risky tier, in a job and in the continuous run, once;
##   - through the real scene, both control modes: a scripted player opens the lesson lock (clean
##     click, false set, tension eased into the counter-rotation band), the screen then asks for the
##     job's own lock; nothing of the lesson counts (no payment route, no stats, a clean job);
##   - a broken tool restarts the lesson, the pause can skip it, the D-120 caution waits for the job.

const HZ := 120
const LANGS := ["en", "pl", "de", "fr", "es"]
const ID := &"pin_tumbler_spool"
const LOCK_PATH := "res://scripts/photoreal/lock_photoreal.gd"

var _save_backup: Dictionary
var _settings_backup := {}
var _change_scenes := true


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)
	for k in ["auto_tension", "reduce_motion"]:
		_settings_backup[k] = Settings.get_value(k, false)
	_change_scenes = Events.change_scenes


func after_all() -> void:
	for k in _settings_backup:
		Settings.set_value(k, _settings_backup[k])
	Save.data = _save_backup
	Save.save()
	Events.change_scenes = _change_scenes
	JobRun.current_job = {}
	JobRun.mode = &"job"


func before_each() -> void:
	Save.data.erase("lessons")
	Save.set_value("jobs_completed", ["a", "b", "c", "d", "e", "f", "g"])  # past the first-jobs coach
	Settings.set_value("reduce_motion", false)
	Events.change_scenes = false
	Events.last_target = ""
	JobRun.mode = &"job"
	JobRun.current_job = {}


func _native() -> bool:
	return ClassDB.class_exists("LockcoreSession")


static func _pin_jobs() -> Array:
	var out: Array = JobRun.all_jobs().filter(func(j: Dictionary) -> bool:
		return JobRun.family_for(j) == &"pin_tumbler" and JobRun.is_playable(j) and not JobRun.is_talk(j) \
				and not String(j.get("id", "")).begins_with("job.refuse"))
	var list_script: GDScript = load("res://scripts/ui/jobs_list.gd")
	out.sort_custom(list_script.job_before)
	return out


## The first pin_tumbler job of the career at the family's first tier with security pins.
static func _first_risky() -> Dictionary:
	for j: Dictionary in _pin_jobs():
		if not TutorialCoach.caution_for(&"pin_tumbler", JobRun.tier_for(j)).is_empty():
			return j
	return {}


func _open(job: Dictionary, auto: bool = false) -> Node:
	Settings.set_value(&"auto_tension", auto)
	JobRun.start(job)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load(JobRun.lock_scene_path()).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(3)
	scene.set_physics_process(false)
	scene.sampler.set_physics_process(false)
	return scene


func _step(scene: Node, tension: float, depth: float, lift: float) -> void:
	scene.sampler.tension = tension
	scene.sampler.pick_depth = depth
	scene.sampler.pick_lift = lift
	scene._physics_process(1.0 / HZ)


## A player who does what the lesson says: holds the tension, lifts the binding pin to its click, and
## when the spool is caught eases the tension into the counter-rotation band and keeps lifting.
## Auto tension (D-52): the game holds and eases the wrench (sampler.auto_level), the player only lifts.
func _play(scene: Node, auto: bool, max_s: float = 40.0) -> bool:
	var target := -1
	var lift := 0.0
	for i in int(max_s * HZ):
		var els: Array = scene.session.describe()["elements"]
		var n := els.size()
		var b := -1
		var caught := false
		for k in n:
			var st := String(els[k]["state"])
			if b < 0 and st in ["bound", "near", "false_set"]:
				b = k
			caught = caught or st == "false_set"
		if b != target:
			target = b
			lift = 0.0
		var t: float = scene.sampler.auto_level if auto else (0.17 if caught else 0.32)
		if b >= 0:
			lift = minf(lift + 0.25 / HZ, 1.0)
		_step(scene, t, (maxi(b, 0) + 0.5) / n, lift)
		if scene.session.finished():
			return scene.session.is_open()
	return false


func _buttons(n: Node, out: Array = []) -> Array:
	if n is BaseButton:
		out.append(n)
	for c in n.get_children():
		_buttons(c, out)
	return out


# ------------------------------------------------------------------ data
func test_lesson_data_lock_and_lines() -> void:
	assert_eq(TutorialCoach.security_lesson_id(&"pin_tumbler"), ID, "the tool-caution table names the lesson")
	assert_eq(TutorialCoach.security_lesson_id(&"wafer"), &"", "a family without security pins has none")
	assert_false(TutorialCoach.has_lesson_for(&"pin_tumbler"), "not a family lesson: the pin tumbler keeps S1–S3")
	var l := TutorialCoach.load_lesson(ID)
	assert_false(l.is_empty(), "the lesson file loads")
	assert_eq(String(l.get("family", "")), "pin_tumbler")
	assert_true(FileAccess.file_exists(String(l.get("lock", ""))), "its authored lock ships")
	assert_eq((l["trap"]["states"] as Array), ["false_set"], "exactly one trap: the false set")
	var keys: Array = [l["trap"]["text"], l["trap"]["text_auto"], l["done"], "pause.skip_lesson"]
	for st: Dictionary in l["steps"]:
		assert_true(st.has("id") and st.has("until"), "step has id + until")
		keys.append(st["text"])
		if st.has("text_auto"):
			keys.append(st["text_auto"])
	var rows := {}
	for r in (I18n._parse_csv("res://i18n/strings.csv") as Array).slice(1):
		rows[String(r[0])] = r
	for k: String in keys:
		assert_has(rows, k, "%s exists" % k)
		var row: PackedStringArray = rows.get(k, PackedStringArray())
		assert_eq(row.size(), LANGS.size() + 1, "%s in five languages" % k)
		for i in range(1, row.size()):
			assert_between(row[i].length(), 8, 56, "%s (%s) fits two chalk lines" % [k, LANGS[i - 1]])


func test_lesson_lock_is_three_stacks_with_the_spool_in_the_middle() -> void:
	if not _native():
		pending("needs the lockcore GDExtension")
		return
	var l := TutorialCoach.load_lesson(ID)
	var s: RefCounted = ClassDB.instantiate("LockcoreSession")
	assert_true(s.create_from_json(FileAccess.get_file_as_string(String(l["lock"]))), "strict parser takes the lock: %s" % [s.last_errors()])
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(String(l["lock"])))
	var stacks: Array = d["spec"]["stacks"]
	assert_eq(stacks.size(), 3)
	assert_eq(stacks.map(func(k: Dictionary) -> String: return String(k["variant"])), ["standard", "spool", "standard"])
	assert_lt(int(stacks[0]["order_q16"]), int(stacks[1]["order_q16"]), "a plain pin binds first: the player has a clean click to compare")
	# the way out the lesson teaches (ease_level) lies inside the lock's counter-rotation band
	var ease := float(l["trap"]["ease_level"]) * 65536.0
	assert_between(ease, float(d["spec"]["cr_lo_q16"]), float(d["spec"]["cr_hi_q16"]), "ease level inside [cr_lo, cr_hi]")
	assert_gt(float(l["tension"]) * 65536.0, float(d["spec"]["cr_hi_q16"]), "the working tension is above the band: the spool has to be eased")


# ------------------------------------------------------------------ pure logic
func _vm(states: Array, open: bool = false) -> Dictionary:
	var els := []
	for s in states:
		els.append({"state": s, "position": 0.0, "window_lo": 0.45, "window_hi": 0.55})
	return {"elements": els, "open": open, "stress": 0.0}


func _feed(c: TutorialCoach, vm: Dictionary, events: Array, s: float, tension: float = 0.32, lift: float = 0.2) -> void:
	for i in int(s * HZ):
		c.update(vm, {"tension": tension, "pick_lift": lift}, events if i == 0 else [], true, true, 1.0 / HZ)


func test_steps_first_pin_then_the_false_set_then_free() -> void:
	var c := TutorialCoach.new(0, false, false)
	c.set_lesson(TutorialCoach.load_lesson(ID))
	assert_eq(c.text_key(), &"tutorial.spool.step1")
	_feed(c, _vm(["bound", "free", "free"]), [], 0.6)
	assert_eq(c.text_key(), &"tutorial.spool.step2", "tension held: the first pin")
	_feed(c, _vm(["set", "bound", "free"]), [{"kind": &"set"}], 0.2)
	assert_eq(c.text_key(), &"tutorial.spool.step3", "clean click: now the middle pin")
	_feed(c, _vm(["set", "false_set", "free"]), [{"kind": &"false_set"}], 0.5)
	assert_true(c.lesson_trap, "the spool is caught: the trap line")
	assert_eq(c.text_key(), &"tutorial.spool.trap")
	_feed(c, _vm(["set", "false_set", "free"]), [{"kind": &"counter_rotate"}], 3.0, 0.17)
	assert_eq(c.text_key(), &"tutorial.spool.trap", "stays while the spool sits in the false set")
	_feed(c, _vm(["set", "set", "bound"]), [{"kind": &"set"}], TutorialCoach.TRAP_MIN_S + 0.2)
	assert_false(c.lesson_trap)
	assert_eq(c.lesson_step_id(), &"free", "the spool is set: no line, the last pin is the player's")
	assert_eq(c.text_key(), &"")
	_feed(c, _vm(["set", "set", "set"], true), [{"kind": &"open"}], 0.1)
	assert_eq(c.text_key(), &"tutorial.spool.done")
	assert_eq(c.lesson_history, [&"hold", &"first", &"spool", &"false_set", &"free", &"done"] as Array[StringName])


func test_auto_tension_lines_and_a_dropped_lock_teaches_again() -> void:
	var c := TutorialCoach.new(0, false, true)
	c.set_lesson(TutorialCoach.load_lesson(ID))
	assert_eq(c.text_key(), &"tutorial.spool.step1_auto", "the game holds the tension")
	_feed(c, _vm(["bound", "free", "free"]), [], 0.2)
	_feed(c, _vm(["set", "bound", "free"]), [{"kind": &"set"}], 0.2)
	_feed(c, _vm(["set", "false_set", "free"]), [{"kind": &"false_set"}], 0.5)
	assert_eq(c.text_key(), &"tutorial.spool.trap_auto", "the game eases the wrench: keep lifting")
	# everything dropped (eased too far): the lock is back at the start; the trap line returns with the next false set
	_feed(c, _vm(["bound", "free", "free"]), [{"kind": &"drop"}], TutorialCoach.TRAP_MIN_S + 0.2)
	assert_eq(c.text_key(), &"")
	_feed(c, _vm(["set", "false_set", "free"]), [{"kind": &"false_set"}], 0.5)
	assert_eq(c.text_key(), &"tutorial.spool.trap_auto")


# ------------------------------------------------------------------ when it is due
func test_due_before_the_first_risky_tier_once_in_jobs_and_the_run() -> void:
	var lp: GDScript = load(LOCK_PATH)
	var first: int = int(TutorialCoach.caution_table()["pin_tumbler"]["tier"])
	assert_true(TutorialCoach.security_lesson_for(&"pin_tumbler", first - 1).is_empty(), "below the tier: none")
	assert_false(TutorialCoach.security_lesson_for(&"pin_tumbler", first).is_empty(), "the first tier with security pins")
	assert_false(TutorialCoach.security_lesson_for(&"pin_tumbler", first + 2).is_empty(), "and above (a career that skips a tier)")
	assert_true(TutorialCoach.security_lesson_for(&"lever", 5).is_empty(), "families without a security lesson")
	if not _native():
		pending("the lock screen plays the lesson only on real lockcore")
		return
	assert_true((lp.pre_lesson_for(&"pin_tumbler", first, {}) as Dictionary).is_empty(), "no job (dev scene): none")
	JobRun.start({"id": "job.x", "family": "pin_tumbler", "tier": first})
	assert_false((lp.pre_lesson_for(&"pin_tumbler", first, {}) as Dictionary).is_empty(), "a job at the tier")
	assert_true((lp.pre_lesson_for(&"pin_tumbler", first - 1, {}) as Dictionary).is_empty(), "a job below it")
	assert_true((lp.pre_lesson_for(&"pin_tumbler", first, {"lw-spool": "0"}) as Dictionary).is_empty(), "--lw-spool 0")
	JobRun.mode = &"run"
	assert_false((lp.pre_lesson_for(&"pin_tumbler", first, {}) as Dictionary).is_empty(), "the continuous run reaches the tier first")
	JobRun.mode = &"tutorial"
	assert_true((lp.pre_lesson_for(&"pin_tumbler", first, {}) as Dictionary).is_empty(), "never in the tutorial")
	JobRun.mode = &"practice"
	assert_true((lp.pre_lesson_for(&"pin_tumbler", first, {}) as Dictionary).is_empty(), "never in practice")
	JobRun.mode = &"job"
	TutorialCoach.mark_lesson_done(ID)
	assert_true((lp.pre_lesson_for(&"pin_tumbler", first, {}) as Dictionary).is_empty(), "done: not again")
	assert_false((lp.pre_lesson_for(&"pin_tumbler", 2, {"lw-spool": "1"}) as Dictionary).is_empty(), "--lw-spool 1 (dev, screenshots)")


func test_career_meets_the_lesson_before_its_first_security_pin() -> void:
	var first: int = int(TutorialCoach.caution_table()["pin_tumbler"]["tier"])
	var jobs := _pin_jobs()
	assert_gt(jobs.size(), 0)
	var risky := _first_risky()
	if risky.is_empty():
		pending("no pin_tumbler job at the risky tier (the continuous run reaches it)")
		return
	for j: Dictionary in jobs:
		if j["id"] == risky["id"]:
			break
		assert_lt(JobRun.tier_for(j), first, "%s comes before the lesson and has no security pin" % j["id"])


# ------------------------------------------------------------------ through the real scene
func test_lesson_lock_then_the_jobs_own_lock() -> void:
	var job := _first_risky()
	if not _native() or job.is_empty():
		pending("needs the lockcore GDExtension and a pin_tumbler job at the risky tier")
		return
	for auto in [false, true]:
		Save.data.erase("lessons")
		Save.set_value("stats/locks_opened", 5)
		var coins: int = Save.get_value("coins", 0)
		Events.last_target = ""
		var scene: Node = await _open(job, auto)
		var tag := "auto=%s" % auto
		watch_signals(Events)
		assert_false(scene.pre_lesson.is_empty(), tag + ": the lesson comes first")
		assert_eq(scene.session.describe()["elements"].size(), 3, tag + ": on its own three-pin lock")
		var coach: TutorialCoach = scene.coach
		assert_true(coach != null and coach.has_lesson() and not coach.lesson_quiet, tag + ": the lesson coach")
		assert_eq(scene.view.chalk_level, ChalkLayer.Level.FULL, tag + ": full chalk")
		assert_not_null(scene.hints, tag + ": hint ladder H1–H4")
		var skip := _buttons(scene.pause_cover).filter(func(b: BaseButton) -> bool: return b.text == I18n.t(&"pause.skip_lesson"))
		assert_eq(skip.size(), 1, tag + ": the pause offers to skip the lesson")
		JobRun.clean = false  # as after a drop in the lesson
		assert_true(_play(scene, auto), tag + ": the player who eases the tension opens the lesson lock")
		gut.p("%s: %s" % [tag, coach.lesson_history])
		for id: StringName in [&"first", &"spool", &"false_set", &"done"]:
			assert_has(coach.lesson_history, id, tag + ": step %s showed" % id)
		assert_lt(coach.lesson_history.find(&"first"), coach.lesson_history.find(&"false_set"), tag + ": clean click before the false set")
		assert_eq(coach.text_key(), &"tutorial.spool.done", tag + ": the closing line")
		assert_eq(Events.last_target, "", tag + ": the closing line holds the screen for a moment")
		for i in int(2.2 * HZ):
			_step(scene, 0.0, 0.5, 0.0)
		assert_eq(Events.last_target, JobRun.lock_scene_path(), tag + ": then the same screen loads the job's lock")
		assert_signal_not_emitted(Events, "lock_opened", tag + ": no payment, no achievements for the lesson lock")
		assert_true(TutorialCoach.lesson_done(ID), tag + ": the save records the lesson")
		assert_false(TutorialCoach.caution_done(&"pin_tumbler"), tag + ": the D-120 caution waits for the job's lock")
		assert_true(JobRun.clean, tag + ": the job starts clean (its tip is not lost in the lesson)")
		assert_eq(String(JobRun.current_job.get("id", "")), String(job["id"]), tag + ": the job is still on")
		assert_eq(int(Save.get_value("stats/locks_opened", 0)), 5, tag + ": no stats")
		assert_eq(int(Save.get_value("coins", 0)), coins, tag + ": no coins")
		assert_false((Save.get_value("jobs_completed", []) as Array).has(job["id"]), tag + ": the job is not done yet")
		# the screen again: the job's own lock, with the D-120 caution and no lesson
		var again: Node = await _open(job, auto)
		assert_true(again.pre_lesson.is_empty(), tag + ": the lesson runs once")
		assert_eq(again.session.describe()["elements"].size(), scene.make_session(&"pin_tumbler", JobRun.seed_for(job), JobRun.tier_for(job)).describe()["elements"].size(),
			tag + ": the job's generated lock")
		assert_true(again.coach != null and again.coach.has_caution() and again.coach.caution_only, tag + ": the tool caution of the first hard lock")
		var none := _buttons(again.pause_cover).filter(func(b: BaseButton) -> bool: return b.text == I18n.t(&"pause.skip_lesson"))
		assert_eq(none.size(), 0, tag + ": no skip plate on a job's lock")


func test_broken_tool_restarts_the_lesson_and_costs_nothing() -> void:
	var job := _first_risky()
	if not _native() or job.is_empty():
		pending("needs the lockcore GDExtension and a pin_tumbler job at the risky tier")
		return
	Save.set_value("stats/locks_broken", 2)
	var scene: Node = await _open(job)
	watch_signals(Events)
	# a heavy hand: full tension, pressing the binding pin until the tool gives
	for i in 30 * HZ:
		_step(scene, 1.0, 0.5 / 3.0, 0.9)
		if scene.session.finished():
			break
	assert_true(scene.session.finished() and not scene.session.is_open(), "the tool breaks in the lesson lock too")
	_step(scene, 0.0, 0.5, 0.0)
	assert_signal_not_emitted(Events, "lock_failed", "not a failed job")
	assert_eq(int(Save.get_value("stats/locks_broken", 0)), 2, "no broken-lock statistic")
	assert_eq(String(JobRun.current_job.get("id", "")), String(job["id"]), "the job stays on")
	assert_true(scene._pre_failed, "the restart is on its way (after the broken pick was seen)")
	scene._restart_pre_lesson()
	assert_eq(Events.last_target, JobRun.lock_scene_path(), "the lesson lock starts again")
	assert_false(TutorialCoach.lesson_done(ID), "still to be learnt")
	# the strain line of D-120 is there in the lesson (its caution is not used up by it)
	var again: Node = await _open(job)
	assert_false(again.pre_lesson.is_empty())
	var vm: Dictionary = again.session.describe().duplicate(true)
	vm["stress"] = 0.8
	again.coach.update(vm, {"tension": 0.6, "pick_lift": 0.2}, [], true, true, 1.0 / HZ)
	assert_eq(again.coach.text_key(), &"lock.caution_stress", "the tool bends: 'ease off' over the lesson line")
	assert_true(again.coach.strain, "and the chalk arrow at the wrench")
	again._note_lesson_open()
	assert_false(TutorialCoach.caution_done(&"pin_tumbler"), "the lesson lock does not use the caution up")


func test_pause_skips_the_lesson() -> void:
	var job := _first_risky()
	if not _native() or job.is_empty():
		pending("needs the lockcore GDExtension and a pin_tumbler job at the risky tier")
		return
	var scene: Node = await _open(job)
	assert_false(scene.pre_lesson.is_empty())
	scene._on_skip_lesson()
	assert_false(get_tree().paused)
	assert_true(TutorialCoach.lesson_done(ID), "skipped = not offered again (the lesson is optional)")
	assert_eq(Events.last_target, JobRun.lock_scene_path(), "straight to the job's lock")
	var again: Node = await _open(job)
	assert_true(again.pre_lesson.is_empty())


func test_lower_tiers_tutorial_and_practice_are_untouched() -> void:
	if not _native():
		pending("needs the lockcore GDExtension")
		return
	var easy: Dictionary = _pin_jobs()[0]
	var scene: Node = await _open(easy)
	assert_true(scene.pre_lesson.is_empty(), "%s (t%d): no lesson" % [easy["id"], JobRun.tier_for(easy)])
	JobRun.start_tutorial(2)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var tut: Node = load(JobRun.lock_scene_path()).instantiate()
	vp.add_child(tut)
	await wait_physics_frames(2)
	assert_true(tut.pre_lesson.is_empty(), "S3 is S3")
	assert_false(TutorialCoach.lesson_done(ID))


func test_false_set_is_shown_in_three_channels_and_marked_in_chalk() -> void:
	var job := _first_risky()
	if not _native() or job.is_empty():
		pending("needs the lockcore GDExtension and a pin_tumbler job at the risky tier")
		return
	var scene: Node = await _open(job)
	watch_signals(Events)
	scene._simulate_stage("false_set")  # the dev stage of the screenshots: first pin set, the spool caught
	var vm: Dictionary = scene.session.describe()
	assert_eq(vm["elements"].map(func(e: Dictionary) -> String: return String(e["state"])), ["set", "false_set", "free"])
	assert_eq(scene.coach.text_key(), &"tutorial.spool.trap", "the lesson names it")
	scene.view.present(vm, {"tension": 0.35, "pick_depth": 0.5, "pick_lift": 0.4}, 1.0 / HZ)
	# picture: the chalk layer gets the caught stack (dashed frame at the shear line, DESIGN §1) next to the set one
	var stacks: Array = scene.view._chalk.marks.get("stacks", [])
	assert_eq(stacks.size(), 3)
	assert_eq(String(stacks[0]["state"]), "set")
	assert_eq(String(stacks[1]["state"]), "false_set", "the chalk frame is drawn for this stack")
	assert_eq(scene.view._chalk.text, I18n.t(&"tutorial.spool.trap"), "and the line is written")
	# sound and haptics: the event has its own sound and its own pattern (never haptics alone)
	assert_false((Haptics.pattern_for(&"false_set") as Dictionary).is_empty(), "haptic pattern for false_set")
	assert_ne(Haptics.pattern_for(&"false_set"), Haptics.pattern_for(&"set"), "not the pattern of a set")
	assert_not_null(Sfx._stream_for(&"false_set", &"brass"), "sound for false_set")
	assert_not_null(Sfx._stream_for(&"counter_rotate", &"brass"), "sound for the counter-rotation")
