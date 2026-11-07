extends GutTest
## D-79: practice mode ("Ćwiczenia" tab of the Workshop). Data copies vs lockcore/practice, why the
## other practice locks are left out, goal keys in all five languages, unlock + goal save logic,
## routing back to the Workshop, every entry on its plan-B lock screen, and the tab's rows.

const LANGS := ["en", "pl", "de", "fr", "es"]
## Elements each plan-B screen draws (pin: PINS_X, wafer: WAFER_X, lever GLBs: lever0..2 / lever0..4,
## warded GLB: ward0..2). A practice lock with more elements would hide some of them.
const CAPACITY := {&"pin_tumbler": 5, &"wafer": 5, &"warded": 3, &"lever": 3, &"lever_detector": 5}
const UI_KEYS := ["workshop.tab_practice", "practice.note", "practice.start", "practice.locked", "practice.goal_met",
	"practice.goal_open", "practice.goal_done", "practice.result_met", "practice.result_open", "practice.result_failed"]

var _save_backup: Dictionary


func before_each() -> void:
	_save_backup = Save.data.duplicate(true)
	Save.data = Save.DEFAULTS.duplicate(true)
	Save.data["jobs_completed"] = []
	Events.change_scenes = false
	Events.last_target = ""
	Practice.current = {}
	Practice.last_result = &""
	JobRun.mode = &"job"
	JobRun.current_job = {}


func after_each() -> void:
	Practice.current = {}
	Practice.met_now = false
	Practice.last_result = &""
	JobRun.mode = &"job"
	JobRun.current_job = {}
	Events.change_scenes = true
	Events.scene_override = null
	Events._fail_scene = null
	Save.data = _save_backup
	Save.save()


func _source_dir() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../lockcore/practice").simplify_path()


func _csv_rows() -> Dictionary:
	var out := {}
	for path in ["res://i18n/strings.csv", "res://i18n/content.csv"]:
		var rows: Array = I18n._parse_csv(path)
		var header: PackedStringArray = rows[0]
		for r in rows.slice(1):
			if (r as PackedStringArray).size() < header.size():
				continue
			var d := {}
			for i in header.size():
				d[header[i]] = r[i]
			out[r[0]] = d
	return out


func test_entries_and_copies_match_lockcore() -> void:
	var entries := Practice.entries()
	assert_gt(entries.size(), 10, "practice locks shipped")
	var last := -1
	for e in entries:
		assert_gt(int(e["order"]), last, "path order (presentation.practice.order)")
		last = int(e["order"])
		assert_true(JobRun.planb_ready(e["family"]), "%s: family has a plan-B screen" % e["id"])
		assert_lte(int(e["elements"]), int(CAPACITY.get(e["family"], 0)), "%s: every element drawn" % e["id"])
	var src := _source_dir()
	if not DirAccess.dir_exists_absolute(src):
		pass_test("lockcore/practice not reachable (exported pack); copies checked in the repo run")
		return
	for e in entries:
		var mine: Variant = JSON.parse_string(FileAccess.get_file_as_string(e["path"]))
		var theirs: Variant = JSON.parse_string(FileAccess.get_file_as_string(src.path_join("%s.json" % e["id"])))
		assert_eq(mine, theirs, "%s is an unchanged copy of lockcore/practice" % e["id"])
	# every lockcore practice lock is either shipped or left out for a reason
	for f in DirAccess.get_files_at(src):
		if not f.ends_with(".json"):
			continue
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(src.path_join(f)))
		var id := f.get_basename()
		var fam := StringName(d["family"])
		var fits := JobRun.planb_ready(fam) and Practice.element_count(d) <= int(CAPACITY.get(fam, 0))
		assert_eq(not Practice.entry(id).is_empty(), fits, "%s (%s, %d elements): shipped iff its screen draws it" % [id, fam, Practice.element_count(d)])


func test_goal_and_ui_keys_in_all_languages() -> void:
	var rows := _csv_rows()
	var keys: Array = UI_KEYS.duplicate()
	for e in Practice.entries():
		keys.append(String(e["goal_key"]))
	for fam in Practice.families():
		keys.append("family.%s.name" % fam)
	for key in keys:
		assert_true(rows.has(key), "%s in the CSV" % key)
		if rows.has(key):
			for lang in LANGS:
				assert_ne(String(rows[key].get(lang, "")).strip_edges(), "", "%s has %s" % [key, lang])


