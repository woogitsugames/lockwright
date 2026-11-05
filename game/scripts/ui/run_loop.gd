extends Control
## Endless run (Tryb Ciągły, PROGRESSION §2): generated locks with the tier curve
## 1 + 1.2*ln(1+n)*skill, 3 lives, rubber band after 2 breaks in a row.
## N-64: the run's state is RunState (static), so it survives this scene being reloaded
## after every lock; Events records each lock's result before routing back here.


func _ready() -> void:
	$VBox/Title.text = I18n.t(&"run.title")
	$VBox/StartButton.custom_minimum_size = Vector2(0, 48)
	if RunState.finished:
		_show_finished()
		return
	$VBox/StartButton.text = I18n.t(&"menu.play")
	$VBox/StartButton.pressed.connect(_next_lock)
	_refresh()


func _refresh() -> void:
	var info := I18n.t(&"run.lock_n").format({"n": RunState.n + 1}) + " · " + I18n.t(&"run.lives_left") + ": " + str(RunState.lives)
	if RunState.breaks_in_row >= 2:
		info += "\n" + I18n.t(&"run.rubber_band")
	$VBox/Info.text = info


func _next_lock() -> void:
	JobRun.mode = &"run"
	JobRun.current_job = RunState.next_job()
	JobRun.clean = true
	get_tree().change_scene_to_file(JobRun.lock_scene_path())


func _show_finished() -> void:
	$VBox/Title.text = I18n.t(&"run.finished").format({"n": RunState.coins})
	$VBox/Info.text = ""
	$VBox/StartButton.text = I18n.t(&"common.continue")
	$VBox/StartButton.pressed.connect(func() -> void:
		RunState.reset()
		JobRun.current_job = {}
		JobRun.mode = &"job"
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
