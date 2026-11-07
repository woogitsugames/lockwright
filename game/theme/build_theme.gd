extends SceneTree
## N-54: builds res://theme/main.tres (warm workshop theme, D-43): enamel plates,
## dark paper, brass and leather instead of Godot grey. Run after editing:
##   godot --headless --path game -s res://theme/build_theme.gd
## Icons are DPITexture (SVG re-rasterised at the screen's oversampling), so the
## toggles and slider knobs stay crisp on 2.6x phones.

const OUT := "res://theme/main.tres"
## Bona Nova with lining figures (visual audit VA: its default old-style digits read "4o", "9:3o",
## "Rozdział ı"); every title/heading and the scripts that set Bona Nova directly use this file.
const TITLE_FONT_OUT := "res://theme/title_font.tres"

const INK := Color(0.11, 0.09, 0.07)          # text on enamel
const CREAM := Color(0.94, 0.90, 0.82)        # text on dark paper
const MUTED := Color(0.80, 0.74, 0.64)        # secondary text on dark paper (>= 4.5:1)
const BRASS := Color(0.83, 0.67, 0.37)
const BRASS_DIM := Color(0.55, 0.44, 0.27)
const ENAMEL := Color(0.91, 0.87, 0.78)
const ENAMEL_HOVER := Color(0.96, 0.93, 0.86)
const ENAMEL_PRESSED := Color(0.80, 0.75, 0.66)
const LEATHER := Color(0.24, 0.16, 0.10)
const PAPER := Color(0.085, 0.065, 0.05, 0.80)  # ~70-80% dark paper underlay

const TOGGLE_OFF := """<svg xmlns="http://www.w3.org/2000/svg" width="56" height="32" viewBox="0 0 56 32">
<rect x="2" y="5" width="52" height="22" rx="11" fill="#3d2a1b" stroke="#c9b89c" stroke-width="2"/>
<circle cx="15" cy="16" r="10" fill="#efe6d4" stroke="#1c1712" stroke-width="2"/>
<circle cx="15" cy="16" r="3" fill="none" stroke="#1c1712" stroke-width="2"/>
</svg>"""
const TOGGLE_ON := """<svg xmlns="http://www.w3.org/2000/svg" width="56" height="32" viewBox="0 0 56 32">
<rect x="2" y="5" width="52" height="22" rx="11" fill="#d4ab5e" stroke="#1c1712" stroke-width="2"/>
<path d="M12 16 l4 4 l7 -8" fill="none" stroke="#1c1712" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="41" cy="16" r="10" fill="#1c1712" stroke="#efe6d4" stroke-width="2"/>
<rect x="40" y="10" width="2" height="12" fill="#efe6d4"/>
</svg>"""
const KNOB := """<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 30 30">
<circle cx="15" cy="15" r="13" fill="#d4ab5e" stroke="#1c1712" stroke-width="2"/>
<circle cx="15" cy="15" r="8" fill="none" stroke="#7a5d2c" stroke-width="1.5"/>
<rect x="14" y="5" width="2" height="20" fill="#1c1712"/>
</svg>"""
const KNOB_HI := """<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 30 30">
<circle cx="15" cy="15" r="14" fill="#ecc77c" stroke="#efe6d4" stroke-width="2"/>
<circle cx="15" cy="15" r="8" fill="none" stroke="#7a5d2c" stroke-width="1.5"/>
<rect x="14" y="5" width="2" height="20" fill="#1c1712"/>
</svg>"""
const ARROW := """<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 18 18">
<path d="M3 6 l6 7 l6 -7" fill="none" stroke="#1c1712" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>"""
const RADIO_ON := """<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
<circle cx="12" cy="12" r="10" fill="#1c1712" stroke="#efe6d4" stroke-width="2"/>
<circle cx="12" cy="12" r="5" fill="#d4ab5e"/>
</svg>"""
const RADIO_OFF := """<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
<circle cx="12" cy="12" r="10" fill="none" stroke="#c9b89c" stroke-width="2"/>
</svg>"""


func _svg(src: String, alpha := 1.0) -> DPITexture:
	if alpha < 1.0:
		src = src.replace("<svg ", "<svg opacity=\"%.2f\" " % alpha)
	return DPITexture.create_from_string(src)


