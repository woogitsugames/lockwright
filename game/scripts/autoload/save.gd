extends Node
## Save singleton. Versioned JSON at user://save.json with migrations.
## Stores meta progress only, never in-lock simulation state (ARCHITECTURE.md §6).
##
## D-136 (robustness): the file is replaced atomically (SafeFile: temp file + rename) and the save that
## was good before the last write stays next to it as save.json.bak.
##   - write fails (full disk, D-123): the files on disk are untouched, the game keeps playing from
##     memory, `dirty` stays true and the write is tried again on the next change, when the app goes
##     to the background and when it closes;
##   - save.json missing, empty, cut or not JSON: the backup is loaded; the damaged file is kept as
##     save.corrupt.json (one copy) instead of being overwritten by a fresh career;
##   - a value of the wrong type (hand-edited or damaged file) is not handed to the game: get_value()
##     returns the caller's default, and the built-in keys fall back to DEFAULTS when loading.

signal changed

const PATH := "user://save.json"
const SCHEMA := "save/1"
## Schemas migrate() can read. Any other is a newer build's save or a foreign file.
const KNOWN_SCHEMAS := ["save/1"]

const DEFAULTS := {
	"coins": 0,
	"tools": {"tw_angle": {"owned": true, "integrity": 100}, "pk_hook": {"owned": true, "integrity": 100}, "pk_rake": {"owned": true, "integrity": 100}},
	"showcase_seen": [],
	"settings_haptics_calibrated": false,
	"stats": {"locks_opened": 0, "locks_broken": 0, "runs_finished": 0},
}

var data: Dictionary = {}
## Where the file lives (tests point a private Save node at their own folder).
var path := PATH
## True while memory holds changes the disk does not (the last write failed).
var dirty := false
## OK, or the error of the last write.
var last_error: Error = OK
## What load_save() found: "new" (no file: first launch), "primary", "backup" (save.json was damaged
## or missing, save.json.bak was used), "defaults" (a save existed but nothing readable was left).
var loaded_from := "new"
var _last_text := ""  # what the file on disk holds (skips writes that would change nothing)
var _hold := 0        # hold() depth: writes wait for release()
var _held := false    # a write was asked for while held


func _ready() -> void:
	load_save()


func backup_path() -> String:
	return path + SafeFile.BACKUP_SUFFIX


func corrupt_path() -> String:
	return path.get_basename() + ".corrupt." + path.get_extension()


func load_save() -> void:
	_last_text = ""
	_hold = 0
	_held = false
	dirty = false
	last_error = OK
	SafeFile.drop_stale_tmp(path)
	var had_primary := FileAccess.file_exists(path)
	var had_backup := FileAccess.file_exists(backup_path())
	var parsed: Variant = SafeFile.read_json_object(path)
	loaded_from = "primary"
	if parsed == null:
		if had_primary:
			_set_aside()
		parsed = SafeFile.read_json_object(backup_path())
		if parsed != null:
			loaded_from = "backup"
			_report("Save: %s was %s, the backup was loaded" % [path, ("damaged (kept as %s)" % corrupt_path()) if had_primary else "missing"])
		elif had_primary or had_backup:
			loaded_from = "defaults"
			_report("Save: nothing readable in %s or its backup, starting fresh" % path)
		else:
			loaded_from = "new"
	if parsed == null:
		data = DEFAULTS.duplicate(true)
		return
	var d: Dictionary = parsed
	if str(d.get("schema", "")) != SCHEMA:
		if not KNOWN_SCHEMAS.has(str(d.get("schema", ""))) and loaded_from == "primary":
			# a save from a newer build (or a foreign file): never destroyed, only set aside
			DirAccess.copy_absolute(path, corrupt_path())
			_report("Save: unknown schema in %s, starting fresh (file kept as %s)" % [path, corrupt_path()])
		d = migrate(d)
	data = DEFAULTS.duplicate(true)
	_merge(data, d)
	_repair(data, DEFAULTS)


func migrate(d: Dictionary) -> Dictionary:
	# One-way migrations, oldest first. Unknown schemas reset to defaults.
	var schema: String = str(d.get("schema", ""))
	match schema:
		"save/1":
			d["schema"] = SCHEMA
		_:
			push_warning("Save: unknown schema '%s', starting fresh" % schema)
			d = {"schema": SCHEMA}
	return d


