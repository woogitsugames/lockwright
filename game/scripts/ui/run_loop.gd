extends Control
## Endless run (Tryb Ciągły, PROGRESSION §2): generated locks with the tier curve
## 1 + 1.2*ln(1+n)*skill, 3 lives, rubber band after 2 breaks in a row.
## N-64: the run's state is RunState (static), so it survives this scene being reloaded
## after every lock; Events records each lock's result before routing back here.

## T59: dispatcher lines between locks (run.dispatch.01..NN), one per lock after the first.
const DISPATCH_COUNT := 15


## VA-06: the shift screen was a 380 dp column of three centred lines on flat brown. Now: a night
## stairwell photo, a back plate like every other screen, and the dispatcher's note on dark paper in
## the lower (thumb) part of the screen, inside the safe area; landscape caps the column at 640 dp.
const BG := "res://assets/ui/gpt/arrival/02_apartment_evening.jpg"
var _paper: PanelContainer
var _back: Button


func _dress() -> void:
	ScreenFrame.backdrop(self, BG, 0.4)
	_paper = PanelContainer.new()
	_paper.name = "Paper"
	_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_paper)
	move_child(_paper, $VBox.get_index())
	_back = Button.new()
	_back.name = "BackButton"
	_back.text = "‹ " + I18n.t(&"common.back")
	_back.custom_minimum_size = Vector2(112, 48)
	_back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	add_child(_back)
	var title := $VBox/Title as Label
	title.theme_type_variation = &"Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	($VBox/Info as Label).add_theme_font_size_override("font_size", UiA11y.fs(18))
	$VBox.add_theme_constant_override("separation", 14)
	resized.connect(_place)
	$VBox.resized.connect(_fit_paper)
	_place()


func _place() -> void:
	var vp := get_viewport_rect().size
	var i := ScreenFrame.insets(self)
	_back.position = Vector2(i.x + ScreenFrame.SIDE, i.y + 8.0)
	var pad := 16.0
	var left := i.x + ScreenFrame.SIDE + pad
	var right := i.z + ScreenFrame.SIDE + pad
	var w := minf(vp.x - left - right, ScreenFrame.MAX_COLUMN - 2.0 * pad)
	var box := $VBox as Control
	box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.offset_left = (vp.x - w) * 0.5
	box.offset_right = -(vp.x - w) * 0.5
	box.offset_bottom = -(i.w + 24.0 + pad)
	box.offset_top = box.offset_bottom - box.get_combined_minimum_size().y
	_fit_paper.call_deferred()


func _fit_paper() -> void:
	var pad := 16.0
	var box := $VBox as Control
	_paper.position = box.position - Vector2(pad, pad)
	_paper.size = box.size + Vector2(2.0 * pad, 2.0 * pad)


func _ready() -> void:
	_dress()
	$VBox/Title.text = I18n.t(&"run.title")
	$VBox/StartButton.custom_minimum_size = Vector2(0, 48)
	$VBox/Info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # dispatcher line + counters (DE/FR are long)
	ScreenFrame.wire_sounds(self)
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
