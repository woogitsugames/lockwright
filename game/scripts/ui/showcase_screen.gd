extends Control
## Showcase: historical notes from game/data/showcase/*.json with source field.

@onready var notes_list: VBoxContainer = $VBox/Scroll/VBox/NotesList
@onready var back_button: Button = $BackButton

const SHOWCASE_DIR := "res://data/showcase"


func _ready() -> void:
	Sfx.play_ambience(&"workshop")
	SafeArea.apply(self)
	$VBox/Title.text = I18n.t(&"showcase.title")
	back_button.text = I18n.t(&"common.back")
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	for path in DirAccess.get_files_at(SHOWCASE_DIR):
		if not path.ends_with(".json"):
			continue
		var note: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SHOWCASE_DIR + "/" + path))
		var nid: String = note.get("id", path.get_basename())
		var card := VBoxContainer.new()
		var title := Button.new()
		title.text = I18n.t(note.get("i18n", {}).get("title", &"showcase.title"))
		title.alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.custom_minimum_size = Vector2(0, 48)
		var body := Label.new()
		body.text = I18n.t(note.get("i18n", {}).get("body", &"showcase.title"))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.visible = false
		var source := Label.new()
		var src: String = note.get("source", "")
		source.text = "%s: %s" % [I18n.t(&"showcase.source"), src if src != "" else I18n.t(&"showcase.unknown_source")]
		source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		source.visible = false
		title.pressed.connect(func() -> void:
			body.visible = not body.visible
			source.visible = body.visible)
		card.add_child(title)
		card.add_child(body)
		card.add_child(source)
		notes_list.add_child(card)