func _merge(base: Dictionary, over: Dictionary) -> void:
	for key in over:
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(over[key]) == TYPE_DICTIONARY:
			_merge(base[key], over[key])
		else:
			base[key] = over[key]


## Built-in keys keep the type of their default: a damaged "tools": 7 or "coins": "x" goes back to
## the default instead of crashing the first screen that reads it.
func _repair(d: Dictionary, defaults: Dictionary) -> void:
	for key: String in defaults:
		var def: Variant = defaults[key]
		if not d.has(key) or not same_kind(d[key], def):
			if d.has(key):
				_report("Save: '%s' had the wrong type, default restored" % key)
			d[key] = def.duplicate(true) if (def is Dictionary or def is Array) else def
		elif def is Dictionary:
			_repair(d[key], def)


## Same JSON kind: numbers (JSON reads every number as float), texts, or the same Variant type.
static func same_kind(a: Variant, b: Variant) -> bool:
	var ta := typeof(a)
	var tb := typeof(b)
	if ta in [TYPE_INT, TYPE_FLOAT] and tb in [TYPE_INT, TYPE_FLOAT]:
		return true
	if ta in [TYPE_STRING, TYPE_STRING_NAME] and tb in [TYPE_STRING, TYPE_STRING_NAME]:
		return true
	return ta == tb


func _set_aside() -> void:
	DirAccess.remove_absolute(corrupt_path())
	DirAccess.rename_absolute(path, corrupt_path())


func _report(msg: String) -> void:
	push_warning(msg)
	var log: Node = get_node_or_null("/root/ErrorLog") if is_inside_tree() else null
	if log != null and log.has_method(&"log_info"):
		log.call(&"log_info", msg)


## Writes the save. False when the disk refused (the game goes on from memory; see `dirty`).
func save() -> bool:
	data["schema"] = SCHEMA
	if _hold > 0:
		_held = true
		changed.emit()
		return true
	var text := JSON.stringify(data, "  ")
	if text == _last_text and not dirty and FileAccess.file_exists(path):
		changed.emit()
		return true
	var err := SafeFile.write_text(path, text, true)
	if err != OK:
		if last_error == OK:  # once per streak, not once per coin
			_report("Save: cannot write %s (error %d); progress stays in memory and is retried" % [path, err])
		last_error = err
		dirty = true
		changed.emit()
		return false
	last_error = OK
	dirty = false
	_last_text = text
	changed.emit()
	return true


## Several changes that belong together (a job settled: the job, the coins, the statistics, the
## "day after") are written once, at release(), instead of once per value. Calls nest.
## A hold never outlives the frame it was taken in: if release() is not reached (an error in
## between), the end of the frame writes what was collected.
func hold() -> void:
	_hold += 1
	if _hold == 1 and is_inside_tree():
		_end_of_frame_release.call_deferred()


func _end_of_frame_release() -> void:
	if _hold > 0:
		_hold = 1
		release()


func release() -> bool:
	_hold = maxi(_hold - 1, 0)
	if _hold > 0 or not _held:
		return true
	_held = false
	return save()


## Retries a write that failed earlier. Called when the app goes to the background or closes.
func flush() -> bool:
	return save() if dirty else true


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if (dirty or _held) and not data.is_empty():
			_hold = 0  # leaving the screen: whatever was being collected is written now
			_held = false
			save()


func get_value(key_path: String, default: Variant = null) -> Variant:
	var node: Variant = data
	for part in key_path.split("/"):
		if typeof(node) != TYPE_DICTIONARY or not node.has(part):
			return default
		node = node[part]
	# D-136: a value of another kind than the caller expects (damaged file) is not handed out
	if default != null and not same_kind(node, default):
		return default
	return node


func set_value(key_path: String, value: Variant) -> void:
	var parts := key_path.split("/")
	var node: Variant = data
	for i in range(parts.size() - 1):
		if not node.has(parts[i]) or typeof(node[parts[i]]) != TYPE_DICTIONARY:
			node[parts[i]] = {}
		node = node[parts[i]]
	node[parts[parts.size() - 1]] = value
	save()