func _flat(bg: Color, border := Color.TRANSPARENT, bw := 0, radius := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	return s


func _pad(s: StyleBox, h: float, v: float) -> StyleBox:
	s.content_margin_left = h
	s.content_margin_right = h
	s.content_margin_top = v
	s.content_margin_bottom = v
	return s


## Enamel plate: cream face, ink border, chamfered corners (corner_detail 1),
## a hard drop shadow; pressed = no shadow + text nudged 2 px down (grey-scale readable).
func _enamel(face: Color, shadow: bool, nudge := 0.0) -> StyleBoxFlat:
	var s := _flat(face, INK, 2, 9)
	s.corner_detail = 1
	if shadow:
		s.shadow_color = Color(0, 0, 0, 0.55)
		s.shadow_size = 1
		s.shadow_offset = Vector2(0, 3)
	_pad(s, 16, 10)
	s.content_margin_top += nudge
	s.content_margin_bottom -= nudge
	return s


func _disabled_plate() -> StyleBoxFlat:
	# outline only, no fill and no shadow: a different shape from an active plate
	var s := _flat(Color(0.08, 0.06, 0.05, 0.55), MUTED, 2, 9)
	s.corner_detail = 1
	return _pad(s, 16, 10)


func _focus_ring() -> StyleBoxFlat:
	var s := _flat(Color.TRANSPARENT, BRASS, 3, 11)
	s.draw_center = false
	s.corner_detail = 1
	s.set_expand_margin_all(4)
	return s


func _init() -> void:
	var t := Theme.new()
	t.default_font = load("res://assets/fonts/AtkinsonHyperlegibleNext-wght.ttf")
	t.default_font_size = 16
	var fv := FontVariation.new()
	fv.base_font = load("res://assets/fonts/BonaNova-Bold.ttf")
	var ts := TextServerManager.get_primary_interface()
	fv.opentype_features = {ts.name_to_tag("lnum"): 1}
	ResourceSaver.save(fv, TITLE_FONT_OUT)
	var title_font: Font = load(TITLE_FONT_OUT)

	# --- Label + variations
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_font_size("font_size", "Label", 16)
	t.set_type_variation("Title", "Label")
	t.set_font("font", "Title", title_font)
	t.set_font_size("font_size", "Title", 28)
	t.set_color("font_color", "Title", CREAM)
	t.set_type_variation("MenuTitle", "Label")
	t.set_font("font", "MenuTitle", title_font)
	t.set_font_size("font_size", "MenuTitle", 46)
	t.set_color("font_color", "MenuTitle", Color(0.97, 0.93, 0.84))
	t.set_color("font_shadow_color", "MenuTitle", Color(0, 0, 0, 0.85))
	t.set_constant("shadow_offset_y", "MenuTitle", 3)
	t.set_constant("shadow_offset_x", "MenuTitle", 0)
	t.set_type_variation("Heading", "Label")
	t.set_font("font", "Heading", title_font)
	t.set_font_size("font_size", "Heading", 21)
	t.set_color("font_color", "Heading", BRASS)
	t.set_type_variation("Caption", "Label")
	t.set_font_size("font_size", "Caption", 14)
	t.set_color("font_color", "Caption", MUTED)
	t.set_type_variation("OnEnamel", "Label")
	t.set_color("font_color", "OnEnamel", INK)
	t.set_color("font_shadow_color", "OnEnamel", Color(0, 0, 0, 0))

	# --- Button (enamel plate)
	t.set_font("font", "Button", t.default_font)
	t.set_font_size("font_size", "Button", 18)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_color("icon_normal_color", "Button", INK)
	t.set_stylebox("normal", "Button", _enamel(ENAMEL, true))
	t.set_stylebox("hover", "Button", _enamel(ENAMEL_HOVER, true))
	t.set_stylebox("pressed", "Button", _enamel(ENAMEL_PRESSED, false, 2))
	t.set_stylebox("hover_pressed", "Button", _enamel(ENAMEL_PRESSED, false, 2))
	t.set_stylebox("disabled", "Button", _disabled_plate())
	t.set_stylebox("focus", "Button", _focus_ring())
	t.set_constant("h_separation", "Button", 8)
	# flat text button on dark paper (e.g. the header "back" plate is a normal Button)
	t.set_type_variation("LinkButtonDark", "Button")
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var e := _flat(Color(0, 0, 0, 0) if st != "pressed" else Color(1, 1, 1, 0.08))
		t.set_stylebox(st, "LinkButtonDark", _pad(e, 8, 8))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "LinkButtonDark", CREAM)

	# VA-xx: workshop tab plate - same enamel, tighter sides so three tabs fit 360 dp in every language
	t.set_type_variation("TabPlate", "Button")
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var tb := (t.get_stylebox(st, "Button") as StyleBoxFlat).duplicate() as StyleBoxFlat
		tb.content_margin_left = 6
		tb.content_margin_right = 6
		t.set_stylebox(st, "TabPlate", tb)
	# VA-xx: a finished job - the plate is laid down on the paper (dark fill, brass hairline, no
	# shadow, cream text), so open and done jobs differ in shape and value, not only in the label
	t.set_type_variation("DonePlate", "Button")
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var fill := Color(0.10, 0.075, 0.055, 0.86) if st != "pressed" and st != "hover_pressed" else Color(0.16, 0.12, 0.09, 0.92)
		var dp := _flat(fill, Color(0.55, 0.44, 0.27, 0.9), 1, 9)
		dp.corner_detail = 1
		_pad(dp, 16, 10)
		t.set_stylebox(st, "DonePlate", dp)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "DonePlate", CREAM)

	# --- OptionButton (enamel plate with an ink chevron)
	t.set_font_size("font_size", "OptionButton", 18)
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		t.set_stylebox(st, "OptionButton", t.get_stylebox(st, "Button"))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "OptionButton", INK)
	t.set_color("font_disabled_color", "OptionButton", MUTED)
	t.set_icon("arrow", "OptionButton", _svg(ARROW))
	t.set_constant("arrow_margin", "OptionButton", 14)
	t.set_stylebox("panel", "PopupMenu", _pad(_flat(Color(0.12, 0.09, 0.07, 0.98), BRASS_DIM, 2, 4), 8, 8))
	t.set_stylebox("hover", "PopupMenu", _flat(Color(0.83, 0.67, 0.37, 0.25), BRASS, 1, 3))
	t.set_color("font_color", "PopupMenu", CREAM)
	t.set_color("font_hover_color", "PopupMenu", Color(1, 0.97, 0.9))
	t.set_font_size("font_size", "PopupMenu", 18)
	t.set_constant("v_separation", "PopupMenu", 18)
	t.set_icon("radio_checked", "PopupMenu", _svg(RADIO_ON))
	t.set_icon("radio_unchecked", "PopupMenu", _svg(RADIO_OFF))

	# --- CheckButton (leather/brass toggle; knob side + check mark, not colour alone)
	t.set_font_size("font_size", "CheckButton", 17)
	for st in ["normal", "pressed", "disabled", "hover_pressed"]:
		t.set_stylebox(st, "CheckButton", _pad(StyleBoxEmpty.new(), 4, 8))
	t.set_stylebox("hover", "CheckButton", _pad(_flat(Color(1, 1, 1, 0.05), Color.TRANSPARENT, 0, 4), 4, 8))
	t.set_stylebox("focus", "CheckButton", _focus_ring())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "CheckButton", CREAM)
	t.set_color("font_disabled_color", "CheckButton", MUTED)
	t.set_icon("checked", "CheckButton", _svg(TOGGLE_ON))
	t.set_icon("unchecked", "CheckButton", _svg(TOGGLE_OFF))
	t.set_icon("checked_disabled", "CheckButton", _svg(TOGGLE_ON, 0.45))
	t.set_icon("unchecked_disabled", "CheckButton", _svg(TOGGLE_OFF, 0.45))
	t.set_icon("checked_mirrored", "CheckButton", _svg(TOGGLE_ON))
	t.set_icon("unchecked_mirrored", "CheckButton", _svg(TOGGLE_OFF))
	t.set_constant("h_separation", "CheckButton", 12)

	# --- HSlider (leather strap, brass fill, brass knob)
	var track := _flat(LEATHER, Color(0.79, 0.72, 0.61, 0.9), 1, 4)
	track.content_margin_top = 5
	track.content_margin_bottom = 5
	t.set_stylebox("slider", "HSlider", track)
	var fill := _flat(BRASS, INK, 1, 4)
	fill.content_margin_top = 5
	fill.content_margin_bottom = 5
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	t.set_icon("grabber", "HSlider", _svg(KNOB))
	t.set_icon("grabber_highlight", "HSlider", _svg(KNOB_HI))
	t.set_icon("grabber_disabled", "HSlider", _svg(KNOB, 0.45))

	# --- Panels (dark paper underlay, no blur/glass)
	var paper := _pad(_flat(PAPER, Color(0.55, 0.44, 0.27, 0.55), 1, 4), 14, 12)
	t.set_stylebox("panel", "PanelContainer", paper)
	t.set_stylebox("panel", "Panel", paper)
	t.set_type_variation("EnamelPanel", "PanelContainer")
	var en := _pad(_flat(ENAMEL, INK, 2, 9), 14, 12)
	en.corner_detail = 1
	en.shadow_color = Color(0, 0, 0, 0.55)
	en.shadow_size = 1
	en.shadow_offset = Vector2(0, 3)
	t.set_stylebox("panel", "EnamelPanel", en)
	t.set_stylebox("panel", "AcceptDialog", _pad(_flat(Color(0.12, 0.09, 0.07, 1), BRASS_DIM, 2, 4), 16, 16))
	t.set_stylebox("embedded_border", "Window", _flat(Color(0.12, 0.09, 0.07, 1), BRASS_DIM, 2, 4))
	t.set_color("title_color", "Window", CREAM)

	# --- Scrollbars (thin brass rail; the content never scrolls sideways)
	t.set_stylebox("scroll", "VScrollBar", _pad(_flat(Color(0, 0, 0, 0.25), Color.TRANSPARENT, 0, 3), 2, 0))
	for st in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var g := _flat(BRASS if st != "grabber" else BRASS_DIM, Color.TRANSPARENT, 0, 3)
		t.set_stylebox(st, "VScrollBar", _pad(g, 3, 0))

	# --- RichTextLabel (showcase notes)
	t.set_color("default_color", "RichTextLabel", CREAM)
	t.set_font_size("normal_font_size", "RichTextLabel", 16)
	t.set_font_size("italics_font_size", "RichTextLabel", 16)

	var err := ResourceSaver.save(t, OUT)
	print("theme saved: ", OUT, " err=", err)
	quit()
