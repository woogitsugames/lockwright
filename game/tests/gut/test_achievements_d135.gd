extends GutTest
## D-135: every achievement can be earned. D-133 found that 24 of the 48 had a trigger nobody
## reported (job results and refusals, lessons, practice, the continuous shift, the dark, the
## workshop). Each test below drives the game's own code for one group — the verification screen and
## the receipt, the lock screens (real scenes; only lockcore's events are scripted), Practice, the
## continuous shift's bookkeeping in Events / RunState, the Workshop — and checks both that the
## achievement comes and that it does not come when its condition is not met.

const DT := 1.0 / 120.0
const VERIFY := "res://scenes/job_verify.tscn"
const PAYMENT := "res://scenes/job_payment.tscn"
## The 24 achievements D-133 could not award.
const WERE_DEAD := ["pin_school", "wafer_school", "pin_master", "wafer_master", "ring_false",
	"first_dark", "dark_clean", "one_pick", "daily_lock", "timed_care", "bench_stop", "tool_care",
	"permission", "witness", "first_no", "ex_partner", "bribe", "aunt_alive", "wrong_floor", "heirs", "partial_refusal",
	"museum_papers", "kazimierz", "capsule"]


## Stands in for lockcore on a real lock screen: the screen, its view, Events and Achievements run
## their own code; the events of each step come from `steps` (one Array per step). The view model
## stays the real session's.
class ScriptedSession extends FakeLockSession:
	var inner: RefCounted
	var steps: Array = []
	var t := 0
	var opened := false
	var broken := false

	func step(_tension: float, _depth: float, _lift: float) -> Array:
		t += 1
		if steps.is_empty():
			return []
		var evs: Array = steps.pop_front()
		for e: Dictionary in evs:
			e["tick"] = t
			opened = opened or e["kind"] == &"open"
			broken = broken or e["kind"] == &"break"
		return evs

	func finished() -> bool:
		return opened or broken

	func is_open() -> bool:
		return opened

	func failure() -> StringName:
		return &"break" if broken else &""

	func describe() -> Dictionary:
		return inner.describe()


var _save_backup: Dictionary
var _went: Array = []
var _auto_before: Variant
var _milestones: Array = []


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)
	_auto_before = Settings.get_value("auto_tension", false)
	Events.milestone.connect(_note_milestone)


func after_all() -> void:
	Events.milestone.disconnect(_note_milestone)
	Settings.set_value("auto_tension", _auto_before)
	Save.data = _save_backup
	Save.save()


func before_each() -> void:
	Save.data = Save.DEFAULTS.duplicate(true)
	Save.data["achievements"] = []
	Save.data["achievements_at"] = {}
	Save.data["jobs_completed"] = []
	Save.data["tutorial_done"] = true
	Save.set_value("lessons/pin_tumbler_spool/done", true)  # D-121: no security lesson lock in front of a pin job
	Achievements.reset_run_counts()
	Events.change_scenes = false
	Events.last_target = ""
	Events.lock_dark = false
	Events._fail_scene = null
	var dummy := Node.new()
	add_child_autofree(dummy)
	Events.scene_override = dummy
	JobRun.current_job = {}
	JobRun.mode = &"job"
	JobRun.checked = []
	Practice.current = {}
	Practice.last_result = &""
	RunState.reset()
	_went = []
	_milestones = []


func after_each() -> void:
	Events.change_scenes = true
	Events.scene_override = null
	Events._fail_scene = null
	Events.lock_dark = false
	Practice.current = {}
	Practice.met_now = false
	Practice.last_result = &""
	RunState.reset()
	JobRun.current_job = {}
	JobRun.mode = &"job"
	JobRun.checked = []
	Achievements.reset_run_counts()


func _note_milestone(kind: StringName, data: Dictionary) -> void:
	_milestones.append([kind, data])


func _has(id: String) -> bool:
	return Achievements.is_unlocked("achievement." + id)


func _ev(kind: String, sub := 0) -> Dictionary:
	return {"kind": StringName(kind), "sub": sub, "name": StringName("%s.%d" % [kind, sub]), "element": 0,
			"intensity": 0.6, "material": &"brass"}


## The lock screen of JobRun.current_job, as the game opens it, with lockcore's events scripted.
func _lock() -> Node:
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load(JobRun.lock_scene_path()).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(2)
	scene.set_physics_process(false)
	scene.sampler.set_physics_process(false)
	scene.open_payoff_s = 0.0
	var s := ScriptedSession.new()
	s.inner = scene.session
	scene.session = s
	Events.scene_override = scene
	Achievements.reset_run_counts()
	return scene


