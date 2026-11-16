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
	"sound_captions": false,
	"tension_lock": false,          # HUD.md §9.2: double tap latches T, single tap lets go (D-107)
	"text_scale_system": true,      # D-107: in-game text size follows the system font scale (Android fontScale, iOS Dynamic Type D-113)        # HUD.md §9.1 (3): caption strip for gameplay sounds (D-90)
	"continuous_resistance": true,
	"calibrated": false,
	"calibration": "",  # "" | "two" | "one" | "none" (TECH.md §2.3 first-run test)
	"quality_profile": "auto",  # "auto" | "high" | "medium" | "low"
	"quality_auto": "high",     # last auto-picked profile (task 7)
	"auto_tension": true,       # D-52: tension held by the game; one thumb picks
	"control_chosen": false,    # D-52: first-launch control choice done
	"voice_download": "auto",   # D-62/D-100: game-language voice pack: "auto" (old "ask" = auto) | "manual"
	"adpf_hint": false,        # D-91 FrameHint opt-in, no UI (D-121: the key was read but not known here, so a settings file could not turn it on)
}

## D-121: names a setting had before, read once from an old settings.cfg when the current key is
## not there yet. "chalk_layer" is what the lock screen asked for while the Settings screen wrote
## "reading_aid" (the "Chalk markings" switch); the switch and the lock now share "reading_aid".
const LEGACY_KEYS := {"chalk_layer": "reading_aid"}

var _cfg := {}
## Where save_settings() writes (tests point a private Settings node at their own folder).
var file_path := PATH
## True while memory holds settings the disk does not (the last write failed).
var dirty := false


func _ready() -> void:
	load_settings()


func load_settings(from: String = "") -> void:
	var path := from if from != "" else file_path
	_cfg = DEFAULTS.duplicate(true)
	SafeFile.drop_stale_tmp(path)
	var file := ConfigFile.new()
	var err := file.load(path)
	if (err != OK or not file.has_section("settings")) and FileAccess.file_exists(path + SafeFile.BACKUP_SUFFIX):
		# D-136: settings.cfg missing, empty, cut or unreadable -> the copy from before the last write
		file = ConfigFile.new()
		err = file.load(path + SafeFile.BACKUP_SUFFIX)
	if err == OK:
		for key in DEFAULTS:
			if file.has_section_key("settings", key) and _same_kind(file.get_value("settings", key), DEFAULTS[key]):
				_cfg[key] = file.get_value("settings", key)
		for old: String in LEGACY_KEYS:
			var key: String = LEGACY_KEYS[old]
			if file.has_section_key("settings", old) and not file.has_section_key("settings", key) \
					and typeof(file.get_value("settings", old)) == typeof(DEFAULTS[key]):
				_cfg[key] = file.get_value("settings", old)
		# D-107: a player who already picked a text size keeps it (the system size is only a default)
		if not file.has_section_key("settings", "text_scale_system") and file.has_section_key("settings", "text_scale") \
				and _same_kind(file.get_value("settings", "text_scale"), 1.0):
			_cfg["text_scale_system"] = is_equal_approx(float(file.get_value("settings", "text_scale")), 1.0)


## D-136: a value of another kind than the setting's default (a damaged or hand-edited file) is
## ignored; the default stays. Whole and fractional numbers count as one kind.
static func _same_kind(a: Variant, b: Variant) -> bool:
	var ta := typeof(a)
	var tb := typeof(b)
	if ta in [TYPE_INT, TYPE_FLOAT] and tb in [TYPE_INT, TYPE_FLOAT]:
		return true
	return ta == tb


## D-136: replaced atomically (temp file + rename, the previous file stays as settings.cfg.bak), so a
## full disk or a kill in the middle of the write cannot leave an empty settings file. False when
## the disk refused: the settings stay in memory and are written with the next change.
func save_settings() -> bool:
	var file := ConfigFile.new()
	for key in _cfg:
		file.set_value("settings", key, _cfg[key])
	dirty = SafeFile.write_text(file_path, file.encode_to_text(), true) != OK
	return not dirty


func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST) and dirty:
		save_settings()


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
