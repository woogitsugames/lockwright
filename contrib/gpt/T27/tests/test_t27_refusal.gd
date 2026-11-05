extends "res://tests/gut/t27_fixture.gd"
## Ethical refusal: no opening, no payment, reputation only once (N-15).


## Checks a refusal job hides the action that would open a lock.
func test_refusal_job_hides_accept_button() -> void:
	JobRun.start(t27_job())
	var scene := t27_scene("res://scenes/job_verify.tscn")
	assert_false(scene.get_node("VBox/AcceptButton").visible)
	assert_true(scene.get_node("VBox/RefuseButton").visible)


## Checks a normal job still offers an accept action after verification.
func test_ordinary_job_offers_accept_button() -> void:
	JobRun.start(t27_job("job.t27_normal"))
	var scene := t27_scene("res://scenes/job_verify.tscn")
	assert_true(scene.get_node("VBox/AcceptButton").visible)


## Checks the first ethical refusal records its ID and earns exactly five reputation.
func test_first_refusal_adds_five_reputation() -> void:
	Save.set_value("jobs_refused", [])
	Save.set_value("reputation", 10)
	JobRun.start(t27_job())
	var scene := t27_scene("res://scenes/job_verify.tscn")
	scene._refuse()  # assertions run before its 1.2 s presentation timer
	assert_eq(Save.get_value("reputation", 0), 15)
	assert_true(Save.get_value("jobs_refused", []).has("job.refuse_t27_fixture"))


## Checks refusing the same job twice cannot farm reputation or duplicate save IDs.
func test_refusal_reward_is_idempotent() -> void:
	Save.set_value("jobs_refused", [])
	Save.set_value("reputation", 10)
	JobRun.start(t27_job())
	var first := t27_scene("res://scenes/job_verify.tscn")
	first._refuse()
	var second := t27_scene("res://scenes/job_verify.tscn")
	second._refuse()
	assert_eq(Save.get_value("reputation", 0), 15)
	assert_eq(Save.get_value("jobs_refused", []).count("job.refuse_t27_fixture"), 1)


## Checks refusing a job never awards coins or records an opened lock.
func test_refusal_cannot_pay_or_count_as_open() -> void:
	Save.set_value("jobs_refused", [])
	var coins: int = Save.get_value("coins", 0)
	var opened: int = Save.get_value("stats/locks_opened", 0)
	JobRun.start(t27_job())
	var scene := t27_scene("res://scenes/job_verify.tscn")
	scene._refuse()
	assert_eq(Save.get_value("coins", 0), coins)
	assert_eq(Save.get_value("stats/locks_opened", 0), opened)
	assert_false(Save.get_value("jobs_completed", []).has("job.refuse_t27_fixture"))


## Checks the refusal action disables both choices against accidental double taps.
func test_refusal_disables_both_actions_immediately() -> void:
	Save.set_value("jobs_refused", [])
	JobRun.start(t27_job())
	var scene := t27_scene("res://scenes/job_verify.tscn")
	scene._refuse()
	assert_true(scene.get_node("VBox/AcceptButton").disabled)
	assert_true(scene.get_node("VBox/RefuseButton").disabled)


## Checks at least one authored ethical-refusal job remains in the game data.
func test_real_refusal_job_data_is_available() -> void:
	var job: Dictionary = JobRun.job_by_id("job.refuse_ex_partner")
	assert_false(job.is_empty(), "the documented first refusal case is missing")
	if not job.is_empty():
		assert_true(JobRun.is_playable(job))
		assert_eq(job.get("reward_coins", 0), 0)
