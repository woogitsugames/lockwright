class_name Practice
extends RefCounted
## D-79: practice mode ("Ćwiczenia", a tab of the Workshop). One entry = one authored practice lock
## (lockwright.lock/1, lockcore/practice/, D-54) played on the family's plan-B lock screen with its goal
## (`practice.<id>.goal`) written in chalk at the top of the plate. No coins, no timer, no pick lost.
##
## Data: res://data/practice/<id>.json are copies of the lockcore/practice files whose family has a
## plan-B screen that draws every element (test_practice.gd checks the copies and the exclusions).
## A lock unlocks once its family was met in the career (a completed job of the family; pin_tumbler
## also by the tutorial S1–S3; a family lesson D-68 counts too). The goal is met when the lock's
## `lesson_target` event happened during an attempt that ends with the lock open (check_locks gates
## both: clumsy bot meets the target, feeling bot opens, D-54). Opening is required because some
## targets come for free (`bind` happens as soon as tension is held, also in auto tension).
## Saved as `practice/<id>/goal`.

const DIR := "res://data/practice"
const JOB_DIR := "res://data/jobs"
## Family sub-events a lesson_target can name (lockcore FamilyModule::event_name: base kind + sub).
## Base kinds ("set", "overset", "false_set", ...) match by name; a base kind also matches its
## sub-events, as in check_locks ("false_set" counts a serration).
const SUB_EVENTS := {
	"pin.serration": [&"false_set", 1],
	"lever.false_gate": [&"false_set", 1],
	"detector.reset": [&"drop", 2],
}

static var _entries: Array = []
static var _job_family: Dictionary = {}  # job id -> lockcore family (built once)
## The entry being played ({} outside a practice run) and whether its goal was met in this attempt.
static var current: Dictionary = {}
static var met_now := false
## Result of the last attempt for the Workshop line: &"" | &"met" | &"open" | &"failed".
static var last_result := &""


## All entries in path order (presentation.practice.order): {id, family, tier, order, goal_key,
## target, path, elements}.
static func entries() -> Array:
	if not _entries.is_empty():
		return _entries
	var out: Array = []
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".json"):
			continue
		var path := DIR + "/" + f
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(d) != TYPE_DICTIONARY:
			push_warning("practice: %s is not a lock file" % path)
			continue
		var p: Dictionary = d.get("presentation", {}).get("practice", {})
		var id := String(d.get("id", "")).trim_prefix("practice.")
		out.append({
			"id": id,
			"family": StringName(d.get("family", "")),
			"tier": int(d.get("difficulty", {}).get("tier", 1)),
			"order": int(p.get("order", 999)),
			"goal_key": StringName(p.get("goal_key", "practice.%s.goal" % id)),
			"target": String(p.get("lesson_target", "open")),
			"path": path,
			"elements": element_count(d),
		})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["order"] < b["order"])
	_entries = out
	return _entries


## Number of mechanism elements in a lock file (stacks, wafers, levers, wards, ...).
static func element_count(d: Dictionary) -> int:
	for v in (d.get("spec", {}) as Dictionary).values():
		if v is Array and not (v as Array).is_empty() and (v as Array)[0] is Dictionary:
			return (v as Array).size()
	return 0


static func entry(id: String) -> Dictionary:
	for e in entries():
		if e["id"] == id:
			return e
	return {}


## Families in the order they first appear on the path (the Workshop groups the rows by family).
static func families() -> Array:
	var out: Array = []
	for e in entries():
		if not out.has(e["family"]):
			out.append(e["family"])
	return out


static func family_met(fam: StringName) -> bool:
	if fam == &"pin_tumbler" and bool(Save.get_value("tutorial_done", false)):
		return true
	if TutorialCoach.lesson_done(fam):
		return true
	if _job_family.is_empty():
		for f in DirAccess.get_files_at(JOB_DIR):
			if f.ends_with(".json"):
				var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(JOB_DIR + "/" + f))
				if typeof(j) == TYPE_DICTIONARY:
					_job_family[String(j.get("id", ""))] = JobRun.family_for(j)
	for jid in Save.get_value("jobs_completed", []):
		if _job_family.get(String(jid), &"") == fam:
			return true
	return false


static func unlocked(e: Dictionary) -> bool:
	return family_met(e["family"])


static func goal_met(id: String) -> bool:
	return bool(Save.get_value("practice/%s/goal" % id, false))


## Prepares the run (JobRun context); the caller changes to JobRun.lock_scene_path().
static func start(e: Dictionary) -> void:
	current = e
	met_now = false
	last_result = &""
	JobRun.mode = &"practice"
	JobRun.current_job = {"id": "practice." + String(e["id"]), "family": String(e["family"]), "tier": e["tier"],
			"reward_coins": 0, "i18n": {}, "lock_spec": e["path"]}
	JobRun.lives = 3
	JobRun.clean = true
	JobRun.last_tip = 0


static func active() -> bool:
	return JobRun.mode == &"practice" and not current.is_empty()


## True if lockcore event `ev` is the lesson target `target`.
static func matches(target: String, ev: Dictionary) -> bool:
	var kind := String(ev.get("kind", ""))
	if kind == target:
		return true
	var sub: Array = SUB_EVENTS.get(target, [])
	return sub.size() == 2 and kind == String(sub[0]) and int(ev.get("sub", 0)) == int(sub[1])


## Events of one physics step. Returns true when the target happens for the first time in this attempt.
static func note_events(events: Array) -> bool:
	if not active() or met_now:
		return false
	for ev in events:
		if matches(current["target"], ev):
			met_now = true
			return true
	return false


## End of the attempt (opened, failed, or left through the pause): the Workshop shows the result once.
static func finish(opened: bool, quit := false) -> void:
	if opened and met_now and not current.is_empty():
		Save.set_value("practice/%s/goal" % current["id"], true)
	last_result = &"" if quit else (&"failed" if not opened else (&"met" if met_now else &"open"))
	current = {}
	met_now = false
	JobRun.mode = &"job"
	# the job context goes at idle time: the other lock_opened listeners of this emission (Achievements,
	# connected after Events) still see the practice lock's family instead of "no job = pin_tumbler"
	(func() -> void: JobRun.current_job = {}).call_deferred()
