class_name JobRun
extends RefCounted
## Static context for the active job / tutorial (Tryb Zleceń loop, stage 2/3).

static var current_job: Dictionary = {}
static var mode: StringName = &"job"  # &"job" | &"tutorial" | &"run" | &"practice" (D-79, Practice)
static var tutorial_stage := 0
static var lives := 3
static var clean := true  # N-25: no drop/break/overset during the current run
static var last_tip := 0  # N-25: tip paid by JobRun.complete()

# lockcore families implemented in lockcore (v0.4); jobs with other families are
# hidden on the list (N-05) instead of silently remapped.
const IMPLEMENTED := [&"pin_tumbler", &"wafer", &"wooden_pin", &"warded", &"lever", &"lever_detector", &"ring_combo",
		&"dial_safe", &"combo", &"magnetic", &"dimple", &"disc_detainer", &"egyptian", &"time_lock", &"axial_slider"]
## N-63: families that already have the photoreal (plan B) lock screen. Only these are offered
## to the player; the rest stay hidden until their plan-B view ships (no placeholder lock.tscn).
const PHOTOREAL_READY := [&"pin_tumbler", &"warded", &"wafer", &"lever", &"dial_safe", &"combo", &"magnetic", &"dimple", &"disc_detainer", &"egyptian", &"time_lock", &"axial_slider"]
## Plan-B scene per family (pin_tumbler: res://scenes/lock_job.tscn).
const PLANB_SCENES := {
	&"warded": "res://scenes/photoreal/lock_job_warded.tscn",
	&"wafer": "res://scenes/photoreal/lock_job_wafer.tscn",
	&"lever": "res://scenes/photoreal/lock_job_lever.tscn",
	&"lever_detector": "res://scenes/photoreal/lock_job_lever_detector.tscn",
	&"dial_safe": "res://scenes/photoreal/lock_job_dial_safe.tscn",
	&"combo": "res://scenes/photoreal/lock_job_combo.tscn",
	&"magnetic": "res://scenes/photoreal/lock_job_magnetic.tscn",
	&"dimple": "res://scenes/photoreal/lock_job_dimple.tscn",
	&"disc_detainer": "res://scenes/photoreal/lock_job_disc_detainer.tscn",
	&"egyptian": "res://scenes/photoreal/lock_job_egyptian.tscn",
	&"time_lock": "res://scenes/photoreal/lock_job_time_lock.tscn",
	&"axial_slider": "res://scenes/photoreal/lock_job_axial_slider.tscn",
}

# Authored tutorial locks S1–S3 (docs/LEVELS.md §2.1–2.3, lockwright.lock/1, checked with
# lockcore/build/check_locks). Loaded through LockcoreSession.create_from_json.
const TUTORIAL_SPECS := ["res://data/tutorial/s1.json", "res://data/tutorial/s2.json", "res://data/tutorial/s3.json"]

# job.family (docs/JOBS.md, generic names) -> lockcore family (aliases only, N-05)
const FAMILY_MAP := {
	"lever": &"lever",
	"combo": &"combo",  # D-60: the thumbwheel lock is its own lockcore family
	"pin_tumbler": &"pin_tumbler",
	"wafer": &"wafer",
	"egyptian": &"egyptian",  # D-60: its own lockcore family (wooden_pin module, gravity pegs)
	"warded": &"warded",
	"lever_detector": &"lever_detector",
	"dial_safe": &"dial_safe",
	"magnetic": &"magnetic",
	"dimple": &"dimple",
	"disc_detainer": &"disc_detainer",
	"time_lock": &"time_lock",
	"axial_slider": &"axial_slider",
}


## T43: how a job ends. "open" (default) = lock scene + payment; "repair" = the time_lock clock-repair
## scene (still a lock scene, lock_opened -> payment, D-60); "talk" = verification settles it on the spot,
## no lock scene (T43 no_open: the spare key, the wrong delivery), a visit fee without a tip.
static func outcome_for(job: Dictionary) -> StringName:
	return StringName(job.get("outcome", "open"))


