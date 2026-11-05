extends Node
## Applies text scale to the project theme (A11Y A-05). Safe-area is SafeArea.apply().

func _ready() -> void:
	Settings.changed.connect(_apply_text_scale)
	_apply_text_scale()


func _apply_text_scale() -> void:
	var scale := float(Settings.get_value("text_scale", 1.0))
	var theme: Theme = load("res://theme/main.tres")
	if theme:
		theme.default_font_size = int(16 * scale)