func test_lesson_targets_are_recognised() -> void:
	var base := ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate", "overset", "drop", "stress",
		"break", "wear", "gate_align", "detector_trip", "open"]
	for e in Practice.entries():
		assert_true(base.has(e["target"]) or Practice.SUB_EVENTS.has(e["target"]), "%s: %s" % [e["id"], e["target"]])
	assert_true(Practice.matches("overset", {"kind": &"overset", "sub": 0}))
	assert_true(Practice.matches("false_set", {"kind": &"false_set", "sub": 1}), "base kind counts its sub-events")
	assert_true(Practice.matches("lever.false_gate", {"kind": &"false_set", "sub": 1}))
	assert_false(Practice.matches("lever.false_gate", {"kind": &"false_set", "sub": 0}))
	assert_true(Practice.matches("detector.reset", {"kind": &"drop", "sub": 2}))
	assert_false(Practice.matches("set", {"kind": &"bind", "sub": 0}))


func _first_of(fam: StringName) -> Dictionary:
	for e in Practice.entries():
		if e["family"] == fam:
			return e
	return {}


func _job_of(fam: StringName) -> String:
	for f in DirAccess.get_files_at("res://data/jobs"):
		var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + f))
		if JobRun.family_for(j) == fam:
			return j["id"]
	return ""


func test_unlock_after_family_met() -> void:
	var pin := _first_of(&"pin_tumbler")
	var wafer := _first_of(&"wafer")
	assert_false(Practice.unlocked(pin), "fresh save: nothing unlocked")
	assert_false(Practice.unlocked(wafer))
	Save.set_value("tutorial_done", true)
	assert_true(Practice.unlocked(pin), "the tutorial meets the pin tumbler")
	assert_false(Practice.unlocked(wafer), "the wafer still waits for its job")
	var jid := _job_of(&"wafer")
	assert_ne(jid, "", "a wafer job exists")
	Save.set_value("jobs_completed", [jid])
	assert_true(Practice.unlocked(wafer), "a completed wafer job unlocks the wafer practice")
	Save.data["jobs_completed"] = []
	Save.set_value("lessons/wafer/done", true)
	assert_true(Practice.unlocked(wafer), "a family lesson counts too")


func test_goal_saved_on_target_event() -> void:
	var e := Practice.entry("t07")  # wafer, lesson_target overset
	assert_eq(e["target"], "overset")
	Practice.start(e)
	assert_eq(JobRun.mode, &"practice")
	assert_eq(JobRun.current_job["lock_spec"], e["path"])
	assert_eq(int(JobRun.current_job["reward_coins"]), 0, "no coins")
	assert_false(Practice.note_events([{"kind": &"set", "sub": 0}]))
	assert_false(Practice.goal_met("t07"))
	assert_true(Practice.note_events([{"kind": &"overset", "sub": 0}]), "the target meets the goal")
	assert_false(Practice.note_events([{"kind": &"overset", "sub": 0}]), "once per attempt")
	assert_true(Practice.goal_met("t07"))
	Save.load_save()
	assert_true(Practice.goal_met("t07"), "goal survives a reload")
	Practice.finish(false)
	assert_eq(Practice.last_result, &"met", "met wins over a later break")
	assert_eq(JobRun.mode, &"job")
	assert_false(Practice.active())
	await get_tree().process_frame
	assert_true(JobRun.current_job.is_empty(), "job context cleared at idle time")
	Practice.start(Practice.entry("t09"))
	Practice.finish(true)
	assert_eq(Practice.last_result, &"open")
	Practice.start(Practice.entry("t09"))
	Practice.finish(false, true)
	assert_eq(Practice.last_result, &"", "leaving through the pause says nothing")


func test_open_and_fail_go_back_to_workshop() -> void:
	var dummy := Node.new()
	add_child_autofree(dummy)
	Events.scene_override = dummy
	Save.set_value("coins", 5)
	Practice.start(Practice.entry("t09"))
	Events._on_lock_opened()
	assert_eq(Events.last_target, Events.WORKSHOP, "open -> Workshop, not the payment")
	assert_eq(Save.get_value("coins"), 5, "no coins")
	assert_eq(Practice.last_result, &"open")
	assert_false(Practice.active())
	Practice.start(Practice.entry("t09"))
	Events.last_target = ""
	Events._route_failed(dummy)
	assert_eq(Events.last_target, Events.WORKSHOP, "fail -> Workshop")
	assert_eq(int(Save.get_value("stats/locks_broken", 0)), 0, "a practice break is not counted")
	assert_eq(Practice.last_result, &"failed")


