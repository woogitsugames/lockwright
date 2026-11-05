class_name JobRun
extends RefCounted
## Static context for the active job (Tryb Zleceń loop, task 3).

static var current_job: Dictionary = {}
static var lives := 3

# job.family (docs/JOBS.md) -> lockcore family implemented in lockcore v0.2
const FAMILY_MAP := {
	"lever": &"lever",
	"combo": &"ring_combo",
	"pin_tumbler": &"pin_tumbler",
	"wafer": &"wafer",
	"egyptian": &"wooden_pin",
	"warded": &"warded",
	"dial_safe": &"lever_detector",
	"time_lock": &"wafer",
	"dimple": &"warded",
	"disc_detainer": &"warded",
	"tubular": &"pin_tumbler",
	"magnetic": &"ring_combo",
	"axial_slider": &"warded",
}


static func family_for(job: Dictionary) -> StringName:
	return FAMILY_MAP.get(job.get("family", "lever"), &"lever")


static func seed_for(job: Dictionary) -> int:
	return int(abs(hash(job.get("id", "job"))) % 1000000) + 1


static func tier_for(job: Dictionary) -> int:
	return clampi(int(job.get("tier", 1)), 1, 3)


static func start(job: Dictionary) -> void:
	current_job = job
	lives = 3


static func complete() -> void:
	var jid: String = current_job.get("id", "")
	var completed: Array = Save.get_value("jobs_completed", [])
	if not completed.has(jid):
		completed.append(jid)
		Save.set_value("jobs_completed", completed)
	Save.set_value("coins", Save.get_value("coins", 0) + int(current_job.get("reward_coins", 0)))
	Save.set_value("stats/locks_opened", Save.get_value("stats/locks_opened", 0) + 1)
	current_job = {}
