extends Control
## Tutorial S1-S3 (ONBOARDING §4): three practice pin locks, chalk on by default.
## Stage state lives in JobRun.tutorial_stage, so returning from the lock scene
## restores it (N-09).


func _ready() -> void:
	Sfx.play_ambience(&"stairwell")
	SafeArea.apply(self)
	$VBox/Title.text = I18n.t(&"tutorial.title")
	_refresh()
	$VBox/StartButton.pressed.connect(_start_stage)


func _refresh() -> void:
	var stage: int = JobRun.tutorial_stage
	var done: bool = Save.get_value("tutorial_done", false)
	if done:
		$VBox/Stage.text = I18n.t(&"tutorial.done")
		$VBox/StartButton.text = I18n.t(&"common.continue")
	else:
		$VBox/Stage.text = I18n.t(&"tutorial.stage").format({"n": stage + 1})
		$VBox/StartButton.text = I18n.t(&"menu.play")


func _start_stage() -> void:
	if Save.get_value("tutorial_done", false):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	JobRun.start_tutorial(JobRun.tutorial_stage)
	get_tree().change_scene_to_file(JobRun.lock_scene_path())
