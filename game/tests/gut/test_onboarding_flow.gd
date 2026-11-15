extends GutTest
## D-134 (docs/handoff/ONBOARDING-AUDIT-2026-11-15.md): the first minutes of a fresh install.
##  - boot: one first-run card (haptics question + "a game, not a course"), answered with one tap,
##    no timers before or after it;
##  - "Start shift" -> control choice -> straight into the first practice lock;
##  - the tutorial ends at the job list (not the main menu) and "Start shift" opens the job list
##    until the first jobs are done;
##  - a tutorial left half way resumes at its stage, the pause can skip it;
##  - the verification screen says that a card can be asked about, until the player has done it.

const BOOT := "res://scenes/boot.tscn"
const MAIN_MENU := "res://scenes/main_menu.tscn"
const CONTROL_CHOICE := "res://scenes/control_choice.tscn"
const TUTORIAL := "res://scenes/tutorial.tscn"
const JOBS_LIST := "res://scenes/jobs_list.tscn"
const RUN_LOOP := "res://scenes/run_loop.tscn"
const LOCK_JOB := "res://scenes/lock_job.tscn"
const LANGS := ["en", "pl", "de", "fr", "es"]
const NEW_KEYS := ["boot.calib_again", "tutorial.frame_click_one", "tutorial.done_title", "tutorial.done_body",
	"tutorial.to_jobs", "pause.skip_tutorial", "verify.hint_tap"]

const MenuScript := preload("res://scripts/ui/main_menu.gd")
const ChoiceScript := preload("res://scripts/ui/control_choice.gd")
const TutorialScript := preload("res://scripts/ui/tutorial.gd")
const VerifyScript := preload("res://scripts/ui/job_verify.gd")

var _save: Dictionary
var _cfg: Dictionary
var _lang := ""


func before_each() -> void:
	_save = Save.data.duplicate(true)
	_cfg = Settings._cfg.duplicate(true)
	_lang = I18n.current_language()
	Events.change_scenes = false
	Events.last_target = ""
	# a fresh install
	for k in ["seen_notice", "tutorial_done", "tutorial_stage", "tutorial_skipped", "jobs_completed", "verify"]:
		Save.data.erase(k)
	Settings._cfg["calibrated"] = false
	Settings._cfg["calibration"] = ""
	Settings._cfg["control_chosen"] = false
	Settings._cfg["auto_tension"] = true
	Settings._cfg["haptics_enabled"] = true
	Settings._cfg["haptics_intensity"] = 1.0
	JobRun.mode = &"job"
	JobRun.current_job = {}
	JobRun.tutorial_stage = 0


func after_each() -> void:
	Events.change_scenes = true
	Events.scene_override = null
	Save.data = _save.duplicate(true)
	Save.save()
	Settings._cfg = _cfg.duplicate(true)
	Settings.save_settings()
	I18n.apply_language(_lang)
	JobRun.mode = &"job"
	JobRun.current_job = {}
	JobRun.tutorial_stage = 0
	get_tree().paused = false


func _open(path: String, size := Vector2i(412, 915)) -> Node:
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	add_child_autofree(vp)
	var scene: Node = load(path).instantiate()
	if "change_scenes" in scene:
		scene.change_scenes = false
	vp.add_child(scene)
	for i in 4:
		await get_tree().process_frame
	return scene


func _buttons(n: Node, out: Array = []) -> Array:
	if n is BaseButton and (n as BaseButton).is_visible_in_tree():
		out.append(n)
	for c in n.get_children():
		_buttons(c, out)
	return out


