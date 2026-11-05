extends Control
## Endless run (Tryb Ciągły, PROGRESSION §2): generated locks with the tier curve
## 1 + 1.2*ln(1+n)*skill, 3 lives, workshop stop every 5 locks, rubber band after 2 breaks.

var _n := 0  # locks in this run
var _breaks := 0
var _last_breaks := 0


func _ready() -> void:
	$VBox/Title.text = I18n.t(&"run.title")
	_refresh()
	$VBox/StartButton.text = I18n.t(&"menu.play")
	$VBox/StartButton.custom_minimum_size = Vector2(0, 48)
	$VBox/StartButton.pressed.connect(_next_lock)
	$VBox/Info.text = I18n.t(&"run.lock_n").format({"n": _n + 1})


func _tier_for(n: int) -> int:
	# progression.json tier_curve: 1 + 1.2*ln(1+n)*skill, rubber band -1 after 2 breaks
	var skill := 1.0
	var t := 1.0 + 1.2 * log(1.0 + n) * skill
	if _breaks - _last_breaks >= 2:
		t -= 1.0
	return clampi(int(t), 1, 6)


func _next_lock() -> void:
	var tier := _tier_for(_n)
	var families := JobRun.IMPLEMENTED
	var fam: StringName = families[_n % families.size()]
	JobRun.mode = &"run"
	JobRun.current_job = {"id": "run.%d" % _n, "family": String(fam), "tier": tier, "reward_coins": 10 * tier, "i18n": {}}
	get_tree().change_scene_to_file(JobRun.lock_scene_path())


func _refresh() -> void:
	$VBox/Info.text = I18n.t(&"run.lock_n").format({"n": _n + 1}) + " · " + I18n.t(&"run.lives_left") + ": " + str(JobRun.lives)


func on_lock_finished(opened: bool) -> void:
	_n += 1
	if not opened:
		_breaks += 1
		JobRun.lives -= 1
		if JobRun.lives <= 0:
			_finish_run()
			return
	Save.set_value("coins", Save.get_value("coins", 0) + 10 * _tier_for(_n))
	_refresh()


func _finish_run() -> void:
	Save.set_value("stats/runs_finished", Save.get_value("stats/runs_finished", 0) + 1)
	$VBox/Title.text = I18n.t(&"run.finished").format({"n": Save.get_value("coins", 0)})
	$VBox/StartButton.text = I18n.t(&"common.continue")
	$VBox/StartButton.pressed.disconnect(_next_lock)
	$VBox/StartButton.pressed.connect(func() -> void:
		_n = 0
		_breaks = 0
		JobRun.lives = 3
		JobRun.current_job = {}
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
