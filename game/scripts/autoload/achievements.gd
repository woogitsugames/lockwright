extends Node

## Local achievements (task 10, contrib/gpt/T10). No Game Center / Play Games yet —
## report_to_platform() is the seam where they plug in later. Progress is stored in
## Save under "achievements" (ids) and "achievements_at" (id -> "YYYY-MM-DD", D-133);
## names/descriptions go through i18n (ach.<id>.name/desc).
##
## D-133: the player sees them on a shelf in the Showcase, so a trigger is checked strictly. A
## condition the game cannot check never passes. Before D-133 unknown conditions were skipped, so
## the first open lock handed out "dark mode" and "no drops" plates at once.
##
## D-135: every achievement in the data can be earned. Three kinds of trigger (data/achievements.json):
##   event=<lockcore kind>;…   a lock event (Events.lock_event): set, drop, …
##   result=open;…             a lock opened (Events.lock_opened)
##   result=<milestone>;… / event=<milestone>;…   something outside a lock (Events.milestone), see
##                             MILESTONES: job results and refusals, lessons, practice goals, the
##                             continuous shift, the workshop
## Conditions after the head are all required. `supported()` says whether the game understands a
## trigger; a test keeps that true for every achievement, so the shelf shows all of them.

signal unlocked(id: String)

const DATA_PATH := "res://data/achievements.json"
const CATEGORIES := ["craft", "mode", "ethics", "story"]
## The data names some families after their lockcore module; jobs use the game name (JobRun.FAMILY_MAP).
const FAMILY_ALIAS := {"wooden_pin": "egyptian"}
## lockcore event kinds (lockcore/include/lockcore/events.hpp); anything else after `event=` is a milestone.
const LOCK_KINDS := ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate", "overset", "drop",
		"stress", "break", "wear", "gate_align", "detector_trip", "open"]
## Events.milestone kinds and the data keys a condition may test (the emitters are named on the right).
const MILESTONES := {
	"job_completed": ["job", "opened", "verified", "verified_by"],  # JobRun.complete()
	"job_refused": ["job", "reason"],                               # job_verify.gd, a refusal job declined
	"job_resolved": ["job", "opened"],                              # job_verify.gd, settled by "one more thing"
	"tutorial_completed": ["track"],                                # JobRun.complete(), S3 done
	"lesson_completed": ["family"],                                 # lock_photoreal.gd, a family lesson's lock open
	"practice_goal": ["id", "family", "family_left"],               # Practice.finish(), goal met and lock open
	"run_lock_opened": ["opened", "streak", "lives"],               # Events, a lock of the continuous shift
	"tool_bought": ["tool"],                                        # workshop_screen.gd
}
## "In the dark" (mode=dark): the light is off when the lock opens and nothing was set while it was on.
const PROGRESS_KINDS := ["set", "gate_align"]

var defs: Array = []
var _counts: Dictionary = {}  # event kind / sub-event name -> count on the current lock
var _last_tick := -1
## The lock the counted events belong to. Events (connected before this node) clears JobRun.current_job
## of a continuous-shift lock and Practice.finish() leaves the practice mode before lock_opened gets
## here; without the copy such a lock was judged as "no job": pin_tumbler, tier 1, mode "job".
var _ctx_job: Dictionary = {}
var _ctx_mode: StringName = &"job"
var _ctx_set := false


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		defs = parsed.get("achievements", [])
	Events.lock_event.connect(_on_lock_event)
	Events.lock_opened.connect(_on_lock_opened)
	Events.lock_failed.connect(func(_reason: StringName) -> void: reset_run_counts())
	Events.milestone.connect(_on_milestone)
	backfill()


func unlocked_ids() -> Array:
	return Save.get_value("achievements", [])


func is_unlocked(id: String) -> bool:
	return unlocked_ids().has(id)


## "YYYY-MM-DD" of the day the achievement was earned; "" when not earned, or earned before D-133.
func unlocked_on(id: String) -> String:
	var at: Variant = Save.get_value("achievements_at", {})
	return String(at.get(id, "")) if typeof(at) == TYPE_DICTIONARY else ""


func def_by_id(id: String) -> Dictionary:
	for d: Dictionary in defs:
		if d.get("id", "") == id:
			return d
	return {}


func points_total() -> int:
	var total := 0
	for d in defs:
		if is_unlocked(d.get("id", "")):
			total += int(d.get("points", 0))
	return total


## `dated` false: earned at a time the save does not know (backfill()); the shelf says "earned", no day.
func unlock(id: String, dated := true) -> void:
	if id == "" or is_unlocked(id):
		return
	var arr: Array = unlocked_ids()
	arr.append(id)
	Save.set_value("achievements", arr)
	if dated:
		var at: Variant = Save.get_value("achievements_at", {})
		var dates: Dictionary = at if typeof(at) == TYPE_DICTIONARY else {}
		dates[id] = Time.get_date_string_from_system()
		Save.set_value("achievements_at", dates)
	unlocked.emit(id)
	report_to_platform(id)  # seam for Game Center / Play Games (not wired yet)