## Plays the scripted steps, then `extra` idle steps (a lesson holds the open lock for its closing line).
func _play(scene: Node, batches: Array, extra := 2) -> void:
	scene.session.steps.append_array(batches)
	for i in batches.size() + extra:
		scene.sampler._physics_process(DT)
		scene._physics_process(DT)


func _close(scene: Node) -> void:
	Events.scene_override = null
	scene.get_parent().queue_free()
	await get_tree().process_frame


func _verify(job_id: String) -> Control:
	var job := JobRun.job_by_id(job_id)
	assert_false(job.is_empty(), "%s exists" % job_id)
	JobRun.start(job)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var v: Control = load(VERIFY).instantiate()
	v.go_override = func(path: String) -> void: _went.append(path)
	v.decision_pause_s = 0.0
	vp.add_child(v)
	await get_tree().process_frame
	await get_tree().process_frame
	return v


func _ask(v: Control, card: String) -> void:
	var tile := v.cards_box.get_node_or_null("Card_" + card) as Button
	assert_not_null(tile, "card %s is on the table" % card)
	if tile != null:
		tile.pressed.emit()


## The rest of a visit after the papers: open (the lock itself is covered by the lock tests), the
## receipt, Continue (job_payment.gd settles through _complete_once on Continue and on Back).
func _accept_open_and_pay(v: Control) -> void:
	var talk := JobRun.is_talk(JobRun.current_job)
	v.accept_button.pressed.emit()
	if not talk:
		assert_eq(String(_went.back()), JobRun.lock_scene_path(), "accept goes to the job's lock")
		Events.lock_event.emit(_ev("open"))
		Events.lock_opened.emit()
		assert_eq(Events.last_target, Events.PAYMENT, "an open lock goes to the receipt")
	else:
		assert_eq(String(_went.back()), PAYMENT)
	await _pay()


func _pay() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var pay: Control = load(PAYMENT).instantiate()
	vp.add_child(pay)
	await get_tree().process_frame
	pay._complete_once()
	vp.queue_free()
	await get_tree().process_frame


func _first_job(fam: String, min_tier := 1) -> Dictionary:
	var out: Array = []
	for j: Dictionary in JobRun.all_jobs():
		if j.get("family", "") == fam and int(j.get("tier", 1)) >= min_tier and not String(j["id"]).begins_with("job.refuse") \
				and not JobRun.is_talk(j) and JobRun.is_playable(j):
			out.append(j)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	return out[0] if not out.is_empty() else {}


# ------------------------------------------------------------------ data and shelf
func test_every_achievement_has_a_trigger_the_game_reports() -> void:
	assert_eq(Achievements.defs.size(), 48)
	var src := ""
	for path in ["res://scripts/lock/job_run.gd", "res://scripts/ui/job_verify.gd", "res://scripts/lock/practice.gd",
			"res://scripts/autoload/events.gd", "res://scripts/ui/workshop_screen.gd", "res://scripts/photoreal/lock_photoreal.gd"]:
		src += FileAccess.get_file_as_string(path)
	for d: Dictionary in Achievements.defs:
		var id := String(d["id"])
		assert_true(Achievements.supported(d), "%s: the game understands \"%s\"" % [id, d["trigger"]])
		var t := Achievements.parse_trigger(String(d["trigger"]))
		if t.get("head", "") == "milestone":
			assert_true(src.contains("milestone.emit(&\"%s\"" % t["what"]), "%s: somebody emits %s" % [id, t["what"]])
		for c: Array in t.get("conds", []):
			if c[0] == "family":
				assert_true(JobRun.FAMILY_MAP.has(Achievements._family_name(String(c[2]))) or t["head"] == "milestone",
						"%s: family %s is in the game" % [id, c[2]])
			if c[0] == "job":
				assert_false(JobRun.job_by_id(String(c[2])).is_empty(), "%s: job %s exists" % [id, c[2]])
	for id: String in WERE_DEAD:
		assert_true(Achievements.supported(Achievements.def_by_id("achievement." + id)), id)
	# a trigger the game does not know is still refused (strict, D-133)
	for bad in ["result=challenge_complete;challenge=daily", "result=open;profile=pin.m5", "event=tool_bought;first=true",
			"result=job_completed;partial_refusal=true", "tutorial.completed=pin.s3", "result=open;family=ring_combo", ""]:
		assert_false(Achievements.supported({"trigger": bad}), "\"%s\" is not a trigger of the game" % bad)


