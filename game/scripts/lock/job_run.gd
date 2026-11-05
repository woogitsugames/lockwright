class_name JobRun
extends RefCounted
## Static context for the active job / tutorial (Tryb Zleceń loop, stage 2/3).

static var current_job: Dictionary = {}
static var mode: StringName = &"job"  # &"job" | &"tutorial"
static var tutorial_stage := 0
static var lives := 3
static var clean := true  # N-25: no drop/break/overset during the current run
static var last_tip := 0  # N-25: tip paid by JobRun.complete()

# lockcore families implemented in lockcore (v0.4); jobs with other families are
# hidden on the list (N-05) instead of silently remapped.
const IMPLEMENTED := [&"pin_tumbler", &"wafer", &"wooden_pin", &"warded", &"lever", &"lever_detector", &"ring_combo"]
## N-63: families that already have the photoreal (plan B) lock screen. Only these are offered
## to the player; the rest stay hidden until their plan-B view ships (no placeholder lock.tscn).
const PHOTOREAL_READY := [&"pin_tumbler", &"warded"]
## Plan-B scene per family (pin_tumbler: res://scenes/lock_job.tscn).
const PLANB_SCENES := {
	&"warded": "res://scenes/photoreal/lock_job_warded.tscn",
}

# Authored tutorial locks S1–S3 (docs/LEVELS.md §2.1–2.3, lockwright.lock/1, checked with
# lockcore/build/check_locks). Loaded through LockcoreSession.create_from_json.
const TUTORIAL_SPECS := ["res://data/tutorial/s1.json", "res://data/tutorial/s2.json", "res://data/tutorial/s3.json"]

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
	return IMPLEMENTED.has(family_for(job)) and PHOTOREAL_READY.has(family_for(job))


static func lock_scene_path() -> String:
	# N-10/D-37: pin_tumbler gets the photoreal screen (plan B) via a thin wrapper that
	# feeds it the job's family/seed/tier (N-14); other families stay on the placeholder
	# view until session A ships their scenes
	var fam := family_for(current_job)
	if fam == &"pin_tumbler" or current_job.is_empty():
		return "res://scenes/lock_job.tscn"
	if PLANB_SCENES.has(fam):
		return PLANB_SCENES[fam]
	return "res://scenes/lock.tscn"


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


static func job_by_id(jid: String) -> Dictionary:
	for dir in ["res://data/jobs", "res://data/jobs_ch7"]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".json"):
				continue
			var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
			if j.get("id", "") == jid:
				return j
	return {}


static func start(job: Dictionary) -> void:
	current_job = job
	mode = &"job"
	lives = 3
	clean = true
	last_tip = 0


static func start_tutorial(stage: int) -> void:
	# N-09: tutorial is a separate mode — never lands on job_payment
	mode = &"tutorial"
	tutorial_stage = stage
	current_job = {"id": "tutorial.s%d" % (stage + 1), "family": "pin_tumbler", "tier": 1, "reward_coins": 0, "i18n": {},
			"lock_spec": TUTORIAL_SPECS[clampi(stage, 0, TUTORIAL_SPECS.size() - 1)]}
	lives = 3
	clean = true
	last_tip = 0


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
	var reward := int(current_job.get("reward_coins", 0))
	last_tip = int(reward * 0.25) if clean and reward > 0 else 0  # N-25: tip for a clean opening (JOBS.md §3, 0–30%)
	Save.set_value("coins", Save.get_value("coins", 0) + reward + last_tip)
	Save.set_value("stats/locks_opened", Save.get_value("stats/locks_opened", 0) + 1)
	current_job = {}
