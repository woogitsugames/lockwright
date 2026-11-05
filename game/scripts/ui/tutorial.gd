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
	$BackButton.text = I18n.t(&"common.back")
	$BackButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))


# G11 master's cards: tutorial stage S1-S3 -> first card of the stage (PL/EN, clean with reading aid)
const STAGE_FIRST_CARD := [1, 7, 10]


func _add_card(stage: int) -> void:
	var lang := "pl" if Settings.language() == "pl" else "en"
	if Save.get_value("reading_aid", false):
		lang = "clean"
	var n: int = STAGE_FIRST_CARD[clampi(stage, 0, 2)]
	var tex := load("res://assets/ui/gpt/tutorial/g11-%02d-%s.png" % [n, lang])
	if tex == null:
		return
	var card := TextureRect.new()
	card.texture = tex
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	card.custom_minimum_size = Vector2(0, 220)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	$VBox.add_child(card)
	var stamp_lang := "pl" if Settings.language() == "pl" else "en"
	var stex := load("res://assets/ui/gpt/tutorial/stamp-g11-stamp-%s.png" % stamp_lang)
	if stex != null:
		var stamp := TextureRect.new()
		stamp.texture = stex
		stamp.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stamp.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		stamp.custom_minimum_size = Vector2(96, 96)
		stamp.position = Vector2(24, 24)
		stamp.size = Vector2(96, 96)
		card.add_child(stamp)


func _refresh() -> void:
	var stage: int = JobRun.tutorial_stage
	var done: bool = Save.get_value("tutorial_done", false)
	if done:
		$VBox/Stage.text = I18n.t(&"tutorial.done")
		$VBox/StartButton.text = I18n.t(&"common.continue")
	else:
		$VBox/Stage.text = I18n.t(&"tutorial.stage").format({"n": stage + 1})
		$VBox/StartButton.text = I18n.t(&"tutorial.start")
		_add_card(stage)


func _start_stage() -> void:
	if Save.get_value("tutorial_done", false):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	JobRun.start_tutorial(JobRun.tutorial_stage)
	get_tree().change_scene_to_file(JobRun.lock_scene_path())