func test_job_achievements_name_cards_their_jobs_have() -> void:
	for d: Dictionary in Achievements.defs:
		var t := Achievements.parse_trigger(String(d["trigger"]))
		if t.get("what", "") != "job_completed":
			continue
		var job_id := ""
		var by := ""
		for c: Array in t["conds"]:
			if c[0] == "job":
				job_id = String(c[2])
			if c[0] == "verified_by":
				by = String(c[2])
		if job_id != "":
			var job := JobRun.job_by_id(job_id)
			assert_false(JobRun.is_talk(job), "%s: a lock is opened on %s" % [d["id"], job_id])
			assert_false((job.get("cards", []) as Array).is_empty(), "%s: %s has papers to check" % [d["id"], job_id])
			if by != "":
				assert_true((job.get("cards", []) as Array).has(by), "%s: %s has the card %s" % [d["id"], job_id, by])


func test_shelf_has_a_spot_for_all_48_and_hidden_ones_stay_a_question_mark() -> void:
	assert_eq(Achievements.shelf_defs().size(), 48)
	I18n.apply_language("pl")
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.disable_3d = true
	add_child_autofree(vp)
	var scene: Control = load("res://scenes/showcase.tscn").instantiate()
	vp.add_child(scene)
	for i in 6:
		await get_tree().process_frame
	scene.show_tab("shelf")
	await get_tree().process_frame
	await get_tree().process_frame
	var shelf: AchievementShelf = scene.shelf
	assert_eq(shelf.spots.size(), 48, "one spot per achievement")
	for cat: String in Achievements.CATEGORIES:
		assert_not_null(shelf.get_node_or_null("Bay_" + cat), "bay %s" % cat)
	var hidden := 0
	for d: Dictionary in Achievements.defs:
		var spot: Control = shelf.spot_for(d["id"])
		assert_not_null(spot, "%s has a spot" % d["id"])
		if bool(d.get("hidden", false)):
			hidden += 1
			assert_eq(spot.get_node("Empty").mark, "?", "%s: hidden, not earned" % d["id"])
			assert_eq(spot.get_node("Name").text, I18n.t(&"ach.hidden.name"))
			assert_false(UiA11y.spoken_name(spot).contains(I18n.t(StringName("ach.%s.name" % d["id"]))))
	assert_eq(hidden, 12, "ex_partner, bribe, heirs … stay a surprise")


# ------------------------------------------------------------------ Principles (ethics)
func test_permission_and_witness_need_the_papers_asked_about() -> void:
	# two papers on the table, a lock to open
	var job_id := "job.krakow_tenement_gate"
	var v := await _verify(job_id)
	await _accept_open_and_pay(v)
	assert_true((Save.get_value("jobs_completed", []) as Array).has(job_id))
	assert_false(_has("permission"), "opened without a look at the papers")
	assert_false(_has("kazimierz"))
	v = await _verify(job_id)
	_ask(v, "manager")
	await _accept_open_and_pay(v)
	assert_false(_has("permission"), "one of two papers is not every paper")
	v = await _verify(job_id)
	_ask(v, "manager")
	_ask(v, "resolution")
	await _accept_open_and_pay(v)
	assert_true(_has("permission"), "every paper asked about, then the lock opened")
	assert_true(_has("kazimierz"), "Stories: the Kazimierz gate after both papers")
	assert_false(_has("witness"), "no witness on this job")
	assert_eq(Achievements.unlocked_on("achievement.permission"), Time.get_date_string_from_system())


func test_witness_counts_when_the_neighbour_was_asked() -> void:
	var job := JobRun.job_by_id("job.grandma_broth")
	assert_eq(job.get("cards", []), ["witness", "letter", "photo"])
	var v := await _verify("job.grandma_broth")
	_ask(v, "letter")
	await _accept_open_and_pay(v)
	assert_false(_has("witness"), "the witness was on the table but nobody asked")
	v = await _verify("job.grandma_broth")
	_ask(v, "witness")
	await _accept_open_and_pay(v)
	assert_true(_has("witness"))
	assert_false(_has("permission"), "the third paper was never laid out")
	# "I need one more thing" lays out the third card and asks about it at once
	v = await _verify("job.grandma_broth")
	_ask(v, "witness")
	_ask(v, "letter")
	v.ask_more_button.pressed.emit()
	assert_true(JobRun.checked.has("photo"))
	await _accept_open_and_pay(v)
	assert_true(_has("permission"))