func report_to_platform(_id: String) -> void:
	# Intentionally empty: platform services (Game Center, Play Games) are not
	# integrated yet; when they are, report here behind OS.has_feature() checks.
	pass


## Achievements the shelf shows, in data order. D-135: all of them (each can be earned; D-133 left
## out those whose trigger nobody reported). Hidden ones are drawn as "?" by the shelf.
func shelf_defs() -> Array:
	return defs.duplicate()


## Does the game understand this trigger (head and every condition)? True for all the data
## (test_achievements_d135.gd); false means a spot on the shelf that could never be filled.
static func supported(def: Dictionary) -> bool:
	var t := parse_trigger(String(def.get("trigger", "")))
	if t.is_empty():
		return false
	if t["head"] == "milestone":
		return _milestone_keys_known(t)
	for c: Array in t["conds"]:
		if not _cond_known(c):
			return false
	return true


## "result=open;family=lever;count(drop)=0" -> {head: "open", what: "open", conds: [[key, op, value], ...]}.
## head: "event" (a lock event `what`), "open" (the lock opened) or "milestone" (Events.milestone `what`).
## {} for a trigger the game does not know.
static func parse_trigger(trig: String) -> Dictionary:
	var parts := trig.split(";", false)
	if parts.is_empty():
		return {}
	var first := parts[0].split("=", true, 1)
	if first.size() != 2 or not (first[0] == "event" or first[0] == "result"):
		return {}
	var what := String(first[1])
	var head := ""
	if first[0] == "result" and what == "open":
		head = "open"
	elif first[0] == "event" and LOCK_KINDS.has(what):
		head = "event"
	elif MILESTONES.has(what):
		head = "milestone"
	else:
		return {}
	var conds: Array = []
	for p in parts.slice(1):
		var op := ">=" if p.contains(">=") else "="
		var kv := p.split(op, true, 1)
		conds.append([kv[0], op, kv[1] if kv.size() == 2 else ""])
	return {"head": head, "what": what, "conds": conds}


## A condition of a lock trigger (event=… / result=open).
static func _cond_known(c: Array) -> bool:
	var key := String(c[0])
	var value := String(c[2])
	if value == "":
		return false
	if key == "family":
		return JobRun.FAMILY_MAP.has(_family_name(value))  # a family no job has (ring_combo) cannot be opened
	if key == "tier":
		return value.is_valid_int()
	if key == "context":
		return value == "non_tutorial"
	if key == "mode":
		return value == "continuous" or value == "dark"
	return key.begins_with("count(") and key.ends_with(")") and value.is_valid_int()


## Milestone conditions name only data the milestone carries.
static func _milestone_keys_known(t: Dictionary) -> bool:
	var keys: Array = MILESTONES.get(String(t["what"]), [])
	for c: Array in t["conds"]:
		if not keys.has(String(c[0])) or String(c[2]) == "":
			return false
	return true


## The job and mode of the lock in play (see _ctx_job).
func _lock_job() -> Dictionary:
	if not JobRun.current_job.is_empty() or not _ctx_set:
		return JobRun.current_job
	return _ctx_job


func _lock_mode() -> StringName:
	return _ctx_mode if _ctx_set else JobRun.mode


func _cond_met(c: Array, family: String) -> bool:
	if not _cond_known(c):
		return false
	var key := String(c[0])
	var value := String(c[2])
	if key == "family":
		return family == _family_name(value)
	if key == "tier":
		var tier := JobRun.tier_for(_lock_job())
		return tier >= int(value) if c[1] == ">=" else tier == int(value)
	if key == "context":
		return _lock_mode() != &"tutorial"
	if key == "mode":
		if value == "dark":
			return Events.lock_dark and int(_counts.get("lit_progress", 0)) == 0
		return _lock_mode() == &"run"
	var have := int(_counts.get(key.trim_prefix("count(").trim_suffix(")"), 0))
	return have >= int(value) if c[1] == ">=" else have == int(value)


## One condition of a milestone trigger against the milestone's data. A key the data lacks never
## passes. bool -> "true"/"false"; a list passes when it holds the value; numbers compare as integers.
static func _data_cond_met(c: Array, data: Dictionary) -> bool:
	var key := String(c[0])
	var value := String(c[2])
	if not data.has(key) or value == "":
		return false
	var have: Variant = data[key]
	if have is Array:
		return c[1] == "=" and (have as Array).any(func(x: Variant) -> bool: return String(x) == value)
	if have is bool:
		return c[1] == "=" and value == ("true" if have else "false")
	if have is int or have is float:
		if not value.is_valid_int():
			return false
		return int(have) >= int(value) if c[1] == ">=" else int(have) == int(value)
	return c[1] == "=" and String(have) == value


