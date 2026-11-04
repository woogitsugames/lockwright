extends Control
## Placeholder for screens implemented in later tasks.
## Shows the i18n title so the scene is never blank and never hardcoded.

@export var title_key: StringName = &"menu.title"


func _ready() -> void:
	var label := Label.new()
	label.text = I18n.t(title_key)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(label)