func test_a_visit_settled_by_talking_opens_nothing() -> void:
	var talk := {}
	for j: Dictionary in JobRun.all_jobs():
		if JobRun.is_talk(j) and (j.get("cards", []) as Array).size() == 2 and not j.has("ask_more"):
			talk = j
			break
	assert_false(talk.is_empty(), "a talk job with two cards")
	var v := await _verify(String(talk["id"]))
	for c in talk["cards"]:
		_ask(v, String(c))
	await _accept_open_and_pay(v)
	assert_true((Save.get_value("jobs_completed", []) as Array).has(String(talk["id"])))
	assert_false(_has("permission"), "permission is about opening a lock")


func test_refusals() -> void:
	# declining an honest job is not "the right no"
	var v := await _verify("job.krakow_tenement_gate")
	v.refuse_button.pressed.emit()
	assert_false(_has("first_no"))
	assert_eq(String(_went.back()), "res://scenes/jobs_list.tscn")
	for pair: Array in [["job.refuse_ex_partner", "ex_partner"], ["job.refuse_rush_bribe", "bribe"], ["job.refuse_aunt_alive", "aunt_alive"]]:
		assert_false(_has(pair[1]))
		v = await _verify(pair[0])
		assert_false(v.accept_button.visible, "%s cannot be opened" % pair[0])
		v.refuse_button.pressed.emit()
		assert_true(_has(pair[1]), "%s refused" % pair[0])
		assert_true(_has("first_no"))
		assert_true((Save.get_value("jobs_refused", []) as Array).has(pair[0]))
	# another refusal job gives only "the right no"
	Save.data["achievements"] = []
	var other := ""
	for j: Dictionary in JobRun.all_jobs():
		var id := String(j["id"])
		if id.begins_with("job.refuse") and not ["job.refuse_ex_partner", "job.refuse_rush_bribe", "job.refuse_aunt_alive"].has(id):
			other = id
			break
	v = await _verify(other)
	v.refuse_button.pressed.emit()
	assert_eq(Achievements.unlocked_ids(), ["achievement.first_no"], other)


func test_wrong_floor_is_settled_by_the_question() -> void:
	var v := await _verify("job.wrong_floor")
	assert_false(_has("wrong_floor"))
	v.ask_more_button.pressed.emit()
	await get_tree().process_frame
	assert_true(_has("wrong_floor"), "asked for one more thing: it is the neighbour's door")
	assert_eq(String(_went.back()), PAYMENT, "paid as a visit, no lock")
	await _pay()
	assert_true((Save.get_value("jobs_completed", []) as Array).has("job.wrong_floor"))
	assert_false(_has("permission"), "no door was opened")


func test_heirs_and_the_antiquarian() -> void:
	for row: Array in [["job.uncle_safe_heirs", "heirs", ["deed", "inheritance"]], ["job.krakow_antiquarian", "partial_refusal", ["witness", "lease"]]]:
		var job_id: String = row[0]
		var cards: Array = row[2]
		assert_eq(JobRun.job_by_id(job_id).get("cards", []), cards)
		var v := await _verify(job_id)
		_ask(v, cards[0])
		await _accept_open_and_pay(v)
		assert_false(_has(row[1]), "%s: one paper is not enough" % job_id)
		v = await _verify(job_id)
		_ask(v, cards[0])
		_ask(v, cards[1])
		await _accept_open_and_pay(v)
		assert_true(_has(row[1]), "%s: both papers, then the safe" % job_id)


# ------------------------------------------------------------------ Stories
func test_story_jobs_need_their_paper() -> void:
	for row: Array in [["job.museum_time_lock", "museum_papers", "institution"], ["job.time_capsule", "capsule", "manager"]]:
		var v := await _verify(row[0])
		await _accept_open_and_pay(v)
		assert_false(_has(row[1]), "%s done without asking about the paper" % row[0])
		v = await _verify(row[0])
		_ask(v, row[2])
		await _accept_open_and_pay(v)
		assert_true(_has(row[1]), "%s after the %s paper" % [row[0], row[2]])
	# the papers of one job do not count for another
	assert_false(_has("kazimierz"))
	assert_true(_has("clock_repaired"), "the museum job ends through its lock (time_lock)")


