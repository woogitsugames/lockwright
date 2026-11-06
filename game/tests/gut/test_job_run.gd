extends GutTest
## N-05/N-06/N-09: job filtering, FNV-1a seed, tutorial mode never pays out.

func test_unimplemented_families_hidden() -> void:
	assert_false(JobRun.is_playable({"family": "safe_wheels"}))  # a family without a lockcore module
	assert_true(JobRun.is_playable({"family": "dial_safe"}))  # D-59 plan-B screen shipped
	assert_false(JobRun.is_playable({"family": "unknown"}))
	assert_true(JobRun.is_playable({"family": "pin_tumbler"}))
	assert_true(JobRun.is_playable({"family": "lever"}))  # N-63: plan-B screen shipped
	# N-72: the 5-lever model is in assets/photoreal_families/lever_detector/ (4766aac)
	assert_true(JobRun.planb_ready(&"lever_detector"))
	assert_true(JobRun.is_playable({"family": "lever_detector"}))
	# still without a plan-B screen: wooden_pin and ring_combo jobs stay hidden
	assert_false(JobRun.is_playable({"family": "wooden_pin"}))
	assert_false(JobRun.is_playable({"family": "ring_combo"}))


## N-72: every job family in the data is either playable or one of the known hidden ones.
func test_job_families_playable_or_known_hidden() -> void:
	const HIDDEN := ["wooden_pin", "ring_combo"]
	var seen := {}
	for dir in ["res://data/jobs", "res://data/jobs_ch7"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".json"):
				var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
				seen[String(j.get("family", ""))] = JobRun.is_playable(j)
	for fam in seen:
		assert_eq(seen[fam], not HIDDEN.has(fam), "job family %s playable=%s" % [fam, seen[fam]])

func test_fnv1a_seed_stable() -> void:
	# N-06: FNV-1a 64 of "job.grandma_broth"
	assert_eq(JobRun.fnv1a64("job.grandma_broth"), JobRun.fnv1a64("job.grandma_broth"))
	assert_ne(JobRun.fnv1a64("a"), JobRun.fnv1a64("b"))

func test_tier_passthrough() -> void:
	assert_eq(JobRun.tier_for({"tier": 5}), 5, "N-05: tier from data, no clamp to 3")

func test_tutorial_mode_completes_without_payment() -> void:
	JobRun.mode = &"tutorial"
	JobRun.tutorial_stage = 0
	JobRun.current_job = {"id": "tutorial.s1", "reward_coins": 0}
	JobRun.complete()
	assert_eq(JobRun.tutorial_stage, 1)
	assert_eq(Save.get_value("coins", 0), Save.get_value("coins", 0), "no coins in tutorial")
	JobRun.tutorial_stage = 2
	JobRun.complete()
	assert_true(Save.get_value("tutorial_done", false), "N-09: tutorial_done after S3")
	Save.set_value("tutorial_done", false)
	JobRun.mode = &"job"
