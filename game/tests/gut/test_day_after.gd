extends GutTest
## V04 day-after scenes: one scene per finished job with `after` (never twice), tap closes,
## a missing portrait falls back to the enamel initial plate, Save remembers what was shown.

const SCENE := "res://scenes/day_after.tscn"
const JOB_AFTER := "job.allotment_shed"  # after: ["zbyszek"], episodic portrait exists
const JOB_NO_PORTRAIT := "job.t43_12_08_henryks_bench"  # after: ["halina", "locksmith"], locksmith has no portrait
const JOB_REFUSED := "job.refuse_aunt_alive"  # refused jobs count as finished too

var _saved: Dictionary


func before_each() -> void:
	_saved = {
		"jobs_completed": Save.get_value("jobs_completed", []),
		"jobs_refused": Save.get_value("jobs_refused", []),
		"day_after_shown": Save.get_value("day_after_shown", []),
	}
	Save.set_value("jobs_completed", [])
	Save.set_value("jobs_refused", [])
	Save.set_value("day_after_shown", [])
	DayAfter.change_scenes = false


func after_each() -> void:
	Save.set_value("jobs_completed", _saved["jobs_completed"])
	Save.set_value("jobs_refused", _saved["jobs_refused"])
	Save.set_value("day_after_shown", _saved["day_after_shown"])
	DayAfter.change_scenes = true


func _open_scene() -> Control:
	var scene: Control = load(SCENE).instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	return scene


func _tap(scene: Control) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	scene._on_gui_input(ev)


func test_no_pending_job_when_nothing_finished() -> void:
	assert_true(DayAfter.pending_job().is_empty())


func test_pending_job_picks_finished_job_with_after() -> void:
	Save.set_value("jobs_completed", ["job.unknown_not_in_data", JOB_AFTER])
	assert_eq(DayAfter.pending_job().get("id", ""), JOB_AFTER,
		"unknown ids and jobs without after-lines are skipped")


func test_pending_job_includes_refused_jobs() -> void:
	Save.set_value("jobs_refused", [JOB_REFUSED])
	assert_eq(DayAfter.pending_job().get("id", ""), JOB_REFUSED)


func test_shown_job_is_never_pending_again() -> void:
	Save.set_value("jobs_completed", [JOB_AFTER])
	DayAfter.mark_shown(JOB_AFTER)
	assert_true(DayAfter.pending_job().is_empty(), "shown once per job")
	DayAfter.mark_shown(JOB_AFTER)
	assert_eq((Save.get_value("day_after_shown", []) as Array).size(), 1, "mark_shown is idempotent")


func test_save_remembers_shown_after_reload() -> void:
	DayAfter.mark_shown(JOB_AFTER)
	Save.load_save()  # re-read user://save.json from disk
	assert_true((Save.get_value("day_after_shown", []) as Array).has(JOB_AFTER))


func test_scene_shows_each_after_line_and_closes_on_tap() -> void:
	Save.set_value("jobs_completed", [JOB_REFUSED])  # two after-lines: lena, neighbour_lucyna
	var scene := await _open_scene()
	assert_false(scene.is_queued_for_deletion(), "a pending job keeps the scene alive")
	var body := scene.get_node("Frame/VBox/Scroll/Body") as VBoxContainer
	assert_eq(body.get_child_count(), 2, "one row per after line")
	var row := body.get_child(0) as HBoxContainer
	assert_eq(row.get_meta("speaker"), "lena")
	assert_eq(row.get_node("Card/Texts/Text").text, I18n.t(&"job.refuse_aunt_alive.after.1"))
	assert_eq(row.get_node("Card/Texts/Speaker").text, I18n.t(&"cast.lena.name"))
	_tap(scene)
	assert_true((Save.get_value("day_after_shown", []) as Array).has(JOB_REFUSED),
		"tap closes the scene and Save remembers it")
	assert_true(DayAfter.pending_job().is_empty(), "not shown again on the next jobs-list entry")


func test_scene_frees_itself_when_nothing_pending() -> void:
	var scene := await _open_scene()
	assert_true(scene.is_queued_for_deletion(), "no pending job -> no scene")


func test_missing_portrait_falls_back_to_initial_plate() -> void:
	Save.set_value("jobs_completed", [JOB_NO_PORTRAIT])
	var scene := await _open_scene()
	var body := scene.get_node("Frame/VBox/Scroll/Body") as VBoxContainer
	assert_eq(body.get_child_count(), 2)
	var with_portrait := body.get_child(0)  # halina: cast avatar
	assert_not_null(with_portrait.get_node_or_null("Avatar"))
	var without := body.get_child(1) as HBoxContainer  # locksmith: no portrait asset
	assert_eq(without.get_meta("speaker"), "locksmith")
	assert_null(without.get_node_or_null("Avatar"))
	assert_not_null(without.get_node_or_null("InitialPlate"), "enamel initial plate instead of a missing portrait")
	assert_eq(without.get_node("Card/Texts/Text").text, I18n.t(&"job.t43_12_08_henryks_bench.after.2"))
