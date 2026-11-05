class_name JobRun
extends RefCounted
## Static context for the active job / tutorial (Tryb Zleceń loop, stage 2/3).

static var current_job: Dictionary = {}
static var mode: StringName = &"job"  # &"job" | &"tutorial"
static var tutorial_stage := 0
static var lives := 3

# lockcore families implemented in lockcore (v0.4); jobs with other families are
# hidden on the list (N-05) instead of silently remapped.
const IMPLEMENTED := [&"pin_tumbler", &"wafer", &"wooden_pin", &"warded", &"lever", &"lever_detector", &"ring_combo"]

# job.family (docs/JOBS.md, generic names) -> lockcore family (aliases only, N-05)
const FAMILY_MAP := {
	"lever": &"lever",
	"combo": &"ring_combo",
	"pin_tumbler": &"pin_tumbler",
	"wafer": &"wafer",
	"egyptian": &"wooden_pin",
	"warded": &"warded",
	"lever_detector": &"lever_detector",
}


static func family_for(job: Dictionary) -> StringName:
	return FAMILY_MAP.get(job.get("family", ""), &"")


static func is_playable(job: Dictionary) -> bool:
	return IMPLEMENTED.has(family_for(job))


static func fnv1a64(s: String) -> int:
	# N-06: FNV-1a 64 like lockcore, engine-independent
	var h := -3750763034362895579  # FNV-1a offset basis 0xcbf29ce484222325 as signed int64
	for i in s.length():
		h = (h ^ s.unicode_at(i)) * 0x100000001b3
	return h & 0x7FFFFFFFFFFFFFFF


static func seed_for(job: Dictionary) -> int:
	return int(fnv1a64(job.get("id", "job")) % 1000000) + 1


static func tier_for(job: Dictionary) -> int:
	# N-05: pass the tier from data through; lockcore clamps to the family range itself
	return maxi(1, int(job.get("tier", 1)))


static func start(job: Dictionary) -> void:
	current_job = job
	mode = &"job"
	lives = 3


static func start_tutorial(stage: int) -> void:
	# N-09: tutorial is a separate mode — never lands on job_payment
	mode = &"tutorial"
	tutorial_stage = stage
	current_job = {"id": "tutorial.s%d" % (stage + 1), "family": "pin_tumbler", "tier": 1, "reward_coins": 0, "i18n": {}}
	lives = 3


static func complete() -> void:
	if mode == &"tutorial":
		tutorial_stage += 1
		if tutorial_stage >= 3:
			Save.set_value("tutorial_done", true)
		current_job = {}
		return
	var jid: String = current_job.get("id", "")
	var completed: Array = Save.get_value("jobs_completed", [])
	if not completed.has(jid):
		completed.append(jid)
		Save.set_value("jobs_completed", completed)
	Save.set_value("coins", Save.get_value("coins", 0) + int(current_job.get("reward_coins", 0)))
	Save.set_value("stats/locks_opened", Save.get_value("stats/locks_opened", 0) + 1)
	current_job = {}
