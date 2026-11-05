extends Control
## Main menu. Buttons are >= 48 dp; all text via i18n.

@onready var play_button: Button = $VBox/PlayButton
@onready var jobs_button: Button = $VBox/JobsButton
@onready var workshop_button: Button = $VBox/WorkshopButton
@onready var showcase_button: Button = $VBox/ShowcaseButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var about_button: Button = $VBox/AboutButton
@onready var title_label: Label = $VBox/Title
@onready var tip_label: Label = $VBox/TipLabel


func _show_tip() -> void:
	# task 10: a random master's tip (contrib/gpt/T10 tips.csv -> i18n tip.* keys)
	var keys: Array = TranslationServer.get_translation_object("en").get_message_list() if false else []
	for k in I18n.all_keys():
		if String(k).begins_with("tip."):
			keys.append(k)
	if keys.is_empty():
		tip_label.text = ""
		return
	tip_label.text = I18n.t(keys[randi() % keys.size()])


func _ready() -> void:
	Sfx.play_ambience(&"night_timer")
	Sfx.play_music(&"main_theme")
	SafeArea.apply(self)
	_show_tip()  # task 10: master's tip on the loading/menu screen
	title_label.text = I18n.t(&"menu.title")
	play_button.text = I18n.t(&"menu.play")
	jobs_button.text = I18n.t(&"menu.jobs")
	workshop_button.text = I18n.t(&"menu.workshop")
	showcase_button.text = I18n.t(&"menu.showcase")
	settings_button.text = I18n.t(&"menu.settings")
	about_button.text = I18n.t(&"menu.about")
	play_button.pressed.connect(func() -> void:
		if Save.get_value("tutorial_done", false):
			get_tree().change_scene_to_file(JobRun.lock_scene_path())
		else:
			get_tree().change_scene_to_file("res://scenes/tutorial.tscn"))
	jobs_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
	workshop_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/workshop.tscn"))
	showcase_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/showcase.tscn"))
	settings_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/settings.tscn"))
	about_button.pressed.connect(func() -> void: $AboutPanel.visible = true)
	$AboutPanel/VBox/CloseButton.text = I18n.t(&"common.close")
	$AboutPanel/VBox/Notice.text = I18n.t(&"about.notice")
	$AboutPanel/VBox/CloseButton.pressed.connect(func() -> void: $AboutPanel.visible = false)
	$AboutPanel/VBox/Notice.gui_input.connect(_on_about_input)  # 5 taps = dev flag "po premierze" (task 11)
	$AboutPanel/VBox/Licenses.text = I18n.t(&"about.licenses")
	I18n.language_changed.connect(_refresh_texts)


var _about_taps := 0


func _on_about_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_about_taps += 1
		if _about_taps >= 5 and not Save.get_value("post_release", false):
			Save.set_value("post_release", true)  # task 11: chapter 7 unlocked
			$AboutPanel/VBox/Notice.text = I18n.t(&"about.post_release_unlocked")
			_about_taps = 0


func _refresh_texts() -> void:
	title_label.text = I18n.t(&"menu.title")
	play_button.text = I18n.t(&"menu.play")
	jobs_button.text = I18n.t(&"menu.jobs")
	workshop_button.text = I18n.t(&"menu.workshop")
	showcase_button.text = I18n.t(&"menu.showcase")
	settings_button.text = I18n.t(&"menu.settings")
	about_button.text = I18n.t(&"menu.about")
	$AboutPanel/VBox/Notice.text = I18n.t(&"about.notice")
	$AboutPanel/VBox/CloseButton.text = I18n.t(&"common.close")
