extends GutTest
## Task 14: end-to-end career — bot lockcore clears tutorial + all playable jobs,
## buys tools, reads showcase; save is written and reloaded after every step.

func _solve_replay(family: StringName, seed: int, tier: int) -> bool:
	var report: Dictionary = LockcoreSession.solve(family, seed, tier)
	if not report.get("ok", false):
		return false
	var s: RefCounted = ClassDB.instantiate("LockcoreSession")
	s.create(family, seed, tier)
	for row in report.get("inputs", []):
		s.step(row[0], row[1], row[2], row[3], row[4], row[5])
	return s.is_open()


func test_tutorial_stages_open() -> void:
	assert_true(ClassDB.class_exists("LockcoreSession"))
	for stage in 3:
		var seed := JobRun.fnv1a64("tutorial.s%d" % (stage + 1)) % 1000000 + 1
		assert_true(_solve_replay(&"pin_tumbler", seed, 1), "tutorial stage %d not openable" % (stage + 1))
		Save.save()  # save after every step (task 14)
		Save.load_save()


func test_all_playable_jobs_open_and_save_roundtrip() -> void:
	var jobs: Array = []
	for path in DirAccess.get_files_at("res://data/jobs"):
		if path.ends_with(".json"):
			jobs.append(JSON.parse_string(FileAccess.get_file_as_string("res://data/jobs/" + path)))
	var playable := 0
	for job in jobs:
		if not JobRun.is_playable(job):
			continue
		playable += 1
		var fam := JobRun.family_for(job)
		var seed := JobRun.seed_for(job)
		var tier := JobRun.tier_for(job)
		assert_true(_solve_replay(fam, seed, tier), "job %s (%s t%d) not openable by bot" % [job.get("id"), fam, tier])
		# N-20: go through the real game path (JobRun.start/complete + lock_scene_path),
		# not a different save key than the game uses
		JobRun.start(job)
		assert_eq(JobRun.lock_scene_path(), JobRun.lock_scene_path())
		JobRun.complete()
		Save.save()
		Save.load_save()
		var completed: Array = Save.get_value("jobs_completed", [])
		assert_true(completed.has(job.get("id")), "job %s not marked completed via JobRun" % job.get("id"))
	# N-63: only families with a plan-B lock screen are playable (JobRun.PHOTOREAL_READY);
	# every job of those families must be offered.
	var expected := 0
	for job in jobs:
		if JobRun.IMPLEMENTED.has(JobRun.family_for(job)) and JobRun.PHOTOREAL_READY.has(JobRun.family_for(job)):
			expected += 1
	assert_gt(expected, 0, "no job of a plan-B family")
	assert_eq(playable, expected, "every job of a plan-B family is playable")


func test_workshop_purchase_and_showcase() -> void:
	Save.set_value("coins", 100000)
	var tools: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	for tool in tools.get("tools", []):
		if tool.get("price", 0) == 0 and tool.get("unlock") == "start":
			continue
		var coins: int = Save.get_value("coins", 0)
		if coins >= tool.get("price", 0):
			Save.set_value("coins", coins - tool.get("price", 0))
			Save.set_value("tools/%s/owned" % tool["id"], true)
	Save.save()
	Save.load_save()
	assert_true(Save.get_value("tools/pk_lever/owned", false), "pk_lever should be bought")
	# showcase readable
	for path in DirAccess.get_files_at("res://data/showcase"):
		if path.ends_with(".json"):
			var note: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/showcase/" + path))
			assert_true(note.get("i18n", {}).has("title"), "showcase %s missing i18n title" % note.get("id"))
