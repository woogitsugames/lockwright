extends Node

## Local achievements (task 10, contrib/gpt/T10). No Game Center / Play Games yet —
## report_to_platform() is the seam where they plug in later. Progress is stored in
## Save under "achievements" (ids) and "achievements_at" (id -> "YYYY-MM-DD", D-133);
## names/descriptions go through i18n (ach.<id>.name/desc).
##
## D-133: the player sees them on a shelf in the Showcase, so a trigger is checked strictly. A
## condition the game cannot check (a mode that does not exist yet, a job result nobody reports)
## never passes, and such an achievement is not `supported()`: the shelf leaves it out instead of
## showing a spot that can never be filled. Before D-133 unknown conditions were skipped, so the
## first open lock handed out "dark mode" and "no drops" plates at once.

signal unlocked(id: String)

const DATA_PATH := "res://data/achievements.json"
const CATEGORIES := ["craft", "mode", "ethics", "story"]
## The data names some families after their lockcore module; jobs use the game name (JobRun.FAMILY_MAP).
const FAMILY_ALIAS := {"wooden_pin": "egyptian"}

var defs: Array = []
var _counts: Dictionary = {}  # event kind / sub-event name -> count on the current lock
var _last_tick := -1


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		defs = parsed.get("achievements", [])
	Events.lock_event.connect(_on_lock_event)
	Events.lock_opened.connect(_on_lock_opened)
	Events.lock_failed.connect(func(_reason: StringName) -> void: reset_run_counts())


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


func unlock(id: String) -> void:
	if id == "" or is_unlocked(id):
		return
	var arr: Array = unlocked_ids()
	arr.append(id)
	Save.set_value("achievements", arr)
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


## Achievements the shelf shows, in data order: those the game can award now, plus any the player
## already holds.
func shelf_defs() -> Array:
	var out: Array = []
	for d: Dictionary in defs:
		if supported(d) or is_unlocked(d.get("id", "")):
			out.append(d)
	return out


## Can the game check this trigger today?
static func supported(def: Dictionary) -> bool:
	var t := parse_trigger(String(def.get("trigger", "")))
	if t.is_empty():
		return false
	for c: Array in t["conds"]:
		if not _cond_known(c):
			return false
	return true


## "result=open;family=lever;count(drop)=0" -> {head: "result", what: "open", conds: [[key, op, value], ...]}.
## {} for a head the game never reports (job results, challenges, workshop events).
static func parse_trigger(trig: String) -> Dictionary:
	var parts := trig.split(";", false)
	if parts.is_empty():
		return {}
	var head := parts[0].split("=", true, 1)
	if head.size() != 2:
		return {}
	if not (head[0] == "event" or (head[0] == "result" and head[1] == "open")):
		return {}
	var conds: Array = []
	for p in parts.slice(1):
		var op := ">=" if p.contains(">=") else "="
		var kv := p.split(op, true, 1)
		conds.append([kv[0], op, kv[1] if kv.size() == 2 else ""])
	return {"head": head[0], "what": head[1], "conds": conds}


static func _cond_known(c: Array) -> bool:
	var key := String(c[0])
	if key == "family":
		return JobRun.FAMILY_MAP.has(_family_name(String(c[2])))  # a family no job has (ring_combo) cannot be opened
	if key == "tier":
		return String(c[2]).is_valid_int()
	if key == "context":
		return c[2] == "non_tutorial"
	if key == "mode":
		return c[2] == "continuous"
	return key.begins_with("count(") and key.ends_with(")") and String(c[2]).is_valid_int()


func _cond_met(c: Array, family: String) -> bool:
	if not _cond_known(c):
		return false
	var key := String(c[0])
	var value := String(c[2])
	if key == "family":
		return family == _family_name(value)
	if key == "tier":
		var tier := JobRun.tier_for(JobRun.current_job)
		return tier >= int(value) if c[1] == ">=" else tier == int(value)
	if key == "context":
		return JobRun.mode != &"tutorial"
	if key == "mode":
		return JobRun.mode == &"run"
	var have := int(_counts.get(key.trim_prefix("count(").trim_suffix(")"), 0))
	return have >= int(value) if c[1] == ">=" else have == int(value)


static func _family_name(data_name: String) -> String:
	return String(FAMILY_ALIAS.get(data_name, data_name))


## Family of the lock in play. No job (S1–S3, practice) means pin_tumbler, as in JobRun.lock_scene_path() (T56).
static func _current_family() -> String:
	return "pin_tumbler" if JobRun.current_job.is_empty() else String(JobRun.family_for(JobRun.current_job))


func _on_lock_event(e: Dictionary) -> void:
	# a tick that runs backwards is a new lock session (left through the pause, retried): counts start over
	var tick := int(e.get("tick", -1))
	if tick >= 0:
		if tick < _last_tick:
			_counts.clear()
		_last_tick = tick
	var kind := String(e.get("kind", ""))
	_counts[kind] = int(_counts.get(kind, 0)) + 1
	var feel := String(e.get("feel", ""))  # D-130 sub-event name ("wood.creak", "detector.reset")
	if feel != "" and feel != kind:
		_counts[feel] = int(_counts.get(feel, 0)) + 1
	_check("event", kind, String(e.get("family", _current_family())))


func _on_lock_opened() -> void:
	_counts["open"] = int(_counts.get("open", 0)) + 1
	_check("result", "open", _current_family())
	reset_run_counts()


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
