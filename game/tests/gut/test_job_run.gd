extends GutTest
## N-05/N-06/N-09: job filtering, FNV-1a seed, tutorial mode never pays out.

func test_unimplemented_families_hidden() -> void:
	assert_false(JobRun.is_playable({"family": "dial_safe"}))
	assert_false(JobRun.is_playable({"family": "unknown"}))
	assert_true(JobRun.is_playable({"family": "pin_tumbler"}))
	assert_true(JobRun.is_playable({"family": "lever"}))

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
