class_name PausePanel
extends RefCounted
## N-75: the lock pause as a proper screen instead of three bare labels in the top-left corner.
## The lock stays visible behind a dark leather shade (same shade as ScreenFrame backdrops); the
## column sits in the middle of the window's safe area (16 dp sides, ScreenFrame.fit) on a dark-paper
## panel (theme PanelContainer, as the "day after" cards) with a title and G17 enamel plates
## (EnamelButton, as the control choice screen): Resume = primary navy, the rest navy, Leave = burgundy.
## Plates are 56 dp high (>= 48 dp), 12 dp apart. No blur, glass or icons.

const SHADE := Color(0.06, 0.045, 0.035, 0.84)
const COLUMN_MAX := 340.0
const BUTTON_H := 56.0
const FADE_S := 0.15


## Restyles `cover` (the scene's UILayer/PauseCover ColorRect with its Box VBoxContainer) and fills it.
## entries: [[i18n key, Callable, plate], ...]. Returns {key: EnamelButton}.
static func build(cover: ColorRect, entries: Array) -> Dictionary:
	cover.color = SHADE
	cover.mouse_filter = Control.MOUSE_FILTER_STOP  # taps never reach the lock under the pause
	var box: VBoxContainer = cover.get_node("Box")
	cover.remove_child(box)
	var frame := MarginContainer.new()
	frame.name = "Frame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(frame)
	ScreenFrame.fit(cover, frame, COLUMN_MAX)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(column)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	column.add_child(panel)
	box.set_anchors_preset(Control.PRESET_TOP_LEFT)
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := Label.new()
	title.name = "Title"
	title.theme_type_variation = &"Title"
	title.text = I18n.t(&"pause.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 48)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(title)
	var out := {}
	for spec in entries:
		var b := EnamelButton.new()
		b.plate = spec[2]
		b.text = I18n.t(spec[0])
		b.custom_minimum_size = Vector2(0, BUTTON_H)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", UiA11y.fs(20))
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.pressed.connect(spec[1])
		box.add_child(b)
		out[spec[0]] = b
	ScreenFrame.wire_sounds(cover, false)
	return out


## Shows the cover with a short fade (none with "reduce motion").
static func open(cover: CanvasItem) -> void:
	cover.visible = true
	if UiA11y.reduce_motion() or not cover.is_inside_tree():
		cover.modulate.a = 1.0
		return
	cover.modulate.a = 0.0
	cover.create_tween().tween_property(cover, "modulate:a", 1.0, FADE_S)
