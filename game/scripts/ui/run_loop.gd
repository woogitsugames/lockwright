extends Control
## Endless run (Tryb Ciągły, PROGRESSION §2): generated locks with the tier curve
## 1 + 1.2*ln(1+n)*skill, 3 lives, rubber band after 2 breaks in a row.
## N-64: the run's state is RunState (static), so it survives this scene being reloaded
## after every lock; Events records each lock's result before routing back here.

## T59: dispatcher lines between locks (run.dispatch.01..NN), one per lock after the first.
const DISPATCH_COUNT := 15


func _ready() -> void:
	$VBox/Title.text = I18n.t(&"run.title")
	$VBox/StartButton.custom_minimum_size = Vector2(0, 48)
	$VBox/Info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # dispatcher line + counters (DE/FR are long)
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
	elif RunState.n > 0:
		info = dispatch_line(RunState.n) + "\n" + info
	$VBox/Info.text = info


## Dispatcher line before lock n+1 (n >= 1): a fixed stride through the list, so consecutive
## locks never repeat a line and a run of 15 locks hears each one once.
static func dispatch_line(n: int) -> String:
	var i := ((n - 1) * 7) % DISPATCH_COUNT + 1
	return I18n.t(StringName("run.dispatch.%02d" % i))


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