# ------------------------------------------------------------------ Craft: lessons, practice, the lever's false notch
func test_three_pin_lessons() -> void:
	Save.data["tutorial_done"] = false
	for stage in 3:
		JobRun.start_tutorial(stage)
		var scene := await _lock()
		assert_false(_has("pin_school"), "before S%d opens" % (stage + 1))
		_play(scene, [[_ev("set")], [_ev("open")]], 300)
		assert_eq(Events.last_target, Events.TUTORIAL, "S%d: back to the lesson screen" % (stage + 1))
		assert_eq(JobRun.tutorial_stage, stage + 1)
		await _close(scene)
	assert_true(bool(Save.get_value("tutorial_done", false)))
	assert_true(_has("pin_school"), "S3 open: the three lessons are done")
	assert_false(_has("first_set"), "a set in the tutorial is not the first click")
	assert_false(_has("wafer_school"))


func test_family_lesson_on_its_first_job() -> void:
	var job := _first_job("dimple")
	assert_false(job.is_empty())
	# a plain pin job is no lesson
	JobRun.start(_first_job("pin_tumbler"))
	var scene := await _lock()
	_play(scene, [[_ev("open")]], 300)
	assert_false(_has("wafer_school"))
	await _close(scene)
	JobRun.start(job)
	scene = await _lock()
	var coach: TutorialCoach = scene.coach
	assert_true(coach != null and coach.has_lesson() and not coach.lesson_quiet, "the family's first job is its lesson")
	_play(scene, [[_ev("set")], [_ev("open")]], 300)
	assert_true(TutorialCoach.lesson_done(&"dimple"))
	assert_true(_has("wafer_school"), "the lesson of a new family, finished")
	assert_true(_has("dimple_first"))
	assert_eq(Events.last_target, Events.PAYMENT)
	await _close(scene)


func test_practice_goals() -> void:
	var pins: Array = Practice.entries().filter(func(e: Dictionary) -> bool: return e["family"] == &"pin_tumbler")
	var wafers: Array = Practice.entries().filter(func(e: Dictionary) -> bool: return e["family"] == &"wafer")
	assert_gt(pins.size(), 1)
	assert_gt(wafers.size(), 1)
	# open without the goal: nothing
	Practice.start(pins[0])
	var scene := await _lock()
	_play(scene, [[_ev("open")]])
	assert_eq(Practice.last_result, &"open")
	assert_false(_has("daily_lock"))
	await _close(scene)
	# the goal's event, then open: the first practice goal
	Practice.start(pins[0])
	scene = await _lock()
	var target := String(pins[0]["target"])
	var sub: Array = Practice.SUB_EVENTS.get(target, [target, 0])
	_play(scene, [[_ev(String(sub[0]), int(sub[1]))], [_ev("open")]])
	assert_eq(Practice.last_result, &"met")
	assert_true(Practice.goal_met(pins[0]["id"]))
	assert_true(_has("daily_lock"), "a practice goal reached")
	assert_false(_has("pin_master"), "%d pin goals still ahead" % Practice.goals_left(&"pin_tumbler"))
	assert_eq(Events.last_target, Events.WORKSHOP)
	await _close(scene)
	# every goal of the family: the last one brings the family's plate
	for row: Array in [[pins, "pin_master"], [wafers, "wafer_master"]]:
		var list: Array = row[0]
		for i in list.size() - 1:
			Save.set_value("practice/%s/goal" % list[i]["id"], true)
		var last: Dictionary = list.back()
		assert_false(_has(row[1]))
		Practice.start(last)
		scene = await _lock()
		target = String(last["target"])
		sub = Practice.SUB_EVENTS.get(target, [target, 0])
		_play(scene, [[_ev(String(sub[0]), int(sub[1]))], [_ev("open")]])
		assert_eq(Practice.goals_left(last["family"]), 0)
		assert_true(_has(row[1]), "every %s practice goal" % last["family"])
		await _close(scene)
	assert_false(_has("first_open"), "practice is not the continuous shift")