# ------------------------------------------------------------------ texts
func test_new_texts_exist_in_five_languages() -> void:
	var rows := {}
	var f := FileAccess.open("res://i18n/strings.csv", FileAccess.READ)
	var head := f.get_csv_line()
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() == head.size():
			rows[r[0]] = r
	for key: String in NEW_KEYS:
		assert_true(rows.has(key), "strings.csv has %s" % key)
		if not rows.has(key):
			continue
		for lang: String in LANGS:
			var text: String = rows[key][head.find(lang)]
			assert_ne(text.strip_edges(), "", "%s has a %s text" % [key, lang])
	# chalk-sized lines stay short (the tutorial screen's captions share the lock's 56-character limit)
	for key: String in ["tutorial.frame_click_one", "tutorial.done_body", "tutorial.frame_lift", "tutorial.frame_lift_one"]:
		for lang: String in LANGS:
			assert_lte((rows[key][head.find(lang)] as String).length(), 56, "%s/%s" % [key, lang])


func test_card_captions_use_the_coach_words() -> void:
	# the stage screen's card and the coach's line in the lock said the same thing in different words
	# ("podnoszenie" / "unoszenie" / "unieś"); the card now uses the coach's sentence
	I18n.apply_language("pl")
	assert_eq(I18n.t(&"tutorial.frame_lift"), I18n.t(&"tutorial.s1_pick"))
	assert_eq(I18n.t(&"tutorial.frame_lift_one"), I18n.t(&"tutorial.s1_pick_one"))
	I18n.apply_language("en")
	assert_eq(I18n.t(&"tutorial.frame_lift"), I18n.t(&"tutorial.s1_pick"))
	assert_eq(I18n.t(&"tutorial.frame_lift_one"), I18n.t(&"tutorial.s1_pick_one"))


func test_one_pin_stage_never_says_find_the_next() -> void:
	assert_eq(TutorialScript.stage_pins(0), 1, "S1 has one pin")
	for auto: bool in [true, false]:
		var keys: Array = TutorialScript.frames_for(0, auto).map(func(f: Array) -> StringName: return f[1])
		assert_has(keys, &"tutorial.frame_click_one", "auto=%s" % auto)
		assert_does_not_have(keys, &"tutorial.frame_click", "auto=%s: one pin has no next pin" % auto)
	var later: Array = TutorialScript.frames_for(1, true).map(func(f: Array) -> StringName: return f[1])
	assert_does_not_have(later, &"tutorial.frame_click_one")


# ------------------------------------------------------------------ boot
func test_first_run_card_asks_once_and_moves_on_at_the_tap() -> void:
	var boot: Node = await _open(BOOT)
	assert_true(Save.get_value("seen_notice", false), "the note counts as shown with the card")
	assert_true(boot.calib.visible, "first run: the card is up")
	assert_false(boot.notice.visible, "no separate timed note card")
	assert_eq(boot.calib_label.text, I18n.t(&"settings.haptics_calibration_two_clicks"), "the question of Settings -> Calibration")
	assert_eq(boot.calib_note.text, I18n.t(&"about.notice"), "the note is on the same card")
	assert_true(boot.calib_note.is_visible_in_tree())
	assert_false(boot.calib_continue.visible)
	for b: Button in [boot.calib_two, boot.calib_one, boot.calib_none, boot.calib_again]:
		assert_true(b.is_visible_in_tree(), "%s shown" % b.name)
		assert_gte(b.size.y, 48.0, "%s: 48 dp target" % b.name)
		assert_gte(b.size.x, 48.0)
	assert_string_contains(boot.calib_two.text, "●●", "dots carry the answer without reading")
	assert_string_contains(boot.calib_two.text, I18n.t(&"boot.calib_two"))
	# nothing happens by itself: the card waits (it used to answer for the player after 6 s)
	await wait_seconds(1.0)
	assert_eq(boot.last_target, "", "still waiting for the player")
	assert_eq(boot.stimulus_count, 1, "the two clicks played once, after the question could be read")
	boot.calib_again.pressed.emit()
	assert_eq(boot.stimulus_count, 2, "Again repeats them")
	assert_true(boot.calib.visible)
	boot.calib_two.pressed.emit()
	await get_tree().process_frame
	assert_eq(boot.last_target, MAIN_MENU, "the menu follows the tap, no timer")
	assert_false(boot.calib.visible)
	assert_true(Settings.get_value("calibrated", false))
	assert_eq(Settings.get_value("calibration", ""), "two")
	assert_true(Settings.haptics_enabled())


