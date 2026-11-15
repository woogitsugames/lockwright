extends GutTest
## N-31 / GEM3 BUG-03: leaving the lock through the pause menu must clear
## get_tree().paused, otherwise the main menu stays frozen.

func test_quit_from_pause_clears_paused() -> void:
	var scene: Node = load("res://scenes/lock.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().paused = true
	scene.get_node("UILayer/PauseMenu/VBox/QuitButton").pressed.emit()
	assert_false(get_tree().paused, "paused must be false after Quit from the pause menu")
	get_tree().paused = false
	# D-133: Quit really changes the scene, so a MainMenu became the tree's current scene and stayed
	# for every later test script (and, once something took it out of the tree, answered settings
	# changes from outside it). The test frees what it opened.
	await get_tree().process_frame
	await get_tree().process_frame
	var menu := get_tree().current_scene
	assert_not_null(menu, "Quit opens the main menu")
	if menu != null:
		assert_eq(menu.scene_file_path, "res://scenes/main_menu.tscn")
		menu.free()
	assert_null(get_tree().current_scene, "no scene left behind for the next test script")
