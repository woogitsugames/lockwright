extends Node

## Local achievements (task 10, contrib/gpt/T10). No Game Center / Play Games yet —
## report_to_platform() is the seam where they plug in later. Progress is stored in
## Save under "achievements"; names/descriptions go through i18n (ach.<id>.name/desc).

signal unlocked(id: String)

const DATA_PATH := "res://data/achievements.json"

var defs: Array = []
var _counts: Dictionary = {}  # "event" -> count this run


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) == TYPE_DICTIONARY:
		defs = parsed.get("achievements", [])
	Events.lock_event.connect(_on_lock_event)
	Events.lock_opened.connect(_on_lock_opened)


func unlocked_ids() -> Array:
	return Save.get_value("achievements", [])


func is_unlocked(id: String) -> bool:
	return unlocked_ids().has(id)


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
	unlocked.emit(id)
	report_to_platform(id)  # seam for Game Center / Play Games (not wired yet)


func report_to_platform(_id: String) -> void:
	# Intentionally empty: platform services (Game Center, Play Games) are not
	# integrated yet; when they are, report here behind OS.has_feature() checks.
	pass


func _on_lock_event(e: Dictionary) -> void:
	var kind := String(e.get("kind", ""))
	_counts[kind] = int(_counts.get(kind, 0)) + 1
	_check_event_triggers(kind, e)


func _on_lock_opened() -> void:
	_counts["open"] = int(_counts.get("open", 0)) + 1
	_check_result_triggers()


func _check_event_triggers(kind: String, e: Dictionary) -> void:
	for d in defs:
		var trig: String = d.get("trigger", "")
		if not trig.begins_with("event="):
			continue
		var parts := trig.trim_prefix("event=").split(";")
		if parts[0] != kind:
			continue
		var ok := true
		for p in parts.slice(1):
			var kv := p.split("=", true, 1)
			if kv.size() != 2:
				continue
			if kv[0] == "family" and String(e.get("family", JobRun.family_for(JobRun.current_job))) != kv[1]:
				ok = false
			if kv[0] == "context" and kv[1] == "non_tutorial" and JobRun.mode == &"tutorial":
				ok = false
		if ok:
			unlock(d.get("id", ""))


func _check_result_triggers() -> void:
	for d in defs:
		var trig: String = d.get("trigger", "")
		if not trig.begins_with("result=open"):
			continue
		var ok := true
		for p in trig.split(";").slice(1):
			var kv := p.split("=", true, 1)
			if kv.size() != 2:
				continue
			if kv[0] == "mode" and kv[1] == "continuous" and JobRun.mode != &"run":
				ok = false
			elif kv[0].begins_with("count("):
				var ev := kv[0].trim_prefix("count(").trim_suffix(")")
				var want := int(kv[1])
				if int(_counts.get(ev, 0)) < want:
					ok = false
			elif kv[0].begins_with("max_streak("):
				pass  # streak tracking needs ordered events; approximated by count
		if ok:
			unlock(d.get("id", ""))


func reset_run_counts() -> void:
	_counts.clear()
