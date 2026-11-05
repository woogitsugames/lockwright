extends Control
## Main menu. Buttons are >= 48 dp; all text via i18n.

@onready var play_button: Button = $VBox/PlayButton
@onready var jobs_button: Button = $VBox/JobsButton
@onready var workshop_button: Button = $VBox/WorkshopButton
@onready var showcase_button: Button = $VBox/ShowcaseButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var about_button: Button = $VBox/AboutButton
@onready var title_label: Label = $VBox/Title


func _ready() -> void:
	title_label.text = I18n.t(&"menu.title")
	play_button.text = I18n.t(&"menu.play")
	jobs_button.text = I18n.t(&"menu.jobs")
	workshop_button.text = I18n.t(&"menu.workshop")
	showcase_button.text = I18n.t(&"menu.showcase")
	settings_button.text = I18n.t(&"menu.settings")
	about_button.text = I18n.t(&"menu.about")
	play_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/lock.tscn"))
	jobs_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/jobs_list.tscn"))
	workshop_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/workshop.tscn"))
	showcase_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/showcase.tscn"))
	settings_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/settings.tscn"))
	about_button.pressed.connect(func() -> void: $AboutPanel.visible = true)
	$AboutPanel/VBox/CloseButton.text = I18n.t(&"common.close")
	$AboutPanel/VBox/Notice.text = I18n.t(&"about.notice")
	$AboutPanel/VBox/CloseButton.pressed.connect(func() -> void: $AboutPanel.visible = false)
	I18n.language_changed.connect(_refresh_texts)


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
