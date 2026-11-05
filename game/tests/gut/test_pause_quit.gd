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