func test_first_run_answers_set_the_haptics() -> void:
	var boot: Node = await _open(BOOT)
	boot.answer("one")
	assert_almost_eq(Settings.haptics_intensity(), 0.6, 0.001)
	assert_true(Settings.haptics_enabled())
	boot.answer("none")
	assert_true(Settings.haptics_enabled(), "one answer only: a second tap changes nothing")
	Save.data.erase("seen_notice")
	Settings._cfg["calibrated"] = false
	var again: Node = await _open(BOOT)
	again.answer("none")
	assert_false(Settings.haptics_enabled(), "none: sound and picture carry the game")
	assert_eq(Settings.get_value("calibration", ""), "none")


func test_first_run_card_fits_small_phones_and_large_text() -> void:
	for size: Vector2i in [Vector2i(360, 640), Vector2i(412, 915), Vector2i(915, 412)]:
		for lang: String in ["pl", "de"]:
			Save.data.erase("seen_notice")
			Settings._cfg["calibrated"] = false
			I18n.apply_language(lang)
			var boot: Node = await _open(BOOT, size)
			await get_tree().process_frame
			var r: Rect2 = boot.calib.get_global_rect()
			var tag := "%s %s" % [size, lang]
			assert_gte(r.position.x, 15.5, tag + ": 16 dp left")
			assert_lte(r.end.x, size.x - 15.5, tag + ": 16 dp right")
			assert_gte(r.position.y, 0.0, tag + ": top on screen")
			assert_lte(r.end.y, float(size.y), tag + ": bottom on screen")
			assert_almost_eq(r.get_center().y, size.y * 0.5, 2.0, tag + ": centred")
			assert_lte(r.size.x, 360.5, tag)
			boot.answer("two")


func test_later_starts_have_no_card() -> void:
	Save.data["seen_notice"] = true
	Settings._cfg["calibrated"] = true
	var boot: Node = await _open(BOOT)
	assert_false(boot.calib.visible)
	assert_false(boot.notice.visible)
	await wait_seconds(0.3)
	assert_eq(boot.last_target, MAIN_MENU)


func test_note_alone_when_the_haptics_are_already_set() -> void:
	# settings kept, save new (a reinstall with a restored settings file): the note with one plate
	Settings._cfg["calibrated"] = true
	Settings._cfg["calibration"] = "one"
	var boot: Node = await _open(BOOT)
	assert_true(boot.calib.visible)
	assert_false(boot.calib_label.visible, "no question")
	assert_false(boot.calib_two.is_visible_in_tree())
	assert_true(boot.calib_continue.visible)
	assert_eq(boot.calib_continue.text, I18n.t(&"common.continue"))
	await wait_seconds(0.9)
	assert_eq(boot.stimulus_count, 0, "no clicks without the question")
	boot.calib_continue.pressed.emit()
	await get_tree().process_frame
	assert_eq(boot.last_target, MAIN_MENU)
	assert_eq(Settings.get_value("calibration", ""), "one", "the earlier answer stays")


# ------------------------------------------------------------------ what "Start shift" opens
func test_start_shift_leads_through_the_onboarding_in_order() -> void:
	assert_eq(MenuScript.play_target(), CONTROL_CHOICE, "fresh: the control choice (D-52)")
	Settings._cfg["control_chosen"] = true
	assert_eq(MenuScript.play_target(), TUTORIAL, "tutorial left half way: its stage screen")
	Save.data["tutorial_done"] = true
	assert_eq(MenuScript.play_target(), JOBS_LIST, "after the tutorial: the first job, not the endless shift")
	Save.data["jobs_completed"] = ["a", "b"]
	assert_eq(MenuScript.play_target(), JOBS_LIST)
	Save.data["jobs_completed"] = ["a", "b", "c"]
	assert_eq(MenuScript.play_target(), RUN_LOOP, "N-64: then the shift")
	var menu: Node = load(MAIN_MENU).instantiate()
	menu.change_scenes = false
	add_child_autofree(menu)
	menu._on_play()
	assert_eq(menu.last_target, RUN_LOOP)
	Save.data["jobs_completed"] = []
	menu._on_play()
	assert_eq(menu.last_target, JOBS_LIST)