static func is_talk(job: Dictionary) -> bool:
	return outcome_for(job) == &"talk"


static func family_for(job: Dictionary) -> StringName:
	return FAMILY_MAP.get(job.get("family", ""), &"")


## D-103: what the locksmith checks before opening (data `verify_kind`): "premises" = the right to a
## flat/room/cellar/kiosk, "object" = whose the thing is (bike, chest, tin, safe), "shared" = consent
## for a common or institutional space or item opened on someone's behalf. Refusals keep the kind of
## what is asked for. Missing or unknown -> "premises" (the old wording).
const VERIFY_KINDS := ["premises", "object", "shared"]


static func verify_kind(job: Dictionary) -> String:
	var k := String(job.get("verify_kind", "premises"))
	return k if VERIFY_KINDS.has(k) else "premises"


## The text key for a verification wording of this job's kind: `<base>.<kind>` when that key exists
## (job.verify.object, verify.title.shared, verify.ask.witness.1.object …), else `base` (premises).
static func verify_key(base: StringName, job: Dictionary) -> StringName:
	var kind := verify_kind(job)
	if kind != "premises":
		var k := StringName("%s.%s" % [base, kind])
		if I18n.has_key(k):
			return k
	return base


## lever_detector joins as soon as its 5-lever plan-B assets are in the project
## (docs/handoff/LOCAL-SESSION-PROMPT.md (b)); no code change needed then.
const DETECTOR_GLB := "res://assets/photoreal_families/lever_detector/lever_detector_baked.glb"


static func planb_ready(fam: StringName) -> bool:
	return PHOTOREAL_READY.has(fam) or (fam == &"lever_detector" and ResourceLoader.exists(DETECTOR_GLB))


static func is_playable(job: Dictionary) -> bool:
	return IMPLEMENTED.has(family_for(job)) and planb_ready(family_for(job))


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
	# N-05: pass the tier from data through; lockcore clamps to the family range itself.
	# D-118: data/tools/validate.py rejects a job tier outside that range (lockcore/tiers.json).
	return maxi(1, int(job.get("tier", 1)))


## Every job that can be played now: the base game's and those of the content packs on the phone
## (D-112). The one place the job files are read from.
static func all_jobs() -> Array:
	var out: Array = []
	for path in ContentPacks.job_paths():
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(j) == TYPE_DICTIONARY:
			out.append(j)
	return out


## The job, or {} when there is no such job on the phone (unknown id, or its content pack is not
## downloaded / was removed: D-112). Callers treat {} as "no job".
static func job_by_id(jid: String) -> Dictionary:
	var path: String = ContentPacks.job_path(jid)
	if path != "":
		var named: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(named) == TYPE_DICTIONARY and named.get("id", "") == jid:
			return named
	for j: Dictionary in all_jobs():  # a file not named after its id
		if j.get("id", "") == jid:
			return j
	return {}


## Chapter, family and tier of a job for progress read from the save: the job itself, or the stub
## the app keeps for a job whose content pack is not on the phone (D-112). {} for an unknown id.
static func job_meta(jid: String) -> Dictionary:
	var j := job_by_id(jid)
	return j if not j.is_empty() else ContentPacks.stub(jid)


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
	var talk := is_talk(current_job)
	last_tip = int(reward * 0.25) if clean and reward > 0 and not talk else 0  # N-25: tip for a clean opening (JOBS.md §3, 0–30%)
	Save.set_value("coins", Save.get_value("coins", 0) + reward + last_tip)
	if not talk:  # T43: a visit settled by talking opens no lock
		Save.set_value("stats/locks_opened", Save.get_value("stats/locks_opened", 0) + 1)
	DayAfter.note_finished(current_job)  # V04/D-78: its "day after" scene waits for the job list
	current_job = {}