static func _family_name(data_name: String) -> String:
	return String(FAMILY_ALIAS.get(data_name, data_name))


## Family of the lock in play. No job (S1–S3, practice) means pin_tumbler, as in JobRun.lock_scene_path() (T56).
func _current_family() -> String:
	var job := _lock_job()
	return "pin_tumbler" if job.is_empty() else String(JobRun.family_for(job))


func _on_lock_event(e: Dictionary) -> void:
	# a tick that runs backwards is a new lock session (left through the pause, retried): counts start over
	var tick := int(e.get("tick", -1))
	if tick >= 0:
		if tick < _last_tick:
			_counts.clear()
		_last_tick = tick
	_ctx_job = JobRun.current_job
	_ctx_mode = JobRun.mode
	_ctx_set = true
	var kind := String(e.get("kind", ""))
	_counts[kind] = int(_counts.get(kind, 0)) + 1
	var feel := String(e.get("feel", ""))  # D-130 sub-event name ("wood.creak", "detector.reset")
	if feel != "" and feel != kind:
		_counts[feel] = int(_counts.get(feel, 0)) + 1
	if PROGRESS_KINDS.has(kind) and not Events.lock_dark:
		_counts["lit_progress"] = int(_counts.get("lit_progress", 0)) + 1  # D-135: not "in the dark"
	_check("event", kind, String(e.get("family", _current_family())))


func _on_lock_opened() -> void:
	_counts["open"] = int(_counts.get("open", 0)) + 1
	_check("open", "open", _current_family())
	reset_run_counts()


## D-135: a save from before the milestones were reported. What the save proves was done is handed
## out once, without a day: these things cannot be done again (a refused job leaves the list, the
## tutorial is over, a tool is bought once), so without this an old career could never fill those
## spots. Nothing is ever taken away (a plate from before D-133 stays, earned strictly or not).
## Not provable from a save, so not given: what was asked at a verification, the dark, the shift.
func backfill() -> void:
	if bool(Save.get_value("tutorial_done", false)):
		_on_milestone(&"tutorial_completed", {"track": "pin"}, false)
	for fam: String in JobRun.FAMILY_MAP:
		if TutorialCoach.has_lesson_for(StringName(fam)) and TutorialCoach.lesson_done(StringName(fam)):
			_on_milestone(&"lesson_completed", {"family": fam}, false)
	for jid in Save.get_value("jobs_refused", []):
		_on_milestone(&"job_refused", {"job": String(jid), "reason": "unverified_access"}, false)
	# a job that the question settles has no other honest end (opening it is the wrong door, which
	# never completes it): completed means settled by asking
	var completed: Array = Save.get_value("jobs_completed", [])
	for d: Dictionary in defs:
		var t := parse_trigger(String(d.get("trigger", "")))
		if t.get("what", "") != "job_resolved":
			continue
		for c: Array in t["conds"]:
			if c[0] == "job" and completed.has(String(c[2])):
				_on_milestone(&"job_resolved", {"job": String(c[2]), "opened": false}, false)
	for e: Dictionary in Practice.entries():
		if Practice.goal_met(e["id"]):
			_on_milestone(&"practice_goal", {"id": String(e["id"]), "family": String(e["family"]),
					"family_left": Practice.goals_left(e["family"])}, false)
	var tools: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/tools.json"))
	if typeof(tools) == TYPE_DICTIONARY:
		for tool: Dictionary in tools.get("tools", []):
			var tid := String(tool.get("id", ""))
			if int(tool.get("price", 0)) > 0 and bool(Save.get_value("tools/%s/owned" % tid, false)):
				_on_milestone(&"tool_bought", {"tool": tid}, false)


func _on_milestone(kind: StringName, data: Dictionary, dated := true) -> void:
	for d: Dictionary in defs:
		var t := parse_trigger(String(d.get("trigger", "")))
		if t.is_empty() or t["head"] != "milestone" or t["what"] != String(kind):
			continue
		var ok := true
		for c: Array in t["conds"]:
			if not _data_cond_met(c, data):
				ok = false
				break
		if ok:
			unlock(d.get("id", ""), dated)


func _check(head: String, what: String, family: String) -> void:
	for d: Dictionary in defs:
		var t := parse_trigger(String(d.get("trigger", "")))
		if t.is_empty() or t["head"] != head or t["what"] != what:
			continue
		var ok := true
		for c: Array in t["conds"]:
			if not _cond_met(c, family):
				ok = false
				break
		if ok:
			unlock(d.get("id", ""))


func reset_run_counts() -> void:
	_counts.clear()
	_last_tick = -1
	_ctx_job = {}
	_ctx_set = false
