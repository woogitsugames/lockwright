extends Node
## Settings singleton. Persists to user://settings.cfg.
## All player-facing text goes through I18n, never hardcoded here.

signal changed

const PATH := "user://settings.cfg"

const DEFAULTS := {
	"haptics_enabled": true,
	"haptics_intensity": 1.0,
	"volume_master": 1.0,
	"volume_sfx": 1.0,
	"volume_ambience": 0.8,
	"language": "",  # empty = follow system
	"dark_mode_assist": false,
	"reading_aid": false,
	"wide_windows": false,
	"text_scale": 1.0,
	"reduce_motion": false,
	"continuous_resistance": true,
}

var _cfg := {}


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	_cfg = DEFAULTS.duplicate(true)
	var file := ConfigFile.new()
	if file.load(PATH) == OK:
		for key in DEFAULTS:
			if file.has_section_key("settings", key):
				_cfg[key] = file.get_value("settings", key)


func save_settings() -> void:
	var file := ConfigFile.new()
	for key in _cfg:
		file.set_value("settings", key, _cfg[key])
	file.save(PATH)


func get_value(key: StringName, default: Variant = null) -> Variant:
	var d: Variant = DEFAULTS.get(key, default)
	return _cfg.get(key, d)


func set_value(key: StringName, value: Variant) -> void:
	if not DEFAULTS.has(key):
		push_warning("Settings: unknown key %s" % key)
		return
	_cfg[key] = value
	save_settings()
	changed.emit()


func haptics_enabled() -> bool:
	return bool(_cfg.get("haptics_enabled", true))


func haptics_intensity() -> float:
	return clampf(float(_cfg.get("haptics_intensity", 1.0)), 0.0, 1.0)


func language() -> String:
	var lang: String = _cfg.get("language", "")
	if lang == "":
		return I18n.system_language()
	return lang
