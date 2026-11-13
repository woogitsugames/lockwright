extends GutTest

func test_defaults_present() -> void:
	assert_true(Settings.get_value("haptics_enabled") == true)
	assert_eq(Settings.haptics_intensity(), 1.0)
	assert_true(Settings.get_value("haptics_enabled") in [true, false])

func test_set_and_clamp() -> void:
	Settings.set_value("haptics_intensity", 0.5)
	assert_eq(Settings.haptics_intensity(), 0.5)
	Settings.set_value("haptics_intensity", 1.0)
	assert_eq(Settings.haptics_intensity(), 1.0)

func test_unknown_key_rejected() -> void:
	Settings.set_value("no_such_key", 1)
	assert_false(Settings.get_value("no_such_key") == 1 and not Settings.DEFAULTS.has("no_such_key"))


# ------------------------------------------------------------------ D-121: the "Chalk markings" switch
## The lock screen asked Settings for "chalk_layer", a key Settings never had, so the switch of the
## Settings screen ("reading_aid") did nothing. Both now use one key; these tests keep it that way.

const HZ := 120


func _all_scripts(dir: String, out: Array = []) -> Array:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_all_scripts(dir.path_join(d), out)
	return out


func test_every_settings_key_the_game_reads_or_writes_exists() -> void:
	var re := RegEx.new()
	re.compile("Settings\\.(?:get_value|set_value)\\(\\s*&?\"([a-z0-9_]+)\"")
	var seen := 0
	for path: String in _all_scripts("res://scripts"):
		for m in re.search_all(FileAccess.get_file_as_string(path)):
			seen += 1
			assert_true(Settings.DEFAULTS.has(m.get_string(1)), "%s uses Settings key '%s', which Settings does not have" % [path.get_file(), m.get_string(1)])
	assert_gt(seen, 20, "the scan found the game's Settings calls")
	assert_false(Settings.DEFAULTS.has("chalk_layer"), "one key for the chalk switch: reading_aid")


func test_old_chalk_layer_key_is_read_once_from_an_old_file() -> void:
	var path := "user://settings_d121_test.cfg"
	var f := ConfigFile.new()
	f.set_value("settings", "chalk_layer", true)
	f.set_value("settings", "haptics_intensity", 0.5)
	f.save(path)
	Settings.load_settings(path)
	assert_true(Settings.get_value("reading_aid"), "chalk_layer = true becomes reading_aid")
	assert_eq(Settings.haptics_intensity(), 0.5, "the rest of the file loads as before")
	f.set_value("settings", "reading_aid", false)
	f.save(path)
	Settings.load_settings(path)
	assert_false(Settings.get_value("reading_aid"), "the current key wins once it is in the file")
	f = ConfigFile.new()
	f.set_value("settings", "chalk_layer", "yes")
	f.save(path)
	Settings.load_settings(path)
	assert_false(Settings.get_value("reading_aid"), "a value of the wrong type is ignored")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Settings.load_settings()  # back to the real file


func _lock_for(job: Dictionary) -> Node:
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


func test_chalk_switch_of_the_settings_screen_reaches_the_lock() -> void:
	var save_backup: Dictionary = Save.data.duplicate(true)
	var aid_backup: bool = Settings.get_value("reading_aid")
	Save.data.erase("lessons")
	Save.set_value("jobs_completed", ["a", "b", "c", "d", "e", "f", "g"])  # past the first jobs' own chalk
	Save.set_value("lessons/pin_tumbler/caution", true)
	Save.set_value("lessons/pin_tumbler_spool/done", true)
	# the switch itself, on the Settings screen
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	vp.disable_3d = true
	add_child_autofree(vp)
	var screen: Control = load("res://scenes/settings.tscn").instantiate()
	vp.add_child(screen)
	await wait_process_frames(3)
	var check: CheckButton = screen.reading_aid_check
	assert_eq(check.text, I18n.t(&"settings.reading_aid"), "the 'Chalk markings' switch")
	var job := JobRun.job_by_id("job.student_dorm")
	assert_eq(JobRun.family_for(job), &"pin_tumbler")
	var lock_script: GDScript = load("res://scripts/photoreal/lock_photoreal.gd")
	for on: bool in [true, false]:
		check.button_pressed = on  # as a tap: emits toggled
		assert_eq(bool(Settings.get_value("reading_aid")), on, "the switch writes reading_aid")
		assert_eq(bool(lock_script.chalk_layer_on()), on, "the lock screen reads the same key")
		var scene: Node = await _lock_for(job)
		var want := ChalkLayer.Level.REDUCED if on else ChalkLayer.Level.OFF
		assert_eq(scene.view.chalk_level, want, "pin tumbler job, switch %s" % on)
		scene._physics_process(1.0 / HZ)
		scene.view.present(scene.session.describe(), {}, 1.0 / HZ)
		assert_eq(scene.view._chalk.marks.has("shear"), on, "chalk marks on the lock only with the switch on (%s)" % on)
		# families with their own view (wafer) and with a lesson behind them (dimple: no pin coach)
		for fam: StringName in [&"wafer", &"dimple"]:
			var fjob: Dictionary = {}
			for j: Dictionary in JobRun.all_jobs():
				if JobRun.family_for(j) == fam and JobRun.is_playable(j):
					fjob = j
					break
			if fjob.is_empty():
				continue
			Save.set_value("lessons/%s/done" % fam, true)
			Save.set_value("lessons/%s/after" % fam, TutorialCoach.FADE_JOBS)
			Save.set_value("lessons/%s/caution" % fam, true)
			var fscene: Node = await _lock_for(fjob)
			assert_eq(fscene.view.chalk_level, want, "%s job, switch %s" % [fam, on])
	# practice: marks follow the switch, the goal line does not need it
	var entry: Dictionary = Practice.entry("t10")
	if not entry.is_empty():
		for on: bool in [true, false]:
			Settings.set_value("reading_aid", on)
			Practice.start(entry)
			var vp2 := SubViewport.new()
			vp2.size = Vector2i(412, 915)
			add_child_autofree(vp2)
			var pscene: Node = load(JobRun.lock_scene_path()).instantiate()
			vp2.add_child(pscene)
			await wait_physics_frames(3)
			assert_eq(pscene.view.chalk_level, ChalkLayer.Level.REDUCED if on else ChalkLayer.Level.OFF, "practice lock, switch %s" % on)
			assert_ne(pscene.view.goal_line, "", "the practice goal is written either way")
			Practice.finish(false, true)
	# D-120: the tool caution is written with the switch off (the coach's line, not the chalk layer)
	Settings.set_value("reading_aid", false)
	Save.data.erase("lessons")
	Save.set_value("lessons/pin_tumbler_spool/done", true)
	var cscene: Node = await _lock_for({"id": "job.d121_caution", "family": "pin_tumbler", "tier": 4, "reward_coins": 0, "i18n": {}})
	assert_eq(cscene.view.chalk_level, ChalkLayer.Level.OFF, "the chalk layer stays off")
	assert_true(cscene.coach != null and cscene.coach.has_caution(), "the caution is on all the same")
	for i in 12:
		cscene._physics_process(1.0 / HZ)
	cscene.view.present(cscene.session.describe(), {}, 1.0 / HZ)
	assert_eq(cscene.view._chalk.text, I18n.t(&"lock.caution_intro"), "and written in chalk")
	Settings.set_value("reading_aid", aid_backup)
	Save.data = save_backup
	Save.save()
	await wait_process_frames(2)  # Practice.finish clears the job context at idle time
	JobRun.current_job = {}
	JobRun.mode = &"job"
