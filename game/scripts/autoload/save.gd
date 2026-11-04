extends Node
## Save singleton. Versioned JSON at user://save.json with migrations.
## Stores meta progress only, never in-lock simulation state (ARCHITECTURE.md §6).

signal changed

const PATH := "user://save.json"
const SCHEMA := "save/1"

const DEFAULTS := {
	"coins": 0,
	"tools": {"tw_angle": {"owned": true, "integrity": 100}, "pk_hook": {"owned": true, "integrity": 100}, "pk_rake": {"owned": true, "integrity": 100}},
	"showcase_seen": [],
	"settings_haptics_calibrated": false,
	"stats": {"locks_opened": 0, "locks_broken": 0, "runs_finished": 0},
}

var data: Dictionary = {}


func _ready() -> void:
	load_save()


func load_save() -> void:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		data = DEFAULTS.duplicate(true)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		data = DEFAULTS.duplicate(true)
		return
	var d: Dictionary = parsed
	if d.get("schema", "") != SCHEMA:
		d = migrate(d)
	data = DEFAULTS.duplicate(true)
	_merge(data, d)


func migrate(d: Dictionary) -> Dictionary:
	# One-way migrations, oldest first. Unknown schemas reset to defaults.
	var schema: String = d.get("schema", "")
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


func save() -> void:
	data["schema"] = SCHEMA
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_error("Save: cannot open %s for writing" % PATH)
		return
	file.store_string(JSON.stringify(data, "  "))
	changed.emit()


func get_value(path: String, default: Variant = null) -> Variant:
	var node: Variant = data
	for part in path.split("/"):
		if typeof(node) != TYPE_DICTIONARY or not node.has(part):
			return default
		node = node[part]
	return node


func set_value(path: String, value: Variant) -> void:
	var parts := path.split("/")
	var node: Variant = data
	for i in range(parts.size() - 1):
		if not node.has(parts[i]) or typeof(node[parts[i]]) != TYPE_DICTIONARY:
			node[parts[i]] = {}
		node = node[parts[i]]
	node[parts[parts.size() - 1]] = value
	save()
