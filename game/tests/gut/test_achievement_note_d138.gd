extends GutTest
## D-138 (owner, 2026-11-16): an earned achievement is said at once by one quiet chalk line at the
## top of the screen — never over a lock, several at once in one line, a tap on a hub screen opens
## its card on the shelf, nothing for backfilled ones.

const JOBS := "res://scenes/jobs_list.tscn"
const PAYMENT := "res://scenes/job_payment.tscn"

var _save_backup: Dictionary
var _note: AchievementNote
var _host: Node


class FakeScene extends Control:
	pass


func before_all() -> void:
	_save_backup = Save.data.duplicate(true)


func after_all() -> void:
	Save.data = _save_backup
	Nav.scene_override = null
	Nav.change_scenes = true
	Achievements.open_on_shelf = ""


func before_each() -> void:
	Save.data.erase("achievements")
	Save.data.erase("achievements_at")
	Nav.change_scenes = false
	Nav.last_target = ""
	_note = AchievementNote.new()
	add_child_autofree(_note)
	_note._timer.stop()  # the test drives _tick() itself


func after_each() -> void:
	Nav.scene_override = null
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = null


func _on(path: String, lock := false) -> void:
	if _host != null and is_instance_valid(_host):
		_host.free()
	_host = FakeScene.new()
	_host.scene_file_path = path
	if lock:
		var s := Node.new()
		s.name = "InputSampler"
		_host.add_child(s)
	add_child(_host)
	Nav.scene_override = _host


func _first_ids(n: int) -> Array:
	var out := []
	for d: Dictionary in Achievements.defs:
		out.append(String(d["id"]))
		if out.size() == n:
			break
	return out


func test_one_line_with_the_name() -> void:
	_on(JOBS)
	var id: String = _first_ids(1)[0]
	_note.push(id)
	_note._tick()
	assert_true(_note.panel.visible, "said at once")
	var name := I18n.t(StringName("ach.%s.name" % id))
	assert_string_contains(_note._label.text, name)
	assert_eq(_note._label.text, I18n.t(&"ach.note.one").format({"name": name}))
	assert_gte(_note.panel.size.y, AchievementNote.MIN_H, "touch target >= 48 dp")
	assert_lt(_note.panel.position.y, 120.0, "at the top, not over the main plate at the bottom")


func test_never_over_a_lock_said_on_the_next_screen() -> void:
	_on("res://scenes/lock_job.tscn", true)
	_note.push(_first_ids(1)[0])
	_note._tick()
	assert_false(_note.panel.visible, "nothing over a lock")
	assert_eq(_note.queue.size(), 1, "it waits")
	_on(PAYMENT)
	_note._tick()
	assert_true(_note.panel.visible, "said on the receipt")
	assert_eq(_note.queue.size(), 0)


func test_several_are_one_line() -> void:
	_on(JOBS)
	var ids := _first_ids(3)
	for id: String in ids:
		_note.push(id)
	_note._tick()
	var name := I18n.t(StringName("ach.%s.name" % ids[0]))
	assert_eq(_note._label.text, I18n.t(&"ach.note.many").format({"name": name, "n": 2}))
	assert_eq(_note.shown_ids.size(), 3)


func test_goes_away_and_a_lock_takes_it_down() -> void:
	_on(JOBS)
	_note.push(_first_ids(1)[0])
	_note._tick()
	_note._hide_at = 0.001  # time is up
	_note._tick()
	await wait_seconds(AchievementNote.FADE_S + 0.1)
	assert_false(_note.panel.visible, "gone after NOTE_S")
	_note.push(_first_ids(2)[1])
	_note._tick()
	assert_true(_note.panel.visible)
	_on("res://scenes/lock_job.tscn", true)
	_note._tick()
	assert_false(_note.panel.visible, "a lock opening takes the line down at once")


func test_tap_on_a_hub_screen_opens_the_card() -> void:
	_on(JOBS)
	var id: String = _first_ids(1)[0]
	_note.push(id)
	_note._tick()
	assert_true(_note.tappable())
	assert_eq(_note.panel.mouse_filter, Control.MOUSE_FILTER_STOP)
	_note.panel.pressed.emit()
	assert_eq(Achievements.open_on_shelf, id)
	assert_eq(Nav.last_target, AchievementNote.SHOWCASE)
	assert_false(_note.panel.visible)
	Achievements.open_on_shelf = ""


func test_during_a_job_the_line_is_information_only() -> void:
	_on(PAYMENT)
	_note.push(_first_ids(1)[0])
	_note._tick()
	assert_false(_note.tappable(), "a bill is never left unsettled")
	assert_eq(_note.panel.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_note.panel.pressed.emit()
	assert_eq(Achievements.open_on_shelf, "")
	assert_eq(Nav.last_target, "")


func test_showcase_opens_the_card() -> void:
	var id: String = _first_ids(1)[0]
	Achievements.unlock(id, false)
	Achievements.open_on_shelf = id
	var sc: Node = load("res://scenes/showcase.tscn").instantiate()
	add_child_autofree(sc)
	await wait_process_frames(3)
	assert_eq(Achievements.open_on_shelf, "", "used once")
	assert_true(sc.card.visible, "the card of the achievement is open")


func test_unlock_feeds_the_note_and_backfill_does_not() -> void:
	var ids := _first_ids(2)
	var before: Node = Achievements.note
	var fake := AchievementNote.new()
	add_child_autofree(fake)
	fake._timer.stop()
	Achievements.note = fake
	Achievements.unlock(ids[0], false)  # backfill: earned before, no day — not said
	assert_eq(fake.queue.size(), 0)
	Achievements.unlock(ids[1])
	assert_eq(fake.queue, [ids[1]] as Array[String])
	Achievements.note = before


func test_five_languages() -> void:
	for lang: String in ["pl", "en", "de", "fr", "es"]:
		I18n.apply_language(lang)
		for k: StringName in [&"ach.note.one", &"ach.note.many"]:
			var t := I18n.t(k)
			assert_ne(t, String(k), "%s %s" % [lang, k])
			assert_string_contains(t, "{name}")
	I18n.apply_language(Settings.language())
