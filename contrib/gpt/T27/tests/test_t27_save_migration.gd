extends "res://tests/gut/t27_fixture.gd"
## Save isolation follows ARCHITECTURE §6: persistent career state, not live lockcore ticks.


## Checks that starting a job does not pay coins before a successful completion.
func test_job_start_does_not_pay_early() -> void:
	var coins: int = Save.get_value("coins", 0)
	JobRun.start({"id": "job.t27_in_progress", "family": "pin_tumbler", "reward_coins": 80})
	assert_eq(Save.get_value("coins", 0), coins)
	assert_false(Save.get_value("jobs_completed", []).has("job.t27_in_progress"))


## Checks a disk save/reload in mid-job preserves career money, not an early reward.
func test_save_during_job_preserves_unpaid_state() -> void:
	var coins: int = Save.get_value("coins", 0)
	JobRun.start({"id": "job.t27_in_progress", "family": "pin_tumbler", "reward_coins": 80})
	Save.save()
	Save.load_save()
	assert_eq(Save.get_value("coins", 0), coins)
	assert_false(Save.get_value("jobs_completed", []).has("job.t27_in_progress"))


## Checks that saving does not serialize live job/lock state (current design contract).
func test_save_file_does_not_contain_live_job() -> void:
	JobRun.start({"id": "job.t27_transient", "family": "pin_tumbler"})
	Save.save()
	var raw := FileAccess.get_file_as_string(Save.PATH)
	assert_false(raw.contains("job.t27_transient"))
	assert_false(raw.contains("current_job"))
	assert_false(raw.contains("lockcore_session"))


## Checks a save reload in the same running app does not clobber active JobRun.
func test_mid_job_reload_keeps_in_memory_context() -> void:
	JobRun.start({"id": "job.t27_keep_context", "family": "pin_tumbler"})
	Save.save()
	Save.load_save()
	assert_eq(JobRun.current_job.get("id"), "job.t27_keep_context")


## Checks completed jobs are persisted with their payment after a reload.
func test_completion_persists_payment_and_progress() -> void:
	var start_coins: int = Save.get_value("coins", 0)
	JobRun.start({"id": "job.t27_complete", "family": "pin_tumbler", "reward_coins": 80})
	JobRun.complete()
	Save.load_save()
	assert_eq(Save.get_value("coins", 0), start_coins + 100)  # clean tip = 25%
	assert_true(Save.get_value("jobs_completed", []).has("job.t27_complete"))


## Checks migration from the current schema retains unrelated career metadata.
func test_save_1_migration_retains_progress() -> void:
	var migrated: Dictionary = Save.migrate({"schema": "save/1", "coins": 42,
		"jobs_completed": ["job.completed_before_upgrade"]})
	assert_eq(migrated.get("schema"), Save.SCHEMA)
	assert_eq(migrated.get("coins"), 42)
	assert_true(migrated.get("jobs_completed", []).has("job.completed_before_upgrade"))


## Checks future/unknown versions are not silently treated as compatible.
func test_unknown_schema_resets_to_current_version() -> void:
	var migrated: Dictionary = Save.migrate({"schema": "save/99", "coins": 999})
	assert_eq(migrated.get("schema"), Save.SCHEMA)
	assert_false(migrated.has("coins"))


## Checks absent schema takes the documented unknown-version reset path.
func test_missing_schema_migrates_to_default_version() -> void:
	var migrated: Dictionary = Save.migrate({"coins": 999})
	assert_eq(migrated.get("schema"), Save.SCHEMA)
	assert_false(migrated.has("coins"))


## Checks a truncated/corrupt file cannot crash save loading or grant progress.
func test_corrupt_json_load_falls_back_to_defaults() -> void:
	var file := FileAccess.open(Save.PATH, FileAccess.WRITE)
	assert_not_null(file)
	if file == null:
		return
	file.store_string("{incomplete:")
	file.close()
	Save.load_save()
	assert_eq(Save.get_value("coins", -1), 0)
	assert_true(Save.get_value("tools/tw_angle/owned", false))


## Checks merging a partial old save preserves nested tool defaults.
func test_partial_save_keeps_nested_defaults() -> void:
	Save.data = Save.DEFAULTS.duplicate(true)
	Save._merge(Save.data, {"tools": {"tw_angle": {"integrity": 23}}})
	assert_true(Save.get_value("tools/tw_angle/owned", false))
	assert_eq(Save.get_value("tools/tw_angle/integrity", -1), 23)
	assert_true(Save.get_value("tools/pk_hook/owned", false))


## Checks refusal data survives a normal save/reload (not only in memory).
func test_refusal_flags_roundtrip_through_disk() -> void:
	Save.set_value("jobs_refused", ["job.refuse_t27_roundtrip"])
	Save.load_save()
	assert_true(Save.get_value("jobs_refused", []).has("job.refuse_t27_roundtrip"))
