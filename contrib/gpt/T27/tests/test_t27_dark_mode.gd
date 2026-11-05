extends "res://tests/gut/t27_fixture.gd"
## Checks both the legacy lighting assist and the photoreal in-the-dark mode.


## Checks the legacy dark mode dims ambient light and switches off the key light.
func test_legacy_dark_mode_reduces_light() -> void:
	var scene := t27_scene("res://scenes/lock.tscn")
	scene._on_dark_mode_toggled(true)
	var env: Environment = scene.get_node("WorldEnvironment").environment
	assert_true(scene._dark_mode)
	assert_lt(env.ambient_light_energy, 0.1)
	assert_false(scene.get_node("KeyLight").visible)


## Checks leaving the legacy dark mode restores the pre-dark light values.
func test_legacy_dark_mode_can_be_reversed() -> void:
	var scene := t27_scene("res://scenes/lock.tscn")
	scene._on_dark_mode_toggled(true)
	scene._on_dark_mode_toggled(false)
	var env: Environment = scene.get_node("WorldEnvironment").environment
	assert_false(scene._dark_mode)
	assert_almost_eq(env.ambient_light_energy, 0.6, 0.001)
	assert_true(scene.get_node("KeyLight").visible)


## Checks the pause-menu dark-mode control toggles the photoreal lock view.
func test_photoreal_dark_mode_toggles_from_pause() -> void:
	var scene := t27_scene("res://scenes/photoreal/lock_photoreal.tscn")
	var view: LockPhotorealView = scene.get_node("ViewLayer/View")
	scene._on_pause()
	scene._on_dark()
	assert_true(view.dark)
	assert_false(scene._paused)
	assert_false(get_tree().paused)


## Checks photoreal darkness hides the roll without disabling the simulated lock.
func test_photoreal_dark_mode_hides_tray_but_not_session() -> void:
	var scene := t27_scene("res://scenes/photoreal/lock_photoreal.tscn")
	var view: LockPhotorealView = scene.get_node("ViewLayer/View")
	var before: Dictionary = scene.session.describe().duplicate(true)
	view.set_dark(true)
	assert_false(view._tray.visible)
	assert_not_null(scene.session)
	assert_eq(scene.session.describe(), before)


## Checks dark mode can be switched off again and restores its visual layer.
func test_photoreal_dark_mode_can_be_reversed() -> void:
	var scene := t27_scene("res://scenes/photoreal/lock_photoreal.tscn")
	var view: LockPhotorealView = scene.get_node("ViewLayer/View")
	view.set_dark(true)
	view.set_dark(false)
	assert_false(view.dark)
	assert_true(view._tray.visible)


## Checks the separate accessibility dark-mode assist option is persisted.
func test_dark_mode_assist_setting_survives_reload() -> void:
	Settings.set_value("dark_mode_assist", true)
	Settings.load_settings()
	assert_true(Settings.get_value("dark_mode_assist"))
