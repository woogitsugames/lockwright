extends GutTest
## D-136: the save and the settings survive a full disk, a cut-off write, a damaged or old file and a
## missing folder. Every test works on a private Save / Settings node in its own user:// folder; the
## game's own save is never touched.

const SaveScript := preload("res://scripts/autoload/save.gd")
const SettingsScript := preload("res://scripts/autoload/settings.gd")

var _dir := ""


func before_each() -> void:
	_dir = "user://test_d136/t%d_%d" % [Time.get_ticks_usec(), randi() % 100000]
	DirAccess.make_dir_recursive_absolute(_dir)
	SafeFile.fail_mode = ""


func after_each() -> void:
	SafeFile.fail_mode = ""
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _save(file := "save.json") -> Node:
	var s: Node = SaveScript.new()
	s.path = _dir.path_join(file)
	add_child_autofree(s)
	return s


func _write(file: String, text: String) -> void:
	var f := FileAccess.open(_dir.path_join(file), FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _read(file: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(_dir.path_join(file)))


func _text(file: String) -> String:
	return FileAccess.get_file_as_string(_dir.path_join(file))


# ---------------------------------------------------------------- atomic write + backup

func test_first_launch_is_new_and_writes_a_whole_file() -> void:
	var s := _save()
	assert_eq(s.loaded_from, "new")
	s.set_value("coins", 5)
	assert_eq(int(_read("save.json")["coins"]), 5)
	assert_false(FileAccess.file_exists(s.path + ".tmp"), "no temp file left after a good write")
	assert_false(s.dirty)


func test_the_previous_save_stays_as_backup() -> void:
	var s := _save()
	s.set_value("coins", 5)
	s.set_value("coins", 6)
	assert_eq(int(_read("save.json")["coins"]), 6)
	assert_eq(int(_read("save.json.bak")["coins"]), 5, "the file from before the last write")


func test_a_write_that_changes_nothing_does_not_touch_the_disk() -> void:
	var s := _save()
	s.set_value("coins", 5)
	var n := SafeFile.writes
	watch_signals(s)
	s.set_value("coins", 5)
	assert_eq(SafeFile.writes, n, "same content: no write, no backup rotation")
	assert_signal_emitted(s, "changed", "listeners still hear about it")
	DirAccess.remove_absolute(s.path)
	s.save()
	assert_true(FileAccess.file_exists(s.path), "a file removed behind the game's back is written again")


func test_missing_folder_is_created_on_write() -> void:
	var s: Node = SaveScript.new()
	s.path = _dir.path_join("gone/deeper/save.json")
	add_child_autofree(s)
	assert_true(s.save())
	assert_true(FileAccess.file_exists(s.path))
	for p: String in [s.path, s.path + ".bak"]:
		DirAccess.remove_absolute(p)
	DirAccess.remove_absolute(_dir.path_join("gone/deeper"))
	DirAccess.remove_absolute(_dir.path_join("gone"))


func test_changes_that_belong_together_are_written_once() -> void:
	var s := _save()
	s.set_value("coins", 1)
	var n := SafeFile.writes
	s.hold()
	s.set_value("coins", 2)
	s.set_value("jobs_completed", ["job.a"])
	s.hold()  # nested
	s.set_value("stats/locks_opened", 1)
	s.release()
	assert_eq(SafeFile.writes, n, "nothing written while held")
	assert_eq(int(_read("save.json")["coins"]), 1)
	assert_eq(int(s.get_value("coins", 0)), 2, "memory is current")
	s.release()
	assert_eq(SafeFile.writes, n + 1, "one write for the whole group")
	var on_disk: Dictionary = _read("save.json")
	assert_eq(int(on_disk["coins"]), 2)
	assert_eq(on_disk["jobs_completed"], ["job.a"])
	assert_eq(int(on_disk["stats"]["locks_opened"]), 1)


func test_a_hold_never_outlives_its_frame_or_the_app_leaving() -> void:
	var s := _save()
	s.hold()
	s.set_value("coins", 5)   # release() never comes (an error in between)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(int(_read("save.json")["coins"]), 5, "written at the end of the frame")
	s.set_value("coins", 6)
	assert_eq(int(_read("save.json")["coins"]), 6, "and later writes are immediate again")
	s.hold()
	s.set_value("coins", 7)
	s.notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(int(_read("save.json")["coins"]), 7, "the app going to the background writes what was collected")


func test_settling_a_job_is_one_write() -> void:
	var backup: Dictionary = Save.data.duplicate(true)
	var job_backup := [JobRun.mode, JobRun.current_job, JobRun.clean]
	JobRun.start({"id": "job.d136_probe", "family": "pin_tumbler", "tier": 1, "reward_coins": 40, "i18n": {}})
	var n := SafeFile.writes
	var coins := int(Save.get_value("coins", 0))
	JobRun.complete()
	assert_eq(SafeFile.writes, n + 1, "job, coins, statistics, day-after: one file write (was four or five)")
	assert_eq(int(Save.get_value("coins", 0)), coins + 40 + 10, "fee and the clean-opening tip")
	assert_true((Save.get_value("jobs_completed", []) as Array).has("job.d136_probe"))
	assert_true((JSON.parse_string(FileAccess.get_file_as_string(Save.path))["jobs_completed"] as Array).has("job.d136_probe"), "and it is on disk")
	Save.data = backup
	Save.save()
	JobRun.mode = job_backup[0]
	JobRun.current_job = job_backup[1]
	JobRun.clean = job_backup[2]


# ---------------------------------------------------------------- full disk (D-123)

func test_full_disk_keeps_the_files_and_the_progress_in_memory() -> void:
	for mode: String in ["open", "short", "rename"]:
		var s := _save("save_%s.json" % mode)
		s.set_value("coins", 10)
		s.set_value("coins", 20)
		var file := "save_%s.json" % mode
		var before := _text(file)
		var before_bak := _text(file + ".bak")
		SafeFile.fail_mode = mode
		watch_signals(s)
		s.set_value("coins", 30)
		s.set_value("jobs_completed", ["job.a"])
		assert_true(s.dirty, "%s: the save knows the disk is behind" % mode)
		assert_ne(s.last_error, OK)
		assert_eq(s.get_value("coins", 0), 30, "%s: the game goes on from memory" % mode)
		assert_eq(_text(file), before, "%s: save.json untouched (not emptied, not cut)" % mode)
		assert_eq(_text(file + ".bak"), before_bak, "%s: the backup untouched" % mode)
		assert_false(FileAccess.file_exists(s.path + ".tmp"), "%s: no half-written temp file left" % mode)
		assert_signal_emitted(s, "changed", "%s: screens still refresh" % mode)
		# room again: the next change, or the app going to the background, writes everything
		SafeFile.fail_mode = ""
		assert_true(s.flush())
		assert_false(s.dirty)
		assert_eq(s.last_error, OK)
		var on_disk: Dictionary = _read(file)
		assert_eq(int(on_disk["coins"]), 30)
		assert_eq(on_disk["jobs_completed"], ["job.a"])


func test_going_to_the_background_retries_a_failed_write() -> void:
	for what: int in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		var s := _save("save_%d.json" % what)
		s.set_value("coins", 1)
		SafeFile.fail_mode = "short"
		s.set_value("coins", 2)
		assert_true(s.dirty)
		SafeFile.fail_mode = ""
		s.notification(what)
		assert_false(s.dirty, "notification %d flushes" % what)
		assert_eq(int(_read("save_%d.json" % what)["coins"]), 2)


func test_background_with_nothing_to_write_does_not_write() -> void:
	var s := _save()
	s.set_value("coins", 1)
	var n := SafeFile.writes
	s.notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_eq(SafeFile.writes, n)


# ---------------------------------------------------------------- damaged / old files

func test_cut_save_falls_back_to_the_backup_and_is_kept_aside() -> void:
	var s := _save()
	s.set_value("coins", 100)
	s.set_value("jobs_completed", ["job.a", "job.b"])
	s.set_value("coins", 150)
	var whole := _text("save.json")
	_write("save.json", whole.substr(0, whole.length() / 2))  # the write was cut half way
	s.load_save()
	assert_eq(s.loaded_from, "backup")
	assert_eq(int(s.get_value("coins", 0)), 100, "the state from before the last write, not a fresh career")
	assert_eq(s.get_value("jobs_completed", []), ["job.a", "job.b"])
	assert_true(FileAccess.file_exists(_dir.path_join("save.corrupt.json")), "the damaged file is kept for support")
	s.set_value("coins", 160)
	assert_eq(int(_read("save.json")["coins"]), 160, "the next write puts a whole save.json back")
	assert_eq(int(_read("save.json.bak")["coins"]), 100, "and the backup that saved the day is still there")


func test_empty_and_garbage_files_are_not_a_crash() -> void:
	for body: String in ["", "{", "[1, 2, 3]", "null", "\u0001\u0002", "{\"coins\": 5,,}"]:
		_write("save.json", body)
		DirAccess.remove_absolute(_dir.path_join("save.json.bak"))
		var s := _save()
		assert_eq(s.loaded_from, "defaults", "body '%s'" % body.c_escape())
		assert_eq(s.get_value("coins", -1), 0)
		assert_true(s.get_value("tools/pk_hook/owned", false), "defaults are complete")
		assert_true(FileAccess.file_exists(_dir.path_join("save.corrupt.json")))
		s.set_value("coins", 1)
		assert_eq(int(_read("save.json")["coins"]), 1, "and the game can save again")


func test_missing_save_with_a_backup_loads_the_backup() -> void:
	var s := _save()
	s.set_value("coins", 7)
	s.set_value("coins", 8)
	DirAccess.remove_absolute(s.path)  # a kill between "old file became .bak" and "new file renamed in"
	s.load_save()
	assert_eq(s.loaded_from, "backup")
	assert_eq(int(s.get_value("coins", 0)), 7)


func test_temp_file_of_a_cut_off_write_is_removed() -> void:
	var s := _save()
	s.set_value("coins", 7)
	_write("save.json.tmp", "{\"coins\": 9")
	s.load_save()
	assert_eq(s.loaded_from, "primary")
	assert_eq(int(s.get_value("coins", 0)), 7)
	assert_false(FileAccess.file_exists(s.path + ".tmp"))


func test_wrong_types_never_reach_the_game() -> void:
	_write("save.json", JSON.stringify({"schema": "save/1", "coins": "many", "tools": 7,
		"stats": {"locks_opened": "x", "locks_broken": 3}, "showcase_seen": {"a": 1},
		"jobs_completed": {"job.a": true}, "reputation": [1], "tutorial_done": "yes",
		"achievements_at": [], "tutorial": {"hint_history": 5}}))
	var s := _save()
	assert_eq(s.loaded_from, "primary")
	assert_eq(s.get_value("coins", 0), 0)
	assert_true(s.get_value("tools/tw_angle/owned", false), "tools: the default set, not the number 7")
	assert_eq(s.get_value("stats/locks_opened", 0), 0)
	assert_eq(int(s.get_value("stats/locks_broken", 0)), 3, "the readable part is kept")
	assert_eq(s.get_value("showcase_seen", []), [])
	assert_eq(s.get_value("jobs_completed", []), [], "an object where a list is expected: the caller's default")
	assert_eq(s.get_value("reputation", 0), 0)
	assert_eq(s.get_value("tutorial_done", false), false)
	assert_eq(s.get_value("achievements_at", {}), {})
	assert_eq(s.get_value("tutorial/hint_history", []), [])
	s.set_value("stats/locks_opened", 1)
	assert_eq(int(s.get_value("stats/locks_opened", 0)), 1)


func test_numbers_read_back_from_json_are_still_numbers() -> void:
	var s := _save()
	s.set_value("coins", 105)
	s.set_value("reputation", -3)
	s.load_save()  # JSON gives 105.0
	assert_eq(int(s.get_value("coins", 0)), 105)
	assert_eq(int(s.get_value("reputation", 0)), -3)
	assert_eq(s.get_value("missing", "fallback"), "fallback")
	assert_null(s.get_value("missing"))


func test_old_save_without_new_keys_gets_the_defaults() -> void:
	_write("save.json", JSON.stringify({"schema": "save/1", "coins": 12, "tools": {"pk_hook": {"owned": true, "integrity": 40}}}))
	var s := _save()
	assert_eq(int(s.get_value("coins", 0)), 12)
	assert_eq(int(s.get_value("tools/pk_hook/integrity", 0)), 40)
	assert_true(s.get_value("tools/tw_angle/owned", false), "a tool added after that save was written")
	assert_eq(int(s.get_value("stats/runs_finished", -1)), 0)


func test_save_of_a_newer_build_is_set_aside_not_destroyed() -> void:
	var newer := JSON.stringify({"schema": "save/9", "coins": 999})
	_write("save.json", newer)
	var s := _save()
	assert_eq(s.get_value("coins", -1), 0, "not understood: a fresh career")
	assert_eq(_text("save.corrupt.json"), newer, "but the newer save is still on the phone")


# ---------------------------------------------------------------- settings

func _settings() -> Node:
	var s: Node = SettingsScript.new()
	s.file_path = _dir.path_join("settings.cfg")
	add_child_autofree(s)
	return s


func test_settings_full_disk_keeps_the_file() -> void:
	var s := _settings()
	s.set_value("volume_music", 0.5)
	var before := _text("settings.cfg")
	SafeFile.fail_mode = "short"
	s.set_value("volume_music", 0.25)
	assert_true(s.dirty)
	assert_eq(_text("settings.cfg"), before, "not emptied by the failed write")
	assert_eq(s.get_value("volume_music"), 0.25, "the choice holds for this session")
	SafeFile.fail_mode = ""
	s.notification(NOTIFICATION_APPLICATION_PAUSED)
	assert_false(s.dirty)
	s.load_settings()
	assert_eq(s.get_value("volume_music"), 0.25)


func test_settings_damaged_file_uses_the_backup_then_defaults() -> void:
	var s := _settings()
	s.set_value("reduce_motion", true)
	s.set_value("volume_music", 0.5)   # settings.cfg.bak now holds reduce_motion without the volume
	_write("settings.cfg", "")
	s.load_settings()
	assert_true(s.get_value("reduce_motion"), "an emptied settings file: the copy from before the last write")
	_write("settings.cfg", "[settings\nvolume_music=\"")
	s.load_settings()
	assert_true(s.get_value("reduce_motion"), "an unreadable settings file: the same")
	DirAccess.remove_absolute(_dir.path_join("settings.cfg.bak"))
	s.load_settings()
	assert_eq(s.get_value("reduce_motion"), false, "nothing readable: defaults, no crash")
	assert_eq(s.get_value("volume_music"), 0.8)
	assert_engine_error_count(2, "the engine names the unreadable file in the log (twice read), nothing else")


func test_settings_values_of_the_wrong_type_are_ignored() -> void:
	_write("settings.cfg", "[settings]\n\nvolume_music=\"loud\"\nreduce_motion=3\nlanguage=7\ntext_scale=\"big\"\nhaptics_intensity=1\nvolume_sfx=0.5\n")
	var s := _settings()
	assert_eq(s.get_value("volume_music"), 0.8)
	assert_eq(s.get_value("reduce_motion"), false)
	assert_eq(s.get_value("language"), "")
	assert_eq(s.get_value("text_scale"), 1.0)
	assert_eq(float(s.get_value("haptics_intensity")), 1.0, "a whole number where a fraction is expected is fine")
	assert_eq(s.get_value("volume_sfx"), 0.5)


# ---------------------------------------------------------------- the rule itself

## Files in user:// that hold state are written through SafeFile. FileAccess.WRITE is left only
## where a cut file is harmless: the session log, and a download's .part / sidecar (checked by
## SHA-256 before use).
func test_no_script_rewrites_a_state_file_in_place() -> void:
	var allowed := {
		"res://scripts/util/safe_file.gd": true,
		"res://scripts/autoload/error_log.gd": true,
		"res://scripts/autoload/pack_store.gd": true,
	}
	var offenders: PackedStringArray = []
	var stack: Array[String] = ["res://scripts"]
	while not stack.is_empty():
		var d: String = stack.pop_back()
		for sub in DirAccess.get_directories_at(d):
			stack.append(d.path_join(sub))
		for f in DirAccess.get_files_at(d):
			var p := d.path_join(f)
			if not f.ends_with(".gd") or allowed.has(p) or p.begins_with("res://scripts/dev") or f == "capture_all_shots.gd":
				continue
			var src := FileAccess.get_file_as_string(p)
			if src.contains("FileAccess.WRITE") or src.contains("ConfigFile.new().save(") or src.contains(".save(PATH)"):
				offenders.append(p)
	assert_eq(offenders, PackedStringArray(), "write user:// state through SafeFile.write_text()")
	var store := FileAccess.get_file_as_string("res://scripts/autoload/pack_store.gd")
	assert_true(store.contains("SafeFile.write_text(dir.path_join(file)"), "installed.json / removed.json are replaced atomically")
