extends GutTest
## T27 shared fixture. Restore the exact save/settings files as well as singleton state.
## This prevents a GUT run from changing a player's user:// data.

var _old_save: Dictionary
var _old_settings: Dictionary
var _old_job: Dictionary
var _old_mode: StringName
var _old_stage: int
var _old_lives: int
var _old_clean: bool
var _old_tip: int
var _old_locale: String
var _old_paused: bool
var _old_haptics_native: Object
var _old_haptics_continuous: Dictionary
var _had_save: bool
var _had_settings: bool
var _save_bytes: PackedByteArray
var _settings_bytes: PackedByteArray


func before_each() -> void:
	_old_paused = get_tree().paused
	_old_save = Save.data.duplicate(true)
	_old_settings = Settings._cfg.duplicate(true)
	_old_job = JobRun.current_job.duplicate(true)
	_old_mode = JobRun.mode
	_old_stage = JobRun.tutorial_stage
	_old_lives = JobRun.lives
	_old_clean = JobRun.clean
	_old_tip = JobRun.last_tip
	_old_locale = TranslationServer.get_locale()
	_old_haptics_native = Haptics._native
	_old_haptics_continuous = Haptics._continuous.duplicate(true)
	_had_save = FileAccess.file_exists(Save.PATH)
	_had_settings = FileAccess.file_exists(Settings.PATH)
	_save_bytes = FileAccess.get_file_as_bytes(Save.PATH) if _had_save else PackedByteArray()
	_settings_bytes = FileAccess.get_file_as_bytes(Settings.PATH) if _had_settings else PackedByteArray()


func after_each() -> void:
	get_tree().paused = false
	JobRun.current_job = _old_job.duplicate(true)
	JobRun.mode = _old_mode
	JobRun.tutorial_stage = _old_stage
	JobRun.lives = _old_lives
	JobRun.clean = _old_clean
	JobRun.last_tip = _old_tip
	Haptics._continuous = _old_haptics_continuous.duplicate(true)
	Haptics._native = _old_haptics_native
	Save.data = _old_save.duplicate(true)
	Settings._cfg = _old_settings.duplicate(true)
	_restore_file(Save.PATH, _had_save, _save_bytes)
	_restore_file(Settings.PATH, _had_settings, _settings_bytes)
	Settings.changed.emit()  # also restores UiA11y theme sizes
	I18n.apply_language(_old_locale)
	get_tree().paused = _old_paused


func _restore_file(path: String, existed: bool, original: PackedByteArray) -> void:
	if not existed:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_buffer(original)


func t27_scene(path: String) -> Node:
	var scene: Node = load(path).instantiate()
	add_child_autofree(scene)
	return scene


func t27_job(jid: String = "job.refuse_t27_fixture") -> Dictionary:
	return {"id": jid, "family": "pin_tumbler", "tier": 2,
		"reward_coins": 0, "cards": [], "i18n": {"title": "jobs.title"}}