func test_lever_false_notch() -> void:
	var job := _first_job("lever")
	assert_false(job.is_empty())
	JobRun.start(job)
	var scene := await _lock()
	_play(scene, [[_ev("set")], [_ev("open")]])
	assert_false(_has("ring_false"), "no false notch on the way")
	assert_true(_has("lever_true"))
	await _close(scene)
	JobRun.start(job)
	scene = await _lock()
	_play(scene, [[_ev("false_set"), _ev("false_set", 1)], [_ev("set")], [_ev("open")]])
	assert_true(_has("ring_false"), "a false notch caught a lever, the lock still opened")
	await _close(scene)
	# the same on a pin lock is "Two Notes", not the lever's plate
	Save.data["achievements"] = []
	JobRun.start(_first_job("pin_tumbler", 3))
	scene = await _lock()
	_play(scene, [[_ev("false_set")], [_ev("open")]])
	assert_true(_has("false_note"))
	assert_false(_has("ring_false"))
	await _close(scene)


# ------------------------------------------------------------------ Modes: the dark, the continuous shift, the workshop
func test_in_the_dark() -> void:
	var job := _first_job("pin_tumbler")
	# light on all the way
	JobRun.start(job)
	var scene := await _lock()
	_play(scene, [[_ev("set")], [_ev("open")]])
	assert_false(_has("first_dark"))
	await _close(scene)
	# the light goes off only after the first set: not "in the dark"
	JobRun.start(job)
	scene = await _lock()
	_play(scene, [[_ev("bind")], [_ev("set")]], 0)
	scene._on_dark()
	assert_true(scene.view.dark)
	_play(scene, [[_ev("set")], [_ev("open")]])
	assert_false(_has("first_dark"), "a pin was set with the light on")
	await _close(scene)
	# off from the pause before anything is set, a drop on the way
	JobRun.start(job)
	scene = await _lock()
	assert_false(Events.lock_dark, "a new lock screen starts lit")
	_play(scene, [[_ev("contact")], [_ev("bind")]], 0)
	scene._on_dark()
	_play(scene, [[_ev("set")], [_ev("drop")], [_ev("set")], [_ev("open")]])
	assert_true(_has("first_dark"), "opened with the light off")
	assert_false(_has("dark_clean"), "there was a drop")
	await _close(scene)
	# and clean
	JobRun.start(job)
	scene = await _lock()
	scene._on_dark()
	_play(scene, [[_ev("set")], [_ev("open")]])
	assert_true(_has("dark_clean"))
	await _close(scene)
	# the light back on before the end: no
	Save.data["achievements"] = []
	JobRun.start(job)
	scene = await _lock()
	scene._on_dark()
	_play(scene, [[_ev("set")]], 0)
	scene._on_dark()
	assert_false(scene.view.dark)
	_play(scene, [[_ev("open")]])
	assert_false(_has("first_dark"), "the light was on when the lock opened")
	await _close(scene)


## One lock of the continuous shift, as run_loop.gd::_next_lock starts it.
func _run_lock(batches: Array) -> void:
	JobRun.mode = &"run"
	JobRun.current_job = RunState.next_job()
	JobRun.clean = true
	var scene := await _lock()
	_play(scene, batches, 2 if batches.back()[0]["kind"] == &"open" else 0)
	assert_eq(Events.last_target, Events.RUN_LOOP)
	await _close(scene)


func test_continuous_shift() -> void:
	RunState.reset()
	await _run_lock([[_ev("set")], [_ev("open")]])  # pin_tumbler
	assert_true(_has("first_open"))
	assert_false(_has("timed_care"))
	await _run_lock([[_ev("gate_align")], [_ev("open")]])  # warded
	assert_true(_has("iron_no_drop"), "a warded lock of the shift is judged as warded")
	assert_false(_has("timed_care"), "two in a row")
	await _run_lock([[_ev("open")]])  # wafer
	assert_true(_has("timed_care"), "three in a row, no broken pick")
	assert_true(_has("wafer_clean"))
	assert_false(_has("bench_stop"))
	await _run_lock([[_ev("open")]])  # lever
	await _run_lock([[_ev("open")]])  # dial_safe
	assert_eq(RunState.opened, 5)
	assert_true(_has("bench_stop"), "five locks opened in one shift")
	assert_true(_has("safe_first"), "the fifth lock of the shift is a dial safe")
	assert_false(_has("one_pick"), "three picks left")
	# a new shift: two picks broken, the third lock opens on the last one
	Save.data["achievements"] = []
	RunState.reset()
	await _run_lock([[_ev("open")]])
	await _run_lock([[_ev("stress")], [_ev("break")]])
	assert_eq(RunState.lives, 2)
	await _run_lock([[_ev("open")]])
	assert_false(_has("one_pick"), "two picks left")
	await _run_lock([[_ev("break")]])
	assert_eq(RunState.lives, 1)
	assert_eq(RunState.streak, 0)
	await _run_lock([[_ev("open")]])
	assert_true(_has("one_pick"), "opened with the last pick")
	assert_false(_has("timed_care"), "the breaks cut the row")
	assert_false(_has("bench_stop"), "three opened in this shift")