func test_control_choice_goes_straight_into_the_first_practice_lock() -> void:
	var cc: Node = await _open(CONTROL_CHOICE)
	cc.select(false)
	Settings.set_value("auto_tension", cc.auto_selected)
	Settings.set_value("control_chosen", true)
	assert_eq(ChoiceScript.next_scene(), LOCK_JOB, "no stage screen between the choice and the lock")
	assert_eq(JobRun.mode, &"tutorial")
	assert_eq(JobRun.tutorial_stage, 0)
	assert_eq(String(JobRun.current_job.get("lock_spec", "")), JobRun.TUTORIAL_SPECS[0], "the authored one-pin lock S1")
	assert_false(bool(Settings.get_value("auto_tension", true)), "the choice is saved")


func test_control_choice_respects_a_tutorial_left_half_way_and_a_finished_one() -> void:
	Settings._cfg["control_chosen"] = true
	Save.data["tutorial_stage"] = 1
	assert_eq(ChoiceScript.next_scene(), TUTORIAL, "stage 2 starts from its own screen (its one new sentence)")
	assert_eq(JobRun.tutorial_stage, 1)
	assert_true(JobRun.current_job.is_empty(), "no lock started")
	Save.data["tutorial_done"] = true
	Save.data["tutorial_stage"] = 3
	assert_eq(ChoiceScript.next_scene(), JOBS_LIST)
	Save.data["jobs_completed"] = ["a", "b", "c"]
	assert_eq(ChoiceScript.next_scene(), RUN_LOOP, "N-64")


# ------------------------------------------------------------------ tutorial: resume, end, skip
func test_tutorial_stage_survives_a_restart() -> void:
	JobRun.start_tutorial(0)
	JobRun.complete()
	assert_eq(int(Save.get_value("tutorial_stage", 0)), 1)
	JobRun.tutorial_stage = 0  # the app was closed: the static starts again
	JobRun.mode = &"job"
	var tut: Node = await _open(TUTORIAL)
	assert_eq(JobRun.tutorial_stage, 1, "the stage screen opens at the saved stage")
	assert_eq(tut.get_node("Margin/Scroll/VBox/Stage").text, I18n.t(&"tutorial.stage").format({"n": 2}))
	assert_eq(Array(tut.frame_captions()), [I18n.t(&"tutorial.s2_intro")])


func test_tutorial_end_screen_leads_to_the_first_job() -> void:
	for stage in 3:
		JobRun.start_tutorial(stage)
		JobRun.complete()
	assert_true(Save.get_value("tutorial_done", false))
	var tut: Node = await _open(TUTORIAL)
	var v := tut.get_node("Margin/Scroll/VBox")
	assert_eq(v.get_node("Title").text, I18n.t(&"tutorial.done_title"))
	assert_eq(v.get_node("Stage").text, I18n.t(&"tutorial.done_body"))
	assert_eq(v.get_node("StartButton").text, I18n.t(&"tutorial.to_jobs"), "the plate names where it leads")
	assert_eq(tut.frame_captions().size(), 0)
	v.get_node("StartButton").pressed.emit()
	assert_eq(Events.last_target, JOBS_LIST, "not the main menu")


