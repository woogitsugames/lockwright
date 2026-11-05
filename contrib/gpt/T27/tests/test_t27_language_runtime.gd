extends "res://tests/gut/t27_fixture.gd"
## Live PL/EN locale changes, fallback, and screen refresh behavior.


## Checks Settings broadcasts an immediate PL -> EN -> PL change to I18n.
func test_locale_changes_without_restarting_game() -> void:
	Settings.set_value("language", "pl")
	assert_eq(I18n.current_language(), "pl")
	Settings.set_value("language", "en")
	assert_eq(I18n.current_language(), "en")
	Settings.set_value("language", "pl")
	assert_eq(I18n.current_language(), "pl")


## Checks two locale-specific labels stay translated after a live switch.
func test_labels_use_new_locale_immediately() -> void:
	Settings.set_value("language", "pl")
	var pl: String = I18n.t(&"menu.play")
	Settings.set_value("language", "en")
	var en: String = I18n.t(&"menu.play")
	assert_ne(pl, "menu.play")
	assert_ne(en, "menu.play")
	assert_ne(pl, en)


## Checks an already-mounted main menu listens for language_changed.
func test_open_main_menu_relabels_on_language_change() -> void:
	Settings.set_value("language", "pl")
	var scene := t27_scene("res://scenes/main_menu.tscn")
	Settings.set_value("language", "en")
	assert_eq(scene.get_node("VBox/PlayButton").text, I18n.t(&"menu.play"))


## Checks an already-mounted settings screen refreshes all accessible labels.
func test_open_settings_screen_relabels_on_language_change() -> void:
	Settings.set_value("language", "en")
	var scene := t27_scene("res://scenes/settings.tscn")
	Settings.set_value("language", "pl")
	assert_eq(scene.get_node("Scroll/VBox/HapticsCheck").text, I18n.t(&"settings.haptics_enabled"))
	assert_eq(scene.get_node("Scroll/VBox/TextScaleLabel").text, I18n.t(&"settings.text_scale"))


## Checks the player's explicit locale persists in settings.cfg.
func test_locale_setting_survives_reload() -> void:
	Settings.set_value("language", "pl")
	Settings.load_settings()
	assert_eq(Settings.language(), "pl")


## Checks unsupported locales fall back to English rather than a raw key.
func test_unsupported_locale_falls_back_to_en() -> void:
	I18n.apply_language("zz-T27")
	assert_eq(I18n.current_language(), "en")
	assert_ne(I18n.t(&"menu.play"), "menu.play")


## REGRESSION: verification is gameplay, so its existing labels must refresh live.
## Currently expected to fail: job_verify.gd does not listen for language_changed.
func test_open_verification_relabels_on_language_change() -> void:
	Settings.set_value("language", "pl")
	JobRun.start(t27_job())
	var scene := t27_scene("res://scenes/job_verify.tscn")
	Settings.set_value("language", "en")
	assert_eq(scene.get_node("VBox/RefuseButton").text, I18n.t(&"job.refuse"),
		"the verification refusal action must follow the selected locale")


## REGRESSION: the legacy lock pause menu is gameplay UI, not static boot text.
## Currently expected to fail: lock_scene.gd fills labels only in _ready().
func test_legacy_pause_relabels_on_language_change() -> void:
	Settings.set_value("language", "pl")
	var scene := t27_scene("res://scenes/lock.tscn")
	Settings.set_value("language", "en")
	assert_eq(scene.get_node("UILayer/PauseMenu/VBox/ResumeButton").text,
		I18n.t(&"pause.resume"), "pause menu must follow the active language")
