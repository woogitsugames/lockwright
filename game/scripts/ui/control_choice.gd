extends Control
## D-52: first-launch control choice, shown once before the tutorial.
## Two large plates: automatic tension (preselected, for beginners) and two thumbs.
## Sets Settings `auto_tension` and `control_chosen`; the lock layer reads them.
## Selected plate = light enamel + "Selected" tag + thicker frame (not colour alone).

const BG := "res://assets/ui/gpt/workshop/02-key-cutter-afternoon-portrait.webp"

# chalk sketches (white strokes on slate), DPITexture keeps them sharp
const SKETCH_AUTO := """<svg xmlns="http://www.w3.org/2000/svg" width="88" height="88" viewBox="0 0 88 88">
<rect width="88" height="88" rx="6" fill="#2b2d2a"/>
<rect x="22" y="10" width="44" height="68" rx="6" fill="none" stroke="#ece8dc" stroke-width="2.5"/>
<path d="M27 62 a9 9 0 0 1 18 0" fill="none" stroke="#ece8dc" stroke-width="2.5" stroke-linecap="round"/>
<path d="M36 62 l4 -6" stroke="#ece8dc" stroke-width="2.5" stroke-linecap="round"/>
<ellipse cx="56" cy="58" rx="9" ry="12" fill="none" stroke="#ece8dc" stroke-width="2.5"/>
<path d="M56 40 v-14 M51 31 l5 -6 l5 6" fill="none" stroke="#ece8dc" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>"""
const SKETCH_MANUAL := """<svg xmlns="http://www.w3.org/2000/svg" width="88" height="88" viewBox="0 0 88 88">
<rect width="88" height="88" rx="6" fill="#2b2d2a"/>
<rect x="22" y="10" width="44" height="68" rx="6" fill="none" stroke="#ece8dc" stroke-width="2.5"/>
<ellipse cx="32" cy="60" rx="8" ry="11" fill="none" stroke="#ece8dc" stroke-width="2.5"/>
<path d="M32 44 v-8 M28 39 l4 -5 l4 5" fill="none" stroke="#ece8dc" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
<ellipse cx="56" cy="58" rx="8" ry="11" fill="none" stroke="#ece8dc" stroke-width="2.5"/>
<path d="M56 42 v-16 M51 31 l5 -6 l5 6 M46 50 h-4 M66 50 h4" fill="none" stroke="#ece8dc" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>"""

var auto_selected := true
var _options := {}


func _ready() -> void:
	ScreenFrame.backdrop(self, BG, 0.6)
	ScreenFrame.fit(self, $Frame)
	auto_selected = bool(Settings.get_value("auto_tension", true)) if Settings.get_value("control_chosen", false) else true
	_options[true] = _make_option(true, SKETCH_AUTO, &"ui.controls.auto", &"ui.controls.auto_desc")
	_options[false] = _make_option(false, SKETCH_MANUAL, &"ui.controls.manual", &"ui.controls.manual_desc")
	$Frame/VBox/Title.text = I18n.t(&"ui.controls.title")
	$Frame/VBox/Note.text = I18n.t(&"ui.controls.note")
	$Frame/VBox/ContinueButton.text = I18n.t(&"common.continue")
	$Frame/VBox/ContinueButton.pressed.connect(confirm)
	resized.connect(_relayout)
	_relayout()
	_update()
	ScreenFrame.enter($Frame/VBox/Scroll)


func _relayout() -> void:
	var vp := get_viewport_rect().size
	$Frame/VBox/Scroll/Options.vertical = vp.x < vp.y


func _make_option(is_auto: bool, svg: String, title_key: StringName, desc_key: StringName) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Auto" if is_auto else "Manual"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var sketch := TextureRect.new()
	sketch.texture = DPITexture.create_from_string(svg)
	sketch.custom_minimum_size = Vector2(88, 88)
	sketch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sketch)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	var tag := ScreenFrame.wrap(Label.new())
	tag.name = "Tag"
	tag.text = I18n.t(&"ui.controls.selected")
	tag.theme_type_variation = &"Caption"
	col.add_child(tag)
	var title := ScreenFrame.wrap(Label.new())
	title.name = "Name"
	title.text = I18n.t(title_key)
	title.add_theme_font_override("font", load("res://assets/fonts/BonaNova-Bold.ttf"))
	title.add_theme_font_size_override("font_size", 20)
	col.add_child(title)
	var desc := ScreenFrame.wrap(Label.new())
	desc.name = "Desc"
	desc.text = I18n.t(desc_key)
	col.add_child(desc)
	var hit := Button.new()
	hit.name = "Hit"
	hit.flat = true
	hit.custom_minimum_size = Vector2(0, 96)
	hit.mouse_filter = Control.MOUSE_FILTER_PASS
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	hit.pressed.connect(select.bind(is_auto))
	panel.add_child(hit)
	$Frame/VBox/Scroll/Options.add_child(panel)
	return panel


func select(is_auto: bool) -> void:
	auto_selected = is_auto
	_update()


func _update() -> void:
	for is_auto in _options:
		var panel: PanelContainer = _options[is_auto]
		var on: bool = is_auto == auto_selected
		panel.theme_type_variation = &"EnamelPanel" if on else &""
		if on:
			var sb := (panel.get_theme_stylebox("panel", &"EnamelPanel") as StyleBoxFlat).duplicate() as StyleBoxFlat
			sb.set_border_width_all(4)
			panel.add_theme_stylebox_override("panel", sb)
		else:
			panel.remove_theme_stylebox_override("panel")
		var ink := Color(0.11, 0.09, 0.07)
		var cream := Color(0.94, 0.90, 0.82)
		for n in ["Name", "Desc", "Tag"]:
			var l: Label = panel.find_child(n, true, false)
			l.add_theme_color_override("font_color", (ink if n != "Tag" else Color(0.32, 0.25, 0.12)) if on else cream)
			l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0 if on else 0.6))
		panel.find_child("Tag", true, false).visible = on


## Saves the choice and continues to the tutorial (or the lock, if already done).
func confirm() -> void:
	Settings.set_value("auto_tension", auto_selected)
	Settings.set_value("control_chosen", true)
	if Save.get_value("tutorial_done", false):
		get_tree().change_scene_to_file(JobRun.lock_scene_path())
	else:
		get_tree().change_scene_to_file("res://scenes/tutorial.tscn")
