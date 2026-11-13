extends GutTest
## D-120: the tool caution. A heavy hand starts to break tools at the first tier of a family that has a
## false gate (heavy-hand bot, D-118), so the first lock played at or above that tier
## (res://data/tool_caution.json) gets a caution from TutorialCoach, in the coach's chalk handwriting.
## Checked here:
##   - the table: families and tiers lockcore has (lockcore/tiers.json), lines in five languages;
##   - pure logic: intro until the first set, the trap line in a false set, the strain line and flag
##     while the tool bends, nothing once the lock is open; a guided lesson keeps its own lines;
##   - through the real scene: the first risky job of a family carries the caution (also with the
##     chalk layer off and without a coach of its own), the line and the wrench arrow are drawn,
##     the save records it on open, the next lock has none; a lock below the tier never has one.

const HZ := 120
const LANGS := ["en", "pl", "de", "fr", "es"]
const LockcoreTiers := preload("res://tests/lockcore_tiers.gd")

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
	Save.set_value("jobs_completed", ["a", "b", "c", "d", "e", "f", "g"])  # past the first-jobs coach
	Settings.set_value("reduce_motion", false)


func _vm(states: Array, stress: float = 0.0, open: bool = false) -> Dictionary:
	var els := []
	for s in states:
		els.append({"state": s, "position": 0.0, "window_lo": 0.45, "window_hi": 0.55})
	return {"elements": els, "open": open, "stress": stress}


func _feed(c: TutorialCoach, vm: Dictionary, events: Array, s: float) -> void:
	for i in int(s * HZ):
		c.update(vm, {"tension": 0.3, "pick_lift": 0.0}, events if i == 0 else [], true, true, 1.0 / HZ)


func _coach(fam: StringName, tier: int) -> TutorialCoach:
	var c := TutorialCoach.new(0, false, false)
	c.family = fam
	c.caution_only = true
	c.set_caution(TutorialCoach.caution_for(fam, tier))
	return c


static func _jobs(fam: StringName) -> Array:
	var out: Array = JobRun.all_jobs().filter(func(j: Dictionary) -> bool: return JobRun.family_for(j) == fam and JobRun.is_playable(j))
	var list_script: GDScript = load("res://scripts/ui/jobs_list.gd")
	out.sort_custom(list_script.job_before)
	return out


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


# ------------------------------------------------------------------ data
func test_table_names_tiers_lockcore_has_and_lines_in_five_languages() -> void:
	var table := TutorialCoach.caution_table()
	assert_eq(table.size(), 6, "six families have a tool that a heavy hand breaks")
	var tiers: Dictionary = LockcoreTiers.ranges()
	if tiers.is_empty():
		gut.p("lockcore/tiers.json not reachable (exported pack); ranges checked in the repository run")
	var rows := {}
	for r in (I18n._parse_csv("res://i18n/strings.csv") as Array).slice(1):
		rows[String(r[0])] = r
	for fam: String in table:
		var e: Dictionary = table[fam]
		assert_true(JobRun.planb_ready(StringName(fam)) or fam == "pin_tumbler", "%s is a family of the game" % fam)
		if not tiers.is_empty():
			assert_has(tiers, fam, "%s is a lockcore family" % fam)
			assert_between(int(e["tier"]), int(tiers[fam][0]), int(tiers[fam][1]), "%s: a tier lockcore has" % fam)
		for k in [String(e["intro"]), String(e["trap"]), String(TutorialCoach.CAUTION_STRESS_KEY)]:
			if k == "":
				continue
			assert_has(rows, k, "%s: %s exists" % [fam, k])
			var row: PackedStringArray = rows.get(k, PackedStringArray())
			assert_eq(row.size(), LANGS.size() + 1, "%s in five languages" % k)
			for i in range(1, row.size()):
				assert_between(row[i].length(), 8, 56, "%s (%s) fits two chalk lines" % [k, LANGS[i - 1]])
		assert_ne(String(e["intro"]), "", "%s has an intro line" % fam)
	assert_eq(String(table["warded"]["trap"]), "", "warded has no false set")


