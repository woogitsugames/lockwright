extends GutTest
## T43 (chapters 9-12, D-66): data integrity, list order, the "talk" outcome (settled without a lock)
## and the clock-repair job ending through Events.lock_opened with family time_lock (achievement).

const T43_IDS_PREFIX := ["job.t43_", "job.refuse_t43_"]


func _t43_jobs() -> Array:
	var out := []
	for f in DirAccess.get_files_at("res://data/jobs"):
		if not f.ends_with(".json"):
			continue
		var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + f))
		for p in T43_IDS_PREFIX:
			if String(j.get("id", "")).begins_with(p):
				out.append(j)
	return out


func test_thirty_jobs_in_chapters_9_to_12_all_playable() -> void:
	var jobs := _t43_jobs()
	assert_eq(jobs.size(), 30)
	var per_chapter := {}
	for j in jobs:
		var ch := int(j.get("chapter", 0))
		assert_between(ch, 9, 12, "%s chapter" % j["id"])
		per_chapter[ch] = int(per_chapter.get(ch, 0)) + 1
		assert_true(JobRun.is_playable(j), "%s (%s) is hidden" % [j["id"], j.get("family")])
		assert_has(["open", "talk", "repair"], String(j.get("outcome", "open")), j["id"])
		assert_eq((j.get("lines", []) as Array).size(), 4, j["id"])
		for sp in j.get("lines", []) + j.get("after", []):
			assert_true(I18n.has_key(StringName("cast.%s.name" % sp)), "cast.%s.name missing" % sp)
		for n in 4:
			assert_true(I18n.has_key(StringName("%s.line.%d" % [j["id"], n + 1])), "%s.line.%d" % [j["id"], n + 1])
	assert_eq(per_chapter, {9: 8, 10: 7, 11: 7, 12: 8})


func test_list_orders_chapters_as_numbers_then_order() -> void:
	var a := {"id": "job.t43_10_01_x", "chapter": 10, "order": 1}
	var b := {"id": "job.t43_09_08_x", "chapter": 9, "order": 8}
	var r := {"id": "job.refuse_t43_09_x", "chapter": 9, "order": 7}
	var list_script: GDScript = load("res://scripts/ui/jobs_list.gd")
	var arr := [a, b, r]
	arr.sort_custom(list_script.job_before)
	assert_eq(arr.map(func(j): return j["id"]), ["job.refuse_t43_09_x", "job.t43_09_08_x", "job.t43_10_01_x"])


func test_talk_job_pays_visit_fee_without_tip_or_lock() -> void:
	var talk: Dictionary = JobRun.job_by_id("job.t43_09_08_spare_key_hook")
	assert_true(JobRun.is_talk(talk))
	Save.set_value("coins", 0)
	var opened: int = Save.get_value("stats/locks_opened", 0)
	JobRun.start(talk)
	JobRun.complete()
	assert_eq(int(Save.get_value("coins", 0)), int(talk["reward_coins"]), "visit fee, no tip")
	assert_eq(int(Save.get_value("stats/locks_opened", 0)), opened, "no lock opened")
	assert_true((Save.get_value("jobs_completed", []) as Array).has(talk["id"]))


func test_clock_repair_job_unlocks_clock_achievement() -> void:
	var job: Dictionary = JobRun.job_by_id("job.t43_10_03_exhibit_clock")
	assert_eq(String(job.get("outcome")), "repair")
	assert_eq(JobRun.family_for(job), &"time_lock")
	var ach := get_tree().root.get_node("Achievements")
	var arr: Array = Save.get_value("achievements", [])
	arr.erase("achievement.clock_repaired")
	Save.set_value("achievements", arr)
	Events.change_scenes = false
	JobRun.start(job)
	Events.lock_opened.emit()
	Events.change_scenes = true
	assert_true(ach.is_unlocked("achievement.clock_repaired"), "clock repair ends via lock_opened with family time_lock")
	JobRun.current_job = {}


func test_every_career_chapter_has_a_header_with_name_and_description() -> void:
	# D-75 (T58): the job list shows "Chapter N · name" and a description above each chapter.
	var chapters := {}
	for f in DirAccess.get_files_at("res://data/jobs"):
		if f.ends_with(".json"):
			var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + f))
			chapters[int(j.get("chapter", 0))] = true
	var list_script: GDScript = load("res://scripts/ui/jobs_list.gd")
	for ch: int in chapters:
		assert_true(I18n.has_key(StringName("chapter.%d.name" % ch)), "chapter.%d.name" % ch)
		assert_true(I18n.has_key(StringName("chapter.%d.desc" % ch)), "chapter.%d.desc" % ch)
		var header: VBoxContainer = list_script.chapter_header(ch)
		assert_eq(header.get_child_count(), 2, "name + description")
		assert_string_contains((header.get_child(0) as Label).text, I18n.t(StringName("chapter.%d.name" % ch)))
		header.free()
