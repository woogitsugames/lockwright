extends GutHookScript
## D-105: GUT pre-run hook (res://.gutconfig.json), so every run gets it: local, CI, -gselect.
## Each test script starts from the global state the previous one started from. Scripts that change
## the autoloads' state (Save, Settings, language, a11y overrides, Events routing, JobRun/Practice
## statics) without putting it back no longer leak it into the scripts that run after them, so a
## test's result does not depend on which scripts ran before it (alphabetical order, -gselect).
## Everything listed in _capture() is restored. A script that leaves the save or the settings changed
## (both persist to user://) is also named in the log ("[isolation] ..."): fix it there. Runtime
## context (language, JobRun/Practice, Events routing, a11y overrides) is restored silently: any test
## that starts a job leaves it behind.

const REPORTED := ["Save.data", "Settings"]

var _snap := {}
var _script_name := ""


func run() -> void:
	gut.start_script.connect(_on_start_script)
	gut.end_script.connect(_on_end_script)


func _on_start_script(coll_script: Variant) -> void:
	_script_name = coll_script.get_full_name() if coll_script != null else "?"
	_snap = _capture()


func _on_end_script() -> void:
	if _snap.is_empty():
		return
	var now := _capture()
	var leaked: PackedStringArray = []
	var detail: PackedStringArray = []
	for k: String in _snap:
		if not _same(_snap[k], now[k]):
			leaked.append(k)
			if k in REPORTED:
				detail.append("%s %s" % [k, _diff_keys(_snap[k], now[k])])
	if leaked.is_empty():
		return
	if not detail.is_empty():
		print("[isolation] %s left changed (restored): %s" % [_script_name, "; ".join(detail)])
	_restore(_snap, leaked)


func _capture() -> Dictionary:
	var events: Node = _autoload("Events")
	var a11y: Node = _autoload("UiA11y")
	var save: Dictionary = _autoload("Save").data.duplicate(true)
	save.erase("schema")   # Save.save() stamps it; not state
	return {
		"Save.data": save,
		"Settings": _autoload("Settings")._cfg.duplicate(true),
		"locale": TranslationServer.get_locale(),
		"UiA11y.overrides": [a11y.screen_reader_override, a11y.reduce_motion_override],
		"Events": [events.change_scenes, events.scene_override, events._fail_scene],
		"JobRun": [JobRun.mode, JobRun.current_job.duplicate(true), JobRun.tutorial_stage, JobRun.lives, JobRun.clean],
		"Practice": [Practice.current.duplicate(true), Practice.met_now],
	}


func _restore(s: Dictionary, keys: PackedStringArray) -> void:
	if keys.has("Save.data"):
		var save: Node = _autoload("Save")
		save.data = s["Save.data"].duplicate(true)
		save.save()   # a later Save.load_save() reads the file: it must not hold the leaked state either
	if keys.has("Settings"):
		var settings: Node = _autoload("Settings")
		settings._cfg = s["Settings"].duplicate(true)
		settings.save_settings()
		_autoload("UiA11y")._apply_text_scale()
		settings.changed.emit()
	if keys.has("locale"):
		_autoload("I18n").apply_language(String(s["locale"]))
	if keys.has("UiA11y.overrides"):
		var a11y: Node = _autoload("UiA11y")
		a11y.screen_reader_override = s["UiA11y.overrides"][0]
		a11y.reduce_motion_override = s["UiA11y.overrides"][1]
	if keys.has("Events"):
		var events: Node = _autoload("Events")
		events.change_scenes = s["Events"][0]
		events.scene_override = s["Events"][1] if is_instance_valid(s["Events"][1]) else null
		events._fail_scene = s["Events"][2] if is_instance_valid(s["Events"][2]) else null
	if keys.has("JobRun"):
		var j: Array = s["JobRun"]
		JobRun.mode = j[0]
		JobRun.current_job = j[1].duplicate(true)
		JobRun.tutorial_stage = j[2]
		JobRun.lives = j[3]
		JobRun.clean = j[4]
	if keys.has("Practice"):
		Practice.current = s["Practice"][0].duplicate(true)
		Practice.met_now = s["Practice"][1]


func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) == TYPE_ARRAY and typeof(b) == TYPE_ARRAY:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _same(a[i], b[i]):
				return false
		return true
	if typeof(a) == TYPE_OBJECT or typeof(b) == TYPE_OBJECT:
		return is_same(a, b)
	return typeof(a) == typeof(b) and a == b


func _diff_keys(a: Dictionary, b: Dictionary) -> Array:
	var out := []
	for k: Variant in a:
		if not b.has(k) or not _same(a[k], b[k]):
			out.append(k)
	for k: Variant in b:
		if not a.has(k):
			out.append(k)
	return out


func _autoload(n: String) -> Node:
	return Engine.get_main_loop().root.get_node("/root/" + n)