func test_caution_starts_at_the_family_tier() -> void:
	assert_true(TutorialCoach.caution_for(&"pin_tumbler", 3).is_empty(), "pin_tumbler t3: no caution")
	assert_false(TutorialCoach.caution_for(&"pin_tumbler", 4).is_empty(), "pin_tumbler t4")
	assert_false(TutorialCoach.caution_for(&"pin_tumbler", 6).is_empty(), "and every tier above")
	assert_true(TutorialCoach.caution_for(&"lever", 3).is_empty())
	assert_false(TutorialCoach.caution_for(&"lever", 4).is_empty())
	assert_true(TutorialCoach.caution_for(&"dimple", 1).is_empty())
	assert_false(TutorialCoach.caution_for(&"dimple", 2).is_empty())
	assert_true(TutorialCoach.caution_for(&"wafer", 3).is_empty(), "wafer: no false gate, no caution")
	assert_true(TutorialCoach.caution_for(&"dial_safe", 3).is_empty(), "no loaded tool, no caution")


# ------------------------------------------------------------------ pure logic
func test_intro_trap_and_strain_lines() -> void:
	var c := _coach(&"pin_tumbler", 4)
	assert_true(c.has_caution())
	_feed(c, _vm(["free", "bound", "free"]), [], 0.5)
	assert_eq(c.text_key(), &"lock.caution_intro", "the intro shows from the start")
	_feed(c, _vm(["free", "bound", "free"]), [], 6.0)
	assert_eq(c.text_key(), &"lock.caution_intro", "and stays until something sets (an event, not a timer)")
	# a false set: the trap line, kept a moment after it clears
	_feed(c, _vm(["free", "false_set", "free"]), [{"kind": &"false_set"}], 0.5)
	assert_eq(c.text_key(), &"lock.caution_false_set")
	assert_false(c.strain, "no strain arrow for a false set")
	_feed(c, _vm(["free", "bound", "free"]), [], 1.0)
	assert_eq(c.text_key(), &"lock.caution_false_set", "kept long enough to read")
	_feed(c, _vm(["free", "bound", "free"]), [], TutorialCoach.CAUTION_KEEP_S)
	assert_eq(c.text_key(), &"lock.caution_intro", "then the intro again (nothing set yet)")
	# the first set ends the intro
	_feed(c, _vm(["set", "bound", "free"]), [{"kind": &"set"}], 0.5)
	assert_eq(c.text_key(), &"", "the intro ends on the first set")
	# the tool bends: line + strain flag; the line outlives the bend a little, the flag does not
	_feed(c, _vm(["set", "bound", "free"], 0.59), [], 0.5)
	assert_false(c.strain, "below lockcore's stress warning: nothing")
	assert_eq(c.text_key(), &"")
	_feed(c, _vm(["set", "false_set", "free"], 0.7), [{"kind": &"stress"}], 0.5)
	assert_true(c.strain)
	assert_eq(c.text_key(), &"lock.caution_stress", "the bending tool goes before the false set")
	_feed(c, _vm(["set", "bound", "free"], 0.3), [], 0.5)
	assert_false(c.strain, "eased off: the arrow goes at once")
	assert_eq(c.text_key(), &"lock.caution_stress")
	_feed(c, _vm(["set", "bound", "free"], 0.3), [], TutorialCoach.CAUTION_KEEP_S + 1.0)
	assert_eq(c.text_key(), &"")
	# open: nothing
	_feed(c, _vm(["set", "set", "set"], 0.9, true), [], 0.2)
	assert_false(c.strain)
	assert_eq(c.text_key(), &"")
	assert_eq(c.caution_history, [&"lock.caution_intro", &"lock.caution_false_set", &"lock.caution_intro",
		&"lock.caution_stress"] as Array[StringName], "the lines in order")