func test_every_entry_opens_in_its_lock_screen() -> void:
	var real := ClassDB.class_exists("LockcoreSession")
	for e in Practice.entries():
		Practice.start(e)
		var path := JobRun.lock_scene_path()
		var want: String = "res://scenes/lock_job.tscn" if e["family"] == &"pin_tumbler" else JobRun.PLANB_SCENES[e["family"]]
		assert_eq(path, want, "%s: the family's plan-B screen" % e["id"])
		var vp := SubViewport.new()
		vp.size = Vector2i(412, 915)
		add_child_autofree(vp)
		var scene: Node = load(path).instantiate()
		vp.add_child(scene)
		for i in 3:
			await get_tree().process_frame
		assert_eq(scene.get("family"), e["family"], "%s: family" % e["id"])
		var view: Node = scene.get("view")
		assert_eq(String(view.get("goal_line")), I18n.t(e["goal_key"]), "%s: goal in chalk" % e["id"])
		assert_null(scene.get("coach"), "%s: no coach in practice" % e["id"])
		if real:
			var session: RefCounted = scene.get("session")
			assert_false(session is FakeLockSession, "%s: authored lock loaded by lockcore" % e["id"])
			var els: Array = session.describe().get("elements", [])
			assert_eq(els.size(), int(e["elements"]), "%s: lockcore sees every element" % e["id"])
			var drawn: Variant = view.get("_active_stacks") if e["family"] == &"pin_tumbler" else view.get("_n")
			if drawn != null:
				assert_eq(int(drawn), int(e["elements"]), "%s: the screen draws every element" % e["id"])
		Practice.finish(false, true)
		vp.queue_free()
		await get_tree().process_frame


func test_workshop_practice_tab() -> void:
	Save.set_value("tutorial_done", true)
	var goal_done := _first_of(&"pin_tumbler")
	Save.set_value("practice/%s/goal" % goal_done["id"], true)
	Practice.last_result = &"failed"  # as after a practice run
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.disable_3d = true
	add_child_autofree(vp)
	var ws: Control = load("res://scenes/workshop.tscn").instantiate()
	vp.add_child(ws)
	await get_tree().process_frame
	await get_tree().process_frame
	var tab: Button = ws.get_node("Frame/VBox/Tabs/TabPractice")
	assert_true(tab.button_pressed, "back from practice: the Ćwiczenia tab is open")
	assert_gte(tab.size.y, 48.0)
	var list: Control = ws.get_node("Frame/VBox/Scroll/ToolsList")
	var res: Label = list.get_node_or_null("PracticeResult")
	assert_not_null(res, "one line about the attempt")
	if res != null:
		assert_eq(res.text, I18n.t(&"practice.result_failed"))
	assert_eq(Practice.last_result, &"", "shown once")
	for fam in Practice.families():
		assert_not_null(list.get_node_or_null("Family_" + String(fam)), "heading for %s" % fam)
	var card: Control = list.get_node("Practice_" + String(goal_done["id"]))
	var play: Button = card.find_child("Action", true, false)
	assert_true(play.visible and not play.disabled, "pin practice unlocked")
	assert_gte(play.size.y, 48.0, "touch target")
	assert_eq((card.find_child("State", true, false) as Label).text, I18n.t(&"practice.goal_met"))
	assert_eq((card.find_child("Name", true, false) as Label).text, I18n.t(goal_done["goal_key"]), "the goal is the row's line")
	var locked: Control = list.get_node("Practice_" + String(_first_of(&"lever")["id"]))
	assert_false((locked.find_child("Action", true, false) as Button).visible, "no button before the family is met")
	assert_eq((locked.find_child("State", true, false) as Label).text, I18n.t(&"practice.locked"))
	assert_lte(ws.get_combined_minimum_size().x, 412.0, "no sideways scroll")
	# the plate starts the practice run (scene change is not followed in the test)
	ws.show_tab("tools")
	assert_false(tab.button_pressed)
