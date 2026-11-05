extends Node
## Applies text scale to the project theme (A11Y A-05). Safe-area is SafeArea.apply().

func _ready() -> void:
	Settings.changed.connect(_apply_text_scale)
	_apply_text_scale()


func _apply_text_scale() -> void:
	var scale := float(Settings.get_value("text_scale", 1.0))
	var theme: Theme = load("res://theme/main.tres")
	if theme:
		# A-11: scale the per-type overrides too, otherwise Label/Button keep 16/18 px
		theme.default_font_size = int(16 * scale)
		theme.set_font_size("font_size", "Label", int(16 * scale))
		theme.set_font_size("font_size", "Button", int(18 * scale))
		theme.set_font_size("font_size", "Title", int(28 * scale))