func test_buying_a_tool() -> void:
	var tool_id := "tl_shackle"
	for coins in [0, 1000]:
		Save.set_value("coins", coins)
		var vp := SubViewport.new()
		vp.size = Vector2i(412, 915)
		vp.disable_3d = true
		add_child_autofree(vp)
		var ws: Control = load("res://scenes/workshop.tscn").instantiate()
		vp.add_child(ws)
		await get_tree().process_frame
		await get_tree().process_frame
		var card := ws.find_child("Tool_" + tool_id, true, false) as Control
		assert_not_null(card, "the workshop lists %s" % tool_id)
		var action := card.find_child("Action", true, false) as Button
		assert_eq(action.disabled, coins == 0)
		action.pressed.emit()
		assert_eq(bool(Save.get_value("tools/%s/owned" % tool_id, false)), coins > 0)
		assert_eq(_has("tool_care"), coins > 0, "coins %d" % coins)
		vp.queue_free()
		await get_tree().process_frame


# ------------------------------------------------------------------ old saves
func test_achievements_in_a_save_are_kept_as_they_are() -> void:
	# a tester's save from before D-133 may hold plates the old loose check handed out; they stay
	# (no date on record), nothing is taken away on load, and they can not be earned twice
	Save.data["achievements"] = ["achievement.first_dark", "achievement.pin_master", "achievement.gone_from_the_data"]
	Save.data["achievements_at"] = {}
	Save.save()
	Save.load_save()
	assert_true(_has("first_dark"))
	assert_true(_has("pin_master"))
	assert_eq(Achievements.unlocked_on("achievement.first_dark"), "", "no invented date")
	assert_eq(AchievementShelf.status_text(Achievements.def_by_id("achievement.first_dark")), I18n.t(&"ach.earned"))
	Achievements.unlock("achievement.first_dark")
	assert_eq((Save.get_value("achievements", []) as Array).count("achievement.first_dark"), 1)
	assert_eq(Achievements.unlocked_on("achievement.first_dark"), "", "an old plate does not get today's date")
	assert_eq(Achievements.points_total(), 0 + int(Achievements.def_by_id("achievement.first_dark")["points"]) + int(Achievements.def_by_id("achievement.pin_master")["points"]))


func test_an_old_career_gets_what_its_save_proves() -> void:
	# a career played before D-135: tutorial done, a family lesson, two refusals, the wrong floor
	# settled, practice goals, a tool bought — none of it can be done a second time
	Save.data["tutorial_done"] = true
	Save.set_value("lessons/dimple/done", true)
	Save.data["jobs_refused"] = ["job.refuse_ex_partner", "job.refuse_aunt_alive"]
	Save.data["jobs_completed"] = ["job.wrong_floor", "job.krakow_tenement_gate", "job.uncle_safe_heirs"]
	for e: Dictionary in Practice.entries():
		if e["family"] == &"wafer":
			Save.set_value("practice/%s/goal" % e["id"], true)
	Save.set_value("tools/tl_shackle/owned", true)
	Achievements.backfill()
	for id in ["pin_school", "wafer_school", "first_no", "ex_partner", "aunt_alive", "wrong_floor", "daily_lock", "wafer_master", "tool_care"]:
		assert_true(_has(id), "%s: the save proves it" % id)
		assert_eq(Achievements.unlocked_on("achievement." + id), "", "%s: no invented day" % id)
	for id in ["bribe", "pin_master", "permission", "kazimierz", "heirs", "first_dark", "one_pick", "bench_stop", "witness"]:
		assert_false(_has(id), "%s: not in the save, or not provable from it" % id)
	var n := Achievements.unlocked_ids().size()
	Achievements.backfill()
	assert_eq(Achievements.unlocked_ids().size(), n, "running it again changes nothing")
	# a fresh save gets nothing
	Save.data = Save.DEFAULTS.duplicate(true)
	Save.data["achievements"] = []
	Achievements.backfill()
	assert_eq(Achievements.unlocked_ids(), [])
