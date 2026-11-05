extends Control
## Tutorial S1-S3 (ONBOARDING §4): three practice pin locks in the bench vise,
## chalk layer on by default; then back to the menu and tutorial_done is saved.

var _stage := 0


func _ready() -> void:
	$VBox/Title.text = I18n.t(&"tutorial.title")
	$VBox/Stage.text = I18n.t(&"tutorial.stage").format({"n": _stage + 1})
	$VBox/StartButton.text = I18n.t(&"menu.play")
	$VBox/StartButton.custom_minimum_size = Vector2(0, 48)
	$VBox/StartButton.pressed.connect(_start_stage)
	$VBox/DoneLabel.text = ""


func _start_stage() -> void:
	JobRun.current_job = {"id": "tutorial.s%d" % (_stage + 1), "family": "pin_tumbler", "tier": 1, "reward_coins": 0, "i18n": {}}
	get_tree().change_scene_to_file("res://scenes/lock.tscn")


func on_lock_finished(opened: bool) -> void:
	# called via Events from the lock scene when a tutorial stage finishes
	_stage += 1
	if _stage >= 3:
		Save.set_value("tutorial_done", true)
		$VBox/DoneLabel.text = I18n.t(&"tutorial.done")
		$VBox/StartButton.text = I18n.t(&"common.continue")
		$VBox/StartButton.pressed.disconnect(_start_stage)
		$VBox/StartButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	else:
		$VBox/Stage.text = I18n.t(&"tutorial.stage").format({"n": _stage + 1})
		$VBox/StartButton.pressed.disconnect(_start_stage)
		$VBox/StartButton.pressed.connect(_start_stage)