func test_pause_of_a_practice_lock_can_skip_the_tutorial() -> void:
	if not ClassDB.class_exists("LockcoreSession"):
		pending("needs the lockcore GDExtension")
		return
	JobRun.start_tutorial(0)
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var scene: Node = load(JobRun.lock_scene_path()).instantiate()
	vp.add_child(scene)
	await wait_physics_frames(3)
	scene.set_physics_process(false)
	scene.sampler.set_physics_process(false)
	var skip := _all_buttons(scene.pause_cover).filter(func(b: BaseButton) -> bool: return b.text == I18n.t(&"pause.skip_tutorial"))
	assert_eq(skip.size(), 1, "the pause offers to skip the tutorial")
	scene._on_pause()
	assert_true(get_tree().paused)
	skip[0].pressed.emit()
	assert_false(get_tree().paused)
	assert_true(Save.get_value("tutorial_done", false))
	assert_true(Save.get_value("tutorial_skipped", false))
	assert_eq(Events.last_target, JOBS_LIST)
	assert_eq(MenuScript.play_target(), CONTROL_CHOICE if not Settings.get_value("control_chosen", false) else JOBS_LIST)
	assert_true(JobRun.current_job.is_empty())
	scene.queue_free()
	await get_tree().process_frame
	# a job's lock has no such plate
	JobRun.start(JobRun.job_by_id("job.student_dorm"))
	var job_scene: Node = load(JobRun.lock_scene_path()).instantiate()
	vp.add_child(job_scene)
	await wait_physics_frames(3)
	job_scene.set_physics_process(false)
	job_scene.sampler.set_physics_process(false)
	var none := _all_buttons(job_scene.pause_cover).filter(func(b: BaseButton) -> bool: return b.text == I18n.t(&"pause.skip_tutorial"))
	assert_eq(none.size(), 0)


func _all_buttons(n: Node, out: Array = []) -> Array:
	if n is BaseButton:
		out.append(n)
	for c in n.get_children():
		_all_buttons(c, out)
	return out


# ------------------------------------------------------------------ verification
func test_verify_says_how_to_ask_until_the_player_has_asked() -> void:
	assert_eq(VerifyScript.hint_key(), &"verify.hint_tap")
	JobRun.start(JobRun.job_by_id("job.bike_interview"))
	var verify: Node = await _open("res://scenes/job_verify.tscn")
	verify.go_override = func(_p: String) -> void: pass
	assert_eq(verify.hint_label.text, I18n.t(&"verify.hint_tap"))
	var cards: Array = verify._cards()
	verify._ask_about(String(cards[0]))
	assert_true(verify.result_panel.visible, "the exchange shows")
	assert_true(Save.get_value(VerifyScript.CARD_ASKED_KEY, false))
	assert_eq(VerifyScript.hint_key(), &"verify.hint", "learned once: the old line is back on the next job")
	var next: Node = await _open("res://scenes/job_verify.tscn")
	assert_eq(next.hint_label.text, I18n.t(&"verify.hint"))


# ------------------------------------------------------------------ voice download note
func test_voice_download_note_is_short_lived_on_top_and_never_over_a_lock() -> void:
	var vp: Node = load("res://scripts/autoload/voice_packs.gd").new()
	vp.auto_follow_language = false
	vp.auto_download = false
	add_child_autofree(vp)
	vp._show_note("Głosy: pobieranie", true)
	await get_tree().process_frame
	assert_eq(vp.note_text(), "Głosy: pobieranie")
	var screen_h: float = vp.get_viewport().get_visible_rect().size.y
	assert_lt(vp._note.position.y, screen_h * 0.25, "under the top edge: the bottom belongs to the screen's main plate")
	assert_eq(vp._note.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never takes a tap")
	await wait_seconds(vp.NOTE_HIDE_S + 0.3)
	assert_eq(vp.note_text(), "", "gone by itself")
	# on a lock nothing is laid over the picture
	var before := get_tree().current_scene
	var lock := Node.new()
	var sampler := Node.new()
	sampler.name = "InputSampler"
	lock.add_child(sampler)
	get_tree().root.add_child(lock)
	get_tree().current_scene = lock
	vp._show_note("Głosy: gotowe", true)
	assert_eq(vp.note_text(), "", "not over a lock")
	get_tree().current_scene = before
	lock.queue_free()
	# the "downloading" line is said once per download, not on every percent
	var src := FileAccess.get_file_as_string("res://scripts/autoload/voice_packs.gd")
	assert_string_contains(src, "_note_said.has(lang)")