func test_intro_can_be_read_when_the_first_set_comes_at_once() -> void:
	var c := _coach(&"lever", 4)
	_feed(c, _vm(["set", "free", "free"]), [{"kind": &"set"}], 1.0)
	assert_eq(c.text_key(), &"lock.caution_intro", "a set in the first second does not wipe the line")
	_feed(c, _vm(["set", "free", "free"]), [], TutorialCoach.CAUTION_MIN_S)
	assert_eq(c.text_key(), &"")


func test_warded_has_its_own_intro_and_no_trap_line() -> void:
	var c := _coach(&"warded", 2)
	_feed(c, _vm(["bound", "free"]), [], 0.5)
	assert_eq(c.text_key(), &"lock.caution_warded")
	_feed(c, _vm(["false_set", "free"]), [{"kind": &"false_set"}], 0.5)
	assert_eq(c.text_key(), &"lock.caution_warded", "no false-set line for wards")
	_feed(c, _vm(["bound", "free"], 0.8), [], 0.2)
	assert_eq(c.text_key(), &"lock.caution_stress")


func test_a_guided_lesson_keeps_its_lines_and_gets_only_the_strain() -> void:
	var c := TutorialCoach.new(0, false, false)
	c.set_lesson(TutorialCoach.load_lesson(&"dimple"))
	c.set_caution(TutorialCoach.caution_for(&"dimple", 2))
	_feed(c, _vm(["free", "free", "free"]), [], 0.2)
	assert_eq(c.text_key(), &"tutorial.dimple.step1", "the lesson's own first line")
	assert_eq(c.caution_key(), &"")
	_feed(c, _vm(["free", "bound", "free"], 0.75), [], 0.2)
	assert_eq(c.text_key(), &"lock.caution_stress", "the bending tool interrupts the lesson line")
	assert_true(c.strain)
	_feed(c, _vm(["free", "bound", "free"], 0.1), [], TutorialCoach.CAUTION_KEEP_S + 0.5)
	assert_true(String(c.text_key()).begins_with("tutorial.dimple."), "and hands back")


func test_coach_without_caution_is_unchanged() -> void:
	var c := TutorialCoach.new(0, false, false)
	c.family = &"lever"
	_feed(c, _vm(["free", "bound", "free"], 0.9), [{"kind": &"bind"}], 0.5)
	assert_false(c.strain)
	assert_eq(c.text_key(), &"lock.lever_coach", "the first-jobs line, no caution")


# ------------------------------------------------------------------ through the real scene
func _first_risky(fam: StringName) -> Dictionary:
	for j: Dictionary in _jobs(fam):
		if not TutorialCoach.caution_for(fam, JobRun.tier_for(j)).is_empty():
			return j
	return {}


