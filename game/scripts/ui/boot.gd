extends Control
## Boot: applies language, shows the one-time "this is a game, not a course" note
## on first launch (ONBOARDING §3.3), then the main menu.

@onready var notice: PanelContainer = $NoticePanel
@onready var notice_label: Label = $NoticePanel/VBox/Label


func _ready() -> void:
	I18n.apply_language(Settings.language())
	notice_label.text = I18n.t(&"about.notice")
	if not Save.get_value("seen_notice", false):
		notice.visible = true
		Save.set_value("seen_notice", true)
	else:
		notice.visible = false
	await get_tree().create_timer(0.1).timeout
	if notice.visible:
		await get_tree().create_timer(3.0).timeout  # the card stays readable, never blocks
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
