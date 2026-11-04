extends Control
## Boot scene: applies language, then moves to the main menu.


func _ready() -> void:
	I18n.apply_language(Settings.language())
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
