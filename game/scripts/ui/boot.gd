extends Control
## Boot: applies language, shows the one-time "this is a game, not a course" note
## on first launch (ONBOARDING §3.3), then the short first-run haptics+audio
## calibration (TECH.md §2.3), then the main menu.

@onready var notice: PanelContainer = $NoticePanel
@onready var notice_label: Label = $NoticePanel/VBox/Label
@onready var calib: PanelContainer = $CalibPanel
@onready var calib_label: Label = $CalibPanel/VBox/Question
@onready var calib_two: Button = $CalibPanel/VBox/TwoButton
@onready var calib_one: Button = $CalibPanel/VBox/OneButton
@onready var calib_none: Button = $CalibPanel/VBox/NoneButton
@onready var calib_skip: Button = $CalibPanel/VBox/SkipButton


func _ready() -> void:
	I18n.apply_language(Settings.language())
	notice_label.text = I18n.t(&"about.notice")
	var first_run: bool = not Save.get_value("seen_notice", false)
	notice.visible = first_run
	if first_run:
		Save.set_value("seen_notice", true)
	await get_tree().create_timer(0.1).timeout
	if notice.visible:
		await get_tree().create_timer(3.0).timeout  # the card stays readable, never blocks
		notice.visible = false
	if first_run and not Settings.get_value("calibrated", false):
		await _run_calibration()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _run_calibration() -> void:
	# TECH.md §2.3: two `set` transients 120 ms apart + the matching sound; player answers.
	calib_label.text = I18n.t(&"boot.calib_title")
	calib_two.text = I18n.t(&"boot.calib_two")
	calib_one.text = I18n.t(&"boot.calib_one")
	calib_none.text = I18n.t(&"boot.calib_none")
	calib_skip.text = I18n.t(&"boot.calib_skip")
	calib.visible = true
	var answered := false
	var done := func(answer: String) -> void:
		if answered:
			return
		answered = true
		Settings.set_value("calibration", answer)
		Settings.set_value("calibrated", true)
		match answer:
			"two":
				Settings.set_value("haptics_intensity", 1.0)
				Settings.set_value("haptics_enabled", true)
			"one":
				Settings.set_value("haptics_intensity", 0.6)  # blurred ERM: lower tier feel
				Settings.set_value("haptics_enabled", true)
			"none":
				Settings.set_value("haptics_enabled", false)  # audio + visuals remain
		calib.visible = false
	calib_two.pressed.connect(func() -> void: done.call("two"))
	calib_one.pressed.connect(func() -> void: done.call("one"))
	calib_none.pressed.connect(func() -> void: done.call("none"))
	calib_skip.pressed.connect(func() -> void: done.call("two"))
	Haptics.play(&"set", 0.9, &"brass")
	Sfx.play(&"set", &"brass")
	await get_tree().create_timer(0.12).timeout
	Haptics.play(&"set", 0.9, &"brass")
	Sfx.play(&"set", &"brass")
	await get_tree().create_timer(6.0).timeout  # skippable by timeout too
	if not answered:
		done.call("two")
