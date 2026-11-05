extends "res://tests/gut/t27_fixture.gd"
## Lock interruption tests: legacy and photoreal implementations, including regressions.


## Checks that pausing the legacy lock freezes the SceneTree and exposes its cover.
func test_legacy_pause_sets_tree_and_cover() -> void:
	var scene := t27_scene("res://scenes/lock.tscn")
	scene._on_pause_pressed()
	assert_true(get_tree().paused)
	assert_true(scene._paused)
	assert_true(scene.get_node("UILayer/PauseMenu").visible)
	scene._on_resume_pressed()


## Checks that resuming the legacy lock clears both pause states and the cover.
func test_legacy_resume_clears_pause() -> void:
	var scene := t27_scene("res://scenes/lock.tscn")
	scene._on_pause_pressed()
	scene._on_resume_pressed()
	assert_false(get_tree().paused)
	assert_false(scene._paused)
	assert_false(scene.get_node("UILayer/PauseMenu").visible)


## Checks automatic pause after application/window focus is lost (R-03).
func test_legacy_focus_loss_auto_pauses() -> void:
	var scene := t27_scene("res://scenes/lock.tscn")
	scene._on_focus_lost()
	assert_true(scene._paused)
	assert_true(get_tree().paused)
	scene._on_resume_pressed()


## Checks that repeated background signals do not accidentally resume the lock.
func test_legacy_repeated_focus_loss_is_idempotent() -> void:
	var scene := t27_scene("res://scenes/lock.tscn")
	scene._on_focus_lost()
	scene._on_focus_lost()
	assert_true(scene._paused)
	assert_true(scene.get_node("UILayer/PauseMenu").visible)
	scene._on_resume_pressed()


## Checks that manually invoking a physics tick during pause cannot move the lock.
func test_legacy_pause_does_not_advance_session() -> void:
	var scene := t27_scene("res://scenes/lock.tscn")
	scene._on_pause_pressed()
	var snapshot: Dictionary = scene.session.describe().duplicate(true)
	scene._physics_process(1.0 / 120.0)
	assert_eq(scene.session.describe(), snapshot)
	scene._on_resume_pressed()


## Checks the photoreal pause cover and the resume path, without changing scenes.
func test_photoreal_pause_resume_roundtrip() -> void:
	var scene := t27_scene("res://scenes/photoreal/lock_photoreal.tscn")
	scene._on_pause()
	assert_true(scene._paused)
	assert_true(scene.get_node("UILayer/PauseCover").visible)
	assert_true(get_tree().paused)
	scene._on_resume()
	assert_false(scene._paused)
	assert_false(scene.get_node("UILayer/PauseCover").visible)
	assert_false(get_tree().paused)


## Checks that photoreal physics does not advance the session while paused.
func test_photoreal_pause_does_not_advance_session() -> void:
	var scene := t27_scene("res://scenes/photoreal/lock_photoreal.tscn")
	scene._on_pause()
	var snapshot: Dictionary = scene.session.describe().duplicate(true)
	scene._physics_process(1.0 / 120.0)
	assert_eq(scene.session.describe(), snapshot)
	scene._on_resume()


## REGRESSION: the main photoreal controller must subscribe to background events.
## Currently expected to fail: lock_photoreal.gd has no focus-exited handler.
func test_photoreal_background_event_is_connected() -> void:
	var scene := t27_scene("res://scenes/photoreal/lock_photoreal.tscn")
	assert_true(get_tree().root.focus_exited.is_connected(Callable(scene, "_on_focus_lost")),
		"R-03: active photoreal lock must pause when the app goes to background")