func test_first_risky_job_of_each_family_carries_the_caution() -> void:
	for fam: String in TutorialCoach.caution_table():
		var job := _first_risky(StringName(fam))
		if job.is_empty():
			gut.p("%s: no job at the risky tier yet (the continuous run reaches it)" % fam)
			continue
		Save.data.erase("lessons")
		var scene: Node = await _open(job)
		var coach: TutorialCoach = scene.coach
		var tag := "%s (%s)" % [fam, job["id"]]
		assert_not_null(coach, tag + ": a coach")
		if coach == null:
			continue
		assert_true(coach.has_caution(), tag + ": caution on")
		if coach.has_lesson():
			assert_false(coach.caution_only, tag + ": the lesson's coach carries it")
		else:
			assert_true(coach.caution_only, tag + ": a coach for the caution alone")
			assert_null(scene.hints, tag + ": no hint ladder for a family the player knows")
			assert_eq(scene.view.chalk_level, ChalkLayer.Level.OFF, tag + ": the chalk layer stays off")
			for i in 12:
				scene._physics_process(1.0 / HZ)
			scene.view.present(scene.session.describe(), {}, 1.0 / HZ)
			assert_eq(scene.view._chalk.text, I18n.t(StringName(coach.caution["intro"])), tag + ": the intro is written in chalk")
		# the tool bends: the line and the chalk arrow at the wrench (two thumbs)
		var vm: Dictionary = scene.session.describe().duplicate(true)
		vm["stress"] = 0.8
		coach.update(vm, {"tension": 0.6, "pick_lift": 0.2}, [], true, true, 1.0 / HZ)
		scene.view.present(vm, {"tension": 0.6, "pick_lift": 0.2}, 1.0 / HZ)
		assert_eq(scene.view._chalk.text, I18n.t(&"lock.caution_stress"), tag + ": the strain line")
		assert_true(bool(scene.view._chalk.marks.get("hint_down", false)) and scene.view._chalk.marks.has("wrench_tip"),
			tag + ": chalk arrow 'ease off' at the wrench")
		assert_gt(scene.view._face.tremor, 0.0, tag + ": the wrench itself bends and cracks (DESIGN §1 stress)")
		# opened: recorded, the next lock of the family has no caution
		scene._note_lesson_open()
		assert_true(TutorialCoach.caution_done(StringName(fam)), tag + ": the save records the caution")
		var again: Node = await _open(job)
		assert_true(again.coach == null or not again.coach.has_caution(), tag + ": only once")


func test_auto_tension_writes_the_line_without_the_wrench_arrow() -> void:
	var job := _first_risky(&"lever_detector")
	if job.is_empty():
		pending("no lever_detector job")
		return
	var scene: Node = await _open(job, true)
	var coach: TutorialCoach = scene.coach
	assert_true(coach != null and coach.has_caution())
	var vm: Dictionary = scene.session.describe().duplicate(true)
	vm["stress"] = 0.8
	coach.update(vm, {"tension": 0.35, "pick_lift": 0.2}, [], false, true, 1.0 / HZ)
	scene.view.present(vm, {"tension": 0.35, "pick_lift": 0.2}, 1.0 / HZ)
	assert_eq(scene.view._chalk.text, I18n.t(&"lock.caution_stress"))
	assert_false(bool(scene.view._chalk.marks.get("hint_down", false)), "the game holds the wrench: no arrow at it")


func test_lock_below_the_tier_and_practice_have_no_caution() -> void:
	var easy: Dictionary = {}
	for j: Dictionary in _jobs(&"pin_tumbler"):
		if JobRun.tier_for(j) < int(TutorialCoach.caution_table()["pin_tumbler"]["tier"]):
			easy = j
			break
	assert_false(easy.is_empty(), "a pin tumbler job below the tier")
	var scene: Node = await _open(easy)
	assert_null(scene.coach, "no coach, no caution below the tier")
	assert_false(TutorialCoach.caution_done(&"pin_tumbler"))
	var lp: GDScript = load("res://scripts/photoreal/lock_photoreal.gd")
	assert_true((lp.caution_for_lock(&"pin_tumbler", 5, {"lw-caution": "0"}) as Dictionary).is_empty(), "--lw-caution 0")
	assert_false((lp.caution_for_lock(&"pin_tumbler", 2, {"lw-caution": "1"}) as Dictionary).is_empty(), "--lw-caution 1")
	JobRun.current_job = {}
	assert_true((lp.caution_for_lock(&"pin_tumbler", 5, {}) as Dictionary).is_empty(), "no job, no caution (dev scenes)")
	JobRun.current_job = easy
	assert_false((lp.caution_for_lock(&"pin_tumbler", 5, {}) as Dictionary).is_empty(), "a job or the continuous run at the tier")
	TutorialCoach.mark_caution_done(&"pin_tumbler")
	assert_true((lp.caution_for_lock(&"pin_tumbler", 5, {}) as Dictionary).is_empty(), "done: not again")
