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
	"volume_music": 0.8,
	"volume_voice": 1.0,  # D-57: "Voices" slider (Voice bus: dialogue lines + vocalizations)
	"language": "",  # empty = follow system
	"dark_mode_assist": false,
	"reading_aid": false,
	"wide_windows": false,
	"text_scale": 1.0,
	"reduce_motion": false,
	"swap_thumbs": false,           # HUD.md §9.2 left-handed: tension right, pick left (D-90)
	"announce_lock_events": true,   # HUD.md §9.2: screen reader announces lock states (D-90)
	"sound_captions": false,        # HUD.md §9.1 (3): caption strip for gameplay sounds (D-90)
	"continuous_resistance": true,
	"calibrated": false,
	"calibration": "",  # "" | "two" | "one" | "none" (TECH.md §2.3 first-run test)
	"quality_profile": "auto",  # "auto" | "high" | "medium" | "low"
	"quality_auto": "high",     # last auto-picked profile (task 7)
	"auto_tension": true,       # D-52: tension held by the game; one thumb picks
	"control_chosen": false,    # D-52: first-launch control choice done
	"voice_download": "auto",   # D-62/D-100: game-language voice pack: "auto" (old "ask" = auto) | "manual"
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
	# T03: DE tylko za flagą deweloperską (Save "dev_mode"); T41: FR/ES tak samo
	if lang in ["de", "fr", "es"] and not Save.get_value("dev_mode", false):
		return I18n.system_language()
	return lang
